class_name WeatherSystem
extends RefCounted

## State machine and environmental modifier system driving dynamic weather cycles.

enum WeatherState {
	CLEAR,
	CLOUDY,
	RAIN,
	DROUGHT
}

signal weather_changed(old_state: WeatherState, new_state: WeatherState)
signal wind_updated(direction: Vector2, speed: float, gust: float)

var current_state: WeatherState = WeatherState.CLEAR
var duration_remaining: float = 60.0
var min_duration: float = 30.0
var max_duration: float = 90.0

# --- WIND & ATMOSPHERIC DYNAMICS ---
var wind_direction: Vector2 = Vector2(0.85, 0.52).normalized()
var target_wind_direction: Vector2 = Vector2(0.85, 0.52).normalized()
var wind_speed: float = 1.5
var target_wind_speed: float = 1.5
var gust_intensity: float = 0.25
var wind_gust: float = 0.0
var sim_time_accum: float = 0.0

var _rng: RandomNumberGenerator
var _event_bus: WorldEventBus

func _init(seed_stream: RandomNumberGenerator = null, event_bus: WorldEventBus = null) -> void:
	_rng = seed_stream if seed_stream != null else RandomNumberGenerator.new()
	_event_bus = event_bus
	duration_remaining = _rng.randf_range(min_duration, max_duration)
	_apply_weather_wind_targets(current_state, true)

func update(delta_sim_seconds: float) -> void:
	duration_remaining -= delta_sim_seconds
	sim_time_accum += delta_sim_seconds

	# Smoothly steer wind speed and direction towards target states
	var lerp_rate: float = clampf(delta_sim_seconds * 0.8, 0.0, 1.0)
	wind_speed = lerpf(wind_speed, target_wind_speed, lerp_rate)
	wind_direction = wind_direction.lerp(target_wind_direction, lerp_rate).normalized()

	# Dynamic harmonic gust turbulence
	var gust_phase_1: float = sin(sim_time_accum * 1.1)
	var gust_phase_2: float = cos(sim_time_accum * 2.7 + 0.8) * 0.5
	var raw_gust: float = maxf(0.0, gust_phase_1 + gust_phase_2)
	wind_gust = raw_gust * gust_intensity * wind_speed

	wind_updated.emit(wind_direction, wind_speed, wind_gust)

	if duration_remaining <= 0.0:
		_transition_to_next_state()

func set_state(new_state: WeatherState, duration: float = 60.0) -> void:
	if new_state == current_state:
		duration_remaining = duration
		return

	var old_state: WeatherState = current_state
	current_state = new_state
	duration_remaining = duration
	_apply_weather_wind_targets(new_state, false)

	weather_changed.emit(old_state, new_state)
	if _event_bus:
		_event_bus.publish("weather_changed", {
			"old_weather": get_state_name(old_state),
			"new_weather": get_state_name(new_state),
			"duration": duration_remaining,
			"wind_speed": wind_speed,
			"wind_direction": [wind_direction.x, wind_direction.y]
		})

func _apply_weather_wind_targets(state: WeatherState, immediate: bool = false) -> void:
	match state:
		WeatherState.CLEAR:
			target_wind_speed = _rng.randf_range(1.0, 1.8)
			gust_intensity = 0.20
		WeatherState.CLOUDY:
			target_wind_speed = _rng.randf_range(2.2, 3.4)
			gust_intensity = 0.40
		WeatherState.RAIN:
			target_wind_speed = _rng.randf_range(4.5, 6.2)
			gust_intensity = 0.75
		WeatherState.DROUGHT:
			target_wind_speed = _rng.randf_range(1.6, 2.6)
			gust_intensity = 0.30

	# Moderate direction drift
	var angle: float = atan2(wind_direction.y, wind_direction.x) + _rng.randf_range(-0.4, 0.4)
	target_wind_direction = Vector2(cos(angle), sin(angle)).normalized()

	if immediate:
		wind_speed = target_wind_speed
		wind_direction = target_wind_direction

