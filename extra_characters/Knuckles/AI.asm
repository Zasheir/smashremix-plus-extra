if !{defined __KNUCKLES_AI__} {
define __KNUCKLES_AI__()

// This file contains this characters AI attacks
scope KNUCKLES_AI: {
    // Define input sequences

    // Charges DSP a few times, jumps out of it to prevent SDs. Might follow up from it?
    KNUCKLES_CHARGED_DSP:
    AI.UNPRESS_A();
    AI.UNPRESS_B();
    AI.UNPRESS_Z();
    AI.STICK_X(0);
    AI.STICK_Y(0xB0);       // stick y down
    AI.PRESS_B(2);          // press B, wait 2 frames
    AI.UNPRESS_B(2);        // unpress B, wait 2 frames
    AI.PRESS_B(2);          // press B, wait 2 frames
    AI.UNPRESS_B(2);        // unpress B, wait 2 frames
    AI.PRESS_B(2);          // press B, wait 2 frames
    AI.UNPRESS_B(2);        // unpress B, wait 2 frames
    AI.PRESS_B(2);          // press B, wait 2 frames
    AI.UNPRESS_B(2);        // unpress B, wait 2 frames
    AI.STICK_Y(0);          // stick y to neutral
    // now wait a bit and then jump to get out of the attack
    AI.UNPRESS_B(5);        // unpress B, wait 5 frames
    AI.UNPRESS_B(5);        // unpress B, wait 5 frames
    AI.UNPRESS_B(5);        // unpress B, wait 5 frames
    AI.UNPRESS_B(5);        // unpress B, wait 5 frames
    AI.CUSTOM(1);           // press C
    AI.UNPRESS_B(1);        // unpress B, wait 1 frame
    AI.CUSTOM(2);           // unpress C
    AI.END();
    AI.add_cpu_input_routine(KNUCKLES_CHARGED_DSP)

    // Create new cpu attack behaviours
    OS.align(4)
    CPU_ATTACKS:
    // grounded attacks
    // add_attack_behaviour(table, attack, hitbox_start_frame, min_x, max_x, min_y, max_y)
    AI.add_attack_behaviour(JAB,    4, 125, 480, 79, 302)
    AI.add_attack_behaviour(GRAB,   6, 325, 455, 207, 337)
    AI.add_attack_behaviour(FTILT,  8, 261, 612, 92, 293)
    AI.add_attack_behaviour(UTILT,  8, 78, 438, 170, 758)
    AI.add_attack_behaviour(DTILT,  6, 145, 624, -12, 242)
    AI.add_attack_behaviour(FSMASH, 14, 496, 1125, 173, 348)
    AI.add_attack_behaviour(USMASH, 7, 40, 470, 240, 968)
    AI.add_attack_behaviour(DSMASH, 14, -450, 388, -79, 916)
    AI.add_custom_attack_behaviour(AI.ROUTINE.NSP_TOWARDS, 18, 1200, 2000, -600, 600)
    AI.add_custom_attack_behaviour(AI.ROUTINE.DASH_ATTACK, 16, 551, 1532, 140, 317)
    AI.add_custom_attack_behaviour(AI.ROUTINE.KNUCKLES_CHARGED_DSP, 12, 400, 1500, 0, 300)

    AI.END_ATTACKS() // end of grounded attacks

    // aerial attacks
    // add_attack_behaviour(table, attack, hitbox_start_frame, min_x, max_x, min_y, max_y)
    AI.add_attack_behaviour(NAIR, 6, -144, 244, 22, 286)
    AI.add_attack_behaviour(FAIR, 12, -119, 396, -110, 640)
    AI.add_attack_behaviour(UAIR, 6, -285, 402, 42, 553)
    AI.add_attack_behaviour(DAIR, 8, -115, 78, -61, 175)
    // we can add new aerial attacks here

    AI.END_ATTACKS() // end of aerial attacks
    OS.align(16)

    if {defined Character.CHARACTER_ADDED_KNUCKLES} {
        // Set CPU behaviour
        Character.table_patch_start(ai_behaviour, Character.id.KNUCKLES, 0x4)
        dw      CPU_ATTACKS
        OS.patch_end()

        // Set CPU SD prevent routine
        Character.table_patch_start(ai_attack_prevent, Character.id.KNUCKLES, 0x4)
        dw      AI.PREVENT_ATTACK.ROUTINE.SONIC_DSP
        OS.patch_end()

        // Set CPU NSP long range behaviour
        Character.table_patch_start(ai_long_range, Character.id.KNUCKLES, 0x4)
        dw    	AI.LONG_RANGE.ROUTINE.NONE
        OS.patch_end()
    }

    if {defined Character.CHARACTER_ADDED_MKNUCKLES} {
        // Set CPU behaviour
        Character.table_patch_start(ai_behaviour, Character.id.MKNUCKLES, 0x4)
        dw      CPU_ATTACKS
        OS.patch_end()

        // Set CPU SD prevent routine
        Character.table_patch_start(ai_attack_prevent, Character.id.MKNUCKLES, 0x4)
        dw      AI.PREVENT_ATTACK.ROUTINE.SONIC_DSP
        OS.patch_end()

        // Set CPU NSP long range behaviour
        Character.table_patch_start(ai_long_range, Character.id.MKNUCKLES, 0x4)
        dw    	AI.LONG_RANGE.ROUTINE.NONE
        OS.patch_end()
    }

    if {defined Character.CHARACTER_ADDED_CBKNUCKLES} {
        // Set CPU behaviour
        Character.table_patch_start(ai_behaviour, Character.id.CBKNUCKLES, 0x4)
        dw      CPU_ATTACKS
        OS.patch_end()

        // Set CPU SD prevent routine
        Character.table_patch_start(ai_attack_prevent, Character.id.CBKNUCKLES, 0x4)
        dw      AI.PREVENT_ATTACK.ROUTINE.SONIC_DSP
        OS.patch_end()

        // Set CPU NSP long range behaviour
        Character.table_patch_start(ai_long_range, Character.id.CBKNUCKLES, 0x4)
        dw    	AI.LONG_RANGE.ROUTINE.NONE
        OS.patch_end()
    }

    if {defined Character.CHARACTER_ADDED_CBMKNUCKLES} {
        // Set CPU behaviour
        Character.table_patch_start(ai_behaviour, Character.id.CBMKNUCKLES, 0x4)
        dw      CPU_ATTACKS
        OS.patch_end()

        // Set CPU SD prevent routine
        Character.table_patch_start(ai_attack_prevent, Character.id.CBMKNUCKLES, 0x4)
        dw      AI.PREVENT_ATTACK.ROUTINE.SONIC_DSP
        OS.patch_end()

        // Set CPU NSP long range behaviour
        Character.table_patch_start(ai_long_range, Character.id.CBMKNUCKLES, 0x4)
        dw    	AI.LONG_RANGE.ROUTINE.NONE
        OS.patch_end()
    }
}
}