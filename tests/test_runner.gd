extends SceneTree

## Standalone Headless Test Runner for Living Planet Sandbox core contracts.

var _passed_count: int = 0
var _failed_count: int = 0
var _log_file: FileAccess = null

func _log(msg: String) -> void:
	print(msg)
	if _log_file:
		_log_file.store_line(msg)
		_log_file.flush()

func _init() -> void:
	_log_file = FileAccess.open("res://reports/test_results.txt", FileAccess.WRITE)
	_log("\n=======================================================")
	_log("   LIVING PLANET SANDBOX — AUTOMATED CONTRACT TESTS   ")
	_log("=======================================================\n")

	run_all_tests()

	_log("\n-------------------------------------------------------")
	_log("TEST RESULTS: Passed: %d | Failed: %d" % [_passed_count, _failed_count])
	_log("-------------------------------------------------------")

	if _log_file:
		_log_file.close()

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
	_run_suite("TestLivingWorldDirector", preload("res://tests/test_living_world_director.gd").new())
	_run_suite("TestLivingWorldScenarios", preload("res://tests/test_living_world_scenarios.gd").new())
	_run_suite("TestBlock12Verification", preload("res://tests/test_block12_verification.gd").new())
	_run_suite("TestBlock1314Verification", preload("res://tests/test_block13_14_verification.gd").new())
	_run_suite("TestBlock15Verification", preload("res://tests/test_block15_verification.gd").new())
	_run_suite("TestBlock16Verification", preload("res://tests/test_block16_verification.gd").new())
	_run_suite("TestBlock17Verification", preload("res://tests/test_block17_verification.gd").new())
	_run_suite("TestBlock18Verification", preload("res://tests/test_block18_verification.gd").new())
	_run_suite("TestBlock19Verification", preload("res://tests/test_block19_verification.gd").new())
	_run_suite("TestBlock22Verification", preload("res://tests/test_block22_verification.gd").new())
	_run_suite("TestBlock23Verification", preload("res://tests/test_block23_verification.gd").new())
	_run_suite("TestBlock23Addendum", preload("res://tests/test_block23_addendum.gd").new())
	_run_suite("TestBlock24Immersion", preload("res://tests/test_block24_immersion.gd").new())
	_run_suite("TestBlock25RC", preload("res://tests/test_block25_rc.gd").new())
	_run_suite("TestBlock26WorldGeneration", preload("res://tests/test_block26_world_generation.gd").new())
	_run_suite("TestBlock27EmergentGameplay", preload("res://tests/test_block27_emergent_gameplay.gd").new())
	_run_suite("TestBlock28ReleaseLoop", preload("res://tests/test_block28_release_loop.gd").new())
	_run_suite("TestBlock29CameraAndQuests", preload("res://tests/test_block29_camera_and_quests.gd").new())
	_run_suite("TestBlock30HeatmapsAndFilters", preload("res://tests/test_block30_heatmaps_and_filters.gd").new())
	_run_suite("TestBlock31SeasonalPhenologyAndForaging", preload("res://tests/test_block31_seasonal_phenology_and_foraging.gd").new())
	_run_suite("TestBlock32ParabolicMicrophoneAndAcoustics", preload("res://tests/test_block32_parabolic_microphone_and_acoustics.gd").new())
	_run_suite("TestBlock33HydrologicalPuddlesAndSnow", preload("res://tests/test_block33_hydrological_puddles_and_snow.gd").new())
	_run_suite("TestBlock34WildernessToolsAndChainReactions", preload("res://tests/test_block34_wilderness_tools_and_chain_reactions.gd").new())
	_run_suite("TestBlock35PolishCampfiresHotbarAndSanctuaries", preload("res://tests/test_block35_polish_campfires_hotbar_and_sanctuaries.gd").new())
	_run_suite("TestBlock36SurvivalShelterForagingAndShowcase", preload("res://tests/test_block36_survival_shelter_foraging_and_showcase.gd").new())
	_run_suite("TestBlock37MarineEcosystem", preload("res://tests/test_block37_marine_ecosystem.gd").new())
	_run_suite("TestBlock38OpenWorldRPG", preload("res://tests/test_block38_open_world_rpg.gd").new())
	_run_suite("TestBlock39CastleAlchemyMarine", preload("res://tests/test_block39_castle_alchemy_marine.gd").new())
	_run_suite("TestBlock42CatacombsFishingEconomy", preload("res://tests/test_block42_catacombs_fishing_economy.gd").new())
	_run_suite("TestBlock46GliderCompendium", preload("res://tests/test_block46_glider_compendium.gd").new())
	_run_suite("TestBlock47FoliageFogAndMarineExpansion", preload("res://tests/test_block47_foliage_fog_and_marine_expansion.gd").new())
	_run_suite("TestBlock48InteractivePromptsAndForaging", preload("res://tests/test_block48_interactive_prompts_and_foraging.gd").new())
	_run_suite("TestBlock49VillageBlacksmithAndCastleLife", preload("res://tests/test_block49_village_blacksmith_and_castle_life.gd").new())
	_run_suite("TestBlock63AnimeARPGController", preload("res://tests/test_block63_anime_arpg_controller.gd").new())
	_run_suite("TestBlock64ElementalReactionsAndFauna", preload("res://tests/test_block64_elemental_reactions_and_fauna.gd").new())
	_run_suite("TestBlock65Phase5VisualAndAcousticOverhaul", preload("res://tests/test_block65_phase5_visual_and_acoustic_overhaul.gd").new())
	_run_suite("TestBlock66CanonicalWorldAndPerspective", preload("res://tests/test_block66_canonical_world_and_perspective.gd").new())
	_run_suite("TestBlock67CombatCharacterAndSkyspireQuest", preload("res://tests/test_block67_combat_character_and_skyspire_quest.gd").new())
	_run_suite("TestDouyinGoldenRatio", preload("res://tests/test_douyin_golden_ratio.gd").new())
	_run_suite("TestBlock68AAAGameFeelAndWardrobe", preload("res://tests/test_block68_aaa_game_feel_and_wardrobe.gd").new())

func _run_suite(suite_name: String, suite: Object) -> void:
	_log(">>> RUNNING SUITE: %s" % suite_name)
	for method_dict: Dictionary in suite.get_method_list():
		var method_name: String = method_dict["name"]
		if method_name.begins_with("test_"):
			try_run_test(suite, method_name)
	_log("")

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
		_log("  [PASS] %s" % method_name)
	else:
		_failed_count += 1
		_log("  [FAIL] %s -> %s" % [method_name, str(result)])
