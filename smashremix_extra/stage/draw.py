"""
Draw a top-down diagram of a stage's layout - collision lines coloured by
yakumono group, blast zones, camera bounds, and map objects (player starts,
item spawns, ...). Pure inspection; reads stage.bin + header.bin, writes a PNG.

    from smashremix_extra.stage import draw
    draw.render_files("stage.bin", "header.bin", "out.png",
                      chain_head=0x5E4C, groupdata_off=0x14)
"""
from __future__ import annotations

from PIL import Image, ImageDraw, ImageFont

from smashremix_extra.stage import collision, ground

# one distinct colour per yakumono group id (1..)
_GROUP_COLORS = [
    (232, 68, 68), (68, 160, 232), (96, 200, 96), (232, 176, 64),
    (176, 112, 232), (64, 208, 200), (232, 120, 176), (150, 150, 150),
    (200, 200, 80), (120, 90, 60), (90, 200, 140), (200, 140, 200),
]
_BG = (24, 26, 30)
_GRID = (44, 47, 52)
_BLAST = (220, 60, 60)
_CAMERA = (210, 190, 70)
_TEXT = (210, 213, 218)
_MAPOBJ = (255, 255, 255)
_START_KINDS = {0x00: "P1", 0x01: "P2", 0x02: "P3", 0x03: "P4",
                0x20: "respawn", 0x04: "item"}


def _font(sz=12):
    try:
        return ImageFont.truetype("DejaVuSans.ttf", sz)
    except OSError:
        return ImageFont.load_default()


