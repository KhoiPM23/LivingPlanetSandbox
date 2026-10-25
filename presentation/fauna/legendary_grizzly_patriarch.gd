class_name LegendaryGrizzlyPatriarch
extends Node3D

## Living Planet Sandbox — RDR2-Style Legendary Grizzly Patriarch (Block 59)
## "Bá Vương Hùng — Hùng Vương Đỉnh Băng Tuyết Skyspire"
## Features:
## 1. Massive apex predator bear with silver-tipped umber fur, muscular hump, and silver claws.
## 2. Dynamic 4-state Territorial FSM: PROWLING, SNIFFING_WIND, TERRITORIAL_ROAR, SNOW_SWIPE.
## 3. Procedural 16-bit PCM deep visceral roar audio synthesizer (sub-bass tremor 55-115 Hz).
## 4. Interactive Close-up Wildlife Photography ([E] Chụp ảnh dã sinh cự ly gần):
##    - Rewards +350 EXP, +120 Haven Coins, and rare material "grizzly_silver_claw" (Móng Bạc Hùng Vương).
## 5. Cold summit frost breath particle effects & snow-kick bursts.
## 6. Iris Xe optimized procedural low-poly geometry & static cached materials.

signal bear_spotted(pos: Vector3)
signal photo_taken(reward: Dictionary)
signal roar_emitted(pos: Vector3)

enum BearState {
	PROWLING = 0,
	SNIFFING_WIND = 1,
	TERRITORIAL_ROAR = 2,
	SNOW_SWIPE = 3
}

const INTERACTION_DIST: float = 6.0
const PROWL_SPEED: float = 1.4

# Visual Components
var _body_pivot: Node3D = null
var _torso_mesh: MeshInstance3D = null
var _hump_mesh: MeshInstance3D = null
var _head_pivot: Node3D = null
var _head_mesh: MeshInstance3D = null
var _snout_mesh: MeshInstance3D = null
var _legs: Array[Node3D] = []
var _frost_breath: CPUParticles3D = null
var _snow_burst: CPUParticles3D = null
var _audio_player: AudioStreamPlayer3D = null

# Materials
static var _fur_dark_mat: StandardMaterial3D = null
static var _fur_silver_tip_mat: StandardMaterial3D = null
static var _snout_mat: StandardMaterial3D = null
static var _eye_mat: StandardMaterial3D = null
static var _claw_mat: StandardMaterial3D = null
static var _roar_wav: AudioStreamWAV = null

# State Variables
var current_state: BearState = BearState.PROWLING
var _state_timer: float = 0.0
var _anim_time: float = 0.0
var _has_photographed: bool = false
var _has_spotted: bool = false
var _home_pos: Vector3 = Vector3(-135.0, 72.0, -130.0)
var _target_pos: Vector3 = Vector3(-135.0, 72.0, -130.0)
var _target_yaw: float = 0.0
var _prowl_radius: float = 8.0
var _terrain_ref: Node = null

func _init() -> void:
	name = "LegendaryGrizzlyPatriarch"
	_init_materials()
	_init_audio()
	_build_bear_model()

func _ready() -> void:
	_home_pos = position
	_target_pos = position

func setup(terrain: Node = null) -> void:
	_terrain_ref = terrain
	_clamp_to_terrain()

static func _init_materials() -> void:
	if _fur_dark_mat != null:
		return

	# Deep Umber Fur
	_fur_dark_mat = StandardMaterial3D.new()
	_fur_dark_mat.albedo_color = Color(0.20, 0.15, 0.11)
	_fur_dark_mat.roughness = 0.88
	_fur_dark_mat.rim_enabled = true
	_fur_dark_mat.rim = 0.35
	_fur_dark_mat.rim_tint = 0.50

	# Silver-Tipped Frost Fur (Shoulders & Back Hump)
	_fur_silver_tip_mat = StandardMaterial3D.new()
	_fur_silver_tip_mat.albedo_color = Color(0.68, 0.72, 0.78)
	_fur_silver_tip_mat.roughness = 0.75
	_fur_silver_tip_mat.rim_enabled = true
	_fur_silver_tip_mat.rim = 0.70
	_fur_silver_tip_mat.rim_tint = 0.90

	# Dark Leather Snout
	_snout_mat = StandardMaterial3D.new()
	_snout_mat.albedo_color = Color(0.10, 0.08, 0.07)
	_snout_mat.roughness = 0.50

	# Dark Eyes
	_eye_mat = StandardMaterial3D.new()
	_eye_mat.albedo_color = Color(0.05, 0.04, 0.04)
	_eye_mat.roughness = 0.15

	# Silver Metallic Claws
	_claw_mat = StandardMaterial3D.new()
	_claw_mat.albedo_color = Color(0.85, 0.88, 0.92)
	_claw_mat.metallic = 0.85
	_claw_mat.roughness = 0.30

