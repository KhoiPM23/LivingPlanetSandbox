@tool
class_name TeleportWaypoint3D
extends Node3D

## Living Planet Sandbox — Genshin-Style Ancient Teleport Waypoint
## Features:
## - Ancient carved stone plinth with floating, levitating crystalline core
## - Dual state: Dormant/Locked (Crimson Red) -> Resonant/Unlocked (Anemo Cyan Teal)
## - Skyward beacon pillar of light & ambient floating energy wisps
## - Pure-math procedural audio synthesis for Ascension Chime & Teleport Warp

signal waypoint_unlocked(id: String, display_name: String)

@export var waypoint_id: String = "haven_pier"
@export var waypoint_name: String = "Tiền Đồn Haven"
@export var waypoint_desc: String = "Cầu cảng cổ vịnh ngọc bích Emerald Cove."
@export var is_unlocked: bool = false

var _crystal: MeshInstance3D = null
var _crystal_light: OmniLight3D = null
var _beacon_beam: MeshInstance3D = null
var _energy_particles: GPUParticles3D = null
var _status_label: Label3D = null
var _audio_player: AudioStreamPlayer3D = null

var _anim_time: float = 0.0
var _pulse_flash: float = 0.0

# Materials
var _stone_mat: StandardMaterial3D = null
var _crystal_locked_mat: StandardMaterial3D = null
var _crystal_unlocked_mat: StandardMaterial3D = null
var _beacon_mat: StandardMaterial3D = null

static var _ascension_chime_wav: AudioStreamWAV = null
static var _teleport_warp_wav: AudioStreamWAV = null

func _init() -> void:
	_init_materials()
	_init_audio()

func _ready() -> void:
	if not _crystal:
		_build_waypoint_structure()
	_update_visual_state(false)

func setup(id: String, title: String, desc: String, world_pos: Vector3, unlocked: bool = false) -> void:
	waypoint_id = id
	waypoint_name = title
	waypoint_desc = desc
	is_unlocked = unlocked
	position = world_pos
	if not _crystal:
		_build_waypoint_structure()
	_update_visual_state(false)

func _init_materials() -> void:
	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.36, 0.35, 0.38) # Weathered granite
	_stone_mat.roughness = 0.90

	_crystal_locked_mat = StandardMaterial3D.new()
	_crystal_locked_mat.albedo_color = Color(0.72, 0.16, 0.14)
	_crystal_locked_mat.roughness = 0.25
	_crystal_locked_mat.emission_enabled = true
	_crystal_locked_mat.emission = Color(0.85, 0.12, 0.10)
	_crystal_locked_mat.emission_energy_multiplier = 0.85

	_crystal_unlocked_mat = StandardMaterial3D.new()
	_crystal_unlocked_mat.albedo_color = Color(0.18, 0.95, 0.88) # Anemo teal
	_crystal_unlocked_mat.metallic = 0.25
	_crystal_unlocked_mat.roughness = 0.15
	_crystal_unlocked_mat.emission_enabled = true
	_crystal_unlocked_mat.emission = Color(0.15, 0.92, 0.82)
	_crystal_unlocked_mat.emission_energy_multiplier = 2.4

	_beacon_mat = StandardMaterial3D.new()
	_beacon_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beacon_mat.albedo_color = Color(0.20, 0.95, 0.88, 0.35)
	_beacon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beacon_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

func _init_audio() -> void:
	if _ascension_chime_wav == null:
		_ascension_chime_wav = _generate_ascension_chime_wav(1.4, 22050)
		_teleport_warp_wav = _generate_teleport_warp_wav(0.65, 22050)

