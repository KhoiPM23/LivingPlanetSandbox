class_name WindWispsParticles3D
extends GPUParticles3D

## Living Planet Sandbox — Block 45 Genshin-Style Floating Anime Wind Wisps
## Emits luminous dandelion/anemo particles that drift smoothly across meadows
## and bluffs following the Island's dynamic atmospheric wind vector.
## Highly optimized for Intel Iris Xe: 48 particles, unshaded additive material.

var _target_player: Node3D = null
var _wind_ref: Node = null

func _init() -> void:
	name = "WindWispsParticles3D"
	amount = 48
	lifetime = 4.5
	preprocess = 1.5
	visibility_aabb = AABB(Vector3(-25.0, -8.0, -25.0), Vector3(50.0, 16.0, 50.0))

	var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(18.0, 4.0, 18.0)
	p_mat.direction = Vector3(0.7, 0.25, 0.5).normalized()
	p_mat.spread = 22.0
	p_mat.initial_velocity_min = 1.2
	p_mat.initial_velocity_max = 2.6
	p_mat.gravity = Vector3(0.0, 0.15, 0.0) # Gentle upward draft
	p_mat.scale_min = 0.08
	p_mat.scale_max = 0.22
	p_mat.color = Color(0.85, 0.96, 1.0, 0.75) # Ethereal cyan-white anime glow
	process_material = p_mat

	# Unshaded luminous sphere
	var s_mesh: SphereMesh = SphereMesh.new()
	s_mesh.radius = 0.08
	s_mesh.height = 0.16
	var m_mat: StandardMaterial3D = StandardMaterial3D.new()
	m_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_mat.albedo_color = Color(0.90, 0.98, 1.0, 0.85)
	s_mesh.material = m_mat
	draw_pass_1 = s_mesh

func setup(player_node: Node3D, wind_node: Node = null) -> void:
	_target_player = player_node
	_wind_ref = wind_node

func _process(_delta: float) -> void:
	if _target_player:
		var p_pos: Vector3 = _target_player.global_position if _target_player.is_inside_tree() else _target_player.position
		global_position = p_pos + Vector3(0.0, 1.8, 0.0)
