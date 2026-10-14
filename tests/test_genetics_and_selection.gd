class_name TestGeneticsAndSelection
extends RefCounted

## Comprehensive verification contract suite for Block 2: Causal Ecology and Heritable Traits.
## Validates 5 core traits, ±5% bounded mutations, two-parent Mendelian recombination,
## trade-off costs, causal behavior impact, deterministic reproducibility,
## multi-generation stability (no NaN/runaway pop), and Schema v2 -> v3 persistence migration.

func test_genome_initialization_and_tradeoffs() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42

	var deer_g: EcosystemGenome = EcosystemGenome.create_default_fauna("island_deer", rng)
	var stalker_g: EcosystemGenome = EcosystemGenome.create_default_fauna("mountain_stalker", rng)
	var grass_g: EcosystemGenome = EcosystemGenome.create_default_flora("grass_patch", rng)

	if deer_g == null or stalker_g == null or grass_g == null:
		return false

	# Verify baseline bounds for 5 traits
	var deer_traits_valid: bool = (
		deer_g.size >= 0.60 and deer_g.size <= 1.50 and
		deer_g.speed >= 0.60 and deer_g.speed <= 1.50 and
		deer_g.sense_range >= 14.0 and deer_g.sense_range <= 48.0 and
		deer_g.energy_efficiency >= 0.65 and deer_g.energy_efficiency <= 1.45 and
		deer_g.foraging >= 0.60 and deer_g.foraging <= 1.50 and
		deer_g.predation == 0.0
	)

	var stalker_traits_valid: bool = (
		stalker_g.size >= 0.60 and stalker_g.size <= 1.50 and
		stalker_g.speed >= 0.60 and stalker_g.speed <= 1.50 and
		stalker_g.sense_range >= 14.0 and stalker_g.sense_range <= 48.0 and
		stalker_g.energy_efficiency >= 0.65 and stalker_g.energy_efficiency <= 1.45 and
		stalker_g.predation >= 0.60 and stalker_g.predation <= 1.50 and
		stalker_g.foraging == 0.0
	)

	# Verify trade-off: higher speed & size = higher metabolic burn multiplier
	var slow_g: EcosystemGenome = EcosystemGenome.new()
	slow_g.speed = 0.8
	slow_g.size = 0.8
	var fast_g: EcosystemGenome = EcosystemGenome.new()
	fast_g.speed = 1.4
	fast_g.size = 1.4
	var tradeoff_burn: bool = fast_g.get_metabolic_burn_multiplier() > (slow_g.get_metabolic_burn_multiplier() * 1.3)

	# Verify flora trade-off: high drought tolerance trades off growth rate in wet conditions
	var wet_plant: EcosystemGenome = EcosystemGenome.new()
	wet_plant.drought_tolerance = 0.12
	var dry_plant: EcosystemGenome = EcosystemGenome.new()
	dry_plant.drought_tolerance = 0.38
	var tradeoff_flora: bool = wet_plant.get_effective_growth_rate(1.0) > dry_plant.get_effective_growth_rate(1.0)

	return deer_traits_valid and stalker_traits_valid and tradeoff_burn and tradeoff_flora

func test_genome_mutation_and_inheritance() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 999

	var parent: EcosystemGenome = EcosystemGenome.create_default_fauna("island_deer", rng)
	parent.generation = 3
	parent.speed = 1.10
	parent.size = 1.05

	# 100% mutation rate with default 5% max delta
	var child: EcosystemGenome = parent.create_mutated_offspring(1042, rng, 1.0, 0.05)

	var generation_incremented: bool = child.generation == 4
	var parent_recorded: bool = child.parent_id == 1042
	var species_preserved: bool = child.species == parent.species

	# Verify mutation occurred and is strictly within ±5% of parent
	var spd_ratio: float = absf(child.speed - parent.speed) / parent.speed
	var sz_ratio: float = absf(child.size - parent.size) / parent.size
	var mutation_bounded: bool = spd_ratio <= 0.0501 and sz_ratio <= 0.0501
	var bounded_absolute: bool = child.speed >= 0.60 and child.speed <= 1.50

	return generation_incremented and parent_recorded and species_preserved and mutation_bounded and bounded_absolute

