// SpidermanSpecial.asm

// This file contains subroutines used by Spider-Man's special moves.

scope SpidermanNSP {

    // floating point constants for physics and fsm
    constant AIR_Y_SPEED(0x4280)            // current setting - float32 64
    constant AIR_Y_SPEED_STALE(0x4200)            // current setting - float32 32
    constant X_SPEED(0x4120)                // current setting - float32 10
    constant X_SPEED_STALE(0x41A0)          // current setting - float32 20
    constant AIR_ACCELERATION(0x3C88)       // current setting - float32 0.0166
    constant AIR_SPEED(0x41B0)              // current setting - float32 22
    // temp variable 3 constants for movement states
    constant BEGIN(0x1)
    constant BEGIN_MOVE(0x2)
    constant MOVE(0x3)

 // @ Description 
    // main subroutine for Wolf's Blaster
    scope main: {
        addiu   sp, sp, -0x0040
        sw      ra, 0x0014(sp)
		swc1    f6, 0x003C(sp)
        swc1    f8, 0x0038(sp)
        sw      a0, 0x0034(sp)
		addu	a2, a0, r0
        lw      v0, 0x0084(a0)                      // loads player struct
        
        or      a3, a0, r0
        lw      t6, 0x017C(v0)
        beql    t6, r0, _idle_transition_check      // this checks moveset variables to see if projectile should be spawned
        lw      ra, 0x0014(sp)
        mtc1    r0, f0
        sw      r0, 0x017C(v0)                      // clears out variable so he only fires one shot
        addiu   a1, sp, 0x0020
        swc1    f0, 0x0020(sp)                      // x origin point
        swc1    f0, 0x0024(sp)                      // y origin point
        swc1    f0, 0x0028(sp)                      // z origin point
        lw      a0, 0x0928(v0)
        sw      a3, 0x0030(sp)
        jal     0x800EDF24                          // generic function used to determine projectile origin point
        sw      v0, 0x002C(sp)
        lw      v0, 0x002C(sp)
        lw      a3, 0x0030(sp)
        sw      r0, 0x001C(sp)
        or      a0, a3, r0
        addiu   a1, sp, 0x0020
        jal     projectile_stage_setting            // this sets the basic features of a projectile
        lw      a2, 0x001C(sp)
		lw      a2, 0x0034(sp)
        lw      ra, 0x0014(sp)
		
		// checks frame counter to see if reached end of the move
        _idle_transition_check:
        mtc1    r0, f6
        lwc1    f8, 0x0078(a2)
        c.le.s  f8, f6
        nop
        bc1fl   _end
        lw      ra, 0x0014(sp)
        lw      a2, 0x0034(sp)
        jal     0x800DEE54
        or      a0, a2, r0
         _end:
		lw      a0, 0x0034(sp)
        lwc1    f6, 0x003C(sp)
        lwc1    f8, 0x0038(sp)
        lw      ra, 0x0014(sp)
        addiu   sp, sp, 0x0040
        jr      ra
        nop

		projectile_stage_setting:
        addiu   sp, sp, -0x0050
        sw      a2, 0x0038(sp)
        lw      t7, 0x0038(sp)
		sw      s0, 0x0018(sp)
        li      s0, _blaster_fireball_struct       // load blaster format address

        
        sw      a1, 0x0034(sp)
        sw      ra, 0x001C(sp)
        lw      t6, 0x0084(a0)
        lw      t0, 0x0024(s0)
        lw      t1, 0x0028(s0)
        li      a1, _blaster_projectile_struct		// load projectile addresses
        lw      a2, 0x0034(sp)
        lui     a3, 0x8000
        sw      t6, 0x002C(sp)
        //sw      t0, 0x0008(a1)        // would revise default pointer, which has another pointer, which is to the hitbox data
        jal     0x801655C8                // This is a generic routine that does much of the work for defining all projectiles
        sw      t1, 0x000C(a1)

        bnez    v0, _projectile_branch
        sw      v0, 0x0028(sp)
        beq     r0, r0, _end_stage_setting
        or      v0, r0, r0
        
        _projectile_branch:
        lw      v1, 0x0084(v0)
        lui     t2, 0x3f80              // load 1(fp) into f2
        addiu   at, r0, 0x0001
        mtc1    r0, f4
        sw      t2, 0x029C(v1)          // save 1(fp) to projectile struct free space
        lw      t3, 0x0000(s0)
        sw      t3, 0x0268(v1)
        //new code here
        lli     t3, Spiderman.FGM.SFX_NSP_HIT               // new hit fgm = NSP_HIT
        sh      t3, 0x0146(v1)          // overwrite hit fgm
        //end new code
   
        OS.copy_segment(0xE3268, 0x2C)   
        lw      t6, 0x002C(sp)
		lwc1    f6, 0x0020(s0)           // load speed (integer)
        lw      v1, 0x0024(sp)
        lw      t7, 0x0044(t6)
        mul.s   f8, f0, f6
        lwc1    f12, 0x0020(sp)
        mtc1    t7, f10
        nop
        cvt.s.w f16, f10
        mul.s   f18, f8, f16
        jal     0x800303F0
        swc1    f18, 0x0020(v1)
        lwc1    f4, 0x0020(s0)
        lw      v1, 0x0024(sp)
        lw      a0, 0x0028(sp)
        mul.s   f6, f0, f4
        swc1    f6, 0x0024(v1)
        lw      t8, 0x0074(a0)
        lwc1    f10, 0x002C(s0)
        lw      t9, 0x0080(t8)
        // This ensures the projectile faces the correct direction
        jal     0x80167FA0
        swc1    f10, 0x0088(t9)
        lw      v0, 0x0028(sp)

        _end_stage_setting:
        lw      ra, 0x001C(sp)
        lw      s0, 0x0018(sp)
        addiu   sp, sp, 0x0050
        jr  	ra
        nop

		// this subroutine seems to have a variety of functions, but definetly deals with the duration of move and result at the end of duration
        blaster_duration:
        addiu   sp, sp, -0x0024
        sw      ra, 0x0014(sp)
        sw      a0, 0x0020(sp)
        swc1    f10, 0x0024(sp)
        lw      a0, 0x0084(a0)
        sw      a0, 0x001C(sp)
        
        _continue:
        addiu   t8, r0, r0          // used to use free space area, but for no apparent reason, affects graphics
        //lw      t8, 0x029C(a0)
        lw      t7, 0x0020(sp)      // t7 = projectile object
        li      t0, _blaster_fireball_struct
        addu    v0, r0, t0
        lw      a1, 0x000C(v0)
        lw      a2, 0x0004(v0)
        lw      t1, 0x0020(sp)
        addiu   t2, r0, r0          // used to use free space area, but for no apparent reason, effects graphics
        lw      v1, 0x0074(t1)
        or      v0, r0, r0
        lwc1    f8, 0x0020(a0)      // load current speed
		lui		at, 0x3F84          // speed multiplier (accel) loaded in at (1.03125)
		mtc1	at, f6              // move speed multiplier to floating point register
		mul.s   f8, f8, f6          // speed multiplied by accel

        lw      at, 0x0004(t0)      // load max speed
        mtc1    at, f6
        lw      at, 0x029C(a0)      // load multiplier that is typically one, unless reflected
        mtc1    at, f10
        mul.s   f6, f6, f10
        c.le.s  f8, f6

        //Sonic USP Start
        lw      t8, 0x0000(t0)      // t8 = initial duration
        addiu   t8, t8, -0x0004     // t8 = initial duration - 4 frames
        // t7 has current count from prior jal
        sltu    t8, t7, t8          // t8 = 1 if after first 4 frames
        //mtc1    r0, f6              // f6 = 0 = no rotation
        lui		at, 0x3E80          // f6 = 0.5 rotation multiplier
        mtc1    at, f6
        beqz    t8, _initial_rotation // if in the first 4 frames, skip normal rotation/gravity
        addiu   a1, r0, r0          // set gravity to 0

        // rest of the duration functionality
        lw      a1, 0x000C(t0)      // load normal gravity

        lw      t1, 0x0020(sp)      // t1 = projectile object
        lw      t2, 0x0084(t1)      // t2 = projectile special struct

        // ensure hitbox is always on in the air
        lli     at, 0x0001          // at = 1 = enable hitbox
        sw      at, 0x0150(t2)      // turn on hitbox

        lw      t3, 0x00FC(t2)      // t3 = 0 if grounded
        bnezl   t3, _initial_rotation // if not grounded, rotate
        lwc1    f6, 0x0014(v0)      // load normal rotation

        _initial_rotation:
        lw      t1, 0x0020(sp)      // t1 = projectile object
        lw      v1, 0x0074(t1)      // v1 = top joint
        lwc1    f4, 0x0030(v1)      // f4 = current rotation value
        add.s   f8, f4, f6          // f8 = new rotation value (rot * 0.5)
        swc1    f8, 0x0030(v1)      // update rotation value
       
        _end_duration:
        lw      ra, 0x0014(sp)
        lwc1    f10, 0x0024(sp)
        addiu   sp, sp, 0x0024
        jr      ra
        nop

        _hitbox_end:
        OS.copy_segment(0xE396C, 0x38)
        // swc1 f4, 0x0148(v0)
        OS.copy_segment(0xE39A8, 0x30)
        
        // this subroutine determines the behavior of the projectile upon reflection
        blaster_reflection:
        addiu   sp, sp, -0x0018
        sw      ra, 0x0014(sp)
        sw      a0, 0x0018(sp)
        lw      a0, 0x0084(a0)      // loads active projectile struct
        lw      t0, 0x0008(v0)
        addiu   t7, r0, Character.id.SPIDERMAN
        bnel    t0, t7, _standard
        lui     t7, 0x3F80          // load normal reflect multiplier if not wolf and thereby top speed of wolf projectile will not increase
        li      t7, 0x3FC90FDB      // load reflect multiplier
        _standard:
        mtc1    t7, f4              // move reflect multiplier to floating point
        sw      t7, 0x029C(a0)      // save multiplier to free space to increase max speed
        lw      t7, 0x0008(a0)
        li      t0, _blaster_fireball_struct // load fireball struct to pull parameters
        lw      t0, 0x0000(t0)      // loads max duration from fireball struct
        sw      t0, 0x0268(a0)      // save max duration to active projectile struct current remaining duration
        lw      a1, 0x0084(t7)      // loads reflective character's struct

        // Before determining new direction, multiply speed.
        lw      t6, 0x0044(a1)      // loads player direction 1 or -1 in fp
        lwc1    f0, 0x0020(a0)      // loads projectile velocity
        mul.s   f0, f0, f4          // multiply current speed by reflection speed multiplier
        nop
        swc1    f0, 0x0020(a0)      // save new speed
        nop
        jal     0x801680EC          // go to the default subroutine that determines direction
        nop

        // old routine for reference, was based on 0x801680EC
        // lw      t6, 0x0044(a1)      // loads direction 1 or -1 in fp
        // lwc1    f0, 0x0020(a0)      // loads velocity
        // mul.s   f0, f0, f4          // multiply current speed by reflection speed multiplier (not original logic)
        // mtc1    r0, f10             // move 0 to f10
        // mtc1    t6, f4              // place direction in f4
        // nop
        // cvt.s.w f6, f4              // cvt to sw floating point
        // mul.s   f8, f0, f6          // change direction of projectile to the opposite direction via multiplication
        // //  lw      t6, 0x0004(t0)      // load max speed
        // //  mtc1    t6, f6              // move max speed to f6
        // c.lt.s  f8, f10             // current velocity compared to 0 (less than or equal to)
        // nop
        // bc1f    _branch              // jump if velocity is greater than 0
        // nop
        // neg.s   f16, f0
        // swc1    f16, 0x0020(a0)     // save velocity
        
        _branch:
        lw      a0, 0x0018(sp)
        lw      v0, 0x0084(a0)      // load active projectile struct
        mtc1    r0, f6              // move 0 to f6
        lwc1    f4, 0x0020(v0)      // load current velocity of projectile
        c.le.s  f6, f4              // compare 0 to current velocity to see if now traveling leftward
        nop
        bc1f    _left               // jump if 0 is greater than velocity, this means the projectile is traveling leftward
        nop
        li        at, 0x3FC90FDB
        mtc1      at, f8    
        lw      t6, 0x0074(a0)
        j       _end_reflect
        swc1    f8, 0x0034(t6)
        _left:
        li        at, 0xBFC90FDB
        mtc1      at, f10
        lw      t7, 0x0074(a0)
        swc1    f10, 0x0034(t7)
        _end_reflect:
        lw      ra, 0x0014(sp)
        addiu   sp, sp, 0x0018
        or      v0, r0, r0
        jr      ra
        nop
        
		
		_blaster_projectile_struct:
        dw 0x00000000                   // this has some sort of bit flag to tell it to use secondary type display list?
		dw 0x00000000
        dw Character.SPIDERMAN_file_6_ptr    // pointer to file
        dw 0x00000000                   // 00000000
        dw 0x12470000                   // rendering routine?
        dw blaster_duration             // duration (default 0x80168540) (samus 0x80168F98)
        dw 0x80175914                   // collision (0x801685F0 - Mario) (0x80169108 - Samus)
        dw 0x80175958    		        // after_effect 0x801691FC, this one is used when grenade connects with player
        dw 0x80175958                   // after_effect 0x801691FC, used when touched by player when object is still, by setting to null, nothing happens
        dw 0x8016DD2C                   // determines behavior when projectile bounces off shield, this uses Master Hand's projectile coding to determine correct angle of graphic (0x8016898C Fox)
        dw 0x80175958                   // after_effect                // rocket_after_effect 0x801691FC
        dw blaster_reflection           // OS.copy_segment(0x1038FC, 0x04)            // this determines reflect behavior (default 0x80168748)
        dw 0x80175958                   // This function is run when the projectile is used on ness while using psi magnet
        OS.copy_segment(0x103904, 0x0C) // empty 

		
		_blaster_fireball_struct:
        dw 100                          // 0x0000 - duration (int)
        float32 45                      // 0x0004 - max speed (200)
        float32 45                      // 0x0008 - min speed (22)
        float32 0                       // 0x000C - gravity
        float32 0                       // 0x0010 - bounce multiplier
        float32 0.05                    // 0x0014 - rotation angle
        float32 0                       // 0x0018 - initial angle (ground)
        float32 345                     // 0x001C   initial angle (air)
        float32 45                      // 0x0020   initial speed
        dw Character.SPIDERMAN_file_6_ptr     // 0x0024   projectile data pointer
        dw 0                            // 0x0028   unknown (default 0)
        float32 0                       // 0x002C   palette index (0 = mario, 1 = luigi)
        OS.copy_segment(0x1038A0, 0x30)
		}

    // @ Description
    // Subroutine which handles movement for Spider-Man's neutral special.
    // Uses the moveset data command 5C0000XX (orignally identified as "apply throw?" by toomai)
    // This command's purpose appears to be setting a temporary variable in the player struct.
    // The most common use of this variable is to determine when a throw should be applied.
    // Variable values used by this subroutine:
    // 0x2 = begin movement
    // 0x3 = movement
    // 0x4 = ending
    scope physics_: {
        // s0 = player struct
        // s1 = attributes pointer
        // 0x184 in player struct = temp variable 3
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      s0, 0x0014(sp)              // ~
        sw      s1, 0x0018(sp)              // store ra, s0, s1
        lw      s0, 0x0084(a0)              // s0 = player struct

        _aerial:
        OS.copy_segment(0x548F0, 0x40)      // copy from original air physics subroutine
        bnez    v0, _check_begin            // modified original branch
        nop
        li      t8, 0x800D8FA8              // t8 = subroutine which disallows air control
        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        ori     t1, r0, MOVE                // t1 = MOVE
        bne     t0, t1, _apply_air_physics  // branch if temp variable 3 != MOVE
        nop
        li      t8, air_control_             // t8 = air_control_

        _apply_air_physics:
        or      a0, s0, r0                  // a0 = player struct
        jalr    t8                          // air control subroutine
        or      a1, s1, r0                  // a1 = attributes pointer
        or      a0, s0, r0                  // a0 = player struct
        jal     0x800D9074                  // air friction subroutine?
        or      a1, s1, r0                  // a1 = attributes pointer

        _check_begin:
        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        ori     t1, r0, BEGIN               // t1 = BEGIN
        bne     t0, t1, _check_begin_move   // skip if temp variable 3 != BEGIN
        // reset fall speed
        lbu     v1, 0x018D(s0)              // v1 = fast fall flag
        ori     t6, r0, 0x0007              // t6 = bitmask (01111111)
        and     v1, v1, t6                  // ~
        sb      v1, 0x018D(s0)              // disable fast fall flag
        // slow x movement
        lwc1    f0, 0x0048(s0)              // f0 = current x velocity
        lui     t0, 0x3F60                  // ~
        mtc1    t0, f2                      // f2 = 0.875
        mul.s   f0, f0, f2                  // f0 = x velocity * 0.875
        swc1    f0, 0x0048(s0)              // x velocity = (x velocity * 0.875)
        // freeze y position
        sw      r0, 0x004C(s0)              // y velocity = 0
        

        _check_begin_move:
        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        ori     t1, r0, BEGIN_MOVE          // t1 = BEGIN_MOVE
        bne     t0, t1, _end                // skip if temp variable 3 != BEGIN_MOVE
        nop

        // initialize x/y velocity
        // If 0x0ADE = 0 (which it should be on the first use), it'll overwrite the current value and use the proper aerial speed. 
        // If 0x0ADE = 1, it'll skip that check and use the STALE value.
        //lui     t1, AIR_Y_SPEED_STALE       // t1 = AIR_Y_SPEED_STALE
        //lui     t0, X_SPEED_STALE           // t0 = X_SPEED_STALE
        //lbu     at, 0x0ADE(s0)              // at = temp flag, used as NSP's ammo
        //bnez    at, _apply_velocity         // skip if temp flag != 0
        //lli     at, OS.TRUE                 // ~
        //sb      at, 0x0ADE(s0)              // temp flag = TRUE
        lui     t1, AIR_Y_SPEED             // t1 = AIR_Y_SPEED
        lui     t0, X_SPEED                 // t0 = X_SPEED

        _apply_velocity:
        mtc1    t0, f2                      // f2 = X_SPEED
        lwc1    f0, 0x0044(s0)              // ~
        cvt.s.w f0, f0                      // f0 = direction
        mul.s   f2, f0, f2                  // f2 = x velocity * direction
        ori     t0, r0, MOVE                // t0 = MOVE
        sw      t0, 0x0184(s0)              // temp variable 3 = MOVE
        swc1    f2, 0x0048(s0)              // store x velocity
        sw      t1, 0x004C(s0)              // store y velocity

        _end:
        lw      ra, 0x001C(sp)              // ~
        lw      s0, 0x0014(sp)              // ~
        lw      s1, 0x0018(sp)              // loar ra, s0, s1
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles Spider-Man's horizontal control for neutral special.
    scope air_control_: {
        addiu   sp, sp,-0x0028              // allocate stack space
        sw      a1, 0x001C(sp)              // ~
        sw      ra, 0x0014(sp)              // ~
        sw      t0, 0x0020(sp)              // ~
        sw      t1, 0x0024(sp)              // store a1, ra, t0, t1
        addiu   a1, r0, 0x0008              // a1 = 0x8 (original line)
        lw      t6, 0x001C(sp)              // t6 = attribute pointer
        // load an immediate value into a2 instead of the air acceleration from the attributes
        lui     a2, AIR_ACCELERATION        // a2 = AIR_ACCELERATION
        lui     a3, AIR_SPEED               // a3 = AIR_SPEED
        jal     0x800D8FC8                  // air drift subroutine?
        nop
        lw      ra, 0x0014(sp)              // ~
        lw      t0, 0x0020(sp)              // ~
        lw      t1, 0x0024(sp)              // load ra, t0, t1
        addiu   sp, sp, 0x0028              // deallocate stack space
        jr      ra                          // return
        nop
    }
   // @ Description
   // Subroutine which handles air collision for neutral special actions
    scope air_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, air_to_ground_          // a1(transition subroutine) = air_to_ground_
        jal     0x800DE6E4                  // common air collision subroutine (transition on landing, no ledge grab)
        nop 
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }
    // @ Description
    // Subroutine which handles ground to air transition for neutral special actions
    scope air_to_ground_: {
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // store ra
        sw      a0, 0x0038(sp)              // 0x0038(sp) = player object
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800DEE98                  // set grounded state
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player struct
        lw      v0, 0x0034(sp)              // v0 = player struct
        lw      a0, 0x0038(sp)              // a0 = player object
        
        //lw      a2, 0x0008(v0)              // load character ID
        //lli     a1, Character.id.KIRBY      // a1 = id.KIRBY
        //beql    a1, a2, _change_action      // if Kirby, load alternate action ID
        //lli     a1, Kirby.Action.SPIDERMAN_NSP_Ground
        //lli     a1, Character.id.JKIRBY     // a1 = id.JKIRBY
        //beql    a1, a2, _change_action      // if J Kirby, load alternate action ID
        //lli     a1, Kirby.Action.SPIDERMAN_NSP_Ground
        
        
        addiu   a1, r0, 0x00E4              // a1 = equivalent ground action for current air action
        _change_action:
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lli     t6, 0x0001                  // ~
        jal     0x800E6F24                  // change action
        sw      t6, 0x0010(sp)              // argument 4 = 1 (continue hitbox)
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop
    }	
}

