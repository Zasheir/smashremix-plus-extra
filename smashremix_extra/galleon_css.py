"""Project Galleon-inspired 12x4 character-select layout for +EXTRA.

The geometry is ported from Project Galleon 1.3.7.1b
(commit 39d357417b995a47998e249ddde9b03f09db8aea).  The target roster keeps
+EXTRA character IDs and native portraits
"""

from __future__ import annotations

import re


GALLEON_CSS_LAYOUT = (
    # row 1
    "GOEMON", "EBI",       "WARIO",   "DRL",   "DRM",    "LANKY",      "DSAMUS",  "GND",     "YLINK",      "YZELDA", "WOLF",   "RYU",
    # row 2
    "MARINA", "PEACH",     "BOWSER",  "LUIGI", "MARIO",  "DONKEY",     "SAMUS",   "CAPTAIN", "LINK",       "SHEIK",  "FALCO",  "KEN",
    # row 3
    "SONIC",  "MKNUCKLES", "LUCAS",   "NESS",  "YOSHI",  "KIRBY",      "FOX",     "PIKACHU", "JIGGLYPUFF", "MTWO",   "PEPPY",  "PIANO", 
    # row 4
    "SNAKE",  "CLOUD",     "MARTH",   "ROY",   "BIRDO",  "METAKNIGHT", "DEDEDE",  "BANJO",   "CONKER",     "CRASH",  "SLIPPY", "DRAGONKING", 
)

# Character variants need to recall their parent's grid portrait and variant row.
VARIANT_PARENTS = {
    "METAL": "MARIO",
    "NMARIO": "MARIO",
    "ELINK": "LINK",
    "JLINK": "LINK",
    "NLINK": "LINK",
    "JSAMUS": "SAMUS",
    "ESAMUS": "SAMUS",
    "NSAMUS": "SAMUS",
    "JNESS": "NESS",
    "NNESS": "NESS",
    "JFALCON": "CAPTAIN",
    "NCAPTAIN": "CAPTAIN",
    "JFOX": "FOX",
    "NFOX": "FOX",
    "JMARIO": "MARIO",
    "JLUIGI": "LUIGI",
    "NLUIGI": "LUIGI",
    "JDK": "DONKEY",
    "GDONKEY": "DONKEY",
    "NDONKEY": "DONKEY",
    "EPIKA": "PIKACHU",
    "JPIKA": "PIKACHU",
    "NPIKACHU": "PIKACHU",
    "JPUFF": "JIGGLYPUFF",
    "EPUFF": "JIGGLYPUFF",
    "NJIGGLY": "JIGGLYPUFF",
    "JKIRBY": "KIRBY",
    "NKIRBY": "KIRBY",
    "JYOSHI": "YOSHI",
    "NYOSHI": "YOSHI",
    "BOSS": "LINK",
    "GBOWSER": "BOWSER",
    "NBOWSER": "BOWSER",
    "SSONIC": "SONIC",
    "NSONIC": "SONIC",
    "MLUIGI": "LUIGI",
    "NWARIO": "WARIO",
    "NLUCAS": "LUCAS",
    "NWOLF": "WOLF",
    "NDRM": "DRM",
    "NSHEIK": "SHEIK",
    "NMARINA": "MARINA",
    "NFALCO": "FALCO",
    "NGND": "GND",
    "NDSAMUS": "DSAMUS",
    "NMARTH": "MARTH",
    "NMTWO": "MTWO",
    "NDEDEDE": "DEDEDE",
    "NYLINK": "YLINK",
    "NGOEMON": "GOEMON",
    "NCONKER": "CONKER",
    "NBANJO": "BANJO",
    "NPEACH": "PEACH",
    "NCRASH": "CRASH",
}

# Zero-based portrait IDs for every selectable grid character.
_CANONICAL_SLOTS = {name: i for i, name in enumerate(GALLEON_CSS_LAYOUT)}


def css_slot_override(character: str) -> int | None:
    """Return a zero-based canonical CSS portrait ID for a character/variant."""
    character = character.upper()
    character = VARIANT_PARENTS.get(character, character)
    return _CANONICAL_SLOTS.get(character)


def _variant_original_block() -> str:
    mappings = {character: character for character in GALLEON_CSS_LAYOUT}
    mappings.update(VARIANT_PARENTS)
    lines = [
        "    // Project Galleon CSS variant-original mappings",
        "    pushvar origin, base",
    ]
    for character, parent in mappings.items():
        lines.extend((
            "    origin Character.variant_original.TABLE_ORIGIN + "
            f"(Character.id.{character} * 4)",
            f"    dw Character.id.{parent}",
        ))
    lines.extend(("    pullvar base, origin", ""))
    return "\n".join(lines)


def filter_bonus_characters(characters: list[str]) -> list[str]:
    """Keep only characters which are not already present in the 48-slot grid."""
    grid = set(GALLEON_CSS_LAYOUT)
    return [character for character in characters if character.upper() not in grid]


def _replace_definition(source: str, name: str, value: str) -> str:
    pattern = rf"constant {re.escape(name)}\([^\n)]*\)"
    updated, count = re.subn(pattern, f"constant {name}({value})", source, count=1)
    if count != 1:
        raise ValueError(f"Could not uniquely replace CharacterSelect constant {name}")
    return updated


def _layout_block() -> str:
    lines = ["    constant NUM_SLOTS(48)", "    scope layout {"]
    for row in range(4):
        lines.append(f"        // row {row + 1}")
        for column in range(12):
            slot = row * 12 + column + 1
            lines.append(f"        define slot_{slot}({GALLEON_CSS_LAYOUT[slot - 1]})")
        if row != 3:
            lines.append("")
    lines.append("    }")
    return "\n".join(lines)


