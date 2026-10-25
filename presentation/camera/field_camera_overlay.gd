class_name FieldCameraOverlay
extends CanvasLayer

## Interactive Field Camera & Binoculars Viewfinder for Living Planet Sandbox.
## Displays an authentic naturalist rangefinder lens with:
## - Circular matte vignette framing & crosshair reticle
## - Real-time focal distance & zoom magnification readouts
## - Dynamic target scanner (detects closest living fauna or geological landmark in crosshair)
## - Mechanical shutter flash animation and audio snap
## - Hotkeys: [Z] or [RMB] toggle, [Wheel] zoom, [Space / LMB] snap field photograph

signal photo_captured(photo_data: Dictionary)
signal camera_toggled(active: bool)

const UIAudioFeedback = preload("res://presentation/audio/ui_audio_feedback.gd")
const ExpeditionManager = preload("res://core/gameplay/expedition_manager.gd")

enum OpticalFilter {
	NATURAL,
	SEPIA_EXPEDITION,
	BIO_FLUORESCENCE,
	MONOCHROME
}

var is_active: bool = false
var zoom_level: float = 3.5
var current_filter: OpticalFilter = OpticalFilter.NATURAL
var current_target_name: String = "Open Wilderness"
var current_target_type: String = "LANDSCAPE"
var current_target_distance: float = 45.0
var is_target_stealth: bool = false

# --- PARABOLIC BIO-ACOUSTIC TELEMETRY ---
var is_acoustic_mode: bool = false
var acoustic_bearing: float = 0.0 # Degrees
var acoustic_decibels: float = 48.0 # dB
var acoustic_frequency_hz: float = 185.0 # Hz
var acoustic_species: String = "Open Ambience"

var _container: Control
var _lens_panel: Panel
var _reticle: Label
var _telemetry_lbl: Label
var _target_bracket: PanelContainer
var _target_lbl: Label
var _oscilloscope_panel: PanelContainer
var _oscilloscope_lbl: Label
var _controls_hint: Label
var _filter_rect: ColorRect
var _flash_rect: ColorRect
var _flash_timer: float = 0.0

var _expedition_manager: ExpeditionManager = null
var _camera_ref: Camera3D = null

func _init() -> void:
	layer = 85
	_build_ui()

func _ready() -> void:
	if not _container:
		_build_ui()
	visible = false

func setup(manager: ExpeditionManager, camera: Camera3D) -> void:
	_expedition_manager = manager
	_camera_ref = camera

