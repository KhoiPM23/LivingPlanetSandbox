@tool
extends SceneTree

func _init() -> void:
	var f_scn = load("res://presentation/assets/models/forest.glb") as PackedScene
	if f_scn:
		var root = f_scn.instantiate()
		var g = root.find_child("Grass_2_D_Color1", true, false) as MeshInstance3D
		if g and g.mesh:
			print("Grass_2_D_Color1 mesh: ", g.mesh)
			print("  surfaces: ", g.mesh.get_surface_count())
			var mat = g.mesh.surface_get_material(0)
			print("  material: ", mat)
			if mat is StandardMaterial3D:
				print("    albedo_color: ", mat.albedo_color)
				print("    albedo_texture: ", mat.albedo_texture)
			# Let's count vertices/triangles
			var arrays = g.mesh.surface_get_arrays(0)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			print("    vertex count: ", verts.size())
		root.free()
	quit(0)
