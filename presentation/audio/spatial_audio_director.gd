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
var _player_fauna: AudioStreamPlayer3D
var _player_music: AudioStreamPlayer = null
var _fauna_voices: Array[AudioStreamPlayer3D] = []
var _fauna_voice_idx: int = 0
var _last_alarm_sound_time: float = -10.0

var _bird_timer: float = 3.0
var _fauna_call_timer: float = 12.0
var _music_timer: float = 30.0
var _startup_fade: float = 0.0
var _ambience_volume_scale: float = 0.85

var _event_bus: WorldEventBus = null

# Pre-cached procedural audio streams (eliminates runtime frame hitching on event triggers)
var _cached_discovery_chime: AudioStreamWAV = null
var _cached_wolf_howl: AudioStreamWAV = null
var _cached_deer_snort: AudioStreamWAV = null
var _cached_fauna_grunt: AudioStreamWAV = null
var _cached_stag_belling: AudioStreamWAV = null
var _village_cue_cooldown: float = 0.0
var _castle_cue_cooldown: float = 0.0
static var _cached_village_marimba: AudioStreamWAV = null
static var _cached_castle_choir: AudioStreamWAV = null

func setup(clock: WorldClock, weather: WeatherSystem, camera: Node3D = null, event_bus: WorldEventBus = null) -> void:
	_clock = clock
	_weather = weather
	_camera = camera
	_event_bus = event_bus

	_setup_wind_audio()
	_setup_lake_water_audio()
	_setup_rain_audio()
	_setup_bird_cricket_audio()
	_setup_fauna_audio()
	_setup_music_audio()
	expand_fauna_voice_pool(8)

	# Pre-cache event sound effects once at startup
	_cached_discovery_chime = _generate_discovery_chime_wav(1.35, 22050)
	_cached_wolf_howl = _generate_wolf_howl_wav(2.0, 22050, 320.0)
	_cached_deer_snort = _generate_deer_alarm_snort_wav(0.30, 22050)
	_cached_fauna_grunt = _generate_fauna_grunt_wav(0.35, 22050, 220.0)
	_cached_stag_belling = _generate_stag_belling_wav(1.5, 22050)

	if _event_bus:
		_event_bus.subscribe("living_world_event", Callable(self, "_on_living_world_event"))
		_event_bus.subscribe("herd_alarm", Callable(self, "_on_herd_alarm"))
		_event_bus.subscribe("environmental_discovery", Callable(self, "_on_environmental_discovery"))

func _enter_tree() -> void:
	if _player_wind and not _player_wind.playing:
		_player_wind.play()
	if _player_water and not _player_water.playing:
		_player_water.play()

func _on_environmental_discovery(payload: Dictionary) -> void:
	var pos: Vector3 = payload.get("position", Vector3.ZERO)
	var chime: AudioStreamWAV = _cached_discovery_chime if _cached_discovery_chime else _generate_discovery_chime_wav(1.35, 22050)
	if chime and is_inside_tree():
		var target_pos: Vector3 = pos if pos != Vector3.ZERO else (_camera.global_position if _camera else Vector3.ZERO)
		play_fauna_sound_at(chime, target_pos, -12.0, 0.99, 1.01)

func _on_herd_alarm(payload: Dictionary) -> void:
	var pos: Vector3 = payload.get("position", Vector3(10.0, 2.0, 10.0))
	var is_panic: bool = payload.get("panic", false)
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_alarm_sound_time < 0.8:
		return # Anti-clutter cooldown
	_last_alarm_sound_time = now

	if is_panic:
		var snort: AudioStreamWAV = _cached_deer_snort if _cached_deer_snort else _generate_deer_alarm_snort_wav(0.30, 22050)
		play_fauna_sound_at(snort, pos, -16.0, 0.94, 1.06)
	else:
		var grunt: AudioStreamWAV = _cached_fauna_grunt if _cached_fauna_grunt else _generate_fauna_grunt_wav(0.35, 22050, 220.0)
		play_fauna_sound_at(grunt, pos, -19.0, 0.95, 1.05)

