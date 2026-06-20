// @ Description
// These constants must be defined for an item.
constant SPAWN_ITEM(cypher_stage_setting_)
constant SHOW_GFX_WHEN_SPAWNED(OS.FALSE)
constant PICKUP_ITEM_MAIN(0)
constant PICKUP_ITEM_INIT(0)
constant DROP_ITEM(0)
constant THROW_ITEM(0)
constant PLAYER_COLLISION(0)

// @ Description
// Offset to item in file.
constant FILE_OFFSET(0x40)

constant CYPHER_FGM(0x33)                // 0x33 = fan smack
constant DAMAGE_TYPE(Damage.id.NORMAL)
constant INITIAL_DAMAGE(1)

constant EXPLODE_TIME(500)
constant DAMAGE_FUSE_TIME(1)

constant INITIAL_SPEED(0x41D0) // 26.0
constant ACCELERATION(0x3F80) // 1.0
constant MAX_SPEED(0x4220) // 40.0
constant ROTATE_SPEED(0x3D8EFA35) // float: 4.0 deg in radians

constant DECELERATION_SPEED(0x3F40) // 0.75
constant GRAVITY(0x3FC0) // 1.5
constant MAX_FALL_SPEED(0x4270) // 60.0

scope cypher_attributes {
    constant DURATION(0x0000)
    constant GRAVITY(0x0004)
    constant MAX_FALL_SPEED(0x0008)
    constant ROTATION(0x000C)
    struct:
    dw EXPLODE_TIME                    // 0x0000 - duration (int)
    float32 3.6                             // 0x0004 - gravity
    float32 63                              // 0x0008 - max fall speed
    float32 0                               // 0x000C - rotation speed
}

scope VARIABLES: {
    constant RELEASED(0x350)
    constant SPEED(0x350)
    constant ANGLE(0x354)
    constant HIT_OPPONENT(0x358)
    constant DISABLED(0x35C)
}

OS.align(16)
item_info_array:
constant ITEM_INFO_ARRAY_ORIGIN(origin())
dw 0x00000000                           // 0x00 - item ID placeholder
dw Character.SNAKE_file_6_ptr           // 0x04 - address of file pointer
dw Snake.FILE_OFFSETS.MERGED_FILERESOURCE_6_3 // 0x08 - offset to item footer
dw 0x1B000000                           // 0x0C - ? either 0x1B000000 or 0x1C000000 - possible argument
dw 0                                    // 0x10 - ?
cypher_item_states:
// state 0 - main/control
dw cypher_main_                        // 0x14 - state 0 main
dw 0                                      // 0x18 - state 0 collision
dw cypher_hurtbox_collision_           // 0x1C - state 0 hitbox collision w/ hurtbox
dw cypher_hurtbox_collision_           // 0x20 - state 0 hitbox collision w/ shield
dw cypher_hurtbox_collision_           // 0x24 - state 0 hitbox collision w/ shield edge
dw 0                                      // 0x28 - state 0 unknown (maybe absorb)
dw 0                                      // 0x2C - state 0 hitbox collision w/ reflector
dw cypher_hitbox_collision_            // 0x30 - state 0 hurtbox collision w/ hitbox
OS.align(16)

