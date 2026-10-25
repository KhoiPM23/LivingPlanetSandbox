class_name WoodlandWildlifeEcosystem
extends Node3D

## Living Planet Sandbox — RDR2-Style Woodland Wildlife Ecosystem (Block 56)
## Simulates living forest animals with realistic behaviors and procedural audio:
## 1. Red Fox (Cáo Đỏ Hoang Dã):
##    - Distinctive rust-orange coat, white throat/chest & tail tip, black paws.
##    - Realistic FSM: FORAGING, MOUSE_STALK (wiggles hips, pounces into grass), ALERT, FLEE.
##    - Procedural 16-bit PCM playful fox yip audio synthesizer.
## 2. Ground Squirrel (Sóc Đất Hạt Dẻ):
##    - Chestnut coat, upright bushy tail, quick burst hops (0.3s hop, 0.4s pause),
##    - PERISCOPE posture (stands on hind legs sniffing air), rapid dart into tree hollows.
##    - Procedural 16-bit PCM chatter chirp audio synthesizer.
## 3. Intel Iris Xe Optimized: Shared StandardMaterial3D, low-poly geometry, 60 FPS budgeted.

signal animal_spotted(species_id: String, animal_name: String, pos: Vector3)
signal predator_pounced(prey_pos: Vector3)

enum FoxState {
	FORAGING,
	STALKING,
	POUNCING,
	ALERT,
	FLEEING
}

enum SquirrelState {
	HOPPING,
	PAUSED,
	PERISCOPE,
	FLEEING
}

# Materials (Shared across all instances)
static var _fox_orange_mat: StandardMaterial3D = null
static var _fox_white_mat: StandardMaterial3D = null
static var _fox_black_mat: StandardMaterial3D = null
static var _fox_eye_mat: StandardMaterial3D = null
static var _squirrel_brown_mat: StandardMaterial3D = null
static var _squirrel_cream_mat: StandardMaterial3D = null

# Procedural Audio Streams
static var _fox_bark_wav: AudioStreamWAV = null
static var _squirrel_chirp_wav: AudioStreamWAV = null

var _foxes: Array[Dictionary] = []
var _squirrels: Array[Dictionary] = []
var _audio_player: AudioStreamPlayer3D = null
var _terrain_ref: Node = null
var _anim_time: float = 0.0

func _init() -> void:
	name = "WoodlandWildlifeEcosystem"
	_init_materials()
	_init_audio()
	_spawn_fox_pack()
	_spawn_squirrel_colony()

func setup(terrain: Node = null) -> void:
	_terrain_ref = terrain
	_clamp_all_to_terrain()

static func _init_materials() -> void:
	if _fox_orange_mat != null:
		return

	# Fox Rust Orange Fur
	_fox_orange_mat = StandardMaterial3D.new()
	_fox_orange_mat.albedo_color = Color(0.86, 0.38, 0.12)
	_fox_orange_mat.roughness = 0.85

	# Fox White Chest & Tail Tip
	_fox_white_mat = StandardMaterial3D.new()
	_fox_white_mat.albedo_color = Color(0.95, 0.94, 0.90)
	_fox_white_mat.roughness = 0.88

	# Fox Black Paws & Ear Tips
	_fox_black_mat = StandardMaterial3D.new()
	_fox_black_mat.albedo_color = Color(0.12, 0.12, 0.14)
	_fox_black_mat.roughness = 0.80

	# Fox Amber Eyes
	_fox_eye_mat = StandardMaterial3D.new()
	_fox_eye_mat.albedo_color = Color(0.95, 0.80, 0.15)
	_fox_eye_mat.roughness = 0.30

	# Squirrel Chestnut Coat
	_squirrel_brown_mat = StandardMaterial3D.new()
	_squirrel_brown_mat.albedo_color = Color(0.55, 0.32, 0.18)
	_squirrel_brown_mat.roughness = 0.85

	# Squirrel Cream Belly
	_squirrel_cream_mat = StandardMaterial3D.new()
	_squirrel_cream_mat.albedo_color = Color(0.90, 0.85, 0.75)
	_squirrel_cream_mat.roughness = 0.90

