class_name AerialRingTrialCourse
extends Node3D

## Living Planet Sandbox — Genshin-Style Aerial Ring Time-Trial Course (Block 58)
## "Thử Luyện Lướt Gió Thời Gian — Chân Trời Cuồng Phong"
## Features:
## 1. Ancient stone chronometer dial pedestal with hovering trial key on Scenic Promontory.
## 2. 5 Luminous aerial flight rings descending across Whispering Gorge toward Grand Emerald Lake.
## 3. Dynamic 35.0s countdown with sequential ring navigation, speed boost (+8.5 m/s), and ascending chimes.
## 4. Completing the course spawns and unlocks the Precious Aerial Chest (Rương Quý Giá Đỉnh Trời).
## 5. Procedural 16-bit PCM ring chimes & victory fanfare audio synthesizers.
## 6. Iris Xe optimized: shared materials, procedural meshes, 60 FPS budgeted.

signal trial_started()
signal ring_cleared(ring_index: int, total_cleared: int)
signal trial_completed(reward: Dictionary)
signal trial_failed()
signal chest_opened(reward: Dictionary)

const TRIAL_DURATION: float = 35.0
const RING_HIT_RADIUS: float = 3.6
const DIAL_INTERACT_RADIUS: float = 3.8

# Visual Components
var _dial_root: Node3D = null
var _dial_key: MeshInstance3D = null
var _dial_light: OmniLight3D = null
var _ring_nodes: Array[Node3D] = []
var _chest_root: Node3D = null
var _chest_lid: Node3D = null
var _chest_light: OmniLight3D = null
var _audio_player: AudioStreamPlayer3D = null

# Materials
static var _stone_pedestal_mat: StandardMaterial3D = null
static var _ring_cyan_mat: StandardMaterial3D = null
static var _ring_gold_mat: StandardMaterial3D = null
static var _ring_inactive_mat: StandardMaterial3D = null
static var _chest_wood_mat: StandardMaterial3D = null
static var _chest_gold_mat: StandardMaterial3D = null

# Audio Streams
static var _ring_chimes: Array[AudioStreamWAV] = []
static var _victory_wav: AudioStreamWAV = null

# State
var is_trial_active: bool = false
var time_remaining: float = 0.0
var current_target_ring: int = 0
var rings_cleared_count: int = 0
var is_trial_completed: bool = false
var is_chest_opened: bool = false

var _anim_time: float = 0.0

# 5 Aerial Ring Coordinates: Descending ridge to lake
var ring_coords: Array[Vector3] = [
	Vector3(-12.0, 9.5, 24.0),   # Ring 0: Launch bluff rim
	Vector3(-6.0, 11.2, 42.0),   # Ring 1: Over Whispering Gorge
	Vector3(6.0, 10.0, 60.0),    # Ring 2: Glade flyway
	Vector3(22.0, 8.5, 76.0),    # Ring 3: Lake basin entry
	Vector3(42.0, 6.2, 85.0)     # Ring 4: Lakeside pier finish
]

var chest_pos: Vector3 = Vector3(44.5, 3.8, 85.5)

func _init() -> void:
	name = "AerialRingTrialCourse"
	_init_materials()
	_init_audio()
	_build_dial_pedestal()
	_build_aerial_rings()
	_build_precious_chest()
	_build_audio_emitter()

func _ready() -> void:
	for i in range(_ring_nodes.size()):
		if i < ring_coords.size():
			_ring_nodes[i].global_position = ring_coords[i]
	if _chest_root:
		_chest_root.global_position = chest_pos

