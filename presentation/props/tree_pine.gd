class_name TreePine
extends Node3D

## High-fidelity natural evergreen hero pines with authentic branch cards,
## realistic PBR bark strata, physical needle alpha scissor, and reactive wind sway.
## Eliminates low-poly stylized toy cones.

enum TreeArchetype {
	ELDER = 0,
	STANDARD = 1,
	SAPLING = 2,
	SNAG = 3,
	CROOKED = 4
}

@export var tree_scale: float = 1.0
@export var archetype: TreeArchetype = TreeArchetype.STANDARD

static var _cached_hero_pines: Array[Mesh] = []
static var _cached_dead_trees: Array[Mesh] = []

static var _shared_pine_bark_mat: StandardMaterial3D = null
static var _shared_pine_needle_mat: ShaderMaterial = null
static var _shared_snag_mat: StandardMaterial3D = null

static func _init_cache() -> void:
	if not _cached_hero_pines.is_empty():
		return

	# 1. Load Hero Game-Ready Pines (PBR Textured with Alpha-Scissor needle cards)
	var pine_paths: Array[String] = [
		"res://presentation/assets/foliage/pine1.gltf",
		"res://presentation/assets/foliage/pine2.gltf",
		"res://presentation/assets/foliage/pine3.gltf"
	]

	for ppath in pine_paths:
		var p_scn = load(ppath) as PackedScene
		if p_scn:
			var root: Node = p_scn.instantiate()
			if root and root.get_child_count() > 0:
				var mi: MeshInstance3D = root.get_child(0) as MeshInstance3D
				if mi and mi.mesh:
					_cached_hero_pines.append(mi.mesh)
			if root:
				root.free()

	# 2. Load Windswept Alpine Snags from Nature Kit
	var n_scn = load("res://presentation/assets/models/nature.glb") as PackedScene
	if n_scn:
		var n_root: Node = n_scn.instantiate()
		if n_root:
			for dname in ["tree_tall_dead", "tree_thin_dead"]:
				var mi: MeshInstance3D = n_root.find_child(dname, true, false) as MeshInstance3D
				if mi and mi.mesh:
					_cached_dead_trees.append(mi.mesh)
			n_root.free()

	# Warm shared materials
	get_shared_pine_bark_material()
	get_shared_pine_needle_material()
	get_shared_snag_material()

static func get_shared_pine_bark_material() -> StandardMaterial3D:
	if _shared_pine_bark_mat == null:
		_shared_pine_bark_mat = StandardMaterial3D.new()
		var alb = load("res://presentation/assets/foliage/pine_bark_base.jpg")
		if alb is Texture2D:
			_shared_pine_bark_mat.albedo_texture = alb
		_shared_pine_bark_mat.albedo_color = Color(0.85, 0.78, 0.72)
		_shared_pine_bark_mat.roughness = 0.90
		var rgh = load("res://presentation/assets/foliage/pine_bark_roughness.jpg")
		if rgh is Texture2D:
			_shared_pine_bark_mat.roughness_texture = rgh
			_shared_pine_bark_mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		var nrm = load("res://presentation/assets/foliage/pine_bark_normal.jpg")
		if nrm is Texture2D:
			_shared_pine_bark_mat.normal_enabled = true
			_shared_pine_bark_mat.normal_texture = nrm
			_shared_pine_bark_mat.normal_scale = 1.2
		_shared_pine_bark_mat.cull_mode = BaseMaterial3D.CULL_BACK
		_shared_pine_bark_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	return _shared_pine_bark_mat

static func get_shared_pine_needle_material() -> ShaderMaterial:
	if _shared_pine_needle_mat == null:
		_shared_pine_needle_mat = ShaderMaterial.new()
		_shared_pine_needle_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
		_shared_pine_needle_mat.set_shader_parameter("use_texture", true)
		_shared_pine_needle_mat.set_shader_parameter("use_vertex_color", false)
		_shared_pine_needle_mat.set_shader_parameter("use_alpha_scissor", true)
		_shared_pine_needle_mat.set_shader_parameter("alpha_scissor_threshold", 0.40)
		var needle_alb = load("res://presentation/assets/foliage/Cluster_albedo.png")
		if needle_alb is Texture2D:
			_shared_pine_needle_mat.set_shader_parameter("albedo_texture", needle_alb)
		var needle_nrm = load("res://presentation/assets/foliage/pine_leaf_normal.jpg")
		if needle_nrm is Texture2D:
			_shared_pine_needle_mat.set_shader_parameter("use_normal_texture", true)
			_shared_pine_needle_mat.set_shader_parameter("normal_texture", needle_nrm)
			_shared_pine_needle_mat.set_shader_parameter("normal_scale", 1.0)
		var needle_rgh = load("res://presentation/assets/foliage/pine_leaf_roughness.jpg")
		if needle_rgh is Texture2D:
			_shared_pine_needle_mat.set_shader_parameter("use_roughness_texture", true)
			_shared_pine_needle_mat.set_shader_parameter("roughness_texture", needle_rgh)
		_shared_pine_needle_mat.set_shader_parameter("roughness", 0.85)
		_shared_pine_needle_mat.set_shader_parameter("wind_speed", 1.15)
		_shared_pine_needle_mat.set_shader_parameter("wind_strength", 0.16)
		_shared_pine_needle_mat.set_shader_parameter("wetness", 0.0)
		_shared_pine_needle_mat.set_shader_parameter("backlight_strength", 0.16)
	return _shared_pine_needle_mat

