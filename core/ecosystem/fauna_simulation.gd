class_name FaunaSimulation
extends RefCounted

## Manages Herbivore and Predator populations, foraging, metabolism, reproduction, and causal predator-prey dynamics.

const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")

enum LifeStage {
	JUVENILE = 0,
	ADULT = 1,
	ELDER = 2
}

enum HerbivoreState {
	WANDERING = 0,
	FORAGING = 1,
	EATING = 2,
	RESTING = 3,
	FLEEING = 4,
	STARVING = 5
}

enum PredatorState {
	WANDERING = 0,
	HUNTING = 1,
	EATING = 2,
	RESTING = 3,
	STARVING = 4
}

class AnimalBase:
	var id: int
	var type: String # "herbivore" or "predator"
	var species: String
	var position: Vector3
	var velocity: Vector3 = Vector3.ZERO
	var heading: float = 0.0 # Radians
	var health: float = 100.0 # 0 - 100%
	var energy: float = 80.0 # 0 - 100% (hunger meter)
	var age: float = 0.0
	var max_age: float = 120.0
	var life_stage: LifeStage = LifeStage.ADULT
	var move_speed: float = 3.5
	var reproduce_cooldown: float = 20.0
	var target_pos: Vector3 = Vector3.ZERO
	var genome: EcosystemGenome = null

class HerbivoreData extends AnimalBase:
	var state: HerbivoreState = HerbivoreState.WANDERING
	var target_plant_id: int = -1
	var threat_id: int = -1
	var eat_timer: float = 0.0

	func _init(p_id: int, p_pos: Vector3, p_genome: EcosystemGenome = null) -> void:
		id = p_id
		type = "herbivore"
		species = "island_deer"
		position = p_pos
		genome = p_genome if p_genome != null else EcosystemGenome.create_default_fauna("island_deer")
		max_age = 150.0
		move_speed = genome.get_effective_speed(3.2)
		reproduce_cooldown = 25.0 / genome.energy_efficiency
		state = HerbivoreState.WANDERING

class PredatorData extends AnimalBase:
	var state: PredatorState = PredatorState.WANDERING
	var target_prey_id: int = -1
	var eat_timer: float = 0.0

	func _init(p_id: int, p_pos: Vector3, p_genome: EcosystemGenome = null) -> void:
		id = p_id
		type = "predator"
		species = "mountain_stalker"
		position = p_pos
		genome = p_genome if p_genome != null else EcosystemGenome.create_default_fauna("mountain_stalker")
		max_age = 180.0
		move_speed = genome.get_effective_speed(5.4)
		reproduce_cooldown = 35.0 / genome.energy_efficiency
		state = PredatorState.WANDERING


var _herbivores: Dictionary = {} # int id -> HerbivoreData
var _predators: Dictionary = {} # int id -> PredatorData
var _next_id: int = 1000

var _rng: RandomNumberGenerator
var _entity_registry: EntityRegistry
var _metrics: EcosystemMetrics
var _event_bus: WorldEventBus

const ISLAND_MAX_RADIUS: float = 68.0

func _init(rng: RandomNumberGenerator, registry: EntityRegistry, metrics: EcosystemMetrics, bus: WorldEventBus = null) -> void:
	_rng = rng if rng != null else RandomNumberGenerator.new()
	_entity_registry = registry
	_metrics = metrics
	_event_bus = bus

func spawn_herbivore(pos: Vector3, initial_energy: float = 80.0, stage: LifeStage = LifeStage.ADULT, genome: EcosystemGenome = null) -> int:
	var id: int = _next_id
	_next_id += 1

	var h: HerbivoreData = HerbivoreData.new(id, pos, genome)
	h.energy = initial_energy
	h.life_stage = stage
	h.age = 30.0 if stage == LifeStage.ADULT else (0.0 if stage == LifeStage.JUVENILE else 110.0)
	h.heading = _rng.randf() * TAU
	_herbivores[id] = h

	if _entity_registry:
		_entity_registry.spawn_entity("herbivore", pos, {
			"species": h.species,
			"energy": h.energy,
			"health": h.health,
			"state": h.state,
			"life_stage": h.life_stage,
			"genome": h.genome.serialize() if h.genome else {}
		}, id)

	if _metrics:
		_metrics.record_birth("herbivore")

	if _event_bus:
		_event_bus.publish("fauna_spawned", {"id": id, "type": "herbivore", "position": pos})

	return id

