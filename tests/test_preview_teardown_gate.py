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

    def test_blank_lifecycle_storage_and_telemetry_are_initialized_per_port(self):
        self.assertIn("constant PREVIEW_STATE_VISIBLE(0)", self.source)
        self.assertIn("constant PREVIEW_STATE_BLANK_WAIT(1)", self.source)
        self.assertIn("constant PREVIEW_STATE_BLANK_READY(2)", self.source)
        self.assertIn("constant PREVIEW_STATE_CONSTRUCTING(3)", self.source)
        self.assertIn("preview_lifecycle_states:; fill 0x0010", self.source)

        counters = (
            "debug_preview_blank_entered_count",
            "debug_preview_teardown_attempted_count",
            "debug_preview_teardown_completed_count",
            "debug_preview_duplicate_teardown_suppressed_count",
            "debug_preview_ready_busy_retry_count",
            "debug_preview_construction_admitted_count",
        )
        for counter in counters:
            with self.subTest(counter=counter):
                self.assertIn(f"{counter}:; fill 0x0010", self.source)

        initialization = self.source.split("scope initialize_dynamic_css_:", 1)[1].split(
            "scope sync_slot_used_by_port:", 1
        )[0]
        clear = initialization.split("_clear_deferred_requests:", 1)[1].split(
            "// This routine will run after characters load", 1
        )[0]
        self.assertIn("li      t4, dynamic_css.preview_lifecycle_states", initialization)
        self.assertIn("lli     t8, dynamic_css.PREVIEW_STATE_BLANK_READY", initialization)
        self.assertIn("sw      t8, 0x0000(t4)", clear)
        self.assertIn("addiu   t4, t4, 0x0004", clear)

        for counter in counters:
            with self.subTest(counter=counter):
                self.assertIn(f"li      t5, dynamic_css.{counter}", initialization)
                self.assertIn("sw      r0, 0x0000(t5)", initialization)

    def test_first_four_player_change_destroys_once_and_returns_blank(self):
        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split(
            "scope dynamically_load_character_:", 1
        )[0]
        changed = gate.split("_debounce_request_changed:", 1)[1].split(
            "_cancel_pending_request:", 1
        )[0]
        self.assertIn("sw      a0, 0x0000(t7)", changed)
        self.assertIn("sw      a2, 0x0004(t7)", changed)
        self.assertIn("lli     t4, dynamic_css.PREVIEW_DEBOUNCE_FRAMES", changed)
        self.assertIn("jal     blank_visible_preview_", changed)
        self.assertNotIn("_replay_without_defer", changed)

        blank = self.source.split("scope blank_visible_preview_:", 1)[1].split(
            "scope reclaim_retired_preview_slots_:", 1
        )[0]
        valid = blank.index("sltiu   at, t3, 0x0004")
        state_write = blank.index("dynamic_css.preview_lifecycle_states")
        self.assertLess(valid, state_write)
        self.assertIn("lli     t2, dynamic_css.PREVIEW_STATE_VISIBLE", blank)
        self.assertIn("bne     t1, t2, _already_blank", blank)
        self.assertIn("lw      a0, 0x0008(s0)", blank)
        self.assertIn("jal     0x800D78E8", blank)
        self.assertIn("sw      r0, 0x0008(s0)", blank)
        self.assertLess(blank.index("jal     0x800D78E8"), blank.index("sw      r0, 0x0008(s0)"))
        self.assertIn("li      t0, dynamic_css.curr_slot_used_by_port", blank)
        self.assertIn("sb      t2, 0x0000(t0)", blank)
        self.assertIn("li      t4, dynamic_css.preview_retiring_slots", blank)
        self.assertIn("li      t4, dynamic_css.preview_retiring_character_ids", blank)
        self.assertIn("lli     t2, Character.id.NONE", blank)
        self.assertIn("sw      t2, 0x0048(s0)", blank)
        self.assertIn("lw      t0, 0x0010(s0)", blank)
        self.assertIn("lli     t2, 0x0001", blank)
        self.assertIn("sw      t2, 0x007C(t0)", blank)
        self.assertIn("sw      r0, 0x0000(t0)              // invalidate committed preview after teardown", blank)
        self.assertIn("lli     t2, dynamic_css.PREVIEW_STATE_BLANK_WAIT", blank)
        self.assertIn("j       0x801361E0", blank)

    def test_changes_while_blank_reset_request_without_repeating_teardown(self):
        self.assertIn("scope blank_visible_preview_:", self.source)
        blank = self.source.split("scope blank_visible_preview_:", 1)[1].split(
            "scope reclaim_retired_preview_slots_:", 1
        )[0]
        already_blank = blank.split("_already_blank:", 1)[1]
        self.assertNotIn("0x800D78E8", already_blank)
        self.assertIn("dynamic_css.debug_preview_duplicate_teardown_suppressed_count", already_blank)
        self.assertIn("j       0x801361E0", already_blank)

        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split(
            "_debounce_request_changed:", 1
        )[0]
        same = gate.split("bne     t4, a2, _debounce_request_changed", 1)[1]
        self.assertNotIn("PREVIEW_DEBOUNCE_FRAMES", same)
        self.assertIn("j       remain_blank_", same)
        self.assertNotIn("_replay_without_defer", gate)

    def test_retired_dynamic_slot_waits_for_protection_and_owner_validation(self):
        self.assertIn("preview_retiring_slots:; fill 0x0010", self.source)
        self.assertIn("preview_retiring_character_ids:; fill 0x0010", self.source)
        self.assertIn("debug_preview_retirement_busy_count:; fill 0x0010", self.source)
        self.assertIn("debug_preview_reclamation_completed_count:; fill 0x0010", self.source)

        self.assertIn("scope reclaim_retired_preview_slots_:", self.source)
        reclaim = self.source.split("scope reclaim_retired_preview_slots_:", 1)[1].split(
            "scope all_four_preview_panels_active_:", 1
        )[0]
        self.assertIn("sltiu   t9, a0, dynamic_css.ACTIVE_HEAP_COUNT", reclaim)
        self.assertIn("li      t4, dynamic_css.slot_used_by_port", reclaim)
        self.assertIn("lli     t5, 0x0008", reclaim)
        self.assertIn("beq     a0, t6, _protected", reclaim)
        self.assertIn("lw      t6, 0x0004(t7)", reclaim)
        self.assertIn("lbu     t6, 0x0008(t7)", reclaim)
        self.assertIn("lbu     t6, 0x0009(t7)", reclaim)
        self.assertIn("lbu     t6, 0x000A(t7)", reclaim)
        self.assertIn("lbu     t6, 0x000B(t7)", reclaim)
        owner_checks = reclaim.count("beq     a1, t6, _owner_matches")
        self.assertEqual(owner_checks, 5)
        reset_call = reclaim.index("jal     reset_heap_slot_")
        self.assertLess(reclaim.index("beq     a0, t6, _protected"), reset_call)
        self.assertLess(reclaim.rindex("beq     a1, t6, _owner_matches"), reset_call)
        self.assertIn("dynamic_css.debug_preview_retirement_busy_count", reclaim)
        self.assertIn("dynamic_css.debug_preview_reclamation_completed_count", reclaim)

        sync = self.source.split("scope sync_slot_used_by_port:", 1)[1].split(
            "scope seed_initial_preview_records_:", 1
        )[0]
        copy = sync.index("sw      t1, 0x0000(t0)")
        reclaim_call = sync.index("jal     reclaim_retired_preview_slots_")
        retry_call = sync.index("jal     retry_deferred_preview_requests_")
        self.assertLess(copy, reclaim_call)
        self.assertLess(reclaim_call, retry_call)

    def test_release_state_ready_busy_and_serialized_admission(self):
        self.assertIn("preview_release_records:; fill 0x0020", self.source)
        retry = self.source.split("scope retry_deferred_preview_requests_:", 1)[1].split(
            "scope use_custom_heap_structs_:", 1
        )[0]
        self.assertIn("li      t7, dynamic_css.preview_lifecycle_states", retry)
        self.assertIn("lli     t8, dynamic_css.PREVIEW_STATE_BLANK_READY", retry)
        ready_store = retry.index("sw      t8, 0x0000(t7)")
        preflight = retry.index("jal     preview_request_can_construct_")
        self.assertLess(ready_store, preflight)
        self.assertIn("dynamic_css.debug_preview_ready_busy_retry_count", retry)
        self.assertIn("li      t5, dynamic_css.preview_release_records", retry)
        self.assertIn("sw      a0, 0x0000(t5)", retry)
        self.assertIn("sw      a2, 0x0004(t5)", retry)
        self.assertIn("lli     t8, dynamic_css.PREVIEW_STATE_CONSTRUCTING", retry)
        self.assertIn("dynamic_css.debug_preview_construction_admitted_count", retry)
        self.assertEqual(retry.count("jal     0x80136128"), 1)
        accepted = retry.split("jal     0x80136128", 1)[1].split("_next:", 1)[0]
        self.assertIn("or      a0, r0, t3", accepted)
        self.assertIn("jal     0x80136300", accepted)
        self.assertIn("b       _return", accepted)

    def test_nested_construction_requires_exact_release_and_mismatch_restarts_wait(self):
        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split(
            "scope dynamically_load_character_:", 1
        )[0]
        entry = gate.split("// In four-player VS", 1)[0]
        self.assertIn("li      t7, dynamic_css.preview_lifecycle_states", entry)
        self.assertIn("lli     t8, dynamic_css.PREVIEW_STATE_CONSTRUCTING", entry)
        self.assertIn("li      t7, dynamic_css.preview_release_records", entry)
        self.assertIn("bne     t4, a0, _release_mismatch", entry)
        self.assertIn("bne     t4, a2, _release_mismatch", entry)
        exact = gate.split("_construction_release:", 1)[1].split("_release_mismatch:", 1)[0]
        self.assertIn("b       _run_preflight", exact)
        self.assertNotIn("PREVIEW_DEBOUNCE_FRAMES", exact)
        mismatch = gate.split("_release_mismatch:", 1)[1].split("_cancel_pending_request:", 1)[0]
        self.assertIn("sw      a0, 0x0000(t7)", mismatch)
        self.assertIn("sw      a2, 0x0004(t7)", mismatch)
        self.assertIn("lli     t4, dynamic_css.PREVIEW_DEBOUNCE_FRAMES", mismatch)
        self.assertIn("lli     t4, dynamic_css.PREVIEW_STATE_BLANK_WAIT", mismatch)
        self.assertIn("j       remain_blank_", mismatch)

    def test_successful_commit_clears_pending_release_and_publishes_visible_last(self):
        commit = self.source.split("scope preview_commit_:", 1)[1].split("_replay:", 1)[0]
        self.assertIn("li      t7, dynamic_css.preview_deferred_records", commit)
        self.assertIn("li      t7, dynamic_css.preview_release_records", commit)
        self.assertIn("li      t7, dynamic_css.preview_debounce_frames", commit)
        self.assertIn("li      t7, dynamic_css.preview_lifecycle_states", commit)
        visible = commit.rindex("sw      r0, 0x0000(t7)              // publish VISIBLE last")
        committed_valid = commit.index("sw      t1, 0x0000(t2)                  // publish valid last")
        self.assertLess(committed_valid, visible)
        self.assertLess(commit.index("dynamic_css.preview_deferred_records"), visible)
        self.assertLess(commit.index("dynamic_css.preview_release_records"), visible)

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
            "scope blank_visible_preview_:", 1
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
            "scope blank_visible_preview_:", 1
        )[0]
        range_check = preflight.split("li      t0, 0x80116E10", 1)[0]
        self.assertIn("or      v1, r0, r0", range_check)
        self.assertIn("sltiu   t9, a0, Character.NUM_CHARACTERS", range_check)
        self.assertIn("beqz    t9, _return", range_check)
        self.assertIn("lli     v1, OS.TRUE", range_check)
        self.assertLess(range_check.index("beqz    t9, _return"), range_check.index("lli     v1, OS.TRUE"))

    def test_preflight_denies_reserved_sentinel_ids_before_table_access(self):
        preflight = self.source.split("scope preview_request_can_construct_:", 1)[1].split(
            "scope blank_visible_preview_:", 1
        )[0]
        validation = preflight.split("li      t0, 0x80116E10", 1)[0]
        self.assertIn("lli     t8, Character.id.PLACEHOLDER", validation)
        self.assertIn("lli     t8, Character.id.NONE", validation)
        self.assertEqual(validation.count("beq     a0, t8, _return"), 2)
        accept = validation.index("lli     v1, OS.TRUE")
        self.assertLess(validation.index("lli     t8, Character.id.PLACEHOLDER"), accept)
        self.assertLess(validation.index("lli     t8, Character.id.NONE"), accept)

        gate = self.source.split("scope preview_teardown_gate_:", 1)[1].split("_count_veto:", 1)[0]
        normal = gate.split("_normal_request:", 1)[1]
        queue_store = normal.index("sw      a0, 0x0000(t7)")
        self.assertIn("_replay_without_defer:", gate)
        self.assertIn("sltiu   at, a0, Character.NUM_CHARACTERS", normal)
        self.assertIn("lli     t8, Character.id.PLACEHOLDER", normal)
        self.assertIn("lli     t8, Character.id.NONE", normal)
        self.assertLess(normal.index("sltiu   at, a0, Character.NUM_CHARACTERS"), queue_store)
        self.assertLess(normal.index("lli     t8, Character.id.NONE"), queue_store)

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
        self.assertIn("li      t7, dynamic_css.preview_release_records", cancel)
        self.assertIn("li      t7, dynamic_css.preview_lifecycle_states", cancel)
        self.assertIn("bne     t4, t5, _cancel_remain_blank", cancel)
        self.assertIn("jal     all_four_preview_panels_active_", cancel)
        self.assertIn("beqz    v1, _run_preflight", cancel)
        self.assertIn("jal     blank_visible_preview_", cancel)
        remain = cancel.split("_cancel_remain_blank:", 1)[1]
        self.assertIn("j       remain_blank_", remain)

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
        self.assertIn("jal     blank_visible_preview_", changed)

    def test_debounce_expiry_keeps_preflight_and_serialized_admission(self):
        retry = self.source.split("scope retry_deferred_preview_requests_:", 1)[1].split(
            "scope use_custom_heap_structs_:", 1
        )[0]
        self.assertIn("jal     all_four_preview_panels_active_", retry)
        self.assertIn("li      t4, dynamic_css.preview_debounce_frames", retry)
        self.assertIn("lw      t6, 0x0000(t4)", retry)
        self.assertIn("beqz    v1, _debounce_ready", retry)
        self.assertIn("beqz    t6, _debounce_ready", retry)
        zero_check = retry.index("beqz    t6, _debounce_ready")
        decrement = retry.index("addiu   t6, t6, -0x0001")
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
        self.assertIn("li      t5, dynamic_css.preview_release_records", retry)
        self.assertIn("lli     t8, dynamic_css.PREVIEW_STATE_CONSTRUCTING", retry)
        loader_call = "jal     0x80136128"
        self.assertIn(loader_call, accepted)
        self.assertIn("or      a0, r0, t3", accepted)
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
        self.assertIn("beqz    v1, _ready_busy", retry)
        self.assertIn("sw      a0, 0x0048(t0)", retry)
        self.assertIn("sb      a2, 0x0000(t5)", retry)
        accepted = retry.split("sw      a0, 0x0048(t0)", 1)[1].split("_next:", 1)[0]
        self.assertIn("li      t5, dynamic_css.preview_release_records", retry)
        self.assertIn("lli     t8, dynamic_css.PREVIEW_STATE_CONSTRUCTING", retry)
        loader_call = "jal     0x80136128"
        self.assertIn(loader_call, accepted)
        self.assertIn("or      a0, r0, t3", accepted)
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
        self.assertIn("v4", MARKER)
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
