class_name TestBlock55CrystalflySeelieAndWildernessCamp
extends RefCounted

## Living Planet Sandbox — Block 55 Automated Regression Test Suite
## Validates Anemo Crystalfly Swarm, Wandering Seelie & Court, Wilderness Campfire Bivouac,
## Ancient Anemo Statue with Gliding Time Trial, and Ground Dressing.

const AnemoCrystalflySwarmScript = preload("res://presentation/environment/anemo_crystalfly_swarm.gd")
const WanderingSeelieScript = preload("res://presentation/environment/wandering_seelie.gd")
const WildernessCampfireSanctuaryScript = preload("res://presentation/environment/wilderness_campfire_sanctuary.gd")
const AncientAnemoStatueScript = preload("res://presentation/environment/ancient_anemo_statue.gd")
const WildernessGroundDressingScript = preload("res://presentation/props/wilderness_ground_dressing.gd")

func test_anemo_crystalfly_swarm_flight_and_capture() -> String:
	var swarm = AnemoCrystalflySwarmScript.new()
	if swarm == null:
		return "Failed to instantiate AnemoCrystalflySwarm"

	if swarm._flies.size() != 7:
		return "Expected 7 crystalflies spawned, got %d" % swarm._flies.size()

	# Check procedural chime WAV
	if swarm._audio_player == null:
		return "AnemoCrystalflySwarm missing _audio_player"
	if swarm._chime_wav == null or swarm._chime_wav.data.is_empty():
		return "AnemoCrystalflySwarm procedural chime WAV audio stream is empty"

	# Test flight behavior tick
	var fly0 = swarm._flies[0]
	var init_pos: Vector3 = fly0["curr_pos"]
	swarm.update_behavior(0.1, Vector3.ZERO, 0.0)
	if fly0["curr_pos"] == init_pos:
		return "Crystalfly position did not update during hovering behavior"

	# Test proximity detection & capture
	var near_fly = swarm.get_nearby_crystalfly(fly0["curr_pos"], 2.0)
	if near_fly.is_empty():
		return "Failed to detect nearby Crystalfly at %s" % str(fly0["curr_pos"])

	var caught_signal: Array = ["", ""]
	swarm.crystalfly_caught.connect(func(fid: String, item: String, _p: Vector3):
		caught_signal[0] = fid
		caught_signal[1] = item
	)

	var loot = swarm.catch_crystalfly(near_fly["id"])
	if loot.is_empty() or loot.get("item_id", "") != "crystal_core":
		return "Failed to catch Crystalfly or invalid loot returned"
	if caught_signal[1] != "crystal_core":
		return "crystalfly_caught signal was not received"
	if swarm.get_active_count() != 6:
		return "Expected 6 active crystalflies remaining, got %d" % swarm.get_active_count()

	# Test panic scatter on sprinting player
	var fly1 = swarm._flies[1]
	swarm.update_behavior(0.1, fly1["curr_pos"], 6.0) # Sprinted right next to fly1
	if not fly1["scattering"]:
		return "Crystalfly should have entered scattering state when player sprints nearby"

	swarm.free()
	return ""

func test_wandering_seelie_path_guiding_and_court() -> String:
	var seelie = WanderingSeelieScript.new()
	if seelie == null:
		return "Failed to instantiate WanderingSeelie"

	if seelie._path.size() != 6:
		return "Expected 6 waypoints along Seelie path, got %d" % seelie._path.size()
	if seelie._court_root == null:
		return "WanderingSeelie missing Seelie Court root"
	if seelie._court_chest == null:
		return "WanderingSeelie missing court chest"

	# Test initial state
	if seelie.current_state != WanderingSeelieScript.SeelieState.WAITING_FOR_PLAYER:
		return "Seelie initial state should be WAITING_FOR_PLAYER"

	# Player approaches WP0
	seelie.update_behavior(0.1, seelie._path[0])
	if seelie.current_state != WanderingSeelieScript.SeelieState.ADVANCING:
		return "Seelie should transition to ADVANCING when player approaches"

	# Fast-forward Seelie through all waypoints to court
	for i in range(seelie._path.size()):
		seelie._current_wp_idx = i
		seelie._seelie_orb.position = seelie._path[i]

	var reached_signal: Array = [false]
	seelie.seelie_reached_court.connect(func(_pos): reached_signal[0] = true)

	seelie.update_behavior(0.1, seelie._path[seelie._path.size() - 1])
	if seelie.current_state != WanderingSeelieScript.SeelieState.REACHED_COURT:
		return "Seelie should transition to REACHED_COURT upon arriving at final waypoint"
	if not reached_signal[0]:
		return "seelie_reached_court signal was not emitted"
	if not seelie._court_chest.visible:
		return "Seelie Court chest should become visible upon arrival"

	# Test opening chest
	var opened_signal: Array = [{}]
	seelie.seelie_chest_opened.connect(func(rew): opened_signal[0] = rew)

	var reward = seelie.open_seelie_chest()
	if reward.is_empty() or reward.get("coins", 0) != 65:
		return "Failed to open Seelie chest or coins mismatch"
	if opened_signal[0].is_empty():
		return "seelie_chest_opened signal was not emitted"

	seelie.free()
	return ""

