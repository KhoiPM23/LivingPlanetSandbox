class_name DayNightCycle
extends Node3D

## Drives celestial movement and atmospheric lighting coupled to WorldClock and WeatherSystem.

@export var day_duration_seconds: float = 120.0 # 2 minutes per full planetary day
@export var start_hour: float = 9.0 # Start at 09:00 AM in bright morning sunlight
@export var sun_path: NodePath
@export var environment_path: NodePath

var _sun: DirectionalLight3D
var _world_env: WorldEnvironment
var _clock: WorldClock
var _weather: WeatherSystem

func setup(clock: WorldClock, sun_node: DirectionalLight3D, env_node: WorldEnvironment, weather: WeatherSystem = null) -> void:
	_clock = clock
	_sun = sun_node
	_world_env = env_node
	_weather = weather

func _process(_delta: float) -> void:
	if not _clock or not _sun or not _world_env:
		return
		
	var time_offset: float = (start_hour / 24.0) * day_duration_seconds
	var sim_time: float = _clock.simulation_time + time_offset
	# Progress from 0.0 (midnight) -> 0.25 (dawn) -> 0.5 (noon) -> 0.75 (dusk) -> 1.0 (midnight)
	var day_phase: float = fmod(sim_time / day_duration_seconds, 1.0)
	var sun_angle: float = (day_phase * TAU) - (PI * 0.5)
	
	# Sun rotation
	_sun.rotation.x = sun_angle
	_sun.rotation.y = deg_to_rad(25.0) # Seasonal orbital tilt
	
	# Altitude: positive when above horizon, negative when below
	var sun_altitude: float = sin(sun_angle)
	var weather_mult: float = _weather.get_sun_multiplier() if _weather else 1.0
	
	if sun_altitude > 0.0:
		# Day
		_sun.visible = true
		_sun.light_energy = clamp(sun_altitude * 1.4, 0.15, 1.25) * weather_mult
		_sun.light_color = Color(1.0, 0.95, 0.85).lerp(Color(1.0, 0.75, 0.5), 1.0 - clamp(sun_altitude * 2.0, 0.0, 1.0))
		_sun.shadow_enabled = true if weather_mult > 0.4 else false # Dim shadows during heavy rain
	else:
		# Night
		_sun.visible = true
		_sun.light_energy = 0.08 * weather_mult # Soft moonlight
		_sun.light_color = Color(0.4, 0.5, 0.7)
		_sun.shadow_enabled = false # Save draw calls during night
		
	# Adjust sky environment
	if _world_env and _world_env.environment and _world_env.environment.sky:
		var sky_mat: Material = _world_env.environment.sky.sky_material
		if sky_mat is ProceduralSkyMaterial:
			var p_sky: ProceduralSkyMaterial = sky_mat as ProceduralSkyMaterial
			var day_factor: float = clamp((sun_altitude + 0.1) / 0.5, 0.0, 1.0)
			
			var target_top: Color = Color(0.02, 0.04, 0.08).lerp(Color(0.28, 0.52, 0.82), day_factor)
			var target_horizon: Color = Color(0.08, 0.12, 0.20).lerp(Color(0.72, 0.78, 0.85), day_factor)
			
			# Weather overcast modification
			if _weather:
				match _weather.current_state:
					WeatherSystem.WeatherState.CLOUDY:
						target_top = target_top.lerp(Color(0.25, 0.28, 0.35), 0.5)
						target_horizon = target_horizon.lerp(Color(0.45, 0.48, 0.55), 0.5)
					WeatherSystem.WeatherState.RAIN:
						target_top = target_top.lerp(Color(0.12, 0.16, 0.22), 0.75)
						target_horizon = target_horizon.lerp(Color(0.35, 0.38, 0.42), 0.7)
					WeatherSystem.WeatherState.DROUGHT:
						target_horizon = target_horizon.lerp(Color(0.85, 0.75, 0.60), 0.35)
						
			p_sky.sky_top_color = target_top
			p_sky.sky_horizon_color = target_horizon
			p_sky.ground_bottom_color = Color(0.01, 0.02, 0.04).lerp(Color(0.18, 0.24, 0.22), day_factor)
			p_sky.ground_horizon_color = p_sky.sky_horizon_color
			
			if _world_env.environment and _world_env.environment.fog_enabled:
				_world_env.environment.fog_light_color = target_horizon.lerp(Color(0.65, 0.75, 0.88), 0.35)
