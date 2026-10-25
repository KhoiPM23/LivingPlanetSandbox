class_name MarineEcosystem
extends Node3D

## Living Planet Sandbox — Marine Ecosystem & Aquatic Biodiversity System.
## Brings ocean shallows, coastal shelves, and Emerald Cove to life with:
## 1. Procedural Underwater Kelp Forests (towering segmented fronds swaying with ocean currents)
## 2. Coastal Seagrass Meadows (dense waving ribbon grass carpet in shallow sunlit water)
## 3. Autonomous Schooling Marine Fish (Emerald Salmon & Reef Sunfish with procedural tail locomotion,
##    cohesion/alignment flocking, water-depth bounding, and reactive player disturbance avoidance)
## 4. Rustic Wooden Fishing Pier & Moored Expedition Skiff with Gerstner wave bobbing & pitch/roll
## 5. Ambient Ascending Air Bubble Streams along coastal reefs and cove shallows.
## High performance: Flora MultiMeshed into 2 draw calls; Fish & Boat fully optimized for Intel Iris Xe.

const UnderwaterFloraShader = preload("res://presentation/shaders/underwater_flora.gdshader")
const FishLocomotionShader = preload("res://presentation/shaders/fish_locomotion.gdshader")

var _terrain: IslandTerrain = null
var _kelp_mmi: MultiMeshInstance3D = null
var _seagrass_mmi: MultiMeshInstance3D = null
var _bubble_particles: GPUParticles3D = null

signal sunken_chest_looted(loot: Dictionary)

# Coral reefs, galleon, and marine megafauna
var _coral_mmi: MultiMeshInstance3D = null
var _coral_material: StandardMaterial3D = null
var _pickles_mmi: MultiMeshInstance3D = null
var _pickles_material: StandardMaterial3D = null
var _sunken_galleon: Node3D = null
var _chest_node: Node3D = null
var _chest_looted: bool = false
var _manta_rays: Array[Node3D] = []
var _sea_turtles: Array[Node3D] = []

# Moored boat and pier
var _pier_root: Node3D = null
var _boat_root: Node3D = null
var _boat_base_pos: Vector3 = Vector3.ZERO
var _boat_time: float = 0.0

# Schooling Fish Data Structure
class FishAgent extends RefCounted:
	var node: MeshInstance3D
	var position: Vector3
	var velocity: Vector3
	var school_id: int
	var swim_speed: float
	var target_heading: float
	var body_length: float

var _fish_agents: Array[FishAgent] = []
var _school_centers: Dictionary = {} # school_id -> Vector3
var _school_base_positions: Dictionary = {} # school_id -> Vector3 (anchor)
var _player_node: Node3D = null

# Materials cache
var _kelp_material: ShaderMaterial = null
var _seagrass_material: ShaderMaterial = null
var _salmon_material: ShaderMaterial = null
var _sunfish_material: ShaderMaterial = null
var _clownfish_material: ShaderMaterial = null
var _tang_material: ShaderMaterial = null

func setup(terrain: IslandTerrain, player: Node3D = null, seed_val: int = 1337) -> void:
	_terrain = terrain
	_player_node = player
	_init_materials()

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val + 9941

	_build_underwater_kelp_forest(rng)
	_build_seagrass_meadows(rng)
	_build_coral_reefs(rng)
	_build_bioluminescent_sea_pickles(rng)
	_build_sunken_galleon()
	_build_gliding_manta_rays()
	_build_sea_turtles(rng)
	_build_coastal_pier_and_boat()
	_build_schooling_fish(rng)
	_build_ambient_bubble_streams()

