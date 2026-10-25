class_name GrandEmeraldLakeFeatures
extends Node3D

## Living Planet Sandbox — Grand Emerald Lake & Fjord Basin Features (Block 52)
## Features:
## 1. Ancient Jade Arch Bridge (Cầu Vòm Đá Cổ Gió Bích) spanning northern channel to Heart Island
## 2. Anemo Sanctuary Pavilion (Đài Vọng Cảnh & Điện Thờ Thần Gió) on Heart Island crown
## 3. Lakeside Stilt Boathouse & Fisher's Pier (Nhà Bè & Bến Thuyền Ven Hồ) on western shore
## 4. Emerald Cascade Waterfall (Thác Nước Đổ Vào Hồ) on southern gorge cliffs
## 5. Lakeside Water Lily Pads & Decorative Shoreline Reeds

signal anemo_sanctuary_visited()

var _terrain: IslandTerrain = null
var _player_node: Node3D = null

# Materials
var _stone_mat: StandardMaterial3D = null
var _marble_mat: StandardMaterial3D = null
var _wood_mat: StandardMaterial3D = null
var _plank_mat: StandardMaterial3D = null
var _thatch_mat: StandardMaterial3D = null
var _anemo_glow_mat: StandardMaterial3D = null
var _waterfall_mat: StandardMaterial3D = null
var _water_lily_mat: StandardMaterial3D = null
var _reed_mat: StandardMaterial3D = null

# Core Nodes
var _bridge_root: Node3D = null
var _pavilion_root: Node3D = null
var _boathouse_root: Node3D = null
var _waterfall_root: Node3D = null
var _anemo_altar_core: Node3D = null
var _anemo_altar_light: OmniLight3D = null
var _altar_particles: GPUParticles3D = null

# Positions
const LAKE_CENTER: Vector3 = Vector3(95.0, 0.0, 85.0)
const HEART_ISLAND_POS: Vector3 = Vector3(95.0, 0.0, 85.0)
const BRIDGE_START: Vector3 = Vector3(95.0, 0.0, 50.0)
const BRIDGE_END: Vector3 = Vector3(95.0, 0.0, 72.0)
const BOATHOUSE_POS: Vector3 = Vector3(32.0, 0.0, 82.0)
const WATERFALL_TOP: Vector3 = Vector3(125.0, 16.5, 172.0)
const WATERFALL_BOTTOM: Vector3 = Vector3(118.0, 0.2, 142.0)

var _anim_time: float = 0.0

func setup(terrain: IslandTerrain, player: Node3D = null) -> void:
	_terrain = terrain
	_player_node = player
	_init_materials()

	_build_ancient_arch_bridge()
	_build_anemo_sanctuary_pavilion()
	_build_lakeside_boathouse_and_pier()
	_build_emerald_cascade_waterfall()
	_build_water_lilies_and_reeds()
	_apply_culling_and_shadow_optimizations()

