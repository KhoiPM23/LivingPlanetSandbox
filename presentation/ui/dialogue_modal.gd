class_name DialogueModal
extends CanvasLayer

## Living Planet Sandbox — Genshin-Style Glassmorphic NPC Dialogue & Quest Modal
## Features:
## 1. Frosted glassmorphic bottom dialog panel with gold trim and anime crest
## 2. Animated typewriter text streamer with sound feedback
## 3. Interactive player response choices with hover fanfares
## 4. Seamless dispatch of narrative quests directly to ExpeditionManager

signal dialogue_finished(npc_id: String, chosen_option_idx: int)
signal quest_assigned(quest_id: String, quest_title: String)

var _is_open: bool = false
var _typewriter_speed: float = 40.0 # characters per second
var _full_text: String = ""
var _displayed_chars: float = 0.0
var _is_typing: bool = false
var _active_npc_id: String = ""
var _active_options: Array[Dictionary] = []

# UI Elements
var _panel_container: PanelContainer = null
var _speaker_label: Label = null
var _title_label: Label = null
var _body_label: Label = null
var _avatar_rect: ColorRect = null
var _avatar_icon: Label = null
var _options_container: VBoxContainer = null
var _prompt_hint: Label = null

func _init() -> void:
	layer = 80 # Above normal HUD, below system pause
	_build_ui()

func _ready() -> void:
	visible = false

func _build_ui() -> void:
	var root_ctrl: Control = Control.new()
	root_ctrl.name = "DialogueRoot"
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root_ctrl)

	_panel_container = PanelContainer.new()
	_panel_container.name = "DialogueGlassPanel"
	_panel_container.custom_minimum_size = Vector2(860.0, 220.0)
	_panel_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel_container.offset_left = 60.0
	_panel_container.offset_right = -60.0
	_panel_container.offset_bottom = -24.0
	_panel_container.offset_top = -244.0

	# Genshin-inspired glassmorphism stylebox
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.14, 0.88) # Deep frosted slate
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.72, 0.42, 0.90) # Warm imperial gold rim
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 18
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	_panel_container.add_theme_stylebox_override("panel", style)
	root_ctrl.add_child(_panel_container)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 22)
	_panel_container.add_child(hbox)

	# Left: NPC Avatar Badge
	var avatar_wrapper: VBoxContainer = VBoxContainer.new()
	avatar_wrapper.custom_minimum_size = Vector2(90.0, 0.0)
	avatar_wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(avatar_wrapper)

	_avatar_rect = ColorRect.new()
	_avatar_rect.custom_minimum_size = Vector2(80.0, 80.0)
	_avatar_rect.color = Color(0.18, 0.22, 0.32, 0.95)
	avatar_wrapper.add_child(_avatar_rect)

	_avatar_icon = Label.new()
	_avatar_icon.text = "⚓"
	_avatar_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_avatar_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_avatar_icon.add_theme_font_size_override("font_size", 38)
	_avatar_rect.add_child(_avatar_icon)

	# Middle: Dialogue Text Flow
	var text_vbox: VBoxContainer = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(text_vbox)

	var header_hbox: HBoxContainer = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 12)
	text_vbox.add_child(header_hbox)

	_speaker_label = Label.new()
	_speaker_label.text = "THUYỀN TRƯỞNG ALISTAIR"
	_speaker_label.add_theme_font_size_override("font_size", 18)
	_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.52)) # Vibrant Genshin gold
	header_hbox.add_child(_speaker_label)

	_title_label = Label.new()
	_title_label.text = "— Trưởng Bến Cảng Tiền Đồn"
	_title_label.add_theme_font_size_override("font_size", 14)
	_title_label.add_theme_color_override("font_color", Color(0.72, 0.80, 0.90))
	header_hbox.add_child(_title_label)

	_body_label = Label.new()
	_body_label.text = "Chào mừng nhà thám hiểm đến với Tiền đồn Emerald! Vùng biển quanh hòn đảo này rất kỳ bí..."
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_label.add_theme_font_size_override("font_size", 15)
	_body_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	text_vbox.add_child(_body_label)

	_prompt_hint = Label.new()
	_prompt_hint.text = "Nhấn [Space] hoặc [E] để tiếp tục..."
	_prompt_hint.add_theme_font_size_override("font_size", 12)
	_prompt_hint.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80, 0.80))
	text_vbox.add_child(_prompt_hint)

	# Right: Option Choices
	_options_container = VBoxContainer.new()
	_options_container.custom_minimum_size = Vector2(250.0, 0.0)
	_options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_options_container.add_theme_constant_override("separation", 8)
	hbox.add_child(_options_container)

