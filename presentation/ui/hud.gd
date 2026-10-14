class_name WorldHUD
extends CanvasLayer

## Comprehensive experiment tools HUD & Observability dashboard for Living Planet Sandbox.
## Displays real-time simulation metrics, live population chart, inspector, event log, tool palette, and toasts.

@export var bootstrap_path: NodePath = ".."
@export var camera_path: NodePath
@export var tool_controller_path: NodePath

var _bootstrap: WorldBootstrap = null
var _camera: Camera3D = null
var _tool_controller: PlayerToolController = null

var _visible: bool = true

# UI References
var _container: Control
var _top_panel: PanelContainer
var _time_label: Label
var _speed_label: Label
var _pause_btn: Button
var _speed_btns: Array[Button] = []

# Left Toolbar
var _toolbar_panel: PanelContainer
var _tool_buttons: Dictionary = {} # ToolMode -> Button
var _radius_label: Label

# Right Observability Panel
var _right_panel: PanelContainer
var _tab_container: TabContainer
var _telemetry_label: Label
var _chart: EcosystemChart
var _chart_title_lbl: Label
var _chart_mode_btn: Button
var _chart_update_timer: float = 0.0
const CHART_UPDATE_INTERVAL: float = 0.35

# Inspector Card
var _inspector_vbox: VBoxContainer
var _inspect_title: Label
var _inspect_details: Label
var _inspect_empty: Label

# Event Log Panel
var _event_log_vbox: VBoxContainer
var _event_scroll: ScrollContainer
var _recent_events: Array[Dictionary] = []
const MAX_EVENT_LOG: int = 40

# Toast Banner
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_timer: float = 0.0

# Bottom Bar
var _bottom_bar: PanelContainer

# Menu & Settings Modal
var _seed_lbl: Label
var _menu_modal: PanelContainer
var _modal_tab_container: TabContainer
var _modal_load_btn: Button
var _sens_label: Label
var _flight_label: Label
var _fog_btn: Button
var _screen_mode_btn: Button
var _preset_btn: Button
var _btn_preset_low: Button
var _btn_preset_balanced: Button
var _btn_preset_cinematic: Button
var _preset_desc_lbl: Label
var _preset_status_lbl: Label

# Camera & Exploration
var _compass_label: Label
var _cam_mode_btn: Button
var _bookmark_btn: Button
var _track_entity_btn: Button
var _last_inspected_id: int = -1
var _last_inspected_pos: Vector3 = Vector3.ZERO

# Weather & Wind Telemetry
var _weather_btn: Button
var _weather_telemetry_label: Label


func _ready() -> void:
	layer = 90
	if has_node(bootstrap_path):
		_bootstrap = get_node(bootstrap_path) as WorldBootstrap
	if has_node(camera_path):
		_camera = get_node(camera_path) as Camera3D
	if has_node(tool_controller_path):
		_tool_controller = get_node(tool_controller_path) as PlayerToolController

	_build_ui()
	_connect_signals()

func setup_controllers(bootstrap: WorldBootstrap, tool_controller: PlayerToolController, camera: Camera3D = null) -> void:
	_bootstrap = bootstrap
	_tool_controller = tool_controller
	_camera = camera
	_connect_signals()

func _connect_signals() -> void:
	if _tool_controller:
		if not _tool_controller.tool_changed.is_connected(_on_tool_changed):
			_tool_controller.tool_changed.connect(_on_tool_changed)
		if not _tool_controller.inspection_performed.is_connected(_on_inspection_performed):
			_tool_controller.inspection_performed.connect(_on_inspection_performed)
		if not _tool_controller.action_feedback.is_connected(show_toast):
			_tool_controller.action_feedback.connect(show_toast)
		if not _tool_controller.radius_changed.is_connected(_on_radius_changed):
			_tool_controller.radius_changed.connect(_on_radius_changed)

	if _bootstrap and _bootstrap.world_event_bus:
		var bus: WorldEventBus = _bootstrap.world_event_bus
		if not bus.is_connected("notification_logged", Callable(self, "_on_event_bus_notification")):
			bus.notification_logged.connect(_on_event_bus_notification)
		bus.subscribe("fauna_spawned", Callable(self, "_on_sim_event").bind("BIRTH"))
		bus.subscribe("plant_spawned", Callable(self, "_on_sim_event").bind("PLANT"))
		bus.subscribe("fauna_died", Callable(self, "_on_sim_event").bind("DEATH"))
		bus.subscribe("plant_died", Callable(self, "_on_sim_event").bind("DECAY"))
		bus.subscribe("player_intervention", Callable(self, "_on_sim_event").bind("TOOL"))
		bus.subscribe("weather_changed", Callable(self, "_on_sim_event").bind("WEATHER"))
		bus.subscribe("causal_cascade_observed", Callable(self, "_on_causal_cascade"))

	if _camera is FreeLookCamera:
		var cam: FreeLookCamera = _camera as FreeLookCamera
		if not cam.mode_changed.is_connected(_on_camera_mode_changed):
			cam.mode_changed.connect(_on_camera_mode_changed)
		if not cam.bookmark_reached.is_connected(_on_camera_bookmark_reached):
			cam.bookmark_reached.connect(_on_camera_bookmark_reached)
		if not cam.followed_entity_lost.is_connected(_on_camera_entity_lost):
			cam.followed_entity_lost.connect(_on_camera_entity_lost)


func _build_ui() -> void:
	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)

	_build_top_bar()
	_build_left_toolbar()
	_build_right_observability_panel()
	_build_toast_banner()
	_build_bottom_hint_bar()
	_build_menu_modal()

