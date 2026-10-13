class_name FreeLookCamera
extends Camera3D

## Exploration camera controller supporting 4 distinct modes:
## 1. FREE_LOOK: 6-DOF free flight navigation with smooth damping
## 2. ORBIT_INSPECT: Spherical orbit around static target coordinate or landmark
## 3. FOLLOW_ENTITY: Smooth tracking camera following moving living creatures
## 4. TOP_DOWN: High-altitude tactical overview of the island ecosystem
## Includes scenic POI bookmarks, smooth transitions, terrain clearance, and compass telemetry.

enum CameraMode {
	FREE_LOOK = 0,
	ORBIT_INSPECT = 1,
	FOLLOW_ENTITY = 2,
	TOP_DOWN = 3,
	FIRST_PERSON_WALKER = 4
}

signal mode_changed(new_mode: CameraMode, mode_name: String)
signal bookmark_reached(bookmark_id: int, bookmark_name: String)
signal followed_entity_lost(entity_id: int)

# --- CONFIGURATION EXPORTS ---
@export var move_speed: float = 18.0
@export var fast_move_speed: float = 40.0
@export var mouse_sensitivity: float = 0.003
@export var smooth_factor: float = 15.0
@export var terrain_node_path: NodePath = ^"../IslandTerrain"

# --- CAMERA MODE & STATE ---
var current_mode: CameraMode = CameraMode.FREE_LOOK
var _velocity: Vector3 = Vector3.ZERO
var _target_rotation: Vector2 = Vector2.ZERO # x = pitch, y = yaw
var _mouse_captured: bool = false
var _input_blocked: bool = false
var _terrain_ref: IslandTerrain = null
var _walker: FirstPersonWalker = null

# --- ORBIT & FOLLOW PARAMETERS ---
var orbit_target: Vector3 = Vector3.ZERO
var orbit_distance: float = 7.0
var min_orbit_distance: float = 2.0
var max_orbit_distance: float = 38.0
var orbit_azimuth: float = 0.0   # Horizontal angle around target (radians)
var orbit_elevation: float = deg_to_rad(28.0) # Pitch angle above horizon (radians)

var _follow_node: Node3D = null
var _follow_callable: Callable = Callable()
var _follow_entity_id: int = -1

# --- TOP-DOWN PARAMETERS ---
var top_down_altitude: float = 48.0
var min_top_down_alt: float = 18.0
var max_top_down_alt: float = 65.0

# --- TRANSITION INTERPOLATION ---
var _in_transition: bool = false
var _transition_time: float = 0.0
var _transition_duration: float = 0.75
var _trans_start_pos: Vector3 = Vector3.ZERO
var _trans_target_pos: Vector3 = Vector3.ZERO
var _trans_start_rot: Vector2 = Vector2.ZERO
var _trans_target_rot: Vector2 = Vector2.ZERO
var _trans_on_complete: Callable = Callable()

# --- SCENIC BOOKMARKS / POINTS OF INTEREST ---
const BOOKMARKS: Array[Dictionary] = [
	{
		"id": 0,
		"name": "Island Panorama",
		"pos": Vector3(25.0, 14.0, 32.0),
		"target": Vector3(0.0, 4.0, 0.0),
		"mode": CameraMode.FREE_LOOK
	},
	{
		"id": 1,
		"name": "Summit Monolith",
		"pos": Vector3(-13.0, 18.0, -11.0),
		"target": Vector3(-16.0, 15.5, -14.0),
		"mode": CameraMode.ORBIT_INSPECT,
		"orbit_target": Vector3(-16.0, 15.5, -14.0),
		"orbit_dist": 6.5
	},
	{
		"id": 2,
		"name": "Emerald Meadows",
		"pos": Vector3(-4.0, 6.5, 14.0),
		"target": Vector3(-2.0, 3.5, 0.0),
		"mode": CameraMode.FREE_LOOK
	},
	{
		"id": 3,
		"name": "Coastal Shoreline",
		"pos": Vector3(22.0, 3.2, -10.0),
		"target": Vector3(0.0, 2.0, 0.0),
		"mode": CameraMode.FREE_LOOK
	},
	{
		"id": 4,
		"name": "Tactical Overview",
		"pos": Vector3(0.0, 50.0, 0.0),
		"target": Vector3(0.0, 0.0, 0.0),
		"mode": CameraMode.TOP_DOWN
	}
]
var _current_bookmark_idx: int = -1

