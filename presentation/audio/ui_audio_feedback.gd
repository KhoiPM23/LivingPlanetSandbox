class_name UIAudioFeedback
extends Node

## Procedural UI Audio Synthesizer for Living Planet Sandbox.
## Generates clean 16-bit PCM procedural sound effects in memory (zero external asset dependencies):
## - play_hover(): Subtle 1100Hz soft blip (20ms) for UI button hover
## - play_click(): Crisp 750Hz -> 500Hz mechanical confirm click (35ms)
## - play_modal_open(): Gentle upward airy swoosh (300Hz -> 650Hz, 80ms)
## - play_modal_close(): Gentle downward airy swoosh (650Hz -> 300Hz, 80ms)
## - play_discovery(): Resonant major triad chord (C5 + E5 + G5, 900ms) with harmonic decay
## - play_milestone(): Majestic fanfare chord (C4 + G4 + C5 + E5, 1.6s) with bell shimmer

static var _instance = null

var _player_ui: AudioStreamPlayer = null
var _player_chime: AudioStreamPlayer = null

var _sfx_volume_scale: float = 0.85

var _hover_wav: AudioStreamWAV = null
var _click_wav: AudioStreamWAV = null
var _open_wav: AudioStreamWAV = null
var _close_wav: AudioStreamWAV = null
var _discovery_wav: AudioStreamWAV = null
var _milestone_wav: AudioStreamWAV = null
var _shutter_wav: AudioStreamWAV = null
var _quest_wav: AudioStreamWAV = null
var _filter_click_wav: AudioStreamWAV = null
var _tape_whir_wav: AudioStreamWAV = null
var _tape_stop_wav: AudioStreamWAV = null

func _init() -> void:
	_instance = self
	_generate_all_streams()

func _ready() -> void:
	_player_ui = AudioStreamPlayer.new()
	_player_ui.name = "UIPlayerSFX"
	_player_ui.bus = "Master"
	add_child(_player_ui)

	_player_chime = AudioStreamPlayer.new()
	_player_chime.name = "UIPlayerChime"
	_player_chime.bus = "Master"
	add_child(_player_chime)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _instance == self:
			_instance = null

static func get_singleton():
	if is_instance_valid(_instance):
		return _instance
	_instance = null
	return null

func set_sfx_volume_scale(scale_val: float) -> void:
	_sfx_volume_scale = clampf(scale_val, 0.0, 1.0)

func play_hover() -> void:
	if _sfx_volume_scale <= 0.01 or not _player_ui:
		return
	_player_ui.stream = _hover_wav
	_player_ui.volume_db = linear_to_db(_sfx_volume_scale * 0.45)
	_player_ui.pitch_scale = randf_range(0.98, 1.02)
	_player_ui.play()

func play_click() -> void:
	if _sfx_volume_scale <= 0.01 or not _player_ui:
		return
	_player_ui.stream = _click_wav
	_player_ui.volume_db = linear_to_db(_sfx_volume_scale * 0.75)
	_player_ui.pitch_scale = randf_range(0.97, 1.03)
	_player_ui.play()

func play_modal_open() -> void:
	if _sfx_volume_scale <= 0.01 or not _player_ui:
		return
	_player_ui.stream = _open_wav
	_player_ui.volume_db = linear_to_db(_sfx_volume_scale * 0.6)
	_player_ui.pitch_scale = 1.0
	_player_ui.play()

func play_modal_close() -> void:
	if _sfx_volume_scale <= 0.01 or not _player_ui:
		return
	_player_ui.stream = _close_wav
	_player_ui.volume_db = linear_to_db(_sfx_volume_scale * 0.55)
	_player_ui.pitch_scale = 1.0
	_player_ui.play()

func play_discovery() -> void:
	if _sfx_volume_scale <= 0.01 or not _player_chime:
		return
	_player_chime.stream = _discovery_wav
	_player_chime.volume_db = linear_to_db(_sfx_volume_scale * 0.85)
	_player_chime.pitch_scale = 1.0
	_player_chime.play()

func play_milestone() -> void:
	if _sfx_volume_scale <= 0.01 or not _player_chime:
		return
	_player_chime.stream = _milestone_wav
	_player_chime.volume_db = linear_to_db(_sfx_volume_scale * 0.95)
	_player_chime.pitch_scale = 1.0
	_player_chime.play()

func play_shutter() -> void:
	if _sfx_volume_scale <= 0.01 or not _player_ui:
		return
	_player_ui.stream = _shutter_wav
	_player_ui.volume_db = linear_to_db(_sfx_volume_scale * 0.90)
	_player_ui.pitch_scale = 1.0
	_player_ui.play()

func play_quest_complete() -> void:
	if _sfx_volume_scale <= 0.01 or not _player_chime:
		return
	_player_chime.stream = _quest_wav
	_player_chime.volume_db = linear_to_db(_sfx_volume_scale * 0.90)
	_player_chime.pitch_scale = 1.0
	_player_chime.play()

func play_filter_click() -> void:
	if _sfx_volume_scale <= 0.01 or not _player_ui:
		return
	_player_ui.stream = _filter_click_wav
	_player_ui.volume_db = linear_to_db(_sfx_volume_scale * 0.85)
	_player_ui.pitch_scale = 1.0
	_player_ui.play()

func play_tape_record() -> void:
	if _sfx_volume_scale <= 0.01 or not _player_ui:
		return
	_player_ui.stream = _tape_whir_wav
	_player_ui.volume_db = linear_to_db(_sfx_volume_scale * 0.90)
	_player_ui.pitch_scale = 1.0
	_player_ui.play()

