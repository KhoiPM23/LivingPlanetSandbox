class_name EcosystemPresentation
extends Node3D

## Visual presentation layer for living fauna and dynamic flora.
## High-fidelity animal models with rigged skeletons and natural locomotion animations (Quaternius CC0).
## High-fidelity multi-tier vegetation models (KayKit & Kenney CC0).
## Purely reflects simulation state. Zero business logic or simulation state mutation.

var _coordinator: EcosystemCoordinator = null
var _herbivore_nodes: Dictionary = {} # int id -> Node3D
var _predator_nodes: Dictionary = {} # int id -> Node3D
var _plant_nodes: Dictionary = {} # int id -> Node3D

var _anim_time: float = 0.0

# --- STATIC PACKED SCENES (Cached for high performance & Iris Xe 60 FPS) ---
static var _stag_scene: PackedScene = null
static var _deer_scene: PackedScene = null
static var _wolf_scene: PackedScene = null

static var _plant_shrub_mesh: Mesh = null
static var _plant_shrub_mat: Material = null
static var _plant_shrub_stem_mat: StandardMaterial3D = null
static var _plant_shrub_leaf_mat: ShaderMaterial = null
static var _plant_grass_mesh: Mesh = null
static var _plant_grass_mat: Material = null

# Fallback primitive resources
var _mesh_herb_body: BoxMesh
var _mat_herb_body: StandardMaterial3D
var _mesh_herb_head: BoxMesh
var _mat_herb_head: StandardMaterial3D
var _mesh_herb_horn: CylinderMesh
var _mat_herb_horn: StandardMaterial3D

var _mesh_pred_body: BoxMesh
var _mat_pred_body: StandardMaterial3D
var _mesh_pred_head: PrismMesh
var _mat_pred_head: StandardMaterial3D
var _mesh_pred_eye: SphereMesh
var _mat_pred_eye: StandardMaterial3D

var _mesh_shrub: SphereMesh
var _mat_shrub: StandardMaterial3D
var _mesh_grass: SphereMesh
var _mat_grass: StandardMaterial3D

var _mesh_select_ring: TorusMesh
var _mat_select_ring: StandardMaterial3D
var _selection_marker: MeshInstance3D
var inspected_entity_id: int = -1

func _init() -> void:
	_init_shared_resources()
	_init_animal_templates()

static func _init_animal_templates() -> void:
	if _stag_scene != null:
		return

	_stag_scene = _load_gltf_packed("res://presentation/assets/models/Stag.gltf")
	_deer_scene = _load_gltf_packed("res://presentation/assets/models/Deer.gltf")
	_wolf_scene = _load_gltf_packed("res://presentation/assets/models/Wolf.gltf")

	# Load hero bush model
	var b_scn = _load_gltf_packed("res://presentation/assets/foliage/bush2.gltf")
	if b_scn:
		var b_root: Node = b_scn.instantiate()
		if b_root and b_root.get_child_count() > 0:
			var mi: MeshInstance3D = b_root.get_child(0) as MeshInstance3D
			if mi and mi.mesh:
				_plant_shrub_mesh = mi.mesh
		b_root.free()

	if _plant_shrub_stem_mat == null:
		_plant_shrub_stem_mat = StandardMaterial3D.new()
		var alb = load("res://presentation/assets/foliage/Lilac_bark_color.jpg")
		if alb is Texture2D:
			_plant_shrub_stem_mat.albedo_texture = alb
		var nrm = load("res://presentation/assets/foliage/Lilac_bark_normal.jpg")
		if nrm is Texture2D:
			_plant_shrub_stem_mat.normal_enabled = true
			_plant_shrub_stem_mat.normal_texture = nrm
		_plant_shrub_stem_mat.roughness = 0.88

	if _plant_shrub_leaf_mat == null:
		_plant_shrub_leaf_mat = ShaderMaterial.new()
		_plant_shrub_leaf_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
		_plant_shrub_leaf_mat.set_shader_parameter("use_texture", true)
		_plant_shrub_leaf_mat.set_shader_parameter("use_alpha_scissor", true)
		_plant_shrub_leaf_mat.set_shader_parameter("alpha_scissor_threshold", 0.45)
		var c_alb = load("res://presentation/assets/foliage/lilac_cards_color.png")
		if c_alb is Texture2D:
			_plant_shrub_leaf_mat.set_shader_parameter("albedo_texture", c_alb)
		var c_nrm = load("res://presentation/assets/foliage/lilac_cards_normal.jpg")
		if c_nrm is Texture2D:
			_plant_shrub_leaf_mat.set_shader_parameter("use_normal_texture", true)
			_plant_shrub_leaf_mat.set_shader_parameter("normal_texture", c_nrm)
		var c_rgh = load("res://presentation/assets/foliage/lilac_cards_roughness.jpg")
		if c_rgh is Texture2D:
			_plant_shrub_leaf_mat.set_shader_parameter("use_roughness_texture", true)
			_plant_shrub_leaf_mat.set_shader_parameter("roughness_texture", c_rgh)
		_plant_shrub_leaf_mat.set_shader_parameter("roughness", 0.82)
		_plant_shrub_leaf_mat.set_shader_parameter("wind_speed", 1.3)
		_plant_shrub_leaf_mat.set_shader_parameter("wind_strength", 0.20)
		_plant_shrub_leaf_mat.set_shader_parameter("backlight_strength", 0.15)
		_plant_shrub_mat = _plant_shrub_leaf_mat

	# Load plant models from forest.glb for grass
	var f_scn = _load_gltf_packed("res://presentation/assets/models/forest.glb")
	if f_scn:
		var f_root: Node = f_scn.instantiate()
		if f_root:
			var g_node: MeshInstance3D = f_root.find_child("Grass_2_D_Color1", true, false) as MeshInstance3D
			if g_node and g_node.mesh:
				_plant_grass_mesh = g_node.mesh
				if g_node.mesh.get_surface_count() > 0:
					_plant_grass_mat = g_node.mesh.surface_get_material(0)
			f_root.free()

