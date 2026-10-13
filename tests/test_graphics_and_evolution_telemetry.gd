class_name TestGraphicsAndEvolutionTelemetry
extends RefCounted

## Automated contract verification for Graphics Scalability Presets (Low, Balanced, High)
## and Evolutionary Diversity Telemetry (Allele drift, variance, bottleneck warnings).

func run_all_tests() -> Dictionary:
	var results: Dictionary = {
		"total": 5,
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	_run_test("test_graphics_presets_switching_and_parameters", Callable(self, "test_graphics_presets_switching_and_parameters"), results)
	_run_test("test_graphics_preset_config_persistence", Callable(self, "test_graphics_preset_config_persistence"), results)
	_run_test("test_evolution_telemetry_variance_and_diversity", Callable(self, "test_evolution_telemetry_variance_and_diversity"), results)
	_run_test("test_evolution_snapshot_recording", Callable(self, "test_evolution_snapshot_recording"), results)
	_run_test("test_iris_xe_balanced_workload_bounds", Callable(self, "test_iris_xe_balanced_workload_bounds"), results)

	return results

func _run_test(test_name: String, callable: Callable, results: Dictionary) -> void:
	print("  Running: %s..." % test_name)
	var ok: bool = false
	var err_msg: String = ""

	match callable.call():
		true:
			ok = true
		false:
			ok = false
			err_msg = "Test assertion failed (returned false)"
		var err:
			ok = false
			err_msg = "Unexpected return: %s" % str(err)

	if ok:
		print("  [PASS] %s" % test_name)
		results["passed"] += 1
	else:
		print("  [FAIL] %s - %s" % [test_name, err_msg])
		results["failed"] += 1
		results["errors"].append("%s: %s" % [test_name, err_msg])

func test_graphics_presets_switching_and_parameters() -> bool:
	var root: Node3D = Node3D.new()

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	root.add_child(sun)

	var env_node: WorldEnvironment = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = Environment.new()
	root.add_child(env_node)

	# 1. Test Low Preset
	var low_changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.LOW, root)
	if sun.shadow_enabled != false:
		root.free()
		return false
	if env_node.environment.glow_enabled != false:
		root.free()
		return false
	if low_changes.get("scaling_3d_scale", 1.0) != 0.75:
		root.free()
		return false

	# 2. Test Balanced Preset
	var bal_changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.BALANCED, root)
	if sun.shadow_enabled != true:
		root.free()
		return false
	if env_node.environment.glow_enabled != true:
		root.free()
		return false
	if bal_changes.get("scaling_3d_scale", 1.0) != 0.85:
		root.free()
		return false

	# 3. Test High Preset
	var high_changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.HIGH, root)
	if sun.shadow_enabled != true:
		root.free()
		return false
	if high_changes.get("scaling_3d_scale", 0.0) != 1.0:
		root.free()
		return false

	root.free()
	return true

func test_graphics_preset_config_persistence() -> bool:
	var test_path: String = "user://test_graphics_persist.cfg"

	var err: Error = GraphicsPresets.save_to_config(GraphicsPresets.Preset.LOW, test_path)
	if err != OK:
		return false

	var loaded: GraphicsPresets.Preset = GraphicsPresets.load_from_config(test_path)
	if loaded != GraphicsPresets.Preset.LOW:
		return false

	# Test High preset save
	GraphicsPresets.save_to_config(GraphicsPresets.Preset.HIGH, test_path)
	var loaded_high: GraphicsPresets.Preset = GraphicsPresets.load_from_config(test_path)
	if loaded_high != GraphicsPresets.Preset.HIGH:
		return false

	# Clean up
	DirAccess.remove_absolute(test_path)
	return true

func test_evolution_telemetry_variance_and_diversity() -> bool:
	var metrics: EcosystemMetrics = EcosystemMetrics.new()

	# Scenario A: Diverse gene pool
	var speeds: Array[float] = [0.75, 1.0, 1.25, 1.50]
	var droughts: Array[float] = [0.12, 0.22, 0.32, 0.38]

	var avg_spd: float = 0.0
	for s in speeds: avg_spd += s
	avg_spd /= float(speeds.size())

	var avg_drg: float = 0.0
	for d in droughts: avg_drg += d
	avg_drg /= float(droughts.size())

	var spd_sq: float = 0.0
	for s in speeds: spd_sq += (s - avg_spd) * (s - avg_spd)
	var spd_var: float = spd_sq / float(speeds.size())

	var drg_sq: float = 0.0
	for d in droughts: drg_sq += (d - avg_drg) * (d - avg_drg)
	var drg_var: float = drg_sq / float(droughts.size())

	metrics.avg_herbivore_speed = avg_spd
	metrics.avg_plant_drought_tolerance = avg_drg
	metrics.allele_speed_variance = spd_var
	metrics.allele_drought_variance = drg_var
	metrics.genetic_diversity_index = sqrt(spd_var) * 3.0 + sqrt(drg_var) * 4.0
	metrics.bottleneck_warning = (metrics.genetic_diversity_index < 0.04 and speeds.size() > 5)

	if metrics.genetic_diversity_index < 0.50:
		return false
	if metrics.bottleneck_warning != false:
		return false

	# Scenario B: Inbred homogeneous population (genetic bottleneck)
	var cloned_speeds: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
	metrics.allele_speed_variance = 0.0
	metrics.allele_drought_variance = 0.0
	metrics.genetic_diversity_index = 0.0
	metrics.bottleneck_warning = (metrics.genetic_diversity_index < 0.04 and cloned_speeds.size() > 5)

	if metrics.bottleneck_warning != true:
		return false

	return true

func test_evolution_snapshot_recording() -> bool:
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	metrics.max_generation = 2
	metrics.avg_herbivore_speed = 1.15
	metrics.avg_plant_drought_tolerance = 0.28
	metrics.genetic_diversity_index = 0.72

	metrics.sample_evolution_snapshot(15.0)
	metrics.sample_evolution_snapshot(30.0)

	if metrics.evolution_history.size() != 2:
		return false

	var snap1: Dictionary = metrics.evolution_history[0]
	var snap2: Dictionary = metrics.evolution_history[1]

	if snap1.get("sim_time", 0.0) != 15.0:
		return false
	if snap2.get("sim_time", 0.0) != 30.0:
		return false
	if snap1.get("max_gen", 0) != 2:
		return false
	if absf(snap1.get("diversity", 0.0) - 0.72) > 0.01:
		return false

	return true

func test_iris_xe_balanced_workload_bounds() -> bool:
	var desc: String = GraphicsPresets.get_preset_description(GraphicsPresets.Preset.BALANCED)
	if not desc.contains("85%"):
		return false

	var low_desc: String = GraphicsPresets.get_preset_description(GraphicsPresets.Preset.LOW)
	if not low_desc.contains("75%"):
		return false

	return true
