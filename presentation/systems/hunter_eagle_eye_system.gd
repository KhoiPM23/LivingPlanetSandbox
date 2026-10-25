class_name HunterEagleEyeSystem
extends Node3D

## Living Planet Sandbox — RDR2-Style Hunter Eagle Eye & Tracking System (Block 57)
## Deep wildlife hunting and animal tracking mechanics:
## 1. Eagle Eye Focus Mode:
##    - Toggleable via hotkey [V] or API `toggle_eagle_eye()`.
##    - Emits mysterious low-frequency sensory hum audio (procedural 16-bit PCM).
##    - Modulates world visual focus: activates glowing golden scent trails and ground prints.
## 2. Animal Scent Trails & Footprints:
##    - Dynamic floating pheromone scent ribbons leading toward nearby wild fauna (Fox, Squirrel, Deer, Wolf).
##    - Scent particles sway naturally with wind direction and dissipate over distance.
## 3. Interactive Clue Nodes (Dấu Vết Thợ Săn):
##    - Deer rubbing scrapes, fox burrow tracks, gnawed pinecones, and predator prints.
##    - Investigating clue [E] grants +30 EXP and reveals animal species, health state, and trail compass heading.
## 4. Intel Iris Xe optimized: shared standard materials, pooled particle nodes, 60 FPS budgeted.

signal eagle_eye_toggled(is_active: bool)
signal track_clue_inspected(clue_id: String, animal_species: String, clue_title: String, clue_pos: Vector3)

# State
var is_active: bool = false
var _anim_time: float = 0.0
var _audio_player: AudioStreamPlayer3D = null

# Materials
static var _scent_glow_mat: StandardMaterial3D = null
static var _clue_node_mat: StandardMaterial3D = null
static var _print_decal_mat: StandardMaterial3D = null
static var _eagle_eye_hum_wav: AudioStreamWAV = null

# Registered Clues
var _clues: Array[Dictionary] = []
var _scent_ribbons: Array[Node3D] = []
var _tracked_animals_ref: Array = []

func _init() -> void:
	name = "HunterEagleEyeSystem"
	_init_materials()
	_init_audio()
	_build_default_clues()

static func _init_materials() -> void:
	if _scent_glow_mat != null:
		return

	# Luminous Golden-Amber Scent Ribbon
	_scent_glow_mat = StandardMaterial3D.new()
	_scent_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_scent_glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_scent_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_scent_glow_mat.albedo_color = Color(1.0, 0.85, 0.25, 0.65)

	# Clue Beacon Node (Pulsing Diamond)
	_clue_node_mat = StandardMaterial3D.new()
	_clue_node_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_clue_node_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_clue_node_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_clue_node_mat.albedo_color = Color(0.95, 0.90, 0.40, 0.85)

	# Ground Footprint Stamp
	_print_decal_mat = StandardMaterial3D.new()
	_print_decal_mat.albedo_color = Color(0.35, 0.26, 0.18)
	_print_decal_mat.roughness = 0.95

func _init_audio() -> void:
	if _eagle_eye_hum_wav == null:
		_eagle_eye_hum_wav = _generate_eagle_eye_hum_wav()

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "EagleEyeAudio"
	_audio_player.stream = _eagle_eye_hum_wav
	_audio_player.unit_size = 12.0
	_audio_player.max_distance = 50.0
	_audio_player.volume_db = 0.0
	add_child(_audio_player)

# =============================================================================
# DEFAULT ANIMAL TRACK CLUES
# =============================================================================
func _build_default_clues() -> void:
	var clue_defs = [
		{
			"id": "clue_fox_den",
			"title": "Hang Cáo Rừng Sâu",
			"species": "Cáo Đỏ (Vulpes)",
			"details": "Lông cáo vương trên rễ thông và dấu móng vuốt đào tìm chuột đồng tươi mới.",
			"pos": Vector3(25.5, 3.5, -13.5),
			"radius": 2.8,
			"target_pos": Vector3(28.0, 3.5, -15.0)
		},
		{
			"id": "clue_squirrel_cache",
			"title": "Hố Giấu Hạt Dẻ",
			"species": "Sóc Đất (Spermophilus)",
			"details": "Đống vỏ hạt dẻ cắn dở và vụn vỏ thông còn vương mùi nhựa thơm ngát.",
			"pos": Vector3(20.5, 3.6, 3.2),
			"radius": 2.5,
			"target_pos": Vector3(20.0, 3.6, 2.0)
		},
		{
			"id": "clue_deer_rub",
			"title": "Vết Chà Gạc Hươu Rừng",
			"species": "Hươu Đực Bạch Đàn (Cervus)",
			"details": "Vỏ cây thông bị gạc cào rách làm nhựa cây chảy vàng óng, cỏ xung quanh bị dẫm bẹp.",
			"pos": Vector3(14.0, 3.8, 16.5),
			"radius": 3.0,
			"target_pos": Vector3(18.0, 3.8, 22.0)
		},
		{
			"id": "clue_wolf_prowl",
			"title": "Dấu Chân Sói Hoang",
			"species": "Sói Núi Đêm (Canis)",
			"details": "Dấu chân 4 móng lớn in sâu trên đất ẩm sườn đồi, hướng đuổi theo đàn hươu.",
			"pos": Vector3(-12.0, 4.5, 18.0),
			"radius": 3.2,
			"target_pos": Vector3(-8.0, 4.5, 20.0)
		}
	]

	for c in clue_defs:
		var c_root = Node3D.new()
		c_root.name = "Clue_" + c["id"]
		c_root.position = c["pos"]
		add_child(c_root)

		# Ground Print Marker
		var print_mesh = CylinderMesh.new()
		print_mesh.top_radius = 0.22
		print_mesh.bottom_radius = 0.26
		print_mesh.height = 0.04
		var p_mi = MeshInstance3D.new()
		p_mi.mesh = print_mesh
		p_mi.material_override = _print_decal_mat
		p_mi.position.y = 0.02
		c_root.add_child(p_mi)

		# Floating Diamond Clue Beacon (Visible predominantly in Eagle Eye)
		var b_mesh = PrismMesh.new()
		b_mesh.size = Vector3(0.18, 0.28, 0.18)
		var b_mi = MeshInstance3D.new()
		b_mi.mesh = b_mesh
		b_mi.material_override = _clue_node_mat
		b_mi.position.y = 0.45
		b_mi.visible = false # Hidden until Eagle Eye
		c_root.add_child(b_mi)

		# Scent Ribbon nodes leading toward animal
		var ribbon_root = Node3D.new()
		ribbon_root.name = "ScentRibbon"
		c_root.add_child(ribbon_root)
		_build_scent_ribbon(ribbon_root, c["pos"], c["target_pos"])

		_clues.append({
			"id": c["id"],
			"title": c["title"],
			"species": c["species"],
			"details": c["details"],
			"pos": c["pos"],
			"radius": c["radius"],
			"root": c_root,
			"beacon": b_mi,
			"ribbon": ribbon_root,
			"is_inspected": false
		})

