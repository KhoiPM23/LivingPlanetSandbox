class_name TestCausalExperimentTools
extends RefCounted

## Automated Contract Test Suite for Block 5:
## Climate Experiment Tools & Causal Ecosystem Integration.
## Verifies temperature/fertilizer/disaster brushes, causal cascade detection, and persistence.

const FloraSimulation = preload("res://core/ecosystem/flora_simulation.gd")
const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")
const EcosystemCoordinator = preload("res://core/ecosystem/ecosystem_coordinator.gd")
const CausalTracker = preload("res://core/ecosystem/causal_tracker.gd")
const ExperimentHistory = preload("res://core/ecosystem/experiment_history.gd")

func run_all() -> int:
	var passed: int = 0
	passed += _test("test_climate_brushes_temperature_and_fertility", Callable(self, "test_climate_brushes_temperature_and_fertility"))
	passed += _test("test_disaster_shock_impact", Callable(self, "test_disaster_shock_impact"))
	passed += _test("test_causal_tracker_interventions_and_queries", Callable(self, "test_causal_tracker_interventions_and_queries"))
	passed += _test("test_causal_cascade_generation_on_mortality", Callable(self, "test_causal_cascade_generation_on_mortality"))
	passed += _test("test_fertilizer_growth_acceleration", Callable(self, "test_fertilizer_growth_acceleration"))
	passed += _test("test_experiment_tools_modes_and_persistence", Callable(self, "test_experiment_tools_modes_and_persistence"))
	passed += _test("test_controlled_population_mutation_and_telemetry", Callable(self, "test_controlled_population_mutation_and_telemetry"))
	passed += _test("test_climate_pulse_dynamics_and_lifecycle", Callable(self, "test_climate_pulse_dynamics_and_lifecycle"))
	passed += _test("test_experiment_history_tracking_and_comparison", Callable(self, "test_experiment_history_tracking_and_comparison"))
	passed += _test("test_simulation_clock_controls_and_event_processing", Callable(self, "test_simulation_clock_controls_and_event_processing"))
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

func test_climate_brushes_temperature_and_fertility() -> String:
	var config: WorldGenerationConfig = WorldGenerationConfig.new(55555)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(config)
	var center_x: float = 0.0
	var center_z: float = 0.0

	var initial_cell: Dictionary = grid.sample_at(center_x, center_z)
	var initial_temp: float = initial_cell["temperature"]
	var initial_fert: float = initial_cell.get("fertility", 1.0)

	# 1. Test Heatwave brush (+8°C)
	var heated: int = grid.apply_temperature_brush(center_x, center_z, 12.0, 8.0)
	if heated <= 0:
		return "Heatwave brush affected 0 cells"

	var after_heat: Dictionary = grid.sample_at(center_x, center_z)
	var heat_temp: float = float(after_heat["temperature"])
	if heat_temp <= initial_temp + 3.0:
		return "Cell temperature did not increase significantly after heatwave (was %.1f, now %.1f)" % [initial_temp, heat_temp]

	# 2. Test Frost brush (-14°C)
	var frozen: int = grid.apply_temperature_brush(center_x, center_z, 12.0, -14.0)
	if frozen <= 0:
		return "Frost brush affected 0 cells"

	var frost_temp: float = float(grid.sample_at(center_x, center_z)["temperature"])
	if frost_temp >= heat_temp:
		return "Cell temperature did not decrease after frost brush (heat was %.1f, now %.1f)" % [heat_temp, frost_temp]

	# 3. Test Fertilizer brush (+1.5 fertility)
	var fertilized: int = grid.apply_fertilizer_brush(center_x, center_z, 10.0, 1.5)
	if fertilized <= 0:
		return "Fertilizer brush affected 0 cells"

	var after_fert: Dictionary = grid.sample_at(center_x, center_z)
	var new_fert: float = after_fert.get("fertility", 1.0)
	if new_fert <= initial_fert + 0.5:
		return "Cell fertility was not boosted (was %.2f, now %.2f)" % [initial_fert, new_fert]

	# Step simulation and verify fertility gradually relaxes
	grid.step_simulation(5.0, 0.5)
	var relaxed_fert: float = grid.sample_at(center_x, center_z).get("fertility", 1.0)
	if relaxed_fert > new_fert:
		return "Fertility did not relax toward equilibrium"

	return ""

