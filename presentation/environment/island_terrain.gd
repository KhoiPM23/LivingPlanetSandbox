class_name IslandTerrain
extends StaticBody3D

## Generates a procedural, bounded island driven by WorldGenerationConfig and EnvironmentalGrid.

@export var island_size: float = 160.0 # 160m x 160m bounded world
@export var resolution: int = 128 # 128x128 vertices
@export var max_height: float = 24.0 # Mountain peak height
@export var water_level: float = 0.0
@export var roughness: float = 0.5

class TerrainMaterialWrapper extends ShaderMaterial:
	var roughness: float = 0.85
	var metallic_specular: float = 0.10
	var albedo_color: Color = Color.WHITE

var _mesh_instance: MeshInstance3D
var _collision_shape: CollisionShape3D
var _seed_val: int = 0
var _noise: FastNoiseLite
var _env_grid: EnvironmentalGrid
var _terrain_material: Variant = null

# --- SURFACE REACTION & WETNESS ---
var surface_wetness: float = 0.0 # 0.0 = bone dry, 1.0 = saturated wet sheen

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

	# Prominent summit peak in north-west quadrant centered at (-24.0, -24.0) with geological strata
	var peak_dist: float = Vector2(x - (-24.0), z - (-24.0)).length()
	var peak_feature: float = exp(-pow(peak_dist / 22.0, 2.0)) * 14.5
	var stratified_peak: float = peak_feature + sin(peak_feature * 1.2) * 0.85

	# Natural elongated lake cove with organic shoreline bays in south-east quadrant
	# Main basin centered at (16.0, 14.0) elongated along (dx=0.85, dz=0.52)
	var dx_lake: float = x - 16.0
	var dz_lake: float = z - 14.0
	# Rotate lake coordinates ~30 degrees for natural orientation
	var l_u: float = dx_lake * 0.866 + dz_lake * 0.5
	var l_v: float = -dx_lake * 0.5 + dz_lake * 0.866
	var lake_ellipse: float = sqrt(pow(l_u / 15.0, 2.0) + pow(l_v / 10.0, 2.0))
	# Shoreline noise distortion for natural gravel coves and inlets
	var lake_shore_noise: float = _noise.get_noise_2d(x * 0.08 + 50.0, z * 0.08 + 50.0) * 0.22
	var lake_carve: float = exp(-pow((lake_ellipse + lake_shore_noise) / 1.0, 2.2)) * 6.8

	# Winding mountain stream inlet carving from valley (-2.0, 4.0) down into the lake (12.0, 11.0)
	var creek_t: float = clamp((x - (-2.0)) / 14.0, 0.0, 1.0)
	var creek_center_z: float = lerp(4.0, 11.0, creek_t) + sin(creek_t * PI * 2.0) * 2.2
	var creek_dist_z: float = abs(z - creek_center_z)
	var creek_carve: float = 0.0
	if x >= -4.0 and x <= 14.0:
		var creek_envelope: float = sin(creek_t * PI)
		var channel_shape: float = clampf(1.0 - (creek_dist_z / 2.6), 0.0, 1.0)
		var channel_bed: float = pow(channel_shape, 1.3) * 1.65 * creek_envelope
		var riffle: float = sin(creek_t * 18.0) * 0.06 * creek_envelope * (1.0 if channel_shape >= 0.2 else 0.0)
		creek_carve = channel_bed - riffle

	# Rocky bluff overlook on the east bank of the lake cove (24.0, 16.0)
	var bluff_dist: float = Vector2(x - 24.0, z - 16.0).length()
	var bluff_feature: float = exp(-pow(bluff_dist / 8.5, 2.0)) * 3.8

	# Geological rock outcrop crags on mountain peak and bluff faces
	var crag_crests: float = 0.0
	if peak_dist < 30.0:
		var p_w: float = clampf(1.0 - (peak_dist / 30.0), 0.0, 1.0)
		var n_crag: float = 1.0 - abs(_noise.get_noise_2d(x * 0.08 + 180.0, z * 0.08 + 180.0) * 2.0)
		crag_crests += clampf(n_crag, 0.0, 1.0) * 1.5 * p_w
	if bluff_dist < 14.0:
		var b_w: float = clampf(1.0 - (bluff_dist / 14.0), 0.0, 1.0)
		var n_crag_bluff: float = 1.0 - abs(_noise.get_noise_2d(x * 0.12 + 250.0, z * 0.12 + 250.0) * 2.0)
		crag_crests += clampf(n_crag_bluff, 0.0, 1.0) * 1.0 * b_w

	# Talus scree debris collar at the foot of the eastern granite bluff
	var talus_feature: float = 0.0
	if bluff_dist >= 6.0 and bluff_dist <= 14.0:
		var talus_t: float = 1.0 - abs(bluff_dist - 9.5) / 4.0
		var n_scree: float = _noise.get_noise_2d(x * 0.14 + 320.0, z * 0.14 + 320.0) * 0.28
		talus_feature = clampf(talus_t, 0.0, 1.0) * (0.55 + n_scree)

	# Raw geological landmass formation
	var raw_elevation: float = 3.2 + n_base * 4.2 + n_ridge * 3.0 + stratified_peak + bluff_feature + crag_crests + talus_feature - lake_carve - creek_carve

	# Sedimentary strata terracing: horizontal bedding planes (~2.6m layer thickness)
	var strata_weight: float = clampf((peak_feature / 14.5) * 0.65 + (bluff_feature / 3.8) * 0.55 + n_ridge * 0.35, 0.0, 1.0)
	var strata_shelf: float = 0.0
	if strata_weight > 0.04:
		var strata_phase: float = raw_elevation / 2.6
		strata_shelf = (sin(strata_phase * TAU) - 0.22 * sin(strata_phase * 2.0 * TAU)) * 0.36 * strata_weight

	var elevation: float = (raw_elevation + strata_shelf) * mask

	# Central Meadow Glade terraced grazing bench (X: 3.0 to 15.0, Z: -1.0 to 8.0)
	var glade_dist_x: float = abs(x - 9.0) / 6.0
	var glade_dist_z: float = abs(z - 3.5) / 4.5
	var glade_box: float = maxf(glade_dist_x, glade_dist_z)
	var glade_factor: float = clampf(1.0 - glade_box, 0.0, 1.0)
	if glade_factor > 0.0:
		var glade_weight: float = smoothstep(0.0, 1.0, glade_factor) * 0.40
		elevation = lerpf(elevation, 3.85 + (n_base - 0.5) * 0.5, glade_weight)

	# Animal trail slight compacted indentation
	var trail_f: float = get_trail_factor(x, z)
	if trail_f > 0.0:
		elevation -= trail_f * 0.08

	# Submerge edges below water level
	if dist_from_center > radius * 0.85:
		var edge_drop: float = (dist_from_center - radius * 0.85) / (radius * 0.15)
		elevation -= edge_drop * 10.0

	return elevation

