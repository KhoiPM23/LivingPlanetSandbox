class_name EnvironmentalStorytelling
extends Node3D

## Living Planet Sandbox — Block 16 Environmental Storytelling & Wordless World Discovery.
## Principles:
## 1. Wordless Narrative: An abandoned naturalist expedition camp, stag antler rub, cove mooring canoe, and clifftop raptor snag.
## 2. No Marker UI: Discovered purely through natural sightlines, game trails, audio ripples, and animal migration behavior.
## 3. Ecological Connection: Traces correlate with living fauna — deer bedding in the meadow, drinking at the canoe cove, and sheltering near the forest camp.
## 4. Solid Grounding & Collision: Every prop sits embedded in the procedural terrain with static collision.

signal discovery_unlocked(poi_id: String, title: String, body: String)

class POIData extends RefCounted:
	var id: String
	var title: String
	var body: String
	var position: Vector3
	var radius: float
	var discovered: bool

var _terrain: IslandTerrain = null
var _event_bus: WorldEventBus = null
var _camera: Node3D = null
var _hud: CanvasLayer = null

var _pois: Array[Dictionary] = []
var _discovered_count: int = 0
var _check_timer: float = 0.0

# Asset cache
static var _cached_props: Dictionary = {}

static func _init_asset_cache() -> void:
	if not _cached_props.is_empty():
		return

	var n_scn = load("res://presentation/assets/models/nature.glb") as PackedScene
	if n_scn:
		var n_root: Node = n_scn.instantiate()
		var prop_keys: Array[String] = [
			"tent_smallClosed", "campfire_stones", "canoe", "log_stack",
			"stump_round", "stump_square", "log", "log_large",
			"tree_tall_dead", "mushroom_redGroup", "rock_smallC", "rock_largeA",
			"flower_purpleA", "flower_yellowC", "lily_large"
		]
		for pk in prop_keys:
			var mi: MeshInstance3D = n_root.find_child(pk, true, false) as MeshInstance3D
			if mi and mi.mesh:
				var p_mat = mi.mesh.surface_get_material(0) if mi.mesh.get_surface_count() > 0 else null
				if p_mat is StandardMaterial3D:
					var custom_mat: StandardMaterial3D = p_mat.duplicate()
					custom_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
					custom_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
					if pk == "tent_smallClosed":
						# Weathered expedition canvas: olive-khaki field shelter instead of pink
						custom_mat.albedo_color = Color(0.44, 0.46, 0.38)
						custom_mat.roughness = 0.90
					elif pk == "campfire_stones":
						# Charred dark river granite stones
						custom_mat.albedo_color = Color(0.30, 0.29, 0.27)
						custom_mat.roughness = 0.85
					elif pk == "canoe":
						# Rich weathered cedar wood for expedition canoe
						custom_mat.albedo_color = Color(0.46, 0.34, 0.22)
						custom_mat.roughness = 0.78
					elif pk == "stump_round" or pk == "stump_square":
						# Natural cedar wood with growth rings instead of untextured white
						custom_mat.albedo_color = Color(0.44, 0.32, 0.20)
						custom_mat.roughness = 0.88
					p_mat = custom_mat
				_cached_props[pk] = {
					"mesh": mi.mesh,
					"mat": p_mat
				}
		n_root.free()

func setup(terrain: IslandTerrain, event_bus: WorldEventBus = null, camera: Node3D = null, hud: CanvasLayer = null, seed_val: int = 1337) -> void:
	_terrain = terrain
	_event_bus = event_bus
	_camera = camera
	_hud = hud

	_init_asset_cache()
	_build_narrative_pois(seed_val)

