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

	# Load Forest Pack (KayKit CC0) for grass
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
		_cached_bush_leaf_mat.set_shader_parameter("backlight_strength", 0.15)
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
				"rock_smallC", "rock_largeA", "rock_tallA", "rock_tallC"
			]
			for pk in prop_keys:
				var mi: MeshInstance3D = n_root.find_child(pk, true, false) as MeshInstance3D
				if mi and mi.mesh:
					var p_mat = mi.mesh.surface_get_material(0) if mi.mesh.get_surface_count() > 0 else null
					if p_mat is StandardMaterial3D:
						var custom_mat: StandardMaterial3D = p_mat.duplicate()
						custom_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
						custom_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
						p_mat = custom_mat
					_cached_nature_props[pk] = {
						"mesh": mi.mesh,
						"mat": p_mat
					}
			n_root.free()

func scatter(terrain: IslandTerrain, seed_val: int = 1337, registry: EntityRegistry = null, grid: EnvironmentalGrid = null, config: WorldGenerationConfig = null) -> void:
	# Clear existing children if regenerating
	for child in get_children():
		child.queue_free()

	_init_asset_cache()

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val

	var density: float = config.vegetation_density if config != null else 1.0
	var final_trees: int = int(tree_count * density)
	var final_grass: int = int(grass_count * density)
	var final_understory: int = int(understory_count * density)

	_scatter_landmark(terrain, registry, grid)
	_scatter_trees(terrain, rng, registry, grid, final_trees)
	_scatter_rocks(terrain, rng, grid)
	_scatter_understory(terrain, rng, grid, final_understory)
	_scatter_grass_multimesh(terrain, rng, grid, final_grass)

func _scatter_landmark(terrain: IslandTerrain, registry: EntityRegistry = null, grid: EnvironmentalGrid = null) -> void:
	var peak_x: float = -24.0
	var peak_z: float = -24.0
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

	# Subdivided into organic groves across the showcase region:
	# Grove 1: Whispering Forest Stand (dense pines/oaks framing trail entrance)
	# Grove 2: North Ridge Conifers (framing Summit Monolith backdrop)
	# Grove 3: Creek & Valley Copse (shading the winding creek)
	# Grove 4: Lake Bluff & South Ridge Stand (overlooking Emerald Basin)
	var grove_quotas: Array[Dictionary] = [
		{"name": "whispering_forest", "min_x": -9.0, "max_x": 1.5, "min_z": -6.5, "max_z": 2.5, "target": 15},
		{"name": "north_ridge", "min_x": -22.0, "max_x": -10.0, "min_z": -18.0, "max_z": -4.0, "target": 12},
		{"name": "creek_copse", "min_x": -3.0, "max_x": 6.0, "min_z": 6.5, "max_z": 12.5, "target": 8},
		{"name": "lake_bluff", "min_x": 18.0, "max_x": 28.0, "min_z": 17.0, "max_z": 28.0, "target": 10},
	]

	var grove_placed: Array[int] = [0, 0, 0, 0]

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
		# Sunlit Meadow Glade (X: 5.0 to 16.5, Z: 0.0 to 9.5) must stay open for grazing stags & sightlines
		if x >= 5.0 and x <= 16.5 and z >= 0.0 and z <= 9.5:
			continue

		# SIGHTLINE & COMPOSITION RULE 2: ANIMAL TRAIL CLEARANCE
		if terrain.get_trail_factor(x, z) > 0.15:
			continue

		# SIGHTLINE & COMPOSITION RULE 3: LAKE WATER CLEARANCE
		if Vector2(x - 16.0, z - 14.0).length() < 9.5:
			continue

		var y: float = terrain.get_height_at(x, z)

		# Elevation check: trees prefer 1.8 to 13.0
		if y < 1.8 or y > 13.0:
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