func _on_living_world_event(payload: Dictionary) -> void:
	var event_type: String = payload.get("type", "")
	var pos: Vector3 = _player_fauna.position if _player_fauna else Vector3(8.5, 3.2, 4.0)
	if payload.has("position") and payload["position"] is Vector3:
		pos = payload["position"]
	elif payload.has("pos") and payload["pos"] is Vector3:
		pos = payload["pos"]

	if _player_fauna:
		_player_fauna.position = pos
		_player_fauna.pitch_scale = randf_range(0.95, 1.05)

	match event_type:
		"DAWN_CHORUS":
			_trigger_bird_warble()
		"PREDATION_OBSERVED":
			var howl: AudioStreamWAV = _cached_wolf_howl if _cached_wolf_howl else _generate_wolf_howl_wav(2.0, 22050, 320.0)
			play_fauna_sound_at(howl, pos, -16.0)
		"HERD_STAMPEDE":
			var snort: AudioStreamWAV = _cached_deer_snort if _cached_deer_snort else _generate_deer_alarm_snort_wav(0.30, 22050)
			play_fauna_sound_at(snort, pos, -16.0)
		"HERD_ALARM":
			var snort: AudioStreamWAV = _cached_deer_snort if _cached_deer_snort else _generate_deer_alarm_snort_wav(0.30, 22050)
			play_fauna_sound_at(snort, pos, -18.0)
		"DISTANT_WILDLIFE_CALL":
			var belling: AudioStreamWAV = _cached_stag_belling if _cached_stag_belling else _generate_stag_belling_wav(1.5, 22050)
			play_fauna_sound_at(belling, pos, -20.0, 0.92, 1.04)
		"THIRST_MIGRATION":
			if _player_water:
				_player_water.volume_db = -12.0

func _process(delta: float) -> void:
	if not _weather:
		return

	# Smooth startup master fade-in over 2.0 seconds (prevents audio pop/buzz during boot)
	_startup_fade = minf(1.0, _startup_fade + delta * 0.5)
	var startup_attn_db: float = lerpf(-60.0, 0.0, _startup_fade)
	var amb_scale_db: float = linear_to_db(_ambience_volume_scale) if _ambience_volume_scale > 0.01 else -80.0

	# 1. Modulate wind volume by WeatherSystem wind speed (0.5 to 12.0 m/s)
	if _player_wind:
		var target_db: float = lerpf(-26.0, -10.0, clampf(_weather.wind_speed / 8.0, 0.0, 1.0)) + amb_scale_db
		_player_wind.volume_db = lerpf(_player_wind.volume_db, target_db + startup_attn_db, delta * 2.0)

	# 2. Modulate water shoreline ripples
	if _player_water:
		var target_water_db: float = -14.0 + startup_attn_db + amb_scale_db
		_player_water.volume_db = lerpf(_player_water.volume_db, target_water_db, delta * 2.0)

	# 3. Modulate rain audio by weather state
	if _player_rain:
		var is_raining: bool = (_weather.current_state == WeatherSystem.WeatherState.RAIN)
		var gust_boost: float = clampf(_weather.wind_gust * 4.0, 0.0, 5.0)
		var target_rain_db: float = (-14.0 + gust_boost + amb_scale_db) if is_raining else -80.0
		_player_rain.volume_db = lerpf(_player_rain.volume_db, target_rain_db, delta * 3.0)
		if is_raining and not _player_rain.playing:
			if is_inside_tree():
				_player_rain.play()
		elif not is_raining and _player_rain.volume_db < -70.0 and _player_rain.playing:
			_player_rain.stop()

	# 4. Authoritative Celestial Day/Night audio crossfade using WorldClock
	if _clock:
		var sim_hour: float = _clock.get_sim_hour()
		var is_day: bool = _clock.is_daytime()
		var day_phase: float = _clock.get_day_phase()
		var day_factor: float = clampf(sin((day_phase - 0.25) * TAU), 0.0, 1.0)
		var night_factor: float = 1.0 - day_factor

		if _player_crickets:
			var target_cricket: float = lerpf(-80.0, -22.0, night_factor) + amb_scale_db
			_player_crickets.volume_db = lerpf(_player_crickets.volume_db, target_cricket + startup_attn_db, delta * 2.5)
			if night_factor > 0.15 and not _player_crickets.playing:
				if is_inside_tree():
					_player_crickets.play()
			elif night_factor <= 0.15 and _player_crickets.volume_db < -70.0 and _player_crickets.playing:
				_player_crickets.stop()

		if _player_birds:
			var target_birds_db: float = lerpf(-80.0, -18.0, day_factor) + amb_scale_db
			_player_birds.volume_db = lerpf(_player_birds.volume_db, target_birds_db + startup_attn_db, delta * 2.5)
			if is_day and _startup_fade > 0.8:
				_bird_timer -= delta
				if _bird_timer <= 0.0:
					var is_dawn: bool = (sim_hour >= 5.0 and sim_hour <= 8.0)
					_bird_timer = randf_range(2.5, 6.0) if is_dawn else randf_range(5.0, 11.0)
					_trigger_bird_warble()

	# 5. Periodic fauna ambient vocalizations (distant stag call / doe snort / wolf howl)
	if _startup_fade > 0.8:
		_fauna_call_timer -= delta
		if _fauna_call_timer <= 0.0:
			_fauna_call_timer = randf_range(16.0, 32.0)
			_trigger_fauna_vocalization()

		# 6. Periodic gentle ambient exploration musical motif
		_music_timer -= delta
		if _music_timer <= 0.0:
			_music_timer = randf_range(50.0, 75.0)
			_trigger_ambient_motif()

		# 7. POI Regional Musical Cues (Block 48)
		_check_poi_regional_music(delta)

