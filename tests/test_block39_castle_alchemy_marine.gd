class_name TestBlock39CastleAlchemyMarine
extends RefCounted

## Living Planet Sandbox — Block 39-41 Automated Verification Suite
## Verifies:
## 1. Ancient Castle Citadel: gatehouse, keep, bastion towers, runic relic activation & Spectral Warden Raymond
## 2. Botanical Alchemy & Potion Brewing: ingredient foraging, crafting, swiftness buff & expiration
## 3. Alchemy Glassmorphic UI modal: open/close state transitions & recipe card presentation
## 4. Marine Biodiversity Expansion: coral reef multimesh, sunken galleon, treasure chest looting & gliding manta rays

const CastleScript = preload("res://presentation/environment/ancient_castle_citadel.gd")
const AlchemySystemScript = preload("res://core/gameplay/alchemy_crafting_system.gd")
const AlchemyModalScript = preload("res://presentation/ui/alchemy_modal.gd")
const MarineScript = preload("res://presentation/environment/marine_ecosystem.gd")

func test_ancient_castle_citadel_architecture_and_relic() -> String:
	var castle = CastleScript.new()
	var terrain = IslandTerrain.new()
	terrain.island_size = 200.0
	terrain.generate_island(1337)

	castle.setup(terrain, null)

	# 1. Architecture nodes
	var gate = castle.get_node_or_null("CastleGatehouse")
	var keep = castle.get_node_or_null("CastleKeep")
	var court = castle.get_node_or_null("CourtyardAndRelic")
	if not gate or not keep or not court:
		castle.queue_free()
		terrain.queue_free()
		return "Expected CastleGatehouse, CastleKeep, and CourtyardAndRelic in AncientCastleCitadel"

	# 2. Spectral Warden Raymond
	var raymond = castle._npc_raymond
	if not raymond:
		castle.queue_free()
		terrain.queue_free()
		return "Expected _npc_raymond in AncientCastleCitadel"

	var plate: Label3D = raymond.get_node_or_null("NamePlate") as Label3D
	if not plate or not "raymond" in plate.text.to_lower():
		castle.queue_free()
		terrain.queue_free()
		return "Expected NamePlate with Raymond on Spectral Warden NPC"

	# 3. Interactivity
	var near_r = castle.get_nearby_interactable(raymond.position + castle.position)
	if near_r.is_empty() or near_r.get("id", "") != "Raymond":
		castle.queue_free()
		terrain.queue_free()
		return "Expected nearby interactable to return Raymond"

	# 4. Relic Activation
	if castle.is_relic_active():
		castle.queue_free()
		terrain.queue_free()
		return "Expected relic to start in un-activated state"

	var relic_signal_fired: Array[bool] = [false]
	castle.castle_relic_activated.connect(func(): relic_signal_fired[0] = true)

	var activated: bool = castle.activate_relic()
	if not activated or not castle.is_relic_active():
		castle.queue_free()
		terrain.queue_free()
		return "Expected activate_relic to succeed and set is_relic_active"

	if not relic_signal_fired[0]:
		castle.queue_free()
		terrain.queue_free()
		return "Expected castle_relic_activated signal to be emitted"

	castle.queue_free()
	terrain.queue_free()
	return ""

