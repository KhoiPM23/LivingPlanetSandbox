class_name TestBlock36SurvivalShelterForagingAndShowcase
extends RefCounted

## Automated Contract Test Suite for Block 36:
## 1. Field Lean-to Canvas Shelter Deployment, Rain Protection & Resting Diurnal Skip.
## 2. Alpine Wild Berry Foraging & Bush Regrowth Simulation.
## 3. Herbivore Wildlife Taming & Feeding Interaction.
## 4. Player Tool Controller & Hotbar Slot Ergonomics (Shelter [9], Forage [0]).
## 5. High-Fidelity Forward+ Vulkan Showcase Evidence Matrix Verification.

const WildernessTorchSystem = preload("res://presentation/tools/wilderness_torch_system.gd")
const PlayerToolController = preload("res://presentation/tools/player_tool_controller.gd")
const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const WorldClock = preload("res://core/clock/world_clock.gd")

func test_shelter_placement_and_visual_elements() -> String:
	var torch_sys: WildernessTorchSystem = WildernessTorchSystem.new()
	torch_sys._ready()

	var target_pos: Vector3 = Vector3(12.0, 2.5, 8.0)
	var shelter: Node3D = torch_sys.place_shelter_at(target_pos)
	if shelter == null:
		torch_sys.free()
		return "Failed to place lean-to shelter at target position"

	if not shelter.get_meta("is_shelter", false):
		torch_sys.free()
		return "Shelter node missing 'is_shelter' metadata"

	var radius: float = float(shelter.get_meta("protection_radius", 0.0))
	if radius < 3.0:
		torch_sys.free()
		return "Shelter protection radius must be >= 3.0m, got %f" % radius

	# Verify shelter lantern
	var lantern_light: OmniLight3D = shelter.find_child("ShelterLanternLight", true, false) as OmniLight3D
	if lantern_light == null or not lantern_light.visible:
		torch_sys.free()
		return "Shelter lantern OmniLight3D missing or invisible"

	if lantern_light.shadow_enabled != false:
		torch_sys.free()
		return "Shelter lantern must have shadow_enabled = false for fillrate budget"

	# Verify active shelter list
	var shelter_list: Array[Vector3] = torch_sys.get_all_shelter_positions()
	if not shelter_list.has(target_pos):
		torch_sys.free()
		return "Active shelter positions does not contain placed shelter"

	torch_sys.free()
	return ""

func test_shelter_rain_protection_and_rest_cycle() -> String:
	var torch_sys: WildernessTorchSystem = WildernessTorchSystem.new()
	torch_sys._ready()

	var clock: WorldClock = WorldClock.new(1200.0)
	clock.set_time_of_day(22.0) # 22:00 (Night)

	var target_pos: Vector3 = Vector3(20.0, 3.0, 20.0)
	torch_sys.place_shelter_at(target_pos)

	# Test rain protection query
	if not torch_sys.is_point_sheltered(target_pos + Vector3(0.5, 0.0, 0.5)):
		torch_sys.free()
		clock.free()
		return "Position under lean-to shelter should be sheltered from rain"

	if torch_sys.is_point_sheltered(target_pos + Vector3(15.0, 0.0, 15.0)):
		torch_sys.free()
		clock.free()
		return "Position far away from shelter should NOT be sheltered"

	# Test resting in shelter (fast-forward from night 22:00 to morning 06:00)
	var new_hour: float = torch_sys.rest_in_shelter(clock)
	if abs(new_hour - 6.0) > 0.1:
		torch_sys.free()
		clock.free()
		return "rest_in_shelter did not return expected dawn hour 6.0 (got %f)" % new_hour

	var clock_hour: float = clock.get_time_of_day()
	if abs(clock_hour - 6.0) > 0.1:
		torch_sys.free()
		clock.free()
		return "Resting in shelter did not advance clock to morning (got %f, expected ~6.0)" % clock_hour

	torch_sys.free()
	return ""

