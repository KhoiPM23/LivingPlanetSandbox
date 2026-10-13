class_name DebugOverlay
extends CanvasLayer

## Displays real runtime metrics and keyboard controls for simulation inspection.

@export var bootstrap_path: NodePath = ".."

var _bootstrap: WorldBootstrap = null
var _label: Label = null
var _panel: PanelContainer = null
var _visible: bool = false

func _ready() -> void:
	layer = 100 # Keep on top of 3D scene
	if has_node(bootstrap_path):
		_bootstrap = get_node(bootstrap_path) as WorldBootstrap
		
	_setup_ui()
	if _panel:
		_panel.visible = _visible

func _setup_ui() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 16.0
	_panel.offset_top = -170.0
	_panel.offset_bottom = -16.0
	
	# Translucent dark aesthetic stylebox
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.1, 0.85)
	style.border_color = Color(0.2, 0.4, 0.6, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	_panel.add_theme_stylebox_override("panel", style)
	
	_label = Label.new()
	_label.text = "Initializing metrics..."
	_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_label.add_theme_font_size_override("font_size", 11)
	
	_panel.add_child(_label)
	add_child(_panel)

func _process(_delta: float) -> void:
	if not _visible or not _label:
		return
		
	var clock: WorldClock = _bootstrap.world_clock if _bootstrap else null
	var registry: EntityRegistry = _bootstrap.entity_registry if _bootstrap else null
	var seed_val: String = str(_bootstrap.world_seed.master_seed) if (_bootstrap and _bootstrap.world_seed) else "N/A"
	
	var summary: String = PerformanceMonitor.format_summary(clock, registry)
	_label.text = (
		"=== ENGINE DEBUG METRICS [F3] ===\n" +
		"Seed: %s\n" % seed_val +
		summary
	)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
		
	var key_event: InputEventKey = event as InputEventKey
	match key_event.keycode:
		KEY_F3:
			_visible = not _visible
			if _panel:
				_panel.visible = _visible

