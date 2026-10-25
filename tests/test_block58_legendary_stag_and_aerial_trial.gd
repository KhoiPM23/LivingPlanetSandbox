extends SceneTree

## Test Suite 58: RDR2-Style Legendary Mythic White Stag & Genshin Aerial Ring Time-Trial Course

const LegendaryMythicStagScript = preload("res://presentation/fauna/legendary_mythic_stag.gd")
const AerialRingTrialCourseScript = preload("res://presentation/environment/aerial_ring_trial_course.gd")
const CanopySunShaftsScript = preload("res://presentation/environment/canopy_sun_shafts.gd")
const CircularMinimapHUDScript = preload("res://presentation/ui/circular_minimap_hud.gd")

func _init() -> void:
	print("--- RUNNING TEST SUITE 58 (LEGENDARY STAG & AERIAL TRIAL) ---")
	var passed: int = 0
	var failed: int = 0

	var tests = [
		"test_mythic_white_stag_model_and_materials",
		"test_mythic_white_stag_fsm_and_communion",
		"test_aerial_ring_trial_course_initialization",
		"test_aerial_ring_trial_countdown_and_sequential_clearing",
		"test_aerial_trial_precious_chest_opened",
		"test_canopy_sun_shafts_and_minimap_landmarks"
	]

	for t_name in tests:
		var err = call(t_name)
		if err == null or err == "":
			print("  [PASS] %s" % t_name)
			passed += 1
		else:
			print("  [FAIL] %s: %s" % [t_name, err])
			failed += 1

	print("SUITE 58 RESULT: Passed: %d | Failed: %d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func test_mythic_white_stag_model_and_materials() -> String:
	var stag = LegendaryMythicStagScript.new()
	root.add_child(stag)

	if not stag.get_node_or_null("BodyPivot"):
		stag.queue_free()
		return "Missing BodyPivot"
	if not stag.get_node_or_null("BodyPivot/NeckPivot"):
		stag.queue_free()
		return "Missing NeckPivot"
	if not stag.get_node_or_null("BodyPivot/NeckPivot/HeadPivot"):
		stag.queue_free()
		return "Missing HeadPivot"
	if not stag.get_node_or_null("BodyPivot/NeckPivot/HeadPivot/GildedAntlers"):
		stag.queue_free()
		return "Missing GildedAntlers"
	if not stag.get_node_or_null("BodyPivot/NeckPivot/HeadPivot/GildedAntlers/AntlerLight"):
		stag.queue_free()
		return "Missing AntlerLight"
	if not stag.get_node_or_null("StardustParticles"):
		stag.queue_free()
		return "Missing StardustParticles"
	if not stag.get_node_or_null("StagAudio"):
		stag.queue_free()
		return "Missing StagAudio"

	var light: OmniLight3D = stag.get_node_or_null("BodyPivot/NeckPivot/HeadPivot/GildedAntlers/AntlerLight") as OmniLight3D
	if light == null or light.light_energy <= 0.0:
		stag.queue_free()
		return "Antler light invalid"

	stag.queue_free()
	return ""

func test_mythic_white_stag_fsm_and_communion() -> String:
	var stag = LegendaryMythicStagScript.new()
	root.add_child(stag)

	if stag.current_state != LegendaryMythicStagScript.StagState.SERENE_GRAZING:
		stag.queue_free()
		return "Initial state should be SERENE_GRAZING"

	var spotted_emitted: Array[bool] = [false]
	stag.stag_spotted.connect(func(_pos): spotted_emitted[0] = true)

	stag.alert_to_player(Vector3(-45.0, 5.4, -5.0))
	if stag.current_state != LegendaryMythicStagScript.StagState.ALERT_REGAL:
		stag.queue_free()
		return "State should be ALERT_REGAL after alert"
	if not spotted_emitted[0]:
		stag.queue_free()
		return "stag_spotted signal not emitted"

	var communed_emitted: Array[bool] = [false]
	stag.stag_communed.connect(func(_reward): communed_emitted[0] = true)

	var reward: Dictionary = stag.perform_communion()
	if stag.current_state != LegendaryMythicStagScript.StagState.SACRED_COMMUNING:
		stag.queue_free()
		return "State should be SACRED_COMMUNING after communion"
	if not communed_emitted[0]:
		stag.queue_free()
		return "stag_communed signal not emitted"
	if reward.get("exp", 0) != 300 or reward.get("coins", 0) != 100:
		stag.queue_free()
		return "Communion reward incorrect"
	if reward.get("item", "") != "mythic_star_antler":
		stag.queue_free()
		return "Missing mythic_star_antler item"

	stag.queue_free()
	return ""

func test_aerial_ring_trial_course_initialization() -> String:
	var course = AerialRingTrialCourseScript.new()
	root.add_child(course)

	if not course.get_node_or_null("TrialDialPedestal"):
		course.queue_free()
		return "Missing TrialDialPedestal"
	if not course.get_node_or_null("TrialDialPedestal/DialKey"):
		course.queue_free()
		return "Missing DialKey"
	if not course.get_node_or_null("PreciousAerialChest"):
		course.queue_free()
		return "Missing PreciousAerialChest"
	if not course.get_node_or_null("TrialAudio"):
		course.queue_free()
		return "Missing TrialAudio"

	if course._ring_nodes.size() != 5:
		course.queue_free()
		return "Expected 5 aerial rings, got %d" % course._ring_nodes.size()

	if course.is_trial_active:
		course.queue_free()
		return "Trial should be inactive initially"
	if course._chest_root.visible:
		course.queue_free()
		return "Chest should be hidden initially"

	course.queue_free()
	return ""

func test_aerial_ring_trial_countdown_and_sequential_clearing() -> String:
	var course = AerialRingTrialCourseScript.new()
	root.add_child(course)

	var started_emitted: Array[bool] = [false]
	course.trial_started.connect(func(): started_emitted[0] = true)

	course.start_trial()
	if not course.is_trial_active:
		course.queue_free()
		return "Trial should be active after start_trial"
	if not started_emitted[0]:
		course.queue_free()
		return "trial_started signal not emitted"
	if course.time_remaining != AerialRingTrialCourseScript.TRIAL_DURATION:
		course.queue_free()
		return "time_remaining should be 35.0s"
	if not course._ring_nodes[0].visible:
		course.queue_free()
		return "Rings should become visible during active trial"

	var completed_emitted: Array[bool] = [false]
	course.trial_completed.connect(func(_rew): completed_emitted[0] = true)

	# Simulate clearing rings 0 through 4 sequentially
	for r_idx in range(5):
		var ring_pos: Vector3 = course.ring_coords[r_idx]
		var cleared = course.check_character_ring_passage(ring_pos)
		if not cleared:
			course.queue_free()
			return "Failed to clear ring %d at position %s" % [r_idx, str(ring_pos)]

	if not course.is_trial_completed:
		course.queue_free()
		return "Trial should be completed after clearing all 5 rings"
	if not completed_emitted[0]:
		course.queue_free()
		return "trial_completed signal not emitted"
	if not course._chest_root.visible:
		course.queue_free()
		return "Precious chest should be revealed on trial completion"

	course.queue_free()
	return ""

func test_aerial_trial_precious_chest_opened() -> String:
	var course = AerialRingTrialCourseScript.new()
	root.add_child(course)

	course.start_trial()
	for r_idx in range(5):
		course.check_character_ring_passage(course.ring_coords[r_idx])

	var chest_emitted: Array[bool] = [false]
	course.chest_opened.connect(func(_rew): chest_emitted[0] = true)

	var reward: Dictionary = course.open_precious_chest()
	if not course.is_chest_opened:
		course.queue_free()
		return "Chest should be opened"
	if not chest_emitted[0]:
		course.queue_free()
		return "chest_opened signal not emitted"
	if reward.get("exp", 0) != 280 or reward.get("coins", 0) != 90:
		course.queue_free()
		return "Chest rewards incorrect"
	if reward.get("item", "") != "anemo_soaring_crest":
		course.queue_free()
		return "Missing anemo_soaring_crest item"

	course.queue_free()
	return ""

func test_canopy_sun_shafts_and_minimap_landmarks() -> String:
	var shafts = CanopySunShaftsScript.new()
	root.add_child(shafts)

	if shafts._shaft_mesh_instances.size() < 6:
		shafts.queue_free()
		return "Expected at least 6 sun shaft instances"
	if not shafts.get_node_or_null("ForestPollenParticles"):
		shafts.queue_free()
		return "Missing ForestPollenParticles"
	shafts.queue_free()

	var minimap = CircularMinimapHUDScript.new()
	root.add_child(minimap)

	var has_stag: bool = false
	var has_trial: bool = false
	for lm in minimap.landmarks:
		if lm.get("id", "") == "mythic_stag":
			has_stag = true
		elif lm.get("id", "") == "aerial_trial":
			has_trial = true

	minimap.queue_free()

	if not has_stag or not has_trial:
		return "CircularMinimapHUD missing mythic_stag or aerial_trial landmark tracking"

	return ""
