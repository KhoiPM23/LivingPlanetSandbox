class_name AncientCastleCitadel
extends Node3D

## Living Planet Sandbox — Block 39 Ancient Ruined Castle Citadel & Spectral Warden
## Features:
## 1. Ancient Stone Gatehouse with twin bastion towers and iron portcullis
## 2. Ruined Citadel Keep with collapsed masonry, battlements, and torch braziers
## 3. Central Runic Relic Dais with cyan ethereal glow and interaction feedback
## 4. Spectral Warden NPC: Sir Raymond with look-at head tracking and 3D nameplate
## 5. Optimized for Intel Iris Xe: shared materials, static trimesh/box collisions

signal castle_relic_activated()
signal brazier_lit(brazier_id: String)
signal sarcophagus_opened(seal_id: String)
signal interaction_requested(target_id: String)

var _terrain: IslandTerrain = null
var _player_node: Node3D = null

# Materials
var _stone_wall_mat: StandardMaterial3D = null
var _stone_flag_mat: StandardMaterial3D = null
var _iron_mat: StandardMaterial3D = null
var _relic_mat: StandardMaterial3D = null
var _spectral_mat: StandardMaterial3D = null

# Nodes
var _npc_raymond: Node3D = null
var _relic_node: Node3D = null
var _relic_light: OmniLight3D = null
var _relic_active: bool = false

# Catacombs & Dungeon state
var _catacombs_root: Node3D = null
var _brazier_alpha_node: Node3D = null
var _brazier_beta_node: Node3D = null
var _brazier_alpha_light: OmniLight3D = null
var _brazier_beta_light: OmniLight3D = null
var _brazier_alpha_lit: bool = false
var _brazier_beta_lit: bool = false
var _sarcophagus_node: Node3D = null
var _sarcophagus_label: Label3D = null
var _sarcophagus_looted: bool = false

# Coordinates on northern bluff
var citadel_base_pos: Vector3 = Vector3(-28.0, 0.0, -22.0)

func setup(terrain: IslandTerrain, player: Node3D = null) -> void:
	_terrain = terrain
	_player_node = player
	_init_materials()

	var ground_y: float = _terrain.get_height_at(citadel_base_pos.x, citadel_base_pos.z) if _terrain else 7.5
	citadel_base_pos.y = ground_y
	position = citadel_base_pos

	_build_gatehouse_and_walls()
	_build_ruined_keep()
	_build_inner_courtyard_and_relic()
	_build_catacombs_crypt()
	_spawn_spectral_warden()

func _init_materials() -> void:
	# Weathered ancient fortress granite
	_stone_wall_mat = StandardMaterial3D.new()
	_stone_wall_mat.albedo_color = Color(0.35, 0.36, 0.38)
	_stone_wall_mat.roughness = 0.92

	# Flagstone pavers
	_stone_flag_mat = StandardMaterial3D.new()
	_stone_flag_mat.albedo_color = Color(0.28, 0.30, 0.32)
	_stone_flag_mat.roughness = 0.88

	# Wrought iron
	_iron_mat = StandardMaterial3D.new()
	_iron_mat.albedo_color = Color(0.12, 0.12, 0.14)
	_iron_mat.metallic = 0.88
	_iron_mat.roughness = 0.40

	# Cyan luminescent ancient relic stone
	_relic_mat = StandardMaterial3D.new()
	_relic_mat.albedo_color = Color(0.15, 0.80, 0.90)
	_relic_mat.emission_enabled = true
	_relic_mat.emission = Color(0.20, 0.85, 0.95)
	_relic_mat.emission_energy_multiplier = 1.6

	# Spectral Warden ethereal material
	_spectral_mat = StandardMaterial3D.new()
	_spectral_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_spectral_mat.albedo_color = Color(0.45, 0.75, 0.95, 0.78)
	_spectral_mat.emission_enabled = true
	_spectral_mat.emission = Color(0.30, 0.65, 0.90)
	_spectral_mat.emission_energy_multiplier = 0.75
	_spectral_mat.roughness = 0.35