func _init_materials() -> void:
	# Kelp material: Olive forest green transitioning to tender sunlit amber-green tips
	_kelp_material = ShaderMaterial.new()
	_kelp_material.shader = UnderwaterFloraShader
	_kelp_material.set_shader_parameter("root_color", Color(0.04, 0.16, 0.08, 1.0))
	_kelp_material.set_shader_parameter("tip_color", Color(0.24, 0.48, 0.22, 1.0))
	_kelp_material.set_shader_parameter("current_speed", 1.25)
	_kelp_material.set_shader_parameter("current_strength", 0.32)
	_kelp_material.set_shader_parameter("plant_height", 5.2)

	# Seagrass material: Vibrant emerald ribbons in sunlit shallows
	_seagrass_material = ShaderMaterial.new()
	_seagrass_material.shader = UnderwaterFloraShader
	_seagrass_material.set_shader_parameter("root_color", Color(0.06, 0.22, 0.10, 1.0))
	_seagrass_material.set_shader_parameter("tip_color", Color(0.18, 0.58, 0.26, 1.0))
	_seagrass_material.set_shader_parameter("current_speed", 1.65)
	_seagrass_material.set_shader_parameter("current_strength", 0.22)
	_seagrass_material.set_shader_parameter("plant_height", 1.4)

	# Emerald Salmon fish material
	_salmon_material = ShaderMaterial.new()
	_salmon_material.shader = FishLocomotionShader
	_salmon_material.set_shader_parameter("body_color_top", Color(0.14, 0.36, 0.58, 1.0))
	_salmon_material.set_shader_parameter("body_color_bottom", Color(0.88, 0.94, 0.98, 1.0))
	_salmon_material.set_shader_parameter("fin_accent_color", Color(0.95, 0.62, 0.22, 1.0))
	_salmon_material.set_shader_parameter("swim_speed", 6.2)
	_salmon_material.set_shader_parameter("wag_amplitude", 0.16)

	# Reef Sunfish material
	_sunfish_material = ShaderMaterial.new()
	_sunfish_material.shader = FishLocomotionShader
	_sunfish_material.set_shader_parameter("body_color_top", Color(0.82, 0.45, 0.12, 1.0))
	_sunfish_material.set_shader_parameter("body_color_bottom", Color(0.96, 0.88, 0.55, 1.0))
	_sunfish_material.set_shader_parameter("fin_accent_color", Color(0.15, 0.75, 0.85, 1.0))
	_sunfish_material.set_shader_parameter("swim_speed", 5.0)
	_sunfish_material.set_shader_parameter("wag_amplitude", 0.13)

	# Minecraft-Style Tropical Clownfish material (vibrant orange & white fin accents)
	_clownfish_material = ShaderMaterial.new()
	_clownfish_material.shader = FishLocomotionShader
	_clownfish_material.set_shader_parameter("body_color_top", Color(1.0, 0.42, 0.08, 1.0))
	_clownfish_material.set_shader_parameter("body_color_bottom", Color(0.98, 0.98, 1.0, 1.0))
	_clownfish_material.set_shader_parameter("fin_accent_color", Color(0.98, 0.95, 0.92, 1.0))
	_clownfish_material.set_shader_parameter("swim_speed", 5.8)
	_clownfish_material.set_shader_parameter("wag_amplitude", 0.18)

	# Neon Blue Tang material (electric blue body & bright yellow tail)
	_tang_material = ShaderMaterial.new()
	_tang_material.shader = FishLocomotionShader
	_tang_material.set_shader_parameter("body_color_top", Color(0.06, 0.26, 0.92, 1.0))
	_tang_material.set_shader_parameter("body_color_bottom", Color(0.12, 0.18, 0.48, 1.0))
	_tang_material.set_shader_parameter("fin_accent_color", Color(1.0, 0.86, 0.10, 1.0))
	_tang_material.set_shader_parameter("swim_speed", 6.6)
	_tang_material.set_shader_parameter("wag_amplitude", 0.17)

	# Minecraft-Style Bioluminescent Sea Pickles material (pulsing teal/cyan emission)
	_pickles_material = StandardMaterial3D.new()
	_pickles_material.albedo_color = Color(0.16, 0.48, 0.32, 1.0)
	_pickles_material.roughness = 0.55
	_pickles_material.emission_enabled = true
	_pickles_material.emission = Color(0.12, 0.92, 0.72, 1.0)
	_pickles_material.emission_energy_multiplier = 0.95

# =============================================================================
# 1. UNDERWATER KELP FOREST MULTIMESH
# =============================================================================
func _build_underwater_kelp_forest(rng: RandomNumberGenerator) -> void:
	var kelp_mesh: ArrayMesh = _create_procedural_kelp_mesh()
	if not kelp_mesh:
		return

	_kelp_mmi = MultiMeshInstance3D.new()
	_kelp_mmi.name = "KelpForestMultiMesh"
	_kelp_mmi.material_override = _kelp_material
	_kelp_mmi.visibility_range_end = 85.0
	_kelp_mmi.visibility_range_end_margin = 15.0
	_kelp_mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	_kelp_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var count: int = 240
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = kelp_mesh
	_kelp_mmi.multimesh = mm

	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = count * 10

	# Scatter kelp in submerged shelf zones: Y between -7.5m and -1.2m
	while placed < count and attempts < max_attempts:
		attempts += 1
		# Focus 35% near Emerald Cove mouth, 65% around coastal reef perimeter
		var x: float
		var z: float
		if rng.randf() < 0.35:
			x = rng.randf_range(10.0, 32.0)
			z = rng.randf_range(8.0, 30.0)
		else:
			var angle: float = rng.randf_range(0.0, TAU)
			var is_expanded: bool = (_terrain != null and _terrain.island_size > 200.0)
			var r_min: float = 240.0 if is_expanded else 45.0
			var r_max: float = 380.0 if is_expanded else 95.0
			var dist: float = rng.randf_range(r_min, r_max)
			x = cos(angle) * dist
			z = sin(angle) * dist

		var y: float = _terrain.get_height_at(x, z) if _terrain else -3.5
		if y < -7.5 or y > -1.2:
			continue

		var t: Transform3D = Transform3D()
		var s: float = rng.randf_range(0.85, 1.45)
		var h_mult: float = rng.randf_range(0.9, 1.3)
		t = t.scaled(Vector3(s, s * h_mult, s))
		t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		t.origin = Vector3(x, y - 0.15, z)
		mm.set_instance_transform(placed, t)
		placed += 1

	mm.visible_instance_count = placed
	add_child(_kelp_mmi)

