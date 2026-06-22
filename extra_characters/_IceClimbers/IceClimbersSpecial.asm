scope OnActionChanged: {
    // a1 = new action id
    OS.routine_begin(0x20)

    lw a0, 0x4(a0) // a0 = player object
    lw s0, 0x84(a0) // s0 = player struct
    sw a0, 0x18(sp) // save player object

    // validate our brother object
    // this fixes cases where the scene changed and the pointer is invalid
    li t0, DualFighter.brother_object_link_table // t0 = brother_object_link_table address
    lbu t1, 0xD(s0) // t1 = port id
    sll t1, t1, 0x2 // t1 = port * 4
    addu t0, t0, t1 // t0 = brother_object_link_table[port]
    lw t0, 0x0(t0) // t0 = brother object
    beqz t0, _end // no brother found
    nop
    bne t0, a0, _end // skip if we're not the correct object
    nop

    // find sister object
    li t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
    lbu t1, 0xD(s0) // t1 = port id
    sll t1, t1, 0x2 // t1 = port * 4
    addu t0, t0, t1 // t0 = sister_object_link_table[port]
    lw t0, 0x0(t0) // t0 = sister object
    beqz t0, _end // no sister found
    nop
    beq t0, a0, _end // skip if we're the sister
    nop

    lw t2, 0x84(t0) // t2 = sister struct

    beqz t2, _end // skip if no struct
    nop

    lw at, 0x4(t2) // t2 = sister object
    beqz at, _end // skip if object is not in struct
    nop

    // Check distance
    // if sister not in range, skip
    lw t3, 0x78(t2) // t3 = sister player position vec3
    lwc1 f2, 0x0(t3) // f2 = sister x
    lwc1 f4, 0x4(t3) // f4 = sister y

    lw t3, 0x78(s0) // t3 = brother player position vec3
    lwc1 f6, 0x0(t3) // f6 = brother x
    lwc1 f8, 0x4(t3) // f8 = brother y

    sub.s f2, f2, f6 // f2 = sister x - brother x
    sub.s f4, f4, f8 // f4 = sister y - brother y
    mul.s f2, f2, f2 // f2 = (sister x - brother x)^2
    mul.s f4, f4, f4 // f4 = (sister y - brother y)^2
    add.s f2, f2, f4 // f2 = (sister x - brother x)^2 + (sister y - brother y)^2
    sqrt.s f2, f2 // f2 = sqrt((sister x - brother x)^2 + (sister y - brother y)^2)

    lui at, 0x447A // 1000.0
    mtc1 at, f4 // f4 = 1000.0
    c.lt.s f2, f4 // if distance < 1000.0
    nop
    bc1fl _end // if not in range, skip
    nop

    // Can go into cheer if in idle, movement actions
    lw t3, 0x14C(t2) // t3 = sister kinetic state
    bnez t3, _end // skip if aerial
    lw t3, 0x24(t2) // t3 = sister's current action
    lli at, Action.Idle
    blt t3, at, _end
    lli at, Action.TeeterStart
    bgt t3, at, _end

    lli at, Action.ThrowF
    beql a1, at, _switch_sister_action
    lli a1, IceClimbers.Action.CHEERF
    lli at, Action.ThrowB
    beql a1, at, _switch_sister_action
    lli a1, IceClimbers.Action.CHEERB

    b _end // no actions matched, skip
    nop

    _switch_sister_action:
    addiu sp, sp, -0x30
    or a0, t0, r0 // a0 = sister object
    sw r0, 0x10(sp) // argument 4 = 0
    or a2, r0, r0 // a2 = float: 0.0
    jal 0x800E6F24 // change action
    lui a3, 0x3F80 // a3 = float: 1.0
    addiu sp, sp, 0x30 // deallocate stack space

    _end:
    lw a0, 0x18(sp) // restore player object
    OS.routine_end(0x20)
}
// Set on_action_changed function
Character.table_patch_start(on_action_changed, Character.id.ICECLIMBERS, 0x4)
dw OnActionChanged
OS.patch_end()

scope _icies_fair: {
    OS.routine_begin(0x20)
    lw      t1, 0x0084(a0)  // loads player struct into t1

    // check costume to see if we're nana
    lbu     at, 0x0010(t1)  // at = costume id
    lli     t0, 0x8
    blt     at, t0, _skip
    nop

    // only apply on frame 1
    lw      t0, 0x0078(a0)  // t0 = current animation frame
    lui     at, 0x4000      // at = 2.0F

    // if frame != 1, skip
    bne     t0, at, _skip
    nop

    li      at, airFNana
    sw      at, 0x86C(t1) // update moveset pointer 1

    // set to read from first item in moveset file?
    sw      r0, 0x870(t1) // fp->motion_scripts[0][0].script_id = 0
    sw      r0, 0x8B0(t1) // fp->motion_scripts[0][1].script_id = 0
    // set the time offset we're at in the moveset file?
    lui     at, 0x4000 // 2.0
    sw      at, 0x8A8(t1) // fp->motion_scripts[0][0].script_wait = 2.0
    sw      at, 0x868(t1) // fp->motion_scripts[0][1].script_wait = 2.0

    _skip:
    OS.routine_end(0x20)
}

scope _icies_dsmash: {
    OS.routine_begin(0x20)
    lw      s0, 0x0084(a0)  // loads player struct into s0

    // check costume to see if we're nana
    lbu     at, 0x0010(s0)  // at = costume id
    lli     t0, 0x8
    blt     at, t0, _skip
    nop

    // only apply on frame 1
    lw      t0, 0x0078(a0)  // t0 = current animation frame
    lui     at, 0x4000      // at = 2.0F

    // if frame != 1, skip
    bne     t0, at, _skip
    nop

    // find brother object
    li      t0, DualFighter.brother_object_link_table // t0 = brother_object_link_table address
    lbu     t1, 0xD(s0) // t1 = port id
    sll     t1, t1, 0x02 // t1 = port * 4
    addu    t0, t0, t1 // t0 = brother_object_link_table[port]
    lw      t0, 0x0(t0) // t0 = brother object

    beqz    t0, _skip // no brother found
    nop

    lw      t1, 0x84(t0) // t1 = brother struct

    lw      t2, 0x0024(t1) // t2 = brother's current action
    lli     t3, Action.DSmash
    bne     t2, t3, _skip // skip if brother is not performing dsmash
    nop

    _set_direction:
    lw      t2, 0x44(t1) // t2 = brother facing direction
    sub     t2, r0, t2 // t2 = 0 - t2 (reverse direction)
    sw      t2, 0x44(s0) // save facing direction

    _update_model_rotation:
    // update model rotation to match direction
    mtc1        t2, f6 // f6 = facing direction
    cvt.s.w     f6, f6 // convert facing direction to float
    lui         at, 0x8013 // ~
    lwc1        f8, 0xFE90(at) // at = rotation constant
    mul.s       f8, f8, f6 // f8 = rotation constant * facing direction
    lw          t4, 0x08E8(s0) // t4 = character control joint struct (s0 = fighter struct)
    swc1        f8, 0x0034(t4) // update character rotation to match direction

    _skip:
    OS.routine_end(0x20)
}

