class_name SpatialAudioDirector
extends Node3D

## Procedural Spatial Audio Director for Living Planet Sandbox.
## Generates clean 16-bit PCM procedural nature soundscapes (CC0 / Clean-Room):
## 1. Ambient mountain wind modulated by WeatherSystem wind speed
## 2. 3D Positional lake shoreline ripples anchored at the Emerald Basin water cove
## 3. Dynamic day forest bird warbles and night cricket trills
## 4. Rain precipitation audio coupled to WeatherEffectsController

var _clock: WorldClock
var _weather: WeatherSystem
var _camera: Node3D

var _player_wind: AudioStreamPlayer
var _player_water: AudioStreamPlayer3D
var _player_rain: AudioStreamPlayer
var _player_birds: AudioStreamPlayer
var _player_crickets: AudioStreamPlayer
var _player_fauna: AudioStreamPlayer

var _bird_timer: float = 3.0
var _fauna_call_timer: float = 12.0

func setup(clock: WorldClock, weather: WeatherSystem, camera: Node3D = null) -> void:
	_clock = clock
	_weather = weather
	_camera = camera

	_setup_wind_audio()
	_setup_lake_water_audio()
	_setup_rain_audio()
	_setup_bird_cricket_audio()
	_setup_fauna_audio()

func _process(delta: float) -> void:
	if not _weather:
		return

	# 1. Modulate wind volume by WeatherSystem wind speed (0.5 to 12.0 m/s)
	if _player_wind and _player_wind.playing:
		var target_db: float = lerpf(-24.0, -8.0, clampf(_weather.wind_speed / 8.0, 0.0, 1.0))
		_player_wind.volume_db = lerpf(_player_wind.volume_db, target_db, delta * 2.0)

	# 2. Modulate rain audio by weather state
	if _player_rain:
		var is_raining: bool = (_weather.current_state == WeatherSystem.WeatherState.RAIN)
		var target_rain_db: float = -12.0 if is_raining else -80.0
		_player_rain.volume_db = lerpf(_player_rain.volume_db, target_rain_db, delta * 3.0)
		if is_raining and not _player_rain.playing:
			_player_rain.play()
		elif not is_raining and _player_rain.volume_db < -70.0 and _player_rain.playing:
			_player_rain.stop()

	# 3. Celestial Day/Night audio crossfade (Birds during day, crickets at night)
	if _clock:
		var is_day: bool = fmod(_clock.simulation_time, 120.0) < 60.0
		if _player_crickets:
			var target_cricket: float = -14.0 if not is_day else -80.0
			_player_crickets.volume_db = lerpf(_player_crickets.volume_db, target_cricket, delta * 2.0)
			if not is_day and not _player_crickets.playing:
				_player_crickets.play()
			elif is_day and _player_crickets.volume_db < -70.0 and _player_crickets.playing:
				_player_crickets.stop()

		if is_day:
			_bird_timer -= delta
			if _bird_timer <= 0.0:
				_bird_timer = randf_range(4.0, 10.0)
				_trigger_bird_warble()

	# 4. Periodic fauna ambient vocalizations (distant stag call / doe snort / wolf howl)
	_fauna_call_timer -= delta
	if _fauna_call_timer <= 0.0:
		_fauna_call_timer = randf_range(16.0, 32.0)
		_trigger_fauna_vocalization()

func _setup_wind_audio() -> void:
	_player_wind = AudioStreamPlayer.new()
	_player_wind.name = "AmbientWindPlayer"
	_player_wind.bus = "Master"
	_player_wind.volume_db = -18.0
	_player_wind.stream = _generate_filtered_noise_wav(2.0, 22050, 420.0)
	add_child(_player_wind)
	_player_wind.play()

func _setup_lake_water_audio() -> void:
	# 3D Positional audio player positioned directly at the Emerald Basin lake cove
	_player_water = AudioStreamPlayer3D.new()
	_player_water.name = "LakeWaterPlayer3D"
	_player_water.position = Vector3(16.0, 0.15, 14.0) # Lake cove center
	_player_water.bus = "Master"
	_player_water.unit_size = 12.0
	_player_water.max_distance = 42.0
	_player_water.volume_db = -6.0
	_player_water.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_player_water.stream = _generate_water_ripple_wav(2.5, 22050)
	add_child(_player_water)
	_player_water.play()

func _setup_rain_audio() -> void:
	_player_rain = AudioStreamPlayer.new()
	_player_rain.name = "RainAudioPlayer"
	_player_rain.bus = "Master"
	_player_rain.volume_db = -80.0
	_player_rain.stream = _generate_rain_wav(1.8, 22050)
	add_child(_player_rain)

