class_name TestBlock31SeasonalPhenologyAndForaging
extends RefCounted

## Automated Contract Suite 38: Block 31 Seasonal Foliage Phenology, Flora Nutrition & Foraging

const VegetationScatter = preload("res://presentation/environment/vegetation_scatter.gd")
const FloraSimulation = preload("res://core/ecosystem/flora_simulation.gd")
const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const ExpeditionManager = preload("res://core/gameplay/expedition_manager.gd")
const EnvironmentalGrid = preload("res://core/environment/environmental_grid.gd")

func test_foliage_shader_parameters_and_seasonal_phenology() -> bool:
	var vs: VegetationScatter = VegetationScatter.new()
	var test_mat: ShaderMaterial = ShaderMaterial.new()
	test_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
	vs.register_foliage_material(test_mat)

	# 1. Test Spring phenology
	vs.apply_season_phenology(0) # SPRING
	var spring_tint: Variant = test_mat.get_shader_parameter("season_tint")
	var spring_weight: float = float(test_mat.get_shader_parameter("season_tint_weight"))
	var spring_frost: float = float(test_mat.get_shader_parameter("frost_amount"))
	if not (spring_tint is Vector3):
		vs.free()
		return false
	if spring_weight <= 0.40:
		vs.free()
		return false
	if spring_frost >= 0.01:
		vs.free()
		return false

	# 2. Test Autumn phenology (golden amber russet)
	vs.apply_season_phenology(2) # AUTUMN
	var autumn_tint: Vector3 = test_mat.get_shader_parameter("season_tint") as Vector3
	var autumn_weight: float = float(test_mat.get_shader_parameter("season_tint_weight"))
	if autumn_tint.x <= 1.20:
		vs.free()
		return false
	if autumn_weight < 0.80:
		vs.free()
		return false

	# 3. Test Winter phenology (rime frost)
	vs.apply_season_phenology(3) # WINTER
	var winter_frost: float = float(test_mat.get_shader_parameter("frost_amount"))
	if winter_frost < 0.40:
		vs.free()
		return false

	vs.free()
	return true

func test_flora_seasonal_growth_and_nutritional_density() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42
	var flora: FloraSimulation = FloraSimulation.new(rng, null, null, null)

	var p1_id: int = flora.spawn_plant("shrub_bush", Vector3(10.0, 1.0, 10.0), 5.0)
	var p2_id: int = flora.spawn_plant("grass_patch", Vector3(12.0, 1.0, 12.0), 5.0)

	# Spring test
	flora.set_active_season(0)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new()
	grid.initialize_grid(func(_x: float, _z: float) -> float: return 1.0)
	flora.step_simulation(1.0, grid)

	var p1: Variant = flora.get_plant(p1_id)
	if p1 == null or p1.nutritional_value < 1.25:
		return false

	# Winter test
	flora.set_active_season(3) # Winter
	flora.step_simulation(1.0, grid)
	if p1.nutritional_value > 0.85:
		return false

	return true

func test_flora_preferred_species_foraging() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 99
	var flora: FloraSimulation = FloraSimulation.new(rng, null, null, null)

	# Plant a grass patch closer (dist 2.0m) and shrub slightly further (dist 3.5m)
	var g_id: int = flora.spawn_plant("grass_patch", Vector3(2.0, 0.0, 0.0), 8.0)
	var s_id: int = flora.spawn_plant("shrub_bush", Vector3(3.5, 0.0, 0.0), 8.0)

	# Without preference: nearest is grass_patch
	var nearest_general: Variant = flora.find_nearest_food(Vector3.ZERO, 10.0, 1.0, "")
	if nearest_general == null or nearest_general.id != g_id:
		return false

	# With preference for shrub_bush: should pick shrub_bush despite being slightly farther
	var nearest_shrub: Variant = flora.find_nearest_food(Vector3.ZERO, 10.0, 1.0, "shrub_bush")
	if nearest_shrub == null or nearest_shrub.id != s_id:
		return false

	return true

func test_fauna_seasonal_foraging_and_nutritional_metabolism() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 77
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, null, null)
	var flora: FloraSimulation = FloraSimulation.new(rng, null, null, null)

	var p_id: int = flora.spawn_plant("shrub_bush", Vector3(2.0, 0.0, 0.0), 10.0)
	var h_id: int = fauna.spawn_herbivore(Vector3(2.5, 0.0, 0.0), 50.0)
	var h: Variant = fauna.get_herbivore(h_id)
	if h == null:
		return false

	# Set high nutrition in flora
	flora.get_plant(p_id).nutritional_value = 1.50
	h.target_plant_id = p_id
	h.state = FaunaSimulation.HerbivoreState.EATING

	var pre_e: float = h.energy
	fauna.step_simulation(0.5, flora, Callable(), null, 12.0)
	var post_e: float = h.energy
	if post_e <= pre_e:
		return false

	return true

func test_expedition_botanical_survey_and_milestone() -> bool:
	var exp: ExpeditionManager = ExpeditionManager.new()
	exp.set_game_state(ExpeditionManager.GameState.PLAYING)

	if exp.get_botanical_survey_count() != 0:
		exp.free()
		return false
	var r1: bool = exp.register_botanical_survey("shrub_bush", "Spring")
	if not r1:
		exp.free()
		return false
	var r_dup: bool = exp.register_botanical_survey("shrub_bush", "Spring")
	if r_dup:
		exp.free()
		return false

	exp.register_botanical_survey("shrub_bush", "Autumn")
	exp.register_botanical_survey("grass_patch", "Winter")

	if exp.get_botanical_survey_count() != 3:
		exp.free()
		return false
	var milestones: Dictionary = exp.get_milestones()
	if not milestones.has("master_botanist"):
		exp.free()
		return false
	if milestones["master_botanist"]["title"] != "🌿 Island Herbalist":
		exp.free()
		return false

	exp.free()
	return true

func test_botanical_survey_persistence_roundtrip() -> bool:
	var exp1: ExpeditionManager = ExpeditionManager.new()
	exp1.set_game_state(ExpeditionManager.GameState.PLAYING)
	exp1.register_botanical_survey("shrub_bush", "Spring")
	exp1.register_botanical_survey("shrub_bush", "Summer")
	exp1.register_botanical_survey("grass_patch", "Autumn")

	var test_path: String = "user://test_botanical_journal.json"
	var err: Error = exp1.save_journal(test_path)
	if err != OK:
		exp1.free()
		return false

	var exp2: ExpeditionManager = ExpeditionManager.new()
	var load_err: Error = exp2.load_journal(test_path)
	if load_err != OK:
		exp1.free()
		exp2.free()
		return false
	if exp2.get_botanical_survey_count() != 3:
		exp1.free()
		exp2.free()
		return false
	if not exp2.get_milestones().has("master_botanist"):
		exp1.free()
		exp2.free()
		return false

	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(test_path)

	exp1.free()
	exp2.free()
	return true
