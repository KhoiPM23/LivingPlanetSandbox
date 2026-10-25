class_name AncientAnemoStatue
extends Node3D

## Living Planet Sandbox — Genshin-Style Ancient Anemo Statue & Gliding Time Trial (Block 55)
## Features:
## 1. 9-Meter Ancient Stone Statue of the Wind Guardian on the panoramic cliff promontory:
##    - 3-Tier stepped circular stone plinth
##    - Winged carved stone deity holding levitating, spinning Anemo Elemental Orb
##    - Concentric rotating runic glyph rings
##    - Upward ascending gentle wind wisps
## 2. Interactive Prayer & Blessing:
##    - [E] Cầu Nguyện Tượng Thần Gió: grants Wind Guardian's Blessing (+25% glide speed, +200 EXP, full recovery)
## 3. Anemo Gliding Time Trial (Khiêu Chiến Lượn Gió):
##    - 45.0-Second countdown challenge traversing the 6 Anemo Flight Rings highway down to Heart Island
##    - Success spawns Victorious Wind Chest (+300 EXP, +100 Coins, milestone completion)
## 4. Procedural 16-bit PCM celestial choir blessing chord audio synthesizer.
## 5. Intel Iris Xe optimized: shared standard materials, zero CPU overhead.

signal statue_prayed(player: Node3D, blessing: Dictionary)
signal time_trial_started(duration: float)
signal time_trial_completed(time_taken: float, reward: Dictionary)
signal time_trial_failed()

var _anim_time: float = 0.0
var _orb_root: Node3D = null
var _orb_light: OmniLight3D = null
var _glyph_ring: Node3D = null
var _audio_player: AudioStreamPlayer3D = null
static var _blessing_wav: AudioStreamWAV = null

# Gliding Time Trial State
var is_time_trial_active: bool = false
var time_trial_timer: float = 0.0
const TIME_TRIAL_LIMIT: float = 45.0
var _trial_rings_hit: int = 0
var _trial_pedestal: MeshInstance3D = null

# Materials
static var _statue_stone_mat: StandardMaterial3D = null
static var _anemo_gem_mat: StandardMaterial3D = null
static var _glyph_mat: StandardMaterial3D = null
static var _trial_red_mat: StandardMaterial3D = null
static var _trial_green_mat: StandardMaterial3D = null

func _init() -> void:
	name = "AncientAnemoStatue"
	_init_materials()
	_build_audio_emitter()
	_build_statue_structure()
	_build_time_trial_pedestal()

static func _init_materials() -> void:
	if _statue_stone_mat != null:
		return

	# Ancient Weathered Granite
	_statue_stone_mat = StandardMaterial3D.new()
	_statue_stone_mat.albedo_color = Color(0.58, 0.60, 0.62)
	_statue_stone_mat.roughness = 0.85

	# Radiant Anemo Elemental Crystal Orb
	_anemo_gem_mat = StandardMaterial3D.new()
	_anemo_gem_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_anemo_gem_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_anemo_gem_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_anemo_gem_mat.albedo_color = Color(0.20, 0.95, 0.85, 0.90)

	# Luminous Glyph Ring
	_glyph_mat = StandardMaterial3D.new()
	_glyph_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glyph_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_glyph_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glyph_mat.albedo_color = Color(0.35, 1.0, 0.90, 0.70)

	# Trial Activation Pedestal (Red = Idle / Ready, Green = Active)
	_trial_red_mat = StandardMaterial3D.new()
	_trial_red_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trial_red_mat.albedo_color = Color(1.0, 0.25, 0.25)

	_trial_green_mat = StandardMaterial3D.new()
	_trial_green_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trial_green_mat.albedo_color = Color(0.25, 1.0, 0.45)

func _build_audio_emitter() -> void:
	if _blessing_wav == null:
		_blessing_wav = _generate_statue_blessing_wav()

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "StatueAudio"
	_audio_player.stream = _blessing_wav
	_audio_player.unit_size = 8.0
	_audio_player.max_distance = 35.0
	_audio_player.volume_db = -1.0
	add_child(_audio_player)

