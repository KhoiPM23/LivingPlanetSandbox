class_name VegetationScatter
extends Node3D

## Deterministically scatters multi-tiered vegetation, rock formations, understory bushes,
## wildflowers, fallen logs, and landmark monolith across IslandTerrain.
## Uses MultiMeshInstance3D for dense multi-blade grass tufts to maintain 35–45+ FPS on Intel Iris Xe.

@export var tree_count: int = 55
@export var rock_count: int = 40
@export var grass_count: int = 900
@export var understory_count: int = 45

var _grass_multimesh: MultiMeshInstance3D = null
var _active_foliage_materials: Array[ShaderMaterial] = []
var active_season: int = 0

# Static asset caches
static var _cached_grass_mesh: Mesh = null
static var _cached_grass_tex: Texture2D = null
static var _cached_bush_meshes: Array = []
static var _cached_bush_mat: Material = null
static var _cached_bush_stem_mat: StandardMaterial3D = null
static var _cached_bush_leaf_mat: ShaderMaterial = null
static var _cached_nature_props: Dictionary = {}

static func _init_asset_cache() -> void:
	if _cached_grass_mesh != null:
		return

	# Load Forest Pack (KayKit CC0) for grass and deciduous trees
	var f_scn = load("res://presentation/assets/models/forest.glb") as PackedScene
	if f_scn:
		var f_root: Node = f_scn.instantiate()
		if f_root:
			var g_node: MeshInstance3D = f_root.find_child("Grass_2_D_Color1", true, false) as MeshInstance3D
			if g_node and g_node.mesh:
				_cached_grass_mesh = g_node.mesh
				if g_node.mesh.get_surface_count() > 0:
					var m = g_node.mesh.surface_get_material(0)
					if m is StandardMaterial3D and m.albedo_texture:
						_cached_grass_tex = m.albedo_texture
			for ok in ["Tree_1_A_Color1", "Tree_1_C_Color1", "Tree_3_C_Color1"]:
				var o_node: MeshInstance3D = f_root.find_child(ok, true, false) as MeshInstance3D
				if o_node and o_node.mesh:
					var o_mat = o_node.mesh.surface_get_material(0) if o_node.mesh.get_surface_count() > 0 else null
					if o_mat is StandardMaterial3D:
						var custom_mat: StandardMaterial3D = o_mat.duplicate()
						custom_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
						custom_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
						o_mat = custom_mat
					_cached_nature_props[ok] = {
						"mesh": o_node.mesh,
						"mat": o_mat
					}
			f_root.free()

	# Load Game-Ready Hero Bushes (Lilac saplings with alpha-scissor leaf cards)
	for bpath in ["res://presentation/assets/foliage/bush1.gltf", "res://presentation/assets/foliage/bush2.gltf"]:
		var b_scn = load(bpath) as PackedScene
		if b_scn:
			var b_root: Node = b_scn.instantiate()
			if b_root and b_root.get_child_count() > 0:
				var mi: MeshInstance3D = b_root.get_child(0) as MeshInstance3D
				if mi and mi.mesh:
					_cached_bush_meshes.append(mi.mesh)
			if b_root:
				b_root.free()

	if _cached_bush_stem_mat == null:
		_cached_bush_stem_mat = StandardMaterial3D.new()
		var alb = load("res://presentation/assets/foliage/Lilac_bark_color.jpg")
		if alb is Texture2D:
			_cached_bush_stem_mat.albedo_texture = alb
		var nrm = load("res://presentation/assets/foliage/Lilac_bark_normal.jpg")
		if nrm is Texture2D:
			_cached_bush_stem_mat.normal_enabled = true
			_cached_bush_stem_mat.normal_texture = nrm
		_cached_bush_stem_mat.roughness = 0.88

	if _cached_bush_leaf_mat == null:
		_cached_bush_leaf_mat = ShaderMaterial.new()
		_cached_bush_leaf_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
		_cached_bush_leaf_mat.set_shader_parameter("use_texture", true)
		_cached_bush_leaf_mat.set_shader_parameter("use_alpha_scissor", true)
		_cached_bush_leaf_mat.set_shader_parameter("alpha_scissor_threshold", 0.45)
		var c_alb = load("res://presentation/assets/foliage/lilac_cards_color.png")
		if c_alb is Texture2D:
			_cached_bush_leaf_mat.set_shader_parameter("albedo_texture", c_alb)
		var c_nrm = load("res://presentation/assets/foliage/lilac_cards_normal.jpg")
		if c_nrm is Texture2D:
			_cached_bush_leaf_mat.set_shader_parameter("use_normal_texture", true)
			_cached_bush_leaf_mat.set_shader_parameter("normal_texture", c_nrm)
		var c_rgh = load("res://presentation/assets/foliage/lilac_cards_roughness.jpg")
		if c_rgh is Texture2D:
			_cached_bush_leaf_mat.set_shader_parameter("use_roughness_texture", true)
			_cached_bush_leaf_mat.set_shader_parameter("roughness_texture", c_rgh)
		_cached_bush_leaf_mat.set_shader_parameter("roughness", 0.82)
		_cached_bush_leaf_mat.set_shader_parameter("wind_speed", 1.3)
		_cached_bush_leaf_mat.set_shader_parameter("wind_strength", 0.20)
		_cached_bush_leaf_mat.set_shader_parameter("backlight_strength", 0.38)
		_cached_bush_mat = _cached_bush_leaf_mat

	# Load Nature Kit (Kenney CC0)
	var n_scn = load("res://presentation/assets/models/nature.glb") as PackedScene
	if n_scn:
		var n_root: Node = n_scn.instantiate()
		if n_root:
			var prop_keys: Array = [
				"grass_leafs", "grass_leafsLarge", "grass_large",
				"flower_purpleA", "flower_purpleC", "flower_yellowA", "flower_yellowC", "flower_redA",
				"log", "log_large", "log_stack", "stump_round", "stump_square",
				"mushroom_redGroup", "mushroom_tanGroup", "mushroom_tanTall",
				"plant_bushDetailed", "plant_bushLarge", "plant_bush",
				"lily_large", "lily_small", "plant_flatTall", "plant_flatShort",
				"rock_smallC", "rock_largeA", "rock_tallA", "rock_tallC",
				"tree_pineTallA", "tree_pineDefaultA", "tree_pineSmallA",
				"tree_oak_fall", "tree_detailed_fall", "tree_default_fall"
			]
			for pk in prop_keys:
				var mi: MeshInstance3D = n_root.find_child(pk, true, false) as MeshInstance3D
				if mi and mi.mesh:
					var p_mat = mi.mesh.surface_get_material(0) if mi.mesh.get_surface_count() > 0 else null
					var final_mesh: Mesh = mi.mesh
					if pk == "stump_round" or pk == "stump_square" or pk == "log" or pk == "log_large":
						var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
						wood_mat.albedo_color = Color(0.44, 0.32, 0.20)
						wood_mat.roughness = 0.88
						wood_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
						wood_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
						p_mat = wood_mat
					elif p_mat is StandardMaterial3D:
						var custom_mat: StandardMaterial3D = p_mat.duplicate()
						custom_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
						custom_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
						p_mat = custom_mat

					# Botanical color grading: remap stylized turquoise flower stems to natural foliage green
					if pk.begins_with("flower_") and mi.mesh is ArrayMesh:
						var am: ArrayMesh = mi.mesh as ArrayMesh
						if am.get_surface_count() > 0:
							var arrays: Array = am.surface_get_arrays(0)
							var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
							if colors.size() > 0:
								var new_colors: PackedColorArray = PackedColorArray()
								new_colors.resize(colors.size())
								for ci in range(colors.size()):
									var c: Color = colors[ci]
									if c.r < 0.35 and c.g > 0.65 and c.b > 0.55:
										new_colors[ci] = Color(0.24, 0.44, 0.16, 1.0)
									else:
										new_colors[ci] = c
								arrays[Mesh.ARRAY_COLOR] = new_colors
								var modified_mesh: ArrayMesh = ArrayMesh.new()
								modified_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
								final_mesh = modified_mesh

					_cached_nature_props[pk] = {
						"mesh": final_mesh,
						"mat": p_mat
					}
			n_root.free()

func register_foliage_material(mat: ShaderMaterial) -> void:
	if mat and not _active_foliage_materials.has(mat):
		_active_foliage_materials.append(mat)
		_apply_season_to_material(mat, active_season, 1.0)

## Dynamic Actor Trampling & Foliage Parting (Zelda BotW / RDR2 Interaction)
func update_actor_interaction(actor_pos: Vector3, radius: float = 1.45, push_strength: float = 0.65) -> void:
	if _cached_bush_leaf_mat and not _active_foliage_materials.has(_cached_bush_leaf_mat):
		_active_foliage_materials.append(_cached_bush_leaf_mat)
	for mat in _active_foliage_materials:
		if is_instance_valid(mat):
			mat.set_shader_parameter("player_pos", actor_pos)
			mat.set_shader_parameter("player_radius", radius)
			mat.set_shader_parameter("player_push_strength", push_strength)

func apply_season_phenology(season: int, blend: float = 1.0) -> void:
	active_season = season
	_init_asset_cache()
	if _cached_bush_leaf_mat and not _active_foliage_materials.has(_cached_bush_leaf_mat):
		_active_foliage_materials.append(_cached_bush_leaf_mat)
	for mat in _active_foliage_materials:
		if is_instance_valid(mat):
			_apply_season_to_material(mat, season, blend)