func get_trail_factor(x: float, z: float) -> float:
	# Animal path winding from Whispering Forest edge (-6.0, -1.0)
	# through Meadow glade (1.0, 3.5), (6.0, 6.0), to Emerald Basin shore (12.5, 8.5)
	if x < -8.0 or x > 14.5 or z < -3.5 or z > 12.0:
		return 0.0
	var t: float = clampf((x - (-6.0)) / 18.5, 0.0, 1.0)
	var path_z: float = lerpf(-1.0, 8.5, t) + sin(t * PI) * 1.85
	var dist_to_path: float = abs(z - path_z)
	var width: float = 1.6
	if dist_to_path > width:
		return 0.0
	return clampf(1.0 - (dist_to_path / width), 0.0, 1.0)

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

	# Material with PBR Triplanar Slope Blending & Biome vertex modulation
	var shader: Shader = load("res://presentation/shaders/terrain_pbr.gdshader")
	var mat: TerrainMaterialWrapper = TerrainMaterialWrapper.new()
	mat.shader = shader
	mat.set_shader_parameter("ground_albedo", load("res://demo/assets/textures/ground037_alb_ht.png"))
	mat.set_shader_parameter("ground_normal", load("res://demo/assets/textures/ground037_nrm_rgh.png"))
	mat.set_shader_parameter("rock_albedo", load("res://demo/assets/textures/rock023_alb_ht.png"))
	mat.set_shader_parameter("rock_normal", load("res://demo/assets/textures/rock023_nrm_rgh.png"))
	mat.set_shader_parameter("uv_scale", 0.22)
	mat.set_shader_parameter("rock_uv_scale", 0.14)
	mat.set_shader_parameter("slope_threshold", 0.25)
	mat.set_shader_parameter("slope_blend", 0.10)
	mat.roughness = 0.85
	mat.metallic_specular = 0.10
	_terrain_material = mat
	_apply_surface_material_properties()

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