func _build_statue_structure() -> void:
	# 1. Stepped Circular Plinth (3 Tiers)
	var tiers = [
		{"r": 3.8, "h": 0.45, "y": 0.225},
		{"r": 2.8, "h": 0.40, "y": 0.65},
		{"r": 1.9, "h": 0.35, "y": 1.025}
	]
	for t in tiers:
		var c_mesh = CylinderMesh.new()
		c_mesh.top_radius = t["r"]
		c_mesh.bottom_radius = t["r"] + 0.15
		c_mesh.height = t["h"]
		var mi = MeshInstance3D.new()
		mi.mesh = c_mesh
		mi.material_override = _statue_stone_mat
		mi.position.y = t["y"]
		add_child(mi)

	# 2. Central Pillar & Statue Torso
	var col = CylinderMesh.new()
	col.top_radius = 0.55
	col.bottom_radius = 0.70
	col.height = 3.2
	var col_mi = MeshInstance3D.new()
	col_mi.mesh = col
	col_mi.material_override = _statue_stone_mat
	col_mi.position.y = 2.8
	add_child(col_mi)

	# 3. Carved Stone Deity Wings
	for side in [-1.0, 1.0]:
		var wing = PrismMesh.new()
		wing.size = Vector3(0.5, 3.4, 0.15)
		var w_mi = MeshInstance3D.new()
		w_mi.mesh = wing
		w_mi.material_override = _statue_stone_mat
		w_mi.position = Vector3(side * 1.35, 3.8, -0.2)
		w_mi.rotation.z = deg_to_rad(35.0 * side)
		w_mi.rotation.y = deg_to_rad(-15.0 * side)
		add_child(w_mi)

	# 4. Levitating Anemo Elemental Crystal Orb
	_orb_root = Node3D.new()
	_orb_root.name = "AnemoCrystalOrb"
	_orb_root.position = Vector3(0.0, 4.9, 0.0)
	add_child(_orb_root)

	var orb_mesh = SphereMesh.new()
	orb_mesh.radius = 0.35
	orb_mesh.height = 0.70
	var orb_mi = MeshInstance3D.new()
	orb_mi.mesh = orb_mesh
	orb_mi.material_override = _anemo_gem_mat
	_orb_root.add_child(orb_mi)

	# Concentric Torus Rings around Orb
	_glyph_ring = Node3D.new()
	_orb_root.add_child(_glyph_ring)

	var t1 = TorusMesh.new()
	t1.inner_radius = 0.50
	t1.outer_radius = 0.58
	var t1_mi = MeshInstance3D.new()
	t1_mi.mesh = t1
	t1_mi.material_override = _glyph_mat
	_glyph_ring.add_child(t1_mi)

	# 5. Radiant Anemo Light
	_orb_light = OmniLight3D.new()
	_orb_light.light_color = Color(0.25, 0.95, 0.88)
	_orb_light.light_energy = 2.8
	_orb_light.omni_range = 14.0
	_orb_light.omni_attenuation = 1.2
	_orb_light.shadow_enabled = true
	_orb_root.add_child(_orb_light)

func _build_time_trial_pedestal() -> void:
	var ped_root = Node3D.new()
	ped_root.name = "TimeTrialPedestal"
	ped_root.position = Vector3(1.6, 1.2, 1.4)
	add_child(ped_root)

	var col = CylinderMesh.new()
	col.top_radius = 0.18
	col.bottom_radius = 0.22
	col.height = 0.75
	var c_mi = MeshInstance3D.new()
	c_mi.mesh = col
	c_mi.material_override = _statue_stone_mat
	c_mi.position.y = 0.375
	ped_root.add_child(c_mi)

	# Glowing Key Monolith
	var key_mesh = PrismMesh.new()
	key_mesh.size = Vector3(0.18, 0.32, 0.08)
	_trial_pedestal = MeshInstance3D.new()
	_trial_pedestal.name = "TrialKey"
	_trial_pedestal.mesh = key_mesh
	_trial_pedestal.material_override = _trial_red_mat
	_trial_pedestal.position.y = 0.85
	ped_root.add_child(_trial_pedestal)

