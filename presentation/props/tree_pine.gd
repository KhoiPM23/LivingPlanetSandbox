class_name TreePine
extends Node3D

## High-fidelity natural evergreen & deciduous trees with authentic branch silhouettes.
## Sourced from Kenney Nature Kit & KayKit Forest Pack (CC0).
## Uses shared static wind shader material for synchronized GPU wind sway and surface wetness sheen.

@export var tree_scale: float = 1.0

static var _shared_foliage_mat: ShaderMaterial = null
static var _shared_trunk_mat: StandardMaterial3D = null

static var _cached_pines: Array = []
static var _cached_snow_pines: Array = []
static var _cached_oaks: Array = []
static var _cached_forest_mat: Material = null

static func _init_cache() -> void:
	if not _cached_pines.is_empty():
		return

	# 1. Load Forest Pack (KayKit CC0) for rich textured conifers & broadleaf trees
	var f_gltf: GLTFDocument = GLTFDocument.new()
	var f_state: GLTFState = GLTFState.new()
	if f_gltf.append_from_file("res://presentation/assets/models/forest.glb", f_state) == OK:
		var f_root: Node = f_gltf.generate_scene(f_state)
		if f_root:
			for pname in ["Tree_4_A_Color1", "Tree_4_C_Color1"]:
				var mi: MeshInstance3D = f_root.find_child(pname, true, false) as MeshInstance3D
				if mi and mi.mesh:
					_cached_pines.append(mi.mesh)
					if _cached_forest_mat == null and mi.mesh.get_surface_count() > 0:
						_cached_forest_mat = mi.mesh.surface_get_material(0)

			for oname in ["Tree_1_A_Color1", "Tree_1_C_Color1", "Tree_3_C_Color1"]:
				var mi: MeshInstance3D = f_root.find_child(oname, true, false) as MeshInstance3D
				if mi and mi.mesh:
					_cached_oaks.append(mi.mesh)

			f_root.free()

	# 2. Load Nature Kit (Kenney CC0) for alpine snow conifers
	var n_gltf: GLTFDocument = GLTFDocument.new()
	var n_state: GLTFState = GLTFState.new()
	if n_gltf.append_from_file("res://presentation/assets/models/nature.glb", n_state) == OK:
		var n_root: Node = n_gltf.generate_scene(n_state)
		if n_root:
			for sname in ["tree_pineTallA_snow", "tree_pineDefaultA_snow", "tree_pineRoundA_snow"]:
				var mi: MeshInstance3D = n_root.find_child(sname, true, false) as MeshInstance3D
				if mi and mi.mesh:
					_cached_snow_pines.append(mi.mesh)
			n_root.free()

	get_shared_foliage_material()

static func get_shared_foliage_material() -> ShaderMaterial:
	if _shared_foliage_mat == null:
		_shared_foliage_mat = ShaderMaterial.new()
		_shared_foliage_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
		_shared_foliage_mat.set_shader_parameter("albedo_top", Color(0.18, 0.45, 0.22, 1.0))
		_shared_foliage_mat.set_shader_parameter("albedo_bottom", Color(0.08, 0.24, 0.12, 1.0))
		_shared_foliage_mat.set_shader_parameter("roughness", 0.75)
		_shared_foliage_mat.set_shader_parameter("wind_speed", 1.2)
		_shared_foliage_mat.set_shader_parameter("wind_strength", 0.18)
		_shared_foliage_mat.set_shader_parameter("wetness", 0.0)
		_shared_foliage_mat.set_shader_parameter("use_texture", false)
		_shared_foliage_mat.set_shader_parameter("use_vertex_color", true)
	return _shared_foliage_mat

static func get_shared_trunk_material() -> StandardMaterial3D:
	if _shared_trunk_mat == null:
		_shared_trunk_mat = StandardMaterial3D.new()
		_shared_trunk_mat.albedo_color = Color(0.28, 0.18, 0.10)
		_shared_trunk_mat.roughness = 0.92
	return _shared_trunk_mat

func _ready() -> void:
	_build_tree()

func _build_tree() -> void:
	_init_cache()

	var y_pos: float = position.y
	var chosen_mesh: Mesh = null
	var is_snow_pine: bool = false

	# Ecological species distribution by altitude & moisture
	if y_pos > 11.0 and not _cached_snow_pines.is_empty():
		# Alpine summit: snow-dusted conifer
		var idx: int = abs(int(position.x * 7.0 + position.z * 13.0)) % _cached_snow_pines.size()
		chosen_mesh = _cached_snow_pines[idx]
		is_snow_pine = true
	elif y_pos < 5.2 and not _cached_oaks.is_empty() and (int(position.x + position.z) % 3 == 0):
		# Low fertile valley: broadleaf deciduous oak
		var idx: int = abs(int(position.x * 5.0 + position.z * 11.0)) % _cached_oaks.size()
		chosen_mesh = _cached_oaks[idx]
	elif not _cached_pines.is_empty():
		# Mountain slopes & boreal forest: evergreen conifer
		var idx: int = abs(int(position.x * 7.0 + position.z * 13.0)) % _cached_pines.size()
		chosen_mesh = _cached_pines[idx]

	if chosen_mesh != null:
		var tree_inst: MeshInstance3D = MeshInstance3D.new()
		tree_inst.name = "TreeModel"
		tree_inst.mesh = chosen_mesh

		if is_snow_pine:
			var base_scale: float = 2.85 * tree_scale
			scale = Vector3(base_scale, base_scale * randf_range(0.95, 1.25), base_scale)
			tree_inst.material_override = get_shared_foliage_material()
		else:
			# Native forest.glb trees are already 4.2m to 10.7m tall
			var base_scale: float = 1.05 * tree_scale
			scale = Vector3(base_scale, base_scale * randf_range(0.9, 1.2), base_scale)
			if _cached_forest_mat:
				tree_inst.material_override = _cached_forest_mat

		tree_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(tree_inst)
		return

	# Fallback primitive if asset not loaded
	scale = Vector3.ONE * tree_scale
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
