class_name TestBlock28ReleaseLoop
extends RefCounted

## Automated contract test suite for Block 28: Commercial Release Loop, Title Screen,
## Expedition Manager, Naturalist Field Journal, UI Audio Synthesizer, and Settings Persistence.

const UIAudioFeedback = preload("res://presentation/audio/ui_audio_feedback.gd")
const ExpeditionManager = preload("res://core/gameplay/expedition_manager.gd")
const GameSettings = preload("res://core/config/game_settings.gd")
const TitleScreen = preload("res://presentation/ui/title_screen.gd")
const IntroTitleCard = preload("res://presentation/ui/intro_title_card.gd")
const FieldJournalModal = preload("res://presentation/ui/field_journal_modal.gd")
const ExpeditionSummaryModal = preload("res://presentation/ui/expedition_summary_modal.gd")

func test_ui_audio_feedback_generation() -> bool:
	var feedback: UIAudioFeedback = UIAudioFeedback.new()
	if feedback._hover_wav == null:
		return false
	if feedback._click_wav == null:
		return false
	if feedback._open_wav == null:
		return false
	if feedback._close_wav == null:
		return false
	if feedback._discovery_wav == null:
		return false
	if feedback._milestone_wav == null:
		return false

	# Verify PCM 16-bit format & sample rate
	if feedback._hover_wav.format != AudioStreamWAV.FORMAT_16_BITS:
		return false
	if feedback._discovery_wav.mix_rate != 22050:
		return false
	if feedback._milestone_wav.data.size() < 1000:
		return false

	feedback.set_sfx_volume_scale(0.5)
	if absf(feedback._sfx_volume_scale - 0.5) > 0.01:
		return false

	feedback.free()
	return true

func test_expedition_manager_state_machine() -> bool:
	var manager: ExpeditionManager = ExpeditionManager.new()
	if manager.current_state != ExpeditionManager.GameState.TITLE_SCREEN:
		return false

	var state_signals: Array[int] = []
	manager.state_changed.connect(func(old_s: int, new_s: int):
		state_signals.append(new_s)
	)

	manager.set_game_state(ExpeditionManager.GameState.PLAYING)
	if manager.current_state != ExpeditionManager.GameState.PLAYING:
		return false
	if state_signals.size() != 1 or state_signals[0] != ExpeditionManager.GameState.PLAYING:
		return false

	manager.set_game_state(ExpeditionManager.GameState.PAUSED)
	if manager.current_state != ExpeditionManager.GameState.PAUSED:
		return false

	manager.set_game_state(ExpeditionManager.GameState.SUMMARY_MODAL)
	if manager.current_state != ExpeditionManager.GameState.SUMMARY_MODAL:
		return false

	manager.free()
	return true

func test_expedition_manager_landmarks_and_milestones() -> bool:
	var manager: ExpeditionManager = ExpeditionManager.new()
	var milestones_unlocked: Array[String] = []
	manager.milestone_unlocked.connect(func(m_id: String, _title: String, _desc: String):
		milestones_unlocked.append(m_id)
	)

	var initial_prog: Dictionary = manager.get_landmark_progress()
	if initial_prog["discovered"] != 0 or initial_prog["total"] != 11 or initial_prog["percentage"] != 0:
		return false

	# Register 1st discovery
	var res1: bool = manager.register_landmark_discovery("field_camp")
	if not res1:
		return false
	# Re-register should return false (idempotent)
	if manager.register_landmark_discovery("field_camp") != false:
		return false

	if not milestones_unlocked.has("first_steps"):
		return false

	# Register up to 5 landmarks
	manager.register_landmark_discovery("antler_rub")
	manager.register_landmark_discovery("cove_mooring")
	manager.register_landmark_discovery("bluff_overlook")
	manager.register_landmark_discovery("ancient_cairn")

	if not milestones_unlocked.has("isle_scout"):
		return false

	var half_prog: Dictionary = manager.get_landmark_progress()
	if half_prog["discovered"] != 5 or half_prog["percentage"] != 45:
		return false

	# Discover all remaining landmarks
	var remaining: Array[String] = [
		"skyspire_overlook", "highland_ring", "cape_solitude",
		"alpine_tarn", "whispering_grotto", "glacial_waterfall"
	]
	for k in remaining:
		manager.register_landmark_discovery(k)

	if not milestones_unlocked.has("master_cartographer"):
		return false

	var full_prog: Dictionary = manager.get_landmark_progress()
	if full_prog["discovered"] != 11 or full_prog["percentage"] != 100:
		return false

	manager.free()
	return true

func test_expedition_manager_species_and_phenomena() -> bool:
	var manager: ExpeditionManager = ExpeditionManager.new()
	var milestones: Array[String] = []
	manager.milestone_unlocked.connect(func(m_id: String, _t: String, _d: String):
		milestones.append(m_id)
	)

	manager.register_species_cataloged("red_deer")
	manager.register_species_cataloged("gray_wolf")
	manager.register_species_cataloged("forest_songbird")
	manager.register_species_cataloged("meadow_firefly")

	if not milestones.has("wildlife_scholar"):
		return false

	var s_prog: Dictionary = manager.get_species_progress()
	if s_prog["cataloged"] != 4 or s_prog["percentage"] != 100:
		return false

	manager.register_phenomenon_witnessed("aurora_borealis")
	manager.register_phenomenon_witnessed("shooting_star")
	manager.register_phenomenon_witnessed("glacial_blizzard")
	manager.register_phenomenon_witnessed("monsoon_rain")

	if not milestones.has("aurora_seer"):
		return false

	var p_prog: Dictionary = manager.get_phenomena_progress()
	if p_prog["witnessed"] != 4 or p_prog["percentage"] != 100:
		return false

	manager.free()
	return true

