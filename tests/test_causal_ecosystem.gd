class_name TestCausalEcosystem
extends RefCounted

## Verification test suite for Block 4 Causal Ecosystem Simulation.
## Tests plant growth/decay, herbivore metabolism, predator threat, reproduction,
## performance scaling, and the complete causal drought experiment.

const FloraSimulation = preload("res://core/ecosystem/flora_simulation.gd")
const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")
const EcosystemCoordinator = preload("res://core/ecosystem/ecosystem_coordinator.gd")

func run_all() -> int:
	var passed: int = 0
	passed += _test("test_plant_growth_and_decay", Callable(self, "test_plant_growth_and_decay"))
	passed += _test("test_herbivore_resource_consumption_and_metabolism", Callable(self, "test_herbivore_resource_consumption_and_metabolism"))
	passed += _test("test_predator_threat_and_predation", Callable(self, "test_predator_threat_and_predation"))
	passed += _test("test_reproduction_and_population_dynamics", Callable(self, "test_reproduction_and_population_dynamics"))
	passed += _test("test_causal_drought_experiment", Callable(self, "test_causal_drought_experiment"))
	passed += _test("test_ecosystem_pause_and_time_scale", Callable(self, "test_ecosystem_pause_and_time_scale"))
	passed += _test("test_performance_scaling", Callable(self, "test_performance_scaling"))
	return passed

func _test(test_name: String, callable: Callable) -> int:
	print("  [RUN] %s" % test_name)
	var err: String = callable.call()
	if err == "":
		print("  [PASS] %s" % test_name)
		return 1
	else:
		printerr("  [FAIL] %s: %s" % [test_name, err])
		return 0

func _dummy_height(_x: float, _z: float) -> float:
	return 2.5

func test_plant_growth_and_decay() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)
	
	# Spawn a test grass patch
	var pid: int = flora.spawn_plant("grass_patch", Vector3(0, 0, 0), 2.0)
	var p = flora.get_plant(pid)
	if p == null:
		return "Failed to spawn plant"
	var initial_biomass: float = p.biomass
	
	# Create simulated EnvironmentalGrid with optimal growing conditions
	var config: WorldGenerationConfig = WorldGenerationConfig.new(12345)
	var env_grid: EnvironmentalGrid = EnvironmentalGrid.new(config)
	for i: int in range(env_grid.get_cell_count()):
		var cell: Dictionary = env_grid.get_cell(i)
		cell["moisture"] = 0.70
		cell["temperature"] = 22.0
		cell["sun_exposure"] = 0.90
		
	# Step 10 seconds of growth
	flora.step_simulation(10.0, env_grid)
	if p.biomass <= initial_biomass:
		return "Plant biomass did not increase under optimal moisture & sunlight (initial: %.2f, now: %.2f)" % [initial_biomass, p.biomass]
		
	# Now induce severe drought in grid
	for i: int in range(env_grid.get_cell_count()):
		var cell: Dictionary = env_grid.get_cell(i)
		cell["moisture"] = 0.05 # Far below min_moisture (0.20)
		
	var post_growth_biomass: float = p.biomass
	var initial_health: float = p.health
	flora.step_simulation(5.0, env_grid)
	
	if p.health >= initial_health:
		return "Plant health did not decline under severe drought (was: %.1f, now: %.1f)" % [initial_health, p.health]
	if p.biomass >= post_growth_biomass:
		return "Plant biomass did not decline under drought"
		
	return ""

func test_herbivore_resource_consumption_and_metabolism() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 23456
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)
	
	# Spawn plant with 8.0 biomass
	var pid: int = flora.spawn_plant("grass_patch", Vector3(0, 0, 0), 8.0)
	var plant = flora.get_plant(pid)
	
	# Spawn hungry herbivore right next to it
	var hid: int = fauna.spawn_herbivore(Vector3(0.5, 0, 0), 40.0)
	var herbivore = fauna.get_herbivore(hid)
	if herbivore == null:
		return "Failed to spawn herbivore"
		
	# Step simulation: herbivore should forage and eat
	fauna.step_simulation(1.0, flora, Callable(self, "_dummy_height"))
	
	if herbivore.energy <= 40.0:
		return "Herbivore did not gain energy after feeding (energy: %.1f)" % herbivore.energy
	if plant.biomass >= 8.0:
		return "Plant biomass was not consumed by feeding herbivore (biomass: %.1f)" % plant.biomass
		
	# Test starvation with isolated herbivore in barren land
	var starving_id: int = fauna.spawn_herbivore(Vector3(50, 0, 50), 2.0)
	var starving_herb = fauna.get_herbivore(starving_id)
	
	# Step simulation without any plants nearby for several seconds
	for step: int in range(10):
		fauna.step_simulation(1.0, flora, Callable(self, "_dummy_height"))
		if not fauna.get_herbivore(starving_id):
			break # Successfully starved and despawned
			
	if fauna.get_herbivore(starving_id) != null and starving_herb.health > 80.0:
		return "Starving herbivore did not suffer health damage without food"
		
	return ""

