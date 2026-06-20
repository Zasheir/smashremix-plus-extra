import os
from dataclasses import dataclass
from typing import List, Dict
from enum import Enum
import struct


class HurtboxHeight(Enum):
    LOW = 0
    MID = 1
    HIGH = 2


@dataclass
class Hurtbox:
    bone: int
    height: HurtboxHeight
    grabbable: bool
    offset: List[float]  # [x, y, z]
    size: List[float]  # [x, y, z]

    def __post_init__(self):
        if isinstance(self.height, str):
            self.height = HurtboxHeight[self.height.upper()]
        elif isinstance(self.height, int):
            self.height = HurtboxHeight(self.height)

        if not isinstance(self.offset, list) or len(self.offset) != 3:
            raise ValueError("Offset must be a list of three floats.")
        if not isinstance(self.size, list) or len(self.size) != 3:
            raise ValueError("Size must be a list of three floats.")

    @classmethod
    def from_bytes(self, data: bytes) -> 'Hurtbox':
        # Adjusting for 0-based index
        bone = int.from_bytes(data[0:4], 'big') - 4
        height = HurtboxHeight(int.from_bytes(
            data[4:8], 'big'))
        grabbable = bool(int.from_bytes(data[8:12], 'big'))
        offset_x = struct.unpack(">f", data[12:16])[0]
        offset_y = struct.unpack(">f", data[16:20])[0]
        offset_z = struct.unpack(">f", data[20:24])[0]
        size_x = struct.unpack(">f", data[24:28])[0]
        size_y = struct.unpack(">f", data[28:32])[0]
        size_z = struct.unpack(">f", data[32:36])[0]

        return Hurtbox(
            bone=bone,
            height=height,
            grabbable=grabbable,
            offset=[offset_x, offset_y, offset_z],
            size=[size_x, size_y, size_z]
        )

    def to_bytes(self) -> bytes:
        data = bytearray()

        bone = min(self.bone+4, 0xFFFFFFFF)

        data.extend(bone.to_bytes(4, 'big'))
        data.extend(self.height.value.to_bytes(4, 'big'))
        data.extend(int(self.grabbable).to_bytes(4, 'big'))
        data.extend(struct.pack(">f", self.offset[0]))
        data.extend(struct.pack(">f", self.offset[1]))
        data.extend(struct.pack(">f", self.offset[2]))
        data.extend(struct.pack(">f", self.size[0]))
        data.extend(struct.pack(">f", self.size[1]))
        data.extend(struct.pack(">f", self.size[2]))
        return bytes(data)

    def to_yaml(self) -> Dict[str, any]:
        return {
            'bone': self.bone,
            'height': self.height.name.lower(),
            'grabbable': self.grabbable,
            'offset': self.offset,
            'size': self.size
        }

    @classmethod
    def disabled(cls) -> 'Hurtbox':
        return cls(
            bone=0xFFFFFFFF,
            height=HurtboxHeight.LOW,
            grabbable=False,
            offset=[0.0, 0.0, 0.0],
            size=[0.0, 0.0, 0.0]
        )
