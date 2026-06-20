// These constants must be defined for a menu item.
define LABEL("Input Buffering")
constant VALUE_TYPE(CharacterSelectDebugMenu.value_type.STRING)
constant MIN_VALUE(0)
constant MAX_VALUE(1)
constant DEFAULT_VALUE(0)
// bitmask: [vs] [1p] [training] [bonus1] [bonus2] [allstar]
constant APPLIES_TO(0b111111)
// bitmask: [human] [cpu]
constant APPLIES_TO_HUMAN_CPU(0b10)
constant VALUE_ARRAY_POINTER(InputBuffer.input_buffer_table)
constant ONCHANGE_HANDLER(0)
constant DISABLES_HIGH_SCORES(OS.TRUE)

// toggle status for each player slot
input_buffer_table:
dw  0
dw  0
dw  0
dw  0

// Holds pointers to value labels
string_table:
dw string_off
dw string_on

// Value labels
string_on:; String.insert("On")
string_off:; String.insert("Off")

// Every frame, start by saving the current input to our buffer
// 0x800E1260
// void ftMainProcUpdateInterrupt(GObj *fighter_gobj)
scope buffer_update: {
    OS.patch_start(0x5CA70, 0x800E1270)
    jal buffer_update
    nop
    _return:
    OS.patch_end()

    // a2 = player struct

    // check if toggle is active for this slot
    lb at, 0xD(a2) // at = player port
    li t0, input_buffer_table // t0 = stick jump table
    sll at, at, 0x2
    addu t0, t0, at // a3 = player entry in input_buffer_table
    lw at, 0x0(t0) // at = entry
    beqz at, _end // branch if disabled
    nop

    // do not update buffer on the first frame of an action
    // this would cause the inputs that led to the action to be buffered
    lw at, 0x1C(a2)
    beqz at, _end
    nop

    // get input buffer struct for player and load it into t9
    or t0, r0, r0 // t0 (player index) = 0
    scope _loop_players: {
        OS.read_word(Global.p_struct_head, at) // at = p1 player struct
        _loop:
        lw t1, 0x4(at) // t1 = player object
        beqz t1, _next // if no player object, get next player struct
        nop
        beq t1, a0, _end // if it's us, exit
        nop
        _next:
        lw at, 0x0(at) // at = next player struct
        bnez at, _loop // loop while there are more players to check
        addiu t0, t0, 0x1
        _end:
    }
    li at, table.pointers
    sll t0, t0, 2
    addu t0, t0, at // t0 = &table.pointers[player port]
    lw t9, 0x0(t0) // t9 = input buffer struct for player

    _check_buttons:
    lh t0, 0x1BE(a2) // button press mask 
    bnez t0, _update_buffer // if any button is pressed, update buffer
    nop

    _check_stick:
    // stick-only buffer only updates if no button actions were buffered
    // stick buffer is only triggered if:
    // - no button press buffer is active, or
    // - stick_x or stick_y has changed since last frame and the absolute value got higher, or
    // - stick_x or stick_y has changed sign since last frame (crossed zero)

    lb at, 0x0(t9) // time counter
    beq at, r0, _check_stick_continue // if no buffer is active, continue checking stick
    nop

    lh t1, 0x8(t9) // t1 = buffered button press
    bnez t1, _decrease_buffer_time // if any button is buffered, do not update stick
    nop

    _check_stick_continue:
    scope stick_x: {
        lb t0, 0x1C2(a2) // stick_x
        lb t1, 0x1C4(a2) // previous stick_x

        // is stick x == 0?
        beqz t0, _end
        nop

        // did stick_x change?
        beq t0, t1, _end // if no change, skip
        nop

        lb t2, 0x5(t9) // buffered stick_x

        // are they in different directions?
        xor at, t0, t2
        andi at, at, 0x80
        bnez at, _update_buffer // if sign changed, update buffer
        nop

        // did absolute value increase?
        abs t0, t0
        abs t2, t2
        slt at, t2, t0
        bnez at, _update_buffer // if abs value increased, update buffer
        nop

        _end:
    }

    scope stick_y: {
        lb t0, 0x1C3(a2) // stick_y
        lb t1, 0x1C5(a2) // previous stick_y

        // is stick y == 0?
        beqz t0, _end
        nop

        // did stick_y change?
        beq t0, t1, _end // if no change, skip
        nop

        lb t2, 0x6(t9) // buffered stick_y

        // are they in different directions?
        xor at, t0, t2
        andi at, at, 0x80
        bnez at, _update_buffer // if sign changed, update buffer
        nop

        // did absolute value increase?
        abs t0, t0
        abs t2, t2
        slt at, t2, t0
        bnez at, _update_buffer // if abs value increased, update buffer
        nop

        _end:
    }

    // if here we're not updating buffer, so let's decrease the time counter
    _decrease_buffer_time:
    // decrease time counter
    lbu t1, 0x0(t9) // t1 = current time counter
    beq t1, r0, _end // if time counter is 0, do nothing
    nop
    addiu t1, t1, -1 // decrement time counter
    sb t1, 0x0(t9) // store new time counter
    _end:
    lw v0, 0x18c(a2) // original line 1
    j _return
    sll v0, v0, 0x1E // original line 2

    scope _update_buffer: {
        // update time counter
        lli at, 10
        lb t0, 0x0(t9) // current time counter
        beq t0, at, _end // if time counter is already 10, do not update
        nop
        sb at, 0x0(t9) // time counter = 10

        // update stick values
        lb at, 0x1C2(a2) // stick_x
        sb at, 0x5(t9) // stick_x
        lb at, 0x1C3(a2) // stick_y
        sb at, 0x6(t9) // stick_y

        // update tap stick values: 268, 269
        lb at, 0x268(a2) // tap_stick_x
        sb at, 0x1(t9) // tap_stick_x
        lb at, 0x269(a2) // tap_stick_y
        sb at, 0x2(t9) // tap_stick_y

        // update hold stick values: 26A, 26B
        lb at, 0x26A(a2) // hold_stick_x
        sb at, 0x3(t9) // hold_stick_x
        lb at, 0x26B(a2) // hold_stick_y
        sb at, 0x4(t9) // hold_stick_y

        // update button press values
        lh at, 0x1BE(a2) // button press mask
        sh at, 0x8(t9) // button press

        b _end
        nop
    }
}

