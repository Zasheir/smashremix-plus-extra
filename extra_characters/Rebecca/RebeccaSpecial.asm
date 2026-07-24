// RebeccaSpecial.asm

// This file contains subroutines used by Rebecca's special moves.

scope RebeccaNSP: {
    // @ Description
    // Main subroutine for Rebecca's neutral special.
    // Peppy code, slightly adjusted.
    // a0 = player object
    scope main_: {
        addiu   sp, sp,-0x0040              // allocate stack space
        sw      ra, 0x0014(sp)              // 0x0014(sp) = ra
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player object
        addu    a2, a0, r0                  // a2 = player object
        lw      v0, 0x0084(a0)              // v0 = player struct

        lw      t6, 0x017C(v0)              // t6 = temp variable 1
        beqzl   t6, _idle_check + 4         // skip if temp variable 1 = 0
        mtc1    r0, f6                      // ~
        sw      r0, 0x017C(v0)              // reset temp variable 1 to 0

        // if we're here, then temp variable 1 was enabled, so create a projectile
        lui     at, 0x4270
        sw      at, 0x0020(sp)              // x offset = ^
        sw      r0, 0x0024(sp)              // y offset = 0
        sw      r0, 0x0028(sp)              // z offset = 0

        addiu   a1, sp, 0x0020              // a1 = address to return x/y/z coordinates to
        lw      a0, 0x092C(v0)              // a0 = part weapon struct
        jal     0x800EDF24                  // returns x/y/z coordinates of the part in a0 to a1
        sw      v0, 0x002C(sp)              // 0x002C(sp) = player struct

        sw      r0, 0x0028(sp)              // set z coordinate to 0
        lw      v0, 0x002C(sp)              // v0 = player struct
        lw      a0, 0x0034(sp)              // a0 = player object
        jal     laser_stage_setting_        // INITIATE Laser
        addiu   a1, sp, 0x0020              // a1 = coordinates to create projectile at
        lw      a0, 0x0034(sp)              // a0 = player object

        // checks the current animation frame to see if we've reached end of the animation
        _idle_check:
        mtc1    r0, f6                      // ~
        lwc1    f8, 0x0078(a0)              // ~
        c.le.s  f8, f6                      // ~
        nop
        bc1fl   _end                        // skip if animation end has not been reached
        nop
        jal     0x800DEE54                  // transition to idle
        sw      r0, 0x017C(v0)              // reset temp variable 1 to 0

        _end:
        lw      ra, 0x0014(sp)              // load ra
        jr      ra
        addiu   sp, sp, 0x0040              // deallocate stack space
    }

    // @ Description
    // Initial subroutine for Rebecca's laser.
    // Peppy code, slightly adjusted.
    scope laser_stage_setting_: {
        addiu   sp, sp,-0x0030              // allocate stack space
        sw      a1, 0x0024(sp)              // ~
        sw      ra, 0x0014(sp)              // store ra, a1
        li      a1, projectile_struct       // a1 = projectile struct
        lw		a2, 0x0024(sp)              // a2 = create coordinates
        jal     0x801655C8                  // general projectile creation
        lui     a3, 0x8000                  // a3 = 0x80000000
        beq     v0, r0, _end_stage_setting  // if 801655C8 returns 0, there's no space to create a new projectile object, so skip to end
        nop

        lw      v1, 0x0084(v0)              // v0 = projectile special struct
        lui     at, 0x4320                  // ~
        mtc1    at, f8                      // projectile speed = 160
        lwc1    f12, 0x0024(v1)             // f12 = y speed? argument for 0x8001863C?
        lwc1    f6, 0x0018(v1)              // ~
        cvt.s.w f6, f6                      // v0 = DIRECTION
        mul.s   f14, f6, f8                 // f14 = speed * DIRECTION
        swc1    f14, 0x0020(v1)             // store projectile speed
        jal     0x8001863C                  // unknown subroutine
        sw      v0, 0x0018(sp)              // 0x0018(sp) = projectile object
        lw      t7, 0x0018(sp)              // t7 = projectile object
        lw      t8, 0x0074(t7)              // t8 = projectile first part struct
        swc1    f0, 0x0038(t8)              // update projectile rotation (returned by 0x8001863C)
        jal     PeppyNSP.create_orange_blast_gfx_  // create orange blast gfx
        lw      a0, 0x0024(sp)              // a0 = creation coordinates
        lw      v0, 0x0018(sp)              // v0 = projectile object

        _end_stage_setting:
        lw      ra, 0x0014(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0030              // deallocate stack space
    }

    // @ Description
    // Projectile struct for Rebecca's laser.
    OS.align(16)
    projectile_struct:
    dw 0x00000000                           // unknown
    dw 0x00000001                           // projectile id
    dw Character.REBECCA_file_6_ptr         // address of Rebecca's file 6 pointer
    dw 0x00000000                           // offset to hitbox
    dw 0x1C000000                           // This determines z axis rotation? (samus is 1246)
    dw 0x801688D0                           // This is the main subroutine for the projectile, handles duration and other things. (default 0x80168540) (samus 0x80168F98)
    dw PeppyNSP.blaster_projectile_collision_check_  // This function runs when the projectile collides with clipping. (0x801685F0 - Mario) (0x80169108 - Samus)
    dw PeppyNSP.blaster_projectile_collision         // This function runs when the projectile collides with a hurtbox.
    dw PeppyNSP.blaster_projectile_collision         // This function runs when the projectile collides with a shield.
    dw PeppyNSP.blaster_projectile_collision_2       // This function runs when the projectile collides with edges of a shield and bounces off
    dw PeppyNSP.blaster_projectile_collision         // This function runs when the projectile collides/clangs with a hitbox.
    dw 0x80168A14                           // This function runs when the projectile collides with Fox's reflector (default 0x80168748)
    dw PeppyNSP.blaster_projectile_collision // This function runs when the projectile collides with Ness's psi magnet// absorb routine
    OS.copy_segment(0x103904, 0x0C)         // empty
}

scope RebeccaUSP {
    constant X_SPEED(0x435c)                // current setting - float:100.0
    constant Y_SPEED(0x42f0)                // current setting - float:40.0
    constant LANDING_FSM(0x3E80)            // current setting - float:0.25
    constant Y_INPUT(0x3f4c)                // current setting - float:0.5
    constant B_PRESSED(0x40)                // bitmask for b press


    // @ Description
    // Subroutine which runs when Rebecca initiates an up special (both ground).
    // Changes action, and sets up initial variable values.
    scope initial_ground: {
        addiu   sp, sp, 0xFFE0              // ~
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // original lines 1-3
        lw      a0, 0x0084(a0)              // a0 = player struct
        lw      t7, 0x014C(a0)              // t7 = kinetic state
        bnez    t7, _change_action          // skip if kinetic state !grounded
        nop
        jal     0x800DEEC8                  // set aerial state
        nop
        _change_action:
        lw      a0, 0x0020(sp)              // a0 = entity struct?
        sw      r0, 0x0010(sp)              // store r0 (some kind of parameter for change action)
        ori     a1, r0, 0x00E4              // a1 = 0xE4
        or      a2, r0, r0                  // a2 = float: 0.0
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3 = float: 1.0
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        ori     v1, r0, 0x0001              // ~
        sw      v1, 0x0184(a0)              // temp variable 3 = 0x1(BEGIN)
        // reset fall speed
        lbu     v1, 0x018D(a0)              // v1 = fast fall flag
        ori     t6, r0, 0x0007              // t6 = bitmask (01111111)
        and     v1, v1, t6                  // ~
        sb      v1, 0x018D(a0)              // disable fast fall flag
        // freeze y position
        lw      v1, 0x09C8(a0)              // v1 = attribute pointer
        lw      v1, 0x0058(v1)              // v1 = gravity
        sw      v1, 0x004C(a0)              // y velocity = gravity
        lw      ra, 0x001C(sp)              // ~
        addiu   sp, sp, 0x0020              // ~
        jr      ra                          // original return logic
        nop
    }

    // @ Description
    // Subroutine which runs when Rebecca initiates an up special (both ground).
    // Changes action, and sets up initial variable values.
    scope initial_air: {
        addiu   sp, sp, 0xFFE0              // ~
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // original lines 1-3
        lw      a0, 0x0084(a0)              // a0 = player struct
        lw      t7, 0x014C(a0)              // t7 = kinetic state
        bnez    t7, _change_action          // skip if kinetic state !grounded
        nop
        jal     0x800DEEC8                  // set aerial state
        nop
        _change_action:
        lw      a0, 0x0020(sp)              // a0 = entity struct?
        sw      r0, 0x0010(sp)              // store r0 (some kind of parameter for change action)
        ori     a1, r0, 0x00E3              // a1 = 0xE3
        or      a2, r0, r0                  // a2 = float: 0.0
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3 = float: 1.0
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        ori     v1, r0, 0x0001              // ~
        sw      v1, 0x0184(a0)              // temp variable 3 = 0x1(BEGIN)
        // reset fall speed
        lbu     v1, 0x018D(a0)              // v1 = fast fall flag
        ori     t6, r0, 0x0007              // t6 = bitmask (01111111)
        and     v1, v1, t6                  // ~
        sb      v1, 0x018D(a0)              // disable fast fall flag
        // freeze y position
        lw      v1, 0x09C8(a0)              // v1 = attribute pointer
        lw      v1, 0x0058(v1)              // v1 = gravity
        sw      v1, 0x004C(a0)              // y velocity = gravity
        lw      ra, 0x001C(sp)              // ~
        addiu   sp, sp, 0x0020              // ~
        jr      ra                          // original return logic
        nop
    }

    // @ Description
    // Holds each player's button presses from the previous frame.
    // Used to add a single frame input buffer to shorten.
    button_press_buffer:
    db 0x00 //p1
    db 0x00 //p2
    db 0x00 //p3
    db 0x00 //p4

    // @ Description
    // Main Subroutine which runs when Rebecca initiates an up special (both ground and air) based on 8015BD24.
    // Deals with transition to part 2 of action and thereby, shortening.
    scope main_ground: {
        addiu   sp, sp, -0x0020              // ~
        sw      ra, 0x0014(sp)              // ~

        _update_buffer:
        lbu     t1, 0x000D(a2)              // t1 = player port
        li      t2, button_press_buffer     // ~
        addu    t3, t2, t1                  // t3 = px button_press_buffer address
        lbu     t1, 0x01BE(a2)              // t1 = button_pressed
        lbu     t2, 0x0000(t3)              // t2 = button_press_buffer
        sb      t1, 0x0000(t3)              // update button_press_buffer with current inputs
        or      t3, t1, t2                  // t3 = button_pressed | button_press_buffer
        sw      t3, 0x0018(sp)              // save button_pressed to stack

        li      a1, usp_2_transition_ground
        jal     0x800D9480
        nop



        lui     at, 0x4190                  // at = 18.0
        mtc1    at, f6                      // ~
        lwc1    f8, 0x0078(a0)              // ~
        c.le.s  f8, f6                      // ~
        nop
        bc1tl   _end                        // skip if haven't reached frame 18
        nop

        lw      t3, 0x0018(sp)              // load button press buffer
        andi    t1, t3, B_PRESSED           // t1 = 0x40 if (B_PRESSED); else t1 = 0
        beq     t1, r0, _end                // skip if (!B_PRESSED)
        nop
        //lh      t8, 0x01BE(a2)              // t8 buttons_pressed
        //andi    t8, t8, Joypad.B            // t8 = 0x0040 if (B_PRESSED); else t8 = 0
        //beqz    t8, _end                  // skip if (!B_PRESSED)
        //nop
        jal     usp_2_transition_ground
        nop

        _end:
        lw      ra, 0x0014(sp)              // ~
        addiu   sp, sp, 0x0020              // ~
        jr      ra                          // original return logic
        nop
    }

    // @ Description
    // Main Subroutine which runs when Rebecca initiates an up special (both ground and air) based on 8015BD24.
    // Deals with transition to part 2 of action and thereby, shortening.
    scope main_air: {
        addiu   sp, sp, -0x0020             // ~
        sw      ra, 0x0014(sp)              // ~

        _update_buffer:
        lbu     t1, 0x000D(a2)              // t1 = player port
        li      t2, button_press_buffer     // ~
        addu    t3, t2, t1                  // t3 = px button_press_buffer address
        lbu     t1, 0x01BE(a2)              // t1 = button_pressed
        lbu     t2, 0x0000(t3)              // t2 = button_press_buffer
        sb      t1, 0x0000(t3)              // update button_press_buffer with current inputs
        or      t3, t1, t2                  // t3 = button_pressed | button_press_buffer
        sw      t3, 0x0018(sp)              // save button_pressed to stack

        li      a1, usp_2_transition_air
        jal     0x800D9480
        nop

        lui     at, 0x4190                  // at = 18.0
        mtc1    at, f6                      // ~
        lwc1    f8, 0x0078(a0)              // ~
        c.le.s  f8, f6                      // ~
        nop
        bc1tl   _end                        // skip if haven't reached frame 18
        nop

        lw      t3, 0x0018(sp)              // load button press buffer
        andi    t1, t3, B_PRESSED           // t1 = 0x40 if (B_PRESSED); else t1 = 0
        beq     t1, r0, _end                // skip if (!B_PRESSED)
        nop

        //lh      t8, 0x01BE(a2)              // t8 buttons_pressed
        //andi    t8, t8, Joypad.B            // t8 = 0x0040 if (B_PRESSED); else t8 = 0
        //beqz    t8, _end                  // skip if (!B_PRESSED)
        //nop

        jal     usp_2_transition_air
        nop

        _end:
        lw      ra, 0x0014(sp)              // ~
        addiu   sp, sp, 0x0020              // ~
        jr      ra                          // original return logic
        nop
    }

    // @ Description
    // Main Subroutine which runs when Rebecca initiates an up special (both ground and air) based on 8015C750.
    // Deals with transition to part 2 of action and thereby, shortening.
    scope usp_2_transition_ground: {
        addiu   sp, sp, -0x0020              // ~
        sw      ra, 0x001C(sp)              // ~
        addiu   t6, r0, 0x0003
        sw      a0, 0x0020(sp)
        sw      t6, 0x0010(sp)
        addiu   a1, r0, 0x00E8              // insert action in a1
        addiu   a2, r0, 0x0000
        jal     0x800E6F24                  // change action routine
        lui     a3, 0x3f80
        jal     0x800E0830
        lw      a0, 0x0020(sp)
        jal     0x8015BFBC
        lw      a0, 0x0020(sp)



        lw      ra, 0x001C(sp)              // ~
        addiu   sp, sp, 0x0020              // ~
        jr      ra                          // original return logic
        nop
    }

    // @ Description
    // Main Subroutine which runs when Rebecca initiates an up special (both ground and air) based on 8015C750.
    // Deals with transition to part 2 of action and thereby, shortening.
    scope usp_2_transition_air: {
        addiu   sp, sp, -0x0020              // ~
        sw      ra, 0x001C(sp)              // ~
        addiu   t6, r0, 0x0003
        sw      a0, 0x0020(sp)
        sw      t6, 0x0010(sp)
        addiu   a1, r0, 0x00E6              // insert action in a1
        addiu   a2, r0, 0x0000
        jal     0x800E6F24                  // change action routine
        lui     a3, 0x3f80
        jal     0x800E0830
        lw      a0, 0x0020(sp)
        jal     0x8015BFBC
        lw      a0, 0x0020(sp)



        lw      ra, 0x001C(sp)              // ~
        addiu   sp, sp, 0x0020              // ~
        jr      ra                          // original return logic
        nop
    }

    // @ Description
    // Subroutine which allows a direction change for Rebecca's up special.
    // Uses the moveset data command 580000XX (orignally identified as "set flag" by toomai)
    // This command's purpose appears to be setting a temporary variable in the player struct.
    // Variable values used by this subroutine:
    // 0x2 = change direction
    scope change_direction_: {
        // 0x180 in player struct = temp variable 2
        lw      a1, 0x0084(a0)              // a1 = player struct
        addiu   sp, sp,-0x0010              // allocate stack space
        sw      t0, 0x0004(sp)              // ~
        sw      t1, 0x0008(sp)              // ~
        sw      ra, 0x000C(sp)              // store t0, t1, ra
        lw      t0, 0x0180(a1)              // t0 = temp variable 2
        ori     t1, r0, 0x0002              // t1 = 0x2
        bne     t1, t0, _end                // skip if temp variable 2 != 2
        nop
        jal     0x80160370                  // turn subroutine (copied from captain falcon)
        nop
        _end:
        lw      t0, 0x0004(sp)              // ~
        lw      t1, 0x0008(sp)              // ~
        lw      ra, 0x000C(sp)              // load t0, t1, ra
        addiu   sp, sp, 0x0010              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles movement for Rebecca's up special.
    // Uses the moveset data command 5C0000XX (orignally identified as "apply throw?" by toomai)
    // This command's purpose appears to be setting a temporary variable in the player struct.
    // The most common use of this variable is to determine when a throw should be applied.
    // Variable values used by this subroutine:
    // 0x1 = begin
    // 0x2 = begin movement
    // 0x3 = movement
    // 0x4 = end movement?
    scope physics_: {
        // s0 = player struct
        // s1 = attributes pointer
        // 0x184 in player struct = temp variable 3
        constant BEGIN(0x1)
        constant BEGIN_MOVE(0x2)
        constant MOVE(0x3)
        constant END_MOVE(0x4)
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      s0, 0x0014(sp)              // ~
        sw      s1, 0x0018(sp)              // original store registers
        sw      t0, 0x0024(sp)              // ~
        sw      t1, 0x0028(sp)              // ~
        swc1    f0, 0x002C(sp)              // ~
        swc1    f2, 0x0030(sp)              // ~
        swc1    f4, 0x0034(sp)              // store t0, t1, f0, f2, f4

        OS.copy_segment(0x548F0, 0x40)      // copy from original air physics subroutine
        bnez    v0, _check_begin            // modified original branch
        nop
        li      t8, 0x800D8FA8              // t8 = subroutine which disallows air control
        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        ori     t1, r0, BEGIN               // t1 = BEGIN
        beq     t0, t1, _continue           // branch if temp variable 3 = BEGIN
        nop
        li      t8, air_control_            // t8 = air_control_

        _continue:
        or      a0, s0, r0                  // a0 = player struct
        jalr    t8                          // air control subroutine
        or      a1, s1, r0                  // a1 = attributes pointer
        or      a0, s0, r0                  // a0 = player struct
        jal     0x800D9074                  // air friction subroutine?
        or      a1, s1, r0                  // a1 = attributes pointer

        _check_begin:
        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        ori     t1, r0, BEGIN               // t1 = BEGIN
        bne     t0, t1, _check_begin_move   // skip if temp variable 3 != BEGIN
        nop
        // slow x movement
        //lwc1    f0, 0x0048(s0)              // f0 = current x velocity
        //lui     t0, 0x3F60                  // ~
        //mtc1    t0, f2                      // f2 = 0.875
        //mul.s   f0, f0, f2                  // f0 = x velocity * 0.875
        //swc1    f0, 0x0048(s0)              // x velocity = (x velocity * 0.875)
        // freeze x position
        sw      r0, 0x0048(s0)              // y velocity = 0
        // freeze y position
        sw      r0, 0x004C(s0)              // y velocity = 0

        _check_begin_move:

        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        ori     t1, r0, BEGIN_MOVE          // t1 = BEGIN_MOVE
        bne     t0, t1, _check_move         // skip if temp variable 3 != BEGIN_MOVE
        nop
        // initialize x/y velocity
        lui     t0, X_SPEED                 // ~
        mtc1    t0, f4                      // f4 = X_SPEED
        lwc1    f0, 0x0044(s0)              // ~
        cvt.s.w f0, f0                      // f0 = direction
        lb      t0, 0x01C3(s0)              // ~
        mtc1    t0, f0                      // ~
        cvt.s.w f0, f0                      // f0 = stick_y
        mtc1    r0, f2                      // f2 = 0
        lui     t0, Y_SPEED                 // load default y speed
        //c.le.s  f2, f0                      // ~
        //nop                                 // ~
        //bc1f    _apply_movement             // branch if stick_y  =< 0
        mtc1    t0, f2                      // put default y speed into f2

        // update y velocity based on stick_y
        // f0 = stick_y
        lui     t0, Y_INPUT                 // ~
        mtc1    t0, f6                      // f4 = 0.4
        mul.s   f6, f0, f6                  // f4 = y velocity input(stick_y * 0.5)
        add.s   f2, f2, f6                  // f2 = y velocity (default y velocity + y velocity input)
        // update x velocity based on y velocity (higher y = lower x)
        lui     t0, 0x3E60                  // ~
        mtc1    t0, f0                      // f0 = 0.21875
        mul.s   f0, f0, f2                  // ~
        sub.s   f4, f4, f0                  // f4 = X_SPEED - (y velocity * 0.21875)

        _apply_movement:
        // f2 = x velocity
        // f4 = y velocity
        lwc1    f0, 0x0044(s0)              // ~
        cvt.s.w f0, f0                      // f0 = direction
        mul.s   f4, f0, f4                  // f2 = x velocity * direction
        swc1    f2, 0x004C(s0)              // store y velocity
        swc1    f4, 0x0048(s0)              // store x velocity
        ori     t0, r0, MOVE                // t0 = MOVE
        sw      t0, 0x0184(s0)              // temp variable 3 = MOVE
        // take mid-air jumps away at this point
        lw      t0, 0x09C8(s0)              // t0 = attribute pointer
        lw      t0, 0x0064(t0)              // t0 = max jumps
        sb      t0, 0x0148(s0)              // jumps used = max jumps
        b       _end                        // end
        nop


        _check_move:
        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        ori     t1, r0, MOVE                // t1 = MOVE
        bne     t0, t1, _check_end_move     // skip if temp variable 3 != MOVE
        nop
        // update y velocity to negate gravity
        lwc1    f0, 0x0058(s1)              // f0 = gravity
        lwc1    f2, 0x004C(s0)              // f2 = y velocity
        add.s   f2, f2, f0                  // f2 = y velocity + GRAVITY
        swc1    f2, 0x004C(s0)              // store updated y velocity

        _check_end_move:
        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        ori     t1, r0, END_MOVE            // t1 = END_MOVE
        bne     t0, t1, _end                // skip if temp variable 3 != END_MOVE
        nop

        lw      t1, 0x0A88(s0)              // t1 = overlay settings
        li      t0, 0x7FFFFFFF              // t2 = bitmask
        and     t1, t1, t0                  // ~
        sw      t1, 0x0A88(s0)              // disable colour overlay bit

        // slow x movement
        lwc1    f0, 0x0048(s0)              // f0 = current x velocity
        lui     t0, 0x3F60                  // ~
        mtc1    t0, f2                      // f2 = 0.875
        mul.s   f0, f0, f2                  // f0 = x velocity * 0.875
        swc1    f0, 0x0048(s0)              // x velocity = (x velocity * 0.875)
        //sw        r0, 0x0048(s0)              // x velocity = (x velocity * 0.875)
        // freeze y position
        lwc1    f0, 0x004C(s0)              // f0 = current y velocity
        mul.s   f0, f0, f2                  // f0 = y velocity * 0.875
        swc1    f0, 0x004C(s0)              // y velocity = (y velocity * 0.875)
        //lw      t1, 0x09C8(s0)              // t1 = attribute pointer
       // lw      t1, 0x0058(t1)              // t1 = fall speed acceleration
        //sw      t1, 0x004C(s0)              // overwrite y velocity with fall speed acceleration value
        //sw      r0, 0x004C(s0)              // y velocity = 0
        OS.copy_segment(0x548F4, 0x58)      // AT 0X800d90f0

        _end:
        lw      t0, 0x0024(sp)              // ~
        lw      t1, 0x0028(sp)              // ~
        lwc1    f0, 0x002C(sp)              // ~
        lwc1    f2, 0x0030(sp)              // ~
        lwc1    f4, 0x0034(sp)              // load t0, t1, f0, f2, f4
        lw      ra, 0x001C(sp)              // ~
        lw      s0, 0x0014(sp)              // ~
        lw      s1, 0x0018(sp)              // original load registers
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles Rebecca's horizontal control for up special.
    scope air_control_: {
        addiu   sp, sp,-0x0028              // allocate stack space
        sw      a1, 0x001C(sp)              // ~
        sw      ra, 0x0014(sp)              // ~
        sw      t0, 0x0020(sp)              // ~
        sw      t1, 0x0024(sp)              // store a1, ra, t0, t1
        addiu   a1, r0, 0x0008              // a1 = 0x8 (original line)
        lw      t6, 0x001C(sp)              // t6 = attribute pointer
        lw      a2, 0x004C(t6)              // a2 = air acceleration
        lw      a3, 0x0050(t6)              // a3 = max air speed
        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        _check_move:
        ori     t1, r0, physics_.MOVE       // t1 = MOVE
        beql    t0, t1, _continue           // branch if temp variable 3 = MOVE
        lui     a2, 0x3CC0                  // on branch, a2 = 0.0234375
        _check_end_move:
        ori     t1, r0, physics_.END_MOVE   // t1 = END_MOVE
        beql    t0, t1, _continue           // branch if temp variable 3 = END_MOVE
        lui     a2, 0x3C00                  // on branch, a2 = 0.0078125

        _continue:
        jal     0x800D8FC8                  // air drift subroutine?
        nop
        lw      ra, 0x0014(sp)              // ~
        lw      t0, 0x0020(sp)              // ~
        lw      t1, 0x0024(sp)              // load ra, t0, t1
        addiu   sp, sp, 0x0028              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles collision for Rebecca's up special.
    // Copy of subroutine 0x80156358, which is the collision subroutine for Mario's up special.
    // Loads the appropriate landing fsm value for Rebecca.
    scope collision_: {
        // Copy the first 30 lines of subroutine 0x80156358
        OS.copy_segment(0xD0D98, 0x78)
        // Replace original line which loads the landing fsm
        //lui     a2, 0x3E8F                // original line 1
        lui     a2, LANDING_FSM             // a2 = LANDING_FSM
        // Copy the last 17 lines of subroutine 0x80156358
        OS.copy_segment(0xD0E14, 0x44)
    }

    // @ Description
    // Main subroutine for Rebecca's up special part 2.
    // Based on subroutine 0x8015C750, which is the main subroutine of Fox's up special ending.
    // Modified to load Rebecca's landing FSM value and disable the interrupt flag.
    scope main_2: {
        // Copied the first 8 lines of subroutine 0x8015C750
        addiu   sp, sp, -0x0038
        sw      ra, 0x0024(sp)
        sw      v1, 0x0028(sp)
        sw      a0, 0x002C(sp)

        //jal     _Rebecca_slash_graphics
        addu    v1, r0, a2                  // load player struct into v1
        lw      v1, 0x0028(sp)
        lw      a0, 0x002C(sp)

        idle_transition:
        lwc1    f6, 0x0078(a0)
        mtc1    r0, f4
        lui     a1, 0x3f80
        or      a2, r0, r0
        c.le.s  f6, f4
        addiu   a3, r0, 0x0001
        bc1fl   _end                        // skip if animation end has not been reached
        lw      ra, 0x0024(sp)              // restore ra
        sw      r0, 0x0010(sp)              // unknown argument = 0
        sw      t6, 0x0018(sp)              // interrupt flag saved

        lui     t6, LANDING_FSM             // t6 = LANDING_FSM
        lw      a0, 0x002C(sp)
        jal     0x801438F0                  // begin special fall
        sw      t6, 0x0014(sp)              // store LANDING_FSM
        lw      ra, 0x0024(sp)              // restore ra

        _end:
        lw      v1, 0x0028(sp)
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop

        //_Rebecca_slash_graphics:
        //addiu   sp, sp, -0x0028
        //sw      ra, 0x0014(sp)
        //sw      v1, 0x0020(sp)
        //sw      a0, 0x0024(sp)
        //lw      a0, 0x0004(v1)
        //lw      t6, 0x017C(v1)              // load moveset variable
        //bnez    t6, skip_graphics           // don't redo graphics routine after completion
        //nop

        jal     PokemonAnnouncer.slash_announcement_
        nop

        //jal     0x80101F84                  // falcon punch animation struct routine
        //sw      v1, 0x0020(sp)              // save player struct
        //lw      v1, 0x0020(sp)              // load player struct
        //lbu     t1, 0x018F(v1)
        //ori     t2, t1, 0x0010
        //sb      t2, 0x018F(v1)
        //addiu   t1, r0, 0x0001
        //sb      t1, 0x017C(v1)

        //skip_graphics:
        //lw      v1, 0x0020(sp)              // load player struct
        //addiu   t0, r0, 0x0002
        //bne     t6, t0, _end_graphics
        //nop

        //jal     0x800E9C3C                  // routine that ends graphics
        //nop

        //_end_graphics:
        //lw      a0, 0x0024(sp)
        //lw      ra, 0x0014(sp)
        //addiu   sp, sp, 0x0028
        //jr      ra
        //nop
    }


    }