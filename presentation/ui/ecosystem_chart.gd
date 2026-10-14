class_name EcosystemChart
extends Control

## Real-time ecological history chart rendering authentic telemetry data using CanvasItem draw methods.
## Zero mock/placeholder data. Renders actual sampled population & biomass curves,
## species heritable trait means, and population variance/demographics.

enum ChartMode {
	POPULATION = 0,
	TRAIT_MEANS = 1,
	DISPERSION_DEMOGRAPHICS = 2
}

@export var max_samples: int = 40
var current_mode: ChartMode = ChartMode.POPULATION

var _history: Array = []

# Palette - Curated harmonious tones for maximum readability
var _color_biomass: Color = Color(0.35, 0.92, 0.45)        # Green
var _color_herbivores: Color = Color(1.0, 0.82, 0.35)      # Amber / Fawn
var _color_predators: Color = Color(1.0, 0.35, 0.35)       # Crimson / Stalker
var _color_cyan: Color = Color(0.35, 0.85, 1.0)            # Cyan (Efficiency / Diversity)
var _color_magenta: Color = Color(0.95, 0.45, 0.95)        # Magenta (Predator Efficiency)
var _color_orange: Color = Color(1.0, 0.60, 0.25)          # Orange (Variance)
var _color_grid: Color = Color(0.2, 0.35, 0.5, 0.25)
var _color_bg: Color = Color(0.04, 0.07, 0.12, 0.88)
var _color_border: Color = Color(0.25, 0.45, 0.65, 0.55)

func update_history(history_samples: Array) -> void:
	_history = history_samples
	queue_redraw()

func cycle_mode() -> ChartMode:
	current_mode = ((int(current_mode) + 1) % 3) as ChartMode
	queue_redraw()
	return current_mode

func set_chart_mode(mode: ChartMode) -> void:
	current_mode = mode
	queue_redraw()

func get_mode_name(mode: ChartMode = current_mode) -> String:
	match mode:
		ChartMode.POPULATION:
			return "Populations (Biomass / Deer / Stalkers)"
		ChartMode.TRAIT_MEANS:
			return "Trait Means (Speed / Size / Efficiency)"
		ChartMode.DISPERSION_DEMOGRAPHICS:
			return "Dispersion & Survival (Variance / Diversity)"
		_:
			return "Populations"

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

	var font: Font = ThemeDB.fallback_font
	var font_size: int = 9

	if _history.size() < 2:
		draw_string(font, Vector2(12, h * 0.55), "Sampling ecological telemetry...", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.75, 0.85, 0.7))
		return

	var margin_top: float = 8.0
	var margin_bottom: float = 20.0
	var plot_h: float = h - (margin_top + margin_bottom)
	var x_step: float = w / float(max_samples - 1)
	var start_idx: int = max_samples - _history.size()

	match current_mode:
		ChartMode.POPULATION:
			_draw_population_mode(w, h, margin_top, plot_h, x_step, start_idx, font, font_size)
		ChartMode.TRAIT_MEANS:
			_draw_trait_means_mode(w, h, margin_top, plot_h, x_step, start_idx, font, font_size)
		ChartMode.DISPERSION_DEMOGRAPHICS:
			_draw_dispersion_demographics_mode(w, h, margin_top, plot_h, x_step, start_idx, font, font_size)

