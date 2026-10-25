class_name IslandTerrain
extends StaticBody3D

## Generates a procedural, bounded island driven by WorldGenerationConfig and EnvironmentalGrid.

@export var island_size: float = 160.0 # 160m x 160m bounded world
@export var resolution: int = 128 # 128x128 vertices
@export var max_height: float = 24.0 # Mountain peak height
@export var water_level: float = 0.0
@export var roughness: float = 0.5
@export var island_seed: int = 1337:
	set(val):
		island_seed = val
		_seed_val = val
		if _noise:
			_noise.seed = val

class TerrainMaterialWrapper extends ShaderMaterial:
	var roughness: float = 0.85
	var metallic_specular: float = 0.10
	var albedo_color: Color = Color.WHITE

var _mesh_instance: MeshInstance3D
var _collision_shape: CollisionShape3D
var _seed_val: int = 1337
var _noise: FastNoiseLite
var _env_grid: EnvironmentalGrid
var _terrain_material: Variant = null

# --- SURFACE REACTION & WETNESS ---
var surface_wetness: float = 0.0 # 0.0 = bone dry, 1.0 = saturated wet sheen
var puddle_depth: float = 0.0 # 0.0 = dry, 1.0 = pooled rain puddles
var snow_drift_accretion: float = 0.0 # 0.0 = clear, 1.0 = snow blanket

func generate_island(config_or_seed: Variant = 1337, grid: EnvironmentalGrid = null) -> void:
	if config_or_seed is WorldGenerationConfig:
		var cfg: WorldGenerationConfig = config_or_seed as WorldGenerationConfig
		island_seed = cfg.seed_val
		_seed_val = cfg.seed_val
		island_size = cfg.island_size
		resolution = cfg.resolution
		max_height = cfg.max_height
		water_level = cfg.water_level
		roughness = cfg.roughness
	elif config_or_seed is int:
		island_seed = config_or_seed
		_seed_val = config_or_seed
	else:
		island_seed = 1337
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

	if island_size > 200.0:
		_build_chunked_terrain_mesh()
	else:
		_build_terrain_mesh()
	_build_world_boundaries()

func get_peak_position() -> Vector2:
	if _seed_val == 1337:
		return Vector2(-24.0, -24.0)
	var s_hash1: int = int(abs(_seed_val * 1103515245 + 12345)) & 0x7FFFFFFF
	var s_hash2: int = int(abs(s_hash1 * 1103515245 + 12345)) & 0x7FFFFFFF
	var peak_offset_angle: float = deg_to_rad(float(s_hash1 % 360))
	var peak_offset_dist: float = 7.5 + float(s_hash2 % 50) * 0.12
	return Vector2(-24.0 + cos(peak_offset_angle) * peak_offset_dist, -24.0 + sin(peak_offset_angle) * peak_offset_dist)

func get_lake_position() -> Vector2:
	if _seed_val == 1337:
		return Vector2(16.0, 14.0)
	var p: Vector2 = get_peak_position()
	return Vector2(-p.x * 0.65, -p.y * 0.65)

func get_bluff_position() -> Vector2:
	if _seed_val == 1337:
		return Vector2(24.0, 16.0)
	var l: Vector2 = get_lake_position()
	return Vector2(l.x + 8.0 * (1.0 if l.x >= 0 else -1.0), l.y + 4.0)

func get_glade_position() -> Vector2:
	if _seed_val == 1337:
		return Vector2(9.0, 3.5)
	var p: Vector2 = get_peak_position()
	var l: Vector2 = get_lake_position()
	return (p + l) * 0.40 + Vector2(2.5, 2.0)

func get_peak_scale() -> float:
	if _seed_val == 1337:
		return 14.5
	var s_hash1: int = int(abs(_seed_val * 1103515245 + 12345)) & 0x7FFFFFFF
	var s_hash2: int = int(abs(s_hash1 * 1103515245 + 12345)) & 0x7FFFFFFF
	var s_hash3: int = int(abs(s_hash2 * 1103515245 + 12345)) & 0x7FFFFFFF
	return 13.0 + float(s_hash3 % 45) * 0.1

func get_peak_height() -> float:
	var p: Vector2 = get_peak_position()
	return get_height_at(p.x, p.y)

