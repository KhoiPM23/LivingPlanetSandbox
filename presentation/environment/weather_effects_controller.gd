class_name WeatherEffectsController
extends Node3D

## Coordinates weather presentation effects, precipitation particles (rain & alpine snow flurries),
## wind-coupled foliage and ocean shaders, atmospheric fog, and surface reactions.
## Referenced as AtmosphereDirector module for Living Planet Sandbox.

var _weather: WeatherSystem
var _terrain: IslandTerrain
var _water: WaterPlane
var _scatter: VegetationScatter
var _camera: Camera3D
var _world_env: WorldEnvironment
var _sun: DirectionalLight3D

var _rain_particles: CPUParticles3D
var _snow_particles: CPUParticles3D
var _spindrift_particles: CPUParticles3D
var _firefly_particles: CPUParticles3D

var _last_eff_wind: float = -999.0
var _last_wind_dir: Vector2 = Vector2(-999.0, -999.0)
var _last_surf_wetness: float = -999.0

func setup(
	weather: WeatherSystem,
	terrain: IslandTerrain,
	water: WaterPlane = null,
	scatter: VegetationScatter = null,
	camera: Camera3D = null,
	env: WorldEnvironment = null,
	sun: DirectionalLight3D = null
) -> void:
	_weather = weather
	_terrain = terrain
	_water = water
	_scatter = scatter
	_camera = camera
	_world_env = env
	_sun = sun

	_setup_rain_particles()
	_setup_snow_particles()
	_setup_spindrift_particles()
	_setup_firefly_particles()

func _setup_rain_particles() -> void:
	if _rain_particles:
		return

	_rain_particles = CPUParticles3D.new()
	_rain_particles.name = "RainParticles"
	_rain_particles.amount = 250
	_rain_particles.lifetime = 1.4
	_rain_particles.preprocess = 0.3
	_rain_particles.emitting = false
	_rain_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain_particles.emission_box_extents = Vector3(28.0, 3.0, 28.0)
	_rain_particles.direction = Vector3(0.0, -1.0, 0.0)
	_rain_particles.spread = 6.0
	_rain_particles.initial_velocity_min = 18.0
	_rain_particles.initial_velocity_max = 24.0

	# Draw pass mesh: Slender unshaded raindrop streak
	var streak_mesh: BoxMesh = BoxMesh.new()
	streak_mesh.size = Vector3(0.025, 0.55, 0.025)

	var streak_mat: StandardMaterial3D = StandardMaterial3D.new()
	streak_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	streak_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	streak_mat.albedo_color = Color(0.72, 0.85, 0.98, 0.42)

	streak_mesh.material = streak_mat
	_rain_particles.mesh = streak_mesh

	add_child(_rain_particles)

func _setup_snow_particles() -> void:
	if _snow_particles:
		return

	_snow_particles = CPUParticles3D.new()
	_snow_particles.name = "SnowParticles"
	_snow_particles.amount = 90
	_snow_particles.lifetime = 2.8
	_snow_particles.preprocess = 0.4
	_snow_particles.emitting = false
	_snow_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_snow_particles.emission_box_extents = Vector3(24.0, 3.0, 24.0)
	_snow_particles.direction = Vector3(0.0, -1.0, 0.0)
	_snow_particles.spread = 22.0
	_snow_particles.initial_velocity_min = 2.0
	_snow_particles.initial_velocity_max = 3.6
	_snow_particles.gravity = Vector3(0.0, -1.2, 0.0)

	var flake_mesh: BoxMesh = BoxMesh.new()
	flake_mesh.size = Vector3(0.045, 0.045, 0.045)

	var flake_mat: StandardMaterial3D = StandardMaterial3D.new()
	flake_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	flake_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	flake_mat.albedo_color = Color(0.95, 0.96, 1.0, 0.85)

	flake_mesh.material = flake_mat
	_snow_particles.mesh = flake_mesh

	add_child(_snow_particles)