func play_tape_stop() -> void:
	if _sfx_volume_scale <= 0.01 or not _player_ui:
		return
	_player_ui.stream = _tape_stop_wav
	_player_ui.volume_db = linear_to_db(_sfx_volume_scale * 0.80)
	_player_ui.pitch_scale = 1.0
	_player_ui.play()
	
func play_milestone_fanfare() -> void:
	play_milestone()

func play_item_pickup() -> void:
	play_discovery()

func play_landmark_chime() -> void:
	play_discovery()

func play_quest_accepted() -> void:
	play_modal_open()

func play_button_click() -> void:
	play_click()

# =========================================================================
# PROCEDURAL 16-BIT PCM WAVE SYNTHESIS
# =========================================================================
func _generate_all_streams() -> void:
	_hover_wav = _generate_tone_wav(1100.0, 0.022, 22050, true, 0.3)
	_click_wav = _generate_sweep_wav(750.0, 480.0, 0.038, 22050)
	_open_wav = _generate_sweep_wav(280.0, 680.0, 0.085, 22050)
	_close_wav = _generate_sweep_wav(680.0, 280.0, 0.085, 22050)
	_discovery_wav = _generate_chord_wav([523.25, 659.25, 783.99], 0.95, 22050)
	_milestone_wav = _generate_chord_wav([261.63, 392.0, 523.25, 659.25], 1.6, 22050, true)
	_shutter_wav = _generate_shutter_pcm(0.12, 22050)
	_quest_wav = _generate_chord_wav([349.23, 440.0, 523.25, 659.25], 1.25, 22050, true)
	_filter_click_wav = _generate_sweep_wav(850.0, 1400.0, 0.025, 22050)
	_tape_whir_wav = _generate_tape_whir_pcm(0.18, 22050)
	_tape_stop_wav = _generate_sweep_wav(420.0, 210.0, 0.045, 22050)

static func _generate_tape_whir_pcm(duration: float, sample_rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * float(sample_rate))
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	var noise_state: float = 0.42
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var sample: float = 0.0
		if t < 0.035:
			sample += sin(TAU * (980.0 - t * 14000.0) * t) * 0.75
		var whir_env: float = clampf(t / 0.02, 0.0, 1.0) * (1.0 - t / duration)
		sample += (sin(TAU * 128.0 * t) * 0.45 + sin(TAU * 256.0 * t) * 0.25) * whir_env
		noise_state = fmod(noise_state * 31.4159 + 0.1234, 1.0)
		sample += (noise_state * 2.0 - 1.0) * 0.06 * whir_env

		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, s16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

static func _generate_shutter_pcm(duration: float, sample_rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * float(sample_rate))
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	var noise_state: float = 0.53
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var sample: float = 0.0

		# Phase 1: 0.00s - 0.03s: Front shutter curtain release (crisp mechanical click 1200Hz -> 600Hz)
		if t < 0.03:
			var env1: float = pow(1.0 - (t / 0.03), 3.0)
			noise_state = fmod(noise_state * 31.0 + 0.17, 1.0)
			var click1: float = (noise_state * 2.0 - 1.0) * 0.7 + sin(t * 1100.0 * TAU) * 0.3
			sample = click1 * env1 * 0.85
		# Phase 2: 0.045s - 0.09s: Rear shutter closure & mirror slap (crisp mechanical slap 700Hz -> 300Hz)
		elif t >= 0.045 and t < 0.09:
			var t2: float = t - 0.045
			var env2: float = pow(1.0 - (t2 / 0.045), 2.5)
			noise_state = fmod(noise_state * 37.0 + 0.23, 1.0)
			var slap: float = (noise_state * 2.0 - 1.0) * 0.6 + sin(t2 * 450.0 * TAU) * 0.4
			sample = slap * env2 * 0.90

		var sample_i16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, sample_i16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

static func _generate_tone_wav(freq: float, duration: float, sample_rate: int = 22050, exp_decay: bool = true, peak_amp: float = 0.5) -> AudioStreamWAV:
	var num_samples: int = int(duration * float(sample_rate))
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = 1.0
		if exp_decay:
			env = exp(-t * (4.0 / duration))
		var sample_f: float = sin(TAU * freq * t) * env * peak_amp
		var sample_i16: int = clampi(int(sample_f * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, sample_i16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

static func _generate_sweep_wav(freq_start: float, freq_end: float, duration: float, sample_rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * float(sample_rate))
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	var phase: float = 0.0
	for i in range(num_samples):
		var frac: float = float(i) / float(num_samples)
		var cur_freq: float = lerpf(freq_start, freq_end, frac)
		phase += TAU * cur_freq / float(sample_rate)
		if phase > TAU:
			phase -= TAU
		var env: float = sin(frac * PI) * (1.0 - frac * 0.4)
		var sample_f: float = sin(phase) * env * 0.45
		var sample_i16: int = clampi(int(sample_f * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, sample_i16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

static func _generate_chord_wav(frequencies: Array, duration: float, sample_rate: int = 22050, add_shimmer: bool = false) -> AudioStreamWAV:
	var num_samples: int = int(duration * float(sample_rate))
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	var note_count: float = float(frequencies.size())
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var frac: float = t / duration

		# Smooth attack (25ms) + exponential release
		var attack: float = clampf(t / 0.025, 0.0, 1.0)
		var decay: float = exp(-t * (3.2 / duration))
		var env: float = attack * decay

		var sum_wave: float = 0.0
		for freq in frequencies:
			var f_val: float = float(freq)
			sum_wave += sin(TAU * f_val * t) + 0.35 * sin(TAU * f_val * 2.0 * t)

		if add_shimmer:
			sum_wave += 0.25 * sin(TAU * 1318.5 * t) * (1.0 - frac)

		var sample_f: float = (sum_wave / (note_count * 1.3)) * env * 0.65
		var sample_i16: int = clampi(int(sample_f * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, sample_i16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav
