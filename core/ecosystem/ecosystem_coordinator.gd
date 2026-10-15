class_name EcosystemCoordinator
extends RefCounted

## Central coordinator orchestrating flora and fauna simulations, spatial partitioning,
## metrics collection, and player environmental interventions.

const FloraSimulation = preload("res://core/ecosystem/flora_simulation.gd")
const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")
const CausalTracker = preload("res://core/ecosystem/causal_tracker.gd")
const ExperimentHistory = preload("res://core/ecosystem/experiment_history.gd")

var flora_sim: FloraSimulation
var fauna_sim: FaunaSimulation
var metrics: EcosystemMetrics
var causal_tracker: CausalTracker
var experiment_history: ExperimentHistory

var _rng: RandomNumberGenerator
var _world_seed: WorldSeed
var _world_clock: WorldClock
var _event_bus: WorldEventBus
var _entity_registry: EntityRegistry
var _env_grid: EnvironmentalGrid
var _weather_system: WeatherSystem
var _scheduler: SimulationScheduler

var _terrain_height_func: Callable = Callable()
var terrain_height_func: Callable:
	get:
		return _terrain_height_func
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
	experiment_history = ExperimentHistory.new(world_clock, world_seed.master_seed if world_seed else 1337)
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

func set_player_presence(player_pos: Vector3, is_active: bool) -> void:
	if fauna_sim:
		fauna_sim.set_player_presence(player_pos, is_active)

func populate_initial_ecosystem(plant_count: int = 60, herbivore_count: int = 14, predator_count: int = 2) -> void:
	# Clear existing
	flora_sim.clear()
	fauna_sim.clear()
	metrics.reset()

	# 1. Spawn initial flora clustered into ecological zones
	var meadow_plants: int = int(plant_count * 0.50)
	var basin_plants: int = int(plant_count * 0.25)
	var forest_plants: int = int(plant_count * 0.15)
	var scattered_plants: int = plant_count - (meadow_plants + basin_plants + forest_plants)

	# 1a. Sunlit Meadow Glade (rich flower drifts & pasture grasses)
	for i: int in range(meadow_plants):
		var x: float = _rng.randf_range(3.5, 15.5)
		var z: float = _rng.randf_range(0.0, 9.0)
		var y: float = _terrain_height_func.call(x, z) if _terrain_height_func.is_valid() else 1.5
		if y > 0.4:
			var species: String = "shrub_bush" if (_rng.randf() < 0.25) else "grass_patch"
			flora_sim.spawn_plant(species, Vector3(x, y, z), _rng.randf_range(3.0, 6.5))

	# 1b. Emerald Basin Cove & Creek Delta (riparian ferns & shoreline brush)
	for i: int in range(basin_plants):
		var x: float = _rng.randf_range(11.5, 21.0)
		var z: float = _rng.randf_range(8.5, 17.5)
		var y: float = _terrain_height_func.call(x, z) if _terrain_height_func.is_valid() else 0.8
		if y > 0.35:
			var species: String = "shrub_bush" if (_rng.randf() < 0.45) else "grass_patch"
			flora_sim.spawn_plant(species, Vector3(x, y, z), _rng.randf_range(2.5, 5.5))

	# 1c. Whispering Forest Margin (understory berry shrubs & shade moss)
	for i: int in range(forest_plants):
		var x: float = _rng.randf_range(-12.0, 0.0)
		var z: float = _rng.randf_range(-6.0, 3.5)
		var y: float = _terrain_height_func.call(x, z) if _terrain_height_func.is_valid() else 2.5
		if y > 0.4:
			flora_sim.spawn_plant("shrub_bush", Vector3(x, y, z), _rng.randf_range(3.5, 6.0))

	# 1d. Island-wide dispersed flora
	for i: int in range(scattered_plants):
		var angle: float = _rng.randf() * TAU
		var dist: float = _rng.randf_range(8.0, 56.0)
		var x: float = cos(angle) * dist
		var z: float = sin(angle) * dist
		var y: float = _terrain_height_func.call(x, z) if _terrain_height_func.is_valid() else 0.5
		if y > 0.4:
			var species: String = "shrub_bush" if (_rng.randf() < 0.35) else "grass_patch"
			flora_sim.spawn_plant(species, Vector3(x, y, z), _rng.randf_range(2.0, 5.0))

	# 2. Spawn initial herbivores clustered in primary foraging & watering niches
	var meadow_herbs: int = int(herbivore_count * 0.65)
	var basin_herbs: int = int(herbivore_count * 0.25)
	var forest_herbs: int = herbivore_count - (meadow_herbs + basin_herbs)

	# 2a. Sunlit Meadow Glade herd (grazing on wildflower meadows)
	for i: int in range(meadow_herbs):
		var x: float = _rng.randf_range(4.0, 15.0)
		var z: float = _rng.randf_range(0.5, 8.5)
		var y: float = _terrain_height_func.call(x, z) if _terrain_height_func.is_valid() else 1.5
		if y > 0.4:
			fauna_sim.spawn_herbivore(Vector3(x, y, z), _rng.randf_range(75.0, 95.0))

	# 2b. Emerald Basin Cove shoreline group (watering hole & creek delta)
	for i: int in range(basin_herbs):
		var x: float = _rng.randf_range(12.0, 20.0)
		var z: float = _rng.randf_range(9.0, 17.0)
		var y: float = _terrain_height_func.call(x, z) if _terrain_height_func.is_valid() else 0.6
		if y > 0.4:
			fauna_sim.spawn_herbivore(Vector3(x, y, z), _rng.randf_range(70.0, 90.0))

	# 2c. Whispering Forest ecotone (sheltered browsing)
	for i: int in range(forest_herbs):
		var x: float = _rng.randf_range(-10.0, -1.0)
		var z: float = _rng.randf_range(-5.0, 2.5)
		var y: float = _terrain_height_func.call(x, z) if _terrain_height_func.is_valid() else 2.5
		if y > 0.4:
			fauna_sim.spawn_herbivore(Vector3(x, y, z), _rng.randf_range(75.0, 92.0))

	# 3. Spawn initial predators in natural predatory vantages & forest perimeter
	# Predator 1: High North Ridge overlooking the valley and basin
	var p1_x: float = _rng.randf_range(-18.0, -10.0)
	var p1_z: float = _rng.randf_range(-18.0, -8.0)
	var p1_y: float = _terrain_height_func.call(p1_x, p1_z) if _terrain_height_func.is_valid() else 3.5
	fauna_sim.spawn_predator(Vector3(p1_x, maxf(0.5, p1_y), p1_z), 85.0)

	# Predator 2+: Forest perimeter stalkers
	for i: int in range(1, predator_count):
		var px: float = _rng.randf_range(-15.0, -7.0)
		var pz: float = _rng.randf_range(-4.0, 4.0)
		var py: float = _terrain_height_func.call(px, pz) if _terrain_height_func.is_valid() else 2.5
		fauna_sim.spawn_predator(Vector3(px, maxf(0.5, py), pz), 85.0)

	if _event_bus:
		_event_bus.publish("ecosystem_populated", {
			"plants": flora_sim.get_plant_count(),
			"herbivores": fauna_sim.get_herbivore_count(),
			"predators": fauna_sim.get_predator_count()
		})

	if experiment_history:
		experiment_history.init_baseline(
			_world_seed.master_seed if _world_seed else 1337,
			{
				"plant_count": flora_sim.get_plant_count(),
				"total_biomass": metrics.total_biomass,
				"herbivore_count": fauna_sim.get_herbivore_count(),
				"predator_count": fauna_sim.get_predator_count(),
				"avg_speed": metrics.avg_herbivore_speed,
				"avg_size": metrics.avg_herbivore_size,
				"avg_efficiency": metrics.avg_herbivore_energy_efficiency,
				"speed_variance": metrics.allele_speed_variance,
				"diversity_index": metrics.genetic_diversity_index
			},
			_world_clock.simulation_time if _world_clock else 0.0
		)

