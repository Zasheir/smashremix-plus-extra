scope DKUltSpecial: {
    scope NSP_START: {
        scope update: {
            OS.routine_begin(0x20)

            lw t0, 0x84(a0) // t0 = fighter struct
            lw t0, 0xadc(t0) // t0 = charge level

            lli t1, 0xA // max charge

            beq t0, t1, _charged
            nop

            _uncharged:
            li a1, 0x8015B320 // ftDonkeySpecialNLoopSetStatus(GObj *fighter_gobj)
            b _end
            nop

            _charged:
            li a1, 0x8015B51C // ftDonkeySpecialNEndSetStatus(GObj *fighter_gobj)

            _end:
            jal 0x800D9480 // ftAnimEndCheckSetStatus(fighter_gobj, function);
            nop
            OS.routine_end(0x20)
        }

        scope update_air: {
            OS.routine_begin(0x20)

            lw t0, 0x84(a0) // t0 = fighter struct
            lw t0, 0xadc(t0) // t0 = charge level

            lli t1, 0xA // max charge

            beq t0, t1, _charged
            nop

            _uncharged:
            li a1, 0x8015B35C // ftDonkeySpecialAirNLoopSetStatus(GObj *fighter_gobj)
            b _end
            nop

            _charged:
            li a1, 0x8015B598 // ftDonkeySpecialAirNEndSetStatus(GObj *fighter_gobj)

            _end:
            jal 0x800D9480 // ftAnimEndCheckSetStatus(fighter_gobj, function);
            nop
            OS.routine_end(0x20)
        }
    }
    scope NSP_LOOP: {
        scope update: {
            OS.routine_begin(0x20)
            sw a0,0x0(sp) // save player object

            jal 0x8015B088 // ftDonkeySpecialNLoopProcUpdate(GObj *fighter_gobj)
            nop

            lw a0, 0x0(sp) // restore player object
            lw a1, 0x84(a0) // a1 = player struct

            // Normal loop takes 12 frames
            // Adjust it to take 14 at first and go down to 7 on the 10th loop
            // Charge goes from 0 to 10

            // cancel anytime
            // punch anytime

            lw at, 0xadc(a1) // at = current charge
            mtc1 at, f2
            cvt.s.w f2, f2 // f2 = current charge (float)
            li at, 0x3F333333
            mtc1 at, f4 // f4 = 0.7
            
            lui at, 0x4160
            mtc1 at, f6 // f6 = 14.0
            lui at, 0x4140
            mtc1 at, f8 // f8 = 12.0

            // frames = 12 / (14 - 0.7 * current_charge)
            mul.s f2, f2, f4 // f2 = charge * 0.7
            sub.s f2, f6, f2 // f2 = (14 - 0.7 * current_charge)
            div.s f2, f8, f2 // f2 = 12 / (14 - 0.7 * current_charge)

            jal 0x8000BB04 // gcSetAnimSpeed(fighter_gobj, speed)
            mfc1 a1, f2

            OS.routine_end(0x20)
        }
    }

    scope DSP_AIR: {
        scope initial: {
            addiu   sp, sp, -0x0020             // ~
            sw      ra, 0x001C(sp)              // ~
            sw      a0, 0x0020(sp)              // original lines 1-3

            lli     a1, DKUlt.Action.DSP_AIR    // a1 = action
            sw      r0, 0x0010(sp)              // argument 4 = 0
            or      a2, r0, r0                  // a2 = float: 0.0
            jal     0x800E6F24                  // change action
            lui     a3, 0x3F80                  // a3 = float: 1.0
            jal     0x800E0830                  // unknown common subroutine
            lw      a0, 0x0020(sp)              // a0 = player object
            b       _end
            nop

            _end:
            lw      a0, 0x0020(sp)              // a0 = player object
            lw      ra, 0x001C(sp)              // ~
            addiu   sp, sp, 0x0020              // ~
            jr      ra                          // original return logic
            nop
        }
    }

    scope USP: {
        scope physics: {
            // Mostly same as original, changes:
            // Can only accel forwards
            // Towards the end of the move, remove control and execute friction
            // for DK to stop
            addiu   sp, sp, -0x18
            sw      ra, 0x14(sp)
            sw      a0, 0x18(sp)

            lui     at, 0x4278 // at = 62.0
            mtc1    at, f2
            lw      at, 0x0078(a0) // at = current animation frame
            mtc1    at, f4

            c.lt.s  f4, f2 // if f4 < f2 (current frame < control end frame)
            nop
            bc1tl   _control // if true, we still have control
            nop

            _no_control:
            b       _friction
            nop

            _control:
            // Check if stick X is positive towards facing direction (only move forwards)
            // If stick_x * direction is negative, they're different signs
            lw      a0, 0x18(sp) // restore a0 = player object
            lw      t0, 0x0084(a0) // t0 = player struct
            lb      t1, 0x01C2(t0) // t1 = stick_x
            lw      t2, 0x0044(t0) // t2 = DIRECTION

            mult    t1, t2 // multiply both numbers
            mflo    t3 // t3 = multiplication result
            bltz    t3, _friction // if t3 < 0, they're different signs
            nop

            lui     a2, 0x3F00 // acceleration = 0.5
            lw      a0, 0x84(a0)
            move    a1, r0 // min_stick = 0
            jal     0x800D89E0 // ftPhysicsApplyClampGroundVelStickRange(fp, min_stick, a2 (accel), a3 (max_speed));
            lui     a3,0x41F0 // max_speed = 30.0

            _friction:
            lui     a1, 0x3F80 // 1.0
            lw      a0, 0x18(sp) // restore a0 = player object
            jal     0x800D8978 // ftPhysicsSetGroundVelFriction(FTStruct *fp, f32 friction)
            lw      a0, 0x84(a0) // a0 = player struct
            jal     0x800D87D0 // ftPhysicsSetGroundVelTransferAir(fighter_gobj);
            lw      a0,0x18(sp) // restore a0 = player object

            _end:
            lw      ra,0x14(sp)
            addiu   sp,sp,0x18
            jr      ra
            nop
        }
    }
}