class_name LakeMallardDuck
extends Node3D

## Living Planet Sandbox — Lake Mallard Duck Waterfowl (Block 53)
## Features:
## 1. Stylized mallard duck with iridescent emerald head, yellow bill, white neck ring, and buoyant body
## 2. Realistic dabbling waterfowl behavior: swimming in gentle arcs, bobbing on lake ripples, dabbling head dip
## 3. Procedural 16-bit PCM 'quack' audio synthesizer
## 4. Spawns water wake ripples when paddling across the lake surface

var swim_center: Vector3 = Vector3(45.0, 0.05, 82.0)
var swim_radius: float = 8.0
var swim_speed: float = 0.85
var _anim_time: float = 0.0
var _swim_angle: float = 0.0
var _dabble_timer: float = 6.0
var _is_dabbling: bool = false
var _dabble_time: float = 0.0

# Nodes
var _body_mesh: MeshInstance3D = null
var _head_root: Node3D = null
var _left_wing: Node3D = null
var _right_wing: Node3D = null
var _audio_player: AudioStreamPlayer3D = null

# Flight State
var is_flying: bool = false
var _flight_timer: float = 0.0

# Materials
static var _body_mat: StandardMaterial3D = null
static var _head_mat: StandardMaterial3D = null
static var _bill_mat: StandardMaterial3D = null
static var _quack_wav: AudioStreamWAV = null

func _init() -> void:
	name = "LakeMallardDuck"
	_init_materials()
	_build_duck_model()
	_build_audio_emitter()

func _ready() -> void:
	swim_center = position

static func _init_materials() -> void:
	if _body_mat != null:
		return
	_body_mat = StandardMaterial3D.new()
	_body_mat.albedo_color = Color(0.42, 0.32, 0.22) # Mottled brown drake plumage
	_body_mat.roughness = 0.75

	_head_mat = StandardMaterial3D.new()
	_head_mat.albedo_color = Color(0.06, 0.45, 0.22) # Iridescent emerald green
	_head_mat.metallic = 0.40
	_head_mat.roughness = 0.35

	_bill_mat = StandardMaterial3D.new()
	_bill_mat.albedo_color = Color(0.95, 0.78, 0.12) # Warm golden bill
	_bill_mat.roughness = 0.50

	_quack_wav = _generate_quack_wav()

func _build_duck_model() -> void:
	# 1. Buoyant Body (Flat bottom, curved top)
	_body_mesh = MeshInstance3D.new()
	var body_sphere: SphereMesh = SphereMesh.new()
	body_sphere.radius = 0.24
	body_sphere.height = 0.48
	body_sphere.radial_segments = 12
	body_sphere.rings = 6
	_body_mesh.mesh = body_sphere
	_body_mesh.material_override = _body_mat
	_body_mesh.scale = Vector3(0.85, 0.65, 1.35)
	_body_mesh.position = Vector3(0.0, 0.12, 0.0)
	add_child(_body_mesh)

	# Tail Feathers (upturned Drake curl)
	var tail_mesh: PrismMesh = PrismMesh.new()
	tail_mesh.size = Vector3(0.18, 0.16, 0.25)
	var tail_mi: MeshInstance3D = MeshInstance3D.new()
	tail_mi.mesh = tail_mesh
	tail_mi.material_override = _body_mat
	tail_mi.position = Vector3(0.0, 0.18, -0.32)
	tail_mi.rotation.x = deg_to_rad(30.0)
	add_child(tail_mi)

	# 2. Articulated Head & Neck
	_head_root = Node3D.new()
	_head_root.name = "DuckHead"
	_head_root.position = Vector3(0.0, 0.18, 0.22)
	add_child(_head_root)

	# Emerald Head
	var head_sphere: SphereMesh = SphereMesh.new()
	head_sphere.radius = 0.11
	head_sphere.height = 0.22
	var head_mi: MeshInstance3D = MeshInstance3D.new()
	head_mi.mesh = head_sphere
	head_mi.material_override = _head_mat
	head_mi.position = Vector3(0.0, 0.12, 0.06)
	_head_root.add_child(head_mi)

	# Yellow Bill
	var bill_mesh: BoxMesh = BoxMesh.new()
	bill_mesh.size = Vector3(0.09, 0.04, 0.14)
	var bill_mi: MeshInstance3D = MeshInstance3D.new()
	bill_mi.mesh = bill_mesh
	bill_mi.material_override = _bill_mat
	bill_mi.position = Vector3(0.0, 0.10, 0.20)
	_head_root.add_child(bill_mi)

	# 3. Articulated Wings (Spreads & flaps during flight)
	_left_wing = Node3D.new()
	_left_wing.name = "LeftWing"
	_left_wing.position = Vector3(0.18, 0.16, 0.0)
	var wing_box: BoxMesh = BoxMesh.new()
	wing_box.size = Vector3(0.36, 0.03, 0.22)
	var lw_mi: MeshInstance3D = MeshInstance3D.new()
	lw_mi.mesh = wing_box
	lw_mi.material_override = _body_mat
	lw_mi.position = Vector3(0.18, 0.0, 0.0)
	_left_wing.add_child(lw_mi)
	_left_wing.rotation.z = deg_to_rad(-18.0) # Folded against body
	add_child(_left_wing)

	_right_wing = Node3D.new()
	_right_wing.name = "RightWing"
	_right_wing.position = Vector3(-0.18, 0.16, 0.0)
	var rw_mi: MeshInstance3D = MeshInstance3D.new()
	rw_mi.mesh = wing_box
	rw_mi.material_override = _body_mat
	rw_mi.position = Vector3(-0.18, 0.0, 0.0)
	_right_wing.add_child(rw_mi)
	_right_wing.rotation.z = deg_to_rad(18.0) # Folded against body
	add_child(_right_wing)

