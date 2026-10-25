class_name CircularMinimapHUD
extends Control

## Living Planet Sandbox — Genshin-Style Circular Radar Minimap HUD (Block 53)
## Features:
## 1. 140px Ornate Circular Radar located at screen top-left (X: 24, Y: 24)
## 2. Frosted glassmorphic backdrop with rotating North dial and brass compass rim
## 3. Real-time player chevron with directional camera FOV cone
## 4. Landmark radar blips: Grand Emerald Lake, Waypoints, Great Windmill, Haven Harbor, Castle
## 5. Nearby Exploration Chest markers (shimmering gold diamonds within radar radius)
## 6. Location subtitle banner displaying current biome / POI name

const MINIMAP_RADIUS: float = 65.0
const RADAR_WORLD_RANGE: float = 110.0 # World distance mapped to edge of radar

var player_ref: Node3D = null
var camera_ref: Camera3D = null
var chest_system_ref: Node3D = null
var waypoint_manager_ref: Node3D = null
var flight_rings_ref: Node3D = null
var flora_ref: Node3D = null

var player_pos: Vector3 = Vector3.ZERO
var player_yaw: float = 0.0 # In radians
var camera_yaw: float = 0.0

var current_location_name: String = "Làng Cảng Haven"
var font: Font = null
var _pulse_time: float = 0.0

# Landmark definitions for radar tracking
var landmarks: Array[Dictionary] = [
	{"id": "haven", "name": "Cảng Haven", "pos": Vector3(14.0, 1.2, 4.0), "icon": "⚓", "color": Color(0.4, 0.8, 1.0)},
	{"id": "grand_lake", "name": "Hồ Ngọc Bích", "pos": Vector3(95.0, 0.5, 85.0), "icon": "🌊", "color": Color(0.2, 0.9, 0.7)},
	{"id": "heart_island", "name": "Đảo Trái Tim", "pos": Vector3(95.0, 3.6, 85.0), "icon": "✦", "color": Color(0.25, 0.95, 0.85)},
	{"id": "windmill", "name": "Cối Xay Gió", "pos": Vector3(105.0, 17.5, -45.0), "icon": "⚙", "color": Color(0.95, 0.8, 0.3)},
	{"id": "castle", "name": "Thành Cổ", "pos": Vector3(-28.0, 7.5, -22.0), "icon": "🏰", "color": Color(0.9, 0.7, 0.35)},
	{"id": "windshear", "name": "Hẻm Gió Hú", "pos": Vector3(-35.0, 14.0, 150.0), "icon": "🌉", "color": Color(0.85, 0.6, 0.95)},
	{"id": "skyspire", "name": "Đỉnh Trời", "pos": Vector3(-125.0, 36.0, -110.0), "icon": "🏔", "color": Color(0.8, 0.9, 1.0)},
	{"id": "anemo_statue", "name": "Tượng Thần Gió", "pos": Vector3(-18.0, 16.1, -18.0), "icon": "🗽", "color": Color(0.2, 0.95, 0.85)},
	{"id": "wild_camp", "name": "Trại Dã Ngoại", "pos": Vector3(7.5, 3.8, 12.0), "icon": "🏕️", "color": Color(1.0, 0.65, 0.25)},
	{"id": "shrine_depths", "name": "Đền Ngàn Đời", "pos": Vector3(-30.0, 4.2, 25.0), "icon": "⛩️", "color": Color(0.3, 0.9, 1.0)},
	{"id": "torch_puzzle", "name": "Đài Hỏa Viêm", "pos": Vector3(25.0, 3.9, -25.0), "icon": "🔥", "color": Color(1.0, 0.5, 0.2)},
	{"id": "anemo_geyser", "name": "Mạch Phong Geyser", "pos": Vector3(-15.0, 2.92, 45.0), "icon": "🌪️", "color": Color(0.35, 0.95, 0.85)},
	{"id": "ancient_stele", "name": "Bia Cổ Ngữ", "pos": Vector3(14.0, 6.54, -18.0), "icon": "📜", "color": Color(0.95, 0.85, 0.35)},
	{"id": "mythic_stag", "name": "Bạch Hươu Thần Thoại", "pos": Vector3(-45.0, 5.4, -15.0), "icon": "🦌", "color": Color(1.0, 0.90, 0.45)},
	{"id": "aerial_trial", "name": "Thử Luyện Lướt Gió", "pos": Vector3(-12.0, 6.25, 12.0), "icon": "⏱️", "color": Color(0.40, 0.95, 0.75)},
	{"id": "grizzly_patriarch", "name": "Bá Vương Hùng", "pos": Vector3(-135.0, 72.0, -130.0), "icon": "🐻", "color": Color(0.85, 0.72, 0.55)},
	{"id": "hydro_puzzle", "name": "Đài Nước Thủy Thần", "pos": Vector3(75.0, 0.5, 70.0), "icon": "🌊", "color": Color(0.20, 0.85, 1.0)}
]

