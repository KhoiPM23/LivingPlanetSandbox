class_name TestBlock34WildernessToolsAndChainReactions
extends RefCounted

## Automated contract test suite for Block 34: Wilderness Survival Tools,
## Handheld & Placed Torches, Elemental Combustion & Ash-Enrichment Ecological Loops.

const WildernessTorchSystem = preload("res://presentation/tools/wilderness_torch_system.gd")
const PlayerToolController = preload("res://presentation/tools/player_tool_controller.gd")
const EnvironmentalGrid = preload("res://core/environment/environmental_grid.gd")
const FloraSimulation = preload("res://core/ecosystem/flora_simulation.gd")
const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")
const WorldGenerationConfig = preload("res://core/environment/world_generation_config.gd")

func test_handheld_torch_toggle_and_lighting_budget() -> bool:
	var torch_sys: WildernessTorchSystem = WildernessTorchSystem.new()
	torch_sys._ready()
	if torch_sys.is_torch_held:
		torch_sys.free()
		return false

	torch_sys.equip_held_torch()
	if not torch_sys.is_torch_held or not torch_sys.is_torch_lit:
		torch_sys.free()
		return false
	if torch_sys._held_light == null:
		torch_sys.free()
		return false

	# Strict fillrate budget for Intel Iris Xe: Omni light must be shadow-free
	if torch_sys._held_light.shadow_enabled != false:
		torch_sys.free()
		return false
	if torch_sys._held_light.omni_range < 10.0 or torch_sys._held_light.light_energy <= 0.0:
		torch_sys.free()
		return false

	# Unequip torch
	torch_sys.unequip_held_torch()
	if torch_sys.is_torch_held:
		torch_sys.free()
		return false
	if torch_sys._held_light.visible:
		torch_sys.free()
		return false

	torch_sys.free()
	return true

func test_placed_torch_budget_and_culling() -> bool:
	var torch_sys: WildernessTorchSystem = WildernessTorchSystem.new()
	torch_sys._ready()
	torch_sys.position = Vector3(0.0, 1.0, 0.0)

	# Place 6 torches at staggered distances
	var positions: Array[Vector3] = [
		Vector3(0.0, 1.0, 0.0),
		Vector3(5.0, 1.0, 0.0),
		Vector3(12.0, 1.0, 0.0),
		Vector3(30.0, 1.0, 0.0),
		Vector3(55.0, 1.0, 0.0),
		Vector3(90.0, 1.0, 0.0)
	]
	for pos in positions:
		torch_sys.place_torch_at(pos)

	if torch_sys._placed_torches.size() != 6:
		torch_sys.free()
		return false

	# Force rebalance
	torch_sys._rebalance_light_budget()

	# Count active omni lights among placed torches
	var active_lights: int = 0
	for t_node in torch_sys._placed_torches:
		var omni: OmniLight3D = t_node.get_meta("omni_ref") as OmniLight3D
		if omni and omni.visible:
			active_lights += 1

	# Must strictly respect hardware budget (<= MAX_ACTIVE_PLACED_LIGHTS)
	if active_lights > WildernessTorchSystem.MAX_ACTIVE_PLACED_LIGHTS:
		torch_sys.free()
		return false
	if active_lights == 0:
		torch_sys.free()
		return false

	torch_sys.free()
	return true

func test_water_immersion_and_rain_extinguishment() -> bool:
	var torch_sys: WildernessTorchSystem = WildernessTorchSystem.new()
	torch_sys._ready()
	torch_sys.setup(null, null, null, null, null, 2.0)
	torch_sys.equip_held_torch()

	# Submerge below water level threshold (water is 2.0, threshold is 2.0 + 0.35 = 2.35)
	torch_sys.position = Vector3(0.0, 1.5, 0.0)
	torch_sys._process(0.1)

	if torch_sys.is_torch_lit:
		torch_sys.free()
		return false
	if torch_sys._held_light and torch_sys._held_light.visible:
		torch_sys.free()
		return false

	# Reignite in dry air
	torch_sys.position = Vector3(0.0, 5.0, 0.0)
	var reignited: bool = torch_sys.reignite_held_torch()
	if not reignited or not torch_sys.is_torch_lit:
		torch_sys.free()
		return false

	torch_sys.free()
	return true