func _build_audio_emitter() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "DuckAudio"
	_audio_player.stream = _quack_wav
	_audio_player.unit_size = 3.5
	_audio_player.max_distance = 15.0
	_audio_player.volume_db = -6.0
	add_child(_audio_player)

func startle_flight() -> void:
	if not is_flying:
		is_flying = true
		_flight_timer = randf_range(5.0, 7.5)
		_is_dabbling = false
		if _audio_player and _quack_wav and is_inside_tree():
			_audio_player.pitch_scale = randf_range(1.25, 1.45) # Alarmed loud quack
			_audio_player.play()

func update_behavior(delta: float, player_pos: Vector3 = Vector3.ZERO, is_player_fast: bool = false) -> void:
	_anim_time += delta
	_dabble_timer -= delta

	# Check player startle
	if not is_flying and player_pos != Vector3.ZERO:
		var d_player: float = global_position.distance_to(player_pos)
		if (d_player < 5.0 and is_player_fast) or d_player < 3.2:
			startle_flight()

	# Handle STARTLED_FLIGHT
	if is_flying:
		_flight_timer -= delta
		# Rapid wing flapping
		var flap: float = sin(_anim_time * 28.0) * 0.75
		if _left_wing:
			_left_wing.rotation.z = flap
		if _right_wing:
			_right_wing.rotation.z = -flap

		# Flight altitude and wide circular loop
		var target_y: float = 3.8 + sin(_anim_time * 2.5) * 0.5
		position.y = lerpf(position.y, target_y, delta * 3.5)

		_swim_angle += ((swim_speed * 4.2) / (swim_radius * 1.8)) * delta
		var fly_x: float = swim_center.x + cos(_swim_angle) * (swim_radius * 1.8)
		var fly_z: float = swim_center.z + sin(_swim_angle) * (swim_radius * 1.8)

		var fly_vec: Vector3 = Vector3(fly_x - position.x, 0.0, fly_z - position.z)
		if fly_vec.length() > 0.01:
			var target_yaw: float = atan2(fly_vec.x, fly_vec.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, delta * 4.5)
			# Aerodynamic banking roll
			rotation.z = clampf(-flap * 0.2, -0.3, 0.3)
			position.x = fly_x
			position.z = fly_z

		if _flight_timer <= 0.0:
			is_flying = false
		return
	else:
		# Return folded wings
		if _left_wing:
			_left_wing.rotation.z = deg_to_rad(-18.0)
		if _right_wing:
			_right_wing.rotation.z = deg_to_rad(18.0)
		rotation.z = 0.0

	# Dabbling (bottom up feeding in water)
	if _is_dabbling:
		_dabble_time -= delta
		rotation.x = deg_to_rad(45.0) # Tail tilted up, head dipped
		if _head_root:
			_head_root.position.y = -0.05
		if _dabble_time <= 0.0:
			_is_dabbling = false
			rotation.x = 0.0
			_dabble_timer = randf_range(6.0, 14.0)
		return

	if _dabble_timer <= 0.0:
		_is_dabbling = true
		_dabble_time = randf_range(2.0, 4.0)
		return

	# Swimming in circular path
	_swim_angle += (swim_speed / swim_radius) * delta
	var target_x: float = swim_center.x + cos(_swim_angle) * swim_radius
	var target_z: float = swim_center.z + sin(_swim_angle) * swim_radius

	var move_vec: Vector3 = Vector3(target_x - position.x, 0.0, target_z - position.z)
	if move_vec.length() > 0.01:
		var target_yaw: float = atan2(move_vec.x, move_vec.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 3.0)
		position.x = target_x
		position.z = target_z

	# Water wave bobbing
	position.y = 0.05 + sin(_anim_time * 2.8) * 0.025
	# Head rhythmic forward bobbing while paddling
	if _head_root:
		_head_root.position.z = 0.22 + sin(_anim_time * 5.5) * 0.03
		_head_root.position.y = 0.18

	# Random occasional gentle quack
	if randf() < 0.003 and _audio_player:
		_audio_player.pitch_scale = randf_range(0.95, 1.08)
		_audio_player.play()

static func _generate_quack_wav(duration: float = 0.22, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		# Rapid nasal attack and exponential decay
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI) * exp(-4.0 * (t / duration))
		var freq: float = lerpf(520.0, 310.0, t / duration)
		# Nasal harmonic duck timbre (strong 2nd & 3rd harmonics)
		var s: float = sin(t * freq * TAU) * 0.5 + sin(t * freq * 2.0 * TAU) * 0.35 + sin(t * freq * 3.0 * TAU) * 0.15
		var val_16: int = int(clampf(s * env * 0.55, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
