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
	_panel.offset_top = -240.0
	_panel.offset_bottom = -16.0
	
	# Translucent dark aesthetic stylebox
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.1, 0.88)
	style.border_color = Color(0.2, 0.45, 0.65, 0.9)
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
	
	var fauna_sim: FaunaSimulation = null
	if _bootstrap and _bootstrap.ecosystem_coordinator:
		fauna_sim = _bootstrap.ecosystem_coordinator.fauna_sim

	var fauna_info: String = ""
	if fauna_sim:
		var h_states: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0}
		for h in fauna_sim.get_all_herbivores():
			h_states[h.state] = h_states.get(h.state, 0) + 1
		var p_states: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
		for p in fauna_sim.get_all_predators():
			p_states[p.state] = p_states.get(p.state, 0) + 1

		var dists: Array[float] = fauna_sim.get_sector_disturbances()
		fauna_info = (
			"Fauna Step: %.2f ms | LOD Tiers: 0/1/2 Active\n" % [fauna_sim.last_simulation_step_time_ms] +
			"Deer [W:%d A:%d F:%d R:%d E:%d D:%d] | Stalker [W:%d H:%d E:%d R:%d]\n" % [
				h_states[0], h_states[7], h_states[4], h_states[3], h_states[2], h_states[6],
				p_states[0], p_states[1], p_states[2], p_states[3]
			] +
			"Disturbance: NW:%.1f | NE:%.1f | SW:%.1f | SE:%.1f\n" % [
				dists[0], dists[1], dists[2], dists[3]
			]
		)

	var summary: String = PerformanceMonitor.format_summary(clock, registry)
	_label.text = (
		"=== ENGINE DEBUG METRICS [F3] ===\n" +
		"Seed: %s\n" % seed_val +
		fauna_info +
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

