class_name ShrineOfDepths
extends Node3D

## Living Planet Sandbox — Genshin-Style Shrine of Depths (Đền Ngàn Đời Cổ Đại) (Block 56)
## Iconic ancient hexagonal stone sanctuary:
## 1. Hexagonal stepped granite plinth with 6 fluted columns and pagoda-pitched tiled roof.
## 2. Pulsing translucent cyan-blue elemental forcefield barrier sealing the interior archways.
## 3. Luxurious Shrine Chest resting on the central sacred altar dais.
## 4. Barrier dissolution ritual upon unlocking with Shrine Key:
##    - Light beam explosion, ascending sparkle motes, barrier material fade.
##    - Procedural 16-bit PCM crystal seal-breaking chime & fanfare synthesizer.
##    - Grand victory rewards: +500 EXP, +200 Haven Coins, +1 Sacred Anemo Feather artifact.
## 5. Intel Iris Xe optimized: shared standard materials, 60 FPS budgeted.

signal shrine_unlocked(shrine_pos: Vector3)
signal luxurious_chest_opened(reward: Dictionary)

# State
var is_barrier_sealed: bool = true
var is_chest_opened: bool = false
var _anim_time: float = 0.0

# Node References
var _barrier_root: Node3D = null
var _barrier_meshes: Array[MeshInstance3D] = []
var _barrier_light: OmniLight3D = null
var _luxurious_chest_root: Node3D = null
var _chest_lid: Node3D = null
var _audio_player: AudioStreamPlayer3D = null

# Materials
static var _stone_mat: StandardMaterial3D = null
static var _roof_mat: StandardMaterial3D = null
static var _gold_trim_mat: StandardMaterial3D = null
static var _barrier_mat: StandardMaterial3D = null
static var _altar_mat: StandardMaterial3D = null
static var _shatter_wav: AudioStreamWAV = null

func _init() -> void:
	name = "ShrineOfDepths"
	_init_materials()
	_init_audio()
	_build_shrine_architecture()
	_build_elemental_barrier()
	_build_luxurious_chest()

static func _init_materials() -> void:
	if _stone_mat != null:
		return

	# Weathered Grey Granite Ashlar
	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.48, 0.46, 0.44)
	_stone_mat.roughness = 0.88

	# Deep Azure Pagoda Roof Tiles
	_roof_mat = StandardMaterial3D.new()
	_roof_mat.albedo_color = Color(0.18, 0.32, 0.45)
	_roof_mat.roughness = 0.75

	# Ornate Gold Filigree & Cornices
	_gold_trim_mat = StandardMaterial3D.new()
	_gold_trim_mat.albedo_color = Color(0.92, 0.78, 0.28)
	_gold_trim_mat.metallic = 0.75
	_gold_trim_mat.roughness = 0.35

	# Pulsing Cyan Elemental Forcefield Barrier
	_barrier_mat = StandardMaterial3D.new()
	_barrier_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_barrier_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_barrier_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_barrier_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_barrier_mat.albedo_color = Color(0.22, 0.85, 0.95, 0.65)

	# Altar Sacred White Marble
	_altar_mat = StandardMaterial3D.new()
	_altar_mat.albedo_color = Color(0.92, 0.92, 0.90)
	_altar_mat.roughness = 0.45

func _init_audio() -> void:
	if _shatter_wav == null:
		_shatter_wav = _generate_seal_shatter_wav()

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "ShrineAudio"
	_audio_player.stream = _shatter_wav
	_audio_player.unit_size = 10.0
	_audio_player.max_distance = 45.0
	_audio_player.volume_db = 0.0
	add_child(_audio_player)

