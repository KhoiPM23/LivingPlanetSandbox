class_name MedievalHavenVillage
extends Node3D

## Living Planet Sandbox — Coastal Haven Medieval Village & Living NPCs
## Authentic medieval coastal outpost featuring:
## 1. Haven Watchtower & Beacon Light (circular stone masonry + brazier)
## 2. Harbor Master's Timber Cottage (timber framing, stone chimney, cedar shingles)
## 3. Herbalist's Alchemy Lodge (flower planters, herb drying racks)
## 4. Village Square with Stone Well, rustic benches, and multi-directional signposts
## 5. Living NPCs: Harbor Master Alistair and Herbalist Elowen with look-at tracking and overhead nameplates

signal interaction_requested(target_type: String, target_id: String, target_pos: Vector3)

var _terrain: IslandTerrain = null
var _player_node: Node3D = null

# Materials
var _stone_mat: StandardMaterial3D = null
var _wood_mat: StandardMaterial3D = null
var _roof_mat: StandardMaterial3D = null
var _iron_mat: StandardMaterial3D = null
var _plank_mat: StandardMaterial3D = null
var _cloth_mat: StandardMaterial3D = null
var _ember_mat: StandardMaterial3D = null
var _road_mat: StandardMaterial3D = null

# NPC Nodes
var _npc_alistair: Node3D = null
var _npc_elowen: Node3D = null
var _npc_milo: Node3D = null
var _npc_goran: Node3D = null
var _signpost_node: Node3D = null
var _cooking_hearth: Node3D = null
var _blacksmith_forge: Node3D = null
var _training_dummy: Node3D = null
var _lighthouse_beam: Node3D = null
var _dummy_wobble_time: float = 0.0
var _street_lantern_lights: Array[OmniLight3D] = []
var _dog_buster: Node3D = null
var _dog_tail: Node3D = null
var _buster_base_y: float = 0.0
var _buster_pet_time: float = 0.0
var _buster_particles: GPUParticles3D = null

var _cat_mimi: Node3D = null
var _cat_tail: Node3D = null
var _mimi_pet_time: float = 0.0
var _mimi_particles: GPUParticles3D = null

var _animal_audio: AudioStreamPlayer3D = null
var _chickens: Array[Node3D] = []
var _anim_time: float = 0.0

static var _dog_bark_wav: AudioStreamWAV = null
static var _cat_purr_wav: AudioStreamWAV = null

func setup(terrain: IslandTerrain, player: Node3D = null) -> void:
	_terrain = terrain
	_player_node = player
	_init_materials()

	_build_watchtower()
	_build_harbor_cottage()
	_build_herbalist_lodge()
	_build_seawind_tavern()
	_build_village_square_and_well()
	_build_harbor_market_stall()
	_build_cooking_hearth()
	_build_blacksmith_forge()
	_build_practice_dummy()
	_build_harbor_fishery_warehouse()
	_build_hillside_suburban_cottage()
	_build_cobblestone_street_network()
	_build_lighthouse_beam()
	_build_street_lanterns()
	_spawn_living_npcs()
	_spawn_village_animals()
	_apply_culling_and_shadow_optimizations()

func _init_materials() -> void:
	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.42, 0.40, 0.38) # Granite ashlar stone
	_stone_mat.roughness = 0.90

	_wood_mat = StandardMaterial3D.new()
	_wood_mat.albedo_color = Color(0.44, 0.32, 0.20) # Weathered oak timber
	_wood_mat.roughness = 0.82

	_roof_mat = StandardMaterial3D.new()
	_roof_mat.albedo_color = Color(0.58, 0.28, 0.22) # Terracotta clay tiles
	_roof_mat.roughness = 0.85

	_iron_mat = StandardMaterial3D.new()
	_iron_mat.albedo_color = Color(0.18, 0.18, 0.20)
	_iron_mat.metallic = 0.85
	_iron_mat.roughness = 0.45

	_plank_mat = StandardMaterial3D.new()
	_plank_mat.albedo_color = Color(0.46, 0.34, 0.22) # Rich oak floorboards
	_plank_mat.roughness = 0.78

	_cloth_mat = StandardMaterial3D.new()
	_cloth_mat.albedo_color = Color(0.78, 0.74, 0.68) # Linen bedding/canvas
	_cloth_mat.roughness = 0.95

	_ember_mat = StandardMaterial3D.new()
	_ember_mat.albedo_color = Color(1.0, 0.40, 0.10)
	_ember_mat.emission_enabled = true
	_ember_mat.emission = Color(1.0, 0.38, 0.08)
	_ember_mat.emission_energy_multiplier = 2.5

	_road_mat = StandardMaterial3D.new()
	_road_mat.albedo_color = Color(0.38, 0.36, 0.34) # Weathered cobblestone road
	_road_mat.roughness = 0.92

# =============================================================================
# 1. HAVEN WATCHTOWER & BEACON LIGHT
# =============================================================================
func _build_watchtower() -> void:
	var twr_x: float = 6.5
	var twr_z: float = -6.5
	var ground_y: float = _terrain.get_height_at(twr_x, twr_z) if _terrain else 1.8

	var twr_root: Node3D = Node3D.new()
	twr_root.name = "HavenWatchtower"
	twr_root.position = Vector3(twr_x, ground_y, twr_z)
	add_child(twr_root)

	# Main cylindrical stone tower
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 1.75
	cyl.bottom_radius = 1.95
	cyl.height = 7.2
	var stone_tower: MeshInstance3D = MeshInstance3D.new()
	stone_tower.mesh = cyl
	stone_tower.material_override = _stone_mat
	stone_tower.position = Vector3(0.0, 3.6, 0.0)
	twr_root.add_child(stone_tower)

	# Timber lookout parapet
	var parapet: BoxMesh = BoxMesh.new()
	parapet.size = Vector3(4.2, 0.85, 4.2)
	var parapet_inst: MeshInstance3D = MeshInstance3D.new()
	parapet_inst.mesh = parapet
	parapet_inst.material_override = _wood_mat
	parapet_inst.position = Vector3(0.0, 7.4, 0.0)
	twr_root.add_child(parapet_inst)

	# Conical roof
	var roof: CylinderMesh = CylinderMesh.new()
	roof.top_radius = 0.05
	roof.bottom_radius = 2.4
	roof.height = 2.4
	var roof_inst: MeshInstance3D = MeshInstance3D.new()
	roof_inst.mesh = roof
	roof_inst.material_override = _roof_mat
	roof_inst.position = Vector3(0.0, 9.0, 0.0)
	twr_root.add_child(roof_inst)

	# Warm Beacon Light
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1.0, 0.78, 0.42)
	light.light_energy = 1.8
	light.omni_range = 18.0
	light.position = Vector3(0.0, 7.8, 0.0)
	twr_root.add_child(light)

	# Static collision
	_add_cylinder_collision(twr_root, Vector3(0.0, 3.6, 0.0), 1.9, 7.2)

