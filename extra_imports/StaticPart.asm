// StaticPart.asm
if !{defined __STATICPART__} {
define __STATICPART__()
print "included StaticPart.asm\n"

// @ Description
// This file sets up "static parts", a counterpart to withheld parts that will always appear.
// This will allow a static part of the model to exist

include "../src/OS.asm"
include "../src/Global.asm"

scope StaticPart {
    // @ Description
    // Exits function ftMainUpdateHiddenPartID early when running with a static part. Prevents withheld part from overriding the existing static part.
    scope prevent_update_static_part_: {
        OS.patch_start(0x621E4, 0x800E69E4)
        j       prevent_update_static_part_
        addu    t0, t6, t7                  // original line 1
        _return:
        OS.patch_end()

        // a2 = part id
        // a0 = player struct
        lw      a2, 0x0000(t0)              // a2 = part id (original line 2)
        li      t8, Character.static_part.table
        lw      at, 0x0008(a0)              // at = character id
        sll     at, at, 0x3                 // at = offset (id * 8)
        addu    t8, t8, at                  // t8 = static part bitfield address
        addiu   t9, a2, -4                  // t9 = part id, adjusted for upper bitfield
        sltiu   at, t9, 32                  // at = 1 if part id >32, else at = 0
        bnez    at, _continue               // branch if part id >32
        lw      t3, 0x0000(t8)              // t3 = static part bitfield (upper)

        // if part id is 32 or higher, we'll use the lower bitfield instead
        lw      t3, 0x0004(t8)              // t3 = static part bitfield (lower)
        addiu   t9, t9, -32                 // t9 = part id, adjusted for lower bitfield

        _continue:
        lui     at, 0x8000                  // at = bitmask
        srlv    at, at, t9                  // shift bitmask for part id
        and     t3, t3, at                  // t3 = 0 if part isn't static, else t3 != 0
        bnez    t3, _static                 // branch if static part
        nop

        _end:
        j       _return                     // return
        nop

        _static:
        j       0x800E6CD4                  // skip to the end of ftMainUpdateHiddenPartID
        lw      ra, 0x001C(sp)              // load ra
    }

    // @ Description
    // Exits function ftMainEjectHiddenPartID early when running with a static part. Prevents static part from being removed.
    scope prevent_eject_static_part_: {
        OS.patch_start(0x62618, 0x800E6E18)
        j       prevent_eject_static_part_
        addu    a3, t8, t9                  // original line 1
        _return:
        OS.patch_end()

        // t0 = part id
        // a0 = player struct
        lw      t0, 0x0000(a3)              // t0 = part id (original line 2)
        li      t8, Character.static_part.table
        lw      at, 0x0008(a0)              // at = character id
        sll     at, at, 0x3                 // at = offset (id * 8)
        addu    t8, t8, at                  // t8 = static part bitfield address
        addiu   t9, t0, -4                  // t9 = part id, adjusted for upper bitfield
        sltiu   at, t9, 32                  // at = 1 if part id >32, else at = 0
        bnez    at, _continue               // branch if part id >32
        lw      t3, 0x0000(t8)              // t3 = static part bitfield (upper)

        // if part id is 32 or higher, we'll use the lower bitfield instead
        lw      t3, 0x0004(t8)              // t3 = static part bitfield (lower)
        addiu   t9, t9, -32                 // t9 = part id, adjusted for lower bitfield

        _continue:
        lui     at, 0x8000                  // at = bitmask
        srlv    at, at, t9                  // shift bitmask for part id
        and     t3, t3, at                  // t3 = 0 if part isn't static, else t3 != 0
        bnez    t3, _static                 // branch if static part
        nop

        _end:
        j       _return                     // return
        nop

        _static:
        j       0x800E6F18                  // skip to the end of ftMainEjectHiddenPartID
        lw      ra, 0x0014(sp)              // load ra
    }

    // @ Description
    // Patch lbCommonSetupFighterPartsDObjs to create static parts
    scope always_create_static_parts_: {
        OS.patch_start(0x447E8, 0x800C8E08)
        j       always_create_static_parts_
        lw      s6, 0x0004(s0)              // s6 = withheld parts bitfield lower (original line 1)
        _return:
        OS.patch_end()

        // s5 = player struct (TODO: this is unsafe if any new lbCommonSetupFighterPartsDObjs calls are added)
        or      t0, s5, r0                  // t0 = player struct
        lw      s5, 0x0000(s0)              // s5 = withheld parts bitfield upper (original line 2)
        li      t1, Character.static_part.table
        lw      at, 0x0008(t0)              // at = character id
        sll     at, at, 0x3                 // at = offset (id * 8)
        addu    t1, t1, at                  // ~
        lw      at, 0x0000(t1)              // at = static part bitfield (upper)
        or      s5, s5, at                  // s5 = withheld parts bitfield | static bitfield (upper)
        lw      at, 0x0004(t1)              // at = static part bitfield (lower)
        j       _return
        or      s6, s6, at                  // s6 = withheld parts bitfield | static bitfield (lower)

        // ftCommonCaptureWaitKirbyUpdateBreakoutVar also calls lbCommonAddFighterPartsFigatree at
        // but a3 already contains the player struct! w00t
    }

    // @ Description
    // Pass player struct in a3 to lbCommonAddFighterPartsFigatree
    scope lbCommonAddFighterPartsFigatree_extra_arg_: {
        OS.patch_start(0x62FD4, 0x800E77D4)
        j       lbCommonAddFighterPartsFigatree_extra_arg_
        lw      a0, 0x0010(t7)              // original line 1
        _return:
        OS.patch_end()

        jal     0x800C87F4                  // original line 2 (lbCommonAddFighterPartsFigatree)
        or      a3, s1, r0                  // a3 = player struct
        j       _return
        nop

        // ftCommonCaptureWaitKirbyUpdateBreakoutVar also calls lbCommonAddFighterPartsFigatree at 8014BC7C
        // but a3 already contains the player struct! w00t
    }

    // @ Description
    // Updates lbCommonAddFighterPartsFigatree to skip static parts when loading animations.
    // This one was a lot of work... I wonder if there was an easier way to do it?
    scope skip_static_parts_: {
        // patch beginning of function
        OS.patch_start(0x441D4, 0x800C87F4)
        j       _stack_allocation
        addiu   sp, sp,-0x0050              // allocate stack space (modified original line 1)
        _stack_allocation_return:
        OS.patch_end()

        _stack_allocation:
        sw      s5, 0x0040(sp)              // store s5
        lw      s5, 0x4(a0)                 // s5 = root_dobj->parent_gobj
        lw      s5, 0x84(s5)                // s5 = player struct
        j       _stack_allocation_return    // return
        sdc1    f20, 0x0018(sp)             // original line 2

        // patch end of function
        OS.patch_start(0x44284, 0x800C88A4)
        j       _stack_deallocation
        lw      s5, 0x0040(sp)              // load s5
        OS.patch_end()

        _stack_deallocation:
        jr      ra                          // return (original line 1)
        addiu   sp, sp, 0x0050              // deallocate stack space (modified original line 2)

        // main hook
        OS.patch_start(0x44220, 0x800C8840)
        j       _augment_loop
        lw      a1, 0x0000(s2)              // original line 1
        _augment_loop_return:
        OS.patch_end()
        // s0 = current part
        // s5 = player struct
        // s3 = root model part

        _augment_loop:
        lw      t1, 0x0084(s0)              // ~
        lbu     t2, 0x000D(t1)              // t2 = part id
        li      t8, Character.static_part.table
        lw      at, 0x0008(s5)              // at = character id
        sll     at, at, 0x3                 // at = offset (id * 8)
        addu    t8, t8, at                  // t8 = static part bitfield address
        addiu   t9, t2, -4                  // t9 = part id, adjusted for upper bitfield
        sltiu   at, t9, 32                  // at = 1 if part id >32, else at = 0
        bnez    at, _continue               // branch if part id >32
        lw      t3, 0x0000(t8)              // t3 = static part bitfield (upper)

        // if part id is 32 or higher, we'll use the lower bitfield instead
        lw      t3, 0x0004(t8)              // t3 = static part bitfield (lower)
        addiu   t9, t9, -32                 // t9 = part id, adjusted for lower bitfield

        _continue:
        lui     at, 0x8000                  // at = bitmask
        srlv    at, at, t9                  // shift bitmask for part id
        and     t3, t3, at                  // t3 = 0 if part isn't static, else t3 != 0
        bnez    t3, _static                 // branch if static part
        nop

        _normal:
        // return and animate normally if not a static part
        j       _augment_loop_return        // return to vanilla loop
        lw      s1, 0x0084(s0)              // original line 2

        _static:
        // if we're here, then we've found a static part!
        // now, determine if it needs to be animated...
        // s0 = current part
        // t2 = part id
        lw      t8, 0x0198(s5)              // t8 = anim flags
        addiu   at, r0, 0xFFE0              // at = bitmask
        and     t8, t8, at                  // t8 = anim flags & mask
        or      t7, r0, r0                  // t7 = withheld parts table id

        ////// checks the withheld parts being "enabled" by the anim flags
        _anim_flag_loop:
        beqz    t8, _exit_anim_flag_loop    // exit loop if no more withheld parts enabled
        lui     t1, 0x8000                  // t1 = bitmask

        and     at, t8, t1                  // at = 0 if withheld part enabled, else t3 != 0
        beqz    at, _anim_flag_loop_end     // branch if withheld part isn't enabled
        nop

        // if we're here, there's a withheld part flag enabled on the animation, so check if it matches
        lw      t6, 0x09C8(s5)              // t6 = attribute pointer
        lw      t6, 0x02D0(t6)              // t6 = withheld parts table
        sll     at, t7, 0x4                 // at = offset (table id * 16)
        addu    t6, t6, at                  // t6 = entry for this part in withheld parts table
        lw      t6, 0x0000(t6)              // t6 = withheld part id
        beq     t6, t2, _animate_static_part // branch if withheld part id matches static part id!
        nop

        _anim_flag_loop_end:
        addiu   t7, t7, 0x0001              // increment withheld parts table id
        b       _anim_flag_loop             // loop
        sll     t8, t8, 1                   // shift bitfield by 1 (next part in table)

        //////// loop ends here
        // if we made it all the way to here, the current static part doesn't need to be animated
        _exit_anim_flag_loop:
        // since we're skipping this part, treat it as if there's no animation track
        // and adjust the track address in s2 to pretend like this never happened!
        or      a1, r0, r0                  // no animation track
        addiu   s2, s2,-0x0004              // s2 = previous animation track address
        j       _augment_loop_return        // return to vanilla loop
        lw      s1, 0x0084(s0)              // original line 2

        // if we make it here, it means an animation flag is being used to animate this part, which is usually static
        _animate_static_part:
        // ...so just return to the normal loop, that's underwhelming
        j       _augment_loop_return        // return to vanilla loop
        lw      s1, 0x0084(s0)              // original line 2
    }

    // @ Description
    // Patch ftCommonGuardUpdateJoints to count the number of joints properly when static parts exist.
    scope fix_ftCommonGuardUpdateJoints_: {
        OS.patch_start(0xC31AC, 0x8014876C)
        j       fix_ftCommonGuardUpdateJoints_
        lw      t3, 0x0000(v1)              // t3 = joint dObj (original line 1)
        _return:
        OS.patch_end()

        // v0 = part id
        // s0 = player struct
        li      t8, Character.static_part.table
        lw      at, 0x0008(s0)              // at = character id
        sll     at, at, 0x3                 // at = offset (id * 8)
        addu    t8, t8, at                  // t8 = static part bitfield address
        addiu   t9, v0, -4                  // t9 = part id, adjusted for upper bitfield
        bltz    t9, _end                    // skip if part id > 0
        sltiu   at, t9, 32                  // at = 1 if part id >32, else at = 0
        bnez    at, _continue               // branch if part id >32
        lw      t5, 0x0000(t8)              // t5 = static part bitfield (upper)

        // if part id is 32 or higher, we'll use the lower bitfield instead
        lw      t5, 0x0004(t8)              // t5 = static part bitfield (lower)
        addiu   t9, t9, -32                 // t9 = part id, adjusted for lower bitfield

        _continue:
        lui     at, 0x8000                  // at = bitmask
        srlv    at, at, t9                  // shift bitmask for part id
        and     t5, t5, at                  // t5 = 0 if part isn't static, else t3 != 0
        bnez    t5, _static                 // branch if static part
        nop

        _end:
        j       _return                     // return
        addiu   v0, v0, 0x0001              // increment part id (original line 2)

        _static:
        j       0x80148780                  // don't increment joint_num for static part
        addiu   v0, v0, 0x0001              // increment part id (original line 2)
    }

    // @ Description
    // Update ftCommonGuardInitJoints to use lbCommonAddDObjAnimJointAll_extended_ and pass the player struct in a3
    scope update_ftCommonGuardInitJoints_: {
        OS.patch_start(0xC3350, 0x80148910)
        j       update_ftCommonGuardInitJoints_
        lw      a2, 0x0B2C(s6)              // original line 1
        _return:
        OS.patch_end()

        jal     lbCommonAddDObjAnimJointAll_extended_ // use extended function, modified original line 2
        or      a3, s6, r0                  // a3 = player struct
        j       _return                     // return
        nop
    }

    // @ Description
    // Patch ftCommonGuardInitJoints to skip animating static parts.
    scope fix_ftCommonGuardInitJoints_: {
        OS.patch_start(0xC3420, 0x801489E0)
        j       fix_ftCommonGuardInitJoints_
        nop
        _return:
        OS.patch_end()

        // s0 = joint dobj
        // s1 = part id
        // s6 = player struct

        li      t8, Character.static_part.table
        lw      at, 0x0008(s6)              // at = character id
        sll     at, at, 0x3                 // at = offset (id * 8)
        addu    t8, t8, at                  // t8 = static part bitfield address
        addiu   t9, s1, -4                  // t9 = part id, adjusted for upper bitfield
        bltz    t9, _end                    // skip if part id > 0
        sltiu   at, t9, 32                  // at = 1 if part id >32, else at = 0
        bnez    at, _continue               // branch if part id >32
        lw      t5, 0x0000(t8)              // t5 = static part bitfield (upper)

        // if part id is 32 or higher, we'll use the lower bitfield instead
        lw      t5, 0x0004(t8)              // t5 = static part bitfield (lower)
        addiu   t9, t9, -32                 // t9 = part id, adjusted for lower bitfield

        _continue:
        lui     at, 0x8000                  // at = bitmask
        srlv    at, at, t9                  // shift bitmask for part id
        and     t5, t5, at                  // t5 = 0 if part isn't static, else t3 != 0
        bnel    t5, r0, _goto_loop_end      // skip animating if static part
        addiu   s1, s1, 0x0001              // increment part id (original line 2)

        _end:
        beqzl   s0, _goto_loop_end          // skip animating if no dobj (original line 1)
        addiu   s1, s1, 0x0001              // increment part id (original line 2)
        j       _return                     // return
        nop

        _goto_loop_end:
        j       0x80148A18                  // jump to end of loop
        nop
    }

    // @ Description
    // Extended version of 0x800C8758 lbCommonAddDObjAnimJointAll
    // a0 = root joint
    // a1 = animation header
    // a2 = animation frame
    // a3 = player struct (new arg)
    scope lbCommonAddDObjAnimJointAll_extended_: {
        addiu   sp, sp,-0x0048              // allocate stack space
        sdc1    f20, 0x0018(sp)
        sw      s3, 0x0038(sp)
        sw      ra, 0x0034(sp)
        sw      s2, 0x0030(sp)
        sw      s1, 0x002C(sp)
        sw      s0, 0x0028(sp)
        sdc1    f22, 0x0020(sp)             // register storage
        mtc1    a2, f20
        lw      t6, 0x0004(a0)
        or      s3, a3, r0                  // s3 = player struct
        or      s1, a1, r0                  // s1 = animation header
        or      s2, a0, r0                  // s2 = root model part
        or      s0, a0, r0                  // s0 = current part
        beqz    a0, _exit_main_loop         // skip loop if current part = NULL
        swc1    f20, 0x0078(t6)
        lui     at, 0x800D
        lwc1    f22, 0x5E7C(at)             // f22 = AOBJ_ANIM_NULL
        _main_loop:
        // first, check for static parts
        // this is based skip_static_parts_, but we don't check for anim flags or allow the static parts to animate
        // maybe this limitation isn't needed and the extra code can be uncommented
        // just not sure if those animation flags get passed properly to a shield pose
        lw      t1, 0x0084(s0)              // ~
        lbu     t2, 0x000D(t1)              // t2 = part id
        li      t8, Character.static_part.table
        lw      at, 0x0008(s3)              // at = character id
        sll     at, at, 0x3                 // at = offset (id * 8)
        addu    t8, t8, at                  // t8 = static part bitfield address
        addiu   t9, t2, -4                  // t9 = part id, adjusted for upper bitfield
        sltiu   at, t9, 32                  // at = 1 if part id >32, else at = 0
        bnez    at, _continue               // branch if part id >32
        lw      t3, 0x0000(t8)              // t3 = static part bitfield (upper)

        // if part id is 32 or higher, we'll use the lower bitfield instead
        lw      t3, 0x0004(t8)              // t3 = static part bitfield (lower)
        addiu   t9, t9, -32                 // t9 = part id, adjusted for lower bitfield

        _continue:
        lui     at, 0x8000                  // at = bitmask
        srlv    at, at, t9                  // shift bitmask for part id
        and     t3, t3, at                  // t3 = 0 if part isn't static, else t3 != 0
        bnez    t3, _static                 // branch if static part
        nop

        _normal:
        // animate normally if not a static part
        b       _original_loop              // continue original loop
        nop

        _static:
        // if we're here, then we've found a static part!
        // we're just going to uh... not animate that

        // // s0 = current part
        // // t2 = part id
        // lw      t8, 0x0198(s3)              // t8 = anim flags
        // addiu   at, r0, 0xFFE0              // at = bitmask
        // and     t8, t8, at                  // t8 = anim flags & mask
        // or      t7, r0, r0                  // t7 = withheld parts table id

        // ////// final loop checks the withheld parts being "enabled" by the anim flags
        // _anim_flag_loop:
        // beqz    t8, _exit_anim_flag_loop    // exit loop if no more withheld parts enabled
        // lui     t1, 0x8000                  // t1 = bitmask

        // and     at, t8, t1                  // at = 0 if withheld part enabled, else t3 != 0
        // beqz    at, _anim_flag_loop_end     // branch if withheld part isn't enabled
        // nop

        // // if we're here, there's a withheld part flag enabled on the animation, so check if it matches
        // lw      t6, 0x09C8(s3)              // t6 = attribute pointer
        // lw      t6, 0x02D0(t6)              // t6 = withheld parts table
        // sll     at, t7, 0x4                 // at = offset (table id * 16)
        // addu    t6, t6, at                  // t6 = entry for this part in withheld parts table
        // lw      t6, 0x0000(t6)              // t6 = withheld part id
        // beq     t6, t2, _animate_static_part // branch if withheld part id matches static part id!
        // nop

        // _anim_flag_loop_end:
        // addiu   t7, t7, 0x0001              // increment withheld parts table id
        // b       _anim_flag_loop             // loop
        // sll     t8, t8, 1                   // shift bitfield by 1 (next part in table)

        // //////// final loop ends here
        // if we made it all the way to here, the current static part doesn't need to be animated
        _exit_anim_flag_loop:
        // since we're skipping this part, go straight to the next one!
        b       _next_part                  // next part
        swc1    f22, 0x0074(s0)             // current_dobj->anim_wait = AOBJ_ANIM_NULL

        // // if we make it here, it means an animation flag is being used to animate this part, which is usually static
        // _animate_static_part:
        // // ...so just continue normally, that's underwhelming

        // now do the original loop
        _original_loop:
        lw      a1, 0x0000(s1)              // a1 = anim track
        beqzl   a1, _skip                   // skip if no anim track
        swc1    f22, 0x0074(s0)             // current_dobj->anim_wait = AOBJ_ANIM_NULL
        mfc1    a2, f20                     // a2 = starting frame
        jal     0x8000BD1C                  // apply animation track
        or      a0, s0, r0                  // a0 = current model part
        b       _next_part
        addiu   s1, s1, 0x0004              // s1 = next animation track
        swc1    f22, 0x0074(s0)             // why is this line here? thanks compiler
        _skip:
        addiu   s1, s1, 0x0004              // s1 = next animation track
        _next_part:
        or      a0, s0, r0                  // a0 = current
        jal     0x800C86E8                  // lbCommonGetTreeDObjNextFromRoot
        or      a1, s2, r0                  // a1 = root model part
        bnez    v0, _main_loop              // loop if next model part != NULL
        or      s0, v0, r0                  // s0 = next model part
        _exit_main_loop:
        lw      ra, 0x0034(sp)
        ldc1    f20, 0x0018(sp)
        ldc1    f22, 0x0020(sp)             // register retrieval
        lw      s0, 0x0028(sp)
        lw      s1, 0x002c(sp)
        lw      s2, 0x0030(sp)
        lw      s3, 0x0038(sp)
        jr      ra                          // return
        addiu   sp, sp, 0x0048              // deallocate stack space
    }
}

} // __STATICPART__