class_name TestGeneticsAndSelection
extends RefCounted

## Verification contract suite for Block 2: Genes, Inheritance and Natural Selection.

func test_genome_initialization_and_tradeoffs() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42

	var deer_g: EcosystemGenome = EcosystemGenome.create_default_fauna("island_deer", rng)
	var stalker_g: EcosystemGenome = EcosystemGenome.create_default_fauna("mountain_stalker", rng)
	var grass_g: EcosystemGenome = EcosystemGenome.create_default_flora("grass_patch", rng)

	if deer_g == null or stalker_g == null or grass_g == null:
		return false

	# Verify baseline bounds
	var deer_speed_valid: bool = deer_g.speed_mult >= 0.70 and deer_g.speed_mult <= 1.50
	var stalker_eff_valid: bool = stalker_g.metabolism_efficiency >= 0.70 and stalker_g.metabolism_efficiency <= 1.40
	var grass_drought_valid: bool = grass_g.drought_tolerance >= 0.10 and grass_g.drought_tolerance <= 0.40

	# Verify metabolic trade-off: higher speed = higher burn multiplier
	var slow_g: EcosystemGenome = EcosystemGenome.new()
	slow_g.speed_mult = 0.8
	var fast_g: EcosystemGenome = EcosystemGenome.new()
	fast_g.speed_mult = 1.4
	var tradeoff_burn: bool = fast_g.get_metabolic_burn_multiplier() > slow_g.get_metabolic_burn_multiplier()

	# Verify flora trade-off: high drought tolerance trades off growth rate in wet conditions
	var wet_plant: EcosystemGenome = EcosystemGenome.new()
	wet_plant.drought_tolerance = 0.12
	var dry_plant: EcosystemGenome = EcosystemGenome.new()
	dry_plant.drought_tolerance = 0.38
	var tradeoff_flora: bool = wet_plant.get_effective_growth_rate(1.0) > dry_plant.get_effective_growth_rate(1.0)

	return deer_speed_valid and stalker_eff_valid and grass_drought_valid and tradeoff_burn and tradeoff_flora

func test_genome_mutation_and_inheritance() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 999

	var parent: EcosystemGenome = EcosystemGenome.create_default_fauna("island_deer", rng)
	parent.generation = 3
	parent.speed_mult = 1.10

	# Force 100% mutation rate
	var child: EcosystemGenome = parent.create_mutated_offspring(1042, rng, 1.0, 0.12)

	var generation_incremented: bool = child.generation == 4
	var parent_recorded: bool = child.parent_id == 1042
	var species_preserved: bool = child.species == parent.species
	var mutation_applied: bool = absf(child.speed_mult - parent.speed_mult) > 0.001
	var bounded: bool = child.speed_mult >= 0.65 and child.speed_mult <= 1.60

	return generation_incremented and parent_recorded and species_preserved and mutation_applied and bounded

func test_genome_serialization_roundtrip() -> bool:
	var g: EcosystemGenome = EcosystemGenome.new()
	g.genome_type = EcosystemGenome.GenomeType.FAUNA
	g.species = "island_deer"
	g.generation = 5
	g.parent_id = 1024
	g.speed_mult = 1.25
	g.metabolism_efficiency = 1.15
	g.size_scale = 1.08
	g.perception_radius = 33.5
	g.coat_tint = Color(0.8, 0.6, 0.4, 1.0)
	g.drought_tolerance = 0.28
	g.growth_rate_mult = 1.12
	g.seed_spread_radius = 9.5
	g.foliage_tint = Color(0.3, 0.7, 0.3, 1.0)

	var dict: Dictionary = g.serialize()
	var g2: EcosystemGenome = EcosystemGenome.deserialize(dict)

	var gen_match: bool = g2.generation == 5 and g2.parent_id == 1024
	var speed_match: bool = absf(g2.speed_mult - 1.25) < 0.01
	var eff_match: bool = absf(g2.metabolism_efficiency - 1.15) < 0.01
	var size_match: bool = absf(g2.size_scale - 1.08) < 0.01
	var coat_match: bool = absf(g2.coat_tint.r - 0.8) < 0.02 and absf(g2.coat_tint.g - 0.6) < 0.02

	return gen_match and speed_match and eff_match and size_match and coat_match

func test_flora_inheritance_and_drought_selection() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 777
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)

	# Plant A: hardy drought-adapted genome (min_moisture = 0.15)
	var hardy_g: EcosystemGenome = EcosystemGenome.new()
	hardy_g.genome_type = EcosystemGenome.GenomeType.FLORA
	hardy_g.species = "grass_patch"
	hardy_g.drought_tolerance = 0.15
	var id_a: int = flora.spawn_plant("grass_patch", Vector3(0, 2, 0), 5.0, hardy_g)

	# Plant B: sensitive wet-soil genome (min_moisture = 0.35)
	var sens_g: EcosystemGenome = EcosystemGenome.new()
	sens_g.genome_type = EcosystemGenome.GenomeType.FLORA
	sens_g.species = "grass_patch"
	sens_g.drought_tolerance = 0.35
	var id_b: int = flora.spawn_plant("grass_patch", Vector3(10, 2, 0), 5.0, sens_g)

	# Create environmental grid with intermediate drought moisture = 0.22
	var config: WorldGenerationConfig = WorldGenerationConfig.new(777)
	var env_grid: EnvironmentalGrid = EnvironmentalGrid.new(config)
	for i: int in range(env_grid.get_cell_count()):
		var cell: Dictionary = env_grid.get_cell(i)
		cell["moisture"] = 0.22
		cell["temperature"] = 20.0
		cell["sun_exposure"] = 0.8

	# Step simulation for 6 seconds
	flora.step_simulation(6.0, env_grid)

	var p_a = flora.get_plant(id_a)
	var p_b = flora.get_plant(id_b)

	# Plant A (hardy: 0.15 <= 0.22) should maintain full or growing health
	# Plant B (sensitive: 0.35 > 0.22) must suffer drought stress decay
	var a_healthy: bool = p_a != null and p_a.health >= 95.0
	var b_decayed: bool = p_b != null and p_b.health < p_a.health

	return a_healthy and b_decayed

func test_fauna_inheritance_and_speed_selection() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 888
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Fast deer genome
	var fast_g: EcosystemGenome = EcosystemGenome.new()
	fast_g.species = "island_deer"
	fast_g.speed_mult = 1.40
	var fast_id: int = fauna.spawn_herbivore(Vector3(0, 1, 0), 80.0, FaunaSimulation.LifeStage.ADULT, fast_g)

	# Slow deer genome
	var slow_g: EcosystemGenome = EcosystemGenome.new()
	slow_g.species = "island_deer"
	slow_g.speed_mult = 0.70
	var slow_id: int = fauna.spawn_herbivore(Vector3(10, 1, 0), 80.0, FaunaSimulation.LifeStage.ADULT, slow_g)

	var fast_deer = fauna.get_herbivore(fast_id)
	var slow_deer = fauna.get_herbivore(slow_id)

	if fast_deer == null or slow_deer == null:
		return false

	# Verify effective speed separation
	var speed_separation: bool = fast_deer.move_speed > (slow_deer.move_speed * 1.8)

	# Verify metabolic cost separation (fast deer burns energy faster)
	var fast_burn: float = fast_deer.genome.get_metabolic_burn_multiplier()
	var slow_burn: float = slow_deer.genome.get_metabolic_burn_multiplier()
	var burn_separation: bool = fast_burn > slow_burn

	return speed_separation and burn_separation