scope SpidermanUSP {
    constant END_X_SPEED(0x41C0)            // float32 24
    constant END_Y_SPEED(0x42C0)            // float32 96
    constant COLLISION_SFX(0x13)            // grab fgm
    constant THROW_GRAVITY(0x4000)          // current setting - float32 2

    constant AIR_ACCELERATION(0x3C88)       // current setting - float32 0.0166
    constant AIR_SPEED(0x41B0)              // current setting - float32 22
    constant AIR_Y_SPEED(0x4200)            // current setting - float32 32
    constant AIR_X_SPEED(0x4120)            // current setting - float32 10
    constant BEGIN(0x1)
    constant BEGIN_MOVE(0x2)
    constant MOVE(0x3)

    // @ Description
    // Initial subroutine for DSPGround.
    scope ground_initial_: {
        addiu   sp, sp,-0x0028              // allocate stack space
        sw      ra, 0x0014(sp)              // ~
        sw      a0, 0x0018(sp)              // store ra, a0
        lli     a1, Spiderman.Action.USPGround // a1(action id) = DSPGround
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        lw      a0, 0x0018(sp)              // a0 = player object
        li      a1, ground_pull_initial_       // a1 = air_pull_initial_
        jal     0x8015E310                  // command grab setup (yoshi)
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0018(sp)              // a0 = player object
        lw      a0, 0x0018(sp)              // ~
        lw      a0, 0x0084(a0)              // ~
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        sw      r0, 0x0184(a0)              // temp variable 3 = 0
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0028              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Initial subroutine for DSPAir.
    scope air_initial_: {
        addiu   sp, sp,-0x0028              // allocate stack space
        sw      ra, 0x0014(sp)              // ~
        sw      a0, 0x0018(sp)              // store ra, a0
        sw      r0, 0x0010(sp)              // argument 4 = 0

        lw      a1, 0x0084(a0)              // a1 = player struct
        lbu     at, 0x0ADD(a1)              // at = temp flag, used as USP's ammo
        bnez    at, _end                    // skip if temp flag != 0

        lli     a1, Spiderman.Action.USPAir    // a1(action id) = DSPAir
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        lw      a0, 0x0018(sp)              // a0 = player object
        li      a1, air_pull_initial_       // a1 = air_pull_initial_
        jal     0x8015E310                  // command grab setup (yoshi)
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0018(sp)              // a0 = player object
        lw      a0, 0x0018(sp)              // ~
        lw      a0, 0x0084(a0)              // ~
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        //ori     v1, r0, 0x0001              // ~
        sw      r0, 0x0184(a0)              // temp variable 3 = 0
        // reset fall speed
        lbu     v1, 0x018D(a0)              // v1 = fast fall flag
        ori     t6, r0, 0x0007              // t6 = bitmask (01111111)
        and     v1, v1, t6                  // ~
        sb      v1, 0x018D(a0)              // disable fast fall flag
        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0028              // deallocate stack space
        jr      ra                          // return
        nop
    }
    
    // @ Description
    // Initial subroutine for DSPGroundPull.
    scope ground_pull_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lw      v1, 0x0084(a0)              // v1 = player struct
        lli     a1, Spiderman.Action.USPGroundPull // a1(action id) = DSPGroundPull
        or      a2, r0, r0                  // a2(starting frame) = 0
        lwc1    f2, 0x017C(v1)              // ~
        cvt.s.w f2, f2                      // ~
        mfc1    a2, f2                      // a2(starting frame) = temp variable 2
        lli     t6, 0x0002                  // ~
        sw      t6, 0x0010(sp)              // argument 4 = 0x0002
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        jal     grab_pull_setup_            // additional command grab setup
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        sw      r0, 0x0184(a0)              // temp variable 3 = 0
        FGM.play(COLLISION_SFX)             // play collision sfx
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Initial subroutine for DSPAirPull.
    scope air_pull_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lw      v1, 0x0084(a0)              // v1 = player struct
        lli     a1, Spiderman.Action.USPAirPull // a1(action id) = DSPAirPull
        lwc1    f2, 0x017C(v1)              // ~
        cvt.s.w f2, f2                      // ~
        mfc1    a2, f2                      // a2(starting frame) = temp variable 2
        lli     t6, 0x0002                  // ~
        sw      t6, 0x0010(sp)              // argument 4 = 0x0002
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        jal     grab_pull_setup_            // additional command grab setup
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        sw      r0, 0x0184(a0)              // temp variable 3 = 0
        sw      r0, 0x0048(a0)              // x velocity = 0
        sw      r0, 0x004C(a0)              // y velocity = 0
        swc1    f4, 0x0048(a0)              // store updated x velocity
        FGM.play(COLLISION_SFX)             // play collision sfx
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Initial subroutine for DSPAirWallPull.
    scope air_wall_pull_initial_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lw      v1, 0x0084(a0)              // v1 = player struct
        lli     a1, Spiderman.Action.USPAirWallPull // a1(action id) = DSPAirWallPull
        lwc1    f2, 0x017C(v1)              // ~
        cvt.s.w f2, f2                      // ~
        mfc1    a2, f2                      // a2(starting frame) = temp variable 2
        lli     t6, 0x0002                  // ~
        sw      t6, 0x0010(sp)              // argument 4 = 0x0002
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        sw      r0, 0x0184(a0)              // temp variable 3 = 0
        sw      r0, 0x0048(a0)              // x velocity = 0
        sw      r0, 0x004C(a0)              // y velocity = 0
        swc1    f4, 0x0048(a0)              // store updated x velocity
        FGM.play(COLLISION_SFX)             // play collision sfx
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Initial subroutine for DSPAAttack.
    scope attack_ground_initial_: {
        addiu   sp, sp,-0x0028              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
		sw      a0, 0x0018(sp)              // 0x0018(a0) = player object

        lw      v0, 0x0084(a0)              // v0 = player struct
        lli     at, 0x0001                  // ~
        sw      at, 0x014C(v0)              // kinetic state = airborne
        lli     a1, Spiderman.Action.USPGAttack // a1(action id) = DSPGAttack
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0018(sp)              // a0 = player object
        lw      a0, 0x0018(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x0048(a0)              // x velocity = 0
        sw      r0, 0x004C(a0)              // y velocity = 0
        lw      ra, 0x0014(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0028              // deallocate stack space
    }

    // @ Description
    // Initial subroutine for DSPAAttack.
    // DISABLED: Transition to Idle instead if B is not held
    scope attack_air_initial_: {
        addiu   sp, sp,-0x0028              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        // lw      v0, 0x0084(a0)              // v0 = player struct
        // lh      t6, 0x01BC(v0)              // t6 = buttons_held
        // andi    t6, t6, Joypad.B            // t6 = 0x4000 if (B_HELD); else t6 = 0
        // beqz    t6, _idle                   // branch if (!B_HELD)
		sw      a0, 0x0018(sp)              // 0x0018(a0) = player object

        lw      v0, 0x0084(a0)              // v0 = player struct
        lli     at, 0x0001                  // ~
        sw      at, 0x014C(v0)              // kinetic state = aerial
        
        // Reset Jumps
        lli     t6, 0x0001                  // t6 = 1 jump
        sb      t6, 0x0148(v0)              // jumps used = 1
        lli     at, OS.TRUE                 // ~
        sb      at, 0x0ADD(v0)              // temp flag = TRUE

        lli     a1, Spiderman.Action.USPAAttack // a1(action id) = DSPAAttack
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0018(sp)              // a0 = player object
        lw      a0, 0x0018(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x0048(a0)              // x velocity = 0
        sw      r0, 0x004C(a0)              // y velocity = 0
        lw      ra, 0x0014(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0028              // deallocate stack space
    }

    // @ Description
    // Initial subroutine for DSPEnd.
    scope end_initial_: {
        addiu   sp, sp,-0x0028              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        sw      a0, 0x0018(sp)              // 0x0018(a0) = player object
        lw      v0, 0x0084(a0)              // v0 = player struct
        lli     at, 0x0001                  // ~
        sw      at, 0x014C(v0)              // kinetic state = aerial

        // Reset Jumps
        lli     t6, 0x0001                  // t6 = 1 jump
        sb      t6, 0x0148(v0)              // jumps used = 1
        lli     at, OS.TRUE                 // ~
        sb      at, 0x0ADD(v0)              // temp flag = TRUE

        lli     a1, Spiderman.Action.USPEnd    // a1(action id) = DSPEnd
        or      a2, r0, r0                  // a2(starting frame) = 0
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        jal     0x800E6F24                  // change action
        sw      r0, 0x0010(sp)              // argument 4 = 0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0018(sp)              // a0 = player object
        lw      a0, 0x0018(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        lui     at, END_X_SPEED             // ~
        mtc1    at, f2                      // f2 = END_X_SPEED
        lwc1    f4, 0x0044(a0)              // ~
        cvt.s.w f4, f4                      // f4 = DIRECTION
        mul.s   f2, f2, f4                  // f2 = END_X_SPEED * DIRECTION
        lui     at, END_Y_SPEED             // ~
        sw      at, 0x004C(a0)              // y velocity = END_Y_SPEED
        swc1    f2, 0x0048(a0)              // x velocity = END_X_SPEED * DIRECTION
        lw      ra, 0x0014(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0028              // deallocate stack space
    }

    // @ Description
    // Subroutine which helps set up the command grab for Spiderman.
    scope grab_pull_setup_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        lli     a1, 0x003F                  // a1 = bitflags?
        jal     0x800E8098                  // sets the byte at 0x193 in the player struct to the value in a1
        lw      a0, 0x0084(a0)              // a0 = player struct
        lw      t6, 0x0830(a0)              // ~
        sw      t6, 0x0840(a0)              // update captured player?
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Main function for USPGround and USPAir
    scope main_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra

        lw      t5, 0x0084(a0)              // t5 = player struct
        lw      t6, 0x017C(t5)              // t6 = starting frame (temp variable 2)
        beqz    t6, _check_idle             // skip if starting frame = 0
        addiu   t6, t6,-0x0001              // t6 = decrement starting frame
        sw      t6, 0x017C(t5)              // store updated starting frame

        _check_idle:
        // checks the current animation frame to see if we've reached end of the animation
        mtc1    r0, f6                      // ~
        lwc1    f8, 0x0078(a0)              // ~
        c.le.s  f8, f6                      // ~
        nop
        bc1fl   _end                        // skip if animation end has not been reached
        nop
        jal     0x800DEE54                  // transition to idle
        nop

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Main function for DSPGroundPull and DSPAirPull.
    // Based on 0x8014A0C0, which is the main function for throws.

    scope ground_pull_main_: {
        // Copy the first 67 lines of subroutine 0x8014A0C0
        OS.copy_segment(0xC4B00, 0x10C)

        jal     attack_ground_initial_             // transition to DSPAttack
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      ra, 0x001C(sp)              // load ra

        _end:
        lw      s0, 0x0018(sp)              // load s0
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    scope air_pull_main_: {
        // Copy the first 67 lines of subroutine 0x8014A0C0
        OS.copy_segment(0xC4B00, 0x10C)

        jal     attack_air_initial_             // transition to DSPAttack
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      ra, 0x001C(sp)              // load ra

        _end:
        lw      s0, 0x0018(sp)              // load s0
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Main function for DSPGroundWallPull and DSPAirWallPull
    scope wall_pull_main_: {
        addiu   sp, sp,-0x0028              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra

        lw      v0, 0x0084(a0)              // v0 = player struct
        sw      v0, 0x0018(sp)              // 0x0018(sp) = player struct

        _check_idle:
        // checks the current animation frame to see if we've reached end of the animation
        mtc1    r0, f6                      // ~
        lwc1    f8, 0x0078(a0)              // ~
        c.le.s  f8, f6                      // ~
        nop
        bc1fl   _end                        // skip if animation end has not been reached
        nop
        jal     end_initial_                // transition to DSPEnd
        nop

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0028              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Physics subroutine for NSPAirThrow.
    // Disallows player control until temp variable 1 is set.
    scope throw_air_physics_: {
        addiu   sp, sp,-0x0040              // allocate stack space
        sw      ra, 0x0014(sp)              // ~
        sw      a0, 0x0018(sp)              // store ra, a0
        lw      s0, 0x0084(a0)              // s0 = player struct
        lw      t6, 0x0180(s0)              // t6 = temp variable 1
        beqz    t6, _end                    // skip if temp variable 1 = 0
        nop

        _end_move:
        jal     air_throw_move_physics_     // custom physics subroutine
        nop

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0040              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Aerial movement subroutine for NSPAirThrow
    // Modified version of subroutine 0x800D90E0.
    scope air_throw_move_physics_: {
        // Copy the first 8 lines of subroutine 0x800D90E0
        OS.copy_segment(0x548E0, 0x20)

        // Skip 7 lines (fast fall branch logic)

        // jal 0x800D8E50                   // ~
        // or a1, s1, r0                    // original 2 lines call gravity subroutine
        lui     a1, THROW_GRAVITY           // a1 = THROW_GRAVITY
        jal     0x800D8D68                  // apply gravity/fall speed
        lw      a2, 0x005C(s1)              // a2 = max fall speed

        // Copy the last 15 lines of subroutine 0x800D90E0
        OS.copy_segment(0x54924, 0x3C)
    }

    // @ Description
    // Subroutine which allows a direction change for Spiderman's up special.
    // Uses the moveset data command 540000XX
    // This command's purpose appears to be setting a temporary variable in the player struct.
    // Variable values used by this subroutine:
    // 0x2 = change direction
    scope change_direction_: {
        // 0x180 in player struct = temp variable 2
        lw      a1, 0x0084(a0)              // a1 = player struct
        addiu   sp, sp,-0x0010              // allocate stack space
        sw      t0, 0x0004(sp)              // ~
        sw      t1, 0x0008(sp)              // ~
        sw      ra, 0x000C(sp)              // store t0, t1, ra
        lw      t0, 0x0180(a1)              // t0 = temp variable 1
        ori     t1, r0, 0x0001              // t1 = 0x2
        bne     t1, t0, _end                // skip if temp variable 2 != 1
        nop
        jal     0x80160370                  // turn subroutine (copied from captain falcon)
        nop

        _end:
        lw      t0, 0x0004(sp)              // ~
        lw      t1, 0x0008(sp)              // ~
        lw      ra, 0x000C(sp)              // load t0, t1, ra
        addiu   sp, sp, 0x0010              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles movement for Spider-Man's up special.
    // Uses the moveset data command 5C0000XX (orignally identified as "apply throw?" by toomai)
    // This command's purpose appears to be setting a temporary variable in the player struct.
    // The most common use of this variable is to determine when a throw should be applied.
    // Variable values used by this subroutine:
    // 0x2 = begin movement
    // 0x3 = movement
    // 0x4 = ending
    scope air_physics_: {
        // s0 = player struct
        // s1 = attributes pointer
        // 0x184 in player struct = temp variable 3
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      s0, 0x0014(sp)              // ~
        sw      s1, 0x0018(sp)              // store ra, s0, s1
        lw      s0, 0x0084(a0)              // s0 = player struct

        _aerial:
        OS.copy_segment(0x548F0, 0x40)      // copy from original air physics subroutine
        bnez    v0, _check_begin            // modified original branch
        nop
        li      t8, 0x800D8FA8              // t8 = subroutine which disallows air control
        lw      t0, 0x0184(s0)              // t0 = temp variable 3
        ori     t1, r0, MOVE                // t1 = MOVE
        bne     t0, t1, _apply_air_physics  // branch if temp variable 3 != MOVE
        nop
        li      t8, air_control_             // t8 = air_control_

        _apply_air_physics:
        or      a0, s0, r0                  // a0 = player struct
        jalr    t8                          // air control subroutine
        or      a1, s1, r0                  // a1 = attributes pointer
        or      a0, s0, r0                  // a0 = player struct
        jal     0x800D9074                  // air friction subroutine?
        or      a1, s1, r0                  // a1 = attributes pointer

        _check_begin:
        lw      t0, 0x0184(s0)              // t0 = temp variable 1
        ori     t1, r0, BEGIN               // t1 = BEGIN
        bne     t0, t1, _check_begin_move   // skip if temp variable 1 != BEGIN
        // reset fall speed
        lbu     v1, 0x018D(s0)              // v1 = fast fall flag
        ori     t6, r0, 0x0007              // t6 = bitmask (01111111)
        and     v1, v1, t6                  // ~
        sb      v1, 0x018D(s0)              // disable fast fall flag
        // slow x movement
        lwc1    f0, 0x0048(s0)              // f0 = current x velocity
        lui     t0, 0x3F60                  // ~
        mtc1    t0, f2                      // f2 = 0.875
        mul.s   f0, f0, f2                  // f0 = x velocity * 0.875
        swc1    f0, 0x0048(s0)              // x velocity = (x velocity * 0.875)
        // freeze y position
        sw      r0, 0x004C(s0)              // y velocity = 0
        

        _check_begin_move:
        lw      t0, 0x0184(s0)              // t0 = temp variable 1
        ori     t1, r0, BEGIN_MOVE          // t1 = BEGIN_MOVE
        bne     t0, t1, _end                // skip if temp variable 1 != BEGIN_MOVE
        nop

        _apply_velocity:
        lui     t1, AIR_Y_SPEED                 // t1 = AIR_Y_SPEED
        lui     t0, AIR_X_SPEED                 // t0 = AIR_X_SPEED
        mtc1    t0, f2                      // f2 = AIR_X_SPEED
        lwc1    f0, 0x0044(s0)              // ~
        cvt.s.w f0, f0                      // f0 = direction
        mul.s   f2, f0, f2                  // f2 = x velocity * direction
        ori     t0, r0, MOVE                // t0 = MOVE
        sw      t0, 0x0184(s0)              // temp variable 3 = MOVE
        swc1    f2, 0x0048(s0)              // store x velocity
        sw      t1, 0x004C(s0)              // store y velocity

        _end:
        lw      ra, 0x001C(sp)              // ~
        lw      s0, 0x0014(sp)              // ~
        lw      s1, 0x0018(sp)              // loar ra, s0, s1
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles Spider-Man's horizontal control for up special.
    scope air_control_: {
        addiu   sp, sp,-0x0028              // allocate stack space
        sw      a1, 0x001C(sp)              // ~
        sw      ra, 0x0014(sp)              // ~
        sw      t0, 0x0020(sp)              // ~
        sw      t1, 0x0024(sp)              // store a1, ra, t0, t1
        addiu   a1, r0, 0x0008              // a1 = 0x8 (original line)
        lw      t6, 0x001C(sp)              // t6 = attribute pointer
        // load an immediate value into a2 instead of the air acceleration from the attributes
        lui     a2, AIR_ACCELERATION        // a2 = AIR_ACCELERATION
        lui     a3, AIR_SPEED               // a3 = AIR_SPEED
        jal     0x800D8FC8                  // air drift subroutine?
        nop
        lw      ra, 0x0014(sp)              // ~
        lw      t0, 0x0020(sp)              // ~
        lw      t1, 0x0024(sp)              // load ra, t0, t1
        addiu   sp, sp, 0x0028              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Collision subroutine for DSPGround.
    scope ground_collision_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      v0, 0x0084(a0)              // v0 = player struct
        lw      at, 0x0184(v0)              // at = temp variable 3
        beqz    at, _check_collision        // branch if temp variable 3 is not set
        sw      a0, 0x0018(sp)              // 0x0018(sp) = player object

        // if temp variable 3 is set, check for chain collisions
        jal     chain_collision_            // run collision for chain
        nop

        beqz    v0, _check_collision        // branch if no collision detected
        lw      a0, 0x0018(sp)              // a0 = player object

        lw      v1, 0x0084(a0)              // v1 = player struct
        lw      at, 0x0044(v1)              // at = DIRECTION
        bgezl   at, _wall_chain_collision   // branch if direction = right
        andi    v0, v0, 0x0001              // a1 = collision result & left wall mask
        andi    v0, v0, 0x0002              // a1 = collision result & right wall mask

        _wall_chain_collision:
        beqz    v0, _check_collision        // branch if collision result is not valid for direction
        nop

        // if we're here, then the chain is colliding with a wall in front of Spiderman, so transition to DSPGroundWallPull
        jal     air_wall_pull_initial_   // transition to DSPGroundWallPull
        lw      a0, 0x0018(sp)              // a0 = player object
        b       _end                        // branch to end
        nop

        _check_collision:
        li      a1, ground_to_air_          // a1(transition subroutine) = ground_to_air_
        jal     0x800DDDDC                  // common ground collision subroutine (transition on no floor, slide-off)
        lw      a0, 0x0018(sp)              // a0 = player object

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Collision subroutine for DSPAir.
    scope air_collision_: {
       addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        lw      v0, 0x0084(a0)              // v0 = player struct
        lw      at, 0x0184(v0)              // at = temp variable 3
        beqz    at, _check_collision        // branch if temp variable 3 is not set
        sw      a0, 0x0018(sp)              // 0x0018(sp) = player object

        // if temp variable 3 is set, check for chain collisions
        jal     chain_collision_            // run collision for chain
        nop

        beqz    v0, _check_collision        // branch if no collision detected
        lw      a0, 0x0018(sp)              // a0 = player object

        lw      v1, 0x0084(a0)              // v1 = player struct
        lw      at, 0x0044(v1)              // at = DIRECTION
        bgezl   at, _wall_chain_collision   // branch if direction = right
        andi    v0, v0, 0x0001              // a1 = collision result & left wall mask
        andi    v0, v0, 0x0002              // a1 = collision result & right wall mask

        _wall_chain_collision:
        beqz    v0, _check_collision        // branch if collision result is not valid for direction
        nop

        // if we're here, then the chain is colliding with a wall in front of Spiderman, so transition to DSPAirWallPull
        jal     air_wall_pull_initial_      // transition to DSPAirWallPull
        lw      a0, 0x0018(sp)              // a0 = player object
        b       _end                        // branch to end
        nop

        _check_collision:
        li      a1, air_to_ground_          // a1(transition subroutine) = air_to_ground_
        jal     0x800DE6E4                  // common air collision subroutine (transition on landing, no ledge grab)
        lw      a0, 0x0018(sp)              // a0 = player object

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles the transition from DSPGround to DSPAir.
    scope ground_to_air_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        jal     0x800DEEC8                  // set aerial state
        lw      a0, 0x0084(a0)              // a0 = player struct
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a1, 0x0084(a0)              // ~
        lw      a1, 0x0024(a1)              // ~
        addiu   a1, r0, Spiderman.Action.USPAir              // a1 = equivalent air action for current ground action (id + 4)
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lli     t6, 0x0003                  // ~
        sw      t6, 0x0010(sp)              // argument 4 = 0x0003
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lw      a0, 0x0020(sp)              // a0 = player object
        li      a1, air_pull_initial_       // a1 = air_pull_initial_
        jal     0x8015E310                  // command grab setup (yoshi)
        lw      a0, 0x0084(a0)              // a0 = player struct
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles the transition from DSPAir to DSPGround.
    scope air_to_ground_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        jal     0x800DEE98                  // set grounded state
        lw      a0, 0x0084(a0)              // a0 = player struct
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a1, 0x0084(a0)              // ~
        lw      a1, 0x0024(a1)              // ~
        addiu   a1, r0, Spiderman.Action.USPGround              // a1 = equivalent ground action for current air action
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lli     t6, 0x0003                  // ~
        sw      t6, 0x0010(sp)              // argument 4 = 0x0003
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lw      a0, 0x0020(sp)              // a0 = player object
        li      a1, air_pull_initial_       // a1 = air_pull_initial_
        jal     0x8015E310                  // command grab setup (yoshi)
        lw      a0, 0x0084(a0)              // a0 = player struct
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Collision subroutine for DSPGround actions.
    scope shared_ground_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, shared_ground_to_air_    // a1(transition subroutine) = shared_ground_to_air_
        jal     0x800DDDDC                  // common ground collision subroutine (transition on no floor, slide-off)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Collision subroutine for DSPAir actions.
    scope shared_air_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, shared_air_to_ground_   // a1(transition subroutine) = shared_air_to_ground_
        jal     0x800DE6E4                  // common air collision subroutine (transition on landing, no ledge grab)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }
    // @ Description
    // Collision wubroutine for NSP throw actions.
    // yes this is from marina yes im keeping the wub
    scope throw_air_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        jal     0x800DE934                  // check ground collision
        sw      a0, 0x0018(sp)              // store a0
        beql    v0, r0, _end                // branch if landing transition didn't occured
        nop

        // if a landing transition is occuring, grab release the opponent
        jal     0x80149AC8                  // grab release
        lw      a0, 0x0018(sp)

        _end:
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles ground to air transitions for DSPGround actions.
    scope shared_ground_to_air_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        jal     0x800DEEC8                  // set aerial state
        lw      a0, 0x0084(a0)              // a0 = player struct
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a1, 0x0084(a0)              // ~
        lw      a1, 0x0024(a1)              // ~
        addiu   a1, a1, 0x0004              // a1 = equivalent air action for current ground action (id + 4)
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lli     t6, 0x0003                  // ~
        sw      t6, 0x0010(sp)              // argument 4 = 0x0003
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles air to ground transitions for DSPAir actions.
    scope shared_air_to_ground_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store a0, ra
        jal     0x800DEE98                  // set grounded state
        lw      a0, 0x0084(a0)              // a0 = player struct
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a1, 0x0084(a0)              // ~
        lw      a1, 0x0024(a1)              // ~
        addiu   a1, a1,-0x0004              // a1 = equivalent air action for current ground action (id - 4)
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lli     t6, 0x0003                  // ~
        sw      t6, 0x0010(sp)              // argument 4 = 0x0003
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Sets up an ECB for the chain pipe and detects collisions.
    // @ Arguments
    // a0 - player object
    // @ Returns
    // v0 - 0 for no collision, 1 for left wall collision, 2 for right wall collision, 4 for ceiling collision
    scope chain_collision_: {
        addiu   sp, sp,-0x0110              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        sw      a0, 0x0018(sp)              // 0x0018(sp) = player object

        addiu   a1, sp, 0x0020              // a1 = address to return x/y/z coordinates to
        sw      r0, 0x0000(a1)              // ~
        sw      r0, 0x0004(a1)              // ~
        sw      r0, 0x0008(a1)              // clear space for x/y/z coordinates
        jal     0x800EDF24                  // returns x/y/z coordinates of the part in a0 to a1
        lw      a0, 0x095C(v0)              // a0 = chain end joint

        lw      a0, 0x0018(sp)              // a0 = player object
        lw      v0, 0x0084(a0)              // v0 = player struct
        addiu   t0, v0, 0x0078              // t0 = ecb info
        addiu   t1, sp, 0x0030              // t1 = chain ecb info
        addiu   at, sp, 0x0020              // ~
        sw      at, 0x0000(t1)              // store chain end x/y/z pointer
        or      t2, t0, r0                  // ~
        or      t3, t1, r0                  // loop setup
        addiu   t4, t1, 0x00D0              // loop end address

        _loop:
        addiu   t2, t2, 0x0004              // ~
        addiu   t3, t3, 0x0004              // increment copy address
        lw      at, 0x0000(t2)              // ~
        bne     t3, t4, _loop               // loop if end not reached
        sw      at, 0x0000(t3)              // copy data from player ecb to chain ecb

        lui     at, 0x4120                  // ~
        sw      at, 0x0038(t1)              // chain ecb upper y = 10
        lui     at, 0x40A0                  // ~
        sw      at, 0x003C(t1)              // chain ecb middle y = 5
        sw      r0, 0x0040(t1)              // chain ecb lower y = 0
        lui     at, 0x4320                  // ~
        sw      at, 0x0044(t1)              // chain ecb width = 160
        addiu   at, t1, 0x0038              // ~
        sw      at, 0x0048(t1)              // store ecb pointer

        or      a0, t1, r0                  // a0 = chain ecb info
        lw      a1, 0x0018(sp)              // a1 = player object
        jal     chain_detect_collision_     // detect collision for chain
        or      a2, r0, r0                  // a2 = 0

        lw      ra, 0x0014(sp)              // load ra
        jr      ra                          // return
        addiu   sp, sp, 0x0110              // allocate stack space
    }

    // @ Description
    // Collision detection function for DSP.
    // Based on function 0x800DE45C
    // @ Arguments
    // a0 - ECB info
    // a1 - player object
    // a2 - unknown(0)
    // @ Returns
    // v0 - 0 for no collision, 1 for left wall collision, 2 for right wall collision, 3 for floor collision, 4 for ceiling
    scope chain_detect_collision_: {
        addiu   sp, sp,-0x0058              // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      s1, 0x0018(sp)              // ~
        sw      s0, 0x0014(sp)              // store ra, s0, s1
        sw      a1, 0x003C(sp)              // 0x003C(sp) = player object
        sw      a2, 0x0040(sp)              // 0x0040(sp) = unknown
        lw      s0, 0x0084(a1)              // s0 = player struct
        or      s1, a0, r0                  // s1 = ecb info
        lw      t0, 0x0044(s0)              // t0 = player direction
        addiu   at, r0, 1                   // at = 1
        bne     at, t0, _check_right_wall   // check right wall collision if facing left
        nop

        _check_left_wall:
        jal     0x800DB838                  // detect left wall collision
        sw      r0, 0x0024(sp)              // 0x0024(sp) = 0
        bnez    v0, _end                    // branch if left collision = true
        lli     v0, 0x0001                  // v0 = 0x1 (left collision)
        b       _check_floor
        nop

        _check_right_wall:
        jal     0x800DC3C8                  // detect right wall collision
        or      a0, s1, r0                  // a0 = ecb info
        bnez    v0, _end                    // branch if right wall collision = true
        lli     v0, 0x0002                  // v0 = 0x2 (right collision)

        _check_floor:
        //jal     0x800DD578                  // detect floor collision
        //or      a0, s1, r0                  // a0 = ecb info

        //bnez    v0, _end                    // branch if floor collision = true
        //lli     v0, 0x0003                  // v0 = 0x3 (floor collision)

        jal     0x800DCF58
        or      a0, s1, r0                  // a0 = ecb info

        bnez    v0, _end                    // branch if ceiling collision = true
        lli     v0, 0x0004                  // v0 = 0x4 (ceiling collision)

        or      v0, r0, r0                  // if no wall collision detected, v0 = 0 (no collision)

        _end:
        lw      ra, 0x001C(sp)              // ~
        lw      s1, 0x0018(sp)              // ~
        lw      s0, 0x0014(sp)              // load ra, s0, s1

        jr      ra                          // return
        addiu   sp, sp, 0x0058              // deallocate stack space
    }

    // @ Description
    // Patch which allows Spiderman's up b to collide with item hurtboxes.
    scope item_hurtbox_patch_: {
        OS.patch_start(0xEB0D8, 0x80170698)
        j       item_hurtbox_patch_
        nop
        nop
        _return:
        OS.patch_end()

        lw      t0, 0x0008(s7)              // t0 = character id
        lli     at, Character.id.SPIDERMAN     // at = id.Spiderman

        bne     at, t0, _check_grab         // skip if character != Spiderman
        nop

        // if we're here the character is Spiderman
        lw      t0, 0x0024(s7)              // t0 = current action id
        lli     at, Spiderman.Action.USPGround // at = DSPGround
        beq     t0, at, _end                // skip grab check for Spiderman DSPGround
        lli     at, Spiderman.Action.USPAir    // at = DSPAir
        beq     t0, at, _end                // skip grab check for Spiderman DSPAir
        nop

        _check_grab:
        sll     t0, t8, 18                  // original line 1
        bltzl   t0, _j_0x80170850           // original line 2, modified
        lw      t6, 0x0094(sp)              // original line 3

        _end:
        j       _return                     // return
        nop

        _j_0x80170850:
        j       0x80170850                  // original branch location
        nop
    }
}

scope SpidermanDSP {

    // @ Description
    // Subroutine which runs when Spider-Man initiates a grounded down special.
    // Puts him in an aerial state and that's about it 00E6
    scope ground_initial_: {
        addiu   sp, sp, 0xFFE0              // ~
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // original lines 1-3
        lw      a0, 0x0084(a0)              // a0 = player struct
        lw      t7, 0x014C(a0)              // t7 = kinetic state
        bnez    t7, _change_action          // skip if kinetic state !grounded
        nop
        jal     0x800DEEC8                  // set aerial state
        nop
        _change_action:
        lw      a0, 0x0020(sp)              // a0 = entity struct?
        sw      r0, 0x0010(sp)              // store r0 (some kind of parameter for change action)
        ori     a1, r0, Spiderman.Action.WebSwingAir              // a1 = 0xE4
        or      a2, r0, r0                  // a2 = float: 0.0
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3 = float: 1.0
        lw      ra, 0x001C(sp)              // ~
        addiu   sp, sp, 0x0020              // ~
        jr      ra                          // original return logic
        nop
        }

    // @ Description
    // Subroutine which runs when Marth initiates aerial neutral special actions.
    // Changes action, and sets up initial variable values.
    // a0 - player object
    // a1 - action id
    scope air_initial_: {
        addiu   sp, sp,-0x0030             // allocate stack space
        sw      ra, 0x001C(sp)              // ~
        sw      a0, 0x0020(sp)              // store ra, a0
        sw      r0, 0x0010(sp)              // argument 4 = 0
        
        lw      a1, 0x0084(a0)              // a1 = player struct
        lbu     at, 0x0ADC(a1)              // at = temp flag, used as DSP's ammo
        bnez    at, _end                    // skip if temp flag != 0
        lli     at, OS.TRUE                 // ~
        sb      at, 0x0ADC(a1)              // temp flag = TRUE
        
        lli     a1, Spiderman.Action.WebSwingAir    // a1(action id) = DSPAir
        or      a2, r0, r0                  // a2 = float: 0.0
        jal     0x800E6F24                  // change action
        lui     a3, 0x3F80                  // a3 = float: 1.0
        jal     0x800E0830                  // unknown common subroutine
        lw      a0, 0x0020(sp)              // a0 = player object
        lw      a0, 0x0020(sp)              // ~
        lw      a0, 0x0084(a0)              // a0 = player struct
        sw      r0, 0x017C(a0)              // temp variable 1 = 0
        sw      r0, 0x0180(a0)              // temp variable 2 = 0
        ori     v1, r0, 0x0001              // ~
        sw      v1, 0x0184(a0)              // temp variable 3 = 0x1(BEGIN)
        // reset fall speed
        lbu     v1, 0x018D(a0)              // v1 = fast fall flag
        ori     t6, r0, 0x0007              // t6 = bitmask (01111111)
        and     v1, v1, t6                  // ~
        sb      v1, 0x018D(a0)              // disable fast fall flag
        // freeze y position
        lw      v1, 0x09C8(a0)              // v1 = attribute pointer
        lw      v1, 0x0058(v1)              // v1 = gravity
        sw      v1, 0x004C(a0)              // y velocity = gravity

        _end:
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0030              // deallocate stack space
        jr      ra                          // return
        nop
    }
    
    // @ Description
    // Subroutine which allows a direction change for Spiderman's down special.
    // Uses the moveset data command 580000XX (orignally identified as "set flag" by toomai)
    // This command's purpose appears to be setting a temporary variable in the player struct.
    // Variable values used by this subroutine:
    // 0x2 = change direction
    scope change_direction_: {
        // 0x180 in player struct = temp variable 2
        lw      a1, 0x0084(a0)              // a1 = player struct
        addiu   sp, sp,-0x0010              // allocate stack space
        sw      t0, 0x0004(sp)              // ~
        sw      t1, 0x0008(sp)              // ~
        sw      ra, 0x000C(sp)              // store t0, t1, ra
        lw      t0, 0x0180(a1)              // t0 = temp variable 2
        ori     t1, r0, 0x0002              // t1 = 0x2
        bne     t1, t0, _end                // skip if temp variable 2 != 2
        nop
        jal     0x80160370                  // turn subroutine (copied from captain falcon)
        nop

        _end:
        lw      t0, 0x0004(sp)              // ~
        lw      t1, 0x0008(sp)              // ~
        lw      ra, 0x000C(sp)              // load t0, t1, ra
        addiu   sp, sp, 0x0010              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles physics for Marth's aerial down special.
    scope ground_physics_: {
        addiu   sp, sp,-0x0020              // allocate stack space
        sw      ra, 0x0014(sp)              // ~
        sw      a0, 0x0018(sp)              // store ra, a0
        
        jal     0x800D91EC                  // physics subroutine (disallows player control)
        nop        
        lw      ra, 0x0014(sp)
        addiu   sp, sp, 0x0020              // deallocate stack space
        jr      ra                          // return
        nop
    }
    
    scope ground_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, ground_to_air_          // a1(transition subroutine) = ground_to_air_
        jal     0x800DDE84                  // common ground collision subroutine (transition on no floor, no slide-off)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    scope air_collision_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      ra, 0x0014(sp)              // store ra
        li      a1, air_to_ground_          // a1(transition subroutine) = air_to_ground_
        jal     0x800DE6E4                  // common air collision subroutine (transition on landing, no ledge grab)
        nop
        lw      ra, 0x0014(sp)              // load ra
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Subroutine which handles ground to air transition for neutral special actions
    scope ground_to_air_: {
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // store ra
        sw      a0, 0x0038(sp)              // 0x0038(sp) = player object
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800DEEC8                  // set airborne state (grounded is 0x800DEE98)
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player struct
        lw      v0, 0x0034(sp)              // v0 = player struct
        lw      a0, 0x0038(sp)              // a0 = player object
        
        addiu   a1, r0, Spiderman.Action.WebSwingAir              // a1 = equivalent ground action for current air action
        _change_action:
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lli     t6, 0x0001                  // ~
        jal     0x800E6F24                  // change action
        sw      t6, 0x0010(sp)              // argument 4 = 1 (continue hitbox)
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop
    }

    scope air_to_ground_: {
        addiu   sp, sp,-0x0038              // allocate stack space
        sw      ra, 0x001C(sp)              // store ra
        sw      a0, 0x0038(sp)              // 0x0038(sp) = player object
        lw      a0, 0x0084(a0)              // a0 = player struct
        jal     0x800DEEC8                  // set airborne state (grounded is 0x800DEE98)
        sw      a0, 0x0034(sp)              // 0x0034(sp) = player struct
        lw      v0, 0x0034(sp)              // v0 = player struct
        lw      a0, 0x0038(sp)              // a0 = player object
        
        addiu   a1, r0, Spiderman.Action.WebSwingAir              // a1 = equivalent ground action for current air action
        _change_action:
        lw      a2, 0x0078(a0)              // a2(starting frame) = current animation frame
        lui     a3, 0x3F80                  // a3(frame speed multiplier) = 1.0
        lli     t6, 0x0001                  // ~
        jal     0x800E6F24                  // change action
        sw      t6, 0x0010(sp)              // argument 4 = 1 (continue hitbox)
        lw      ra, 0x001C(sp)              // load ra
        addiu   sp, sp, 0x0038              // deallocate stack space
        jr      ra                          // return
        nop
    }
}