func _scatter_rocks(terrain: IslandTerrain, rng: RandomNumberGenerator, grid: EnvironmentalGrid = null) -> void:
	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = rock_count * 8
	var half_size: float = terrain.island_size * 0.44

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
			# Cluster tightly at foot of Eastern Granite Bluff (X: 19.5 to 26.5, Z: 12.5 to 21.0)
			x = rng.randf_range(19.5, 26.5)
			z = rng.randf_range(12.5, 21.0)
			y = terrain.get_height_at(x, z)
			if y < 0.4 or y > 8.0:
				continue
			r_scale = rng.randf_range(1.2, 2.2) # Heavy scree rockfall
			y_embed = 0.20
			rock_arch = RockBoulder.RockArchetype.TALUS_SCREE
			talus_placed += 1

		elif creek_placed < creek_target:
			# Valley Creek bed & banks (-2.0 to 12.0)
			var c_t: float = rng.randf_range(0.05, 0.95)
			var c_x: float = lerpf(-2.0, 12.0, c_t)
			var c_z: float = lerpf(4.0, 11.0, c_t) + sin(c_t * PI * 2.0) * 2.2 + rng.randf_range(-1.2, 1.2)
			x = c_x
			z = c_z
			y = terrain.get_height_at(x, z)
			if y < 0.1:
				continue
			r_scale = rng.randf_range(0.65, 1.35) # Water-smoothed river stones
			y_embed = 0.14
			rock_arch = RockBoulder.RockArchetype.RIVER_STONE
			creek_placed += 1

		elif glade_placed < glade_target:
			# Anchor rock at the border of Sunlit Meadow
			x = 14.5 + rng.randf_range(-0.8, 0.8)
			z = 1.5 + rng.randf_range(-0.8, 0.8)
			y = terrain.get_height_at(x, z)
			r_scale = rng.randf_range(1.7, 2.3) # Prominent meadow crag
			y_embed = 0.22
			rock_arch = RockBoulder.RockArchetype.PROMINENT_CRAG
			glade_placed += 1

		else:
			# Mountain ridges, bluffs, and perimeter
			x = rng.randf_range(-half_size, half_size)
			z = rng.randf_range(-half_size, half_size)
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

	var flower_keys: Array = ["flower_purpleA", "flower_purpleC", "flower_yellowA", "flower_yellowC", "flower_redA"]

	while placed < target_count and attempts < max_attempts:
		attempts += 1
		# 65% of understory clustered intentionally in the Showcase Region
		var in_showcase: bool = rng.randf() < 0.65
		var x: float
		var z: float

		# Priority sub-zones
		var sub_zone: int = rng.randi() % 5 if in_showcase else -1
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
		if y > 11.5:
			continue

		# Prevent understory from clogging the animal trail
		if terrain.get_trail_factor(x, z) > 0.45:
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

		elif sub_zone == 1:
			# Shaded Whispering Forest floor: fallen logs, round stumps, mushrooms, lilac undergrowth
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
			elif f_roll < 0.45 and _cached_nature_props.has("stump_round"):
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props["stump_round"]["mesh"]
				prop_inst.material_override = _cached_nature_props["stump_round"]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(1.1, 1.6)
				y -= 0.06
			elif f_roll < 0.70 and (_cached_nature_props.has("mushroom_redGroup") or _cached_nature_props.has("mushroom_tanGroup")):
				var mk: String = "mushroom_redGroup" if rng.randf() < 0.5 else "mushroom_tanGroup"
				if not _cached_nature_props.has(mk):
					mk = "mushroom_redGroup"
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props[mk]["mesh"]
				prop_inst.material_override = _cached_nature_props[mk]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.9, 1.5)
			elif not _cached_bush_meshes.is_empty():
				var b_mesh: Mesh = _cached_bush_meshes[rng.randi() % _cached_bush_meshes.size()]
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = b_mesh
				if b_mesh.get_surface_count() > 1:
					prop_inst.set_surface_override_material(0, _cached_bush_stem_mat)
					prop_inst.set_surface_override_material(1, _cached_bush_leaf_mat)
				elif _cached_bush_mat:
					prop_inst.material_override = _cached_bush_mat
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.8, 1.3)

		elif sub_zone == 2:
			# Sunlit Meadow Glade: rich wildflowers (purple bellflowers, red poppies, yellow daisies)
			var fk: String = flower_keys[rng.randi() % flower_keys.size()]
			if _cached_nature_props.has(fk):
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props[fk]["mesh"]
				prop_inst.material_override = _cached_nature_props[fk]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(1.1, 1.8)

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
			if _cached_nature_props.has("log_large") and prop_inst.mesh == _cached_nature_props["log_large"]["mesh"]:
				prop_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			else:
				prop_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(prop_inst)
			placed += 1

