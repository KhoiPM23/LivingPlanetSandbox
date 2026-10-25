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

func set_player_presence(player_pos: Vector3, is_active: bool, player_speed: float = -1.0) -> void:
	if fauna_sim:
		fauna_sim.set_player_presence(player_pos, is_active, player_speed)

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

	# 2. Spawn initial herbivores across ecological niches across the island
	var spawned_herb_positions: Array[Vector3] = []
	var herb_regions: Array[Dictionary] = [
		{"name": "meadow_glade", "min_x": 3.0, "max_x": 16.0, "min_z": 0.0, "max_z": 9.0, "weight": 0.22},
		{"name": "basin_cove", "min_x": 12.0, "max_x": 20.5, "min_z": 8.5, "max_z": 17.5, "weight": 0.16},
		{"name": "whispering_forest", "min_x": -75.0, "max_x": -15.0, "min_z": -35.0, "max_z": 45.0, "weight": 0.22},
		{"name": "grand_lake_shores", "min_x": 70.0, "max_x": 125.0, "min_z": 60.0, "max_z": 115.0, "weight": 0.20},
		{"name": "highland_plateau", "min_x": 95.0, "max_x": 185.0, "min_z": -95.0, "max_z": -15.0, "weight": 0.20}
	]

	for i: int in range(herbivore_count):
		var reg: Dictionary
		if i < 10:
			reg = herb_regions[1] if (i >= 4) else herb_regions[0]
		else:
			reg = herb_regions[i % herb_regions.size()]
		var pos: Vector3 = Vector3.ZERO
		var found: bool = false
		for attempt: int in range(36):
			var rx: float = _rng.randf_range(reg["min_x"], reg["max_x"])
			var rz: float = _rng.randf_range(reg["min_z"], reg["max_z"])
			var ry: float = _terrain_height_func.call(rx, rz) if _terrain_height_func.is_valid() else 1.5
			if ry <= 0.4:
				continue
			var candidate: Vector3 = Vector3(rx, ry, rz)
			if Vector2(candidate.x - 7.5, candidate.z - 3.5).length() < 6.2:
				continue
			var too_close: bool = false
			for prev_p: Vector3 in spawned_herb_positions:
				if candidate.distance_to(prev_p) < 2.5:
					too_close = true
					break
			if not too_close:
				pos = candidate
				found = true
				break
		if not found:
			var fx: float = 12.0 + float(i % 7) * 1.3
			var fz: float = 9.0 + float((i * 2) % 7) * 1.3
			var fy: float = _terrain_height_func.call(fx, fz) if _terrain_height_func.is_valid() else 1.5
			var fallback_pos: Vector3 = Vector3(fx, maxf(0.5, fy), fz)
			for offset_attempt: int in range(16):
				var cl: bool = false
				for prev_p: Vector3 in spawned_herb_positions:
					if fallback_pos.distance_to(prev_p) < 2.55:
						cl = true
						break
				if not cl and Vector2(fallback_pos.x - 7.5, fallback_pos.z - 3.5).length() >= 6.2:
					break
				fallback_pos.x += 1.2
				fallback_pos.z += 1.1
			pos = fallback_pos
		spawned_herb_positions.append(pos)
		fauna_sim.spawn_herbivore(pos, _rng.randf_range(75.0, 95.0))

	# 3. Spawn initial predators distributed across regional hunting territories
	var pred_regions: Array[Vector3] = [
		Vector3(-14.0, 3.5, -12.0), # High North Ridge
		Vector3(-45.0, 4.2, 18.0),  # Whispering Deep Forest
		Vector3(135.0, 8.5, -45.0), # Highland Plateau Ridge
		Vector3(110.0, 2.5, 95.0),  # Grand Lake Woods Margin
		Vector3(-25.0, 4.0, 140.0), # Cape Solitude Bluffs
		Vector3(-65.0, 12.0, -55.0),# Grotto Foothills
		Vector3(55.0, 2.2, 35.0),   # South Meadow Valley
		Vector3(-95.0, 6.0, 25.0)   # Western Forest Slopes
	]

	for i: int in range(predator_count):
		var p_base: Vector3 = pred_regions[i % pred_regions.size()]
		var px: float = p_base.x + _rng.randf_range(-6.0, 6.0)
		var pz: float = p_base.z + _rng.randf_range(-6.0, 6.0)
		var py: float = _terrain_height_func.call(px, pz) if _terrain_height_func.is_valid() else p_base.y
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

	# Compute diurnal solar hour from authoritative WorldClock
	var sim_hour: float = 12.0
	if _world_clock:
		sim_hour = _world_clock.get_sim_hour()
		if flora_sim and _world_clock.has_method("get_season"):
			flora_sim.set_active_season(_world_clock.get_season() as int)

	# Step plant growth and environmental decay
	if flora_sim and _env_grid:
		flora_sim.step_simulation(delta_sim, _env_grid)

	# Step fauna foraging, metabolism, movement, and predation with diurnal hour
	if fauna_sim:
		fauna_sim.step_simulation(delta_sim, flora_sim, _terrain_height_func, _weather_system, sim_hour)

	# Compute live genetic telemetry (single-pass running variance optimization)
	var total_herb_speed: float = 0.0
	var total_herb_size: float = 0.0
	var total_herb_sense: float = 0.0
	var total_herb_eff: float = 0.0
	var total_herb_forage: float = 0.0
	var sq_herb_speed: float = 0.0
	var sq_herb_size: float = 0.0
	var sq_herb_sense: float = 0.0
	var sq_herb_eff: float = 0.0
	var sq_herb_forage: float = 0.0
	var max_gen: int = 1
	var herbs: Array = fauna_sim.get_all_herbivores() if fauna_sim else []
	for h in herbs:
		if h.genome:
			var spd: float = h.genome.speed
			total_herb_speed += spd
			sq_herb_speed += spd * spd

			var sz: float = h.genome.size
			total_herb_size += sz
			sq_herb_size += sz * sz

			var sn: float = h.genome.sense_range
			total_herb_sense += sn
			sq_herb_sense += sn * sn

			var ef: float = h.genome.energy_efficiency
			total_herb_eff += ef
			sq_herb_eff += ef * ef

			var fg: float = h.genome.foraging
			total_herb_forage += fg
			sq_herb_forage += fg * fg

			max_gen = maxi(max_gen, h.genome.generation)

	if herbs.size() > 0:
		var h_len: float = float(herbs.size())
		metrics.avg_herbivore_speed = total_herb_speed / h_len
		metrics.avg_herbivore_size = total_herb_size / h_len
		metrics.avg_herbivore_sense_range = total_herb_sense / h_len
		metrics.avg_herbivore_energy_efficiency = total_herb_eff / h_len
		metrics.avg_herbivore_foraging = total_herb_forage / h_len

		if herbs.size() > 1:
			metrics.allele_speed_variance = maxf(0.0, (sq_herb_speed / h_len) - (metrics.avg_herbivore_speed * metrics.avg_herbivore_speed))
			metrics.allele_size_variance = maxf(0.0, (sq_herb_size / h_len) - (metrics.avg_herbivore_size * metrics.avg_herbivore_size))
			metrics.allele_sense_variance = maxf(0.0, (sq_herb_sense / h_len) - (metrics.avg_herbivore_sense_range * metrics.avg_herbivore_sense_range))
			metrics.allele_efficiency_variance = maxf(0.0, (sq_herb_eff / h_len) - (metrics.avg_herbivore_energy_efficiency * metrics.avg_herbivore_energy_efficiency))
			metrics.allele_foraging_variance = maxf(0.0, (sq_herb_forage / h_len) - (metrics.avg_herbivore_foraging * metrics.avg_herbivore_foraging))
		else:
			metrics.allele_speed_variance = 0.0
			metrics.allele_size_variance = 0.0
			metrics.allele_sense_variance = 0.0
			metrics.allele_efficiency_variance = 0.0
			metrics.allele_foraging_variance = 0.0
	else:
		metrics.avg_herbivore_speed = 0.0
		metrics.avg_herbivore_size = 0.0
		metrics.avg_herbivore_sense_range = 0.0
		metrics.avg_herbivore_energy_efficiency = 0.0
		metrics.avg_herbivore_foraging = 0.0
		metrics.allele_speed_variance = 0.0
		metrics.allele_size_variance = 0.0
		metrics.allele_sense_variance = 0.0
		metrics.allele_efficiency_variance = 0.0
		metrics.allele_foraging_variance = 0.0

	var total_pred_speed: float = 0.0
	var total_pred_size: float = 0.0
	var total_pred_sense: float = 0.0
	var total_pred_eff: float = 0.0
	var total_pred_predation: float = 0.0
	var sq_pred_predation: float = 0.0
	var preds: Array = fauna_sim.get_all_predators() if fauna_sim else []
	for p in preds:
		if p.genome:
			total_pred_speed += p.genome.speed
			total_pred_size += p.genome.size
			total_pred_sense += p.genome.sense_range
			total_pred_eff += p.genome.energy_efficiency
			var pr: float = p.genome.predation
			total_pred_predation += pr
			sq_pred_predation += pr * pr
			max_gen = maxi(max_gen, p.genome.generation)

	if preds.size() > 0:
		var p_len: float = float(preds.size())
		metrics.avg_predator_speed = total_pred_speed / p_len
		metrics.avg_predator_size = total_pred_size / p_len
		metrics.avg_predator_sense_range = total_pred_sense / p_len
		metrics.avg_predator_energy_efficiency = total_pred_eff / p_len
		metrics.avg_predator_predation = total_pred_predation / p_len
		metrics.allele_predation_variance = maxf(0.0, (sq_pred_predation / p_len) - (metrics.avg_predator_predation * metrics.avg_predator_predation)) if preds.size() > 1 else 0.0
	else:
		metrics.avg_predator_speed = 0.0
		metrics.avg_predator_size = 0.0
		metrics.avg_predator_sense_range = 0.0
		metrics.avg_predator_energy_efficiency = 0.0
		metrics.avg_predator_predation = 0.0
		metrics.allele_predation_variance = 0.0

	var total_drought_tol: float = 0.0
	var sq_drought_tol: float = 0.0
	var plants: Array = flora_sim.get_all_plants() if flora_sim else []
	for p in plants:
		if p.genome:
			var dt: float = p.genome.drought_tolerance
			total_drought_tol += dt
			sq_drought_tol += dt * dt
			max_gen = maxi(max_gen, p.genome.generation)

	var drg_var: float = 0.0
	if plants.size() > 0:
		var pl_len: float = float(plants.size())
		metrics.avg_plant_drought_tolerance = total_drought_tol / pl_len
		drg_var = maxf(0.0, (sq_drought_tol / pl_len) - (metrics.avg_plant_drought_tolerance * metrics.avg_plant_drought_tolerance)) if plants.size() > 1 else 0.0
	else:
		metrics.avg_plant_drought_tolerance = 0.0
	metrics.allele_drought_variance = drg_var
	metrics.max_generation = max_gen

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
