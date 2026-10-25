class_name HydroLakeSanctuaryPuzzle
extends Node3D

## Living Planet Sandbox — Genshin-Style Hydro Lake Sanctuary & Water Spout (Block 59)
## "Đài Nước Thủy Thần & Cột Nước Cuồng Triều Hồ Ngọc Bích"
## Features:
## 1. 3 Submerged glowing Runic Hydro Seals beneath Grand Emerald Lake surface.
## 2. Interactive [E] or melee combat activation for each hydro seal.
## 3. Water Spout Eruption: 28m vertical swirling hydro geyser with animated rising torus rings.
## 4. Vertical Catapult: launches character 26.5 m/s skyward onto hovering floral islet.
## 5. Floating Floral Islet with sacred flora and Luxurious Island Chest (Rương Thủy Thần Siêu Cấp).
## 6. Procedural 16-bit PCM water chime & geyser eruption audio synthesizers.

signal seal_activated(seal_idx: int, total_active: int)
signal spout_erupted(spout_pos: Vector3)
signal player_launched(launch_velocity: Vector3)
signal luxurious_chest_opened(reward: Dictionary)

const SPOUT_CENTER: Vector3 = Vector3(75.0, 0.2, 70.0)
const ISLET_CENTER: Vector3 = Vector3(75.0, 24.5, 70.0)
const LAUNCH_IMPULSE: float = 26.5

# Seal Positions (Distributed on Grand Emerald Lake bed beneath clear turquoise water)
var seal_positions: Array[Vector3] = [
	Vector3(70.0, 0.1, 65.0),
	Vector3(80.0, 0.1, 65.0),
	Vector3(75.0, 0.1, 76.0)
]

var seal_active: Array[bool] = [false, false, false]
var is_spout_active: bool = false
var is_chest_opened: bool = false
var _anim_time: float = 0.0

# Visual Components
var _seal_nodes: Array[Node3D] = []
var _seal_lights: Array[OmniLight3D] = []
var _spout_root: Node3D = null
var _spout_cylinder: MeshInstance3D = null
var _spout_rings: Array[MeshInstance3D] = []
var _spout_particles: CPUParticles3D = null
var _islet_root: Node3D = null
var _chest_pivot: Node3D = null
var _chest_lid: Node3D = null
var _chest_sparks: CPUParticles3D = null
var _audio_chime: AudioStreamPlayer3D = null
var _audio_geyser: AudioStreamPlayer3D = null

# Materials
static var _stone_mat: StandardMaterial3D = null
static var _seal_off_mat: StandardMaterial3D = null
static var _seal_lit_mat: StandardMaterial3D = null
static var _water_spout_mat: StandardMaterial3D = null
static var _chest_lapis_mat: StandardMaterial3D = null
static var _chest_gold_mat: StandardMaterial3D = null
static var _islet_grass_mat: StandardMaterial3D = null
static var _water_chime_wav: AudioStreamWAV = null
static var _water_geyser_wav: AudioStreamWAV = null

func _init() -> void:
	name = "HydroLakeSanctuaryPuzzle"
	_init_materials()
	_init_audio()
	_build_puzzle_hierarchy()

