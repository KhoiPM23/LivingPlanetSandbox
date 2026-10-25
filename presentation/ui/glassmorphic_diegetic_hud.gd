class_name GlassmorphicDiegeticHUD
extends CanvasLayer

## Living Planet Sandbox — Block 65 Phase 5.2 Glassmorphic Diegetic HUD.
## Combines Genshin Impact's elegant frosted aesthetic with RDR2's immersive contextual minimalism:
## 1. Frosted Glassmorphic Elemental Orb & Status Header
## 2. Dynamic Radial Skill Cooldown Arc & Primed Glow
## 3. Ergonomic Translucent Pill Hotbar with Quick Key Glyphs
## 4. Context-Sensitive Auto-Fade (Retracts during peaceful strolls, awakens during action)

signal hud_visibility_changed(is_visible: bool)

var _is_hud_visible: bool = true
var _auto_fade_timer: float = 0.0
const AUTO_FADE_TIMEOUT: float = 4.0
var _target_alpha: float = 1.0
var _current_alpha: float = 1.0

# UI Controls
var _root_container: Control
var _top_left_card: PanelContainer
var _element_orb: Control
var _element_label: Label
var _cooldown_arc: Control
var _cooldown_progress: float = 1.0 # 0.0 to 1.0 (1.0 = ready)
var _health_bar: ProgressBar
var _stamina_mini_bar: ProgressBar

var _bottom_pill_bar: PanelContainer
var _hotbar_box: HBoxContainer

# State tracking
var _current_element_name: String = "Phong (Anemo)"
var _current_element_symbol: String = "🌀"
var _current_element_color: Color = Color(0.45, 0.95, 0.85)

func _init() -> void:
	name = "GlassmorphicDiegeticHUD"
	layer = 12 # Above standard scene elements, below system modals

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	_root_container = Control.new()
	_root_container.name = "HUDContainer"
	_root_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root_container)

	_build_top_left_card()
	_build_bottom_pill_bar()

func _build_top_left_card() -> void:
	_top_left_card = PanelContainer.new()
	_top_left_card.name = "TopLeftElementalCard"
	_top_left_card.position = Vector2(24.0, 24.0)
	_top_left_card.custom_minimum_size = Vector2(210.0, 72.0)
	_top_left_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.06, 0.10, 0.14, 0.65) # Frosted midnight slate
	card_style.set_corner_radius_all(16)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.55, 0.85, 0.95, 0.35) # Luminescent celestial cyan rim
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	card_style.shadow_size = 8
	_top_left_card.add_theme_stylebox_override("panel", card_style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	_top_left_card.add_child(hbox)

	# 1. Circular Elemental Orb
	_element_orb = Control.new()
	_element_orb.name = "ElementOrb"
	_element_orb.custom_minimum_size = Vector2(56.0, 56.0)
	_element_orb.draw.connect(_on_draw_element_orb)
	hbox.add_child(_element_orb)

	_element_label = Label.new()
	_element_label.text = "🌀"
	_element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_element_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_element_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_element_label.add_theme_font_size_override("font_size", 24)
	_element_orb.add_child(_element_label)

	# 2. Vital Bars
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox)

	var name_lbl: Label = Label.new()
	name_lbl.text = "Lữ Khách (Traveler)"
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 0.98))
	vbox.add_child(name_lbl)

	# Health bar
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(120.0, 6.0)
	_health_bar.value = 100.0
	_health_bar.show_percentage = false
	var hp_bg: StyleBoxFlat = StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.12, 0.16, 0.18, 0.8)
	hp_bg.set_corner_radius_all(3)
	var hp_fill: StyleBoxFlat = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.32, 0.85, 0.45) # Emerald life
	hp_fill.set_corner_radius_all(3)
	_health_bar.add_theme_stylebox_override("background", hp_bg)
	_health_bar.add_theme_stylebox_override("fill", hp_fill)
	vbox.add_child(_health_bar)

	_root_container.add_child(_top_left_card)

func _on_draw_element_orb() -> void:
	var center: Vector2 = _element_orb.size * 0.5
	var radius: float = center.x - 4.0

	# Background circle
	_element_orb.draw_circle(center, radius, Color(0.08, 0.14, 0.20, 0.85))

	# Cooldown progress ring
	var sweep_angle: float = _cooldown_progress * TAU
	if sweep_angle > 0.05:
		_element_orb.draw_arc(center, radius - 2.0, -PI * 0.5, -PI * 0.5 + sweep_angle, 32, _current_element_color, 2.5, true)

	# Outer glowing ring
	_element_orb.draw_arc(center, radius, 0.0, TAU, 36, Color(1.0, 1.0, 1.0, 0.25), 1.0, true)