func _ready() -> void:
	_target_rotation.y = rotation.y
	_target_rotation.x = rotation.x
	if has_node(terrain_node_path):
		_terrain_ref = get_node(terrain_node_path) as IslandTerrain
	_ensure_walker()

func _ensure_walker() -> void:
	if _walker == null:
		_walker = FirstPersonWalker.new()
		_walker.name = "FirstPersonWalkerBody"
		_walker.top_level = true
		add_child(_walker)
		if _terrain_ref:
			_walker.setup(_terrain_ref)

func get_walker() -> FirstPersonWalker:
	if _walker == null:
		_ensure_walker()
	return _walker

func set_input_blocked(blocked: bool) -> void:
	_input_blocked = blocked
	if _input_blocked and _mouse_captured:
		release_mouse()

func is_input_blocked() -> bool:
	return _input_blocked

func capture_mouse() -> void:
	_mouse_captured = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func release_mouse() -> void:
	_mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func look_at_target(target: Vector3) -> void:
	if is_inside_tree():
		look_at(target, Vector3.UP)
		_target_rotation.y = rotation.y
		_target_rotation.x = rotation.x
	else:
		var fwd: Vector3 = (target - position).normalized()
		if fwd.length_squared() > 0.001:
			_target_rotation.y = atan2(-fwd.x, -fwd.z)
			var horiz: float = Vector2(fwd.x, fwd.z).length()
			_target_rotation.x = atan2(fwd.y, horiz)
			rotation.y = _target_rotation.y
			rotation.x = _target_rotation.x


# =========================================================================
# CAMERA MODE SWITCHING
# =========================================================================
func set_camera_mode(new_mode: CameraMode, instant: bool = false) -> void:
	if current_mode == new_mode:
		return
	var old_mode: CameraMode = current_mode
	current_mode = new_mode

	if old_mode == CameraMode.FIRST_PERSON_WALKER and new_mode != CameraMode.FIRST_PERSON_WALKER:
		release_mouse()

	if current_mode == CameraMode.FIRST_PERSON_WALKER:
		_ensure_walker()
		var ground_y: float = 0.0
		if _terrain_ref:
			ground_y = _terrain_ref.get_height_at(position.x, position.z)
		var spawn_pos: Vector3 = Vector3(position.x, ground_y, position.z)
		if _walker:
			_walker.teleport_to(spawn_pos)
			position = _walker.get_eye_position()
		_target_rotation.y = rotation.y
		_target_rotation.x = clampf(rotation.x, -deg_to_rad(60.0), deg_to_rad(60.0))
		rotation.x = _target_rotation.x
		_follow_node = null
		_follow_callable = Callable()
		_follow_entity_id = -1
		if not _input_blocked:
			capture_mouse()
	elif current_mode == CameraMode.TOP_DOWN:
		var target_pos: Vector3 = Vector3(position.x, top_down_altitude, position.z)
		var target_rot: Vector2 = Vector2(-deg_to_rad(85.0), 0.0)
		if instant:
			position = target_pos
			_target_rotation = target_rot
			rotation.x = target_rot.x
			rotation.y = target_rot.y
		else:
			_start_smooth_transition(target_pos, target_rot, 0.6)
	elif current_mode == CameraMode.FREE_LOOK:
		_target_rotation.y = rotation.y
		_target_rotation.x = rotation.x
		_follow_node = null
		_follow_callable = Callable()
		_follow_entity_id = -1

	mode_changed.emit(current_mode, get_mode_name(current_mode))

func cycle_camera_mode() -> void:
	if current_mode == CameraMode.FREE_LOOK:
		set_camera_mode(CameraMode.FIRST_PERSON_WALKER)
	elif current_mode == CameraMode.FIRST_PERSON_WALKER:
		set_camera_mode(CameraMode.FREE_LOOK)
	else:
		set_camera_mode(CameraMode.FREE_LOOK)

func get_mode_name(mode: CameraMode) -> String:
	match mode:
		CameraMode.FREE_LOOK: return "Free Flight"
		CameraMode.ORBIT_INSPECT: return "Orbit View"
		CameraMode.FOLLOW_ENTITY: return "Tracking Entity"
		CameraMode.TOP_DOWN: return "Tactical Map"
		CameraMode.FIRST_PERSON_WALKER: return "First-Person Walker"
		_: return "Unknown"