func _draw_population_mode(w: float, h: float, margin_top: float, plot_h: float, x_step: float, start_idx: int, font: Font, font_size: int) -> void:
	# Find max values for normalization with safe floors
	var max_bio: float = 10.0
	var max_count: float = 10.0
	for item in _history:
		max_bio = maxf(max_bio, float(item.get("biomass", 0.0)))
		max_count = maxf(max_count, float(item.get("herbivores", 0.0)))
		max_count = maxf(max_count, float(item.get("predators", 0.0)) * 2.5)

	var pts_bio: PackedVector2Array = PackedVector2Array()
	var pts_herb: PackedVector2Array = PackedVector2Array()
	var pts_pred: PackedVector2Array = PackedVector2Array()

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

	if pts_bio.size() >= 2:
		draw_polyline(pts_bio, _color_biomass, 1.5, true)
	if pts_herb.size() >= 2:
		draw_polyline(pts_herb, _color_herbivores, 1.5, true)
	if pts_pred.size() >= 2:
		draw_polyline(pts_pred, _color_predators, 1.5, true)

	# Legend with exact units
	var leg_y: float = h - 6.0
	draw_rect(Rect2(8, leg_y - 7, 7, 7), _color_biomass)
	draw_string(font, Vector2(18, leg_y), "Biomass (kg)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.8, 0.95, 0.8))

	draw_rect(Rect2(88, leg_y - 7, 7, 7), _color_herbivores)
	draw_string(font, Vector2(98, leg_y), "Deer (n)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.9, 0.75))

	draw_rect(Rect2(154, leg_y - 7, 7, 7), _color_predators)
	draw_string(font, Vector2(164, leg_y), "Stalkers (n)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.75, 0.75))

func _draw_trait_means_mode(w: float, h: float, margin_top: float, plot_h: float, x_step: float, start_idx: int, font: Font, font_size: int) -> void:
	# Traits are typically 0.60 to 1.50 scale
	var min_val: float = 0.50
	var max_val: float = 1.60
	var range_val: float = max_val - min_val

	var pts_h_spd: PackedVector2Array = PackedVector2Array()
	var pts_p_spd: PackedVector2Array = PackedVector2Array()
	var pts_h_eff: PackedVector2Array = PackedVector2Array()
	var pts_p_eff: PackedVector2Array = PackedVector2Array()

	for i in range(_history.size()):
		var sample: Dictionary = _history[i]
		var x: float = (start_idx + i) * x_step

		var hs_val: float = float(sample.get("avg_speed", 0.0))
		var y_hs: float = margin_top + plot_h * (1.0 - clampf((hs_val - min_val) / range_val, 0.0, 1.0)) if hs_val > 0.0 else margin_top + plot_h
		pts_h_spd.append(Vector2(x, y_hs))

		var ps_val: float = float(sample.get("pred_avg_speed", sample.get("avg_predation", 0.0)))
		var y_ps: float = margin_top + plot_h * (1.0 - clampf((ps_val - min_val) / range_val, 0.0, 1.0)) if ps_val > 0.0 else margin_top + plot_h
		pts_p_spd.append(Vector2(x, y_ps))

		var he_val: float = float(sample.get("avg_eff", 0.0))
		var y_he: float = margin_top + plot_h * (1.0 - clampf((he_val - min_val) / range_val, 0.0, 1.0)) if he_val > 0.0 else margin_top + plot_h
		pts_h_eff.append(Vector2(x, y_he))

		var pe_val: float = float(sample.get("pred_avg_eff", 0.0))
		var y_pe: float = margin_top + plot_h * (1.0 - clampf((pe_val - min_val) / range_val, 0.0, 1.0)) if pe_val > 0.0 else margin_top + plot_h
		pts_p_eff.append(Vector2(x, y_pe))

	if pts_h_spd.size() >= 2:
		draw_polyline(pts_h_spd, _color_herbivores, 1.5, true)
	if pts_p_spd.size() >= 2:
		draw_polyline(pts_p_spd, _color_predators, 1.5, true)
	if pts_h_eff.size() >= 2:
		draw_polyline(pts_h_eff, _color_cyan, 1.5, true)
	if pts_p_eff.size() >= 2:
		draw_polyline(pts_p_eff, _color_magenta, 1.5, true)

	# Legend with exact units
	var leg_y: float = h - 6.0
	draw_rect(Rect2(4, leg_y - 7, 6, 6), _color_herbivores)
	draw_string(font, Vector2(12, leg_y), "Deer Spd", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.9, 0.75))

	draw_rect(Rect2(66, leg_y - 7, 6, 6), _color_predators)
	draw_string(font, Vector2(74, leg_y), "Stk Spd", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.75, 0.75))

	draw_rect(Rect2(122, leg_y - 7, 6, 6), _color_cyan)
	draw_string(font, Vector2(130, leg_y), "Deer Eff", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.75, 0.95, 1.0))

	draw_rect(Rect2(182, leg_y - 7, 6, 6), _color_magenta)
	draw_string(font, Vector2(190, leg_y), "Stk Eff", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.8, 1.0))

func _draw_dispersion_demographics_mode(w: float, h: float, margin_top: float, plot_h: float, x_step: float, start_idx: int, font: Font, font_size: int) -> void:
	var pts_var: PackedVector2Array = PackedVector2Array()
	var pts_div: PackedVector2Array = PackedVector2Array()
	var pts_surv: PackedVector2Array = PackedVector2Array()

	for i in range(_history.size()):
		var sample: Dictionary = _history[i]
		var x: float = (start_idx + i) * x_step

		# Allele Variance (0.0 to 0.10)
		var v_val: float = float(sample.get("speed_var", 0.0))
		var y_var: float = margin_top + plot_h * (1.0 - clampf(v_val / 0.06, 0.0, 1.0))
		pts_var.append(Vector2(x, y_var))

		# Genetic Diversity Index D (0.0 to 2.0)
		var d_val: float = float(sample.get("diversity", 1.0))
		var y_div: float = margin_top + plot_h * (1.0 - clampf(d_val / 1.5, 0.0, 1.0))
		pts_div.append(Vector2(x, y_div))

		# Deer Survival Rate (0.0 to 1.0 = 0% to 100%)
		var s_val: float = float(sample.get("survival_herb", 1.0))
		var y_surv: float = margin_top + plot_h * (1.0 - clampf(s_val, 0.0, 1.0))
		pts_surv.append(Vector2(x, y_surv))

	if pts_var.size() >= 2:
		draw_polyline(pts_var, _color_orange, 1.5, true)
	if pts_div.size() >= 2:
		draw_polyline(pts_div, _color_cyan, 1.5, true)
	if pts_surv.size() >= 2:
		draw_polyline(pts_surv, _color_biomass, 1.5, true)

	# Legend with exact units
	var leg_y: float = h - 6.0
	draw_rect(Rect2(8, leg_y - 7, 7, 7), _color_orange)
	draw_string(font, Vector2(18, leg_y), "Speed Var (σ²)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.85, 0.7))

	draw_rect(Rect2(96, leg_y - 7, 7, 7), _color_cyan)
	draw_string(font, Vector2(106, leg_y), "Diversity (D)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.75, 0.95, 1.0))

	draw_rect(Rect2(174, leg_y - 7, 7, 7), _color_biomass)
	draw_string(font, Vector2(184, leg_y), "Survival (%)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.8, 0.95, 0.8))