func _apply_season_to_material(mat: ShaderMaterial, season: int, blend: float) -> void:
	var tint: Vector3 = Vector3(1.0, 1.0, 1.0)
	var weight: float = 0.0
	var frost: float = 0.0
	match season:
		0: # SPRING
			tint = Vector3(1.08, 1.15, 0.92)
			weight = 0.55 * blend
			frost = 0.0
		1: # SUMMER
			tint = Vector3(0.95, 1.05, 0.95)
			weight = 0.35 * blend
			frost = 0.0
		2: # AUTUMN
			tint = Vector3(1.45, 0.88, 0.42)
			weight = 0.85 * blend
			frost = 0.05 * blend
		3: # WINTER
			tint = Vector3(0.88, 0.95, 1.05)
			weight = 0.70 * blend
			frost = 0.45 * blend
	mat.set_shader_parameter("season_tint", tint)
	mat.set_shader_parameter("season_tint_weight", weight)
	mat.set_shader_parameter("frost_amount", frost)

func scatter(terrain: IslandTerrain, seed_val: int = 1337, registry: EntityRegistry = null, grid: EnvironmentalGrid = null, config: WorldGenerationConfig = null) -> void:
	# Clear existing children if regenerating
	for child in get_children():
		child.queue_free()

	_init_asset_cache()

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val

	var density: float = config.vegetation_density if config != null else 1.0
	var is_expanded: bool = terrain != null and terrain.island_size > 200.0
	var base_trees: int = 65 if is_expanded else tree_count
	var base_grass: int = 3200 if is_expanded else grass_count
	var base_understory: int = 75 if is_expanded else understory_count
	var final_trees: int = int(base_trees * density)
	var final_grass: int = int(base_grass * density)
	var final_understory: int = int(base_understory * density)

	_scatter_landmark(terrain, registry, grid)
	_scatter_trees(terrain, rng, registry, grid, final_trees)
	if is_expanded:
		_scatter_canopy_pines_multimesh(terrain, rng, grid, int(2000 * density))
		_scatter_wildflowers_multimesh(terrain, rng, grid, int(2000 * density))
	_scatter_tropical_rainforest_multimesh(terrain, rng, grid, density, is_expanded)
	_scatter_rocks(terrain, rng, grid)
	_scatter_understory(terrain, rng, grid, final_understory)
	_scatter_grass_multimesh(terrain, rng, grid, final_grass)

func _scatter_landmark(terrain: IslandTerrain, registry: EntityRegistry = null, grid: EnvironmentalGrid = null) -> void:
	var peak_pos: Vector2 = terrain.get_peak_position() if terrain else Vector2(-24.0, -24.0)
	var peak_x: float = peak_pos.x
	var peak_z: float = peak_pos.y
	var peak_y: float = terrain.get_height_at(peak_x, peak_z)

	var monolith: LandmarkMonolith = LandmarkMonolith.new()
	monolith.name = "SummitMonolith"
	monolith.position = Vector3(peak_x, peak_y, peak_z)
	add_child(monolith)

	if registry:
		var env_info: Dictionary = grid.get_environment_at(peak_x, peak_z) if grid != null else {}
		registry.spawn_entity("landmark", monolith.position, {
			"type": "ancient_monolith",
			"active": true,
			"biome": env_info.get("biome_name", "Alpine Granite Summit")
		})

func _scatter_trees(terrain: IslandTerrain, rng: RandomNumberGenerator, registry: EntityRegistry = null, grid: EnvironmentalGrid = null, target_count: int = 55) -> void:
	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = target_count * 12
	var half_size: float = terrain.island_size * 0.42
	var is_canonical: bool = (terrain == null or terrain.island_seed == 1337)

	var glade_pos: Vector2 = terrain.get_glade_position() if terrain else Vector2(9.0, 3.5)
	var lake_pos: Vector2 = terrain.get_lake_position() if terrain else Vector2(16.0, 14.0)
	var peak_pos: Vector2 = terrain.get_peak_position() if terrain else Vector2(-24.0, -24.0)
	var bluff_pos: Vector2 = terrain.get_bluff_position() if terrain else Vector2(24.0, 16.0)

	# Subdivided into organic groves across the showcase region:
	# Grove 1: Whispering Forest Stand (dense pines/oaks framing trail entrance)
	# Grove 2: North Ridge Conifers (framing Summit Monolith backdrop)
	# Grove 3: Creek & Valley Copse (shading the winding creek)
	# Grove 4: Lake Bluff & South Ridge Stand (overlooking Emerald Basin)
	var grove_quotas: Array[Dictionary]
	if is_canonical:
		grove_quotas = [
			{"name": "whispering_forest", "min_x": -9.0, "max_x": 1.5, "min_z": -6.5, "max_z": 2.5, "target": 15},
			{"name": "north_ridge", "min_x": -22.0, "max_x": -10.0, "min_z": -18.0, "max_z": -4.0, "target": 12},
			{"name": "creek_copse", "min_x": -3.0, "max_x": 6.0, "min_z": 6.5, "max_z": 12.5, "target": 8},
			{"name": "lake_bluff", "min_x": 18.0, "max_x": 28.0, "min_z": 17.0, "max_z": 28.0, "target": 10},
		]
		if terrain != null and terrain.island_size > 200.0:
			grove_quotas.append_array([
				{"name": "skyspire_pines", "min_x": -165.0, "max_x": -125.0, "min_z": -165.0, "max_z": -125.0, "target": 14},
				{"name": "highland_plateau", "min_x": 140.0, "max_x": 210.0, "min_z": -60.0, "max_z": 10.0, "target": 16},
				{"name": "cape_solitude_bluffs", "min_x": -10.0, "max_x": 50.0, "min_z": 160.0, "max_z": 220.0, "target": 12},
				{"name": "sunset_promontory", "min_x": -210.0, "max_x": -150.0, "min_z": 20.0, "max_z": 70.0, "target": 8}
			])
	else:
		grove_quotas = [
			{"name": "forest_stand", "min_x": glade_pos.x - 15.0, "max_x": glade_pos.x - 5.0, "min_z": glade_pos.y - 7.0, "max_z": glade_pos.y + 3.0, "target": 15},
			{"name": "alpine_ridge", "min_x": peak_pos.x + 4.0, "max_x": peak_pos.x + 14.0, "min_z": peak_pos.y + 4.0, "max_z": peak_pos.y + 14.0, "target": 12},
			{"name": "valley_copse", "min_x": (peak_pos.x + lake_pos.x) * 0.5 - 5.0, "max_x": (peak_pos.x + lake_pos.x) * 0.5 + 5.0, "min_z": (peak_pos.y + lake_pos.y) * 0.5 - 4.0, "max_z": (peak_pos.y + lake_pos.y) * 0.5 + 4.0, "target": 8},
			{"name": "coastal_bluff", "min_x": bluff_pos.x - 5.0, "max_x": bluff_pos.x + 5.0, "min_z": bluff_pos.y - 5.0, "max_z": bluff_pos.y + 5.0, "target": 10},
		]

	var grove_placed: Array[int] = []
	grove_placed.resize(grove_quotas.size())
	grove_placed.fill(0)

	while placed < target_count and attempts < max_attempts:
		attempts += 1
		var x: float = 0.0
		var z: float = 0.0

		# Pick grove according to target quota
		var grove_idx: int = -1
		for g in range(grove_quotas.size()):
			if grove_placed[g] < grove_quotas[g]["target"]:
				grove_idx = g
				break

		if grove_idx != -1:
			var g_def: Dictionary = grove_quotas[grove_idx]
			x = rng.randf_range(g_def["min_x"], g_def["max_x"])
			z = rng.randf_range(g_def["min_z"], g_def["max_z"])
		else:
			# Outer wilderness
			x = rng.randf_range(-half_size, half_size)
			z = rng.randf_range(-half_size, half_size)

		# SIGHTLINE & COMPOSITION RULE 1: STRICT GLADE CLEARANCE ZONE
		if is_canonical:
			if x >= 5.0 and x <= 16.5 and z >= 0.0 and z <= 9.5:
				continue
		else:
			if Vector2(x - glade_pos.x, z - glade_pos.y).length() < 7.5:
				continue

		# SIGHTLINE & COMPOSITION RULE 2: ANIMAL TRAIL CLEARANCE
		if terrain.get_trail_factor(x, z) > 0.15:
			continue

		# SIGHTLINE & COMPOSITION RULE 3: LAKE WATER CLEARANCE
		var lake_center: Vector2 = Vector2(16.0, 14.0) if is_canonical else lake_pos
		if Vector2(x - lake_center.x, z - lake_center.y).length() < 9.5:
			continue

		# SIGHTLINE & COMPOSITION RULE 4: FIELD CAMP CLEARANCE
		var camp_center: Vector2 = Vector2(-5.5, 0.5) if is_canonical else (glade_pos - Vector2(14.5, 3.0))
		if Vector2(x - camp_center.x, z - camp_center.y).length() < 2.5:
			continue

		var y: float = terrain.get_height_at(x, z)

		# Elevation check: trees prefer 1.8 to 13.0 (up to 38.0 on expanded alpine terrain)
		var max_tree_y: float = 38.0 if (terrain != null and terrain.island_size > 200.0) else 13.0
		if y < 1.8 or y > max_tree_y:
			continue

		# Check local slope
		var delta: float = 1.0
		var slope_x: float = abs(terrain.get_height_at(x + delta, z) - terrain.get_height_at(x - delta, z)) / (2.0 * delta)
		var slope_z: float = abs(terrain.get_height_at(x, z + delta) - terrain.get_height_at(x, z - delta)) / (2.0 * delta)
		if slope_x > 0.85 or slope_z > 0.85:
			continue # Too steep

		# Environmental grid check
		var env_data: Dictionary = {}
		if grid:
			env_data = grid.get_environment_at(x, z)
			var b_type: int = env_data.get("biome", BiomeClassifier.BiomeType.TEMPERATE_MEADOW)
			if b_type != BiomeClassifier.BiomeType.BOREAL_FOREST and b_type != BiomeClassifier.BiomeType.TEMPERATE_MEADOW:
				continue
			if env_data.get("moisture", 0.5) < 0.28:
				continue

		# Multi-species canopy: blend broadleaf deciduous oaks/birches into outer wilderness
		# In Hero region (Whispering Forest & Emerald Basin), maintain 100% authentic Hero Scots Pines (TreePine)
		var is_hero_zone: bool = (x >= -12.0 and x <= 30.0 and z >= -8.0 and z <= 30.0)
		var is_deciduous: bool = not is_hero_zone and ((grove_idx == 0 and grove_placed[0] >= 3 and grove_placed[0] < 8 and rng.randf() < 0.65) or \
								 (grove_idx == 2 and grove_placed[2] >= 2 and rng.randf() < 0.50))
		var dec_key: String = ""
		if is_deciduous:
			for dk in ["tree_oak_fall", "tree_detailed_fall", "tree_default_fall"]:
				if _cached_nature_props.has(dk):
					dec_key = dk
					break
		if dec_key != "":
			var d_node: MeshInstance3D = MeshInstance3D.new()
			d_node.mesh = _cached_nature_props[dec_key]["mesh"]
			d_node.material_override = _cached_nature_props[dec_key]["mat"]
			var d_scale: float = rng.randf_range(1.20, 1.65)
			d_node.scale = Vector3.ONE * d_scale
			d_node.position = Vector3(x, y, z)
			d_node.rotation.y = rng.randf_range(0.0, TAU)
			add_child(d_node)
			placed += 1
			if grove_idx != -1:
				grove_placed[grove_idx] += 1
			if registry:
				registry.spawn_entity("flora_deciduous", d_node.position, {
					"species": "deciduous_oak",
					"scale": d_scale,
					"health": 100.0,
					"biome": env_data.get("biome_name", "Temperate Meadow"),
					"moisture_affinity": env_data.get("moisture", 0.6)
				})
			continue

		var tree: TreePine = TreePine.new()
		# Natural archetype and scale distribution per grove:
		if grove_idx == 0:
			# Whispering Forest: Ancient towering veterans in core, saplings on glade margin
			if grove_placed[0] < 3:
				tree.archetype = TreePine.TreeArchetype.ELDER
				tree.tree_scale = rng.randf_range(1.25, 1.55)
			elif grove_placed[0] >= 11:
				tree.archetype = TreePine.TreeArchetype.SAPLING
				tree.tree_scale = rng.randf_range(0.85, 1.05)
			else:
				tree.archetype = TreePine.TreeArchetype.STANDARD
				tree.tree_scale = rng.randf_range(1.05, 1.35)
		elif grove_idx == 1:
			# North Ridge: Weathered windswept snags and crooked pines framing the alpine monolith
			if grove_placed[1] < 4:
				tree.archetype = TreePine.TreeArchetype.SNAG
				tree.tree_scale = rng.randf_range(0.90, 1.25)
			elif grove_placed[1] < 8:
				tree.archetype = TreePine.TreeArchetype.CROOKED
				tree.tree_scale = rng.randf_range(0.85, 1.20)
			else:
				tree.archetype = TreePine.TreeArchetype.STANDARD
				tree.tree_scale = rng.randf_range(0.95, 1.30)
		elif grove_idx == 2:
			# Creek Copse: Riparian pines and younger growth
			if grove_placed[2] < 3:
				tree.archetype = TreePine.TreeArchetype.SAPLING
				tree.tree_scale = rng.randf_range(0.80, 1.05)
			else:
				tree.archetype = TreePine.TreeArchetype.STANDARD
				tree.tree_scale = rng.randf_range(0.95, 1.35)
		elif grove_idx == 3:
			# Lake Bluff: Windswept crooked pines leaning toward water and standard pines
			if grove_placed[3] < 4:
				tree.archetype = TreePine.TreeArchetype.CROOKED
				tree.tree_scale = rng.randf_range(0.90, 1.30)
			else:
				tree.archetype = TreePine.TreeArchetype.STANDARD
				tree.tree_scale = rng.randf_range(0.95, 1.40)
		else:
			tree.archetype = TreePine.TreeArchetype.STANDARD
			tree.tree_scale = rng.randf_range(0.85, 1.40)

		tree.position = Vector3(x, y, z)
		tree.rotation.y = rng.randf_range(0.0, TAU)
		add_child(tree)
		placed += 1

		if grove_idx != -1:
			grove_placed[grove_idx] += 1

		if registry:
			registry.spawn_entity("flora_pine", tree.position, {
				"species": "conifer",
				"scale": tree.tree_scale,
				"health": 100.0,
				"biome": env_data.get("biome_name", "Temperate Meadow"),
				"moisture_affinity": env_data.get("moisture", 0.6)
			})