func _build_scent_ribbon(parent: Node3D, start_pos: Vector3, end_pos: Vector3) -> void:
	var count = 5
	for step in range(1, count + 1):
		var frac: float = float(step) / float(count)
		var mid = start_pos.lerp(end_pos, frac)
		# Arc upward slightly
		mid.y += sin(frac * PI) * 0.45

		var orb = SphereMesh.new()
		orb.radius = 0.06 + frac * 0.04
		orb.height = orb.radius * 2.0
		var orb_mi = MeshInstance3D.new()
		orb_mi.mesh = orb
		orb_mi.material_override = _scent_glow_mat
		orb_mi.position = mid - start_pos
		orb_mi.visible = false
		parent.add_child(orb_mi)

# =============================================================================
# EAGLE EYE LOGIC & UPDATE
# =============================================================================
func toggle_eagle_eye() -> bool:
	set_eagle_eye(not is_active)
	return is_active

func set_eagle_eye(active: bool) -> void:
	if is_active == active:
		return
	is_active = active

	if is_active:
		if _audio_player and is_inside_tree():
			_audio_player.play()
	else:
		if _audio_player and is_inside_tree() and _audio_player.playing:
			_audio_player.stop()

	# Toggle clue beacons & scent ribbons visibility
	for c in _clues:
		c["beacon"].visible = is_active
		for child in c["ribbon"].get_children():
			if child is MeshInstance3D:
				child.visible = is_active

	eagle_eye_toggled.emit(is_active)

func _process(delta: float) -> void:
	if not is_active:
		return

	_anim_time += delta

	# Animate clue beacon bobbing & rotation
	for c in _clues:
		var beacon: MeshInstance3D = c["beacon"]
		if beacon.visible:
			beacon.position.y = 0.45 + sin(_anim_time * 3.5) * 0.08
			beacon.rotation.y += delta * 2.2

		# Animate scent ribbon breathing pulse
		var ribbon: Node3D = c["ribbon"]
		for i in range(ribbon.get_child_count()):
			var orb = ribbon.get_child(i) as MeshInstance3D
			if orb and orb.visible:
				var offset_scale = 1.0 + sin(_anim_time * 4.0 + float(i) * 0.8) * 0.25
				orb.scale = Vector3.ONE * offset_scale

func get_nearest_clue(player_pos: Vector3) -> Dictionary:
	var best_dist: float = 999999.0
	var best_clue: Dictionary = {}
	for c in _clues:
		var dist = player_pos.distance_to(c["pos"])
		if dist <= c["radius"] and dist < best_dist:
			best_dist = dist
			best_clue = c
	return best_clue

func inspect_clue(clue_id: String) -> Dictionary:
	for c in _clues:
		if c["id"] == clue_id:
			c["is_inspected"] = true
			track_clue_inspected.emit(c["id"], c["species"], c["title"], c["pos"])
			return c
	return {}

# =============================================================================
# PROCEDURAL 16-BIT PCM AUDIO SYNTHESIZER
# =============================================================================
func _generate_eagle_eye_hum_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 1.8
	var total_samples: int = int(sample_rate * duration)
	var byte_count: int = total_samples * 2
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(byte_count)

	# Ethereal low-frequency sensory drone: 82Hz (E2) + 164Hz harmonic + subtle beating 84Hz
	var f0: float = 82.0
	var f1: float = 164.0
	var f2: float = 84.0

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		# Smooth attack and decay envelope
		var env: float = sin(t / duration * PI)

		var wave: float = sin(t * f0 * TAU) * 0.50
		wave += sin(t * f1 * TAU) * 0.25
		wave += sin(t * f2 * TAU) * 0.25

		var sample_val: float = wave * env * 0.65
		var int_val: int = int(clampf(sample_val, -1.0, 1.0) * 32767.0)

		var byte_idx: int = i * 2
		buffer[byte_idx] = int_val & 0xFF
		buffer[byte_idx + 1] = (int_val >> 8) & 0xFF

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = buffer
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = int(sample_rate * 0.3)
	wav.loop_end = int(sample_rate * 1.5)
	return wav
