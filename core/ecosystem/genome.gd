class_name EcosystemGenome
extends RefCounted

## Decoupled genetic representation for living entities (Fauna & Flora).
## Supports 5 heritable traits, phenotypic variation, controlled mutations,
## trade-off calculations, two-parent sexual recombination, and generation lineage tracking.
## References causal ecology principles from judeudumullage/Genesis (MIT License).

enum GenomeType {
	FAUNA = 0,
	FLORA = 1
}

# --- METADATA & LINEAGE ---
var genome_type: GenomeType = GenomeType.FAUNA
var species: String = "island_deer"
var generation: int = 1
var parent_id: int = -1
var parent_b_id: int = -1 # Secondary parent for two-parent sexual recombination

# --- 5 FAUNA HERITABLE TRAITS (Alleles & Phenotypes) ---

## 1. Size (0.60 to 1.50): Body mass. Increases max energy/health, but raises basal metabolic drain allometrically.
var size: float = 1.0:
	set(v):
		size = clampf(v, 0.60, 1.50)
var size_scale: float:
	get:
		return size
	set(v):
		size = v

## 2. Speed (0.60 to 1.50): Locomotor agility. Increases top speed and flee sprint, but increases metabolic burn quadratically.
var speed: float = 1.0:
	set(v):
		speed = clampf(v, 0.60, 1.50)
var speed_mult: float:
	get:
		return speed
	set(v):
		speed = v

## 3. Sense Range (14.0 to 48.0m): Perception radius. Broadens threat detection and food foraging radius; adds slight neural metabolic overhead.
var sense_range: float = 28.0:
	set(v):
		sense_range = clampf(v, 14.0, 48.0)
var perception_radius: float:
	get:
		return sense_range
	set(v):
		sense_range = v

## 4. Energy Efficiency (0.65 to 1.45): Basal metabolic efficiency. Higher efficiency reduces hunger drain and shortens reproduction cooldowns.
var energy_efficiency: float = 1.0:
	set(v):
		energy_efficiency = clampf(v, 0.65, 1.45)
var metabolism_efficiency: float:
	get:
		return energy_efficiency
	set(v):
		energy_efficiency = v

## 5A. Predation (0.60 to 1.50 for carnivores, 0.0 for herbivores): Attack prowess, strike distance, and energy harvest efficiency.
var predation: float = 0.0:
	set(v):
		predation = clampf(v, 0.0, 1.50)

## 5B. Foraging (0.60 to 1.50 for herbivores, 0.0 for carnivores): Biological counterpart to predation. Grazing rate and digestion yield.
var foraging: float = 0.0:
	set(v):
		foraging = clampf(v, 0.0, 1.50)

var coat_tint: Color = Color(0.72, 0.55, 0.38) # Visual phenotype coat coloration

# --- FLORA GENES (Alleles & Environmental Affinities) ---
var drought_tolerance: float = 0.20   # 0.10 to 0.40 min moisture (Trade-off: drought survival vs wet growth)
var growth_rate_mult: float = 1.0     # 0.60 to 1.50 (Trade-off: growth speed vs moisture demand)
var seed_spread_radius: float = 8.0   # 4.0 to 14.0 meters seed dispersion
var foliage_tint: Color = Color(0.35, 0.75, 0.35) # Visual foliage pigmentation

