extends RefCounted

func test_clock_tick_advancement() -> Variant:
	var clock: WorldClock = WorldClock.new(10.0) # 10 ticks per second (0.1s delta)
	
	var ticks: int = clock.advance(0.25) # Should execute exactly 2 ticks
	if ticks != 2:
		return "Expected 2 ticks for 0.25s at 10Hz, got %d" % ticks
		
	if clock.tick_count != 2:
		return "Expected tick_count == 2, got %d" % clock.tick_count
		
	if not is_equal_approx(clock.simulation_time, 0.2):
		return "Expected simulation_time == 0.2, got %f" % clock.simulation_time
		
	return null

func test_clock_pause() -> Variant:
	var clock: WorldClock = WorldClock.new(10.0)
	clock.set_paused(true)
	
	var ticks: int = clock.advance(0.5)
	if ticks != 0 or clock.tick_count != 0:
		return "Clock advanced while paused"
		
	clock.set_paused(false)
	ticks = clock.advance(0.1)
	if ticks != 1:
		return "Clock failed to resume after unpausing"
		
	return null

func test_clock_time_scale() -> Variant:
	var clock: WorldClock = WorldClock.new(10.0)
	clock.set_time_scale(2.0) # 2x speed
	
	# In 0.1 real seconds at 2x speed, effective delta is 0.2s -> 2 ticks
	var ticks: int = clock.advance(0.1)
	if ticks != 2:
		return "Expected 2 ticks at 2x speed for 0.1s delta, got %d" % ticks
		
	return null
