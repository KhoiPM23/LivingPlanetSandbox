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
	STARVING = 5,
	DRINKING = 6,
	ALERT = 7
}

enum PredatorState {
	WANDERING = 0,
	HUNTING = 1,
	EATING = 2,
	RESTING = 3,
	STARVING = 4,
	DRINKING = 5,
	ALERT = 6
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
	var wander_timer: float = 0.0
	var wander_interval: float = 2.0
	var desync_offset: float = 0.0
	var state_timer: float = 0.0
	var hydration: float = 85.0 # 0 - 100% (thirst meter)
	var alert_timer: float = 0.0 # Time spent in vigilant alert
	var is_sheltered: bool = false # Under forest canopy or rock overhang
	var temperament: String = "balanced"
	var temperament_factor: float = 1.0
	var sim_lod_tier: int = 0 # 0: Full (<35m), 1: Mid (35-75m), 2: Distant (>75m)
	var lod_step_counter: int = 0

class HerbivoreData extends AnimalBase:
	var state: HerbivoreState = HerbivoreState.WANDERING
	var target_plant_id: int = -1
	var threat_id: int = -1
	var eat_timer: float = 0.0
	var flee_timer: float = 0.0
	var vigilance_timer: float = 0.0
	var threat_memory: float = 0.0
	var last_known_threat_pos: Vector3 = Vector3.ZERO
	var alarm_cooldown: float = 0.0
	var panic_alarm_cooldown: float = 0.0
	var regroup_timer: float = 0.0
	var reaction_latency: float = 0.0 # Latency before executing herd alarm flight
	var pending_panic_alarm: bool = false
	var is_in_sanctuary: bool = false
	var is_sleeping: bool = false
	var sanctuary_pos: Vector3 = Vector3.ZERO

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
	var is_stalking: bool = false
	var sprint_timer: float = 0.0
	var hunt_duration: float = 0.0
	var hunt_stamina: float = 7.0
	var hunt_fatigue: float = 0.0
	var stalks_abandoned: int = 0
	var is_deterred_by_fire: bool = false

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

var _player_pos: Vector3 = Vector3.ZERO
var _last_player_pos: Vector3 = Vector3.ZERO
var _player_speed: float = 0.0
var _player_present: bool = false
const ISLAND_MAX_RADIUS: float = 68.0
var island_boundary_radius: float = 68.0

# Active Dynamic Light Sources for Nyctophobia / Phototaxis (Torches & Campfires)
var _active_light_sources: Array[Vector3] = []

func set_active_light_sources(sources: Array[Vector3]) -> void:
	_active_light_sources = sources

func register_light_source(pos: Vector3) -> void:
	if not _active_light_sources.has(pos):
		_active_light_sources.append(pos)

func unregister_light_source(pos: Vector3) -> void:
	_active_light_sources.erase(pos)

func get_active_light_sources() -> Array[Vector3]:
	return _active_light_sources

func set_boundary_radius(radius: float) -> void:
	island_boundary_radius = radius

# Sector Disturbance Spatial Memory Map (Block 27)
const SECTOR_NAMES: Array[String] = ["NW_SUMMIT", "NE_COVE", "SW_FOREST", "SE_MEADOW"]
const SECTOR_CENTERS: Array[Vector3] = [
	Vector3(-25.0, 0.0, -25.0), # NW Summit
	Vector3(25.0, 0.0, -25.0),  # NE Cove
	Vector3(-25.0, 0.0, 25.0),  # SW Forest
	Vector3(25.0, 0.0, 25.0)    # SE Meadow
]
var sector_disturbances: Array[float] = [0.0, 0.0, 0.0, 0.0]
var last_simulation_step_time_ms: float = 0.0

func get_sector_index(pos: Vector3) -> int:
	var is_east: bool = pos.x > 0.0
	var is_south: bool = pos.z > 0.0
	if not is_east and not is_south:
		return 0 # NW_SUMMIT
	elif is_east and not is_south:
		return 1 # NE_COVE
	elif not is_east and is_south:
		return 2 # SW_FOREST
	else:
		return 3 # SE_MEADOW

func add_sector_disturbance(target, amount: float) -> void:
	var idx: int = -1
	if target is Vector3:
		idx = get_sector_index(target)
	elif target is int or target is float:
		idx = int(target)
	if idx >= 0 and idx < sector_disturbances.size():
		sector_disturbances[idx] = clampf(sector_disturbances[idx] + amount, 0.0, 100.0)

func get_sector_disturbances() -> Array[float]:
	return sector_disturbances

func get_sector_disturbance(idx: int) -> float:
	if idx >= 0 and idx < sector_disturbances.size():
		return sector_disturbances[idx]
	return 0.0

func get_lowest_disturbance_sector() -> int:
	var lowest_idx: int = 0
	var lowest_val: float = sector_disturbances[0]
	for i: int in range(1, sector_disturbances.size()):
		if sector_disturbances[i] < lowest_val:
			lowest_val = sector_disturbances[i]
			lowest_idx = i
	return lowest_idx

func get_sector_center(idx: int) -> Vector3:
	if idx >= 0 and idx < SECTOR_CENTERS.size():
		return SECTOR_CENTERS[idx]
	return Vector3.ZERO


func set_player_presence(player_pos: Vector3, is_present: bool, speed: float = -1.0) -> void:
	if speed >= 0.0:
		_player_speed = speed
	elif _player_present and is_present:
		var horiz_dist: float = Vector2(player_pos.x - _last_player_pos.x, player_pos.z - _last_player_pos.z).length()
		if horiz_dist > 6.0:
			_player_speed = 0.0
		else:
			_player_speed = horiz_dist * 2.0
	else:
		_player_speed = 0.0
	_last_player_pos = _player_pos
	_player_pos = player_pos
	_player_present = is_present

func update_player(player_pos: Vector3, speed: float = -1.0, is_present: bool = true) -> void:
	set_player_presence(player_pos, is_present, speed)

func get_player_position() -> Vector3:
	return _player_pos

func get_player_speed() -> float:
	return _player_speed

func is_player_present() -> bool:
	return _player_present

## Ray-march Line of Sight check against terrain height profile to model occlusion by ridges/crests.
func _check_line_of_sight(from_pos: Vector3, to_pos: Vector3, height_callable: Callable) -> bool:
	if not height_callable.is_valid():
		return true
	var from_ground_y: float = height_callable.call(from_pos.x, from_pos.z)
	var to_ground_y: float = height_callable.call(to_pos.x, to_pos.z)
	var start_y: float = maxf(from_pos.y, from_ground_y) + 1.2
	var end_y: float = maxf(to_pos.y, to_ground_y) + 1.5
	var horiz_dist: float = Vector2(to_pos.x - from_pos.x, to_pos.z - from_pos.z).length()
	if horiz_dist < 2.0:
		return true
	for t in [0.25, 0.50, 0.75]:
		var sample_x: float = lerpf(from_pos.x, to_pos.x, t)
		var sample_z: float = lerpf(from_pos.z, to_pos.z, t)
		var ray_y: float = lerpf(start_y, end_y, t)
		var terrain_y: float = height_callable.call(sample_x, sample_z)
		if terrain_y > ray_y + 0.30:
			return false
	return true

func _init(rng: RandomNumberGenerator = null, registry: EntityRegistry = null, metrics: EcosystemMetrics = null, bus: WorldEventBus = null) -> void:
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
	h.wander_interval = _rng.randf_range(1.6, 3.4)
	h.wander_timer = _rng.randf_range(0.0, h.wander_interval)
	h.desync_offset = _rng.randf_range(0.0, 5.0)
	var temp_roll: float = _rng.randf()
	if temp_roll < 0.25:
		h.temperament = "cautious"
		h.temperament_factor = 1.15
	elif temp_roll > 0.75:
		h.temperament = "bold"
		h.temperament_factor = 0.88
	else:
		h.temperament = "balanced"
		h.temperament_factor = 1.0
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
	p.wander_interval = _rng.randf_range(1.8, 3.6)
	p.wander_timer = _rng.randf_range(0.0, p.wander_interval)
	p.desync_offset = _rng.randf_range(0.0, 5.0)
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

func tame_feed_herbivore(id: int) -> bool:
	var h: HerbivoreData = get_herbivore(id)
	if not h:
		return false
	h.energy = clampf(h.energy + 35.0, 0.0, 100.0)
	h.threat_memory = 0.0
	h.flee_timer = 0.0
	h.state = HerbivoreState.EATING
	return true

func get_predator(id: int) -> PredatorData:
	return _predators.get(id, null)

func get_herbivore_count() -> int:
	return _herbivores.size()

func get_predator_count() -> int:
	return _predators.size()

func get_all_herbivores() -> Array:
	return _herbivores.values()

func get_herbivores() -> Array:
	return _herbivores.values()

func get_all_predators() -> Array:
	return _predators.values()

func get_predators() -> Array:
	return _predators.values()

## Step simulation for all fauna: updates metabolism, AI decisions, foraging, and predator-prey dynamics
func step_simulation(delta: float, flora_sim: RefCounted, height_callable: Callable, weather: RefCounted = null, sim_hour: float = 12.0) -> void:
	var step_start_usec: int = Time.get_ticks_usec()
	var herbivore_deaths: Array[Dictionary] = []
	var herbivore_births: Array = []
	var predator_deaths: Array[Dictionary] = []
	var predator_births: Array = []

