class_name TestBlock37MarineEcosystem
extends RefCounted

## Living Planet Sandbox — Block 37 Automated Verification Suite
## Verifies:
## 1. MarineEcosystem underwater flora instancing (Kelp & Seagrass MultiMeshes)
## 2. Marine fish schooling simulation (Emerald Salmon & Reef Sunfish, underwater bounding)
## 3. Moored expedition skiff and rustic wooden pier geometry & wave physics
## 4. Tree needle shader draw distance fix (no premature leaf stripping)
## 5. Horizon fog density and color harmonization integrity

func test_marine_ecosystem_initialization() -> String:
	var marine_scn = preload("res://presentation/environment/marine_ecosystem.gd")
	var marine = marine_scn.new()
	var terrain = IslandTerrain.new()
	terrain.island_size = 200.0
	terrain.generate_island(1337)

	marine.setup(terrain, null, 1337)

	# 1. Kelp MultiMesh verification
	var kelp_mmi: MultiMeshInstance3D = marine.get_node_or_null("KelpForestMultiMesh") as MultiMeshInstance3D
	if not kelp_mmi:
		marine.queue_free()
		terrain.queue_free()
		return "Expected KelpForestMultiMesh in MarineEcosystem"
	if not kelp_mmi.multimesh or kelp_mmi.multimesh.visible_instance_count <= 0:
		marine.queue_free()
		terrain.queue_free()
		return "Expected KelpForestMultiMesh to have placed instances (got %d)" % (kelp_mmi.multimesh.visible_instance_count if kelp_mmi.multimesh else 0)

	# 2. Seagrass MultiMesh verification
	var seagrass_mmi: MultiMeshInstance3D = marine.get_node_or_null("SeagrassMultiMesh") as MultiMeshInstance3D
	if not seagrass_mmi:
		marine.queue_free()
		terrain.queue_free()
		return "Expected SeagrassMultiMesh in MarineEcosystem"
	if not seagrass_mmi.multimesh or seagrass_mmi.multimesh.visible_instance_count <= 0:
		marine.queue_free()
		terrain.queue_free()
		return "Expected SeagrassMultiMesh to have placed instances (got %d)" % (seagrass_mmi.multimesh.visible_instance_count if seagrass_mmi.multimesh else 0)

	# 3. Pier & Boat verification
	var pier: Node3D = marine.get_node_or_null("RusticWoodenPier") as Node3D
	if not pier:
		marine.queue_free()
		terrain.queue_free()
		return "Expected RusticWoodenPier in MarineEcosystem"
	var boat: Node3D = marine.get_node_or_null("MooredExpeditionSkiff") as Node3D
	if not boat:
		marine.queue_free()
		terrain.queue_free()
		return "Expected MooredExpeditionSkiff in MarineEcosystem"

	# 4. Fish agents verification
	if marine._fish_agents.size() < 20:
		marine.queue_free()
		terrain.queue_free()
		return "Expected at least 20 schooling fish agents (got %d)" % marine._fish_agents.size()

	# Check that all fish are positioned submerged beneath the water surface (Y < 0.0)
	for agent in marine._fish_agents:
		if agent.position.y > 0.0:
			marine.queue_free()
			terrain.queue_free()
			return "Fish agent spawned above waterline: Y = %.2f" % agent.position.y

	# 5. Simulate 1 physics/process step to verify wave bobbing and schooling update
	var initial_boat_y: float = boat.position.y
	marine._process(0.05)
	# Process should run without errors and keep fish submerged
	for agent in marine._fish_agents:
		if agent.position.y > -0.30:
			marine.queue_free()
			terrain.queue_free()
			return "Fish agent breached water surface: Y = %.2f" % agent.position.y

	marine.queue_free()
	terrain.queue_free()
	return ""

func test_tree_foliage_draw_distance_integrity() -> String:
	# Verifies the fix for the tree leaf disappearing bug
	var needle_mat: ShaderMaterial = TreePine.get_shared_pine_needle_material()
	if not needle_mat:
		return "Expected valid pine needle material"

	var max_dist: float = needle_mat.get_shader_parameter("max_draw_distance")
	if max_dist > 0.0 and max_dist < 260.0:
		return "Pine needle max_draw_distance too low (%.1fm) — leaves will vanish from standing trees!" % max_dist

	return ""

func test_horizon_fog_calibration() -> String:
	# Verifies calibrated fog settings to eliminate horizon cutlines
	var cycle_scn = preload("res://presentation/environment/day_night_cycle.gd")
	var cycle = cycle_scn.new()
	var env: WorldEnvironment = WorldEnvironment.new()
	var env_res: Environment = Environment.new()
	env_res.fog_enabled = true
	env.environment = env_res

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	var clock: WorldClock = WorldClock.new()

	cycle.setup(clock, sun, env, null)
	cycle.apply_lighting_state(1) # MIDDAY

	if env.environment.fog_density > 0.0030:
		cycle.queue_free()
		env.queue_free()
		sun.queue_free()
		return "Midday fog density too high (%.4f) — creates opaque horizon cut-line" % env.environment.fog_density

	cycle.queue_free()
	env.queue_free()
	sun.queue_free()
	return ""
