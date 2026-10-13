class_name EcosystemCoordinator
extends RefCounted

## Central coordinator orchestrating flora and fauna simulations, spatial partitioning,
## metrics collection, and player environmental interventions.

const FloraSimulation = preload("res://core/ecosystem/flora_simulation.gd")
const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")
const CausalTracker = preload("res://core/ecosystem/causal_tracker.gd")

var flora_sim: FloraSimulation
var fauna_sim: FaunaSimulation
var metrics: EcosystemMetrics
var causal_tracker: CausalTracker

var _rng: RandomNumberGenerator
var _world_seed: WorldSeed
var _world_clock: WorldClock
var _event_bus: WorldEventBus
var _entity_registry: EntityRegistry
var _env_grid: EnvironmentalGrid
var _weather_system: WeatherSystem
var _scheduler: SimulationScheduler

var _terrain_height_func: Callable = Callable()
var is_active: bool = true

func _init(
	world_seed: WorldSeed,
	world_clock: WorldClock,
	event_bus: WorldEventBus,
	entity_registry: EntityRegistry,
	env_grid: EnvironmentalGrid,
	weather_system: WeatherSystem,
	scheduler: SimulationScheduler = null
) -> void:
	_world_seed = world_seed
	_world_clock = world_clock
	_event_bus = event_bus
	_entity_registry = entity_registry
	_env_grid = env_grid
	_weather_system = weather_system
	_scheduler = scheduler

	_rng = world_seed.get_stream("ecology") if world_seed != null else RandomNumberGenerator.new()
	metrics = EcosystemMetrics.new()
	causal_tracker = CausalTracker.new(world_clock)
	flora_sim = FloraSimulation.new(_rng, entity_registry, metrics, event_bus)
	fauna_sim = FaunaSimulation.new(_rng, entity_registry, metrics, event_bus)

	if _event_bus:
		_event_bus.subscribe("plant_died", Callable(self, "_on_plant_died_causal"))
		_event_bus.subscribe("fauna_died", Callable(self, "_on_fauna_died_causal"))

	if _scheduler:
		# Run ecosystem simulation at 2Hz (every 5 ticks at 10Hz clock)
		_scheduler.register_task("ecosystem_tick", 5, Callable(self, "_on_ecosystem_tick"))

func bind_terrain_height(callable: Callable) -> void:
	_terrain_height_func = callable

func populate_initial_ecosystem(plant_count: int = 60, herbivore_count: int = 14, predator_count: int = 2) -> void:
	# Clear existing
	flora_sim.clear()
	fauna_sim.clear()
	metrics.reset()

	# 1. Spawn initial flora across habitable island cells
	for i: int in range(plant_count):
		var angle: float = _rng.randf() * TAU
		var dist: float = _rng.randf_range(6.0, 58.0)
		var x: float = cos(angle) * dist
		var z: float = sin(angle) * dist
		var y: float = 0.5
		if _terrain_height_func.is_valid():
			y = _terrain_height_func.call(x, z)

		# Check above water level
		if y > 0.4:
			var species: String = "shrub_bush" if (_rng.randf() < 0.35) else "grass_patch"
			var initial_bio: float = _rng.randf_range(2.0, 6.0)
			flora_sim.spawn_plant(species, Vector3(x, y, z), initial_bio)

	# 2. Spawn initial herbivores in meadow/forest zones
	for i: int in range(herbivore_count):
		var angle: float = _rng.randf() * TAU
		var dist: float = _rng.randf_range(8.0, 45.0)
		var x: float = cos(angle) * dist
		var z: float = sin(angle) * dist
		var y: float = 1.0
		if _terrain_height_func.is_valid():
			y = _terrain_height_func.call(x, z)
		if y > 0.4:
			var initial_energy: float = _rng.randf_range(70.0, 95.0)
			fauna_sim.spawn_herbivore(Vector3(x, y, z), initial_energy)

	# 3. Spawn initial predators near higher elevation
	for i: int in range(predator_count):
		var angle: float = _rng.randf() * TAU
		var dist: float = _rng.randf_range(20.0, 48.0)
		var x: float = cos(angle) * dist
		var z: float = sin(angle) * dist
		var y: float = 2.0
		if _terrain_height_func.is_valid():
			y = _terrain_height_func.call(x, z)
		if y > 0.4:
			fauna_sim.spawn_predator(Vector3(x, y, z), 85.0)

	if _event_bus:
		_event_bus.publish("ecosystem_populated", {
			"plants": flora_sim.get_plant_count(),
			"herbivores": fauna_sim.get_herbivore_count(),
			"predators": fauna_sim.get_predator_count()
		})

func _on_ecosystem_tick(_tick_num: int, _sim_time: float) -> void:
	if not is_active:
		return
	var time_scale: float = _world_clock.time_scale if _world_clock != null else 1.0
	var delta_sim: float = 0.5 * time_scale
	step_simulation(delta_sim)

