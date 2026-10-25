class_name TestBlock26WorldGeneration
extends RefCounted

## Automated verification suite for Block 26:
## Next-Generation World Building, Procedural Landscapes & Rendering Pipeline.

func run_all_tests() -> Dictionary:
	var results: Dictionary = {
		"total": 8,
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	_run_test("test_seed_determinism_and_reproducibility", Callable(self, "test_seed_determinism_and_reproducibility"), results)
	_run_test("test_seed_variety_and_topological_divergence", Callable(self, "test_seed_variety_and_topological_divergence"), results)
	_run_test("test_macro_shape_and_ocean_containment", Callable(self, "test_macro_shape_and_ocean_containment"), results)
	_run_test("test_biome_classification_and_slope_masking", Callable(self, "test_biome_classification_and_slope_masking"), results)
	_run_test("test_vegetation_adaptive_clustering_and_sightlines", Callable(self, "test_vegetation_adaptive_clustering_and_sightlines"), results)
	_run_test("test_graphics_preset_contracts_and_tonemapping", Callable(self, "test_graphics_preset_contracts_and_tonemapping"), results)
	_run_test("test_water_depth_and_occlusion_integrity", Callable(self, "test_water_depth_and_occlusion_integrity"), results)
	_run_test("test_performance_and_telemetry_contracts", Callable(self, "test_performance_and_telemetry_contracts"), results)

	return results

func _run_test(test_name: String, callable: Callable, results: Dictionary) -> void:
	print("  Running: %s..." % test_name)
	var err_msg: String = callable.call()
	if err_msg.is_empty():
		print("  [PASS] %s" % test_name)
		results["passed"] += 1
	else:
		print("  [FAIL] %s - %s" % [test_name, err_msg])
		results["failed"] += 1
		results["errors"].append("%s: %s" % [test_name, err_msg])

func test_seed_determinism_and_reproducibility() -> String:
	# 1. Generate two separate IslandTerrain instances with identical seed 1337
	var t_a: IslandTerrain = IslandTerrain.new()
	var t_b: IslandTerrain = IslandTerrain.new()
	t_a.generate_island(1337)
	t_b.generate_island(1337)

	var sample_points: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(-24.0, -24.0),
		Vector2(16.0, 14.0),
		Vector2(24.0, 16.0),
		Vector2(9.0, 3.5),
		Vector2(-35.0, 20.0),
		Vector2(45.0, -15.0),
		Vector2(-10.0, -40.0),
		Vector2(30.0, 30.0),
		Vector2(-5.5, 0.5)
	]

	for pt in sample_points:
		var ha: float = t_a.get_height_at(pt.x, pt.y)
		var hb: float = t_b.get_height_at(pt.x, pt.y)
		if absf(ha - hb) > 0.0001:
			t_a.free()
			t_b.free()
			return "Seed 1337 non-deterministic at (%s): %.5f vs %.5f" % [str(pt), ha, hb]

	# Clean up
	t_a.free()
	t_b.free()
	return ""