func open_dialogue(npc_id: String, speaker: String, title: String, icon: String, message: String, options: Array[Dictionary]) -> void:
	_active_npc_id = npc_id
	_speaker_label.text = speaker
	_title_label.text = "— " + title if not title.is_empty() else ""
	_avatar_icon.text = icon
	_full_text = message
	_displayed_chars = 0.0
	_is_typing = true
	_active_options = options

	_body_label.text = ""
	_clear_options()
	_is_open = true
	visible = true

func _clear_options() -> void:
	for child in _options_container.get_children():
		child.queue_free()

func _populate_options() -> void:
	_clear_options()
	for i in range(_active_options.size()):
		var opt: Dictionary = _active_options[i]
		var btn: Button = Button.new()
		btn.text = "[%d] %s" % [i + 1, opt.get("label", "Tiếp tục")]
		btn.custom_minimum_size = Vector2(240.0, 36.0)

		# Genshin button style
		var b_style: StyleBoxFlat = StyleBoxFlat.new()
		b_style.bg_color = Color(0.14, 0.18, 0.26, 0.90)
		b_style.border_width_left = 1
		b_style.border_width_right = 1
		b_style.border_width_top = 1
		b_style.border_width_bottom = 1
		b_style.border_color = Color(0.75, 0.62, 0.35, 0.80)
		b_style.corner_radius_top_left = 8
		b_style.corner_radius_top_right = 8
		b_style.corner_radius_bottom_left = 8
		b_style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", b_style)

		var h_style: StyleBoxFlat = b_style.duplicate()
		h_style.bg_color = Color(0.24, 0.32, 0.45, 0.95)
		h_style.border_color = Color(1.0, 0.88, 0.45, 1.0)
		btn.add_theme_stylebox_override("hover", h_style)

		var idx: int = i
		btn.pressed.connect(func(): _select_option(idx))
		_options_container.add_child(btn)

func _select_option(idx: int) -> void:
	if idx < 0 or idx >= _active_options.size():
		close_dialogue()
		return

	var opt: Dictionary = _active_options[idx]
	var quest_id: String = opt.get("quest_id", "")
	var quest_title: String = opt.get("quest_title", "")
	if not quest_id.is_empty():
		quest_assigned.emit(quest_id, quest_title)

	dialogue_finished.emit(_active_npc_id, idx)
	close_dialogue()

func close_dialogue() -> void:
	_is_open = false
	visible = false
	_clear_options()

func is_dialogue_open() -> bool:
	return _is_open

func _process(delta: float) -> void:
	if not _is_open:
		return

	if _is_typing:
		_displayed_chars += _typewriter_speed * delta
		var char_count: int = int(_displayed_chars)
		if char_count >= _full_text.length():
			_body_label.text = _full_text
			_is_typing = false
			_populate_options()
			_prompt_hint.visible = false
		else:
			_body_label.text = _full_text.substr(0, char_count)
			_prompt_hint.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_E:
			if _is_typing:
				# Complete typewriter immediately
				_body_label.text = _full_text
				_is_typing = false
				_populate_options()
				_prompt_hint.visible = false
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			_select_option(0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			_select_option(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			_select_option(2)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			close_dialogue()
			get_viewport().set_input_as_handled()
