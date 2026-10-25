class_name TestBlock22Verification
extends RefCounted

## Verification Suite for Block 22 & Addendum:
## Living World Audio & Behavioral Feedback, Movement/Animation Alignment,
## Natural World Interaction, Celestial Sky & Forest Biome Expansion.

const SpatialAudioDirectorScript = preload("res://presentation/audio/spatial_audio_director.gd")
const FirstPersonWalkerScript = preload("res://presentation/camera/first_person_walker.gd")
const EcosystemPresentationScript = preload("res://presentation/ecosystem/ecosystem_presentation.gd")
const DayNightCycleScript = preload("res://presentation/environment/day_night_cycle.gd")
const VegetationScatterScript = preload("res://presentation/environment/vegetation_scatter.gd")

func _flat_height(_x: float, _z: float) -> float:
	return 2.5

## 1. P0: Character & Wildlife forward axis alignment (+Z model mesh aligned to Godot -Z)
func test_character_and_fauna_forward_orientation() -> String:
	# A. Player character model orientation
	var walker: FirstPersonWalker = FirstPersonWalker.new()
	if walker._character_instance:
		if not is_equal_approx(walker._character_instance.rotation.y, PI):
			var r_y: float = walker._character_instance.rotation.y
			walker.free()
			return "Player character instance rotation.y is not PI (got %.3f); forward axis misaligned." % r_y
	walker.free()

	# B. Wildlife presentation model rotation
	var eco_pres: EcosystemPresentation = EcosystemPresentation.new()
	var h_mesh: Node3D = eco_pres._create_herbivore_mesh()
	if h_mesh:
		var model_node: Node3D = h_mesh.get_node_or_null("Model") as Node3D
		if model_node:
			if not is_equal_approx(model_node.rotation.y, PI):
				var r_y: float = model_node.rotation.y
				h_mesh.free()
				eco_pres.free()
				return "Herbivore model instance rotation.y is not PI (got %.3f); animal moves backward." % r_y
		h_mesh.free()

	var p_mesh: Node3D = eco_pres._create_predator_mesh()
	if p_mesh:
		var model_node: Node3D = p_mesh.get_node_or_null("Model") as Node3D
		if model_node:
			if not is_equal_approx(model_node.rotation.y, PI):
				var r_y: float = model_node.rotation.y
				p_mesh.free()
				eco_pres.free()
				return "Predator model instance rotation.y is not PI (got %.3f); predator moves backward." % r_y
		p_mesh.free()
	eco_pres.free()

	# C. Verify heading rotation angle math
	# In Godot: forward is -Z (angle 0.0), right is +X (angle -PI/2), left is -X (angle +PI/2)
	var forward_vel: Vector3 = Vector3(0.0, 0.0, -2.5)
	var rot_y: float = atan2(-forward_vel.x, -forward_vel.z)
	if not is_zero_approx(rot_y):
		return "Forward velocity (0, 0, -1) did not produce 0.0 rotation angle (got %.3f)." % rot_y

	return ""

## 2. P0: Fauna avoidance & player distance hysteresis (no magnetic repulsion when still)
func test_fauna_flight_and_alert_hysteresis() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 445566
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var bus: WorldEventBus = WorldEventBus.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics, bus)

	var alarm_events: Array[Dictionary] = []
	bus.subscribe("herd_alarm", func(p: Dictionary) -> void:
		alarm_events.append(p)
	)

	# Spawn deer at (10.0, 2.5, 10.0)
	var hid: int = fauna.spawn_herbivore(Vector3(10.0, 2.5, 10.0), 85.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)

	# 1. Player is stationary at 11m: deer enters ALERT (vigilance) without fleeing or magnetic repulsion
	fauna.set_player_presence(Vector3(21.0, 2.5, 10.0), true, 0.0)
	fauna.step_simulation(0.3, null, Callable(self, "_flat_height"))

	if h.state != FaunaSimulation.HerbivoreState.ALERT:
		return "Stationary player at 11m caused state %d instead of ALERT vigilance." % h.state

	var had_panic: bool = false
	for ev in alarm_events:
		if ev.get("panic", false):
			had_panic = true
	if had_panic:
		return "Stationary player at 11m triggered panic herd alarm unexpectedly."

	# 2. Fast sprint approach: triggers FLEEING and panic herd alarm
	alarm_events.clear()
	fauna._player_speed = 4.5 # Fast sprint
	fauna.step_simulation(0.3, null, Callable(self, "_flat_height"))

	if h.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "Sprint approach within 12m failed to trigger FLEEING (state: %d)." % h.state

	var caught_panic: bool = false
	for ev in alarm_events:
		if ev.get("panic", false):
			caught_panic = true
	if not caught_panic:
		return "Panic flight from sprint approach failed to broadcast panic herd alarm event."

	# 3. Verify alarm cooldown was applied
	if h.alarm_cooldown <= 0.0:
		return "Herd alarm cooldown was not set on fleeing animal."

	return ""

