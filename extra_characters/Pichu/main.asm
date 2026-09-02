// Pichu.asm

// This file contains file inclusions, action edits, and assembly for Pichu.

include "./SelfDmg.asm"

scope Pichu {
    insert FSMASHC,"moveset/FsmashConcurrent.bin"
    FSMASH:; Moveset.CONCURRENT_STREAM(FSMASHC); insert "moveset/Fsmash.bin"

    insert SPARKLE_,"moveset/SPARKLE.bin"; Moveset.GO_TO(SPARKLE)
    insert SHIELD_BREAK_, "moveset/SHIELDBREAK.bin"; Moveset.GO_TO(SPARKLE)
    insert STUN_, "moveset/STUN.bin"; Moveset.GO_TO(STUN)
    insert SLEEP_, "moveset/SLEEP.bin"; Moveset.GO_TO(SLEEP)

    BTHROWW:; Moveset.THROW_DATA(BTHROWDATA); insert "moveset/THROWB.bin"
    FTHROW:; Moveset.THROW_DATA(FTHROWDATA); Moveset.GO_TO(THROWF)

    // Modify Action Parameters             // Action                       // Animation                 // Moveset Data   // Flags
    Character.edit_action_parameters(PICHU, Action.Idle,                    File.PICHU_ANIM_IDLE,        -1,               -1)
    Character.edit_action_parameters(PICHU, Action.Taunt,                   File.PICHU_ANIM_TAUNT,       taunt,            -1)
    Character.edit_action_parameters(PICHU, Action.DashAttack,              -1,                          DashAtck,         -1)
    Character.edit_action_parameters(PICHU, Action.DashAttack,              -1,                          DashAtck,         -1)
    Character.edit_action_parameters(PICHU, Action.RollF,                   -1,                          RollF,            -1)
    Character.edit_action_parameters(PICHU, Action.RollB,                   -1,                          RollB,            -1)
    Character.edit_action_parameters(PICHU, Action.AttackAirF,              File.PICHU_ANIM_FAIR,        Fair,             -1)
    Character.edit_action_parameters(PICHU, Action.AttackAirD,              -1,                          Dair,             -1)
    Character.edit_action_parameters(PICHU, Action.AttackAirN,              File.PICHU_ANIM_NAIR,        Nair,             -1)
    Character.edit_action_parameters(PICHU, Action.AttackAirB,              File.PICHU_ANIM_BAIR,        Bair,             -1)
    Character.edit_action_parameters(PICHU, Action.AttackAirU,              -1,                          -1,               -1)
    Character.edit_action_parameters(PICHU, Action.ShieldBreak,             -1,                          SHIELDBREAK,      -1)
    Character.edit_action_parameters(PICHU, Action.Stun,                    -1,                          STUN,             -1)
    Character.edit_action_parameters(PICHU, Action.Sleep,                   -1,                          SLEEP,            -1)
    Character.edit_action_parameters(PICHU, Action.Tech,                    -1,                          TECH,             -1)
    Character.edit_action_parameters(PICHU, Action.TechF,                   -1,                          TECHF,            -1)
    Character.edit_action_parameters(PICHU, Action.TechB,                   -1,                          TECHF,            -1)
    Character.edit_action_parameters(PICHU, Action.Teeter,                  -1,                          TEETER,           -1)
    Character.edit_action_parameters(PICHU, Action.ThrowB,                  -1,                          BTHROWW,          -1)
    Character.edit_action_parameters(PICHU, Action.ThrowF,                  -1,                          FTHROW,           -1)
    Character.edit_action_parameters(PICHU, Action.PIKACHU.ThunderStart,    File.PICHU_ANIM_DOWNBSTART,  DOWNBSTART,       -1)
    Character.edit_action_parameters(PICHU, Action.PIKACHU.ThunderStartAir, -1,                          DOWNBSTART,       -1)
    Character.edit_action_parameters(PICHU, Action.PIKACHU.Thunder,         File.PICHU_ANIM_DOWNBMAIN,   -1,               -1)
    Character.edit_action_parameters(PICHU, Action.PIKACHU.ThunderAir,      File.PICHU_ANIM_DOWNBMAIN,   -1,               -1)
    Character.edit_action_parameters(PICHU, Action.PIKACHU.ThunderHit,      File.PICHU_ANIM_DOWNBMAIN,   -1,               -1)
    Character.edit_action_parameters(PICHU, Action.PIKACHU.ThunderHitAir,   File.PICHU_ANIM_DOWNBMAIN,   -1,               -1)
    Character.edit_action_parameters(PICHU, Action.PIKACHU.ThunderEnd,      File.PICHU_ANIM_DOWNBEND,    -1,               -1)
    Character.edit_action_parameters(PICHU, Action.PIKACHU.ThunderEndAir,   File.PICHU_ANIM_DOWNBEND,    -1,               -1)
    Character.edit_action_parameters(PICHU, Action.PIKACHU.QuickAttack,     -1,                          UPBSTARTG,        -1)
    Character.edit_action_parameters(PICHU, Action.PIKACHU.QuickAttackAir,  -1,                          UPBSTARTG,        -1)

    // Modify Menu Action Parameters              // Action  // Animation             // Moveset Data  // Flags
    Character.edit_menu_action_parameters(PICHU,  0x0,       File.PICHU_ANIM_IDLE,    -1,              -1)          // CSS IDLE
    Character.edit_menu_action_parameters(PICHU,  0x1,       File.PICHU_ANIM_SELECT,  -1,              -1)          // VICTORY 1 AND SELECT
    Character.edit_menu_action_parameters(PICHU,  0x2,       File.PICHU_ANIM_SELECT,  results,         0x80000000)  // VICTORY 2
    Character.edit_menu_action_parameters(PICHU,  0x3,       File.PICHU_ANIM_SELECT,  results,         0x80000000)  // VICTORY 2
    Character.edit_menu_action_parameters(PICHU,  0x4,       File.PICHU_ANIM_SELECT,  results,         0x80000000)  // VICTORY 2
    Character.edit_menu_action_parameters(PICHU,  0x5,       File.PICHU_ANIM_CLAP,    -1,              -1)          // CLAP

    // Add Action Parameters                // Action Name  // Base Action  // Animation                // Moveset Data  // Flags
    Character.add_new_action_params(PICHU,  RclBair,        -1,             File.PICHU_ANIM_BAIR,       Bair,            -1)
    Character.add_new_action_params(PICHU,  RclFair,        -1,             0x07EB,                     Fair,            0x80000000)
    Character.add_new_action_params(PICHU,  RclDair,        -1,             0x07EE,                     Dair,            0x80000000)
    Character.add_new_action_params(PICHU,  RclNBA,         -1,             0x0827,                     NEUTRALBAIR,     0x00000000)
    Character.add_new_action_params(PICHU,  RclNBG,         -1,             0x0826,                     NEUTRALB,        0x00000000)
    Character.add_new_action_params(PICHU,  RclBTh,         Action.ThrowB,  0x07CC,                     BTHROWW,         0x10000000)
    Character.add_new_action_params(PICHU,  RclUBEA,        0x0ED,          0x0828,                     UBEG,            0x80000000)
    Character.add_new_action_params(PICHU,  RclUBEG,        0x0EA,          0x0828,                     UBEGG,           0x80000000)
    Character.add_new_action_params(PICHU,  RclDBHITG,      0x0E2,          File.PICHU_ANIM_DOWNBMAIN,  DOWNBHITG,       0x00000000)
    Character.add_new_action_params(PICHU,  RclDBHITA,      0x0E6,          File.PICHU_ANIM_DOWNBMAIN,  DOWNBHITG,      0x00000000)
    Character.add_new_action_params(PICHU,  RclFS,          -1,             0x07E7,                     FSMASH,          0x00000000)

    Character.add_new_action_params(PICHU,  DBAIREND,       0x0E7,             File.PICHU_ANIM_DOWNBEND,   Thunder_End,     0x00000000)

    // Add Actions                   // Action Name  // Base Action      // Parameters            // Staling ID   // Main ASM   // Interrupt/Other ASM              // Movement/Physics ASM  // Collision ASM  
    Character.add_new_action(PICHU,  RclBair,        Action.AttackAirB,  ActionParams.RclBair,    0xB,            0x800D94E8,   theselfdamagetest.selfdmg_,         0x800D90E0,              0x80150A08) // Back Air
    Character.add_new_action(PICHU,  RclFair,        Action.AttackAirF,  ActionParams.RclFair,    0xA,            0x800D94E8,   theselfdamagetest.selfdmg_,         0x800D90E0,              0x80150A08) // Forward Air 
    Character.add_new_action(PICHU,  RclDair,        Action.AttackAirD,  ActionParams.RclDair,    0x10,           0x80150980,   theselfdamagetest.selfdmg_,         0x800D90E0,              0x80150A08) // Down Air 
    Character.add_new_action(PICHU,  RclNBA,         0x0DF,              ActionParams.RclNBA,     0x12,           0x800D94E8,   theselfdamagetest.selfdmg_,         0x800D91EC,              0x80151C38) // Neutral B Air  
    Character.add_new_action(PICHU,  RclNBG,         0x0DE,              ActionParams.RclNBG,     0x12,           0x800D94C4,   theselfdamagetest.selfdmg_,         0x800D8BB4,              0x80151C14) // Neutral B Ground
    Character.add_new_action(PICHU,  RclBTh,         Action.ThrowB,      ActionParams.RclBTh,     0x24,           0x8014A0C0,   theselfdamagetest.BThselfdmg_,      0x800D8CCC,              0x80149B78) // BThrow  
    Character.add_new_action(PICHU,  RclUBEG,        0x0EA,              ActionParams.RclUBEG,    0x1E,           0x801532B8,   theselfdamagetest.selfdmg_,         0x801533E4,              0x801534BC) // Up Special End
    Character.add_new_action(PICHU,  RclUBEA,        0x0ED,              ActionParams.RclUBEA,    0x1E,           0x80153340,   theselfdamagetest.selfdmg_,         0x80153414,              0x801534E0) // Up Special End Air
    Character.add_new_action(PICHU,  RclDBHITG,      0x0E2,              ActionParams.RclDBHITG,  0x11,           0x801523F4,   theselfdamagetest.Thunderselfdmg_,  0x800D8BB4,              0x801524A4) // Thunder Hit Ground
    Character.add_new_action(PICHU,  RclDBHITA,      0x0E6,              ActionParams.RclDBHITA,  0x11,           0x80152424,   theselfdamagetest.Thunderselfdmg_,  0x80152454,              0x801524C8) // Thunder Hit Air
    Character.add_new_action(PICHU,  RclFS,          0x0CC,              ActionParams.RclFS,      0x9,            0x8014FE40,   theselfdamagetest.FSselfdmg_,       0x800D8CCC,              0x800DDF44) // FSmash

    Character.add_new_action(PICHU,  DBAIREND,       0x0E7,              ActionParams.DBAIREND,   0x11,            0x80152620,   -1,                                 0x80152454,              0x801524C8) // Thunder Air End


    // Action replacement map
    scope action_replace_map_: {
        // Action to replace | New action
        dh Action.AttackAirB; dh Pichu.Action.RclBair;
        dh Action.AttackAirF; dh Pichu.Action.RclFair;
        dh Action.AttackAirD; dh Pichu.Action.RclDair;
        dh 0x0DF; dh Pichu.Action.RclNBA; // Neutral B Air
        dh 0x0DE; dh Pichu.Action.RclNBG; // Neutral B Ground
        dh Action.ThrowB; dh Pichu.Action.RclBTh; // BThrow
        dh 0x0ED; dh Pichu.Action.RclUBEA; // UBE
        dh 0x0EA; dh Pichu.Action.RclUBEG; // UBE
        dh 0x0E2; dh Pichu.Action.RclDBHITG; // DBHITG
        dh 0x0E6; dh Pichu.Action.RclDBHITA; // DBHITA

        dh 0x0E6; dh Pichu.Action.DBAIREND; // DBENDAIR

        dh 0x0CA; dh Pichu.Action.RclFS;
        dh 0x0CB; dh Pichu.Action.RclFS;
        dh 0x0CC; dh Pichu.Action.RclFS;
        dh 0x0CD; dh Pichu.Action.RclFS;
        dh 0x0CE; dh Pichu.Action.RclFS;
        
        dw 0xFFFFFFFF // end of map
    }

    // Set action replacement table
    Character.table_patch_start(action_replace_map, Character.id.PICHU, 0x4)
    dw action_replace_map_
    OS.patch_end()

    // Set crowd chant FGM.
    Character.table_patch_start(crowd_chant_fgm, Character.id.PICHU, 0x2)
    dh  FGM.CROWD
    OS.patch_end()

    // Set menu zoom size.
    Character.table_patch_start(menu_zoom, Character.id.PICHU, 0x4)
    float32 0.7
    OS.patch_end()

    // Set Magnifying Glass Scale Override
    Character.table_patch_start(magnifying_glass_zoom, Character.id.PICHU, 0x4)
    float32 0.65
    OS.patch_end()

    // Set Remix 1P ending music
    Character.table_patch_start(remix_1p_end_bgm, Character.id.PICHU, 0x2)
    dh {MIDI.id.SS_AQUA}
    OS.patch_end()

    // Set action strings
    Character.table_patch_start(action_string, Character.id.PICHU, 0x4)
    dw Action.PIKACHU.action_string_table // Since Pichu has the same specials as Pikachu, this was used for the words to display in Training Mode.
    OS.patch_end()

}