func _init_materials() -> void:
	# Ancient Weathered Granite Ashlar
	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.48, 0.46, 0.43)
	_stone_mat.roughness = 0.88

	# Classical Jade/White Marble
	_marble_mat = StandardMaterial3D.new()
	_marble_mat.albedo_color = Color(0.85, 0.88, 0.86)
	_marble_mat.roughness = 0.40

	# Weathered Pier Timber
	_wood_mat = StandardMaterial3D.new()
	_wood_mat.albedo_color = Color(0.38, 0.28, 0.18)
	_wood_mat.roughness = 0.85

	# Deck Planks
	_plank_mat = StandardMaterial3D.new()
	_plank_mat.albedo_color = Color(0.48, 0.36, 0.22)
	_plank_mat.roughness = 0.78

	# Thatch / Reed Roofing
	_thatch_mat = StandardMaterial3D.new()
	_thatch_mat.albedo_color = Color(0.55, 0.45, 0.28)
	_thatch_mat.roughness = 0.95

	# Luminous Anemo Teal Glow
	_anemo_glow_mat = StandardMaterial3D.new()
	_anemo_glow_mat.albedo_color = Color(0.18, 0.88, 0.82)
	_anemo_glow_mat.emission_enabled = true
	_anemo_glow_mat.emission = Color(0.20, 0.92, 0.85)
	_anemo_glow_mat.emission_energy_multiplier = 3.5

	# Waterfall Cascade Material
	_waterfall_mat = StandardMaterial3D.new()
	_waterfall_mat.albedo_color = Color(0.75, 0.94, 0.98, 0.82)
	_waterfall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_waterfall_mat.roughness = 0.05
	_waterfall_mat.metallic_specular = 0.85

	# Water Lily Pad Green
	_water_lily_mat = StandardMaterial3D.new()
	_water_lily_mat.albedo_color = Color(0.18, 0.45, 0.22)
	_water_lily_mat.roughness = 0.65

	# Shoreline Cattail / Reed
	_reed_mat = StandardMaterial3D.new()
	_reed_mat.albedo_color = Color(0.32, 0.48, 0.20)
	_reed_mat.roughness = 0.80

func _get_ground_y(x: float, z: float, default_y: float = 0.0) -> float:
	if _terrain:
		return _terrain.get_height_at(x, z)
	return default_y

# =============================================================================
# 1. ANCIENT JADE ARCH BRIDGE (CẦU VÒM ĐÁ CỔ GIÓ BÍCH)
# =============================================================================
func _build_ancient_arch_bridge() -> void:
	_bridge_root = Node3D.new()
	_bridge_root.name = "AncientJadeArchBridge"
	add_child(_bridge_root)

	var start_y: float = maxf(_get_ground_y(BRIDGE_START.x, BRIDGE_START.z, 1.5), 1.2)
	var end_y: float = maxf(_get_ground_y(BRIDGE_END.x, BRIDGE_END.z, 2.4), 2.2)
	var span_len: float = (Vector2(BRIDGE_END.x, BRIDGE_END.z) - Vector2(BRIDGE_START.x, BRIDGE_START.z)).length()
	var num_steps: int = 14
	var bridge_width: float = 3.8

	# Walkway segments forming graceful arch
	for i in range(num_steps):
		var t0: float = float(i) / float(num_steps)
		var t1: float = float(i + 1) / float(num_steps)
		var t_mid: float = (t0 + t1) * 0.5

		var p_mid_x: float = lerpf(BRIDGE_START.x, BRIDGE_END.x, t_mid)
		var p_mid_z: float = lerpf(BRIDGE_START.z, BRIDGE_END.z, t_mid)
		# Arch parabola
		var arch_lift: float = sin(t_mid * PI) * 2.8
		var p_mid_y: float = lerpf(start_y, end_y, t_mid) + arch_lift

		# Bridge segment deck
		var step_mesh: BoxMesh = BoxMesh.new()
		step_mesh.size = Vector3(bridge_width, 0.45, (span_len / float(num_steps)) * 1.05)

		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = step_mesh
		mi.material_override = _stone_mat
		mi.position = Vector3(p_mid_x, p_mid_y, p_mid_z)
		# Angle deck according to slope
		var dy: float = (end_y - start_y) / float(num_steps) + cos(t_mid * PI) * (PI * 2.8 / float(num_steps))
		mi.rotation.x = -atan2(dy, span_len / float(num_steps))
		_bridge_root.add_child(mi)

		# Stone balustrade posts on left & right sides
		for side in [-1.0, 1.0]:
			var post_mesh: BoxMesh = BoxMesh.new()
			post_mesh.size = Vector3(0.28, 0.85, 0.28)
			var post_mi: MeshInstance3D = MeshInstance3D.new()
			post_mi.mesh = post_mesh
			post_mi.material_override = _marble_mat
			post_mi.position = Vector3(p_mid_x + side * (bridge_width * 0.5 - 0.15), p_mid_y + 0.55, p_mid_z)
			_bridge_root.add_child(post_mi)

	# Stone abutment piers supporting the center span
	for pier_t in [0.33, 0.67]:
		var pier_x: float = lerpf(BRIDGE_START.x, BRIDGE_END.x, pier_t)
		var pier_z: float = lerpf(BRIDGE_START.z, BRIDGE_END.z, pier_t)
		var deck_y: float = lerpf(start_y, end_y, pier_t) + sin(pier_t * PI) * 2.8
		var bed_y: float = _get_ground_y(pier_x, pier_z, -2.5)

		var pier_mesh: CylinderMesh = CylinderMesh.new()
		pier_mesh.top_radius = 1.3
		pier_mesh.bottom_radius = 1.6
		pier_mesh.height = maxf(deck_y - bed_y + 0.2, 1.0)

		var p_mi: MeshInstance3D = MeshInstance3D.new()
		p_mi.mesh = pier_mesh
		p_mi.material_override = _stone_mat
		p_mi.position = Vector3(pier_x, (deck_y + bed_y) * 0.5, pier_z)
		_bridge_root.add_child(p_mi)

	# Ornamental Stone Lanterns at bridge entrances
	for side_x in [-1.8, 1.8]:
		_spawn_bridge_lantern(Vector3(BRIDGE_START.x + side_x, start_y + 0.8, BRIDGE_START.z))
		_spawn_bridge_lantern(Vector3(BRIDGE_END.x + side_x, end_y + 0.8, BRIDGE_END.z))

	# Collision body for bridge deck so player can walk smoothly across
	var sb: StaticBody3D = StaticBody3D.new()
	sb.name = "BridgeCollision"
	var col: CollisionShape3D = CollisionShape3D.new()
	var col_box: BoxShape3D = BoxShape3D.new()
	col_box.size = Vector3(bridge_width + 0.2, 0.6, span_len + 1.2)
	col.shape = col_box
	var mid_y: float = (start_y + end_y) * 0.5 + 1.2
	sb.position = Vector3(BRIDGE_START.x, mid_y, (BRIDGE_START.z + BRIDGE_END.z) * 0.5)
	sb.rotation.x = -atan2(end_y - start_y, span_len)
	sb.add_child(col)
	_bridge_root.add_child(sb)

