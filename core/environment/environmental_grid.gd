class_name EnvironmentalGrid
extends RefCounted

## 2D discrete ecological simulation grid storing physical variables:
## Temperature, Moisture, Water Availability, Sun Exposure, and dynamic Biome state.

@export var grid_size: int = 32 # 32x32 cells covering the bounded island (~5m per cell)

var _config: WorldGenerationConfig
var _cells: Array[Dictionary] = []
var _cell_size: float = 5.0
var _half_world: float = 80.0
var _active_pulses: Array[Dictionary] = []
var _pulse_id_counter: int = 1

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
	if _config:
		_cell_size = _config.island_size / float(grid_size)
		_half_world = _config.island_size * 0.5
	_cells.clear()
	_cells.resize(grid_size * grid_size)
	
	for gz in range(grid_size):
		var wz: float = -_half_world + (float(gz) + 0.5) * _cell_size
		for gx in range(grid_size):
			var wx: float = -_half_world + (float(gx) + 0.5) * _cell_size
			var elev: float = 1.0
			if height_sampler.is_valid():
				elev = height_sampler.call(wx, wz)
			
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
				"temp_modifier": 0.0,
				"moisture": initial_moisture,
				"water_availability": water_avail,
				"sun_exposure": 0.8,
				"fertility": 1.0,
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
		var temp_mod: float = cell.get("temp_modifier", 0.0)
		var current_t: float = base_t + diurnal_temp_shift + weather_temp_offset + temp_mod
		cell["temperature"] = clamp(current_t, -25.0, 50.0)
		if absf(temp_mod) > 0.01:
			cell["temp_modifier"] = move_toward(temp_mod, 0.0, 0.10 * delta_time)
		
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

		# 4. Fertility relaxation toward equilibrium
		var fert: float = cell.get("fertility", 1.0)
		if fert > 1.0:
			cell["fertility"] = move_toward(fert, 1.0, 0.02 * delta_time)
		elif fert < 1.0:
			cell["fertility"] = move_toward(fert, 1.0, 0.01 * delta_time)
		
		# 5. Re-classify Biome based on current state
		cell["biome"] = BiomeClassifier.classify(cell["temperature"], cell["moisture"], elev, _config.water_level)

	# 6. Step active finite climate pulses
	var pulse_idx: int = _active_pulses.size() - 1
	while pulse_idx >= 0:
		var p: Dictionary = _active_pulses[pulse_idx]
		p["remaining"] = float(p.get("remaining", 0.0)) - delta_time
		var p_rad_sq: float = float(p.get("radius", 12.0)) * float(p.get("radius", 12.0))
		var p_cx: float = float(p.get("center_x", 0.0))
		var p_cz: float = float(p.get("center_z", 0.0))
		var p_type: String = str(p.get("type", "deluge"))

		for i in range(_cells.size()):
			var cell: Dictionary = _cells[i]
			var dx: float = cell["world_x"] - p_cx
			var dz: float = cell["world_z"] - p_cz
			var d_sq: float = dx * dx + dz * dz
			if d_sq <= p_rad_sq:
				var falloff: float = 1.0 - (sqrt(d_sq) / maxf(sqrt(p_rad_sq), 0.001))
				var rate_factor: float = (0.5 + 0.5 * falloff) * delta_time
				match p_type:
					"deluge":
						cell["moisture"] = clampf(cell["moisture"] + 0.06 * rate_factor, 0.05, 1.0)
						cell["temperature"] = clampf(cell["temperature"] - 0.4 * rate_factor, -25.0, 50.0)
					"heat_pulse":
						cell["temperature"] = clampf(cell["temperature"] + 1.2 * rate_factor, -25.0, 50.0)
						cell["moisture"] = clampf(cell["moisture"] - 0.03 * rate_factor, 0.05, 1.0)
					"cold_snap":
						cell["temperature"] = clampf(cell["temperature"] - 1.2 * rate_factor, -25.0, 50.0)
				cell["biome"] = BiomeClassifier.classify(cell["temperature"], cell["moisture"], cell["elevation"], _config.water_level)

		if float(p.get("remaining", 0.0)) <= 0.0:
			_active_pulses.remove_at(pulse_idx)
		pulse_idx -= 1

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
		"fertility": 1.0,
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

## Targeted temperature intervention: modifies heat or cold in a bounded radius
func apply_temperature_brush(center_x: float, center_z: float, radius: float, delta_temp: float) -> int:
	var radius_sq: float = radius * radius
	var affected_count: int = 0
	for i in range(_cells.size()):
		var cell: Dictionary = _cells[i]
		var dx: float = cell["world_x"] - center_x
		var dz: float = cell["world_z"] - center_z
		var dist_sq: float = dx * dx + dz * dz
		if dist_sq <= radius_sq:
			var falloff: float = 1.0 - (sqrt(dist_sq) / maxf(radius, 0.001))
			var effective_delta: float = delta_temp * (0.5 + 0.5 * falloff)
			var current_mod: float = cell.get("temp_modifier", 0.0)
			cell["temp_modifier"] = clampf(current_mod + effective_delta, -35.0, 35.0)
			cell["temperature"] = clampf(cell["temperature"] + effective_delta, -25.0, 50.0)
			cell["biome"] = BiomeClassifier.classify(cell["temperature"], cell["moisture"], cell["elevation"], _config.water_level)
			affected_count += 1
	return affected_count

