import re

import pytest


import smashremix_extra.selected_preview_gate as preview_gate
from smashremix_extra.selected_preview_gate import MARKER, transform_character_select


PRISTINE_SOURCE = """if !{defined __CHARACTER_SELECT__} {
define __CHARACTER_SELECT__()
scope CharacterSelect {
    constant CSS_PLAYER_STRUCT(0x8013BA88)
    constant CSS_PLAYER_STRUCT_TRAINING(0x80138558)

        _draw_indicator:
        li      t1, Character.id.NONE
        beq     t1, s3, _next               // skip drawing if no character displayed
        nop
        addiu   sp, sp,-0x0020              // allocate stack space

    scope sync_slot_used_by_port: {
        li      t0, dynamic_css.slot_used_by_port
        lw      t1, 0x0004(t0)              // curr_slot_used_by_port
        jr      ra
        sw      t1, 0x0000(t0)              // update slot_used_by_port
    }
}
} // __CHARACTER_SELECT__
"""


PRISTINE_BOOT = """    // @ Description
    // Draws the version on the title screen
    scope draw_version_on_title_screen_: {
        addiu   sp, sp,-0x0030              // allocate stack space
        sw      ra, 0x0004(sp)              // save registers

        Render.load_font()
        Render.draw_string(1, 3, string_version, Render.NOOP, 0x43200000, 0x435A0000, 0x888800FF, 0x3F700000, Render.alignment.CENTER)

        lw      ra, 0x0004(sp)              // restore registers
        addiu   sp, sp, 0x0030              // deallocate stack space

        jr      ra
        nop
    }

    string_version:; String.insert("Smash Remix v2.0.1 +SUMMERCART (0.6.6)")
"""


def transformed():
    return transform_character_select(PRISTINE_SOURCE)


def execute_emitted_probe_formatter(transformed_boot, identifier):
    """Execute the emitted formatter loop with MIPS branch-delay semantics."""
    block = transformed_boot.split("        _format_probe_identifier:\n", 1)[1]
    block = block.split("        Render.draw_string", 1)[0]
    instructions = []
    labels = {"_format_probe_identifier": 0}
    for raw in block.splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.endswith(":"):
            labels[line[:-1]] = len(instructions)
            continue
        op, operands = line.split(None, 1) if " " in line else (line, "")
        instructions.append((op, [item.strip() for item in operands.split(",") if item]))

    registers = {"t0": identifier, "t1": 0, "t2": 8}
    output = bytearray(8)

    def value(operand):
        return registers[operand] if operand in registers else int(operand, 0)

    def execute_non_branch(instruction):
        op, args = instruction
        if op == "nop":
            return
        if op == "srl":
            registers[args[0]] = value(args[1]) >> int(args[2], 0)
        elif op == "sltiu":
            registers[args[0]] = int(value(args[1]) < int(args[2], 0))
        elif op == "addiu":
            registers[args[0]] = (value(args[1]) + int(args[2], 0)) & 0xFFFFFFFF
        elif op == "sb":
            output[registers[args[1].split("(", 1)[1][:-1]]] = value(args[0]) & 0xFF
        elif op == "sll":
            registers[args[0]] = (value(args[1]) << int(args[2], 0)) & 0xFFFFFFFF
        else:
            raise AssertionError(f"unsupported formatter op {op}")

    pc = 0
    while pc < len(instructions):
        op, args = instructions[pc]
        if op in {"bnez", "beqz"}:
            condition = value(args[0]) != 0
            if op == "beqz":
                condition = not condition
            execute_non_branch(instructions[pc + 1])
            pc = labels[args[1]] if condition else pc + 2
        else:
            execute_non_branch(instructions[pc])
            pc += 1
    return output.decode("ascii")


def test_title_version_displays_centered_raw_summercart_identifier():
    transformed_boot = preview_gate.transform_boot_title_diagnostic(PRISTINE_BOOT)

    assert transformed_boot.count(preview_gate.TITLE_DIAGNOSTIC_MARKER) == 1
    assert "jal     CharacterSelect.resolve_preview_workaround_" in transformed_boot
    assert "String.insert(\"Smash Remix v2.0.1 +SUMMERCART (0.6.6)\")" in transformed_boot
    assert "String.insert(\"[ID:00000000]\")" in transformed_boot
    assert "li      t0, CharacterSelect.css_preview_probe_identifier" in transformed_boot
    assert "li      t1, string_probe_identifier + 4" in transformed_boot
    assert "srl     t3, t0, 0x001C" in transformed_boot
    assert "sll     t0, t0, 0x0004" in transformed_boot
    assert "Render.draw_string(1, 3, string_probe_identifier" in transformed_boot


@pytest.mark.parametrize(
    ("identifier", "expected"),
    [
        (0x00000000, "00000000"),
        (0x53437632, "53437632"),
        (0xABCDEF01, "ABCDEF01"),
        (0xFFFFFFFF, "FFFFFFFF"),
    ],
)
def test_title_probe_formatter_executes_all_hexadecimal_classes(identifier, expected):
    transformed_boot = preview_gate.transform_boot_title_diagnostic(PRISTINE_BOOT)
    assert execute_emitted_probe_formatter(transformed_boot, identifier) == expected


def test_title_probe_formatter_test_is_mutation_sensitive():
    transformed_boot = preview_gate.transform_boot_title_diagnostic(PRISTINE_BOOT)
    mutated = transformed_boot.replace(
        "bnez    t4, _store_probe_digit",
        "beqz    t4, _store_probe_digit",
        1,
    )
    assert execute_emitted_probe_formatter(mutated, 0xABCDEF01) != "ABCDEF01"


def test_title_diagnostic_is_idempotent_and_rejects_marker_only_corruption():
    transformed_boot = preview_gate.transform_boot_title_diagnostic(PRISTINE_BOOT)
    assert preview_gate.transform_boot_title_diagnostic(transformed_boot) == transformed_boot

    corrupted = transformed_boot.replace(
        "srl     t3, t0, 0x001C",
        "srl     t3, t0, 0x0018",
        1,
    )
    with pytest.raises(ValueError, match="not canonical"):
        preview_gate.transform_boot_title_diagnostic(corrupted)


def test_preview_policy_defaults_to_auto_and_emits_three_modes():
    assert preview_gate.PREVIEW_POLICY_AUTO == 0
    assert preview_gate.PREVIEW_POLICY_FORCE_ON == 1
    assert preview_gate.PREVIEW_POLICY_FORCE_OFF == 2
    assert preview_gate.PREVIEW_POLICY == preview_gate.PREVIEW_POLICY_AUTO
    assert preview_gate.PREVIEW_PROBE_WAIT_EACH_IO is True

    asm = transformed()
    assert "constant CSS_PREVIEW_POLICY_AUTO(0)" in asm
    assert "constant CSS_PREVIEW_POLICY_FORCE_ON(1)" in asm
    assert "constant CSS_PREVIEW_POLICY_FORCE_OFF(2)" in asm
    assert f"constant CSS_PREVIEW_POLICY({preview_gate.PREVIEW_POLICY_AUTO})" in asm


def test_summercart_auto_probe_is_cached_and_uses_documented_identifier_protocol():
    asm = transformed()
    resolver = PreviewAsm(asm)._scope("resolve_preview_workaround_")
    assert "css_preview_workaround_enabled" in resolver
    assert "li      t1, CSS_PREVIEW_WORKAROUND_UNKNOWN" in resolver
    assert "lli     t1, CSS_PREVIEW_WORKAROUND_UNKNOWN" not in resolver
    assert "lui     t1, 0xBFFF" in resolver
    assert resolver.count("sw      ") >= 4
    assert sum(
        "sw      " in line and "0x0010(t1)" in line for line in resolver.splitlines()
    ) == 3
    assert "0x5F55" in resolver and "0x4E4C" in resolver
    assert "0x4F43" in resolver and "0x4B5F" in resolver
    assert "lw      t2, 0x000C(t1)" in resolver
    assert "css_preview_probe_identifier" in resolver
    assert resolver.index("lw      t2, 0x000C(t1)") < resolver.index("sw      t2, 0x0000(t3)")
    assert "0x5343" in resolver and "0x7632" in resolver


def test_summercart_probe_can_emit_wait_before_every_register_access(monkeypatch):
    monkeypatch.setattr(preview_gate, "PREVIEW_PROBE_WAIT_EACH_IO", True)
    resolver = PreviewAsm(transform_character_select(PRISTINE_SOURCE))._scope(
        "resolve_preview_workaround_"
    )

    assert "constant CSS_PREVIEW_WAIT_EACH_IO(1)" in transform_character_select(PRISTINE_SOURCE)
    assert "_wait_for_pi_unlock_1:" in resolver
    assert "_wait_for_pi_unlock_2:" in resolver
    assert "_wait_for_pi_identifier:" in resolver

    initial_wait = resolver.index("_wait_for_pi:")
    reset_write = resolver.index("sw      r0, 0x0010(t1)")
    unlock_1_wait = resolver.index("_wait_for_pi_unlock_1:")
    unlock_1_write = resolver.index("sw      t2, 0x0010(t1)", reset_write)
    unlock_2_wait = resolver.index("_wait_for_pi_unlock_2:")
    unlock_2_write = resolver.index("sw      t2, 0x0010(t1)", unlock_1_write + 1)
    identifier_wait = resolver.index("_wait_for_pi_identifier:")
    identifier_read = resolver.index("lw      t2, 0x000C(t1)")
    assert (
        initial_wait
        < reset_write
        < unlock_1_wait
        < unlock_1_write
        < unlock_2_wait
        < unlock_2_write
        < identifier_wait
        < identifier_read
    )
    for label, next_operation in (
        ("_wait_for_pi_unlock_1", unlock_1_write),
        ("_wait_for_pi_unlock_2", unlock_2_write),
        ("_wait_for_pi_identifier", identifier_read),
    ):
        wait_loop = resolver[resolver.index(f"{label}:"):next_operation]
        assert "lw      t2, 0x0010(t1)" in wait_loop
        assert "andi    t2, t2, 0x0003" in wait_loop
        assert f"bnez    t2, {label}" in wait_loop


def test_summercart_auto_probe_waits_for_pi_dma_and_io_idle():
    resolver = PreviewAsm(transformed())._scope("resolve_preview_workaround_")
    assert "lui     t1, 0xA460" in resolver
    assert "lw      t2, 0x0010(t1)" in resolver
    assert "andi    t2, t2, 0x0003" in resolver
    assert "bnez    t2, _wait_for_pi" in resolver


def test_auto_policy_enables_exact_summercart_and_caches_without_reprobing():
    h = PreviewAsm(transformed(), policy=preview_gate.PREVIEW_POLICY_AUTO)
    assert h.call_resolver() == 1
    assert h.mem[h.symbols["css_preview_probe_identifier"]] == 0x53437632
    key_writes = [event for event in h.events if event[0] == "sw" and event[1] == 0xBFFF0010]
    assert [event[2] for event in key_writes] == [0, 0x5F554E4C, 0x4F434B5F]

    h.mem[0xBFFF000C] = 0x000C000C
    assert h.call_resolver() == 1
    assert [event for event in h.events if event[0] == "sw" and event[1] == 0xBFFF0010] == key_writes


def test_auto_policy_disables_open_bus_and_force_modes_never_probe_cart():
    auto = PreviewAsm(
        transformed(), policy=preview_gate.PREVIEW_POLICY_AUTO, cart_identifier=0x000C000C
    )
    assert auto.call_resolver() == 0

    for policy, expected in (
        (preview_gate.PREVIEW_POLICY_FORCE_ON, 1),
        (preview_gate.PREVIEW_POLICY_FORCE_OFF, 0),
    ):
        h = PreviewAsm(transformed(), policy=policy, cart_identifier=0x53437632)
        assert h.call_resolver() == expected
        assert not [event for event in h.events if event[0] == "sw" and event[1] == 0xBFFF0010]


def test_disabled_policy_restores_stock_gate_selection_sync_and_indicator_paths():
    h = PreviewAsm(
        transformed(), policy=preview_gate.PREVIEW_POLICY_AUTO, cart_identifier=0x000C000C
    )
    assert h.call_gate()
    assert h.record() == (0xFF, 0, 0, 0)

    panel = h.symbols["CSS_PLAYER_STRUCT"]
    h.mem[panel + 8] = 0xA0000000
    result = h.call_select(0, held=0, selected=1)
    assert (result["v0"], result["v1"]) == h.native_selection_returns
    assert h.loads == 0 and h.mem[panel + 8] == 0xA0000000

    slots = h.symbols["dynamic_css.slot_used_by_port"]
    h.mem[slots + 4] = 0x44332211
    h.frame()
    assert h.mem[slots] == 0x44332211
    assert h.mem[h.symbols["css_preview_frame_serial"]] == 0

    indicator = transformed()[transformed().index("        _draw_indicator:"):]
    indicator = indicator[:indicator.index("        addiu   sp, sp,-0x0020")]
    assert "jal     resolve_preview_workaround_" in indicator
    assert "beqz    v0, _draw_stock_indicator" in indicator


def test_disabled_stock_bypasses_are_mutation_resistant():
    source = transformed()

    gate_scope = PreviewAsm(source)._scope("selected_preview_make_gate_")
    gate_branch = "        beqz    t5, _allow\n"
    assert gate_scope.count(gate_branch) == 1
    mutated_gate = source.replace(
        gate_scope, gate_scope.replace(gate_branch, "        bnez    t5, _allow\n", 1), 1
    )
    with pytest.raises(AssertionError):
        assert PreviewAsm(mutated_gate, cart_identifier=0x000C000C).call_gate()

    select_scope = PreviewAsm(source)._scope("selected_preview_on_select_")
    select_branch = "        beqz    t3, _stock_select\n"
    assert select_scope.count(select_branch) == 1
    mutated_select = source.replace(
        select_scope, select_scope.replace(select_branch, "        bnez    t3, _stock_select\n", 1), 1
    )
    selected = PreviewAsm(mutated_select, cart_identifier=0x000C000C)
    selected.call_select(0, held=0, selected=1)
    with pytest.raises(AssertionError):
        assert selected.loads == 0

    sync_scope = PreviewAsm(source)._scope("sync_slot_used_by_port")
    sync_branch = "        beqz    v0, _stock_sync\n"
    assert sync_scope.count(sync_branch) == 1
    mutated_sync = source.replace(
        sync_scope, sync_scope.replace(sync_branch, "        bnez    v0, _stock_sync\n", 1), 1
    )
    synced = PreviewAsm(mutated_sync, cart_identifier=0x000C000C)
    synced.frame()
    with pytest.raises(AssertionError):
        assert synced.mem[synced.symbols["css_preview_frame_serial"]] == 0


def test_invalid_internal_preview_policy_is_rejected(monkeypatch):
    monkeypatch.setattr(preview_gate, "PREVIEW_POLICY", 99)
    with pytest.raises(ValueError, match="invalid CSS preview policy: 99"):
        transform_character_select(PRISTINE_SOURCE)


def test_reclaimer_uses_character_select_scoped_reset_symbol():
    """The native recycler is scoped by CharacterSelect, not dynamic_css."""
    pristine_with_native_reset = PRISTINE_SOURCE.replace(
        "    }\n}\n} // __CHARACTER_SELECT__\n",
        """    }

    scope reset_heap_slot_: {
        jr      ra
        nop
    }
}
} // __CHARACTER_SELECT__
""",
        1,
    )
    assert "scope CharacterSelect {" in pristine_with_native_reset
    assert pristine_with_native_reset.count("scope reset_heap_slot_:") == 1

    reclaimer = PreviewAsm(transform_character_select(pristine_with_native_reset))._scope(
        "reclaim_retired_slot_"
    )
    assert reclaimer.count("jal     reset_heap_slot_") == 1
    assert "jal     dynamic_css.reset_heap_slot_" not in reclaimer


class BigEndianMemory:
    """Sparse, byte-addressed memory with word-compatible test access."""

    def __init__(self):
        self.bytes = {}

    def __contains__(self, address):
        return all((address + offset) in self.bytes for offset in range(4))

    def __getitem__(self, address):
        return self.read_word(address)

    def get(self, address, default=None):
        return self.read_word(address) if address in self else default

    def __setitem__(self, address, value):
        self.write_word(address, value)

    def __delitem__(self, address):
        for offset in range(4):
            self.bytes.pop(address + offset, None)

    def update(self, values):
        for address, value in values.items():
            self[address] = value

    def setdefault(self, address, default):
        if address not in self:
            self[address] = default
        return self[address]

    def read_word(self, address):
        assert address in self, f"unmapped lw {address:#x}"
        return sum(self.bytes[address + offset] << (24 - offset * 8) for offset in range(4))

    def read_byte(self, address):
        assert address in self.bytes, f"unmapped byte load {address:#x}"
        return self.bytes[address]

    def write_word(self, address, value):
        value &= 0xFFFFFFFF
        for offset in range(4):
            self.bytes[address + offset] = (value >> (24 - offset * 8)) & 0xFF

    def write_byte(self, address, value):
        self.bytes[address] = value & 0xFF