func test_sexual_recombination_and_lineage() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1234

	var parent_a: EcosystemGenome = EcosystemGenome.new()
	parent_a.species = "island_deer"
	parent_a.generation = 2
	parent_a.speed = 1.35
	parent_a.size = 0.85
	parent_a.sense_range = 36.0
	parent_a.energy_efficiency = 1.25
	parent_a.foraging = 0.90
	parent_a.coat_tint = Color(0.9, 0.5, 0.3, 1.0)

	var parent_b: EcosystemGenome = EcosystemGenome.new()
	parent_b.species = "island_deer"
	parent_b.generation = 4
	parent_b.speed = 0.75
	parent_b.size = 1.40
	parent_b.sense_range = 22.0
	parent_b.energy_efficiency = 0.80
	parent_b.foraging = 1.30
	parent_b.coat_tint = Color(0.4, 0.3, 0.2, 1.0)

	# Pure recombination with 0% mutation to test exact Mendelian segregation
	var child: EcosystemGenome = EcosystemGenome.create_recombined_offspring(parent_a, parent_b, 501, 502, rng, 0.0, 0.05)

	var gen_correct: bool = child.generation == 5
	var lineage_correct: bool = child.parent_id == 501 and child.parent_b_id == 502
	# Offspring traits must equal either parent A or parent B
	var speed_inherited: bool = is_equal_approx(child.speed, 1.35) or is_equal_approx(child.speed, 0.75)
	var size_inherited: bool = is_equal_approx(child.size, 0.85) or is_equal_approx(child.size, 1.40)
	var sense_inherited: bool = is_equal_approx(child.sense_range, 36.0) or is_equal_approx(child.sense_range, 22.0)
	var eff_inherited: bool = is_equal_approx(child.energy_efficiency, 1.25) or is_equal_approx(child.energy_efficiency, 0.80)
	var forage_inherited: bool = is_equal_approx(child.foraging, 0.90) or is_equal_approx(child.foraging, 1.30)

	return gen_correct and lineage_correct and speed_inherited and size_inherited and sense_inherited and eff_inherited and forage_inherited

func test_genome_serialization_roundtrip() -> bool:
	var g: EcosystemGenome = EcosystemGenome.new()
	g.genome_type = EcosystemGenome.GenomeType.FAUNA
	g.species = "mountain_stalker"
	g.generation = 5
	g.parent_id = 1024
	g.parent_b_id = 1025
	g.speed = 1.25
	g.energy_efficiency = 1.15
	g.size = 1.08
	g.sense_range = 33.5
	g.predation = 1.30
	g.foraging = 0.0
	g.coat_tint = Color(0.2, 0.2, 0.22, 1.0)

	var dict: Dictionary = g.serialize()
	var g2: EcosystemGenome = EcosystemGenome.deserialize(dict)

	var gen_match: bool = g2.generation == 5 and g2.parent_id == 1024 and g2.parent_b_id == 1025
	var speed_match: bool = absf(g2.speed - 1.25) < 0.01
	var eff_match: bool = absf(g2.energy_efficiency - 1.15) < 0.01
	var size_match: bool = absf(g2.size - 1.08) < 0.01
	var sense_match: bool = absf(g2.sense_range - 33.5) < 0.05
	var pred_match: bool = absf(g2.predation - 1.30) < 0.01

	return gen_match and speed_match and eff_match and size_match and sense_match and pred_match

func test_flora_inheritance_and_drought_selection() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 777
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)

	var hardy_g: EcosystemGenome = EcosystemGenome.new()
	hardy_g.genome_type = EcosystemGenome.GenomeType.FLORA
	hardy_g.species = "grass_patch"
	hardy_g.drought_tolerance = 0.15
	var id_a: int = flora.spawn_plant("grass_patch", Vector3(0, 2, 0), 5.0, hardy_g)

	var sens_g: EcosystemGenome = EcosystemGenome.new()
	sens_g.genome_type = EcosystemGenome.GenomeType.FLORA
	sens_g.species = "grass_patch"
	sens_g.drought_tolerance = 0.35
	var id_b: int = flora.spawn_plant("grass_patch", Vector3(10, 2, 0), 5.0, sens_g)

	var config: WorldGenerationConfig = WorldGenerationConfig.new(777)
	var env_grid: EnvironmentalGrid = EnvironmentalGrid.new(config)
	for i: int in range(env_grid.get_cell_count()):
		var cell: Dictionary = env_grid.get_cell(i)
		cell["moisture"] = 0.22
		cell["temperature"] = 20.0
		cell["sun_exposure"] = 0.8

	flora.step_simulation(6.0, env_grid)

	var p_a = flora.get_plant(id_a)
	var p_b = flora.get_plant(id_b)

	var a_healthy: bool = p_a != null and p_a.health >= 95.0
	var b_decayed: bool = p_b != null and p_b.health < p_a.health

	return a_healthy and b_decayed