func spawn_predator(pos: Vector3, initial_energy: float = 80.0, genome: EcosystemGenome = null) -> int:
	var id: int = _next_id
	_next_id += 1

	var p: PredatorData = PredatorData.new(id, pos, genome)
	p.energy = initial_energy
	p.heading = _rng.randf() * TAU
	_predators[id] = p

	if _entity_registry:
		_entity_registry.spawn_entity("predator", pos, {
			"species": p.species,
			"energy": p.energy,
			"health": p.health,
			"state": p.state,
			"life_stage": p.life_stage,
			"genome": p.genome.serialize() if p.genome else {}
		}, id)



	if _metrics:
		_metrics.record_birth("predator")

	if _event_bus:
		_event_bus.publish("fauna_spawned", {"id": id, "type": "predator", "position": pos})

	return id

func remove_herbivore(id: int, reason: String = "natural") -> void:
	if not _herbivores.has(id):
		return
	var pos: Vector3 = _herbivores[id].position
	_herbivores.erase(id)

	if _entity_registry:
		_entity_registry.despawn_entity(id, reason)

	if _metrics:
		_metrics.record_death("herbivore", reason)

	if _event_bus:
		_event_bus.publish("fauna_died", {"id": id, "type": "herbivore", "reason": reason, "position": pos})

func remove_predator(id: int, reason: String = "natural") -> void:
	if not _predators.has(id):
		return
	var pos: Vector3 = _predators[id].position
	_predators.erase(id)

	if _entity_registry:
		_entity_registry.despawn_entity(id, reason)

	if _metrics:
		_metrics.record_death("predator", reason)

	if _event_bus:
		_event_bus.publish("fauna_died", {"id": id, "type": "predator", "reason": reason, "position": pos})

func get_herbivore(id: int) -> HerbivoreData:
	return _herbivores.get(id, null)

func get_predator(id: int) -> PredatorData:
	return _predators.get(id, null)

func get_herbivore_count() -> int:
	return _herbivores.size()

func get_predator_count() -> int:
	return _predators.size()

func get_all_herbivores() -> Array:
	return _herbivores.values()

func get_all_predators() -> Array:
	return _predators.values()

