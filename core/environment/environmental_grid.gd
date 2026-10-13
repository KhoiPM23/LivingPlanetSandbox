class_name EnvironmentalGrid
extends RefCounted

## 2D discrete ecological simulation grid storing physical variables:
## Temperature, Moisture, Water Availability, Sun Exposure, and dynamic Biome state.

@export var grid_size: int = 32 # 32x32 cells covering the bounded island (~5m per cell)

var _config: WorldGenerationConfig
var _cells: Array[Dictionary] = []
var _cell_size: float = 5.0
var _half_world: float = 80.0

func _init(config: WorldGenerationConfig = null) -> void:
	_config = config if config != null else WorldGenerationConfig.new()
	_cell_size = _config.island_size / float(grid_size)
	_half_world = _config.island_size * 0.5
	initialize_grid(Callable(self, "_default_height_sampler"))

func _default_height_sampler(wx: float, wz: float) -> float:
	var dist: float = Vector2(wx, wz).length()
	return maxf(0.0, 15.0 * (1.0 - (dist / _half_world)))

func get_cell(idx: int) -> Dictionary:
	if idx >= 0 and idx < _cells.size():
		return _cells[idx]
	return {}

func initialize_grid(height_sampler: Callable, moisture_noise: FastNoiseLite = null) -> void:
	_cells.clear()
	_cells.resize(grid_size * grid_size)
	
	for gz in range(grid_size):
		var wz: float = -_half_world + (float(gz) + 0.5) * _cell_size
		for gx in range(grid_size):
			var wx: float = -_half_world + (float(gx) + 0.5) * _cell_size
			var elev: float = height_sampler.call(wx, wz)
			
			# Base moisture: simplex noise modulated by distance to water table
			var noise_val: float = 0.5
			if moisture_noise:
				noise_val = (moisture_noise.get_noise_2d(wx * 1.5, wz * 1.5) + 1.0) * 0.5
				
			var water_dist: float = max(0.0, elev - _config.water_level)
			var ocean_proximity: float = clamp(1.0 - (water_dist / 6.0), 0.0, 1.0)
			var initial_moisture: float = clamp(_config.base_moisture * 0.7 + noise_val * 0.3 + ocean_proximity * 0.35, 0.05, 1.0)
			
			# Initial temperature: base temp minus elevation lapse rate
			var lapse: float = elev * _config.lapse_rate
			var initial_temp: float = _config.base_temperature - lapse
			
			# Water availability
			var water_avail: float = 1.0 if elev <= _config.water_level else clamp(1.0 - (water_dist / 8.0), 0.05, 1.0)
			
			var biome: BiomeClassifier.BiomeType = BiomeClassifier.classify(initial_temp, initial_moisture, elev, _config.water_level)
			
			var cell_data: Dictionary = {
				"gx": gx,
				"gz": gz,
				"world_x": wx,
				"world_z": wz,
				"elevation": elev,
				"temperature": initial_temp,
				"base_temperature": initial_temp,
				"moisture": initial_moisture,
				"water_availability": water_avail,
				"sun_exposure": 0.8,
				"biome": biome
			}
			
			_cells[gz * grid_size + gx] = cell_data

func step_simulation(delta_time: float, day_phase: float, weather: WeatherSystem = null) -> void:
	# Diurnal temperature cycle: peaks at day_phase ~ 0.55 (early afternoon), dips at ~ 0.15 (pre-dawn)
	var diurnal_angle: float = (day_phase * TAU) - (PI * 0.6)
	var diurnal_temp_shift: float = sin(diurnal_angle) * 5.5 # ±5.5°C swing
	
	var weather_temp_offset: float = weather.get_temperature_offset() if weather != null else 0.0
	var precip_rate: float = weather.get_precipitation_rate() if weather != null else 0.0
	var sun_factor: float = weather.get_sun_multiplier() if weather != null else 1.0
	
	for i in range(_cells.size()):
		var cell: Dictionary = _cells[i]
		var elev: float = cell["elevation"]
		
		# 1. Update Temperature
		var base_t: float = cell["base_temperature"]
		var current_t: float = base_t + diurnal_temp_shift + weather_temp_offset
		cell["temperature"] = clamp(current_t, -25.0, 50.0)
		
		# 2. Update Moisture & Water Availability
		if elev <= _config.water_level:
			# Ocean is saturated
			cell["moisture"] = 1.0
			cell["water_availability"] = 1.0
		else:
			var m: float = cell["moisture"]
			# Precipitation adds moisture
			m += precip_rate * delta_time
			# Evaporation removes moisture as temperature rises
			var evap_rate: float = 0.005 * max(0.1, (cell["temperature"] + 10.0) / 30.0)
			m -= evap_rate * delta_time
			
			# Capillary replenishment from nearby ground water
			m += cell["water_availability"] * 0.002 * delta_time
			cell["moisture"] = clamp(m, 0.05, 1.0)
			
		# 3. Update Sun Exposure
		cell["sun_exposure"] = clamp(sun_factor * max(0.0, sin(diurnal_angle)), 0.0, 1.0)
		
		# 4. Re-classify Biome based on current state
		cell["biome"] = BiomeClassifier.classify(cell["temperature"], cell["moisture"], elev, _config.water_level)