static func _init_materials() -> void:
	if _stone_pedestal_mat != null:
		return

	# Ancient Carved Stone Dial
	_stone_pedestal_mat = StandardMaterial3D.new()
	_stone_pedestal_mat.albedo_color = Color(0.28, 0.32, 0.36)
	_stone_pedestal_mat.roughness = 0.85

	# Active Cyan Flight Ring
	_ring_cyan_mat = StandardMaterial3D.new()
	_ring_cyan_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_cyan_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_cyan_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_cyan_mat.albedo_color = Color(0.25, 0.95, 0.85, 0.85)
	_ring_cyan_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Cleared Gold Flight Ring
	_ring_gold_mat = StandardMaterial3D.new()
	_ring_gold_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_gold_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_gold_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_gold_mat.albedo_color = Color(1.0, 0.88, 0.35, 0.90)
	_ring_gold_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Inactive / Dormant Ring
	_ring_inactive_mat = StandardMaterial3D.new()
	_ring_inactive_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_inactive_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_inactive_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_inactive_mat.albedo_color = Color(0.25, 0.65, 0.75, 0.25)
	_ring_inactive_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Precious Chest Materials
	_chest_wood_mat = StandardMaterial3D.new()
	_chest_wood_mat.albedo_color = Color(0.35, 0.22, 0.14)
	_chest_wood_mat.roughness = 0.75

	_chest_gold_mat = StandardMaterial3D.new()
	_chest_gold_mat.albedo_color = Color(0.95, 0.82, 0.32)
	_chest_gold_mat.metallic = 0.85
	_chest_gold_mat.roughness = 0.30
	_chest_gold_mat.emission_enabled = true
	_chest_gold_mat.emission = Color(0.95, 0.78, 0.25)
	_chest_gold_mat.emission_energy_multiplier = 1.2

static func _init_audio() -> void:
	if _victory_wav != null:
		return

	# 5 Ascending Ring Chimes (C5, E5, G5, B5, C6)
	var frequencies: Array[float] = [523.25, 659.25, 783.99, 987.77, 1046.50]
	for freq in frequencies:
		_ring_chimes.append(_generate_ring_chime_wav(freq))

	_victory_wav = _generate_trial_victory_wav()

func _build_dial_pedestal() -> void:
	_dial_root = Node3D.new()
	_dial_root.name = "TrialDialPedestal"
	_dial_root.position = Vector3(0.0, 0.0, 0.0)
	add_child(_dial_root)

	# Stepped Octagonal Plinth
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 1.15
	base_mesh.bottom_radius = 1.35
	base_mesh.height = 0.45
	base_mesh.radial_segments = 8
	base_mesh.material = _stone_pedestal_mat
	var base_inst = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.position = Vector3(0.0, 0.22, 0.0)
	_dial_root.add_child(base_inst)

	# Upper Pillar
	var pillar_mesh = CylinderMesh.new()
	pillar_mesh.top_radius = 0.75
	pillar_mesh.bottom_radius = 0.90
	pillar_mesh.height = 0.75
	pillar_mesh.radial_segments = 8
	pillar_mesh.material = _stone_pedestal_mat
	var pillar_inst = MeshInstance3D.new()
	pillar_inst.mesh = pillar_mesh
	pillar_inst.position = Vector3(0.0, 0.70, 0.0)
	_dial_root.add_child(pillar_inst)

	# Hovering Runic Dial Key
	var key_mesh = TorusMesh.new()
	key_mesh.inner_radius = 0.22
	key_mesh.outer_radius = 0.45
	key_mesh.material = _ring_cyan_mat
	_dial_key = MeshInstance3D.new()
	_dial_key.name = "DialKey"
	_dial_key.mesh = key_mesh
	_dial_key.position = Vector3(0.0, 1.45, 0.0)
	_dial_root.add_child(_dial_key)

	# Inner Diamond Core
	var core_mesh = PrismMesh.new()
	core_mesh.size = Vector3(0.24, 0.35, 0.24)
	core_mesh.material = _chest_gold_mat
	var core_inst = MeshInstance3D.new()
	core_inst.mesh = core_mesh
	core_inst.position = Vector3(0.0, 0.0, 0.0)
	_dial_key.add_child(core_inst)

	# Dial Radiance
	_dial_light = OmniLight3D.new()
	_dial_light.name = "DialLight"
	_dial_light.light_color = Color(0.35, 0.95, 0.85)
	_dial_light.light_energy = 1.6
	_dial_light.omni_range = 5.5
	_dial_key.add_child(_dial_light)