// @ Description
// Subroutine which sets up initial properties of cypher.
// a0 - player object
// a1 - item info array
// a2 - x/y/z coordinates to create item at
// a3 - unknown x/y/z offset
scope cypher_stage_setting_: {
    addiu   sp, sp,-0x0060                  // allocate stack space
    sw      s0, 0x0020(sp)                  // ~
    sw      s1, 0x0024(sp)                  // ~
    sw      ra, 0x0028(sp)                  // store s0, s1, ra
    sw      a0, 0x0038(sp)                  // 0x0038(sp) = player object
    sw      a2, 0x003C(sp)                  // 0x003C(sp) = original x/y/z
    jal     0x8016E174                      // create item
    sw      r0, 0x0010(sp)                  // argument 4(unknown) = 0
    beqz    v0, _end                        // end if no item was created
    or      s0, v0, r0                      // s0 = item object
    li      s1, cypher_attributes.struct   // s1 = cypher_attributes.struct

    // item is created
    sw      v0, 0x0040(sp)                  // 0x0040(sp) = item object
    lw      v1, 0x0084(v0)                  // v1 = item special struct
    sw      v1, 0x002C(sp)                  // 0x002C(sp) = item special struct
    lw      a0, 0x0074(v0)                  // a0 = item first joint (joint 0)
    sw      a0, 0x0030(sp)                  // 0x0030(sp) = item joint 0
    lli     a1, 0x002E                      // a1(render routine?) = 0x2E
    jal     0x80008CC0                      // set up render routine?
    or      a2, r0, r0                      // a2 (unknown) = 0
    lw      a0, 0x0030(sp)                  // ~
    lw      a0, 0x0010(a0)                  // a0 = item second joint (joint 1)
    lli     a1, 0x002E                      // a1(render routine?) = 0x2E
    jal     0x80008CC0                      // set up render routine?
    or      a2, r0, r0                      // a2 (unknown) = 0

    ecb_size: {
        lw      v1, 0x002C(sp)          // v1 = item special struct
        sw      r0, 0x0074(v1)          // ecb center = 0
        lui     at, 0x4248              // at = 50.0
        sw      at, 0x0070(v1)          // ecb top
        lui     at, 0xC248              // at = -50.0
        sw      at, 0x0078(v1)          // ecb bottom
        lui     at, 0x4248              // at = 50.0
        sw      at, 0x007C(v1)          // ecb width
    }

    lw      v1, 0x002C(sp)                  // v1 = item special struct
    lbu     t9, 0x0158(v1)                  // ~
    ori     t9, t9, 0x0010                  // ~
    sb      t9, 0x0158(v1)                  // enable unknown bitflag
    lw      t6, cypher_attributes.DURATION(s1)  // t6 = duration
    sw      t6, 0x02C0(v1)                  // store duration\
    lli     t7, 0x0004                      // ~
    sw      t7, 0x0354(v1)                  // unknown value(bit field?) = 0x00000004

    lw      a0, 0x0038(sp)                  // a0 = player object
    lw      v1, 0x002C(sp)                  // v1 = item special struct
    sw      a0, 0x0008(v1)                  // set player as projectile owner
    lw      t6, 0x0084(a0)                  // t6 = player struct
    lbu     at, 0x000C(t6)                  // load player team
    sb      at, 0x0014(v1)                  // save player's team to item to prevent damage when team attack is off
    lbu     at, 0x000D(t6)                  // at = player port
    sb      at, 0x0015(v1)                  // store player port for combo ownership
    // sw      v1, 0x0AE0(t6)                  // save object address to free space in player struct
    sw      t6, 0x01C4(v1)                  // save player struct to custom variable space in the item special struct

    li      s1, cypher_attributes.struct   // s1 = cypher_attributes.struct

    sw      r0, VARIABLES.RELEASED(v1) // released = FALSE
    sw      r0, 0x010C(v1) // disable hitbox

    lw      v0, 0x0040(sp) // v0 = item object
    lw      t0, 0x0074(v0) // t0 = item first joint (joint 0)
    li      at, 0x40490FDB // at = PI = 180 deg but in radians
    sw      at, 0x0038(t0) // x rotation = 0

    _scale_graphic:
    lui at, 0x3FC0  // at = 1.5
    sw at, 0x40(t0) // set x scale
    sw at, 0x44(t0) // set y scale
    sw at, 0x48(t0) // set z scale

    _flip_graphic:
    lw      t6, 0x0038(sp)                  // ~
    lw      t6, 0x0084(t6)                  // t6 = player struct
    lw      t6, 0x0044(t6)                 // t6 = player direction
    addiu   at, r0, -1
    bne     t6, at, _continue
    nop
    // negate X scale (flip graphic)
    lw      v0, 0x0040(sp) // v0 = item object
    lw      t0, 0x0074(v0) // t0 = item first joint (joint 0)
    lwc1    f2, 0x40(t0) // f2 = x scale
    neg.s   f2, f2 // f2 = -x scale
    swc1    f2, 0x40(t0) // set x scale to -x scale

    _continue:
    sw      t6, 0x0024(v1) // set direction

    lli     at, 0x0001                      // ~
    sw      at, 0x0248(v1)                  // enable hurtbox
    // sw      at, 0x010C(v1)                  // enable hitbox

    // lui     t2, 0x43E1 // size = 450
    // sw      t2, 0x0138(v0)
    lli     at, 6 // damage
    sw      at, 0x0110(v1)
    lli     at, 42  // hit angle
    sw      at, 0x013C(v1)
    lli     at, 63 // base knockback
    sw      at, 0x0148(v1)
    lli     at, 17 // knockback growth
    sw      at, 0x0140(v1)
    addiu   at, r0, FGM.hit.KICK_M // hit sound
    sh      at, 0x156(v1)

    // Set hurtbox size
    lui at, 0x4316
    sw at, 0x258(v1) // save hurtbox size X
    sw at, 0x25C(v1) // save hurtbox size Y
    sw at, 0x260(v1) // save hurtbox size Z

    // Make projectile not interact with other hitboxes (not trade hits) - impossible to set_off
    // lbu at, 0x158(v1)
    // andi at, at, 0xFF7F
    // sb at, 0x158(v1)

    // lhu     at, 0x02CE(v1)                  // ~
    // ori     at, at, 0x0080                  // ~
    // sh      at, 0x02CE(v1)                  // enable bitflag which allows owner's hitboxes to collide with the hurtbox

    li      t0, cypher_attributes.struct   // t0 = cypher_attributes.struct
    lw      t1, cypher_attributes.MAX_FALL_SPEED(t0)    // t1 = MAX_SPEED
    sw      t1, 0x01C8(v1)                  // max speed = MAX_SPEED
    sw      r0, 0x01CC(v1)                  // rotation direction = 0
    sw      r0, 0x01D0(v1)                  // hitbox refresh timer = 0
    li      t1, cypher_blast_zone_         // load cypher blast zone routine
    sw      t1, 0x0398(v1)                  // save routine to part of item special struct that carries unique blast wall destruction routines

    sw      r0, 0x0100(v1)                  // remove possible reference to character ID use by Bomb

    lw      a1, 0x0038(sp)					// ~
    lw      a1, 0x0084(a1)                  // ~
    addiu   a2, a1, 0x0078                  // a2 = unknown
    lw      a1, 0x0078(a1)                  // a1 = player x/y/z coordinates
    jal     0x800DF058                      // check clipping
    lw      a0, 0x0040(sp)                  // a0 = item object

    _end:
    or      v0, s0, r0                      // v0 = item object
    lw      s0, 0x0020(sp)                  // ~
    lw      s1, 0x0024(sp)                  // ~
    lw      ra, 0x0028(sp)                  // load s0, s1, ra
    jr      ra                              // return
    addiu   sp, sp, 0x0060                  // deallocate stack space
}

