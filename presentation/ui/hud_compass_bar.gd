class_name HUDCompassBar
extends Control

## Living Planet Sandbox — Block 45 Genshin-Style Dynamic Waypoint Compass HUD
## Sleek, frosted horizontal compass ribbon showing cardinal directions and
## real-time distance waypoints for Haven Harbor, Ancient Castle Citadel,
## Drivable Skiff Boat, and Emerald Cove Reefs.

var _camera_ref: Camera3D = null
var _player_ref: Node3D = null
var _boat_ref: Node3D = null
var _network_ref: Node3D = null

var waypoints: Array[Dictionary] = [
	{
		"id": "village",
		"title": "Haven",
		"icon": "⚓",
		"pos": Vector3(13.8, 1.2, 4.2),
		"color": Color(0.40, 0.78, 1.0)
	},
	{
		"id": "cave",
		"title": "Grotto",
		"icon": "💎",
		"pos": Vector3(-78.0, 16.5, -72.0),
		"color": Color(0.35, 0.95, 0.90)
	},
	{
		"id": "grand_lake",
		"title": "Hồ Ngọc Bích",
		"icon": "🏞️",
		"pos": Vector3(95.0, 0.5, 85.0),
		"color": Color(0.20, 0.90, 0.65)
	},
	{
		"id": "castle",
		"title": "Citadel",
		"icon": "🏰",
		"pos": Vector3(-28.0, 7.5, -22.0),
		"color": Color(0.95, 0.75, 0.35)
	},
	{
		"id": "skyspire",
		"title": "Skyspire",
		"icon": "🏔️",
		"pos": Vector3(-125.0, 36.0, -110.0),
		"color": Color(0.85, 0.92, 1.0)
	},
	{
		"id": "cove",
		"title": "Cove",
		"icon": "🌊",
		"pos": Vector3(22.0, -1.5, 18.0),
		"color": Color(0.30, 0.95, 0.85)
	}
]

const COMPASS_WIDTH: float = 380.0
const COMPASS_HEIGHT: float = 36.0
const FOV_DEGREES: float = 110.0

func _init() -> void:
	name = "HUDCompassBar"
	custom_minimum_size = Vector2(COMPASS_WIDTH, COMPASS_HEIGHT)
	mouse_filter = MOUSE_FILTER_IGNORE

func _ready() -> void:
	# Center at top
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -COMPASS_WIDTH * 0.5
	offset_right = COMPASS_WIDTH * 0.5
	offset_top = 14.0
	offset_bottom = 14.0 + COMPASS_HEIGHT

func setup(camera: Camera3D, player: Node3D, boat: Node3D = null, network: Node3D = null) -> void:
	_camera_ref = camera
	_player_ref = player
	_boat_ref = boat
	_network_ref = network

func set_waypoint_network(network: Node3D) -> void:
	_network_ref = network

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	# 1. Frosted dark glass ribbon background
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.06, 0.08, 0.12, 0.65), true)
	draw_rect(rect, Color(0.85, 0.75, 0.45, 0.35), false, 1.5)

	# Center reticle mark
	var cx: float = size.x * 0.5
	draw_line(Vector2(cx, 0.0), Vector2(cx, 8.0), Color(1.0, 0.85, 0.40, 0.95), 2.0)
	draw_line(Vector2(cx, size.y - 8.0), Vector2(cx, size.y), Color(1.0, 0.85, 0.40, 0.95), 2.0)

	# Determine current yaw heading in degrees [0, 360)
	var cam_yaw: float = 0.0
	if _camera_ref and _camera_ref.is_inside_tree():
		cam_yaw = rad_to_deg(_camera_ref.global_rotation.y)
	elif _player_ref and _player_ref.is_inside_tree():
		cam_yaw = rad_to_deg(_player_ref.global_rotation.y)

	var p_pos: Vector3 = Vector3.ZERO
	if _player_ref and _player_ref.is_inside_tree():
		p_pos = _player_ref.global_position

	# 2. Draw Cardinal & Intercardinal Ticks
	var cardinals: Array[Dictionary] = [
		{"deg": 0.0, "label": "N", "is_major": true},
		{"deg": 45.0, "label": "NE", "is_major": false},
		{"deg": 90.0, "label": "E", "is_major": true},
		{"deg": 135.0, "label": "SE", "is_major": false},
		{"deg": 180.0, "label": "S", "is_major": true},
		{"deg": 225.0, "label": "SW", "is_major": false},
		{"deg": 270.0, "label": "W", "is_major": true},
		{"deg": 315.0, "label": "NW", "is_major": false}
	]

	var font: Font = ThemeDB.fallback_font
	var font_size: int = 12

	for c in cardinals:
		var deg: float = c["deg"]
		var diff: float = fposmod((deg - cam_yaw) + 180.0, 360.0) - 180.0

		if absf(diff) <= (FOV_DEGREES * 0.5):
			var norm: float = diff / (FOV_DEGREES * 0.5)
			var x: float = cx + norm * (COMPASS_WIDTH * 0.46)
			var label: String = c["label"]
			var col: Color = Color(1.0, 0.88, 0.45) if c["is_major"] else Color(0.75, 0.82, 0.88, 0.70)

			# Tick mark
			draw_line(Vector2(x, size.y - 6.0), Vector2(x, size.y - 2.0), col, 1.0)
			# Text
			var str_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			draw_string(font, Vector2(x - str_size.x * 0.5, 16.0), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, col)

	# 3. Dynamic Waypoint Markers
	var wp_list: Array[Dictionary] = waypoints.duplicate()
	if _boat_ref and _boat_ref.is_inside_tree():
		wp_list.append({
			"id": "boat",
			"title": "Skiff",
			"icon": "⛵",
			"pos": _boat_ref.global_position,
			"color": Color(0.45, 0.95, 0.55)
		})

	if _network_ref and _network_ref.has_method("get_waypoints"):
		for nwp in _network_ref.get_waypoints():
			wp_list.append({
				"id": nwp.waypoint_id,
				"title": nwp.waypoint_name,
				"icon": "✨" if nwp.is_unlocked else "🔴",
				"pos": nwp.global_position if nwp.is_inside_tree() else nwp.position,
				"color": Color(0.20, 0.95, 0.88) if nwp.is_unlocked else Color(0.95, 0.35, 0.25)
			})

	for wp in wp_list:
		var w_pos: Vector3 = wp["pos"]
		var dist: float = p_pos.distance_to(w_pos)
		var angle_to_wp: float = rad_to_deg(atan2(w_pos.x - p_pos.x, w_pos.z - p_pos.z))
		# Normalize angle to heading
		var diff: float = fposmod((angle_to_wp - cam_yaw) + 180.0, 360.0) - 180.0

		if absf(diff) <= (FOV_DEGREES * 0.5):
			var norm: float = diff / (FOV_DEGREES * 0.5)
			var x: float = cx + norm * (COMPASS_WIDTH * 0.46)
			var icon_text: String = "%s %.0fm" % [wp["icon"], dist]
			var col: Color = wp["color"]
			var str_sz: Vector2 = font.get_string_size(icon_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
			draw_string(font, Vector2(x - str_sz.x * 0.5, size.y - 5.0), icon_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, col)
