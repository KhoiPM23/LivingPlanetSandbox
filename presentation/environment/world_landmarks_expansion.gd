class_name WorldLandmarksExpansion
extends Node3D

## Living Planet Sandbox — World Landmarks & Regional Architecture Expansion (Block 52)
## Features:
## 1. The Great Highland Windmill (Cối Xay Gió Khổng Lồ Cao Nguyên) with animated rotating sails
## 2. Highland Farmstead & Sheep Pasture (Nông Trang Cao Nguyên & Chuồng Gia Súc)
## 3. Windshear Rope Suspension Bridge (Cầu Treo Hẻm Vực Gió) spanning deep canyon
## 4. Cape Lookout Coastal Watchtower (Tháp Canh Vách Đá Ven Biển) on western sea cliffs
## 5. Ancient Ruined Colonnade (Hàng Cột Đá Tàn Tích Cổ) along the pilgrimage mountain trail

var _terrain: IslandTerrain = null
var _player_node: Node3D = null

# Materials
var _stone_mat: StandardMaterial3D = null
var _weathered_wood_mat: StandardMaterial3D = null
var _roof_mat: StandardMaterial3D = null
var _plank_mat: StandardMaterial3D = null
var _canvas_mat: StandardMaterial3D = null
var _rope_mat: StandardMaterial3D = null
var _hay_mat: StandardMaterial3D = null
var _iron_mat: StandardMaterial3D = null
var _brazier_fire_mat: StandardMaterial3D = null

# Core Nodes
var _windmill_root: Node3D = null
var _windmill_blades_hub: Node3D = null
var _farmstead_root: Node3D = null
var _suspension_bridge_root: Node3D = null
var _watchtower_root: Node3D = null
var _colonnade_root: Node3D = null

# Locations across 720m island
const WINDMILL_POS: Vector3 = Vector3(120.0, 0.0, -42.0)
const FARMSTEAD_POS: Vector3 = Vector3(100.0, 0.0, -58.0)
const BRIDGE_START: Vector3 = Vector3(-48.0, 0.0, 145.0)
const BRIDGE_END: Vector3 = Vector3(-22.0, 0.0, 145.0)
const WATCHTOWER_POS: Vector3 = Vector3(-155.0, 0.0, 36.0)
const COLONNADE_POS: Vector3 = Vector3(56.0, 0.0, 32.0)

var _anim_time: float = 0.0

func setup(terrain: IslandTerrain, player: Node3D = null) -> void:
	_terrain = terrain
	_player_node = player
	_init_materials()

	_build_great_highland_windmill()
	_build_highland_farmstead()
	_build_windshear_suspension_bridge()
	_build_cape_lookout_watchtower()
	_build_ancient_ruined_colonnade()
	_apply_culling_and_shadow_optimizations()

func _init_materials() -> void:
	# Heavy Granite Stone
	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.44, 0.42, 0.40)
	_stone_mat.roughness = 0.88

	# Weathered Timber
	_weathered_wood_mat = StandardMaterial3D.new()
	_weathered_wood_mat.albedo_color = Color(0.36, 0.28, 0.18)
	_weathered_wood_mat.roughness = 0.85

	# Terracotta / Cedar Shingles
	_roof_mat = StandardMaterial3D.new()
	_roof_mat.albedo_color = Color(0.52, 0.26, 0.18)
	_roof_mat.roughness = 0.82

	# Floorboards & Planks
	_plank_mat = StandardMaterial3D.new()
	_plank_mat.albedo_color = Color(0.46, 0.35, 0.22)
	_plank_mat.roughness = 0.78

	# Windmill Sail Canvas (Off-white linen)
	_canvas_mat = StandardMaterial3D.new()
	_canvas_mat.albedo_color = Color(0.88, 0.86, 0.80)
	_canvas_mat.roughness = 0.90
	_canvas_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Hemp Rope
	_rope_mat = StandardMaterial3D.new()
	_rope_mat.albedo_color = Color(0.52, 0.44, 0.30)
	_rope_mat.roughness = 0.95

	# Golden Dry Hay
	_hay_mat = StandardMaterial3D.new()
	_hay_mat.albedo_color = Color(0.82, 0.72, 0.32)
	_hay_mat.roughness = 0.92

	# Black Forged Iron
	_iron_mat = StandardMaterial3D.new()
	_iron_mat.albedo_color = Color(0.16, 0.16, 0.18)
	_iron_mat.metallic = 0.85
	_iron_mat.roughness = 0.40

	# Emissive Fire Ember
	_brazier_fire_mat = StandardMaterial3D.new()
	_brazier_fire_mat.albedo_color = Color(1.0, 0.45, 0.12)
	_brazier_fire_mat.emission_enabled = true
	_brazier_fire_mat.emission = Color(1.0, 0.52, 0.15)
	_brazier_fire_mat.emission_energy_multiplier = 3.0

