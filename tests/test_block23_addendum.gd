class_name TestBlock23Addendum
extends RefCounted

## Automated Contract Verification Suite for Block 23 Addendum:
## Critical Regression Fixes, Cinematic Rendering, World Generation & Wildlife Audio.

func test_weather_manual_override_and_restoration() -> String:
	var seed_obj: WorldSeed = WorldSeed.new(1337)
	var bus: WorldEventBus = WorldEventBus.new()
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)

	# Baseline: dynamic automatic weather
	if weather.manual_override:
		return "WeatherSystem should start with manual_override = false"

	# Apply manual override state
	weather.set_manual_state(WeatherSystem.WeatherState.RAIN)
	if not weather.manual_override:
		return "WeatherSystem did not enable manual_override flag"
	if weather.current_state != WeatherSystem.WeatherState.RAIN:
		return "WeatherSystem current_state is not RAIN after manual set"

	# Simulate 120 seconds of gameplay: manual state must NOT transition or decrement duration
	var initial_duration: float = weather.duration_remaining
	for i in range(120):
		weather.update(1.0)
	if weather.current_state != WeatherSystem.WeatherState.RAIN:
		return "WeatherSystem auto-transitioned away from manual RAIN override"
	if weather.duration_remaining != initial_duration:
		return "WeatherSystem duration decremented while under manual override"

	# Clear manual override: dynamic simulation restored
	weather.clear_manual_override()
	if weather.manual_override:
		return "WeatherSystem failed to clear manual_override flag"
	weather.update(weather.duration_remaining + 1.0)
	# Should be eligible for automatic transitions
	return ""

func test_island_seed_variation_and_determinism() -> String:
	var terrain_1337_a: IslandTerrain = IslandTerrain.new()
	var terrain_1337_b: IslandTerrain = IslandTerrain.new()
	var terrain_4242: IslandTerrain = IslandTerrain.new()
	var terrain_9999: IslandTerrain = IslandTerrain.new()

	terrain_1337_a.generate_island(1337)
	terrain_1337_b.generate_island(1337)
	terrain_4242.generate_island(4242)
	terrain_9999.generate_island(9999)

	# 1. Determinism check: identical seed produces identical elevations everywhere
	for sample_pt in [Vector2(0, 0), Vector2(-24, -24), Vector2(16, 14), Vector2(30, -10)]:
		var h_a: float = terrain_1337_a.get_height_at(sample_pt.x, sample_pt.y)
		var h_b: float = terrain_1337_b.get_height_at(sample_pt.x, sample_pt.y)
		if absf(h_a - h_b) > 0.0001:
			return "Seed 1337 non-deterministic at %s: %.4f vs %.4f" % [sample_pt, h_a, h_b]

	# 2. Backward compatibility check for canonical 1337
	var center_h: float = terrain_1337_a.get_height_at(0.0, 0.0)
	var peak_h: float = terrain_1337_a.get_height_at(-24.0, -24.0)
	var edge_h: float = terrain_1337_a.get_height_at(75.0, 75.0)
	if not (center_h > 0.0 and peak_h > center_h and edge_h < 0.0):
		return "Canonical seed 1337 violated height contract"

	# 3. Seed variation check: different seeds produce distinct elevations and coastlines
	var h_diff_count: int = 0
	var test_points: Array[Vector2] = [
		Vector2(-24.0, -24.0),
		Vector2(24.0, 24.0),
		Vector2(-35.0, 10.0),
		Vector2(35.0, -15.0),
		Vector2(55.0, 0.0)
	]
	for pt in test_points:
		var h1: float = terrain_1337_a.get_height_at(pt.x, pt.y)
		var h2: float = terrain_4242.get_height_at(pt.x, pt.y)
		var h3: float = terrain_9999.get_height_at(pt.x, pt.y)
		if absf(h1 - h2) > 0.25 or absf(h1 - h3) > 0.25:
			h_diff_count += 1

	if h_diff_count < 3:
		return "Seeds 1337, 4242, and 9999 did not produce sufficient terrain elevation differences"

	terrain_1337_a.free()
	terrain_1337_b.free()
	terrain_4242.free()
	terrain_9999.free()
	return ""

func test_wildlife_spawn_distribution_and_spacing() -> String:
	var seed_obj: WorldSeed = WorldSeed.new(1337)
	var bus: WorldEventBus = WorldEventBus.new()
	var clock: WorldClock = WorldClock.new()
	var registry: EntityRegistry = EntityRegistry.new()
	var grid: EnvironmentalGrid = EnvironmentalGrid.new()
	grid.initialize_grid(func(_x: float, _z: float) -> float: return 2.0)
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)

	var coord: EcosystemCoordinator = EcosystemCoordinator.new(seed_obj, clock, bus, registry, grid, weather)
	coord.populate_initial_ecosystem(55, 14, 2)

	var herbs: Array = coord.fauna_sim.get_herbivores()
	if herbs.size() != 14:
		coord.free()
		return "Expected 14 herbivores, got %d" % herbs.size()

	# Check player spawn exclusion zone (radius 6.0m around (7.5, 3.5))
	var player_spawn: Vector2 = Vector2(7.5, 3.5)
	for h in herbs:
		var h_pos: Vector2 = Vector2(h.position.x, h.position.z)
		if h_pos.distance_to(player_spawn) < 6.0:
			return "Herbivore spawned inside player camera exclusion zone: %s" % h.position

	# Check minimum separation between animals
	for i in range(herbs.size()):
		for j in range(i + 1, herbs.size()):
			var p1: Vector3 = herbs[i].position
			var p2: Vector3 = herbs[j].position
			if p1.distance_to(p2) < 2.5:
				return "Herbivores spawned too close (< 2.5m): %s vs %s" % [p1, p2]

	return ""

func test_upgraded_wildlife_audio_characteristics() -> String:
	var dir_script: GDScript = preload("res://presentation/audio/spatial_audio_director.gd")
	var deer_snort: AudioStreamWAV = dir_script._generate_deer_alarm_snort_wav(0.35, 22050)
	var wolf_growl: AudioStreamWAV = dir_script._generate_wolf_growl_wav(1.4, 22050)

	if not deer_snort or deer_snort.data.is_empty():
		return "Deer alarm snort audio stream is null or empty"
	if deer_snort.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		return "Deer alarm snort should have LOOP_DISABLED"
	if deer_snort.mix_rate != 22050:
		return "Deer alarm snort mix rate mismatch"

	if not wolf_growl or wolf_growl.data.is_empty():
		return "Wolf growl audio stream is null or empty"
	if wolf_growl.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		return "Wolf growl should have LOOP_DISABLED"

	# Check for non-clipping in 16-bit PCM buffer
	var snort_data: PackedByteArray = deer_snort.data
	var max_snort_amp: int = 0
	for i in range(mini(500, snort_data.size() / 2)):
		var val: int = abs(snort_data.decode_s16(i * 2))
		max_snort_amp = maxi(max_snort_amp, val)
	if max_snort_amp < 1000:
		return "Deer alarm snort audio is silent (max amp: %d)" % max_snort_amp
	if max_snort_amp > 32760:
		return "Deer alarm snort audio is clipping (max amp: %d)" % max_snort_amp

	return ""