## Step simulation for all fauna: updates metabolism, AI decisions, foraging, and predator-prey dynamics
func step_simulation(delta: float, flora_sim: RefCounted, height_callable: Callable, weather: RefCounted = null) -> void:
	var herbivore_deaths: Array[Dictionary] = []
	var herbivore_births: Array = []
	var predator_deaths: Array[Dictionary] = []
	var predator_births: Array = []

	var weather_speed_mult: float = 1.0
	var weather_burn_mult: float = 1.0
	if weather:
		var w_state: int = int(weather.get("current_state"))
		if w_state == 2: # WeatherState.RAIN
			weather_speed_mult = 0.82 # 18% slower movement through wet mud/rain
			weather_burn_mult = 1.10 # rain chill increased metabolic demand
		elif w_state == 3: # WeatherState.DROUGHT
			weather_speed_mult = 0.95
			weather_burn_mult = 1.15 # heat/thirst dehydration

	var total_herb_energy: float = 0.0
	var total_herb_health: float = 0.0
	var total_pred_energy: float = 0.0

	# =========================================================================
	# 1. HERBIVORES SIMULATION
	# =========================================================================
	for id: int in _herbivores.keys():
		var h: HerbivoreData = _herbivores[id]
		h.age += delta
		if h.reproduce_cooldown > 0.0:
			h.reproduce_cooldown -= delta

		# Lifecycle stages
		if h.age > h.max_age * 0.7:
			h.life_stage = LifeStage.ELDER
		elif h.age > 25.0:
			h.life_stage = LifeStage.ADULT
		else:
			h.life_stage = LifeStage.JUVENILE

		# Metabolism (energy drain based on genome trade-off and weather chill)
		var burn_mult: float = (h.genome.get_metabolic_burn_multiplier() if h.genome else 1.0) * weather_burn_mult
		var metabolic_drain: float = 1.0 * delta * burn_mult
		if h.velocity.length_squared() > 0.1:
			metabolic_drain += 0.5 * delta * (h.genome.speed if h.genome else 1.0) * weather_burn_mult
		h.energy = maxf(0.0, h.energy - metabolic_drain)

		# Starvation damage
		if h.energy <= 0.0:
			h.health = maxf(0.0, h.health - 6.0 * delta)
			h.state = HerbivoreState.STARVING
			if h.health <= 0.0:
				herbivore_deaths.append({"id": id, "reason": "starvation"})
				continue
		elif h.energy < 25.0:
			h.state = HerbivoreState.STARVING

		# Old age death
		if h.age >= h.max_age:
			h.health = maxf(0.0, h.health - 8.0 * delta)
			if h.health <= 0.0:
				herbivore_deaths.append({"id": id, "reason": "old_age"})
				continue

		# Check nearby predators (Threat / Fleeing with sense_range)
		var threat_dist: float = (h.genome.sense_range * 0.5) if h.genome else 14.0
		var nearest_threat: PredatorData = _find_nearest_predator(h.position, threat_dist)

		if nearest_threat != null:
			h.state = HerbivoreState.FLEEING
			h.threat_id = nearest_threat.id
			# Flee directly away from threat
			var flee_dir: Vector3 = (h.position - nearest_threat.position)
			flee_dir.y = 0.0
			if flee_dir.length_squared() < 0.01:
				flee_dir = Vector3(cos(h.heading), 0.0, sin(h.heading))
			else:
				flee_dir = flee_dir.normalized()
			h.velocity = flee_dir * (h.move_speed * 1.25 * weather_speed_mult)
			_move_animal(h, delta, height_callable)
		else:
			# Not fleeing: AI behavior based on energy
			var max_e: float = h.genome.get_effective_max_energy() if h.genome else 100.0
			var max_hp: float = h.genome.get_effective_max_health() if h.genome else 100.0

			if h.state == HerbivoreState.EATING:
				h.eat_timer += delta
				if flora_sim:
					var intake_rate: float = h.genome.get_effective_intake_rate(2.5) if h.genome else 2.5
					var eaten: float = flora_sim.consume_biomass(h.target_plant_id, intake_rate * delta)
					var energy_gain: float = eaten * 12.0 * (h.genome.energy_efficiency if h.genome else 1.0)
					h.energy = minf(max_e, h.energy + energy_gain)
					h.health = minf(max_hp, h.health + 2.0 * delta)

					# Stop eating if plant depleted or full
					if eaten <= 0.05 or h.energy >= (max_e * 0.95) or h.eat_timer > 4.0:
						h.state = HerbivoreState.WANDERING
						h.eat_timer = 0.0
						h.target_plant_id = -1
				h.velocity = Vector3.ZERO
			elif h.energy < (max_e * 0.80):
				# Hungry: Seek food with sense_range
				h.state = HerbivoreState.FORAGING
				var food: Variant = null
				var forage_radius: float = h.genome.sense_range if h.genome else 28.0
				if flora_sim:
					food = flora_sim.find_nearest_food(h.position, forage_radius, 0.8)

				if food != null:
					h.target_plant_id = food.id
					var to_food: Vector3 = (food.position - h.position)
					to_food.y = 0.0
					var dist: float = to_food.length()
					if dist < 1.4:
						h.state = HerbivoreState.EATING
						h.eat_timer = 0.0
						h.velocity = Vector3.ZERO
						if flora_sim:
							var intake_rate: float = h.genome.get_effective_intake_rate(2.5) if h.genome else 2.5
							var eaten: float = flora_sim.consume_biomass(h.target_plant_id, intake_rate * delta)
							var energy_gain: float = eaten * 12.0 * (h.genome.energy_efficiency if h.genome else 1.0)
							h.energy = minf(max_e, h.energy + energy_gain)
							h.health = minf(max_hp, h.health + 2.0 * delta)
					else:
						h.velocity = to_food.normalized() * (h.move_speed * weather_speed_mult)
						_move_animal(h, delta, height_callable)
				else:
					# No food nearby: wander to find grazing grounds
					_wander_animal(h, delta, height_callable, weather_speed_mult)
			else:
				# Full / Content: Wander peacefully or rest
				h.state = HerbivoreState.WANDERING
				_wander_animal(h, delta, height_callable, weather_speed_mult)

		# Reproduction (Adult with high energy & health)
		if h.life_stage == LifeStage.ADULT and h.energy >= 75.0 and h.health >= 70.0 and h.reproduce_cooldown <= 0.0:
			if _herbivores.size() < 40:
				var mate: HerbivoreData = _find_compatible_mate(h, (h.genome.sense_range * 0.5) if h.genome else 14.0)
				var child_genome: EcosystemGenome = null
				if mate != null and mate.genome != null and h.genome != null:
					child_genome = EcosystemGenome.create_recombined_offspring(h.genome, mate.genome, h.id, mate.id, _rng, 0.25, 0.05)
					mate.energy -= 20.0
					mate.reproduce_cooldown = maxf(mate.reproduce_cooldown, 15.0 / mate.genome.energy_efficiency)
				elif h.genome != null:
					child_genome = h.genome.create_mutated_offspring(h.id, _rng, 0.25, 0.05)

				var b_pos: Vector3 = h.position + Vector3(_rng.randf_range(-2.0, 2.0), 0.0, _rng.randf_range(-2.0, 2.0))
				herbivore_births.append({"pos": b_pos, "genome": child_genome})
				h.energy -= 35.0
				var base_cool: float = _rng.randf_range(25.0, 45.0)
				h.reproduce_cooldown = base_cool / (h.genome.energy_efficiency if h.genome else 1.0)

		total_herb_energy += h.energy
		total_herb_health += h.health

		if _entity_registry:
			_entity_registry.update_property(id, "position", h.position)
			_entity_registry.update_property(id, "energy", h.energy)
			_entity_registry.update_property(id, "health", h.health)
			_entity_registry.update_property(id, "state", h.state)
			_entity_registry.update_property(id, "life_stage", h.life_stage)

	# =========================================================================
	# 2. PREDATORS SIMULATION
	# =========================================================================
	for pid: int in _predators.keys():
		var p: PredatorData = _predators[pid]
		p.age += delta
		if p.reproduce_cooldown > 0.0:
			p.reproduce_cooldown -= delta

		# Metabolism
		var p_burn: float = 1.2 * delta * (p.genome.get_metabolic_burn_multiplier() if p.genome else 1.0)
		p.energy = maxf(0.0, p.energy - p_burn)
		if p.energy <= 0.0:
			p.health = maxf(0.0, p.health - 5.0 * delta)
			p.state = PredatorState.STARVING
			if p.health <= 0.0:
				predator_deaths.append({"id": pid, "reason": "starvation"})
				continue
		elif p.energy < 30.0:
			p.state = PredatorState.STARVING

		# Old age
		if p.age >= p.max_age:
			p.health = maxf(0.0, p.health - 6.0 * delta)
			if p.health <= 0.0:
				predator_deaths.append({"id": pid, "reason": "old_age"})
				continue

		var p_max_e: float = p.genome.get_effective_max_energy() if p.genome else 100.0
		var p_max_hp: float = p.genome.get_effective_max_health() if p.genome else 100.0

		if p.state == PredatorState.EATING:
			p.eat_timer += delta
			p.velocity = Vector3.ZERO
			if p.eat_timer >= 3.0 or p.energy >= (p_max_e * 0.95):
				p.state = PredatorState.WANDERING
				p.eat_timer = 0.0
		elif p.energy < (p_max_e * 0.75):
			# Hunt nearest herbivore with sense_range
			p.state = PredatorState.HUNTING
			var hunt_radius: float = p.genome.sense_range if p.genome else 32.0
			var target_prey: HerbivoreData = _find_nearest_herbivore(p.position, hunt_radius)
			if target_prey != null:
				p.target_prey_id = target_prey.id
				var to_prey: Vector3 = (target_prey.position - p.position)
				to_prey.y = 0.0
				var dist: float = to_prey.length()
				var strike_dist: float = p.genome.get_effective_strike_distance(2.0) if p.genome else 2.0
				if dist < strike_dist or dist <= (p.move_speed * delta):
					# Catch and kill prey! Strike success and yield depend on predation trait
					herbivore_deaths.append({"id": target_prey.id, "reason": "predation"})
					var kill_energy: float = p.genome.get_effective_kill_yield(55.0) if p.genome else 55.0
					p.energy = minf(p_max_e, p.energy + kill_energy)
					p.health = minf(p_max_hp, p.health + 15.0)
					p.state = PredatorState.EATING
					p.eat_timer = 0.0
					p.velocity = Vector3.ZERO
				else:
					p.velocity = to_prey.normalized() * (p.move_speed * weather_speed_mult)
					_move_animal(p, delta, height_callable)
			else:
				# No prey found: wander
				_wander_animal(p, delta, height_callable, weather_speed_mult)
		else:
			p.state = PredatorState.WANDERING
			_wander_animal(p, delta, height_callable, weather_speed_mult)

		# Predator reproduction (Sexual recombination if compatible mate is nearby, else single-parent)
		if p.energy >= 85.0 and p.health >= 80.0 and p.reproduce_cooldown <= 0.0 and _predators.size() < 6:
			var p_mate: PredatorData = _find_compatible_mate(p, (p.genome.sense_range * 0.5) if p.genome else 16.0)
			var child_p_genome: EcosystemGenome = null
			if p_mate != null and p_mate.genome != null and p.genome != null:
				child_p_genome = EcosystemGenome.create_recombined_offspring(p.genome, p_mate.genome, p.id, p_mate.id, _rng, 0.25, 0.05)
				p_mate.energy -= 25.0
				p_mate.reproduce_cooldown = maxf(p_mate.reproduce_cooldown, 25.0 / p_mate.genome.energy_efficiency)
			elif p.genome != null:
				child_p_genome = p.genome.create_mutated_offspring(p.id, _rng, 0.25, 0.05)

			var pb_pos: Vector3 = p.position + Vector3(_rng.randf_range(-2.0, 2.0), 0.0, _rng.randf_range(-2.0, 2.0))
			predator_births.append({"pos": pb_pos, "genome": child_p_genome})
			p.energy -= 40.0
			var base_pred_cool: float = _rng.randf_range(40.0, 60.0)
			p.reproduce_cooldown = base_pred_cool / (p.genome.energy_efficiency if p.genome else 1.0)


		total_pred_energy += p.energy

		if _entity_registry:
			_entity_registry.update_property(pid, "position", p.position)
			_entity_registry.update_property(pid, "energy", p.energy)
			_entity_registry.update_property(pid, "health", p.health)
			_entity_registry.update_property(pid, "state", p.state)

	# Remove dead animals
	for d: Dictionary in herbivore_deaths:
		remove_herbivore(d["id"], d["reason"])
	for d: Dictionary in predator_deaths:
		remove_predator(d["id"], d["reason"])

	# Spawn newborns
	for b in herbivore_births:
		if b is Dictionary:
			spawn_herbivore(b["pos"], 60.0, LifeStage.JUVENILE, b.get("genome", null))
		elif b is Vector3:
			spawn_herbivore(b, 60.0, LifeStage.JUVENILE)
	for pb in predator_births:
		if pb is Dictionary:
			spawn_predator(pb["pos"], 60.0, pb.get("genome", null))
		elif pb is Vector3:
			spawn_predator(pb, 60.0)


	# Update aggregate metrics
	if _metrics:
		var h_count: int = _herbivores.size()
		var p_count: int = _predators.size()
		_metrics.herbivore_count = h_count
		_metrics.predator_count = p_count
		_metrics.average_herbivore_energy = (total_herb_energy / float(h_count)) if h_count > 0 else 0.0
		_metrics.average_herbivore_health = (total_herb_health / float(h_count)) if h_count > 0 else 0.0
		_metrics.average_predator_energy = (total_pred_energy / float(p_count)) if p_count > 0 else 0.0

		# Food availability ratio: available biomass / herd consumption demand
		var herd_demand: float = maxf(1.0, float(h_count) * 2.0)
		_metrics.food_availability_ratio = _metrics.total_biomass / herd_demand

