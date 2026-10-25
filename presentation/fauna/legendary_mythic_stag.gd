class_name LegendaryMythicStag
extends Node3D

## Living Planet Sandbox — RDR2-Style Legendary Mythic White Stag (Block 58)
## "Thần Thú Bạch Hươu — Tinh Linh Rừng Cổ Thụ"
## Features:
## 1. Regal alabaster stag with glowing gilded 12-point branching antlers (OmniLight3D aura).
## 2. Dynamic FSM: SERENE_GRAZING, MAJESTIC_STRIDE, ALERT_REGAL, SACRED_COMMUNING, SPIRIT_LEAP.
## 3. Interactive Sacred Communion ([E] Kính cẩn thuần hóa):
##    - Stag bows regal head, antlers pulse golden starlight
##    - Procedural 16-bit PCM ethereal bugle call synthesizer
##    - Bestows "Phúc Lành Bạch Hươu" (+25% sprint speed, golden hoofprints), +300 EXP, +100 Coins
## 4. Compatible with Eagle Eye: leaves radiant golden star hoofprints & scent trail.
## 5. Optimized for Intel Iris Xe: low-poly procedural meshes, shared materials.

signal stag_spotted(pos: Vector3)
signal stag_communed(reward: Dictionary)

enum StagState {
	SERENE_GRAZING,
	MAJESTIC_STRIDE,
	ALERT_REGAL,
	SACRED_COMMUNING,
	SPIRIT_LEAP
}

const INTERACTION_DIST: float = 4.5
const LEAP_SPEED: float = 6.8
const WALK_SPEED: float = 2.2

# Visual Components
var _body_pivot: Node3D = null
var _neck_pivot: Node3D = null
var _head_pivot: Node3D = null
var _antlers_node: Node3D = null
var _antler_light: OmniLight3D = null
var _legs: Array[Node3D] = []
var _tail_pivot: Node3D = null
var _stardust_particles: CPUParticles3D = null
var _audio_player: AudioStreamPlayer3D = null

# Materials
static var _stag_white_mat: StandardMaterial3D = null
static var _stag_gold_mat: StandardMaterial3D = null
static var _stag_eye_mat: StandardMaterial3D = null
static var _stag_hoof_mat: StandardMaterial3D = null
static var _bugle_wav: AudioStreamWAV = null

# State
var current_state: StagState = StagState.SERENE_GRAZING
var _state_timer: float = 0.0
var _anim_time: float = 0.0
var _has_communed: bool = false
var _has_spotted: bool = false
var _communion_cooldown: float = 0.0
var _terrain_ref: Node = null
var _home_pos: Vector3 = Vector3(-45.0, 5.4, -15.0)
var _target_pos: Vector3 = Vector3(-45.0, 5.4, -15.0)
var _target_yaw: float = 0.0
var _wander_radius: float = 16.0

func _init() -> void:
	name = "LegendaryMythicStag"
	_init_materials()
	_init_audio()
	_build_stag_model()

func _ready() -> void:
	_home_pos = position
	_target_pos = position

func setup(terrain: Node = null) -> void:
	_terrain_ref = terrain
	_clamp_to_terrain()

static func _init_materials() -> void:
	if _stag_white_mat != null:
		return

	# Alabaster White Pelt with subtle celestial Fresnel
	_stag_white_mat = StandardMaterial3D.new()
	_stag_white_mat.albedo_color = Color(0.96, 0.97, 1.0)
	_stag_white_mat.roughness = 0.80
	_stag_white_mat.rim_enabled = true
	_stag_white_mat.rim = 0.45
	_stag_white_mat.rim_tint = 0.65

	# Gilded Ethereal Antlers
	_stag_gold_mat = StandardMaterial3D.new()
	_stag_gold_mat.albedo_color = Color(1.0, 0.88, 0.45)
	_stag_gold_mat.roughness = 0.35
	_stag_gold_mat.metallic = 0.60
	_stag_gold_mat.emission_enabled = true
	_stag_gold_mat.emission = Color(1.0, 0.82, 0.32)
	_stag_gold_mat.emission_energy_multiplier = 2.0

	# Sapphire Eyes
	_stag_eye_mat = StandardMaterial3D.new()
	_stag_eye_mat.albedo_color = Color(0.12, 0.35, 0.85)
	_stag_eye_mat.roughness = 0.15

	# Dark Gold Hooves
	_stag_hoof_mat = StandardMaterial3D.new()
	_stag_hoof_mat.albedo_color = Color(0.55, 0.42, 0.18)
	_stag_hoof_mat.roughness = 0.60