	# Sector Disturbance Decay & Player Sprint Disturbance (Block 27)
	for s_i: int in range(sector_disturbances.size()):
		sector_disturbances[s_i] = maxf(0.0, sector_disturbances[s_i] - 1.2 * delta)

	if _player_present and _player_speed > 3.8:
		add_sector_disturbance(_player_pos, 4.0 * delta)

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

		# Simulation LOD tier assignment (Block 27)
		var dist_to_player: float = h.position.distance_to(_player_pos) if _player_present else 10.0
		if dist_to_player < 35.0:
			h.sim_lod_tier = 0
		elif dist_to_player < 75.0:
			h.sim_lod_tier = 1
		else:
			h.sim_lod_tier = 2
		h.lod_step_counter += 1

		# Reaction latency propagation for herd alarm (Block 27)
		if h.reaction_latency > 0.0:
			h.reaction_latency = maxf(0.0, h.reaction_latency - delta)
			if h.reaction_latency <= 0.0 and h.pending_panic_alarm:
				h.pending_panic_alarm = false
				if h.state != HerbivoreState.FLEEING:
					h.state = HerbivoreState.FLEEING
					h.flee_timer = 2.8

		# Lifecycle stages
		if h.age > h.max_age * 0.7:
			h.life_stage = LifeStage.ELDER
		elif h.age > 25.0:
			h.life_stage = LifeStage.ADULT
		else:
			h.life_stage = LifeStage.JUVENILE

		# Metabolism & Hydration
		var burn_mult: float = (h.genome.get_metabolic_burn_multiplier() if h.genome else 1.0) * weather_burn_mult
		if h.state == HerbivoreState.RESTING:
			burn_mult *= 0.50 # Resting sleep conservation
		if h.is_in_sanctuary or h.is_sleeping:
			burn_mult *= 0.60 # Additional 40% metabolic conservation near campfire/torch sanctuary
		var metabolic_drain: float = 1.0 * delta * burn_mult
		if h.velocity.length_squared() > 0.1:
			metabolic_drain += 0.5 * delta * (h.genome.speed if h.genome else 1.0) * weather_burn_mult
		h.energy = maxf(0.0, h.energy - metabolic_drain)

		# Hydration depletion (accelerated by heat/drought)
		var drought_thirst: float = 1.8 if (weather and int(weather.get("current_state")) == 3) else 1.0
		h.hydration = maxf(0.0, h.hydration - 0.35 * delta * drought_thirst)

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

		# Timers advance
		if h.alarm_cooldown > 0.0:
			h.alarm_cooldown = maxf(0.0, h.alarm_cooldown - delta)
		if h.panic_alarm_cooldown > 0.0:
			h.panic_alarm_cooldown = maxf(0.0, h.panic_alarm_cooldown - delta)
		if h.flee_timer > 0.0:
			h.flee_timer = maxf(0.0, h.flee_timer - delta)
		if h.vigilance_timer > 0.0:
			h.vigilance_timer = maxf(0.0, h.vigilance_timer - delta)
		if h.regroup_timer > 0.0:
			h.regroup_timer = maxf(0.0, h.regroup_timer - delta)
		if h.threat_memory > 0.0:
			h.threat_memory = maxf(0.0, h.threat_memory - delta * 0.25)

		# Check nearby predators (Threat / Fleeing with sense_range and line-of-sight)
		var threat_dist: float = ((h.genome.sense_range * 0.5) if h.genome else 14.0) * h.temperament_factor
		var nearest_threat: PredatorData = _find_nearest_predator(h.position, threat_dist)
		var predator_detected: bool = false
		var should_panic_flee: bool = false
		if nearest_threat != null:
			var pred_dist: float = h.position.distance_to(nearest_threat.position)
			var has_los_to_pred: bool = _check_line_of_sight(h.position, nearest_threat.position, height_callable)
			if has_los_to_pred or pred_dist < 4.5 or (not nearest_threat.is_stalking and pred_dist < 8.5):
				predator_detected = true
				if pred_dist <= 7.5 or (nearest_threat.state == PredatorState.HUNTING and not nearest_threat.is_stalking):
					should_panic_flee = true

		if predator_detected and nearest_threat != null:
			# Priority override: Survival cancels feeding, drinking, or resting immediately
			if h.state == HerbivoreState.EATING or h.state == HerbivoreState.DRINKING or h.state == HerbivoreState.RESTING:
				h.target_plant_id = -1
				h.eat_timer = 0.0

			if should_panic_flee:
				h.state = HerbivoreState.FLEEING
				h.threat_id = nearest_threat.id
				h.flee_timer = 3.2
				h.threat_memory = 1.0
				h.last_known_threat_pos = nearest_threat.position
				_spread_herd_alarm(h, true)
				# Flee directly away from threat
				var flee_dir: Vector3 = (h.position - nearest_threat.position)
				flee_dir.y = 0.0
				if flee_dir.length_squared() < 0.01:
					flee_dir = Vector3(cos(h.heading), 0.0, sin(h.heading))
				else:
					flee_dir = flee_dir.normalized()

				# Flocking separation and alignment during flight to disperse herd without clipping
				var flight_sep: Vector3 = Vector3.ZERO
				var flight_align: Vector3 = Vector3.ZERO
				var flight_peers: int = 0
				for other in _herbivores.values():
					if other.id != h.id:
						var o_diff: Vector3 = h.position - other.position
						o_diff.y = 0.0
						var o_dist: float = o_diff.length()
						if o_dist < 4.0 and o_dist > 0.01:
							flight_sep += (o_diff / (o_dist * o_dist)) * 2.5
						if o_dist < 14.0 and other.state == HerbivoreState.FLEEING and other.velocity.length_squared() > 0.1:
							flight_align += other.velocity.normalized()
							flight_peers += 1
				if flight_sep.length_squared() > 0.01:
					flee_dir = (flee_dir * 1.0 + flight_sep.normalized() * 0.85).normalized()
				if flight_peers > 0:
					flee_dir = (flee_dir * 1.0 + (flight_align / float(flight_peers)).normalized() * 0.35).normalized()

