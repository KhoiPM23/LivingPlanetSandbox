class_name TestEnvironmentSystems
extends RefCounted

## Verification suite for Block 3: Procedural World & Environment Systems.

func test_generation_config_validation() -> bool:
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(1337)
	if not cfg.is_valid():
		return false
		
	# Test out of range clamping
	cfg.base_temperature = 100.0
	cfg.base_moisture = -5.0
	cfg.clamp_values()
	
	if cfg.base_temperature > 50.0 or cfg.base_moisture < 0.05:
		return false
		
	# Roundtrip serialization
	var dict: Dictionary = cfg.to_dict()
	var restored: WorldGenerationConfig = WorldGenerationConfig.from_dict(dict)
	return restored.seed_val == cfg.seed_val and abs(restored.base_temperature - cfg.base_temperature) < 0.001

func test_seed_generation_reproducibility() -> bool:
	var terrain_a: IslandTerrain = IslandTerrain.new()
	var terrain_b: IslandTerrain = IslandTerrain.new()
	var terrain_c: IslandTerrain = IslandTerrain.new()
	
	var cfg_a: WorldGenerationConfig = WorldGenerationConfig.new(4242)
	var cfg_b: WorldGenerationConfig = WorldGenerationConfig.new(4242)
	var cfg_c: WorldGenerationConfig = WorldGenerationConfig.new(9999)
	
	terrain_a.generate_island(cfg_a)
	terrain_b.generate_island(cfg_b)
	terrain_c.generate_island(cfg_c)
	
	var h_a: float = terrain_a.get_height_at(12.0, -18.0)
	var h_b: float = terrain_b.get_height_at(12.0, -18.0)
	var h_c: float = terrain_c.get_height_at(12.0, -18.0)
	
	terrain_a.free()
	terrain_b.free()
	terrain_c.free()
	
	# Same seed must be identical; different seed must differ
	var same_seed_matches: bool = abs(h_a - h_b) < 0.0001
	var diff_seed_differs: bool = abs(h_a - h_c) > 0.01
	
	return same_seed_matches and diff_seed_differs

func test_environmental_grid_ranges() -> bool:
	var terrain: IslandTerrain = IslandTerrain.new()
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(1337)
	terrain.generate_island(cfg)
	
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)
	grid.initialize_grid(Callable(terrain, "get_height_at"))
	
	# Check random sampling of cells
	var samples: Array[Vector2] = [
		Vector2(0, 0), Vector2(-24, -24), Vector2(40, 40), Vector2(-50, 20), Vector2(10, -30)
	]
	
	var all_valid: bool = true
	for pos: Vector2 in samples:
		var env: Dictionary = grid.get_environment_at(pos.x, pos.y)
		var t: float = env.get("temperature", 0.0)
		var m: float = env.get("moisture", 0.0)
		var w: float = env.get("water_availability", 0.0)
		var s: float = env.get("sun_exposure", 0.0)
		
		if t < -25.0 or t > 50.0: all_valid = false
		if m < 0.05 or m > 1.0: all_valid = false
		if w < 0.0 or w > 1.0: all_valid = false
		if s < 0.0 or s > 1.0: all_valid = false
		
	terrain.free()
	return all_valid

func test_diurnal_cycle_simulation() -> bool:
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(1337)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)
	var height_func: Callable = func(_x: float, _z: float) -> float: return 5.0
	grid.initialize_grid(height_func)
	
	# Sample center cell at dawn (0.25) vs early afternoon (0.55)
	grid.step_simulation(1.0, 0.25)
	var dawn_env: Dictionary = grid.get_environment_at(0, 0)
	var dawn_temp: float = dawn_env.get("temperature", 20.0)
	
	grid.step_simulation(1.0, 0.55)
	var noon_env: Dictionary = grid.get_environment_at(0, 0)
	var noon_temp: float = noon_env.get("temperature", 20.0)
	
	# Afternoon temperature must be measurably warmer than dawn
	return noon_temp > dawn_temp

func test_weather_system_state_machine_and_effects() -> bool:
	var weather: WeatherSystem = WeatherSystem.new()
	weather.set_state(WeatherSystem.WeatherState.RAIN, 60.0)
	
	var rain_sun: float = weather.get_sun_multiplier()
	var rain_precip: float = weather.get_precipitation_rate()
	var rain_temp_off: float = weather.get_temperature_offset()
	
	weather.set_state(WeatherSystem.WeatherState.DROUGHT, 60.0)
	var drought_sun: float = weather.get_sun_multiplier()
	var drought_precip: float = weather.get_precipitation_rate()
	var drought_temp_off: float = weather.get_temperature_offset()
	
	var rain_correct: bool = (rain_sun < 0.5 and rain_precip > 0.0 and rain_temp_off < 0.0)
	var drought_correct: bool = (drought_sun > 1.0 and drought_precip < 0.0 and drought_temp_off > 0.0)
	
	return rain_correct and drought_correct

func test_biome_classification_consistency() -> bool:
	# Ocean
	var b_ocean: BiomeClassifier.BiomeType = BiomeClassifier.classify(22.0, 1.0, -2.0, 0.0)
	# Beach
	var b_beach: BiomeClassifier.BiomeType = BiomeClassifier.classify(22.0, 0.5, 0.8, 0.0)
	# Alpine Summit
	var b_alpine: BiomeClassifier.BiomeType = BiomeClassifier.classify(4.0, 0.4, 15.0, 0.0)
	# Boreal Forest
	var b_boreal: BiomeClassifier.BiomeType = BiomeClassifier.classify(12.0, 0.6, 6.0, 0.0)
	# Temperate Meadow
	var b_meadow: BiomeClassifier.BiomeType = BiomeClassifier.classify(22.0, 0.6, 5.0, 0.0)
	# Arid Shrubland
	var b_arid: BiomeClassifier.BiomeType = BiomeClassifier.classify(30.0, 0.2, 5.0, 0.0)
	
	var c1: bool = (b_ocean == BiomeClassifier.BiomeType.OCEAN)
	var c2: bool = (b_beach == BiomeClassifier.BiomeType.COASTAL_BEACH)
	var c3: bool = (b_alpine == BiomeClassifier.BiomeType.ALPINE_SUMMIT)
	var c4: bool = (b_boreal == BiomeClassifier.BiomeType.BOREAL_FOREST)
	var c5: bool = (b_meadow == BiomeClassifier.BiomeType.TEMPERATE_MEADOW)
	var c6: bool = (b_arid == BiomeClassifier.BiomeType.ARID_SHRUBLAND)
	
	return c1 and c2 and c3 and c4 and c5 and c6