func _build_gatehouse_and_walls() -> void:
	var gate_root: Node3D = Node3D.new()
	gate_root.name = "CastleGatehouse"
	add_child(gate_root)

	# Left Bastion Tower
	_build_bastion_tower(gate_root, Vector3(-4.5, 0.0, 0.0), 2.2, 8.5)
	# Right Bastion Tower
	_build_bastion_tower(gate_root, Vector3(4.5, 0.0, 0.0), 2.2, 8.5)

	# Archway Header Lintels
	var arch: MeshInstance3D = MeshInstance3D.new()
	var arch_box: BoxMesh = BoxMesh.new()
	arch_box.size = Vector3(5.8, 1.8, 2.2)
	arch.mesh = arch_box
	arch.material_override = _stone_wall_mat
	arch.position = Vector3(0.0, 6.2, 0.0)
	gate_root.add_child(arch)
	_add_box_collision(gate_root, arch.position, arch_box.size)

	# Iron Portcullis Bars
	var portcullis: MeshInstance3D = MeshInstance3D.new()
	var port_box: BoxMesh = BoxMesh.new()
	port_box.size = Vector3(4.2, 4.8, 0.15)
	portcullis.mesh = port_box
	portcullis.material_override = _iron_mat
	portcullis.position = Vector3(0.0, 3.8, 0.0) # Raised portcullis allowing player to walk through
	gate_root.add_child(portcullis)

	# Flanking Rampart Walls
	_build_rampart_wall(gate_root, Vector3(-10.5, 0.0, -3.5), deg_to_rad(30.0), 8.0)
	_build_rampart_wall(gate_root, Vector3(10.5, 0.0, -3.5), deg_to_rad(-30.0), 8.0)

func _build_bastion_tower(parent: Node3D, pos: Vector3, radius: float, height: float) -> void:
	var tower: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius * 0.95
	cyl.bottom_radius = radius
	cyl.height = height
	tower.mesh = cyl
	tower.material_override = _stone_wall_mat
	tower.position = pos + Vector3(0.0, height * 0.5, 0.0)
	parent.add_child(tower)

	# Crenellation parapet on top
	var parapet: MeshInstance3D = MeshInstance3D.new()
	var p_cyl: CylinderMesh = CylinderMesh.new()
	p_cyl.top_radius = radius * 1.12
	p_cyl.bottom_radius = radius * 1.05
	p_cyl.height = 1.1
	parapet.mesh = p_cyl
	parapet.material_override = _stone_wall_mat
	parapet.position = pos + Vector3(0.0, height + 0.55, 0.0)
	parent.add_child(parapet)

	_add_cylinder_collision(parent, tower.position, radius, height)

func _build_rampart_wall(parent: Node3D, pos: Vector3, yaw: float, length: float) -> void:
	var wall: MeshInstance3D = MeshInstance3D.new()
	var w_box: BoxMesh = BoxMesh.new()
	w_box.size = Vector3(length, 5.5, 1.8)
	wall.mesh = w_box
	wall.material_override = _stone_wall_mat
	wall.position = pos + Vector3(0.0, 2.75, 0.0)
	wall.rotation.y = yaw
	parent.add_child(wall)
	_add_box_collision(parent, wall.position, w_box.size, yaw)

func _build_ruined_keep() -> void:
	var keep_root: Node3D = Node3D.new()
	keep_root.name = "CastleKeep"
	keep_root.position = Vector3(0.0, 0.0, -14.0)
	add_child(keep_root)

	# Main Tower Keep (Octagonal / Cylindrical)
	var keep_mesh: MeshInstance3D = MeshInstance3D.new()
	var k_cyl: CylinderMesh = CylinderMesh.new()
	k_cyl.top_radius = 4.8
	k_cyl.bottom_radius = 5.2
	k_cyl.height = 12.5
	keep_mesh.mesh = k_cyl
	keep_mesh.material_override = _stone_wall_mat
	keep_mesh.position = Vector3(0.0, 6.25, 0.0)
	keep_root.add_child(keep_mesh)
	_add_cylinder_collision(keep_root, keep_mesh.position, 5.0, 12.5)

	# Ancient Beacon Brazier
	var brazier_light: OmniLight3D = OmniLight3D.new()
	brazier_light.light_color = Color(0.45, 0.85, 1.0) # Spectral ethereal blue
	brazier_light.light_energy = 2.2
	brazier_light.omni_range = 22.0
	brazier_light.position = Vector3(0.0, 13.0, 0.0)
	keep_root.add_child(brazier_light)

