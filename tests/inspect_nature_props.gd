@tool
extends SceneTree

func _init() -> void:
	var n_scn = load("res://presentation/assets/models/nature.glb") as PackedScene
	if n_scn:
		var root = n_scn.instantiate()
		for c in root.get_children():
			if c is MeshInstance3D and c.mesh:
				var m = c.mesh.surface_get_material(0) if c.mesh.get_surface_count() > 0 else null
				print("Nature node: ", c.name, " mat: ", m)
				if m is StandardMaterial3D:
					print("   albedo: ", m.albedo_color, " tex: ", m.albedo_texture, " vcol: ", m.vertex_color_use_as_albedo)
		root.free()
	quit(0)
