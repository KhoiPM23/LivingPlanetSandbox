class_name TestBlock54AerialWindRingsAndLivingEcology
extends RefCounted

## Living Planet Sandbox — Block 54 Automated Regression Test Suite
## Validates Anemo Aerial Flight Rings Highway, Luminescent Night Flora (Star Lotus & Spore Mushrooms),
## Lake Emerald Tree Frog & Lily Pad Perch, and Circular Minimap Radar Integration.

const AnemoFlightRingsScript = preload("res://presentation/environment/anemo_flight_rings.gd")
const LuminescentNightFloraScript = preload("res://presentation/props/luminescent_night_flora.gd")
const LakeEmeraldFrogScript = preload("res://presentation/props/lake_emerald_frog.gd")
const CircularMinimapHUDScript = preload("res://presentation/ui/circular_minimap_hud.gd")

func test_anemo_flight_rings_highway_and_boost_physics() -> String:
	var rings = AnemoFlightRingsScript.new()
	if rings == null:
		return "Failed to instantiate AnemoFlightRings"

	if rings.get_ring_count() != 6:
		return "Expected 6 anemo flight rings, got %d" % rings.get_ring_count()

	var poses = rings.get_ring_positions()
	if poses.size() != 6:
		return "Expected 6 ring positions, got %d" % poses.size()

	# Check procedural whoosh WAV audio
	if rings._audio_player == null:
		return "AnemoFlightRings missing _audio_player"
	if rings._whoosh_wav == null or rings._whoosh_wav.data.is_empty():
		return "AnemoFlightRings procedural whoosh WAV audio data is empty"

	# Test mock walker passing through ring 0
	var mock_walker = CharacterBody3D.new()
	var ring0_pos = poses[0]
	mock_walker.position = ring0_pos

	var signal_passed: Array = [-1, 0]
	rings.ring_passed.connect(func(idx: int, count: int):
		signal_passed[0] = idx
		signal_passed[1] = count
	)

	var boost_res = rings.update_flight_physics(0.016, mock_walker)
	if not boost_res.get("boost", false):
		return "Expected boost == true when walker is within flight ring radius"
	if signal_passed[0] != 0:
		return "Expected ring_passed signal for index 0, got %d" % signal_passed[0]
	if boost_res.get("boost_speed", 0.0) < 16.0:
		return "Expected boost speed >= 16.0 m/s, got %f" % boost_res.get("boost_speed", 0.0)
	if boost_res.get("lift_impulse", 0.0) < 3.0:
		return "Expected lift impulse >= 3.0 m/s, got %f" % boost_res.get("lift_impulse", 0.0)

	# Verify cooldown prevents immediate re-triggering
	var repeat_res = rings.update_flight_physics(0.016, mock_walker)
	if repeat_res.get("boost", false):
		return "Ring should not re-trigger while cooldown is active"

	rings.free()
	mock_walker.free()
	return ""

func test_luminescent_night_flora_star_lotus_and_spore_mushrooms() -> String:
	var flora = LuminescentNightFloraScript.new()
	if flora == null:
		return "Failed to instantiate LuminescentNightFlora"

	flora.setup(null)

	if flora._lotuses.size() < 4:
		return "Expected at least 4 Star Lotus flowers on Grand Lake, got %d" % flora._lotuses.size()
	if flora._mushrooms.size() < 6:
		return "Expected at least 6 Luminous Spore Mushrooms, got %d" % flora._mushrooms.size()

	var initial_unharvested = flora.get_unharvested_count()
	if initial_unharvested != flora._lotuses.size() + flora._mushrooms.size():
		return "Initial unharvested count mismatch"

	# Test day/night flora breathing update
	flora.update_flora(0.1, false, Vector3.ZERO) # Day
	flora.update_flora(0.1, true, Vector3.ZERO)  # Night

	# Test harvesting Star Lotus
	var lotus0 = flora._lotuses[0]
	var near_lotus = flora.get_nearby_forageable(lotus0["pos"], 2.0)
	if near_lotus.is_empty():
		return "Failed to detect nearby Star Lotus at %s" % str(lotus0["pos"])
	if near_lotus.get("item_id", "") != "star_lotus":
		return "Expected item_id 'star_lotus', got '%s'" % near_lotus.get("item_id", "")

	var harvested_signal: Array = ["", ""]
	flora.flora_harvested.connect(func(ftype: String, item: String, _p: Vector3):
		harvested_signal[0] = ftype
		harvested_signal[1] = item
	)

	var loot = flora.harvest_flora(near_lotus["id"])
	if loot.is_empty() or loot.get("item_id", "") != "star_lotus":
		return "Failed to harvest Star Lotus or invalid loot returned"
	if harvested_signal[1] != "star_lotus":
		return "flora_harvested signal was not received for star_lotus"

	# Test spore mushroom proximity spore trigger
	var mush0 = flora._mushrooms[0]
	var mush_pos = mush0["pos"]
	flora.update_flora(0.1, false, mush_pos) # Player directly on mushroom
	if mush0["spore_cooldown"] <= 0.0:
		return "Spore mushroom should have activated spore burst cooldown on proximity"

	# Harvest mushroom
	var near_mush = flora.get_nearby_forageable(mush_pos, 2.0)
	if near_mush.is_empty():
		return "Failed to detect nearby Spore Mushroom at %s" % str(mush_pos)
	var m_loot = flora.harvest_flora(near_mush["id"])
	if m_loot.get("item_id", "") != "glowing_spore":
		return "Expected glowing_spore from mushroom harvest, got '%s'" % m_loot.get("item_id", "")

	flora.free()
	return ""

