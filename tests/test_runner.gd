extends SceneTree

## Standalone Headless Test Runner for Living Planet Sandbox core contracts.

var _passed_count: int = 0
var _failed_count: int = 0

func _init() -> void:
	print("\n=======================================================")
	print("   LIVING PLANET SANDBOX — AUTOMATED CONTRACT TESTS   ")
	print("=======================================================\n")

	run_all_tests()

	print("\n-------------------------------------------------------")
	print("TEST RESULTS: Passed: %d | Failed: %d" % [_passed_count, _failed_count])
	print("-------------------------------------------------------")

	var exit_code: int = 0 if _failed_count == 0 else 1
	quit(exit_code)

func run_all_tests() -> void:
	_run_suite("WorldSeed", preload("res://tests/test_world_seed.gd").new())
	_run_suite("WorldClock", preload("res://tests/test_world_clock.gd").new())
	_run_suite("WorldEventBus", preload("res://tests/test_world_event_bus.gd").new())
	_run_suite("EntityRegistry", preload("res://tests/test_entity_registry.gd").new())
	_run_suite("WorldPersistence", preload("res://tests/test_world_persistence.gd").new())
	_run_suite("TestPlayableWorld", preload("res://tests/test_playable_world.gd").new())
	_run_suite("TestEnvironmentSystems", preload("res://tests/test_environment_systems.gd").new())
	_run_suite("TestCausalEcosystem", preload("res://tests/test_causal_ecosystem.gd").new())
	_run_suite("TestExperimentToolsAndPersistence", preload("res://tests/test_experiment_tools_and_persistence.gd").new())
	_run_suite("TestStabilityAndRegression", preload("res://tests/test_stability_and_regression.gd").new())
	_run_suite("TestVisualPolishAndUX", preload("res://tests/test_visual_polish_and_ux.gd").new())
	_run_suite("TestCameraExploration", preload("res://tests/test_camera_exploration.gd").new())
	_run_suite("TestGeneticsAndSelection", preload("res://tests/test_genetics_and_selection.gd").new())
	_run_suite("TestWeatherAndSurface", preload("res://tests/test_weather_and_surface.gd").new())
	_run_suite("TestGraphicsAndEvolutionTelemetry", preload("res://tests/test_graphics_and_evolution_telemetry.gd").new())
	_run_suite("TestCausalExperimentTools", preload("res://tests/test_causal_experiment_tools.gd").new())
	_run_suite("TestFoliageOpacityRegression", preload("res://tests/test_foliage_opacity_regression.gd").new())
	_run_suite("TestEcosystemBehaviorAcceptance", preload("res://tests/test_ecosystem_behavior_acceptance.gd").new())




func _run_suite(suite_name: String, suite: Object) -> void:
	print(">>> RUNNING SUITE: %s" % suite_name)
	for method_dict: Dictionary in suite.get_method_list():
		var method_name: String = method_dict["name"]
		if method_name.begins_with("test_"):
			try_run_test(suite, method_name)
	print("")

func try_run_test(suite: Object, method_name: String) -> void:
	var result: Variant = suite.call(method_name)
	var passed: bool = false
	if result == null:
		passed = true
	elif result is bool and result == true:
		passed = true
	elif result is String and (result as String).is_empty():
		passed = true

	if passed:
		_passed_count += 1
		print("  [PASS] %s" % method_name)
	else:
		_failed_count += 1
		print("  [FAIL] %s -> %s" % [method_name, str(result)])
