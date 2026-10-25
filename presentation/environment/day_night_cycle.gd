class_name DayNightCycle
extends Node3D

## Drives celestial movement and atmospheric lighting coupled to WorldClock and WeatherSystem.
## Supports continuous diurnal progression as well as calibrated visual QA presets:
## 1. Clear Midday (high-elevation crisp sunlight, blue atmosphere)
## 2. Golden Hour (warm amber directional grazing light, long trailing shadows)
## 3. Overcast / Post-Rain (diffuse slate sky, soft ambient fill, wet sheen)

enum LightingState {
	DYNAMIC = 0,
	MIDDAY = 1,
	GOLDEN_HOUR = 2,
	OVERCAST_RAIN = 3
}

@export var day_duration_seconds: float = 1800.0 # 30 minutes per full planetary day — Genshin-like pacing
@export var start_hour: float = 11.5 # Start at 11:30 AM in bright high-sun midday

var current_lighting_state: LightingState = LightingState.DYNAMIC
var current_sun_dir: Vector3 = Vector3(0.45, 0.85, 0.28).normalized()
var current_moon_dir: Vector3 = Vector3(-0.45, -0.85, -0.28).normalized()

# Smooth lighting state to prevent jarring snap-rotation of shadows
var _smooth_sun_basis: Basis = Basis()
var _sun_basis_initialized: bool = false
var _shadow_throttle: float = 0.0
const SHADOW_UPDATE_INTERVAL: float = 2.0 # Update shadow direction every 2 real seconds

var _sun: DirectionalLight3D
var _world_env: WorldEnvironment
var _clock: WorldClock
var _weather: WeatherSystem
var _cloud_dome: MeshInstance3D = null
var _cloud_mat: ShaderMaterial = null

func get_sun_direction() -> Vector3:
	return current_sun_dir

func get_moon_direction() -> Vector3:
	return current_moon_dir

func setup(clock: WorldClock, sun_node: DirectionalLight3D, env_node: WorldEnvironment, weather: WeatherSystem = null) -> void:
	_clock = clock
	_sun = sun_node
	_world_env = env_node
	_weather = weather
	if _clock:
		day_duration_seconds = _clock.day_duration
		start_hour = _clock.start_hour

	# Calibrate ProceduralSkyMaterial sun disc to realistic compact angular diameter
	if _world_env and _world_env.environment:
		var env: Environment = _world_env.environment
		# ACES filmic tonemapper for delicate dynamic range without clipped highlights
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.02
		# Delicate celestial radiance bloom without distorting ground contrast
		env.glow_enabled = true
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		env.glow_bloom = 0.10
		env.glow_intensity = 0.32
		env.glow_hdr_threshold = 1.02
		# Cinematic color grading with pure natural color fidelity (Genshin vibrant anime palette)
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.08
		env.adjustment_saturation = 1.12
		# Aerial perspective depth fog with layered height fog (RDR2 Atmospheric Depth)
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_depth_begin = 320.0
		env.fog_depth_end = 980.0
		env.fog_depth_curve = 1.15
		env.fog_height = 8.5
		env.fog_height_density = 0.08

		if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var p_sky: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial
			p_sky.sun_angle_max = 0.0
			p_sky.sun_curve = 0.01

	_setup_cloud_dome()

func get_time_of_day() -> float:
	return _clock.get_time_of_day() if _clock else 12.0

func is_night() -> bool:
	var h: float = get_time_of_day()
	return h < 6.0 or h >= 18.0

func _setup_cloud_dome() -> void:
	if _cloud_dome != null:
		return
	_cloud_dome = MeshInstance3D.new()
	_cloud_dome.name = "ProceduralCloudDome"
	var s_mesh: SphereMesh = SphereMesh.new()
	s_mesh.radius = 820.0
	s_mesh.height = 1640.0
	s_mesh.is_hemisphere = false
	_cloud_dome.mesh = s_mesh
	_cloud_mat = ShaderMaterial.new()
	_cloud_mat.shader = preload("res://presentation/shaders/clouds_procedural.gdshader")
	_cloud_dome.material_override = _cloud_mat
	_cloud_dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_cloud_dome)

func set_midday() -> void:
	apply_lighting_state(LightingState.MIDDAY)

func set_golden_hour() -> void:
	apply_lighting_state(LightingState.GOLDEN_HOUR)

func set_overcast_rain() -> void:
	apply_lighting_state(LightingState.OVERCAST_RAIN)

