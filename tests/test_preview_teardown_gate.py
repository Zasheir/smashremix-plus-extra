from pathlib import Path
import unittest

from smashremix_extra.preview_teardown_gate import MARKER, port_preview_teardown_gate_source

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

    def test_real_preflight_replaces_character_81_trigger_without_heap_writes(self):
        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split(
            "scope dynamically_load_character_:", 1
        )[0]
        self.assertIn("jal     preview_request_can_construct_", gate)
        self.assertIn("lw      a1, 0x0020(sp)", gate)
        self.assertIn("bnez    v1, _continue", gate)
        self.assertNotIn("lli     at, 0x0051", gate)

        preflight = self.source.split("scope preview_request_can_construct_:", 1)[1].split(
            "scope preview_teardown_gate_:", 1
        )[0]
        self.assertIn("li      t0, 0x80116E10", preflight)
        self.assertIn("lw      t0, 0x0028(t0)", preflight)
        self.assertIn("lli     t9, Character.id.SONIC", preflight)
        self.assertIn("beqz    a2, _ordinary_main_file", preflight)
        self.assertIn("lw      t0, 0x0040(t0)", preflight)
        self.assertIn("lw      t0, 0x0000(t0)", preflight)
        self.assertIn("li      t0, dynamic_css.heap_slot_0", preflight)
        self.assertIn("lli     t1, dynamic_css.ACTIVE_HEAP_COUNT", preflight)
        self.assertIn("li      t5, dynamic_css.slot_used_by_port", preflight)
        self.assertIn("lli     t6, 0x0008", preflight)
        self.assertIn("or      v1, r0, r0", preflight)
        self.assertNotIn("sw      ", preflight)
        self.assertNotIn("sb      ", preflight)

    def test_preflight_denies_out_of_range_character_ids(self):
        preflight = self.source.split("scope preview_request_can_construct_:", 1)[1].split(
            "scope preview_teardown_gate_:", 1
        )[0]
        range_check = preflight.split("li      t0, 0x80116E10", 1)[0]
        self.assertIn("or      v1, r0, r0", range_check)
        self.assertIn("sltiu   t9, a0, Character.NUM_CHARACTERS", range_check)
        self.assertIn("beqz    t9, _return", range_check)
        self.assertIn("lli     v1, OS.TRUE", range_check)
        self.assertLess(range_check.index("beqz    t9, _return"), range_check.index("lli     v1, OS.TRUE"))

    def test_preflight_denies_reserved_sentinel_ids_before_table_access(self):
        preflight = self.source.split("scope preview_request_can_construct_:", 1)[1].split(
            "scope preview_teardown_gate_:", 1
        )[0]
        validation = preflight.split("li      t0, 0x80116E10", 1)[0]
        self.assertIn("lli     t8, Character.id.PLACEHOLDER", validation)
        self.assertIn("lli     t8, Character.id.NONE", validation)
        self.assertEqual(validation.count("beq     a0, t8, _return"), 2)
        accept = validation.index("lli     v1, OS.TRUE")
        self.assertLess(validation.index("lli     t8, Character.id.PLACEHOLDER"), accept)
        self.assertLess(validation.index("lli     t8, Character.id.NONE"), accept)

        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split("_count_veto:", 1)[0]
        queue_store = gate.index("sw      a0, 0x0000(t7)")
        self.assertIn("_replay_without_defer:", gate)
        self.assertIn("sltiu   at, a0, Character.NUM_CHARACTERS", gate)
        self.assertIn("lli     t8, Character.id.PLACEHOLDER", gate)
        self.assertIn("lli     t8, Character.id.NONE", gate)
        self.assertEqual(gate.count("beq     a0, t8, _replay_without_defer"), 2)
        self.assertLess(gate.index("sltiu   at, a0, Character.NUM_CHARACTERS"), queue_store)
        self.assertLess(gate.index("lli     t8, Character.id.NONE"), queue_store)

    def test_invalid_latest_hover_cancels_stale_deferred_request(self):
        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split("_count_veto:", 1)[0]
        validation = gate.split("jal     all_four_preview_panels_active_", 1)[0]
        self.assertIn("beqz    at, _cancel_pending_request", validation)
        self.assertEqual(validation.count("beq     a0, t8, _cancel_pending_request"), 2)

        cancel = gate.split("_cancel_pending_request:", 1)[1].split("_run_preflight:", 1)[0]
        self.assertIn("li      t7, dynamic_css.preview_deferred_records", cancel)
        self.assertIn("sll     t8, a1, 0x0003", cancel)
        self.assertIn("lli     t4, Character.id.NONE", cancel)
        self.assertIn("sw      t4, 0x0000(t7)", cancel)
        self.assertIn("sw      r0, 0x0004(t7)", cancel)
        self.assertIn("li      t6, dynamic_css.preview_debounce_frames", cancel)
        self.assertIn("sll     t8, a1, 0x0002", cancel)
        self.assertIn("sw      r0, 0x0000(t6)", cancel)
        self.assertIn("b       _run_preflight", cancel)

    def test_four_player_preview_debounce_storage_and_initialization(self):
        self.assertIn("constant PREVIEW_DEBOUNCE_FRAMES(18)", self.source)
        self.assertIn("preview_debounce_frames:; fill 0x0010", self.source)

        initialization = self.source.split("scope initialize_dynamic_css_:", 1)[1].split(
            "scope sync_slot_used_by_port:", 1
        )[0]
        clear = initialization.split("_clear_deferred_requests:", 1)[1].split(
            "// This routine will run after characters load", 1
        )[0]
        self.assertIn("li      t3, dynamic_css.preview_debounce_frames", initialization)
        self.assertIn("sw      r0, 0x0000(t3)", clear)
        self.assertIn("addiu   t3, t3, 0x0004", clear)
        self.assertEqual(clear.count("sw      r0, 0x0000(t3)"), 1)

        helper = self.source.split("scope all_four_preview_panels_active_:", 1)[1].split(
            "scope retry_deferred_preview_requests_:", 1
        )[0]
        self.assertIn("li      t0, CSS_PLAYER_STRUCT", helper)
        self.assertIn("lli     t1, 0x0004", helper)
        self.assertIn("lw      t2, 0x0084(t0)", helper)
        self.assertIn("lli     t3, 0x0002", helper)
        self.assertIn("beq     t2, t3, _return", helper)
        self.assertIn("addiu   t0, t0, 0x00BC", helper)
        self.assertIn("addiu   t1, t1, -0x0001", helper)
        self.assertIn("lli     v1, OS.TRUE", helper)
        self.assertNotIn("sw      ", helper)
        self.assertNotIn("sb      ", helper)

    def test_four_player_hover_is_last_request_wins_without_same_request_restart(self):
        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split(
            "_replay_without_defer:", 1
        )[0]
        self.assertIn("jal     all_four_preview_panels_active_", gate)
        self.assertIn("beqz    v1, _run_preflight", gate)
        self.assertIn("li      t6, dynamic_css.preview_debounce_frames", gate)
        self.assertIn("sll     t8, t3, 0x0002", gate)
        self.assertIn("lw      t4, 0x0000(t7)", gate)
        self.assertIn("bne     t4, a0, _debounce_request_changed", gate)
        self.assertIn("lw      t4, 0x0004(t7)", gate)
        self.assertIn("bne     t4, a2, _debounce_request_changed", gate)
        same_request = gate.split("bne     t4, a2, _debounce_request_changed", 1)[1].split(
            "_debounce_request_changed:", 1
        )[0]
        self.assertNotIn("PREVIEW_DEBOUNCE_FRAMES", same_request)
        changed = gate.split("_debounce_request_changed:", 1)[1]
        self.assertIn("sw      a0, 0x0000(t7)", changed)
        self.assertIn("sw      a2, 0x0004(t7)", changed)
        self.assertIn("lli     t4, dynamic_css.PREVIEW_DEBOUNCE_FRAMES", changed)
        self.assertIn("sw      t4, 0x0000(t6)", changed)
        self.assertIn("b       _replay_without_defer", changed)

    def test_debounce_expiry_keeps_preflight_and_serialized_admission(self):
        retry = self.source.split("scope retry_deferred_preview_requests_:", 1)[1].split(
            "scope use_custom_heap_structs_:", 1
        )[0]
        self.assertIn("jal     all_four_preview_panels_active_", retry)
        self.assertIn("li      t4, dynamic_css.preview_debounce_frames", retry)
        self.assertIn("lw      t6, 0x0000(t4)", retry)
        self.assertIn("beqz    v1, _debounce_ready", retry)
        self.assertIn("beqz    t6, _debounce_ready", retry)
        release_guard_text = "bltz    t6, _return"
        self.assertIn(release_guard_text, retry)
        release_guard = retry.index(release_guard_text)
        zero_check = retry.index("beqz    t6, _debounce_ready")
        decrement = retry.index("addiu   t6, t6, -0x0001")
        self.assertLess(release_guard, zero_check)
        self.assertLess(zero_check, decrement)
        post_decrement = (
            "addiu   t6, t6, -0x0001\n"
            "        sw      t6, 0x0000(t4)\n"
            "        beqz    t6, _debounce_ready"
        )
        self.assertIn(post_decrement, retry)
        self.assertIn("b       _next", retry)
        self.assertIn("_debounce_ready:", retry)
        self.assertLess(retry.index("_debounce_ready:"), retry.index("jal     preview_request_can_construct_"))
        accepted = retry.split("sw      a0, 0x0048(t0)", 1)[1].split("_next:", 1)[0]
        self.assertIn("addiu   t5, r0, -0x0001", accepted)
        self.assertIn("sw      t5, 0x0000(t4)", accepted)
        loader_call = "jal     0x80136128"
        self.assertIn(loader_call, accepted)
        self.assertIn("or      a0, r0, t3", accepted)
        self.assertLess(accepted.index("sw      t5, 0x0000(t4)"), accepted.index(loader_call))
        self.assertNotIn("sw      t5, 0x0000(t1)", accepted)
        self.assertNotIn("sw      r0, 0x0004(t1)", accepted)
        self.assertIn("b       _return", accepted)

        continuation = self.source.split("_continue:", 1)[1].split("_resolve:", 1)[0]
        self.assertIn("li      t6, dynamic_css.preview_debounce_frames", continuation)
        self.assertIn("sw      r0, 0x0000(t6)", continuation)

    def test_expired_retry_release_is_consumed_once_without_rearming(self):
        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split(
            "_run_preflight:", 1
        )[0]
        self.assertIn("lw      t5, 0x0000(t6)", gate)
        self.assertIn("bltz    t5, _debounce_release", gate)
        release = gate.split("_debounce_release:", 1)[1].split(
            "_debounce_request_changed:", 1
        )[0]
        self.assertIn("lw      t4, 0x0000(t7)", release)
        self.assertIn("bne     t4, a0, _debounce_request_changed", release)
        self.assertIn("lw      t4, 0x0004(t7)", release)
        self.assertIn("bne     t4, a2, _debounce_request_changed", release)
        self.assertIn("lli     t4, Character.id.NONE", release)
        self.assertIn("sw      t4, 0x0000(t7)", release)
        self.assertIn("sw      r0, 0x0004(t7)", release)
        self.assertIn("sw      r0, 0x0000(t6)", release)
        self.assertIn("b       _run_preflight", release)
        self.assertNotIn("PREVIEW_DEBOUNCE_FRAMES", release)

    def test_deferred_requests_are_saved_and_retried_per_port(self):
        self.assertIn(
            "preview_deferred_records:; fill 0x0020",
            self.source,
        )
        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split(
            "_count_veto:", 1
        )[0]
        self.assertIn("li      t7, dynamic_css.preview_deferred_records", gate)
        self.assertIn("sll     t8, t3, 0x0003", gate)
        self.assertIn("sw      a0, 0x0000(t7)", gate)
        self.assertIn("sw      a2, 0x0004(t7)", gate)

        sync = self.source.split("scope sync_slot_used_by_port:", 1)[1].split(
            "scope use_custom_heap_structs_:", 1
        )[0]
        self.assertIn("jal     retry_deferred_preview_requests_", sync)
        retry = self.source.split("scope retry_deferred_preview_requests_:", 1)[1].split(
            "scope use_custom_heap_structs_:", 1
        )[0]
        self.assertIn("jal     preview_request_can_construct_", retry)
        self.assertIn("lw      a2, 0x0004(t1)", retry)
        self.assertIn("addiu   t3, t3, 0x0001", retry)
        self.assertIn("beqz    v1, _next", retry)
        self.assertIn("sw      a0, 0x0048(t0)", retry)
        self.assertIn("sb      a2, 0x0000(t5)", retry)
        accepted = retry.split("sw      a0, 0x0048(t0)", 1)[1].split("_next:", 1)[0]
        self.assertIn("addiu   t5, r0, -0x0001", accepted)
        self.assertIn("sw      t5, 0x0000(t4)", accepted)
        loader_call = "jal     0x80136128"
        self.assertIn(loader_call, accepted)
        self.assertIn("or      a0, r0, t3", accepted)
        self.assertLess(accepted.index("sw      t5, 0x0000(t4)"), accepted.index(loader_call))
        self.assertNotIn("sw      t5, 0x0000(t1)", accepted)
        self.assertNotIn("sw      r0, 0x0004(t1)", accepted)
        self.assertIn("b       _return", accepted)
        self.assertIn("nop", accepted)
        self.assertIn("addiu   t0, t0, 0x00BC", retry)
        self.assertIn("addiu   t1, t1, 0x0008", retry)

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

    def test_deferred_request_replays_committed_character_variant_and_classic_flag(self):
        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split("_continue:", 1)[0]
        self.assertIn("jal     preview_request_can_construct_", gate)
        self.assertIn("sw      a0, 0x0000(t7)", gate)
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

    def test_obsolete_marker_fails_closed_instead_of_silently_skipping_upgrade(self):
        self.assertIn("v3", MARKER)
        old = "// +EXTRA committed preview replay spike"
        invalid_sources = {
            "old": self.source.replace(MARKER, old),
            "v2": self.source.replace(MARKER, old + " v2"),
            "mixed": self.source + "\n" + old + "\n",
            "malformed": self.source.replace(MARKER, MARKER + "-corrupt"),
            "duplicate": self.source + "\n" + MARKER + "\n",
            "future": self.source.replace(MARKER, old + " v99"),
        }
        for case, invalid in invalid_sources.items():
            with self.subTest(case=case), self.assertRaisesRegex(ValueError, "marker.*regenerate"):
                port_preview_teardown_gate_source(invalid)


if __name__ == "__main__":
    unittest.main()