func set_ambience_volume_scale(scale: float) -> void:
	_ambience_volume_scale = clampf(scale, 0.0, 1.0)

func get_ambience_volume_scale() -> float:
	return _ambience_volume_scale

func _setup_music_audio() -> void:
	_player_music = AudioStreamPlayer.new()
	_player_music.name = "AmbientMusicPlayer"
	_player_music.bus = "Master"
	_player_music.volume_db = -18.0
	add_child(_player_music)

func _trigger_ambient_motif() -> void:
	if not _player_music or not is_inside_tree() or _ambience_volume_scale <= 0.05:
		return
	var motif: AudioStreamWAV = _generate_ambient_motif_wav(3.6, 22050)
	var amb_scale_db: float = linear_to_db(_ambience_volume_scale) if _ambience_volume_scale > 0.01 else -80.0
	_player_music.volume_db = -18.0 + amb_scale_db
	_player_music.stream = motif
	_player_music.play()

func _setup_wind_audio() -> void:
	_player_wind = AudioStreamPlayer.new()
	_player_wind.name = "AmbientWindPlayer"
	_player_wind.bus = "Master"
	_player_wind.volume_db = -80.0 # Starts silent, fades in smoothly
	_player_wind.stream = _generate_filtered_noise_wav(3.0, 22050, 240.0)
	add_child(_player_wind)
	if is_inside_tree():
		_player_wind.play()

func _setup_lake_water_audio() -> void:
	# 3D Positional audio player positioned directly at the Emerald Basin lake cove
	_player_water = AudioStreamPlayer3D.new()
	_player_water.name = "LakeWaterPlayer3D"
	_player_water.position = Vector3(16.0, 0.15, 14.0) # Lake cove center
	_player_water.bus = "Master"
	_player_water.unit_size = 8.0
	_player_water.max_distance = 42.0
	_player_water.volume_db = -80.0 # Starts silent, fades in smoothly
	_player_water.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_player_water.stream = _generate_water_ripple_wav(3.0, 22050)
	add_child(_player_water)
	if is_inside_tree():
		_player_water.play()

