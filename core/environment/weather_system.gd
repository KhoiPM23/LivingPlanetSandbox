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

var current_state: WeatherState = WeatherState.CLEAR
var duration_remaining: float = 60.0
var min_duration: float = 30.0
var max_duration: float = 90.0

var _rng: RandomNumberGenerator
var _event_bus: WorldEventBus

func _init(seed_stream: RandomNumberGenerator = null, event_bus: WorldEventBus = null) -> void:
	_rng = seed_stream if seed_stream != null else RandomNumberGenerator.new()
	_event_bus = event_bus
	duration_remaining = _rng.randf_range(min_duration, max_duration)

func update(delta_sim_seconds: float) -> void:
	duration_remaining -= delta_sim_seconds
	if duration_remaining <= 0.0:
		_transition_to_next_state()

func set_state(new_state: WeatherState, duration: float = 60.0) -> void:
	if new_state == current_state:
		duration_remaining = duration
		return
		
	var old_state: WeatherState = current_state
	current_state = new_state
	duration_remaining = duration
	
	weather_changed.emit(old_state, new_state)
	if _event_bus:
		_event_bus.publish("weather_changed", {
			"old_weather": get_state_name(old_state),
			"new_weather": get_state_name(new_state),
			"duration": duration_remaining
		})

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

static func get_state_name(state: WeatherState) -> String:
	match state:
		WeatherState.CLEAR: return "Clear Skies"
		WeatherState.CLOUDY: return "Overcast Clouds"
		WeatherState.RAIN: return "Gentle Rain"
		WeatherState.DROUGHT: return "Arid Drought"
		_: return "Clear Skies"

func to_dict() -> Dictionary:
	return {
		"current_state": current_state,
		"duration_remaining": duration_remaining
	}

func from_dict(dict: Dictionary) -> void:
	current_state = dict.get("current_state", WeatherState.CLEAR) as WeatherState
	duration_remaining = dict.get("duration_remaining", 60.0)