				h.velocity = flee_dir * (h.move_speed * 1.25 * weather_speed_mult)
				_move_animal(h, delta, height_callable)
			else:
				# Stalking or distant threat: observant ALERT vigilance
				h.state = HerbivoreState.ALERT
				h.threat_id = nearest_threat.id
				h.threat_memory = 1.0
				h.last_known_threat_pos = nearest_threat.position
				h.vigilance_timer = 2.8
				var to_pred: Vector3 = (nearest_threat.position - h.position)
				to_pred.y = 0.0
				if to_pred.length_squared() > 0.01:
					h.heading = atan2(to_pred.z, to_pred.x)
				h.velocity = Vector3.ZERO
				_spread_herd_alarm(h, false)

		elif _player_present:
			var to_player: Vector3 = (_player_pos - h.position)
			to_player.y = 0.0
			var p_dist: float = to_player.length()

			var forward: Vector3 = Vector3(cos(h.heading), 0.0, sin(h.heading))
			var dot_p: float = forward.dot(to_player.normalized()) if p_dist > 0.01 else 1.0
			var is_behind: bool = dot_p < -0.88 # ~58-degree rear blind spot behind spine

			var has_los_to_player: bool = _check_line_of_sight(h.position, _player_pos, height_callable)
			var is_sprint: bool = _player_speed > 3.8
			var is_sneak: bool = _player_speed < 1.6 and _player_speed > 0.01

			var flight_trigger: bool = false
			var alert_trigger: bool = false

			# 1. Flight condition:
			# Sudden sprint approach within 12m, intimate close approach (< 7.0 * temperament), or active fast approach
			if is_sprint and p_dist < 12.0 and (has_los_to_player or p_dist < 8.0):
				flight_trigger = true
			elif p_dist < (7.0 * h.temperament_factor) and (has_los_to_player or p_dist < 4.5):
				flight_trigger = true
			elif not is_sneak and _player_speed > 1.8 and p_dist < (8.5 * h.temperament_factor) and has_los_to_player:
				flight_trigger = true

			# 2. Alert condition:
			if not flight_trigger and h.state != HerbivoreState.FLEEING:
				if has_los_to_player:
					if not is_behind:
						var alert_dist: float = (9.0 if is_sneak else 15.0) * h.temperament_factor
						if is_sprint:
							alert_dist = 20.0 * h.temperament_factor
						if p_dist <= alert_dist:
							alert_trigger = true
					else:
						# In rear blind spot: can only see if close, or heard footsteps
						var rear_detect_dist: float = 16.0 if is_sprint else (13.0 if not is_sneak else 6.0)
						if p_dist <= rear_detect_dist:
							alert_trigger = true
				else:
					# LOS occluded by terrain crest: only footstep acoustics penetrate
					if is_sprint and p_dist < 14.0:
						alert_trigger = true
					elif not is_sneak and p_dist < 4.5:
						alert_trigger = true

			if flight_trigger:
				h.state = HerbivoreState.FLEEING
				h.threat_id = -999 # Distinguish player encounter from predator
				h.flee_timer = 2.5
				h.threat_memory = 1.0
				h.last_known_threat_pos = _player_pos
				_spread_herd_alarm(h, true)
				var flee_dir: Vector3 = (h.position - _player_pos)
				flee_dir.y = 0.0
				if flee_dir.length_squared() < 0.01:
					flee_dir = Vector3(cos(h.heading), 0.0, sin(h.heading))
				else:
					flee_dir = flee_dir.normalized()

				# Flocking separation and alignment during flight from player
				var flight_sep: Vector3 = Vector3.ZERO
				var flight_align: Vector3 = Vector3.ZERO
				var flight_peers: int = 0
				for other in _herbivores.values():
					if other.id != h.id:
						var o_diff: Vector3 = h.position - other.position
						o_diff.y = 0.0
						var o_dist: float = o_diff.length()
						if o_dist < 3.0 and o_dist > 0.01:
							flight_sep += (o_diff / (o_dist * o_dist)) * 1.6
						if o_dist < 12.0 and other.state == HerbivoreState.FLEEING and other.velocity.length_squared() > 0.1:
							flight_align += other.velocity.normalized()
							flight_peers += 1
				if flight_sep.length_squared() > 0.01:
					flee_dir = (flee_dir * 1.0 + flight_sep.normalized() * 0.70).normalized()
				if flight_peers > 0:
					flee_dir = (flee_dir * 1.0 + (flight_align / float(flight_peers)).normalized() * 0.35).normalized()

				h.velocity = flee_dir * (h.move_speed * 1.35 * weather_speed_mult)
				_move_animal(h, delta, height_callable)

			elif alert_trigger:
				h.state = HerbivoreState.ALERT
				h.threat_memory = 1.0
				h.last_known_threat_pos = _player_pos
				h.vigilance_timer = 3.5
				_spread_herd_alarm(h, false)
				if to_player.length_squared() > 0.01:
					h.heading = atan2(to_player.z, to_player.x)
				h.velocity = Vector3.ZERO

			elif h.state == HerbivoreState.FLEEING and h.threat_id == -999:
				if p_dist >= 30.0 or (p_dist >= 14.0 and h.flee_timer <= 0.0):
					# Player retreated or flee timer expired: halt into alert vigilance facing last known threat
					h.state = HerbivoreState.ALERT
					h.threat_id = -1
					h.vigilance_timer = 2.5
					h.regroup_timer = 4.0
					h.velocity = Vector3.ZERO
					if to_player.length_squared() > 0.01:
						h.heading = atan2(to_player.z, to_player.x)
				else:
					# Continue active flight commitment away from threat
					var flee_dir: Vector3 = (h.position - _player_pos)
					flee_dir.y = 0.0
					if flee_dir.length_squared() < 0.01:
						flee_dir = Vector3(cos(h.heading), 0.0, sin(h.heading))
					else:
						flee_dir = flee_dir.normalized()

					var flight_sep: Vector3 = Vector3.ZERO
					var flight_align: Vector3 = Vector3.ZERO
					var flight_peers: int = 0
					for other in _herbivores.values():
						if other.id != h.id:
							var o_diff: Vector3 = h.position - other.position
							o_diff.y = 0.0
							var o_dist: float = o_diff.length()
							if o_dist < 3.0 and o_dist > 0.01:
								flight_sep += (o_diff / (o_dist * o_dist)) * 1.6
							if o_dist < 12.0 and other.state == HerbivoreState.FLEEING and other.velocity.length_squared() > 0.1:
								flight_align += other.velocity.normalized()
								flight_peers += 1
					if flight_sep.length_squared() > 0.01:
						flee_dir = (flee_dir * 1.0 + flight_sep.normalized() * 0.70).normalized()
					if flight_peers > 0:
						flee_dir = (flee_dir * 1.0 + (flight_align / float(flight_peers)).normalized() * 0.35).normalized()

					h.velocity = flee_dir * (h.move_speed * 1.35 * weather_speed_mult)
					_move_animal(h, delta, height_callable)

			elif h.state == HerbivoreState.FLEEING and h.flee_timer > 0.0:
				# Flight commitment from non-player threat (predator or herd alarm)
				var flee_dir: Vector3 = (h.position - h.last_known_threat_pos) if h.last_known_threat_pos != Vector3.ZERO else Vector3(cos(h.heading), 0.0, sin(h.heading))
				flee_dir.y = 0.0
				if flee_dir.length_squared() < 0.01:
					flee_dir = Vector3(cos(h.heading), 0.0, sin(h.heading))
				else:
					flee_dir = flee_dir.normalized()

