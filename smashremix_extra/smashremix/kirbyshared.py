from dataclasses import dataclass
from typing import List
import lineinfile
from smashremix_extra import hex_util


@dataclass
class KirbyJumpConfig:
    character_id: str = ""
    jump_decay: float = 0
    height_multiplier_3: float = 0
    height_multiplier_4: float = 0
    height_multiplier_5: float = 0
    height_multiplier_6: float = 0


class KirbyShared:
    def __init__(self):
        self.configs: List[KirbyJumpConfig] = []

    def Inject(self):
        # Inject configs into jigglypuffkirbyshared.asm
        if not self.configs:
            return

        # jump_fix_1
        defs = []

        for config in self.configs:
            defs.append(
                f"\t\taddiu at, r0, Character.id.{config.character_id} // {config.character_id} ID"
                f"\n\t\tbeq v0, at, _kirby_jump_1"
            )

        lineinfile.add_line_to_file(
            filepath="src/jigglypuffkirbyshared.asm",
            line="\n\t".join(defs),
            inserter=lineinfile.AfterLast(
                r".*beq\s*v0, at, _kirby_jump_1.*")
        )

        # jump_fix_2
        defs = []
        bottom_defs = []

        for config in self.configs:
            defs.append(
                f"\t\taddiu at, r0, Character.id.{config.character_id} // {config.character_id} ID"
                f"\n\t\tbeq v0, at, _{config.character_id}_jump_2"
            )

            bottom_defs.append(
                f"\t\t{config.character_id}_jump_multiplier_table:"
                f"\n\t\tfloat32 0 // jump 1 (not used)"
                f"\n\t\tfloat32 0 // jump 2 (not used)"
                f"\n\t\tfloat32 {config.height_multiplier_3} // jump 3"
                f"\n\t\tfloat32 {config.height_multiplier_4} // jump 4"
                f"\n\t\tfloat32 {config.height_multiplier_5} // jump 5"
                f"\n\t\tfloat32 {config.height_multiplier_6} // jump 6"
            )

            bottom_defs.append(
                f"\t\t_{config.character_id}_jump_2:"
                f"\n\t\tmtc1\tt4, f4 // move t4 to float"
                f"\n\t\tlui\tat, 0x{hex_util.float_to_ieee754_hex(config.jump_decay)[0:4]} // at - {config.character_id}s jump decay"
                f"\n\t\tmtc1\tat, f8 // move at to float"
                f"\n\t\tcvt.s.w\tf6, f4 // convert f6"
                f"\n\t\tli\tat, {config.character_id}_jump_multiplier_table // at={config.character_id}s jump multipler table"
                f"\n\t\tsll\tt5, v1, 2 // t5=offset to current jump multipler"
                f"\n\t\taddu\tat, at, t5 // at=current index"
                f"\n\t\tlwc1\tf16, 0x0000(at) // f16=jump multipler for this jump"
                f"\n\t\tj 0x80140090 // goto the rest of the kirby extra jump routine"
                f"\n\t\tnop"
            )

        lineinfile.add_line_to_file(
            filepath="src/jigglypuffkirbyshared.asm",
            line="\n\t".join(defs),
            inserter=lineinfile.AfterLast(
                r".*beq\s*v0, at, _kirby_jump_2.*")
        )

        # Add bottom defs before "_dedede_jump_2:"
        lineinfile.add_line_to_file(
            filepath="src/jigglypuffkirbyshared.asm",
            line="\n\n".join(bottom_defs)+"\n\n",
            inserter=lineinfile.BeforeFirst(
                r".*_dedede_jump_2:.*")
        )

        # jump_fix_3
        defs = []

        for config in self.configs:
            defs.append(
                f"\t\taddiu at, r0, Character.id.{config.character_id} // {config.character_id} ID"
                f"\n\t\tbeq v1, at, _puff_jump_3"
            )

        lineinfile.add_line_to_file(
            filepath="src/jigglypuffkirbyshared.asm",
            line="\n\t".join(defs),
            inserter=lineinfile.AfterLast(
                r".*beq\s*v1, at, _puff_jump_3.*")
        )

        # jump_fix_4
        defs = []

        for config in self.configs:
            defs.append(
                f"\t\taddiu at, r0, Character.id.{config.character_id} // {config.character_id} ID"
                f"\n\t\tbeq v0, at, _kirby_jump_4"
            )

        lineinfile.add_line_to_file(
            filepath="src/jigglypuffkirbyshared.asm",
            line="\n\t".join(defs),
            inserter=lineinfile.AfterLast(
                r".*beq\s*v0, at, _kirby_jump_4.*")
        )

        # jump_fix_5
        defs = []

        for config in self.configs:
            defs.append(
                f"\t\taddiu at, r0, Character.id.{config.character_id} // {config.character_id} ID"
                f"\n\t\tbeq v1, at, _kirby_jump_5"
            )

        lineinfile.add_line_to_file(
            filepath="src/jigglypuffkirbyshared.asm",
            line="\n\t".join(defs),
            inserter=lineinfile.AfterLast(
                r".*beq\s*v1, at, _kirby_jump_5.*")
        )


kirby_shared = KirbyShared()