static func _init_audio() -> void:
	if _roar_wav != null:
		return
	_roar_wav = _generate_grizzly_roar_wav()

static func _generate_grizzly_roar_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 1.35
	var total_samples: int = int(sample_rate * duration)
	var pcm_data: PackedByteArray = PackedByteArray()
	pcm_data.resize(total_samples * 2)

	var phase_main: float = 0.0
	var phase_sub: float = 0.0
	var phase_growl: float = 0.0

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		# Deep pitch drop from 115 Hz down to 55 Hz
		var freq_main: float = lerpf(115.0, 55.0, ease(t / duration, 0.5))
		var freq_sub: float = freq_main * 0.5
		var growl_mod: float = sin(phase_growl) * 0.35 + 0.65

		phase_main += (TAU * freq_main) / float(sample_rate)
		phase_sub += (TAU * freq_sub) / float(sample_rate)
		phase_growl += (TAU * 18.0) / float(sample_rate)

		# Combined wave: fundamental + sub-octave growl + resonant distortion
		var sig: float = sin(phase_main) * 0.55 + sin(phase_sub) * 0.35 + sin(phase_main * 2.0) * 0.15
		sig *= growl_mod

		# Soft attack & exponential decay envelope
		var env: float = 1.0
		if t < 0.12:
			env = t / 0.12
		else:
			env = exp(-2.0 * (t - 0.12))

		sig = clampf(sig * env * 0.90, -1.0, 1.0)
		var sample_val: int = int(round(sig * 32767.0))
		pcm_data.encode_s16(i * 2, sample_val)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = pcm_data
	return wav

