from pathlib import Path
import unittest

from smashremix_extra.preview_teardown_gate import port_preview_teardown_gate_source

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = ROOT / "smashremix" / "src" / "CharacterSelect.asm"


class PreviewTeardownGateGenerationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original = UPSTREAM.read_text()
        cls.source = port_preview_teardown_gate_source(cls.original)

    def test_css_initialization_seeds_provisional_mario_records_valid_last(self):
        initialization = self.source.split("scope initialize_dynamic_css_:", 1)[1].split(
            "scope sync_slot_used_by_port:", 1
        )[0]
        self.assertIn("_seed_provisional_preview_records:", initialization)
        self.assertIn("li      t0, dynamic_css.preview_committed_records", initialization)
        self.assertIn("lli     t1, 0x0004", initialization)
        seed = initialization.split("_seed_provisional_preview_records:", 1)[1].split(
            "_preview_records_seeded:", 1
        )[0]
        self.assertIn("sw      r0, 0x0004(t0)", seed)
        self.assertIn("sw      r0, 0x0008(t0)", seed)
        self.assertIn("sw      r0, 0x000C(t0)", seed)
        self.assertIn("lli     t2, 0x0002", seed)
        valid = seed.index("sw      t2, 0x0000(t0)")
        self.assertLess(seed.index("sw      r0, 0x0004(t0)"), valid)
        self.assertLess(seed.index("sw      r0, 0x0008(t0)"), valid)
        self.assertLess(seed.index("sw      r0, 0x000C(t0)"), valid)
        self.assertIn("addiu   t0, t0, 0x0010", seed)
        self.assertIn("addiu   t1, t1, -0x0001", seed)
        self.assertIn("bnez    t1, _seed_provisional_preview_records", seed)

    def test_preload_sync_seeds_each_published_vs_preview_valid_last(self):
        sync = self.source.split("scope sync_slot_used_by_port:", 1)[1].split(
            "scope use_custom_heap_structs_:", 1
        )[0]
        self.assertIn("jal     seed_initial_preview_records_", sync)

        seed = self.source.split("scope seed_initial_preview_records_:", 1)[1].split(
            "scope use_custom_heap_structs_:", 1
        )[0]
        self.assertIn("li      t0, CSS_PLAYER_STRUCT", seed)
        self.assertIn("li      t1, dynamic_css.preview_committed_records", seed)
        self.assertIn("lli     t2, 0x0004", seed)
        self.assertIn("lw      t3, 0x0000(t1)", seed)
        self.assertIn("lli     t4, OS.TRUE", seed)
        self.assertIn("beq     t3, t4, _next", seed)
        self.assertNotIn("bnez    t3, _next", seed)
        self.assertIn("lw      t3, 0x0008(t0)", seed)
        self.assertIn("beqz    t3, _next", seed)
        self.assertIn("lw      t4, 0x0048(t0)", seed)
        self.assertIn("lw      t5, 0x004C(t0)", seed)
        self.assertIn("li      t6, Sonic.classic_table", seed)
        self.assertIn("lbu     t6, 0x0000(t6)", seed)
        valid = seed.index("sw      t3, 0x0000(t1)")
        self.assertLess(seed.index("sw      t4, 0x0004(t1)"), valid)
        self.assertLess(seed.index("sw      t5, 0x0008(t1)"), valid)
        self.assertLess(seed.index("sw      t6, 0x000C(t1)"), valid)
        self.assertIn("addiu   t0, t0, 0x00BC", seed)
        self.assertIn("addiu   t1, t1, 0x0010", seed)

    def test_success_edge_commits_exact_per_port_preview_valid_last(self):
        source = self.source
        self.assertIn("preview_committed_records:; fill 0x0040", source)
        self.assertIn("OS.patch_start(0x132E24, 0x80134BA4)", source)
        commit = source.split("scope preview_commit_:", 1)[1]
        body = commit.split("_replay:", 1)[0]
        self.assertIn("lw      t4, 0x0048(t0)", body)
        self.assertIn("lw      t5, 0x004C(t0)", body)
        self.assertIn("li      t6, Sonic.classic_table", body)
        self.assertIn("lbu     t6, 0x0000(t6)", body)
        self.assertLess(body.index("sw      t4, 0x0004(t2)"), body.index("sw      t1, 0x0000(t2)"))
        self.assertLess(body.index("sw      t5, 0x0008(t2)"), body.index("sw      t1, 0x0000(t2)"))
        self.assertLess(body.index("sw      t6, 0x000C(t2)"), body.index("sw      t1, 0x0000(t2)"))

    def test_character_81_replays_committed_character_variant_and_classic_flag(self):
        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split("_continue:", 1)[0]
        self.assertIn("lli     at, 0x0051", gate)
        self.assertIn("lw      a0, 0x0004(t2)", gate)
        self.assertIn("lw      v0, 0x0008(t2)", gate)
        self.assertIn("lw      t6, 0x000C(t2)", gate)
        self.assertIn("li      t5, Sonic.classic_table", gate)
        self.assertIn("sb      t6, 0x0000(t5)", gate)
        self.assertIn("sw      a0, 0x0048(s0)", gate)
        self.assertIn("j       0x801361CC", gate)
        self.assertNotIn("curr_slot_used_by_port", gate)

    def test_invalid_record_uses_preloaded_mario_without_slot_requirement(self):
        gate = self.source.split("scope preview_teardown_gate_:", 1)[1]
        self.assertIn("_fallback:", gate)
        fallback = gate.partition("_fallback:")[2].partition("_continue:")[0]
        self.assertIn("sw      r0, 0x0048(s0)", fallback)
        self.assertIn("or      v0, r0, r0", fallback)
        self.assertIn("sb      r0, 0x0000(t5)", fallback)
        self.assertNotIn("slot", fallback.lower())

    def test_normal_path_still_calls_variant_resolver(self):
        continuation = self.source.split("scope preview_teardown_gate_:", 1)[1].split("_continue:", 1)[1]
        self.assertIn("jal     0x8013487C", continuation)
        self.assertIn("lw      a1, 0x0020(sp)", continuation)

    def test_transform_is_idempotent(self):
        self.assertEqual(self.source, port_preview_teardown_gate_source(self.source))


if __name__ == "__main__":
    unittest.main()