func _get_ground_y(x: float, z: float, default_y: float = 0.0) -> float:
	if _terrain:
		return _terrain.get_height_at(x, z)
	return default_y

# =============================================================================
# 1. THE GREAT HIGHLAND WINDMILL (CỐI XAY GIÓ KHỔNG LỒ CAO NGUYÊN)
# =============================================================================
func _build_great_highland_windmill() -> void:
	_windmill_root = Node3D.new()
	_windmill_root.name = "TheGreatHighlandWindmill"
	add_child(_windmill_root)

	var ground_y: float = _get_ground_y(WINDMILL_POS.x, WINDMILL_POS.z, 18.0)
	var pos: Vector3 = Vector3(WINDMILL_POS.x, ground_y, WINDMILL_POS.z)

	# 14m Tapering Conical Stone Tower
	var tower_mesh: CylinderMesh = CylinderMesh.new()
	tower_mesh.top_radius = 2.8
	tower_mesh.bottom_radius = 4.2
	tower_mesh.height = 12.0
	tower_mesh.radial_segments = 16
	var tower_mi: MeshInstance3D = MeshInstance3D.new()
	tower_mi.mesh = tower_mesh
	tower_mi.material_override = _stone_mat
	tower_mi.position = pos + Vector3(0.0, 6.0, 0.0)
	_windmill_root.add_child(tower_mi)

	# Domed Roof Cap
	var cap_mesh: CylinderMesh = CylinderMesh.new()
	cap_mesh.top_radius = 0.4
	cap_mesh.bottom_radius = 3.2
	cap_mesh.height = 2.6
	cap_mesh.radial_segments = 16
	var cap_mi: MeshInstance3D = MeshInstance3D.new()
	cap_mi.mesh = cap_mesh
	cap_mi.material_override = _roof_mat
	cap_mi.position = pos + Vector3(0.0, 12.0 + 1.3, 0.0)
	_windmill_root.add_child(cap_mi)

	# Mid-level Wooden Balcony
	var balc_mesh: CylinderMesh = CylinderMesh.new()
	balc_mesh.top_radius = 4.6
	balc_mesh.bottom_radius = 4.6
	balc_mesh.height = 0.35
	balc_mesh.radial_segments = 16
	var balc_mi: MeshInstance3D = MeshInstance3D.new()
	balc_mi.mesh = balc_mesh
	balc_mi.material_override = _plank_mat
	balc_mi.position = pos + Vector3(0.0, 7.5, 0.0)
	_windmill_root.add_child(balc_mi)

	# Rotating Windmill Blades Hub
	_windmill_blades_hub = Node3D.new()
	_windmill_blades_hub.name = "WindmillBladesHub"
	_windmill_blades_hub.position = pos + Vector3(0.0, 11.5, 2.9)
	_windmill_root.add_child(_windmill_blades_hub)

	var hub_axle: CylinderMesh = CylinderMesh.new()
	hub_axle.top_radius = 0.45
	hub_axle.bottom_radius = 0.45
	hub_axle.height = 0.85
	hub_axle.radial_segments = 12
	var axle_mi: MeshInstance3D = MeshInstance3D.new()
	axle_mi.mesh = hub_axle
	axle_mi.material_override = _iron_mat
	axle_mi.rotation.x = deg_to_rad(90.0)
	_windmill_blades_hub.add_child(axle_mi)

	# 4 Lattice Wooden Blades with Canvas Sails
	for b in range(4):
		var blade_angle: float = float(b) * (PI * 0.5)
		var blade_len: float = 6.8

		var spar_mesh: BoxMesh = BoxMesh.new()
		spar_mesh.size = Vector3(0.18, blade_len, 0.18)
		var spar_mi: MeshInstance3D = MeshInstance3D.new()
		spar_mi.mesh = spar_mesh
		spar_mi.material_override = _weathered_wood_mat
		spar_mi.position = Vector3(sin(blade_angle) * (blade_len * 0.5), cos(blade_angle) * (blade_len * 0.5), 0.1)
		spar_mi.rotation.z = -blade_angle
		_windmill_blades_hub.add_child(spar_mi)

		# Canvas cloth sail panel
		var sail_mesh: QuadMesh = QuadMesh.new()
		sail_mesh.size = Vector2(1.15, blade_len * 0.85)
		var sail_mi: MeshInstance3D = MeshInstance3D.new()
		sail_mi.mesh = sail_mesh
		sail_mi.material_override = _canvas_mat
		sail_mi.position = Vector3(sin(blade_angle) * (blade_len * 0.5) + cos(blade_angle) * 0.55, cos(blade_angle) * (blade_len * 0.5) - sin(blade_angle) * 0.55, 0.12)
		sail_mi.rotation.z = -blade_angle
		_windmill_blades_hub.add_child(sail_mi)

	# Adjacent Grain Storehouse
	var shed_mesh: BoxMesh = BoxMesh.new()
	shed_mesh.size = Vector3(4.8, 3.2, 4.2)
	var shed_mi: MeshInstance3D = MeshInstance3D.new()
	shed_mi.mesh = shed_mesh
	shed_mi.material_override = _weathered_wood_mat
	shed_mi.position = pos + Vector3(4.5, 1.6, -1.5)
	_windmill_root.add_child(shed_mi)

	# Shed roof
	var sroof_mesh: PrismMesh = PrismMesh.new()
	sroof_mesh.size = Vector3(4.5, 1.8, 5.2)
	var sroof_mi: MeshInstance3D = MeshInstance3D.new()
	sroof_mi.mesh = sroof_mesh
	sroof_mi.material_override = _roof_mat
	sroof_mi.position = pos + Vector3(4.5, 3.2 + 0.9, -1.5)
	sroof_mi.rotation.y = deg_to_rad(90.0)
	_windmill_root.add_child(sroof_mi)

	# Physical Collision for Tower and Shed
	var sb: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = 4.2
	cyl.height = 12.0
	col.shape = cyl
	sb.position = pos + Vector3(0.0, 6.0, 0.0)
	sb.add_child(col)
	_windmill_root.add_child(sb)