func _spawn_bridge_lantern(pos: Vector3) -> void:
	var base_mesh: CylinderMesh = CylinderMesh.new()
	base_mesh.top_radius = 0.22
	base_mesh.bottom_radius = 0.28
	base_mesh.height = 0.95
	var base_mi: MeshInstance3D = MeshInstance3D.new()
	base_mi.mesh = base_mesh
	base_mi.material_override = _stone_mat
	base_mi.position = pos
	_bridge_root.add_child(base_mi)

	var lamp_mesh: BoxMesh = BoxMesh.new()
	lamp_mesh.size = Vector3(0.35, 0.40, 0.35)
	var lamp_mi: MeshInstance3D = MeshInstance3D.new()
	lamp_mi.mesh = lamp_mesh
	lamp_mi.material_override = _anemo_glow_mat
	lamp_mi.position = pos + Vector3(0.0, 0.65, 0.0)
	_bridge_root.add_child(lamp_mi)

	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(0.40, 0.92, 0.85)
	light.light_energy = 0.85
	light.omni_range = 6.5
	light.position = pos + Vector3(0.0, 0.70, 0.0)
	_bridge_root.add_child(light)

# =============================================================================
# 2. ANEMO SANCTUARY PAVILION (ĐÀI VỌNG CẢNH & ĐIỆN THỜ THẦN GIÓ)
# =============================================================================
func _build_anemo_sanctuary_pavilion() -> void:
	_pavilion_root = Node3D.new()
	_pavilion_root.name = "AnemoSanctuaryPavilion"
	add_child(_pavilion_root)

	var island_y: float = maxf(_get_ground_y(HEART_ISLAND_POS.x, HEART_ISLAND_POS.z, 3.2), 2.5)
	var pav_center: Vector3 = Vector3(HEART_ISLAND_POS.x, island_y, HEART_ISLAND_POS.z)

	# Octagonal stepped stone foundation plinth
	var base_mesh: CylinderMesh = CylinderMesh.new()
	base_mesh.top_radius = 6.2
	base_mesh.bottom_radius = 6.8
	base_mesh.height = 0.65
	base_mesh.radial_segments = 8
	var base_mi: MeshInstance3D = MeshInstance3D.new()
	base_mi.mesh = base_mesh
	base_mi.material_override = _marble_mat
	base_mi.position = pav_center + Vector3(0.0, 0.32, 0.0)
	_pavilion_root.add_child(base_mi)

	# Upper dais
	var upper_mesh: CylinderMesh = CylinderMesh.new()
	upper_mesh.top_radius = 5.2
	upper_mesh.bottom_radius = 5.6
	upper_mesh.height = 0.40
	upper_mesh.radial_segments = 8
	var upper_mi: MeshInstance3D = MeshInstance3D.new()
	upper_mi.mesh = upper_mesh
	upper_mi.material_override = _stone_mat
	upper_mi.position = pav_center + Vector3(0.0, 0.80, 0.0)
	_pavilion_root.add_child(upper_mi)

	# 6 Fluted Classical Marble Columns
	var col_radius: float = 4.2
	var col_height: float = 4.8
	for i in range(6):
		var angle: float = (float(i) / 6.0) * TAU
		var col_x: float = pav_center.x + cos(angle) * col_radius
		var col_z: float = pav_center.z + sin(angle) * col_radius

		var col_mesh: CylinderMesh = CylinderMesh.new()
		col_mesh.top_radius = 0.32
		col_mesh.bottom_radius = 0.38
		col_mesh.height = col_height
		col_mesh.radial_segments = 16

		var c_mi: MeshInstance3D = MeshInstance3D.new()
		c_mi.mesh = col_mesh
		c_mi.material_override = _marble_mat
		c_mi.position = Vector3(col_x, pav_center.y + 1.0 + col_height * 0.5, col_z)
		_pavilion_root.add_child(c_mi)

	# Classical Roof Entablature & Domed Cap
	var dome_mesh: CylinderMesh = CylinderMesh.new()
	dome_mesh.top_radius = 0.4
	dome_mesh.bottom_radius = 5.0
	dome_mesh.height = 2.2
	dome_mesh.radial_segments = 12
	var dome_mi: MeshInstance3D = MeshInstance3D.new()
	dome_mi.mesh = dome_mesh
	dome_mi.material_override = _stone_mat
	dome_mi.position = pav_center + Vector3(0.0, 1.0 + col_height + 1.1, 0.0)
	_pavilion_root.add_child(dome_mi)

	# Central Anemo Altar Pedestal
	var altar_base: CylinderMesh = CylinderMesh.new()
	altar_base.top_radius = 1.1
	altar_base.bottom_radius = 1.4
	altar_base.height = 1.1
	var ab_mi: MeshInstance3D = MeshInstance3D.new()
	ab_mi.mesh = altar_base
	ab_mi.material_override = _marble_mat
	ab_mi.position = pav_center + Vector3(0.0, 1.55, 0.0)
	_pavilion_root.add_child(ab_mi)

	# Levitating Anemo Relic Core (rotating in _process)
	_anemo_altar_core = Node3D.new()
	_anemo_altar_core.name = "AnemoRelicCore"
	_anemo_altar_core.position = pav_center + Vector3(0.0, 2.6, 0.0)
	_pavilion_root.add_child(_anemo_altar_core)

	var crystal_mesh: SphereMesh = SphereMesh.new()
	crystal_mesh.radius = 0.42
	crystal_mesh.height = 0.84
	crystal_mesh.radial_segments = 8
	crystal_mesh.rings = 6
	var cr_mi: MeshInstance3D = MeshInstance3D.new()
	cr_mi.mesh = crystal_mesh
	cr_mi.material_override = _anemo_glow_mat
	_anemo_altar_core.add_child(cr_mi)

	# Altar Light
	_anemo_altar_light = OmniLight3D.new()
	_anemo_altar_light.light_color = Color(0.25, 0.95, 0.88)
	_anemo_altar_light.light_energy = 2.8
	_anemo_altar_light.omni_range = 9.0
	_anemo_altar_core.add_child(_anemo_altar_light)

	# Physical collision for the pavilion floor & altar
	var sb: StaticBody3D = StaticBody3D.new()
	var col_shape: CollisionShape3D = CollisionShape3D.new()
	var cyl_shape: CylinderShape3D = CylinderShape3D.new()
	cyl_shape.radius = 6.2
	cyl_shape.height = 1.2
	col_shape.shape = cyl_shape
	sb.position = pav_center + Vector3(0.0, 0.6, 0.0)
	sb.add_child(col_shape)
	_pavilion_root.add_child(sb)

