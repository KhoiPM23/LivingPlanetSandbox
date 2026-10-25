@tool
class_name WaypointTeleportModal
extends Control

## Living Planet Sandbox — Genshin-Style Teleport Waypoint Modal
## Displays island map locations, unlock statuses, and allows instant fast-travel.

signal teleport_requested(target_wp_id: String)
signal modal_closed

var _network: Node = null
var _container: VBoxContainer = null
var _is_open: bool = false

func setup(network: Node) -> void:
	_network = network
	_build_ui()
	visible = false

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Darkened Backdrop
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.10, 0.72)
	add_child(bg)

	# Center Panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 480)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.13, 0.20, 0.94)
	style.border_color = Color(0.24, 0.78, 0.85, 0.85)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 14)
	panel.add_child(root_vbox)

	# Header Title
	var header = Label.new()
	header.text = "✦ MẠNG LƯỚI ĐIỂM DỊCH CHUYỂN ANEMO ✦"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.35, 0.95, 0.90))
	root_vbox.add_child(header)

	var sub_label = Label.new()
	sub_label.text = "Chọn điểm dịch chuyển đã khai mở để dịch chuyển tức thời qua luồng gió nguyên tố."
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_label.add_theme_font_size_override("font_size", 13)
	sub_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
	root_vbox.add_child(sub_label)

	var sep = HSeparator.new()
	root_vbox.add_child(sep)

	# Scroll Container for Waypoint entries
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(510, 260)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_container = VBoxContainer.new()
	_container.add_theme_constant_override("separation", 10)
	_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_container)

	# Close Button
	var close_btn = Button.new()
	close_btn.text = "Đóng [ESC]"
	close_btn.custom_minimum_size = Vector2(140, 36)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(close_modal)
	root_vbox.add_child(close_btn)

func open_modal() -> void:
	_is_open = true
	visible = true
	_refresh_list()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_modal() -> void:
	_is_open = false
	visible = false
	modal_closed.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func is_open() -> bool:
	return _is_open

func _refresh_list() -> void:
	if not _container or not _network:
		return

	for c in _container.get_children():
		c.queue_free()

	for wp in _network.get_waypoints():
		var row = PanelContainer.new()
		var row_style = StyleBoxFlat.new()
		row_style.bg_color = Color(0.14, 0.18, 0.26, 0.85) if wp.is_unlocked else Color(0.12, 0.12, 0.16, 0.65)
		row_style.border_color = Color(0.25, 0.85, 0.80, 0.7) if wp.is_unlocked else Color(0.65, 0.25, 0.20, 0.5)
		row_style.border_width_left = 2
		row_style.border_width_right = 1
		row_style.border_width_top = 1
		row_style.border_width_bottom = 1
		row_style.corner_radius_top_left = 6
		row_style.corner_radius_top_right = 6
		row_style.corner_radius_bottom_left = 6
		row_style.corner_radius_bottom_right = 6
		row_style.content_margin_left = 14
		row_style.content_margin_right = 14
		row_style.content_margin_top = 10
		row_style.content_margin_bottom = 10
		row.add_theme_stylebox_override("panel", row_style)
		_container.add_child(row)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		row.add_child(hbox)

		var icon_lbl = Label.new()
		icon_lbl.text = "✨" if wp.is_unlocked else "🔴"
		icon_lbl.add_theme_font_size_override("font_size", 22)
		hbox.add_child(icon_lbl)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)

		var name_lbl = Label.new()
		name_lbl.text = wp.waypoint_name
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0) if wp.is_unlocked else Color(0.65, 0.65, 0.70))
		info_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = wp.waypoint_desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.68, 0.75, 0.82))
		info_vbox.add_child(desc_lbl)

		if wp.is_unlocked:
			var tp_btn = Button.new()
			tp_btn.text = "Dịch Chuyển"
			tp_btn.custom_minimum_size = Vector2(110, 32)
			var wp_target_id: String = wp.waypoint_id
			tp_btn.pressed.connect(func():
				teleport_requested.emit(wp_target_id)
				close_modal()
			)
			hbox.add_child(tp_btn)
		else:
			var locked_lbl = Label.new()
			locked_lbl.text = "Chưa Khai Mở"
			locked_lbl.add_theme_font_size_override("font_size", 12)
			locked_lbl.add_theme_color_override("font_color", Color(0.95, 0.45, 0.35))
			hbox.add_child(locked_lbl)

func _unhandled_input(event: InputEvent) -> void:
	if _is_open and event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			close_modal()
			get_viewport().set_input_as_handled()
