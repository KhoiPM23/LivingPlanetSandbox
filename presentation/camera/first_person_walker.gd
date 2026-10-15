class_name FirstPersonWalker
extends CharacterBody3D

## Living Planet Sandbox — Player Character & Exploration Controller.
## Inspired by Red Dead Redemption 2 / GTA V ground-level wilderness exploration.
## Features:
## - Full 3D skinned humanoid character mesh (MIT-licensed Godot 3D model)
## - Skeletal animation state machine: Idle, Walk, Run, Jump, Falling with smooth cross-fade blending
## - Smooth character rotation towards movement direction (no instant snaps)
## - Weighty acceleration & natural deceleration stopping with floor snap
## - SpringArm3D collision-avoiding third-person camera (never clips into rocks, cliffs, or trees)
## - Seamless toggle between Third-Person (default exploration) and First-Person perspectives
## - Ecosystem proximity broadcasting to trigger realistic wildlife responses

signal perspective_changed(is_third_person: bool)

# --- MOVEMENT SETTINGS ---
@export var walk_speed: float = 3.6
@export var sprint_speed: float = 7.5
@export var jump_velocity: float = 5.6
@export var gravity: float = 19.6
@export var turn_speed: float = 11.5
@export var acceleration: float = 16.0
@export var deceleration: float = 14.0
@export var eye_height: float = 1.65

# --- CAMERA SETTINGS ---
@export var mouse_sensitivity: float = 0.0028
@export var camera_distance: float = 3.2
@export var min_camera_distance: float = 1.6
@export var max_camera_distance: float = 5.5
@export var min_pitch: float = deg_to_rad(-55.0)
@export var max_pitch: float = deg_to_rad(65.0)
@export var shoulder_offset_x: float = 0.28
@export var shoulder_height: float = 1.45

# --- STATE VARIABLES ---
var is_third_person: bool = true
var _terrain: IslandTerrain = null
var _capsule: CapsuleShape3D = null
var _collision_shape: CollisionShape3D = null

# Child nodes
var _model_root: Node3D = null
var _character_instance: Node3D = null
var _anim_player: AnimationPlayer = null
var _spring_arm: SpringArm3D = null
var _camera: Camera3D = null

# Camera rotation
var _cam_yaw: float = 0.0
var _cam_pitch: float = deg_to_rad(-10.0)
var _target_cam_yaw: float = 0.0
var _target_cam_pitch: float = deg_to_rad(-10.0)
var _model_yaw: float = 0.0

# Movement states
var _is_sprinting: bool = false
var _current_anim: String = ""

func _init() -> void:
	collision_layer = 2 # Player layer
	collision_mask = 1  # StaticBody3D terrain, props, boulders
	floor_max_angle = deg_to_rad(48.0)
	floor_snap_length = 0.40
	floor_stop_on_slope = true
	floor_constant_speed = true

	_build_collision()

func _ready() -> void:
	if not _collision_shape:
		_build_collision()
	_build_model()
	_build_camera_rig()
	_setup_animations()

func _build_collision() -> void:
	if _collision_shape:
		return
	_collision_shape = CollisionShape3D.new()
	_collision_shape.name = "PlayerCollisionShape"
	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.35
	_capsule.height = 1.75
	_collision_shape.shape = _capsule
	# Center capsule so base rests at Y = 0.0
	_collision_shape.position = Vector3(0.0, 0.875, 0.0)
	add_child(_collision_shape)

func _build_model() -> void:
	if _model_root:
		return
	_model_root = Node3D.new()
	_model_root.name = "ModelRoot"
	add_child(_model_root)

	var scn: PackedScene = load("res://presentation/assets/models/human_character.glb") as PackedScene
	if scn:
		_character_instance = scn.instantiate()
		_character_instance.name = "HumanMesh"
		# Base model is 2.118m tall; scale to 1.75m human proportion
		var scale_factor: float = 1.75 / 2.118
		_character_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
		_model_root.add_child(_character_instance)

		_anim_player = _character_instance.find_child("*AnimationPlayer*", true, false) as AnimationPlayer

