// Pichu.asm

// This file contains shit i stole to make Pichu hurt itself.

scope theselfdamagetest {
    constant IDKMAN(50)
    constant FSMASHFRAME(25)
    constant BTHFRAME(15)
    constant FSENDFRAME(60)
    constant BTHENDFRAME(40)
    constant ZERO(0)



    scope selfdmg_: {
        addiu   sp, sp,-0x0040              // allocate stack space
        sw      ra, 0x0014(sp)              // 0x0014(sp) = ra
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player object
        lw      v0, 0x0084(a0)              // v0 = player struct
        lw      t7, 0x0180(v0)              // t7 = temp variable 2


        lli at, IDKMAN
        beq t7, at, applydmg_    // if variable 2 = IDKMAN do damage
        nop
        bc1fl   end_                        // skip if animation end has not been reached
        nop


        applydmg_:                                                      //apply damage
        lw      a0, 0x0084(a0)              // a0 = fighter struct
        jal     0x800EA248                  // apply damage
        addiu   a1, r0, 1                  // argument 1 = 1 damage to add


        end_:                                                           //end
        lw      ra, 0x0014(sp)              // load ra
        jr      ra
        addiu   sp, sp, 0x0040              // deallocate stack space
    }

    scope FSselfdmg_: {
        addiu   sp, sp,-0x0040              // allocate stack space
        sw      ra, 0x0014(sp)              // 0x0014(sp) = ra
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player object
        lw      v0, 0x0084(a0)              // v0 = player struct
        sw      v0, 0x0050(sp)              // save player struct
        lw      t7, 0x0180(v0)              // t7 = temp variable 2
        lw      t6, 0x0B28(v0)
        addiu   t8, t6, 0x0001                      // add a frame
        sw      t8, 0x0B28(v0)                      // save new frame amount

        lli at, FSENDFRAME
        bge     t8, at, cleanup_             // skip if temp variable 1 = 0
        nop
        lli at, FSMASHFRAME
        beq     t8, at, applydmg_             // skip if temp variable 1 = 0
        nop
        bc1fl   end_                        // skip if animation end has not been reached
        nop

        cleanup_:
        lli at, ZERO
        sw      at, 0x0B28(v0)                      // save new frame amount
        bc1fl   end_


        applydmg_:                                                      //apply damage
        lw      a0, 0x0084(a0)              // a0 = fighter struct
        jal     0x800EA248                  // apply damage
        addiu   a1, r0, 2                  // argument 1 = 2 damage to add


        end_:                                                           //end
        lw      ra, 0x0014(sp)              // load ra
        jr      ra
        addiu   sp, sp, 0x0040              // deallocate stack space
    }

    scope BThselfdmg_: {
        addiu   sp, sp,-0x0040              // allocate stack space
        sw      ra, 0x0014(sp)              // 0x0014(sp) = ra
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player object
        lw      v0, 0x0084(a0)              // v0 = player struct
        sw      v0, 0x0050(sp)              // save player struct
        lw      t7, 0x0180(v0)              // t7 = temp variable 2
        lw      t6, 0x0B28(v0)
        addiu   t8, t6, 0x0001                      // add a frame
        sw      t8, 0x0B28(v0)                      // save new frame amount

        lli at, BTHENDFRAME
        bge     t8, at, cleanup_             // skip if temp variable 1 = 0
        nop
        lli at, BTHFRAME
        beq     t8, at, applydmg_             // skip if temp variable 1 = 0
        nop
        bc1fl   end_                        // skip if animation end has not been reached
        nop

        cleanup_:
        lli at, ZERO
        sw      at, 0x0B28(v0)                      // save new frame amount
        bc1fl   end_


        applydmg_:                                                      //apply damage
        lw      a0, 0x0084(a0)              // a0 = fighter struct
        jal     0x800EA248                  // apply damage
        addiu   a1, r0, 1                  // argument 1 = 1 damage to add


        end_:                                                           //end
        lw      ra, 0x0014(sp)              // load ra
        jr      ra
        addiu   sp, sp, 0x0040              // deallocate stack space
    }

    scope Thunderselfdmg_: {
        addiu   sp, sp,-0x0030              // allocate stack spcae
        sw      s0, 0x0020(sp)              // ~
        sw      ra, 0x0024(sp)              // ~
        sw      a0, 0x0028(sp)              // store s0, ra, a0
        lw      s0, 0x0084(a0)              // s0 = player struct
        lw      t6, 0x0184(s0)              // t6 = temp variable 3
        beqz    t6, _end
        nop
                                                 //apply damage
        lw      a0, 0x0084(a0)              // a0 = fighter struct
        jal     0x800EA248                  // apply damage
        addiu   a1, r0, 5                  // argument 1 = 5 damage to add

        _end:
        lw      s0, 0x0020(sp)              // ~
        lw      ra, 0x0024(sp)              // load s0, ra
        jr      ra                          // return
        addiu   sp, sp, 0x0030              // deallocate stack space
    }

}