// This file contains this characters AI attacks

// Create new cpu attack behaviours
OS.align(4)
CPU_ATTACKS:
// grounded attacks
// add_attack_behaviour(table, attack, hitbox_start_frame, min_x, max_x, min_y, max_y)
AI.add_attack_behaviour(JAB, 3, 88, 439, 305, 422)
AI.add_attack_behaviour(FTILT, 4, 344, 537, 270, 438)
AI.add_attack_behaviour(GRAB, 6, 152, 459, 208, 348)
AI.add_attack_behaviour(UTILT, 6, 32, 437, 127, 913)
AI.add_attack_behaviour(DTILT, 6, 334, 758, -2, 163)
// AI.add_attack_behaviour(DSMASH, 8, -482, 472, 62, 287)
AI.add_attack_behaviour(DSMASH, 29, 304, 584, -7, 273)
AI.add_attack_behaviour(USMASH, 11, 9, 346, 53, 213)
// AI.add_attack_behaviour(FSMASH, 41, 304, 584, -7, 273)
AI.add_attack_behaviour(FSMASH, 20, 1000, 3000, -1000, 1000)
AI.add_attack_behaviour(USMASH, 90, 0, 800, -200, 500) // explosion
AI.add_attack_behaviour(NSPG, 30, 500, 3000, -1000, 1000)
AI.add_custom_attack_behaviour(AI.ROUTINE.DASH_ATTACK, 5, 431, 1296, 45, 419)
// we can add new grounded attacks here

AI.END_ATTACKS() // end of grounded attacks

// aerial attacks
// add_attack_behaviour(table, attack, hitbox_start_frame, min_x, max_x, min_y, max_y)
AI.add_attack_behaviour(DAIR, 3, -61, 184, -151, 196)
AI.add_attack_behaviour(DAIR, 25, -61, 184, -151, 196) // last hit
AI.add_custom_attack_behaviour(AI.ROUTINE.BAIR, 7, -464, -68, 79, 264)
AI.add_custom_attack_behaviour(AI.ROUTINE.BAIR, 7+4, -464, -68, 79, 264)
AI.add_custom_attack_behaviour(AI.ROUTINE.BAIR, 7+8, -464, -68, 79, 264)
AI.add_attack_behaviour(NAIR, 10, 36, 464, 36, 497) // hit 1
AI.add_attack_behaviour(NAIR, 18, 36, 464, 36, 497) // hit 2
AI.add_attack_behaviour(NAIR, 26, 36, 464, 36, 497) // hit 3
AI.add_attack_behaviour(NAIR, 36, 124, 364, 213, 453) // hit 4
AI.add_attack_behaviour(UAIR, 10, -65, 65, 435, 764)
AI.add_attack_behaviour(UAIR, 10+4, -65, 65, 435, 764) // late hit
AI.add_attack_behaviour(UAIR, 10+8, -65, 65, 435, 764) // later hit
AI.add_custom_attack_behaviour(AI.ROUTINE.FAIR, 16, 41, 478, -36, 552)
AI.add_attack_behaviour(NSPA, 30, 500, 3000, -1000, 1000)
// we can add new aerial attacks here

AI.END_ATTACKS() // end of aerial attacks
OS.align(16)

// Set CPU behaviour
Character.table_patch_start(ai_behaviour, Character.id.SNAKE, 0x4)
dw CPU_ATTACKS
OS.patch_end()

// Set CPU NSP long range behaviour
Character.table_patch_start(ai_long_range, Character.id.SNAKE, 0x4)
dw AI.LONG_RANGE.ROUTINE.NSP_SHOOT
OS.patch_end()

// Custom custom long range action input
Character.table_patch_start(nsp_shoot_custom_move, Character.id.SNAKE, 0x4)
dw AI.ROUTINE.DSP
OS.patch_end()

