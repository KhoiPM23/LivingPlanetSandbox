class_name FloraSimulation
extends RefCounted

## Manages plant species, life cycle, growth stages, biomass, and environmental causal interactions.
## Driven by moisture, temperature, and sun exposure from EnvironmentalGrid.

const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")

enum GrowthStage {
	SEED = 0,
	SPROUT = 1,
	GROWING = 2,
	MATURE = 3,
	DECAYING = 4,
	DEAD = 5
}

class PlantData:
	var id: int
	var species: String # "grass_patch" or "shrub_bush"
	var position: Vector3
	var stage: GrowthStage = GrowthStage.SPROUT
	var biomass: float = 2.0 # Current edible biomass (kg/units)
	var max_biomass: float = 10.0
	var health: float = 100.0 # 0.0 - 100.0%
	var age: float = 0.0
	var max_age: float = 180.0 # Lifespan seconds
	var min_moisture: float = 0.25 # Minimum moisture before drought stress
	var optimal_temp_min: float = 8.0 # °C
	var optimal_temp_max: float = 32.0 # °C
	var base_growth_rate: float = 0.4 # Biomass gained per second in ideal conditions
	var spread_cooldown: float = 15.0 # Seconds between reproduction attempts
	
	func _init(p_id: int, p_species: String, p_pos: Vector3, p_max_biomass: float = 10.0) -> void:
		id = p_id
		species = p_species
		position = p_pos
		max_biomass = p_max_biomass
		biomass = max_biomass * 0.35 # Start as young growing plant
		health = 100.0
		age = 0.0
		if species == "shrub_bush":
			max_biomass = 25.0
			base_growth_rate = 0.25
			min_moisture = 0.30
			max_age = 300.0
			spread_cooldown = 25.0
		else:
			max_biomass = 10.0
			base_growth_rate = 0.5
			min_moisture = 0.20
			max_age = 180.0
			spread_cooldown = 15.0

var _plants: Dictionary = {} # int id -> PlantData
var _next_id: int = 2000
var _rng: RandomNumberGenerator

var _entity_registry: EntityRegistry
var _metrics: EcosystemMetrics
var _event_bus: WorldEventBus

# Spatial hash grid (cell_size = 10m) for fast neighbor queries
var _spatial_grid: Dictionary = {} # Vector2i (cx, cz) -> Array[int]
const GRID_CELL_SIZE: float = 10.0

func _init(rng: RandomNumberGenerator, registry: EntityRegistry, metrics: EcosystemMetrics, bus: WorldEventBus = null) -> void:
	_rng = rng if rng != null else RandomNumberGenerator.new()
	_entity_registry = registry
	_metrics = metrics
	_event_bus = bus

func spawn_plant(species: String, pos: Vector3, initial_biomass: float = -1.0) -> int:
	var id: int = _next_id
	_next_id += 1
	
	var plant: PlantData = PlantData.new(id, species, pos)
	if initial_biomass >= 0.0:
		plant.biomass = clampf(initial_biomass, 0.1, plant.max_biomass)
	_plants[id] = plant
	
	_add_to_spatial_grid(id, pos)
	
	# Register data entity in EntityRegistry
	if _entity_registry:
		_entity_registry.spawn_entity("plant", pos, {
			"species": species,
			"biomass": plant.biomass,
			"max_biomass": plant.max_biomass,
			"stage": plant.stage,
			"health": plant.health
		}, id)
		
	if _metrics:
		_metrics.record_birth("plant")
		
	if _event_bus:
		_event_bus.publish("plant_spawned", {"id": id, "species": species, "position": pos})
		
	return id

func remove_plant(id: int, reason: String = "decay") -> void:
	if not _plants.has(id):
		return
	var plant: PlantData = _plants[id]
	_remove_from_spatial_grid(id, plant.position)
	_plants.erase(id)
	
	if _entity_registry:
		_entity_registry.despawn_entity(id, reason)
		
	if _metrics:
		_metrics.record_death("plant", reason)
		
	if _event_bus:
		_event_bus.publish("plant_died", {"id": id, "reason": reason})

func get_plant(id: int) -> PlantData:
	return _plants.get(id, null)

func get_plant_count() -> int:
	return _plants.size()

func get_all_plants() -> Array:
	return _plants.values()