def _patch_add_to_css_overrides(source: str) -> str:
    pattern = re.compile(
        r"(add_to_css\(Character\.id\.(\w+),[^\n]*,\s*)"
        r"(-?\d+|BOOKEND_BONUS_PORTRAIT)(\))"
    )

    def replace(match: re.Match[str]) -> str:
        override = css_slot_override(match.group(2))
        if override is None:
            return match.group(0)
        return f"{match.group(1)}{override}{match.group(4)}"

    return pattern.sub(replace, source)


def port_galleon_css_source(
    source: str,
) -> str:
    """Transform generated Smash Remix 2.0.1 CSS source into the 12x4 port."""
    definitions = {
        "START_X": "42",
        "NUM_ROWS": "4",
        "NUM_COLUMNS": "12",
        "PORTRAIT_SCALE": "0x3F1A",
        "PORTRAIT_WIDTH": "18",
        "PORTRAIT_HEIGHT": "18",
        "TOKEN_Y_OFFSET": "0xC135",
        "RANDOM_TOKEN_X": "0x478B",
        "RANDOM_TOKEN_X_INT": "270",
        "TOKEN_OFFSET_Y": "-4",
    }
    for name, value in definitions.items():
        source = _replace_definition(source, name, value)

    layout_pattern = re.compile(
        r"    constant NUM_SLOTS\([^\n]+\)\n"
        r"    scope layout \{.*?\n    \}\n\n"
        r"(?=    // @ Description\n    // This renders the portraits)",
        re.DOTALL,
    )
    source, count = layout_pattern.subn(_layout_block() + "\n\n", source, count=1)
    if count != 1:
        raise ValueError("Could not replace CharacterSelect layout block")

    bonus_pattern = re.compile(
        r"(^\s*bonus_chars:\s*\n)(.*?)"
        r"(^\s*OS\.align\(4\)\s*\n\s*constant NUM_BONUS_CHARS\()[^)]*(\))",
        re.DOTALL | re.MULTILINE,
    )
    match = bonus_pattern.search(source)
    if not match:
        raise ValueError("Could not locate CharacterSelect bonus character table")
    bonus_ids = re.findall(r"db Character\.id\.(\w+)", match.group(2))
    bonus_ids = filter_bonus_characters(bonus_ids)
    bonus_lines = "".join(f"    db Character.id.{name}\n" for name in bonus_ids)
    replacement = (
        f"{match.group(1)}{bonus_lines}{match.group(3)}"
        f"{len(bonus_ids)}{match.group(4)}"
    )
    source = source[:match.start()] + replacement + source[match.end():]

    portrait_defs_marker = "        // Project Galleon CSS portrait aliases\n"
    portrait_defs_pattern = re.compile(
        re.escape(portrait_defs_marker)
        + r"        constant GALLEON_SWORD_KNIGHT\([^\n]+\)\n"
        + r"        constant GALLEON_UZI\([^\n]+\)\n"
    )
    source = portrait_defs_pattern.sub("", source)
    portrait_table_pattern = re.compile(
        r"    portrait_offset_table:\n"
        r"    evaluate n\(0\)\n"
        r"    while NUM_SLOTS > \{n\} \{.*?"
        r"    OS\.align\(4\)\n",
        re.DOTALL,
    )
    portrait_table = """    portrait_offset_table:
    evaluate n(0)
    while NUM_SLOTS > {n} {
        evaluate n({n} + 1)
        dw portrait_offsets.{layout.slot_{n}}
    }
    dw portrait_offsets.BONUS_BOOKEND
    dw portrait_offsets.RANDOM_BOOKEND
    OS.align(4)
"""
    source, count = portrait_table_pattern.subn(portrait_table, source, count=1)
    if count != 1:
        raise ValueError("Could not replace CharacterSelect portrait offset table")

    velocity_pattern = re.compile(
        r"    portrait_velocity:\n.*?\n\n"
        r"(?=    // @ Description\n    // Pointer to id_table)",
        re.DOTALL,
    )
    velocity_table = """    portrait_velocity:
    float32 2.9                               // column 1
    float32 3.9                               // column 2
    float32 5.9                               // column 3
    float32 7.8                               // column 4
    float32 11.8                              // column 5
    float32 13.8                              // column 6
    float32 -13.8                             // column 7
    float32 -11.8                             // column 8
    float32 -7.8                              // column 9
    float32 -5.9                              // column 10
    float32 -3.9                              // column 11
    float32 -2.3                              // column 12
    float32 1.9                               // left bookend
    float32 -1.4                              // right bookend

"""
    source, count = velocity_pattern.subn(velocity_table, source, count=1)
    if count != 1:
        raise ValueError("Could not replace CharacterSelect portrait velocity table")

    source = _replace_definition(source, "HEAP_SIZE", "0x0001F000")
    source = _patch_add_to_css_overrides(source)

    variant_marker = "    // Project Galleon CSS variant-original mappings\n"
    variant_pattern = re.compile(
        re.escape(variant_marker)
        + r"    pushvar origin, base\n.*?"
        + r"    pullvar base, origin\n",
        re.DOTALL,
    )
    source = variant_pattern.sub("", source)
    closing_pattern = re.compile(r"\n(?=}\n\n\n} // __CHARACTER_SELECT__)")
    source, count = closing_pattern.subn(
        "\n" + _variant_original_block(),
        source,
        count=1,
    )
    if count != 1:
        raise ValueError("Could not insert CharacterSelect variant-original mappings")
    return source