func _init_audio() -> void:
	if _fox_bark_wav == null:
		_fox_bark_wav = _generate_fox_bark_wav()
	if _squirrel_chirp_wav == null:
		_squirrel_chirp_wav = _generate_squirrel_chirp_wav()

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "WildlifeAudio"
	_audio_player.unit_size = 5.0
	_audio_player.max_distance = 25.0
	_audio_player.volume_db = -2.0
	add_child(_audio_player)

# =============================================================================
# RED FOX PACK BUILDER
# =============================================================================
func _spawn_fox_pack() -> void:
	var fox_spawns = [
		Vector3(16.0, 3.8, 10.0),   # Woodland Glade by Meadow
		Vector3(-8.0, 4.5, 20.0),   # Whispering Ridge Pine Verge
		Vector3(28.0, 3.5, -15.0)   # North Farmstead Border
	]

	for i in range(fox_spawns.size()):
		var f_pos: Vector3 = fox_spawns[i]
		var f_root = Node3D.new()
		f_root.name = "RedFox_%d" % i
		f_root.position = f_pos
		add_child(f_root)

		# 1. Torso
		var body_mesh = BoxMesh.new()
		body_mesh.size = Vector3(0.32, 0.28, 0.65)
		var b_mi = MeshInstance3D.new()
		b_mi.name = "Torso"
		b_mi.mesh = body_mesh
		b_mi.material_override = _fox_orange_mat
		b_mi.position.y = 0.32
		f_root.add_child(b_mi)

		# White Throat / Bib
		var bib_mesh = BoxMesh.new()
		bib_mesh.size = Vector3(0.24, 0.18, 0.28)
		var bib_mi = MeshInstance3D.new()
		bib_mi.mesh = bib_mesh
		bib_mi.material_override = _fox_white_mat
		bib_mi.position = Vector3(0.0, 0.26, 0.22)
		f_root.add_child(bib_mi)

		# 2. Head & Snout
		var head_root = Node3D.new()
		head_root.name = "HeadRoot"
		head_root.position = Vector3(0.0, 0.44, 0.36)
		f_root.add_child(head_root)

		var head_mesh = BoxMesh.new()
		head_mesh.size = Vector3(0.22, 0.20, 0.26)
		var h_mi = MeshInstance3D.new()
		h_mi.mesh = head_mesh
		h_mi.material_override = _fox_orange_mat
		head_root.add_child(h_mi)

		# Pointed Snout
		var snout_mesh = PrismMesh.new()
		snout_mesh.size = Vector3(0.14, 0.18, 0.12)
		var s_mi = MeshInstance3D.new()
		s_mi.mesh = snout_mesh
		s_mi.material_override = _fox_white_mat
		s_mi.position = Vector3(0.0, -0.04, 0.18)
		s_mi.rotation.x = deg_to_rad(-90.0)
		head_root.add_child(s_mi)

		# Black Nose Tip
		var nose_mesh = SphereMesh.new()
		nose_mesh.radius = 0.035
		nose_mesh.height = 0.07
		var n_mi = MeshInstance3D.new()
		n_mi.mesh = nose_mesh
		n_mi.material_override = _fox_black_mat
		n_mi.position = Vector3(0.0, -0.04, 0.27)
		head_root.add_child(n_mi)

		# Triangular Ears
		for side in [-1.0, 1.0]:
			var ear_mesh = PrismMesh.new()
			ear_mesh.size = Vector3(0.08, 0.12, 0.04)
			var e_mi = MeshInstance3D.new()
			e_mi.mesh = ear_mesh
			e_mi.material_override = _fox_black_mat
			e_mi.position = Vector3(side * 0.08, 0.14, -0.04)
			head_root.add_child(e_mi)

		# 3. Bushy Tail
		var tail_root = Node3D.new()
		tail_root.name = "TailRoot"
		tail_root.position = Vector3(0.0, 0.36, -0.32)
		f_root.add_child(tail_root)

		var tail_mesh = CylinderMesh.new()
		tail_mesh.top_radius = 0.06
		tail_mesh.bottom_radius = 0.12
		tail_mesh.height = 0.42
		var t_mi = MeshInstance3D.new()
		t_mi.mesh = tail_mesh
		t_mi.material_override = _fox_orange_mat
		t_mi.position = Vector3(0.0, 0.08, -0.18)
		t_mi.rotation.x = deg_to_rad(45.0)
		tail_root.add_child(t_mi)

		# White Tail Tip
		var tip_mesh = SphereMesh.new()
		tip_mesh.radius = 0.08
		tip_mesh.height = 0.16
		var tip_mi = MeshInstance3D.new()
		tip_mi.mesh = tip_mesh
		tip_mi.material_override = _fox_white_mat
		tip_mi.position = Vector3(0.0, 0.20, -0.30)
		tail_root.add_child(tip_mi)

		# 4. Fore and Hind Legs (Black Stockings)
		var legs: Array[MeshInstance3D] = []
		var leg_offsets = [
			Vector3(-0.11, 0.16, 0.20),
			Vector3(0.11, 0.16, 0.20),
			Vector3(-0.11, 0.16, -0.20),
			Vector3(0.11, 0.16, -0.20)
		]
		for lo in leg_offsets:
			var leg_mesh = CylinderMesh.new()
			leg_mesh.top_radius = 0.045
			leg_mesh.bottom_radius = 0.035
			leg_mesh.height = 0.32
			var l_mi = MeshInstance3D.new()
			l_mi.mesh = leg_mesh
			l_mi.material_override = _fox_black_mat
			l_mi.position = lo
			f_root.add_child(l_mi)
			legs.append(l_mi)

		_foxes.append({
			"id": "fox_%d" % i,
			"root": f_root,
			"head": head_root,
			"tail": tail_root,
			"legs": legs,
			"state": FoxState.FORAGING,
			"state_timer": randf_range(3.0, 6.0),
			"base_pos": f_pos,
			"curr_pos": f_pos,
			"target_pos": f_pos + Vector3(2.5, 0.0, 2.5),
			"stalk_timer": 0.0,
			"stalk_wobble": 0.0,
			"move_speed": 1.4,
			"alert_timer": 0.0
		})

