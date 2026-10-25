class_name MountableSteedController
extends Node3D

## Living Planet Sandbox — Block 61: Mountable Steed & Prairie Companion (Thú Cưỡi Thảo Nguyên)
## Implements high-speed open-world traversal across the 720m island landscape:
## - Interactive mounting: [F] Cưỡi Hươu Thảo Nguyên (Mount Steed)
## - High-velocity 4-gait locomotion: Walk (5.2 m/s), Trot (8.5 m/s), Gallop (14.0 m/s), Spirit Leap (7.5 m/s)
## - Ground-clamping IK slope alignment (pitch & roll conforming to terrain normal)
## - Animated skeletal mesh with 4 articulated legs and swaying antlers
## - Procedural 16-bit PCM galloping hooves audio and golden stardust particles
## - Integrated socket docking for FirstPersonWalker with expanded 5.2m cinematic camera

signal player_mounted(steed: Node3D)
signal player_dismounted(steed: Node3D)
signal hoofbeat_triggered(gait: String)

enum GaitState {
	RESTING = 0,
	WALK = 1,
	TROT = 2,
	GALLOP = 3,
	LEAPING = 4
}

const INTERACT_DIST: float = 3.2
const WALK_SPEED: float = 5.2
const TROT_SPEED: float = 8.5
const GALLOP_SPEED: float = 14.0
const LEAP_VELOCITY: float = 7.5
const GRAVITY: float = 18.5

# Visual pivots
var _body_pivot: Node3D = null
var _neck_pivot: Node3D = null
var _head_pivot: Node3D = null
var _antlers: Node3D = null
var _legs: Array[Node3D] = []
var _mount_socket: Marker3D = null
var _hoof_particles: GPUParticles3D = null
var _audio_player: AudioStreamPlayer3D = null

# Materials
static var _pelt_mat: StandardMaterial3D = null
static var _antler_mat: StandardMaterial3D = null
static var _saddle_mat: StandardMaterial3D = null
static var _hoof_wav: AudioStreamWAV = null

# Movement & Physics State
var is_player_mounted: bool = false
var velocity: Vector3 = Vector3.ZERO
var current_gait: GaitState = GaitState.RESTING
var _terrain_ref: IslandTerrain = null
var _player_ref: FirstPersonWalker = null
var _facing_yaw: float = 0.0
var _anim_phase: float = 0.0
var _last_hoof_beat: float = 0.0
var _slope_pitch: float = 0.0
var _slope_roll: float = 0.0
var _lean_roll: float = 0.0

func _init() -> void:
	name = "MountablePrairieSteed"
	_init_materials()
	_init_audio()
	_build_steed_model()

func _ready() -> void:
	_clamp_to_terrain()

func setup(terrain: IslandTerrain, player: FirstPersonWalker = null) -> void:
	_terrain_ref = terrain
	_player_ref = player
	_clamp_to_terrain()

static func _init_materials() -> void:
	if _pelt_mat != null:
		return
	_pelt_mat = StandardMaterial3D.new()
	_pelt_mat.albedo_color = Color(0.88, 0.72, 0.52) # Golden fawn prairie coat
	_pelt_mat.roughness = 0.75
	_pelt_mat.rim_enabled = true
	_pelt_mat.rim = 0.35

	_antler_mat = StandardMaterial3D.new()
	_antler_mat.albedo_color = Color(0.96, 0.85, 0.40) # Celestial gilded antlers
	_antler_mat.metallic = 0.55
	_antler_mat.roughness = 0.30
	_antler_mat.emission_enabled = true
	_antler_mat.emission = Color(0.92, 0.75, 0.28)
	_antler_mat.emission_energy_multiplier = 1.4

	_saddle_mat = StandardMaterial3D.new()
	_saddle_mat.albedo_color = Color(0.25, 0.18, 0.14) # Tooled dark leather saddle
	_saddle_mat.roughness = 0.45

static func _init_audio() -> void:
	if _hoof_wav != null:
		return
	var rate: int = 22050
	var duration: float = 0.12
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = exp(-32.0 * t)
		var tone: float = sin(t * TAU * 95.0) + 0.35 * sin(t * TAU * 190.0)
		var noise: float = (randf() * 2.0 - 1.0) * 0.25
		var sample: float = (tone * 0.75 + noise) * env
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	_hoof_wav = AudioStreamWAV.new()
	_hoof_wav.format = AudioStreamWAV.FORMAT_16_BITS
	_hoof_wav.mix_rate = rate
	_hoof_wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	_hoof_wav.data = byte_data

