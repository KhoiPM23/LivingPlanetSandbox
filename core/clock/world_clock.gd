class_name WorldClock
extends RefCounted

## Governs simulation time independent of render frame rates.

signal tick(tick_number: int, sim_time: float)
signal time_scale_changed(new_scale: float)
signal paused_changed(is_paused: bool)

var simulation_time: float = 0.0
var tick_count: int = 0
var tick_rate: float = 10.0 # 10 simulation ticks per real second
var tick_delta: float = 0.1 # 1.0 / tick_rate
var time_scale: float = 1.0
var is_paused: bool = false

var _accumulator: float = 0.0

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