func _build_aerial_rings() -> void:
	for i in range(ring_coords.size()):
		var r_pos: Vector3 = ring_coords[i]
		var ring_node = Node3D.new()
		ring_node.name = "TrialRing_%d" % i
		ring_node.top_level = true
		ring_node.position = r_pos
		add_child(ring_node)

		# Outer Torus Ring
		var torus_mesh = TorusMesh.new()
		torus_mesh.inner_radius = 2.05
		torus_mesh.outer_radius = 2.35
		torus_mesh.material = _ring_inactive_mat
		var torus_inst = MeshInstance3D.new()
		torus_inst.name = "TorusMesh"
		torus_inst.mesh = torus_mesh
		ring_node.add_child(torus_inst)

		# Inner Wind Chevron Flanges
		for c_idx in range(4):
			var chev_mesh = PrismMesh.new()
			chev_mesh.size = Vector3(0.22, 0.65, 0.08)
			chev_mesh.material = _ring_cyan_mat
			var chev_inst = MeshInstance3D.new()
			chev_inst.name = "Chevron_%d" % c_idx
			chev_inst.mesh = chev_mesh
			var a: float = float(c_idx) * (TAU / 4.0)
			chev_inst.position = Vector3(cos(a) * 1.85, sin(a) * 1.85, 0.0)
			chev_inst.rotation.z = a - PI * 0.5
			ring_node.add_child(chev_inst)

		# Rings face flight travel direction (pointing toward next ring or lake)
		var next_pos: Vector3 = ring_coords[min(i + 1, ring_coords.size() - 1)] if i < ring_coords.size() - 1 else r_pos + Vector3(1.0, -0.1, 0.2)
		var fwd: Vector3 = (next_pos - r_pos).normalized()
		if fwd.length_squared() > 0.01:
			var yaw: float = atan2(fwd.x, fwd.z)
			var pitch: float = asin(-fwd.y)
			ring_node.rotation = Vector3(pitch, yaw, 0.0)

		# Hidden initially until trial starts
		ring_node.visible = false
		_ring_nodes.append(ring_node)

func _build_precious_chest() -> void:
	_chest_root = Node3D.new()
	_chest_root.name = "PreciousAerialChest"
	_chest_root.top_level = true
	_chest_root.position = chest_pos
	add_child(_chest_root)

	# Chest Base
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(1.4, 0.65, 0.95)
	base_mesh.material = _chest_wood_mat
	var base_inst = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.position = Vector3(0.0, 0.32, 0.0)
	_chest_root.add_child(base_inst)

	# Gold Straps & Corners
	var band_mesh = BoxMesh.new()
	band_mesh.size = Vector3(1.44, 0.68, 0.12)
	band_mesh.material = _chest_gold_mat
	for b_sign in [-1.0, 1.0]:
		var band_inst = MeshInstance3D.new()
		band_inst.mesh = band_mesh
		band_inst.position = Vector3(0.0, 0.32, b_sign * 0.32)
		_chest_root.add_child(band_inst)

	# Chest Lid (Pivotable)
	_chest_lid = Node3D.new()
	_chest_lid.name = "ChestLid"
	_chest_lid.position = Vector3(0.0, 0.65, -0.45)
	_chest_root.add_child(_chest_lid)

	var lid_mesh = CylinderMesh.new()
	lid_mesh.top_radius = 0.48
	lid_mesh.bottom_radius = 0.48
	lid_mesh.height = 1.4
	lid_mesh.radial_segments = 16
	lid_mesh.material = _chest_wood_mat
	var lid_inst = MeshInstance3D.new()
	lid_inst.mesh = lid_mesh
	lid_inst.rotation.z = deg_to_rad(90.0)
	lid_inst.position = Vector3(0.0, 0.0, 0.45)
	_chest_lid.add_child(lid_inst)

	# Gilded Trim on Lid
	var lid_trim_mesh = CylinderMesh.new()
	lid_trim_mesh.top_radius = 0.50
	lid_trim_mesh.bottom_radius = 0.50
	lid_trim_mesh.height = 0.14
	lid_trim_mesh.material = _chest_gold_mat
	for t_sign in [-1.0, 1.0]:
		var trim_inst = MeshInstance3D.new()
		trim_inst.mesh = lid_trim_mesh
		trim_inst.rotation.z = deg_to_rad(90.0)
		trim_inst.position = Vector3(t_sign * 0.45, 0.0, 0.45)
		_chest_lid.add_child(trim_inst)

	# Chest Aura Light
	_chest_light = OmniLight3D.new()
	_chest_light.name = "ChestLight"
	_chest_light.light_color = Color(1.0, 0.88, 0.45)
	_chest_light.light_energy = 1.8
	_chest_light.omni_range = 6.0
	_chest_light.position = Vector3(0.0, 0.5, 0.0)
	_chest_root.add_child(_chest_light)

	# Hidden until trial completed
	_chest_root.visible = false