static func _init_materials() -> void:
	if _stone_mat != null:
		return

	# Carved Sanctuary Pedestal Stone
	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.38, 0.44, 0.48)
	_stone_mat.roughness = 0.85

	# Submerged Seal Off (Pulsing Dim Cyan)
	_seal_off_mat = StandardMaterial3D.new()
	_seal_off_mat.albedo_color = Color(0.12, 0.45, 0.65)
	_seal_off_mat.emission_enabled = true
	_seal_off_mat.emission = Color(0.15, 0.60, 0.90)
	_seal_off_mat.emission_energy_multiplier = 1.0

	# Submerged Seal Activated (Radiant Azure)
	_seal_lit_mat = StandardMaterial3D.new()
	_seal_lit_mat.albedo_color = Color(0.30, 0.90, 1.0)
	_seal_lit_mat.emission_enabled = true
	_seal_lit_mat.emission = Color(0.20, 0.85, 1.0)
	_seal_lit_mat.emission_energy_multiplier = 4.0

	# Swirling Water Spout Column
	_water_spout_mat = StandardMaterial3D.new()
	_water_spout_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_water_spout_mat.albedo_color = Color(0.25, 0.80, 0.98, 0.55)
	_water_spout_mat.emission_enabled = true
	_water_spout_mat.emission = Color(0.18, 0.68, 0.92)
	_water_spout_mat.emission_energy_multiplier = 1.8
	_water_spout_mat.roughness = 0.10

	# Luxurious Chest Lapis Lazuli Body (Rich royal sapphire with elegant rim)
	_chest_lapis_mat = StandardMaterial3D.new()
	_chest_lapis_mat.albedo_color = Color(0.12, 0.32, 0.58)
	_chest_lapis_mat.roughness = 0.28
	_chest_lapis_mat.metallic = 0.25
	_chest_lapis_mat.rim_enabled = true
	_chest_lapis_mat.rim = 0.45
	_chest_lapis_mat.rim_tint = 0.50

	# Luxurious Chest Filigree Gold (Gleaming metallic gold without radioactive overglow)
	_chest_gold_mat = StandardMaterial3D.new()
	_chest_gold_mat.albedo_color = Color(0.96, 0.82, 0.32)
	_chest_gold_mat.metallic = 0.92
	_chest_gold_mat.roughness = 0.22
	_chest_gold_mat.emission_enabled = true
	_chest_gold_mat.emission = Color(0.55, 0.42, 0.12)
	_chest_gold_mat.emission_energy_multiplier = 0.65

	# Floating Islet Turf
	_islet_grass_mat = StandardMaterial3D.new()
	_islet_grass_mat.albedo_color = Color(0.24, 0.58, 0.30)
	_islet_grass_mat.roughness = 0.85

static func _init_audio() -> void:
	if _water_chime_wav == null:
		_water_chime_wav = _generate_water_chime_wav()
	if _water_geyser_wav == null:
		_water_geyser_wav = _generate_water_geyser_wav()

static func _generate_water_chime_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.95
	var total_samples: int = int(sample_rate * duration)
	var pcm_data: PackedByteArray = PackedByteArray()
	pcm_data.resize(total_samples * 2)

	var phase1: float = 0.0
	var phase2: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		# Ascending water chime harmonics (880 Hz & 1320 Hz)
		phase1 += (TAU * 880.0) / float(sample_rate)
		phase2 += (TAU * 1320.0) / float(sample_rate)
		var sig: float = (sin(phase1) * 0.65 + sin(phase2) * 0.35) * exp(-4.5 * t)
		var s_val: int = int(round(clampf(sig, -1.0, 1.0) * 32767.0))
		pcm_data.encode_s16(i * 2, s_val)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = pcm_data
	return wav

static func _generate_water_geyser_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 1.8
	var total_samples: int = int(sample_rate * duration)
	var pcm_data: PackedByteArray = PackedByteArray()
	pcm_data.resize(total_samples * 2)

	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		# Deep rushing water rumble
		var freq: float = lerpf(90.0, 180.0, sin(t * 5.0) * 0.5 + 0.5)
		phase += (TAU * freq) / float(sample_rate)
		var noise: float = randf_range(-0.35, 0.35)
		var sig: float = (sin(phase) * 0.65 + noise) * minf(t / 0.25, 1.0) * exp(-1.2 * maxf(t - 0.5, 0.0))
		var s_val: int = int(round(clampf(sig, -1.0, 1.0) * 32767.0))
		pcm_data.encode_s16(i * 2, s_val)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = pcm_data
	return wav