func get_surface_wetness() -> float:
	return surface_wetness

func set_surface_wetness(val: float) -> void:
	surface_wetness = clampf(val, 0.0, 1.0)
	_apply_surface_material_properties()

func update_surface_reaction(delta: float, weather: WeatherSystem = null) -> void:
	if weather:
		match weather.current_state:
			WeatherSystem.WeatherState.RAIN:
				# Rain rapidly accumulates surface water sheen
				surface_wetness = minf(1.0, surface_wetness + 0.10 * delta)
			WeatherSystem.WeatherState.DROUGHT:
				# Drought bakes and dries surface rapidly
				surface_wetness = maxf(0.0, surface_wetness - 0.12 * delta)
			WeatherSystem.WeatherState.CLEAR:
				# Sun and air steadily evaporate standing wetness
				surface_wetness = maxf(0.0, surface_wetness - 0.035 * delta)
			WeatherSystem.WeatherState.CLOUDY:
				# Moderate equilibrium
				surface_wetness = move_toward(surface_wetness, 0.12, 0.015 * delta)

	_apply_surface_material_properties(weather)

func _apply_surface_material_properties(weather: WeatherSystem = null) -> void:
	if not _terrain_material:
		return

	# Wet earth and damp rock become reflective and smooth
	_terrain_material.roughness = lerpf(0.85, 0.28, surface_wetness)
	_terrain_material.metallic_specular = lerpf(0.10, 0.55, surface_wetness)

	# Damp surfaces darken by up to 20%
	var damp_factor: float = lerpf(1.0, 0.80, surface_wetness)
	if weather and weather.current_state == WeatherSystem.WeatherState.DROUGHT:
		_terrain_material.albedo_color = Color(1.04, 1.02, 0.96)
	else:
		_terrain_material.albedo_color = Color(damp_factor, damp_factor, damp_factor)

	if _terrain_material is ShaderMaterial:
		_terrain_material.set_shader_parameter("wetness", surface_wetness)

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

	# Showcase Region: Central Meadow Glade lush pasture tint
	var glade_dx: float = abs(pos.x - 9.0) / 6.0
	var glade_dz: float = abs(pos.z - 3.5) / 4.5
	var glade_f: float = clampf(1.0 - maxf(glade_dx, glade_dz), 0.0, 1.0)
	if glade_f > 0.0:
		var col_glade_lush: Color = Color(0.35, 0.56, 0.20)
		col = col.lerp(col_glade_lush, glade_f * 0.60)

	# Showcase Region: Eastern Granite Bluff talus scree apron (X: 20 to 26, Z: 12 to 20)
	var bluff_talus_dist: float = Vector2(pos.x - 22.5, pos.z - 16.5).length()
	if bluff_talus_dist < 6.5 and slope > 0.20:
		var talus_weight: float = clampf((6.5 - bluff_talus_dist) / 6.5, 0.0, 1.0) * clampf((slope - 0.20) / 0.35, 0.0, 1.0)
		var col_scree: Color = Color(0.42, 0.40, 0.38)
		col = col.lerp(col_scree, talus_weight * 0.75)

	# Showcase Region: Animal trail compacted dark loam
	var trail_f: float = get_trail_factor(pos.x, pos.z)
	if trail_f > 0.0:
		var col_trail_loam: Color = Color(0.24, 0.18, 0.13)
		col = col.lerp(col_trail_loam, trail_f * 0.90)

	# Showcase Region: Creek bed eroded channel gravel & pebble floor
	if pos.x >= -4.0 and pos.x <= 14.0:
		var creek_t_v: float = clampf((pos.x - (-2.0)) / 14.0, 0.0, 1.0)
		var creek_cz: float = lerpf(4.0, 11.0, creek_t_v) + sin(creek_t_v * PI * 2.0) * 2.2
		var dist_cz: float = abs(pos.z - creek_cz)
		if dist_cz < 2.4:
			var gravel_w: float = clampf(1.0 - (dist_cz / 2.4), 0.0, 1.0) * sin(creek_t_v * PI)
			var col_gravel: Color = Color(0.36, 0.34, 0.30)
			col = col.lerp(col_gravel, gravel_w * 0.82)

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
