class_name HighlandSheep
extends Node3D

## Living Planet Sandbox — Fluffy Highland Sheep (Block 53)
## Features:
## 1. Stylized fluffy sheep model with round wool body, cute dark head, and 4 animated legs
## 2. Behavioral states: GRAZING (nibbling grass), WANDERING (stepping), LOOKING (observing player), HAPPY_PET (jumping with heart particles)
## 3. Procedural 16-bit PCM 'baa' synthesizer
## 4. Interactive petting [E] with tail wagging, heart sparkles, and soft wool reward

signal sheep_petted()
signal threat_alerted(threat_pos: Vector3)

enum SheepState { GRAZING, WANDERING, LOOKING, HAPPY_PET, ALERT, PANIC_FLEE }

var current_state: SheepState = SheepState.GRAZING
var wander_target: Vector3 = Vector3.ZERO
var flee_target: Vector3 = Vector3.ZERO
var base_pos: Vector3 = Vector3.ZERO
var tether_radius: float = 8.5
var move_speed: float = 1.2
var _anim_time: float = 0.0
var _state_timer: float = 3.0
var _pet_time: float = 0.0
var _flee_timer: float = 0.0
var is_wet: bool = false
var _shake_timer: float = 0.0

# Node references
var _body_mesh: MeshInstance3D = null
var _head_root: Node3D = null
var _head_mesh: MeshInstance3D = null
var _legs: Array[MeshInstance3D] = []
var _tail_mesh: MeshInstance3D = null
var _heart_particles: GPUParticles3D = null
var _audio_player: AudioStreamPlayer3D = null

# Materials
static var _wool_mat: StandardMaterial3D = null
static var _face_mat: StandardMaterial3D = null
static var _horn_mat: StandardMaterial3D = null
static var _baa_wav: AudioStreamWAV = null

func _init() -> void:
	name = "HighlandSheep"
	_init_materials()
	_build_sheep_model()
	_build_heart_particles()
	_build_audio_emitter()

func _ready() -> void:
	base_pos = global_position if is_inside_tree() else position
	wander_target = base_pos

static func _init_materials() -> void:
	if _wool_mat != null:
		return
	_wool_mat = StandardMaterial3D.new()
	_wool_mat.albedo_color = Color(0.96, 0.95, 0.92) # Soft fluffy warm white
	_wool_mat.roughness = 0.95

	_face_mat = StandardMaterial3D.new()
	_face_mat.albedo_color = Color(0.22, 0.18, 0.16) # Dark chocolate face and hooves
	_face_mat.roughness = 0.85

	_horn_mat = StandardMaterial3D.new()
	_horn_mat.albedo_color = Color(0.65, 0.58, 0.45) # Curved horn beige
	_horn_mat.roughness = 0.70

	_baa_wav = _generate_baa_wav()