## Targeted soil fertilizer intervention: enriches nutrients in a bounded radius
func apply_fertilizer_brush(center_x: float, center_z: float, radius: float, delta_fertility: float) -> int:
	var radius_sq: float = radius * radius
	var affected_count: int = 0
	for i in range(_cells.size()):
		var cell: Dictionary = _cells[i]
		var dx: float = cell["world_x"] - center_x
		var dz: float = cell["world_z"] - center_z
		var dist_sq: float = dx * dx + dz * dz
		if dist_sq <= radius_sq:
			var falloff: float = 1.0 - (sqrt(dist_sq) / maxf(radius, 0.001))
			var effective_delta: float = delta_fertility * (0.6 + 0.4 * falloff)
			var cur_fert: float = cell.get("fertility", 1.0)
			cell["fertility"] = clampf(cur_fert + effective_delta, 0.2, 3.0)
			affected_count += 1
	return affected_count

## Localized disaster shock: sudden extreme heat spike (+12°C) combined with severe desiccation (-45% moisture)
func apply_disaster_shock(center_x: float, center_z: float, radius: float) -> int:
	var radius_sq: float = radius * radius
	var affected_count: int = 0
	for i in range(_cells.size()):
		var cell: Dictionary = _cells[i]
		var dx: float = cell["world_x"] - center_x
		var dz: float = cell["world_z"] - center_z
		var dist_sq: float = dx * dx + dz * dz
		if dist_sq <= radius_sq:
			var falloff: float = 1.0 - (sqrt(dist_sq) / maxf(radius, 0.001))
			var heat_delta: float = 12.0 * (0.5 + 0.5 * falloff)
			var moisture_drop: float = 0.45 * (0.5 + 0.5 * falloff)
			var cur_mod: float = cell.get("temp_modifier", 0.0)
			cell["temp_modifier"] = clampf(cur_mod + heat_delta, -35.0, 35.0)
			cell["temperature"] = clampf(cell["temperature"] + heat_delta, -25.0, 50.0)
			cell["moisture"] = clampf(cell["moisture"] - moisture_drop, 0.05, 1.0)
			cell["biome"] = BiomeClassifier.classify(cell["temperature"], cell["moisture"], cell["elevation"], _config.water_level)
			affected_count += 1
	return affected_count

## Elemental ash enrichment: burning grass/brush deposits potassium-rich charcoal ash into the soil,
## increasing fertility (+0.45) and marking charred_ash_active for accelerated tender shoot regrowth.
func apply_ash_enrichment(center_x: float, center_z: float, radius: float = 6.0) -> int:
	var radius_sq: float = radius * radius
	var affected_count: int = 0
	for i in range(_cells.size()):
		var cell: Dictionary = _cells[i]
		var dx: float = cell["world_x"] - center_x
		var dz: float = cell["world_z"] - center_z
		var dist_sq: float = dx * dx + dz * dz
		if dist_sq <= radius_sq:
			var falloff: float = 1.0 - (sqrt(dist_sq) / maxf(radius, 0.001))
			var fertility_gain: float = 0.45 * (0.6 + 0.4 * falloff)
			var cur_fert: float = cell.get("fertility", 1.0)
			cell["fertility"] = clampf(cur_fert + fertility_gain, 0.2, 3.0)
			cell["charred_ash_active"] = true
			cell["charred_ash_timer"] = 180.0
			affected_count += 1
	return affected_count

## Restores cell moistures, temperatures, and fertilities from persisted save data
func restore_cell_data(moistures: Array, temps: Array = [], fertilities: Array = []) -> void:
	var count: int = mini(_cells.size(), moistures.size())
	for i in range(count):
		var cell: Dictionary = _cells[i]
		cell["moisture"] = clampf(float(moistures[i]), 0.05, 1.0)
		if i < temps.size():
			cell["temperature"] = clampf(float(temps[i]), -25.0, 50.0)
		if i < fertilities.size():
			cell["fertility"] = clampf(float(fertilities[i]), 0.2, 3.0)
		cell["biome"] = BiomeClassifier.classify(cell["temperature"], cell["moisture"], cell["elevation"], _config.water_level)

## Triggers a finite climate pulse with defined duration, scope, and continuous physical effects.
func trigger_climate_pulse(center_x: float, center_z: float, radius: float, pulse_type: String = "deluge", duration: float = 25.0) -> Dictionary:
	var pulse_data: Dictionary = {
		"id": _pulse_id_counter,
		"center_x": center_x,
		"center_z": center_z,
		"radius": radius,
		"type": pulse_type,
		"duration": duration,
		"remaining": duration,
		"cells_affected": 0
	}
	_pulse_id_counter += 1

	var rad_sq: float = radius * radius
	var affected: int = 0
	for i in range(_cells.size()):
		var cell: Dictionary = _cells[i]
		var dx: float = cell["world_x"] - center_x
		var dz: float = cell["world_z"] - center_z
		if (dx * dx + dz * dz) <= rad_sq:
			affected += 1
	pulse_data["cells_affected"] = affected
	_active_pulses.append(pulse_data)
	return pulse_data

func get_active_pulses() -> Array[Dictionary]:
	return _active_pulses

func get_active_pulse_count() -> int:
	return _active_pulses.size()

func clear_pulses() -> void:
	_active_pulses.clear()

func serialize_pulses() -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for p in _active_pulses:
		res.append(p.duplicate())
	return res

func deserialize_pulses(data: Array) -> void:
	_active_pulses.clear()
	for item in data:
		if item is Dictionary:
			_active_pulses.append(item.duplicate())

