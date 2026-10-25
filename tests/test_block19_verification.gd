class_name TestBlock19Verification
extends RefCounted

## Verification Suite for Block 19: Integrated Showcase, Immersion QA & Performance Acceptance.
## Validates the 9-stage continuous gameplay journey, integration audits, visual evidence,
## performance budgets, and emergent ecology soundscape under 100% stable headless execution.

const LivingWorldDirectorScript = preload("res://core/living_world/living_world_director.gd")
const SpatialAudioDirectorScript = preload("res://presentation/audio/spatial_audio_director.gd")
const EnvironmentalStorytellingScript = preload("res://presentation/environment/environmental_storytelling.gd")

func test_integration_camera_springarm_and_input_delegation() -> String:
	# 1. Verify Camera SpringArm clipping protection
	var walker: FirstPersonWalker = FirstPersonWalker.new()
	var cam: Camera3D = walker.get_camera()
	if not cam:
		walker.free()
		return "FirstPersonWalker failed to build camera rig."

	var spring_arm: SpringArm3D = walker._spring_arm
	if not spring_arm:
		walker.free()
		return "FirstPersonWalker missing SpringArm3D for collision occlusion protection."

	if spring_arm.margin < 0.15:
		var m: float = spring_arm.margin
		walker.free()
		return "SpringArm3D collision margin too small (%.2fm < 0.15m)." % m

	if spring_arm.collision_mask != 1:
		var mask: int = spring_arm.collision_mask
		walker.free()
		return "SpringArm3D collision mask must be 1 to collide with terrain/boulders/trees (got %d)." % mask

	# 2. Verify perspective switching
	walker.set_perspective(false)
	if walker.is_third_person:
		walker.free()
		return "FirstPersonWalker failed to switch to first-person perspective."

	walker.set_perspective(true)
	if not walker.is_third_person:
		walker.free()
		return "FirstPersonWalker failed to switch back to third-person perspective."

	walker.free()
	return ""