func _build_inner_courtyard_and_relic() -> void:
	var court_root: Node3D = Node3D.new()
	court_root.name = "CourtyardAndRelic"
	court_root.position = Vector3(0.0, 0.0, -7.0)
	add_child(court_root)

	# Flagstone courtyard platform
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var f_box: BoxMesh = BoxMesh.new()
	f_box.size = Vector3(12.0, 0.35, 10.0)
	floor_mesh.mesh = f_box
	floor_mesh.material_override = _stone_flag_mat
	floor_mesh.position = Vector3(0.0, 0.175, 0.0)
	court_root.add_child(floor_mesh)
	_add_box_collision(court_root, floor_mesh.position, f_box.size)

	# Central Relic Monolith Dais
	_relic_node = Node3D.new()
	_relic_node.name = "AncientRelicMonolith"
	_relic_node.position = Vector3(0.0, 0.35, 0.0)
	court_root.add_child(_relic_node)

	# Stepped stone base
	var dais_base: MeshInstance3D = MeshInstance3D.new()
	var d_cyl: CylinderMesh = CylinderMesh.new()
	d_cyl.top_radius = 1.4
	d_cyl.bottom_radius = 1.6
	d_cyl.height = 0.5
	dais_base.mesh = d_cyl
	dais_base.material_override = _stone_wall_mat
	dais_base.position = Vector3(0.0, 0.25, 0.0)
	_relic_node.add_child(dais_base)

	# Floating Runic Crystal Obelisk
	var obelisk: MeshInstance3D = MeshInstance3D.new()
	var prism: PrismMesh = PrismMesh.new()
	prism.size = Vector3(0.85, 2.6, 0.85)
	obelisk.mesh = prism
	obelisk.material_override = _relic_mat
	obelisk.position = Vector3(0.0, 1.8, 0.0)
	_relic_node.add_child(obelisk)

	# Glowing Relic Light
	_relic_light = OmniLight3D.new()
	_relic_light.light_color = Color(0.25, 0.88, 1.0)
	_relic_light.light_energy = 1.8
	_relic_light.omni_range = 10.0
	_relic_light.position = Vector3(0.0, 1.8, 0.0)
	_relic_node.add_child(_relic_light)

	# 3D In-world Interaction Label
	var label: Label3D = Label3D.new()
	label.name = "RelicLabel"
	label.text = "✦ Cổ Vật Niêm Phong Khải Huyền ✦\n[Nhấn E để Kích Hoạt]"
	label.font_size = 20
	label.modulate = Color(0.55, 0.92, 1.0)
	label.outline_modulate = Color(0.05, 0.15, 0.25, 0.9)
	label.outline_size = 5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0.0, 3.4, 0.0)
	_relic_node.add_child(label)