func set_dynamic() -> void:
	current_lighting_state = LightingState.DYNAMIC

func apply_lighting_state(state: LightingState) -> void:
	current_lighting_state = state
	if not _sun or not _world_env:
		return

	var p_sky: ProceduralSkyMaterial = null
	if _world_env.environment and _world_env.environment.sky:
		if _world_env.environment.sky.sky_material is ProceduralSkyMaterial:
			p_sky = _world_env.environment.sky.sky_material as ProceduralSkyMaterial

	var s_dir: Vector3 = Vector3(0.45, 0.85, 0.28).normalized()

	match state:
		LightingState.MIDDAY:
			current_sun_dir = s_dir
			current_moon_dir = -s_dir
			_sun.visible = true
			_sun.transform = Transform3D().looking_at(-s_dir, Vector3.UP)
			_sun.light_energy = 1.35
			_sun.light_color = Color(1.0, 0.97, 0.92)
			_sun.shadow_enabled = true
			_sun.shadow_blur = 1.6
			_sun.shadow_bias = 0.012
			_sun.shadow_normal_bias = 1.2
			if p_sky:
				p_sky.sky_top_color = Color(0.09, 0.32, 0.72)
				p_sky.sky_horizon_color = Color(0.52, 0.68, 0.88)
				p_sky.ground_bottom_color = Color(0.08, 0.12, 0.10)
				p_sky.ground_horizon_color = Color(0.42, 0.55, 0.72)
				p_sky.sun_angle_max = 0.0
				p_sky.sun_curve = 0.01
			if _world_env.environment:
				_world_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
				_world_env.environment.ambient_light_energy = 0.72
				_world_env.environment.ambient_light_color = Color(0.54, 0.64, 0.76)
				_world_env.environment.ambient_light_sky_contribution = 0.65
				_world_env.environment.fog_density = 0.0018
				_world_env.environment.fog_depth_begin = 340.0
				_world_env.environment.fog_depth_end = 980.0
				_world_env.environment.fog_light_color = Color(0.52, 0.68, 0.88)
				_world_env.environment.fog_height = 8.5
				_world_env.environment.fog_height_density = 0.06
			if _cloud_mat:
				_cloud_mat.set_shader_parameter("day_factor", 1.0)
				_cloud_mat.set_shader_parameter("golden_factor", 0.0)
				_cloud_mat.set_shader_parameter("twilight_factor", 0.0)
				_cloud_mat.set_shader_parameter("cloud_coverage", 0.20)
				_cloud_mat.set_shader_parameter("rain_factor", 0.0)
				_cloud_mat.set_shader_parameter("sun_dir", s_dir)
				_cloud_mat.set_shader_parameter("moon_dir", -s_dir)
				_cloud_mat.set_shader_parameter("moon_phase", 0.50)

		LightingState.GOLDEN_HOUR:
			var golden_s_dir: Vector3 = Vector3(0.92, 0.22, -0.32).normalized()
			current_sun_dir = golden_s_dir
			current_moon_dir = -golden_s_dir
			_sun.visible = true
			_sun.transform = Transform3D().looking_at(-golden_s_dir, Vector3.UP)
			_sun.light_energy = 1.25
			_sun.light_color = Color(1.0, 0.82, 0.64)
			_sun.shadow_enabled = true
			_sun.shadow_blur = 1.8
			_sun.shadow_bias = 0.02
			_sun.shadow_normal_bias = 1.6
			if p_sky:
				p_sky.sky_top_color = Color(0.12, 0.20, 0.45)
				p_sky.sky_horizon_color = Color(0.95, 0.62, 0.38)
				p_sky.ground_bottom_color = Color(0.08, 0.10, 0.12)
				p_sky.ground_horizon_color = Color(0.55, 0.45, 0.42)
				p_sky.sun_angle_max = 0.0
				p_sky.sun_curve = 0.01
			if _world_env.environment:
				_world_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
				_world_env.environment.ambient_light_energy = 0.64
				_world_env.environment.ambient_light_color = Color(0.52, 0.62, 0.75)
				_world_env.environment.ambient_light_sky_contribution = 0.70
				_world_env.environment.fog_density = 0.0016
				_world_env.environment.fog_depth_begin = 320.0
				_world_env.environment.fog_depth_end = 920.0
				_world_env.environment.fog_light_color = Color(0.90, 0.68, 0.52)
				_world_env.environment.fog_height = 8.5
				_world_env.environment.fog_height_density = 0.12
			if _cloud_mat:
				_cloud_mat.set_shader_parameter("day_factor", 0.60)
				_cloud_mat.set_shader_parameter("golden_factor", 0.95)
				_cloud_mat.set_shader_parameter("twilight_factor", 0.15)
				_cloud_mat.set_shader_parameter("cloud_coverage", 0.28)
				_cloud_mat.set_shader_parameter("rain_factor", 0.0)
				_cloud_mat.set_shader_parameter("sun_dir", golden_s_dir)
				_cloud_mat.set_shader_parameter("moon_dir", -golden_s_dir)
				_cloud_mat.set_shader_parameter("moon_phase", 0.50)

		LightingState.OVERCAST_RAIN:
			current_sun_dir = s_dir
			current_moon_dir = -s_dir
			_sun.visible = true
			_sun.transform = Transform3D().looking_at(-s_dir, Vector3.UP)
			_sun.light_energy = 0.45
			_sun.light_color = Color(0.65, 0.70, 0.78)
			_sun.shadow_enabled = false
			if p_sky:
				p_sky.sky_top_color = Color(0.14, 0.18, 0.24)
				p_sky.sky_horizon_color = Color(0.36, 0.40, 0.46)
				p_sky.ground_bottom_color = Color(0.09, 0.11, 0.12)
				p_sky.ground_horizon_color = Color(0.34, 0.38, 0.44)
				p_sky.sun_angle_max = 0.0
				p_sky.sun_curve = 0.01
			if _world_env.environment:
				_world_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
				_world_env.environment.ambient_light_energy = 0.48
				_world_env.environment.ambient_light_color = Color(0.44, 0.48, 0.54)
				_world_env.environment.fog_density = 0.010
				_world_env.environment.fog_depth_begin = 220.0
				_world_env.environment.fog_depth_end = 650.0
				_world_env.environment.fog_light_color = Color(0.50, 0.56, 0.64)
				_world_env.environment.fog_height = 8.5
				_world_env.environment.fog_height_density = 0.04
			if _cloud_mat:
				_cloud_mat.set_shader_parameter("day_factor", 0.45)
				_cloud_mat.set_shader_parameter("golden_factor", 0.0)
				_cloud_mat.set_shader_parameter("twilight_factor", 0.0)
				_cloud_mat.set_shader_parameter("cloud_coverage", 0.88)
				_cloud_mat.set_shader_parameter("rain_factor", 1.0)