static func _load_gltf_packed(path: String) -> PackedScene:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is PackedScene:
			return res
	return null

func _init_shared_resources() -> void:
	# Fallback herbivore resources
	_mesh_herb_body = BoxMesh.new()
	_mesh_herb_body.size = Vector3(0.7, 0.6, 1.2)
	_mat_herb_body = StandardMaterial3D.new()
	_mat_herb_body.albedo_color = Color(0.72, 0.55, 0.38)
	_mat_herb_body.roughness = 0.85

	_mesh_herb_head = BoxMesh.new()
	_mesh_herb_head.size = Vector3(0.4, 0.4, 0.5)
	_mat_herb_head = StandardMaterial3D.new()
	_mat_herb_head.albedo_color = Color(0.65, 0.48, 0.32)
	_mat_herb_head.roughness = 0.85

	_mesh_herb_horn = CylinderMesh.new()
	_mesh_herb_horn.top_radius = 0.02
	_mesh_herb_horn.bottom_radius = 0.06
	_mesh_herb_horn.height = 0.35
	_mat_herb_horn = StandardMaterial3D.new()
	_mat_herb_horn.albedo_color = Color(0.85, 0.82, 0.72)

	# Fallback predator resources
	_mesh_pred_body = BoxMesh.new()
	_mesh_pred_body.size = Vector3(0.65, 0.55, 1.4)
	_mat_pred_body = StandardMaterial3D.new()
	_mat_pred_body.albedo_color = Color(0.22, 0.25, 0.30)
	_mat_pred_body.roughness = 0.75

	_mesh_pred_head = PrismMesh.new()
	_mesh_pred_head.size = Vector3(0.45, 0.45, 0.6)
	_mat_pred_head = StandardMaterial3D.new()
	_mat_pred_head.albedo_color = Color(0.16, 0.18, 0.22)

	_mesh_pred_eye = SphereMesh.new()
	_mesh_pred_eye.radius = 0.05
	_mesh_pred_eye.height = 0.1
	_mat_pred_eye = StandardMaterial3D.new()
	_mat_pred_eye.albedo_color = Color(1.0, 0.6, 0.1)
	_mat_pred_eye.emission_enabled = true
	_mat_pred_eye.emission = Color(1.0, 0.6, 0.1)
	_mat_pred_eye.emission_energy_multiplier = 2.0

	# Fallback flora resources
	_mesh_shrub = SphereMesh.new()
	_mesh_shrub.radius = 0.5
	_mesh_shrub.height = 0.8
	_mat_shrub = StandardMaterial3D.new()
	_mat_shrub.albedo_color = Color(0.24, 0.52, 0.28)
	_mat_shrub.roughness = 0.9

	_mesh_grass = SphereMesh.new()
	_mesh_grass.radius = 0.35
	_mesh_grass.height = 0.5
	_mat_grass = StandardMaterial3D.new()
	_mat_grass.albedo_color = Color(0.38, 0.72, 0.32)
	_mat_grass.roughness = 0.9

	# Selection Indicator Resources
	_mesh_select_ring = TorusMesh.new()
	_mesh_select_ring.inner_radius = 0.95
	_mesh_select_ring.outer_radius = 1.15
	_mesh_select_ring.rings = 24
	_mesh_select_ring.ring_segments = 12
	_mat_select_ring = StandardMaterial3D.new()
	_mat_select_ring.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_select_ring.albedo_color = Color(0.25, 0.85, 1.0, 0.85)
	_mat_select_ring.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Setup Selection Marker Node
	_selection_marker = MeshInstance3D.new()
	_selection_marker.name = "InspectionSelectionRing"
	_selection_marker.mesh = _mesh_select_ring
	_selection_marker.material_override = _mat_select_ring
	_selection_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_selection_marker.visible = false
	add_child(_selection_marker)