# =============================================================================
# 2. HARBOR MASTER'S TIMBER COTTAGE (ENTERABLE MODULAR ARCHITECTURE)
# =============================================================================
func _build_harbor_cottage() -> void:
	var cot_x: float = 10.5
	var cot_z: float = 1.2
	var g_center: float = _terrain.get_height_at(cot_x, cot_z) if _terrain else 1.2
	var g_back: float = _terrain.get_height_at(cot_x, cot_z - 2.5) if _terrain else 1.2
	var g_left: float = _terrain.get_height_at(cot_x - 3.0, cot_z) if _terrain else 1.2
	var ground_y: float = maxf(g_center, maxf(g_back, g_left)) + 0.25

	var cot_root: Node3D = Node3D.new()
	cot_root.name = "HarborMasterCottage"
	cot_root.position = Vector3(cot_x, ground_y, cot_z)
	cot_root.rotation.y = deg_to_rad(-18.0)
	add_child(cot_root)

	# Stone Foundation Plinth (anchors building into ground, seals out grass)
	var found_box: BoxMesh = BoxMesh.new()
	found_box.size = Vector3(6.4, 1.4, 5.4)
	var found_inst: MeshInstance3D = MeshInstance3D.new()
	found_inst.mesh = found_box
	found_inst.material_override = _stone_mat
	found_inst.position = Vector3(0.0, -0.62, 0.0)
	cot_root.add_child(found_inst)
	_add_box_collision(cot_root, Vector3(0.0, -0.62, 0.0), Vector3(6.4, 1.4, 5.4))

	# 1. Walkable Timber Plank Floor
	var floor_box: BoxMesh = BoxMesh.new()
	floor_box.size = Vector3(6.2, 0.16, 5.2)
	var floor_inst: MeshInstance3D = MeshInstance3D.new()
	floor_inst.mesh = floor_box
	floor_inst.material_override = _plank_mat
	floor_inst.position = Vector3(0.0, 0.08, 0.0)
	cot_root.add_child(floor_inst)

	# Entrance Timber Step
	var step_box: BoxMesh = BoxMesh.new()
	step_box.size = Vector3(2.0, 0.25, 0.8)
	var step_inst: MeshInstance3D = MeshInstance3D.new()
	step_inst.mesh = step_box
	step_inst.material_override = _wood_mat
	step_inst.position = Vector3(0.0, -0.12, 2.9)
	cot_root.add_child(step_inst)

	# 2. Back Wall (Z = -2.5)
	var back_wall: BoxMesh = BoxMesh.new()
	back_wall.size = Vector3(6.2, 3.2, 0.25)
	var back_inst: MeshInstance3D = MeshInstance3D.new()
	back_inst.mesh = back_wall
	back_inst.material_override = _wood_mat
	back_inst.position = Vector3(0.0, 1.6, -2.5)
	cot_root.add_child(back_inst)
	_add_box_collision(cot_root, Vector3(0.0, 1.6, -2.5), Vector3(6.2, 3.2, 0.25))

	# 3. Left Wall (X = -3.0) with Timber Framing
	var left_wall: BoxMesh = BoxMesh.new()
	left_wall.size = Vector3(0.25, 3.2, 5.2)
	var left_inst: MeshInstance3D = MeshInstance3D.new()
	left_inst.mesh = left_wall
	left_inst.material_override = _wood_mat
	left_inst.position = Vector3(-3.0, 1.6, 0.0)
	cot_root.add_child(left_inst)
	_add_box_collision(cot_root, Vector3(-3.0, 1.6, 0.0), Vector3(0.25, 3.2, 5.2))

	# 4. Right Wall (X = +3.0) with Stone Fireplace Recess
	var right_wall: BoxMesh = BoxMesh.new()
	right_wall.size = Vector3(0.25, 3.2, 5.2)
	var right_inst: MeshInstance3D = MeshInstance3D.new()
	right_inst.mesh = right_wall
	right_inst.material_override = _wood_mat
	right_inst.position = Vector3(3.0, 1.6, 0.0)
	cot_root.add_child(right_inst)
	_add_box_collision(cot_root, Vector3(3.0, 1.6, 0.0), Vector3(0.25, 3.2, 5.2))

	# 5. Front Wall with Open Walkable Doorway (Z = +2.5)
	# Left front section (X: -3.0 to -0.9)
	var front_l: BoxMesh = BoxMesh.new()
	front_l.size = Vector3(2.1, 3.2, 0.25)
	var front_l_inst: MeshInstance3D = MeshInstance3D.new()
	front_l_inst.mesh = front_l
	front_l_inst.material_override = _wood_mat
	front_l_inst.position = Vector3(-1.95, 1.6, 2.5)
	cot_root.add_child(front_l_inst)
	_add_box_collision(cot_root, Vector3(-1.95, 1.6, 2.5), Vector3(2.1, 3.2, 0.25))

	# Right front section (X: +0.9 to +3.0)
	var front_r: BoxMesh = BoxMesh.new()
	front_r.size = Vector3(2.1, 3.2, 0.25)
	var front_r_inst: MeshInstance3D = MeshInstance3D.new()
	front_r_inst.mesh = front_r
	front_r_inst.material_override = _wood_mat
	front_r_inst.position = Vector3(1.95, 1.6, 2.5)
	cot_root.add_child(front_r_inst)
	_add_box_collision(cot_root, Vector3(1.95, 1.6, 2.5), Vector3(2.1, 3.2, 0.25))

	# Doorway lintel beam (Y: 2.5 to 3.2)
	var lintel: BoxMesh = BoxMesh.new()
	lintel.size = Vector3(1.8, 0.7, 0.25)
	var lintel_inst: MeshInstance3D = MeshInstance3D.new()
	lintel_inst.mesh = lintel
	lintel_inst.material_override = _wood_mat
	lintel_inst.position = Vector3(0.0, 2.85, 2.5)
	cot_root.add_child(lintel_inst)

	# 6. Pitched Gabled Terracotta Roof
	var prand: PrismMesh = PrismMesh.new()
	prand.size = Vector3(5.6, 2.2, 6.8)
	var roof_inst: MeshInstance3D = MeshInstance3D.new()
	roof_inst.mesh = prand
	roof_inst.material_override = _roof_mat
	roof_inst.rotation.y = deg_to_rad(90.0)
	roof_inst.position = Vector3(0.0, 4.3, 0.0)
	cot_root.add_child(roof_inst)

	# 7. Stone Chimney
	var chimney: BoxMesh = BoxMesh.new()
	chimney.size = Vector3(0.9, 5.0, 0.9)
	var chim_inst: MeshInstance3D = MeshInstance3D.new()
	chim_inst.mesh = chimney
	chim_inst.material_override = _stone_mat
	chim_inst.position = Vector3(2.6, 2.5, 0.6)
	cot_root.add_child(chim_inst)

	# 8. Interior: Stone Fireplace Hearth & Firelight
	var hearth: BoxMesh = BoxMesh.new()
	hearth.size = Vector3(0.7, 1.5, 1.4)
	var hearth_inst: MeshInstance3D = MeshInstance3D.new()
	hearth_inst.mesh = hearth
	hearth_inst.material_override = _stone_mat
	hearth_inst.position = Vector3(2.6, 0.75, 0.6)
	cot_root.add_child(hearth_inst)

	var embers: BoxMesh = BoxMesh.new()
	embers.size = Vector3(0.35, 0.12, 0.7)
	var ember_inst: MeshInstance3D = MeshInstance3D.new()
	ember_inst.mesh = embers
	ember_inst.material_override = _ember_mat
	ember_inst.position = Vector3(2.35, 0.20, 0.6)
	cot_root.add_child(ember_inst)

	var fire_omni: OmniLight3D = OmniLight3D.new()
	fire_omni.light_color = Color(1.0, 0.65, 0.22)
	fire_omni.light_energy = 1.2
	fire_omni.omni_range = 5.0
	fire_omni.shadow_enabled = false
	fire_omni.position = Vector3(2.1, 0.6, 0.6)
	cot_root.add_child(fire_omni)

	# 9. Interior: Dining Table & Stools
	var table_top: BoxMesh = BoxMesh.new()
	table_top.size = Vector3(1.4, 0.08, 0.9)
	var table_inst: MeshInstance3D = MeshInstance3D.new()
	table_inst.mesh = table_top
	table_inst.material_override = _wood_mat
	table_inst.position = Vector3(-0.8, 0.82, 0.0)
	cot_root.add_child(table_inst)

	var t_leg: BoxMesh = BoxMesh.new()
	t_leg.size = Vector3(0.08, 0.78, 0.08)
	for lx in [-0.6, 0.6]:
		for lz in [-0.35, 0.35]:
			var leg_inst: MeshInstance3D = MeshInstance3D.new()
			leg_inst.mesh = t_leg
			leg_inst.material_override = _wood_mat
			leg_inst.position = Vector3(-0.8 + lx, 0.39, lz)
			cot_root.add_child(leg_inst)

	var stool_mesh: CylinderMesh = CylinderMesh.new()
	stool_mesh.top_radius = 0.22
	stool_mesh.bottom_radius = 0.24
	stool_mesh.height = 0.45
	for sx in [-0.8, 0.0]:
		var stool: MeshInstance3D = MeshInstance3D.new()
		stool.mesh = stool_mesh
		stool.material_override = _wood_mat
		stool.position = Vector3(sx, 0.23, 0.8)
		cot_root.add_child(stool)

	# 10. Interior: Adventurer's Bed (Back-left corner)
	var bed_frame: BoxMesh = BoxMesh.new()
	bed_frame.size = Vector3(1.3, 0.35, 2.1)
	var bed_inst: MeshInstance3D = MeshInstance3D.new()
	bed_inst.mesh = bed_frame
	bed_inst.material_override = _wood_mat
	bed_inst.position = Vector3(-2.1, 0.18, -1.2)
	cot_root.add_child(bed_inst)

	var mattress: BoxMesh = BoxMesh.new()
	mattress.size = Vector3(1.2, 0.18, 1.95)
	var mat_inst: MeshInstance3D = MeshInstance3D.new()
	mat_inst.mesh = mattress
	mat_inst.material_override = _cloth_mat
	mat_inst.position = Vector3(-2.1, 0.42, -1.2)
	cot_root.add_child(mat_inst)

	var pillow: BoxMesh = BoxMesh.new()
	pillow.size = Vector3(0.9, 0.12, 0.45)
	var pil_inst: MeshInstance3D = MeshInstance3D.new()
	pil_inst.mesh = pillow
	pil_inst.material_override = _cloth_mat
	pil_inst.position = Vector3(-2.1, 0.54, -1.9)
	cot_root.add_child(pil_inst)

	# 11. Interior: Bookshelf & Cupboard
	var shelf: BoxMesh = BoxMesh.new()
	shelf.size = Vector3(1.4, 2.0, 0.4)
	var shelf_inst: MeshInstance3D = MeshInstance3D.new()
	shelf_inst.mesh = shelf
	shelf_inst.material_override = _wood_mat
	shelf_inst.position = Vector3(0.8, 1.0, -2.2)
	cot_root.add_child(shelf_inst)

	# 12. Interior Hanging Lantern
	var int_lantern: OmniLight3D = OmniLight3D.new()
	int_lantern.light_color = Color(1.0, 0.88, 0.60)
	int_lantern.light_energy = 0.95
	int_lantern.omni_range = 5.5
	int_lantern.shadow_enabled = false
	int_lantern.position = Vector3(0.0, 2.7, 0.0)
	cot_root.add_child(int_lantern)