func _create_procedural_kelp_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var height: float = 4.8
	var segments: int = 7
	var seg_h: float = height / float(segments)

	# Center stalk + alternating leaf blade cards
	for i in range(segments):
		var y0: float = float(i) * seg_h
		var y1: float = float(i + 1) * seg_h
		var r: float = 0.05 * (1.0 - (float(i) / float(segments)) * 0.4)

		# Stalk quad (crossbill ribbon)
		st.set_normal(Vector3.FORWARD)
		st.add_vertex(Vector3(-r, y0, 0.0))
		st.add_vertex(Vector3(r, y0, 0.0))
		st.add_vertex(Vector3(r, y1, 0.0))

		st.add_vertex(Vector3(-r, y0, 0.0))
		st.add_vertex(Vector3(r, y1, 0.0))
		st.add_vertex(Vector3(-r, y1, 0.0))

		# Leaf blade extending outward alternately on X or Z
		var leaf_sign: float = 1.0 if (i % 2 == 0) else -1.0
		var leaf_w: float = 0.28 * (1.0 - (float(i) / float(segments)) * 0.3)
		var leaf_len: float = 0.75 * (1.0 - (float(i) / float(segments)) * 0.25)

		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(0.0, y1, 0.0))
		st.add_vertex(Vector3(leaf_len * leaf_sign, y1 + 0.18, -leaf_w * 0.5))
		st.add_vertex(Vector3(leaf_len * leaf_sign, y1 + 0.18, leaf_w * 0.5))
		# Reverse face
		st.add_vertex(Vector3(0.0, y1, 0.0))
		st.add_vertex(Vector3(leaf_len * leaf_sign, y1 + 0.18, leaf_w * 0.5))
		st.add_vertex(Vector3(leaf_len * leaf_sign, y1 + 0.18, -leaf_w * 0.5))

	st.generate_normals()
	return st.commit()

# =============================================================================
# 2. SEAGRASS MEADOWS MULTIMESH
# =============================================================================
func _build_seagrass_meadows(rng: RandomNumberGenerator) -> void:
	var grass_mesh: ArrayMesh = _create_procedural_seagrass_mesh()
	if not grass_mesh:
		return

	_seagrass_mmi = MultiMeshInstance3D.new()
	_seagrass_mmi.name = "SeagrassMultiMesh"
	_seagrass_mmi.material_override = _seagrass_material
	_seagrass_mmi.visibility_range_end = 70.0
	_seagrass_mmi.visibility_range_end_margin = 15.0
	_seagrass_mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	_seagrass_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var count: int = 380
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = grass_mesh
	_seagrass_mmi.multimesh = mm

	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = count * 8

	# Scatter in shallow sunlit seabed: Y between -3.2m and -0.35m
	while placed < count and attempts < max_attempts:
		attempts += 1
		var x: float
		var z: float
		if rng.randf() < 0.35:
			# High concentration around Emerald Cove shallows
			x = rng.randf_range(8.0, 26.0)
			z = rng.randf_range(6.0, 24.0)
		else:
			var angle: float = rng.randf_range(0.0, TAU)
			var is_expanded: bool = (_terrain != null and _terrain.island_size > 200.0)
			var r_min: float = 230.0 if is_expanded else 35.0
			var r_max: float = 360.0 if is_expanded else 85.0
			var dist: float = rng.randf_range(r_min, r_max)
			x = cos(angle) * dist
			z = sin(angle) * dist

		var y: float = _terrain.get_height_at(x, z) if _terrain else -1.2
		if y < -3.2 or y > -0.35:
			continue

		var t: Transform3D = Transform3D()
		var s: float = rng.randf_range(0.75, 1.35)
		t = t.scaled(Vector3(s, s * rng.randf_range(0.85, 1.25), s))
		t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		t.origin = Vector3(x, y - 0.05, z)
		mm.set_instance_transform(placed, t)
		placed += 1

	mm.visible_instance_count = placed
	add_child(_seagrass_mmi)

func _create_procedural_seagrass_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 3 crossed ribbon blades in a natural tuft
	for b in range(3):
		var angle: float = float(b) * (PI / 3.0)
		var dir_x: float = cos(angle)
		var dir_z: float = sin(angle)
		var h: float = 1.15 + (float(b) * 0.15)
		var w: float = 0.12

		st.set_normal(Vector3(-dir_z, 0.0, dir_x))
		st.add_vertex(Vector3(-dir_x * w, 0.0, -dir_z * w))
		st.add_vertex(Vector3(dir_x * w, 0.0, dir_z * w))
		st.add_vertex(Vector3(dir_x * (w * 0.4), h, dir_z * (w * 0.4)))

		st.add_vertex(Vector3(-dir_x * w, 0.0, -dir_z * w))
		st.add_vertex(Vector3(dir_x * (w * 0.4), h, dir_z * (w * 0.4)))
		st.add_vertex(Vector3(-dir_x * (w * 0.4), h, -dir_z * (w * 0.4)))

	st.generate_normals()
	return st.commit()

