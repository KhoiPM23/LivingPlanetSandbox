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
static var _cached_nature_props: Dictionary = {}

static func _init_asset_cache() -> void:
	if _cached_grass_mesh != null:
		return

	# Load Forest Pack (KayKit CC0)
	var f_gltf: GLTFDocument = GLTFDocument.new()
	var f_state: GLTFState = GLTFState.new()
	if f_gltf.append_from_file("res://presentation/assets/models/forest.glb", f_state) == OK:
		var f_root: Node = f_gltf.generate_scene(f_state)
		if f_root:
			var g_node: MeshInstance3D = f_root.find_child("Grass_2_D_Color1", true, false) as MeshInstance3D
			if g_node and g_node.mesh:
				_cached_grass_mesh = g_node.mesh
				if g_node.mesh.get_surface_count() > 0:
					var m = g_node.mesh.surface_get_material(0)
					if m is StandardMaterial3D and m.albedo_texture:
						_cached_grass_tex = m.albedo_texture

			for bname in ["Bush_1_E_Color1", "Bush_3_B_Color1"]:
				var b_node: MeshInstance3D = f_root.find_child(bname, true, false) as MeshInstance3D
				if b_node and b_node.mesh:
					_cached_bush_meshes.append(b_node.mesh)
					if _cached_bush_mat == null and b_node.mesh.get_surface_count() > 0:
						_cached_bush_mat = b_node.mesh.surface_get_material(0)

			f_root.free()

	# Load Nature Kit (Kenney CC0)
	var n_gltf: GLTFDocument = GLTFDocument.new()
	var n_state: GLTFState = GLTFState.new()
	if n_gltf.append_from_file("res://presentation/assets/models/nature.glb", n_state) == OK:
		var n_root: Node = n_gltf.generate_scene(n_state)
		if n_root:
			var prop_keys: Array = ["flower_purpleA", "flower_yellowA", "flower_redA", "log_large", "mushroom_redGroup", "plant_bushDetailed", "lily_large"]
			for pk in prop_keys:
				var mi: MeshInstance3D = n_root.find_child(pk, true, false) as MeshInstance3D
				if mi and mi.mesh:
					_cached_nature_props[pk] = {
						"mesh": mi.mesh,
						"mat": mi.mesh.surface_get_material(0) if mi.mesh.get_surface_count() > 0 else null
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
	var max_attempts: int = target_count * 6
	var half_size: float = terrain.island_size * 0.42

	while placed < target_count and attempts < max_attempts:
		attempts += 1
		var x: float = rng.randf_range(-half_size, half_size)
		var z: float = rng.randf_range(-half_size, half_size)
		var y: float = terrain.get_height_at(x, z)

		# Trees prefer meadows and valley slopes: elevation between 2.2 and 12.0
		if y < 2.2 or y > 12.0:
			continue

		# Check ecological compatibility if EnvironmentalGrid exists
		var env_data: Dictionary = {}
		if grid:
			env_data = grid.get_environment_at(x, z)
			var b_type: int = env_data.get("biome", BiomeClassifier.BiomeType.TEMPERATE_MEADOW)
			if b_type != BiomeClassifier.BiomeType.BOREAL_FOREST and b_type != BiomeClassifier.BiomeType.TEMPERATE_MEADOW:
				continue
			if env_data.get("moisture", 0.5) < 0.32:
				continue # Soil too dry for conifers

		# Check local slope
		var delta: float = 1.0
		var slope_x: float = abs(terrain.get_height_at(x + delta, z) - terrain.get_height_at(x - delta, z)) / (2.0 * delta)
		var slope_z: float = abs(terrain.get_height_at(x, z + delta) - terrain.get_height_at(x, z - delta)) / (2.0 * delta)
		if slope_x > 0.85 or slope_z > 0.85:
			continue # Too steep

		var tree: TreePine = TreePine.new()
		tree.tree_scale = rng.randf_range(0.85, 1.45)
		tree.position = Vector3(x, y, z)
		tree.rotation.y = rng.randf_range(0.0, TAU)
		add_child(tree)
		placed += 1

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
	var max_attempts: int = rock_count * 4
	var half_size: float = terrain.island_size * 0.44

	while placed < rock_count and attempts < max_attempts:
		attempts += 1
		var x: float = rng.randf_range(-half_size, half_size)
		var z: float = rng.randf_range(-half_size, half_size)
		var y: float = terrain.get_height_at(x, z)

		if y < 0.2:
			continue

		var rock: RockBoulder = RockBoulder.new()
		rock.rock_scale = rng.randf_range(0.7, 1.8)
		rock.position = Vector3(x, y, z)
		rock.rotation.y = rng.randf_range(0.0, TAU)
		rock.rotation.x = rng.randf_range(-0.15, 0.15)
		add_child(rock)
		placed += 1

func _scatter_understory(terrain: IslandTerrain, rng: RandomNumberGenerator, grid: EnvironmentalGrid = null, target_count: int = 45) -> void:
	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = target_count * 5
	var half_size: float = terrain.island_size * 0.42

	var flower_keys: Array = ["flower_purpleA", "flower_yellowA", "flower_redA"]

	while placed < target_count and attempts < max_attempts:
		attempts += 1
		var x: float = rng.randf_range(-half_size, half_size)
		var z: float = rng.randf_range(-half_size, half_size)
		var y: float = terrain.get_height_at(x, z)

		if y < 0.3 or y > 11.0:
			continue

		var env_data: Dictionary = grid.get_environment_at(x, z) if grid else {}
		var moisture: float = env_data.get("moisture", 0.5)
		var b_type: int = env_data.get("biome", BiomeClassifier.BiomeType.TEMPERATE_MEADOW)

		# Choose prop based on ecological niche
		var prop_inst: MeshInstance3D = null

		if moisture > 0.65 and _cached_nature_props.has("mushroom_redGroup") and rng.randf() < 0.30:
			# Shaded damp grove: mushrooms
			prop_inst = MeshInstance3D.new()
			prop_inst.mesh = _cached_nature_props["mushroom_redGroup"]["mesh"]
			prop_inst.material_override = _cached_nature_props["mushroom_redGroup"]["mat"]
			prop_inst.scale = Vector3.ONE * rng.randf_range(0.8, 1.4)
		elif moisture > 0.55 and _cached_nature_props.has("log_large") and rng.randf() < 0.25:
			# Forest floor: fallen log
			prop_inst = MeshInstance3D.new()
			prop_inst.mesh = _cached_nature_props["log_large"]["mesh"]
			prop_inst.material_override = _cached_nature_props["log_large"]["mat"]
			prop_inst.scale = Vector3.ONE * rng.randf_range(0.7, 1.2)
		elif b_type == BiomeClassifier.BiomeType.TEMPERATE_MEADOW and rng.randf() < 0.40:
			# Sunlit meadow: colorful wildflowers
			var fk: String = flower_keys[rng.randi() % flower_keys.size()]
			if _cached_nature_props.has(fk):
				prop_inst = MeshInstance3D.new()
				prop_inst.mesh = _cached_nature_props[fk]["mesh"]
				prop_inst.material_override = _cached_nature_props[fk]["mat"]
				prop_inst.scale = Vector3.ONE * rng.randf_range(0.9, 1.5)
		elif not _cached_bush_meshes.is_empty():
			# Understory bush
			var b_mesh: Mesh = _cached_bush_meshes[rng.randi() % _cached_bush_meshes.size()]
			prop_inst = MeshInstance3D.new()
			prop_inst.mesh = b_mesh
			if _cached_bush_mat:
				prop_inst.material_override = _cached_bush_mat
			prop_inst.scale = Vector3.ONE * rng.randf_range(0.7, 1.3)

		if prop_inst:
			prop_inst.position = Vector3(x, y, z)
			prop_inst.rotation.y = rng.randf_range(0.0, TAU)
			# Optimize shadow passes: only dense bushes and heavy logs cast shadows
			if not _cached_bush_meshes.is_empty() and prop_inst.mesh in _cached_bush_meshes:
				prop_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			elif _cached_nature_props.has("log_large") and prop_inst.mesh == _cached_nature_props["log_large"]["mesh"]:
				prop_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			else:
				prop_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(prop_inst)
			placed += 1

func _scatter_grass_multimesh(terrain: IslandTerrain, rng: RandomNumberGenerator, grid: EnvironmentalGrid = null, target_count: int = 900) -> void:
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = "GrassMultiMesh"
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = target_count

	var grass_mesh: Mesh = _cached_grass_mesh
	if grass_mesh == null:
		var p_mesh: PrismMesh = PrismMesh.new()
		p_mesh.size = Vector3(0.5, 0.7, 0.05)
		grass_mesh = p_mesh

	var grass_mat: ShaderMaterial = ShaderMaterial.new()
	grass_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
	if _cached_grass_tex != null:
		grass_mat.set_shader_parameter("albedo_texture", _cached_grass_tex)
		grass_mat.set_shader_parameter("use_texture", true)
	else:
		grass_mat.set_shader_parameter("albedo_top", Color(0.32, 0.65, 0.26, 1.0))
		grass_mat.set_shader_parameter("albedo_bottom", Color(0.16, 0.38, 0.14, 1.0))
		grass_mat.set_shader_parameter("use_texture", false)

	grass_mat.set_shader_parameter("wind_speed", 1.8)
	grass_mat.set_shader_parameter("wind_strength", 0.3)
	grass_mat.set_shader_parameter("wetness", 0.0)

	mmi.material_override = grass_mat
	mm.mesh = grass_mesh
	mmi.multimesh = mm

	var half_size: float = terrain.island_size * 0.42

	for i in range(target_count):
		var x: float = rng.randf_range(-half_size, half_size)
		var z: float = rng.randf_range(-half_size, half_size)
		var y: float = terrain.get_height_at(x, z)

		var suitable: bool = (y >= 1.1 and y <= 11.0)
		if grid and suitable:
			var env: Dictionary = grid.get_environment_at(x, z)
			if env.get("moisture", 0.5) < 0.22:
				suitable = false

		if suitable:
			var t: Transform3D = Transform3D()
			var s: float = rng.randf_range(0.55, 0.95)
			t = t.scaled(Vector3(s, s * 0.85, s))
			t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			t.origin = Vector3(x, y, z)
			mm.set_instance_transform(i, t)
		else:
			var t: Transform3D = Transform3D()
			t.origin = Vector3(0.0, -100.0, 0.0)
			mm.set_instance_transform(i, t)

	add_child(mmi)
	_grass_multimesh = mmi