# =============================================================================
# 3. HERBALIST'S BOTANICAL CHALET (ENTERABLE MODULAR ARCHITECTURE)
# =============================================================================
func _build_herbalist_lodge() -> void:
	var lod_x: float = 18.5
	var lod_z: float = -5.5
	var g_center: float = _terrain.get_height_at(lod_x, lod_z) if _terrain else 1.5
	var g_back: float = _terrain.get_height_at(lod_x, lod_z - 2.2) if _terrain else 1.5
	var ground_y: float = maxf(g_center, g_back) + 0.25

	var lod_root: Node3D = Node3D.new()
	lod_root.name = "HerbalistLodge"
	lod_root.position = Vector3(lod_x, ground_y, lod_z)
	lod_root.rotation.y = deg_to_rad(28.0)
	add_child(lod_root)

	# Stone Foundation Plinth
	var found_box: BoxMesh = BoxMesh.new()
	found_box.size = Vector3(5.6, 1.4, 4.6)
	var found_inst: MeshInstance3D = MeshInstance3D.new()
	found_inst.mesh = found_box
	found_inst.material_override = _stone_mat
	found_inst.position = Vector3(0.0, -0.62, 0.0)
	lod_root.add_child(found_inst)
	_add_box_collision(lod_root, Vector3(0.0, -0.62, 0.0), Vector3(5.6, 1.4, 4.6))

	# 1. Walkable Timber Plank Floor
	var floor_box: BoxMesh = BoxMesh.new()
	floor_box.size = Vector3(5.4, 0.16, 4.4)
	var floor_inst: MeshInstance3D = MeshInstance3D.new()
	floor_inst.mesh = floor_box
	floor_inst.material_override = _plank_mat
	floor_inst.position = Vector3(0.0, 0.08, 0.0)
	lod_root.add_child(floor_inst)

	# Entrance Step
	var step_box: BoxMesh = BoxMesh.new()
	step_box.size = Vector3(1.8, 0.25, 0.7)
	var step_inst: MeshInstance3D = MeshInstance3D.new()
	step_inst.mesh = step_box
	step_inst.material_override = _wood_mat
	step_inst.position = Vector3(0.0, -0.12, 2.5)
	lod_root.add_child(step_inst)

	# 2. Back Wall (Z = -2.1)
	var back_wall: BoxMesh = BoxMesh.new()
	back_wall.size = Vector3(5.4, 2.8, 0.25)
	var back_inst: MeshInstance3D = MeshInstance3D.new()
	back_inst.mesh = back_wall
	back_inst.material_override = _stone_mat
	back_inst.position = Vector3(0.0, 1.4, -2.1)
	lod_root.add_child(back_inst)
	_add_box_collision(lod_root, Vector3(0.0, 1.4, -2.1), Vector3(5.4, 2.8, 0.25))

	# 3. Left Wall (X = -2.6)
	var left_wall: BoxMesh = BoxMesh.new()
	left_wall.size = Vector3(0.25, 2.8, 4.4)
	var left_inst: MeshInstance3D = MeshInstance3D.new()
	left_inst.mesh = left_wall
	left_inst.material_override = _wood_mat
	left_inst.position = Vector3(-2.6, 1.4, 0.0)
	lod_root.add_child(left_inst)
	_add_box_collision(lod_root, Vector3(-2.6, 1.4, 0.0), Vector3(0.25, 2.8, 4.4))

	# 4. Right Wall (X = +2.6)
	var right_wall: BoxMesh = BoxMesh.new()
	right_wall.size = Vector3(0.25, 2.8, 4.4)
	var right_inst: MeshInstance3D = MeshInstance3D.new()
	right_inst.mesh = right_wall
	right_inst.material_override = _wood_mat
	right_inst.position = Vector3(2.6, 1.4, 0.0)
	lod_root.add_child(right_inst)
	_add_box_collision(lod_root, Vector3(2.6, 1.4, 0.0), Vector3(0.25, 2.8, 4.4))

	# 5. Front Wall with Open Doorway (Z = +2.1)
	var front_l: BoxMesh = BoxMesh.new()
	front_l.size = Vector3(1.8, 2.8, 0.25)
	var front_l_inst: MeshInstance3D = MeshInstance3D.new()
	front_l_inst.mesh = front_l
	front_l_inst.material_override = _stone_mat
	front_l_inst.position = Vector3(-1.7, 1.4, 2.1)
	lod_root.add_child(front_l_inst)
	_add_box_collision(lod_root, Vector3(-1.7, 1.4, 2.1), Vector3(1.8, 2.8, 0.25))

	var front_r: BoxMesh = BoxMesh.new()
	front_r.size = Vector3(1.8, 2.8, 0.25)
	var front_r_inst: MeshInstance3D = MeshInstance3D.new()
	front_r_inst.mesh = front_r
	front_r_inst.material_override = _stone_mat
	front_r_inst.position = Vector3(1.7, 1.4, 2.1)
	lod_root.add_child(front_r_inst)
	_add_box_collision(lod_root, Vector3(1.7, 1.4, 2.1), Vector3(1.8, 2.8, 0.25))

	var lintel: BoxMesh = BoxMesh.new()
	lintel.size = Vector3(1.8, 0.6, 0.25)
	var lintel_inst: MeshInstance3D = MeshInstance3D.new()
	lintel_inst.mesh = lintel
	lintel_inst.material_override = _wood_mat
	lintel_inst.position = Vector3(0.0, 2.5, 2.1)
	lod_root.add_child(lintel_inst)

	# 6. Roof
	var roof_prism: PrismMesh = PrismMesh.new()
	roof_prism.size = Vector3(4.8, 1.9, 5.8)
	var roof_inst: MeshInstance3D = MeshInstance3D.new()
	roof_inst.mesh = roof_prism
	roof_inst.material_override = _roof_mat
	roof_inst.rotation.y = deg_to_rad(90.0)
	roof_inst.position = Vector3(0.0, 3.7, 0.0)
	lod_root.add_child(roof_inst)

	# 7. Interior: Herbalist Apothecary Table & Dry Racks
	var table: BoxMesh = BoxMesh.new()
	table.size = Vector3(1.6, 0.8, 0.8)
	var t_inst: MeshInstance3D = MeshInstance3D.new()
	t_inst.mesh = table
	t_inst.material_override = _wood_mat
	t_inst.position = Vector3(0.0, 0.4, -1.3)
	lod_root.add_child(t_inst)

	var flask: CylinderMesh = CylinderMesh.new()
	flask.top_radius = 0.04
	flask.bottom_radius = 0.12
	flask.height = 0.25
	var flask_inst: MeshInstance3D = MeshInstance3D.new()
	flask_inst.mesh = flask
	flask_inst.position = Vector3(0.4, 0.92, -1.3)
	lod_root.add_child(flask_inst)

	var rack: BoxMesh = BoxMesh.new()
	rack.size = Vector3(1.8, 0.08, 0.08)
	var rack_inst: MeshInstance3D = MeshInstance3D.new()
	rack_inst.mesh = rack
	rack_inst.material_override = _wood_mat
	rack_inst.position = Vector3(0.0, 2.3, 0.3)
	lod_root.add_child(rack_inst)

	var h_omni: OmniLight3D = OmniLight3D.new()
	h_omni.light_color = Color(1.0, 0.82, 0.50)
	h_omni.light_energy = 0.9
	h_omni.omni_range = 5.0
	h_omni.shadow_enabled = false
	h_omni.position = Vector3(0.0, 2.4, 0.0)
	lod_root.add_child(h_omni)

# =============================================================================
# 3b. SEA WIND TAVERN & INN ("QUÁN TRỌ GIÓ BIỂN")
# =============================================================================
func _build_seawind_tavern() -> void:
	var tav_x: float = 14.5
	var tav_z: float = 7.2
	var g_center: float = _terrain.get_height_at(tav_x, tav_z) if _terrain else 1.2
	var g_back: float = _terrain.get_height_at(tav_x, tav_z - 3.0) if _terrain else 1.2
	var ground_y: float = maxf(g_center, g_back) + 0.25

	var tav_root: Node3D = Node3D.new()
	tav_root.name = "SeaWindTavern"
	tav_root.position = Vector3(tav_x, ground_y, tav_z)
	tav_root.rotation.y = deg_to_rad(-45.0)
	add_child(tav_root)

	# Stone Foundation Plinth
	var found_box: BoxMesh = BoxMesh.new()
	found_box.size = Vector3(7.8, 1.4, 6.4)
	var found_inst: MeshInstance3D = MeshInstance3D.new()
	found_inst.mesh = found_box
	found_inst.material_override = _stone_mat
	found_inst.position = Vector3(0.0, -0.62, 0.0)
	tav_root.add_child(found_inst)
	_add_box_collision(tav_root, Vector3(0.0, -0.62, 0.0), Vector3(7.8, 1.4, 6.4))

	# 1. Walkable Timber Plank Floor (7.6m x 6.2m)
	var floor_box: BoxMesh = BoxMesh.new()
	floor_box.size = Vector3(7.6, 0.16, 6.2)
	var floor_inst: MeshInstance3D = MeshInstance3D.new()
	floor_inst.mesh = floor_box
	floor_inst.material_override = _plank_mat
	floor_inst.position = Vector3(0.0, 0.08, 0.0)
	tav_root.add_child(floor_inst)

	# Entrance Step
	var step_box: BoxMesh = BoxMesh.new()
	step_box.size = Vector3(2.4, 0.25, 0.8)
	var step_inst: MeshInstance3D = MeshInstance3D.new()
	step_inst.mesh = step_box
	step_inst.material_override = _wood_mat
	step_inst.position = Vector3(0.0, -0.12, 3.4)
	tav_root.add_child(step_inst)

	# 2. Back Wall (Z = -3.0)
	var back_wall: BoxMesh = BoxMesh.new()
	back_wall.size = Vector3(7.6, 3.6, 0.28)
	var back_inst: MeshInstance3D = MeshInstance3D.new()
	back_inst.mesh = back_wall
	back_inst.material_override = _stone_mat
	back_inst.position = Vector3(0.0, 1.8, -3.0)
	tav_root.add_child(back_inst)
	_add_box_collision(tav_root, Vector3(0.0, 1.8, -3.0), Vector3(7.6, 3.6, 0.28))

	# 3. Left Wall (X = -3.7)
	var left_wall: BoxMesh = BoxMesh.new()
	left_wall.size = Vector3(0.28, 3.6, 6.2)
	var left_inst: MeshInstance3D = MeshInstance3D.new()
	left_inst.mesh = left_wall
	left_inst.material_override = _wood_mat
	left_inst.position = Vector3(-3.7, 1.8, 0.0)
	tav_root.add_child(left_inst)
	_add_box_collision(tav_root, Vector3(-3.7, 1.8, 0.0), Vector3(0.28, 3.6, 6.2))

	# 4. Right Wall (X = +3.7) with large tavern fireplace
	var right_wall: BoxMesh = BoxMesh.new()
	right_wall.size = Vector3(0.28, 3.6, 6.2)
	var right_inst: MeshInstance3D = MeshInstance3D.new()
	right_inst.mesh = right_wall
	right_inst.material_override = _stone_mat
	right_inst.position = Vector3(3.7, 1.8, 0.0)
	tav_root.add_child(right_inst)
	_add_box_collision(tav_root, Vector3(3.7, 1.8, 0.0), Vector3(0.28, 3.6, 6.2))

	# 5. Front Wall with Open Doorway (Z = +3.0)
	var front_l: BoxMesh = BoxMesh.new()
	front_l.size = Vector3(2.6, 3.6, 0.28)
	var front_l_inst: MeshInstance3D = MeshInstance3D.new()
	front_l_inst.mesh = front_l
	front_l_inst.material_override = _wood_mat
	front_l_inst.position = Vector3(-2.4, 1.8, 3.0)
	tav_root.add_child(front_l_inst)
	_add_box_collision(tav_root, Vector3(-2.4, 1.8, 3.0), Vector3(2.6, 3.6, 0.28))

	var front_r: BoxMesh = BoxMesh.new()
	front_r.size = Vector3(2.6, 3.6, 0.28)
	var front_r_inst: MeshInstance3D = MeshInstance3D.new()
	front_r_inst.mesh = front_r
	front_r_inst.material_override = _wood_mat
	front_r_inst.position = Vector3(2.4, 1.8, 3.0)
	tav_root.add_child(front_r_inst)
	_add_box_collision(tav_root, Vector3(2.4, 1.8, 3.0), Vector3(2.6, 3.6, 0.28))

	var lintel: BoxMesh = BoxMesh.new()
	lintel.size = Vector3(2.4, 0.8, 0.28)
	var lintel_inst: MeshInstance3D = MeshInstance3D.new()
	lintel_inst.mesh = lintel
	lintel_inst.material_override = _wood_mat
	lintel_inst.position = Vector3(0.0, 3.2, 3.0)
	tav_root.add_child(lintel_inst)

	var tavern_lbl: Label3D = Label3D.new()
	tavern_lbl.text = "🍻 QUÁN TRỌ GIÓ BIỂN"
	tavern_lbl.font_size = 20
	tavern_lbl.modulate = Color(1.0, 0.90, 0.65)
	tavern_lbl.outline_modulate = Color(0.12, 0.08, 0.04, 0.9)
	tavern_lbl.outline_size = 5
	tavern_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tavern_lbl.position = Vector3(0.0, 3.9, 3.2)
	tav_root.add_child(tavern_lbl)

	# 6. Roof
	var roof_prism: PrismMesh = PrismMesh.new()
	roof_prism.size = Vector3(6.8, 2.4, 8.2)
	var roof_inst: MeshInstance3D = MeshInstance3D.new()
	roof_inst.mesh = roof_prism
	roof_inst.material_override = _roof_mat
	roof_inst.rotation.y = deg_to_rad(90.0)
	roof_inst.position = Vector3(0.0, 4.8, 0.0)
	tav_root.add_child(roof_inst)

	# 7. Interior: L-shaped Tavern Bar Counter & Stools
	var bar_counter: BoxMesh = BoxMesh.new()
	bar_counter.size = Vector3(3.2, 0.95, 0.65)
	var bar_inst: MeshInstance3D = MeshInstance3D.new()
	bar_inst.mesh = bar_counter
	bar_inst.material_override = _wood_mat
	bar_inst.position = Vector3(-1.8, 0.48, -1.2)
	tav_root.add_child(bar_inst)

	for bi in range(3):
		var bar_stool: CylinderMesh = CylinderMesh.new()
		bar_stool.top_radius = 0.22
		bar_stool.bottom_radius = 0.24
		bar_stool.height = 0.65
		var bs_inst: MeshInstance3D = MeshInstance3D.new()
		bs_inst.mesh = bar_stool
		bs_inst.material_override = _wood_mat
		bs_inst.position = Vector3(-2.6 + float(bi) * 0.8, 0.33, -0.45)
		tav_root.add_child(bs_inst)

	# 8. Interior: Tavern Fireplace & Warm Light
	var fire_omni: OmniLight3D = OmniLight3D.new()
	fire_omni.light_color = Color(1.0, 0.68, 0.25)
	fire_omni.light_energy = 1.3
	fire_omni.omni_range = 6.5
	fire_omni.shadow_enabled = false
	fire_omni.position = Vector3(3.2, 1.2, 0.0)
	tav_root.add_child(fire_omni)

	# 9. Interior: Dining Table with Benches
	var tav_table: BoxMesh = BoxMesh.new()
	tav_table.size = Vector3(1.8, 0.75, 0.9)
	var tt_inst: MeshInstance3D = MeshInstance3D.new()
	tt_inst.mesh = tav_table
	tt_inst.material_override = _wood_mat
	tt_inst.position = Vector3(1.2, 0.38, 1.2)
	tav_root.add_child(tt_inst)

	# 10. Chandelier
	var ch_omni: OmniLight3D = OmniLight3D.new()
	ch_omni.light_color = Color(1.0, 0.85, 0.55)
	ch_omni.light_energy = 1.1
	ch_omni.omni_range = 7.0
	ch_omni.shadow_enabled = false
	ch_omni.position = Vector3(0.0, 3.0, 0.0)
	tav_root.add_child(ch_omni)

