extends RefCounted

func test_save_and_load_roundtrip() -> Variant:
	var seed_obj: WorldSeed = WorldSeed.new(998877)
	var clock: WorldClock = WorldClock.new(10.0)
	clock.simulation_time = 42.5
	clock.tick_count = 425
	clock.time_scale = 1.5
	
	var registry: EntityRegistry = EntityRegistry.new()
	registry.spawn_entity("pine", Vector3(10, 0, 20), {"health": 100.0})
	registry.spawn_entity("wolf", Vector3(5, 0, 5), {"health": 90.0})
	
	var test_path: String = "user://tests/persistence_test.json"
	var save_err: Error = WorldPersistence.save_world(test_path, seed_obj, clock, registry)
	if save_err != OK:
		return "save_world failed with error code: %d" % save_err
		
	var result: Dictionary = WorldPersistence.load_world(test_path)
	if result.get("error", ERR_CANT_OPEN) != OK:
		return "load_world failed with error: %d" % result.get("error", -1)
		
	var data: Dictionary = result.get("data", {})
	if data["seed"]["master_seed"] != 998877:
		return "Restored master_seed mismatch: %d" % data["seed"]["master_seed"]
		
	if not is_equal_approx(data["clock"]["simulation_time"], 42.5):
		return "Restored simulation_time mismatch: %f" % data["clock"]["simulation_time"]
		
	if data["entities"].size() != 2:
		return "Restored entities count mismatch: %d != 2" % data["entities"].size()
		
	var ent0: Dictionary = data["entities"][0]
	if ent0["position"] != Vector3(10, 0, 20):
		return "Restored position Vector3 mismatch: %s" % str(ent0["position"])
		
	return null

func test_backup_rotation() -> Variant:
	var seed_obj: WorldSeed = WorldSeed.new(1)
	var clock: WorldClock = WorldClock.new(10.0)
	var registry: EntityRegistry = EntityRegistry.new()
	var test_path: String = "user://tests/rotation_test.json"
	
	# First save
	WorldPersistence.save_world(test_path, seed_obj, clock, registry)
	# Second save should rotate first save to .bak
	seed_obj.set_master_seed(2)
	WorldPersistence.save_world(test_path, seed_obj, clock, registry)
	
	var bak_path: String = test_path + ".bak"
	if not FileAccess.file_exists(bak_path):
		return "Backup file (.bak) was not created upon rotation"
		
	return null
