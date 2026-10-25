class_name AnemoWindGeyser
extends Node3D

## Living Planet Sandbox — Genshin-Style Anemo Wind Geyser (Mạch Phong Cổ Đại) (Block 57)
## Powerful ancient elemental wind geyser venting through the canyon rock shelf:
## 1. Sealed State:
##    - 3 breakable ancient boulders blocking the subterranean vent aperture.
##    - Interacting [E] or weapon attack strikes crumble the seal rocks.
## 2. Unsealed Eruption:
##    - Enormous 32m swirling vertical Anemo wind geyser cylinder with vortex rings.
##    - Procedural 16-bit PCM subterranean pressure release blast & roaring wind audio.
##    - Dynamic aerodynamic lift: Propels character upward with 22.0 m/s vertical surge,
##      auto-opening the Anemo Glider for high-altitude cliff soaring.
## 3. Rewards: +250 EXP, +80 Haven Coins, and Windshear Crest discovery.
## 4. Intel Iris Xe optimized: shared standard materials, 60 FPS budgeted.

signal geyser_unsealed(geyser_pos: Vector3)
signal geyser_propelled(character: Node3D, surge_velocity: float)

# State
var is_sealed: bool = true
var seal_health: int = 3
var vent_radius: float = 3.5
var geyser_height: float = 32.0
var _anim_time: float = 0.0

# Node References
var _vent_rim: MeshInstance3D = null
var _seal_rocks: Array[MeshInstance3D] = []
var _geyser_column: MeshInstance3D = null
var _vortex_rings: Array[MeshInstance3D] = []
var _audio_player: AudioStreamPlayer3D = null
var _wind_light: OmniLight3D = null

# Materials
static var _rim_stone_mat: StandardMaterial3D = null
static var _seal_rock_mat: StandardMaterial3D = null
static var _wind_stream_mat: StandardMaterial3D = null
static var _vortex_ring_mat: StandardMaterial3D = null
static var _blast_wav: AudioStreamWAV = null

func _init() -> void:
	name = "AnemoWindGeyser"
	_init_materials()
	_init_audio()
	_build_geyser_aperture()
	_build_seal_rocks()
	_build_wind_column()

static func _init_materials() -> void:
	if _rim_stone_mat != null:
		return

	# Weathered Basalt Well Rim
	_rim_stone_mat = StandardMaterial3D.new()
	_rim_stone_mat.albedo_color = Color(0.36, 0.38, 0.40)
	_rim_stone_mat.roughness = 0.90

	# Sealed Runestone with glowing turquoise fissures
	_seal_rock_mat = StandardMaterial3D.new()
	_seal_rock_mat.albedo_color = Color(0.42, 0.45, 0.42)
	_seal_rock_mat.roughness = 0.85
	_seal_rock_mat.emission_enabled = true
	_seal_rock_mat.emission = Color(0.25, 0.85, 0.70)
	_seal_rock_mat.emission_energy_multiplier = 0.8

	# Translucent Anemo Wind Column
	_wind_stream_mat = StandardMaterial3D.new()
	_wind_stream_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_wind_stream_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_wind_stream_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_wind_stream_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_wind_stream_mat.albedo_color = Color(0.30, 0.92, 0.80, 0.35)

	# Luminous Golden-Emerald Vortex Swirl Ring
	_vortex_ring_mat = StandardMaterial3D.new()
	_vortex_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_vortex_ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_vortex_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_vortex_ring_mat.albedo_color = Color(0.55, 0.95, 0.50, 0.65)

func _init_audio() -> void:
	if _blast_wav == null:
		_blast_wav = _generate_geyser_blast_wav()

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "GeyserAudio"
	_audio_player.stream = _blast_wav
	_audio_player.unit_size = 14.0
	_audio_player.max_distance = 65.0
	_audio_player.volume_db = 0.0
	add_child(_audio_player)

# =============================================================================
# ARCHITECTURE BUILDER
# =============================================================================
func _build_geyser_aperture() -> void:
	# Circular Stone Well Rim
	var rim_mesh = CylinderMesh.new()
	rim_mesh.top_radius = vent_radius + 0.4
	rim_mesh.bottom_radius = vent_radius + 0.8
	rim_mesh.height = 0.6
	_vent_rim = MeshInstance3D.new()
	_vent_rim.mesh = rim_mesh
	_vent_rim.material_override = _rim_stone_mat
	_vent_rim.position.y = 0.3
	add_child(_vent_rim)

func _build_seal_rocks() -> void:
	var offsets = [
		Vector3(-0.9, 0.55, -0.6),
		Vector3(0.9, 0.60, -0.4),
		Vector3(0.0, 0.65, 0.9)
	]
	for i in range(offsets.size()):
		var rock_mesh = SphereMesh.new()
		rock_mesh.radius = 1.15
		rock_mesh.height = 1.6
		var r_mi = MeshInstance3D.new()
		r_mi.name = "SealRock_%d" % i
		r_mi.mesh = rock_mesh
		r_mi.material_override = _seal_rock_mat
		r_mi.position = offsets[i]
		r_mi.rotation = Vector3(randf_range(-0.3, 0.3), randf_range(0.0, TAU), randf_range(-0.3, 0.3))
		add_child(r_mi)
		_seal_rocks.append(r_mi)

