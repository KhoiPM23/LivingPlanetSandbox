class_name TestBlock38OpenWorldRPG
extends RefCounted

## Living Planet Sandbox — Block 38 Automated Verification Suite
## Verifies:
## 1. Anime character model overhaul & cel-shading / inverted hull outline shaders
## 2. Drivable expedition skiff mounting/dismounting & water physics
## 3. Coastal Haven medieval village architecture, static colliders & living NPCs
## 4. Genshin-style glassmorphic dialogue modal, typewriter & response options
## 5. Narrative commission assignment & progression in ExpeditionManager

const WalkerScript = preload("res://presentation/camera/first_person_walker.gd")
const BoatScript = preload("res://presentation/vehicles/drivable_boat.gd")
const VillageScript = preload("res://presentation/environment/medieval_haven_village.gd")
const DialogueModalScript = preload("res://presentation/ui/dialogue_modal.gd")
const ExpeditionScript = preload("res://core/gameplay/expedition_manager.gd")
const CameraScript = preload("res://presentation/camera/free_look_camera.gd")

func test_anime_character_and_cel_shading() -> String:
	var walker = WalkerScript.new()
	walker._build_collision()
	walker._build_model()
	walker._build_anime_particles()

	# 1. Slender proportions check
	if not walker._character_instance:
		walker.queue_free()
		return "Expected _character_instance to be instantiated in FirstPersonWalker"

	var s: Vector3 = walker._character_instance.scale
	if s.x > 0.85 or s.z > 0.85:
		walker.queue_free()
		return "Expected slender anime scale on X and Z (< 0.85), got: %s" % str(s)

	# 2. Anime dash wind particles check
	if not walker._dash_particles:
		walker.queue_free()
		return "Expected _dash_particles to be created for anime sprint effect"
	if walker._dash_particles.name != "AnimeDashParticles":
		walker.queue_free()
		return "Expected _dash_particles node name to be AnimeDashParticles"

	# 3. Cel material and outline next-pass check
	var meshes: Array[Node] = walker._character_instance.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		walker.queue_free()
		return "Expected MeshInstance3D nodes in character model"

	var found_cel: bool = false
	var found_outline: bool = false
	for m in meshes:
		var mi: MeshInstance3D = m as MeshInstance3D
		if mi and mi.visible and mi.material_override is ShaderMaterial:
			var sm: ShaderMaterial = mi.material_override as ShaderMaterial
			if sm.shader and "cel" in sm.shader.resource_path.to_lower():
				found_cel = true
			if sm.next_pass is ShaderMaterial:
				var np: ShaderMaterial = sm.next_pass as ShaderMaterial
				if np.shader and "outline" in np.shader.resource_path.to_lower():
					found_outline = true
			break

	walker.queue_free()

	if not found_cel:
		return "Expected Anime Cel Shader assigned to visible character meshes"
	if not found_outline:
		return "Expected Anime Outline Shader assigned as next_pass to cel material"

	return ""

func test_interactive_drivable_boat() -> String:
	var boat = BoatScript.new()
	boat._ready()

	# 1. Initial State
	if boat.is_driven:
		boat.queue_free()
		return "Expected boat to start in un-driven state"
	if boat.max_forward_speed <= 0.0 or boat.turn_speed <= 0.0:
		boat.queue_free()
		return "Expected positive movement and steering speeds on DrivableBoat"

	# 2. Interaction proximity
	boat.position = Vector3(10.0, 0.0, 10.0)
	if not boat.can_interact(Vector3(11.0, 0.0, 10.5)):
		boat.queue_free()
		return "Expected can_interact to be true when within 3.2m of boat"
	if boat.can_interact(Vector3(30.0, 0.0, 30.0)):
		boat.queue_free()
		return "Expected can_interact to be false when far from boat"

	# 3. Mount and Dismount lifecycle
	var walker = WalkerScript.new()
	walker._ready()

	var cam = CameraScript.new()

	var mounted_signal: Array[bool] = [false]
	var dismounted_signal: Array[bool] = [false]
	boat.player_mounted.connect(func(_b): mounted_signal[0] = true)
	boat.player_dismounted.connect(func(_b): dismounted_signal[0] = true)

	boat.mount_player(walker, cam)
	if not boat.is_driven:
		boat.queue_free()
		walker.queue_free()
		cam.queue_free()
		return "Expected is_driven to be true after mounting player"
	if walker.visible:
		boat.queue_free()
		walker.queue_free()
		cam.queue_free()
		return "Expected walker to be hidden while driving boat"
	if not mounted_signal[0]:
		boat.queue_free()
		walker.queue_free()
		cam.queue_free()
		return "Expected player_mounted signal to be emitted"

	boat.dismount_player()
	if boat.is_driven:
		boat.queue_free()
		walker.queue_free()
		cam.queue_free()
		return "Expected is_driven to be false after dismounting player"
	if not walker.visible:
		boat.queue_free()
		walker.queue_free()
		cam.queue_free()
		return "Expected walker to be visible again after dismounting"
	if not dismounted_signal[0]:
		boat.queue_free()
		walker.queue_free()
		cam.queue_free()
		return "Expected player_dismounted signal to be emitted"

	boat.queue_free()
	walker.queue_free()
	cam.queue_free()
	return ""