func set_inspected_entity(id: int) -> void:
	inspected_entity_id = id
	if not _selection_marker:
		return
	if id <= 0:
		_selection_marker.visible = false
	else:
		_selection_marker.visible = true

func setup(coordinator: EcosystemCoordinator) -> void:
	_coordinator = coordinator

func _process(delta: float) -> void:
	if not _coordinator or not is_visible_in_tree():
		return

	_anim_time += delta
	_update_herbivores(delta)
	_update_predators(delta)
	# NOTE: Plant visual nodes are intentionally NOT rendered here.
	# VegetationScatter already places flora visuals deterministically across the terrain.
	# Rendering ecosystem plant nodes separately would cause visual overlap/doubling.
	# Flora simulation state is tracked internally but has no separate 3D representation.
	_update_selection_marker(delta)

func _update_selection_marker(delta: float) -> void:
	if not _selection_marker or not _selection_marker.visible:
		return
	_selection_marker.rotation.y += delta * 2.0

	var target_node: Node3D = null
	if _herbivore_nodes.has(inspected_entity_id):
		target_node = _herbivore_nodes[inspected_entity_id]
	elif _predator_nodes.has(inspected_entity_id):
		target_node = _predator_nodes[inspected_entity_id]
	elif _plant_nodes.has(inspected_entity_id):
		target_node = _plant_nodes[inspected_entity_id]

	if target_node and is_instance_valid(target_node):
		_selection_marker.position = target_node.position + Vector3(0.0, 0.05, 0.0)
		var base_scale: float = target_node.scale.x * 1.15
		_selection_marker.scale = Vector3(base_scale, 1.0, base_scale)
	else:
		_selection_marker.visible = false

func _play_anim(anim: AnimationPlayer, anim_name: String, blend_time: float = 0.2) -> void:
	if not anim or anim.current_animation == anim_name:
		return
	if anim.has_animation(anim_name):
		anim.play(anim_name, blend_time)

