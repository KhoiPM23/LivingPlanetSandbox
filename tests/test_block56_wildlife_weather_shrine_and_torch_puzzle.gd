class_name TestBlock56WildlifeWeatherShrineAndTorchPuzzle
extends RefCounted

## Living Planet Sandbox — Block 56 Automated Regression Test Suite
## Validates Woodland Wildlife Ecosystem (Fox & Squirrel FSM, 16-bit PCM audio),
## Campfire Weather & Cooking Director (weather rain reaction, sizzling audio, hearth recipes),
## Genshin-Style Shrine of Depths (hexagonal columns, seal barrier, Luxurious Chest),
## Genshin-Style Elemental Pyro Torch Puzzle (4 braziers, 15s timer, Exquisite Chest),
## and Circular Minimap HUD landmark tracking.

const WoodlandWildlifeEcosystemScript = preload("res://presentation/fauna/woodland_wildlife_ecosystem.gd")
const CampfireWeatherDirectorScript = preload("res://presentation/environment/campfire_weather_director.gd")
const ShrineOfDepthsScript = preload("res://presentation/environment/shrine_of_depths.gd")
const ElementalTorchPuzzleScript = preload("res://presentation/environment/elemental_torch_puzzle.gd")
const CircularMinimapHUDScript = preload("res://presentation/ui/circular_minimap_hud.gd")

func test_woodland_wildlife_fox_and_squirrel_fsm() -> String:
	var ecosystem = WoodlandWildlifeEcosystemScript.new()
	if ecosystem == null:
		return "Failed to instantiate WoodlandWildlifeEcosystem"

	# Check population counts: 3 foxes, 4 squirrels
	if ecosystem._foxes.size() != 3:
		return "Expected 3 red foxes spawned, got %d" % ecosystem._foxes.size()
	if ecosystem._squirrels.size() != 4:
		return "Expected 4 ground squirrels spawned, got %d" % ecosystem._squirrels.size()

	# Check procedural audio generation
	if ecosystem._audio_player == null:
		return "WoodlandWildlifeEcosystem missing _audio_player"
	if ecosystem._fox_bark_wav == null or ecosystem._fox_bark_wav.data.is_empty():
		return "Fox bark procedural audio stream is missing or empty"
	if ecosystem._squirrel_chirp_wav == null or ecosystem._squirrel_chirp_wav.data.is_empty():
		return "Squirrel chirp procedural audio stream is missing or empty"

	# Test Fox initial state & behavior tick
	var fox0 = ecosystem._foxes[0]
	if fox0["state"] != WoodlandWildlifeEcosystemScript.FoxState.FORAGING:
		return "Expected fox0 to start in FORAGING state, got %d" % fox0["state"]

	var init_pos: Vector3 = fox0["curr_pos"]
	ecosystem.update_behavior(0.1, Vector3.ZERO, 0.0)
	if fox0["curr_pos"] == init_pos:
		return "Fox position did not update during foraging tick"

	# Test Fox alert/flee reaction when player sprints nearby
	ecosystem.update_behavior(0.1, fox0["curr_pos"] + Vector3(1.0, 0.0, 1.0), 6.5)
	if fox0["state"] != WoodlandWildlifeEcosystemScript.FoxState.ALERT and fox0["state"] != WoodlandWildlifeEcosystemScript.FoxState.FLEEING:
		return "Fox should have triggered ALERT or FLEEING state when sprinting player is within 8m"

	# Test Squirrel behavior tick & state validation
	var sq0 = ecosystem._squirrels[0]
	var sq_init_pos: Vector3 = sq0["curr_pos"]
	ecosystem.update_behavior(0.1, Vector3.ZERO, 0.0)
	if sq0["state"] != WoodlandWildlifeEcosystemScript.SquirrelState.HOPPING and sq0["state"] != WoodlandWildlifeEcosystemScript.SquirrelState.PAUSED and sq0["state"] != WoodlandWildlifeEcosystemScript.SquirrelState.PERISCOPE:
		return "Squirrel initial state invalid"

	ecosystem.free()
	return ""

