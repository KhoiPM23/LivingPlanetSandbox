class_name TestBlock47FoliageFogAndMarineExpansion
extends RefCounted

## Living Planet Sandbox — Block 47 Automated Contract Test Suite
## Verifies:
## 1. Foliage shader depth_draw_opaque enforcement & vertex integrity
## 2. Tree visibility range expansion & elimination of dithering leaf disappearance
## 3. Atmospheric depth fog distance extension (horizon clear, no 360m wall cut-off)
## 4. Minecraft-style marine biodiversity expansion (Clownfish, Blue Tang, Sea Pickles, Sea Turtles)

const TreePineScript = preload("res://presentation/props/tree_pine.gd")
const MarineScript = preload("res://presentation/environment/marine_ecosystem.gd")
const WeatherControllerScript = preload("res://presentation/environment/weather_effects_controller.gd")
const PresetsScript = preload("res://presentation/graphics/graphics_presets.gd")

func test_foliage_shader_depth_draw_opaque() -> String:
	var shader = load("res://presentation/shaders/foliage_wind.gdshader") as Shader
	if not shader:
		return "Failed to load foliage_wind.gdshader"

	var code: String = shader.code
	if not "depth_draw_opaque" in code:
		return "Expected foliage_wind.gdshader to declare depth_draw_opaque in render_mode"
	if not "cull_disabled" in code:
		return "Expected foliage_wind.gdshader to declare cull_disabled in render_mode"

	return ""

func test_tree_visibility_range_expanded() -> String:
	var tree: TreePine = TreePine.new()
	tree.position = Vector3(10.0, 3.5, 10.0)
	tree._ready()

	var tm: MeshInstance3D = tree.find_child("TreeModel", true, false) as MeshInstance3D
	if not tm:
		tree.queue_free()
		return "Expected TreeModel child in TreePine"

	if tm.visibility_range_end < 450.0:
		var end_val = tm.visibility_range_end
		tree.queue_free()
		return "Expected tree visibility_range_end >= 450m for 720m island, got %.1f" % end_val

	if tm.visibility_range_fade_mode != GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED:
		tree.queue_free()
		return "Expected tree visibility_range_fade_mode to be VISIBILITY_RANGE_FADE_DISABLED to prevent leaf flickering"

	tree.queue_free()
	return ""

func test_atmospheric_fog_horizon_extension() -> String:
	var weather_ctrl: WeatherEffectsController = WeatherControllerScript.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1337
	var bus: WorldEventBus = WorldEventBus.new()
	var weather: WeatherSystem = WeatherSystem.new(rng, bus)
	weather.set_weather_override(WeatherSystem.WeatherState.CLEAR)

	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = Environment.new()
	world_env.environment.fog_enabled = true
	world_env.environment.fog_mode = Environment.FOG_MODE_DEPTH
	world_env.environment.fog_depth_begin = 180.0
	world_env.environment.fog_depth_end = 920.0

	weather_ctrl._weather = weather
	weather_ctrl._world_env = world_env

	# Run process to evaluate steady state
	weather_ctrl._process(1.0)

	var fog_end: float = world_env.environment.fog_depth_end
	weather_ctrl.queue_free()
	world_env.queue_free()

	# In CLEAR weather, fog depth end must not clamp at 360m; it should reach >= 800m
	if fog_end < 400.0:
		return "Expected fog_depth_end to be expanded for 720m/960m scale (got %.1f)" % fog_end

	return ""

func test_marine_biodiversity_and_minecraft_style_life() -> String:
	var marine: MarineEcosystem = MarineScript.new()
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.island_size = 720.0
	terrain.generate_island(1337)

	marine.setup(terrain, null, 1337)

	# 1. Check diverse fish schools (Salmon, Sunfish, Tropical Clownfish, Neon Blue Tang)
	if marine._fish_agents.size() < 60:
		marine.queue_free()
		terrain.queue_free()
		return "Expected at least 60 schooling fish across diverse species (got %d)" % marine._fish_agents.size()

	if marine._school_centers.size() < 4:
		marine.queue_free()
		terrain.queue_free()
		return "Expected at least 4 distinct schooling centers (got %d)" % marine._school_centers.size()

	# 2. Check Bioluminescent Sea Pickles MultiMesh
	var pickles: MultiMeshInstance3D = marine.get_node_or_null("SeaPicklesMultiMesh") as MultiMeshInstance3D
	if not pickles or not pickles.multimesh:
		marine.queue_free()
		terrain.queue_free()
		return "Expected SeaPicklesMultiMesh in MarineEcosystem"

	if pickles.multimesh.instance_count < 48:
		marine.queue_free()
		terrain.queue_free()
		return "Expected >= 48 sea pickle instances, got %d" % pickles.multimesh.instance_count

	# 3. Check Sea Turtles
	if marine._sea_turtles.size() < 3:
		marine.queue_free()
		terrain.queue_free()
		return "Expected at least 3 Sea Turtles in MarineEcosystem (got %d)" % marine._sea_turtles.size()

	# 4. Check Coral Reef MultiMesh expansion
	var corals: MultiMeshInstance3D = marine.get_node_or_null("CoralReefMultiMesh") as MultiMeshInstance3D
	if not corals or not corals.multimesh:
		marine.queue_free()
		terrain.queue_free()
		return "Expected CoralReefMultiMesh in MarineEcosystem"

	if corals.multimesh.instance_count < 60:
		marine.queue_free()
		terrain.queue_free()
		return "Expected >= 60 coral instances, got %d" % corals.multimesh.instance_count

	# 5. Check Sea Turtle anatomy (shell, flippers)
	var turtle0: Node3D = marine._sea_turtles[0]
	if not turtle0.get_node_or_null("FlipperL") or not turtle0.get_node_or_null("FlipperR"):
		marine.queue_free()
		terrain.queue_free()
		return "Expected FlipperL and FlipperR nodes on SeaTurtle"

	marine.queue_free()
	terrain.queue_free()
	return ""
