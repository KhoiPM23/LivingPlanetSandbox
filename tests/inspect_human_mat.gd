@tool
extends SceneTree
func _init():
    var doc = GLTFDocument.new()
    var state = GLTFState.new()
    if doc.append_from_file('res://presentation/assets/models/human_character.glb', state) == OK:
        var root = doc.generate_scene(state)
        var mesh_inst: MeshInstance3D = root.find_child('Robot', true, false)
        if mesh_inst and mesh_inst.mesh:
            print('Surfaces: ', mesh_inst.mesh.get_surface_count())
            for i in range(mesh_inst.mesh.get_surface_count()):
                var mat = mesh_inst.get_active_material(i)
                print('Surface ', i, ' mat: ', mat.resource_name if mat else 'null')
                if mat is StandardMaterial3D:
                    print('  albedo: ', mat.albedo_color, ' rough: ', mat.roughness, ' metallic: ', mat.metallic)
        root.free()
    quit(0)