func _setup_spindrift_particles() -> void:
	if _spindrift_particles:
		return

	_spindrift_particles = CPUParticles3D.new()
	_spindrift_particles.name = "SummitSpindriftParticles"
	_spindrift_particles.amount = 110
	_spindrift_particles.lifetime = 1.8
	_spindrift_particles.preprocess = 0.4
	_spindrift_particles.emitting = false
	_spindrift_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_spindrift_particles.emission_box_extents = Vector3(22.0, 3.0, 22.0)
	_spindrift_particles.direction = Vector3(1.0, -0.15, 0.0)
	_spindrift_particles.spread = 15.0
	_spindrift_particles.initial_velocity_min = 7.5
	_spindrift_particles.initial_velocity_max = 14.0
	_spindrift_particles.gravity = Vector3(0.0, -0.8, 0.0)

	var s_mesh: BoxMesh = BoxMesh.new()
	s_mesh.size = Vector3(0.045, 0.045, 0.045)

	var s_mat: StandardMaterial3D = StandardMaterial3D.new()
	s_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	s_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	s_mat.albedo_color = Color(0.96, 0.98, 1.0, 0.82)
	s_mesh.material = s_mat
	_spindrift_particles.mesh = s_mesh

	add_child(_spindrift_particles)

func _setup_firefly_particles() -> void:
	if _firefly_particles:
		return

	_firefly_particles = CPUParticles3D.new()
	_firefly_particles.name = "ForestFireflies"
	_firefly_particles.amount = 35
	_firefly_particles.lifetime = 3.6
	_firefly_particles.preprocess = 0.5
	_firefly_particles.emitting = false
	_firefly_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_firefly_particles.emission_box_extents = Vector3(18.0, 2.5, 18.0)
	_firefly_particles.direction = Vector3(0.0, 1.0, 0.0)
	_firefly_particles.spread = 180.0
	_firefly_particles.initial_velocity_min = 0.15
	_firefly_particles.initial_velocity_max = 0.55
	_firefly_particles.gravity = Vector3(0.0, 0.02, 0.0)

	var f_mesh: SphereMesh = SphereMesh.new()
	f_mesh.radius = 0.05
	f_mesh.height = 0.10

	var f_mat: StandardMaterial3D = StandardMaterial3D.new()
	f_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	f_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	f_mat.albedo_color = Color(0.95, 0.88, 0.25, 0.90)
	f_mesh.material = f_mat
	_firefly_particles.mesh = f_mesh

	add_child(_firefly_particles)