func _spawn_spectral_warden() -> void:
	# Sir Raymond standing in the castle courtyard before the keep
	_npc_raymond = Node3D.new()
	_npc_raymond.name = "NPC_Raymond"
	_npc_raymond.position = Vector3(2.8, 0.35, -5.5)
	add_child(_npc_raymond)

	# Armored torso
	var torso: MeshInstance3D = MeshInstance3D.new()
	var cap: CapsuleMesh = CapsuleMesh.new()
	cap.radius = 0.36
	cap.height = 1.75
	torso.mesh = cap
	torso.material_override = _spectral_mat
	torso.position = Vector3(0.0, 0.875, 0.0)
	_npc_raymond.add_child(torso)

	# Knight Greathelm
	var helm: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.42, 0.46, 0.42)
	helm.mesh = box
	helm.material_override = _spectral_mat
	helm.position = Vector3(0.0, 1.62, 0.0)
	_npc_raymond.add_child(helm)

	# Spectral Greatsword held upright
	var sword: MeshInstance3D = MeshInstance3D.new()
	var sw_box: BoxMesh = BoxMesh.new()
	sw_box.size = Vector3(0.08, 1.65, 0.22)
	sword.mesh = sw_box
	sword.material_override = _spectral_mat
	sword.position = Vector3(0.42, 0.85, 0.25)
	_npc_raymond.add_child(sword)

	# Overhead 3D Nameplate
	var plate: Label3D = Label3D.new()
	plate.name = "NamePlate"
	plate.text = "🛡️ HIỆP SĨ RAYMOND — Hộ Vệ Tàn Tích Cổ"
	plate.font_size = 24
	plate.modulate = Color(0.65, 0.88, 1.0)
	plate.outline_modulate = Color(0.08, 0.15, 0.25, 0.95)
	plate.outline_size = 6
	plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plate.position = Vector3(0.0, 2.25, 0.0)
	_npc_raymond.add_child(plate)

	_add_cylinder_collision(_npc_raymond, Vector3(0.0, 0.85, 0.0), 0.48, 1.75)

func _process(delta: float) -> void:
	# Subtle floating rotation of ancient relic obelisk
	if _relic_node:
		var ob = _relic_node.get_node_or_null("PrismMesh")
		if not ob:
			for c in _relic_node.get_children():
				if c is MeshInstance3D and c.mesh is PrismMesh:
					c.rotation.y += delta * 0.75
					break

	# Look-at head tracking toward player
	if _npc_raymond and _player_node:
		var p_pos: Vector3 = _player_node.global_position if _player_node.is_inside_tree() else _player_node.position
		var r_pos: Vector3 = _npc_raymond.global_position if _npc_raymond.is_inside_tree() else (_npc_raymond.position + position)
		if r_pos.distance_to(p_pos) < 7.0:
			var target_yaw: float = atan2(p_pos.x - r_pos.x, p_pos.z - r_pos.z)
			_npc_raymond.rotation.y = lerp_angle(_npc_raymond.rotation.y, target_yaw, delta * 3.5)

