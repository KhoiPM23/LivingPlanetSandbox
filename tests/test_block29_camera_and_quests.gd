class_name TestBlock29CameraAndQuests
extends RefCounted

## Automated contract test suite for Block 29: Naturalist Field Toolset, Wildlife Photography,
## Active Seed Commissions, and High-Altitude Alpine Snow Acoustics.

const UIAudioFeedback = preload("res://presentation/audio/ui_audio_feedback.gd")
const ExpeditionManager = preload("res://core/gameplay/expedition_manager.gd")
const FieldCameraOverlay = preload("res://presentation/camera/field_camera_overlay.gd")
const FirstPersonWalker = preload("res://presentation/camera/first_person_walker.gd")
const FieldJournalModal = preload("res://presentation/ui/field_journal_modal.gd")

func test_ui_audio_shutter_and_quest_synthesis() -> bool:
	var feedback: UIAudioFeedback = UIAudioFeedback.new()
	if feedback._shutter_wav == null:
		feedback.free()
		return false
	if feedback._quest_wav == null:
		feedback.free()
		return false

	# Verify PCM 16-bit format & sample rate
	if feedback._shutter_wav.format != AudioStreamWAV.FORMAT_16_BITS:
		feedback.free()
		return false
	if feedback._quest_wav.mix_rate != 22050:
		feedback.free()
		return false
	if feedback._shutter_wav.data.size() < 1000:
		feedback.free()
		return false
	if feedback._quest_wav.data.size() < 1000:
		feedback.free()
		return false

	# Verify methods execute without crash
	feedback.play_shutter()
	feedback.play_quest_complete()

	feedback.free()
	return true

func test_expedition_photo_album_contract() -> bool:
	var manager: ExpeditionManager = ExpeditionManager.new()
	if manager.get_photo_count() != 0:
		manager.free()
		return false
	if not manager.get_photos().is_empty():
		manager.free()
		return false

	var milestones_unlocked: Array[String] = []
	manager.milestone_unlocked.connect(func(m_id: String, _title: String, _desc: String):
		milestones_unlocked.append(m_id)
	)

	# Save 1st photo
	var p1: Dictionary = manager.save_photo("Red Deer", "FAUNA", 14.5, 95, "Central Glade", "10:30", true)
	if p1.is_empty() or p1["id"] != 1:
		manager.free()
		return false
	if p1["subject"] != "Red Deer" or p1["quality_rating"] != 5 or not p1["stealth_unalerted"]:
		manager.free()
		return false

	# Check milestone 1: shutter_novice
	if not milestones_unlocked.has("shutter_novice"):
		manager.free()
		return false

	# Save 2 more photos
	manager.save_photo("Skyspire Peaks", "LANDMARK", 42.0, 80, "Alpine Massif", "11:00", false)
	manager.save_photo("Gray Wolf", "FAUNA", 22.0, 88, "Pine Forest", "11:30", true)

	if manager.get_photo_count() != 3:
		manager.free()
		return false

	# Check milestone 2: wildlife_chronicler
	if not milestones_unlocked.has("wildlife_chronicler"):
		manager.free()
		return false

	manager.free()
	return true

func test_expedition_seed_quests_contract() -> bool:
	var manager: ExpeditionManager = ExpeditionManager.new()
	manager.generate_seed_quests(1337)

	var quests: Array[Dictionary] = manager.get_active_quests()
	if quests.size() != 3:
		manager.free()
		return false

	if manager.get_completed_quests_count() != 0:
		manager.free()
		return false

	# Test Summit Topographic Survey Quest Progress
	manager.check_quest_progress("PLAYER_POSITION", {"position": Vector3(0.0, 40.0, 0.0)})
	var q_summit: Dictionary = quests[0]
	if q_summit["progress"] != 40:
		manager.free()
		return false

	manager.check_quest_progress("PLAYER_POSITION", {"position": Vector3(0.0, 58.0, 0.0)})
	if not q_summit["completed"]:
		manager.free()
		return false

	# Test Wildlife Photography Quest Progress
	manager.check_quest_progress("PHOTO_CAPTURED", {"target_type": "FAUNA"})
	var q_photo: Dictionary = quests[1]
	if q_photo["progress"] != 1 or q_photo["completed"]:
		manager.free()
		return false

	manager.check_quest_progress("PHOTO_CAPTURED", {"target_type": "FAUNA"})
	if not q_photo["completed"]:
		manager.free()
		return false

	# Test Landmark Discovery Quest Progress
	manager.check_quest_progress("LANDMARK_DISCOVERED", {"id": "whispering_grotto"})
	var q_grotto: Dictionary = quests[2]
	if not q_grotto["completed"]:
		manager.free()
		return false

	if manager.get_completed_quests_count() != 3:
		manager.free()
		return false

	manager.free()
	return true