# =============================================================================
# 3. RUSTIC WOODEN PIER & MOORED ACTIVE EXPEDITION BOAT
# =============================================================================
func _build_coastal_pier_and_boat() -> void:
	# Wooden fishing pier extending from shore at (13.5, 7.2) into Emerald Cove water
	_pier_root = Node3D.new()
	_pier_root.name = "RusticWoodenPier"
	add_child(_pier_root)

	var pier_start_x: float = 12.8
	var pier_start_z: float = 6.8
	var pier_deck_y: float = 0.28 # 28cm above water level Y=0

	# 6 pier plank segments extending into the water
	var pier_mat: StandardMaterial3D = StandardMaterial3D.new()
	pier_mat.albedo_color = Color(0.40, 0.30, 0.20) # Weathered cedar wood
	pier_mat.roughness = 0.88

	var pylon_mat: StandardMaterial3D = StandardMaterial3D.new()
	pylon_mat.albedo_color = Color(0.28, 0.24, 0.20) # Water-stained cedar logs
	pylon_mat.roughness = 0.92

	for i in range(5):
		var px: float = pier_start_x + (float(i) * 1.3)
		var pz: float = pier_start_z + (float(i) * 0.95)
		var ground_h: float = _terrain.get_height_at(px, pz) if _terrain else -1.2

		# Deck plank board
		var deck: MeshInstance3D = MeshInstance3D.new()
		var deck_box: BoxMesh = BoxMesh.new()
		deck_box.size = Vector3(1.4, 0.12, 1.4)
		deck.mesh = deck_box
		deck.material_override = pier_mat
		deck.position = Vector3(px, pier_deck_y, pz)
		deck.rotation.y = deg_to_rad(-36.0)
		deck.visibility_range_end = 150.0
		deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_pier_root.add_child(deck)

		# Support pilings into seabed
		var pylon_height: float = (pier_deck_y - ground_h) + 0.4
		var pylon: MeshInstance3D = MeshInstance3D.new()
		var cyl: CylinderMesh = CylinderMesh.new()
		cyl.top_radius = 0.11
		cyl.bottom_radius = 0.12
		cyl.height = pylon_height
		pylon.mesh = cyl
		pylon.material_override = pylon_mat
		pylon.position = Vector3(px, pier_deck_y - (pylon_height * 0.5), pz)
		pylon.visibility_range_end = 150.0
		pylon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_pier_root.add_child(pylon)

	# Moored Drivable Expedition Skiff tied to end of pier
	var boat_scn = preload("res://presentation/vehicles/drivable_boat.gd")
	_boat_root = boat_scn.new()
	_boat_root.name = "MooredExpeditionSkiff"
	_boat_base_pos = Vector3(19.2, -0.06, 11.5)
	_boat_root.position = _boat_base_pos
	_boat_root.rotation.y = deg_to_rad(-45.0)
	if _boat_root.has_method("setup_terrain"):
		_boat_root.setup_terrain(_terrain)
	add_child(_boat_root)

func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

# =============================================================================
# 4. SCHOOLING MARINE FISH SIMULATION
# =============================================================================
func _build_schooling_fish(rng: RandomNumberGenerator) -> void:
	var fish_mesh: ArrayMesh = _create_procedural_fish_mesh()
	if not fish_mesh:
		return

	# School 0: Emerald Salmon (14 fish in sheltered Emerald Cove)
	_spawn_school(fish_mesh, _salmon_material, 0, 14, Vector3(16.0, -1.2, 12.0), 5.5, rng)

	# School 1: Coastal Reef Sunfish (18 fish along western coastal shelf)
	_spawn_school(fish_mesh, _sunfish_material, 1, 18, Vector3(-25.0, -1.8, 22.0), 12.0, rng)

	# School 2: Minecraft-Style Tropical Clownfish (20 vibrant orange & white striped fish around shallow reefs)
	_spawn_school(fish_mesh, _clownfish_material, 2, 20, Vector3(22.5, -1.3, 16.5), 6.5, rng)

	# School 3: Neon Blue Tang (16 electric blue & yellow fish in outer reef waters)
	_spawn_school(fish_mesh, _tang_material, 3, 16, Vector3(14.0, -1.6, 26.0), 8.0, rng)

	# School 4: Grand Emerald Lake Salmon (24 fish in vast inland lake)
	_spawn_school(fish_mesh, _salmon_material, 4, 24, Vector3(95.0, -1.4, 85.0), 28.0, rng)

	# School 5: Northern Mist Lake Golden Perch (16 fish in Whispering Mist Lake)
	_spawn_school(fish_mesh, _sunfish_material, 5, 16, Vector3(-15.0, -1.0, -185.0), 16.0, rng)

	# School 6: Southern Cape Solitude Bluefish (18 fish in Southern Ocean Bay)
	_spawn_school(fish_mesh, _tang_material, 6, 18, Vector3(-45.0, -2.0, 160.0), 22.0, rng)

	# School 7: Western Coves Reef Sunfish (18 fish in Western coastal coves)
	_spawn_school(fish_mesh, _clownfish_material, 7, 18, Vector3(-140.0, -1.8, 20.0), 20.0, rng)

func _spawn_school(mesh: Mesh, mat: Material, school_id: int, count: int, center: Vector3, radius: float, rng: RandomNumberGenerator) -> void:
	_school_centers[school_id] = center
	_school_base_positions[school_id] = center

	for i in range(count):
		var agent: FishAgent = FishAgent.new()
		agent.school_id = school_id
		agent.swim_speed = rng.randf_range(1.8, 3.2)
		agent.body_length = rng.randf_range(0.35, 0.55)

		var offset: Vector3 = Vector3(
			rng.randf_range(-radius, radius),
			rng.randf_range(-0.8, 0.4),
			rng.randf_range(-radius, radius)
		)
		agent.position = center + offset
		# Bound strictly underwater: Y between -3.5m and -0.4m
		agent.position.y = clampf(agent.position.y, -3.2, -0.4)

		var heading: float = rng.randf_range(0.0, TAU)
		agent.target_heading = heading
		agent.velocity = Vector3(-sin(heading), 0.0, -cos(heading)) * agent.swim_speed

		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.name = "Fish_%d_%d" % [school_id, i]
		mi.mesh = mesh
		mi.material_override = mat
		mi.scale = Vector3.ONE * agent.body_length
		mi.position = agent.position
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 50.0
		mi.visibility_range_end_margin = 10.0
		add_child(mi)

		agent.node = mi
		_fish_agents.append(agent)

