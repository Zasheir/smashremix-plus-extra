"""Throwaway committed-preview replay at the coherent CSS gate."""

from __future__ import annotations


MARKER = "// +EXTRA committed preview replay spike"


def _replace_once(source: str, old: str, new: str) -> str:
    count = source.count(old)
    if count != 1:
        raise ValueError(f"expected exactly one transform anchor, found {count}")
    return source.replace(old, new, 1)


def port_preview_teardown_gate_source(source: str) -> str:
    if MARKER in source:
        return source

    source = _replace_once(
        source,
        "        alt_heap_pointer:; dw 0x0\n\n",
        "        alt_heap_pointer:; dw 0x0\n\n"
        f"        {MARKER}\n"
        "        preview_committed_records:; fill 0x0040\n"
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
        "        _preview_records_seeded:\n\n"
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

    // Replace the known failing request before variant and ftCreateDesc derivation.
    OS.patch_start(0x134440, 0x801361C0)
    j       preview_teardown_gate_
    nop
    OS.patch_end()

scope preview_teardown_gate_: {
    lw      a0, 0x0048(s0)
    lli     at, 0x0051
    bne     a0, at, _continue
    nop

    lw      t3, 0x0020(sp)                  // t3 = port
    sltiu   at, t3, 0x0004
    beqz    at, _fallback_invalid_port
    nop
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
