class_name ExplorationChestSystem
extends Node3D

## Living Planet Sandbox — Exploration Treasure Chests & Anemo Elemental Monuments (Block 53)
## Features:
## 1. 6 Hidden Scenic Exploration Chests across landmarks (Heart Island, Bridge Underpass, Windmill, Canyon, Cape, Summit)
## 2. Animated chest lid opening kinetics with golden glint particle bursts
## 3. Anemo Elemental Monument with spinning propeller puzzle solving
## 4. Procedural 16-bit PCM triumphant fanfare audio synthesizer
## 5. Persistent state tracking opened vs sealed chests and awarding coins, EXP, and Anemo Shards

signal chest_opened(chest_id: String, reward: Dictionary)
signal monument_activated(monument_id: String)

# Materials
var _wood_mat: StandardMaterial3D = null
var _brass_mat: StandardMaterial3D = null
var _stone_mat: StandardMaterial3D = null
var _anemo_glow_mat: StandardMaterial3D = null
var _gold_mat: StandardMaterial3D = null
static var _fanfare_wav: AudioStreamWAV = null

# Chest Nodes
var _chests: Dictionary = {} # id -> Dictionary { node, lid, particles, is_open, reward, light }
var _monument_root: Node3D = null
var _monument_propeller: Node3D = null
var _monument_active: bool = false
var _monument_spin_speed: float = 0.0
var _audio_player: AudioStreamPlayer3D = null

func _init() -> void:
	name = "ExplorationChestSystem"
	_init_materials()
	_build_audio_emitter()

func setup(terrain: IslandTerrain = null) -> void:
	_spawn_all_chests(terrain)
	_build_anemo_elemental_monument(terrain)

func _init_materials() -> void:
	_wood_mat = StandardMaterial3D.new()
	_wood_mat.albedo_color = Color(0.38, 0.24, 0.14) # Stained dark oak
	_wood_mat.roughness = 0.70

	_brass_mat = StandardMaterial3D.new()
	_brass_mat.albedo_color = Color(0.85, 0.68, 0.22) # Polished brass bands
	_brass_mat.metallic = 0.85
	_brass_mat.roughness = 0.35

	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.45, 0.45, 0.42)
	_stone_mat.roughness = 0.85

	_anemo_glow_mat = StandardMaterial3D.new()
	_anemo_glow_mat.albedo_color = Color(0.20, 0.90, 0.82)
	_anemo_glow_mat.emission_enabled = true
	_anemo_glow_mat.emission = Color(0.25, 0.95, 0.88)
	_anemo_glow_mat.emission_energy_multiplier = 3.0

	_gold_mat = StandardMaterial3D.new()
	_gold_mat.albedo_color = Color(1.0, 0.84, 0.0)
	_gold_mat.metallic = 0.92
	_gold_mat.roughness = 0.25

	if _fanfare_wav == null:
		_fanfare_wav = _generate_fanfare_wav()

func _build_audio_emitter() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "ChestAudio"
	_audio_player.stream = _fanfare_wav
	_audio_player.unit_size = 6.0
	_audio_player.max_distance = 25.0
	_audio_player.volume_db = -2.0
	add_child(_audio_player)