func _scatter_canopy_pines_multimesh(terrain: IslandTerrain, rng: RandomNumberGenerator, grid: EnvironmentalGrid = null, target_count: int = 3600) -> void:
	TreePine._init_cache()
	if TreePine._cached_hero_pines.is_empty():
		return

	# High-density grove zones across the 720m world:
	# 1. Whispering Forest stand (core showcase)
	# 2. Pine Highlands plateau (sprawling eastern conifer woods)
	# 3. Cape Solitude coastal slopes & bluffs
	# 4. Skyspire lower flanks and foothills
	# 5. Sunset Promontory and western flanks
	var canopy_zones: Array[Dictionary] = [
		# Zone 1: Whispering Deep Forest Stand (West & Southwest - heavy continuous woods)
		{"min_x": -220.0, "max_x": -15.0, "min_z": -80.0, "max_z": 130.0, "min_y": 2.5, "max_y": 22.0, "weight": 0.28},
		# Zone 2: Whispering Pine Highlands (Northeast Plateau)
		{"min_x": 75.0, "max_x": 260.0, "min_z": -170.0, "max_z": 20.0, "min_y": 5.0, "max_y": 34.0, "weight": 0.22},
		# Zone 3: Skyspire Lower Alpine Slopes (Northwest foothills)
		{"min_x": -240.0, "max_x": -45.0, "min_z": -240.0, "max_z": -45.0, "min_y": 5.0, "max_y": 30.0, "weight": 0.16},
		# Zone 4: Southeast Grand Lake Woodlands (Rolling hills around Grand Lake)
		{"min_x": 25.0, "max_x": 250.0, "min_z": 20.0, "max_z": 250.0, "min_y": 2.5, "max_y": 26.0, "weight": 0.20},
		# Zone 5: Cape Solitude & Southern Coastal Forest (Deep South)
		{"min_x": -140.0, "max_x": 140.0, "min_z": 90.0, "max_z": 290.0, "min_y": 2.2, "max_y": 24.0, "weight": 0.14}
	]

	# High-performance stylized anime pines (nature.glb: 78-230 tris) replacing 11,844 tri models
	var mesh1: Mesh = _cached_nature_props["tree_pineTallA"]["mesh"] if _cached_nature_props.has("tree_pineTallA") else TreePine._cached_hero_pines[0]
	var mat1_0: Material = _cached_nature_props["tree_pineTallA"]["mat"] if _cached_nature_props.has("tree_pineTallA") else TreePine.get_shared_pine_bark_material()
	var mat1_1: Material = null if _cached_nature_props.has("tree_pineTallA") else TreePine.get_shared_pine_needle_material()
	var s1_min: float = 2.4 if _cached_nature_props.has("tree_pineTallA") else 0.35
	var s1_max: float = 3.8 if _cached_nature_props.has("tree_pineTallA") else 0.58

	var mesh2: Mesh = _cached_nature_props["tree_pineDefaultA"]["mesh"] if _cached_nature_props.has("tree_pineDefaultA") else (TreePine._cached_hero_pines[1] if TreePine._cached_hero_pines.size() > 1 else mesh1)
	var mat2_0: Material = _cached_nature_props["tree_pineDefaultA"]["mat"] if _cached_nature_props.has("tree_pineDefaultA") else TreePine.get_shared_pine_bark_material()
	var mat2_1: Material = null if _cached_nature_props.has("tree_pineDefaultA") else TreePine.get_shared_pine_needle_material()
	var s2_min: float = 2.0 if _cached_nature_props.has("tree_pineDefaultA") else 0.30
	var s2_max: float = 3.2 if _cached_nature_props.has("tree_pineDefaultA") else 0.48

	var mesh3: Mesh = _cached_nature_props["tree_pineSmallA"]["mesh"] if _cached_nature_props.has("tree_pineSmallA") else (TreePine._cached_hero_pines[2] if TreePine._cached_hero_pines.size() > 2 else mesh1)
	var mat3_0: Material = _cached_nature_props["tree_pineSmallA"]["mat"] if _cached_nature_props.has("tree_pineSmallA") else TreePine.get_shared_pine_bark_material()
	var mat3_1: Material = null if _cached_nature_props.has("tree_pineSmallA") else TreePine.get_shared_pine_needle_material()
	var s3_min: float = 1.4 if _cached_nature_props.has("tree_pineSmallA") else 0.18
	var s3_max: float = 2.4 if _cached_nature_props.has("tree_pineSmallA") else 0.32

	# Target count scaled for smooth 60 FPS on Iris Xe (max 1100 total canopy pines)
	var clamped_target: int = mini(target_count, 1100)
	var tall_count: int = int(clamped_target * 0.45)
	var dense_count: int = int(clamped_target * 0.35)
	var sapling_count: int = int(clamped_target * 0.20)

	_build_tree_tier_multimesh("PineCanopyMultiMesh", mesh1, mat1_0, mat1_1, tall_count, s1_min, s1_max, 0.95, 1.25, canopy_zones, terrain, rng, false)
	_build_tree_tier_multimesh("PineDenseMultiMesh", mesh2, mat2_0, mat2_1, dense_count, s2_min, s2_max, 0.92, 1.18, canopy_zones, terrain, rng, false)
	_build_tree_tier_multimesh("PineSubcanopyMultiMesh", mesh3, mat3_0, mat3_1, sapling_count, s3_min, s3_max, 0.90, 1.15, canopy_zones, terrain, rng, false)