func _process(_delta: float) -> void:
	if not _clock or not _sun or not _world_env:
		return

	# Always ensure celestial cloud dome follows active exploration camera
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
	if cam and _cloud_dome:
		_cloud_dome.global_position = cam.global_position

	if current_lighting_state != LightingState.DYNAMIC:
		return

	# Single authoritative source of truth: WorldClock
	var day_phase: float = _clock.get_day_phase()
	var sun_angle: float = (day_phase * TAU) - (PI * 0.5)

	# 1. Physical 3D Celestial Trajectories (23.5° astronomical axial tilt)
	# Rises in East (+X), arcs smoothly across southern sky (+Y, -Z), sets in West (-X)
	var sun_dir: Vector3 = Vector3(
		cos(sun_angle),
		sin(sun_angle) * cos(deg_to_rad(23.5)),
		-sin(sun_angle) * sin(deg_to_rad(23.5))
	).normalized()

	# Moon opposes sun directly with realistic 5.14° lunar orbital inclination
	var moon_dir: Vector3 = -sun_dir
	moon_dir = Transform3D().rotated(Vector3(0.0, 1.0, 0.0), deg_to_rad(5.14)) * moon_dir
	moon_dir = moon_dir.normalized()

	current_sun_dir = sun_dir
	current_moon_dir = moon_dir

	# Continuous multi-day lunar phase progression
	var day_num: int = _clock.get_day_number() if (_clock and _clock.has_method("get_day_number")) else 1
	var moon_phase: float = fposmod((float(day_num) * 0.125) + (day_phase * 0.05) + 0.50, 1.0)

	var sun_alt: float = sun_dir.y
	var weather_mult: float = _weather.get_sun_multiplier() if _weather else 1.0

	# Diurnal and atmospheric transition factors
	var day_factor: float = clampf((sun_alt + 0.16) / 0.52, 0.0, 1.0)
	var golden_factor: float = clampf(1.0 - absf(sun_alt - 0.04) / 0.22, 0.0, 1.0) * (1.0 if sun_alt > -0.10 else 0.0)
	var twilight_factor: float = clampf(1.0 - absf(sun_alt - (-0.08)) / 0.16, 0.0, 1.0)
	var twilight_blend: float = smoothstep(-0.14, 0.06, sun_alt)
	var rain_factor: float = 1.0 if (_weather and _weather.current_state == WeatherSystem.WeatherState.RAIN) else 0.0

	# 2. Celestial Directional Lighting & Shadows
	var noon_color: Color = Color(1.0, 0.98, 0.94)
	var golden_color: Color = Color(1.0, 0.82, 0.64) # Refined golden peach sunset
	var day_color: Color = noon_color.lerp(golden_color, golden_factor)
	var night_color: Color = Color(0.42, 0.58, 0.85) # Cool silver moonlight

	var day_energy: float = clampf(maxf(sun_alt + 0.08, 0.15) * 1.35, 0.35, 1.35) * weather_mult
	if golden_factor > 0.15:
		day_energy = maxf(day_energy, 1.20 * golden_factor) * weather_mult
	var night_energy: float = clampf(maxf(moon_dir.y, 0.15) * 0.22, 0.08, 0.24) * weather_mult

	# Day/Night directional light — smooth continuous slerp tracks sun precisely with zero jerky snap
	var active_celestial_dir: Vector3 = sun_dir if twilight_blend >= 0.50 else moon_dir
	var light_target: Vector3 = -active_celestial_dir
	var up_vec: Vector3 = Vector3.UP if absf(light_target.y) < 0.98 else Vector3.FORWARD
	var target_transform: Transform3D = Transform3D().looking_at(light_target, up_vec)

	if not _sun_basis_initialized:
		_sun.transform = target_transform
		_smooth_sun_basis = target_transform.basis
		_sun_basis_initialized = true
	else:
		_smooth_sun_basis = _smooth_sun_basis.slerp(target_transform.basis, minf(_delta * 2.0, 1.0))
		_sun.transform.basis = _smooth_sun_basis

	_sun.visible = true
	_sun.light_energy = lerpf(night_energy, day_energy, twilight_blend)
	_sun.light_color = night_color.lerp(day_color, twilight_blend)
	_sun.shadow_enabled = (twilight_blend > 0.25 and weather_mult > 0.35) or (twilight_blend <= 0.15 and moon_dir.y > 0.30 and weather_mult > 0.40)
	_sun.shadow_blur = 1.6
	_sun.shadow_bias = 0.010
	_sun.shadow_normal_bias = 1.1

	# 3. Sky Atmosphere & Ambient Environment
	if _world_env and _world_env.environment:
		var env: Environment = _world_env.environment
		var dyn_ambient_e: float = lerpf(0.28, 0.72, day_factor) * weather_mult
		var dyn_ambient_c: Color = Color(0.20, 0.28, 0.42).lerp(Color(0.54, 0.64, 0.76), day_factor)
		if golden_factor > 0.05:
			dyn_ambient_c = dyn_ambient_c.lerp(Color(0.52, 0.62, 0.75), golden_factor * 0.70)
		env.ambient_light_energy = dyn_ambient_e
		env.ambient_light_color = dyn_ambient_c

		var target_top: Color = Color(0.008, 0.015, 0.04).lerp(Color(0.12, 0.44, 0.88), day_factor)
		var target_horizon: Color = Color(0.035, 0.065, 0.12).lerp(Color(0.58, 0.78, 0.95), day_factor)

		if golden_factor > 0.05:
			target_top = target_top.lerp(Color(0.14, 0.22, 0.52), golden_factor * 0.70)
			target_horizon = target_horizon.lerp(Color(0.96, 0.64, 0.38), golden_factor * 0.85)
		elif twilight_factor > 0.05:
			target_top = target_top.lerp(Color(0.05, 0.08, 0.22), twilight_factor * 0.60)
			target_horizon = target_horizon.lerp(Color(0.42, 0.20, 0.28), twilight_factor * 0.75)

		if _weather:
			match _weather.current_state:
				WeatherSystem.WeatherState.CLOUDY:
					target_top = target_top.lerp(Color(0.18, 0.22, 0.28), 0.60)
					target_horizon = target_horizon.lerp(Color(0.40, 0.44, 0.50), 0.60)
				WeatherSystem.WeatherState.RAIN:
					target_top = target_top.lerp(Color(0.12, 0.15, 0.20), 0.82)
					target_horizon = target_horizon.lerp(Color(0.30, 0.34, 0.40), 0.78)
				WeatherSystem.WeatherState.DROUGHT:
					target_horizon = target_horizon.lerp(Color(0.85, 0.75, 0.55), 0.40)

		if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var p_sky: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial
			p_sky.sun_angle_max = 0.0
			p_sky.sun_curve = 0.01
			p_sky.sky_top_color = target_top
			p_sky.sky_horizon_color = target_horizon
			p_sky.ground_bottom_color = Color(0.01, 0.015, 0.03).lerp(Color(0.10, 0.14, 0.12), day_factor)
			p_sky.ground_horizon_color = p_sky.sky_horizon_color

		# Unified Fog Coordination with Aerial Perspective Harmonization
		# Fog color directly tracks horizon sky to eliminate harsh horizon cut-lines across distant trees
		var target_fog_color: Color = target_horizon.lerp(Color(0.60, 0.72, 0.86), 0.20)
		var target_fog_density: float = 0.0018

		if _weather:
			match _weather.current_state:
				WeatherSystem.WeatherState.RAIN:
					target_fog_density = 0.0085
					target_fog_color = target_horizon.lerp(Color(0.42, 0.46, 0.52), 0.50)
				WeatherSystem.WeatherState.CLOUDY:
					target_fog_density = 0.0038
					target_fog_color = target_horizon.lerp(Color(0.52, 0.58, 0.66), 0.40)
				WeatherSystem.WeatherState.DROUGHT:
					target_fog_density = 0.0012
					target_fog_color = target_horizon.lerp(Color(0.78, 0.72, 0.60), 0.35)
				WeatherSystem.WeatherState.CLEAR:
					target_fog_density = 0.0018
					target_fog_color = target_horizon.lerp(Color(0.60, 0.72, 0.86), 0.20)

		target_fog_color = target_fog_color.lerp(Color(0.04, 0.06, 0.12), (1.0 - day_factor) * 0.75)
		if golden_factor > 0.05:
			target_fog_color = target_fog_color.lerp(Color(0.96, 0.54, 0.20), golden_factor * 0.75)

		env.fog_light_color = env.fog_light_color.lerp(target_fog_color, _delta * 3.0)
		env.fog_density = lerpf(env.fog_density, target_fog_density, _delta * 3.0)

		# Layered Height Fog: morning/dusk valley mist vs clear alpine heights (RDR2 Atmospheric Depth)
		var target_height_density: float = 0.08
		if golden_factor > 0.05 or twilight_factor > 0.05:
			target_height_density = 0.12
		elif _weather and _weather.current_state == WeatherSystem.WeatherState.RAIN:
			target_height_density = 0.04
		env.fog_height_density = lerpf(env.fog_height_density, target_height_density, _delta * 2.5)
		env.fog_height = lerpf(env.fog_height, 8.5, _delta * 2.5)

	# 4. Drive Upgraded Procedural Sky & Cloud Dome Shader
	if _cloud_mat:
		_cloud_mat.set_shader_parameter("day_factor", day_factor)
		_cloud_mat.set_shader_parameter("golden_factor", golden_factor)
		_cloud_mat.set_shader_parameter("twilight_factor", twilight_factor)
		_cloud_mat.set_shader_parameter("rain_factor", rain_factor)
		_cloud_mat.set_shader_parameter("sun_dir", sun_dir)
		_cloud_mat.set_shader_parameter("moon_dir", moon_dir)
		_cloud_mat.set_shader_parameter("moon_phase", moon_phase)

		var target_cov: float = 0.20
		if _weather:
			_cloud_mat.set_shader_parameter("wind_dir", _weather.wind_direction)
			_cloud_mat.set_shader_parameter("wind_speed", _weather.wind_speed)
			match _weather.current_state:
				WeatherSystem.WeatherState.CLEAR:
					target_cov = 0.20
				WeatherSystem.WeatherState.CLOUDY:
					target_cov = 0.65
				WeatherSystem.WeatherState.RAIN:
					target_cov = 0.88
				WeatherSystem.WeatherState.DROUGHT:
					target_cov = 0.04
		_cloud_mat.set_shader_parameter("cloud_coverage", target_cov)