# =============================================================================
# 2. HIGHLAND FARMSTEAD & SHEEP PASTURE (NÔNG TRANG CAO NGUYÊN & CHUỒNG GIA SÚC)
# =============================================================================
func _build_highland_farmstead() -> void:
	_farmstead_root = Node3D.new()
	_farmstead_root.name = "HighlandFarmstead"
	add_child(_farmstead_root)

	var farm_y: float = _get_ground_y(FARMSTEAD_POS.x, FARMSTEAD_POS.z, 16.5)
	var pos: Vector3 = Vector3(FARMSTEAD_POS.x, farm_y, FARMSTEAD_POS.z)

	# Farmhouse Living Quarters
	var house_mesh: BoxMesh = BoxMesh.new()
	house_mesh.size = Vector3(7.2, 3.6, 5.5)
	var house_mi: MeshInstance3D = MeshInstance3D.new()
	house_mi.mesh = house_mesh
	house_mi.material_override = _weathered_wood_mat
	house_mi.position = pos + Vector3(0.0, 1.8, 0.0)
	_farmstead_root.add_child(house_mi)

	# Pitched Roof
	var hroof_mesh: PrismMesh = PrismMesh.new()
	hroof_mesh.size = Vector3(5.8, 2.4, 7.8)
	var hroof_mi: MeshInstance3D = MeshInstance3D.new()
	hroof_mi.mesh = hroof_mesh
	hroof_mi.material_override = _roof_mat
	hroof_mi.position = pos + Vector3(0.0, 3.6 + 1.2, 0.0)
	hroof_mi.rotation.y = deg_to_rad(90.0)
	_farmstead_root.add_child(hroof_mi)

	# Stone Chimney
	var chim_mesh: BoxMesh = BoxMesh.new()
	chim_mesh.size = Vector3(1.1, 5.8, 1.1)
	var chim_mi: MeshInstance3D = MeshInstance3D.new()
	chim_mi.mesh = chim_mesh
	chim_mi.material_override = _stone_mat
	chim_mi.position = pos + Vector3(2.6, 2.9, 0.0)
	_farmstead_root.add_child(chim_mi)

	# Split-rail Wooden Pasture Fence (20m x 16m pasture)
	var fence_w: float = 20.0
	var fence_d: float = 16.0
	var pasture_center: Vector3 = pos + Vector3(-12.0, 0.0, 10.0)

	_build_fence_line(pasture_center + Vector3(-fence_w*0.5, 0, -fence_d*0.5), pasture_center + Vector3(fence_w*0.5, 0, -fence_d*0.5))
	_build_fence_line(pasture_center + Vector3(fence_w*0.5, 0, -fence_d*0.5), pasture_center + Vector3(fence_w*0.5, 0, fence_d*0.5))
	_build_fence_line(pasture_center + Vector3(fence_w*0.5, 0, fence_d*0.5), pasture_center + Vector3(-fence_w*0.5, 0, fence_d*0.5))
	_build_fence_line(pasture_center + Vector3(-fence_w*0.5, 0, fence_d*0.5), pasture_center + Vector3(-fence_w*0.5, 0, -fence_d*0.5))

	# Hay Bales in pasture
	for hb_pos in [Vector3(-8.0, 0.0, 8.0), Vector3(-6.5, 0.0, 9.5), Vector3(-14.0, 0.0, 12.0)]:
		var hb_mesh: CylinderMesh = CylinderMesh.new()
		hb_mesh.top_radius = 0.75
		hb_mesh.bottom_radius = 0.75
		hb_mesh.height = 1.1
		var hb_mi: MeshInstance3D = MeshInstance3D.new()
		hb_mi.mesh = hb_mesh
		hb_mi.material_override = _hay_mat
		var hby: float = _get_ground_y(pasture_center.x + hb_pos.x, pasture_center.z + hb_pos.z, farm_y)
		hb_mi.position = Vector3(pasture_center.x + hb_pos.x, hby + 0.55, pasture_center.z + hb_pos.z)
		_farmstead_root.add_child(hb_mi)

	# Collision
	var sb: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(7.4, 4.0, 5.7)
	col.shape = box
	sb.position = pos + Vector3(0.0, 2.0, 0.0)
	sb.add_child(col)
	_farmstead_root.add_child(sb)