				var flight_sep: Vector3 = Vector3.ZERO
				var flight_align: Vector3 = Vector3.ZERO
				var flight_peers: int = 0
				for other in _herbivores.values():
					if other.id != h.id:
						var o_diff: Vector3 = h.position - other.position
						o_diff.y = 0.0
						var o_dist: float = o_diff.length()
						if o_dist < 3.0 and o_dist > 0.01:
							flight_sep += (o_diff / (o_dist * o_dist)) * 1.6
						if o_dist < 12.0 and other.state == HerbivoreState.FLEEING and other.velocity.length_squared() > 0.1:
							flight_align += other.velocity.normalized()
							flight_peers += 1
				if flight_sep.length_squared() > 0.01:
					flee_dir = (flee_dir * 1.0 + flight_sep.normalized() * 0.70).normalized()
				if flight_peers > 0:
					flee_dir = (flee_dir * 1.0 + (flight_align / float(flight_peers)).normalized() * 0.40).normalized()

				h.velocity = flee_dir * (h.move_speed * 1.25 * weather_speed_mult)
				_move_animal(h, delta, height_callable)

			elif h.state == HerbivoreState.FLEEING:
				# Flee timer expired: halt into alert vigilance
				h.state = HerbivoreState.ALERT
				h.threat_id = -1
				h.vigilance_timer = 2.5
				h.regroup_timer = 4.0
				h.velocity = Vector3.ZERO

			elif h.state == HerbivoreState.ALERT:
				if p_dist > 16.0:
					# Hysteresis: Player walked beyond 16m. Vigilance timer counts down before returning to wandering
					if h.vigilance_timer <= 0.0:
						h.state = HerbivoreState.WANDERING
						h.velocity = Vector3.ZERO
					else:
						# Hold vigilant posture facing threat
						h.velocity = Vector3.ZERO
				else:
					# Player is within 16m: hold alert vigilance, look at player without flickering
					h.velocity = Vector3.ZERO
					if to_player.length_squared() > 0.01:
						h.heading = atan2(to_player.z, to_player.x)
			else:
				# Routine behaviors
				_process_herbivore_routine(h, delta, flora_sim, height_callable, weather_speed_mult, sim_hour, weather)

		else:
			# Player not present
			if h.state == HerbivoreState.FLEEING and h.threat_id == -999:
				h.state = HerbivoreState.WANDERING
				h.threat_id = -1
			elif h.state == HerbivoreState.FLEEING and h.flee_timer > 0.0:
				# Continue fleeing away from last known threat position with flocking
				var flee_dir: Vector3 = (h.position - h.last_known_threat_pos) if h.last_known_threat_pos != Vector3.ZERO else Vector3(cos(h.heading), 0.0, sin(h.heading))
				flee_dir.y = 0.0
				if flee_dir.length_squared() < 0.01:
					flee_dir = Vector3(cos(h.heading), 0.0, sin(h.heading))
				else:
					flee_dir = flee_dir.normalized()

				var flight_sep: Vector3 = Vector3.ZERO
				var flight_align: Vector3 = Vector3.ZERO
				var flight_peers: int = 0
				for other in _herbivores.values():
					if other.id != h.id:
						var o_diff: Vector3 = h.position - other.position
						o_diff.y = 0.0
						var o_dist: float = o_diff.length()
						if o_dist < 3.0 and o_dist > 0.01:
							flight_sep += (o_diff / (o_dist * o_dist)) * 1.6
						if o_dist < 12.0 and other.state == HerbivoreState.FLEEING and other.velocity.length_squared() > 0.1:
							flight_align += other.velocity.normalized()
							flight_peers += 1
				if flight_sep.length_squared() > 0.01:
					flee_dir = (flee_dir * 1.0 + flight_sep.normalized() * 0.70).normalized()
				if flight_peers > 0:
					flee_dir = (flee_dir * 1.0 + (flight_align / float(flight_peers)).normalized() * 0.40).normalized()

				h.velocity = flee_dir * (h.move_speed * 1.25 * weather_speed_mult)
				_move_animal(h, delta, height_callable)
			elif h.state == HerbivoreState.FLEEING:
				h.state = HerbivoreState.ALERT
				h.threat_id = -1
				h.vigilance_timer = 2.5
				h.regroup_timer = 4.0
				h.velocity = Vector3.ZERO
			elif h.state == HerbivoreState.ALERT and h.vigilance_timer <= 0.0:
				h.state = HerbivoreState.WANDERING
			else:
				_process_herbivore_routine(h, delta, flora_sim, height_callable, weather_speed_mult, sim_hour, weather)

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
			_entity_registry.update_property(id, "is_in_sanctuary", h.is_in_sanctuary)
			_entity_registry.update_property(id, "is_sleeping", h.is_sleeping)

	# =========================================================================
	# 2. PREDATORS SIMULATION
	# =========================================================================
	for pid: int in _predators.keys():
		var p: PredatorData = _predators[pid]
		p.age += delta
		if p.reproduce_cooldown > 0.0:
			p.reproduce_cooldown -= delta

		# Simulation LOD tier assignment (Block 27)
		var p_dist_player: float = p.position.distance_to(_player_pos) if _player_present else 999.0
		if p_dist_player < 35.0:
			p.sim_lod_tier = 0
		elif p_dist_player < 75.0:
			p.sim_lod_tier = 1
		else:
			p.sim_lod_tier = 2
		p.lod_step_counter += 1

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

		# Predator fatigue cooldown recovery
		if p.hunt_fatigue > 0.0:
			p.hunt_fatigue = maxf(0.0, p.hunt_fatigue - delta)

		# 1. Light & Fire Avoidance (Nyctophobia): Predators fear active torches and campfires
		var nearest_light_dist: float = 999.0
		var nearest_light_pos: Vector3 = Vector3.ZERO
		for l_pos in _active_light_sources:
			var d: float = p.position.distance_to(l_pos)
			if d < nearest_light_dist:
				nearest_light_dist = d
				nearest_light_pos = l_pos

		var is_repelled_by_fire: bool = nearest_light_dist < 12.0
		p.is_deterred_by_fire = is_repelled_by_fire

		if is_repelled_by_fire:
			var flee_dir: Vector3 = (p.position - nearest_light_pos)
			flee_dir.y = 0.0
			if flee_dir.length_squared() < 0.01:
				flee_dir = Vector3(cos(p.heading), 0.0, sin(p.heading))
			p.velocity = flee_dir.normalized() * (p.move_speed * 1.10 * weather_speed_mult)
			p.heading = atan2(p.velocity.z, p.velocity.x)
			if p.state == PredatorState.HUNTING:
				p.state = PredatorState.ALERT
				p.target_prey_id = -1
			_move_animal(p, delta, height_callable)
		elif _player_present and p_dist_player < 5.5 and p.energy < 40.0:
			# Starving/weak predator retreats from player presence
			var flee_dir: Vector3 = (p.position - _player_pos)
			flee_dir.y = 0.0
			p.velocity = flee_dir.normalized() * (p.move_speed * 1.15 * weather_speed_mult)
			_move_animal(p, delta, height_callable)
		elif _player_present and p_dist_player < 10.0 and p.state == PredatorState.WANDERING:
			p.state = PredatorState.ALERT
			var to_player: Vector3 = (_player_pos - p.position)
			to_player.y = 0.0
			if to_player.length_squared() > 0.01:
				p.heading = atan2(to_player.z, to_player.x)
			p.velocity = Vector3.ZERO
		elif p.state == PredatorState.DRINKING:
			p.eat_timer += delta
			p.velocity = Vector3.ZERO
			p.energy = minf(p_max_e, p.energy + 2.5 * delta)
			if p.eat_timer >= 2.5:
				p.state = PredatorState.WANDERING
				p.eat_timer = 0.0
		elif p.state == PredatorState.RESTING:
			p.state_timer += delta
			p.velocity = Vector3.ZERO
			# Exit resting when hunt fatigue has recovered (3.5-5.0s) or when hunger demands action
			var fatigue_cleared: bool = (p.hunt_fatigue <= 0.0)
			if fatigue_cleared and (p.state_timer >= 4.0 or p.energy < 55.0):
				p.state = PredatorState.WANDERING
				p.state_timer = 0.0
		elif p.state == PredatorState.EATING:
			p.eat_timer += delta
			p.velocity = Vector3.ZERO
			if p.eat_timer >= 3.0 or p.energy >= (p_max_e * 0.95):
				p.state = PredatorState.WANDERING
				p.eat_timer = 0.0
		elif p.energy < (p_max_e * 0.90) or _find_nearest_herbivore(p.position, 9.0) != null:
			# Hunt nearest herbivore with sense_range
			var hunt_radius: float = p.genome.sense_range if p.genome else 32.0
			var target_prey: HerbivoreData = _find_nearest_herbivore(p.position, hunt_radius)

