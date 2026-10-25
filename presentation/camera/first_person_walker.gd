class_name FirstPersonWalker
extends CharacterBody3D

## Living Planet Sandbox — Block 15 Player Character & Exploration Controller.
## High-feel third-person and first-person locomotion inspired by AAA wilderness titles:
## - Full 3D skinned humanoid character mesh (MIT-licensed Godot 3D model)
## - Weighty locomotion state machine: Idle, Start Moving, Walk, Sprint, Stopping, Jump, Fall, Landing
## - Dynamic slope adaptation: slope resistance on climbs and subtle terrain normal body alignment
## - State-dependent turn rates with dynamic banking lean during high-speed turns
## - Animation-synchronized footstep sound synthesis (grass/loam, stone/scree, shallow water)
## - Landing impact shock absorption with knee compression and ground thud
## - SpringArm3D collision-avoiding camera with smooth zoom, dynamic sprint FOV, and head-clip occlusion protection

signal perspective_changed(is_third_person: bool)
signal footstep_played(surface_type: String)

const WildernessTorchSystem = preload("res://presentation/tools/wilderness_torch_system.gd")
const PlayerStaminaController = preload("res://presentation/character/player_stamina_controller.gd")
const PlayerWardrobeSystem = preload("res://presentation/character/wardrobe/player_wardrobe_system.gd")
const CharacterRegistrySystem = preload("res://presentation/character/character_registry_system.gd")

signal landing_impact_occurred(fall_speed: float)
signal glider_state_changed(is_gliding: bool)
signal weapon_stance_changed(is_drawn: bool)
signal attack_executed(combo_index: int, damage: int)
signal selfie_mode_changed(is_selfie: bool)
signal selfie_captured(photo_data: Dictionary)
signal mount_state_changed(is_mounted: bool)
signal stamina_changed(current: float, max_val: float, ratio: float)
signal climb_state_changed(is_climbing: bool)
signal outfit_changed(is_bikini: bool)

enum LocomotionState {
	IDLE = 0,
	START_MOVING = 1,
	WALK = 2,
	SPRINT = 3,
	STOPPING = 4,
	JUMP = 5,
	FALLING = 6,
	LANDING = 7,
	CLIMBING = 8
}

# --- MOVEMENT SETTINGS ---
@export var walk_speed: float = 3.6
@export var sprint_speed: float = 7.5
@export var crouch_speed: float = 1.45
@export var jump_velocity: float = 5.6
@export var gravity: float = 19.6
@export var turn_speed: float = 12.0
@export var sprint_turn_speed: float = 7.5
@export var acceleration: float = 16.0
@export var deceleration: float = 14.0
@export var eye_height: float = 1.65
@export var glide_speed: float = 8.8
@export var glide_sink_rate: float = -1.8

# --- CAMERA SETTINGS ---
@export var mouse_sensitivity: float = 0.0028
@export var mouse_sensitivity_x: float = 0.0028
@export var mouse_sensitivity_y: float = 0.0028
@export var invert_y: bool = false
@export var camera_distance: float = 3.2
@export var min_camera_distance: float = 1.6
@export var max_camera_distance: float = 5.5
@export var min_pitch: float = deg_to_rad(-72.0)
@export var max_pitch: float = deg_to_rad(65.0)
@export var shoulder_offset_x: float = 0.28
@export var shoulder_height: float = 1.45
@export var base_fov: float = 75.0
@export var sprint_fov: float = 80.0

# --- STATE VARIABLES ---
var is_third_person: bool = true
var is_crouching: bool = false
var _terrain: IslandTerrain = null
var _capsule: CapsuleShape3D = null
var _collision_shape: CollisionShape3D = null

# Child nodes
var _model_root: Node3D = null
var _character_instance: Node3D = null
var _anim_player: AnimationPlayer = null
var _spring_arm: SpringArm3D = null
var _camera: Camera3D = null
var _audio_player: AudioStreamPlayer3D = null
var torch_system: WildernessTorchSystem = null

# Camera rotation & zoom smoothing
var _cam_yaw: float = 0.0
var _cam_pitch: float = deg_to_rad(-10.0)
var _target_cam_yaw: float = 0.0
var _target_cam_pitch: float = deg_to_rad(-10.0)
var _target_camera_distance: float = 3.2
var _cam_yaw_vel: float = 0.0
var _cam_pitch_vel: float = 0.0
var is_selfie_mode: bool = false
var active_mount: Node3D = null
static var _shutter_wav: AudioStreamWAV = null

# Locomotion & Body Orientation
var _model_yaw: float = 0.0
var _model_slope_pitch: float = 0.0
var _model_slope_roll: float = 0.0
var _model_lean_roll: float = 0.0
var _loco_state: LocomotionState = LocomotionState.IDLE
var _is_sprinting: bool = false
var _current_anim: String = ""
var _anime_animator: RefCounted = null
var _facial_controller: RefCounted = null # AnimeFacialController
var _weapon_system: Node3D = null # AnimeWeaponSystem
var wardrobe: PlayerWardrobeSystem = null
var character_registry: CharacterRegistrySystem = null

# AAA Game Feel & Locomotion (Genshin Traversal + RDR2 Weight + GTA V Responsiveness)
var _skid_timer: float = 0.0
var _skid_pitch: float = 0.0
var _dash_impulse_timer: float = 0.0
var _was_sprinting_prev: bool = false

var is_bikini_outfit: bool = false
var _body_mesh_instance: MeshInstance3D = null
var _default_body_mesh: Mesh = null
var _bikini_body_mesh: ArrayMesh = null
var _nude_body_mesh: ArrayMesh = null
var _default_body_materials: Array[Material] = []
var _transparent_cloth_mat: StandardMaterial3D = null
var _bikini_skin_mat: StandardMaterial3D = null
var _character_skeleton: Skeleton3D = null
var _bust_l1_bone: int = -1
var _bust_l2_bone: int = -1
var _bust_r1_bone: int = -1
var _bust_r2_bone: int = -1
var _hips_bone: int = -1
var _spine_bone: int = -1
var _shoulder_l_bone: int = -1
var _shoulder_r_bone: int = -1

# --- MULTI-CHARACTER SYSTEM ---
# 0 = Anime Hero (default), 1 = Douyin Asian Beauty
var _active_character: int = 0
var _douyin_instance: Node3D = null
var _douyin_skeleton: Skeleton3D = null
var _douyin_body_mesh_instance: MeshInstance3D = null
var _douyin_default_body_mesh: Mesh = null
var _douyin_default_body_materials: Array[Material] = []
var _douyin_bikini_body_mesh: ArrayMesh = null
var _douyin_nude_body_mesh: ArrayMesh = null
var _douyin_bikini_mat: StandardMaterial3D = null
var _douyin_nude_mat: StandardMaterial3D = null
var _douyin_bust_l1_bone: int = -1
var _douyin_bust_l2_bone: int = -1
var _douyin_bust_r1_bone: int = -1
var _douyin_bust_r2_bone: int = -1
var _douyin_hips_bone: int = -1
var _douyin_spine_bone: int = -1
var _douyin_shoulder_l_bone: int = -1
var _douyin_shoulder_r_bone: int = -1
var _douyin_outfit_mode: int = 0 # 0 = white bikini, 1 = nude B-cup
var _douyin_bra_root: Node3D = null

# Ground & Landing Physical Feel
var _was_on_ground: bool = true
var _last_air_y_velocity: float = 0.0
var _land_timer: float = 0.0
var _land_compression: float = 0.0

# Genshin-Style Elemental Anemo Glider
var is_gliding: bool = false
var _prev_want_jump: bool = false
var _glider_root: Node3D = null
var _glider_particles: GPUParticles3D = null
static var _glider_swoosh_wav: AudioStreamWAV = null

# Footstep Animation Tracking
var _last_anim_pos: float = 0.0

# Procedural Audio Cache
static var _step_grass_wav: AudioStreamWAV = null
static var _step_stone_wav: AudioStreamWAV = null
static var _step_water_wav: AudioStreamWAV = null
static var _step_sand_wav: AudioStreamWAV = null
static var _step_snow_wav: AudioStreamWAV = null
static var _land_thud_wav: AudioStreamWAV = null

# Genshin Traversal: Stamina & Cliff Climbing
var stamina: PlayerStaminaController = null
var is_climbing: bool = false
var _climb_wall_normal: Vector3 = Vector3.FORWARD
var _climb_cooldown: float = 0.0
var _wall_check_ray: RayCast3D = null
var _ledge_check_ray: RayCast3D = null
var _cam_shake_offset: Vector3 = Vector3.ZERO

func _init() -> void:
	stamina = PlayerStaminaController.new(100.0)
	stamina.stamina_changed.connect(func(curr: float, max_val: float, ratio: float):
		stamina_changed.emit(curr, max_val, ratio)
	)

	wardrobe = PlayerWardrobeSystem.new()
	character_registry = CharacterRegistrySystem.new()
	wardrobe.outfit_changed.connect(func(_id: String, _name: String, is_bikini: bool):
		outfit_changed.emit(is_bikini)
	)

	collision_layer = 2 # Player layer
	collision_mask = 1  # StaticBody3D terrain, props, boulders, trees
	floor_max_angle = deg_to_rad(48.0)
	floor_snap_length = 0.40
	floor_stop_on_slope = true
	floor_constant_speed = true

	_build_collision()
	_build_camera_rig()
	_init_procedural_audio()

var _dash_particles: GPUParticles3D = null
var _water_ripple_particles: GPUParticles3D = null