func _build_catacombs_crypt() -> void:
	_catacombs_root = Node3D.new()
	_catacombs_root.name = "CastleCatacombs"
	# Subterranean crypt level centered beneath keep
	_catacombs_root.position = Vector3(0.0, -4.8, -20.0)
	add_child(_catacombs_root)

	# 1. Entrance Portal Archway & Descending Stairwell at (0, 0, -11.0)
	var stair_root: Node3D = Node3D.new()
	stair_root.name = "CryptStairwell"
	stair_root.position = Vector3(0.0, 0.0, -11.0)
	add_child(stair_root)

	# Portal lintel
	var portal: MeshInstance3D = MeshInstance3D.new()
	var p_box: BoxMesh = BoxMesh.new()
	p_box.size = Vector3(3.6, 3.8, 1.2)
	portal.mesh = p_box
	portal.material_override = _stone_wall_mat
	portal.position = Vector3(0.0, 1.9, 0.0)
	stair_root.add_child(portal)

	# Portal Sign
	var p_lbl: Label3D = Label3D.new()
	p_lbl.name = "PortalLabel"
	p_lbl.text = "🏛️ LỐI XUỐNG THẠCH THẤT HOÀNG GIA"
	p_lbl.font_size = 20
	p_lbl.modulate = Color(0.65, 0.88, 1.0)
	p_lbl.outline_modulate = Color(0.05, 0.1, 0.2, 0.9)
	p_lbl.outline_size = 5
	p_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	p_lbl.position = Vector3(0.0, 3.6, 0.0)
	stair_root.add_child(p_lbl)

	# 8 Stone steps descending from y=0 down to y=-4.8
	for i in range(8):
		var step: MeshInstance3D = MeshInstance3D.new()
		var s_mesh: BoxMesh = BoxMesh.new()
		s_mesh.size = Vector3(3.2, 0.6, 1.2)
		step.mesh = s_mesh
		step.material_override = _stone_flag_mat
		step.position = Vector3(0.0, -0.6 * (i + 1), -1.1 * (i + 1))
		stair_root.add_child(step)
		_add_box_collision(stair_root, step.position, s_mesh.size)

	# 2. Main Crypt Chamber
	# Floor
	var c_floor: MeshInstance3D = MeshInstance3D.new()
	var cf_box: BoxMesh = BoxMesh.new()
	cf_box.size = Vector3(14.0, 0.4, 16.0)
	c_floor.mesh = cf_box
	c_floor.material_override = _stone_flag_mat
	c_floor.position = Vector3(0.0, -0.2, 0.0)
	_catacombs_root.add_child(c_floor)
	_add_box_collision(_catacombs_root, c_floor.position, cf_box.size)

	# Ceiling
	var c_ceil: MeshInstance3D = MeshInstance3D.new()
	var cc_box: BoxMesh = BoxMesh.new()
	cc_box.size = Vector3(14.0, 0.4, 16.0)
	c_ceil.mesh = cc_box
	c_ceil.material_override = _stone_wall_mat
	c_ceil.position = Vector3(0.0, 4.4, 0.0)
	_catacombs_root.add_child(c_ceil)
	_add_box_collision(_catacombs_root, c_ceil.position, cc_box.size)

	# Perimeter Walls
	_build_crypt_wall(_catacombs_root, Vector3(0.0, 2.1, -8.0), Vector3(14.0, 4.4, 0.8))
	_build_crypt_wall(_catacombs_root, Vector3(-7.0, 2.1, 0.0), Vector3(0.8, 4.4, 16.0))
	_build_crypt_wall(_catacombs_root, Vector3(7.0, 2.1, 0.0), Vector3(0.8, 4.4, 16.0))
	_build_crypt_wall(_catacombs_root, Vector3(-4.5, 2.1, 8.0), Vector3(5.0, 4.4, 0.8))
	_build_crypt_wall(_catacombs_root, Vector3(4.5, 2.1, 8.0), Vector3(5.0, 4.4, 0.8))

	# 3. 4 Crypt Vault Pillars
	var p_offsets: Array[Vector3] = [
		Vector3(-4.0, 2.0, -4.0),
		Vector3(4.0, 2.0, -4.0),
		Vector3(-4.0, 2.0, 4.0),
		Vector3(4.0, 2.0, 4.0)
	]
	for p_pos in p_offsets:
		var col: MeshInstance3D = MeshInstance3D.new()
		var col_mesh: CylinderMesh = CylinderMesh.new()
		col_mesh.top_radius = 0.55
		col_mesh.bottom_radius = 0.65
		col_mesh.height = 4.2
		col.mesh = col_mesh
		col.material_override = _stone_wall_mat
		col.position = p_pos
		_catacombs_root.add_child(col)
		_add_cylinder_collision(_catacombs_root, p_pos, 0.6, 4.2)

	# 4. Wall Torch Sconces with ethereal blue light
	var sconce_positions: Array[Vector3] = [
		Vector3(-6.4, 2.2, -4.0),
		Vector3(6.4, 2.2, -4.0),
		Vector3(-6.4, 2.2, 4.0),
		Vector3(6.4, 2.2, 4.0)
	]
	for sc_pos in sconce_positions:
		var sc_light: OmniLight3D = OmniLight3D.new()
		sc_light.light_color = Color(0.35, 0.75, 1.0)
		sc_light.light_energy = 1.4
		sc_light.omni_range = 8.5
		sc_light.position = sc_pos
		_catacombs_root.add_child(sc_light)

	# 5. Runic Braziers
	_brazier_alpha_node = _build_crypt_brazier("CatacombBrazierAlpha", Vector3(-3.5, 0.0, -2.5))
	_catacombs_root.add_child(_brazier_alpha_node)
	_brazier_alpha_light = _brazier_alpha_node.get_node("BrazierLight") as OmniLight3D

	_brazier_beta_node = _build_crypt_brazier("CatacombBrazierBeta", Vector3(3.5, 0.0, -2.5))
	_catacombs_root.add_child(_brazier_beta_node)
	_brazier_beta_light = _brazier_beta_node.get_node("BrazierLight") as OmniLight3D

	# 6. Ancient Stone Sarcophagus
	_build_ancient_sarcophagus(Vector3(0.0, 0.0, -5.5))

