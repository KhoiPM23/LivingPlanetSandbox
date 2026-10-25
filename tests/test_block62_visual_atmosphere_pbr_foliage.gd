extends SceneTree

## Automated Contract Test Suite for Block 62:
## GIAI ĐOẠN 2: PHẦN NHÌN & KHÔNG KHÍ ĐẲNG CẤP (RDR2 Atmospheric Fidelity)
## - 2.1. Dynamic Volumetric Atmosphere (Layered Height Fog & Dynamic Celestial Sun Shafts)
## - 2.2. Stylized PBR Terrain (Northern Velvety Moss, Lowland Lake Mud & Rain Ripple Normals)
## - 2.3. Dynamic Wind & Interactive Foliage (Actor Trampling & Foliage Parting)

const DayNightCycleScript = preload("res://presentation/environment/day_night_cycle.gd")
const CanopySunShaftsScript = preload("res://presentation/environment/canopy_sun_shafts.gd")
const VegetationScatterScript = preload("res://presentation/environment/vegetation_scatter.gd")
const WeatherEffectsControllerScript = preload("res://presentation/environment/weather_effects_controller.gd")

func _init() -> void:
	print("\n=======================================================")
	print("   BLOCK 62 — VISUAL ATMOSPHERE, PBR TERRAIN & FOLIAGE")
	print("=======================================================\n")

	var all_passed: bool = true
	var tests: Array[String] = [
		"test_dynamic_foliage_parting_and_trampling",
		"test_terrain_pbr_moss_mud_and_rain_ripples",
		"test_dynamic_canopy_sun_shafts_celestial_tracking",
		"test_layered_height_fog_and_rayleigh_sky",
		"test_weather_effects_controller_height_fog_sync"
	]

	for t_name: String in tests:
		var ok: bool = call(t_name)
		if ok:
			print("  [PASS] %s" % t_name)
		else:
			print("  [FAIL] %s" % t_name)
			all_passed = false

	print("\n-------------------------------------------------------")
	print("RESULT: %s" % ("ALL TESTS PASSED (5/5)" if all_passed else "SOME TESTS FAILED"))
	print("-------------------------------------------------------\n")

	quit(0 if all_passed else 1)

## 1. Verifies foliage shader actor trampling uniforms & scatter interaction updating
func test_dynamic_foliage_parting_and_trampling() -> bool:
	var f = FileAccess.open("res://presentation/shaders/foliage_wind.gdshader", FileAccess.READ)
	if not f:
		push_error("Failed to read foliage_wind.gdshader")
		return false
	var code: String = f.get_as_text()
	f.close()

	if not code.contains("uniform vec3 player_pos"):
		push_error("Missing player_pos uniform in foliage_wind.gdshader")
		return false
	if not code.contains("player_radius"):
		push_error("Missing player_radius uniform in foliage_wind.gdshader")
		return false
	if not code.contains("player_push_strength"):
		push_error("Missing player_push_strength uniform in foliage_wind.gdshader")
		return false
	if not code.contains("dist_to_player < player_radius"):
		push_error("Missing interactive foliage trampling radius condition in vertex()")
		return false

	var scatter: VegetationScatter = VegetationScatterScript.new()
	root.add_child(scatter)

	var test_mat: ShaderMaterial = ShaderMaterial.new()
	test_mat.shader = load("res://presentation/shaders/foliage_wind.gdshader") as Shader
	scatter.register_foliage_material(test_mat)

	# Simulate actor walking near grass
	var test_pos: Vector3 = Vector3(15.0, 3.8, 22.0)
	scatter.update_actor_interaction(test_pos, 1.45, 0.65)

	var set_pos: Vector3 = test_mat.get_shader_parameter("player_pos")
	var set_rad: float = test_mat.get_shader_parameter("player_radius")
	var set_str: float = test_mat.get_shader_parameter("player_push_strength")

	if set_pos.distance_to(test_pos) > 0.001:
		push_error("Shader player_pos did not match dispatched actor position")
		scatter.queue_free()
		return false
	if absf(set_rad - 1.45) > 0.001 or absf(set_str - 0.65) > 0.001:
		push_error("Shader trampling radius or push strength mismatch")
		scatter.queue_free()
		return false

	# Test Steed mounted expansion radius (2.2m)
	scatter.update_actor_interaction(test_pos, 2.2, 0.85)
	if absf(float(test_mat.get_shader_parameter("player_radius")) - 2.2) > 0.001:
		push_error("Mount expanded parting radius not updated")
		scatter.queue_free()
		return false

	scatter.queue_free()
	return true

## 2. Verifies Stylized PBR Terrain: Northern Velvety Moss, Lowland Lake Mud & Rain Ripple Normals
func test_terrain_pbr_moss_mud_and_rain_ripples() -> bool:
	var f = FileAccess.open("res://presentation/shaders/terrain_pbr.gdshader", FileAccess.READ)
	if not f:
		push_error("Failed to read terrain_pbr.gdshader")
		return false
	var code: String = f.get_as_text()
	f.close()

	# Northern Shaded Velvety Cliff Moss
	if not code.contains("Northern Shaded Velvety Moss on Cliffs"):
		push_error("Missing northern shaded moss section in terrain_pbr.gdshader")
		return false
	if not code.contains("moss_weight"):
		push_error("Missing moss_weight calculation in terrain_pbr.gdshader")
		return false
	if not code.contains("north_bias"):
		push_error("Missing north_bias in terrain_pbr.gdshader")
		return false

	# Lowland Lake Mud & Riparian Humus Blending
	if not code.contains("Lowland Lake Mud"):
		push_error("Missing lowland lake mud blending in terrain_pbr.gdshader")
		return false
	if not code.contains("lake_mud_weight"):
		push_error("Missing lake_mud_weight in terrain_pbr.gdshader")
		return false

	# Micro-Rain Ripple Normal Perturbations
	if not code.contains("Micro-Rain Ripple Normal Perturbation"):
		push_error("Missing micro-rain ripple normal perturbations in terrain_pbr.gdshader")
		return false
	if not code.contains("rip_norm"):
		push_error("Missing rip_norm calculation in terrain_pbr.gdshader")
		return false

	# Ambient Occlusion contract preservation
	if not code.contains("crevice_ao") or not code.contains("AO = crevice_ao;"):
		push_error("Crevice AO contract violated in terrain_pbr.gdshader")
		return false

	return true

