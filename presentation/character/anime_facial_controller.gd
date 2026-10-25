@tool
class_name AnimeFacialController
extends RefCounted

## Living Planet Sandbox — High-Fidelity Anime Character Facial Controller
## Manages VRoid/Anime 57-blendshape facial expressions:
## - Natural procedural blinking (3.0s - 5.5s intervals with realistic lid kinetics)
## - Dynamic emotional states: Neutral, Joy/Smile, Combat Focus, Wind Squint, Wonder/Surprise
## - Smooth, artifact-free blend transitions

enum ExpressionMode {
	NEUTRAL = 0,
	JOY = 1,
	COMBAT = 2,
	WIND_SQUINT = 3,
	SURPRISE = 4
}

var _face_mesh: MeshInstance3D = null

# Blend shape indices cache
var _idx_eye_close: int = -1
var _idx_eye_close_r: int = -1
var _idx_eye_close_l: int = -1
var _idx_eye_joy: int = -1
var _idx_mth_joy: int = -1
var _idx_brw_joy: int = -1
var _idx_all_joy: int = -1
var _idx_all_angry: int = -1
var _idx_all_surprised: int = -1
var _idx_mth_fun: int = -1

# Blinking state
var _blink_timer: float = 3.5
var _is_blinking: bool = false
var _blink_progress: float = 0.0
var _blink_duration: float = 0.16
var _current_blink_weight: float = 0.0

# Expression state
var _current_mode: ExpressionMode = ExpressionMode.NEUTRAL
var _mode_timer: float = 0.0

# Current active blend shape weights (for smooth lerping)
var _weight_close: float = 0.0
var _weight_joy: float = 0.0
var _weight_mth_joy: float = 0.0
var _weight_angry: float = 0.0
var _weight_surprised: float = 0.0

func setup(face_mesh: MeshInstance3D) -> void:
	_face_mesh = face_mesh
	if not _face_mesh or not _face_mesh.mesh:
		return

	_idx_eye_close = _face_mesh.find_blend_shape_by_name("Fcl_EYE_Close")
	_idx_eye_close_r = _face_mesh.find_blend_shape_by_name("Fcl_EYE_Close_R")
	_idx_eye_close_l = _face_mesh.find_blend_shape_by_name("Fcl_EYE_Close_L")
	_idx_eye_joy = _face_mesh.find_blend_shape_by_name("Fcl_EYE_Joy")
	_idx_mth_joy = _face_mesh.find_blend_shape_by_name("Fcl_MTH_Joy")
	_idx_brw_joy = _face_mesh.find_blend_shape_by_name("Fcl_BRW_Joy")
	_idx_all_joy = _face_mesh.find_blend_shape_by_name("Fcl_ALL_Joy")
	_idx_all_angry = _face_mesh.find_blend_shape_by_name("Fcl_ALL_Angry")
	_idx_all_surprised = _face_mesh.find_blend_shape_by_name("Fcl_ALL_Surprised")
	_idx_mth_fun = _face_mesh.find_blend_shape_by_name("Fcl_MTH_Fun")

	_reset_all_shapes()

func set_expression(mode: ExpressionMode, duration: float = 0.0) -> void:
	_current_mode = mode
	_mode_timer = duration

func get_expression() -> ExpressionMode:
	return _current_mode

func trigger_joy(duration: float = 3.5) -> void:
	set_expression(ExpressionMode.JOY, duration)

func trigger_surprise(duration: float = 2.5) -> void:
	set_expression(ExpressionMode.SURPRISE, duration)

func trigger_combat(active: bool) -> void:
	if active:
		set_expression(ExpressionMode.COMBAT, 0.0)
	elif _current_mode == ExpressionMode.COMBAT:
		set_expression(ExpressionMode.NEUTRAL, 0.0)

func trigger_blink(duration: float = 0.16) -> void:
	_is_blinking = true
	_blink_progress = 0.0
	_blink_duration = duration

