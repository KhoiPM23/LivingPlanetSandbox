class_name UpdraftVent3D
extends Node3D

## Living Planet Sandbox — Block 46 Genshin-Style Elemental Updraft Vent.
## Swirling anemo vertical air current that propels the player high into the sky (+14.2 m/s)
## and automatically deploys the Anemo Glider for scenic mountain and coastal soaring.

signal player_boosted(walker: Node)

@export var updraft_radius: float = 2.8
@export var updraft_height: float = 14.5
@export var updraft_power: float = 14.2
@export var vent_color: Color = Color(0.60, 0.92, 0.82, 0.65)

var _base_ring: MeshInstance3D = null
var _particles: GPUParticles3D = null
var _wind_column: MeshInstance3D = null
var _player_ref: Node = null
var _boost_cooldown: float = 0.0

func _ready() -> void:
	_build_visuals()

func setup(pos: Vector3, custom_power: float = 14.2, custom_height: float = 14.5) -> void:
	position = pos
	updraft_power = custom_power
	updraft_height = custom_height

func set_player_reference(p: Node) -> void:
	_player_ref = p

func _build_visuals() -> void:
	# 1. Subtle carved stone anemo rune ring
	_base_ring = MeshInstance3D.new()
	_base_ring.name = "AnemoRuneRing"
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 1.30
	torus.outer_radius = 1.55
	torus.rings = 24
	torus.ring_segments = 16
	_base_ring.mesh = torus
	_base_ring.position = Vector3(0.0, 0.08, 0.0)

	var ring_mat: StandardMaterial3D = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.42, 0.46, 0.44) # Weathered granite ring
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.50, 0.85, 0.75)
	ring_mat.emission_energy_multiplier = 0.35 # Soft, natural rune glow
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_base_ring.material_override = ring_mat
	add_child(_base_ring)

	# 2. Subtle ethereal swirling vertical air current (ultra-soft transparency)
	_wind_column = MeshInstance3D.new()
	_wind_column.name = "WindColumnVortex"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 1.65
	cyl.bottom_radius = 1.35
	cyl.height = updraft_height
	cyl.radial_segments = 24
	_wind_column.mesh = cyl
	_wind_column.position = Vector3(0.0, updraft_height * 0.5, 0.0)

	var col_mat: StandardMaterial3D = StandardMaterial3D.new()
	col_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	col_mat.albedo_color = Color(0.85, 0.96, 0.92, 0.025) # Gentle air refraction, no harsh cyan tube
	col_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	col_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_wind_column.material_override = col_mat
	add_child(_wind_column)

	# 3. Rising swirl breeze particle wisps
	_particles = GPUParticles3D.new()
	_particles.name = "UpdraftParticles"
	_particles.amount = 24
	_particles.lifetime = 1.35
	_particles.position = Vector3(0.0, 0.2, 0.0)

	var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	p_mat.emission_ring_radius = 1.35
	p_mat.emission_ring_inner_radius = 0.4
	p_mat.emission_ring_height = 0.2
	p_mat.direction = Vector3(0.0, 1.0, 0.0)
	p_mat.spread = 6.0
	p_mat.initial_velocity_min = 9.5
	p_mat.initial_velocity_max = 13.0
	p_mat.color = Color(0.88, 0.98, 0.94, 0.35)
	_particles.process_material = p_mat

	var p_mesh: SphereMesh = SphereMesh.new()
	p_mesh.radius = 0.05
	p_mesh.height = 0.14
	var p_smat: StandardMaterial3D = StandardMaterial3D.new()
	p_smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_smat.albedo_color = Color(0.88, 0.98, 0.94, 0.30)
	p_smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mesh.material = p_smat
	_particles.draw_pass_1 = p_mesh
	add_child(_particles)

func _process(delta: float) -> void:
	if _base_ring:
		_base_ring.rotation.y += 1.2 * delta
	if _wind_column:
		_wind_column.rotation.y -= 1.8 * delta

	if _boost_cooldown > 0.0:
		_boost_cooldown -= delta

func _physics_process(_delta: float) -> void:
	_check_player_updraft()

func _check_player_updraft() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		_resolve_player()
	if _player_ref == null:
		return

	var p_pos: Vector3 = _player_ref.global_position if _player_ref.is_inside_tree() else _player_ref.position
	var self_pos: Vector3 = global_position if is_inside_tree() else position

	var horiz_dist: float = Vector2(p_pos.x - self_pos.x, p_pos.z - self_pos.z).length()
	var vert_delta: float = p_pos.y - self_pos.y

	if horiz_dist <= updraft_radius and vert_delta >= -0.5 and vert_delta <= updraft_height:
		_apply_updraft(_player_ref)

func _apply_updraft(walker: Node) -> void:
	if "velocity" in walker:
		# Propel upward
		walker.velocity.y = maxf(walker.velocity.y, updraft_power)

	if walker.has_method("open_glider") and "is_gliding" in walker:
		if not walker.is_gliding and walker.velocity.y > 4.0:
			walker.open_glider()

	if _boost_cooldown <= 0.0:
		_boost_cooldown = 0.5
		player_boosted.emit(walker)

func _resolve_player() -> void:
	if get_tree() and get_tree().current_scene:
		var scene: Node = get_tree().current_scene
		var cam: Node = scene.get_node_or_null("FreeLookCamera")
		if cam and cam.has_method("get_walker"):
			_player_ref = cam.get_walker()
			if _player_ref:
				return
		var w: Node = scene.find_child("*Walker*", true, false)
		if w:
			_player_ref = w
			return