func _update_herbivores(delta: float) -> void:
	var active_herbivores: Array = _coordinator.fauna_sim.get_all_herbivores()
	var active_ids: Dictionary = {}

	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
	var cam_pos: Vector3 = cam.global_position if (cam and cam.is_inside_tree()) else Vector3(0.0, 15.0, 25.0)

	for h in active_herbivores:
		active_ids[h.id] = true
		var node: Node3D = _herbivore_nodes.get(h.id, null)
		if node == null:
			node = _create_herbivore_mesh(h.genome, h.id)
			add_child(node)
			_herbivore_nodes[h.id] = node
			node.position = h.position

		var target_pos: Vector3 = h.position
		var current_speed: float = h.velocity.length()
		var is_moving: bool = current_speed > 0.08
		var anim: AnimationPlayer = (node.get_meta("anim_player") as AnimationPlayer) if node.has_meta("anim_player") else null
		var dist_to_cam: float = node.position.distance_to(cam_pos)
		var is_distant: bool = dist_to_cam > 55.0

		# Authentic animation state machine with exact stride-matched speed scaling
		if anim:
			match h.state:
				FaunaSimulation.HerbivoreState.DRINKING:
					anim.speed_scale = 1.0
					_play_anim(anim, "Idle_Headlow", 0.30)
				FaunaSimulation.HerbivoreState.ALERT:
					anim.speed_scale = 1.0
					_play_anim(anim, "Idle_2", 0.18)
				FaunaSimulation.HerbivoreState.RESTING:
					anim.speed_scale = 1.0
					_play_anim(anim, "Idle_Headlow", 0.35)
				FaunaSimulation.HerbivoreState.EATING:
					anim.speed_scale = 1.0
					_play_anim(anim, "Eating", 0.20)
				FaunaSimulation.HerbivoreState.FLEEING:
					# Stride matching for Gallop: ~3.75 m/s base stride
					anim.speed_scale = clampf(current_speed / 3.75, 0.75, 1.65)
					_play_anim(anim, "Gallop", 0.15)
				FaunaSimulation.HerbivoreState.STARVING:
					if is_moving:
						anim.speed_scale = clampf(current_speed / 1.55, 0.55, 1.15)
						_play_anim(anim, "Walk", 0.25)
					else:
						anim.speed_scale = 1.0
						_play_anim(anim, "Idle_HitReact1", 0.30)
				_: # WANDERING, FORAGING
					if is_moving:
						# Stride matching for Walk: ~1.55 m/s base stride
						anim.speed_scale = clampf(current_speed / 1.55, 0.65, 1.45)
						_play_anim(anim, "Walk", 0.22)
					else:
						anim.speed_scale = 1.0
						# Dynamic idle posture shifts (Idle -> Idle_2 head look -> Idle_Headlow ground sniff)
						var idle_timer: float = float(node.get_meta("idle_timer", 0.0)) + delta
						var idle_dur: float = float(node.get_meta("idle_dur", 6.0))
						var cur_idle: String = String(node.get_meta("idle_clip", "Idle"))
						if idle_timer >= idle_dur:
							idle_timer = 0.0
							var r: float = randf()
							if r < 0.45:
								cur_idle = "Idle"
							elif r < 0.80:
								cur_idle = "Idle_2"
							else:
								cur_idle = "Idle_Headlow"
							node.set_meta("idle_dur", randf_range(5.0, 9.5))
							node.set_meta("idle_clip", cur_idle)
						node.set_meta("idle_timer", idle_timer)
						_play_anim(anim, cur_idle, 0.32)
		else:
			# Fallback bobbing if using primitive models
			var head_node: Node3D = node.get_node_or_null("Head") as Node3D
			if head_node:
				if h.state == FaunaSimulation.HerbivoreState.EATING or h.state == FaunaSimulation.HerbivoreState.DRINKING:
					head_node.rotation.x = lerp_angle(head_node.rotation.x, deg_to_rad(32.0), clampf(delta * 10.0, 0.0, 1.0))
				else:
					head_node.rotation.x = lerp_angle(head_node.rotation.x, 0.0, clampf(delta * 8.0, 0.0, 1.0))

		node.position = node.position.lerp(target_pos, clampf(delta * 12.0, 0.0, 1.0))

		# Smooth natural rotation toward travel direction (GLTF forward is -Z) with rate-limited turning
		if is_moving:
			var target_rot_y: float = atan2(-h.velocity.x, -h.velocity.z) if anim != null else atan2(h.velocity.x, h.velocity.z)
			var max_angular_speed: float = 6.2 if h.state == FaunaSimulation.HerbivoreState.FLEEING else 4.2
			var diff: float = angle_difference(node.rotation.y, target_rot_y)
			node.rotation.y = wrapf(node.rotation.y + clampf(diff, -delta * max_angular_speed, delta * max_angular_speed), -PI, PI)
		elif h.state == FaunaSimulation.HerbivoreState.ALERT:
			# When alert, orient body towards vigilance heading
			var target_rot_y: float = atan2(-cos(h.heading), -sin(h.heading)) if anim != null else h.heading
			var diff: float = angle_difference(node.rotation.y, target_rot_y)
			node.rotation.y = wrapf(node.rotation.y + clampf(diff, -delta * 3.6, delta * 3.6), -PI, PI)

		# Dual-Axis terrain slope conformance: Pitch (forward/back) and Roll (left/right sidehill)
		if _coordinator and _coordinator.terrain_height_func.is_valid():
			var fwd_x: float = -sin(node.rotation.y)
			var fwd_z: float = -cos(node.rotation.y)
			var h_fwd: float = _coordinator.terrain_height_func.call(node.position.x + fwd_x * 0.7, node.position.z + fwd_z * 0.7)
			var h_back: float = _coordinator.terrain_height_func.call(node.position.x - fwd_x * 0.7, node.position.z - fwd_z * 0.7)
			if is_finite(h_fwd) and is_finite(h_back):
				var target_pitch: float = clampf(atan2(h_fwd - h_back, 1.4), -0.65, 0.65)
				node.rotation.x = wrapf(lerp_angle(node.rotation.x, target_pitch, clampf(delta * 7.0, 0.0, 1.0)), -PI, PI)

			if not is_distant:
				var right_x: float = cos(node.rotation.y)
				var right_z: float = -sin(node.rotation.y)
				var h_right: float = _coordinator.terrain_height_func.call(node.position.x + right_x * 0.35, node.position.z + right_z * 0.35)
				var h_left: float = _coordinator.terrain_height_func.call(node.position.x - right_x * 0.35, node.position.z - right_z * 0.35)
				if is_finite(h_right) and is_finite(h_left):
					var target_roll: float = clampf(atan2(h_right - h_left, 0.7), -0.55, 0.55)
					node.rotation.z = wrapf(lerp_angle(node.rotation.z, target_roll, clampf(delta * 7.0, 0.0, 1.0)), -PI, PI)
			else:
				node.rotation.z = wrapf(lerp_angle(node.rotation.z, 0.0, clampf(delta * 4.0, 0.0, 1.0)), -PI, PI)

		# Phenotypic trait scale
		var base_scale: float = 0.58 if (h.id % 2 == 0) else 0.52
		var life_mult: float = 0.55 if h.life_stage == FaunaSimulation.LifeStage.JUVENILE else 1.0
		var trait_mult: float = h.genome.size_scale if h.genome else 1.0
		var final_scale: float = base_scale * life_mult * trait_mult

		if not is_equal_approx(node.scale.x, final_scale):
			node.scale = Vector3(final_scale, final_scale, final_scale)

	for id: int in _herbivore_nodes.keys():
		if not active_ids.has(id):
			_herbivore_nodes[id].queue_free()
			_herbivore_nodes.erase(id)