# =========================================================================
# FACTORY CONSTRUCTORS
# =========================================================================
static func create_default_fauna(species_name: String, rng: RandomNumberGenerator = null) -> EcosystemGenome:
	var g: EcosystemGenome = EcosystemGenome.new()
	g.genome_type = GenomeType.FAUNA
	g.species = species_name
	g.generation = 1
	g.parent_id = -1
	g.parent_b_id = -1

	var r: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()

	if species_name == "mountain_stalker":
		g.size = clampf(1.0 + r.randf_range(-0.06, 0.06), 0.60, 1.50)
		g.speed = clampf(1.0 + r.randf_range(-0.05, 0.05), 0.60, 1.50)
		g.sense_range = clampf(32.0 + r.randf_range(-3.0, 3.0), 14.0, 48.0)
		g.energy_efficiency = clampf(1.0 + r.randf_range(-0.05, 0.05), 0.65, 1.45)
		g.predation = clampf(1.0 + r.randf_range(-0.05, 0.05), 0.60, 1.50)
		g.foraging = 0.0
		# Charcoal dark base with slight shade variation
		var v: float = r.randf_range(0.12, 0.22)
		g.coat_tint = Color(v, v, v + 0.02, 1.0)
	else: # island_deer
		g.size = clampf(1.0 + r.randf_range(-0.06, 0.06), 0.60, 1.50)
		g.speed = clampf(1.0 + r.randf_range(-0.05, 0.05), 0.60, 1.50)
		g.sense_range = clampf(28.0 + r.randf_range(-3.0, 3.0), 14.0, 48.0)
		g.energy_efficiency = clampf(1.0 + r.randf_range(-0.05, 0.05), 0.65, 1.45)
		g.foraging = clampf(1.0 + r.randf_range(-0.05, 0.05), 0.60, 1.50)
		g.predation = 0.0
		# Warm fawn tan with slight golden/reddish variation
		var hue_shift: float = r.randf_range(-0.03, 0.03)
		var sat: float = clampf(0.55 + r.randf_range(-0.08, 0.08), 0.35, 0.75)
		g.coat_tint = Color.from_hsv(wrapf(0.08 + hue_shift, 0.0, 1.0), sat, 0.72)

	return g

static func create_default_flora(species_name: String, rng: RandomNumberGenerator = null) -> EcosystemGenome:
	var g: EcosystemGenome = EcosystemGenome.new()
	g.genome_type = GenomeType.FLORA
	g.species = species_name
	g.generation = 1
	g.parent_id = -1
	g.parent_b_id = -1

	var r: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()

	if species_name == "shrub_bush":
		g.drought_tolerance = clampf(0.30 + r.randf_range(-0.04, 0.04), 0.15, 0.45)
		g.growth_rate_mult = clampf(1.0 + r.randf_range(-0.08, 0.08), 0.60, 1.50)
		g.seed_spread_radius = clampf(10.0 + r.randf_range(-2.0, 2.0), 5.0, 15.0)
		g.size = clampf(1.0 + r.randf_range(-0.07, 0.07), 0.60, 1.50)
		g.foliage_tint = Color(0.28, 0.62, 0.30)
	else: # grass_patch
		g.drought_tolerance = clampf(0.20 + r.randf_range(-0.04, 0.04), 0.10, 0.38)
		g.growth_rate_mult = clampf(1.0 + r.randf_range(-0.08, 0.08), 0.60, 1.50)
		g.seed_spread_radius = clampf(8.0 + r.randf_range(-1.5, 1.5), 4.0, 12.0)
		g.size = clampf(1.0 + r.randf_range(-0.07, 0.07), 0.60, 1.50)
		g.foliage_tint = Color(0.38, 0.78, 0.32)

	return g

# =========================================================================
# REPRODUCTION & MUTATION
# =========================================================================