static func _init_audio() -> void:
	if _bugle_wav != null:
		return
	_bugle_wav = _generate_mythic_stag_bugle_wav()

func _build_stag_model() -> void:
	_body_pivot = Node3D.new()
	_body_pivot.name = "BodyPivot"
	add_child(_body_pivot)

	# 1. Torso
	var torso_mesh = CapsuleMesh.new()
	torso_mesh.radius = 0.44
	torso_mesh.height = 1.65
	torso_mesh.material = _stag_white_mat
	var torso_inst = MeshInstance3D.new()
	torso_inst.mesh = torso_mesh
	torso_inst.rotation.x = deg_to_rad(90.0)
	torso_inst.position = Vector3(0.0, 1.25, 0.0)
	_body_pivot.add_child(torso_inst)

	# 2. Chest & Withers hump
	var chest_mesh = SphereMesh.new()
	chest_mesh.radius = 0.48
	chest_mesh.height = 0.95
	chest_mesh.material = _stag_white_mat
	var chest_inst = MeshInstance3D.new()
	chest_inst.mesh = chest_mesh
	chest_inst.position = Vector3(0.0, 1.35, 0.55)
	_body_pivot.add_child(chest_inst)

	# 3. Neck Pivot
	_neck_pivot = Node3D.new()
	_neck_pivot.name = "NeckPivot"
	_neck_pivot.position = Vector3(0.0, 1.40, 0.65)
	_body_pivot.add_child(_neck_pivot)

	var neck_mesh = CylinderMesh.new()
	neck_mesh.top_radius = 0.22
	neck_mesh.bottom_radius = 0.34
	neck_mesh.height = 0.85
	neck_mesh.material = _stag_white_mat
	var neck_inst = MeshInstance3D.new()
	neck_inst.mesh = neck_mesh
	neck_inst.position = Vector3(0.0, 0.38, 0.22)
	neck_inst.rotation.x = deg_to_rad(32.0)
	_neck_pivot.add_child(neck_inst)

	# 4. Head Pivot
	_head_pivot = Node3D.new()
	_head_pivot.name = "HeadPivot"
	_head_pivot.position = Vector3(0.0, 0.72, 0.42)
	_neck_pivot.add_child(_head_pivot)

	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.28, 0.32, 0.55)
	head_mesh.material = _stag_white_mat
	var head_inst = MeshInstance3D.new()
	head_inst.mesh = head_mesh
	head_inst.position = Vector3(0.0, 0.08, 0.18)
	head_inst.rotation.x = deg_to_rad(-12.0)
	_head_pivot.add_child(head_inst)

	# Muzzle
	var muzzle_mesh = BoxMesh.new()
	muzzle_mesh.size = Vector3(0.18, 0.16, 0.32)
	muzzle_mesh.material = _stag_white_mat
	var muzzle_inst = MeshInstance3D.new()
	muzzle_inst.mesh = muzzle_mesh
	muzzle_inst.position = Vector3(0.0, 0.02, 0.48)
	_head_pivot.add_child(muzzle_inst)

	# Eyes
	for eye_sign in [-1.0, 1.0]:
		var eye_mesh = SphereMesh.new()
		eye_mesh.radius = 0.045
		eye_mesh.height = 0.09
		eye_mesh.material = _stag_eye_mat
		var eye_inst = MeshInstance3D.new()
		eye_inst.mesh = eye_mesh
		eye_inst.position = Vector3(eye_sign * 0.15, 0.12, 0.25)
		_head_pivot.add_child(eye_inst)

	# Ears
	for ear_sign in [-1.0, 1.0]:
		var ear_mesh = PrismMesh.new()
		ear_mesh.size = Vector3(0.10, 0.28, 0.06)
		ear_mesh.material = _stag_white_mat
		var ear_inst = MeshInstance3D.new()
		ear_inst.mesh = ear_mesh
		ear_inst.position = Vector3(ear_sign * 0.18, 0.28, 0.0)
		ear_inst.rotation = Vector3(deg_to_rad(-18.0), 0.0, ear_sign * deg_to_rad(-35.0))
		_head_pivot.add_child(ear_inst)

	# 5. Grand Gilded Antlers
	_antlers_node = Node3D.new()
	_antlers_node.name = "GildedAntlers"
	_antlers_node.position = Vector3(0.0, 0.26, 0.05)
	_head_pivot.add_child(_antlers_node)

	_build_branching_antlers()

	# Antler Radiance OmniLight
	_antler_light = OmniLight3D.new()
	_antler_light.name = "AntlerLight"
	_antler_light.light_color = Color(1.0, 0.88, 0.50)
	_antler_light.light_energy = 1.4
	_antler_light.omni_range = 6.5
	_antler_light.omni_attenuation = 1.2
	_antlers_node.add_child(_antler_light)

	# 6. Legs (4 slender limbs)
	var leg_coords = [
		{"name": "Leg_FL", "pos": Vector3(-0.25, 0.85, 0.45)},
		{"name": "Leg_FR", "pos": Vector3(0.25, 0.85, 0.45)},
		{"name": "Leg_BL", "pos": Vector3(-0.25, 0.85, -0.45)},
		{"name": "Leg_BR", "pos": Vector3(0.25, 0.85, -0.45)}
	]
	for l_data in leg_coords:
		var leg_root = Node3D.new()
		leg_root.name = l_data["name"]
		leg_root.position = l_data["pos"]
		_body_pivot.add_child(leg_root)

		# Upper Leg
		var upper_mesh = CylinderMesh.new()
		upper_mesh.top_radius = 0.12
		upper_mesh.bottom_radius = 0.08
		upper_mesh.height = 0.55
		upper_mesh.material = _stag_white_mat
		var upper_inst = MeshInstance3D.new()
		upper_inst.mesh = upper_mesh
		upper_inst.position = Vector3(0.0, -0.22, 0.0)
		leg_root.add_child(upper_inst)

		# Lower Leg
		var lower_mesh = CylinderMesh.new()
		lower_mesh.top_radius = 0.07
		lower_mesh.bottom_radius = 0.05
		lower_mesh.height = 0.55
		lower_mesh.material = _stag_white_mat
		var lower_inst = MeshInstance3D.new()
		lower_inst.mesh = lower_mesh
		lower_inst.position = Vector3(0.0, -0.65, 0.0)
		leg_root.add_child(lower_inst)

		# Hoof
		var hoof_mesh = BoxMesh.new()
		hoof_mesh.size = Vector3(0.10, 0.09, 0.12)
		hoof_mesh.material = _stag_hoof_mat
		var hoof_inst = MeshInstance3D.new()
		hoof_inst.mesh = hoof_mesh
		hoof_inst.position = Vector3(0.0, -0.92, 0.02)
		leg_root.add_child(hoof_inst)

		_legs.append(leg_root)

	# 7. Tail
	_tail_pivot = Node3D.new()
	_tail_pivot.name = "TailPivot"
	_tail_pivot.position = Vector3(0.0, 1.30, -0.78)
	_body_pivot.add_child(_tail_pivot)

	var tail_mesh = CylinderMesh.new()
	tail_mesh.top_radius = 0.08
	tail_mesh.bottom_radius = 0.02
	tail_mesh.height = 0.28
	tail_mesh.material = _stag_white_mat
	var tail_inst = MeshInstance3D.new()
	tail_inst.mesh = tail_mesh
	tail_inst.position = Vector3(0.0, -0.12, -0.06)
	tail_inst.rotation.x = deg_to_rad(-25.0)
	_tail_pivot.add_child(tail_inst)

	# 8. Golden Stardust Particle System
	_stardust_particles = CPUParticles3D.new()
	_stardust_particles.name = "StardustParticles"
	_stardust_particles.amount = 16
	_stardust_particles.lifetime = 1.8
	_stardust_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_stardust_particles.emission_sphere_radius = 1.2
	_stardust_particles.gravity = Vector3(0.0, -0.15, 0.0)
	_stardust_particles.initial_velocity_min = 0.2
	_stardust_particles.initial_velocity_max = 0.6
	_stardust_particles.scale_amount_min = 0.04
	_stardust_particles.scale_amount_max = 0.08
	_stardust_particles.color = Color(1.0, 0.88, 0.40, 0.85)
	add_child(_stardust_particles)

	# 9. Spatial Audio Player
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "StagAudio"
	_audio_player.stream = _bugle_wav
	_audio_player.unit_size = 12.0
	_audio_player.max_distance = 65.0
	_audio_player.volume_db = 2.0
	add_child(_audio_player)