func _build_fence_line(p_start: Vector3, p_end: Vector3) -> void:
	var dist: float = (Vector2(p_end.x, p_end.z) - Vector2(p_start.x, p_start.z)).length()
	var posts: int = int(dist / 3.2)
	for i in range(posts + 1):
		var t: float = float(i) / float(max(posts, 1))
		var fx: float = lerpf(p_start.x, p_end.x, t)
		var fz: float = lerpf(p_start.z, p_end.z, t)
		var fy: float = _get_ground_y(fx, fz, p_start.y)

		var post_mesh: CylinderMesh = CylinderMesh.new()
		post_mesh.top_radius = 0.09
		post_mesh.bottom_radius = 0.11
		post_mesh.height = 1.2
		var p_mi: MeshInstance3D = MeshInstance3D.new()
		p_mi.mesh = post_mesh
		p_mi.material_override = _weathered_wood_mat
		p_mi.position = Vector3(fx, fy + 0.6, fz)
		_farmstead_root.add_child(p_mi)

		# Horizontal rail
		if i < posts:
			var next_fx: float = lerpf(p_start.x, p_end.x, float(i + 1) / float(max(posts, 1)))
			var next_fz: float = lerpf(p_start.z, p_end.z, float(i + 1) / float(max(posts, 1)))
			var mid_x: float = (fx + next_fx) * 0.5
			var mid_z: float = (fz + next_fz) * 0.5
			var mid_y: float = _get_ground_y(mid_x, mid_z, fy)

			var rail_mesh: BoxMesh = BoxMesh.new()
			rail_mesh.size = Vector3(0.08, 0.12, 3.3)
			var r_mi: MeshInstance3D = MeshInstance3D.new()
			r_mi.mesh = rail_mesh
			r_mi.material_override = _weathered_wood_mat
			r_mi.position = Vector3(mid_x, mid_y + 0.85, mid_z)
			r_mi.rotation.y = atan2(next_fx - fx, next_fz - fz)
			_farmstead_root.add_child(r_mi)

