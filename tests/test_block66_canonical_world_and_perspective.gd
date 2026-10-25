class_name TestBlock66CanonicalWorldAndPerspective
extends RefCounted

## Living Planet Sandbox — Block 66 Automated Verification Suite (Nhóm 2)
## Validates:
## 1. Canonical Map Lock & 110m+ Skyspire Alpine Summit
## 2. Distant Directional Shadows (360m PSSM 4-Split Cascade)
## 3. Shader View-Space Normal Transformation & Exposure Invariance
## 4. True First-Person Body Awareness (Downward View Visibility, 0.05m Near Plane)
## 5. Frozen Lake Under-Ice Fish & Perimeter Leaping Fish Effects

const FirstPersonWalkerScript = preload("res://presentation/camera/first_person_walker.gd")
const IcePlatformSystemScript = preload("res://presentation/elements/ice_platform_system.gd")
const TitleScreenScript = preload("res://presentation/ui/title_screen.gd")

func get_suite_name() -> String:
	return "TestBlock66CanonicalWorldAndPerspective"

func get_tests() -> Array[Callable]:
	return [
		Callable(self, "test_canonical_map_lock_and_skyspire_elevation"),
		Callable(self, "test_directional_shadow_distance_and_cascades"),
		Callable(self, "test_shader_normal_view_space_and_exposure_invariance"),
		Callable(self, "test_first_person_body_awareness_and_pitch_depth"),
		Callable(self, "test_frozen_lake_under_ice_and_leaping_fish")
	]

func test_canonical_map_lock_and_skyspire_elevation() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.island_size = 720.0

	# Verify Skyspire summit elevates to 108m - 120m soaring height analytically
	var summit_h: float = terrain.get_height_at(-145.0, -145.0)
	if summit_h < 105.0:
		terrain.free()
		return "Expected Skyspire summit at (-145, -145) to elevate >= 105m, got %.2fm" % summit_h

	# Verify TitleScreen has canonical seed locked to 1337
	var title = TitleScreenScript.new()
	title._ready()
	if title._seed_input == null or title._seed_input.text != "1337":
		title.free()
		terrain.free()
		return "Expected TitleScreen to lock canonical seed 1337"

	title.free()
	terrain.free()
	return ""

func test_directional_shadow_distance_and_cascades() -> String:
	var file = FileAccess.open("res://scenes/main.tscn", FileAccess.READ)
	if not file:
		return "Failed to open res://scenes/main.tscn"
	var text: String = file.get_as_text()
	file.close()

	if text.find("directional_shadow_max_distance = 360.0") == -1:
		return "main.tscn must specify directional_shadow_max_distance = 360.0"

	if text.find("directional_shadow_mode = 2") == -1:
		return "main.tscn must use 4-split PSSM directional shadow mode (mode = 2)"

	if text.find("glow_blend_mode = 1") == -1:
		return "main.tscn must use SCREEN glow blend mode (mode = 1) for exposure stability"

	return ""

func test_shader_normal_view_space_and_exposure_invariance() -> String:
	var shader = load("res://presentation/shaders/terrain_pbr.gdshader") as Shader
	if not shader:
		return "Failed to load terrain_pbr.gdshader"
	var code = shader.code
	if code.find("mat3(VIEW_MATRIX) * eff_world_norm") == -1:
		return "terrain_pbr.gdshader must transform normal to view space using VIEW_MATRIX"

	var f_shader = load("res://presentation/shaders/foliage_wind.gdshader") as Shader
	if not f_shader:
		return "Failed to load foliage_wind.gdshader"
	var f_code = f_shader.code
	if f_code.find("INV_VIEW_MATRIX * vec4(NORMAL, 0.0)") == -1:
		return "foliage_wind.gdshader must compute shelf_ao in world normal space to prevent camera tilt darkening"

	return ""

func test_first_person_body_awareness_and_pitch_depth() -> String:
	var walker: FirstPersonWalker = FirstPersonWalkerScript.new()
	walker._build_model()

	# Verify pitch angle allows deep downward look at legs/feet
	if walker.min_pitch > deg_to_rad(-70.0):
		walker.free()
		return "Expected min_pitch <= -70.0 degrees, got %.1f" % rad_to_deg(walker.min_pitch)

	# Verify camera near clip plane
	var cam: Camera3D = walker.get_camera()
	if cam.near > 0.06:
		walker.free()
		return "Expected camera near clipping plane <= 0.06m for chest/body clearance, got %.2f" % cam.near

	# Switch to First Person
	walker.set_perspective(false)

	# Verify head/hair are SHADOWS_ONLY while body meshes are ON
	if walker._character_instance:
		for child in walker._character_instance.find_children("*", "GeometryInstance3D", true, false):
			var geom: GeometryInstance3D = child as GeometryInstance3D
			var lname: String = geom.name.to_lower()
			if lname.contains("face") or lname.contains("hair"):
				if geom.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
					walker.free()
					return "Expected head/hair '%s' to be SHADOWS_ONLY in first person" % geom.name
			elif not lname.contains("aura"):
				if geom.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_ON or not geom.visible:
					walker.free()
					return "Expected body mesh '%s' to be visible with cast_shadow ON in first person" % geom.name

	walker.free()
	return ""

func test_frozen_lake_under_ice_and_leaping_fish() -> String:
	var ice_sys: IcePlatformSystem = IcePlatformSystemScript.new()
	var pos: Vector3 = Vector3(40.0, 0.0, 60.0)

	var ok: bool = ice_sys.freeze_at(pos, 3.4)
	if not ok:
		ice_sys.free()
		return "Failed to freeze ice platform at test position"

	if ice_sys._active_platforms.is_empty():
		ice_sys.free()
		return "No active ice platform recorded"

	var p_data: Dictionary = ice_sys._active_platforms[0]
	if not p_data.has("under_fish") or p_data["under_fish"].size() < 2:
		ice_sys.free()
		return "Expected at least 2 shadowy under-ice fish instances"

	if not p_data.has("leap_fish") or not is_instance_valid(p_data["leap_fish"]):
		ice_sys.free()
		return "Expected perimeter leaping fish node"

	# Simulate 1.0 second to ensure fish swimming animation advances
	var initial_angle: float = p_data["under_fish"][0]["angle"]
	ice_sys.update_simulation(1.0)
	var new_angle: float = p_data["under_fish"][0]["angle"]
	if is_equal_approx(initial_angle, new_angle):
		ice_sys.free()
		return "Expected under-ice fish orbit angle to advance during update_simulation"

	ice_sys.free()
	return ""