scope recovery_logic: {
    OS.routine_begin(0x20)
    sw a0, 0x10(sp)

    lw at, 0x24(a0) // at = action id
    lli t0, Snake.Action.CYPHERAIRHANG
    beq t0, at, _usp
    nop

    b _end
    nop

    scope _usp: {
        mtc1 r0, f0 // ensure f0 = 0

        lw t0, 0x78(a0) // load location vector
        lwc1 f2, 0x0(t0) // f2 = location X
        lwc1 f4, 0x4(t0) // f4 = location Y

        mtc1 r0, f0 // guarantee f0 = 0

        // check closest ledge in X
        scope ledge_check: {
            lwc1 f6, 0x01CC+0x4C(a0) // load nearest LEFT ledge X
            lwc1 f8, 0x01CC+0x54(a0) // load nearest RIGHT ledge X

            sub.s f6, f6, f2
            abs.s f6, f6 // f6 = abs(distance) to left ledge

            sub.s f8, f8, f2
            abs.s f8, f8 // f8 = abs(distance) to right ledge

            c.le.s f6, f8
            nop
            bc1f _right
            nop

            _left:
            lwc1 f6, 0x01CC+0x4C(a0) // load nearest LEFT ledge X
            lwc1 f8, 0x01CC+0x50(a0) // load nearest LEFT ledge Y
            
            b _check_end
            nop

            _right:
            lwc1 f6, 0x01CC+0x54(a0) // load nearest RIGHT ledge X
            lwc1 f8, 0x01CC+0x58(a0) // load nearest RIGHT ledge Y

            _check_end:
        }

        sub.s f14, f6, f2 // f14 = x diff
        sub.s f12, f8, f4 // f12 = y diff

        lw t6, 0x9C8(a0) // t6 = character attributes
        lwc1 f20, 0xB0(t6) // f20 = ledge grab Y
        add.s f20, f4, f20 // f20 = Y + ledge grab Y

        lw t0, 0x44(a0) // t0 = player facing direction (int)
        mtc1 t0, f10
        cvt.s.w f10, f10 // f10 = facing direction (float)

        lwc1 f22, 0xB0(t6) // f22 = ledge grab X
        mul.s f10, f10, f22 // f10 = facing direction * ledge grab X
        add.s f22, f2, f10 // f22 = X + facing direction * ledge grab X

        // skip if air speed is down
        lwc1 f2, 0x4C(a0) // f2 = y speed
        c.le.s f2, f0 // y speed < 0?
        nop
        bc1t _end
        nop

        add.s f20, f20, f2 // account for next frame's movement

        // check if (Y + ledge grab + y_speed(1 frame)) is above ledge Y
        c.le.s f20, f8 // f20 <= ledge Y?
        nop
        bc1t _end
        nop

        // check if ledge grab X is beyond ledge X in the facing direction
        // we can use the x diff to determine this
        // first check if the x diff is positive or negative
        c.lt.s f14, f0 // if x diff < 0
        nop
        bc1t _going_left // if x diff < 0, hold left
        nop

        _going_right:
        // check if ledge grab X > ledge X
        // if so, usp_drop
        c.le.s f22, f6 // f22 <= ledge X?
        nop
        bc1f _usp_drop // if not, usp_drop
        nop
        b _end
        nop
        
        _going_left:
        // check if ledge grab X < ledge X
        // if so, usp_drop
        c.le.s f6, f22 // ledge X <= ledge grab X?
        nop
        bc1f _usp_drop // if not, usp_drop
        nop
        b _end
        nop

        _usp_drop:
        jal 0x80132758 // execute AI command
        lli a1, AI.ROUTINE.STICK_DOWN // arg1 = press down to drop from usp
        b _end
        nop
    }

    _end:
    lw a0, 0x10(sp)
    OS.routine_end(0x20)
}
Character.table_patch_start(recovery_logic, Character.id.SNAKE, 0x4)
dw recovery_logic; OS.patch_end()