# =============================================================================
# GROUND SQUIRREL COLONY BUILDER
# =============================================================================
func _spawn_squirrel_colony() -> void:
	var sq_spawns = [
		Vector3(10.5, 3.8, 8.5),    # Near Birch Grove Log
		Vector3(14.0, 3.8, 14.0),   # Campsite Perimeter
		Vector3(-4.0, 4.2, 16.0),   # Whispering Ridge Boulder
		Vector3(20.0, 3.6, 2.0)     # Meadow Forest Verge
	]

	for i in range(sq_spawns.size()):
		var s_pos: Vector3 = sq_spawns[i]
		var sq_root = Node3D.new()
		sq_root.name = "GroundSquirrel_%d" % i
		sq_root.position = s_pos
		add_child(sq_root)

		# 1. Compact Torso
		var body = SphereMesh.new()
		body.radius = 0.10
		body.height = 0.22
		var b_mi = MeshInstance3D.new()
		b_mi.mesh = body
		b_mi.material_override = _squirrel_brown_mat
		b_mi.position.y = 0.12
		sq_root.add_child(b_mi)

		# Cream Chest
		var chest = SphereMesh.new()
		chest.radius = 0.08
		chest.height = 0.16
		var c_mi = MeshInstance3D.new()
		c_mi.mesh = chest
		c_mi.material_override = _squirrel_cream_mat
		c_mi.position = Vector3(0.0, 0.11, 0.05)
		sq_root.add_child(c_mi)

		# 2. Head
		var head = SphereMesh.new()
		head.radius = 0.08
		head.height = 0.14
		var h_mi = MeshInstance3D.new()
		h_mi.name = "SquirrelHead"
		h_mi.mesh = head
		h_mi.material_override = _squirrel_brown_mat
		h_mi.position = Vector3(0.0, 0.20, 0.08)
		sq_root.add_child(h_mi)

		# 3. Upright Bushy Tail
		var tail_root = Node3D.new()
		tail_root.name = "SquirrelTail"
		tail_root.position = Vector3(0.0, 0.12, -0.08)
		sq_root.add_child(tail_root)

		var tail_mesh = CylinderMesh.new()
		tail_mesh.top_radius = 0.08
		tail_mesh.bottom_radius = 0.03
		tail_mesh.height = 0.24
		var t_mi = MeshInstance3D.new()
		t_mi.mesh = tail_mesh
		t_mi.material_override = _squirrel_brown_mat
		t_mi.position = Vector3(0.0, 0.12, -0.04)
		t_mi.rotation.x = deg_to_rad(-35.0)
		tail_root.add_child(t_mi)

		_squirrels.append({
			"id": "squirrel_%d" % i,
			"root": sq_root,
			"head": h_mi,
			"tail": tail_root,
			"state": SquirrelState.HOPPING,
			"state_timer": randf_range(1.5, 3.0),
			"base_pos": s_pos,
			"curr_pos": s_pos,
			"target_pos": s_pos + Vector3(1.5, 0.0, 1.5),
			"hop_phase": 0.0,
			"periscope_yaw": 0.0
		})

