import importlib
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASE_CSS = ROOT / "smashremix" / "src" / "CharacterSelect.asm"


class GalleonCssPortTests(unittest.TestCase):
    def load_port(self):
        spec = importlib.util.find_spec("smashremix_extra.galleon_css")
        self.assertIsNotNone(spec, "galleon_css port module is not implemented")
        return importlib.import_module("smashremix_extra.galleon_css")

    def transformed_source(self):
        port = self.load_port()
        return port.port_galleon_css_source(
            BASE_CSS.read_text(encoding="utf-8"),
        )

    def test_layout_is_12_by_4_with_target_roster(self):
        port = self.load_port()
        expected = (
            "GOEMON", "EBI", "WARIO", "DRL", "DRM", "LANKY",
            "DSAMUS", "GND", "YLINK", "YZELDA", "WOLF", "RYU",
            "MARINA", "PEACH", "BOWSER", "LUIGI", "MARIO", "DONKEY",
            "SAMUS", "CAPTAIN", "LINK", "SHEIK", "FALCO", "KEN",
            "SONIC", "MKNUCKLES", "LUCAS", "NESS", "YOSHI", "KIRBY",
            "FOX", "PIKACHU", "JIGGLYPUFF", "MTWO", "PEPPY", "PIANO",
            "SNAKE", "CLOUD", "MARTH", "ROY", "BIRDO", "METAKNIGHT",
            "DEDEDE", "BANJO", "CONKER", "CRASH", "SLIPPY", "DRAGONKING",
        )
        self.assertEqual(expected, port.GALLEON_CSS_LAYOUT)
        self.assertEqual(48, len(set(port.GALLEON_CSS_LAYOUT)))

    def test_source_uses_galleon_geometry_and_native_portraits(self):
        source = self.transformed_source()
        for definition in (
            "constant START_X(42)",
            "constant NUM_ROWS(4)",
            "constant NUM_COLUMNS(12)",
            "constant NUM_SLOTS(48)",
            "constant PORTRAIT_WIDTH(18)",
            "constant PORTRAIT_HEIGHT(18)",
            "define slot_10(YZELDA)",
            "define slot_41(BIRDO)",
            "dw portrait_offsets.{layout.slot_{n}}",
        ):
            self.assertIn(definition, source)

        self.assertNotRegex(source, r"Character\.id\.(?:SKNIGHT|UZI|LUCIA)\b")
        self.assertNotIn("GALLEON_SWORD_KNIGHT", source)
        self.assertNotIn("GALLEON_UZI", source)
        self.assertNotIn("PROJECTGALLEONCSS", source)

    def test_galleon_keeps_the_standard_1d000_preview_heap_size(self):
        source = self.transformed_source()
        self.assertIn("constant HEAP_SIZE(0x0001D000)", source)
        self.assertNotIn("constant HEAP_SIZE(0x0001F000)", source)

    def test_grid_characters_are_removed_from_bonus_bookend(self):
        port = self.load_port()
        bonus = [
            "DSAMUS", "LUCAS", "PEPPY", "SLIPPY", "ROY", "DRL", "LANKY",
            "DRAGONKING", "EBI", "PIANO", "BIRDO", "CLOUD", "MKNUCKLES",
            "YZELDA", "KEN", "METAKNIGHT", "MRGAW", "RYU", "SNAKE",
            "SPIDERMAN",
        ]
        self.assertEqual(
            ["MRGAW", "SPIDERMAN"],
            port.filter_bonus_characters(bonus),
        )

    def test_character_slot_overrides_resolve_to_canonical_portraits(self):
        port = self.load_port()
        self.assertEqual(35, port.css_slot_override("PIANO"))
        self.assertEqual(3, port.css_slot_override("DRL"))
        self.assertEqual(9, port.css_slot_override("YZELDA"))
        self.assertEqual(40, port.css_slot_override("BIRDO"))
        self.assertEqual(37, port.css_slot_override("CLOUD"))
        self.assertEqual(25, port.css_slot_override("MKNUCKLES"))
        self.assertIsNone(port.css_slot_override("SPIDERMAN"))
        self.assertEqual(20, port.css_slot_override("ELINK"))
        self.assertEqual(18, port.css_slot_override("JSAMUS"))

    def test_all_grid_fighters_and_variants_use_the_correct_variant_original(self):
        port = self.load_port()
        source = self.transformed_source()

        expected = {character: character for character in port.GALLEON_CSS_LAYOUT}
        expected.update(port.VARIANT_PARENTS)

        marker = "// Project Galleon CSS variant-original mappings"
        self.assertEqual(1, source.count(marker))
        for character, parent in expected.items():
            assignment = (
                "origin Character.variant_original.TABLE_ORIGIN + "
                f"(Character.id.{character} * 4)\n"
                f"    dw Character.id.{parent}"
            )
            self.assertIn(assignment, source, character)

    def test_all_variant_portrait_overrides_resolve_to_the_parent_slot(self):
        port = self.load_port()
        for character, parent in port.VARIANT_PARENTS.items():
            expected_slot = port.css_slot_override(parent)
            if expected_slot is not None:
                self.assertEqual(
                    expected_slot,
                    port.css_slot_override(character),
                    character,
                )

    def test_transform_is_idempotent(self):
        port = self.load_port()
        once = self.transformed_source()
        twice = port.port_galleon_css_source(
            once,
        )
        self.assertEqual(once, twice)

    def test_native_portraits_are_valid_32px_rgba_images(self):
        from PIL import Image

        for character in ("YZelda", "Birdo"):
            for filename in ("portrait.png", "portrait_flash.png"):
                path = ROOT / "extra_characters" / character / filename
                with Image.open(path) as image:
                    self.assertEqual((32, 32), image.size)
                    self.assertEqual("RGBA", image.mode)


if __name__ == "__main__":
    unittest.main()
