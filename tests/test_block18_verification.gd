class_name TestBlock18Verification
extends RefCounted

## Automated Verification Suite for Block 18:
## Cinematic Environment, Spatial Audio & Weather Coherence.
## Verifies single authoritative WorldClock, continuous diurnal lighting/audio transitions,
## 3D positional fauna audio attenuation, multi-tier weather reaction & lingering wetness,
## preset scalability, and unscripted emergent cinematic moments.

const DayNightCycleScript = preload("res://presentation/environment/day_night_cycle.gd")

func test_authoritative_clock_lighting_and_audio_synchronization() -> String:
	var clock: WorldClock = WorldClock.new()
	var seed_obj: WorldSeed = WorldSeed.new(1337)
	var bus: WorldEventBus = WorldEventBus.new()
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	var env_node: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	var sky: Sky = Sky.new()
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env_node.environment = env

	var day_night: Node = DayNightCycleScript.new()
	day_night.setup(clock, sun, env_node, weather)

	var audio_dir: SpatialAudioDirector = SpatialAudioDirector.new()
	audio_dir.setup(clock, weather, sun, bus)

	# 1. Test Midday (12.0h)
	clock.set_sim_hour(12.0)
	day_night._process(0.016)
	audio_dir._process(0.016)

	if sun.light_energy < 1.0:
		_cleanup_nodes([sun, env_node, day_night, audio_dir])
		return "Midday sun energy too dim: %.2f (expected >= 1.0)" % sun.light_energy

	if not clock.is_daytime():
		_cleanup_nodes([sun, env_node, day_night, audio_dir])
		return "Clock reported false for is_daytime() at hour 12.0"

	# 2. Test Twilight / Sunset (18.5h) — Verify continuity, no NaN or extreme jumps
	clock.set_sim_hour(18.5)
	day_night._process(0.016)
	audio_dir._process(0.016)

	if sun.light_energy <= 0.0 or is_nan(sun.light_energy):
		_cleanup_nodes([sun, env_node, day_night, audio_dir])
		return "Twilight sun energy invalid: %.2f" % sun.light_energy

	# 3. Test Midnight (0.0h)
	clock.set_sim_hour(0.0)
	day_night._process(0.016)
	for i in range(30):
		audio_dir._process(0.1)

	if clock.is_daytime():
		_cleanup_nodes([sun, env_node, day_night, audio_dir])
		return "Clock reported true for is_daytime() at midnight 0.0h"

	if sun.light_energy > 0.40:
		_cleanup_nodes([sun, env_node, day_night, audio_dir])
		return "Midnight moonlight too bright: %.2f (expected <= 0.40)" % sun.light_energy

	# Crickets should be active at midnight
	if audio_dir._player_crickets.volume_db < -40.0:
		_cleanup_nodes([sun, env_node, day_night, audio_dir])
		return "Night crickets not fading in at midnight: %.1f dB" % audio_dir._player_crickets.volume_db

	# Birds should be silent at midnight
	if audio_dir._player_birds.volume_db > -40.0:
		_cleanup_nodes([sun, env_node, day_night, audio_dir])
		return "Day birds still loud at midnight: %.1f dB" % audio_dir._player_birds.volume_db

	# 4. Test Dawn (6.0h)
	clock.set_sim_hour(6.0)
	day_night._process(0.016)
	for i in range(30):
		audio_dir._process(0.1)

	if not clock.is_daytime():
		_cleanup_nodes([sun, env_node, day_night, audio_dir])
		return "Clock reported false for is_daytime() at dawn 6.0h"

	_cleanup_nodes([sun, env_node, day_night, audio_dir])
	return ""

