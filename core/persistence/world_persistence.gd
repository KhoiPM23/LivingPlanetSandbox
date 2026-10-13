class_name WorldPersistence
extends RefCounted

## Handles atomic, versioned save/load state persistence.
## Supports Schema v1 and Schema v2 (complete ecological, environmental & physical simulation state).

const CURRENT_SCHEMA_VERSION: int = 2
const DEFAULT_SAVE_PATH: String = "user://saves/world_state.json"

## Complete Save for Schema Version 2
static func save_complete_world(
	save_path: String,
	world_seed: WorldSeed,
	clock: WorldClock,
	registry: EntityRegistry,
	grid: EnvironmentalGrid = null,
	weather: WeatherSystem = null,
	coordinator: EcosystemCoordinator = null,
	extra_data: Dictionary = {}
) -> Error:
	var dir_path: String = save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		var err_dir: Error = DirAccess.make_dir_recursive_absolute(dir_path)
		if err_dir != OK:
			return err_dir

	var payload: Dictionary = {
		"version": CURRENT_SCHEMA_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"seed": {
			"master_seed": world_seed.master_seed if world_seed else 0
		},
		"clock": {
			"simulation_time": clock.simulation_time if clock else 0.0,
			"tick_count": clock.tick_count if clock else 0,
			"time_scale": clock.time_scale if clock else 1.0,
			"is_paused": clock.is_paused if clock else false
		},
		"config": {},
		"weather": {},
		"environment": {},
		"ecosystem": {
			"plants": [],
			"herbivores": [],
			"predators": []
		},
		"metrics": {},
		"entities": [],
		"extra": extra_data
	}

	# 1. Config & Environment Grid
	if grid:
		var cfg: WorldGenerationConfig = grid.get_config()
		if cfg:
			payload["config"] = {
				"island_size": cfg.island_size,
				"water_level": cfg.water_level,
				"base_temperature": cfg.base_temperature,
				"base_moisture": cfg.base_moisture,
				"lapse_rate": cfg.lapse_rate
			}

		var cell_moistures: Array[float] = []
		var cell_temps: Array[float] = []
		for i in range(grid.get_cell_count()):
			var cell: Dictionary = grid.get_cell(i)
			cell_moistures.append(float(cell.get("moisture", 0.5)))
			cell_temps.append(float(cell.get("temperature", 20.0)))


		payload["environment"] = {
			"grid_size": grid.grid_size,
			"cell_moistures": cell_moistures,
			"cell_temperatures": cell_temps
		}

	# 2. Weather System
	if weather:
		payload["weather"] = {
			"current_state": int(weather.current_state),
			"duration_remaining": snapped(weather.duration_remaining, 0.1)
		}

	# 3. Ecosystem Coordinator (Flora & Fauna simulation instances)
	if coordinator:
		if coordinator.flora_sim:
			for p in coordinator.flora_sim.get_all_plants():
				payload["ecosystem"]["plants"].append({
					"id": p.id,
					"species": p.species,
					"position": [snapped(p.position.x, 0.01), snapped(p.position.y, 0.01), snapped(p.position.z, 0.01)],
					"biomass": snapped(p.biomass, 0.1),
					"max_biomass": snapped(p.max_biomass, 0.1),
					"health": snapped(p.health, 0.1),
					"age": snapped(p.age, 0.1),
					"stage": int(p.stage)
				})

		if coordinator.fauna_sim:
			for h in coordinator.fauna_sim.get_all_herbivores():
				payload["ecosystem"]["herbivores"].append({
					"id": h.id,
					"species": h.species,
					"position": [snapped(h.position.x, 0.01), snapped(h.position.y, 0.01), snapped(h.position.z, 0.01)],
					"velocity": [snapped(h.velocity.x, 0.01), snapped(h.velocity.y, 0.01), snapped(h.velocity.z, 0.01)],
					"heading": snapped(h.heading, 0.01),
					"health": snapped(h.health, 0.1),
					"energy": snapped(h.energy, 0.1),
					"age": snapped(h.age, 0.1),
					"life_stage": int(h.life_stage),
					"state": int(h.state)
				})

			for pr in coordinator.fauna_sim.get_all_predators():
				payload["ecosystem"]["predators"].append({
					"id": pr.id,
					"species": pr.species,
					"position": [snapped(pr.position.x, 0.01), snapped(pr.position.y, 0.01), snapped(pr.position.z, 0.01)],
					"velocity": [snapped(pr.velocity.x, 0.01), snapped(pr.velocity.y, 0.01), snapped(pr.velocity.z, 0.01)],
					"heading": snapped(pr.heading, 0.01),
					"health": snapped(pr.health, 0.1),
					"energy": snapped(pr.energy, 0.1),
					"age": snapped(pr.age, 0.1),
					"life_stage": int(pr.life_stage),
					"state": int(pr.state)
				})

		if coordinator.metrics:
			payload["metrics"] = {
				"births_total": coordinator.metrics.births_total,
				"births_by_type": coordinator.metrics.births_by_type.duplicate(),
				"deaths_total": coordinator.metrics.deaths_total,
				"deaths_by_cause": coordinator.metrics.deaths_by_cause.duplicate()
			}

	# 4. Entity Registry (backward compatible + general props)
	if registry:
		for id: int in registry.get_all_ids():
			var ent: Dictionary = registry.get_entity(id)
			var ent_copy: Dictionary = ent.duplicate(true)
			if ent_copy.has("position") and ent_copy["position"] is Vector3:
				var pos: Vector3 = ent_copy["position"]
				ent_copy["position"] = [pos.x, pos.y, pos.z]
			payload["entities"].append(ent_copy)

	return _write_atomic_file(save_path, payload)

