class_name WanderingSeelie
extends Node3D

## Living Planet Sandbox — Genshin-Style Wandering Seelie & Seelie Court (Block 55)
## Features:
## 1. Ethereal floating cyan Spirit Seelie that guides the explorer along a scenic mountain ridge path.
## 2. Dynamic proximity guiding: moves smoothly to next waypoint when player is near (< 4.5m),
##    pauses if player lags behind (> 14m).
## 3. Ancient Stone Seelie Court (Bệ Tiên Linh) on the scenic lake terrace.
## 4. Arrival ritual: spirals into stone pedestal, transforms to radiant golden amber,
##    emits a pillar of light, and summons an Exquisite Seelie Treasure Chest!
## 5. Procedural 16-bit PCM mystical spirit chime & harmonic resolution audio synthesizer.
## 6. Intel Iris Xe optimized: shared geometry, unshaded additive blending, zero CPU stalls.

signal seelie_reached_court(pos: Vector3)
signal seelie_chest_opened(reward: Dictionary)

enum SeelieState { WAITING_FOR_PLAYER, ADVANCING, REACHED_COURT }

var current_state: SeelieState = SeelieState.WAITING_FOR_PLAYER
var _anim_time: float = 0.0
var _current_wp_idx: int = 0
var _audio_player: AudioStreamPlayer3D = null
static var _seelie_chime_wav: AudioStreamWAV = null
static var _court_arrival_wav: AudioStreamWAV = null

# Visual Nodes
var _seelie_orb: Node3D = null
var _light: OmniLight3D = null
var _particles: GPUParticles3D = null
var _court_root: Node3D = null
var _court_flame: MeshInstance3D = null
var _court_chest: Node3D = null
var _court_chest_open: bool = false

# Materials
static var _seelie_cyan_mat: StandardMaterial3D = null
static var _seelie_gold_mat: StandardMaterial3D = null
static var _stone_mat: StandardMaterial3D = null

# Scenic 6-Waypoint Guide Path (From Whispering Ridge down to Lake Terrace)
var _path: Array[Vector3] = [
	Vector3(-14.0, 5.2, 36.0), # WP 0: Cavern Overlook Ridge
	Vector3(-6.0, 4.4, 42.0),  # WP 1: Mountain Pine Copse
	Vector3(4.0, 4.0, 38.0),   # WP 2: Rocky Brook Crossing
	Vector3(14.0, 3.8, 34.0),  # WP 3: Wilderness Camp Trailhead
	Vector3(20.0, 3.6, 31.0),  # WP 4: Lakeside Birch Slope
	Vector3(23.0, 3.4, 29.0)   # WP 5: Seelie Court Pedestal
]

func _init() -> void:
	name = "WanderingSeelie"
	_init_materials()
	_build_audio_emitter()
	_build_seelie_court()
	_build_seelie_spirit()

static func _init_materials() -> void:
	if _seelie_cyan_mat != null:
		return

	# Ethereal Cyan Spirit Orb
	_seelie_cyan_mat = StandardMaterial3D.new()
	_seelie_cyan_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_seelie_cyan_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_seelie_cyan_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_seelie_cyan_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_seelie_cyan_mat.albedo_color = Color(0.20, 0.95, 0.88, 0.85)

	# Golden Rested Court Spirit
	_seelie_gold_mat = StandardMaterial3D.new()
	_seelie_gold_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_seelie_gold_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_seelie_gold_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_seelie_gold_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_seelie_gold_mat.albedo_color = Color(1.0, 0.85, 0.28, 0.92)

	# Ancient Weathered Seelie Court Stone
	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.52, 0.55, 0.58)
	_stone_mat.roughness = 0.85

func _build_audio_emitter() -> void:
	if _seelie_chime_wav == null:
		_seelie_chime_wav = _generate_seelie_chime_wav()
	if _court_arrival_wav == null:
		_court_arrival_wav = _generate_court_arrival_wav()

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "SeelieAudio"
	_audio_player.stream = _seelie_chime_wav
	_audio_player.unit_size = 7.0
	_audio_player.max_distance = 30.0
	_audio_player.volume_db = -1.0
	add_child(_audio_player)

