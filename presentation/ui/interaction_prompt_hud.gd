class_name InteractionPromptHUD
extends Control

## Living Planet Sandbox — Block 48 Genshin-Style Dynamic Interaction & Foraging Toast HUD
## Displays context-sensitive floating interaction prompts ([E] Trò chuyện / Thu thập / Chèo thuyền)
## and floating item pickup toasts (+1 Cỏ Gió Đảo) with glassmorphic styling.

var _prompt_card: PanelContainer = null
var _key_badge: Label = null
var _action_icon: Label = null
var _action_title: Label = null
var _target_name: Label = null
var _toast_container: VBoxContainer = null

var _target_alpha: float = 0.0
var _current_alpha: float = 0.0
var _active_prompt_id: String = ""

func _init() -> void:
	name = "InteractionPromptHUD"
	mouse_filter = MOUSE_FILTER_IGNORE

func _ready() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_right = 0.0
	offset_top = 0.0
	offset_bottom = 0.0

	_build_prompt_card()
	_build_toast_container()

func _build_prompt_card() -> void:
	_prompt_card = PanelContainer.new()
	_prompt_card.name = "PromptCard"
	_prompt_card.mouse_filter = MOUSE_FILTER_IGNORE

	# Position near lower-center of viewport (Genshin action prompt position)
	_prompt_card.anchor_left = 0.5
	_prompt_card.anchor_right = 0.5
	_prompt_card.anchor_top = 0.68
	_prompt_card.anchor_bottom = 0.68
	_prompt_card.offset_left = -150.0
	_prompt_card.offset_right = 150.0
	_prompt_card.offset_top = -22.0
	_prompt_card.offset_bottom = 22.0

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.14, 0.88)
	style.border_color = Color(0.40, 0.78, 1.0, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(22)
	style.content_margin_left = 14
	style.content_margin_right = 18
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	_prompt_card.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.name = "PromptHBox"
	hbox.mouse_filter = MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_prompt_card.add_child(hbox)

	# [E] Key pill badge
	var key_panel: PanelContainer = PanelContainer.new()
	var key_style: StyleBoxFlat = StyleBoxFlat.new()
	key_style.bg_color = Color(0.95, 0.82, 0.35, 0.95)
	key_style.set_corner_radius_all(6)
	key_style.content_margin_left = 8
	key_style.content_margin_right = 8
	key_style.content_margin_top = 2
	key_style.content_margin_bottom = 2
	key_panel.add_theme_stylebox_override("panel", key_style)

	_key_badge = Label.new()
	_key_badge.text = "E"
	_key_badge.add_theme_color_override("font_color", Color(0.05, 0.06, 0.08))
	_key_badge.add_theme_font_size_override("font_size", 14)
	key_panel.add_child(_key_badge)
	hbox.add_child(key_panel)

	# Icon
	_action_icon = Label.new()
	_action_icon.text = "💬"
	_action_icon.add_theme_font_size_override("font_size", 16)
	hbox.add_child(_action_icon)

	# Text column
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 0)

	_action_title = Label.new()
	_action_title.text = "Trò chuyện"
	_action_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_action_title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_action_title)

	_target_name = Label.new()
	_target_name.text = "Thuyền trưởng Alistair"
	_target_name.add_theme_color_override("font_color", Color(0.68, 0.88, 1.0, 0.9))
	_target_name.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_target_name)

	hbox.add_child(vbox)

	_prompt_card.modulate.a = 0.0
	add_child(_prompt_card)

func _build_toast_container() -> void:
	_toast_container = VBoxContainer.new()
	_toast_container.name = "ToastContainer"
	_toast_container.mouse_filter = MOUSE_FILTER_IGNORE
	_toast_container.anchor_left = 0.72
	_toast_container.anchor_right = 0.96
	_toast_container.anchor_top = 0.42
	_toast_container.anchor_bottom = 0.85
	_toast_container.add_theme_constant_override("separation", 8)
	add_child(_toast_container)

func show_prompt(prompt_id: String, action_title: String, target_name: String, icon: String = "💬") -> void:
	_active_prompt_id = prompt_id
	if _action_title:
		_action_title.text = action_title
	if _target_name:
		_target_name.text = target_name
	if _action_icon:
		_action_icon.text = icon
	_target_alpha = 1.0

func hide_prompt(prompt_id: String = "") -> void:
	if prompt_id == "" or _active_prompt_id == prompt_id:
		_target_alpha = 0.0
		_active_prompt_id = ""

func is_prompt_visible() -> bool:
	return _target_alpha > 0.1

func get_active_prompt_id() -> String:
	return _active_prompt_id

func show_pickup_toast(item_name: String, count: int = 1, icon: String = "🌿") -> void:
	if not _toast_container:
		return

	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = MOUSE_FILTER_IGNORE

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.18, 0.90)
	style.border_color = Color(0.35, 0.85, 0.55, 0.80)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 12
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.mouse_filter = MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	var icon_lbl: Label = Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 15)
	hbox.add_child(icon_lbl)

	var name_lbl: Label = Label.new()
	name_lbl.text = "%s  +%d" % [item_name, count]
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.98, 0.94))
	name_lbl.add_theme_font_size_override("font_size", 13)
	hbox.add_child(name_lbl)

	_toast_container.add_child(panel)

	# Animate fade in and fade out
	panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(2.2)
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(Callable(panel, "queue_free"))

func _process(delta: float) -> void:
	_current_alpha = lerpf(_current_alpha, _target_alpha, clampf(14.0 * delta, 0.0, 1.0))
	if _prompt_card:
		_prompt_card.modulate.a = _current_alpha
		_prompt_card.visible = _current_alpha > 0.01