# =========================================================================
# 1. TOP BAR: CLOCK, SIM CONTROLS, QUICK SAVE/LOAD
# =========================================================================
func _build_top_bar() -> void:
	_top_panel = PanelContainer.new()
	_top_panel.anchor_left = 0.0
	_top_panel.anchor_top = 0.0
	_top_panel.anchor_right = 1.0
	_top_panel.anchor_bottom = 0.0
	_top_panel.offset_left = 12.0
	_top_panel.offset_top = 10.0
	_top_panel.offset_right = -12.0
	_top_panel.offset_bottom = 48.0

	var style: StyleBoxFlat = _create_glass_style(Color(0.05, 0.08, 0.13, 0.88), Color(0.22, 0.42, 0.62, 0.6), 6)
	_top_panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)

	# Title & Seed
	var title: Label = Label.new()
	title.text = "LIVING PLANET SANDBOX"
	title.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	title.add_theme_font_size_override("font_size", 12)
	hbox.add_child(title)

	_seed_lbl = Label.new()
	var seed_val: Variant = _bootstrap.world_seed.master_seed if (_bootstrap and _bootstrap.world_seed) else 1337
	_seed_lbl.text = "[Seed: %s]" % str(seed_val)
	_seed_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	_seed_lbl.add_theme_font_size_override("font_size", 11)
	hbox.add_child(_seed_lbl)

	# Compass Telemetry
	_compass_label = Label.new()
	_compass_label.text = "🧭 N 000°"
	_compass_label.add_theme_color_override("font_color", Color(0.35, 0.9, 0.75))
	_compass_label.add_theme_font_size_override("font_size", 11)
	hbox.add_child(_compass_label)

	# Camera Mode Switcher
	_cam_mode_btn = Button.new()
	_cam_mode_btn.text = "🎥 Free [V]"
	_cam_mode_btn.custom_minimum_size = Vector2(85, 24)
	_cam_mode_btn.pressed.connect(_on_camera_mode_btn_pressed)
	hbox.add_child(_cam_mode_btn)

	# Scenic Viewpoints
	_bookmark_btn = Button.new()
	_bookmark_btn.text = "📍 POI [B]"
	_bookmark_btn.custom_minimum_size = Vector2(75, 24)
	_bookmark_btn.pressed.connect(_on_bookmark_btn_pressed)
	hbox.add_child(_bookmark_btn)

	# Weather State & Cycle Button
	_weather_btn = Button.new()
	_weather_btn.text = "☀️ Clear [Y]"
	_weather_btn.custom_minimum_size = Vector2(105, 24)
	_weather_btn.pressed.connect(_on_cycle_weather_pressed)
	hbox.add_child(_weather_btn)

	# Wind Vector & Ground Wetness Telemetry
	_weather_telemetry_label = Label.new()
	_weather_telemetry_label.text = "💨 -- 0.0m/s | 💧 0%"
	_weather_telemetry_label.add_theme_color_override("font_color", Color(0.70, 0.88, 1.0))
	_weather_telemetry_label.add_theme_font_size_override("font_size", 11)
	hbox.add_child(_weather_telemetry_label)

	hbox.add_child(_create_spacer())


	# Simulation Clock
	_time_label = Label.new()
	_time_label.text = "Day 1 -- 09:00 (Day)"
	_time_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_time_label.add_theme_font_size_override("font_size", 12)
	hbox.add_child(_time_label)

	# Pause / Resume Button
	_pause_btn = Button.new()
	_pause_btn.text = "Pause [Space]"
	_pause_btn.custom_minimum_size = Vector2(85, 24)
	_pause_btn.pressed.connect(_on_pause_pressed)
	hbox.add_child(_pause_btn)

	# Speed Buttons: 0.5x, 1x, 2x, 5x
	var speeds: Array[float] = [0.5, 1.0, 2.0, 5.0]
	for sp: float in speeds:
		var btn: Button = Button.new()
		btn.text = "%.1fx" % sp
		btn.custom_minimum_size = Vector2(42, 24)
		btn.pressed.connect(_on_speed_button_pressed.bind(sp))
		_speed_btns.append(btn)
		hbox.add_child(btn)

	hbox.add_child(_create_spacer())

	# QuickSave / QuickLoad / Reset / Help / Menu / Hide
	var save_btn: Button = Button.new()
	save_btn.text = "Save [F5]"
	save_btn.pressed.connect(_on_quicksave_pressed)
	hbox.add_child(save_btn)

	var load_btn: Button = Button.new()
	load_btn.text = "Load [F9]"
	load_btn.pressed.connect(_on_quickload_pressed)
	hbox.add_child(load_btn)

	var reset_btn: Button = Button.new()
	reset_btn.text = "Reset"
	reset_btn.pressed.connect(_on_reset_pressed)
	hbox.add_child(reset_btn)

	var help_btn: Button = Button.new()
	help_btn.text = "Help [F1]"
	help_btn.pressed.connect(open_help_modal)
	hbox.add_child(help_btn)

	var menu_btn: Button = Button.new()
	menu_btn.text = "Menu [Esc]"
	menu_btn.pressed.connect(toggle_menu_modal)
	hbox.add_child(menu_btn)

	var hide_btn: Button = Button.new()
	hide_btn.text = "Hide [H]"
	hide_btn.pressed.connect(toggle_hud)
	hbox.add_child(hide_btn)

	_top_panel.add_child(hbox)
	_container.add_child(_top_panel)

# =========================================================================
# 2. LEFT TOOLBAR: TOOL PALETTE
# =========================================================================
func _build_left_toolbar() -> void:
	_toolbar_panel = PanelContainer.new()
	_toolbar_panel.anchor_left = 0.0
	_toolbar_panel.anchor_top = 0.0
	_toolbar_panel.anchor_right = 0.0
	_toolbar_panel.anchor_bottom = 0.0
	_toolbar_panel.offset_left = 12.0
	_toolbar_panel.offset_top = 58.0
	_toolbar_panel.offset_right = 145.0
	_toolbar_panel.offset_bottom = 450.0

	var style: StyleBoxFlat = _create_glass_style(Color(0.05, 0.08, 0.13, 0.88), Color(0.22, 0.42, 0.62, 0.6), 6)
	_toolbar_panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)

	var header: Label = Label.new()
	header.text = "EXPERIMENT TOOLS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	header.add_theme_font_size_override("font_size", 10)
	vbox.add_child(header)

	var tools_def: Array[Dictionary] = [
		{"mode": PlayerToolController.ToolMode.INSPECT, "label": "[1] Inspect"},
		{"mode": PlayerToolController.ToolMode.MOISTURE_ADD, "label": "[2] +Moisture"},
		{"mode": PlayerToolController.ToolMode.MOISTURE_SUB, "label": "[3] -Moisture"},
		{"mode": PlayerToolController.ToolMode.SPAWN_PLANT, "label": "[4] +Plant"},
		{"mode": PlayerToolController.ToolMode.SPAWN_HERBIVORE, "label": "[5] +Deer"},
		{"mode": PlayerToolController.ToolMode.SPAWN_PREDATOR, "label": "[6] +Stalker"},
		{"mode": PlayerToolController.ToolMode.DELETE_ENTITY, "label": "[7] Delete"},
		{"mode": PlayerToolController.ToolMode.HEATWAVE, "label": "[8] Heatwave"},
		{"mode": PlayerToolController.ToolMode.FROST, "label": "[9] Frost"},
		{"mode": PlayerToolController.ToolMode.SOIL_FERTILIZE, "label": "[0] Fertilize"},
		{"mode": PlayerToolController.ToolMode.DISASTER_SHOCK, "label": "[-] Disaster"}
	]

	for t in tools_def:
		var mode: PlayerToolController.ToolMode = t["mode"]
		var btn: Button = Button.new()
		btn.text = t["label"]
		btn.custom_minimum_size = Vector2(115, 26)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_tool_button_pressed.bind(mode))
		_tool_buttons[mode] = btn
		vbox.add_child(btn)

	_radius_label = Label.new()
	_radius_label.text = "Radius: 8.0m ([ / ])"
	_radius_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_radius_label.add_theme_color_override("font_color", Color(0.65, 0.8, 0.9))
	_radius_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(_radius_label)

	_toolbar_panel.add_child(vbox)
	_container.add_child(_toolbar_panel)