# =========================================================================
# ORBIT & FOLLOW CONTROL
# =========================================================================
func start_orbit(target_pos: Vector3, distance: float = 7.0, instant: bool = false) -> void:
	orbit_target = target_pos
	orbit_distance = clampf(distance, min_orbit_distance, max_orbit_distance)

	# Compute current angles relative to target
	var offset: Vector3 = position - orbit_target
	if offset.length_squared() > 0.01:
		orbit_azimuth = atan2(offset.x, offset.z)
		var horizontal_dist: float = Vector2(offset.x, offset.z).length()
		orbit_elevation = clampf(atan2(offset.y, horizontal_dist), deg_to_rad(-5.0), deg_to_rad(80.0))

	current_mode = CameraMode.ORBIT_INSPECT
	_follow_node = null
	_follow_callable = Callable()
	_follow_entity_id = -1

	var desired_pos: Vector3 = _calculate_orbit_position(orbit_target, orbit_azimuth, orbit_elevation, orbit_distance)
	if instant:
		position = desired_pos
		look_at_target(orbit_target)
	else:
		_start_smooth_transition_lookat(desired_pos, orbit_target, 0.6)

	mode_changed.emit(current_mode, get_mode_name(current_mode))

func start_following_node(node: Node3D, distance: float = 6.0, entity_id: int = -1, instant: bool = false) -> void:
	if not is_instance_valid(node):
		return
	_follow_node = node
	_follow_callable = Callable()
	_follow_entity_id = entity_id
	orbit_target = node.global_position if node.is_inside_tree() else node.position
	orbit_distance = clampf(distance, min_orbit_distance, max_orbit_distance)

	current_mode = CameraMode.FOLLOW_ENTITY

	var desired_pos: Vector3 = _calculate_orbit_position(orbit_target, orbit_azimuth, orbit_elevation, orbit_distance)
	if instant:
		position = desired_pos
		look_at_target(orbit_target)
	else:
		_start_smooth_transition_lookat(desired_pos, orbit_target, 0.5)

	mode_changed.emit(current_mode, get_mode_name(current_mode))

func start_following_callable(pos_getter: Callable, distance: float = 6.0, entity_id: int = -1, instant: bool = false) -> void:
	if not pos_getter.is_valid():
		return
	_follow_node = null
	_follow_callable = pos_getter
	_follow_entity_id = entity_id
	var initial_pos: Variant = pos_getter.call()
	if initial_pos is Vector3:
		orbit_target = initial_pos
	orbit_distance = clampf(distance, min_orbit_distance, max_orbit_distance)
	current_mode = CameraMode.FOLLOW_ENTITY

	var desired_pos: Vector3 = _calculate_orbit_position(orbit_target, orbit_azimuth, orbit_elevation, orbit_distance)
	if instant:
		position = desired_pos
		look_at_target(orbit_target)
	else:
		_start_smooth_transition_lookat(desired_pos, orbit_target, 0.5)

	mode_changed.emit(current_mode, get_mode_name(current_mode))

func stop_following() -> void:
	if current_mode == CameraMode.FOLLOW_ENTITY:
		set_camera_mode(CameraMode.FREE_LOOK)

func _calculate_orbit_position(target: Vector3, azimuth: float, elevation: float, dist: float) -> Vector3:
	var cos_elev: float = cos(elevation)
	var x: float = sin(azimuth) * cos_elev * dist
	var y: float = sin(elevation) * dist
	var z: float = cos(azimuth) * cos_elev * dist
	return target + Vector3(x, y, z)

# =========================================================================
# SCENIC POI BOOKMARKS
# =========================================================================
func get_bookmarks() -> Array[Dictionary]:
	return BOOKMARKS

func jump_to_bookmark(index: int, instant: bool = false) -> void:
	if index < 0 or index >= BOOKMARKS.size():
		return
	_current_bookmark_idx = index
	var bm: Dictionary = BOOKMARKS[index]
	var dest_pos: Vector3 = bm["pos"]
	var target_look: Vector3 = bm["target"]
	var target_mode: CameraMode = bm["mode"]

	if instant:
		current_mode = target_mode
		position = dest_pos
		look_at_target(target_look)
		if bm.has("orbit_target"):
			orbit_target = bm["orbit_target"]
			orbit_distance = bm.get("orbit_dist", 7.0)
		mode_changed.emit(current_mode, get_mode_name(current_mode))
		bookmark_reached.emit(bm["id"], bm["name"])
	else:
		_start_smooth_transition_lookat(dest_pos, target_look, 0.8, func():
			current_mode = target_mode
			if bm.has("orbit_target"):
				orbit_target = bm["orbit_target"]
				orbit_distance = bm.get("orbit_dist", 7.0)
			mode_changed.emit(current_mode, get_mode_name(current_mode))
			bookmark_reached.emit(bm["id"], bm["name"])
		)

