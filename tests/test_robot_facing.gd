@tool
extends SceneTree
func _init():
    var scn = load('res://presentation/assets/models/human_character.glb')
    if scn:
        var inst = scn.instantiate()
        var robot = inst.find_child('Robot', true, false)
        if robot:
            var aabb = robot.mesh.get_aabb()
            print('Robot AABB: ', aabb)
            # Check nose/face or arm positions
        inst.free()
    quit(0)
