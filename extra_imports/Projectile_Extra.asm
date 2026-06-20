// Projectile.asm
if !{defined __PROJECTILE_EXTRA__} {
    define __PROJECTILE_EXTRA__()
    print "included Projectile_extra.asm\n"

    include "OS.asm"

    scope Projectile {
        constant MAX_REMIX_PROJECTILE_NUM(128) // maximum number of extra projectiles that can be added

        scope hitlag_multiplier {
            OS.align(4)
            table:
            constant TABLE_ORIGIN(origin())
            fill (MAX_REMIX_PROJECTILE_NUM * 0x2), 0xFFFF
            OS.align(4)
        }

        macro set_projectile_hitlag_multiplier(id, multi) {
            pushvar origin, base
            origin Projectile.hitlag_multiplier.TABLE_ORIGIN + (({id} - Projectile.VANILLA_LAST_ID) * 0x2)
            dh {multi}
            pullvar base, origin
            print "Setting projectile hitlag multiplier: {id} - Multiplier: 0x" ; OS.print_hex({multi}) ; print "\n"
        }

        scope di_multiplier {
            OS.align(4)
            table:
            constant TABLE_ORIGIN(origin())
            fill (MAX_REMIX_PROJECTILE_NUM * 0x2), 0xFFFF
            OS.align(4)
        }

        macro set_projectile_di_multiplier(id, multi) {
            pushvar origin, base
            origin Projectile.di_multiplier.TABLE_ORIGIN + (({id} - Projectile.VANILLA_LAST_ID) * 0x2)
            dh {multi}
            pullvar base, origin
            print "Setting projectile di multiplier: {id} - Multiplier: 0x" ; OS.print_hex({multi}) ; print "\n"
        }
    }
}