func test_fauna_predator_fire_avoidance() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4444
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)
	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)

	var pred_id: int = fauna.spawn_predator(Vector3(10.0, 0.0, 10.0), 90.0)
	var pred = fauna.get_predator(pred_id)
	if pred == null:
		return false

	# Light placed at (12.0, 0.0, 10.0) -> distance 2.0m (< 10.0m deterrence radius)
	fauna.register_light_source(Vector3(12.0, 0.0, 10.0))
	fauna.step_simulation(0.1, flora, Callable())

	if not pred.is_deterred_by_fire:
		return false

	# Steering velocity must repel away from fire (predator at x=10, light at x=12 -> repel velocity.x < 0)
	if pred.velocity.x >= 0.0:
		return false

	# Move light source far away (> 10m)
	fauna.set_active_light_sources([Vector3(50.0, 0.0, 50.0)])
	fauna.step_simulation(0.1, flora, Callable())
	if pred.is_deterred_by_fire:
		return false

	return true

func test_ash_enrichment_environmental_grid() -> bool:
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(1337)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)
	grid.initialize_grid(Callable())

	var initial_env: Dictionary = grid.get_environment_at(10.0, 10.0)
	var initial_fert: float = initial_env.get("fertility", 1.0)

	var affected: int = grid.apply_ash_enrichment(10.0, 10.0, 6.0)
	if affected <= 0:
		return false

	var enriched_env: Dictionary = grid.get_environment_at(10.0, 10.0)
	var enriched_fert: float = enriched_env.get("fertility", 1.0)
	if enriched_fert <= initial_fert:
		return false

	var cell: Dictionary = grid.get_environment_at(10.0, 10.0)
	if not cell.get("charred_ash_active", false):
		return false

	return true

func test_flora_accelerated_regrowth_on_ash() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5555
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var cfg: WorldGenerationConfig = WorldGenerationConfig.new(1337)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(cfg)
	grid.initialize_grid(Callable())

	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)

	# Plant 1 on normal soil
	var pid1: int = flora.spawn_plant("shrub_bush", Vector3(20.0, 2.0, 20.0), 1.0)
	# Apply ash enrichment at (0.0, 0.0)
	grid.apply_ash_enrichment(0.0, 0.0, 5.0)
	# Plant 2 on ash enriched soil
	var pid2: int = flora.spawn_plant("shrub_bush", Vector3(0.0, 2.0, 0.0), 1.0)

	var p1 = flora.get_plant(pid1)
	var p2 = flora.get_plant(pid2)

	# Step flora simulation
	flora.step_simulation(2.0, grid)

	# Plant 2 on ash should have higher nutritional value from mineral enrichment
	if p2.nutritional_value <= p1.nutritional_value:
		return false

	# Test apply_fire_burn clears dry biomass and resets to sprout
	p2.biomass = 3.5
	var burned: int = flora.apply_fire_burn(Vector3(0.0, 2.0, 0.0), 3.0)
	if burned != 1:
		return false
	if p2.biomass > 0.5:
		return false

	return true

func test_herbivore_foraging_attraction_to_ash_glade() -> bool:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6666
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var flora: FloraSimulation = FloraSimulation.new(rng, null, metrics)

	# Plant A: standard plant at distance 12m
	var pidA: int = flora.spawn_plant("grass_patch", Vector3(12.0, 0.0, 0.0), 2.0)
	var pA = flora.get_plant(pidA)
	pA.nutritional_value = 1.0

	# Plant B: ash-enriched tender shoots at distance 14m (physically further, but high nutrition 1.35)
	var pidB: int = flora.spawn_plant("grass_patch", Vector3(14.0, 0.0, 0.0), 2.0)
	var pB = flora.get_plant(pidB)
	pB.nutritional_value = 1.35

	# Herbivore searches food from origin (0, 0, 0)
	var nearest = flora.find_nearest_food(Vector3.ZERO, 30.0)
	if nearest == null:
		return false

	# Due to distance weighting (14^2 / 1.6 = 122.5 < 12^2 = 144), Plant B is prioritized!
	if nearest.id != pidB:
		return false

	return true

func test_player_tool_controller_torch_integration() -> bool:

	var tool_ctrl: PlayerToolController = PlayerToolController.new()
	if not tool_ctrl.get_tool_name(PlayerToolController.ToolMode.TORCH).begins_with("Wilderness Torch"):
		tool_ctrl.free()
		return false
	if not tool_ctrl.is_area_tool(PlayerToolController.ToolMode.TORCH):
		tool_ctrl.free()
		return false

	tool_ctrl.set_tool(PlayerToolController.ToolMode.TORCH)
	if tool_ctrl.active_tool != PlayerToolController.ToolMode.TORCH:
		tool_ctrl.free()
		return false

	tool_ctrl.free()
	return true