func test_field_camera_overlay_state_and_zoom() -> bool:
	var overlay: FieldCameraOverlay = FieldCameraOverlay.new()
	if overlay.is_active:
		overlay.free()
		return false
	if absf(overlay.zoom_level - 3.5) > 0.01:
		overlay.free()
		return false

	var toggle_signal_received: Dictionary = {"active": false}
	overlay.camera_toggled.connect(func(active: bool):
		toggle_signal_received["active"] = active
	)

	overlay.toggle_camera_mode()
	if not overlay.is_active or not toggle_signal_received["active"]:
		overlay.free()
		return false

	# Zoom adjustment and limits (2.0x to 8.0x)
	overlay.adjust_zoom(1.5)
	if absf(overlay.zoom_level - 5.0) > 0.01:
		overlay.free()
		return false

	overlay.adjust_zoom(10.0) # Should clamp to 8.0
	if absf(overlay.zoom_level - 8.0) > 0.01:
		overlay.free()
		return false

	overlay.adjust_zoom(-20.0) # Should clamp to 2.0
	if absf(overlay.zoom_level - 2.0) > 0.01:
		overlay.free()
		return false

	# Target scanner update
	overlay.update_target_scanner("Red Deer", "FAUNA", 18.2, true)
	if overlay.current_target_name != "Red Deer" or overlay.current_target_type != "FAUNA" or not overlay.is_target_stealth:
		overlay.free()
		return false

	# Snap Photo
	var manager: ExpeditionManager = ExpeditionManager.new()
	overlay.setup(manager, null)
	var photo: Dictionary = overlay.snap_photo("Emerald Meadow", "09:15")
	if photo.is_empty() or photo["subject"] != "Red Deer" or photo["quality_score"] < 50:
		manager.free()
		overlay.free()
		return false

	manager.free()
	overlay.free()
	return true

func test_first_person_walker_alpine_snow_acoustics() -> bool:
	var walker: FirstPersonWalker = FirstPersonWalker.new()
	if walker._step_snow_wav == null:
		walker.free()
		return false

	# Verify PCM 16-bit format & sample rate
	if walker._step_snow_wav.format != AudioStreamWAV.FORMAT_16_BITS:
		walker.free()
		return false
	if walker._step_snow_wav.mix_rate != 22050:
		walker.free()
		return false
	if walker._step_snow_wav.data.size() < 500:
		walker.free()
		return false

	walker.free()
	return true

func test_journal_photo_album_tab_integration() -> bool:
	var manager: ExpeditionManager = ExpeditionManager.new()
	manager.save_photo("Emerald Lake", "LANDSCAPE", 55.0, 75, "Glade Cove", "08:30", false)

	var journal: FieldJournalModal = FieldJournalModal.new()
	journal._ready()
	journal.setup(manager)

	if journal._tab_container == null:
		journal.free()
		manager.free()
		return false

	# Verify 5th tab is Photo Album
	if journal._tab_container.get_tab_count() < 5:
		journal.free()
		manager.free()
		return false

	var tab_title: String = journal._tab_container.get_tab_title(4)
	if not "Photo Album" in tab_title:
		journal.free()
		manager.free()
		return false

	journal.show_journal(4)
	if journal._tab_container.current_tab != 4:
		journal.free()
		manager.free()
		return false

	journal.free()
	manager.free()
	return true
