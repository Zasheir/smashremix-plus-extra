from PIL import Image, ImageDraw, ImageFont


def wrap_text(text, font, max_width, draw):
    """
    Splits the text into lines that fit within the specified width.
    If a word is too long, it breaks the word into multiple segments.
    """
    lines = []
    words = text.split(' ')

    # Buffer for the current line
    current_line = []

    for word in words:
        while word:
            # Check if the current line with the word fits
            test_line = ' '.join(current_line + [word])
            text_bbox = draw.textbbox((0, 0), test_line, font=font)
            text_width = text_bbox[2] - text_bbox[0]

            if text_width <= max_width:
                # If the whole word fits, add it to the current line
                current_line.append(word)
                break
            else:
                # If the word is too long, break it into segments
                # Try to find a suitable split point
                for i in range(len(word), 0, -1):
                    segment = word[:i]
                    segment_bbox = draw.textbbox((0, 0), segment, font=font)
                    segment_width = segment_bbox[2] - segment_bbox[0]

                    if segment_width <= max_width:
                        # Add the segment to the current line
                        current_line.append(segment)
                        # Reduce the word to the remaining part
                        word = word[i:]  # Remaining part of the word
                        break
                else:
                    # If we can't split it, just take one character
                    current_line.append(word[0])
                    word = word[1:]

        # If the current line exceeds the maximum width, finalize it and start a new one
        if draw.textlength(' '.join(current_line), font=font) > max_width:
            lines.append(' '.join(current_line[:-1]))  # Add the completed line
            # Start new line with the last word
            current_line = [current_line[-1]]

    # Add the last line if there's any remaining text
    if current_line:
        lines.append(' '.join(current_line))

    return lines


def create_stage_icon(stage_name, output_path):
    # Load the base image (background)
    base_image = Image.open("extra_resources/stage_icon_base.bmp")

    # Set the size (your background image should already be 40x30)
    width, height = base_image.size

    # Load the custom font
    # Adjust the size as needed
    font = ImageFont.truetype("extra_resources/stage_font.ttf", size=16)

    # Create a drawing object
    draw = ImageDraw.Draw(base_image)

    # Convert stage name to uppercase
    stage_name = stage_name.upper()

    # Wrap the text into multiple lines if needed
    lines = wrap_text(stage_name, font, width, draw)

    # Predefined line height and spacing
    line_height = 6
    line_spacing = 1
    total_text_height = len(lines) * (line_height +
                                      line_spacing) - line_spacing

    # Start drawing from a vertically centered position
    current_y = (height - total_text_height) // 2

    for line in lines:
        # Calculate text size and position to center each line horizontally
        text_bbox = draw.textbbox((0, 0), line, font=font, anchor="lt")
        text_width = text_bbox[2] - text_bbox[0]
        text_x = (width - text_width) // 2

        # Draw each line
        draw.text((text_x, current_y), line, font=font,
                  fill=(255, 255, 255), anchor="lt")

        # Move to the next line
        current_y += line_height + line_spacing

    # Save the resulting image
    base_image.save(output_path)
    print(f"Stage icon saved at: {output_path}")