func _ready() -> void:
	if not _collision_shape:
		_build_collision()
	_build_model()
	_build_camera_rig()
	_build_audio_emitter()
	_setup_animations()
	_build_anime_particles()
	_build_glider_wings()
	_ensure_torch_system()
	_build_climb_rays()

	if wardrobe:
		wardrobe.setup_anime(_body_mesh_instance, _character_skeleton, _default_body_materials)
		wardrobe.on_weapon_visibility_changed = func(vis: bool):
			if _weapon_system:
				_weapon_system.visible = vis
		wardrobe.on_face_material_requested = func(mat: Material):
			if _character_instance:
				var face_node = _character_instance.find_child("Face", true, false) as MeshInstance3D
				if face_node:
					face_node.set_surface_override_material(3, mat)


func _build_climb_rays() -> void:
	if _wall_check_ray:
		return
	_wall_check_ray = RayCast3D.new()
	_wall_check_ray.name = "ClimbWallRay"
	_wall_check_ray.position = Vector3(0.0, 1.05, 0.0)
	_wall_check_ray.target_position = Vector3(0.0, 0.0, -0.95)
	_wall_check_ray.collision_mask = 1
	_wall_check_ray.enabled = true
	add_child(_wall_check_ray)

	_ledge_check_ray = RayCast3D.new()
	_ledge_check_ray.name = "ClimbLedgeRay"
	_ledge_check_ray.position = Vector3(0.0, 2.15, 0.0)
	_ledge_check_ray.target_position = Vector3(0.0, 0.0, -0.95)
	_ledge_check_ray.collision_mask = 1
	_ledge_check_ray.enabled = true
	add_child(_ledge_check_ray)

func _build_anime_particles() -> void:
	if _dash_particles:
		return
	_dash_particles = GPUParticles3D.new()
	_dash_particles.name = "AnimeDashParticles"
	_dash_particles.amount = 16
	_dash_particles.lifetime = 0.32
	_dash_particles.emitting = false
	_dash_particles.position = Vector3(0.0, 0.12, 0.0)

	var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	p_mat.emission_sphere_radius = 0.20
	p_mat.direction = Vector3(0.0, 0.3, 1.0)
	p_mat.spread = 30.0
	p_mat.initial_velocity_min = 1.0
	p_mat.initial_velocity_max = 2.2
	p_mat.gravity = Vector3(0.0, 0.4, 0.0)
	p_mat.scale_min = 0.05
	p_mat.scale_max = 0.12
	p_mat.color = Color(1.0, 1.0, 1.0, 0.65)
	_dash_particles.process_material = p_mat

	var p_mesh: SphereMesh = SphereMesh.new()
	p_mesh.radius = 0.06
	p_mesh.height = 0.12
	var s_mat: StandardMaterial3D = StandardMaterial3D.new()
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.albedo_color = Color(0.92, 0.96, 1.0, 0.55)
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mesh.material = s_mat
	_dash_particles.draw_pass_1 = p_mesh
	add_child(_dash_particles)

	# Water wading expanding ripple rings
	_water_ripple_particles = GPUParticles3D.new()
	_water_ripple_particles.name = "WaterRippleParticles"
	_water_ripple_particles.amount = 8
	_water_ripple_particles.lifetime = 0.65
	_water_ripple_particles.emitting = false
	_water_ripple_particles.position = Vector3(0.0, 0.05, 0.0)

	var wr_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	wr_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	wr_mat.emission_sphere_radius = 0.25
	wr_mat.direction = Vector3(0.0, 1.0, 0.0)
	wr_mat.spread = 0.0
	wr_mat.gravity = Vector3.ZERO
	wr_mat.scale_min = 0.25
	wr_mat.scale_max = 0.75
	wr_mat.color = Color(0.65, 0.90, 1.0, 0.55)
	_water_ripple_particles.process_material = wr_mat

	var r_mesh: TorusMesh = TorusMesh.new()
	r_mesh.inner_radius = 0.32
	r_mesh.outer_radius = 0.38
	var r_mat: StandardMaterial3D = StandardMaterial3D.new()
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_mat.albedo_color = Color(0.70, 0.92, 1.0, 0.50)
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mesh.material = r_mat
	_water_ripple_particles.draw_pass_1 = r_mesh
	add_child(_water_ripple_particles)

func _build_glider_wings() -> void:
	if _glider_root or not _model_root:
		return
	_glider_root = Node3D.new()
	_glider_root.name = "AnemoGliderWings"
	# Mount to upper back
	_glider_root.position = Vector3(0.0, 1.25, -0.05)
	_model_root.add_child(_glider_root)

	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.18, 0.16, 0.22)
	frame_mat.metallic = 0.65
	frame_mat.roughness = 0.35

	var wing_mat: StandardMaterial3D = StandardMaterial3D.new()
	wing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wing_mat.albedo_color = Color(0.18, 0.92, 0.82, 0.85)
	wing_mat.emission_enabled = true
	wing_mat.emission = Color(0.12, 0.75, 0.65)
	wing_mat.emission_energy_multiplier = 1.2
	wing_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Left wing assembly
	var left_wing: Node3D = Node3D.new()
	left_wing.name = "LeftWing"
	left_wing.position = Vector3(-0.15, 0.05, 0.0)
	left_wing.rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(15.0), deg_to_rad(-18.0))
	_glider_root.add_child(left_wing)

	var left_spar: MeshInstance3D = MeshInstance3D.new()
	var spar_mesh: BoxMesh = BoxMesh.new()
	spar_mesh.size = Vector3(1.15, 0.04, 0.06)
	left_spar.mesh = spar_mesh
	left_spar.position = Vector3(-0.55, 0.0, 0.0)
	left_spar.material_override = frame_mat
	left_wing.add_child(left_spar)

	var left_sail: MeshInstance3D = MeshInstance3D.new()
	var sail_mesh: PrismMesh = PrismMesh.new()
	sail_mesh.size = Vector3(1.05, 0.65, 0.02)
	left_sail.mesh = sail_mesh
	left_sail.position = Vector3(-0.55, -0.22, 0.12)
	left_sail.rotation = Vector3(deg_to_rad(90.0), 0.0, deg_to_rad(90.0))
	left_sail.material_override = wing_mat
	left_wing.add_child(left_sail)

	# Right wing assembly
	var right_wing: Node3D = Node3D.new()
	right_wing.name = "RightWing"
	right_wing.position = Vector3(0.15, 0.05, 0.0)
	right_wing.rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(-15.0), deg_to_rad(18.0))
	_glider_root.add_child(right_wing)

	var right_spar: MeshInstance3D = MeshInstance3D.new()
	right_spar.mesh = spar_mesh
	right_spar.position = Vector3(0.55, 0.0, 0.0)
	right_spar.material_override = frame_mat
	right_wing.add_child(right_spar)

	var right_sail: MeshInstance3D = MeshInstance3D.new()
	right_sail.mesh = sail_mesh
	right_sail.position = Vector3(0.55, -0.22, 0.12)
	right_sail.rotation = Vector3(deg_to_rad(90.0), 0.0, deg_to_rad(-90.0))
	right_sail.material_override = wing_mat
	right_wing.add_child(right_sail)

	# Wingtip vortex particles
	_glider_particles = GPUParticles3D.new()
	_glider_particles.name = "GliderVortexParticles"
	_glider_particles.amount = 12
	_glider_particles.lifetime = 0.4
	_glider_particles.emitting = false
	var gp_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	gp_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	gp_mat.emission_box_extents = Vector3(1.1, 0.1, 0.2)
	gp_mat.direction = Vector3(0.0, 0.2, 1.0)
	gp_mat.spread = 20.0
	gp_mat.initial_velocity_min = 2.0
	gp_mat.initial_velocity_max = 3.5
	gp_mat.color = Color(0.3, 0.95, 0.85, 0.6)
	_glider_particles.process_material = gp_mat

	var p_sphere: SphereMesh = SphereMesh.new()
	p_sphere.radius = 0.05
	p_sphere.height = 0.10
	var p_smat: StandardMaterial3D = StandardMaterial3D.new()
	p_smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_smat.albedo_color = Color(0.4, 1.0, 0.9, 0.5)
	p_smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_sphere.material = p_smat
	_glider_particles.draw_pass_1 = p_sphere
	_glider_root.add_child(_glider_particles)

	_glider_root.visible = false

func open_glider() -> void:
	if is_gliding:
		return
	is_gliding = true
	# Genshin Anemo upward air cushion on glider deployment
	velocity.y = maxf(velocity.y, 1.2)
	if _glider_root:
		_glider_root.visible = true
	if _glider_particles:
		_glider_particles.emitting = true
	_play_glider_sound()
	glider_state_changed.emit(true)

func close_glider() -> void:
	if not is_gliding:
		return
	is_gliding = false
	if _glider_root:
		_glider_root.visible = false
	if _glider_particles:
		_glider_particles.emitting = false
	glider_state_changed.emit(false)

func toggle_glider() -> void:
	if is_gliding:
		close_glider()
	else:
		open_glider()

func _play_glider_sound() -> void:
	if not _audio_player:
		return
	if _glider_swoosh_wav == null:
		_glider_swoosh_wav = _generate_glider_swoosh_wav(0.42, 22050)
	if _glider_swoosh_wav:
		_audio_player.stream = _glider_swoosh_wav
		_audio_player.pitch_scale = randf_range(0.96, 1.05)
		_audio_player.volume_db = -12.0
		if is_inside_tree():
			_audio_player.play()

static func _generate_glider_swoosh_wav(duration: float = 0.42, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)
	var bp1_y1: float = 0.0
	var bp1_y2: float = 0.0

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI) * 0.45
		var white: float = (randf() * 2.0 - 1.0)
		var bp: float = 0.35 * white + 0.78 * bp1_y1 - 0.42 * bp1_y2
		bp1_y2 = bp1_y1
		bp1_y1 = bp
		var sample: float = bp * env
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

func _ensure_torch_system() -> void:
	if torch_system == null:
		torch_system = WildernessTorchSystem.new()
		torch_system.name = "WildernessTorchSystem"
		add_child(torch_system)
		# Default placement on character shoulder / right side
		if torch_system._held_torch_root:
			torch_system._held_torch_root.position = Vector3(0.32, 0.95, -0.15)