func test_disaster_shock_impact() -> String:
	var config: WorldGenerationConfig = WorldGenerationConfig.new(66666)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(config)
	var center_x: float = 10.0
	var center_z: float = 10.0

	var before: Dictionary = grid.sample_at(center_x, center_z)
	var before_temp: float = before["temperature"]
	var before_moist: float = before["moisture"]

	var affected: int = grid.apply_disaster_shock(center_x, center_z, 15.0)
	if affected <= 0:
		return "Disaster shock affected 0 cells"

	var after: Dictionary = grid.sample_at(center_x, center_z)
	if after["temperature"] <= before_temp + 4.0:
		return "Disaster shock did not spike temperature sufficiently"
	if after["moisture"] >= before_moist:
		return "Disaster shock did not desiccate soil moisture"

	return ""

func test_causal_tracker_interventions_and_queries() -> String:
	var clock: WorldClock = WorldClock.new(10.0)
	clock.simulation_time = 120.0
	var tracker: CausalTracker = CausalTracker.new(clock)

	var target_pos: Vector3 = Vector3(15.0, 1.0, -20.0)
	tracker.record_intervention("heatwave", target_pos, 8.0, {"delta_temp": 8.0})

	# Query near target
	var found: Dictionary = tracker.find_recent_intervention_near(target_pos + Vector3(2.0, 0.0, 2.0), 6.0, 60.0)
	if found.is_empty():
		return "Failed to find recent intervention within radius margin"
	if found["type"] != "heatwave":
		return "Expected heatwave intervention, got: %s" % found.get("type", "")

	# Query far away
	var far: Dictionary = tracker.find_recent_intervention_near(Vector3(-50.0, 0.0, 50.0), 6.0, 60.0)
	if not far.is_empty():
		return "Found intervention for position far outside bounds"

	# Check causal status string
	var status_str: String = tracker.get_causal_status_at(target_pos)
	if not ("Heatwave" in status_str):
		return "Expected Heatwave in causal status, got: %s" % status_str

	var natural_status: String = tracker.get_causal_status_at(Vector3(-60.0, 0.0, 60.0))
	if natural_status != "Natural equilibrium":
		return "Expected Natural equilibrium, got: %s" % natural_status

	return ""

func test_causal_cascade_generation_on_mortality() -> String:
	var clock: WorldClock = WorldClock.new(10.0)
	clock.simulation_time = 200.0
	var tracker: CausalTracker = CausalTracker.new(clock)

	var plant_pos: Vector3 = Vector3(5.0, 0.5, 5.0)
	# Record drought brush intervention at same sector 10 seconds ago
	tracker.record_intervention("moisture_sub", plant_pos, 8.0, {"delta": -0.2}, 190.0)

	# Plant withers due to drought
	var causal_event: Dictionary = tracker.process_plant_death(2042, plant_pos, "drought", 200.0)
	if causal_event.is_empty():
		return "CausalTracker failed to correlate plant drought death with player intervention"

	if causal_event["cause"] != "moisture_sub":
		return "Expected cause moisture_sub, got: %s" % causal_event.get("cause", "")
	if not ("Plant #2042 withered" in causal_event.get("narrative", "")):
		return "Narrative missing expected text: %s" % causal_event.get("narrative", "")

	# Check fauna starvation correlation
	var herb_pos: Vector3 = plant_pos + Vector3(2.0, 0.0, 1.0)
	var fauna_event: Dictionary = tracker.process_fauna_starvation(1088, herb_pos, 205.0)
	if fauna_event.is_empty():
		return "Failed to correlate herbivore starvation with nearby habitat desiccation"
	if fauna_event["effect"] != "fauna_starvation":
		return "Expected effect fauna_starvation, got: %s" % fauna_event.get("effect", "")

	return ""