# =============================================================================
# 3. LAKESIDE STILT BOATHOUSE & FISHER'S PIER (NHÀ BÈ & BẾN THUYỀN VEN HỒ)
# =============================================================================
func _build_lakeside_boathouse_and_pier() -> void:
	_boathouse_root = Node3D.new()
	_boathouse_root.name = "LakesideBoathouseAndPier"
	add_child(_boathouse_root)

	var shore_y: float = maxf(_get_ground_y(BOATHOUSE_POS.x, BOATHOUSE_POS.z, 1.2), 0.8)
	var pier_elevation: float = shore_y + 0.35
	var pier_len: float = 18.0
	var pier_width: float = 3.2

	# Pier deck extending eastward into the lake (+X direction)
	var deck_mesh: BoxMesh = BoxMesh.new()
	deck_mesh.size = Vector3(pier_len, 0.25, pier_width)
	var deck_mi: MeshInstance3D = MeshInstance3D.new()
	deck_mi.mesh = deck_mesh
	deck_mi.material_override = _plank_mat
	deck_mi.position = Vector3(BOATHOUSE_POS.x + pier_len * 0.5, pier_elevation, BOATHOUSE_POS.z)
	_boathouse_root.add_child(deck_mi)

	# Submerged wooden stilt pilings along the pier
	var num_pilings: int = 5
	for p in range(num_pilings):
		var px: float = BOATHOUSE_POS.x + 2.0 + float(p) * (pier_len - 3.0) / float(num_pilings - 1)
		for side in [-1.0, 1.0]:
			var pz: float = BOATHOUSE_POS.z + side * (pier_width * 0.5 - 0.25)
			var bed_y: float = _get_ground_y(px, pz, -1.8)

			var post_mesh: CylinderMesh = CylinderMesh.new()
			post_mesh.top_radius = 0.16
			post_mesh.bottom_radius = 0.18
			post_mesh.height = maxf(pier_elevation - bed_y + 0.5, 1.2)
			var post_mi: MeshInstance3D = MeshInstance3D.new()
			post_mi.mesh = post_mesh
			post_mi.material_override = _wood_mat
			post_mi.position = Vector3(px, (pier_elevation + bed_y) * 0.5, pz)
			_boathouse_root.add_child(post_mi)

	# Rustic Boathouse Shelter on shore end
	var bh_x: float = BOATHOUSE_POS.x - 3.5
	var bh_z: float = BOATHOUSE_POS.z
	var bh_y: float = shore_y

	# Walls (timber half-timber frame)
	var wall_mesh: BoxMesh = BoxMesh.new()
	wall_mesh.size = Vector3(5.5, 3.2, 4.8)
	var wall_mi: MeshInstance3D = MeshInstance3D.new()
	wall_mi.mesh = wall_mesh
	wall_mi.material_override = _wood_mat
	wall_mi.position = Vector3(bh_x, bh_y + 1.6, bh_z)
	_boathouse_root.add_child(wall_mi)

	# Pitched Thatch Roof
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = Vector3(5.2, 2.0, 6.0)
	var roof_mi: MeshInstance3D = MeshInstance3D.new()
	roof_mi.mesh = roof_mesh
	roof_mi.material_override = _thatch_mat
	roof_mi.position = Vector3(bh_x, bh_y + 3.2 + 1.0, bh_z)
	roof_mi.rotation.y = deg_to_rad(90.0)
	_boathouse_root.add_child(roof_mi)

	# Moored Wooden Skiff tied to end of pier
	var skiff_mesh: BoxMesh = BoxMesh.new()
	skiff_mesh.size = Vector3(3.4, 0.6, 1.4)
	var skiff_mi: MeshInstance3D = MeshInstance3D.new()
	skiff_mi.mesh = skiff_mesh
	skiff_mi.material_override = _wood_mat
	skiff_mi.position = Vector3(BOATHOUSE_POS.x + pier_len + 1.2, 0.15, BOATHOUSE_POS.z - 1.2)
	skiff_mi.rotation.y = deg_to_rad(15.0)
	_boathouse_root.add_child(skiff_mi)

	# Hanging amber lantern on pier post
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1.0, 0.78, 0.45)
	light.light_energy = 1.4
	light.omni_range = 8.5
	light.position = Vector3(BOATHOUSE_POS.x + pier_len - 0.5, pier_elevation + 1.6, BOATHOUSE_POS.z)
	_boathouse_root.add_child(light)

	# Collision
	var sb: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(pier_len + 5.5, 1.5, pier_width + 2.0)
	col.shape = box
	sb.position = Vector3(BOATHOUSE_POS.x + pier_len * 0.4, pier_elevation - 0.5, BOATHOUSE_POS.z)
	sb.add_child(col)
	_boathouse_root.add_child(sb)