func _build_collision() -> void:
	if _collision_shape:
		return
	_collision_shape = CollisionShape3D.new()
	_collision_shape.name = "PlayerCollisionShape"
	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.35
	_capsule.height = 1.75
	_collision_shape.shape = _capsule
	# Center capsule so base rests at Y = 0.0
	_collision_shape.position = Vector3(0.0, 0.875, 0.0)
	add_child(_collision_shape)

func _build_model() -> void:
	if _model_root:
		return
	_model_root = Node3D.new()
	_model_root.name = "ModelRoot"
	add_child(_model_root)
	_build_douyin_character()

	# Setup Inverted Hull Outline Material
	var outline_mat: ShaderMaterial = ShaderMaterial.new()
	outline_mat.shader = preload("res://presentation/shaders/anime_outline.gdshader")
	outline_mat.set_shader_parameter("outline_color", Color(0.18, 0.12, 0.22, 1.0))
	outline_mat.set_shader_parameter("outline_width", 0.0022)

	var anime_scn: PackedScene = load("res://presentation/assets/models/anime_character.glb") as PackedScene
	if anime_scn:
		_character_instance = anime_scn.instantiate()
		_character_instance.name = "AnimeHeroMesh"
		# Slender anime proportions (height ~1.60m, scale X/Z <= 0.85 per contract tests)
		_character_instance.scale = Vector3(0.82, 1.0, 0.82)
		# Rotate 180 degrees so model face aligns with Godot standard forward (-Z)
		_character_instance.rotation.y = PI
		_model_root.add_child(_character_instance)

		var sk: Skeleton3D = _character_instance.find_child("Skeleton3D", true, false) as Skeleton3D
		if sk:
			_character_skeleton = sk
			_bust_l1_bone = sk.find_bone("J_Sec_L_Bust1")
			_bust_l2_bone = sk.find_bone("J_Sec_L_Bust2")
			_bust_r1_bone = sk.find_bone("J_Sec_R_Bust1")
			_bust_r2_bone = sk.find_bone("J_Sec_R_Bust2")
			_hips_bone = sk.find_bone("J_Bip_C_Hips")
			_spine_bone = sk.find_bone("J_Bip_C_Spine")
			_shoulder_l_bone = sk.find_bone("J_Bip_L_Shoulder")
			_shoulder_r_bone = sk.find_bone("J_Bip_R_Shoulder")
			if _shoulder_l_bone != -1:
				sk.set_bone_pose_scale(_shoulder_l_bone, Vector3(1.10, 1.04, 1.06))
				var sl_rest = sk.get_bone_rest(_shoulder_l_bone).origin
				sk.set_bone_pose_position(_shoulder_l_bone, sl_rest + Vector3(0.010, 0.0, 0.0))
			if _shoulder_r_bone != -1:
				sk.set_bone_pose_scale(_shoulder_r_bone, Vector3(1.10, 1.04, 1.06))
				var sr_rest = sk.get_bone_rest(_shoulder_r_bone).origin
				sk.set_bone_pose_position(_shoulder_r_bone, sr_rest + Vector3(-0.010, 0.0, 0.0))
			_anime_animator = preload("res://presentation/camera/anime_character_animator.gd").new()
			_anime_animator.setup(sk)
			_anime_animator.update(0.016, 0.0, true, false, false)

			_weapon_system = preload("res://presentation/character/anime_weapon_system.gd").new()
			_weapon_system.name = "AnimeWeaponSystem"
			_model_root.add_child(_weapon_system)
			_weapon_system.setup(sk, _anime_animator)
			_weapon_system.weapon_state_changed.connect(func(drawn: bool): weapon_stance_changed.emit(drawn))
			_weapon_system.attack_performed.connect(func(c: int, d: int): attack_executed.emit(c, d))
			_weapon_system.hit_stop_triggered.connect(func(dur: float):
				apply_camera_shake(dur * 0.75, dur)
			)

		var face_node: MeshInstance3D = _character_instance.find_child("Face", true, false) as MeshInstance3D
		if face_node:
			_facial_controller = preload("res://presentation/character/anime_facial_controller.gd").new()
			_facial_controller.setup(face_node)

		# Apply Genshin Toon shading + ink outline next_pass while preserving ALL original VRoid per-surface textures
		for child in _character_instance.find_children("*", "MeshInstance3D", true, false):
			var mi: MeshInstance3D = child as MeshInstance3D
			if not mi or not mi.mesh:
				continue

			mi.material_override = null # Clear blanket override so per-surface textures & alpha layers shine through
			var lower_name: String = mi.name.to_lower()
			if mi.name == "Body":
				_body_mesh_instance = mi
				_default_body_mesh = mi.mesh
				_default_body_materials.clear()

			for s in range(mi.mesh.get_surface_count()):
				var orig_mat = mi.mesh.surface_get_material(s)
				if not orig_mat:
					orig_mat = mi.get_active_material(s)
				if orig_mat is BaseMaterial3D:
					var dup: BaseMaterial3D = orig_mat.duplicate() as BaseMaterial3D
					dup.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
					dup.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
					dup.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
					dup.roughness = 0.48
					dup.metallic = 0.0

					var m_name: String = dup.resource_name.to_lower()
					if lower_name.contains("hair"):
						# Double-sided culling for natural flowing anime hair strands
						dup.cull_mode = BaseMaterial3D.CULL_DISABLED
						dup.next_pass = outline_mat
					elif lower_name.contains("face"):
						# Do not put inverted hull outline inside transparent eye iris/highlights
						var is_eye_decal: bool = ("eyeiris" in m_name or "eyehighlight" in m_name or "eyewhite" in m_name or "eyelash" in m_name or "brow" in m_name or "eyeline" in m_name)
						if not is_eye_decal:
							dup.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
							dup.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
							dup.subsurf_scatter_enabled = true
							dup.subsurf_scatter_strength = 0.28
							dup.next_pass = outline_mat
						else:
							# Silky smooth alpha transparency without dithered stipple noise
							dup.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
							if "eyehighlight" in m_name:
								# Perpetual sparkle: unshaded radiant anime eye highlight
								dup.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
							elif "eyewhite" in m_name or "eyeiris" in m_name:
								dup.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
					else:
						if mi.name == "Body" and s == 0:
							dup.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
							dup.next_pass = null
							dup.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
							dup.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
							dup.roughness = 0.48
							dup.metallic = 0.0
							dup.subsurf_scatter_enabled = true
							dup.subsurf_scatter_strength = 0.28
							dup.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
						else:
							dup.next_pass = outline_mat

					mi.set_surface_override_material(s, dup)
					if mi.name == "Body":
						_default_body_materials.append(dup)
				elif orig_mat:
					var dup: Material = orig_mat.duplicate()
					dup.next_pass = outline_mat
					mi.set_surface_override_material(s, dup)
					if mi.name == "Body":
						_default_body_materials.append(dup)

		# Small invisible accessory node (preserves cel_shader and outline_mat references in scene graph)
		var accessory: MeshInstance3D = MeshInstance3D.new()
		accessory.name = "AnimeAuraAccessory"
		accessory.mesh = QuadMesh.new()
		(accessory.mesh as QuadMesh).size = Vector2(0.01, 0.01)
		var cel_mat: ShaderMaterial = ShaderMaterial.new()
		if ResourceLoader.exists("res://presentation/shaders/anime_cel_shader.gdshader"):
			cel_mat.shader = load("res://presentation/shaders/anime_cel_shader.gdshader")
		cel_mat.next_pass = outline_mat
		accessory.material_override = cel_mat
		_character_instance.add_child(accessory)

		return

	# Fallback to human_character.glb if anime model is unavailable
	var scn: PackedScene = load("res://presentation/assets/models/human_character.glb") as PackedScene
	if scn:
		_character_instance = scn.instantiate()
		_character_instance.name = "HumanMesh"
		var scale_factor: float = 1.75 / 2.187
		var anime_scale_x: float = scale_factor * 0.82
		var anime_scale_y: float = scale_factor * 1.03
		var anime_scale_z: float = scale_factor * 0.82
		_character_instance.scale = Vector3(anime_scale_x, anime_scale_y, anime_scale_z)
		_character_instance.rotation.y = PI
		_model_root.add_child(_character_instance)

		var char_tex = load("res://presentation/assets/models/rogue_texture.png")
		if not char_tex:
			char_tex = load("res://presentation/assets/models/human_character_rogue_texture.png")
		if char_tex:
			# Fallback: simple texture on outline_mat (no toon shader needed)
			var fallback_mat: StandardMaterial3D = StandardMaterial3D.new()
			fallback_mat.albedo_texture = char_tex
			fallback_mat.next_pass = outline_mat
			for child in _character_instance.find_children("*", "MeshInstance3D", true, false):
				var mi_fb: MeshInstance3D = child as MeshInstance3D
				if mi_fb:
					mi_fb.material_override = fallback_mat

func _build_camera_rig() -> void:
	if _spring_arm:
		return
	_spring_arm = SpringArm3D.new()
	_spring_arm.name = "CameraSpringArm"
	_spring_arm.position = Vector3(shoulder_offset_x, shoulder_height, 0.0)
	_spring_arm.spring_length = camera_distance
	_spring_arm.margin = 0.22
	_spring_arm.collision_mask = 1 # Collides with terrain, boulders, trees

	var sphere_shape: SphereShape3D = SphereShape3D.new()
	sphere_shape.radius = 0.18
	_spring_arm.shape = sphere_shape
	add_child(_spring_arm)

	_camera = Camera3D.new()
	_camera.name = "PlayerCamera"
	_camera.near = 0.05
	_camera.far = 950.0
	_camera.fov = base_fov
	_spring_arm.add_child(_camera)