func _setup_bird_cricket_audio() -> void:
	_player_crickets = AudioStreamPlayer.new()
	_player_crickets.name = "NightCricketsPlayer"
	_player_crickets.bus = "Master"
	_player_crickets.volume_db = -80.0
	_player_crickets.stream = _generate_cricket_wav(1.5, 22050)
	add_child(_player_crickets)

	_player_birds = AudioStreamPlayer.new()
	_player_birds.name = "DayBirdsPlayer"
	_player_birds.bus = "Master"
	_player_birds.volume_db = -16.0
	add_child(_player_birds)

func _setup_fauna_audio() -> void:
	_player_fauna = AudioStreamPlayer.new()
	_player_fauna.name = "FaunaAudioPlayer"
	_player_fauna.bus = "Master"
	_player_fauna.volume_db = -20.0
	add_child(_player_fauna)

func _trigger_fauna_vocalization() -> void:
	if not _player_fauna:
		return
	var is_day: bool = fmod(_clock.simulation_time, 120.0) < 60.0 if _clock else true
	if is_day:
		# Herbivore contact snort/grunt (~180Hz)
		_player_fauna.stream = _generate_fauna_grunt_wav(0.65, 22050, 180.0)
		_player_fauna.volume_db = -22.0
	else:
		# Distant night wolf howl glide (~310Hz)
		_player_fauna.stream = _generate_wolf_howl_wav(2.2, 22050, 310.0)
		_player_fauna.volume_db = -19.0
	_player_fauna.play()

func _trigger_bird_warble() -> void:
	if not _player_birds:
		return
	_player_birds.stream = _generate_bird_chirp_wav(0.45, 22050, randf_range(2800.0, 3600.0))
	_player_birds.play()

## --- PROCEDURAL 16-BIT PCM AUDIO SYNTHESIS GENERATORS ---

static func _generate_filtered_noise_wav(duration: float, rate: int, cutoff_freq: float) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var last_sample: float = 0.0
	var alpha: float = clampf((cutoff_freq * TAU) / rate, 0.01, 0.95)

	for i in range(num_samples):
		var white: float = (randf() * 2.0 - 1.0) * 0.45
		last_sample += alpha * (white - last_sample)
		var val_16: int = int(clampf(last_sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = byte_data
	return wav

static func _generate_water_ripple_wav(duration: float, rate: int) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var lpf: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		# Low frequency rhythmic swell
		var swell: float = sin(t * 1.8) * 0.35 + sin(t * 3.4) * 0.15
		var white: float = (randf() * 2.0 - 1.0) * (0.20 + swell * 0.15)
		lpf += 0.06 * (white - lpf)
		var val_16: int = int(clampf(lpf * 1.8, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = byte_data
	return wav

static func _generate_rain_wav(duration: float, rate: int) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var lpf: float = 0.0
	for i in range(num_samples):
		var white: float = (randf() * 2.0 - 1.0) * 0.35
		# Rain has a higher frequency hiss with micro drops
		lpf += 0.28 * (white - lpf)
		var val_16: int = int(clampf(lpf, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = byte_data
	return wav

static func _generate_cricket_wav(duration: float, rate: int) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		# Rapid pulse envelope at 16 Hz
		var pulse: float = pow(maxf(0.0, sin(t * 16.0 * PI)), 4.0)
		# High frequency cricket chirp at ~4400 Hz
		var tone: float = sin(t * 4400.0 * TAU) * pulse * 0.22
		var val_16: int = int(clampf(tone, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = byte_data
	return wav

static func _generate_bird_chirp_wav(duration: float, rate: int, base_freq: float) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var envelope: float = sin((t / duration) * PI) * 0.35
		# Frequency modulated warble
		var freq: float = base_freq + sin(t * 28.0) * 450.0 + (t / duration) * 300.0
		phase += (freq * TAU) / float(rate)
		var sample: float = sin(phase) * envelope
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_fauna_grunt_wav(duration: float, rate: int, base_freq: float) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var envelope: float = sin((t / duration) * PI) * 0.28
		var freq: float = base_freq * (1.0 - (t / duration) * 0.25) + sin(t * 40.0) * 15.0
		phase += (freq * TAU) / float(rate)
		var sample: float = sin(phase) * envelope
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_wolf_howl_wav(duration: float, rate: int, base_freq: float) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var norm_t: float = t / duration
		var envelope: float = sin(norm_t * PI) * 0.25
		var pitch_arch: float = sin(norm_t * PI) * 110.0
		var freq: float = base_freq + pitch_arch + sin(t * 12.0) * 8.0
		phase += (freq * TAU) / float(rate)
		var sample: float = sin(phase) * envelope
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