func _build_sheep_model() -> void:
	# 1. Fluffy Wool Torso (Rounded bulbous body)
	_body_mesh = MeshInstance3D.new()
	var body_sphere: SphereMesh = SphereMesh.new()
	body_sphere.radius = 0.55
	body_sphere.height = 1.1
	body_sphere.radial_segments = 14
	body_sphere.rings = 8
	_body_mesh.mesh = body_sphere
	_body_mesh.material_override = _wool_mat
	_body_mesh.scale = Vector3(1.15, 1.0, 1.45)
	_body_mesh.position = Vector3(0.0, 0.65, 0.0)
	add_child(_body_mesh)

	# 2. Articulated Head Root
	_head_root = Node3D.new()
	_head_root.name = "SheepHead"
	_head_root.position = Vector3(0.0, 0.78, 0.62)
	add_child(_head_root)

	# Head Mesh
	_head_mesh = MeshInstance3D.new()
	var head_box: BoxMesh = BoxMesh.new()
	head_box.size = Vector3(0.32, 0.35, 0.42)
	_head_mesh.mesh = head_box
	_head_mesh.material_override = _face_mat
	_head_mesh.position = Vector3(0.0, 0.0, 0.15)
	_head_root.add_child(_head_mesh)

	# Wool Tuft atop head
	var tuft_mesh: SphereMesh = SphereMesh.new()
	tuft_mesh.radius = 0.22
	tuft_mesh.height = 0.35
	var tuft_mi: MeshInstance3D = MeshInstance3D.new()
	tuft_mi.mesh = tuft_mesh
	tuft_mi.material_override = _wool_mat
	tuft_mi.position = Vector3(0.0, 0.22, 0.10)
	_head_root.add_child(tuft_mi)

	# Ears
	for side in [-1.0, 1.0]:
		var ear_mesh: BoxMesh = BoxMesh.new()
		ear_mesh.size = Vector3(0.24, 0.08, 0.12)
		var ear_mi: MeshInstance3D = MeshInstance3D.new()
		ear_mi.mesh = ear_mesh
		ear_mi.material_override = _face_mat
		ear_mi.position = Vector3(side * 0.22, 0.08, 0.05)
		ear_mi.rotation.z = side * deg_to_rad(-18.0)
		_head_root.add_child(ear_mi)

	# 3. Four Stubby Legs
	var leg_coords = [
		Vector3(-0.32, 0.25, 0.42),  # Front Left
		Vector3(0.32, 0.25, 0.42),   # Front Right
		Vector3(-0.32, 0.25, -0.42), # Back Left
		Vector3(0.32, 0.25, -0.42)   # Back Right
	]
	for l_pos in leg_coords:
		var leg_mesh: CylinderMesh = CylinderMesh.new()
		leg_mesh.top_radius = 0.09
		leg_mesh.bottom_radius = 0.08
		leg_mesh.height = 0.50
		var l_mi: MeshInstance3D = MeshInstance3D.new()
		l_mi.mesh = leg_mesh
		l_mi.material_override = _face_mat
		l_mi.position = l_pos
		add_child(l_mi)
		_legs.append(l_mi)

	# 4. Tiny Tail
	var tail_mesh: SphereMesh = SphereMesh.new()
	tail_mesh.radius = 0.12
	tail_mesh.height = 0.20
	_tail_mesh = MeshInstance3D.new()
	_tail_mesh.mesh = tail_mesh
	_tail_mesh.material_override = _wool_mat
	_tail_mesh.position = Vector3(0.0, 0.65, -0.75)
	add_child(_tail_mesh)

func _build_heart_particles() -> void:
	_heart_particles = GPUParticles3D.new()
	_heart_particles.name = "SheepHeartParticles"
	_heart_particles.emitting = false
	_heart_particles.one_shot = true
	_heart_particles.amount = 8
	_heart_particles.lifetime = 1.3
	_heart_particles.explosiveness = 0.6

	var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(0.35, 0.2, 0.35)
	p_mat.direction = Vector3(0.0, 1.0, 0.0)
	p_mat.spread = 25.0
	p_mat.initial_velocity_min = 0.8
	p_mat.initial_velocity_max = 1.5
	p_mat.gravity = Vector3(0.0, -0.1, 0.0)
	p_mat.scale_min = 0.12
	p_mat.scale_max = 0.24
	_heart_particles.process_material = p_mat

	var heart_mesh: SphereMesh = SphereMesh.new()
	heart_mesh.radius = 0.10
	heart_mesh.height = 0.18
	var h_mat: StandardMaterial3D = StandardMaterial3D.new()
	h_mat.albedo_color = Color(1.0, 0.42, 0.68)
	h_mat.emission_enabled = true
	h_mat.emission = Color(1.0, 0.45, 0.72)
	h_mat.emission_energy_multiplier = 2.0
	heart_mesh.material = h_mat
	_heart_particles.draw_pass_1 = heart_mesh

	_heart_particles.position = Vector3(0.0, 1.1, 0.2)
	add_child(_heart_particles)

func _build_audio_emitter() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "SheepAudio"
	_audio_player.stream = _baa_wav
	_audio_player.unit_size = 5.0
	_audio_player.max_distance = 18.0
	_audio_player.volume_db = -4.0
	add_child(_audio_player)