func _transition_to_next_state() -> void:
	var roll: float = _rng.randf()
	var next_state: WeatherState = WeatherState.CLEAR

	match current_state:
		WeatherState.CLEAR:
			# From clear -> 50% cloudy, 15% drought, 35% stay clear
			if roll < 0.50: next_state = WeatherState.CLOUDY
			elif roll < 0.65: next_state = WeatherState.DROUGHT
			else: next_state = WeatherState.CLEAR
		WeatherState.CLOUDY:
			# From cloudy -> 45% rain, 40% clear, 15% stay cloudy
			if roll < 0.45: next_state = WeatherState.RAIN
			elif roll < 0.85: next_state = WeatherState.CLEAR
			else: next_state = WeatherState.CLOUDY
		WeatherState.RAIN:
			# Rain -> 65% cloudy, 35% clear
			if roll < 0.65: next_state = WeatherState.CLOUDY
			else: next_state = WeatherState.CLEAR
		WeatherState.DROUGHT:
			# Drought -> 60% clear, 30% cloudy, 10% drought
			if roll < 0.60: next_state = WeatherState.CLEAR
			elif roll < 0.90: next_state = WeatherState.CLOUDY
			else: next_state = WeatherState.DROUGHT

	var duration: float = _rng.randf_range(min_duration, max_duration)
	set_state(next_state, duration)

func get_sun_multiplier() -> float:
	match current_state:
		WeatherState.CLEAR: return 1.0
		WeatherState.CLOUDY: return 0.55
		WeatherState.RAIN: return 0.25
		WeatherState.DROUGHT: return 1.25
		_: return 1.0

func get_precipitation_rate() -> float:
	match current_state:
		WeatherState.CLEAR: return 0.0
		WeatherState.CLOUDY: return 0.0
		WeatherState.RAIN: return 0.04 # Increases ground moisture
		WeatherState.DROUGHT: return -0.02 # Evaporates/dries moisture
		_: return 0.0

func get_temperature_offset() -> float:
	match current_state:
		WeatherState.CLEAR: return 0.0
		WeatherState.CLOUDY: return -1.5
		WeatherState.RAIN: return -4.0
		WeatherState.DROUGHT: return +4.5
		_: return 0.0

# --- WIND GETTERS & TELEMETRY ---
func get_wind_direction() -> Vector2:
	return wind_direction

func get_wind_speed() -> float:
	return wind_speed

func get_wind_gust() -> float:
	return wind_gust

func get_effective_wind_speed() -> float:
	return wind_speed + wind_gust

func get_wind_velocity() -> Vector2:
	return wind_direction * (wind_speed + wind_gust)

func get_wind_cardinal() -> String:
	# Convert wind direction angle to 8-wind cardinal
	var angle_deg: float = rad_to_deg(atan2(wind_direction.y, wind_direction.x))
	if angle_deg < 0.0:
		angle_deg += 360.0
	var cardinals: Array[String] = ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
	var index: int = int(round(angle_deg / 45.0)) % 8
	return cardinals[index]

static func get_state_name(state: WeatherState) -> String:
	match state:
		WeatherState.CLEAR: return "Clear Skies"
		WeatherState.CLOUDY: return "Overcast Clouds"
		WeatherState.RAIN: return "Gentle Rain"
		WeatherState.DROUGHT: return "Arid Drought"
		_: return "Clear Skies"

static func get_state_icon(state: WeatherState) -> String:
	match state:
		WeatherState.CLEAR: return "☀️"
		WeatherState.CLOUDY: return "☁️"
		WeatherState.RAIN: return "🌧️"
		WeatherState.DROUGHT: return "🌵"
		_: return "☀️"

func to_dict() -> Dictionary:
	return {
		"current_state": int(current_state),
		"duration_remaining": duration_remaining,
		"wind_dir_x": wind_direction.x,
		"wind_dir_y": wind_direction.y,
		"wind_speed": wind_speed,
		"gust_intensity": gust_intensity
	}

func from_dict(dict: Dictionary) -> void:
	current_state = dict.get("current_state", WeatherState.CLEAR) as WeatherState
	duration_remaining = dict.get("duration_remaining", 60.0)
	if dict.has("wind_dir_x") and dict.has("wind_dir_y"):
		wind_direction = Vector2(float(dict.get("wind_dir_x", 1.0)), float(dict.get("wind_dir_y", 0.0))).normalized()
		target_wind_direction = wind_direction
	if dict.has("wind_speed"):
		wind_speed = float(dict.get("wind_speed", 1.5))
		target_wind_speed = wind_speed
	if dict.has("gust_intensity"):
		gust_intensity = float(dict.get("gust_intensity", 0.25))
