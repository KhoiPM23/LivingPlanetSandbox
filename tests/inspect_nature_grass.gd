@tool
extends SceneTree

func _init() -> void:
	var n_scn = load("res://presentation/assets/models/nature.glb") as PackedScene
	if n_scn:
		var root = n_scn.instantiate()
		for gname in ["grass_large", "grass_leafsLarge", "grass_leafs"]:
			var g = root.find_child(gname, true, false) as MeshInstance3D
			if g and g.mesh:
				var arrays = g.mesh.surface_get_arrays(0)
				var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				print(gname, " verts: ", verts.size(), " aabb: ", g.mesh.get_aabb())
		root.free()
	quit(0)
