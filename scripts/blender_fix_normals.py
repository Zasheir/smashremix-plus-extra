import bpy

rigged_rooms = []
regular_rooms = []

# if there's no selected meshes to use, let's just grab everything in the scene
if len(bpy.context.selected_objects) == 0:
    bpy.ops.object.select_all(action='SELECT')

for room in bpy.context.selected_objects:
    if room.type == 'MESH':
        if len(room.data.polygons) > 0:
            for modifier in room.modifiers:
                if modifier.type == "ARMATURE":
                    rigged_rooms.append(room)

# get unrigged versions of every room
for room in rigged_rooms:
    bpy.ops.object.select_all(action='DESELECT')

    room.select_set(True)
    bpy.context.view_layer.objects.active = room
    bpy.ops.object.duplicate()
    regular_room = bpy.context.view_layer.objects.active

    regular_room.modifiers.clear() # hope you didn't have an important modifier!
    regular_rooms.append(regular_room)

# actually adjust normals
for idx, reg_room in enumerate(regular_rooms):
    bpy.ops.object.select_all(action='DESELECT')
    rig_room = rigged_rooms[idx]

    # transfer normals from rigged room to regular room
    reg_room.select_set(True)
    bpy.context.view_layer.objects.active = rig_room
    bpy.ops.object.data_transfer(data_type='CUSTOM_NORMAL', loop_mapping='TOPOLOGY')

    reg_room.select_set(False)

    # transfer normals from regular room to rigged room
    rig_room.select_set(True)
    bpy.context.view_layer.objects.active = reg_room
    bpy.ops.object.data_transfer(data_type='CUSTOM_NORMAL', loop_mapping='TOPOLOGY')

    print('Adjusted normals for', rig_room.name)

# delete regular rooms since they're un-needed after the normals stuff
bpy.ops.object.select_all(action='DESELECT')
for room in regular_rooms:
    room.select_set(True)
bpy.ops.object.delete()