func _build_tree_tier_multimesh(
	tier_name: String,
	mesh: Mesh,
	mat0: Material,
	mat1: Material,
	count: int,
	s_min: float,
	s_max: float,
	h_min: float,
	h_max: float,
	zones: Array[Dictionary],
	terrain: IslandTerrain,
	rng: RandomNumberGenerator,
	enable_shadows: bool = false
) -> void:
	if mesh == null or count <= 0:
		return

	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = tier_name
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enable_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 240.0
	mmi.visibility_range_end_margin = 30.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count

	var tree_mesh: Mesh = mesh.duplicate()
	if mat0 and tree_mesh.get_surface_count() > 0:
		tree_mesh.surface_set_material(0, mat0)
	if mat1 and tree_mesh.get_surface_count() > 1:
		tree_mesh.surface_set_material(1, mat1)
	mm.mesh = tree_mesh
	mmi.multimesh = mm

	var lake_center: Vector2 = Vector2(16.0, 14.0)
	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = count * 8

	while placed < count and attempts < max_attempts:
		attempts += 1
		# Pick zone based on weight
		var roll: float = rng.randf()
		var chosen_zone: Dictionary = zones[0]
		var accum: float = 0.0
		for z_def in zones:
			accum += z_def["weight"]
			if roll <= accum:
				chosen_zone = z_def
				break

		var x: float = rng.randf_range(chosen_zone["min_x"], chosen_zone["max_x"])
		var z: float = rng.randf_range(chosen_zone["min_z"], chosen_zone["max_z"])

		# SIGHTLINE & OPENING CLEARANCES: Keep immediate player spawn, camp, and lake waters clear
		if Vector2(x - 7.5, z - 3.5).length() < 5.5 or Vector2(x - 7.5, z - 16.5).length() < 5.5: # Immediate spawn clearing
			continue
		if Vector2(x - (-5.5), z - 0.5).length() < 3.2: # Camp
			continue
		if Vector2(x - 13.8, z - 8.8).length() < 3.8: # Canoe mooring
			continue
		if Vector2(x - lake_center.x, z - lake_center.y).length() < 12.0: # Core basin
			continue
		var d_grand_lake_v: float = Vector2(x - 95.0, z - 85.0).length()
		if d_grand_lake_v >= 18.0 and d_grand_lake_v < 125.0: # Grand Emerald Lake water surface clearance (allows flora on Heart Island and outer shore)
			continue
		if Vector2(x - (-15.0), z - (-185.0)).length() < 44.0: # Whispering Mist Lake clearance
			continue
		if terrain.get_trail_factor(x, z) > 0.14: # Animal trail corridor
			continue

		var y: float = terrain.get_height_at(x, z)
		if y < chosen_zone["min_y"] or y > chosen_zone["max_y"]:
			continue

		# Slope check
		var d: float = 1.0
		var sx: float = abs(terrain.get_height_at(x + d, z) - terrain.get_height_at(x - d, z)) / (2.0 * d)
		var sz: float = abs(terrain.get_height_at(x, z + d) - terrain.get_height_at(x, z - d)) / (2.0 * d)
		if sx > 0.90 or sz > 0.90:
			continue

		var t: Transform3D = Transform3D()
		var s: float = rng.randf_range(s_min, s_max)
		var h_mult: float = rng.randf_range(h_min, h_max)
		t = t.scaled(Vector3(s, s * h_mult, s))
		t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		# Subtle wind lean
		t = t.rotated(Vector3.RIGHT, rng.randf_range(-0.04, 0.04))
		t = t.rotated(Vector3.FORWARD, rng.randf_range(-0.04, 0.04))
		t.origin = Vector3(x, y - 0.35, z) # Embed root flare
		mm.set_instance_transform(placed, t)
		placed += 1

	mm.instance_count = placed
	add_child(mmi)