# =============================================================================
# 4. VILLAGE SQUARE, GATHERING WELL & SIGNPOST
# =============================================================================
func _build_village_square_and_well() -> void:
	var sqr_x: float = 13.0
	var sqr_z: float = -2.5
	var ground_y: float = _terrain.get_height_at(sqr_x, sqr_z) if _terrain else 1.4

	var sqr_root: Node3D = Node3D.new()
	sqr_root.name = "VillageSquare"
	sqr_root.position = Vector3(sqr_x, ground_y, sqr_z)
	add_child(sqr_root)

	# Circular stone well
	var well_cyl: CylinderMesh = CylinderMesh.new()
	well_cyl.top_radius = 1.15
	well_cyl.bottom_radius = 1.2
	well_cyl.height = 0.95
	var well_inst: MeshInstance3D = MeshInstance3D.new()
	well_inst.mesh = well_cyl
	well_inst.material_override = _stone_mat
	well_inst.position = Vector3(0.0, 0.48, 0.0)
	sqr_root.add_child(well_inst)

	# Well timber roof
	var well_roof: PrismMesh = PrismMesh.new()
	well_roof.size = Vector3(2.4, 1.0, 2.4)
	var well_rf_inst: MeshInstance3D = MeshInstance3D.new()
	well_rf_inst.mesh = well_roof
	well_rf_inst.material_override = _wood_mat
	well_rf_inst.position = Vector3(0.0, 2.2, 0.0)
	sqr_root.add_child(well_rf_inst)

	_add_cylinder_collision(sqr_root, Vector3(0.0, 0.48, 0.0), 1.2, 0.95)

	# Village Signpost
	_signpost_node = Node3D.new()
	_signpost_node.name = "VillageSignpost"
	_signpost_node.position = Vector3(sqr_x - 2.5, ground_y, sqr_z + 1.8)
	add_child(_signpost_node)

	var post: MeshInstance3D = MeshInstance3D.new()
	var post_cyl: CylinderMesh = CylinderMesh.new()
	post_cyl.top_radius = 0.08
	post_cyl.bottom_radius = 0.09
	post_cyl.height = 2.2
	post.mesh = post_cyl
	post.material_override = _wood_mat
	post.position = Vector3(0.0, 1.1, 0.0)
	_signpost_node.add_child(post)

	# Sign arrows
	var board: MeshInstance3D = MeshInstance3D.new()
	var b_box: BoxMesh = BoxMesh.new()
	b_box.size = Vector3(1.1, 0.22, 0.06)
	board.mesh = b_box
	board.material_override = _wood_mat
	board.position = Vector3(0.45, 1.8, 0.0)
	_signpost_node.add_child(board)

# =============================================================================
# 5. STREET LANTERNS
# =============================================================================
func _build_street_lanterns() -> void:
	var lantern_coords: Array[Vector2] = [
		Vector2(11.5, 4.2),   # Pier road
		Vector2(14.8, -0.5),  # Cottage side
		Vector2(16.5, -4.0),  # Herbalist path
		Vector2(8.5, -3.5)    # Watchtower approach
	]

	for coord in lantern_coords:
		var lx: float = coord.x
		var lz: float = coord.y
		var ly: float = _terrain.get_height_at(lx, lz) if _terrain else 1.2

		var lamp: Node3D = Node3D.new()
		lamp.name = "StreetLantern"
		lamp.position = Vector3(lx, ly, lz)
		add_child(lamp)

		var pole: MeshInstance3D = MeshInstance3D.new()
		var p_cyl: CylinderMesh = CylinderMesh.new()
		p_cyl.top_radius = 0.06
		p_cyl.bottom_radius = 0.08
		p_cyl.height = 2.8
		pole.mesh = p_cyl
		pole.material_override = _wood_mat
		pole.position = Vector3(0.0, 1.4, 0.0)
		lamp.add_child(pole)

		var head: MeshInstance3D = MeshInstance3D.new()
		var h_box: BoxMesh = BoxMesh.new()
		h_box.size = Vector3(0.28, 0.38, 0.28)
		head.mesh = h_box
		head.material_override = _iron_mat
		head.position = Vector3(0.0, 2.7, 0.0)
		lamp.add_child(head)

		var lantern_light: OmniLight3D = OmniLight3D.new()
		lantern_light.light_color = Color(1.0, 0.85, 0.50)
		lantern_light.light_energy = 0.95
		lantern_light.omni_range = 6.5
		lantern_light.position = Vector3(0.0, 2.65, 0.0)
		lamp.add_child(lantern_light)
		_street_lantern_lights.append(lantern_light)

# =============================================================================
# 6. HARBOR MARKET STALL & VILLAGE COOKING HEARTH (BLOCK 44)
# =============================================================================
func _build_harbor_market_stall() -> void:
	var stall_x: float = 10.5
	var stall_z: float = 7.5
	var ground_y: float = _terrain.get_height_at(stall_x, stall_z) if _terrain else 0.85

	var stall_root: Node3D = Node3D.new()
	stall_root.name = "HarborMarketStall"
	stall_root.position = Vector3(stall_x, ground_y, stall_z)
	add_child(stall_root)

	# Timber Counter
	var counter: MeshInstance3D = MeshInstance3D.new()
	var c_box: BoxMesh = BoxMesh.new()
	c_box.size = Vector3(2.8, 0.95, 1.2)
	counter.mesh = c_box
	counter.material_override = _wood_mat
	counter.position = Vector3(0.0, 0.475, 0.0)
	stall_root.add_child(counter)
	_add_box_collision(stall_root, counter.position, c_box.size)

	# Awning Canopy
	var awning: MeshInstance3D = MeshInstance3D.new()
	var a_box: BoxMesh = BoxMesh.new()
	a_box.size = Vector3(3.2, 0.15, 2.0)
	awning.mesh = a_box
	awning.material_override = _roof_mat
	awning.position = Vector3(0.0, 2.4, 0.0)
	awning.rotation.x = deg_to_rad(12.0)
	stall_root.add_child(awning)

	# Cargo Fish Crates
	var crate: MeshInstance3D = MeshInstance3D.new()
	var cr_box: BoxMesh = BoxMesh.new()
	cr_box.size = Vector3(0.65, 0.55, 0.65)
	crate.mesh = cr_box
	crate.material_override = _wood_mat
	crate.position = Vector3(-1.6, 0.275, 0.2)
	stall_root.add_child(crate)
	_add_box_collision(stall_root, crate.position, cr_box.size)