func update(delta: float, is_gliding: bool, is_sprinting: bool, in_combat: bool) -> void:
	if not _face_mesh:
		return

	# 1. Update timed expression duration
	if _mode_timer > 0.0:
		_mode_timer -= delta
		if _mode_timer <= 0.0:
			_current_mode = ExpressionMode.NEUTRAL

	# Automatic environmental reaction if currently in neutral state
	var active_mode: ExpressionMode = _current_mode
	if active_mode == ExpressionMode.NEUTRAL:
		if in_combat:
			active_mode = ExpressionMode.COMBAT
		elif is_gliding or (is_sprinting and delta > 0.0):
			active_mode = ExpressionMode.WIND_SQUINT

	# 2. Update Natural Blinking Kinetics
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_is_blinking = true
		_blink_progress = 0.0
		# Random next blink in 2.8 to 5.2 seconds
		_blink_timer = randf_range(2.8, 5.2)

	if _is_blinking:
		_blink_progress += delta
		var norm_t: float = _blink_progress / _blink_duration
		if norm_t < 0.40:
			# Fast lid closing
			_current_blink_weight = clampf(norm_t / 0.40, 0.0, 1.0)
		elif norm_t < 1.0:
			# Smooth lid opening
			_current_blink_weight = clampf(1.0 - (norm_t - 0.40) / 0.60, 0.0, 1.0)
		else:
			_current_blink_weight = 0.0
			_is_blinking = false
	else:
		_current_blink_weight = 0.0

	# 3. Determine target weights for active expression
	var target_close: float = _current_blink_weight
	var target_joy: float = 0.0
	var target_mth_joy: float = 0.0
	var target_angry: float = 0.0
	var target_surprised: float = 0.0

	match active_mode:
		ExpressionMode.JOY:
			target_joy = 0.85
			target_mth_joy = 0.90
			# Don't blink during full happy closed-eye smile
			target_close = maxf(target_close, 0.15)
		ExpressionMode.COMBAT:
			target_angry = 0.45
			# Narrow eyes slightly
			target_close = maxf(target_close, 0.10)
		ExpressionMode.WIND_SQUINT:
			# Partial squint against wind
			target_close = maxf(target_close, 0.35)
			target_joy = 0.20
		ExpressionMode.SURPRISE:
			target_surprised = 0.75
			# Eyes wide open, pause blinking
			target_close = 0.0
		_: # NEUTRAL
			pass

	# 4. Smooth lerp transitions (prevent popping)
	var blend_spd: float = clampf(delta * 14.0, 0.0, 1.0)
	_weight_close = lerpf(_weight_close, target_close, blend_spd)
	_weight_joy = lerpf(_weight_joy, target_joy, blend_spd)
	_weight_mth_joy = lerpf(_weight_mth_joy, target_mth_joy, blend_spd)
	_weight_angry = lerpf(_weight_angry, target_angry, blend_spd)
	_weight_surprised = lerpf(_weight_surprised, target_surprised, blend_spd)

	# 5. Apply weights to MeshInstance3D
	_set_shape(_idx_eye_close, _weight_close)
	if _idx_eye_close < 0:
		_set_shape(_idx_eye_close_r, _weight_close)
		_set_shape(_idx_eye_close_l, _weight_close)
	_set_shape(_idx_all_joy, _weight_joy * 0.4)
	_set_shape(_idx_eye_joy, _weight_joy)
	_set_shape(_idx_mth_joy, _weight_mth_joy)
	_set_shape(_idx_brw_joy, _weight_joy * 0.6)
	_set_shape(_idx_all_angry, _weight_angry)
	_set_shape(_idx_all_surprised, _weight_surprised)

func _set_shape(idx: int, val: float) -> void:
	if idx >= 0 and _face_mesh:
		_face_mesh.set_blend_shape_value(idx, clampf(val, 0.0, 1.0))

func _reset_all_shapes() -> void:
	if not _face_mesh or not _face_mesh.mesh:
		return
	if not _face_mesh.mesh.has_method("get_blend_shape_count"):
		return
	for i in range(_face_mesh.mesh.get_blend_shape_count()):
		_face_mesh.set_blend_shape_value(i, 0.0)