func _build_crypt_wall(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var wall: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	wall.mesh = box
	wall.material_override = _stone_wall_mat
	wall.position = pos
	parent.add_child(wall)
	_add_box_collision(parent, pos, size)

func _build_crypt_brazier(id: String, pos: Vector3) -> Node3D:
	var b_root: Node3D = Node3D.new()
	b_root.name = id
	b_root.position = pos

	var ped: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.70
	cyl.height = 1.1
	ped.mesh = cyl
	ped.material_override = _stone_wall_mat
	ped.position = Vector3(0.0, 0.55, 0.0)
	b_root.add_child(ped)

	var bowl: MeshInstance3D = MeshInstance3D.new()
	var b_cyl: CylinderMesh = CylinderMesh.new()
	b_cyl.top_radius = 0.75
	b_cyl.bottom_radius = 0.40
	b_cyl.height = 0.45
	bowl.mesh = b_cyl
	bowl.material_override = _iron_mat
	bowl.position = Vector3(0.0, 1.2, 0.0)
	b_root.add_child(bowl)

	var light: OmniLight3D = OmniLight3D.new()
	light.name = "BrazierLight"
	light.light_color = Color(0.20, 0.85, 1.0)
	light.light_energy = 0.0
	light.omni_range = 10.0
	light.position = Vector3(0.0, 1.6, 0.0)
	b_root.add_child(light)

	var lbl: Label3D = Label3D.new()
	lbl.name = "BrazierLabel"
	lbl.text = "🔥 Đài Lửa Viễn Cổ [E]"
	lbl.font_size = 18
	lbl.modulate = Color(0.75, 0.85, 1.0)
	lbl.outline_modulate = Color(0.05, 0.1, 0.15, 0.9)
	lbl.outline_size = 5
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0.0, 2.1, 0.0)
	b_root.add_child(lbl)

	_add_cylinder_collision(b_root, Vector3(0.0, 0.6, 0.0), 0.65, 1.3)
	return b_root

func _build_ancient_sarcophagus(pos: Vector3) -> void:
	_sarcophagus_node = Node3D.new()
	_sarcophagus_node.name = "AncientSarcophagus"
	_sarcophagus_node.position = pos
	_catacombs_root.add_child(_sarcophagus_node)

	var coffer: MeshInstance3D = MeshInstance3D.new()
	var c_box: BoxMesh = BoxMesh.new()
	c_box.size = Vector3(2.4, 1.1, 3.4)
	coffer.mesh = c_box
	coffer.material_override = _stone_wall_mat
	coffer.position = Vector3(0.0, 0.55, 0.0)
	_sarcophagus_node.add_child(coffer)

	var lid: MeshInstance3D = MeshInstance3D.new()
	var l_box: BoxMesh = BoxMesh.new()
	l_box.size = Vector3(2.6, 0.35, 3.6)
	lid.mesh = l_box
	lid.material_override = _relic_mat
	lid.position = Vector3(0.0, 1.25, 0.0)
	_sarcophagus_node.add_child(lid)

	var crest: MeshInstance3D = MeshInstance3D.new()
	var cr_prism: PrismMesh = PrismMesh.new()
	cr_prism.size = Vector3(0.6, 0.4, 2.2)
	crest.mesh = cr_prism
	crest.material_override = _relic_mat
	crest.position = Vector3(0.0, 1.55, 0.0)
	_sarcophagus_node.add_child(crest)

	_sarcophagus_label = Label3D.new()
	_sarcophagus_label.name = "SarcophagusLabel"
	_sarcophagus_label.text = "⚱️ QUAN QUÁCH VUA CỔ VIỄN ĐẠI\n[Phong ấn Cổ Ngữ — Hãy thắp 2 Đài Lửa]"
	_sarcophagus_label.font_size = 20
	_sarcophagus_label.modulate = Color(0.85, 0.90, 1.0)
	_sarcophagus_label.outline_modulate = Color(0.1, 0.1, 0.2, 0.9)
	_sarcophagus_label.outline_size = 6
	_sarcophagus_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sarcophagus_label.position = Vector3(0.0, 2.4, 0.0)
	_sarcophagus_node.add_child(_sarcophagus_label)

	_add_box_collision(_sarcophagus_node, Vector3(0.0, 0.7, 0.0), Vector3(2.6, 1.4, 3.6))