# =============================================================================
# 4. EMERALD CASCADE WATERFALL (THÁC NƯỚC ĐỔ VÀO HỒ)
# =============================================================================
func _build_emerald_cascade_waterfall() -> void:
	_waterfall_root = Node3D.new()
	_waterfall_root.name = "EmeraldCascadeWaterfall"
	add_child(_waterfall_root)

	var top_pos: Vector3 = WATERFALL_TOP
	var bot_pos: Vector3 = WATERFALL_BOTTOM
	var fall_h: float = top_pos.y - bot_pos.y
	var fall_dist: float = (Vector2(top_pos.x, top_pos.z) - Vector2(bot_pos.x, bot_pos.z)).length()

	# Tumbling water sheet (quad mesh tilted along cliff face)
	var sheet_mesh: QuadMesh = QuadMesh.new()
	sheet_mesh.size = Vector2(8.5, sqrt(fall_h * fall_h + fall_dist * fall_dist))
	var sheet_mi: MeshInstance3D = MeshInstance3D.new()
	sheet_mi.mesh = sheet_mesh
	sheet_mi.material_override = _waterfall_mat
	sheet_mi.position = (top_pos + bot_pos) * 0.5
	sheet_mi.rotation.y = atan2(bot_pos.x - top_pos.x, bot_pos.z - top_pos.z)
	sheet_mi.rotation.x = -atan2(fall_dist, fall_h)
	_waterfall_root.add_child(sheet_mi)

	# Stepped granite crags flanking waterfall
	for i in range(4):
		var t: float = float(i) / 3.0
		var rock_pos: Vector3 = lerp(top_pos, bot_pos, t)
		for side in [-1.0, 1.0]:
			var crag_mesh: BoxMesh = BoxMesh.new()
			crag_mesh.size = Vector3(3.2, 2.5, 3.8)
			var crag_mi: MeshInstance3D = MeshInstance3D.new()
			crag_mi.mesh = crag_mesh
			crag_mi.material_override = _stone_mat
			crag_mi.position = rock_pos + Vector3(side * 5.2, -0.6, 0.0)
			_waterfall_root.add_child(crag_mi)

	# Plunge pool foam disc at bottom of waterfall
	var foam_mesh: CylinderMesh = CylinderMesh.new()
	foam_mesh.top_radius = 6.5
	foam_mesh.bottom_radius = 6.5
	foam_mesh.height = 0.05
	var foam_mi: MeshInstance3D = MeshInstance3D.new()
	foam_mi.mesh = foam_mesh
	foam_mi.material_override = _waterfall_mat
	foam_mi.position = bot_pos + Vector3(0.0, 0.05, 0.0)
	_waterfall_root.add_child(foam_mi)