func _scatter_tropical_rainforest_multimesh(terrain: IslandTerrain, rng: RandomNumberGenerator, grid: EnvironmentalGrid = null, density: float = 1.0, is_expanded: bool = false) -> void:
	# Primeval Tropical Rainforest zones:
	# Zone 1: Southern / Southwestern Humid Basin & Riparian Jungle (core showcase pocket)
	# Zone 2: Southeastern Lake Overlook Jungle Margin
	# In expanded mode, append Zone 3 (Deep Southern River Rainforest Basin) and Zone 4 (Western Humid Jungle Valley)
	var trop_zones: Array[Dictionary] = [
		{"min_x": -36.0, "max_x": 8.0, "min_z": 10.0, "max_z": 46.0, "min_y": 1.2, "max_y": 11.5, "weight": 0.65},
		{"min_x": 8.0, "max_x": 32.0, "min_z": 22.0, "max_z": 48.0, "min_y": 1.2, "max_y": 9.5, "weight": 0.35}
	]
	if is_expanded:
		trop_zones = [
			{"min_x": -36.0, "max_x": 8.0, "min_z": 10.0, "max_z": 46.0, "min_y": 1.2, "max_y": 11.5, "weight": 0.20},
			{"min_x": 8.0, "max_x": 32.0, "min_z": 22.0, "max_z": 48.0, "min_y": 1.2, "max_y": 9.5, "weight": 0.15},
			{"min_x": -75.0, "max_x": 55.0, "min_z": 46.0, "max_z": 175.0, "min_y": 1.2, "max_y": 24.0, "weight": 0.40},
			{"min_x": -185.0, "max_x": -70.0, "min_z": 15.0, "max_z": 125.0, "min_y": 2.0, "max_y": 24.0, "weight": 0.25}
		]

	# 1. Broadleaf Rainforest Emergent & Canopy Trees (Game-Ready Multi-branch foliage cards)
	if _cached_bush_meshes.size() > 1 and _cached_bush_stem_mat and _cached_bush_leaf_mat:
		var can_mesh: Mesh = _cached_bush_meshes[1]
		var can_mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		can_mmi.name = "TropicalCanopyMultiMesh"
		can_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		can_mmi.visibility_range_end = 480.0
		can_mmi.visibility_range_end_margin = 40.0

		var canopy_count: int = int((160 if is_expanded else 40) * density)
		var can_mm: MultiMesh = MultiMesh.new()
		can_mm.transform_format = MultiMesh.TRANSFORM_3D
		can_mm.instance_count = canopy_count

		var dup_can_mesh: Mesh = can_mesh.duplicate()
		if dup_can_mesh.get_surface_count() > 0:
			dup_can_mesh.surface_set_material(0, _cached_bush_stem_mat)
		if dup_can_mesh.get_surface_count() > 1:
			dup_can_mesh.surface_set_material(1, _cached_bush_leaf_mat)
		can_mm.mesh = dup_can_mesh
		can_mmi.multimesh = can_mm

		var can_placed: int = 0
		var can_attempts: int = 0
		var can_max: int = canopy_count * 8
		while can_placed < canopy_count and can_attempts < can_max:
			can_attempts += 1
			var roll_c: float = rng.randf()
			var chosen_c: Dictionary = trop_zones[0]
			var acc_c: float = 0.0
			for zd in trop_zones:
				acc_c += zd["weight"]
				if roll_c <= acc_c:
					chosen_c = zd
					break
			var cx: float = rng.randf_range(chosen_c["min_x"], chosen_c["max_x"])
			var cz: float = rng.randf_range(chosen_c["min_z"], chosen_c["max_z"])
			if Vector2(cx - 16.0, cz - 14.0).length() < 9.5 or terrain.get_trail_factor(cx, cz) > 0.15:
				continue
			if cx >= 4.0 and cx <= 16.5 and cz >= -1.0 and cz <= 9.5:
				continue
			var cy: float = terrain.get_height_at(cx, cz)
			if cy < chosen_c["min_y"] or cy > chosen_c["max_y"]:
				continue

			var ct: Transform3D = Transform3D()
			var cs: float = rng.randf_range(3.8, 6.2)
			ct = ct.scaled(Vector3(cs, cs * rng.randf_range(1.0, 1.30), cs))
			ct = ct.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			ct.origin = Vector3(cx, cy - 0.15, cz)
			can_mm.set_instance_transform(can_placed, ct)
			can_placed += 1

		can_mm.instance_count = can_placed
		add_child(can_mmi)

	# 2. Subcanopy Broadleaf Trees with Game-Ready Alpha-Scissor Leaf Cards
	if _cached_bush_meshes.size() > 1 and _cached_bush_stem_mat and _cached_bush_leaf_mat:
		var sub_mesh: Mesh = _cached_bush_meshes[1]
		var sub_mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		sub_mmi.name = "TropicalSubcanopyMultiMesh"
		sub_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sub_mmi.visibility_range_end = 420.0
		sub_mmi.visibility_range_end_margin = 35.0

		var sub_count: int = int((120 if is_expanded else 30) * density)
		var sub_mm: MultiMesh = MultiMesh.new()
		sub_mm.transform_format = MultiMesh.TRANSFORM_3D
		sub_mm.instance_count = sub_count

		var dup_sub_mesh: Mesh = sub_mesh.duplicate()
		if dup_sub_mesh.get_surface_count() > 0:
			dup_sub_mesh.surface_set_material(0, _cached_bush_stem_mat)
		if dup_sub_mesh.get_surface_count() > 1:
			dup_sub_mesh.surface_set_material(1, _cached_bush_leaf_mat)
		sub_mm.mesh = dup_sub_mesh
		sub_mmi.multimesh = sub_mm

		var sub_placed: int = 0
		var sub_attempts: int = 0
		var sub_max: int = sub_count * 9
		while sub_placed < sub_count and sub_attempts < sub_max:
			sub_attempts += 1
			var roll_s: float = rng.randf()
			var chosen_z: Dictionary = trop_zones[0]
			var acc_s: float = 0.0
			for zd in trop_zones:
				acc_s += zd["weight"]
				if roll_s <= acc_s:
					chosen_z = zd
					break
			var sx: float = rng.randf_range(chosen_z["min_x"], chosen_z["max_x"])
			var sz: float = rng.randf_range(chosen_z["min_z"], chosen_z["max_z"])
			if Vector2(sx - 16.0, sz - 14.0).length() < 9.5 or terrain.get_trail_factor(sx, sz) > 0.15:
				continue
			if sx >= 4.0 and sx <= 16.5 and sz >= -1.0 and sz <= 9.5:
				continue
			var sy: float = terrain.get_height_at(sx, sz)
			if sy < chosen_z["min_y"] or sy > chosen_z["max_y"]:
				continue

			var st: Transform3D = Transform3D()
			var ss: float = rng.randf_range(2.4, 4.2)
			st = st.scaled(Vector3(ss, ss * rng.randf_range(0.95, 1.25), ss))
			st = st.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			st.origin = Vector3(sx, sy - 0.12, sz)
			sub_mm.set_instance_transform(sub_placed, st)
			sub_placed += 1

		sub_mm.instance_count = sub_placed
		add_child(sub_mmi)

	# 3. Giant Prehistoric Ferns & Broadleaf Fan Fronds
	var fern_key: String = "plant_flatTall"
	if not _cached_nature_props.has(fern_key):
		for alt_f in ["plant_flatShort", "grass_leafsLarge"]:
			if _cached_nature_props.has(alt_f):
				fern_key = alt_f
				break
	if _cached_nature_props.has(fern_key):
		var fern_info: Dictionary = _cached_nature_props[fern_key]
		var f_mesh: Mesh = fern_info["mesh"]
		var fern_mat: ShaderMaterial = ShaderMaterial.new()
		fern_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
		fern_mat.set_shader_parameter("blade_height", 1.8)
		fern_mat.set_shader_parameter("albedo_top", Color(0.20, 0.48, 0.14, 1.0))
		fern_mat.set_shader_parameter("albedo_bottom", Color(0.06, 0.18, 0.06, 1.0))
		fern_mat.set_shader_parameter("wind_speed", 1.1)
		fern_mat.set_shader_parameter("wind_strength", 0.20)
		fern_mat.set_shader_parameter("backlight_strength", 0.40)
		fern_mat.set_shader_parameter("roughness", 0.76)

		var fern_count: int = int((1200 if is_expanded else 280) * density)
		_build_tropical_prop_multimesh(
			"TropicalFernsMultiMesh",
			f_mesh,
			fern_mat,
			fern_count,
			1.35, 2.75, 0.95, 1.30,
			trop_zones, terrain, rng, false, 280.0, 0.05
		)

	# 3. Dense Tropical Bushes & Leafy Shrubs
	var bush_key: String = "plant_bushDetailed"
	if not _cached_nature_props.has(bush_key):
		for alt_b in ["plant_bushLarge", "plant_bush"]:
			if _cached_nature_props.has(alt_b):
				bush_key = alt_b
				break
	if _cached_nature_props.has(bush_key):
		var b_info: Dictionary = _cached_nature_props[bush_key]
		var b_mesh: Mesh = b_info["mesh"]
		var b_mat = b_info["mat"]
		if b_mat is StandardMaterial3D:
			var nb: StandardMaterial3D = b_mat.duplicate()
			nb.cull_mode = BaseMaterial3D.CULL_DISABLED
			nb.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
			nb.roughness = 0.80
			b_mat = nb

		var bush_count: int = int((750 if is_expanded else 180) * density)
		_build_tropical_prop_multimesh(
			"TropicalUndergrowthMultiMesh",
			b_mesh,
			b_mat,
			bush_count,
			1.10, 1.85, 0.90, 1.20,
			trop_zones, terrain, rng, false, 260.0, 0.08
		)

	# 4. Primeval Rainforest Floor Props (Giant fallen mossy logs, bracket mushrooms, stumps)
	var floor_prop_count: int = 14 if is_expanded else 8
	var floor_placed: int = 0
	var floor_attempts: int = 0
	while floor_placed < floor_prop_count and floor_attempts < floor_prop_count * 8:
		floor_attempts += 1
		var z_def: Dictionary = trop_zones[floor_attempts % trop_zones.size()]
		var px: float = rng.randf_range(z_def["min_x"], z_def["max_x"])
		var pz: float = rng.randf_range(z_def["min_z"], z_def["max_z"])
		if Vector2(px - 16.0, pz - 14.0).length() < 9.5:
			continue
		if px >= 4.0 and px <= 16.5 and pz >= -1.0 and pz <= 9.5:
			continue
		if terrain.get_trail_factor(px, pz) > 0.15:
			continue
		var py: float = terrain.get_height_at(px, pz)
		if py < z_def["min_y"] or py > z_def["max_y"]:
			continue

		var roll: float = rng.randf()
		var p_key: String = ""
		var p_scale: float = 1.0
		var y_off: float = 0.0
		if roll < 0.45 and _cached_nature_props.has("log_large"):
			p_key = "log_large"
			p_scale = rng.randf_range(1.2, 1.8)
			y_off = 0.12
		elif roll < 0.70 and _cached_nature_props.has("mushroom_tanTall"):
			p_key = "mushroom_tanTall"
			p_scale = rng.randf_range(1.4, 2.2)
			y_off = 0.05
		elif _cached_nature_props.has("stump_round"):
			p_key = "stump_round"
			p_scale = rng.randf_range(1.3, 1.9)
			y_off = 0.08

		if p_key != "":
			var node: MeshInstance3D = MeshInstance3D.new()
			node.mesh = _cached_nature_props[p_key]["mesh"]
			node.material_override = _cached_nature_props[p_key]["mat"]
			node.scale = Vector3.ONE * p_scale
			node.position = Vector3(px, py - y_off, pz)
			node.rotation.y = rng.randf_range(0.0, TAU)
			node.visibility_range_end = 45.0
			node.visibility_range_end_margin = 8.0
			add_child(node)
			floor_placed += 1

func _build_tropical_prop_multimesh(
	tier_name: String,
	mesh: Mesh,
	mat: Material,
	count: int,
	s_min: float,
	s_max: float,
	h_min: float,
	h_max: float,
	zones: Array[Dictionary],
	terrain: IslandTerrain,
	rng: RandomNumberGenerator,
	enable_shadows: bool = false,
	vis_range: float = 160.0,
	root_embed: float = 0.15
) -> void:
	if mesh == null or count <= 0:
		return

	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = tier_name
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enable_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = vis_range
	mmi.visibility_range_end_margin = 35.0

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count

	var prop_mesh: Mesh = mesh.duplicate()
	if mat and prop_mesh.get_surface_count() > 0:
		prop_mesh.surface_set_material(0, mat)
	mm.mesh = prop_mesh
	mmi.multimesh = mm

	var lake_center: Vector2 = Vector2(16.0, 14.0)
	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = count * 9

	while placed < count and attempts < max_attempts:
		attempts += 1
		var roll: float = rng.randf()
		var chosen_zone: Dictionary = zones[0]
		var accum: float = 0.0
		for z_def in zones:
			accum += z_def["weight"]
			if roll <= accum:
				chosen_zone = z_def
				break

		var x: float = rng.randf_range(chosen_zone["min_x"], chosen_zone["max_x"])
		var z: float = rng.randf_range(chosen_zone["min_z"], chosen_zone["max_z"])

		# Clearances
		if x >= 4.0 and x <= 16.5 and z >= -1.0 and z <= 9.5: # Glade
			continue
		if Vector2(x - lake_center.x, z - lake_center.y).length() < 9.5: # Lake water
			continue
		if terrain.get_trail_factor(x, z) > 0.15: # Animal trail corridor
			continue
		if Vector2(x - (-5.5), z - 0.5).length() < 3.2: # Camp
			continue
		if Vector2(x - 13.8, z - 8.8).length() < 3.8: # Canoe mooring
			continue
		if Vector2(x - 7.5, z - 3.5).length() < 3.5: # Player spawn
			continue

		var y: float = terrain.get_height_at(x, z)
		if y < chosen_zone["min_y"] or y > chosen_zone["max_y"]:
			continue

		# Slope check
		var d: float = 1.0
		var sx: float = abs(terrain.get_height_at(x + d, z) - terrain.get_height_at(x - d, z)) / (2.0 * d)
		var sz: float = abs(terrain.get_height_at(x, z + d) - terrain.get_height_at(x, z - d)) / (2.0 * d)
		if sx > 0.88 or sz > 0.88:
			continue

		var t: Transform3D = Transform3D()
		var s: float = rng.randf_range(s_min, s_max)
		var h_mult: float = rng.randf_range(h_min, h_max)
		t = t.scaled(Vector3(s, s * h_mult, s))
		t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		# Subtle slope tilt
		t = t.rotated(Vector3.RIGHT, clampf(-sz * 0.20, -0.25, 0.25))
		t = t.rotated(Vector3.FORWARD, clampf(sx * 0.20, -0.25, 0.25))
		t.origin = Vector3(x, y - root_embed, z)
		mm.set_instance_transform(placed, t)
		placed += 1

	mm.instance_count = placed
	add_child(mmi)