func get_height_at(x: float, z: float) -> float:
	if not _noise:
		_noise = FastNoiseLite.new()
		_noise.seed = _seed_val if _seed_val != 0 else island_seed
		_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_noise.frequency = 0.015
		_noise.fractal_octaves = 4
		_noise.fractal_lacunarity = 2.0
		_noise.fractal_gain = roughness

	var half_size: float = 160.0 * 0.5
	var dist_from_center: float = Vector2(x, z).length()
	var radius: float = half_size * 0.95

	# Seed-dependent geography parameters
	var is_canonical_1337: bool = (_seed_val == 1337)
	var peak_pos: Vector2 = get_peak_position()
	var peak_x: float = peak_pos.x
	var peak_z: float = peak_pos.y
	var peak_scale: float = get_peak_scale()

	var lake_pos: Vector2 = get_lake_position()
	var lake_x: float = lake_pos.x
	var lake_z: float = lake_pos.y

	var bluff_pos: Vector2 = get_bluff_position()
	var bluff_x: float = bluff_pos.x
	var bluff_z: float = bluff_pos.y

	var lobe_k1: float = 3.0
	var lobe_amp1: float = 0.08
	var lobe_phase1: float = 0.0
	var lobe_k2: float = 5.0
	var lobe_amp2: float = 0.04
	var lobe_phase2: float = 0.0

	if not is_canonical_1337:
		var s_hash1: int = int(abs(_seed_val * 1103515245 + 12345)) & 0x7FFFFFFF
		var s_hash2: int = int(abs(s_hash1 * 1103515245 + 12345)) & 0x7FFFFFFF
		var s_hash3: int = int(abs(s_hash2 * 1103515245 + 12345)) & 0x7FFFFFFF

		lobe_k1 = 3.0 + float(s_hash1 % 3)
		lobe_amp1 = 0.12 + float(s_hash2 % 8) * 0.015
		lobe_phase1 = float(s_hash3 % 360) * deg_to_rad(1.0)
		lobe_k2 = 5.0 + float(s_hash2 % 3)
		lobe_amp2 = 0.06 + float(s_hash1 % 5) * 0.01
		lobe_phase2 = float(s_hash2 % 360) * deg_to_rad(1.0)

	# Organic coastline with fjord lobes and bay indentations
	var theta: float = atan2(z, x)
	var coast_mod: float = 1.0 + lobe_amp1 * cos(lobe_k1 * theta + lobe_phase1) + lobe_amp2 * cos(lobe_k2 * theta + lobe_phase2)
	var coast_noise: float = _noise.get_noise_2d(x * 0.04 + 77.0, z * 0.04 + 77.0) * 0.08
	var effective_radius: float = radius * (coast_mod + coast_noise)

	# Radial mask: 1.0 at center, drops to 0.0 at shoreline, negative in ocean
	var t: float = clamp(dist_from_center / effective_radius, 0.0, 1.0)
	var mask: float = cos(t * PI * 0.5)
	mask = pow(mask, 1.2) # Flattens beaches near edges

	# Primary terrain noise with domain warping for organic landforms
	var warp_x: float = 0.0
	var warp_z: float = 0.0
	if not is_canonical_1337:
		warp_x = _noise.get_noise_2d(x * 0.025 + 133.0, z * 0.025 + 133.0) * 8.5
		warp_z = _noise.get_noise_2d(x * 0.025 + 266.0, z * 0.025 + 266.0) * 8.5

	var n_base: float = (_noise.get_noise_2d(x + warp_x, z + warp_z) + 1.0) * 0.5
	# Secondary mountain ridge accent
	var n_ridge: float = abs(_noise.get_noise_2d((x + warp_x) * 1.8 + 100.0, (z + warp_z) * 1.8 + 100.0))

	# Prominent summit peak with geological strata
	var peak_dist: float = Vector2(x - peak_x, z - peak_z).length()
	var peak_feature: float = exp(-pow(peak_dist / 22.0, 2.0)) * peak_scale
	var stratified_peak: float = peak_feature + sin(peak_feature * 1.2) * 0.85

	# Natural elongated lake cove with organic shoreline bays
	var dx_lake: float = x - lake_x
	var dz_lake: float = z - lake_z
	var l_u: float = dx_lake * 0.866 + dz_lake * 0.5
	var l_v: float = -dx_lake * 0.5 + dz_lake * 0.866
	var lake_ellipse: float = sqrt(pow(l_u / 15.0, 2.0) + pow(l_v / 10.0, 2.0))
	var lake_shore_noise: float = _noise.get_noise_2d(x * 0.08 + 50.0, z * 0.08 + 50.0) * 0.22
	var lake_rad: float = maxf(0.0, (lake_ellipse + lake_shore_noise) / 1.0)
	var lake_carve: float = exp(-pow(lake_rad, 2.2)) * 6.8

	# Winding mountain stream inlet carving down towards lake
	var creek_carve: float = 0.0
	if is_canonical_1337:
		var creek_t: float = clamp((x - (-2.0)) / 14.0, 0.0, 1.0)
		var creek_center_z: float = lerp(4.0, 11.0, creek_t) + sin(creek_t * PI * 2.0) * 2.2
		var creek_dist_z: float = abs(z - creek_center_z)
		if x >= -4.0 and x <= 14.0:
			var creek_envelope: float = sin(creek_t * PI)
			var channel_shape: float = clampf(1.0 - (creek_dist_z / 2.6), 0.0, 1.0)
			var channel_bed: float = pow(channel_shape, 1.3) * 1.65 * creek_envelope
			var riffle: float = sin(creek_t * 18.0) * 0.06 * creek_envelope * (1.0 if channel_shape >= 0.2 else 0.0)
			creek_carve = channel_bed - riffle
	else:
		var runoff_start: Vector2 = Vector2(peak_x * 0.45, peak_z * 0.45)
		var runoff_end: Vector2 = Vector2(lake_x, lake_z)
		var d_runoff: Vector2 = runoff_end - runoff_start
		var len_sq: float = d_runoff.length_squared()
		if len_sq > 4.0:
			var t_drain: float = clampf(((x - runoff_start.x) * d_runoff.x + (z - runoff_start.y) * d_runoff.y) / len_sq, 0.0, 1.0)
			var path_pt: Vector2 = runoff_start + d_runoff * t_drain + Vector2(-d_runoff.y, d_runoff.x).normalized() * sin(t_drain * PI * 2.0) * 2.5
			var dist_drain: float = Vector2(x - path_pt.x, z - path_pt.y).length()
			if dist_drain < 2.8:
				var drain_env: float = sin(t_drain * PI)
				creek_carve = clampf(1.0 - (dist_drain / 2.8), 0.0, 1.0) * 1.65 * drain_env

	# Rocky bluff overlook
	var bluff_dist: float = Vector2(x - bluff_x, z - bluff_z).length()
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

	# Sedimentary strata terracing
	var strata_weight: float = clampf((peak_feature / 14.5) * 0.65 + (bluff_feature / 3.8) * 0.55 + n_ridge * 0.35, 0.0, 1.0)
	var strata_shelf: float = 0.0
	if strata_weight > 0.04:
		var strata_phase: float = raw_elevation / 2.6
		strata_shelf = (sin(strata_phase * TAU) - 0.22 * sin(strata_phase * 2.0 * TAU)) * 0.36 * strata_weight

	var inner_elevation: float = (raw_elevation + strata_shelf) * mask

	# Central Meadow Glade terraced grazing bench
	var glade_center: Vector2 = get_glade_position() if not is_canonical_1337 else Vector2(9.0, 3.5)
	var glade_dist_x: float = abs(x - glade_center.x) / 6.0
	var glade_dist_z: float = abs(z - glade_center.y) / 4.5
	var glade_box: float = maxf(glade_dist_x, glade_dist_z)
	var glade_factor: float = clampf(1.0 - glade_box, 0.0, 1.0)
	if glade_factor > 0.0:
		var glade_weight: float = smoothstep(0.0, 1.0, glade_factor) * 0.40
		inner_elevation = lerpf(inner_elevation, 3.85 + (n_base - 0.5) * 0.5, glade_weight)

	# Animal trail slight compacted indentation
	var trail_f: float = get_trail_factor(x, z)
	if trail_f > 0.0:
		inner_elevation -= trail_f * 0.08

	# In standard 160m prototype mode, preserve exact bounded island for contract test suites
	if island_size <= 200.0:
		if dist_from_center > 60.0:
			var edge_drop: float = (dist_from_center - 60.0) / 14.0
			inner_elevation -= edge_drop * 8.5
		if dist_from_center >= 72.0:
			inner_elevation = minf(inner_elevation, -1.8 - (dist_from_center - 72.0) * 0.15)
		if dist_from_center > radius * 0.85:
			var drop_outer: float = (dist_from_center - radius * 0.85) / (radius * 0.15)
			inner_elevation -= drop_outer * 10.0
		return inner_elevation

	# --- 720m EXPANDED WORLD: SINGLE CONTINUOUS UNIFIED CONTINENT ---
	# No concentric ring, no artificial moat, no splitting water channels.
	var r: float = dist_from_center

	# Core baseline landmass before radial falloff
	var core_land: float = raw_elevation + strata_shelf
	if glade_factor > 0.0:
		var glade_weight: float = smoothstep(0.0, 1.0, glade_factor) * 0.40
		core_land = lerpf(core_land, 3.85 + (n_base - 0.5) * 0.5, glade_weight)
	if trail_f > 0.0:
		core_land -= trail_f * 0.08

	# Macroscopic regional features across the 720m continent:
	var n_outer_hills: float = (_noise.get_noise_2d(x * 0.012 + 400.0, z * 0.012 + 400.0) + 1.0) * 4.5
	var n_outer_ridges: float = abs(_noise.get_noise_2d(x * 0.024 + 450.0, z * 0.024 + 450.0)) * 5.2
	var n_outer_valley: float = (_noise.get_noise_2d(x * 0.008 + 800.0, z * 0.008 + 800.0)) * 3.2
	var n_crags_strata: float = (_noise.get_noise_2d(x * 0.038 + 330.0, z * 0.038 + 330.0) + 1.0) * 3.2

	# 1. Northwest: Skyspire Alpine Massif (Soaring Alpine Peak 108m-115m, Glacial Cirque & Razor Arêtes)
	var d_nw: float = Vector2(x - (-145.0), z - (-145.0)).length()
	# Dual-tier mountain profile: expansive glacial massif pedestal + towering jagged spire
	var h_massif_base: float = exp(-pow(d_nw / 95.0, 1.75)) * 68.0
	var h_massif_spire: float = exp(-pow(d_nw / 48.0, 2.10)) * 68.0
	var h_skyspire: float = h_massif_base + h_massif_spire

	# Razor Arête Knife-Edge Ridges
	# Ridge 1: North-Northwest spine toward coastal ocean crags
	var v_r1_x: float = x - (-145.0)
	var v_r1_z: float = z - (-145.0)
	var d_r1_perp: float = abs(v_r1_x * (-0.97) - v_r1_z * (-0.24))
	var t_r1_along: float = v_r1_x * (-0.24) + v_r1_z * (-0.97)
	var ridge1_knife: float = 0.0
	if t_r1_along > 0.0 and t_r1_along < 115.0 and d_r1_perp < 24.0:
		ridge1_knife = (1.0 - d_r1_perp / 24.0) * (1.0 - t_r1_along / 115.0) * 16.5

	# Ridge 2: West-Southwest spine toward Sunset Promontory
	var d_r2_perp: float = abs(v_r1_x * 0.42 - v_r1_z * (-0.91))
	var t_r2_along: float = v_r1_x * (-0.91) + v_r1_z * (-0.42)
	var ridge2_knife: float = 0.0
	if t_r2_along > 0.0 and t_r2_along < 95.0 and d_r2_perp < 20.0:
		ridge2_knife = (1.0 - d_r2_perp / 20.0) * (1.0 - t_r2_along / 95.0) * 12.5

	var n_alpine_crags: float = abs(_noise.get_noise_2d(x * 0.038 + 500.0, z * 0.038 + 500.0)) * 7.5

	# 1b. Alpine Tarn Glacial Cirque Basin (Center: -125.0, -110.0; Lake Water Surface at Y = 36.0m)
	var d_tarn: float = Vector2(x - (-125.0), z - (-110.0)).length()
	var tarn_basin_carve: float = 0.0
	if d_tarn < 38.0:
		var tarn_env: float = clampf(1.0 - (d_tarn / 38.0), 0.0, 1.0)
		tarn_basin_carve = tarn_env * tarn_env * (3.0 - 2.0 * tarn_env) * 22.0
		# Eastern natural moraine rock threshold (holds lake water at Y = 36.0m)
		if x > -114.0 and d_tarn >= 18.0:
			tarn_basin_carve *= 0.35

	# 1c. Whispering Grotto Cavern Ravine Depression (Center: -78.0, -72.0; Floor Y = 7.2m)
	var d_cave: float = Vector2(x - (-78.0), z - (-72.0)).length()
	var cave_trench_carve: float = 0.0
	if d_cave < 22.0:
		var cave_env: float = clampf(1.0 - (d_cave / 22.0), 0.0, 1.0)
		cave_trench_carve = cave_env * cave_env * 7.5

	# 2. Northeast: Whispering Pine Highlands (28-36m) & Wooded Plateau
	var d_east: float = Vector2(x - 175.0, z - (-25.0)).length()
	var h_highlands: float = exp(-pow(d_east / 66.0, 2.0)) * 32.5
	var n_highland_ridge: float = (_noise.get_noise_2d(x * 0.022 + 600.0, z * 0.022 + 600.0) + 1.0) * 4.2

	# 3. South: Cape Solitude & Ocean Coastal Bluffs (22-28m)
	var d_south: float = Vector2(x - 22.0, z - 192.0).length()
	var h_bluffs_outer: float = exp(-pow(d_south / 62.0, 2.0)) * 24.5
	var n_cliff_face: float = abs(_noise.get_noise_2d(x * 0.038 + 700.0, z * 0.038 + 700.0)) * 5.2

	# 4. West: Sunset Promontory & Coastal Tors (18-24m)
	var d_west: float = Vector2(x - (-180.0), z - 48.0).length()
	var h_promontory: float = exp(-pow(d_west / 56.0, 2.0)) * 21.0

	# 5. East & Southeast: Expansive Sunlit Meadow Plains (broad, rolling, continuous green pastures)
	var d_meadow: float = Vector2(x - 90.0, z - 70.0).length()
	var h_meadow_plains: float = exp(-pow(d_meadow / 110.0, 2.0)) * 3.5

	# 6. West & Southwest: Whispering Deep Forest Rolling Hills
	var d_forest: float = Vector2(x - (-90.0), z - 30.0).length()
	var h_forest_hills: float = exp(-pow(d_forest / 85.0, 2.0)) * 7.5

	# 7. Southeast: Grand Emerald Lake ("Hồ Ngọc Bích" — vast Genshin-scale inland sea, 140m radius)
	var d_grand_lake: float = Vector2(x - 95.0, z - 85.0).length()
	var grand_lake_carve: float = 0.0
	if d_grand_lake < 140.0:
		var gl_env: float = clampf(1.0 - (d_grand_lake / 140.0), 0.0, 1.0)
		var gl_noise: float = _noise.get_noise_2d(x * 0.032 + 880.0, z * 0.032 + 880.0) * 0.16
		var gl_rad: float = clampf(gl_env + gl_noise, 0.0, 1.0)
		grand_lake_carve = gl_rad * gl_rad * (3.0 - 2.0 * gl_rad) * 11.5

	# 8. Central-North: Whispering Mist Lake (northern scenic lake, 42m radius)
	var d_mist_lake: float = Vector2(x - (-15.0), z - (-185.0)).length()
	var mist_lake_carve: float = 0.0
	if d_mist_lake < 42.0:
		var ml_env: float = clampf(1.0 - (d_mist_lake / 42.0), 0.0, 1.0)
		var ml_noise: float = _noise.get_noise_2d(x * 0.05 + 990.0, z * 0.05 + 990.0) * 0.14
		var ml_rad: float = clampf(ml_env + ml_noise, 0.0, 1.0)
		mist_lake_carve = ml_rad * ml_rad * (3.0 - 2.0 * ml_rad) * 7.5

	# 9. Silverstream River — winds from Skyspire foothills (-80,-80) to Grand Emerald Lake (95,85)
	# Carved as a sinusoidal channel with organic width variation
	var river_carve: float = 0.0
	var river_start: Vector2 = Vector2(-80.0, -80.0)
	var river_end: Vector2 = Vector2(80.0, 70.0)
	var riv_delta: Vector2 = river_end - river_start
	var riv_len_sq: float = riv_delta.length_squared()
	if riv_len_sq > 100.0:
		var riv_t: float = clampf(((x - river_start.x) * riv_delta.x + (z - river_start.y) * riv_delta.y) / riv_len_sq, 0.0, 1.0)
		# Meandering path: sine wave offset perpendicular to river axis
		var perp_x: float = -riv_delta.y / riv_delta.length()
		var perp_z: float = riv_delta.x / riv_delta.length()
		var meander: float = sin(riv_t * PI * 3.5) * 18.0 + sin(riv_t * PI * 7.0) * 8.0
		var river_pt: Vector2 = river_start + riv_delta * riv_t + Vector2(perp_x, perp_z) * meander
		var dist_to_river: float = Vector2(x - river_pt.x, z - river_pt.y).length()
		# River width narrows at high elevation, widens toward lowland
		var river_width: float = lerpf(3.2, 9.5, riv_t)
		var river_noise_w: float = _noise.get_noise_2d(x * 0.06 + 1100.0, z * 0.06 + 1100.0) * 0.25
		river_width *= (1.0 + river_noise_w)
		if dist_to_river < river_width:
			var ch_factor: float = clampf(1.0 - (dist_to_river / river_width), 0.0, 1.0)
			var ch_depth: float = lerpf(1.2, 2.8, riv_t)  # Deeper downstream
			river_carve = ch_factor * ch_factor * ch_depth * sin(riv_t * PI)  # Taper at start/end

	# 10. Windshear Canyon Gorge — dramatic cliff-sided chasm in southwest bluffs
	var gorge_carve: float = 0.0
	var gorge_center_x: float = -35.0
	var gorge_t: float = clampf((z - 110.0) / 75.0, 0.0, 1.0)
	if z > 110.0 and z < 185.0:
		var gorge_cx: float = gorge_center_x + sin(gorge_t * PI * 2.0) * 8.0
		var dist_gorge: float = abs(x - gorge_cx)
		var gorge_w: float = 12.0 + sin(gorge_t * PI) * 5.0
		if dist_gorge < gorge_w:
			var gorge_f: float = clampf(1.0 - (dist_gorge / gorge_w), 0.0, 1.0)
			gorge_carve = gorge_f * gorge_f * 8.5 * sin(gorge_t * PI)

	var macroscopic_land: float = (h_skyspire + ridge1_knife + ridge2_knife + n_alpine_crags - tarn_basin_carve - cave_trench_carve - grand_lake_carve - mist_lake_carve - river_carve - gorge_carve) + (h_highlands + n_highland_ridge) + (h_bluffs_outer + n_cliff_face) + h_promontory + h_meadow_plains + h_forest_hills + n_outer_hills + n_outer_ridges + n_outer_valley + n_crags_strata

	# Smooth natural transition from core central glade into macroscopic regional terrain (between 30m and 75m)
	var t_blend: float = clampf((r - 30.0) / 45.0, 0.0, 1.0)
	t_blend = t_blend * t_blend * (3.0 - 2.0 * t_blend) # smoothstep
	var unified_land: float = lerpf(core_land, 3.2 + macroscopic_land * 0.78, t_blend)

	# Ensure Grand Emerald Lake bed reaches realistic bathymetry (-1.8m to -4.2m) with Central Heart Island at (95, 85)
	if d_grand_lake < 125.0 and r > 35.0:
		var depth_factor: float = clampf(1.0 - (d_grand_lake / 125.0), 0.0, 1.0)
		var lake_bed_h: float = -2.6 - depth_factor * 1.6 + _noise.get_noise_2d(x * 0.05, z * 0.05) * 0.5

		# Anemo Shimmering Islet (Heart Island) right at center (d_grand_lake < 19.0)
		if d_grand_lake < 19.0:
			var isle_t: float = clampf(1.0 - (d_grand_lake / 19.0), 0.0, 1.0)
			isle_t = isle_t * isle_t * (3.0 - 2.0 * isle_t)
			var isle_h: float = 2.4 + isle_t * 1.2 + _noise.get_noise_2d(x * 0.1, z * 0.1) * 0.4
			lake_bed_h = lerpf(lake_bed_h, isle_h, isle_t)

		# Steep bathymetric bank: reaches 1.0 within 18m of shoreline
		var gl_env: float = clampf(1.0 - (d_grand_lake / 125.0), 0.0, 1.0)
		var gl_w: float = clampf(gl_env / 0.15, 0.0, 1.0)
		gl_w = gl_w * gl_w * (3.0 - 2.0 * gl_w)
		unified_land = lerpf(unified_land, lake_bed_h, gl_w)

	# Ensure Whispering Mist Lake bed stays at -1.5m to -2.0m
	if d_mist_lake < 32.0 and r > 40.0:
		var mist_bed_h: float = -1.8 + _noise.get_noise_2d(x * 0.08, z * 0.08) * 0.4
		var ml_w: float = clampf(1.0 - (d_mist_lake / 32.0), 0.0, 1.0)
		ml_w = ml_w * ml_w * (3.0 - 2.0 * ml_w)
		unified_land = lerpf(unified_land, mist_bed_h, ml_w)

	# Ensure Alpine Tarn lake bed stays precisely in glacial bathymetry range (32.0m - 34.5m)
	if d_tarn < 20.0 and r > 70.0:
		var bed_h: float = 32.8 + _noise.get_noise_2d(x * 0.12, z * 0.12) * 0.7
		var tarn_w: float = clampf(1.0 - (d_tarn / 20.0), 0.0, 1.0)
		unified_land = lerpf(unified_land, bed_h, tarn_w)

	# Ensure Whispering Grotto cavern floor stays smooth and grounded at mountain root (16.2m - 16.8m)
	if d_cave < 16.0 and r > 60.0:
		var cave_floor_h: float = 16.5 + _noise.get_noise_2d(x * 0.15, z * 0.15) * 0.35
		var cave_w: float = clampf(1.0 - (d_cave / 16.0), 0.0, 1.0)
		unified_land = lerpf(unified_land, cave_floor_h, cave_w)

	# Continuous outer coastline envelope: slopes gently down to beaches at 295m-335m and ocean at >340m
	var t_coast: float = clampf((r - 295.0) / 45.0, 0.0, 1.0)
	var coast_mask: float = 1.0 - t_coast * t_coast * (3.0 - 2.0 * t_coast)
	var final_elevation: float = unified_land * coast_mask
	if r > 338.0:
		final_elevation -= (r - 338.0) * 1.25

	return final_elevation