func _setup_rain_audio() -> void:
	_player_rain = AudioStreamPlayer.new()
	_player_rain.name = "RainAudioPlayer"
	_player_rain.bus = "Master"
	_player_rain.volume_db = -80.0
	_player_rain.stream = _generate_rain_wav(6.0, 22050)
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
	_fauna_voices.clear()
	for i in range(3):
		var p: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		p.name = "FaunaAudioPlayer3D" if i == 0 else ("FaunaAudioPlayer3D_" + str(i))
		p.bus = "Master"
		p.unit_size = 8.0
		p.max_distance = 65.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.volume_db = -18.0
		p.position = Vector3(8.5, 3.2, 4.0)
		add_child(p)
		_fauna_voices.append(p)
	_player_fauna = _fauna_voices[0]

func expand_fauna_voice_pool(target_size: int = 8) -> void:
	while _fauna_voices.size() < target_size:
		var idx: int = _fauna_voices.size()
		var p: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		p.name = "FaunaAudioPlayer3D_" + str(idx)
		p.bus = "Master"
		p.unit_size = 8.0
		p.max_distance = 65.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.volume_db = -18.0
		p.position = Vector3(8.5, 3.2, 4.0)
		add_child(p)
		_fauna_voices.append(p)

func get_active_voice_count() -> int:
	var count: int = 0
	for v in _fauna_voices:
		if v != null and v.playing:
			count += 1
	return count

func get_max_voice_count() -> int:
	return _fauna_voices.size()

func play_distant_fauna_call(stream: AudioStream, sector_idx: int) -> AudioStreamPlayer3D:
	var sec_centers: Array[Vector3] = [
		Vector3(-25.0, 4.5, -25.0), # NW
		Vector3(25.0, 4.5, -25.0),  # NE
		Vector3(-25.0, 4.5, 25.0),  # SW
		Vector3(25.0, 4.5, 25.0)    # SE
	]
	var pos: Vector3 = sec_centers[clampi(sector_idx, 0, 3)]
	return play_fauna_sound_at(stream, pos, -22.0, 0.92, 1.05)


func play_fauna_sound_at(stream: AudioStream, pos: Vector3, vol_db: float, min_pitch: float = 0.94, max_pitch: float = 1.06) -> AudioStreamPlayer3D:
	if stream == null or _fauna_voices.is_empty():
		return null

	var chosen: AudioStreamPlayer3D = null
	for v in _fauna_voices:
		if not v.playing:
			chosen = v
			break
	if chosen == null:
		_fauna_voice_idx = (_fauna_voice_idx + 1) % _fauna_voices.size()
		chosen = _fauna_voices[_fauna_voice_idx]

	chosen.position = pos
	chosen.stream = stream
	chosen.volume_db = vol_db
	chosen.pitch_scale = randf_range(min_pitch, max_pitch)

	# Mirror on primary player for contract test inspection
	if _player_fauna:
		_player_fauna.position = pos
		_player_fauna.pitch_scale = chosen.pitch_scale
		_player_fauna.stream = stream
		_player_fauna.volume_db = vol_db

	if is_inside_tree():
		chosen.play()
	return chosen

func trigger_fauna_vocalization_at(pos: Vector3, is_predator: bool) -> void:
	if is_predator:
		play_fauna_sound_at(_generate_wolf_howl_wav(2.4, 22050, randf_range(295.0, 325.0)), pos, -15.0)
	else:
		play_fauna_sound_at(_generate_fauna_grunt_wav(0.55, 22050, randf_range(175.0, 205.0)), pos, -18.0)

func _trigger_fauna_vocalization() -> void:
	if not _player_fauna:
		return
	var is_day: bool = _clock.is_daytime() if _clock else true
	_player_fauna.pitch_scale = randf_range(0.95, 1.05)
	if is_day:
		# Herbivore contact snort/grunt (~180Hz) positioned near meadow glade
		_player_fauna.position = Vector3(randf_range(6.0, 11.0), 3.2, randf_range(2.0, 5.5))
		_player_fauna.stream = _generate_fauna_grunt_wav(0.65, 22050, randf_range(175.0, 195.0))
		_player_fauna.volume_db = -18.0
	else:
		# Distant night wolf howl glide (~310Hz) positioned along northern ridge
		_player_fauna.position = Vector3(randf_range(-20.0, -12.0), 16.5, randf_range(-22.0, -14.0))
		_player_fauna.stream = _generate_wolf_howl_wav(2.2, 22050, randf_range(305.0, 325.0))
		_player_fauna.volume_db = -15.0
	if is_inside_tree():
		_player_fauna.play()