## 3. Verifies Dynamic Celestial Sun Shafts tracking celestial trajectory
func test_dynamic_canopy_sun_shafts_celestial_tracking() -> bool:
	var shafts: CanopySunShafts = CanopySunShaftsScript.new()
	root.add_child(shafts)

	# Verify cone count & pollen particles
	if shafts._shaft_mesh_instances.size() < 6:
		push_error("Expected at least 6 sun shaft instances")
		shafts.queue_free()
		return false

	# Test explicit celestial alignment
	var morning_sun: Vector3 = Vector3(0.72, 0.35, -0.40).normalized()
	shafts.align_with_sun(morning_sun, false)

	# Check that cone mesh orientation rotated toward morning sun
	var first_cone: MeshInstance3D = shafts._shaft_mesh_instances[0]
	var y_axis_dot: float = first_cone.basis.y.dot(morning_sun)
	if y_axis_dot < 0.95:
		push_error("Sun shaft cone Y axis did not align with celestial sun direction (dot=%.3f)" % y_axis_dot)
		shafts.queue_free()
		return false

	# Test lighting state adaptation
	var dnc: DayNightCycle = DayNightCycleScript.new()
	root.add_child(dnc)
	shafts.setup(dnc)

	dnc.set_golden_hour()
	shafts.update_lighting_adaptation()
	var g_col: Color = shafts._shaft_mat.albedo_color
	if g_col.r < 0.90 or g_col.g < 0.70:
		push_error("Expected warm amber/gold color in golden hour shaft adaptation")
		shafts.queue_free()
		dnc.queue_free()
		return false

	dnc.set_midday()
	shafts.update_lighting_adaptation()
	var m_col: Color = shafts._shaft_mat.albedo_color
	if m_col.b < 0.90:
		push_error("Expected cool blue-white daylight color in midday shaft adaptation")
		shafts.queue_free()
		dnc.queue_free()
		return false

	shafts.queue_free()
	dnc.queue_free()
	return true

## 4. Verifies Layered Height Fog & Celestial Trajectory in DayNightCycle
func test_layered_height_fog_and_rayleigh_sky() -> bool:
	var dnc: DayNightCycle = DayNightCycleScript.new()
	root.add_child(dnc)

	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = Environment.new()
	root.add_child(world_env)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	root.add_child(sun)

	var clock: WorldClock = WorldClock.new(10.0)
	clock.day_duration = 1800.0
	clock.start_hour = 11.5

	dnc.setup(clock, sun, world_env, null)

	var env: Environment = world_env.environment
	if not env.fog_enabled:
		push_error("Expected fog_enabled == true")
		dnc.queue_free()
		world_env.queue_free()
		sun.queue_free()
		return false

	if absf(env.fog_height - 8.5) > 0.1:
		push_error("Expected fog_height == 8.5, got: %.2f" % env.fog_height)
		dnc.queue_free()
		world_env.queue_free()
		sun.queue_free()
		return false

	if env.fog_height_density < 0.04:
		push_error("Expected fog_height_density >= 0.04 for valley mist, got: %.3f" % env.fog_height_density)
		dnc.queue_free()
		world_env.queue_free()
		sun.queue_free()
		return false

	var s_dir: Vector3 = dnc.get_sun_direction()
	if not s_dir.is_normalized():
		push_error("get_sun_direction() must return normalized vector")
		dnc.queue_free()
		world_env.queue_free()
		sun.queue_free()
		return false

	dnc.queue_free()
	world_env.queue_free()
	sun.queue_free()
	return true

## 5. Verifies WeatherEffectsController layered height fog synchronization
func test_weather_effects_controller_height_fog_sync() -> bool:
	var weather_ctrl: WeatherEffectsController = WeatherEffectsControllerScript.new()
	root.add_child(weather_ctrl)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1337
	var bus: WorldEventBus = WorldEventBus.new()
	var weather: WeatherSystem = WeatherSystem.new(rng, bus)
	weather.set_weather_override(WeatherSystem.WeatherState.RAIN)

	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = Environment.new()
	world_env.environment.fog_enabled = true
	world_env.environment.fog_mode = Environment.FOG_MODE_DEPTH
	root.add_child(world_env)

	weather_ctrl._weather = weather
	weather_ctrl._world_env = world_env

	# Run process step to apply weather fog properties
	weather_ctrl._process(1.0)

	var env: Environment = world_env.environment
	if env.fog_height_density < 0.02 or env.fog_height_density > 0.15:
		push_error("Expected synced fog_height_density within [0.02, 0.15], got: %.3f" % env.fog_height_density)
		weather_ctrl.queue_free()
		world_env.queue_free()
		return false

	weather_ctrl.queue_free()
	world_env.queue_free()
	return true
