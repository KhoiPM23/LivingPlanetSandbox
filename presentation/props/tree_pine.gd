class_name TreePine
extends Node3D

## High-fidelity natural evergreen/pine tree with authentic 3D branch silhouettes.
## Sourced from CC0 KayKit Forest Pack.
## Uses shared static wind shader material for synchronized GPU wind sway and surface wetness sheen.

@export var tree_scale: float = 1.0

static var _shared_foliage_mat: ShaderMaterial = null
static var _shared_trunk_mat: StandardMaterial3D = null
static var _cached_meshes: Array = []

static func _init_cache() -> void:
	if not _cached_meshes.is_empty():
		return
	var gltf: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	var err: Error = gltf.append_from_file("res://presentation/assets/models/forest.glb", state)
	if err != OK:
		return
	var root: Node = gltf.generate_scene(state)
	if not root:
		return

	var candidate_names: Array = ["Tree_1_A_Color1", "Tree_1_C_Color1", "Tree_3_A_Color1", "Tree_4_A_Color1"]
	var tex: Texture2D = null
	for cname in candidate_names:
		var mi: MeshInstance3D = root.find_child(cname, true, false) as MeshInstance3D
		if mi and mi.mesh:
			_cached_meshes.append(mi.mesh)
			if tex == null and mi.mesh.get_surface_count() > 0:
				var m = mi.mesh.surface_get_material(0)
				if m is StandardMaterial3D and m.albedo_texture:
					tex = m.albedo_texture

	var shared_mat: ShaderMaterial = get_shared_foliage_material()
	if tex and shared_mat:
		shared_mat.set_shader_parameter("albedo_texture", tex)
		shared_mat.set_shader_parameter("use_texture", true)

	root.free()

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
		_shared_foliage_mat.set_shader_parameter("use_texture", false)
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
	_init_cache()

	if not _cached_meshes.is_empty():
		# Deterministic variation selection based on position hash
		var idx: int = abs(int(position.x * 7.0 + position.z * 13.0)) % _cached_meshes.size()
		var mesh: Mesh = _cached_meshes[idx]

		var tree_inst: MeshInstance3D = MeshInstance3D.new()
		tree_inst.name = "TreeModel"
		tree_inst.mesh = mesh
		tree_inst.material_override = get_shared_foliage_material()
		add_child(tree_inst)
		return

	# Fallback primitive if asset not loaded
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