## 3. Workstream A: Spatial Audio 3-Voice Pool & Procedural Sound Synthesis
func test_spatial_audio_voice_pool_and_generators() -> String:
	var audio_dir: SpatialAudioDirector = SpatialAudioDirector.new()

	# A. Verify voice pool initialization
	audio_dir._setup_fauna_audio()
	if audio_dir._fauna_voices.size() != 3:
		var sz: int = audio_dir._fauna_voices.size()
		audio_dir.free()
		return "SpatialAudioDirector fauna voice pool size is %d (expected 3)." % sz

	if audio_dir._player_fauna != audio_dir._fauna_voices[0]:
		audio_dir.free()
		return "Primary _player_fauna alias does not match _fauna_voices[0]."

	# B. Test 3D voice allocation
	var test_stream: AudioStreamWAV = SpatialAudioDirector._generate_fauna_grunt_wav(0.2, 22050, 180.0)
	var allocated: AudioStreamPlayer3D = audio_dir.play_fauna_sound_at(test_stream, Vector3(12.0, 3.0, 8.0), -16.0)
	if not allocated:
		audio_dir.free()
		return "play_fauna_sound_at failed to allocate an AudioStreamPlayer3D voice."
	if allocated.position != Vector3(12.0, 3.0, 8.0):
		var p: Vector3 = allocated.position
		audio_dir.free()
		return "Allocated voice was not positioned at target source location (got %s)." % str(p)

	# C. Test procedural waveform generators
	var snort: AudioStreamWAV = SpatialAudioDirector._generate_deer_alarm_snort_wav(0.32, 22050)
	if not snort or snort.data.size() < 1000:
		audio_dir.free()
		return "Deer alarm snort generator returned invalid or empty audio stream."
	if snort.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		audio_dir.free()
		return "Deer alarm snort should have LOOP_DISABLED."

	var growl: AudioStreamWAV = SpatialAudioDirector._generate_wolf_growl_wav(1.2, 22050)
	if not growl or growl.data.size() < 1000:
		audio_dir.free()
		return "Wolf growl generator returned invalid or empty audio stream."

	var rain: AudioStreamWAV = SpatialAudioDirector._generate_rain_wav(2.0, 22050)
	if not rain or rain.data.size() < 1000:
		audio_dir.free()
		return "Rain audio generator returned invalid or empty audio stream."
	if rain.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		audio_dir.free()
		return "Rain audio must have LOOP_FORWARD for continuous seamless weather ambience."

	audio_dir.free()
	return ""

## 4. P1: Celestial Sun Disc & Procedural Cloud Dome Presentation
func test_celestial_sun_and_clouds_presentation() -> String:
	var cycle: DayNightCycle = DayNightCycle.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	var env: WorldEnvironment = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.sky = Sky.new()
	var p_sky: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	env.environment.sky.sky_material = p_sky

	var clock: WorldClock = WorldClock.new()
	clock.day_duration = 720.0
	clock.start_hour = 11.5
	var weather: WeatherSystem = WeatherSystem.new()

	cycle.setup(clock, sun, env, weather)

	# A. Verify sun disc calibration (realistic compact angular diameter)
	if p_sky.sun_angle_max > deg_to_rad(4.5):
		var ang: float = rad_to_deg(p_sky.sun_angle_max)
		sun.free()
		env.free()
		cycle.free()
		return "ProceduralSkyMaterial sun_angle_max is %.1f deg (expected <= 4.0 deg for crisp disc)." % ang

	# B. Verify procedural cloud dome node and shader material
	if not cycle._cloud_dome:
		sun.free()
		env.free()
		cycle.free()
		return "DayNightCycle did not instantiate _cloud_dome MeshInstance3D."

	if not cycle._cloud_mat:
		sun.free()
		env.free()
		cycle.free()
		return "DayNightCycle missing _cloud_mat ShaderMaterial."

	# C. Verify weather state coverage coupling
	weather.current_state = WeatherSystem.WeatherState.RAIN
	cycle._process(0.016)
	var rain_cov: float = cycle._cloud_mat.get_shader_parameter("cloud_coverage")
	if rain_cov < 0.80:
		sun.free()
		env.free()
		cycle.free()
		return "Rain cloud coverage is %.2f (expected >= 0.80 for overcast storm front)." % rain_cov

	weather.current_state = WeatherSystem.WeatherState.CLEAR
	cycle._process(0.016)
	var clear_cov: float = cycle._cloud_mat.get_shader_parameter("cloud_coverage")
	if clear_cov > 0.30:
		sun.free()
		env.free()
		cycle.free()
		return "Clear weather cloud coverage is %.2f (expected <= 0.30 for fair-weather sky)." % clear_cov

	sun.free()
	env.free()
	cycle.free()
	return ""

## 5. P2: Forest Biome Expansion & Multi-Species Canopy Layering
func test_forest_biome_canopy_and_understory_layers() -> String:
	VegetationScatter._init_asset_cache()

	# A. Verify caching of broadleaf deciduous trees
	var has_deciduous: bool = false
	for dk in ["tree_oak_fall", "tree_detailed_fall", "tree_default_fall"]:
		if VegetationScatter._cached_nature_props.has(dk):
			has_deciduous = true
			break
	if not has_deciduous:
		return "VegetationScatter failed to cache broadleaf deciduous trees from Nature Pack."

	# B. Verify forest floor props
	for fk in ["log", "stump_round", "mushroom_redGroup"]:
		if not VegetationScatter._cached_nature_props.has(fk):
			return "VegetationScatter missing forest-floor prop '%s'." % fk

	return ""
