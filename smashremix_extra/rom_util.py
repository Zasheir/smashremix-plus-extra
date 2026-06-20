import os
import platform
import shlex
import subprocess
from typing import Callable, Optional

from SSB import SSBtbl, N64
from smashremix_extra import hex_util


def run_windows_command(
    command: str,
    on_output: Optional[Callable[[str], None]] = None
) -> subprocess.CompletedProcess:
    """Run a Windows executable, prepending 'wine' automatically on Linux."""
    if platform.system() == "Linux":
        command = f"wine {command}"

    print(f"Running command: {command}")

    process = subprocess.Popen(
        shlex.split(command, posix=False),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    collected_output = []
    for line in process.stdout:
        line = line.rstrip()
        collected_output.append(line)
        if on_output:
            on_output(line)

    process.wait()

    return subprocess.CompletedProcess(
        args=command,
        returncode=process.returncode,
        stdout="\n".join(collected_output),
        stderr=None
    )


def get_attrib_offset(main_file_path: str) -> str:
    """Return the hex offset of the character attribute block in a main.bin file."""
    pattern = b'\x00\x64\x00\x64'  # 0x00640064
    with open(main_file_path, 'rb') as f:
        binary_data = f.read()
    last_position = hex_util.find_last_instance_of_pattern(binary_data, pattern)
    return hex(last_position - 228)[2:]


def extract_files(smashremix_path: str) -> None:
    """Extract the ROM files that need to be edited from original.z64 into scripts/."""
    FILES_TO_EXTRACT = [
        0xC,     # 1p vs screen nameplate
        0x11,    # CSS nameplate
        0x14,    # Big series logo (background in CSS, stage series logo)
        0x23,    # 3d series logo used in the Results screen
        0x153E,  # Stage icons 2
        0xA05,   # Character portraits
        0x10F5,  # Data screen bios
        0x10F6,  # Data screen names, works, special attacks
    ]

    rom_file_entries = SSBtbl.fromROM(
        N64(open(os.path.join(smashremix_path, "roms/original.z64"), "rb").read())
    )
    print(f"original.z64 has {len(rom_file_entries)} files")

    for file_id in FILES_TO_EXTRACT:
        print(f"Extracting file {file_id:04X} from original.z64")
        with open(f"scripts/{file_id:04X}.bin", "wb") as f:
            f.write(rom_file_entries[int(file_id)].extract("data"))