func _trigger_bird_warble() -> void:
	if not _player_birds:
		return
	_player_birds.pitch_scale = randf_range(0.96, 1.04)
	_player_birds.stream = _generate_bird_chirp_wav(0.45, 22050, randf_range(2800.0, 3600.0))
	if is_inside_tree():
		_player_birds.play()

## --- PROCEDURAL 16-BIT PCM AUDIO SYNTHESIS GENERATORS ---

static func _apply_loop_crossfade(data: PackedByteArray, num_samples: int, crossfade_samples: int = 1024) -> void:
	if crossfade_samples * 2 >= num_samples:
		crossfade_samples = num_samples / 4
	for k in range(crossfade_samples):
		var weight: float = float(k) / float(crossfade_samples)
		# Smooth S-curve raised-cosine window
		var smooth_w: float = 0.5 * (1.0 - cos(weight * PI))
		var start_idx: int = k * 2
		var end_idx: int = (num_samples - crossfade_samples + k) * 2
		var s_start: float = float(data.decode_s16(start_idx)) / 32767.0
		var s_end: float = float(data.decode_s16(end_idx)) / 32767.0
		var blended: float = s_end * (1.0 - smooth_w) + s_start * smooth_w
		var blended_16: int = int(clampf(blended, -1.0, 1.0) * 32767.0)
		data.encode_s16(end_idx, blended_16)
		data.encode_s16(start_idx, blended_16)