func _build_audio_emitter() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "TrialAudio"
	_audio_player.unit_size = 15.0
	_audio_player.max_distance = 60.0
	_audio_player.volume_db = 2.0
	add_child(_audio_player)

func _process(delta: float) -> void:
	_anim_time += delta

	# Hovering Dial Key Bobbing & Rotation
	if _dial_key:
		_dial_key.rotation.y += delta * 1.4
		_dial_key.position.y = 1.45 + sin(_anim_time * 2.5) * 0.08

	# Dial Light Pulse
	if _dial_light:
		var pulse: float = 1.2 + sin(_anim_time * 3.0) * 0.4
		_dial_light.light_energy = pulse

	# Active Trial Countdown & Ring Animation
	if is_trial_active:
		time_remaining -= delta
		if time_remaining <= 0.0:
			_fail_trial()
			return

		# Pulse current target ring
		if current_target_ring < _ring_nodes.size():
			var cur_node: Node3D = _ring_nodes[current_target_ring]
			cur_node.rotation.z += delta * 1.8
			var torus = cur_node.get_node_or_null("TorusMesh") as MeshInstance3D
			if torus:
				var scale_pulse: float = 1.0 + sin(_anim_time * 6.0) * 0.08
				torus.scale = Vector3(scale_pulse, scale_pulse, scale_pulse)

	# Chest Light pulse if revealed
	if _chest_root and _chest_root.visible and not is_chest_opened:
		if _chest_light:
			_chest_light.light_energy = 1.5 + sin(_anim_time * 3.5) * 0.5

func is_player_near_dial(player_pos: Vector3) -> bool:
	var d_pos = _dial_root.global_position if (_dial_root and is_inside_tree()) else position
	return d_pos.distance_to(player_pos) <= DIAL_INTERACT_RADIUS

func is_player_near_chest(player_pos: Vector3) -> bool:
	if not _chest_root or not _chest_root.visible or is_chest_opened:
		return false
	var c_pos = _chest_root.global_position if is_inside_tree() else chest_pos
	return c_pos.distance_to(player_pos) <= 3.8

func start_trial() -> void:
	if is_trial_active:
		return

	is_trial_active = true
	time_remaining = TRIAL_DURATION
	current_target_ring = 0
	rings_cleared_count = 0
	is_trial_completed = false

	# Reveal and activate all rings
	for i in range(_ring_nodes.size()):
		var r_node: Node3D = _ring_nodes[i]
		r_node.visible = true
		_set_ring_material(i, _ring_cyan_mat if i == 0 else _ring_inactive_mat)

	# Change dial color to golden running state
	if _dial_key:
		_dial_key.material_override = _ring_gold_mat
	if _dial_light:
		_dial_light.light_color = Color(1.0, 0.85, 0.35)

	# Play start chime
	_play_audio(_ring_chimes[0])
	trial_started.emit()

func check_character_ring_passage(character_pos: Vector3) -> bool:
	if not is_trial_active:
		return false

	if current_target_ring >= ring_coords.size():
		return false

	var target_pos: Vector3 = ring_coords[current_target_ring]
	if character_pos.distance_to(target_pos) <= RING_HIT_RADIUS:
		_clear_current_ring()
		return true

	return false

func _clear_current_ring() -> void:
	var cleared_idx: int = current_target_ring
	rings_cleared_count += 1

	# Turn cleared ring gold
	_set_ring_material(cleared_idx, _ring_gold_mat)

	# Play ascending chime
	var chime_idx: int = clampi(cleared_idx, 0, _ring_chimes.size() - 1)
	_play_audio(_ring_chimes[chime_idx])

	ring_cleared.emit(cleared_idx, rings_cleared_count)

	current_target_ring += 1
	if current_target_ring < ring_coords.size():
		# Activate next ring
		_set_ring_material(current_target_ring, _ring_cyan_mat)
	else:
		# All 5 rings cleared!
		_complete_trial()

