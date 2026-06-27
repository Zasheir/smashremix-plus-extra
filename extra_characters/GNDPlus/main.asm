// GNDPlus.asm

// This file contains file inclusions, action edits, and assembly for GNDPlus.

scope GNDPlus {

    scope FACE: {
        constant NORMAL(0xAC000000)
        constant BLINK(0xAC000001)
        constant SLEEP(0xAC000001)
        constant SHOCK(0xAC000006)
        constant LAUGH(0xAC000007)
    }
    scope HAND_L: {
        constant CLOSED(0xA0500000)
        constant OPEN(0xA0500001)
    }
    scope HAND_R: {
        constant CLOSED(0xA0800000)
        constant OPEN(0xA0800001)
    }
    scope TRIDENT: {
        constant SHOW(0xA0880000)
        constant HIDE(0xA0880001)
    }

    // Insert Moveset files
    insert BLINK_,"moveset/BLINK.bin"; Moveset.GO_TO(BLINK_)            // loops
    IDLE_:
    dw 0xBC000003                               // set slope contour state
    dw 0xD0013F33                               // set FSM without setting command execution speed
    Moveset.SUBROUTINE(BLINK_)                   // blink
    dw 0x0400001E; Moveset.SUBROUTINE(BLINK_)    // wait 30 frames then blink
    dw 0x04000050; Moveset.SUBROUTINE(BLINK_)    // wait 80 frames then blink
    dw 0x04000032; Moveset.GO_TO(IDLE_)          // loop
    insert RUN_,"moveset/RUN.bin"; Moveset.GO_TO(RUN_)            // loops
    insert SPARKLE_,"moveset/SPARKLE.bin"; Moveset.GO_TO(SPARKLE_)            // loops
    insert SHIELD_BREAK_,"moveset/SHIELD_BREAK.bin"; Moveset.GO_TO(SPARKLE_)            // loops
    insert STUN_, "moveset/STUN.bin"; Moveset.GO_TO(STUN_)         // loops
    insert SLEEP_, "moveset/SLEEP.bin"; Moveset.GO_TO(SLEEP_)         // loops
    USP_GROUND_:; Moveset.THROW_DATA(USP_THROW_DATA); insert "moveset/UP_SPECIAL_GROUND.bin"
    USP_AIR_:; Moveset.THROW_DATA(USP_THROW_DATA); insert "moveset/UP_SPECIAL_AIR.bin"
    ENTRY_1_:; insert "moveset/ENTRY_1.bin"

    TEETER:
    dw FACE.SHOCK; dw 0;

	DOWN_BOUNCE:
	dw FACE.SHOCK
	Moveset.GO_TO(Moveset.shared.DOWN_BOUNCE)

    // Modify Action Parameters             // Action               // Animation                // Moveset Data             // Flags
    Character.edit_action_parameters(GNDPLUS,   Action.Idle,            File.GNDPLUS_ANIM_NEWIDLE,       IDLE_,                       -1)
    Character.edit_action_parameters(GNDPLUS,   Action.ReviveWait,      File.GNDPLUS_ANIM_NEWIDLE,       IDLE_,                       -1)
    Character.edit_action_parameters(GNDPLUS,   Action.Run,             -1,                         RUN_,                        -1)
    Character.edit_action_parameters(GNDPLUS,   Action.Teeter,          -1,                         TEETER,                     -1)
    Character.edit_action_parameters(GNDPLUS,   Action.JumpAerialF,     -1,                         JUMP2,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.JumpAerialB,     -1,                         JUMP2,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.DownBounceD,     -1,                         DOWN_BOUNCE,                -1)
    Character.edit_action_parameters(GNDPLUS,   Action.DownBounceU,     -1,                         DOWN_BOUNCE,                -1)
    Character.edit_action_parameters(GNDPLUS,   Action.DownStandD,      -1,                         DOWN_STAND,                 -1)
    Character.edit_action_parameters(GNDPLUS,   Action.DownStandU,      -1,                         DOWN_STAND,                 -1)
    Character.edit_action_parameters(GNDPLUS,   Action.TechF,           -1,                         TECHROLL,                   -1)
    Character.edit_action_parameters(GNDPLUS,   Action.TechB,           -1,                         TECHROLL,                   -1)
    Character.edit_action_parameters(GNDPLUS,   Action.Tech,            -1,                         TECHSTAND,                  -1)
    Character.edit_action_parameters(GNDPLUS,   Action.CliffAttackQuick2, -1,                       edgeattackf,                -1)
    Character.edit_action_parameters(GNDPLUS,   Action.CliffAttackSlow2, -1,                        EDGEATTACKS,                -1)
    Character.edit_action_parameters(GNDPLUS,   Action.Taunt,           File.GND_TAUNT,             TAUNT,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.ShieldBreak,     -1,                         SHIELD_BREAK_,               -1)
    Character.edit_action_parameters(GNDPLUS,   Action.Stun,            -1,                         STUN_,                       -1)
    Character.edit_action_parameters(GNDPLUS,   Action.Sleep,           -1,                         SLEEP_,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.Jab1,            -1,                         JAB_1,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.DashAttack,      -1,                         DASH_ATTACK,                -1)
    Character.edit_action_parameters(GNDPLUS,   Action.FTiltHigh,       File.GNDPLUS_ANIM_FTILT,         FTILT,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.FTiltMidHigh,    File.GNDPLUS_ANIM_FTILT,         FTILT,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.FTilt,           File.GNDPLUS_ANIM_FTILT,         FTILT,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.FTiltMidLow,     File.GNDPLUS_ANIM_FTILT,         FTILT,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.FTiltLow,        File.GNDPLUS_ANIM_FTILT,         FTILT,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.UTilt,           -1,                         UTILT,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.DTilt,           -1,                         DTILT,                      -1)
    Character.edit_action_parameters(GNDPLUS,   Action.FSmashHigh,      0,                          0x80000000,                 0)
    Character.edit_action_parameters(GNDPLUS,   Action.FSmash,          0x64E,                      FSMASH,                     0)
    Character.edit_action_parameters(GNDPLUS,   Action.FSmashLow,       0,                          0x80000000,                 0)
    Character.edit_action_parameters(GNDPLUS,   Action.USmash,          File.GND_USMASH,            USMASH,                     0)
    Character.edit_action_parameters(GNDPLUS,   Action.DSmash,          File.GND_DSMASH,            DSMASH,                     -1)
    Character.edit_action_parameters(GNDPLUS,   Action.AttackAirN,      0x667,                      NAIR,                       -1)
    Character.edit_action_parameters(GNDPLUS,   Action.AttackAirF,      File.GND_FAIR,              FAIR,                       -1)
    Character.edit_action_parameters(GNDPLUS,   Action.AttackAirB,      -1,                         BAIR,                       -1)
    Character.edit_action_parameters(GNDPLUS,   Action.AttackAirU,      -1,                         UAIR,                       -1)
    Character.edit_action_parameters(GNDPLUS,   Action.AttackAirD,      -1,                         DAIR,                       -1)
    Character.edit_action_parameters(GNDPLUS,   Action.LandingAirN,     0x66B,                      0x1720,                     -1)
    Character.edit_action_parameters(GNDPLUS,   Action.LandingAirF,     0,                          0x80000000,                 -1)
    Character.edit_action_parameters(GNDPLUS,   0xE0,                   File.GND_ENTRY_1,           ENTRY_1_,                    0x40000000)
    Character.edit_action_parameters(GNDPLUS,   0xE1,                   File.GND_ENTRY_1,           ENTRY_1_,                    0x40000000)
    Character.edit_action_parameters(GNDPLUS,   0xE2,                   File.GND_ENTRY_2_LEFT,      ENTRY_2,                    0x40000000)
    Character.edit_action_parameters(GNDPLUS,   0xE3,                   File.GND_ENTRY_2_RIGHT,     ENTRY_2,                    0x40000000)
    Character.edit_action_parameters(GNDPLUS,   0xE4,                   -1,                         NSP_GROUND,                 -1)
    Character.edit_action_parameters(GNDPLUS,   0xE5,                   -1,                         NSP_AIR,                    -1)
    Character.edit_action_parameters(GNDPLUS,   0xE6,                   -1,                         DSP_GROUND,                 -1)
    Character.edit_action_parameters(GNDPLUS,   0xE7,                   -1,                         DSP_FLIP,                   -1)
    Character.edit_action_parameters(GNDPLUS,   0xE8,                   -1,                         DSP_LAND,                   -1)
    Character.edit_action_parameters(GNDPLUS,   0xE9,                   -1,                         DSP_AIR,                    -1)
    Character.edit_action_parameters(GNDPLUS,   0xEB,                   -1,                         USP_GROUND_,                 -1)
    Character.edit_action_parameters(GNDPLUS,   0xEC,                   -1,                         USP_GRAB,                   -1)
    Character.edit_action_parameters(GNDPLUS,   0xED,                   -1,                         USP_RELEASE,                -1)
    Character.edit_action_parameters(GNDPLUS,   0xEE,                   -1,                         USP_AIR_,                    -1)

    // Modify Menu Action Parameters             // Action          // Animation                // Moveset Data             // Flags
    Character.edit_menu_action_parameters(GNDPLUS,   0x0,               File.GNDPLUS_ANIM_NEWIDLE,       IDLE_,                       -1)
    Character.edit_menu_action_parameters(GNDPLUS,   0x1,               -1,                         VICTORY_POSE_1,             -1)
    Character.edit_menu_action_parameters(GNDPLUS,   0x2,               File.GND_SELECT,            VICTORY_POSE_2,             -1)
    Character.edit_menu_action_parameters(GNDPLUS,   0x3,               File.GND_VICTORY1,          VICTORY_POSE_3,             -1)
    Character.edit_menu_action_parameters(GNDPLUS,   0x4,               File.GND_VICTORY1,          VICTORY_POSE_3,             -1)
    Character.edit_menu_action_parameters(GNDPLUS,   0xE,               File.GND_1P_CPU,            ONEP,                       -1)
    Character.edit_menu_action_parameters(GNDPLUS,   0xD,               File.GND_POSE_1P,           ONEP,                       -1)

    // Set menu zoom size.
    Character.table_patch_start(menu_zoom, Character.id.GNDPLUS, 0x4)
    float32 1.125
    OS.patch_end()

    // Remove entry script.
    Character.table_patch_start(entry_script, Character.id.GNDPLUS, 0x4)
    dw 0x8013DD68                           // skips entry script
    OS.patch_end()

    // Set crowd chant FGM.
    Character.table_patch_start(crowd_chant_fgm, Character.id.GNDPLUS, 0x2)
    dh  0x02EA
    OS.patch_end()

    // Set default costumes
    Character.set_default_costumes(Character.id.GNDPLUS, 0, 6, 5, 3, 4, 1, 2)
    Teams.add_team_costume(YELLOW, GNDPLUS, 0x7)

    // Shield colors for costume matching
    Character.set_costume_shield_colors(GNDPLUS, ORANGE, BLUE, GREEN, PURPLE, RED, BROWN, AZURE, YELLOW)

    // Set Kirby star damage
    Character.table_patch_start(kirby_inhale_struct, 0x8, Character.id.GND, 0xC)
    dw Character.kirby_inhale_struct.star_damage.DK
    OS.patch_end()

    // Set Kirby hat_id
    Character.table_patch_start(kirby_inhale_struct, 0x2, Character.id.GND, 0xC)
    dh 0x11
    OS.patch_end()

    // @ Description
    // GNDPlus's extra actions
    scope Action {
        //constant Jab3(0x0DC)
        //constant JabLoopStart(0x0DD)
        //constant JabLoop(0x0DE)
        //constant JabLoopEnd(0x0DF)
        constant AppearLeft1(0x0E0)
        constant AppearRight1(0x0E1)
        constant AppearLeft2(0x0E2)
        constant AppearRight2(0x0E3)
        constant WarlockPunch(0x0E4)
        constant WarlockPunchAir(0x0E5)
        constant WarlockKick(0x0E6)
        constant WarlockKickFromGroundAir(0x0E7)
        constant LandingWarlockKick(0x0E8)
        constant WarlockKickEnd(0x0E9)
        constant CollisionWarlockKick(0x0EA)
        constant WarlockDive(0x0EB)
        constant WarlockDiveCatch(0x0EC)
        constant WarlockDiveEnd1(0x0ED)
        constant WarlockDiveEnd2(0x0EE)

        // strings!
        //string_0x0DC:; String.insert("Jab3")
        //string_0x0DD:; String.insert("JabLoopStart")
        //string_0x0DE:; String.insert("JabLoop")
        //string_0x0DF:; String.insert("JabLoopEnd")
        string_0x0E0:; String.insert("AppearLeft1")
        string_0x0E1:; String.insert("AppearRight1")
        string_0x0E2:; String.insert("AppearLeft1")
        string_0x0E3:; String.insert("AppearRight2")
        string_0x0E4:; String.insert("WarlockPunch")
        string_0x0E5:; String.insert("WarlockPunchAir")
        string_0x0E6:; String.insert("WizardsFoot")
        string_0x0E7:; String.insert("WizardsFootFromGroundAir")
        string_0x0E8:; String.insert("LandingWizardsFoot")
        string_0x0E9:; String.insert("WizardsFootAir")
        string_0x0EA:; String.insert("WizardsFootRecoil")
        string_0x0EB:; String.insert("DarkDive")
        string_0x0EC:; String.insert("DarkDiveCatch")
        string_0x0ED:; String.insert("DarkDiveRelease")
        string_0x0EE:; String.insert("DarkDiveAir")

        action_string_table:
        dw 0
        dw 0
        dw 0
        dw 0
        dw string_0x0E0
        dw string_0x0E1
        dw string_0x0E2
        dw string_0x0E3
        dw string_0x0E4
        dw string_0x0E5
        dw string_0x0E6
        dw string_0x0E7
        dw string_0x0E8
        dw string_0x0E9
        dw string_0x0EA
        dw string_0x0EB
        dw string_0x0EC
        dw string_0x0ED
        dw string_0x0EE
    }

    // Set action strings
    Character.table_patch_start(action_string, Character.id.GNDPLUS, 0x4)
    dw  Action.action_string_table
    OS.patch_end()

    // Set Remix 1P ending music
    Character.table_patch_start(remix_1p_end_bgm, Character.id.GNDPLUS, 0x2)
    dh {MIDI.id.GERUDO_VALLEY}
    OS.patch_end()

}
