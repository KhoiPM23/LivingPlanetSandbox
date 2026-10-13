class_name EcosystemMetrics
extends RefCounted

## Observability and metrics tracker for Living Planet Sandbox causal ecosystem.
## Collects authentic state metrics (biomass, populations, births, deaths, food availability).

var plant_count: int = 0
var herbivore_count: int = 0
var predator_count: int = 0

var total_biomass: float = 0.0 # Total plant biomass (biomass units)
var average_plant_health: float = 0.0 # 0.0 - 100.0%
var average_plant_moisture: float = 0.0 # 0.0 - 1.0

var average_herbivore_energy: float = 0.0 # 0.0 - 100.0%
var average_herbivore_health: float = 0.0 # 0.0 - 100.0%
var average_predator_energy: float = 0.0 # 0.0 - 100.0%

# Genetic & Evolutionary Telemetry
var avg_herbivore_speed: float = 1.0
var avg_herbivore_size: float = 1.0
var avg_plant_drought_tolerance: float = 0.20
var max_generation: int = 1
var genetic_diversity_index: float = 1.0
var allele_speed_variance: float = 0.0
var allele_drought_variance: float = 0.0
var bottleneck_warning: bool = false

var food_availability_ratio: float = 1.0 # Available biomass / herd demand

# Cumulative event counters
var births_total: int = 0
var births_by_type: Dictionary = {"plant": 0, "herbivore": 0, "predator": 0}

var deaths_total: int = 0
var deaths_by_cause: Dictionary = {
	"plant_decay": 0,
	"plant_drought": 0,
	"herbivore_starvation": 0,
	"herbivore_predation": 0,
	"herbivore_old_age": 0,
	"predator_starvation": 0,
	"predator_old_age": 0
}

# Performance telemetry
var last_sim_step_duration_ms: float = 0.0

# Telemetry history buffer (up to 40 samples for real-time HUD charts)
var history: Array[Dictionary] = []
var evolution_history: Array[Dictionary] = []
const MAX_HISTORY_SAMPLES: int = 40
const MAX_EVOLUTION_SAMPLES: int = 50

func sample_history() -> void:
	history.append({
		"biomass": total_biomass,
		"herbivores": herbivore_count,
		"predators": predator_count,
		"plants": plant_count,
		"avg_speed": avg_herbivore_speed,
		"avg_size": avg_herbivore_size,
		"drought_tol": avg_plant_drought_tolerance,
		"max_gen": max_generation,
		"diversity": genetic_diversity_index,
		"bottleneck": bottleneck_warning
	})
	if history.size() > MAX_HISTORY_SAMPLES:
		history.pop_front()

func sample_evolution_snapshot(sim_time: float) -> void:
	evolution_history.append({
		"sim_time": sim_time,
		"max_gen": max_generation,
		"avg_speed": avg_herbivore_speed,
		"speed_var": allele_speed_variance,
		"avg_drought_tol": avg_plant_drought_tolerance,
		"drought_var": allele_drought_variance,
		"diversity": genetic_diversity_index,
		"bottleneck": bottleneck_warning,
		"herbivore_count": herbivore_count,
		"plant_count": plant_count
	})
	if evolution_history.size() > MAX_EVOLUTION_SAMPLES:
		evolution_history.pop_front()

func record_birth(entity_type: String) -> void:
	births_total += 1
	if births_by_type.has(entity_type):
		births_by_type[entity_type] += 1
	else:
		births_by_type[entity_type] = 1

func record_death(entity_type: String, cause: String) -> void:
	deaths_total += 1
	var key: String = "%s_%s" % [entity_type, cause]
	if deaths_by_cause.has(key):
		deaths_by_cause[key] += 1
	else:
		deaths_by_cause[key] = 1

func reset() -> void:
	history.clear()
	evolution_history.clear()
	plant_count = 0
	herbivore_count = 0
	predator_count = 0
	total_biomass = 0.0
	average_plant_health = 0.0
	average_plant_moisture = 0.0
	average_herbivore_energy = 0.0
	average_herbivore_health = 0.0
	average_predator_energy = 0.0
	avg_herbivore_speed = 1.0
	avg_herbivore_size = 1.0
	avg_plant_drought_tolerance = 0.20
	max_generation = 1
	genetic_diversity_index = 1.0
	allele_speed_variance = 0.0
	allele_drought_variance = 0.0
	bottleneck_warning = false
	food_availability_ratio = 1.0
	births_total = 0
	births_by_type = {"plant": 0, "herbivore": 0, "predator": 0}
	deaths_total = 0
	deaths_by_cause = {
		"plant_decay": 0,
		"plant_drought": 0,
		"herbivore_starvation": 0,
		"herbivore_predation": 0,
		"herbivore_old_age": 0,
		"predator_starvation": 0,
		"predator_old_age": 0
	}
	last_sim_step_duration_ms = 0.0

func to_dict() -> Dictionary:
	return {
		"plant_count": plant_count,
		"herbivore_count": herbivore_count,
		"predator_count": predator_count,
		"total_biomass": snapped(total_biomass, 0.1),
		"average_plant_health": snapped(average_plant_health, 0.1),
		"average_herbivore_energy": snapped(average_herbivore_energy, 0.1),
		"average_herbivore_health": snapped(average_herbivore_health, 0.1),
		"average_predator_energy": snapped(average_predator_energy, 0.1),
		"avg_herbivore_speed": snapped(avg_herbivore_speed, 0.01),
		"avg_herbivore_size": snapped(avg_herbivore_size, 0.01),
		"avg_plant_drought_tolerance": snapped(avg_plant_drought_tolerance, 0.01),
		"max_generation": max_generation,
		"diversity_index": snapped(genetic_diversity_index, 0.01),
		"speed_variance": snapped(allele_speed_variance, 0.001),
		"drought_variance": snapped(allele_drought_variance, 0.001),
		"bottleneck_warning": bottleneck_warning,
		"food_availability_ratio": snapped(food_availability_ratio, 0.01),
		"births_total": births_total,
		"births_by_type": births_by_type.duplicate(),
		"deaths_total": deaths_total,
		"deaths_by_cause": deaths_by_cause.duplicate(),
		"sim_step_ms": snapped(last_sim_step_duration_ms, 0.01)
	}
