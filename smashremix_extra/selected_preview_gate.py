"""Generate the selected-only VS CSS fighter-preview gate."""

import re

MARKER = "// +EXTRA selected-only VS CSS previews v2"

_SYNC_PRISTINE = """    scope sync_slot_used_by_port: {
        li      t0, dynamic_css.slot_used_by_port
        lw      t1, 0x0004(t0)              // curr_slot_used_by_port
        jr      ra
        sw      t1, 0x0000(t0)              // update slot_used_by_port
    }
"""
_SYNC_CANONICAL = """    scope sync_slot_used_by_port: {
        li      t0, dynamic_css.slot_used_by_port
        lw      t1, 0x0004(t0)              // curr_slot_used_by_port
        sw      t1, 0x0000(t0)              // update slot_used_by_port
        // o32 outgoing argument home area: sp+0x00..0x0C is callee-owned.
        addiu   sp, sp, -0x0020
        sw      ra, 0x001C(sp)
        jal     p1_preview_frame_
        nop
        lw      ra, 0x001C(sp)
        jr      ra
        addiu   sp, sp, 0x0020
    }
"""

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
    constant P1_PREVIEW_DEBOUNCE_FRAMES(18)
    constant P1_PREVIEW_SUPPRESSED(0)
    constant P1_PREVIEW_WAITING(1)
    constant P1_PREVIEW_CONSTRUCTING(2)
    constant P1_PREVIEW_VISIBLE(3)
    constant FORCE_SELECTED_PREVIEW_OWNER_INACTIVE(0xFFFFFFFF)
    forced_selected_preview_owner:
    dw FORCE_SELECTED_PREVIEW_OWNER_INACTIVE
    p1_preview_pending_character:; dw Character.id.NONE
    p1_preview_pending_variant:; dw 0
    p1_preview_frame_countdown:; dw 0
    p1_preview_state:; dw P1_PREVIEW_SUPPRESSED
    p1_preview_suppress_depth:; dw 0

    OS.patch_start(0x134458, 0x801361D8)
    jal     selected_preview_make_gate_
    or      a3, v0, r0                  // original delay slot
    OS.patch_end()

    OS.patch_start(0x135474, 0x801371F4)
    jal     selected_preview_on_select_
    sw      v1, 0x0018(sp)              // original delay slot
    OS.patch_end()

    scope selected_preview_on_select_: {{
        sltiu   t3, a0, 0x0004           // stock puck/player index is unsigned 0..3
        bnez    t3, _valid_puck
        nop
        j       0x80131C74                // invalid input: retain stock selection behavior
        nop
        _valid_puck:
        // o32 outgoing argument home area: sp+0x00..0x0C is callee-owned.
        addiu   sp, sp, -0x0040
        sw      ra, 0x003C(sp)
        sw      a0, 0x0038(sp)
        sw      a1, 0x0034(sp)
        sw      a2, 0x0030(sp)
        sw      a3, 0x002C(sp)

        li      t0, CSS_PLAYER_STRUCT
        lli     t1, 0x00BC
        multu   a0, t1
        mflo    t1
        addu    t0, t0, t1
        lw      t0, 0x0080(t0)          // held player index
        sw      t0, 0x0028(sp)

        sltiu   t3, t0, 0x0004           // do not index CSS panels with a corrupt held index
        beqz    t3, _invalid_held_player
        nop

        bnez    t0, _keep_p1_scheduler
        nop
        li      t2, p1_preview_pending_character
        lli     t1, Character.id.NONE
        sw      t1, 0x0000(t2)
        sw      r0, 0x0004(t2)
        sw      r0, 0x0008(t2)
        sw      r0, 0x000C(t2)
        _keep_p1_scheduler:

        li      t2, forced_selected_preview_owner
        lw      t1, 0x0000(t2)
        sw      t1, 0x0024(sp)           // preserve outer forced owner for nested stock updates
        or      a0, t0, r0
        sw      t0, 0x0000(t2)           // exact held player owns this forced stock update
        jal     0x80136128              // stock mnPlayersVSUpdateFighter
        nop
        li      t2, forced_selected_preview_owner
        lw      t1, 0x0024(sp)
        sw      t1, 0x0000(t2)           // balanced restoration preserves an outer owner

        lw      a0, 0x0038(sp)
        lw      a1, 0x0034(sp)
        lw      a2, 0x0030(sp)
        lw      a3, 0x002C(sp)
        jal     0x80131C74              // stock mnPlayersVSSelectFighterPuck
        nop
        sw      v0, 0x0020(sp)           // preserve native selection results across optional cleanup
        sw      v1, 0x001C(sp)

        lw      t0, 0x0028(sp)          // held player index
        li      t1, CSS_PLAYER_STRUCT
        lli     t2, 0x00BC
        multu   t0, t2
        mflo    t2
        addu    t1, t1, t2
        lw      t2, 0x0058(t1)          // panel is_selected after stock selection
        bnez    t2, _return
        nop
        bnez    t0, _hide_denied_preview
        nop
        li      t2, p1_preview_suppress_depth
        lli     t1, 0x0001
        lw      t3, 0x0000(t2)
        addu    t3, t3, t1
        sw      t3, 0x0000(t2)           // stock update synchronously re-enters this gate
        _hide_denied_preview:
        or      a0, t0, r0
        jal     0x80136128              // unforced update hides a denied C-button preview
        nop
        bnez    t0, _return
        nop
        li      t2, p1_preview_suppress_depth
        lw      t3, 0x0000(t2)
        addiu   t3, t3, -0x0001
        sw      t3, 0x0000(t2)

        _return:
        lw      v0, 0x0020(sp)
        lw      v1, 0x001C(sp)
        lw      ra, 0x003C(sp)
        addiu   sp, sp, 0x0040
        jr      ra
        nop

        _invalid_held_player:
        lw      a0, 0x0038(sp)
        lw      a1, 0x0034(sp)
        lw      a2, 0x0030(sp)
        lw      a3, 0x002C(sp)
        jal     0x80131C74                // invalid held index: do not force or cancel scheduler
        nop
        sw      v0, 0x0020(sp)
        sw      v1, 0x001C(sp)
        b       _return
        nop
    }}

    scope selected_preview_make_gate_: {{
        sltiu   t5, a1, 0x0004           // native player index is unsigned 0..3
        beqz    t5, _return
        nop
        li      t0, CSS_PLAYER_STRUCT
        lli     t1, 0x00BC
        multu   a1, t1
        mflo    t1
        addu    t0, t0, t1
        lw      t2, 0x0058(t0)          // panel is_selected
        bnez    a1, _non_p1
        nop
        b       _p1
        nop
        _non_p1:
        bnez    t2, _allow
        nop
        li      t3, forced_selected_preview_owner
        lw      t3, 0x0000(t3)
        beq     a1, t3, _allow           // only this player may bypass an unselected gate
        nop
        beqz    a0, _return
        nop
        lli     t2, 0x0001
        sw      t2, 0x007C(a0)          // hide retained preview GObj

        _return:
        jr      ra
        nop

        _p1:
        bnez    t2, _cancel_and_allow
        nop
        li      t3, forced_selected_preview_owner
        lw      t3, 0x0000(t3)
        beq     a1, t3, _cancel_and_allow // forced P1 selection cancels its scheduler and allows
        nop
        lw      t3, 0x0084(t0)          // MAN/CPU are the only open panel states
        sltiu   t4, t3, 0x0002
        beqz    t4, _cancel_p1
        nop
        li      t2, p1_preview_suppress_depth
        lw      t3, 0x0000(t2)
        bnez    t3, _cancel_p1
        nop
        lw      t3, 0x0048(t0)          // exact displayed character request
        sltiu   t4, t3, Character.NUM_CHARACTERS
        beqz    t4, _cancel_p1
        nop
        lli     t4, Character.id.PLACEHOLDER
        beq     t3, t4, _cancel_p1
        nop
        lli     t4, Character.id.NONE
        beq     t3, t4, _cancel_p1
        nop
        li      t2, p1_preview_pending_character
        lw      t4, 0x0000(t2)
        bne     t3, t4, _restart
        nop
        lw      t4, 0x0004(t2)
        bne     v0, t4, _restart         // hook-time resolved variant is part of the request
        nop
        lw      t4, 0x000C(t2)
        lli     t5, P1_PREVIEW_CONSTRUCTING
        beq     t4, t5, _allow            // nested exact loader construction releases only itself
        nop
        lli     t5, P1_PREVIEW_VISIBLE
        beq     t4, t5, _allow
        nop
        // Exact WAITING requests are denied without advancing time; render owns the clock.
        b       _hide_p1_hover
        nop

        _restart:
        sw      t3, 0x0000(t2)
        sw      v0, 0x0004(t2)
        lli     t4, P1_PREVIEW_DEBOUNCE_FRAMES
        sw      t4, 0x0008(t2)
        lli     t4, P1_PREVIEW_WAITING
        sw      t4, 0x000C(t2)
        b       _hide_p1_hover
        nop

        _hide_p1_hover:
        beqz    a0, _return
        nop
        lli     t4, 0x0001
        sw      t4, 0x007C(a0)           // only P1 scheduler denials hide retained previews
        b       _return
        nop

        _cancel_and_allow:
        li      t2, p1_preview_pending_character
        lli     t4, Character.id.NONE
        sw      t4, 0x0000(t2)
        sw      r0, 0x0004(t2)
        sw      r0, 0x0008(t2)
        sw      r0, 0x000C(t2)
        b       _allow
        nop

        _cancel_p1:
        li      t2, p1_preview_pending_character
        lli     t4, Character.id.NONE
        sw      t4, 0x0000(t2)
        sw      r0, 0x0004(t2)
        sw      r0, 0x0008(t2)
        sw      r0, 0x000C(t2)
        beqz    a0, _return
        nop
        lli     t4, 0x0001
        sw      t4, 0x007C(a0)           // only P1 cancellation denies this construction
        b       _return
        nop

        _allow:
        j       0x80134A8C              // native mnPlayersVSMakeFighter entry
        nop
    }}

    // Render callback: frame clock for stationary P1 hover debounce.
    scope p1_preview_frame_: {{
        // o32 outgoing argument home area: sp+0x00..0x0C is callee-owned.
        addiu   sp, sp, -0x0050
        sw      ra, 0x004C(sp)
        sw      at, 0x0048(sp)
        sw      a0, 0x0044(sp)
        sw      a1, 0x0040(sp)
        sw      a2, 0x003C(sp)
        sw      a3, 0x0038(sp)
        sw      v0, 0x0034(sp)
        sw      v1, 0x0030(sp)
        sw      t2, 0x002C(sp)
        sw      t3, 0x0028(sp)
        sw      t4, 0x0024(sp)
        sw      t5, 0x0020(sp)
        sw      t6, 0x001C(sp)
        sw      t7, 0x0018(sp)
        sw      t8, 0x0014(sp)
        sw      t9, 0x0010(sp)

        li      t2, p1_preview_pending_character
        lw      t3, 0x000C(t2)
        lli     t4, P1_PREVIEW_WAITING
        bne     t3, t4, _return
        nop
        li      t4, CSS_PLAYER_STRUCT
        lw      t5, 0x0058(t4)
        bnez    t5, _clear
        nop
        lw      t5, 0x0084(t4)
        sltiu   t5, t5, 0x0002
        beqz    t5, _clear
        nop
        lw      t5, 0x0048(t4)
        lw      t6, 0x0000(t2)
        bne     t5, t6, _clear
        nop
        lw      t5, 0x004C(t4)          // live panel variant compared with hook-time resolved v0
        lw      t6, 0x0004(t2)
        bne     t5, t6, _clear
        nop
        lw      t5, 0x0008(t2)
        beqz    t5, _clear                // malformed WAITING zero must clear, never underflow
        nop
        addiu   t5, t5, -0x0001
        sw      t5, 0x0008(t2)
        bnez    t5, _return
        nop
        lli     t5, P1_PREVIEW_CONSTRUCTING
        sw      t5, 0x000C(t2)
        jal     0x80136128              // proven native per-port loader
        or      a0, r0, r0               // P1, safe single-instruction delay slot

        li      t2, p1_preview_pending_character
        lw      t3, 0x000C(t2)
        lli     t4, P1_PREVIEW_CONSTRUCTING
        bne     t3, t4, _return          // nested mismatch preserved newest request
        nop
        li      t4, CSS_PLAYER_STRUCT
        lw      t5, 0x0058(t4)
        bnez    t5, _clear
        nop
        lw      t5, 0x0084(t4)
        sltiu   t5, t5, 0x0002
        beqz    t5, _clear
        nop
        lw      t5, 0x0048(t4)
        lw      t6, 0x0000(t2)
        bne     t5, t6, _clear
        nop
        lw      t5, 0x004C(t4)          // live panel variant compared with hook-time resolved v0
        lw      t6, 0x0004(t2)
        bne     t5, t6, _clear
        nop
        lw      t5, 0x0008(t4)
        beqz    t5, _clear
        nop
        lli     t5, P1_PREVIEW_VISIBLE
        sw      t5, 0x000C(t2)
        b       _return
        nop

        _clear:
        lli     t3, Character.id.NONE
        sw      t3, 0x0000(t2)
        sw      r0, 0x0004(t2)
        sw      r0, 0x0008(t2)
        sw      r0, 0x000C(t2)
        _return:
        lw      t9, 0x0010(sp)
        lw      t8, 0x0014(sp)
        lw      t7, 0x0018(sp)
        lw      t6, 0x001C(sp)
        lw      t5, 0x0020(sp)
        lw      t4, 0x0024(sp)
        lw      t3, 0x0028(sp)
        lw      t2, 0x002C(sp)
        lw      v1, 0x0030(sp)
        lw      v0, 0x0034(sp)
        lw      a3, 0x0038(sp)
        lw      a2, 0x003C(sp)
        lw      a1, 0x0040(sp)
        lw      a0, 0x0044(sp)
        lw      at, 0x0048(sp)
        lw      ra, 0x004C(sp)
        jr      ra
        addiu   sp, sp, 0x0050
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

    pristine_sync_count = transformed.count(_SYNC_PRISTINE)
    canonical_sync_count = transformed.count(_SYNC_CANONICAL)
    if pristine_sync_count == 1 and canonical_sync_count == 0:
        transformed = transformed.replace(_SYNC_PRISTINE, _SYNC_CANONICAL, 1)
    elif pristine_sync_count != 0 or canonical_sync_count != 1:
        raise ValueError(
            "expected exactly one pristine or canonical dynamic CSS sync scope, found "
            f"{pristine_sync_count} and {canonical_sync_count}"
        )

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
