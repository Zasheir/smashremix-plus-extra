Ryu/
- animations/...bin
- moveset/...bin
- config.yaml
- main.bin
- character.bin
- main_reqlist.txt -> For all lines that reference the original MAIN file, replace with ${CHARACTER}
- character_reqlist.txt
- main.asm

# CONFIG.YAML
# Example:

# File offsets for main and character
offsets:
  main: ["0398", "0000"]
  character: ["0004", "AB7C"]
# Character definitions
definitions:
  base_character: LINK

# ANIMATIONS
Animations will be imported as CHARACTER_ANIM_FILENAME. Example: Ryu/animations/idle.bin -> File.RYU_ANIM_IDLE

# ASM
main.asm will be compiled into

scope Ryu {
    insert filename "moveset/filename.bin"
    ...for all files in moveset

    // MAIN.ASM FILE CONTENT
}

This means that you'll have to adapt your main file where:
- Animation files are named File.CHARNAME_ANIM_FILENAME (like in the File.RYU_ANIM_IDLE example)
- Moveset files are named "filename". So if you have "Jab1.bin", reference it as Jab1.