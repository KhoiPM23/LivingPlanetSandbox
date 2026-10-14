class_name TreePine
extends Node3D

## Stylized evergreen tree with trunk and layered conical foliage.
## Uses shared static wind shader material for synchronized GPU wind sway and surface wetness sheen.

@export var tree_scale: float = 1.0

static var _shared_foliage_mat: ShaderMaterial = null
static var _shared_trunk_mat: StandardMaterial3D = null

static func get_shared_foliage_material() -> ShaderMaterial:
	if _shared_foliage_mat == null:
		_shared_foliage_mat = ShaderMaterial.new()
		_shared_foliage_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
		_shared_foliage_mat.set_shader_parameter("albedo_top", Color(0.20, 0.42, 0.24, 1.0))
		_shared_foliage_mat.set_shader_parameter("albedo_bottom", Color(0.12, 0.28, 0.16, 1.0))
		_shared_foliage_mat.set_shader_parameter("roughness", 0.75)
		_shared_foliage_mat.set_shader_parameter("wind_speed", 1.2)
		_shared_foliage_mat.set_shader_parameter("wind_strength", 0.18)
		_shared_foliage_mat.set_shader_parameter("wetness", 0.0)
	return _shared_foliage_mat

static func get_shared_trunk_material() -> StandardMaterial3D:
	if _shared_trunk_mat == null:
		_shared_trunk_mat = StandardMaterial3D.new()
		_shared_trunk_mat.albedo_color = Color(0.35, 0.22, 0.14)
		_shared_trunk_mat.roughness = 0.9
	return _shared_trunk_mat

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

	var trunk_instance: MeshInstance3D = MeshInstance3D.new()
	trunk_instance.mesh = trunk_mesh
	trunk_instance.material_override = get_shared_trunk_material()
	trunk_instance.position = Vector3(0.0, 1.1, 0.0)
	add_child(trunk_instance)

	# 3 Foliage cones
	var cone_heights: Array = [1.8, 3.0, 4.0]
	var cone_radii: Array = [1.6, 1.25, 0.9]
	var cone_lengths: Array = [1.8, 1.6, 1.4]
	var fol_mat: ShaderMaterial = get_shared_foliage_material()

	for i in range(3):
		var cone_mesh: CylinderMesh = CylinderMesh.new()
		cone_mesh.top_radius = 0.02
		cone_mesh.bottom_radius = cone_radii[i]
		cone_mesh.height = cone_lengths[i]
		cone_mesh.radial_segments = 7

		var cone_instance: MeshInstance3D = MeshInstance3D.new()
		cone_instance.mesh = cone_mesh
		cone_instance.material_override = fol_mat
		cone_instance.position = Vector3(0.0, cone_heights[i], 0.0)
		add_child(cone_instance)