func _build_bear_model() -> void:
	_body_pivot = Node3D.new()
	_body_pivot.name = "BodyPivot"
	add_child(_body_pivot)

	# 1. Main Massive Torso (Muscular rounded silhouette)
	var torso_mesh_inst: MeshInstance3D = MeshInstance3D.new()
	torso_mesh_inst.name = "Torso"
	var b_torso: CapsuleMesh = CapsuleMesh.new()
	b_torso.radius = 0.68
	b_torso.height = 2.3
	torso_mesh_inst.mesh = b_torso
	torso_mesh_inst.material_override = _fur_dark_mat
	torso_mesh_inst.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	torso_mesh_inst.position = Vector3(0.0, 1.45, 0.0)
	_body_pivot.add_child(torso_mesh_inst)
	_torso_mesh = torso_mesh_inst

	# 2. Muscular Shoulders / Hump (Silver-tipped, powerful apex predator crest)
	var hump_mesh_inst: MeshInstance3D = MeshInstance3D.new()
	hump_mesh_inst.name = "ShoulderHump"
	var s_hump: SphereMesh = SphereMesh.new()
	s_hump.radius = 0.72
	s_hump.height = 1.05
	hump_mesh_inst.mesh = s_hump
	hump_mesh_inst.material_override = _fur_silver_tip_mat
	hump_mesh_inst.scale = Vector3(1.15, 0.95, 1.30)
	hump_mesh_inst.position = Vector3(0.0, 1.95, -0.45)
	_body_pivot.add_child(hump_mesh_inst)
	_hump_mesh = hump_mesh_inst

	# 3. Head & Snout Pivot
	_head_pivot = Node3D.new()
	_head_pivot.name = "HeadPivot"
	_head_pivot.position = Vector3(0.0, 1.65, -1.15)
	_body_pivot.add_child(_head_pivot)

	# Bear Head (Sculpted rounded head)
	var head_mesh_inst: MeshInstance3D = MeshInstance3D.new()
	head_mesh_inst.name = "Head"
	var b_head: CapsuleMesh = CapsuleMesh.new()
	b_head.radius = 0.40
	b_head.height = 0.88
	head_mesh_inst.mesh = b_head
	head_mesh_inst.material_override = _fur_dark_mat
	head_mesh_inst.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	head_mesh_inst.position = Vector3(0.0, 0.0, -0.22)
	_head_pivot.add_child(head_mesh_inst)
	_head_mesh = head_mesh_inst

	# Snout (Tapered predator muzzle)
	var snout_mesh_inst: MeshInstance3D = MeshInstance3D.new()
	snout_mesh_inst.name = "Snout"
	var b_snout: CylinderMesh = CylinderMesh.new()
	b_snout.top_radius = 0.20
	b_snout.bottom_radius = 0.29
	b_snout.height = 0.55
	snout_mesh_inst.mesh = b_snout
	snout_mesh_inst.material_override = _snout_mat
	snout_mesh_inst.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	snout_mesh_inst.position = Vector3(0.0, -0.10, -0.74)
	_head_pivot.add_child(snout_mesh_inst)
	_snout_mesh = snout_mesh_inst

	# Ears
	for side in [-1.0, 1.0]:
		var ear: MeshInstance3D = MeshInstance3D.new()
		var c_ear: CylinderMesh = CylinderMesh.new()
		c_ear.top_radius = 0.16
		c_ear.bottom_radius = 0.12
		c_ear.height = 0.14
		ear.mesh = c_ear
		ear.material_override = _fur_silver_tip_mat
		ear.position = Vector3(side * 0.38, 0.45, -0.15)
		ear.rotation_degrees = Vector3(0, 0, side * 25.0)
		_head_pivot.add_child(ear)

	# Eyes
	for side in [-1.0, 1.0]:
		var eye: MeshInstance3D = MeshInstance3D.new()
		var s_eye: SphereMesh = SphereMesh.new()
		s_eye.radius = 0.06
		s_eye.height = 0.12
		eye.mesh = s_eye
		eye.material_override = _eye_mat
		eye.position = Vector3(side * 0.36, 0.15, -0.65)
		_head_pivot.add_child(eye)

	# 4. Muscular Legs & Silver Claws
	var leg_coords: Array[Vector3] = [
		Vector3(-0.62, 0.70, -0.75), # Front-Left
		Vector3(0.62, 0.70, -0.75),  # Front-Right
		Vector3(-0.62, 0.65, 0.75),  # Back-Left
		Vector3(0.62, 0.65, 0.75)   # Back-Right
	]
	_legs.clear()
	for i in range(leg_coords.size()):
		var leg_pivot: Node3D = Node3D.new()
		leg_pivot.name = "LegPivot_%d" % i
		leg_pivot.position = leg_coords[i]
		_body_pivot.add_child(leg_pivot)

		var leg_mesh: MeshInstance3D = MeshInstance3D.new()
		var b_leg: CapsuleMesh = CapsuleMesh.new()
		b_leg.radius = 0.22
		b_leg.height = 1.30
		leg_mesh.mesh = b_leg
		leg_mesh.material_override = _fur_dark_mat
		leg_mesh.position = Vector3(0.0, -0.55, 0.0)
		leg_pivot.add_child(leg_mesh)

		# Add 3 curved silver claws to each paw
		for c_idx in range(3):
			var claw: MeshInstance3D = MeshInstance3D.new()
			var b_claw: BoxMesh = BoxMesh.new()
			b_claw.size = Vector3(0.05, 0.06, 0.20)
			claw.mesh = b_claw
			claw.material_override = _claw_mat
			var claw_x: float = (float(c_idx) - 1.0) * 0.12
			claw.position = Vector3(claw_x, -1.15, -0.22)
			claw.rotation_degrees = Vector3(25.0, 0.0, 0.0)
			leg_pivot.add_child(claw)

		_legs.append(leg_pivot)

	# 5. Frost Breath Particles (Snout tip)
	_frost_breath = CPUParticles3D.new()
	_frost_breath.name = "FrostBreathParticles"
	_frost_breath.emitting = true
	_frost_breath.amount = 12
	_frost_breath.lifetime = 1.4
	_frost_breath.speed_scale = 0.9
	_frost_breath.explosiveness = 0.1
	_frost_breath.direction = Vector3(0, -0.2, -1.0)
	_frost_breath.spread = 22.0
	_frost_breath.gravity = Vector3(0, 0.35, 0)
	_frost_breath.initial_velocity_min = 0.8
	_frost_breath.initial_velocity_max = 1.5
	_frost_breath.scale_amount_min = 0.15
	_frost_breath.scale_amount_max = 0.40
	_frost_breath.color = Color(0.92, 0.96, 1.0, 0.45)
	_head_pivot.add_child(_frost_breath)
	_frost_breath.position = Vector3(0.0, -0.15, -1.15)

	# 6. Snow Swipe Kick Particles
	_snow_burst = CPUParticles3D.new()
	_snow_burst.name = "SnowBurstParticles"
	_snow_burst.emitting = false
	_snow_burst.one_shot = true
	_snow_burst.amount = 35
	_snow_burst.lifetime = 1.0
	_snow_burst.explosiveness = 0.85
	_snow_burst.direction = Vector3(0, 0.8, -0.6)
	_snow_burst.spread = 45.0
	_snow_burst.gravity = Vector3(0, -9.8, 0)
	_snow_burst.initial_velocity_min = 4.0
	_snow_burst.initial_velocity_max = 7.5
	_snow_burst.scale_amount_min = 0.20
	_snow_burst.scale_amount_max = 0.55
	_snow_burst.color = Color(0.95, 0.98, 1.0, 0.85)
	_body_pivot.add_child(_snow_burst)
	_snow_burst.position = Vector3(0.0, 0.2, -1.1)

	# 7. Procedural Audio Player 3D
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "BearAudioPlayer"
	_audio_player.stream = _roar_wav
	_audio_player.max_distance = 65.0
	_audio_player.unit_size = 12.0
	_audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(_audio_player)

