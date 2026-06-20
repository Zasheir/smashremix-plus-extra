scope setup: {
    OS.routine_begin(0x60)

    // Check if hazards disabled
    li      a0, Toggles.entry_hazard_mode
    lw      a1, 0x0004(a0)
    andi    a1, a1, 0x0001 // t0 = 1 if hazard_mode is 1 or 3, 0 otherwise
    bnez    a1, _end // don't register if hazards are off
    nop

    Render.register_routine(wallcheck)

    _end:
    OS.routine_end(0x60)
}

scope wallcheck: {
    OS.routine_begin(0x60)

    // For each fighter struct, check if they are colliding with a wall
    OS.read_word(Global.p_struct_head, at) // at = p1 player struct
    _loop:
    lw t0, 0x0004(at) // t0 = player object
    beqz t0, _next // if no player object, get next player struct
    nop

    lw t0, 0x24(at) // t0 = current action
    lli t1, Action.WallBounce
    bne t0, t1, _next // if not wall bounce action, skip
    nop

    lw t0, 0x1C(at) // t0 = current frame (int)
    lli t1, 0x1
    bne t0, t1, _next // if not on first frame, skip
    nop

    // if here, we just hit a wall
    lui t0, 0x42C8 // ~
    mtc1 t0, f2 // f2 = 100.0
    lwc1 f4, 0x54(at) // f4 = knockback x velocity
    abs.s f4, f4
    nop
    c.le.s f2, f4 // xspeed > threshold?
    nop
    bc1f _next // speed too low
    nop

    sw at, 0x4(sp) // save at

    lw t0, 0x44(at) // t0 = facing direction
    bltz t0, ko_left // if facing left, use left
    nop
    b ko_right
    nop

    ko_left:
    jal 0x8013C454 // KO left - ftCommonDeadLeftSetStatus(GObj *fighter_gobj)
    lw a0, 0x4(at) // t0 = player object
    b _next
    lw at, 0x4(sp) // restore at

    ko_right:
    jal 0x8013C30C // KO right - ftCommonDeadRightSetStatus(GObj *fighter_gobj)
    lw a0, 0x4(at) // t0 = player object
    lw at, 0x4(sp) // restore at

    _next:
    lw at, 0x0(at) // at = next player struct
    bnez at, _loop // loop while there are more players to check
    nop
    _end:

    OS.routine_end(0x60)
}