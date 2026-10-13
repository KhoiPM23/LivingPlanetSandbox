class_name WorldBootstrap
extends Node

## Central coordinator initializing and running a Living Planet Sandbox world.

@export var initial_seed: String = "LIVING_PLANET_PRIME"
@export var simulation_tick_rate: float = 10.0
@export var auto_start: bool = true

var world_seed: WorldSeed
var world_clock: WorldClock
var world_event_bus: WorldEventBus
var entity_registry: EntityRegistry
var simulation_scheduler: SimulationScheduler
var world_config: WorldGenerationConfig
var environmental_grid: EnvironmentalGrid
var weather_system: WeatherSystem
var ecosystem_coordinator: EcosystemCoordinator

var is_initialized: bool = false

func _enter_tree() -> void:
	if not is_initialized and auto_start:
		initialize_world(initial_seed)

func initialize_world(seed_value: Variant) -> void:
	world_seed = WorldSeed.new(seed_value)
	world_clock = WorldClock.new(simulation_tick_rate)
	world_event_bus = WorldEventBus.new()
	entity_registry = EntityRegistry.new(world_event_bus)
	simulation_scheduler = SimulationScheduler.new(world_clock)
	
	world_config = WorldGenerationConfig.new(world_seed.master_seed)
	weather_system = WeatherSystem.new(world_seed.get_stream("weather"), world_event_bus)
	environmental_grid = EnvironmentalGrid.new(world_config)
	ecosystem_coordinator = EcosystemCoordinator.new(
		world_seed,
		world_clock,
		world_event_bus,
		entity_registry,
		environmental_grid,
		weather_system,
		simulation_scheduler
	)
	
	# Register recurring environmental grid simulation task (every 5 ticks = 0.5s at 10Hz)
	simulation_scheduler.register_task("environment_tick", 5, Callable(self, "_on_environment_tick"))
	
	is_initialized = true
	world_event_bus.notification_logged.emit("SYSTEM", "World initialized with seed: " + str(world_seed.master_seed))

func _process(delta: float) -> void:
	if is_initialized and world_clock:
		world_clock.advance(delta)

func _on_environment_tick(_tick_num: int, _sim_time: float) -> void:
	if not world_clock or not environmental_grid or not weather_system:
		return
		
	var delta_sim: float = 0.5 * world_clock.time_scale
	weather_system.update(delta_sim)
	
	var day_phase: float = fmod((world_clock.simulation_time + 45.0) / 120.0, 1.0)
	environmental_grid.step_simulation(delta_sim, day_phase, weather_system)

func reset_world(new_seed: Variant = null) -> void:
	var seed_to_use: Variant = new_seed if new_seed != null else world_seed.master_seed
	if simulation_scheduler:
		simulation_scheduler.clear()
	if entity_registry:
		entity_registry.clear()
	if world_clock:
		world_clock.reset()
	if world_seed:
		world_seed.set_master_seed(seed_to_use)
	if simulation_scheduler and world_clock:
		simulation_scheduler.bind_clock(world_clock)
		simulation_scheduler.register_task("environment_tick", 5, Callable(self, "_on_environment_tick"))
		
	world_config = WorldGenerationConfig.new(world_seed.master_seed)
	weather_system = WeatherSystem.new(world_seed.get_stream("weather"), world_event_bus)
	environmental_grid = EnvironmentalGrid.new(world_config)
	ecosystem_coordinator = EcosystemCoordinator.new(
		world_seed,
		world_clock,
		world_event_bus,
		entity_registry,
		environmental_grid,
		weather_system,
		simulation_scheduler
	)
	
	if world_event_bus:
		world_event_bus.notification_logged.emit("SYSTEM", "World reset with seed: " + str(world_seed.master_seed))

func save_world_state(path: String = WorldPersistence.DEFAULT_SAVE_PATH) -> Error:
	var err: Error = WorldPersistence.save_complete_world(
		path,
		world_seed,
		world_clock,
		entity_registry,
		environmental_grid,
		weather_system,
		ecosystem_coordinator
	)
	if world_event_bus:
		if err == OK:
			world_event_bus.notification_logged.emit("SYSTEM", "World state saved to: " + path)
			world_event_bus.publish("save_completed", {"path": path})
		else:
			world_event_bus.notification_logged.emit("ERROR", "Failed to save world: %d" % err)
			world_event_bus.publish("save_failed", {"path": path, "error": err})
	return err

