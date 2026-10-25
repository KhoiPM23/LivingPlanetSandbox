class_name WorldClock
extends RefCounted

## Governs simulation time independent of render frame rates.

signal tick(tick_number: int, sim_time: float)
signal time_scale_changed(new_scale: float)
signal paused_changed(is_paused: bool)

const DEFAULT_DAY_DURATION: float = 720.0 # 12 real minutes per full simulation day — contract test canonical
const DEFAULT_START_HOUR: float = 11.5   # 11:30 AM Midday exploration start

var day_duration: float = DEFAULT_DAY_DURATION
var start_hour: float = DEFAULT_START_HOUR
var simulation_time: float = 0.0
var tick_count: int = 0
var tick_rate: float = 10.0 # 10 simulation ticks per real second
var tick_delta: float = 0.1 # 1.0 / tick_rate
var time_scale: float = 1.0
var is_paused: bool = false

var _accumulator: float = 0.0

func get_sim_time() -> float:
	return simulation_time + (start_hour / 24.0) * day_duration

func get_day_phase() -> float:
	if day_duration <= 0.0:
		return 0.0
	return fmod(get_sim_time() / day_duration, 1.0)

func get_sim_hour() -> float:
	return get_day_phase() * 24.0

func get_time_of_day() -> float:
	return get_sim_hour()

func set_time_of_day(target_hour: float) -> void:
	var desired_phase: float = fposmod(target_hour / 24.0, 1.0)
	var current_phase: float = get_day_phase()
	var phase_diff: float = fposmod(desired_phase - current_phase, 1.0)
	simulation_time += phase_diff * day_duration

func get_day_number() -> int:
	if day_duration <= 0.0:
		return 1
	return int(get_sim_time() / day_duration) + 1

enum Season {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER
}

func get_season() -> Season:
	var day: int = get_day_number()
	var idx: int = ((day - 1) / 3) % 4
	return Season.values()[idx]

func get_season_name() -> String:
	match get_season():
		Season.SPRING:
			return "Spring Bloom"
		Season.SUMMER:
			return "High Summer"
		Season.AUTUMN:
			return "Golden Autumn"
		Season.WINTER:
			return "Frost Winter"
		_:
			return "Temperate"

func is_daytime() -> bool:
	var phase: float = get_day_phase()
	return phase >= 0.25 and phase < 0.75

func set_sim_hour(hour: float) -> void:
	var target_h: float = fmod(hour, 24.0)
	if target_h < 0.0:
		target_h += 24.0
	var offset_hours: float = target_h - start_hour
	if offset_hours < 0.0:
		offset_hours += 24.0
	simulation_time = (offset_hours / 24.0) * day_duration

func _init(p_tick_rate: float = 10.0) -> void:
	set_tick_rate(p_tick_rate)

func set_tick_rate(p_rate: float) -> void:
	if p_rate <= 0.0:
		p_rate = 10.0
	tick_rate = p_rate
	tick_delta = 1.0 / p_rate

func set_time_scale(p_scale: float) -> void:
	var clamped_scale: float = max(0.0, p_scale)
	if not is_equal_approx(time_scale, clamped_scale):
		time_scale = clamped_scale
		time_scale_changed.emit(time_scale)

func set_paused(p_paused: bool) -> void:
	if is_paused != p_paused:
		is_paused = p_paused
		paused_changed.emit(is_paused)

func pause() -> void:
	set_paused(true)

func resume() -> void:
	set_paused(false)

func toggle_pause() -> void:
	set_paused(not is_paused)

## Advances clock by delta and returns number of simulation ticks to execute.
func advance(delta: float) -> int:
	if is_paused or time_scale <= 0.0:
		return 0
	
	var effective_delta: float = delta * time_scale
	_accumulator += effective_delta
	
	var executed_ticks: int = 0
	# Cap max ticks per frame to prevent spiral of death during lag spikes
	var max_ticks_per_frame: int = 5
	
	while (_accumulator + 0.00001) >= tick_delta and executed_ticks < max_ticks_per_frame:
		_accumulator -= tick_delta
		tick_count += 1
		simulation_time += tick_delta
		executed_ticks += 1
		tick.emit(tick_count, simulation_time)
	
	# If still overloaded, discard excess accumulator to protect frame rate
	if _accumulator >= tick_delta * max_ticks_per_frame:
		_accumulator = 0.0
		
	return executed_ticks

func reset() -> void:
	simulation_time = 0.0
	tick_count = 0
	_accumulator = 0.0
	is_paused = false
	time_scale = 1.0