func _init() -> void:
	name = "CircularMinimapHUD"
	custom_minimum_size = Vector2(170, 190)
	size = Vector2(170, 190)
	position = Vector2(24, 24)
	mouse_filter = MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font

func _ready() -> void:
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = 24.0
	offset_right = 24.0 + 170.0
	offset_top = 24.0
	offset_bottom = 24.0 + 190.0
	if font == null:
		font = ThemeDB.fallback_font

func setup(p_player: Node3D, p_camera: Camera3D = null, p_chests: Node3D = null, p_waypoints: Node3D = null, p_rings: Node3D = null, p_flora: Node3D = null) -> void:
	player_ref = p_player
	camera_ref = p_camera
	chest_system_ref = p_chests
	waypoint_manager_ref = p_waypoints
	flight_rings_ref = p_rings
	flora_ref = p_flora

func _process(delta: float) -> void:
	_pulse_time += delta

	# Track player transform
	if player_ref and is_instance_valid(player_ref):
		player_pos = player_ref.global_position if player_ref.is_inside_tree() else player_ref.position
		player_yaw = player_ref.rotation.y

	# Track camera transform
	if camera_ref and is_instance_valid(camera_ref):
		camera_yaw = camera_ref.rotation.y
	else:
		camera_yaw = player_yaw

	_update_location_name()
	queue_redraw()

func _update_location_name() -> void:
	var closest_name: String = "Vùng Hoang Dã"
	var closest_dist: float = 65.0 # Max distance to display named landmark

	for lm in landmarks:
		var d: float = Vector2(player_pos.x, player_pos.z).distance_to(Vector2(lm["pos"].x, lm["pos"].z))
		if d < closest_dist:
			closest_dist = d
			closest_name = lm["name"]

	current_location_name = closest_name

func _draw() -> void:
	var center: Vector2 = Vector2(80, 80)
	var r: float = MINIMAP_RADIUS

	# 1. Outer glow drop shadow
	draw_circle(center, r + 4.0, Color(0.0, 0.0, 0.0, 0.45))

	# 2. Glassmorphic frosted dark circular base
	draw_circle(center, r, Color(0.07, 0.10, 0.14, 0.88))

	# 3. Concentric radar range rings (40m, 80m)
	var r_40m: float = r * (40.0 / RADAR_WORLD_RANGE)
	var r_80m: float = r * (80.0 / RADAR_WORLD_RANGE)
	draw_arc(center, r_40m, 0.0, TAU, 32, Color(0.35, 0.50, 0.65, 0.22), 1.0, true)
	draw_arc(center, r_80m, 0.0, TAU, 40, Color(0.35, 0.50, 0.65, 0.28), 1.0, true)

	# 4. Subtle crosshairs
	draw_line(center - Vector2(r - 5, 0), center + Vector2(r - 5, 0), Color(0.4, 0.6, 0.8, 0.15), 1.0)
	draw_line(center - Vector2(0, r - 5), center + Vector2(0, r - 5), Color(0.4, 0.6, 0.8, 0.15), 1.0)

	# 5. Grand Emerald Lake Water Boundary Overlay (if lake within range)
	_draw_lake_boundary(center, r)

	# 6. Waypoints and Landmark Blips
	_draw_landmarks_and_waypoints(center, r)

	# 7. Exploration Chests Radar Blips
	_draw_chest_blips(center, r)

	# 7b. Anemo Flight Rings Highway Blips
	_draw_flight_ring_blips(center, r)

	# 7c. Luminescent Star Lotus Lake Blips
	_draw_flora_blips(center, r)

	# 8. Player Camera FOV Cone & Direction Arrow
	_draw_player_fov_and_arrow(center)

	# 9. Outer Golden Ornate Rim & Cardinal Dial
	_draw_outer_dial(center, r)

	# 10. Location Banner & Coordinates
	_draw_location_banner(center, r)

func _world_to_radar(world_x: float, world_z: float, center: Vector2, max_r: float) -> Dictionary:
	var dx: float = world_x - player_pos.x
	var dz: float = world_z - player_pos.z
	var dist: float = Vector2(dx, dz).length()

	# Rotate relative to camera facing (Up = Camera Forward)
	var angle: float = atan2(dz, dx) - (camera_yaw + PI * 0.5)
	var radar_dist: float = (dist / RADAR_WORLD_RANGE) * max_r
	var is_clamped: bool = false

	if radar_dist > max_r - 6.0:
		radar_dist = max_r - 6.0
		is_clamped = true

	var offset: Vector2 = Vector2(cos(angle), sin(angle)) * radar_dist
	return {
		"pos": center + offset,
		"clamped": is_clamped,
		"dist": dist
	}