# =============================================================================
# 3. WINDSHEAR ROPE SUSPENSION BRIDGE (CẦU TREO HẺM VỰC GIÓ)
# =============================================================================
func _build_windshear_suspension_bridge() -> void:
	_suspension_bridge_root = Node3D.new()
	_suspension_bridge_root.name = "WindshearSuspensionBridge"
	add_child(_suspension_bridge_root)

	var start_y: float = maxf(_get_ground_y(BRIDGE_START.x, BRIDGE_START.z, 12.5), 10.0)
	var end_y: float = maxf(_get_ground_y(BRIDGE_END.x, BRIDGE_END.z, 12.5), 10.0)
	var p_start: Vector3 = Vector3(BRIDGE_START.x, start_y, BRIDGE_START.z)
	var p_end: Vector3 = Vector3(BRIDGE_END.x, end_y, BRIDGE_END.z)
	var span_len: float = (p_end - p_start).length()
	var num_planks: int = 18
	var bridge_width: float = 2.6

	# Stone Anchor Towers on cliff edges
	for anchor_pos in [p_start, p_end]:
		var tower_mesh: BoxMesh = BoxMesh.new()
		tower_mesh.size = Vector3(1.6, 4.2, 3.6)
		var t_mi: MeshInstance3D = MeshInstance3D.new()
		t_mi.mesh = tower_mesh
		t_mi.material_override = _stone_mat
		t_mi.position = anchor_pos + Vector3(0.0, 2.1, 0.0)
		_suspension_bridge_root.add_child(t_mi)

	# Wooden tread planks with natural catenary sag
	for i in range(num_planks):
		var t: float = float(i + 0.5) / float(num_planks)
		var px: float = lerpf(p_start.x, p_end.x, t)
		var pz: float = lerpf(p_start.z, p_end.z, t)
		# Catenary sag in the middle (1.4m dip)
		var sag: float = sin(t * PI) * 1.4
		var py: float = lerpf(p_start.y, p_end.y, t) - sag

		var plank_mesh: BoxMesh = BoxMesh.new()
		plank_mesh.size = Vector3(span_len / float(num_planks) * 0.92, 0.12, bridge_width)
		var pl_mi: MeshInstance3D = MeshInstance3D.new()
		pl_mi.mesh = plank_mesh
		pl_mi.material_override = _weathered_wood_mat
		pl_mi.position = Vector3(px, py, pz)
		_suspension_bridge_root.add_child(pl_mi)

		# Side rope uprights
		for side in [-1.0, 1.0]:
			var rope_vert: CylinderMesh = CylinderMesh.new()
			rope_vert.top_radius = 0.03
			rope_vert.bottom_radius = 0.03
			rope_vert.height = 1.1
			var rv_mi: MeshInstance3D = MeshInstance3D.new()
			rv_mi.mesh = rope_vert
			rv_mi.material_override = _rope_mat
			rv_mi.position = Vector3(px, py + 0.55, pz + side * (bridge_width * 0.5 - 0.15))
			_suspension_bridge_root.add_child(rv_mi)

	# Main suspension cables running across
	for side in [-1.0, 1.0]:
		var cable_mesh: CylinderMesh = CylinderMesh.new()
		cable_mesh.top_radius = 0.05
		cable_mesh.bottom_radius = 0.05
		cable_mesh.height = span_len * 1.02
		var cab_mi: MeshInstance3D = MeshInstance3D.new()
		cab_mi.mesh = cable_mesh
		cab_mi.material_override = _rope_mat
		cab_mi.position = Vector3((p_start.x + p_end.x) * 0.5, (p_start.y + p_end.y) * 0.5 + 1.1 - 0.7, p_start.z + side * (bridge_width * 0.5 - 0.15))
		cab_mi.rotation.z = deg_to_rad(90.0)
		_suspension_bridge_root.add_child(cab_mi)

	# Walkable Collision Shape
	var sb: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(span_len, 0.4, bridge_width)
	col.shape = box
	sb.position = Vector3((p_start.x + p_end.x) * 0.5, (p_start.y + p_end.y) * 0.5 - 0.6, p_start.z)
	sb.add_child(col)
	_suspension_bridge_root.add_child(sb)

# =============================================================================
# 4. CAPE LOOKOUT COASTAL WATCHTOWER (THÁP CANH VÁCH ĐÁ VEN BIỂN)
# =============================================================================
func _build_cape_lookout_watchtower() -> void:
	_watchtower_root = Node3D.new()
	_watchtower_root.name = "CapeLookoutWatchtower"
	add_child(_watchtower_root)

	var cliff_y: float = _get_ground_y(WATCHTOWER_POS.x, WATCHTOWER_POS.z, 16.5)
	var pos: Vector3 = Vector3(WATCHTOWER_POS.x, cliff_y, WATCHTOWER_POS.z)

	# Hexagonal Stone Bastion Tower
	var tower_mesh: CylinderMesh = CylinderMesh.new()
	tower_mesh.top_radius = 3.2
	tower_mesh.bottom_radius = 3.6
	tower_mesh.height = 10.0
	tower_mesh.radial_segments = 6
	var t_mi: MeshInstance3D = MeshInstance3D.new()
	t_mi.mesh = tower_mesh
	t_mi.material_override = _stone_mat
	t_mi.position = pos + Vector3(0.0, 5.0, 0.0)
	_watchtower_root.add_child(t_mi)

	# Battlements / Parapet atop tower
	var parapet_mesh: CylinderMesh = CylinderMesh.new()
	parapet_mesh.top_radius = 3.5
	parapet_mesh.bottom_radius = 3.3
	parapet_mesh.height = 1.1
	parapet_mesh.radial_segments = 6
	var p_mi: MeshInstance3D = MeshInstance3D.new()
	p_mi.mesh = parapet_mesh
	p_mi.material_override = _stone_mat
	p_mi.position = pos + Vector3(0.0, 10.5, 0.0)
	_watchtower_root.add_child(p_mi)

	# Iron Lookout Brazier on parapet
	var braz_mesh: CylinderMesh = CylinderMesh.new()
	braz_mesh.top_radius = 0.6
	braz_mesh.bottom_radius = 0.4
	braz_mesh.height = 0.6
	var b_mi: MeshInstance3D = MeshInstance3D.new()
	b_mi.mesh = braz_mesh
	b_mi.material_override = _iron_mat
	b_mi.position = pos + Vector3(0.0, 11.3, 0.0)
	_watchtower_root.add_child(b_mi)

	var fire_mesh: SphereMesh = SphereMesh.new()
	fire_mesh.radius = 0.35
	fire_mesh.height = 0.7
	var f_mi: MeshInstance3D = MeshInstance3D.new()
	f_mi.mesh = fire_mesh
	f_mi.material_override = _brazier_fire_mat
	f_mi.position = pos + Vector3(0.0, 11.75, 0.0)
	_watchtower_root.add_child(f_mi)

	var fire_light: OmniLight3D = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.60, 0.22)
	fire_light.light_energy = 2.4
	fire_light.omni_range = 14.0
	fire_light.position = pos + Vector3(0.0, 12.0, 0.0)
	_watchtower_root.add_child(fire_light)

	# Static collision
	var sb: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = 3.6
	cyl.height = 11.0
	col.shape = cyl
	sb.position = pos + Vector3(0.0, 5.5, 0.0)
	sb.add_child(col)
	_watchtower_root.add_child(sb)

