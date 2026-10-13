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

func run_all() -> int:
	var passed: int = 0
	passed += _test("test_climate_brushes_temperature_and_fertility", Callable(self, "test_climate_brushes_temperature_and_fertility"))
	passed += _test("test_disaster_shock_impact", Callable(self, "test_disaster_shock_impact"))
	passed += _test("test_causal_tracker_interventions_and_queries", Callable(self, "test_causal_tracker_interventions_and_queries"))
	passed += _test("test_causal_cascade_generation_on_mortality", Callable(self, "test_causal_cascade_generation_on_mortality"))
	passed += _test("test_fertilizer_growth_acceleration", Callable(self, "test_fertilizer_growth_acceleration"))
	passed += _test("test_experiment_tools_modes_and_persistence", Callable(self, "test_experiment_tools_modes_and_persistence"))
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

	var tool_ctrl: PlayerToolController = PlayerToolController.new()
	if not ("Heatwave" in tool_ctrl.get_tool_name(PlayerToolController.ToolMode.HEATWAVE)):
		return "Incorrect name for HEATWAVE tool"
	if not ("Frost" in tool_ctrl.get_tool_name(PlayerToolController.ToolMode.FROST)):
		return "Incorrect name for FROST tool"
	if not ("Fertilize" in tool_ctrl.get_tool_name(PlayerToolController.ToolMode.SOIL_FERTILIZE)):
		return "Incorrect name for SOIL_FERTILIZE tool"
	if not ("Disaster" in tool_ctrl.get_tool_name(PlayerToolController.ToolMode.DISASTER_SHOCK)):
		return "Incorrect name for DISASTER_SHOCK tool"
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

	var interventions: Array = eco_data["causal_interventions"]
	if interventions.size() != 1:
		return "Expected 1 saved intervention, got: %d" % interventions.size()
	if interventions[0].get("type", "") != "heatwave":
		return "Expected saved intervention type heatwave, got: %s" % interventions[0].get("type", "")

	# Clean up test save file
	DirAccess.remove_absolute(save_path)
	DirAccess.remove_absolute(save_path + ".bak")

	return ""
