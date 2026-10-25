extends SceneTree

## Automated Contract Test Suite for Block 61:
## - State Interpolation & Anti-Jank Engine (Giai đoạn 1.1)
## - AAA Mass-Spring-Damper Camera & Selfie Camera Mode (Giai đoạn 1.2)
## - Mountable Prairie Steed (Thú Cưỡi Thảo Nguyên)
## - Submerged Sea Cavern & Catacombs Passage (Quần Xã Hang Biển Ngầm)

const EcosystemStateInterpolatorScript = preload("res://presentation/ecosystem/ecosystem_state_interpolator.gd")
const MountableSteedControllerScript = preload("res://presentation/fauna/mountable_steed_controller.gd")
const SubmergedSeaCavernScript = preload("res://presentation/environment/submerged_sea_cavern.gd")

func _init() -> void:
	print("\n=======================================================")
	print("   BLOCK 61 — STATE INTERPOLATOR, MOUNT, CAVERN, SELFIE")
	print("=======================================================\n")

	var all_passed: bool = true
	var tests: Array[String] = [
		"test_state_interpolator_hermite_and_banking",
		"test_mountable_steed_mechanics",
		"test_submerged_sea_cavern_architecture",
		"test_camera_spring_damper_and_selfie_mode",
		"test_walker_mount_system_integration"
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

# 1. State Interpolation Engine Verification
func test_state_interpolator_hermite_and_banking() -> bool:
	var interp = EcosystemStateInterpolatorScript.new()
	var test_node = Node3D.new()

	# Register entity and bind node
	var buf = interp.register_entity("deer_alpha", test_node)
	if buf == null or not interp.has_entity("deer_alpha"):
		test_node.free()
		interp.free()
		return false

	# Push 3 simulation tick states at 0.5s intervals (2Hz simulation)
	interp.push_state("deer_alpha", Vector3(0.0, 0.0, 0.0), 0.0, 0.0)
	interp.push_state("deer_alpha", Vector3(5.0, 0.0, 2.0), deg_to_rad(30.0), 0.5)
	interp.push_state("deer_alpha", Vector3(10.0, 0.0, 8.0), deg_to_rad(65.0), 1.0)

	# Simulate 60 FPS frames across time
	interp._global_sim_time = 0.35 # Interpolation point between sample 0 and 1
	interp.update_all(0.016)

	var pos_mid: Vector3 = interp.get_interpolated_position("deer_alpha")
	var yaw_mid: float = interp.get_interpolated_yaw("deer_alpha")
	var _roll_mid: float = interp.get_interpolated_roll("deer_alpha")

	# Position must be smooth between 0 and 10, yaw between 0 and 65 deg
	var valid_pos: bool = pos_mid.x > 0.0 and pos_mid.x < 10.0
	var valid_yaw: bool = yaw_mid >= 0.0 and yaw_mid <= deg_to_rad(65.0)

	test_node.free()
	interp.free()
	return valid_pos and valid_yaw

# 2. Mountable Prairie Steed Verification
func test_mountable_steed_mechanics() -> bool:
	var steed = MountableSteedControllerScript.new()
	var walker = FirstPersonWalker.new()

	# Initial resting state
	if steed.is_player_mounted:
		steed.free()
		walker.free()
		return false

	# Mount player
	var mount_ok: bool = steed.mount_player(walker)
	if not mount_ok or not steed.is_player_mounted:
		steed.free()
		walker.free()
		return false

	# Verify camera expanded distance for open-world traversal
	var cam_expanded: bool = walker.camera_distance >= 5.0

	# Step sprint/gallop motion
	steed.step_mounted_motion(0.1, Vector3.FORWARD, true, false)
	var is_galloping: bool = steed.current_gait == MountableSteedControllerScript.GaitState.GALLOP
	var high_speed: bool = Vector2(steed.velocity.x, steed.velocity.z).length() > 0.5

	# Step leap jump
	steed.step_mounted_motion(0.1, Vector3.FORWARD, true, true)
	var is_leaping: bool = steed.current_gait == MountableSteedControllerScript.GaitState.LEAPING
	var vertical_boost: bool = steed.velocity.y > 0.0

	# Dismount player
	steed.dismount_player()
	var dismounted_ok: bool = not steed.is_player_mounted

	steed.free()
	walker.free()
	return cam_expanded and is_galloping and high_speed and is_leaping and vertical_boost and dismounted_ok

# 3. Submerged Sea Cavern Architecture & Traversal
func test_submerged_sea_cavern_architecture() -> bool:
	var cavern = SubmergedSeaCavernScript.new()
	var walker = FirstPersonWalker.new()

	# Check entrance prompts from sea and castle
	var sea_prompt: Dictionary = cavern.get_interaction_prompt(SubmergedSeaCavernScript.GALLEON_ENTRANCE_POS)
	var has_sea_action: bool = sea_prompt.get("action", "") == "enter_from_sea"

	var castle_prompt: Dictionary = cavern.get_interaction_prompt(SubmergedSeaCavernScript.CATACOMBS_EXIT_POS)
	var has_castle_action: bool = castle_prompt.get("action", "") == "enter_from_castle"

	# Mid-chamber reliquary chest
	var chest_prompt: Dictionary = cavern.get_interaction_prompt(SubmergedSeaCavernScript.MID_CHAMBER_POS)
	var has_chest_action: bool = chest_prompt.get("action", "") == "open_chest"

	# Trigger chest interaction
	var chest_res: Dictionary = cavern.trigger_interaction(walker, "open_chest")
	var chest_opened_ok: bool = chest_res.get("success", false) and cavern.is_chest_opened
	var reward_relic: String = chest_res.get("reward", {}).get("id", "")

	# Trigger sea entrance traversal
	var enter_res: Dictionary = cavern.trigger_interaction(walker, "enter_from_sea")
	var enter_ok: bool = enter_res.get("success", false)

	cavern.free()
	walker.free()
	return has_sea_action and has_castle_action and has_chest_action and chest_opened_ok and reward_relic == "ancient_relic_con_dau" and enter_ok

# 4. AAA Mass-Spring-Damper Camera & Selfie Mode Verification
func test_camera_spring_damper_and_selfie_mode() -> bool:
	var walker = FirstPersonWalker.new()

	# Test mass-spring-damper camera dynamics
	walker._target_cam_yaw = deg_to_rad(45.0)
	walker._target_cam_pitch = deg_to_rad(15.0)
	walker.update_camera_rotation(0.05)

	# Camera should smoothly converge toward target without instant snapping
	var smooth_yaw: bool = absf(walker._cam_yaw) > 0.001 and absf(walker._cam_yaw) < deg_to_rad(45.0)
	var has_velocity: bool = absf(walker._cam_yaw_vel) > 0.001

	# Test Selfie Mode toggle
	var selfie_active: bool = walker.toggle_selfie_mode()
	if not selfie_active or not walker.is_selfie_mode:
		walker.free()
		return false

	# Test selfie facial expression assignment
	walker.set_facial_expression_by_index(1) # Joy / Smile
	walker.set_facial_expression_by_index(3) # Combat / Confident

	# Test selfie photo capture
	var photo_res: Dictionary = walker.capture_selfie()
	var photo_valid: bool = photo_res.has("timestamp") and photo_res.has("camera_yaw")

	# Exit selfie mode
	walker.set_selfie_mode(false)
	var exited_ok: bool = not walker.is_selfie_mode

	walker.free()
	return smooth_yaw and has_velocity and selfie_active and photo_valid and exited_ok

# 5. Walker Mount System Integration
func test_walker_mount_system_integration() -> bool:
	var walker = FirstPersonWalker.new()
	var steed = MountableSteedControllerScript.new()

	# Initially not mounted
	if walker.is_mounted():
		walker.free()
		steed.free()
		return false

	# Mount steed
	var m_ok: bool = walker.mount_steed(steed)
	if not m_ok or not walker.is_mounted():
		walker.free()
		steed.free()
		return false

	# Move character while mounted delegates to steed motion
	walker.move_character(0.1, Vector3.FORWARD, true, false)
	var steed_moved: bool = steed.current_gait == MountableSteedControllerScript.GaitState.GALLOP

	# Dismount
	walker.dismount_steed()
	var d_ok: bool = not walker.is_mounted()

	walker.free()
	steed.free()
	return m_ok and steed_moved and d_ok