func _build_puzzle_hierarchy() -> void:
	# 1. Build 3 Submerged Runic Hydro Seals
	_seal_nodes.clear()
	_seal_lights.clear()
	for i in range(seal_positions.size()):
		var seal_node: Node3D = Node3D.new()
		seal_node.name = "HydroSeal_%d" % i
		seal_node.position = seal_positions[i]
		add_child(seal_node)

		# Stone Base Pedestal
		var base_mesh: MeshInstance3D = MeshInstance3D.new()
		var c_base: CylinderMesh = CylinderMesh.new()
		c_base.top_radius = 1.10
		c_base.bottom_radius = 1.30
		c_base.height = 0.40
		base_mesh.mesh = c_base
		base_mesh.material_override = _stone_mat
		base_mesh.position = Vector3(0.0, -0.15, 0.0)
		seal_node.add_child(base_mesh)

		# Submerged Runic Crystal
		var crystal_mesh: MeshInstance3D = MeshInstance3D.new()
		crystal_mesh.name = "RunicCrystal"
		var c_crys: CylinderMesh = CylinderMesh.new()
		c_crys.top_radius = 0.55
		c_crys.bottom_radius = 0.70
		c_crys.height = 0.30
		crystal_mesh.mesh = c_crys
		crystal_mesh.material_override = _seal_off_mat
		crystal_mesh.position = Vector3(0.0, 0.12, 0.0)
		seal_node.add_child(crystal_mesh)

		# Pulsing Cyan Light
		var seal_light: OmniLight3D = OmniLight3D.new()
		seal_light.name = "SealLight"
		seal_light.light_color = Color(0.25, 0.85, 1.0)
		seal_light.light_energy = 1.2
		seal_light.omni_range = 6.0
		seal_light.position = Vector3(0.0, 0.35, 0.0)
		seal_node.add_child(seal_light)

		_seal_nodes.append(seal_node)
		_seal_lights.append(seal_light)

	# 2. Build Hydro Water Spout Geyser (Center)
	_spout_root = Node3D.new()
	_spout_root.name = "HydroWaterSpout"
	_spout_root.position = SPOUT_CENTER
	_spout_root.visible = false
	add_child(_spout_root)

	# Water Cylinder Column (Stops cleanly beneath hovering islet base)
	_spout_cylinder = MeshInstance3D.new()
	_spout_cylinder.name = "SpoutColumn"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 1.40
	cyl.bottom_radius = 1.85
	cyl.height = 22.5
	_spout_cylinder.mesh = cyl
	_spout_cylinder.material_override = _water_spout_mat
	_spout_cylinder.position = Vector3(0.0, 11.25, 0.0)
	_spout_root.add_child(_spout_cylinder)

	# 3 Rising Torus Rings
	_spout_rings.clear()
	for r_idx in range(3):
		var ring: MeshInstance3D = MeshInstance3D.new()
		ring.name = "ToroidRing_%d" % r_idx
		var tor: TorusMesh = TorusMesh.new()
		tor.inner_radius = 1.40
		tor.outer_radius = 1.95
		ring.mesh = tor
		ring.material_override = _water_spout_mat
		ring.position = Vector3(0.0, float(r_idx) * 8.5, 0.0)
		_spout_root.add_child(ring)
		_spout_rings.append(ring)

	# Water Spray Particles
	_spout_particles = CPUParticles3D.new()
	_spout_particles.name = "SpoutParticles"
	_spout_particles.emitting = false
	_spout_particles.amount = 45
	_spout_particles.lifetime = 1.6
	_spout_particles.direction = Vector3(0, 1, 0)
	_spout_particles.spread = 15.0
	_spout_particles.gravity = Vector3(0, -6.0, 0)
	_spout_particles.initial_velocity_min = 18.0
	_spout_particles.initial_velocity_max = 28.0
	_spout_particles.scale_amount_min = 0.25
	_spout_particles.scale_amount_max = 0.65
	_spout_particles.color = Color(0.40, 0.90, 1.0, 0.70)
	_spout_root.add_child(_spout_particles)
	_spout_particles.position = Vector3(0.0, 1.0, 0.0)

	# 3. Build Hovering Floral Islet & Luxurious Chest
	_islet_root = Node3D.new()
	_islet_root.name = "HoveringFloralIslet"
	_islet_root.position = ISLET_CENTER
	add_child(_islet_root)

	# Floating Island Base (Inverted ancient rock pinnacle)
	var islet_base: MeshInstance3D = MeshInstance3D.new()
	islet_base.name = "IslandBase"
	var c_isl: CylinderMesh = CylinderMesh.new()
	c_isl.top_radius = 4.4
	c_isl.bottom_radius = 1.2
	c_isl.height = 3.2
	islet_base.mesh = c_isl
	islet_base.material_override = _stone_mat
	islet_base.position = Vector3(0.0, -1.6, 0.0)
	_islet_root.add_child(islet_base)

	# Island Grass Cap
	var grass_cap: MeshInstance3D = MeshInstance3D.new()
	grass_cap.name = "GrassCap"
	var c_grp: CylinderMesh = CylinderMesh.new()
	c_grp.top_radius = 4.5
	c_grp.bottom_radius = 4.3
	c_grp.height = 0.35
	grass_cap.mesh = c_grp
	grass_cap.material_override = _islet_grass_mat
	grass_cap.position = Vector3(0.0, 0.05, 0.0)
	_islet_root.add_child(grass_cap)

	# Ancient Stone Torus Border
	var stone_border: MeshInstance3D = MeshInstance3D.new()
	stone_border.name = "StoneBorder"
	var t_bor: TorusMesh = TorusMesh.new()
	t_bor.inner_radius = 4.15
	t_bor.outer_radius = 4.55
	stone_border.mesh = t_bor
	stone_border.material_override = _stone_mat
	stone_border.position = Vector3(0.0, 0.16, 0.0)
	_islet_root.add_child(stone_border)

	# Sacred Flora around Islet Rim
	for fl_i in range(6):
		var fl_angle: float = float(fl_i) * (TAU / 6.0) + 0.35
		var fl_pos: Vector3 = Vector3(cos(fl_angle) * 3.3, 0.22, sin(fl_angle) * 3.3)
		var lotus: MeshInstance3D = MeshInstance3D.new()
		var c_lotus: CylinderMesh = CylinderMesh.new()
		c_lotus.top_radius = 0.28
		c_lotus.bottom_radius = 0.08
		c_lotus.height = 0.22
		lotus.mesh = c_lotus
		lotus.material_override = _seal_lit_mat
		lotus.position = fl_pos
		_islet_root.add_child(lotus)

	# 4. Build Luxurious Island Chest (Authentic Genshin domed barrel vault)
	_chest_pivot = Node3D.new()
	_chest_pivot.name = "LuxuriousIslandChest"
	_chest_pivot.position = Vector3(0.0, 0.25, 0.0)
	_islet_root.add_child(_chest_pivot)

	# Chest Base Box (Lapis Lazuli with gold corner bevels)
	var chest_box: MeshInstance3D = MeshInstance3D.new()
	chest_box.name = "ChestBase"
	var b_box: BoxMesh = BoxMesh.new()
	b_box.size = Vector3(1.4, 0.70, 0.95)
	chest_box.mesh = b_box
	chest_box.material_override = _chest_lapis_mat
	chest_box.position = Vector3(0.0, 0.35, 0.0)
	_chest_pivot.add_child(chest_box)

	# Gold Filigree Rim
	var gold_trim: MeshInstance3D = MeshInstance3D.new()
	gold_trim.name = "GoldTrim"
	var b_trim: BoxMesh = BoxMesh.new()
	b_trim.size = Vector3(1.44, 0.12, 0.99)
	gold_trim.mesh = b_trim
	gold_trim.material_override = _chest_gold_mat
	gold_trim.position = Vector3(0.0, 0.68, 0.0)
	_chest_pivot.add_child(gold_trim)

	# Chest Hinged Lid Pivot
	_chest_lid = Node3D.new()
	_chest_lid.name = "ChestLidPivot"
	_chest_lid.position = Vector3(0.0, 0.70, 0.47)
	_chest_pivot.add_child(_chest_lid)

	# Domed Barrel Vault Lid
	var lid_mesh: MeshInstance3D = MeshInstance3D.new()
	lid_mesh.name = "LidMesh"
	var c_lid: CylinderMesh = CylinderMesh.new()
	c_lid.top_radius = 0.47
	c_lid.bottom_radius = 0.47
	c_lid.height = 1.42
	lid_mesh.mesh = c_lid
	lid_mesh.material_override = _chest_lapis_mat
	lid_mesh.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	lid_mesh.position = Vector3(0.0, 0.18, -0.47)
	_chest_lid.add_child(lid_mesh)

	# 2 Curved Gold Filigree Straps across the barrel vault
	for band_x in [-0.46, 0.46]:
		var band: MeshInstance3D = MeshInstance3D.new()
		var c_band: CylinderMesh = CylinderMesh.new()
		c_band.top_radius = 0.49
		c_band.bottom_radius = 0.49
		c_band.height = 0.10
		band.mesh = c_band
		band.material_override = _chest_gold_mat
		band.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		band.position = Vector3(band_x, 0.18, -0.47)
		_chest_lid.add_child(band)

	# Front Lock Plate
	var lid_gold_crest: MeshInstance3D = MeshInstance3D.new()
	var b_crest: BoxMesh = BoxMesh.new()
	b_crest.size = Vector3(0.30, 0.36, 0.08)
	lid_gold_crest.mesh = b_crest
	lid_gold_crest.material_override = _chest_gold_mat
	lid_gold_crest.position = Vector3(0.0, 0.12, -0.95)
	_chest_lid.add_child(lid_gold_crest)

	# Glowing Cyan Hydro Gem Clasp
	var hydro_gem: MeshInstance3D = MeshInstance3D.new()
	var s_gem: SphereMesh = SphereMesh.new()
	s_gem.radius = 0.08
	s_gem.height = 0.15
	hydro_gem.mesh = s_gem
	hydro_gem.material_override = _seal_lit_mat
	hydro_gem.position = Vector3(0.0, 0.12, -1.00)
	_chest_lid.add_child(hydro_gem)

	# Golden Chest Spark Particles
	_chest_sparks = CPUParticles3D.new()
	_chest_sparks.name = "ChestSparks"
	_chest_sparks.emitting = false
	_chest_sparks.one_shot = true
	_chest_sparks.amount = 35
	_chest_sparks.lifetime = 1.5
	_chest_sparks.explosiveness = 0.9
	_chest_sparks.direction = Vector3(0, 1, 0)
	_chest_sparks.spread = 45.0
	_chest_sparks.gravity = Vector3(0, -4.0, 0)
	_chest_sparks.initial_velocity_min = 3.5
	_chest_sparks.initial_velocity_max = 7.0
	_chest_sparks.scale_amount_min = 0.15
	_chest_sparks.scale_amount_max = 0.45
	_chest_sparks.color = Color(1.0, 0.88, 0.35, 0.95)
	_chest_pivot.add_child(_chest_sparks)
	_chest_sparks.position = Vector3(0.0, 0.85, 0.0)

	# 5. Audio Players
	_audio_chime = AudioStreamPlayer3D.new()
	_audio_chime.name = "AudioChime"
	_audio_chime.stream = _water_chime_wav
	_audio_chime.max_distance = 45.0
	add_child(_audio_chime)

	_audio_geyser = AudioStreamPlayer3D.new()
	_audio_geyser.name = "AudioGeyser"
	_audio_geyser.stream = _water_geyser_wav
	_audio_geyser.max_distance = 65.0
	add_child(_audio_geyser)

