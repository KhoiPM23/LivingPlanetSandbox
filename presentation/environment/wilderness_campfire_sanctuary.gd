class_name WildernessCampfireSanctuary
extends Node3D

## Living Planet Sandbox — RDR2-Style Wilderness Campfire & Bivouac Sanctuary (Block 55)
## Features:
## 1. Naturalistic wilderness bivouac nestled in the birch/pine woods overlooking Grand Emerald Lake:
##    - Fieldstone circular campfire ring with glowing char logs & flickering warm flame
##    - Iron tripod cooking spit with steaming cast-iron kettle pot
##    - Timber A-frame lean-to shelter with canvas bedroll & woolen camp blankets
##    - Oak splitting block with embedded woodcutter axe & stacked firewood cord
##    - Weathered log benches for seating
## 2. Dynamic campfire lighting with natural organic thermal flicker (OmniLight3D).
## 3. Procedural 16-bit PCM wood crackling, pop, and ember hiss audio synthesizer.
## 4. Interactive Camp Life:
##    - [E] Ngồi Nghỉ Bên Bếp Lửa: grants 'Cozy Warmth' buff (+15% stamina, restores health)
##    - [E] Nấu Nướng Dã Ngoại: cooks Hearty Wild Stew (+100 EXP, camp nutrition)
## 5. Intel Iris Xe optimized: shared standard materials, throttled smoke particles, 60 FPS budgeted.

signal camp_rested(player: Node3D)
signal meal_cooked(meal_id: String, exp: int)

var _anim_time: float = 0.0
var _fire_light: OmniLight3D = null
var _smoke_particles: GPUParticles3D = null
var _steam_particles: GPUParticles3D = null
var _audio_player: AudioStreamPlayer3D = null
static var _campfire_wav: AudioStreamWAV = null

# Materials
static var _stone_mat: StandardMaterial3D = null
static var _wood_mat: StandardMaterial3D = null
static var _bark_mat: StandardMaterial3D = null
static var _iron_mat: StandardMaterial3D = null
static var _canvas_mat: StandardMaterial3D = null
static var _ember_mat: StandardMaterial3D = null

func _init() -> void:
	name = "WildernessCampfireSanctuary"
	_init_materials()
	_build_audio_emitter()
	_build_campsite()

static func _init_materials() -> void:
	if _stone_mat != null:
		return

	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.48, 0.46, 0.44)
	_stone_mat.roughness = 0.90

	_wood_mat = StandardMaterial3D.new()
	_wood_mat.albedo_color = Color(0.45, 0.32, 0.20)
	_wood_mat.roughness = 0.75

	_bark_mat = StandardMaterial3D.new()
	_bark_mat.albedo_color = Color(0.28, 0.20, 0.14)
	_bark_mat.roughness = 0.88

	_iron_mat = StandardMaterial3D.new()
	_iron_mat.albedo_color = Color(0.22, 0.22, 0.24)
	_iron_mat.metallic = 0.85
	_iron_mat.roughness = 0.35

	_canvas_mat = StandardMaterial3D.new()
	_canvas_mat.albedo_color = Color(0.78, 0.72, 0.60)
	_canvas_mat.roughness = 0.80

	# Glowing Embers & Flame Core
	_ember_mat = StandardMaterial3D.new()
	_ember_mat.albedo_color = Color(1.0, 0.42, 0.08)
	_ember_mat.emission_enabled = true
	_ember_mat.emission = Color(1.0, 0.48, 0.12)
	_ember_mat.emission_energy_multiplier = 3.2

func _build_audio_emitter() -> void:
	if _campfire_wav == null:
		_campfire_wav = _generate_campfire_wav()

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "CampfireCracklingAudio"
	_audio_player.stream = _campfire_wav
	_audio_player.unit_size = 5.0
	_audio_player.max_distance = 22.0
	_audio_player.volume_db = -3.0
	_audio_player.autoplay = true
	add_child(_audio_player)