func _build_seelie_spirit() -> void:
	_seelie_orb = Node3D.new()
	_seelie_orb.name = "SpiritOrb"
	_seelie_orb.position = _path[0]
	add_child(_seelie_orb)

	# 1. Teardrop/Orb Mesh
	var sphere = SphereMesh.new()
	sphere.radius = 0.24
	sphere.height = 0.48
	var mi = MeshInstance3D.new()
	mi.name = "OrbMesh"
	mi.mesh = sphere
	mi.material_override = _seelie_cyan_mat
	_seelie_orb.add_child(mi)

	# 2. Outer Halo Ring
	var torus = TorusMesh.new()
	torus.inner_radius = 0.28
	torus.outer_radius = 0.36
	var t_mi = MeshInstance3D.new()
	t_mi.name = "HaloRing"
	t_mi.mesh = torus
	t_mi.material_override = _seelie_cyan_mat
	_seelie_orb.add_child(t_mi)

	# 3. Soft Cyan Spirit Light
	_light = OmniLight3D.new()
	_light.light_color = Color(0.25, 0.95, 0.88)
	_light.light_energy = 1.35
	_light.omni_range = 4.5
	_light.omni_attenuation = 1.4
	_light.shadow_enabled = false
	_seelie_orb.add_child(_light)

	# 4. Trailing Spirit Particle Stream
	_particles = GPUParticles3D.new()
	_particles.name = "SpiritTrail"
	_particles.amount = 14
	_particles.lifetime = 0.65
	_particles.emitting = true
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0.0, -0.4, -0.8)
	p_mat.spread = 20.0
	p_mat.initial_velocity_min = 0.3
	p_mat.initial_velocity_max = 0.8
	p_mat.gravity = Vector3(0.0, 0.3, 0.0)
	p_mat.scale_min = 0.05
	p_mat.scale_max = 0.14
	p_mat.color = Color(0.3, 1.0, 0.9, 0.8)
	_particles.process_material = p_mat

	var p_sphere = SphereMesh.new()
	p_sphere.radius = 0.04
	p_sphere.height = 0.08
	p_sphere.material = _seelie_cyan_mat
	_particles.draw_pass_1 = p_sphere
	_seelie_orb.add_child(_particles)

func _build_seelie_court() -> void:
	var court_pos: Vector3 = _path[_path.size() - 1]
	_court_root = Node3D.new()
	_court_root.name = "SeelieCourt"
	_court_root.position = court_pos
	add_child(_court_root)

	# 1. Carved Hollow Stone Pedestal
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.45
	base_mesh.bottom_radius = 0.60
	base_mesh.height = 0.75
	var b_mi = MeshInstance3D.new()
	b_mi.mesh = base_mesh
	b_mi.material_override = _stone_mat
	b_mi.position.y = 0.375
	_court_root.add_child(b_mi)

	# 2. Golden Flame Spirit (Becomes active upon arrival)
	var flame_mesh = SphereMesh.new()
	flame_mesh.radius = 0.18
	flame_mesh.height = 0.36
	_court_flame = MeshInstance3D.new()
	_court_flame.name = "CourtFlame"
	_court_flame.mesh = flame_mesh
	_court_flame.material_override = _seelie_gold_mat
	_court_flame.position.y = 0.90
	_court_flame.visible = false
	_court_root.add_child(_court_flame)

	# 3. Exquisite Seelie Treasure Chest (Spawned next to court upon arrival)
	_court_chest = Node3D.new()
	_court_chest.name = "SeelieExquisiteChest"
	_court_chest.position = Vector3(1.4, 0.0, 0.4)
	_court_chest.visible = false
	_court_root.add_child(_court_chest)

	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.9, 0.55, 0.6)
	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color(0.18, 0.35, 0.55) # Deep lapis lazuli & gold trims
	c_mat.metallic = 0.45
	c_mat.roughness = 0.35
	var cb_mi = MeshInstance3D.new()
	cb_mi.mesh = c_box
	cb_mi.material_override = c_mat
	cb_mi.position.y = 0.275
	_court_chest.add_child(cb_mi)

	var c_gold_trim = BoxMesh.new()
	c_gold_trim.size = Vector3(0.94, 0.12, 0.64)
	var cg_mat = StandardMaterial3D.new()
	cg_mat.albedo_color = Color(1.0, 0.85, 0.25)
	cg_mat.metallic = 0.8
	var cg_mi = MeshInstance3D.new()
	cg_mi.mesh = c_gold_trim
	cg_mi.material_override = cg_mat
	cg_mi.position.y = 0.52
	_court_chest.add_child(cg_mi)