func _build_narrative_pois(seed_val: int) -> void:
	# Clear existing
	for c in get_children():
		c.queue_free()
	_pois.clear()
	_discovered_count = 0

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val + 777

	# =========================================================================
	# POI 1: OVERGROWN NATURALIST FIELD CAMP (Whispering Forest edge)
	# =========================================================================
	var camp_x: float = -5.5
	var camp_z: float = 0.5
	var camp_y: float = _terrain.get_height_at(camp_x, camp_z) if _terrain else 3.8
	var camp_pos: Vector3 = Vector3(camp_x, camp_y, camp_z)

	var camp_node: Node3D = Node3D.new()
	camp_node.name = "POI_FieldCamp"
	camp_node.position = camp_pos
	add_child(camp_node)

	# 1. Weathered canvas research tent
	if _cached_props.has("tent_smallClosed"):
		var tent: MeshInstance3D = _create_prop_instance("tent_smallClosed", Vector3(0.0, -0.04, 0.0), Vector3(0.02, 0.32, -0.01), Vector3.ONE * 1.35)
		camp_node.add_child(tent)
		_add_box_collision(camp_node, Vector3(0.0, 0.7, 0.0), Vector3(1.6, 1.4, 2.0))

	# 2. Stone fire pit with cold charcoal
	if _cached_props.has("campfire_stones"):
		var fire: MeshInstance3D = _create_prop_instance("campfire_stones", Vector3(1.6, -0.05, 1.2), Vector3(0.0, rng.randf_range(0.0, TAU), 0.0), Vector3.ONE * 1.15)
		camp_node.add_child(fire)
		_add_cylinder_collision(camp_node, Vector3(1.6, 0.18, 1.2), 0.55, 0.36)

	# 3. Stack of cut firewood
	if _cached_props.has("log_stack"):
		var stack: MeshInstance3D = _create_prop_instance("log_stack", Vector3(-1.4, -0.03, -1.1), Vector3(0.0, -0.45, 0.0), Vector3.ONE * 1.1)
		camp_node.add_child(stack)
		_add_box_collision(camp_node, Vector3(-1.4, 0.35, -1.1), Vector3(1.2, 0.7, 0.8))

	# 4. Field workbench stump
	if _cached_props.has("stump_round"):
		var stump: MeshInstance3D = _create_prop_instance("stump_round", Vector3(1.2, -0.05, -0.6), Vector3(0.0, 0.2, 0.0), Vector3.ONE * 1.2)
		camp_node.add_child(stump)

	# 5. Decaying bench log
	if _cached_props.has("log"):
		var log_bench: MeshInstance3D = _create_prop_instance("log", Vector3(0.2, -0.06, 1.8), Vector3(0.0, 1.35, 0.0), Vector3.ONE * 1.1)
		camp_node.add_child(log_bench)

	_register_poi("field_camp", "⛺ Overgrown Field Camp", "A naturalist's abandoned canvas shelter and stone fire pit, reclaimed by forest moss.", camp_pos, 9.5)

	# =========================================================================
	# POI 2: STAG ANTLER RUB & BEDDING HOLLOW (Sunlit Meadow)
	# =========================================================================
	var rub_x: float = 8.5
	var rub_z: float = 2.5
	var rub_y: float = _terrain.get_height_at(rub_x, rub_z) if _terrain else 3.1
	var rub_pos: Vector3 = Vector3(rub_x, rub_y, rub_z)

	var rub_node: Node3D = Node3D.new()
	rub_node.name = "POI_AntlerRub"
	rub_node.position = rub_pos
	add_child(rub_node)

	# 1. Fallen weathered cedar trunk worn smooth by velvet rubbing
	if _cached_props.has("log_large"):
		var cedar_trunk: MeshInstance3D = _create_prop_instance("log_large", Vector3(0.0, -0.08, 0.0), Vector3(0.04, 0.85, -0.02), Vector3.ONE * 1.25)
		rub_node.add_child(cedar_trunk)
		_add_cylinder_collision(rub_node, Vector3(0.0, 0.25, 0.0), 0.38, 2.8)

	# 2. Bedding hollow surrounded by meadow boundary river stones
	if _cached_props.has("rock_smallC"):
		rub_node.add_child(_create_prop_instance("rock_smallC", Vector3(-1.2, -0.06, 0.9), Vector3(0.0, 1.2, 0.0), Vector3.ONE * 1.3))
		rub_node.add_child(_create_prop_instance("rock_smallC", Vector3(1.4, -0.06, -0.8), Vector3(0.0, 2.4, 0.0), Vector3.ONE * 1.1))
		rub_node.add_child(_create_prop_instance("rock_smallC", Vector3(-0.7, -0.05, -1.0), Vector3(0.0, 0.8, 0.0), Vector3.ONE * 0.95))

	_register_poi("antler_rub", "🦌 Stag Antler Rub", "A weathered cedar trunk polished smooth by seasonal velvet rubbing, nestled in trampled bedding grass.", rub_pos, 7.5)

	# =========================================================================
	# POI 3: EMERALD COVE MOORING & CANOE (Lake cove water's edge)
	# =========================================================================
	var cove_x: float = 13.8
	var cove_z: float = 8.8
	var cove_y: float = _terrain.get_height_at(cove_x, cove_z) if _terrain else 0.45
	var cove_pos: Vector3 = Vector3(cove_x, cove_y, cove_z)

	var cove_node: Node3D = Node3D.new()
	cove_node.name = "POI_CoveMooring"
	cove_node.position = cove_pos
	add_child(cove_node)

	# 1. Abandoned expedition canoe resting half in sand, half in water
	if _cached_props.has("canoe"):
		var canoe: MeshInstance3D = _create_prop_instance("canoe", Vector3(0.0, -0.08, 0.0), Vector3(0.08, -0.62, 0.02), Vector3.ONE * 1.2)
		cove_node.add_child(canoe)
		_add_box_collision(cove_node, Vector3(0.0, 0.22, 0.0), Vector3(0.9, 0.45, 2.6))

	# 2. Weathered timber mooring post
	if _cached_props.has("stump_square"):
		var post: MeshInstance3D = _create_prop_instance("stump_square", Vector3(-1.1, -0.05, -0.8), Vector3(0.06, 0.15, -0.03), Vector3.ONE * 1.15)
		cove_node.add_child(post)

	# 3. Water lilies floating alongside hull
	if _cached_props.has("lily_large"):
		var lily: MeshInstance3D = _create_prop_instance("lily_large", Vector3(0.9, -0.32, 0.4), Vector3.ZERO, Vector3.ONE * 1.4)
		cove_node.add_child(lily)

	_register_poi("cove_mooring", "🛶 Emerald Cove Mooring", "An abandoned wooden canoe resting among cattails and sand ripples where animals gather to drink.", cove_pos, 6.5)

	# =========================================================================
	# POI 4: EASTERN GRANITE BLUFF RAPTOR SNAG (High cliff overlook)
	# =========================================================================
	var bluff_x: float = 21.5
	var bluff_z: float = 14.8
	var bluff_y: float = _terrain.get_height_at(bluff_x, bluff_z) if _terrain else 8.2
	var bluff_pos: Vector3 = Vector3(bluff_x, bluff_y, bluff_z)

	var bluff_node: Node3D = Node3D.new()
	bluff_node.name = "POI_BluffOverlook"
	bluff_node.position = bluff_pos
	add_child(bluff_node)

	# 1. Towering windswept dead pine snag
	if _cached_props.has("tree_tall_dead"):
		var snag: MeshInstance3D = _create_prop_instance("tree_tall_dead", Vector3(0.0, -0.10, 0.0), Vector3(0.05, 0.45, -0.04), Vector3.ONE * 2.1)
		bluff_node.add_child(snag)
		_add_cylinder_collision(bluff_node, Vector3(0.0, 2.0, 0.0), 0.32, 4.0)

	# 2. Surrounding talus boulders
	if _cached_props.has("rock_largeA"):
		var cliff_rock: MeshInstance3D = _create_prop_instance("rock_largeA", Vector3(1.2, -0.12, -0.9), Vector3(0.1, 1.1, -0.1), Vector3.ONE * 1.3)
		bluff_node.add_child(cliff_rock)

	_register_poi("bluff_overlook", "🦅 Granite Bluff Perch", "A windswept dead pine overlooking the entire basin, commanding panoramic views of the island.", bluff_pos, 9.5)

	# =========================================================================
	# POI 5: WHISPERING MONOLITHS & ANCIENT CAIRN (West-Southwest coastal knoll)
	# =========================================================================
	var cairn_x: float = -16.5
	var cairn_z: float = -12.5
	var cairn_y: float = _terrain.get_height_at(cairn_x, cairn_z) if _terrain else 5.4
	var cairn_pos: Vector3 = Vector3(cairn_x, cairn_y, cairn_z)

	var cairn_node: Node3D = Node3D.new()
	cairn_node.name = "POI_AncientCairn"
	cairn_node.position = cairn_pos
	add_child(cairn_node)

	# 1. Standing monoliths in an ancient ritual circle
	if _cached_props.has("rock_largeA"):
		var monolith_1: MeshInstance3D = _create_prop_instance("rock_largeA", Vector3(-1.8, -0.14, 0.0), Vector3(0.08, 0.42, 0.14), Vector3.ONE * 1.45)
		cairn_node.add_child(monolith_1)
		_add_cylinder_collision(cairn_node, Vector3(-1.8, 0.65, 0.0), 0.72, 1.6)

		var monolith_2: MeshInstance3D = _create_prop_instance("rock_largeA", Vector3(1.7, -0.12, -0.8), Vector3(-0.06, 1.85, -0.10), Vector3.ONE * 1.35)
		cairn_node.add_child(monolith_2)
		_add_cylinder_collision(cairn_node, Vector3(1.7, 0.60, -0.8), 0.68, 1.5)

	# 2. Weathered boundary stones and sacred purple alpine flora
	if _cached_props.has("rock_smallC"):
		cairn_node.add_child(_create_prop_instance("rock_smallC", Vector3(0.2, -0.06, 1.8), Vector3(0.0, 0.85, 0.0), Vector3.ONE * 1.5))
		cairn_node.add_child(_create_prop_instance("rock_smallC", Vector3(-0.9, -0.05, -1.6), Vector3(0.0, 2.15, 0.0), Vector3.ONE * 1.3))

	if _cached_props.has("flower_purpleA"):
		cairn_node.add_child(_create_prop_instance("flower_purpleA", Vector3(0.0, -0.02, 0.0), Vector3.ZERO, Vector3.ONE * 1.35))

	_register_poi("ancient_cairn", "🗿 Whispering Monoliths", "A prehistoric circle of weathered granite monoliths perched above the ocean surf, humming softly in the coastal wind.", cairn_pos, 10.5)

	# =========================================================================
	# EXPANDED WORLD (720m) OUTER CONTINENTAL POIs
	# =========================================================================
	if _terrain != null and _terrain.island_size > 200.0:
		# POI 6: Skyspire Alpine High Summit
		var sky_x: float = -145.0
		var sky_z: float = -145.0
		var sky_y: float = _terrain.get_height_at(sky_x, sky_z)
		var sky_pos: Vector3 = Vector3(sky_x, sky_y, sky_z)
		var sky_node: Node3D = Node3D.new()
		sky_node.name = "POI_SkyspireSummit"
		sky_node.position = sky_pos
		add_child(sky_node)
		if _cached_props.has("rock_largeA"):
			sky_node.add_child(_create_prop_instance("rock_largeA", Vector3(0.0, -0.2, 0.0), Vector3(0.1, 0.5, 0.0), Vector3.ONE * 2.2))
		_register_poi("skyspire_overlook", "🦅 Skyspire Alpine Peak", "The highest elevation on the continent, piercing the clouds with a panoramic overlook of all biomes.", sky_pos, 14.0)

		# POI 7: Whispering Pine Highlands Megaliths
		var high_x: float = 180.0
		var high_z: float = -30.0
		var high_y: float = _terrain.get_height_at(high_x, high_z)
		var high_pos: Vector3 = Vector3(high_x, high_y, high_z)
		var high_node: Node3D = Node3D.new()
		high_node.name = "POI_HighlandPlateau"
		high_node.position = high_pos
		add_child(high_node)
		if _cached_props.has("rock_largeA"):
			high_node.add_child(_create_prop_instance("rock_largeA", Vector3(-1.5, -0.15, 0.0), Vector3.ZERO, Vector3.ONE * 1.8))
			high_node.add_child(_create_prop_instance("rock_largeA", Vector3(1.5, -0.15, 0.0), Vector3.ZERO, Vector3.ONE * 1.6))
		_register_poi("highland_ring", "🌲 Highland Megalith Ring", "An elevated plateau covered in ancient pine woods and monumental rock slabs overlooking the eastern ocean.", high_pos, 14.0)

		# POI 8: Cape Solitude Ocean Bluffs
		var cape_x: float = 20.0
		var cape_z: float = 195.0
		var cape_y: float = _terrain.get_height_at(cape_x, cape_z)
		var cape_pos: Vector3 = Vector3(cape_x, cape_y, cape_z)
		var cape_node: Node3D = Node3D.new()
		cape_node.name = "POI_CapeSolitude"
		cape_node.position = cape_pos
		add_child(cape_node)
		if _cached_props.has("tree_tall_dead"):
			cape_node.add_child(_create_prop_instance("tree_tall_dead", Vector3(0.0, -0.1, 0.0), Vector3.ZERO, Vector3.ONE * 1.4))
		_register_poi("cape_solitude", "⚓ Cape Solitude Bluffs", "Sheer ocean cliffs facing the Southern breakers, where pelagic currents crash against granite tors.", cape_pos, 14.0)

		# POI 9: Alpine Glacial Tarn Lake
		var tarn_pos: Vector3 = Vector3(-125.0, 36.0, -110.0)
		_register_poi("alpine_tarn", "💎 Skyspire Alpine Tarn", "A pristine high-altitude glacial lake nestled inside the alpine mountain amphitheater, reflecting the icy summits.", tarn_pos, 16.0)

		# POI 10: Whispering Grotto Cavern
		var grotto_pos: Vector3 = Vector3(-78.0, 16.5, -72.0)
		_register_poi("whispering_grotto", "🔮 Whispering Grotto", "A vaulted subterranean rock cavern carved beneath the mountain roots, illuminated by azure crystals and an echoing pool.", grotto_pos, 14.0)

		# POI 11: Silverveil Glacial Falls
		var falls_pos: Vector3 = Vector3(-96.0, 26.5, -88.0)
		_register_poi("glacial_waterfall", "🌊 Silverveil Glacial Falls", "A thundering glacial mountain cascade spilling from the Alpine Tarn down through stepped rock gorges into the cavern valley.", falls_pos, 18.0)

