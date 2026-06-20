include "./CloudSpecial.asm"

// This file contains file inclusions, action edits, and assembly for Cloud.

scope Cloud {

    insert SPARKLE_, "moveset/SPARKLE.bin"; Moveset.GO_TO(SPARKLE_)
    insert SHIELDBREAK_, "moveset/SHIELD_BREAK.bin"; Moveset.GO_TO(SPARKLE_)
    insert STUN_, "moveset/STUN.bin"; Moveset.GO_TO(STUN_)
    insert SLEEP_, "moveset/SLEEP.bin"; Moveset.GO_TO(SLEEP_)

    CUSTOM_THROWB:; Moveset.THROW_DATA(THROWB_DATA); Moveset.GO_TO(THROWB)
    CUSTOM_THROWF:; Moveset.THROW_DATA(THROWF_DATA); Moveset.GO_TO(THROWF)
	
	insert RUN_,"moveset/RUN.bin"; Moveset.GO_TO(RUN_) // loops

    // Modify Action Parameters             // Action                 // Animation                      // Moveset Data // Flags
    Character.edit_action_parameters(CLOUD, Action.Entry,             File.CLOUD_ANIM_IDLE,             -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.ReviveWait,        File.CLOUD_ANIM_IDLE,             -1,             -1)
    Character.edit_action_parameters(CLOUD, 0x006,                    File.CLOUD_ANIM_IDLE,             -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.Idle,              File.CLOUD_ANIM_IDLE,             -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.Walk1,             File.CLOUD_ANIM_WALK1,            -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.Walk2,             File.CLOUD_ANIM_WALK2,            -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.Walk3,             File.CLOUD_ANIM_WALK3,            -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.Turn,              File.CLOUD_ANIM_TURN,             -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.Dash,              File.CLOUD_ANIM_DASH,             -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.Run,               File.CLOUD_ANIM_RUN,              RUN_,           -1)
    Character.edit_action_parameters(CLOUD, Action.RunBrake,          File.CLOUD_ANIM_RUNBRAKE,         -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.TurnRun,           File.CLOUD_ANIM_RUNTURN,          -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.Taunt,             File.CLOUD_ANIM_TAUNT,            TAUNT,          -1)
    Character.edit_action_parameters(CLOUD, Action.Crouch,            File.CLOUD_ANIM_CROUCHSTART,      -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.CrouchIdle,        File.CLOUD_ANIM_CROUCHWAIT,       -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.CrouchEnd,         File.CLOUD_ANIM_CROUCHEND,        -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.Fall,              File.CLOUD_ANIM_FALL,             -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.FallAerial,        File.CLOUD_ANIM_FALLAERIAL,       -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.FallSpecial,       File.CLOUD_ANIM_FALLSPECIAL,      -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.JumpF,             File.CLOUD_ANIM_JUMPF,            JUMP1,          0x00000000)
    Character.edit_action_parameters(CLOUD, Action.JumpAerialF,       File.CLOUD_ANIM_JUMPAERIALF,      JUMP2,          0x00000000)
    Character.edit_action_parameters(CLOUD, Action.JumpB,             File.CLOUD_ANIM_JUMPB,            JUMP1,          -1)
    Character.edit_action_parameters(CLOUD, Action.JumpAerialB,       File.CLOUD_ANIM_JUMPAERIALB,      JUMP2,          0x00000000)
    Character.edit_action_parameters(CLOUD, Action.JumpSquat,         File.CLOUD_ANIM_JUMPSQUAT,        -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.ShieldJumpSquat,   File.CLOUD_ANIM_JUMPSQUAT,        -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.LandingLight,      File.CLOUD_ANIM_LANDINGLIGHT,     -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.LandingHeavy,      File.CLOUD_ANIM_LANDINGLIGHT,     -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.LandingAirX,       File.CLOUD_ANIM_LANDINGAIRN,      -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.LandingAirF,       File.CLOUD_ANIM_LANDINGAIRF,      -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.LandingAirB,       File.CLOUD_ANIM_LANDINGAIRB,      -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.LandingAirU,       File.CLOUD_ANIM_LANDINGAIRU,      -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.LandingAirD,       File.CLOUD_ANIM_LANDINGAIRD,      LANDAIR,        -1)
    Character.edit_action_parameters(CLOUD, Action.Grab,              File.CLOUD_ANIM_GRAB,             GRAB,           -1)
    Character.edit_action_parameters(CLOUD, Action.GrabPull,          File.CLOUD_ANIM_GRABPULL,         GRABPULL,       -1)
    Character.edit_action_parameters(CLOUD, Action.ThrowF,            File.CLOUD_ANIM_THROWF,           CUSTOM_THROWF,  -1)
    Character.edit_action_parameters(CLOUD, Action.ThrowB,            File.CLOUD_ANIM_THROWB,           CUSTOM_THROWB,  -1)
    Character.edit_action_parameters(CLOUD, Action.ClangRecoil,       File.CLOUD_ANIM_CLANGREBOUND,     -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.TechF,             -1,                               TECHFROLL,      -1)
    Character.edit_action_parameters(CLOUD, Action.TechB,             -1,                               TECHFROLL,      -1)
    Character.edit_action_parameters(CLOUD, Action.Tech,              -1,                               TECHSTAND,      -1)
    Character.edit_action_parameters(CLOUD, Action.CliffAttackQuick2, -1,                               CLIFFATKQUICK,  -1)
    Character.edit_action_parameters(CLOUD, Action.CliffAttackSlow2,  -1,                               CLIFFATKSLOW,   -1)
    Character.edit_action_parameters(CLOUD, Action.Teeter,            -1,                               TEETER,         -1)
    Character.edit_action_parameters(CLOUD, Action.Jab1,              File.CLOUD_ANIM_JAB1,             JAB1,           0x00000000)
    Character.edit_action_parameters(CLOUD, Action.Jab2,              File.CLOUD_ANIM_JAB2,             JAB2,           0x40000000)
    Character.edit_action_parameters(CLOUD, 0xDC,                     File.CLOUD_ANIM_JAB3,             JAB3,           0x40000000)
    Character.edit_action_parameters(CLOUD, Action.AttackAirN,        File.CLOUD_ANIM_AIRN,             AIRN,           -1)
    Character.edit_action_parameters(CLOUD, Action.AttackAirU,        File.CLOUD_ANIM_AIRU,             AIRU,           -1)
    Character.edit_action_parameters(CLOUD, Action.AttackAirD,        File.CLOUD_ANIM_AIRD,             AIRD,           -1)
    Character.edit_action_parameters(CLOUD, Action.AttackAirF,        File.CLOUD_ANIM_AIRF,             AIRF,           -1)
    Character.edit_action_parameters(CLOUD, Action.AttackAirB,        File.CLOUD_ANIM_AIRB,             AIRB,           -1)
    Character.edit_action_parameters(CLOUD, Action.FTilt,             File.CLOUD_ANIM_TILTF,            TILTF,          0x40000000)
    Character.edit_action_parameters(CLOUD, Action.UTilt,             File.CLOUD_ANIM_TILTU,            TILTU,          -1)
    Character.edit_action_parameters(CLOUD, Action.DTilt,             File.CLOUD_ANIM_TILTD,            TILTD,          0x40000000)
    Character.edit_action_parameters(CLOUD, Action.DashAttack,        File.CLOUD_ANIM_DASHATTACK,       DASHATTACK,     0x40000000)
    Character.edit_action_parameters(CLOUD, Action.USmash,            File.CLOUD_ANIM_USMASH,           SMASHU,         0x00000000)
    Character.edit_action_parameters(CLOUD, Action.FSmash,            File.CLOUD_ANIM_FSMASH,           SMASHF,         0x40000000)
    Character.edit_action_parameters(CLOUD, Action.DSmash,            File.CLOUD_ANIM_DSMASH,           SMASHD,         0x80000000)
    Character.edit_action_parameters(CLOUD, 0xE2,                     File.CLOUD_ANIM_SPECIALHI,        -1,             0x40000000)
    Character.edit_action_parameters(CLOUD, 0xE4,                     File.CLOUD_ANIM_SPECIALHI,        -1,             0x40000000)
    Character.edit_action_parameters(CLOUD, 0xE4,                     File.CLOUD_ANIM_SPECIALHI,        -1,             0x40000000)
    Character.edit_action_parameters(CLOUD, 0xE5,                     File.CLOUD_ANIM_SPECIALN,         NSP,            -1)
    Character.edit_action_parameters(CLOUD, 0xE8,                     File.CLOUD_ANIM_SPECIALN,         NSP,            -1)
    Character.edit_action_parameters(CLOUD, 0x0EB,                    File.CLOUD_ANIM_SPECIALLW1,       SPECIALLW1,     0x40000000)
    Character.edit_action_parameters(CLOUD, 0x0EC,                    File.CLOUD_ANIM_SPECIALLW1,       SPECIALLW1,     0x40000000)
    Character.edit_action_parameters(CLOUD, Action.Pass,              File.CLOUD_ANIM_PASSPLATFORMDROP, -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.ShieldDrop,        File.CLOUD_ANIM_PASSPLATFORMDROP, -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageMid1,        File.CLOUD_ANIM_DAMAGEN1,         -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageMid2,        File.CLOUD_ANIM_DAMAGEN2,         -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageMid3,        File.CLOUD_ANIM_DAMAGEN3,         -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageHigh1,       File.CLOUD_ANIM_DAMAGEHI1,        -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageHigh2,       File.CLOUD_ANIM_DAMAGEHI2,        -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageHigh3,       File.CLOUD_ANIM_DAMAGEHI3,        -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageLow1,        File.CLOUD_ANIM_DAMAGELW1,        -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageLow2,        File.CLOUD_ANIM_DAMAGELW2,        -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageLow3,        File.CLOUD_ANIM_DAMAGELW3,        -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageAir1,        File.CLOUD_ANIM_DAMAGEAIR1,       -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageAir2,        File.CLOUD_ANIM_DAMAGEAIR2,       -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageAir3,        File.CLOUD_ANIM_DAMAGEAIR3,       -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageFlyHigh,     File.CLOUD_ANIM_DAMAGEFLYHI,      -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageFlyLow,      File.CLOUD_ANIM_DAMAGEFLYLW,      -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageFlyMid,      File.CLOUD_ANIM_DAMAGEFLYN,       -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.WallBounce,        File.CLOUD_ANIM_DAMAGEFALL,       -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.Tumble,            File.CLOUD_ANIM_DAMAGEFALL,       -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageFlyRoll,     File.CLOUD_ANIM_DAMAGEFLYROLL,    -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.DamageFlyTop,      File.CLOUD_ANIM_DAMAGEFLYTOP,     -1,             -1)
    Character.edit_action_parameters(CLOUD, Action.ShieldBreak,       -1,                               SHIELDBREAK_,   -1)
    Character.edit_action_parameters(CLOUD, Action.Stun,              -1,                               STUN_,          -1)
    Character.edit_action_parameters(CLOUD, Action.Sleep,             -1,                               SLEEP_,         -1)

    Character.edit_action_parameters(CLOUD, Action.DownAttackD, File.CLOUD_ANIM_DOWNATTACKD, -1, -1)
    Character.edit_action_parameters(CLOUD, Action.DownAttackU, File.CLOUD_ANIM_DOWNATTACKU, -1, -1)
    Character.edit_action_parameters(CLOUD, Action.DownStandD, File.CLOUD_ANIM_DOWNSTANDD, -1, -1);
    Character.edit_action_parameters(CLOUD, Action.DownStandU, File.CLOUD_ANIM_DOWNSTANDU, -1, -1);
    // Character.edit_action_parameters(CLOUD, Action.Tech, File.CLOUD_ANIM_TECH, -1, -1);
    // Character.edit_action_parameters(CLOUD, Action.TechF, File.CLOUD_ANIM_TECHF, -1, -1)
    // Character.edit_action_parameters(CLOUD, Action.TechB, File.CLOUD_ANIM_TECHB, -1, -1)
    Character.edit_action_parameters(CLOUD, Action.DownForwardD, File.CLOUD_ANIM_DOWNFORWARDD, -1, -1)
    Character.edit_action_parameters(CLOUD, Action.DownForwardU, File.CLOUD_ANIM_DOWNFORWARDU, -1, -1)
    Character.edit_action_parameters(CLOUD, Action.DownBackD, File.CLOUD_ANIM_DOWNBACKD, -1, -1)
    Character.edit_action_parameters(CLOUD, Action.DownBackU, File.CLOUD_ANIM_DOWNBACKU, -1, -1)

    // Modify Menu Action Parameters             // Action // Animation             // Moveset Data // Flags
    Character.edit_menu_action_parameters(CLOUD, 0x0,      File.CLOUD_ANIM_IDLE,    GRABPULL,       -1)
    Character.edit_menu_action_parameters(CLOUD, 0x1,      File.CLOUD_ANIM_VICTORY, VICTORY,        -1)
    Character.edit_menu_action_parameters(CLOUD, 0x2,      File.CLOUD_ANIM_VICTORY, VICTORY,        -1)
    Character.edit_menu_action_parameters(CLOUD, 0x3,      File.CLOUD_ANIM_VICTORY, VICTORY,        -1)
    Character.edit_menu_action_parameters(CLOUD, 0x4,      File.CLOUD_ANIM_VICTORY, CSS,            -1)
    Character.edit_menu_action_parameters(CLOUD, 0x5,      File.CLOUD_ANIM_IDLE,    GRABPULL,       -1)
    Character.edit_menu_action_parameters(CLOUD, 0x6,      File.CLOUD_ANIM_IDLE,    GRABPULL,       -1)
    Character.edit_menu_action_parameters(CLOUD, 0x7,      File.CLOUD_ANIM_IDLE,    GRABPULL,       -1)
    Character.edit_menu_action_parameters(CLOUD, 0x8,      File.CLOUD_ANIM_IDLE,    GRABPULL,       -1)
    Character.edit_menu_action_parameters(CLOUD, 0x9,      File.CLOUD_ANIM_IDLE,    GRABPULL,       -1)
    Character.edit_menu_action_parameters(CLOUD, 0xA,      File.CLOUD_ANIM_IDLE,    GRABPULL,       -1)
    Character.edit_menu_action_parameters(CLOUD, 0xB,      File.CLOUD_ANIM_IDLE,    GRABPULL,       -1)
    Character.edit_menu_action_parameters(CLOUD, 0xC,      File.CLOUD_ANIM_IDLE,    GRABPULL,       -1)
    Character.edit_menu_action_parameters(CLOUD, 0xD,      File.CLOUD_ANIM_1P_POSE, GRABPULL,       -1)

    // Modify Actions            // Action // Staling ID // Main ASM    // Interrupt/Other ASM      // Movement/Physics ASM // Collision ASM
    Character.edit_action(CLOUD, 0xE5,     -1,           CloudNSP.main, CloudNSP.change_direction_, CloudNSP.physics_,      -1)
    Character.edit_action(CLOUD, 0xE8,     -1,           CloudNSP.main, CloudNSP.change_direction_, CloudNSP.physics_,      CloudNSP.air_collision_)
    Character.edit_action(CLOUD, 0xEB,     -1,           CloudDSP.main, 0,                          0x800D8BB4,             0x800DDF44)
    Character.edit_action(CLOUD, 0xEC,     -1,           CloudDSP.main, 0,                          CloudDSP.physics,       CloudDSP.air_collision_)

    // add movement to jab3
    Character.edit_action(CLOUD, 0xDC,     -1,           -1,            0,                          0x800D8C14,             0x800DDF44)

    // Add Action Parameters               // Action Name  // Base Action // Animation                   // Moveset Data // Flags
    Character.add_new_action_params(CLOUD, JAB2_,          -1,            File.CLOUD_ANIM_JAB2,          JAB2,           0x40000000)
    Character.add_new_action_params(CLOUD, USP,            -1,            File.CLOUD_ANIM_SPECIALHI,     SPECIALHI,      0x40000000)
    Character.add_new_action_params(CLOUD, USP2,           -1,            File.CLOUD_ANIM_SPECIALHI2,    SPECIALHI2,     0x00000000)
    Character.add_new_action_params(CLOUD, USP_LAND,       -1,            File.CLOUD_ANIM_SPECIALHILAND, SPECIALHI_LAND, 0x00000000)
    Character.add_new_action_params(CLOUD, SPECIALLW2,     -1,            File.CLOUD_ANIM_SPECIALLW2,    SPECIALLW2,     0x40000000)
    Character.add_new_action_params(CLOUD, SPECIALLW2_AIR, -1,            File.CLOUD_ANIM_SPECIALLW2,    SPECIALLW2,     0x40000000)
    Character.add_new_action_params(CLOUD, SPECIALLW3,     -1,            File.CLOUD_ANIM_SPECIALLW3,    SPECIALLW3,     0x40000000)
    Character.add_new_action_params(CLOUD, SPECIALLW3_AIR, -1,            File.CLOUD_ANIM_SPECIALLW3,    SPECIALLW3,     0x40000000)

    // Add Actions                  // Action Name  // Base Action  //Parameters                 // Staling ID // Main ASM     // Interrupt/Other ASM      // Movement/Physics ASM // Collision ASM
    Character.add_new_action(CLOUD, JAB2_,          -1,             ActionParams.JAB2_,          -1,           0x8014E824,     0x8014E9B4,                 0x800D8C14,             0x800DDF44)
    Character.add_new_action(CLOUD, USP,            -1,             ActionParams.USP,            -1,           CloudUSP.main_, CloudUSP.change_direction_, CloudUSP.physics_,      CloudUSP.collision_)
    Character.add_new_action(CLOUD, USP2,           -1,             ActionParams.USP2,           -1,           0x00000000,     0,                          CloudUSP.physics2_,     CloudUSP.usp2_collision_)
    Character.add_new_action(CLOUD, USP_LAND,       -1,             ActionParams.USP_LAND,       -1,           0x800D94C4,     0,                          0x800D8BB4,             0x800DDF44)
    Character.add_new_action(CLOUD, SPECIALLW2,     -1,             ActionParams.SPECIALLW2,     -1,           CloudDSP.main,  0,                          0x800D8BB4,             0x800DDF44)
    Character.add_new_action(CLOUD, SPECIALLW2_AIR, -1,             ActionParams.SPECIALLW2_AIR, -1,           CloudDSP.main,  0,                          CloudDSP.physics,       CloudDSP.air_collision_)
    Character.add_new_action(CLOUD, SPECIALLW3,     -1,             ActionParams.SPECIALLW3,     -1,           CloudDSP.main,  0,                          0x800D8BB4,             0x800DDF44)
    Character.add_new_action(CLOUD, SPECIALLW3_AIR, -1,             ActionParams.SPECIALLW3_AIR, -1,           CloudDSP.main,  0,                          CloudDSP.physics,       CloudDSP.air_collision_)

    // Action replacement map
    scope action_replace_map_: {
        dh Action.Jab2; dh Cloud.Action.JAB2_;
        dw 0xFFFFFFFF // end of map
    }

    // Set action replacement table
    Character.table_patch_start(action_replace_map, Character.id.CLOUD, 0x4)
    dw action_replace_map_
    OS.patch_end()

    // Set default costumes
    Character.set_default_costumes(Character.id.CLOUD, 0, 1, 2, 3, 1, 2, 3)
    Teams.add_team_costume(YELLOW, CLOUD, 0x4)

    // Shield colors for costume matching
    Character.set_costume_shield_colors(CLOUD, MAGENTA, RED, BLUE, GREEN, YELLOW, PURPLE, BLACK, NA)

    // Disable rapid jab
    Character.table_patch_start(rapid_jab, Character.id.CLOUD, 0x4)
    dw      Character.rapid_jab.DISABLED        // disable rapid jab
    OS.patch_end()

    Character.table_patch_start(air_usp, Character.id.CLOUD, 0x4)
    dw      CloudUSP.air_initial_
    OS.patch_end()

    Character.table_patch_start(ground_usp, Character.id.CLOUD, 0x4)
    dw      CloudUSP.ground_initial_
    OS.patch_end()
	
    // Set crowd chant FGM.
    Character.table_patch_start(crowd_chant_fgm, Character.id.CLOUD, 0x2)
    dh FGM.CHANT
    OS.patch_end()	

    scope Action {
        constant Jab3(0x0DC)
        constant JabLoopStart(0x0DD)
        constant JabLoop(0x0DE)
        constant JabLoopEnd(0x0DF)
        constant Appear1(0x0E0)
        constant Appear2(0x0E1)
        constant UpSpecial(0x0E2)
        constant UpSpecialEnd(0x0E3)
        constant UpSpecialAir(0x0E4)
        constant Boomerang(0x0E5)
        constant BoomerangCatch(0x0E6)
        constant BoomerangMiss(0x0E7)
        constant BoomerangAir(0x0E8)
        constant BoomerangCatchAir(0x0E9)
        constant BoomerangMissAir(0x0EA)
        constant Bomb(0x0EB)
        constant BombAir(0x0EC)

        // strings!
        //string_0x0DC:; String.insert("Jab3")
        //string_0x0DD:; String.insert("JabLoopStart")
        //string_0x0DE:; String.insert("JabLoop")
        //string_0x0DF:; String.insert("JabLoopEnd")
        //string_0x0E0:; String.insert("Appear1")
        //string_0x0E1:; String.insert("Appear2")
        //string_0x0E2:; String.insert("UpSpecial")
        //string_0x0E3:; String.insert("UpSpecialEnd")
        //string_0x0E4:; String.insert("UpSpecialAir")
        string_0x0E5:; String.insert("BladeBeam")
        //string_0x0E6:; String.insert("BoomerangCatch")
        //string_0x0E7:; String.insert("BoomerangMiss")
        string_0x0E8:; String.insert("BladeBeamAir")
        //string_0x0E9:; String.insert("BoomerangCatchAir")
        //string_0x0EA:; String.insert("BoomerangMissAir")
        string_0x0EB:; String.insert("CrossSlash1")
        string_0x0EC:; String.insert("CrossSlash1Air")
        string_0x0ED:; String.insert("Jab2")
        string_0x0EE:; String.insert("Climhazzard1")
        string_0x0EF:; String.insert("Climhazzard2")
        string_0x0F0:; String.insert("ClimhazzardLand")
        string_0x0F1:; String.insert("CrossSlash2")
        string_0x0F2:; String.insert("CrossSlash2Air")
        string_0x0F3:; String.insert("CrossSlash3")
        string_0x0F4:; String.insert("CrossSlash3Air")

        action_string_table:
        dw Action.COMMON.string_jab3
        dw Action.COMMON.string_jabloopstart
        dw Action.COMMON.string_jabloop
        dw Action.COMMON.string_jabloopend
        dw Action.COMMON.string_appear1
        dw Action.COMMON.string_appear2
        dw Action.LINK.string_0x0E2
        dw Action.LINK.string_0x0E3
        dw 0
        dw string_0x0E5
        dw Action.LINK.string_0x0E6
        dw Action.LINK.string_0x0E7
        dw string_0x0E8
        dw Action.LINK.string_0x0E9
        dw Action.LINK.string_0x0EA
        dw string_0x0EB
        dw string_0x0EC
        dw string_0x0ED
        dw string_0x0EE
        dw string_0x0EF
        dw string_0x0F0
        dw string_0x0F1
        dw string_0x0F2
        dw string_0x0F3
        dw string_0x0F4
    }

    // Set action strings
    Character.table_patch_start(action_string, Character.id.CLOUD, 0x4)
    dw  Action.action_string_table
    OS.patch_end()

    CLOUD_USP_TWICE:
    AI.UNPRESS_Z()
    AI.UNPRESS_A()
    AI.UNPRESS_B()
    AI.STICK_X(0)
    AI.STICK_Y(0x28, 1)
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1); // 32f
    AI.STICK_Y(0, 0)
    AI.END()
    AI.add_cpu_input_routine(CLOUD_USP_TWICE)

    CLOUD_DSP_FULL:
    AI.UNPRESS_Z()
    AI.UNPRESS_A()
    AI.UNPRESS_B()
    AI.STICK_X(0)
    AI.STICK_Y(-0x28, 1)
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1);
    AI.PRESS_B(1); AI.UNPRESS_B(1); AI.PRESS_B(1); AI.UNPRESS_B(1); // 40f
    AI.STICK_Y(0, 0)
    AI.END()
    AI.add_cpu_input_routine(CLOUD_DSP_FULL)

    CPU_ATTACKS:
    // Edit cpu attack behaviours
    // edit_attack_behavior(table, attack, override, start_hb, end_hb, min_x, max_x, min_y, max_y)
    AI.add_attack_behaviour(JAB, 4, 138, 460, 255, 395)
    AI.add_attack_behaviour(GRAB, 6, -2, 305, 221, 371)
    AI.add_attack_behaviour(UTILT, 6, -334, 391, 235, 853)
    AI.add_attack_behaviour(DTILT, 6, 230, 1373, 106, 206)
    AI.add_custom_attack_behaviour(AI.ROUTINE.CLOUD_USP_TWICE, 7, 52, 684, 146, 600) // not doing full upper value because we don't wanna hit with at the top
    AI.add_attack_behaviour(FTILT, 8, 243, 661, 157, 355)
    AI.add_attack_behaviour(DSMASH, 8, -650, 476, 122, 260)
    AI.add_custom_attack_behaviour(AI.ROUTINE.CLOUD_DSP_FULL, 10, 217, 589, 230, 602)
    AI.add_attack_behaviour(USMASH, 14, -271, 556, 79, 918)
    AI.add_attack_behaviour(FSMASH, 19, 263, 763, 186, 386)
    AI.add_attack_behaviour(NSPG, 12, 600, 3000, 50, 500)
    AI.add_custom_attack_behaviour(AI.ROUTINE.DASH_ATTACK, 9, 418, 1002, 74, 566)

    AI.END_ATTACKS() // end of grounded attacks

    AI.add_attack_behaviour(NAIR, 5, -430, 401, 22, 722)
    AI.add_attack_behaviour(UAIR, 7, -212, 311, 197, 653)
    AI.add_custom_attack_behaviour(AI.ROUTINE.CLOUD_USP_TWICE, 7, 52, 684, 146, 600) // not doing full upper value because we don't wanna hit with at the top
    AI.add_custom_attack_behaviour(AI.ROUTINE.CLOUD_DSP_FULL, 10, 217, 589, 230, 602)
    AI.add_attack_behaviour(DAIR, 11, -90, 63, -203, 89)
    AI.add_attack_behaviour(UAIR, 7+4, -212, 311, 197, 653) // late hit
    AI.add_custom_attack_behaviour(AI.ROUTINE.BAIR, 11, -542, -160, 134, 601)
    AI.add_attack_behaviour(NSPA, 12, 600, 3000, 50, 500)
    AI.add_attack_behaviour(DAIR, 11+4, -90, 63, -203, 89) // late hit
    AI.add_custom_attack_behaviour(AI.ROUTINE.FAIR, 18, 270, 510, 10, 640)

    AI.END_ATTACKS() // end of aerial attacks
    OS.align(16)

    // Set CPU behaviour
    Character.table_patch_start(ai_behaviour, Character.id.CLOUD, 0x4)
    dw      CPU_ATTACKS
    OS.patch_end()
}