func _build_cooking_hearth() -> void:
	var h_x: float = 2.5
	var h_z: float = 1.5
	var ground_y: float = _terrain.get_height_at(h_x, h_z) if _terrain else 1.2

	_cooking_hearth = Node3D.new()
	_cooking_hearth.name = "VillageCookingHearth"
	_cooking_hearth.position = Vector3(h_x, ground_y, h_z)
	add_child(_cooking_hearth)

	# Rustic circular stone ring
	var ring: MeshInstance3D = MeshInstance3D.new()
	var r_cyl: CylinderMesh = CylinderMesh.new()
	r_cyl.top_radius = 0.95
	r_cyl.bottom_radius = 1.1
	r_cyl.height = 0.4
	ring.mesh = r_cyl
	ring.material_override = _stone_mat
	ring.position = Vector3(0.0, 0.2, 0.0)
	_cooking_hearth.add_child(ring)

	# Cast iron cauldron hanging over fire
	var pot: MeshInstance3D = MeshInstance3D.new()
	var p_sph: SphereMesh = SphereMesh.new()
	p_sph.radius = 0.38
	p_sph.height = 0.5
	pot.mesh = p_sph
	pot.material_override = _iron_mat
	pot.position = Vector3(0.0, 0.65, 0.0)
	_cooking_hearth.add_child(pot)

	# Warm campfire light
	var fire_light: OmniLight3D = OmniLight3D.new()
	fire_light.name = "HearthLight"
	fire_light.light_color = Color(1.0, 0.65, 0.25)
	fire_light.light_energy = 1.8
	fire_light.omni_range = 7.0
	fire_light.position = Vector3(0.0, 0.45, 0.0)
	_cooking_hearth.add_child(fire_light)

	# Floating 3D label
	var lbl: Label3D = Label3D.new()
	lbl.name = "HearthLabel"
	lbl.text = "🍲 BẾP LỬA DÃ NGOẠI [E]"
	lbl.font_size = 20
	lbl.modulate = Color(1.0, 0.88, 0.45)
	lbl.outline_modulate = Color(0.15, 0.08, 0.02, 0.9)
	lbl.outline_size = 5
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0.0, 1.6, 0.0)
	_cooking_hearth.add_child(lbl)

	_add_cylinder_collision(_cooking_hearth, Vector3(0.0, 0.3, 0.0), 1.1, 0.6)

# =============================================================================
# 7. LIVING NPCS (ALISTAIR, ELOWEN, MILO)
# =============================================================================
func _spawn_living_npcs() -> void:
	# NPC 1: Harbor Master Alistair (Pier Entrance)
	var alistair_pos: Vector3 = Vector3(13.8, _terrain.get_height_at(13.8, 4.2) if _terrain else 0.85, 4.2)
	_npc_alistair = _create_stylized_npc("Alistair", "⚓ THUYỀN TRƯỞNG ALISTAIR", Color(0.18, 0.35, 0.65), alistair_pos)
	add_child(_npc_alistair)

	# NPC 2: Herbalist Elowen (Herb Garden)
	var elowen_pos: Vector3 = Vector3(17.2, _terrain.get_height_at(17.2, -4.8) if _terrain else 1.4, -4.8)
	_npc_elowen = _create_stylized_npc("Elowen", "🌿 NHÀ THẢO DƯỢC ELOWEN", Color(0.22, 0.55, 0.30), elowen_pos)
	add_child(_npc_elowen)

	# NPC 3: Merchant Milo (Market Stall)
	var milo_pos: Vector3 = Vector3(10.5, _terrain.get_height_at(10.5, 6.8) if _terrain else 0.85, 6.8)
	_npc_milo = _create_stylized_npc("Milo", "💰 THƯƠNG NHÂN MILO", Color(0.72, 0.45, 0.18), milo_pos)
	add_child(_npc_milo)

	# NPC 4: Blacksmith Goran (Village Forge)
	var goran_pos: Vector3 = Vector3(4.8, _terrain.get_height_at(4.8, -2.6) if _terrain else 1.2, -2.6)
	_npc_goran = _create_stylized_npc("Goran", "🔨 THỢ RÈN GORAN", Color(0.65, 0.22, 0.18), goran_pos)
	add_child(_npc_goran)

func _create_stylized_npc(id: String, display_name: String, cloak_color: Color, world_pos: Vector3) -> Node3D:
	var npc_root: Node3D = Node3D.new()
	npc_root.name = "NPC_" + id
	npc_root.position = world_pos

	# Capsule body
	var body: MeshInstance3D = MeshInstance3D.new()
	var cap: CapsuleMesh = CapsuleMesh.new()
	cap.radius = 0.32
	cap.height = 1.65
	body.mesh = cap
	var b_mat: StandardMaterial3D = StandardMaterial3D.new()
	b_mat.albedo_color = cloak_color
	b_mat.roughness = 0.65
	body.material_override = b_mat
	body.position = Vector3(0.0, 0.825, 0.0)
	npc_root.add_child(body)

	# Head
	var head: MeshInstance3D = MeshInstance3D.new()
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = 0.22
	sph.height = 0.44
	head.mesh = sph
	var h_mat: StandardMaterial3D = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.95, 0.85, 0.75) # Warm skin tone
	head.material_override = h_mat
	head.position = Vector3(0.0, 1.55, 0.0)
	npc_root.add_child(head)

	# Floating 3D overhead plate
	var plate: Label3D = Label3D.new()
	plate.name = "NamePlate"
	plate.text = display_name
	plate.font_size = 24
	plate.modulate = Color(1.0, 0.90, 0.55)
	plate.outline_modulate = Color(0.1, 0.1, 0.1, 0.9)
	plate.outline_size = 6
	plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plate.position = Vector3(0.0, 2.15, 0.0)
	npc_root.add_child(plate)

	# Interaction collision volume
	_add_cylinder_collision(npc_root, Vector3(0.0, 0.85, 0.0), 0.45, 1.7)

	return npc_root

func _process(delta: float) -> void:
	_anim_time += delta

	# Tail wagging on Buster the Dog
	if _dog_tail:
		if _buster_pet_time > 0.0:
			_buster_pet_time -= delta
			_dog_tail.rotation.y = sin(_anim_time * 22.0) * deg_to_rad(48.0)
			if _dog_buster and _buster_base_y > 0.0:
				_dog_buster.position.y = _buster_base_y + absf(sin(_anim_time * 14.0)) * 0.05
		else:
			_dog_tail.rotation.y = sin(_anim_time * 6.5) * deg_to_rad(28.0)
			if _dog_buster and _buster_base_y > 0.0:
				_dog_buster.position.y = _buster_base_y

	# Tail swishing on Mimi the Cat
	if _cat_tail:
		if _mimi_pet_time > 0.0:
			_mimi_pet_time -= delta
			_cat_tail.rotation.z = cos(_anim_time * 8.0) * deg_to_rad(25.0)
		else:
			_cat_tail.rotation.z = cos(_anim_time * 2.8) * deg_to_rad(18.0)

	# Chicken pecking motion
	for i in range(_chickens.size()):
		var ch: Node3D = _chickens[i]
		var h: Node3D = ch.get_node_or_null("ChickenHead") as Node3D
		if h:
			var peck = maxf(0.0, sin(_anim_time * 4.5 + float(i) * 1.7)) * deg_to_rad(-24.0)
			h.rotation.x = peck

	if not _player_node:
		return

	var p_pos: Vector3 = _player_node.global_position

	# NPCs smoothly turn to look toward player when within 6.0m
	if _npc_alistair:
		var dist_a: float = _npc_alistair.global_position.distance_to(p_pos)
		if dist_a < 6.0:
			var target_yaw_a: float = atan2(p_pos.x - _npc_alistair.global_position.x, p_pos.z - _npc_alistair.global_position.z)
			_npc_alistair.rotation.y = lerp_angle(_npc_alistair.rotation.y, target_yaw_a, delta * 4.0)

	if _npc_elowen:
		var dist_e: float = _npc_elowen.global_position.distance_to(p_pos)
		if dist_e < 6.0:
			var target_yaw_e: float = atan2(p_pos.x - _npc_elowen.global_position.x, p_pos.z - _npc_elowen.global_position.z)
			_npc_elowen.rotation.y = lerp_angle(_npc_elowen.rotation.y, target_yaw_e, delta * 4.0)

	if _npc_milo:
		var dist_m: float = _npc_milo.global_position.distance_to(p_pos)
		if dist_m < 6.0:
			var target_yaw_m: float = atan2(p_pos.x - _npc_milo.global_position.x, p_pos.z - _npc_milo.global_position.z)
			_npc_milo.rotation.y = lerp_angle(_npc_milo.rotation.y, target_yaw_m, delta * 4.0)

	if _npc_goran:
		var dist_g: float = _npc_goran.global_position.distance_to(p_pos)
		if dist_g < 6.0:
			var target_yaw_g: float = atan2(p_pos.x - _npc_goran.global_position.x, p_pos.z - _npc_goran.global_position.z)
			_npc_goran.rotation.y = lerp_angle(_npc_goran.rotation.y, target_yaw_g, delta * 4.0)

	# Training dummy wobble oscillation
	if _training_dummy and _dummy_wobble_time > 0.0:
		_dummy_wobble_time -= delta
		_training_dummy.rotation.z = sin(_dummy_wobble_time * 25.0) * deg_to_rad(14.0) * clampf(_dummy_wobble_time / 1.0, 0.0, 1.0)
	elif _training_dummy:
		_training_dummy.rotation.z = 0.0

	# Pier lighthouse stationary warm beacon (sweeping spotlight removed)

func strike_practice_dummy() -> void:
	_dummy_wobble_time = 1.0