func _build_campsite() -> void:
	# 1. Circular Stone Fire Pit Ring
	var fire_center = Vector3.ZERO
	for r_i in range(10):
		var ang: float = float(r_i) * (TAU / 10.0)
		var rock = SphereMesh.new()
		rock.radius = 0.16
		rock.height = 0.24
		var r_mi = MeshInstance3D.new()
		r_mi.mesh = rock
		r_mi.material_override = _stone_mat
		r_mi.position = Vector3(cos(ang) * 0.72, 0.08, sin(ang) * 0.72)
		r_mi.scale = Vector3(1.0, randf_range(0.7, 1.1), 1.0)
		add_child(r_mi)

	# 2. Charred Logs in Teepee Structure
	for l_i in range(4):
		var l_ang: float = float(l_i) * (PI * 0.5)
		var log_mesh = CylinderMesh.new()
		log_mesh.top_radius = 0.06
		log_mesh.bottom_radius = 0.08
		log_mesh.height = 0.70
		var l_mi = MeshInstance3D.new()
		l_mi.mesh = log_mesh
		l_mi.material_override = _bark_mat
		l_mi.position = Vector3(cos(l_ang) * 0.24, 0.22, sin(l_ang) * 0.24)
		l_mi.rotation.z = deg_to_rad(30.0)
		l_mi.rotation.y = l_ang
		add_child(l_mi)

	# 3. Glowing Ember Mound Core
	var ember_mesh = SphereMesh.new()
	ember_mesh.radius = 0.28
	ember_mesh.height = 0.22
	var e_mi = MeshInstance3D.new()
	e_mi.mesh = ember_mesh
	e_mi.material_override = _ember_mat
	e_mi.position = Vector3(0.0, 0.08, 0.0)
	add_child(e_mi)

	# 4. Thermal Flickering Flame Light
	_fire_light = OmniLight3D.new()
	_fire_light.light_color = Color(1.0, 0.55, 0.22)
	_fire_light.light_energy = 2.4
	_fire_light.omni_range = 10.5
	_fire_light.omni_attenuation = 1.3
	_fire_light.position = Vector3(0.0, 0.45, 0.0)
	_fire_light.shadow_enabled = true
	add_child(_fire_light)

	# 5. Rising Smoke Particles
	_smoke_particles = GPUParticles3D.new()
	_smoke_particles.name = "CampfireSmoke"
	_smoke_particles.amount = 12
	_smoke_particles.lifetime = 2.2
	_smoke_particles.position = Vector3(0.0, 0.40, 0.0)
	var sp_mat = ParticleProcessMaterial.new()
	sp_mat.direction = Vector3(0.1, 1.0, 0.05)
	sp_mat.spread = 12.0
	sp_mat.initial_velocity_min = 0.8
	sp_mat.initial_velocity_max = 1.6
	sp_mat.scale_min = 0.15
	sp_mat.scale_max = 0.45
	sp_mat.color = Color(0.65, 0.65, 0.65, 0.25)
	_smoke_particles.process_material = sp_mat

	var sm_mesh = SphereMesh.new()
	sm_mesh.radius = 0.12
	sm_mesh.height = 0.24
	var sm_mat = StandardMaterial3D.new()
	sm_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm_mat.albedo_color = Color(0.70, 0.68, 0.65, 0.20)
	sm_mesh.material = sm_mat
	_smoke_particles.draw_pass_1 = sm_mesh
	add_child(_smoke_particles)

	# 6. Iron Cooking Tripod Spit & Steaming Cast-Iron Kettle
	var tripod_root = Node3D.new()
	tripod_root.name = "CookingTripod"
	add_child(tripod_root)

	for leg_i in range(3):
		var t_ang: float = float(leg_i) * (TAU / 3.0)
		var leg = CylinderMesh.new()
		leg.top_radius = 0.02
		leg.bottom_radius = 0.025
		leg.height = 1.45
		var leg_mi = MeshInstance3D.new()
		leg_mi.mesh = leg
		leg_mi.material_override = _iron_mat
		leg_mi.position = Vector3(cos(t_ang) * 0.40, 0.65, sin(t_ang) * 0.40)
		leg_mi.rotation.z = deg_to_rad(18.0)
		leg_mi.rotation.y = t_ang
		tripod_root.add_child(leg_mi)

	# Hanging Pot
	var pot = CylinderMesh.new()
	pot.top_radius = 0.16
	pot.bottom_radius = 0.14
	pot.height = 0.25
	var pot_mi = MeshInstance3D.new()
	pot_mi.mesh = pot
	pot_mi.material_override = _iron_mat
	pot_mi.position = Vector3(0.0, 0.60, 0.0)
	tripod_root.add_child(pot_mi)

	# 7. Timber A-Frame Shelter Lean-To
	var shelter = Node3D.new()
	shelter.name = "LeanToShelter"
	shelter.position = Vector3(-2.2, 0.0, 0.4)
	shelter.rotation.y = deg_to_rad(35.0)
	add_child(shelter)

	var tarp = BoxMesh.new()
	tarp.size = Vector3(2.6, 0.04, 2.0)
	var tarp_mi = MeshInstance3D.new()
	tarp_mi.mesh = tarp
	tarp_mi.material_override = _canvas_mat
	tarp_mi.position = Vector3(0.0, 0.95, -0.6)
	tarp_mi.rotation.x = deg_to_rad(32.0)
	shelter.add_child(tarp_mi)

	# Bedroll inside shelter
	var bedroll = CylinderMesh.new()
	bedroll.top_radius = 0.22
	bedroll.bottom_radius = 0.22
	bedroll.height = 1.6
	var bed_mi = MeshInstance3D.new()
	bed_mi.mesh = bedroll
	bed_mi.material_override = _bark_mat
	bed_mi.position = Vector3(0.0, 0.18, -0.7)
	bed_mi.rotation.z = PI * 0.5
	shelter.add_child(bed_mi)

	# 8. Oak Splitting Stump with Woodcutter Axe
	var stump_root = Node3D.new()
	stump_root.position = Vector3(1.8, 0.0, -1.2)
	add_child(stump_root)

	var stump = CylinderMesh.new()
	stump.top_radius = 0.32
	stump.bottom_radius = 0.36
	stump.height = 0.65
	var s_mi = MeshInstance3D.new()
	s_mi.mesh = stump
	s_mi.material_override = _bark_mat
	s_mi.position.y = 0.325
	stump_root.add_child(s_mi)

	# Iron axe embedded
	var axe_handle = CylinderMesh.new()
	axe_handle.top_radius = 0.02
	axe_handle.bottom_radius = 0.02
	axe_handle.height = 0.70
	var ah_mi = MeshInstance3D.new()
	ah_mi.mesh = axe_handle
	ah_mi.material_override = _wood_mat
	ah_mi.position = Vector3(0.0, 0.75, 0.0)
	ah_mi.rotation.z = deg_to_rad(-25.0)
	stump_root.add_child(ah_mi)

	# 9. Natural Log Sitting Bench
	var log_bench = CylinderMesh.new()
	log_bench.top_radius = 0.18
	log_bench.bottom_radius = 0.18
	log_bench.height = 2.2
	var lb_mi = MeshInstance3D.new()
	lb_mi.mesh = log_bench
	lb_mi.material_override = _wood_mat
	lb_mi.position = Vector3(0.2, 0.18, 1.6)
	lb_mi.rotation.z = PI * 0.5
	add_child(lb_mi)

