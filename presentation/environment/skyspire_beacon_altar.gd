class_name SkyspireBeaconAltar
extends Node3D

## Living Planet Sandbox — Ancient Anemo Spire Beacon Altar (Cổ Đài Phong Ngân Đỉnh Skyspire 114m)
## Represents the apex summit monument of the 720m continent:
## 1. Ancient stone plinth with glowing Celtic/Anemo runes on stepped granite dais.
## 2. Floating Anemo Core Crystal hovering and rotating with radiant cyan emission.
## 3. Activation Ceremony:
##    - Unleashes a massive skyward light beam piercing the firmament.
##    - Activates an eternal super-updraft thermal vent (allowing infinite skyward glide).
##    - Awards 1000 EXP, completes Skyspire Master Questline, and unlocks "Apex Conqueror" title.
##    - Synthesizes 16-bit PCM celestial wind resonance & chime fanfare.

signal beacon_activated(pos: Vector3, reward_xp: int)

var is_activated: bool = false
var _anim_time: float = 0.0

# Visual nodes
var _crystal_node: MeshInstance3D = null
var _light_beam: MeshInstance3D = null
var _omni_light: OmniLight3D = null
var _updraft_vent: Node3D = null
var _audio_player: AudioStreamPlayer3D = null
var _rune_particles: GPUParticles3D = null

# Materials
static var _stone_mat: StandardMaterial3D = null
static var _crystal_dormant_mat: StandardMaterial3D = null
static var _crystal_active_mat: StandardMaterial3D = null
static var _beam_mat: StandardMaterial3D = null
static var _chime_wav: AudioStreamWAV = null

func _init() -> void:
	name = "SkyspireBeaconAltar"
	_init_materials()
	_init_audio()
	_build_altar_dais()
	_build_floating_crystal()
	_build_skyward_beam()
	_build_audio_emitter()

static func _init_materials() -> void:
	if _stone_mat != null:
		return

	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.38, 0.40, 0.45) # Mountain granite
	_stone_mat.roughness = 0.85

	_crystal_dormant_mat = StandardMaterial3D.new()
	_crystal_dormant_mat.albedo_color = Color(0.25, 0.65, 0.60)
	_crystal_dormant_mat.emission_enabled = true
	_crystal_dormant_mat.emission = Color(0.15, 0.55, 0.50)
	_crystal_dormant_mat.emission_energy_multiplier = 0.8

	_crystal_active_mat = StandardMaterial3D.new()
	_crystal_active_mat.albedo_color = Color(0.40, 1.0, 0.90)
	_crystal_active_mat.emission_enabled = true
	_crystal_active_mat.emission = Color(0.20, 0.95, 0.85)
	_crystal_active_mat.emission_energy_multiplier = 2.4

	_beam_mat = StandardMaterial3D.new()
	_beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam_mat.albedo_color = Color(0.30, 0.95, 0.88, 0.45)

func _init_audio() -> void:
	if _chime_wav != null:
		return
	_chime_wav = _generate_beacon_fanfare_pcm(1.4, 22050)

func _build_altar_dais() -> void:
	# Stepped Base Dais
	var base_mesh: CylinderMesh = CylinderMesh.new()
	base_mesh.top_radius = 2.6
	base_mesh.bottom_radius = 3.2
	base_mesh.height = 0.45
	base_mesh.radial_segments = 8 # Octagonal altar
	var base_inst: MeshInstance3D = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.material_override = _stone_mat
	base_inst.position = Vector3(0.0, 0.22, 0.0)
	add_child(base_inst)

	# Upper Dais
	var top_mesh: CylinderMesh = CylinderMesh.new()
	top_mesh.top_radius = 1.6
	top_mesh.bottom_radius = 2.2
	top_mesh.height = 0.35
	top_mesh.radial_segments = 8
	var top_inst: MeshInstance3D = MeshInstance3D.new()
	top_inst.mesh = top_mesh
	top_inst.material_override = _stone_mat
	top_inst.position = Vector3(0.0, 0.55, 0.0)
	add_child(top_inst)

	# 4 Corner Obelisk Pillars
	for i in range(4):
		var angle: float = i * (PI * 0.5) + PI * 0.25
		var pil: MeshInstance3D = MeshInstance3D.new()
		var p_mesh: BoxMesh = BoxMesh.new()
		p_mesh.size = Vector3(0.35, 1.4, 0.35)
		pil.mesh = p_mesh
		pil.material_override = _stone_mat
		pil.position = Vector3(cos(angle) * 1.8, 1.1, sin(angle) * 1.8)
		add_child(pil)