# =========================================================================
# 3. RIGHT OBSERVABILITY PANEL (TELEMETRY + CHART + INSPECTOR + LOG)
# =========================================================================
func _build_right_observability_panel() -> void:
	_right_panel = PanelContainer.new()
	_right_panel.anchor_left = 1.0
	_right_panel.anchor_top = 0.0
	_right_panel.anchor_right = 1.0
	_right_panel.anchor_bottom = 0.0
	_right_panel.offset_left = -330.0
	_right_panel.offset_top = 58.0
	_right_panel.offset_right = -12.0
	_right_panel.offset_bottom = 430.0

	var style: StyleBoxFlat = _create_glass_style(Color(0.05, 0.08, 0.13, 0.90), Color(0.24, 0.46, 0.68, 0.65), 6)
	_right_panel.add_theme_stylebox_override("panel", style)

	_tab_container = TabContainer.new()
	_tab_container.custom_minimum_size = Vector2(300, 350)
	_tab_container.add_theme_font_size_override("font_size", 11)

	# --- TAB 1: TELEMETRY & CHART ---
	var tab_telemetry: VBoxContainer = VBoxContainer.new()
	tab_telemetry.name = "Telemetry"
	tab_telemetry.add_theme_constant_override("separation", 6)

	_telemetry_label = Label.new()
	_telemetry_label.text = "Gathering telemetry..."
	_telemetry_label.add_theme_font_size_override("font_size", 11)
	_telemetry_label.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
	tab_telemetry.add_child(_telemetry_label)

	var chart_hdr: HBoxContainer = HBoxContainer.new()
	_chart_title_lbl = Label.new()
	_chart_title_lbl.text = "POPULATION & BIOMASS DYNAMICS"
	_chart_title_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	_chart_title_lbl.add_theme_font_size_override("font_size", 10)
	chart_hdr.add_child(_chart_title_lbl)
	chart_hdr.add_child(_create_spacer())

	_chart_mode_btn = Button.new()
	_chart_mode_btn.text = "Populations ▾"
	_chart_mode_btn.add_theme_font_size_override("font_size", 9)
	_chart_mode_btn.pressed.connect(_on_cycle_chart_mode)
	chart_hdr.add_child(_chart_mode_btn)
	tab_telemetry.add_child(chart_hdr)

	_chart = EcosystemChart.new()
	_chart.custom_minimum_size = Vector2(290, 140)
	tab_telemetry.add_child(_chart)

	_tab_container.add_child(tab_telemetry)

	# --- TAB 2: INSPECTOR ---
	var tab_inspect: VBoxContainer = VBoxContainer.new()
	tab_inspect.name = "Inspector"
	tab_inspect.add_theme_constant_override("separation", 6)

	_inspect_title = Label.new()
	_inspect_title.text = "INSPECTION DETAILS"
	_inspect_title.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	_inspect_title.add_theme_font_size_override("font_size", 11)
	tab_inspect.add_child(_inspect_title)

	_inspect_empty = Label.new()
	_inspect_empty.text = "Select [1] Inspect tool and click on the world to inspect entities or terrain cells."
	_inspect_empty.autowrap_mode = TextServer.AUTOWRAP_WORD
	_inspect_empty.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	_inspect_empty.add_theme_font_size_override("font_size", 11)
	tab_inspect.add_child(_inspect_empty)

	_inspect_details = Label.new()
	_inspect_details.text = ""
	_inspect_details.autowrap_mode = TextServer.AUTOWRAP_WORD
	_inspect_details.add_theme_font_size_override("font_size", 11)
	tab_inspect.add_child(_inspect_details)

	_track_entity_btn = Button.new()
	_track_entity_btn.text = "🎯 Track Entity in Camera [F]"
	_track_entity_btn.visible = false
	_track_entity_btn.pressed.connect(_on_track_entity_pressed)
	tab_inspect.add_child(_track_entity_btn)

	_tab_container.add_child(tab_inspect)


	# --- TAB 3: EVENT LOG ---
	var tab_events: VBoxContainer = VBoxContainer.new()
	tab_events.name = "Event Log"
	tab_events.add_theme_constant_override("separation", 4)

	var log_title: Label = Label.new()
	log_title.text = "SIMULATION EVENT HISTORY"
	log_title.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	log_title.add_theme_font_size_override("font_size", 10)
	tab_events.add_child(log_title)

	_event_scroll = ScrollContainer.new()
	_event_scroll.custom_minimum_size = Vector2(290, 260)
	_event_log_vbox = VBoxContainer.new()
	_event_log_vbox.add_theme_constant_override("separation", 2)
	_event_scroll.add_child(_event_log_vbox)
	tab_events.add_child(_event_scroll)

	_tab_container.add_child(tab_events)

	_right_panel.add_child(_tab_container)
	_container.add_child(_right_panel)

# =========================================================================
# 4. FEEDBACK TOAST BANNER
# =========================================================================
func _build_toast_banner() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_top = 0.0
	_toast_panel.anchor_right = 0.5
	_toast_panel.anchor_bottom = 0.0
	_toast_panel.offset_left = -220.0
	_toast_panel.offset_top = 56.0
	_toast_panel.offset_right = 220.0
	_toast_panel.offset_bottom = 88.0
	_toast_panel.visible = false

	var style: StyleBoxFlat = _create_glass_style(Color(0.08, 0.16, 0.24, 0.95), Color(0.35, 0.75, 1.0, 0.8), 6)
	_toast_panel.add_theme_stylebox_override("panel", style)

	_toast_label = Label.new()
	_toast_label.text = "Ready"
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_toast_label.add_theme_font_size_override("font_size", 11)
	_toast_panel.add_child(_toast_label)

	_container.add_child(_toast_panel)

# =========================================================================
# 5. BOTTOM HINT BAR
# =========================================================================
func _build_bottom_hint_bar() -> void:
	_bottom_bar = PanelContainer.new()
	_bottom_bar.anchor_left = 0.5
	_bottom_bar.anchor_top = 1.0
	_bottom_bar.anchor_right = 0.5
	_bottom_bar.anchor_bottom = 1.0
	_bottom_bar.offset_left = -440.0
	_bottom_bar.offset_top = -36.0
	_bottom_bar.offset_right = 440.0
	_bottom_bar.offset_bottom = -10.0

	var style: StyleBoxFlat = _create_glass_style(Color(0.04, 0.06, 0.10, 0.8), Color(0.2, 0.35, 0.5, 0.4), 6)
	_bottom_bar.add_theme_stylebox_override("panel", style)

	var hint: Label = Label.new()
	hint.text = "[W/A/S/D] Move | [V] Flycam ↔ Walker | [Space] Jump / Pause | [Shift] Sprint | [B] POI | [1-0] Tools | [Esc] Menu"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95, 0.85))
	hint.add_theme_font_size_override("font_size", 11)
	_bottom_bar.add_child(hint)


	_container.add_child(_bottom_bar)

