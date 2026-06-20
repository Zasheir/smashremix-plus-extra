OS.align(4)
CPU_ATTACKS:
// Edit cpu attack behaviours
// edit_attack_behavior(table, attack, override, start_hb, end_hb, min_x, max_x, min_y, max_y)
AI.add_attack_behaviour(DTILT, 3, 281, 593, 53, 183)
AI.add_attack_behaviour(DSMASH, 4, 216, 530, 107, 348) // front hit
AI.add_attack_behaviour(DSMASH, 9, -484, -163, 117, 247) // back hit
AI.add_attack_behaviour(GRAB, 6, 97, 333, 122, 242)
AI.add_attack_behaviour(FTILT, 6, 226, 631, 102, 262)
AI.add_attack_behaviour(JAB, 8, 163, 469-200, 49, 269) // making range smaller so we don't use when it's super easy to DI out of it
AI.add_attack_behaviour(UTILT, 8, -125, 143, 371, 899)
AI.add_attack_behaviour(USMASH, 8, -363, 363, 492, 810) // first hit
AI.add_attack_behaviour(USPG, 8, 168, 515, 31, 379)
AI.add_attack_behaviour(USPG, 11, 168, 524, 1200, 1475)
AI.add_attack_behaviour(NSPG, 12, -127, 127, 95, 345)
AI.add_attack_behaviour(NSPG, 18, -637, 637, 50, 345)
AI.add_attack_behaviour(FSMASH, 24, 289, 782, 138, 318)
AI.add_attack_behaviour(DSPG, 28+6, 79, 623, 138, 318)
AI.add_custom_attack_behaviour(AI.ROUTINE.DASH_ATTACK, 7, 373, 959, 195, 323)

AI.END_ATTACKS() // end of grounded attacks

AI.add_attack_behaviour(UAIR, 6, -444, 361, 368, 634)
AI.add_attack_behaviour(DAIR, 4, -361, 315, -316, -95)
AI.add_attack_behaviour(NAIR, 6, -175, 121, -23, 351)
AI.add_attack_behaviour(NAIR, 6+4, -175, 121, -23, 351) // late hit
AI.add_attack_behaviour(NAIR, 6+8, -175, 121, -23, 351) // later hit
AI.add_attack_behaviour(USPA, 7, 241, 441, -9, 419)
AI.add_attack_behaviour(USPA, 10, 241, 524, 1200, 1475)
AI.add_custom_attack_behaviour(AI.ROUTINE.BAIR, 7, -444, -112, 21, 343) // first hit
AI.add_custom_attack_behaviour(AI.ROUTINE.FAIR, 9, 213, 561, -60, 288) // first hit
AI.add_attack_behaviour(NSPA, 12, -127, 127, 95, 345)
AI.add_attack_behaviour(NSPA, 18, -637, 637, 50, 472)
AI.add_custom_attack_behaviour(AI.ROUTINE.FAIR, 15, 72, 520, 27, 247) // last hit
AI.add_custom_attack_behaviour(AI.ROUTINE.BAIR, 20, -474, -90, 72, 292) // last hit
AI.add_attack_behaviour(DSPA, 28+6, 79, 623, 138, 318)

AI.END_ATTACKS() // end of aerial attacks
OS.align(16)

// Set CPU behaviour
Character.table_patch_start(ai_behaviour, Character.id.METAKNIGHT, 0x4)
dw CPU_ATTACKS
OS.patch_end()