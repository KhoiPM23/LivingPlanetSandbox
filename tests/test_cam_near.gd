@tool
extends SceneTree

func _check_node(node: Node, pos: Vector3) -> void:
	if node is VisualInstance3D:
		var gpos = node.global_position
		var dist = gpos.distance_to(pos)
		if dist < 12.0:
			print("VisualInstance near cam: ", node.name, " class: ", node.get_class(), " pos: ", gpos, " dist: ", dist)
			if node is MeshInstance3D:
				var m = (node as MeshInstance3D).mesh
				if m:
					print("   Mesh AABB: ", m.get_aabb())
	for c in node.get_children():
		_check_node(c, pos)

func _init() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main = packed.instantiate()
	root.add_child(main)

	var cam_pos = Vector3(-8.0, 4.2, 4.0)
	print("Checking objects near cam pos: ", cam_pos)
	_check_node(main, cam_pos)
	main.free()
	quit(0)