func test_spatial_3d_audio_attenuation_and_localization() -> String:
	var clock: WorldClock = WorldClock.new()
	var seed_obj: WorldSeed = WorldSeed.new(1337)
	var bus: WorldEventBus = WorldEventBus.new()
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)

	var audio_dir: SpatialAudioDirector = SpatialAudioDirector.new()
	audio_dir.setup(clock, weather, null, bus)

	# 1. Verify AudioStreamPlayer3D types
	if not (audio_dir._player_fauna is AudioStreamPlayer3D):
		audio_dir.free()
		return "Fauna audio player is not an AudioStreamPlayer3D"

	if not (audio_dir._player_water is AudioStreamPlayer3D):
		audio_dir.free()
		return "Water audio player is not an AudioStreamPlayer3D"

	# 2. Verify Attenuation model
	var fauna_3d: AudioStreamPlayer3D = audio_dir._player_fauna
	if fauna_3d.attenuation_model != AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE:
		audio_dir.free()
		return "Fauna audio player does not use ATTENUATION_INVERSE_DISTANCE"

	if fauna_3d.max_distance < 40.0:
		audio_dir.free()
		return "Fauna audio max distance too short: %.1fm" % fauna_3d.max_distance

	# 3. Test 3D positioning dispatch
	var target_pos: Vector3 = Vector3(14.5, 2.0, 9.0)
	audio_dir.trigger_fauna_vocalization_at(target_pos, false)

	if fauna_3d.position.distance_to(target_pos) > 0.01:
		audio_dir.free()
		return "Fauna vocalization did not update 3D position correctly: %s vs %s" % [str(fauna_3d.position), str(target_pos)]

	# 4. Test pitch variation (anti-machine repetition)
	var pitch_samples: Array[float] = []
	for i in range(5):
		audio_dir.trigger_fauna_vocalization_at(target_pos, false)
		pitch_samples.append(fauna_3d.pitch_scale)

	var has_variation: bool = false
	for i in range(1, pitch_samples.size()):
		if abs(pitch_samples[i] - pitch_samples[0]) > 0.001:
			has_variation = true
			break

	if not has_variation:
		audio_dir.free()
		return "Fauna vocalization has zero pitch variation across calls (machine-like repetition)"

	# 5. Test EventBus publish with position payload
	bus.publish("living_world_event", {
		"type": "HERD_ALARM",
		"position": Vector3(-5.0, 4.0, 12.0)
	})

	if fauna_3d.position.distance_to(Vector3(-5.0, 4.0, 12.0)) > 0.01:
		audio_dir.free()
		return "EventBus living_world_event did not update fauna 3D position: %s" % str(fauna_3d.position)

	audio_dir.free()
	return ""

func test_multi_tier_weather_coherence_and_lingering_wetness() -> String:
	var seed_obj: WorldSeed = WorldSeed.new(1337)
	var bus: WorldEventBus = WorldEventBus.new()
	var clock: WorldClock = WorldClock.new()
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)

	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	var water: WaterPlane = WaterPlane.new()
	var water_mat: ShaderMaterial = ShaderMaterial.new()
	water_mat.shader = preload("res://presentation/shaders/water.gdshader")
	water.material_override = water_mat

	var weather_fx: WeatherEffectsController = WeatherEffectsController.new()
	weather_fx.setup(weather, terrain, water)

	var audio_dir: SpatialAudioDirector = SpatialAudioDirector.new()
	audio_dir.setup(clock, weather, null, bus)

	# 1. Force RAIN state
	weather.set_state(WeatherSystem.WeatherState.RAIN)
	# Advance 2 seconds of rain
	for i in range(20):
		weather_fx._process(0.1)
		audio_dir._process(0.1)

	if not weather_fx.is_rain_emitting():
		_cleanup_nodes([terrain, water, weather_fx, audio_dir])
		return "Rain particles not emitting during RAIN weather state"

	var rain_rip: float = float(water_mat.get_shader_parameter("rain_ripple_strength"))
	if rain_rip <= 0.5:
		_cleanup_nodes([terrain, water, weather_fx, audio_dir])
		return "Water shader rain ripple strength too low: %.2f" % rain_rip

	var wetness_after_rain: float = terrain.get_surface_wetness()
	if wetness_after_rain < 0.15:
		_cleanup_nodes([terrain, water, weather_fx, audio_dir])
		return "Terrain surface wetness did not accumulate during rain: %.2f" % wetness_after_rain

	# 2. Transition from RAIN to CLEAR
	weather.set_state(WeatherSystem.WeatherState.CLEAR)
	weather_fx._process(0.016)

	# Rain particles must stop immediately
	if weather_fx.is_rain_emitting():
		_cleanup_nodes([terrain, water, weather_fx, audio_dir])
		return "Rain particles still emitting immediately after switching to CLEAR"

	# Surface wetness MUST LINGER (physical evaporation takes time, not instant snap)
	var lingering_wetness: float = terrain.get_surface_wetness()
	if lingering_wetness < 0.10:
		_cleanup_nodes([terrain, water, weather_fx, audio_dir])
		return "Surface wetness vanished instantly upon weather clearing: %.2f (no lingering sheen)" % lingering_wetness

	# Step 5 seconds of clear weather — wetness should steadily evaporate
	for i in range(50):
		weather_fx._process(0.1)
		audio_dir._process(0.1)

	var dried_wetness: float = terrain.get_surface_wetness()
	if dried_wetness >= lingering_wetness:
		_cleanup_nodes([terrain, water, weather_fx, audio_dir])
		return "Surface wetness did not evaporate during CLEAR weather (before: %.2f, after: %.2f)" % [lingering_wetness, dried_wetness]

	_cleanup_nodes([terrain, water, weather_fx, audio_dir])
	return ""

