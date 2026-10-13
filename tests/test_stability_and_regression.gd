class_name TestStabilityAndRegression
extends RefCounted

## Stress, stability, and regression verification suite for Living Planet Sandbox.
## Validates resilience against rapid state cycling, mass mortality, carrying capacity limits, and invalid inputs.

func test_rapid_pause_resume_cycles() -> Variant:
	var clock: WorldClock = WorldClock.new(10.0)
	var total_ticks: int = 0
	
	for i in range(50):
		clock.set_paused(true)
		var ticks_paused: int = clock.advance(0.2)
		if ticks_paused != 0:
			return "Clock advanced %d ticks while paused (iteration %d)" % [ticks_paused, i]
			
		clock.set_paused(false)
		var ticks_resumed: int = clock.advance(0.1)
		total_ticks += ticks_resumed

	if total_ticks == 0:
		return "Clock failed to advance after repeated pause/resume cycles"
		
	return null

func test_repeated_save_load_stress() -> Variant:
	var seed_obj: WorldSeed = WorldSeed.new(442211)
	var clock: WorldClock = WorldClock.new(10.0)
	var bus: WorldEventBus = WorldEventBus.new()
	var reg: EntityRegistry = EntityRegistry.new(bus)
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(442211)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)

	var coord: EcosystemCoordinator = EcosystemCoordinator.new(seed_obj, clock, bus, reg, grid, weather)
	coord.populate_initial_ecosystem(35, 10, 2)

	var save_path: String = "user://tests/stability_save_stress.json"

	for cycle in range(5):
		clock.advance(1.0)
		var err: Error = WorldPersistence.save_complete_world(save_path, seed_obj, clock, reg, grid, weather, coord)
		if err != OK:
			return "Save cycle %d failed with error: %d" % [cycle, err]
			
		var load_res: Dictionary = WorldPersistence.load_world(save_path)
		if load_res.get("error", ERR_CANT_OPEN) != OK:
			return "Load cycle %d failed: %s" % [cycle, load_res.get("message", "")]
			
		var data: Dictionary = load_res.get("data", {})
		if not data.has("ecosystem") or data["ecosystem"]["herbivores"].size() == 0:
			return "Load cycle %d dropped herbivore data" % cycle

	return null

func test_rapid_world_resets() -> Variant:
	var seed_obj: WorldSeed = WorldSeed.new(100)
	var clock: WorldClock = WorldClock.new(10.0)
	var bus: WorldEventBus = WorldEventBus.new()
	var reg: EntityRegistry = EntityRegistry.new(bus)
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(100)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)
	var sched: SimulationScheduler = SimulationScheduler.new(clock)

	var coord: EcosystemCoordinator = EcosystemCoordinator.new(seed_obj, clock, bus, reg, grid, weather, sched)

	for i in range(10):
		coord.populate_initial_ecosystem(20, 8, 2)
		var count_before: int = reg.get_count()
		if count_before == 0:
			return "Ecosystem failed to populate on reset cycle %d" % i

		# Rapid wipe & re-seed
		reg.clear()
		clock.reset()
		coord.clear()
		sched.clear()
		seed_obj.set_master_seed(100 + i * 7)

		if reg.get_count() != 0:
			return "Leftover entities in registry after reset cycle %d: %d" % [i, reg.get_count()]
		if clock.simulation_time != 0.0:
			return "Clock simulation time not reset on cycle %d" % i

	return null

func test_mass_starvation_and_collapse_event() -> Variant:
	var seed_obj: WorldSeed = WorldSeed.new(9999)
	var bus: WorldEventBus = WorldEventBus.new()
	var reg: EntityRegistry = EntityRegistry.new(bus)
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna_sim: FaunaSimulation = FaunaSimulation.new(seed_obj.get_stream("ecology"), reg, metrics, bus)

	# Spawn dense herbivore herd (60 animals) with low energy and moderate health
	for i in range(60):
		var pos: Vector3 = Vector3(float(i % 8) * 3.0, 1.0, float(i / 8) * 3.0)
		var hid: int = fauna_sim.spawn_herbivore(pos, 10.0)
		var h = fauna_sim.get_herbivore(hid)
		if h:
			h.health = 35.0

	# Simulate with NULL flora (complete barren wasteland, 0 food) for 70 steps (35s)
	var dummy_height: Callable = func(_x: float, _z: float) -> float: return 1.0

	for step in range(70):
		fauna_sim.step_simulation(0.5, null, dummy_height)

	# Herd must experience starvation mortality without crashing or throwing errors
	if metrics.deaths_total == 0:
		return "Zero starvation deaths recorded during barren wasteland collapse"
	if fauna_sim.get_herbivore_count() >= 60:
		return "Starving herd population did not decline during zero-food crisis"
	if metrics.deaths_by_cause.get("herbivore_starvation", 0) == 0:
		return "Starvation cause breakdown missing in metrics"

	return null

