@tool
extends SceneTree

func test_model(path: String) -> void:
	print("--- Testing ", path, " ---")
	var gltf: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	var err = gltf.append_from_file(path, state)
	if err != OK:
		printerr("Failed to load ", path, ": ", err)
		return
	var root: Node = gltf.generate_scene(state)
	if not root:
		printerr("generate_scene failed for ", path)
		return
	for child in root.get_children():
		if child is MeshInstance3D:
			var m: Mesh = child.mesh
			print("  Child: ", child.name, " Mesh: ", m.get_class(), " Surfaces: ", m.get_surface_count())
	root.free()

func _init() -> void:
	test_model("res://presentation/assets/foliage/pine1.gltf")
	test_model("res://presentation/assets/foliage/pine2.gltf")
	test_model("res://presentation/assets/foliage/pine3.gltf")
	test_model("res://presentation/assets/foliage/bush1.gltf")
	test_model("res://presentation/assets/foliage/bush2.gltf")
	print("ALL MODELS VERIFIED!")
	quit(0)
