@tool
extends SceneTree
func _init():
    var doc = GLTFDocument.new()
    var state = GLTFState.new()
    if doc.append_from_file('res://presentation/assets/models/human_character.glb', state) == OK:
        var root = doc.generate_scene(state)
        var mesh_inst = root.find_child('*', true, false)
        for c in root.get_children():
            _check_mesh(c)
        root.free()
    quit(0)

func _check_mesh(node):
    if node is MeshInstance3D and node.mesh:
        var aabb = node.mesh.get_aabb()
        print(node.name, ' AABB: size=', aabb.size, ' pos=', aabb.position)
    for c in node.get_children():
        _check_mesh(c)