			if p.hunt_fatigue > 0.0:
				# Recovering breath from exhausted chase
				p.state = PredatorState.RESTING
				p.velocity = Vector3.ZERO
			elif target_prey != null:
				p.state = PredatorState.HUNTING
				p.target_prey_id = target_prey.id
				p.hunt_duration += delta

				var to_prey: Vector3 = (target_prey.position - p.position)
				to_prey.y = 0.0
				var dist: float = to_prey.length()
				var strike_dist: float = p.genome.get_effective_strike_distance(2.0) if p.genome else 2.0

				# Hunt abort conditions: prey outran predator (>25m) or chase stamina exceeded
				if dist > 25.0 or (p.hunt_duration > p.hunt_stamina and dist > strike_dist * 2.0):
					# Abort hunt! Enter resting to catch breath
					p.state = PredatorState.RESTING
					p.hunt_fatigue = 3.5
					p.state_timer = 0.0
					p.hunt_duration = 0.0
					p.is_stalking = false
					p.stalks_abandoned += 1
					p.target_prey_id = -1
					p.velocity = Vector3.ZERO
					if _event_bus:
						_event_bus.publish("predator_hunt_aborted", {"id": pid, "reason": "outrun", "position": p.position})
				elif dist < strike_dist or dist <= (p.move_speed * delta):
					# Catch and kill prey! Strike success and yield depend on predation trait
					herbivore_deaths.append({"id": target_prey.id, "reason": "predation"})
					add_sector_disturbance(target_prey.position, 25.0)
					var kill_energy: float = p.genome.get_effective_kill_yield(55.0) if p.genome else 55.0
					p.energy = minf(p_max_e, p.energy + kill_energy)
					p.health = minf(p_max_hp, p.health + 15.0)
					p.state = PredatorState.EATING
					p.eat_timer = 0.0
					p.hunt_duration = 0.0
					p.is_stalking = false
					p.hunt_fatigue = 15.0 # Satiation digestion cooldown prevents repetitive slaughter
					p.velocity = Vector3.ZERO
				else:
					p.is_stalking = (dist > 8.0)
					var hunt_speed_mult: float = 1.25 if dist <= 8.0 else 0.75
					p.velocity = to_prey.normalized() * (p.move_speed * hunt_speed_mult * weather_speed_mult)
					_move_animal(p, delta, height_callable)
			else:
				# No prey found: wander
				p.state = PredatorState.WANDERING
				p.hunt_duration = 0.0
				p.is_stalking = false
				_wander_animal(p, delta, height_callable, weather_speed_mult, sim_hour)
		else:
			var is_shore: bool = (p.position.y <= 0.85 and p.position.y >= 0.18)
			var p_drink_chance: float = 0.25 if (sim_hour >= 16.0 and sim_hour <= 18.5) else 0.05
			if is_shore and _rng.randf() < p_drink_chance:
				p.state = PredatorState.DRINKING
				p.eat_timer = 0.0
				p.velocity = Vector3.ZERO
			else:
				p.state = PredatorState.WANDERING
				_wander_animal(p, delta, height_callable, weather_speed_mult, sim_hour)

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

	# Continuous soft relaxation pass to prevent any overlap across all animal states
	_apply_fauna_separation(delta, height_callable)

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

	last_simulation_step_time_ms = float(Time.get_ticks_usec() - step_start_usec) / 1000.0


func _process_herbivore_routine(h: HerbivoreData, delta: float, flora_sim: RefCounted, height_callable: Callable, weather_speed_mult: float, sim_hour: float, weather: RefCounted = null) -> void:
	# If vigilant from predator or herd alert, maintain alert posture and do not overwrite with routine
	if h.state == HerbivoreState.ALERT:
		if h.vigilance_timer > 0.0:
			h.velocity = Vector3.ZERO
			return
		else:
			h.state = HerbivoreState.WANDERING

	var max_e: float = h.genome.get_effective_max_energy() if h.genome else 100.0
	var max_hp: float = h.genome.get_effective_max_health() if h.genome else 100.0

	var is_near_shoreline: bool = (h.position.y <= 0.95 and Vector2(h.position.x - 16.0, h.position.z - 14.0).length() < 13.0)

	# 1. Thirst & Drinking at Emerald Basin Shoreline
	if (h.hydration < 45.0 or (sim_hour >= 15.0 and sim_hour <= 18.0 and h.hydration < 75.0)) and is_near_shoreline and h.state != HerbivoreState.EATING:
		h.state = HerbivoreState.DRINKING
		h.eat_timer = 0.0
		h.velocity = Vector3.ZERO

	if h.state == HerbivoreState.DRINKING:
		h.eat_timer += delta
		h.velocity = Vector3.ZERO
		h.hydration = minf(100.0, h.hydration + 25.0 * delta)
		h.energy = minf(max_e, h.energy + 3.0 * delta)
		h.health = minf(max_hp, h.health + 1.5 * delta)
		if h.eat_timer >= 3.0 or h.hydration >= 98.0:
			h.state = HerbivoreState.WANDERING
			h.eat_timer = 0.0
		return
	elif h.state == HerbivoreState.RESTING:
		h.state_timer += delta
		h.velocity = Vector3.ZERO
		var is_raining_now: bool = (weather != null and int(weather.get("current_state")) == 2)
		if h.is_in_sanctuary:
			if sim_hour >= 5.0 and sim_hour < 20.0:
				h.state = HerbivoreState.WANDERING
				h.is_in_sanctuary = false
				h.is_sleeping = false
				h.state_timer = 0.0
			elif h.energy < 25.0:
				h.state = HerbivoreState.FORAGING
				h.is_in_sanctuary = false
				h.is_sleeping = false
				h.state_timer = 0.0
			return
		# Sleep wake conditions: hungry (<40), rested enough (>25s), or daybreak (>= 5.5h) when not actively raining
		if h.energy < 40.0 or h.state_timer > 30.0 or (sim_hour >= 5.5 and sim_hour < 20.0 and not is_raining_now):
			h.state = HerbivoreState.WANDERING
			h.state_timer = 0.0
		return
	elif h.state == HerbivoreState.EATING:
		h.eat_timer += delta
		if flora_sim:
			var intake_rate: float = h.genome.get_effective_intake_rate(2.5) if h.genome else 2.5
			var eaten: float = flora_sim.consume_biomass(h.target_plant_id, intake_rate * delta)
			var nutrition: float = flora_sim.get_plant_nutrition(h.target_plant_id) if flora_sim.has_method("get_plant_nutrition") else 1.0
			var energy_gain: float = eaten * 12.0 * nutrition * (h.genome.energy_efficiency if h.genome else 1.0)
			h.energy = minf(max_e, h.energy + energy_gain)
			h.health = minf(max_hp, h.health + 2.0 * delta)