func test_lake_emerald_frog_perch_fsm_and_dive() -> String:
	var frog = LakeEmeraldFrogScript.new()
	if frog == null:
		return "Failed to instantiate LakeEmeraldFrog"

	if frog._body_mesh == null:
		return "LakeEmeraldFrog missing _body_mesh"
	if frog._throat_sac == null:
		return "LakeEmeraldFrog missing _throat_sac"
	if frog._audio_player == null:
		return "LakeEmeraldFrog missing _audio_player"
	if frog._croak_wav == null or frog._croak_wav.data.is_empty():
		return "LakeEmeraldFrog procedural croak WAV audio stream is empty"

	frog.position = Vector3(45.0, 0.05, 82.0)
	frog.lily_pad_pos = frog.position

	# Test 1: Basking state (player far away)
	frog.update_behavior(0.1, Vector3(0.0, 0.0, 0.0))
	if frog.current_state != LakeEmeraldFrogScript.FrogState.BASKING:
		return "Frog should remain in BASKING state when player is far away"

	# Test 2: Alert state (player within 6m)
	frog.update_behavior(0.1, Vector3(48.0, 0.05, 82.0))
	if frog.current_state != LakeEmeraldFrogScript.FrogState.ALERT:
		return "Frog should transition to ALERT state when player is within 6m"

	# Test 3: Flee dive trigger (player within 2.8m)
	var dived_signal: Array = [false]
	frog.frog_dived.connect(func(_pos: Vector3): dived_signal[0] = true)

	frog.update_behavior(0.1, Vector3(46.0, 0.05, 82.0))
	if frog.current_state != LakeEmeraldFrogScript.FrogState.DIVING:
		return "Frog should transition to DIVING state when player is within 2.8m"

	# Tick dive animation to completion (0.75s)
	frog.update_behavior(0.8, Vector3(46.0, 0.05, 82.0))
	if frog.current_state != LakeEmeraldFrogScript.FrogState.UNDERWATER:
		return "Frog should transition to UNDERWATER state after dive finishes"
	if not dived_signal[0]:
		return "frog_dived signal was not emitted upon entering water"

	frog.free()
	return ""

func test_circular_minimap_flight_rings_and_flora_tracking() -> String:
	var hud = CircularMinimapHUDScript.new()
	if hud == null:
		return "Failed to instantiate CircularMinimapHUD"

	var dummy_p = Node3D.new()
	dummy_p.position = Vector3(95.0, 3.5, 85.0)

	var dummy_cam = Camera3D.new()

	var rings = AnemoFlightRingsScript.new()
	var flora = LuminescentNightFloraScript.new()
	flora.setup(null)

	hud.setup(dummy_p, dummy_cam, null, null, rings, flora)
	hud._process(0.016)

	if hud.flight_rings_ref != rings:
		return "Minimap flight_rings_ref not bound"
	if hud.flora_ref != flora:
		return "Minimap flora_ref not bound"

	# Verify radar coordinates calculation for ring 0 and flora 0
	var ring0: Vector3 = rings.get_ring_positions()[0]
	var r_data = hud._world_to_radar(ring0.x, ring0.z, Vector2(80, 80), CircularMinimapHUDScript.MINIMAP_RADIUS)
	if not r_data.has("pos") or not r_data.has("clamped"):
		return "Failed to project flight ring to radar coordinates"

	var lotus0: Vector3 = flora._lotuses[0]["pos"]
	var l_data = hud._world_to_radar(lotus0.x, lotus0.z, Vector2(80, 80), CircularMinimapHUDScript.MINIMAP_RADIUS)
	if not l_data.has("pos") or not l_data.has("clamped"):
		return "Failed to project star lotus to radar coordinates"

	hud.free()
	dummy_p.free()
	dummy_cam.free()
	rings.free()
	flora.free()
	return ""
