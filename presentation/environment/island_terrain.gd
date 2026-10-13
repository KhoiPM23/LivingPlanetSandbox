class_name IslandTerrain
extends StaticBody3D

## Generates a procedural, bounded island driven by WorldGenerationConfig and EnvironmentalGrid.

@export var island_size: float = 160.0 # 160m x 160m bounded world
@export var resolution: int = 128 # 128x128 vertices
@export var max_height: float = 24.0 # Mountain peak height
@export var water_level: float = 0.0
@export var roughness: float = 0.5

var _mesh_instance: MeshInstance3D
var _collision_shape: CollisionShape3D
var _seed_val: int = 0
var _noise: FastNoiseLite
var _env_grid: EnvironmentalGrid

func generate_island(config_or_seed: Variant = 1337, grid: EnvironmentalGrid = null) -> void:
	if config_or_seed is WorldGenerationConfig:
		var cfg: WorldGenerationConfig = config_or_seed as WorldGenerationConfig
		_seed_val = cfg.seed_val
		island_size = cfg.island_size
		resolution = cfg.resolution
		max_height = cfg.max_height
		water_level = cfg.water_level
		roughness = cfg.roughness
	elif config_or_seed is int:
		_seed_val = config_or_seed
	else:
		_seed_val = 1337
		
	_env_grid = grid
	
	_noise = FastNoiseLite.new()
	_noise.seed = _seed_val
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.015
	_noise.fractal_octaves = 4
	_noise.fractal_lacunarity = 2.0
	_noise.fractal_gain = roughness
	
	if _env_grid:
		_env_grid.initialize_grid(Callable(self, "get_height_at"))
		
	_build_terrain_mesh()
	_build_world_boundaries()

func get_height_at(x: float, z: float) -> float:
	if not _noise:
		return 0.0
		
	var half_size: float = island_size * 0.5
	var dist_from_center: float = Vector2(x, z).length()
	var radius: float = half_size * 0.95
	
	# Radial mask: 1.0 at center, drops to 0.0 at shoreline, negative in ocean
	var t: float = clamp(dist_from_center / radius, 0.0, 1.0)
	var mask: float = cos(t * PI * 0.5)
	mask = pow(mask, 1.2) # Flattens beaches near edges
	
	# Primary terrain noise
	var n_base: float = (_noise.get_noise_2d(x, z) + 1.0) * 0.5
	# Secondary mountain ridge accent
	var n_ridge: float = abs(_noise.get_noise_2d(x * 1.8 + 100.0, z * 1.8 + 100.0))
	
	# Prominent summit peak in north-west quadrant centered at (-24.0, -24.0)
	var peak_dist: float = Vector2(x - (-24.0), z - (-24.0)).length()
	var peak_feature: float = exp(-pow(peak_dist / 22.0, 2.0)) * 14.0
	
	# 3.5m dry land base ensures island interior remains dry meadow/forest above waterline
	var elevation: float = (3.5 + n_base * 5.0 + n_ridge * 3.0 + peak_feature) * mask
	
	# Submerge edges below water level
	if dist_from_center > radius * 0.85:
		var edge_drop: float = (dist_from_center - radius * 0.85) / (radius * 0.15)
		elevation -= edge_drop * 10.0
		
	return elevation

func _build_terrain_mesh() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var step: float = island_size / float(resolution - 1)
	var half_size: float = island_size * 0.5
	
	# Grid of vertices
	var vertices: PackedVector3Array = PackedVector3Array()
	vertices.resize(resolution * resolution)
	
	for z_idx in range(resolution):
		var z_pos: float = -half_size + float(z_idx) * step
		for x_idx in range(resolution):
			var x_pos: float = -half_size + float(x_idx) * step
			var y_pos: float = get_height_at(x_pos, z_pos)
			vertices[z_idx * resolution + x_idx] = Vector3(x_pos, y_pos, z_pos)
			
	# Construct triangles with smooth normals & slope/height vertex colors
	for z_idx in range(resolution - 1):
		for x_idx in range(resolution - 1):
			var i0: int = z_idx * resolution + x_idx
			var i1: int = z_idx * resolution + (x_idx + 1)
			var i2: int = (z_idx + 1) * resolution + x_idx
			var i3: int = (z_idx + 1) * resolution + (x_idx + 1)
			
			var v0: Vector3 = vertices[i0]
			var v1: Vector3 = vertices[i1]
			var v2: Vector3 = vertices[i2]
			var v3: Vector3 = vertices[i3]
			
			_add_terrain_vertex(st, v0)
			_add_terrain_vertex(st, v1)
			_add_terrain_vertex(st, v2)
			
			_add_terrain_vertex(st, v1)
			_add_terrain_vertex(st, v3)
			_add_terrain_vertex(st, v2)
			
	st.generate_normals()
	st.generate_tangents()
	
	var array_mesh: ArrayMesh = st.commit()
	
	# Material with vertex color blending
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	mat.metallic_specular = 0.1
	
	if not _mesh_instance:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "TerrainMeshInstance"
		add_child(_mesh_instance)
		
	_mesh_instance.mesh = array_mesh
	_mesh_instance.material_override = mat
	
	# Generate exact collision shape
	if not _collision_shape:
		_collision_shape = CollisionShape3D.new()
		_collision_shape.name = "TerrainCollisionShape"
		add_child(_collision_shape)
		
	_collision_shape.shape = array_mesh.create_trimesh_shape()

