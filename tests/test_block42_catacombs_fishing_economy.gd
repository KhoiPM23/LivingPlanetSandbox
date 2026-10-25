class_name TestBlock42CatacombsFishingEconomy
extends RefCounted

## Living Planet Sandbox — Block 42-45 Automated Verification Suite
## Verifies:
## 1. Castle Catacombs Crypt & Royal Sarcophagus brazier puzzle mechanics
## 2. Dynamic boat & shore FishingSystem state machine, bite timers & marine catch tables
## 3. Haven Village Harbor Market Stall, Merchant Milo NPC, Cooking Hearth & Night Lighting
## 4. Expanded Alchemy Economy: Haven Coins currency & advanced marine recipes
## 5. Genshin-Style HUD Compass Bar waypoints & Wind Wisps Particles

const CastleScript = preload("res://presentation/environment/ancient_castle_citadel.gd")
const FishingScript = preload("res://core/gameplay/fishing_system.gd")
const VillageScript = preload("res://presentation/environment/medieval_haven_village.gd")
const AlchemySystemScript = preload("res://core/gameplay/alchemy_crafting_system.gd")
const CompassScript = preload("res://presentation/ui/hud_compass_bar.gd")
const WindWispsScript = preload("res://presentation/environment/wind_wisps_particles.gd")

func test_castle_catacombs_and_sarcophagus_puzzle() -> String:
	var castle = CastleScript.new()
	var terrain = IslandTerrain.new()
	terrain.island_size = 200.0
	terrain.generate_island(1337)

	castle.setup(terrain, null)

	# 1. Structure verification
	var catacombs = castle.get_node_or_null("CastleCatacombs")
	var stairwell = castle.get_node_or_null("CryptStairwell")
	if not catacombs or not stairwell:
		castle.queue_free()
		terrain.queue_free()
		return "Expected CastleCatacombs and CryptStairwell in AncientCastleCitadel"

	var b_alpha = catacombs.get_node_or_null("CatacombBrazierAlpha")
	var b_beta = catacombs.get_node_or_null("CatacombBrazierBeta")
	var sarc = catacombs.get_node_or_null("AncientSarcophagus")
	if not b_alpha or not b_beta or not sarc:
		castle.queue_free()
		terrain.queue_free()
		return "Expected CatacombBrazierAlpha, CatacombBrazierBeta, and AncientSarcophagus in CastleCatacombs"

	# 2. Initial puzzle state: locked
	if castle.is_brazier_lit("CatacombBrazierAlpha") or castle.is_brazier_lit("CatacombBrazierBeta"):
		castle.queue_free()
		terrain.queue_free()
		return "Expected braziers to start unlit"

	if castle.are_both_braziers_lit():
		castle.queue_free()
		terrain.queue_free()
		return "Expected are_both_braziers_lit() to be false initially"

	var early_loot: Dictionary = castle.open_sarcophagus()
	if not early_loot.is_empty():
		castle.queue_free()
		terrain.queue_free()
		return "Expected open_sarcophagus() to return empty dict when braziers are not lit"

	# 3. Light Braziers
	var b_sig: Array[String] = [""]
	castle.brazier_lit.connect(func(id: String): b_sig[0] = id)

	var lit_a = castle.light_brazier("CatacombBrazierAlpha")
	if not lit_a or not castle.is_brazier_lit("CatacombBrazierAlpha") or b_sig[0] != "CatacombBrazierAlpha":
		castle.queue_free()
		terrain.queue_free()
		return "Expected Brazier Alpha to ignite and emit signal"

	var lit_b = castle.light_brazier("CatacombBrazierBeta")
	if not lit_b or not castle.is_brazier_lit("CatacombBrazierBeta") or not castle.are_both_braziers_lit():
		castle.queue_free()
		terrain.queue_free()
		return "Expected Brazier Beta to ignite and are_both_braziers_lit() to be true"

	# 4. Open Sarcophagus
	var s_sig: Array[String] = [""]
	castle.sarcophagus_opened.connect(func(seal: String): s_sig[0] = seal)

	var loot: Dictionary = castle.open_sarcophagus()
	if loot.get("item", "") != "ancient_royal_seal":
		castle.queue_free()
		terrain.queue_free()
		return "Expected ancient_royal_seal from open_sarcophagus()"

	if not castle.has_royal_seal() or not castle.is_sarcophagus_looted():
		castle.queue_free()
		terrain.queue_free()
		return "Expected has_royal_seal() and is_sarcophagus_looted() to be true"

	if s_sig[0] != "ancient_royal_seal":
		castle.queue_free()
		terrain.queue_free()
		return "Expected sarcophagus_opened signal to emit ancient_royal_seal"

	# Cannot double-loot
	var second_loot: Dictionary = castle.open_sarcophagus()
	if not second_loot.is_empty():
		castle.queue_free()
		terrain.queue_free()
		return "Expected second open_sarcophagus() call to return empty dict"

	castle.queue_free()
	terrain.queue_free()
	return ""

