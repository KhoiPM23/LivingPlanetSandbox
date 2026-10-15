@tool
extends SceneTree

func _init() -> void:
	var f_gltf: GLTFDocument = GLTFDocument.new()
	var f_state: GLTFState = GLTFState.new()
	if f_gltf.append_from_file("res://presentation/assets/models/forest.glb", f_state) == OK:
		var root: Node = f_gltf.generate_scene(f_state)
		print("=== FOREST.GLB MESHES ===")
		_print_children(root)
		root.free()

	var n_gltf: GLTFDocument = GLTFDocument.new()
	var n_state: GLTFState = GLTFState.new()
	if n_gltf.append_from_file("res://presentation/assets/models/nature.glb", n_state) == OK:
		var root: Node = n_gltf.generate_scene(n_state)
		print("=== NATURE.GLB MESHES ===")
		_print_children(root)
		root.free()
	quit(0)

func _print_children(node: Node, prefix: String = "") -> void:
	for c in node.get_children():
		if c is MeshInstance3D:
			print(prefix, "Mesh: ", c.name)
		_print_children(c, prefix + "  ")