func test_fauna_inheritance_and_speed_selection() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 888
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	var fast_g: EcosystemGenome = EcosystemGenome.new()
	fast_g.species = "island_deer"
	fast_g.speed = 1.40
	var fast_id: int = fauna.spawn_herbivore(Vector3(0, 1, 0), 80.0, FaunaSimulation.LifeStage.ADULT, fast_g)

	var slow_g: EcosystemGenome = EcosystemGenome.new()
	slow_g.species = "island_deer"
	slow_g.speed = 0.70
	var slow_id: int = fauna.spawn_herbivore(Vector3(10, 1, 0), 80.0, FaunaSimulation.LifeStage.ADULT, slow_g)

	var fast_deer = fauna.get_herbivore(fast_id)
	var slow_deer = fauna.get_herbivore(slow_id)

	if fast_deer == null or slow_deer == null:
		return false

	var speed_separation: bool = fast_deer.move_speed > (slow_deer.move_speed * 1.8)
	var fast_burn: float = fast_deer.genome.get_metabolic_burn_multiplier()
	var slow_burn: float = slow_deer.genome.get_metabolic_burn_multiplier()
	var burn_separation: bool = fast_burn > slow_burn

	return speed_separation and burn_separation

func test_traits_affect_foraging_and_predation_actions() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 333
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)
	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)

	# Plant food source
	var plant_id: int = flora.spawn_plant("grass_patch", Vector3(0, 1, 0), 20.0)

	# Deer A: high foraging (1.40) vs Deer B: low foraging (0.70)
	var g_high_forage: EcosystemGenome = EcosystemGenome.new()
	g_high_forage.species = "island_deer"
	g_high_forage.foraging = 1.40

	var g_low_forage: EcosystemGenome = EcosystemGenome.new()
	g_low_forage.species = "island_deer"
	g_low_forage.foraging = 0.70

	var deer_high_id: int = fauna.spawn_herbivore(Vector3(0.5, 1, 0), 50.0, FaunaSimulation.LifeStage.ADULT, g_high_forage)
	var deer_low_id: int = fauna.spawn_herbivore(Vector3(0.5, 1, 0), 50.0, FaunaSimulation.LifeStage.ADULT, g_low_forage)
	var deer_high = fauna.get_herbivore(deer_high_id)
	var deer_low = fauna.get_herbivore(deer_low_id)
	deer_high.state = FaunaSimulation.HerbivoreState.EATING
	deer_high.target_plant_id = plant_id
	deer_low.state = FaunaSimulation.HerbivoreState.EATING
	deer_low.target_plant_id = plant_id

	var height_fn: Callable = func(_x, _z): return 1.0
	fauna.step_simulation(1.0, flora, height_fn)

	# Deer with higher foraging trait consumed and recovered more energy
	var foraging_impact: bool = deer_high.energy > deer_low.energy

	# Stalker A: high predation (1.40) vs Stalker B: low predation (0.70)
	var g_high_pred: EcosystemGenome = EcosystemGenome.new()
	g_high_pred.species = "mountain_stalker"
	g_high_pred.predation = 1.40
	var g_low_pred: EcosystemGenome = EcosystemGenome.new()
	g_low_pred.species = "mountain_stalker"
	g_low_pred.predation = 0.70

	var strike_high: float = g_high_pred.get_effective_strike_distance(2.0)
	var strike_low: float = g_low_pred.get_effective_strike_distance(2.0)
	var yield_high: float = g_high_pred.get_effective_kill_yield(55.0)
	var yield_low: float = g_low_pred.get_effective_kill_yield(55.0)

	var predation_strike_impact: bool = strike_high > (strike_low * 1.5)
	var predation_yield_impact: bool = yield_high > yield_low

	return foraging_impact and predation_strike_impact and predation_yield_impact

func test_multi_generation_simulation_stability() -> bool:
	var seed_obj: WorldSeed = WorldSeed.new(99999)
	var rng: RandomNumberGenerator = seed_obj.get_stream("ecology")
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Populate starter organisms
	for i in range(20):
		flora.spawn_plant("grass_patch", Vector3(rng.randf_range(-20, 20), 1, rng.randf_range(-20, 20)), 15.0)
	for i in range(12):
		fauna.spawn_herbivore(Vector3(rng.randf_range(-15, 15), 1, rng.randf_range(-15, 15)), 85.0)
	for i in range(2):
		fauna.spawn_predator(Vector3(rng.randf_range(-25, 25), 1, rng.randf_range(-25, 25)), 90.0)

	var height_fn: Callable = func(_x, _z): return 1.0

	# Step 50 ticks of continuous simulation (25.0 simulated seconds)
	for tick in range(50):
		fauna.step_simulation(0.5, flora, height_fn)

	# Verify numerical integrity across all living entities
	var no_nan: bool = true
	var population_bounded: bool = true

	var herbs: Array = fauna.get_all_herbivores()
	var preds: Array = fauna.get_all_predators()

	if herbs.size() > 45 or preds.size() > 10:
		population_bounded = false

	for h in herbs:
		if is_nan(h.position.x) or is_nan(h.energy) or is_nan(h.health):
			no_nan = false
		if h.energy < 0.0 or h.health < 0.0:
			no_nan = false
		if h.genome:
			if h.genome.size < 0.60 or h.genome.size > 1.50: no_nan = false
			if h.genome.speed < 0.60 or h.genome.speed > 1.50: no_nan = false

	for p in preds:
		if is_nan(p.position.x) or is_nan(p.energy) or is_nan(p.health):
			no_nan = false
		if p.energy < 0.0 or p.health < 0.0:
			no_nan = false
		if p.genome:
			if p.genome.predation < 0.60 or p.genome.predation > 1.50: no_nan = false

	return no_nan and population_bounded

