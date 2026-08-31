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
