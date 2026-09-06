"""Generate the selected-only VS CSS fighter-preview gate."""

import re

MARKER = "// +EXTRA selected-only VS CSS previews v1"

_ANCHOR = "    constant CSS_PLAYER_STRUCT(0x8013BA88)\n"
_TRAINING_ANCHOR = "    constant CSS_PLAYER_STRUCT_TRAINING(0x80138558)\n"
_SELECTED_MARKER = re.compile(r"^\s*// \+EXTRA selected-only VS CSS previews\b.*$", re.MULTILINE)
_LEGACY_MARKER = re.compile(
    r"^\s*// \+EXTRA (?:"
    r"no-preview|"
    r"safe multiplayer no-preview|"
    r"multiplayer fighter-preview suppression|"
    r"committed preview replay spike|"
    r"preview teardown gate spike|"
    r"exact serialized CSS preview scheduler|"
    r"preview lifecycle|"
    r"preview debounce"
    r")\b.*$",
    re.IGNORECASE | re.MULTILINE,
)

_STOCK_INDICATOR_PRISTINE = """        _draw_indicator:
        li      t1, Character.id.NONE
        beq     t1, s3, _next               // skip drawing if no character displayed
        nop
        addiu   sp, sp,-0x0020              // allocate stack space
"""
_STOCK_INDICATOR_CANONICAL = """        _draw_indicator:
        li      t1, Character.id.NONE
        beq     t1, s3, _next               // skip drawing if no character displayed
        nop
        lw      t1, 0x0088(s2)              // t1 = character selected state
        beqz    t1, _next                    // selected-only previews have no hover fighter object
        nop
        addiu   sp, sp,-0x0020              // allocate stack space
"""

_BLOCK = f"""

    {MARKER}
    force_selected_preview:
    dw 0

    OS.patch_start(0x134458, 0x801361D8)
    jal     selected_preview_make_gate_
    or      a3, v0, r0                  // original delay slot
    OS.patch_end()

    OS.patch_start(0x135474, 0x801371F4)
    jal     selected_preview_on_select_
    sw      v1, 0x0018(sp)              // original delay slot
    OS.patch_end()

    scope selected_preview_on_select_: {{
        addiu   sp, sp, -0x0020
        sw      ra, 0x001C(sp)
        sw      a0, 0x0018(sp)
        sw      a1, 0x0014(sp)

        li      t0, CSS_PLAYER_STRUCT
        lli     t1, 0x00BC
        multu   a0, t1
        mflo    t1
        addu    t0, t0, t1
        lw      t0, 0x0080(t0)          // held player index
        sw      t0, 0x0010(sp)

        li      t2, force_selected_preview
        lli     t1, 0x0001
        sw      t1, 0x0000(t2)
        or      a0, t0, r0
        jal     0x80136128              // stock mnPlayersVSUpdateFighter
        nop
        li      t2, force_selected_preview
        sw      r0, 0x0000(t2)

        lw      a1, 0x0014(sp)
        lw      a0, 0x0018(sp)
        jal     0x80131C74              // stock mnPlayersVSSelectFighterPuck
        nop

        lw      t0, 0x0010(sp)          // held player index
        li      t1, CSS_PLAYER_STRUCT
        lli     t2, 0x00BC
        multu   t0, t2
        mflo    t2
        addu    t1, t1, t2
        lw      t2, 0x0058(t1)          // panel is_selected after stock selection
        bnez    t2, _return
        nop
        or      a0, t0, r0
        jal     0x80136128              // unforced update hides a denied C-button preview
        nop

        _return:
        lw      a1, 0x0014(sp)
        lw      a0, 0x0018(sp)
        lw      ra, 0x001C(sp)
        addiu   sp, sp, 0x0020
        jr      ra
        nop
    }}

    scope selected_preview_make_gate_: {{
        li      t0, CSS_PLAYER_STRUCT
        lli     t1, 0x00BC
        multu   a1, t1
        mflo    t1
        addu    t0, t0, t1
        lw      t2, 0x0058(t0)          // panel is_selected
        bnez    t2, _allow
        nop
        li      t2, force_selected_preview
        lw      t2, 0x0000(t2)
        bnez    t2, _allow
        nop
        beqz    a0, _return
        nop
        lli     t2, 0x0001
        sw      t2, 0x007C(a0)          // hide retained preview GObj

        _return:
        jr      ra
        nop

        _allow:
        j       0x80134A8C              // native mnPlayersVSMakeFighter entry
        nop
    }}
"""


def transform_character_select(source: str) -> str:
    """Insert the gate only into the exact pristine CSS transform region."""
    if _LEGACY_MARKER.search(source):
        raise ValueError("legacy CSS preview marker present")

    selected_markers = [marker.strip() for marker in _SELECTED_MARKER.findall(source)]
    if selected_markers and selected_markers != [MARKER]:
        raise ValueError("stale, future, or duplicate selected-only preview marker")

    anchor_count = source.count(_ANCHOR)
    training_anchor_count = source.count(_TRAINING_ANCHOR)
    if anchor_count != 1 or training_anchor_count != 1:
        raise ValueError(
            "expected exactly one CSS and training transform anchor, found "
            f"{anchor_count} and {training_anchor_count}"
        )

    start = source.index(_ANCHOR)
    end = source.index(_TRAINING_ANCHOR, start) + len(_TRAINING_ANCHOR)
    region = source[start:end]
    pristine_region = _ANCHOR + _TRAINING_ANCHOR
    canonical_region = _ANCHOR + _BLOCK + _TRAINING_ANCHOR
    if region == canonical_region:
        transformed = source
    elif region == pristine_region:
        if selected_markers:
            raise ValueError("selected-only preview marker lies outside canonical region")
        transformed = source[:start] + canonical_region + source[end:]
    else:
        raise ValueError("selected-only preview transform region is not pristine or canonical")

    pristine_stock_count = transformed.count(_STOCK_INDICATOR_PRISTINE)
    canonical_stock_count = transformed.count(_STOCK_INDICATOR_CANONICAL)
    if canonical_stock_count == 1 and pristine_stock_count == 0:
        return transformed
    if pristine_stock_count == 1 and canonical_stock_count == 0:
        return transformed.replace(
            _STOCK_INDICATOR_PRISTINE,
            _STOCK_INDICATOR_CANONICAL,
            1,
        )
    raise ValueError(
        "expected exactly one pristine or canonical stock-indicator hover guard, found "
        f"{pristine_stock_count} and {canonical_stock_count}"
    )