static func get_shared_snag_material() -> StandardMaterial3D:
	if _shared_snag_mat == null:
		_shared_snag_mat = StandardMaterial3D.new()
		_shared_snag_mat.albedo_color = Color(0.42, 0.40, 0.38) # Weathered gray driftwood
		_shared_snag_mat.roughness = 0.94
	return _shared_snag_mat

# Backward compatibility accessors for existing weather & lighting callers
static func get_shared_kaykit_material() -> ShaderMaterial:
	return get_shared_pine_needle_material()

static func get_shared_kenney_material() -> ShaderMaterial:
	return get_shared_pine_needle_material()

static func get_shared_foliage_material() -> ShaderMaterial:
	return get_shared_pine_needle_material()

static func get_shared_trunk_material() -> StandardMaterial3D:
	return get_shared_pine_bark_material()

func _ready() -> void:
	_build_tree()

func _build_tree() -> void:
	_init_cache()

	var y_pos: float = position.y
	var chosen_mesh: Mesh = null
	var is_snag: bool = (archetype == TreeArchetype.SNAG)
	var base_scale: float = 0.34 * tree_scale

	# Auto-detect windswept dead snag if on high mountain ridge and not set
	if archetype == TreeArchetype.STANDARD and y_pos > 8.5 and not _cached_dead_trees.is_empty() and (abs(int(position.x * 11.0 + position.z * 5.0)) % 5 == 0):
		is_snag = true

	if is_snag and not _cached_dead_trees.is_empty():
		var idx: int = abs(int(position.x * 3.0 + position.z * 7.0)) % _cached_dead_trees.size()
		chosen_mesh = _cached_dead_trees[idx]
		base_scale = 2.6 * tree_scale
	elif not _cached_hero_pines.is_empty():
		var idx: int = abs(int(position.x * 7.0 + position.z * 13.0)) % _cached_hero_pines.size()
		chosen_mesh = _cached_hero_pines[idx]
		match archetype:
			TreeArchetype.ELDER:
				base_scale = 0.44 * tree_scale # Giant veteran pines (~15m - 17m)
			TreeArchetype.SAPLING:
				base_scale = 0.18 * tree_scale # Juvenile pines (~5m - 7m)
			TreeArchetype.CROOKED:
				base_scale = 0.30 * tree_scale
			_:
				base_scale = 0.34 * tree_scale # Standard pines (~10m - 13m)

	if chosen_mesh != null:
		var tree_inst: MeshInstance3D = MeshInstance3D.new()
		tree_inst.name = "TreeModel"
		tree_inst.mesh = chosen_mesh

		if is_snag:
			tree_inst.material_override = get_shared_snag_material()
		else:
			# Surface 0: PBR Bark
			tree_inst.set_surface_override_material(0, get_shared_pine_bark_material())
			# Surface 1: Foliage needle branch cards with wind sway
			if chosen_mesh.get_surface_count() > 1:
				tree_inst.set_surface_override_material(1, get_shared_pine_needle_material())

		tree_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		tree_inst.visibility_range_end = 115.0
		tree_inst.visibility_range_end_margin = 15.0
		tree_inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		var height_var: float = randf_range(0.92, 1.18)
		scale = Vector3(base_scale, base_scale * height_var, base_scale)

		# Natural tilt / wind-lean
		var tilt_x: float = randf_range(-0.035, 0.035)
		var tilt_z: float = randf_range(-0.035, 0.035)
		if archetype == TreeArchetype.CROOKED or is_snag:
			tilt_x = randf_range(-0.14, 0.14)
			tilt_z = randf_range(-0.14, 0.14)
		tree_inst.rotation.x = tilt_x
		tree_inst.rotation.z = tilt_z

		add_child(tree_inst)

		# Physical trunk collision body
		var col_body: StaticBody3D = StaticBody3D.new()
		col_body.name = "TrunkCollision"
		var col_shape: CollisionShape3D = CollisionShape3D.new()
		var cyl: CylinderShape3D = CylinderShape3D.new()
		var r_mult: float = 1.3 if archetype == TreeArchetype.ELDER else (0.6 if archetype == TreeArchetype.SAPLING else 1.0)
		cyl.radius = 0.28 * r_mult * tree_scale
		cyl.height = 4.5
		col_shape.shape = cyl
		col_shape.position = Vector3(0.0, 2.25, 0.0)
		col_body.add_child(col_shape)
		add_child(col_body)
		return

	# Fallback if gltf fails
	scale = Vector3.ONE * tree_scale
	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.32
	trunk_mesh.height = 3.5
	var trunk_inst: MeshInstance3D = MeshInstance3D.new()
	trunk_inst.mesh = trunk_mesh
	trunk_inst.material_override = get_shared_pine_bark_material()
	trunk_inst.position = Vector3(0.0, 1.75, 0.0)
	add_child(trunk_inst)
