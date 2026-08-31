from pathlib import Path
import unittest

try:
    from smashremix_extra.preview_teardown_gate import port_preview_teardown_gate_source
except ModuleNotFoundError:
    port_preview_teardown_gate_source = lambda source: source

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = ROOT / "smashremix" / "src" / "CharacterSelect.asm"


class PreviewTeardownGateGenerationTests(unittest.TestCase):
    def test_character_81_is_replaced_before_variant_and_constructor_inputs(self):
        source = port_preview_teardown_gate_source(UPSTREAM.read_text())
        self.assertIn("OS.patch_start(0x134440, 0x801361C0)", source)
        self.assertNotIn("OS.patch_start(0x1384AC, 0x8013A22C)", source)
        scope = source.split("scope preview_teardown_gate_:", 1)[1]
        trigger = scope.split("_continue:", 1)[0]
        self.assertIn("lw      a0, 0x0048(s0)", trigger)
        self.assertIn("lli     at, 0x0051", trigger)
        self.assertIn("bne     a0, at, _continue", trigger)
        self.assertIn("sw      r0, 0x0048(s0)", trigger)
        self.assertIn("debug_preview_teardown_veto_count", trigger)
        continuation = scope.split("_continue:", 1)[1]
        self.assertIn("jal     0x8013487C", continuation)
        self.assertIn("lw      a1, 0x0020(sp)", continuation)
        self.assertIn("j       0x801361CC", continuation)

    def test_transform_is_idempotent(self):
        once = port_preview_teardown_gate_source(UPSTREAM.read_text())
        self.assertEqual(once, port_preview_teardown_gate_source(once))


if __name__ == "__main__":
    unittest.main()