func _build_ui() -> void:
	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)

	# 1. Dark Vignette Outer Framing
	_lens_panel = Panel.new()
	_lens_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var lens_style: StyleBoxFlat = StyleBoxFlat.new()
	lens_style.bg_color = Color(0.01, 0.02, 0.04, 0.45)
	lens_style.border_width_left = 64
	lens_style.border_width_right = 64
	lens_style.border_width_top = 36
	lens_style.border_width_bottom = 36
	lens_style.border_color = Color(0.02, 0.03, 0.06, 0.92)
	lens_style.corner_radius_top_left = 48
	lens_style.corner_radius_top_right = 48
	lens_style.corner_radius_bottom_left = 48
	lens_style.corner_radius_bottom_right = 48
	_lens_panel.add_theme_stylebox_override("panel", lens_style)
	_lens_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_lens_panel)

	# 2. Central Reticle & Crosshair
	_reticle = Label.new()
	_reticle.text = "┌           ┐\n     ┼     \n└           ┘"
	_reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reticle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reticle.set_anchors_preset(Control.PRESET_CENTER)
	_reticle.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0, 0.85))
	_reticle.add_theme_font_size_override("font_size", 18)
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_reticle)

	# 3. Top Telemetry: Focal Length, Compass, Zoom
	_telemetry_lbl = Label.new()
	_telemetry_lbl.text = "OPTICAL ZOOM: 3.5x  •  FOCAL DIST: 32.0m  •  SHUTTER: 1/500s  •  ISO 100"
	_telemetry_lbl.anchor_left = 0.2
	_telemetry_lbl.anchor_top = 0.08
	_telemetry_lbl.anchor_right = 0.8
	_telemetry_lbl.anchor_bottom = 0.12
	_telemetry_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_telemetry_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 0.9))
	_telemetry_lbl.add_theme_font_size_override("font_size", 11)
	_telemetry_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_telemetry_lbl)

	# 4. Target Identification Bracket
	_target_bracket = PanelContainer.new()
	_target_bracket.anchor_left = 0.3
	_target_bracket.anchor_top = 0.62
	_target_bracket.anchor_right = 0.7
	_target_bracket.anchor_bottom = 0.68
	var b_style: StyleBoxFlat = StyleBoxFlat.new()
	b_style.bg_color = Color(0.04, 0.08, 0.14, 0.75)
	b_style.border_color = Color(0.35, 0.88, 1.0, 0.7)
	b_style.border_width_left = 1
	b_style.border_width_right = 1
	b_style.border_width_top = 1
	b_style.border_width_bottom = 1
	b_style.corner_radius_top_left = 4
	b_style.corner_radius_top_right = 4
	b_style.corner_radius_bottom_left = 4
	b_style.corner_radius_bottom_right = 4
	_target_bracket.add_theme_stylebox_override("panel", b_style)
	_target_bracket.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_target_lbl = Label.new()
	_target_lbl.text = "🎯 TARGET: Open Wilderness (Scanning...)"
	_target_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_target_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_target_lbl.add_theme_font_size_override("font_size", 11)
	_target_bracket.add_child(_target_lbl)
	_container.add_child(_target_bracket)

	# 4b. Bio-Acoustic Directional Oscilloscope Panel
	_oscilloscope_panel = PanelContainer.new()
	_oscilloscope_panel.anchor_left = 0.25
	_oscilloscope_panel.anchor_top = 0.70
	_oscilloscope_panel.anchor_right = 0.75
	_oscilloscope_panel.anchor_bottom = 0.76
	var osc_style: StyleBoxFlat = StyleBoxFlat.new()
	osc_style.bg_color = Color(0.01, 0.05, 0.09, 0.85)
	osc_style.border_color = Color(0.18, 0.88, 0.76, 0.80)
	osc_style.border_width_left = 1
	osc_style.border_width_right = 1
	osc_style.border_width_top = 1
	osc_style.border_width_bottom = 1
	osc_style.corner_radius_top_left = 4
	osc_style.corner_radius_top_right = 4
	osc_style.corner_radius_bottom_left = 4
	osc_style.corner_radius_bottom_right = 4
	_oscilloscope_panel.add_theme_stylebox_override("panel", osc_style)
	_oscilloscope_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_oscilloscope_panel.visible = false

	_oscilloscope_lbl = Label.new()
	_oscilloscope_lbl.text = "🎙️ PARABOLIC MIC: 185 Hz | 58 dB | BEARING: 042° [SPECTRUM:  ▂▃▅▆▇▆▅▃▂ ]"
	_oscilloscope_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_oscilloscope_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_oscilloscope_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.85))
	_oscilloscope_lbl.add_theme_font_size_override("font_size", 10)
	_oscilloscope_panel.add_child(_oscilloscope_lbl)
	_container.add_child(_oscilloscope_panel)

	# 5. Bottom Controls Hint
	_controls_hint = Label.new()
	_controls_hint.text = "[LMB / Space]: Capture Photo   •   [F]: Cycle Lens Filter   •   [Wheel Up/Down]: Zoom (2x - 8x)   •   [Z / RMB]: Lower Camera"
	_controls_hint.anchor_left = 0.15
	_controls_hint.anchor_top = 0.90
	_controls_hint.anchor_right = 0.85
	_controls_hint.anchor_bottom = 0.95
	_controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_hint.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	_controls_hint.add_theme_font_size_override("font_size", 10)
	_controls_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_controls_hint)

	# 6. Optical Spectrum Lens Filter Tint Layer
	_filter_rect = ColorRect.new()
	_filter_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_filter_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	_filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_filter_rect)

	# 7. Shutter Flash Overlay
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_flash_rect)

