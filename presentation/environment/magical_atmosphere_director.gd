class_name MagicalAtmosphereDirector
extends Node3D

## Living Planet Sandbox — Cinematic Magical Atmosphere & Atmospheric FX Director (Block 53)
## Features:
## 1. Floating Dandelion Tufts & Windflower Petals (day-time drifting breeze particles)
## 2. Nocturnal Luminous Fireflies (glowing golden-green orbs automatically active at dusk/night)
## 3. Atmospheric God Ray Sun Shafts (soft translucent shafts piercing down into the Grand Lake & forest canopy)
## 4. Intel Iris Xe optimized: shared unshaded additive materials, capped particle counts, zero performance lag

var _target_player: Node3D = null
var _day_night: Node = null # DayNightCycle reference
var _dandelion_particles: GPUParticles3D = null
var _firefly_particles: GPUParticles3D = null
var _sun_rays_root: Node3D = null
var _ray_mesh_instances: Array[MeshInstance3D] = []

var _anim_time: float = 0.0

func _init() -> void:
	name = "MagicalAtmosphereDirector"
	_build_dandelion_and_petal_particles()
	_build_nocturnal_fireflies()
	_build_volumetric_sun_rays()

func setup(player_node: Node3D, day_night_node: Node = null) -> void:
	_target_player = player_node
	_day_night = day_night_node

func _build_dandelion_and_petal_particles() -> void:
	_dandelion_particles = GPUParticles3D.new()
	_dandelion_particles.name = "DandelionPetalParticles"
	_dandelion_particles.amount = 40
	_dandelion_particles.lifetime = 6.0
	_dandelion_particles.preprocess = 2.0
	_dandelion_particles.visibility_aabb = AABB(Vector3(-25.0, -8.0, -25.0), Vector3(50.0, 16.0, 50.0))

	var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(22.0, 5.0, 22.0)
	p_mat.direction = Vector3(0.8, 0.15, 0.4).normalized()
	p_mat.spread = 28.0
	p_mat.initial_velocity_min = 1.0
	p_mat.initial_velocity_max = 2.4
	p_mat.gravity = Vector3(0.0, -0.04, 0.0) # Slow gentle float
	p_mat.scale_min = 0.08
	p_mat.scale_max = 0.18
	p_mat.color = Color(1.0, 0.96, 0.92, 0.82)
	_dandelion_particles.process_material = p_mat

	# Soft tuft mesh
	var s_mesh: SphereMesh = SphereMesh.new()
	s_mesh.radius = 0.06
	s_mesh.height = 0.12
	var m_mat: StandardMaterial3D = StandardMaterial3D.new()
	m_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_mat.albedo_color = Color(1.0, 0.98, 0.92, 0.85)
	s_mesh.material = m_mat
	_dandelion_particles.draw_pass_1 = s_mesh

	add_child(_dandelion_particles)

func _build_nocturnal_fireflies() -> void:
	_firefly_particles = GPUParticles3D.new()
	_firefly_particles.name = "NocturnalFireflies"
	_firefly_particles.amount = 32
	_firefly_particles.lifetime = 4.8
	_firefly_particles.preprocess = 1.5
	_firefly_particles.visibility_aabb = AABB(Vector3(-20.0, -4.0, -20.0), Vector3(40.0, 10.0, 40.0))

	var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(18.0, 2.5, 18.0)
	p_mat.direction = Vector3(0.0, 1.0, 0.0)
	p_mat.spread = 80.0
	p_mat.initial_velocity_min = 0.3
	p_mat.initial_velocity_max = 0.8
	p_mat.gravity = Vector3(0.0, 0.08, 0.0) # Hovering upward wisp
	p_mat.scale_min = 0.06
	p_mat.scale_max = 0.14
	p_mat.color = Color(0.65, 1.0, 0.35, 0.90) # Luminous yellow-green glow
	_firefly_particles.process_material = p_mat

	var s_mesh: SphereMesh = SphereMesh.new()
	s_mesh.radius = 0.07
	s_mesh.height = 0.14
	var f_mat: StandardMaterial3D = StandardMaterial3D.new()
	f_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	f_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	f_mat.albedo_color = Color(0.70, 1.0, 0.40, 0.90)
	s_mesh.material = f_mat
	_firefly_particles.draw_pass_1 = s_mesh

	add_child(_firefly_particles)

func _build_volumetric_sun_rays() -> void:
	_sun_rays_root = Node3D.new()
	_sun_rays_root.name = "VolumetricSunRays"
	add_child(_sun_rays_root)

	# 4 Angled golden light shafts piercing down over Grand Emerald Lake
	var ray_mat: StandardMaterial3D = StandardMaterial3D.new()
	ray_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ray_mat.albedo_color = Color(1.0, 0.88, 0.60, 0.07) # Soft warm golden haze
	ray_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var ray_coords = [
		Vector3(75.0, 26.0, 65.0),
		Vector3(105.0, 30.0, 95.0),
		Vector3(90.0, 28.0, 115.0),
		Vector3(125.0, 32.0, 75.0)
	]

	for r_pos in ray_coords:
		var ray_mesh: CylinderMesh = CylinderMesh.new()
		ray_mesh.top_radius = 2.4
		ray_mesh.bottom_radius = 8.5
		ray_mesh.height = 36.0
		ray_mesh.radial_segments = 12

		var r_mi: MeshInstance3D = MeshInstance3D.new()
		r_mi.mesh = ray_mesh
		r_mi.material_override = ray_mat
		r_mi.position = r_pos
		r_mi.rotation.x = deg_to_rad(22.0)
		r_mi.rotation.z = deg_to_rad(-14.0)
		_sun_rays_root.add_child(r_mi)
		_ray_mesh_instances.append(r_mi)

func _process(delta: float) -> void:
	_anim_time += delta

	# Track player smoothly
	if _target_player:
		var p_pos: Vector3 = _target_player.global_position if _target_player.is_inside_tree() else _target_player.position
		if _dandelion_particles:
			if _dandelion_particles.is_inside_tree():
				_dandelion_particles.global_position = p_pos + Vector3(0.0, 2.0, 0.0)
			else:
				_dandelion_particles.position = p_pos + Vector3(0.0, 2.0, 0.0)
		if _firefly_particles:
			if _firefly_particles.is_inside_tree():
				_firefly_particles.global_position = p_pos + Vector3(0.0, 1.2, 0.0)
			else:
				_firefly_particles.position = p_pos + Vector3(0.0, 1.2, 0.0)

	# Toggle fireflies vs dandelions based on day/night cycle
	var is_night: bool = false
	if _day_night and _day_night.has_method("is_night"):
		is_night = _day_night.is_night()
	else:
		# Fallback based on time if available
		var hour: float = _day_night.get("current_hour") if (_day_night and "current_hour" in _day_night) else 12.0
		is_night = (hour < 5.5 or hour > 19.5)

	if _firefly_particles:
		_firefly_particles.emitting = is_night
	if _dandelion_particles:
		_dandelion_particles.emitting = not is_night

	# Modulate sun rays opacity with subtle atmospheric breathing
	var ray_alpha: float = 0.06 + sin(_anim_time * 0.8) * 0.015
	if is_night:
		ray_alpha = 0.005 # Almost invisible at night
	for r_mi in _ray_mesh_instances:
		var mat = r_mi.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = ray_alpha