scope cpu_post_process: {
    OS.routine_begin(0x20)
    sw a0, 0x10(sp)

    // if using Nikita, go to its scope
    lw at, 0x24(a0) // at = action id
    lli t0, Snake.Action.NIKITAOPERATION
    beq t0, at, nikita_control
    lli t0, Snake.Action.NIKITAAIROPERATION
    beq t0, at, nikita_control
    nop

    lli t0, Snake.Action.GRENADESTART
    beq t0, at, grenade_control
    lli t0, Snake.Action.GRENADEWAIT
    beq t0, at, grenade_control
    lli t0, Snake.Action.GRENADESTARTAIR
    beq t0, at, grenade_control
    lli t0, Snake.Action.GRENADEWAITAIR
    beq t0, at, grenade_control
    lli t0, Snake.Action.GRENADEWALKF
    beq t0, at, grenade_control
    lli t0, Snake.Action.GRENADEWALKB
    beq t0, at, grenade_control
    nop

    lli t0, Action.Tumble
    beq t0, at, grenade_out_of_tumble
    nop

    b dsp_check
    nop

    scope nikita_control: {
        // if not above clipping, press Z to cancel
        addiu at, r0, -1 // at = 0xFFFFFFF
        lw t1, 0x00EC(a0) // get current clipping below player
        beq at, t1, _end // do not activate if not above clipping
        nop

        lw t0, 0x0AE0(a0) // t0 = 0 if no nikita out, otherwise nikita object ptr
        beqz t0, _end // if no nikita out, skip
        nop

        lw at, 0x01FC(a0) // get target player object
        beqz at, _end // if no target object, skip
        nop

        jal 0x80132758 // execute AI command
        lli a1, AI.ROUTINE.NULL

        // load max stick value to f10
        lui at, 0x42A0 // at = 80.0
        mtc1 at, f10

        lw t0, 0x4(t0) // t0 = nikita object
        lw t1, 0x74(t0) // t1 = t1 = nikita x/y/z position at 1C(t1), 20(t1), 24(t1)
        lwc1 f2, 0x1C(t1) // f2 = location X
        lwc1 f4, 0x20(t1) // f4 = location Y

        lw at, 0x01FC(a0) // get target player object
        lw at, 0x84(at) // at = target struct
        lw t1, 0x78(at) // load target location vector
        lwc1 f6, 0x0(t1) // f6 = target X
        lwc1 f8, 0x4(t1) // f8 = target Y
        lwc1 f20, 0xB4(at) // Load ECB collision diamond center
        add.s f8, f8, f20 // y += collision diamond center

        sub.s f12, f6, f2 // f14 = x diff
        sub.s f14, f8, f4 // f12 = y diff

        sub.s f12, f6, f2 // dx = target_x - player_x
        sub.s f14, f8, f4 // dy = target_y - player_y

        // dx^2 + dy^2
        mul.s f16, f12, f12
        mul.s f18, f14, f14
        add.s f20, f16, f18

        // if distance == 0, stick = (0, 0)
        c.eq.s f20, f0
        bc1t _zero
        nop

        // magnitude = sqrt(dx^2 + dy^2)
        sqrt.s f22, f20

        // scale = max / magnitude
        div.s f24, f10, f22

        // scaled dx/dy
        mul.s f26, f12, f24
        mul.s f28, f14, f24

        // convert to integers (truncate)
        cvt.w.s f26, f26
        cvt.w.s f28, f28
        mfc1 at, f26
        sb at, 0x01C8(a0) // save CPU stick_x
        mfc1 at, f28
        b _end
        sb at, 0x01C9(a0) // save CPU stick_y

        _zero:
        sb r0, 0x01C8(a0) // save CPU stick_x
        sb r0, 0x01C9(a0) // save CPU stick_y
        b _end
        nop

        _cancel:
        jal 0x80132758 // execute AI command
        lli a1, AI.ATTACK_TABLE.GRAB.INPUT
        b _end
        nop

        _end:
    }
    b _end
    nop

    scope grenade_control: {
        // if not above clipping, always throw the grenade as soon as possible
        addiu at, r0, -1 // at = 0xFFFFFFF
        lw t1, 0x00EC(a0) // get current clipping below player
        beq at, t1, _grenade_throw
        nop

        _random_chance_hold:
        jal Global.get_random_int_ // v0 = (random value)
        lli a0, 4 // 1 in 4 chance to keep holding the grenade each frame
        beqz v0, _grenade_hold
        lw a0, 0x10(sp) // restore player struct

        lw t0, 0x78(a0) // load location vector
        lwc1 f2, 0x0(t0) // f2 = location X
        lwc1 f4, 0x4(t0) // f4 = location Y

        lw at, 0x01FC(a0) // get target player object
        beqz at, _end // if no target object, skip
        nop
        lw at, 0x84(at) // at = target struct

        lw t1, 0x78(at) // load target location vector
        lwc1 f6, 0x0(t1) // f6 = target X
        lwc1 f8, 0x4(t1) // f8 = target Y

        sub.s f14, f6, f2 // f14 = x diff
        sub.s f12, f8, f4 // f12 = y diff

        // Calculate distance to target into f20
        mul.s f20, f14, f14 // f20 = (x distance)^2
        mul.s f22, f12, f12 // f22 = (y distance)^2
        add.s f20, f20, f22 // f20 = (x distance)^2 + (y distance)^2
        sqrt.s f20, f20 // f20 = sqrt((x distance)^2 + (y distance)^2) = distance to target

        // Will set stick values as if looking to the right, then adjust for facing direction later
        // if distance <= 500, set stick back and continue
        lui at, 0x43FA // at = 500.0
        mtc1 at, f2
        c.le.s f20, f2
        nop
        bc1f _set_stick
        addiu t8, r0, 0xFFB0 // t8 = -80

        // if distance <= 1500, set stick neutral and continue
        lui at, 0x4448 // at = 1500.0
        mtc1 at, f2
        c.le.s f20, f2
        nop
        bc1f _set_stick
        or t8, r0, r0 // t8 = 0

        // if distance > 1500, set stick forwards and continue
        lui at, 0x44BB // at = 1500.0
        mtc1 at, f2
        c.le.s f20, f2
        nop
        bc1f _set_stick
        addiu t8, r0, 0x50 // t8 = 80

        _set_stick:
        lw t0, 0x44(a0) // t0 = player facing direction
        mul t8, t8, t0 // adjust stick for facing direction
        sb t8, 0x01C8(a0) // save CPU stick_x

        _grenade_throw:
        sh r0, 0x01C6(a0) // save cpu button press mask (release all buttons)
        jal 0x80132758 // execute AI command
        lli a1, AI.ROUTINE.NULL // arg1 = NULL -> so our inputs are not overriden
        b _end
        nop

        _grenade_hold:
        // hold the grenade by holding B
        lh at, 0x01C6(a0)
        ori at, at, 0x4000 // press B
        sh at, 0x01C6(a0) // save press B mask

        jal 0x80132758 // execute AI command
        lli a1, AI.ROUTINE.NULL // arg1 = NULL -> so our inputs are not overriden

        jal Global.get_random_int_ // v0 = (random value)
        lli a0, 4 // 1 in 4 chance to shield and drop the grenade each frame
        bnez v0, _end
        lw a0, 0x10(sp) // restore player struct

        jal 0x80132758 // execute AI command
        lli a1, AI.ATTACK_TABLE.GRAB.INPUT // arg1 = grab

        b _end
        nop

        _end:
    }
    b _end
    nop

    scope grenade_out_of_tumble: {
        lw t0, 0x1C(a0) // t0 = current frame (int)

        lli t1, 0x1
        bne t0, t1, _end // if not the first frame out of tumble, skip
        nop

        _random_chance_hold:
        jal Global.get_random_int_ // v0 = (random value)
        lli a0, 4 // 1 in 4 chance to go for it
        bnez v0, _end
        lw a0, 0x10(sp) // restore player struct

        lw t0, 0x78(a0) // load location vector
        lwc1 f2, 0x0(t0) // f2 = location X
        lwc1 f4, 0x4(t0) // f4 = location Y

        lw at, 0x01FC(a0) // get target player object
        beqz at, _end // if no target object, skip
        nop
        lw at, 0x84(at) // at = target struct

        lw t1, 0x78(at) // load target location vector
        lwc1 f6, 0x0(t1) // f6 = target X
        lwc1 f8, 0x4(t1) // f8 = target Y

        sub.s f14, f6, f2 // f14 = x diff
        sub.s f12, f8, f4 // f12 = y diff

        // Calculate distance to target into f20
        mul.s f20, f14, f14 // f20 = (x distance)^2
        mul.s f22, f12, f12 // f22 = (y distance)^2
        add.s f20, f20, f22 // f20 = (x distance)^2 + (y distance)^2
        sqrt.s f20, f20 // f20 = sqrt((x distance)^2 + (y distance)^2) = distance to target

        // if distance <= 1000, use neutral B
        lui at, 0x447A // at = 1000.0
        mtc1 at, f2
        c.le.s f20, f2
        nop
        bc1t _pull_grenade
        nop
        b _end
        nop

        _pull_grenade:
        jal 0x80132758 // execute AI command
        lli a1, AI.ATTACK_TABLE.NSPA.INPUT

        _end:
    }
    b _end
    nop

    scope dsp_check: {
        lw t0, 0x0ADC(a0) // t0 = 0 if no c4 out, otherwise c4 object ptr
        beqz t0, _end // if no c4 out, skip
        nop

        // If going for DSP when it's out, cancel action
        lw t1, 0x1D4(a0) // t1 = ft_com->p_command
        li t2, AI.command_table // load command table base address
        lw at, AI.ATTACK_TABLE.DSPG.INPUT << 2(t2)
        beq t1, at, _no_input
        nop

        // if not above clipping, do not activate c4
        addiu at, r0, -1 // at = 0xFFFFFFF
        lw t1, 0x00EC(a0) // get current clipping below player
        beq at, t1, _end // do not activate if not above clipping
        nop

        lw t0, 0x4(t0) // t0 = c4 object
        lw t1, 0x74(t0) // t1 = t1 = c4 x/y/z position at 1C(t1), 20(t1), 24(t1)
        lwc1 f2, 0x1C(t1) // f2 = location X
        lwc1 f4, 0x20(t1) // f4 = location Y

        lw at, 0x01FC(a0) // get target player object
        beqz at, _end // if no target object, skip
        nop
        lw at, 0x84(at) // at = target struct

        lw t1, 0x78(at) // load target location vector
        lwc1 f6, 0x0(t1) // f6 = target X
        lwc1 f8, 0x4(t1) // f8 = target Y
        lwc1 f20, 0xB4(at) // Load ECB collision diamond center
        add.s f8, f8, f20 // y += collision diamond center

        sub.s f14, f6, f2 // f14 = x diff
        sub.s f12, f8, f4 // f12 = y diff

        // Calculate distance to target into f20
        mul.s f20, f14, f14 // f20 = (x distance)^2
        mul.s f22, f12, f12 // f22 = (y distance)^2
        add.s f20, f20, f22 // f20 = (x distance)^2 + (y distance)^2
        sqrt.s f20, f20 // f20 = sqrt((x distance)^2 + (y distance)^2) = distance to target

        // if distance <= 800, set routine to DSP
        lui at, 0x4448 // at = 800.0
        mtc1 at, f2
        c.le.s f20, f2
        nop
        bc1f _end
        nop
        
        _activate:
        jal 0x80132758 // execute AI command
        lli a1, AI.ATTACK_TABLE.DSPG.INPUT
        b _end
        nop

        _no_input:
        jal 0x80132758 // execute AI command
        lli a1, AI.ROUTINE.NULL // arg1 = NULL
        b _end
        nop

        _end:
    }
    b _end
    nop

    _end:
    lw a0, 0x10(sp)
    OS.routine_end(0x20)
}
Character.table_patch_start(cpu_post_process, Character.id.SNAKE, 0x4)
dw cpu_post_process; OS.patch_end()