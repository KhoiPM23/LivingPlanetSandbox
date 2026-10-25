class_name TestBlock30HeatmapsAndFilters
extends RefCounted

## Automated contract test suite for Block 30: Wildlife Tracking & Territory Heatmaps,
## Multi-Filter Optical Spectrum Photography, and Seasonal Ecological Cycles.

const UIAudioFeedback = preload("res://presentation/audio/ui_audio_feedback.gd")
const ExpeditionManager = preload("res://core/gameplay/expedition_manager.gd")
const FieldCameraOverlay = preload("res://presentation/camera/field_camera_overlay.gd")
const IslandMapCanvas = preload("res://presentation/ui/island_map_canvas.gd")
const WorldClock = preload("res://core/clock/world_clock.gd")

func test_ui_audio_rotary_filter_click() -> bool:
	var feedback: UIAudioFeedback = UIAudioFeedback.new()
	if feedback._filter_click_wav == null:
		feedback.free()
		return false

	# Verify PCM 16-bit format & sample rate
	if feedback._filter_click_wav.format != AudioStreamWAV.FORMAT_16_BITS:
		feedback.free()
		return false
	if feedback._filter_click_wav.mix_rate != 22050:
		feedback.free()
		return false
	if feedback._filter_click_wav.data.size() < 400:
		feedback.free()
		return false

	# Verify method executes without error
	feedback.play_filter_click()

	feedback.free()
	return true

func test_optical_filter_modes_and_visual_tints() -> bool:
	var cam: FieldCameraOverlay = FieldCameraOverlay.new()
	if cam.current_filter != FieldCameraOverlay.OpticalFilter.NATURAL:
		cam.free()
		return false
	if cam.get_filter_name() != "Natural Spectrum":
		cam.free()
		return false

	# Mode 1 -> Mode 2: Sepia Expedition
	var mode2 = cam.cycle_filter_mode()
	if mode2 != FieldCameraOverlay.OpticalFilter.SEPIA_EXPEDITION or cam.get_filter_name() != "Sepia Expedition":
		cam.free()
		return false
	if cam._filter_rect == null or cam._filter_rect.color.a <= 0.05:
		cam.free()
		return false

	# Mode 2 -> Mode 3: Bio-Fluorescence
	var mode3 = cam.cycle_filter_mode()
	if mode3 != FieldCameraOverlay.OpticalFilter.BIO_FLUORESCENCE or cam.get_filter_name() != "Bio-Fluorescence":
		cam.free()
		return false
	# Green component should be dominant for bio-fluorescence
	if cam._filter_rect.color.g <= cam._filter_rect.color.r:
		cam.free()
		return false

	# Mode 3 -> Mode 4: Monochrome Silver
	var mode4 = cam.cycle_filter_mode()
	if mode4 != FieldCameraOverlay.OpticalFilter.MONOCHROME or cam.get_filter_name() != "Monochrome Silver":
		cam.free()
		return false

	# Mode 4 -> Mode 1: Natural Spectrum
	var mode1 = cam.cycle_filter_mode()
	if mode1 != FieldCameraOverlay.OpticalFilter.NATURAL or cam.get_filter_name() != "Natural Spectrum":
		cam.free()
		return false
	if cam._filter_rect.color.a != 0.0:
		cam.free()
		return false

	cam.free()
	return true

func test_photo_snapshot_filter_metadata_and_master_milestone() -> bool:
	var manager: ExpeditionManager = ExpeditionManager.new()

	var unlocked_milestones: Array[String] = []
	manager.milestone_unlocked.connect(func(m_id: String, _title: String, _desc: String):
		unlocked_milestones.append(m_id)
	)

	# 1. First Photo with Natural Spectrum
	var p1: Dictionary = manager.save_photo("Red Deer", "FAUNA", 12.0, 90, "Central Basin", "09:00", true, "Natural Spectrum")
	if p1.get("filter", "") != "Natural Spectrum":
		manager.free()
		return false

	# 2. Second Photo with Sepia Expedition
	var p2: Dictionary = manager.save_photo("Summit Monolith", "LANDMARK", 35.0, 85, "Skyspire", "10:00", false, "Sepia Expedition")
	if p2.get("filter", "") != "Sepia Expedition":
		manager.free()
		return false

	# 3. Third Photo with Bio-Fluorescence
	var p3: Dictionary = manager.save_photo("Meadow Fireflies", "FAUNA", 8.0, 95, "Whispering Glade", "22:00", true, "Bio-Fluorescence")
	if p3.get("filter", "") != "Bio-Fluorescence":
		manager.free()
		return false

	# 4. Fourth Photo with Monochrome Silver
	manager.save_photo("Glacial Waterfall", "LANDMARK", 25.0, 80, "Alpine Tarn", "12:00", false, "Monochrome Silver")

	if manager.get_photo_count() != 4:
		manager.free()
		return false
	if unlocked_milestones.has("master_photographer"):
		manager.free()
		return false

	# 5. Fifth Photo -> Triggers Master of Light milestone!
	var p5: Dictionary = manager.save_photo("Gray Wolf", "FAUNA", 18.0, 95, "Pine Highlands", "15:00", true, "Bio-Fluorescence")
	if p5.get("filter", "") != "Bio-Fluorescence":
		manager.free()
		return false

	if manager.get_photo_count() != 5:
		manager.free()
		return false
	if not unlocked_milestones.has("master_photographer"):
		manager.free()
		return false

	var badges: Dictionary = manager.get_milestones()
	if not badges.has("master_photographer") or not badges["master_photographer"]["title"].contains("Master of Light"):
		manager.free()
		return false

	manager.free()
	return true