func _build_branching_antlers() -> void:
	for side in [-1.0, 1.0]:
		# Main Beam
		var main_beam = CylinderMesh.new()
		main_beam.top_radius = 0.035
		main_beam.bottom_radius = 0.065
		main_beam.height = 0.85
		main_beam.material = _stag_gold_mat
		var beam_inst = MeshInstance3D.new()
		beam_inst.mesh = main_beam
		beam_inst.position = Vector3(side * 0.28, 0.40, -0.08)
		beam_inst.rotation = Vector3(deg_to_rad(22.0), side * deg_to_rad(-18.0), side * deg_to_rad(-28.0))
		_antlers_node.add_child(beam_inst)

		# Brow Tine (forward branch)
		var brow_tine = CylinderMesh.new()
		brow_tine.top_radius = 0.02
		brow_tine.bottom_radius = 0.04
		brow_tine.height = 0.35
		brow_tine.material = _stag_gold_mat
		var brow_inst = MeshInstance3D.new()
		brow_inst.mesh = brow_tine
		brow_inst.position = Vector3(side * 0.22, 0.22, 0.14)
		brow_inst.rotation = Vector3(deg_to_rad(-35.0), side * deg_to_rad(-15.0), side * deg_to_rad(-15.0))
		_antlers_node.add_child(brow_inst)

		# Crown Fork (top branching points)
		var crown_tine = CylinderMesh.new()
		crown_tine.top_radius = 0.015
		crown_tine.bottom_radius = 0.035
		crown_tine.height = 0.42
		crown_tine.material = _stag_gold_mat
		var crown_inst = MeshInstance3D.new()
		crown_inst.mesh = crown_tine
		crown_inst.position = Vector3(side * 0.48, 0.72, -0.14)
		crown_inst.rotation = Vector3(deg_to_rad(15.0), side * deg_to_rad(-32.0), side * deg_to_rad(-45.0))
		_antlers_node.add_child(crown_inst)

