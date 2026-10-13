class_name FreeLookCamera
extends Camera3D

## Free-flying exploration camera controller with smooth mouse look and keyboard navigation.

@export var move_speed: float = 18.0
@export var fast_move_speed: float = 40.0
@export var mouse_sensitivity: float = 0.003
@export var smooth_factor: float = 15.0

var _velocity: Vector3 = Vector3.ZERO
var _target_rotation: Vector2 = Vector2.ZERO # x = pitch, y = yaw
var _mouse_captured: bool = false

@export var terrain_node_path: NodePath = ^"../IslandTerrain"
var _terrain_ref: IslandTerrain = null

func _ready() -> void:
	_target_rotation.y = rotation.y
	_target_rotation.x = rotation.x
	if has_node(terrain_node_path):
		_terrain_ref = get_node(terrain_node_path) as IslandTerrain

func look_at_target(target: Vector3) -> void:
	look_at(target, Vector3.UP)
	_target_rotation.y = rotation.y
	_target_rotation.x = rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.is_pressed():
			_toggle_mouse_capture(not _mouse_captured)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.is_pressed():
			move_speed = clampf(move_speed + 2.0, 8.0, 38.0)
			fast_move_speed = move_speed * 2.2
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.is_pressed():
			move_speed = clampf(move_speed - 2.0, 8.0, 38.0)
			fast_move_speed = move_speed * 2.2
	elif event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		if _mouse_captured:
			_toggle_mouse_capture(false)
	elif event is InputEventMouseMotion and _mouse_captured:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_target_rotation.y -= motion.relative.x * mouse_sensitivity
		_target_rotation.x -= motion.relative.y * mouse_sensitivity
		_target_rotation.x = clamp(_target_rotation.x, -deg_to_rad(88.0), deg_to_rad(88.0))

func _toggle_mouse_capture(capture: bool) -> void:
	_mouse_captured = capture
	if _mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	if not _terrain_ref and has_node(terrain_node_path):
		_terrain_ref = get_node(terrain_node_path) as IslandTerrain
		
	# Smooth rotation interpolation
	rotation.y = lerp_angle(rotation.y, _target_rotation.y, smooth_factor * delta)
	rotation.x = lerp_angle(rotation.x, _target_rotation.x, smooth_factor * delta)
	
	# Movement input with action check and direct key fallback
	var input_dir: Vector3 = Vector3.ZERO
	
	var fwd: bool = Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var bwd: bool = Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var lft: bool = Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var rgt: bool = Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var up: bool = Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_E)
	var down: bool = Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_C)
	
	if fwd:
		input_dir -= transform.basis.z
	if bwd:
		input_dir += transform.basis.z
	if lft:
		input_dir -= transform.basis.x
	if rgt:
		input_dir += transform.basis.x
	if up:
		input_dir += Vector3.UP
	if down:
		input_dir -= Vector3.UP
		
	var speed: float = fast_move_speed if Input.is_key_pressed(KEY_SHIFT) else move_speed
	var target_vel: Vector3 = input_dir.normalized() * speed if input_dir.length_squared() > 0.0 else Vector3.ZERO
	_velocity = _velocity.lerp(target_vel, smooth_factor * delta)
	position += _velocity * delta
	
	# Clearance and boundary protection (no clipping underground or diving under water)
	var min_clearance: float = 0.85
	if _terrain_ref:
		var terrain_h: float = _terrain_ref.get_height_at(position.x, position.z)
		min_clearance = maxf(terrain_h + 0.9, 0.85)
		
	if position.y < min_clearance:
		position.y = lerpf(position.y, min_clearance, clampf(delta * 14.0, 0.0, 1.0))
		
	# Bounded exploration ceilings
	position.y = clampf(position.y, min_clearance, 68.0)
	position.x = clampf(position.x, -76.0, 76.0)
	position.z = clampf(position.z, -76.0, 76.0)