func test_wildlife_territory_heatmaps_on_map_canvas() -> bool:
	var canvas: IslandMapCanvas = IslandMapCanvas.new()

	if not canvas.show_wildlife_heatmaps:
		canvas.free()
		return false

	var herb_positions = [Vector3(15.0, 4.0, 25.0), Vector3(-10.0, 3.5, 40.0)]
	var pred_positions = [Vector3(-85.0, 12.0, -45.0)]
	var trail = [Vector3(0.0, 0.0, 0.0), Vector3(10.0, 0.0, 10.0), Vector3(15.0, 0.0, 20.0)]

	canvas.update_wildlife_telemetry(herb_positions, pred_positions, trail)

	if canvas.herbivore_positions.size() != 2:
		canvas.free()
		return false
	if canvas.predator_positions.size() != 1:
		canvas.free()
		return false
	if canvas.disturbance_trail.size() != 3:
		canvas.free()
		return false

	# Toggle off
	var active1 = canvas.toggle_wildlife_heatmaps()
	if active1 != false or canvas.show_wildlife_heatmaps != false:
		canvas.free()
		return false

	# Toggle on
	var active2 = canvas.toggle_wildlife_heatmaps()
	if active2 != true or canvas.show_wildlife_heatmaps != true:
		canvas.free()
		return false

	canvas.free()
	return true

func test_world_clock_seasonal_cycles() -> bool:
	var clock: WorldClock = WorldClock.new()
	clock.day_duration = 720.0
	clock.start_hour = 0.0
	clock.simulation_time = 0.0

	# Day 1: Spring Bloom
	if clock.get_day_number() != 1:
		return false
	if clock.get_season() != WorldClock.Season.SPRING:
		return false
	if clock.get_season_name() != "Spring Bloom":
		return false

	# Advance 3 days -> Day 4: High Summer
	clock.simulation_time = 3.0 * clock.day_duration
	if clock.get_day_number() != 4:
		return false
	if clock.get_season() != WorldClock.Season.SUMMER:
		return false
	if clock.get_season_name() != "High Summer":
		return false

	# Advance 3 days -> Day 7: Golden Autumn
	clock.simulation_time = 6.0 * clock.day_duration
	if clock.get_day_number() != 7:
		return false
	if clock.get_season() != WorldClock.Season.AUTUMN:
		return false
	if clock.get_season_name() != "Golden Autumn":
		return false

	# Advance 3 days -> Day 10: Frost Winter
	clock.simulation_time = 9.0 * clock.day_duration
	if clock.get_day_number() != 10:
		return false
	if clock.get_season() != WorldClock.Season.WINTER:
		return false
	if clock.get_season_name() != "Frost Winter":
		return false

	# Advance 3 days -> Day 13: Back to Spring Bloom
	clock.simulation_time = 12.0 * clock.day_duration
	if clock.get_day_number() != 13:
		return false
	if clock.get_season() != WorldClock.Season.SPRING:
		return false

	return true

func test_camera_overlay_snap_photo_filter_persistence() -> bool:
	var overlay: FieldCameraOverlay = FieldCameraOverlay.new()
	overlay.set_camera_active(true)

	# Snap default photo
	var snap1 = overlay.snap_photo("Emerald Basin", "08:30")
	if snap1.get("filter", "") != "Natural Spectrum":
		overlay.free()
		return false

	# Cycle filter to Sepia Expedition
	overlay.cycle_filter_mode()
	var snap2 = overlay.snap_photo("Cairn Ridge", "09:15")
	if snap2.get("filter", "") != "Sepia Expedition":
		overlay.free()
		return false

	# Cycle filter to Bio-Fluorescence
	overlay.cycle_filter_mode()
	var snap3 = overlay.snap_photo("Firefly Glade", "21:45")
	if snap3.get("filter", "") != "Bio-Fluorescence":
		overlay.free()
		return false

	overlay.free()
	return true