# =============================================================================
# UPDATE BEHAVIOR & FSM TICKS
# =============================================================================
func update_behavior(delta: float, player_pos: Vector3, player_speed: float = 0.0) -> void:
	_anim_time += delta
	_update_fox_fsm(delta, player_pos, player_speed)
	_update_squirrel_fsm(delta, player_pos, player_speed)

func _update_fox_fsm(delta: float, player_pos: Vector3, player_speed: float) -> void:
	for fox in _foxes:
		var root: Node3D = fox["root"]
		var curr: Vector3 = fox["curr_pos"]
		var dist_to_player: float = curr.distance_to(player_pos)

		fox["state_timer"] -= delta

		# Player proximity alert / flee check
		if dist_to_player < 5.0 and player_speed > 3.0:
			fox["state"] = FoxState.FLEEING
			fox["state_timer"] = 3.5
			# Flee opposite to player direction
			var flee_dir: Vector3 = (curr - player_pos).normalized()
			flee_dir.y = 0.0
			fox["target_pos"] = curr + flee_dir * 12.0
		elif dist_to_player < 8.0 and fox["state"] != FoxState.FLEEING and fox["state"] != FoxState.ALERT:
			fox["state"] = FoxState.ALERT
			fox["state_timer"] = 2.5
			_play_fox_sound(curr)
			animal_spotted.emit(fox["id"], "Cáo Đỏ Rừng Sâu", curr)

		match fox["state"]:
			FoxState.FORAGING:
				if fox["state_timer"] <= 0.0:
					# 35% chance to transition to mouse stalking
					if randf() < 0.35:
						fox["state"] = FoxState.STALKING
						fox["state_timer"] = randf_range(2.5, 4.0)
						fox["stalk_timer"] = 0.0
					else:
						# Pick new foraging point within 8m of home
						var offset = Vector3(randf_range(-6.0, 6.0), 0.0, randf_range(-6.0, 6.0))
						fox["target_pos"] = fox["base_pos"] + offset
						fox["state_timer"] = randf_range(3.5, 6.0)

				# Trot towards target
				var move_vec = fox["target_pos"] - curr
				move_vec.y = 0.0
				if move_vec.length() <= 0.4:
					var offset = Vector3(randf_range(-6.0, 6.0), 0.0, randf_range(-6.0, 6.0))
					if offset.length() < 1.0:
						offset = Vector3(2.5, 0.0, 2.5)
					fox["target_pos"] = fox["base_pos"] + offset
					move_vec = fox["target_pos"] - curr
					move_vec.y = 0.0

				if move_vec.length() > 0.4:
					var dir = move_vec.normalized()
					curr += dir * fox["move_speed"] * delta
					root.rotation.y = lerp_angle(root.rotation.y, atan2(dir.x, dir.z), delta * 5.0)
					# Gentle tail wag
					fox["tail"].rotation.y = sin(_anim_time * 6.0) * 0.25

			FoxState.STALKING:
				# Freeze and wiggle hips before pouncing
				fox["stalk_timer"] += delta
				fox["stalk_wobble"] = sin(fox["stalk_timer"] * 16.0) * 0.18
				fox["tail"].rotation.z = fox["stalk_wobble"]
				fox["head"].rotation.x = deg_to_rad(15.0) # Lower snout to grass
				if fox["state_timer"] <= 0.0:
					fox["state"] = FoxState.POUNCING
					fox["state_timer"] = 0.8

			FoxState.POUNCING:
				# High dramatic parabolic pounce arc into grass
				var pounce_t: float = 1.0 - (fox["state_timer"] / 0.8)
				var pounce_h: float = sin(pounce_t * PI) * 0.85
				curr.y = _get_terrain_y(curr.x, curr.z) + pounce_h
				if pounce_t > 0.85 and fox["state_timer"] <= 0.1:
					predator_pounced.emit(curr)
				if fox["state_timer"] <= 0.0:
					fox["state"] = FoxState.FORAGING
					fox["state_timer"] = randf_range(4.0, 7.0)

			FoxState.ALERT:
				# Face player curiosity
				var p_dir = (player_pos - curr).normalized()
				p_dir.y = 0.0
				if p_dir.length_squared() > 0.01:
					root.rotation.y = lerp_angle(root.rotation.y, atan2(p_dir.x, p_dir.z), delta * 6.0)
				fox["head"].rotation.x = deg_to_rad(-8.0) # Perked up ears
				if fox["state_timer"] <= 0.0:
					fox["state"] = FoxState.FORAGING
					fox["state_timer"] = 3.0

			FoxState.FLEEING:
				# Sprint away swiftly
				var flee_vec = fox["target_pos"] - curr
				flee_vec.y = 0.0
				if flee_vec.length() > 0.3:
					var dir = flee_vec.normalized()
					curr += dir * 6.2 * delta
					root.rotation.y = lerp_angle(root.rotation.y, atan2(dir.x, dir.z), delta * 8.0)
				if fox["state_timer"] <= 0.0:
					fox["state"] = FoxState.FORAGING
					fox["base_pos"] = curr
					fox["state_timer"] = 4.0

		if fox["state"] != FoxState.POUNCING:
			curr.y = _get_terrain_y(curr.x, curr.z)
		fox["curr_pos"] = curr
		root.position = curr