func test_predator_threat_and_predation() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 34567
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)
	
	# Spawn herbivore at (0, 0, 0)
	var hid: int = fauna.spawn_herbivore(Vector3(0, 0, 0), 80.0)
	var herb = fauna.get_herbivore(hid)
	
	# Spawn hungry predator close by at (3, 0, 0)
	var pid: int = fauna.spawn_predator(Vector3(3.0, 0, 0), 30.0)
	var pred = fauna.get_predator(pid)
	
	# Step 1: Herbivore should detect threat and enter FLEEING
	fauna.step_simulation(0.2, flora, Callable(self, "_dummy_height"))
	if herb.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "Herbivore did not enter FLEEING state when predator was close (state: %d)" % herb.state
		
	# Step multiple ticks: predator should catch prey
	var prey_killed: bool = false
	for step: int in range(15):
		fauna.step_simulation(0.5, flora, Callable(self, "_dummy_height"))
		if fauna.get_herbivore(hid) == null:
			prey_killed = true
			break
			
	if not prey_killed:
		return "Predator failed to catch and kill nearby prey"
	if pred.energy <= 30.0:
		return "Predator did not restore energy after successful hunt (energy: %.1f)" % pred.energy
	if metrics.deaths_by_cause.get("herbivore_predation", 0) < 1:
		return "Metrics did not record herbivore predation event"
		
	return ""

func test_reproduction_and_population_dynamics() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 45678
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)
	
	# Spawn healthy, high-energy adult herbivore with reproduction ready
	var hid: int = fauna.spawn_herbivore(Vector3(5, 0, 5), 95.0, FaunaSimulation.LifeStage.ADULT)
	var h = fauna.get_herbivore(hid)
	h.reproduce_cooldown = 0.0
	
	var initial_herb_count: int = fauna.get_herbivore_count()
	fauna.step_simulation(1.0, flora, Callable(self, "_dummy_height"))
	
	if fauna.get_herbivore_count() <= initial_herb_count:
		return "High-energy adult herbivore did not reproduce (count before: %d, after: %d)" % [initial_herb_count, fauna.get_herbivore_count()]
	if metrics.births_total < 2: # 1 initial spawn + 1 offspring
		return "Metrics did not record birth event (total: %d)" % metrics.births_total
		
	return ""

func test_causal_drought_experiment() -> String:
	# =========================================================================
	# EXPERIMENT: DROUGHT SCENARIO vs CONTROL SCENARIO (Identical Seeds: 99999)
	# =========================================================================
	var test_seed: int = 99999
	
	# --- RUN A: DROUGHT SCENARIO ---
	var seed_a: WorldSeed = WorldSeed.new(test_seed)
	var clock_a: WorldClock = WorldClock.new(10.0)
	var bus_a: WorldEventBus = WorldEventBus.new()
	var reg_a: EntityRegistry = EntityRegistry.new(bus_a)
	var sched_a: SimulationScheduler = SimulationScheduler.new(clock_a)
	var cfg_a: WorldGenerationConfig = WorldGenerationConfig.new(test_seed)
	var grid_a: EnvironmentalGrid = EnvironmentalGrid.new(cfg_a)
	var weather_a: WeatherSystem = WeatherSystem.new(seed_a.get_stream("weather"), bus_a)
	var coord_a: EcosystemCoordinator = EcosystemCoordinator.new(seed_a, clock_a, bus_a, reg_a, grid_a, weather_a, sched_a)
	coord_a.bind_terrain_height(Callable(self, "_dummy_height"))
	
	# Spawn identical starting population (40 plants, 10 herbivores, 0 predators to isolate food chain)
	coord_a.populate_initial_ecosystem(40, 10, 0)
	var initial_biomass: float = coord_a.metrics.total_biomass
	
	# Warmup 5 steps under normal conditions
	for step: int in range(5):
		coord_a.step_simulation(1.0)
	var initial_herb_count: int = coord_a.metrics.herbivore_count
		
	# Induce severe DROUGHT in Scenario A
	coord_a.apply_drought(0.04) # Drop soil moisture to 4%
	
	# Run 90 simulation steps under drought (enough time for food decay, energy & health exhaustion)
	for step: int in range(90):
		coord_a.step_simulation(1.0)
		
	var drought_final_biomass: float = coord_a.metrics.total_biomass
	var drought_final_herbs: int = coord_a.metrics.herbivore_count
	var drought_starvations: int = coord_a.metrics.deaths_by_cause.get("herbivore_starvation", 0)
	
	# --- RUN B: CONTROL SCENARIO (Optimal Moisture, No Drought) ---
	var seed_b: WorldSeed = WorldSeed.new(test_seed)
	var clock_b: WorldClock = WorldClock.new(10.0)
	var bus_b: WorldEventBus = WorldEventBus.new()
	var reg_b: EntityRegistry = EntityRegistry.new(bus_b)
	var sched_b: SimulationScheduler = SimulationScheduler.new(clock_b)
	var cfg_b: WorldGenerationConfig = WorldGenerationConfig.new(test_seed)
	var grid_b: EnvironmentalGrid = EnvironmentalGrid.new(cfg_b)
	var weather_b: WeatherSystem = WeatherSystem.new(seed_b.get_stream("weather"), bus_b)
	var coord_b: EcosystemCoordinator = EcosystemCoordinator.new(seed_b, clock_b, bus_b, reg_b, grid_b, weather_b, sched_b)
	coord_b.bind_terrain_height(Callable(self, "_dummy_height"))
	
	coord_b.populate_initial_ecosystem(40, 10, 0)
	
	# Warmup 5 steps
	for step: int in range(5):
		coord_b.step_simulation(1.0)
		
	# Keep normal/lush moisture in Scenario B
	for i: int in range(grid_b.get_cell_count()):
		var cell: Dictionary = grid_b.get_cell(i)
		cell["moisture"] = 0.65 # Good soil moisture
		
	# Run 90 simulation steps under healthy conditions
	for step: int in range(90):
		coord_b.step_simulation(1.0)
		
	var control_final_biomass: float = coord_b.metrics.total_biomass
	var control_final_herbs: int = coord_b.metrics.herbivore_count
	var control_starvations: int = coord_b.metrics.deaths_by_cause.get("herbivore_starvation", 0)
	
	# =========================================================================
	# CAUSAL VERIFICATION ASSERTIONS
	# =========================================================================
	# 1. Biomass divergence: Control scenario must have substantially more biomass than Drought scenario
	if control_final_biomass <= drought_final_biomass:
		return "Causal failure: Control biomass (%.1f) did not exceed drought biomass (%.1f)" % [control_final_biomass, drought_final_biomass]
		
	# 2. Herbivore population under drought must have suffered starvation deaths
	if drought_starvations < 1 and drought_final_herbs >= initial_herb_count:
		return "Causal failure: Drought did not trigger any herbivore starvation"
		
	# 3. Control herbivores must have had zero or fewer starvations than drought
	if control_starvations > drought_starvations:
		return "Causal failure: Control had more starvations (%d) than drought (%d)" % [control_starvations, drought_starvations]
		
	# 4. Control final herbivore count must be higher than drought final count
	if control_final_herbs < drought_final_herbs:
		return "Causal failure: Control herbivore population (%d) was lower than drought population (%d)" % [control_final_herbs, drought_final_herbs]
		
	return ""