func _build_blacksmith_forge() -> void:
	var fx: float = 3.8
	var fz: float = -3.2
	var fy: float = _terrain.get_height_at(fx, fz) if _terrain else 1.2

	_blacksmith_forge = Node3D.new()
	_blacksmith_forge.name = "BlacksmithForge"
	_blacksmith_forge.position = Vector3(fx, fy, fz)
	add_child(_blacksmith_forge)

	# Stone hearth base
	var h_mesh: BoxMesh = BoxMesh.new()
	h_mesh.size = Vector3(1.6, 0.85, 1.4)
	var hearth: MeshInstance3D = MeshInstance3D.new()
	hearth.mesh = h_mesh
	hearth.material_override = _stone_mat
	hearth.position = Vector3(0.0, 0.425, 0.0)
	_blacksmith_forge.add_child(hearth)

	# Glowing coal bed
	var coal: MeshInstance3D = MeshInstance3D.new()
	var c_box: BoxMesh = BoxMesh.new()
	c_box.size = Vector3(0.9, 0.15, 0.8)
	coal.mesh = c_box
	var c_mat: StandardMaterial3D = StandardMaterial3D.new()
	c_mat.albedo_color = Color(1.0, 0.45, 0.1)
	c_mat.emission_enabled = true
	c_mat.emission = Color(1.0, 0.35, 0.05)
	c_mat.emission_energy_multiplier = 2.2
	coal.material_override = c_mat
	coal.position = Vector3(0.0, 0.88, 0.0)
	_blacksmith_forge.add_child(coal)

	var forge_light: OmniLight3D = OmniLight3D.new()
	forge_light.light_color = Color(1.0, 0.55, 0.15)
	forge_light.light_energy = 1.4
	forge_light.omni_range = 4.5
	forge_light.position = Vector3(0.0, 1.1, 0.0)
	_blacksmith_forge.add_child(forge_light)

	# Heavy Iron Anvil
	var anvil: MeshInstance3D = MeshInstance3D.new()
	var a_box: BoxMesh = BoxMesh.new()
	a_box.size = Vector3(0.5, 0.65, 0.35)
	anvil.mesh = a_box
	anvil.material_override = _iron_mat
	anvil.position = Vector3(1.2, 0.325, 0.2)
	_blacksmith_forge.add_child(anvil)

	_add_box_collision(_blacksmith_forge, Vector3(0.0, 0.425, 0.0), Vector3(1.6, 0.85, 1.4))

func _build_practice_dummy() -> void:
	var dx: float = 4.5
	var dz: float = -1.5
	var dy: float = _terrain.get_height_at(dx, dz) if _terrain else 1.0

	_training_dummy = Node3D.new()
	_training_dummy.name = "PracticeDummy"
	_training_dummy.position = Vector3(dx, dy, dz)
	add_child(_training_dummy)

	# Central wooden post
	var post: MeshInstance3D = MeshInstance3D.new()
	var p_cyl: CylinderMesh = CylinderMesh.new()
	p_cyl.top_radius = 0.14
	p_cyl.bottom_radius = 0.16
	p_cyl.height = 1.8
	post.mesh = p_cyl
	post.material_override = _wood_mat
	post.position = Vector3(0.0, 0.9, 0.0)
	_training_dummy.add_child(post)

	# Crossarm timber
	var arm: MeshInstance3D = MeshInstance3D.new()
	var a_box: BoxMesh = BoxMesh.new()
	a_box.size = Vector3(1.1, 0.12, 0.12)
	arm.mesh = a_box
	arm.material_override = _wood_mat
	arm.position = Vector3(0.0, 1.25, 0.0)
	_training_dummy.add_child(arm)

	# Straw sack torso
	var torso: MeshInstance3D = MeshInstance3D.new()
	var t_cap: CapsuleMesh = CapsuleMesh.new()
	t_cap.radius = 0.28
	t_cap.height = 0.9
	torso.mesh = t_cap
	var t_mat: StandardMaterial3D = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.78, 0.70, 0.45) # Straw yellow
	t_mat.roughness = 0.95
	torso.material_override = t_mat
	torso.position = Vector3(0.0, 1.1, 0.0)
	_training_dummy.add_child(torso)

	# Nameplate
	var lbl: Label3D = Label3D.new()
	lbl.text = "🎯 BÙ NHÌN TẬP LUYỆN"
	lbl.font_size = 20
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0.0, 2.05, 0.0)
	lbl.modulate = Color(1.0, 0.92, 0.65)
	_training_dummy.add_child(lbl)

	_add_cylinder_collision(_training_dummy, Vector3(0.0, 0.9, 0.0), 0.35, 1.8)

# =============================================================================
# COBBLESTONE STREET NETWORK & PATHWAYS
# =============================================================================
func _build_cobblestone_street_network() -> void:
	var roads_root: Node3D = Node3D.new()
	roads_root.name = "CobblestoneStreets"
	add_child(roads_root)

	var road_segments: Array[Dictionary] = [
		{"from": Vector2(0.0, 0.0), "to": Vector2(13.0, -2.5)},    # Pier to Village Square
		{"from": Vector2(13.0, -2.5), "to": Vector2(10.5, 1.2)},   # Square to Harbor Cottage
		{"from": Vector2(13.0, -2.5), "to": Vector2(14.5, 7.2)},   # Square to Sea Wind Tavern
		{"from": Vector2(13.0, -2.5), "to": Vector2(18.5, -5.5)},  # Square to Herbalist Lodge
		{"from": Vector2(13.0, -2.5), "to": Vector2(3.8, -3.2)},   # Square to Blacksmith Forge
		{"from": Vector2(3.8, -3.2), "to": Vector2(6.5, -6.5)},    # Forge to Watchtower
	]

	for seg in road_segments:
		var p1: Vector2 = seg["from"]
		var p2: Vector2 = seg["to"]
		var dist: float = p1.distance_to(p2)
		var steps: int = maxi(2, int(dist / 2.2))
		for s in range(steps + 1):
			var t: float = float(s) / float(steps)
			var cur_p: Vector2 = p1.lerp(p2, t)
			var gy: float = _terrain.get_height_at(cur_p.x, cur_p.y) if _terrain else 1.2
			var paver: MeshInstance3D = MeshInstance3D.new()
			var p_box: BoxMesh = BoxMesh.new()
			p_box.size = Vector3(2.2, 0.08, 1.8)
			paver.mesh = p_box
			paver.material_override = _road_mat
			paver.position = Vector3(cur_p.x, gy + 0.03, cur_p.y)
			var angle: float = (p2 - p1).angle()
			paver.rotation.y = -angle
			roads_root.add_child(paver)

func _build_lighthouse_beam() -> void:
	var twr_x: float = 6.5
	var twr_z: float = -6.5
	var ground_y: float = _terrain.get_height_at(twr_x, twr_z) if _terrain else 1.8

	_lighthouse_beam = Node3D.new()
	_lighthouse_beam.name = "LighthouseRevolvingBeam"
	_lighthouse_beam.position = Vector3(twr_x, ground_y + 8.8, twr_z)
	add_child(_lighthouse_beam)

	# Stationary warm beacon lantern (Eliminated sweeping spotlight & 90m cone)
	var lantern_omni: OmniLight3D = OmniLight3D.new()
	lantern_omni.name = "BeaconLanternLight"
	lantern_omni.light_color = Color(1.0, 0.85, 0.52)
	lantern_omni.light_energy = 1.4
	lantern_omni.omni_range = 16.0
	lantern_omni.shadow_enabled = false
	_lighthouse_beam.add_child(lantern_omni)

	# Decorative lantern brass housing
	var cage: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.35
	cyl.height = 0.70
	cage.mesh = cyl
	cage.material_override = _iron_mat
	_lighthouse_beam.add_child(cage)

func get_nearby_interactable(player_pos: Vector3) -> Dictionary:
	# Checks for closest NPC, hearth, forge, dummy, or village signpost within interaction range
	var closest_interactable: Dictionary = {}
	var min_dist: float = 999.0

	var candidates: Array[Dictionary] = [
		{"node": _npc_alistair, "radius": 2.8, "data": {"type": "NPC", "id": "Alistair", "prompt": "[E] Nói chuyện với Thuyền trưởng Alistair"}},
		{"node": _npc_elowen, "radius": 2.8, "data": {"type": "NPC", "id": "Elowen", "prompt": "[E] Nói chuyện với Nhà thảo dược Elowen"}},
		{"node": _npc_milo, "radius": 2.8, "data": {"type": "NPC", "id": "Milo", "prompt": "[E] Giao thương với Thương nhân Milo"}},
		{"node": _npc_goran, "radius": 2.8, "data": {"type": "NPC", "id": "Goran", "prompt": "[E] Trò chuyện với Thợ rèn Goran"}},
		{"node": _training_dummy, "radius": 2.8, "data": {"type": "TRAINING", "id": "PracticeDummy", "prompt": "[E] Tấn công bù nhìn tập luyện"}},
		{"node": _blacksmith_forge, "radius": 2.8, "data": {"type": "FORGE", "id": "BlacksmithForge", "prompt": "[E] Sử dụng Đe rèn Tiền Đồn"}},
		{"node": _cooking_hearth, "radius": 2.8, "data": {"type": "COOKING", "id": "VillageHearth", "prompt": "[E] Nấu ăn tại Bếp Lửa Dã Ngoại"}},
		{"node": _dog_buster, "radius": 2.5, "data": {"type": "ANIMAL", "id": "Buster", "prompt": "[E] Vuốt ve Buster (Tavern Hound)"}},
		{"node": _cat_mimi, "radius": 2.5, "data": {"type": "ANIMAL", "id": "Mimi", "prompt": "[E] Vuốt ve Mimi (Garden Cat)"}},
		{"node": _signpost_node, "radius": 2.5, "data": {"type": "SIGNPOST", "id": "HavenSign", "prompt": "[E] Đọc biển chỉ dẫn Tiền Đồn Haven"}},
	]

	for c in candidates:
		var n: Node3D = c["node"] as Node3D
		if n:
			var pos: Vector3 = n.global_position if n.is_inside_tree() else n.position
			var d: float = pos.distance_to(player_pos)
			if d <= (c["radius"] as float) and d < min_dist:
				min_dist = d
				closest_interactable = c["data"] as Dictionary

	return closest_interactable

func set_night_lighting(is_night: bool) -> void:
	for light in _street_lantern_lights:
		if is_instance_valid(light):
			light.visible = is_night