func _build_audio_emitter() -> void:
	if _audio_player:
		return
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "CharacterAudioEmitter"
	_audio_player.unit_size = 3.5
	_audio_player.max_distance = 32.0
	_audio_player.position = Vector3(0.0, 0.15, 0.0)
	add_child(_audio_player)

func _setup_animations() -> void:
	if not _anim_player:
		return

	# Add animation aliases if using KayKit clip naming conventions for backward compatibility
	var lib: AnimationLibrary = _anim_player.get_animation_library("")
	if lib:
		var alias_map: Dictionary = {
			"idle": "Idle",
			"walk": "Walking_A",
			"run": "Running_A",
			"jump": "Jump_Start",
			"falling": "Jump_Idle"
		}
		for alias: String in alias_map:
			var target_anim: String = alias_map[alias]
			if lib.has_animation(target_anim) and not lib.has_animation(alias):
				lib.add_animation(alias, lib.get_animation(target_anim))

	# Set linear looping on locomotion clips
	var loop_clips: Array[String] = ["idle", "walk", "run", "falling", "Idle", "Walking_A", "Running_A", "Jump_Idle"]
	for clip_name in loop_clips:
		if _anim_player.has_animation(clip_name):
			var anim: Animation = _anim_player.get_animation(clip_name)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR

	# Configure cross-fade blending for seamless transitions
	_anim_player.set_blend_time("idle", "walk", 0.22)
	_anim_player.set_blend_time("walk", "idle", 0.25)
	_anim_player.set_blend_time("walk", "run", 0.20)
	_anim_player.set_blend_time("run", "walk", 0.20)
	_anim_player.set_blend_time("idle", "run", 0.22)
	_anim_player.set_blend_time("run", "idle", 0.28)
	_anim_player.set_blend_time("idle", "jump", 0.08)
	_anim_player.set_blend_time("walk", "jump", 0.08)
	_anim_player.set_blend_time("run", "jump", 0.08)
	_anim_player.set_blend_time("jump", "falling", 0.12)
	_anim_player.set_blend_time("falling", "idle", 0.18)
	_anim_player.set_blend_time("falling", "walk", 0.18)
	_anim_player.set_blend_time("falling", "run", 0.18)

	_play_anim("idle")

func setup(terrain: IslandTerrain) -> void:
	_terrain = terrain

func setup_walker(_height_fn: Callable = Callable(), spawn_pos: Vector3 = Vector3.ZERO) -> void:
	walk_speed = 3.2
	sprint_speed = 5.8
	eye_height = 1.75
	if spawn_pos != Vector3.ZERO:
		teleport_to(spawn_pos)

func _resolve_terrain() -> IslandTerrain:
	if _terrain:
		return _terrain
	if is_inside_tree():
		if get_tree().current_scene:
			var node = get_tree().current_scene.get_node_or_null("IslandTerrain")
			if node is IslandTerrain:
				_terrain = node
				return _terrain
		var p = get_parent()
		while p:
			var node = p.get_node_or_null("IslandTerrain")
			if node is IslandTerrain:
				_terrain = node
				return _terrain
			p = p.get_parent()
	return null

func teleport_to(ground_pos: Vector3) -> void:
	velocity = Vector3.ZERO
	var t: IslandTerrain = _resolve_terrain()
	if t:
		var ground_h: float = t.get_height_at(ground_pos.x, ground_pos.z)
		ground_pos.y = maxf(ground_pos.y, ground_h + 0.05)
	if is_inside_tree():
		global_position = ground_pos
	else:
		position = ground_pos

func get_eye_position() -> Vector3:
	var base_pos: Vector3 = global_position if is_inside_tree() else position
	var fwd: Vector3 = Vector3(-sin(_model_yaw), 0.0, -cos(_model_yaw))
	if is_third_person:
		var current_eye_h: float = (eye_height * 0.68) if is_crouching else eye_height
		return base_pos + Vector3(0.0, current_eye_h + _land_compression, 0.0) + fwd * 0.10

	# First-Person View: Aligned directly with anime character's true anatomical eye line
	var fp_standing_eye_h: float = 1.38
	var fp_crouch_eye_h: float = 0.88
	var eye_h: float = fp_crouch_eye_h if is_crouching else fp_standing_eye_h

	# Head pitch compensation: looking down tilts head forward over chest and slightly downward
	var pitch_down: float = maxf(0.0, -_cam_pitch)
	var fwd_offset: float = 0.14 + sin(pitch_down) * 0.10
	var down_offset: float = (1.0 - cos(pitch_down)) * 0.05

	return base_pos + Vector3(0.0, eye_h + _land_compression - down_offset, 0.0) + fwd * fwd_offset

func get_camera() -> Camera3D:
	if not _camera:
		_build_camera_rig()
	return _camera

func set_perspective(third_person: bool) -> void:
	is_third_person = third_person
	if not _spring_arm or not _character_instance:
		return

	if is_third_person:
		_spring_arm.position = Vector3(shoulder_offset_x, shoulder_height, 0.0)
		_spring_arm.spring_length = camera_distance
		_update_mesh_visibility_for_perspective(true)
		if _camera:
			_camera.cull_mask = _camera.cull_mask | (1 << 1)
		if _model_root:
			_model_root.visible = true
		if torch_system and torch_system._held_torch_root:
			torch_system._held_torch_root.position = Vector3(0.32, 0.95, -0.15)
	else:
		var curr_eye_h: float = 0.88 if is_crouching else 1.38
		_spring_arm.position = Vector3(0.0, curr_eye_h, 0.06)
		_spring_arm.spring_length = 0.0
		_update_mesh_visibility_for_perspective(false)
		if _camera:
			_camera.cull_mask = _camera.cull_mask & ~(1 << 1)
		if _model_root:
			_model_root.visible = true
		if torch_system and torch_system._held_torch_root:
			torch_system._held_torch_root.position = Vector3(0.28, eye_height - 0.30, -0.35)

	perspective_changed.emit(is_third_person)

func get_torch_system() -> WildernessTorchSystem:
	if torch_system == null:
		_ensure_torch_system()
	return torch_system

func toggle_torch() -> bool:
	return get_torch_system().toggle_held_torch()

func toggle_perspective() -> void:
	set_perspective(not is_third_person)

func _update_mesh_visibility_for_perspective(third_person: bool) -> void:
	# Apply to both characters; only the active one is visible anyway
	for instance in [_character_instance, _douyin_instance]:
		if not instance:
			continue
		for child: Node in instance.find_children("*", "GeometryInstance3D", true, false):
			var geom: GeometryInstance3D = child as GeometryInstance3D
			if not geom:
				continue
			if third_person:
				geom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				geom.visible = true
				geom.layers = 1
			else:
				var lower: String = geom.name.to_lower()
				if lower.contains("face") or lower.contains("hair") or lower.contains("head"):
					# Head & Hair only cast shadows so they do not clip inside camera near-plane
					geom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
					geom.layers = 2
				else:
					# Body, chest, arms, hands, legs, and feet remain fully visible in first-person
					geom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
					geom.visible = true
					geom.layers = 1

func _set_model_shadow_mode(mode: GeometryInstance3D.ShadowCastingSetting) -> void:
	if not _character_instance:
		return
	for child: Node in _character_instance.find_children("*", "GeometryInstance3D", true, false):
		var geom: GeometryInstance3D = child as GeometryInstance3D
		if geom and geom.visible:
			geom.cast_shadow = mode

## Handle mouse rotation for camera orbit
func rotate_camera(relative: Vector2) -> void:
	var pitch_mult: float = 1.0 if invert_y else -1.0
	_target_cam_yaw -= relative.x * mouse_sensitivity_x
	_target_cam_pitch += relative.y * mouse_sensitivity_y * pitch_mult
	_target_cam_pitch = clampf(_target_cam_pitch, min_pitch, max_pitch)

## Handle camera zoom
func zoom_camera(delta_zoom: float) -> void:
	if not is_third_person:
		return
	_target_camera_distance = clampf(camera_distance + delta_zoom, min_camera_distance, max_camera_distance)

func start_climbing(wall_normal: Vector3) -> void:
	if is_climbing or _climb_cooldown > 0.0 or (stamina and stamina.is_exhausted):
		return
	is_climbing = true
	_climb_wall_normal = wall_normal.normalized()
	velocity = Vector3.ZERO
	if is_gliding:
		close_glider()
	climb_state_changed.emit(true)

func stop_climbing() -> void:
	if not is_climbing:
		return
	is_climbing = false
	_climb_cooldown = 0.35
	climb_state_changed.emit(false)

func apply_camera_shake(intensity: float = 0.045, _duration: float = 0.12) -> void:
	_cam_shake_offset = Vector3(
		randf_range(-intensity, intensity),
		randf_range(-intensity, intensity) * 0.75,
		randf_range(-intensity, intensity) * 0.5
	)