// ftMainSetStatus: 800E6F24 + B88
scope on_action_change: {
    OS.patch_start(0x632AC, 0x800E7AAC)
    j on_action_change
    nop
    _return:
    OS.patch_end()

    // s1 = player struct
    lw a0, 0x4(s1) // a0 = player object

    // check if toggle is active for this slot
    lb at, 0xD(s1) // at = player port
    li t0, input_buffer_table // t0 = stick jump table
    sll at, at, 0x2
    addu t0, t0, at // a3 = player entry in input_buffer_table
    lw at, 0x0(t0) // at = entry
    beqz at, _end // branch if disabled
    nop

    // for these actions, we do not clear the buffer
    lw t0, 0x24(s1)
    lli t1, Action.JumpSquat
    beq t0, t1, _end
    lli t1, Action.ShieldJumpSquat
    beq t0, t1, _end
    lli t1, Action.LandingLight
    beq t0, t1, _end
    lli t1, Action.LandingHeavy
    beq t0, t1, _end
    lli t1, Action.LandingSpecial
    beq t0, t1, _end
    lli t1, Action.LandingAirN
    beq t0, t1, _end
    lli t1, Action.LandingAirF
    beq t0, t1, _end
    lli t1, Action.LandingAirB
    beq t0, t1, _end
    lli t1, Action.LandingAirU
    beq t0, t1, _end
    lli t1, Action.LandingAirD
    beq t0, t1, _end
    lli t1, Action.LandingAirX
    beq t0, t1, _end
    lli t1, Action.ShieldDrop
    beq t0, t1, _end
    lli t1, Action.Turn
    beq t0, t1, _end
    nop
    
    // if buffer time counter is not zero, update player struct values with our stored values
    or t0, r0, r0 // t0 (player index) = 0
    scope _loop_players: {
        OS.read_word(Global.p_struct_head, at) // at = p1 player struct
        _loop:
        lw t1, 0x4(at) // t1 = player object
        beqz t1, _next // if no player object, get next player struct
        nop
        beq t1, a0, _end // if it's us, exit
        nop
        _next:
        lw at, 0x0(at) // at = next player struct
        bnez at, _loop // loop while there are more players to check
        addiu t0, t0, 0x1
        _end:
    }
    li at, table.pointers
    sll t0, t0, 2
    addu t0, t0, at // t0 = &table.pointers[player port]
    lw t0, 0x0(t0) // t0 = input buffer struct for player
    lbu t1, 0x0(t0) // t1 = time counter
    beq t1, r0, _clear_buffer // if time counter is 0, do not apply inputs
    nop
    // update player struct with buffered values
    lb at, 0x5(t0) // stick_x
    sb at, 0x1C2(s1) // stick_x
    lb at, 0x6(t0) // stick_y
    sb at, 0x1C3(s1) // stick_y
    lb at, 0x1(t0) // tap_stick_x
    sb at, 0x268(s1) // tap_stick_x
    lb at, 0x2(t0) // tap_stick_y
    sb at, 0x269(s1) // tap_stick_y
    lb at, 0x3(t0) // hold_stick_x
    sb at, 0x26A(s1) // hold_stick_x
    lb at, 0x4(t0) // hold_stick_y
    sb at, 0x26B(s1) // hold_stick_y
    lh at, 0x8(t0) // button press
    lh t1, 0x1BE(s1) // current button press mask
    or at, at, t1 // add buffered input
    sh at, 0x1BE(s1) // button press mask
    lh t1, 0x1BC(s1) // current button held mask
    or at, at, t1 // add buffered input
    sh at, 0x1BC(s1) // button held mask

    _clear_buffer:
    sb r0, 0x0(t0) // clear time counter
    sb r0, 0x1(t0) // clear buffered tap_stick_x
    sb r0, 0x2(t0) // clear buffered tap_stick_y
    sb r0, 0x3(t0) // clear buffered hold_stick_x
    sb r0, 0x4(t0) // clear buffered hold_stick_y
    sb r0, 0x5(t0) // clear buffered stick_x
    sb r0, 0x6(t0) // clear buffered stick_y
    sh r0, 0x8(t0) // clear buffered button press

    _end:
    lw s1, 0x18(sp) // original line 1: restore s1
    jr ra // original line 2: return
    addiu sp, sp, 0x90 // original line 3
}

scope table: {
    // time counter: 1
    // tap_stick_x: 1
    // tap_stick_y: 1
    // hold_stick_x: 1
    // hold_stick_y: 1
    // stick_x: 1
    // stick_y: 1
    // padding: 1
    // button press: 2
    // total: 12

    p1:; fill 16;
    p2:; fill 16;
    p3:; fill 16;
    p4:; fill 16;
    p5:; fill 16;
    p6:; fill 16;
    p7:; fill 16;
    p8:; fill 16;

    // we're creating 8 slots to support Ice Climbers in case they're in the build
    scope pointers: {
        dw p1; dw p2; dw p3; dw p4;
        dw p5; dw p6; dw p7; dw p8;
    }
}
