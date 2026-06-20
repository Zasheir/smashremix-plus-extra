include "./DualFighter.asm"

// This file contains file inclusions, action edits, and assembly for Ice Climbers.

scope IceClimbers {

    insert SPARKLE_, "moveset/SPARKLE.bin"; Moveset.GO_TO(SPARKLE_)
    insert SHIELDBREAK_, "moveset/SHIELD_BREAK.bin"; Moveset.GO_TO(SPARKLE_)
    insert STUN_, "moveset/STUN.bin"; Moveset.GO_TO(STUN_)
    insert SLEEP_, "moveset/SLEEP.bin"; Moveset.GO_TO(SLEEP_)
	
    CUSTOM_THROWB:; Moveset.THROW_DATA(throwBData); Moveset.GO_TO(throwB)
    CUSTOM_THROWF:; Moveset.THROW_DATA(throwFData); Moveset.GO_TO(throwF)
    // GRAB_:; Moveset.THROW_DATA(THROWF_DATA); Moveset.GO_TO(GRAB)
	
	insert RUN_,"moveset/RUN.bin"; Moveset.GO_TO(RUN_) // loops

    include "./IceClimbersSpecial.asm"

    // Modify Action Parameters                   // Action                 // Animation                          // Moveset Data // Flags
    Character.edit_action_parameters(ICECLIMBERS, Action.Idle,              File.ICECLIMBERS_ANIM_IDLE,           -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Revive1,           File.ICECLIMBERS_ANIM_DOWNBOUNCED,    -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.ReviveWait,        File.ICECLIMBERS_ANIM_IDLE,           -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Walk1,             File.ICECLIMBERS_ANIM_WALK1,          -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Walk2,             File.ICECLIMBERS_ANIM_WALK2,          -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Walk3,             File.ICECLIMBERS_ANIM_WALK3,          -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Dash,              File.ICECLIMBERS_ANIM_DASH,           -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Run,               File.ICECLIMBERS_ANIM_RUN,            RUN_,           -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.RunBrake,          File.ICECLIMBERS_ANIM_RUNBRAKE,       -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.TurnRun,           File.ICECLIMBERS_ANIM_TURNRUN,        -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Turn,              File.ICECLIMBERS_ANIM_TURN,           -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Tech,              -1,                                   Tech,           -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.TechF,             -1,                                   TechRoll,       -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.TechB,             -1,                                   TechRoll,       -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.CliffAttackQuick2, -1,                                   CliffATKQuick,  -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.CliffAttackSlow2,  -1,                                   CliffATKSlow,   -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Teeter,            -1,                                   Teeter,         -1)

    Character.edit_action_parameters(ICECLIMBERS, Action.JumpF,             File.ICECLIMBERS_ANIM_JUMPF,          jump,           -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.JumpB,             File.ICECLIMBERS_ANIM_JUMPB,          jump,           -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.JumpAerialF,       File.ICECLIMBERS_ANIM_JUMPAERIALBOTH, jumpAerial,     -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.JumpAerialB,       File.ICECLIMBERS_ANIM_JUMPAERIALBOTH, jumpAerial,     -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Fall,              File.ICECLIMBERS_ANIM_FALL,           -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.FallAerial,        File.ICECLIMBERS_ANIM_FALLAERIAL,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.FallSpecial,       File.ICECLIMBERS_ANIM_FALLSPECIAL,    -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.LandingSpecial,    File.ICECLIMBERS_ANIM_LANDINGAIRU,    -1,             0x0)


    Character.edit_action_parameters(ICECLIMBERS, Action.Taunt,             File.ICECLIMBERS_ANIM_TAUNT,          taunt,          -1)

    Character.edit_action_parameters(ICECLIMBERS, Action.DashAttack,        File.ICECLIMBERS_ANIM_DASHATTACK,     attackDash,     -1)

    Character.edit_action_parameters(ICECLIMBERS, Action.FTilt,             File.ICECLIMBERS_ANIM_TILTF,          tiltF,          0x0)
    Character.edit_action_parameters(ICECLIMBERS, Action.FTiltMidHigh,      0,                                    0x80000000,     0x00000000)
    Character.edit_action_parameters(ICECLIMBERS, Action.FTiltMidLow,       0,                                    0x80000000,     0x00000000)
    Character.edit_action_parameters(ICECLIMBERS, Action.FTiltHigh,         File.ICECLIMBERS_ANIM_TILTFHI,        tiltF,          0x0)
    Character.edit_action_parameters(ICECLIMBERS, Action.FTiltLow,          File.ICECLIMBERS_ANIM_TILTFLO,        tiltF,          0x0)
    Character.edit_action_parameters(ICECLIMBERS, Action.UTilt,             File.ICECLIMBERS_ANIM_TILTU,          tiltU,          0x0)
    Character.edit_action_parameters(ICECLIMBERS, Action.DTilt,             File.ICECLIMBERS_ANIM_TILTD,          tiltD,          0x0)

    Character.edit_action_parameters(ICECLIMBERS, Action.FSmashHigh,        0,                                    0x80000000,     0x00000000)
    Character.edit_action_parameters(ICECLIMBERS, Action.FSmashMidHigh,     0,                                    0x80000000,     0x00000000)
    Character.edit_action_parameters(ICECLIMBERS, Action.FSmash,            File.ICECLIMBERS_ANIM_SMASHF,         smashF,         0x0)
    Character.edit_action_parameters(ICECLIMBERS, Action.FSmashMidLow,      0,                                    0x80000000,     0x00000000)
    Character.edit_action_parameters(ICECLIMBERS, Action.FSmashLow,         0,                                    0x80000000,     0x00000000)
    Character.edit_action_parameters(ICECLIMBERS, Action.USmash,            File.ICECLIMBERS_ANIM_SMASHU,         smashU,         0x0)
    Character.edit_action_parameters(ICECLIMBERS, Action.DSmash,            File.ICECLIMBERS_ANIM_SMASHD,         smashD,         0x0)

    Character.edit_action_parameters(ICECLIMBERS, Action.AttackAirN,        File.ICECLIMBERS_ANIM_AIRN,           airN,           0x0)
    Character.edit_action_parameters(ICECLIMBERS, Action.AttackAirF,        File.ICECLIMBERS_ANIM_AIRF,           airF,           0x0)
    Character.edit_action_parameters(ICECLIMBERS, Action.AttackAirB,        File.ICECLIMBERS_ANIM_AIRB,           airB,           0x0)
    Character.edit_action_parameters(ICECLIMBERS, Action.AttackAirU,        File.ICECLIMBERS_ANIM_AIRU,           airU,           0x0)
    Character.edit_action_parameters(ICECLIMBERS, Action.AttackAirD,        File.ICECLIMBERS_ANIM_AIRD,           airD,           0x0)
    Character.edit_action_parameters(ICECLIMBERS, Action.LandingAirU,       File.ICECLIMBERS_ANIM_LANDINGAIRU,    -1,             0x0)

    Character.edit_action_parameters(ICECLIMBERS, Action.Grab,              File.ICECLIMBERS_ANIM_GRAB,           grab,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.GrabPull,          File.ICECLIMBERS_ANIM_GRABPULL,       -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.ThrowF,            File.ICECLIMBERS_ANIM_THROWF,         CUSTOM_THROWF,  -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.ThrowB,            File.ICECLIMBERS_ANIM_THROWB,         CUSTOM_THROWB,  -1)

    Character.edit_action_parameters(ICECLIMBERS, Action.Jab1,              File.ICECLIMBERS_ANIM_JAB1,           jab1,           -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Jab2,              File.ICECLIMBERS_ANIM_JAB2,           jab2,           -1)

    Character.edit_action_parameters(ICECLIMBERS, Action.DamageHigh1,       File.ICECLIMBERS_ANIM_DAMAGEHI1,      -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageHigh2,       File.ICECLIMBERS_ANIM_DAMAGEHI2,      -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageHigh3,       File.ICECLIMBERS_ANIM_DAMAGEHI3,      -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageMid1,        File.ICECLIMBERS_ANIM_DAMAGEN1,       -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageMid2,        File.ICECLIMBERS_ANIM_DAMAGEN2,       -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageMid3,        File.ICECLIMBERS_ANIM_DAMAGEN3,       -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageLow1,        File.ICECLIMBERS_ANIM_DAMAGELW1,      -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageLow2,        File.ICECLIMBERS_ANIM_DAMAGELW2,      -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageLow3,        File.ICECLIMBERS_ANIM_DAMAGELW3,      -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageAir1,        File.ICECLIMBERS_ANIM_DAMAGEAIR1,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageAir2,        File.ICECLIMBERS_ANIM_DAMAGEAIR2,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageAir3,        File.ICECLIMBERS_ANIM_DAMAGEAIR3,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageFlyHigh,     File.ICECLIMBERS_ANIM_DAMAGEFLYHI,    -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageFlyMid,      File.ICECLIMBERS_ANIM_DAMAGEFLYN,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageFlyLow,      File.ICECLIMBERS_ANIM_DAMAGEFLYLW,    -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.WallBounce,        File.ICECLIMBERS_ANIM_DAMAGEFALL,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Tumble,            File.ICECLIMBERS_ANIM_DAMAGEFALL,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageFlyRoll,     File.ICECLIMBERS_ANIM_DAMAGEFLYROLL,  -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DamageFlyTop,      File.ICECLIMBERS_ANIM_DAMAGEFLYTOP,   -1,             -1)

    Character.edit_action_parameters(ICECLIMBERS, Action.ShieldBreak,       -1,                                   SHIELDBREAK_,   -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Stun,              -1,                                   STUN_,          -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Sleep,             -1,                                   SLEEP_,         -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DownBounceU,       File.ICECLIMBERS_ANIM_DOWNBOUNCEU,    -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.StunLandU,         File.ICECLIMBERS_ANIM_DOWNBOUNCEU,    -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DownBounceD,       File.ICECLIMBERS_ANIM_DOWNBOUNCED,    -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.StunLandD,         File.ICECLIMBERS_ANIM_DOWNBOUNCED,    -1,             -1)

    Character.edit_action_parameters(ICECLIMBERS, Action.WallBounce,        File.ICECLIMBERS_ANIM_DAMAGEFALL,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.Tumble,            File.ICECLIMBERS_ANIM_DAMAGEFALL,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.ShieldBreakFall,   File.ICECLIMBERS_ANIM_DAMAGEFALL,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.InhalePulled,      File.ICECLIMBERS_ANIM_DAMAGEFALL,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.InhaleSpat,        File.ICECLIMBERS_ANIM_DAMAGEFALL,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.InhaleCopied,      File.ICECLIMBERS_ANIM_DAMAGEFALL,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.DeadU,             File.ICECLIMBERS_ANIM_DAMAGEFALL,     -1,             -1)
    Character.edit_action_parameters(ICECLIMBERS, Action.ScreenKO,          File.ICECLIMBERS_ANIM_DAMAGEFALL,     -1,             -1)
    
    Character.edit_action_parameters(ICECLIMBERS, Action.ShieldBreak,       File.ICECLIMBERS_ANIM_DAMAGEFLYTOP,   -1,             -1)

    Character.edit_action_parameters(ICECLIMBERS, Action.JumpSquat,         File.ICECLIMBERS_ANIM_LANDING,        -1,             -1);
    Character.edit_action_parameters(ICECLIMBERS, Action.ShieldJumpSquat,   File.ICECLIMBERS_ANIM_LANDING,        -1,             -1);
    Character.edit_action_parameters(ICECLIMBERS, Action.LandingLight,      File.ICECLIMBERS_ANIM_LANDING,        -1,             -1);
    Character.edit_action_parameters(ICECLIMBERS, Action.LandingHeavy,      File.ICECLIMBERS_ANIM_LANDING,        -1,             -1);
    Character.edit_action_parameters(ICECLIMBERS, Action.LandingAirX,       File.ICECLIMBERS_ANIM_LANDING,        -1,             -1);

    Character.edit_action_parameters(ICECLIMBERS, Action.Pass,              File.ICECLIMBERS_ANIM_PASS,           -1,             -1);
    Character.edit_action_parameters(ICECLIMBERS, Action.ShieldDrop,        File.ICECLIMBERS_ANIM_PASS,           -1,             -1);

    Character.edit_action_parameters(ICECLIMBERS, Action.LandingAirF,       File.ICECLIMBERS_ANIM_LANDINGAIRF,    -1,             -1);
    Character.edit_action_parameters(ICECLIMBERS, Action.LandingAirB,       File.ICECLIMBERS_ANIM_LANDINGAIRB,    -1,             -1);
    Character.edit_action_parameters(ICECLIMBERS, Action.LandingAirD,       File.ICECLIMBERS_ANIM_LANDINGAIRD,    -1,             -1);

    Character.edit_action_parameters(ICECLIMBERS, Action.Crouch,            File.ICECLIMBERS_ANIM_CROUCH,         -1,             -1);
    Character.edit_action_parameters(ICECLIMBERS, Action.CrouchIdle,        File.ICECLIMBERS_ANIM_CROUCHWAIT,     -1,             -1);
    Character.edit_action_parameters(ICECLIMBERS, Action.CrouchEnd,         File.ICECLIMBERS_ANIM_CROUCHEND,      -1,             -1);

    // Add Action Parameters                     // Action Name // Base Action     // Animation                         // Moveset Data // Flags
    Character.add_new_action_params(ICECLIMBERS, SQUALLSOLO,    -1,                File.ICECLIMBERS_ANIM_SQUALLSOLO,    squall,         0x0)
    Character.add_new_action(ICECLIMBERS, SQUALLSOLO, -1, ActionParams.SQUALLSOLO, -1, IceClimbersUSP._update, 0, IceClimbersUSP._physics, IceClimbersUSP._collision)
    Character.add_new_action_params(ICECLIMBERS, SQUALLDUO,     -1,                File.ICECLIMBERS_ANIM_SQUALLDUO,     squallDuo,      0x0)
    Character.add_new_action(ICECLIMBERS, SQUALLDUO, -1, ActionParams.SQUALLDUO, -1, IceClimbersUSP._update, IceClimbersUSP._duo_interrupt_brother, IceClimbersUSP._physics, IceClimbersUSP._collision)
    Character.add_new_action_params(ICECLIMBERS, SQUALLDUONANA, -1,                File.ICECLIMBERS_ANIM_SQUALLDUONANA, squallDuoNana,  0x0)
    Character.add_new_action(ICECLIMBERS, SQUALLDUONANA, -1, ActionParams.SQUALLDUONANA, -1, IceClimbersUSP._update, IceClimbersUSP._duo_interrupt_sister,  IceClimbersUSP._nana_duo_physics, 0)

    Character.add_new_action_params(ICECLIMBERS, ICEBLOCK,      -1,                File.ICECLIMBERS_ANIM_SPECIALN,      specialN,       0x0)
    Character.add_new_action(ICECLIMBERS, ICEBLOCK, -1, ActionParams.ICEBLOCK, -1, IceClimbersNSP._update, -1, IceClimbersNSP._physics, IceClimbersNSP._collision)
    Character.add_new_action_params(ICECLIMBERS, BLIZZARD,      -1,                File.ICECLIMBERS_ANIM_SPECIALLW,     blizz,          0x0)
    Character.add_new_action(ICECLIMBERS, BLIZZARD, -1, ActionParams.BLIZZARD, -1, IceClimbersDSP._update, -1, IceClimbersDSP._physics, IceClimbersDSP._collision)

    Character.add_new_action_params(ICECLIMBERS, FAIR_,         Action.AttackAirF, File.ICECLIMBERS_ANIM_AIRF,          airF,           -1)
    Character.add_new_action(ICECLIMBERS, FAIR_, Action.AttackAirF, ActionParams.FAIR_, -1, -1, _icies_fair, -1, -1)
    Character.add_new_action_params(ICECLIMBERS, SMASHD_,       Action.DSmash,     File.ICECLIMBERS_ANIM_SMASHD,        smashD,         0x0)
    Character.add_new_action(ICECLIMBERS, SMASHD_, Action.DSmash, ActionParams.SMASHD_, -1, -1, _icies_dsmash, -1, -1)

    Character.add_new_action_params(ICECLIMBERS, DEAD_, Action.Idle, 0x0, dead, -1)
    Character.add_new_action(ICECLIMBERS, DEAD_, -1, ActionParams.DEAD_, 0x0, 0x8013C0EC, 0x0, 0x0, 0x0)

    Character.add_new_action_params(ICECLIMBERS, CHEERF, -1, File.ICECLIMBERS_ANIM_THROWFNANA, 0x80000000, 0x40000000)
    Character.add_new_action(ICECLIMBERS, CHEERF, -1, ActionParams.CHEERF, -1, 0x800D94C4, 0, 0x800D8C14, 0x800DDF44)
    Character.add_new_action_params(ICECLIMBERS, CHEERB, -1, File.ICECLIMBERS_ANIM_THROWBNANA, 0x80000000, 0x40000000)
    Character.add_new_action(ICECLIMBERS, CHEERB, -1, ActionParams.CHEERB, -1, 0x800D94C4, 0, 0x800D8C14, 0x800DDF44)

    // Modify Menu Action Parameters // Action // Animation // Moveset Data // Flags
    Character.edit_menu_action_parameters(ICECLIMBERS, 0x0, File.ICECLIMBERS_ANIM_IDLE, -1, -1)
    Character.edit_menu_action_parameters(ICECLIMBERS, 0x1, File.ICECLIMBERS_ANIM_WIN1, -1, -1)
    Character.edit_menu_action_parameters(ICECLIMBERS, 0x2, File.ICECLIMBERS_ANIM_WIN2, win2, -1)
    Character.edit_menu_action_parameters(ICECLIMBERS, 0x3, File.ICECLIMBERS_ANIM_WIN3, -1, -1)
    Character.edit_menu_action_parameters(ICECLIMBERS, 0x4, File.ICECLIMBERS_ANIM_WIN3, -1, -1)
    Character.edit_menu_action_parameters(ICECLIMBERS, 0x5, File.ICECLIMBERS_ANIM_CLAPS, -1, -1)
    Character.edit_menu_action_parameters(ICECLIMBERS, 0xA, File.ICECLIMBERS_ANIM_IDLE, -1, -1)
    Character.edit_menu_action_parameters(ICECLIMBERS, 0xD, File.ICECLIMBERS_ANIM_IDLE, -1, -1)
    Character.edit_menu_action_parameters(ICECLIMBERS, 0xE, File.ICECLIMBERS_ANIM_IDLE, -1, -1)

    // Menu actions for Nana
    Character.add_new_action_params(ICECLIMBERS, WIN1NANA, -1, File.ICECLIMBERS_ANIM_WIN1NANA, 0x80000000, 0x0)
    Character.add_new_action(ICECLIMBERS, WIN1NANA, -1, ActionParams.WIN1NANA, -1, 0x0, 0x0, 0x0, 0x0)
    Character.add_new_action_params(ICECLIMBERS, WIN2NANA, -1, File.ICECLIMBERS_ANIM_WIN2NANA, win2nana, 0x0)
    Character.add_new_action(ICECLIMBERS, WIN2NANA, -1, ActionParams.WIN2NANA, -1, 0x0, 0x0, 0x0, 0x0)
    Character.add_new_action_params(ICECLIMBERS, WIN3NANA, -1, File.ICECLIMBERS_ANIM_WIN3NANA, 0x80000000, 0x0)
    Character.add_new_action(ICECLIMBERS, WIN3NANA, -1, ActionParams.WIN3NANA, -1, 0x0, 0x0, 0x0, 0x0)
    Character.add_new_action_params(ICECLIMBERS, CLAPSNANA, -1, File.ICECLIMBERS_ANIM_CLAPSNANA, 0x80000000, 0x0)
    Character.add_new_action(ICECLIMBERS, CLAPSNANA, -1, ActionParams.CLAPSNANA, -1, 0x0, 0x0, 0x0, 0x0)
    
    // Action replacement map
    scope action_replace_map_: {
        dh Action.AttackAirF; dh IceClimbers.Action.FAIR_;
        dh Action.DSmash; dh IceClimbers.Action.SMASHD_;
        dh Action.DeadD; dh IceClimbers.Action.DEAD_;
        dh Action.DeadS; dh IceClimbers.Action.DEAD_;
        dw 0xFFFFFFFF // end of map
    }

    // Set action replacement table
    Character.table_patch_start(action_replace_map, Character.id.ICECLIMBERS, 0x4)
    dw action_replace_map_
    OS.patch_end()

    Character.table_patch_start(air_usp, Character.id.ICECLIMBERS, 0x4)
    dw      IceClimbersUSP._initial
    OS.patch_end()
	
    Character.table_patch_start(ground_usp, Character.id.ICECLIMBERS, 0x4)
    dw      IceClimbersUSP._initial
    OS.patch_end()

    Character.table_patch_start(air_nsp, Character.id.ICECLIMBERS, 0x4)
    dw      IceClimbersNSP._initial
    OS.patch_end()
	
    Character.table_patch_start(ground_nsp, Character.id.ICECLIMBERS, 0x4)
    dw      IceClimbersNSP._initial
    OS.patch_end()

    Character.table_patch_start(air_dsp, Character.id.ICECLIMBERS, 0x4)
    dw      IceClimbersDSP._initial
    OS.patch_end()
	
    Character.table_patch_start(ground_dsp, Character.id.ICECLIMBERS, 0x4)
    dw      IceClimbersDSP._initial
    OS.patch_end()

    Character.table_patch_start(jab_3, Character.id.ICECLIMBERS, 0x4)
    dw      Character.jab_3.DISABLED        // disable jab 3
    OS.patch_end()

    // Remove entry script (no more warp pipe).
    Character.table_patch_start(entry_script, Character.id.ICECLIMBERS, 0x4)
    dw 0x8013DD68                           // skips entry script
    OS.patch_end()

    scope grounded_script_: {
        j Character.grounded_script.DISABLED // back to original routine
        nop
    }
	
    Character.table_patch_start(grounded_script, Character.id.ICECLIMBERS, 0x4)
    dw grounded_script_
    OS.patch_end()

    scope initial_script_: {
        j 0x800D7F0C // back to original routine
        nop
    }
	
    Character.table_patch_start(initial_script, Character.id.ICECLIMBERS, 0x4)
    dw initial_script_
    OS.patch_end()

    // Set default costumes
    Character.set_default_costumes(Character.id.ICECLIMBERS, 0, 1, 2, 3, 1, 0, 3)
    Teams.add_team_costume(YELLOW, ICECLIMBERS, 0x4)

    // Shield colors for costume matching
    Character.set_costume_shield_colors(ICECLIMBERS, BLUE, RED, CYAN, GREEN, YELLOW, ORANGE, BROWN, BLACK)

    // single "mash" press
    ICIES_USP_MASH:
    AI.UNPRESS_Z()
    AI.UNPRESS_A()
    AI.UNPRESS_B()
    dh 0xA080       // stick x = tilt to target
    AI.PRESS_B(1)
    AI.UNPRESS_B(1)
    AI.END()
    AI.add_cpu_input_routine(ICIES_USP_MASH)

    ICIES_RECOVERY: {
        OS.routine_begin(0x20)

        lw      v0, 0x0024(a0)              // v0 = current action ID
        addiu   at, r0, IceClimbers.Action.SQUALLSOLO
        beq     at, v0, _upB
        addiu   at, r0, IceClimbers.Action.SQUALLDUO
        beq     at, v0, _upB
        nop

        b   _end // no override
        nop

        _upB:
        lw          t1, 0x78(a0) // load location vector
        lwc1        f2, 0x4(t1) // f2 = location Y
        lwc1        f4, 0x01CC+0x64(a0) // f4 = target Y

        // if location Y > target Y, skip
        c.lt.s      f2, f4
        nop
        bc1t        _end
        nop

        jal     0x80132758              // execute AI command
        addiu   a1, r0, AI.ROUTINE.ICIES_USP_MASH // arg1 = PRESS B

        _end:
        OS.routine_end(0x20)
    }
    Character.table_patch_start(recovery_logic, Character.id.ICECLIMBERS, 0x4)
    dw  ICIES_RECOVERY
    OS.patch_end()

    CPU_ATTACKS:
    // Edit cpu attack behaviours
    // edit_attack_behavior(table, attack, override, start_hb, end_hb, min_x, max_x, min_y, max_y)
    AI.add_attack_behaviour(JAB, 4, -38, 423, 230, 359)
    AI.add_attack_behaviour(GRAB, 6, 146, 291, 163, 308)
    AI.add_attack_behaviour(UTILT, 7, -90, 90, 266, 650)
    AI.add_attack_behaviour(DTILT, 7, 81, 588, 21, 198)
    AI.add_attack_behaviour(FTILT, 8, -3, 558, 122, 245)
    AI.add_attack_behaviour(DSMASH, 8, 59, 570, 0, 210)
    AI.add_attack_behaviour(USPG, 9, -483, 482, 22, 605)
    AI.add_attack_behaviour(FSMASH, 10, 157, 508, 14, 326)
    AI.add_attack_behaviour(USMASH, 11, -400, 325, 88, 696)
    AI.add_attack_behaviour(DSPG, 17, 0, 950, 0, 600)
    AI.add_attack_behaviour(NSPG, 30, 500, 1000, 0, 200)
    AI.add_custom_attack_behaviour(AI.ROUTINE.DASH_ATTACK, 9, 566, 971, 119, 346)
    AI.END_ATTACKS() // end of grounded attacks

    AI.add_attack_behaviour(NAIR, 5, -291, 416, 26, 371)
    AI.add_attack_behaviour(UAIR, 6, -446, 392, 359, 867)
    AI.add_attack_behaviour(USPA, 9, -483, 482, 22, 605)
    AI.add_custom_attack_behaviour(AI.ROUTINE.BAIR, 8, -447, 250, 65, 239)
    AI.add_attack_behaviour(DAIR, 11, -63, 134, -91, 110)
    AI.add_custom_attack_behaviour(AI.ROUTINE.FAIR, 14, 10, 366, -65, 607)
    AI.add_attack_behaviour(DSPA, 17, 0, 950, 0, 600)
    AI.add_attack_behaviour(NSPA, 30, 500, 1000, -200, 0)

    AI.END_ATTACKS() // end of aerial attacks
    OS.align(16)

    // Set CPU behaviour
    Character.table_patch_start(ai_behaviour, Character.id.ICECLIMBERS, 0x4)
    dw      CPU_ATTACKS
    OS.patch_end()

    scope Action {
        string_0x0DC:; String.insert("Jab3")
        string_0x0DE:; String.insert("Entry")
        string_0x0DF:; String.insert("MagicICECLIMBERSRide")
        string_0x0E0:; String.insert("MagicICECLIMBERSAttack")
        string_0x0E1:; String.insert("MagicICECLIMBERSJump")
        string_0x0E2:; String.insert("MagicICECLIMBERSEscape")
        string_0x0E5:; String.insert("SquallHammerSolo")
        string_0x0E6:; String.insert("SquallHammerDuo")
        string_0x0E7:; String.insert("SquallHammerDuoNana")
        string_0x0EA:; String.insert("IceShot")
        string_0x0EB:; String.insert("Blizzard")

        action_string_table:
        dw string_0x0DC
        dw Action.COMMON.string_jabloop
        dw string_0x0DE
        dw string_0x0DF
        dw string_0x0E0
        dw string_0x0E1
        dw string_0x0E2
        dw Action.COMMON.string_jabloop
        dw Action.COMMON.string_jabloop
        dw string_0x0E5
        dw string_0x0E6
        dw string_0x0E7
        dw Action.string_0x0D2 // fair
        dw Action.string_0x0D0 // dsmash
        dw string_0x0EA
        dw string_0x0EB
    }

    // Set action strings
    Character.table_patch_start(action_string, Character.id.ICECLIMBERS, 0x4)
    dw  Action.action_string_table
    OS.patch_end()
}