func light_brazier(brazier_id: String) -> bool:
	if brazier_id == "CatacombBrazierAlpha":
		if _brazier_alpha_lit:
			return false
		_brazier_alpha_lit = true
		if _brazier_alpha_light:
			_brazier_alpha_light.light_energy = 2.4
		var lbl = _brazier_alpha_node.get_node_or_null("BrazierLabel") as Label3D
		if lbl:
			lbl.text = "🔥 Đài Lửa Cổ Tả (Đã Thắp)"
			lbl.modulate = Color(0.4, 1.0, 0.8)
		brazier_lit.emit("CatacombBrazierAlpha")
	elif brazier_id == "CatacombBrazierBeta":
		if _brazier_beta_lit:
			return false
		_brazier_beta_lit = true
		if _brazier_beta_light:
			_brazier_beta_light.light_energy = 2.4
		var lbl = _brazier_beta_node.get_node_or_null("BrazierLabel") as Label3D
		if lbl:
			lbl.text = "🔥 Đài Lửa Cổ Hữu (Đã Thắp)"
			lbl.modulate = Color(0.4, 1.0, 0.8)
		brazier_lit.emit("CatacombBrazierBeta")
	else:
		return false

	if are_both_braziers_lit() and not _sarcophagus_looted:
		if _sarcophagus_label:
			_sarcophagus_label.text = "✨ PHONG ẤN ĐÃ MỞ ✨\n[E] Thu hồi Ấn Tín Hoàng Gia Viễn Cổ"
			_sarcophagus_label.modulate = Color(1.0, 0.92, 0.45)
		print("[AncientCastleCitadel] Catacombs seal dispelled! Sarcophagus unlocked.")

	return true

func is_brazier_lit(brazier_id: String) -> bool:
	if brazier_id == "CatacombBrazierAlpha":
		return _brazier_alpha_lit
	elif brazier_id == "CatacombBrazierBeta":
		return _brazier_beta_lit
	return false

func are_both_braziers_lit() -> bool:
	return _brazier_alpha_lit and _brazier_beta_lit

func is_sarcophagus_looted() -> bool:
	return _sarcophagus_looted

func has_royal_seal() -> bool:
	return _sarcophagus_looted

func open_sarcophagus() -> Dictionary:
	if not are_both_braziers_lit() or _sarcophagus_looted:
		return {}
	_sarcophagus_looted = true
	if _sarcophagus_label:
		_sarcophagus_label.text = "✨ ĐÃ THU HỒI ẤN TÍN HOÀNG GIA ✨"
		_sarcophagus_label.modulate = Color(0.6, 1.0, 0.7)
	sarcophagus_opened.emit("ancient_royal_seal")
	print("[AncientCastleCitadel] Sarcophagus opened: Ancient Royal Seal claimed!")
	return {
		"item": "ancient_royal_seal",
		"title": "Ấn Tín Hoàng Gia Viễn Cổ",
		"coins": 100
	}