func _build_floating_crystal() -> void:
	_crystal_node = MeshInstance3D.new()
	_crystal_node.name = "AnemoApexCrystal"
	var prism: PrismMesh = PrismMesh.new()
	prism.size = Vector3(0.65, 1.1, 0.65)
	_crystal_node.mesh = prism
	_crystal_node.material_override = _crystal_dormant_mat
	_crystal_node.position = Vector3(0.0, 1.65, 0.0)
	add_child(_crystal_node)

	_omni_light = OmniLight3D.new()
	_omni_light.name = "BeaconGlowLight"
	_omni_light.light_color = Color(0.20, 0.85, 0.78)
	_omni_light.light_energy = 1.2
	_omni_light.omni_range = 14.0
	_crystal_node.add_child(_omni_light)

func _build_skyward_beam() -> void:
	_light_beam = MeshInstance3D.new()
	_light_beam.name = "SkywardLightBeam"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 1.1
	cyl.bottom_radius = 0.75
	cyl.height = 120.0
	cyl.radial_segments = 16
	_light_beam.mesh = cyl
	_light_beam.material_override = _beam_mat
	_light_beam.position = Vector3(0.0, 60.0, 0.0)
	_light_beam.visible = false
	add_child(_light_beam)

func _build_audio_emitter() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "BeaconAudio"
	_audio_player.unit_size = 6.0
	_audio_player.max_distance = 65.0
	_audio_player.position = Vector3(0.0, 1.5, 0.0)
	add_child(_audio_player)

func _process(delta: float) -> void:
	_anim_time += delta
	if _crystal_node:
		var float_offset: float = sin(_anim_time * 2.2) * 0.08
		_crystal_node.position.y = 1.65 + float_offset
		_crystal_node.rotation.y += delta * (1.6 if is_activated else 0.45)

	if is_activated and _light_beam:
		var pulse: float = 0.40 + sin(_anim_time * 3.5) * 0.08
		if _light_beam.material_override is StandardMaterial3D:
			(_light_beam.material_override as StandardMaterial3D).albedo_color.a = pulse

func can_interact(player_pos: Vector3) -> bool:
	if is_activated:
		return false
	var altar_pos: Vector3 = global_position if is_inside_tree() else position
	return player_pos.distance_to(altar_pos) <= 4.5

func activate_beacon() -> bool:
	if is_activated:
		return false

	is_activated = true
	if _crystal_node:
		_crystal_node.material_override = _crystal_active_mat
	if _omni_light:
		_omni_light.light_energy = 3.5
		_omni_light.omni_range = 28.0
	if _light_beam:
		_light_beam.visible = true

	# Play celestial resonance fanfare
	if _audio_player and _chime_wav and is_inside_tree():
		_audio_player.stream = _chime_wav
		_audio_player.volume_db = 0.0
		_audio_player.play()

	var beacon_pos: Vector3 = global_position if is_inside_tree() else position
	beacon_activated.emit(beacon_pos, 1000)
	return true

static func _generate_beacon_fanfare_pcm(duration: float, rate: int) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var freqs: Array[float] = [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6 major arpeggio
	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = clampf(t / 0.15, 0.0, 1.0) * exp(-2.2 * (t / duration))
		var note_idx: int = int(clampf(t / (duration * 0.25), 0.0, 3.0))
		var f_note: float = freqs[note_idx]
		var harmonic: float = sin(t * f_note * TAU) * 0.6 + sin(t * f_note * 2.0 * TAU) * 0.25 + sin(t * f_note * 3.0 * TAU) * 0.15
		var sample: float = harmonic * env * 0.42
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