func cycle_bookmark() -> void:
	var next_idx: int = (_current_bookmark_idx + 1) % BOOKMARKS.size()
	jump_to_bookmark(next_idx, false)

# =========================================================================
# COMPASS & ORIENTATION TELEMETRY
# =========================================================================
func get_compass_heading_degrees() -> float:
	# Facing vector on horizontal XZ plane
	var fwd: Vector3 = -transform.basis.z
	var angle_rad: float = atan2(fwd.x, -fwd.z) # 0 = North (-Z), PI/2 = East (+X)
	var deg: float = rad_to_deg(angle_rad)
	if deg < 0.0:
		deg += 360.0
	return deg

func get_compass_cardinal() -> String:
	var deg: float = get_compass_heading_degrees()
	var cardinals: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var idx: int = int(round(deg / 45.0)) % 8
	return cardinals[idx]

# =========================================================================
# INPUT HANDLING
# =========================================================================
func _unhandled_input(event: InputEvent) -> void:
	if _input_blocked:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.is_pressed():
			if current_mode == CameraMode.FREE_LOOK:
				_toggle_mouse_capture(not _mouse_captured)
			elif current_mode == CameraMode.FIRST_PERSON_WALKER:
				if not _mouse_captured:
					capture_mouse()
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.is_pressed():
			if current_mode == CameraMode.FIRST_PERSON_WALKER and not _mouse_captured:
				capture_mouse()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.is_pressed():
			_handle_zoom_in()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.is_pressed():
			_handle_zoom_out()
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			if current_mode == CameraMode.FIRST_PERSON_WALKER:
				release_mouse()
			elif _mouse_captured:
				release_mouse()
			elif current_mode != CameraMode.FREE_LOOK:
				set_camera_mode(CameraMode.FREE_LOOK)
		elif event.keycode == KEY_V:
			cycle_camera_mode()
		elif event.keycode == KEY_B:
			cycle_bookmark()
	elif event is InputEventMouseMotion and _mouse_captured:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_handle_mouse_look(motion.relative)

func _handle_zoom_in() -> void:
	match current_mode:
		CameraMode.FREE_LOOK:
			move_speed = clampf(move_speed + 2.0, 8.0, 38.0)
			fast_move_speed = move_speed * 2.2
		CameraMode.ORBIT_INSPECT, CameraMode.FOLLOW_ENTITY:
			orbit_distance = clampf(orbit_distance - 0.75, min_orbit_distance, max_orbit_distance)
		CameraMode.TOP_DOWN:
			top_down_altitude = clampf(top_down_altitude - 3.0, min_top_down_alt, max_top_down_alt)

func _handle_zoom_out() -> void:
	match current_mode:
		CameraMode.FREE_LOOK:
			move_speed = clampf(move_speed - 2.0, 8.0, 38.0)
			fast_move_speed = move_speed * 2.2
		CameraMode.ORBIT_INSPECT, CameraMode.FOLLOW_ENTITY:
			orbit_distance = clampf(orbit_distance + 0.75, min_orbit_distance, max_orbit_distance)
		CameraMode.TOP_DOWN:
			top_down_altitude = clampf(top_down_altitude + 3.0, min_top_down_alt, max_top_down_alt)

func _handle_mouse_look(rel: Vector2) -> void:
	match current_mode:
		CameraMode.FREE_LOOK, CameraMode.FIRST_PERSON_WALKER:
			_target_rotation.y -= rel.x * mouse_sensitivity
			_target_rotation.x -= rel.y * mouse_sensitivity
			_target_rotation.x = clamp(_target_rotation.x, -deg_to_rad(85.0), deg_to_rad(85.0))
		CameraMode.ORBIT_INSPECT, CameraMode.FOLLOW_ENTITY:
			orbit_azimuth -= rel.x * mouse_sensitivity * 1.5
			orbit_elevation += rel.y * mouse_sensitivity * 1.5
			orbit_elevation = clampf(orbit_elevation, deg_to_rad(-5.0), deg_to_rad(82.0))
		CameraMode.TOP_DOWN:
			# In top-down mode, right-drag pans the camera
			position.x -= rel.x * 0.05
			position.z -= rel.y * 0.05

func _toggle_mouse_capture(capture: bool) -> void:
	_mouse_captured = capture
	if _mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# =========================================================================