func _build_wind_column() -> void:
	# Giant vertical updraft cylinder
	var col_mesh = CylinderMesh.new()
	col_mesh.top_radius = vent_radius * 1.1
	col_mesh.bottom_radius = vent_radius * 0.9
	col_mesh.height = geyser_height
	_geyser_column = MeshInstance3D.new()
	_geyser_column.mesh = col_mesh
	_geyser_column.material_override = _wind_stream_mat
	_geyser_column.position.y = geyser_height * 0.5 + 0.3
	_geyser_column.visible = false # Hidden while sealed
	add_child(_geyser_column)

	# 3 Ascending Vortex Swirl Rings
	for r in range(3):
		var ring_mesh = TorusMesh.new()
		ring_mesh.inner_radius = vent_radius * 0.75
		ring_mesh.outer_radius = vent_radius * 1.05
		var ring_mi = MeshInstance3D.new()
		ring_mi.mesh = ring_mesh
		ring_mi.material_override = _vortex_ring_mat
		ring_mi.position.y = 3.0 + float(r) * 10.0
		ring_mi.visible = false
		add_child(ring_mi)
		_vortex_rings.append(ring_mi)

	# Internal Anemo Glow Light
	_wind_light = OmniLight3D.new()
	_wind_light.light_color = Color(0.35, 0.95, 0.85)
	_wind_light.light_energy = 0.0
	_wind_light.omni_range = 16.0
	_wind_light.position.y = 2.5
	add_child(_wind_light)

# =============================================================================
# SEAL DAMAGE & ERUPTION LOGIC
# =============================================================================
func damage_seal(amount: int = 1) -> bool:
	if not is_sealed:
		return false

	seal_health = maxi(0, seal_health - amount)

	# Shrink or remove damaged rocks
	var active_rocks: int = 0
	for i in range(_seal_rocks.size()):
		if i >= seal_health:
			_seal_rocks[i].visible = false
		else:
			active_rocks += 1

	if seal_health <= 0:
		unseal_geyser()
		return true
	return false

func unseal_geyser() -> void:
	if not is_sealed:
		return
	is_sealed = false
	seal_health = 0

	for r in _seal_rocks:
		r.visible = false

	_geyser_column.visible = true
	for ring in _vortex_rings:
		ring.visible = true

	if _wind_light:
		_wind_light.light_energy = 2.4

	if _audio_player and is_inside_tree():
		_audio_player.play()

	var emit_pos: Vector3 = global_position if is_inside_tree() else position
	geyser_unsealed.emit(emit_pos)

func _process(delta: float) -> void:
	if is_sealed:
		return

	_anim_time += delta

	# Animate ascending vortex rings
	for r_idx in range(_vortex_rings.size()):
		var ring = _vortex_rings[r_idx]
		ring.rotation.y += delta * 4.5
		var r_y = fmod((_anim_time * 8.0 + float(r_idx) * 10.0), geyser_height)
		ring.position.y = 1.0 + r_y
		var pulse_scale = 1.0 + sin(_anim_time * 6.0 + float(r_idx)) * 0.15
		ring.scale = Vector3(pulse_scale, 1.0, pulse_scale)

	# Pulse wind column breathing
	if _geyser_column:
		_geyser_column.rotation.y -= delta * 1.2

func check_character_propulsion(walker: Node3D) -> bool:
	if is_sealed or walker == null:
		return false

	var char_pos: Vector3 = walker.global_position if walker.is_inside_tree() else walker.position
	var self_pos: Vector3 = global_position if is_inside_tree() else position

	var horiz_dist = Vector2(char_pos.x - self_pos.x, char_pos.z - self_pos.z).length()
	var vert_dist = char_pos.y - self_pos.y

	if horiz_dist <= vent_radius and vert_dist >= -1.0 and vert_dist <= geyser_height:
		# Propel character upward
		if walker.has_method("apply_vertical_impulse"):
			walker.apply_vertical_impulse(22.0)
		elif "velocity" in walker:
			walker.velocity.y = 22.0

		if walker.has_method("open_glider"):
			walker.open_glider()

		geyser_propelled.emit(walker, 22.0)
		return true
	return false

# =============================================================================
# PROCEDURAL 16-BIT PCM AUDIO SYNTHESIZER
# =============================================================================
func _generate_geyser_blast_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 2.5
	var total_samples: int = int(sample_rate * duration)
	var byte_count: int = total_samples * 2
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(byte_count)

	# Powerful subterranean explosion blast followed by rushing continuous wind
	var f_low: float = 65.0
	var f_rush: float = 240.0

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)

		# Initial blast burst in first 0.4s, then steady rushing storm
		var blast_env: float = exp(-t * 3.5) if t < 0.8 else 0.0
		var storm_env: float = smoothstep(0.1, 0.6, t) * (1.0 - smoothstep(1.8, 2.5, t)) * 0.45

		var noise: float = (randf() * 2.0 - 1.0) * 0.35
		var low_thud: float = sin(t * f_low * TAU) * 0.65
		var wind_whistle: float = sin(t * f_rush * TAU + sin(t * 12.0) * 2.0) * 0.25

		var sample_val: float = (low_thud + noise) * blast_env + (wind_whistle + noise) * storm_env
		var int_val: int = int(clampf(sample_val, -1.0, 1.0) * 32767.0)

		var byte_idx: int = i * 2
		buffer[byte_idx] = int_val & 0xFF
		buffer[byte_idx + 1] = (int_val >> 8) & 0xFF

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = buffer
	return wav