func _spawn_all_chests(terrain: IslandTerrain) -> void:
	var chest_defs: Array[Dictionary] = [
		{
			"id": "lake_island_chest",
			"name": "Rương Báu Đảo Thần Gió",
			"pos": Vector3(95.0, 3.8, 88.0),
			"type": "Exquisite",
			"coins": 150, "exp": 300, "item": "anemo_gem"
		},
		{
			"id": "arch_bridge_chest",
			"name": "Rương Cổ Cầu Vòm Đá",
			"pos": Vector3(95.0, 0.6, 61.0),
			"type": "Common",
			"coins": 60, "exp": 120, "item": "haven_coins"
		},
		{
			"id": "windmill_loft_chest",
			"name": "Rương Thợ Cối Xay Gió",
			"pos": Vector3(120.0, 7.8, -42.0),
			"type": "Common",
			"coins": 80, "exp": 150, "item": "flour_sack"
		},
		{
			"id": "windshear_ledge_chest",
			"name": "Rương Hẻm Vực Gió",
			"pos": Vector3(-35.0, 5.2, 142.0),
			"type": "Precious",
			"coins": 200, "exp": 400, "item": "windshear_feather"
		},
		{
			"id": "cape_bastion_chest",
			"name": "Rương Tháp Canh Bờ Biển",
			"pos": Vector3(-155.0, 27.2, 36.0),
			"type": "Common",
			"coins": 75, "exp": 140, "item": "sea_compass"
		},
		{
			"id": "skyspire_peak_chest",
			"name": "Rương Đỉnh Tuyết Skyspire",
			"pos": Vector3(-48.0, 52.8, -14.0),
			"type": "Precious",
			"coins": 250, "exp": 500, "item": "glacial_crown"
		}
	]

	for def in chest_defs:
		var chest_id: String = def["id"]
		var c_pos: Vector3 = def["pos"]
		if terrain:
			var gh: float = terrain.get_height_at(c_pos.x, c_pos.z)
			# Only clamp if chest is on ground (not placed on building elevation)
			if c_pos.y < gh:
				c_pos.y = gh

		var chest_node: Node3D = Node3D.new()
		chest_node.name = "Chest_" + chest_id
		chest_node.position = c_pos
		add_child(chest_node)

		# 1. Chest Body
		var body_mesh: BoxMesh = BoxMesh.new()
		body_mesh.size = Vector3(0.95, 0.48, 0.65)
		var b_mi: MeshInstance3D = MeshInstance3D.new()
		b_mi.mesh = body_mesh
		b_mi.material_override = _wood_mat
		b_mi.position = Vector3(0.0, 0.24, 0.0)
		chest_node.add_child(b_mi)

		# Brass trim corner bands
		var trim_mesh: BoxMesh = BoxMesh.new()
		trim_mesh.size = Vector3(0.98, 0.50, 0.68)
		var tr_mi: MeshInstance3D = MeshInstance3D.new()
		tr_mi.mesh = trim_mesh
		tr_mi.material_override = _brass_mat
		tr_mi.position = Vector3(0.0, 0.24, 0.0)
		tr_mi.scale = Vector3(1.02, 0.25, 1.02)
		chest_node.add_child(tr_mi)

		# 2. Hingeable Lid Root (pivots at back rim: Y=0.48, Z=-0.32)
		var lid_root: Node3D = Node3D.new()
		lid_root.name = "ChestLid"
		lid_root.position = Vector3(0.0, 0.48, -0.32)
		chest_node.add_child(lid_root)

		# Domed Lid Mesh
		var lid_mesh: CylinderMesh = CylinderMesh.new()
		lid_mesh.top_radius = 0.33
		lid_mesh.bottom_radius = 0.33
		lid_mesh.height = 0.95
		lid_mesh.radial_segments = 12
		var lid_mi: MeshInstance3D = MeshInstance3D.new()
		lid_mi.mesh = lid_mesh
		lid_mi.material_override = _wood_mat
		lid_mi.rotation.z = deg_to_rad(90.0)
		lid_mi.position = Vector3(0.0, 0.08, 0.32)
		lid_root.add_child(lid_mi)

		# Front Gold Latch / Lock
		var latch_mesh: BoxMesh = BoxMesh.new()
		latch_mesh.size = Vector3(0.18, 0.18, 0.08)
		var la_mi: MeshInstance3D = MeshInstance3D.new()
		la_mi.mesh = latch_mesh
		la_mi.material_override = _gold_mat
		la_mi.position = Vector3(0.0, -0.04, 0.65)
		lid_root.add_child(la_mi)

		# 3. Soft Ambient Aura Glow (unopened state)
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = Color(1.0, 0.85, 0.35) if def["type"] != "Precious" else Color(0.35, 0.95, 0.88)
		light.light_energy = 0.9
		light.omni_range = 3.5
		light.position = Vector3(0.0, 0.6, 0.0)
		chest_node.add_child(light)

		# 4. Golden Sparkle Burst Particles
		var parts: GPUParticles3D = GPUParticles3D.new()
		parts.name = "OpenSparkles"
		parts.emitting = false
		parts.one_shot = true
		parts.amount = 16
		parts.lifetime = 1.6
		parts.explosiveness = 0.8

		var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
		p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		p_mat.emission_box_extents = Vector3(0.4, 0.2, 0.3)
		p_mat.direction = Vector3(0.0, 1.0, 0.0)
		p_mat.spread = 35.0
		p_mat.initial_velocity_min = 1.2
		p_mat.initial_velocity_max = 2.5
		p_mat.scale_min = 0.10
		p_mat.scale_max = 0.25
		parts.process_material = p_mat

		var s_mesh: SphereMesh = SphereMesh.new()
		s_mesh.radius = 0.08
		s_mesh.height = 0.16
		var sm_mat: StandardMaterial3D = StandardMaterial3D.new()
		sm_mat.albedo_color = Color(1.0, 0.92, 0.35)
		sm_mat.emission_enabled = true
		sm_mat.emission = Color(1.0, 0.95, 0.45)
		sm_mat.emission_energy_multiplier = 3.0
		s_mesh.material = sm_mat
		parts.draw_pass_1 = s_mesh
		parts.position = Vector3(0.0, 0.5, 0.0)
		chest_node.add_child(parts)

		_chests[chest_id] = {
			"node": chest_node,
			"lid": lid_root,
			"particles": parts,
			"light": light,
			"is_open": false,
			"name": def["name"],
			"type": def["type"],
			"reward": {
				"coins": def["coins"],
				"exp": def["exp"],
				"item": def["item"]
			}
		}