func _move_animal(animal: AnimalBase, delta: float, height_callable: Callable) -> void:
	var next_pos: Vector3 = animal.position + animal.velocity * delta

	# Keep within island dry bounds (radius ~68m)
	if next_pos.length() > ISLAND_MAX_RADIUS:
		var to_center: Vector3 = -next_pos.normalized()
		animal.velocity = to_center * animal.move_speed
		next_pos = animal.position + animal.velocity * delta

	if height_callable.is_valid():
		var y: float = height_callable.call(next_pos.x, next_pos.z)
		# Ensure animal stays above water level (Y = 0.0)
		if y < 0.2:
			# Rebound inland
			animal.velocity = -animal.position.normalized() * animal.move_speed
			next_pos = animal.position + animal.velocity * delta
			y = maxf(0.2, height_callable.call(next_pos.x, next_pos.z))
		next_pos.y = y

	animal.position = next_pos
	if animal.velocity.length_squared() > 0.1:
		animal.heading = atan2(animal.velocity.z, animal.velocity.x)

func _wander_animal(animal: AnimalBase, delta: float, height_callable: Callable, speed_mult: float = 1.0) -> void:
	# Small random steering turn
	animal.heading += _rng.randf_range(-0.4, 0.4)
	animal.velocity = Vector3(cos(animal.heading), 0.0, sin(animal.heading)) * (animal.move_speed * 0.5 * speed_mult)
	_move_animal(animal, delta, height_callable)