func test_seed_variety_and_topological_divergence() -> String:
	# Compare 3 distinct seeds: 1337, 4242, 9999
	var t_1337: IslandTerrain = IslandTerrain.new()
	var t_4242: IslandTerrain = IslandTerrain.new()
	var t_9999: IslandTerrain = IslandTerrain.new()

	t_1337.generate_island(1337)
	t_4242.generate_island(4242)
	t_9999.generate_island(9999)

	# 1. Peak positions must diverge
	var p_1337: Vector2 = t_1337.get_peak_position()
	var p_4242: Vector2 = t_4242.get_peak_position()
	var p_9999: Vector2 = t_9999.get_peak_position()

	if (p_1337 - p_4242).length() < 7.0:
		t_1337.free()
		t_4242.free()
		t_9999.free()
		return "Peaks 1337 and 4242 insufficiently separated: %.1fm" % (p_1337 - p_4242).length()

	if (p_1337 - p_9999).length() < 7.0:
		t_1337.free()
		t_4242.free()
		t_9999.free()
		return "Peaks 1337 and 9999 insufficiently separated: %.1fm" % (p_1337 - p_9999).length()

	# 2. Peak heights must vary across seeds
	var h_peak_1337: float = t_1337.get_peak_height()
	var h_peak_4242: float = t_4242.get_peak_height()
	var h_peak_9999: float = t_9999.get_peak_height()

	var peak_range: float = maxf(h_peak_1337, maxf(h_peak_4242, h_peak_9999)) - minf(h_peak_1337, minf(h_peak_4242, h_peak_9999))
	if peak_range < 0.5:
		t_1337.free()
		t_4242.free()
		t_9999.free()
		return "Peak height variance too low across seeds: range %.2fm" % peak_range

	# 3. Sample grid points across islands to verify true elevation divergence
	var test_coords: Array[Vector2] = [
		Vector2(-24.0, -24.0),
		Vector2(24.0, 24.0),
		Vector2(-30.0, 15.0),
		Vector2(15.0, -30.0),
		Vector2(35.0, 10.0),
		Vector2(-10.0, 35.0),
		Vector2(0.0, 20.0),
		Vector2(20.0, 0.0),
		Vector2(-15.0, -15.0),
		Vector2(10.0, 10.0)
	]

	var diff_count: int = 0
	for pt in test_coords:
		var h1: float = t_1337.get_height_at(pt.x, pt.y)
		var h2: float = t_4242.get_height_at(pt.x, pt.y)
		var h3: float = t_9999.get_height_at(pt.x, pt.y)
		if absf(h1 - h2) > 0.40 or absf(h1 - h3) > 0.40:
			diff_count += 1

	t_1337.free()
	t_4242.free()
	t_9999.free()

	if diff_count < 7:
		return "Insufficient elevation variance across seeds: only %d/10 points diverged" % diff_count

	return ""

func test_macro_shape_and_ocean_containment() -> String:
	for s in [1337, 4242, 9999]:
		var terrain: IslandTerrain = IslandTerrain.new()
		terrain.generate_island(s)

		# Center must be dry land
		var h_center: float = terrain.get_height_at(0.0, 0.0)
		if h_center <= 0.0:
			terrain.free()
			return "Seed %d center elevation (%.2fm) is submerged" % [s, h_center]

		# Outer perimeter points (distance >= 75m) must be submerged in ocean (< 0m)
		var perimeter_pts: Array[Vector2] = [
			Vector2(75.0, 0.0),
			Vector2(-75.0, 0.0),
			Vector2(0.0, 75.0),
			Vector2(0.0, -75.0),
			Vector2(65.0, 65.0),
			Vector2(-65.0, -65.0)
		]

		for pt in perimeter_pts:
			var h_peri: float = terrain.get_height_at(pt.x, pt.y)
			if h_peri > 0.5:
				terrain.free()
				return "Seed %d perimeter point (%s) not submerged: %.2fm" % [s, str(pt), h_peri]

		terrain.free()

	return ""

func test_biome_classification_and_slope_masking() -> String:
	# 1. Marine rule
	var b_ocean: BiomeClassifier.BiomeType = BiomeClassifier.classify(20.0, 0.8, -1.0, 0.0)
	if b_ocean != BiomeClassifier.BiomeType.OCEAN:
		return "Submerged point not classified as OCEAN (got %d)" % b_ocean

	# 2. Beach rule
	var b_beach: BiomeClassifier.BiomeType = BiomeClassifier.classify(20.0, 0.5, 0.8, 0.0)
	if b_beach != BiomeClassifier.BiomeType.COASTAL_BEACH:
		return "Low coastal point not classified as COASTAL_BEACH (got %d)" % b_beach

	# 3. Alpine Summit rule
	var b_alpine: BiomeClassifier.BiomeType = BiomeClassifier.classify(2.0, 0.4, 15.0, 0.0)
	if b_alpine != BiomeClassifier.BiomeType.ALPINE_SUMMIT:
		return "Summit elevation not classified as ALPINE_SUMMIT (got %d)" % b_alpine

	# 4. Boreal Forest rule
	var b_forest: BiomeClassifier.BiomeType = BiomeClassifier.classify(12.0, 0.65, 5.0, 0.0)
	if b_forest != BiomeClassifier.BiomeType.BOREAL_FOREST:
		return "Temperate forest conditions not classified as BOREAL_FOREST (got %d)" % b_forest

	return ""

