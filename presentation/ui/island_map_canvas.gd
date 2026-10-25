class_name IslandMapCanvas
extends Control

## Top-Down Cartographic Island Map for Living Planet Sandbox.
## Renders a 2D topographic vector map of the 720m continent,
## displaying coastline, regional biomes, discovered POIs, and player position/heading.

var world_radius: float = 360.0
var player_pos: Vector3 = Vector3(7.5, 3.8, 3.5)
var player_heading: float = 0.0 # Degrees from North (0° = North, 90° = East)
var pois: Array[Dictionary] = []
var discovered_count: int = 0
var font: Font = null

var show_wildlife_heatmaps: bool = true
var herbivore_positions: Array[Vector3] = []
var predator_positions: Array[Vector3] = []
var disturbance_trail: Array[Vector3] = []

func _init() -> void:
	custom_minimum_size = Vector2(380, 380)
	size = Vector2(380, 380)
	font = ThemeDB.fallback_font

func update_player(pos: Vector3, heading_deg: float) -> void:
	player_pos = pos
	player_heading = heading_deg
	queue_redraw()

func update_pois(poi_list: Array[Dictionary]) -> void:
	pois = poi_list
	discovered_count = 0
	for p in pois:
		if p.get("discovered", false):
			discovered_count += 1
	queue_redraw()

func toggle_wildlife_heatmaps() -> bool:
	show_wildlife_heatmaps = not show_wildlife_heatmaps
	queue_redraw()
	return show_wildlife_heatmaps

func set_wildlife_heatmaps_visible(p_visible: bool) -> void:
	show_wildlife_heatmaps = p_visible
	queue_redraw()

func update_wildlife_telemetry(herbivores: Array, predators: Array, trail: Array = []) -> void:
	herbivore_positions.clear()
	for h in herbivores:
		if h is Vector3:
			herbivore_positions.append(h)
		elif h is Dictionary and h.has("position"):
			herbivore_positions.append(h["position"])

	predator_positions.clear()
	for p in predators:
		if p is Vector3:
			predator_positions.append(p)
		elif p is Dictionary and p.has("position"):
			predator_positions.append(p["position"])

	if not trail.is_empty():
		disturbance_trail.clear()
		for t in trail:
			if t is Vector3:
				disturbance_trail.append(t)
	elif player_pos != Vector3.ZERO:
		if disturbance_trail.is_empty() or disturbance_trail.back().distance_to(player_pos) > 8.0:
			disturbance_trail.append(player_pos)
			if disturbance_trail.size() > 24:
				disturbance_trail.pop_front()

	queue_redraw()

func _draw() -> void:
	var c: Vector2 = size * 0.5
	var map_radius: float = minf(size.x, size.y) * 0.44
	var s: float = map_radius / world_radius

	# 1. Ocean Background Rim
	draw_circle(c, map_radius + 14.0, Color(0.05, 0.09, 0.15, 0.95))
	draw_arc(c, map_radius + 14.0, 0, TAU, 64, Color(0.18, 0.35, 0.52, 0.5), 1.5)

	# 2. Concentric Distance Rings (120m, 240m, 360m)
	for r_dist in [120.0, 240.0, 340.0]:
		var r_px: float = r_dist * s
		draw_arc(c, r_px, 0, TAU, 48, Color(0.20, 0.38, 0.50, 0.22), 1.0)

	# 3. 720m Continent Base Landmass (Smoothed organic polygon)
	var land_points: PackedVector2Array = PackedVector2Array()
	var num_pts: int = 64
	for i in range(num_pts):
		var ang: float = (float(i) / float(num_pts)) * TAU
		# Slight natural variance for coastline organic feel
		var r_var: float = 330.0 + sin(ang * 3.0) * 8.0 + cos(ang * 5.0) * 6.0
		var pt: Vector2 = c + Vector2(cos(ang), sin(ang)) * (r_var * s)
		land_points.append(pt)

	draw_colored_polygon(land_points, Color(0.24, 0.40, 0.20, 0.95))

	# 4. Regional Biome Washes
	# A. Whispering Deep Forest (West & Southwest: angle approx PI*0.65 to PI*1.35)
	var forest_pts: PackedVector2Array = PackedVector2Array()
	forest_pts.append(c)
	for i in range(24):
		var ang: float = lerpf(PI * 0.60, PI * 1.40, float(i) / 23.0)
		var pt: Vector2 = c + Vector2(cos(ang), sin(ang)) * (310.0 * s)
		forest_pts.append(pt)
	draw_colored_polygon(forest_pts, Color(0.11, 0.27, 0.14, 0.85))

	# B. Sunlit Meadow Plains (East & Southeast: angle approx -PI*0.35 to PI*0.45)
	var meadow_pts: PackedVector2Array = PackedVector2Array()
	meadow_pts.append(c)
	for i in range(24):
		var ang: float = lerpf(-PI * 0.35, PI * 0.45, float(i) / 23.0)
		var pt: Vector2 = c + Vector2(cos(ang), sin(ang)) * (315.0 * s)
		meadow_pts.append(pt)
	draw_colored_polygon(meadow_pts, Color(0.36, 0.54, 0.22, 0.85))

	# C. Skyspire Alpine Range (Northwest: angle approx PI*1.15 to PI*1.55)
	var alpine_pts: PackedVector2Array = PackedVector2Array()
	alpine_pts.append(c)
	for i in range(16):
		var ang: float = lerpf(PI * 1.15, PI * 1.55, float(i) / 15.0)
		var pt: Vector2 = c + Vector2(cos(ang), sin(ang)) * (290.0 * s)
		alpine_pts.append(pt)
	draw_colored_polygon(alpine_pts, Color(0.38, 0.42, 0.46, 0.80))

	# D. Pine Highlands (Northeast: angle approx PI*1.55 to PI*1.95)
	var high_pts: PackedVector2Array = PackedVector2Array()
	high_pts.append(c)
	for i in range(16):
		var ang: float = lerpf(PI * 1.55, PI * 1.95, float(i) / 15.0)
		var pt: Vector2 = c + Vector2(cos(ang), sin(ang)) * (300.0 * s)
		high_pts.append(pt)
	draw_colored_polygon(high_pts, Color(0.18, 0.34, 0.26, 0.80))

	# E. Emerald Cove Lake Basin (Center-East)
	draw_circle(c + Vector2(18.0 * s, 14.0 * s), 28.0 * s, Color(0.12, 0.28, 0.42, 0.90))

	# F. Alpine Glacial Tarn Lake Basin (Northwest)
	draw_circle(c + Vector2(-125.0 * s, -110.0 * s), 20.0 * s, Color(0.14, 0.45, 0.58, 0.95))
	draw_circle(c + Vector2(-125.0 * s, -110.0 * s), 15.0 * s, Color(0.20, 0.60, 0.72, 0.95))

	# G. Silverveil Glacial Falls Cascade Ribbon (Tarn to Grotto)
	var stream_pts: PackedVector2Array = PackedVector2Array([
		c + Vector2(-108.0 * s, -98.0 * s),
		c + Vector2(-96.0 * s, -88.0 * s),
		c + Vector2(-82.0 * s, -78.0 * s)
	])
	draw_polyline(stream_pts, Color(0.35, 0.75, 0.95, 0.90), 2.5)

	# 4.5. Wildlife Ecological Territory Heatmaps & Grazing/Hunting Corridors
	if show_wildlife_heatmaps:
		# A. Herbivore Grazing Pastures (Soft glowing emerald/cyan translucent circles)
		for h_pos in herbivore_positions:
			var hc: Vector2 = c + Vector2(h_pos.x * s, h_pos.z * s)
			draw_circle(hc, 26.0 * s, Color(0.18, 0.90, 0.55, 0.16))
			draw_circle(hc, 13.0 * s, Color(0.25, 0.95, 0.65, 0.25))
			draw_circle(hc, 3.5 * s, Color(0.35, 1.0, 0.75, 0.85))

		# B. Predator Hunting Corridors (Amber/Crimson alert glow circles)
		for p_pos in predator_positions:
			var pc: Vector2 = c + Vector2(p_pos.x * s, p_pos.z * s)
			draw_circle(pc, 34.0 * s, Color(0.95, 0.35, 0.15, 0.15))
			draw_circle(pc, 17.0 * s, Color(1.0, 0.25, 0.10, 0.22))
			draw_circle(pc, 4.0 * s, Color(1.0, 0.40, 0.20, 0.90))

		# C. Player Disturbance Trail
		if disturbance_trail.size() >= 2:
			var trail_pts: PackedVector2Array = PackedVector2Array()
			for t_pos in disturbance_trail:
				trail_pts.append(c + Vector2(t_pos.x * s, t_pos.z * s))
			draw_polyline(trail_pts, Color(0.25, 0.85, 1.0, 0.35), 1.5)

	# 5. Coastline Sandy Perimeter Stroke
	for i in range(land_points.size()):
		var p1: Vector2 = land_points[i]
		var p2: Vector2 = land_points[(i + 1) % land_points.size()]
		draw_line(p1, p2, Color(0.70, 0.64, 0.46, 0.90), 2.0)

	# 6. Biome Labels
	if font:
		draw_string(font, c + Vector2(-110.0, 15.0), "DEEP FOREST", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.70, 0.90, 0.75, 0.85))
		draw_string(font, c + Vector2(40.0, 35.0), "MEADOW PLAINS", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.92, 0.96, 0.70, 0.85))
		draw_string(font, c + Vector2(-65.0, -95.0), "SKYSPIRE MASSIF", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.85, 0.90, 0.95, 0.85))
		draw_string(font, c + Vector2(-88.0, -56.0), "TARN LAKE", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(0.40, 0.85, 1.0, 0.85))
		draw_string(font, c + Vector2(45.0, -75.0), "HIGHLANDS", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.75, 0.88, 0.80, 0.85))
		draw_string(font, c + Vector2(5.0, -4.0), "COVE", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(0.55, 0.85, 1.0, 0.85))

	# 7. Landmarks (POIs)
	for p in pois:
		var p_world: Vector3 = p.get("position", Vector3.ZERO)
		var p_canvas: Vector2 = c + Vector2(p_world.x * s, p_world.z * s)
		var discovered: bool = p.get("discovered", false)
		var p_id: String = p.get("id", "")

		if discovered:
			# Discovered Landmark badge: gold icon
			draw_circle(p_canvas, 5.5, Color(1.0, 0.82, 0.20, 0.95))
			draw_circle(p_canvas, 3.5, Color(0.12, 0.14, 0.18, 0.95))
			if font:
				var short_name: String = _get_short_poi_name(p_id)
				draw_string(font, p_canvas + Vector2(7.0, 3.0), short_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.90, 0.40))
		else:
			# Undiscovered Landmark: subtle grey question marker
			draw_circle(p_canvas, 4.0, Color(0.40, 0.50, 0.60, 0.60))
			draw_circle(p_canvas, 2.0, Color(0.12, 0.16, 0.22, 0.80))

	# 8. Cardinal Compass Markers
	if font:
		draw_string(font, c + Vector2(-4.0, -map_radius - 1.0), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1.0, 0.85, 0.25))
		draw_string(font, c + Vector2(-4.0, map_radius + 12.0), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.7, 0.8, 0.9, 0.6))
		draw_string(font, c + Vector2(map_radius + 3.0, 4.0), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.7, 0.8, 0.9, 0.6))
		draw_string(font, c + Vector2(-map_radius - 12.0, 4.0), "W", HORIZONTAL_ALIGNMENT_RIGHT, -1, 9, Color(0.7, 0.8, 0.9, 0.6))

	# 9. Player Location Indicator (Directional Arrow)
	var pl_canvas: Vector2 = c + Vector2(player_pos.x * s, player_pos.z * s)
	# Pulse ring
	draw_circle(pl_canvas, 8.0, Color(0.2, 0.95, 0.85, 0.25))

	# Arrow pointing toward player_heading
	# In 3D: Z is south, -Z is north. Heading 0° = -Z (up on canvas).
	var rad: float = deg_to_rad(player_heading - 90.0)
	var fwd: Vector2 = Vector2(cos(rad), sin(rad))
	var right: Vector2 = Vector2(-fwd.y, fwd.x)

	var nose: Vector2 = pl_canvas + fwd * 9.0
	var wing_l: Vector2 = pl_canvas - fwd * 5.0 + right * 5.0
	var wing_r: Vector2 = pl_canvas - fwd * 5.0 - right * 5.0

	var arrow_pts: PackedVector2Array = PackedVector2Array([nose, wing_l, pl_canvas - fwd * 2.0, wing_r])
	draw_colored_polygon(arrow_pts, Color(0.20, 0.96, 0.85, 1.0))
	draw_polyline(PackedVector2Array([wing_l, nose, wing_r]), Color(1.0, 1.0, 1.0, 0.9), 1.2)

	# 10. Wildlife Heatmap Mode Legend
	if show_wildlife_heatmaps and font:
		draw_string(font, c + Vector2(-map_radius + 4.0, map_radius + 12.0), "🟢 Grazing  🔴 Hunting [TAB]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.75, 0.90, 0.95, 0.85))

func _get_short_poi_name(id: String) -> String:
	match id:
		"antler_rub": return "Antler Rub"
		"cove_mooring": return "Emerald Cove"
		"field_camp": return "Field Camp"
		"monoliths": return "Monoliths"
		"cairn_summit": return "Summit Cairn"
		"skyspire_overlook": return "Skyspire Peak"
		"highland_ring": return "Highlands"
		"cape_solitude": return "Cape Solitude"
		"alpine_tarn": return "Alpine Tarn"
		"whispering_grotto": return "Grotto Cave"
		"glacial_waterfall": return "Glacial Falls"
		_: return id.capitalize()
