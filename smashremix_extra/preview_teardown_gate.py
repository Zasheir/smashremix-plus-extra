"""Throwaway gate before CSS derives preview construction state."""

from __future__ import annotations


MARKER = "// +EXTRA preview teardown gate spike"


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
        "        debug_preview_teardown_veto_count:; dw 0\n\n",
    )

    gate = """
    // +EXTRA spike: replace the known failing request before any derived state.
    OS.patch_start(0x134440, 0x801361C0)
    j       preview_teardown_gate_
    nop
    OS.patch_end()

scope preview_teardown_gate_: {
    lw      a0, 0x0048(s0)
    lli     at, 0x0051
    bne     a0, at, _continue
    nop

    // Keep the panel, variant lookup, and ftCreateDesc transaction coherent.
    sw      r0, 0x0048(s0)
    or      a0, r0, r0
    li      at, dynamic_css.debug_preview_teardown_veto_count
    lw      t6, 0x0000(at)
    addiu   t6, t6, 0x0001
    sw      t6, 0x0000(at)

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
        gate + "    scope dynamically_load_character_: {\n",
    )
    return source