func _update_squirrel_fsm(delta: float, player_pos: Vector3, player_speed: float) -> void:
	for sq in _squirrels:
		var root: Node3D = sq["root"]
		var curr: Vector3 = sq["curr_pos"]
		var dist_to_player: float = curr.distance_to(player_pos)

		sq["state_timer"] -= delta

		if dist_to_player < 4.5 and player_speed > 2.0:
			sq["state"] = SquirrelState.FLEEING
			sq["state_timer"] = 2.0
			var f_dir = (curr - player_pos).normalized()
			f_dir.y = 0.0
			sq["target_pos"] = curr + f_dir * 8.0
			_play_squirrel_sound(curr)

		match sq["state"]:
			SquirrelState.HOPPING:
				sq["hop_phase"] += delta * 12.0
				var hop_y: float = abs(sin(sq["hop_phase"])) * 0.16
				var m_dir = (sq["target_pos"] - curr).normalized()
				m_dir.y = 0.0
				curr += m_dir * 2.8 * delta
				curr.y = _get_terrain_y(curr.x, curr.z) + hop_y
				root.rotation.y = atan2(m_dir.x, m_dir.z) if m_dir.length_squared() > 0.01 else root.rotation.y
				if sq["state_timer"] <= 0.0 or curr.distance_to(sq["target_pos"]) < 0.3:
					sq["state"] = SquirrelState.PAUSED if randf() < 0.6 else SquirrelState.PERISCOPE
					sq["state_timer"] = randf_range(1.2, 2.5)

			SquirrelState.PAUSED:
				curr.y = _get_terrain_y(curr.x, curr.z)
				sq["tail"].rotation.x = deg_to_rad(-35.0) + sin(_anim_time * 8.0) * 0.15
				if sq["state_timer"] <= 0.0:
					sq["state"] = SquirrelState.HOPPING
					var off = Vector3(randf_range(-3.5, 3.5), 0.0, randf_range(-3.5, 3.5))
					sq["target_pos"] = sq["base_pos"] + off
					sq["state_timer"] = randf_range(1.5, 3.0)

			SquirrelState.PERISCOPE:
				# Stand upright on hind legs and look around
				curr.y = _get_terrain_y(curr.x, curr.z)
				root.rotation.x = deg_to_rad(-25.0)
				sq["tail"].rotation.x = deg_to_rad(-55.0)
				if sq["state_timer"] <= 0.0:
					root.rotation.x = 0.0
					sq["state"] = SquirrelState.HOPPING
					sq["state_timer"] = 2.0

			SquirrelState.FLEEING:
				# Rapid darting dash
				var dart_dir = (sq["target_pos"] - curr).normalized()
				dart_dir.y = 0.0
				curr += dart_dir * 5.2 * delta
				curr.y = _get_terrain_y(curr.x, curr.z) + abs(sin(_anim_time * 20.0)) * 0.12
				root.rotation.y = atan2(dart_dir.x, dart_dir.z) if dart_dir.length_squared() > 0.01 else root.rotation.y
				if sq["state_timer"] <= 0.0:
					sq["state"] = SquirrelState.PAUSED
					sq["base_pos"] = curr
					sq["state_timer"] = 1.5

		sq["curr_pos"] = curr
		root.position = curr