func _create_procedural_fish_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Low-poly streamlined fish: Snout at -Z (0.0, 0.0, -0.45), Tail at +Z (0.0, 0.0, 0.45)
	var snout: Vector3 = Vector3(0.0, 0.0, -0.45)
	var mid_top: Vector3 = Vector3(0.0, 0.12, -0.05)
	var mid_bot: Vector3 = Vector3(0.0, -0.10, -0.05)
	var mid_left: Vector3 = Vector3(-0.075, 0.0, -0.05)
	var mid_right: Vector3 = Vector3(0.075, 0.0, -0.05)
	var tail_peduncle: Vector3 = Vector3(0.0, 0.0, 0.35)

	# Tail fin vertices
	var fin_top: Vector3 = Vector3(0.0, 0.14, 0.55)
	var fin_bot: Vector3 = Vector3(0.0, -0.12, 0.55)
	var fin_mid: Vector3 = Vector3(0.0, 0.0, 0.42)

	# Anterior body
	_add_tri(st, snout, mid_left, mid_top)
	_add_tri(st, snout, mid_top, mid_right)
	_add_tri(st, snout, mid_bot, mid_left)
	_add_tri(st, snout, mid_right, mid_bot)

	# Posterior body
	_add_tri(st, mid_top, mid_left, tail_peduncle)
	_add_tri(st, mid_right, mid_top, tail_peduncle)
	_add_tri(st, mid_left, mid_bot, tail_peduncle)
	_add_tri(st, mid_bot, mid_right, tail_peduncle)

	# Caudal tail fin (two-sided)
	_add_tri(st, tail_peduncle, fin_top, fin_mid)
	_add_tri(st, tail_peduncle, fin_mid, fin_top)
	_add_tri(st, tail_peduncle, fin_mid, fin_bot)
	_add_tri(st, tail_peduncle, fin_bot, fin_mid)

	# Small dorsal fin
	var d_front: Vector3 = Vector3(0.0, 0.10, -0.08)
	var d_tip: Vector3 = Vector3(0.0, 0.19, 0.06)
	var d_back: Vector3 = Vector3(0.0, 0.07, 0.12)
	_add_tri(st, d_front, d_tip, d_back)
	_add_tri(st, d_front, d_back, d_tip)

	st.generate_normals()
	return st.commit()

# =============================================================================
# 5. AMBIENT BUBBLE PARTICLES
# =============================================================================
func _build_ambient_bubble_streams() -> void:
	_bubble_particles = GPUParticles3D.new()
	_bubble_particles.name = "AquaticBubbles"
	_bubble_particles.position = Vector3(16.0, -1.8, 12.0) # Emerald Cove center
	_bubble_particles.amount = 45
	_bubble_particles.lifetime = 3.5
	_bubble_particles.explosiveness = 0.0
	_bubble_particles.randomness = 0.65

	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(12.0, 1.2, 10.0)
	mat.direction = Vector3.UP
	mat.spread = 15.0
	mat.initial_velocity_min = 0.45
	mat.initial_velocity_max = 0.95
	mat.gravity = Vector3(0.0, 0.15, 0.0) # Upward buoyant drift
	mat.scale_min = 0.04
	mat.scale_max = 0.12
	_bubble_particles.process_material = mat

	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12
	var b_mat: StandardMaterial3D = StandardMaterial3D.new()
	b_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	b_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.45)
	b_mat.roughness = 0.15
	sphere.material = b_mat
	_bubble_particles.draw_pass_1 = sphere

	add_child(_bubble_particles)

