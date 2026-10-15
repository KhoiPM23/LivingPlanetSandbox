@tool
extends SceneTree

func _init() -> void:
	var gltf: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	gltf.append_from_file("res://presentation/assets/models/Stag.gltf", state)
	var root: Node = gltf.generate_scene(state)
	var arm = root.find_child("AnimalArmature", true, false)
	if arm:
		for c in arm.get_children():
			print("Armature child: ", c.name, " type: ", c.get_class())
			if c is Skeleton3D:
				for sc in c.get_children():
					print("  Skeleton child: ", sc.name, " type: ", sc.get_class())
					if sc is MeshInstance3D and sc.mesh:
						print("    Mesh aabb: ", sc.mesh.get_aabb())
	root.free()
	quit(0)