## Backward compatible save function for Schema v1 and simple callers
static func save_world(save_path: String, world_seed: WorldSeed, clock: WorldClock, registry: EntityRegistry, extra_data: Dictionary = {}) -> Error:
	var dir_path: String = save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		var err_dir: Error = DirAccess.make_dir_recursive_absolute(dir_path)
		if err_dir != OK:
			return err_dir

	var payload: Dictionary = {
		"version": CURRENT_SCHEMA_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"seed": {
			"master_seed": world_seed.master_seed if world_seed else 0
		},
		"clock": {
			"simulation_time": clock.simulation_time if clock else 0.0,
			"tick_count": clock.tick_count if clock else 0,
			"time_scale": clock.time_scale if clock else 1.0,
			"is_paused": clock.is_paused if clock else false
		},
		"entities": [],
		"extra": extra_data
	}

	if registry:
		for id: int in registry.get_all_ids():
			var ent: Dictionary = registry.get_entity(id)
			var ent_copy: Dictionary = ent.duplicate(true)
			if ent_copy.has("position") and ent_copy["position"] is Vector3:
				var pos: Vector3 = ent_copy["position"]
				ent_copy["position"] = [pos.x, pos.y, pos.z]
			payload["entities"].append(ent_copy)

	return _write_atomic_file(save_path, payload)

static func _write_atomic_file(save_path: String, payload: Dictionary) -> Error:
	var json_string: String = JSON.stringify(payload, "\t")
	var tmp_path: String = save_path + ".tmp"
	var bak_path: String = save_path + ".bak"

	# 1. Write atomic temporary file
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(json_string)
	file.flush()
	file.close()

	# 2. Rotate backup if existing save exists
	if FileAccess.file_exists(save_path):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		var backup_err: Error = DirAccess.rename_absolute(save_path, bak_path)
		if backup_err != OK:
			printerr("[WorldPersistence] Warning: Failed to rotate backup: %d" % backup_err)

	# 3. Promote temp file to official save
	var rename_err: Error = DirAccess.rename_absolute(tmp_path, save_path)
	return rename_err

