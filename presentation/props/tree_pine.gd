class_name TreePine
extends Node3D

## Stylized evergreen tree with trunk and layered conical foliage.

@export var tree_scale: float = 1.0

func _ready() -> void:
	_build_tree()

func _build_tree() -> void:
	scale = Vector3.ONE * tree_scale
	
	# Trunk
	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.35
	trunk_mesh.height = 2.2
	trunk_mesh.radial_segments = 6
	
	var trunk_mat: StandardMaterial3D = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.35, 0.22, 0.14)
	trunk_mat.roughness = 0.9
	
	var trunk_instance: MeshInstance3D = MeshInstance3D.new()
	trunk_instance.mesh = trunk_mesh
	trunk_instance.material_override = trunk_mat
	trunk_instance.position = Vector3(0.0, 1.1, 0.0)
	add_child(trunk_instance)
	
	# Foliage material
	var foliage_mat: StandardMaterial3D = StandardMaterial3D.new()
	foliage_mat.albedo_color = Color(0.18, 0.38, 0.22)
	foliage_mat.roughness = 0.8
	
	# 3 Foliage cones
	var cone_heights: Array = [1.8, 3.0, 4.0]
	var cone_radii: Array = [1.6, 1.25, 0.9]
	var cone_lengths: Array = [1.8, 1.6, 1.4]
	
	for i in range(3):
		var cone_mesh: CylinderMesh = CylinderMesh.new()
		cone_mesh.top_radius = 0.02
		cone_mesh.bottom_radius = cone_radii[i]
		cone_mesh.height = cone_lengths[i]
		cone_mesh.radial_segments = 7
		
		var cone_instance: MeshInstance3D = MeshInstance3D.new()
		cone_instance.mesh = cone_mesh
		cone_instance.material_override = foliage_mat
		cone_instance.position = Vector3(0.0, cone_heights[i], 0.0)
		add_child(cone_instance)
