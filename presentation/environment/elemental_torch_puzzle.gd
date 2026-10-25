class_name ElementalTorchPuzzle
extends Node3D

## Living Planet Sandbox — Genshin-Style Elemental Pyro Torch Puzzle (Block 56)
## Timed elemental environmental brazier puzzle:
## 1. 4 carved stone braziers arranged in a diamond constellation (North, East, South, West).
## 2. Striking brazier with weapon or pressing [E] ignites tall flame & orange thermal light.
## 3. 15.0-second challenge timer: Lighting all 4 torches solves the puzzle.
## 4. Spawns an Exquisite Elemental Chest in the center with ascending particle pillar.
## 5. Procedural 16-bit PCM fire whoosh ignition & triumphant harmonic chime audio.
## 6. Intel Iris Xe optimized: shared standard materials, 60 FPS budgeted.

signal torch_lit(torch_index: int, total_lit: int)
signal puzzle_solved(chest_pos: Vector3)
signal puzzle_chest_opened(reward: Dictionary)

const PUZZLE_TIME_LIMIT: float = 15.0

var _torches: Array[Dictionary] = []
var _is_puzzle_solved: bool = false
var _puzzle_timer: float = 0.0
var _chest_root: Node3D = null
var _chest_lid: Node3D = null
var _chest_opened: bool = false
var _audio_player: AudioStreamPlayer3D = null

# Materials
static var _stone_mat: StandardMaterial3D = null
static var _iron_mat: StandardMaterial3D = null
static var _fire_mat: StandardMaterial3D = null
static var _ember_mat: StandardMaterial3D = null
static var _chest_mat: StandardMaterial3D = null

# Procedural Audio
static var _ignite_wav: AudioStreamWAV = null
static var _solve_wav: AudioStreamWAV = null

func _init() -> void:
	name = "ElementalTorchPuzzle"
	_init_materials()
	_init_audio()
	_build_braziers()
	_build_exquisite_chest()

static func _init_materials() -> void:
	if _stone_mat != null:
		return

	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.45, 0.43, 0.40)
	_stone_mat.roughness = 0.90

	_iron_mat = StandardMaterial3D.new()
	_iron_mat.albedo_color = Color(0.18, 0.18, 0.20)
	_iron_mat.metallic = 0.85
	_iron_mat.roughness = 0.40

	# Radiant Pyro Flame
	_fire_mat = StandardMaterial3D.new()
	_fire_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fire_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fire_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fire_mat.albedo_color = Color(1.0, 0.48, 0.12, 0.85)

	# Charcoal Embers
	_ember_mat = StandardMaterial3D.new()
	_ember_mat.albedo_color = Color(0.15, 0.15, 0.15)
	_ember_mat.roughness = 0.95

	# Exquisite Chest Lacquer & Brass
	_chest_mat = StandardMaterial3D.new()
	_chest_mat.albedo_color = Color(0.24, 0.48, 0.65) # Azure lacquer
	_chest_mat.metallic = 0.45
	_chest_mat.roughness = 0.45

func _init_audio() -> void:
	if _ignite_wav == null:
		_ignite_wav = _generate_ignite_wav()
	if _solve_wav == null:
		_solve_wav = _generate_solve_wav()

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "TorchPuzzleAudio"
	_audio_player.stream = _ignite_wav
	_audio_player.unit_size = 6.0
	_audio_player.max_distance = 30.0
	_audio_player.volume_db = -1.0
	add_child(_audio_player)