func _process(delta: float) -> void:
	_anim_time += delta

	# 1. Pulse inactive seals
	for i in range(seal_active.size()):
		if not seal_active[i] and i < _seal_lights.size():
			_seal_lights[i].light_energy = 0.8 + sin(_anim_time * 2.5 + float(i) * 1.5) * 0.4

	# 2. Animate Water Spout (swirl rotation and rising torus rings)
	if is_spout_active and _spout_root:
		_spout_cylinder.rotation.y += delta * 3.5
		for r_idx in range(_spout_rings.size()):
			var ring: MeshInstance3D = _spout_rings[r_idx]
			ring.rotation.y -= delta * 4.5
			# Ascend upward in loop from 1.0m to 25.0m
			var r_y: float = fposmod((float(r_idx) * 8.5) + (_anim_time * 11.0), 24.5) + 1.0
			ring.position.y = r_y
			# Torus ring expansion as it shoots skyward
			var s: float = 1.0 + (r_y / 25.0) * 0.35
			ring.scale = Vector3(s, 1.0, s)

	# 3. Animate Chest Lid smooth opening
	if is_chest_opened and _chest_lid:
		_chest_lid.rotation.x = lerp_angle(_chest_lid.rotation.x, -deg_to_rad(65.0), delta * 5.0)

	# 4. Subtle islet floating hover
	if _islet_root:
		_islet_root.position.y = ISLET_CENTER.y + sin(_anim_time * 1.2) * 0.25