func _process(delta: float) -> void:
	if not _weather:
		return

	var is_precipitating: bool = (_weather.current_state == WeatherSystem.WeatherState.RAIN)
	var wind_dir: Vector2 = _weather.get_wind_direction()
	var eff_wind: float = _weather.get_effective_wind_speed()

	# Check alpine freezing condition for conditional snow flurries (summit snowline is >= 11.0m)
	var is_alpine_cold: bool = false
	if _camera and is_instance_valid(_camera):
		var cam_pos: Vector3 = _camera.global_position if _camera.is_inside_tree() else _camera.position
		if cam_pos.y >= 11.0:
			is_alpine_cold = true
		elif _terrain and _terrain._env_grid:
			var env_data: Dictionary = _terrain._env_grid.get_environment_at(cam_pos.x, cam_pos.z)
			if float(env_data.get("temperature", 20.0)) <= 2.0:
				is_alpine_cold = true

	# 1. Update Rain & Snow Particles (Camera Centered Volume)
	if _rain_particles:
		var should_rain: bool = is_precipitating and not is_alpine_cold
		if _rain_particles.emitting != should_rain:
			_rain_particles.emitting = should_rain
		if should_rain and is_inside_tree() and _camera and is_instance_valid(_camera) and _camera.is_inside_tree():
			_rain_particles.global_position = Vector3(
				_camera.global_position.x,
				_camera.global_position.y + 11.0,
				_camera.global_position.z
			)
			var slant_x: float = wind_dir.x * (eff_wind * 0.08)
			var slant_z: float = wind_dir.y * (eff_wind * 0.08)
			_rain_particles.direction = Vector3(slant_x, -1.0, slant_z).normalized()

	if _snow_particles:
		var should_snow: bool = is_precipitating and is_alpine_cold
		if _snow_particles.emitting != should_snow:
			_snow_particles.emitting = should_snow
		if should_snow and is_inside_tree() and _camera and is_instance_valid(_camera) and _camera.is_inside_tree():
			_snow_particles.global_position = Vector3(
				_camera.global_position.x,
				_camera.global_position.y + 9.0,
				_camera.global_position.z
			)
			var drift_x: float = wind_dir.x * (eff_wind * 0.14)
			var drift_z: float = wind_dir.y * (eff_wind * 0.14)
			_snow_particles.direction = Vector3(drift_x, -1.0, drift_z).normalized()

	# 1b. Update Summit Spindrift Particles (Skyspire Peak Y >= 42m)
	if _spindrift_particles:
		var c_pos: Vector3 = _camera.global_position if (_camera and is_instance_valid(_camera) and _camera.is_inside_tree()) else Vector3.ZERO
		var should_spindrift: bool = (c_pos.y >= 42.0)
		if _spindrift_particles.emitting != should_spindrift:
			_spindrift_particles.emitting = should_spindrift
		if should_spindrift and is_inside_tree() and _camera and is_instance_valid(_camera) and _camera.is_inside_tree():
			_spindrift_particles.global_position = Vector3(
				c_pos.x,
				c_pos.y + 1.5,
				c_pos.z
			)
			var s_dir_x: float = wind_dir.x if absf(wind_dir.x) > 0.01 else 0.85
			var s_dir_z: float = wind_dir.y if absf(wind_dir.y) > 0.01 else 0.52
			_spindrift_particles.direction = Vector3(s_dir_x, -0.15, s_dir_z).normalized()

	# 1c. Update Forest Fireflies (Low elevation glades & forests Y < 14m at night/dusk)
	if _firefly_particles:
		var c_pos_f: Vector3 = _camera.global_position if (_camera and is_instance_valid(_camera) and _camera.is_inside_tree()) else Vector3.ZERO
		var is_night_or_dusk: bool = false
		if _sun and _sun.light_energy < 0.75:
			is_night_or_dusk = true
		elif _world_env and _world_env.environment and _world_env.environment.ambient_light_energy < 0.60:
			is_night_or_dusk = true

		var should_fireflies: bool = (c_pos_f.y < 14.0) and is_night_or_dusk and not is_precipitating
		if _firefly_particles.emitting != should_fireflies:
			_firefly_particles.emitting = should_fireflies
		if should_fireflies and is_inside_tree() and _camera and is_instance_valid(_camera) and _camera.is_inside_tree():
			_firefly_particles.global_position = Vector3(
				c_pos_f.x,
				maxf(c_pos_f.y, 2.0),
				c_pos_f.z
			)

	# 2. Update Terrain Surface Reaction
	if _terrain:
		_terrain.update_surface_reaction(delta, _weather)

	# 3 & 4. Update Water, Foliage Wind & Wetness when conditions change
	var surf_wetness: float = _terrain.get_surface_wetness() if _terrain else 0.0

	if absf(_last_eff_wind - eff_wind) > 0.04 or _last_wind_dir.distance_to(wind_dir) > 0.04 or absf(_last_surf_wetness - surf_wetness) > 0.01:
		_last_eff_wind = eff_wind
		_last_wind_dir = wind_dir
		_last_surf_wetness = surf_wetness

		if _water and _water.material_override is ShaderMaterial:
			var smat: ShaderMaterial = _water.material_override as ShaderMaterial
			smat.set_shader_parameter("wind_dir", wind_dir)
			var target_amp: float = 0.42 if is_precipitating else (0.28 if _weather.current_state == WeatherSystem.WeatherState.CLOUDY else 0.20)
			var target_spd: float = 0.9 + eff_wind * 0.22
			smat.set_shader_parameter("wave_amplitude", target_amp)
			smat.set_shader_parameter("wave_speed_1", target_spd)
			smat.set_shader_parameter("wave_speed_2", target_spd * 0.68)
			smat.set_shader_parameter("rain_ripple_strength", 1.0 if is_precipitating else 0.0)

		if _scatter and _scatter._grass_multimesh and _scatter._grass_multimesh.material_override is ShaderMaterial:
			var gmat: ShaderMaterial = _scatter._grass_multimesh.material_override as ShaderMaterial
			gmat.set_shader_parameter("wind_dir", wind_dir)
			gmat.set_shader_parameter("wind_speed", 1.0 + eff_wind * 0.35)
			gmat.set_shader_parameter("wind_strength", 0.22 + eff_wind * 0.08)
			gmat.set_shader_parameter("wetness", surf_wetness)

		var tmat: ShaderMaterial = TreePine.get_shared_pine_needle_material()
		if tmat:
			tmat.set_shader_parameter("wind_dir", wind_dir)
			tmat.set_shader_parameter("wind_speed", 0.75 + eff_wind * 0.22)
			tmat.set_shader_parameter("wind_strength", 0.12 + eff_wind * 0.05)
			tmat.set_shader_parameter("wetness", surf_wetness)


	# 5. Smooth Atmospheric Fog & Lighting
	if _world_env and _world_env.environment:
		var env: Environment = _world_env.environment
		var target_fog_density: float = 0.004
		var target_fog_color: Color = Color(0.68, 0.76, 0.86)
		var target_depth_begin: float = 180.0
		var target_depth_end: float = 920.0

		match _weather.current_state:
			WeatherSystem.WeatherState.RAIN:
				if is_alpine_cold:
					target_fog_density = 0.008
					target_fog_color = Color(0.72, 0.76, 0.84)
					target_depth_begin = 45.0
					target_depth_end = 360.0
				else:
					target_fog_density = 0.006
					target_fog_color = Color(0.52, 0.58, 0.66)
					target_depth_begin = 60.0
					target_depth_end = 420.0
			WeatherSystem.WeatherState.DROUGHT:
				target_fog_density = 0.0018
				target_fog_color = Color(0.78, 0.72, 0.60)
				target_depth_begin = 140.0
				target_depth_end = 820.0
			WeatherSystem.WeatherState.CLOUDY:
				target_fog_density = 0.0035
				target_fog_color = Color(0.64, 0.68, 0.74)
				target_depth_begin = 110.0
				target_depth_end = 680.0
			WeatherSystem.WeatherState.CLEAR:
				target_fog_density = 0.0015
				target_fog_color = Color(0.68, 0.76, 0.86)
				target_depth_begin = 180.0
				target_depth_end = 920.0

		env.fog_depth_begin = lerpf(env.fog_depth_begin, target_depth_begin, delta * 2.5)
		env.fog_depth_end = lerpf(env.fog_depth_end, target_depth_end, delta * 2.5)
		env.fog_density = lerpf(env.fog_density, target_fog_density, delta * 2.5)
		var target_h_density: float = 0.04 if _weather.current_state == WeatherSystem.WeatherState.RAIN else 0.08
		env.fog_height = lerpf(env.fog_height, 8.5, delta * 2.5)
		env.fog_height_density = lerpf(env.fog_height_density, target_h_density, delta * 2.5)
		# env.fog_light_color is authoritatively controlled by DayNightCycle to maintain correct twilight/night scattering

# --- OBSERVABILITY & TESTING HELPERS ---
func is_rain_emitting() -> bool:
	return _rain_particles != null and _rain_particles.emitting

func is_snow_emitting() -> bool:
	return _snow_particles != null and _snow_particles.emitting

func get_rain_particle_count() -> int:
	return _rain_particles.amount if _rain_particles != null else 0

func get_snow_particle_count() -> int:
	return _snow_particles.amount if _snow_particles != null else 0

func set_particle_budget(rain_count: int, snow_count: int) -> void:
	if _rain_particles:
		_rain_particles.amount = maxi(30, rain_count)
	if _snow_particles:
		_snow_particles.amount = maxi(15, snow_count)

func is_spindrift_emitting() -> bool:
	return _spindrift_particles != null and _spindrift_particles.emitting

func is_firefly_emitting() -> bool:
	return _firefly_particles != null and _firefly_particles.emitting

func get_spindrift_particle_count() -> int:
	return _spindrift_particles.amount if _spindrift_particles != null else 0

func get_firefly_particle_count() -> int:
	return _firefly_particles.amount if _firefly_particles != null else 0