# =============================================================================
# BRAZIER DIAMOND CONSTELLATION BUILDER
# =============================================================================
func _build_braziers() -> void:
	var offsets = [
		Vector3(0.0, 0.0, -3.6),  # 0: North
		Vector3(3.6, 0.0, 0.0),   # 1: East
		Vector3(0.0, 0.0, 3.6),   # 2: South
		Vector3(-3.6, 0.0, 0.0)   # 3: West
	]

	for i in range(offsets.size()):
		var off: Vector3 = offsets[i]
		var b_root = Node3D.new()
		b_root.name = "Brazier_%d" % i
		b_root.position = off
		add_child(b_root)

		# 1. Carved Stone Pedestal
		var ped_mesh = CylinderMesh.new()
		ped_mesh.top_radius = 0.32
		ped_mesh.bottom_radius = 0.42
		ped_mesh.height = 0.90
		var ped_mi = MeshInstance3D.new()
		ped_mi.mesh = ped_mesh
		ped_mi.material_override = _stone_mat
		ped_mi.position.y = 0.45
		b_root.add_child(ped_mi)

		# 2. Iron Dish Bowl
		var dish_mesh = CylinderMesh.new()
		dish_mesh.top_radius = 0.48
		dish_mesh.bottom_radius = 0.28
		dish_mesh.height = 0.25
		var dish_mi = MeshInstance3D.new()
		dish_mi.mesh = dish_mesh
		dish_mi.material_override = _iron_mat
		dish_mi.position.y = 0.98
		b_root.add_child(dish_mi)

		# 3. Flame Mesh (Initially invisible)
		var flame_root = Node3D.new()
		flame_root.name = "FlameRoot"
		flame_root.position.y = 1.15
		flame_root.visible = false
		b_root.add_child(flame_root)

		var flame_mesh = PrismMesh.new()
		flame_mesh.size = Vector3(0.36, 0.75, 0.36)
		var f_mi = MeshInstance3D.new()
		f_mi.mesh = flame_mesh
		f_mi.material_override = _fire_mat
		f_mi.position.y = 0.35
		flame_root.add_child(f_mi)

		# Fire OmniLight
		var f_light = OmniLight3D.new()
		f_light.light_color = Color(1.0, 0.55, 0.15)
		f_light.light_energy = 2.4
		f_light.omni_range = 8.0
		flame_root.add_child(f_light)

		_torches.append({
			"index": i,
			"root": b_root,
			"flame": flame_root,
			"light": f_light,
			"lit": false,
			"pos": off
		})

# =============================================================================
# EXQUISITE CHEST BUILDER
# =============================================================================
func _build_exquisite_chest() -> void:
	_chest_root = Node3D.new()
	_chest_root.name = "PuzzleExquisiteChest"
	_chest_root.position = Vector3(0.0, 0.0, 0.0)
	_chest_root.visible = false
	add_child(_chest_root)

	# Stone Plinth
	var plinth = CylinderMesh.new()
	plinth.top_radius = 0.75
	plinth.bottom_radius = 0.85
	plinth.height = 0.20
	var p_mi = MeshInstance3D.new()
	p_mi.mesh = plinth
	p_mi.material_override = _stone_mat
	p_mi.position.y = 0.10
	_chest_root.add_child(p_mi)

	# Chest Body
	var body = BoxMesh.new()
	body.size = Vector3(0.85, 0.44, 0.56)
	var b_mi = MeshInstance3D.new()
	b_mi.mesh = body
	b_mi.material_override = _chest_mat
	b_mi.position.y = 0.42
	_chest_root.add_child(b_mi)

	# Hinged Lid
	_chest_lid = Node3D.new()
	_chest_lid.name = "ChestLid"
	_chest_lid.position = Vector3(0.0, 0.64, -0.28)
	_chest_root.add_child(_chest_lid)

	var lid = BoxMesh.new()
	lid.size = Vector3(0.88, 0.22, 0.58)
	var l_mi = MeshInstance3D.new()
	l_mi.mesh = lid
	l_mi.material_override = _chest_mat
	l_mi.position = Vector3(0.0, 0.11, 0.28)
	_chest_lid.add_child(l_mi)

func _process(delta: float) -> void:
	if _is_puzzle_solved:
		return

	# Handle 15s timer when at least one torch is lit
	if _puzzle_timer > 0.0:
		_puzzle_timer -= delta
		if _puzzle_timer <= 0.0:
			_extinguish_all_torches()

func ignite_torch(index: int) -> bool:
	if _is_puzzle_solved:
		return false
	if index < 0 or index >= _torches.size():
		return false

	var torch = _torches[index]
	if torch["lit"]:
		return false # Already lit

	torch["lit"] = true
	torch["flame"].visible = true

	# Start or refresh 15s timer
	_puzzle_timer = PUZZLE_TIME_LIMIT

	# Play ignite whoosh sound
	if _audio_player and is_inside_tree():
		_audio_player.global_position = torch["root"].global_position
		_audio_player.stream = _ignite_wav
		_audio_player.play()

	var total_lit: int = get_lit_count()
	torch_lit.emit(index, total_lit)
	print("[ElementalTorchPuzzle] Torch %d ignited! (Total Lit: %d/4, Time Remaining: %.1fs)" % [
		index, total_lit, _puzzle_timer
	])

	# Check puzzle victory condition
	if total_lit == _torches.size():
		_solve_puzzle()

	return true

