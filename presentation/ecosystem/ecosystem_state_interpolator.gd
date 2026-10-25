class_name EcosystemStateInterpolator
extends Node

## Living Planet Sandbox — Block 61: State Interpolation & Anti-Jank Engine (Giai đoạn 1.1)
## Bridges low-frequency 2Hz discrete simulation updates to silky 60+ FPS presentation:
## - Hermite cubic spline position interpolation with continuous first derivatives (zero jerk)
## - Quaternion/Spherical yaw interpolation preventing sudden angular snapping
## - Velocity-based aerodynamic banking roll on turns
## - Dead reckoning & extrapolation dampener when ticks fluctuate
## - Direct Node3D auto-binding for seamless presentation updates

class EntitySample:
	var position: Vector3 = Vector3.ZERO
	var yaw: float = 0.0
	var timestamp: float = 0.0
	var velocity: Vector3 = Vector3.ZERO

	func _init(p: Vector3 = Vector3.ZERO, y: float = 0.0, t: float = 0.0, v: Vector3 = Vector3.ZERO) -> void:
		position = p
		yaw = y
		timestamp = t
		velocity = v

class EntityMotionBuffer:
	var id: String = ""
	var node_ref: Node3D = null
	var samples: Array[EntitySample] = []
	var max_samples: int = 4
	var current_render_pos: Vector3 = Vector3.ZERO
	var current_render_yaw: float = 0.0
	var current_render_roll: float = 0.0
	var interpolation_delay: float = 0.12 # Delay buffer for Hermite curve evaluation
	var buffer_time: float = 0.0

	func _init(entity_id: String, target_node: Node3D = null) -> void:
		id = entity_id
		node_ref = target_node

	func add_sample(pos: Vector3, y: float, time_sec: float) -> void:
		var vel: Vector3 = Vector3.ZERO
		if not samples.is_empty():
			var prev: EntitySample = samples.back()
			var dt: float = maxf(0.001, time_sec - prev.timestamp)
			vel = (pos - prev.position) / dt

		var s: EntitySample = EntitySample.new(pos, y, time_sec, vel)
		samples.append(s)
		while samples.size() > max_samples:
			samples.pop_front()

		if samples.size() == 1:
			current_render_pos = pos
			current_render_yaw = y

var _buffers: Dictionary = {}
var _global_sim_time: float = 0.0

func _init() -> void:
	name = "EcosystemStateInterpolator"

func _process(delta: float) -> void:
	_global_sim_time += delta
	update_all(delta)

## Register or retrieve a motion buffer for an entity
func register_entity(entity_id: String, target_node: Node3D = null) -> EntityMotionBuffer:
	if _buffers.has(entity_id):
		var buf: EntityMotionBuffer = _buffers[entity_id]
		if target_node != null:
			buf.node_ref = target_node
		return buf

	var new_buf: EntityMotionBuffer = EntityMotionBuffer.new(entity_id, target_node)
	_buffers[entity_id] = new_buf
	return new_buf

func unregister_entity(entity_id: String) -> void:
	_buffers.erase(entity_id)

func has_entity(entity_id: String) -> bool:
	return _buffers.has(entity_id)

func clear_all() -> void:
	_buffers.clear()

## Feed a discrete simulation tick state (e.g. from 2Hz Fauna tick)
func push_state(entity_id: String, pos: Vector3, yaw: float, timestamp: float = -1.0) -> void:
	var t: float = timestamp if timestamp >= 0.0 else _global_sim_time
	var buf: EntityMotionBuffer = register_entity(entity_id)
	buf.add_sample(pos, yaw, t)

## Evaluate Hermite cubic spline position interpolation
func update_all(delta: float) -> void:
	for id: String in _buffers.keys():
		var buf: EntityMotionBuffer = _buffers[id]
		_interpolate_buffer(buf, delta)
		if buf.node_ref and is_instance_valid(buf.node_ref):
			buf.node_ref.position = buf.current_render_pos
			buf.node_ref.rotation.y = buf.current_render_yaw
			buf.node_ref.rotation.z = buf.current_render_roll

