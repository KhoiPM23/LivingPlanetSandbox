class_name AlchemyModal
extends CanvasLayer

## Living Planet Sandbox — Genshin-Style Glassmorphic Alchemy Crafting Modal
## Displays botanical ingredients inventory, craftable potion recipes, and one-click brewing.

signal alchemy_closed()

const AlchemyCraftingSystem = preload("res://core/gameplay/alchemy_crafting_system.gd")

var _alchemy_system: Node = null
var _is_open: bool = false

# UI Elements
var _root_panel: PanelContainer = null
var _ing_label: Label = null
var _cards_container: VBoxContainer = null

func _init() -> void:
	layer = 82
	_build_ui()

func _ready() -> void:
	visible = false

func setup(alchemy_sys: Node) -> void:
	_alchemy_system = alchemy_sys
	if _alchemy_system and _alchemy_system.has_signal("inventory_updated"):
		_alchemy_system.inventory_updated.connect(func(_inv): _refresh_ui())

func open_modal() -> void:
	_is_open = true
	visible = true
	_refresh_ui()

func close_modal() -> void:
	_is_open = false
	visible = false
	alchemy_closed.emit()

func is_open() -> bool:
	return _is_open

func _build_ui() -> void:
	var root: Control = Control.new()
	root.name = "AlchemyRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	_root_panel = PanelContainer.new()
	_root_panel.name = "AlchemyPanel"
	_root_panel.custom_minimum_size = Vector2(680.0, 520.0)
	_root_panel.set_anchors_preset(Control.PRESET_CENTER)
	_root_panel.offset_left = -340.0
	_root_panel.offset_right = 340.0
	_root_panel.offset_top = -260.0
	_root_panel.offset_bottom = 260.0

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.15, 0.92) # Deep frosted slate
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.72, 0.40, 0.95) # Imperial gold trim
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 24
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 22.0
	_root_panel.add_theme_stylebox_override("panel", style)
	root.add_child(_root_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_root_panel.add_child(vbox)

	# Header Title
	var title_lbl: Label = Label.new()
	title_lbl.text = "⚗️ BÀN CHẾ TÁC GIẢ KIM THẢO DƯỢC"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.50))
	vbox.add_child(title_lbl)

	# Ingredients Stock Status
	_ing_label = Label.new()
	_ing_label.text = "Kho dược liệu: 🌿 Tảo bẹ: 0 | 🫐 Quả mọng: 0 | ❄️ Thảo dược núi: 0"
	_ing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ing_label.add_theme_font_size_override("font_size", 14)
	_ing_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	vbox.add_child(_ing_label)

	# Cards Container
	_cards_container = VBoxContainer.new()
	_cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards_container.add_theme_constant_override("separation", 10)
	vbox.add_child(_cards_container)

	# Close Button
	var close_btn: Button = Button.new()
	close_btn.text = "✖ Đóng Bàn Chế Tác [Esc]"
	close_btn.custom_minimum_size = Vector2(0.0, 38.0)
	var b_style: StyleBoxFlat = StyleBoxFlat.new()
	b_style.bg_color = Color(0.18, 0.22, 0.30, 0.85)
	b_style.border_width_left = 1
	b_style.border_width_right = 1
	b_style.border_width_top = 1
	b_style.border_width_bottom = 1
	b_style.border_color = Color(0.65, 0.65, 0.70, 0.5)
	b_style.corner_radius_top_left = 8
	b_style.corner_radius_top_right = 8
	b_style.corner_radius_bottom_left = 8
	b_style.corner_radius_bottom_right = 8
	close_btn.add_theme_stylebox_override("normal", b_style)
	close_btn.pressed.connect(close_modal)
	vbox.add_child(close_btn)

func _refresh_ui() -> void:
	if not _alchemy_system or not _cards_container:
		return

	var inv = _alchemy_system.inventory
	_ing_label.text = "Kho dược liệu: 🌿 Tảo bẹ: %d | 🫐 Quả mọng: %d | ❄️ Thảo dược núi: %d" % [
		inv.get("kelp_fronds", 0),
		inv.get("forest_berries", 0),
		inv.get("mountain_herbs", 0)
	]

	for child in _cards_container.get_children():
		child.queue_free()

	for recipe_id in AlchemyCraftingSystem.RECIPES.keys():
		var r: Dictionary = AlchemyCraftingSystem.RECIPES[recipe_id]
		var can_brew: bool = _alchemy_system.can_craft(recipe_id)
		var is_active: bool = _alchemy_system.is_buff_active(recipe_id)

		var card: PanelContainer = PanelContainer.new()
		var c_style: StyleBoxFlat = StyleBoxFlat.new()
		c_style.bg_color = Color(0.12, 0.15, 0.22, 0.85) if can_brew else Color(0.08, 0.10, 0.14, 0.65)
		c_style.border_width_left = 1
		c_style.border_width_right = 1
		c_style.border_width_top = 1
		c_style.border_width_bottom = 1
		c_style.border_color = Color(0.85, 0.72, 0.40, 0.70) if can_brew else Color(0.3, 0.35, 0.40, 0.40)
		c_style.corner_radius_top_left = 10
		c_style.corner_radius_top_right = 10
		c_style.corner_radius_bottom_left = 10
		c_style.corner_radius_bottom_right = 10
		c_style.content_margin_left = 14.0
		c_style.content_margin_right = 14.0
		c_style.content_margin_top = 10.0
		c_style.content_margin_bottom = 10.0
		card.add_theme_stylebox_override("panel", c_style)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		card.add_child(hbox)

		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)

		var r_title: Label = Label.new()
		r_title.text = r["title"]
		r_title.add_theme_font_size_override("font_size", 15)
		r_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65) if can_brew else Color(0.6, 0.65, 0.70))
		info_vbox.add_child(r_title)

		var r_desc: Label = Label.new()
		r_desc.text = r["desc"]
		r_desc.add_theme_font_size_override("font_size", 12)
		r_desc.add_theme_color_override("font_color", Color(0.80, 0.85, 0.90))
		info_vbox.add_child(r_desc)

		var brew_btn: Button = Button.new()
		brew_btn.custom_minimum_size = Vector2(140.0, 36.0)
		brew_btn.disabled = not can_brew

		if is_active:
			var remain: float = _alchemy_system.get_buff_remaining(recipe_id)
			brew_btn.text = "Đang Hiệu Lực (%ds)" % int(remain)
		else:
			brew_btn.text = "Chế Tác & Uống" if can_brew else "Thiếu Nguyên Liệu"

		var rid: String = recipe_id
		brew_btn.pressed.connect(func():
			if _alchemy_system:
				_alchemy_system.craft_potion(rid)
		)
		hbox.add_child(brew_btn)

		_cards_container.add_child(card)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			close_modal()
			get_viewport().set_input_as_handled()