func step_simulation(delta_sim: float) -> void:
	var start_usec: int = Time.get_ticks_usec()

	# Step plant growth and environmental decay
	if flora_sim and _env_grid:
		flora_sim.step_simulation(delta_sim, _env_grid)

	# Step fauna foraging, metabolism, movement, and predation
	if fauna_sim:
		fauna_sim.step_simulation(delta_sim, flora_sim, _terrain_height_func, _weather_system)

	# Compute live genetic telemetry
	var total_herb_speed: float = 0.0
	var total_herb_size: float = 0.0
	var max_gen: int = 1
	var herbs: Array = fauna_sim.get_all_herbivores() if fauna_sim else []
	for h in herbs:
		if h.genome:
			total_herb_speed += h.genome.speed_mult
			total_herb_size += h.genome.size_scale
			max_gen = maxi(max_gen, h.genome.generation)
	if herbs.size() > 0:
		metrics.avg_herbivore_speed = total_herb_speed / float(herbs.size())
		metrics.avg_herbivore_size = total_herb_size / float(herbs.size())

	var total_drought_tol: float = 0.0
	var plants: Array = flora_sim.get_all_plants() if flora_sim else []
	for p in plants:
		if p.genome:
			total_drought_tol += p.genome.drought_tolerance
			max_gen = maxi(max_gen, p.genome.generation)
	if plants.size() > 0:
		metrics.avg_plant_drought_tolerance = total_drought_tol / float(plants.size())
	metrics.max_generation = max_gen

	# Compute Allele Variances and Diversity
	var speed_sq_sum: float = 0.0
	for h in herbs:
		if h.genome:
			var diff: float = h.genome.speed_mult - metrics.avg_herbivore_speed
			speed_sq_sum += diff * diff
	var spd_var: float = (speed_sq_sum / float(herbs.size())) if herbs.size() > 1 else 0.0
	metrics.allele_speed_variance = spd_var

	var drought_sq_sum: float = 0.0
	for p in plants:
		if p.genome:
			var diff_p: float = p.genome.drought_tolerance - metrics.avg_plant_drought_tolerance
			drought_sq_sum += diff_p * diff_p
	var drg_var: float = (drought_sq_sum / float(plants.size())) if plants.size() > 1 else 0.0
	metrics.allele_drought_variance = drg_var

	# Diversity Index: combination of standard deviations
	var spd_std: float = sqrt(spd_var)
	var drg_std: float = sqrt(drg_var)
	metrics.genetic_diversity_index = clampf((spd_std * 3.0 + drg_std * 4.0), 0.0, 2.0)
	metrics.bottleneck_warning = (metrics.genetic_diversity_index < 0.04 and herbs.size() > 5)

	var duration_ms: float = float(Time.get_ticks_usec() - start_usec) / 1000.0
	metrics.last_sim_step_duration_ms = duration_ms
	metrics.sample_history()

	if _world_clock and int(_world_clock.tick_count) % 10 == 0:
		metrics.sample_evolution_snapshot(_world_clock.simulation_time)

	if _event_bus:
		_event_bus.publish("ecosystem_metrics_updated", metrics.to_dict())


## Player Interventions
func apply_drought(moisture_target: float = 0.05) -> void:
	if _weather_system:
		_weather_system.set_state(WeatherSystem.WeatherState.DROUGHT, 60.0)
	if _env_grid:
		# Directly penalize moisture across all grid cells
		for i: int in range(_env_grid.get_cell_count()):
			var cell: Dictionary = _env_grid.get_cell(i)
			if not cell.is_empty():
				cell["moisture"] = minf(cell.get("moisture", 0.5), moisture_target)

	if _event_bus:
		_event_bus.publish("player_intervention", {"action": "drought", "moisture_target": moisture_target})

func apply_rain() -> void:
	if _weather_system:
		_weather_system.set_state(WeatherSystem.WeatherState.RAIN, 45.0)
	if _event_bus:
		_event_bus.publish("player_intervention", {"action": "rain"})

func spawn_herbivore_at_center() -> int:
	var pos: Vector3 = Vector3(_rng.randf_range(-5.0, 5.0), 0.0, _rng.randf_range(-5.0, 5.0))
	if _terrain_height_func.is_valid():
		pos.y = _terrain_height_func.call(pos.x, pos.z)
	return fauna_sim.spawn_herbivore(pos, 85.0)

func spawn_predator_at_center() -> int:
	var pos: Vector3 = Vector3(_rng.randf_range(-15.0, 15.0), 0.0, _rng.randf_range(-15.0, 15.0))
	if _terrain_height_func.is_valid():
		pos.y = _terrain_height_func.call(pos.x, pos.z)
	return fauna_sim.spawn_predator(pos, 85.0)

func clear() -> void:
	if flora_sim:
		flora_sim.clear()
	if fauna_sim:
		fauna_sim.clear()
	if metrics:
		metrics.reset()
	if causal_tracker:
		causal_tracker.clear()

func _on_plant_died_causal(payload: Variant) -> void:
	if not causal_tracker or not (payload is Dictionary):
		return
	var dict: Dictionary = payload as Dictionary
	var pid: int = dict.get("id", 0)
	var reason: String = dict.get("reason", "decay")
	var pos: Vector3 = dict.get("position", Vector3.ZERO)
	var sim_t: float = _world_clock.simulation_time if _world_clock else 0.0
	var event: Dictionary = causal_tracker.process_plant_death(pid, pos, reason, sim_t)
	if not event.is_empty() and _event_bus:
		_event_bus.publish("causal_cascade_observed", event)

func _on_fauna_died_causal(payload: Variant) -> void:
	if not causal_tracker or not (payload is Dictionary):
		return
	var dict: Dictionary = payload as Dictionary
	var fid: int = dict.get("id", 0)
	var reason: String = dict.get("reason", "natural")
	var pos: Vector3 = dict.get("position", Vector3.ZERO)
	var sim_t: float = _world_clock.simulation_time if _world_clock else 0.0
	if reason == "starvation":
		var event: Dictionary = causal_tracker.process_fauna_starvation(fid, pos, sim_t)
		if not event.is_empty() and _event_bus:
			_event_bus.publish("causal_cascade_observed", event)
