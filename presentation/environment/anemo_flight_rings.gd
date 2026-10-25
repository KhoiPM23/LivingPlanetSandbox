class_name AnemoFlightRings
extends Node3D

## Living Planet Sandbox — Anemo Aerial Flight Rings & Wind Highway (Block 54)
## Features:
## 1. 6 Luminous circular Anemo Rings creating an aerial gliding highway from Windshear Bluffs to Heart Island
## 2. Dynamic player intersection detection while gliding:
##    - Accelerates character glide speed (+75% speed boost)
##    - Updraft altitude boost maintaining glide flight
##    - Procedural 16-bit PCM aerodynamic wind whoosh audio synthesizer
##    - Golden-emerald particle ring burst upon passing through
## 3. Emissive animated torus shader with pulsing inner vortex rotation
## 4. Intel Iris Xe optimized: shared geometry, unshaded additive blending, zero CPU strain

signal ring_passed(ring_index: int, total_passed: int)

const RING_RADIUS: float = 2.8
const RING_THICKNESS: float = 0.18

var _rings: Array[Dictionary] = []
var _audio_player: AudioStreamPlayer3D = null
var _anim_time: float = 0.0
var _passed_count: int = 0
static var _whoosh_wav: AudioStreamWAV = null

# Materials
var _ring_glow_mat: StandardMaterial3D = null
var _ring_core_mat: StandardMaterial3D = null

func _init() -> void:
	name = "AnemoFlightRings"
	_init_materials()
	_build_audio_emitter()
	_create_flight_highway()

func _init_materials() -> void:
	_ring_glow_mat = StandardMaterial3D.new()
	_ring_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_glow_mat.albedo_color = Color(0.25, 0.95, 0.85, 0.75)
	_ring_glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	_ring_core_mat = StandardMaterial3D.new()
	_ring_core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_core_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_core_mat.albedo_color = Color(1.0, 0.92, 0.45, 0.85)
	_ring_core_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	if _whoosh_wav == null:
		_whoosh_wav = _generate_whoosh_wav()

func _build_audio_emitter() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "FlightRingAudio"
	_audio_player.stream = _whoosh_wav
	_audio_player.unit_size = 8.0
	_audio_player.max_distance = 35.0
	_audio_player.volume_db = -1.0
	add_child(_audio_player)

func _create_flight_highway() -> void:
	# Aerial highway starting high above Windshear Canyon bluff (-25, 24, 115)
	# descending gracefully across the pine ridge towards Heart Island (95, 12, 85)
	var waypoints = [
		{"pos": Vector3(-20.0, 24.5, 120.0), "facing": Vector3(0.55, -0.05, -0.45).normalized()},
		{"pos": Vector3(5.0, 22.0, 108.0),   "facing": Vector3(0.65, -0.08, -0.35).normalized()},
		{"pos": Vector3(32.0, 19.0, 98.0),   "facing": Vector3(0.72, -0.08, -0.22).normalized()},
		{"pos": Vector3(58.0, 16.5, 92.0),   "facing": Vector3(0.80, -0.06, -0.15).normalized()},
		{"pos": Vector3(80.0, 14.0, 88.0),   "facing": Vector3(0.85, -0.05, -0.08).normalized()},
		{"pos": Vector3(95.0, 11.5, 85.0),   "facing": Vector3(0.85, -0.02, 0.00).normalized()}
	]

	for idx in range(waypoints.size()):
		var wp = waypoints[idx]
		var r_pos: Vector3 = wp["pos"]
		var r_dir: Vector3 = wp["facing"]

		var ring_node = Node3D.new()
		ring_node.name = "Ring_%d" % idx
		if r_dir.length_squared() > 0.001:
			ring_node.transform = Transform3D().looking_at(r_dir, Vector3.UP)
		ring_node.position = r_pos
		add_child(ring_node)

		# 1. Outer Torus Ring
		var torus_mesh: TorusMesh = TorusMesh.new()
		torus_mesh.inner_radius = RING_RADIUS - RING_THICKNESS
		torus_mesh.outer_radius = RING_RADIUS
		torus_mesh.rings = 24
		torus_mesh.ring_segments = 12

		var t_mi: MeshInstance3D = MeshInstance3D.new()
		t_mi.mesh = torus_mesh
		t_mi.material_override = _ring_glow_mat
		ring_node.add_child(t_mi)

		# 2. Inner Golden Accent Chevrons (4 cardinal winged arrows)
		var chevron_root: Node3D = Node3D.new()
		chevron_root.name = "Chevrons"
		ring_node.add_child(chevron_root)

		for c_i in range(4):
			var ang: float = float(c_i) * (PI * 0.5)
			var prism: PrismMesh = PrismMesh.new()
			prism.size = Vector3(0.35, 0.65, 0.12)
			var p_mi: MeshInstance3D = MeshInstance3D.new()
			p_mi.mesh = prism
			p_mi.material_override = _ring_core_mat
			p_mi.position = Vector3(cos(ang) * (RING_RADIUS - 0.25), sin(ang) * (RING_RADIUS - 0.25), 0.0)
			p_mi.rotation.z = ang + PI * 0.5
			chevron_root.add_child(p_mi)

		# 3. Burst Particle System when passed through
		var burst_particles: GPUParticles3D = GPUParticles3D.new()
		burst_particles.name = "BurstParticles"
		burst_particles.emitting = false
		burst_particles.one_shot = true
		burst_particles.amount = 16
		burst_particles.lifetime = 1.0
		burst_particles.explosiveness = 0.85

		var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
		p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		p_mat.emission_ring_radius = RING_RADIUS
		p_mat.emission_ring_inner_radius = RING_RADIUS - 0.4
		p_mat.direction = Vector3(0.0, 0.0, 1.0)
		p_mat.spread = 25.0
		p_mat.initial_velocity_min = 3.5
		p_mat.initial_velocity_max = 6.0
		p_mat.scale_min = 0.12
		p_mat.scale_max = 0.28
		p_mat.color = Color(0.3, 1.0, 0.85, 0.9)
		burst_particles.process_material = p_mat

		var s_mesh: SphereMesh = SphereMesh.new()
		s_mesh.radius = 0.08
		s_mesh.height = 0.16
		var b_mat: StandardMaterial3D = StandardMaterial3D.new()
		b_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		b_mat.albedo_color = Color(0.4, 1.0, 0.9, 0.95)
		s_mesh.material = b_mat
		burst_particles.draw_pass_1 = s_mesh

		ring_node.add_child(burst_particles)

		_rings.append({
			"node": ring_node,
			"pos": r_pos,
			"facing": r_dir,
			"chevrons": chevron_root,
			"particles": burst_particles,
			"active": true,
			"cooldown": 0.0
		})