## Single-parent asexual / clonal reproduction with controlled mutations.
## Default mutation strength is strictly bounded to ±5% (0.05).
func create_mutated_offspring(parent_entity_id: int, rng: RandomNumberGenerator, mutation_rate: float = 0.25, max_mutation_pct: float = 0.05) -> EcosystemGenome:
	var child: EcosystemGenome = EcosystemGenome.new()
	child.genome_type = genome_type
	child.species = species
	child.generation = generation + 1
	child.parent_id = parent_entity_id
	child.parent_b_id = -1

	# Clone parent genes
	child.size = size
	child.speed = speed
	child.sense_range = sense_range
	child.energy_efficiency = energy_efficiency
	child.predation = predation
	child.foraging = foraging
	child.coat_tint = coat_tint

	child.drought_tolerance = drought_tolerance
	child.growth_rate_mult = growth_rate_mult
	child.seed_spread_radius = seed_spread_radius
	child.foliage_tint = foliage_tint

	if rng == null:
		return child

	# Apply strictly bounded mutations (±5% per trait by default)
	if genome_type == GenomeType.FAUNA:
		if rng.randf() < mutation_rate:
			var delta_size: float = child.size * rng.randf_range(-max_mutation_pct, max_mutation_pct)
			child.size = clampf(child.size + delta_size, 0.60, 1.50)

		if rng.randf() < mutation_rate:
			var delta_speed: float = child.speed * rng.randf_range(-max_mutation_pct, max_mutation_pct)
			child.speed = clampf(child.speed + delta_speed, 0.60, 1.50)

		if rng.randf() < mutation_rate:
			var delta_sense: float = child.sense_range * rng.randf_range(-max_mutation_pct, max_mutation_pct)
			child.sense_range = clampf(child.sense_range + delta_sense, 14.0, 48.0)

		if rng.randf() < mutation_rate:
			var delta_eff: float = child.energy_efficiency * rng.randf_range(-max_mutation_pct, max_mutation_pct)
			child.energy_efficiency = clampf(child.energy_efficiency + delta_eff, 0.65, 1.45)

		if child.species == "mountain_stalker":
			if rng.randf() < mutation_rate:
				var delta_pred: float = child.predation * rng.randf_range(-max_mutation_pct, max_mutation_pct)
				child.predation = clampf(child.predation + delta_pred, 0.60, 1.50)
		else:
			if rng.randf() < mutation_rate:
				var delta_forage: float = child.foraging * rng.randf_range(-max_mutation_pct, max_mutation_pct)
				child.foraging = clampf(child.foraging + delta_forage, 0.60, 1.50)

		if rng.randf() < mutation_rate * 0.8:
			var h: float = child.coat_tint.h + rng.randf_range(-0.03, 0.03)
			var s: float = clampf(child.coat_tint.s + rng.randf_range(-0.05, 0.05), 0.2, 0.8)
			var v: float = clampf(child.coat_tint.v + rng.randf_range(-0.05, 0.05), 0.15, 0.9)
			child.coat_tint = Color.from_hsv(wrapf(h, 0.0, 1.0), s, v)
	else: # FLORA
		if rng.randf() < mutation_rate:
			var delta_drg: float = child.drought_tolerance * rng.randf_range(-max_mutation_pct, max_mutation_pct)
			child.drought_tolerance = clampf(child.drought_tolerance + delta_drg, 0.08, 0.45)
		if rng.randf() < mutation_rate:
			var delta_growth: float = child.growth_rate_mult * rng.randf_range(-max_mutation_pct, max_mutation_pct)
			child.growth_rate_mult = clampf(child.growth_rate_mult + delta_growth, 0.55, 1.60)
		if rng.randf() < mutation_rate:
			var delta_spr: float = child.seed_spread_radius * rng.randf_range(-max_mutation_pct, max_mutation_pct)
			child.seed_spread_radius = clampf(child.seed_spread_radius + delta_spr, 3.5, 16.0)
		if rng.randf() < mutation_rate * 0.7:
			var h: float = child.foliage_tint.h + rng.randf_range(-0.03, 0.03)
			var s: float = clampf(child.foliage_tint.s + rng.randf_range(-0.05, 0.05), 0.25, 0.85)
			var v: float = clampf(child.foliage_tint.v + rng.randf_range(-0.05, 0.05), 0.3, 0.9)
			child.foliage_tint = Color.from_hsv(wrapf(h, 0.0, 1.0), s, v)

	return child

