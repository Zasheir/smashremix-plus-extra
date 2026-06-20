from dataclasses import dataclass

SMASHREMIX_PATH = "smashremix"

VARIANT_TYPES = ["dl", "omega", "remix", "remix2", "remix3", "remix4", "remix5", "remix6"]

PRIMARY_MOVESETS = {
    "MARIO": "0x0CA",
    "METAL": "0x0CD",
    "FOX": "0x0D0",
    "DONKEY": "0x0D4",
    "SAMUS": "0x0D8",
    "LUIGI": "0x0DC",
    "LINK": "0x0E0",
    "KIRBY": "0x0E4",
    "JIGGLYPUFF": "0x0E8",
    "CAPTAIN": "0x0EB",
    "NESS": "0x0EE",
    "PIKACHU": "0x0F2",
    "YOSHI": "0x0F6",
    "BOSS": "0x0F9"
}

SHIELD_POSES = {
    "MARIO": "0x012A",
    "METAL": "0x012A",
    "FOX": "0x013A",
    "DONKEY": "0x013E",
    "SAMUS": "0x0142",
    "LUIGI": "0x012A",
    "LINK": "0x0147",
    "KIRBY": "0x0149",
    "JIGGLYPUFF": "0x014B",
    "CAPTAIN": "0x014E",
    "NESS": "0x0151",
    "PIKACHU": "0x0157",
    "YOSHI": "0x0154"
}

COMMAND_SIZES = {
    "0C": 5,
    "0D": 5,
    "10": 5,
    "30": 2,
    "34": 2,
    "7C": 4,
    "88": 2,
    "90": 2,
    "98": 4,
    "9A": 4,
    "9C": 4,
    "B8": 2,
}


@dataclass
class ExtraFile:
    filename: str
    character_list_id: int
    InternalFileTableOffsetBytes: int
    InternalFileResourceOffsetBytes: int
    game_file_id: int = -1
