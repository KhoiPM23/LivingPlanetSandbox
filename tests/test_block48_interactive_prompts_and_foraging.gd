class_name TestBlock48InteractivePromptsAndForaging
extends RefCounted

## Automated Contract Test Suite for Block 48:
## 1. InteractionPromptHUD lifecycle, prompts & toast alerts
## 2. ForagingNodes procedural generation, proximity check & collection
## 3. Character anime water ripples & movement particle systems

func run_all() -> Dictionary:
	var results: Dictionary = {
		"suite": "Block 48 (Prompts & Foraging)",
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	test_interaction_prompt_hud_lifecycle(results)
	test_foraging_nodes_generation_and_collection(results)
	test_character_anime_particles(results)

	return results

func test_interaction_prompt_hud_lifecycle(results: Dictionary = {}) -> Variant:
	var hud: InteractionPromptHUD = InteractionPromptHUD.new()
	if not hud:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Failed to instantiate InteractionPromptHUD")
		return "Failed to instantiate InteractionPromptHUD"

	hud._ready()

	# 1. Test prompt display
	hud.show_prompt("herb_gather", "Thu thập", "Cỏ Gió Vực Thẳm", "🌸")
	if not hud.is_prompt_visible() or hud.get_active_prompt_id() != "herb_gather":
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Prompt failed to activate with correct active ID")
		hud.free()
		return "Prompt failed to activate"

	# 2. Test prompt hide
	hud.hide_prompt("herb_gather")
	if hud.is_prompt_visible():
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Prompt failed to hide upon request")
		hud.free()
		return "Prompt failed to hide"

	# 3. Test pickup toast container
	hud.show_pickup_toast("Cỏ Gió Vực Thẳm", 1, "🌸")
	var tc = hud.get_node_or_null("ToastContainer")
	if not tc or tc.get_child_count() == 0:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Toast card was not added to ToastContainer")
		hud.free()
		return "ToastContainer empty"

	hud.free()
	if results.has("passed"): results["passed"] += 1
	print("  [PASS] test_interaction_prompt_hud_lifecycle")
	return true

func test_foraging_nodes_generation_and_collection(results: Dictionary = {}) -> Variant:
	var foraging: ForagingNodes = ForagingNodes.new()
	foraging.setup(null, 1337)

	var total: int = foraging.get_total_nodes()
	if total < 15:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("ForagingNodes generated insufficient nodes (%d < 15)" % total)
		foraging.free()
		return "Insufficient nodes"

	# Find a node and test proximity
	var first_node = foraging.nodes[0]
	var nearby: Dictionary = foraging.get_nearby_forageable(first_node.pos, 3.0)
	if nearby.is_empty() or nearby["id"] != first_node.id:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Proximity detection failed for node %s" % first_node.id)
		foraging.free()
		return "Proximity detection failed"

	# Test collection
	var harvest: Dictionary = foraging.collect_node(first_node.id)
	if harvest.is_empty() or harvest["count"] < 1:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Collection failed for node %s" % first_node.id)
		foraging.free()
		return "Collection failed"

	if not first_node.is_collected:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Node state was not marked is_collected")
		foraging.free()
		return "is_collected false"

	# Node should no longer be detectable
	var nearby_after: Dictionary = foraging.get_nearby_forageable(first_node.pos, 3.0)
	if not nearby_after.is_empty() and nearby_after.get("id") == first_node.id:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("Collected node is still detectable")
		foraging.free()
		return "Collected node still detectable"

	foraging.free()
	if results.has("passed"): results["passed"] += 1
	print("  [PASS] test_foraging_nodes_generation_and_collection")
	return true

func test_character_anime_particles(results: Dictionary = {}) -> Variant:
	var walker: FirstPersonWalker = FirstPersonWalker.new()
	walker._ready()

	var dash_p = walker.get_node_or_null("AnimeDashParticles")
	var ripple_p = walker.get_node_or_null("WaterRippleParticles")
	var glider = walker._model_root.get_node_or_null("AnemoGliderWings") if walker._model_root else null

	if not dash_p:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("AnimeDashParticles missing on FirstPersonWalker")
		walker.free()
		return "AnimeDashParticles missing"

	if not ripple_p:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("WaterRippleParticles missing on FirstPersonWalker")
		walker.free()
		return "WaterRippleParticles missing"

	if not glider:
		if results.has("failed"): results["failed"] += 1
		if results.has("errors"): results["errors"].append("AnemoGliderWings missing on character model root")
		walker.free()
		return "AnemoGliderWings missing"

	walker.free()
	if results.has("passed"): results["passed"] += 1
	print("  [PASS] test_character_anime_particles")
	return true