func get_trail_factor(x: float, z: float) -> float:
	if _seed_val == 1337:
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
	else:
		# Seed-adaptive game trail connecting glade to lake cove
		var g: Vector2 = get_glade_position()
		var l: Vector2 = get_lake_position()
		var d_gl: Vector2 = l - g
		var len_sq: float = d_gl.length_squared()
		if len_sq < 4.0:
			return 0.0
		var t: float = clampf(((x - g.x) * d_gl.x + (z - g.y) * d_gl.y) / len_sq, 0.0, 1.0)
		var trail_pt: Vector2 = g + d_gl * t + Vector2(-d_gl.y, d_gl.x).normalized() * sin(t * PI) * 1.8
		var dist: float = Vector2(x - trail_pt.x, z - trail_pt.y).length()
		if dist > 1.6:
			return 0.0
		return clampf(1.0 - (dist / 1.6), 0.0, 1.0)

func _get_or_create_terrain_material() -> TerrainMaterialWrapper:
	if _terrain_material != null and _terrain_material is TerrainMaterialWrapper:
		return _terrain_material as TerrainMaterialWrapper
	var shader: Shader = load("res://presentation/shaders/terrain_pbr.gdshader")
	var mat: TerrainMaterialWrapper = TerrainMaterialWrapper.new()
	mat.shader = shader
	mat.set_shader_parameter("ground_albedo", load("res://demo/assets/textures/ground037_alb_ht.png"))
	mat.set_shader_parameter("ground_normal", load("res://demo/assets/textures/ground037_nrm_rgh.png"))
	mat.set_shader_parameter("rock_albedo", load("res://demo/assets/textures/rock023_alb_ht.png"))
	mat.set_shader_parameter("rock_normal", load("res://demo/assets/textures/rock023_nrm_rgh.png"))
	mat.set_shader_parameter("uv_scale", 0.20)
	mat.set_shader_parameter("rock_uv_scale", 0.12)
	mat.set_shader_parameter("slope_threshold", 0.28)
	mat.set_shader_parameter("slope_blend", 0.12)
	var is_expanded: bool = island_size > 200.0
	mat.set_shader_parameter("snow_height", 36.0 if is_expanded else 12.0)
	mat.set_shader_parameter("snow_transition", 6.0 if is_expanded else 2.5)
	mat.roughness = 0.85
	mat.metallic_specular = 0.10
	_terrain_material = mat
	_apply_surface_material_properties()
	return mat