func _build_steed_model() -> void:
	_body_pivot = Node3D.new()
	_body_pivot.name = "BodyPivot"
	_body_pivot.position = Vector3(0.0, 1.25, 0.0)
	add_child(_body_pivot)

	# Torso Capsule
	var torso: MeshInstance3D = MeshInstance3D.new()
	var t_mesh: CapsuleMesh = CapsuleMesh.new()
	t_mesh.radius = 0.42
	t_mesh.height = 1.65
	torso.mesh = t_mesh
	torso.material_override = _pelt_mat
	torso.rotation.x = deg_to_rad(90.0)
	_body_pivot.add_child(torso)

	# Saddle & Stirrup mount
	var saddle: MeshInstance3D = MeshInstance3D.new()
	var s_mesh: BoxMesh = BoxMesh.new()
	s_mesh.size = Vector3(0.72, 0.22, 0.75)
	saddle.mesh = s_mesh
	saddle.material_override = _saddle_mat
	saddle.position = Vector3(0.0, 0.38, -0.05)
	_body_pivot.add_child(saddle)

	# Mount socket for player character attachment
	_mount_socket = Marker3D.new()
	_mount_socket.name = "MountSocket"
	_mount_socket.position = Vector3(0.0, 0.48, -0.05)
	_body_pivot.add_child(_mount_socket)

	# Neck & Head
	_neck_pivot = Node3D.new()
	_neck_pivot.position = Vector3(0.0, 0.35, -0.72)
	_neck_pivot.rotation.x = deg_to_rad(-35.0)
	_body_pivot.add_child(_neck_pivot)

	var neck_mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var n_cyl: CylinderMesh = CylinderMesh.new()
	n_cyl.top_radius = 0.22
	n_cyl.bottom_radius = 0.32
	n_cyl.height = 0.85
	neck_mesh_inst.mesh = n_cyl
	neck_mesh_inst.material_override = _pelt_mat
	neck_mesh_inst.position = Vector3(0.0, 0.42, 0.0)
	_neck_pivot.add_child(neck_mesh_inst)

	_head_pivot = Node3D.new()
	_head_pivot.position = Vector3(0.0, 0.85, 0.0)
	_neck_pivot.add_child(_head_pivot)

	var head_mesh: MeshInstance3D = MeshInstance3D.new()
	var h_prism: PrismMesh = PrismMesh.new()
	h_prism.size = Vector3(0.38, 0.55, 0.32)
	head_mesh.mesh = h_prism
	head_mesh.material_override = _pelt_mat
	head_mesh.rotation.x = deg_to_rad(90.0)
	_head_pivot.add_child(head_mesh)

	# Branching Antlers
	_antlers = Node3D.new()
	_antlers.position = Vector3(0.0, 0.25, 0.05)
	_head_pivot.add_child(_antlers)

	for side in [-1.0, 1.0]:
		var beam: MeshInstance3D = MeshInstance3D.new()
		var b_cyl: CylinderMesh = CylinderMesh.new()
		b_cyl.top_radius = 0.03
		b_cyl.bottom_radius = 0.05
		b_cyl.height = 0.95
		beam.mesh = b_cyl
		beam.material_override = _antler_mat
		beam.position = Vector3(side * 0.35, 0.42, 0.0)
		beam.rotation = Vector3(deg_to_rad(15.0), 0.0, side * deg_to_rad(-28.0))
		_antlers.add_child(beam)

	# 4 Articulated Legs
	_legs.clear()
	var leg_coords: Array[Vector3] = [
		Vector3(-0.32, 0.0, -0.65), # Front Left
		Vector3(0.32, 0.0, -0.65),  # Front Right
		Vector3(-0.35, 0.0, 0.65),  # Back Left
		Vector3(0.35, 0.0, 0.65)   # Back Right
	]

	for i in range(4):
		var leg_pivot: Node3D = Node3D.new()
		leg_pivot.name = "LegPivot_%d" % i
		leg_pivot.position = leg_coords[i]
		_body_pivot.add_child(leg_pivot)

		var upper: MeshInstance3D = MeshInstance3D.new()
		var u_cyl: CylinderMesh = CylinderMesh.new()
		u_cyl.top_radius = 0.11
		u_cyl.bottom_radius = 0.08
		u_cyl.height = 0.72
		upper.mesh = u_cyl
		upper.material_override = _pelt_mat
		upper.position = Vector3(0.0, -0.36, 0.0)
		leg_pivot.add_child(upper)

		var lower_pivot: Node3D = Node3D.new()
		lower_pivot.position = Vector3(0.0, -0.72, 0.0)
		leg_pivot.add_child(lower_pivot)

		var lower: MeshInstance3D = MeshInstance3D.new()
		var l_cyl: CylinderMesh = CylinderMesh.new()
		l_cyl.top_radius = 0.08
		l_cyl.bottom_radius = 0.05
		l_cyl.height = 0.62
		lower.mesh = l_cyl
		lower.material_override = _pelt_mat
		lower.position = Vector3(0.0, -0.31, 0.0)
		lower_pivot.add_child(lower)

		_legs.append(leg_pivot)

	# Particles & Audio
	_hoof_particles = GPUParticles3D.new()
	_hoof_particles.name = "HoofStardust"
	_hoof_particles.amount = 18
	_hoof_particles.lifetime = 0.45
	_hoof_particles.emitting = false
	var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	p_mat.emission_sphere_radius = 0.40
	p_mat.direction = Vector3(0.0, 0.6, -1.0)
	p_mat.spread = 25.0
	p_mat.initial_velocity_min = 2.0
	p_mat.initial_velocity_max = 4.5
	p_mat.gravity = Vector3(0.0, -2.5, 0.0)
	p_mat.scale_min = 0.08
	p_mat.scale_max = 0.22
	p_mat.color = Color(1.0, 0.88, 0.45, 0.75)
	_hoof_particles.process_material = p_mat

	var sp_mesh: SphereMesh = SphereMesh.new()
	sp_mesh.radius = 0.05
	sp_mesh.height = 0.10
	var sp_mat: StandardMaterial3D = StandardMaterial3D.new()
	sp_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sp_mat.albedo_color = Color(1.0, 0.92, 0.55, 0.85)
	sp_mat.emission_enabled = true
	sp_mat.emission = Color(1.0, 0.85, 0.35)
	sp_mesh.material = sp_mat
	_hoof_particles.draw_pass_1 = sp_mesh
	add_child(_hoof_particles)

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "SteedAudio"
	_audio_player.unit_size = 4.0
	_audio_player.max_distance = 45.0
	add_child(_audio_player)