# =========================================================================
# 6. MAIN MENU & SETTINGS MODAL
# =========================================================================
func _build_menu_modal() -> void:
	_menu_modal = PanelContainer.new()
	_menu_modal.set_anchors_preset(Control.PRESET_CENTER)
	_menu_modal.custom_minimum_size = Vector2(540, 460)
	_menu_modal.size = Vector2(540, 460)
	_menu_modal.position = Vector2(370, 130)
	_menu_modal.visible = false

	var style: StyleBoxFlat = _create_glass_style(Color(0.06, 0.09, 0.15, 0.96), Color(0.3, 0.65, 0.95, 0.85), 8)
	_menu_modal.add_theme_stylebox_override("panel", style)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)

	# Modal Header
	var header_hbox: HBoxContainer = HBoxContainer.new()
	var modal_title: Label = Label.new()
	modal_title.text = "LIVING PLANET SANDBOX — MENU & SETTINGS"
	modal_title.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	modal_title.add_theme_font_size_override("font_size", 12)
	header_hbox.add_child(modal_title)

	header_hbox.add_child(_create_spacer())

	var close_btn: Button = Button.new()
	close_btn.text = "  ✕  "
	close_btn.pressed.connect(toggle_menu_modal)
	header_hbox.add_child(close_btn)
	main_vbox.add_child(header_hbox)

	# Tab Container
	_modal_tab_container = TabContainer.new()
	_modal_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_modal_tab_container.add_theme_font_size_override("font_size", 11)

	# --- TAB 1: SIMULATION & WORLD ---
	var tab_sim: VBoxContainer = VBoxContainer.new()
	tab_sim.name = "Simulation"
	tab_sim.add_theme_constant_override("separation", 8)

	var resume_btn: Button = Button.new()
	resume_btn.text = "Resume Simulation [Esc]"
	resume_btn.custom_minimum_size = Vector2(0, 32)
	resume_btn.pressed.connect(toggle_menu_modal)
	tab_sim.add_child(resume_btn)

	var reroll_btn: Button = Button.new()
	reroll_btn.text = "Re-roll World (Generate New Seed)"
	reroll_btn.custom_minimum_size = Vector2(0, 30)
	reroll_btn.pressed.connect(_on_reroll_world_pressed)
	tab_sim.add_child(reroll_btn)

	var quicksave_btn: Button = Button.new()
	quicksave_btn.text = "Save Experiment State [F5]"
	quicksave_btn.custom_minimum_size = Vector2(0, 30)
	quicksave_btn.pressed.connect(func():
		_on_quicksave_pressed()
		_update_modal_save_status()
	)
	tab_sim.add_child(quicksave_btn)

	_modal_load_btn = Button.new()
	_modal_load_btn.text = "Load Save State [F9]"
	_modal_load_btn.custom_minimum_size = Vector2(0, 30)
	_modal_load_btn.pressed.connect(_on_quickload_pressed)
	tab_sim.add_child(_modal_load_btn)

	var modal_reset_btn: Button = Button.new()
	modal_reset_btn.text = "Reset Current Seed to Initial State"
	modal_reset_btn.custom_minimum_size = Vector2(0, 30)
	modal_reset_btn.pressed.connect(func():
		_on_reset_pressed()
		toggle_menu_modal()
	)
	tab_sim.add_child(modal_reset_btn)

	var quit_btn: Button = Button.new()
	quit_btn.text = "Quit to Desktop"
	quit_btn.custom_minimum_size = Vector2(0, 30)
	quit_btn.pressed.connect(func(): get_tree().quit())
	tab_sim.add_child(quit_btn)

	_modal_tab_container.add_child(tab_sim)

	# --- TAB 2: SETTINGS ---
	var tab_settings: VBoxContainer = VBoxContainer.new()
	tab_settings.name = "Settings"
	tab_settings.add_theme_constant_override("separation", 8)

	var preset_hdr: Label = Label.new()
	preset_hdr.text = "GRAPHICS QUALITY PRESET"
	preset_hdr.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	preset_hdr.add_theme_font_size_override("font_size", 11)
	tab_settings.add_child(preset_hdr)

	var preset_hbox: HBoxContainer = HBoxContainer.new()
	preset_hbox.add_theme_constant_override("separation", 6)

	_btn_preset_low = Button.new()
	_btn_preset_low.text = "Low"
	_btn_preset_low.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_preset_low.pressed.connect(func(): _set_graphics_preset(GraphicsPresets.Preset.LOW))
	preset_hbox.add_child(_btn_preset_low)

	_btn_preset_balanced = Button.new()
	_btn_preset_balanced.text = "Balanced (Iris Xe)"
	_btn_preset_balanced.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_preset_balanced.pressed.connect(func(): _set_graphics_preset(GraphicsPresets.Preset.BALANCED))
	preset_hbox.add_child(_btn_preset_balanced)

	_btn_preset_cinematic = Button.new()
	_btn_preset_cinematic.text = "Cinematic"
	_btn_preset_cinematic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_preset_cinematic.pressed.connect(func(): _set_graphics_preset(GraphicsPresets.Preset.CINEMATIC))
	preset_hbox.add_child(_btn_preset_cinematic)

	tab_settings.add_child(preset_hbox)

	_preset_desc_lbl = Label.new()
	_preset_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_preset_desc_lbl.add_theme_font_size_override("font_size", 10)
	_preset_desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	tab_settings.add_child(_preset_desc_lbl)

	_preset_status_lbl = Label.new()
	_preset_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_preset_status_lbl.add_theme_font_size_override("font_size", 10)
	_preset_status_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6))
	tab_settings.add_child(_preset_status_lbl)

	_preset_btn = Button.new()
	_preset_btn.text = "Cycle Preset [Click] ▾"
	_preset_btn.custom_minimum_size = Vector2(0, 26)
	_preset_btn.pressed.connect(_on_cycle_graphics_preset)
	tab_settings.add_child(_preset_btn)

	_update_preset_ui_state()

	_screen_mode_btn = Button.new()
	_screen_mode_btn.text = "Window Mode: Windowed (1280x720)"
	_screen_mode_btn.custom_minimum_size = Vector2(0, 30)
	_screen_mode_btn.pressed.connect(_on_toggle_screen_mode)
	tab_settings.add_child(_screen_mode_btn)

	_fog_btn = Button.new()
	_fog_btn.text = "Atmospheric Distance Fog: ON"
	_fog_btn.custom_minimum_size = Vector2(0, 30)
	_fog_btn.pressed.connect(_on_toggle_fog)
	tab_settings.add_child(_fog_btn)

	var sens_vbox: VBoxContainer = VBoxContainer.new()
	var sens_hdr: HBoxContainer = HBoxContainer.new()
	var sens_title: Label = Label.new()
	sens_title.text = "Camera Mouse Sensitivity:"
	sens_title.add_theme_font_size_override("font_size", 11)
	sens_hdr.add_child(sens_title)
	sens_hdr.add_child(_create_spacer())
	_sens_label = Label.new()
	_sens_label.text = "0.0030"
	_sens_label.add_theme_font_size_override("font_size", 11)
	sens_hdr.add_child(_sens_label)
	sens_vbox.add_child(sens_hdr)

	var sens_slider: HSlider = HSlider.new()
	sens_slider.min_value = 0.001
	sens_slider.max_value = 0.008
	sens_slider.step = 0.0005
	sens_slider.value = 0.003
	sens_slider.value_changed.connect(_on_sensitivity_slider_changed)
	sens_vbox.add_child(sens_slider)
	tab_settings.add_child(sens_vbox)

	var flight_vbox: VBoxContainer = VBoxContainer.new()
	var flight_hdr: HBoxContainer = HBoxContainer.new()
	var flight_title: Label = Label.new()
	flight_title.text = "Camera Base Flight Speed:"
	flight_title.add_theme_font_size_override("font_size", 11)
	flight_hdr.add_child(flight_title)
	flight_hdr.add_child(_create_spacer())
	_flight_label = Label.new()
	_flight_label.text = "18.0 m/s"
	_flight_label.add_theme_font_size_override("font_size", 11)
	flight_hdr.add_child(_flight_label)
	flight_vbox.add_child(flight_hdr)

	var flight_slider: HSlider = HSlider.new()
	flight_slider.min_value = 8.0
	flight_slider.max_value = 36.0
	flight_slider.step = 2.0
	flight_slider.value = 18.0
	flight_slider.value_changed.connect(_on_flight_slider_changed)
	flight_vbox.add_child(flight_slider)
	tab_settings.add_child(flight_vbox)

	_modal_tab_container.add_child(tab_settings)

	# --- TAB 3: CONTROLS & HELP GUIDE ---
	var tab_help: VBoxContainer = VBoxContainer.new()
	tab_help.name = "Controls & Guide"
	tab_help.add_theme_constant_override("separation", 6)

	var help_scroll: ScrollContainer = ScrollContainer.new()
	help_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var help_lbl: Label = Label.new()
	help_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	help_lbl.add_theme_font_size_override("font_size", 10)
	help_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
	help_lbl.text = """[EXPLORATION MODES & CAMERA]
• [V]: Toggle Dual-Mode: Flycam (6-DOF Flight) ↔ First-Person Walker
• [W/A/S/D]: Move (Walk / Strafe in Walker; Free Flight / Pan in Flycam)
• [Space]: Jump in First-Person Walker | Pause/Resume simulation in Flycam
• [Shift]: Sprint boost (faster walking / flight)
• [Right Mouse]: Toggle free-look mouse camera in Flycam mode
• [Mouse Look]: Direct mouse look in First-Person Walker (auto-captured)
• [Esc]: Release mouse & open Pause / Settings Menu (Resuming re-captures mouse)
• [E / Q]: Ascend / Descend elevation in Flycam mode
• [Scroll Wheel]: Adjust flight speed (Flycam) or zoom distance (Orbit)
• [B]: Cycle scenic Points of Interest (POI bookmarks)
• [F]: Track inspected entity with orbit camera

[EXPERIMENT TOOLS]
• [1 - 7, 8, 9, 0, -]: Select experiment tools (Inspect, +Moisture, -Moisture, Plant, Deer, Stalker, Delete, Heatwave, Frost, Fertilize, Disaster)
• [[ / ]]: Decrease / Increase tool brush radius
• [Left Mouse]: Apply selected tool at crosshair/cursor position
• [Space / P]: Pause / Resume simulation clock
• [1x, 2x, 5x]: Time dilation speed
• [F5]: QuickSave experiment state | [F9]: QuickLoad experiment state
• [F1]: Open this Help Guide | [Esc]: Toggle Pause & Settings Menu
• [H]: Hide all HUD overlays for scenic observation

[ECOLOGICAL DYNAMICS]
• Water & Sunshine: Moisture and sunlight drive photosynthesis and plant biomass growth.
• Herbivores (Deer): Graze on mature plants. Without plants, they suffer starvation damage and die.
• Predators (Stalkers): Hunt deer to survive. Prevent deer herds from overgrazing the landscape.
• Interventions: Use the moisture brush to revive dying biomes or trigger causal droughts."""

	help_scroll.add_child(help_lbl)
	tab_help.add_child(help_scroll)
	_modal_tab_container.add_child(tab_help)

	main_vbox.add_child(_modal_tab_container)
	_menu_modal.add_child(main_vbox)
	_container.add_child(_menu_modal)