func test_campfire_weather_reaction_and_cooking() -> String:
	var director = CampfireWeatherDirectorScript.new()
	if director == null:
		return "Failed to instantiate CampfireWeatherDirector"

	# Check procedural audio synthesizer
	if director._sizzle_wav == null or director._sizzle_wav.data.is_empty():
		return "CampfireWeatherDirector procedural sizzle audio stream is empty"

	# Test weather reaction dynamics
	# 1. Rain storm reaction
	director.update_weather_reaction(0.5, 0.8) # Rain intensity 0.8
	if not director.is_raining:
		return "Expected is_raining to be true when rain intensity is 0.8"
	if director.steam_level <= 0.0:
		return "Expected steam_level to rise during rain reaction"

	# 2. Clear skies reaction
	director.update_weather_reaction(1.0, 0.0) # Clear skies
	if director.is_raining:
		return "Expected is_raining to be false when rain intensity is 0.0"

	# Test cooking recipes
	if not director.recipes.has("grilled_salmon") or not director.recipes.has("sweet_jam"):
		return "Missing standard campfire recipes: grilled_salmon or sweet_jam"

	var mock_inventory = {
		"emerald_salmon": 1,
		"wild_raspberry": 3,
		"star_lotus": 1,
		"highland_mint": 1
	}

	# Test can_cook_recipe
	if not director.can_cook_recipe("grilled_salmon", mock_inventory):
		return "Expected can_cook_recipe('grilled_salmon') to be true with sufficient ingredients"

	var cooked_dish = director.cook_recipe("grilled_salmon", mock_inventory)
	if cooked_dish.is_empty():
		return "Failed to cook grilled_salmon"
	if cooked_dish.get("dish_id", "") != "grilled_salmon":
		return "Unexpected dish_id returned from cook_recipe"
	if mock_inventory.get("emerald_salmon", -1) != 0:
		return "Ingredients were not correctly deducted from inventory after cooking"

	# Check sweet_jam cooking
	if not director.can_cook_recipe("sweet_jam", mock_inventory):
		return "Expected can_cook_recipe('sweet_jam') to be true with 2 raspberries"
	var jam = director.cook_recipe("sweet_jam", mock_inventory)
	if jam.is_empty() or mock_inventory.get("wild_raspberry", -1) != 0:
		return "Failed to cook sweet_jam or ingredients not deducted"

	director.free()
	return ""

func test_shrine_of_depths_barrier_and_luxurious_chest() -> String:
	var shrine = ShrineOfDepthsScript.new()
	if shrine == null:
		return "Failed to instantiate ShrineOfDepths"

	if not shrine.is_barrier_sealed:
		return "Shrine barrier should be sealed by default"
	if shrine.is_chest_opened:
		return "Shrine chest should be closed by default"
	if shrine._barrier_meshes.size() != 6:
		return "Expected 6 barrier archway meshes, got %d" % shrine._barrier_meshes.size()
	if shrine._shatter_wav == null or shrine._shatter_wav.data.is_empty():
		return "Shrine procedural seal shatter audio stream is empty"

	# Check proximity detection before unlock
	var near_inter = shrine.get_nearby_interactable(shrine.position, 2.0)
	if near_inter.is_empty() or near_inter.get("id", "") != "shrine_barrier":
		return "Expected 'shrine_barrier' prompt while barrier is sealed"

	# Test barrier unlocking
	var unlocked = shrine.unlock_shrine()
	if not unlocked:
		return "unlock_shrine() failed"
	if shrine.is_barrier_sealed:
		return "is_barrier_sealed should be false after unlocking"
	if shrine._barrier_root.visible:
		return "Barrier root should be hidden after unlocking"

	# Double unlock should return false
	if shrine.unlock_shrine():
		return "Second unlock_shrine() call should have returned false"

	# Check proximity detection after barrier unlock
	var chest_inter = shrine.get_nearby_interactable(shrine.position, 2.0)
	if chest_inter.is_empty() or chest_inter.get("id", "") != "shrine_chest":
		return "Expected 'shrine_chest' prompt after barrier is dispelled"

	# Test opening Luxurious Chest
	var reward = shrine.open_luxurious_chest()
	if reward.is_empty():
		return "open_luxurious_chest() returned empty reward"
	if reward.get("exp", 0) != 500 or reward.get("coins", 0) != 200:
		return "Unexpected chest reward values: %s" % str(reward)
	if reward.get("artifact", "") != "anemo_soaring_feather":
		return "Expected artifact 'anemo_soaring_feather' in reward"
	if not shrine.is_chest_opened:
		return "is_chest_opened should be true after opening chest"

	# Opening again should return empty
	if not shrine.open_luxurious_chest().is_empty():
		return "Second call to open_luxurious_chest() should return empty"

	shrine.free()
	return ""

