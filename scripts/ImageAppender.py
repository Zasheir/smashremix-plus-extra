from PIL import Image


class ImageMode:
    RGBA5551 = 'RGBA5551'
    IA8 = 'IA8'
    I8 = 'I8'


def get_image_data(image_path, expected_width=-1, expected_height=-1):
    '''
        Loads image from image_path and
        returns it as a bytearray along with width and height
    '''
    image = Image.open(image_path).convert('RGBA')

    if expected_width != -1 and expected_height != -1:
        if image.width != expected_width or image.height != expected_height:
            image = image.resize((expected_width, expected_height))

    return list(image.getdata()), image.width, image.height


def rgba5551(_pixels):
    out = bytearray()
    for r, g, b, a in _pixels:
        red = (r & 0xF8) >> 3
        green = (g & 0xF8) >> 3
        blue = (b & 0xF8) >> 3
        alpha_bit = 1 if a > 0 else 0
        high = (red << 3) | ((green & 0x1C) >> 2)
        low = ((green & 0x03) << 6) | (blue << 1) | alpha_bit
        out += bytes([high, low])
    return out


def ia8(_pixels):
    out = bytearray()
    for r, g, b, a in _pixels:
        intensity = (r >> 4) << 4
        alpha = a >> 4
        out.append(intensity | alpha)
    return out


def i8(_pixels):
    out = bytearray()
    for r, g, b, _ in _pixels:
        intensity = (r + g + b) // 3
        out.append(intensity & 0xFF)
    return out


def interleave(array: bytearray, height: int):
    bytes_per_line = len(array) // height

    for line in range(1, height, 2):  # Start from line 1, every other line
        start = line * bytes_per_line
        end = start + bytes_per_line

        i = start
        while i + 7 < end:
            # Swap 4 bytes with the next 4
            array[i:i+8] = array[i+4:i+8] + array[i:i+4]
            i += 8


def build_header(width, height, data1, data2, pointer1, mode_bytes):
    header = bytearray()
    header.extend([
        0x00, width, 0x00, width,
        0x00, 0x00, 0x00, 0x00,
        (pointer1 >> 8) & 0xFF, pointer1 & 0xFF,
        (data1 >> 8) & 0xFF, data1 & 0xFF,
        0x00, height, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, width, 0x00, height,
        0x3F, 0x80, 0x00, 0x00,
        0x3F, 0x80, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x02, 0x20, 0x12, 0x34,
        0xFF, 0xFF, 0xFF, 0xFF,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x01,
        0x00, 0x01, 0x00, 0x24,
        0x00, height, 0x00, height,
    ])
    header += mode_bytes
    header += b'\x00\x00\xFF\xFF'
    header += bytes([(data2 >> 8) & 0xFF, data2 & 0xFF])
    header += b'\x00' * 16
    return header


def append_image(input_file, output_file, _pixels, width, height, mode) -> int:
    '''
        Appends _pixels data with width/height using mode to the input file
        and writes it to the output file
        Returns a pointer to the added image's data
    '''
    with open(input_file, "rb") as f:
        current_file = bytearray(f.read())

    if mode == ImageMode.RGBA5551:
        image_bytes = rgba5551(_pixels)
        mode_bytes = b'\x00\x02'
    elif mode == ImageMode.IA8:
        image_bytes = ia8(_pixels)
        mode_bytes = b'\x03\x01'
    elif mode == ImageMode.I8:
        image_bytes = i8(_pixels)
        mode_bytes = b'\x04\x01'
    else:
        raise ValueError("Invalid image mode")

    interleave(image_bytes, height)

    # Update pointer in previous file
    if current_file[-0x14] == 0xFF and current_file[-0x13] == 0xFF:
        current_file[-0x14] = (
            ((len(current_file) + len(image_bytes) + 0x10) // 4) >> 8) & 0xFF
        current_file[-0x13] = (
            ((len(current_file) + len(image_bytes) + 0x10) // 4)) & 0xFF
    else:
        current_file[-0xC] = (
            ((len(current_file) + len(image_bytes) + 0x10) // 4) >> 8) & 0xFF
        current_file[-0xB] = (
            ((len(current_file) + len(image_bytes) + 0x10) // 4) & 0xFF)

    out = bytearray(current_file)

    out += b'\xDF\x00\x00\x00' + b'\x00' * 4

    data1 = len(out) // 4

    # append image data
    out += image_bytes
    data2 = len(out) // 4

    pointer1 = (len(out) + 60) // 4 + 2

    header = build_header(width, height, data1, data2, pointer1, mode_bytes)
    out += header

    with open(output_file, "wb") as f:
        f.write(out)

    data_address = data2 * 4

    if data_address >= 0x3FFFC:
        raise ValueError("Image too large, exceeds addressable space.")

    return data_address


# CLI Support
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Append image to SSB64 .bin file.")
    parser.add_argument("input_bin", help="Input .bin file")
    parser.add_argument("image_file", help="Image file (e.g. PNG)")
    parser.add_argument("output_bin", help="Output .bin file")
    parser.add_argument(
        "--mode", choices=[ImageMode.RGBA5551, ImageMode.IA8, ImageMode.I8], required=True)
    args = parser.parse_args()

    _pixels, w, h = get_image_data(args.image_file)

    append_image(
        args.input_bin, args.output_bin, _pixels, w, h, args.mode
    )