// @ Description
// Main subroutine for the cypher.
// a0 = item object
scope cypher_main_: {
    addiu   sp, sp,-0x0040                  // allocate stack space
    sw      s0, 0x0014(sp)                  // ~
    sw      s1, 0x0018(sp)                  // ~
    sw      s2, 0x001C(sp)                  // ~
    sw      ra, 0x0030(sp)                  // store ra, s0-s2

    lw      s0, 0x0084(a0)                  // s0 = item special struct
    or      s1, a0, r0                      // s1 = item object

    lw t0, VARIABLES.RELEASED(s0) // t0 = released state
    bnez t0, _detached
    nop

    scope _attached: {
        lw t3, 0x8(s0) // t3 = owner
        lw t3, 0x84(t3) // t3 = owner player struct

        // owner must be Snake
        lw t1, 0x8(t3) // t1 = character id
        ori t2, r0, Character.id.SNAKE
        bne t1, t2, _release // release if character is not Snake (somehow)
        nop
        // snake must be in a usp action
        lw      t1, 0x0024(t3) // t1 = current action
        lli     t2, Snake.Action.CYPHERSTART
        beq     t1, t2, _action_check_passed // branch if action is nikita operation
        lli     t2, Snake.Action.CYPHERAIRSTART
        beq     t1, t2, _action_check_passed // branch if action is nikita air operation
        lli     t2, Snake.Action.CYPHERAIRHANG
        beq     t1, t2, _action_check_passed // branch if action is nikita air operation
        nop
        // If we're here, the action is not a cypher operation. Release
        _release: {
            // TODO: release cypher
            lli at, 0x1
            sw at, VARIABLES.RELEASED(s0) // released = TRUE
            lli at, 0x1
            sw at, 0x10C(s0) // enable hitbox

            lui at, 0x4120 // at = 10.0
            sw at, 0x30(s0) // save as item y speed
            
            b _end
            nop
        }

        _action_check_passed:
        addiu sp, sp, -0x20 // allocate space for a vec3

        sw r0, 0x0(sp)
        sw r0, 0x4(sp)
        sw r0, 0x8(sp) // vec3 at 0x0(sp) = {0, 0, 0}
        addiu a1, sp, 0x0 // a1 = vec3 pointer

        jal 0x800EDF24 // gmCollisionGetFighterPartsWorldPosition(DObj *main_dobj, Vec3f *vec) (part, &offset) (updates vec3 in a1)
        lw a0, 0x0928(t3) // a0 = part 0xC (right hand) struct
        
        lw t4, 0x74(s1) // t4 = item position at 1C(t4), 20(t4), 24(t4)

        lw t3, 0x8(s0) // t3 = owner
        lw t3, 0x84(t3) // t3 = owner player struct

        // X
        lwc1 f2, 0x0(sp) // f2 = vec3 x
        lwc1 f6, 0x44(t3) // f6 = player direction
        cvt.s.w f6, f6 // convert player direction to float
        lui at, 0x42A0 // at = 80.0
        mtc1 at, f4 // f4 = offset
        mul.s f4, f4, f6 // f4 = offset * player direction
        add.s f2, f2, f4 // f2 = vec3 x + offset
        swc1 f2, 0x1C(t4) // set item x position to vec3 x + offset

        // Y
        lwc1 f2, 0x4(sp) // f2 = vec3 y
        lui at, 0x4316 // at = 150.0
        mtc1 at, f4 // f4 = offset
        add.s f2, f2, f4 // f2 = vec3 y + offset
        swc1 f2, 0x20(t4) // set item y position to vec3 y + offset

        sw r0, 0x28(t4) // set item z position to 0
        // lw at, 0x8(sp) // at = vec3 z
        // sw at, 0x24(t4) // set item z position to vec3 z

        addiu sp, sp, 0x20 // deallocate space

        // set speed as owner speed
        lw at, 0x8C(t3) // at = player x speed
        sw at, 0x2C(s0) // set item x speed to player x speed

        _end:
    }
    b _common
    nop

    scope _detached: {
        scope _update_speed: {
            constant MAX_RISE_SPEED(0x4220) // 40.0
            constant RISE_ACCEL(0x3F80) // 1.0

            lwc1 f2, 0x30(s0) // f2 = y speed

            lui at, RISE_ACCEL
            mtc1 at, f4 // f4 = RISE_ACCEL

            add.s f2, f2, f4 // f2 = y speed + RISE_ACCEL

            lui at, MAX_RISE_SPEED
            mtc1 at, f4 // f4 = MAX_RISE_SPEED

            // if y speed is greater than MAX_RISE_SPEED, set it to MAX_RISE_SPEED
            c.le.s f2, f4 // ~
            nop // ~
            bc1fl _save_speed // branch if y speed < MAX_RISE_SPEED...
            mov.s f2, f4 // ...and set y speed to MAX_RISE_SPEED

            _save_speed:
            swc1 f2, 0x30(s0) // store y speed

            _end:
        }

        // scope _move: {
        //     lw t0, 0x74(s1) // t0 = item position at 1C(t0), 20(t0), 24(t0)

        //     lwc1 f2, 0x1C(t0) // f2 = item x position
        //     lwc1 f4, 0x2C(s0) // f4 = x speed
        //     add.s f2, f2, f4 // f2 = item x position + x speed
        //     swc1 f2, 0x1C(t0) // store item x position

        //     lwc1 f2, 0x20(t0) // f2 = item y position
        //     lwc1 f4, 0x30(s0) // f4 = y speed
        //     add.s f2, f2, f4 // f2 = item y position + y speed
        //     swc1 f2, 0x20(t0) // store item y position

        //     _end:
        // }
    }

    _common:

    _check_damage:
    lw at, 0x1c(s0) // load item->percent_damage (total damage received)
    slti at, at, 13 // at = 0 if damage >= 13; at = 1 if damage < 13
    bnez at, _check_duration  // branch if damage < 13 (continue normal operation)
    nop
    // if we're here, we took enough damage to explode
    lw a0, 0x0074(s1) // a0 = item first joint struct
    jal 0x801005C8 // create exploseion gfx
    addiu a0, a0, 0x001C // a0 = item x/y/z
    b _explode
    nop

    _check_duration:
    lw v0, 0x02C0(s0) // v0 = remaining duration
    bnezl v0, _update_duration // branch if duration has not ended
    nop
    b _explode
    nop

    _update_duration:
    addiu t7, v0,-0x0001 // t7 = decremented duration
    sw t7, 0x02C0(s0) // store updated duration

    _end:
    lw      s0, 0x0014(sp)                  // ~
    lw      s1, 0x0018(sp)                  // ~
    lw      s2, 0x001C(sp)                  // ~
    lw      ra, 0x0030(sp)                  // store ra, s0-s2
    addiu   sp, sp, 0x0040                  // deallocate stack space
    jr      ra                              // return
    or      v0, r0, r0                      // v0 = 0

    scope _explode: {
        _clear_reference:
        // set owner's reference to cypher to 0 (tmp variable 1)
        lw      t0, 0x0008(s0) // t0 = item owner
        lw      t0, 0x0084(t0) // t0 = owner player struct
        lw      at, 0x017C(t0) // at = owner's temp variable 1
        bne     s1, at, _continue // branch if owner's temp variable 1 is not the cypher item
        nop
        sw      r0, 0x017C(t0) // set player's cypher reference to 0

        _continue:
        lw      s0, 0x0014(sp) // ~
        lw      s1, 0x0018(sp) // ~
        lw      s2, 0x001C(sp) // ~
        lw      ra, 0x0030(sp) // store ra, s0-s2
        addiu   sp, sp, 0x0040 // deallocate stack space
        jr      ra // return
        lli     v0, 0x1 // v0 = 1 (destroy)
    }
}