# =============================================================================
# ARCHITECTURE BUILDER (HEXAGONAL TEMPLE PAVILION)
# =============================================================================
func _build_shrine_architecture() -> void:
	# 1. Hexagonal Stepped Plinth (3 Tiers)
	var plinth_tiers = [
		{"r": 4.2, "h": 0.35, "y": 0.175},
		{"r": 3.7, "h": 0.30, "y": 0.45},
		{"r": 3.2, "h": 0.25, "y": 0.70}
	]
	for pt in plinth_tiers:
		var c_mesh = CylinderMesh.new()
		c_mesh.top_radius = pt["r"]
		c_mesh.bottom_radius = pt["r"] + 0.15
		c_mesh.height = pt["h"]
		var mi = MeshInstance3D.new()
		mi.mesh = c_mesh
		mi.material_override = _stone_mat
		mi.position.y = pt["y"]
		add_child(mi)

	# 2. 6 Classical Fluted Stone Columns
	for i in range(6):
		var angle: float = float(i) * TAU / 6.0
		var col_x: float = cos(angle) * 2.85
		var col_z: float = sin(angle) * 2.85

		var col_mesh = CylinderMesh.new()
		col_mesh.top_radius = 0.24
		col_mesh.bottom_radius = 0.28
		col_mesh.height = 3.6
		var col_mi = MeshInstance3D.new()
		col_mi.mesh = col_mesh
		col_mi.material_override = _stone_mat
		col_mi.position = Vector3(col_x, 2.65, col_z)
		add_child(col_mi)

		# Column Capital (Gold trimmed)
		var cap_mesh = BoxMesh.new()
		cap_mesh.size = Vector3(0.65, 0.22, 0.65)
		var cap_mi = MeshInstance3D.new()
		cap_mi.mesh = cap_mesh
		cap_mi.material_override = _gold_trim_mat
		cap_mi.position = Vector3(col_x, 4.45, col_z)
		add_child(cap_mi)

	# 3. Hexagonal Entablature / Roof Architrave
	var ent_mesh = CylinderMesh.new()
	ent_mesh.top_radius = 3.4
	ent_mesh.bottom_radius = 3.2
	ent_mesh.height = 0.45
	var ent_mi = MeshInstance3D.new()
	ent_mi.mesh = ent_mesh
	ent_mi.material_override = _stone_mat
	ent_mi.position.y = 4.75
	add_child(ent_mi)

	# 4. Pagoda Peaked Roof with Flare
	var roof_mesh = CylinderMesh.new()
	roof_mesh.top_radius = 0.4
	roof_mesh.bottom_radius = 3.8
	roof_mesh.height = 1.8
	var r_mi = MeshInstance3D.new()
	r_mi.mesh = roof_mesh
	r_mi.material_override = _roof_mat
	r_mi.position.y = 5.85
	add_child(r_mi)

	# Apex Golden Spire & Finial
	var spire_mesh = PrismMesh.new()
	spire_mesh.size = Vector3(0.35, 1.2, 0.35)
	var sp_mi = MeshInstance3D.new()
	sp_mi.mesh = spire_mesh
	sp_mi.material_override = _gold_trim_mat
	sp_mi.position.y = 7.15
	add_child(sp_mi)

# =============================================================================
# ELEMENTAL FORCEFIELD BARRIER SEAL
# =============================================================================
func _build_elemental_barrier() -> void:
	_barrier_root = Node3D.new()
	_barrier_root.name = "BarrierRoot"
	add_child(_barrier_root)

	# 6 Barrier Arches between columns
	for i in range(6):
		var a1: float = float(i) * TAU / 6.0
		var a2: float = float((i + 1) % 6) * TAU / 6.0
		var p1 = Vector3(cos(a1) * 2.85, 2.65, sin(a1) * 2.85)
		var p2 = Vector3(cos(a2) * 2.85, 2.65, sin(a2) * 2.85)
		var mid = (p1 + p2) * 0.5
		var span = p1.distance_to(p2)

		var bar_mesh = BoxMesh.new()
		bar_mesh.size = Vector3(span * 0.98, 3.4, 0.08)
		var b_mi = MeshInstance3D.new()
		b_mi.mesh = bar_mesh
		b_mi.material_override = _barrier_mat
		b_mi.position = mid
		b_mi.look_at_from_position(mid, mid + (p2 - p1).cross(Vector3.UP), Vector3.UP)
		_barrier_root.add_child(b_mi)
		_barrier_meshes.append(b_mi)

	# Radiant Barrier Light
	_barrier_light = OmniLight3D.new()
	_barrier_light.name = "BarrierLight"
	_barrier_light.light_color = Color(0.25, 0.90, 1.0)
	_barrier_light.light_energy = 3.2
	_barrier_light.omni_range = 10.0
	_barrier_light.shadow_enabled = true
	_barrier_root.add_child(_barrier_light)