func _get_terrain_y(x: float, z: float) -> float:
	if _terrain_ref and _terrain_ref.has_method("get_height_at"):
		return _terrain_ref.get_height_at(x, z)
	return 3.8

func _clamp_all_to_terrain() -> void:
	for f in _foxes:
		f["curr_pos"].y = _get_terrain_y(f["curr_pos"].x, f["curr_pos"].z)
		f["root"].position = f["curr_pos"]
	for s in _squirrels:
		s["curr_pos"].y = _get_terrain_y(s["curr_pos"].x, s["curr_pos"].z)
		s["root"].position = s["curr_pos"]

func _play_fox_sound(pos: Vector3) -> void:
	if _audio_player and is_inside_tree() and not _audio_player.playing:
		_audio_player.global_position = pos
		_audio_player.stream = _fox_bark_wav
		_audio_player.play()

func _play_squirrel_sound(pos: Vector3) -> void:
	if _audio_player and is_inside_tree() and not _audio_player.playing:
		_audio_player.global_position = pos
		_audio_player.stream = _squirrel_chirp_wav
		_audio_player.play()

# =============================================================================
# PROCEDURAL 16-BIT PCM WAVE SYNTHESIZERS
# =============================================================================
func _generate_fox_bark_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.28
	var num_samples: int = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		# Short playful pitch sweep 650Hz -> 1150Hz -> 850Hz
		var freq: float = 650.0 + sin(t * PI / duration) * 500.0
		var env: float = sin(t * PI / duration)
		var val: float = sin(TAU * freq * t) * 0.7 + sin(TAU * freq * 2.0 * t) * 0.2
		var sample_val: int = int(clampf(val * env * 0.55, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

func _generate_squirrel_chirp_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.18
	var num_samples: int = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		# Rapid high-frequency chatter chirp 2200Hz - 2800Hz
		var freq: float = 2200.0 + sin(t * 75.0) * 600.0
		var env: float = sin(t * PI / duration)
		var val: float = sin(TAU * freq * t)
		var sample_val: int = int(clampf(val * env * 0.45, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

func get_fox_count() -> int:
	return _foxes.size()

func get_squirrel_count() -> int:
	return _squirrels.size()
