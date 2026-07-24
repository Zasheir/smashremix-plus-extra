import argparse

TEMPLATE = """[{}-{}-C:45]
Good Name=SmashRemix2.0.1 {}
Internal Name=SmashRemixExtra
Status=Compatible
Counter Factor=1
Culling=1
SMM-Cache=0
SMM-FUNC=0
SMM-TLB=0
RDRAM Size=8
Use TLB=No
ViRefresh=2200"""


def main(filename):
    with open(filename, "rb") as f:
        f.seek(0x10)
        val1 = f.read(4)
        val2 = f.read(4)
    hex1 = val1.hex().upper()
    hex2 = val2.hex().upper()

    with open("version.txt", 'r', encoding='utf-8') as f:
        version = f.read()

    print(TEMPLATE.format(hex1, hex2, version))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate RDB entry from ROM file."
    )
    parser.add_argument(
        "filename",
        nargs="?",
        default="ssb64asm_extra.z64",
        help="Path to the ROM file (default: %(default)s)"
    )
    args = parser.parse_args()
    main(args.filename)