func _process(delta: float) -> void:
	_anim_time += delta
	_state_timer -= delta
	if _communion_cooldown > 0.0:
		_communion_cooldown -= delta

	# Antler Breathing Radiance
	if _antler_light:
		var pulse: float = 1.2 + sin(_anim_time * 2.2) * 0.45
		_antler_light.light_energy = pulse

	# Tail gentle swish
	if _tail_pivot:
		_tail_pivot.rotation.y = sin(_anim_time * 3.5) * 0.25

	match current_state:
		StagState.SERENE_GRAZING:
			_update_grazing(delta)
		StagState.MAJESTIC_STRIDE:
			_update_stride(delta)
		StagState.ALERT_REGAL:
			_update_alert(delta)
		StagState.SACRED_COMMUNING:
			_update_communing(delta)
		StagState.SPIRIT_LEAP:
			_update_leap(delta)

	_clamp_to_terrain()

func _update_grazing(delta: float) -> void:
	# Head dips down slowly to graze
	if _neck_pivot:
		_neck_pivot.rotation.x = lerp_angle(_neck_pivot.rotation.x, deg_to_rad(-22.0), delta * 2.0)
	if _head_pivot:
		_head_pivot.rotation.x = lerp_angle(_head_pivot.rotation.x, deg_to_rad(-28.0), delta * 2.0)

	# Gentle breathing heave
	if _body_pivot:
		_body_pivot.position.y = sin(_anim_time * 1.8) * 0.02

	if _state_timer <= 0.0:
		_pick_new_wander_target()
		current_state = StagState.MAJESTIC_STRIDE
		_state_timer = randf_range(4.0, 7.5)