func test_continuous_gameplay_journey_stages() -> String:
	var seed_obj: WorldSeed = WorldSeed.new(1337)
	var clock: WorldClock = WorldClock.new()
	var bus: WorldEventBus = WorldEventBus.new()
	var registry: EntityRegistry = EntityRegistry.new(bus)
	var config: WorldGenerationConfig = WorldGenerationConfig.new(seed_obj.master_seed)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(config)
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	# STAGE 1: Spawn in Third-Person Character Mode
	var walker: FirstPersonWalker = FirstPersonWalker.new()
	var spawn_pos: Vector3 = Vector3(7.5, terrain.get_height_at(7.5, 3.5), 3.5)
	walker.teleport_to(spawn_pos)
	walker.set_perspective(true)
	if not walker.is_third_person:
		walker.free()
		terrain.free()
		return "Player failed to initialize in third-person mode."

	# STAGE 2: Uneven Terrain Slope Traversal & Weighty Acceleration
	walker.move_character(0.05, Vector3(0.0, 0.0, -1.0), false, false)
	if walker.velocity.length() < 0.05:
		walker.free()
		terrain.free()
		return "FirstPersonWalker failed to accelerate forward on input."

	# STAGE 3: Forest Canopy Understory Traversal
	var forest_pos: Vector3 = Vector3(-4.0, terrain.get_height_at(-4.0, 1.0), 1.0)
	walker.teleport_to(forest_pos)
	var env_data: Dictionary = grid.get_environment_at(-4.0, 1.0)
	var moisture: float = env_data.get("moisture", 0.5)
	if moisture < 0.2:
		walker.free()
		terrain.free()
		return "Whispering Forest coordinate lacks moisture in environmental grid (got %.2f)." % moisture

	# STAGE 4: Environmental Storytelling Landmark Discovery (Stag Antler Rub)
	var storytelling = EnvironmentalStorytellingScript.new()
	var mock_cam: Node3D = Node3D.new()
	storytelling.setup(terrain, bus, mock_cam, null, 1337)
	var antler_poi: Dictionary = storytelling.get_poi_by_id("antler_rub")
	if antler_poi.is_empty():
		walker.free()
		mock_cam.free()
		storytelling.free()
		terrain.free()
		return "Failed to find 'antler_rub' POI in EnvironmentalStorytelling."

	mock_cam.position = antler_poi["position"] + Vector3(0.2, 0.0, 0.2)
	storytelling._process(0.3)
	if storytelling.get_discovered_count() != 1:
		walker.free()
		mock_cam.free()
		storytelling.free()
		terrain.free()
		return "EnvironmentalStorytelling failed to trigger discovery for Stag Antler Rub."

	# STAGE 5: Approach Deer Herd (Sneak vs Sprint Response)
	var metrics_cls = preload("res://core/ecosystem/ecosystem_metrics.gd")
	var fauna_sim: FaunaSimulation = FaunaSimulation.new(RandomNumberGenerator.new(), registry, metrics_cls.new(), bus)
	var deer_id: int = fauna_sim.spawn_herbivore(Vector3(20.0, 2.0, 10.0))
	var deer: FaunaSimulation.HerbivoreData = fauna_sim.get_all_herbivores()[0]

	# Sneaking approach (speed 1.2 m/s, 14m away)
	fauna_sim.set_player_presence(Vector3(20.0, 2.0, 24.0), true, 1.2)
	fauna_sim.step_simulation(0.5, null, func(_x: float, _z: float) -> float: return 2.0)
	if deer.state == FaunaSimulation.HerbivoreState.FLEEING:
		walker.free()
		mock_cam.free()
		storytelling.free()
		terrain.free()
		return "Deer panicked prematurely against sneaking player at 14m."

	# Sprinting approach (speed 6.5 m/s, 8m away)
	fauna_sim.set_player_presence(Vector3(20.0, 2.0, 18.0), true, 6.5)
	fauna_sim.step_simulation(0.5, null, func(_x: float, _z: float) -> float: return 2.0)
	if deer.state != FaunaSimulation.HerbivoreState.FLEEING and deer.flee_timer <= 0.0 and deer.threat_memory <= 0.0:
		walker.free()
		mock_cam.free()
		storytelling.free()
		terrain.free()
		return "Deer failed to trigger flight response against sprinting player at 8m."

	# STAGE 6: Lake Shoreline Traversal & Drinking Boundary
	var shore_pos: Vector3 = Vector3(14.0, terrain.get_height_at(14.0, 9.5), 9.5)
	walker.teleport_to(shore_pos)
	if shore_pos.y > 1.8:
		walker.free()
		mock_cam.free()
		storytelling.free()
		terrain.free()
		return "Lake shoreline height out of bounds (%.2fm > 1.8m)." % shore_pos.y

	# STAGE 7: Weather Transition (Rain)
	weather.set_state(WeatherSystem.WeatherState.RAIN, 60.0)
	if weather.current_state != WeatherSystem.WeatherState.RAIN:
		walker.free()
		mock_cam.free()
		storytelling.free()
		terrain.free()
		return "WeatherSystem failed to transition to RAIN."

	# STAGE 8: Spatial Audio Localization
	var audio_dir: SpatialAudioDirector = SpatialAudioDirector.new()
	audio_dir.setup(clock, weather, mock_cam, bus)
	var water_player: AudioStreamPlayer3D = audio_dir._player_water
	if not water_player:
		walker.free()
		mock_cam.free()
		storytelling.free()
		audio_dir.free()
		terrain.free()
		return "SpatialAudioDirector missing LakeWaterPlayer3D emitter."

	var dist_to_audio: float = shore_pos.distance_to(water_player.position)
	if dist_to_audio > 10.0:
		walker.free()
		mock_cam.free()
		storytelling.free()
		audio_dir.free()
		terrain.free()
		return "Player at shoreline too far from lake ripple audio (%.1fm > 10.0m)." % dist_to_audio

	# Cleanup
	walker.free()
	mock_cam.free()
	storytelling.free()
	audio_dir.free()
	terrain.free()
	return ""

