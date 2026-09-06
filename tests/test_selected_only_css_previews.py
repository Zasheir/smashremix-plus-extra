import pytest

import character_appender
from character_appender import CharacterAppender
from smashremix_extra.selected_preview_gate import (
    MARKER,
    transform_character_select,
)


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
}

} // __CHARACTER_SELECT__
"""


def test_hover_preview_construction_is_vetoed_until_selection():
    transformed = transform_character_select(PRISTINE_SOURCE)

    assert transformed.count(MARKER) == 1
    assert "OS.patch_start(0x134458, 0x801361D8)" in transformed
    assert "jal     selected_preview_make_gate_" in transformed
    assert "or      a3, v0, r0" in transformed

    assert "scope selected_preview_make_gate_:" in transformed
    assert "constant CSS_PLAYER_STRUCT(0x8013BA88)" in transformed
    assert "lli     t1, 0x00BC" in transformed
    assert "lw      t2, 0x0058(t0)" in transformed
    assert "bnez    t2, _allow" in transformed
    assert "li      t2, force_selected_preview" in transformed
    assert "lw      t2, 0x0000(t2)" in transformed
    assert "lw      t2, force_selected_preview" not in transformed
    assert "beqz    a0, _return" in transformed
    assert "sw      t2, 0x007C(a0)" in transformed
    assert "j       0x80134A8C" in transformed
    assert "j       0x80134AF8" not in transformed

    assert "0x80136300" not in transformed
    assert "0x80500000" not in transformed
    assert "0x80780000" not in transformed
    assert "0x0008(t0)" not in transformed
    assert "0x0010(t0)" not in transformed
    assert "HEAP_SIZE" not in transformed
    assert "ACTIVE_HEAP_COUNT" not in transformed
    assert "heap_slot" not in transformed
    assert "evict" not in transformed.lower()


def test_selection_input_forces_one_stock_preview_update_before_a_or_c_selection():
    transformed = transform_character_select(PRISTINE_SOURCE)

    assert "OS.patch_start(0x135474, 0x801371F4)" in transformed
    assert "jal     selected_preview_on_select_" in transformed
    assert "sw      v1, 0x0018(sp)" in transformed

    assert "scope selected_preview_on_select_:" in transformed
    assert "lw      t0, 0x0080(t0)" in transformed
    assert "sw      t1, 0x0000(t2)" in transformed
    assert "jal     0x80136128" in transformed
    assert "sw      r0, 0x0000(t2)" in transformed
    assert "jal     0x80131C74" in transformed
    assert "j       0x80131C74" not in transformed

    force_set = transformed.index("sw      t1, 0x0000(t2)")
    stock_update = transformed.index("jal     0x80136128")
    force_clear = transformed.index("sw      r0, 0x0000(t2)")
    stock_selection = transformed.index("jal     0x80131C74")
    assert force_set < stock_update < force_clear < stock_selection


def test_denied_costume_selection_hides_the_forced_preview_after_stock_returns():
    transformed = transform_character_select(PRISTINE_SOURCE)

    stock_selection = transformed.index("jal     0x80131C74")
    selected_check = transformed.index("lw      t2, 0x0058(t1)", stock_selection)
    denied_update = transformed.index("jal     0x80136128", stock_selection)
    return_to_caller = transformed.index("jr      ra", stock_selection)

    assert stock_selection < selected_check < denied_update < return_to_caller
    assert "bnez    t2, _return" in transformed[stock_selection:denied_update]
    assert "sw      r0, 0x0000(t2)" in transformed[:stock_selection]


def test_unselected_hover_skips_stock_indicator_before_player_object_dereference():
    transformed = transform_character_select(PRISTINE_SOURCE)

    draw_indicator = transformed.index("_draw_indicator:")
    selected_load = transformed.index("lw      t1, 0x0088(s2)", draw_indicator)
    selected_branch = transformed.index("beqz    t1, _next", selected_load)
    stack_allocation = transformed.index("addiu   sp, sp,-0x0020", selected_branch)

    assert draw_indicator < selected_load < selected_branch < stack_allocation


def test_transform_is_idempotent_only_for_the_canonical_marked_region():
    transformed = transform_character_select(PRISTINE_SOURCE)

    assert transform_character_select(transformed) == transformed

    corruptions = (
        transformed.replace(MARKER, f"{MARKER}\n    // injected", 1),
        transformed.replace(MARKER, "// +EXTRA selected-only VS CSS previews v0", 1),
        transformed.replace(MARKER, f"{MARKER}\n    {MARKER}", 1),
        transformed.replace("0x80134A8C", "0x80134A90", 1),
        PRISTINE_SOURCE.replace(
            "    constant CSS_PLAYER_STRUCT_TRAINING(0x80138558)\n",
            "    // injected in selected-preview transform region\n"
            "    constant CSS_PLAYER_STRUCT_TRAINING(0x80138558)\n",
        ),
        PRISTINE_SOURCE.replace(
            "    constant CSS_PLAYER_STRUCT(0x8013BA88)\n",
            "    constant CSS_PLAYER_STRUCT(0x8013BA88)\n"
            "    constant CSS_PLAYER_STRUCT(0x8013BA88)\n",
        ),
        PRISTINE_SOURCE.replace(
            "    constant CSS_PLAYER_STRUCT_TRAINING(0x80138558)\n", "",
        ),
        PRISTINE_SOURCE + "// +EXTRA no-preview v3\n",
        PRISTINE_SOURCE + "// +EXTRA preview lifecycle v1\n",
        PRISTINE_SOURCE + "// +EXTRA preview debounce v1\n",
    )

    for source in corruptions:
        with pytest.raises(ValueError):
            transform_character_select(source)


@pytest.mark.parametrize(
    "legacy_marker",
    (
        "// +EXTRA safe multiplayer no-preview v3",
        "// +EXTRA multiplayer fighter-preview suppression v1",
        "// +EXTRA multiplayer fighter-preview suppression v2",
        "// +EXTRA committed preview replay spike",
        "// +EXTRA committed preview replay spike v5",
        "// +EXTRA preview teardown gate spike",
        "// +EXTRA exact serialized CSS preview scheduler",
    ),
)
def test_known_historical_preview_transform_markers_fail_closed(legacy_marker):
    with pytest.raises(ValueError, match="legacy CSS preview marker present"):
        transform_character_select(f"{PRISTINE_SOURCE}\n{legacy_marker}\n")


def test_unrelated_preview_comment_remains_allowed():
    source = f"{PRISTINE_SOURCE}\n// +EXTRA stage thumbnail preview note\n"
    transformed = transform_character_select(source)

    assert transformed.count(MARKER) == 1
    assert "stage thumbnail preview note" in transformed


def test_edit_src_files_transforms_character_select_once(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    rom_root = tmp_path / "smashremix"
    (rom_root / "roms").mkdir(parents=True)
    (rom_root / "roms" / "original_extra.z64").write_bytes(b"rom")
    (tmp_path / "src").mkdir()
    character_select = tmp_path / "src" / "CharacterSelect.asm"
    character_select.write_text(PRISTINE_SOURCE, encoding="utf-8")
    monkeypatch.setattr(character_appender, "smashremix_path", str(rom_root))

    appender = object.__new__(CharacterAppender)
    for method_name in (
        "_patch_src_paths",
        "_patch_audio_asm",
        "_patch_character_asm",
        "_patch_stage_asm",
        "_patch_toggle_asm",
    ):
        setattr(appender, method_name, lambda *_: None)

    calls = []

    def transform_once(source):
        calls.append(source)
        return transform_character_select(source)

    appender.selected_preview_transform = transform_once
    appender.edit_src_files()

    assert calls == [PRISTINE_SOURCE]
    assert character_select.read_text(encoding="utf-8").count(MARKER) == 1