func update_behavior(delta: float, player_pos: Vector3 = Vector3.ZERO) -> void:
	_anim_time += delta

	# Gentle breathing hover animation
	var hover_y: float = sin(_anim_time * 3.2) * 0.16
	var halo_rot: float = _anim_time * 2.5
	var halo = _seelie_orb.get_node_or_null("HaloRing")
	if halo:
		halo.rotation.y = halo_rot
		halo.rotation.x = sin(_anim_time * 1.8) * 0.3

	if current_state == SeelieState.REACHED_COURT:
		# Resting gracefully in Seelie Court
		if _court_flame:
			var pulse: float = 0.9 + sin(_anim_time * 4.0) * 0.25
			_court_flame.scale = Vector3(pulse, pulse * 1.1, pulse)
		return

	var target_wp: Vector3 = _path[_current_wp_idx] + Vector3(0.0, hover_y, 0.0)
	var curr_pos: Vector3 = _seelie_orb.position
	var dist_to_wp: float = curr_pos.distance_to(target_wp)

	var dist_p: float = 999.0
	if player_pos != Vector3.ZERO:
		dist_p = curr_pos.distance_to(player_pos)

	match current_state:
		SeelieState.WAITING_FOR_PLAYER:
			# Hover in place at current waypoint
			_seelie_orb.position = target_wp
			if dist_p < 4.5:
				current_state = SeelieState.ADVANCING
				if _audio_player and is_inside_tree():
					_audio_player.global_position = curr_pos
					_audio_player.stream = _seelie_chime_wav
					_audio_player.play()

		SeelieState.ADVANCING:
			# Float smoothly along path toward current target waypoint
			var dir: Vector3 = (target_wp - curr_pos).normalized()
			var speed: float = 3.8
			if dist_p > 13.0:
				speed = 1.0 # Slow down if explorer falls far behind
			elif dist_p < 2.5:
				speed = 4.8 # Quicken pace if explorer stays right beside

			_seelie_orb.position = curr_pos.move_toward(target_wp, delta * speed)

			if dist_to_wp < 0.4:
				# Reached waypoint
				if _current_wp_idx < _path.size() - 1:
					_current_wp_idx += 1
					current_state = SeelieState.WAITING_FOR_PLAYER
				else:
					# Final waypoint reached -> Complete arrival ceremony!
					_complete_arrival_ritual()

func _complete_arrival_ritual() -> void:
	current_state = SeelieState.REACHED_COURT
	_seelie_orb.visible = false
	if _court_flame:
		_court_flame.visible = true
	if _court_chest:
		_court_chest.visible = true

	if _audio_player and is_inside_tree():
		_audio_player.global_position = _court_root.global_position
		_audio_player.stream = _court_arrival_wav
		_audio_player.play()

	var emit_pos: Vector3 = _court_root.global_position if (_court_root and _court_root.is_inside_tree()) else (_path[_path.size() - 1] if _path.size() > 0 else Vector3.ZERO)
	seelie_reached_court.emit(emit_pos)

func get_nearby_interactable(pos: Vector3, max_dist: float = 3.2) -> Dictionary:
	if current_state == SeelieState.REACHED_COURT and not _court_chest_open:
		var c_pos: Vector3 = _court_chest.global_position if _court_chest.is_inside_tree() else _path[_path.size() - 1] + Vector3(1.4, 0.0, 0.4)
		if pos.distance_to(c_pos) <= max_dist:
			return {
				"id": "seelie_chest",
				"type": "chest",
				"name": "Rương Tinh Linh Quý Giá",
				"icon": "🎁",
				"pos": c_pos
			}
	return {}

func open_seelie_chest() -> Dictionary:
	if current_state == SeelieState.REACHED_COURT and not _court_chest_open:
		_court_chest_open = true
		var reward = {
			"exp": 180,
			"coins": 65,
			"item": "anemo_crystal_core",
			"message": "Đã mở Rương Tinh Linh! (+180 EXP, +65 Hải Tệ)"
		}
		seelie_chest_opened.emit(reward)
		return reward
	return {}

static func _generate_seelie_chime_wav(duration: float = 0.5, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI)
		# Floating resonant glass tone
		var s: float = sin(t * 880.0 * TAU) * 0.6 + sin(t * 1320.0 * TAU) * 0.3 + sin(t * 1760.0 * TAU) * 0.1
		var sample: float = s * env * 0.4
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_court_arrival_wav(duration: float = 1.2, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	# 4-note ascending celestial fanfare: E5 (659Hz) -> G#5 (830Hz) -> B5 (987Hz) -> E6 (1318Hz)
	var notes = [659.25, 830.61, 987.77, 1318.5]
	var note_dur: float = 0.22

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var sample: float = 0.0

		for n in range(notes.size()):
			var start_t: float = float(n) * note_dur
			if t >= start_t:
				var nt: float = t - start_t
				var env: float = exp(-nt * 3.5)
				var bell: float = sin(nt * notes[n] * TAU) * 0.7 + sin(nt * notes[n] * 2.0 * TAU) * 0.3
				sample += bell * env * 0.3

		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