func toggle_camera_mode() -> void:
	set_camera_active(not is_active)

func set_camera_active(active: bool) -> void:
	if is_active == active:
		return
	is_active = active
	visible = is_active

	var fb = UIAudioFeedback.get_singleton()
	if fb:
		if is_active:
			fb.play_modal_open()
		else:
			fb.play_modal_close()

	camera_toggled.emit(is_active)

func cycle_filter_mode() -> OpticalFilter:
	var next_idx: int = (int(current_filter) + 1) % OpticalFilter.size()
	set_filter_mode(next_idx as OpticalFilter)
	var fb = UIAudioFeedback.get_singleton()
	if fb and fb.has_method("play_filter_click"):
		fb.play_filter_click()
	return current_filter

func set_filter_mode(mode: OpticalFilter) -> void:
	current_filter = mode
	_apply_filter_style()
	_update_hud_readouts()

func get_filter_name() -> String:
	match current_filter:
		OpticalFilter.NATURAL:
			return "Natural Spectrum"
		OpticalFilter.SEPIA_EXPEDITION:
			return "Sepia Expedition"
		OpticalFilter.BIO_FLUORESCENCE:
			return "Bio-Fluorescence"
		OpticalFilter.MONOCHROME:
			return "Monochrome Silver"
		_:
			return "Natural Spectrum"

func _apply_filter_style() -> void:
	if not _filter_rect:
		return
	match current_filter:
		OpticalFilter.NATURAL:
			_filter_rect.color = Color(1.0, 1.0, 1.0, 0.0)
		OpticalFilter.SEPIA_EXPEDITION:
			_filter_rect.color = Color(0.85, 0.65, 0.38, 0.28)
		OpticalFilter.BIO_FLUORESCENCE:
			_filter_rect.color = Color(0.12, 0.88, 0.45, 0.26)
		OpticalFilter.MONOCHROME:
			_filter_rect.color = Color(0.55, 0.60, 0.70, 0.32)

func adjust_zoom(delta_zoom: float) -> void:
	zoom_level = clampf(zoom_level + delta_zoom, 2.0, 8.0)
	_update_hud_readouts()

func snap_photo(location_name: String = "Central Basin", time_str: String = "08:00") -> Dictionary:
	# 1. Trigger Flash Animation
	_flash_timer = 0.18
	if _flash_rect:
		_flash_rect.color = Color(1.0, 1.0, 1.0, 0.85)

	# 2. Trigger Procedural Shutter Audio
	var fb = UIAudioFeedback.get_singleton()
	if fb:
		fb.play_shutter()

	# 3. Calculate Photo Quality Score
	var base_score: int = 50
	if current_target_type == "FAUNA":
		base_score = 75
		if current_target_distance <= 20.0:
			base_score += 20 # Proximity bonus
		if is_target_stealth:
			base_score += 15 # Stealth unalerted bonus
	elif current_target_type == "LANDMARK":
		base_score = 80
	elif current_target_type == "PHENOMENON":
		base_score = 90

	var final_score: int = clampi(base_score, 40, 100)

	# 4. Save to Expedition Manager
	var photo_entry: Dictionary = {}
	if _expedition_manager:
		photo_entry = _expedition_manager.save_photo(
			current_target_name,
			current_target_type,
			current_target_distance,
			final_score,
			location_name,
			time_str,
			is_target_stealth,
			get_filter_name()
		)
	else:
		photo_entry = {
			"subject": current_target_name,
			"type": current_target_type,
			"distance": current_target_distance,
			"score": final_score,
			"filter": get_filter_name()
		}

	if not photo_entry.has("filter"):
		photo_entry["filter"] = get_filter_name()

	photo_captured.emit(photo_entry)
	return photo_entry

func update_target_scanner(target_name: String, target_type: String, dist: float, is_stealth: bool = false) -> void:
	current_target_name = target_name
	current_target_type = target_type
	current_target_distance = dist
	is_target_stealth = is_stealth
	_update_hud_readouts()

func toggle_acoustic_mode() -> void:
	set_acoustic_mode(not is_acoustic_mode)