## Two-parent sexual recombination (Mendelian allele inheritance + bounded ±5% mutations).
static func create_recombined_offspring(
	parent_a: EcosystemGenome,
	parent_b: EcosystemGenome,
	parent_a_id: int,
	parent_b_id: int,
	rng: RandomNumberGenerator,
	mutation_rate: float = 0.25,
	max_mutation_pct: float = 0.05
) -> EcosystemGenome:
	var child: EcosystemGenome = EcosystemGenome.new()
	child.genome_type = parent_a.genome_type
	child.species = parent_a.species
	child.generation = maxi(parent_a.generation, parent_b.generation) + 1
	child.parent_id = parent_a_id
	child.parent_b_id = parent_b_id

	var r: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()

	# Recombine each allele (50% chance from either parent)
	child.size = parent_a.size if r.randf() < 0.5 else parent_b.size
	child.speed = parent_a.speed if r.randf() < 0.5 else parent_b.speed
	child.sense_range = parent_a.sense_range if r.randf() < 0.5 else parent_b.sense_range
	child.energy_efficiency = parent_a.energy_efficiency if r.randf() < 0.5 else parent_b.energy_efficiency
	child.predation = parent_a.predation if r.randf() < 0.5 else parent_b.predation
	child.foraging = parent_a.foraging if r.randf() < 0.5 else parent_b.foraging

	# Phenotypic blend for coat tint
	var blend_weight: float = r.randf_range(0.35, 0.65)
	child.coat_tint = parent_a.coat_tint.lerp(parent_b.coat_tint, blend_weight)

	# Apply controlled mutation (±5% default)
	if r.randf() < mutation_rate:
		child.size = clampf(child.size + child.size * r.randf_range(-max_mutation_pct, max_mutation_pct), 0.60, 1.50)
	if r.randf() < mutation_rate:
		child.speed = clampf(child.speed + child.speed * r.randf_range(-max_mutation_pct, max_mutation_pct), 0.60, 1.50)
	if r.randf() < mutation_rate:
		child.sense_range = clampf(child.sense_range + child.sense_range * r.randf_range(-max_mutation_pct, max_mutation_pct), 14.0, 48.0)
	if r.randf() < mutation_rate:
		child.energy_efficiency = clampf(child.energy_efficiency + child.energy_efficiency * r.randf_range(-max_mutation_pct, max_mutation_pct), 0.65, 1.45)

	if child.species == "mountain_stalker":
		if r.randf() < mutation_rate:
			child.predation = clampf(child.predation + child.predation * r.randf_range(-max_mutation_pct, max_mutation_pct), 0.60, 1.50)
	else:
		if r.randf() < mutation_rate:
			child.foraging = clampf(child.foraging + child.foraging * r.randf_range(-max_mutation_pct, max_mutation_pct), 0.60, 1.50)

	if r.randf() < mutation_rate * 0.8:
		var h: float = child.coat_tint.h + r.randf_range(-0.03, 0.03)
		var s: float = clampf(child.coat_tint.s + r.randf_range(-0.05, 0.05), 0.2, 0.8)
		var v: float = clampf(child.coat_tint.v + r.randf_range(-0.05, 0.05), 0.15, 0.9)
		child.coat_tint = Color.from_hsv(wrapf(h, 0.0, 1.0), s, v)

	return child

# =========================================================================
# TRADE-OFF AND CAUSAL PHENOTYPE EVALUATORS
# =========================================================================

## Continuous metabolic drain multiplier:
## Higher speed (quadratic burn) + larger mass (allometric burn) + wider senses + prowess vs energy efficiency.
func get_metabolic_burn_multiplier() -> float:
	var eff: float = maxf(0.5, energy_efficiency)
	var base_burn: float = 1.0 / eff
	var speed_penalty: float = 0.70 + 0.30 * (speed * speed)
	var size_penalty: float = 0.70 + 0.30 * pow(size, 1.5)
	var base_range: float = 32.0 if species == "mountain_stalker" else 28.0
	var sensory_cost: float = 0.85 + 0.15 * (sense_range / base_range)
	var prowess: float = predation if species == "mountain_stalker" else foraging
	var prowess_cost: float = 0.85 + 0.15 * maxf(0.6, prowess)
	return base_burn * speed_penalty * size_penalty * sensory_cost * prowess_cost

## Effective movement speed in m/s given species base speed
func get_effective_speed(base_speed: float) -> float:
	return base_speed * speed

## Effective maximum energy capacity
func get_effective_max_energy() -> float:
	return 100.0 * size

## Effective maximum health capacity
func get_effective_max_health() -> float:
	return 100.0 * (0.8 + 0.2 * size)

## Herbivore feeding intake rate (biomass/s)
func get_effective_intake_rate(base_intake: float = 2.5) -> float:
	return base_intake * maxf(0.6, foraging)

## Predator strike catch distance
func get_effective_strike_distance(base_dist: float = 2.0) -> float:
	return base_dist * maxf(0.6, predation)