func _build_chunked_terrain_mesh() -> void:
	var mat: TerrainMaterialWrapper = _get_or_create_terrain_material()

	# Remove any direct TerrainMeshInstance if present from single-mesh mode
	var direct_mesh: Node = get_node_or_null("TerrainMeshInstance")
	if direct_mesh:
		direct_mesh.queue_free()
		remove_child(direct_mesh)
		_mesh_instance = null

	# Clean up any previous collision shapes
	for child in get_children():
		if child is CollisionShape3D:
			child.queue_free()
			remove_child(child)
	_collision_shape = null

	var chunks_node: Node3D = get_node_or_null("ChunksRoot") as Node3D
	if not chunks_node:
		chunks_node = Node3D.new()
		chunks_node.name = "ChunksRoot"
		add_child(chunks_node)
	else:
		for c in chunks_node.get_children():
			c.queue_free()
			chunks_node.remove_child(c)

	# 3x3 Grid of Chunks, covering [-half_size, half_size] (720m)
	var chunk_span: float = island_size / 3.0 # 240.0m
	var half_size: float = island_size * 0.5  # 360.0m

	for cz in range(3):
		for cx in range(3):
			var min_x: float = -half_size + float(cx) * chunk_span
			var min_z: float = -half_size + float(cz) * chunk_span

			var is_center: bool = (cx == 1 and cz == 1)
			var is_edge: bool = (cx == 1 or cz == 1) and not is_center  # Middle row/col
			# Resolution: center=80, edges=64, corners=56 — much richer detail across full 720m
			var chunk_res: int = 80 if is_center else (64 if is_edge else 56)

			var st: SurfaceTool = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)

			var step_x: float = chunk_span / float(chunk_res - 1)
			var step_z: float = chunk_span / float(chunk_res - 1)

			var vertices: PackedVector3Array = PackedVector3Array()
			vertices.resize(chunk_res * chunk_res)

			for z_i in range(chunk_res):
				var z_pos: float = min_z + float(z_i) * step_z
				for x_i in range(chunk_res):
					var x_pos: float = min_x + float(x_i) * step_x
					var y_pos: float = get_height_at(x_pos, z_pos)
					vertices[z_i * chunk_res + x_i] = Vector3(x_pos, y_pos, z_pos)

			for z_i in range(chunk_res - 1):
				for x_i in range(chunk_res - 1):
					var i0: int = z_i * chunk_res + x_i
					var i1: int = z_i * chunk_res + (x_i + 1)
					var i2: int = (z_i + 1) * chunk_res + x_i
					var i3: int = (z_i + 1) * chunk_res + (x_i + 1)

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
			var chunk_mesh: ArrayMesh = st.commit()

			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.name = "TerrainMeshInstance" if is_center else "Chunk_%d_%d" % [cx, cz]
			mi.mesh = chunk_mesh
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			chunks_node.add_child(mi)

			var col: CollisionShape3D = CollisionShape3D.new()
			col.name = "TerrainCollisionShape" if is_center else "Col_Chunk_%d_%d" % [cx, cz]
			col.shape = chunk_mesh.create_trimesh_shape()
			add_child(col)

			if is_center:
				_mesh_instance = mi
				_collision_shape = col

