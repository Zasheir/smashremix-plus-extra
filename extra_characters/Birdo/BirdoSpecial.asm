// BirdoSpecial.asm

// This file contains subroutines used by Birdo's special moves.

scope BirdoUSP {
    // @ Description
    // Subroutine which runs when Birdo initiates a grounded neutral special.
    scope ground_begin_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lw      a2, 0x0084(a0)              // ~
        lw      a2, 0x0008(a2)              // a2 = current character ID
        lli     a1, Birdo.Action.USP_Ground_Begin // a1(action id) = USP_Ground_Begin
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // ~
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        sw      r0, 0x0184(a0)              // temp variable 3 = 0
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which runs when Birdo initiates an aerial neutral special.
    scope air_begin_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lw      a2, 0x0084(a0)              // ~
        lw      a2, 0x0008(a2)              // a2 = current character ID
        lli     a1, Birdo.Action.USP_Air_Begin // a1(action id) = USP_Air_Begin
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // ~
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        sw      r0, 0x0184(a0)              // temp variable 3 = 0
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which begins Birdo's grounded neutral special ending action.
    scope ground_end_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra

        lw      a2, 0x0084(a0)              // ~
        lw      a2, 0x0008(a2)              // a2 = current character ID
        lli     a1, Birdo.Action.USP_Ground_End // a1(action id) = USP_Ground_End
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which begins Birdo's aerial neural special ending action.
    scope air_end_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra

        lw      a2, 0x0084(a0)              // ~
        lw      a2, 0x0008(a2)              // a2 = current character ID
        lli     a1, Birdo.Action.USP_Air_End // a1(action id) = USP_Ground_End
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Main subroutine for USP_Ground_Begin
    // If temp variable 2 is set by moveset, cancel with USP_Ground_End when B is not held.
    scope ground_begin_main_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      v0, 0x0084(a0)              // v0 = player struct
        lw      t7, 0x0180(v0)              // t7 = temp variable 2
        beqz    t7, _check_end              // branch if temp variable 2 is not set
        lh      t7, 0x01BC(v0)              // t7 = buttons_held
        andi    t7, t7, Joypad.B            // t7 = 0x0020 if (B_HELD); else t7 = 0
        bnez    t7, _check_end              // branch if (B_HELD)
        nop

        _release:
        // if we're here then temp variable 2 is set and b is not held, so transition to ending action
        jal     ground_end_initial_         // transition to USP_Ground_End
        nop
        b       _end
        nop

        _check_end:
        mtc1    r0, f6                      // ~
        lwc1    f8, 0x0078(a0)              // ~
        c.le.s  f8, f6                      // ~
        nop
        bc1fl   _end                        // skip if animation end has not been reached
        nop
        jal     0x800DEE54                  // transition to idle
        nop

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Main subroutine for USP_Air_Begin
    // If temp variable 2 is set by moveset, cancel with USP_Ground_End when B is not held.
    scope air_begin_main_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      v0, 0x0084(a0)              // v0 = player struct
        lw      t7, 0x0180(v0)              // t7 = temp variable 2
        beqz    t7, _check_end              // branch if temp variable 2 is not set
        lh      t7, 0x01BC(v0)              // t7 = buttons_held
        andi    t7, t7, Joypad.B            // t7 = 0x0020 if (B_HELD); else t7 = 0
        bnez    t7, _check_end              // branch if (B_HELD)
        nop

        _release:
        // if we're here then temp variable 2 is set and b is not held, so transition to ending action
        jal     air_end_initial_            // transition to USP_Air_End
        nop
        b       _end
        nop

        _check_end:
        mtc1    r0, f6                      // ~
        lwc1    f8, 0x0078(a0)              // ~
        c.le.s  f8, f6                      // ~
        nop
        bc1fl   _end                        // skip if animation end has not been reached
        nop
        jal     0x800DEE54                  // transition to idle
        nop

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Main subroutine for neutral special air ending.
    // If temp variable 1 is set by moveset, create a projectile.
    // The value of temp variable 3 will be added as bonus power to the projectile.
    scope end_main_: {
        addiu   sp, sp,-0x0040              // allocate stack space
        sw      ra, 0x0014(sp)              // 0x0014(sp) = ra
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player object
        addu    a2, a0, r0                  // a2 = player object
        lw      v0, 0x0084(a0)              // v0 = player struct
        lw      t6, 0x017C(v0)              // t6 = temp variable 1
        beq     t6, r0, _idle_check         // skip if temp variable 1 = 0
        sw      r0, 0x017C(v0)              // reset temp variable 1 to 0

        // if we're here, then temp variable 1 was enabled, so create a projectile
        swc1    f0, 0x0020(sp)              // ~
        swc1    f0, 0x0024(sp)              // ~
        swc1    f0, 0x0028(sp)              // clear space used for x/y/z coordinates (probably not needed)
        addiu   a1, sp, 0x0020              // a1 = address to return x/y/z coordinates to
        lw      a0, 0x092C(v0)              // a0 = part 0xD (weapon) struct
        jal     0x800EDF24                  // returns x/y/z coordinates of the part in a0 to a1
        sw      v0, 0x002C(sp)              // 0x002C(sp) = player struct
        lwc1    f6, 0x0024(sp)              // f6 = y coordinate
        lui     t6, 0x4270                  // ~
        mtc1    t6, f8                      // f6 = 60
        add.s   f6, f6, f8                  // add 60 to y coordinate
        swc1    f6, 0x0024(sp)              // store updated y coordinate
        sw      r0, 0x0028(sp)              // set z coordinate to 0
        lw      v0, 0x002C(sp)              // v0 = player struct
        lw      a0, 0x0034(sp)              // a0 = player object
        jal     ball_stage_setting_         // INITIATE BALL
        addiu   a1, sp, 0x0020              // a1 = coordinates to create projectile at
        lw      a0, 0x0034(sp)              // a0 = player object

        _idle_check:
        // checks the current animation frame to see if we've reached end of the animation
        mtc1    r0, f6                      // ~
        lwc1    f8, 0x0078(a0)              // ~
        c.le.s  f8, f6                      // ~
        nop
        bc1fl   _end                        // skip if animation end has not been reached
        nop
        jal     0x800DEE54                  // transition to idle
        nop

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0040              // deallocate stack space
        jr      ra
        nop
    }

    // @ Description
    // Subroutine which handles ground collision for neutral special actions
    scope ground_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, ground_to_air_          // a1(transition subroutine) = ground_to_air_
        jal     0x800DDE84                  // common ground collision subroutine (transition on no floor, no slide-off)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles air collision for neutral special begin and wait
    scope air_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, air_to_ground_          // a1(transition subroutine) = air_to_ground_
        jal     0x800DE6E4                  // common air collision subroutine (transition on landing, no ledge grab)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles ground to air transition for neutral special actions
    scope ground_to_air_: {
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // store ra
        sw      a0, 0x0038(sp)              // 0x0038(sp) = player object
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800DEEC8                  // set aerial state
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player struct
        lw      v0, 0x0034(sp)              // v0 = player struct
        lw      a0, 0x0038(sp)              // a0 = player object
        lw      t7, 0x0024(v0)              // t7 = current action
        addiu   a1, t7, 0x0002              // a1 = equivalent air action for current ground action (id + 3)
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lli     t6, 0x0800                  // ~
        jal     0x800E6F24                  // change action
        sw      t6, 0x0010(sp)              // argument 4 = 0x0800 (this flag continues FGM called with the 3C command)
        jal     0x800D8EB8                  // momentum capture?
        lw      a0, 0x0034(sp)              // a0 = player struct
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles air to ground transition for begin and wait neutral special actions
    scope air_to_ground_: {
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // store ra
        sw      a0, 0x0038(sp)              // 0x0038(sp) = player object
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800DEE98                  // set grounded state
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player struct
        lw      v0, 0x0034(sp)              // v0 = player struct
        lw      a0, 0x0038(sp)              // a0 = player object
        lw      t7, 0x0024(v0)              // t7 = current action
        addiu   a1, t7,-0x0002              // a1 = equivalent ground action for current air action (id - 3)
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lli     t6, 0x0800                  // ~
        jal     0x800E6F24                  // change action
        sw      t6, 0x0010(sp)              // argument 4 = 0x0800 (this flag continues FGM called with the 3C command)
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which sets up the initial properties for the projectile.
    // TODO: this is still largely uncommented, and may contain leftover logic that isn't needed.
    scope ball_stage_setting_: {
        constant MAX_POWER(4)
        addiu   sp, sp, -0x0050
        sw      s0, 0x0018(sp)
        li      s0, ball_properties_struct   // s0 = projectile properties struct address
        sw      a1, 0x0034(sp)
        sw      ra, 0x001C(sp)
        lw      t6, 0x0084(a0)
        lw      t0, 0x0024(s0)
        lw      t1, 0x0028(s0)
        li      a1, ball_projectile_struct  // a1 = main projectile struct address
        lw      a2, 0x0034(sp)
        lui     a3, 0x8000
        sw      t6, 0x002C(sp)              // 0x002C(sp) = player struct
        jal     0x801655C8                  // This is a generic routine that does much of the work for defining all projectiles
        sw      t1, 0x000C(a1)

        beq     v0, r0, _end_stage_setting  // if 801655C8 returns 0, there's no space to create a new projectile object, so skip to end
        nop

        _projectile_branch:
        sw      v0, 0x0028(sp)              // 0x0028(sp) = projectile object
        lw      v1, 0x0084(v0)              // v1 = projectile struct
        lw      t3, 0x0000(s0)              // t3 = duration
        sw      t3, 0x0268(v1)              // store duration
        lw      t4, 0x002C(sp)              // t4 = player struct
        lw      t5, 0x014C(t4)              // t5 = kinetic state
        beq     t5, r0, _power_adjustments  // branch if kinetic state = grounded
        lwc1    f12, 0x0018(s0)             // f12 = initial angle (ground)
        lwc1    f12, 0x001C(s0)             // f12 = initial angle (air)

        _power_adjustments:
        // check power level
        lw      t6, 0x002C(sp)              // t6 = player struct
        lw      t6, 0x0184(t6)              // t6 = temp variable 3/power level (int)
        mtc1    t6, f8                      // ~
        cvt.s.w f8, f8                      // f8 = power level (float)
        swc1    f8, 0x01B4(v1)              // 0x01B4 in projectile struct = power level (float)
        beqz    t6, _ball_drop              // branch if power level = 0 (ball drop)
        lli     at, 10                      // ~
        beq     t6, at, _power_shot         // branch if power level = 10 (power shot)
        nop

        // if power level is between 1-9, do a normal shot
        _normal_shot:
        // play a sound
        FGM.play(42)                        // play FGM
        // adjust hitbox parameters
        lw      v0, 0x0028(sp)              // v0 = projectile object
        lw      v1, 0x0084(v0)              // v1 = projectile struct
        lli     t7, 0                       // ~
        sw      t7, 0x010C(v1)              // Damage Type = 0(Normal)
        lli     t7, 8                       // ~
        sw      t7, 0x0104(v1)              // Damage = 8
        lli     t7, 80                      // ~
        sw      t7, 0x0130(v1)              // KBG = 80
        lli     t7, 20                      // ~
        sw      t7, 0x0138(v1)              // BKB = 20
        lli     t7, 38                      // ~
        sh      t7, 0x0146(v1)              // on-hit FGM = 38
        // set initial speed
        lw      t6, 0x0030(s0)              // ~
        sw      t6, 0x0048(sp)              // 0x0048(sp) = normal shot speed
        // adjust angle based on power level
        lw      t6, 0x002C(sp)              // t6 = player struct
        lwc1    f8, 0x0184(t6)              // ~
        cvt.s.w f8, f8                      // f8 = power level (float)
        li      t6, 0x3DB2B8C7              // ~
        mtc1    t6, f6                      // f6 = 0.0872665 rads (5 degrees)
        mul.s   f6, f6, f8                  // f6 = angle adjustment (5 degrees per power level)
        b       _continue                   // continue stage setting
        add.s   f12, f12, f6                // f12 = adjusted angle (initial angle + adjustment)

        // if power level is 10, do a power shot
        _power_shot:
        // play a sound
        FGM.play(25)                        // play FGM
        // adjust hitbox parameters
        lw      v0, 0x0028(sp)              // v0 = projectile object
        lw      v1, 0x0084(v0)              // v1 = projectile struct
        lli     t7, 1                       // ~
        sw      t7, 0x010C(v1)              // Damage Type = 1(Fire)
        lli     t7, 12                      // ~
        sw      t7, 0x0104(v1)              // Damage = 12
        lli     t7, 110                     // ~
        sw      t7, 0x0130(v1)              // KBG = 110
        lli     t7, 40                      // ~
        sw      t7, 0x0138(v1)              // BKB = 40
        lli     t7, 31                      // ~
        sh      t7, 0x0146(v1)              // on-hit FGM = 31
        // set initial speed
        lw      t6, 0x0034(s0)              // ~
        sw      t6, 0x0048(sp)              // 0x0048(sp) = power shot speed
        // set angle
        lw      at, 0x0038(s0)              // ~
        b       _continue                   // continue stage setting
        mtc1    at, f12                     // f12 = power shot angle

        // if power level is 0, drop the ball straight down
        _ball_drop:
        // // play a sound
        // FGM.play(42)                     // play FGM
        // adjust hitbox parameters
        lw      v0, 0x0028(sp)              // v0 = projectile object
        lw      v1, 0x0084(v0)              // v1 = projectile struct
        lli     t7, 0                       // ~
        sw      t7, 0x010C(v1)              // Damage Type = 0(Normal)
        lli     t7, 6                       // ~
        sw      t7, 0x0104(v1)              // Damage = 6
        lli     t7, 50                      // ~
        sw      t7, 0x0130(v1)              // KBG = 50
        lli     t7, 15                      // ~
        sw      t7, 0x0138(v1)              // BKB = 15
        lli     t7, 40                      // ~
        sh      t7, 0x0146(v1)              // on-hit FGM = 40
        // set initial speed
        sw      r0, 0x0048(sp)              // 0x0048(sp) = 0
        // set angle
        mtc1    r0, f12                     // f12 = 0 degree angle

        _continue:

        mtc1    r0, f4                      // f4 = 0
        swc1    f4, 0x0028(v1)              // set z speed? to 0
        swc1    f12, 0x0020(sp)             // 0x0020(sp) = adjusted angle
        jal     0x80035CD0                  // ~
        sw      v1, 0x0024(sp)              // original logic

        // add bonus speed
        lwc1    f6, 0x0020(s0)              // f6 = initial projectile speed
        lwc1    f8, 0x0048(sp)              // f8 = bonus speed
        add.s   f6, f6, f8                  // f6 = initial speed + bonus speed

        lw      t6, 0x002C(sp)              // ~
        lw      v1, 0x0024(sp)              // ~
        lw      t7, 0x0044(t6)              // ~
        mul.s   f8, f0, f6                  // ~
        lwc1    f12, 0x0020(sp)             // ~
        mtc1    t7, f10                     // ~
        nop                                 // ~
        cvt.s.w f16, f10                    // ~
        mul.s   f18, f8, f16                // ~
        jal     0x800303F0                  // ~
        swc1    f18, 0x0020(v1)             // original logic

        // add bonus speed
        lwc1    f4, 0x0020(s0)              // f4 = initial projectile speed
        lwc1    f6, 0x0048(sp)              // f6 = bonus speed
        add.s   f4, f4, f6                  // f4 = initial speed + bonus speed

        lw      v1, 0x0024(sp)              // ~
        lw      a0, 0x0028(sp)              // ~
        mul.s   f6, f0, f4                  // ~
        swc1    f6, 0x0024(v1)              // ~
        lw      t8, 0x0074(a0)              // ~
        lwc1    f10, 0x002C(s0)             // ~
        lw      t9, 0x0080(t8)              // ~
        jal     0x80167FA0                  // ~
        swc1    f10, 0x0088(t9)             // ~
        lw      v0, 0x0028(sp)              // original logic

        _end_stage_setting:
        lw      ra, 0x001C(sp)
        lw      s0, 0x0018(sp)
        addiu   sp, sp, 0x0050
        jr      ra
        nop
    }

    // @ Description
    // Main subroutine for the ball.
    scope ball_main_: {
        addiu   sp, sp, 0xFFE0              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        sw      a0, 0x0020(sp)              // 0x0020(sp) = projectile object
        lw      a0, 0x0084(a0)              // a0 = projectile struct
        jal     0x80167FE8                  // original logic, subroutine returns 1 if projectile duration is over
        sw      a0, 0x001C(sp)              // 0x001C(sp) = projectile struct
        beq     v0, r0, _continue           // branch if projectile duration has not ended
        lw      a0, 0x001C(sp)              // a0 = projectile struct

        _end_duration:
        lw      t7, 0x0020(sp)              // t7 = projectile object
        lw      a0, 0x0074(t7)              // ~
        addiu   a0, a0, 0x001C              // a0 = projectile x/y/z coords
        jal     0x800FF648                  // create smoke gfx
        lui     a1, 0x3F80                  // a1 = 1.0
        b       _end                        // branch to end
        lli     v0, OS.TRUE                 // return TRUE (destroys projectile)

        _continue:
        li      v0, ball_properties_struct  // v0 = ball_properties_struct
        lw      a1, 0x000C(v0)              // a1 = gravity
        jal     0x80168088                  // apply gravity to ball
        lw      a2, 0x0004(v0)              // a2 = max speed
        lw      a0, 0x001C(sp)              // a0 = projectile struct
        lw      t1, 0x0020(sp)              // t1 = projectile object
        lw      v1, 0x0074(t1)              // v1 = projectile struct with coordinates/rotation etc (bone struct?)
        li      at, ball_properties_struct  // at = ball properties struct
        lwc1    f6, 0x0014(at)              // f6 = rotation speed
        lwc1    f4, 0x01B4(a0)              // f4 = power level
        lui     t6, 0x3F00                  // ~
        mtc1    t6, f8                      // f8 = 0.5
        mul.s   f4, f4, f8                  // f4 = power level * 0.5
        lui     t6, 0x3F80                  // ~
        mtc1    t6, f8                      // f8 = 1
        add.s   f4, f4, f8                  // f4 = 1 + (power level * 0.5)
        mul.s   f6, f6, f4                  // increase rotation speed by 50% per power level
        lwc1    f4, 0x0030(v1)              // f4 = current rotation
        add.s   f8, f4, f6                  // add rotation speed to current rotation
        swc1    f8, 0x0030(v1)              // update rotation
        lli     v0, OS.FALSE                // return FALSE (don't destroy)

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // This subroutine destroys the ball and creates a smoke gfx.
    scope ball_destruction_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      a0, 0x0074(a0)              // ~
        addiu   a0, a0, 0x001C              // a0 = projectile x/y/z coords
        jal     0x800FF648                  // create smoke gfx
        lui     a1, 0x3F80                  // a1 = 1.0
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        lli     v0, OS.TRUE                 // return TRUE (destroys projectile)
    }

    // @ Description
    // Collision function for Birdo's ball.
    scope ball_collision_: {
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      s0, 0x0018(sp)              // store ra, s0
        jal     0x80167A58                  // wpMapTestAll - test for collisions
        or      s0, a0, r0                  // s0 = projectile object
        or      a0, s0, r0                  // a0 = projectile object
        addiu   a1, r0, 0x0C21              // a1 = collision mask = all
        li      a2, ball_properties_struct  // ~
        lw      a2, 0x0010(a2)              // a2 = bounce multiplier
        jal     0x80167C38                  // wpMapCheckAllRebound - check for collisions and apply bounce
        addiu   a3, sp, 0x0028              // a3 = pos
        beqz    v0, _skip                   // skip if no collision
        lw      a0, 0x0084(s0)              // a0 = projectile special struct
        jal     0x800C7A84                  // lbCommonMag2D - f0 = projectile absolute velocity
        addiu   a0, a0, 0x0020              // a0 = projectile x/y/z speed
        li      at, ball_properties_struct  // ~
        lwc1    f4, 0x0008(at)              // f4 = minimum speed
        c.lt.s  f0, f4                      // ~
        nop
        bc1f    _bounce                     // bounce if absolute velocity >= minimum speed
        nop
        // if absolute velocity < minimum speed
        lw      a0, 0x0074(s0)              // ~
        addiu   a0, a0, 0x001C              // a0 = projectile x/y/z
        jal     0x800FF648                  // create small smoke gfx
        lui     a1, 0x3F80                  // a1 = 1.0
        b       _end                        // end
        addiu   v0, r0, 0x0001              // return 1 (destroy projectile)
        _bounce:
        jal     0x80167FA0                  // wpMainVelSetModelPitch - set rotation based on velocity
        or      a0, s0, r0                  // a0 = projectile object
        lw      a0, 0x0074(s0)              // ~
        jal     0x800FF048                  // create small dust gfx
        addiu   a0, a0, 0x001C              // a0 = projectile x/y/z

        _skip:
        or      v0, r0, r0                  // return 0 (don't destroy projectile)

        _end:
        lw      ra, 0x001C(sp)              // ~
        lw      s0, 0x0018(sp)              // load ra, s0
        jr      ra                          // return
        addiu   sp, sp, 0x0038              // deallocate stack space
    }

    OS.align(16)
    ball_projectile_struct:
    constant BALL_ID(0x1100)
    dw 0x00000000                           // unknown
    dw BALL_ID                              // projectile id
    dw Character.BIRDO_file_6_ptr           // address of Birdo's file 6 pointer
    dw Birdo.FILE_OFFSETS.MERGED_FILERESOURCE_6_1 // 00000000
    dw 0x12470000                           // This determines z axis rotation? (samus is 1246)
    dw ball_main_                           // This is the main subroutine for the projectile, handles duration and other things. (default 0x80168540) (samus 0x80168F98)
    dw ball_collision_                      // This function runs each frame to test for collisions. (0x801685F0 - Mario) (0x80169108 - Samus)
    dw ball_destruction_                    // This function runs when the projectile collides with a hurtbox.
    dw ball_destruction_                    // This function runs when the projectile collides with a shield.
    dw 0x801686F8                           // This function runs when the projectile collides with edges of a shield and bounces off
    dw ball_destruction_                    // This function runs when the projectile collides/clangs with a hitbox.
    dw 0x801692C4                           // This function runs when the projectile collides with Fox's reflector (default 0x80168748)
    dw ball_destruction_                    // This function runs when the projectile collides with Ness's psi magnet
    OS.copy_segment(0x103904, 0x0C)         // empty

    OS.align(16)
    ball_properties_struct:
    dw 100                                  // 0x0000 - duration (int)
    float32 120                             // 0x0004 - max speed
    float32 5                               // 0x0008 - min speed
    float32 1.2                             // 0x000C - gravity
    float32 0.75                            // 0x0010 - bounce multiplier
    float32 0.1                             // 0x0014 - rotation speed
    float32 -0.139626                       // 0x0018 - initial angle (ground)
    float32 -0.139626                       // 0x001C - initial angle (air)
    float32 0                               // 0x0020 - initial speed
    dw Character.BIRDO_file_6_ptr           // 0x0024 - projectile data pointer
    dw Birdo.FILE_OFFSETS.MERGED_FILERESOURCE_6_1 // 00000000
    dw 0x00000000                           // 0x002C - palette index (0 = mario, 1 = luigi)
    float32 50                              // 0x0030 - normal shot speed
    float32 110                             // 0x0034 - power shot speed
    float32 0.0872665                       // 0x0038 - power shot angle
}

scope BirdoNSP {

    // floating point constants for physics and fsm
    constant AIR_Y_SPEED(0x4120)            // current setting - float32 10
    constant AIR_Y_SPEED_STALE(0x4120)            // current setting - float32 10
    constant X_SPEED(0x4120)                // current setting - float32 10
    constant X_SPEED_STALE(0x41A0)          // current setting - float32 20
    constant AIR_ACCELERATION(0x3C88)       // current setting - float32 0.0166
    constant AIR_SPEED(0x41B0)              // current setting - float32 22
    // temp variable 3 constants for movement states
    constant BEGIN(0x1)
    constant BEGIN_MOVE(0x2)
    constant MOVE(0x3)

 // @ Description
    // main subroutine for Birdo's Blaster
    scope main: {
        addiu   sp, sp, -0x0040
        sw      ra, 0x0014(sp)
        swc1    f6, 0x003C(sp)
        swc1    f8, 0x0038(sp)
        sw      a0, 0x0034(sp)
        addu    a2, a0, r0
        lw      v0, 0x0084(a0)                      // loads player struct

        or      a3, a0, r0
        lw      t6, 0x017C(v0)
        beql    t6, r0, _idle_transition_check      // this checks moveset variables to see if projectile should be spawned
        lw      ra, 0x0014(sp)
        mtc1    r0, f0
        sw      r0, 0x017C(v0)              // clears out variable so he only fires one shot
    //    lh      t6, 0x01BC(v0)              // t7 = buttons_held
    //    andi    t6, t6, Joypad.B            // t7 = 0x0020 if (B_HELD); else t7 = 0
    //    beqz    t6, _egg                    // skip if B is not held
    //    nop
//
    //    _fireball:
    //    addiu   a1, sp, 0x0020
    //    swc1    f0, 0x0020(sp)                      // x origin point
    //    swc1    f0, 0x0024(sp)                      // y origin point
    //    swc1    f0, 0x0028(sp)                      // z origin point
    //    lw      a0, 0x090C(v0)
    //    sw      a3, 0x0030(sp)
    //    jal     0x800EDF24                          // generic function used to determine projectile origin point
    //    sw      v0, 0x002C(sp)
    //    lw      v0, 0x002C(sp)
    //    lw      a3, 0x0030(sp)
    //    sw      r0, 0x001C(sp)
    //    or      a0, a3, r0
    //    addiu   a1, sp, 0x0020
    //    jal     fireprojectile_stage_setting            // this sets the basic features of a projectile
    //    lw      a2, 0x001C(sp)
    //    lw      a2, 0x0034(sp)
    //    lw      ra, 0x0014(sp)
//
    //    // checks frame counter to see if reached end of the move
    //    _idle_transition_check2:
    //    mtc1    r0, f6
    //    lwc1    f8, 0x0078(a2)
    //    c.le.s  f8, f6
    //    nop
    //    bc1fl   _end2
    //    lw      ra, 0x0014(sp)
    //    lw      a2, 0x0034(sp)
    //    jal     0x800DEE54
    //    or      a0, a2, r0
    //     _end2:
    //    lw      a0, 0x0034(sp)
    //    lwc1    f6, 0x003C(sp)
    //    lwc1    f8, 0x0038(sp)
    //    lw      ra, 0x0014(sp)
    //    addiu   sp, sp, 0x0040
    //    jr      ra
    //    nop
    //    
    //    fireprojectile_stage_setting:
    //    addiu   sp, sp, -0x0050
    //    sw      a2, 0x0038(sp)
    //    lw      t7, 0x0038(sp)
    //    sw      s0, 0x0018(sp)
    //    li      s0, _fire_fireball_struct       // load blaster format address
//
//
    //    sw      a1, 0x0034(sp)
    //    sw      ra, 0x001C(sp)
    //    lw      t6, 0x0084(a0)
    //    lw      t0, 0x0024(s0)
    //    lw      t1, 0x0028(s0)
    //    li      a1, _fire_projectile_struct      // load projectile addresses
    //    lw      a2, 0x0034(sp)
    //    lui     a3, 0x8000
    //    sw      t6, 0x002C(sp)
    //    //sw      t0, 0x0008(a1)        // would revise default pointer, which has another pointer, which is to the hitbox data
    //    jal     0x801655C8                // This is a generic routine that does much of the work for defining all projectiles
    //    sw      t1, 0x000C(a1)
//
    //    bnez    v0, _fireprojectile_branch
    //    sw      v0, 0x0028(sp)
    //    beq     r0, r0, _fireend_stage_setting
    //    or      v0, r0, r0
//
    //    _fireprojectile_branch:
    //    lw      v1, 0x0084(v0)
    //    lui     t2, 0x3f80              // load 1(fp) into f2
    //    addiu   at, r0, 0x0001
    //    mtc1    r0, f4
    //    sw      t2, 0x029C(v1)           // save 1(fp) to projectile struct free space
    //    lw      t3, 0x0000(s0)
    //    sw      t3, 0x0268(v1)
//
    //    OS.copy_segment(0xE3268, 0x2C)
    //    lw      t6, 0x002C(sp)
    //    lwc1    f6, 0x0020(s0)           // load speed (integer)
////
//  //      lw t0, 0x002C(sp)                // load player struct from stack
//  //      lwc1 f0, 0x0048(t0)              // load direction from player struct
//  //      cvt.s.w f0, f0                   // convert direction to float
//  //      lb t0, 0x01C2(t0)                // load stick_x from player struct
//  //      mtc1 t0, f2                      // move stick_x to fp register
//  //      cvt.s.w f2, f2                    // convert stick_x to float
//  //      mul.s   f0, f2, f0                  // f0 = stick_x * direction
//  //      lui     t0, 0x4120                  // ~
//  //      mtc1    t0, f2                      // f2 = 10
//  //      c.le.s  f2, f0                      // ~
//  //      bc1t    _fastfire                   // branch if stick_x * direction => 10
//  //      nop                                 // ~
////
//  //      _slowfire:
//  //      lui     t6, 0xC1A0                  // ~
//  //      mtc1    t6, f6                      // f6 = -20
//  //      add.s   f6, f6, f8                  // f6 = bonus speed (power level + -20)
//  //      swc1    f6, 0x0048(sp)              // 0x0048(sp) = bonus speed
//  //      bc1f    _adjustspeedfire            // branch if stick_x * direction =< 10
//  //      nop
//  //      j _fireprojectile:
////
//  //      _fastfire:
//  //      lui     t6, 0x41A0                  // ~
//  //      mtc1    t6, f6                      // f6 = 20
//  //      add.s   f6, f6, f8                  // f6 = bonus speed (power level + 20)
//  //      swc1    f6, 0x0048(sp)              // 0x0048(sp) = bonus speed
////
////
//  //      _adjustspeedfire:
//  //      // add bonus speed
//  //      lwc1    f6, 0x0020(s0)              // f6 = initial projectile speed
//  //      lwc1    f8, 0x0048(sp)              // f8 = bonus speed
//  //      add.s   f6, f6, f8                  // f6 = initial speed + bonus speed
////
//  //      _fireprojectile:
    //    lw      v1, 0x0024(sp)
    //    lw      t7, 0x0044(t6)
    //    mul.s   f8, f0, f6
    //    lwc1    f12, 0x0020(sp)
    //    mtc1    t7, f10
    //    nop
    //    cvt.s.w f16, f10
    //    mul.s   f18, f8, f16
    //    jal     0x800303F0
    //    swc1    f18, 0x0020(v1)
    //    lwc1    f4, 0x0020(s0)
    //    lw      v1, 0x0024(sp)
    //    lw      a0, 0x0028(sp)
    //    mul.s   f6, f0, f4
    //    swc1    f6, 0x0024(v1)
    //    lw      t8, 0x0074(a0)
    //    lwc1    f10, 0x002C(s0)
    //    lw      t9, 0x0080(t8)
    //    lli     t7, 1                       // ~
    //    sw      t7, 0x010C(v1)              // Damage Type = 1(Fire)
    //    lli     t7, 0x001B                  // t7 = 0x1F
    //    sh      t7, 0x0146(v1)              // set on-hit FGM to 0x1B
    //    // This ensures the projectile faces the correct direction
    //    jal     0x80167FA0
    //    swc1    f10, 0x0088(t9)
    //    lw      v0, 0x0028(sp)
//
    //    _fireend_stage_setting:
    //    lw      ra, 0x001C(sp)
    //    lw      s0, 0x0018(sp)
    //    addiu   sp, sp, 0x0050
    //    jr      ra
    //    nop
//
    //    // this subroutine seems to have a variety of functions, but definetly deals with the duration of move and result at the end of duration
    //    fire_duration:
    //    addiu   sp, sp, -0x0024
    //    sw      ra, 0x0014(sp)
    //    sw      a0, 0x0020(sp)
    //    swc1    f10, 0x0024(sp)
    //    lw      a0, 0x0084(a0)
    //    sw      a0, 0x001C(sp)
//
    //    _firecontinue:
    //    addiu   t8, r0, r0          // used to use free space area, but for no apparent reason, affects graphics
    //    //lw      t8, 0x029C(a0)
    //    lw      t7, 0x0020(sp)      // t7 = projectile object
    //    li      t0, _fire_fireball_struct
    //    addu    v0, r0, t0
    //    lw      a1, 0x000C(v0)
    //    lw      a2, 0x0004(v0)
    //    lw      t1, 0x0020(sp)
    //    addiu   t2, r0, r0          // used to use free space area, but for no apparent reason, effects graphics
    //    lw      v1, 0x0074(t1)
    //    or      v0, r0, r0
    //    lwc1    f8, 0x0020(a0)      // load current speed
    //    lui     at, 0x3F84          // speed multiplier (accel) loaded in at (1.03125)
    //    mtc1    at, f6              // move speed multiplier to floating point register
    //    mul.s   f8, f8, f6          // speed multiplied by accel
//
    //    lw      at, 0x0004(t0)      // load max speed
    //    mtc1    at, f6
    //    lw      at, 0x029C(a0)      // load multiplier that is typically one, unless reflected
    //    mtc1    at, f10
    //    mul.s   f6, f6, f10
    //    c.le.s  f8, f6
//
    //    lw      t8, 0x0000(t0)      // t8 = initial duration
    //    addiu   t8, t8, -0x0004     // t8 = initial duration - 4 frames
    //    // t7 has current count from prior jal
    //    sltu    t8, t7, t8          // t8 = 1 if after first 4 frames
    //    //mtc1    r0, f6              // f6 = 0 = no rotation
    //    lui		at, 0x3E80          // f6 = 0.5 rotation multiplier
    //    mtc1    at, f6
    //    beqz    t8, _initial_rotation // if in the first 4 frames, skip normal rotation/gravity
    //    addiu   a1, r0, r0          // set gravity to 0
//
    //    // rest of the duration functionality
    //    lw      a1, 0x000C(t0)      // load normal gravity
//
    //    lw      t1, 0x0020(sp)      // t1 = projectile object
    //    lw      t2, 0x0084(t1)      // t2 = projectile special struct
//
    //    // ensure hitbox is always on in the air
    //    lli     at, 0x0001          // at = 1 = enable hitbox
    //    sw      at, 0x0150(t2)      // turn on hitbox
//
    //    lw      t3, 0x00FC(t2)      // t3 = 0 if grounded
    //    bnezl   t3, _initial_rotation // if not grounded, rotate
    //    lwc1    f6, 0x0014(v0)      // load normal rotation
//
    //    _initial_rotation:
    //    lw      t1, 0x0020(sp)      // t1 = projectile object
    //    lw      v1, 0x0074(t1)      // v1 = top joint
    //    lwc1    f4, 0x0030(v1)      // f4 = current rotation value
    //    add.s   f8, f4, f6          // f8 = new rotation value (rot * 0.5)
    //    swc1    f8, 0x0030(v1)      // update rotation value
//
    //    _fireend_duration:
    //    lw      ra, 0x0014(sp)
    //    lwc1    f10, 0x0024(sp)
    //    addiu   sp, sp, 0x0024
    //    jr      ra
    //    nop
//
    //    _firehitbox_end:
    //    OS.copy_segment(0xE396C, 0x38)
    //    // swc1 f4, 0x0148(v0)
    //    OS.copy_segment(0xE39A8, 0x30)

        _egg:
        addiu   a1, sp, 0x0020
        swc1    f0, 0x0020(sp)                      // x origin point
        swc1    f0, 0x0024(sp)                      // y origin point
        swc1    f0, 0x0028(sp)                      // z origin point
        lw      a0, 0x090C(v0)
        sw      a3, 0x0030(sp)
        jal     0x800EDF24                          // generic function used to determine projectile origin point
        sw      v0, 0x002C(sp)
        lw      v0, 0x002C(sp)
        lw      a3, 0x0030(sp)
        sw      r0, 0x001C(sp)
        or      a0, a3, r0
        addiu   a1, sp, 0x0020
        jal     projectile_stage_setting            // this sets the basic features of a projectile
        lw      a2, 0x001C(sp)
        lw      a2, 0x0034(sp)
        lw      ra, 0x0014(sp)

        // checks frame counter to see if reached end of the move
        _idle_transition_check:
        mtc1    r0, f6
        lwc1    f8, 0x0078(a2)
        c.le.s  f8, f6
        nop
        bc1fl   _end
        lw      ra, 0x0014(sp)
        lw      a2, 0x0034(sp)
        jal     0x800DEE54
        or      a0, a2, r0
         _end:
        lw      a0, 0x0034(sp)
        lwc1    f6, 0x003C(sp)
        lwc1    f8, 0x0038(sp)
        lw      ra, 0x0014(sp)
        addiu   sp, sp, 0x0040
        jr      ra
        nop

        projectile_stage_setting:
        addiu   sp, sp, -0x0050
        sw      a2, 0x0038(sp)
        lw      t7, 0x0038(sp)
        sw      s0, 0x0018(sp)
        li      s0, _egg_fireball_struct       // load blaster format address


        sw      a1, 0x0034(sp)
        sw      ra, 0x001C(sp)
        lw      t6, 0x0084(a0)
        lw      t0, 0x0024(s0)
        lw      t1, 0x0028(s0)
        li      a1, _egg_projectile_struct      // load projectile addresses
        lw      a2, 0x0034(sp)
        lui     a3, 0x8000
        sw      t6, 0x002C(sp)
        //sw      t0, 0x0008(a1)        // would revise default pointer, which has another pointer, which is to the hitbox data
        jal     0x801655C8                // This is a generic routine that does much of the work for defining all projectiles
        sw      t1, 0x000C(a1)

        bnez    v0, _projectile_branch
        sw      v0, 0x0028(sp)
        beq     r0, r0, _end_stage_setting
        or      v0, r0, r0

        _projectile_branch:
        lw      v1, 0x0084(v0)
        lui     t2, 0x3f80              // load 1(fp) into f2
        addiu   at, r0, 0x0001
        mtc1    r0, f4
        sw      t2, 0x029C(v1)           // save 1(fp) to projectile struct free space
        lw      t3, 0x0000(s0)
        sw      t3, 0x0268(v1)

        OS.copy_segment(0xE3268, 0x2C)
        lw      t6, 0x002C(sp)
        lwc1    f6, 0x0020(s0)           // load speed (integer)

//        cvt.s.w f0, f0                      // f0 = direction
//        lb      t0, 0x01C2(s0)              // ~
//        mtc1    t0, f2                      // ~
//        cvt.s.w f2, f2                      // f2 = stick_x
//        mul.s   f0, f2, f0                  // f0 = stick_x * direction
//        lui     t0, 0x4120                  // ~
//        mtc1    t0, f2                      // f2 = 10
//        c.le.s  f2, f0                      // ~
//        bc1t    _fastegg                   // branch if stick_x * direction => 10
//        nop                                 // ~
//
//        _slowegg:
//        lui     t6, 0xC1A0                  // ~
//        mtc1    t6, f6                      // f6 = -20
//        add.s   f6, f6, f8                  // f6 = bonus speed (power level + -20)
//        swc1    f6, 0x0048(sp)              // 0x0048(sp) = bonus speed
//        bc1f    _adjustspeedegg            // branch if stick_x * direction =< 10
//        nop
//
//        _fastegg:
//        lui     t6, 0x41A0                  // ~
//        mtc1    t6, f6                      // f6 = 20
//        add.s   f6, f6, f8                  // f6 = bonus speed (power level + 20)
//        swc1    f6, 0x0048(sp)              // 0x0048(sp) = bonus speed
//
//
//        _adjustspeedegg:
//        // add bonus speed
//        lwc1    f6, 0x0020(s0)              // f6 = initial projectile speed
//        lwc1    f8, 0x0048(sp)              // f8 = bonus speed
//        add.s   f6, f6, f8                  // f6 = initial speed + bonus speed

        lw      v1, 0x0024(sp)
        lw      t7, 0x0044(t6)
        mul.s   f8, f0, f6
        lwc1    f12, 0x0020(sp)
        mtc1    t7, f10
        nop
        cvt.s.w f16, f10
        mul.s   f18, f8, f16
        jal     0x800303F0
        swc1    f18, 0x0020(v1)
        lwc1    f4, 0x0020(s0)
        lw      v1, 0x0024(sp)
        lw      a0, 0x0028(sp)
        mul.s   f6, f0, f4
        swc1    f6, 0x0024(v1)
        lw      t8, 0x0074(a0)
        lwc1    f10, 0x002C(s0)
        lw      t9, 0x0080(t8)
        lli     t7, 0                       // ~
        sw      t7, 0x010C(v1)              // Damage Type = 0(Normal)
        lli     t7, 0x001F                  // t7 = 0x1F
        sh      t7, 0x0146(v1)              // set on-hit FGM to 0x1F
        // This ensures the projectile faces the correct direction
        jal     0x80167FA0
        swc1    f10, 0x0088(t9)
        lw      v0, 0x0028(sp)
        

        _end_stage_setting:
        lw      ra, 0x001C(sp)
        lw      s0, 0x0018(sp)
        addiu   sp, sp, 0x0050
        jr      ra
        nop

        // this subroutine seems to have a variety of functions, but definetly deals with the duration of move and result at the end of duration
        egg_duration:
        addiu   sp, sp, -0x0024
        sw      ra, 0x0014(sp)
        sw      a0, 0x0020(sp)
        swc1    f10, 0x0024(sp)
        lw      a0, 0x0084(a0)
        sw      a0, 0x001C(sp)

        _continue:
        addiu   t8, r0, r0          // used to use free space area, but for no apparent reason, affects graphics
        //lw      t8, 0x029C(a0)
        li      t0, _egg_fireball_struct
        addu    v0, r0, t0
        lw      a1, 0x000C(v0)
        lw      a2, 0x0004(v0)
        lw      t1, 0x0020(sp)
        addiu   t2, r0, r0          // used to use free space area, but for no apparent reason, effects graphics
        lw      v1, 0x0074(t1)
        or      v0, r0, r0
        lwc1    f8, 0x0020(a0)      // load current speed
        lui     at, 0xBD00          // speed multiplier (accel) loaded in at (-0.03125)
        mtc1    at, f6              // move speed multiplier to floating point register
        mul.s   f8, f8, f6          // speed multiplied by accel


        lw      at, 0x0004(t0)      // load max speed
        mtc1    at, f6
        lw      at, 0x029C(a0)      // load multiplier that is typically one, unless reflected
        mtc1    at, f10
        mul.s   f6, f6, f10
        c.le.s  f8, f6
        nop

        _end_duration:
        lw      ra, 0x0014(sp)
        lwc1    f10, 0x0024(sp)
        addiu   sp, sp, 0x0024
        jr      ra
        nop

        _hitbox_end:
        OS.copy_segment(0xE396C, 0x38)
        // swc1 f4, 0x0148(v0)
        OS.copy_segment(0xE39A8, 0x30)

        // this subroutine determines the behavior of the projectile upon reflection
        egg_reflection:
        addiu   sp, sp, -0x0018
        sw      ra, 0x0014(sp)
        sw      a0, 0x0018(sp)
        lw      a0, 0x0084(a0)      // loads active projectile struct
        lw      t0, 0x0008(v0)
        addiu   t7, r0, Character.id.BIRDO
        bnel    t0, t7, _standard
        lui     t7, 0x3F80          // load normal reflect multiplier if not Birdo and thereby top speed of Birdo projectile will not increase
        li      t7, 0x3FC90FDB      // load reflect multiplier
        _standard:
        mtc1    t7, f4              // move reflect multiplier to floating point
        sw      t7, 0x029C(a0)      // save multiplier to free space to increase max speed
        lw      t7, 0x0008(a0)
        li      t0, _egg_fireball_struct // load fireball struct to pull parameters
        lw      t0, 0x0000(t0)      // loads max duration from fireball struct
        sw      t0, 0x0268(a0)      // save max duration to active projectile struct current remaining duration
        lw      a1, 0x0084(t7)      // loads reflective character's struct

        // Before determining new direction, multiply speed.
        lw      t6, 0x0044(a1)      // loads player direction 1 or -1 in fp
        lwc1    f0, 0x0020(a0)      // loads projectile velocity
        mul.s   f0, f0, f4          // multiply current speed by reflection speed multiplier
        nop
        swc1    f0, 0x0020(a0)      // save new speed
        nop
        jal     0x801680EC          // go to the default subroutine that determines direction
        nop

        _branch:
        lw      a0, 0x0018(sp)
        lw      v0, 0x0084(a0)      // load active projectile struct
        mtc1    r0, f6              // move 0 to f6
        lwc1    f4, 0x0020(v0)      // load current velocity of projectile
        c.le.s  f6, f4              // compare 0 to current velocity to see if now traveling leftward
        nop
        bc1f    _left               // jump if 0 is greater than velocity, this means the projectile is traveling leftward
        nop
        li        at, 0x3FC90FDB
        mtc1      at, f8
        lw      t6, 0x0074(a0)
        j       _end_reflect
        swc1    f8, 0x0034(t6)
        _left:
        li        at, 0xBFC90FDB
        mtc1      at, f10
        lw      t7, 0x0074(a0)
        swc1    f10, 0x0034(t7)
        _end_reflect:
        lw      ra, 0x0014(sp)
        addiu   sp, sp, 0x0018
        or      v0, r0, r0
        jr      ra
        nop

        // @ Description
        // This subroutine destroys the nut and creates a smoke gfx.
        egg_destruction_:
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      a0, 0x0074(a0)              // ~
        addiu   a0, a0, 0x001C              // a0 = projectile x/y/z coords
        jal     0x801041A0                  // create egg shatter gfx
        nop
        jal     0x800269C0                  // play FGM
        lli     a0, 0x00FC                  // FGM id = FC
        lui     a1, 0x3F80                  // a1 = 1.0
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        lli     v0, OS.TRUE                 // return TRUE (destroys projectile)

        // @ Description
        // This subroutine destroys the nut and creates a smoke gfx.
        fire_destruction_:
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      a0, 0x0074(a0)              // ~
        addiu   a0, a0, 0x001C              // a0 = projectile x/y/z coords
        jal     0x80100480                  // create small explosion gfx
        nop
        jal     0x800269C0                  // play FGM
        lli     a0, 0x001C                  // FGM id = 1C
        lui     a1, 0x3F80                  // a1 = 1.0
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        lli     v0, OS.TRUE                 // return TRUE (destroys projectile)

        _egg_projectile_struct:
        dw 0x00000000                   // this has some sort of bit flag to tell it to use secondary type display list?
        dw 0x00000000
        dw Character.BIRDO_file_6_ptr    // pointer to file
        dw Birdo.FILE_OFFSETS.MERGED_FILERESOURCE_6_0 // 00000000
        dw 0x12480000                   // rendering routine?
        dw egg_duration             // duration (default 0x80168540) (samus 0x80168F98)
        dw 0x80175914                   // collision (0x801685F0 - Mario) (0x80169108 - Samus)
        dw egg_destruction_             // after_effect 0x801691FC, this one is used when grenade connects with player
        dw egg_destruction_             // after_effect 0x801691FC, used when touched by player when object is still, by setting to null, nothing happens
        dw 0x8016DD2C                   // determines behavior when projectile bounces off shield, this uses Master Hand's projectile coding to determine correct angle of graphic (0x8016898C Fox)
        dw egg_destruction_             // after_effect                // rocket_after_effect 0x801691FC
        dw egg_reflection           // OS.copy_segment(0x1038FC, 0x04)            // this determines reflect behavior (default 0x80168748)
        dw egg_destruction_             // This function is run when the projectile is used on ness while using psi magnet
        OS.copy_segment(0x103904, 0x0C) // empty


        _egg_fireball_struct:
        dw 100                          // 0x0000 - duration (int)
        float32 50                      // 0x0004 - max speed
        float32 50                      // 0x0008 - min speed
        float32 0                       // 0x000C - gravity
        float32 0                       // 0x0010 - bounce multiplier
        float32 0                       // 0x0014 - rotation angle
        float32 0                       // 0x0018 - initial angle (ground)
        float32 0                       // 0x001C   initial angle (air)
        float32 50                      // 0x0020   initial speed
        dw Character.BIRDO_file_6_ptr    // 0x0024   projectile data pointer
        dw Birdo.FILE_OFFSETS.MERGED_FILERESOURCE_6_0 // 00000000
        float32 0                       // 0x002C   palette index (0 = mario, 1 = luigi)
        OS.copy_segment(0x1038A0, 0x30)

        _fire_projectile_struct:
        dw 0x00000000                   // this has some sort of bit flag to tell it to use secondary type display list?
        dw 0x00000000
        dw Character.BIRDO_file_6_ptr    // pointer to file
        dw Birdo.FILE_OFFSETS.MERGED_FILERESOURCE_6_2 // 00000000
        dw 0x12480000                   // rendering routine?
        dw egg_duration             // duration (default 0x80168540) (samus 0x80168F98)
        dw 0x80175914                   // collision (0x801685F0 - Mario) (0x80169108 - Samus)
        dw fire_destruction_             // after_effect 0x801691FC, this one is used when grenade connects with player
        dw fire_destruction_             // after_effect 0x801691FC, used when touched by player when object is still, by setting to null, nothing happens
        dw 0x8016DD2C                   // determines behavior when projectile bounces off shield, this uses Master Hand's projectile coding to determine correct angle of graphic (0x8016898C Fox)
        dw 0x80175958             // after_effect                // rocket_after_effect 0x801691FC
        dw egg_reflection           // OS.copy_segment(0x1038FC, 0x04)            // this determines reflect behavior (default 0x80168748)
        dw 0x80175958             // This function is run when the projectile is used on ness while using psi magnet
        OS.copy_segment(0x103904, 0x0C) // empty


        _fire_fireball_struct:
        dw 100                          // 0x0000 - duration (int)
        float32 70                      // 0x0004 - max speed
        float32 70                      // 0x0008 - min speed
        float32 0                       // 0x000C - gravity
        float32 0                       // 0x0010 - bounce multiplier
        float32 0.1                     // 0x0014 - rotation angle
        float32 0                       // 0x0018 - initial angle (ground)
        float32 0                       // 0x001C   initial angle (air)
        float32 70                      // 0x0020   initial speed
        dw Character.BIRDO_file_6_ptr    // 0x0024   projectile data pointer
        dw Birdo.FILE_OFFSETS.MERGED_FILERESOURCE_6_2 // 00000000
        float32 0                       // 0x002C   palette index (0 = mario, 1 = luigi)
        OS.copy_segment(0x1038A0, 0x30)
        }
    // @ Description
    // Subroutine which handles movement for Birdo's neutral special.
    // Uses the moveset data command 5C0000XX (orignally identified as "apply throw?" by toomai)
    // This command's purpose appears to be setting a temporary variable in the player struct.
    // The most common use of this variable is to determine when a throw should be applied.
    // Variable values used by this subroutine:
    // 0x2 = begin movement
    // 0x3 = movement
    // 0x4 = ending
    scope physics_: {
        // s0 = player struct
        // s1 = attributes pointer
        // 0x184 in player struct = temp variable 3
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      s0, 0x0014(sp)              // ~
        sw      s1, 0x0018(sp)              // store ra, s0, s1
        lw      s0, 0x0084(a0)              // s0 = player struct

        _aerial:
        OS.copy_segment(0x548F0, 0x40)      // copy from original air physics subroutine
        bnez    v0, _check_begin            // modified original branch
        nop
        li      t8, 0x800D8FA8              // t8 = subroutine which disallows air control
        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        ori     t1, r0, MOVE                // t1 = MOVE
        bne     t0, t1, _apply_air_physics  // branch if temp variable 3 != MOVE
        nop
        li      t8, air_control_             // t8 = air_control_

        _apply_air_physics:
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
        // reset fall speed
        lbu     v1, 0x018D(s0)              // v1 = fast fall flag
        ori     t6, r0, 0x0007              // t6 = bitmask (01111111)
        and     v1, v1, t6                  // ~
        sb      v1, 0x018D(s0)              // disable fast fall flag
        // slow x movement
        lwc1    f0, 0x0048(s0)              // f0 = current x velocity
        lui     t0, 0x3F60                  // ~
        mtc1    t0, f2                      // f2 = 0.875
        mul.s   f0, f0, f2                  // f0 = x velocity * 0.875
        swc1    f0, 0x0048(s0)              // x velocity = (x velocity * 0.875)
        // freeze y position
        sw      r0, 0x004C(s0)              // y velocity = 0
        

        _check_begin_move:
        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        ori     t1, r0, BEGIN_MOVE          // t1 = BEGIN_MOVE
        bne     t0, t1, _end                // skip if temp variable 3 != BEGIN_MOVE
        nop

        lui     t1, AIR_Y_SPEED             // t1 = AIR_Y_SPEED
        lui     t0, X_SPEED                 // t0 = X_SPEED

        _apply_velocity:
        mtc1    t0, f2                      // f2 = X_SPEED
        lwc1    f0, 0x0044(s0)              // ~
        cvt.s.w f0, f0                      // f0 = direction
        mul.s   f2, f0, f2                  // f2 = x velocity * direction
        ori     t0, r0, MOVE                // t0 = MOVE
        sw      t0, 0x0184(s0)              // temp variable 3 = MOVE
        swc1    f2, 0x0048(s0)              // store x velocity
        sw      t1, 0x004C(s0)              // store y velocity

        _end:
        lw      ra, 0x001C(sp)              // ~
        lw      s0, 0x0014(sp)              // ~
        lw      s1, 0x0018(sp)              // loar ra, s0, s1
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles Birdo's horizontal control for neutral special.
    scope air_control_: {
        addiu   sp, sp,-0x0028              // allocate stack space
        sw      a1, 0x001C(sp)              // ~
        sw      ra, 0x0014(sp)              // ~
        sw      t0, 0x0020(sp)              // ~
        sw      t1, 0x0024(sp)              // store a1, ra, t0, t1
        addiu   a1, r0, 0x0008              // a1 = 0x8 (original line)
        lw      t6, 0x001C(sp)              // t6 = attribute pointer
        // load an immediate value into a2 instead of the air acceleration from the attributes
        lui     a2, AIR_ACCELERATION        // a2 = AIR_ACCELERATION
        lui     a3, AIR_SPEED               // a3 = AIR_SPEED
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
   // Subroutine which handles air collision for neutral special actions
    scope air_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, air_to_ground_          // a1(transition subroutine) = air_to_ground_
        jal     0x800DE6E4                  // common air collision subroutine (transition on landing, no ledge grab)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles ground to air transition for neutral special actions
    scope air_to_ground_: {
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // store ra
        sw      a0, 0x0038(sp)              // 0x0038(sp) = player object
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800DEE98                  // set grounded state
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player struct
        lw      v0, 0x0034(sp)              // v0 = player struct
        lw      a0, 0x0038(sp)              // a0 = player object

        //lw      a2, 0x0008(v0)              // load character ID
        //lli     a1, Character.id.KIRBY      // a1 = id.KIRBY
        //beql    a1, a2, _change_action      // if Kirby, load alternate action ID
        //lli     a1, Kirby.Action.BIRDO_NSP_Ground
        //lli     a1, Character.id.JKIRBY     // a1 = id.JKIRBY
        //beql    a1, a2, _change_action      // if J Kirby, load alternate action ID
        //lli     a1, Kirby.Action.BIRDO_NSP_Ground


        addiu   a1, r0, 0x00E4              // a1 = equivalent ground action for current air action
        _change_action:
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lli     t6, 0x0001                  // ~
        jal     0x800E6F24                  // change action
        sw      t6, 0x0010(sp)              // argument 4 = 1 (continue hitbox)
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop
    }
}

scope BirdoDSP {
    constant Y_SPEED(0xC2F0)                // current setting - float:-120.0
    constant INITIAL_Y_SPEED(0x4220)        // current setting - float:40.0
    constant INITIAL_X_SPEED(0x4120)        // current setting - float:10.0

    constant BEGIN(0x1)
    constant MOVE(0x2)

    // @ Description
    // Subroutine which runs when Birdo initiates an aerial down special.
    // Changes action, and sets up initial variable values.
    scope air_initial_: {
        addiu   sp, sp, 0xFFE0              // ~
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // original lines 1-3
        sw      r0, 0x0010(sp)              // argument 4 = 0
        lli     a1, Birdo.Action.POWBlockAir              // a1 = DSPAir
        or      a2, r0, r0                  // a2 = float: 0.0
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3 = float: 1.0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
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
        jr      ra                          // original return logic
        addiu   sp, sp, 0x0020              // ~
    }

    // @ Description
    // Subroutine which runs when Birdo initiates a grounded down special.
    // Changes action, and sets up initial variable values.
    scope ground_initial_: {
        addiu   sp, sp, 0xFFE0              // ~
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // original lines 1-3
        sw      r0, 0x0010(sp)              // argument 4 = 0
        lli     a1, Birdo.Action.POWBlockGround              // a1 = DSPGround
        or      a2, r0, r0                  // a2 = float: 0.0
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3 = float: 1.0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        ori     v1, r0, 0x0001              // ~
        sw      v1, 0x0184(a0)              // temp variable 3 = 0x1(BEGIN)
        lw      ra, 0x001C(sp)              // ~
        jr      ra                          // original return logic
        addiu   sp, sp, 0x0020              // ~
    }

    // @ Description
    // Subroutine which sets up the movement for the grounded version of Birdo's down special.
    // Temp variable 1 (5400XXXX):
    // 0x1 = apply initial movement and set aerial kinetic state
    // Temp variable 2 (5800XXXX):
    // 0x1 = control air drift (physics_)
    // Temp variable 3 (5C00XXXX):
    // 0x1 = begin
    // 0x2 = apply movement speed (physics_)
    scope ground_move_: {
        // a2 = player struct
        // 0x184 in player struct = temp variable 3

        addiu   sp, sp,-0x0018              // allocate stack space
        sw      t0, 0x0004(sp)              // ~
        sw      t1, 0x0008(sp)              // ~
        swc1    f0, 0x000C(sp)              // ~
        swc1    f2, 0x0010(sp)              // ~
        sw      ra, 0x0014(sp)              // store t0, t1, f0, f2, ra

        // slow x movement
        lwc1    f0, 0x0048(a2)              // f0 = current x velocity
        lui     t0, 0x3F80                  // ~
        mtc1    t0, f2                      // f2 = 1
        mul.s   f0, f0, f2                  // f0 = x velocity * 1
        swc1    f0, 0x0048(a2)              // x velocity = (x velocity * 1)

        _check_begin:
        lw      t0, 0x0184(a2)              // t0 = temp variable 3
        ori     t1, r0, BEGIN               // t1 = BEGIN
        bne     t0, t1, _check_initial      // skip if t0 != BEGIN
        nop
        // slow y movement
        lwc1    f0, 0x004C(a2)              // f0 = current y velocity
        lui     t0, 0x3F80                  // ~
        mtc1    t0, f2                      // f2 = 1
        mul.s   f0, f0, f2                  // f0 = x velocity * 1
        swc1    f0, 0x004C(a2)              // y velocity = (y velocity * 1)

        _check_initial:
        lw      t0, 0x017C(a2)              // t0 = temp variable 1
        beq     t0, r0, _end                // skip if temp variable 1 = 0
        nop
        // reset temp variable 2
        sw      r0, 0x017C(a2)              // temp variable 1 = 0
        // apply initial x velocity
        lui     t1, INITIAL_X_SPEED         // ~
        mtc1    t1, f0                      // f0 = INITIAL_X_SPEED
        lwc1    f2, 0x0044(a2)              // ~
        cvt.s.w f2, f2                      // f2 = DIRECTION
        mul.s   f0, f0, f2                  // f0 = INITIAL_X_SPEED * DIRECTION
        swc1    f0, 0x0048(a2)              // x velocity = INITIAL_X_SPEED * DIRECTION
        // apply initial y velocity
        lui     t0, INITIAL_Y_SPEED         // ~
        sw      t0, 0x004C(a2)              // y velocity = INITIAL_Y_SPEED
        jal     0x800DEEC8                  // set aerial state
        or      a0, a2, r0                  // a0 = player struct

        _end:
        lw      t0, 0x0004(sp)              // ~
        lw      t1, 0x0008(sp)              // ~
        lwc1    f0, 0x000C(sp)              // ~
        lwc1    f2, 0x0010(sp)              // ~
        lw      ra, 0x0014(sp)              // load t0, t1, f0, f2, ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which sets up the movement for the aerial version of Birdo's down special.
    // Temp variable 2 (5800XXXX):
    // 0x1 = control air drift (physics_)
    // Temp variable 3 (5C00XXXX):
    // 0x1 = begin
    // 0x2 = apply movement speed
    scope air_move_: {
        // a2 = player struct
        // 0x184 in player struct = temp variable 3

        addiu   sp, sp,-0x0018              // allocate stack space
        sw      t0, 0x0004(sp)              // ~
        sw      t1, 0x0008(sp)              // ~
        swc1    f0, 0x000C(sp)              // ~
        swc1    f2, 0x0010(sp)              // store t0, t1, f0, f2

        // slow x movement
        lwc1    f0, 0x0048(a2)              // f0 = current x velocity
        lui     t0, 0x0000                  // ~
        mtc1    t0, f2                      // f2 = 0
        mul.s   f0, f0, f2                  // f0 = x velocity * 0
        swc1    f0, 0x0048(a2)              // x velocity = (x velocity * 0)

        _check_begin:
        lw      t0, 0x0184(a2)              // t0 = temp variable 3
        ori     t1, r0, BEGIN               // t1 = BEGIN
        bne     t0, t1, _check_initial      // skip if t0 != BEGIN
        nop
        // slow y movement
        lwc1    f0, 0x004C(a2)              // f0 = current y velocity
        lui     t0, 0x3F80                  // ~
        mtc1    t0, f2                      // f2 = 1
        mul.s   f0, f0, f2                  // f0 = x velocity * 1
        swc1    f0, 0x004C(a2)              // y velocity = (y velocity * 1)

        _check_initial:
        lw      t0, 0x017C(a2)              // t0 = temp variable 1
        beq     t0, r0, _end                // skip if temp variable 1 = 0
        nop
        // reset temp variable 2
        sw      r0, 0x017C(a2)              // temp variable 1 = 0
        // apply initial y velocity
        lui     t0, INITIAL_Y_SPEED         // ~
        sw      t0, 0x004C(a2)              // y velocity = INITIAL_Y_SPEED
        or      a0, a2, r0                  // a0 = player struct

        _end:
        lw      t0, 0x0004(sp)              // ~
        lw      t1, 0x0008(sp)              // ~
        lwc1    f0, 0x000C(sp)              // ~
        lwc1    f2, 0x0010(sp)              // load t0, t1, f0, f2
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles movement for Birdo's down special.
    // Prevents player control when temp variable 2 = 0
    // Prevents negative Y velocity when temp variable 3 = 1 (BEGIN)
    scope physics_: {
        // 0x180 in player struct = temp variable 2

        addiu   sp, sp,-0x0018              // allocate stack space
        sw      t0, 0x0004(sp)              // ~
        sw      t1, 0x0008(sp)              // ~
        sw    	ra, 0x000C(sp)              // ~
        sw      a0, 0x0010(sp)              // store t0, t1, ra, a0
        lw      t0, 0x0084(a0)              // t0 = player struct
        lw      t1, 0x0180(t0)              // t1 = temp variable 2
        li      t8, 0x800D90E0              // t8 = physics subroutine which allows player control
        bnez    t1, _subroutine             // skip if t1 != 0
        nop
        li      t8, 0x800D91EC              // t8 = physics subroutine which prevents player control

        _subroutine:
        jalr      t8                        // run physics subroutine
        nop

        _check_fall:
        lw      a0, 0x0010(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        lw      t0, 0x0184(a0)              // t0 = temp variable 3
        ori     t1, r0, BEGIN               // t1 = BEGIN
        bne     t0, t1, _check_move         // skip if temp variable 3 != BEGIN
        nop

        // Checks if the highest bit is set to 1, which is used to represent a negative floating
        // point value. If the highest bit is set to 1, sets y velocity to 0.
        lw      t0, 0x004C(a0)              // t0 = y velocity
        lui     t1, 0x8000                  // t1 = bitmask
        and     t1, t0, t1                  // t1 = 0 if y velocity is positive
        bnel    t1, r0, _end                // execute next instruction if y velocity is negative
        sw      r0, 0x004C(a0)              // y velocity = 0

        _check_move:
        lw      t0, 0x0184(a0)              // t0 = temp variable 3
        ori     t1, r0, MOVE                // t1 = MOVE
        bne     t0, t1, _end                // skip if t0 != MOVE
        nop
        // apply y velocity
        lui     t1, Y_SPEED                 // ~
        sw      t1, 0x004C(a0)              // y velocity = Y_SPEED
        

        _end:
        lw      t0, 0x0004(sp)              // ~
        lw      t1, 0x0008(sp)              // ~
        lw      ra, 0x000C(sp)              // ~
        lw      a0, 0x0010(sp)              // load t0, t1, ra, a0
        addiu 	sp, sp, 0x0018				// deallocate stack space
        jr      ra                          // return
        nop
    }
}