func _on_ecosystem_tick(_tick_num: int, _sim_time: float) -> void:
	if not is_active:
		return
	var time_scale: float = _world_clock.time_scale if _world_clock != null else 1.0
	var delta_sim: float = 0.5 * time_scale
	step_simulation(delta_sim)

func step_simulation(delta_sim: float) -> void:
	var start_usec: int = Time.get_ticks_usec()

	# Compute diurnal solar hour for coupled ecological behaviors (120s full day, 09:00 morning offset)
	var sim_hour: float = 12.0
	if _world_clock:
		var sim_time: float = _world_clock.simulation_time + 45.0
		var day_phase: float = fmod(sim_time / 120.0, 1.0)
		sim_hour = day_phase * 24.0

	# Step plant growth and environmental decay
	if flora_sim and _env_grid:
		flora_sim.step_simulation(delta_sim, _env_grid)

	# Step fauna foraging, metabolism, movement, and predation with diurnal hour
	if fauna_sim:
		fauna_sim.step_simulation(delta_sim, flora_sim, _terrain_height_func, _weather_system, sim_hour)

	# Compute live genetic telemetry
	var total_herb_speed: float = 0.0
	var total_herb_size: float = 0.0
	var total_herb_sense: float = 0.0
	var total_herb_eff: float = 0.0
	var total_herb_forage: float = 0.0
	var max_gen: int = 1
	var herbs: Array = fauna_sim.get_all_herbivores() if fauna_sim else []
	for h in herbs:
		if h.genome:
			total_herb_speed += h.genome.speed
			total_herb_size += h.genome.size
			total_herb_sense += h.genome.sense_range
			total_herb_eff += h.genome.energy_efficiency
			total_herb_forage += h.genome.foraging
			max_gen = maxi(max_gen, h.genome.generation)
	if herbs.size() > 0:
		var h_len: float = float(herbs.size())
		metrics.avg_herbivore_speed = total_herb_speed / h_len
		metrics.avg_herbivore_size = total_herb_size / h_len
		metrics.avg_herbivore_sense_range = total_herb_sense / h_len
		metrics.avg_herbivore_energy_efficiency = total_herb_eff / h_len
		metrics.avg_herbivore_foraging = total_herb_forage / h_len
	else:
		metrics.avg_herbivore_speed = 0.0
		metrics.avg_herbivore_size = 0.0
		metrics.avg_herbivore_sense_range = 0.0
		metrics.avg_herbivore_energy_efficiency = 0.0
		metrics.avg_herbivore_foraging = 0.0

	var total_pred_speed: float = 0.0
	var total_pred_size: float = 0.0
	var total_pred_sense: float = 0.0
	var total_pred_eff: float = 0.0
	var total_pred_predation: float = 0.0
	var preds: Array = fauna_sim.get_all_predators() if fauna_sim else []
	for p in preds:
		if p.genome:
			total_pred_speed += p.genome.speed
			total_pred_size += p.genome.size
			total_pred_sense += p.genome.sense_range
			total_pred_eff += p.genome.energy_efficiency
			total_pred_predation += p.genome.predation
			max_gen = maxi(max_gen, p.genome.generation)
	if preds.size() > 0:
		var p_len: float = float(preds.size())
		metrics.avg_predator_speed = total_pred_speed / p_len
		metrics.avg_predator_size = total_pred_size / p_len
		metrics.avg_predator_sense_range = total_pred_sense / p_len
		metrics.avg_predator_energy_efficiency = total_pred_eff / p_len
		metrics.avg_predator_predation = total_pred_predation / p_len
	else:
		metrics.avg_predator_speed = 0.0
		metrics.avg_predator_size = 0.0
		metrics.avg_predator_sense_range = 0.0
		metrics.avg_predator_energy_efficiency = 0.0
		metrics.avg_predator_predation = 0.0

	var total_drought_tol: float = 0.0
	var plants: Array = flora_sim.get_all_plants() if flora_sim else []
	for p in plants:
		if p.genome:
			total_drought_tol += p.genome.drought_tolerance
			max_gen = maxi(max_gen, p.genome.generation)
	if plants.size() > 0:
		metrics.avg_plant_drought_tolerance = total_drought_tol / float(plants.size())
	else:
		metrics.avg_plant_drought_tolerance = 0.0
	metrics.max_generation = max_gen

	# Compute Allele Variances and Diversity
	var speed_sq_sum: float = 0.0
	var size_sq_sum: float = 0.0
	var sense_sq_sum: float = 0.0
	var eff_sq_sum: float = 0.0
	var forage_sq_sum: float = 0.0
	for h in herbs:
		if h.genome:
			var diff_spd: float = h.genome.speed - metrics.avg_herbivore_speed
			speed_sq_sum += diff_spd * diff_spd
			var diff_sz: float = h.genome.size - metrics.avg_herbivore_size
			size_sq_sum += diff_sz * diff_sz
			var diff_sn: float = h.genome.sense_range - metrics.avg_herbivore_sense_range
			sense_sq_sum += diff_sn * diff_sn
			var diff_ef: float = h.genome.energy_efficiency - metrics.avg_herbivore_energy_efficiency
			eff_sq_sum += diff_ef * diff_ef
			var diff_fg: float = h.genome.foraging - metrics.avg_herbivore_foraging
			forage_sq_sum += diff_fg * diff_fg
	var h_div: float = float(herbs.size()) if herbs.size() > 1 else 1.0
	metrics.allele_speed_variance = speed_sq_sum / h_div if herbs.size() > 1 else 0.0
	metrics.allele_size_variance = size_sq_sum / h_div if herbs.size() > 1 else 0.0
	metrics.allele_sense_variance = sense_sq_sum / h_div if herbs.size() > 1 else 0.0
	metrics.allele_efficiency_variance = eff_sq_sum / h_div if herbs.size() > 1 else 0.0
	metrics.allele_foraging_variance = forage_sq_sum / h_div if herbs.size() > 1 else 0.0

	var pred_sq_sum: float = 0.0
	for p in preds:
		if p.genome:
			var diff_pr: float = p.genome.predation - metrics.avg_predator_predation
			pred_sq_sum += diff_pr * diff_pr
	metrics.allele_predation_variance = (pred_sq_sum / float(preds.size())) if preds.size() > 1 else 0.0

	var drought_sq_sum: float = 0.0
	for p in plants:
		if p.genome:
			var diff_p: float = p.genome.drought_tolerance - metrics.avg_plant_drought_tolerance
			drought_sq_sum += diff_p * diff_p
	var drg_var: float = (drought_sq_sum / float(plants.size())) if plants.size() > 1 else 0.0
	metrics.allele_drought_variance = drg_var

	# Demographic survival & birth rate calculation
	var deaths_herb: int = int(metrics.deaths_by_cause.get("herbivore_starvation", 0)) + int(metrics.deaths_by_cause.get("herbivore_predation", 0)) + int(metrics.deaths_by_cause.get("herbivore_old_age", 0))
	var cohort_herb: int = herbs.size() + deaths_herb
	metrics.survival_rate_herbivore = (float(herbs.size()) / float(cohort_herb)) if cohort_herb > 0 else 1.0
	metrics.birth_rate_herbivore = float(metrics.births_by_type.get("herbivore", 0)) / maxf(1.0, float(cohort_herb))

	var deaths_pred: int = int(metrics.deaths_by_cause.get("predator_starvation", 0)) + int(metrics.deaths_by_cause.get("predator_old_age", 0))
	var cohort_pred: int = preds.size() + deaths_pred
	metrics.survival_rate_predator = (float(preds.size()) / float(cohort_pred)) if cohort_pred > 0 else 1.0
	metrics.birth_rate_predator = float(metrics.births_by_type.get("predator", 0)) / maxf(1.0, float(cohort_pred))

	# Diversity Index: combination of standard deviations
	var spd_std: float = sqrt(metrics.allele_speed_variance)
	var drg_std: float = sqrt(drg_var)
	metrics.genetic_diversity_index = clampf((spd_std * 3.0 + drg_std * 4.0), 0.0, 2.0)
	metrics.bottleneck_warning = (metrics.genetic_diversity_index < 0.04 and herbs.size() > 5)

	var duration_ms: float = float(Time.get_ticks_usec() - start_usec) / 1000.0
	metrics.last_sim_step_duration_ms = duration_ms
	metrics.sample_history()

	if _world_clock and int(_world_clock.tick_count) % 10 == 0:
		metrics.sample_evolution_snapshot(_world_clock.simulation_time)

	if experiment_history and _world_clock:
		experiment_history.step(_world_clock.simulation_time, {
			"plant_count": flora_sim.get_plant_count() if flora_sim else 0,
			"total_biomass": metrics.total_biomass,
			"herbivore_count": fauna_sim.get_herbivore_count() if fauna_sim else 0,
			"predator_count": fauna_sim.get_predator_count() if fauna_sim else 0,
			"avg_speed": metrics.avg_herbivore_speed,
			"avg_size": metrics.avg_herbivore_size,
			"avg_efficiency": metrics.avg_herbivore_energy_efficiency,
			"speed_variance": metrics.allele_speed_variance,
			"diversity_index": metrics.genetic_diversity_index
		})

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
	if experiment_history:
		experiment_history.clear()