# =============================================================================
# 5. WATER LILY PADS & SHORELINE REEDS
# =============================================================================
func _build_water_lilies_and_reeds() -> void:
	var lily_root: Node3D = Node3D.new()
	lily_root.name = "WaterLiliesAndReeds"
	add_child(lily_root)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9922

	# Clusters of water lily pads in the shallow western bay
	for i in range(16):
		var lx: float = BOATHOUSE_POS.x + rng.randf_range(4.0, 22.0)
		var lz: float = BOATHOUSE_POS.z + rng.randf_range(-14.0, 14.0)

		var pad_mesh: CylinderMesh = CylinderMesh.new()
		pad_mesh.top_radius = rng.randf_range(0.45, 0.85)
		pad_mesh.bottom_radius = pad_mesh.top_radius
		pad_mesh.height = 0.02
		pad_mesh.radial_segments = 12

		var p_mi: MeshInstance3D = MeshInstance3D.new()
		p_mi.mesh = pad_mesh
		p_mi.material_override = _water_lily_mat
		p_mi.position = Vector3(lx, 0.02, lz)
		p_mi.rotation.y = rng.randf_range(0.0, TAU)
		lily_root.add_child(p_mi)

	# Clustered shoreline reeds along northern and eastern banks
	for i in range(24):
		var angle: float = rng.randf_range(0.0, TAU)
		var rad: float = rng.randf_range(115.0, 130.0)
		var rx: float = LAKE_CENTER.x + cos(angle) * rad
		var rz: float = LAKE_CENTER.z + sin(angle) * rad
		var ry: float = _get_ground_y(rx, rz, 0.2)
		if ry > -0.4 and ry < 1.2:
			var reed_mesh: CylinderMesh = CylinderMesh.new()
			reed_mesh.top_radius = 0.04
			reed_mesh.bottom_radius = 0.06
			reed_mesh.height = rng.randf_range(1.4, 2.2)
			var r_mi: MeshInstance3D = MeshInstance3D.new()
			r_mi.mesh = reed_mesh
			r_mi.material_override = _reed_mat
			r_mi.position = Vector3(rx, ry + reed_mesh.height * 0.5, rz)
			r_mi.rotation.z = rng.randf_range(-0.1, 0.1)
			lily_root.add_child(r_mi)

func _process(delta: float) -> void:
	_anim_time += delta
	# Rotate the levitating anemo relic core in the sanctuary pavilion
	if _anemo_altar_core:
		_anemo_altar_core.rotation.y += delta * 1.2
		_anemo_altar_core.position.y = (HEART_ISLAND_POS.y + 2.6) + sin(_anim_time * 2.2) * 0.12

func _apply_culling_and_shadow_optimizations() -> void:
	for child in find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = child as MeshInstance3D
		if not mi:
			continue
		var mname: String = mi.name.to_lower()
		var p_name: String = mi.get_parent().name.to_lower() if mi.get_parent() else ""
		var is_major_landmark: bool = ("bridge" in p_name or "pavilion" in p_name or "boathouse" in p_name or "waterfall" in p_name or "cascade" in p_name or "altar" in mname)
		if is_major_landmark:
			mi.visibility_range_end = 260.0
			mi.visibility_range_end_margin = 30.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		else:
			# Water lilies, reeds, pier pylons, planks, shoreline clutter
			mi.visibility_range_end = 80.0
			mi.visibility_range_end_margin = 15.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
