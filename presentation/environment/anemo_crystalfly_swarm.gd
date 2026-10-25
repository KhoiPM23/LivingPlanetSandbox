class_name AnemoCrystalflySwarm
extends Node3D

## Living Planet Sandbox — Genshin-Style Anemo Crystalfly Swarm (Block 55)
## Features:
## 1. 7 Luminous Anemo Crystalflies fluttering near sacred ancient trees, Heart Island, and the Wind Guardian Statue.
## 2. 4 Faceted crystalline diamond wings with unshaded additive bioluminescent glow (turquoise & gold).
## 3. High-frequency wing fluttering animation (sin(t * 18.0) * 0.45 rad) and gentle wandering orbits.
## 4. Interactive Capture: [E] Bắt Tinh Điệp Phong (+30 EXP, crystal_core ingredient).
## 5. Panic scatter: fast-sprinting players startle crystalflies into soaring upward into the sky.
## 6. Procedural 16-bit PCM crystalline bell chime audio synthesizer.
## 7. Intel Iris Xe optimized: shared materials, throttled particles, zero CPU stalls.

signal crystalfly_caught(fly_id: String, item_id: String, pos: Vector3)

var _flies: Array[Dictionary] = []
var _anim_time: float = 0.0
var _audio_player: AudioStreamPlayer3D = null
static var _chime_wav: AudioStreamWAV = null

# Shared Materials
static var _wing_mat: StandardMaterial3D = null
static var _body_mat: StandardMaterial3D = null
static var _trail_mat: StandardMaterial3D = null

func _init() -> void:
	name = "AnemoCrystalflySwarm"
	_init_materials()
	_build_audio_emitter()
	_spawn_crystalfly_swarm()

static func _init_materials() -> void:
	if _wing_mat != null:
		return

	# Crystalline Turquoise Wings
	_wing_mat = StandardMaterial3D.new()
	_wing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_wing_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_wing_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_wing_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_wing_mat.albedo_color = Color(0.22, 0.95, 0.88, 0.80)

	# Radiant Golden-Cyan Core Body
	_body_mat = StandardMaterial3D.new()
	_body_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_body_mat.albedo_color = Color(1.0, 0.95, 0.45, 1.0)

	# Trail Particle Material
	_trail_mat = StandardMaterial3D.new()
	_trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.albedo_color = Color(0.35, 1.0, 0.90, 0.75)

func _build_audio_emitter() -> void:
	if _chime_wav == null:
		_chime_wav = _generate_crystal_chime_wav()
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "CrystalflyAudio"
	_audio_player.stream = _chime_wav
	_audio_player.unit_size = 6.0
	_audio_player.max_distance = 25.0
	_audio_player.volume_db = -1.5
	add_child(_audio_player)

func _spawn_crystalfly_swarm() -> void:
	var spawn_coords = [
		Vector3(-18.0, 17.5, -16.0),  # Anemo Guardian Statue Summit Promontory
		Vector3(-14.0, 13.5, -12.0),  # Statue Mountain Pine Copse
		Vector3(26.0, 4.5, 30.0),     # Wilderness Camp Birch Grove
		Vector3(8.0, 5.0, 5.0),       # Sunlit Meadow Glade
		Vector3(-8.0, 8.0, 8.0),      # Whispering Grotto Ridge
		Vector3(18.0, 4.0, 22.0),     # Highland Trail Wildflowers
		Vector3(28.0, 3.8, 38.0)      # Lakeshore Reeds
	]

	for i in range(spawn_coords.size()):
		var base_pos: Vector3 = spawn_coords[i]
		var fly_root: Node3D = Node3D.new()
		fly_root.name = "Crystalfly_%d" % i
		fly_root.position = base_pos
		add_child(fly_root)

		# 1. Core Diamond Crystal Body
		var b_mesh: PrismMesh = PrismMesh.new()
		b_mesh.size = Vector3(0.08, 0.22, 0.08)
		var b_mi: MeshInstance3D = MeshInstance3D.new()
		b_mi.mesh = b_mesh
		b_mi.material_override = _body_mat
		b_mi.rotation.x = PI
		fly_root.add_child(b_mi)

		# 2. Four Faceted Crystalline Wings (Forewings & Hindwings)
		var left_forewing: Node3D = _create_wing(true, true)
		var right_forewing: Node3D = _create_wing(false, true)
		var left_hindwing: Node3D = _create_wing(true, false)
		var right_hindwing: Node3D = _create_wing(false, false)

		fly_root.add_child(left_forewing)
		fly_root.add_child(right_forewing)
		fly_root.add_child(left_hindwing)
		fly_root.add_child(right_hindwing)

		# 3. Soft Radial Glow Light
		var glow_light: OmniLight3D = OmniLight3D.new()
		glow_light.light_color = Color(0.28, 0.95, 0.88)
		glow_light.light_energy = 0.95
		glow_light.omni_range = 3.2
		glow_light.omni_attenuation = 1.6
		glow_light.shadow_enabled = false
		fly_root.add_child(glow_light)

		# 4. Trailing Sparkle Emitter
		var parts: GPUParticles3D = GPUParticles3D.new()
		parts.name = "Sparkles"
		parts.amount = 6
		parts.lifetime = 0.55
		parts.emitting = true
		var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
		p_mat.direction = Vector3(0.0, -1.0, 0.0)
		p_mat.spread = 25.0
		p_mat.initial_velocity_min = 0.2
		p_mat.initial_velocity_max = 0.6
		p_mat.gravity = Vector3(0.0, -0.2, 0.0)
		p_mat.scale_min = 0.04
		p_mat.scale_max = 0.10
		p_mat.color = Color(0.35, 1.0, 0.9, 0.8)
		parts.process_material = p_mat

		var s_mesh: SphereMesh = SphereMesh.new()
		s_mesh.radius = 0.035
		s_mesh.height = 0.07
		s_mesh.material = _trail_mat
		parts.draw_pass_1 = s_mesh
		fly_root.add_child(parts)

		_flies.append({
			"id": "crystalfly_%d" % i,
			"root": fly_root,
			"base_pos": base_pos,
			"curr_pos": base_pos,
			"left_fore": left_forewing,
			"right_fore": right_forewing,
			"left_hind": left_hindwing,
			"right_hind": right_hindwing,
			"light": glow_light,
			"particles": parts,
			"caught": false,
			"scattering": false,
			"scatter_time": 0.0,
			"phase_offset": randf() * TAU
		})