func _add_terrain_vertex(st: SurfaceTool, pos: Vector3) -> void:
	var h: float = pos.y
	var col: Color = Color(0.86, 0.80, 0.62) # Sand default
	
	if _env_grid:
		var env_data: Dictionary = _env_grid.get_environment_at(pos.x, pos.z)
		var b_type: BiomeClassifier.BiomeType = env_data.get("biome", BiomeClassifier.BiomeType.TEMPERATE_MEADOW) as BiomeClassifier.BiomeType
		col = BiomeClassifier.get_biome_color(b_type)
	else:
		# Native height-fallback
		var col_sand: Color = Color(0.86, 0.80, 0.62)
		var col_meadow: Color = Color(0.36, 0.58, 0.26)
		var col_forest: Color = Color(0.22, 0.44, 0.20)
		var col_rock: Color = Color(0.48, 0.48, 0.50)
		var col_peak_snow: Color = Color(0.85, 0.88, 0.92)
		
		if h < 0.8:
			col = col_sand
		elif h < 1.8:
			col = col_sand.lerp(col_meadow, (h - 0.8) / 1.0)
		elif h < 7.5:
			col = col_meadow.lerp(col_forest, (h - 1.8) / 5.7)
		elif h < 11.5:
			col = col_forest.lerp(col_rock, (h - 7.5) / 4.0)
		else:
			col = col_rock.lerp(col_peak_snow, clamp((h - 11.5) / 3.0, 0.0, 1.0) * 0.4)
			
	# Organic slope, shoreline, and alpine snow blending
	var d: float = 0.8
	var dx: float = (get_height_at(pos.x + d, pos.z) - get_height_at(pos.x - d, pos.z)) / (2.0 * d)
	var dz: float = (get_height_at(pos.x, pos.z + d) - get_height_at(pos.x, pos.z - d)) / (2.0 * d)
	var slope: float = sqrt(dx * dx + dz * dz)
	
	if slope > 0.38:
		var rock_factor: float = clampf((slope - 0.38) / 0.45, 0.0, 1.0)
		var col_rock: Color = Color(0.42, 0.43, 0.46)
		col = col.lerp(col_rock, rock_factor * 0.82)
		
	if h < 1.1 and h >= -0.5:
		var sand_factor: float = clampf(1.0 - (h / 1.1), 0.0, 1.0)
		var col_sand: Color = Color(0.84, 0.77, 0.58)
		col = col.lerp(col_sand, sand_factor * 0.88)
		
	if h > 12.0:
		var snow_factor: float = clampf((h - 12.0) / 3.5, 0.0, 1.0)
		var col_snow: Color = Color(0.92, 0.94, 0.98)
		col = col.lerp(col_snow, snow_factor * 0.80)
		
	# Subtle organic micro-variation
	var noise_mod: float = (sin(pos.x * 0.8) * cos(pos.z * 0.8)) * 0.035
	col.r = clampf(col.r + noise_mod, 0.0, 1.0)
	col.g = clampf(col.g + noise_mod, 0.0, 1.0)
	col.b = clampf(col.b + noise_mod, 0.0, 1.0)
	
	st.set_color(col)
	st.set_uv(Vector2(pos.x * 0.1, pos.z * 0.1))
	st.add_vertex(pos)

func _build_world_boundaries() -> void:
	# 4 invisible perimeter boundary barriers preventing player from falling out of world bounds
	var half: float = island_size * 0.5
	var wall_height: float = 60.0
	var thickness: float = 4.0
	
	var boundaries_data: Array = [
		{"pos": Vector3(0, wall_height * 0.5, -half), "size": Vector3(island_size, wall_height, thickness)},
		{"pos": Vector3(0, wall_height * 0.5, half), "size": Vector3(island_size, wall_height, thickness)},
		{"pos": Vector3(-half, wall_height * 0.5, 0), "size": Vector3(thickness, wall_height, island_size)},
		{"pos": Vector3(half, wall_height * 0.5, 0), "size": Vector3(thickness, wall_height, island_size)}
	]
	
	var boundaries_node: Node3D = Node3D.new()
	boundaries_node.name = "WorldBoundaries"
	add_child(boundaries_node)
	
	for data in boundaries_data:
		var sb: StaticBody3D = StaticBody3D.new()
		var col: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = data["size"]
		col.shape = box
		sb.position = data["pos"]
		sb.add_child(col)
		boundaries_node.add_child(sb)