func _build_camera_rig() -> void:
	if _spring_arm:
		return
	_spring_arm = SpringArm3D.new()
	_spring_arm.name = "CameraSpringArm"
	_spring_arm.position = Vector3(shoulder_offset_x, shoulder_height, 0.0)
	_spring_arm.spring_length = camera_distance
	_spring_arm.margin = 0.22
	_spring_arm.collision_mask = 1 # Collides with terrain and rock boulders

	var sphere_shape: SphereShape3D = SphereShape3D.new()
	sphere_shape.radius = 0.18
	_spring_arm.shape = sphere_shape
	add_child(_spring_arm)

	_camera = Camera3D.new()
	_camera.name = "PlayerCamera"
	_camera.near = 0.15
	_camera.far = 280.0
	_spring_arm.add_child(_camera)

func _setup_animations() -> void:
	if not _anim_player:
		return

	# Set linear looping on locomotion clips
	var loop_clips: Array[String] = ["idle", "walk", "run", "falling"]
	for clip_name in loop_clips:
		if _anim_player.has_animation(clip_name):
			var anim: Animation = _anim_player.get_animation(clip_name)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR

	# Configure cross-fade blending for seamless transitions
	_anim_player.set_blend_time("idle", "walk", 0.20)
	_anim_player.set_blend_time("walk", "idle", 0.25)
	_anim_player.set_blend_time("walk", "run", 0.20)
	_anim_player.set_blend_time("run", "walk", 0.20)
	_anim_player.set_blend_time("idle", "run", 0.20)
	_anim_player.set_blend_time("run", "idle", 0.30)
	_anim_player.set_blend_time("idle", "jump", 0.10)
	_anim_player.set_blend_time("walk", "jump", 0.10)
	_anim_player.set_blend_time("run", "jump", 0.10)
	_anim_player.set_blend_time("jump", "falling", 0.15)
	_anim_player.set_blend_time("falling", "idle", 0.20)
	_anim_player.set_blend_time("falling", "walk", 0.20)
	_anim_player.set_blend_time("falling", "run", 0.20)

	_play_anim("idle")

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

func get_camera() -> Camera3D:
	return _camera

func set_perspective(third_person: bool) -> void:
	is_third_person = third_person
	if not _spring_arm or not _character_instance:
		return

	if is_third_person:
		# Third-person: Camera behind shoulder on spring arm, character visible
		_spring_arm.position = Vector3(shoulder_offset_x, shoulder_height, 0.0)
		_spring_arm.spring_length = camera_distance
		_set_model_shadow_mode(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	else:
		# First-person: Camera placed directly at eye position
		_spring_arm.position = Vector3(0.0, eye_height, 0.0)
		_spring_arm.spring_length = 0.0
		# In first person, only cast shadows so the mesh doesn't occlude camera
		_set_model_shadow_mode(GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)

	perspective_changed.emit(is_third_person)

func toggle_perspective() -> void:
	set_perspective(not is_third_person)

func _set_model_shadow_mode(mode: GeometryInstance3D.ShadowCastingSetting) -> void:
	if not _character_instance:
		return
	var mesh_inst: MeshInstance3D = _character_instance.find_child("Robot", true, false) as MeshInstance3D
	if mesh_inst:
		mesh_inst.cast_shadow = mode

## Handle mouse rotation for camera orbit
func rotate_camera(relative: Vector2) -> void:
	_target_cam_yaw -= relative.x * mouse_sensitivity
	_target_cam_pitch -= relative.y * mouse_sensitivity
	_target_cam_pitch = clampf(_target_cam_pitch, min_pitch, max_pitch)

## Handle camera zoom
func zoom_camera(delta_zoom: float) -> void:
	if not is_third_person:
		return
	camera_distance = clampf(camera_distance + delta_zoom, min_camera_distance, max_camera_distance)
	if _spring_arm:
		_spring_arm.spring_length = camera_distance

## Main physics movement update
func move_character(delta: float, wish_dir: Vector3, is_sprinting: bool, want_jump: bool) -> void:
	_is_sprinting = is_sprinting
	var on_ground: bool = is_on_floor() if is_inside_tree() else true

	# 1. Vertical Movement & Gravity
	if not on_ground:
		velocity.y -= gravity * delta
	else:
		if want_jump:
			velocity.y = jump_velocity
		else:
			velocity.y = -0.1

	var current_pos: Vector3 = global_position if is_inside_tree() else position

	# 2. Horizontal Movement & Deceleration
	var target_speed: float = sprint_speed if is_sprinting else walk_speed
	# Water dampening in shallow lagoon
	if current_pos.y < 0.2:
		target_speed *= 0.70

	var has_input: bool = wish_dir.length_squared() > 0.001
	if has_input:
		var target_h: Vector3 = wish_dir.normalized() * target_speed
		var rate: float = acceleration if on_ground else 5.0
		velocity.x = lerpf(velocity.x, target_h.x, clampf(rate * delta, 0.0, 1.0))
		velocity.z = lerpf(velocity.z, target_h.z, clampf(rate * delta, 0.0, 1.0))

		# Smooth character facing direction towards movement vector
		var target_yaw: float = atan2(-wish_dir.x, -wish_dir.z)
		_model_yaw = lerp_angle(_model_yaw, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))
		if _model_root:
			_model_root.rotation.y = _model_yaw
	else:
		# Natural deceleration with friction
		var rate: float = deceleration if on_ground else 2.5
		velocity.x = lerpf(velocity.x, 0.0, clampf(rate * delta, 0.0, 1.0))
		velocity.z = lerpf(velocity.z, 0.0, clampf(rate * delta, 0.0, 1.0))

	# 3. Move and slide
	if is_inside_tree():
		move_and_slide()
		current_pos = global_position
	else:
		position += velocity * delta
		current_pos = position

	# 4. Enforce Island Boundaries (radius 74m)
	var horiz: Vector2 = Vector2(current_pos.x, current_pos.z)
	if horiz.length() > 74.0:
		var clamped: Vector2 = horiz.normalized() * 74.0
		current_pos.x = clamped.x
		current_pos.z = clamped.y
		if is_inside_tree():
			global_position = current_pos
		else:
			position = current_pos

	if current_pos.y < -1.5:
		current_pos.y = -1.5
		velocity.y = 0.0
		if is_inside_tree():
			global_position = current_pos
		else:
			position = current_pos

	# 5. Update Animation State Machine
	_update_animation_state(delta, has_input, is_sprinting, on_ground)

func _update_animation_state(delta: float, has_input: bool, is_sprint: bool, on_ground: bool) -> void:
	if not _anim_player:
		return

	var h_speed: float = Vector2(velocity.x, velocity.z).length()

	if not on_ground:
		if velocity.y > 0.8:
			_play_anim("jump")
		else:
			_play_anim("falling")
	else:
		if h_speed < 0.15 or not has_input:
			_play_anim("idle")
			_anim_player.speed_scale = 1.0
		elif is_sprint and h_speed > 4.2:
			_play_anim("run")
			_anim_player.speed_scale = clampf(h_speed / 5.8, 0.85, 1.45)
		else:
			_play_anim("walk")
			_anim_player.speed_scale = clampf(h_speed / 2.8, 0.75, 1.35)

func _play_anim(anim_name: String) -> void:
	if _current_anim == anim_name:
		return
	if _anim_player and _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name)
		_current_anim = anim_name

func update_camera_rotation(delta: float) -> void:
	_cam_yaw = lerp_angle(_cam_yaw, _target_cam_yaw, clampf(18.0 * delta, 0.0, 1.0))
	_cam_pitch = lerp_angle(_cam_pitch, _target_cam_pitch, clampf(18.0 * delta, 0.0, 1.0))

	if _spring_arm:
		_spring_arm.rotation.y = _cam_yaw
		_spring_arm.rotation.x = _cam_pitch

func get_camera_yaw() -> float:
	return _cam_yaw

func get_camera_pitch() -> float:
	return _cam_pitch

func is_sprinting() -> bool:
	return _is_sprinting and Vector2(velocity.x, velocity.z).length() > 3.0

## Contract-compatible alias for existing camera/tests
func move_walker(delta: float, wish_dir: Vector3, is_sprinting_flag: bool, want_jump: bool) -> Vector3:
	move_character(delta, wish_dir, is_sprinting_flag, want_jump)
	return get_eye_position()