func test_expedition_manager_persistence_roundtrip() -> bool:
	var manager: ExpeditionManager = ExpeditionManager.new()
	manager.active_seed = 9988
	manager.game_mode = "Naturalist"
	manager.register_landmark_discovery("skyspire_overlook")
	manager.register_species_cataloged("gray_wolf")
	manager.register_phenomenon_witnessed("aurora_borealis")

	var test_path: String = "user://test_expedition_journal.json"
	var err_save: Error = manager.save_journal(test_path)
	if err_save != OK:
		manager.free()
		return false

	var reader: ExpeditionManager = ExpeditionManager.new()
	var err_load: Error = reader.load_journal(test_path)
	if err_load != OK:
		manager.free()
		reader.free()
		return false

	if reader.active_seed != 9988:
		return false
	if reader.game_mode != "Naturalist":
		return false
	if not reader.get_landmarks()["skyspire_overlook"]["discovered"]:
		return false
	if not reader.get_species()["gray_wolf"]["cataloged"]:
		return false
	if not reader.get_phenomena()["aurora_borealis"]["witnessed"]:
		return false

	# Clean up test file
	DirAccess.remove_absolute(test_path)
	manager.free()
	reader.free()
	return true

func test_game_settings_persistence() -> bool:
	var settings: GameSettings = GameSettings.new()
	settings.graphics_preset = 2
	settings.window_mode = 1
	settings.fog_enabled = false
	settings.master_volume = 0.65
	settings.ambience_volume = 0.70
	settings.sfx_volume = 0.80
	settings.mouse_sensitivity = 0.0055

	var test_path: String = "user://test_settings.cfg"
	var err_save: Error = settings.save_to_disk(test_path)
	if err_save != OK:
		return false

	var loaded: GameSettings = GameSettings.new()
	var err_load: Error = loaded.load_from_disk(test_path)
	if err_load != OK:
		return false

	if loaded.graphics_preset != 2:
		return false
	if loaded.window_mode != 1:
		return false
	if loaded.fog_enabled != false:
		return false
	if absf(loaded.master_volume - 0.65) > 0.01:
		return false
	if absf(loaded.ambience_volume - 0.70) > 0.01:
		return false
	if absf(loaded.sfx_volume - 0.80) > 0.01:
		return false
	if absf(loaded.mouse_sensitivity - 0.0055) > 0.0001:
		return false

	DirAccess.remove_absolute(test_path)
	return true

func test_title_screen_and_modals() -> bool:
	var title: TitleScreen = TitleScreen.new()
	title._ready()

	var res: Dictionary = {"started": false, "seed": 0, "mode": ""}
	title.expedition_started.connect(func(s: int, m: String, _l: bool):
		res["started"] = true
		res["seed"] = s
		res["mode"] = m
	)

	title._seed_input.text = "7712"
	title._mode_option_btn.selected = 0
	title._on_embark_confirmed()

	if not res["started"] or res["seed"] != 7712 or res["mode"] != "Explorer":
		title.free()
		return false

	title.free()
	return true

func test_field_journal_modal_display() -> bool:
	var manager: ExpeditionManager = ExpeditionManager.new()
	manager.register_landmark_discovery("field_camp")
	manager.register_species_cataloged("red_deer")

	var modal: FieldJournalModal = FieldJournalModal.new()
	modal._ready()
	modal.setup(manager)
	modal.show_journal(0)

	if not modal.visible:
		manager.free()
		modal.free()
		return false

	if modal._landmark_progress_bar.value != 1.0:
		manager.free()
		modal.free()
		return false

	if modal._fauna_progress_bar.value != 1.0:
		manager.free()
		modal.free()
		return false

	modal.hide_journal()
	if modal.visible:
		manager.free()
		modal.free()
		return false

	manager.free()
	modal.free()
	return true

func test_expedition_summary_modal_content() -> bool:
	var manager: ExpeditionManager = ExpeditionManager.new()
	manager.register_landmark_discovery("skyspire_overlook")

	var summary: ExpeditionSummaryModal = ExpeditionSummaryModal.new()
	summary._ready()
	summary.setup(manager)
	summary.show_summary()

	if not summary.visible:
		manager.free()
		summary.free()
		return false

	if summary._stats_lbl.text.is_empty():
		manager.free()
		summary.free()
		return false

	manager.free()
	summary.free()
	return true

func test_intro_title_card_timing() -> bool:
	var card: IntroTitleCard = IntroTitleCard.new()
	card._ready()
	card.display_intro("DAY 1 — 08:00", "EMERALD BASIN", 1337)

	if not card.visible:
		card.free()
		return false

	if not card._title_lbl.text.contains("DAY 1 — 08:00"):
		card.free()
		return false

	# Simulate time elapse past duration
	card._process(6.0)
	if not card._is_fading:
		card.free()
		return false

	card._process(1.5)
	if card.visible:
		card.free()
		return false

	card.free()
	return true
