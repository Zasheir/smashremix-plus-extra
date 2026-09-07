import re

import pytest


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


def transformed():
    return transform_character_select(PRISTINE_SOURCE)


class PreviewAsm:
    """Small execution harness for the emitted gate/frame blocks, not a model."""

    REG = {"r0": "r0", "zero": "r0"}

    def __init__(self, asm, mismatch=None, *, spill_caller_home=False):
        self.asm = asm
        self.mismatch = mismatch
        self.spill_caller_home = spill_caller_home
        self.home_spills = 0
        self.loads = self.allows = self.sync_calls = 0
        self._next_link_id = 0
        self.obj = 0x90000000
        self.mem = {}
        self.native_selection_returns = (0x12345678, 0x9ABCDEF0)
        self.native_selection_selected = 1
        self.gate_outcomes = []
        self.symbols = {
            "CSS_PLAYER_STRUCT": 0x8013BA88,
            "p1_preview_pending_character": 0x81000000,
            "p1_preview_pending_variant": 0x81000004,
            "p1_preview_frame_countdown": 0x81000008,
            "p1_preview_state": 0x8100000C,
            "p1_preview_suppress_depth": 0x81000010,
            "forced_selected_preview_owner": 0x81000014,
            "dynamic_css.slot_used_by_port": 0x81000018,
            "Character.id.NONE": 0xFF,
            "Character.id.PLACEHOLDER": 0xFE,
            "Character.NUM_CHARACTERS": 0x80,
            "P1_PREVIEW_DEBOUNCE_FRAMES": 18,
            "P1_PREVIEW_WAITING": 1,
            "P1_PREVIEW_CONSTRUCTING": 2,
            "P1_PREVIEW_VISIBLE": 3,
        }
        self.code = {name: self._parse(self._scope(name)) for name in
                     ("sync_slot_used_by_port", "selected_preview_on_select_",
                      "selected_preview_make_gate_", "p1_preview_frame_")}
        self.mem[self.symbols["forced_selected_preview_owner"]] = 0xFFFFFFFF
        self.mem[self.symbols["p1_preview_suppress_depth"]] = 0
        self.mem[self.symbols["dynamic_css.slot_used_by_port"]] = 0
        self.mem[self.symbols["dynamic_css.slot_used_by_port"] + 4] = 0
        self.set_panel(0x12, 3)
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
        self.mem[base + 0x84] = state
        self.mem.setdefault(base + 8, 0)

    def record(self):
        p = self.symbols["p1_preview_pending_character"]
        return tuple(self.mem.get(p + o, 0) for o in (0, 4, 8, 12))

    def clear(self):
        p = self.symbols["p1_preview_pending_character"]
        self.mem.update({p: 0xFF, p + 4: 0, p + 8: 0, p + 12: 0})

    def call_gate(self, *, player=0, object=True, variant=None):
        base = self.symbols["CSS_PLAYER_STRUCT"] + player * 0xBC
        return self.run("selected_preview_make_gate_", {"a0": self.obj if object else 0,
                                                          "a1": player,
                                                          "v0": self.mem[base + 0x4C] if variant is None else variant,
                                                          "ra": 0})

    def frame(self, initial=None):
        self.sync_calls += 1
        regs = {register: 0 for register in
                ("at", "a0", "a1", "a2", "a3", "v0", "v1", "t2", "t3", "t4", "t5", "t6", "t7", "t8", "t9")}
        regs.update({"sp": 0x90010000, "ra": 0})
        if initial:
            regs.update(initial)
        return self.run("sync_slot_used_by_port", regs)

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
        if self.mismatch:
            self.mismatch(self)
        player = self.val("a0", regs)
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

    def _native_select(self, regs):
        held = self.mem[self.symbols["CSS_PLAYER_STRUCT"] + self.val("a0", regs) * 0xBC + 0x80]
        if 0 <= held < 4:
            self.mem[self.symbols["CSS_PLAYER_STRUCT"] + held * 0xBC + 0x58] = self.native_selection_selected
        regs["v0"], regs["v1"] = self.native_selection_returns

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
        elif op == "lw":
            address = self.addr(a[1], regs)
            assert address in self.mem, f"unmapped lw {address:#x}"
            regs[a[0]] = self.mem[address]
        elif op == "sw": self.mem[self.addr(a[1], regs)] = self.val(a[0], regs) & 0xFFFFFFFF
        elif op == "or": regs[a[0]] = self.val(a[1], regs) | self.val(a[2], regs)
        elif op == "addu": regs[a[0]] = (self.val(a[1], regs) + self.val(a[2], regs)) & 0xFFFFFFFF
        elif op == "addiu": regs[a[0]] = (self.val(a[1], regs) + int(a[2], 0)) & 0xFFFFFFFF
        elif op == "sltiu": regs[a[0]] = int(self.val(a[1], regs) < self.val(a[2], regs))
        elif op == "multu": regs["lo"] = self.val(a[0], regs) * self.val(a[1], regs)
        elif op == "mflo": regs[a[0]] = self.val("lo", regs)
        else: raise AssertionError(f"unsupported emitted op {op}")


