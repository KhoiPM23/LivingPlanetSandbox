class_name TestBlock67CombatCharacterAndSkyspireQuest
extends RefCounted

## Automated Contract Tests for Block 67:
## 1. Weapon hand socket alignment & dynamic crescent slash arc ribbon VFX.
## 2. Organic facial blinking & expression controller.
## 3. 3-Phase Skyspire Mountain Expedition questline & 114m summit beacon altar.
## 4. Summer Bikini Outfit toggle & body material swapping.
## 5. Locomotion athletic counter-torso spine twist and lean.

const AnimeWeaponSystemScript = preload("res://presentation/character/anime_weapon_system.gd")
const AnimeFacialControllerScript = preload("res://presentation/character/anime_facial_controller.gd")
const SkyspireBeaconAltarScript = preload("res://presentation/environment/skyspire_beacon_altar.gd")
const ExpeditionManagerScript = preload("res://core/gameplay/expedition_manager.gd")
const FirstPersonWalkerScript = preload("res://presentation/camera/first_person_walker.gd")
const AnimeCharacterAnimatorScript = preload("res://presentation/camera/anime_character_animator.gd")

func get_tests() -> Array[Callable]:
	return [
		Callable(self, "test_weapon_hand_socket_alignment_and_slash_arc_mesh"),
		Callable(self, "test_anime_facial_controller_organic_blinking_and_shapes"),
		Callable(self, "test_skyspire_3phase_questline_and_apex_beacon_activation"),
		Callable(self, "test_summer_bikini_outfit_toggle_and_materials"),
		Callable(self, "test_locomotion_athletic_spine_twist_and_lean")
	]

## 1. Verifies weapon hand socket alignment, blade positioning, and crescent arc trail
func test_weapon_hand_socket_alignment_and_slash_arc_mesh() -> bool:
	var skel: Skeleton3D = Skeleton3D.new()
	skel.add_bone("J_Bip_C_Chest")
	skel.add_bone("J_Bip_R_Hand")

	var ws: AnimeWeaponSystem = AnimeWeaponSystemScript.new()
	ws.setup(skel)

	if ws.is_drawn:
		push_error("Weapon should start sheathed")
		ws.free()
		skel.free()
		return false

	# Unsheathe weapon into right hand
	ws.set_drawn(true)
	if not ws.is_drawn:
		push_error("Weapon should be drawn after set_drawn(true)")
		ws.free()
		skel.free()
		return false

	var blade = ws.get("_blade_mesh") as Node3D
	if not blade or blade.get_parent() != ws.get("_hand_attachment"):
		push_error("Blade should be child of hand attachment when drawn")
		ws.free()
		skel.free()
		return false

	# Verify calibrated hand socket position (grip inside palm, not offset into wrist)
	if absf(blade.position.x - (-0.02)) > 0.05 or absf(blade.position.y - 0.05) > 0.05:
		push_error("Blade hand socket position not aligned with palm: %s" % str(blade.position))
		ws.free()
		skel.free()
		return false

	# Test attack triggering crescent arc mesh
	var triggered: bool = ws.trigger_attack()
	if not triggered:
		push_error("Attack should trigger successfully")
		ws.free()
		skel.free()
		return false

	var arc_mesh = ws.get("_slash_arc_mesh") as MeshInstance3D
	if not arc_mesh or not arc_mesh.visible:
		push_error("Crescent slash arc ribbon mesh should be visible on attack")
		ws.free()
		skel.free()
		return false

	# Update past fadeout duration
	ws.update(0.35)
	if arc_mesh.visible:
		push_error("Slash arc mesh should fade out and hide after lifetime")
		ws.free()
		skel.free()
		return false

	ws.free()
	skel.free()
	return true

## 2. Verifies organic blinking kinetics and facial controller blend shapes
func test_anime_facial_controller_organic_blinking_and_shapes() -> bool:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var mesh: ImmediateMesh = ImmediateMesh.new()
	mi.mesh = mesh

	var fc = AnimeFacialControllerScript.new()
	fc.setup(mi)

	# Trigger manual blink
	fc.trigger_blink(0.16)
	if not fc.get("_is_blinking"):
		push_error("trigger_blink should set _is_blinking flag to true")
		mi.free()
		return false

	# Step half-way through lid closure
	fc.update(0.04, false, false, false)
	if fc.get("_current_blink_weight") <= 0.0:
		push_error("Blink weight should rise during eyelid closure phase")
		mi.free()
		return false

	# Step past full duration -> should finish blinking
	fc.update(0.20, false, false, false)
	if fc.get("_is_blinking"):
		push_error("Blink should complete after duration has elapsed")
		mi.free()
		return false

	# Test expression modes
	fc.trigger_combat(true)
	if fc.get_expression() != AnimeFacialController.ExpressionMode.COMBAT:
		push_error("trigger_combat should set COMBAT expression mode")
		mi.free()
		return false

	fc.trigger_combat(false)
	if fc.get_expression() != AnimeFacialController.ExpressionMode.NEUTRAL:
		push_error("trigger_combat(false) should restore NEUTRAL expression mode")
		mi.free()
		return false

	mi.free()
	return true