static func load_world(save_path: String) -> Dictionary:
	var path_to_load: String = save_path
	if not FileAccess.file_exists(path_to_load):
		var bak_path: String = save_path + ".bak"
		if FileAccess.file_exists(bak_path):
			path_to_load = bak_path
		else:
			return {"error": ERR_FILE_NOT_FOUND, "data": {}, "message": "Save file not found"}

	var file: FileAccess = FileAccess.open(path_to_load, FileAccess.READ)
	if not file:
		return {"error": FileAccess.get_open_error(), "data": {}, "message": "Could not open save file"}

	var content: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(content)
	if parse_err != OK:
		# Attempt fallback to .bak if available and not already on .bak
		var bak_path: String = save_path + ".bak"
		if path_to_load != bak_path and FileAccess.file_exists(bak_path):
			print("[WorldPersistence] Primary save corrupted. Attempting fallback to backup: " + bak_path)
			return load_world(bak_path)
		return {"error": parse_err, "data": {}, "message": "Corrupted JSON: " + json.get_error_message()}

	var data: Variant = json.data
	if not (data is Dictionary):
		return {"error": ERR_INVALID_DATA, "data": {}, "message": "Root save content is not a JSON object"}

	var save_dict: Dictionary = data as Dictionary

	# Schema Validation
	if not save_dict.has("version"):
		return {"error": ERR_INVALID_DATA, "data": {}, "message": "Missing schema version"}

	var ver: int = int(save_dict.get("version", 0))
	if ver > CURRENT_SCHEMA_VERSION or ver < 1:
		return {"error": ERR_INVALID_DATA, "data": {}, "message": "Unsupported schema version: %d (Current: %d)" % [ver, CURRENT_SCHEMA_VERSION]}

	if not save_dict.has("seed") or not save_dict.has("clock"):
		return {"error": ERR_INVALID_DATA, "data": {}, "message": "Missing required save sections (seed or clock)"}

	# Vector3 Deserialization Helper
	_deserialize_positions(save_dict)

	return {"error": OK, "data": save_dict}

static func _deserialize_positions(data: Dictionary) -> void:
	# Registry entities
	if data.has("entities") and data["entities"] is Array:
		for ent: Variant in data["entities"]:
			if ent is Dictionary and ent.has("position") and ent["position"] is Array:
				var arr: Array = ent["position"]
				if arr.size() >= 3:
					ent["position"] = Vector3(float(arr[0]), float(arr[1]), float(arr[2]))

	# Ecosystem entities (v2)
	if data.has("ecosystem") and data["ecosystem"] is Dictionary:
		var eco: Dictionary = data["ecosystem"]
		if eco.has("plants") and eco["plants"] is Array:
			for p: Variant in eco["plants"]:
				if p is Dictionary and p.has("position") and p["position"] is Array:
					var arr: Array = p["position"]
					if arr.size() >= 3:
						p["position"] = Vector3(float(arr[0]), float(arr[1]), float(arr[2]))

		if eco.has("herbivores") and eco["herbivores"] is Array:
			for h: Variant in eco["herbivores"]:
				if h is Dictionary and h.has("position") and h["position"] is Array:
					var arr: Array = h["position"]
					if arr.size() >= 3:
						h["position"] = Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
				if h is Dictionary and h.has("velocity") and h["velocity"] is Array:
					var varr: Array = h["velocity"]
					if varr.size() >= 3:
						h["velocity"] = Vector3(float(varr[0]), float(varr[1]), float(varr[2]))

		if eco.has("predators") and eco["predators"] is Array:
			for pr: Variant in eco["predators"]:
				if pr is Dictionary and pr.has("position") and pr["position"] is Array:
					var arr: Array = pr["position"]
					if arr.size() >= 3:
						pr["position"] = Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
				if pr is Dictionary and pr.has("velocity") and pr["velocity"] is Array:
					var varr: Array = pr["velocity"]
					if varr.size() >= 3:
						pr["velocity"] = Vector3(float(varr[0]), float(varr[1]), float(varr[2]))
