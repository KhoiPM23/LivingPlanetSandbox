class_name FirstPersonWalker
extends CharacterBody3D

## First-person walking exploration controller.
## Provides physical capsule collision against island terrain, gravity, slope handling,
## jump mechanics, and maintains realistic eye height (1.65m) above the terrain surface.

@export var walk_speed: float = 6.0
@export var sprint_speed: float = 10.5
@export var jump_velocity: float = 5.2
@export var gravity: float = 19.6
@export var eye_height: float = 1.65 # 1.6 - 1.7m realistic human eye level

var _collision_shape: CollisionShape3D = null
var _capsule: CapsuleShape3D = null
var _terrain: IslandTerrain = null

func _init() -> void:
	collision_layer = 2 # Player/Camera layer
	collision_mask = 1  # Collides with StaticBody3D terrain and world environment
	floor_max_angle = deg_to_rad(48.0) # Up to 48 deg traversable slopes
	floor_snap_length = 0.35 # Snaps to slopes descending smoothly
	floor_stop_on_slope = true
	floor_constant_speed = true

	_build_collision()

func _ready() -> void:
	if not _collision_shape:
		_build_collision()

func _build_collision() -> void:
	if _collision_shape:
		return

	_collision_shape = CollisionShape3D.new()
	_collision_shape.name = "WalkerCollisionShape"

	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.35
	_capsule.height = 1.75 # Standard character height

	_collision_shape.shape = _capsule
	# Center capsule so base is at Y = 0.0 and top is at Y = 1.75
	_collision_shape.position = Vector3(0.0, 0.875, 0.0)
	add_child(_collision_shape)

func setup(terrain: IslandTerrain) -> void:
	_terrain = terrain

func teleport_to(ground_pos: Vector3) -> void:
	velocity = Vector3.ZERO
	if is_inside_tree():
		global_position = ground_pos
	else:
		position = ground_pos

func get_eye_position() -> Vector3:
	var base_pos: Vector3 = global_position if is_inside_tree() else position
	return base_pos + Vector3(0.0, eye_height, 0.0)

## Main physics movement update called by camera controller during physics step
func move_walker(delta: float, wish_dir: Vector3, is_sprinting: bool, want_jump: bool) -> Vector3:
	var on_ground: bool = is_on_floor() if is_inside_tree() else true

	# 1. Gravity and Vertical Movement
	if not on_ground:
		velocity.y -= gravity * delta
	else:
		if want_jump:
			velocity.y = jump_velocity
		else:
			# Slight downward velocity to maintain floor snap
			velocity.y = -0.1

	var current_pos: Vector3 = global_position if is_inside_tree() else position

	# 2. Horizontal Movement
	var target_speed: float = sprint_speed if is_sprinting else walk_speed
	# If walking in shallow ocean water (Y < 0.2m), dampen speed
	if current_pos.y < 0.2:
		target_speed *= 0.70

	var target_h: Vector3 = wish_dir * target_speed
	var accel: float = 16.0 if on_ground else 4.0
	velocity.x = lerpf(velocity.x, target_h.x, clampf(accel * delta, 0.0, 1.0))
	velocity.z = lerpf(velocity.z, target_h.z, clampf(accel * delta, 0.0, 1.0))

	# 3. Physics Move and Slide
	if is_inside_tree():
		move_and_slide()
		current_pos = global_position
	else:
		position += velocity * delta
		current_pos = position

	# 4. Enforce Island Boundary Limits (radius 74m)
	var horiz: Vector2 = Vector2(current_pos.x, current_pos.z)
	if horiz.length() > 74.0:
		var clamped: Vector2 = horiz.normalized() * 74.0
		current_pos.x = clamped.x
		current_pos.z = clamped.y
		if is_inside_tree():
			global_position = current_pos
		else:
			position = current_pos

	# Sea floor safety clamp
	if current_pos.y < -1.5:
		current_pos.y = -1.5
		velocity.y = 0.0
		if is_inside_tree():
			global_position = current_pos
		else:
			position = current_pos

	return get_eye_position()