func _solve_puzzle() -> void:
	_is_puzzle_solved = true
	_puzzle_timer = 0.0
	if _chest_root:
		_chest_root.visible = true

	if _audio_player and is_inside_tree():
		_audio_player.global_position = global_position
		_audio_player.stream = _solve_wav
		_audio_player.play()

	var c_pos: Vector3 = global_position if is_inside_tree() else position
	puzzle_solved.emit(c_pos)
	print("[ElementalTorchPuzzle] ALL 4 TORCHES IGNITED! Exquisite Chest revealed at %s" % str(c_pos))

func _extinguish_all_torches() -> void:
	for t in _torches:
		t["lit"] = false
		t["flame"].visible = false
	_puzzle_timer = 0.0
	print("[ElementalTorchPuzzle] Time expired! All torches extinguished. Try again.")

func open_puzzle_chest() -> Dictionary:
	if not _is_puzzle_solved or _chest_opened:
		return {}

	_chest_opened = true
	if _chest_lid:
		_chest_lid.rotation.x = deg_to_rad(-85.0)

	var reward = {
		"exp": 220,
		"coins": 75,
		"item": "fire_crystal",
		"item_title": "Pha Lê Hỏa Viêm Cổ Đại"
	}
	puzzle_chest_opened.emit(reward)
	print("[ElementalTorchPuzzle] Opened Exquisite Puzzle Chest -> Reward: %s" % str(reward))
	return reward

func get_nearby_interactable(player_pos: Vector3, max_dist: float = 2.8) -> Dictionary:
	var base: Vector3 = global_position if is_inside_tree() else position

	# Check for unopened solved chest
	if _is_puzzle_solved and not _chest_opened:
		if player_pos.distance_to(base) <= max_dist:
			return {
				"id": "torch_puzzle_chest",
				"type": "chest",
				"name": "Rương Tinh Xảo Nguyên Tố Hỏa",
				"icon": "📦",
				"pos": base
			}

	# Check individual unlit torches
	if not _is_puzzle_solved:
		for t in _torches:
			var t_pos = base + t["pos"]
			if not t["lit"] and player_pos.distance_to(t_pos) <= max_dist:
				return {
					"id": "torch_%d" % t["index"],
					"type": "torch",
					"index": t["index"],
					"name": "Đài Đốt Lửa Cổ #%d [E/Đánh Kiếm]" % (t["index"] + 1),
					"icon": "🔥",
					"pos": t_pos
				}

	return {}

func get_lit_count() -> int:
	var count: int = 0
	for t in _torches:
		if t["lit"]:
			count += 1
	return count

# =============================================================================
# PROCEDURAL 16-BIT PCM AUDIO SYNTHESIZERS
# =============================================================================
func _generate_ignite_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.45
	var num_samples: int = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		# Rapid low roar + pitch sweep 120Hz -> 480Hz
		var freq: float = 120.0 + (t / duration) * 360.0
		var noise: float = randf_range(-0.5, 0.5)
		var env: float = sin(t * PI / duration)
		var val: float = (sin(TAU * freq * t) * 0.6 + noise * 0.4) * env
		var sample_val: int = int(clampf(val * 0.70, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

func _generate_solve_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 1.2
	var num_samples: int = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)

	# Harmonic major triad fanfare (C5 -> E5 -> G5 -> C6)
	var notes = [523.25, 659.25, 783.99, 1046.50]
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var seg: int = int(t / 0.25)
		var n_idx = mini(seg, notes.size() - 1)
		var freq: float = notes[n_idx]
		var sub_t: float = fmod(t, 0.25)
		var env: float = exp(-sub_t * 6.0) if seg < 3 else exp(-(t - 0.75) * 2.5)
		var val: float = sin(TAU * freq * t) * env * 0.65
		var sample_val: int = int(clampf(val, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream
