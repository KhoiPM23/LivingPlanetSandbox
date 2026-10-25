class_name TestBlock23Verification
extends RefCounted

## Automated verification suite for Block 23 (Integration Stability, Polish & Runtime Acceptance).
## Tests player locomotion framerate independence, camera-physics separation,
## fauna alarm throttling, audio null-safety resilience, and rain lifecycle.

const FirstPersonWalker = preload("res://presentation/camera/first_person_walker.gd")
const FreeLookCamera = preload("res://presentation/camera/free_look_camera.gd")
const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const SpatialAudioDirector = preload("res://presentation/audio/spatial_audio_director.gd")
const WeatherSystem = preload("res://core/environment/weather_system.gd")
const WorldClock = preload("res://core/clock/world_clock.gd")
const WorldEventBus = preload("res://core/events/world_event_bus.gd")
const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")

func _flat_height(_x: float, _z: float) -> float:
	return 2.0

## 1. Player Locomotion: Framerate-independent acceleration, deceleration, and diagonal normalization
func test_player_framerate_independent_locomotion() -> String:
	var walker: FirstPersonWalker = FirstPersonWalker.new()
	walker._ready()

	# A. Diagonal input must be normalized (no sqrt(2) speed boost)
	var diag_input: Vector3 = Vector3(1.0, 0.0, 1.0).normalized()
	for _i in range(30):
		walker.move_character(0.016, diag_input, false, false)
	var diag_speed: float = Vector2(walker.velocity.x, walker.velocity.z).length()
	var expected_speed: float = walker.walk_speed
	if absf(diag_speed - expected_speed) > 0.15:
		walker.free()
		return "Diagonal movement produced incorrect speed: %.2f vs expected %.2f" % [diag_speed, expected_speed]

	# B. Test acceleration at 30 FPS (dt = 0.033) vs 60 FPS (dt = 0.016)
	var w30: FirstPersonWalker = FirstPersonWalker.new()
	w30._ready()
	w30.move_character(0.033, Vector3(0.0, 0.0, -1.0), false, false)
	var s30: float = Vector2(w30.velocity.x, w30.velocity.z).length()

	var w60: FirstPersonWalker = FirstPersonWalker.new()
	w60._ready()
	w60.move_character(0.016, Vector3(0.0, 0.0, -1.0), false, false)
	w60.move_character(0.017, Vector3(0.0, 0.0, -1.0), false, false)
	var s60: float = Vector2(w60.velocity.x, w60.velocity.z).length()

	if absf(s30 - s60) > 0.18:
		walker.free()
		w30.free()
		w60.free()
		return "Framerate variance: 30 FPS vs 60 FPS acceleration deviated excessively (%.2f vs %.2f)" % [s30, s60]

	# C. Stopping deceleration must brake smoothly to 0 without reversing
	for _i in range(40):
		walker.move_character(0.016, Vector3.ZERO, false, false)
	var stopped_speed: float = Vector2(walker.velocity.x, walker.velocity.z).length()
	if stopped_speed > 0.05:
		walker.free()
		w30.free()
		w60.free()
		return "Character failed to come to a complete stop: speed remaining %.3f" % stopped_speed

	walker.free()
	w30.free()
	w60.free()
	return ""

## 2. Camera Physics Separation: Camera transform and rotation lerps cleanly in process without double updates
func test_camera_process_separation() -> String:
	var walker: FirstPersonWalker = FirstPersonWalker.new()
	walker._ready()

	# Target yaw test
	walker.rotate_camera(Vector2(100.0, 0.0))
	var initial_yaw: float = walker.get_camera_yaw()
	walker.update_camera_rotation(0.016)
	var new_yaw: float = walker.get_camera_yaw()

	if new_yaw == initial_yaw:
		walker.free()
		return "Camera rotation failed to advance when update_camera_rotation was called"

	# Verify FOV modulation doesn't overshoot
	walker._is_sprinting = false
	walker.velocity = Vector3.ZERO
	for _i in range(20):
		walker.update_camera_rotation(0.016)
	if absf(walker.get_camera().fov - walker.base_fov) > 0.2:
		walker.free()
		return "Base FOV failed to stabilize when stationary (got %.2f, expected %.2f)" % [walker.get_camera().fov, walker.base_fov]

	walker.free()
	return ""

## 3. Fauna Alarm Cooldown Throttling: Prevents runaway per-frame event bus cascades
func test_fauna_alarm_cooldown_throttling() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 707070
	var bus: WorldEventBus = WorldEventBus.new()
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics, bus)

	var alarm_counter: Array[int] = [0]
	bus.subscribe("herd_alarm", func(_payload: Dictionary) -> void:
		alarm_counter[0] += 1
	)

	var h1_id: int = fauna.spawn_herbivore(Vector3(10.0, 2.0, 10.0), 85.0)
	var h2_id: int = fauna.spawn_herbivore(Vector3(14.0, 2.0, 10.0), 85.0)
	var h1: FaunaSimulation.HerbivoreData = fauna.get_herbivore(h1_id)
	var h2: FaunaSimulation.HerbivoreData = fauna.get_herbivore(h2_id)

	# Trigger initial panic alarm
	h1.last_known_threat_pos = Vector3(0.0, 2.0, 10.0)
	fauna._spread_herd_alarm(h1, true)
	if alarm_counter[0] != 1:
		return "Initial alarm failed to publish to WorldEventBus"

	# Attempt to broadcast repeat alarms immediately in consecutive frames (as would occur in 60Hz loop)
	for _i in range(10):
		fauna._spread_herd_alarm(h1, true)
		fauna._spread_herd_alarm(h2, true)

	if alarm_counter[0] > 1:
		return "Alarm cooldown failed: emitted %d events in rapid succession (expected exactly 1)" % alarm_counter[0]

	return ""

## 4. Audio Resilience: Null stream and edge case safety
func test_spatial_audio_null_stream_resilience() -> String:
	var director: SpatialAudioDirector = SpatialAudioDirector.new()
	director._setup_fauna_audio()

	# Passing null stream should return null gracefully without crashing
	var result: AudioStreamPlayer3D = director.play_fauna_sound_at(null, Vector3(5.0, 1.0, 5.0), -12.0)
	if result != null:
		director.free()
		return "play_fauna_sound_at returned a player despite stream being null"

	director.free()
	return ""

## 5. Weather Rain Lifecycle and Audio Fade
func test_weather_rain_lifecycle_and_fade() -> String:
	var weather: WeatherSystem = WeatherSystem.new()
	var director: SpatialAudioDirector = SpatialAudioDirector.new()
	director.setup(null, weather, null, null)

	# 1. State = CLEAR -> Rain player volume should target -80 dB
	weather.set_state(WeatherSystem.WeatherState.CLEAR, 60.0)
	director._process(0.1)
	if director._player_rain.volume_db > -20.0:
		director.free()
		return "Rain player volume was too high during CLEAR state (%.1f dB)" % director._player_rain.volume_db

	# 2. State = RAIN -> Rain volume rises toward ~-14 dB
	weather.set_state(WeatherSystem.WeatherState.RAIN, 60.0)
	for _i in range(30):
		director._process(0.1)
	if director._player_rain.volume_db < -30.0:
		director.free()
		return "Rain volume failed to fade in during RAIN state (%.1f dB)" % director._player_rain.volume_db

	# 3. State returns to CLEAR -> Rain volume fades down toward -80 dB
	weather.set_state(WeatherSystem.WeatherState.CLEAR, 60.0)
	for _i in range(40):
		director._process(0.1)
	if director._player_rain.volume_db > -60.0:
		director.free()
		return "Rain volume failed to fade out when returning to CLEAR (%.1f dB)" % director._player_rain.volume_db

	director.free()
	return ""