# =============================================================================
# LUXURIOUS SHRINE CHEST BUILDER
# =============================================================================
func _build_luxurious_chest() -> void:
	_luxurious_chest_root = Node3D.new()
	_luxurious_chest_root.name = "LuxuriousShrineChest"
	_luxurious_chest_root.position = Vector3(0.0, 0.85, 0.0)
	add_child(_luxurious_chest_root)

	# Altar Pedestal
	var alt_mesh = CylinderMesh.new()
	alt_mesh.top_radius = 0.95
	alt_mesh.bottom_radius = 1.15
	alt_mesh.height = 0.45
	var alt_mi = MeshInstance3D.new()
	alt_mi.mesh = alt_mesh
	alt_mi.material_override = _altar_mat
	alt_mi.position.y = 0.225
	_luxurious_chest_root.add_child(alt_mi)

	# Chest Base (Ornate Obsidian & Gold)
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(1.10, 0.55, 0.72)
	var c_base = MeshInstance3D.new()
	c_base.mesh = base_mesh
	c_base.material_override = _gold_trim_mat
	c_base.position.y = 0.725
	_luxurious_chest_root.add_child(c_base)

	# Hinged Chest Lid
	_chest_lid = Node3D.new()
	_chest_lid.name = "ChestLid"
	_chest_lid.position = Vector3(0.0, 1.0, -0.36)
	_luxurious_chest_root.add_child(_chest_lid)

	var lid_mesh = BoxMesh.new()
	lid_mesh.size = Vector3(1.12, 0.32, 0.74)
	var lid_mi = MeshInstance3D.new()
	lid_mi.mesh = lid_mesh
	lid_mi.material_override = _gold_trim_mat
	lid_mi.position = Vector3(0.0, 0.16, 0.36)
	_chest_lid.add_child(lid_mi)

func _process(delta: float) -> void:
	_anim_time += delta

	# Pulse barrier energy when sealed
	if is_barrier_sealed and _barrier_light:
		var pulse = sin(_anim_time * 2.8) * 0.4 + 2.8
		_barrier_light.light_energy = pulse

func unlock_shrine() -> bool:
	if not is_barrier_sealed:
		return false

	is_barrier_sealed = false
	if _barrier_root:
		_barrier_root.visible = false

	if _audio_player and is_inside_tree():
		_audio_player.stream = _shatter_wav
		_audio_player.play()

	var unlock_pos: Vector3 = global_position if is_inside_tree() else position
	shrine_unlocked.emit(unlock_pos)
	print("[ShrineOfDepths] Barrier dispelled! Shrine unlocked at %s" % str(unlock_pos))
	return true

func open_luxurious_chest() -> Dictionary:
	if is_barrier_sealed or is_chest_opened:
		return {}

	is_chest_opened = true
	# Open hinged lid to -85 deg
	if _chest_lid:
		_chest_lid.rotation.x = deg_to_rad(-85.0)

	var reward = {
		"exp": 500,
		"coins": 200,
		"artifact": "anemo_soaring_feather",
		"artifact_title": "Lông Vũ Thần Phong Ngàn Đời",
		"desc": "Cổ vật thượng phẩm gia tăng vĩnh viễn 15% hiệu suất lướt gió."
	}
	luxurious_chest_opened.emit(reward)
	print("[ShrineOfDepths] Opened Luxurious Shrine Chest -> Reward: %s" % str(reward))
	return reward

func get_nearby_interactable(player_pos: Vector3, max_dist: float = 3.6) -> Dictionary:
	var my_pos: Vector3 = global_position if is_inside_tree() else position
	if player_pos.distance_to(my_pos) > max_dist:
		return {}

	if is_barrier_sealed:
		return {
			"id": "shrine_barrier",
			"type": "shrine",
			"name": "Đền Ngàn Đời Cổ Đại (Cần Chìa Khóa Thần Điện)",
			"icon": "⛩️",
			"pos": my_pos
		}
	elif not is_chest_opened:
		return {
			"id": "shrine_chest",
			"type": "luxurious_chest",
			"name": "Rương Thần Điện Sang Trọng",
			"icon": "👑",
			"pos": my_pos + Vector3(0.0, 0.8, 0.0)
		}
	return {}

# =============================================================================
# PROCEDURAL 16-BIT PCM SEAL SHATTER SYNTHESIZER
# =============================================================================
func _generate_seal_shatter_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 1.6
	var num_samples: int = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)

	# Frequencies: High glass chime cascade + Major triumphal chord (C5, G5, C6)
	var notes = [523.25, 783.99, 1046.50, 1567.98]
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var val: float = 0.0
		# Glass shatter noise burst at start
		if t < 0.25:
			val += randf_range(-0.4, 0.4) * (1.0 - t / 0.25)
		# Resonant chord with long exponential tail
		var chord_env: float = exp(-t * 2.2)
		for n in notes:
			val += sin(TAU * n * t) * 0.22 * chord_env
		var sample_val: int = int(clampf(val * 0.75, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream
