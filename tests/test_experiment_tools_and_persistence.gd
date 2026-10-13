class_name TestExperimentToolsAndPersistence
extends RefCounted

## Automated test suite for Block 5: Experiment Tools, Observability, and Save/Load Persistence.

const FloraSimulation = preload("res://core/ecosystem/flora_simulation.gd")
const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")

func test_save_and_load_roundtrip_v2() -> Variant:
	var seed_obj: WorldSeed = WorldSeed.new(778899)
	var clock: WorldClock = WorldClock.new(10.0)
	clock.simulation_time = 64.2
	clock.tick_count = 642
	clock.set_time_scale(2.0)
	clock.set_paused(false)

	var bus: WorldEventBus = WorldEventBus.new()
	var registry: EntityRegistry = EntityRegistry.new(bus)
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(778899)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)
	weather.set_state(WeatherSystem.WeatherState.RAIN, 42.5)

	# Mutate specific grid cells
	grid.apply_moisture_brush(10.0, 10.0, 6.0, 0.25)
	var cell_sample_pre: Dictionary = grid.sample_at(10.0, 10.0)
	var expected_moisture: float = cell_sample_pre.get("moisture", 0.0)

	var coord: EcosystemCoordinator = EcosystemCoordinator.new(
		seed_obj, clock, bus, registry, grid, weather
	)

	# Spawn specific known flora and fauna
	var p1_id: int = coord.flora_sim.spawn_plant("shrub_bush", Vector3(12.0, 1.5, 14.0), 5.5)
	var p2_id: int = coord.flora_sim.spawn_plant("grass_patch", Vector3(-8.0, 2.0, -10.0), 3.2)
	var h1_id: int = coord.fauna_sim.spawn_herbivore(Vector3(15.0, 1.2, 10.0), 88.0)
	var pr1_id: int = coord.fauna_sim.spawn_predator(Vector3(-12.0, 3.0, 22.0), 75.0)

	var test_path: String = "user://tests/roundtrip_v2_test.json"
	var err: Error = WorldPersistence.save_complete_world(
		test_path, seed_obj, clock, registry, grid, weather, coord
	)
	if err != OK:
		return "save_complete_world failed with error code: %d" % err

	# Clear / mutate state
	grid.apply_moisture_brush(10.0, 10.0, 6.0, -0.40)
	coord.flora_sim.clear()
	coord.fauna_sim.clear()
	registry.clear()
	clock.simulation_time = 0.0
	clock.tick_count = 0
	weather.set_state(WeatherSystem.WeatherState.CLEAR, 10.0)

	# Restore state via bootstrap loading logic
	var load_result: Dictionary = WorldPersistence.load_world(test_path)
	if load_result.get("error", ERR_CANT_OPEN) != OK:
		return "load_world failed: %s" % load_result.get("message", "")

	var data: Dictionary = load_result.get("data", {})

	# 1. Verify Seed & Clock
	if data["seed"]["master_seed"] != 778899:
		return "Restored master_seed mismatch: %d" % data["seed"]["master_seed"]
	if not is_equal_approx(data["clock"]["simulation_time"], 64.2):
		return "Restored simulation_time mismatch: %f" % data["clock"]["simulation_time"]
	if data["clock"]["tick_count"] != 642:
		return "Restored tick_count mismatch: %d" % data["clock"]["tick_count"]
	if not is_equal_approx(data["clock"]["time_scale"], 2.0):
		return "Restored time_scale mismatch: %f" % data["clock"]["time_scale"]

	# 2. Verify Weather
	if data["weather"]["current_state"] != WeatherSystem.WeatherState.RAIN:
		return "Restored weather state mismatch: %d" % data["weather"]["current_state"]

	# 3. Verify Grid Moisture Restoration
	var env_data: Dictionary = data["environment"]
	grid.restore_cell_data(env_data["cell_moistures"], env_data["cell_temperatures"])
	var cell_sample_post: Dictionary = grid.sample_at(10.0, 10.0)
	if not is_equal_approx(cell_sample_post.get("moisture", 0.0), expected_moisture):
		return "Grid restored moisture mismatch: %f != %f" % [cell_sample_post.get("moisture", 0.0), expected_moisture]

	# 4. Verify Ecosystem Restoration
	var plants: Array = data["ecosystem"]["plants"]
	if plants.size() != 2:
		return "Restored plants count mismatch: %d != 2" % plants.size()
	for p in plants:
		coord.flora_sim.restore_plant(p)
	if coord.flora_sim.get_plant(p1_id) == null:
		return "Plant #%d not found in restored flora_sim" % p1_id
	if coord.flora_sim.get_plant(p1_id).species != "shrub_bush":
		return "Plant #%d species mismatch" % p1_id

	var herbivores: Array = data["ecosystem"]["herbivores"]
	if herbivores.size() != 1:
		return "Restored herbivores count mismatch: %d != 1" % herbivores.size()
	for h in herbivores:
		coord.fauna_sim.restore_herbivore(h)
	if coord.fauna_sim.get_herbivore(h1_id) == null:
		return "Herbivore #%d not found in restored fauna_sim" % h1_id
	if not is_equal_approx(coord.fauna_sim.get_herbivore(h1_id).energy, 88.0):
		return "Herbivore #%d energy mismatch: %f" % [h1_id, coord.fauna_sim.get_herbivore(h1_id).energy]

	var predators: Array = data["ecosystem"]["predators"]
	if predators.size() != 1:
		return "Restored predators count mismatch: %d != 1" % predators.size()
	for pr in predators:
		coord.fauna_sim.restore_predator(pr)
	if coord.fauna_sim.get_predator(pr1_id) == null:
		return "Predator #%d not found in restored fauna_sim" % pr1_id

	# 5. Verify EntityRegistry Synchronization
	if registry.get_count() != 4:
		return "EntityRegistry count mismatch after restoration: %d != 4" % registry.get_count()

	return null

func test_corrupted_file_and_schema_validation() -> Variant:
	var corrupt_path: String = "user://tests/corrupt_file_test.json"
	var dir_path: String = corrupt_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	# Case A: Corrupted JSON syntax
	var file: FileAccess = FileAccess.open(corrupt_path, FileAccess.WRITE)
	file.store_string("{\n\t\"version\": 2,\n\t\"seed\": { \"master_seed\": ") # Unfinished JSON
	file.close()

	var result: Dictionary = WorldPersistence.load_world(corrupt_path)
	if result.get("error", OK) == OK:
		return "Corrupted JSON file did not return error!"

	# Case B: Automatic fallback to .bak when primary file is corrupt
	var bak_path: String = corrupt_path + ".bak"
	var valid_payload: Dictionary = {
		"version": 2,
		"seed": {"master_seed": 54321},
		"clock": {"simulation_time": 10.0, "tick_count": 100, "time_scale": 1.0, "is_paused": false}
	}
	var bak_file: FileAccess = FileAccess.open(bak_path, FileAccess.WRITE)
	bak_file.store_string(JSON.stringify(valid_payload))
	bak_file.close()

	var fallback_res: Dictionary = WorldPersistence.load_world(corrupt_path)
	if fallback_res.get("error", ERR_FILE_CORRUPT) != OK:
		return "Fallback to .bak failed when primary file was corrupt!"
	if fallback_res["data"]["seed"]["master_seed"] != 54321:
		return "Data restored from fallback .bak mismatch: %d" % fallback_res["data"]["seed"]["master_seed"]

	# Case C: Unsupported future schema version
	var future_payload: Dictionary = {
		"version": 99,
		"seed": {"master_seed": 1},
		"clock": {"simulation_time": 0.0}
	}
	var f_file: FileAccess = FileAccess.open(corrupt_path, FileAccess.WRITE)
	f_file.store_string(JSON.stringify(future_payload))
	f_file.close()
	if FileAccess.file_exists(bak_path):
		DirAccess.remove_absolute(bak_path)

	var future_res: Dictionary = WorldPersistence.load_world(corrupt_path)
	if future_res.get("error", OK) != ERR_INVALID_DATA:
		return "Future schema version 99 was not rejected with ERR_INVALID_DATA"

	# Case D: Missing required schema fields (missing clock)
	var missing_payload: Dictionary = {
		"version": 2,
		"seed": {"master_seed": 1}
	}
	var m_file: FileAccess = FileAccess.open(corrupt_path, FileAccess.WRITE)
	m_file.store_string(JSON.stringify(missing_payload))
	m_file.close()

	var missing_res: Dictionary = WorldPersistence.load_world(corrupt_path)
	if missing_res.get("error", OK) != ERR_INVALID_DATA:
		return "Payload missing clock section was not rejected with ERR_INVALID_DATA"

	return null

func test_atomic_save_and_backup_rotation() -> Variant:
	var path: String = "user://tests/atomic_rotation_test.json"
	var seed1: WorldSeed = WorldSeed.new(111)
	var seed2: WorldSeed = WorldSeed.new(222)
	var clock: WorldClock = WorldClock.new(10.0)
	var reg: EntityRegistry = EntityRegistry.new()

	# First save
	WorldPersistence.save_world(path, seed1, clock, reg)
	if not FileAccess.file_exists(path):
		return "Initial save file does not exist"

	# Second save
	WorldPersistence.save_world(path, seed2, clock, reg)
	var bak_path: String = path + ".bak"
	if not FileAccess.file_exists(bak_path):
		return "Backup file (.bak) was not created upon rotation"

	var active_data: Dictionary = WorldPersistence.load_world(path)
	if active_data["data"]["seed"]["master_seed"] != 222:
		return "Active file does not contain latest save (expected 222)"

	var bak_data: Dictionary = WorldPersistence.load_world(bak_path)
	if bak_data["data"]["seed"]["master_seed"] != 111:
		return "Backup file (.bak) does not contain previous save (expected 111)"

	# Verify .tmp does not remain
	var tmp_path: String = path + ".tmp"
	if FileAccess.file_exists(tmp_path):
		return "Temporary file (.tmp) lingered after save promotion"

	return null

func test_clean_world_reset() -> Variant:
	var seed_obj: WorldSeed = WorldSeed.new(333)
	var clock: WorldClock = WorldClock.new(10.0)
	clock.simulation_time = 120.0
	clock.tick_count = 1200

	var bus: WorldEventBus = WorldEventBus.new()
	var reg: EntityRegistry = EntityRegistry.new(bus)
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(333)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)
	var sched: SimulationScheduler = SimulationScheduler.new(clock)

	var coord: EcosystemCoordinator = EcosystemCoordinator.new(
		seed_obj, clock, bus, reg, grid, weather, sched
	)
	coord.populate_initial_ecosystem(30, 8, 2)

	if reg.get_count() == 0:
		return "Initial ecosystem population failed to populate registry"

	# Perform complete world reset
	reg.clear()
	clock.reset()
	coord.clear()
	sched.clear()
	seed_obj.set_master_seed(999)

	# Verify pristine state
	if seed_obj.master_seed != 999:
		return "New seed not applied on reset"
	if clock.simulation_time != 0.0 or clock.tick_count != 0:
		return "Clock not zeroed on reset"
	if reg.get_count() != 0:
		return "EntityRegistry has leftover entities after reset: %d" % reg.get_count()
	if coord.flora_sim.get_plant_count() != 0:
		return "FloraSimulation has lingering plants after reset: %d" % coord.flora_sim.get_plant_count()
	if coord.fauna_sim.get_herbivore_count() != 0:
		return "FaunaSimulation has lingering herbivores after reset: %d" % coord.fauna_sim.get_herbivore_count()
	if coord.fauna_sim.get_predator_count() != 0:
		return "FaunaSimulation has lingering predators after reset: %d" % coord.fauna_sim.get_predator_count()

	return null

func test_player_moisture_brush_intervention() -> Variant:
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(1234)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)

	var pre_center: Dictionary = grid.sample_at(15.0, 15.0)
	var m_before: float = pre_center.get("moisture", 0.5)

	var distant_pre: Dictionary = grid.sample_at(-60.0, -60.0)
	var distant_m_before: float = distant_pre.get("moisture", 0.5)

	# Apply +0.25 moisture in 8m radius
	var affected: int = grid.apply_moisture_brush(15.0, 15.0, 8.0, 0.25)
	if affected <= 0:
		return "apply_moisture_brush affected 0 cells in 8m radius"

	var post_center: Dictionary = grid.sample_at(15.0, 15.0)
	var m_after: float = post_center.get("moisture", 0.5)
	if m_after <= m_before:
		return "Moisture did not increase at brush center: %f <= %f" % [m_after, m_before]

	# Verify distant cells unaffected
	var distant_post: Dictionary = grid.sample_at(-60.0, -60.0)
	var distant_m_after: float = distant_post.get("moisture", 0.5)
	if not is_equal_approx(distant_m_before, distant_m_after):
		return "Distant cell moisture unexpectedly changed: %f != %f" % [distant_m_before, distant_m_after]

	# Apply -0.35 moisture reduction
	grid.apply_moisture_brush(15.0, 15.0, 8.0, -0.35)
	var post_sub: Dictionary = grid.sample_at(15.0, 15.0)
	var m_sub: float = post_sub.get("moisture", 0.5)
	if m_sub >= m_after:
		return "Moisture did not decrease after negative brush: %f >= %f" % [m_sub, m_after]

	return null

func test_entity_spawn_inspect_and_delete_tools() -> Variant:
	var seed_obj: WorldSeed = WorldSeed.new(555)
	var bus: WorldEventBus = WorldEventBus.new()
	var reg: EntityRegistry = EntityRegistry.new(bus)
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna_sim: FaunaSimulation = FaunaSimulation.new(seed_obj.get_stream("ecology"), reg, metrics, bus)

	# 1. Spawn Tool Test
	var deer_id: int = fauna_sim.spawn_herbivore(Vector3(20.0, 1.5, 20.0), 85.0)
	if not fauna_sim.get_herbivore(deer_id):
		return "Failed to spawn herbivore via fauna_sim"
	if not reg.has_entity(deer_id):
		return "Spawned herbivore was not registered in EntityRegistry"
	if metrics.births_total != 1:
		return "Birth was not recorded in EcosystemMetrics"

	# 2. Inspection Query Test
	var h_data = fauna_sim.get_herbivore(deer_id)
	if h_data.species != "island_deer":
		return "Inspected species mismatch: %s" % h_data.species
	if not is_equal_approx(h_data.energy, 85.0):
		return "Inspected energy mismatch: %f" % h_data.energy

	# 3. Delete Tool Test
	fauna_sim.remove_herbivore(deer_id, "player_deleted")
	if fauna_sim.get_herbivore(deer_id) != null:
		return "Herbivore was not removed from fauna_sim"
	if reg.has_entity(deer_id):
		return "Deleted herbivore was not removed from EntityRegistry"
	if metrics.deaths_total != 1:
		return "Death was not recorded in EcosystemMetrics"

	return null