func is_player_near_seal(p_pos: Vector3, seal_idx: int) -> bool:
	if seal_idx < 0 or seal_idx >= seal_positions.size():
		return false
	return p_pos.distance_to(seal_positions[seal_idx]) <= 3.5

func get_nearest_inactive_seal(p_pos: Vector3) -> int:
	var closest_idx: int = -1
	var min_dist: float = 3.5
	for i in range(seal_positions.size()):
		if not seal_active[i]:
			var d: float = p_pos.distance_to(seal_positions[i])
			if d <= min_dist:
				min_dist = d
				closest_idx = i
	return closest_idx

func activate_seal(idx: int) -> bool:
	if idx < 0 or idx >= seal_active.size():
		return false
	if seal_active[idx]:
		return false

	seal_active[idx] = true
	# Visual update: radiant azure material and high energy
	if idx < _seal_nodes.size():
		var crys: MeshInstance3D = _seal_nodes[idx].find_child("RunicCrystal", true, false) as MeshInstance3D
		if crys:
			crys.material_override = _seal_lit_mat
	if idx < _seal_lights.size():
		_seal_lights[idx].light_energy = 3.5
		_seal_lights[idx].light_color = Color(0.1, 0.95, 1.0)

	# Play water chime audio
	if _audio_chime and is_inside_tree():
		_audio_chime.position = seal_positions[idx]
		_audio_chime.play()

	var total_active: int = get_total_active_seals()
	seal_activated.emit(idx, total_active)
	print("[HydroLakeSanctuaryPuzzle] Seal %d activated! (%d/3 active)" % [idx + 1, total_active])

	if total_active == 3 and not is_spout_active:
		erupt_water_spout()

	return true

