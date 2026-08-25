import unittest

import character_appender


class StageMenuPaginationTests(unittest.TestCase):
    def test_variants_do_not_shift_random_from_lower_right_slot(self):
        build_pages = getattr(character_appender, "build_stage_menu_pages", None)
        if build_pages is None:
            self.fail("character_appender.build_stage_menu_pages is not implemented")

        visible_stages = [f"Stage{i:02d}" for i in range(26)]
        stage_folders = (
            visible_stages[:5]
            + ["Stage04/dl"]
            + visible_stages[5:12]
            + ["Stage11/remix"]
            + visible_stages[12:20]
            + ["Stage19/omega"]
            + visible_stages[20:]
        )

        pages = build_pages(stage_folders, stages_per_page=18)

        self.assertEqual(2, len(pages))
        self.assertEqual(visible_stages[:17] + ["RANDOM"], pages[0])
        self.assertEqual(visible_stages[17:] + ["RANDOM"] * 9, pages[1])
        self.assertNotIn("Stage04/dl", pages[0] + pages[1])
        self.assertNotIn("Stage11/remix", pages[0] + pages[1])
        self.assertNotIn("Stage19/omega", pages[0] + pages[1])


if __name__ == "__main__":
    unittest.main()