func _add_box_collision(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var sb: StaticBody3D = StaticBody3D.new()
	sb.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = pos
	sb.add_child(cs)
	parent.add_child(sb)

func _add_cylinder_collision(parent: Node3D, pos: Vector3, radius: float, height: float) -> void:
	var sb: StaticBody3D = StaticBody3D.new()
	sb.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	cs.shape = cyl
	cs.position = pos
	sb.add_child(cs)
	parent.add_child(sb)

func _get_ground_y(x: float, z: float, default_y: float = 1.2) -> float:
	if _terrain:
		return _terrain.get_height_at(x, z)
	return default_y

func _spawn_village_animals() -> void:
	var animals_root: Node3D = Node3D.new()
	animals_root.name = "HavenVillageAnimals"
	add_child(animals_root)

	# 1. Buster the Tavern Hound (faithful retriever resting near Sea Wind Tavern)
	var dog_x: float = 12.8
	var dog_z: float = 9.8
	var dog_y: float = _get_ground_y(dog_x, dog_z) + 0.35 # On tavern wooden deck

	_buster_base_y = dog_y

	_dog_buster = Node3D.new()
	_dog_buster.name = "DogBuster"
	_dog_buster.position = Vector3(dog_x, dog_y, dog_z)
	_dog_buster.rotation.y = deg_to_rad(-45.0)
	animals_root.add_child(_dog_buster)

	# Buster Love Sparkle Particles
	_buster_particles = GPUParticles3D.new()
	_buster_particles.name = "BusterHearts"
	_buster_particles.amount = 12
	_buster_particles.lifetime = 0.8
	_buster_particles.emitting = false
	_buster_particles.one_shot = true
	_buster_particles.position = Vector3(0.0, 0.45, 0.15)

	var p_proc = ParticleProcessMaterial.new()
	p_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	p_proc.emission_sphere_radius = 0.25
	p_proc.direction = Vector3(0.0, 1.0, 0.0)
	p_proc.initial_velocity_min = 0.8
	p_proc.initial_velocity_max = 1.6
	p_proc.gravity = Vector3(0.0, 0.4, 0.0)
	p_proc.color = Color(1.0, 0.35, 0.55, 0.85)
	_buster_particles.process_material = p_proc

	var heart_mesh = SphereMesh.new()
	heart_mesh.radius = 0.04
	heart_mesh.height = 0.08
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(1.0, 0.40, 0.60)
	h_mat.emission_enabled = true
	h_mat.emission = Color(1.0, 0.30, 0.50)
	h_mat.emission_energy_multiplier = 1.8
	heart_mesh.material = h_mat
	_buster_particles.draw_pass_1 = heart_mesh
	_dog_buster.add_child(_buster_particles)

	var dog_mat: StandardMaterial3D = StandardMaterial3D.new()
	dog_mat.albedo_color = Color(0.74, 0.50, 0.28) # Warm golden retriever fur
	dog_mat.roughness = 0.85

	var dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.15, 0.12, 0.10)

	var red_collar: StandardMaterial3D = StandardMaterial3D.new()
	red_collar.albedo_color = Color(0.85, 0.15, 0.15)

	# Torso
	var body: MeshInstance3D = MeshInstance3D.new()
	var cap: CapsuleMesh = CapsuleMesh.new()
	cap.radius = 0.14
	cap.height = 0.44
	body.mesh = cap
	body.material_override = dog_mat
	body.rotation.x = deg_to_rad(90.0)
	body.position = Vector3(0.0, 0.14, 0.0)
	_dog_buster.add_child(body)

	# Head
	var head: MeshInstance3D = MeshInstance3D.new()
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = 0.11
	sph.height = 0.22
	head.mesh = sph
	head.material_override = dog_mat
	head.position = Vector3(0.0, 0.26, 0.20)
	_dog_buster.add_child(head)

	# Snout
	var snout: MeshInstance3D = MeshInstance3D.new()
	var scyl: CylinderMesh = CylinderMesh.new()
	scyl.top_radius = 0.04
	scyl.bottom_radius = 0.055
	scyl.height = 0.09
	snout.mesh = scyl
	snout.material_override = dog_mat
	snout.position = Vector3(0.0, 0.24, 0.31)
	snout.rotation.x = deg_to_rad(90.0)
	_dog_buster.add_child(snout)

	# Nose tip
	var nose: MeshInstance3D = MeshInstance3D.new()
	var nsph: SphereMesh = SphereMesh.new()
	nsph.radius = 0.02
	nsph.height = 0.04
	nose.mesh = nsph
	nose.material_override = dark_mat
	nose.position = Vector3(0.0, 0.25, 0.36)
	_dog_buster.add_child(nose)

	# Collar
	var collar: MeshInstance3D = MeshInstance3D.new()
	var tcyl: CylinderMesh = CylinderMesh.new()
	tcyl.top_radius = 0.12
	tcyl.bottom_radius = 0.12
	tcyl.height = 0.03
	collar.mesh = tcyl
	collar.material_override = red_collar
	collar.position = Vector3(0.0, 0.21, 0.15)
	collar.rotation.x = deg_to_rad(30.0)
	_dog_buster.add_child(collar)

	# Floppy Ears (L & R)
	for side in [-1.0, 1.0]:
		var ear: MeshInstance3D = MeshInstance3D.new()
		var ecap: CapsuleMesh = CapsuleMesh.new()
		ecap.radius = 0.035
		ecap.height = 0.11
		ear.mesh = ecap
		ear.material_override = dark_mat
		ear.position = Vector3(side * 0.10, 0.25, 0.18)
		ear.rotation.z = deg_to_rad(side * 35.0)
		_dog_buster.add_child(ear)

	# Tail
	_dog_tail = Node3D.new()
	_dog_tail.name = "BusterTail"
	_dog_tail.position = Vector3(0.0, 0.18, -0.20)
	_dog_buster.add_child(_dog_tail)

	var tail_mesh: MeshInstance3D = MeshInstance3D.new()
	var tcyl2: CylinderMesh = CylinderMesh.new()
	tcyl2.top_radius = 0.015
	tcyl2.bottom_radius = 0.035
	tcyl2.height = 0.24
	tail_mesh.mesh = tcyl2
	tail_mesh.material_override = dog_mat
	tail_mesh.position = Vector3(0.0, 0.08, -0.06)
	tail_mesh.rotation.x = deg_to_rad(-45.0)
	_dog_tail.add_child(tail_mesh)

	# 2. Mimi the Calico Cat (perched gracefully on the herbalist stone planter)
	var cat_x: float = 19.2
	var cat_z: float = -4.2
	var cat_y: float = _get_ground_y(cat_x, cat_z) + 0.62

	_cat_mimi = Node3D.new()
	_cat_mimi.name = "CatMimi"
	_cat_mimi.position = Vector3(cat_x, cat_y, cat_z)
	_cat_mimi.rotation.y = deg_to_rad(-120.0)
	animals_root.add_child(_cat_mimi)

	# Mimi Serenity Particles
	_mimi_particles = GPUParticles3D.new()
	_mimi_particles.name = "MimiHearts"
	_mimi_particles.amount = 10
	_mimi_particles.lifetime = 0.85
	_mimi_particles.emitting = false
	_mimi_particles.one_shot = true
	_mimi_particles.position = Vector3(0.0, 0.35, 0.08)

	var m_proc = ParticleProcessMaterial.new()
	m_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m_proc.emission_sphere_radius = 0.20
	m_proc.direction = Vector3(0.0, 1.0, 0.0)
	m_proc.initial_velocity_min = 0.6
	m_proc.initial_velocity_max = 1.3
	m_proc.gravity = Vector3(0.0, 0.3, 0.0)
	m_proc.color = Color(1.0, 0.75, 0.45, 0.85)
	_mimi_particles.process_material = m_proc

	var m_mesh = SphereMesh.new()
	m_mesh.radius = 0.035
	m_mesh.height = 0.07
	var m_mat = StandardMaterial3D.new()
	m_mat.albedo_color = Color(1.0, 0.70, 0.40)
	m_mat.emission_enabled = true
	m_mat.emission = Color(1.0, 0.65, 0.30)
	m_mat.emission_energy_multiplier = 1.6
	m_mesh.material = m_mat
	_mimi_particles.draw_pass_1 = m_mesh
	_cat_mimi.add_child(_mimi_particles)

	var cat_mat: StandardMaterial3D = StandardMaterial3D.new()
	cat_mat.albedo_color = Color(0.95, 0.92, 0.88) # Calico base cream

	var ginger_mat: StandardMaterial3D = StandardMaterial3D.new()
	ginger_mat.albedo_color = Color(0.88, 0.48, 0.18) # Ginger patch

	# Cat Loaf Body
	var c_body: MeshInstance3D = MeshInstance3D.new()
	var c_cap: CapsuleMesh = CapsuleMesh.new()
	c_cap.radius = 0.09
	c_cap.height = 0.28
	c_body.mesh = c_cap
	c_body.material_override = cat_mat
	c_body.rotation.x = deg_to_rad(90.0)
	c_body.position = Vector3(0.0, 0.09, 0.0)
	_cat_mimi.add_child(c_body)

	# Cat Head
	var c_head: MeshInstance3D = MeshInstance3D.new()
	var c_sph: SphereMesh = SphereMesh.new()
	c_sph.radius = 0.075
	c_sph.height = 0.15
	c_head.mesh = c_sph
	c_head.material_override = ginger_mat
	c_head.position = Vector3(0.0, 0.17, 0.13)
	_cat_mimi.add_child(c_head)

	# Cat Ears (Pointed prisms/cones)
	for side in [-1.0, 1.0]:
		var c_ear: MeshInstance3D = MeshInstance3D.new()
		var c_cone: CylinderMesh = CylinderMesh.new()
		c_cone.top_radius = 0.005
		c_cone.bottom_radius = 0.035
		c_cone.height = 0.06
		c_ear.mesh = c_cone
		c_ear.material_override = ginger_mat
		c_ear.position = Vector3(side * 0.048, 0.24, 0.12)
		c_ear.rotation.z = deg_to_rad(side * -18.0)
		_cat_mimi.add_child(c_ear)

	# Cat Tail (curled)
	_cat_tail = Node3D.new()
	_cat_tail.name = "MimiTail"
	_cat_tail.position = Vector3(0.0, 0.07, -0.12)
	_cat_mimi.add_child(_cat_tail)

	var ct_mesh: MeshInstance3D = MeshInstance3D.new()
	var ct_cyl: CylinderMesh = CylinderMesh.new()
	ct_cyl.top_radius = 0.012
	ct_cyl.bottom_radius = 0.022
	ct_cyl.height = 0.20
	ct_mesh.mesh = ct_cyl
	ct_mesh.material_override = ginger_mat
	ct_mesh.position = Vector3(0.05, 0.05, -0.06)
	ct_mesh.rotation.z = deg_to_rad(45.0)
	_cat_tail.add_child(ct_mesh)

	# 3. Market Chickens
	_chickens.clear()
	var chicken_spots = [Vector2(14.2, 3.8), Vector2(11.8, 5.5)]
	var chick_mat: StandardMaterial3D = StandardMaterial3D.new()
	chick_mat.albedo_color = Color(0.96, 0.94, 0.88)
	var beak_mat: StandardMaterial3D = StandardMaterial3D.new()
	beak_mat.albedo_color = Color(0.98, 0.75, 0.12)

	for spot in chicken_spots:
		var c_node: Node3D = Node3D.new()
		c_node.position = Vector3(spot.x, _get_ground_y(spot.x, spot.y) + 0.12, spot.y)
		animals_root.add_child(c_node)
		_chickens.append(c_node)

		var c_b: MeshInstance3D = MeshInstance3D.new()
		var c_sph2: SphereMesh = SphereMesh.new()
		c_sph2.radius = 0.08
		c_sph2.height = 0.16
		c_b.mesh = c_sph2
		c_b.material_override = chick_mat
		c_b.scale = Vector3(0.8, 1.0, 1.2)
		c_node.add_child(c_b)

		var c_h: MeshInstance3D = MeshInstance3D.new()
		c_h.name = "ChickenHead"
		var c_hsph: SphereMesh = SphereMesh.new()
		c_hsph.radius = 0.045
		c_hsph.height = 0.09
		c_h.mesh = c_hsph
		c_h.material_override = chick_mat
		c_h.position = Vector3(0.0, 0.08, 0.07)
		c_node.add_child(c_h)

		var c_bk: MeshInstance3D = MeshInstance3D.new()
		var c_cone2: CylinderMesh = CylinderMesh.new()
		c_cone2.top_radius = 0.002
		c_cone2.bottom_radius = 0.016
		c_cone2.height = 0.035
		c_bk.mesh = c_cone2
		c_bk.material_override = beak_mat
		c_bk.position = Vector3(0.0, 0.08, 0.12)
		c_bk.rotation.x = deg_to_rad(90.0)
		c_node.add_child(c_bk)

	# Audio emitter for village animals
	_animal_audio = AudioStreamPlayer3D.new()
	_animal_audio.name = "VillageAnimalAudio"
	_animal_audio.unit_size = 4.0
	_animal_audio.max_distance = 25.0
	_animal_audio.position = Vector3(14.0, 1.2, 5.0)
	animals_root.add_child(_animal_audio)

	if _dog_bark_wav == null:
		_dog_bark_wav = _generate_dog_bark_wav()
		_cat_purr_wav = _generate_cat_purr_wav()

