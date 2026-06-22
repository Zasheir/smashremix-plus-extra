scope DualFighter {
    // Note: I know they're not brother and sister, but I thought naming things "sister" was funny!

    // TODO: apply popoforce in the air too
    // TODO: detect grab input and ignore button press if not holding an item

    is_processing_sister:
    dw  0

    sister_object_link_table:
    dw  0   // P1
    dw  0   // P2
    dw  0   // P3
    dw  0   // P4

    brother_object_link_table:
    dw  0   // P1
    dw  0   // P2
    dw  0   // P3
    dw  0   // P4

    scope InputBuffer: {
        // 2b button held mask + 1b stick X + 1b stick Y + 4b (1 word) facing direction
        constant FRAME_SIZE(8)
        constant MAX_FRAMES(6)
        constant BUFFER_TOTAL_SIZE(FRAME_SIZE * MAX_FRAMES)

        buffer:
        fill (BUFFER_TOTAL_SIZE) // p1
        fill (BUFFER_TOTAL_SIZE) // p2
        fill (BUFFER_TOTAL_SIZE) // p3
        fill (BUFFER_TOTAL_SIZE) // p4
    }

    scope Camera: {
        // 0x8010BC54
        // This is in the loop that finds which players to follow
        // The object has an array of 4 entries for that, so we avoid overflowing it
        scope find_fighters: {
            OS.patch_start(0x875FC, 0x8010BDFC)
            j       find_fighters
            nop
            nop
            _return:
            OS.patch_end()

            lw t0, 0x84(s0) // t0 = processed player struct

            _original:
            lw s0, 0x4(s0) // original line 1: load next player object pointer

            beqz s0, _end // if next player is null, return
            nop

            lw v0, 0x0084(s0) // original line 3: load next player struct

            lb t1, 0xD(t0) // t1 = previous player port
            lb t2, 0xD(v0) // t2 = current player port

            beq t1, t2, _original // if previous player port == current player port, skip
            nop

            // continue with the loop
            _j_8010BC9C:
            j   0x8010BC9C // continue the loop
            nop

            _end:
            j       _return
            nop
        }
    }

    scope Hitbox: {
        // 800E4870+50
        scope search_fighter_hitbox: {
            OS.patch_start(0x600C0, 0x800E48C0)
            j       search_fighter_hitbox
            nop
            _return:
            OS.patch_end()

            lw t9, 0x00A4(sp) // original line 1: other gobj
            lw t1, 0x00A8(sp) // original line 2: self gobj

            lli t2, 0x1 // original line 3

            // t3 and t5 seem safe to use
            _normal_hitbox:
            lw t3, 0x84(t9) // t3 = other player struct
            lb t3, 0xD(t3) // t3 = other player port

            lw t5, 0x84(t1) // t5 = self player struct
            lb t5, 0xD(t5) // t5 = self player port

            beq t3, t5, _j_624 // if other player port == self player port, skip collision
            nop

            _throw_hitbox:
            lw t3, 0x84(t9) // t3 = other player struct
            lw t3, 0x0844(t3) // Player Captured by (object)
            beqz t3, _thrown_hitbox // if no player capturing them, skip check
            nop
            lw t3, 0x84(t3) // other player struct
            lb t3, 0xD(t3) // t3 = other player port
            beq t3, t5, _j_624 // if other player port == self player port, skip collision
            nop

            _thrown_hitbox:
            lw t3, 0x84(t9) // t3 = other player struct
            lw t3, 0x278(t3) // t3 = GObj of opponent that threw this fighter
            beqz t3, _end // if no player capturing them, skip check
            nop
            lw t3, 0x84(t3) // other player struct
            lb t3, 0xD(t3) // t3 = other player port
            beq t3, t5, _j_624 // if other player port == self player port, skip collision
            nop

            _end:
            j       _return
            nop

            _j_624:
            j 0x800E4870+0x624 // skip secondary character
            sw t2,0x68(sp) // original line 4
        }

        // 800E5E58+70
        scope search_fighter_catch: {
            OS.patch_start(0x616C8, 0x800E5EC8)
            j       search_fighter_catch
            nop
            _return:
            OS.patch_end()

            // t9 = our fighter gobj
            // s3 = hitbox owner's fighter gobj
            lw      t5, 0x84(t9) // t5 = our fighter struct

            _check_if_relative:
            lw      t2, 0x84(t9) // t2 = fighter struct (me)
            lbu     t2, 0xD(t2) // t2 = fighter port id (me)
            lw      t3, 0x84(s3) // t3 = hitbox owner fighter struct
            lbu     t3, 0xD(t3) // t2 = hitbox owner port id

            beq     t2, t3, _j_270 // same port means we're relatives
            nop

            _original:
            beql    s3, t9, _j_270 // original line 1: is the current gobj (s3) == me? If so, go to next loop iteration
            nop

            _end:
            j       _return
            nop

            _j_270:
            j       0x800E5E58+0x270
            lw      s3, 0x4(s3) // original line 2: load next fighter gobj for next iteration
        }

        // ftMainSearchWeaponAttack
        // 0x800E4ED4+60
        scope search_weapon_attack: {
            OS.patch_start(0x60734, 0x800E4F34)
            j       search_weapon_attack
            nop
            _return:
            OS.patch_end()

            // t9 = our fighter gobj
            // t1 = hitbox owner's fighter gobj

            beqz    t1, _original // if the hitbox has no owner, continue normally
            nop

            lw      t2, 0x84(t9) // t2 = fighter struct (me)
            lbu     t2, 0xD(t2) // t2 = fighter port id (me)
            lw      t3, 0x84(t1) // t3 = hitbox owner fighter struct
            lbu     t3, 0xD(t3) // t2 = hitbox owner port id

            beq     t2, t3, _j_6CC // same port means we're relatives
            nop

            _original:
            beql    t9, t1, _j_6CC // original line 1: is the weapon hitbox owner == me? If so, go to next loop iteration
            nop

            _end:
            j       _return
            lw      t9, 0xb4(sp) // original line 2

            _j_6CC:
            j       0x800E4ED4+0x6CC
            lw      t9, 0xb4(sp) // original line 2
        }

        // ftMainSearchItemAttack
        // 0x800E55DC+60
        scope search_item_attack: {
            OS.patch_start(0x60E3C, 0x800E563C)
            j       search_item_attack
            nop
            _return:
            OS.patch_end()

            // t9 = our fighter gobj
            // t1 = hitbox owner's fighter gobj (can be null!)

            beqz    t1, _end // if the item has no owner, skip
            nop

            lw      t2, 0x84(t9) // t2 = fighter struct (me)
            lbu     t2, 0xD(t2) // t2 = fighter port id (me)

            lw      t3, 0x84(t1) // t3 = hitbox owner fighter struct
            lbu     t3, 0xD(t3) // t2 = hitbox owner port id

            beq     t2, t3, _j_618 // same port means we're relatives
            nop

            _original:
            beql    t9, t1, _j_618 // original line 1: is the weapon hitbox owner == me? If so, go to next loop iteration
            nop

            _end:
            j       _return
            lw      t5, 0x00B4(sp) // original line 2

            _j_618:
            j       0x800E55DC+0x618
            lw      t5, 0x00B4(sp) // original line 2
        }

        // wpProcessProcSearchHitWeapon - weapon on weapon (projectile on projectile)
        // 0x80166954+B8
        scope search_weapon_on_weapon_collision: {
            OS.patch_start(0xE144C, 0x80166A0C)
            j       search_weapon_on_weapon_collision
            nop
            _return:
            OS.patch_end()

            // t5 = our fighter gobj
            // t7 = hitbox owner's fighter gobj

            beql    t5, t7, _j_258 // original line 1: both projectiles have the same owner, skip to next iteration
            nop

            // if any of the owners is null, skip
            beqz    t5, _end
            nop
            beqz    t7, _end
            nop

            lw      t0, 0x84(t5) // t0 = fighter struct (me)
            lbu     t0, 0xD(t0) // t0 = fighter port id (me)

            lw      t1, 0x84(t7) // t1 = hitbox owner fighter struct
            lbu     t1, 0xD(t1) // t1 = hitbox owner port id

            beq     t0, t1, _j_258 // same port means we're relatives
            nop

            _end:
            j       _return
            nop

            _j_258:
            j       0x80166954+0x258
            lw      s5, 0x4(s5) // original line 2
        }

        // void itProcessSearchFighterAttack(GObj *item_gobj) // Check fighters for hit detection
        // 0x801705C4+68
        scope search_item_hitbox_collision: {
            OS.patch_start(0xEB06C, 0x8017062C)
            j       search_item_hitbox_collision
            nop // original line 2
            _return:
            OS.patch_end()

            // t9 = item owner fighter gobj
            // v1 = hitbox owner's fighter gobj

            // if any of the owners is null, skip
            beqz    t9, _original
            nop
            beqz    v1, _original
            nop

            lw      t1, 0x84(t9) // t1 = item owner struct
            lbu     t1, 0xD(t1) // t1 = item owner port id

            lw      t6, 0x84(v1) // t6 = hitbox owner fighter struct
            lbu     t6, 0xD(t6) // t6 = hitbox owner port id

            beq     t1, t6, _end // same port means we're relatives. skip object comparison
            nop

            _original:
            bne     t9, v1, _j_7C // original line 1: item and hitbox have the same owner, skip to next iteration
            nop

            _end:
            j       _return
            nop

            _j_7C:
            j       0x801705C4+0x7C
            nop // original line 2
        }

        // void itProcessSearchItemAttack(GObj *this_gobj) // Check other items for hit detection
        // 0x8017088C+88
        scope search_item_on_item_collision: {
            OS.patch_start(0xEB354, 0x80170914)
            j       search_item_on_item_collision
            nop // original line 2
            _return:
            OS.patch_end()

            // t9 = item owner fighter gobj
            // t0 = hitbox owner's fighter gobj

            // if any of the owners is null, skip
            beqz    t9, _original
            nop
            beqz    t0, _original
            nop

            lw      t2, 0x84(t9) // t2 = item owner struct
            lbu     t2, 0xD(t2) // t2 = item owner port id

            lw      t3, 0x84(t0) // t3 = hitbox owner fighter struct
            lbu     t3, 0xD(t3) // t3 = hitbox owner port id

            beq     t2, t3, _end // same port means we're relatives. skip object comparison
            nop

            _original:
            bne     t9, t0, _j_9C // original line 1: item and hitbox have the same owner, skip to next iteration
            nop

            _end:
            j       _return
            nop

            _j_9C:
            j       0x8017088C+0x9C
            nop // original line 2
        }

        // void itProcessSearchWeaponAttack(GObj *item_gobj) // Check weapons for hit detection
        // 0x80170C84
    }

    // Make sister receive more damage from attacks
    // Make sister deal less damage and more knockback with her direct attacks
    scope Damage: {
        // 800E3EBC+960
        // ftMainProcessHitCollisionStatsMain
        scope sister_added_knockback: {
            OS.patch_start(0x6001C, 0x800E481C)
            j       sister_added_knockback
            nop
            _return:
            OS.patch_end()

            constant KNOCKBACK_MULTI(0x3F8CCCCD) // 1.1

            lwc1    f16,0xa0(sp) // original line 1: load final knockback value

            // s5 = player struct
            // 0xc8(sp) = player object

            lw  t2, 0xC8(sp) // t2 = player object

            _check_if_sister:
            // fighter is a sister if its own object is in the sister object link table
            // in the position of the port it's assigned to
            li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu     t1, 0xD(s5) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = sister_object_link_table[port]
            lw      t0, 0x0(t0) // t0 = sister object

            bne     t2, t0, _end // if fighter object != sister object, skip
            nop

            _is_sister:
            li      at, KNOCKBACK_MULTI // at = multiplier
            mtc1    at, f18 // load multiplier into f18
            mul.s   f16, f16, f18 // apply multiplier to final knockback

            _end:
            j       _return
            lli     at,2 // original line 2: load 2, used to check if damage type is gmHitCollision_Element_Electric
        }

        // Make sister's moves deal less damage and more knockback
        // 0x800DF0F0+348
        // ftMainParseMotionEvent
        scope sister_lower_damage_higher_kb: {
            OS.patch_start(0x5AC38, 0x800DF438)
            j       sister_lower_damage_higher_kb
            nop
            _return:
            OS.patch_end()

            srl     t5, t8, 0x16 // original line 1
            sw      t5, 0x2C(t0) // original line 2: save hitbox knockback growth

            // s1 = fighter struct
            // t0 = hitbox struct (ft_hit)

            _check_if_sister:
            // fighter is a sister if its own object is in the sister object link table
            // in the position of the port it's assigned to
            li      t4, DualFighter.sister_object_link_table // t4 = sister_object_link_table address
            lbu     t5, 0xD(s1) // t5 = port id
            sll     t5, t5, 0x02 // t5 = port * 4
            addu    t4, t4, t5 // t4 = sister_object_link_table[port]
            lw      t4, 0x0(t4) // t4 = sister object

            lw      t5, 0x4(s1) // t5 = player object

            bne     t5, t4, _end // if fighter object != sister object, skip
            nop

            _is_sister:
            lwc1        f2, 0xC(t0) // loads damage from hitbox struct
            cvt.s.w     f2, f2 // convert damage to float
            lui         at, 0x3F40 // multiplier = 0.75
            mtc1        at, f4 // f4 = multiplier
            mul.s       f2, f2, f4 // multiply damage by multiplier
            ceil.w.s    f2, f2 // convert to int (round up)
            swc1        f2, 0xC(t0) // saves damage to hitbox struct

            lwc1        f2, 0x2C(t0) // loads knockback growth from hitbox struct
            cvt.s.w     f2, f2 // convert knockback growth to float
            li          at, 0x3F99999A // multiplier = 1.2
            mtc1        at, f4 // f4 = multiplier
            mul.s       f2, f2, f4 // multiply knockback growth by multiplier
            ceil.w.s    f2, f2 // convert to int (round up)
            swc1        f2, 0x2C(t0) // saves knockback growth to hitbox struct

            _end:
            j       _return // return
            nop
        }
    }

    // When the brother is in hitlag, we apply some hitlag to the sister too
    // so that they stay in sync more often than not
    scope Hitlag: {
        // 800E61EC+4AC
        scope apply_hitlag_to_sister: {
            OS.patch_start(0x61E98, 0x800E6698)
            jal     apply_hitlag_to_sister
            nop
            _return:
            OS.patch_end()

            // s0 = player struct
            // 0xA0(sp) = player object

            _check_if_brother:
            // fighter is a brother if its own object is in the brother object link table
            // in the position of the port it's assigned to
            li      t0, DualFighter.brother_object_link_table // t0 = brother_object_link_table address
            lbu     t1, 0xD(s0) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = brother_object_link_table[port]
            lw      t0, 0x0(t0) // t0 = brother object in table

            lw      t1, 0xA0(sp) // load our fighter object

            bne     t1, t0, _original // if fighter object != brother object, we're not a brother in a duo. skip.
            nop

            _is_brother:
            // find sister object
            li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu     t1, 0xD(s0) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = sister_object_link_table[port]
            lw      t0, 0x0(t0) // t0 = sister object

            // if sister not in range, skip to _original
            lw      t2, 0x84(t0) // t2 = sister player struct
            lw      t3, 0x78(t2) // t3 = sister player position vec3
            lwc1    f2, 0x0(t3) // f2 = sister x
            lwc1    f4, 0x4(t3) // f4 = sister y

            lw      t3, 0x78(s0) // t3 = brother player position vec3
            lwc1    f6, 0x0(t3) // f6 = brother x
            lwc1    f8, 0x4(t3) // f8 = brother y

            sub.s   f2, f2, f6 // f2 = sister x - brother x
            sub.s   f4, f4, f8 // f4 = sister y - brother y
            mul.s   f2, f2, f2 // f2 = (sister x - brother x)^2
            mul.s   f4, f4, f4 // f4 = (sister y - brother y)^2
            add.s   f2, f2, f4 // f2 = (sister x - brother x)^2 + (sister y - brother y)^2
            sqrt.s  f2, f2 // f2 = sqrt((sister x - brother x)^2 + (sister y - brother y)^2)

            lui     at, 0x447A // 1000.0
            mtc1    at, f4 // f4 = 1000.0
            c.lt.s  f2, f4 // if distance < 1000.0
            nop
            bc1fl   _original // if not, skip to _original
            nop

            lwc1    f0, 0x40(s0) // load current hitlag value
            cvt.s.w f0, f0 // convert hitlag to float

            // load sister hitlag value
            lwc1    f2, 0x40(t2) // t2 = sister hitlag value
            cvt.s.w f2, f2 // convert sister hitlag to float

            _check_if_hitlag_greater:
            // if our hitlag * 0.25 > sister's hitlag value, set our hitlag to sister
            lui     at, 0x3E80 // 0.25
            mtc1    at, f4 // f4 = 0.25
            mul.s   f0, f0, f4 // f0 = our hitlag * 0.25
            c.lt.s  f2, f0 // if sister's hitlag < our hitlag * 0.25
            nop
            bc1fl   _original // if not, skip to _original
            nop

            _set_hitlag:
            trunc.w.s   f0, f0 // convert to int (truncate)
            swc1        f0, 0x40(t2) // set hitlag to sister's hitlag
            lbu         t0, 0x192(t2) // load fp->is_knockback_paused
            ori         t0, t0, 0x2 // set fp->is_knockback_paused = TRUE; This operation is needed because the byte is shared
            sb          t0, 0x192(t2) // save back
            
            sh          r0, 0x1c0(t2) // fp->input.pl.button_tap = 0
            sh          r0, 0x1be(t2) // fp->input.pl.button_tap_prev = 0
            lw          t0, 0xa04(t2) // t0 = fp->proc_lagstart
            beqzl       t0, _original // if no fp->proc_lagstart function, skip
            mtc1        r0, f0 // original code did this
            jalr        t0 // if there's a fp->proc_lagstart, run it
            lw          a0, 0x4(t2) // a0 = sister player object
            mtc1        r0, f0 // original code did this

            _original:
            lw      t7, 0x84(sp) // original line 1
            beqzl   t7, _j_4C8 // original line 2
            lw      v0, 0xA04(s0) // original line 3
            j       _return
            nop

            _j_4C8:
            j       0x800E61EC+0x4C8
            nop
        }
    }

    // When changing into an action, the game sets a uniquely generated (incremental) id
    // called "motion_count" in the decomp
    // This is used to check and not apply staling on mulithit moves
    // Here, we check if we're performing the same action as Popo to make it work similarly
    // to multihit moves
    scope Staling: {
        // 800EA5E8+14
        scope match_brother_motion_count: {
            OS.patch_start(0x65DFC, 0x800EA5FC)
            jal match_brother_motion_count
            lw t7,0x18(sp) // original line 1: t7 = player struct
            _return:
            OS.patch_end()

            // t7 = player struct

            // get brother object
            li      t9, DualFighter.brother_object_link_table // t9 = brother_object_link_table address
            lbu     t8, 0xD(t7) // t8 = port id
            sll     t8, t8, 0x2 // t8 = port * 4
            addu    t9, t9, t8 // t9 = brother_object_link_table[port]
            lw      t9, 0x0(t9) // t9 = brother object

            beqz t9, _end // if there's no brother, skip
            nop

            lw t0, 0x4(t7) // t0 = our object
            beq t0, t9, _end // if we're the brother, skip
            nop

            lw t0, 0x84(t9) // t0 = brother struct
            lw t1, 0x24(t0) // t1 = brother current action

            lw t2, 0x24(t7) // our current action

            bne t1, t2, _end // if we're not changing to the same action as the brother, skip
            nop

            lh v0, 0x28C(t0) // load motion_count from brother

            _end:
            sh v0, 0x28C(t7) // original line 2: save motion_count to player struct
            j _return // return
            nop
        }
    }

    scope Moveset: {
        // ftMainSetStatus: 800E6F24 + 38
        // scope replace_sister_action: {
        //     OS.patch_start(0x6275C, 0x800E6F5C)
        //     jal     replace_sister_action
        //     nop
        //     _return:
        //     OS.patch_end()

        //     // a0 = fighter gobj
        //     // a1 = action to change to
        //     // s1 = character struct

        //     lw  t0, 0x0008(s1)  // t0 = character id

        //     _check_if_sister:
        //     // fighter is a sister if its own object is in the sister object link table
        //     // in the position of the port it's assigned to
        //     li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
        //     lbu     t1, 0xD(s1) // t1 = port id
        //     sll     t1, t1, 0x02 // t1 = port * 4
        //     addu    t0, t0, t1 // t0 = sister_object_link_table[port]
        //     lw      t0, 0x0(t0) // t0 = sister object

        //     bne     a0, t0, _end // if fighter object != sister object, skip
        //     nop

        //     lli     at, Action......forward air...

        //     addiu   a1, a1, 0x1 // change target action
        //     sw      a1, 0x94(sp) // save changex

        //     _end:
        //     lhu     t0, 0x28E(s1)    // original line 1
        //     sh      t0, 0(t8)        // original line 2
        //     j       _return         // return
        //     nop
        // }
    }

    scope Spawn: {
        // 800D7F3C+868
        // ftManager_MakeFighter
        scope spawn_sister: {
            OS.patch_start(0x53FA4, 0x800D87A4)
            j       spawn_sister
            nop
            _return:
            OS.patch_end()

            // s6 = ftSpawnInfo
            
            // check character id
            lw      t0, 0x0(s6) // t1 = character id
            lli     t1, Character.id.ICECLIMBERS
            bne     t0, t1, _original
            nop

            _check_spawn_sister:
            // if not spawning sister, set it to 1 and spawn her
            li      t0, DualFighter.is_processing_sister // t0 = is_processing_sister address
            lw      t1, 0(t0) // t1 = is_processing_sister
            bnez    t1, _original // if is_processing_sister != 0, skip
            nop

            lli     t1, 1 // is_processing_sister = 1
            sw      t1, 0(t0) // save is_processing_sister = 1

            // start by resetting sister pointer
            li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu     t1, 0x15(s6) // t1 = port id
            sll     t1, t1, 0x2 // t1 = port * 4
            addu    t0, t0, t1 // t0 = sister_object_link_table[port]
            sw      r0, 0x0(t0) // sister_object_link_table[port] = NULL

            // save brother object
            li      t0, DualFighter.brother_object_link_table // t0 = brother_object_link_table address
            lbu     t1, 0x15(s6) // t1 = port id
            sll     t1, t1, 0x2 // t1 = port * 4
            addu    t0, t0, t1 // t0 = brother_object_link_table[port]
            lw      v0, 0x60(sp) // v0 = player object
            sw      v0, 0x0(t0) // brother_object_link_table[port] = v0

            // costume id += 8
            lbu     t9, 0x17(s6)
            addiu   t9, t9, 0x8
            sb      t9, 0x17(s6)

            // computer level = 7 ("Nana" in Japanese)
            lli     t9, 0x7
            sb      t9, 0x13(s6)

            // create a new animation bank heap
            jal     0x800D78B4 // ftManager_AllocAnimHeapKind
            lw      a0,0x0(s6) // a0 = character id
            sw      v0,0x38(s6) // overwrite ftSpawnInfo.anim_heap_kind
            lw      ra, 0x4c(sp) // restore ra

            // check if currently in a match, branch to continue if that's the case
            li      t1, Global.current_screen
            lbu     t1, 0x0(t1)
            li      t2, Global.screen.VS_CSS
            beq     t1, t2, _continue
            li      t2, Global.screen._1P_CSS
            beq     t1, t2, _continue
            li      t2, Global.screen.TRAINING_CSS
            beq     t1, t2, _continue
            li      t2, Global.screen.BONUS_1_CSS
            beq     t1, t2, _continue
            li      t2, Global.screen.BONUS_2_CSS
            beq     t1, t2, _continue
            li      t2, Global.screen.RESULTS
            beq     t1, t2, _continue
            nop

            lli     t0, 0x1 // player kind = CPU
            sw      t0, 0x28(s6) // save player_spawn.pl_kind = CPU

            _continue:
            jal     0x800D7F3C // ftManager_MakeFighter
            or      a0, s6, r0 // a0 = ftSpawnInfo
            lw      ra, 0x4c(sp) // restore ra

            // set spawning sister to 0
            li      t0, DualFighter.is_processing_sister // t0 = is_processing_sister address
            sw      r0, 0(t0) // save is_processing_sister = 0

            // save sister object
            li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu     t1, 0x15(s6) // t1 = port id
            sll     t1, t1, 0x2 // t1 = port * 4
            addu    t0, t0, t1 // t0 = sister_object_link_table[port]
            sw      v0, 0x0(t0) // sister_object_link_table[port] = v0

            _edit_sister_attributes:
            // edited out because these will also affect brother
            // // v0 = sister GObj
            // lw  t0, 0x84(v0) // t0 = sister player struct
            // lw  t1, 0x9C8(t0) // t1 = sister attributes
            // sw  r0, 0x80(t1) // jostle width = 0 - disable jostle

            // // is_have_catch = 0 - disable grabbing
            // lbu     t2, 0x102(t1)
            // andi    t2, t2, 0xFFF7
            // sb      t2, 0x102(t1)

            _original:
            lw      v0,0x60(sp) // original line 1: load player object to return
            lw      s0,0x30(sp) // original line 2

            _end:
            j       _return
            nop
        }

        // 800D78E8+1C
        // ftManagerDestroyFighter
        scope destroy_sister: {
            OS.patch_start(0x53104, 0x800D7904)
            j       destroy_sister
            nop
            _return:
            OS.patch_end()

            lw t7, 0x84(a0) // original line 1: t7 = fighter struct
            sw t7, 0x2c(sp) // original line 2: save fighter struct to 0x2C
            // t7 is used after this
            
            _check_character:
            // check character id
            lw      t0, 0x0008(t7) // t0 = character ID
            lli     t1, Character.id.ICECLIMBERS
            bne     t0, t1, _original
            nop

            _check_has_sister:
            // save sister object
            li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu     t1, 0xD(t7) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = sister_object_link_table[port]
            lw      t2, 0x0(t0) // t2 = sister_object_link_table[port]

            beqz    t2, _original // we have no sister, skip
            nop

            _destroy_sister:
            // if we have a sister, set processing sister to 1 and destroy her object
            li      t0, DualFighter.is_processing_sister // t0 = is_processing_sister address
            lw      t1, 0(t0) // t1 = is_processing_sister
            bnez    t1, _original // if is_processing_sister != 0, skip
            nop

            lli     t1, 1 // is_processing_sister = 1
            sw      t1, 0(t0) // save is_processing_sister = 1

            jal     0x800D78E8
            or      a0, r0, t2 // a0 = sister object

            // restore all registers (copied from the start of the function)
            lw ra, 0x24(sp)
            lw s3, 0x20(sp)
            lw s2, 0x1c(sp)
            lw s1, 0x18(sp)
            lw s0, 0x14(sp)
            lw a0, 0x30(sp)
            lw t7, 0x84(a0)
            sw t7, 0x2c(sp)

            // set spawning sister to 0
            li      t0, DualFighter.is_processing_sister // t0 = is_processing_sister address
            sw      r0, 0(t0) // save is_processing_sister = 0

            // clear sister and brother objects link
            li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu     t1, 0xD(t7) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = sister_object_link_table[port]
            sw      r0, 0x0(t0) // sister_object_link_table[port] = r0

            li      t0, DualFighter.brother_object_link_table // t0 = brother_object_link_table address
            lbu     t1, 0xD(t7) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = brother_object_link_table[port]
            sw      r0, 0x0(t0) // brother_object_link_table[port] = r0

            _original:

            _end:
            j       _return
            nop
        }

        // 0x800D7194
        // ftManagerAllocFighter
        // this is the function that allocates fighter structs
        scope allocate_fighter_structs: {
            OS.patch_start(0x52994, 0x800D7194)
            j       allocate_fighter_structs
            nop
            _return:
            OS.patch_end()

            // if a1 < 8, set a1 to 8
            // a1 = number of fighters to allocate
            lli at, 0x8 // at = 8
            bge a1, at, _original // if a1 >= 8, skip
            nop

            lli a1, 0x8 // allocate 8 slots for fighters

            _original:
            sll a2, a1, 2 // original line 1
            subu a2, a2, a1 // original line 2

            _end:
            j      _return
            nop
        }
    }


    scope Jostle: {
        // Skip jostle if the other player is a sister
        // 800E1260+824
        // ftMainProcUpdateInterrupt
        scope skip_sister_jostle: {
            OS.patch_start(0x5D284, 0x800E1A84)
            j       skip_sister_jostle
            nop
            _return:
            OS.patch_end()

            // t1 = player object
            // a1 = other player object
            // v0 = other player struct

            // check if the other object is a sister object, skip if so
            li t9, DualFighter.sister_object_link_table // t9 = sister_object_link_table address
            lw at, 0x0(t9) // port 1
            beq a1, at, _j_A0C // skip jostle against this object, check next
            lw at, 0x4(t9) // port 2
            beq a1, at, _j_A0C // skip jostle against this object, check next
            lw at, 0x8(t9) // port 3
            beq a1, at, _j_A0C // skip jostle against this object, check next
            lw at, 0xC(t9) // port 4
            beq a1, at, _j_A0C // skip jostle against this object, check next
            nop

            // check if we're any sister, skip jostle if we are
            li t9, DualFighter.sister_object_link_table // t9 = sister_object_link_table address
            lw at, 0x0(t9) // port 1
            beq t1, at, _j_A70 // skip jostle completely
            lw at, 0x4(t9) // port 2
            beq t1, at, _j_A70 // skip jostle completely
            lw at, 0x8(t9) // port 3
            beq t1, at, _j_A70 // skip jostle completely
            lw at, 0xC(t9) // port 4
            beq t1, at, _j_A70 // skip jostle completely
            nop

            _end:
            bnezl t4, _j_A0C // original line 1
            lli a3, 1 // original line 2

            j _return
            nop

            // skip object
            _j_A0C:
            j 0x800E1260+0xA0C
            nop

            // skip jostle
            _j_A70:
            j 0x800E1260+0xA70
            mtc1 r0, f14 // original line on this jump
        }

        // Implement a custom jostle for the sister
        // Where she floats towards a position slightly behind the brother, aka "popoforce"
        // 800DA034+1C0
        // mpProcessUpdateMain
        scope popoforce: {
            // distance to be behind brother
            constant DISTANCE_X(0x42C80000) // 100.0

            // seems to be the same distance regardless of the value
            // the game corrects direction automatically, so negative is always towards the background
            constant DISTANCE_Z(0xC2C80000) // -100.0

            OS.patch_start(0x559F4, 0x800DA1F4)
            j popoforce
            add.s f4, f8, f18 // original line 1: coll_data->vel_speed.z + coll_data->vel_push.z;
            _return:
            OS.patch_end()

            swc1 f4, 0x8(s0) // original line 2: save new translate->z

            // s5 = object
            // s0 = object translation vec3

            // safe: t5, t6, t7, t8, t9
            or t6, r0, s5

            // check if the object matches a sister from the table
            li t9, DualFighter.sister_object_link_table // t9 = sister_object_link_table address
            lw at, 0x0(t9) // port 1
            beq t6, at, _check_distance
            lw at, 0x4(t9) // port 2
            beq t6, at, _check_distance
            lw at, 0x8(t9) // port 3
            beq t6, at, _check_distance
            lw at, 0xC(t9) // port 4
            beq t6, at, _check_distance
            nop
            b _end
            nop

            _check_distance:
            lw t7, 0x84(t6) // t7 = sister struct

            // get brother object
            li t9, DualFighter.brother_object_link_table // t9 = brother_object_link_table address
            lbu at, 0xD(t7) // at = port id
            sll at, at, 0x2 // at = port * 4
            addu t9, t9, at // t9 = brother_object_link_table[port]
            lw t8, 0x0(t9) // t8 = brother object
            lw t9, 0x84(t8) // t9 = brother player struct

            // t6 = sister object
            // t7 = sister struct
            // t8 = brother object
            // t9 = brother struct

            // check if we're less then 1000 units away from the brother (distance)
            lw at, 0x78(t9) // at = brother player position vec3
            lwc1 f0, 0x0(at) // f0 = brother x
            lwc1 f2, 0x4(at) // f2 = brother y
            
            lw at, 0x78(t7) // at = sister player position vec3
            lwc1 f4, 0x0(at) // f4 = sister x
            lwc1 f6, 0x4(at) // f6 = sister y

            sub.s f0, f0, f4 // f0 = brother x - sister
            sub.s f2, f2, f6 // f2 = brother y - sister y
            mul.s f0, f0, f0 // f0 = (brother x - sister x)^2
            mul.s f2, f2, f2 // f2 = (brother y - sister y)^2
            add.s f0, f0, f2 // f0 = (brother x - sister x)^2 + (brother y - sister y)^2
            sqrt.s f0, f0 // f0 = sqrt((brother x - sister x)^2 + (brother y - sister y)^2)

            // if we're less than 1000 units away from the brother, float towards a position behind him
            lui at, 0x447A // 1000.0
            mtc1 at, f2 // f2 = 1000.0
            c.lt.s f0, f2 // if distance < 1000.0
            nop
            bc1fl _end // branch to float towards a position behind the brother
            nop

            _check_action: {
                // actions where we don't apply popoforce
                lw t5, 0x24(t7) // t5 = sister action
                lli at, Action.Idle
                blt t5, at, _end // if action < Idle, skip
                // stage hazards and interactions, knockdown, tech, getup options - skip
                lli at, Action.Tornado
                blt t5, at, pc() + (4*4)
                lli at, Action.Tech
                ble t5, at, _end
                nop
                // shield break, stun, sleep, grab, throws, being thrown, inhaled, egg - skip
                lli at, Action.ShieldBreak
                blt t5, at, pc() + (4*4)
                lli at, Action.ThrownFoxB
                ble t5, at, _end
                nop
                // cheer
                lli at, IceClimbers.Action.CHEERF
                beq t5, at, _end
                lli at, IceClimbers.Action.CHEERB
                beq t5, at, _end
                nop
            }

            _float_to_position:
            // when close to brother, float towards a position behind him

            // get brother's x position into f6
            lw t5, 0x78(t9) // t5 = brother player position vec3
            lwc1 f6, 0x0(t5) // f6 = brother x

            // get brother's facing direction into f2
            lwc1 f2, 0x44(t9) // f2 = facing direction (1 = right, -1 = left)
            cvt.s.w f2, f2 // convert facing direction to float

            // load DISTANCE_X into f4
            li at, DISTANCE_X // DISTANCE_X
            mtc1 at, f4 // f4 = DISTANCE_X

            // calculate target position = f4
            mul.s f4, f4, f2 // f4 = DISTANCE_X * facing direction
            sub.s f4, f6, f4 // f4 = brother x - (DISTANCE_X * facing direction)

            // get sister's x position into f2
            lw t5, 0x78(t7) // t5 = sister player position vec3
            lwc1 f2, 0x0(t5) // f2 = sister x

            // get the difference between the sister's x and the target x into f6
            sub.s f6, f4, f2 // f6 = target x - sister x

            // normalize the distance to the target
            // divide distance by 1000 to normalize it
            lui at, 0x447A // 1000
            mtc1 at, f8 // f8 = 1000
            div.s f6, f6, f8 // f6 = (target x - sister x) / 1000
            nop

            // load force constant into f10
            lui at, 0x41F0 // 30.0
            mtc1 at, f10 // f10 = push force

            // make push force proportional to the difference between the sister's x and the target x
            mul.s f10, f10, f6 // f10 = push force * (target x - sister x)/1000

            // apply force x
            lwc1 f2, 0x0(s0) // pos x
            add.s f2, f2, f10
            swc1 f2, 0x0(s0) // save updated pos x

            _float_y:
            lw at, 0x14C(t7)
            beqz at, _float_behind_z // skip if grounded
            nop

            // get brother's y position into f4
            lw t5, 0x78(t9) // t5 = brother player position vec3
            lwc1 f4, 0x4(t5) // f4 = brother y

            // get sister's y position into f2
            lw t5, 0x78(t7) // t5 = sister player position vec3
            lwc1 f2, 0x4(t5) // f2 = sister y

            // get the difference between the sister's y and the target y into f6
            sub.s f6, f4, f2 // f6 = target y - sister y

            // normalize the distance to the target
            // divide distance by 1000 to normalize it
            lui at, 0x447A // 1000
            mtc1 at, f8 // f8 = 1000
            div.s f6, f6, f8 // f6 = (target y - sister y) / 1000
            nop

            // load force constant into f10
            lui at, 0x41F0 // 30.0
            mtc1 at, f10 // f10 = push force

            // make push force proportional to the difference between the sister's y and the target y
            mul.s f10, f10, f6 // f10 = push force * (target y - sister y)/1000

            // apply force y
            lwc1 f2, 0x4(s0) // pos y
            add.s f2, f2, f10
            swc1 f2, 0x4(s0) // save updated pos y

            _float_behind_z:
            // also go slightly to the background to draw under brother
            li at, DISTANCE_Z
            mtc1 at, f10 // f10 = DISTANCE_Z
            swc1 f10, 0x8(s0) // save updated pos z

            _end:
            j _return
            nop
        }
    }

    scope Ledge: {
        // 0x800DE45C+1D4 mpCommonRunFighterSpecialCollisions
        scope ignore_sister_cliff_catch: {
            OS.patch_start(0x59E30, 0x800DE630)
            j       ignore_sister_cliff_catch
            nop
            _return:
            OS.patch_end()

            beql    v1, a0, _j_21C // original line 1: if we're the fighter we're comparing to, skip
            nop

            lw      t4, 0x84(a0) // t4 = fighter struct
            lw      t5, 0x84(v1) // t5 = other fighter struct

            _check_if_other_is_sister:
            // fighter is a sister if its own object is in the sister object link table
            // in the position of the port it's assigned to
            li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu     t1, 0xD(t4) // t1 = OUR port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = sister_object_link_table[port]
            lw      t0, 0x0(t0) // t0 = sister object

            beq     v1, t0, _j_21C // if other fighter object == OUR sister object, skip to the next loop iteration
            nop

            _check_if_other_is_brother:
            // fighter is a brother if its own object is in the brother object link table
            // in the position of the port it's assigned to
            li      t0, DualFighter.brother_object_link_table // t0 = brother_object_link_table address
            lbu     t1, 0xD(t4) // t1 = OUR port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = brother_object_link_table[port]
            lw      t0, 0x0(t0) // t0 = brother object

            beq     v1, t0, _j_21C // if other fighter object == OUR brother object, skip to the next loop iteration
            nop

            // If here we're not comparing with ourselves, our sister, or our brother. Continue
            b       _end
            nop

            _j_21C:
            j       0x800DE45C+0x21C
            lw      v1, 0x4(v1) // load next fighter for the next loop iteration

            _end:
            j       _return
            nop
        }
    }

    scope Grab: {
        // Disable grab for sister

        // 0x80149C60+28 ftCommonCatchCheckInterruptGuard
        scope disable_shield_grab: {
            OS.patch_start(0xC46C8, 0x80149C88)
            j       disable_shield_grab
            lw      t9, 0x100(v0) // original line 1 
            _return:
            OS.patch_end()

            // a0 = fighter object
            // v1 = fighter struct

            // check if we're a sister
            li      t2, DualFighter.sister_object_link_table // t2 = sister_object_link_table address
            lbu     t3, 0xD(v1) // t3 = port id
            sll     t3, t3, 0x02 // t3 = port * 4

            addu    t2, t2, t3 // t2 = sister_object_link_table[port]
            lw      t2, 0x0(t2) // t2 = sister object

            beq     a0, t2, _is_sister // if player object == sister object
            nop

            b       _end
            nop

            _is_sister:
            j       0x80149C60+0x70 // return false -- don't grab
            lli     v0, 0x1 // return 1 to ignore grab inputs

            _end:
            j       _return
            sll     t1, t9, 0x14 // original line 2: here is_have_catch is being loaded into t1
        }

        // 0x80149CE0+70 ftCommonCatchCheckInterruptCommon
        scope disable_grab: {
            OS.patch_start(0xC4790, 0x80149D50)
            j       disable_grab
            lw      t4, 0x100(t3) // original line 1
            _return:
            OS.patch_end()

            // a1 = fighter object
            lw      t5, 0x84(a1) // t5 = fighter struct

            // check if we're a sister
            li      t2, DualFighter.sister_object_link_table // t2 = sister_object_link_table address
            lbu     t3, 0xD(t5) // t3 = port id
            sll     t3, t3, 0x02 // t3 = port * 4

            addu    t2, t2, t3 // t2 = sister_object_link_table[port]
            lw      t2, 0x0(t2) // t2 = sister object

            beq     a1, t2, _is_sister // if player object == sister object
            nop

            b       _end
            nop

            _is_sister:
            j       0x80149CE0+0x90 // return
            lli     v0, 0x1 // return 1 to ignore grab inputs

            _end:
            j       _return
            sll     t6,t4,0x14 // original line 2
        }
        
        // 0x80149D80+74 ftCommonCatchCheckInterruptDashRun
        scope dash_grab: {
            OS.patch_start(0xC4834, 0x80149DF4)
            j       dash_grab
            lw      t4, 0x100(t3) // original line 1
            _return:
            OS.patch_end()

            // a2 = fighter object
            lw      t5, 0x84(a2) // t5 = fighter struct

            // check if we're a sister
            li      t2, DualFighter.sister_object_link_table // t2 = sister_object_link_table address
            lbu     t1, 0xD(t5) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4

            addu    t2, t2, t1 // t2 = sister_object_link_table[port]
            lw      t2, 0x0(t2) // t2 = sister object

            beq     a2, t2, _is_sister // if player object == sister object
            nop

            b       _end
            nop

            _is_sister:
            j       0x80149D80+0x94 // return
            lli     v0, 0x1 // return 1 to ignore grab inputs

            _end:
            j       _return
            sll     t6, t4, 0x14 // original line 2
        }

        // 0x80149E24+64 ftCommonCatchCheckInterruptAttack11
        scope jab_grab: {
            OS.patch_start(0xC48C8, 0x80149E88)
            j       jab_grab
            nop
            _return:
            OS.patch_end()

            // a2 = fighter object
            lw      t5, 0x84(a2) // t5 = fighter struct

            // check if we're a sister
            li      t2, DualFighter.sister_object_link_table // t2 = sister_object_link_table address
            lbu     t6, 0xD(t5) // t6 = port id
            sll     t6, t6, 0x02 // t6 = port * 4

            addu    t2, t2, t6 // t2 = sister_object_link_table[port]
            lw      t2, 0x0(t2) // t2 = sister object

            beq     a2, t2, _is_sister // if player object == sister object
            nop

            b       _end
            nop

            _is_sister:
            j       0x80149E24+0x80 // return
            lli     v0, 0x1 // return 1 to ignore grab inputs

            _end:
            sll     t3, t1, 0x14
            bgez    t3, _b_80 // original line 1: checking is_have_chatch?
            nop
            j       _return
            nop

            _b_80:
            j       0x80149E24+0x80 // return
            nop
        }
    }

    scope KO: {
        // TODO: KO sister if brother is not coming back

        // 8013BF94+a4
        // ftCommonDeadCheckRebirth: when sister is KOed, do not revive
        scope skip_revive: {
            OS.patch_start(0xB6A78, 0x8013C038)
            j       skip_revive
            nop
            _return:
            OS.patch_end()

            // v0 = fighter struct
            // a0 = fighter object

            _check_if_sister:
            // fighter is a sister if its own object is in the sister object link table
            // in the position of the port it's assigned to
            li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu     t1, 0xD(v0) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = sister_object_link_table[port]
            lw      t0, 0x0(t0) // t0 = sister object

            bne     a0, t0, _normal // if fighter object != sister object, skip
            nop

            _is_sister:
            jal     0x8013D8B0 // ftCommonSleepSetStatus(fighter_gobj)
            nop
            b       _end
            nop

            _normal:
            jal     0x8013CF60 // original line 1: ftCommonRebirthDownSetStatus(GObj *this_gobj)
            nop // original line 2

            _end:
            j       _return
            nop
        }

        // 0x8013BD64+C
        // ftCommonDeadUpdateScore
        scope skip_score_update: {
            OS.patch_start(0xB67B0, 0x8013BD70)
            j       skip_score_update
            nop
            _return:
            OS.patch_end()

            // a0 = fighter struct

            _check_if_sister:
            // fighter is a sister if its own object is in the sister object link table
            // in the position of the port it's assigned to
            li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu     t1, 0xD(a0) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = sister_object_link_table[port]
            lw      t0, 0x0(t0) // t0 = sister object

            lw      t1, 0x4(a0) // load our fighter object

            bne     t1, t0, _normal // if fighter object != sister object, skip
            nop

            _is_sister:
            j       0x8013BD64+0x21C // skip the whole function
            nop

            _normal:
            jal     0x8010F76C // original line 1
            or      s0, r0, a0 // original line 2

            _end:
            j       _return
            nop
        }

        // 8013CF60+18
        // ftCommonRebirthDownSetStatus
        scope rebirth_sister: {
            OS.patch_start(0xB79B8, 0x8013CF78)
            j       rebirth_sister
            nop
            _return:
            OS.patch_end()

            lw  s1, 0x84(a0) // s1 = fighter struct

            _check_if_brother:
            // fighter is a brother if its own object is in the brother object link table
            // in the position of the port it's assigned to
            li      t0, DualFighter.brother_object_link_table // t0 = brother_object_link_table address
            lbu     t1, 0xD(s1) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = brother_object_link_table[port]
            lw      t0, 0x0(t0) // t0 = brother object

            bne     a0, t0, _original // if fighter object != brother object, skip
            nop

            _is_brother:
            // find sister object
            li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu     t1, 0xD(s1) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = sister_object_link_table[port]
            lw      t0, 0x0(t0) // t0 = sister object

            _revive_sister:
            // we have to save t7, a0, ra
            addiu sp, sp, -0x20 // allocate space
            sw  t7, 0x4(sp)
            sw  a0, 0x8(sp)
            sw  ra, 0x14(sp)

            jal     0x8013CF60 // call the function itself
            or      a0, r0, t0 // argument = sister object
            
            // TODO: sync all this_fp->status_vars.common.rebirth variables
            // TODO: clear input buffer
            // TODO: effect on vanish

            lw  t7, 0x4(sp)
            lw  a0, 0x8(sp)
            lw  ra, 0x14(sp)
            addiu sp, sp, 0x20 // deallocate space

            _original:
            or  s0, r0, a0 // original line 1
            lw  s1, 0x84(a0) // original line 2

            _end:
            j       _return
            nop
        }
    }

    scope AI: {
        // 8013A834+40
        // ftComputerProcessAll
        scope cpu_main: {
            OS.patch_start(0xB52B4, 0x8013A874)
            j       cpu_main
            nop
            _return:
            OS.patch_end()

            // a0 = fighter object
            // s0 = fighter struct

            _check_if_sister:
            // fighter is a sister if its own object is in the sister object link table
            // in the position of the port it's assigned to
            li      t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu     t1, 0xD(s0) // t1 = port id
            sll     t1, t1, 0x02 // t1 = port * 4
            addu    t0, t0, t1 // t0 = sister_object_link_table[port]
            lw      t0, 0x0(t0) // t0 = sister object

            beq     a0, t0, _is_sister // if fighter object == sister object, skip
            nop

            b      _end // skip the sister logic
            nop

            _is_sister: {
                addiu sp, sp, -0x20 // allocate space
                sw  ra, 0x4(sp)

                define brother_struct(0x8(sp))
                define input_queue_addr(0xC(sp))

                // get the address of our input buffer and save it
                _get_input_queue_addr: {
                    li      t0, DualFighter.InputBuffer.buffer // t0 = InputBuffer.buffer address

                    // get our port id
                    lbu     t4, 0xD(s0) // t4 = port id
                    lli     t9, DualFighter.InputBuffer.BUFFER_TOTAL_SIZE // t9 = BUFFER_TOTAL_SIZE
                    mul     t4, t4, t9 // t4 = port id * BUFFER_TOTAL_SIZE
                    addu    t0, t0, t4 // t0 = InputBuffer.buffer[port]

                    sw      t0, {input_queue_addr}
                }

                // get the brother object
                li      t0, DualFighter.brother_object_link_table // t0 = brother_object_link_table address
                lbu     t1, 0xD(s0) // t1 = port id
                sll     t1, t1, 0x02 // t1 = port * 4
                addu    t0, t0, t1 // t0 = brother_object_link_table[port]
                lw      t0, 0x0(t0) // t0 = brother object
                lw      t5, 0x84(t0) // t5 = brother player struct
                sw      t5, {brother_struct} // save brother struct for later

                // if brother is dead, act as a normal CPU
                lw      t0, 0x24(t5) // at = brother action
                lli     at, Action.ScreenKOWait // at = Action.ScreenKOWait = dead
                beql    t0, at, _end // if brother action == dead, skip to normal cpu
                addiu   sp, sp, 0x20 // deallocate space
                lli     at, Action.DeadU // at = Action.DeadU = fying in the distance
                beql    t0, at, _end // if brother action == dead, skip to normal cpu
                addiu   sp, sp, 0x20 // deallocate space
                lli     at, Action.ScreenKO // at = Action.ScreenKO = flying near screen
                beql    t0, at, _end // if brother action == dead, skip to normal cpu
                addiu   sp, sp, 0x20 // deallocate space
                
                // get the brother's position vec3 into t1
                lw      t1, 0x78(t5) // t1 = brother player position vec3

                // get the sister's cpu struct from the sister struct (s0)
                addiu   t2, s0, 0x01CC // t2 = FTComputer struct

                // save brother's fighter struct as the sister's target fighter
                sw      t5, 0x6C(t2) // save brother object to sister's cpu struct

                lw      t3, 0x0(t1) // t3 = brother x
                sw      t3, 0x60(t2) // save brother x to sister's cpu struct
                lw      t3, 0x4(t1) // t3 = brother y
                sw      t3, 0x64(t2) // save brother y to sister's cpu struct

                // load brother's position into f0 and f2
                lwc1    f0, 0x60(t2) // f0 = brother x
                lwc1    f2, 0x64(t2) // f2 = brother y

                // get sister's position into f4 and f6
                lw      t1, 0x78(s0) // t1 = sister player position vec3
                lwc1    f4, 0x0(t1) // f4 = sister x
                lwc1    f6, 0x4(t1) // f6 = sister y

                // calculate distance to brother
                sub.s   f0, f0, f4 // f0 = brother x - sister x
                sub.s   f2, f2, f6 // f2 = brother y - sister y
                mul.s   f0, f0, f0 // f0 = (brother x - sister x)^2
                mul.s   f2, f2, f2 // f2 = (brother y - sister y)^2
                add.s   f0, f0, f2 // f0 = (brother x - sister x)^2 + (brother y - sister y)^2
                sqrt.s  f0, f0 // f0 = sqrt((brother x - sister x)^2 + (brother y - sister y)^2)

                // save distance to brother into sister's cpu struct
                swc1    f0, 0x68(t2) // save distance to brother

                // if close to brother, we'll read his inputs and copy them to our buffer
                lui     at, 0x447A // 1000.0
                mtc1    at, f2 // f2 = 1000.0
                c.lt.s  f0, f2 // if distance to brother < 1000.0
                nop
                bc1tl   _copy_brother_inputs // branch to copy brother inputs
                nop

                scope _follow_brother: {
                    // base function for getting current objective
                    // this updates objective and gets awareness of ledges
                    // when offstage, it will set the objective to recovery
                    jal     0x80136D0C // ftComputerGetObjectiveStatus(GObj *this_gobj)
                    lw      a0, 0x4(s0) // a0 = fighter object
                    lw      ra, 0x4(sp) // restore ra

                    addiu   t0, s0, 0x1CC // t0 = cpu struct
                    lbu     t0, 0x0(t0) // t0 = current cpu objective

                    lli     t1, 0x4 // t1 = nFTComputerObjectiveRecover

                    bne     t0, t1, _move
                    nop

                    _recovery:
                    jal     0x80137F24 // ftComputerFollowObjectiveRecover(fighter struct)
                    or      a0, r0, s0 // a0 = fighter struct
                    lw      ra, 0x4(sp) // restore ra
                    
                    b       _handle_special_cases
                    nop

                    _move:
                    // move towards the brother
                    // this function will handle pointing stick towards objective
                    // and also jumping when target is above, etc
                    // save brother's line id as sister's fp->fighter_com.target_line_id
                    lw      t5, {brother_struct}
                    lw      at, 0xEC(t5) // at = brother line id
                    lw      t0, 0x14C(t5) // t0 = brother kinetic state
                    addiu   t1, r0, -1 // t1 = -1
                    bnezl   t0, pc()+12
                    sw      t1, 0x1CC+0x5C(s0) // if brother is grounded, set sister target_line_id to -1
                    sw      at, 0x1CC+0x5C(s0) // otherwise, set sister target_line_id to brother line id
                    // save brother's position as sister's ft_com->target_pos
                    lw      at, 0x78(t5) // at = brother vec3 position pointer
                    lwc1    f2, 0x0(at) // f2 = brother x
                    swc1    f2, 0x1CC+0x60(s0) // save brother x to sister's ft_com->target_pos.x
                    lwc1    f2, 0x4(at) // f2 = brother y
                    swc1    f2, 0x1CC+0x64(s0) // save brother y to sister's ft_com->target_pos.y
                    jal     0x80134E98 // ftComputerFollowObjectiveWalk(fighter struct)
                    or      a0, r0, s0 // a0 = fighter struct
                    lw      ra, 0x4(sp) // restore ra

                    jal     0x80131C68 // ftComputerUpdateInputs(fighter struct)
                    or      a0, r0, s0
                    lw      ra, 0x4(sp) // restore ra

                    _fix_walk_command: {
                        // release Z if separated while was holding shield
                        // otherwise the cpu would just stay there shielding
                        lh      t0, 0x01C6(s0)
                        sll     t0, t0, 16 // Shift left to move to upper 4 bytes
                        andi    t0, t0, 0xDFFF // Clear bit 0x2000 (Z) from t0
                        srl     t0, t0, 16 // Shift right to move back to lower 4 bytes
                        sh      t0, 0x01C6(s0)

                        // Here we check if the stick is set to a halfway point
                        // as the walk command does and update it to full stick instead
                        lb      t0, 0x01C8(s0) // t0 = cpu joystick X
                        lli     t1, 0x28 // going right, not full stick
                        beq     t1, t0, _set_joystick_x_max_x
                        lli     t1, 0xD8 // going left, not full stick
                        andi    t0, t0, 0x00FF // stick left would be FFD8, so separate only last byte
                        beq     t1, t0, _set_joystick_x_min_x
                        nop
                        b       _handle_special_cases
                        nop

                        _set_joystick_x_max_x:
                        lli     t0, 0x50 // set full stick to max range
                        sb      t0, 0x01C8(s0) // t0 = cpu joystick X
                        b       _handle_special_cases
                        nop

                        _set_joystick_x_min_x:
                        lli     t0, 0xB0 // set full stick to min range
                        sb      t0, 0x01C8(s0) // t0 = cpu joystick X
                        b       _handle_special_cases
                        nop

                        // in some special cases, we might wanna reset stick for a frame
                        // like if walking we want to dash instead,
                        // or if holding a cliff we want to climb it
                        _handle_special_cases:
                        lw      t1, 0x0024(s0)
                        lli     at, Action.Walk1
                        beq     t1, at, _reset_stick
                        lli     at, Action.Walk2
                        beq     t1, at, _reset_stick
                        lli     at, Action.Walk3
                        beq     t1, at, _reset_stick
                        lli     at, Action.CliffWait
                        beq     t1, at, _climb_cliff
                        lli     at, Action.CrouchIdle
                        beq     t1, at, _reset_stick
                        nop

                        b   _process_input_queue
                        nop

                        _reset_stick:
                        sb      r0, 0x01C8(s0) // cpu stick x = 0
                        sb      r0, 0x01C9(s0) // cpu stick y = 0
                        b       _process_input_queue
                        nop

                        _climb_cliff:
                        lli     a1, 0x2
                        jal     0x80132758 // ftComputerSetCommandImmediate
                        or      a0, r0, s0 // a0 = fighter struct
                        lw      ra, 0x4(sp) // restore ra
                        b       _process_input_queue
                        nop
                    }

                    b       _process_input_queue // process input queue even when far away
                    nop
                }

                _copy_brother_inputs:
                // copy brother inputs to our buffer
                lw      t0, {input_queue_addr}

                // reset inputs
                sh      r0, 0x01C6(s0) // save button mask to our struct
                sb      r0, 0x01C8(s0) // save joystick X to our struct
                sb      r0, 0x01C9(s0) // save joystick Y to our struct

                // assign the first input from our buffer into our struct
                lhu     t1, 0x0000(t0) // t1 = button mask
                lb      t2, 0x0002(t0) // t2 = joystick X
                lb      t3, 0x0003(t0) // t3 = joystick Y
                lw      t4, 0x0004(t0) // t4 = facing direction

                sh      t1, 0x01C6(s0) // save button mask to our struct
                sb      t2, 0x01C8(s0) // save joystick X to our struct
                sb      t3, 0x01C9(s0) // save joystick Y to our struct

                // ignore brother's input during grab
                lw t1, 0x0024(t5)
                lli at, Action.Grab
                beq at, t1, _ignore_input_press
                lli at, Action.GrabPull
                beq at, t1, _ignore_input_press
                lli at, Action.GrabWait
                beq at, t1, _ignore_input_press
                nop

                b _set_direction
                nop

                scope _ignore_input_press: {
                    // here we add the inputs to the held button mask too
                    // this will make Nana not trigger any button press trigger
                    lh t1, 0x01C6(s0) // load button mask
                    xori t1, t1, Joypad.Z | Joypad.R // ignore R and Z press since it will make Nana shield
                    sh t1, 0x01BC(s0) // save button held mask
                    sh t1, 0x01C6(s0) // save button held mask

                    // update stick values
                    lb at, 0x1C2(t5) // stick_x
                    sb at, 0x1C8(s0) // save joystick X to our struct
                    sb at, 0x1C2(s0) // stick_x
                    sb at, 0x1C4(s0) // prev_stick_x
                    lb at, 0x1C3(t5) // stick_y
                    sb at, 0x1C9(s0) // save joystick Y to our struct
                    sb at, 0x1C3(s0) // stick_y
                    sb at, 0x1C5(s0) // prev_stick_y

                    // also update timing-based stick triggers to not trigger jumps or rolls
                    addiu at, r0, -2
                    sb at, 0x268(s0) // tap_stick_x
                    sb at, 0x269(s0) // tap_stick_y
                    sb at, 0x26A(s0) // hold_stick_x
                    sb at, 0x26B(s0) // hold_stick_y

                    _fill_buffer_with_current_input:
                    li t9, DualFighter.InputBuffer.FRAME_SIZE // t9 = FRAME_SIZE
                    li t6, DualFighter.InputBuffer.MAX_FRAMES // t6 = MAX_FRAMES

                    move t7, r0 // t7 = 0 (index)

                    lh t1, 0x1BC(t5) // held buttons
                    lb t2, 0x1C2(t5) // stick_x
                    lb t3, 0x1C3(t5) // stick_y
                    lw t4, 0x44(t5) // facing direction

                    _fill_inputs_loop:
                    beq t7, t6, _loop_end // if index == MAX_FRAMES, end loop
                    nop
                    sh t1, 0x0000(t0) // save button mask
                    sb t2, 0x0002(t0) // save joystick X
                    sb t3, 0x0003(t0) // save joystick Y
                    sw t4, 0x0004(t0) // save facing direction
                    addu t0, t0, t9 // t0 = buffer + FRAME_SIZE * (index + 1)
                    b _fill_inputs_loop // loop
                    addiu t7, t7, 1 // index += 1
                    _loop_end:

                    // TODO: check final input press
                    // if Z+A, R, remove Z input?
                    // exception: held item

                    // topo do pulo fair - cai certinho
                    // double up air: popo landing lag, nana nao

                    b _is_sister_end
                    nop
                }

                scope _set_direction: {
                    // if sister is in a running/dashing state, do not apply turnaround
                    lw t1, 0x0024(s0)
                    lli at, Action.Dash
                    beq at, t1, _process_input_queue
                    lli at, Action.Run
                    beq at, t1, _process_input_queue
                    lli at, Action.RunBrake
                    beq at, t1, _process_input_queue
                    lli at, Action.Turn
                    beq at, t1, _process_input_queue
                    lli at, Action.TurnRun
                    beq at, t1, _process_input_queue
                    nop

                    // if sister is performing a special, do not turn around
                    lw t1, 0x0024(s0)
                    lli at, IceClimbers.Action.ICEBLOCK
                    beq at, t1, _process_input_queue
                    lli at, IceClimbers.Action.BLIZZARD
                    beq at, t1, _process_input_queue
                    nop

                    // if sister is grabbing the ledge, do not turnaround
                    lw t1, 0x0024(s0)
                    lli at, Action.CliffCatch // first cliff function
                    blt t1, at, pc()+(4*4)
                    lli at, Action.CliffEscapeSlow2 // last cliff function
                    ble t1, at, _process_input_queue
                    nop

                    b _continue
                    nop

                    _continue:
                    // if aerial, set current facing direction
                    // if grounded, set facing direction from 5 frames ago
                    lw    t2, 0x014C(s0) // t2 = kinetic state
                    bnez  t2, _aerial
                    nop

                    _grounded:
                    lw    t4, 0x0004(t0) // t4 = facing direction from (MAX_FRAMES-1)(!) frames ago, because the buffer didn't move yet!
                    sw    t4, 0x44(s0) // save facing direction
                    b     _process_input_queue
                    nop

                    _aerial:
                    lw          t4, 0x44(t5) // t4 = brother facing direction
                    sw          t4, 0x44(s0) // save facing direction

                    _update_model_rotation:
                    // update model rotation to match direction
                    mtc1        t4, f6 // f6 = facing direction
                    cvt.s.w     f6, f6 // convert facing direction to float
                    lui         at, 0x8013 // ~
                    lwc1        f8, 0xFE90(at) // at = rotation constant
                    mul.s       f8, f8, f6 // f8 = rotation constant * facing direction
                    lw          t4, 0x08E8(s0) // t4 = character control joint struct (s0 = fighter struct)
                    swc1        f8, 0x0034(t4) // update character rotation to match direction
                }

                _process_input_queue:
                // load required variables
                lw      t0, {input_queue_addr}
                lw      t5, {brother_struct}

                // move all inputs back by one
                li      t9, DualFighter.InputBuffer.FRAME_SIZE // t9 = FRAME_SIZE
                li      t6, DualFighter.InputBuffer.MAX_FRAMES // t6 = MAX_FRAMES
                addiu   t6, t6, -1 // t6 = MAX_FRAMES - 1

                move    t7, r0 // t7 = 0 (index)

                _move_inputs_loop:
                beq     t7, t6, _add_current_input // if index == MAX_FRAMES - 1, add current input
                nop

                addu    t8, t0, t9 // t8 = buffer + FRAME_SIZE * (index + 1)
                lhu     t1, 0x0000(t8) // t1 = button mask
                lb      t2, 0x0002(t8) // t2 = joystick X
                lb      t3, 0x0003(t8) // t3 = joystick Y
                lw      t4, 0x0004(t8) // t4 = facing direction

                sh      t1, 0x0000(t0) // save button mask
                sb      t2, 0x0002(t0) // save joystick X
                sb      t3, 0x0003(t0) // save joystick Y
                sw      t4, 0x0004(t0) // save facing direction

                addu    t0, t0, t9 // t0 = buffer + FRAME_SIZE * (index + 1)
                b       _move_inputs_loop // loop
                addiu   t7, t7, 1 // index += 1

                _add_current_input:
                // add the current brother input to the end of our buffer
                lhu     t1, 0x01BC(t5) // t1 = button mask
                lb      t2, 0x01C2(t5) // t2 = joystick X
                lb      t3, 0x01C3(t5) // t3 = joystick Y
                lw      t4, 0x044(t5) // t4 = facing direction

                sh      t1, 0x0000(t0) // save button mask
                sb      t2, 0x0002(t0) // save joystick X
                sb      t3, 0x0003(t0) // save joystick Y
                sw      t4, 0x0004(t0) // save facing direction
            }
            _is_sister_end:
            lw      ra, 0x4(sp)
            j       0x8013A834+0x64 // jump to the end of the function, skipping normal logic
            addiu sp, sp, 0x20 // deallocate space

            _end:
            jal     0x8013A63C // original line 1: ftComputerProcessTrait
            or      a0, r0, s0 // original line 2: load fighter struct into a0
            j       _return
            nop
        }
    }

    // Fixes for Remix code messing up our logic
    scope Remix: {
        // Remix code for z-cancel skips the check based on a random value
        // So we skip the remix patch and run the original code instead
        // Function: 0x80150A08
        scope z_cancel_: {
            OS.patch_start(0x000CB470, 0x80150A30)
            jal z_cancel_
            lw v0,0x180(v1) // original line 1
            _return:
            OS.patch_end()

            // v1 = fighter struct
            beqzl v0, _branch_b8 // original line 2
            lui at, 0xC1A0 // original line 3

            // Check if we're a sister
            li t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu t1, 0xD(v1) // t1 = port id
            sll t1, t1, 0x02 // t1 = port * 4
            addu t0, t0, t1 // t0 = sister_object_link_table[port]
            lw t0, 0x0(t0) // t0 = sister object
            lw t1, 0x4(v1) // t1 = fighter object
            bne t1, t0, _end // if fighter object != sister object, skip
            nop

            // If we're a sister, we skip the remix code and run the original code
            _original:
            lw t6, 0x160(v1)
            slti at, t6, 0xB // check Z press timing

            j 0x80150A08+0x38 // continue
            nop

            _branch_b8:
            j 0x80150A08+0xB8 // jump to else
            nop

            _end:
            j _return // return to the end of the function
            nop
        }
    }

    scope Menus: {
        // this is used to set animations in menus
        // scSubsysFighterSetStatus(GObj *fighter_gobj, s32 status_id)
        // 0x803905CC+8
        scope set_menu_action: {
            OS.patch_start(0x107BB4, 0x803905D4)
            j set_menu_action
            sw r0, 0x10(sp) // original line 1
            _return:
            OS.patch_end()

            or a2, r0, r0 // original line 2

            li at, 0x00010000
            beq a1, at, _end // if action == nFTDemoStatusNull, skip
            nop

            lw at, 0x84(a0) // at = fighter struct

            // a0 = fighter gobj
            _check_has_sister:
            li t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
            lbu t1, 0xD(at) // t1 = port id
            sll t1, t1, 0x2 // t1 = port * 4
            addu t0, t0, t1 // t0 = sister_object_link_table[port]
            lw t2, 0x0(t0) // t2 = sister_object_link_table[port]
            beqz t2, _end // we have no sister, skip
            nop

            addiu sp, sp, -0x20 // allocate space
            sw a0, 0x0(sp)
            sw a1, 0x4(sp)
            sw a2, 0x8(sp)
            sw a3, 0xC(sp)
            sw ra, 0x14(sp)

            or a0, r0, t2 // a0 = sister gobj

            li at, 0x10001 // win1
            beql a1, at, _change_action
            lli a1, IceClimbers.Action.WIN1NANA
            li at, 0x10002 // win2
            beql a1, at, _change_action
            lli a1, IceClimbers.Action.WIN2NANA
            li at, 0x10003 // win3
            beql a1, at, _change_action
            lli a1, IceClimbers.Action.WIN3NANA
            li at, 0x10004 // selected
            beql a1, at, _change_action
            lli a1, IceClimbers.Action.WIN3NANA
            li at, 0x10005 // claps
            beql a1, at, _change_action
            lli a1, IceClimbers.Action.CLAPSNANA

            _change_action:
            // call the function for the sister
            addiu sp, sp, -0x20 // allocate space
            jal 0x800E6F24 // ftMainSetStatus(GObj *fighter_gobj, s32 status_id, f32 frame_begin, f32 anim_speed, u32 flags)
            lui a3, 0x3F80 // a3 = 1.0f
            addiu sp, sp, 0x20 // deallocate space

            lw a0, 0x0(sp) // reload fighter gobj
            lw a1, 0x4(sp) // reload status id
            lw a2, 0x8(sp) // reload frame_begin
            lw a3, 0xC(sp) // reload flags
            lw ra, 0x14(sp) // reload ra
            addiu sp, sp, 0x20 // deallocate space

            // enforce original values
            sw r0, 0x10(sp) // original line 1
            or a2, r0, r0 // original line 2

            _end:
            j   _return
            nop
        }

        scope VS: {
            // https://github.com/VetriTheRetri/ssb-decomp-re/blob/0cb1816286948a1845aec5114ed6bb0c07234080/src/ovl26.c#L1341
            // 80134A8C+1A8
            // mnVSPlayersMakeFighter
            scope vs_spawn: {
                OS.patch_start(0x132EB4, 0x80134C34)
                j vs_spawn
                lwc1 f8, 0(v1) // original line 1: load menu zoom attribute
                _return:
                OS.patch_end()

                swc1 f8, 0x48(t5) // original line 2: save scale z as menu zoom attribute

                // s0 = fighter gobj
                _check_has_sister:
                li t0, DualFighter.sister_object_link_table // t0 = sister_object_link_table address
                lw t1, 0x6C(sp) // t1 = port id
                sll t1, t1, 0x2 // t1 = port * 4
                addu t0, t0, t1 // t0 = sister_object_link_table[port]
                lw t2, 0x0(t0) // t2 = sister_object_link_table[port]
                beqz t2, _end // we have no sister, skip
                nop

                scope _position: {
                    lw t1, 0x74(t2) // t1 = sister position vec3
                    lw t4, 0x74(s0) // t4 = brother position vec3

                    _pos_x:
                    lwc1 f2, 0x1C(t4) // f2 = brother x
                    lui at, 0x4348
                    mtc1 at, f4 // f4 = 200.0
                    add.s f6, f2, f4 // f2 = brother x + 200.0
                    swc1 f6, 0x1C(t1) // save sister x
                    sub.s f6, f2, f4 // f2 = brother x - 200.0
                    swc1 f6, 0x1C(t4) // save brother x

                    _pos_y:
                    lwc1 f2, 0x20(t4) // f2 = brother y
                    swc1 f2, 0x20(t1) // save sister y
                }

                scope _scale: {
                    lwc1 f2, 0x40(t4) // f2 = brother scale x
                    swc1 f2, 0x40(t1) // save sister scale x
                    lwc1 f2, 0x44(t4) // f2 = brother scale y
                    swc1 f2, 0x44(t1) // save sister scale y
                    lwc1 f2, 0x48(t4) // f2 = brother scale z
                    swc1 f2, 0x48(t1) // save sister scale z
                }

                _end:
                j   _return
                nop
            }

            // 0x800E9248
            // void ftParamInitAllParts(GObj *fighter_gobj, s32 costume, s32 shade)

            // void mnVSResultsSetFighterPosition(GObj* fighter_gobj, s32 player, s32 place)
            // We skip this one and instead set positions when setting scale!

            // void mnVSResultsSetFighterScale(GObj *fighter_gobj, s32 player, s32 fkind, s32 place)
            // 0x801338EC+0x30
            scope results_position_scale: {
                OS.patch_start(0x152ABC, 0x8013391C)
                j results_position_scale
                lw t0, 0x74(a0) // original line 1: t0 = model transforms
                _return:
                OS.patch_end()

                lwc1 f8, 0x0(v0) // original line 2: load menu zoom attribute (dSCSubsysFighterScales[fkind])

                // s0 = fighter gobj
                lw at, 0x84(a0) // at = fighter struct
                _check_has_sister:
                li t2, DualFighter.sister_object_link_table // t2 = sister_object_link_table address
                lbu t1, 0xD(at) // t1 = port id
                sll t1, t1, 0x2 // t1 = port * 4
                addu t2, t2, t1 // t2 = sister_object_link_table[port]
                lw t2, 0x0(t2) // t2 = sister_object_link_table[port]
                beqz t2, _end // we have no sister, skip
                nop

                lw t1, 0x74(t2) // t1 = sister model transforms

                lwc1 f2, 0x1C(t0) // f2 = brother x
                swc1 f2, 0x1C(t1) // save sister x
                lwc1 f2, 0x20(t0) // f2 = brother y
                swc1 f2, 0x20(t1) // save sister y
                lwc1 f2, 0x24(t0) // f2 = brother z
                swc1 f2, 0x24(t1) // save sister z
                lwc1 f2, 0x40(t0) // f2 = brother scale x
                swc1 f2, 0x40(t1) // save sister scale x
                lwc1 f2, 0x44(t0) // f2 = brother scale y
                swc1 f2, 0x44(t1) // save sister scale y
                lwc1 f2, 0x48(t0) // f2 = brother scale z
                swc1 f2, 0x48(t1) // save sister scale z

                _end:
                j   _return
                nop
            }
        }
    }
}