func test_atmospheric_depth_contrast_and_preset_scalability() -> String:
	var root: Node3D = Node3D.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	root.add_child(sun)

	var env_node: WorldEnvironment = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env: Environment = Environment.new()
	env_node.environment = env
	root.add_child(env_node)

	# 1. Test BALANCED Preset (Intel Iris Xe optimized profile)
	var bal_changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.BALANCED, root)

	if sun.directional_shadow_mode != DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS:
		root.free()
		return "Balanced preset does not use 2-split directional shadows"

	if sun.directional_shadow_max_distance > 70.0:
		root.free()
		return "Balanced shadow max distance too high for Iris Xe: %.1fm (expected <= 70m)" % sun.directional_shadow_max_distance

	if env.ssao_enabled != false:
		root.free()
		return "Balanced preset must keep SSAO disabled to prevent Iris Xe memory bus saturation"

	if env.fog_enabled != true:
		root.free()
		return "Balanced preset must maintain atmospheric depth fog"

	# 2. Test CINEMATIC Preset (High fidelity profile)
	var cin_changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.CINEMATIC, root)

	if sun.directional_shadow_mode != DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS:
		root.free()
		return "Cinematic preset does not use 4-split cascaded shadows"

	if env.ssao_enabled != true:
		root.free()
		return "Cinematic preset must enable SSAO for rich contact depth"

	if env.volumetric_fog_enabled != true:
		root.free()
		return "Cinematic preset must enable volumetric fog for atmospheric sun scattering"

	root.free()
	return ""

func test_emergent_cinematic_moments_integrity() -> String:
	var seed_obj: WorldSeed = WorldSeed.new(1337)
	var bus: WorldEventBus = WorldEventBus.new()
	var clock: WorldClock = WorldClock.new()
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)

	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	var cam: Camera3D = Camera3D.new()
	cam.position = Vector3(7.5, 3.5, 3.5) # Meadow glade

	var weather_fx: WeatherEffectsController = WeatherEffectsController.new()
	weather_fx.setup(weather, terrain, null, null, cam)

	var audio_dir: SpatialAudioDirector = SpatialAudioDirector.new()
	audio_dir.setup(clock, weather, cam, bus)

	# Moment 1: Dawn Chorus & Morning Light
	clock.set_sim_hour(6.2)
	var phase: float = clock.get_day_phase()
	if phase < 0.20 or phase > 0.30:
		_cleanup_nodes([terrain, cam, weather_fx, audio_dir])
		return "Dawn solar phase out of expected range: %.2f" % phase

	# Moment 2: Alpine Snow Condition at High Altitude Summit
	weather.set_state(WeatherSystem.WeatherState.RAIN)
	# At meadow glade (Y: 3.5m), it should rain
	cam.position = Vector3(7.5, 3.5, 3.5)
	weather_fx._process(0.016)
	if not weather_fx.is_rain_emitting() or weather_fx.is_snow_emitting():
		_cleanup_nodes([terrain, cam, weather_fx, audio_dir])
		return "Meadow glade unexpectedly triggered snow instead of rain"

	# Move camera to alpine summit (Y: 15.0m) — should trigger drifting alpine snow flurries
	cam.position = Vector3(-18.0, 15.0, -18.0)
	weather_fx._process(0.016)
	if not weather_fx.is_snow_emitting() or weather_fx.is_rain_emitting():
		_cleanup_nodes([terrain, cam, weather_fx, audio_dir])
		return "Alpine summit altitude did not trigger snow flurries"

	# Moment 3: Distant 3D Wildlife Call echoing before sighting
	var deer_pos: Vector3 = Vector3(16.0, 1.2, 14.0) # Lake shore
	audio_dir.trigger_fauna_vocalization_at(deer_pos, false)
	var dist: float = cam.position.distance_to(audio_dir._player_fauna.position)
	if dist < 20.0:
		_cleanup_nodes([terrain, cam, weather_fx, audio_dir])
		return "Fauna call not distant from summit camera: %.1fm" % dist

	_cleanup_nodes([terrain, cam, weather_fx, audio_dir])
	return ""

func _cleanup_nodes(nodes: Array) -> void:
	for n in nodes:
		if n and is_instance_valid(n):
			if n is Node and n.get_parent():
				n.get_parent().remove_child(n)
			n.free()