func pet_buster() -> Dictionary:
	_buster_pet_time = 2.5
	if _buster_particles:
		_buster_particles.restart()
	_play_animal_sound(_dog_bark_wav, -11.0)
	return {
		"id": "buster",
		"name": "Buster",
		"message": "Buster vẫy đuôi mừng rỡ và sủa vang vui vẻ!",
		"buff": "buster_friendship",
		"exp": 60
	}

func pet_mimi() -> Dictionary:
	_mimi_pet_time = 2.5
	if _mimi_particles:
		_mimi_particles.restart()
	_play_animal_sound(_cat_purr_wav, -12.0)
	return {
		"id": "mimi",
		"name": "Mimi",
		"message": "Mimi gừ gừ êm dịu và cuộn tròn hạnh phúc!",
		"buff": "mimi_serenity",
		"exp": 60
	}

func _play_animal_sound(wav: AudioStreamWAV, vol_db: float) -> void:
	if not _animal_audio or wav == null or not is_inside_tree():
		return
	_animal_audio.stream = wav
	_animal_audio.volume_db = vol_db
	_animal_audio.pitch_scale = randf_range(0.96, 1.05)
	_animal_audio.play()

static func _generate_dog_bark_wav(duration: float = 0.28, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI) * exp(-5.0 * (t / duration))
		var freq: float = lerpf(380.0, 220.0, t / duration)
		var tone: float = sin(t * freq * TAU) * 0.7 + sin(t * freq * 2.0 * TAU) * 0.3
		var val_16: int = int(clampf(tone * env * 0.5, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_cat_purr_wav(duration: float = 0.85, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI) * 0.45
		var purr_freq: float = 26.0 + sin(t * 8.0 * TAU) * 3.0
		var motor: float = sin(t * purr_freq * TAU)
		var tone: float = sin(t * 135.0 * TAU) * 0.35 + motor * 0.65
		var val_16: int = int(clampf(tone * env * 0.45, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

func _build_harbor_fishery_warehouse() -> void:
	var wh_root: Node3D = Node3D.new()
	wh_root.name = "HarborFisheryWarehouse"
	add_child(wh_root)

	var ground_y: float = _get_ground_y(-6.5, 14.5, 1.2)
	var pos: Vector3 = Vector3(-6.5, ground_y, 14.5)

	# Stone foundation & timber walls
	var wh_mesh: BoxMesh = BoxMesh.new()
	wh_mesh.size = Vector3(6.8, 3.8, 5.2)
	var wh_mi: MeshInstance3D = MeshInstance3D.new()
	wh_mi.mesh = wh_mesh
	wh_mi.material_override = _wood_mat
	wh_mi.position = pos + Vector3(0.0, 1.9, 0.0)
	wh_root.add_child(wh_mi)

	# Pitched slate shingle roof
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = Vector3(5.6, 2.2, 7.4)
	var roof_mi: MeshInstance3D = MeshInstance3D.new()
	roof_mi.mesh = roof_mesh
	roof_mi.material_override = _roof_mat
	roof_mi.position = pos + Vector3(0.0, 3.8 + 1.1, 0.0)
	roof_mi.rotation.y = deg_to_rad(90.0)
	wh_root.add_child(roof_mi)

	# Overhanging cargo hoist beam
	var beam_mesh: BoxMesh = BoxMesh.new()
	beam_mesh.size = Vector3(0.22, 0.22, 2.4)
	var beam_mi: MeshInstance3D = MeshInstance3D.new()
	beam_mi.mesh = beam_mesh
	beam_mi.material_override = _wood_mat
	beam_mi.position = pos + Vector3(0.0, 4.2, 3.2)
	wh_root.add_child(beam_mi)

	# Stored fish barrels outside
	for bx in [-2.2, -1.2, 1.5]:
		var barrel: CylinderMesh = CylinderMesh.new()
		barrel.top_radius = 0.38
		barrel.bottom_radius = 0.42
		barrel.height = 0.95
		var b_mi: MeshInstance3D = MeshInstance3D.new()
		b_mi.mesh = barrel
		b_mi.material_override = _wood_mat
		b_mi.position = pos + Vector3(bx, 0.48, 2.9)
		wh_root.add_child(b_mi)

	# Collision
	var sb: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(7.0, 4.0, 5.4)
	col.shape = box
	sb.position = pos + Vector3(0.0, 2.0, 0.0)
	sb.add_child(col)
	wh_root.add_child(sb)

func _build_hillside_suburban_cottage() -> void:
	var cot_root: Node3D = Node3D.new()
	cot_root.name = "HillsideSuburbanCottage"
	add_child(cot_root)

	var ground_y: float = _get_ground_y(26.0, 16.0, 4.8)
	var pos: Vector3 = Vector3(26.0, ground_y, 16.0)

	# 2-story half-timber cottage
	var house_mesh: BoxMesh = BoxMesh.new()
	house_mesh.size = Vector3(5.8, 4.6, 5.2)
	var h_mi: MeshInstance3D = MeshInstance3D.new()
	h_mi.mesh = house_mesh
	h_mi.material_override = _wood_mat
	h_mi.position = pos + Vector3(0.0, 2.3, 0.0)
	cot_root.add_child(h_mi)

	# Terracotta hip roof
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = Vector3(5.6, 2.4, 6.4)
	var r_mi: MeshInstance3D = MeshInstance3D.new()
	r_mi.mesh = roof_mesh
	r_mi.material_override = _roof_mat
	r_mi.position = pos + Vector3(0.0, 4.6 + 1.2, 0.0)
	r_mi.rotation.y = deg_to_rad(90.0)
	cot_root.add_child(r_mi)

	# Stone hearth chimney
	var chim_mesh: BoxMesh = BoxMesh.new()
	chim_mesh.size = Vector3(0.9, 6.2, 0.9)
	var c_mi: MeshInstance3D = MeshInstance3D.new()
	c_mi.mesh = chim_mesh
	c_mi.material_override = _stone_mat
	c_mi.position = pos + Vector3(2.5, 3.1, 0.0)
	cot_root.add_child(c_mi)

	# Wooden flower planter on sill
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(1.8, 0.35, 0.45)
	var b_mi: MeshInstance3D = MeshInstance3D.new()
	b_mi.mesh = box_mesh
	b_mi.material_override = _wood_mat
	b_mi.position = pos + Vector3(-0.5, 2.2, 2.7)
	cot_root.add_child(b_mi)

	# Collision
	var sb: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(6.0, 4.8, 5.4)
	col.shape = box
	sb.position = pos + Vector3(0.0, 2.4, 0.0)
	sb.add_child(col)
	cot_root.add_child(sb)

func _apply_culling_and_shadow_optimizations() -> void:
	for child in find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = child as MeshInstance3D
		if not mi:
			continue
		var mname: String = mi.name.to_lower()
		var p_name: String = mi.get_parent().name.to_lower() if mi.get_parent() else ""
		
		# Major architecture retains longer visibility and shadow casting
		var is_major_building: bool = ("watchtower" in p_name or "cottage" in p_name or "tavern" in p_name or "warehouse" in p_name or "havenwatchtower" in mname)
		if is_major_building:
			mi.visibility_range_end = 220.0
			mi.visibility_range_end_margin = 25.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		else:
			# Small clutter, street lanterns, barrels, crates, animals, dummy, well roof, fences
			mi.visibility_range_end = 85.0
			mi.visibility_range_end_margin = 15.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