class PreviewAsm:
    """Small execution harness for the emitted gate/frame blocks, not a model."""

    REG = {"r0": "r0", "zero": "r0"}

    def __init__(self, asm, mismatch=None, post_gate_mismatch=None, *, spill_caller_home=False,
                 destroy_mutation=None, destroy_clobber_callers=False,
                 reset_mutation=None, reset_slot_effect=None, reset_clobber_callers=False,
                 policy=0, cart_identifier=0x53437632):
        self.asm = asm
        self.mismatch = mismatch
        self.post_gate_mismatch = post_gate_mismatch
        self.spill_caller_home = spill_caller_home
        self.destroy_mutation = destroy_mutation
        self.destroy_clobber_callers = destroy_clobber_callers
        self.reset_mutation = reset_mutation
        self.reset_slot_effect = reset_slot_effect
        self.reset_clobber_callers = reset_clobber_callers
        self.home_spills = 0
        self.loads = self.allows = self.sync_calls = 0
        self.load_ports = []
        self._next_link_id = 0
        self.obj = 0x90000000
        self.mem = BigEndianMemory()
        self.native_selection_returns = (0x12345678, 0x9ABCDEF0)
        self.native_selection_selected = 1
        self.gate_outcomes = []
        self.events = []
        self.destroy_calls = []
        self.reset_calls = []
        self.frame_serial = 0
        self.action_ledger = []
        self._callback_name = None
        self._callback_action = None
        self.symbols = {
            "CSS_PLAYER_STRUCT": 0x8013BA88,
            "css_preview_pending_character": 0x81000000,
            "css_preview_pending_variant": 0x81000004,
            "css_preview_frame_countdown": 0x81000008,
            "css_preview_state": 0x8100000C,
            # Legacy test helpers address the same global record fields.
            "p1_preview_pending_character": 0x81000000,
            "p1_preview_pending_variant": 0x81000004,
            "p1_preview_frame_countdown": 0x81000008,
            "p1_preview_state": 0x8100000C,
            "p1_preview_suppress_depth": 0x81000010,
            "forced_selected_preview_owner": 0x81000014,
            "dynamic_css.slot_used_by_port": 0x81000018,
            "dynamic_css.curr_slot_used_by_port": 0x8100001C,
            "ACTIVE_HEAP_COUNT": 5,
            "dynamic_css.ACTIVE_HEAP_COUNT": 5,
            "css_preview_owner": 0x81000020,
            "css_preview_policy_owner": 0x81000024,
            "css_preview_policy_generation": 0x81000028,
            "css_preview_request_generation": 0x8100002C,
            "css_preview_dispatch_state": 0x81000030,
            "css_preview_action": 0x81000034,
            "css_preview_frame_serial": 0x81000038,
            "css_preview_reclaim_cursor": 0x8100003C,
            "css_preview_slot_epochs": 0x81000040,
            "css_preview_retirement_character": 0x81000060,
            "css_preview_retirement_epoch": 0x81000080,
            "css_preview_retirement_frame": 0x810000A0,
            "css_preview_retirement_valid": 0x810000C0,
            "Character.id.NONE": 0xFF,
            "Character.id.PLACEHOLDER": 0xFE,
            "Character.NUM_CHARACTERS": 0x80,
            "CSS_PREVIEW_DEBOUNCE_FRAMES": 18,
            "CSS_PREVIEW_WAITING": 1,
            "CSS_PREVIEW_CONSTRUCTING": 2,
            "CSS_PREVIEW_VISIBLE": 3,
            "CSS_PREVIEW_REVOKE_PENDING": 4,
            "CSS_PREVIEW_DISPATCHING": 1,
            "CSS_PREVIEW_ACTION_NONE": 0,
            "CSS_PREVIEW_ACTION_REVOKE": 1,
            "CSS_PREVIEW_OWNER_INACTIVE": 0xFFFFFFFF,
            "CSS_PREVIEW_POLICY_AUTO": 0,
            "CSS_PREVIEW_POLICY_FORCE_ON": 1,
            "CSS_PREVIEW_POLICY_FORCE_OFF": 2,
            "CSS_PREVIEW_POLICY": policy,
            "CSS_PREVIEW_WORKAROUND_UNKNOWN": 0xFFFFFFFF,
            "CSS_PREVIEW_WORKAROUND_DISABLED": 0,
            "CSS_PREVIEW_WORKAROUND_ENABLED": 1,
            "css_preview_workaround_enabled": 0x810000E0,
            "css_preview_probe_identifier": 0x810000E4,
        }
        for slot in range(self.symbols["ACTIVE_HEAP_COUNT"]):
            self.symbols[f"dynamic_css.heap_slot_{slot}"] = 0x81000100 + slot * 0x10
        self.code = {name: self._parse(self._scope(name)) for name in
                     ("sync_slot_used_by_port", "selected_preview_on_select_",
                      "selected_preview_make_gate_", "css_preview_frame_",
                      "ordered_preview_owner_", "refresh_preview_policy_", "record_dynamic_slot_binding_",
                      "reclaim_retired_slot_", "resolve_preview_workaround_")}
        self.mem[self.symbols["css_preview_workaround_enabled"]] = 0xFFFFFFFF
        self.mem[self.symbols["css_preview_probe_identifier"]] = 0xFFFFFFFF
        self.mem[0xA4600010] = 0
        self.mem[0xBFFF000C] = cart_identifier
        self.mem[self.symbols["forced_selected_preview_owner"]] = 0xFFFFFFFF
        self.mem[self.symbols["css_preview_owner"]] = 0xFFFFFFFF
        self.mem[self.symbols["css_preview_policy_owner"]] = 0xFFFFFFFF
        self.mem[self.symbols["css_preview_policy_generation"]] = 0
        self.mem[self.symbols["css_preview_request_generation"]] = 0
        self.mem[self.symbols["css_preview_dispatch_state"]] = 0
        self.mem[self.symbols["css_preview_action"]] = 0
        self.mem[self.symbols["css_preview_frame_serial"]] = 0
        self.mem[self.symbols["css_preview_reclaim_cursor"]] = 0
        for slot in range(self.symbols["ACTIVE_HEAP_COUNT"]):
            for base in ("css_preview_slot_epochs", "css_preview_retirement_character",
                         "css_preview_retirement_epoch", "css_preview_retirement_frame",
                         "css_preview_retirement_valid"):
                self.mem[self.symbols[base] + slot * 4] = 0
        self.mem[self.symbols["p1_preview_suppress_depth"]] = 0
        self.mem[self.symbols["dynamic_css.slot_used_by_port"]] = 0
        self.mem[self.symbols["dynamic_css.slot_used_by_port"] + 4] = 0
        for player in range(4):
            self.set_panel(0x12 + player, 3, player=player)
        self.clear()

    def _scope(self, name):
        headers = list(re.finditer(rf"^\s*scope\s+{re.escape(name)}:\s*\{{", self.asm, re.MULTILINE))
        assert len(headers) == 1, f"expected one scope {name}, found {len(headers)}"
        start = headers[0].start()
        opening = self.asm.index("{", headers[0].start(), headers[0].end())
        depth = 0
        for offset in range(opening, len(self.asm)):
            char = self.asm[offset]
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    return self.asm[start:offset + 1]
        raise AssertionError(f"unclosed scope {name}")

    def _parse(self, text):
        out, labels = [], {}
        for raw in text.splitlines()[1:]:
            line = raw.split("//", 1)[0].strip()
            if not line or line.startswith(("scope ", "{{", "}}")):
                continue
            if line.endswith(":"):
                label = line[:-1].strip()
                assert label not in labels, f"duplicate label {label}"
                labels[label] = len(out)
                continue
            parts = line.split(None, 1)
            if len(parts) == 2:
                out.append((parts[0], [x.strip() for x in parts[1].split(",")]))
            elif parts:
                out.append((parts[0], []))
        return out, labels

    def val(self, value, regs):
        value = value.strip()
        if value == "r0" or value == "zero":
            return 0
        if value in regs:
            return regs[value]
        if re.fullmatch(r"(?:a|v|t|s)\d|sp|ra|at|lo", value):
            raise AssertionError(f"uninitialized register {value}")
        if value in self.symbols:
            return self.symbols[value]
        if value.startswith("0x"):
            return int(value, 16)
        return int(value, 10)

    def addr(self, operand, regs):
        match = re.fullmatch(r"(0x[0-9A-Fa-f]+|\d+)\((\w+)\)", operand)
        assert match, operand
        return (int(match.group(1), 0) + self.val(match.group(2), regs)) & 0xFFFFFFFF

    def set_panel(self, char, variant, *, selected=0, state=0, player=0):
        base = self.symbols["CSS_PLAYER_STRUCT"] + player * 0xBC
        self.mem[base + 0x48] = char
        self.mem[base + 0x4C] = variant
        self.mem[base + 0x58] = selected
        self.mem[base + 0x88] = selected
        self.mem[base + 0x84] = state
        self.mem.setdefault(base + 8, 0)

    def record(self):
        p = self.symbols["p1_preview_pending_character"]
        return tuple(self.mem.get(p + o, 0) for o in (0, 4, 8, 12))

    def global_record(self):
        return (self.mem[self.symbols["css_preview_owner"]], *self.record())

    def policy(self):
        return (self.mem[self.symbols["css_preview_policy_owner"]],
                self.mem[self.symbols["css_preview_policy_generation"]],
                self.mem[self.symbols["css_preview_request_generation"]])

    def clear(self):
        p = self.symbols["p1_preview_pending_character"]
        self.mem.update({p: 0xFF, p + 4: 0, p + 8: 0, p + 12: 0})
        self.mem[self.symbols["css_preview_owner"]] = 0xFFFFFFFF

    def seed_heap_slot(self, slot, primary, additional=()):
        assert 0 <= slot < self.symbols["ACTIVE_HEAP_COUNT"]
        assert len(additional) <= 4
        base = self.symbols[f"dynamic_css.heap_slot_{slot}"]
        self.mem[base + 4] = primary
        for offset in range(4):
            self.mem.write_byte(base + 8 + offset, additional[offset] if offset < len(additional) else 0)

    def read_heap_slot(self, slot):
        assert 0 <= slot < self.symbols["ACTIVE_HEAP_COUNT"]
        base = self.symbols[f"dynamic_css.heap_slot_{slot}"]
        return {"primary": self.mem[base + 4],
                "additional": tuple(self.mem.read_byte(base + 8 + offset) for offset in range(4))}

    def seed_protections(self, *, previous=(0xFF,) * 4, current=(0xFF,) * 4):
        assert len(previous) == len(current) == 4
        for base, values in ((self.symbols["dynamic_css.slot_used_by_port"], previous),
                             (self.symbols["dynamic_css.curr_slot_used_by_port"], current)):
            for offset, value in enumerate(values):
                self.mem.write_byte(base + offset, value)

    def read_protections(self):
        return tuple(tuple(self.mem.read_byte(base + offset) for offset in range(4)) for base in
                     (self.symbols["dynamic_css.slot_used_by_port"],
                      self.symbols["dynamic_css.curr_slot_used_by_port"]))

    def begin_frame(self, callback):
        self.frame_serial += 1
        self._callback_name = callback
        self._callback_action = None

    def record_lifecycle_action(self, action, *, nested=False):
        assert action in {"construct", "destroy", "reset/reclaim", "metadata_clear"}
        if self._callback_name is None:
            self.begin_frame("implicit")
        entry = {"frame": self.frame_serial, "callback": self._callback_name}
        if nested:
            entry["nested_attempted"] = action
        else:
            if self._callback_action == action:
                return
            assert self._callback_action is None, "one lifecycle action per modeled callback"
            self._callback_action = action
            entry["action"] = action
        self.action_ledger.append(entry)

    def call_gate(self, *, player=0, object=True, variant=None):
        base = self.symbols["CSS_PLAYER_STRUCT"] + player * 0xBC
        return self.run("selected_preview_make_gate_", {"a0": self.obj if object else 0,
                                                          "a1": player,
                                                          "v0": self.mem[base + 0x4C] if variant is None else variant,
                                                          "sp": 0x90010000, "ra": 0})

    def call_resolver(self):
        return self.run("resolve_preview_workaround_", {"sp": 0x90010000, "ra": 0})["v0"]

    def call_ordered_owner(self):
        return self.run("ordered_preview_owner_", {"ra": 0})["v1"]

    def frame(self, initial=None):
        self.sync_calls += 1
        if self.mem[self.symbols["css_preview_dispatch_state"]]:
            self.events.append("nested_frame")
        else:
            self.begin_frame("sync_slot_used_by_port")
        regs = {register: 0 for register in
                ("at", "a0", "a1", "a2", "a3", "v0", "v1", "t2", "t3", "t4", "t5", "t6", "t7", "t8", "t9")}
        regs.update({"sp": 0x90010000, "ra": 0})
        if initial:
            regs.update(initial)
        return self.run("sync_slot_used_by_port", regs, expected_link=regs["ra"])

    def call_select(self, puck, *, held, selected=None, outer_owner=0xFFFFFFFF):
        if selected is not None:
            self.native_selection_selected = selected
        puck_base = self.symbols["CSS_PLAYER_STRUCT"] + puck * 0xBC
        self.mem[puck_base + 0x80] = held
        self.mem[self.symbols["forced_selected_preview_owner"]] = outer_owner
        return self.run("selected_preview_on_select_", {
            "a0": puck, "a1": 0x11, "a2": 0x22, "a3": 0x33,
            "sp": 0x90010000, "ra": 0,
        })

    def _native_loader(self, regs):
        self.loads += 1
        self.record_lifecycle_action("construct")
        self.events.append("native_loader")
        if self.mismatch:
            self.mismatch(self)
        player = self.val("a0", regs)
        self.load_ports.append(player)
        base = self.symbols["CSS_PLAYER_STRUCT"] + player * 0xBC
        native_return_link = regs["ra"]
        native_regs = dict(regs)
        native_regs.update({"a0": self.obj, "a1": player, "v0": self.mem[base + 0x4C]})
        gate_link = self._new_link()
        native_regs["ra"] = gate_link
        outcome = self.run("selected_preview_make_gate_", native_regs, gate_link)
        regs["ra"] = native_return_link
        if outcome:
            self.mem[base + 8] = 0xA0000000
        if self.post_gate_mismatch:
            self.post_gate_mismatch(self)

    def _native_select(self, regs):
        held = self.mem[self.symbols["CSS_PLAYER_STRUCT"] + self.val("a0", regs) * 0xBC + 0x80]
        if 0 <= held < 4:
            self.mem[self.symbols["CSS_PLAYER_STRUCT"] + held * 0xBC + 0x58] = self.native_selection_selected
        regs["v0"], regs["v1"] = self.native_selection_returns

    def _native_destroy(self, regs):
        gobj = self.val("a0", regs)
        panel = next((self.symbols["CSS_PLAYER_STRUCT"] + player * 0xBC for player in range(4)
                      if self.mem.get(self.symbols["CSS_PLAYER_STRUCT"] + player * 0xBC + 8) == gobj), None)
        player = None if panel is None else (panel - self.symbols["CSS_PLAYER_STRUCT"]) // 0xBC
        call = {"a0": gobj, "panel": panel,
                "current_slot": None if player is None else self.mem.read_byte(
                    self.symbols["dynamic_css.curr_slot_used_by_port"] + player),
                "frame_serial": self.frame_serial, "event_index": len(self.events)}
        self.destroy_calls.append(call)
        self.events.append(("destroy", call))
        self.record_lifecycle_action("destroy")
        if self.destroy_mutation:
            self.events.append(("destroy_callback", call))
            self.destroy_mutation(self)
        if self.destroy_clobber_callers:
            caller_saved = ("at", "v0", "v1", "a0", "a1", "a2", "a3",
                            "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "t8", "t9")
            for index, register in enumerate(caller_saved):
                regs[register] = 0xC10B0000 | index

    def _native_reset(self, regs):
        slot = self.val("a0", regs)
        call = {"a0": slot, "frame_serial": self.frame_serial, "event_index": len(self.events)}
        self.reset_calls.append(call)
        self.events.append(("reset", call))
        self.record_lifecycle_action("reset/reclaim")
        if self.reset_mutation:
            self.events.append(("reset_callback", call))
            self.reset_mutation(self)
        if self.reset_slot_effect:
            self.reset_slot_effect(self, slot)
        if self.reset_clobber_callers:
            caller_saved = ("at", "v0", "v1", "a0", "a1", "a2", "a3",
                            "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "t8", "t9")
            for index, register in enumerate(caller_saved):
                regs[register] = 0xC10C0000 | index

    def _new_link(self):
        self._next_link_id += 1
        return 0xF0000000 + self._next_link_id

    def _assert_return_link(self, name, regs, expected_link):
        assert regs["ra"] == expected_link, (
            f"wrong return link in {name}: expected {expected_link!r}, got {regs['ra']!r}"
        )

    def _spill_caller_home(self, regs):
        """Model o32's callee-owned 16-byte caller home area at every jal."""
        if not self.spill_caller_home:
            return
        sp = self.val("sp", regs)
        self.home_spills += 1
        for word, offset in enumerate((0, 4, 8, 12)):
            self.mem[(sp + offset) & 0xFFFFFFFF] = 0xC0110000 | (self.home_spills << 4) | word

    def run(self, name, initial, expected_link=None):
        if expected_link is None:
            self.begin_frame(name)
        code, labels = self.code[name]
        regs = initial
        if expected_link is None:
            expected_link = self.val("ra", regs)
        pc = 0
        outcome = False

        def delay():
            nonlocal pc
            pc += 1
            assert pc < len(code), f"missing delay slot in {name}"
            self._one(code[pc], regs)

        while pc < len(code):
            op, args = code[pc]
            if op in {"beq", "bne", "beqz", "bnez", "b"}:
                take = (op == "b" or
                        (op == "beq" and self.val(args[0], regs) == self.val(args[1], regs)) or
                        (op == "bne" and self.val(args[0], regs) != self.val(args[1], regs)) or
                        (op == "beqz" and self.val(args[0], regs) == 0) or
                        (op == "bnez" and self.val(args[0], regs) != 0))
                target = args[-1]
                delay(); pc = labels[target] if take else pc + 1
                continue
            if op in {"jal", "j", "jr"}:
                target = args[0]
                link = self._new_link() if op == "jal" else None
                if link is not None:
                    regs["ra"] = link
                delay()
                if op == "jal":
                    self._spill_caller_home(regs)
                if op == "jal" and target in self.code:
                    self.run(target, regs, link)
                elif op == "jal" and target == "0x80136128":
                    self._native_loader(regs)
                elif op == "jal" and target == "0x80131C74":
                    self._native_select(regs)
                elif op == "jal" and target == "0x800D78E8":
                    self._native_destroy(regs)
                elif op == "jal" and target == "reset_heap_slot_":
                    self._native_reset(regs)
                elif op == "j" and target == "0x80134A8C":
                    self._assert_return_link(name, regs, expected_link)
                    self.allows += 1
                    self.gate_outcomes.append(True)
                    return True if name == "selected_preview_make_gate_" else regs
                elif op == "j" and target == "0x80131C74":
                    self._native_select(regs)
                    self._assert_return_link(name, regs, expected_link)
                    return regs
                elif op == "jr":
                    assert target == "ra", f"unsupported jr target {target}"
                    self._assert_return_link(name, regs, expected_link)
                    return outcome if name == "selected_preview_make_gate_" else regs
                elif op == "jal":
                    raise AssertionError(f"unsupported native call {target}")
                else:
                    pc = labels[target]
                    continue
                pc += 1
                continue
            self._one((op, args), regs); pc += 1
        return outcome if name == "selected_preview_make_gate_" else regs

    def _one(self, ins, regs):
        op, a = ins
        if op == "nop": return
        if op in {"li", "lli"}: regs[a[0]] = self.val(a[1], regs)
        elif op == "lui": regs[a[0]] = (self.val(a[1], regs) << 16) & 0xFFFFFFFF
        elif op == "lw":
            address = self.addr(a[1], regs)
            assert address in self.mem, f"unmapped lw {address:#x}"
            regs[a[0]] = self.mem[address]
        elif op == "lbu":
            regs[a[0]] = self.mem.read_byte(self.addr(a[1], regs))
        elif op == "lb":
            value = self.mem.read_byte(self.addr(a[1], regs))
            regs[a[0]] = value | 0xFFFFFF00 if value & 0x80 else value
        elif op == "sw":
            address = self.addr(a[1], regs)
            value = self.val(a[0], regs) & 0xFFFFFFFF
            self.mem[address] = value
            if address == self.symbols["css_preview_frame_serial"]:
                self.frame_serial = value
            self.events.append(("sw", address, value))
        elif op == "sb":
            address = self.addr(a[1], regs)
            value = self.val(a[0], regs)
            self.mem.write_byte(address, value)
            self.events.append(("sb", address, value & 0xFF))
        elif op in {"or", "ori"}: regs[a[0]] = self.val(a[1], regs) | self.val(a[2], regs)
        elif op == "andi": regs[a[0]] = self.val(a[1], regs) & self.val(a[2], regs)
        elif op == "addu": regs[a[0]] = (self.val(a[1], regs) + self.val(a[2], regs)) & 0xFFFFFFFF
        elif op == "subu": regs[a[0]] = (self.val(a[1], regs) - self.val(a[2], regs)) & 0xFFFFFFFF
        elif op == "addiu": regs[a[0]] = (self.val(a[1], regs) + int(a[2], 0)) & 0xFFFFFFFF
        elif op == "sltiu": regs[a[0]] = int(self.val(a[1], regs) < self.val(a[2], regs))
        elif op == "sltu": regs[a[0]] = int(self.val(a[1], regs) < self.val(a[2], regs))
        elif op == "sll": regs[a[0]] = (self.val(a[1], regs) << int(a[2], 0)) & 0xFFFFFFFF
        elif op == "multu": regs["lo"] = self.val(a[0], regs) * self.val(a[1], regs)
        elif op == "mflo": regs[a[0]] = self.val("lo", regs)
        else: raise AssertionError(f"unsupported emitted op {op}")


def test_scope_parser_extracts_only_its_balanced_scope_and_rejects_unclosed_scope():
    h = PreviewAsm(transformed())
    sync = h._scope("sync_slot_used_by_port")
    gate = h._scope("selected_preview_make_gate_")
    assert "jal     css_preview_frame_" in sync
    assert "scope selected_preview_on_select_" not in sync
    assert "scope css_preview_frame_" not in sync
    assert "j       0x80134A8C" in gate
    assert "scope css_preview_frame_" not in gate
    with pytest.raises(AssertionError, match="unclosed scope"):
        h.asm += "\nscope malformed: {\n    nop\n"
        h._scope("malformed")


def test_harness_mutation_sensitivity_proves_zero_guard_is_executed():
    # The intentionally removed emitted guard must make the real behavior fail.
    asm = transformed().replace("        beqz    t5, _clear                // malformed WAITING zero must clear, never underflow\n", "", 1)
    h = PreviewAsm(asm)
    h.call_gate()
    p = h.symbols["p1_preview_pending_character"]
    h.mem[p + 8] = 0
    h.frame()
    with pytest.raises(AssertionError):
        assert h.record() == (0xFF, 0, 0, 0)


def test_p1_gate_and_frame_execute_exact_waiting_debounce_lifecycle():
    h = PreviewAsm(transformed())
    h.call_gate()
    assert h.record() == (0x12, 3, 18, 1)
    assert h.mem[h.obj + 0x7C] == 1
    h.call_gate()
    assert h.record() == (0x12, 3, 18, 1)  # gate calls never tick
    for _ in range(17): h.frame()
    assert h.loads == 0 and h.record() == (0x12, 3, 1, 1)
    h.frame()
    assert h.loads == 1 and h.record() == (0x12, 3, 0, 3)
    for _ in range(20): h.frame()
    assert h.loads == 1 and h.record() == (0x12, 3, 0, 3)


def test_global_record_schedules_p2_after_selected_p1_for_exact_18_frame_lifecycle():
    h = PreviewAsm(transformed())
    h.set_panel(0x12, 3, player=0, selected=1)
    h.set_panel(0x27, 6, player=1, selected=0)

    assert not h.call_gate(player=1)
    assert h.global_record() == (1, 0x27, 6, 18, 1)
    assert h.mem[h.obj + 0x7C] == 1

    for _ in range(17):
        h.frame()
    assert h.loads == 0 and h.global_record() == (1, 0x27, 6, 1, 1)

    h.frame()
    assert h.loads == 1 and h.load_ports == [1]
    assert h.global_record() == (1, 0x27, 6, 0, 3)
    assert h.mem[h.symbols["CSS_PLAYER_STRUCT"] + 0xBC + 8] == 0xA0000000

    for _ in range(20):
        h.frame()
    assert h.loads == 1 and h.load_ports == [1]


def test_global_record_schedules_p3_after_selected_p1_p2_for_exact_18_frame_lifecycle():
    h = PreviewAsm(transformed())
    h.set_panel(0x12, 3, player=0, selected=1)
    h.set_panel(0x27, 6, player=1, selected=1)
    h.set_panel(0x31, 2, player=2, selected=0)

    assert not h.call_gate(player=2)
    assert h.global_record() == (2, 0x31, 2, 18, 1)

    for _ in range(17):
        h.frame()
    assert h.loads == 0 and h.global_record() == (2, 0x31, 2, 1, 1)

    h.frame()
    assert h.loads == 1 and h.load_ports == [2]
    assert h.global_record() == (2, 0x31, 2, 0, 3)


def test_p4_gate_is_denied_until_fixed_prefix_selects_then_admits_policy_owner_three():
    h = PreviewAsm(transformed())
    h.set_panel(0x3A, 5, player=3, selected=0)
    assert not h.call_gate(player=3)
    assert h.global_record() == (0xFFFFFFFF, 0xFF, 0, 0, 0)

    for player in range(3):
        h.set_panel(0x20 + player, player, player=player, selected=1)
    assert h.call_ordered_owner() == 3
    assert not h.call_gate(player=3)
    assert h.global_record() == (3, 0x3A, 5, 18, 1)


def test_p4_debounce_keeps_identical_request_and_restarts_character_or_variant():
    h = PreviewAsm(transformed())
    for player in range(3):
        h.set_panel(0x20 + player, player, player=player, selected=1)
    h.set_panel(0x3A, 5, player=3, selected=0)
    h.call_gate(player=3)
    assert h.global_record() == (3, 0x3A, 5, 18, 1)
    h.frame()
    assert h.global_record() == (3, 0x3A, 5, 17, 1)
    h.call_gate(player=3)
    assert h.global_record() == (3, 0x3A, 5, 17, 1)
    h.set_panel(0x3B, 5, player=3, selected=0)
    h.call_gate(player=3)
    assert h.global_record() == (3, 0x3B, 5, 18, 1)
    h.frame()
    h.set_panel(0x3B, 6, player=3, selected=0)
    h.call_gate(player=3)
    assert h.global_record() == (3, 0x3B, 6, 18, 1)


def test_p4_expiry_uses_native_loader_once_with_owner_and_revalidation():
    h = PreviewAsm(transformed())
    for player in range(3):
        h.set_panel(0x20 + player, player, player=player, selected=1)
    h.set_panel(0x3A, 5, player=3, selected=0)
    h.call_gate(player=3)
    for _ in range(18):
        h.frame()
    assert h.loads == 1 and h.load_ports == [3]
    assert h.global_record() == (3, 0x3A, 5, 0, 3)
    assert h.mem[h.symbols["CSS_PLAYER_STRUCT"] + 3 * 0xBC + 8] == 0xA0000000

    stale = PreviewAsm(transformed(), post_gate_mismatch=lambda x: x.mem.__setitem__(
        x.symbols["css_preview_policy_generation"], 99
    ))
    for player in range(3):
        stale.set_panel(0x20 + player, player, player=player, selected=1)
    stale.set_panel(0x3A, 5, player=3, selected=0)
    stale.call_gate(player=3)
    for _ in range(18):
        stale.frame()
    assert stale.loads == 1 and stale.load_ports == [3]
    assert_scheduler_metadata_cleared(stale)


def test_selecting_visible_p4_preserves_fighter_and_advances_policy_inactive():
    h = PreviewAsm(transformed())
    panel = seed_visible_preview(h, owner=3, character=0x3A, slot=2, epoch=0x44)
    result = h.call_select(3, held=3, selected=1)
    assert (result["v0"], result["v1"]) == h.native_selection_returns
    assert h.policy()[0] == 0xFFFFFFFF
    assert h.destroy_calls == []
    assert h.mem[panel + 8] == 0xA0000000
    h.frame()
    assert h.global_record()[0] == 3
    assert h.destroy_calls == [] and h.mem[panel + 8] == 0xA0000000


def test_stationary_unselected_p4_revokes_through_destroy_before_clear_on_prerequisite_loss():
    h = PreviewAsm(transformed())
    panel = seed_visible_preview(h, owner=3, character=0x3A, slot=2, epoch=0x44)
    p2 = h.symbols["CSS_PLAYER_STRUCT"] + 0xBC
    h.mem[p2 + 0x58] = h.mem[p2 + 0x88] = 0
    h.frame()
    assert len(h.destroy_calls) == 1
    call = h.destroy_calls[0]
    assert call["panel"] == panel and call["a0"] == 0xA0B0C0D0
    assert h.events.index(("destroy", call)) < h.events.index(("sw", panel + 8, 0))
    assert h.mem[panel + 8] == 0 and retirement(h, 2)[:2] == (0x3A, 0x44)
    assert_scheduler_metadata_cleared(h)


def test_p4_dynamic_retirement_publishes_valid_last_and_reclaims_with_existing_checks():
    h = PreviewAsm(transformed())
    seed_visible_preview(h, owner=3, character=0x3A, slot=2, epoch=0x44)
    h.seed_heap_slot(2, 0x3A)
    p2 = h.symbols["CSS_PLAYER_STRUCT"] + 0xBC
    h.mem[p2 + 0x58] = h.mem[p2 + 0x88] = 0
    h.frame()
    assert retirement(h, 2)[3] == 1
    assert h.reset_calls == []
    h.seed_protections()
    h.frame(); h.frame()
    assert [call["a0"] for call in h.reset_calls] == [2]
    assert retirement(h, 2)[3] == 0


@pytest.mark.parametrize("variant", (0, 6), ids=("a", "c"))
def test_forced_p4_selection_without_hover_records_shared_dynamic_binding_epoch(variant):
    h = PreviewAsm(transformed())
    for player in range(3):
        h.set_panel(0x20 + player, player, player=player, selected=1)
    h.set_panel(0x3A, variant, player=3, selected=0)
    h.mem.write_byte(h.symbols["dynamic_css.curr_slot_used_by_port"] + 3, 1)
    assert h.mem[h.symbols["CSS_PLAYER_STRUCT"] + 3 * 0xBC + 8] == 0
    h.call_select(3, held=3, selected=1)
    assert h.mem[h.symbols["css_preview_slot_epochs"] + 4] == 1


def test_p4_nested_loader_destructor_and_reset_callbacks_cannot_gain_lifecycle_authority():
    loader = PreviewAsm(transformed(), mismatch=lambda x: x.frame())
    for player in range(3):
        loader.set_panel(0x20 + player, player, player=player, selected=1)
    loader.set_panel(0x3A, 5, player=3, selected=0)
    loader.call_gate(player=3)
    for _ in range(18): loader.frame()
    assert loader.loads == 1 and loader.events.count("nested_frame") == 1

    destroy = PreviewAsm(transformed(), destroy_mutation=lambda x: x.frame())
    seed_visible_preview(destroy, owner=3, character=0x3A, slot=2, epoch=0x44)
    p2 = destroy.symbols["CSS_PLAYER_STRUCT"] + 0xBC
    destroy.mem[p2 + 0x58] = destroy.mem[p2 + 0x88] = 0
    destroy.frame()
    assert len(destroy.destroy_calls) == 1 and destroy.events.count("nested_frame") == 1

    reset = PreviewAsm(transformed(), reset_mutation=lambda x: x.frame())
    reset.seed_heap_slot(2, 0x3A); reset.seed_protections(); seed_retirement(reset, 2, 0x3A, epoch=0x44)
    reset.mem[reset.symbols["css_preview_reclaim_cursor"]] = 2
    reset.frame()
    assert [call["a0"] for call in reset.reset_calls] == [2]
    assert reset.events.count("nested_frame") == 1


def test_each_widened_owner_bound_mutation_breaks_its_p4_path_but_not_p1_p3_controls():
    source = transformed()
    targets = {
        "gate": "        sltiu   t5, v1, 0x0004           // P1/P2/P3/P4 can own the one global record.\n",
        "visible": "        _visible:\n        li      t4, css_preview_owner\n        lw      t5, 0x0000(t4)\n        sltiu   t6, t5, 0x0004\n",
        "waiting": "        _waiting:\n        li      t4, css_preview_owner\n        lw      t5, 0x0000(t4)\n        sltiu   t6, t5, 0x0004\n",
        "constructing": "        lli     t4, CSS_PREVIEW_CONSTRUCTING\n        bne     t3, t4, _return          // nested mismatch preserved newest request\n        nop\n        li      t4, css_preview_owner\n        lw      t5, 0x0000(t4)\n        sltiu   t6, t5, 0x0004\n",
    }

    def p4(asm, phase):
        h = PreviewAsm(asm)
        for player in range(3):
            h.set_panel(0x20 + player, player, player=player, selected=1)
        h.set_panel(0x3A, 5, player=3, selected=0)
        if phase == "visible":
            seed_visible_preview(h, owner=3, character=0x3A, slot=2, epoch=0x44)
            h.frame()
            return h.global_record()[0] == 3
        h.call_gate(player=3)
        if phase == "gate":
            return h.global_record()[0] == 3
        h.frame()
        if phase == "waiting":
            return h.global_record()[-2:] == (17, 1)
        for _ in range(17): h.frame()
        return h.global_record() == (3, 0x3A, 5, 0, 3)

    for phase, target in targets.items():
        assert source.count(target) == 1, phase
        mutated = source.replace(target, target.replace("0x0004", "0x0003"), 1)
        with pytest.raises(AssertionError):
            assert p4(mutated, phase)
        control = PreviewAsm(mutated)
        control.set_panel(0x20, 0, player=0, selected=1)
        control.set_panel(0x21, 1, player=1, selected=1)
        control.set_panel(0x31, 2, player=2, selected=0)
        control.call_gate(player=2)
        assert control.global_record()[0] == 2


def test_p1_then_p2_selection_handoffs_preserve_selected_objects_and_advance_policy_generation():
    h = PreviewAsm(transformed())
    h.call_gate()
    assert h.policy() == (0, 1, 1)

    h.call_select(0, held=0, selected=1)
    p1_object = h.mem[h.symbols["CSS_PLAYER_STRUCT"] + 8]
    assert p1_object == 0xA0000000
    assert h.policy() == (1, 2, 0)

    h.set_panel(0x27, 6, player=1, selected=0)
    h.call_gate(player=1)
    assert h.global_record() == (1, 0x27, 6, 18, 1)
    assert h.policy() == (1, 2, 2)

    h.call_select(1, held=1, selected=1)
    assert h.mem[h.symbols["CSS_PLAYER_STRUCT"] + 8] == p1_object
    assert h.mem[h.symbols["CSS_PLAYER_STRUCT"] + 0xBC + 8] == 0xA0000000
    assert h.policy() == (2, 3, 0)


def test_sync_scope_owns_lifecycle_clock_and_calls_helper_exactly_once():
    asm = transformed()
    h = PreviewAsm(asm)
    slot = h.symbols["dynamic_css.slot_used_by_port"]
    h.mem[slot + 4] = 0x42
    h.call_gate()
    h.frame()
    assert h.mem[slot] == 0x42
    assert h.sync_calls == 1 and h.record() == (0x12, 3, 17, 1)

    without_call = PreviewAsm(asm.replace("        jal     css_preview_frame_\n", "", 1))
    without_call.call_gate()
    for _ in range(18):
        without_call.frame()
    assert without_call.loads == 0 and without_call.record() == (0x12, 3, 18, 1)

    duplicate_call = PreviewAsm(asm.replace("        jal     css_preview_frame_\n", "        jal     css_preview_frame_\n        nop\n        jal     css_preview_frame_\n", 1))
    duplicate_call.call_gate()
    for _ in range(9):
        duplicate_call.frame()
    assert duplicate_call.loads == 1


def test_gate_request_changes_and_nested_construction_are_executed_from_assembly():
    h = PreviewAsm(transformed())
    h.call_gate(); h.set_panel(0x13, 3); h.call_gate()
    assert h.record() == (0x13, 3, 18, 1)
    h.set_panel(0x13, 4); h.call_gate()
    assert h.record() == (0x13, 4, 18, 1)
    h.mem[h.symbols["p1_preview_state"]] = 2
    h.call_gate()
    assert h.allows == 1 and h.record() == (0x13, 4, 18, 2)


def test_nested_mismatch_restarts_newest_request_and_prevents_stale_publish():
    fired = []
    def mismatch(h):
        if not fired:
            fired.append(True); h.set_panel(0x21, 7)
    h = PreviewAsm(transformed(), mismatch)
    h.call_gate()
    for _ in range(18): h.frame()
    assert h.loads == 1 and h.record() == (0x21, 7, 18, 1)
    assert h.mem[h.symbols["CSS_PLAYER_STRUCT"] + 8] == 0


def test_native_loader_policy_owner_mutation_clears_stale_metadata_without_destroying_produced_object():
    def mutate_policy_owner(h):
        h.mem[h.symbols["css_preview_policy_owner"]] = 1

    h = PreviewAsm(transformed(), post_gate_mismatch=mutate_policy_owner)
    h.call_gate()
    for _ in range(18):
        h.frame()
    assert h.global_record() == (0xFFFFFFFF, 0xFF, 0, 0, 0)
    assert h.policy()[2] == 0
    assert h.mem[h.symbols["CSS_PLAYER_STRUCT"] + 8] == 0xA0000000


def assert_scheduler_metadata_cleared(h):
    assert h.global_record() == (0xFFFFFFFF, 0xFF, 0, 0, 0)
    assert h.mem[h.symbols["css_preview_request_generation"]] == 0


def assert_preselection_request_generation_reset(events, request_generation):
    native_loader_index = events.index("native_loader")
    request_reset = ("sw", request_generation, 0)
    assert events[:native_loader_index].count(request_reset) == 1, (
        "pre-selection cleanup must reset request generation before native_loader"
    )


def test_preselection_cleanup_clears_request_generation_before_forced_native_update():
    h = PreviewAsm(transformed())
    h.call_gate()
    h.mem[h.symbols["css_preview_request_generation"]] = 0x13579BDF
    event_start = len(h.events)

    h.call_select(0, held=0, selected=0)

    assert_scheduler_metadata_cleared(h)
    assert_preselection_request_generation_reset(
        h.events[event_start:], h.symbols["css_preview_request_generation"]
    )


def test_preselection_reset_assertion_rejects_removal_of_its_specific_store():
    source = transformed()
    preselection_generation_reset = (
        "        li      t2, css_preview_request_generation\n"
        "        sw      r0, 0x0000(t2)\n"
        "        _keep_p1_scheduler:\n"
    )
    assert source.count(preselection_generation_reset) == 1
    mutated = source.replace(preselection_generation_reset, "        _keep_p1_scheduler:\n", 1)
    h = PreviewAsm(mutated)
    h.call_gate()
    h.mem[h.symbols["css_preview_request_generation"]] = 0x13579BDF
    event_start = len(h.events)

    h.call_select(0, held=0, selected=0)

    assert_scheduler_metadata_cleared(h)
    with pytest.raises(AssertionError, match="pre-selection cleanup"):
        assert_preselection_request_generation_reset(
            h.events[event_start:], h.symbols["css_preview_request_generation"]
        )


def test_cancel_and_allow_clears_request_generation_with_scheduler_metadata():
    h = PreviewAsm(transformed())
    h.call_gate()
    h.mem[h.symbols["css_preview_request_generation"]] = 0x2468ACE0
    h.mem[h.symbols["forced_selected_preview_owner"]] = 0

    assert h.call_gate()

    assert_scheduler_metadata_cleared(h)


def test_cancel_p1_clears_request_generation_with_scheduler_metadata():
    h = PreviewAsm(transformed())
    h.call_gate()
    h.mem[h.symbols["css_preview_request_generation"]] = 0xDEADBEEF
    h.mem[h.symbols["p1_preview_suppress_depth"]] = 1

    assert not h.call_gate()

    assert_scheduler_metadata_cleared(h)


@pytest.mark.parametrize("selected,state,char", [(1, 0, 0x12), (0, 2, 0x12), (0, 0, 0xFF), (0, 0, 0xFE)])
def test_p1_cancellation_paths_clear_all_concrete_scheduler_words(selected, state, char):
    h = PreviewAsm(transformed()); h.call_gate()
    h.set_panel(char, 3, selected=selected, state=state)
    h.call_gate()
    assert h.record() == (0xFF, 0, 0, 0)


def test_p1_selected_and_forced_owner_unselected_allow_after_cancelling_waiting_record():
    h = PreviewAsm(transformed())
    h.call_gate()
    h.set_panel(0x12, 3, selected=1)
    assert h.call_gate() and h.record() == (0xFF, 0, 0, 0)

    h.call_gate()
    h.set_panel(0x12, 3, selected=0)
    h.mem[h.symbols["forced_selected_preview_owner"]] = 0
    assert h.call_gate() and h.record() == (0xFF, 0, 0, 0)


def test_p1_forced_and_suppressed_paths_clear_all_concrete_scheduler_words():
    h = PreviewAsm(transformed()); h.call_gate()
    h.mem[h.symbols["forced_selected_preview_owner"]] = 0; h.call_gate()
    assert h.record() == (0xFF, 0, 0, 0) and h.allows == 1
    h.call_gate(); h.mem[h.symbols["p1_preview_suppress_depth"]] = 1; h.call_gate()
    assert h.record() == (0xFF, 0, 0, 0)


def test_mflo_requires_initialized_lo_register():
    with pytest.raises(AssertionError, match="uninitialized register lo"):
        PreviewAsm(transformed())._one(("mflo", ["t1"]), {})


def test_waiting_zero_is_cleared_by_executed_helper_before_underflow():
    h = PreviewAsm(transformed()); h.call_gate()
    h.mem[h.symbols["p1_preview_pending_character"] + 8] = 0
    h.frame()
    assert h.record() == (0xFF, 0, 0, 0) and h.loads == 0


def test_deferred_request_with_advanced_policy_generation_clears_metadata_before_native_construction():
    h = PreviewAsm(transformed())
    h.call_gate()
    h.mem[h.symbols["css_preview_policy_generation"]] += 1
    for _ in range(18):
        h.frame()
    assert h.global_record() == (0xFFFFFFFF, 0xFF, 0, 0, 0)
    assert h.loads == 0


def test_selection_wrapper_forces_exact_owner_restores_it_and_preserves_native_returns():
    h = PreviewAsm(transformed())
    h.call_gate()
    result = h.call_select(0, held=0, selected=1, outer_owner=2)
    assert (result["v0"], result["v1"]) == h.native_selection_returns
    assert h.mem[h.symbols["forced_selected_preview_owner"]] == 2
    assert h.mem[h.symbols["CSS_PLAYER_STRUCT"] + 8] == 0xA0000000
    assert h.record() == (0xFF, 0, 0, 0)

    h.call_gate()
    result = h.call_select(0, held=0, selected=0, outer_owner=3)
    assert (result["v0"], result["v1"]) == h.native_selection_returns
    assert h.mem[h.symbols["forced_selected_preview_owner"]] == 3
    assert h.mem[h.symbols["p1_preview_suppress_depth"]] == 0

    h.call_gate(); before = h.record()
    h.set_panel(0x22, 1, player=1)
    h.call_select(1, held=1, selected=1, outer_owner=0xFFFFFFFF)
    assert h.record() == before

    h.call_gate(); before = h.record()
    result = h.call_select(0, held=4, selected=1, outer_owner=1)
    assert (result["v0"], result["v1"]) == h.native_selection_returns
    assert h.record() == before
    assert h.mem[h.symbols["forced_selected_preview_owner"]] == 1


@pytest.mark.parametrize(
    ("removed", "assertion"),
    [
        ("        sw      t1, 0x0000(t2)           // balanced restoration preserves an outer owner\n",
         lambda h: h.mem[h.symbols["forced_selected_preview_owner"]] == 2),
        ("        sw      t3, 0x0000(t2)\n\n        _return:",
         lambda h: h.mem[h.symbols["p1_preview_suppress_depth"]] == 0),
    ],
)
def test_selection_wrapper_mutations_are_observable(removed, assertion):
    asm = transformed().replace(removed, "\n" if "_return" not in removed else "\n        _return:", 1)
    h = PreviewAsm(asm)
    if "restoration" in removed:
        h.call_select(0, held=0, selected=1, outer_owner=2)
    else:
        h.call_select(0, held=0, selected=0, outer_owner=0xFFFFFFFF)
    with pytest.raises(AssertionError):
        assert assertion(h)


@pytest.mark.parametrize(
    ("scope_name", "restore", "exercise"),
    [
        ("sync_slot_used_by_port", "        lw      ra, 0x002C(sp)\n",
         lambda h: (h.call_gate(), h.frame())),
        ("css_preview_frame_", "        lw      ra, 0x007C(sp)\n",
         lambda h: (h.call_gate(), [h.frame() for _ in range(18)])),
        ("selected_preview_on_select_", "        lw      ra, 0x003C(sp)\n",
         lambda h: h.call_select(0, held=0, selected=1)),
    ],
)
def test_saved_ra_restoration_mutations_raise_wrong_return_link(scope_name, restore, exercise):
    asm = transformed()
    scope = PreviewAsm(asm)._scope(scope_name)
    assert scope.count(restore) == 1
    mutated_scope = scope.replace(restore, "", 1)
    assert mutated_scope.count(restore) == 0
    mutated = asm.replace(scope, mutated_scope, 1)
    assert mutated != asm

    with pytest.raises(AssertionError, match="wrong return link"):
        exercise(PreviewAsm(mutated))


def test_duplicate_label_in_one_extracted_scope_is_rejected_before_execution():
    asm = transformed()
    scope = PreviewAsm(asm)._scope("css_preview_frame_")
    label = "        _clear:\n"
    assert scope.count(label) == 1
    mutated_scope = scope.replace(label, f"{label}{label}", 1)
    assert mutated_scope.count(label) == 2
    mutated = asm.replace(scope, mutated_scope, 1)

    with pytest.raises(AssertionError, match="duplicate label _clear"):
        PreviewAsm(mutated)


def test_p2_to_p4_selected_only_gate_does_not_touch_p1_scheduler():
    h = PreviewAsm(transformed()); h.call_gate(); before = h.record()
    for player in (1, 2, 3):
        h.set_panel(0x20 + player, 1, player=player, selected=0)
        denied = h.call_gate(player=player)
        assert h.mem[h.obj + 0x7C] == 1 and h.record() == before and not denied
        h.set_panel(0x20 + player, 1, player=player, selected=1)
        allowed = h.call_gate(player=player)
        assert h.record() == before and allowed


def test_all_jal_issuing_frames_reserve_exact_o32_home_and_save_maps():
    asm = transformed()
    h = PreviewAsm(asm)
    expected = {
        "sync_slot_used_by_port": ("0x0030", {"ra": "0x002C", "t2": "0x0028", "t3": "0x0024"}),
        "selected_preview_on_select_": ("0x0040", {
            "ra": "0x003C", "a0": "0x0038", "a1": "0x0034", "a2": "0x0030",
            "a3": "0x002C", "t0": "0x0028", "t1": "0x0024", "v0": "0x0020", "v1": "0x001C",
        }),
        "css_preview_frame_": ("0x0080", {
            "t9": "0x0010", "t8": "0x0014", "t7": "0x0018", "t6": "0x001C",
            "t5": "0x0020", "t4": "0x0024", "t3": "0x0028", "t2": "0x002C",
            "v1": "0x0030", "v0": "0x0034", "a3": "0x0038", "a2": "0x003C",
            "a1": "0x0040", "a0": "0x0044", "at": "0x0048", "ra": "0x007C",
        }),
        "selected_preview_make_gate_": ("0x0040", {
            "ra": "0x003C", "a0": "0x0038", "a1": "0x0034", "v0": "0x0030", "t0": "0x002C",
        }),
        "refresh_preview_policy_": ("0x0020", {"ra": "0x001C"}),
    }
    for name, (frame, slots) in expected.items():
        scope = h._scope(name)
        assert f"addiu   sp, sp, -{frame}" in scope
        assert f"addiu   sp, sp, {frame}" in scope
        assert int(frame, 16) % 16 == 0
        assert "outgoing argument home area: sp+0x00..0x0C" in scope
        assert "jal" in scope
        for register, offset in slots.items():
            assert f"sw      {register}, {offset}(sp)" in scope
            assert f"lw      {register}, {offset}(sp)" in scope
        for offset in re.findall(r"\b(?:sw|lw)\s+\w+,\s*(0x[0-9A-Fa-f]+)\(sp\)", scope):
            assert int(offset, 16) >= 0x10


def test_o32_callee_home_spills_do_not_corrupt_saved_state_or_return_links():
    h = PreviewAsm(transformed(), spill_caller_home=True)
    link = 0xABCDEF01
    assert h.frame({"ra": link})["ra"] == link

    volatile = {
        register: 0x11000000 + number
        for number, register in enumerate(
            ("at", "a0", "a1", "a2", "a3", "v0", "v1", "t2", "t3", "t4", "t5", "t6", "t7", "t8", "t9"),
            start=1,
        )
    }
    h.call_gate()
    for _ in range(17):
        h.frame()
    result = h.frame(volatile | {"ra": link})
    assert {register: result[register] for register in volatile} == volatile
    assert result["ra"] == link

    h.call_gate()
    result = h.call_select(0, held=0, selected=0, outer_owner=2)
    assert (result["v0"], result["v1"]) == h.native_selection_returns
    assert h.mem[h.symbols["forced_selected_preview_owner"]] == 2
    assert h.mem[h.symbols["p1_preview_suppress_depth"]] == 0
    assert h.home_spills >= 4


@pytest.mark.parametrize("states", [
    (p1, p2, p3, p4)
    for p1 in (0, 1)
    for p2 in (0, 1)
    for p3 in (0, 1)
    for p4 in (0, 1)
])
def test_ordered_preview_owner_executes_all_selection_combinations_for_open_prefix(states):
    h = PreviewAsm(transformed())
    for player, state in enumerate(states):
        h.set_panel(0x20 + player, 0, player=player, state=state)
    for flags in range(16):
        selected = tuple((flags >> player) & 1 for player in range(4))
        for player, value in enumerate(selected):
            h.set_panel(0x20 + player, 0, player=player, selected=value, state=states[player])
        expected = next((player for player in range(4) if not selected[player]), 0xFFFFFFFF)
        assert h.call_ordered_owner() == expected


def test_ordered_preview_owner_closed_prefix_is_never_skipped():
    cases = (
        ((0, 0, 0, 0), (2, 0, 0, 0)),
        ((1, 0, 0, 0), (0, 2, 0, 0)),
        ((1, 1, 0, 0), (0, 0, 2, 0)),
    )
    for selected, states in cases:
        h = PreviewAsm(transformed())
        for player in range(4):
            h.set_panel(0x20 + player, 0, player=player, selected=selected[player], state=states[player])
        assert h.call_ordered_owner() == 0xFFFFFFFF


@pytest.mark.parametrize("p4_selected", (0, 1))
def test_ordered_preview_owner_is_inactive_when_p4_is_closed(p4_selected):
    h = PreviewAsm(transformed())
    for player in range(3):
        h.set_panel(0x20 + player, 0, player=player, selected=1, state=0)
    h.set_panel(0x23, 0, player=3, selected=p4_selected, state=2)
    assert h.call_ordered_owner() == 0xFFFFFFFF


@pytest.mark.parametrize(
    ("old", "new", "p4_selected", "p4_state", "expected"),
    (
        ("lw      t1, 0x02B8(t0)", "li      t1, 0", 0, 2, 0xFFFFFFFF),
        ("lw      t1, 0x028C(t0)", "li      t1, 0", 1, 0, 0xFFFFFFFF),
        ("li      v1, 3", "li      v1, 2", 0, 0, 3),
    ),
)
def test_ordered_preview_owner_p4_reads_and_owner_are_mutation_resistant(
    old, new, p4_selected, p4_state, expected
):
    asm = transformed()
    assert asm.count(old) == 1
    h = PreviewAsm(asm.replace(old, new, 1))
    for player in range(3):
        h.set_panel(0x20 + player, 0, player=player, selected=1, state=0)
    h.set_panel(0x23, 0, player=3, selected=p4_selected, state=p4_state)
    assert h.call_ordered_owner() != expected


def test_ordered_preview_owner_is_read_only_call_free_and_has_p4_offsets():
    scope = PreviewAsm(transformed())._scope("ordered_preview_owner_")
    assert not re.search(r"^\s*s[wb]\s", scope, re.MULTILINE)
    assert "jal" not in scope
    assert "0x028C" in scope and "0x02B8" in scope


def test_structural_abi_delay_slot_idempotence_and_indicator_guard_remain():
    asm = transformed()
    sync = asm[asm.index("scope sync_slot_used_by_port:"):]
    helper = asm[asm.index("scope css_preview_frame_:"):]
    assert sync.index("sw      t1, 0x0000(t0)") < sync.index("jal     css_preview_frame_")
    assert "sw      ra, 0x002C(sp)" in sync and "lw      ra, 0x002C(sp)" in sync
    assert "lw      t1, 0x0088(s2)" in asm and "beqz    t1, _next" in asm
    for register in ("ra", "at", "a0", "a1", "a2", "a3", "v0", "v1", "t2", "t3", "t4", "t5", "t6", "t7", "t8", "t9"):
        assert f"sw      {register}," in helper and f"lw      {register}," in helper
    assert transform_character_select(asm) == asm


def test_frame_policy_mismatches_branch_to_metadata_only_clear_path_before_and_after_native_loading():
    scope = PreviewAsm(transformed())._scope("css_preview_frame_")
    assert scope.count("request owner must remain the current policy owner") == 2
    assert scope.count("request epoch must remain the current policy epoch") == 2
    clear = scope[scope.index("        _clear:"):scope.index("        _return:")]
    assert "css_preview_owner" in clear
    assert "lli     t3, Character.id.NONE" in clear
    assert "sw      t3, 0x0000(t2)" in clear
    assert "css_preview_request_generation" in clear
    assert "CSS_PLAYER_STRUCT" not in clear


def test_transform_and_selection_wrapper_fail_closed_on_known_corruption():
    asm = transformed()
    wrapper = asm[asm.index("scope selected_preview_on_select_:"):asm.index("scope selected_preview_make_gate_:")]
    assert "jal     0x80136128" in wrapper and "jal     0x80131C74" in wrapper
    assert wrapper.index("jal     0x80136128") < wrapper.index("jal     0x80131C74")
    corruptions = (
        asm.replace(MARKER, f"{MARKER}\\n    // injected", 1),
        asm.replace("0x80134A8C", "0x80134A90", 1),
        PRISTINE_SOURCE.replace("    constant CSS_PLAYER_STRUCT_TRAINING", "    // injected\\n    constant CSS_PLAYER_STRUCT_TRAINING"),
        PRISTINE_SOURCE + "// +EXTRA preview lifecycle v1\\n",
        PRISTINE_SOURCE + "// +EXTRA preview debounce v1\\n",
    )
    for source in corruptions:
        with pytest.raises(ValueError):
            transform_character_select(source)


def test_edit_src_files_transforms_character_select_once_and_leaves_boot_clean(tmp_path, monkeypatch):
    import character_appender
    from character_appender import CharacterAppender

    monkeypatch.chdir(tmp_path)
    rom_root = tmp_path / "smashremix"; (rom_root / "roms").mkdir(parents=True)
    (rom_root / "roms" / "original_extra.z64").write_bytes(b"rom")
    (tmp_path / "src").mkdir(); target = tmp_path / "src" / "CharacterSelect.asm"
    boot_target = tmp_path / "src" / "Boot.asm"
    target.write_text(PRISTINE_SOURCE, encoding="utf-8")
    boot_target.write_text(PRISTINE_BOOT, encoding="utf-8")
    monkeypatch.setattr(character_appender, "smashremix_path", str(rom_root))
    appender = object.__new__(CharacterAppender)
    for method in ("_patch_src_paths", "_patch_audio_asm", "_patch_character_asm", "_patch_stage_asm", "_patch_toggle_asm"):
        setattr(appender, method, lambda *_: None)
    appender.selected_preview_transform = transform_character_select
    appender.edit_src_files()
    assert target.read_text(encoding="utf-8").count(MARKER) == 1
    assert boot_target.read_text(encoding="utf-8") == PRISTINE_BOOT


def test_harness_big_endian_byte_ops_cohere_with_word_memory_and_sign_extend():
    h = PreviewAsm(transformed())
    address = 0x81230000
    h.mem[address] = 0x80FE1234
    regs = {"t0": address, "t1": 0xA5}

    h._one(("lbu", ["t2", "0x0001(t0)"]), regs)
    h._one(("lb", ["t3", "0x0000(t0)"]), regs)
    h._one(("sb", ["t1", "0x0002(t0)"]), regs)

    assert regs["t2"] == 0xFE
    assert regs["t3"] == 0xFFFFFF80
    assert h.mem[address] == 0x80FEA534


def test_harness_sll_supports_byte_slot_offset_calculation():
    h = PreviewAsm(transformed())
    regs = {"t0": 3}
    h._one(("sll", ["t1", "t0", "0x0004"]), regs)
    assert regs["t1"] == 0x30


def test_harness_destructor_observes_a0_order_and_pre_call_slot_snapshot():
    callback_seen = []
    h = PreviewAsm(transformed(), destroy_mutation=lambda harness: callback_seen.append(harness.destroy_calls[-1]))
    panel = h.symbols["CSS_PLAYER_STRUCT"] + 0xBC
    gobj = 0xA0B0C0D0
    h.mem[panel + 8] = gobj
    h.seed_protections(current=(0xFF, 3, 0xFF, 0xFF))
    h.code["destroy_probe"] = ([
        ("sw", ["ra", "0x0010(sp)"]), ("jal", ["0x800D78E8"]), ("nop", []),
        ("lw", ["ra", "0x0010(sp)"]), ("jr", ["ra"]), ("nop", []),
    ], {})

    h.run("destroy_probe", {"a0": gobj, "sp": 0x90010000, "ra": 0})

    call = h.destroy_calls[-1]
    assert callback_seen == [call]
    assert call["a0"] == gobj
    assert call["panel"] == panel and call["current_slot"] == 3
    assert h.events.index(("destroy", call)) < h.events.index(("destroy_callback", call))


def test_harness_reset_observes_slot_without_implicit_side_effect_and_can_opt_in():
    observed = []
    h = PreviewAsm(transformed(), reset_mutation=lambda harness: observed.append(harness.reset_calls[-1]))
    h.seed_heap_slot(2, 0x31, (0x40, 0x41))
    h.code["reset_probe"] = ([
        ("sw", ["ra", "0x0010(sp)"]), ("jal", ["reset_heap_slot_"]), ("nop", []),
        ("lw", ["ra", "0x0010(sp)"]), ("jr", ["ra"]), ("nop", []),
    ], {})

    h.run("reset_probe", {"a0": 2, "sp": 0x90010000, "ra": 0})
    assert h.reset_calls == observed and h.read_heap_slot(2)["primary"] == 0x31

    h.reset_slot_effect = lambda harness, slot: harness.seed_heap_slot(slot, 0, ())
    h.run("reset_probe", {"a0": 2, "sp": 0x90010000, "ra": 0})
    assert h.read_heap_slot(2)["primary"] == 0


def test_harness_dynamic_slot_and_protection_helpers_have_five_slot_layout():
    h = PreviewAsm(transformed())
    h.seed_heap_slot(4, 0x2A, (0x10, 0x11, 0x12, 0x13))
    h.seed_protections(previous=(0, 1, 2, 3), current=(4, 5, 6, 7))

    assert h.symbols["ACTIVE_HEAP_COUNT"] == 5
    assert h.read_heap_slot(4) == {"primary": 0x2A, "additional": (0x10, 0x11, 0x12, 0x13)}
    assert h.read_protections() == ((0, 1, 2, 3), (4, 5, 6, 7))
    assert h.symbols["dynamic_css.heap_slot_4"] - h.symbols["dynamic_css.heap_slot_0"] == 0x40


def test_harness_action_ledger_allows_one_action_and_records_nested_attempts():
    h = PreviewAsm(transformed())
    h.begin_frame("retirement_dispatch")
    h.record_lifecycle_action("destroy")
    h.record_lifecycle_action("reset/reclaim", nested=True)

    assert h.frame_serial == 1
    assert h.action_ledger == [
        {"frame": 1, "callback": "retirement_dispatch", "action": "destroy"},
        {"frame": 1, "callback": "retirement_dispatch", "nested_attempted": "reset/reclaim"},
    ]
    with pytest.raises(AssertionError, match="one lifecycle action"):
        h.record_lifecycle_action("metadata_clear")


def seed_visible_preview(h, *, owner=1, character=0x27, slot=3, epoch=0x55, gobj=0xA0B0C0D0):
    for player in range(3):
        h.set_panel(0x12 + player, player, player=player, selected=1)
    h.set_panel(character, 6, player=owner, selected=0)
    panel = h.symbols["CSS_PLAYER_STRUCT"] + owner * 0xBC
    h.mem[panel + 8] = gobj
    h.mem[h.symbols["css_preview_owner"]] = owner
    h.mem[h.symbols["css_preview_policy_owner"]] = owner
    h.mem[h.symbols["css_preview_policy_generation"]] = 7
    h.mem[h.symbols["css_preview_request_generation"]] = 7
    p = h.symbols["css_preview_pending_character"]
    h.mem.update({p: character, p + 4: 6, p + 8: 0, p + 12: h.symbols["CSS_PREVIEW_VISIBLE"]})
    h.seed_protections(previous=(4, 3, 2, 1), current=(4, 3, 2, 1))
    h.mem.write_byte(h.symbols["dynamic_css.curr_slot_used_by_port"] + owner, slot)
    if 0 <= slot < h.symbols["ACTIVE_HEAP_COUNT"]:
        h.mem[h.symbols["css_preview_slot_epochs"] + slot * 4] = epoch
    return panel


def retirement(h, slot):
    return tuple(h.mem[h.symbols[base] + slot * 4] for base in
                 ("css_preview_retirement_character", "css_preview_retirement_epoch",
                  "css_preview_retirement_frame", "css_preview_retirement_valid"))


def slot_epochs(h):
    return tuple(h.mem[h.symbols["css_preview_slot_epochs"] + slot * 4] for slot in range(5))


def test_policy_loss_revokes_visible_p2_after_destructor_and_publishes_valid_last():
    previous_before = (4, 1, 2, 0)
    current_before = (2, 3, 4, 1)
    h = PreviewAsm(transformed())
    panel = seed_visible_preview(h, owner=1, character=0x27, slot=3, epoch=0x55)
    h.seed_protections(previous=previous_before, current=current_before)
    original_hover, original_visibility = h.mem[panel + 0x48], 0xCAFEBABE
    h.mem[panel + 0x10] = original_visibility
    # P1 becomes the new ordered owner without another gate call or P2 cursor movement.
    p1 = h.symbols["CSS_PLAYER_STRUCT"]
    h.mem[p1 + 0x58] = h.mem[p1 + 0x88] = 0

    h.frame()

    assert len(h.destroy_calls) == 1
    call = h.destroy_calls[0]
    assert (call["a0"], call["panel"], call["current_slot"]) == (0xA0B0C0D0, panel, 3)
    assert h.reset_calls == []
    assert h.mem[panel + 8] == 0
    previous_after, current_after = h.read_protections()
    assert previous_after == current_before
    assert previous_after != previous_before
    assert current_after == (2, 0xFF, 4, 1)
    assert retirement(h, 3) == (0x27, 0x55, call["frame_serial"], 1)
    assert h.mem[panel + 0x48] == original_hover and h.mem[panel + 0x10] == original_visibility
    assert_scheduler_metadata_cleared(h)
    assert h.events.index(("destroy", call)) < h.events.index(("sw", panel + 8, 0))

    # This targeted teardown mutation must invalidate the behavioral proof.
    mutated = PreviewAsm(
        transformed(),
        destroy_mutation=lambda harness: harness.seed_protections(
            previous=(0xFF,) * 4,
            current=harness.read_protections()[1],
        ),
    )
    mutated_panel = seed_visible_preview(mutated, owner=1, character=0x27, slot=3, epoch=0x55)
    mutated.seed_protections(previous=previous_before, current=current_before)
    mutated_p1 = mutated.symbols["CSS_PLAYER_STRUCT"]
    mutated.mem[mutated_p1 + 0x58] = mutated.mem[mutated_p1 + 0x88] = 0
    mutated.frame()

    assert mutated.destroy_calls[0]["current_slot"] == 3
    assert mutated.mem[mutated_panel + 8] == 0
    with pytest.raises(AssertionError):
        assert mutated.read_protections()[0] == current_before


@pytest.mark.parametrize("mutated_owner", (2, 0xFFFFFFFF), ids=("p3", "inactive"))
def test_revocation_uses_owner_captured_before_destructor_reentry(mutated_owner):
    current_before = (2, 3, 4, 1)
    h = PreviewAsm(
        transformed(),
        destroy_mutation=lambda harness: harness.mem.__setitem__(
            harness.symbols["css_preview_owner"], mutated_owner
        ),
    )
    panel = seed_visible_preview(h, owner=1, character=0x27, slot=3, epoch=0x55)
    h.seed_protections(previous=(4, 1, 2, 0), current=current_before)
    p1 = h.symbols["CSS_PLAYER_STRUCT"]
    h.mem[p1 + 0x58] = h.mem[p1 + 0x88] = 0

    h.frame()

    assert len(h.destroy_calls) == 1
    assert h.destroy_calls[0]["panel"] == panel
    assert h.mem[panel + 8] == 0
    assert h.read_protections()[1] == (2, 0xFF, 4, 1)
    assert retirement(h, 3)[:2] == (0x27, 0x55)


def test_revocation_reloads_scheduler_base_after_destructor_clobbers_callers():
    h = PreviewAsm(transformed(), destroy_clobber_callers=True)
    panel = seed_visible_preview(h, owner=1, character=0x27, slot=3, epoch=0x55)
    p1 = h.symbols["CSS_PLAYER_STRUCT"]
    h.mem[p1 + 0x58] = h.mem[p1 + 0x88] = 0

    h.frame()

    assert len(h.destroy_calls) == 1
    assert h.mem[panel + 8] == 0
    assert h.mem.read_byte(h.symbols["dynamic_css.curr_slot_used_by_port"] + 1) == 0xFF
    assert retirement(h, 3)[:2] == (0x27, 0x55)
    assert_scheduler_metadata_cleared(h)


def test_missing_post_destructor_scheduler_reload_fails_under_abi_clobber():
    reload_scheduler = (
        "        li      t2, css_preview_pending_character // external destructor may clobber caller-saved t2\n"
    )
    asm = transformed()
    assert asm.count(reload_scheduler) == 1
    h = PreviewAsm(asm.replace(reload_scheduler, "        nop\n", 1), destroy_clobber_callers=True)
    seed_visible_preview(h, owner=1, character=0x27, slot=3, epoch=0x55)
    p1 = h.symbols["CSS_PLAYER_STRUCT"]
    h.mem[p1 + 0x58] = h.mem[p1 + 0x88] = 0

    h.frame()

    with pytest.raises(AssertionError):
        assert_scheduler_metadata_cleared(h)


def test_policy_loss_revokes_visible_p3_when_p2_prerequisite_reopens():
    h = PreviewAsm(transformed())
    panel = seed_visible_preview(h, owner=2, character=0x31, slot=4, epoch=0x77)
    p2 = h.symbols["CSS_PLAYER_STRUCT"] + 0xBC
    h.mem[p2 + 0x58] = h.mem[p2 + 0x88] = 0

    h.frame()

    assert len(h.destroy_calls) == 1 and h.destroy_calls[0]["panel"] == panel
    assert retirement(h, 4)[:2] == (0x31, 0x77)
    assert_scheduler_metadata_cleared(h)


def test_visible_later_selected_fighter_is_never_revoked_by_policy_loss():
    h = PreviewAsm(transformed())
    panel = seed_visible_preview(h, owner=1)
    p1 = h.symbols["CSS_PLAYER_STRUCT"]
    h.mem[p1 + 0x58] = h.mem[p1 + 0x88] = 0
    h.mem[panel + 0x58] = h.mem[panel + 0x88] = 1

    h.frame()

    assert h.destroy_calls == [] and h.mem[panel + 8] == 0xA0B0C0D0
    assert h.global_record()[0] == 1


@pytest.mark.parametrize("slot", (0xFF, 5))
def test_visible_revocation_with_invalid_slot_destroys_without_retirement_or_reset(slot):
    h = PreviewAsm(transformed())
    panel = seed_visible_preview(h, slot=slot)
    p1 = h.symbols["CSS_PLAYER_STRUCT"]
    h.mem[p1 + 0x58] = h.mem[p1 + 0x88] = 0

    h.frame()

    assert len(h.destroy_calls) == 1 and h.mem[panel + 8] == 0
    assert h.reset_calls == []
    assert [retirement(h, index) for index in range(5)] == [(0, 0, 0, 0)] * 5


def test_visible_null_inconsistency_clears_metadata_without_allocator_or_pointer_mutation():
    h = PreviewAsm(transformed())
    panel = seed_visible_preview(h, slot=3)
    h.mem[panel + 8] = 0
    before = h.read_protections()
    p1 = h.symbols["CSS_PLAYER_STRUCT"]
    h.mem[p1 + 0x58] = h.mem[p1 + 0x88] = 0

    h.frame()

    assert h.destroy_calls == [] and h.read_protections() == before
    assert [retirement(h, index) for index in range(5)] == [(0, 0, 0, 0)] * 5
    assert_scheduler_metadata_cleared(h)


def test_revocation_is_once_and_nested_destructor_frame_is_guarded():
    h = PreviewAsm(transformed(), destroy_mutation=lambda harness: harness.frame())
    seed_visible_preview(h)
    p1 = h.symbols["CSS_PLAYER_STRUCT"]
    h.mem[p1 + 0x58] = h.mem[p1 + 0x88] = 0

    h.frame()
    first_serial = h.mem[h.symbols["css_preview_frame_serial"]]
    h.frame()

    assert len(h.destroy_calls) == 1 and h.loads == 0
    assert h.events.count("nested_frame") == 1
    assert h.mem[h.symbols["css_preview_frame_serial"]] == first_serial + 1


def test_refresh_policy_mutation_that_erases_visible_record_prevents_required_revocation():
    asm = transformed()
    preserve_visible = "        beq     t1, t2, _return           // frame owns visible policy-loss teardown\n"
    assert asm.count(preserve_visible) == 1
    h = PreviewAsm(asm.replace(preserve_visible, "        nop\n", 1))
    seed_visible_preview(h)
    p1 = h.symbols["CSS_PLAYER_STRUCT"]
    h.mem[p1 + 0x58] = h.mem[p1 + 0x88] = 0

    h.frame()

    with pytest.raises(AssertionError):
        assert len(h.destroy_calls) == 1


def test_revocation_mutations_remove_required_emitted_steps_meaningfully_fail():
    asm = transformed()
    mutations = (
        ("        jal     0x800D78E8", "        nop", "destroy_calls"),
        ("        sw      r0, 0x0008(t4)", "        nop", "pointer"),
        ("        sb      t6, 0x0000(t4)", "        nop", "current_slot"),
        ("        sw      t6, 0x0000(t4)          // valid last", "        nop", "retirement"),
        ("        lw      t6, 0x0058(t4)", "        lli     t6, 0x0000", "selected58"),
        ("        lw      t6, 0x0088(t4)", "        lli     t6, 0x0000", "selected"),
    )
    for old, new, assertion in mutations:
        assert old in asm
        h = PreviewAsm(asm.replace(old, new, 1))
        panel = seed_visible_preview(h)
        p1 = h.symbols["CSS_PLAYER_STRUCT"]
        h.mem[p1 + 0x58] = h.mem[p1 + 0x88] = 0
        if assertion == "selected58":
            h.mem[panel + 0x58] = 1
        if assertion == "selected":
            h.mem[panel + 0x88] = 1
        h.frame()
        with pytest.raises(AssertionError):
            if assertion == "destroy_calls": assert len(h.destroy_calls) == 1
            elif assertion == "pointer": assert h.mem[panel + 8] == 0
            elif assertion == "current_slot": assert h.mem.read_byte(h.symbols["dynamic_css.curr_slot_used_by_port"] + 1) == 0xFF
            elif assertion == "retirement": assert retirement(h, 3)[3] == 1
            else: assert h.destroy_calls == []


def test_retired_slot_is_not_reset_in_its_retirement_frame_then_reclaims_next_frame():
    h = PreviewAsm(transformed())
    h.seed_heap_slot(2, 0x31)
    h.seed_protections()
    h.mem[h.symbols["css_preview_slot_epochs"] + 8] = 0x55
    h.mem[h.symbols["css_preview_retirement_character"] + 8] = 0x31
    h.mem[h.symbols["css_preview_retirement_epoch"] + 8] = 0x55
    h.mem[h.symbols["css_preview_retirement_frame"] + 8] = 1
    h.mem[h.symbols["css_preview_retirement_valid"] + 8] = 1
    h.mem[h.symbols["css_preview_reclaim_cursor"]] = 2

    h.frame()
    assert h.reset_calls == [] and retirement(h, 2)[3] == 1
    for _ in range(5):
        h.frame()
    assert [call["a0"] for call in h.reset_calls] == [2]
    assert retirement(h, 2)[3] == 0


def test_retirement_at_u32_max_reclaims_when_outer_sync_wraps_to_zero():
    h = PreviewAsm(transformed())
    h.seed_heap_slot(2, 0x31)
    h.seed_protections()
    h.mem[h.symbols["css_preview_slot_epochs"] + 8] = 0x55
    h.mem[h.symbols["css_preview_retirement_character"] + 8] = 0x31
    h.mem[h.symbols["css_preview_retirement_epoch"] + 8] = 0x55
    h.mem[h.symbols["css_preview_retirement_frame"] + 8] = 0xFFFFFFFF
    h.mem[h.symbols["css_preview_retirement_valid"] + 8] = 1
    h.mem[h.symbols["css_preview_reclaim_cursor"]] = 2
    h.mem[h.symbols["css_preview_frame_serial"]] = 0xFFFFFFFF

    h.frame()

    assert h.mem[h.symbols["css_preview_frame_serial"]] == 0
    assert [call["a0"] for call in h.reset_calls] == [2]
    assert retirement(h, 2)[3] == 0


def test_modular_retirement_age_mutation_to_legacy_unsigned_comparison_fails_wrap_regression():
    source = transformed()
    reclaimer = PreviewAsm(source)._scope("reclaim_retired_slot_")
    modular_age = (
        "        subu    t4, t3, t2                  // modular age = current - retirement\n"
        "        beqz    t4, _normal                 // same frame remains pending\n"
        "        nop\n"
        "        lui     t5, 0x8000\n"
        "        sltu    t4, t4, t5\n"
        "        beqz    t4, _normal                 // future/half-range-or-older remains pending\n"
        "        nop\n"
    )
    legacy_unsigned_age = (
        "        sltu    t4, t2, t3\n"
        "        beqz    t4, _normal\n"
        "        nop\n"
    )
    assert reclaimer.count(modular_age) == 1
    mutated = source.replace(reclaimer, reclaimer.replace(modular_age, legacy_unsigned_age, 1), 1)
    h = PreviewAsm(mutated)
    h.seed_heap_slot(2, 0x31)
    h.seed_protections()
    h.mem[h.symbols["css_preview_slot_epochs"] + 8] = 0x55
    h.mem[h.symbols["css_preview_retirement_character"] + 8] = 0x31
    h.mem[h.symbols["css_preview_retirement_epoch"] + 8] = 0x55
    h.mem[h.symbols["css_preview_retirement_frame"] + 8] = 0xFFFFFFFF
    h.mem[h.symbols["css_preview_retirement_valid"] + 8] = 1
    h.mem[h.symbols["css_preview_reclaim_cursor"]] = 2
    h.mem[h.symbols["css_preview_frame_serial"]] = 0xFFFFFFFF

    h.frame()

    with pytest.raises(AssertionError):
        assert [call["a0"] for call in h.reset_calls] == [2] and retirement(h, 2)[3] == 0


@pytest.mark.parametrize("protected_index", range(8))
def test_each_previous_and_current_protection_byte_defers_reset_until_cursor_revisits(protected_index):
    h = PreviewAsm(transformed())
    h.seed_heap_slot(1, 0x22)
    previous = [0xFF] * 4
    current = [0xFF] * 4
    (previous if protected_index < 4 else current)[protected_index % 4] = 1
    h.seed_protections(previous=tuple(previous), current=tuple(current))
    h.mem[h.symbols["css_preview_slot_epochs"] + 4] = 9
    for base, value in (("css_preview_retirement_character", 0x22),
                        ("css_preview_retirement_epoch", 9),
                        ("css_preview_retirement_frame", 0),
                        ("css_preview_retirement_valid", 1)):
        h.mem[h.symbols[base] + 4] = value
    h.mem[h.symbols["css_preview_reclaim_cursor"]] = 1
    h.mem[h.symbols["css_preview_frame_serial"]] = 1

    reclaim_regs = {register: 0 for register in ("a0", "t0", "t1")}
    reclaim_regs.update({"sp": 0x90010000, "ra": 0})
    h.run("reclaim_retired_slot_", reclaim_regs)
    assert h.reset_calls == [] and retirement(h, 1)[3] == 1
    h.seed_protections()
    h.mem[h.symbols["css_preview_reclaim_cursor"]] = 1
    reclaim_regs = {register: 0 for register in ("a0", "t0", "t1")}
    reclaim_regs.update({"sp": 0x90010000, "ra": 0})
    h.run("reclaim_retired_slot_", reclaim_regs)
    assert [call["a0"] for call in h.reset_calls] == [1]


def seed_retirement(h, slot, character, epoch=7, frame=0):
    h.mem[h.symbols["css_preview_slot_epochs"] + slot * 4] = epoch
    for base, value in (("css_preview_retirement_character", character),
                        ("css_preview_retirement_epoch", epoch),
                        ("css_preview_retirement_frame", frame),
                        ("css_preview_retirement_valid", 1)):
        h.mem[h.symbols[base] + slot * 4] = value
    h.mem[h.symbols["css_preview_reclaim_cursor"]] = slot
    h.mem[h.symbols["css_preview_frame_serial"]] = frame + 1


@pytest.mark.parametrize("additional_index", (None, 0, 1, 2, 3))
def test_reclaim_accepts_exact_primary_or_each_additional_character_id(additional_index):
    h = PreviewAsm(transformed())
    character = 0x30 + (0 if additional_index is None else additional_index)
    h.seed_heap_slot(4, 0x30 if additional_index is None else 0x11,
                     () if additional_index is None else tuple(
                         character if index == additional_index else 0x11 for index in range(4)))
    h.seed_protections()
    seed_retirement(h, 4, character)
    h.frame()
    assert [call["a0"] for call in h.reset_calls] == [4]


@pytest.mark.parametrize("kind", ("epoch", "ownership"))
def test_stale_retirement_abandons_without_reset_and_blocks_scheduler_work(kind):
    h = PreviewAsm(transformed())
    h.call_gate()
    h.seed_heap_slot(0, 0x21)
    h.seed_protections()
    seed_retirement(h, 0, 0x21)
    if kind == "epoch":
        h.mem[h.symbols["css_preview_slot_epochs"]] += 1
    else:
        h.seed_heap_slot(0, 0x22)
    countdown = h.record()[2]
    h.frame()
    assert h.reset_calls == [] and retirement(h, 0)[3] == 0
    assert h.loads == 0 and h.record()[2] == countdown


def test_round_robin_inspects_one_retirement_per_callback_and_wraps():
    h = PreviewAsm(transformed())
    h.seed_protections()
    for slot in range(5):
        h.seed_heap_slot(slot, 0x40 + slot)
        seed_retirement(h, slot, 0x40 + slot, epoch=slot + 1)
    h.mem[h.symbols["css_preview_reclaim_cursor"]] = 0
    h.mem[h.symbols["css_preview_frame_serial"]] = 1
    for _ in range(5):
        h.frame()
    assert [call["a0"] for call in h.reset_calls] == list(range(5))
    assert h.mem[h.symbols["css_preview_reclaim_cursor"]] == 0


def test_reset_invalidates_before_reentry_and_preserves_newer_retirement_record():
    def publish_newer(h):
        h.frame()
        h.mem[h.symbols["css_preview_retirement_character"] + 8] = 0x66
        h.mem[h.symbols["css_preview_retirement_epoch"] + 8] = 0x99
        h.mem[h.symbols["css_preview_retirement_frame"] + 8] = 9
        h.mem[h.symbols["css_preview_retirement_valid"] + 8] = 1

    h = PreviewAsm(transformed(), reset_mutation=publish_newer)
    h.seed_heap_slot(2, 0x31); h.seed_protections(); seed_retirement(h, 2, 0x31)
    h.frame()
    assert [call["a0"] for call in h.reset_calls] == [2]
    assert retirement(h, 2) == (0x66, 0x99, 9, 1)
    assert h.events.count("nested_frame") == 1


def test_successful_dynamic_native_bindings_increment_slot_epoch_including_same_character_reuse():
    h = PreviewAsm(transformed())
    h.mem.write_byte(h.symbols["dynamic_css.curr_slot_used_by_port"], 2)
    h.call_gate()
    for _ in range(18): h.frame()
    assert h.mem[h.symbols["css_preview_slot_epochs"] + 8] == 1
    h.clear(); h.mem[h.symbols["css_preview_policy_owner"]] = 0
    h.call_gate()
    for _ in range(18): h.frame()
    assert h.mem[h.symbols["css_preview_slot_epochs"] + 8] == 2


def test_shared_binding_epoch_hook_services_deferred_and_forced_native_paths_once():
    h = PreviewAsm(transformed())
    assert "record_dynamic_slot_binding_" in h.code
    h.mem.write_byte(h.symbols["dynamic_css.curr_slot_used_by_port"], 2)
    h.call_gate()
    for _ in range(18):
        h.frame()
    assert h.mem[h.symbols["css_preview_slot_epochs"] + 8] == 1

    h.clear()
    h.mem[h.symbols["css_preview_policy_owner"]] = 0
    h.call_select(0, held=0, selected=1)
    assert h.mem[h.symbols["css_preview_slot_epochs"] + 8] == 2


@pytest.mark.parametrize("slot", (0xFF, 5))
def test_shared_binding_epoch_hook_ignores_preloaded_and_out_of_range_slots(slot):
    h = PreviewAsm(transformed())
    h.mem.write_byte(h.symbols["dynamic_css.curr_slot_used_by_port"], slot)
    h.call_select(0, held=0, selected=1)
    assert [h.mem[h.symbols["css_preview_slot_epochs"] + index * 4] for index in range(5)] == [0] * 5


def test_failed_native_binding_with_no_fighter_object_leaves_all_slot_epochs_unchanged():
    source = transformed()
    object_guard = "        beqz    t1, _return                // native path did not publish a fighter object\n"
    binding_scope = PreviewAsm(source)._scope("record_dynamic_slot_binding_")
    assert binding_scope.count(object_guard) == 1

    def exercise(asm):
        h = PreviewAsm(asm)
        h.mem.write_byte(h.symbols["dynamic_css.curr_slot_used_by_port"], 2)
        assert h.mem[h.symbols["CSS_PLAYER_STRUCT"] + 8] == 0
        before = slot_epochs(h)
        h.run("record_dynamic_slot_binding_", {"a0": 0, "sp": 0x90010000, "ra": 0})
        return h, before

    h, before = exercise(source)
    assert slot_epochs(h) == before == (0, 0, 0, 0, 0)

    # This is an emitted-assembly negative control, scoped to the native object guard.
    mutated_scope = binding_scope.replace(object_guard, "        nop\n", 1)
    mutated = source.replace(binding_scope, mutated_scope, 1)
    mutated_h, mutated_before = exercise(mutated)
    with pytest.raises(AssertionError):
        assert slot_epochs(mutated_h) == mutated_before


def test_empty_retirement_inspection_advances_cursor_and_runs_scheduler_in_same_callback():
    h = PreviewAsm(transformed())
    h.call_gate()
    before = h.record()[2]
    h.mem[h.symbols["css_preview_reclaim_cursor"]] = 3
    h.frame()
    assert h.mem[h.symbols["css_preview_reclaim_cursor"]] == 4
    assert h.record()[2] == before - 1 and h.loads == 0


def test_reset_full_caller_clobber_keeps_reclaimer_return_cursor_and_scheduler_blocked():
    h = PreviewAsm(transformed(), reset_clobber_callers=True)
    h.call_gate()
    h.seed_heap_slot(2, 0x31)
    h.seed_protections()
    seed_retirement(h, 2, 0x31)
    before = h.record()[2]
    h.frame()
    assert [call["a0"] for call in h.reset_calls] == [2]
    assert retirement(h, 2)[3] == 0
    assert h.mem[h.symbols["css_preview_reclaim_cursor"]] == 3
    assert h.record()[2] == before and h.loads == 0


def test_corrupt_reclaim_cursor_is_clamped_before_slot_array_access():
    h = PreviewAsm(transformed())
    h.call_gate()
    h.mem[h.symbols["css_preview_reclaim_cursor"]] = 0xFFFFFFFF
    before = h.record()[2]
    h.frame()
    assert h.mem[h.symbols["css_preview_reclaim_cursor"]] == 1
    assert h.record()[2] == before - 1


def test_shared_binding_epoch_mutation_fails_deferred_and_forced_behavioral_proof():
    source = transformed()
    increment = "        addiu   t1, t1, 0x0001\n        sw      t1, 0x0000(t0)\n"
    assert source.count(increment) == 2  # policy generation plus the unique shared binding increment
    shared_scope = PreviewAsm(source)._scope("record_dynamic_slot_binding_")
    policy_scope = PreviewAsm(source)._scope("refresh_preview_policy_")
    assert increment in shared_scope
    # Replace only the shared helper scope: policy generation remains byte-for-byte intact.
    mutated_scope = shared_scope.replace(increment, "        nop\n        sw      t1, 0x0000(t0)\n", 1)
    mutated = source.replace(shared_scope, mutated_scope, 1)
    assert PreviewAsm(mutated)._scope("refresh_preview_policy_") == policy_scope

    deferred = PreviewAsm(mutated)
    deferred.mem.write_byte(deferred.symbols["dynamic_css.curr_slot_used_by_port"], 2)
    deferred.call_gate()
    for _ in range(18):
        deferred.frame()
    with pytest.raises(AssertionError):
        assert deferred.mem[deferred.symbols["css_preview_slot_epochs"] + 8] == 1

    forced = PreviewAsm(mutated)
    forced.mem.write_byte(forced.symbols["dynamic_css.curr_slot_used_by_port"], 2)
    forced.call_select(0, held=0, selected=1)
    with pytest.raises(AssertionError):
        assert forced.mem[forced.symbols["css_preview_slot_epochs"] + 8] == 1


@pytest.mark.parametrize(
    ("pending_kind", "protection"),
    (("same", None), ("future", None), ("previous", "previous"), ("current", "current")),
)
def test_pending_retirement_keeps_scheduler_work_running_in_outer_frame(pending_kind, protection):
    source = transformed()

    def exercise(asm, kind, protected):
        h = PreviewAsm(asm)
        h.call_gate()
        h.seed_heap_slot(1, 0x21)
        previous = [0xFF] * 4
        current = [0xFF] * 4
        if protected:
            # The outer sync copies current into previous before reclamation; this
            # models both a carried prior-frame protection and the live one.
            current[2] = 1
            if protected == "previous":
                previous[2] = 1
        h.seed_protections(previous=tuple(previous), current=tuple(current))
        # sync_slot_used_by_port increments this to 11 before reclaim inspection.
        h.mem[h.symbols["css_preview_frame_serial"]] = 10
        pending_frame = {"same": 11, "future": 12}.get(kind, 10)
        seed_retirement(h, 1, 0x21, frame=pending_frame)
        h.mem[h.symbols["css_preview_frame_serial"]] = 10
        before = h.mem[h.symbols["css_preview_frame_countdown"]]
        h.frame()
        return h, before

    h, before = exercise(source, pending_kind, protection)
    assert h.reset_calls == []
    assert retirement(h, 1)[3] == 1
    assert h.mem[h.symbols["css_preview_reclaim_cursor"]] == 2
    assert h.mem[h.symbols["css_preview_frame_countdown"]] == before - 1
    assert h.loads == 0  # countdown remains nonzero, so this outer callback only ticks.

    if pending_kind == "same":
        reclaimer = PreviewAsm(source)._scope("reclaim_retired_slot_")
        pending_guard = "        beqz    t4, _normal                 // same frame remains pending\n"
        assert reclaimer.count(pending_guard) == 1
        # Diverting pending records into an existing consuming path must stop the scheduler tick.
        mutated = source.replace(reclaimer, reclaimer.replace(pending_guard,
                                                               "        b       _abandon\n", 1), 1)
        mutated_h, mutated_before = exercise(mutated, pending_kind, protection)
        with pytest.raises(AssertionError):
            assert (mutated_h.reset_calls == [] and retirement(mutated_h, 1)[3] == 1
                    and mutated_h.record()[2] == mutated_before - 1)


def test_reclamation_guard_and_commit_mutations_fail_behaviorally():
    source = transformed()
    scenarios = (
        ("earlier-frame", "        beqz    t4, _normal                 // same frame remains pending\n",
         "        nop\n", lambda h: (h.reset_calls == [] and retirement(h, 0)[3] == 1),
         lambda h: seed_retirement(h, 0, 0x21, frame=h.mem[h.symbols["css_preview_frame_serial"]])),
        ("epoch", "        bne     t2, t3, _abandon\n", "        beq     t2, t3, _abandon\n",
         lambda h: [call["a0"] for call in h.reset_calls] == [0], lambda h: seed_retirement(h, 0, 0x21)),
        ("primary", "        lw      t3, 0x0004(t0)\n        beq     t2, t3, _reset\n",
         "        lw      t3, 0x0004(t0)\n        bne     t2, t3, _reset\n",
         lambda h: [call["a0"] for call in h.reset_calls] == [0], lambda h: seed_retirement(h, 0, 0x21)),
        ("additional", "        lbu     t3, 0x0008(t0)\n        beq     t2, t3, _reset\n",
         "        lbu     t3, 0x0008(t0)\n        beq     t2, t3, _abandon\n",
         lambda h: [call["a0"] for call in h.reset_calls] == [0], lambda h: seed_retirement(h, 0, 0x22)),
        ("clear-before-reset", "        sw      r0, 0x0000(t0)             // nested reset cannot duplicate or erase newer data\n",
         "        nop\n", lambda h: retirement(h, 0)[3] == 0, lambda h: seed_retirement(h, 0, 0x21)),
    )
    reclaimer = PreviewAsm(source)._scope("reclaim_retired_slot_")
    for name, old, new, expected, seed in scenarios:
        assert reclaimer.count(old) == 1, name
        mutated_scope = reclaimer.replace(old, new, 1)
        h = PreviewAsm(source.replace(reclaimer, mutated_scope, 1))
        h.seed_heap_slot(0, 0x21, (0x22,))
        h.seed_protections()
        seed(h)
        h.frame()
        assert not expected(h), name


def test_reclaim_cursor_advance_and_wrap_mutations_fail_behaviorally():
    source = transformed()
    advance = "        sw      t1, 0x0000(t0)\n        sll     t1, a0, 0x0002\n"
    assert source.count(advance) == 1
    h = PreviewAsm(source.replace(advance, "        nop\n        sll     t1, a0, 0x0002\n", 1))
    h.seed_protections()
    for slot in (0, 1):
        h.seed_heap_slot(slot, 0x40 + slot)
        seed_retirement(h, slot, 0x40 + slot)
    h.frame(); h.frame()
    with pytest.raises(AssertionError):
        assert [call["a0"] for call in h.reset_calls] == [0, 1]


def test_each_outer_callback_has_at_most_one_lifecycle_action_across_paths():
    cases = []

    countdown = PreviewAsm(transformed()); countdown.call_gate(); countdown.action_ledger.clear(); countdown.frame()
    cases.append(countdown)

    construct = PreviewAsm(transformed()); construct.call_gate(); construct.action_ledger.clear()
    for _ in range(18): construct.frame()
    cases.append(construct)

    reset = PreviewAsm(transformed()); reset.seed_heap_slot(0, 0x21); reset.seed_protections(); seed_retirement(reset, 0, 0x21)
    reset.action_ledger.clear(); reset.frame(); cases.append(reset)

    stale = PreviewAsm(transformed()); stale.seed_heap_slot(0, 0x21); stale.seed_protections(); seed_retirement(stale, 0, 0x21)
    stale.mem[stale.symbols["css_preview_slot_epochs"]] += 1; stale.action_ledger.clear(); stale.frame(); cases.append(stale)

    revoke = PreviewAsm(transformed()); seed_visible_preview(revoke); revoke.action_ledger.clear()
    p1 = revoke.symbols["CSS_PLAYER_STRUCT"]; revoke.mem[p1 + 0x58] = revoke.mem[p1 + 0x88] = 0; revoke.frame(); cases.append(revoke)

    for h in cases:
        by_callback = {}
        for entry in h.action_ledger:
            by_callback.setdefault((entry["frame"], entry["callback"]), []).append(entry["action"])
        assert all(len(actions) <= 1 for actions in by_callback.values())