func _find_nearest_predator(pos: Vector3, max_dist: float) -> PredatorData:
	var best_dist_sq: float = max_dist * max_dist
	var nearest: PredatorData = null
	for p: PredatorData in _predators.values():
		var d_sq: float = pos.distance_squared_to(p.position)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			nearest = p
	return nearest

func _find_nearest_herbivore(pos: Vector3, max_dist: float) -> HerbivoreData:
	var best_dist_sq: float = max_dist * max_dist
	var nearest: HerbivoreData = null
	for h: HerbivoreData in _herbivores.values():
		var d_sq: float = pos.distance_squared_to(h.position)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			nearest = h
	return nearest

func _find_compatible_mate(animal: AnimalBase, search_radius: float) -> AnimalBase:
	var best_dist_sq: float = search_radius * search_radius
	var best_mate: AnimalBase = null
	var candidate_pool: Array = _herbivores.values() if animal.type == "herbivore" else _predators.values()
	for candidate in candidate_pool:
		if candidate.id == animal.id:
			continue
		if candidate.life_stage != LifeStage.ADULT:
			continue
		if candidate.energy < 60.0 or candidate.health < 60.0:
			continue
		var d_sq: float = animal.position.distance_squared_to(candidate.position)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			best_mate = candidate
	return best_mate