// @ Description
// Changes a cypher to the aerial/main state.
// a0 = item object
scope cypher_begin_main_: {
    addiu   sp, sp,-0x0018                  // allocate stack space
    sw      ra, 0x0014(sp)                  // ~
    sw      a0, 0x0018(sp)                  // store ra, a0
    lw      a0, 0x0084(a0)                  // a0 = item special struct
    // lbu     t0, 0x02CE(a0)               // t0 = unknown bitfield
    // andi    t0, t0, 0xFF7F               // disable item pickup bit
    // sb      t0, 0x02CE(a0)               // store updated bitfield
    lli     at, 0x0001                      // ~
    jal     0x80173F78                      // bomb subroutine, sets kinetic state value
    nop
    // sw      r0, 0x010C(a0)                  // disable hitbox
    lw      a0, 0x0018(sp)                  // a0 = item object
    li      a1, cypher_item_states         // a1 = object state base address
    jal     0x80172EC8                      // change item state
    ori     a2, r0, r0                      // a2 = 0 (aerial/main state)
    lw      ra, 0x0014(sp)                  // load ra
    jr      ra                              // return
    addiu   sp, sp, 0x0018                  // deallocate stack space
}

// @ Description
// Runs when a cypher's hitbox collides with a hurtbox.
// a0 = item object
scope cypher_hurtbox_collision_: {
    OS.routine_begin(0x20)
    lli v0, 0x1 // destroy
    OS.routine_end(0x20)
}

// @ Description
// this subroutine handles hitbox collision for the cypher
// a0 = item object
scope cypher_hitbox_collision_: {
    lw v0, 0x0084(a0) // v0 = item special struct

    sw r0, 0x2bc(v0) // ip->damage_lag = 0 -> do not enter hitlag

    jr      ra
    or      v0, r0, r0 // return 0 (do not destroy)
}

// @ Description
// this routine gets run by whenever a projectile crosses the blast zone. The purpose here is to restock Peppy's cyphers
scope cypher_blast_zone_: {
    jr ra // return
    lli v0, 0x1 // destroy
}