# =============================================================================
# RUNTIME PHYSICS & FLOCKING LOCOMOTION
# =============================================================================
func _process(delta: float) -> void:
	_boat_time += delta

	# 1. Physical Gerstner Wave Bobbing for Moored Boat (when not actively driven)
	if _boat_root and not ("is_driven" in _boat_root and _boat_root.is_driven):
		# Synchronized with water.gdshader Gerstner harmonics
		var wave_amp: float = 0.08
		var bob_y: float = sin(_boat_time * 1.6 + 0.5) * wave_amp + (cos(_boat_time * 2.8) * (wave_amp * 0.35))
		var pitch_roll: float = sin(_boat_time * 1.4) * 0.045
		var roll: float = cos(_boat_time * 1.8 + 0.3) * 0.055

		_boat_root.position.y = _boat_base_pos.y + bob_y
		_boat_root.rotation.x = pitch_roll
		_boat_root.rotation.z = roll

	# 2. Update Schooling Fish Locomotion
	if _fish_agents.is_empty():
		return

	# Slowly orbit school anchor centers around their respective bay / lake regions
	for sid in _school_centers:
		var base_pos: Vector3 = _school_base_positions.get(sid, _school_centers[sid])
		var orbit_angle: float = _boat_time * 0.08 * (1.0 if (sid % 2 == 0) else -0.8) + float(sid) * 1.5
		var center_radius: float = 6.0 if sid == 0 else (18.0 if (sid == 4 or sid == 6) else 10.0)
		_school_centers[sid] = Vector3(
			base_pos.x + cos(orbit_angle) * center_radius,
			base_pos.y,
			base_pos.z + sin(orbit_angle) * center_radius
		)

	var player_pos: Vector3 = _player_node.global_position if _player_node else Vector3(9999.0, 9999.0, 9999.0)

	for agent in _fish_agents:
		var school_center: Vector3 = _school_centers.get(agent.school_id, agent.position)

		# Vector toward school center (cohesion)
		var to_center: Vector3 = school_center - agent.position
		to_center.y = 0.0 # Maintain shallow horizontal schooling
		var center_dist: float = to_center.length()
		var steer: Vector3 = Vector3.ZERO
		if center_dist > 4.5:
			steer += to_center.normalized() * 1.4

		# Player disturbance avoidance (flee if player approaches within 4.5m)
		var to_player: Vector3 = agent.position - player_pos
		var p_dist: float = to_player.length()
		if p_dist < 4.5:
			steer += to_player.normalized() * (4.5 - p_dist) * 3.2

		# Apply steering to velocity
		agent.velocity = agent.velocity.lerp(agent.velocity.normalized() * agent.swim_speed + steer, delta * 2.5)
		agent.velocity.y = lerpf(agent.velocity.y, 0.0, delta * 4.0) # Damp vertical motion

		# Move agent
		agent.position += agent.velocity * delta

		# Enforce water surface boundary: stay submerged below Y = -0.35m
		agent.position.y = clampf(agent.position.y, -3.2, -0.38)

		# Orient fish along travel heading
		if agent.velocity.length_squared() > 0.01:
			var target_yaw: float = atan2(-agent.velocity.x, -agent.velocity.z)
			agent.node.rotation.y = lerp_angle(agent.node.rotation.y, target_yaw, delta * 6.0)

		agent.node.position = agent.position

	# Animate graceful Manta Ray gliding
	for i in range(_manta_rays.size()):
		var ray = _manta_rays[i]
		if not is_instance_valid(ray):
			continue
		var angle: float = _boat_time * 0.12 + float(i) * (TAU / 3.0)
		var r: float = 22.0 + sin(_boat_time * 0.25 + float(i)) * 3.5
		ray.position = Vector3(cos(angle) * r, -1.6 + sin(_boat_time * 0.5 + float(i)) * 0.25, sin(angle) * r)
		ray.rotation.y = angle + PI * 0.5
		ray.rotation.z = sin(_boat_time * 1.5 + float(i)) * 0.12

	# Animate graceful Sea Turtles (swimming in circular patrols with flapping flippers)
	for i in range(_sea_turtles.size()):
		var turtle = _sea_turtles[i]
		if not is_instance_valid(turtle):
			continue
		var t_time: float = _boat_time * 0.28 + float(i) * 2.1
		var t_radius: float = 7.5 + float(i) * 3.5
		var origin_c: Vector3 = Vector3(16.0 + float(i) * 5.0, -0.85, 12.0 + float(i) * 4.0)
		turtle.position = origin_c + Vector3(cos(t_time) * t_radius, sin(t_time * 1.5) * 0.15, sin(t_time) * t_radius)
		turtle.rotation.y = t_time + PI * 0.5
		turtle.rotation.z = sin(t_time * 2.0) * 0.08
		var fl = turtle.get_node_or_null("FlipperL") as Node3D
		var fr = turtle.get_node_or_null("FlipperR") as Node3D
		if fl:
			fl.rotation.z = sin(t_time * 3.5) * 0.32
		if fr:
			fr.rotation.z = -sin(t_time * 3.5) * 0.32

	# Animate Bioluminescent Sea Pickles pulsing emission
	if _pickles_material:
		_pickles_material.emission_energy_multiplier = 0.85 + 0.35 * sin(_boat_time * 2.2)

func _build_coral_reefs(rng: RandomNumberGenerator) -> void:
	_coral_mmi = MultiMeshInstance3D.new()
	_coral_mmi.name = "CoralReefMultiMesh"
	_coral_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_coral_mmi.visibility_range_end = 75.0
	_coral_mmi.visibility_range_end_margin = 15.0

	_coral_material = StandardMaterial3D.new()
	_coral_material.albedo_color = Color(0.92, 0.44, 0.55) # Living coral pink
	_coral_material.roughness = 0.70
	_coral_material.emission_enabled = true
	_coral_material.emission = Color(0.20, 0.75, 0.85) # Gentle cyan bioluminescence
	_coral_material.emission_energy_multiplier = 0.45
	_coral_mmi.material_override = _coral_material

	var c_mesh: SphereMesh = SphereMesh.new()
	c_mesh.radius = 0.55
	c_mesh.height = 0.75
	c_mesh.radial_segments = 8
	c_mesh.rings = 6

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = c_mesh
	var max_corals: int = 64
	mm.instance_count = max_corals
	_coral_mmi.multimesh = mm

	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = max_corals * 10
	while placed < max_corals and attempts < max_attempts:
		attempts += 1
		var x: float
		var z: float
		if rng.randf() < 0.45:
			x = rng.randf_range(12.0, 32.0)
			z = rng.randf_range(8.0, 28.0)
		else:
			var angle: float = rng.randf_range(0.0, TAU)
			var is_expanded: bool = (_terrain != null and _terrain.island_size > 200.0)
			var r_min: float = 235.0 if is_expanded else 40.0
			var r_max: float = 370.0 if is_expanded else 90.0
			var dist: float = rng.randf_range(r_min, r_max)
			x = cos(angle) * dist
			z = sin(angle) * dist

		var y: float = _terrain.get_height_at(x, z) if _terrain else -1.5
		if y < -3.8 or y > -0.4:
			continue

		var t: Transform3D = Transform3D()
		var s: float = rng.randf_range(0.8, 1.6)
		t = t.scaled(Vector3(s, s * 0.75, s))
		t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		t.origin = Vector3(x, y - 0.05, z)
		mm.set_instance_transform(placed, t)
		placed += 1

	mm.visible_instance_count = placed
	add_child(_coral_mmi)