func _update_stride(delta: float) -> void:
	# Regal high neck carriage
	if _neck_pivot:
		_neck_pivot.rotation.x = lerp_angle(_neck_pivot.rotation.x, deg_to_rad(12.0), delta * 3.0)
	if _head_pivot:
		_head_pivot.rotation.x = lerp_angle(_head_pivot.rotation.x, deg_to_rad(6.0), delta * 3.0)

	# Steer towards target
	var to_target: Vector3 = _target_pos - position
	to_target.y = 0.0
	var dist: float = to_target.length()

	if dist > 0.8:
		var move_dir: Vector3 = to_target.normalized()
		_target_yaw = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, _target_yaw, delta * 3.5)
		position += move_dir * WALK_SPEED * delta

		# 4-Leg Trot Animation
		var leg_swing: float = sin(_anim_time * 6.5) * 0.45
		if _legs.size() >= 4:
			_legs[0].rotation.x = leg_swing
			_legs[1].rotation.x = -leg_swing
			_legs[2].rotation.x = -leg_swing
			_legs[3].rotation.x = leg_swing

		if _body_pivot:
			_body_pivot.position.y = absf(sin(_anim_time * 6.5)) * 0.04
	else:
		# Arrived at wander point
		current_state = StagState.SERENE_GRAZING
		_state_timer = randf_range(3.5, 6.0)
		_reset_legs()

	if _state_timer <= 0.0:
		current_state = StagState.SERENE_GRAZING
		_state_timer = randf_range(3.5, 6.0)
		_reset_legs()

func _update_alert(delta: float) -> void:
	# Erect regal posture facing threat/player
	if _neck_pivot:
		_neck_pivot.rotation.x = lerp_angle(_neck_pivot.rotation.x, deg_to_rad(22.0), delta * 4.0)
	if _head_pivot:
		_head_pivot.rotation.x = lerp_angle(_head_pivot.rotation.x, deg_to_rad(10.0), delta * 4.0)

	_reset_legs()

	if _state_timer <= 0.0:
		current_state = StagState.SERENE_GRAZING
		_state_timer = randf_range(3.0, 5.0)

func _update_communing(delta: float) -> void:
	# Bow head gently in sacred communion
	if _neck_pivot:
		_neck_pivot.rotation.x = lerp_angle(_neck_pivot.rotation.x, deg_to_rad(-14.0), delta * 2.5)
	if _head_pivot:
		_head_pivot.rotation.x = lerp_angle(_head_pivot.rotation.x, deg_to_rad(-16.0), delta * 2.5)

	if _state_timer <= 0.0:
		current_state = StagState.MAJESTIC_STRIDE
		_pick_new_wander_target()
		_state_timer = 5.0

func _update_leap(delta: float) -> void:
	var to_target: Vector3 = _target_pos - position
	to_target.y = 0.0
	if to_target.length() > 0.5:
		var move_dir: Vector3 = to_target.normalized()
		position += move_dir * LEAP_SPEED * delta
		rotation.y = lerp_angle(rotation.y, atan2(-move_dir.x, -move_dir.z), delta * 5.0)
		if _body_pivot:
			_body_pivot.position.y = sin(_anim_time * 8.0) * 0.35
	else:
		current_state = StagState.ALERT_REGAL
		_state_timer = 3.0
		_reset_legs()