## Finds closest plant with sufficient biomass within radius
func find_nearest_food(pos: Vector3, search_radius: float, min_biomass: float = 1.0) -> PlantData:
	var min_dist_sq: float = search_radius * search_radius
	var best_plant: PlantData = null
	
	var min_cx: int = int(floor((pos.x - search_radius) / GRID_CELL_SIZE))
	var max_cx: int = int(floor((pos.x + search_radius) / GRID_CELL_SIZE))
	var min_cz: int = int(floor((pos.z - search_radius) / GRID_CELL_SIZE))
	var max_cz: int = int(floor((pos.z + search_radius) / GRID_CELL_SIZE))
	
	for cx: int in range(min_cx, max_cx + 1):
		for cz: int in range(min_cz, max_cz + 1):
			var cell_key: Vector2i = Vector2i(cx, cz)
			if not _spatial_grid.has(cell_key):
				continue
			var cell_ids: Array = _spatial_grid[cell_key]
			for pid: int in cell_ids:
				var p: PlantData = _plants.get(pid, null)
				if p and p.biomass >= min_biomass and p.stage != GrowthStage.DEAD:
					var dist_sq: float = pos.distance_squared_to(p.position)
					if dist_sq < min_dist_sq:
						min_dist_sq = dist_sq
						best_plant = p
						
	return best_plant

## Consumes biomass from a plant. Returns actual amount consumed.
func consume_biomass(plant_id: int, request_amount: float) -> float:
	if not _plants.has(plant_id):
		return 0.0
	var p: PlantData = _plants[plant_id]
	var eaten: float = minf(p.biomass, request_amount)
	p.biomass = maxf(0.0, p.biomass - eaten)
	
	# Update stage if overgrazed
	if p.biomass < 0.5 and p.stage == GrowthStage.MATURE:
		p.stage = GrowthStage.SPROUT
		
	if _entity_registry:
		_entity_registry.update_property(plant_id, "biomass", p.biomass)
		_entity_registry.update_property(plant_id, "stage", p.stage)
		
	return eaten

## Simulates plant growth, weather impact, reproduction and death
func step_simulation(delta: float, env_grid: EnvironmentalGrid) -> void:
	if env_grid == null:
		return
		
	var ids_to_remove: Array[Dictionary] = []
	var new_sprouts: Array[Dictionary] = []
	
	var total_biomass: float = 0.0
	var total_health: float = 0.0
	var total_moisture_sum: float = 0.0
	
	for id: int in _plants.keys():
		var p: PlantData = _plants[id]
		p.age += delta
		if p.spread_cooldown > 0.0:
			p.spread_cooldown -= delta
			
		var env: Dictionary = env_grid.sample_at(p.position.x, p.position.z)
		var temp: float = env.get("temperature", 20.0)
		var moisture: float = env.get("moisture", 0.6)
		var sun: float = env.get("sun_exposure", 0.8)
		
		total_moisture_sum += moisture
		
		# 1. Environmental Causal Impact
		if moisture >= p.min_moisture:
			# Sufficient moisture: Growth favored by warmth and sunlight
			var moisture_mult: float = clampf(moisture / 0.6, 0.4, 1.8)
			var sun_mult: float = clampf(sun / 0.7, 0.2, 1.4)
			var temp_mult: float = 0.2
			if temp >= p.optimal_temp_min and temp <= p.optimal_temp_max:
				temp_mult = 1.0 - (absf(temp - 20.0) / 25.0) # Peak around 20°C
			elif temp < 0.0:
				temp_mult = 0.0 # Dormant in freeze
				
			var growth: float = p.base_growth_rate * moisture_mult * sun_mult * temp_mult * delta
			p.biomass = minf(p.max_biomass, p.biomass + growth)
			p.health = minf(100.0, p.health + 2.5 * delta)
		else:
			# DROUGHT STRESS: Moisture deficit leads to biomass loss and health decay
			var deficit: float = (p.min_moisture - moisture) / maxf(p.min_moisture, 0.01)
			var drought_decay: float = 12.0 * deficit * delta
			var biomass_loss: float = 0.6 * deficit * delta
			p.health = maxf(0.0, p.health - drought_decay)
			p.biomass = maxf(0.0, p.biomass - biomass_loss)
			
		# Old age decay
		if p.age > p.max_age:
			p.health = maxf(0.0, p.health - 6.0 * delta)
			
		# Update Growth Stage
		if p.health <= 0.0:
			p.stage = GrowthStage.DEAD
			var cause: String = "drought" if moisture < p.min_moisture else "decay"
			ids_to_remove.append({"id": id, "reason": cause})
			continue
		elif p.health < 35.0 or p.age > p.max_age * 0.85:
			p.stage = GrowthStage.DECAYING
		elif p.biomass >= p.max_biomass * 0.70:
			p.stage = GrowthStage.MATURE
		elif p.biomass >= 2.0:
			p.stage = GrowthStage.GROWING
		elif p.biomass >= 0.5:
			p.stage = GrowthStage.SPROUT
		else:
			p.stage = GrowthStage.SEED
			
		# 2. Reproduction / Spreading (Only mature, healthy plants in good soil)
		if p.stage == GrowthStage.MATURE and p.health >= 70.0 and p.spread_cooldown <= 0.0 and _plants.size() < 180:
			var spread_angle: float = _rng.randf() * TAU
			var spread_dist: float = _rng.randf_range(3.0, 7.5)
			var target_pos: Vector3 = p.position + Vector3(cos(spread_angle) * spread_dist, 0.0, sin(spread_angle) * spread_dist)
			
			# Check target boundary within island (radius 70m)
			if target_pos.length() < 70.0:
				var target_env: Dictionary = env_grid.sample_at(target_pos.x, target_pos.z)
				if target_env.get("elevation", 1.0) > 0.4 and target_env.get("moisture", 0.0) >= p.min_moisture:
					new_sprouts.append({
						"species": p.species,
						"pos": target_pos,
						"biomass": 0.8
					})
					p.spread_cooldown = _rng.randf_range(20.0, 40.0)
					
		total_biomass += p.biomass
		total_health += p.health
		
		# Sync data to entity registry
		if _entity_registry:
			_entity_registry.update_property(id, "biomass", p.biomass)
			_entity_registry.update_property(id, "health", p.health)
			_entity_registry.update_property(id, "stage", p.stage)
			
	# Remove dead plants
	for dead: Dictionary in ids_to_remove:
		remove_plant(dead["id"], dead["reason"])
		
	# Spawn new offspring
	for s: Dictionary in new_sprouts:
		spawn_plant(s["species"], s["pos"], s["biomass"])
		
	# Update aggregate metrics
	if _metrics:
		var count: int = _plants.size()
		_metrics.plant_count = count
		_metrics.total_biomass = total_biomass
		_metrics.average_plant_health = (total_health / float(count)) if count > 0 else 0.0
		_metrics.average_plant_moisture = (total_moisture_sum / float(count)) if count > 0 else 0.0

