class_name EcosystemGenome
extends RefCounted

## Decoupled genetic representation for living entities (Fauna & Flora).
## Supports heritable traits, phenotypic variation, controlled mutations,
## trade-off calculations, and generation lineage tracking.

enum GenomeType {
	FAUNA = 0,
	FLORA = 1
}

# --- METADATA & LINEAGE ---
var genome_type: GenomeType = GenomeType.FAUNA
var species: String = "island_deer"
var generation: int = 1
var parent_id: int = -1

# --- FAUNA GENES (Alleles & Heritable Phenotypes) ---
var speed_mult: float = 1.0           # 0.70 to 1.50 (Trade-off: speed vs metabolic burn)
var metabolism_efficiency: float = 1.0 # 0.70 to 1.40 (Trade-off: efficiency vs cooldown)
var size_scale: float = 1.0           # 0.75 to 1.35 (Trade-off: health/capacity vs food needs)
var perception_radius: float = 28.0   # 16.0 to 44.0 (Trade-off: threat/food spotting vs cognitive load)
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

	var r: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()

	if species_name == "mountain_stalker":
		g.speed_mult = clampf(1.0 + r.randf_range(-0.06, 0.06), 0.70, 1.50)
		g.metabolism_efficiency = clampf(1.0 + r.randf_range(-0.05, 0.05), 0.70, 1.40)
		g.size_scale = clampf(1.0 + r.randf_range(-0.08, 0.08), 0.75, 1.35)
		g.perception_radius = clampf(32.0 + r.randf_range(-3.0, 3.0), 20.0, 44.0)
		# Charcoal dark base with slight shade variation
		var v: float = r.randf_range(0.12, 0.22)
		g.coat_tint = Color(v, v, v + 0.02, 1.0)
	else: # island_deer
		g.speed_mult = clampf(1.0 + r.randf_range(-0.06, 0.06), 0.70, 1.50)
		g.metabolism_efficiency = clampf(1.0 + r.randf_range(-0.05, 0.05), 0.70, 1.40)
		g.size_scale = clampf(1.0 + r.randf_range(-0.08, 0.08), 0.75, 1.35)
		g.perception_radius = clampf(28.0 + r.randf_range(-3.0, 3.0), 16.0, 40.0)
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

	var r: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()

	if species_name == "shrub_bush":
		g.drought_tolerance = clampf(0.30 + r.randf_range(-0.04, 0.04), 0.15, 0.45)
		g.growth_rate_mult = clampf(1.0 + r.randf_range(-0.08, 0.08), 0.60, 1.50)
		g.seed_spread_radius = clampf(10.0 + r.randf_range(-2.0, 2.0), 5.0, 15.0)
		g.size_scale = clampf(1.0 + r.randf_range(-0.07, 0.07), 0.75, 1.35)
		g.foliage_tint = Color(0.28, 0.62, 0.30)
	else: # grass_patch
		g.drought_tolerance = clampf(0.20 + r.randf_range(-0.04, 0.04), 0.10, 0.38)
		g.growth_rate_mult = clampf(1.0 + r.randf_range(-0.08, 0.08), 0.60, 1.50)
		g.seed_spread_radius = clampf(8.0 + r.randf_range(-1.5, 1.5), 4.0, 12.0)
		g.size_scale = clampf(1.0 + r.randf_range(-0.07, 0.07), 0.75, 1.35)
		g.foliage_tint = Color(0.38, 0.78, 0.32)

	return g