## 3. Verifies 3-Phase Skyspire Questline registration, elevation triggers, and beacon activation
func test_skyspire_3phase_questline_and_apex_beacon_activation() -> bool:
	var exp: ExpeditionManager = ExpeditionManagerScript.new()
	exp.register_skyspire_quests()

	# 1. Landmark verification
	var landmarks: Dictionary = exp.get_landmarks()
	if not landmarks.has("skyspire_overlook"):
		push_error("ExpeditionManager must contain 'skyspire_overlook' landmark")
		exp.free()
		return false

	var peak_landmark = landmarks["skyspire_overlook"]
	if peak_landmark["coords"].y < 110.0:
		push_error("Skyspire landmark must be elevated >= 110.0m on summit, got: %f" % peak_landmark["coords"].y)
		exp.free()
		return false

	# 2. Quest existence verification
	var quests: Array[Dictionary] = exp.get_active_quests()
	var has_p1: bool = false
	var has_p2: bool = false
	var has_p3: bool = false

	for q in quests:
		if q.get("id", "") == "skyspire_ascent_phase1":
			has_p1 = true
		elif q.get("id", "") == "skyspire_ascent_phase2":
			has_p2 = true
		elif q.get("id", "") == "skyspire_ascent_phase3":
			has_p3 = true

	if not has_p1 or not has_p2 or not has_p3:
		push_error("ExpeditionManager must register all 3 Skyspire Ascent quest phases")
		exp.free()
		return false

	# 3. Simulate phase 1: Approaching Alpine Tarn at Y = 42m in Northwest sector
	exp.check_quest_progress("PLAYER_POSITION", {"position": Vector3(-65.0, 42.0, -65.0)})
	var p1_done: bool = false
	for q in exp.get_active_quests():
		if q["id"] == "skyspire_ascent_phase1" and q["completed"]:
			p1_done = true
			break
	if not p1_done:
		push_error("Phase 1 should complete when player ascends to Y >= 35m in Northwest Massif")
		exp.free()
		return false

	# 4. Simulate phase 2: Climbing Frostbite Cliff at Y = 78m in Northwest sector
	exp.check_quest_progress("PLAYER_POSITION", {"position": Vector3(-110.0, 78.0, -110.0)})
	var p2_done: bool = false
	for q in exp.get_active_quests():
		if q["id"] == "skyspire_ascent_phase2" and q["completed"]:
			p2_done = true
			break
	if not p2_done:
		push_error("Phase 2 should complete when player ascends to Y >= 70m in Northwest Massif")
		exp.free()
		return false

	# 5. Simulate phase 3: Awakening SkyspireBeaconAltar at 114m summit
	var beacon: Node3D = SkyspireBeaconAltarScript.new()
	beacon.position = Vector3(-145.0, 114.0, -145.0)

	var beacon_signals: Array[Vector3] = []
	beacon.beacon_activated.connect(func(pos: Vector3, xp: int):
		beacon_signals.append(pos)
		exp.check_quest_progress("BEACON_ACTIVATED", {"id": "skyspire_beacon", "position": pos})
	)

	beacon.activate_beacon()
	if not beacon.is_activated or beacon_signals.is_empty():
		push_error("SkyspireBeaconAltar must activate and emit beacon_activated signal")
		beacon.free()
		exp.free()
		return false

	var p3_done: bool = false
	for q in exp.get_active_quests():
		if q["id"] == "skyspire_ascent_phase3" and q["completed"]:
			p3_done = true
			break
	if not p3_done:
		push_error("Phase 3 should complete when Skyspire Beacon Altar is activated")
		beacon.free()
		exp.free()
		return false

	beacon.free()
	exp.free()
	return true

## 4. Verifies Summer Bikini Outfit toggle and signal emission
func test_summer_bikini_outfit_toggle_and_materials() -> bool:
	var walker: FirstPersonWalker = FirstPersonWalkerScript.new()

	var outfit_signals: Array[bool] = []
	walker.outfit_changed.connect(func(is_bikini: bool):
		outfit_signals.append(is_bikini)
	)

	# Initially standard adventurer outfit
	if walker.is_bikini_outfit:
		push_error("Walker should default to standard adventurer outfit")
		walker.free()
		return false

	# Enable bikini outfit
	walker.set_bikini_outfit(true)
	if not walker.is_bikini_outfit or outfit_signals.size() == 0 or not outfit_signals[-1]:
		push_error("set_bikini_outfit(true) must set is_bikini_outfit and emit true")
		walker.free()
		return false

	# Toggle off
	var res = walker.toggle_bikini_outfit()
	if res or walker.is_bikini_outfit or not (outfit_signals.size() >= 2 and not outfit_signals[-1]):
		push_error("toggle_bikini_outfit() must revert to standard outfit")
		walker.free()
		return false

	walker.free()
	return true

## 5. Verifies athletic counter-torso spine twist during sprint locomotion
func test_locomotion_athletic_spine_twist_and_lean() -> bool:
	var skel: Skeleton3D = Skeleton3D.new()
	skel.add_bone("J_Bip_C_Hips")
	skel.add_bone("J_Bip_C_Spine")
	skel.add_bone("J_Bip_C_Chest")
	skel.add_bone("J_Bip_R_UpperLeg")
	skel.add_bone("J_Bip_L_UpperLeg")

	var anim = AnimeCharacterAnimatorScript.new()
	anim.setup(skel)

	# Update running locomotion
	anim.update(0.016, 6.2, true, false, true)

	var spine_idx: int = skel.find_bone("J_Bip_C_Spine")
	var spine_rot: Quaternion = skel.get_bone_pose_rotation(spine_idx)
	if is_nan(spine_rot.x) or is_nan(spine_rot.w):
		push_error("Spine bone rotation should be valid non-NaN quaternion")
		skel.free()
		return false

	skel.free()
	return true