func _create_wing(is_left: bool, is_fore: bool) -> Node3D:
	var pivot = Node3D.new()
	var w_mesh = PrismMesh.new()
	var w_len: float = 0.32 if is_fore else 0.22
	var w_w: float = 0.18 if is_fore else 0.14
	w_mesh.size = Vector3(w_w, w_len, 0.02)

	var mi = MeshInstance3D.new()
	mi.mesh = w_mesh
	mi.material_override = _wing_mat
	var side_sign: float = -1.0 if is_left else 1.0
	mi.position = Vector3(side_sign * (w_w * 0.55), (w_len * 0.45) if is_fore else (-w_len * 0.35), 0.0)
	mi.rotation.z = deg_to_rad(-25.0 * side_sign) if is_fore else deg_to_rad(30.0 * side_sign)

	pivot.add_child(mi)
	return pivot

func update_behavior(delta: float, player_pos: Vector3 = Vector3.ZERO, player_speed: float = 0.0) -> void:
	_anim_time += delta

	for fly in _flies:
		if fly["caught"]:
			continue

		var f_root: Node3D = fly["root"]
		var phase: float = _anim_time * 2.2 + fly["phase_offset"]

		# 1. High frequency wing flapping animation
		var flap_ang: float = sin(_anim_time * 18.0 + fly["phase_offset"]) * 0.52
		fly["left_fore"].rotation.y = flap_ang
		fly["right_fore"].rotation.y = -flap_ang
		fly["left_hind"].rotation.y = flap_ang * 0.75
		fly["right_hind"].rotation.y = -flap_ang * 0.75

		# 2. Panic scatter logic if player sprints nearby
		if not fly["scattering"] and player_pos != Vector3.ZERO:
			var d_p: float = fly["curr_pos"].distance_to(player_pos)
			if d_p < 3.2 and player_speed > 4.5:
				fly["scattering"] = true
				fly["scatter_time"] = 0.0

		if fly["scattering"]:
			fly["scatter_time"] += delta
			# Soar upward into the sky
			fly["curr_pos"].y += delta * 6.5
			fly["curr_pos"].x += cos(phase) * delta * 2.2
			fly["curr_pos"].z += sin(phase) * delta * 2.2
			f_root.position = fly["curr_pos"]

			if fly["scatter_time"] >= 2.5:
				# Dissipate into the sky
				f_root.visible = false
				fly["caught"] = true # Removed from world
			continue

		# 3. Gentle figure-8 floating hover path
		var wander_r: float = 1.4
		var off_x: float = sin(phase) * wander_r
		var off_z: float = cos(phase * 0.5) * wander_r * 1.2
		var off_y: float = sin(phase * 1.5) * 0.35

		fly["curr_pos"] = fly["base_pos"] + Vector3(off_x, off_y, off_z)
		f_root.position = fly["curr_pos"]
		f_root.rotation.y = lerp_angle(f_root.rotation.y, phase + PI * 0.5, delta * 3.0)

func get_nearby_crystalfly(pos: Vector3, max_dist: float = 2.4) -> Dictionary:
	for fly in _flies:
		if not fly["caught"] and not fly["scattering"]:
			var d: float = pos.distance_to(fly["curr_pos"])
			if d <= max_dist:
				return {
					"id": fly["id"],
					"name": "Tinh Điệp Phong",
					"item_id": "crystal_core",
					"pos": fly["curr_pos"],
					"icon": "🦋",
					"exp": 30
				}
	return {}

func catch_crystalfly(fly_id: String) -> Dictionary:
	for fly in _flies:
		if fly["id"] == fly_id and not fly["caught"]:
			fly["caught"] = true
			var f_root: Node3D = fly["root"]
			f_root.visible = false

			if _audio_player and is_inside_tree():
				_audio_player.global_position = fly["curr_pos"]
				_audio_player.pitch_scale = randf_range(0.98, 1.05)
				_audio_player.play()

			crystalfly_caught.emit(fly_id, "crystal_core", fly["curr_pos"])
			return {
				"id": fly_id,
				"name": "Tinh Nhân Tinh Điệp",
				"item_id": "crystal_core",
				"icon": "🦋",
				"exp": 30
			}
	return {}

func get_active_count() -> int:
	var c: int = 0
	for f in _flies:
		if not f["caught"]:
			c += 1
	return c

static func _generate_crystal_chime_wav(duration: float = 0.75, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	# 3-note crystalline triad arpeggio: C6 (1046.5Hz), E6 (1318.5Hz), G6 (1568Hz)
	var freqs = [1046.5, 1318.5, 1568.0]
	var note_dur: float = 0.12

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var sample: float = 0.0

		for n in range(freqs.size()):
			var start_t: float = float(n) * note_dur
			if t >= start_t:
				var note_t: float = t - start_t
				var env: float = exp(-note_t * 5.5)
				var chime: float = sin(note_t * freqs[n] * TAU) * 0.7 + sin(note_t * freqs[n] * 2.0 * TAU) * 0.3
				sample += chime * env * 0.35

		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