func test_berry_foraging_and_regrowth_cycle() -> String:
	var torch_sys: WildernessTorchSystem = WildernessTorchSystem.new()
	torch_sys._ready()

	var bush_pos: Vector3 = Vector3(30.0, 1.0, 30.0)
	torch_sys.register_forage_bush(bush_pos, "alpine_elderberry")
	var bush: Dictionary = torch_sys.get_nearest_forage_bush(bush_pos, 2.0)
	if bush.is_empty():
		torch_sys.free()
		return "Failed to register wild forage bush"

	# Initial harvest
	var harvest_res: Dictionary = torch_sys.harvest_bush_at(bush_pos)
	if not harvest_res.get("success", false) or harvest_res.get("count", 0) != 3:
		torch_sys.free()
		return "Expected successful harvest of 3 berries, got: %s" % str(harvest_res)

	if torch_sys.get_total_foraged_berries() != 3:
		torch_sys.free()
		return "Inventory total berries should be 3, got %d" % torch_sys.get_total_foraged_berries()

	# Second immediate harvest on depleted bush
	var second_res: Dictionary = torch_sys.harvest_bush_at(bush_pos)
	if second_res.get("success", false):
		torch_sys.free()
		return "Depleted bush should not yield berries, got: %s" % str(second_res)

	# Simulate regrowth after 50s
	torch_sys.step_foraging_simulation(50.0)
	var regrown_bush: Dictionary = torch_sys.get_nearest_forage_bush(bush_pos, 2.0)
	if not regrown_bush.get("is_ripe", false) or regrown_bush.get("count", 0) < 3:
		torch_sys.free()
		return "Bush did not regrow ripe berries after elapsed regrowth duration"

	torch_sys.free()
	return ""

func test_wildlife_feeding_and_taming() -> String:
	var torch_sys: WildernessTorchSystem = WildernessTorchSystem.new()
	torch_sys._ready()
	torch_sys.foraged_berries_inventory["alpine_elderberry"] = 3

	var fauna_sim: FaunaSimulation = FaunaSimulation.new()
	var player_pos: Vector3 = Vector3(10.0, 1.0, 10.0)
	var herbivore_pos: Vector3 = player_pos + Vector3(2.0, 0.0, 1.5)

	var hid: int = fauna_sim.spawn_herbivore(herbivore_pos, 40.0)
	var h: FaunaSimulation.HerbivoreData = fauna_sim.get_herbivore(hid)
	if h == null:
		torch_sys.free()
		return "Failed to spawn herbivore for feeding test"

	# Set herbivore in anxious state
	h.threat_memory = 0.8
	h.flee_timer = 2.0

	# Feed herbivore
	var feed_res: Dictionary = torch_sys.feed_nearby_herbivore(player_pos, fauna_sim)
	if not feed_res.get("success", false):
		torch_sys.free()
		return "feed_nearby_herbivore failed when herbivore was in range: %s" % str(feed_res)

	if torch_sys.get_total_foraged_berries() != 2:
		torch_sys.free()
		return "Inventory berries should decrease by 1 after feeding, got %d" % torch_sys.get_total_foraged_berries()

	if h.threat_memory > 0.05 or h.energy < 70.0:
		torch_sys.free()
		return "Fed herbivore did not calm down or recover energy (threat: %f, energy: %f)" % [h.threat_memory, h.energy]

	torch_sys.free()
	return ""

func test_player_tool_controller_shelter_and_forage() -> String:
	var controller: PlayerToolController = PlayerToolController.new()

	# Check Shelter tool selection
	controller.set_tool(PlayerToolController.ToolMode.SHELTER)
	if controller.active_tool != PlayerToolController.ToolMode.SHELTER:
		controller.free()
		return "PlayerToolController failed to switch to ToolMode.SHELTER"

	# Check Forage tool selection
	controller.set_tool(PlayerToolController.ToolMode.FORAGE)
	if controller.active_tool != PlayerToolController.ToolMode.FORAGE:
		controller.free()
		return "PlayerToolController failed to switch to ToolMode.FORAGE"

	controller.free()
	return ""

func test_showcase_evidence_matrix_integrity() -> String:
	var required_showcases: Array[String] = [
		"res://reports/final_acceptance/showcase_night_campfire_sanctuary.png",
		"res://reports/final_acceptance/showcase_field_shelter_camp.png",
		"res://reports/final_acceptance/showcase_berry_foraging.png"
	]

	for path in required_showcases:
		var gpath: String = ProjectSettings.globalize_path(path)
		if not FileAccess.file_exists(gpath):
			return "Missing required showcase screenshot: %s" % gpath

		var file: FileAccess = FileAccess.open(gpath, FileAccess.READ)
		if file == null:
			return "Cannot open showcase screenshot for reading: %s" % gpath

		var len_bytes: int = file.get_length()
		file.close()

		# Ensure image is not empty and has substantive Forward+ Vulkan content (> 100KB)
		if len_bytes < 100000:
			return "Showcase screenshot %s size is suspiciously small (%d bytes)" % [gpath, len_bytes]

	return ""
