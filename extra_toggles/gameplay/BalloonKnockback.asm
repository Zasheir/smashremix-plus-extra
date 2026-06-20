scope BalloonKnockback {
    fixed_knockback_flag:
    db 0x0000
    OS.align(4)

    // 800E2604 + 44 = 800E2648
    // This is the function that calls the physics logic to run
    // The physics logic applies velocities and updates collisions
    scope rerun_kb: {
        OS.patch_start(0x5DE48, 0x800E2648)
        j       rerun_kb
        nop
        _return:
        OS.patch_end()

        _original:
        addiu   sp,sp,-0x18
        sw      a0, 0x4(sp) // backup a0

        jal     0x800E2048
        nop

        lw      a0, 0x4(sp) // restore a0
        addiu   sp,sp,0x18

        lw      ra,0x14(sp)

        Toggles.read(entry_BalloonKnockback, t0)      // t0 = balloon kb toggle
        beqz    t0, _end                      // branch if toggle is disabled
        nop

        _kb_check:
        OS.save_registers()

        li      t1, fixed_knockback_flag     // t1 = fixed_knockback_flag address
        lw      t1, 0x0000(t1)               // t1 = fixed_knockback_flag value

        bnez    t1, _skip                   // skip on fixed knockback moves
        nop

        lw      v0, 0x84(a0)                // v0 = player struct
        lw      t0, 0x07EC(v0)              // t0 = current knockback value
        beqz    t0, _skip                   // branch if knockback == 0
        nop

        // check magnitude
        addiu   sp,sp,-0x18
        sw      a0, 0x4(sp) // backup a0
        sw      v0, 0x8(sp) // backup a0
        sw      ra, 0xC(sp) // backup a0

        jal     0x80018F7C // vector magnitude
        addiu   a0,v0,0x54
        nop

        lw      a0, 0x4(sp) // restore a0
        lw      v0, 0x8(sp) // backup a0
        lw      ra, 0xC(sp) // backup a0
        addiu   sp,sp,0x18

        lui     at,0x42A0 // 80.0
        mtc1    at, f4
        nop
        c.lt.s  f0, f4 // is magnitude <= 80?
        nop
        bc1fl   _repeat // if not, repeat
        nop

        lui     at,0x4270 // 60.0
        mtc1    at, f4
        nop
        c.lt.s  f0, f4 // is magnitude <= 60?
        nop
        bc1fl   _half_check // if not, repeat half
        nop

        b _skip
        nop

        _half_check:
        // only run once every 2 frames
        ori     t3, r0, 0x0001  // % 1

        // Using t3 in the "and" working as a "mod" operation (division remainder)
        li      t5, Global.current_screen_frame_count // ~
        lw      t5, 0x0000(t5)           // t5 = global frame count

        and     t7, t5, t3
        beqz    t7, _skip
        nop

        _repeat:
        // Decrease hitstun because we ran an extra frame
        lw      t0, 0x0B18(v0)
        addiu   t0, -1
        sw      t0, 0x0B18(v0)

        addiu   sp,sp,-0x18
        sw      a0, 0x4(sp) // backup a0
        sw      v0, 0x8(sp) // backup a0
        sw      ra, 0xC(sp) // backup a0
        jal     0x800E2048
        nop
        lw      a0, 0x4(sp) // restore a0
        lw      v0, 0x8(sp) // backup a0
        lw      ra, 0xC(sp) // backup a0
        addiu   sp,sp,0x18

        _skip:
        OS.restore_registers()

        _end:
        j       _return
        nop
    }

    // 800E9D78+1F0=800E9F68
    // sets final knockback value
    // (before checking knockback value limits and clamping them)
    scope update_kb_flag: {
        OS.patch_start(0x6576C, 0x800E9F6C)
        j       update_kb_flag
        nop
        _return:
        OS.patch_end()

        beqz    a3, _not_fixed
        nop

        _is_fixed:
        lli     t0, 0x1
        li      t1, fixed_knockback_flag     // t1 = fixed_knockback_flag address
        sw      t0, 0x0000(t1)                  // update fixed_knockback_flag
        b   _original
        nop

        _not_fixed:
        li      t1, fixed_knockback_flag     // t1 = fixed_knockback_flag address
        sw      r0, 0x0000(t1)                  // update fixed_knockback_flag
        b   _original
        nop

        _original:
        c.le.s  f0, f2  // original line 1
        nop             // original line 2

        j       _return
        nop
    }
}