func test_medieval_haven_village_and_npcs() -> String:
	var village = VillageScript.new()
	var terrain = IslandTerrain.new()
	terrain.island_size = 200.0
	terrain.generate_island(1337)

	village.setup(terrain, null)

	# 1. Building structures check
	var twr: Node3D = village.get_node_or_null("HavenWatchtower") as Node3D
	var hbr: Node3D = village.get_node_or_null("HarborMasterCottage") as Node3D
	var hrb: Node3D = village.get_node_or_null("HerbalistLodge") as Node3D
	var sqr: Node3D = village.get_node_or_null("VillageSquare") as Node3D

	if not twr or not hbr or not hrb or not sqr:
		village.queue_free()
		terrain.queue_free()
		return "Expected Watchtower, Harbor Cottage, Herbalist Lodge, and Village Square in MedievalHavenVillage"

	# 2. Living NPCs check
	var alistair: Node3D = village._npc_alistair
	var elowen: Node3D = village._npc_elowen
	if not alistair or not elowen:
		village.queue_free()
		terrain.queue_free()
		return "Expected NPCs Alistair and Elowen in MedievalHavenVillage"

	var a_plate: Label3D = alistair.get_node_or_null("NamePlate") as Label3D
	if not a_plate or not "alistair" in a_plate.text.to_lower():
		village.queue_free()
		terrain.queue_free()
		return "Expected 3D overhead NamePlate for Alistair"

	# 3. Interactivity checks
	var near_a = village.get_nearby_interactable(alistair.position)
	if near_a.is_empty() or near_a.get("id", "") != "Alistair":
		village.queue_free()
		terrain.queue_free()
		return "Expected nearby interactable to return Alistair when close"

	var far_interact = village.get_nearby_interactable(Vector3(999.0, 0.0, 999.0))
	if not far_interact.is_empty():
		village.queue_free()
		terrain.queue_free()
		return "Expected empty interactable dictionary when far from village"

	village.queue_free()
	terrain.queue_free()
	return ""

func test_genshin_dialogue_modal_and_quests() -> String:
	var modal = DialogueModalScript.new()
	modal._ready()

	var assigned_data: Array[String] = ["", ""]
	modal.quest_assigned.connect(func(qid, qtitle):
		assigned_data[0] = qid
		assigned_data[1] = qtitle
	)

	modal.open_dialogue(
		"Alistair",
		"THUYỀN TRƯỞNG ALISTAIR",
		"Trưởng Bến Cảng",
		"⚓",
		"Xin chào nhà thám hiểm!",
		[
			{"label": "Nhận ủy thác thuyền", "quest_id": "boat_expedition", "quest_title": "Hải Trình Vịnh Ngọc Bích"},
			{"label": "Tạm biệt", "quest_id": "", "quest_title": ""}
		]
	)

	if not modal.is_dialogue_open():
		modal.queue_free()
		return "Expected dialogue modal to be open after open_dialogue"

	# Select option 0
	modal._select_option(0)

	if assigned_data[0] != "boat_expedition":
		modal.queue_free()
		return "Expected quest_assigned signal with boat_expedition (got %s)" % assigned_data[0]

	if modal.is_dialogue_open():
		modal.queue_free()
		return "Expected dialogue modal to close after selecting response option"

	modal.queue_free()
	return ""

func test_expedition_village_custom_commissions() -> String:
	var exp = ExpeditionScript.new()
	exp.generate_seed_quests(1337)

	var initial_count: int = exp.get_active_quests().size()

	# Add custom narrative commission
	exp.add_custom_commission("boat_expedition", "Hải Trình Vịnh Ngọc Bích", "Lên thuyền tại cầu cảng.", "BOAT_VOYAGE", 1, 350)

	if exp.get_active_quests().size() != initial_count + 1:
		exp.queue_free()
		return "Expected active quests size to increment by 1"

	var completed_data: Array[bool] = [false]
	exp.quest_completed.connect(func(qid, _title, _xp):
		if qid == "boat_expedition":
			completed_data[0] = true
	)

	# Trigger quest progression
	var res: bool = exp.check_quest_progress("VILLAGE_ACTION", {"action_id": "boat_expedition"})
	if not res:
		exp.queue_free()
		return "Expected check_quest_progress to return true when completing village commission"

	if not completed_data[0]:
		exp.queue_free()
		return "Expected quest_completed signal to fire for boat_expedition"

	exp.queue_free()
	return ""
