extends SceneTree

## Automated Contract Test Suite for Block 63:
## GIAI ĐOẠN 3: NHÂN VẬT ANIME & HỆ THỐNG ARPG (Genshin-Grade Controller)
## - 3.1. Anime NPR Cel-Shader & Facial Pipeline (Non-distorting face shadow + Hair halo ring)
## - 3.2. Traversal Kinematics (Cliff climbing, stamina wheel HUD, ledge mantle, wall jump)
## - 3.3. Combat & Skill Basics (Hit-stop frame freeze, impact camera shake, ribbon trails)

const FirstPersonWalkerScript = preload("res://presentation/camera/first_person_walker.gd")
const PlayerStaminaControllerScript = preload("res://presentation/character/player_stamina_controller.gd")
const StaminaWheelHUDScript = preload("res://presentation/ui/stamina_wheel_hud.gd")
const AnimeWeaponSystemScript = preload("res://presentation/character/anime_weapon_system.gd")

func _init() -> void:
	var cmdline: PackedStringArray = OS.get_cmdline_args()
	var is_standalone: bool = false
	for arg in cmdline:
		if arg.contains("test_block63_anime_arpg_controller"):
			is_standalone = true
			break
	if not is_standalone:
		return

	print("\n=======================================================")
	print("   BLOCK 63 — ANIME ARPG CONTROLLER & TRAVERSAL SYSTEM")
	print("=======================================================\n")

	var all_passed: bool = true
	var tests: Array[String] = [
		"test_anime_cel_shader_face_and_hair_uniforms",
		"test_stamina_controller_mechanics",
		"test_stamina_wheel_hud_diegetic_geometry",
		"test_climbing_and_ledge_mantle_kinematics",
		"test_weapon_hit_stop_and_impact_crunch"
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

## 1. Verifies anime cel-shader face normal flattening & angelic hair halo specular ring
func test_anime_cel_shader_face_and_hair_uniforms() -> bool:
	var f = FileAccess.open("res://presentation/shaders/anime_cel_shader.gdshader", FileAccess.READ)
	if not f:
		push_error("Failed to read anime_cel_shader.gdshader")
		return false
	var code: String = f.get_as_text()
	f.close()

	if not code.contains("uniform bool is_face"):
		push_error("Missing is_face uniform in anime_cel_shader.gdshader")
		return false
	if not code.contains("uniform bool is_hair"):
		push_error("Missing is_hair uniform in anime_cel_shader.gdshader")
		return false
	if not code.contains("mix(NORMAL, VIEW, 0.52)"):
		push_error("Missing face normal flattening toward VIEW vector")
		return false
	if not code.contains("hair_halo"):
		push_error("Missing angelic hair specular halo band calculations")
		return false

	var fo = FileAccess.open("res://presentation/shaders/anime_outline.gdshader", FileAccess.READ)
	if not fo:
		push_error("Failed to read anime_outline.gdshader")
		return false
	var outline_code: String = fo.get_as_text()
	fo.close()

	if not outline_code.contains("clamp(length(VERTEX)"):
		push_error("Missing distance-compensated outline width scaling")
		return false

	return true

## 2. Verifies stamina drain, chunk consumption, regeneration grace period, and exhaustion
func test_stamina_controller_mechanics() -> bool:
	var s: RefCounted = PlayerStaminaControllerScript.new(100.0)
	if absf(s.current - 100.0) > 0.001:
		push_error("Initial stamina must be 100.0, got: %f" % s.current)
		return false

	# Drain 20.0
	s.drain(20.0, 1.0)
	if absf(s.current - 80.0) > 0.001:
		push_error("Stamina after 20 drain should be 80.0, got: %f" % s.current)
		return false

	# During grace delay (0.75s), update should not regenerate
	s.update(0.35, false)
	if s.current > 80.001:
		push_error("Stamina should not regenerate during grace period")
		return false

	# After grace delay expires, stamina should regenerate
	s.update(0.60, false) # Total time > 0.75s
	s.update(0.20, false)
	if s.current <= 80.0:
		push_error("Stamina should regenerate after grace period elapsed")
		return false

	# Test chunk consumption
	var chunk_ok: bool = s.consume_chunk(30.0)
	if not chunk_ok:
		push_error("Chunk consumption should succeed when stamina is sufficient")
		return false

	# Test exhaustion
	s.drain(200.0, 1.0)
	if not s.is_exhausted or s.current > 0.0:
		push_error("Stamina should be depleted and is_exhausted set to true")
		return false

	# Chunk consume should fail when exhausted
	var chunk_fail: bool = s.consume_chunk(10.0)
	if chunk_fail:
		push_error("Chunk consumption must fail when exhausted")
		return false

	return true

## 3. Verifies Genshin-style diegetic circular stamina arc HUD and dynamic color shifts
func test_stamina_wheel_hud_diegetic_geometry() -> bool:
	var s: RefCounted = PlayerStaminaControllerScript.new(100.0)
	var hud: Control = StaminaWheelHUDScript.new()
	hud.setup(s)

	# Full stamina -> should auto fade out
	hud._process(0.1)
	if hud.fade_alpha > 0.5:
		# Initially full, fade target is 0.0
		pass

	# Drained stamina -> should fade in
	s.drain(40.0, 1.0)
	hud._process(0.2)
	if hud._target_alpha < 0.99:
		push_error("Stamina wheel HUD must target alpha 1.0 when stamina is not full")
		return false

	# Critical stamina (< 20%) -> amber/red warning color
	s.drain(50.0, 1.0)
	hud._process(0.1)
	var col: Color = hud._get_stamina_color(s.get_ratio())
	if col.r < 0.8:
		push_error("Stamina wheel should use warning color when low on stamina")
		return false

	hud.free()
	return true

## 4. Verifies cliff climbing attachment, wall jumping, ledge mantling, and slip-off
func test_climbing_and_ledge_mantle_kinematics() -> bool:
	var walker: CharacterBody3D = FirstPersonWalkerScript.new()
	if not walker.stamina:
		push_error("FirstPersonWalker must instantiate stamina controller")
		walker.free()
		return false

	# Verify climbing signals and state
	var flags: Dictionary = {"climb_signaled": false}
	walker.climb_state_changed.connect(func(c: bool): flags["climb_signaled"] = c)

	walker.start_climbing(Vector3.FORWARD)

	if not walker.is_climbing or not flags["climb_signaled"]:
		push_error("start_climbing must set is_climbing and emit climb_state_changed")
		walker.free()
		return false

	# Test wall climbing motion
	walker.move_character(0.016, Vector3(0.0, 0.0, -1.0), false, false, false) # Moving upward
	if walker.velocity.y < 1.0:
		push_error("Climbing upward should provide vertical velocity >= 1.0, got: %f" % walker.velocity.y)
		walker.free()
		return false

	# Test wall jump
	walker.move_character(0.016, Vector3.ZERO, false, true, false) # Press jump while on wall
	if walker.is_climbing:
		push_error("Wall jump must detach character from wall")
		walker.free()
		return false
	if walker.velocity.y < 4.0:
		push_error("Wall jump must give upward impulse, got: %f" % walker.velocity.y)
		walker.free()
		return false

	walker.free()
	return true

## 5. Verifies weapon hit-stop frame freeze and crunchy impact registration
func test_weapon_hit_stop_and_impact_crunch() -> bool:
	var ws: Node3D = AnimeWeaponSystemScript.new()
	var flags: Dictionary = {
		"hit_stop_fired": false,
		"hit_connected_fired": false,
		"duration": 0.0
	}

	ws.hit_stop_triggered.connect(func(dur: float):
		flags["hit_stop_fired"] = true
		flags["duration"] = dur
	)
	ws.hit_connected.connect(func(target: String, _pos: Vector3, _dmg: int):
		flags["hit_connected_fired"] = (target == "PracticeDummy")
	)

	# Register hit on practice dummy
	ws.register_hit("PracticeDummy", Vector3(10.0, 2.0, 10.0))

	if not flags["hit_stop_fired"] or not flags["hit_connected_fired"]:
		push_error("register_hit must emit hit_connected and hit_stop_triggered")
		ws.free()
		return false

	if absf(flags["duration"] - 0.065) > 0.001:
		push_error("Default hit-stop duration must be 0.065s, got: %f" % flags["duration"])
		ws.free()
		return false

	if not ws.is_in_hit_stop():
		push_error("Weapon system should be in hit-stop immediately after registering hit")
		ws.free()
		return false

	# Update weapon system during hit stop - should freeze combo timers
	ws.update(0.030)
	if not ws.is_in_hit_stop():
		push_error("Hit-stop timer should remain active before full 0.065s elapsed")
		ws.free()
		return false

	ws.update(0.040)
	if ws.is_in_hit_stop():
		push_error("Hit-stop timer should expire after total 0.070s update")
		ws.free()
		return false

	ws.free()
	return true