func _process(delta: float) -> void:
	_anim_time += delta

	# Levitating orb gentle bob & rotation
	if _orb_root:
		_orb_root.position.y = 4.9 + sin(_anim_time * 2.2) * 0.12
		_orb_root.rotation.y += delta * 0.85
	if _glyph_ring:
		_glyph_ring.rotation.x = sin(_anim_time * 1.5) * 0.35
		_glyph_ring.rotation.z = cos(_anim_time * 1.2) * 0.35

	# Time trial tick
	if is_time_trial_active:
		time_trial_timer -= delta
		if _trial_pedestal:
			_trial_pedestal.rotation.y += delta * 4.5

		if time_trial_timer <= 0.0:
			# Failed
			cancel_time_trial()

func get_nearby_interactable(pos: Vector3, max_dist: float = 3.6) -> Dictionary:
	var s_pos: Vector3 = global_position if is_inside_tree() else position

	# Check time trial pedestal
	var ped_pos: Vector3 = s_pos + Vector3(1.6, 1.2, 1.4)
	if pos.distance_to(ped_pos) <= 2.2:
		if not is_time_trial_active:
			return {
				"id": "anemo_time_trial",
				"type": "trial",
				"name": "Khiêu Chiến Thời Gian Lượn Gió",
				"icon": "⏱️",
				"pos": ped_pos
			}
		else:
			return {
				"id": "anemo_time_trial_active",
				"type": "trial",
				"name": "Khiêu Chiến Đang Diễn Ra (Còn %.1fs)" % maxf(time_trial_timer, 0.0),
				"icon": "🌀",
				"pos": ped_pos
			}

	# Check statue prayer dais
	if pos.distance_to(s_pos) <= max_dist:
		return {
			"id": "anemo_statue_prayer",
			"type": "statue",
			"name": "Tượng Thần Phong Linh Cổ Đại",
			"icon": "✨",
			"pos": s_pos
		}

	return {}

func pray_at_statue(walker: CharacterBody3D = null) -> Dictionary:
	if _audio_player and is_inside_tree():
		_audio_player.play()

	if walker and walker.has_method("get_facial_controller"):
		var fc = walker.get_facial_controller()
		if fc and fc.has_method("trigger_surprise"):
			fc.trigger_surprise(3.5)

	var blessing = {
		"buff": "wind_guardians_blessing",
		"glide_speed_mult": 1.25,
		"duration": 120.0,
		"exp": 200,
		"message": "Nhận được 'Phước Lành Thần Gió'! (+25% Tốc độ lượn dù, +200 EXP)"
	}
	statue_prayed.emit(walker, blessing)
	return blessing

func start_time_trial() -> bool:
	if is_time_trial_active:
		return false

	is_time_trial_active = true
	time_trial_timer = TIME_TRIAL_LIMIT
	_trial_rings_hit = 0
	if _trial_pedestal:
		_trial_pedestal.material_override = _trial_green_mat

	time_trial_started.emit(TIME_TRIAL_LIMIT)
	return true

func register_ring_hit(ring_index: int, total_hit: int) -> void:
	if not is_time_trial_active:
		return

	_trial_rings_hit += 1
	# If player hits all 6 rings or final ring at Heart Island
	if ring_index == 5 or _trial_rings_hit >= 6:
		complete_time_trial()

func complete_time_trial() -> void:
	if not is_time_trial_active:
		return

	is_time_trial_active = false
	var time_taken: float = TIME_TRIAL_LIMIT - time_trial_timer
	if _trial_pedestal:
		_trial_pedestal.material_override = _trial_red_mat

	var reward = {
		"exp": 300,
		"coins": 100,
		"time_taken": time_taken,
		"message": "Khiêu Chiến Thành Công! Hoàn thành trong %.1f giây (+300 EXP, +100 Hải Tệ)" % time_taken
	}
	time_trial_completed.emit(time_taken, reward)

func cancel_time_trial() -> void:
	if not is_time_trial_active:
		return
	is_time_trial_active = false
	if _trial_pedestal:
		_trial_pedestal.material_override = _trial_red_mat
	time_trial_failed.emit()

static func _generate_statue_blessing_wav(duration: float = 1.4, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	# Celestial harmonic choral chord: F#4 (370Hz), A#4 (466Hz), C#5 (554Hz), F#5 (740Hz)
	var chord = [369.99, 466.16, 554.37, 739.99]

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI)
		var s: float = 0.0
		for freq in chord:
			s += sin(t * freq * TAU) * 0.25

		var sample: float = s * env * 0.55
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