func test_fishing_system_lifecycle_and_catches() -> String:
	var fs = FishingScript.new()

	# 1. State machine transitions
	if fs.is_fishing() or fs.is_biting():
		fs.queue_free()
		return "Expected FishingSystem to start in IDLE state"

	var started = fs.start_fishing(false, false)
	if not started or not fs.is_fishing():
		fs.queue_free()
		return "Expected start_fishing to succeed and transition to fishing state"

	# Advance into WAITING
	fs.update(0.016)
	if fs.state != FishingScript.State.WAITING:
		fs.queue_free()
		return "Expected FishingSystem to transition from CASTING to WAITING"

	# Force bite by decrementing bite_wait_timer
	fs.bite_wait_timer = 0.01
	fs.update(0.02)
	if not fs.is_biting() or fs.state != FishingScript.State.BITING:
		fs.queue_free()
		return "Expected FishingSystem to transition to BITING when timer expires"

	# Strike catch
	var catch = fs.attempt_reel()
	if not catch.get("success", false):
		fs.queue_free()
		return "Expected attempt_reel to succeed during BITING window"

	var sp_id = catch.get("species_id", "")
	if sp_id != "emerald_salmon" and sp_id != "pearl_oyster":
		fs.queue_free()
		return "Expected emerald_salmon or pearl_oyster from shallow water catch, got: %s" % sp_id

	if fs.is_fishing():
		fs.queue_free()
		return "Expected state to return to IDLE after reeling"

	# Test deep sea catch
	fs.start_fishing(true, true) # deep sea + lure
	fs.update(0.016)
	fs.bite_wait_timer = 0.01
	fs.update(0.02)
	var deep_catch = fs.attempt_reel()
	var deep_sp = deep_catch.get("species_id", "")
	if deep_sp != "golden_sunfish" and deep_sp != "pearl_oyster":
		fs.queue_free()
		return "Expected golden_sunfish or pearl_oyster from deep sea catch, got: %s" % deep_sp

	# Test cancel
	fs.start_fishing(false, false)
	fs.cancel_fishing()
	if fs.is_fishing():
		fs.queue_free()
		return "Expected cancel_fishing to reset to IDLE"

	fs.queue_free()
	return ""

func test_haven_village_market_milo_and_cooking_hearth() -> String:
	var village = VillageScript.new()
	var terrain = IslandTerrain.new()
	terrain.island_size = 200.0
	terrain.generate_island(1337)

	village.setup(terrain, null)

	# 1. Market stall and cooking hearth nodes
	var stall = village.get_node_or_null("HarborMarketStall")
	var hearth = village.get_node_or_null("VillageCookingHearth")
	if not stall or not hearth:
		village.queue_free()
		terrain.queue_free()
		return "Expected HarborMarketStall and VillageCookingHearth in MedievalHavenVillage"

	# 2. Merchant Milo NPC
	var milo = village._npc_milo
	if not milo:
		village.queue_free()
		terrain.queue_free()
		return "Expected _npc_milo in MedievalHavenVillage"

	var m_plate: Label3D = milo.get_node_or_null("NamePlate") as Label3D
	if not m_plate or not "milo" in m_plate.text.to_lower():
		village.queue_free()
		terrain.queue_free()
		return "Expected NamePlate containing 'Milo' on merchant NPC"

	# 3. Interactivity checks
	var near_milo = village.get_nearby_interactable(milo.position)
	if near_milo.get("id", "") != "Milo":
		village.queue_free()
		terrain.queue_free()
		return "Expected nearby interactable near Milo to return id 'Milo'"

	var near_hearth = village.get_nearby_interactable(hearth.position)
	if near_hearth.get("id", "") != "VillageHearth":
		village.queue_free()
		terrain.queue_free()
		return "Expected nearby interactable near hearth to return id 'VillageHearth'"

	# 4. Street lantern night lighting toggle
	village.set_night_lighting(false)
	for light in village._street_lantern_lights:
		if light.visible:
			village.queue_free()
			terrain.queue_free()
			return "Expected lantern light to be invisible during day"

	village.set_night_lighting(true)
	for light in village._street_lantern_lights:
		if not light.visible:
			village.queue_free()
			terrain.queue_free()
			return "Expected lantern light to be visible at night"

	village.queue_free()
	terrain.queue_free()
	return ""