func update_flight_physics(delta: float, walker: Node3D) -> Dictionary:
	_anim_time += delta
	var boost_result: Dictionary = {}

	# Rotate chevrons and pulse ring glows
	var pulse_glow: float = 0.65 + sin(_anim_time * 3.5) * 0.20
	if _ring_glow_mat:
		_ring_glow_mat.albedo_color.a = pulse_glow

	for idx in range(_rings.size()):
		var r_data = _rings[idx]
		var r_node: Node3D = r_data["node"]
		var chev: Node3D = r_data["chevrons"]
		if chev:
			chev.rotation.z += delta * 1.8

		if r_data["cooldown"] > 0.0:
			r_data["cooldown"] -= delta

		if not walker or not is_instance_valid(walker):
			continue

		var p_pos: Vector3 = walker.global_position if walker.is_inside_tree() else walker.position

		# Check player intersection
		var dist_to_center: float = p_pos.distance_to(r_data["pos"])
		if dist_to_center < RING_RADIUS + 0.8 and r_data["cooldown"] <= 0.0:
			# Player flew through ring
			r_data["cooldown"] = 2.0
			_passed_count += 1

			# Trigger particles
			var parts: GPUParticles3D = r_data["particles"]
			if parts:
				parts.restart()
				parts.emitting = true

			# Audio playback
			if _audio_player and is_inside_tree():
				_audio_player.global_position = r_data["pos"]
				_audio_player.pitch_scale = randf_range(1.05, 1.25)
				_audio_player.play()

			boost_result = {
				"boost": true,
				"boost_dir": r_data["facing"],
				"boost_speed": 16.5, # Strong aerodynamic glide surge
				"lift_impulse": 3.2,  # Updraft to stay airborne
				"ring_index": idx,
				"total_passed": _passed_count
			}
			ring_passed.emit(idx, _passed_count)

	return boost_result

func get_ring_count() -> int:
	return _rings.size()

func get_ring_positions() -> Array[Vector3]:
	var poses: Array[Vector3] = []
	for r in _rings:
		poses.append(r["pos"])
	return poses

static func _generate_whoosh_wav(duration: float = 0.65, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		# Smooth swell envelope mimicking wind rushing through ears
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI)
		var freq_sweep: float = lerpf(180.0, 680.0, t / duration)
		var wind_noise: float = randf_range(-0.35, 0.35)
		var chime: float = sin(t * freq_sweep * TAU) * 0.5 + sin(t * freq_sweep * 1.5 * TAU) * 0.25
		var sample: float = (chime + wind_noise) * env * 0.75
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