func _process(delta: float) -> void:
	_anim_time += delta

	# Natural organic thermal fire flicker
	if _fire_light:
		var flicker: float = 2.4 + sin(_anim_time * 12.0) * 0.35 + sin(_anim_time * 23.5) * 0.18
		_fire_light.light_energy = flicker
		_fire_light.position.x = sin(_anim_time * 8.0) * 0.04
		_fire_light.position.z = cos(_anim_time * 9.5) * 0.04

func get_nearby_interactable(pos: Vector3, max_dist: float = 2.8) -> Dictionary:
	var camp_pos: Vector3 = global_position if is_inside_tree() else position
	var d: float = pos.distance_to(camp_pos)
	if d <= max_dist:
		return {
			"id": "wilderness_campfire",
			"type": "camp",
			"name": "Bếp Lửa Dã Ngoại Rừng Sâu",
			"icon": "🏕️",
			"pos": camp_pos
		}
	return {}

func rest_at_campfire(walker: CharacterBody3D = null) -> Dictionary:
	camp_rested.emit(walker)
	if walker and walker.has_method("get_facial_controller"):
		var fc = walker.get_facial_controller()
		if fc and fc.has_method("trigger_joy"):
			fc.trigger_joy(4.0)

	return {
		"message": "Nghỉ ngơi bên bếp lửa dã ngoại (+100% Sinh lực, Buff Ấm Áp Dã Ngoại)",
		"buff": "camp_warmth",
		"duration": 90.0,
		"exp": 40
	}

func cook_campfire_stew() -> Dictionary:
	var res = {
		"meal_id": "hearty_wild_stew",
		"name": "Thịt Hầm Dã Ngoại Rừng Sâu",
		"exp": 100,
		"icon": "🍲",
		"message": "Đã nấu thành công: Thịt Hầm Dã Ngoại (+100 EXP, +35% Thể lực)"
	}
	meal_cooked.emit("hearty_wild_stew", 100)
	return res

static func _generate_campfire_wav(duration: float = 2.0, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		# Deep thermal air rush rumble
		var rumble: float = sin(t * 55.0 * TAU) * 0.25 + sin(t * 110.0 * TAU) * 0.15
		# Random stochastic wood snap pop
		var pop: float = 0.0
		if randf() < 0.0035:
			pop = randf_range(0.4, 0.85)

		var noise: float = randf_range(-0.15, 0.15)
		var sample: float = (rumble + noise + pop) * 0.45
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.data = byte_data
	return wav