func restore_herbivore(data: Dictionary) -> int:
	var id: int = int(data.get("id", _next_id))
	_next_id = maxi(_next_id, id + 1)
	var pos: Vector3 = data.get("position", Vector3.ZERO)
	var genome: EcosystemGenome = null
	if data.has("genome") and data["genome"] is Dictionary and not data["genome"].is_empty():
		genome = EcosystemGenome.deserialize(data["genome"])
	var h: HerbivoreData = HerbivoreData.new(id, pos, genome)
	h.species = data.get("species", "island_deer")
	h.velocity = data.get("velocity", Vector3.ZERO)
	h.heading = float(data.get("heading", 0.0))
	h.health = float(data.get("health", 100.0))
	h.energy = float(data.get("energy", 80.0))
	h.age = float(data.get("age", 0.0))
	h.life_stage = data.get("life_stage", LifeStage.ADULT) as LifeStage
	h.state = data.get("state", HerbivoreState.WANDERING) as HerbivoreState
	_herbivores[id] = h
	if _entity_registry:
		_entity_registry.spawn_entity("herbivore", pos, {
			"species": h.species,
			"energy": h.energy,
			"health": h.health,
			"state": h.state,
			"life_stage": h.life_stage,
			"genome": h.genome.serialize() if h.genome else {}
		}, id)
	return id

func restore_predator(data: Dictionary) -> int:
	var id: int = int(data.get("id", _next_id))
	_next_id = maxi(_next_id, id + 1)
	var pos: Vector3 = data.get("position", Vector3.ZERO)
	var genome: EcosystemGenome = null
	if data.has("genome") and data["genome"] is Dictionary and not data["genome"].is_empty():
		genome = EcosystemGenome.deserialize(data["genome"])
	var p: PredatorData = PredatorData.new(id, pos, genome)
	p.species = data.get("species", "mountain_stalker")
	p.velocity = data.get("velocity", Vector3.ZERO)
	p.heading = float(data.get("heading", 0.0))
	p.health = float(data.get("health", 100.0))
	p.energy = float(data.get("energy", 80.0))
	p.age = float(data.get("age", 0.0))
	p.life_stage = data.get("life_stage", LifeStage.ADULT) as LifeStage
	p.state = data.get("state", PredatorState.WANDERING) as PredatorState
	_predators[id] = p
	if _entity_registry:
		_entity_registry.spawn_entity("predator", pos, {
			"species": p.species,
			"energy": p.energy,
			"health": p.health,
			"state": p.state,
			"life_stage": p.life_stage,
			"genome": p.genome.serialize() if p.genome else {}
		}, id)
	return id


func clear() -> void:
	if _entity_registry:
		for id: int in _herbivores.keys():
			_entity_registry.despawn_entity(id, "clear")
		for id: int in _predators.keys():
			_entity_registry.despawn_entity(id, "clear")
	_herbivores.clear()
	_predators.clear()
	_next_id = 1000