func _draw_lake_boundary(center: Vector2, max_r: float) -> void:
	# Grand Emerald Lake Center: (95, 85), Radius: 50m
	var lake_pos: Vector2 = Vector2(95.0, 85.0)
	var p_2d: Vector2 = Vector2(player_pos.x, player_pos.z)
	var dist_to_lake: float = p_2d.distance_to(lake_pos)

	if dist_to_lake < RADAR_WORLD_RANGE + 60.0:
		var lake_radar = _world_to_radar(lake_pos.x, lake_pos.y, center, max_r)
		var lake_screen_r: float = (48.0 / RADAR_WORLD_RANGE) * max_r
		draw_circle(lake_radar["pos"], minf(lake_screen_r, 32.0), Color(0.12, 0.45, 0.55, 0.25))
		draw_arc(lake_radar["pos"], minf(lake_screen_r, 32.0), 0.0, TAU, 24, Color(0.25, 0.85, 0.75, 0.35), 1.2, true)

func _draw_landmarks_and_waypoints(center: Vector2, max_r: float) -> void:
	# Landmarks
	for lm in landmarks:
		var r_data = _world_to_radar(lm["pos"].x, lm["pos"].z, center, max_r)
		var blip_pos: Vector2 = r_data["pos"]
		var alpha: float = 0.65 if r_data["clamped"] else 0.95
		var col: Color = lm["color"]
		col.a = alpha

		# Draw circular marker badge
		draw_circle(blip_pos, 4.0, Color(0.08, 0.12, 0.16, 0.9))
		draw_circle(blip_pos, 2.8, col)

	# Active Waypoints from WaypointNetworkManager
	if waypoint_manager_ref and waypoint_manager_ref.has_method("get_all_waypoints"):
		var wps = waypoint_manager_ref.get_all_waypoints()
		for wp in wps:
			var wp_pos = wp.get("pos", Vector3.ZERO)
			var r_data = _world_to_radar(wp_pos.x, wp_pos.z, center, max_r)
			var b_pos: Vector2 = r_data["pos"]
			var wp_col: Color = Color(0.20, 0.90, 0.85, 0.95)
			# Diamond icon
			var pts: PackedVector2Array = [
				b_pos + Vector2(0, -3.5),
				b_pos + Vector2(3.5, 0),
				b_pos + Vector2(0, 3.5),
				b_pos + Vector2(-3.5, 0)
			]
			draw_colored_polygon(pts, wp_col)

func _draw_chest_blips(center: Vector2, max_r: float) -> void:
	if chest_system_ref and "get_chest_count" in chest_system_ref:
		var chests = chest_system_ref.get("_chests")
		if chests is Dictionary:
			for cid in chests:
				var c_info = chests[cid]
				if c_info.get("is_open", false):
					continue
				var c_node: Node3D = c_info.get("node")
				if not c_node:
					continue
				var c_pos: Vector3 = c_node.global_position if c_node.is_inside_tree() else c_node.position
				var dist: float = Vector2(player_pos.x, player_pos.z).distance_to(Vector2(c_pos.x, c_pos.z))

				# Only display chests within detection range (85m)
				if dist <= 85.0:
					var r_data = _world_to_radar(c_pos.x, c_pos.z, center, max_r)
					var b_pos: Vector2 = r_data["pos"]
					var pulse: float = 0.8 + sin(_pulse_time * 4.5) * 0.2
					var gold_col: Color = Color(1.0, 0.85, 0.25, pulse)

					# Sparkling mini diamond
					var diamond: PackedVector2Array = [
						b_pos + Vector2(0, -3.0),
						b_pos + Vector2(3.0, 0),
						b_pos + Vector2(0, 3.0),
						b_pos + Vector2(-3.0, 0)
					]
					draw_colored_polygon(diamond, gold_col)
					draw_polyline(diamond, Color(0.2, 0.15, 0.05, 0.9), 1.0)

func _draw_flight_ring_blips(center: Vector2, max_r: float) -> void:
	if flight_rings_ref and flight_rings_ref.has_method("get_ring_positions"):
		var poses: Array = flight_rings_ref.get_ring_positions()
		for i in range(poses.size()):
			var r_pos: Vector3 = poses[i]
			var dist: float = Vector2(player_pos.x, player_pos.z).distance_to(Vector2(r_pos.x, r_pos.z))
			if dist <= 140.0:
				var r_data = _world_to_radar(r_pos.x, r_pos.z, center, max_r)
				var b_pos: Vector2 = r_data["pos"]
				var pulse: float = 0.8 + sin(_pulse_time * 3.5 + float(i) * 0.8) * 0.2
				var col: Color = Color(0.25, 0.95, 0.85, pulse)
				draw_arc(b_pos, 3.5, 0.0, TAU, 16, col, 1.2, true)
				draw_circle(b_pos, 1.5, Color(1.0, 0.92, 0.45, pulse))