func _build_bottom_pill_bar() -> void:
	_bottom_pill_bar = PanelContainer.new()
	_bottom_pill_bar.name = "BottomPillBar"
	_bottom_pill_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bottom_pill_bar.position.y -= 36.0
	_bottom_pill_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pill_style: StyleBoxFlat = StyleBoxFlat.new()
	pill_style.bg_color = Color(0.05, 0.08, 0.12, 0.55)
	pill_style.set_corner_radius_all(20)
	pill_style.border_width_left = 1
	pill_style.border_width_top = 1
	pill_style.border_width_right = 1
	pill_style.border_width_bottom = 1
	pill_style.border_color = Color(0.70, 0.85, 0.95, 0.25)
	_bottom_pill_bar.add_theme_stylebox_override("panel", pill_style)

	_hotbar_box = HBoxContainer.new()
	_hotbar_box.add_theme_constant_override("separation", 16)
	_bottom_pill_bar.add_child(_hotbar_box)

	var hotkeys: Array[Dictionary] = [
		{"key": "Z", "action": "Hệ Nguyên Tố", "icon": "🌀"},
		{"key": "Q", "action": "Kỹ Năng", "icon": "⚡"},
		{"key": "Space", "action": "Cánh Lượn", "icon": "🪽"},
		{"key": "F", "action": "Chiến Mã", "icon": "🐎"},
		{"key": "E", "action": "Tương Tác", "icon": "✋"},
		{"key": "H", "action": "Ẩn HUD", "icon": "👁️"}
	]

	for hk in hotkeys:
		var item_hbox: HBoxContainer = HBoxContainer.new()
		item_hbox.add_theme_constant_override("separation", 6)

		var badge: PanelContainer = PanelContainer.new()
		var b_style: StyleBoxFlat = StyleBoxFlat.new()
		b_style.bg_color = Color(0.20, 0.28, 0.35, 0.75)
		b_style.set_corner_radius_all(6)
		badge.add_theme_stylebox_override("panel", b_style)

		var k_lbl: Label = Label.new()
		k_lbl.text = " %s " % hk["key"]
		k_lbl.add_theme_font_size_override("font_size", 11)
		k_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
		badge.add_child(k_lbl)
		item_hbox.add_child(badge)

		var act_lbl: Label = Label.new()
		act_lbl.text = "%s %s" % [hk["icon"], hk["action"]]
		act_lbl.add_theme_font_size_override("font_size", 12)
		act_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 0.94))
		item_hbox.add_child(act_lbl)

		_hotbar_box.add_child(item_hbox)

	_root_container.add_child(_bottom_pill_bar)

func update_hud(delta: float, is_acting: bool, element_idx: int, cooldown_ratio: float) -> void:
	if not _is_hud_visible:
		return

	_cooldown_progress = clampf(cooldown_ratio, 0.0, 1.0)
	if _element_orb:
		_element_orb.queue_redraw()

	# RDR2-style contextual auto-fade
	if is_acting:
		_auto_fade_timer = 0.0
		_target_alpha = 1.0
	else:
		_auto_fade_timer += delta
		if _auto_fade_timer >= AUTO_FADE_TIMEOUT:
			_target_alpha = 0.22 # Smoothly settle into whisper-opacity during peaceful contemplation
		else:
			_target_alpha = 1.0

	_current_alpha = lerpf(_current_alpha, _target_alpha, delta * 4.5)
	if _root_container:
		_root_container.modulate.a = _current_alpha

func set_element(element_idx: int) -> void:
	match element_idx:
		1: # ANEMO
			_current_element_name = "Phong (Anemo)"
			_current_element_symbol = "🌀"
			_current_element_color = Color(0.45, 0.95, 0.85)
		2: # PYRO
			_current_element_name = "Hỏa (Pyro)"
			_current_element_symbol = "🔥"
			_current_element_color = Color(1.0, 0.48, 0.22)
		3: # HYDRO
			_current_element_name = "Thủy (Hydro)"
			_current_element_symbol = "💧"
			_current_element_color = Color(0.35, 0.72, 1.0)
		4: # CRYO
			_current_element_name = "Băng (Cryo)"
			_current_element_symbol = "❄️"
			_current_element_color = Color(0.70, 0.92, 1.0)

	if _element_label:
		_element_label.text = _current_element_symbol
	if _element_orb:
		_element_orb.queue_redraw()

func toggle_visibility() -> void:
	_is_hud_visible = not _is_hud_visible
	visible = _is_hud_visible
	hud_visibility_changed.emit(_is_hud_visible)

func is_hud_visible() -> bool:
	return _is_hud_visible

func wake_hud() -> void:
	_auto_fade_timer = 0.0
	_target_alpha = 1.0
	_current_alpha = 1.0
	if _root_container:
		_root_container.modulate.a = 1.0