func set_acoustic_mode(active: bool) -> void:
	is_acoustic_mode = active
	if is_acoustic_mode and not is_active:
		set_camera_active(true)
	var fb = UIAudioFeedback.get_singleton()
	if fb:
		if is_acoustic_mode:
			fb.play_tape_record()
		else:
			fb.play_tape_stop()
	_update_hud_readouts()

func update_acoustic_telemetry(bearing: float, decibels: float, frequency: float, species: String) -> void:
	acoustic_bearing = bearing
	acoustic_decibels = decibels
	acoustic_frequency_hz = frequency
	acoustic_species = species
	_update_hud_readouts()

func record_sound_log(location_name: String = "Sunlit Basin", time_str: String = "12:00") -> Dictionary:
	var fb = UIAudioFeedback.get_singleton()
	if fb:
		fb.play_tape_record()
	var log_entry: Dictionary = {}
	if _expedition_manager:
		log_entry = _expedition_manager.save_sound_log(
			acoustic_species,
			acoustic_frequency_hz,
			acoustic_decibels,
			acoustic_bearing,
			location_name,
			time_str
		)
	else:
		log_entry = {
			"species": acoustic_species,
			"frequency_hz": acoustic_frequency_hz,
			"decibels": acoustic_decibels,
			"bearing": acoustic_bearing,
			"location": location_name,
			"timestamp": time_str
		}
	return log_entry

func _update_hud_readouts() -> void:
	if not _telemetry_lbl or not _target_lbl:
		return
	if is_acoustic_mode:
		_telemetry_lbl.text = "PARABOLIC ACOUSTIC REFLECTOR  •  BEARING: %03d°  •  GAIN: +6.0dB  •  FREQ: %.0f Hz" % [
			int(acoustic_bearing), acoustic_frequency_hz
		]
		if _oscilloscope_panel and _oscilloscope_lbl:
			_oscilloscope_panel.visible = true
			var bars: String = " ▂▃▅▆▇▆▅▃▂ " if acoustic_decibels > 50.0 else " ▂▃▂   ▂▃ "
			_oscilloscope_lbl.text = "🎙️ BIO-ACOUSTIC: %s [ %.0f Hz | %.1f dB ] [ %s ]" % [
				acoustic_species, acoustic_frequency_hz, acoustic_decibels, bars
			]
		if _reticle:
			_reticle.text = "( ( ( 🎙️ ┼ 🎙️ ) ) )"
		if _controls_hint:
			_controls_hint.text = "[LMB / Space]: Capture Photo  •  [R]: Record Tape  •  [X]: Toggle Mic  •  [F]: Filter  •  [Z]: Exit"
	else:
		_telemetry_lbl.text = "OPTICAL ZOOM: %.1fx  •  FOCAL: %.1fm  •  FILTER: %s  •  SHUTTER: 1/500s" % [
			zoom_level, current_target_distance, get_filter_name().to_upper()
		]
		if _oscilloscope_panel:
			_oscilloscope_panel.visible = false
		if _reticle:
			_reticle.text = "┌           ┐\n     ┼     \n└           ┘"
		if _controls_hint:
			_controls_hint.text = "[LMB / Space]: Capture Photo   •   [F]: Cycle Lens Filter   •   [Wheel Up/Down]: Zoom (2x - 8x)   •   [Z / RMB]: Lower Camera"

	var stealth_tag: String = " [🌿 STEALTH +15]" if is_target_stealth else ""
	var type_icon: String = "🦌" if current_target_type == "FAUNA" else ("🗿" if current_target_type == "LANDMARK" else "🌌")
	if current_target_type == "LANDSCAPE":
		type_icon = "🌲"
	_target_lbl.text = "%s TARGET: %s (%.1fm)%s" % [type_icon, current_target_name, current_target_distance, stealth_tag]

func _process(delta: float) -> void:
	if not is_active:
		return

	if _flash_timer > 0.0:
		_flash_timer -= delta
		var alpha: float = clampf(_flash_timer / 0.18, 0.0, 1.0) * 0.85
		_flash_rect.color = Color(1.0, 1.0, 1.0, alpha)