func _build_bioluminescent_sea_pickles(rng: RandomNumberGenerator) -> void:
	_pickles_mmi = MultiMeshInstance3D.new()
	_pickles_mmi.name = "SeaPicklesMultiMesh"
	_pickles_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pickles_mmi.material_override = _pickles_material
	_pickles_mmi.visibility_range_end = 65.0
	_pickles_mmi.visibility_range_end_margin = 15.0

	# Cluster of 4 small glowing cups
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cup_offsets: Array[Vector3] = [
		Vector3(-0.08, 0.0, -0.06),
		Vector3(0.09, 0.0, -0.04),
		Vector3(-0.04, 0.0, 0.08),
		Vector3(0.07, 0.0, 0.07)
	]
	for off in cup_offsets:
		var ch: float = 0.28 + (off.x * 0.4)
		var cr: float = 0.06
		for s in range(5):
			var a0: float = float(s) * (TAU / 5.0)
			var a1: float = float(s + 1) * (TAU / 5.0)
			var p0: Vector3 = off + Vector3(cos(a0) * cr, 0.0, sin(a0) * cr)
			var p1: Vector3 = off + Vector3(cos(a1) * cr, 0.0, sin(a1) * cr)
			var p2: Vector3 = off + Vector3(cos(a1) * cr * 0.85, ch, sin(a1) * cr * 0.85)
			var p3: Vector3 = off + Vector3(cos(a0) * cr * 0.85, ch, sin(a0) * cr * 0.85)
			st.set_normal(Vector3(cos(a0), 0.2, sin(a0)).normalized())
			st.add_vertex(p0)
			st.add_vertex(p1)
			st.add_vertex(p2)
			st.add_vertex(p0)
			st.add_vertex(p2)
			st.add_vertex(p3)
	st.generate_normals()
	var pickle_mesh: ArrayMesh = st.commit()

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = pickle_mesh
	var count: int = 56
	mm.instance_count = count
	_pickles_mmi.multimesh = mm

	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = count * 10
	while placed < count and attempts < max_attempts:
		attempts += 1
		var x: float
		var z: float
		if rng.randf() < 0.45:
			x = rng.randf_range(11.0, 28.0)
			z = rng.randf_range(7.0, 26.0)
		else:
			var angle: float = rng.randf_range(0.0, TAU)
			var is_expanded: bool = (_terrain != null and _terrain.island_size > 200.0)
			var r_min: float = 235.0 if is_expanded else 40.0
			var r_max: float = 360.0 if is_expanded else 90.0
			var dist: float = rng.randf_range(r_min, r_max)
			x = cos(angle) * dist
			z = sin(angle) * dist

		var y: float = _terrain.get_height_at(x, z) if _terrain else -1.8
		if y < -4.2 or y > -0.35:
			continue

		var t: Transform3D = Transform3D()
		var s: float = rng.randf_range(0.85, 1.35)
		t = t.scaled(Vector3(s, s, s))
		t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		t.origin = Vector3(x, y - 0.02, z)
		mm.set_instance_transform(placed, t)
		placed += 1

	mm.visible_instance_count = placed
	add_child(_pickles_mmi)

func _build_sea_turtles(rng: RandomNumberGenerator) -> void:
	var shell_mat: StandardMaterial3D = StandardMaterial3D.new()
	shell_mat.albedo_color = Color(0.24, 0.45, 0.22) # Olive sea turtle carapace
	shell_mat.roughness = 0.65

	var skin_mat: StandardMaterial3D = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.38, 0.52, 0.30)
	skin_mat.roughness = 0.75

	var turtle_coords: Array[Vector3] = [
		Vector3(14.5, -0.75, 15.5),
		Vector3(22.0, -1.10, 8.5),
		Vector3(-22.0, -0.90, 18.0)
	]

	for i in range(turtle_coords.size()):
		var root: Node3D = Node3D.new()
		root.name = "SeaTurtle_%d" % i
		root.position = turtle_coords[i]

		# Carapace (oval dome shell)
		var shell: MeshInstance3D = MeshInstance3D.new()
		var s_mesh: SphereMesh = SphereMesh.new()
		s_mesh.radius = 0.45
		s_mesh.height = 0.38
		s_mesh.radial_segments = 10
		s_mesh.rings = 6
		shell.mesh = s_mesh
		shell.material_override = shell_mat
		shell.scale = Vector3(1.0, 0.55, 1.35)
		root.add_child(shell)

		# Head
		var head: MeshInstance3D = MeshInstance3D.new()
		var h_mesh: SphereMesh = SphereMesh.new()
		h_mesh.radius = 0.16
		h_mesh.height = 0.22
		head.mesh = h_mesh
		head.material_override = skin_mat
		head.position = Vector3(0.0, 0.02, -0.72)
		root.add_child(head)

		# Left Front Flipper
		var fl_l: MeshInstance3D = MeshInstance3D.new()
		fl_l.name = "FlipperL"
		var fl_mesh: BoxMesh = BoxMesh.new()
		fl_mesh.size = Vector3(0.55, 0.04, 0.22)
		fl_l.mesh = fl_mesh
		fl_l.material_override = skin_mat
		fl_l.position = Vector3(-0.48, -0.05, -0.32)
		fl_l.rotation.y = deg_to_rad(-25.0)
		root.add_child(fl_l)

		# Right Front Flipper
		var fl_r: MeshInstance3D = MeshInstance3D.new()
		fl_r.name = "FlipperR"
		fl_r.mesh = fl_mesh
		fl_r.material_override = skin_mat
		fl_r.position = Vector3(0.48, -0.05, -0.32)
		fl_r.rotation.y = deg_to_rad(25.0)
		root.add_child(fl_r)

		_sea_turtles.append(root)
		add_child(root)