func test_elemental_torch_puzzle_ignite_and_solve() -> String:
	var puzzle = ElementalTorchPuzzleScript.new()
	if puzzle == null:
		return "Failed to instantiate ElementalTorchPuzzle"

	if puzzle._torches.size() != 4:
		return "Expected 4 torches in puzzle, got %d" % puzzle._torches.size()
	if puzzle.get_lit_count() != 0:
		return "Expected 0 lit torches initially, got %d" % puzzle.get_lit_count()
	if puzzle._is_puzzle_solved:
		return "Puzzle should not be solved initially"
	if puzzle._chest_root.visible:
		return "Chest root should be hidden initially"
	if puzzle._ignite_wav == null or puzzle._solve_wav == null:
		return "Puzzle procedural audio streams missing"

	# Test lighting torch 0
	var lit0 = puzzle.ignite_torch(0)
	if not lit0:
		return "Failed to ignite torch 0"
	if puzzle.get_lit_count() != 1:
		return "Expected 1 lit torch, got %d" % puzzle.get_lit_count()
	if puzzle._puzzle_timer != ElementalTorchPuzzleScript.PUZZLE_TIME_LIMIT:
		return "Expected puzzle timer to be set to %f" % ElementalTorchPuzzleScript.PUZZLE_TIME_LIMIT

	# Test igniting same torch returns false
	if puzzle.ignite_torch(0):
		return "Igniting already lit torch should return false"

	# Test timer expiration resets torches
	puzzle._process(16.0) # Exceed 15s time limit
	if puzzle.get_lit_count() != 0:
		return "Expected torches to extinguish after timer expires, got %d" % puzzle.get_lit_count()

	# Test lighting all 4 torches in sequence to solve
	puzzle.ignite_torch(0)
	puzzle.ignite_torch(1)
	puzzle.ignite_torch(2)
	puzzle.ignite_torch(3)

	if not puzzle._is_puzzle_solved:
		return "Expected puzzle to be solved when all 4 torches are lit"
	if not puzzle._chest_root.visible:
		return "Exquisite chest root should be visible upon solve"

	# Test opening puzzle chest
	var reward = puzzle.open_puzzle_chest()
	if reward.is_empty():
		return "open_puzzle_chest() returned empty reward"
	if reward.get("exp", 0) != 220 or reward.get("coins", 0) != 75:
		return "Unexpected chest rewards: %s" % str(reward)
	if reward.get("item", "") != "fire_crystal":
		return "Expected item 'fire_crystal' in chest reward"
	if not puzzle._chest_opened:
		return "Expected _chest_opened to be true"

	puzzle.free()
	return ""

func test_circular_minimap_shrine_and_torch_tracking() -> String:
	var hud = CircularMinimapHUDScript.new()
	if hud == null:
		return "Failed to instantiate CircularMinimapHUD"

	var found_shrine: bool = false
	var found_torch: bool = false
	for lm in hud.landmarks:
		if lm.get("id", "") == "shrine_depths":
			found_shrine = true
			if lm.get("name", "") != "Đền Ngàn Đời":
				return "Unexpected shrine landmark name: %s" % lm.get("name", "")
		elif lm.get("id", "") == "torch_puzzle":
			found_torch = true
			if lm.get("name", "") != "Đài Hỏa Viêm":
				return "Unexpected torch puzzle landmark name: %s" % lm.get("name", "")

	if not found_shrine:
		return "Minimap missing landmark 'shrine_depths'"
	if not found_torch:
		return "Minimap missing landmark 'torch_puzzle'"

	hud.free()
	return ""