func _scatter_wildflowers_multimesh(terrain: IslandTerrain, rng: RandomNumberGenerator, grid: EnvironmentalGrid = null, target_count: int = 1800) -> void:
	var flower_keys: Array[String] = ["flower_purpleA", "flower_yellowA", "flower_redA"]
	var available_keys: Array[String] = []
	for fk in flower_keys:
		if _cached_nature_props.has(fk):
			available_keys.append(fk)

	if available_keys.is_empty():
		return

	var count_per_species: int = int(target_count / available_keys.size())

	for k in available_keys:
		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.name = "Flowers_" + k
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = 45.0
		mmi.visibility_range_end_margin = 8.0

		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = count_per_species
		mm.mesh = _cached_nature_props[k]["mesh"]
		mmi.material_override = _cached_nature_props[k]["mat"]
		mmi.multimesh = mm

		# Species cluster seed locations across meadows, glades, and sunny highland passes
		var cluster_centers: Array[Vector2] = []
		if k == "flower_purpleA":
			cluster_centers = [
				Vector2(6.5, 4.0), Vector2(10.0, 2.0), Vector2(14.0, 7.5),
				Vector2(35.0, 25.0), Vector2(65.0, 45.0), Vector2(95.0, 65.0),
				Vector2(125.0, 85.0), Vector2(145.0, 35.0)
			]
		elif k == "flower_yellowA":
			cluster_centers = [
				Vector2(8.0, 6.0), Vector2(12.5, 3.5), Vector2(18.0, 10.0),
				Vector2(25.0, 18.0), Vector2(50.0, 35.0), Vector2(80.0, 55.0),
				Vector2(110.0, 75.0), Vector2(135.0, 110.0)
			]
		else: # redA
			cluster_centers = [
				Vector2(5.0, 2.0), Vector2(11.0, 5.0), Vector2(15.0, 12.0),
				Vector2(-8.0, 5.0), Vector2(-15.0, 20.0), Vector2(-20.0, -10.0),
				Vector2(45.0, 15.0), Vector2(75.0, 25.0), Vector2(105.0, 45.0)
			]

		var placed: int = 0
		var attempts: int = 0
		var max_attempts: int = count_per_species * 5

		while placed < count_per_species and attempts < max_attempts:
			attempts += 1
			var center: Vector2 = cluster_centers[attempts % cluster_centers.size()]
			var angle: float = rng.randf() * TAU
			var radius: float = rng.randf_range(0.5, 9.5)
			var x: float = center.x + cos(angle) * radius
			var z: float = center.y + sin(angle) * radius

			var y: float = terrain.get_height_at(x, z)
			if y < 0.8 or y > 34.0 or terrain.get_trail_factor(x, z) > 0.25:
				continue
			if Vector2(x - 16.0, z - 14.0).length() < 9.5: # Lake water surface clearance
				continue
			if Vector2(x - 13.8, z - 8.8).length() < 3.5: # Canoe
				continue
			if Vector2(x - 7.5, z - 3.5).length() < 3.5: # Player spawn
				continue
			if Vector2(x - 10.0, z - 1.0).length() < 3.0: # Third-person camera pullback
				continue

			var t: Transform3D = Transform3D()
			var s: float = rng.randf_range(0.90, 1.45)
			t = t.scaled(Vector3.ONE * s)
			t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			t.origin = Vector3(x, y - 0.04, z)
			mm.set_instance_transform(placed, t)
			placed += 1

		mm.instance_count = placed
		add_child(mmi)

func _scatter_rocks(terrain: IslandTerrain, rng: RandomNumberGenerator, grid: EnvironmentalGrid = null) -> void:
	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = rock_count * 8
	var half_size: float = terrain.island_size * 0.44
	var is_canonical: bool = (terrain == null or terrain.island_seed == 1337)

	var bluff_pos: Vector2 = terrain.get_bluff_position() if terrain else Vector2(24.0, 16.0)
	var peak_pos: Vector2 = terrain.get_peak_position() if terrain else Vector2(-24.0, -24.0)
	var lake_pos: Vector2 = terrain.get_lake_position() if terrain else Vector2(16.0, 14.0)
	var glade_pos: Vector2 = terrain.get_glade_position() if terrain else Vector2(9.0, 3.5)

	# Geomorphological rock allocation:
	# 1. Talus Scree Apron under Eastern Granite Bluff: 14 boulders
	# 2. Valley Creek Stepping Stones & Riverbank Boulders: 10 boulders
	# 3. Meadow Focal Crag: 2 prominent boulders
	# 4. Alpine Ridge & Perimeter Crags: remaining 14 boulders
	var talus_target: int = 14
	var creek_target: int = 10
	var glade_target: int = 2

	var talus_placed: int = 0
	var creek_placed: int = 0
	var glade_placed: int = 0

	while placed < rock_count and attempts < max_attempts:
		attempts += 1
		var x: float = 0.0
		var z: float = 0.0
		var y: float = 0.0
		var r_scale: float = 1.0
		var y_embed: float = 0.15 # Depth embedded in earth so it doesn't float

		var rock_arch: RockBoulder.RockArchetype = RockBoulder.RockArchetype.AUTO
		if talus_placed < talus_target:
			# Cluster tightly at foot of Granite Bluff
			if is_canonical:
				x = rng.randf_range(19.5, 26.5)
				z = rng.randf_range(12.5, 21.0)
			else:
				x = rng.randf_range(bluff_pos.x - 3.5, bluff_pos.x + 3.5)
				z = rng.randf_range(bluff_pos.y - 3.5, bluff_pos.y + 3.5)
			y = terrain.get_height_at(x, z)
			if y < 0.4 or y > 8.0:
				continue
			r_scale = rng.randf_range(1.2, 2.2) # Heavy scree rockfall
			y_embed = 0.20
			rock_arch = RockBoulder.RockArchetype.TALUS_SCREE
			talus_placed += 1

		elif creek_placed < creek_target:
			# Valley Creek bed & banks
			var c_t: float = rng.randf_range(0.05, 0.95)
			if is_canonical:
				x = lerpf(-2.0, 12.0, c_t)
				z = lerpf(4.0, 11.0, c_t) + sin(c_t * PI * 2.0) * 2.2 + rng.randf_range(-1.2, 1.2)
			else:
				var runoff_start: Vector2 = peak_pos * 0.45
				x = lerpf(runoff_start.x, lake_pos.x, c_t) + rng.randf_range(-1.2, 1.2)
				z = lerpf(runoff_start.y, lake_pos.y, c_t) + sin(c_t * PI * 2.0) * 2.0 + rng.randf_range(-1.2, 1.2)
			y = terrain.get_height_at(x, z)
			if y < 0.1:
				continue
			r_scale = rng.randf_range(0.65, 1.35) # Water-smoothed river stones
			y_embed = 0.14
			rock_arch = RockBoulder.RockArchetype.RIVER_STONE
			creek_placed += 1

		elif glade_placed < glade_target:
			# Anchor rock at the border of Sunlit Meadow
			var g_anchor: Vector2 = Vector2(14.5, 1.5) if is_canonical else (glade_pos + Vector2(5.5, -2.0))
			x = g_anchor.x + rng.randf_range(-0.8, 0.8)
			z = g_anchor.y + rng.randf_range(-0.8, 0.8)
			y = terrain.get_height_at(x, z)
			r_scale = rng.randf_range(1.7, 2.3) # Prominent meadow crag
			y_embed = 0.22
			rock_arch = RockBoulder.RockArchetype.PROMINENT_CRAG
			glade_placed += 1

		else:
			# Mountain ridges, bluffs, and perimeter
			x = rng.randf_range(-half_size, half_size)
			z = rng.randf_range(-half_size, half_size)
			if Vector2(x - 7.5, z - 3.5).length() < 4.5: # Player spawn
				continue
			if Vector2(x - 9.0, z - 5.2).length() < 3.5: # Third-person camera pullback
				continue
			y = terrain.get_height_at(x, z)
			if y < 0.2:
				continue
			if y > 5.0:
				r_scale = rng.randf_range(1.2, 2.4)
				rock_arch = RockBoulder.RockArchetype.TALUS_SCREE
			else:
				r_scale = rng.randf_range(0.7, 1.6)
				rock_arch = RockBoulder.RockArchetype.RIVER_STONE
			y_embed = 0.15

		var rock: RockBoulder = RockBoulder.new()
		rock.rock_scale = r_scale
		rock.archetype = rock_arch
		# Embed slightly into terrain to eliminate floating contact gap
		rock.position = Vector3(x, y - y_embed, z)
		rock.rotation.y = rng.randf_range(0.0, TAU)
		rock.rotation.x = rng.randf_range(-0.15, 0.15)
		rock.rotation.z = rng.randf_range(-0.15, 0.15)
		add_child(rock)
		placed += 1

