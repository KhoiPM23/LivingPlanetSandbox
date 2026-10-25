class_name TestBlock57HuntingTrackingGeyserAndStele
extends RefCounted

## Living Planet Sandbox — Test Suite 57
## Validates Block 57 RDR2 Hunter Eagle Eye Tracking & Genshin Anemo Geyser / Stele Systems

const HunterEagleEyeSystemScript = preload("res://presentation/systems/hunter_eagle_eye_system.gd")
const AnemoWindGeyserScript = preload("res://presentation/environment/anemo_wind_geyser.gd")
const AncientSteleInscriptionScript = preload("res://presentation/environment/ancient_stele_inscription.gd")
const CircularMinimapHUDScript = preload("res://presentation/ui/circular_minimap_hud.gd")

func test_hunter_eagle_eye_toggle_and_beacons() -> String:
	var sys = HunterEagleEyeSystemScript.new()
	if sys == null:
		return "Failed to instantiate HunterEagleEyeSystem"
	if sys._clues.size() != 4:
		return "Expected 4 animal track clues, got %d" % sys._clues.size()

	var toggled_signal: Array[bool] = [false]
	sys.eagle_eye_toggled.connect(func(active: bool):
		toggled_signal[0] = active
	)

	# 1. Toggle ON
	var state1 = sys.toggle_eagle_eye()
	if not state1 or not sys.is_active or not toggled_signal[0]:
		sys.free()
		return "Eagle Eye failed to toggle ON"

	# Verify beacons are visible
	for c in sys._clues:
		if not c["beacon"].visible:
			sys.free()
			return "Eagle Eye clue beacon is not visible when active"

	# 2. Toggle OFF
	var state2 = sys.toggle_eagle_eye()
	if state2 or sys.is_active or toggled_signal[0]:
		sys.free()
		return "Eagle Eye failed to toggle OFF"

	sys.free()
	return ""

func test_hunter_clue_inspection() -> String:
	var sys = HunterEagleEyeSystemScript.new()
	var clue_near_fox = sys.get_nearest_clue(Vector3(25.5, 3.5, -13.5))
	if clue_near_fox.is_empty() or clue_near_fox["id"] != "clue_fox_den":
		sys.free()
		return "get_nearest_clue failed to return clue_fox_den within radius"

	var signal_inspected: Array[bool] = [false]
	sys.track_clue_inspected.connect(func(c_id: String, _sp: String, _title: String, _pos: Vector3):
		if c_id == "clue_fox_den":
			signal_inspected[0] = true
	)

	var inspected_data = sys.inspect_clue("clue_fox_den")
	if inspected_data.is_empty() or not signal_inspected[0] or not inspected_data.get("is_inspected", false):
		sys.free()
		return "inspect_clue failed to set is_inspected or emit signal"

	sys.free()
	return ""

func test_anemo_wind_geyser_seal_and_damage() -> String:
	var geyser = AnemoWindGeyserScript.new()
	if not geyser.is_sealed or geyser.seal_health != 3:
		geyser.free()
		return "Anemo Wind Geyser initial state is not sealed with 3 health"

	# Damage 1
	geyser.damage_seal(1)
	if geyser.seal_health != 2 or not geyser.is_sealed:
		geyser.free()
		return "Geyser damage_seal(1) failed to reduce health to 2"

	var unsealed_signal: Array[bool] = [false]
	geyser.geyser_unsealed.connect(func(_pos: Vector3):
		unsealed_signal[0] = true
	)

	# Damage 2 more -> unseal
	geyser.damage_seal(2)
	if geyser.is_sealed or geyser.seal_health != 0 or not unsealed_signal[0]:
		geyser.free()
		return "Geyser failed to unseal when seal health reached 0"

	if not geyser._geyser_column.visible:
		geyser.free()
		return "Geyser wind column mesh is not visible after unsealing"

	geyser.free()
	return ""

func test_anemo_wind_geyser_propulsion() -> String:
	var geyser = AnemoWindGeyserScript.new()
	geyser.position = Vector3(10.0, 5.0, 10.0)
	geyser.unseal_geyser()

	# Create dummy character node
	var dummy = CharacterBody3D.new()
	dummy.position = Vector3(10.0, 5.5, 10.0)
	dummy.velocity = Vector3.ZERO

	var propelled_signal: Array[bool] = [false]
	geyser.geyser_propelled.connect(func(_char: Node3D, surge: float):
		if surge >= 20.0:
			propelled_signal[0] = true
	)

	var result = geyser.check_character_propulsion(dummy)
	if not result or not propelled_signal[0] or dummy.velocity.y < 20.0:
		geyser.free()
		dummy.free()
		return "check_character_propulsion failed to launch character with upward velocity"

	geyser.free()
	dummy.free()
	return ""

func test_ancient_stele_inscription_reading() -> String:
	var stele = AncientSteleInscriptionScript.new()
	if stele.is_read:
		stele.free()
		return "Ancient Stele initial state is already read"

	var signal_received: Array[bool] = [false]
	stele.stele_read.connect(func(title: String, _txt: String, reward: Dictionary):
		if title == "Bia Cổ Ngữ Ngàn Đời" and reward.get("exp", 0) == 150:
			signal_received[0] = true
	)

	var reward_res = stele.read_inscription()
	if not stele.is_read or not signal_received[0] or reward_res.get("title", "") != "Học Giả Cổ Ngữ":
		stele.free()
		return "read_inscription failed to return correct rewards or set is_read"

	stele.free()
	return ""

func test_minimap_hud_geyser_and_stele_tracking() -> String:
	var minimap = CircularMinimapHUDScript.new()
	var has_geyser: bool = false
	var has_stele: bool = false

	for lm in minimap.landmarks:
		if lm["id"] == "anemo_geyser":
			has_geyser = true
		elif lm["id"] == "ancient_stele":
			has_stele = true

	if not has_geyser or not has_stele:
		minimap.free()
		return "CircularMinimapHUD missing anemo_geyser or ancient_stele landmark tracking"

	minimap.free()
	return ""