## Mutates living entities within an area using controlled biological bounds.
func mutate_population_in_area(center: Vector3, radius: float) -> int:
	var affected_count: int = 0
	var rad_sq: float = radius * radius

	if fauna_sim:
		for h in fauna_sim.get_all_herbivores():
			if center.distance_squared_to(h.position) <= rad_sq and h.genome:
				h.genome.mutate_in_place(_rng, 0.65, 0.08)
				affected_count += 1
		for p in fauna_sim.get_all_predators():
			if center.distance_squared_to(p.position) <= rad_sq and p.genome:
				p.genome.mutate_in_place(_rng, 0.65, 0.08)
				affected_count += 1

	if flora_sim:
		for pl in flora_sim.get_all_plants():
			if center.distance_squared_to(pl.position) <= rad_sq and pl.genome:
				pl.genome.mutate_in_place(_rng, 0.60, 0.08)
				affected_count += 1

	# Trigger immediate recalculation of genetic telemetry
	step_simulation(0.0)

	if _event_bus:
		_event_bus.publish("population_mutated", {
			"pos": center,
			"radius": radius,
			"affected_count": affected_count
		})

	return affected_count

## Triggers a finite climate pulse through environmental grid
func apply_climate_pulse(center: Vector3, radius: float, pulse_type: String = "deluge", duration: float = 25.0) -> Dictionary:
	var pulse_info: Dictionary = {}
	if _env_grid:
		pulse_info = _env_grid.trigger_climate_pulse(center.x, center.z, radius, pulse_type, duration)

	if _event_bus:
		_event_bus.publish("climate_pulse_triggered", {
			"pos": center,
			"radius": radius,
			"type": pulse_type,
			"duration": duration,
			"cells_affected": pulse_info.get("cells_affected", 0)
		})

	return pulse_info

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