func _process(delta: float) -> void:
	_anim_time += delta
	_state_timer += delta

	match current_state:
		BearState.PROWLING:
			_update_prowling(delta)
		BearState.SNIFFING_WIND:
			_update_sniffing(delta)
		BearState.TERRITORIAL_ROAR:
			_update_roaring(delta)
		BearState.SNOW_SWIPE:
			_update_snow_swipe(delta)

	_clamp_to_terrain()

func _update_prowling(delta: float) -> void:
	# Move slowly toward target wander point
	var cur_xz: Vector2 = Vector2(position.x, position.z)
	var tgt_xz: Vector2 = Vector2(_target_pos.x, _target_pos.z)
	var diff: Vector2 = tgt_xz - cur_xz

	if diff.length() > 0.5:
		var dir_xz: Vector2 = diff.normalized()
		position.x += dir_xz.x * PROWL_SPEED * delta
		position.z += dir_xz.y * PROWL_SPEED * delta
		_target_yaw = atan2(-dir_xz.x, -dir_xz.y)
		rotation.y = lerp_angle(rotation.y, _target_yaw, delta * 3.0)

		# Stride leg animation
		var cycle: float = _anim_time * 3.5
		if _legs.size() >= 4:
			_legs[0].rotation.x = sin(cycle) * 0.35
			_legs[1].rotation.x = -sin(cycle) * 0.35
			_legs[2].rotation.x = -sin(cycle) * 0.35
			_legs[3].rotation.x = sin(cycle) * 0.35
		if _body_pivot:
			_body_pivot.position.y = absf(sin(cycle * 2.0)) * 0.06
			_body_pivot.rotation.x = 0.0
	else:
		# Reset leg rotations
		for leg in _legs:
			leg.rotation.x = lerpf(leg.rotation.x, 0.0, delta * 6.0)

	# Transition timer
	if _state_timer >= 6.5:
		_transition_to_random_state()

func _update_sniffing(delta: float) -> void:
	for leg in _legs:
		leg.rotation.x = lerpf(leg.rotation.x, 0.0, delta * 6.0)

	if _head_pivot:
		# Sniffs air: lifts head up and turns slightly
		_head_pivot.rotation.x = lerpf(_head_pivot.rotation.x, -deg_to_rad(22.0), delta * 3.5)
		_head_pivot.rotation.y = sin(_anim_time * 2.5) * deg_to_rad(15.0)

	if _state_timer >= 4.0:
		_transition_to_random_state()