func _set_ring_material(index: int, mat: Material) -> void:
	if index < 0 or index >= _ring_nodes.size():
		return
	var r_node: Node3D = _ring_nodes[index]
	var torus = r_node.get_node_or_null("TorusMesh") as MeshInstance3D
	if torus:
		torus.material_override = mat

func _complete_trial() -> void:
	is_trial_active = false
	is_trial_completed = true

	# Play triumph fanfare
	_play_audio(_victory_wav)

	# Reveal Precious Aerial Chest
	if _chest_root:
		_chest_root.visible = true

	# Reset dial to idle gold
	if _dial_light:
		_dial_light.light_color = Color(1.0, 0.88, 0.40)

	var reward: Dictionary = {
		"exp": 280,
		"coins": 90,
		"item": "anemo_soaring_crest",
		"item_title": "Huy Hiệu Phong Thần Ngàn Đời",
		"desc": "Bảo vật lướt gió tinh xảo ban tặng gia tốc +20% khi bay qua các luồng gió đảo."
	}
	trial_completed.emit(reward)

func _fail_trial() -> void:
	is_trial_active = false
	current_target_ring = 0

	# Hide rings
	for r_node in _ring_nodes:
		r_node.visible = false

	# Reset dial key to cyan
	if _dial_key:
		_dial_key.material_override = _ring_cyan_mat
	if _dial_light:
		_dial_light.light_color = Color(0.35, 0.95, 0.85)

	trial_failed.emit()

func open_precious_chest() -> Dictionary:
	if is_chest_opened or not _chest_root or not _chest_root.visible:
		return {}

	is_chest_opened = true

	# Open lid
	if _chest_lid:
		_chest_lid.rotation.x = deg_to_rad(-65.0)

	# Hide aura light
	if _chest_light:
		_chest_light.light_energy = 0.4

	# Play victory sound
	_play_audio(_victory_wav)

	var reward: Dictionary = {
		"exp": 280,
		"coins": 90,
		"item": "anemo_soaring_crest",
		"item_title": "Huy Hiệu Phong Thần Ngàn Đời"
	}
	chest_opened.emit(reward)
	return reward

func _play_audio(stream: AudioStreamWAV) -> void:
	if _audio_player and stream and is_inside_tree():
		_audio_player.stream = stream
		_audio_player.play()

static func _generate_ring_chime_wav(freq: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.85
	var total_samples: int = int(sample_rate * duration)
	var byte_data = PackedByteArray()
	byte_data.resize(total_samples * 2)

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var fundamental = sin(TAU * freq * t)
		var overtone_1 = 0.35 * sin(TAU * (freq * 2.0) * t)
		var overtone_2 = 0.15 * sin(TAU * (freq * 3.5) * t)
		var env: float = exp(-4.5 * t)
		var wave: float = (fundamental + overtone_1 + overtone_2) * env * 0.7
		var sample_val: int = int(clampf(wave, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_val)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = byte_data
	return stream

static func _generate_trial_victory_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 1.6
	var total_samples: int = int(sample_rate * duration)
	var byte_data = PackedByteArray()
	byte_data.resize(total_samples * 2)

	# 4-note victory arpeggio: C5 (523Hz), E5 (659Hz), G5 (784Hz), C6 (1046Hz)
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.50]
	var note_dur: float = 0.32

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var n_idx: int = clampi(int(t / note_dur), 0, notes.size() - 1)
		var freq: float = notes[n_idx]
		var local_t: float = t - float(n_idx) * note_dur

		var fundamental = sin(TAU * freq * local_t)
		var harm_2 = 0.40 * sin(TAU * (freq * 2.0) * local_t)
		var harm_3 = 0.20 * sin(TAU * (freq * 3.0) * local_t)

		var env: float = 1.0
		if local_t < 0.04:
			env = local_t / 0.04
		else:
			env = exp(-3.2 * (local_t - 0.04))

		var wave: float = (fundamental + harm_2 + harm_3) * env * 0.72
		var sample_val: int = int(clampf(wave, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_val)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = byte_data
	return stream
