class_name EcosystemChart
extends Control

## Real-time ecological history chart rendering authentic telemetry data using CanvasItem draw methods.
## Zero mock/placeholder data. Renders actual sampled population & biomass curves.

@export var max_samples: int = 40
var _history: Array = []

var _color_biomass: Color = Color(0.35, 0.92, 0.45)
var _color_herbivores: Color = Color(1.0, 0.82, 0.35)
var _color_predators: Color = Color(1.0, 0.35, 0.35)
var _color_grid: Color = Color(0.2, 0.35, 0.5, 0.25)
var _color_bg: Color = Color(0.04, 0.07, 0.12, 0.85)
var _color_border: Color = Color(0.25, 0.45, 0.65, 0.5)

func update_history(history_samples: Array) -> void:
	_history = history_samples
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 10.0 or h <= 10.0:
		return

	# 1. Background & Border
	draw_rect(Rect2(0, 0, w, h), _color_bg, true)
	draw_rect(Rect2(0, 0, w, h), _color_border, false, 1.0)

	# 2. Grid lines
	draw_line(Vector2(0, h * 0.25), Vector2(w, h * 0.25), _color_grid, 1.0)
	draw_line(Vector2(0, h * 0.50), Vector2(w, h * 0.50), _color_grid, 1.0)
	draw_line(Vector2(0, h * 0.75), Vector2(w, h * 0.75), _color_grid, 1.0)

	if _history.size() < 2:
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(12, h * 0.55), "Sampling ecological telemetry...", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.75, 0.85, 0.7))
		return

	# 3. Find max values for normalization
	var max_bio: float = 10.0
	var max_count: float = 10.0
	for item in _history:
		max_bio = maxf(max_bio, float(item.get("biomass", 0.0)))
		max_count = maxf(max_count, float(item.get("herbivores", 0.0)))
		max_count = maxf(max_count, float(item.get("predators", 0.0)) * 2.5)

	var margin_top: float = 8.0
	var margin_bottom: float = 18.0
	var plot_h: float = h - (margin_top + margin_bottom)
	var x_step: float = w / float(max_samples - 1)

	var pts_bio: PackedVector2Array = PackedVector2Array()
	var pts_herb: PackedVector2Array = PackedVector2Array()
	var pts_pred: PackedVector2Array = PackedVector2Array()

	var start_idx: int = max_samples - _history.size()

	for i in range(_history.size()):
		var sample: Dictionary = _history[i]
		var x: float = (start_idx + i) * x_step

		var b_val: float = float(sample.get("biomass", 0.0))
		var y_bio: float = margin_top + plot_h * (1.0 - clampf(b_val / max_bio, 0.0, 1.0))
		pts_bio.append(Vector2(x, y_bio))

		var h_val: float = float(sample.get("herbivores", 0.0))
		var y_herb: float = margin_top + plot_h * (1.0 - clampf(h_val / max_count, 0.0, 1.0))
		pts_herb.append(Vector2(x, y_herb))

		var p_val: float = float(sample.get("predators", 0.0))
		var y_pred: float = margin_top + plot_h * (1.0 - clampf((p_val * 2.5) / max_count, 0.0, 1.0))
		pts_pred.append(Vector2(x, y_pred))

	# 4. Draw Polylines
	if pts_bio.size() >= 2:
		draw_polyline(pts_bio, _color_biomass, 1.5, true)
	if pts_herb.size() >= 2:
		draw_polyline(pts_herb, _color_herbivores, 1.5, true)
	if pts_pred.size() >= 2:
		draw_polyline(pts_pred, _color_predators, 1.5, true)

	# 5. Legend
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 9
	var leg_y: float = h - 5.0
	
	draw_rect(Rect2(8, leg_y - 7, 7, 7), _color_biomass)
	draw_string(font, Vector2(18, leg_y), "Biomass", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.8, 0.9, 0.8))

	draw_rect(Rect2(72, leg_y - 7, 7, 7), _color_herbivores)
	draw_string(font, Vector2(82, leg_y), "Deer", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.9, 0.9, 0.8))

	draw_rect(Rect2(120, leg_y - 7, 7, 7), _color_predators)
	draw_string(font, Vector2(130, leg_y), "Stalkers", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.9, 0.8, 0.8))