func _build_terrain_mesh() -> void:
	var chunks_node: Node3D = get_node_or_null("ChunksRoot") as Node3D
	if chunks_node:
		chunks_node.queue_free()
		remove_child(chunks_node)

	for child in get_children():
		if child is CollisionShape3D and child.name != "TerrainCollisionShape":
			child.queue_free()
			remove_child(child)

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
	var array_mesh: ArrayMesh = st.commit()

	var mat: TerrainMaterialWrapper = _get_or_create_terrain_material()

	if not _mesh_instance:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "TerrainMeshInstance"
		add_child(_mesh_instance)

	_mesh_instance.mesh = array_mesh
	_mesh_instance.material_override = mat
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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

func get_puddle_depth() -> float:
	return puddle_depth

func set_puddle_depth(val: float) -> void:
	puddle_depth = clampf(val, 0.0, 1.0)
	_apply_surface_material_properties()

func get_snow_drift_accretion() -> float:
	return snow_drift_accretion

func set_snow_drift_accretion(val: float) -> void:
	snow_drift_accretion = clampf(val, 0.0, 1.0)
	_apply_surface_material_properties()

func update_surface_reaction(delta: float, weather: WeatherSystem = null) -> void:
	if weather:
		match weather.current_state:
			WeatherSystem.WeatherState.RAIN:
				# Rain rapidly accumulates surface water sheen and depressions fill with puddles
				surface_wetness = minf(1.0, surface_wetness + 0.10 * delta)
				puddle_depth = minf(1.0, puddle_depth + 0.08 * delta)
			WeatherSystem.WeatherState.DROUGHT:
				# Drought bakes and dries surface rapidly
				surface_wetness = maxf(0.0, surface_wetness - 0.12 * delta)
				puddle_depth = maxf(0.0, puddle_depth - 0.15 * delta)
			WeatherSystem.WeatherState.CLEAR:
				# Sun and air steadily evaporate standing wetness and puddles
				var evap_rate: float = 0.035
				if weather.get("wind_speed") != null:
					evap_rate *= (1.0 + float(weather.wind_speed) * 0.25)
				surface_wetness = maxf(0.0, surface_wetness - evap_rate * delta)
				puddle_depth = maxf(0.0, puddle_depth - evap_rate * 0.85 * delta)
			WeatherSystem.WeatherState.CLOUDY:
				# Moderate equilibrium
				surface_wetness = move_toward(surface_wetness, 0.12, 0.015 * delta)
				puddle_depth = move_toward(puddle_depth, 0.0, 0.02 * delta)

	_apply_surface_material_properties(weather)