func _build_waypoint_structure() -> void:
	# 1. Base Carved Hexagonal Plinth
	var base: MeshInstance3D = MeshInstance3D.new()
	var b_cyl: CylinderMesh = CylinderMesh.new()
	b_cyl.top_radius = 0.95
	b_cyl.bottom_radius = 1.15
	b_cyl.height = 0.70
	base.mesh = b_cyl
	base.material_override = _stone_mat
	base.position = Vector3(0.0, 0.35, 0.0)
	add_child(base)

	# 2. Carved Pedestal Columns (3 curved stone brackets)
	for i in range(3):
		var angle: float = float(i) * TAU / 3.0
		var col: MeshInstance3D = MeshInstance3D.new()
		var c_box: BoxMesh = BoxMesh.new()
		c_box.size = Vector3(0.22, 1.35, 0.28)
		col.mesh = c_box
		col.material_override = _stone_mat
		col.position = Vector3(cos(angle) * 0.70, 1.25, sin(angle) * 0.70)
		col.rotation.y = -angle
		col.rotation.x = deg_to_rad(12.0)
		add_child(col)

	# 3. Levitating Diamond Crystal Core
	_crystal = MeshInstance3D.new()
	_crystal.name = "LevitatingCore"
	var prism: PrismMesh = PrismMesh.new()
	prism.size = Vector3(0.48, 0.85, 0.48)
	_crystal.mesh = prism
	_crystal.material_override = _crystal_locked_mat
	_crystal.position = Vector3(0.0, 1.65, 0.0)
	add_child(_crystal)

	# Core OmniLight
	_crystal_light = OmniLight3D.new()
	_crystal_light.name = "CoreLight"
	_crystal_light.light_color = Color(1.0, 0.25, 0.20)
	_crystal_light.light_energy = 1.0
	_crystal_light.omni_range = 6.0
	_crystal.add_child(_crystal_light)

	# 4. Skyward Vertical Beacon Pillar
	_beacon_beam = MeshInstance3D.new()
	_beacon_beam.name = "SkywardBeacon"
	var beam_cyl: CylinderMesh = CylinderMesh.new()
	beam_cyl.top_radius = 0.22
	beam_cyl.bottom_radius = 0.35
	beam_cyl.height = 42.0
	_beacon_beam.mesh = beam_cyl
	_beacon_beam.material_override = _beacon_mat
	_beacon_beam.position = Vector3(0.0, 22.5, 0.0)
	add_child(_beacon_beam)

	# 5. Anemo Energy Particles
	_energy_particles = GPUParticles3D.new()
	_energy_particles.name = "AnemoWisps"
	_energy_particles.amount = 16
	_energy_particles.lifetime = 1.2
	_energy_particles.position = Vector3(0.0, 1.5, 0.0)

	var p_proc: ParticleProcessMaterial = ParticleProcessMaterial.new()
	p_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	p_proc.emission_sphere_radius = 0.65
	p_proc.direction = Vector3(0.0, 1.0, 0.0)
	p_proc.spread = 20.0
	p_proc.initial_velocity_min = 0.8
	p_proc.initial_velocity_max = 2.2
	p_proc.gravity = Vector3(0.0, 0.5, 0.0)
	p_proc.scale_min = 0.06
	p_proc.scale_max = 0.16
	p_proc.color = Color(0.25, 0.98, 0.88, 0.75)
	_energy_particles.process_material = p_proc

	var p_sph: SphereMesh = SphereMesh.new()
	p_sph.radius = 0.05
	p_sph.height = 0.10
	var p_mat: StandardMaterial3D = StandardMaterial3D.new()
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.albedo_color = Color(0.35, 1.0, 0.92, 0.65)
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_sph.material = p_mat
	_energy_particles.draw_pass_1 = p_sph
	add_child(_energy_particles)

	# 6. Overhead 3D Status Label
	_status_label = Label3D.new()
	_status_label.name = "WaypointLabel"
	_status_label.font_size = 20
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.position = Vector3(0.0, 2.65, 0.0)
	add_child(_status_label)

	# 7. Audio emitter
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "WaypointAudioEmitter"
	_audio_player.unit_size = 5.0
	_audio_player.max_distance = 45.0
	add_child(_audio_player)

	# 8. Static collision volume
	var sb: StaticBody3D = StaticBody3D.new()
	sb.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var cyl_shape: CylinderShape3D = CylinderShape3D.new()
	cyl_shape.radius = 1.0
	cyl_shape.height = 1.6
	cs.shape = cyl_shape
	cs.position = Vector3(0.0, 0.8, 0.0)
	sb.add_child(cs)
	add_child(sb)

