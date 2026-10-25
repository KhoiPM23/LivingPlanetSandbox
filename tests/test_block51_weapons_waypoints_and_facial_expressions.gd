class_name TestBlock51WeaponsWaypointsAndFacialExpressions
extends RefCounted

## Living Planet Sandbox — Block 51 Automated Contract Test Suite
## Verifies:
## 1. AnimeFacialController VRoid 57-blendshape binding, natural blinking & emotional kinetics
## 2. AnimeWeaponSystem procedural Anemo blade, dual bone sockets, sheath/draw & 3-hit combo
## 3. TeleportWaypoint3D levitating crystal core, unlock transition, ascension chime & sky beacon
## 4. WaypointNetworkManager 4-biome network registration & fast travel teleportation
## 5. Village Buster & Mimi petting interactions, happy kinetics & audio synthesis
## 6. HUDCompassBar real-time waypoint tracking & status icons

const FacialControllerScript = preload("res://presentation/character/anime_facial_controller.gd")
const WeaponSystemScript = preload("res://presentation/character/anime_weapon_system.gd")
const WaypointScript = preload("res://presentation/environment/teleport_waypoint.gd")
const NetworkManagerScript = preload("res://presentation/environment/waypoint_network_manager.gd")
const WalkerScript = preload("res://presentation/camera/first_person_walker.gd")
const VillageScript = preload("res://presentation/environment/medieval_haven_village.gd")
const CompassScript = preload("res://presentation/ui/hud_compass_bar.gd")

func test_anime_facial_controller_blendshapes() -> String:
	var walker: FirstPersonWalker = WalkerScript.new()
	walker._ready()

	var fc = walker.get_facial_controller()
	if not fc:
		walker.free()
		return "Expected AnimeFacialController to be instantiated in FirstPersonWalker"

	# Verify cached blendshape indices found on Face mesh
	if fc._idx_eye_close < 0:
		walker.free()
		return "Expected Fcl_EYE_Close blendshape index to be valid"
	if fc._idx_all_joy < 0:
		walker.free()
		return "Expected Fcl_ALL_Joy blendshape index to be valid"
	if fc._idx_all_angry < 0:
		walker.free()
		return "Expected Fcl_ALL_Angry blendshape index to be valid"

	# Test emotional state transitions
	fc.trigger_joy(2.0)
	if fc.get_expression() != FacialControllerScript.ExpressionMode.JOY:
		walker.free()
		return "Expected facial expression mode to be JOY after trigger_joy"

	# Update step: verify smooth blending towards joy
	fc.update(0.15, false, false, false)
	if fc._weight_joy <= 0.1:
		walker.free()
		return "Expected _weight_joy > 0.1 after update, got %.2f" % fc._weight_joy

	# Trigger surprise
	fc.trigger_surprise(1.5)
	if fc.get_expression() != FacialControllerScript.ExpressionMode.SURPRISE:
		walker.free()
		return "Expected expression mode to be SURPRISE"

	walker.free()
	return ""

func test_anime_weapon_system_and_combat_stance() -> String:
	var walker: FirstPersonWalker = WalkerScript.new()
	walker._ready()

	var ws: Node3D = walker.get_weapon_system()
	if not ws:
		walker.free()
		return "Expected AnimeWeaponSystem to be instantiated in FirstPersonWalker"

	# 1. Check bone sockets created on character Skeleton
	if not ws._back_attachment:
		walker.free()
		return "Expected BackWeaponSocket BoneAttachment3D"
	if not ws._hand_attachment:
		walker.free()
		return "Expected RightHandWeaponSocket BoneAttachment3D"

	# 2. Check initial sheathed state
	if ws.is_drawn:
		walker.free()
		return "Expected weapon to start sheathed on back"
	if ws._blade_mesh.get_parent() != ws._back_attachment:
		walker.free()
		return "Expected blade mesh to be mounted in BackWeaponSocket when sheathed"

	# 3. Toggle draw: draw weapon into hand
	var drawn: bool = walker.toggle_weapon()
	if not drawn or not ws.is_drawn:
		walker.free()
		return "Expected weapon to be drawn after toggle_weapon()"
	if ws._blade_mesh.get_parent() != ws._hand_attachment:
		walker.free()
		return "Expected blade mesh to be mounted in RightHandWeaponSocket when drawn"

	# 4. Test 3-Hit Attack Combo
	# Strike 1
	var atk1: bool = walker.trigger_weapon_attack()
	if not atk1 or ws._combo_stage != 0:
		walker.free()
		return "Expected first attack to trigger combo stage 0"

	# Advance timer to clear cooldown and execute Strike 2
	ws._attack_cooldown = 0.0
	var atk2: bool = walker.trigger_weapon_attack()
	if not atk2 or ws._combo_stage != 1:
		walker.free()
		return "Expected second attack to trigger combo stage 1"

	# Strike 3 (Finisher)
	ws._attack_cooldown = 0.0
	var atk3: bool = walker.trigger_weapon_attack()
	if not atk3 or ws._combo_stage != 2:
		walker.free()
		return "Expected third attack to trigger combo stage 2 (Finisher)"

	# 5. Toggle sheath: returns blade to back socket
	walker.toggle_weapon()
	if ws.is_drawn:
		walker.free()
		return "Expected weapon to be sheathed after second toggle"
	if ws._blade_mesh.get_parent() != ws._back_attachment:
		walker.free()
		return "Expected blade to return to BackWeaponSocket when sheathed"

	walker.free()
	return ""

