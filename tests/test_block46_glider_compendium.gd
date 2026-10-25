class_name TestBlock46GliderCompendium
extends RefCounted

## Living Planet Sandbox — Suite 45 Contract Verification.
## Validates Genshin Elemental Anemo Glider Wings, Updraft Vents,
## Field Journal Marine & Alchemy Compendium, and POI Regional Audio Synthesizers.

const FirstPersonWalker = preload("res://presentation/camera/first_person_walker.gd")
const UpdraftVent3D = preload("res://presentation/environment/updraft_vent.gd")
const FieldJournalModal = preload("res://presentation/ui/field_journal_modal.gd")
const SpatialAudioDirector = preload("res://presentation/audio/spatial_audio_director.gd")

func run_all_tests() -> Dictionary:
	var results: Dictionary = {
		"total": 0,
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	var tests: Array[Callable] = [
		Callable(self, "test_glider_initialization"),
		Callable(self, "test_glider_open_close_toggle"),
		Callable(self, "test_glider_flight_aerodynamics"),
		Callable(self, "test_updraft_vent_propulsion"),
		Callable(self, "test_field_journal_compendium_tab"),
		Callable(self, "test_poi_regional_audio_synthesis")
	]

	for test in tests:
		results["total"] += 1
		var err: String = test.call()
		if err == "":
			results["passed"] += 1
		else:
			results["failed"] += 1
			results["errors"].append(err)

	return results

func test_glider_initialization() -> String:
	var walker: FirstPersonWalker = FirstPersonWalker.new()
	walker._ready()

	if walker.is_gliding:
		walker.queue_free()
		return "Expected glider to be closed initially."
	if walker._glider_root == null:
		walker.queue_free()
		return "Expected _glider_root to be instantiated in FirstPersonWalker."
	if walker._glider_root.visible:
		walker.queue_free()
		return "Expected _glider_root to be hidden initially."
	if not is_equal_approx(walker.glide_speed, 8.8):
		walker.queue_free()
		return "Expected glide_speed to be 8.8 m/s, got %f" % walker.glide_speed
	if not is_equal_approx(walker.glide_sink_rate, -1.8):
		walker.queue_free()
		return "Expected glide_sink_rate to be -1.8 m/s, got %f" % walker.glide_sink_rate

	walker.queue_free()
	return ""

func test_glider_open_close_toggle() -> String:
	var walker: FirstPersonWalker = FirstPersonWalker.new()
	walker._ready()

	var state_events: Array[bool] = []
	walker.glider_state_changed.connect(func(active: bool): state_events.append(active))

	walker.open_glider()
	if not walker.is_gliding or not walker._glider_root.visible:
		walker.queue_free()
		return "open_glider() failed to activate glider or show wing mesh."
	if state_events.size() != 1 or state_events[0] != true:
		walker.queue_free()
		return "Expected glider_state_changed(true) signal emission."

	walker.close_glider()
	if walker.is_gliding or walker._glider_root.visible:
		walker.queue_free()
		return "close_glider() failed to deactivate glider or hide wing mesh."
	if state_events.size() != 2 or state_events[1] != false:
		walker.queue_free()
		return "Expected glider_state_changed(false) signal emission."

	walker.toggle_glider()
	if not walker.is_gliding:
		walker.queue_free()
		return "toggle_glider() failed to toggle glider state."

	walker.queue_free()
	return ""

func test_glider_flight_aerodynamics() -> String:
	var walker: FirstPersonWalker = FirstPersonWalker.new()
	walker._ready()
	walker.open_glider()

	# Simulate air physics step while descending fast (-12.0 m/s)
	walker.velocity.y = -12.0
	walker.move_character(0.1, Vector3(0.0, 0.0, -1.0), false, false, false)

	# Glider should arrest extreme fall speed towards glide_sink_rate (-1.8 m/s)
	if walker.velocity.y <= -12.0:
		walker.queue_free()
		return "Expected glider aerodynamics to decelerate terminal fall speed."

	if walker.velocity.y < -8.0:
		walker.queue_free()
		return "Expected glider descent to clamp towards -1.8 m/s, got %f" % walker.velocity.y

	walker.queue_free()
	return ""

func test_updraft_vent_propulsion() -> String:
	var vent: UpdraftVent3D = UpdraftVent3D.new()
	vent.setup(Vector3.ZERO, 14.5, 15.0)
	vent._ready()

	var walker: FirstPersonWalker = FirstPersonWalker.new()
	walker._ready()
	walker.velocity = Vector3.ZERO
	walker.position = Vector3(0.5, 2.0, 0.5)

	var boosted_events: Array[Node] = []
	vent.player_boosted.connect(func(w): boosted_events.append(w))

	vent._apply_updraft(walker)

	if walker.velocity.y < 14.5:
		vent.queue_free()
		walker.queue_free()
		return "Expected updraft vent to propel player with velocity.y >= 14.5 m/s, got %f" % walker.velocity.y

	if not walker.is_gliding:
		vent.queue_free()
		walker.queue_free()
		return "Expected updraft launch to auto-deploy Anemo Glider Wings."

	if boosted_events.is_empty():
		vent.queue_free()
		walker.queue_free()
		return "Expected player_boosted signal emission."

	vent.queue_free()
	walker.queue_free()
	return ""

func test_field_journal_compendium_tab() -> String:
	var exp_mgr = preload("res://core/gameplay/expedition_manager.gd").new()
	var modal: FieldJournalModal = FieldJournalModal.new()
	modal.setup(exp_mgr)

	if modal._compendium_vbox == null:
		modal.queue_free()
		exp_mgr.queue_free()
		return "Expected _compendium_vbox to be instantiated in FieldJournalModal."

	modal.refresh_display()

	var card_count: int = modal._compendium_vbox.get_child_count()
	if card_count < 7:
		modal.queue_free()
		exp_mgr.queue_free()
		return "Expected at least 7 compendium cards, found %d" % card_count

	modal.queue_free()
	exp_mgr.queue_free()
	return ""

func test_poi_regional_audio_synthesis() -> String:
	var marimba_wav: AudioStreamWAV = SpatialAudioDirector._generate_village_marimba_wav(0.5, 22050)
	if marimba_wav == null or marimba_wav.data.is_empty():
		return "Failed to synthesize Haven Village marimba audio stream."
	if marimba_wav.mix_rate != 22050:
		return "Expected marimba mix_rate to be 22050, got %d" % marimba_wav.mix_rate

	var choir_wav: AudioStreamWAV = SpatialAudioDirector._generate_castle_choir_wav(0.5, 22050)
	if choir_wav == null or choir_wav.data.is_empty():
		return "Failed to synthesize Castle Citadel choir pad audio stream."
	if choir_wav.mix_rate != 22050:
		return "Expected choir pad mix_rate to be 22050, got %d" % choir_wav.mix_rate

	return ""