# =============================================================================
# ANEMO ELEMENTAL MONUMENT (TRỤ NGUYÊN TỐ PHONG)
# =============================================================================
func _build_anemo_elemental_monument(terrain: IslandTerrain) -> void:
	_monument_root = Node3D.new()
	_monument_root.name = "AnemoElementalMonument"
	var mon_pos: Vector3 = Vector3(91.0, 0.0, 48.0)
	if terrain:
		mon_pos.y = maxf(terrain.get_height_at(mon_pos.x, mon_pos.z), 1.2)
	_monument_root.position = mon_pos
	add_child(_monument_root)

	# 1. Carved Stepped Stone Obelisk
	var obelisk_mesh: CylinderMesh = CylinderMesh.new()
	obelisk_mesh.top_radius = 0.45
	obelisk_mesh.bottom_radius = 0.75
	obelisk_mesh.height = 3.2
	obelisk_mesh.radial_segments = 6
	var ob_mi: MeshInstance3D = MeshInstance3D.new()
	ob_mi.mesh = obelisk_mesh
	ob_mi.material_override = _stone_mat
	ob_mi.position = Vector3(0.0, 1.6, 0.0)
	_monument_root.add_child(ob_mi)

	# 2. Spinning 4-Blade Anemo Pinwheel
	_monument_propeller = Node3D.new()
	_monument_propeller.name = "AnemoPropeller"
	_monument_propeller.position = Vector3(0.0, 3.1, 0.0)
	_monument_root.add_child(_monument_propeller)

	for i in range(4):
		var ang: float = float(i) * (PI * 0.5)
		var blade_mesh: BoxMesh = BoxMesh.new()
		blade_mesh.size = Vector3(0.08, 0.95, 0.25)
		var bl_mi: MeshInstance3D = MeshInstance3D.new()
		bl_mi.mesh = blade_mesh
		bl_mi.material_override = _anemo_glow_mat
		bl_mi.position = Vector3(sin(ang) * 0.48, cos(ang) * 0.48, 0.0)
		bl_mi.rotation.z = -ang
		_monument_propeller.add_child(bl_mi)

	# Luminous Anemo Light
	var m_light: OmniLight3D = OmniLight3D.new()
	m_light.name = "MonumentLight"
	m_light.light_color = Color(0.20, 0.95, 0.85)
	m_light.light_energy = 1.8
	m_light.omni_range = 7.0
	m_light.position = Vector3(0.0, 3.2, 0.0)
	_monument_root.add_child(m_light)