func _scatter_understory(terrain: IslandTerrain, rng: RandomNumberGenerator, grid: EnvironmentalGrid = null, target_count: int = 65) -> void:
	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = target_count * 8
	var half_size: float = terrain.island_size * 0.42
	var is_expanded: bool = (terrain != null and terrain.island_size > 200.0)

	var flower_keys: Array = ["flower_purpleA", "flower_purpleC", "flower_yellowA", "flower_yellowC", "flower_redA"]

	while placed < target_count and attempts < max_attempts:
		attempts += 1
		var x: float
		var z: float
		var sub_zone: int = -1

		if is_expanded:
			var zone_roll: float = rng.randf()
			if zone_roll < 0.22:
				sub_zone = 0 # Emerald Basin shoreline & water
				x = rng.randf_range(12.0, 26.0)
				z = rng.randf_range(10.0, 22.0)
			elif zone_roll < 0.44:
				sub_zone = 1 # Whispering Forest floor
				x = rng.randf_range(-8.5, 1.5)
				z = rng.randf_range(-6.5, 2.5)
			elif zone_roll < 0.60:
				sub_zone = 2 # Sunlit Meadow Glade
				x = rng.randf_range(4.0, 16.0)
				z = rng.randf_range(1.0, 9.5)
			elif zone_roll < 0.72:
				sub_zone = 3 # Creek banks & trail borders
				x = rng.randf_range(-2.0, 12.0)
				z = rng.randf_range(3.0, 10.0)
			elif zone_roll < 0.82:
				sub_zone = 5 # Whispering Pine Highlands understory
				x = rng.randf_range(140.0, 205.0)
				z = rng.randf_range(-55.0, 8.0)
			elif zone_roll < 0.92:
				sub_zone = 6 # Cape Solitude Bluffs undergrowth
				x = rng.randf_range(-8.0, 48.0)
				z = rng.randf_range(162.0, 218.0)
			else:
				sub_zone = -1 # General wilderness
				x = rng.randf_range(-half_size, half_size)
				z = rng.randf_range(-half_size, half_size)
		else:
			# 65% of understory clustered intentionally in the Showcase Region
			var in_showcase: bool = rng.randf() < 0.65
			sub_zone = rng.randi() % 5 if in_showcase else -1
			match sub_zone:
				0: # Sub-zone 3: Emerald Basin water lilies & reeds
					x = rng.randf_range(14.0, 22.0)
					z = rng.randf_range(11.0, 18.0)
				1: # Sub-zone 1: Whispering Forest floor (mossy logs, mushrooms)
					x = rng.randf_range(-7.0, 0.0)
					z = rng.randf_range(-5.0, 2.0)
				2: # Sub-zone 2: Sunlit Meadow Glade (wildflower carpet)
					x = rng.randf_range(4.0, 15.0)
					z = rng.randf_range(1.0, 9.0)
				3: # Creek banks & trail borders (pebbles, shrubs)
					x = rng.randf_range(-2.0, 12.0)
					z = rng.randf_range(3.0, 10.0)
				4: # Granite Bluff transition bushes
					x = rng.randf_range(18.0, 26.0)
					z = rng.randf_range(12.0, 20.0)
				_: # Island background
					x = rng.randf_range(-half_size, half_size)
					z = rng.randf_range(-half_size, half_size)

		var y: float = terrain.get_height_at(x, z)
		var is_water_cove: bool = Vector2(x - 16.0, z - 14.0).length() < 13.0
		if y < 0.05 and not is_water_cove:
			continue
		var max_understory_y: float = 36.0 if is_expanded else 11.5
		if y > max_understory_y:
			continue

		# Prevent understory from clogging the animal trail
		if terrain.get_trail_factor(x, z) > 0.45:
			continue

		# Prevent understory props from obstructing the player spawn and initial camera orbit
		if Vector2(x - 7.5, z - 3.5).length() < 7.5:
			continue
		if Vector2(x - 10.2, z - 0.8).length() < 5.5:
			continue

		# Prevent understory props from spawning inside or through the canoe
		if Vector2(x - 13.8, z - 8.8).length() < 3.8:
			continue

		# Prevent understory bush cards from clipping into forest trail camera
		if Vector2(x - (-1.8), z - 0.4).length() < 2.5:
			continue

		var env_data: Dictionary = grid.get_environment_at(x, z) if grid else {}
		var moisture: float = env_data.get("moisture", 0.5)

		var prop_inst: MeshInstance3D = null

		if sub_zone == 0 or (is_water_cove and y < 0.6):
			var roll: float = rng.randf()
			if roll < 0.45 and (_cached_nature_props.has("lily_large") or _cached_nature_props.has("lily_small")):
				# Floating lilies on water plane
				var lk: String = "lily_large" if rng.randf() < 0.65 else "lily_small"
				if not _cached_nature_props.has(lk):
					lk = "lily_large" if _cached_nature_props.has("lily_large") else "lily_small"
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props[lk]["mesh"]
				prop_inst.material_override = _cached_nature_props[lk]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(1.1, 1.9)
				y = 0.03 # Rest directly on water surface
			elif _cached_nature_props.has("plant_flatTall") or _cached_nature_props.has("plant_flatShort"):
				# Shoreline reeds
				var rk: String = "plant_flatTall" if rng.randf() < 0.6 else "plant_flatShort"
				if not _cached_nature_props.has(rk):
					rk = "plant_flatTall"
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props[rk]["mesh"]
				prop_inst.material_override = _cached_nature_props[rk]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(1.1, 1.8)

		elif sub_zone == 1 or sub_zone == 5:
			# Shaded Forest floor: fallen logs, round stumps, mushrooms, and hero lilac undergrowth
			var f_roll: float = rng.randf()
			if f_roll < 0.28 and (_cached_nature_props.has("log_large") or _cached_nature_props.has("log")):
				var lk: String = "log_large" if rng.randf() < 0.6 else "log"
				if not _cached_nature_props.has(lk):
					lk = "log_large"
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props[lk]["mesh"]
				prop_inst.material_override = _cached_nature_props[lk]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.9, 1.3)
				y -= 0.10 # Embed log slightly into leaf litter
			elif f_roll < 0.44 and _cached_nature_props.has("stump_round"):
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props["stump_round"]["mesh"]
				prop_inst.material_override = _cached_nature_props["stump_round"]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(1.1, 1.6)
				y -= 0.06
			elif f_roll < 0.58 and (_cached_nature_props.has("mushroom_tanGroup") or _cached_nature_props.has("mushroom_redGroup")):
				var mk: String = "mushroom_tanGroup" if rng.randf() < 0.65 else "mushroom_redGroup"
				if not _cached_nature_props.has(mk):
					mk = "mushroom_tanGroup" if _cached_nature_props.has("mushroom_tanGroup") else "mushroom_redGroup"
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props[mk]["mesh"]
				prop_inst.material_override = _cached_nature_props[mk]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(1.2, 1.8)
				y -= 0.04
			elif not _cached_bush_meshes.is_empty():
				var b_mesh: Mesh = _cached_bush_meshes[rng.randi() % _cached_bush_meshes.size()]
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = b_mesh
				if b_mesh.get_surface_count() > 1:
					prop_inst.set_surface_override_material(0, _cached_bush_stem_mat)
					prop_inst.set_surface_override_material(1, _cached_bush_leaf_mat)
				elif _cached_bush_mat:
					prop_inst.material_override = _cached_bush_mat
				# Realistic botanical shrub scale (0.24 - 0.36 -> ~0.85m to 1.25m height)
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.24, 0.36)
			elif _cached_nature_props.has("rock_smallC"):
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props["rock_smallC"]["mesh"]
				prop_inst.material_override = _cached_nature_props["rock_smallC"]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.8, 1.4)
				y -= 0.05

		elif sub_zone == 2:
			# Sunlit Meadow Glade: natural low shrubs, smooth river stones, and weathered timber
			var m_roll: float = rng.randf()
			if m_roll < 0.22 and not _cached_bush_meshes.is_empty():
				var b_mesh: Mesh = _cached_bush_meshes[rng.randi() % _cached_bush_meshes.size()]
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = b_mesh
				if b_mesh.get_surface_count() > 1:
					prop_inst.set_surface_override_material(0, _cached_bush_stem_mat)
					prop_inst.set_surface_override_material(1, _cached_bush_leaf_mat)
				elif _cached_bush_mat:
					prop_inst.material_override = _cached_bush_mat
				# Natural low shrub scale (0.22 - 0.32 -> ~0.75m to 1.1m height)
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.22, 0.32)
			elif m_roll < 0.65 and _cached_nature_props.has("rock_smallC"):
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props["rock_smallC"]["mesh"]
				prop_inst.material_override = _cached_nature_props["rock_smallC"]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.8, 1.3)
				y -= 0.05
			elif _cached_nature_props.has("log"):
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props["log"]["mesh"]
				prop_inst.material_override = _cached_nature_props["log"]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.8, 1.1)
				y -= 0.08

		elif sub_zone == 3:
			# Creek banks: river pebbles or detailed bushes
			if _cached_nature_props.has("rock_smallC") and rng.randf() < 0.50:
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props["rock_smallC"]["mesh"]
				prop_inst.material_override = _cached_nature_props["rock_smallC"]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.8, 1.5)
				y -= 0.05
			elif _cached_nature_props.has("plant_bushDetailed"):
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props["plant_bushDetailed"]["mesh"]
				prop_inst.material_override = _cached_nature_props["plant_bushDetailed"]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.85, 1.4)

		elif sub_zone == 6:
			# Cape Solitude Bluffs: wind-swept shrubs and weathered rocks
			if _cached_nature_props.has("plant_bushDetailed") and rng.randf() < 0.50:
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props["plant_bushDetailed"]["mesh"]
				prop_inst.material_override = _cached_nature_props["plant_bushDetailed"]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.7, 1.2)
			elif _cached_nature_props.has("rock_smallC"):
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props["rock_smallC"]["mesh"]
				prop_inst.material_override = _cached_nature_props["rock_smallC"]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.9, 1.6)
				y -= 0.06

		else:
			# General bushes & undergrowth
			if _cached_nature_props.has("plant_bushDetailed") and rng.randf() < 0.40:
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props["plant_bushDetailed"]["mesh"]
				prop_inst.material_override = _cached_nature_props["plant_bushDetailed"]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.85, 1.4)
			elif not _cached_bush_meshes.is_empty():
				var b_mesh: Mesh = _cached_bush_meshes[rng.randi() % _cached_bush_meshes.size()]
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = b_mesh
				if b_mesh.get_surface_count() > 1:
					prop_inst.set_surface_override_material(0, _cached_bush_stem_mat)
					prop_inst.set_surface_override_material(1, _cached_bush_leaf_mat)
				elif _cached_bush_mat:
					prop_inst.material_override = _cached_bush_mat
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.7, 1.3)

		if prop_inst:
			prop_inst.position = Vector3(x, y, z)
			prop_inst.rotation.y = rng.randf_range(0.0, TAU)
			prop_inst.visibility_range_end = 52.0
			prop_inst.visibility_range_end_margin = 8.0
			if _cached_nature_props.has("log_large") and prop_inst.mesh == _cached_nature_props["log_large"]["mesh"]:
				prop_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			else:
				prop_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(prop_inst)
			placed += 1