			# Stop eating if plant depleted or full
			if eaten <= 0.05 or h.energy >= (max_e * 0.95) or h.eat_timer > 4.0:
				h.state = HerbivoreState.WANDERING
				h.eat_timer = 0.0
				h.target_plant_id = -1
		h.velocity = Vector3.ZERO
		return

	# 2. Weather Rain Sheltering: Seek canopy shelter and bed down
	var is_raining: bool = (weather != null and int(weather.get("current_state")) == 2)
	if is_raining and h.energy >= 38.0:
		var in_canopy: bool = (h.position.x < 3.0 and h.position.x > -15.0 and h.position.z < 6.0 and h.position.z > -9.0)
		if in_canopy:
			h.state = HerbivoreState.RESTING
			h.is_sheltered = true
			h.state_timer = 0.0
			h.velocity = Vector3.ZERO
			return
		else:
			# Move toward Whispering Forest canopy center (-6.0, -1.5)
			var to_canopy: Vector3 = Vector3(-6.0, 0.0, -1.5) - h.position
			to_canopy.y = 0.0
			h.velocity = to_canopy.normalized() * (h.move_speed * 0.75 * weather_speed_mult)
			_move_animal(h, delta, height_callable)
			return

	# 3. Nighttime Circadian & Fire Sanctuary (20:00 - 05:00)
	var is_nighttime: bool = (sim_hour >= 20.0 or sim_hour < 5.0)
	if is_nighttime and not _active_light_sources.is_empty():
		var nearest_light: Vector3 = Vector3.ZERO
		var min_light_dist: float = 999.0
		for l_pos in _active_light_sources:
			var d_l: float = h.position.distance_to(l_pos)
			if d_l < min_light_dist:
				min_light_dist = d_l
				nearest_light = l_pos

		if min_light_dist <= 24.0:
			h.sanctuary_pos = nearest_light
			if min_light_dist > 8.5:
				h.is_in_sanctuary = false
				h.is_sleeping = false
				var to_fire: Vector3 = nearest_light - h.position
				to_fire.y = 0.0
				h.velocity = to_fire.normalized() * (h.move_speed * 0.70 * weather_speed_mult)
				_move_animal(h, delta, height_callable)
				return
			elif min_light_dist < 3.0:
				h.is_in_sanctuary = true
				var away_fire: Vector3 = h.position - nearest_light
				away_fire.y = 0.0
				if away_fire.length_squared() < 0.01:
					away_fire = Vector3(cos(h.heading), 0.0, sin(h.heading))
				h.velocity = away_fire.normalized() * (h.move_speed * 0.40 * weather_speed_mult)
				_move_animal(h, delta, height_callable)
				return
			else:
				h.is_in_sanctuary = true
				h.state = HerbivoreState.RESTING
				h.velocity = Vector3.ZERO
				h.is_sleeping = (sim_hour >= 0.0 and sim_hour <= 4.5)
				return
	elif not is_nighttime:
		h.is_in_sanctuary = false
		h.is_sleeping = false

	# 3b. Nighttime Circadian Canopy Fallback: Seek Whispering Forest canopy shelter
	if is_nighttime and h.energy >= 42.0:
		var in_night_canopy: bool = (h.position.x < 3.0 and h.position.x > -15.0 and h.position.z < 6.0 and h.position.z > -9.0)
		if in_night_canopy:
			h.state = HerbivoreState.RESTING
			h.is_sheltered = true
			h.state_timer = 0.0
			h.velocity = Vector3.ZERO
			return
		else:
			var to_bed: Vector3 = Vector3(-5.5, 0.0, -1.0) - h.position
			to_bed.y = 0.0
			h.velocity = to_bed.normalized() * (h.move_speed * 0.70 * weather_speed_mult)
			_move_animal(h, delta, height_callable)
			return
	elif h.energy < (max_e * 0.80):
		# Hungry: Seek food with sense_range
		h.state = HerbivoreState.FORAGING
		var food: Variant = null
		var forage_radius: float = h.genome.sense_range if h.genome else 28.0
		if flora_sim:
			var season: int = flora_sim.get_active_season() if flora_sim.has_method("get_active_season") else 0
			var pref_species: String = "shrub_bush" if (season == 0 or season == 1) else ""
			food = flora_sim.find_nearest_food(h.position, forage_radius, 0.8, pref_species)

		if food != null:
			h.target_plant_id = food.id
			var dist_to_plant: float = (food.position - h.position).length()
			var forage_slot: Vector3 = _get_forage_slot(food.position, h.id)
			var to_food: Vector3 = (forage_slot - h.position)
			to_food.y = 0.0
			var dist: float = to_food.length()
			if dist < 1.4 or dist_to_plant < 2.0:
				h.state = HerbivoreState.EATING
				h.eat_timer = 0.0
				h.velocity = Vector3.ZERO
				if flora_sim:
					var intake_rate: float = h.genome.get_effective_intake_rate(2.5) if h.genome else 2.5
					var eaten: float = flora_sim.consume_biomass(h.target_plant_id, intake_rate * delta)
					var nutrition: float = flora_sim.get_plant_nutrition(h.target_plant_id) if flora_sim.has_method("get_plant_nutrition") else 1.0
					var energy_gain: float = eaten * 12.0 * nutrition * (h.genome.energy_efficiency if h.genome else 1.0)
					h.energy = minf(max_e, h.energy + energy_gain)
					h.health = minf(max_hp, h.health + 2.0 * delta)
			else:
				h.velocity = to_food.normalized() * (h.move_speed * weather_speed_mult)
				_move_animal(h, delta, height_callable)
		else:
			# No food found: wander
			_wander_animal(h, delta, height_callable, weather_speed_mult, sim_hour)
	else:
		# Thirst migration: Steer toward distributed individual drinking slots at Emerald Basin Shoreline
		if (h.hydration < 50.0 or (sim_hour >= 15.0 and sim_hour <= 18.0 and h.hydration < 75.0)) and not is_near_shoreline:
			var target_water: Vector3 = _get_individual_shoreline_spot(h.id)
			var to_lake: Vector3 = target_water - h.position
			to_lake.y = 0.0
			h.velocity = to_lake.normalized() * (h.move_speed * 0.85 * weather_speed_mult)
			_move_animal(h, delta, height_callable)
		else:
			h.state = HerbivoreState.WANDERING
			_wander_animal(h, delta, height_callable, weather_speed_mult, sim_hour)

func _move_animal(animal: AnimalBase, delta: float, height_callable: Callable) -> void:
	# 1. Slope grade and cliff obstacle avoidance
	if height_callable.is_valid() and animal.velocity.length_squared() > 0.01:
		var move_dir: Vector3 = animal.velocity.normalized()
		var probe_dist: float = maxf(1.4, animal.velocity.length() * delta * 2.0)
		var probe_x: float = animal.position.x + move_dir.x * probe_dist
		var probe_z: float = animal.position.z + move_dir.z * probe_dist
		var current_y: float = height_callable.call(animal.position.x, animal.position.z)
		var y_probe: float = height_callable.call(probe_x, probe_z)
		var slope: float = (y_probe - current_y) / probe_dist

