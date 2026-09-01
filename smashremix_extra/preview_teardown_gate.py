"""Throwaway committed-preview replay at the coherent CSS gate."""

from __future__ import annotations


MARKER = "// +EXTRA committed preview replay spike v3"
MARKER_FAMILY = "// +EXTRA committed preview replay spike"


def _replace_once(source: str, old: str, new: str) -> str:
    count = source.count(old)
    if count != 1:
        raise ValueError(f"expected exactly one transform anchor, found {count}")
    return source.replace(old, new, 1)


def port_preview_teardown_gate_source(source: str) -> str:
    marker_lines = [
        line.strip() for line in source.splitlines() if line.strip().startswith(MARKER_FAMILY)
    ]
    if marker_lines:
        if marker_lines == [MARKER]:
            return source
        raise ValueError("invalid preview teardown marker; regenerate from pristine source")

    source = _replace_once(
        source,
        "        alt_heap_pointer:; dw 0x0\n\n",
        "        alt_heap_pointer:; dw 0x0\n\n"
        f"        {MARKER}\n"
        "        constant PREVIEW_DEBOUNCE_FRAMES(18)\n"
        "        preview_committed_records:; fill 0x0040\n"
        "        preview_deferred_records:; fill 0x0020\n"
        "        preview_debounce_frames:; fill 0x0010\n"
        "        debug_preview_teardown_veto_count:; dw 0\n"
        "        debug_preview_teardown_fallback_count:; dw 0\n\n",
    )

    source = _replace_once(
        source,
        "        sw      s2, 0x0004(at)              // clear current slot used by port\n\n"
        "        // This routine will run after characters load and update slot_used_by_port\n",
        "        sw      s2, 0x0004(at)              // clear current slot used by port\n\n"
        "        li      t0, dynamic_css.preview_committed_records\n"
        "        lli     t1, 0x0004                  // four per-port records\n"
        "        _seed_provisional_preview_records:\n"
        "        sw      r0, 0x0004(t0)              // preloaded Mario character\n"
        "        sw      r0, 0x0008(t0)              // default variant\n"
        "        sw      r0, 0x000C(t0)              // non-Classic\n"
        "        lli     t2, 0x0002                  // provisional, replace when published\n"
        "        sw      t2, 0x0000(t0)              // publish valid last\n"
        "        addiu   t1, t1, -0x0001\n"
        "        bnez    t1, _seed_provisional_preview_records\n"
        "        addiu   t0, t0, 0x0010\n"
        "        _preview_records_seeded:\n"
        "        li      t0, dynamic_css.preview_deferred_records\n"
        "        li      t3, dynamic_css.preview_debounce_frames\n"
        "        lli     t1, 0x0004\n"
        "        lli     t2, Character.id.NONE\n"
        "        _clear_deferred_requests:\n"
        "        sw      t2, 0x0000(t0)\n"
        "        sw      r0, 0x0004(t0)\n"
        "        sw      r0, 0x0000(t3)\n"
        "        addiu   t0, t0, 0x0008\n"
        "        addiu   t3, t3, 0x0004\n"
        "        addiu   t1, t1, -0x0001\n"
        "        bnez    t1, _clear_deferred_requests\n"
        "        nop\n\n"
        "        // This routine will run after characters load and update slot_used_by_port\n",
    )

    source = _replace_once(
        source,
        "    scope sync_slot_used_by_port: {\n"
        "        li      t0, dynamic_css.slot_used_by_port\n"
        "        lw      t1, 0x0004(t0)              // curr_slot_used_by_port\n"
        "        jr      ra\n"
        "        sw      t1, 0x0000(t0)              // update slot_used_by_port\n"
        "    }\n\n",
        "    scope sync_slot_used_by_port: {\n"
        "        addiu   sp, sp, -0x0010\n"
        "        sw      ra, 0x0004(sp)\n"
        "        jal     seed_initial_preview_records_\n"
        "        nop\n"
        "        jal     retry_deferred_preview_requests_\n"
        "        nop\n"
        "        li      t0, dynamic_css.slot_used_by_port\n"
        "        lw      t1, 0x0004(t0)              // curr_slot_used_by_port\n"
        "        sw      t1, 0x0000(t0)              // update slot_used_by_port\n"
        "        lw      ra, 0x0004(sp)\n"
        "        jr      ra\n"
        "        addiu   sp, sp, 0x0010\n"
        "    }\n\n"
        "    scope seed_initial_preview_records_: {\n"
        "        addiu   sp, sp, -0x0020\n"
        "        sw      t2, 0x0004(sp)\n"
        "        sw      t3, 0x0008(sp)\n"
        "        sw      t4, 0x000C(sp)\n"
        "        sw      t5, 0x0010(sp)\n"
        "        sw      t6, 0x0014(sp)\n"
        "        sw      t7, 0x0018(sp)\n"
        "        li      t0, CSS_PLAYER_STRUCT\n"
        "        li      t1, dynamic_css.preview_committed_records\n"
        "        lli     t2, 0x0004\n"
        "        lli     t7, 0x0000\n"
        "        _loop:\n"
        "        lw      t3, 0x0000(t1)\n"
        "        lli     t4, OS.TRUE\n"
        "        beq     t3, t4, _next\n"
        "        nop\n"
        "        lw      t3, 0x0008(t0)              // published preview fighter object\n"
        "        beqz    t3, _next\n"
        "        nop\n"
        "        lw      t4, 0x0048(t0)\n"
        "        lw      t5, 0x004C(t0)\n"
        "        li      t6, Sonic.classic_table\n"
        "        addu    t6, t6, t7\n"
        "        lbu     t6, 0x0000(t6)\n"
        "        sw      t4, 0x0004(t1)\n"
        "        sw      t5, 0x0008(t1)\n"
        "        sw      t6, 0x000C(t1)\n"
        "        lli     t3, OS.TRUE\n"
        "        sw      t3, 0x0000(t1)              // publish valid last\n"
        "        _next:\n"
        "        addiu   t7, t7, 0x0001\n"
        "        addiu   t0, t0, 0x00BC\n"
        "        addiu   t1, t1, 0x0010\n"
        "        addiu   t2, t2, -0x0001\n"
        "        bnez    t2, _loop\n"
        "        nop\n"
        "        lw      t2, 0x0004(sp)\n"
        "        lw      t3, 0x0008(sp)\n"
        "        lw      t4, 0x000C(sp)\n"
        "        lw      t5, 0x0010(sp)\n"
        "        lw      t6, 0x0014(sp)\n"
        "        lw      t7, 0x0018(sp)\n"
        "        jr      ra\n"
        "        addiu   sp, sp, 0x0020\n"
        "    }\n\n"
        "    scope all_four_preview_panels_active_: {\n"
        "        or      v1, r0, r0\n"
        "        li      t0, CSS_PLAYER_STRUCT\n"
        "        lli     t1, 0x0004\n"
        "        lli     t3, 0x0002                  // Closed panel state\n"
        "        _loop:\n"
        "        lw      t2, 0x0084(t0)              // MAN=0, CPU=1, Closed=2\n"
        "        beq     t2, t3, _return\n"
        "        nop\n"
        "        addiu   t0, t0, 0x00BC\n"
        "        addiu   t1, t1, -0x0001\n"
        "        bnez    t1, _loop\n"
        "        nop\n"
        "        lli     v1, OS.TRUE\n"
        "        _return:\n"
        "        jr      ra\n"
        "        nop\n"
        "    }\n\n"
        "    scope retry_deferred_preview_requests_: {\n"
        "        addiu   sp, sp, -0x0060\n"
        "        sw      ra, 0x0004(sp)\n"
        "        sw      a0, 0x0008(sp)\n"
        "        sw      a1, 0x0040(sp)\n"
        "        sw      a2, 0x0048(sp)\n"
        "        sw      v0, 0x000C(sp)\n"
        "        sw      v1, 0x0010(sp)\n"
        "        sw      t2, 0x0014(sp)\n"
        "        sw      t3, 0x0018(sp)\n"
        "        sw      t4, 0x001C(sp)\n"
        "        sw      t5, 0x0020(sp)\n"
        "        sw      t6, 0x0024(sp)\n"
        "        sw      t7, 0x0028(sp)\n"
        "        sw      t8, 0x002C(sp)\n"
        "        sw      t9, 0x0030(sp)\n"
        "        jal     all_four_preview_panels_active_\n"
        "        nop\n"
        "        sw      v1, 0x004C(sp)              // four-player debounce remains active\n"
        "        li      t0, CSS_PLAYER_STRUCT\n"
        "        li      t1, dynamic_css.preview_deferred_records\n"
        "        lli     t2, 0x0004\n"
        "        lli     t3, 0x0000\n"
        "        _loop:\n"
        "        lw      a0, 0x0000(t1)\n"
        "        lw      a2, 0x0004(t1)\n"
        "        lli     t5, Character.id.NONE\n"
        "        beq     a0, t5, _next\n"
        "        nop\n"
        "        li      t4, dynamic_css.preview_debounce_frames\n"
        "        sll     t5, t3, 0x0002\n"
        "        addu    t4, t4, t5\n"
        "        lw      t6, 0x0000(t4)\n"
        "        lw      v1, 0x004C(sp)\n"
        "        beqz    v1, _debounce_ready        // no longer four-player: remove artificial delay\n"
        "        nop\n"
        "        bltz    t6, _return                // one admitted release waits for the construction gate\n"
        "        nop\n"
        "        beqz    t6, _debounce_ready\n"
        "        nop\n"
        "        addiu   t6, t6, -0x0001\n"
        "        sw      t6, 0x0000(t4)\n"
        "        beqz    t6, _debounce_ready\n"
        "        nop\n"
        "        b       _next\n"
        "        nop\n"
        "        _debounce_ready:\n"
        "        sw      r0, 0x0000(t4)\n"
        "        sw      t0, 0x0034(sp)\n"
        "        sw      t1, 0x0038(sp)\n"
        "        sw      t2, 0x003C(sp)\n"
        "        sw      t3, 0x0044(sp)\n"
        "        sw      t4, 0x0050(sp)\n"
        "        jal     preview_request_can_construct_\n"
        "        nop\n"
        "        lw      t0, 0x0034(sp)\n"
        "        lw      t1, 0x0038(sp)\n"
        "        lw      t2, 0x003C(sp)\n"
        "        lw      t3, 0x0044(sp)\n"
        "        lw      t4, 0x0050(sp)\n"
        "        beqz    v1, _next\n"
        "        nop\n"
        "        li      t5, Sonic.classic_table\n"
        "        addu    t5, t5, t3\n"
        "        sb      a2, 0x0000(t5)\n"
        "        sw      a0, 0x0048(t0)\n"
        "        addiu   t5, r0, -0x0001            // one-shot release for forced loader call\n"
        "        sw      t5, 0x0000(t4)\n"
        "        jal     0x80136128                  // run the existing per-port CSS loader now\n"
        "        or      a0, r0, t3                  // a0 = port (safe single-instruction delay slot)\n"
        "        b       _return\n"
        "        nop\n"
        "        _next:\n"
        "        addiu   t3, t3, 0x0001\n"
        "        addiu   t0, t0, 0x00BC\n"
        "        addiu   t1, t1, 0x0008\n"
        "        addiu   t2, t2, -0x0001\n"
        "        bnez    t2, _loop\n"
        "        nop\n"
        "        _return:\n"
        "        lw      ra, 0x0004(sp)\n"
        "        lw      a0, 0x0008(sp)\n"
        "        lw      a1, 0x0040(sp)\n"
        "        lw      a2, 0x0048(sp)\n"
        "        lw      v0, 0x000C(sp)\n"
        "        lw      v1, 0x0010(sp)\n"
        "        lw      t2, 0x0014(sp)\n"
        "        lw      t3, 0x0018(sp)\n"
        "        lw      t4, 0x001C(sp)\n"
        "        lw      t5, 0x0020(sp)\n"
        "        lw      t6, 0x0024(sp)\n"
        "        lw      t7, 0x0028(sp)\n"
        "        lw      t8, 0x002C(sp)\n"
        "        lw      t9, 0x0030(sp)\n"
        "        jr      ra\n"
        "        addiu   sp, sp, 0x0060\n"
        "    }\n\n",
    )

    code = """
    // Commit a preview only after the fighter object is published at panel+0x08.
    OS.patch_start(0x132E24, 0x80134BA4)
    j       preview_commit_
    nop
    OS.patch_end()

scope preview_commit_: {
    lw      t3, 0x006C(sp)                  // t3 = port
    sltiu   at, t3, 0x0004
    beqz    at, _replay
    nop

    sll     t2, t3, 0x0004
    li      at, dynamic_css.preview_committed_records
    addu    t2, t2, at
    lw      t0, 0x0020(sp)                  // t0 = panel
    lw      t4, 0x0048(t0)                  // committed character
    lw      t5, 0x004C(t0)                  // committed resolved variant
    li      t6, Sonic.classic_table
    addu    t6, t6, t3
    lbu     t6, 0x0000(t6)                  // committed Classic Sonic flag
    sw      t4, 0x0004(t2)
    sw      t5, 0x0008(t2)
    sw      t6, 0x000C(t2)
    lli     t1, OS.TRUE
    sw      t1, 0x0000(t2)                  // publish valid last

_replay:
    lw      t3, 0x006C(sp)                  // original line 1
    lw      t1, 0x0074(s0)                  // original line 2
    j       0x80134BAC
    nop
}

    // Read-only preflight: accept loaded/resident requests or any safely available heap.
    // Return v1 = OS.TRUE to construct now, v1 = OS.FALSE to defer.
scope preview_request_can_construct_: {
    or      v1, r0, r0
    sltiu   t9, a0, Character.NUM_CHARACTERS
    beqz    t9, _return
    nop
    lli     t8, Character.id.PLACEHOLDER
    beq     a0, t8, _return
    nop
    lli     t8, Character.id.NONE
    beq     a0, t8, _return
    nop
    lli     v1, OS.TRUE

    // A non-zero main-file pointer is already loaded, whether permanent or dynamic.
    li      t0, 0x80116E10
    sll     t1, a0, 0x0002
    addu    t0, t0, t1
    lw      t0, 0x0000(t0)
    beqz    t0, _scan_slots
    nop
    lli     t9, Character.id.SONIC
    bne     a0, t9, _ordinary_main_file
    nop
    beqz    a2, _ordinary_main_file
    nop
    lw      t0, 0x0040(t0)                 // Classic Sonic selected main-file pointer
    b       _selected_main_file
    nop
_ordinary_main_file:
    lw      t0, 0x0028(t0)
_selected_main_file:
    beqz    t0, _scan_slots
    nop
    lw      t0, 0x0000(t0)
    bnez    t0, _return
    nop

_scan_slots:
    // Accept a free slot or a slot already owning this exact/additional ID.
    li      t0, dynamic_css.heap_slot_0
    lli     t1, dynamic_css.ACTIVE_HEAP_COUNT
_slot_loop:
    lw      t2, 0x0004(t0)
    lli     t3, Character.id.NONE
    beq     t2, t3, _return
    nop
    beq     a0, t2, _return
    nop
    lbu     t4, 0x0008(t0)
    beq     a0, t4, _return
    nop
    lbu     t4, 0x0009(t0)
    beq     a0, t4, _return
    nop
    lbu     t4, 0x000A(t0)
    beq     a0, t4, _return
    nop
    lbu     t4, 0x000B(t0)
    beq     a0, t4, _return
    nop
    addiu   t0, t0, 0x0010
    addiu   t1, t1, -0x0001
    bnez    t1, _slot_loop
    nop

    // Every assigned slot is usable unless its index appears in previous/current protection.
    lli     t4, 0x0000
_candidate_loop:
    li      t5, dynamic_css.slot_used_by_port
    lli     t6, 0x0008
_protection_loop:
    lbu     t7, 0x0000(t5)
    beq     t4, t7, _protected
    nop
    addiu   t5, t5, 0x0001
    addiu   t6, t6, -0x0001
    bnez    t6, _protection_loop
    nop
    b       _return                         // this candidate is unprotected
    nop

_protected:
    addiu   t4, t4, 0x0001
    slti    t8, t4, dynamic_css.ACTIVE_HEAP_COUNT
    bnez    t8, _candidate_loop
    nop
    or      v1, r0, r0                     // all five heaps are protected

_return:
    jr      ra
    nop
}

    // Gate before variant and ftCreateDesc derivation.
    OS.patch_start(0x134440, 0x801361C0)
    j       preview_teardown_gate_
    nop
    OS.patch_end()

scope preview_teardown_gate_: {
    lw      a0, 0x0048(s0)
    lw      a1, 0x0020(sp)
    or      a2, r0, r0
    sltiu   at, a1, 0x0004
    beqz    at, _run_preflight
    nop
    li      t9, Sonic.classic_table
    addu    t9, t9, a1
    lbu     a2, 0x0000(t9)

    // In four-player VS, debounce every valid preview request before construction.
    sltiu   at, a0, Character.NUM_CHARACTERS
    beqz    at, _cancel_pending_request
    nop
    lli     t8, Character.id.PLACEHOLDER
    beq     a0, t8, _cancel_pending_request
    nop
    lli     t8, Character.id.NONE
    beq     a0, t8, _cancel_pending_request
    nop
    jal     all_four_preview_panels_active_
    nop
    beqz    v1, _run_preflight
    nop

    lw      t3, 0x0020(sp)                  // t3 = port
    li      t7, dynamic_css.preview_deferred_records
    sll     t8, t3, 0x0003
    addu    t7, t7, t8
    li      t6, dynamic_css.preview_debounce_frames
    sll     t8, t3, 0x0002
    addu    t6, t6, t8
    lw      t5, 0x0000(t6)
    bltz    t5, _debounce_release
    nop
    lw      t4, 0x0000(t7)
    bne     t4, a0, _debounce_request_changed
    nop
    lw      t4, 0x0004(t7)
    bne     t4, a2, _debounce_request_changed
    nop
    b       _replay_without_defer           // same pending request does not restart timer
    nop
_debounce_release:
    lw      t4, 0x0000(t7)
    bne     t4, a0, _debounce_request_changed
    nop
    lw      t4, 0x0004(t7)
    bne     t4, a2, _debounce_request_changed
    nop
    lli     t4, Character.id.NONE
    sw      t4, 0x0000(t7)
    sw      r0, 0x0004(t7)
    sw      r0, 0x0000(t6)
    b       _run_preflight                  // exact aged request gets one construction attempt
    nop
_debounce_request_changed:
    sw      a0, 0x0000(t7)
    sw      a2, 0x0004(t7)
    lli     t4, dynamic_css.PREVIEW_DEBOUNCE_FRAMES
    sw      t4, 0x0000(t6)
    b       _replay_without_defer
    nop

_cancel_pending_request:
    li      t7, dynamic_css.preview_deferred_records
    sll     t8, a1, 0x0003
    addu    t7, t7, t8
    lli     t4, Character.id.NONE
    sw      t4, 0x0000(t7)
    sw      r0, 0x0004(t7)
    li      t6, dynamic_css.preview_debounce_frames
    sll     t8, a1, 0x0002
    addu    t6, t6, t8
    sw      r0, 0x0000(t6)
    b       _run_preflight
    nop

_run_preflight:
    jal     preview_request_can_construct_
    nop
    bnez    v1, _continue
    nop

    lw      t3, 0x0020(sp)                  // t3 = port
    sltiu   at, t3, 0x0004
    beqz    at, _fallback_invalid_port
    nop
    sltiu   at, a0, Character.NUM_CHARACTERS
    beqz    at, _replay_without_defer
    nop
    lli     t8, Character.id.PLACEHOLDER
    beq     a0, t8, _replay_without_defer
    nop
    lli     t8, Character.id.NONE
    beq     a0, t8, _replay_without_defer
    nop
    li      t7, dynamic_css.preview_deferred_records
    sll     t8, t3, 0x0003
    addu    t7, t7, t8
    sw      a0, 0x0000(t7)
    sw      a2, 0x0004(t7)
    li      t6, dynamic_css.preview_debounce_frames
    sll     t8, t3, 0x0002
    addu    t6, t6, t8
    sw      r0, 0x0000(t6)
_replay_without_defer:
    sll     t2, t3, 0x0004
    li      at, dynamic_css.preview_committed_records
    addu    t2, t2, at
    lw      t4, 0x0000(t2)
    beqz    t4, _fallback
    nop

    lw      a0, 0x0004(t2)
    lw      v0, 0x0008(t2)
    lw      t6, 0x000C(t2)
    li      t5, Sonic.classic_table
    addu    t5, t5, t3
    sb      t6, 0x0000(t5)
    sw      a0, 0x0048(s0)
    b       _count_veto
    nop

_fallback:
    sw      r0, 0x0048(s0)
    or      v0, r0, r0
    li      t5, Sonic.classic_table
    addu    t5, t5, t3
    sb      r0, 0x0000(t5)
    b       _count_fallback
    nop

_fallback_invalid_port:
    sw      r0, 0x0048(s0)
    or      v0, r0, r0

_count_fallback:
    li      at, dynamic_css.debug_preview_teardown_fallback_count
    lw      t6, 0x0000(at)
    addiu   t6, t6, 0x0001
    sw      t6, 0x0000(at)

_count_veto:
    li      at, dynamic_css.debug_preview_teardown_veto_count
    lw      t6, 0x0000(at)
    addiu   t6, t6, 0x0001
    sw      t6, 0x0000(at)
    j       0x801361CC
    nop

_continue:
    lw      t3, 0x0020(sp)
    sltiu   at, t3, 0x0004
    beqz    at, _resolve
    nop
    li      t7, dynamic_css.preview_deferred_records
    sll     t8, t3, 0x0003
    addu    t7, t7, t8
    lli     t8, Character.id.NONE
    sw      t8, 0x0000(t7)                 // accepted request supersedes stale deferred work
    sw      r0, 0x0004(t7)
    li      t6, dynamic_css.preview_debounce_frames
    sll     t8, t3, 0x0002
    addu    t6, t6, t8
    sw      r0, 0x0000(t6)
_resolve:
    jal     0x8013487C
    lw      a1, 0x0020(sp)
    j       0x801361CC
    nop
}

"""
    source = _replace_once(
        source,
        "    scope dynamically_load_character_: {\n",
        code + "    scope dynamically_load_character_: {\n",
    )
    return source