# TRANSITION LOGIC
# =========================================================================
func _start_smooth_transition(target_pos: Vector3, target_rot: Vector2, duration: float, on_complete: Callable = Callable()) -> void:
	_in_transition = true
	_transition_time = 0.0
	_transition_duration = duration
	_trans_start_pos = position
	_trans_target_pos = target_pos
	_trans_start_rot = Vector2(rotation.x, rotation.y)
	_trans_target_rot = target_rot
	_trans_on_complete = on_complete

func _start_smooth_transition_lookat(target_pos: Vector3, look_at_pt: Vector3, duration: float, on_complete: Callable = Callable()) -> void:
	_in_transition = true
	_transition_time = 0.0
	_transition_duration = duration
	_trans_start_pos = position
	_trans_target_pos = target_pos
	_trans_start_rot = Vector2(rotation.x, rotation.y)

	# Calculate target rotation looking at look_at_pt from target_pos
	var fwd: Vector3 = (look_at_pt - target_pos).normalized()
	var yaw: float = atan2(-fwd.x, -fwd.z)
	var horiz: float = Vector2(fwd.x, fwd.z).length()
	var pitch: float = atan2(fwd.y, horiz)
	_trans_target_rot = Vector2(pitch, yaw)
	_trans_on_complete = on_complete

# =========================================================================
# MAIN PROCESS UPDATE
# =========================================================================
func _physics_process(delta: float) -> void:
	if current_mode == CameraMode.FIRST_PERSON_WALKER:
		_process_walker(delta)

func _process_walker(delta: float) -> void:
	if _walker == null:
		_ensure_walker()
	if _walker == null:
		return

	rotation.y = lerp_angle(rotation.y, _target_rotation.y, smooth_factor * delta)
	rotation.x = lerp_angle(rotation.x, _target_rotation.x, smooth_factor * delta)

	if _input_blocked:
		position = _walker.get_eye_position()
		return

	var wish_dir: Vector3 = Vector3.ZERO
	var fwd: bool = Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var bwd: bool = Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var lft: bool = Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var rgt: bool = Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)

	var cam_yaw: float = rotation.y
	var fwd_vec: Vector3 = Vector3(-sin(cam_yaw), 0.0, -cos(cam_yaw))
	var rgt_vec: Vector3 = Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw))

	if fwd: wish_dir += fwd_vec
	if bwd: wish_dir -= fwd_vec
	if lft: wish_dir -= rgt_vec
	if rgt: wish_dir += rgt_vec

	if wish_dir.length_squared() > 0.001:
		wish_dir = wish_dir.normalized()

	var is_sprinting: bool = Input.is_key_pressed(KEY_SHIFT)
	var want_jump: bool = Input.is_key_pressed(KEY_SPACE)

	var eye_pos: Vector3 = _walker.move_walker(delta, wish_dir, is_sprinting, want_jump)
	position = eye_pos

func _process(delta: float) -> void:
	if not _terrain_ref and has_node(terrain_node_path):
		_terrain_ref = get_node(terrain_node_path) as IslandTerrain

	if _in_transition:
		_process_transition(delta)
		_enforce_boundaries(delta)
		return

	if current_mode == CameraMode.FIRST_PERSON_WALKER:
		rotation.y = lerp_angle(rotation.y, _target_rotation.y, smooth_factor * delta)
		rotation.x = lerp_angle(rotation.x, _target_rotation.x, smooth_factor * delta)
		if _walker:
			position = _walker.get_eye_position()
		return

	match current_mode:
		CameraMode.FREE_LOOK:
			_process_free_look(delta)
		CameraMode.ORBIT_INSPECT:
			_process_orbit_inspect(delta)
		CameraMode.FOLLOW_ENTITY:
			_process_follow_entity(delta)
		CameraMode.TOP_DOWN:
			_process_top_down(delta)

	_enforce_boundaries(delta)

func _process_transition(delta: float) -> void:
	_transition_time += delta
	var t: float = clampf(_transition_time / _transition_duration, 0.0, 1.0)
	var ease_t: float = _ease_in_out(t)

	position = _trans_start_pos.lerp(_trans_target_pos, ease_t)
	rotation.x = lerp_angle(_trans_start_rot.x, _trans_target_rot.x, ease_t)
	rotation.y = lerp_angle(_trans_start_rot.y, _trans_target_rot.y, ease_t)
	_target_rotation = Vector2(rotation.x, rotation.y)

	if t >= 1.0:
		_in_transition = false
		if _trans_on_complete.is_valid():
			_trans_on_complete.call()
			_trans_on_complete = Callable()

func _ease_in_out(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)