func _scatter_grass_multimesh(terrain: IslandTerrain, rng: RandomNumberGenerator, grid: EnvironmentalGrid = null, target_count: int = 1500) -> void:
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = "GrassMultiMesh"
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = target_count

	# Prioritize authentic multi-stem botanical grass clump (KayKit Grass_2_D_Color1 or Kenney grass_large)
	var grass_mesh: Mesh = null
	if _cached_grass_mesh != null:
		grass_mesh = _cached_grass_mesh
	elif _cached_nature_props.has("grass_large"):
		grass_mesh = _cached_nature_props["grass_large"]["mesh"]
	elif _cached_nature_props.has("grass_leafsLarge"):
		grass_mesh = _cached_nature_props["grass_leafsLarge"]["mesh"]
	else:
		var p_mesh: PrismMesh = PrismMesh.new()
		p_mesh.size = Vector3(0.5, 0.7, 0.05)
		grass_mesh = p_mesh

	var grass_mat: ShaderMaterial = ShaderMaterial.new()
	grass_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
	grass_mat.set_shader_parameter("blade_height", 0.85)
	# Natural temperate meadow: warm olive-sage at tips, dark humus at root
	grass_mat.set_shader_parameter("albedo_top", Color(0.22, 0.36, 0.14, 1.0))
	grass_mat.set_shader_parameter("albedo_bottom", Color(0.09, 0.16, 0.06, 1.0))
	grass_mat.set_shader_parameter("use_texture", false)
	grass_mat.set_shader_parameter("use_vertex_color", false)
	grass_mat.set_shader_parameter("wind_speed", 1.3)
	grass_mat.set_shader_parameter("wind_strength", 0.16)
	grass_mat.set_shader_parameter("wetness", 0.0)
	grass_mat.set_shader_parameter("backlight_strength", 0.08)
	grass_mat.set_shader_parameter("roughness", 0.80)

	mmi.material_override = grass_mat
	mm.mesh = grass_mesh
	mmi.multimesh = mm

	var half_size: float = terrain.island_size * 0.42

	for i in range(target_count):
		# Concentrate 70% in the Showcase Valley, Glade & Lake Basin zone (-8 to 26, -5 to 22)
		var x: float
		var z: float
		if rng.randf() < 0.70:
			x = rng.randf_range(-8.0, 26.0)
			z = rng.randf_range(-5.0, 22.0)
		else:
			x = rng.randf_range(-half_size, half_size)
			z = rng.randf_range(-half_size, half_size)

		var y: float = terrain.get_height_at(x, z)

		var suitable: bool = (y >= 0.8 and y <= 11.2)
		if grid and suitable:
			var env: Dictionary = grid.get_environment_at(x, z)
			if env.get("moisture", 0.5) < 0.18:
				suitable = false

		# Animal Trail suppression: suppress grass on the compacted footpath
		if terrain.get_trail_factor(x, z) > 0.32:
			suitable = false

		# Prevent grass clumps from directly obstructing key vantage cameras
		if Vector2(x - 25.0, z - 21.0).length() < 3.2 or Vector2(x - 2.5, z - 4.5).length() < 1.8 or Vector2(x - (-14.0), z - 4.0).length() < 2.0:
			suitable = false

		if suitable:
			# Calculate local slope to conform grass transform to terrain normal
			var d: float = 0.5
			var sx: float = (terrain.get_height_at(x + d, z) - terrain.get_height_at(x - d, z)) / (2.0 * d)
			var sz: float = (terrain.get_height_at(x, z + d) - terrain.get_height_at(x, z - d)) / (2.0 * d)

			var t: Transform3D = Transform3D()
			var s: float = rng.randf_range(0.46, 0.70)
			# Extra lush density in central meadow glade
			if x >= 4.0 and x <= 16.0 and z >= 0.0 and z <= 10.0:
				s = rng.randf_range(0.54, 0.80)
			t = t.scaled(Vector3(s, s * randf_range(0.92, 1.15), s))
			t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			# Natural slope tilt
			t = t.rotated(Vector3.RIGHT, clampf(-sz * 0.35, -0.4, 0.4))
			t = t.rotated(Vector3.FORWARD, clampf(sx * 0.35, -0.4, 0.4))
			t.origin = Vector3(x, y, z)
			mm.set_instance_transform(i, t)
		else:
			var t: Transform3D = Transform3D()
			t.origin = Vector3(0.0, -100.0, 0.0)
			mm.set_instance_transform(i, t)

	add_child(mmi)
	_grass_multimesh = mmi