func test_population_boom_and_carrying_capacity() -> Variant:
	var seed_obj: WorldSeed = WorldSeed.new(888)
	var bus: WorldEventBus = WorldEventBus.new()
	var reg: EntityRegistry = EntityRegistry.new(bus)
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(888)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)
	var flora_sim: FloraSimulation = FloraSimulation.new(seed_obj.get_stream("ecology"), reg, metrics, bus)
	var fauna_sim: FaunaSimulation = FaunaSimulation.new(seed_obj.get_stream("ecology"), reg, metrics, bus)

	# Abundant food: 80 mature plants
	for i in range(80):
		var pos: Vector3 = Vector3(cos(float(i)) * 25.0, 1.0, sin(float(i)) * 25.0)
		flora_sim.spawn_plant("grass_patch", pos, 10.0)

	# High starting herd: 35 herbivores + 6 predators
	for i in range(35):
		fauna_sim.spawn_herbivore(Vector3(float(i - 17) * 2.0, 1.0, 0.0), 95.0)
	for i in range(6):
		fauna_sim.spawn_predator(Vector3(float(i - 3) * 5.0, 1.0, 10.0), 90.0)

	var dummy_height: Callable = func(_x: float, _z: float) -> float: return 1.0

	# Step 30 iterations (15 simulation seconds)
	for step in range(30):
		flora_sim.step_simulation(0.5, grid)
		fauna_sim.step_simulation(0.5, flora_sim, dummy_height)

	# Carrying capacity checks: population must remain bounded and not explode past safety limits
	if fauna_sim.get_herbivore_count() > 60:
		return "Herbivore population exploded beyond carrying capacity ceiling: %d" % fauna_sim.get_herbivore_count()
	if fauna_sim.get_predator_count() > 12:
		return "Predator population exploded beyond carrying capacity ceiling: %d" % fauna_sim.get_predator_count()
	if metrics.food_availability_ratio <= 0.0:
		return "Invalid food availability ratio: %f" % metrics.food_availability_ratio

	return null


func test_invalid_inputs_and_edge_cases() -> Variant:
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(1234)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)

	# Edge Case 1: Out of bounds sampling
	var oob_sample: Dictionary = grid.sample_at(99999.0, -99999.0)
	if oob_sample.is_empty():
		return "Out-of-bounds sampling returned empty dictionary instead of clamped edge cell"

	# Edge Case 2: Extreme coordinates in get_environment_at
	var env_extreme: Dictionary = grid.get_environment_at(-99999.0, 99999.0)
	if not env_extreme.has("temperature") or not env_extreme.has("biome_name"):
		return "get_environment_at failed on extreme coordinates"

	# Edge Case 3: Zero or negative radius moisture brush
	var affected_zero: int = grid.apply_moisture_brush(0.0, 0.0, 0.0, 0.1)
	# Should safely affect 1 or 0 cells without division by zero
	if affected_zero < 0:
		return "apply_moisture_brush returned negative cell count on zero radius"

	# Edge Case 4: Flora consuming negative or zero biomass
	var seed_obj: WorldSeed = WorldSeed.new(1)
	var flora: FloraSimulation = FloraSimulation.new(seed_obj.get_stream("ecology"), null, null, null)
	var pid: int = flora.spawn_plant("grass_patch", Vector3.ZERO, 5.0)
	var eaten_zero: float = flora.consume_biomass(pid, 0.0)
	if eaten_zero != 0.0:
		return "consume_biomass(0.0) returned non-zero value: %f" % eaten_zero

	var eaten_neg: float = flora.consume_biomass(pid, -5.0)
	if eaten_neg > 0.0:
		return "consume_biomass(-5.0) returned positive value: %f" % eaten_neg

	# Edge Case 5: Querying non-existent entity
	var missing: Variant = flora.get_plant(999999)
	if missing != null:
		return "get_plant(999999) did not return null"

	return null