static func _generate_filtered_noise_wav(duration: float, rate: int, cutoff_freq: float) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var b0: float = 0.0
	var b1: float = 0.0
	var alpha: float = clampf((cutoff_freq * TAU) / rate, 0.005, 0.35)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		# Gentle low-frequency mountain swell
		var gust: float = 0.75 + 0.25 * sin(t * 1.5) + 0.12 * sin(t * 0.6)
		var white: float = (randf() * 2.0 - 1.0) * 0.28 * gust
		# 2-pole lowpass filter for deep soothing mountain wind (no harsh static or radio hiss)
		b0 += alpha * (white - b0)
		b1 += alpha * (b0 - b1)
		var val_16: int = int(clampf(b1 * 1.9, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	_apply_loop_crossfade(byte_data, num_samples, int(rate * 0.10))

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
	var lpf2: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		# Low frequency rhythmic lake swell (water lapping gently against sand)
		var swell: float = sin(t * 1.9) * 0.35 + sin(t * 3.7) * 0.15
		var white: float = (randf() * 2.0 - 1.0) * (0.10 + maxf(0.0, swell) * 0.12)
		lpf += 0.035 * (white - lpf)
		lpf2 += 0.045 * (lpf - lpf2)
		var val_16: int = int(clampf(lpf2 * 2.2, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	_apply_loop_crossfade(byte_data, num_samples, int(rate * 0.10))

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
	var crossfade_samples: int = int(rate * 0.40) # 0.4s smooth circular crossfade
	var total_samples: int = num_samples + crossfade_samples

	var raw_samples: PackedFloat32Array = PackedFloat32Array()
	raw_samples.resize(total_samples)

	var lpf: float = 0.0
	var lpf2: float = 0.0
	for i in range(total_samples):
		var white: float = (randf() * 2.0 - 1.0) * 0.22
		# Dual-stage gentle raindrop patter filter
		lpf += 0.22 * (white - lpf)
		lpf2 += 0.14 * (lpf - lpf2)
		raw_samples[i] = lpf2 * 1.8

	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var s: float = raw_samples[i]
		if i < crossfade_samples:
			var w: float = float(i) / float(crossfade_samples)
			var smooth_w: float = 0.5 * (1.0 - cos(w * PI))
			var tail_s: float = raw_samples[num_samples + i]
			s = tail_s * (1.0 - smooth_w) + s * smooth_w
		var val_16: int = int(clampf(s, -1.0, 1.0) * 32767.0)
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
		# Natural rhythmic chirping pattern: 3 quick chirps followed by quiet pause (cycle length 1.2s)
		var cycle_t: float = fmod(t, 1.2)
		var chirp_amp: float = 0.0
		if cycle_t < 0.36:
			var sub_t: float = fmod(cycle_t, 0.12)
			if sub_t < 0.07:
				chirp_amp = sin((sub_t / 0.07) * PI)
		# Harmonious soft nocturnal cricket chirp (~3600 Hz + harmonic ~7200 Hz), no harsh 16Hz square buzzing
		var tone: float = (sin(t * 3600.0 * TAU) * 0.75 + sin(t * 7200.0 * TAU) * 0.25) * chirp_amp * 0.09
		var val_16: int = int(clampf(tone, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	_apply_loop_crossfade(byte_data, num_samples, int(rate * 0.08))

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

static func _generate_deer_alarm_snort_wav(duration: float = 0.35, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	# Dual bandpass resonators for nasal passage formant simulation (1850 Hz & 3100 Hz)
	var bp1_y1: float = 0.0
	var bp1_y2: float = 0.0
	var bp2_y1: float = 0.0
	var bp2_y2: float = 0.0
	var pop_phase: float = 0.0

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		# Rapid 12ms attack followed by expulsive nasal air decay
		var env: float = 0.0
		if t < 0.012:
			env = t / 0.012
		else:
			env = exp(-(t - 0.012) * 10.5)

		# Initial vocal fold transient pop (first 25ms)
		var pop: float = 0.0
		if t < 0.025:
			pop_phase += (440.0 * TAU) / float(rate)
			pop = sin(pop_phase) * (1.0 - t / 0.025) * 0.35

		# White noise turbulent nasal air
		var white: float = (randf() * 2.0 - 1.0)

		# Resonator 1: ~1850 Hz nasal cavity
		var bp1: float = 0.42 * white + 0.85 * bp1_y1 - 0.35 * bp1_y2
		bp1_y2 = bp1_y1
		bp1_y1 = bp1

		# Resonator 2: ~3100 Hz nostril hiss
		var bp2: float = 0.38 * white + 0.65 * bp2_y1 - 0.45 * bp2_y2
		bp2_y2 = bp2_y1
		bp2_y1 = bp2

		var air_mix: float = (bp1 * 0.60 + bp2 * 0.40) * 0.75
		var sample: float = (air_mix + pop) * env * 0.88
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_wolf_growl_wav(duration: float = 1.4, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var p0: float = 0.0
	var p1: float = 0.0
	var p2: float = 0.0
	var flutter_phase: float = 0.0
	var breath_lp: float = 0.0

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var norm_t: float = t / duration
		var env: float = sin(norm_t * PI) * 0.40
		# Dynamic snarling pitch: rises slightly in mid-growl aggression
		var base_f0: float = 88.0 + sin(norm_t * PI) * 14.0

		p0 += (base_f0 * TAU) / float(rate)
		p1 += (base_f0 * 2.0 * TAU) / float(rate)
		p2 += (base_f0 * 3.0 * TAU) / float(rate)

		# 38 Hz glottal rasp modulation
		flutter_phase += (38.0 * TAU) / float(rate)
		var rasp: float = 0.65 + 0.35 * sin(flutter_phase)

		# Multi-harmonic vocal body with asymmetric tanh saturation
		var raw_vocal: float = sin(p0) * 0.55 + sin(p1) * 0.30 + sin(p2) * 0.15
		var saturated_vocal: float = tanh(raw_vocal * 1.6) * rasp

		# Upper breath friction hiss
		var noise_val: float = (randf() * 2.0 - 1.0)
		breath_lp += 0.22 * (noise_val - breath_lp)
		var breath: float = breath_lp * 0.16

		var sample: float = (saturated_vocal + breath) * env
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_stag_belling_wav(duration: float = 1.6, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var p0: float = 0.0
	var p1: float = 0.0
	var p2: float = 0.0
	var throat_phase: float = 0.0

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var norm_t: float = t / duration

		# Bell envelope: gentle swell, sustained body, smooth taper
		var env: float = sin(norm_t * PI)
		env = pow(env, 0.75) * 0.45

		# Pitch contour: deep resonant guttural throat belling gliding 112 -> 132 -> 118 Hz
		var f0: float = 112.0 + sin(norm_t * PI) * 20.0
		p0 += (f0 * TAU) / float(rate)
		p1 += (f0 * 2.0 * TAU) / float(rate)
		p2 += (f0 * 3.0 * TAU) / float(rate)

		# 22 Hz guttural flutter
		throat_phase += (22.0 * TAU) / float(rate)
		var throat_mod: float = 0.72 + 0.28 * sin(throat_phase)

		var vocal_core: float = (sin(p0) * 0.58 + sin(p1) * 0.28 + sin(p2) * 0.14) * throat_mod
		var saturated: float = tanh(vocal_core * 1.8)

		var sample: float = saturated * env
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_rustle_foliage_wav(duration: float = 0.35, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var bp1_y1: float = 0.0
	var bp1_y2: float = 0.0

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var norm_t: float = t / duration

		# Rapid crisp attack, quick decay
		var env: float = (1.0 - norm_t) * sin(norm_t * PI * 1.5)
		env = maxf(0.0, env) * 0.35

		var white: float = (randf() * 2.0 - 1.0)
		# 2400 Hz foliage crackle bandpass resonator
		var bp: float = 0.40 * white + 0.72 * bp1_y1 - 0.38 * bp1_y2
		bp1_y2 = bp1_y1
		bp1_y1 = bp

		var sample: float = bp * env
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_discovery_chime_wav(duration: float = 1.35, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	# Frequencies for open fifth / major chord: 523.25 Hz (C5), 659.25 Hz (E5), 783.99 Hz (G5), 1046.5 Hz (C6)
	var freqs: Array[float] = [523.25, 659.25, 783.99, 1046.5]
	var amps: Array[float] = [0.25, 0.18, 0.15, 0.10]
	var decay_rates: Array[float] = [2.2, 2.8, 3.4, 4.2]
	var phases: Array[float] = [0.0, 0.0, 0.0, 0.0]

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var sample: float = 0.0

		# 8ms soft attack
		var attack: float = minf(1.0, t / 0.008)

		for k in range(4):
			phases[k] += (freqs[k] * TAU) / float(rate)
			var env: float = attack * exp(-t * decay_rates[k]) * amps[k]
			sample += sin(phases[k]) * env

		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_ambient_motif_wav(duration: float = 3.6, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	# Gentle pentatonic acoustic chime motif: D4 (293.66 Hz), F#4 (369.99 Hz), A4 (440.00 Hz), D5 (587.33 Hz)
	var notes: Array[float] = [293.66, 369.99, 440.00, 587.33]
	var note_times: Array[float] = [0.0, 0.45, 0.90, 1.35]
	var note_amps: Array[float] = [0.22, 0.20, 0.18, 0.24]
	var decay: float = 1.35

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var sample: float = 0.0

		for k in range(notes.size()):
			var note_t: float = t - note_times[k]
			if note_t >= 0.0:
				var attack: float = minf(1.0, note_t / 0.02)
				var env: float = attack * exp(-note_t * decay) * note_amps[k]
				var fundamental: float = sin(note_t * notes[k] * TAU)
				var overtone: float = sin(note_t * notes[k] * 2.0 * TAU) * 0.25
				sample += (fundamental + overtone) * env

		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

func _check_poi_regional_music(delta: float) -> void:
	if _village_cue_cooldown > 0.0:
		_village_cue_cooldown = maxf(0.0, _village_cue_cooldown - delta)
	if _castle_cue_cooldown > 0.0:
		_castle_cue_cooldown = maxf(0.0, _castle_cue_cooldown - delta)

	if not _camera or _ambience_volume_scale <= 0.05 or not is_inside_tree():
		return

	var cam_pos: Vector3 = _camera.global_position if _camera.is_inside_tree() else _camera.position

	# Check Haven Village Square (Vector3(32.0, 3.5, 62.0))
	var dist_village: float = Vector2(cam_pos.x - 32.0, cam_pos.z - 62.0).length()
	if dist_village < 38.0 and _village_cue_cooldown <= 0.0:
		_village_cue_cooldown = 50.0
		_play_village_cue()
		return

	# Check Castle Citadel Keep (Vector3(-36.0, 16.0, -42.0))
	var dist_castle: float = Vector2(cam_pos.x + 36.0, cam_pos.z + 42.0).length()
	if dist_castle < 42.0 and _castle_cue_cooldown <= 0.0:
		_castle_cue_cooldown = 50.0
		_play_castle_cue()

func _play_village_cue() -> void:
	if not _player_music or not is_inside_tree():
		return
	if _cached_village_marimba == null:
		_cached_village_marimba = _generate_village_marimba_wav(4.2, 22050)
	var amb_scale_db: float = linear_to_db(_ambience_volume_scale) if _ambience_volume_scale > 0.01 else -80.0
	_player_music.volume_db = -16.0 + amb_scale_db
	_player_music.stream = _cached_village_marimba
	_player_music.play()

func _play_castle_cue() -> void:
	if not _player_music or not is_inside_tree():
		return
	if _cached_castle_choir == null:
		_cached_castle_choir = _generate_castle_choir_wav(4.5, 22050)
	var amb_scale_db: float = linear_to_db(_ambience_volume_scale) if _ambience_volume_scale > 0.01 else -80.0
	_player_music.volume_db = -15.0 + amb_scale_db
	_player_music.stream = _cached_castle_choir
	_player_music.play()

static func _generate_village_marimba_wav(duration: float = 4.2, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	# Uplifting Celtic/Anime village marimba arpeggio: G4, B4, D5, E5, G5, D5
	var notes: Array[float] = [392.00, 493.88, 587.33, 659.25, 783.99, 587.33]
	var note_times: Array[float] = [0.0, 0.40, 0.80, 1.20, 1.70, 2.30]
	var note_amps: Array[float] = [0.24, 0.22, 0.26, 0.24, 0.28, 0.20]
	var decay: float = 2.1

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var sample: float = 0.0

		for k in range(notes.size()):
			var note_t: float = t - note_times[k]
			if note_t >= 0.0:
				var attack: float = minf(1.0, note_t / 0.005) # 5ms wooden attack
				var env: float = attack * exp(-note_t * decay) * note_amps[k]
				var fundamental: float = sin(note_t * notes[k] * TAU)
				var overtone: float = sin(note_t * notes[k] * 2.76 * TAU) * 0.22
				sample += (fundamental + overtone) * env

		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_castle_choir_wav(duration: float = 4.5, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	# Ethereal solemn minor cathedral chord pad: A3 (220Hz), C4 (261.6Hz), E4 (329.6Hz), A4 (440Hz)
	var freqs: Array[float] = [220.00, 261.63, 329.63, 440.00]
	var amps: Array[float] = [0.22, 0.18, 0.20, 0.15]

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var norm_t: float = t / duration
		var attack: float = minf(1.0, t / 0.85)
		var decay: float = 1.0 - pow(norm_t, 2.2)
		var envelope: float = attack * decay

		var sample: float = 0.0
		var vibrato: float = sin(t * 5.5 * TAU) * 1.8

		for k in range(freqs.size()):
			var f: float = freqs[k] + vibrato
			var voice: float = sin(t * f * TAU) + sin(t * f * 2.0 * TAU) * 0.35 + sin(t * f * 3.0 * TAU) * 0.15
			sample += voice * amps[k]

		sample *= envelope * 0.75
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

