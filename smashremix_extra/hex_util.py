import re
import os
import struct


def find_last_instance_of_pattern(binary_data, pattern):
    last_position = -1
    for i in range(len(binary_data) - len(pattern) + 1):
        if binary_data[i:i + len(pattern)] == pattern:
            last_position = i
    return last_position


def find_last_hex_id(filename):
    hex_pattern = re.compile(r'\b0x[0-9A-Fa-f]+\b')
    last_id = None

    with open(filename, 'r') as file:
        for line in file:
            match = hex_pattern.findall(line)
            if match:
                last_id = match[-1]

    return last_id


def get_image_last_file_offset_int(main_file_path: str):
    # FFFFFFFF 00000000 00000000 00000001
    pattern = b'\xFF\xFF\xFF\xFF\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01'
    pos = -1

    with open(main_file_path, 'rb') as binary_file:
        binary_data = binary_file.read()
        last_position = find_last_instance_of_pattern(
            binary_data, pattern)
        pos = last_position - 40

    return pos


def float_to_ieee754_hex(value):
    # Convert the float to its IEEE 754 binary representation (4 bytes)
    binary_rep = struct.pack('>f', value)  # '>f' means big-endian float
    # Convert the binary representation to a hexadecimal string
    hex_rep = ''.join(f'{byte:02X}' for byte in binary_rep)
    return hex_rep
