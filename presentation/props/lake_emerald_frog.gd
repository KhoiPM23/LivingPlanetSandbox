class_name LakeEmeraldFrog
extends Node3D

## Living Planet Sandbox — Lake Emerald Tree Frog & Water Lily Perch (Block 54)
## Features:
## 1. Cute stylized Emerald Frog perched on floating lily pads on Grand Lake
## 2. Inflatable vocal throat sac pulsing rhythmically with procedural 'croak' synth
## 3. Dynamic reaction: jumps with parabolic splash dive when player approaches within 2.8m
## 4. Spawns water ripple wave rings upon diving into lake surface

signal frog_dived(pos: Vector3)

enum FrogState { BASKING, ALERT, DIVING, UNDERWATER }

var current_state: FrogState = FrogState.BASKING
var lily_pad_pos: Vector3 = Vector3.ZERO
var _anim_time: float = 0.0
var _croak_timer: float = 4.0
var _dive_time: float = 0.0
var _dive_start: Vector3 = Vector3.ZERO
var _dive_target: Vector3 = Vector3.ZERO

# Mesh Nodes
var _body_mesh: MeshInstance3D = null
var _throat_sac: MeshInstance3D = null
var _eye_left: MeshInstance3D = null
var _eye_right: MeshInstance3D = null
var _legs: Array[MeshInstance3D] = []
var _audio_player: AudioStreamPlayer3D = null

# Materials
static var _skin_mat: StandardMaterial3D = null
static var _belly_mat: StandardMaterial3D = null
static var _eye_mat: StandardMaterial3D = null
static var _croak_wav: AudioStreamWAV = null

func _init() -> void:
	name = "LakeEmeraldFrog"
	_init_materials()
	_build_frog_model()
	_build_audio_emitter()

func _ready() -> void:
	lily_pad_pos = position

static func _init_materials() -> void:
	if _skin_mat != null:
		return

	_skin_mat = StandardMaterial3D.new()
	_skin_mat.albedo_color = Color(0.12, 0.72, 0.28) # Vibrant emerald green
	_skin_mat.roughness = 0.35
	_skin_mat.metallic = 0.10

	_belly_mat = StandardMaterial3D.new()
	_belly_mat.albedo_color = Color(0.92, 0.95, 0.55) # Soft pastel cream belly
	_belly_mat.roughness = 0.50

	_eye_mat = StandardMaterial3D.new()
	_eye_mat.albedo_color = Color(0.05, 0.05, 0.05) # Glossy black pupil with gold iris
	_eye_mat.roughness = 0.15

	_croak_wav = _generate_croak_wav()

func _build_frog_model() -> void:
	# 1. Bulbous Emerald Body
	_body_mesh = MeshInstance3D.new()
	var b_sphere: SphereMesh = SphereMesh.new()
	b_sphere.radius = 0.15
	b_sphere.height = 0.30
	b_sphere.radial_segments = 12
	b_sphere.rings = 6
	_body_mesh.mesh = b_sphere
	_body_mesh.material_override = _skin_mat
	_body_mesh.scale = Vector3(1.1, 0.75, 1.35)
	_body_mesh.position = Vector3(0.0, 0.10, 0.0)
	add_child(_body_mesh)

	# 2. Inflatable Cream Throat Sac (expands during croak)
	_throat_sac = MeshInstance3D.new()
	var t_sphere: SphereMesh = SphereMesh.new()
	t_sphere.radius = 0.09
	t_sphere.height = 0.18
	_throat_sac.mesh = t_sphere
	_throat_sac.material_override = _belly_mat
	_throat_sac.position = Vector3(0.0, 0.06, 0.12)
	add_child(_throat_sac)

	# 3. Big Bulbous Eyes
	var e_mesh: SphereMesh = SphereMesh.new()
	e_mesh.radius = 0.045
	e_mesh.height = 0.09

	_eye_left = MeshInstance3D.new()
	_eye_left.mesh = e_mesh
	_eye_left.material_override = _eye_mat
	_eye_left.position = Vector3(-0.09, 0.18, 0.08)
	add_child(_eye_left)

	_eye_right = MeshInstance3D.new()
	_eye_right.mesh = e_mesh
	_eye_right.material_override = _eye_mat
	_eye_right.position = Vector3(0.09, 0.18, 0.08)
	add_child(_eye_right)

	# 4. Crouched Hind Legs
	var leg_coords = [
		Vector3(-0.14, 0.05, -0.06),
		Vector3(0.14, 0.05, -0.06),
		Vector3(-0.11, 0.04, 0.10),
		Vector3(0.11, 0.04, 0.10)
	]
	for l_pos in leg_coords:
		var leg_box: BoxMesh = BoxMesh.new()
		leg_box.size = Vector3(0.06, 0.05, 0.12)
		var l_mi: MeshInstance3D = MeshInstance3D.new()
		l_mi.mesh = leg_box
		l_mi.material_override = _skin_mat
		l_mi.position = l_pos
		add_child(l_mi)
		_legs.append(l_mi)

