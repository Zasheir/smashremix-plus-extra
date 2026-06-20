// @ Description
// This establishes Emerald Coast hazard object for water
scope setup: {
    addiu   sp, sp,-0x0060              // allocate stack space
    sw      ra, 0x0024(sp)              // ~
    sw      s0, 0x0028(sp)              // store ra, s0

    // _check_hazard:
    li      t0, Toggles.entry_hazard_mode
    lw      t0, 0x0004(t0)              // t0 = hazard_mode (hazards disabled when t0 = 1 or 3)
    andi    t0, t0, 0x0001              // t0 = 1 if hazard_mode is 1 or 3, 0 otherwise
    bnez    t0, _end                    // if hazard_mode enabled, skip original
    nop

    li      s0, 0x801313F0              // load hardcoded space used by hazards, generally for pointers
    sw      r0, 0x0060(s0)              // clear under_water flags and frenzy turns

    sw      s0, 0x0020(sp)              // hardcoded space used by hazards, generally for pointers

    li      a1, water_                  // emerald coast water routine
    addiu   a2, r0, 0x0001              // group
    addiu   a0, r0, 0x03F2              // object id

    jal     Render.CREATE_OBJECT_       // create object
    lui     a3, 0x8000                  // unknown

    sw      v0, 0x0050(sp)              // save object address
    addiu   t6, r0, 0xFFFF
    or      s0, v0, r0
    sw      t6, 0x0010(sp)
    or      a0, v0, r0
    lw      a1, 0x0030(sp)
    addiu   a2, r0, 0x0004

    lui     t7, 0x8013
    lw      t7, 0x13F0(t7)
    lw      t8, 0x0028(sp)
    or      a0, s0, r0
    or      a2, r0, r0
    addiu   a3, r0, 0x001C
    sw      r0, 0x0010(sp)
    sw      r0, 0x0014(sp)

    _end:
    lw      ra, 0x0024(sp)              // ~
    lw      s0, 0x0028(sp)              // load ra, s0
    jr      ra                          // return
    addiu   sp, sp, 0x0060              // deallocate stack space
}