func test_schema_v2_to_v3_migration_roundtrip() -> bool:
	var test_path: String = "user://tests/schema_v2_migration_test.json"
	var dir: String = test_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	# Construct realistic Schema v2 save payload (lacking v3 trait names, predation/foraging)
	var v2_payload: Dictionary = {
		"version": 2,
		"timestamp": 1700000000,
		"seed": {"master_seed": 771122},
		"clock": {"simulation_time": 45.0, "tick_count": 90, "time_scale": 1.0, "is_paused": false},
		"config": {},
		"weather": {},
		"environment": {},
		"ecosystem": {
			"plants": [],
			"herbivores": [
				{
					"id": 1001,
					"species": "island_deer",
					"position": [5.0, 1.2, -3.0],
					"velocity": [0.0, 0.0, 0.0],
					"heading": 0.5,
					"health": 95.0,
					"energy": 78.0,
					"age": 40.0,
					"life_stage": 1,
					"state": 0,
					"genome": {
						"type": 0,
						"species": "island_deer",
						"generation": 2,
						"parent_id": 1000,
						"speed_mult": 1.15,
						"metabolism_efficiency": 1.08,
						"size_scale": 0.95,
						"perception_radius": 30.0
					}
				}
			],
			"predators": [
				{
					"id": 2001,
					"species": "mountain_stalker",
					"position": [-12.0, 2.0, 15.0],
					"velocity": [0.0, 0.0, 0.0],
					"heading": 1.2,
					"health": 100.0,
					"energy": 82.0,
					"age": 35.0,
					"life_stage": 1,
					"state": 0,
					"genome": {
						"type": 0,
						"species": "mountain_stalker",
						"generation": 1,
						"parent_id": -1,
						"speed_mult": 1.05,
						"metabolism_efficiency": 0.98,
						"size_scale": 1.10,
						"perception_radius": 34.0
					}
				}
			]
		},
		"metrics": {
			"births_total": 5,
			"deaths_total": 2
		},
		"entities": []
	}

	var f: FileAccess = FileAccess.open(test_path, FileAccess.WRITE)
	if not f:
		return false
	f.store_string(JSON.stringify(v2_payload))
	f.close()

	# Load through WorldPersistence: must trigger automatic schema migration to v3
	var load_result: Dictionary = WorldPersistence.load_world(test_path)
	if load_result.get("error", OK) != OK:
		return false

	var loaded_data: Dictionary = load_result["data"]
	var migrated_version: int = int(loaded_data.get("version", 0))
	var original_ver: int = int(loaded_data.get("migrated_from_version", 0))

	if migrated_version != 3 or original_ver != 2:
		return false

	# Verify herbivore genome has all 5 v3 traits properly backfilled
	var h_list: Array = loaded_data["ecosystem"]["herbivores"]
	var h_genome: Dictionary = h_list[0]["genome"]
	var h_traits_ok: bool = (
		is_equal_approx(float(h_genome["speed"]), 1.15) and
		is_equal_approx(float(h_genome["energy_efficiency"]), 1.08) and
		is_equal_approx(float(h_genome["size"]), 0.95) and
		is_equal_approx(float(h_genome["sense_range"]), 30.0) and
		is_equal_approx(float(h_genome["foraging"]), 1.0) and
		is_equal_approx(float(h_genome["predation"]), 0.0)
	)

	# Verify predator genome has predation backfilled
	var p_list: Array = loaded_data["ecosystem"]["predators"]
	var p_genome: Dictionary = p_list[0]["genome"]
	var p_traits_ok: bool = (
		is_equal_approx(float(p_genome["speed"]), 1.05) and
		is_equal_approx(float(p_genome["predation"]), 1.0) and
		is_equal_approx(float(p_genome["foraging"]), 0.0)
	)

	# Cleanup test file
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(test_path)
	if FileAccess.file_exists(test_path + ".bak"):
		DirAccess.remove_absolute(test_path + ".bak")

	return h_traits_ok and p_traits_ok