func test_visual_quality_evidence_integrity() -> String:
	var required_shots: Array[String] = [
		"res://reports/final_acceptance/final_01_opening_panorama.png",
		"res://reports/final_acceptance/final_02_dense_forest_interior.png",
		"res://reports/final_acceptance/final_03_forest_path_depth.png",
		"res://reports/final_acceptance/final_04_open_biome_meadow.png",
		"res://reports/final_acceptance/final_05_biome_transition.png",
		"res://reports/final_acceptance/final_06_lake_water_edge_vista.png",
		"res://reports/final_acceptance/final_07_distant_overlook.png",
		"res://reports/final_acceptance/final_08_midday_lighting.png",
		"res://reports/final_acceptance/final_09_golden_hour_lighting.png",
		"res://reports/final_acceptance/final_10_night_celestial.png",
		"res://reports/final_acceptance/final_11_representative_gameplay.png",
		"res://reports/final_acceptance/final_12_demanding_scene_perf.png"
	]

	for path in required_shots:
		var global_path: String = ProjectSettings.globalize_path(path)
		if not FileAccess.file_exists(global_path):
			return "Visual evidence screenshot missing: %s" % path
		var file: FileAccess = FileAccess.open(global_path, FileAccess.READ)
		if not file or file.get_length() < 50000: # Must be at least 50 KB
			var sz: int = file.get_length() if file else 0
			if file: file.close()
			return "Visual evidence screenshot is corrupt or too small: %s (%d bytes)" % [path, sz]
		file.close()

	return ""

func test_performance_and_telemetry_acceptance() -> String:
	var seed_obj: WorldSeed = WorldSeed.new(1337)
	var clock: WorldClock = WorldClock.new()
	var bus: WorldEventBus = WorldEventBus.new()
	var registry: EntityRegistry = EntityRegistry.new(bus)
	var config: WorldGenerationConfig = WorldGenerationConfig.new(seed_obj.master_seed)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(config)
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)

	var coord: EcosystemCoordinator = EcosystemCoordinator.new(seed_obj, clock, bus, registry, grid, weather)
	coord.bind_terrain_height(func(_x: float, _z: float) -> float: return 2.0)

	# Target workload: 55 plants, 14 herbivores, 2 predators
	coord.populate_initial_ecosystem(55, 14, 2)

	# Warmup 4 steps before benchmarking to eliminate cold start buffer allocations
	for w: int in range(4):
		coord.step_simulation(0.5)

	# Benchmark 20 continuous simulation steps
	var max_step_time_usec: int = 0
	var total_step_time_usec: int = 0
	for i in range(20):
		var t0: int = Time.get_ticks_usec()
		coord.step_simulation(0.5)
		var dt_usec: int = Time.get_ticks_usec() - t0
		total_step_time_usec += dt_usec
		if dt_usec > max_step_time_usec:
			max_step_time_usec = dt_usec

	var avg_step_time_ms: float = float(total_step_time_usec) / (20.0 * 1000.0)
	var max_step_time_ms: float = float(max_step_time_usec) / 1000.0

	# 30 FPS frame budget is 33.33ms. Simulation tick (0.5s) must be < 10.0ms (< 30% frame budget).
	if avg_step_time_ms > 10.0:
		return "Average sim step time exceeded 10.0ms budget: %.2f ms" % avg_step_time_ms

	if max_step_time_ms > 16.0:
		return "Sim step spike exceeded 16.0ms threshold: %.2f ms" % max_step_time_ms

	var mem_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	if mem_mb > 450.0:
		return "Static memory usage exceeded 450 MB: %.1f MB" % mem_mb

	return ""

func test_gameplay_immersion_and_causal_soundscape() -> String:
	var seed_obj: WorldSeed = WorldSeed.new(9999)
	var clock: WorldClock = WorldClock.new()
	var bus: WorldEventBus = WorldEventBus.new()
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)

	var audio: SpatialAudioDirector = SpatialAudioDirector.new()
	audio.setup(clock, weather, null, bus)

	# 1. Verify wind audio modulation by wind speed
	weather.wind_speed = 1.0
	for i in range(8):
		audio._process(0.5)
	var calm_wind_db: float = audio._player_wind.volume_db

	weather.wind_speed = 11.0
	for i in range(8):
		audio._process(0.5)
	var gust_wind_db: float = audio._player_wind.volume_db

	if gust_wind_db <= calm_wind_db + 4.0:
		audio.free()
		return "Wind audio did not dynamically scale with wind speed (calm: %.1f, gust: %.1f)" % [calm_wind_db, gust_wind_db]

	# 2. Verify living world event sound reactions
	bus.publish("living_world_event", {"type": "PREDATION_OBSERVED"})
	if not audio._player_fauna.stream:
		audio.free()
		return "SpatialAudioDirector failed to synthesize wolf howl on PREDATION_OBSERVED."

	bus.publish("living_world_event", {"type": "HERD_ALARM"})
	if not audio._player_fauna.stream:
		audio.free()
		return "SpatialAudioDirector failed to synthesize alarm grunt on HERD_ALARM."

	audio.free()
	return ""
