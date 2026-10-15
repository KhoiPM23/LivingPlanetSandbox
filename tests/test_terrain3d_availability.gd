@tool
extends SceneTree

func _init() -> void:
	print("Checking Terrain3D availability in ClassDB...")
	var has_terrain3d: bool = ClassDB.class_exists("Terrain3D")
	print("Terrain3D exists: ", has_terrain3d)
	if has_terrain3d:
		var t = ClassDB.instantiate("Terrain3D")
		print("Successfully instantiated Terrain3D: ", t)
	quit()