func pet_sheep() -> void:
	current_state = SheepState.HAPPY_PET
	_pet_time = 2.5
	if _heart_particles:
		_heart_particles.restart()
		_heart_particles.emitting = true
	if _audio_player and _baa_wav and is_inside_tree():
		_audio_player.pitch_scale = randf_range(1.08, 1.25) # Happier high-pitched baa
		_audio_player.play()
	sheep_petted.emit()

func alert_threat(threat_pos: Vector3, is_immediate_danger: bool = false) -> void:
	if current_state == SheepState.HAPPY_PET and not is_immediate_danger:
		return

	if is_immediate_danger:
		current_state = SheepState.PANIC_FLEE
		_flee_timer = randf_range(4.0, 6.0)
		var self_pos: Vector3 = global_position if is_inside_tree() else position
		var away_dir: Vector3 = (self_pos - threat_pos).normalized()
		if away_dir.length_squared() < 0.001:
			away_dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
		away_dir.y = 0.0
		flee_target = self_pos + away_dir * 18.0
		if _audio_player and _baa_wav and is_inside_tree():
			_audio_player.pitch_scale = randf_range(1.25, 1.45) # Alarmed frantic baa
			_audio_player.play()
		threat_alerted.emit(threat_pos)
	else:
		if current_state != SheepState.PANIC_FLEE:
			current_state = SheepState.ALERT
			_state_timer = randf_range(3.0, 4.5)

func set_wet(wet: bool) -> void:
	is_wet = wet
	if wet and _shake_timer <= 0.0:
		_shake_timer = 1.2 # Trigger water droplet full-body shake

