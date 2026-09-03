"""
Patch a stage's `MPGroundData` (in header.bin) from config.yaml - scene light,
blast zones, camera bounds, fog. All in-place scalar writes; nothing moves, no
pointer is touched.

    # config.yaml (any subset)
    blast_zones:   { top: 5700, bottom: -1500, left: -6000, right: 6000 }
    camera_bounds: { top: 3900, bottom: -1500, left: -4200, right: 4200 }
    light_angle:   [80, 25]            # [pitch deg, yaw deg]  (z is unused)
    fog:           { color: [225, 200, 255], alpha: 0 }   # color = #RRGGBB or [r,g,b]

`MPGroundData` sits at `offsets.header[1]` inside header.bin (that value is the
struct offset the engine loads it from). Field offsets are relative to it:

    +0x4C  fog_color (u8 r,g,b)   +0x4F  fog_alpha (u8)
    +0x60  light_angle.x (f32)    +0x64  light_angle.y (f32)
    +0x6C  camera_bound top/bottom/right/left (s16 x4)
    +0x74  map_bound   top/bottom/right/left (s16 x4)   <- the blast zones
"""
from __future__ import annotations

import struct

from smashremix_extra.logger import logger

_S16 = {"top": 0, "bottom": 2, "right": 4, "left": 6}


def read(header_bytes, groupdata_offset):
    """Decode the editable MPGroundData fields -> dict (for the drawing tool)."""
    d, b = header_bytes, groupdata_offset

    def bounds(off):
        return {s: struct.unpack_from(">h", d, b + off + so)[0]
                for s, so in _S16.items()}

    return {
        "camera_bounds": bounds(0x6C),
        "blast_zones": bounds(0x74),
        "light_angle": [struct.unpack_from(">f", d, b + 0x60)[0],
                        struct.unpack_from(">f", d, b + 0x64)[0]],
        "fog": {"color": list(d[b + 0x4C:b + 0x4F]), "alpha": d[b + 0x4F]},
    }


def _color(v):
    if isinstance(v, str):
        v = v.lstrip("#")
        return (int(v[0:2], 16), int(v[2:4], 16), int(v[4:6], 16))
    return (int(v[0]) & 0xFF, int(v[1]) & 0xFF, int(v[2]) & 0xFF)


def apply(header_path, groupdata_offset, cfg, *, label=""):
    """`cfg` = the whole config.yaml dict; reads blast_zones / camera_bounds /
    light_angle / fog from it. Returns a list of the fields it changed."""
    label = f"{label}: " if label else ""
    keys = ("blast_zones", "camera_bounds", "light_angle", "fog")
    if not any(k in cfg for k in keys):
        return []

    d = bytearray(open(header_path, "rb").read())
    b = groupdata_offset
    if b + 0x7C > len(d):
        raise ValueError(f"{label}header.bin too small for MPGroundData @ 0x{b:X}")
    changed = []

    def put_bounds(cfg_key, field_off):
        block = cfg.get(cfg_key)
        if not block:
            return
        for side, so in _S16.items():
            if side in block:
                struct.pack_into(">h", d, b + field_off + so, int(block[side]))
        changed.append(cfg_key)

    put_bounds("camera_bounds", 0x6C)
    put_bounds("blast_zones", 0x74)

    if "light_angle" in cfg:
        la = cfg["light_angle"]
        struct.pack_into(">f", d, b + 0x60, float(la[0]))
        if len(la) > 1:
            struct.pack_into(">f", d, b + 0x64, float(la[1]))
        changed.append("light_angle")

    if "fog" in cfg:
        fog = cfg["fog"] or {}
        if "color" in fog:
            d[b + 0x4C:b + 0x4F] = bytes(_color(fog["color"]))
        if "alpha" in fog:
            d[b + 0x4F] = int(fog["alpha"]) & 0xFF
        changed.append("fog")

    open(header_path, "wb").write(d)
    return changed