func _build_audio_emitter() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "FrogAudio"
	_audio_player.stream = _croak_wav
	_audio_player.unit_size = 3.0
	_audio_player.max_distance = 14.0
	_audio_player.volume_db = -5.0
	add_child(_audio_player)

func update_behavior(delta: float, player_pos: Vector3 = Vector3.ZERO) -> void:
	_anim_time += delta
	_croak_timer -= delta

	if current_state == FrogState.UNDERWATER:
		# Gradually respawn on lily pad after 12 seconds
		if _croak_timer <= -12.0:
			current_state = FrogState.BASKING
			position = lily_pad_pos
			visible = true
			rotation = Vector3.ZERO
			_croak_timer = randf_range(3.0, 7.0)
		return

	if current_state == FrogState.DIVING:
		_dive_time += delta * 2.2
		if _dive_time >= 1.0:
			current_state = FrogState.UNDERWATER
			visible = false
			frog_dived.emit(position)
			return

		# Parabolic leaping arc into lake water
		var t: float = _dive_time
		position.x = lerpf(_dive_start.x, _dive_target.x, t)
		position.z = lerpf(_dive_start.z, _dive_target.z, t)
		var arch_h: float = sin(t * PI) * 0.8
		position.y = lerpf(_dive_start.y, -0.4, t) + arch_h
		rotation.x = lerpf(-deg_to_rad(30.0), deg_to_rad(65.0), t)
		return

	# Distance to player
	var dist_p: float = 999.0
	if player_pos != Vector3.ZERO:
		dist_p = global_position.distance_to(player_pos) if is_inside_tree() else position.distance_to(player_pos)

	# Flee dive trigger
	if dist_p < 2.8 and current_state != FrogState.DIVING:
		current_state = FrogState.DIVING
		_dive_time = 0.0
		_dive_start = position
		# Dive away from player into lake water
		var flee_dir: Vector3 = (position - player_pos).normalized()
		flee_dir.y = 0.0
		if flee_dir.length_squared() < 0.01:
			flee_dir = Vector3(1.0, 0.0, 0.0)
		_dive_target = position + flee_dir * randf_range(1.8, 2.8)
		if _audio_player and is_inside_tree():
			_audio_player.pitch_scale = randf_range(1.2, 1.35)
			_audio_player.play()
		return

	if dist_p < 6.0:
		current_state = FrogState.ALERT
		var dir: Vector3 = (player_pos - position).normalized()
		var target_yaw: float = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 3.5)
	else:
		current_state = FrogState.BASKING

	# Basking: Throat pulsing & occasional croaks
	if _throat_sac:
		var throat_pulse: float = 1.0 + sin(_anim_time * 4.2) * 0.35
		_throat_sac.scale = Vector3(throat_pulse, throat_pulse, throat_pulse)

	if _croak_timer <= 0.0:
		_croak_timer = randf_range(4.0, 9.0)
		if _audio_player and is_inside_tree() and randf() < 0.65:
			_audio_player.pitch_scale = randf_range(0.92, 1.08)
			_audio_player.play()

static func _generate_croak_wav(duration: float = 0.35, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		# Dual-pulse guttural ribbit envelope
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI)
		var pulse_mod: float = (sin(t * 28.0 * TAU) + 1.0) * 0.5
		var pitch: float = 175.0 - (t / duration) * 45.0
		var s: float = sin(t * pitch * TAU) * 0.65 + sin(t * pitch * 2.0 * TAU) * 0.35
		var sample: float = s * env * pulse_mod * 0.65
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
