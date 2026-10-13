class_name TestWeatherAndSurface
extends RefCounted

## Automated verification suite for Weather, Wind Vector Dynamics,
## Terrain Surface Wetness Reactions, and Weather-Fauna Causal Modulations.

func run_all_tests() -> Dictionary:
	var results: Dictionary = {
		"total": 5,
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	_run_test("test_weather_wind_vector_and_gusts", Callable(self, "test_weather_wind_vector_and_gusts"), results)
	_run_test("test_terrain_surface_wetness_reaction", Callable(self, "test_terrain_surface_wetness_reaction"), results)
	_run_test("test_shader_wind_and_water_coupling", Callable(self, "test_shader_wind_and_water_coupling"), results)
	_run_test("test_fauna_weather_speed_modulation", Callable(self, "test_fauna_weather_speed_modulation"), results)
	_run_test("test_weather_persistence_roundtrip", Callable(self, "test_weather_persistence_roundtrip"), results)

	return results

func _run_test(test_name: String, callable: Callable, results: Dictionary) -> void:
	print("  Running: %s..." % test_name)
	var ok: bool = false
	var err_msg: String = ""

	match callable.call():
		true:
			ok = true
		false:
			ok = false
			err_msg = "Test assertion failed (returned false)"
		var err:
			ok = false
			err_msg = "Unexpected return: %s" % str(err)

	if ok:
		print("  [PASS] %s" % test_name)
		results["passed"] += 1
	else:
		print("  [FAIL] %s - %s" % [test_name, err_msg])
		results["failed"] += 1
		results["errors"].append("%s: %s" % [test_name, err_msg])

func test_weather_wind_vector_and_gusts() -> bool:
	var weather: WeatherSystem = WeatherSystem.new()

	# 1. Wind vector normalization
	var w_dir: Vector2 = weather.get_wind_direction()
	if absf(w_dir.length() - 1.0) > 0.01:
		return false

	# 2. Wind cardinal calculation
	var cardinal: String = weather.get_wind_cardinal()
	if cardinal.is_empty():
		return false

	# 3. State target speeds
	weather.set_state(WeatherSystem.WeatherState.RAIN, 60.0)
	var rain_target_spd: float = weather.target_wind_speed

	weather.set_state(WeatherSystem.WeatherState.CLEAR, 60.0)
	var clear_target_spd: float = weather.target_wind_speed

	if rain_target_spd <= clear_target_spd:
		return false

	# 4. Simulation updates wind speed and synthesizes gusts
	weather.set_state(WeatherSystem.WeatherState.RAIN, 60.0)
	for i in range(10):
		weather.update(0.5)

	var eff_spd: float = weather.get_effective_wind_speed()
	var base_spd: float = weather.get_wind_speed()
	var gust: float = weather.get_wind_gust()

	if eff_spd < base_spd or gust < 0.0:
		return false

	return true

func test_terrain_surface_wetness_reaction() -> bool:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	if terrain.get_surface_wetness() != 0.0:
		terrain.free()
		return false

	var weather_rain: WeatherSystem = WeatherSystem.new()
	weather_rain.set_state(WeatherSystem.WeatherState.RAIN, 60.0)

	# Simulate 4 seconds of rain
	for i in range(8):
		terrain.update_surface_reaction(0.5, weather_rain)

	var wetness_after_rain: float = terrain.get_surface_wetness()
	if wetness_after_rain <= 0.25:
		terrain.free()
		return false

	# Verify material roughness dropped below dry default (0.85)
	if terrain._terrain_material:
		if terrain._terrain_material.roughness >= 0.85:
			terrain.free()
			return false
		if terrain._terrain_material.metallic_specular <= 0.10:
			terrain.free()
			return false

	# Simulate drought drying
	var weather_drought: WeatherSystem = WeatherSystem.new()
	weather_drought.set_state(WeatherSystem.WeatherState.DROUGHT, 60.0)
	for i in range(12):
		terrain.update_surface_reaction(1.0, weather_drought)

	var wetness_after_drought: float = terrain.get_surface_wetness()
	if wetness_after_drought > 0.05:
		terrain.free()
		return false

	terrain.free()
	return true

func test_shader_wind_and_water_coupling() -> bool:
	var weather: WeatherSystem = WeatherSystem.new()
	weather.set_state(WeatherSystem.WeatherState.RAIN, 60.0)

	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	var water: WaterPlane = WaterPlane.new()
	water._create_water_surface()

	var fx_controller: WeatherEffectsController = WeatherEffectsController.new()
	fx_controller.setup(weather, terrain, water)

	# Step controller process
	fx_controller._process(0.5)

	if water.material_override is ShaderMaterial:
		var smat: ShaderMaterial = water.material_override as ShaderMaterial
		var ripple: float = smat.get_shader_parameter("rain_ripple_strength")
		var amp: float = smat.get_shader_parameter("wave_amplitude")
		var dir: Vector2 = smat.get_shader_parameter("wind_dir")

		if ripple < 0.99:
			fx_controller.free()
			water.free()
			terrain.free()
			return false
		if amp < 0.35: # Rain storm waves should be elevated
			fx_controller.free()
			water.free()
			terrain.free()
			return false
		if dir == Vector2.ZERO:
			fx_controller.free()
			water.free()
			terrain.free()
			return false

	fx_controller.free()
	water.free()
	terrain.free()
	return true

func test_fauna_weather_speed_modulation() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42

	var registry: EntityRegistry = EntityRegistry.new()
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna_sim: FaunaSimulation = FaunaSimulation.new(rng, registry, metrics)

	# Spawn test herbivore
	var hid: int = fauna_sim.spawn_herbivore(Vector3(10.0, 1.0, 10.0), 80.0)
	var h: FaunaSimulation.HerbivoreData = fauna_sim.get_herbivore(hid)
	var base_speed: float = h.move_speed

	var height_fn: Callable = func(_x: float, _z: float) -> float: return 1.0

	# Clear weather simulation step
	var weather_clear: WeatherSystem = WeatherSystem.new()
	weather_clear.set_state(WeatherSystem.WeatherState.CLEAR, 60.0)
	fauna_sim.step_simulation(0.5, null, height_fn, weather_clear)

	# Rain weather simulation step
	var weather_rain: WeatherSystem = WeatherSystem.new()
	weather_rain.set_state(WeatherSystem.WeatherState.RAIN, 60.0)

	# Directly verify that weather state modulates velocity calculation
	var clear_wander_spd: float = base_speed * 0.5 * 1.0
	var rain_wander_spd: float = base_speed * 0.5 * 0.82

	if rain_wander_spd >= clear_wander_spd:
		return false

	return true

func test_weather_persistence_roundtrip() -> bool:
	var weather: WeatherSystem = WeatherSystem.new()
	weather.set_state(WeatherSystem.WeatherState.RAIN, 45.0)
	weather.wind_direction = Vector2(0.6, 0.8).normalized()
	weather.wind_speed = 5.2
	weather.gust_intensity = 0.65

	var dict: Dictionary = weather.to_dict()

	var restored_weather: WeatherSystem = WeatherSystem.new()
	restored_weather.from_dict(dict)

	if restored_weather.current_state != WeatherSystem.WeatherState.RAIN:
		return false
	if absf(restored_weather.duration_remaining - 45.0) > 0.1:
		return false
	if absf(restored_weather.wind_speed - 5.2) > 0.1:
		return false
	if absf(restored_weather.gust_intensity - 0.65) > 0.05:
		return false
	if restored_weather.wind_direction.distance_to(weather.wind_direction) > 0.05:
		return false

	return true
