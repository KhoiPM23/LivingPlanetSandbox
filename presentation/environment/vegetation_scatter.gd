class_name VegetationScatter
extends Node3D

## Deterministically scatters vegetation, rock formations, and landmark monolith across IslandTerrain.
## Uses MultiMeshInstance3D for grass blades to maintain 60+ FPS on Intel Iris Xe graphics.

@export var tree_count: int = 55
@export var rock_count: int = 35
@export var grass_count: int = 800

var _grass_multimesh: MultiMeshInstance3D = null

func scatter(terrain: IslandTerrain, seed_val: int = 1337, registry: EntityRegistry = null, grid: EnvironmentalGrid = null, config: WorldGenerationConfig = null) -> void:
	# Clear existing children if regenerating
	for child in get_children():
		child.queue_free()
		
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	var density: float = config.vegetation_density if config != null else 1.0
	var final_trees: int = int(tree_count * density)
	var final_grass: int = int(grass_count * density)
	
	_scatter_landmark(terrain, registry, grid)
	_scatter_trees(terrain, rng, registry, grid, final_trees)
	_scatter_rocks(terrain, rng, grid)
	_scatter_grass_multimesh(terrain, rng, grid, final_grass)

func _scatter_landmark(terrain: IslandTerrain, registry: EntityRegistry = null, grid: EnvironmentalGrid = null) -> void:
	# Place monolith near high peak in north-west quadrant
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
		tree.tree_scale = rng.randf_range(0.85, 1.35)
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
		rock.rock_scale = rng.randf_range(0.6, 1.7)
		rock.position = Vector3(x, y, z)
		rock.rotation.y = rng.randf_range(0.0, TAU)
		rock.rotation.x = rng.randf_range(-0.15, 0.15)
		add_child(rock)
		placed += 1

func _scatter_grass_multimesh(terrain: IslandTerrain, rng: RandomNumberGenerator, grid: EnvironmentalGrid = null, target_count: int = 800) -> void:
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = "GrassMultiMesh"
	
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = target_count
	
	var grass_mesh: PrismMesh = PrismMesh.new()
	grass_mesh.size = Vector3(0.5, 0.7, 0.05)
	
	var grass_mat: ShaderMaterial = ShaderMaterial.new()
	grass_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
	grass_mat.set_shader_parameter("wind_speed", 1.8)
	grass_mat.set_shader_parameter("wind_strength", 0.3)
	
	mmi.material_override = grass_mat
	mm.mesh = grass_mesh
	mmi.multimesh = mm
	
	var half_size: float = terrain.island_size * 0.42
	
	for i in range(target_count):
		var x: float = rng.randf_range(-half_size, half_size)
		var z: float = rng.randf_range(-half_size, half_size)
		var y: float = terrain.get_height_at(x, z)
		
		var suitable: bool = (y >= 1.2 and y <= 10.5)
		if grid and suitable:
			var env: Dictionary = grid.get_environment_at(x, z)
			if env.get("moisture", 0.5) < 0.25:
				suitable = false # Parched soil cannot sustain grass tufts
				
		if suitable:
			var t: Transform3D = Transform3D()
			var s: float = rng.randf_range(0.7, 1.3)
			t = t.scaled(Vector3(s, s, s))
			t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			t.origin = Vector3(x, y + 0.35, z)
			mm.set_instance_transform(i, t)
		else:
			var t: Transform3D = Transform3D()
			t.origin = Vector3(0.0, -100.0, 0.0)
			mm.set_instance_transform(i, t)
			
	add_child(mmi)
	_grass_multimesh = mmi