// @ Description
// Main function for Emerald Coast's water. Based on Pirate Land's water.
scope water_: {
    constant WATER_Y(0xC4898000)        // current setting - float: -1100
    constant SPLASH_Y(0xC47A0000)       // current setting - float: -1000

    addiu   sp, sp, -0x0050             // allocate stack space
    sw      ra, 0x0024(sp)              // ~
    sw      s0, 0x0028(sp)              // ~
    sw      s1, 0x002C(sp)              // store ra, s0, s1
    or      s0, r0, r0                  // current port = 0
    lli     s1, 0x0003                  // final iteration = 0x3

    _loop:
    jal     Character.port_to_struct_   // v0 = player struct for current port
    or      a0, s0, r0                  // a0 = current port
    beqz    v0, _loop_end               // skip if no struct found for current port
    nop

    // if the player is present
    sw      v0, 0x003C(sp)              // 0x003C(sp) = px struct

    lw      t6, 0x0008(v0)              // t6 = character id
    lli     at, Character.id.FOX        // at = id.FOX
    beq     at, t6, _fire_fox_check     // perform action check if character = FOX
    lli     at, Character.id.JFOX       // at = id.JFOX
    beq     at, t6, _fire_fox_check     // perform action check if character = FOX
    lli     at, Character.id.FALCO      // at = id.FALCO
    bne     at, t6, _check_intro        // skip action check if character != FALCO

    _fire_fox_check:
    lw      t6, 0x0024(v0)              // t6 = action id
    lli     at, Action.FOX.FireFoxAir   // same as FALCO.Action.FireBirdAir
    beq     t6, at, _loop_end           // skip if Fox/Falco are doing their up special
    nop

    _check_intro:
    li      t6, Global.current_screen   // ~
    lbu     t6, 0x0000(t6)              // t6 = screen_id
    ori     at, r0, 0x0036              // ~
    beq     at, t6, _check_y            // skip if screen_id = training mode
    nop

    li      t6, Global.match_info       // ~
    lw      t6, 0x0000(t6)              // t6 = match info struct
    lw      t6, 0x0018(t6)              // t6 = time elapsed
    beqz    t6, _loop_end               // skip if time elapsed = 0
    nop

    _check_y:
    lw      v0, 0x0078(v0)              // v0 = px x/y/z coordinates
    li      t8, 0x801313F0              // t8 = stage data
    addu    t8, t8, s0                  // t8 = stage data + port offset
    lwc1    f2, 0x0004(v0)              // f2 = px y position
    li      at, WATER_Y                 // ~
    mtc1    at, f4                      // f4 = WATER_Y
    c.le.s  f2, f4                      // compare player location to beginning of water
    nop
    bc1fl   _loop_end                   // skip if player is above water...
    sb      r0, 0x005C(t8)              // ...and set px_under_water to FALSE

    lbu     t0, 0x005C(t8)              // t0 = px_under_water
    bnez    t0, _water_physics          // branch if px_under_water != FALSE
    lli     at, OS.TRUE                 // ~

    // if the player has just gone under the water
    sb      at, 0x005C(t8)              // px_under_water = TRUE
    lw      at, 0x0000(v0)              // at = px x
    sw      at, 0x0030(sp)              // 0x0030(sp) = px x
    li      at, SPLASH_Y                // ~
    sw      at, 0x0034(sp)              // 0x0034(sp) = SPLASH_Y
    sw      r0, 0x0038(sp)              // 0x0038(sp) = 0
    addiu   a0, sp, 0x0030              // a0 = coordinates to create gfx at
    jal     0x801001A8                  // create "splash" gfx
    addiu   a1, r0, 0x0001              // a1 = 1
    addiu   a0, sp, 0x0030              // a0 = coordinates to create gfx at
    jal     0x801001A8                  // create "splash" gfx
    addiu   a1, r0,-0x0001              // a1 = -1
    jal     0x800269C0                  // play fgm
    addiu   a0, r0, 0x03D1              // fgm id = 0x3D1 (Splash)

    _water_physics:
    lw      v0, 0x003C(sp)              // v0 = px struct
    lbu     at, 0x018D(v0)              // at = bit field
    andi    at, at, 0x0007              // at = bit field & mask(0b01111111), this disables the fast fall flag
    sb      at, 0x018D(v0)              // store updated bit field
    lui     at, 0xC1A0                  // ~
    mtc1    at, f2                      // f2 = -20.0
    lui     at, 0x3F70                  // ~
    mtc1    at, f4                      // f4 = 0.9375
    lui     at, 0x3F60                  // ~
    mtc1    at, f6                      // f6 = 0.875
    lwc1    f8, 0x0048(v0)              // f8 = x velocity
    lwc1    f10, 0x004C(v0)             // f10 = y velocity
    mul.s   f8, f8, f4                  // f8 = x velocity * 0.9375
    mul.s   f10, f10, f6                // f10 = y velocity * 0.875
    c.le.s  f2, f10                     // ~
    swc1    f8, 0x0048(v0)              // store updated x velocity

    // Check for Knuckles
    lw      t0, 0x24(v0)                // Load action ID

    if {defined Character.CHARACTER_ADDED_KNUCKLES} {
        lli     at, Knuckles.Action.GlideTurn // ~
        beql    at, t0, _apply_glide    // ~
        nop                             // ~
    }

    if {defined Character.CHARACTER_ADDED_MKNUCKLES} {
        lli     at, MKnuckles.Action.GlideTurn // ~
        beql    at, t0, _apply_glide    // ~
        nop                             // ~
    }

    if {defined Character.CHARACTER_ADDED_CBKNUCKLES} {
        lli     at, CBKnuckles.Action.GlideTurn // ~
        beql    at, t0, _apply_glide    // ~
        nop                             // ~
    }

    if {defined Character.CHARACTER_ADDED_CBMKNUCKLES} {
        lli     at, CBMKnuckles.Action.GlideTurn // ~
        beql    at, t0, _apply_glide    // ~
        nop                             // ~
    }

    b       _water_continue             // branch if not Knuckles
    nop

    _apply_glide:
    lwc1    f8, 0xB24(v0)               // Load backed up velocity for GlideTurn to return to
    mul.s   f8, f8, f4                  // *= 0.9375
    nop                                 // ~
    swc1    f8, 0xB24(v0)               // Store new backed up velocity

    _water_continue:
    bc1fl   _water_knockback            // if y velocity =< -20...
    swc1    f10, 0x004C(v0)             // ...store updated y velocity

    _water_knockback:
    lui     at, 0x3F7B                  // ~
    mtc1    at, f6                      // f6 = 0.980469
    lwc1    f8, 0x0054(v0)              // f8 = x kb velocity
    lwc1    f10, 0x0058(v0)             // f10 = y kb velocity
    mul.s   f8, f8, f6                  // f8 = x velocity * 0.980469
    mul.s   f10, f10, f6                // f10 = y velocity * 0.980469
    swc1    f8, 0x0054(v0)              // store updated kb x velocity
    swc1    f10, 0x0058(v0)             // store updated kb y velocity
    c.le.s  f2, f10                     // ~
    mul.s   f10, f10, f4                // f10 = y velocity * 0.9375
    bc1fl   _loop_end                   // if y velocity =< -20...
    swc1    f10, 0x0058(v0)             // ...store updated kb y velocity

    _loop_end:
    bne     s0, s1, _loop               // loop if final iteration has not been reached
    addiu   s0, s0, 0x0001              // iterate current port

    lw      ra, 0x0024(sp)              // ~
    lw      s0, 0x0028(sp)              // ~
    lw      s1, 0x002C(sp)              // load ra, s0, s1
    jr      ra                          // return
    addiu   sp, sp, 0x0050              // deallocate stack space
}