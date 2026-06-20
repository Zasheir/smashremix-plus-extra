import os
import re
import shutil
import yaml

from smashremix_extra.constants import SMASHREMIX_PATH as smashremix_path
from smashremix_extra.image_appender import append_image, get_image_data, ImageMode
from smashremix_extra.gen_stage_icon import create_stage_icon
from smashremix_extra.file_manager import FileManager
from smashremix_extra import hex_util


class StageProcessor:
    """Processes extra stage folders and accumulates patch data."""

    def __init__(self):
        self.stage_headers_strings = []
        self.stages_mushroom_kingdom_camera_strings = []
        self.stage_spawn_location_strings = {"default": [], "neutral": []}
        self.stage_icon_offsets = []
        self.stage_configs = []
        self.stage_series_textures = {}

    def process(self, stage_folder: str) -> None:
        """Process one stage folder and accumulate patch data into self."""
        config = yaml.safe_load(open(
            f"extra_stages/{stage_folder}/config.yaml", encoding="utf-8"
        ))
        print(config)

        output_path = f"build/extra_stages/{stage_folder}/"
        original_path = f"./extra_stages/{stage_folder}/"

        # Copy all files from the stage folder to the output path
        shutil.copytree(
            original_path,
            output_path,
            dirs_exist_ok=True
        )

        header_file = FileManager.add_file(
            path=f"{output_path}/header.bin",
            name=f"{stage_folder}_header",
            internal_file_table_offset=config['offsets']['header'][0],
            internal_file_resource_offset=config['offsets']['header'][1],
            reqlist_path=f"{output_path}/header_reqlist.txt",
            compression_level=1
        )

        stage_file = FileManager.add_file(
            path=f"{output_path}/stage.bin",
            name=f"{stage_folder}_stage",
            internal_file_table_offset=config['offsets']['stage'][0],
            internal_file_resource_offset=config['offsets']['stage'][1],
            compression_level=2
        )

        bg_file = FileManager.add_file(
            path=f"{output_path}/background.bin",
            name=f"{stage_folder}_background",
            internal_file_table_offset=config['offsets']['background'][0],
            internal_file_resource_offset=config['offsets']['background'][1],
            compression_level=2
        )

        self.stage_headers_strings.append(
            f"constant STAGE_{stage_folder.upper().replace("/", "_")}(0x{header_file.id:X})"
        )

        stage_name = config.get(
            'name', stage_folder.upper().replace("/", " "))

        config["id"] = stage_folder.upper().replace("/", "_")

        if "/" in stage_folder:
            config["base_stage"] = "id.STAGE_" + \
                stage_folder.upper().split("/")[0]
            config["variant_type"] = "variant_type." + \
                stage_folder.split("/")[1].upper()

        self.stage_configs.append(config)

        # Stage icon
        # If stage icon image doesn't exist, generate one
        if not os.path.isfile(f"{output_path}/icon.bmp"):
            create_stage_icon(
                stage_name,
                f"{output_path}/icon.bmp"
            )

        # Append icon
        pixels, w, h = get_image_data(
            f"{output_path}/icon.bmp"
        )
        icon_texture = append_image(
            "scripts/153E.bin",
            "scripts/153E.bin",
            pixels,
            w, h,
            ImageMode.RGBA5551
        )
        icon_texture += 16
        icon_texture += 0x01000000  # Flag to use 2nd file
        icon_texture = f"0x{icon_texture:08X}"

        self.stage_icon_offsets.append(icon_texture)

        # Check for SSS series logo image
        if os.path.isfile(f"{output_path}/series_logo.png"):
            pixels, w, h = get_image_data(
                f"{output_path}/series_logo.png"
            )
            series_texture = append_image(
                "scripts/0014.bin",
                "scripts/0014.bin",
                pixels,
                w, h,
                ImageMode.I8
            )
            series_texture += 16

            # Get logo position from config
            series_x = hex_util.float_to_ieee754_hex(
                config.get("series_position", {}).get("x", 3))
            series_y = hex_util.float_to_ieee754_hex(
                config.get("series_position", {}).get("y", 19))

            self.stage_series_textures[f"{stage_folder}"] = {
                "offset": f"0x{series_texture:X}",
                "x": f"0x{series_x}",
                "y": f"0x{series_y}"
            }

        # Spawn locations
        for category in ["default", "neutral"]:
            spawn = config.get(
                'spawn_locations', {}).get(category, {})

            self.stage_spawn_location_strings[category].append("\n\t".join([
                f"// {stage_folder.upper().replace('/', '_')}",
                f"float32 {int(spawn.get('p1')[0]):+05}, {
                    int(spawn.get('p1')[1]):+05}",
                f"float32 {int(spawn.get('p2')[0]):+05}, {
                    int(spawn.get('p2')[1]):+05}",
                f"float32 {int(spawn.get('p3')[0]):+05}, {
                    int(spawn.get('p3')[1]):+05}",
                f"float32 {int(spawn.get('p4')[0]):+05}, {
                    int(spawn.get('p4')[1]):+05}"
            ]))

        # Toggle to use Mushroom Kingdom's camera
        # It scrolls more rather than trying to stay more centered
        # Good for big stages
        if config.get("mushroom_kingdom_camera"):
            self.stages_mushroom_kingdom_camera_strings.append(
                f"\t\taddiu   at, r0, Stages.id.STAGE_{
                    stage_folder.upper().replace('/', '_')}\n"
                f"\t\tbeq     at, v0, mkingdom_camera\n"
            )

        with open(f"{original_path}/header_reqlist.txt", 'r', encoding='utf-8') as reqlist:
            with open(f"{output_path}/header_reqlist.txt", 'w', encoding='utf-8') as compiled_reqlist:
                for line in reqlist.readlines():
                    line = line.replace(
                        "${STAGE}", f"{stage_file.id:04X} {stage_file.name}")

                    line = line.replace(
                        "${BACKGROUND}", f"{bg_file.id:04X} {bg_file.name}")

                    compiled_reqlist.write(line)

        # Read config and update attributes
        with open(f"{original_path}/header.bin", 'rb') as binary_file:
            data = bytearray(binary_file.read())

            # At 0x60 we have the magnifying glass color RRGGBB00
            if config.get("magnifying_glass_color"):
                color = config.get("magnifying_glass_color")
                # Accept either an array or a html color string
                if isinstance(color, str):
                    color = color.replace("#", "")
                    color_r = int(color[0:2], 16)
                    color_g = int(color[2:4], 16)
                    color_b = int(color[4:6], 16)
                    color = bytearray(
                        [color_r, color_g, color_b, 0x00]
                    )
                elif isinstance(color, list) and len(color) == 3:
                    color = bytearray(
                        [color[0], color[1], color[2], 0x00]
                    )

                data[0x60:0x64] = color

            with open(f"{output_path}/header.bin", 'wb') as binary_file:
                binary_file.write(data)