scope IceClimbersNSP: {
    scope IceBlockItem: {
        constant SLOPE_ACCELERATION(0x4060)     // current setting - float: 3.5

        OS.align(16)
        iceblock_item_info_array:
        constant ICEBLOCK_ID(0x15)
        dw ICEBLOCK_ID                           // 0x00 - item ID (will be updated by Item.add_item
        dw Character.ICECLIMBERS_file_6_ptr     // 0x04 - address of file pointer
        dw 0x00000040                           // 0x08 - offset to item footer
        dw 0x1B000000                           // 0x0C - ? either 0x1B000000 or 0x1C000000 - possible argument
        dw 0                                    // 0x10 - ?
        iceblock_item_states:
        // state 0 - main/aerial
        dw iceblock_main_                        // 0x14 - state 0 main
        dw iceblock_collision_                   // 0x18 - state 0 collision
        dw iceblock_hurtbox_collision_           // 0x1C - state 0 hitbox collision w/ hurtbox
        dw iceblock_shield_collision           // 0x20 - state 0 hitbox collision w/ shield
        dw 0x801733E4                           // 0x24 - state 0 hitbox collision w/ shield edge
        dw 0                                    // 0x28 - state 0 unknown (maybe absorb)
        dw 0x80173434                           // 0x2C - state 0 hitbox collision w/ reflector
        dw iceblock_hitbox_collision_            // 0x30 - state 0 hurtbox collision w/ hitbox
        OS.align(16)

        // @ Description
        // Subroutine which sets up initial properties of iceblock.
        // a0 - player object
        // a1 - item info array
        // a2 - x/y/z coordinates to create item at
        // a3 - unknown x/y/z offset
        scope iceblock_stage_setting_: {
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
            li      s1, iceblock_attributes.struct   // s1 = iceblock_attributes.struct
            // item is created
            sw      v0, 0x0040(sp)                  // 0x0040(sp) = item object
            lw      v1, 0x0084(v0)                  // v1 = item special struct
            sw      v1, 0x002C(sp)                  // 0x002C(sp) = item special struct

            sw r0, 0x350(v1) // set custom variable (released) to 0

            lw      a0, 0x0074(v0)                  // a0 = item first joint (joint 0)
            sw      a0, 0x0030(sp)                  // 0x0030(sp) = item joint 0
            lli     a1, 0x002E                      // a1(render routine?) = 0x2E
            jal     0x80008CC0                      // set up render routine?
            or      a2, r0, r0                      // a2 (unknown) = 0
            // lw      a0, 0x0030(sp)                  // ~
            // lw      a0, 0x0010(a0)                  // a0 = item second joint (joint 1)
            // lli     a1, 0x002E                      // a1(render routine?) = 0x2E
            // jal     0x80008CC0                      // set up render routine?
            // or      a2, r0, r0                      // a2 (unknown) = 0

            scope _scale: {
                lui     at, 0x3FA7  // at = 1.3046875
                mtc1    at, f2 // f2 = scale multiplier

                _scale_graphic:
                lw      t0, 0x0030(sp) // t0 = item joint 0
                sw      at, 0x40(t0) // set x scale
                sw      at, 0x44(t0) // set y scale
                sw      at, 0x48(t0) // set z scale

                _rotate_graphic:
                mtc1    r0, f0 // f0 = 0.0
                swc1    f0, 0x0038(t0) // set x rotation = 0

                _scale_ecb:
                lw      t0, 0x002C(sp)          // t0 = item special struct

                lwc1    f0, 0x0070(t0)          // f0 = ecb top
                mul.s   f0, f0, f2              // f0 = ecb top * scale
                swc1    f0, 0x0070(t0)          // update ecb top

                lwc1    f0, 0x0074(t0)          // f0 = ecb center
                mul.s   f0, f0, f2              // f0 = ecb center * scale
                swc1    f0, 0x0074(t0)          // update ecb center

                lwc1    f0, 0x0078(t0)          // f0 = ecb bottom
                mul.s   f0, f0, f2              // f0 = ecb bottom * scale
                swc1    f0, 0x0078(t0)          // update ecb bottom

                lwc1    f0, 0x007C(t0)          // f0 = ecb width
                mul.s   f0, f0, f2              // f0 = ecb width * scale
                swc1    f0, 0x007C(t0)          // update ecb width

                _scale_hitbox:
                lw      t0, 0x002C(sp)          // t0 = item special struct
                lui     at, 0x42C8
                sw      at, 0x138(t0)          // save hitbox size
                sw      at, 0x258(t0)           // save hurtbox size X
                sw      at, 0x25C(t0)           // save hurtbox size Y
                sw      at, 0x260(t0)           // save hurtbox size Z
            }

            _setup_hitbox:
            lw      t0, 0x2C(sp) // t0 = item special struct
            li      at, 0x0004
            sw      at, 0x0110(t0) // hitbox damage
            li      at, 0x0169 // 361
            sw      at, 0x013C(t0) // // hit angle
            li      at, 0x0005
            sw      at, 0x0148(t0) // base knockback
            li      at, 0x0032 // 50
            sw      at, 0x0140(t0) // knockback growth

            lw      v1, 0x002C(sp)                  // v1 = item special struct
            lbu     t9, 0x0158(v1)                  // ~
            ori     t9, t9, 0x0010                  // ~
            sb      t9, 0x0158(v1)                  // enable unknown bitflag
            lw      t6, iceblock_attributes.DURATION(s1)  // t6 = duration
            sw      t6, 0x02C0(v1)                  // store duration
            lli     t7, 0x0004                      // ~
            sw      t7, 0x0354(v1)                  // unknown value(bit field?) = 0x00000004
            lli     at, 0x1
            sw      at, 0x108(v1)                   // set aerial state

            lwc1    f12, iceblock_attributes.ANGLE(s1) // f12 = ANGLE
            // ultra64 cosf function
            jal     0x80035CD0                      // f0 = cos(ANGLE)
            swc1    f12, 0x0050(sp)                 // 0x0050(sp) = ANGLE
            lw      t6, 0x0038(sp)                  // ~
            lw      t6, 0x0084(t6)                  // t6 = player struct
            lwc1    f10, 0x0044(t6)                 // ~
            cvt.s.w f10, f10                        // f10 = DIRECTION

            // lwc1    f6, 0x0B20(t6)                  // ~
            // cvt.s.w f6, f6                          // f6 = SPEED
            lui     at, 0x4220 // 40.0
            mtc1    at, f6 // f6 = 40.0

            mul.s   f12, f6, f10                    // f12 = x velocity (SPEED * DIRECTION)
            lw      v1, 0x002C(sp)                  // v1 = item special struct
            swc1    f12, 0x002C(v1)                 // store x velocity
            lw      a0, 0x0038(sp)                  // a0 = player object
            lw      v1, 0x002C(sp)                  // v1 = item special struct
            sw      a0, 0x0008(v1)                  // set player as projectile owner
            lw      t6, 0x0084(a0)                  // t6 = player struct
            lbu     at, 0x000C(t6)                  // load player team
            sb      at, 0x0014(v1)                  // save player's team to item to prevent damage when team attack is off
            lbu     at, 0x000D(t6)                  // at = player port
            sb      at, 0x0015(v1)                  // store player port for combo ownership
            lw      at, 0x0040(sp)                  // 0x0040(sp) = item object

            _setup_references:
            sw      at, 0x0B20(t6)                  // save object address to free space in player struct
            sw      t6, 0x01C4(v1)                  // save player struct to custom variable space in the item special struct

            scope _assign_slot_in_player_struct: {
                lw t0, 0xADC(t6) // t0 = player struct's first iceblock slot
                bnez t0, _slot_2
                nop
                sw at, 0xADC(t6)
                addiu t0, t6, 0xADC // t0 = slot address
                b _end
                sw t0, 0x358(v1) // save slot address so we can cleanup on deletion

                _slot_2:
                sw at, 0xAE0(t6)
                addiu t0, t6, 0xAE0 // t0 = slot address
                sw t0, 0x358(v1) // save slot address so we can cleanup on deletion

                _end:
            }

            sw      r0, 0x0030(v1)                  // y velocity = 0
            sw      r0, 0x0034(v1)                  // z velocity = 0
            lli     at, 0x0001                      // ~
            sw      r0, 0x0248(v1)                  // disable hurtbox
            sw      r0, 0x010C(v1)                  // disable hitbox
            lhu     at, 0x02CE(v1)                  // ~
            ori     at, at, 0x0080                  // ~
            // sh      at, 0x02CE(v1)                  // enable bitflag which allows owner's hitboxes to collide with the hurtbox

            li      t0, iceblock_attributes.struct   // t0 = iceblock_attributes.struct
            lw      t1, iceblock_attributes.MAX_SPEED(t0)    // t1 = MAX_SPEED
            sw      t1, 0x01C8(v1)                  // max speed = MAX_SPEED
            sw      r0, 0x01CC(v1)                  // rotation direction = 0
            sw      r0, 0x01D0(v1)                  // hitbox refresh timer = 0
            sw      r0, 0x01D4(v1)                  // hitbox collision flag = FALSE
            li      t1, iceblock_blast_zone_         // load iceblock blast zone routine
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
        // Main subroutine for the iceblock.
        // a0 = item object
        scope iceblock_main_: {
            addiu   sp, sp,-0x0040                  // allocate stack space
            sw      s0, 0x0014(sp)                  // ~
            sw      s1, 0x0018(sp)                  // ~
            sw      s2, 0x001C(sp)                  // ~
            sw      ra, 0x0030(sp)                  // store ra, s0-s2

            lw      s0, 0x0084(a0)                  // s0 = item special struct
            or      s1, a0, r0                      // s1 = item object
            li      s2, iceblock_attributes.struct   // s2 = iceblock_attributes.struct

            lw      t0, 0x350(s0)                  // t0 = custom variable (released)
            beqz    t0, _unreleased                // branch if unreleased
            nop

            lw      at, 0x0108(s0)                  // at = kinetic state
            beq     at, r0, _update_speed_ground    // branch if kinetic state = grounded
            nop

            _update_speed_air:
            lui     at, 0x3F80                      // ~
            mtc1    at, f2                          // f2 = 1.0
            lwc1    f4, iceblock_attributes.MAX_SPEED(s2)    // f4 = MAX_SPEED
            lwc1    f6, 0x01C8(s0)                  // f6 = current max speed
            sub.s   f6, f6, f2                      // f6 = current max speed - 1.0
            c.le.s  f6, f4                          // ~
            nop                                     // ~
            bc1f    _apply_speed_air                // branch if MAX_SPEED =< updated max speed
            swc1    f6, 0x01C8(s0)                  // update current max speed
            // if updated max speed is below MAX_SPEED
            swc1    f4, 0x01C8(s0)                  // current max speed = MAX_SPEED

            _apply_speed_air:
            lw      a1, iceblock_attributes.GRAVITY(s2) // a1 = GRAVITY
            lw      a2, 0x01C8(s0)                  // a2 = current max speed
            jal     0x80172558                      // apply gravity/max speed
            or      a0, s0, r0                      // a0 = item special struct
            b       _check_duration                 // branch
            nop

            _update_speed_ground:

            _check_duration:
            lw      v0, 0x02C0(s0)                  // v0 = remaining duration
            addiu   t7, v0,-0x0001                  // t7 = decremented duration
            sw      t7, 0x02C0(s0)                  // store updated duration
            beqz    t7, _delete                  // branch if duration = 0
            nop

            b _end
            or      v0, r0, r0                      // v0 = 0

            _unreleased:
            lw      t0, 0x0008(s0) // t0 = item owner
            beqz    t0, _delete // no owner, delete item
            nop
            lw      t0, 0x84(t0) // t0 = item owner struct
            lw      t1, 0x24(t0) // t1 = projectile owner's current action
            lli     t2, IceClimbers.Action.ICEBLOCK
            bne     t1, t2, _delete // delete item if not in iceblock action
            nop

            b _end
            or v0, r0, r0

            _delete:
            lli v0, 0x1 // v0 = 1 (delete item)
            lw at, 0x358(s0)
            sw r0, 0x0(at) // clear our reference in owner's struct
            b _end // end
            nop

            _end:
            sw      r0, 0x01D4(s0)                  // hitbox collision flag = FALSE
            lw      s0, 0x0014(sp)                  // ~
            lw      s1, 0x0018(sp)                  // ~
            lw      s2, 0x001C(sp)                  // ~
            lw      ra, 0x0030(sp)                  // store ra, s0-s2lw      s0, 0x0014(sp)                  // ~
            lw      s1, 0x0018(sp)                  // ~
            lw      s2, 0x001C(sp)                  // ~
            lw      ra, 0x0030(sp)                  // store ra, s0-s2
            jr      ra                              // return
            addiu   sp, sp, 0x0040                  // deallocate stack space
        }

        // @ Description
        // Collision subroutine for the iceblock.
        // a0 = item object
        scope iceblock_collision_: {
            addiu   sp, sp,-0x0058                  // allocate stack space
            sw      ra, 0x0014(sp)                  // ~
            sw      s0, 0x0040(sp)                  // ~
            sw      s1, 0x0044(sp)                  // store ra, s0, s1
            or      s0, a0, r0                      // s0 = item object

            lw      t0, 0x0084(s0)                  // t0 = item special struct
            lw      at, 0x0108(t0)                  // at = kinetic state
            bnez    at, _aerial                     // skip if kinetic state = aerial
            nop

            _grounded:
            li      a1, set_aerial_state
            jal     0x801735A0 // itMapCheckLRWallProcGround(GObj *item_gobj, void (*proc_map)(GObj*))
            lw      a0, 0x0040(sp) // a0 = item object
            
            jal     0x8017B874 // itNBumperAttachedSetModelYaw(GObj *item_gobj) - rotation = ground angle, stolen from bumper
            lw      a0, 0x0040(sp) // a0 = item object

            _reset_fall_speed:
            lw      t0, 0x0084(s0) // t0 = item special struct
            sw      r0, 0x30(t0) // y speed = 0

            _reflect_wall:
            lw      t0, 0x0084(s0) // t0 = item special struct
            lhu     t6, 0x008E(t0) // t6 = collision flags
            andi    t6, t6, Surface.WALL // t6 = collision flags | wall bitmask

            beqz    t6, _adjust_slope_speed // not colliding with a wall, skip
            nop

            // collided with wall, invert movement
            lwc1    f2, 0x2C(t0) // f2 = x velocity
            neg.s   f2, f2 // f2 = -x velocity
            swc1    f2, 0x2C(t0) // update x velocity

            _adjust_slope_speed:
            // adjust speed based on ground angle
            lw      t0, 0x0084(s0) // t0 = item special struct
            lwc1    f12, 0xB8(t0) // f12 = ground_angle.x
            lui     at, SLOPE_ACCELERATION // ~
            mtc1    at, f2 // f2 = SLOPE_ACCELERATION
            mul.s   f2, f2, f12 // f2 = SLOPE_ACCELERATION * slope angle
            lwc1    f4, 0x2C(t0) // f4 = x velocity
            add.s   f4, f4, f2 // f4 = current x velocity + acceleration
            swc1    f4, 0x2C(t0) // update x velocity

            // lwc1    f4, 0x0044(s0)              // ~
            // cvt.s.w f4, f4                      // f4 = DIRECTION
            // neg.s   f4, f4                      // f4 = -DIRECTION
            // mul.s   f2, f2, f0                  // f2 = SLOPE_ACCELERATION * sin(slope angle)
            // mul.s   f2, f2, f4                  // f2 = speed difference = (SLOPE_ACCELERATION * sin(slope angle)) * -DIRECTION
            // lwc1    f4, 0x0060(s0)              // f4 = ground x velocity
            // add.s   f4, f4, f2                  // f4 = current x velocity + calculated speed difference
            // swc1    f4, 0x0060(s0)              // update ground x velocity

            b       _end
            nop

            _aerial:
            // sb32 is_collide_ground = itMapTestAllCollisionFlag(item_gobj, MPCOLL_FLAG_GROUND);
            lli     a1, Surface.GROUND
            jal     0x801737B8
            lw      a0, 0x0040(sp) // a0 = item object

            beqz    v0, _aerial_reflect_wall
            nop

            lw      a0, 0x0040(sp) // a0 = item object
            lw      a0, 0x84(a0) // a0 = item special struct
            sw      r0, 0x108(a0) // set grounded state
            b       _end // transition to grounded and skip the rest of the function
            nop

            _aerial_reflect_wall:
            lw      t0, 0x0084(s0) // t0 = item special struct
            lhu     t6, 0x008E(t0) // t6 = collision flags
            andi    t6, t6, Surface.WALL // t6 = collision flags | wall bitmask

            beqz    t6, _end // not colliding with a wall, skip
            nop

            // collided with wall, invert movement
            lwc1    f2, 0x2C(t0) // f2 = x velocity
            neg.s   f2, f2 // f2 = -x velocity
            swc1    f2, 0x2C(t0) // update x velocity

            _end:
            lw      ra, 0x0014(sp)                  // ~
            lw      s0, 0x0040(sp)                  // ~
            lw      s1, 0x0044(sp)                  // load ra, s0, s1
            addiu   sp, sp, 0x0058                  // deallocate stack space
            jr      ra                              // return
            or      v0, r0, r0                      // return 0
        }

        scope set_aerial_state: {
            lw      at, 0x84(a0) // at = item special struct
            lli     t0, 0x1
            jr      ra
            sw      t0, 0x108(at)
        }

        // @ Description
        // Changes a iceblock to the aerial/main state.
        // a0 = item object
        scope iceblock_begin_main_: {
            addiu   sp, sp,-0x0018                  // allocate stack space
            sw      ra, 0x0014(sp)                  // ~
            sw      a0, 0x0018(sp)                  // store ra, a0
            lw      a0, 0x0084(a0)               // a0 = item special struct
            // lbu     t0, 0x02CE(a0)               // t0 = unknown bitfield
            // andi    t0, t0, 0xFF7F               // disable item pickup bit
            // sb      t0, 0x02CE(a0)               // store updated bitfield
            lli     at, 0x0001                      // ~
            jal     0x80173F78                      // bomb subroutine, sets kinetic state value
            sw      at, 0x010C(a0)                  // enable hitbox
            jal     0x80185CD4                      // bomb subroutine, sets an unknown value to 0x1
            lw      a0, 0x0018(sp)                  // a0 = item object
            lw      a0, 0x0018(sp)                  // a0 = item object
            li      a1, iceblock_item_states         // a1 = object state base address
            jal     0x80172EC8                      // change item state
            ori     a2, r0, r0                      // a2 = 0 (aerial/main state)
            lw      ra, 0x0014(sp)                  // load ra
            jr      ra                              // return
            addiu   sp, sp, 0x0018                  // deallocate stack space
        }

        // @ Description
        // Runs when a Iceblock's hitbox collides with a hurtbox.
        // a0 = item object
        scope iceblock_hurtbox_collision_: {
            OS.routine_begin(0x20)

            lw      t0, 0x0084(a0)              // t0 = item special struct
            // sw      r0, 0x02C0(t0)              // update remaining duration
            lli     v0, 0x0

            // prevent the x/y speed from being updated if the hitbox collision flag is enabled
            // this is to prevent it being destroyed on trades or right after being reflected
            lw      t1, 0x01D4(t0) // t1 = hitbox collision flag
            bnez    t1, _end // skip if hitbox collision flag = TRUE
            sw      r0, 0x01D4(t0) // hitbox collision flag = FALSE

            // if the hitbox collision flag wasn't enabled
            lw at, 0x358(t0)
            sw r0, 0x0(at) // clear our reference in owner's struct
            lli v0, 0x1 // destroy

            _end:
            OS.routine_end(0x20)
        }

        scope iceblock_shield_collision: {
            OS.routine_begin(0x20)

            lw      t0, 0x0084(a0) // t0 = item special struct
            lwc1    f2, 0x2C(t0) // f2 = x velocity
            neg.s   f2, f2 // f2 = -x velocity
            swc1    f2, 0x2C(t0) // update x velocity

            or      v0, r0, r0 // do not destroy

            OS.routine_end(0x20)
        }

        // @ Description
        // this subroutine handles hitbox collision for the iceblock, causing it to be launched when hit by attacks
        // a0 = item object
        scope iceblock_hitbox_collision_: {
            addiu   sp, sp,-0x0050              // allocate stack space
            lw      v0, 0x0084(a0)              // v0 = item special struct
            sw      ra, 0x0020(sp)              // 0x0020(sp) = ra
            sw      a0, 0x0024(sp)              // 0x0024(sp) = item object
            // jal     iceblock_begin_main_         // transition to aerial/main state
            sw      v0, 0x0028(sp)              // 0x0028(sp) = item special struct

            // update item ownership and combo ownership
            lw      t0, 0x0028(sp)              // t0 = item special struct

            lw      t1, 0x01D4(t0)              // hitbox collision flag = TRUE
            bnez    t1, _end                    // skip if hitbox collision flag = TRUE
            nop

            lw      t1, 0x02A8(t0)              // t1 = object which has ownership over the colliding hitbox
            sw      t1, 0x0008(t0)              // update item owner
            lli     at, 0x0004                  // at = 0x4 (no combo ownership)
            beqz    t1, _calculate_movement     // skip if there isn't an object in t1
            lli     t2, 0x03E8                  // t2 = player object type
            lw      t3, 0x0000(t1)              // t3 = object type
            bne     t2, t3, _calculate_movement // skip if object type != player
            lw      t1, 0x0084(t1)              // t1 = type specific special struct
            lbu     at, 0x000D(t1)              // at = player port (for combo ownership)

            _calculate_movement:
            // skip if colliding with owner
            lbu     t4, 0x0015(t0)
            beq     t4, at, _end
            nop

            sb      at, 0x0015(t0)              // update combo ownership
            lwc1    f0, 0x0298(t0)              // ~
            cvt.s.w f0, f0                      // f0 = damage
            lui     t1, 0x4000                  // ~
            mtc1    t1, f2                      // f2 = 2
            mul.s   f0, f0, f2                  // f0 = damage * 2
            lui     t1, 0x4220                  // ~
            mtc1    t1, f2                      // f2 = 40
            add.s   f0, f0, f2                  // f0 = knockback ((damage * 2) + 40)
            swc1    f0, 0x002C(sp)              // 0x002C(sp) = knockback
            swc1    f0, 0x01C8(t0)              // current max speed = knockback
            lw      a0, 0x029C(t0)              // a0 = knockback angle
            lli     a0, 0x1E // angle = 30 deg (int)
            // this subroutine converts the int angle in a0 to radians, also handles sakurai angle
            jal     0x801409BC                  // f0 = knockback angle in rads
            lw      a2, 0x002C(sp)              // a2 = knockback
            swc1    f0, 0x0030(sp)              // 0x0030(sp) = knockback angle
            // ultra64 cosf function
            jal     0x80035CD0                  // f0 = cos(angle)
            mov.s   f12, f0                     // f12 = knockback angle
            lwc1    f4, 0x002C(sp)              // f4 = knockback
            mul.s   f4, f4, f0                  // f4 = x velocity (knockback * cos(angle))
            swc1    f4, 0x0034(sp)              // 0x0034(sp) = x velocity
            // ultra64 sinf function
            jal     0x800303F0                  // f0 = sin(angle)
            lwc1    f12, 0x0030(sp)             // f12 = knockback angle
            lwc1    f4, 0x002C(sp)              // f4 = knockback
            mul.s   f4, f4, f0                  // f4 = y velocity (knockback * sin(angle))
            lwc1    f2, 0x0034(sp)              // f2 = x velocity

            lw      t0, 0x0028(sp)              // t0 = item special struct

            lli     at, 0x1
            sw      at, 0x108(t0) // set aerial state

            lw      t1, 0x02A4(t0)              // ~
            subu    t1, r0, t1                  // t1 = DIRECTION
            sw      t1, 0x0024(t0)              // update item direction
            mtc1    t1, f0                      // ~
            cvt.s.w f0, f0                      // f0 = DIRECTION
            mul.s   f2, f0, f2                  // f2 = x velocity * DIRECTION
            swc1    f2, 0x002C(t0)              // update projectile x velocity
            swc1    f4, 0x0030(t0)              // update projectile y velocity
            lli     t1, 000016                  // ~
            sw      t1, 0x01D0(t0)              // set hitbox refresh timer to 16 frames
            lli     t1, OS.TRUE                 // ~
            sw      t1, 0x01D4(t0)              // hitbox collision flag = TRUE
            
            _end:
            lw      ra, 0x0020(sp)              // load ra
            addiu   sp, sp, 0x0050              // deallocate stack space
            jr      ra
            or      v0, r0, r0                  // return 0 (do not destroy)
        }

        scope iceblock_attributes {
            constant DURATION(0x0000)
            constant GRAVITY(0x0004)
            constant MAX_SPEED(0x0008)
            constant BOUNCE(0x000C)
            constant ANGLE(0x0010)
            constant ROTATION(0x0014)
            struct:
            dw 150                                  // 0x0000 - duration (int)
            float32 3.4                             // 0x0004 - gravity
            float32 120.0                          // 0x0008 - max speed
            float32 1.0                            // 0x000C - bounce multiplier - how much bouncing affects speed
            float32 0                            // 0x0010 - angle
            float32 0                           // 0x0014 - rotation speed
        }

        // @ Description
        // this routine gets run by whenever a projectile crosses the blast zone. The purpose here is to restock Conker's iceblocks
        scope iceblock_blast_zone_: {
            lw t0, 0x0084(a0) // t0 = item special struct
            lw at, 0x358(t0)
            sw r0, 0x0(at) // clear our reference in owner's struct
            jr ra // return
            nop
            // sw      r0, 0x0B20(t1)          // clear out player struct free space so another iceblock can be thrown
        }
    }

    scope _initial: {
        addiu   sp, sp, 0xFFE0              // ~
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // original lines 1-3

        // reset fast fall
        lbu     v1, 0x018D(a1)              // v1 = fast fall flag
        ori     t6, r0, 0x0007              // t6 = bitmask (01111111)
        and     v1, v1, t6                  // ~
        sb      v1, 0x018D(a1)              // disable fast fall flag

        // hop
        lui     t1, 0x4234 // t1 = 45.0
        sw      t1, 0x004C(a1) // store y velocity

        lli     a1, IceClimbers.Action.ICEBLOCK // a1 = Action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        or      a2, r0, r0                  // a2 = float: 0.0
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3 = float: 1.0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x0B20(a0)              // projectile reference = NULL
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        ori     v1, r0, 0x0002              // ~
        sw      v1, 0x0184(a0)              // temp variable 3 = 0x1(BEGIN)
        lw      ra, 0x001C(sp)              // ~
        addiu   sp, sp, 0x0020              // ~
        jr      ra                          // original return logic
        nop
    }

    scope _update: {
        OS.routine_begin(0x20)

        sw      a0, 0x4(sp)
        lw      s0, 0x0084(a0)  // s0 = player struct

        lw      t0, 0x1C(s0) // t0 = current frame (int)

        // spawn projectile at this frame
        lli     t1, 6
        beq     t0, t1, _spawn_projectile
        nop
        lli     t1, 18
        blt     t0, t1, _update_projectile_pos
        nop
        lli     t1, 18
        beq     t0, t1, _release_projectile
        nop
        b       _check_animation_end
        nop
        
        _spawn_projectile: {
            // 0x0ADC and 0x0AE0 are used as pointers to iceblocks we have created
            // limit total ice blocks to 2
            _check_reference_slots:
            lw at, 0x0ADC(s0)
            beqz at, _slots_passed // this slot is empty, we can continue
            nop
            lw at, 0x0AE0(s0)
            beqz at, _slots_passed // this slot is empty, we can continue
            nop
            b _check_animation_end // no empty slots, skip item spawn
            nop
            _slots_passed:

            addiu   sp, sp, -0x20
            {
                lw          t0, 0x78(s0) // t0 = player position vec3
                
                // create pos vec3 at 0x0
                // not bothering with the correct position here since we have
                // code dedicated to positioning the projectile later
                lwc1    f2, 0x0(t0) // f2 = player x
                swc1    f2, 0x0(sp) // x

                lwc1    f2, 0x4(t0) // f2 = player y
                swc1    f2, 0x4(sp) // y

                sw      r0, 0x8(sp) // z

                // create vel vec3 at 0x10
                sw      r0, 0x10(sp)
                sw      r0, 0x14(sp)
                sw      r0, 0x18(sp)

                li      a1, IceBlockItem.iceblock_item_info_array
                addiu   a2, sp, 0x0 // a2 = vec3 position
                addiu   a3, sp, 0x10 // a3 = vec3 velocity

                addiu   sp, sp, -0x20
                {
                    sw a0, 0x4(sp) // save player object

                    li at, 0x80000002                      // ~
                    sw at, 0x10(sp) // argument 4 = flags
                    
                    _spawn_weapon:
                    jal IceBlockItem.iceblock_stage_setting_
                    nop
                }
                addiu   sp, sp, 0x20
            }
            addiu   sp, sp, 0x20
        }
        lw      a0, 0x4(sp) // restore a0

        _update_projectile_pos:
        lw      s0, 0x0084(a0)  // s0 = player struct

        lw      v0, 0xB20(s0) // load projectile object from player struct

        beqz    v0, _check_animation_end // skip if projectile is null
        nop

        lw          t4, 0x74(v0) // t4 = item position at 1C(t4), 20(t4), 24(t4)
        
        lw          t0, 0x78(s0) // t0 = player position vec3

        lw          t1, 0x8E8(s0)   // t1 = topjoint transform bone
        lwc1        f6, 0x0040(t1)  // f6 = topjoint X scale

        lw          t1, 0x44(s0) // t1 = facing direction
        mtc1        t1, f8 // f8 = facing direction
        cvt.s.w     f8, f8 // f8 = facing direction (float)

        mul.s       f10, f6, f8 // f6 = facing direction * scale
        
        lwc1    f2, 0x0(t0) // f2 = player x
        lui     at, 0x43AF // offset x = 350.0
        mtc1    at, f4 // f4 = offset x
        mul.s   f4, f4, f10 // offset * (direction * scale)
        add.s   f2, f2, f4 // f2 = pos x + final offset
        swc1    f2, 0x1C(t4) // x


        // frame 6 the projectile is created, 17 is the last update before it's deployed
        // so we're working with 12 frames
        lw      t1, 0x1C(s0) // t1 = current animation frame (int)
        addiu   t1, t1, -6
        mtc1    t1, f8 // f8 = current frame counting from projectile spawn
        cvt.s.w f8, f8

        lli     at, 17
        mtc1    at, f10
        cvt.s.w f10, f10 // f10 = final frame counting from projectile spawn

        div.s   f8, f8, f10 // f8 = normalized animation progress

        lui     at, 0x43FA // offset y = 500.0
        mtc1    at, f4 // f4 = initial offset y

        lui     at, 0x43C8 // subtract y = 400.0
        mtc1    at, f10 // f10 = total value to be subtracted from y by the projectile's deployment
        mul.s   f8, f8, f10 // f8 = how much we have to subtract from y at this point

        sub.s   f4, f4, f8 // subtract y (animate it going down)

        lwc1    f2, 0x4(t0) // f2 = player y
        mul.s   f4, f4, f6 // offset * scale
        add.s   f2, f2, f4 // f2 = pos y + final offset
        swc1    f2, 0x20(t4) // y

        sw      r0, 0x24(t4) // z

        lw      a0, 0x4(sp) // restore a0

        b   _check_animation_end
        nop

        _release_projectile:
        lw      s0, 0x0084(a0)  // s0 = player struct

        lw      v0, 0xB20(s0) // load projectile object from player struct

        beqz    v0, _check_animation_end // skip if projectile is null
        nop
        
        lw      v1, 0x84(v0) // v1 = ItemGetStruct(item_gobj)

        lli     t0, 0x1
        sw      t0, 0x0248(v1) // enable hurtbox
        sw      t0, 0x010C(v1) // enable hitbox
        sw      t0, 0x350(v1) // set custom variable (released) to 1

        // lwc1    f2, 0x44(s0) // f2 = player facing direction
        // cvt.s.w f2, f2 // f2 = float(player direction)

        // lui     at, 0x4220 // 40.0
        // mtc1    at, f4 // f4 = SPEED
        // mul.s   f2, f2, f4 // f2 = facing direction * speed
        // swc1    f2, 0x20(v1) // save speed x

        _check_animation_end:
        lw      s0, 0x0084(a0)  // s0 = player struct
        lw      t6, 0x014C(s0)  // t6 = kinetic state (0 = grounded, 1 = aerial)
        bnez    t6, _check_animation_end_air
        nop

        _check_animation_end_gnd:
        jal     0x800D94C4
        nop
        b       _end
        nop

        _check_animation_end_air:
        jal     0x800D94E8
        nop

        _end:
        OS.routine_end(0x20)
    }

    _physics: {
        OS.routine_begin(0x20)
        lw      s0, 0x0084(a0)  // s0 = player struct

        lw      s0, 0x0084(a0)  // s0 = player struct
        lw      t6, 0x014C(s0)  // t6 = kinetic state (0 = grounded, 1 = aerial)
        bnez    t6, _aerial
        nop

        _grounded:
        jal     0x800D8BB4 // grounded subroutine, apply ground friction
        nop
        b       _end
        nop

        _aerial:
        jal     0x800D91EC // aerial subroutine, apply aerial friction
        nop
        
        _end:
        OS.routine_end(0x20)
    }

    scope _collision: {
        OS.routine_begin(0x28)
        sw      s0, 0x18(sp)
        sw      a0, 0x1C(sp)

        lw      s0, 0x84(a0)  // s0 = player struct
        lw      t6, 0x014C(s0)  // t6 = kinetic state (0 = grounded, 1 = aerial)
        bnez    t6, _aerial
        nop

        _grounded:
        jal 0x800DDF44 // grounded subroutine - do not fall from ledges
        nop
        b _end
        nop

        _aerial:
        li      a1, _air_to_ground  // a1 (transition subroutine) = air_to_ground_
        jal     0x800DE80C          // mpCommonProcFighterCliff(GObj *fighter_gobj, void (*proc_map)(GObj*)) air collision subroutine (transition on landing, allows ledge grab)
        nop 

        _end:
        lw  s0, 0x18(sp)
        lw  a0, 0x1C(sp)
        OS.routine_end(0x28)
    }

    scope _air_to_ground: {
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // store ra
        sw      a0, 0x0038(sp)              // 0x0038(sp) = player object
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800DEE98                  // set grounded state
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player struct
        lw      v0, 0x0034(sp)              // v0 = player struct
        lw      a0, 0x0038(sp)              // a0 = player object

        addiu   a1, r0, Action.LandingAirU
        _change_action:
        or      a2, r0, r0                  // a2(start frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1
        jal     0x800E6F24                  // change action
        nop
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop
    }
}

scope IceClimbersDSP: {
    _blizz_projectile_struct:
    dw 0x00000000                           // this has some sort of bit flag to tell it to use secondary type display list?
    dw 0x0
    dw Character.ICECLIMBERS_file_7_ptr     // pointer to file
    dw 0x00000000                           // 00000000
    dw 0x00000040                           // rendering routine?
    dw _blizz_update                        // update routine
    dw 0x80175914                           // collision (0x801685F0 - Mario) (0x80169108 - Samus)
    dw 0x80175958    		                // after_effect 0x801691FC, this one is used when grenade connects with player
    dw 0x80175958                           // after_effect 0x801691FC, used when touched by player when object is still, by setting to null, nothing happens
    dw 0x8016DD2C                           // determines behavior when projectile bounces off shield, this uses Master Hand's projectile coding to determine correct angle of graphic (0x8016898C Fox)
    dw 0x80175958                           // after_effect                // rocket_after_effect 0x801691FC
    dw 0x80168748                           // OS.copy_segment(0x1038FC, 0x04)            // this determines reflect behavior (default 0x80168748)
    dw 0x80175958                           // This function is run when the projectile is used on ness while using psi magnet
    OS.copy_segment(0x103904, 0x0C)         // empty

    scope _blizz_update: {
        OS.routine_begin(0x20)
        lw      a0, 0x0084(a0) // a0 = projectile struct

        jal     0x80167FE8 // decrease duration and check if duration is over
        sw      a0, 0x001C(sp) // store a0
        bnez    v0, _end_duration // branch if duration over
        nop
        lw      a0, 0x001C(sp) // restore a0

        _update:
        lw t0, 0x268(a0) // t0 = current lifetime
        lli at, 0x7
        beq t0, at, _hitbox_2
        lli at, 0x3
        beq t0, at, _hitbox_3
        nop
        b _end_duration
        nop

        _hitbox_2:
        // Hitbox size
        lui     at, 0x42F0 // at = 120.0 (fp)
        sw      at, 0x0128(a0) // save
        // Hitbox damage
        lli     at, 0x0001
        sw      at, 0x0104(a0) // save

        b _end_duration
        nop

        _hitbox_3:
        // Hitbox size
        lui     at, 0x4270 // at = 60.0 (fp)
        sw      at, 0x0128(a0) // save
        // Hitbox knockback growth
        lli     at, 0x0014 // at = 20
        sw      at, 0x0130(a0) // save

        _end_duration:
        OS.routine_end(0x20)
    }
    
    scope _initial: {
        addiu   sp, sp, 0xFFE0              // ~
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // original lines 1-3

        // reset fast fall
        lbu     v1, 0x018D(a1)              // v1 = fast fall flag
        ori     t6, r0, 0x0007              // t6 = bitmask (01111111)
        and     v1, v1, t6                  // ~
        sb      v1, 0x018D(a1)              // disable fast fall flag

        lli     a1, IceClimbers.Action.BLIZZARD // a1 = Action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        or      a2, r0, r0                  // a2 = float: 0.0
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3 = float: 1.0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        ori     v1, r0, 0x0002              // ~
        sw      v1, 0x0184(a0)              // temp variable 3 = 0x1(BEGIN)
        lw      ra, 0x001C(sp)              // ~
        addiu   sp, sp, 0x0020              // ~
        jr      ra                          // original return logic
        nop
    }

    scope _update: {
        OS.routine_begin(0x20)

        sw      a0, 0x4(sp)
        lw      s0, 0x84(a0)  // s0 = player struct

        lw      t0, 0x1C(s0) // t0 = current frame (int)

        lli     at, 16
        blt     t0, at, _check_animation_end
        nop

        lli     at, 56
        bgt     t0, at, _check_animation_end
        nop

        // spawn a projectile every 5 frames
        lli     at, 16
        beq     t0, at, _spawn_projectile
        lli     at, 21
        beq     t0, at, _spawn_projectile
        lli     at, 26
        beq     t0, at, _spawn_projectile
        lli     at, 31
        beq     t0, at, _spawn_projectile
        lli     at, 36
        beq     t0, at, _spawn_projectile
        lli     at, 41
        beq     t0, at, _spawn_projectile
        lli     at, 46
        beq     t0, at, _spawn_projectile
        lli     at, 51
        beq     t0, at, _spawn_projectile
        lli     at, 56
        beq     t0, at, _spawn_projectile
        nop
        b       _check_animation_end
        nop
        
        _spawn_projectile: {
            addiu   sp, sp, -0x20
            {
                lw          t0, 0x78(s0) // t0 = player position vec3

                lw          t1, 0x8E8(s0)   // t1 = topjoint transform bone
                lwc1        f6, 0x0040(t1)  // f6 = topjoint X scale

                lw          t1, 0x44(s0) // t1 = facing direction
                mtc1        t1, f8 // f8 = facing direction
                cvt.s.w     f8, f8 // f8 = facing direction (float)

                mul.s       f10, f6, f8 // f6 = facing direction * scale
                
                // create pos vec3 at 0x0
                lwc1    f2, 0x0(t0) // f2 = player x
                lui     at, 0x4396 // offset x = 300.0
                mtc1    at, f4 // f4 = offset x
                mul.s   f4, f4, f10 // offset * (direction * scale)
                add.s   f2, f2, f4 // f2 = pos x + final offset
                swc1    f2, 0x0(sp) // x

                lwc1    f2, 0x4(t0) // f2 = player y
                lui     at, 0x4348 // offset y = 200.0
                mtc1    at, f4 // f4 = offset y
                mul.s   f4, f4, f6 // offset * scale
                add.s   f2, f2, f4 // f2 = pos y + final offset
                swc1    f2, 0x4(sp) // y

                sw      r0, 0x8(sp) // z

                li      a1, _blizz_projectile_struct
                addiu   a2, sp, 0x0 // a2 = vec3 position
                lui     a3, 0x8000 // a3 = flags

                addiu   sp, sp, -0x20
                {
                    sw a0, 0x4(sp) // save player object

                    _spawn_dust: {
                        addiu   sp, sp, -0x20
                        sw a0, 0x4(sp)
                        sw a1, 0x8(sp)
                        sw a2, 0xC(sp)
                        sw a3, 0x10(sp) // save arguments

                        lw s0, 0x84(a0) // s0 = player struct
                        lw a1, 0x44(s0) // a1 = player facing direction
                        sub a1, r0, a1 // invert a1

                        or  a0, r0, a2 // a0 = pos

                        lli a3, 0x0

                        addiu   sp, sp, -0x20

                        jal 0x800FF048 // LBParticle* efManagerDustLightMakeEffect(Vec3f *pos, s32 lr, f32 f_index)
                        nop

                        // v0 = LBParticle
                        or  t0, r0, v0 // t0 = LBParticle object

                        addiu   sp, sp, 0x20
                        
                        lw a0, 0x4(sp)
                        lw a1, 0x8(sp)
                        lw a2, 0xC(sp)
                        lw a3, 0x10(sp) // load arguments back
                        addiu   sp, sp, 0x20
                    }
                    sw  t0, 0x1C(sp) // save LBParticle object

                    beqz t0, _spawn_weapon // if LBParticle failed to spawn, skip changes to it
                    nop

                    lw  t0, 0x5C(t0) // t0 = LBTransform
                    lw  t1, 0x4(a2) // load Y from spawn pos
                    sw  t1, 0x8(t0) // update GFX Y location (the creation function spawns it a bit above the original point)

                    lui at, 0x4000 // GFX scale = 2.0
                    sw  at, 0x1C(t0)
                    sw  at, 0x20(t0)
                    sw  at, 0x24(t0)
                    
                    _spawn_weapon:
                    jal 0x801655C8 // GObj* wpManagerMakeWeapon(GObj *parent_gobj, WPDesc *wp_desc, Vec3f *spawn_pos, u32 flags)
                    nop

                    sw v0, 0x8(sp) // save projectile object

                    beqz v0, _end_spawn // if projectile failed to spawn, skip changes to it
                    nop

                    lw v1, 0x84(v0) // v1 = ItemGetStruct(item_gobj);

                    lli t0, 0xA // lifetime = 10
                    sw t0, 0x268(v1) // save lifetime

                    // Hitbox size
                    lui     at, 0x430C              // at = 140.0 (fp)
                    sw      at, 0x0128(v1)          // save

                    // Hitbox damage
                    lli     at, 0x0002
                    sw      at, 0x0104(v1)          // save

                    // Hit type
                    sw      r0, 0x010C(v1)          // save

                    // Hit angle
                    lli  at, 0x169 // 361
                    sw   at, 0x012C(v1)

                    // Hitbox base knockback
                    lli     at, 0x000A              // at = 10
                    sw      at, 0x0138(v1)          // save

                    // Hitbox knockback growth
                    lli     at, 0x0032              // at = 50
                    sw      at, 0x0130(v1)          // save

                    // Hit FGM
                    lli     at, FGM.hit.PUNCH_S
                    sh      at, 0x0146(v1)          // save

                    // generate angle between 60 and 115
                    jal     Global.get_random_int_  // v0 = (random value)
                    lli     a0, 0x37                // a0 = random max = 55
                    addiu   t0, v0, 0x3C            // t0 = ANGLE = 60 + random(55)
                    // this subroutine converts the int angle in a0 to radians, also handles sakurai angle
                    jal     0x801409BC // f0 = knockback angle in rads
                    or      a0, r0, t0 // deploy angle
                    mov.s   f6, f0 // f6 = deploy angle (radians)
                    swc1    f6, 0xC(sp) // save deploy angle

                    lw      v0, 0x8(sp)             // restore v0 = projectile object
                    lw      v1, 0x84(v0)            // v1 = ItemGetStruct(item_gobj);

                    // ultra64 sinf function
                    jal     0x800303F0 // f0 = sin(f12)
                    mov.s   f12, f6 // f12 = deploy angle(radians)
                    lwc1    f6, 0xC(sp) // load deploy angle
                    lw      v0, 0x8(sp) // restore v0 = projectile object
                    lw      v1, 0x84(v0) // v1 = ItemGetStruct(item_gobj);

                    lw a0, 0x4(sp) // load player object
                    lw s0, 0x84(a0) // s0 = player struct
                    lwc1 f2, 0x44(s0) // f2 = player facing direction
                    cvt.s.w f2, f2 // f2 = float(player direction)

                    lui at, 0x4270 // 60.0
                    mtc1 at, f4 // f4 = SPEED
                    mul.s   f2, f2, f4 // f2 = facing direction * speed
                    mul.s   f2, f2, f0 // f2 *= cos(angle)
                    swc1    f2, 0x20(v1) // save speed x

                    // ultra64 cosf function
                    jal     0x80035CD0 // f0 = cos(f12)
                    mov.s   f12, f6 // f12 = deploy angle(radians)
                    lw      v0, 0x8(sp) // restore v0 = projectile object
                    lw      v1, 0x84(v0) // v1 = ItemGetStruct(item_gobj);

                    lui at, 0x4270 // 60.0
                    mtc1 at, f4 // f4 = SPEED
                    mul.s   f2, f4, f0 // f2 = speed * sin(angle)
                    swc1    f2, 0x24(v1) // save speed y

                    // set no display list for projectile
                    lw t0, 0x74(v0)
                    sw r0, 0x50(t0)

                    jal 0x80167FA0 // wpMainVelSetModelPitch(weapon_gobj); - set projectile rotation based on speed
                    or a0, r0, v0 // a0 = item object

                    lw v0, 0x8(sp) // restore v0 = projectile object
                    lw v1, 0x84(v0) // v1 = ItemGetStruct(item_gobj);

                    // update speeds on GFX
                    lw  t0, 0x1C(sp) // LBParticle object
                    beqz t0, _end_spawn // if LBParticle failed to spawn, skip changes to it
                    nop
                    lw  t0, 0x5C(t0) // t0 = LBTransform
                    lw  t1, 0xBC(t0) // t1 = 0xBC(LBTransform) = effect_gobj
                    lw  t1, 0x84(t1) // 0x84(effect_gobj) = particle struct

                    lwc1 f2, 0x20(v1) // load projectile speed X
                    lui at, 0x4000
                    mtc1 at, f4
                    div.s f2, f2, f4 // f2 = speed X / 2.0
                    swc1 f2, 0x18(t1) // effect_vars.dust_normal.vel1.x

                    // lwc1 f2, 0x24(v1) // load projectile speed Y
                    // div.s f2, f2, f4 // f2 = speed Y / 2.0
                    // swc1 f2, 0x1C(t1) // effect_vars.dust_normal.vel1.y
                    sw r0, 0x1C(t1) // effect_vars.dust_normal.vel1.y

                    sw r0, 0x24(t1) // effect_vars.dust_normal.vel2.x (remove randomized offsets)
                    sw r0, 0x28(t1) // effect_vars.dust_normal.vel2.y (remove randomized offsets)

                    _end_spawn:
                }
                addiu   sp, sp, 0x20
            }
            addiu   sp, sp, 0x20
        }
        lw      a0, 0x4(sp) // restore a0
        lw      s0, 0x84(a0)  // s0 = player struct

        _check_animation_end:
        lw      s0, 0x0084(a0)  // s0 = player struct
        lw      t6, 0x014C(s0)  // t6 = kinetic state (0 = grounded, 1 = aerial)
        bnez    t6, _check_animation_end_air
        nop

        _check_animation_end_gnd:
        jal     0x800D94C4
        nop
        b       _end
        nop

        _check_animation_end_air:
        jal     0x800D94E8
        nop

        _end:
        OS.routine_end(0x20)
    }

    _physics: {
        OS.routine_begin(0x20)
        lw      s0, 0x0084(a0)  // s0 = player struct

        lw      s0, 0x0084(a0)  // s0 = player struct
        lw      t6, 0x014C(s0)  // t6 = kinetic state (0 = grounded, 1 = aerial)
        bnez    t6, _aerial
        nop

        _grounded:
        jal     0x800D8BB4 // grounded subroutine, apply ground friction
        nop
        b       _end
        nop

        _aerial:
        jal     0x800D91EC // aerial subroutine, apply aerial friction
        nop
        
        _end:
        OS.routine_end(0x20)
    }

    scope _collision: {
        OS.routine_begin(0x28)
        sw      s0, 0x18(sp)
        sw      a0, 0x1C(sp)

        lw      s0, 0x84(a0)  // s0 = player struct
        lw      t6, 0x014C(s0)  // t6 = kinetic state (0 = grounded, 1 = aerial)
        bnez    t6, _aerial
        nop

        _grounded:
        jal 0x800DDF44 // grounded subroutine - do not fall from ledges
        nop
        b _end
        nop

        _aerial:
        li      a1, _air_to_ground  // a1 (transition subroutine) = air_to_ground_
        jal     0x800DE80C          // mpCommonProcFighterCliff(GObj *fighter_gobj, void (*proc_map)(GObj*)) air collision subroutine (transition on landing, allows ledge grab)
        nop 

        _end:
        lw  s0, 0x18(sp)
        lw  a0, 0x1C(sp)
        OS.routine_end(0x28)
    }

    scope _air_to_ground: {
        // here, a0 = player object
        OS.routine_begin(0x20)
        jal     0x800DEE98      // set grounded state
        lw      a0, 0x84(a0)    // player struct
        OS.routine_end(0x20)
    }
}

scope IceClimbersUSP: {
    // @ Description
    // Subroutine which runs when Ice Climbers initiates an up special.
    // Changes action, and sets up initial variable values.
    scope _initial: {
        addiu   sp, sp, 0xFFE0              // ~
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // original lines 1-3

        lw      a1, 0x84(a0) // a1 = player struct

        // reset fast fall
        lbu     v1, 0x018D(a1)              // v1 = fast fall flag
        ori     t6, r0, 0x0007              // t6 = bitmask (01111111)
        and     v1, v1, t6                  // ~
        sb      v1, 0x018D(a1)              // disable fast fall flag
        // reset fall speed
        sw      r0, 0x004C(a1)              // y velocity = 0
        sw      r0, 0x0058(a1)              // air y speed = 0
        // reset x speed
        sw      r0, 0x48(a1) // X Velocity = 0
        sw      r0, 0x54(a1) // Air X velocity = 0

        // set initial x speed
        li          at, 0x41A00000  // initial max speed = 20
        mtc1        at, f12         // f12 = initial max speed
        lb          at, 0x01C2(a1)  // at = stick_x
        mtc1        at, f14         // ~
        cvt.s.w     f14, f14        // f14 = float(stick x)
        lli         at, 80          // max stick x value
        mtc1        at, f10         // f10 = max stick x value
        cvt.s.w     f10, f10        // f10 = float(max stick x value)
        div.s       f14, f14, f10   // f14 = normalized stick X value
        mul.s       f14, f14, f12   // f14 = initial max speed * normalized stick X
        swc1        f14, 0x48(a1)   // X Velocity
        swc1        f14, 0x54(a1)   // Air X velocity

        _check_if_brother:
        // fighter is a brother if its own object is in the brother object link table
        // in the position of the port it's assigned to
        li      t0, DualFighter.brother_object_link_table // t0 = brother_object_link_table address
        lbu     t1, 0xD(a1) // t1 = port id
        sll     t1, t1, 0x02 // t1 = port * 4
        addu    t0, t0, t1 // t0 = brother_object_link_table[port]
        lw      t0, 0x0(t0) // t0 = brother object in table

        lw      t1, 0x4(a1) // load our fighter object

        bne     t1, t0, _solo // if fighter object != brother object, we're not a brother in a duo. skip.
        nop

        _is_brother:
        // find sister object
        li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
        lbu     t1, 0xD(a1) // t1 = port id
        sll     t1, t1, 0x02 // t1 = port * 4
        addu    t0, t0, t1 // t0 = sister_object_link_table[port]
        lw      t0, 0x0(t0) // t0 = sister object

        beq     t0, r0, _solo // if there's no sister(???) go solo
        nop

        _check_sister_action: {
            // check for actions that CAN be cancelled into the duo move
            lw      t2, 0x84(t0) // t2 = sister player struct
            lw      t3, 0x24(t2) // t3 = sister action

            // Idle, movement
            lli     at, Action.Idle
            blt     t3, at, pc() + 12
            lli     at, Action.TeeterStart
            ble     t3, at, _check_sister_distance
            
            // Falling (no hitstun)
            lli     at, Action.Tumble
            blt     t3, at, pc() + 12
            lli     at, Action.LandingSpecial
            ble     t3, at, _check_sister_distance

            // Shielding, rolling
            lli     at, Action.ShieldOn
            blt     t3, at, pc() + 12
            lli     at, Action.RollB
            ble     t3, at, _check_sister_distance

            // Normals, aerials, landing lag
            lli     at, Action.Jab1
            blt     t3, at, pc() + 12
            lli     at, Action.LandingAirX
            ble     t3, at, _check_sister_distance

            // usp: only allow Nana to join if either we or her are offstage
            // check nana
            lli     at, IceClimbers.Action.SQUALLSOLO
            bne     t3, at, pc() + (4*9)
            lw      t3, 0xEC(t2) // t3 = clipping id Nana is above (0xFFFF if none)
            addiu   at, r0, -1 // at = 0xFFFFFFF
            beq     t3, at, _check_sister_distance
            nop
            lw      t3, 0xEC(a1) // t3 = clipping id Popo is above (0xFFFF if none)
            addiu   at, r0, -1 // at = 0xFFFFFFF
            beq     t3, at, _check_sister_distance
            nop

            // no actions match, skip to solo squall
            b       _solo
            nop
        }

        _check_sister_distance:
        // if sister not in range, skip to _solo
        lw      t2, 0x84(t0) // t2 = sister player struct
        lw      t3, 0x78(t2) // t3 = sister player position vec3
        lwc1    f2, 0x0(t3) // f2 = sister x
        lwc1    f4, 0x4(t3) // f4 = sister y

        lw      t3, 0x78(a1) // t3 = brother player position vec3
        lwc1    f6, 0x0(t3) // f6 = brother x
        lwc1    f8, 0x4(t3) // f8 = brother y

        sub.s   f2, f2, f6 // f2 = sister x - brother x
        sub.s   f4, f4, f8 // f4 = sister y - brother y
        mul.s   f2, f2, f2 // f2 = (sister x - brother x)^2
        mul.s   f4, f4, f4 // f4 = (sister y - brother y)^2
        add.s   f2, f2, f4 // f2 = (sister x - brother x)^2 + (sister y - brother y)^2
        sqrt.s  f2, f2 // f2 = sqrt((sister x - brother x)^2 + (sister y - brother y)^2)

        lui     at, 0x44FA // 1000.0
        mtc1    at, f4 // f4 = 1000.0
        c.lt.s  f2, f4 // if distance < 1000.0
        nop
        bc1fl   _solo // if not, skip to _solo
        nop

        _duo:
        OS.save_registers()
        addiu   sp, sp, -0x20
        sw      t0, 0x14(sp)                 // save player object
        or      a0, r0, t0                  // a0 = player object
        lli     a1, IceClimbers.Action.SQUALLDUONANA // a1 = Action.USPA
        sw      r0, 0x0010(sp)              // argument 4 = 0
        or      a2, r0, r0                  // a2 = float: 0.0
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3 = float: 1.0
        // jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x14(sp)                 // a0 = player object
        addiu   sp, sp, 0x20
        OS.restore_registers()

        lli     a1, IceClimbers.Action.SQUALLDUO // a1 = Action.USPA
        b       _continue
        nop

        _solo:
        lli     a1, IceClimbers.Action.SQUALLSOLO // a1 = Action.USPA

        _continue:
        sw      r0, 0x0010(sp)              // argument 4 = 0
        or      a2, r0, r0                  // a2 = float: 0.0
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3 = float: 1.0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        ori     v1, r0, 0x0002              // ~
        sw      v1, 0x0184(a0)              // temp variable 3 = 0x1(BEGIN)
        lw      ra, 0x001C(sp)              // ~
        addiu   sp, sp, 0x0020              // ~
        jr      ra                          // original return logic
        nop
    }

    // forces Nana to Popo's position
    scope _nana_duo_physics: {
        OS.routine_begin(0x20)

        define player_object(0x0(sp))
        define player_struct(0x4(sp))
        define brother_object(0x8(sp))
        define brother_struct(0xC(sp))

        sw      a0, 0x1C(sp)
        lw      s0, 0x84(a0) // s0 = player struct
        sw      a0, {player_object}
        sw      s0, {player_struct}

        // find brother object
        li      t0, DualFighter.brother_object_link_table // t0 = brother_object_link_table address
        lbu     t1, 0xD(s0) // t1 = port id
        sll     t1, t1, 0x02 // t1 = port * 4
        addu    t0, t0, t1 // t0 = brother_object_link_table[port]
        lw      t0, 0x0(t0) // t0 = brother object

        beqz    t0, _skip // no brother found
        nop

        lw      t1, 0x84(t0) // t1 = brother struct
        sw      t0, {brother_object}
        sw      t1, {brother_struct}

        _sync_position:
        lw      t2, 0x78(t1) // t2 = brother player position vec3
        lwc1    f2, 0x0(t2) // f2 = brother x
        lwc1    f4, 0x4(t2) // f4 = brother y

        lw      t2, 0x78(s0) // t2 = player position vec3
        swc1    f2, 0x0(t2) // sister x = brother x
        swc1    f4, 0x4(t2) // sister y = brother y

        scope _sync_kinetic_state: {
            lw      t6, 0x014C(s0) // t6 = kinetic state (0 = grounded, 1 = aerial)
            lw      t7, 0x014C(t1) // t7 = brother kinetic state
            beq     t6, t7, _end // skip if same
            nop
            
            bnez    t6, _aerial
            nop

            _grounded:
            jal     0x800DEEC8 // mpCommonSetFighterAir(FTStruct *fp)
            lw      a0, 0x84(a0) // player struct
            b _end
            nop

            _aerial:
            jal     0x800DE324 // mpCommonSetFighterProjectGround(GObj *fighter_gobj) - this updates all ground collision variables
            lw      a0, {player_object}
            jal     0x800DEE98 // mpCommonSetFighterGround(FTStruct *fp)
            lw      a0, {player_struct}

            _end:
            lw      a0, {player_object} // recover variables
            lw      s0, {player_struct}
            lw      t0, {brother_object}
            lw      t1, {brother_struct}
        }

        _sync_clipping_id: {
            lw t6, 0xEC(t1) // t6 = clipping id brother is above
            sw t6, 0xEC(s0) // t6 = clipping id Nana is above
        }

        _sync_speeds:
        lw      t2, 0x48(t1) // X Velocity
        sw      t2, 0x48(s0)
        lw      t2, 0x4C(t1) // Y Velocity
        sw      t2, 0x4C(s0)
        lw      t2, 0x54(t1) // Air X velocity
        sw      t2, 0x54(s0)
        lw      t2, 0x58(t1) // Air Y velocity
        sw      t2, 0x58(s0)
        lw      t2, 0x8C(t1) // X Speed
        sw      t2, 0x8C(s0)
        lw      t2, 0x90(t1) // Y Speed
        sw      t2, 0x90(s0)

        _sync_hitlag:
        lw      t2, 0x40(t1) // t2 = hitlag
        sw      t2, 0x40(s0)
        lb      t2, 0x192(t1) // fp->is_knockback_paused
        sb      t2, 0x192(s0)

        _sync_animation:
        lw      t2, 0x0078(t0)  // t2 = brother animation frame
        lw      t3, 0x0078(a0)  // t3 = current animation frame

        beq     t2, t3, _skip // if already sync, skip
        nop

        // void lbCommonAddFighterPartsFigatree(DObj *root_dobj, void **figatree, f32 anim_frame)
        lw      t7, 0x8E8(s0)
        lw      a0, 0x10(t7) // a0 = root dobj
        lw      a1, 0x9CC(s0) // a1 = figatree (fighter animation tree)
        jal     0x800C87F4
        lw      a2, 0x0078(t0)  // t2 = brother animation frame
        lw      a0, 0x1C(sp)

        lw      t1, {brother_struct}
        lw      s0, {player_struct}

        lw      at, 0x1C(t1) // at = brother current frame (int)
        sw      at, 0x1C(s0) // at = current frame (int)

        // sync position we're at in the moveset commands file
        lw      at, 0x8A8(t1) // fp->motion_scripts[0][0].script_wait
        sw      at, 0x8A8(s0)

        jal     0x800E0830 // ftMainPlayAnimNoEffect(GObj *fighter_gobj) (update animation)
        nop

        _skip:
        OS.routine_end(0x20)
    }

    scope _update: {
        OS.routine_begin(0x20)

        lw      s0, 0x0084(a0)  // s0 = player struct
        lw      t6, 0x014C(s0)  // t6 = kinetic state (0 = grounded, 1 = aerial)
        bnez    t6, _aerial
        nop

        _grounded:
        // if animation ends, go to idle
        jal     0x800D94C4 // ftAnimEndSetWait(GObj *fighter_gobj)
        nop
        b       _end
        nop

        _aerial:
        // checks the current animation frame to see if we've reached end of the animation
        mtc1    r0, f6                      // ~
        lwc1    f8, 0x0078(a0)              // ~
        c.le.s  f8, f6                      // ~
        nop
        bc1fl   _end                        // skip if animation end has not been reached
        nop

        // ftCommonFallSpecialSetStatus(GObj *fighter_gobj, f32 drift, sb32 unknown, sb32 is_fall_accelerate, sb32 is_goto_landing, f32 landing_lag, sb32 is_allow_interrupt)
        addiu   sp, sp, -0x20
        lui     a1, 0x3F70                  // a1 (air speed multiplier) = 0.9375
        or      a2, r0, r0                  // a2 (unknown) = 0
        lli     a3, 0x0001                  // a3 (can fast fall) = 1
        sw      r0, 0x0010(sp)              // a4 (is_goto_landing) = 0
        sw      r0, 0x0018(sp)              // is_allow_interrupt = FALSE
        lui     t6, 0x3F00                  // t6 = 0.5
        sw      t6, 0x0014(sp)              // a5 (landing_lag) = 0.5
        jal     0x801438F0                  // begin special fall
        nop
        addiu   sp, sp, 0x20

        _end:
        OS.routine_end(0x20)
    }

    // interrupt if brother is not doing squall with us
    scope _duo_interrupt_sister: {
        OS.routine_begin(0x20)

        define player_object(0x0(sp))
        define player_struct(0x4(sp))
        define brother_object(0x8(sp))
        define brother_struct(0xC(sp))

        sw      a0, 0x1C(sp)
        lw      s0, 0x84(a0) // s0 = player struct
        sw      a0, {player_object}
        sw      s0, {player_struct}

        // find brother object
        li      t0, DualFighter.brother_object_link_table // t0 = brother_object_link_table address
        lbu     t1, 0xD(s0) // t1 = port id
        sll     t1, t1, 0x02 // t1 = port * 4
        addu    t0, t0, t1 // t0 = brother_object_link_table[port]
        lw      t0, 0x0(t0) // t0 = brother object

        beqz    t0, _interrupt // no brother found
        nop

        lw      t1, 0x84(t0) // t1 = brother struct
        sw      t0, {brother_object}
        sw      t1, {brother_struct}

        lw      t2, 0x0024(t1) // t2 = brother's current action
        lli     t3, IceClimbers.Action.SQUALLDUO
        bne     t2, t3, _interrupt // skip if brother is not performing squall
        nop

        b       _skip
        nop

        _interrupt:
        lw      t6, 0x014C(s0)  // t6 = kinetic state (0 = grounded, 1 = aerial)
        bnez    t6, _aerial
        nop

        _grounded:
        jal     0x8013E1C8 // ftCommonWaitSetStatus(GObj *fighter_gobj)
        nop
        b       _skip
        nop

        _aerial:
        // ftCommonFallSpecialSetStatus(GObj *fighter_gobj, f32 drift, sb32 unknown, sb32 is_fall_accelerate, sb32 is_goto_landing, f32 landing_lag, sb32 is_allow_interrupt)
        addiu   sp, sp, -0x20
        lui     a1, 0x3F70                  // a1 (air speed multiplier) = 0.9375
        or      a2, r0, r0                  // a2 (unknown) = 0
        lli     a3, 0x0001                  // a3 (can fast fall) = 1
        sw      r0, 0x0010(sp)              // a4 (is_goto_landing) = 0
        sw      r0, 0x0018(sp)              // is_allow_interrupt = FALSE
        lui     t6, 0x3F00                  // t6 = 0.5
        sw      t6, 0x0014(sp)              // a5 (landing_lag) = 0.5
        jal     0x801438F0                  // begin special fall
        nop
        addiu   sp, sp, 0x20

        _skip:
        OS.routine_end(0x20)
    }

    // interrupt if brother is not doing squall with us
    scope _duo_interrupt_brother: {
        OS.routine_begin(0x20)

        define player_object(0x0(sp))
        define player_struct(0x4(sp))
        define sister_object(0x8(sp))
        define sister_struct(0xC(sp))

        sw      a0, 0x1C(sp)
        lw      s0, 0x84(a0) // s0 = player struct
        sw      a0, {player_object}
        sw      s0, {player_struct}

        // find sister object
        li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
        lbu     t1, 0xD(s0) // t1 = port id
        sll     t1, t1, 0x02 // t1 = port * 4
        addu    t0, t0, t1 // t0 = sister_object_link_table[port]
        lw      t0, 0x0(t0) // t0 = sister object

        beqz    t0, _interrupt // no sister found
        nop

        lw      t1, 0x84(t0) // t1 = sister struct
        sw      t0, {sister_object}
        sw      t1, {sister_struct}

        lw      t2, 0x0024(t1) // t2 = sister's current action
        lli     t3, IceClimbers.Action.SQUALLDUONANA
        bne     t2, t3, _interrupt // skip if sister is not performing squall
        nop

        b       _skip
        nop

        _interrupt:
        lw      t6, 0x014C(s0)  // t6 = kinetic state (0 = grounded, 1 = aerial)
        bnez    t6, _aerial
        nop

        _grounded:
        jal     0x8013E1C8 // ftCommonWaitSetStatus(GObj *fighter_gobj)
        nop
        b       _skip
        nop

        _aerial:
        // ftCommonFallSpecialSetStatus(GObj *fighter_gobj, f32 drift, sb32 unknown, sb32 is_fall_accelerate, sb32 is_goto_landing, f32 landing_lag, sb32 is_allow_interrupt)
        addiu   sp, sp, -0x20
        lui     a1, 0x3F70                  // a1 (air speed multiplier) = 0.9375
        or      a2, r0, r0                  // a2 (unknown) = 0
        lli     a3, 0x0001                  // a3 (can fast fall) = 1
        sw      r0, 0x0010(sp)              // a4 (is_goto_landing) = 0
        sw      r0, 0x0018(sp)              // is_allow_interrupt = FALSE
        lui     t6, 0x3F00                  // t6 = 0.5
        sw      t6, 0x0014(sp)              // a5 (landing_lag) = 0.5
        jal     0x801438F0                  // begin special fall
        nop
        addiu   sp, sp, 0x20

        _skip:
        OS.routine_end(0x20)
    }

    scope _collision: {
        OS.routine_begin(0x28)
        sw      s0, 0x18(sp)
        sw      a0, 0x1C(sp)

        lw      s0, 0x84(a0)  // s0 = player struct
        lw      t6, 0x014C(s0)  // t6 = kinetic state (0 = grounded, 1 = aerial)
        bnez    t6, _aerial
        nop

        _grounded:
        jal 0x800DDF44 // grounded subroutine - do not fall from ledges
        nop
        b _end
        nop

        _aerial:
        li      a1, _air_to_ground  // a1 (transition subroutine) = air_to_ground_
        jal     0x800DE80C          // mpCommonProcFighterCliff(GObj *fighter_gobj, void (*proc_map)(GObj*)) air collision subroutine (transition on landing, allows ledge grab)
        nop 

        _end:
        lw  s0, 0x18(sp)
        lw  a0, 0x1C(sp)
        OS.routine_end(0x28)
    }

    scope _air_to_ground: {
        // here, a0 = player object
        OS.routine_begin(0x20)
        jal     0x800DEE98      // set grounded state
        lw      a0, 0x84(a0)    // player struct
        OS.routine_end(0x20)
    }

    scope _physics: {
        OS.routine_begin(0x20)

        sw      a0, 0x18(sp)

        lw      s0, 0x84(a0)  // s0 = player struct
        lw      t6, 0x014C(s0)  // t6 = kinetic state (0 = grounded, 1 = aerial)
        bnez    t6, _aerial
        nop

        scope _grounded: {
            _control:
            // do not allow control by the end of the animation
            lui     at, 0x4248 // 50.0
            mtc1    at, f6
            lwc1    f8, 0x0078(a0)
            c.le.s  f8, f6
            nop
            bc1fl   _friction // skip if frame >= final movement frame
            nop

            _control_x:
            or      a1, r0, r0 // arg2 = min stick X
            li      a2, 0x3D4CCCCD // arg3 (acceleration) = 0.05
            li      a3, 0x42100000 // arg4 (max speed) = 36
            jal     0x800D89E0 // ftPhysicsApplyClampGroundVelStickRange(FTStruct *fp, s32 stick_x_min, f32 vel, f32 clamp)
            lw      a0, 0x84(a0) // arg0 = player struct
            lw      a0, 0x18(sp) // restore a0

            _fly:
            lw      s0, 0x84(a0) // s0 = player struct
            lh      t0, 0x01BE(s0) // get button pressed
            andi    t0, t0, Joypad.B // check if B pressed
            beqz    t0, _friction
            nop
            li      a1, 0x41F00000 // arg1 = velocity = 30
            li      a2, 0x42200000 // arg2 = clamp = 40
            jal     0x800D8D34 // ftPhysicsAddClampAirVelY(FTStruct *fp, f32 vel, f32 clamp)
            lw      a0, 0x84(a0) // arg0 = player struct
            lw      a0, 0x18(sp) // restore a0

            li      a1, 0x41F00000 // arg1 = velocity = 30
            lw      s0, 0x84(a0) // s0 = player struct
            sw      a1, 0x4c(s0) // save Y speed = tap upwards speed
            
            jal     0x800DEEC8 // mpCommonSetFighterAir(FTStruct *fp)
            lw      a0, 0x84(a0) // arg0 = player struct
            lw      a0, 0x18(sp) // restore a0

            b       _end // If we flew, we lift from the ground. Skip grounded friction
            nop
            
            _friction:
            li      a1, 0x3fA00000 // arg1 = friction multiplier = 1.25
            jal     0x800D8978 // ftPhysicsSetGroundVelFriction(FTStruct *fp, f32 friction)
            lw      a0, 0x84(a0) // arg0 = player struct
            lw      a0, 0x18(sp) // restore a0

            jal     0x800D87D0 // ftPhysicsSetGroundVelTransferAir(GObj *fighter_gobj) (applies ground speed)
            nop
            lw      a0, 0x18(sp) // restore a0

            b       _end
            nop
        }

        scope _aerial: {
            _gravity:
            li      a1, 0x4059999A // arg1 = gravity = 3.4
            li      a2, 0x428C0000 // arg2 = (terminal) max fall speed = 70
            jal     0x800D8D68 // ftPhysicsApplyGravityClampTVel(FTStruct *fp, f32 gravity, f32 tvel)
            lw      a0, 0x84(a0) // arg0 = player struct
            lw      a0, 0x18(sp) // restore a0
            
            _control:
            // do not allow control by the end of the animation
            lui     at, 0x4248 // 50.0
            mtc1    at, f6
            lwc1    f8, 0x0078(a0)
            c.le.s  f8, f6
            nop
            bc1fl   _friction // skip if frame >= final movement frame
            nop

            _control_x:
            or      a1, r0, r0 // arg2 = min stick X
            li      a2, 0x3D4CCCCD // arg3 = 0.05
            li      a3, 0x42100000 // arg4 = 36

            jal     0x800D8FC8 // ftPhysicsClampAirVelXStickRange(FTStruct *fp, s32 stick_x_min, f32 vel, f32 clamp)
            lw      a0, 0x84(a0) // arg0 = player struct
            lw      a0, 0x18(sp) // restore a0

            scope _fly: {
                lw      s0, 0x84(a0) // s0 = player struct
                lh      t0, 0x01BE(s0) // get button pressed
                andi    t0, t0, Joypad.B // check if B pressed
                beqz    t0, _friction
                nop
                
                li      a1, 0x42200000 // arg1 = velocity = 40
                li      a2, 0x42200000 // arg2 = clamp = 40

                lw      t0, 0x0024(s0) // t0 = current action
                lli     t1, IceClimbers.Action.SQUALLDUO
                beq     t0, t1, _apply_velocity // if performing squall duo, use these rise speeds
                nop
                // if solo, rise less
                li      a1, 0x41C80000 // arg1 = velocity = 30
                li      a2, 0x41C80000 // arg2 = clamp = 30
                
                _apply_velocity:
                jal     0x800D8D34 // ftPhysicsAddClampAirVelY(FTStruct *fp, f32 vel, f32 clamp)
                lw      a0, 0x84(a0) // arg0 = player struct
                lw      a0, 0x18(sp) // restore a0
            }

            _friction:
            lw      a0, 0x84(a0) // arg0 = player struct
            jal     0x800D9074 // ftPhysicsApplyAirVelXFriction(FTStruct *fp, FTAttributes *attr)
            lw      a1, 0x9C8(a0) // arg1 = player attributes
            lw      a0, 0x18(sp) // restore a0
        }

        _end:
        OS.routine_end(0x20)
    }
}