def test_scope_parser_extracts_only_its_balanced_scope_and_rejects_unclosed_scope():
    h = PreviewAsm(transformed())
    sync = h._scope("sync_slot_used_by_port")
    gate = h._scope("selected_preview_make_gate_")
    assert "jal     p1_preview_frame_" in sync
    assert "scope selected_preview_on_select_" not in sync
    assert "scope p1_preview_frame_" not in sync
    assert "j       0x80134A8C" in gate
    assert "scope p1_preview_frame_" not in gate
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


def test_sync_scope_owns_lifecycle_clock_and_calls_helper_exactly_once():
    asm = transformed()
    h = PreviewAsm(asm)
    slot = h.symbols["dynamic_css.slot_used_by_port"]
    h.mem[slot + 4] = 0x42
    h.call_gate()
    h.frame()
    assert h.mem[slot] == 0x42
    assert h.sync_calls == 1 and h.record() == (0x12, 3, 17, 1)

    without_call = PreviewAsm(asm.replace("        jal     p1_preview_frame_\n", "", 1))
    without_call.call_gate()
    for _ in range(18):
        without_call.frame()
    assert without_call.loads == 0 and without_call.record() == (0x12, 3, 18, 1)

    duplicate_call = PreviewAsm(asm.replace("        jal     p1_preview_frame_\n", "        jal     p1_preview_frame_\n        nop\n        jal     p1_preview_frame_\n", 1))
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
        ("sync_slot_used_by_port", "        lw      ra, 0x001C(sp)\n",
         lambda h: (h.call_gate(), h.frame())),
        ("p1_preview_frame_", "        lw      ra, 0x004C(sp)\n",
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
    scope = PreviewAsm(asm)._scope("p1_preview_frame_")
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
        "sync_slot_used_by_port": ("0x0020", {"ra": "0x001C"}),
        "selected_preview_on_select_": ("0x0040", {
            "ra": "0x003C", "a0": "0x0038", "a1": "0x0034", "a2": "0x0030",
            "a3": "0x002C", "t0": "0x0028", "t1": "0x0024", "v0": "0x0020", "v1": "0x001C",
        }),
        "p1_preview_frame_": ("0x0050", {
            "t9": "0x0010", "t8": "0x0014", "t7": "0x0018", "t6": "0x001C",
            "t5": "0x0020", "t4": "0x0024", "t3": "0x0028", "t2": "0x002C",
            "v1": "0x0030", "v0": "0x0034", "a3": "0x0038", "a2": "0x003C",
            "a1": "0x0040", "a0": "0x0044", "at": "0x0048", "ra": "0x004C",
        }),
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


def test_structural_abi_delay_slot_idempotence_and_indicator_guard_remain():
    asm = transformed()
    sync = asm[asm.index("scope sync_slot_used_by_port:"):]
    helper = asm[asm.index("scope p1_preview_frame_:"):]
    assert sync.index("sw      t1, 0x0000(t0)") < sync.index("jal     p1_preview_frame_")
    assert "sw      ra, 0x001C(sp)" in sync and "lw      ra, 0x001C(sp)" in sync
    assert "lw      t1, 0x0088(s2)" in asm and "beqz    t1, _next" in asm
    for register in ("ra", "at", "a0", "a1", "a2", "a3", "v0", "v1", "t2", "t3", "t4", "t5", "t6", "t7", "t8", "t9"):
        assert f"sw      {register}," in helper and f"lw      {register}," in helper
    assert transform_character_select(asm) == asm


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


def test_edit_src_files_transforms_character_select_once(tmp_path, monkeypatch):
    import character_appender
    from character_appender import CharacterAppender

    monkeypatch.chdir(tmp_path)
    rom_root = tmp_path / "smashremix"; (rom_root / "roms").mkdir(parents=True)
    (rom_root / "roms" / "original_extra.z64").write_bytes(b"rom")
    (tmp_path / "src").mkdir(); target = tmp_path / "src" / "CharacterSelect.asm"
    target.write_text(PRISTINE_SOURCE, encoding="utf-8")
    monkeypatch.setattr(character_appender, "smashremix_path", str(rom_root))
    appender = object.__new__(CharacterAppender)
    for method in ("_patch_src_paths", "_patch_audio_asm", "_patch_character_asm", "_patch_stage_asm", "_patch_toggle_asm"):
        setattr(appender, method, lambda *_: None)
    appender.selected_preview_transform = transform_character_select
    appender.edit_src_files()
    assert target.read_text(encoding="utf-8").count(MARKER) == 1
