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

@export var day_duration_seconds: float = 720.0 # 12 minutes per full planetary day (peaceful exploration pace)
@export var start_hour: float = 11.5 # Start at 11:30 AM in bright high-sun midday

var current_lighting_state: LightingState = LightingState.DYNAMIC

var _sun: DirectionalLight3D
var _world_env: WorldEnvironment
var _clock: WorldClock
var _weather: WeatherSystem

func setup(clock: WorldClock, sun_node: DirectionalLight3D, env_node: WorldEnvironment, weather: WeatherSystem = null) -> void:
	_clock = clock
	_sun = sun_node
	_world_env = env_node
	_weather = weather

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

	match state:
		LightingState.MIDDAY:
			_sun.visible = true
			_sun.rotation.x = deg_to_rad(-62.0)
			_sun.rotation.y = deg_to_rad(25.0)
			_sun.light_energy = 1.55
			_sun.light_color = Color(1.0, 0.98, 0.92)
			_sun.shadow_enabled = true
			if p_sky:
				p_sky.sky_top_color = Color(0.08, 0.28, 0.68)
				p_sky.sky_horizon_color = Color(0.46, 0.62, 0.84)
				p_sky.ground_bottom_color = Color(0.08, 0.12, 0.10)
				p_sky.ground_horizon_color = Color(0.42, 0.55, 0.72)
				p_sky.sun_angle_max = 0.90
				p_sky.sun_curve = 0.06
			if _world_env.environment:
				# Reset ambient to crisp daytime values
				_world_env.environment.ambient_light_energy = 0.14
				_world_env.environment.ambient_light_color = Color(0.40, 0.50, 0.66)
				_world_env.environment.volumetric_fog_density = 0.00075
				_world_env.environment.volumetric_fog_albedo = Color(0.62, 0.74, 0.90)

		LightingState.GOLDEN_HOUR:
			_sun.visible = true
			_sun.rotation.x = deg_to_rad(-16.0)
			_sun.rotation.y = deg_to_rad(45.0)
			_sun.light_energy = 1.45
			_sun.light_color = Color(1.0, 0.64, 0.32)
			_sun.shadow_enabled = true
			if p_sky:
				p_sky.sky_top_color = Color(0.10, 0.18, 0.44)
				p_sky.sky_horizon_color = Color(0.95, 0.52, 0.20)
				p_sky.ground_bottom_color = Color(0.08, 0.09, 0.08)
				p_sky.ground_horizon_color = Color(0.85, 0.42, 0.18)
				p_sky.sun_angle_max = 1.10
				p_sky.sun_curve = 0.12
			if _world_env.environment:
				# Raise warm amber ambient fill for golden hour — low-angle sun leaves half the scene dark without it
				_world_env.environment.ambient_light_energy = 0.38
				_world_env.environment.ambient_light_color = Color(0.62, 0.48, 0.32)
				_world_env.environment.volumetric_fog_density = 0.0012
				_world_env.environment.volumetric_fog_albedo = Color(0.92, 0.60, 0.35)

		LightingState.OVERCAST_RAIN:
			_sun.visible = true
			_sun.rotation.x = deg_to_rad(-45.0)
			_sun.rotation.y = deg_to_rad(25.0)
			_sun.light_energy = 0.45
			_sun.light_color = Color(0.68, 0.74, 0.82)
			_sun.shadow_enabled = false
			if p_sky:
				p_sky.sky_top_color = Color(0.16, 0.20, 0.26)
				p_sky.sky_horizon_color = Color(0.36, 0.40, 0.46)
				p_sky.ground_bottom_color = Color(0.09, 0.11, 0.12)
				p_sky.ground_horizon_color = Color(0.34, 0.38, 0.44)
			if _world_env.environment:
				_world_env.environment.volumetric_fog_density = 0.0035
				_world_env.environment.volumetric_fog_albedo = Color(0.48, 0.54, 0.62)

func _process(_delta: float) -> void:
	if not _clock or not _sun or not _world_env:
		return

	if current_lighting_state != LightingState.DYNAMIC:
		return

	var time_offset: float = (start_hour / 24.0) * day_duration_seconds
	var sim_time: float = _clock.simulation_time + time_offset
	# Progress from 0.0 (midnight) -> 0.25 (dawn) -> 0.5 (noon) -> 0.75 (dusk) -> 1.0 (midnight)
	var day_phase: float = fmod(sim_time / day_duration_seconds, 1.0)
	var sun_angle: float = (day_phase * TAU) - (PI * 0.5)

	# Altitude: positive when above horizon (day), negative when below (night)
	var sun_altitude: float = sin(sun_angle)
	var weather_mult: float = _weather.get_sun_multiplier() if _weather else 1.0

	if sun_altitude > 0.0:
		# Day & Golden Hour: Light shines DOWNWARD onto the island (-X rotation)
		_sun.visible = true
		var sun_pitch: float = -clampf(sun_altitude * deg_to_rad(65.0), deg_to_rad(14.0), deg_to_rad(65.0))
		var day_t: float = clampf((day_phase - 0.25) / 0.50, 0.0, 1.0)
		var sun_yaw: float = lerpf(deg_to_rad(-45.0), deg_to_rad(65.0), day_t)
		_sun.rotation = Vector3(sun_pitch, sun_yaw, 0.0)

		_sun.light_energy = clamp(sun_altitude * 1.65, 0.45, 1.60) * weather_mult
		# Warm amber-gold during dawn/dusk, crisp natural light at midday
		var golden_factor: float = clamp(1.0 - (sun_altitude / 0.45), 0.0, 1.0)
		var noon_color: Color = Color(1.0, 0.98, 0.94)
		var golden_color: Color = Color(1.0, 0.72, 0.42)
		_sun.light_color = noon_color.lerp(golden_color, golden_factor)
		_sun.shadow_enabled = true if weather_mult > 0.35 else false
	else:
		# Authentic Midnight Moonlight: Soft top-down cool moonlight
		_sun.visible = true
		_sun.rotation = Vector3(deg_to_rad(-45.0), deg_to_rad(180.0), 0.0)
		_sun.light_energy = 0.22 * weather_mult # Soft directional moonlight
		_sun.light_color = Color(0.45, 0.60, 0.88) # Cool silver moonlight
		_sun.shadow_enabled = false

	# Adjust sky environment
	if _world_env and _world_env.environment and _world_env.environment.sky:
		var sky_mat: Material = _world_env.environment.sky.sky_material
		if sky_mat is ProceduralSkyMaterial:
			var p_sky: ProceduralSkyMaterial = sky_mat as ProceduralSkyMaterial
			var day_factor: float = clamp((sun_altitude + 0.05) / 0.45, 0.0, 1.0)

			var target_top: Color = Color(0.015, 0.03, 0.07).lerp(Color(0.18, 0.44, 0.82), day_factor)
			var target_horizon: Color = Color(0.04, 0.07, 0.14).lerp(Color(0.74, 0.80, 0.88), day_factor)

			# Golden hour sky horizon tint
			if day_factor > 0.05 and day_factor < 0.65:
				var dusk_intensity: float = sin(day_factor * PI / 0.65) * 0.50
				target_horizon = target_horizon.lerp(Color(0.92, 0.58, 0.25), dusk_intensity)

			# Weather overcast modification
			if _weather:
				match _weather.current_state:
					WeatherSystem.WeatherState.CLOUDY:
						target_top = target_top.lerp(Color(0.22, 0.25, 0.32), 0.55)
						target_horizon = target_horizon.lerp(Color(0.42, 0.45, 0.52), 0.55)
					WeatherSystem.WeatherState.RAIN:
						target_top = target_top.lerp(Color(0.10, 0.14, 0.20), 0.80)
						target_horizon = target_horizon.lerp(Color(0.32, 0.35, 0.40), 0.75)
					WeatherSystem.WeatherState.DROUGHT:
						target_horizon = target_horizon.lerp(Color(0.85, 0.75, 0.55), 0.40)

			p_sky.sky_top_color = target_top
			p_sky.sky_horizon_color = target_horizon
			p_sky.ground_bottom_color = Color(0.01, 0.015, 0.03).lerp(Color(0.14, 0.20, 0.16), day_factor)
			p_sky.ground_horizon_color = p_sky.sky_horizon_color

			if _world_env.environment:
				if _world_env.environment.volumetric_fog_enabled:
					_world_env.environment.volumetric_fog_albedo = target_horizon.lerp(Color(0.85, 0.92, 0.98), day_factor * 0.3)
				elif _world_env.environment.fog_enabled:
					_world_env.environment.fog_light_color = target_horizon.lerp(Color(0.62, 0.72, 0.85), day_factor * 0.25)
