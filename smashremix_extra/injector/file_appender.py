"""
File appender translating SSBFileInjector.exe logic to Python.
"""


def pad_to_alignment(data: bytes, alignment: int, pad_byte: int = 0x00) -> bytes:
    """
    Pad data to a specified alignment boundary.

    Args:
        data: The data to pad
        alignment: Target alignment (e.g., 16 for 0x10, 4096 for 0x1000)
        pad_byte: Byte value to use for padding (typically 0xFF for ROM, 0x00 for data)

    Returns:
        Padded data
    """
    remainder = len(data) % alignment
    if remainder == 0:
        return data

    padding_size = alignment - remainder
    return data + bytes([pad_byte] * padding_size)


def align_address(address: int, alignment: int) -> int:
    """
    Align an address up to the next boundary.
    """
    remainder = address % alignment
    if remainder == 0:
        return address
    return address + (alignment - remainder)


class FileTableEntry:
    """
    Represents a single file entry in the SSB64 file table.
    """

    def __init__(self):
        self.index = 0
        self.is_compressed = False
        self.data_offset = 0
        self.internal_resource_table_offset_words = 0
        self.compressed_size_words = 0
        self.internal_resource_data_words = 0
        self.decompressed_size_words = 0
        self.data_compressed = bytearray()
        self.req_file = []  # list of 16-bit file IDs


def calculate_file_table_size(entries: list[FileTableEntry], num_req_entries: int = 0) -> int:
    """
    Calculate the total size needed for the file table and file data.
    """
    num_entries = len(entries)

    # File table header: 12 bytes per entry + 12 bytes terminator
    file_table_size = (num_entries * 0xC) + 0xC

    current_address = file_table_size
    for entry in entries:
        # Each file data: compressed_size_words * 4 bytes
        current_address += len(entry.data_compressed)

        # Req file indices: 2 bytes each
        current_address += len(entry.req_file) * 2

    # Align to 0x10 boundary
    current_address = align_address(current_address, 0x10)

    return current_address


def pad_rom_file(rom_data: bytes) -> bytes:
    """
    Pad ROM to 4096-byte (0x1000) alignment.
    """
    return pad_to_alignment(rom_data, 0x1000, pad_byte=0xFF)