func update_behavior(delta: float, player_pos: Vector3 = Vector3.ZERO, is_player_sprinting: bool = false, is_player_attacking: bool = false, is_near_fire: bool = false) -> void:
	_anim_time += delta
	_state_timer -= delta

	# Full-body wet shake animation
	if _shake_timer > 0.0:
		_shake_timer -= delta
		rotation.z = sin(_anim_time * 36.0) * 0.12
		if _head_root:
			_head_root.rotation.z = -sin(_anim_time * 36.0) * 0.22
	else:
		rotation.z = 0.0
		if _head_root:
			_head_root.rotation.z = 0.0

	# Threat checks
	if is_near_fire:
		alert_threat(player_pos if player_pos != Vector3.ZERO else global_position + Vector3(1, 0, 1), true)
	elif is_player_attacking and player_pos != Vector3.ZERO and global_position.distance_to(player_pos) < 7.5:
		alert_threat(player_pos, true)
	elif is_player_sprinting and player_pos != Vector3.ZERO and global_position.distance_to(player_pos) < 5.0:
		alert_threat(player_pos, true)

	if current_state == SheepState.HAPPY_PET:
		_pet_time -= delta
		# Happy vertical hop animation
		position.y += sin(_anim_time * 12.0) * 0.02
		# Fast tail wag
		if _tail_mesh:
			_tail_mesh.rotation.y = sin(_anim_time * 16.0) * 0.45
		if _pet_time <= 0.0:
			current_state = SheepState.LOOKING
			_state_timer = 3.0
		return

	# Handle PANIC_FLEE
	if current_state == SheepState.PANIC_FLEE:
		_flee_timer -= delta
		if _head_root:
			_head_root.position.y = 0.85
			_head_root.rotation.x = deg_to_rad(-15.0) # Head up sprinting
		if _tail_mesh:
			_tail_mesh.rotation.y = sin(_anim_time * 24.0) * 0.55 # Frantic tail wag

		var flee_diff: Vector3 = flee_target - position
		flee_diff.y = 0.0
		if flee_diff.length() > 0.5 and _flee_timer > 0.0:
			var flee_dir: Vector3 = flee_diff.normalized()
			var target_yaw: float = atan2(flee_dir.x, flee_dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, delta * 8.0)
			position += flee_dir * (move_speed * 3.4) * delta

			# Fast galloping leg animation
			var gallop_swing: float = sin(_anim_time * 16.0) * 0.55
			if _legs.size() >= 4:
				_legs[0].rotation.x = gallop_swing
				_legs[1].rotation.x = -gallop_swing
				_legs[2].rotation.x = -gallop_swing
				_legs[3].rotation.x = gallop_swing
		else:
			current_state = SheepState.ALERT
			_state_timer = 3.0
		return

	# Handle ALERT
	if current_state == SheepState.ALERT:
		if _head_root:
			_head_root.position.y = 0.88
			_head_root.rotation.x = deg_to_rad(-22.0) # Head raised high vigilance
		for l in _legs:
			l.rotation.x = 0.0
		if _state_timer <= 0.0:
			current_state = SheepState.LOOKING
			_state_timer = randf_range(3.0, 5.0)
		return

	# Distance to player
	var dist_player: float = global_position.distance_to(player_pos) if player_pos != Vector3.ZERO else 999.0
	if dist_player < 5.0 and current_state != SheepState.HAPPY_PET:
		current_state = SheepState.LOOKING
		# Turn head to observe player
		var dir_to_p: Vector3 = (player_pos - global_position).normalized()
		var target_yaw: float = atan2(dir_to_p.x, dir_to_p.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 3.5)
		if _head_root:
			_head_root.position.y = 0.78 + sin(_anim_time * 2.0) * 0.03
			_head_root.rotation.x = -0.15 # Inquisitive tilt up
		return

	# State switching
	if _state_timer <= 0.0:
		if current_state == SheepState.GRAZING:
			current_state = SheepState.WANDERING
			_state_timer = randf_range(3.0, 6.0)
			# Pick random point near pasture base
			var ang: float = randf_range(0.0, TAU)
			var r: float = randf_range(1.0, tether_radius)
			wander_target = base_pos + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
			# Occasional gentle baa
			if randf() < 0.25 and _audio_player:
				_audio_player.pitch_scale = randf_range(0.95, 1.05)
				_audio_player.play()
		else:
			current_state = SheepState.GRAZING
			_state_timer = randf_range(4.0, 9.0)

	# Execute states
	if current_state == SheepState.GRAZING:
		# Head dips to grass
		if _head_root:
			_head_root.position.y = 0.35 + sin(_anim_time * 3.0) * 0.06
			_head_root.rotation.x = deg_to_rad(35.0) # Head down nibbling
		# Slow tail swish
		if _tail_mesh:
			_tail_mesh.rotation.y = sin(_anim_time * 2.5) * 0.20
		# Zero leg movement
		for l in _legs:
			l.rotation.x = 0.0

	elif current_state == SheepState.WANDERING:
		if _head_root:
			_head_root.position.y = 0.70
			_head_root.rotation.x = deg_to_rad(10.0)

		var diff: Vector3 = wander_target - position
		diff.y = 0.0
		if diff.length() > 0.4:
			var move_dir: Vector3 = diff.normalized()
			var target_yaw: float = atan2(move_dir.x, move_dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, delta * 4.0)
			position += move_dir * move_speed * delta

			# Leg walking swing
			var leg_swing: float = sin(_anim_time * 6.5) * 0.35
			if _legs.size() >= 4:
				_legs[0].rotation.x = leg_swing
				_legs[1].rotation.x = -leg_swing
				_legs[2].rotation.x = -leg_swing
				_legs[3].rotation.x = leg_swing
		else:
			current_state = SheepState.GRAZING
			_state_timer = randf_range(4.0, 8.0)

static func _generate_baa_wav(duration: float = 0.75, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		# Smooth attack, prolonged bleat envelope with vocal vibrato
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI) * (1.0 - t / duration * 0.4)
		var vibrato: float = sin(t * 5.5 * TAU) * 14.0
		var pitch: float = 240.0 + vibrato - (t / duration) * 35.0
		# Formant synthesis simulating animal vocal tract
		var fundamental: float = sin(t * pitch * TAU) * 0.65
		var harmonic2: float = sin(t * pitch * 2.0 * TAU) * 0.25
		var harmonic3: float = sin(t * pitch * 3.0 * TAU) * 0.10
		var sample: float = (fundamental + harmonic2 + harmonic3) * env * 0.6
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