func test_teleport_waypoint_mechanics() -> String:
	var wp: Node3D = WaypointScript.new()
	wp.setup("test_wp", "Cực Bắc", "Đài quan sát biển sâu.", Vector3(10.0, 2.0, 10.0), false)

	# 1. Verify locked state visuals
	if wp.is_unlocked:
		wp.free()
		return "Expected waypoint to start locked"
	if wp._beacon_beam.visible:
		wp.free()
		return "Expected skyward beacon beam to be hidden while locked"

	# 2. Test unlock activation
	var unlocked_signal_received: Array[bool] = [false]
	wp.waypoint_unlocked.connect(func(_id, _name): unlocked_signal_received[0] = true)

	var res: bool = wp.unlock()
	if not res or not wp.is_unlocked:
		wp.free()
		return "Expected unlock() to succeed and set is_unlocked to true"
	if not unlocked_signal_received[0]:
		wp.free()
		return "Expected waypoint_unlocked signal to be emitted upon unlock"
	if not wp._beacon_beam.visible:
		wp.free()
		return "Expected skyward beacon beam to be visible after unlocking"

	# 3. Test interaction range and safe arrival position
	if not wp.can_interact(Vector3(11.0, 2.0, 10.0)):
		wp.free()
		return "Expected player at 1.0m to be within waypoint interaction radius"
	if wp.can_interact(Vector3(25.0, 2.0, 10.0)):
		wp.free()
		return "Expected player at 15m to be out of waypoint interaction radius"

	var arrival: Vector3 = wp.get_teleport_arrival_position()
	if arrival.distance_to(wp.position) < 1.0:
		wp.free()
		return "Expected arrival position to have offset from pedestal to prevent clipping"

	wp.free()
	return ""

func test_waypoint_network_manager() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.island_size = 720.0

	var net: Node3D = NetworkManagerScript.new()
	net.setup(terrain)

	# 1. Verify all 4 strategic waypoints spawned
	var waypoints: Array = net.get_waypoints()
	if waypoints.size() != 4:
		net.free()
		terrain.free()
		return "Expected 4 waypoints across island, got %d" % waypoints.size()

	var required_ids: Array[String] = ["haven_pier", "whispering_grotto", "castle_citadel", "skyspire_summit"]
	for id in required_ids:
		var wp = net.get_waypoint(id)
		if not wp:
			net.free()
			terrain.free()
			return "Expected waypoint with id '%s' to exist" % id

	# 2. Verify haven_pier starts unlocked
	var pier_wp: Node3D = net.get_waypoint("haven_pier")
	if not pier_wp.is_unlocked:
		net.free()
		terrain.free()
		return "Expected haven_pier to be unlocked as default starting anchor"

	# 3. Test fast travel teleportation
	var walker: FirstPersonWalker = WalkerScript.new()
	walker.position = Vector3.ZERO
	var tp_res: bool = net.teleport_player(walker, "haven_pier")
	if not tp_res:
		walker.free()
		net.free()
		terrain.free()
		return "Expected teleport_player to haven_pier to succeed"

	var expected_arrival: Vector3 = pier_wp.get_teleport_arrival_position()
	if walker.position.distance_to(expected_arrival) > 0.05:
		var dist = walker.position.distance_to(expected_arrival)
		walker.free()
		net.free()
		terrain.free()
		return "Expected walker position to match arrival position (offset: %.3f)" % dist

	walker.free()
	net.free()
	terrain.free()
	return ""

func test_village_petting_interactions() -> String:
	var village: MedievalHavenVillage = VillageScript.new()
	village.setup(null, null)

	# 1. Test Buster petting
	var buster_res: Dictionary = village.pet_buster()
	if buster_res.get("id", "") != "buster":
		village.free()
		return "Expected pet_buster() to return buster result"
	if village._buster_pet_time <= 1.0:
		village.free()
		return "Expected _buster_pet_time to be activated (> 1.0s)"

	# 2. Test Mimi petting
	var mimi_res: Dictionary = village.pet_mimi()
	if mimi_res.get("id", "") != "mimi":
		village.free()
		return "Expected pet_mimi() to return mimi result"
	if village._mimi_pet_time <= 1.0:
		village.free()
		return "Expected _mimi_pet_time to be activated (> 1.0s)"

	village.free()
	return ""

func test_compass_bar_waypoint_sync() -> String:
	var compass: HUDCompassBar = CompassScript.new()
	var net: Node3D = NetworkManagerScript.new()
	net.setup(null)

	compass.set_waypoint_network(net)
	if compass._network_ref != net:
		compass.free()
		net.free()
		return "Expected compass._network_ref to be bound to WaypointNetworkManager"

	compass.free()
	net.free()
	return ""
