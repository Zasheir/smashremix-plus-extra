scope AutolinkAngle {
    // Grounded moves:
    // - No change
    // Aerial moves:
    // - If opponent is grounded:
    //  - Knockback length is unchanged
    //  - Direction is set to 80 deg
    // - If opponent is in the air:
    //  - Knockback speed and direction set to match the attacker's speed +
    //      distance from the opponent to the hitbox * low multiplier
    //  - Results in matching the attacker's speed and slightly adjusting towards the hitbox's center

    // 800E3EBC + 570
    scope set_hit_angle: {
        OS.patch_start(0x5FC2C, 0x800E442C)
        j       set_hit_angle
        nop
        _return:
        OS.patch_end()

        // autolink angle is 362
        lw t0, 0x07F4(s5)
        lli at, 362
        bne t0, at, _original
        nop

        // do not apply when attacker is grounded
        lw      t0, 0x014C(s1)    // t0 = attacker kinetic state
        beqz    t0, _original     // perform original behavior if kinetic state == grounded
        nop

        _check_knockback:
        lwc1        f0, 0xa0(sp)
        lui         t0, 0x42A0 // 80.0
        mtc1        t0, f2
        c.lt.s      f0, f2
        nop
        bc1tl       _continue
        nop

        // else, original behavior
        b   _original
        nop

        _continue:
        // if the victim is grounded, we set knockback angle to 80 and exit
        // otherwise, go to _aerial
        lw      t0, 0x014C(s5)    // t0 = victim kinetic state
        bnez    t0, _aerial       // skip if kinetic state !grounded
        nop

        ori     t0, r0, 0x50    // t0 = 80 degrees
        sw      t0, 0x07F4(s5)  // original line 2 (set angle)
        b       _end
        nop

        _aerial:
        lwc1 f14, 0x0048(s1) // f14 = attacker x speed 0x008C?
        lwc1 f12, 0x004C(s1) // f12 = attacker y speed 0x0090?

        // Get the magnitude of the attacker's velocity vector
        mul.s   f2, f12, f12  // f2 = x^2
        mul.s   f4, f14, f14  // f4 = y^2
        add.s   f2, f2, f4    // Add x^2 and y^2
        sqrt.s  f10,f2        // f10 = square root of (x^2 + y^2) = velocity magnitude

        lwc1    f4, 0x44(s0) // f4 = hitbox pos x
        lwc1    f6, 0x48(s0) // f6 = hitbox pos y
        
        lw      t0, 0x4(s5)     // t0 = victim object
        lw      t0, 0x0074(t0)  // t0 = victim location vector
        lwc1    f16, 0x1C(t0)   // f16 = victim x pos
        lwc1    f18, 0x20(t0)   // f18 = victim y pos

        // Add collision Y to position Y to get the victim's actual character center
        lwc1    f8, 0xb4(s5)    // f8 = fp->coll_data.object_coll.center
        add.s   f18, f18, f8    // adjust victim Y to actual character center

        // Calculate offset between victim and hitbox
        sub.s   f4, f4, f16 // f4 = hitbox offset x
        nop
        sub.s   f6, f6, f18 // f6 = hitbox offset y
        nop
        // Scale hitbox offset vector down
        lui     t0, 0x3D27      // 0.04
        mtc1    t0, f2          // f2 = 0.04

        mul.s   f4, f4, f2    // x2_scaled = x2_normalized * magnitude_scaled
        mul.s   f6, f6, f2    // y2_scaled = y2_normalized * magnitude_scaled

        // Overwrite knockback magnitude
        // Get hitbox offset vector magnitude
        mul.s  f20, f4, f4    // x^2
        mul.s  f22, f6, f6    // y^2
        add.s  f24, f20, f22  // x^2 + y^2
        sqrt.s f26, f24       // f26 = sqrt(x^2 + y^2)

        add.s   f10, f10, f26 // f10 = speed magnitude + hitbox offset magnitude
        swc1    f10, 0xa0(sp) // overwrite hitbox knockback magnitude in a0(sp)

        // Sum both vectors
        add.s   f14, f14, f4 // add hitbox offset to the calculation x
        add.s   f12, f12, f6 // add hitbox offset to the calculation y

        // Negative X fix
        // Fixes reverse hits
        negative_x_fix:
        lw      t0, 0x4(s1) // t0 = attacker object
        lw      t0, 0x0074(t0) // t0 = attacker location vector
        lwc1    f20, 0x1C(t0) // f20 = attacker pos x
        c.lt.s  f16, f20
        nop
        bc1fl negative_x_fix_end
        nop
        neg.s   f14, f14 // if it was a reverse hit, x = -x
        negative_x_fix_end:
        
        // Get angle from vector using default function atan2f(y, x)
        // Result is in Radians
        jal     0x8001863C // atan2f(f12, f14), result ends in f0 (radians)
        nop
        
        // RAD TO DEG
        li      t0, 0x42652EE1  // ~
        mtc1    t0, f2          // f2 = 180/pi
        mul.s   f4, f0, f2      // f4 = f0 * (180/pi) (angle in degrees)
        cvt.w.s f0, f4          // Convert to int
        // END

        swc1 f0, 0x07F4(s5) // overwrite hit angle

        b _end
        nop

        _original:
        // Load hit angle, apply to player
        lw t2, 0x0028(s0) // original line 1
        sw t2, 0x07F4(s5) // original line 2

        _end:
        j       _return
        nop
    }
}