func toggle_menu_modal() -> void:
	if not _menu_modal:
		return
	_menu_modal.visible = not _menu_modal.visible
	if _menu_modal.visible:
		_update_modal_save_status()
		if _camera and _camera is FreeLookCamera:
			var cam: FreeLookCamera = _camera as FreeLookCamera
			cam.set_input_blocked(true)
			cam.release_mouse()
		if _tool_controller:
			_tool_controller.set_input_blocked(true)
	else:
		if _camera and _camera is FreeLookCamera:
			var cam: FreeLookCamera = _camera as FreeLookCamera
			cam.set_input_blocked(false)
			if cam.current_mode == FreeLookCamera.CameraMode.FIRST_PERSON_WALKER:
				cam.capture_mouse()
		if _tool_controller:
			_tool_controller.set_input_blocked(false)

func open_help_modal() -> void:
	if not _menu_modal:
		return
	_menu_modal.visible = true
	_update_modal_save_status()
	if _camera and _camera is FreeLookCamera:
		var cam: FreeLookCamera = _camera as FreeLookCamera
		cam.set_input_blocked(true)
		cam.release_mouse()
	if _tool_controller:
		_tool_controller.set_input_blocked(true)
	if _modal_tab_container:
		_modal_tab_container.current_tab = 2

func _update_modal_save_status() -> void:
	if not _modal_load_btn:
		return
	var has_save: bool = FileAccess.file_exists("user://saves/world_save.json")
	if has_save:
		_modal_load_btn.disabled = false
		_modal_load_btn.text = "Load Save State [F9] (Available)"
	else:
		_modal_load_btn.disabled = true
		_modal_load_btn.text = "Load Save State [F9] (No Save Found)"

func _on_cycle_chart_mode() -> void:
	if not _chart:
		return
	var new_mode: EcosystemChart.ChartMode = _chart.cycle_mode()
	match new_mode:
		EcosystemChart.ChartMode.POPULATION:
			if _chart_mode_btn: _chart_mode_btn.text = "Populations ▾"
			if _chart_title_lbl: _chart_title_lbl.text = "POPULATIONS & BIOMASS"
		EcosystemChart.ChartMode.TRAIT_MEANS:
			if _chart_mode_btn: _chart_mode_btn.text = "Trait Means ▾"
			if _chart_title_lbl: _chart_title_lbl.text = "TRAIT MEANS (SPEED/EFF)"
		EcosystemChart.ChartMode.DISPERSION_DEMOGRAPHICS:
			if _chart_mode_btn: _chart_mode_btn.text = "Dispersion/Surv ▾"
			if _chart_title_lbl: _chart_title_lbl.text = "DISPERSION & SURVIVAL"
	show_toast("Chart View: " + _chart.get_mode_name(new_mode), true)

func _set_graphics_preset(preset: GraphicsPresets.Preset) -> void:
	var root_node: Node = get_tree().root if get_tree() else self
	var changes: Dictionary = GraphicsPresets.apply_preset(preset, root_node)
	GraphicsPresets.save_to_config(preset)
	_update_preset_ui_state(changes)
	show_toast("Applied Preset: " + GraphicsPresets.get_preset_name(preset), true)

func _update_preset_ui_state(changes: Dictionary = {}) -> void:
	var p: GraphicsPresets.Preset = GraphicsPresets.current_preset
	if _btn_preset_low:
		_btn_preset_low.modulate = Color(1.3, 1.3, 0.9) if p == GraphicsPresets.Preset.LOW else Color(1.0, 1.0, 1.0)
	if _btn_preset_balanced:
		_btn_preset_balanced.modulate = Color(1.3, 1.3, 0.9) if p == GraphicsPresets.Preset.BALANCED else Color(1.0, 1.0, 1.0)
	if _btn_preset_cinematic:
		_btn_preset_cinematic.modulate = Color(1.3, 1.3, 0.9) if p == GraphicsPresets.Preset.CINEMATIC else Color(1.0, 1.0, 1.0)

	if _preset_desc_lbl:
		_preset_desc_lbl.text = GraphicsPresets.get_preset_description(p)

	if _preset_status_lbl:
		var scale_pct: int = int(changes.get("scaling_3d_scale", 0.85) * 100.0) if not changes.is_empty() else (75 if p == GraphicsPresets.Preset.LOW else (85 if p == GraphicsPresets.Preset.BALANCED else 100))
		var msaa_str: String = "Disabled" if p != GraphicsPresets.Preset.CINEMATIC else "2X"
		var shadows_str: String = "Disabled" if p == GraphicsPresets.Preset.LOW else ("Fast 2K" if p == GraphicsPresets.Preset.BALANCED else "High 4K")
		var grass_cnt: int = int(changes.get("grass_count", 350 if p == GraphicsPresets.Preset.LOW else (700 if p == GraphicsPresets.Preset.BALANCED else 1000)))
		var rain_cnt: int = int(changes.get("rain_amount", 160 if p == GraphicsPresets.Preset.LOW else (350 if p == GraphicsPresets.Preset.BALANCED else 550)))
		_preset_status_lbl.text = "Active: %s | Scale: %d%% | MSAA: %s | Shadows: %s | Grass: %d | Rain: %d" % [
			GraphicsPresets.get_preset_name(p), scale_pct, msaa_str, shadows_str, grass_cnt, rain_cnt
		]

	if _preset_btn:
		_preset_btn.text = "Cycle Preset: %s ▾" % GraphicsPresets.get_preset_name(p)

