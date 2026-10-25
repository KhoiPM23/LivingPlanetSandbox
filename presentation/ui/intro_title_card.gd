class_name IntroTitleCard
extends CanvasLayer

## Cinematic lower-third expedition introduction card.
## Displays world arrival coordinates, active expedition objectives, and key hints.

const UIAudioFeedback = preload("res://presentation/audio/ui_audio_feedback.gd")

var _container: PanelContainer
var _title_lbl: Label
var _sub_lbl: Label
var _mission_lbl: Label
var _hint_lbl: Label

var _display_timer: float = 0.0
var _fade_timer: float = 0.0
var _is_fading: bool = false
const DISPLAY_DURATION: float = 5.5
const FADE_DURATION: float = 1.0

func _init() -> void:
	layer = 85

func _ready() -> void:
	_build_ui()
	visible = false

func _build_ui() -> void:
	_container = PanelContainer.new()
	_container.anchor_left = 0.5
	_container.anchor_top = 0.82
	_container.anchor_right = 0.5
	_container.anchor_bottom = 0.82
	_container.offset_left = -340
	_container.offset_top = -65
	_container.offset_right = 340
	_container.offset_bottom = 65
	_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.12, 0.90)
	style.border_color = Color(0.35, 0.75, 0.95, 0.75)
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_container.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)

	var top_hbox: HBoxContainer = HBoxContainer.new()
	_title_lbl = Label.new()
	_title_lbl.text = "🧭 DAY 1 — 08:00 | EMERALD BASIN"
	_title_lbl.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
	_title_lbl.add_theme_font_size_override("font_size", 13)
	top_hbox.add_child(_title_lbl)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)

	_sub_lbl = Label.new()
	_sub_lbl.text = "SKYSPIRE CONTINENT (720m)"
	_sub_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	_sub_lbl.add_theme_font_size_override("font_size", 10)
	top_hbox.add_child(_sub_lbl)
	vbox.add_child(top_hbox)

	_mission_lbl = Label.new()
	_mission_lbl.text = "MISSION: Traverse the island, map all 11 ancient landmarks, and catalog living wildlife in your Field Journal."
	_mission_lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98))
	_mission_lbl.add_theme_font_size_override("font_size", 11)
	_mission_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_mission_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.text = "[W/A/S/D] Move | [Shift] Sprint | [C] Stealth | [J] Field Journal | [M] Map | [Esc] Pause & Settings"
	_hint_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.75))
	_hint_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(_hint_lbl)

	_container.add_child(vbox)
	add_child(_container)

func display_intro(day_hour_str: String = "DAY 1 — 08:00", location_name: String = "EMERALD BASIN", seed_val: int = 1337) -> void:
	_title_lbl.text = "🧭 %s | %s" % [day_hour_str, location_name]
	_sub_lbl.text = "CONTINENTAL SEED: #%d (720m)" % seed_val
	_container.modulate = Color(1.0, 1.0, 1.0, 1.0)
	visible = true
	_display_timer = 0.0
	_fade_timer = 0.0
	_is_fading = false

	var feedback = UIAudioFeedback.get_singleton()
	if feedback:
		feedback.play_discovery()

func _process(delta: float) -> void:
	if not visible:
		return

	if not _is_fading:
		_display_timer += delta
		if _display_timer >= DISPLAY_DURATION:
			_is_fading = true
	else:
		_fade_timer += delta
		var alpha: float = 1.0 - clampf(_fade_timer / FADE_DURATION, 0.0, 1.0)
		_container.modulate = Color(1.0, 1.0, 1.0, alpha)
		if _fade_timer >= FADE_DURATION:
			visible = false
			_is_fading = false

func dismiss_now() -> void:
	if visible and not _is_fading:
		_is_fading = true