func _reset_legs() -> void:
	for leg in _legs:
		leg.rotation.x = 0.0
	if _body_pivot:
		_body_pivot.position.y = 0.0

func _pick_new_wander_target() -> void:
	var angle: float = randf_range(0.0, TAU)
	var r: float = randf_range(4.0, _wander_radius)
	_target_pos = _home_pos + Vector3(cos(angle) * r, 0.0, sin(angle) * r)

func _clamp_to_terrain() -> void:
	if _terrain_ref and _terrain_ref.has_method("get_height_at"):
		var h: float = _terrain_ref.get_height_at(position.x, position.z)
		position.y = h

func is_player_near(p_pos: Vector3, threshold: float = INTERACTION_DIST) -> bool:
	var p_cur = global_position if is_inside_tree() else position
	return p_cur.distance_to(p_pos) <= threshold

func alert_to_player(player_pos: Vector3) -> void:
	if current_state == StagState.SACRED_COMMUNING:
		return
	var to_player: Vector3 = player_pos - position
	to_player.y = 0.0
	if to_player.length() > 0.1:
		_target_yaw = atan2(-to_player.x, -to_player.z)
		rotation.y = _target_yaw
	current_state = StagState.ALERT_REGAL
	_state_timer = 4.0
	if not _has_spotted:
		_has_spotted = true
		stag_spotted.emit(position)

func perform_communion() -> Dictionary:
	_has_communed = true
	_communion_cooldown = 180.0
	current_state = StagState.SACRED_COMMUNING
	_state_timer = 4.0

	# Play ethereal bugle call
	if _audio_player and is_inside_tree():
		_audio_player.play()

	# Emit burst of stardust particles
	if _stardust_particles and is_inside_tree():
		_stardust_particles.restart()

	var reward: Dictionary = {
		"exp": 300,
		"coins": 100,
		"item": "mythic_star_antler",
		"item_title": "Gạc Hươu Tinh Tú Huyền Thoại",
		"buff": "spirit_stag_blessing",
		"buff_title": "Phúc Lành Bạch Hươu",
		"duration": 120.0,
		"desc": "Tốc độ chạy bứt phá +25%, tiêu hao thể lực giảm 40%, gót chân tỏa hạt vàng kim."
	}
	stag_communed.emit(reward)
	return reward

static func _generate_mythic_stag_bugle_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 2.4
	var total_samples: int = int(sample_rate * duration)
	var byte_data = PackedByteArray()
	byte_data.resize(total_samples * 2)

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)

		# Pitch envelope: rises from 196Hz (G3) to 392Hz (G4), swells, then resolves
		var freq: float = 196.0 + 196.0 * sin(minf(t * 1.2, PI * 0.5))
		if t > 1.2:
			freq = lerpf(freq, 293.66, (t - 1.2) / 1.2) # Resolves to D4 (293.66Hz)

		# Fundamental + 2nd harmonic + 3rd harmonic bell shimmer
		var fundamental = sin(TAU * freq * t)
		var second_harm = 0.45 * sin(TAU * (freq * 2.0) * t)
		var bell_shimmer = 0.22 * sin(TAU * (freq * 3.0) * t) * (1.0 + sin(TAU * 12.0 * t) * 0.25)

		# Envelope: 0.25s attack, sustain, gentle tail decay
		var env: float = 1.0
		if t < 0.25:
			env = t / 0.25
		else:
			env = exp(-1.2 * (t - 0.25))

		var wave: float = (fundamental + second_harm + bell_shimmer) * env * 0.75
		var sample_val: int = int(clampf(wave, -1.0, 1.0) * 32767.0)

		byte_data.encode_s16(i * 2, sample_val)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = byte_data
	return stream