func load_world_state(path: String = WorldPersistence.DEFAULT_SAVE_PATH) -> Error:
	var result: Dictionary = WorldPersistence.load_world(path)
	var err: Error = result.get("error", ERR_CANT_OPEN)
	if err != OK:
		if world_event_bus:
			world_event_bus.notification_logged.emit("ERROR", "Failed to load world (%s): %s" % [path, result.get("message", "")])
			world_event_bus.publish("load_failed", {"path": path, "error": err, "message": result.get("message", "")})
		return err
		
	var data: Dictionary = result.get("data", {})
	
	# 1. Restore seed & config
	if data.has("seed") and data["seed"].has("master_seed"):
		world_seed.set_master_seed(data["seed"]["master_seed"])
		world_config = WorldGenerationConfig.new(world_seed.master_seed)
		
	# 2. Restore clock
	if data.has("clock"):
		world_clock.simulation_time = data["clock"].get("simulation_time", 0.0)
		world_clock.tick_count = data["clock"].get("tick_count", 0)
		world_clock.set_time_scale(data["clock"].get("time_scale", 1.0))
		world_clock.set_paused(data["clock"].get("is_paused", false))
		
	# 3. Restore weather
	if data.has("weather") and weather_system:
		var st: int = data["weather"].get("current_state", 0)
		var dur: float = data["weather"].get("duration_remaining", 60.0)
		weather_system.set_state(st as WeatherSystem.WeatherState, dur)
		
	# 4. Restore environment grid
	if data.has("environment") and environmental_grid:
		var env_data: Dictionary = data["environment"]
		if env_data.has("cell_moistures"):
			environmental_grid.restore_cell_data(
				env_data.get("cell_moistures", []),
				env_data.get("cell_temperatures", [])
			)
			
	# 5. Restore ecosystem simulation (Schema v2)
	entity_registry.clear()
	
	if data.has("ecosystem") and ecosystem_coordinator:
		var eco_data: Dictionary = data["ecosystem"]
		if ecosystem_coordinator.flora_sim:
			ecosystem_coordinator.flora_sim.clear()
			for plant_data: Dictionary in eco_data.get("plants", []):
				ecosystem_coordinator.flora_sim.restore_plant(plant_data)
				
		if ecosystem_coordinator.fauna_sim:
			ecosystem_coordinator.fauna_sim.clear()
			for h_data: Dictionary in eco_data.get("herbivores", []):
				ecosystem_coordinator.fauna_sim.restore_herbivore(h_data)
			for p_data: Dictionary in eco_data.get("predators", []):
				ecosystem_coordinator.fauna_sim.restore_predator(p_data)
				
		if data.has("metrics") and ecosystem_coordinator.metrics:
			var m_data: Dictionary = data["metrics"]
			ecosystem_coordinator.metrics.births_total = m_data.get("births_total", 0)
			ecosystem_coordinator.metrics.births_by_type = m_data.get("births_by_type", {}).duplicate()
			ecosystem_coordinator.metrics.deaths_total = m_data.get("deaths_total", 0)
			ecosystem_coordinator.metrics.deaths_by_cause = m_data.get("deaths_by_cause", {}).duplicate()
	elif data.has("entities"):
		# Schema v1 fallback
		for ent: Dictionary in data["entities"]:
			var ent_type: String = ent.get("type", "unknown")
			var pos: Vector3 = ent.get("position", Vector3.ZERO)
			var props: Dictionary = ent.get("properties", {})
			props["health"] = ent.get("health", 100.0)
			props["energy"] = ent.get("energy", 100.0)
			props["age"] = ent.get("age", 0.0)
			entity_registry.spawn_entity(ent_type, pos, props, ent.get("id", -1))

	if world_event_bus:
		world_event_bus.notification_logged.emit("SYSTEM", "World state successfully loaded from: " + path)
		world_event_bus.publish("load_completed", {"path": path})
		
	return OK