# =============================================================================
# 5. ANCIENT RUINED COLONNADE (HÀNG CỘT ĐÁ TÀN TÍCH CỔ)
# =============================================================================
func _build_ancient_ruined_colonnade() -> void:
	_colonnade_root = Node3D.new()
	_colonnade_root.name = "AncientRuinedColonnade"
	add_child(_colonnade_root)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4488

	# Classical Stone Columns along the ancient ridge path
	for i in range(8):
		var t: float = float(i) / 7.0
		var cx: float = COLONNADE_POS.x + (t - 0.5) * 28.0
		var cz: float = COLONNADE_POS.z + sin(t * PI) * 6.0
		var cy: float = _get_ground_y(cx, cz, 6.5)

		var is_broken: bool = (i == 2 or i == 5)
		var col_h: float = 2.4 if is_broken else rng.randf_range(4.2, 5.4)

		var col_mesh: CylinderMesh = CylinderMesh.new()
		col_mesh.top_radius = 0.42
		col_mesh.bottom_radius = 0.48
		col_mesh.height = col_h
		col_mesh.radial_segments = 12

		var c_mi: MeshInstance3D = MeshInstance3D.new()
		c_mi.mesh = col_mesh
		c_mi.material_override = _stone_mat
		c_mi.position = Vector3(cx, cy + col_h * 0.5, cz)
		if is_broken:
			c_mi.rotation = Vector3(rng.randf_range(0.1, 0.25), rng.randf_range(0.0, TAU), rng.randf_range(-0.1, 0.1))
		_colonnade_root.add_child(c_mi)

		# Stone capital / entablature block
		if not is_broken:
			var cap_mesh: BoxMesh = BoxMesh.new()
			cap_mesh.size = Vector3(1.2, 0.45, 1.2)
			var cap_mi: MeshInstance3D = MeshInstance3D.new()
			cap_mi.mesh = cap_mesh
			cap_mi.material_override = _stone_mat
			cap_mi.position = Vector3(cx, cy + col_h + 0.22, cz)
			_colonnade_root.add_child(cap_mi)

func _process(delta: float) -> void:
	_anim_time += delta
	# Rotate the giant windmill blades smoothly
	if _windmill_blades_hub:
		_windmill_blades_hub.rotation.z += delta * 0.45

func _apply_culling_and_shadow_optimizations() -> void:
	for child in find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = child as MeshInstance3D
		if not mi:
			continue
		var mname: String = mi.name.to_lower()
		var p_name: String = mi.get_parent().name.to_lower() if mi.get_parent() else ""
		var is_major_landmark: bool = ("windmill" in p_name or "tower" in p_name or "bridge" in p_name or "barn" in p_name or "dwelling" in p_name or "windmill" in mname)
		if is_major_landmark:
			mi.visibility_range_end = 260.0
			mi.visibility_range_end_margin = 30.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		else:
			# Fences, hay bales, crates, planks, ropes, small colonnade capitals
			mi.visibility_range_end = 95.0
			mi.visibility_range_end_margin = 15.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
