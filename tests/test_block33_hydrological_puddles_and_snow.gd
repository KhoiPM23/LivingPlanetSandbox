class_name TestBlock33HydrologicalPuddlesAndSnow
extends RefCounted

## Automated Contract Suite 40: Block 33 Hydrological Rain Puddle Pooling, Surface Sheen & Snow Drift Accretion

const IslandTerrain = preload("res://presentation/environment/island_terrain.gd")
const WeatherSystem = preload("res://core/environment/weather_system.gd")

func test_terrain_pbr_shader_puddle_and_snow_uniforms() -> bool:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	var mat: Variant = terrain._terrain_material
	if mat == null:
		terrain.free()
		return false

	if mat is ShaderMaterial:
		var s_mat: ShaderMaterial = mat as ShaderMaterial
		s_mat.set_shader_parameter("puddle_depth", 0.75)
		s_mat.set_shader_parameter("snow_drift_accretion", 0.50)

		var p_val: float = float(s_mat.get_shader_parameter("puddle_depth"))
		var s_val: float = float(s_mat.get_shader_parameter("snow_drift_accretion"))
		if absf(p_val - 0.75) > 0.01:
			terrain.free()
			return false
		if absf(s_val - 0.50) > 0.01:
			terrain.free()
			return false

	terrain.free()
	return true

func test_island_terrain_puddle_and_snow_properties() -> bool:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	terrain.set_puddle_depth(0.65)
	if absf(terrain.get_puddle_depth() - 0.65) > 0.001:
		terrain.free()
		return false

	terrain.set_snow_drift_accretion(0.40)
	if absf(terrain.get_snow_drift_accretion() - 0.40) > 0.001:
		terrain.free()
		return false

	# Clamping check
	terrain.set_puddle_depth(2.5)
	if terrain.get_puddle_depth() > 1.0:
		terrain.free()
		return false

	terrain.set_snow_drift_accretion(-1.0)
	if terrain.get_snow_drift_accretion() < 0.0:
		terrain.free()
		return false

	terrain.free()
	return true

func test_rain_storm_puddle_accumulation() -> bool:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)
	terrain.set_puddle_depth(0.0)
	terrain.set_surface_wetness(0.0)

	var weather: WeatherSystem = WeatherSystem.new()
	weather.set_weather_override(WeatherSystem.WeatherState.RAIN)

	# Simulate 2.0s of rain
	terrain.update_surface_reaction(2.0, weather)
	if terrain.get_puddle_depth() <= 0.10:
		terrain.free()
		return false
	if terrain.get_surface_wetness() <= 0.10:
		terrain.free()
		return false

	terrain.free()
	return true

func test_drought_and_clear_evaporation() -> bool:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)
	terrain.set_puddle_depth(0.80)
	terrain.set_surface_wetness(0.80)

	var weather: WeatherSystem = WeatherSystem.new()
	weather.set_weather_override(WeatherSystem.WeatherState.CLEAR)
	weather.wind_speed = 3.0

	var pre_puddle: float = terrain.get_puddle_depth()
	terrain.update_surface_reaction(3.0, weather)
	var post_puddle: float = terrain.get_puddle_depth()

	if post_puddle >= pre_puddle:
		terrain.free()
		return false

	# Drought rapid evaporation test
	weather.set_weather_override(WeatherSystem.WeatherState.DROUGHT)
	terrain.update_surface_reaction(6.0, weather)
	if terrain.get_puddle_depth() > 0.10:
		terrain.free()
		return false

	terrain.free()
	return true

func test_terrain_shadow_casting_optimization() -> bool:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	if terrain._mesh_instance == null:
		terrain.free()
		return false

	# Must have shadow casting disabled to protect Iris Xe GPU framerate
	if terrain._mesh_instance.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		terrain.free()
		return false

	terrain.free()
	return true