def render(stage_bytes, header_bytes, *, chain_head=None, groupdata_off=0x14,
           width=2000, margin=90, only_group=None):
    """only_group: if set, draw collision lines for just that yakumono id (the
    view bounds, grid, blast/camera boxes and map objects are unchanged, so a
    set of per-group images all share the same framing)."""
    geo = collision.decode(stage_bytes, chain_head)
    gd = ground.read(header_bytes, groupdata_off)

    # View = blast zone (grown) + camera bounds + map objects, then collision
    # vertices that fall within ~1.6x of that (keeps huge blast-corner diagonals
    # from blowing up the scale - they just clip at the canvas edge).
    xs, ys = [], []
    for b in (gd["blast_zones"], gd["camera_bounds"]):
        xs += [b["left"], b["right"]]
        ys += [b["bottom"], b["top"]]
    for _k, x, y in geo.mapobjs:
        xs.append(x)
        ys.append(y)
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    hw = (max(xs) - min(xs)) * 0.8 + 500
    hh = (max(ys) - min(ys)) * 0.8 + 500
    for _yid, _tn, _ln, pts in geo.iter_lines():
        for x, y, _f in pts:
            if abs(x - cx) <= hw and abs(y - cy) <= hh:
                xs.append(x)
                ys.append(y)
    minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)

    span_x = max(maxx - minx, 1)
    span_y = max(maxy - miny, 1)
    scale = (width - 2 * margin) / span_x
    height = max(int(span_y * scale + 2 * margin), 400)

    def px(x, y):
        return (margin + (x - minx) * scale,
                height - margin - (y - miny) * scale)   # flip: game Y is up

    img = Image.new("RGB", (width, height), _BG)
    dr = ImageDraw.Draw(img)
    f, fs = _font(17), _font(14)

    # grid at 0 and every 1000 units
    for gx in range(int(minx // 1000) * 1000, int(maxx) + 1000, 1000):
        x0, _ = px(gx, 0)
        dr.line([(x0, 0), (x0, height)], fill=_GRID)
    for gy in range(int(miny // 1000) * 1000, int(maxy) + 1000, 1000):
        _, y0 = px(0, gy)
        dr.line([(0, y0), (width, y0)], fill=_GRID)
    ox, oy = px(0, 0)
    dr.line([(ox, 0), (ox, height)], fill=(70, 74, 80))
    dr.line([(0, oy), (width, oy)], fill=(70, 74, 80))

    def rect(b, color, dash, tag):
        x0, y0 = px(b["left"], b["top"])
        x1, y1 = px(b["right"], b["bottom"])
        step = 14 if dash else 0
        if step:
            for a, c in ((x0, x1), ):
                for xx in range(int(a), int(c), step):
                    dr.line([(xx, y0), (min(xx + step / 2, c), y0)], fill=color)
                    dr.line([(xx, y1), (min(xx + step / 2, c), y1)], fill=color)
            for a, c in ((y0, y1) if y0 < y1 else (y1, y0), ):
                for yy in range(int(a), int(c), step):
                    dr.line([(x0, yy), (x0, min(yy + step / 2, c))], fill=color)
                    dr.line([(x1, yy), (x1, min(yy + step / 2, c))], fill=color)
        else:
            dr.rectangle([x0, y0, x1, y1], outline=color)
        ymin, ymax = min(y0, y1), max(y0, y1)
        th = 15
        # tag centred just above the top edge
        tw = dr.textlength(tag, font=fs)
        dr.text(((x0 + x1) / 2 - tw / 2, ymin - th - 5), tag, fill=color, font=fs)
        # corner coordinates, just outside each corner
        for cx, cy, sx, sy in ((b["left"], b["top"], x0, ymin),
                               (b["right"], b["top"], x1, ymin),
                               (b["left"], b["bottom"], x0, ymax),
                               (b["right"], b["bottom"], x1, ymax)):
            t = f"{cx}, {cy}"
            w = dr.textlength(t, font=fs)
            dx = -w - 4 if sx <= (x0 + x1) / 2 else 4
            dy = -th - 3 if sy <= (ymin + ymax) / 2 else 3
            dr.text((sx + dx, sy + dy), t, fill=color, font=fs)

    rect(gd["camera_bounds"], _CAMERA, False, "camera")
    rect(gd["blast_zones"], _BLAST, False, "blast zone")

    # collision lines
    ftiny = _font(11)
    labeled = set()   # screen positions already given an x,y label
    for yid, tname, line_id, pts in geo.iter_lines():
        if only_group is not None and yid != only_group:
            continue
        color = _GROUP_COLORS[(yid - 1) % len(_GROUP_COLORS)]
        scr = [px(x, y) for x, y, _f in pts]
        w = 3 if tname in ("rwall", "lwall") else 2
        drop = bool(pts and pts[0][2] & 0x4000)
        if drop:
            for (ax, ay), (bx, by) in zip(scr, scr[1:]):
                n = max(int(((bx - ax) ** 2 + (by - ay) ** 2) ** 0.5 / 12), 1)
                for k in range(0, n, 2):
                    dr.line([(ax + (bx - ax) * k / n, ay + (by - ay) * k / n),
                             (ax + (bx - ax) * (k + 1) / n,
                              ay + (by - ay) * (k + 1) / n)], fill=color, width=w)
        else:
            dr.line(scr, fill=color, width=w)
        for idx, ((sx, sy), (x, y, pf)) in enumerate(zip(scr, pts)):
            dr.ellipse([sx - 2, sy - 2, sx + 2, sy + 2], fill=color)
            if pf & 0x8000:                      # grab-able ledge
                dr.ellipse([sx - 6, sy - 6, sx + 6, sy + 6], outline=color, width=2)
            key = (round(sx), round(sy))
            if key in labeled:
                continue
            labeled.add(key)
            # offset the label away from the rest of the line: a point that is
            # the left/upper end of its line gets its text on the left/above,
            # etc.; centred when the two ends line up on that axis.
            ox2, oy2 = scr[idx - 1] if idx else scr[idx + 1]
            txt = f"{x}, {y}"
            tw, th, pad = dr.textlength(txt, font=ftiny), 12, 6
            dx = (pad if sx > ox2 + 1 else -tw - pad if sx < ox2 - 1 else -tw / 2)
            dy = (-th - pad if sy < oy2 - 1 else pad if sy > oy2 + 1 else -th / 2)
            dr.text((sx + dx, sy + dy), txt, fill=_TEXT, font=ftiny)
        # line id at the midpoint of the middle segment
        i = max(len(scr) // 2 - 1, 0)
        mx = (scr[i][0] + scr[i + 1][0]) / 2 if len(scr) > 1 else scr[0][0]
        my = (scr[i][1] + scr[i + 1][1]) / 2 if len(scr) > 1 else scr[0][1]
        dr.text((mx + 3, my - 12), f"L{line_id} g{yid}", fill=color, font=fs)

    # map objects
    for k, x, y in geo.mapobjs:
        sx, sy = px(x, y)
        dr.ellipse([sx - 3, sy - 3, sx + 3, sy + 3], outline=_MAPOBJ)
        if k in _START_KINDS:
            dr.text((sx + 4, sy - 6), _START_KINDS[k], fill=_MAPOBJ, font=fs)

    # legend
    ly = 12
    head = (f"group {only_group} only" if only_group is not None
            else f"{geo.group_count} groups")
    dr.text((12, ly), f"{head}   "
            f"light {gd['light_angle'][0]:.0f},{gd['light_angle'][1]:.0f}   "
            f"1000u grid", fill=_TEXT, font=f)
    for yid in sorted({y for y, *_ in geo.groups}):
        if only_group is not None and yid != only_group:
            continue
        ly += 16
        c = _GROUP_COLORS[(yid - 1) % len(_GROUP_COLORS)]
        dr.line([(12, ly + 6), (30, ly + 6)], fill=c, width=3)
        dr.text((36, ly), f"group {yid}", fill=c, font=fs)
    return img


def render_files(stage_path, header_path, out_path, *,
                 chain_head=None, groupdata_off=0x14, only_group=None):
    img = render(open(stage_path, "rb").read(), open(header_path, "rb").read(),
                 chain_head=chain_head, groupdata_off=groupdata_off,
                 only_group=only_group)
    img.save(out_path)
    return out_path


def render_group_set(stage_path, header_path, out_path, *,
                     chain_head=None, groupdata_off=0x14):
    """Write `out_path` (all groups) plus one `<stem>_groupN.<ext>` per group.
    Returns the list of paths written."""
    import os

    sb = open(stage_path, "rb").read()
    hb = open(header_path, "rb").read()
    kw = dict(chain_head=chain_head, groupdata_off=groupdata_off)

    render(sb, hb, **kw).save(out_path)
    written = [out_path]

    stem, ext = os.path.splitext(out_path)
    geo = collision.decode(sb, chain_head)
    for yid in sorted({y for y, *_ in geo.groups}):
        p = f"{stem}_group{yid}{ext}"
        render(sb, hb, only_group=yid, **kw).save(p)
        written.append(p)
    return written
