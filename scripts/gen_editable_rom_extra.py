#!/usr/bin/env python3
"""
Injects an extra character over their base character, producing a ROM GE
can open directly to edit their model/animations.

Wraps gen_editable_rom.py, but fixes up file IDs using
filename_overrides_extra.txt - the vanilla-scoped IDs in src/File.asm only
match a build containing every extra character.

Known issue: GE adds/removes a character's Special Parts based on which
moveset commands reference them, so a part can come in on the wrong bone or
be missing. Fix by manually editing the movesets in GE: remove unused
"Set Model Form" commands and add correct ones for every part in use - the
model then updates correctly.

Usage:
    python3 scripts/gen_editable_rom_extra.py --character TERRY \\
        --rom /path/to/ssb64asm_extra.z64 --output terry_over_falcon.z64
"""
import argparse
import os
import re
import shutil
import sys
import tempfile

APPENDER_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SMASHREMIX_DIR = os.path.join(APPENDER_DIR, "smashremix")
SMASHREMIX_SCRIPTS_DIR = os.path.join(SMASHREMIX_DIR, "scripts")
# character_appender.py builds against the *content* repo that embeds
# appender/ as a submodule (extra_characters/, src/, main.asm, build/ all
# live there, cwd-relative) - not against paths inside appender/ itself.
CONTENT_ROOT = os.path.dirname(APPENDER_DIR)


def load_extra_overrides(overrides_path):
    """Map CONSTANT_NAME -> file ID, for one specific extra ROM build."""
    overrides = {}
    pattern = re.compile(r'^([0-9A-Fa-f]{4})\s+([A-Z0-9_]+)$')
    with open(overrides_path, "r", encoding="utf-8") as f:
        for line in f:
            match = pattern.match(line.strip())
            if match:
                file_id, name = match.groups()
                overrides[name] = int(file_id, 16)
    return overrides


def find_animation_definitions(character_name, roots):
    """Same regex-based scan as gen_editable_rom.get_character_animation_definitions,
    but over an arbitrary list of root directories. Extra characters (like Terry)
    declare their Character.edit_action_parameters(...) calls in their own
    extra_characters/<Name>/main.asm rather than in the shared src/Character.asm
    that gen_editable_rom.py only looks at, so its src/-only scan misses them."""
    animation_entries = []

    for root_dir in roots:
        if not os.path.isdir(root_dir):
            continue
        for root, _, files in os.walk(root_dir):
            for file in files:
                if not file.endswith('.asm'):
                    continue
                with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                    lines = [
                        line for line in f if not line.strip().startswith('//')]
                    content = ''.join(lines)

                    patterns = [
                        rf'Character\.(edit_action_parameters)\(\s*{character_name}\s*,\s*([^,]+),\s*File\.([^,]+).*?,.*?(0x[0-9A-Fa-f]+|\-1|\d+)\)',
                        rf'Character\.(edit_menu_action_parameters)\(\s*{character_name}\s*,\s*([^,]+),.*?File\.([^,]+).*?,\s*(0x[0-9A-Fa-f]+|\-1|\d+)\)'
                    ]

                    for pattern in patterns:
                        matches = re.finditer(pattern, content, re.MULTILINE)
                        for match in matches:
                            func, action_name, file_name, flags = match.groups()
                            if file_name != '-1':
                                animation_entries.append((
                                    file_name,
                                    action_name.split(".")[-1],
                                    int(flags, 16) if flags != '-1' else -1,
                                    func
                                ))

    return animation_entries