func _create_prop_instance(prop_name: String, rel_pos: Vector3, rel_rot: Vector3, prop_scale: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = prop_name + "_Mesh"
	mi.mesh = _cached_props[prop_name]["mesh"]
	mi.material_override = _cached_props[prop_name]["mat"]
	mi.position = rel_pos
	mi.rotation = rel_rot
	mi.scale = prop_scale
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi

func _add_box_collision(parent: Node3D, col_pos: Vector3, col_size: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "PropStaticBody"
	body.collision_layer = 1
	body.collision_mask = 0
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = col_size
	col.shape = box
	col.position = col_pos
	body.add_child(col)
	parent.add_child(body)

func _add_cylinder_collision(parent: Node3D, col_pos: Vector3, radius: float, height: float) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "PropStaticBody"
	body.collision_layer = 1
	body.collision_mask = 0
	var col: CollisionShape3D = CollisionShape3D.new()
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	col.shape = cyl
	col.position = col_pos
	body.add_child(col)
	parent.add_child(body)

func _register_poi(poi_id: String, title: String, body: String, pos: Vector3, radius: float) -> void:
	_pois.append({
		"id": poi_id,
		"title": title,
		"body": body,
		"position": pos,
		"radius": radius,
		"discovered": false
	})

func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer < 0.25:
		return
	_check_timer = 0.0

	var p_pos: Vector3 = _get_player_position()
	for poi in _pois:
		if not poi["discovered"]:
			var dist: float = p_pos.distance_to(poi["position"])
			if dist <= poi["radius"]:
				poi["discovered"] = true
				_discovered_count += 1
				_trigger_discovery(poi)

func _trigger_discovery(poi: Dictionary) -> void:
	var poi_id: String = poi["id"]
	var title: String = poi["title"]
	var body: String = poi["body"]

	print("[EnvironmentalStorytelling] Discovered POI: %s — %s" % [title, body])
	discovery_unlocked.emit(poi_id, title, body)

	if _event_bus:
		_event_bus.publish("environmental_discovery", {
			"id": poi_id,
			"title": title,
			"body": body,
			"position": poi.get("position", Vector3.ZERO),
			"discovered_count": _discovered_count,
			"total_count": _pois.size()
		})

	if _hud and _hud.has_method("_on_emergent_event"):
		_hud.call("_on_emergent_event", "discovery", title, body, "notice")

func _get_player_position() -> Vector3:
	if _camera is FreeLookCamera:
		var cam: FreeLookCamera = _camera as FreeLookCamera
		if (cam.current_mode == FreeLookCamera.CameraMode.FIRST_PERSON_WALKER or cam.current_mode == FreeLookCamera.CameraMode.THIRD_PERSON_CHARACTER) and cam.get_walker():
			var walker = cam.get_walker()
			if walker.is_inside_tree():
				return walker.global_position
			elif walker.position != Vector3.ZERO:
				return walker.position
		return cam.global_position if cam.is_inside_tree() else cam.position
	elif _camera:
		return _camera.global_position if _camera.is_inside_tree() else _camera.position
	return Vector3.ZERO

func get_poi_count() -> int:
	return _pois.size()

func get_discovered_count() -> int:
	return _discovered_count

func get_poi_by_id(poi_id: String) -> Dictionary:
	for p in _pois:
		if p["id"] == poi_id:
			return p
	return {}

func get_all_pois() -> Array[Dictionary]:
	return _pois

func get_nearest_poi(pos: Vector3) -> Dictionary:
	var best_dist: float = 999999.0
	var best_poi: Dictionary = {}
	for p in _pois:
		var d: float = pos.distance_to(p["position"])
		if d < best_dist:
			best_dist = d
			best_poi = p.duplicate()
			best_poi["distance"] = d
	return best_poi