func get_total_active_seals() -> int:
	var count: int = 0
	for a in seal_active:
		if a:
			count += 1
	return count

func erupt_water_spout() -> void:
	is_spout_active = true
	if _spout_root:
		_spout_root.visible = true
	if _spout_particles and is_inside_tree():
		_spout_particles.emitting = true
	if _audio_geyser and is_inside_tree():
		_audio_geyser.position = SPOUT_CENTER
		_audio_geyser.play()

	spout_erupted.emit(SPOUT_CENTER)
	print("[HydroLakeSanctuaryPuzzle] Grand Emerald Lake rumbled — Hydro Water Spout erupted!")

func check_player_launch(p_pos: Vector3, walker: Node3D = null) -> bool:
	if not is_spout_active:
		return false

	var dist_xz: float = Vector2(p_pos.x, p_pos.z).distance_to(Vector2(SPOUT_CENTER.x, SPOUT_CENTER.z))
	if dist_xz <= 3.2 and p_pos.y <= SPOUT_CENTER.y + 6.0:
		var launch_vec: Vector3 = Vector3(0.0, LAUNCH_IMPULSE, 0.0)
		if walker and "velocity" in walker:
			walker.velocity.y = maxf(walker.velocity.y, LAUNCH_IMPULSE)
			# Impart gentle forward nudge toward islet center
			walker.velocity.x = (ISLET_CENTER.x - p_pos.x) * 0.4
			walker.velocity.z = (ISLET_CENTER.z - p_pos.z) * 0.4
			if walker.has_method("open_glider") and "is_gliding" in walker and not walker.is_gliding:
				walker.open_glider()
		player_launched.emit(launch_vec)
		print("[HydroLakeSanctuaryPuzzle] Player catapulted skyward by Hydro Spout (+26.5 m/s)!")
		return true
	return false

func is_player_near_chest(p_pos: Vector3) -> bool:
	var chest_global: Vector3 = _chest_pivot.global_position if (_chest_pivot and _chest_pivot.is_inside_tree()) else (ISLET_CENTER + Vector3(0.0, 0.25, 0.0))
	return p_pos.distance_to(chest_global) <= 3.2

func open_luxurious_chest() -> Dictionary:
	if is_chest_opened:
		return {}

	is_chest_opened = true
	if _chest_sparks and is_inside_tree():
		_chest_sparks.restart()
		_chest_sparks.emitting = true

	var reward: Dictionary = {
		"exp": 500,
		"coins": 200,
		"item": "hydro_heart_pearl",
		"item_title": "Ngọc Trái Tim Thủy Thần",
		"desc": "Bảo ngọc thuần khiết kết tinh từ linh khí Hồ Ngọc Bích, trao tặng quyền năng hòa hợp nguyên tố Thủy."
	}
	luxurious_chest_opened.emit(reward)
	print("[HydroLakeSanctuaryPuzzle] Opened Luxurious Island Chest on floating islet! Reward: %s" % reward["item_title"])
	return reward