func sample_at(world_x: float, world_z: float) -> Dictionary:
	var gx: int = clampi(int((world_x + _half_world) / _cell_size), 0, grid_size - 1)
	var gz: int = clampi(int((world_z + _half_world) / _cell_size), 0, grid_size - 1)
	var idx: int = gz * grid_size + gx
	if idx >= 0 and idx < _cells.size():
		return _cells[idx]
	return {}

func get_environment_at(world_x: float, world_z: float) -> Dictionary:
	var gx: int = clampi(int((world_x + _half_world) / _cell_size), 0, grid_size - 1)
	var gz: int = clampi(int((world_z + _half_world) / _cell_size), 0, grid_size - 1)
	
	var idx: int = gz * grid_size + gx
	if idx >= 0 and idx < _cells.size():
		var cell: Dictionary = _cells[idx]
		var result: Dictionary = cell.duplicate()
		result["biome_name"] = BiomeClassifier.get_biome_name(cell["biome"] as BiomeClassifier.BiomeType)
		result["biome_color"] = BiomeClassifier.get_biome_color(cell["biome"] as BiomeClassifier.BiomeType)
		return result
		
	return {
		"temperature": _config.base_temperature,
		"moisture": _config.base_moisture,
		"water_availability": 0.5,
		"sun_exposure": 1.0,
		"biome": BiomeClassifier.BiomeType.TEMPERATE_MEADOW,
		"biome_name": "Temperate Meadow",
		"elevation": 0.0
	}

func get_cell_count() -> int:
	return _cells.size()

func get_config() -> WorldGenerationConfig:
	return _config

## Targeted environmental intervention: modifies moisture in a bounded radius
func apply_moisture_brush(center_x: float, center_z: float, radius: float, delta_moisture: float) -> int:
	var radius_sq: float = radius * radius
	var affected_count: int = 0
	for i in range(_cells.size()):
		var cell: Dictionary = _cells[i]
		var dx: float = cell["world_x"] - center_x
		var dz: float = cell["world_z"] - center_z
		var dist_sq: float = dx * dx + dz * dz
		if dist_sq <= radius_sq:
			var falloff: float = 1.0 - (sqrt(dist_sq) / maxf(radius, 0.001))
			var effective_delta: float = delta_moisture * (0.5 + 0.5 * falloff)
			var new_m: float = clampf(cell["moisture"] + effective_delta, 0.05, 1.0)
			cell["moisture"] = new_m
			cell["biome"] = BiomeClassifier.classify(cell["temperature"], cell["moisture"], cell["elevation"], _config.water_level)
			affected_count += 1
	return affected_count

## Restores cell moistures and temperatures from persisted save data
func restore_cell_data(moistures: Array, temps: Array = []) -> void:
	var count: int = mini(_cells.size(), moistures.size())
	for i in range(count):
		var cell: Dictionary = _cells[i]
		cell["moisture"] = clampf(float(moistures[i]), 0.05, 1.0)
		if i < temps.size():
			cell["temperature"] = clampf(float(temps[i]), -25.0, 50.0)
		cell["biome"] = BiomeClassifier.classify(cell["temperature"], cell["moisture"], cell["elevation"], _config.water_level)