func _update_roaring(delta: float) -> void:
	if _body_pivot:
		# Rears up on hind legs (+30 degrees pitch)
		_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, -deg_to_rad(30.0), delta * 4.0)
		_body_pivot.position.y = lerpf(_body_pivot.position.y, 0.55, delta * 4.0)

	if _head_pivot:
		# Throws head back in mighty roar
		_head_pivot.rotation.x = lerpf(_head_pivot.rotation.x, -deg_to_rad(35.0), delta * 4.0)

	# Raise front paws
	if _legs.size() >= 2:
		_legs[0].rotation.x = lerpf(_legs[0].rotation.x, -deg_to_rad(55.0) + sin(_anim_time * 6.0) * 0.15, delta * 5.0)
		_legs[1].rotation.x = lerpf(_legs[1].rotation.x, -deg_to_rad(55.0) - sin(_anim_time * 6.0) * 0.15, delta * 5.0)

	if _state_timer >= 3.8:
		_transition_to_state(BearState.PROWLING)

func _update_snow_swipe(delta: float) -> void:
	if _body_pivot:
		_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, deg_to_rad(8.0), delta * 4.0)

	if _legs.size() >= 2:
		# Right paw swipes across snow
		_legs[1].rotation.x = sin(_anim_time * 7.0) * deg_to_rad(45.0)

	if _state_timer >= 2.8:
		_transition_to_state(BearState.PROWLING)

func _transition_to_random_state() -> void:
	var roll: float = randf()
	if roll < 0.40:
		_transition_to_state(BearState.PROWLING)
	elif roll < 0.70:
		_transition_to_state(BearState.SNIFFING_WIND)
	elif roll < 0.88:
		_transition_to_state(BearState.TERRITORIAL_ROAR)
	else:
		_transition_to_state(BearState.SNOW_SWIPE)

func _transition_to_state(new_state: BearState) -> void:
	current_state = new_state
	_state_timer = 0.0

	match new_state:
		BearState.PROWLING:
			# Pick new wander target on summit
			var angle: float = randf() * TAU
			var dist: float = randf_range(2.0, _prowl_radius)
			_target_pos = _home_pos + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
			if _body_pivot:
				_body_pivot.position.y = 0.0
		BearState.SNIFFING_WIND:
			pass
		BearState.TERRITORIAL_ROAR:
			emit_roar()
		BearState.SNOW_SWIPE:
			if _snow_burst:
				_snow_burst.restart()
				_snow_burst.emitting = true

func emit_roar() -> void:
	if _audio_player and is_inside_tree() and not _audio_player.playing:
		_audio_player.play()
	var b_pos: Vector3 = global_position if is_inside_tree() else position
	roar_emitted.emit(b_pos)
	print("[LegendaryGrizzlyPatriarch] Deep territorial roar resonated across Skyspire summit!")

func is_player_near(p_pos: Vector3) -> bool:
	var b_pos: Vector3 = global_position if is_inside_tree() else position
	return p_pos.distance_to(b_pos) <= INTERACTION_DIST

func check_player_spotted(p_pos: Vector3) -> void:
	var b_pos: Vector3 = global_position if is_inside_tree() else position
	if not _has_spotted and p_pos.distance_to(b_pos) <= 24.0:
		_has_spotted = true
		bear_spotted.emit(b_pos)

func take_wildlife_photo() -> Dictionary:
	_has_photographed = true
	# Reared up roar celebration pose
	_transition_to_state(BearState.TERRITORIAL_ROAR)

	var reward: Dictionary = {
		"exp": 350,
		"coins": 120,
		"item": "grizzly_silver_claw",
		"title": "Khoảnh Khắc Dã Sinh: Hùng Vương Đỉnh Băng Tuyết",
		"desc": "Bức ảnh cận cảnh huyền thoại ghi lại phong thái oai dũng của Bá Vương Hùng trên đỉnh Skyspire Massif."
	}
	photo_taken.emit(reward)
	return reward

func _clamp_to_terrain() -> void:
	if _terrain_ref and _terrain_ref.has_method("get_height_at"):
		var h: float = _terrain_ref.get_height_at(position.x, position.z)
		position.y = h
	elif position.y < 0.0:
		position.y = 0.0