func _build_sunken_galleon() -> void:
	_sunken_galleon = Node3D.new()
	_sunken_galleon.name = "SunkenGalleon"
	var gx: float = 24.5
	var gz: float = 18.5
	var gy: float = _terrain.get_height_at(gx, gz) if _terrain else -2.5
	_sunken_galleon.position = Vector3(gx, gy, gz)
	_sunken_galleon.rotation.y = deg_to_rad(35.0)
	_sunken_galleon.rotation.z = deg_to_rad(12.0)
	add_child(_sunken_galleon)

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.22, 0.18, 0.15)
	wood_mat.roughness = 0.95

	# Keel beam
	var keel: MeshInstance3D = MeshInstance3D.new()
	var k_box: BoxMesh = BoxMesh.new()
	k_box.size = Vector3(1.2, 0.6, 9.5)
	keel.mesh = k_box
	keel.material_override = wood_mat
	_sunken_galleon.add_child(keel)

	# 6 curved exposed rib frames
	for i in range(6):
		var rib: MeshInstance3D = MeshInstance3D.new()
		var r_box: BoxMesh = BoxMesh.new()
		r_box.size = Vector3(3.8, 1.8, 0.28)
		rib.mesh = r_box
		rib.material_override = wood_mat
		rib.position = Vector3(0.0, 0.8, -3.5 + float(i) * 1.4)
		_sunken_galleon.add_child(rib)

	# Broken main mast
	var mast: MeshInstance3D = MeshInstance3D.new()
	var m_cyl: CylinderMesh = CylinderMesh.new()
	m_cyl.top_radius = 0.18
	m_cyl.bottom_radius = 0.24
	m_cyl.height = 6.8
	mast.mesh = m_cyl
	mast.material_override = wood_mat
	mast.position = Vector3(0.0, 3.2, 0.5)
	mast.rotation.x = deg_to_rad(22.0)
	_sunken_galleon.add_child(mast)

	# Sunken Treasure Chest
	_chest_node = Node3D.new()
	_chest_node.name = "SunkenTreasureChest"
	_chest_node.position = Vector3(0.0, 0.35, 1.2)
	_sunken_galleon.add_child(_chest_node)

	var chest_mesh: MeshInstance3D = MeshInstance3D.new()
	var c_box: BoxMesh = BoxMesh.new()
	c_box.size = Vector3(0.85, 0.55, 0.60)
	chest_mesh.mesh = c_box
	var c_mat: StandardMaterial3D = StandardMaterial3D.new()
	c_mat.albedo_color = Color(0.55, 0.40, 0.18)
	c_mat.metallic = 0.55
	c_mat.roughness = 0.65
	chest_mesh.material_override = c_mat
	_chest_node.add_child(chest_mesh)

	var chest_label: Label3D = Label3D.new()
	chest_label.name = "ChestLabel"
	chest_label.text = "💎 Rương Kho Báu Đáy Biển [E]"
	chest_label.font_size = 18
	chest_label.modulate = Color(1.0, 0.90, 0.45)
	chest_label.outline_modulate = Color(0.05, 0.1, 0.2, 0.9)
	chest_label.outline_size = 4
	chest_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	chest_label.position = Vector3(0.0, 0.65, 0.0)
	_chest_node.add_child(chest_label)

func _build_gliding_manta_rays() -> void:
	var ray_mat: StandardMaterial3D = StandardMaterial3D.new()
	ray_mat.albedo_color = Color(0.12, 0.22, 0.35)
	ray_mat.roughness = 0.45

	for i in range(3):
		var ray: Node3D = Node3D.new()
		ray.name = "MantaRay_%d" % i
		var prism: PrismMesh = PrismMesh.new()
		prism.size = Vector3(2.4, 0.22, 1.8)
		var mesh_inst: MeshInstance3D = MeshInstance3D.new()
		mesh_inst.mesh = prism
		mesh_inst.material_override = ray_mat
		mesh_inst.rotation.x = deg_to_rad(-90.0)
		ray.add_child(mesh_inst)

		var start_angle: float = float(i) * (TAU / 3.0)
		ray.position = Vector3(cos(start_angle) * 22.0, -1.8, sin(start_angle) * 22.0)
		_manta_rays.append(ray)
		add_child(ray)

func get_nearby_interactable(player_pos: Vector3) -> Dictionary:
	if _chest_node and not _chest_looted:
		var c_pos: Vector3 = _chest_node.global_position if _chest_node.is_inside_tree() else (_chest_node.position + _sunken_galleon.position)
		if c_pos.distance_to(player_pos) <= 3.2:
			return {"type": "SUNKEN_CHEST", "id": "SunkenChest", "prompt": "[E] Trục vớt Rương Kho Báu Đáy Biển"}
	return {}

func loot_sunken_chest() -> Dictionary:
	if _chest_looted or not _chest_node:
		return {}
	_chest_looted = true
	var label = _chest_node.get_node_or_null("ChestLabel") as Label3D
	if label:
		label.text = "✦ Đã Trục Vớt Rương ✦"
		label.modulate = Color(0.6, 0.65, 0.70)
	var loot: Dictionary = {
		"title": "Cổ Vật Hải Đồ & Vàng Bạc Cướp Biển",
		"gold": 250,
		"relic_id": "sunken_astrolabe"
	}
	sunken_chest_looted.emit(loot)
	print("[MarineEcosystem] Sunken treasure chest salvaged!")
	return loot

func is_chest_looted() -> bool:
	return _chest_looted

func get_boat() -> CharacterBody3D:
	return _boat_root as CharacterBody3D
