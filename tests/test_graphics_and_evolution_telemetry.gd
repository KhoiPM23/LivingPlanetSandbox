class_name TestGraphicsAndEvolutionTelemetry
extends RefCounted

## Automated contract verification for Graphics Scalability Presets (Low, Balanced, Cinematic)
## and Evolutionary Diversity Telemetry (Allele drift, variance, bottleneck warnings, species channels).

func run_all_tests() -> Dictionary:
	var results: Dictionary = {
		"total": 8,
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	_run_test("test_graphics_presets_switching_and_parameters", Callable(self, "test_graphics_presets_switching_and_parameters"), results)
	_run_test("test_cinematic_preset_switching_and_msaa", Callable(self, "test_cinematic_preset_switching_and_msaa"), results)
	_run_test("test_graphics_preset_config_persistence", Callable(self, "test_graphics_preset_config_persistence"), results)
	_run_test("test_evolution_telemetry_variance_and_diversity", Callable(self, "test_evolution_telemetry_variance_and_diversity"), results)
	_run_test("test_evolution_snapshot_recording", Callable(self, "test_evolution_snapshot_recording"), results)
	_run_test("test_iris_xe_balanced_workload_bounds", Callable(self, "test_iris_xe_balanced_workload_bounds"), results)
	_run_test("test_chart_multi_channel_and_empty_population_handling", Callable(self, "test_chart_multi_channel_and_empty_population_handling"), results)
	_run_test("test_species_trait_telemetry_isolation_and_demographics", Callable(self, "test_species_trait_telemetry_isolation_and_demographics"), results)

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
	if env_node.environment.fog_enabled != false:
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
	if env_node.environment.fog_enabled != true:
		root.free()
		return false
	if bal_changes.get("scaling_3d_scale", 1.0) != 0.85:
		root.free()
		return false

	# 3. Test High / Cinematic Preset
	var high_changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.HIGH, root)
	if sun.shadow_enabled != true:
		root.free()
		return false
	if env_node.environment.fog_enabled != true:
		root.free()
		return false
	if high_changes.get("scaling_3d_scale", 0.0) != 1.0:
		root.free()
		return false

	root.free()
	return true

func test_cinematic_preset_switching_and_msaa() -> bool:
	var root: Node3D = Node3D.new()

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	root.add_child(sun)

	var env_node: WorldEnvironment = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = Environment.new()
	root.add_child(env_node)

	var changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.CINEMATIC, root)
	if changes.get("scaling_3d_scale", 0.0) != 1.0:
		root.free()
		return false
	if changes.get("msaa_3d", Viewport.MSAA_DISABLED) != Viewport.MSAA_2X:
		root.free()
		return false
	if changes.get("shadow_enabled", false) != true:
		root.free()
		return false
	if changes.get("fog_enabled", false) != true:
		root.free()
		return false
	if sun.directional_shadow_max_distance < 100.0:
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

	# Test Cinematic preset save
	GraphicsPresets.save_to_config(GraphicsPresets.Preset.CINEMATIC, test_path)
	var loaded_cinematic: GraphicsPresets.Preset = GraphicsPresets.load_from_config(test_path)
	if loaded_cinematic != GraphicsPresets.Preset.CINEMATIC:
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

func test_chart_multi_channel_and_empty_population_handling() -> bool:
	var chart: EcosystemChart = EcosystemChart.new()
	chart.size = Vector2(300, 150)

	# 1. Mode cycling
	if chart.current_mode != EcosystemChart.ChartMode.POPULATION:
		chart.free()
		return false

	var mode2: EcosystemChart.ChartMode = chart.cycle_mode()
	if mode2 != EcosystemChart.ChartMode.TRAIT_MEANS:
		chart.free()
		return false

	var mode3: EcosystemChart.ChartMode = chart.cycle_mode()
	if mode3 != EcosystemChart.ChartMode.DISPERSION_DEMOGRAPHICS:
		chart.free()
		return false

	var mode_back: EcosystemChart.ChartMode = chart.cycle_mode()
	if mode_back != EcosystemChart.ChartMode.POPULATION:
		chart.free()
		return false

	# 2. Empty population safety (Extinct/Zero population)
	var empty_samples: Array = [
		{"biomass": 0.0, "herbivores": 0, "predators": 0, "avg_speed": 0.0, "pred_avg_speed": 0.0, "speed_var": 0.0},
		{"biomass": 0.0, "herbivores": 0, "predators": 0, "avg_speed": 0.0, "pred_avg_speed": 0.0, "speed_var": 0.0}
	]
	chart.update_history(empty_samples)
	chart.set_chart_mode(EcosystemChart.ChartMode.POPULATION)
	if not chart.get_mode_name().contains("Populations"):
		chart.free()
		return false

	chart.set_chart_mode(EcosystemChart.ChartMode.TRAIT_MEANS)
	if not chart.get_mode_name().contains("Trait Means"):
		chart.free()
		return false

	chart.set_chart_mode(EcosystemChart.ChartMode.DISPERSION_DEMOGRAPHICS)
	if not chart.get_mode_name().contains("Dispersion"):
		chart.free()
		return false

	chart.free()
	return true

func test_species_trait_telemetry_isolation_and_demographics() -> bool:
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	metrics.total_biomass = 45.2
	metrics.plant_count = 50
	metrics.herbivore_count = 12
	metrics.predator_count = 3
	metrics.avg_herbivore_speed = 1.18
	metrics.avg_herbivore_size = 1.05
	metrics.avg_herbivore_energy_efficiency = 1.10
	metrics.avg_predator_speed = 1.25
	metrics.avg_predator_size = 1.30
	metrics.avg_predator_energy_efficiency = 0.95
	metrics.allele_speed_variance = 0.035
	metrics.allele_size_variance = 0.022
	metrics.allele_efficiency_variance = 0.015
	metrics.survival_rate_herbivore = 0.88
	metrics.survival_rate_predator = 0.67
	metrics.births_total = 14
	metrics.deaths_total = 2

	metrics.sample_history()

	if metrics.history.size() != 1:
		return false

	var sample: Dictionary = metrics.history[0]
	if absf(float(sample.get("pred_avg_speed", 0.0)) - 1.25) > 0.01:
		return false
	if absf(float(sample.get("avg_speed", 0.0)) - 1.18) > 0.01:
		return false
	if absf(float(sample.get("pred_avg_eff", 0.0)) - 0.95) > 0.01:
		return false
	if absf(float(sample.get("avg_eff", 0.0)) - 1.10) > 0.01:
		return false
	if absf(float(sample.get("speed_var", 0.0)) - 0.035) > 0.005:
		return false
	if int(sample.get("births_total", 0)) != 14:
		return false
	if int(sample.get("deaths_total", 0)) != 2:
		return false

	return true