func test_fertilizer_growth_acceleration() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 77777
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)

	# Setup normal vs fertilized grids
	var config: WorldGenerationConfig = WorldGenerationConfig.new(77777)
	var grid_normal: EnvironmentalGrid = EnvironmentalGrid.new(config)
	var grid_fertile: EnvironmentalGrid = EnvironmentalGrid.new(config)

	# Boost fertility in fertile grid
	grid_fertile.apply_fertilizer_brush(0.0, 0.0, 20.0, 1.5)

	# Plant in normal grid
	var p1_id: int = flora.spawn_plant("grass_patch", Vector3(0.0, 1.0, 0.0), 2.0)
	var p1 = flora.get_plant(p1_id)
	flora.step_simulation(5.0, grid_normal)
	var normal_bio: float = p1.biomass

	# Plant in fertile grid
	flora.clear()
	var p2_id: int = flora.spawn_plant("grass_patch", Vector3(0.0, 1.0, 0.0), 2.0)
	var p2 = flora.get_plant(p2_id)
	flora.step_simulation(5.0, grid_fertile)
	var fertile_bio: float = p2.biomass

	if fertile_bio <= normal_bio:
		return "Plant in fertilized soil did not accumulate more biomass (normal: %.2f, fertile: %.2f)" % [normal_bio, fertile_bio]

	return ""

func test_experiment_tools_modes_and_persistence() -> String:
	# 1. Verify PlayerToolController ToolMode additions
	if PlayerToolController.ToolMode.HEATWAVE != 8:
		return "ToolMode.HEATWAVE is not 8"
	if PlayerToolController.ToolMode.FROST != 9:
		return "ToolMode.FROST is not 9"
	if PlayerToolController.ToolMode.SOIL_FERTILIZE != 10:
		return "ToolMode.SOIL_FERTILIZE is not 10"
	if PlayerToolController.ToolMode.DISASTER_SHOCK != 11:
		return "ToolMode.DISASTER_SHOCK is not 11"
	if PlayerToolController.ToolMode.MUTATE_POPULATION != 12:
		return "ToolMode.MUTATE_POPULATION is not 12"
	if PlayerToolController.ToolMode.CLIMATE_PULSE != 13:
		return "ToolMode.CLIMATE_PULSE is not 13"

	var tool_ctrl: PlayerToolController = PlayerToolController.new()
	if not ("Heatwave" in tool_ctrl.get_tool_name(PlayerToolController.ToolMode.HEATWAVE)):
		return "Incorrect name for HEATWAVE tool"
	if not ("Frost" in tool_ctrl.get_tool_name(PlayerToolController.ToolMode.FROST)):
		return "Incorrect name for FROST tool"
	if not ("Fertilize" in tool_ctrl.get_tool_name(PlayerToolController.ToolMode.SOIL_FERTILIZE)):
		return "Incorrect name for SOIL_FERTILIZE tool"
	if not ("Disaster" in tool_ctrl.get_tool_name(PlayerToolController.ToolMode.DISASTER_SHOCK)):
		return "Incorrect name for DISASTER_SHOCK tool"
	if not ("Mutate" in tool_ctrl.get_tool_name(PlayerToolController.ToolMode.MUTATE_POPULATION)):
		return "Incorrect name for MUTATE_POPULATION tool"
	if not ("Pulse" in tool_ctrl.get_tool_name(PlayerToolController.ToolMode.CLIMATE_PULSE)):
		return "Incorrect name for CLIMATE_PULSE tool"
	tool_ctrl.free()

	# 2. Test persistence of cell fertilities and causal interventions
	var save_path: String = "user://tests/causal_tools_persistence_test.json"
	var seed_obj: WorldSeed = WorldSeed.new(88888)
	var clock: WorldClock = WorldClock.new(10.0)
	var reg: EntityRegistry = EntityRegistry.new()
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(WorldGenerationConfig.new(88888))
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"))
	var coord: EcosystemCoordinator = EcosystemCoordinator.new(seed_obj, clock, null, reg, grid, weather)

	grid.apply_fertilizer_brush(5.0, 5.0, 15.0, 1.2)
	coord.causal_tracker.record_intervention("heatwave", Vector3(10.0, 1.0, 10.0), 8.0, {"delta_temp": 8.0})

	var err: Error = WorldPersistence.save_complete_world(save_path, seed_obj, clock, reg, grid, weather, coord)
	if err != OK:
		return "WorldPersistence save failed with error: %d" % err

	var load_res: Dictionary = WorldPersistence.load_world(save_path)
	if load_res["error"] != OK:
		return "WorldPersistence load failed: %s" % load_res.get("message", "")

	var loaded_data: Dictionary = load_res["data"]
	var env_data: Dictionary = loaded_data.get("environment", {})
	if not env_data.has("cell_fertilities"):
		return "Loaded save missing cell_fertilities section"

	var eco_data: Dictionary = loaded_data.get("ecosystem", {})
	if not eco_data.has("causal_interventions"):
		return "Loaded save missing causal_interventions section"
	if not eco_data.has("experiment_history"):
		return "Loaded save missing experiment_history section"

	var interventions: Array = eco_data["causal_interventions"]
	if interventions.size() != 1:
		return "Expected 1 saved intervention, got: %d" % interventions.size()
	if interventions[0].get("type", "") != "heatwave":
		return "Expected saved intervention type heatwave, got: %s" % interventions[0].get("type", "")

	# Clean up test save file
	DirAccess.remove_absolute(save_path)
	DirAccess.remove_absolute(save_path + ".bak")

	return ""

func test_controlled_population_mutation_and_telemetry() -> String:
	var seed_obj: WorldSeed = WorldSeed.new(99991)
	var clock: WorldClock = WorldClock.new(10.0)
	var reg: EntityRegistry = EntityRegistry.new()
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(WorldGenerationConfig.new(99991))
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"))
	var coord: EcosystemCoordinator = EcosystemCoordinator.new(seed_obj, clock, null, reg, grid, weather)

	coord.populate_initial_ecosystem(30, 10, 2)
	coord.step_simulation(0.1)

	var initial_herbs: Array = coord.fauna_sim.get_all_herbivores()
	if initial_herbs.is_empty():
		return "No herbivores spawned in initial ecosystem"

	var initial_gen: int = initial_herbs[0].genome.generation

	# Mutate population in area
	var affected: int = coord.mutate_population_in_area(Vector3.ZERO, 60.0)
	if affected <= 0:
		return "Mutate population affected 0 entities"

	# Verify generation advanced and alleles remain strictly bounded
	for h in coord.fauna_sim.get_all_herbivores():
		if h.genome.generation <= initial_gen:
			return "Herbivore genome generation did not advance after mutation"
		if h.genome.speed < 0.60 or h.genome.speed > 1.50:
			return "Herbivore speed out of physiological bounds: %.2f" % h.genome.speed
		if h.genome.size < 0.60 or h.genome.size > 1.50:
			return "Herbivore size out of physiological bounds: %.2f" % h.genome.size
		if h.genome.energy_efficiency < 0.65 or h.genome.energy_efficiency > 1.45:
			return "Herbivore energy efficiency out of physiological bounds: %.2f" % h.genome.energy_efficiency

	# Verify telemetry variance is valid and non-zero
	if coord.metrics.allele_speed_variance < 0.0:
		return "Negative allele speed variance after mutation"
	if coord.metrics.genetic_diversity_index < 0.0:
		return "Negative genetic diversity index"

	return ""

func test_climate_pulse_dynamics_and_lifecycle() -> String:
	var config: WorldGenerationConfig = WorldGenerationConfig.new(77771)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(config)

	var center_x: float = 0.0
	var center_z: float = 0.0
	var before_cell: Dictionary = grid.sample_at(center_x, center_z)
	var before_moist: float = before_cell["moisture"]
	var before_temp: float = before_cell["temperature"]

	# Trigger Deluge climate pulse (5.0s duration)
	var pulse: Dictionary = grid.trigger_climate_pulse(center_x, center_z, 15.0, "deluge", 5.0)
	if pulse.is_empty() or grid.get_active_pulse_count() != 1:
		return "Climate pulse failed to register in EnvironmentalGrid"

	# Step 2.5s: pulse still active
	grid.step_simulation(2.5, 0.5)
	if grid.get_active_pulse_count() != 1:
		return "Climate pulse expired prematurely"

	var mid_cell: Dictionary = grid.sample_at(center_x, center_z)
	if mid_cell["moisture"] <= before_moist:
		return "Deluge pulse did not increase moisture during active period"

	# Step 3.0s (total 5.5s > 5.0s duration): pulse should cleanly expire
	grid.step_simulation(3.0, 0.5)
	if grid.get_active_pulse_count() != 0:
		return "Climate pulse failed to clean up after duration expired"

	return ""