func _on_cycle_graphics_preset() -> void:
	var next_p: int = (int(GraphicsPresets.current_preset) + 1) % 3
	_set_graphics_preset(next_p as GraphicsPresets.Preset)

func _on_toggle_screen_mode() -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if _screen_mode_btn:
			_screen_mode_btn.text = "Window Mode: Windowed (1280x720)"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		if _screen_mode_btn:
			_screen_mode_btn.text = "Window Mode: Fullscreen"

func _on_toggle_fog() -> void:
	var env_node: WorldEnvironment = get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if env_node and env_node.environment:
		env_node.environment.fog_enabled = not env_node.environment.fog_enabled
		if _fog_btn:
			_fog_btn.text = "Atmospheric Distance Fog: " + ("ON" if env_node.environment.fog_enabled else "OFF")

func _on_sensitivity_slider_changed(val: float) -> void:
	if _camera and "mouse_sensitivity" in _camera:
		_camera.mouse_sensitivity = val
	if _sens_label:
		_sens_label.text = "%.4f" % val

func _on_flight_slider_changed(val: float) -> void:
	if _camera and "move_speed" in _camera:
		_camera.move_speed = val
		_camera.fast_move_speed = val * 2.2
	if _flight_label:
		_flight_label.text = "%.1f m/s" % val

func _on_reroll_world_pressed() -> void:
	if not _bootstrap:
		return
	var new_seed: int = randi() % 89999999 + 10000000
	_bootstrap.world_seed.set_seed(new_seed)
	_bootstrap.reset_world()

	var main_node: Node = get_tree().root.find_child("Main", true, false)
	if main_node and main_node.has_node("IslandTerrain"):
		var terrain: IslandTerrain = main_node.get_node("IslandTerrain") as IslandTerrain
		terrain.generate_island(_bootstrap.world_config if _bootstrap.world_config else new_seed, _bootstrap.environmental_grid)
		if main_node.has_node("VegetationScatter"):
			var scatter: VegetationScatter = main_node.get_node("VegetationScatter") as VegetationScatter
			scatter.scatter(terrain, new_seed, _bootstrap.entity_registry, _bootstrap.environmental_grid, _bootstrap.world_config)

	if _bootstrap.ecosystem_coordinator:
		_bootstrap.ecosystem_coordinator.populate_initial_ecosystem(55, 14, 2)

	if _seed_lbl:
		_seed_lbl.text = "[Seed: %d]" % new_seed

	show_toast("Re-rolled procedural world with new seed: %d" % new_seed, true)
	toggle_menu_modal()

# =========================================================================
# UI PROCESS LOOP
# =========================================================================
func _process(delta: float) -> void:
	if not _visible:
		return

	# Handle Toast decay
	if _toast_panel.visible:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_panel.visible = false

	# Update Time representation
	var clock: WorldClock = _bootstrap.world_clock if _bootstrap else null
	if clock:
		var day_duration: float = 120.0
		var start_hour: float = 9.0
		var sim_time: float = clock.simulation_time + (start_hour / 24.0) * day_duration
		var day_num: int = int(sim_time / day_duration) + 1
		var day_phase: float = fmod(sim_time / day_duration, 1.0)
		var total_hours: float = day_phase * 24.0
		var hours: int = int(total_hours)
		var minutes: int = int((total_hours - float(hours)) * 60.0)

		var phase_name: String = "Midnight"
		if day_phase >= 0.20 and day_phase < 0.35: phase_name = "Dawn"
		elif day_phase >= 0.35 and day_phase < 0.70: phase_name = "Day"
		elif day_phase >= 0.70 and day_phase < 0.85: phase_name = "Dusk"
		elif day_phase >= 0.85 or day_phase < 0.20: phase_name = "Night"

		_time_label.text = "Day %d -- %02d:%02d (%s)" % [day_num, hours, minutes, phase_name]
		_pause_btn.text = "Resume [Space]" if clock.is_paused else "Pause [Space]"

	# Update Telemetry & Chart
	var coord: EcosystemCoordinator = _bootstrap.ecosystem_coordinator if _bootstrap else null
	var weather: WeatherSystem = _bootstrap.weather_system if _bootstrap else null
	if coord and coord.metrics:
		var m: EcosystemMetrics = coord.metrics
		var w_name: String = WeatherSystem.get_state_name(weather.current_state) if weather else "Clear"

		var div_str: String = "Div: %.2f" % m.genetic_diversity_index
		if m.bottleneck_warning:
			div_str += " [⚠️ Bottleneck]"
		_telemetry_label.text = "Weather: %s | Max Gen: %d | %s\nPlants: %d | Biomass: %.1f kg (DroughtTol: %.0f%%)\nDeer: %d (Avg Spd: %.2fx) | Stalkers: %d\nBirths: %d | Deaths: %d (Tick: %.2fms)" % [
			w_name,
			m.max_generation,
			div_str,
			m.plant_count,
			m.total_biomass,
			m.avg_plant_drought_tolerance * 100.0,
			m.herbivore_count,
			m.avg_herbivore_speed,
			m.predator_count,
			m.births_total,
			m.deaths_total,
			m.last_sim_step_duration_ms
		]


		_chart_update_timer -= delta
		if _chart_update_timer <= 0.0:
			_chart_update_timer = CHART_UPDATE_INTERVAL
			if _chart and m.history.size() > 0:
				_chart.update_history(m.history)

	# Update Camera Telemetry
	if _camera is FreeLookCamera:
		var cam: FreeLookCamera = _camera as FreeLookCamera
		if _compass_label:
			_compass_label.text = "🧭 %s %03.0f°" % [cam.get_compass_cardinal(), cam.get_compass_heading_degrees()]
		if _cam_mode_btn:
			if cam.current_mode == FreeLookCamera.CameraMode.FIRST_PERSON_WALKER:
				_cam_mode_btn.text = "🚶 Walker [V]"
			elif cam.current_mode == FreeLookCamera.CameraMode.FREE_LOOK:
				_cam_mode_btn.text = "🎥 Flycam [V]"
			else:
				_cam_mode_btn.text = "🎥 %s [V]" % cam.get_mode_name(cam.current_mode)

	# Update Weather & Wind Telemetry
	if weather and _weather_btn and _weather_telemetry_label:
		_weather_btn.text = "%s %s [Y]" % [WeatherSystem.get_state_icon(weather.current_state), WeatherSystem.get_state_name(weather.current_state)]
		var eff_wind: float = weather.get_effective_wind_speed()
		var cardinal: String = weather.get_wind_cardinal()
		var wet_pct: int = 0
		var root_node: Node = get_tree().root if get_tree() else null
		var main_node: Node = root_node.find_child("Main", true, false) if root_node else null
		if main_node and main_node.has_node("IslandTerrain"):
			var terrain: IslandTerrain = main_node.get_node("IslandTerrain") as IslandTerrain
			wet_pct = int(terrain.get_surface_wetness() * 100.0)
		_weather_telemetry_label.text = "💨 %s %.1fm/s | 💧 %d%%" % [cardinal, eff_wind, wet_pct]