func test_expanded_alchemy_economy_and_recipes() -> String:
	var alchemy = AlchemySystemScript.new()

	# 1. Currency management
	if alchemy.get_coins() != 50:
		alchemy.queue_free()
		return "Expected starting coins to be 50, got: %d" % alchemy.get_coins()

	alchemy.add_coins(30)
	if alchemy.get_coins() != 80:
		alchemy.queue_free()
		return "Expected coins to be 80 after adding 30"

	var spent = alchemy.spend_coins(25)
	if not spent or alchemy.get_coins() != 55:
		alchemy.queue_free()
		return "Expected spend_coins(25) to succeed and balance to be 55"

	var overspend = alchemy.spend_coins(999)
	if overspend or alchemy.get_coins() != 55:
		alchemy.queue_free()
		return "Expected spend_coins(999) to fail and balance to remain 55"

	# 2. Marine recipes
	if not alchemy.RECIPES.has("herb_salmon_soup"):
		alchemy.queue_free()
		return "Expected recipe 'herb_salmon_soup' in AlchemyCraftingSystem"

	if not alchemy.RECIPES.has("abyssal_clarity_elixir"):
		alchemy.queue_free()
		return "Expected recipe 'abyssal_clarity_elixir' in AlchemyCraftingSystem"

	if not alchemy.RECIPES.has("solar_sovereign_tonic"):
		alchemy.queue_free()
		return "Expected recipe 'solar_sovereign_tonic' in AlchemyCraftingSystem"

	# 3. Add ingredients & Craft Herb Salmon Soup
	if alchemy.can_craft("herb_salmon_soup"):
		alchemy.queue_free()
		return "Expected can_craft('herb_salmon_soup') to be false before adding salmon"

	alchemy.add_ingredient("emerald_salmon", 1)
	if not alchemy.can_craft("herb_salmon_soup"):
		alchemy.queue_free()
		return "Expected can_craft('herb_salmon_soup') to be true after adding salmon"

	var crafted = alchemy.craft_potion("herb_salmon_soup")
	if not crafted or not alchemy.is_buff_active("herb_salmon_soup"):
		alchemy.queue_free()
		return "Expected craft_potion to succeed and buff to be active"

	alchemy.queue_free()
	return ""

func test_hud_compass_bar_and_wind_wisps() -> String:
	# 1. Compass Bar
	var compass = CompassScript.new()
	if compass.waypoints.is_empty():
		compass.queue_free()
		return "Expected waypoints in HUDCompassBar"

	var found_village: bool = false
	var found_castle: bool = false
	for wp in compass.waypoints:
		if wp.get("id", "") == "village":
			found_village = true
		elif wp.get("id", "") == "castle":
			found_castle = true

	if not found_village or not found_castle:
		compass.queue_free()
		return "Expected village and castle waypoints in HUDCompassBar"

	# 2. Wind Wisps
	var wisps = WindWispsScript.new()
	if wisps.amount != 48:
		compass.queue_free()
		wisps.queue_free()
		return "Expected WindWispsParticles3D amount to be 48"

	if not wisps.process_material is ParticleProcessMaterial:
		compass.queue_free()
		wisps.queue_free()
		return "Expected ParticleProcessMaterial on WindWispsParticles3D"

	compass.queue_free()
	wisps.queue_free()
	return ""