func test_wilderness_campfire_sanctuary_and_cooking() -> String:
	var camp = WildernessCampfireSanctuaryScript.new()
	if camp == null:
		return "Failed to instantiate WildernessCampfireSanctuary"

	if camp._fire_light == null:
		return "Campfire missing _fire_light"
	if camp._smoke_particles == null:
		return "Campfire missing _smoke_particles"
	if camp._audio_player == null:
		return "Campfire missing _audio_player"
	if camp._campfire_wav == null or camp._campfire_wav.data.is_empty():
		return "Campfire procedural crackle WAV audio stream is empty"

	# Test thermal flicker tick
	var init_energy: float = camp._fire_light.light_energy
	camp._process(0.1)
	if camp._fire_light.light_energy == init_energy:
		return "Campfire thermal light flicker did not modulate energy"

	# Test resting at campfire
	var rested_signal: Array = [false]
	camp.camp_rested.connect(func(_p): rested_signal[0] = true)

	var rest_res = camp.rest_at_campfire(null)
	if not rested_signal[0]:
		return "camp_rested signal was not emitted"
	if rest_res.get("buff", "") != "camp_warmth":
		return "Expected camp_warmth buff from resting"

	# Test cooking stew
	var cooked_signal: Array = ["", 0]
	camp.meal_cooked.connect(func(mid: String, exp: int):
		cooked_signal[0] = mid
		cooked_signal[1] = exp
	)

	var cook_res = camp.cook_campfire_stew()
	if cook_res.get("meal_id", "") != "hearty_wild_stew":
		return "Expected hearty_wild_stew meal from camp cooking"
	if cooked_signal[0] != "hearty_wild_stew":
		return "meal_cooked signal was not emitted"

	camp.free()
	return ""

func test_ancient_anemo_statue_prayer_and_time_trial() -> String:
	var statue = AncientAnemoStatueScript.new()
	if statue == null:
		return "Failed to instantiate AncientAnemoStatue"

	if statue._orb_root == null:
		return "AncientAnemoStatue missing _orb_root"
	if statue._glyph_ring == null:
		return "AncientAnemoStatue missing _glyph_ring"
	if statue._trial_pedestal == null:
		return "AncientAnemoStatue missing _trial_pedestal"
	if statue._blessing_wav == null or statue._blessing_wav.data.is_empty():
		return "AncientAnemoStatue procedural blessing WAV audio stream is empty"

	# Test prayer interaction
	var prayed_signal: Array = [false]
	statue.statue_prayed.connect(func(_p, _b): prayed_signal[0] = true)

	var blessing = statue.pray_at_statue(null)
	if not prayed_signal[0]:
		return "statue_prayed signal was not emitted"
	if blessing.get("buff", "") != "wind_guardians_blessing":
		return "Expected wind_guardians_blessing from statue prayer"

	# Test time trial activation
	var trial_started: Array = [false]
	statue.time_trial_started.connect(func(_d): trial_started[0] = true)

	var ok = statue.start_time_trial()
	if not ok or not statue.is_time_trial_active:
		return "Failed to activate time trial"
	if not trial_started[0]:
		return "time_trial_started signal was not emitted"

	# Test time trial ring hit progression
	for r in range(6):
		statue.register_ring_hit(r, r + 1)

	if statue.is_time_trial_active:
		return "Time trial should be completed after hitting all 6 rings"

	statue.free()
	return ""

func test_wilderness_ground_dressing_and_bushes() -> String:
	var dressing = WildernessGroundDressingScript.new()
	if dressing == null:
		return "Failed to instantiate WildernessGroundDressing"

	if dressing._bushes.size() != 4:
		return "Expected 4 wild raspberry bushes spawned, got %d" % dressing._bushes.size()

	# Test harvesting wild raspberry bush
	var bush0 = dressing._bushes[0]
	var near_b = dressing.get_nearby_forageable(bush0["pos"], 2.0)
	if near_b.is_empty():
		return "Failed to detect nearby Raspberry Bush at %s" % str(bush0["pos"])

	var foraged_signal: Array = ["", ""]
	dressing.berry_foraged.connect(func(bid: String, item: String, _p: Vector3):
		foraged_signal[0] = bid
		foraged_signal[1] = item
	)

	var res = dressing.harvest_bush(near_b["id"])
	if res.get("item_id", "") != "wild_raspberry":
		return "Expected wild_raspberry item from bush harvest"
	if foraged_signal[1] != "wild_raspberry":
		return "berry_foraged signal was not emitted"
	if dressing.get_unharvested_count() != 3:
		return "Expected 3 unharvested bushes remaining, got %d" % dressing.get_unharvested_count()

	dressing.free()
	return ""