func _draw_flora_blips(center: Vector2, max_r: float) -> void:
	if flora_ref:
		var lotuses = flora_ref.get("_lotuses")
		if lotuses is Array:
			for l in lotuses:
				if l.get("harvested", false):
					continue
				var l_pos: Vector3 = l.get("pos", Vector3.ZERO)
				var dist: float = Vector2(player_pos.x, player_pos.z).distance_to(Vector2(l_pos.x, l_pos.z))
				if dist <= 65.0:
					var r_data = _world_to_radar(l_pos.x, l_pos.z, center, max_r)
					var b_pos: Vector2 = r_data["pos"]
					var pulse: float = 0.75 + sin(_pulse_time * 2.8) * 0.25
					draw_circle(b_pos, 2.2, Color(0.2, 0.95, 0.85, pulse))

func _draw_player_fov_and_arrow(center: Vector2) -> void:
	# Relative player forward heading vs camera
	var rel_heading: float = player_yaw - camera_yaw

	# 1. Camera FOV Cone (semi-transparent fan)
	var fov_span: float = deg_to_rad(45.0)
	var fov_len: float = 24.0
	var fov_pts: PackedVector2Array = [center]
	var steps: int = 8
	for i in range(steps + 1):
		var a: float = -PI * 0.5 - fov_span * 0.5 + (fov_span * float(i) / float(steps))
		fov_pts.append(center + Vector2(cos(a), sin(a)) * fov_len)
	draw_colored_polygon(fov_pts, Color(0.35, 0.75, 1.0, 0.18))

	# 2. Player Chevron Arrow pointing in player direction
	var arrow_angle: float = -PI * 0.5 + rel_heading
	var forward: Vector2 = Vector2(cos(arrow_angle), sin(arrow_angle))
	var right: Vector2 = Vector2(-forward.y, forward.x)

	var p_tip: Vector2 = center + forward * 6.5
	var p_left: Vector2 = center - forward * 4.0 - right * 4.5
	var p_notch: Vector2 = center - forward * 2.0
	var p_right: Vector2 = center - forward * 4.0 + right * 4.5

	var chevron: PackedVector2Array = [p_tip, p_left, p_notch, p_right]
	draw_colored_polygon(chevron, Color(1.0, 0.92, 0.40, 1.0)) # Warm golden player chevron
	draw_polyline(chevron, Color(0.1, 0.08, 0.05, 0.8), 1.2)

func _draw_outer_dial(center: Vector2, max_r: float) -> void:
	# 1. Brass rim
	draw_arc(center, max_r, 0.0, TAU, 48, Color(0.78, 0.65, 0.32, 0.95), 2.5, true)
	draw_arc(center, max_r + 2.0, 0.0, TAU, 48, Color(0.35, 0.28, 0.15, 0.8), 1.0, true)

	# 2. Cardinal Dial with North Pointer
	# World North is (0, -1) in 2D Z axis
	var north_angle: float = -PI * 0.5 - camera_yaw
	var n_pos: Vector2 = center + Vector2(cos(north_angle), sin(north_angle)) * (max_r - 8.0)

	# North indicator badge
	draw_circle(n_pos, 5.5, Color(0.10, 0.12, 0.16, 0.95))
	draw_circle(n_pos, 4.5, Color(0.92, 0.32, 0.28, 0.95)) # Red North marker
	if font:
		draw_string(font, n_pos + Vector2(-3.5, 3.5), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color.WHITE)

func _draw_location_banner(center: Vector2, max_r: float) -> void:
	if not font:
		return
	var banner_y: float = center.y + max_r + 8.0
	var bg_rect: Rect2 = Rect2(center.x - 65.0, banner_y, 130.0, 20.0)

	# Frosted dark banner capsule
	draw_rect(bg_rect, Color(0.06, 0.08, 0.12, 0.85), true)
	draw_rect(bg_rect, Color(0.70, 0.58, 0.28, 0.65), false, 1.0)

	# Location title
	draw_string(font, Vector2(center.x - 60.0, banner_y + 14.0), current_location_name, HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color(0.95, 0.92, 0.82))

	# Coords readout
	var coord_str: String = "X: %d  Z: %d" % [int(player_pos.x), int(player_pos.z)]
	draw_string(font, Vector2(center.x - 60.0, banner_y + 30.0), coord_str, HORIZONTAL_ALIGNMENT_CENTER, 120, 9, Color(0.65, 0.75, 0.85, 0.75))