func mount_player(player: FirstPersonWalker) -> bool:
	if is_player_mounted:
		return false
	_player_ref = player
	is_player_mounted = true
	_player_ref.visible = true

	# Expand camera distance for majestic open-world riding view
	_player_ref.camera_distance = 5.2
	_player_ref._target_camera_distance = 5.2

	player_mounted.emit(self)
	return true

func dismount_player() -> void:
	if not is_player_mounted:
		return
	is_player_mounted = false
	if _player_ref:
		# Reposition player to left side of mount on ground
		var side_offset: Vector3 = Vector3(cos(_facing_yaw), 0.0, -sin(_facing_yaw)) * 1.45
		var steed_pos: Vector3 = global_position if is_inside_tree() else position
		if _player_ref.is_inside_tree():
			_player_ref.global_position = steed_pos + side_offset
		else:
			_player_ref.position = steed_pos + side_offset
		_player_ref.velocity = Vector3.ZERO
		_player_ref.camera_distance = 3.2
		_player_ref._target_camera_distance = 3.2

	if _hoof_particles:
		_hoof_particles.emitting = false
	player_dismounted.emit(self)

## Steed movement and physics step called during riding loop
func step_mounted_motion(delta: float, input_dir: Vector3, is_sprint: bool, want_jump: bool) -> void:
	var on_ground: bool = _is_grounded()
	var has_input: bool = input_dir.length_squared() > 0.01

	# 1. Gait speed calculation
	var target_speed: float = 0.0
	if has_input:
		if is_sprint:
			target_speed = GALLOP_SPEED
			current_gait = GaitState.GALLOP
		else:
			target_speed = TROT_SPEED
			current_gait = GaitState.TROT
	else:
		target_speed = 0.0
		current_gait = GaitState.RESTING

	# 2. Horizontal Acceleration & Turning
	if has_input:
		var move_dir: Vector3 = input_dir.normalized()
		var target_vel_h: Vector3 = move_dir * target_speed
		velocity.x = lerpf(velocity.x, target_vel_h.x, clampf(9.0 * delta, 0.0, 1.0))
		velocity.z = lerpf(velocity.z, target_vel_h.z, clampf(9.0 * delta, 0.0, 1.0))

		var target_yaw: float = atan2(-move_dir.x, -move_dir.z)
		var yaw_diff: float = wrapf(target_yaw - _facing_yaw, -PI, PI)
		_facing_yaw = lerp_angle(_facing_yaw, target_yaw, clampf(8.5 * delta, 0.0, 1.0))

		# Aerodynamic banking lean on turns
		var target_lean: float = clampf(-yaw_diff * 0.25, -deg_to_rad(18.0), deg_to_rad(18.0))
		_lean_roll = lerpf(_lean_roll, target_lean, clampf(8.0 * delta, 0.0, 1.0))
	else:
		velocity.x = lerpf(velocity.x, 0.0, clampf(7.5 * delta, 0.0, 1.0))
		velocity.z = lerpf(velocity.z, 0.0, clampf(7.5 * delta, 0.0, 1.0))
		_lean_roll = lerpf(_lean_roll, 0.0, clampf(8.0 * delta, 0.0, 1.0))

	# 3. Vertical Physics & Spirit Leap
	if on_ground:
		if want_jump:
			velocity.y = LEAP_VELOCITY
			current_gait = GaitState.LEAPING
		else:
			velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	# Position step
	position += velocity * delta
	_clamp_to_terrain()

	# 4. Slope Ground Clamping IK
	_update_slope_alignment(delta)

	# 5. Leg trot/gallop animation & audio
	_update_steed_animation(delta)

	# 6. Synchronize mounted player transform
	if _player_ref and is_player_mounted:
		var socket_pos: Vector3 = _mount_socket.global_position if _mount_socket.is_inside_tree() else (position + _mount_socket.position)
		if _player_ref.is_inside_tree():
			_player_ref.global_position = socket_pos
		else:
			_player_ref.position = socket_pos
		_player_ref.velocity = velocity
		_player_ref._model_yaw = _facing_yaw