func _update_predators(delta: float) -> void:
	var active_predators: Array = _coordinator.fauna_sim.get_all_predators()
	var active_ids: Dictionary = {}

	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
	var cam_pos: Vector3 = cam.global_position if (cam and cam.is_inside_tree()) else Vector3(0.0, 15.0, 25.0)

	for p in active_predators:
		active_ids[p.id] = true
		var node: Node3D = _predator_nodes.get(p.id, null)
		if node == null:
			node = _create_predator_mesh(p.genome, p.id)
			add_child(node)
			_predator_nodes[p.id] = node
			node.position = p.position

		var target_pos: Vector3 = p.position
		var current_speed: float = p.velocity.length()
		var is_moving: bool = current_speed > 0.08
		var anim: AnimationPlayer = (node.get_meta("anim_player") as AnimationPlayer) if node.has_meta("anim_player") else null
		var dist_to_cam: float = node.position.distance_to(cam_pos)
		var is_distant: bool = dist_to_cam > 55.0

		# Authentic predator animation state machine with stride-matched speed scaling
		if anim:
			match p.state:
				FaunaSimulation.PredatorState.DRINKING:
					anim.speed_scale = 1.0
					_play_anim(anim, "Idle_2_HeadLow", 0.30)
				FaunaSimulation.PredatorState.ALERT:
					anim.speed_scale = 1.0
					_play_anim(anim, "Idle_2", 0.18)
				FaunaSimulation.PredatorState.RESTING:
					anim.speed_scale = 1.0
					_play_anim(anim, "Idle_2_HeadLow", 0.35)
				FaunaSimulation.PredatorState.EATING:
					anim.speed_scale = 1.0
					_play_anim(anim, "Eating", 0.20)
				FaunaSimulation.PredatorState.HUNTING:
					# Stride matching for predator Gallop: ~4.00 m/s base stride
					anim.speed_scale = clampf(current_speed / 4.00, 0.75, 1.65)
					_play_anim(anim, "Gallop", 0.15)
				FaunaSimulation.PredatorState.STARVING:
					if is_moving:
						anim.speed_scale = clampf(current_speed / 1.65, 0.55, 1.20)
						_play_anim(anim, "Walk", 0.25)
					else:
						anim.speed_scale = 1.0
						_play_anim(anim, "Idle_HitReact1", 0.30)
				_: # WANDERING
					if is_moving:
						# Stride matching for predator Walk: ~1.65 m/s base stride
						anim.speed_scale = clampf(current_speed / 1.65, 0.65, 1.45)
						_play_anim(anim, "Walk", 0.22)
					else:
						anim.speed_scale = 1.0
						# Dynamic predator posture shifts (Idle alert scan -> Idle_2 look -> Idle_2_HeadLow scent sniff)
						var idle_timer: float = float(node.get_meta("idle_timer", 0.0)) + delta
						var idle_dur: float = float(node.get_meta("idle_dur", 5.5))
						var cur_idle: String = String(node.get_meta("idle_clip", "Idle"))
						if idle_timer >= idle_dur:
							idle_timer = 0.0
							var r: float = randf()
							if r < 0.40:
								cur_idle = "Idle"
							elif r < 0.75:
								cur_idle = "Idle_2"
							else:
								cur_idle = "Idle_2_HeadLow"
							node.set_meta("idle_dur", randf_range(4.5, 8.5))
							node.set_meta("idle_clip", cur_idle)
						node.set_meta("idle_timer", idle_timer)
						_play_anim(anim, cur_idle, 0.30)
		else:
			var head_node: Node3D = node.get_node_or_null("Head") as Node3D
			if head_node:
				if p.state == FaunaSimulation.PredatorState.EATING or p.state == FaunaSimulation.PredatorState.DRINKING:
					head_node.rotation.x = lerp_angle(head_node.rotation.x, deg_to_rad(-60.0), clampf(delta * 10.0, 0.0, 1.0))
				else:
					head_node.rotation.x = lerp_angle(head_node.rotation.x, deg_to_rad(-90.0), clampf(delta * 8.0, 0.0, 1.0))

		node.position = node.position.lerp(target_pos, clampf(delta * 12.0, 0.0, 1.0))

		if is_moving:
			var target_rot_y: float = atan2(-p.velocity.x, -p.velocity.z) if anim != null else atan2(p.velocity.x, p.velocity.z)
			var max_pred_angular_speed: float = 6.8 if p.state == FaunaSimulation.PredatorState.HUNTING else 4.5
			var diff: float = angle_difference(node.rotation.y, target_rot_y)
			node.rotation.y = wrapf(node.rotation.y + clampf(diff, -delta * max_pred_angular_speed, delta * max_pred_angular_speed), -PI, PI)
		elif p.state == FaunaSimulation.PredatorState.ALERT:
			var target_rot_y: float = atan2(-cos(p.heading), -sin(p.heading)) if anim != null else p.heading
			var diff: float = angle_difference(node.rotation.y, target_rot_y)
			node.rotation.y = wrapf(node.rotation.y + clampf(diff, -delta * 3.8, delta * 3.8), -PI, PI)

		# Dual-Axis predator slope pitch and roll conformance
		if _coordinator and _coordinator.terrain_height_func.is_valid():
			var fwd_x: float = -sin(node.rotation.y)
			var fwd_z: float = -cos(node.rotation.y)
			var h_fwd: float = _coordinator.terrain_height_func.call(node.position.x + fwd_x * 0.6, node.position.z + fwd_z * 0.6)
			var h_back: float = _coordinator.terrain_height_func.call(node.position.x - fwd_x * 0.6, node.position.z - fwd_z * 0.6)
			if is_finite(h_fwd) and is_finite(h_back):
				var target_pitch: float = clampf(atan2(h_fwd - h_back, 1.2), -0.65, 0.65)
				node.rotation.x = wrapf(lerp_angle(node.rotation.x, target_pitch, clampf(delta * 7.0, 0.0, 1.0)), -PI, PI)

			if not is_distant:
				var right_x: float = cos(node.rotation.y)
				var right_z: float = -sin(node.rotation.y)
				var h_right: float = _coordinator.terrain_height_func.call(node.position.x + right_x * 0.30, node.position.z + right_z * 0.30)
				var h_left: float = _coordinator.terrain_height_func.call(node.position.x - right_x * 0.30, node.position.z - right_z * 0.30)
				if is_finite(h_right) and is_finite(h_left):
					var target_roll: float = clampf(atan2(h_right - h_left, 0.6), -0.55, 0.55)
					node.rotation.z = wrapf(lerp_angle(node.rotation.z, target_roll, clampf(delta * 7.0, 0.0, 1.0)), -PI, PI)
			else:
				node.rotation.z = wrapf(lerp_angle(node.rotation.z, 0.0, clampf(delta * 4.0, 0.0, 1.0)), -PI, PI)

		var base_scale: float = 0.46
		var trait_mult: float = p.genome.size_scale if p.genome else 1.0
		var final_scale: float = base_scale * trait_mult

		if not is_equal_approx(node.scale.x, final_scale):
			node.scale = Vector3(final_scale, final_scale, final_scale)

	for id: int in _predator_nodes.keys():
		if not active_ids.has(id):
			_predator_nodes[id].queue_free()
			_predator_nodes.erase(id)