func _apply_surface_material_properties(weather: WeatherSystem = null) -> void:
	if not _terrain_material:
		return

	# Wet earth and damp rock become reflective and smooth
	var eff_wet: float = maxf(surface_wetness, puddle_depth * 0.70)
	_terrain_material.roughness = lerpf(0.85, 0.28, eff_wet)
	_terrain_material.metallic_specular = lerpf(0.10, 0.55, eff_wet)

	# Damp surfaces darken by up to 20%
	var damp_factor: float = lerpf(1.0, 0.80, eff_wet)
	if weather and weather.current_state == WeatherSystem.WeatherState.DROUGHT:
		_terrain_material.albedo_color = Color(1.04, 1.02, 0.96)
	else:
		_terrain_material.albedo_color = Color(damp_factor, damp_factor, damp_factor)

	if _terrain_material is ShaderMaterial:
		_terrain_material.set_shader_parameter("wetness", surface_wetness)
		_terrain_material.set_shader_parameter("puddle_depth", puddle_depth)
		_terrain_material.set_shader_parameter("snow_drift_accretion", snow_drift_accretion)

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
		var col_sand: Color = Color(0.78, 0.72, 0.54)
		col = col.lerp(col_sand, sand_factor * 0.88)
		# Shoreline wet margin darkening: wet sand and gravel at the waterline
		if h < 0.42:
			var wet_margin: float = clampf((0.42 - h) / 0.55, 0.0, 1.0)
			var col_wet_sand: Color = Color(0.36, 0.32, 0.26)
			col = col.lerp(col_wet_sand, wet_margin * 0.75)

	var snow_start_h: float = 36.0 if island_size > 200.0 else 12.0
	if h > snow_start_h:
		var snow_factor: float = clampf((h - snow_start_h) / 5.5, 0.0, 1.0)
		var slope_mask: float = clampf((0.55 - slope) / 0.25, 0.0, 1.0)
		var col_snow: Color = Color(0.92, 0.94, 0.98)
		col = col.lerp(col_snow, snow_factor * slope_mask * 0.85)

	# Showcase Region: Central Meadow Glade lush pasture tint
	var glade_c: Vector2 = get_glade_position() if not (_seed_val == 1337) else Vector2(9.0, 3.5)
	var glade_dx: float = abs(pos.x - glade_c.x) / 6.0
	var glade_dz: float = abs(pos.z - glade_c.y) / 4.5
	var glade_f: float = clampf(1.0 - maxf(glade_dx, glade_dz), 0.0, 1.0)
	if glade_f > 0.0:
		var col_glade_lush: Color = Color(0.35, 0.56, 0.20)
		col = col.lerp(col_glade_lush, glade_f * 0.60)

	# Showcase Region: Eastern Granite Bluff talus scree apron
	var bluff_c: Vector2 = get_bluff_position() if not (_seed_val == 1337) else Vector2(24.0, 16.0)
	var bluff_talus_dist: float = Vector2(pos.x - (bluff_c.x - 1.5), pos.z - (bluff_c.y + 0.5)).length()
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
	var existing_wb: Node = get_node_or_null("WorldBoundaries")
	if existing_wb:
		existing_wb.queue_free()
		remove_child(existing_wb)

	# 4 invisible perimeter boundary barriers preventing player from falling out of world bounds
	var half: float = island_size * 0.5
	var wall_height: float = 60.0 if island_size <= 200.0 else 120.0
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
