MyStage/
- config.yaml
- header.bin
- stage.bin
- background.bin
- header_reqlist.txt -> replace lines referencing the original STAGE / BACKGROUND
                         files with ${STAGE} / ${BACKGROUND}
- icon.bmp            -> optional, auto-generated from the name if missing
- series_logo.png     -> optional SSS series logo
- hazards.asm         -> optional, see below
- <name>.bin          -> optional imported bin files (see "files:")
- sounds/<name>.aifc  -> optional imported sound effects (see "sounds:")

# CONFIG.YAML

offsets:
  header:     ["0098", "0014"]
  stage:      ["52E4", "3FFFC"]
  background: ["269D0", "3FFFC"]

name: "My Stage"
series: MARIO                       # series logo constant, or the folder name
                                   # if series_logo.png is present
hazard_type: "HAZARDS"             # NONE | HAZARDS | MOVEMENT | BOTH
mushroom_kingdom_camera: true
magnifying_glass_color: "#88CCFF"  # html color or [R, G, B]

music:
  main: "..."
  occasional: "..."
  rare: -1
  rare2: -1

spawn_locations:
  default: { p1: [-2500, 0], p2: [2500, 0], p3: [1000, 0], p4: [-1000, 0] }
  neutral: { p1: [-2500, 0], p2: [2500, 0], p3: [1000, 0], p4: [-1000, 0] }

# HAZARDS.ASM

If a `hazards.asm` file is present, it is compiled into

    scope <FOLDER>_HAZARDS {
        scope FILES { ... }   // auto-generated, from files:  (see below)
        scope FGM   { ... }   // auto-generated, from sounds: (see below)
        // hazards.asm file content
    }

and `Hazards.<FOLDER>_HAZARDS.setup` is registered as the stage's setup
function (replacing the default clone function). It must define a
`scope setup:` that returns via `jr ra`. See extra_stages/BattleHarbor for
a minimal example.

# files:  (imported bin files, like a character's `files:`)

files:
  - [extra_model, "3FFFC", "0040"]   # [name, tableOffset, resourceOffset]
  - [extra_model2]                    # offsets default to "3FFFC" (empty lists)

Each `<name>.bin` in the stage folder is appended as a new game file. An
optional `<name>_reqlist.txt` beside it is honored (its size must match the
file's resource linked list, same rule as characters). Each import produces,
inside `scope FILES`:

    FILES.EXTRA_MODEL       ->  the new file id
    FILES.EXTRA_MODEL_ptr   ->  a word; setup fills it with the file's RAM addr
                                via resolve_stage_file(FILES.X, FILES.X_ptr)

Load it at runtime with `Render.load_file_` (a0 = file id, a1 = ram pointer
slot), the same way the RTTF bomb / KlapTrap hazards load their models.

You can also reference an imported file from `header_reqlist.txt` with the
token `${EXTRA_MODEL}` if it should load together with the stage.

# sounds:  (imported sound effects / FGM, like a character's `sounds:`)

sounds:
  custom_sfx: {}
  custom_sfx2: { sample_rate: 32000, fgm_type: VOICE, reverb: 0, length: -1 }

Each key maps to `sounds/<key>.aifc` in the stage folder. Defaults:
sample_rate 16000, fgm_type VOICE, reverb 0, length -1 (auto). Each produces,
inside `scope FGM`:

    FGM.CUSTOM_SFX   ->  the new FGM id

Play it with `li a0, FGM.CUSTOM_SFX` then `jal FGM.play_` (register-safe) - set
a0 BEFORE the jal, `li` is a two-instruction load and would split across the
delay slot. Stage sound ids continue the sequence after all character sounds.
