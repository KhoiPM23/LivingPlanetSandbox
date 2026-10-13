class_name WeatherEffectsController
extends Node3D

## Coordinates weather presentation effects, precipitation particles,
## wind-coupled foliage and ocean shaders, atmospheric fog, and surface reactions.

var _weather: WeatherSystem
var _terrain: IslandTerrain
var _water: WaterPlane
var _scatter: VegetationScatter
var _camera: Camera3D
var _world_env: WorldEnvironment
var _sun: DirectionalLight3D

var _rain_particles: GPUParticles3D
var _rain_mat: ParticleProcessMaterial

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

func _setup_rain_particles() -> void:
	if _rain_particles:
		return

	_rain_particles = GPUParticles3D.new()
	_rain_particles.name = "RainParticles"
	_rain_particles.amount = 420
	_rain_particles.lifetime = 1.4
	_rain_particles.preprocess = 0.3
	_rain_particles.visibility_aabb = AABB(Vector3(-35, -20, -35), Vector3(70, 40, 70))
	_rain_particles.emitting = false

	# Particle process material
	_rain_mat = ParticleProcessMaterial.new()
	_rain_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_rain_mat.emission_box_extents = Vector3(28.0, 3.0, 28.0)
	_rain_mat.direction = Vector3(0.0, -1.0, 0.0)
	_rain_mat.spread = 6.0
	_rain_mat.initial_velocity_min = 18.0
	_rain_mat.initial_velocity_max = 24.0

	_rain_particles.process_material = _rain_mat

	# Draw pass mesh: Slender unshaded raindrop streak
	var streak_mesh: BoxMesh = BoxMesh.new()
	streak_mesh.size = Vector3(0.025, 0.55, 0.025)

	var streak_mat: StandardMaterial3D = StandardMaterial3D.new()
	streak_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	streak_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	streak_mat.albedo_color = Color(0.72, 0.85, 0.98, 0.42)

	streak_mesh.material = streak_mat
	_rain_particles.draw_pass_1 = streak_mesh

	add_child(_rain_particles)

func _process(delta: float) -> void:
	if not _weather:
		return

	var is_raining: bool = (_weather.current_state == WeatherSystem.WeatherState.RAIN)
	var wind_dir: Vector2 = _weather.get_wind_direction()
	var eff_wind: float = _weather.get_effective_wind_speed()

	# 1. Update Rain Particles
	if _rain_particles:
		_rain_particles.emitting = is_raining

		# Center rain volume over camera for optimal local density (when inside tree)
		if is_inside_tree():
			if _camera and is_instance_valid(_camera) and _camera.is_inside_tree():
				_rain_particles.global_position = Vector3(
					_camera.global_position.x,
					_camera.global_position.y + 11.0,
					_camera.global_position.z
				)
			else:
				_rain_particles.global_position = Vector3(0.0, 20.0, 0.0)

		# Slant falling rain according to wind vector
		if _rain_mat and is_raining:
			var slant_x: float = wind_dir.x * (eff_wind * 0.08)
			var slant_z: float = wind_dir.y * (eff_wind * 0.08)
			_rain_mat.direction = Vector3(slant_x, -1.0, slant_z).normalized()

	# 2. Update Terrain Surface Reaction
	if _terrain:
		_terrain.update_surface_reaction(delta, _weather)

	# 3. Update Water Ocean Shader Waves & Rain Ripples
	if _water and _water.material_override is ShaderMaterial:
		var smat: ShaderMaterial = _water.material_override as ShaderMaterial
		smat.set_shader_parameter("wind_dir", wind_dir)
		var target_amp: float = 0.42 if is_raining else (0.28 if _weather.current_state == WeatherSystem.WeatherState.CLOUDY else 0.20)
		var target_spd: float = 0.9 + eff_wind * 0.22
		smat.set_shader_parameter("wave_amplitude", target_amp)
		smat.set_shader_parameter("wave_speed_1", target_spd)
		smat.set_shader_parameter("wave_speed_2", target_spd * 0.68)
		smat.set_shader_parameter("rain_ripple_strength", 1.0 if is_raining else 0.0)

	# 4. Update Foliage Wind & Wetness
	if _scatter and _scatter._grass_multimesh and _scatter._grass_multimesh.material_override is ShaderMaterial:
		var gmat: ShaderMaterial = _scatter._grass_multimesh.material_override as ShaderMaterial
		gmat.set_shader_parameter("wind_dir", wind_dir)
		gmat.set_shader_parameter("wind_speed", 1.0 + eff_wind * 0.35)
		gmat.set_shader_parameter("wind_strength", 0.22 + eff_wind * 0.08)
		if _terrain:
			gmat.set_shader_parameter("wetness", _terrain.get_surface_wetness())

	# 5. Smooth Atmospheric Fog & Lighting
	if _world_env and _world_env.environment:
		var env: Environment = _world_env.environment
		var target_fog_density: float = 0.004
		var target_fog_color: Color = Color(0.68, 0.76, 0.86)

		match _weather.current_state:
			WeatherSystem.WeatherState.RAIN:
				target_fog_density = 0.012
				target_fog_color = Color(0.52, 0.58, 0.66)
			WeatherSystem.WeatherState.DROUGHT:
				target_fog_density = 0.003
				target_fog_color = Color(0.78, 0.72, 0.60)
			WeatherSystem.WeatherState.CLOUDY:
				target_fog_density = 0.006
				target_fog_color = Color(0.64, 0.68, 0.74)
			WeatherSystem.WeatherState.CLEAR:
				target_fog_density = 0.004
				target_fog_color = Color(0.68, 0.76, 0.86)

		env.fog_density = lerpf(env.fog_density, target_fog_density, delta * 2.5)
		env.fog_light_color = env.fog_light_color.lerp(target_fog_color, delta * 2.5)