## Plant visual rendering is suppressed: VegetationScatter handles all flora visuals.
## This function is kept for API compatibility but does NOT instantiate any nodes.
## Flora simulation state tracking continues internally via EcosystemCoordinator.
func _update_plants() -> void:
	pass

static func _find_mesh_instances(node: Node, out_arr: Array) -> void:
	if node is MeshInstance3D:
		out_arr.append(node)
	for c in node.get_children():
		_find_mesh_instances(c, out_arr)

## High-fidelity rigged herbivore (Stag / Deer) with Skeletal Mesh & Locomotion Animations
func _create_herbivore_mesh(genome: EcosystemGenome = null, entity_id: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "HerbivoreView_" + str(entity_id)

	# Compatibility node
	var dummy_head: Node3D = Node3D.new()
	dummy_head.name = "Head"
	root.add_child(dummy_head)

	# Select model variation: Stag (Male with horns) or Deer (Female doe)
	var scene_to_inst: PackedScene = _stag_scene if (entity_id % 2 == 0 and _stag_scene != null) else _deer_scene
	if scene_to_inst == null and _stag_scene != null:
		scene_to_inst = _stag_scene

	if scene_to_inst != null:
		var model_inst: Node3D = scene_to_inst.instantiate() as Node3D
		var anim: AnimationPlayer = model_inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim:
			root.set_meta("anim_player", anim)
			anim.play("Idle")

		# Apply natural fur material, soft specular fur sheen, and phenotype coat tint
		var meshes: Array = []
		_find_mesh_instances(model_inst, meshes)
		for mesh_node in meshes:
			if mesh_node is MeshInstance3D and mesh_node.mesh:
				mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				for s in range(mesh_node.mesh.get_surface_count()):
					var m = mesh_node.mesh.surface_get_material(s)
					if m is StandardMaterial3D:
						var custom_mat: StandardMaterial3D = m.duplicate()
						custom_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
						custom_mat.roughness = 0.82
						custom_mat.metallic_specular = 0.22
						if genome and s == 0 and genome.coat_tint != Color(0.72, 0.55, 0.38):
							custom_mat.albedo_color = genome.coat_tint
						mesh_node.set_surface_override_material(s, custom_mat)

		root.add_child(model_inst)
		var base_scale: float = 0.58 if (entity_id % 2 == 0) else 0.52
		if genome:
			root.scale = Vector3.ONE * (base_scale * genome.size_scale)
		else:
			root.scale = Vector3.ONE * base_scale
		return root

	# Fallback primitive model
	var body_inst: MeshInstance3D = MeshInstance3D.new()
	body_inst.name = "Body"
	body_inst.mesh = _mesh_herb_body
	body_inst.material_override = _mat_herb_body
	body_inst.position = Vector3(0.0, 0.5, 0.0)
	root.add_child(body_inst)

	var head_inst: MeshInstance3D = MeshInstance3D.new()
	head_inst.name = "Head"
	head_inst.mesh = _mesh_herb_head
	head_inst.material_override = _mat_herb_head
	head_inst.position = Vector3(0.0, 0.85, 0.5)
	root.add_child(head_inst)

	var horn_left: MeshInstance3D = MeshInstance3D.new()
	horn_left.name = "HornLeft"
	horn_left.mesh = _mesh_herb_horn
	horn_left.material_override = _mat_herb_horn
	horn_left.position = Vector3(-0.15, 1.15, 0.45)
	horn_left.rotation_degrees = Vector3(15, 0, -15)
	root.add_child(horn_left)

	var horn_right: MeshInstance3D = MeshInstance3D.new()
	horn_right.name = "HornRight"
	horn_right.mesh = _mesh_herb_horn
	horn_right.material_override = _mat_herb_horn
	horn_right.position = Vector3(0.15, 1.15, 0.45)
	horn_right.rotation_degrees = Vector3(15, 0, 15)
	root.add_child(horn_right)

	if genome:
		root.scale = Vector3.ONE * genome.size_scale

	return root

## High-fidelity rigged predator (Wolf) with Skeletal Mesh & Locomotion Animations
func _create_predator_mesh(genome: EcosystemGenome = null, entity_id: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "PredatorView_" + str(entity_id)

	var dummy_head: Node3D = Node3D.new()
	dummy_head.name = "Head"
	root.add_child(dummy_head)

	if _wolf_scene != null:
		var model_inst: Node3D = _wolf_scene.instantiate() as Node3D
		var anim: AnimationPlayer = model_inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim:
			root.set_meta("anim_player", anim)
			anim.play("Idle")

		var meshes: Array = []
		_find_mesh_instances(model_inst, meshes)
		for mesh_node in meshes:
			if mesh_node is MeshInstance3D and mesh_node.mesh:
				mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				for s in range(mesh_node.mesh.get_surface_count()):
					var m = mesh_node.mesh.surface_get_material(s)
					if m is StandardMaterial3D:
						var custom_mat: StandardMaterial3D = m.duplicate()
						custom_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
						custom_mat.roughness = 0.80
						custom_mat.metallic_specular = 0.22
						if genome and s == 0 and genome.coat_tint != Color(0.15, 0.15, 0.16):
							custom_mat.albedo_color = genome.coat_tint
						mesh_node.set_surface_override_material(s, custom_mat)

		root.add_child(model_inst)
		var base_scale: float = 0.46
		if genome:
			root.scale = Vector3.ONE * (base_scale * genome.size_scale)
		else:
			root.scale = Vector3.ONE * base_scale
		return root

	# Fallback primitive model
	var body_inst: MeshInstance3D = MeshInstance3D.new()
	body_inst.name = "Body"
	body_inst.mesh = _mesh_pred_body
	body_inst.material_override = _mat_pred_body
	body_inst.position = Vector3(0.0, 0.45, 0.0)
	root.add_child(body_inst)

	var head_inst: MeshInstance3D = MeshInstance3D.new()
	head_inst.name = "Head"
	head_inst.mesh = _mesh_pred_head
	head_inst.material_override = _mat_pred_head
	head_inst.position = Vector3(0.0, 0.6, 0.7)
	head_inst.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(head_inst)

	var eye_l: MeshInstance3D = MeshInstance3D.new()
	eye_l.mesh = _mesh_pred_eye
	eye_l.material_override = _mat_pred_eye
	eye_l.position = Vector3(-0.12, 0.62, 0.82)
	root.add_child(eye_l)

	var eye_r: MeshInstance3D = MeshInstance3D.new()
	eye_r.mesh = _mesh_pred_eye
	eye_r.material_override = _mat_pred_eye
	eye_r.position = Vector3(0.12, 0.62, 0.82)
	root.add_child(eye_r)

	if genome:
		root.scale = Vector3.ONE * genome.size_scale

	return root

## High-fidelity plant mesh using natural foliage models
func _create_plant_mesh(species: String, genome: EcosystemGenome = null) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "PlantView_" + species

	var inst: MeshInstance3D = MeshInstance3D.new()

	if species == "shrub_bush":
		if _plant_shrub_mesh:
			inst.mesh = _plant_shrub_mesh
			if _plant_shrub_mesh.get_surface_count() > 1:
				inst.set_surface_override_material(0, _plant_shrub_stem_mat)
				inst.set_surface_override_material(1, _plant_shrub_leaf_mat)
			elif _plant_shrub_mat:
				inst.material_override = _plant_shrub_mat
			inst.scale = Vector3.ONE * 0.85
		else:
			inst.mesh = _mesh_shrub
			inst.material_override = _mat_shrub
			inst.position = Vector3(0.0, _mesh_shrub.height * 0.5, 0.0)
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		if _plant_grass_mesh:
			inst.mesh = _plant_grass_mesh
			if _plant_grass_mat:
				inst.material_override = _plant_grass_mat
			inst.scale = Vector3.ONE * 0.7
		else:
			inst.mesh = _mesh_grass
			inst.material_override = _mat_grass
			inst.position = Vector3(0.0, _mesh_grass.height * 0.5, 0.0)
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	root.add_child(inst)
	if genome:
		root.scale = Vector3.ONE * genome.size_scale
	return root

func clear() -> void:
	for node: Node3D in _herbivore_nodes.values():
		node.queue_free()
	_herbivore_nodes.clear()

	for node: Node3D in _predator_nodes.values():
		node.queue_free()
	_predator_nodes.clear()

	for node: Node3D in _plant_nodes.values():
		node.queue_free()
	_plant_nodes.clear()

## Returns the 3D visual scene node representing an entity, or null if uninstantiated
func get_entity_node(id: int) -> Node3D:
	if _herbivore_nodes.has(id):
		return _herbivore_nodes[id]
	if _predator_nodes.has(id):
		return _predator_nodes[id]
	if _plant_nodes.has(id):
		return _plant_nodes[id]
	return null

## Returns the current global position of an entity presentation node, or Vector3.ZERO
func get_entity_position(id: int) -> Vector3:
	var n: Node3D = get_entity_node(id)
	if is_instance_valid(n):
		return n.global_position
	return Vector3.ZERO