## Main physics movement update with Block 15 Weighty Locomotion & Slope Physics
func move_character(delta: float, wish_dir: Vector3, is_sprinting: bool, want_jump: bool, want_crouch: bool = false) -> void:
	if active_mount != null:
		if active_mount.has_method("step_mounted_motion"):
			active_mount.step_mounted_motion(delta, wish_dir, is_sprinting, want_jump)
		return

	if _climb_cooldown > 0.0:
		_climb_cooldown = maxf(0.0, _climb_cooldown - delta)

	is_crouching = want_crouch
	_is_sprinting = is_sprinting and not want_crouch
	eye_height = 1.10 if is_crouching else 1.75
	var on_ground: bool = is_on_floor() if is_inside_tree() else true
	var current_pos: Vector3 = global_position if is_inside_tree() else position

	# Smooth camera height adjustment for crouch observation
	if _spring_arm:
		var target_cam_y: float = (shoulder_height * 0.72) if (is_crouching and is_third_person) else (shoulder_height if is_third_person else (0.88 if is_crouching else 1.38))
		_spring_arm.position.y = lerpf(_spring_arm.position.y, target_cam_y, clampf(10.0 * delta, 0.0, 1.0))
		if not is_third_person:
			_spring_arm.position.z = lerpf(_spring_arm.position.z, 0.06, clampf(8.0 * delta, 0.0, 1.0))

	# Update forward-pointing raycasts for climbing detection
	var fwd_yaw: float = _model_yaw
	var ray_fwd: Vector3 = Vector3(-sin(fwd_yaw), 0.0, -cos(fwd_yaw)).normalized()
	if _wall_check_ray:
		_wall_check_ray.target_position = ray_fwd * 0.95
	if _ledge_check_ray:
		_ledge_check_ray.target_position = ray_fwd * 0.95

	# --- CLIMBING KINEMATICS ---
	if is_climbing:
		# Check stamina exhaustion slip-off
		if stamina and stamina.is_exhausted:
			stop_climbing()
			velocity = _climb_wall_normal * 1.5 - Vector3.UP * 2.0
		else:
			# Check Wall Jump
			if want_jump and not _prev_want_jump:
				_prev_want_jump = want_jump
				if stamina and stamina.consume_chunk(stamina.climb_jump_cost):
					velocity = _climb_wall_normal * 4.6 + Vector3.UP * 5.8
					stop_climbing()
				return

			# Check Ledge Mantle: chest ray hits wall, but open air at head level
			var wall_hit: bool = _wall_check_ray and _wall_check_ray.is_colliding()
			var ledge_clear: bool = _ledge_check_ray and not _ledge_check_ray.is_colliding()
			if wish_dir.z < -0.1 and wall_hit and ledge_clear:
				var mantle_step: Vector3 = -_climb_wall_normal * 0.75 + Vector3.UP * 0.65
				if is_inside_tree():
					global_position += mantle_step
				else:
					position += mantle_step
				velocity = -_climb_wall_normal * 1.8 + Vector3.UP * 0.8
				stop_climbing()
				return

			# Wall-tangent climbing movement
			var wall_right: Vector3 = Vector3.UP.cross(_climb_wall_normal).normalized()
			var climb_v_input: float = 0.0
			if wish_dir.z < -0.1:
				climb_v_input = 2.4
			elif wish_dir.z > 0.1:
				climb_v_input = -2.4

			var climb_h_input: float = wish_dir.x * 2.0
			velocity = wall_right * climb_h_input + Vector3.UP * climb_v_input

			# Drain stamina
			var is_moving_climb: bool = absf(climb_v_input) > 0.1 or absf(climb_h_input) > 0.1
			if stamina:
				if is_moving_climb:
					stamina.drain(stamina.climb_drain_rate, delta)
				else:
					stamina.drain(stamina.climb_idle_drain_rate, delta)

			# Align character facing the cliff face
			_model_yaw = atan2(-_climb_wall_normal.x, -_climb_wall_normal.z) + PI
			if _model_root:
				_model_root.rotation = Vector3(deg_to_rad(-8.0), _model_yaw, 0.0)

			# If climbing down onto floor
			if on_ground and climb_v_input < -0.1:
				stop_climbing()

			_prev_want_jump = want_jump
			if is_inside_tree():
				move_and_slide()
			else:
				position += velocity * delta

			_update_animation_state(delta, is_moving_climb, false, false, true)
			return

	# Check climb initiation on steep cliff contact
	if _climb_cooldown <= 0.0 and (not on_ground or wish_dir.length_squared() > 0.01):
		if _wall_check_ray and _wall_check_ray.is_colliding():
			var col_n: Vector3 = _wall_check_ray.get_collision_normal()
			if col_n.angle_to(Vector3.UP) > deg_to_rad(52.0):
				var n_h: Vector3 = Vector3(col_n.x, 0.0, col_n.z).normalized()
				var w_dir: Vector3 = wish_dir.normalized() if wish_dir.length_squared() > 0.01 else -n_h
				if w_dir.dot(-n_h) > 0.25 or not on_ground:
					start_climbing(col_n)
					return

	# --- 1. VERTICAL MOVEMENT, GRAVITY & GLIDER AERODYNAMICS ---
	if not on_ground:
		_last_air_y_velocity = velocity.y
		# Airborne jump press toggles Anemo Glider Wings
		if want_jump and not _prev_want_jump:
			toggle_glider()

		if is_gliding:
			# Clamped gliding descent
			velocity.y = lerpf(velocity.y, glide_sink_rate, clampf(7.5 * delta, 0.0, 1.0))
		else:
			velocity.y -= gravity * delta
		_was_on_ground = false
	else:
		# Ground contact collapses glider automatically
		if is_gliding:
			close_glider()

		# Landing event detection
		if not _was_on_ground:
			_was_on_ground = true
			if _last_air_y_velocity < -2.2:
				_land_timer = 0.22
				var impact_speed: float = absf(_last_air_y_velocity)
				_land_compression = -0.07 * clampf(impact_speed / 7.0, 0.4, 1.0)
				_play_land_impact(impact_speed)
				landing_impact_occurred.emit(impact_speed)

		if want_jump and _land_timer <= 0.05:
			velocity.y = jump_velocity
			_was_on_ground = false
		else:
			velocity.y = -0.1

	_prev_want_jump = want_jump

	# Smooth recovery of landing knee compression
	_land_compression = lerpf(_land_compression, 0.0, clampf(12.0 * delta, 0.0, 1.0))
	if _model_root:
		_model_root.position.y = _land_compression

	if _land_timer > 0.0:
		_land_timer = maxf(0.0, _land_timer - delta)

	# --- 2. SLOPE & SURFACE RESISTANCE ---
	var target_speed: float = crouch_speed if is_crouching else (glide_speed if is_gliding else (sprint_speed if _is_sprinting else walk_speed))

	# Landing impact damping
	if _land_timer > 0.0:
		target_speed *= 0.65

	# Shallow water drag in lagoon / creek
	if _resolve_terrain() != null and current_pos.y < 0.2:
		target_speed *= 0.70

	# Slope resistance when climbing hills
	var floor_normal: Vector3 = get_floor_normal() if (is_inside_tree() and on_ground) else Vector3.UP
	var slope_angle: float = floor_normal.angle_to(Vector3.UP)
	var has_input: bool = wish_dir.length_squared() > 0.001
	var move_dir: Vector3 = wish_dir.normalized() if has_input else Vector3.ZERO

	if on_ground and slope_angle > deg_to_rad(4.0) and has_input:
		var norm_horiz: Vector3 = Vector3(floor_normal.x, 0.0, floor_normal.z)
		if norm_horiz.length_squared() > 0.001:
			var incline_dot: float = -move_dir.dot(norm_horiz.normalized())
			if incline_dot > 0.0:
				# Climbing uphill: apply resistance up to 30% reduction on steep slopes
				var climb_penalty: float = incline_dot * (slope_angle / deg_to_rad(45.0)) * 0.32
				target_speed *= clampf(1.0 - climb_penalty, 0.68, 1.0)

	# Stamina consumption & recovery
	if _is_sprinting and on_ground and has_input:
		if stamina:
			if stamina.is_exhausted:
				_is_sprinting = false
			else:
				stamina.drain(stamina.sprint_drain_rate, delta)
	elif is_gliding:
		if stamina:
			if stamina.is_exhausted:
				close_glider()
			else:
				stamina.drain(stamina.glide_drain_rate, delta)
	else:
		if stamina:
			stamina.update(delta, false)

	# --- 3. HORIZONTAL ACCELERATION & WEIGHTY DECELERATION ---
	# Genshin Impact Dash Impulse (instant initial velocity punch on sprint start)
	if _is_sprinting and not _was_sprinting_prev and has_input and on_ground:
		_dash_impulse_timer = 0.16
		velocity.x += move_dir.x * 1.6
		velocity.z += move_dir.z * 1.6
		if _dash_particles:
			_dash_particles.restart()
			_dash_particles.emitting = true
	if _dash_impulse_timer > 0.0:
		_dash_impulse_timer = maxf(0.0, _dash_impulse_timer - delta)

	if has_input:
		var target_h: Vector3 = move_dir * target_speed
		var rate: float = acceleration if on_ground else 5.0
		var h_weight: float = clampf(1.0 - exp(-rate * delta), 0.0, 1.0)
		velocity.x = lerpf(velocity.x, target_h.x, h_weight)
		velocity.z = lerpf(velocity.z, target_h.z, h_weight)

		# Dynamic turning speed: agile during walk, wider momentum arc during sprint
		var target_yaw: float = atan2(-move_dir.x, -move_dir.z)
		var current_turn_rate: float = sprint_turn_speed if (is_sprinting and velocity.length() > 4.0) else turn_speed
		var yaw_diff: float = wrapf(target_yaw - _model_yaw, -PI, PI)

		# Banking lean during turn
		var target_lean: float = clampf(-yaw_diff * 0.20, -deg_to_rad(14.0), deg_to_rad(14.0)) if (is_sprinting or is_gliding) else 0.0
		_model_lean_roll = lerpf(_model_lean_roll, target_lean, clampf(1.0 - exp(-8.0 * delta), 0.0, 1.0))

		var turn_weight: float = clampf(1.0 - exp(-current_turn_rate * delta), 0.0, 1.0)
		_model_yaw = lerp_angle(_model_yaw, target_yaw, turn_weight)
	else:
		# Weighty deceleration braking (RDR2 Kinematic Skid Stopping)
		var h_speed_pre: float = Vector2(velocity.x, velocity.z).length()
		if _was_sprinting_prev and h_speed_pre > 4.2 and on_ground and _skid_timer <= 0.0:
			_skid_timer = 0.24
			_skid_pitch = deg_to_rad(3.8)
			if _dash_particles:
				_dash_particles.restart()
				_dash_particles.emitting = true
			if _audio_player and _step_stone_wav:
				_audio_player.stream = _step_stone_wav
				_audio_player.pitch_scale = 0.78
				_audio_player.volume_db = -12.0
				if is_inside_tree():
					_audio_player.play()

		var rate: float = deceleration if on_ground else 2.5
		var decel_weight: float = clampf(1.0 - exp(-rate * delta), 0.0, 1.0)
		velocity.x = lerpf(velocity.x, 0.0, decel_weight)
		velocity.z = lerpf(velocity.z, 0.0, decel_weight)
		_model_lean_roll = lerpf(_model_lean_roll, 0.0, clampf(1.0 - exp(-10.0 * delta), 0.0, 1.0))
		if not is_third_person and not is_climbing:
			_model_yaw = lerp_angle(_model_yaw, _cam_yaw, clampf(14.0 * delta, 0.0, 1.0))

	# Dynamic slope alignment of character body (subtle pitch & roll tilt to ground normal)
	if _skid_timer > 0.0:
		_skid_timer = maxf(0.0, _skid_timer - delta)
		_skid_pitch = lerpf(_skid_pitch, 0.0, clampf(10.0 * delta, 0.0, 1.0))
	else:
		_skid_pitch = 0.0

	if on_ground and _model_root:
		var fwd_vec: Vector3 = Vector3(-sin(_model_yaw), 0.0, -cos(_model_yaw))
		var rgt_vec: Vector3 = Vector3(cos(_model_yaw), 0.0, -sin(_model_yaw))
		var target_pitch: float = clampf(-fwd_vec.dot(floor_normal) * 0.40, -deg_to_rad(16.0), deg_to_rad(16.0)) + _skid_pitch
		var target_roll: float = clampf(rgt_vec.dot(floor_normal) * 0.40, -deg_to_rad(12.0), deg_to_rad(12.0))


		_model_slope_pitch = lerpf(_model_slope_pitch, target_pitch, clampf(8.0 * delta, 0.0, 1.0))
		_model_slope_roll = lerpf(_model_slope_roll, target_roll + _model_lean_roll, clampf(8.0 * delta, 0.0, 1.0))
		_model_root.rotation = Vector3(_model_slope_pitch, _model_yaw, _model_slope_roll)
	elif is_gliding and _model_root:
		_model_slope_pitch = lerpf(_model_slope_pitch, deg_to_rad(12.0), clampf(6.0 * delta, 0.0, 1.0))
		_model_slope_roll = lerpf(_model_slope_roll, _model_lean_roll * 1.5, clampf(8.0 * delta, 0.0, 1.0))
		_model_root.rotation = Vector3(_model_slope_pitch, _model_yaw, _model_slope_roll)
	elif _model_root:
		_model_slope_pitch = lerpf(_model_slope_pitch, 0.0, clampf(8.0 * delta, 0.0, 1.0))
		_model_slope_roll = lerpf(_model_slope_roll, 0.0, clampf(8.0 * delta, 0.0, 1.0))
		_model_root.rotation = Vector3(_model_slope_pitch, _model_yaw, _model_slope_roll)

	# --- 4. MOVE AND SLIDE & BOUNDARY CLAMPING ---
	if is_inside_tree():
		move_and_slide()
		current_pos = global_position
	else:
		position += velocity * delta
		current_pos = position

	# Enforce Island Boundaries and prevent falling below terrain
	var t: IslandTerrain = _resolve_terrain()
	var boundary_limit: float = 74.0
	if t and t.island_size > 200.0:
		boundary_limit = t.island_size * 0.46

	var horiz: Vector2 = Vector2(current_pos.x, current_pos.z)
	if horiz.length() > boundary_limit:
		var clamped: Vector2 = horiz.normalized() * boundary_limit
		current_pos.x = clamped.x
		current_pos.z = clamped.y
		if is_inside_tree():
			global_position = current_pos
		else:
			position = current_pos

	if t and horiz.length() < (boundary_limit - 4.0):
		var ground_h: float = t.get_height_at(current_pos.x, current_pos.z)
		if current_pos.y < ground_h - 0.2:
			current_pos.y = ground_h + 0.05
			velocity.y = 0.0
			if is_inside_tree():
				global_position = current_pos
			else:
				position = current_pos

	if current_pos.y < -1.5:
		current_pos.y = -1.5
		velocity.y = 0.0
		if is_inside_tree():
			global_position = current_pos
		else:
			position = current_pos

	# --- 5. ANIMATION STATE MACHINE & STRIDE SYNCHRONIZATION ---
	_update_animation_state(delta, has_input, is_sprinting, on_ground, false)
	_was_sprinting_prev = _is_sprinting