func _process(delta: float) -> void:
	_anim_time += delta

	# Levitating crystal core continuous floating & rotation
	if _crystal:
		_crystal.rotation.y += delta * (2.4 if is_unlocked else 0.8)
		var bob: float = sin(_anim_time * (2.4 if is_unlocked else 1.4)) * 0.10
		_crystal.position.y = 1.65 + bob

	# Flash pulse recovery
	if _pulse_flash > 0.0:
		_pulse_flash = maxf(0.0, _pulse_flash - delta * 3.0)
		if _crystal_light:
			_crystal_light.light_energy = (2.2 + _pulse_flash * 6.0) if is_unlocked else 1.0

func unlock() -> bool:
	if is_unlocked:
		return false

	is_unlocked = true
	_pulse_flash = 1.0
	_update_visual_state(true)
	_play_sound(_ascension_chime_wav, -8.0)
	waypoint_unlocked.emit(waypoint_id, waypoint_name)
	return true

func _update_visual_state(play_particles: bool) -> void:
	if not _crystal or not _crystal_light or not _status_label or not _beacon_beam:
		return

	if is_unlocked:
		_crystal.material_override = _crystal_unlocked_mat
		_crystal_light.light_color = Color(0.20, 0.95, 0.88)
		_crystal_light.light_energy = 2.2
		_crystal_light.omni_range = 9.0
		_beacon_beam.visible = true
		if _energy_particles:
			_energy_particles.emitting = true
		_status_label.text = "✨ %s\n[E] Dịch Chuyển [M]" % waypoint_name.to_upper()
		_status_label.modulate = Color(0.65, 1.0, 0.95)
		_status_label.outline_modulate = Color(0.05, 0.20, 0.18, 0.9)
	else:
		_crystal.material_override = _crystal_locked_mat
		_crystal_light.light_color = Color(1.0, 0.25, 0.20)
		_crystal_light.light_energy = 0.9
		_crystal_light.omni_range = 4.5
		_beacon_beam.visible = false
		if _energy_particles:
			_energy_particles.emitting = false
		_status_label.text = "🔴 ĐIỂM DỊCH CHUYỂN\n[E] Kích hoạt: %s" % waypoint_name
		_status_label.modulate = Color(1.0, 0.55, 0.45)
		_status_label.outline_modulate = Color(0.25, 0.05, 0.05, 0.9)

	if play_particles and _energy_particles:
		_energy_particles.restart()

func can_interact(player_pos: Vector3) -> bool:
	var my_pos: Vector3 = global_position if is_inside_tree() else position
	return my_pos.distance_to(player_pos) <= 3.2

func get_teleport_arrival_position() -> Vector3:
	var my_pos: Vector3 = global_position if is_inside_tree() else position
	# Spawn 1.8m in front of pedestal (+Z forward)
	return my_pos + Vector3(0.0, 0.1, 1.8)

func play_teleport_arrival_fx() -> void:
	_play_sound(_teleport_warp_wav, -10.0)
	if _energy_particles:
		_energy_particles.restart()

func _play_sound(wav: AudioStreamWAV, vol_db: float) -> void:
	if not _audio_player or wav == null or not is_inside_tree():
		return
	_audio_player.stream = wav
	_audio_player.volume_db = vol_db
	_audio_player.pitch_scale = randf_range(0.98, 1.02)
	_audio_player.play()

# =============================================================================
# SYNTHESIZERS (Harmonic Ascension Chime & Teleport Warp)
# =============================================================================
static func _generate_ascension_chime_wav(duration: float, rate: int) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	# Frequencies of a mystical Major 9th chord (E4, G#4, B4, D#5, F#5)
	var freqs: Array[float] = [329.63, 415.30, 493.88, 622.25, 739.99]
	var delays: Array[float] = [0.0, 0.08, 0.16, 0.24, 0.32]

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var sample: float = 0.0

		for c in range(freqs.size()):
			var note_t: float = t - delays[c]
			if note_t >= 0.0:
				var note_env: float = exp(-4.2 * note_t)
				var tone: float = sin(note_t * freqs[c] * TAU) * 0.7 + sin(note_t * freqs[c] * 2.0 * TAU) * 0.3
				sample += tone * note_env * 0.22

		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_teleport_warp_wav(duration: float, rate: int) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI) * 0.45
		var freq: float = lerpf(240.0, 880.0, pow(t / duration, 0.75))
		var sample: float = sin(t * freq * TAU) * env
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