func _scatter_grass_multimesh(terrain: IslandTerrain, rng: RandomNumberGenerator, grid: EnvironmentalGrid = null, target_count: int = 20000) -> void:
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = "GrassMultiMesh"
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 55.0
	mmi.visibility_range_end_margin = 8.0

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = target_count

	# Prioritize lightweight stylized grass tufts (Kenney grass_leafs 36 tris for high FPS)
	var grass_mesh: Mesh = null
	if _cached_nature_props.has("grass_leafs"):
		grass_mesh = _cached_nature_props["grass_leafs"]["mesh"]
	elif _cached_nature_props.has("grass_leafsLarge"):
		grass_mesh = _cached_nature_props["grass_leafsLarge"]["mesh"]
	elif _cached_grass_mesh != null:
		grass_mesh = _cached_grass_mesh
	else:
		var p_mesh: PrismMesh = PrismMesh.new()
		p_mesh.size = Vector3(0.5, 0.7, 0.05)
		grass_mesh = p_mesh

	var grass_mat: ShaderMaterial = ShaderMaterial.new()
	grass_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
	grass_mat.set_shader_parameter("blade_height", 0.15)
	grass_mat.set_shader_parameter("max_draw_distance", 55.0)
	# Vibrant natural temperate meadow: rich chlorophyll green tips, dark humus root for seamless ground contact
	grass_mat.set_shader_parameter("albedo_top", Color(0.28, 0.46, 0.16, 1.0))
	grass_mat.set_shader_parameter("albedo_bottom", Color(0.10, 0.16, 0.07, 1.0))
	grass_mat.set_shader_parameter("use_texture", false)
	grass_mat.set_shader_parameter("use_vertex_color", false)
	grass_mat.set_shader_parameter("wind_speed", 1.25)
	grass_mat.set_shader_parameter("wind_strength", 0.18)
	grass_mat.set_shader_parameter("wetness", 0.0)
	grass_mat.set_shader_parameter("backlight_strength", 0.42)
	grass_mat.set_shader_parameter("roughness", 0.78)

	register_foliage_material(grass_mat)
	mmi.material_override = grass_mat
	mm.mesh = grass_mesh
	mmi.multimesh = mm

	var half_size: float = terrain.island_size * 0.42
	var is_expanded: bool = (terrain != null and terrain.island_size > 200.0)

	var is_canonical: bool = (terrain == null or terrain.island_seed == 1337)
	var glade_pos: Vector2 = terrain.get_glade_position() if terrain else Vector2(9.0, 3.5)
	var lake_pos: Vector2 = terrain.get_lake_position() if terrain else Vector2(16.0, 14.0)
	var bluff_pos: Vector2 = terrain.get_bluff_position() if terrain else Vector2(24.0, 16.0)

	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = target_count * 5

	while placed < target_count and attempts < max_attempts:
		attempts += 1
		var x: float
		var z: float
		if is_expanded:
			var region_roll: float = rng.randf()
			if region_roll < 0.65:
				# Central Sunlit Meadow & Expansive Plains (from Glade across Lake to Southeast)
				x = rng.randf_range(-6.0, 160.0)
				z = rng.randf_range(-8.0, 150.0)
			elif region_roll < 0.85:
				# Whispering Deep Forest understory carpet
				x = rng.randf_range(-175.0, -10.0)
				z = rng.randf_range(-55.0, 85.0)
			else:
				# Pine Highlands & Coastal margins
				x = rng.randf_range(-half_size, half_size)
				z = rng.randf_range(-half_size, half_size)
		else:
			if rng.randf() < 0.70:
				if is_canonical:
					x = rng.randf_range(-8.0, 26.0)
					z = rng.randf_range(-5.0, 22.0)
				else:
					var min_x_s: float = minf(glade_pos.x - 10.0, lake_pos.x - 6.0)
					var max_x_s: float = maxf(glade_pos.x + 10.0, bluff_pos.x + 6.0)
					var min_z_s: float = minf(glade_pos.y - 10.0, lake_pos.y - 6.0)
					var max_z_s: float = maxf(glade_pos.y + 10.0, bluff_pos.y + 6.0)
					x = rng.randf_range(min_x_s, max_x_s)
					z = rng.randf_range(min_z_s, max_z_s)
			else:
				x = rng.randf_range(-half_size, half_size)
				z = rng.randf_range(-half_size, half_size)

		var y: float = terrain.get_height_at(x, z)
		var max_grass_y: float = 38.0 if is_expanded else 11.2
		if y < 0.45 or y > max_grass_y:
			continue

		if grid:
			var env: Dictionary = grid.get_environment_at(x, z)
			if env.get("moisture", 0.5) < 0.15:
				continue

		# Animal Trail suppression
		if terrain.get_trail_factor(x, z) > 0.38:
			continue

		# Clearances: camp, lake water center, canoe, and player spawn
		if Vector2(x - (-5.5), z - 0.5).length() < 2.8: # Camp
			continue
		if Vector2(x - 16.0, z - 14.0).length() < 9.0: # Lake center
			continue
		if Vector2(x - 13.8, z - 8.8).length() < 3.2: # Canoe
			continue
		if Vector2(x - 7.5, z - 3.5).length() < 3.5: # Player spawn
			continue
		if Vector2(x - 9.0, z - 5.0).length() < 2.5: # Player spawn third-person camera pullback
			continue

		# Calculate local slope to conform grass transform to terrain normal
		var d: float = 0.5
		var sx: float = (terrain.get_height_at(x + d, z) - terrain.get_height_at(x - d, z)) / (2.0 * d)
		var sz: float = (terrain.get_height_at(x, z + d) - terrain.get_height_at(x, z - d)) / (2.0 * d)
		if absf(sx) > 1.2 or absf(sz) > 1.2:
			continue

		var t: Transform3D = Transform3D()
		# Natural botanical grass scale for grass_leafs (0.15m - 0.22m height)
		var s: float = rng.randf_range(0.85, 1.25)
		if x >= 3.0 and x <= 18.0 and z >= -2.0 and z <= 12.0:
			s = rng.randf_range(1.0, 1.40) # Gentle meadow glade
		t = t.scaled(Vector3(s, s * rng.randf_range(0.92, 1.15), s))
		t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		# Natural terrain slope tilt
		t = t.rotated(Vector3.RIGHT, clampf(-sz * 0.35, -0.4, 0.4))
		t = t.rotated(Vector3.FORWARD, clampf(sx * 0.35, -0.4, 0.4))
		t.origin = Vector3(x, y, z)
		mm.set_instance_transform(placed, t)
		placed += 1

	mm.instance_count = placed
	add_child(mmi)
	_grass_multimesh = mmi

	# 2. Add botanical tall flowering grass MultiMesh for vertical meadow depth
	if is_expanded and _cached_nature_props.has("grass_large"):
		var tall_mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		tall_mmi.name = "TallGrassMultiMesh"
		tall_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tall_mmi.visibility_range_end = 45.0
		tall_mmi.visibility_range_end_margin = 8.0

		var tall_count: int = 400
		var tall_mm: MultiMesh = MultiMesh.new()
		tall_mm.transform_format = MultiMesh.TRANSFORM_3D
		if _cached_nature_props.has("grass_large"):
			tall_mm.mesh = _cached_nature_props["grass_large"]["mesh"]
		else:
			tall_mm.mesh = grass_mesh
		tall_mm.instance_count = tall_count
		var tall_grass_mat: ShaderMaterial = grass_mat.duplicate()
		tall_grass_mat.set_shader_parameter("blade_height", 0.45)
		tall_grass_mat.set_shader_parameter("max_draw_distance", 45.0)
		tall_grass_mat.set_shader_parameter("albedo_top", Color(0.32, 0.52, 0.18, 1.0))
		tall_grass_mat.set_shader_parameter("albedo_bottom", Color(0.12, 0.18, 0.08, 1.0))
		register_foliage_material(tall_grass_mat)
		tall_mmi.material_override = tall_grass_mat
		tall_mmi.multimesh = tall_mm

		var tall_placed: int = 0
		var tall_attempts: int = 0
		var tall_max: int = tall_count * 5

		while tall_placed < tall_count and tall_attempts < tall_max:
			tall_attempts += 1
			var tx: float
			var tz: float
			var r_zone: float = rng.randf()
			if r_zone < 0.50:
				tx = rng.randf_range(-12.0, 30.0)
				tz = rng.randf_range(-8.0, 24.0)
			elif r_zone < 0.75:
				tx = rng.randf_range(110.0, 210.0)
				tz = rng.randf_range(-60.0, 15.0)
			else:
				tx = rng.randf_range(-20.0, 60.0)
				tz = rng.randf_range(145.0, 225.0)

			var ty: float = terrain.get_height_at(tx, tz)
			if ty < 0.6 or ty > 36.0:
				continue
			if terrain.get_trail_factor(tx, tz) > 0.30:
				continue
			if Vector2(tx - 16.0, tz - 14.0).length() < 9.0:
				continue
			if Vector2(tx - 13.8, tz - 8.8).length() < 3.5:
				continue
			if Vector2(tx - 6.5, tz - 4.0).length() < 3.2: # Third-person camera clearance
				continue

			var tt: Transform3D = Transform3D()
			var ts: float = rng.randf_range(0.36, 0.54)
			tt = tt.scaled(Vector3(ts, ts * rng.randf_range(0.95, 1.20), ts))
			tt = tt.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			tt.origin = Vector3(tx, ty, tz)
			tall_mm.set_instance_transform(tall_placed, tt)
			tall_placed += 1

		tall_mm.instance_count = tall_placed
		add_child(tall_mmi)