		# Check major rock obstacles: Eastern Granite Bluff core (23.0, 16.0)
		var to_bluff: Vector2 = Vector2(probe_x - 23.0, probe_z - 16.0)
		if to_bluff.length() < 7.2:
			var deflect_bluff: Vector3 = Vector3(to_bluff.x, 0.0, to_bluff.y).normalized()
			animal.velocity = (animal.velocity * 0.20 + deflect_bluff * animal.move_speed * 0.90).normalized() * animal.velocity.length()

		# Summit monolith core (-24.0, -24.0)
		var to_summit: Vector2 = Vector2(probe_x - (-24.0), probe_z - (-24.0))
		if to_summit.length() < 6.8:
			var deflect_summit: Vector3 = Vector3(to_summit.x, 0.0, to_summit.y).normalized()
			animal.velocity = (animal.velocity * 0.20 + deflect_summit * animal.move_speed * 0.90).normalized() * animal.velocity.length()

		# If steep obstacle ahead (slope > 0.55 or cliff wall)
		if slope > 0.55:
			var left_vec: Vector3 = Vector3(-move_dir.z, 0.0, move_dir.x)
			var right_vec: Vector3 = -left_vec
			var y_left: float = height_callable.call(animal.position.x + left_vec.x * 1.2, animal.position.z + left_vec.z * 1.2)
			var y_right: float = height_callable.call(animal.position.x + right_vec.x * 1.2, animal.position.z + right_vec.z * 1.2)
			var s_left: float = (y_left - current_y)
			var s_right: float = (y_right - current_y)

			if s_left < 0.45 and s_left <= s_right:
				animal.velocity = (move_dir * 0.15 + left_vec * 0.95).normalized() * animal.velocity.length()
			elif s_right < 0.45:
				animal.velocity = (move_dir * 0.15 + right_vec * 0.95).normalized() * animal.velocity.length()
			else:
				# Turn away from sheer cliff face downhill
				animal.velocity = -move_dir * (animal.velocity.length() * 0.6)

	var next_pos: Vector3 = animal.position + animal.velocity * delta

	# 2. Keep within island dry bounds
	var max_r: float = island_boundary_radius if island_boundary_radius > 0.0 else ISLAND_MAX_RADIUS
	if next_pos.length() > max_r:
		var to_center: Vector3 = -next_pos.normalized()
		animal.velocity = to_center * animal.move_speed
		next_pos = animal.position + animal.velocity * delta

	# 3. Elevation and water avoidance
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

func _wander_animal(animal: AnimalBase, delta: float, height_callable: Callable, speed_mult: float = 1.0, sim_hour: float = 12.0) -> void:
	var steer: Vector3 = Vector3(cos(animal.heading), 0.0, sin(animal.heading))

	if animal.type == "herbivore":
		var separation: Vector3 = Vector3.ZERO
		var cohesion_center: Vector3 = Vector3.ZERO
		var neighbor_count: int = 0

		for other in _herbivores.values():
			if other.id == animal.id:
				continue
			var offset: Vector3 = animal.position - other.position
			offset.y = 0.0
			var dist: float = offset.length()
			if dist < 0.001:
				continue
			if dist < 3.2:
				# Repel strongly if too close (avoid overlapping & personal space)
				separation += (offset / (dist * dist)) * 3.5
			elif dist < 14.0:
				# Cohesion: gather toward herd center of mass
				cohesion_center += other.position
				neighbor_count += 1

		if neighbor_count > 0:
			cohesion_center /= float(neighbor_count)
			var to_center: Vector3 = cohesion_center - animal.position
			to_center.y = 0.0
			var cohesion_weight: float = 0.45 if (animal is HerbivoreData and (animal as HerbivoreData).regroup_timer > 0.0) else 0.20
			steer += to_center.normalized() * cohesion_weight

		if separation.length_squared() > 0.001:
			steer += separation.normalized() * 1.50

		# Check nearby predators while wandering: steer away if predator is within 12m
		for p_stalk in _predators.values():
			var p_off: Vector3 = animal.position - p_stalk.position
			p_off.y = 0.0
			var p_d: float = p_off.length()
			if p_d < 12.0 and p_d > 0.01:
				steer += (p_off / p_d) * 2.5

		# Diurnal Attraction Niches:
		if sim_hour >= 20.5 or sim_hour < 5.0:
			# Nighttime: steer toward Whispering Forest canopy for shelter
			var to_forest: Vector3 = Vector3(-6.0, 0.0, -2.0) - Vector3(animal.position.x, 0.0, animal.position.z)
			steer += to_forest.normalized() * 0.35
		elif sim_hour >= 16.0 and sim_hour <= 18.5:
			# Golden Hour / Dusk: steer toward Emerald Basin Cove & Creek Delta for watering
			var to_basin: Vector3 = Vector3(16.0, 0.0, 13.0) - Vector3(animal.position.x, 0.0, animal.position.z)
			steer += to_basin.normalized() * 0.38
		else:
			# Daytime: gentle pull toward Sunlit Meadow Glade (grazing)
			var to_glade: Vector3 = Vector3(8.5, 0.0, 3.5) - Vector3(animal.position.x, 0.0, animal.position.z)
			steer += to_glade.normalized() * 0.25

		# Sector Disturbance Relocation Steering (Block 27):
		var curr_sec: int = get_sector_index(animal.position)
		if sector_disturbances[curr_sec] > 15.0:
			var quiet_sec: int = get_lowest_disturbance_sector()
			if quiet_sec != curr_sec:
				var to_quiet: Vector3 = (get_sector_center(quiet_sec) - animal.position)
				to_quiet.y = 0.0
				steer += to_quiet.normalized() * 0.40


	elif animal.type == "predator":
		# Predators maintain stalking distance from other predators
		var p_sep: Vector3 = Vector3.ZERO
		for other_p in _predators.values():
			if other_p.id == animal.id:
				continue
			var p_offset: Vector3 = animal.position - other_p.position
			p_offset.y = 0.0
			var p_dist: float = p_offset.length()
			if p_dist < 8.0 and p_dist > 0.001:
				p_sep += (p_offset / p_dist) * 1.5
		if p_sep.length_squared() > 0.001:
			steer += p_sep.normalized() * 0.8

		# Predators patrol high ridge / forest edge during day, descend near basin at dusk
		if sim_hour >= 16.0 and sim_hour <= 19.0:
			var to_ambush: Vector3 = Vector3(10.0, 0.0, 10.0) - Vector3(animal.position.x, 0.0, animal.position.z)
			steer += to_ambush.normalized() * 0.30

	# Terrain obstacle / steep cliff and water edge avoidance
	if height_callable.is_valid():
		var ahead: Vector3 = animal.position + Vector3(cos(animal.heading), 0.0, sin(animal.heading)) * 1.4
		var y_ahead: float = height_callable.call(ahead.x, ahead.z)
		var slope_diff: float = y_ahead - animal.position.y
		if slope_diff > 1.1:
			var side_steer: Vector3 = Vector3(-sin(animal.heading), 0.0, cos(animal.heading))
			steer += side_steer * 1.6
		elif y_ahead < 0.24:
			var to_center: Vector3 = -animal.position.normalized()
			steer += to_center * 1.8

	# Desynchronized individual wander heading updates
	animal.wander_timer += delta
	var random_turn: float = 0.0
	if animal.wander_timer >= animal.wander_interval:
		animal.wander_timer = 0.0
		animal.wander_interval = _rng.randf_range(1.6, 3.4)
		random_turn = _rng.randf_range(-0.40, 0.40)

	var base_heading: float = atan2(steer.z, steer.x) if steer.length_squared() > 0.01 else animal.heading
	animal.heading = lerp_angle(animal.heading, base_heading + random_turn, 0.25)