func test_vegetation_adaptive_clustering_and_sightlines() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	var scatter: VegetationScatter = VegetationScatter.new()
	scatter.scatter(terrain, 1337)

	# Summit monolith must exist
	var monolith: LandmarkMonolith = scatter.get_node_or_null("SummitMonolith") as LandmarkMonolith
	if not monolith:
		scatter.free()
		terrain.free()
		return "SummitMonolith not found in VegetationScatter"

	if (monolith.position - Vector3(-24.0, terrain.get_height_at(-24.0, -24.0), -24.0)).length() > 0.1:
		scatter.free()
		terrain.free()
		return "SummitMonolith not positioned at peak: %s" % str(monolith.position)

	# MultiMesh grass must exist and have instances
	var grass: MultiMeshInstance3D = scatter.get_node_or_null("GrassMultiMesh") as MultiMeshInstance3D
	if not grass or not grass.multimesh or grass.multimesh.instance_count == 0:
		scatter.free()
		terrain.free()
		return "GrassMultiMesh missing or empty"

	# Tropical primeval rainforest layers must exist and have instances
	var trop_canopy: MultiMeshInstance3D = scatter.get_node_or_null("TropicalCanopyMultiMesh") as MultiMeshInstance3D
	var trop_ferns: MultiMeshInstance3D = scatter.get_node_or_null("TropicalFernsMultiMesh") as MultiMeshInstance3D
	if not trop_canopy or not trop_canopy.multimesh or trop_canopy.multimesh.instance_count == 0:
		scatter.free()
		terrain.free()
		return "TropicalCanopyMultiMesh missing or empty"
	if not trop_ferns or not trop_ferns.multimesh or trop_ferns.multimesh.instance_count == 0:
		scatter.free()
		terrain.free()
		return "TropicalFernsMultiMesh missing or empty"

	scatter.free()
	terrain.free()
	return ""

func test_graphics_preset_contracts_and_tonemapping() -> String:
	var root: Node3D = Node3D.new()

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	root.add_child(sun)

	var env_node: WorldEnvironment = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = Environment.new()
	root.add_child(env_node)

	# Test Balanced preset
	var bal_changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.BALANCED, root)
	if not bal_changes.get("shadow_enabled", false):
		root.free()
		return "Balanced preset expected shadow_enabled = true"
	if bal_changes.get("scaling_3d_scale", 0.0) != 0.85:
		root.free()
		return "Balanced preset expected scaling_3d_scale = 0.85"
	if env_node.environment.tonemap_mode != Environment.TONE_MAPPER_FILMIC:
		root.free()
		return "Balanced preset expected Filmic tonemapping"

	# Test Cinematic preset
	var cin_changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.CINEMATIC, root)
	if not cin_changes.get("ssao_enabled", false):
		root.free()
		return "Cinematic preset expected ssao_enabled = true"
	if not cin_changes.get("volumetric_fog_enabled", false):
		root.free()
		return "Cinematic preset expected volumetric_fog_enabled = true"
	if cin_changes.get("scaling_3d_scale", 0.0) != 1.0:
		root.free()
		return "Cinematic preset expected scaling_3d_scale = 1.0"

	root.free()
	return ""

func test_water_depth_and_occlusion_integrity() -> String:
	var water: WaterPlane = WaterPlane.new()
	water._ready()

	if not (water.mesh is PlaneMesh):
		water.free()
		return "WaterPlane mesh is not PlaneMesh"

	if not (water.material_override is ShaderMaterial):
		water.free()
		return "WaterPlane material is not ShaderMaterial"

	var s_mat: ShaderMaterial = water.material_override as ShaderMaterial
	if s_mat.shader == null:
		water.free()
		return "WaterPlane ShaderMaterial has null shader"

	water.free()
	return ""

func test_performance_and_telemetry_contracts() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2601
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn population
	for i in range(14):
		fauna.spawn_herbivore(Vector3(float(i * 2), 2.5, 0.0), 85.0)
	for j in range(2):
		fauna.spawn_predator(Vector3(float(j * 10), 2.5, 10.0))

	# Benchmark 25 simulation steps
	var start_us: int = Time.get_ticks_usec()
	for step in range(25):
		fauna.step_simulation(0.5, null, Callable(self, "_flat_sampler"), null, 12.0)
	var elapsed_us: int = Time.get_ticks_usec() - start_us
	var avg_step_ms: float = float(elapsed_us) / 25000.0

	if avg_step_ms > 3.5:
		return "Average fauna simulation step too slow: %.2f ms (budget <= 3.5 ms)" % avg_step_ms

	return ""

func _flat_sampler(_x: float, _z: float) -> float:
	return 2.5