func _process_free_look(delta: float) -> void:
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

	if fwd: input_dir -= transform.basis.z
	if bwd: input_dir += transform.basis.z
	if lft: input_dir -= transform.basis.x
	if rgt: input_dir += transform.basis.x
	if up: input_dir += Vector3.UP
	if down: input_dir -= Vector3.UP

	var speed: float = fast_move_speed if Input.is_key_pressed(KEY_SHIFT) else move_speed
	var target_vel: Vector3 = input_dir.normalized() * speed if input_dir.length_squared() > 0.0 else Vector3.ZERO
	_velocity = _velocity.lerp(target_vel, smooth_factor * delta)
	position += _velocity * delta

func _process_orbit_inspect(delta: float) -> void:
	var desired_pos: Vector3 = _calculate_orbit_position(orbit_target, orbit_azimuth, orbit_elevation, orbit_distance)
	position = position.lerp(desired_pos, clampf(delta * smooth_factor, 0.0, 1.0))

	# Keep facing target
	var fwd: Vector3 = (orbit_target - position).normalized()
	if fwd.length_squared() > 0.001:
		var target_yaw: float = atan2(-fwd.x, -fwd.z)
		var horiz: float = Vector2(fwd.x, fwd.z).length()
		var target_pitch: float = atan2(fwd.y, horiz)
		rotation.y = lerp_angle(rotation.y, target_yaw, smooth_factor * delta)
		rotation.x = lerp_angle(rotation.x, target_pitch, smooth_factor * delta)
		_target_rotation = Vector2(rotation.x, rotation.y)

func _process_follow_entity(delta: float) -> void:
	var valid_target: bool = false
	if is_instance_valid(_follow_node):
		var target_pt: Vector3 = _follow_node.global_position if _follow_node.is_inside_tree() else _follow_node.position
		orbit_target = orbit_target.lerp(target_pt, clampf(delta * 12.0, 0.0, 1.0))
		valid_target = true

	elif _follow_callable.is_valid():
		var pt: Variant = _follow_callable.call()
		if pt is Vector3:
			orbit_target = orbit_target.lerp(pt, clampf(delta * 12.0, 0.0, 1.0))
			valid_target = true

	if not valid_target:
		# Target entity lost/died
		if _follow_entity_id != -1:
			followed_entity_lost.emit(_follow_entity_id)
		# Fall back to orbit inspect at last known position
		current_mode = CameraMode.ORBIT_INSPECT
		_follow_node = null
		_follow_callable = Callable()
		_follow_entity_id = -1
		mode_changed.emit(current_mode, get_mode_name(current_mode))
		return

	# Follow position
	_process_orbit_inspect(delta)

func _process_top_down(delta: float) -> void:
	# Planar panning
	var pan_dir: Vector3 = Vector3.ZERO
	if Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		pan_dir.z -= 1.0
	if Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		pan_dir.z += 1.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		pan_dir.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		pan_dir.x += 1.0

	var speed: float = fast_move_speed if Input.is_key_pressed(KEY_SHIFT) else move_speed
	var target_vel: Vector3 = pan_dir.normalized() * speed if pan_dir.length_squared() > 0.0 else Vector3.ZERO
	_velocity = _velocity.lerp(target_vel, smooth_factor * delta)
	position.x += _velocity.x * delta
	position.z += _velocity.z * delta
	position.y = lerpf(position.y, top_down_altitude, clampf(delta * 8.0, 0.0, 1.0))

	# Fixed looking down
	rotation.x = lerp_angle(rotation.x, -deg_to_rad(85.0), smooth_factor * delta)
	rotation.y = lerp_angle(rotation.y, 0.0, smooth_factor * delta)
	_target_rotation = Vector2(rotation.x, rotation.y)

# =========================================================================
# BOUNDARIES & CLEARANCE ENFORCEMENT
# =========================================================================
func _enforce_boundaries(delta: float) -> void:
	var min_clearance: float = 0.85
	if _terrain_ref:
		var terrain_h: float = _terrain_ref.get_height_at(position.x, position.z)
		min_clearance = maxf(terrain_h + 0.9, 0.85)

	if position.y < min_clearance:
		position.y = lerpf(position.y, min_clearance, clampf(delta * 14.0, 0.0, 1.0))

	# Bounded exploration ceilings and island horizontal limits
	position.y = clampf(position.y, min_clearance, 68.0)
	position.x = clampf(position.x, -76.0, 76.0)
	position.z = clampf(position.z, -76.0, 76.0)