# =========================================================================
# EVENT HANDLERS & CALLBACKS
# =========================================================================
func _on_tool_button_pressed(mode: PlayerToolController.ToolMode) -> void:
	if _tool_controller:
		_tool_controller.set_tool(mode)

func _on_tool_changed(mode: PlayerToolController.ToolMode, _name: String) -> void:
	for m in _tool_buttons.keys():
		var btn: Button = _tool_buttons[m]
		if m == mode:
			btn.modulate = Color(1.3, 1.3, 0.9)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)

func _on_radius_changed(rad: float) -> void:
	if _radius_label:
		_radius_label.text = "Radius: %.1fm ([ / ])" % rad

func _on_pause_pressed() -> void:
	if _bootstrap and _bootstrap.world_clock:
		_bootstrap.world_clock.toggle_pause()
		var is_p: bool = _bootstrap.world_clock.is_paused
		show_toast("Simulation " + ("Paused" if is_p else "Resumed"), true)

func _on_speed_button_pressed(sp: float) -> void:
	if _bootstrap and _bootstrap.world_clock:
		_bootstrap.world_clock.set_time_scale(sp)
		show_toast("Simulation Speed: %.1fx" % sp, true)

func _on_quicksave_pressed() -> void:
	if _bootstrap:
		var err: Error = _bootstrap.save_world_state()
		if err == OK:
			show_toast("QuickSave successful: world_state.json", true)
		else:
			show_toast("QuickSave failed! Error: %d" % err, false)

func _on_quickload_pressed() -> void:
	if _bootstrap:
		var err: Error = _bootstrap.load_world_state()
		if err == OK:
			show_toast("QuickLoad successful! World state restored.", true)
		else:
			show_toast("QuickLoad failed! Error: %d" % err, false)

func _on_reset_pressed() -> void:
	if _bootstrap:
		_bootstrap.reset_world()
		if _bootstrap.ecosystem_coordinator:
			_bootstrap.ecosystem_coordinator.populate_initial_ecosystem(55, 14, 2)
		show_toast("World reset to clean state with seed: %d" % _bootstrap.world_seed.master_seed, true)

func toggle_hud() -> void:
	_visible = not _visible
	_container.visible = _visible

func show_toast(msg: String, is_success: bool = true) -> void:
	if not _toast_panel or not _toast_label:
		return
	_toast_label.text = msg
	var col: Color = Color(0.3, 0.85, 1.0) if is_success else Color(1.0, 0.4, 0.3)
	_toast_label.add_theme_color_override("font_color", col)
	_toast_panel.visible = true
	_toast_timer = 2.5

func _format_bar(val: float, max_val: float, length: int = 10) -> String:
	var ratio: float = clampf(val / max_val if max_val > 0.0 else 0.0, 0.0, 1.0)
	var filled: int = int(round(ratio * float(length)))
	var bar: String = ""
	for i in range(filled): bar += "█"
	for i in range(length - filled): bar += "░"
	return "[%s] %.1f%%" % [bar, ratio * 100.0]

func _on_inspection_performed(data: Dictionary) -> void:
	_inspect_empty.visible = false
	var txt: String = ""

	# Entity Info
	var ent: Variant = data.get("entity", null)
	if ent is Dictionary and not ent.is_empty():
		var type: String = ent.get("type", "entity").to_upper()
		var species: String = ent.get("species", "Unknown")
		var id: int = ent.get("id", 0)
		var hp: float = ent.get("health", 100.0)
		var age: float = ent.get("age", 0.0)
		_last_inspected_id = id
		_last_inspected_pos = data.get("position", Vector3.ZERO)


		txt += "=== ENTITY #%d (%s) ===\n" % [id, type]
		txt += "Species:    %s\n" % species
		txt += "Vitality:   %s\n" % _format_bar(hp, 100.0)
		if ent.has("energy"):
			txt += "Metabolism: %s\n" % _format_bar(float(ent.get("energy", 0.0)), 100.0)
		if ent.has("biomass"):
			var bio: float = float(ent.get("biomass", 0.0))
			var max_b: float = float(ent.get("max_biomass", 10.0))
			txt += "Biomass:    %s (%.1f / %.1f kg)\n" % [_format_bar(bio, max_b), bio, max_b]
		txt += "Life Stage: %s (Age: %.1fs)\n" % [ent.get("life_stage_name", ent.get("stage_name", "Adult")), age]

		var st_name: String = ent.get("state_name", "")
		var state_desc: String = ""
		match st_name:
			"EATING": state_desc = "Grazing on plant biomass"
			"FORAGING": state_desc = "Seeking food source within scent radius"
			"HUNTING": state_desc = "Stalking prey herbivores"
			"FLEEING": state_desc = "Sprinting away from predator threat"
			"RESTING": state_desc = "Resting, conserving metabolic energy"
			"STARVING": state_desc = "CRITICAL: Zero energy, taking damage!"
			"WANDERING": state_desc = "Exploring natural habitat"
			_: state_desc = "Active in habitat"
		txt += "Behavior:   %s\n -> %s\n\n" % [st_name, state_desc]

		# Genome & Lineage Details
		var genome_dict: Variant = ent.get("genome", null)
		if genome_dict == null and ent.has("properties"):
			genome_dict = ent["properties"].get("genome", null)
		if genome_dict is Dictionary and not genome_dict.is_empty():
			var gen: int = int(genome_dict.get("generation", 1))
			var p_id: int = int(genome_dict.get("parent_id", -1))
			var p_b_id: int = int(genome_dict.get("parent_b_id", -1))
			txt += "=== 5-TRAIT GENOME & LINEAGE ===\n"
			txt += "Generation: %d\n" % gen
			if p_id > 0 and p_b_id > 0:
				txt += "Lineage:    Cross of #%d x #%d\n" % [p_id, p_b_id]
			elif p_id > 0:
				txt += "Lineage:    Offspring of #%d\n" % p_id
			else:
				txt += "Lineage:    Founder Ancestor (Gen 1)\n"

			var sz: float = float(genome_dict.get("size", genome_dict.get("size_scale", 1.0)))
			var spd: float = float(genome_dict.get("speed", genome_dict.get("speed_mult", 1.0)))
			var sn: float = float(genome_dict.get("sense_range", genome_dict.get("perception_radius", 28.0)))
			var eff: float = float(genome_dict.get("energy_efficiency", genome_dict.get("metabolism_efficiency", 1.0)))
			txt += "Size Scale:    %.2fx (mass & caps)\n" % sz
			txt += "Speed Allele:  %.2fx (agility)\n" % spd
			txt += "Sense Range:   %.1fm (sight/scent)\n" % sn
			txt += "Metabolism:    %.2fx (efficiency)\n" % eff

			if genome_dict.has("predation") and float(genome_dict["predation"]) > 0.05:
				txt += "Predation:     %.2fx (strike prowess)\n" % float(genome_dict["predation"])
			elif genome_dict.has("foraging") and float(genome_dict["foraging"]) > 0.05:
				txt += "Foraging:      %.2fx (intake rate)\n" % float(genome_dict["foraging"])

			if genome_dict.has("drought_tolerance"):
				txt += "Drought Tol:   %.0f%% min moisture\n" % (float(genome_dict.get("drought_tolerance", 0.20)) * 100.0)
			txt += "\n"

	# Environment Info

	var env: Variant = data.get("environment", null)
	if env is Dictionary and not env.is_empty():
		var pos: Vector3 = data.get("position", Vector3.ZERO)
		txt += "=== TERRAIN CELL (%.1f, %.1f) ===\n" % [pos.x, pos.z]
		txt += "Elevation:   %.1fm\n" % env.get("elevation", 0.0)
		txt += "Biome:       %s\n" % env.get("biome_name", "Unknown")
		txt += "Temperature: %.1f°C\n" % env.get("temperature", 20.0)
		txt += "Moisture:    %.0f%%\n" % (env.get("moisture", 0.5) * 100.0)
		txt += "Water Avail: %.2f\n" % env.get("water_availability", 0.5)
		txt += "Sun Exposure:%.0f%%\n" % (env.get("sun_exposure", 1.0) * 100.0)
		if env.has("fertility"):
			txt += "Fertility:   %.1fx\n" % env.get("fertility", 1.0)
		if env.has("causal_status"):
			txt += "Causal Status: %s\n" % env.get("causal_status", "Natural equilibrium")

	_inspect_details.text = txt
	if _last_inspected_id > 0 and _track_entity_btn:
		_track_entity_btn.visible = true
		_track_entity_btn.text = "🎯 Track Entity #%d [F]" % _last_inspected_id
	elif _track_entity_btn:
		_track_entity_btn.visible = false

	# Switch to inspector tab
	if _tab_container:
		_tab_container.current_tab = 1


