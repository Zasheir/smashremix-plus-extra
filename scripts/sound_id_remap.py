import os

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

id_old_new = {
    "058F": "FFF0",  # PUNCH_S
    "0590": "FFF1",  # PUNCH_M
    "0591": "FFF2",  # PUNCH_L
    "057B": "FFF3",  # KICK_S
    "057C": "FFF4",  # KICK_M
    "057D": "FFF5",  # KICK_L
    "057E": "FFF6",  # WHOOSH_S
    "057F": "FFF7",  # WHOOSH_M
    "0580": "FFF8",  # WHOOSH_L
    "0582": "FFF9",  # HADOUKEN
    "0583": "FFFA",  # SHORYUKEN
    "058E": "FFFB",  # GROUND_BUMP
    "0585": "FFFC",  # TATSU_S
    "0584": "FFFD",  # TATSU
    "0592": "FFFE",  # DIZZY
    "0593": "FFFF",  # TECH
    "0581": "FFE0",  # THROW
    "0599": "FFE1",  # DAMAGED
    "0586": "FFE2",  # DIE
    "058D": "FFE3",  # PERFECT
    "0594": "FFE4",  # SEYA
    "0595": "FFE5",  # YA
}

os.makedirs(f"./out/", exist_ok=True)

for moveset_file in os.listdir(f"."):
    if not moveset_file.lower().endswith(".bin"):
        continue

    print(f"Compiling moveset file: {moveset_file}")

    with open(f"{moveset_file}", 'rb') as binary_file:
        data = bytearray(binary_file.read())

    pos = 0

    while pos < len(data):
        command = data[pos:pos+1].hex().upper()
        command_size = (COMMAND_SIZES.get(command) or 1) * 4
        if command in ["38", "3C", "40", "44", "48", "4C", "50"]:
            sfx = data[pos+2:pos+4].hex().upper()

            if sfx in id_old_new:
                print(f"REPLACING SFX: {
                    command} - SOUND ID [{sfx}] -> (0x{id_old_new[sfx]})")
                # Replace the original 4 digits with the new ones
                new_sfx = bytes.fromhex(id_old_new[sfx])
                data[pos+2:pos+4] = new_sfx

                if sfx in ["057E", "057F", "0580"]:
                    data[pos:pos+1] = bytes.fromhex("4C")
        pos += command_size

    with open(f"./out/{moveset_file}", 'wb') as binary_file:
        binary_file.write(data)