## Predator kill energy conversion yield
func get_effective_kill_yield(base_energy: float = 55.0) -> float:
	return base_energy * (0.8 + 0.2 * maxf(0.6, predation))

## Plant growth rate trade-off: high drought tolerance trades off wet-season growth rate
func get_effective_growth_rate(base_growth_rate: float) -> float:
	var tolerance_penalty: float = clampf(1.15 - 0.5 * (drought_tolerance - 0.15), 0.75, 1.25)
	return base_growth_rate * growth_rate_mult * tolerance_penalty

# =========================================================================
# SERIALIZATION & SCHEMA v3 COMPATIBILITY
# =========================================================================
func serialize() -> Dictionary:
	return {
		"type": int(genome_type),
		"species": species,
		"generation": generation,
		"parent_id": parent_id,
		"parent_b_id": parent_b_id,
		# 5 V3 Core Traits
		"size": snapped(size, 0.001),
		"speed": snapped(speed, 0.001),
		"sense_range": snapped(sense_range, 0.01),
		"energy_efficiency": snapped(energy_efficiency, 0.001),
		"predation": snapped(predation, 0.001),
		"foraging": snapped(foraging, 0.001),
		# Backward compatibility aliases for Schema v2 readers
		"size_scale": snapped(size, 0.001),
		"speed_mult": snapped(speed, 0.001),
		"perception_radius": snapped(sense_range, 0.01),
		"metabolism_efficiency": snapped(energy_efficiency, 0.001),
		"coat_tint": [coat_tint.r, coat_tint.g, coat_tint.b, coat_tint.a],
		"drought_tolerance": snapped(drought_tolerance, 0.001),
		"growth_rate_mult": snapped(growth_rate_mult, 0.001),
		"seed_spread_radius": snapped(seed_spread_radius, 0.01),
		"foliage_tint": [foliage_tint.r, foliage_tint.g, foliage_tint.b, foliage_tint.a]
	}

static func deserialize(dict: Dictionary) -> EcosystemGenome:
	var g: EcosystemGenome = EcosystemGenome.new()
	g.genome_type = dict.get("type", 0) as GenomeType
	g.species = dict.get("species", "island_deer")
	g.generation = int(dict.get("generation", 1))
	g.parent_id = int(dict.get("parent_id", -1))
	g.parent_b_id = int(dict.get("parent_b_id", -1))

	# Load 5 traits with fallback to Schema v2 aliases
	if dict.has("size"):
		g.size = float(dict["size"])
	elif dict.has("size_scale"):
		g.size = float(dict["size_scale"])

	if dict.has("speed"):
		g.speed = float(dict["speed"])
	elif dict.has("speed_mult"):
		g.speed = float(dict["speed_mult"])

	if dict.has("sense_range"):
		g.sense_range = float(dict["sense_range"])
	elif dict.has("perception_radius"):
		g.sense_range = float(dict["perception_radius"])

	if dict.has("energy_efficiency"):
		g.energy_efficiency = float(dict["energy_efficiency"])
	elif dict.has("metabolism_efficiency"):
		g.energy_efficiency = float(dict["metabolism_efficiency"])

	if dict.has("predation"):
		g.predation = float(dict["predation"])
	elif g.species == "mountain_stalker":
		g.predation = 1.0

	if dict.has("foraging"):
		g.foraging = float(dict["foraging"])
	elif g.species == "island_deer":
		g.foraging = 1.0

	var c_arr: Variant = dict.get("coat_tint", null)
	if c_arr is Array and c_arr.size() >= 4:
		g.coat_tint = Color(float(c_arr[0]), float(c_arr[1]), float(c_arr[2]), float(c_arr[3]))

	g.drought_tolerance = float(dict.get("drought_tolerance", 0.20))
	g.growth_rate_mult = float(dict.get("growth_rate_mult", 1.0))
	g.seed_spread_radius = float(dict.get("seed_spread_radius", 8.0))

	var f_arr: Variant = dict.get("foliage_tint", null)
	if f_arr is Array and f_arr.size() >= 4:
		g.foliage_tint = Color(float(f_arr[0]), float(f_arr[1]), float(f_arr[2]), float(f_arr[3]))

	return g