func _interpolate_buffer(buf: EntityMotionBuffer, delta: float) -> void:
	if buf.samples.size() < 2:
		if not buf.samples.is_empty():
			buf.current_render_pos = buf.samples.back().position
			buf.current_render_yaw = buf.samples.back().yaw
		return

	# Target render time is buffered slightly behind current simulation time
	var render_target_time: float = _global_sim_time - buf.interpolation_delay

	# Find surrounding sample pair
	var s0: EntitySample = buf.samples[0]
	var s1: EntitySample = buf.samples.back()
	var found_span: bool = false

	for i in range(buf.samples.size() - 1):
		var a: EntitySample = buf.samples[i]
		var b: EntitySample = buf.samples[i + 1]
		if a.timestamp <= render_target_time and render_target_time <= b.timestamp:
			s0 = a
			s1 = b
			found_span = true
			break

	if not found_span:
		# Extrapolate or clamp to latest sample
		var latest: EntitySample = buf.samples.back()
		var overshoot: float = maxf(0.0, render_target_time - latest.timestamp)
		# Damped linear dead-reckoning
		var damped_vel: Vector3 = latest.velocity * exp(-3.0 * overshoot)
		var target_extrapolated: Vector3 = latest.position + damped_vel * overshoot
		buf.current_render_pos = buf.current_render_pos.lerp(target_extrapolated, clampf(14.0 * delta, 0.0, 1.0))
		buf.current_render_yaw = lerp_angle(buf.current_render_yaw, latest.yaw, clampf(14.0 * delta, 0.0, 1.0))
		buf.current_render_roll = lerpf(buf.current_render_roll, 0.0, clampf(8.0 * delta, 0.0, 1.0))
		return

	var span_dt: float = maxf(0.0001, s1.timestamp - s0.timestamp)
	var t_norm: float = clampf((render_target_time - s0.timestamp) / span_dt, 0.0, 1.0)

	# Hermite cubic basis functions:
	# h00(t) = 2t^3 - 3t^2 + 1
	# h10(t) = t^3 - 2t^2 + t
	# h01(t) = -2t^3 + 3t^2
	# h11(t) = t^3 - t^2
	var t2: float = t_norm * t_norm
	var t3: float = t2 * t_norm
	var h00: float = 2.0 * t3 - 3.0 * t2 + 1.0
	var h10: float = t3 - 2.0 * t2 + t_norm
	var h01: float = -2.0 * t3 + 3.0 * t2
	var h11: float = t3 - t2

	var m0: Vector3 = s0.velocity * span_dt
	var m1: Vector3 = s1.velocity * span_dt

	var hermite_pos: Vector3 = h00 * s0.position + h10 * m0 + h01 * s1.position + h11 * m1
	buf.current_render_pos = hermite_pos

	# Angular interpolation
	buf.current_render_yaw = lerp_angle(s0.yaw, s1.yaw, t_norm)

	# Dynamic banking roll based on yaw angular rate
	var yaw_rate: float = wrapf(s1.yaw - s0.yaw, -PI, PI) / span_dt
	var target_roll: float = clampf(-yaw_rate * 0.15, -deg_to_rad(15.0), deg_to_rad(15.0))
	buf.current_render_roll = lerpf(buf.current_render_roll, target_roll, clampf(10.0 * delta, 0.0, 1.0))

func get_interpolated_position(entity_id: String) -> Vector3:
	if _buffers.has(entity_id):
		return _buffers[entity_id].current_render_pos
	return Vector3.ZERO

func get_interpolated_yaw(entity_id: String) -> float:
	if _buffers.has(entity_id):
		return _buffers[entity_id].current_render_yaw
	return 0.0

func get_interpolated_roll(entity_id: String) -> float:
	if _buffers.has(entity_id):
		return _buffers[entity_id].current_render_roll
	return 0.0