	var wander_speed: float = animal.move_speed * 0.48 * speed_mult
	animal.velocity = Vector3(cos(animal.heading), 0.0, sin(animal.heading)) * wander_speed
	_move_animal(animal, delta, height_callable)

func _get_individual_shoreline_spot(animal_id: int) -> Vector3:
	# Distribute drinking positions organically along accessible northern/western lake shoreline
	var angle: float = deg_to_rad(115.0 + fmod(float(animal_id * 37 + 11), 150.0))
	var radius: float = 10.2 + fmod(float(animal_id * 17 + 5), 3.4)
	var dx: float = cos(angle) * radius
	var dz: float = sin(angle) * radius * 0.72
	return Vector3(16.0 + dx, 0.28, 14.0 + dz)

func _get_forage_slot(plant_pos: Vector3, herb_id: int) -> Vector3:
	# Distributed foraging ring: 2.2m to 2.8m spacing to prevent clipping into shrubs or other foragers
	var slot_dist: float = 2.3 + fmod(float(herb_id * 17), 0.5)
	var slot_angle: float = float(herb_id % 8) * (TAU / 8.0) + float((herb_id * 31) % 10) * 0.05
	return plant_pos + Vector3(cos(slot_angle), 0.0, sin(slot_angle)) * slot_dist

func _get_safe_radius(a1: AnimalBase, a2: AnimalBase) -> float:
	var is_stag1: bool = (a1.type == "herbivore" and (a1.id % 2 == 0))
	var is_stag2: bool = (a2.type == "herbivore" and (a2.id % 2 == 0))
	var r1: float = 1.6 if is_stag1 else (1.3 if a1.type == "herbivore" else 1.4)
	var r2: float = 1.6 if is_stag2 else (1.3 if a2.type == "herbivore" else 1.4)

	if a1.genome:
		r1 *= a1.genome.size_scale
	if a2.genome:
		r2 *= a2.genome.size_scale

	# Herbivore vs predator distance is substantially larger unless actively striking
	if a1.type != a2.type:
		return (r1 + r2) * 1.35 # ~4.0m
	return r1 + r2 # 3.2m for stag-stag, 2.9m stag-doe, 2.6m doe-doe, 2.8m wolf-wolf

func _apply_fauna_separation(delta: float, height_callable: Callable) -> void:
	var all_animals: Array = []
	all_animals.append_array(_herbivores.values())
	all_animals.append_array(_predators.values())
	var n: int = all_animals.size()
	if n <= 1:
		return

	var modified: Dictionary = {}
	# Soft inter-animal relaxation pass across all states (grazing, drinking, resting, wandering)
	for i: int in range(n):
		var a1: AnimalBase = all_animals[i]
		for j: int in range(i + 1, n):
			var a2: AnimalBase = all_animals[j]

			var diff_x: float = a1.position.x - a2.position.x
			var diff_z: float = a1.position.z - a2.position.z
			var d_sq: float = diff_x * diff_x + diff_z * diff_z
			# Fast broadphase: maximum possible safe radius squared is < 45.0m^2
			if d_sq > 45.0:
				continue

			var r_safe: float = _get_safe_radius(a1, a2)
			if d_sq >= (r_safe * r_safe):
				continue

			var dist: float = sqrt(d_sq)

			# Allow close contact if a predator is actively in strike range of its target prey
			if (a1 is PredatorData and (a1 as PredatorData).state == PredatorState.HUNTING and (a1 as PredatorData).target_prey_id == a2.id) or \
			   (a2 is PredatorData and (a2 as PredatorData).state == PredatorState.HUNTING and (a2 as PredatorData).target_prey_id == a1.id):
				continue

			if dist < r_safe:
				var pen: float = r_safe - dist
				if pen < 0.005:
					continue
				# Smooth quadratic falloff so gentle touches exert soft pushes, while tight overlaps push firmly without jitter
				var norm_pen: float = clampf(pen / r_safe, 0.0, 1.0)
				var push_mag: float = minf(pen * (0.35 + 0.55 * norm_pen), 5.5 * delta)
				var push_dir: Vector3
				if dist > 0.02:
					push_dir = Vector3(diff_x / dist, 0.0, diff_z / dist)
				else:
					var angle: float = float((a1.id * 73 + a2.id * 37) % 360) * (PI / 180.0)
					push_dir = Vector3(cos(angle), 0.0, sin(angle))

				# Mass/size-aware push distribution
				var m1: float = 1.25 if (a1.type == "herbivore" and (a1.id % 2 == 0)) else 1.0
				var m2: float = 1.25 if (a2.type == "herbivore" and (a2.id % 2 == 0)) else 1.0
				var total_m: float = m1 + m2
				var ratio1: float = m2 / total_m
				var ratio2: float = m1 / total_m

				a1.position += push_dir * (push_mag * ratio1)
				a2.position -= push_dir * (push_mag * ratio2)
				modified[a1.id] = a1
				modified[a2.id] = a2

	if not modified.is_empty() and height_callable.is_valid():
		for a: AnimalBase in modified.values():
			a.position.y = height_callable.call(a.position.x, a.position.z)

func _find_nearest_predator(pos: Vector3, max_dist: float) -> PredatorData:
	var best_dist_sq: float = max_dist * max_dist
	var nearest: PredatorData = null
	for p: PredatorData in _predators.values():
		var d_sq: float = pos.distance_squared_to(p.position)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			nearest = p
	return nearest

func _spread_herd_alarm(source_deer: HerbivoreData, is_panic: bool) -> void:
	add_sector_disturbance(source_deer.position, 15.0 if is_panic else 5.0)

	if is_panic:
		if source_deer.panic_alarm_cooldown > 0.0:
			return
		source_deer.panic_alarm_cooldown = 3.0
		source_deer.alarm_cooldown = 4.0
	else:
		if source_deer.alarm_cooldown > 0.0:
			return
		source_deer.alarm_cooldown = 4.0

	for other in _herbivores.values():
		if other.id == source_deer.id:
			continue
		if is_panic:
			if other.panic_alarm_cooldown > 0.0:
				continue
		else:
			if other.alarm_cooldown > 0.0:
				continue

		var d: float = other.position.distance_to(source_deer.position)
		if d < 12.0:
			other.alarm_cooldown = 3.5
			if is_panic:
				other.panic_alarm_cooldown = 2.5
			other.threat_memory = 1.0
			other.last_known_threat_pos = source_deer.last_known_threat_pos
			if is_panic and other.state != HerbivoreState.FLEEING:
				# Distance-proportional reaction latency (Block 27)
				var latency: float = 0.08 + (d / 12.0) * 0.24
				other.reaction_latency = latency
				other.pending_panic_alarm = true
				other.threat_id = source_deer.threat_id
				other.state = HerbivoreState.FLEEING
				other.velocity = source_deer.velocity
				other.heading = source_deer.heading
				other.flee_timer = 2.8
			elif not is_panic and (other.state == HerbivoreState.WANDERING or other.state == HerbivoreState.FORAGING):
				other.state = HerbivoreState.ALERT
				other.heading = source_deer.heading
				other.vigilance_timer = 3.5
				other.velocity = Vector3.ZERO
	if _event_bus:
		_event_bus.publish("herd_alarm", {"source_id": source_deer.id, "panic": is_panic, "position": source_deer.position})

func _find_nearest_herbivore(pos: Vector3, max_dist: float) -> HerbivoreData:
	var best_dist_sq: float = max_dist * max_dist
	var nearest: HerbivoreData = null
	for h: HerbivoreData in _herbivores.values():
		if h.is_in_sanctuary:
			continue
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
