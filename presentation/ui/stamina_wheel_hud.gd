class_name StaminaWheelHUD
extends Control

## Living Planet Sandbox — Block 63: Genshin-Style Diegetic Stamina Wheel HUD
## Renders a curved anime stamina arc near the character center:
## - Smoothly fades in when stamina is expended (ratio < 1.0)
## - Dynamic color shifts: Emerald Green (1.0 -> 0.35) -> Warm Amber (0.35 -> 0.15) -> Crimson Flash (< 0.15)
## - Smoothly fades out when stamina reaches 100% full
## - Pure vector draw_arc() with zero texture memory and zero GPU bandwidth cost

const PlayerStaminaController = preload("res://presentation/character/player_stamina_controller.gd")

var _ratio: float = 1.0
var _display_alpha: float = 0.0
var _flash_timer: float = 0.0
var _stamina_ref: RefCounted = null

var fade_alpha: float:
	get:
		return _display_alpha

var _target_alpha: float:
	get:
		return 1.0 if (_stamina_ref != null and not _stamina_ref.is_full()) else 0.0

const ARC_RADIUS: float = 38.0
const ARC_WIDTH: float = 4.5
const START_ANGLE: float = -PI * 0.75
const TOTAL_SWEEP: float = PI * 1.50

func setup(stamina_controller: RefCounted) -> void:
	_stamina_ref = stamina_controller
	if _stamina_ref:
		_stamina_ref.stamina_changed.connect(_on_stamina_changed)
		_stamina_ref.stamina_exhausted.connect(_on_stamina_exhausted)

func _process(delta: float) -> void:
	_flash_timer += delta * 6.0
	var target_alpha: float = _target_alpha
	_display_alpha = lerpf(_display_alpha, target_alpha, clampf(7.5 * delta, 0.0, 1.0))

	if _display_alpha > 0.01:
		queue_redraw()

func _on_stamina_changed(_curr: float, _max_val: float, ratio: float) -> void:
	_ratio = ratio
	queue_redraw()

func _on_stamina_exhausted() -> void:
	_flash_timer = 0.0
	queue_redraw()

func _get_stamina_color(ratio: float) -> Color:
	if ratio > 0.35:
		# Vibrant Emerald Green (Genshin Anemo Swiftness)
		return Color(0.32, 0.88, 0.48, 0.95 * _display_alpha)
	elif ratio > 0.15:
		# Caution Amber
		return Color(1.0, 0.72, 0.22, 0.95 * _display_alpha)
	else:
		# Critical Crimson Flash
		var pulse: float = sin(_flash_timer) * 0.5 + 0.5
		return Color(1.0, 0.22 + 0.3 * pulse, 0.25, 0.95 * _display_alpha)

func _draw() -> void:
	if _display_alpha <= 0.01:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	# Diegetic placement floating just right of character center-mass
	var center: Vector2 = vp_size * 0.5 + Vector2(65.0, -10.0)

	# 1. Background dark ring track
	var bg_col: Color = Color(0.08, 0.12, 0.16, 0.45 * _display_alpha)
	draw_arc(center, ARC_RADIUS, START_ANGLE, START_ANGLE + TOTAL_SWEEP, 32, bg_col, ARC_WIDTH + 2.0, true)

	# 2. Determine foreground color based on stamina reserve
	var fg_col: Color = _get_stamina_color(_ratio)

	# 3. Active stamina sweep arc
	var active_sweep: float = TOTAL_SWEEP * clampf(_ratio, 0.0, 1.0)
	if active_sweep > 0.01:
		draw_arc(center, ARC_RADIUS, START_ANGLE, START_ANGLE + active_sweep, 32, fg_col, ARC_WIDTH, true)

		# 4. Leading glowing edge pip
		var lead_angle: float = START_ANGLE + active_sweep
		var pip_pos: Vector2 = center + Vector2(cos(lead_angle), sin(lead_angle)) * ARC_RADIUS
		var pip_col: Color = Color(1.0, 1.0, 1.0, 0.95 * _display_alpha)
		draw_circle(pip_pos, ARC_WIDTH * 0.85, pip_col)
