@tool
extends SceneTree

func _init() -> void:
	var gltf: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	gltf.append_from_file("res://presentation/assets/foliage/pine1.gltf", state)
	var root: Node = gltf.generate_scene(state)
	var mi: MeshInstance3D = root.get_child(0) as MeshInstance3D
	var mesh: Mesh = mi.mesh
	for s in range(mesh.get_surface_count()):
		var mat: StandardMaterial3D = mesh.surface_get_material(s) as StandardMaterial3D
		if mat:
			print("Surface ", s, " albedo_color: ", mat.albedo_color, " tex: ", mat.albedo_texture)
	root.free()
	quit(0)
