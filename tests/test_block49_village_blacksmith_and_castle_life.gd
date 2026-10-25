class_name TestBlock49VillageBlacksmithAndCastleLife
extends RefCounted

## Automated Contract Test Suite for Block 49:
## 1. Medieval Village Blacksmith Goran, Forge, Practice Dummy & Lighthouse Beam
## 2. Dynamic Commission Objectives (Blacksmith Tinkering & Wild Herbs Foraging)

func run_all() -> Dictionary:
	var results: Dictionary = {
		"suite": "Block 49 (Village Life & Blacksmith)",
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	test_medieval_village_blacksmith_and_dummy(results)
	test_blacksmith_and_foraging_commissions(results)

	return results

func test_medieval_village_blacksmith_and_dummy(results: Dictionary = {}) -> Variant:
	var village: MedievalHavenVillage = MedievalHavenVillage.new()
	village.setup(null, null)

	# Verify Goran NPC
	if not village._npc_goran:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Goran NPC was not spawned in village")
		village.free()
		return "Goran NPC missing"

	# Verify Blacksmith Forge
	if not village._blacksmith_forge:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Blacksmith Forge was not built")
		village.free()
		return "Blacksmith forge missing"

	# Verify Practice Dummy
	if not village._training_dummy:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Training Dummy was not built")
		village.free()
		return "Training dummy missing"

	# Verify Lighthouse Beam
	if not village._lighthouse_beam:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Lighthouse Beam was not instantiated")
		village.free()
		return "Lighthouse beam missing"

	# Test dummy strike wobble
	village.strike_practice_dummy()
	if village._dummy_wobble_time <= 0.0:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("strike_practice_dummy() did not initiate wobble oscillation")
		village.free()
		return "Dummy did not wobble"

	# Test proximity interactables
	var dummy_pos: Vector3 = village._training_dummy.position
	var d_interact: Dictionary = village.get_nearby_interactable(dummy_pos)
	if d_interact.get("id") != "PracticeDummy":
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Practice dummy proximity interaction failed: %s" % str(d_interact))
		village.free()
		return "Practice dummy proximity failed"

	var goran_pos: Vector3 = village._npc_goran.position
	var g_interact: Dictionary = village.get_nearby_interactable(goran_pos)
	if g_interact.get("id") != "Goran":
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Goran proximity interaction failed: %s" % str(g_interact))
		village.free()
		return "Goran proximity failed"

	village.free()
	if results.has("passed"): results["passed"] += 1
	print("  [PASS] test_medieval_village_blacksmith_and_dummy")
	return true

func test_blacksmith_and_foraging_commissions(results: Dictionary = {}) -> Variant:
	var expedition: ExpeditionManager = ExpeditionManager.new()

	# Register quests
	expedition.add_custom_commission("blacksmith_tinkering", "🔨 Thử Luyện Thao Trường", "Tấn công bù nhìn tập luyện tại thao trường", "VILLAGE", 1, 250)
	expedition.add_custom_commission("forage_wild_herbs", "🌿 Thu Thập Dược Thảo Hoang Dã", "Thu thập 3 mẫu thảo dược hoang dã quanh các quần xã trên đảo", "VILLAGE", 3, 300)

	var quests: Array[Dictionary] = expedition.get_active_quests()
	if quests.size() < 2:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Failed to accept village commissions")
		expedition.free()
		return "Failed to accept commissions"

	# Advance blacksmith quest
	var completed_bt: bool = expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "blacksmith_tinkering"})
	if not completed_bt:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("blacksmith_tinkering did not complete after target action")
		expedition.free()
		return "blacksmith_tinkering did not complete"

	# Advance forage quest 3 times
	expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "forage_wild_herbs"})
	expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "forage_wild_herbs"})
	var completed_fh: bool = expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "forage_wild_herbs"})
	if not completed_fh:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("forage_wild_herbs did not complete after 3 gathers")
		expedition.free()
		return "forage_wild_herbs did not complete"

	expedition.free()
	if results.has("passed"): results["passed"] += 1
	print("  [PASS] test_blacksmith_and_foraging_commissions")
	return true