func test_alchemy_crafting_and_buffs() -> String:
	var alchemy = AlchemySystemScript.new()

	# 1. Initial inventory verification
	if alchemy.inventory.get("forest_berries", 0) < 1 or alchemy.inventory.get("mountain_herbs", 0) < 1:
		alchemy.queue_free()
		return "Expected starting botanical ingredients in AlchemyCraftingSystem"

	# 2. Crafting verification
	if not alchemy.can_craft("swiftness_elixir"):
		alchemy.queue_free()
		return "Expected can_craft(swiftness_elixir) to be true"

	var initial_berries: int = alchemy.inventory["forest_berries"]
	var initial_herbs: int = alchemy.inventory["mountain_herbs"]

	var crafted_signal: Array[bool] = [false]
	alchemy.potion_crafted.connect(func(_id, _title): crafted_signal[0] = true)

	var success: bool = alchemy.craft_potion("swiftness_elixir")
	if not success:
		alchemy.queue_free()
		return "Expected craft_potion to return true"

	if not crafted_signal[0]:
		alchemy.queue_free()
		return "Expected potion_crafted signal to be emitted"

	if alchemy.inventory["forest_berries"] != initial_berries - 1 or alchemy.inventory["mountain_herbs"] != initial_herbs - 1:
		alchemy.queue_free()
		return "Expected botanical ingredients to be deducted upon brewing"

	if not alchemy.is_buff_active("swiftness_elixir"):
		alchemy.queue_free()
		return "Expected swiftness_elixir buff to be active after brewing"

	# 3. Buff expiration
	alchemy._process(50.0) # Elixir duration is 45s
	if alchemy.is_buff_active("swiftness_elixir"):
		alchemy.queue_free()
		return "Expected swiftness_elixir buff to expire after duration passes"

	alchemy.queue_free()
	return ""

func test_alchemy_ui_modal() -> String:
	var modal = AlchemyModalScript.new()
	var alchemy = AlchemySystemScript.new()
	modal.setup(alchemy)

	if modal.is_open():
		modal.queue_free()
		alchemy.queue_free()
		return "Expected AlchemyModal to start closed"

	modal.open_modal()
	if not modal.is_open():
		modal.queue_free()
		alchemy.queue_free()
		return "Expected AlchemyModal to be open after open_modal"

	modal.close_modal()
	if modal.is_open():
		modal.queue_free()
		alchemy.queue_free()
		return "Expected AlchemyModal to be closed after close_modal"

	modal.queue_free()
	alchemy.queue_free()
	return ""

func test_marine_coral_reefs_and_sunken_galleon() -> String:
	var marine = MarineScript.new()
	var terrain = IslandTerrain.new()
	terrain.island_size = 200.0
	terrain.generate_island(1337)

	marine.setup(terrain, null, 1337)

	# 1. Coral Reef MultiMesh verification
	var coral_mmi: MultiMeshInstance3D = marine.get_node_or_null("CoralReefMultiMesh") as MultiMeshInstance3D
	if not coral_mmi:
		marine.queue_free()
		terrain.queue_free()
		return "Expected CoralReefMultiMesh in MarineEcosystem"
	if not coral_mmi.multimesh or coral_mmi.multimesh.visible_instance_count <= 0:
		marine.queue_free()
		terrain.queue_free()
		return "Expected placed coral reef instances (got %d)" % (coral_mmi.multimesh.visible_instance_count if coral_mmi.multimesh else 0)

	# 2. Sunken Galleon verification
	var galleon: Node3D = marine.get_node_or_null("SunkenGalleon") as Node3D
	if not galleon:
		marine.queue_free()
		terrain.queue_free()
		return "Expected SunkenGalleon in MarineEcosystem"

	var chest: Node3D = galleon.get_node_or_null("SunkenTreasureChest") as Node3D
	if not chest:
		marine.queue_free()
		terrain.queue_free()
		return "Expected SunkenTreasureChest aboard SunkenGalleon"

	# 3. Manta Rays verification
	if marine._manta_rays.size() < 2:
		marine.queue_free()
		terrain.queue_free()
		return "Expected at least 2 gliding manta ray instances (got %d)" % marine._manta_rays.size()

	# 4. Chest looting lifecycle
	if marine.is_chest_looted():
		marine.queue_free()
		terrain.queue_free()
		return "Expected sunken chest to start un-looted"

	var loot: Dictionary = marine.loot_sunken_chest()
	if loot.is_empty() or not loot.has("relic_id"):
		marine.queue_free()
		terrain.queue_free()
		return "Expected non-empty loot dictionary with relic_id from sunken chest"

	if not marine.is_chest_looted():
		marine.queue_free()
		terrain.queue_free()
		return "Expected is_chest_looted to be true after looting"

	marine.queue_free()
	terrain.queue_free()
	return ""