def main():
    parser = argparse.ArgumentParser(
        description="Generates a vanilla ROM with an extra character injected over their base character for editing.")
    parser.add_argument('--character', required=True,
                        help="Extra character name as defined in src/Character.asm, e.g. TERRY")
    parser.add_argument('--rom', required=True,
                        help="Path to the built extra ROM (e.g. ssb64asm_extra.z64) containing the character's data")
    parser.add_argument('--vanilla', default=os.path.join(SMASHREMIX_DIR, "roms", "ssb.rom"),
                        help="Path to the vanilla Smash 64 ROM file")
    parser.add_argument('--overrides', default=os.path.join(SMASHREMIX_DIR, "roms", "filename_overrides_extra.txt"),
                        help="filename_overrides_extra.txt matching --rom's build")
    parser.add_argument('--output', default='editable_rom.z64',
                        help='Output ROM file path')
    parser.add_argument('--export-animations', action='store_true',
                        help="Export the character's action animation files to an "
                        "animations/ folder next to the output ROM. Off by default; "
                        "these are extracted from --rom only and never injected into "
                        "the output ROM.")
    parser.add_argument('--animations-dir', default=None,
                        help='Where to export animations to when --export-animations is set '
                        '(default: an "animations" folder next to --output)')
    args = parser.parse_args()

    output_path = os.path.abspath(args.output)
    rom_path = os.path.abspath(args.rom)
    vanilla_path = os.path.abspath(args.vanilla)
    overrides_path = os.path.abspath(args.overrides)
    animations_dir = os.path.abspath(args.animations_dir) if args.animations_dir else os.path.join(
        os.path.dirname(output_path), "animations")

    workdir = tempfile.mkdtemp(prefix="gen_editable_rom_extra_")
    try:
        # gen_editable_rom.py hardcodes paths (src/, build/, roms/,
        # assembler/) relative to the process cwd, so we assemble a working
        # directory with the pieces it expects: extra-character source from
        # the appender repo, everything else from the smashremix checkout.
        os.symlink(os.path.join(CONTENT_ROOT, "src"),
                   os.path.join(workdir, "src"))
        os.symlink(os.path.join(SMASHREMIX_DIR, "build"),
                   os.path.join(workdir, "build"))
        os.symlink(os.path.join(SMASHREMIX_DIR, "assembler"),
                   os.path.join(workdir, "assembler"))
        os.symlink(os.path.join(SMASHREMIX_DIR, "roms"),
                   os.path.join(workdir, "roms"))

        sys.path.insert(0, SMASHREMIX_SCRIPTS_DIR)
        os.chdir(workdir)

        import gen_editable_rom as ger

        overrides = load_extra_overrides(overrides_path)
        character_prefix = f"{args.character}_"
        for name, file_id in overrides.items():
            if name.startswith(character_prefix):
                ger.FILES[name] = file_id

        class RunArgs:
            character = args.character
            rom = rom_path
            vanilla = vanilla_path
            output = os.path.basename(output_path)

        ergen = ger.EditableROMGenerator(RunArgs())

        # file_shield can be a literal hex ID baked into Character.asm
        # instead of a File.xxx name. If it points at this character's own
        # shield pose file, rewrite it as a File.xxx reference so
        # EditableROMGenerator injects it, instead of silently leaving the
        # parent's vanilla shield pose in place.
        shield_field = ergen.character['file_shield']
        if isinstance(shield_field, str) and not shield_field.startswith('File.'):
            own_shield_name = f"{args.character}_SHIELD_POSE"
            if own_shield_name in overrides:
                ergen.character['file_shield'] = f"File.{own_shield_name}"

        # gen_editable_rom.py finds a character's animation overrides by
        # regex-scanning src/*.asm for Character.edit_action_parameters(...)
        # calls. That works for standard Remix characters (defined in
        # src/Character.asm), but extra characters like Terry declare theirs
        # in their own extra_characters/<Name>/main.asm, which never lands
        # under src/. Point it at both locations so the reimport actually
        # finds them.
        ergen.get_character_animation_definitions = lambda: find_animation_definitions(
            ergen.character["name"],
            [os.path.join(workdir, "src"),
             os.path.join(CONTENT_ROOT, "extra_characters")]
        )

        try:
            ergen.create_rom()
        finally:
            ergen.cleanup()

        # create_rom() always dumps the (correctly discovered) animations to
        # an animations/ folder relative to cwd (workdir) as its last step.
        # Only carry it out to the caller if it was asked for; otherwise it
        # is discarded along with the rest of workdir below.
        generated_animations_dir = os.path.join(workdir, "animations")
        if args.export_animations and os.path.isdir(generated_animations_dir):
            os.makedirs(animations_dir, exist_ok=True)
            shutil.copytree(generated_animations_dir,
                            animations_dir, dirs_exist_ok=True)

        generated = os.path.join(workdir, os.path.basename(output_path))
        shutil.move(generated, output_path)
    finally:
        os.chdir(APPENDER_DIR)
        shutil.rmtree(workdir, ignore_errors=True)

    print(f"\nDone. Output ROM: {output_path}")


if __name__ == "__main__":
    main()
