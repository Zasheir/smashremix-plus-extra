// YZeldaSpecial.asm

// This file contains subroutines used by Princess YZelda's special moves.

scope YZeldaNSP {

    // @ Description
    // Subroutine which runs when YZelda initiates a grounded neutral special.
    scope ground_begin_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra

        lw      a2, 0x0084(a0)              // ~
        lw      a2, 0x0008(a2)              // a2 = current character ID
        // lli     a1, Character.id.KIRBY      // a1 = id.KIRBY
        // beql    a1, a2, pc() + 24           // if Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Ground_Begin
        // lli     a1, Character.id.JKIRBY     // a1 = id.JKIRBY
        // beql    a1, a2, pc() + 12           // if J Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Ground_Begin

        lli     a1, YZelda.Action.NSP_Ground_Begin // a1(action id) = NSP_Ground_Begin
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
    // Subroutine which runs when YZelda initiates an aerial neutral special.
    scope air_begin_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra

        lw      a2, 0x0084(a0)              // ~
        lw      a2, 0x0008(a2)              // a2 = current character ID
        // lli     a1, Character.id.KIRBY      // a1 = id.KIRBY
        // beql    a1, a2, pc() + 24           // if Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Air_Begin
        // lli     a1, Character.id.JKIRBY     // a1 = id.JKIRBY
        // beql    a1, a2, pc() + 12           // if J Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Air_Begin

        lli     a1, YZelda.Action.NSP_Air_Begin // a1(action id) = NSP_Air_Begin
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
    // Subroutine which begins YZelda's grounded neutral special wait action.
    scope ground_wait_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra

        lw      a2, 0x0084(a0)              // ~
        lw      a2, 0x0008(a2)              // a2 = current character ID
        // lli     a1, Character.id.KIRBY      // a1 = id.KIRBY
        // beql    a1, a2, pc() + 24           // if Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Ground_Wait
        // lli     a1, Character.id.JKIRBY     // a1 = id.JKIRBY
        // beql    a1, a2, pc() + 12           // if J Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Ground_Wait

        lli     a1, YZelda.Action.NSP_Ground_Wait // a1(action id) = NSP_Ground_Wait
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lli     t6, 0x0800                  // ~
        jal     0x800E6F24                  // change action
        sw      t6, 0x0010(sp)              // argument 4 = 0x0800 (this flag continues FGM called with the 3C command)
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which begins YZelda's aerial neutral special wait action.
    scope air_wait_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra

        lw      a2, 0x0084(a0)              // ~
        lw      a2, 0x0008(a2)              // a2 = current character ID
        // lli     a1, Character.id.KIRBY      // a1 = id.KIRBY
        // beql    a1, a2, pc() + 24           // if Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Air_Wait
        // lli     a1, Character.id.JKIRBY     // a1 = id.JKIRBY
        // beql    a1, a2, pc() + 12           // if J Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Air_Wait

        lli     a1, YZelda.Action.NSP_Air_Wait // a1(action id) = NSP_Air_Wait
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lli     t6, 0x0800                  // ~
        jal     0x800E6F24                  // change action
        sw      t6, 0x0010(sp)              // argument 4 = 0x0800 (this flag continues FGM called with the 3C command)
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which begins YZelda's grounded neutral special ending action.
    scope ground_end_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra

        lw      a2, 0x0084(a0)              // ~
        lw      a2, 0x0008(a2)              // a2 = current character ID
        // lli     a1, Character.id.KIRBY      // a1 = id.KIRBY
        // beql    a1, a2, pc() + 24           // if Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Ground_End
        // lli     a1, Character.id.JKIRBY     // a1 = id.JKIRBY
        // beql    a1, a2, pc() + 12           // if J Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Ground_End

        lli     a1, YZelda.Action.NSP_Ground_End // a1(action id) = NSP_Ground_End
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
    // Subroutine which begins YZelda's aerial neural special ending action.
    scope air_end_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra

        lw      a2, 0x0084(a0)              // ~
        lw      a2, 0x0008(a2)              // a2 = current character ID
        // lli     a1, Character.id.KIRBY      // a1 = id.KIRBY
        // beql    a1, a2, pc() + 24           // if Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Air_End
        // lli     a1, Character.id.JKIRBY     // a1 = id.JKIRBY
        // beql    a1, a2, pc() + 12           // if J Kirby, load alternate action ID
        // lli     a1, Kirby.Action.CONKER_NSP_Air_End

        lli     a1, YZelda.Action.NSP_Air_End // a1(action id) = NSP_Ground_End
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
    // Main subroutine for NSP_Ground_Begin
    // If temp variable 2 is set by moveset, cancel with NSP_Ground_End when B is not held.
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
        jal     ground_end_initial_         // transition to NSP_Ground_End
        nop
        b       _end
        nop

        _check_end:
        li      a1, ground_wait_initial_    // a1(transition subroutine) = ground_wait_initial_
        jal     0x800D9480                  // common main subroutine (transition on animation end)
        nop

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Main subroutine for NSP_Air_Begin
    // If temp variable 2 is set by moveset, cancel with NSP_Ground_End when B is not held.
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
        jal     air_end_initial_            // transition to NSP_Air_End
        nop
        b       _end
        nop

        _check_end:
        li      a1, air_wait_initial_       // a1(transition subroutine) = air_wait_initial_
        jal     0x800D9480                  // common main subroutine (transition on animation end)
        nop

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Main subroutine for NSP_Ground_Wait
    scope ground_wait_main_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      v0, 0x0084(a0)              // v0 = player struct
        lh      t7, 0x01BC(v0)              // t7 = buttons_held
        andi    t7, t7, Joypad.B            // t7 = 0x0020 if (B_HELD); else t7 = 0
        bnez    t7, _end                    // branch if (B_HELD)
        nop

        // if we reach this point, the b button is not being held, so transition to ending action
        jal     ground_end_initial_         // transition to NSP_Ground_End
        nop

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Main subroutine for NSP_Air_Wait
    scope air_wait_main_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      v0, 0x0084(a0)              // v0 = player struct
        lh      t7, 0x01BC(v0)              // t7 = buttons_held
        andi    t7, t7, Joypad.B            // t7 = 0x0020 if (B_HELD); else t7 = 0
        bnez    t7, _end                    // branch if (B_HELD)
        nop

        // if we reach this point, the b button is not being held, so transition to ending action
        jal     air_end_initial_            // transition to NSP_Air_End
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
        lw      a0, 0x0940(v0)              // a0 = part 0xD (weapon) struct
        jal     0x800EDF24                  // returns x/y/z coordinates of the part in a0 to a1
        sw      v0, 0x002C(sp)              // 0x002C(sp) = player struct
        lwc1    f6, 0x0024(sp)              // f6 = y coordinate
        lui     t6, 0x4350                  // ~
        mtc1    t6, f8                      // f6 = 60
        add.s   f6, f6, f8                  // add 60 to y coordinate
        swc1    f6, 0x0024(sp)              // store updated y coordinate
        sw      r0, 0x0028(sp)              // set z coordinate to 0
        lw      v0, 0x002C(sp)              // v0 = player struct
        lw      a0, 0x0034(sp)              // a0 = player object
        jal     arrow_stage_setting_        // INITIATE ARROW
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
    // Subroutine which handles air collision for neutral special end
    scope air_collision_end_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      t9, 0x0078(a0)              // t9(starting frame) = current animation frame
        lui     t8, 0x40c0                  // insert amount of frames before conker fires (6)
        mtc1    t9, f2                      // move to floating point
        mtc1    t8, f4                      // move to floating point
        c.lt.s  f2, f4                      // compare current frame to see if equal or greater than (6)
        bc1fl   _fired                      // branch to collision process for NSP after firing
        nop
        li      a1, air_to_ground_          // a1(transition subroutine) = air_to_ground_
        jal     0x800DE6E4                  // common air collision subroutine (transition on landing, no ledge grab)
        nop
        b       _end                        // end subroutine
        nop

        _fired:
       jal      0x800DE978                  // air collision subroutine (cancel on landing)
       nop

        _end:
        lw      ra, 0x0014(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0020              // deallocate stack space
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
        addiu   a1, t7, 0x0003              // a1 = equivalent air action for current ground action (id + 3)
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
        addiu   a1, t7,-0x0003              // a1 = equivalent ground action for current air action (id - 3)
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
    scope arrow_stage_setting_: {
        constant MAX_POWER(4)
        addiu   sp, sp, -0x0050
        sw      s0, 0x0018(sp)
        li      s0, arrow_properties_struct   // s0 = projectile properties struct address
        sw      a1, 0x0034(sp)
        sw      ra, 0x001C(sp)
        lw      t6, 0x0084(a0)
        lw      t0, 0x0024(s0)
        lw      t1, 0x0028(s0)
        li      a1, arrow_projectile_struct   // a1 = main projectile struct address
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
        // calculate power level, check if max power has been reached, and store power level in the projectile struct
        lw      t6, 0x002C(sp)              // t6 = player struct
        lw      t6, 0x0184(t6)              // t6 = temp variable 3/power level (int)
        mtc1    t6, f8                      // ~
        cvt.s.w f8, f8                      // f8 = power level (float)
        swc1    f8, 0x01B4(v1)              // 0x01B4 in projectile struct = power level (float)
        lli     t5, MAX_POWER - 1           // ~
        sltu    t5, t5, t6                  // t5 = 1 if power level > MAX_POWER, else t5 = 0

        _fgm:
        // play an FGM, changes with power level
        beqz    t6, _play_fgm               // branch if power level = 0...
        lli     a0, YZelda.FGM.NSP_BOW_FAIL      // ..and load FGM id custom
        // if power level is above 0
        beqz    t5, _play_fgm               // branch if bool max_power = FALSE
        lli     a0, YZelda.FGM.NSP_BOW_SHOOT     // ..and load FGM id custom
        // if power level is above 0 and max_power = TRUE
        lli     a0, YZelda.FGM.NSP_BOW_FULL      // load FGM id custom

        _play_fgm:
        jal     FGM.play_                   // play FGM
        nop

        _hitbox:
        // adjust hitbox properties based on power level
        // t6 = power level (int), t5 = bool max_power
        lw      t7, 0x0104(v1)              // t7 = current hitbox damage
        sll     t8, t6, 0x1                 // t8 = power level * 2
        addu    t7, t7, t8                  // t7 = hitbox damage + (power level * 2)
        sw      t7, 0x0104(v1)              // add 2 damage per power level
        lli     t7, 3                       // ~
        sw      t7, 0x010C(v1)              // Damage Type = 3(Slash)
        lli     t7, 0x0106                  // t7 = 0x106
        sh      t7, 0x0146(v1)              // set on-hit FGM to 0x106
        lw      t7, 0x0130(v1)              // t7 = current hitbox kbg
        sll     t8, t6, 0x2                 // ~
        subu    t8, t8, t6                  // ~
        sll     t8, t8, 0x2                 // t8 = power level * 12
        addu    t7, t7, t8                  // t7 = hitbox kbg + (power level * 12)
        sw      t7, 0x0130(v1)              // add 16 kbg per power level
        lw      t7, 0x0138(v1)              // t7 = current hitbox bkb
        sll     t8, t6, 0x2                 // t8 = power level * 4
        addu    t7, t7, t8                  // t7 = hitbox bkb + (power level * 4)
        sw      t7, 0x0138(v1)              // add 4 bkb per power level
        beqz    t5, _speed                  // branch if bool max_power = FALSE
        lli     t7, 13                      // ~
        sw      t7, 0x010C(v1)              // Damage Type = 13(Light)
        lli     t7, YZelda.FGM.SFX_NSP_HIT_FULL   // t7 = Custom FGM
        // if bool max_power = TRUE
        sh      t7, 0x0146(v1)              // set on-hit FGM to Custom
        li      s0, light_arrow_properties_struct   // s0 = projectile properties struct address

        _speed:
        // adjust speed based on power level
        // f8 = power level (float)
        lui     t6, 0x4248                  // ~
        mtc1    t6, f6                      // f6 = 12
        mul.s   f6, f6, f8                  // f6 = bonus speed (power level * 12)
        swc1    f6, 0x0048(sp)              // 0x0048(sp) = bonus speed

        _angle:
        // adjust angle based on power level
        li      t6, 0x3C0EFA39              // ~
        mtc1    t6, f6                      // f6 = 0.00872665 rads (.5 degrees)
        mul.s   f6, f6, f8                  // f6 = angle adjustment (.5 degrees per power level)
        sub.s   f12, f12, f6                // f12 = adjusted angle (initial angle - adjustment)

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
    // Main subroutine for the arrow.
    scope arrow_main_: {
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
        li      v0, arrow_properties_struct   // v0 = arrow_properties_struct

        // lw      a1, 0x000C(v0)              // a1 = gravity
        // jal     0x80168088                  // apply gravity to arrow

        lwc1    f4, 0x01B4(a0)              // f4 = power level
        lui     t6, 0xBE1A                  // ~
        mtc1    t6, f8                      // f8 = -0.15
        mul.s   f4, f4, f8                  // f4 = power level * -0.15
        lui     t6, 0xBE80                  // ~
        mtc1    t6, f8                      // f8 = 1
        add.s   f4, f4, f8                  // f4 = 1 + (power level * -0.15)
        mul.s   f6, f6, f4                  // decrease rotation speed by 15% per power level
        lwc1    f6, 0x000C(v0)              // f6 = gravity
        add.s   f6, f4, f6                  // add -0.15 to gravity?
        mfc1    a1, f6                      // register f6 to a1
        jal     0x80168088                  // apply gravity to arrow

        lw      a2, 0x0004(v0)              // a2 = max speed
        lw      a0, 0x001C(sp)              // a0 = projectile struct
        lw      t1, 0x0020(sp)              // t1 = projectile object
        lw      v1, 0x0074(t1)              // v1 = projectile struct with coordinates/rotation etc (bone struct?)
        li      at, arrow_properties_struct   // at = arrow properties struct
        lwc1    f6, 0x0014(at)              // f6 = rotation speed
        lwc1    f4, 0x01B4(a0)              // f4 = power level
        lui     t6, 0xBE1A                  // ~
        mtc1    t6, f8                      // f8 = -0.15
        mul.s   f4, f4, f8                  // f4 = power level * -0.15
        lui     t6, 0x3F1A                  // ~
        mtc1    t6, f8                      // f8 = 1
        add.s   f4, f4, f8                  // f4 = 1 + (power level * -0.15)
        mul.s   f6, f6, f4                  // decrease rotation speed by 15% per power level
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
    // This subroutine destroys the arrow and creates a smoke gfx.
    scope arrow_destruction_: {
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

    OS.align(16)
    arrow_projectile_struct:
    constant ARROW_ID(0x1001)
    dw 0x00000000                           // unknown
    dw ARROW_ID                               // projectile id
    dw Character.YZELDA_file_6_ptr          // address of YZelda's file 6 pointer
    dw 0x00000000                           // offset to hitbox
    dw 0x12470000                           // This determines z axis rotation? (samus is 1246)
    dw arrow_main_                            // This is the main subroutine for the projectile, handles duration and other things. (default 0x80168540) (samus 0x80168F98)
    dw 0x80175914                           // This function runs when the projectile collides with clipping. (0x801685F0 - Mario) (0x80169108 - Samus)
    dw arrow_destruction_                     // This function runs when the projectile collides with a hurtbox.
    dw arrow_destruction_                     // This function runs when the projectile collides with a shield.
    dw 0x801686F8                           // This function runs when the projectile collides with edges of a shield and bounces off
    dw arrow_destruction_                     // This function runs when the projectile collides/clangs with a hitbox.
    dw 0x801692C4                           // This function runs when the projectile collides with Fox's reflector (default 0x80168748)
    dw arrow_destruction_                     // This function runs when the projectile collides with Ness's psi magnet
    OS.copy_segment(0x103904, 0x0C)         // empty

    OS.align(16)
    arrow_properties_struct:
    dw 90                                   // 0x0000 - duration (int)
    float32 200                             // 0x0004 - max speed
    float32 0                               // 0x0008 - min speed
    float32 0.75                            // 0x000C - gravity
    float32 0                               // 0x0010 - bounce multiplier
    float32 0.025                           // 0x0014 - rotation speed
    float32 0                               // 0x0018 - initial angle (ground)
    float32 0                               // 0x001C   initial angle (air)
    float32 40                              // 0x0020   initial speed
    dw Character.YZELDA_file_6_ptr          // 0x0024   projectile data pointer
    dw 0x00000000                           // 0x0028   unknown (default 0)
    float32 0                               // 0x002C   palette index (0 = mario, 1 = luigi)

    OS.align(16)
    light_arrow_properties_struct:
    dw 90                                   // 0x0000 - duration (int)
    float32 220                             // 0x0004 - max speed
    float32 0                               // 0x0008 - min speed
    float32 0.75                            // 0x000C - gravity
    float32 0                               // 0x0010 - bounce multiplier
    float32 0.02                            // 0x0014 - rotation speed
    float32 0.1                               // 0x0018 - initial angle (ground)
    float32 0.1                               // 0x001C   initial angle (air)
    float32 50                              // 0x0020   initial speed
    dw Character.YZELDA_file_6_ptr          // 0x0024   projectile data pointer
    dw 0x00000000                           // 0x0028   unknown (default 0)
    float32 1                               // 0x002C   palette index (0 = mario, 1 = luigi)
}

// Subroutines for Up Special
scope YZeldaUSP {
    constant DEFAULT_ANGLE(0x3FC90FDB) // float 1.570796 rads
    constant LANDING_FSM(0x3fBD3000) // float 0.37 (makes it 30 frames)
    constant INITIAL_SPEED(0x0000) // float 0
    constant SPEED(0x0000) // float 0
    constant BASE_SPEED(0x3F00)  // float: 0.5
    constant DECELERATION_FACTOR(0x4120) // float: 10
    constant TURN_SPEED(0x3D99999A) // float: 0.075 rads/3 degree
    constant DURATION(75)

    // @ Description
    // Subroutine which controls movement during Slippy's up special.
    scope movement_physics_: {
        addiu   sp, sp,-0x0040              // allocate stack space
        sw      ra, 0x0014(sp)              // ~
        sw      a0, 0x0020(sp)              // ~
        sw      s0, 0x0024(sp)              // store ra, a0, s0
        lw      s0, 0x0084(a0)              // s0 = player struct
        lw      t7, 0x0B28(s0)              // t7 = frame counter
        addiu   t7, t7, 0x0001              // increment frame counter
        slti    at, t7, 0x0002              // ~
        bnez    at, _end                    // skip if first frame of movement (replicated from firefox)
        sw      t7, 0x0B28(s0)              // store updated frame counter

        _get_stick_angle:
        lb      t0, 0x01C2(s0)              // t0 = stick_x
        lb      t1, 0x01C3(s0)              // t1 = stick_y
        lw      t2, 0x0044(s0)              // t2 = direction
        multu   t0, t2                      // ~
        mflo    t0                          // t0 = stick_x * direction
        mtc1    t1, f12                     // ~
        mtc1    t0, f14                     // ~
        cvt.s.w f12, f12                    // f12 = stick y
        cvt.s.w f14, f14                    // f14 = stick x * direction
        mul.s   f8, f12, f12                // ~
        mul.s   f10, f14, f14               // ~
        add.s   f8, f8, f10                 // ~
        sqrt.s  f8, f8                      // f8 = absolute stick x/y
        lui     at, 0x4120                  // ~
        mtc1    at, f6                      // f6 = 10
        c.le.s  f6, f8                      // ~
        nop                                 // ~
        bc1fl   _calculate_speed            // skip if absolute stick < 0...
        lwc1    f10, 0x0B20(s0)             // ...and set new angle to previous angle

        jal     0x8001863C                  // f0 = atan2(f12,f14)
        nop
        mov.s   f12, f0                     // f12 = stick angle

        _get_turn_angle:
        mtc1    r0, f0                      // f0 = 0
        li      at, 0x40C90FE4              // ~
        mtc1    at, f2                      // f2 = 6.28319 rads/360 degrees
        li      at, 0xC0490FD0              // ~
        mtc1    at, f4                      // f4 = -3.14159 rads/-180 degrees
        li      at, TURN_SPEED              // ~
        mtc1    at, f6                      // f6 = TURN_SPEED
        lwc1    f10, 0x0B20(s0)             // f10 = current movement angle
        sub.s   f8, f12, f10                // f8 = angle difference: stick angle - current angle
        c.lt.s  f4, f8                      // ~
        nop                                 // ~
        bc1fl   _calculate_turn             // branch if angle difference < -180...
        add.s   f8, f8, f2                  // ...and add 360 degrees to angle differnece

        _calculate_turn:
        abs.s   f14, f8                     // f14 = absolute angle difference
        c.lt.s  f6, f14                     // ~
        nop                                 // ~
        bc1fl   _update_angle               // branch and immediately update if absolute angle difference < TURN_SPEED...
        mov.s   f10, f12                    // ...and set movement angle to stick angle
        c.lt.s  f0, f8                      // ~
        nop                                 // ~
        bc1fl   _apply_turn                 // branch if angle difference < 0...
        neg.s   f6, f6                      // ...and set f6 to -TURN_SPEED

        _apply_turn:
        add.s   f10, f10, f6                // f10 = previous angle + TURN_SPEED

        _update_angle:
        c.lt.s  f4, f10                     // ~
        nop                                 // ~
        bc1fl   _calculate_speed            // branch if new movement angle < -180...
        add.s   f10, f10, f2                // ...and add 360 degrees to movement angle

        _calculate_speed:
        swc1    f10, 0x0B20(s0)             // store updated movement angle
        lui     at, 0x420C                  // ~
        mtc1    at, f2                      // f2 = 35
        lwc1    f4, 0x0B24(s0)              // ~
        cvt.s.w f4, f4                      // f4 = duration remaining
        add.s   f4, f2, f2                  // f4 = 35 + 35
        lui     at, BASE_SPEED              // ~
        mtc1    at, f6                      // ~
        mul.s   f4, f6, f4                  // f4 = SPEED: BASE_SPEED * multiplier
        swc1    f4, 0x0030(sp)              // 0x0030(sp) = SPEED


        _apply_movement:
        // ultra64 cosf function
        jal     0x80035CD0                  // f0 = cos(f12)
        lwc1    f12, 0x0B20(s0)             // f12 = movement angle
        lwc1    f4, 0x0030(sp)              // f4 = SPEED
        mul.s   f4, f4, f0                  // f4 = x velocity (SPEED * cos(angle))
        swc1    f4, 0x0034(sp)              // 0x0034(sp) = x velocity
        // ultra64 sinf function
        jal     0x800303F0                  // f0 = sin(f12)
        lwc1    f12, 0x0B20(s0)             // f12 = movement angle
        lwc1    f4, 0x0030(sp)              // f4 = SPEED
        mul.s   f4, f4, f0                  // f4 = y velocity (SPEED * sin(angle))
        lwc1    f0, 0x0044(s0)              // ~
        cvt.s.w f0, f0                      // f0 = direction
        lwc1    f2, 0x0034(sp)              // f2 = x velocity
        mul.s   f2, f2, f0                  // f2 = x velocity * direction
        swc1    f2, 0x0048(s0)              // store updated x velocity
        swc1    f4, 0x004C(s0)              // store updated y velocity

        _end:
        jal     0x8015C054                  // unknown final firefox subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      ra, 0x0014(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0040              // deallocate stack space
    }

    // @ Description
    // Subroutine which runs when YZelda initiates a grounded up special.
    scope ground_begin_initial_: {
        addiu   sp, sp,-0x0030              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lli     a1, YZelda.Action.USPA_BEGIN // a1(action id) = USP_Ground_Begin
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
        lui     t0, 0x3F00                  // ~
        mtc1    t0, f0                      // f0 = 0.5
        lwc1    f2, 0x0060(a0)              // f2 = x velocity
        mul.s   f2, f2, f0                  // ~
        swc1    f2, 0x0060(a0)              // multiply x velocity by 0.5 and update
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0030              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which runs when YZelda initiates an aerial up special.
    scope air_begin_initial_: {
        addiu   sp, sp,-0x0030              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lli     a1, YZelda.Action.USPA_BEGIN // a1(action id) = USP_Air_Begin
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
        lui     t0, 0x3F00                  // ~
        mtc1    t0, f0                      // f0 = 0.5
        lwc1    f2, 0x0048(a0)              // f2 = x velocity
        mul.s   f2, f2, f0                  // ~
        swc1    f2, 0x0048(a0)              // multiply x velocity by 0.5 and update
        lui     at, INITIAL_SPEED           // at = INITIAL_SPEED
        sw      at, 0x004C(a0)              // y velocity = INITIAL_SPEED
        // freeze y position
        lw      v1, 0x09C8(a0)              // v1 = attribute pointer
        lw      v1, 0x0058(v1)              // v1 = gravity
        sw      v1, 0x004C(a0)              // y velocity = gravity
        lbu     v1, 0x018D(a0)              // v1 = fast fall flag
        ori     t6, r0, 0x0007              // t6 = bitmask (01111111)
        and     v1, v1, t6                  // ~
        sb      v1, 0x018D(a0)              // disable fast fall flag
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0030              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // Main subroutine for USP_Ground_Begin and USP_Air_Begin
    scope begin_main_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      t8, 0x014C(a2)              // t8 = kinetic state
        li      a1, move_initial_           // a1(transition subroutine) = move_initial_
        jal     0x800D9480                  // common main subroutine (transition on animation end)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Collision subroutine for USP_Ground_Begin.
    scope ground_begin_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, air_begin_transition_   // a1(transition subroutine) = air_begin_transition_
        jal     0x800DDE84                  // common ground collision subroutine (transition on no floor, no slide-off)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Collision subroutine for USP_Air_Begin.
    scope air_begin_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        sw      a0, 0x0010(sp)              // save object
        sw      s1, 0x0008(sp)
        sw      a1, 0x000c(sp)

        _first:
        li      a1, ground_begin_transition_ // a1(transition subroutine) = ground_begin_transition_
        jal     0x800DE80C                  // common air collision subroutine (transition on landing, allow ledge grab)
        nop

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Physics subroutine for USP_Air_Begin.
    scope air_begin_physics_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      s0, 0x0014(sp)              // ~
        sw      s1, 0x0018(sp)              // original store registers
        sw      a1, 0x000C(sp)              // ~
        sw      ra, 0x0014(sp)              // ~
        lw      s0, 0x0084(a0)              // load player struct
        lw      t6, 0x0180(s0)              // load variable 2
        lw      s1, 0x09C8(s0)              // load attribute pointer
        or      a0, s0, r0                  // place player struct into a0
        beqz    t6, _no_drift               // branch if variable not active yet
        or      a1, s1, r0                  // place attribute pointer into a1

        addiu   a1, r0, 0x0008              // a1 = 0x8 (original line)
        lw      a2, 0x004C(s1)              // a2 = air acceleration
        lw      a3, 0x0050(s1)              // a3 = max air speed

        _continue:
        jal     0x800D8FC8                  // air drift subroutine?
        nop

        _no_drift:
        jal     0x800D8E50                  // set vertical velocity
        or      a1, s1, r0
        or      a0, s0, r0
        jal     0x800D8FA8
        or      a1, s1, r0
        bnez    v0, _end
        or      a0, s0, r0
        jal     0x800D9074                  // apply air friction
        or      a1, s1, r0

        _end:
        lw      a1, 0x000C(sp)
        lw      ra, 0x001C(sp)              // ~
        lw      s0, 0x0014(sp)
        lw      s1, 0x0018(sp)
        jr      ra                          // return
        addiu   sp, sp, 0x0020              // deallocate stack space
    }

    // @ Description
    // Subroutine which transitions to USP_Ground_Begin.
    scope ground_begin_transition_: {
        addiu   sp, sp,-0x0050              // allocate stack space
        sw      ra, 0x001C(sp)              // store ra
        sw      a0, 0x0038(sp)              // 0x0038(sp) = player object
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800DEE98                  // set grounded state
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player struct
        lw      a0, 0x0038(sp)              // a0 = player object
        lli     a1, YZelda.Action.USPG_BEGIN // a1(action id) = USP_Ground_Begin
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0050              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which transitions to USP_Air_Begin.
    scope air_begin_transition_: {
        addiu   sp, sp,-0x0050              // allocate stack space
        sw      ra, 0x001C(sp)              // store ra
        sw      a0, 0x0038(sp)              // 0x0038(sp) = player object
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800DEEC8                  // set aerial state
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player struct
        lw      a0, 0x0038(sp)              // a0 = player object
        lli     a1, YZelda.Action.USPA_BEGIN // a1(action id) = USP_Air_Begin
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800D8EB8                  // momentum capture?
        lw      a0, 0x0034(sp)              // a0 = player struct
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0050              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which begins YZelda's up special movement actions.
    scope move_initial_: {
        addiu   sp, sp,-0x0040              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // ~
        sw      s0, 0x0024(sp)              // store a0, s0, ra
        lw      s0, 0x0084(a0)              // s0 = player struct
        lb      v0, 0x01C2(s0)              // v0 = stick_x
        bltzl   v0, _check_turnaround       // branch if stick_x is negative...
        subu    v0, r0, v0                  // ...and make stick_x positive

        _check_turnaround:
        // v0 = absolute stick_x
        slti    at, v0, 0x000B              // at = 1 if absolute stick_x < 11, else at = 0
        bnez    at, _check_deadzone         // skip if absolute stick_x < 11
        nop
        jal     0x800E8044                  // apply turnaround
        or      a0, s0, r0                  // a0 = player struct

        _check_deadzone:
        lw      t8, 0x014C(s0)              // t8 = kinetic state
        sw      t8, 0x0028(sp)              // 0x0028(sp) = kinetic state
        lb      t0, 0x01C2(s0)              // t0 = stick_x
        lb      t1, 0x01C3(s0)              // t1 = stick_y
        multu   t0, t0                      // ~
        mflo    t2                          // t2 = stick_x ^ 2
        multu   t1, t1                      // ~
        mflo    t3                          // t3 = stick_y ^ 2
        addu    t2, t2, t3                  // ~
        mtc1    t2, f12                     // ~
        cvt.s.w f12, f12                    // ~
        sqrt.s  f12, f12                    // f12 = absolute stick input
        cvt.w.s f12, f12                    // ~
        mfc1    t2, f12                     // t2 = absolute stick input (int)
        slti    at, t2, 0x000B              // at(use_default_angle) = 1 if absolute stick < 11, else at = 0
        sw      at, 0x002C(sp)              // 0x002C(sp) = use_default_angle
        bnez    at, _aerial                 // branch if use_default_angle = 1
        nop

        bnez    t8, _change_action          // skip if kinetic state !grounded
        lli     a1, YZelda.Action.USPA_MOVE // a1(action id) = USPA_MOVE

        _grounded:
        lb      t0, 0x01C3(s0)              // t0 = stick_y
        bnez    t0, _aerial                 // branch if stick_y = 0
        lli     a1, YZelda.Action.USPA_MOVE // a1(action id) = USPA_MOVE
        lb      t0, 0x01C2(s0)              // t0 = stick_x
        beqz    t0, _aerial                 // branch if stick_x = 0
        lli     a1, YZelda.Action.USPA_MOVE // a1(action id) = USPA_MOVE

        _aerial:
        jal     0x800DEEC8                  // set aerial state
        or      a0, s0, r0                  // a0 = player struct
        lli     a1, YZelda.Action.USPA_MOVE // a1(action id) = USPA_MOVE

        _change_action:
        sw      r0, 0x0060(s0)              // ground x velocity = 0
        sw      r0, 0x0048(s0)              // x velocity = 0
        sw      r0, 0x004C(s0)              // y velocity = 0
        lw      a0, 0x0020(sp)              // a0 = player object
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object

        // take mid-air jumps away at this point
        lw      t0, 0x09C8(s0)              // t0 = attribute pointer
        lw      t0, 0x0064(t0)              // t0 = max jumps
        sb      t0, 0x0148(s0)              // jumps used = max jumps
        li      t0, DEFAULT_ANGLE           // t0 = DEFAULT_ANGLE
        lw      at, 0x002C(sp)              // at = use_default_angle
        sw      t0, 0x0B20(s0)              // store DEFAULT_ANGLE

        _continue:
        lb      t0, 0x01C2(s0)              // t0 = stick_x
        lb      t1, 0x01C3(s0)              // t1 = stick_y
        lw      t2, 0x0044(s0)              // t2 = direction
        multu   t0, t2                      // ~
        mflo    t0                          // t0 = stick_x * direction
        mtc1    t1, f12                     // ~
        mtc1    t0, f14                     // ~
        cvt.s.w f12, f12                    // f12 = stick y
        jal     0x8001863C                  // f0 = atan2(f12,f14)
        cvt.s.w f14, f14                    // f14 = stick x * direction
        swc1    f0, 0x0B20(s0)              // store movement angle

        _visibility:
        lbu     at, 0x018D(s0)              // at = bit field
        ori     at, at, 0x0001              // enable bitflag for invisibility
        sb      at, 0x018D(s0)              // update bit field
        li      t0, CharEnvColor.moveset_table
        lbu     t1, 0x000D(s0)              // t1 = port
        sll     t1, t1, 0x0002              // t1 = offset to env color override value
        addu    t0, t0, t1                  // t0 = address of env color override value
        li      t1, 0xFFFFFF00              // env color for full transparency
        sw      t1, 0x0000(t0)              // store updated env color

        _intangibility:
        lli     t0, 0x0003                  // ~
        sb      t0, 0x05BB(s0)              // set hurtbox state to 0x0003(intangible)

        _platform:
        lw      at, 0x0028(sp)              // at = kinetic state
        bnez    at, _end                    // skip if kinetic state was !grounded
        nop

        // if the original kinetic state was grounded, this will allow dropping through platforms
        lw      t8, 0x00EC(s0)              // t8 = platform ID
        sw      t8, 0x0144(s0)              // allows pass through given ID?


        _end:
        lw      ra, 0x001C(sp)              // ~
        lw      s0, 0x0024(sp)              // load s0
        addiu   sp, sp, 0x0040              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Main subroutine for USPG_MOVE and USPA_MOVE.
    scope move_main_: {
        addiu   sp, sp,-0x0030              // allocate stack space
        sw      ra, 0x001C(sp)              // store
        lw      v0, 0x0084(a0)              // v0 = player struct
        lw      t6, 0x0B18(v0)              // t6 = movement timer
        addiu   t6, t6,-0x0001              // decrement timer
        bnez    t6, _end                    // skip if timer !0
        sw      t6, 0x0B18(v0)              // update movement timer

        // If we're here, then the movement timer has ended, so transition to ending animation
        lw      t6, 0x014C(v0)              // t6 = kinetic state
        bnez    t6, _aerial                 // branch if kinetic state !grounded
        nop

        _grounded:
        jal     air_end_initial_            // transition to USPG_END
        nop
        b       _end                        // end
        nop

        _aerial:
        jal     air_end_initial_            // transition to USPA_END
        nop

        _end:
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0030              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Physics subroutine for USPG_MOVE and USPA_MOVE.
    scope move_physics_: {
        addiu   sp, sp,-0x0040              // allocate stack space
        sw      ra, 0x0014(sp)              // ~
        sw      a0, 0x0020(sp)              // ~
        sw      s0, 0x0024(sp)              // store ra, a0, s0
        lw      s0, 0x0084(a0)              // s0 = player struct
        lw      t7, 0x0B28(s0)              // t7 = frame counter
        addiu   t7, t7, 0x0001              // increment frame counter
        slti    at, t7, 0x0002              // ~
        bnez    at, _end                    // skip if first frame of movement (replicated from firefox)
        sw      t7, 0x0B28(s0)              // store updated frame counter

        _get_stick_angle:
        lb      t0, 0x01C2(s0)              // t0 = stick_x
        lb      t1, 0x01C3(s0)              // t1 = stick_y
        lw      t2, 0x0044(s0)              // t2 = direction
        multu   t0, t2                      // ~
        mflo    t0                          // t0 = stick_x * direction
        mtc1    t1, f12                     // ~
        mtc1    t0, f14                     // ~
        cvt.s.w f12, f12                    // f12 = stick y
        cvt.s.w f14, f14                    // f14 = stick x * direction
        mul.s   f8, f12, f12                // ~
        mul.s   f10, f14, f14               // ~
        add.s   f8, f8, f10                 // ~
        sqrt.s  f8, f8                      // f8 = absolute stick x/y
        lui     at, 0x4120                  // ~
        mtc1    at, f6                      // f6 = 10
        c.le.s  f6, f8                      // ~
        nop                                 // ~
        bc1fl   _calculate_speed            // skip if absolute stick < 0...
        lwc1    f10, 0x0B20(s0)             // ...and set new angle to previous angle

        jal     0x8001863C                  // f0 = atan2(f12,f14)
        nop
        mov.s   f12, f0                     // f12 = stick angle

        _get_turn_angle:
        mtc1    r0, f0                      // f0 = 0
        li      at, 0x40C90FE4              // ~
        mtc1    at, f2                      // f2 = 6.28319 rads/360 degrees
        li      at, 0xC0490FD0              // ~
        mtc1    at, f4                      // f4 = -3.14159 rads/-180 degrees
        li      at, TURN_SPEED              // ~
        mtc1    at, f6                      // f6 = TURN_SPEED
        lwc1    f10, 0x0B20(s0)             // f10 = current movement angle
        sub.s   f8, f12, f10                // f8 = angle difference: stick angle - current angle
        c.lt.s  f4, f8                      // ~
        nop                                 // ~
        bc1fl   _calculate_turn             // branch if angle difference < -180...
        add.s   f8, f8, f2                  // ...and add 360 degrees to angle differnece

        _calculate_turn:
        abs.s   f14, f8                     // f14 = absolute angle difference
        c.lt.s  f6, f14                     // ~
        nop                                 // ~
        bc1fl   _update_angle               // branch and immediately update if absolute angle difference < TURN_SPEED...
        mov.s   f10, f12                    // ...and set movement angle to stick angle
        c.lt.s  f0, f8                      // ~
        nop                                 // ~
        bc1fl   _apply_turn                 // branch if angle difference < 0...
        neg.s   f6, f6                      // ...and set f6 to -TURN_SPEED

        _apply_turn:
        add.s   f10, f10, f6                // f10 = previous angle + TURN_SPEED

        _update_angle:
        c.lt.s  f4, f10                     // ~
        nop                                 // ~
        bc1fl   _calculate_speed            // branch if new movement angle < -180...
        add.s   f10, f10, f2                // ...and add 360 degrees to movement angle

        _calculate_speed:
        swc1    f10, 0x0B20(s0)             // store updated movement angle
        lui     at, 0x3F80                  // ~
        mtc1    at, f2                      // f2 = 1
        lwc1    f4, 0x0B24(s0)              // ~
        cvt.s.w f4, f4                      // f4 = duration remaining
        add.s   f4, f4, f2                  // f4 = duration remaining + 1
        lui     at, DECELERATION_FACTOR     // ~
        mtc1    at, f6                      // f6 = DECELERATION_FACTOR
        div.s   f4, f4, f6                  // ~
        add.s   f4, f4, f2                  // f4 = speed multiplier: 1 + (duration remaining / DECELERATION_FACTOR)
        lui     at, BASE_SPEED              // ~
        mtc1    at, f6                      // ~
        mul.s   f4, f6, f4                  // f4 = SPEED: BASE_SPEED * multiplier
        swc1    f4, 0x0030(sp)              // 0x0030(sp) = SPEED


        _apply_movement:
        // ultra64 cosf function
        jal     0x80035CD0                  // f0 = cos(f12)
        lwc1    f12, 0x0B20(s0)             // f12 = movement angle
        lwc1    f4, 0x0030(sp)              // f4 = SPEED
        mul.s   f4, f4, f0                  // f4 = x velocity (SPEED * cos(angle))
        swc1    f4, 0x0034(sp)              // 0x0034(sp) = x velocity
        // ultra64 sinf function
        jal     0x800303F0                  // f0 = sin(f12)
        lwc1    f12, 0x0B20(s0)             // f12 = movement angle
        lwc1    f4, 0x0030(sp)              // f4 = SPEED
        mul.s   f4, f4, f0                  // f4 = y velocity (SPEED * sin(angle))
        lwc1    f0, 0x0044(s0)              // ~
        cvt.s.w f0, f0                      // f0 = direction
        lwc1    f2, 0x0034(sp)              // f2 = x velocity
        mul.s   f2, f2, f0                  // f2 = x velocity * direction
        swc1    f2, 0x0048(s0)              // store updated x velocity
        swc1    f4, 0x004C(s0)              // store updated y velocity

        _end:
        jal     0x8015C054                  // unknown final firefox subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      ra, 0x0014(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0040              // deallocate stack space
    }

    // @ Description
    // Collision subroutine for USPA_MOVE.
    scope air_move_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, air_move_transition_ // a1(transition subroutine) = ground_move_transition_
        jal     0x800DE80C                  // common air collision subroutine (transition on landing, allow ledge grab)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Collision subroutine for USPG_MOVE.
    scope ground_move_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, air_move_transition_    // a1(transition subroutine) = air_move_transition_
        jal     0x800DDDDC                  // common ground collision subroutine (transition on no floor, slide-off)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which transitions to USPA_MOVE.
    scope air_move_transition_: {
        addiu   sp, sp,-0x0050              // allocate stack space
        sw      ra, 0x001C(sp)              // store ra
        sw      a0, 0x0038(sp)              // 0x0038(sp) = player object
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800DEEC8                  // set aerial state
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player struct

        _visibility:
        lbu     at, 0x018D(a0)              // at = bit field
        ori     at, at, 0x0001              // enable bitflag for invisibility
        sb      at, 0x018D(a0)              // update bit field
        li      t0, CharEnvColor.moveset_table
        lbu     t1, 0x000D(a0)              // t1 = port
        sll     t1, t1, 0x0002              // t1 = offset to env color override value
        addu    t0, t0, t1                  // t0 = address of env color override value
        li      t1, 0xFFFFFF00              // env color for full transparency
        sw      t1, 0x0000(t0)              // store updated env color

        _intangibility:
        lli     t0, 0x0003                  // ~
        sb      t0, 0x05BB(a0)              // set hurtbox state to 0x0003(intangible)

        _end:
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0050              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which begins YZelda's grounded up special ending action.
    scope ground_end_initial_: {
        addiu   sp, sp,-0x0030              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lli     a1, YZelda.Action.USPG_END // a1(action id) = USPG_END
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        lui     t0, 0x3E80                  // ~
        mtc1    t0, f0                      // f0 = 0.25
        lwc1    f2, 0x0060(a0)              // f2 = x velocity
        mul.s   f2, f2, f0                  // ~
        swc1    f2, 0x0060(a0)              // multiply x velocity by 0.25 and update
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0030              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which begins YZelda's aerial up special ending action.
    scope air_end_initial_: {
        addiu   sp, sp,-0x0030              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lli     a1, YZelda.Action.USPA_END  // a1(action id) = USPA_END
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        lui     t0, 0x3F40                  // ~
        mtc1    t0, f0                      // f0 = 0.75
        lwc1    f2, 0x0048(a0)              // f2 = x velocity
        mul.s   f2, f2, f0                  // ~
        swc1    f2, 0x0048(a0)              // multiply x velocity by 0.75 and update
        lwc1    f2, 0x004C(a0)              // f2 = y velocity
        mul.s   f2, f2, f0                  // ~
        swc1    f2, 0x004C(a0)              // multiply y velocity by 0.75 and update
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0030              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Main subroutine for USPA_END.
    // Transitions to special fall on animation end, and makes the character invisible if temp variable 3 is set.
    scope air_end_main_: {
        addiu   sp, sp,-0x0030              // allocate stack space
        sw      ra, 0x0024(sp)              // store ra

        lw      v1, 0x0084(a0)              // v1 = player struct
        lw      t6, 0x017C(v1)              // t6 = temp variable 1
        lli     at, 0x0001                  // ~
        lli     at, 0x0002                  // ~

        _end:
        lw      ra, 0x0024(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0030              // deallocate stack space
        nop
    }

    // @ Description
    // Subroutine which allows a direction change for Marth's up special.
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
        jr      ra                          // return
        addiu   sp, sp, 0x0010              // deallocate stack space
    }

    // @ Description
    // Main subroutine for USPG_END.
    // Transitions to idle on animation end, and makes the character invisible if temp variable 3 is set.
    scope ground_end_main_: {
        addiu   sp, sp,-0x0030              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra

        jal     end_invisibility_           // check for invisibility
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800D94C4                  // check for idle transition
        lw      a0, 0x0020(sp)              // a0 = player object

        _end:
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0030              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which makes the character invisible if temp variable 3 is set during up special ending actions.
    // a0 - player struct
    scope end_invisibility_: {
        lbu     at, 0x018D(a0)              // at = bit field
        lw      t0, 0x0184(a0)              // t0 = temp variable 3
        beqz    t0, _end                    // branch if temp variable 3 = 0
        andi    at, at, 0xFFFE              // disable bitflag for invisibility
        // if temp variable 3 is set
        ori     at, at, 0x0001              // enable bitflag for invisibility

        _end:
        jr      ra                          // return
        sb      at, 0x018D(a0)              // update bit field
    }

    // @ Description
    // Collision subroutine for USPG_END and USPA_END.
    // Based on subroutine 0x8015DD58, which is the collision subroutine for Samus' up special.
    // Modified to load YZelda's landing FSM value.
    scope end_collision_: {
        // Copy the first 26 lines of subroutine 0x8015DD58
        OS.copy_segment(0xD8798, 0x68)
        lli     a1, OS.FALSE                // interrupt flag = FALSE
        lui     a2, LANDING_FSM >> 16       // load upper 2 bytes of LANDING_FSM
        // Copy the next 7 lines
        OS.copy_segment(0xD8808, 0x1C)
        jal     0x80142E3C                  // original line, landing transition
        addiu   a2, a2, LANDING_FSM & 0xFFFF// load lower 2 bytes of LANDING_FSM
        b       _end                        // end
        lw      ra, 0x0014(sp)              // load ra

        _grounded:
        jal     0x800DDEE8                  // grounded subroutine
        nop
        lw      ra, 0x0014(sp)

        _end:
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    scope end_air_collision_: {
    addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, air_end_transition_ // a1(transition subroutine) = air_end_transition_
        jal     0x800DE80C                  // common air collision subroutine (transition on landing, allow ledge grab)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    scope air_end_transition_: {
        addiu   sp, sp,-0x0050              // allocate stack space
        sw      ra, 0x001C(sp)              // store ra
        sw      a0, 0x0038(sp)              // 0x0038(sp) = player object
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800DEE98                  // set grounded state
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player struct
        lw      a0, 0x0038(sp)              // a0 = player object
        lli     a1, YZelda.Action.USPG_END // a1(action id) = USPG_END
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        ori     t7, r0, 0x0003              // t7 = 0x0003 (hitbox persist)
        jal     0x800E6F24                  // change action
        sw      t7, 0x0010(sp)              // argument 4 = 0

        _end:
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0050              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which applies movement to YZelda's up special based on the angle stored at 0x0B20 in the player struct.
    // a0 - player struct
    scope apply_movement_: {
        addiu   sp, sp,-0x0040              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      t1, 0xB18(a0)               // load timer
        slti    t1, t1, 0x0030              // shift to determine if enough time has passed to move_initial_
        beqz    t1, _end                    // if not enough time, skip movement

        lui     at, SPEED                   // ~
        sw      at, 0x0018(sp)              // 0x0018(sp) = SPEED
        lw      at, 0x0B20(a0)              // ~
        sw      at, 0x001C(sp)              // 0x001C(sp) = movement angle
        sw      a0, 0x0020(sp)              // 0x0020(sp) = player struct

        // ultra64 cosf function
        jal     0x80035CD0                  // f0 = cos(f12)
        lwc1    f12, 0x001C(sp)             // f12 = movement angle
        lwc1    f4, 0x0018(sp)              // f4 = SPEED
        mul.s   f4, f4, f0                  // f4 = x velocity (SPEED * cos(angle))
        swc1    f4, 0x0024(sp)              // 0x0024(sp) = x velocity
        // ultra64 sinf function
        jal     0x800303F0                  // f0 = sin(f12)
        lwc1    f12, 0x001C(sp)             // f12 = movement angle
        lwc1    f4, 0x0018(sp)              // f4 = SPEED
        mul.s   f4, f4, f0                  // f4 = y velocity (SPEED * sin(angle))

        lw      at, 0x0020(sp)              // at = player struct
        lw      t0, 0x014C(at)              // t0 = kinetic state
        bnez    t0, _aerial                 // branch if kinetic state !grounded
        lwc1    f2, 0x0024(sp)              // f2 = x velocity

        _grounded:
        swc1    f2, 0x0060(at)              // store updated ground x velocity
        lwc1    f0, 0x0044(at)              // ~
        cvt.s.w f0, f0                      // f0 = direction
        mul.s   f2, f2, f0                  // f2 = x velocity * direction
        b       _end                        // end
        swc1    f2, 0x0048(at)              // store updated air x velocity

        _aerial:
        lwc1    f0, 0x0044(at)              // ~
        cvt.s.w f0, f0                      // f0 = direction
        mul.s   f2, f2, f0                  // f2 = x velocity * direction
        swc1    f2, 0x0048(at)              // store updated x velocity
        swc1    f4, 0x004C(at)              // store updated y velocity

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0040              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles YZelda's horizontal control for up special end.
    // based on 0x800D91EC
    // s1 = player struct
    // a2 = other player struct?
    scope end_physics_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      s0, 0x0014(sp)              // ~
        sw      s1, 0x0018(sp)              // original store registers
        sw      a1, 0x000C(sp)              // ~
        sw      ra, 0x0014(sp)              // ~
        lw      s0, 0x0084(a0)              // load player struct
        lw      t6, 0x0180(s0)              // load variable 2
        lw      s1, 0x09C8(s0)              // load attribute pointer
        or      a0, s0, r0                  // place player struct into a0
        jal     0x800D8E50                  // set vertical velocity
        or      a1, s1, r0                  // place attribute pointer into a1

        addiu   a1, r0, 0x0008              // a1 = 0x8 (original line)
        lw      a2, 0x004C(s1)              // a2 = air acceleration
        lw      a3, 0x0050(s1)              // a3 = max air speed

        _continue:
        jal     0x800D8FC8                  // air drift subroutine?
        nop


        _end:
        lw      a1, 0x000C(sp)
        lw      ra, 0x001C(sp)              // ~
        lw      s0, 0x0014(sp)
        lw      s1, 0x0018(sp)
        jr      ra                          // return
        addiu   sp, sp, 0x0020              // deallocate stack space
    }
}

// @ Description
// Subroutines for YZelda Down special (counter).
scope YZeldaDSP {
    // @ Description
    // Subroutine which runs when YZelda initiates a grounded down special.
    scope ground_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lli     a1, YZelda.Action.DSP_Ground // a1(action id) = DSP_Ground
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
        sw      r0, 0x0B18(a0)              // hit detection = FALSE
        lw      ra, 0x001C(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0020              // deallocate stack space
    }

    // @ Description
    // Subroutine which runs when YZelda initiates an aerial down special.
    scope air_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lli     a1, YZelda.Action.DSP_Air    // a1(action id) = DSP_Air
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
        sw      r0, 0x0B18(a0)              // hit detection = FALSE
        sw      r0, 0x004C(a0)              // y velocity = 0
        lwc1    f4, 0x0048(a0)              // f4 = x velocity
        lui     at, 0x3F00                  // ~
        mtc1    at, f6                      // f6 = 0.5
        mul.s   f4, f4, f6                  // f4 = x velocity * 0.5
        swc1    f4, 0x0048(a0)              // store updated x velocity
        lw      ra, 0x001C(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0020              // deallocate stack space
    }

    // @ Description
    // Subroutine which begins YZelda's grounded down special attack action.
    scope ground_attack_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra

        jal     PokemonAnnouncer.counter_announcement_
        nop

        lli     a1, YZelda.Action.DSP_Ground_Attack // a1(action id) = DSP_Ground_Attack
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      ra, 0x001C(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0020              // deallocate stack space
    }

    // @ Description
    // Subroutine which begins YZelda's aerial neural special attack action.
    scope air_attack_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra

        jal     PokemonAnnouncer.counter_announcement_
        nop

        lli     a1, YZelda.Action.DSP_Air_Attack // a1(action id) = DSP_Air_Attack
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      ra, 0x001C(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0020              // deallocate stack space
    }

    // @ Description
    // Main subroutine for down special.
    // If temp variable 1 is set by moveset, make YZelda invincible, and check for hits.
    scope main_: {
        addiu   sp, sp,-0x0040              // allocate stack space
        sw      ra, 0x0014(sp)              // 0x0014(sp) = ra
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player object
        addu    a2, a0, r0                  // a2 = player object
        lw      v0, 0x0084(a0)              // v0 = player struct
        lw      t6, 0x017C(v0)              // t6 = temp variable 1
        beqz    t6, _hit_detection_check    // branch if temp variable 1 isn't set
        sw      r0, 0x07E8(v0)              // set armour to 0

        // if temp variable 1 is set
        lui     at, 0x4800                  // ~
        sw      at, 0x07E8(v0)              // set armour to a very high amount (should be unbreakable)

        _hit_detection_check:
        lw      t6, 0x0B18(v0)              // t6 = hit detection
        beqz    t6, _idle_check             // branch if hit detection = FALSE
        nop

        // if marth has been hit
        lw      t6, 0x07FC(v0)              // t6 = hit direction
        sw      t6, 0x0044(v0)              // direction = hit direction
        mtc1    t6, f6                      // ~
        cvt.s.w f6, f6                      // f6 = direction
        lui     at, 0x8013                  // ~
        lwc1    f8, 0xFE90(at)              // at = rotation constant
        mul.s   f8, f8, f6                  // f8 = rotation constant * direction
        lw      t6, 0x08E8(v0)              // t6 = character control joint struct
        swc1    f8, 0x0034(t6)              // update character rotation to match direction
        lw      t6, 0x014C(v0)              // t6 = kinetic state
        bnez    t6, _aerial                 // branch if kinetic state !grounded
        nop

        jal     ground_attack_initial_      // begin grounded attack action
        nop
        b       _end                        // end
        nop

        _aerial:
        jal     air_attack_initial_         // begin aerial attack action
        nop
        b       _end                        // end
        nop


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
        jr      ra
        addiu   sp, sp, 0x0040              // deallocate stack space
    }

    // @ Description
    // Subroutine which handles physics for YZelda's aerial down special.
    scope air_physics_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x0014(sp)              // ~
        sw      a0, 0x0018(sp)              // store ra, a0

        jal     0x800D91EC                  // physics subroutine (disallows player control)
        nop

        lw      a0, 0x0018(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        lwc1    f4, 0x004C(a0)              // f4 = current y velocity
        lui     at, 0x3FC0                  // ~
        mtc1    at, f6                      // f6 = 1.5
        add.s   f4, f4, f6                  // f4 = current y velocity + 1.5
        swc1    f4, 0x004C(a0)              // store updated y velocity

        lw      ra, 0x0014(sp)
        jr      ra                          // return
        addiu   sp, sp, 0x0020              // deallocate stack space
    }

    // @ Description
    // Subroutine which handles ground collision for down special actions
    scope ground_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, ground_to_air_          // a1(transition subroutine) = ground_to_air_
        jal     0x800DDE84                  // common ground collision subroutine (transition on no floor, no slide-off)
        nop
        lw      ra, 0x0014(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0018              // deallocate stack space
    }

    // @ Description
    // Subroutine which handles air collision for down special actions
    scope air_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, air_to_ground_          // a1(transition subroutine) = air_to_ground_
        jal     0x800DE6E4                  // common air collision subroutine (transition on landing, no ledge grab)
        nop
        lw      ra, 0x0014(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0018              // deallocate stack space
    }

    // @ Description
    // Subroutine which handles ground to air transition for down special actions
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
        addiu   a1, t7, 0x0002              // a1 = equivalent air action for current ground action (id + 2)
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lli     t6, 0x2803                  // ~
        jal     0x800E6F24                  // change action
        sw      t6, 0x0010(sp)              // argument 4 = 0x2803 (continue: sword trails, 3C command FGM, gfx routines, hitboxes)
        jal     0x800D8EB8                  // momentum capture?
        lw      a0, 0x0034(sp)              // a0 = player struct
        lw      ra, 0x001C(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0038              // deallocate stack space
    }

    // @ Description
    // Subroutine which handles air to ground transition for down special actions
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
        addiu   a1, t7,-0x0002              // a1 = equivalent ground action for current air action (id - 2)
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lli     t6, 0x2803                  // ~
        jal     0x800E6F24                  // change action
        sw      t6, 0x0010(sp)              // argument 4 = 0x2803 (continue: sword trails, 3C command FGM, gfx routines, hitboxes)
        lw      ra, 0x001C(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0038              // deallocate stack space
    }

    // @ Description
    // @ Description
    // Patch which adds hit detection for counter and prevents Marth from taking damage
    scope detection_patch_: {
        OS.patch_start(0x65A48, 0x800EA248)
        j       detection_patch_
        nop
        _return:
        OS.patch_end()

        // a0 = player struct
        // a1 = damage
        addiu   sp, sp,-0x0030              // original line 1
        sw      ra, 0x0014(sp)              // original line 2

        lw      t8, 0x0008(a0)              // t8 = character id
        lli     t9, Character.id.YZELDA     // t9 = id.YZELDA
        beq     t8, t9, _check_yzelda_action // check action if character = YOUNG ZELDA
        lli     t9, Character.id.MARTH      // t9 = id.MARTH
        bne     t8, t9, _end                // skip if character != MARTH
        nop

        _check_marth_action:
        lw      t8, 0x0024(a0)              // t8 = current action
        lli     t9, Marth.Action.DSP_Ground // t9 = Action.DSP_Ground
        beq     t8, t9, _counter            // branch if current action = DSP_Ground
        lli     t9, Marth.Action.DSP_Air    // t9 = Action.DSP_Air
        bne     t8, t9, _end                // skip if current action != DSP_Air
        nop
        b       _counter
        nop

        _check_yzelda_action:
        lw      t8, 0x0024(a0)              // t8 = current action
        lli     t9, YZelda.Action.DSP_Ground // t9 = Action.DSP_Ground
        beq     t8, t9, _counter            // branch if current action = DSP_Ground
        lli     t9, YZelda.Action.DSP_Air   // t9 = Action.DSP_Air
        bne     t8, t9, _end                // skip if current action != DSP_Air
        nop

        _counter:
        lw      t8, 0x017C(a0)              // t8 = temp variable 1
        beqz    t8, _end                    // skip if temp variable 1 isn't set
        nop

        // if temp variable 1 is set
        or      a1, r0, r0                  // damage = 0
        lli     t8, 0x0001                  // ~
        sw      t8, 0x0B18(a0)              // hit detection = 1


        _end:
        j       _return                     // return
        nop
    }
}