func get_nearby_interactable(player_pos: Vector3) -> Dictionary:
	var base: Vector3 = global_position if is_inside_tree() else position

	# Raymond NPC proximity (within 3.0m)
	if _npc_raymond:
		var r_pos: Vector3 = _npc_raymond.global_position if _npc_raymond.is_inside_tree() else (_npc_raymond.position + base)
		if r_pos.distance_to(player_pos) <= 3.0:
			return {"type": "NPC", "id": "Raymond", "prompt": "[E] Thỉnh giáo Hiệp sĩ Raymond"}

	# Ancient Relic Dais proximity (within 2.8m)
	if _relic_node:
		var rel_pos: Vector3 = _relic_node.global_position if _relic_node.is_inside_tree() else (_relic_node.position + base + Vector3(0, 0, -7))
		if rel_pos.distance_to(player_pos) <= 2.8:
			return {"type": "RELIC", "id": "CastleRelic", "prompt": "[E] Kích hoạt Cổ Vật Niêm Phong"}

	# Catacomb Brazier Alpha (within 2.6m)
	if _brazier_alpha_node and _catacombs_root:
		var b_pos: Vector3 = _brazier_alpha_node.global_position if _brazier_alpha_node.is_inside_tree() else (_brazier_alpha_node.position + _catacombs_root.position + base)
		if b_pos.distance_to(player_pos) <= 2.6:
			return {
				"type": "BRAZIER",
				"id": "CatacombBrazierAlpha",
				"lit": _brazier_alpha_lit,
				"prompt": "[E] Thắp sáng Đài Lửa Cổ Tả" if not _brazier_alpha_lit else "Đài Lửa Cổ Tả (Đã Thắp)"
			}

	# Catacomb Brazier Beta (within 2.6m)
	if _brazier_beta_node and _catacombs_root:
		var b_pos: Vector3 = _brazier_beta_node.global_position if _brazier_beta_node.is_inside_tree() else (_brazier_beta_node.position + _catacombs_root.position + base)
		if b_pos.distance_to(player_pos) <= 2.6:
			return {
				"type": "BRAZIER",
				"id": "CatacombBrazierBeta",
				"lit": _brazier_beta_lit,
				"prompt": "[E] Thắp sáng Đài Lửa Cổ Hữu" if not _brazier_beta_lit else "Đài Lửa Cổ Hữu (Đã Thắp)"
			}

	# Ancient Sarcophagus (within 2.8m)
	if _sarcophagus_node and _catacombs_root:
		var s_pos: Vector3 = _sarcophagus_node.global_position if _sarcophagus_node.is_inside_tree() else (_sarcophagus_node.position + _catacombs_root.position + base)
		if s_pos.distance_to(player_pos) <= 2.8:
			if not are_both_braziers_lit():
				return {
					"type": "SARCOPHAGUS",
					"id": "AncientSarcophagus",
					"locked": true,
					"prompt": "Phong ấn Cổ Ngữ đang khoá chặt quan quách"
				}
			elif not _sarcophagus_looted:
				return {
					"type": "SARCOPHAGUS",
					"id": "AncientSarcophagus",
					"locked": false,
					"prompt": "[E] Mở Quan Quách & Thu hồi Ấn Tín Hoàng Gia"
				}
			else:
				return {
					"type": "SARCOPHAGUS",
					"id": "AncientSarcophagus",
					"locked": false,
					"looted": true,
					"prompt": "Quan Quách đã được thu hồi"
				}

	return {}

func activate_relic() -> bool:
	if _relic_active:
		return false
	_relic_active = true
	if _relic_light:
		_relic_light.light_energy = 4.5
		_relic_light.omni_range = 18.0
	var label = _relic_node.get_node_or_null("RelicLabel") as Label3D
	if label:
		label.text = "✨ ĐÃ GIẢI KHỞI PHONG ẤN THÀNH CỔ ✨"
		label.modulate = Color(1.0, 0.95, 0.60)
	castle_relic_activated.emit()
	print("[AncientCastleCitadel] Castle relic seal broken!")
	return true

func is_relic_active() -> bool:
	return _relic_active

func _add_box_collision(parent: Node3D, pos: Vector3, size: Vector3, yaw: float = 0.0) -> void:
	var sb: StaticBody3D = StaticBody3D.new()
	sb.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = pos
	if absf(yaw) > 0.001:
		cs.rotation.y = yaw
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
