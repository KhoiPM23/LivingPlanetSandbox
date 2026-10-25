class_name TestBlock32ParabolicMicrophoneAndAcoustics
extends RefCounted

## Automated Contract Suite 39: Block 32 Parabolic Bio-Acoustic Microphone, Directional Spectrogram & Sound Logging

const UIAudioFeedback = preload("res://presentation/audio/ui_audio_feedback.gd")
const FieldCameraOverlay = preload("res://presentation/camera/field_camera_overlay.gd")
const ExpeditionManager = preload("res://core/gameplay/expedition_manager.gd")
const FieldJournalModal = preload("res://presentation/ui/field_journal_modal.gd")

func test_ui_audio_tape_deck_synthesis() -> bool:
	var feedback: UIAudioFeedback = UIAudioFeedback.new()
	if feedback._tape_whir_wav == null or feedback._tape_stop_wav == null:
		feedback.free()
		return false

	if feedback._tape_whir_wav.format != AudioStreamWAV.FORMAT_16_BITS or feedback._tape_whir_wav.mix_rate != 22050:
		feedback.free()
		return false
	if feedback._tape_stop_wav.format != AudioStreamWAV.FORMAT_16_BITS or feedback._tape_stop_wav.mix_rate != 22050:
		feedback.free()
		return false

	if feedback._tape_whir_wav.data.size() < 1000 or feedback._tape_stop_wav.data.size() < 400:
		feedback.free()
		return false

	feedback.play_tape_record()
	feedback.play_tape_stop()
	feedback.free()
	return true

func test_field_camera_acoustic_mode_toggle_and_reticle() -> bool:
	var overlay: FieldCameraOverlay = FieldCameraOverlay.new()
	if overlay.is_acoustic_mode:
		overlay.free()
		return false

	overlay.set_camera_active(true)
	overlay.toggle_acoustic_mode()
	if not overlay.is_acoustic_mode:
		overlay.free()
		return false

	if overlay._reticle == null or not overlay._reticle.text.contains("🎙️"):
		overlay.free()
		return false

	overlay.toggle_acoustic_mode()
	if overlay.is_acoustic_mode:
		overlay.free()
		return false

	overlay.free()
	return true

func test_acoustic_directional_telemetry_and_oscilloscope() -> bool:
	var overlay: FieldCameraOverlay = FieldCameraOverlay.new()
	overlay.set_camera_active(true)
	overlay.set_acoustic_mode(true)

	overlay.update_acoustic_telemetry(45.0, 68.5, 182.0, "Red Deer")

	if overlay.acoustic_bearing != 45.0 or overlay.acoustic_decibels != 68.5 or overlay.acoustic_frequency_hz != 182.0:
		overlay.free()
		return false
	if overlay.acoustic_species != "Red Deer":
		overlay.free()
		return false

	if overlay._oscilloscope_panel == null or not overlay._oscilloscope_panel.visible:
		overlay.free()
		return false
	if overlay._oscilloscope_lbl == null or not overlay._oscilloscope_lbl.text.contains("Red Deer") or not overlay._oscilloscope_lbl.text.contains("182 Hz"):
		overlay.free()
		return false

	overlay.free()
	return true

func test_sound_log_recording_and_expedition_storage() -> bool:
	var exp: ExpeditionManager = ExpeditionManager.new()
	exp.set_game_state(ExpeditionManager.GameState.PLAYING)
	var overlay: FieldCameraOverlay = FieldCameraOverlay.new()
	overlay.setup(exp, null)
	overlay.set_camera_active(true)
	overlay.set_acoustic_mode(true)

	overlay.update_acoustic_telemetry(120.0, 72.0, 425.0, "Gray Wolf")
	var log_res: Dictionary = overlay.record_sound_log("Northern Ridge", "21:30")

	if log_res.is_empty():
		overlay.free()
		exp.free()
		return false
	if log_res.get("species") != "Gray Wolf" or log_res.get("frequency_hz") != 425.0 or log_res.get("bearing") != 120.0:
		overlay.free()
		exp.free()
		return false

	if exp.get_sound_log_count() != 1:
		overlay.free()
		exp.free()
		return false

	overlay.free()
	exp.free()
	return true

func test_acoustic_naturalist_milestone_unlock() -> bool:
	var exp: ExpeditionManager = ExpeditionManager.new()
	exp.set_game_state(ExpeditionManager.GameState.PLAYING)

	exp.save_sound_log("Red Deer", 182.0, 58.0, 42.0, "Sunlit Meadow", "07:15")
	exp.save_sound_log("Gray Wolf", 425.0, 68.0, 310.0, "North Ridge", "22:00")
	if exp.get_milestones().has("acoustic_naturalist"):
		exp.free()
		return false

	exp.save_sound_log("Golden Eagle", 1850.0, 52.0, 18.0, "Skyspire", "11:45")
	if exp.get_sound_log_count() != 3:
		exp.free()
		return false

	var milestones: Dictionary = exp.get_milestones()
	if not milestones.has("acoustic_naturalist"):
		exp.free()
		return false
	if milestones["acoustic_naturalist"]["title"] != "🎙️ Master of Island Voices":
		exp.free()
		return false

	exp.free()
	return true

func test_sound_logs_persistence_roundtrip() -> bool:
	var exp1: ExpeditionManager = ExpeditionManager.new()
	exp1.set_game_state(ExpeditionManager.GameState.PLAYING)
	exp1.save_sound_log("Red Deer", 182.0, 58.0, 42.0, "Meadow", "08:00")
	exp1.save_sound_log("Gray Wolf", 425.0, 70.0, 270.0, "Crags", "20:00")
	exp1.save_sound_log("Golden Eagle", 1850.0, 54.0, 90.0, "Peak", "14:00")

	var test_path: String = "user://test_acoustics_journal.json"
	var err: Error = exp1.save_journal(test_path)
	if err != OK:
		exp1.free()
		return false

	var exp2: ExpeditionManager = ExpeditionManager.new()
	var load_err: Error = exp2.load_journal(test_path)
	if load_err != OK:
		exp1.free()
		exp2.free()
		return false

	if exp2.get_sound_log_count() != 3:
		exp1.free()
		exp2.free()
		return false
	if not exp2.get_milestones().has("acoustic_naturalist"):
		exp1.free()
		exp2.free()
		return false

	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(test_path)

	exp1.free()
	exp2.free()
	return true

func test_field_journal_acoustics_tab() -> bool:
	var exp: ExpeditionManager = ExpeditionManager.new()
	exp.set_game_state(ExpeditionManager.GameState.PLAYING)
	exp.save_sound_log("Red Deer", 182.0, 60.0, 45.0, "Basin", "08:30")

	var modal: FieldJournalModal = FieldJournalModal.new()
	modal._ready()
	modal.setup(exp)
	modal.show_journal(5) # Tab 6 (index 5) is Bio-Acoustics

	if modal._sound_vbox == null or modal._sound_count_lbl == null:
		modal.free()
		exp.free()
		return false
	if modal._sound_vbox.get_child_count() != 1:
		modal.free()
		exp.free()
		return false

	modal.free()
	exp.free()
	return true
