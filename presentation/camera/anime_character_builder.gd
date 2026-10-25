@tool
class_name AnimeCharacterBuilder
extends RefCounted

## Builds high-fidelity Genshin-style anime character visual enhancements:
## - Slender, graceful heroic proportions (8-head anime ratio)
## - Expressive anime face with detailed sparkling eyes, blush, and delicate jaw
## - Volumetric layered anime hair with bangs, side locks, dynamic ponytail
## - High-contrast adventurer outfit styling & cel shader integration

static var _cached_eye_texture: ImageTexture = null

static func get_anime_eye_texture() -> ImageTexture:
	if _cached_eye_texture != null:
		return _cached_eye_texture

	var w: int = 128
	var h: int = 128
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0)) # Transparent background

	var cx: float = 64.0
	var cy: float = 68.0
	var rx: float = 38.0
	var ry: float = 46.0

	# 1. Sclera (Eye White)
	for y in range(h):
		for x in range(w):
			var dx = (x - cx) / rx
			var dy = (y - cy) / ry
			var dist_sq = dx * dx + dy * dy
			if dist_sq <= 1.0:
				# Slight upper shadow on sclera for depth
				var shadow = clampf(1.0 - (float(y) / float(h)) * 0.15, 0.85, 1.0)
				img.set_pixel(x, y, Color(0.96 * shadow, 0.97 * shadow, 1.0 * shadow, 1.0))

	# 2. Iris (Emerald-Teal Genshin Adventurer Palette)
	var iris_cx: float = cx
	var iris_cy: float = cy + 2.0
	var ir_x: float = rx * 0.76
	var ir_y: float = ry * 0.88

	for y in range(h):
		for x in range(w):
			var dx = (x - iris_cx) / ir_x
			var dy = (y - iris_cy) / ir_y
			var d_sq = dx * dx + dy * dy
			if d_sq <= 1.0:
				var t = clampf((float(y) - (iris_cy - ir_y)) / (ir_y * 2.0), 0.0, 1.0)
				# Gradient: Deep oceanic sapphire at top -> Vibrant glowing emerald/cyan at bottom
				var top_color = Color(0.08, 0.18, 0.38, 1.0)
				var mid_color = Color(0.05, 0.48, 0.62, 1.0)
				var bot_color = Color(0.18, 0.88, 0.75, 1.0)
				var iris_col: Color
				if t < 0.5:
					iris_col = top_color.lerp(mid_color, t * 2.0)
				else:
					iris_col = mid_color.lerp(bot_color, (t - 0.5) * 2.0)

				# Dark iris rim
				if d_sq > 0.82:
					iris_col = iris_col.lerp(Color(0.04, 0.10, 0.22, 1.0), 0.75)
				img.set_pixel(x, y, iris_col)

	# 3. Pupil (Deep dark center)
	var pup_rx: float = ir_x * 0.38
	var pup_ry: float = ir_y * 0.46
	for y in range(h):
		for x in range(w):
			var dx = (x - iris_cx) / pup_rx
			var dy = (y - iris_cy) / pup_ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, Color(0.03, 0.06, 0.14, 1.0))

	# 4. Primary Specular Catchlight (Top-Left sparkling diamond)
	for y in range(h):
		for x in range(w):
			var dist = Vector2(x - (iris_cx - 11.0), y - (iris_cy - 12.0)).length()
			if dist <= 7.0:
				var a = clampf(1.0 - (dist / 7.0), 0.0, 1.0)
				var prev = img.get_pixel(x, y)
				img.set_pixel(x, y, prev.lerp(Color(1.0, 1.0, 1.0, 1.0), a))

	# 5. Secondary Catchlight (Bottom-Right soft glow)
	for y in range(h):
		for x in range(w):
			var dist = Vector2(x - (iris_cx + 9.0), y - (iris_cy + 13.0)).length()
			if dist <= 4.5:
				var a = clampf(1.0 - (dist / 4.5), 0.0, 1.0) * 0.75
				var prev = img.get_pixel(x, y)
				img.set_pixel(x, y, prev.lerp(Color(0.85, 0.98, 1.0, 1.0), a))

	# 6. Upper Eyelash / Winged Eyeliner Arc
	for x in range(w):
		var nx = (float(x) - cx) / rx
		if abs(nx) <= 1.08:
			var curve_y = cy - ry * sqrt(max(0.0, 1.0 - nx * nx * 0.75))
			var thick = 4.5 + max(0.0, (1.0 - abs(nx))) * 3.5
			# Flare at outer corner (wing)
			if nx > 0.6:
				thick += (nx - 0.6) * 5.0
				curve_y -= (nx - 0.6) * 4.0
			for y in range(int(curve_y - thick * 0.5), int(curve_y + thick * 0.5) + 1):
				if y >= 0 and y < h:
					img.set_pixel(x, y, Color(0.12, 0.08, 0.16, 1.0))

	# 7. Lower Lash Accent (Subtle anime lash dot)
	for x in range(int(cx - 14.0), int(cx + 18.0)):
		var nx = (float(x) - cx) / (rx * 0.8)
		var curve_y = cy + ry * sqrt(max(0.0, 1.0 - nx * nx * 0.9))
		for y in range(int(curve_y - 1.0), int(curve_y + 2.0)):
			if y >= 0 and y < h:
				var prev = img.get_pixel(x, y)
				img.set_pixel(x, y, prev.lerp(Color(0.18, 0.12, 0.22, 0.85), 0.8))

	_cached_eye_texture = ImageTexture.create_from_image(img)
	return _cached_eye_texture

static func build_anime_head() -> Node3D:
	var head_root: Node3D = Node3D.new()
	head_root.name = "AnimeHeroHead"

	var skin_color: Color = Color(1.0, 0.93, 0.90, 1.0) # Delicate fair anime skin
	var hair_color: Color = Color(0.96, 0.78, 0.44, 1.0) # Radiant golden anime hair
	var hair_shadow: Color = Color(0.78, 0.58, 0.28, 1.0)
	var gold_accent: Color = Color(0.98, 0.82, 0.22, 1.0)

	# Shared Skin Material with soft Cel Shading
	var skin_mat: StandardMaterial3D = StandardMaterial3D.new()
	skin_mat.albedo_color = skin_color
	skin_mat.roughness = 0.45
	skin_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	skin_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON

	# Shared Hair Material with rich anime sheen
	var hair_mat: StandardMaterial3D = StandardMaterial3D.new()
	hair_mat.albedo_color = hair_color
	hair_mat.roughness = 0.35
	hair_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	hair_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	hair_mat.rim_enabled = true
	hair_mat.rim = 0.55
	hair_mat.rim_tint = 0.3

	# Shared Gold Metal Material
	var gold_mat: StandardMaterial3D = StandardMaterial3D.new()
	gold_mat.albedo_color = gold_accent
	gold_mat.metallic = 0.85
	gold_mat.roughness = 0.25

	# 1. Head Cranium & Face Base (delicate proportions)
	var face_mesh: SphereMesh = SphereMesh.new()
	face_mesh.radius = 0.115
	face_mesh.height = 0.230
	face_mesh.radial_segments = 24
	face_mesh.rings = 16
	var face_inst: MeshInstance3D = MeshInstance3D.new()
	face_inst.name = "FaceBase"
	face_inst.mesh = face_mesh
	face_inst.material_override = skin_mat
	# Slightly taper Z/X for slender anime silhouette
	face_inst.scale = Vector3(0.92, 1.02, 0.94)
	face_inst.position = Vector3(0.0, 0.08, 0.0)
	head_root.add_child(face_inst)

	# 2. Cute Tapered Anime Chin
	var chin_mesh: CylinderMesh = CylinderMesh.new()
	chin_mesh.top_radius = 0.085
	chin_mesh.bottom_radius = 0.025
	chin_mesh.height = 0.090
	chin_mesh.radial_segments = 16
	var chin_inst: MeshInstance3D = MeshInstance3D.new()
	chin_inst.name = "Chin"
	chin_inst.mesh = chin_mesh
	chin_inst.material_override = skin_mat
	chin_inst.position = Vector3(0.0, 0.015, 0.035)
	chin_inst.rotation.x = deg_to_rad(12.0)
	head_root.add_child(chin_inst)

	# 3. Delicate Anime Ears
	for side in [-1.0, 1.0]:
		var ear_mesh: SphereMesh = SphereMesh.new()
		ear_mesh.radius = 0.024
		ear_mesh.height = 0.048
		ear_mesh.radial_segments = 12
		var ear_inst: MeshInstance3D = MeshInstance3D.new()
		ear_inst.mesh = ear_mesh
		ear_inst.material_override = skin_mat
		ear_inst.position = Vector3(side * 0.106, 0.08, -0.012)
		ear_inst.scale = Vector3(0.35, 1.0, 0.65)
		ear_inst.rotation.y = deg_to_rad(side * 18.0)
		head_root.add_child(ear_inst)

	# 4. Expressive Anime Eyes (Decal Quads)
	var eye_tex: ImageTexture = get_anime_eye_texture()
	var eye_mat: StandardMaterial3D = StandardMaterial3D.new()
	eye_mat.albedo_texture = eye_tex
	eye_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # Vibrant anime eye catchlights
	eye_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var eye_quad: QuadMesh = QuadMesh.new()
	eye_quad.size = Vector2(0.052, 0.056)

	# Left Eye
	var eye_left: MeshInstance3D = MeshInstance3D.new()
	eye_left.name = "EyeLeft"
	eye_left.mesh = eye_quad
	eye_left.material_override = eye_mat
	eye_left.position = Vector3(0.044, 0.088, 0.104)
	eye_left.rotation.y = deg_to_rad(15.0)
	head_root.add_child(eye_left)

	# Right Eye (mirrored UV via scale.x = -1)
	var eye_right: MeshInstance3D = MeshInstance3D.new()
	eye_right.name = "EyeRight"
	eye_right.mesh = eye_quad
	eye_right.material_override = eye_mat
	eye_right.position = Vector3(-0.044, 0.088, 0.104)
	eye_right.scale.x = -1.0
	eye_right.rotation.y = deg_to_rad(-15.0)
	head_root.add_child(eye_right)

	# 5. Soft Anime Cheek Blush
	var blush_mat: StandardMaterial3D = StandardMaterial3D.new()
	blush_mat.albedo_color = Color(1.0, 0.62, 0.68, 0.48)
	blush_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blush_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for side in [-1.0, 1.0]:
		var blush_mesh: QuadMesh = QuadMesh.new()
		blush_mesh.size = Vector2(0.034, 0.016)
		var blush_inst: MeshInstance3D = MeshInstance3D.new()
		blush_inst.mesh = blush_mesh
		blush_inst.material_override = blush_mat
		blush_inst.position = Vector3(side * 0.055, 0.058, 0.098)
		blush_inst.rotation.y = deg_to_rad(side * 22.0)
		blush_inst.rotation.z = deg_to_rad(side * -8.0)
		head_root.add_child(blush_inst)

	# 6. Volumetric Layered Anime Hair:
	# 6a. Hair Crown Cap (Base volume)
	var hair_cap: SphereMesh = SphereMesh.new()
	hair_cap.radius = 0.126
	hair_cap.height = 0.245
	hair_cap.radial_segments = 24
	var cap_inst: MeshInstance3D = MeshInstance3D.new()
	cap_inst.mesh = hair_cap
	cap_inst.material_override = hair_mat
	cap_inst.position = Vector3(0.0, 0.105, -0.018)
	cap_inst.scale = Vector3(0.96, 0.98, 1.04)
	head_root.add_child(cap_inst)

	# 6b. Center Bangs (Stylized anime fringe tapering down)
	var center_bang: CylinderMesh = CylinderMesh.new()
	center_bang.top_radius = 0.032
	center_bang.bottom_radius = 0.006
	center_bang.height = 0.095
	center_bang.radial_segments = 12
	var cb_inst: MeshInstance3D = MeshInstance3D.new()
	cb_inst.mesh = center_bang
	cb_inst.material_override = hair_mat
	cb_inst.position = Vector3(0.008, 0.138, 0.108)
	cb_inst.rotation.x = deg_to_rad(28.0)
	cb_inst.rotation.z = deg_to_rad(6.0)
	head_root.add_child(cb_inst)

	# 6c. Side-Swept Bangs (Left & Right)
	for side in [-1.0, 1.0]:
		var side_bang: CylinderMesh = CylinderMesh.new()
		side_bang.top_radius = 0.036
		side_bang.bottom_radius = 0.008
		side_bang.height = 0.115
		side_bang.radial_segments = 12
		var sb_inst: MeshInstance3D = MeshInstance3D.new()
		sb_inst.mesh = side_bang
		sb_inst.material_override = hair_mat
		sb_inst.position = Vector3(side * 0.052, 0.132, 0.096)
		sb_inst.rotation.x = deg_to_rad(24.0)
		sb_inst.rotation.z = deg_to_rad(side * 18.0)
		sb_inst.rotation.y = deg_to_rad(side * 14.0)
		head_root.add_child(sb_inst)

	# 6d. Long Elegant Cheek Tendrils (framing the face)
	for side in [-1.0, 1.0]:
		var tendril: CylinderMesh = CylinderMesh.new()
		tendril.top_radius = 0.024
		tendril.bottom_radius = 0.005
		tendril.height = 0.190
		tendril.radial_segments = 12
		var t_inst: MeshInstance3D = MeshInstance3D.new()
		t_inst.mesh = tendril
		t_inst.material_override = hair_mat
		t_inst.position = Vector3(side * 0.092, 0.035, 0.065)
		t_inst.rotation.z = deg_to_rad(side * 6.0)
		t_inst.rotation.x = deg_to_rad(10.0)
		head_root.add_child(t_inst)

	# 6e. Dynamic Flowing High Ponytail at Back Crown
	var ponytail_root: Node3D = Node3D.new()
	ponytail_root.name = "DynamicPonytail"
	ponytail_root.position = Vector3(0.0, 0.145, -0.112)
	ponytail_root.rotation.x = deg_to_rad(-24.0)
	head_root.add_child(ponytail_root)

	# Hair Clasp / Adventurer Ornament
	var ring_mesh: TorusMesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.018
	ring_mesh.outer_radius = 0.034
	var ring_inst: MeshInstance3D = MeshInstance3D.new()
	ring_inst.mesh = ring_mesh
	ring_inst.material_override = gold_mat
	ring_inst.rotation.x = deg_to_rad(90.0)
	ponytail_root.add_child(ring_inst)

	# Flowing Ponytail Plume (Tier 1 & Tier 2)
	var plume1: CylinderMesh = CylinderMesh.new()
	plume1.top_radius = 0.032
	plume1.bottom_radius = 0.024
	plume1.height = 0.160
	plume1.radial_segments = 12
	var p1_inst: MeshInstance3D = MeshInstance3D.new()
	p1_inst.name = "PlumeSegment1"
	p1_inst.mesh = plume1
	p1_inst.material_override = hair_mat
	p1_inst.position = Vector3(0.0, -0.075, -0.025)
	p1_inst.rotation.x = deg_to_rad(-16.0)
	ponytail_root.add_child(p1_inst)

	var plume2: CylinderMesh = CylinderMesh.new()
	plume2.top_radius = 0.024
	plume2.bottom_radius = 0.006
	plume2.height = 0.210
	plume2.radial_segments = 12
	var p2_inst: MeshInstance3D = MeshInstance3D.new()
	p2_inst.name = "PlumeSegment2"
	p2_inst.mesh = plume2
	p2_inst.material_override = hair_mat
	p2_inst.position = Vector3(0.0, -0.220, -0.065)
	p2_inst.rotation.x = deg_to_rad(-12.0)
	ponytail_root.add_child(p2_inst)

	# Adventurer Emerald Gem Clasp
	var gem_mesh: SphereMesh = SphereMesh.new()
	gem_mesh.radius = 0.015
	gem_mesh.height = 0.030
	var gem_mat: StandardMaterial3D = StandardMaterial3D.new()
	gem_mat.albedo_color = Color(0.12, 0.88, 0.65, 1.0)
	gem_mat.emission_enabled = true
	gem_mat.emission = Color(0.12, 0.88, 0.65, 1.0)
	gem_mat.emission_energy_multiplier = 0.8
	var gem_inst: MeshInstance3D = MeshInstance3D.new()
	gem_inst.mesh = gem_mesh
	gem_inst.material_override = gem_mat
	gem_inst.position = Vector3(0.028, 0.012, 0.015)
	ponytail_root.add_child(gem_inst)

	return head_root