func _on_sim_event(payload: Variant, category: String) -> void:
	var desc: String = ""
	if payload is Dictionary:
		desc = JSON.stringify(payload)
	else:
		desc = str(payload)
	log_event(category, desc)

func _on_event_bus_notification(category: String, message: String) -> void:
	log_event(category, message)

func _on_causal_cascade(payload: Variant) -> void:
	if not (payload is Dictionary):
		return
	var evt: Dictionary = payload as Dictionary
	var headline: String = evt.get("headline", "Causal event detected")
	var narrative: String = evt.get("narrative", "")
	log_event("CAUSE & EFFECT", "%s: %s" % [headline, narrative])
	show_toast("⚡ " + headline, true)

func log_event(category: String, desc: String) -> void:
	var clock: WorldClock = _bootstrap.world_clock if _bootstrap else null
	var time_str: String = "00:00"
	if clock:
		var sim_time: float = clock.simulation_time + (9.0 / 24.0) * 120.0
		var day_phase: float = fmod(sim_time / 120.0, 1.0)
		var h: int = int(day_phase * 24.0)
		var m: int = int((day_phase * 24.0 - float(h)) * 60.0)
		time_str = "%02d:%02d" % [h, m]

	var entry: Dictionary = {
		"time": time_str,
		"category": category,
		"desc": desc
	}
	_recent_events.append(entry)
	if _recent_events.size() > MAX_EVENT_LOG:
		_recent_events.pop_front()

	# Add entry label
	if _event_log_vbox:
		var lbl: Label = Label.new()
		lbl.text = "[%s] [%s] %s" % [time_str, category, desc]
		lbl.add_theme_font_size_override("font_size", 10)
		var c: Color = Color(0.75, 0.85, 0.95)
		if category == "BIRTH" or category == "PLANT": c = Color(0.4, 0.9, 0.5)
		elif category == "DEATH" or category == "DECAY": c = Color(0.95, 0.45, 0.45)
		elif category == "TOOL": c = Color(1.0, 0.8, 0.3)
		elif category == "WEATHER": c = Color(0.5, 0.8, 1.0)
		lbl.add_theme_color_override("font_color", c)
		_event_log_vbox.add_child(lbl)

		# Auto scroll
		if _event_scroll:
			_event_scroll.scroll_vertical = 999999

func _create_glass_style(bg: Color, border: Color, corner: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner)
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	return style

func _create_spacer() -> Control:
	var sp: Control = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sp

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_H:
				toggle_hud()
			KEY_ESCAPE:
				toggle_menu_modal()
			KEY_F1:
				open_help_modal()
			KEY_SPACE:
				if _camera is FreeLookCamera and (_camera as FreeLookCamera).current_mode == FreeLookCamera.CameraMode.FIRST_PERSON_WALKER:
					pass # Space is jump in Walker mode; do not toggle pause
				else:
					_on_pause_pressed()
			KEY_P:
				_on_pause_pressed()
			KEY_F5:
				_on_quicksave_pressed()
			KEY_F9:
				_on_quickload_pressed()
			KEY_T, KEY_Y:
				_on_cycle_weather_pressed()
			KEY_F:
				_on_track_entity_pressed()

func _on_cycle_weather_pressed() -> void:
	if not _bootstrap or not _bootstrap.weather_system:
		return
	var weather: WeatherSystem = _bootstrap.weather_system
	var next_st: int = (int(weather.current_state) + 1) % 4
	weather.set_state(next_st as WeatherSystem.WeatherState, 60.0)
	show_toast("Weather changed to: %s %s [Y]" % [WeatherSystem.get_state_icon(next_st as WeatherSystem.WeatherState), WeatherSystem.get_state_name(next_st as WeatherSystem.WeatherState)], true)

func _on_camera_mode_btn_pressed() -> void:
	if _camera is FreeLookCamera:
		(_camera as FreeLookCamera).cycle_camera_mode()

func _on_bookmark_btn_pressed() -> void:
	if _camera is FreeLookCamera:
		(_camera as FreeLookCamera).cycle_bookmark()

func _on_track_entity_pressed() -> void:
	if not (_camera is FreeLookCamera):
		return
	var cam: FreeLookCamera = _camera as FreeLookCamera

	if cam.current_mode == FreeLookCamera.CameraMode.FOLLOW_ENTITY:
		cam.set_camera_mode(FreeLookCamera.CameraMode.FREE_LOOK)
		show_toast("Returned to Free Flight mode", true)
		return

	if _last_inspected_id > 0:
		var root_node: Node = get_tree().root if get_tree() else null
		var eco: EcosystemPresentation = root_node.find_child("EcosystemPresentation", true, false) as EcosystemPresentation if root_node else null
		if eco:
			var node: Node3D = eco.get_entity_node(_last_inspected_id)
			if is_instance_valid(node):
				cam.start_following_node(node, 6.0, _last_inspected_id)
				show_toast("Tracking Entity #%d" % _last_inspected_id, true)
				return
		cam.start_orbit(_last_inspected_pos, 7.0)
		show_toast("Orbiting target location", true)
	elif _last_inspected_pos != Vector3.ZERO:
		cam.start_orbit(_last_inspected_pos, 7.0)
		show_toast("Orbiting inspected point", true)
	else:
		show_toast("No entity or point selected to track", false)

func _on_camera_mode_changed(mode: FreeLookCamera.CameraMode, mode_name: String) -> void:
	if _cam_mode_btn:
		if mode == FreeLookCamera.CameraMode.FIRST_PERSON_WALKER:
			_cam_mode_btn.text = "🚶 Walker [V]"
		elif mode == FreeLookCamera.CameraMode.FREE_LOOK:
			_cam_mode_btn.text = "🎥 Flycam [V]"
		else:
			_cam_mode_btn.text = "🎥 %s [V]" % mode_name
	show_toast("Camera: %s" % mode_name, true)

func _on_camera_bookmark_reached(_id: int, b_name: String) -> void:
	show_toast("Viewpoint: %s" % b_name, true)

func _on_camera_entity_lost(id: int) -> void:
	show_toast("Tracked Entity #%d was lost" % id, false)