func _add_to_spatial_grid(id: int, pos: Vector3) -> void:
	var cell_key: Vector2i = Vector2i(int(floor(pos.x / GRID_CELL_SIZE)), int(floor(pos.z / GRID_CELL_SIZE)))
	if not _spatial_grid.has(cell_key):
		_spatial_grid[cell_key] = []
	_spatial_grid[cell_key].append(id)

func _remove_from_spatial_grid(id: int, pos: Vector3) -> void:
	var cell_key: Vector2i = Vector2i(int(floor(pos.x / GRID_CELL_SIZE)), int(floor(pos.z / GRID_CELL_SIZE)))
	if _spatial_grid.has(cell_key):
		_spatial_grid[cell_key].erase(id)
		if _spatial_grid[cell_key].is_empty():
			_spatial_grid.erase(cell_key)

func restore_plant(data: Dictionary) -> int:
	var id: int = int(data.get("id", _next_id))
	_next_id = maxi(_next_id, id + 1)
	var species: String = data.get("species", "grass_patch")
	var pos: Vector3 = data.get("position", Vector3.ZERO)
	var max_bio: float = float(data.get("max_biomass", 10.0))
	var plant: PlantData = PlantData.new(id, species, pos, max_bio)
	plant.biomass = float(data.get("biomass", plant.biomass))
	plant.health = float(data.get("health", 100.0))
	plant.age = float(data.get("age", 0.0))
	plant.stage = data.get("stage", GrowthStage.MATURE) as GrowthStage
	_plants[id] = plant
	_add_to_spatial_grid(id, pos)
	if _entity_registry:
		_entity_registry.spawn_entity("plant", pos, {
			"species": species,
			"biomass": plant.biomass,
			"max_biomass": plant.max_biomass,
			"stage": plant.stage,
			"health": plant.health
		}, id)
	return id

func clear() -> void:
	if _entity_registry:
		for id: int in _plants.keys():
			_entity_registry.despawn_entity(id, "clear")
	_plants.clear()
	_spatial_grid.clear()
	_next_id = 2000