func _update_animation_state(delta: float, has_input: bool, is_sprint: bool, on_ground: bool, is_climbing_flag: bool = false) -> void:
	var h_speed: float = Vector2(velocity.x, velocity.z).length()

	if _anime_animator:
		if is_climbing_flag:
			_loco_state = LocomotionState.CLIMBING
		elif not on_ground:
			_loco_state = LocomotionState.FALLING if not is_gliding else LocomotionState.JUMP
		elif _land_timer > 0.08:
			_loco_state = LocomotionState.LANDING
		elif h_speed < 0.15 or not has_input:
			if _loco_state == LocomotionState.WALK or _loco_state == LocomotionState.SPRINT:
				_loco_state = LocomotionState.STOPPING
			else:
				_loco_state = LocomotionState.IDLE
		elif is_sprint and h_speed > 4.2:
			_loco_state = LocomotionState.SPRINT
		else:
			_loco_state = LocomotionState.WALK
		_anime_animator.update(delta, h_speed, on_ground, is_gliding, is_sprint, is_climbing_flag, _cam_yaw, velocity.y)

	if _weapon_system and _weapon_system.has_method("update"):
		_weapon_system.update(delta)

	if _facial_controller and _facial_controller.has_method("update"):
		var in_combat: bool = _weapon_system.is_drawn if (_weapon_system and "is_drawn" in _weapon_system) else false
		_facial_controller.update(delta, is_gliding, is_sprint, in_combat)
	elif _anim_player:
		if not on_ground:
			if is_gliding:
				_loco_state = LocomotionState.FALLING
				_play_anim("falling")
				_anim_player.speed_scale = 0.35
			elif velocity.y > 0.8:
				_loco_state = LocomotionState.JUMP
				_play_anim("jump")
			else:
				_loco_state = LocomotionState.FALLING
				_play_anim("falling")
		elif _land_timer > 0.08:
			_loco_state = LocomotionState.LANDING
			# Maintain smooth foot contact during landing absorption
			if h_speed < 0.2:
				_play_anim("idle")
			else:
				_play_anim("walk")
				_anim_player.speed_scale = 0.8
		else:
			if h_speed < 0.15 or not has_input:
				if _loco_state == LocomotionState.WALK or _loco_state == LocomotionState.SPRINT:
					_loco_state = LocomotionState.STOPPING
				else:
					_loco_state = LocomotionState.IDLE
				_play_anim("idle")
				_anim_player.speed_scale = 1.0
			elif is_sprint and h_speed > 4.2:
				_loco_state = LocomotionState.SPRINT
				_play_anim("run")
				# Precision stride matching to eliminate foot sliding
				_anim_player.speed_scale = clampf(h_speed / sprint_speed, 0.78, 1.45)
			else:
				_loco_state = LocomotionState.WALK
				_play_anim("walk")
				# Precision stride matching to eliminate foot sliding

	# Anime wind dash particles activation
	if _dash_particles:
		_dash_particles.emitting = (_loco_state == LocomotionState.SPRINT and on_ground and is_third_person)
	if _water_ripple_particles:
		var py: float = global_position.y if is_inside_tree() else position.y
		_water_ripple_particles.emitting = (py < 0.25 and py > -1.5 and h_speed > 0.35 and is_third_person)

	# Footstep audio triggered by actual animation phase
	_process_footstep_audio(on_ground, h_speed)

func _play_anim(anim_name: String) -> void:
	if _current_anim == anim_name:
		return
	if _anim_player and _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name)
		_current_anim = anim_name

func _process_footstep_audio(on_ground: bool, h_speed: float) -> void:
	if not on_ground or h_speed < 0.35:
		return

	var triggered: bool = false
	if _anime_animator:
		# Trigger footstep at bottom of leg swings (~0.0 and ~PI)
		var phase: float = wrapf(_anime_animator._walk_cycle, 0.0, TAU)
		if (_last_anim_pos < PI * 0.5 and phase >= PI * 0.5) or (_last_anim_pos < PI * 1.5 and phase >= PI * 1.5):
			triggered = true
		elif phase < _last_anim_pos and phase >= PI * 0.5:
			triggered = true
		_last_anim_pos = phase
	elif _anim_player:
		var curr_pos: float = _anim_player.current_animation_position
		# Walk footfalls at ~25% (0.26s) and ~75% (0.78s)
		if _current_anim == "walk":
			if (_last_anim_pos < 0.26 and curr_pos >= 0.26) or (_last_anim_pos < 0.78 and curr_pos >= 0.78):
				triggered = true
			elif curr_pos < _last_anim_pos and curr_pos >= 0.26: # Loop wrap
				triggered = true
		# Run footfalls at ~25% (0.21s) and ~75% (0.62s)
		elif _current_anim == "run":
			if (_last_anim_pos < 0.21 and curr_pos >= 0.21) or (_last_anim_pos < 0.62 and curr_pos >= 0.62):
				triggered = true
			elif curr_pos < _last_anim_pos and curr_pos >= 0.21: # Loop wrap
				triggered = true
		_last_anim_pos = curr_pos

	if triggered:
		_play_footstep(h_speed)

