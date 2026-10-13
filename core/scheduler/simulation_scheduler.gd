class_name SimulationScheduler
extends RefCounted

## Coordinates recurring simulation systems on fixed tick intervals.

class SimTask:
	var name: String
	var interval_ticks: int
	var callback: Callable
	var last_executed_tick: int = 0
	
	func _init(p_name: String, p_interval: int, p_callback: Callable) -> void:
		name = p_name
		interval_ticks = max(1, p_interval)
		callback = p_callback

var _tasks: Array[SimTask] = []
var _clock: WorldClock = null

func _init(clock: WorldClock = null) -> void:
	if clock:
		bind_clock(clock)

func bind_clock(clock: WorldClock) -> void:
	_clock = clock
	if not _clock.tick.is_connected(_on_clock_tick):
		_clock.tick.connect(_on_clock_tick)

func unbind_clock() -> void:
	if _clock and _clock.tick.is_connected(_on_clock_tick):
		_clock.tick.disconnect(_on_clock_tick)
	_clock = null

func register_task(task_name: String, interval_ticks: int, callback: Callable) -> void:
	for task: SimTask in _tasks:
		if task.name == task_name:
			task.interval_ticks = max(1, interval_ticks)
			task.callback = callback
			return
	_tasks.append(SimTask.new(task_name, interval_ticks, callback))

func unregister_task(task_name: String) -> void:
	for i: int in range(_tasks.size() - 1, -1, -1):
		if _tasks[i].name == task_name:
			_tasks.remove_at(i)

func _on_clock_tick(tick_number: int, sim_time: float) -> void:
	for task: SimTask in _tasks:
		if (tick_number - task.last_executed_tick) >= task.interval_ticks:
			task.last_executed_tick = tick_number
			if task.callback.is_valid():
				task.callback.call(tick_number, sim_time)

func clear() -> void:
	_tasks.clear()
