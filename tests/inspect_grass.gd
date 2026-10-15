@tool
extends SceneTree

func _init() -> void:
	print("--- INSPECTING GRASS MESHES ---")
	var f_scn = load("res://presentation/assets/models/forest.glb") as PackedScene
	if f_scn:
		var f_root = f_scn.instantiate()
		for c in f_root.get_children():
			if "Grass" in c.name or "grass" in c.name or "Bush" in c.name:
				print("Forest GLB node: ", c.name, " class: ", c.get_class())
				if c is MeshInstance3D and c.mesh:
					print("   surfaces: ", c.mesh.get_surface_count(), " aabb: ", c.mesh.get_aabb())
		f_root.free()

	var n_scn = load("res://presentation/assets/models/nature.glb") as PackedScene
	if n_scn:
		var n_root = n_scn.instantiate()
		for c in n_root.get_children():
			if "grass" in c.name:
				print("Nature GLB node: ", c.name, " class: ", c.get_class())
				if c is MeshInstance3D and c.mesh:
					print("   surfaces: ", c.mesh.get_surface_count(), " aabb: ", c.mesh.get_aabb())
		n_root.free()

	quit(0)