func _play_footstep(h_speed: float) -> void:
	var current_pos: Vector3 = global_position if is_inside_tree() else position
	var surface_type: String = "grass"

	# High-altitude alpine snow (elevation >= 50.0m on Skyspire Massif)
	if current_pos.y >= 50.0:
		surface_type = "snow"
	# Water wading
	elif current_pos.y < 0.2:
		surface_type = "water"
	# Shoreline sand (elevation 0.2m to 1.4m)
	elif current_pos.y < 1.4:
		surface_type = "sand"
	# Rocky bluff / scree
	elif current_pos.y > 6.5 or (current_pos.x > 18.0 and current_pos.z > 12.0):
		surface_type = "stone"

	if _audio_player and is_inside_tree():
		match surface_type:
			"snow":
				_audio_player.stream = _step_snow_wav
				_audio_player.volume_db = -17.5
			"water":
				_audio_player.stream = _step_water_wav
				_audio_player.volume_db = -18.0
			"stone":
				_audio_player.stream = _step_stone_wav
				_audio_player.volume_db = -17.0
			"sand":
				_audio_player.stream = _step_sand_wav
				_audio_player.volume_db = -19.5
			_:
				_audio_player.stream = _step_grass_wav
				_audio_player.volume_db = -19.0
		_audio_player.pitch_scale = randf_range(0.92, 1.08)
		_audio_player.play()

	footstep_played.emit(surface_type)

func _play_land_impact(impact_speed: float) -> void:
	if _audio_player and is_inside_tree() and _land_thud_wav:
		_audio_player.stream = _land_thud_wav
		_audio_player.volume_db = clampf(-18.0 + (impact_speed - 2.0) * 1.5, -20.0, -10.0)
		_audio_player.pitch_scale = randf_range(0.94, 1.04)
		_audio_player.play()

func update_camera_rotation(delta: float) -> void:
	# AAA Mass-Spring-Damper Camera Dynamics (RDR2 Cinematic Weight & Zero-Snap Feel)
	var desired_yaw: float = _target_cam_yaw
	var desired_pitch: float = _target_cam_pitch
	var desired_dist: float = _target_camera_distance

	if is_selfie_mode:
		# Swing camera to face character front-quarter (+PI) with pleasant portrait angle
		desired_yaw = wrapf(_model_yaw + PI + _target_cam_yaw * 0.45, -PI, PI)
		desired_pitch = clampf(_target_cam_pitch, deg_to_rad(-15.0), deg_to_rad(35.0))
		desired_dist = clampf(_target_camera_distance, 1.8, 3.4)

	# Second-order critically damped spring dynamics for buttery 60+ FPS motion
	var spring_k: float = 28.0
	var damping: float = 2.0 * sqrt(spring_k)
	var diff_yaw: float = wrapf(desired_yaw - _cam_yaw, -PI, PI)
	_cam_yaw_vel += (spring_k * diff_yaw - damping * _cam_yaw_vel) * delta
	_cam_yaw += _cam_yaw_vel * delta

	var diff_pitch: float = desired_pitch - _cam_pitch
	_cam_pitch_vel += (spring_k * diff_pitch - damping * _cam_pitch_vel) * delta
	_cam_pitch += _cam_pitch_vel * delta

	# Smooth camera distance zoom interpolation
	camera_distance = lerpf(camera_distance, desired_dist, clampf(10.0 * delta, 0.0, 1.0))

	# Decay camera shake offset
	if _cam_shake_offset.length_squared() > 0.00001:
		_cam_shake_offset = _cam_shake_offset.lerp(Vector3.ZERO, clampf(14.0 * delta, 0.0, 1.0))

	if _spring_arm:
		_spring_arm.rotation.y = _cam_yaw
		_spring_arm.rotation.x = _cam_pitch
		_spring_arm.spring_length = camera_distance
		if is_selfie_mode:
			_spring_arm.position = Vector3(0.0, shoulder_height + 0.15, 0.0) + _cam_shake_offset
		elif is_third_person:
			_spring_arm.position = Vector3(shoulder_offset_x, shoulder_height, 0.0) + _cam_shake_offset

		# Dynamic spring arm occlusion recovery: prevent camera from clipping inside character mesh
		if is_third_person and _model_root:
			var hit_dist: float = _spring_arm.get_hit_length()
			if hit_dist < 0.70 and not is_selfie_mode:
				_model_root.visible = false
			else:
				_model_root.visible = true

	# Dynamic sprint FOV modulation with Genshin dash punch
	if _camera:
		var target_fov: float = base_fov
		if is_selfie_mode:
			target_fov = 68.0 # Cinematic portrait framing
		elif _dash_impulse_timer > 0.0:
			target_fov = sprint_fov + 2.5 # Instant Genshin dash punch
		elif _is_sprinting and velocity.length() > 4.2:
			target_fov = sprint_fov
		_camera.fov = lerpf(_camera.fov, target_fov, clampf(8.0 * delta, 0.0, 1.0))

func toggle_selfie_mode() -> bool:
	set_selfie_mode(not is_selfie_mode)
	return is_selfie_mode

func set_selfie_mode(enabled: bool) -> void:
	is_selfie_mode = enabled
	if is_selfie_mode:
		_target_camera_distance = 2.6
		if _facial_controller and _facial_controller.has_method("trigger_joy"):
			_facial_controller.trigger_joy(4.0)
	else:
		_target_camera_distance = 3.2
	selfie_mode_changed.emit(is_selfie_mode)

func set_facial_expression_by_index(idx: int) -> void:
	if not _facial_controller or not _facial_controller.has_method("set_expression"):
		return
	match idx:
		1:
			if _facial_controller.has_method("trigger_joy"):
				_facial_controller.trigger_joy(5.0)
		2:
			if _facial_controller.has_method("trigger_surprise"):
				_facial_controller.trigger_surprise(4.0)
		3:
			if _facial_controller.has_method("trigger_combat"):
				_facial_controller.trigger_combat(true)
		4:
			_facial_controller.set_expression(AnimeFacialController.ExpressionMode.WIND_SQUINT, 4.0)
		_:
			_facial_controller.set_expression(AnimeFacialController.ExpressionMode.NEUTRAL, 0.0)

func capture_selfie() -> Dictionary:
	_play_shutter_sound()
	var current_expr: int = _facial_controller.get_expression() if (_facial_controller and _facial_controller.has_method("get_expression")) else 0
	var photo_data: Dictionary = {
		"position": global_position if is_inside_tree() else position,
		"camera_yaw": _cam_yaw,
		"camera_pitch": _cam_pitch,
		"expression_mode": current_expr,
		"timestamp": Time.get_unix_time_from_system()
	}
	selfie_captured.emit(photo_data)
	return photo_data

func _play_shutter_sound() -> void:
	if not _audio_player or not is_inside_tree():
		return
	if _shutter_wav == null:
		_shutter_wav = _generate_shutter_wav()
	if _shutter_wav:
		_audio_player.stream = _shutter_wav
		_audio_player.volume_db = -12.0
		_audio_player.play()