scope SFXReplace {
    // Replaces SFX calls from Moveset files for costumes
    // To be used with Character.costume_fgm_remap
    scope Moveset: {
        // SAMPLE:
        // db  0; // set for costume 0
        // db  2; // set for costume 2
        // db  0xFF // end costume listing
        // OS.align(4)
        // dh  0x03EA; dh 0x03EB // replace SFX1 with SFX2
        // dh  0xFFFF; // end SFX listing
        // OS.align(4)
        // Character.table_patch_start(costume_fgm_remap, Character.id.CHARACTER, 0x4)
        // dw SAMPLE; OS.patch_end()

        ICIES_REPLACE:
        // All Nana costumes
        db  01;
        db  02;
        db  05;
        db  07;
        db  08;
        db  11;
        db  12;
        db  14;
        db  0xFF // end costume listing
        OS.align(4)
        dh  IceClimbers.FGM.BLIZZ; dh IceClimbers.FGM.BLIZZNANA;
        dh  IceClimbers.FGM.DAMAGEFLY; dh IceClimbers.FGM.DAMAGEFLYNANA;
        dh  IceClimbers.FGM.DIE; dh IceClimbers.FGM.DIENANA;
        dh  IceClimbers.FGM.STARKO; dh IceClimbers.FGM.STARKONANA;
        dh  IceClimbers.FGM.ICEBLOCK; dh IceClimbers.FGM.ICEBLOCKNANA;
        dh  IceClimbers.FGM.SMASHD; dh IceClimbers.FGM.SMASHDNANA;
        dh  IceClimbers.FGM.SMASHF; dh IceClimbers.FGM.SMASHFNANA;
        dh  IceClimbers.FGM.SMASHU; dh IceClimbers.FGM.SMASHUNANA;
        dh  IceClimbers.FGM.SQUALL; dh IceClimbers.FGM.SQUALLNANA;
        dh  IceClimbers.FGM.TAUNT; dh IceClimbers.FGM.TAUNTNANA;
        dh  IceClimbers.FGM.STUN; dh IceClimbers.FGM.STUNNANA;
        dh  IceClimbers.FGM.SLEEP; dh IceClimbers.FGM.SLEEPNANA;
        dh  IceClimbers.FGM.TEETER; dh IceClimbers.FGM.TEETERNANA;
        dh  IceClimbers.FGM.TECH; dh IceClimbers.FGM.TECHNANA;
        dh  0xFFFF; // end SFX listing
        OS.align(4)

        // 800DF0F0+774
        scope voice_sfx_replace: {
            OS.patch_start(0x5B138, 0x800DF938)
            j       voice_sfx_replace
            nop
            _return:
            OS.patch_end()

            // s1 = fighter struct

            sw t9, 0x4(s0) // original line 1
            and a1, a1, at // original line 2

            _check_replace:
            lw      t0, 0x8(s1) // t0 = character ID
            // sll     t0, t0, 2
            // li      at, Character.costume_fgm_remap.table
            // addu    t0, t0, at              // t0 = entry
            // lw      t0, 0x0000(t0)          // t0 = characters entry in jump table
            // beqz    t0, _end                // skip if no entry
            // nop

            lli     at, Character.id.ICECLIMBERS
            bne     t0, at, _end
            nop

            li      t0, ICIES_REPLACE

            _continue:
            lb      t1, 0x10(s1) // t1 = costume ID
            or      t2, r0, r0 // will replace = false
            addiu   t3, r0, 0xFFFF // costume loop end marker
            _costume_loop:
            lb      at, 0x0(t0) // at = costume id in struct
            beq     at, t3, _costume_loop_end // 0xFF marks the end
            nop
            bne     at, t1, _costume_loop // if doesn't match our costume, go to next
            addiu   t0, t0, 0x1 // walk in the struct
            _matches:
            b       _costume_loop // we have to walk until the end is reached
            lli     t2, 0x1 // will replace = true
            _costume_loop_end:

            beqz    t2, _end // if will replace == false, skip
            nop

            // Align t0 to the next multiple of 4
            addiu   t0, t0, 0x3
            li      t1, 0xFFFFFFFC
            and     t0, t0, t1

            // Loop for GFX replacements
            lli   t3, 0xFFFF // t3 = loop end marker

            _gfx_loop:
            lhu     t5, 0x0(t0) // load original GFX
            beq     t5, t3, _end // if we find the end marker, exit
            nop
            lhu     t6, 0x2(t0) // load replacement GFX
            bne     a1, t5, _gfx_loop_next // if GFX doesn't match the table element, skip
            nop
            // if here, GFX id matches
            or      a1, t6, r0 // replace GFX
            b       _end // skip straight to the end
            nop
            _gfx_loop_next:
            addiu   t0, t0, 0x4 // go to next element
            b       _gfx_loop
            nop

            _end:
            j   _return
            nop
        }
    }
}