from struct import Struct


class Stage:
    def __init__(self, name, id, variant):
        self.name = name
        self.id = id
        self.variants = {
            k: None for k in StageVariant.__annotations__.keys()
        }


class StageVariant(Struct):
    DL: Stage
    OMEGA: Stage
    REMIX: Stage
    REMIX2: Stage
    REMIX3: Stage
    REMIX4: Stage
    REMIX5: Stage
    REMIX6: Stage