func _is_grounded() -> bool:
	if _terrain_ref:
		var gh: float = _terrain_ref.get_height_at(position.x, position.z)
		return position.y <= gh + 0.15
	return position.y <= 0.15

func _clamp_to_terrain() -> void:
	if _terrain_ref:
		var gh: float = _terrain_ref.get_height_at(position.x, position.z)
		if position.y < gh:
			position.y = gh

func _update_slope_alignment(delta: float) -> void:
	if not _terrain_ref or not _body_pivot:
		return
	var norm: Vector3 = _terrain_ref.get_normal_at(position.x, position.z)
	var fwd: Vector3 = Vector3(-sin(_facing_yaw), 0.0, -cos(_facing_yaw))
	var rgt: Vector3 = Vector3(cos(_facing_yaw), 0.0, -sin(_facing_yaw))

	var target_pitch: float = clampf(-fwd.dot(norm) * 0.45, -deg_to_rad(22.0), deg_to_rad(22.0))
	var target_roll: float = clampf(rgt.dot(norm) * 0.45, -deg_to_rad(16.0), deg_to_rad(16.0))

	_slope_pitch = lerpf(_slope_pitch, target_pitch, clampf(8.0 * delta, 0.0, 1.0))
	_slope_roll = lerpf(_slope_roll, target_roll + _lean_roll, clampf(8.0 * delta, 0.0, 1.0))
	_body_pivot.rotation = Vector3(_slope_pitch, _facing_yaw, _slope_roll)

func _update_steed_animation(delta: float) -> void:
	var h_speed: float = Vector2(velocity.x, velocity.z).length()
	if h_speed > 0.35:
		var anim_rate: float = clampf(h_speed * 1.15, 4.0, 14.0)
		_anim_phase = wrapf(_anim_phase + anim_rate * delta, 0.0, TAU)

		# 4-beat gallop articulation
		if _legs.size() == 4:
			_legs[0].rotation.x = sin(_anim_phase) * 0.65       # Front L
			_legs[1].rotation.x = sin(_anim_phase + PI) * 0.65  # Front R
			_legs[2].rotation.x = sin(_anim_phase + PI * 0.6) * 0.60 # Back L
			_legs[3].rotation.x = sin(_anim_phase + PI * 1.6) * 0.60 # Back R

		# Spine & head gallop cadence
		if _neck_pivot:
			_neck_pivot.rotation.x = deg_to_rad(-35.0) + sin(_anim_phase * 2.0) * deg_to_rad(6.0)

		# Hoofbeat audio trigger
		if (_anim_phase < PI and _last_hoof_beat >= PI) or (_anim_phase >= PI and _last_hoof_beat < PI):
			_play_hoofbeat()
		_last_hoof_beat = _anim_phase

		if _hoof_particles:
			_hoof_particles.emitting = is_player_mounted
	else:
		# Idle resting stance
		if _legs.size() == 4:
			for leg: Node3D in _legs:
				leg.rotation.x = lerpf(leg.rotation.x, 0.0, clampf(6.0 * delta, 0.0, 1.0))
		if _hoof_particles:
			_hoof_particles.emitting = false

func _play_hoofbeat() -> void:
	if _audio_player and is_inside_tree() and _hoof_wav:
		_audio_player.stream = _hoof_wav
		_audio_player.pitch_scale = randf_range(0.92, 1.08)
		_audio_player.volume_db = -16.0 if current_gait == GaitState.GALLOP else -20.0
		_audio_player.play()
	hoofbeat_triggered.emit("gallop" if current_gait == GaitState.GALLOP else "trot")