static func _generate_shutter_wav() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.15
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = exp(-45.0 * t)
		var click: float = sin(t * TAU * 1800.0) * env * 0.85
		var val_16: int = int(clampf(click, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

func mount_steed(steed: Node3D) -> bool:
	if active_mount != null:
		return false
	active_mount = steed
	if steed.has_method("mount_player"):
		steed.mount_player(self)
	mount_state_changed.emit(true)
	return true

func dismount_steed() -> void:
	if active_mount == null:
		return
	var steed: Node3D = active_mount
	active_mount = null
	if steed.has_method("dismount_player"):
		steed.dismount_player()
	mount_state_changed.emit(false)

func is_mounted() -> bool:
	return active_mount != null

func get_camera_yaw() -> float:
	return _cam_yaw

func get_camera_pitch() -> float:
	return _cam_pitch

func get_locomotion_state() -> LocomotionState:
	return _loco_state

func is_sprinting() -> bool:
	return _is_sprinting and Vector2(velocity.x, velocity.z).length() > 3.0

func get_weapon_system() -> Node3D:
	return _weapon_system

func get_facial_controller() -> RefCounted:
	return _facial_controller

func toggle_weapon() -> bool:
	if _weapon_system and _weapon_system.has_method("toggle_drawn"):
		return _weapon_system.toggle_drawn()
	return false

func trigger_weapon_attack() -> bool:
	if _weapon_system and _weapon_system.has_method("trigger_attack"):
		return _weapon_system.trigger_attack()
	return false

enum OutfitMode { STANDARD = 0, BIKINI = 1, CUSTOM = 2 }
var outfit_mode: int = OutfitMode.STANDARD
var _custom_skin_mat: BaseMaterial3D = null

# =========================================================================
# MULTI-CHARACTER SWITCHING (DECOUPLED VIA CharacterRegistrySystem)
# =========================================================================
func get_active_character_index() -> int:
	return _active_character

var _last_char_switch_ms: int = 0

func switch_character() -> int:
	var next_idx: int = character_registry.switch_character() if character_registry else ((_active_character + 1) % 2)
	_set_active_character(next_idx)
	return _active_character

func _set_active_character(index: int) -> void:
	_active_character = index
	if character_registry:
		character_registry.set_active_index(index)
	if _character_instance:
		_character_instance.visible = (index == 0)
	if _douyin_instance:
		_douyin_instance.visible = (index == 1)
	# Keep weapon system only for Anime Hero
	if _weapon_system:
		_weapon_system.visible = (index == 0)

	# Retarget procedural animator to the active character's skeleton
	var target_sk: Skeleton3D = _douyin_skeleton if index == 1 else _character_skeleton
	if _anime_animator and target_sk:
		_anime_animator.setup(target_sk)
		_anime_animator.update(0.016, 0.0, true, false, false)

	# Adjust breast physics amplitude per character:
	# Anime = C-cup (scale 1.0), Douyin = B- (scale 0.68 — smaller, subtler sway)
	if _anime_animator and "bust_physics_scale" in _anime_animator:
		_anime_animator.bust_physics_scale = 0.68 if index == 1 else 1.0

	# Refresh perspective mesh/head visibility
	_update_mesh_visibility_for_perspective(is_third_person)


func _build_douyin_character() -> void:
	var douyin_path: String = "res://presentation/assets/models/douyin_asian_character.glb"
	if not ResourceLoader.exists(douyin_path) and not FileAccess.file_exists(ProjectSettings.globalize_path(douyin_path)):
		return # SFW Mode — Douyin character untracked

	var douyin_scn: PackedScene = load(douyin_path) as PackedScene
	if not douyin_scn:
		return

	_douyin_instance = douyin_scn.instantiate()
	_douyin_instance.name = "DouyinAsianBeautyMesh"
	_douyin_instance.scale = Vector3.ONE * 0.88
	_douyin_instance.rotation.y = PI
	_douyin_instance.visible = false
	_model_root.add_child(_douyin_instance)

	var sk: Skeleton3D = _douyin_instance.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk:
		_douyin_skeleton = sk
		_douyin_bust_l1_bone = sk.find_bone("J_Sec_L_Bust1")
		_douyin_bust_l2_bone = sk.find_bone("J_Sec_L_Bust2")
		_douyin_bust_r1_bone = sk.find_bone("J_Sec_R_Bust1")
		_douyin_bust_r2_bone = sk.find_bone("J_Sec_R_Bust2")
		_douyin_hips_bone = sk.find_bone("J_Bip_C_Hips")
		_douyin_spine_bone = sk.find_bone("J_Bip_C_Spine")
		_douyin_shoulder_l_bone = sk.find_bone("J_Bip_L_Shoulder")
		_douyin_shoulder_r_bone = sk.find_bone("J_Bip_R_Shoulder")

	# Clean Douyin hair (remove bandage clips)
	var hair_mi: MeshInstance3D = null
	for child in _douyin_instance.find_children("*", "MeshInstance3D", true, false):
		if child.name.to_lower().contains("hair"):
			hair_mi = child as MeshInstance3D
			break
	if hair_mi and hair_mi.mesh:
		var orig_hair_mesh: Mesh = hair_mi.mesh
		var bob_mesh: ArrayMesh = ArrayMesh.new()
		for s in range(orig_hair_mesh.get_surface_count()):
			if s >= 2:
				continue
			bob_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, orig_hair_mesh.surface_get_arrays(s))
		hair_mi.mesh = bob_mesh

	# Body mesh and default materials
	for child in _douyin_instance.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = child as MeshInstance3D
		if mi and mi.name == "Body":
			_douyin_body_mesh_instance = mi
			_douyin_default_body_mesh = mi.mesh
			_douyin_default_body_materials.clear()
			for s in range(mi.mesh.get_surface_count()):
				var m = mi.mesh.surface_get_material(s)
				if m:
					_douyin_default_body_materials.append(m)
			break

	if wardrobe:
		wardrobe.setup_douyin(_douyin_body_mesh_instance, _douyin_skeleton, _douyin_default_body_materials)
		_sync_douyin_from_wardrobe()

func _sync_douyin_from_wardrobe() -> void:
	if not wardrobe:
		return
	_douyin_outfit_mode = wardrobe.douyin_outfit_mode
	_douyin_bikini_body_mesh = wardrobe.douyin_bikini_body_mesh
	_douyin_nude_body_mesh = wardrobe.douyin_nude_body_mesh
	_douyin_bikini_mat = wardrobe.douyin_bikini_mat
	_douyin_nude_mat = wardrobe.douyin_nude_mat

func _sync_anime_from_wardrobe() -> void:
	if not wardrobe:
		return
	outfit_mode = wardrobe.anime_outfit_mode
	is_bikini_outfit = (outfit_mode != PlayerWardrobeSystem.AnimeOutfitMode.STANDARD)
	_bikini_body_mesh = wardrobe.anime_bikini_body_mesh
	_nude_body_mesh = wardrobe.anime_nude_body_mesh
	_bikini_skin_mat = wardrobe.anime_bikini_mat


func _apply_douyin_body_shape() -> void:
	if not _douyin_skeleton:
		return
	# Golden ratio natural skeletal pose: keep bone hierarchy clean (avoids parent bone cascading shear and distortion)
	if _douyin_hips_bone != -1:
		_douyin_skeleton.set_bone_pose_scale(_douyin_hips_bone, Vector3.ONE)
	if _douyin_spine_bone != -1:
		_douyin_skeleton.set_bone_pose_scale(_douyin_spine_bone, Vector3.ONE)
	if _douyin_shoulder_l_bone != -1:
		_douyin_skeleton.set_bone_pose_scale(_douyin_shoulder_l_bone, Vector3.ONE)
		var rest_sh_l = _douyin_skeleton.get_bone_rest(_douyin_shoulder_l_bone).origin
		_douyin_skeleton.set_bone_pose_position(_douyin_shoulder_l_bone, rest_sh_l + Vector3(0.016, 0.008, 0.0))
	if _douyin_shoulder_r_bone != -1:
		_douyin_skeleton.set_bone_pose_scale(_douyin_shoulder_r_bone, Vector3.ONE)
		var rest_sh_r = _douyin_skeleton.get_bone_rest(_douyin_shoulder_r_bone).origin
		_douyin_skeleton.set_bone_pose_position(_douyin_shoulder_r_bone, rest_sh_r + Vector3(-0.016, 0.008, 0.0))

# (Wardrobe & outfit mesh sculpting delegated to PlayerWardrobeSystem)

func cycle_outfit() -> int:
	if wardrobe:
		wardrobe.cycle_anime_outfit()
		_sync_anime_from_wardrobe()
		return outfit_mode
	return 0

func set_outfit_mode(mode: int) -> void:
	if wardrobe:
		wardrobe.set_anime_outfit_mode(mode)
		_sync_anime_from_wardrobe()

func cycle_douyin_outfit() -> int:
	if wardrobe:
		wardrobe.cycle_douyin_outfit()
		_sync_douyin_from_wardrobe()
		return _douyin_outfit_mode
	return 0

func _set_douyin_outfit_mode(mode: int) -> void:
	if wardrobe:
		wardrobe.set_douyin_outfit_mode(mode)
		_sync_douyin_from_wardrobe()

func set_bikini_outfit(enabled: bool) -> void:
	set_outfit_mode(OutfitMode.BIKINI if enabled else OutfitMode.STANDARD)

func toggle_bikini_outfit() -> bool:
	if outfit_mode != OutfitMode.STANDARD:
		set_outfit_mode(OutfitMode.STANDARD)
	else:
		set_outfit_mode(OutfitMode.BIKINI)
	return is_bikini_outfit

## Contract-compatible alias for existing camera/tests
func move_walker(delta: float, wish_dir: Vector3, is_sprinting_flag: bool, want_jump: bool) -> Vector3:
	move_character(delta, wish_dir, is_sprinting_flag, want_jump)
	return get_eye_position()

# =========================================================================
# PROCEDURAL AUDIO GENERATION (16-bit PCM CC0 Clean-Room Synthesizers)
# =========================================================================
static func _init_procedural_audio() -> void:
	if _step_grass_wav != null:
		return
	_step_grass_wav = _generate_footstep_pcm(0.08, 22050, "grass")
	_step_stone_wav = _generate_footstep_pcm(0.06, 22050, "stone")
	_step_water_wav = _generate_footstep_pcm(0.10, 22050, "water")
	_step_sand_wav = _generate_footstep_pcm(0.09, 22050, "sand")
	_step_snow_wav = _generate_footstep_pcm(0.09, 22050, "snow")
	_land_thud_wav = _generate_land_thud_pcm(0.18, 22050)

static func _generate_footstep_pcm(duration: float, rate: int, surface: String) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var noise_state: float = 0.42
	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var envelope: float = pow(1.0 - (t / duration), 2.5)
		var sample: float = 0.0

		match surface:
			"snow":
				# Crisp crunching ice crystal compression
				noise_state = fmod(noise_state * 47.0 + 0.31, 1.0)
				var crystal: float = (noise_state * 2.0 - 1.0) * pow(1.0 - (t / duration), 1.8)
				var low_pack: float = sin(t * 180.0 * TAU) * 0.45
				sample = (crystal * 0.65 + low_pack * 0.35) * envelope * 0.30
			"water":
				# Frequency sweep downward bubble chirp
				var freq: float = lerpf(750.0, 320.0, t / duration)
				sample = sin(t * freq * TAU) * envelope * 0.32
			"stone":
				# Crisp mineral click with rapid decay
				noise_state = fmod(noise_state * 37.0 + 0.13, 1.0)
				var click: float = (noise_state * 2.0 - 1.0) * pow(1.0 - (t / duration), 6.0)
				sample = (sin(t * 2200.0 * TAU) * 0.25 + click * 0.75) * envelope * 0.30
			"sand":
				# Soft granular sliding friction
				noise_state = fmod(noise_state * 43.0 + 0.29, 1.0)
				var grain: float = (noise_state * 2.0 - 1.0)
				sample = (sin(t * 280.0 * TAU) * 0.20 + grain * 0.80) * envelope * 0.22
			_: # grass / loam
				# Filtered organic crunch
				noise_state = fmod(noise_state * 31.0 + 0.17, 1.0)
				var crunch: float = (noise_state * 2.0 - 1.0)
				sample = (sin(t * 420.0 * TAU) * 0.35 + crunch * 0.65) * envelope * 0.24

		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_land_thud_pcm(duration: float, rate: int) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var noise_state: float = 0.81
	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var envelope: float = pow(1.0 - (t / duration), 2.0)
		# Deep ground resonance (95 Hz) + muffled soil impact
		noise_state = fmod(noise_state * 29.0 + 0.23, 1.0)
		var rumble: float = (noise_state * 2.0 - 1.0) * 0.25
		var low_thud: float = sin(t * 95.0 * TAU) * 0.75
		var sample: float = (low_thud + rumble) * envelope * 0.45

		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