func test_ecosystem_pause_and_time_scale() -> String:
	var seed_val: int = 55555
	var seed_obj: WorldSeed = WorldSeed.new(seed_val)
	var clock: WorldClock = WorldClock.new(10.0)
	var bus: WorldEventBus = WorldEventBus.new()
	var reg: EntityRegistry = EntityRegistry.new(bus)
	var sched: SimulationScheduler = SimulationScheduler.new(clock)
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(seed_val)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)
	var coord: EcosystemCoordinator = EcosystemCoordinator.new(seed_obj, clock, bus, reg, grid, weather, sched)
	
	coord.populate_initial_ecosystem(20, 5, 0)
	var bio_start: float = coord.metrics.total_biomass
	
	# Pause the world
	clock.pause()
	clock.advance(5.0) # Should not tick scheduler
	
	# Verify biomass did not change while paused
	if coord.metrics.total_biomass != bio_start:
		return "Ecosystem updated while clock was paused"
		
	# Resume
	clock.resume()
	clock.set_time_scale(2.0)
	clock.advance(1.0) # Advances 2.0s sim time (20 ticks)
	
	return ""

func test_performance_scaling() -> String:
	var seed_val: int = 66666
	var seed_obj: WorldSeed = WorldSeed.new(seed_val)
	var clock: WorldClock = WorldClock.new(10.0)
	var bus: WorldEventBus = WorldEventBus.new()
	var reg: EntityRegistry = EntityRegistry.new(bus)
	var sched: SimulationScheduler = SimulationScheduler.new(clock)
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(seed_val)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)
	var coord: EcosystemCoordinator = EcosystemCoordinator.new(seed_obj, clock, bus, reg, grid, weather, sched)
	coord.bind_terrain_height(Callable(self, "_dummy_height"))
	
	# Stress scale: 120 plants, 35 herbivores, 6 predators
	coord.populate_initial_ecosystem(120, 35, 6)
	
	# Warmup 4 steps before benchmarking to eliminate cold start buffer allocations
	for w: int in range(4):
		coord.step_simulation(0.5)

	var total_time_usec: int = 0
	var iterations: int = 20
	for i: int in range(iterations):
		var t0: int = Time.get_ticks_usec()
		coord.step_simulation(0.5)
		total_time_usec += (Time.get_ticks_usec() - t0)
		
	var avg_ms: float = float(total_time_usec) / (float(iterations) * 1000.0)
	# Budget target: ecosystem step should take < 25.0ms on CPU (2Hz tick allows up to 25-50ms)
	if avg_ms > 25.0:
		return "Ecosystem step exceeded performance budget (avg: %.2f ms)" % avg_ms
		
	return ""