# =========================================================================
# REPRODUCTION & MUTATION
# =========================================================================
func create_mutated_offspring(parent_entity_id: int, rng: RandomNumberGenerator, mutation_rate: float = 0.25, mutation_strength: float = 0.12) -> EcosystemGenome:
	var child: EcosystemGenome = EcosystemGenome.new()
	child.genome_type = genome_type
	child.species = species
	child.generation = generation + 1
	child.parent_id = parent_entity_id

	# Clone parent genes
	child.speed_mult = speed_mult
	child.metabolism_efficiency = metabolism_efficiency
	child.size_scale = size_scale
	child.perception_radius = perception_radius
	child.coat_tint = coat_tint

	child.drought_tolerance = drought_tolerance
	child.growth_rate_mult = growth_rate_mult
	child.seed_spread_radius = seed_spread_radius
	child.foliage_tint = foliage_tint

	if rng == null:
		return child

	# Apply controlled mutations
	if genome_type == GenomeType.FAUNA:
		if rng.randf() < mutation_rate:
			child.speed_mult = clampf(child.speed_mult + rng.randf_range(-mutation_strength, mutation_strength), 0.65, 1.60)
		if rng.randf() < mutation_rate:
			child.metabolism_efficiency = clampf(child.metabolism_efficiency + rng.randf_range(-mutation_strength, mutation_strength), 0.65, 1.50)
		if rng.randf() < mutation_rate:
			child.size_scale = clampf(child.size_scale + rng.randf_range(-mutation_strength * 0.7, mutation_strength * 0.7), 0.70, 1.40)
		if rng.randf() < mutation_rate:
			child.perception_radius = clampf(child.perception_radius + rng.randf_range(-3.0, 3.0), 16.0, 45.0)
		if rng.randf() < mutation_rate * 0.8:
			# Subtle phenotype coat tint mutation
			var h: float = child.coat_tint.h + rng.randf_range(-0.03, 0.03)
			var s: float = clampf(child.coat_tint.s + rng.randf_range(-0.05, 0.05), 0.2, 0.8)
			var v: float = clampf(child.coat_tint.v + rng.randf_range(-0.05, 0.05), 0.15, 0.9)
			child.coat_tint = Color.from_hsv(wrapf(h, 0.0, 1.0), s, v)
	else: # FLORA
		if rng.randf() < mutation_rate:
			child.drought_tolerance = clampf(child.drought_tolerance + rng.randf_range(-0.03, 0.03), 0.08, 0.45)
		if rng.randf() < mutation_rate:
			child.growth_rate_mult = clampf(child.growth_rate_mult + rng.randf_range(-mutation_strength, mutation_strength), 0.55, 1.60)
		if rng.randf() < mutation_rate:
			child.seed_spread_radius = clampf(child.seed_spread_radius + rng.randf_range(-1.5, 1.5), 3.5, 16.0)
		if rng.randf() < mutation_rate * 0.7:
			var h: float = child.foliage_tint.h + rng.randf_range(-0.03, 0.03)
			var s: float = clampf(child.foliage_tint.s + rng.randf_range(-0.05, 0.05), 0.25, 0.85)
			var v: float = clampf(child.foliage_tint.v + rng.randf_range(-0.05, 0.05), 0.3, 0.9)
			child.foliage_tint = Color.from_hsv(wrapf(h, 0.0, 1.0), s, v)

	return child

# =========================================================================
# TRADE-OFF AND CAUSAL PHENOTYPE EVALUATORS
# =========================================================================
## Returns continuous metabolic drain multiplier (higher speed/size -> burns energy faster)
func get_metabolic_burn_multiplier() -> float:
	var base_burn: float = 1.0 / maxf(0.5, metabolism_efficiency)
	var speed_penalty: float = 0.75 + 0.35 * (speed_mult * speed_mult)
	var size_penalty: float = 0.80 + 0.25 * size_scale
	var sensory_cost: float = 0.90 + 0.10 * (perception_radius / 28.0)
	return base_burn * speed_penalty * size_penalty * sensory_cost

## Effective movement speed in m/s given species base speed
func get_effective_speed(base_speed: float) -> float:
	return base_speed * speed_mult

## Effective maximum energy capacity
func get_effective_max_energy() -> float:
	return 100.0 * size_scale

## Effective maximum health capacity
func get_effective_max_health() -> float:
	return 100.0 * (0.8 + 0.2 * size_scale)

## Plant growth rate trade-off: high drought tolerance trades off wet-season growth rate
func get_effective_growth_rate(base_growth_rate: float) -> float:
	var tolerance_penalty: float = clampf(1.15 - 0.5 * (drought_tolerance - 0.15), 0.75, 1.25)
	return base_growth_rate * growth_rate_mult * tolerance_penalty

# =========================================================================
# SERIALIZATION & SCHEMA v2 COMPATIBILITY
# =========================================================================
func serialize() -> Dictionary:
	return {
		"type": int(genome_type),
		"species": species,
		"generation": generation,
		"parent_id": parent_id,
		"speed_mult": speed_mult,
		"metabolism_efficiency": metabolism_efficiency,
		"size_scale": size_scale,
		"perception_radius": perception_radius,
		"coat_tint": [coat_tint.r, coat_tint.g, coat_tint.b, coat_tint.a],
		"drought_tolerance": drought_tolerance,
		"growth_rate_mult": growth_rate_mult,
		"seed_spread_radius": seed_spread_radius,
		"foliage_tint": [foliage_tint.r, foliage_tint.g, foliage_tint.b, foliage_tint.a]
	}

static func deserialize(dict: Dictionary) -> EcosystemGenome:
	var g: EcosystemGenome = EcosystemGenome.new()
	g.genome_type = dict.get("type", 0) as GenomeType
	g.species = dict.get("species", "island_deer")
	g.generation = int(dict.get("generation", 1))
	g.parent_id = int(dict.get("parent_id", -1))

	g.speed_mult = float(dict.get("speed_mult", 1.0))
	g.metabolism_efficiency = float(dict.get("metabolism_efficiency", 1.0))
	g.size_scale = float(dict.get("size_scale", 1.0))
	g.perception_radius = float(dict.get("perception_radius", 28.0))

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