func strike_monument() -> void:
	_monument_spin_speed = 18.0
	_monument_active = true
	monument_activated.emit("anemo_bridge_monument")
	# Unlock nearby chest if closed
	if _chests.has("arch_bridge_chest") and not _chests["arch_bridge_chest"]["is_open"]:
		var chest_data = _chests["arch_bridge_chest"]
		if chest_data["light"]:
			chest_data["light"].light_energy = 2.5

func open_chest(chest_id: String) -> Dictionary:
	if not _chests.has(chest_id):
		return {}
	var c_data: Dictionary = _chests[chest_id]
	if c_data["is_open"]:
		return {}

	c_data["is_open"] = true
	var lid: Node3D = c_data["lid"] as Node3D
	if lid:
		# Smoothly hinge open lid
		lid.rotation.x = deg_to_rad(-85.0)

	var parts: GPUParticles3D = c_data["particles"] as GPUParticles3D
	if parts:
		parts.restart()
		parts.emitting = true

	var light: OmniLight3D = c_data["light"] as OmniLight3D
	if light:
		light.light_energy = 0.2 # Dim down after opening

	if _audio_player and _fanfare_wav:
		var c_node = c_data["node"] as Node3D
		if c_node and c_node.is_inside_tree():
			_audio_player.global_position = c_node.global_position
		if is_inside_tree():
			_audio_player.pitch_scale = randf_range(0.98, 1.02)
			_audio_player.play()

	var reward: Dictionary = c_data["reward"]
	chest_opened.emit(chest_id, reward)
	return reward

func get_nearest_unopened_chest(pos: Vector3, max_dist: float = 3.5) -> String:
	var closest_id: String = ""
	var closest_dist: float = max_dist
	for cid in _chests:
		var c_data = _chests[cid]
		if c_data["is_open"]:
			continue
		var c_node: Node3D = c_data["node"]
		var d: float = c_node.global_position.distance_to(pos) if c_node.is_inside_tree() else c_node.position.distance_to(pos)
		if d < closest_dist:
			closest_dist = d
			closest_id = cid
	return closest_id

func get_chest_count() -> int:
	return _chests.size()

func get_unopened_count() -> int:
	var count: int = 0
	for cid in _chests:
		if not _chests[cid]["is_open"]:
			count += 1
	return count

func _process(delta: float) -> void:
	if _monument_propeller:
		if _monument_spin_speed > 0.05:
			_monument_propeller.rotation.y += _monument_spin_speed * delta
			_monument_spin_speed = lerpf(_monument_spin_speed, 0.0, delta * 1.5)
		else:
			# Slow idle breeze rotation
			_monument_propeller.rotation.y += delta * 0.4

static func _generate_fanfare_wav(duration: float = 1.25, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	# Major triad arpeggio + triumphant sustained chord (C5 -> E5 -> G5 -> C6)
	var notes = [
		{"t_start": 0.00, "t_end": 0.20, "freq": 523.25},  # C5
		{"t_start": 0.18, "t_end": 0.38, "freq": 659.25},  # E5
		{"t_start": 0.36, "t_end": 0.56, "freq": 783.99},  # G5
		{"t_start": 0.54, "t_end": 1.25, "freq": 1046.50}  # C6 (High sustained bell)
	]

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var sample: float = 0.0

		for note in notes:
			if t >= note["t_start"] and t <= note["t_end"]:
				var dt: float = t - note["t_start"]
				var dur: float = note["t_end"] - note["t_start"]
				var env: float = sin(clampf(dt / dur, 0.0, 1.0) * PI) * exp(-1.5 * (dt / dur))
				var s: float = sin(dt * note["freq"] * TAU) * 0.65 + sin(dt * note["freq"] * 2.0 * TAU) * 0.25
				sample += s * env

		var val_16: int = int(clampf(sample * 0.65, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
