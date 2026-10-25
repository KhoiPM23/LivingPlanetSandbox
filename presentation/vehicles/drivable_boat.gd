class_name DrivableBoat
extends CharacterBody3D

## Living Planet Sandbox — Interactive Drivable Expedition Skiff
## Allows the player to board at the wooden pier, row across the open sea,
## explore coastal coves, and disembark seamlessly onto the shore.
## Controls:
## - [E]: Board Boat / Disembark onto Shore
## - [W] / [S]: Row Forward / Reverse
## - [A] / [D]: Steer Rudder Left / Right
## - Mouse: Free Camera Orbit around Boat

signal player_mounted(boat: DrivableBoat)
signal player_dismounted(boat: DrivableBoat)

@export var max_forward_speed: float = 7.2
@export var max_reverse_speed: float = 2.4
@export var acceleration: float = 4.2
@export var deceleration: float = 3.0
@export var turn_speed: float = 1.8
@export var water_level: float = 0.0

var is_driven: bool = false
var _current_forward_speed: float = 0.0
var _angular_velocity: float = 0.0
var _boat_time: float = 0.0

var _driver_walker: FirstPersonWalker = null
var _main_camera: FreeLookCamera = null
var _terrain_ref: IslandTerrain = null

# Child nodes
var _hull_mesh: MeshInstance3D = null
var _oar_left: MeshInstance3D = null
var _oar_right: MeshInstance3D = null
var _wake_particles: GPUParticles3D = null
var _interact_area: Area3D = null
var _spring_arm: SpringArm3D = null
var _boat_camera: Camera3D = null
var _audio_splash: AudioStreamPlayer3D = null

# Fishing Rig (Block 43)
var _fishing_rod: MeshInstance3D = null
var _bobber: MeshInstance3D = null
var _fishing_hint_label: Label3D = null
var _is_fishing_active: bool = false
var _is_bobber_biting: bool = false

# Camera orbit around boat
var _cam_yaw: float = 0.0
var _cam_pitch: float = deg_to_rad(-14.0)
var _target_cam_yaw: float = 0.0
var _target_cam_pitch: float = deg_to_rad(-14.0)

# Procedural Audio Cache
static var _row_splash_wav: AudioStreamWAV = null

func _init() -> void:
	collision_layer = 4 # Vehicle layer
	collision_mask = 1  # Terrain / obstacle layer
	_init_procedural_splash_audio()

func _ready() -> void:
	_build_boat_geometry()
	_build_wake_particles()
	_build_interaction_area()
	_build_camera_rig()
	_build_fishing_rig()
	_build_audio()

func setup_terrain(terrain: IslandTerrain) -> void:
	_terrain_ref = terrain

func _build_boat_geometry() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Pointed bow at -Z, wide transom stern at +Z
	var bow_tip: Vector3 = Vector3(0.0, 0.42, -2.1)
	var bow_keel: Vector3 = Vector3(0.0, -0.22, -1.7)
	var mid_port: Vector3 = Vector3(-0.75, 0.35, 0.0)
	var mid_stbd: Vector3 = Vector3(0.75, 0.35, 0.0)
	var mid_keel: Vector3 = Vector3(0.0, -0.28, 0.0)
	var stern_port: Vector3 = Vector3(-0.62, 0.32, 1.6)
	var stern_stbd: Vector3 = Vector3(0.62, 0.32, 1.6)
	var stern_keel: Vector3 = Vector3(0.0, -0.18, 1.6)

	# Bottom hull port & starboard
	_add_tri(st, bow_keel, mid_keel, mid_port)
	_add_tri(st, bow_keel, bow_tip, mid_port)
	_add_tri(st, bow_keel, mid_stbd, mid_keel)
	_add_tri(st, bow_keel, mid_stbd, bow_tip)

	_add_tri(st, mid_keel, stern_keel, stern_port)
	_add_tri(st, mid_keel, stern_port, mid_port)
	_add_tri(st, mid_keel, stern_stbd, stern_keel)
	_add_tri(st, mid_keel, mid_stbd, stern_stbd)

	# Transom stern plate
	_add_tri(st, stern_keel, stern_port, stern_stbd)

	# Internal seat / thwart
	var seat_y: float = 0.12
	_add_tri(st, Vector3(-0.68, seat_y, -0.25), Vector3(0.68, seat_y, -0.25), Vector3(0.68, seat_y, 0.25))
	_add_tri(st, Vector3(-0.68, seat_y, -0.25), Vector3(0.68, seat_y, 0.25), Vector3(-0.68, seat_y, 0.25))

	st.generate_normals()
	var mesh_res: ArrayMesh = st.commit()

	_hull_mesh = MeshInstance3D.new()
	_hull_mesh.name = "SkiffHull"
	_hull_mesh.mesh = mesh_res

	# Weathered cedar boat material
	var b_mat: StandardMaterial3D = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.48, 0.34, 0.20)
	b_mat.roughness = 0.72
	_hull_mesh.material_override = b_mat
	add_child(_hull_mesh)

	# Collision shape for boat
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.6, 0.8, 3.8)
	col.shape = box
	col.position = Vector3(0.0, 0.15, 0.0)
	add_child(col)

	# Dual Oars
	_oar_left = _create_oar(true)
	_oar_right = _create_oar(false)
	add_child(_oar_left)
	add_child(_oar_right)

func _create_oar(is_left: bool) -> MeshInstance3D:
	var oar: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.03
	cyl.bottom_radius = 0.035
	cyl.height = 2.4
	oar.mesh = cyl
	var o_mat: StandardMaterial3D = StandardMaterial3D.new()
	o_mat.albedo_color = Color(0.62, 0.48, 0.30)
	o_mat.roughness = 0.80
	oar.material_override = o_mat

	var side_mult: float = 1.0 if is_left else -1.0
	oar.position = Vector3(side_mult * 0.78, 0.25, 0.0)
	oar.rotation.z = deg_to_rad(side_mult * 55.0)
	oar.rotation.y = deg_to_rad(side_mult * 15.0)
	return oar

func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

func _build_wake_particles() -> void:
	_wake_particles = GPUParticles3D.new()
	_wake_particles.name = "BoatWaterWake"
	_wake_particles.position = Vector3(0.0, 0.0, 1.7)
	_wake_particles.amount = 32
	_wake_particles.lifetime = 1.4
	_wake_particles.emitting = false

	var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(0.65, 0.05, 0.3)
	p_mat.direction = Vector3(0.0, 0.2, 1.0)
	p_mat.spread = 20.0
	p_mat.initial_velocity_min = 1.2
	p_mat.initial_velocity_max = 2.8
	p_mat.gravity = Vector3(0.0, -1.5, 0.0)
	p_mat.scale_min = 0.10
	p_mat.scale_max = 0.35
	p_mat.color = Color(0.90, 0.96, 1.0, 0.55)
	_wake_particles.process_material = p_mat

	var p_mesh: SphereMesh = SphereMesh.new()
	p_mesh.radius = 0.15
	p_mesh.height = 0.30
	var s_mat: StandardMaterial3D = StandardMaterial3D.new()
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.albedo_color = Color(0.92, 0.98, 1.0, 0.40)
	s_mat.roughness = 0.10
	p_mesh.material = s_mat
	_wake_particles.draw_pass_1 = p_mesh

	add_child(_wake_particles)

func _build_interaction_area() -> void:
	_interact_area = Area3D.new()
	_interact_area.name = "BoardingTrigger"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 3.2
	shape.shape = sphere
	_interact_area.add_child(shape)
	add_child(_interact_area)

func _build_camera_rig() -> void:
	_spring_arm = SpringArm3D.new()
	_spring_arm.name = "BoatSpringArm"
	_spring_arm.spring_length = 5.8
	_spring_arm.margin = 0.25
	_spring_arm.position = Vector3(0.0, 1.6, 0.0)

	var s_shape: SphereShape3D = SphereShape3D.new()
	s_shape.radius = 0.25
	_spring_arm.shape = s_shape
	add_child(_spring_arm)

	_boat_camera = Camera3D.new()
	_boat_camera.name = "BoatCamera"
	_boat_camera.fov = 75.0
	_boat_camera.near = 0.15
	_boat_camera.far = 950.0
	_spring_arm.add_child(_boat_camera)

func _build_audio() -> void:
	_audio_splash = AudioStreamPlayer3D.new()
	_audio_splash.name = "RowAudio"
	_audio_splash.unit_size = 5.0
	_audio_splash.max_distance = 45.0
	add_child(_audio_splash)

func _build_fishing_rig() -> void:
	_fishing_rod = MeshInstance3D.new()
	_fishing_rod.name = "BoatFishingRod"
	var r_cyl: CylinderMesh = CylinderMesh.new()
	r_cyl.top_radius = 0.015
	r_cyl.bottom_radius = 0.035
	r_cyl.height = 3.2
	_fishing_rod.mesh = r_cyl
	var rod_mat: StandardMaterial3D = StandardMaterial3D.new()
	rod_mat.albedo_color = Color(0.72, 0.60, 0.35)
	rod_mat.roughness = 0.65
	_fishing_rod.material_override = rod_mat
	_fishing_rod.position = Vector3(0.55, 0.65, -0.6)
	_fishing_rod.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(20.0), deg_to_rad(15.0))
	_fishing_rod.visible = false
	add_child(_fishing_rod)

	_bobber = MeshInstance3D.new()
	_bobber.name = "BoatFishingBobber"
	var b_sph: SphereMesh = SphereMesh.new()
	b_sph.radius = 0.12
	b_sph.height = 0.24
	_bobber.mesh = b_sph
	var b_mat: StandardMaterial3D = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.95, 0.22, 0.22)
	b_mat.roughness = 0.3
	_bobber.material_override = b_mat
	_bobber.position = Vector3(1.2, 0.0, -4.5)
	_bobber.visible = false
	add_child(_bobber)

	_fishing_hint_label = Label3D.new()
	_fishing_hint_label.name = "FishingPrompt"
	_fishing_hint_label.text = "🎣 Đang thả câu... [F] Thu cần"
	_fishing_hint_label.font_size = 22
	_fishing_hint_label.modulate = Color(1.0, 0.95, 0.6)
	_fishing_hint_label.outline_modulate = Color(0.1, 0.1, 0.2, 0.9)
	_fishing_hint_label.outline_size = 6
	_fishing_hint_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_fishing_hint_label.position = Vector3(1.2, 1.4, -4.5)
	_fishing_hint_label.visible = false
	add_child(_fishing_hint_label)

func set_fishing_visuals(active: bool, biting: bool = false) -> void:
	_is_fishing_active = active
	_is_bobber_biting = biting
	if _fishing_rod:
		_fishing_rod.visible = active
	if _bobber:
		_bobber.visible = active
	if _fishing_hint_label:
		_fishing_hint_label.visible = active
		if biting:
			_fishing_hint_label.text = "🎣 CÁ CẮN CÂU! [SPACE] ĐỂ GIẬT CẦN!"
			_fishing_hint_label.modulate = Color(1.0, 0.35, 0.25)
		else:
			_fishing_hint_label.text = "🎣 Đang thả câu... [F] Thu cần"
			_fishing_hint_label.modulate = Color(0.85, 0.95, 1.0)

func _init_procedural_splash_audio() -> void:
	if _row_splash_wav != null:
		return
	var sample_rate: int = 22050
	var duration: float = 0.38
	var total_samples: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_samples * 2)

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 9.5) * sin(t * 3.14159 / duration)
		var noise: float = (randf() * 2.0 - 1.0) * 0.45
		var low_wave: float = sin(2.0 * PI * 180.0 * t) * 0.55
		var s: float = (noise + low_wave) * env * 0.55
		var sample_val: int = int(clampf(s, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)

	_row_splash_wav = AudioStreamWAV.new()
	_row_splash_wav.format = AudioStreamWAV.FORMAT_16_BITS
	_row_splash_wav.mix_rate = sample_rate
	_row_splash_wav.stereo = false
	_row_splash_wav.data = byte_array

func can_interact(player_pos: Vector3) -> bool:
	var b_pos: Vector3 = global_position if is_inside_tree() else position
	return b_pos.distance_to(player_pos) <= 3.2

func mount_player(walker: FirstPersonWalker, camera: FreeLookCamera) -> void:
	if is_driven:
		return
	is_driven = true
	_driver_walker = walker
	_main_camera = camera

	# Disable walker movement & hide mesh
	_driver_walker.visible = false
	_driver_walker.set_physics_process(false)

	# Transition camera to Boat Camera
	_boat_camera.make_current()
	_target_cam_yaw = rotation.y
	_cam_yaw = rotation.y
	_target_cam_pitch = deg_to_rad(-14.0)
	_cam_pitch = deg_to_rad(-14.0)

	player_mounted.emit(self)
	print("[Boat] Player mounted the expedition skiff.")

func dismount_player() -> void:
	if not is_driven or not _driver_walker:
		return
	is_driven = false

	# Position walker on nearest land or pier safely
	var cur_pos: Vector3 = global_position if is_inside_tree() else position
	var cur_basis: Basis = global_transform.basis if is_inside_tree() else transform.basis
	var dismount_pos: Vector3 = cur_pos + (cur_basis * Vector3(-1.8, 0.4, 0.0))
	if _terrain_ref:
		var ground_h: float = _terrain_ref.get_height_at(dismount_pos.x, dismount_pos.z)
		dismount_pos.y = maxf(ground_h + 0.15, 0.35)

	_driver_walker.teleport_to(dismount_pos)
	_driver_walker.visible = true
	_driver_walker.set_physics_process(true)

	if _driver_walker.get_camera():
		_driver_walker.get_camera().make_current()

	_current_forward_speed = 0.0
	_angular_velocity = 0.0
	if _wake_particles:
		_wake_particles.emitting = false
	set_fishing_visuals(false, false)

	var prev_walker = _driver_walker
	_driver_walker = null
	player_dismounted.emit(self)
	print("[Boat] Player dismounted onto shore.")

func _unhandled_input(event: InputEvent) -> void:
	if not is_driven:
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_target_cam_yaw -= event.relative.x * 0.003
		_target_cam_pitch -= event.relative.y * 0.003
		_target_cam_pitch = clampf(_target_cam_pitch, deg_to_rad(-55.0), deg_to_rad(25.0))

func _physics_process(delta: float) -> void:
	_boat_time += delta

	if is_driven:
		_process_driving_controls(delta)
	else:
		_process_idle_moored_bobbing(delta)

func _process_driving_controls(delta: float) -> void:
	var want_forward: float = 0.0
	var want_turn: float = 0.0

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		want_forward += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		want_forward -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		want_turn += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		want_turn -= 1.0

	# Accelerate / Decelerate
	var target_speed: float = want_forward * (max_forward_speed if want_forward > 0.0 else max_reverse_speed)
	var accel_rate: float = acceleration if want_forward != 0.0 else deceleration
	_current_forward_speed = move_toward(_current_forward_speed, target_speed, accel_rate * delta)

	# Steer rudder
	var target_turn: float = want_turn * turn_speed
	_angular_velocity = move_toward(_angular_velocity, target_turn, 4.0 * delta)
	rotation.y += _angular_velocity * delta

	# Calculate horizontal velocity
	var forward_dir: Vector3 = -global_transform.basis.z
	velocity = forward_dir * _current_forward_speed

	# Move boat on horizontal water plane
	move_and_slide()

	# Keep height locked to water surface with wave bobbing
	var wave_amp: float = 0.09
	var wave_y: float = sin(_boat_time * 2.2 + position.x * 0.2) * wave_amp
	position.y = water_level + wave_y

	# Banking roll on turns & pitch on acceleration
	var bank_roll: float = -_angular_velocity * 0.10
	var accel_pitch: float = -(_current_forward_speed / max_forward_speed) * 0.08
	rotation.z = lerpf(rotation.z, bank_roll, delta * 5.0)
	rotation.x = lerpf(rotation.x, accel_pitch, delta * 4.0)

	# Animated oar rowing motion
	if absf(_current_forward_speed) > 0.4:
		var oar_swing: float = sin(_boat_time * 5.5) * 0.35
		_oar_left.rotation.y = deg_to_rad(15.0) + oar_swing
		_oar_right.rotation.y = deg_to_rad(-15.0) - oar_swing
		if _wake_particles:
			_wake_particles.emitting = (_current_forward_speed > 0.8)

		# Periodic splash sound
		if fposmod(_boat_time * 5.5, PI) < 0.12 and _audio_splash and not _audio_splash.playing:
			_audio_splash.stream = _row_splash_wav
			_audio_splash.pitch_scale = randf_range(0.92, 1.08)
			_audio_splash.play()
	else:
		if _wake_particles:
			_wake_particles.emitting = false

	# Camera follow smoothing
	_cam_yaw = lerp_angle(_cam_yaw, _target_cam_yaw, delta * 12.0)
	_cam_pitch = lerpf(_cam_pitch, _target_cam_pitch, delta * 12.0)
	if _spring_arm:
		_spring_arm.rotation = Vector3(_cam_pitch, _cam_yaw - rotation.y, 0.0)

	# Dynamic bobber wave reaction
	if _is_fishing_active and _bobber:
		if _is_bobber_biting:
			_bobber.position.y = -0.06 + sin(_boat_time * 24.0) * 0.12
		else:
			_bobber.position.y = sin(_boat_time * 2.2) * 0.04

func _process_idle_moored_bobbing(delta: float) -> void:
	var wave_amp: float = 0.07
	var bob_y: float = sin(_boat_time * 1.5 + 0.4) * wave_amp + (cos(_boat_time * 2.6) * (wave_amp * 0.3))
	var pitch: float = sin(_boat_time * 1.3) * 0.04
	var roll: float = cos(_boat_time * 1.7 + 0.2) * 0.05

	position.y = water_level + bob_y
	rotation.x = pitch
	rotation.z = roll
