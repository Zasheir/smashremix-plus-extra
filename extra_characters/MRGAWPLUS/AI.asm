// This file contains this characters AI attacks

    MRGAWPLUS_CHEF_CANCEL:
    AI.UNPRESS_A();
    AI.CUSTOM(1);
    AI.UNPRESS_B(3);
    AI.CUSTOM(2);
    AI.UNPRESS_Z(3);
    AI.PRESS_B(2);          // press B, wait 2 frames
    AI.UNPRESS_B(28);        // unpress B, wait 28 frames
    AI.PRESS_B(2);          // press B, wait 2 frames
    AI.UNPRESS_B(2);        // unpress B, wait 2 frames
    AI.STICK_Y(0);          // stick y to neutral
    AI.STICK_X(0);	    // stick x to neutral
    AI.END();
    AI.add_cpu_input_routine(MRGAWPLUS_CHEF_CANCEL)

    MRGAWPLUS_CHEF_MULTI:
    AI.UNPRESS_A();
    AI.UNPRESS_B();
    AI.UNPRESS_Z();
    AI.PRESS_B(2);          // press B, wait 2 frames
    AI.UNPRESS_B(30);        // unpress B, wait 30 frames
    AI.PRESS_B(2);          // press B, wait 2 frames
    AI.UNPRESS_B(16);        // unpress B, wait 16 frames
    AI.PRESS_B(2);          // press B, wait 2 frames
    AI.UNPRESS_B(16);        // unpress B, wait 16 frames
    AI.PRESS_B(2);          // press B, wait 2 frames
    AI.UNPRESS_B(16);        // unpress B, wait 16 frames
    AI.PRESS_B(2);          // press B, wait 2 frames
    AI.UNPRESS_B(16);        // unpress B, wait 16 frames
    AI.STICK_Y(0);          // stick y to neutral
    AI.STICK_X(0);	    // stick x to neutral
    AI.END();
    AI.add_cpu_input_routine(MRGAWPLUS_CHEF_MULTI)

// Create new cpu attack behaviours
OS.align(4)
CPU_ATTACKS:
// grounded attacks
// add_attack_behaviour(table, attack, hitbox_start_frame, min_x, max_x, min_y, max_y)
AI.add_attack_behaviour(JAB, 4, 100, 420, 120, 272)
AI.add_attack_behaviour(FTILT, 9, 108, 412, 85, 286)
AI.add_attack_behaviour(UTILT, 6, -227, 370, 112, 538)
AI.add_attack_behaviour(DTILT, 5, 259, 433, -50, 156)
AI.add_attack_behaviour(FSMASH, 14, 96, 640, 106, 290)
AI.add_attack_behaviour(USMASH, 10, -265, 320, 221, 462)
AI.add_attack_behaviour(DSMASH, 11, -479, 491, 28, 186)
AI.add_attack_behaviour(NSPG, 83, 1200, 1600, 0, 400)
AI.add_attack_behaviour(USPG, 2, -95, 95, -3, 400)
AI.add_attack_behaviour(DSPG, 15, 103, 373, 143, 412)
AI.add_attack_behaviour(GRAB, 6, 169, 313, 162, 306)
AI.add_custom_attack_behaviour(AI.ROUTINE.DASH_ATTACK, 6, 200, 1200, 70, 250)
AI.add_custom_attack_behaviour(AI.ROUTINE.MRGAWPLUS_CHEF_CANCEL, 16, 400, 2000, -25, 300)
AI.add_custom_attack_behaviour(AI.ROUTINE.MRGAWPLUS_CHEF_MULTI, 16, 400, 2000, -25, 300)
// we can add new grounded attacks here

AI.END_ATTACKS() // end of grounded attacks

// aerial attacks
// add_attack_behaviour(table, attack, hitbox_start_frame, min_x, max_x, min_y, max_y)
AI.add_attack_behaviour(NAIR, 6, -150, 150, 176, 500)
AI.add_attack_behaviour(FAIR, 9, 61, 414, -25, 135)
AI.add_attack_behaviour(UAIR, 5, -135, 53, 189, 619)
AI.add_attack_behaviour(DAIR, 9, 2, 253, -310, 93)
AI.add_attack_behaviour(BAIR, 10, -450, -15, -50, 125)
AI.add_attack_behaviour(NSPA, 83, 1200, 1600, 0, 400)
AI.add_attack_behaviour(USPA, 2, -95, 95, -3, 400)
AI.add_attack_behaviour(DSPA, 15, 103, 373, 143, 412)
// we can add new aerial attacks here

AI.END_ATTACKS() // end of aerial attacks
OS.align(16)

// Set CPU behaviour
Character.table_patch_start(ai_behaviour, Character.id.MRGAWPLUS, 0x4)
dw CPU_ATTACKS
OS.patch_end()

// Set CPU SD prevent routine
Character.table_patch_start(ai_attack_prevent, Character.id.MRGAWPLUS, 0x4)
dw AI.PREVENT_ATTACK.ROUTINE.USP // skip USP if unsafe
OS.patch_end()

// Set CPU NSP long range behaviour
Character.table_patch_start(ai_long_range, Character.id.MRGAWPLUS, 0x4)
dw AI.LONG_RANGE.ROUTINE.NSP_SHOOT
OS.patch_end()