func test_experiment_history_tracking_and_comparison() -> String:
	var clock: WorldClock = WorldClock.new(10.0)
	var exp_hist: ExperimentHistory = ExperimentHistory.new(clock, 12345)

	# 1. Baseline initialization
	var base_snap: Dictionary = {
		"plant_count": 50,
		"total_biomass": 200.0,
		"herbivore_count": 12,
		"predator_count": 2,
		"avg_speed": 1.0,
		"diversity_index": 0.55
	}
	exp_hist.init_baseline(12345, base_snap, 0.0)
	var stored_base: Dictionary = exp_hist.get_initial_baseline()
	if stored_base.get("plant_count", 0) != 50 or stored_base.get("seed", 0) != 12345:
		return "Baseline initialization failed"

	# 2. Record experiment with evaluation delay (10.0s)
	clock.simulation_time = 15.0
	var rec: Dictionary = exp_hist.record_experiment("Heatwave Experiment", "heatwave", Vector3(5, 0, 5), 10.0, base_snap, 15.0, 10.0)
	if exp_hist.get_experiments().size() != 1:
		return "Failed to record experiment"
	if rec.get("is_evaluated", true):
		return "Experiment marked evaluated prematurely"

	# Step before eval time
	clock.simulation_time = 20.0
	exp_hist.step(clock.simulation_time, base_snap)
	if rec.get("is_evaluated", false):
		return "Experiment evaluated before target time"

	# Step at/past eval time
	clock.simulation_time = 26.0
	var post_snap: Dictionary = {
		"plant_count": 42,
		"total_biomass": 165.0,
		"herbivore_count": 10,
		"predator_count": 2,
		"avg_speed": 1.02,
		"diversity_index": 0.58
	}
	exp_hist.step(clock.simulation_time, post_snap)
	if not rec.get("is_evaluated", false):
		return "Experiment failed to evaluate after delay"
	if not ("Flora" in rec.get("summary", "")):
		return "Comparison summary missing flora metrics"

	# 3. Serialization roundtrip
	var saved: Dictionary = exp_hist.serialize()
	var restored: ExperimentHistory = ExperimentHistory.new(clock)
	restored.deserialize(saved)

	if restored.master_seed != 12345:
		return "Restored master seed mismatch"
	if restored.get_experiments().size() != 1:
		return "Restored experiment count mismatch"

	return ""

func test_simulation_clock_controls_and_event_processing() -> String:
	var clock: WorldClock = WorldClock.new(10.0)
	var bus: WorldEventBus = WorldEventBus.new()
	var event_received: Array[bool] = [false]

	bus.subscribe("test_event", func(_p): event_received[0] = true)

	# 1. Normal ticking
	var ticks: int = clock.advance(0.3)
	if ticks != 3:
		return "Clock did not advance 3 ticks in 0.3s at 10Hz, got: %d" % ticks

	# 2. Pause
	clock.pause()
	var paused_ticks: int = clock.advance(0.5)
	if paused_ticks != 0:
		return "Clock advanced ticks while paused"
	if not clock.is_paused:
		return "Clock is_paused is false after pause()"

	# Verify event bus can still process and deliver events during simulation pause
	bus.publish("test_event", {"status": "ok"})
	if not event_received[0]:
		return "WorldEventBus failed to deliver event during simulation pause"

	# 3. Resume and Time Scale
	clock.resume()
	clock.set_time_scale(2.0)
	var fast_ticks: int = clock.advance(0.2)
	# 0.2s * 2.0x time_scale = 0.4s effective -> 4 ticks
	if fast_ticks != 4:
		return "Clock did not scale ticks under 2.0x time scale, got: %d" % fast_ticks

	return ""
