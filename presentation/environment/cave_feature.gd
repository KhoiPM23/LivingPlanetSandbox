class_name CaveFeature
extends Node3D

## High-Fidelity Traversable Cavern & Rock Grotto (Whispering Grotto).
## Assembles a subterranean natural cathedral from monolithic granite boulders,
## with a vaulted stone ceiling, natural oculus sunbeam, stalactites,
## bioluminescent crystal glow, and an echoing subterranean crystal pool.

const RockBoulder = preload("res://presentation/props/rock_boulder.gd")

@export var grotto_center: Vector3 = Vector3(-78.0, 16.5, -72.0)
@export var cavern_radius: float = 14.0

var _arch_pillars: Node3D = null
var _crystal_lights: Array[OmniLight3D] = []
var _subterranean_pool: MeshInstance3D = null
var _audio_emitter: AudioStreamPlayer3D = null
var _spore_particles: CPUParticles3D = null
var _drip_particles: CPUParticles3D = null

func _init() -> void:
	name = "WhisperingGrotto"
	position = grotto_center
	_build_vaulted_ceiling()
	_build_stalactites_and_stalagmites()
	_build_bioluminescent_crystals()
	_build_subterranean_pool()
	_build_bioluminescent_spores()
	_build_stalactite_drips()
	_build_grotto_acoustics()
	_build_grand_entrance_portal()

func _ready() -> void:
	var terrain: IslandTerrain = null
	if get_parent():
		terrain = get_parent().get_node_or_null("IslandTerrain") as IslandTerrain
	if terrain:
		var ground_h: float = terrain.get_height_at(position.x, position.z)
		position.y = ground_h
		var portal: Node3D = get_node_or_null("CavernEntrancePortal") as Node3D
		if portal:
			var p_ground: float = terrain.get_height_at(position.x, position.z + 13.5)
			portal.position.y = p_ground - ground_h

func _build_vaulted_ceiling() -> void:
	_arch_pillars = Node3D.new()
	_arch_pillars.name = "VaultedCeilingArches"
	add_child(_arch_pillars)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9988

	# Ring of massive inward-slanting granite monolithic crags forming vaulted walls and roof
	var num_vault_arches: int = 14
	for i in range(num_vault_arches):
		var angle: float = (float(i) / float(num_vault_arches)) * TAU
		# Leave wide southern entrance open for seamless player entry from meadow
		if angle > 0.35 * PI and angle < 0.65 * PI:
			continue

		var r_dist: float = cavern_radius * rng.randf_range(0.92, 1.12)
		var arch_pos: Vector3 = Vector3(cos(angle) * r_dist, 0.0, sin(angle) * r_dist)

		# Wall pillar
		var pillar: RockBoulder = RockBoulder.new()
		pillar.archetype = RockBoulder.RockArchetype.PROMINENT_CRAG
		pillar.rock_scale = rng.randf_range(2.8, 4.2)
		pillar.position = arch_pos
		# Slant inward towards cavern center
		var inward_tilt_x: float = -cos(angle) * 0.35
		var inward_tilt_z: float = -sin(angle) * 0.35
		pillar.rotation = Vector3(inward_tilt_x, angle + PI * 0.5, inward_tilt_z)
		_arch_pillars.add_child(pillar)

		# Overhead ceiling cap boulder bridging towards oculus
		if i % 2 == 0:
			var cap: RockBoulder = RockBoulder.new()
			cap.archetype = RockBoulder.RockArchetype.TALUS_SCREE
			cap.rock_scale = rng.randf_range(2.5, 3.8)
			cap.position = arch_pos * 0.55 + Vector3(0.0, 7.5 + rng.randf_range(-0.5, 0.8), 0.0)
			cap.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.0, TAU), rng.randf_range(-0.3, 0.3))
			_arch_pillars.add_child(cap)

func _build_stalactites_and_stalagmites() -> void:
	var decor_group: Node3D = Node3D.new()
	decor_group.name = "Speleothems"
	add_child(decor_group)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4455

	# Hanging stalactites
	for i in range(8):
		var ang: float = rng.randf_range(0.0, TAU)
		var rad: float = rng.randf_range(3.0, 9.5)
		var stala_pos: Vector3 = Vector3(cos(ang) * rad, 7.8, sin(ang) * rad)

		var cone: MeshInstance3D = MeshInstance3D.new()
		var c_mesh: CylinderMesh = CylinderMesh.new()
		c_mesh.top_radius = 0.02
		c_mesh.bottom_radius = rng.randf_range(0.25, 0.45)
		c_mesh.height = rng.randf_range(1.6, 3.2)
		cone.mesh = c_mesh

		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.32, 0.30, 0.28)
		mat.roughness = 0.35 # Wet mineral sheen
		mat.metallic = 0.05
		cone.material_override = mat

		# Invert to hang downwards
		cone.position = stala_pos - Vector3(0.0, c_mesh.height * 0.5, 0.0)
		cone.rotation = Vector3(PI, 0.0, rng.randf_range(-0.1, 0.1))
		decor_group.add_child(cone)

	# Rising floor stalagmites
	for i in range(7):
		var ang: float = rng.randf_range(0.0, TAU)
		var rad: float = rng.randf_range(4.5, 11.0)
		var stala_pos: Vector3 = Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)

		var cone: MeshInstance3D = MeshInstance3D.new()
		var c_mesh: CylinderMesh = CylinderMesh.new()
		c_mesh.top_radius = 0.03
		c_mesh.bottom_radius = rng.randf_range(0.3, 0.6)
		c_mesh.height = rng.randf_range(1.2, 2.4)
		cone.mesh = c_mesh

		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.34, 0.32, 0.30)
		mat.roughness = 0.40
		cone.material_override = mat

		cone.position = stala_pos + Vector3(0.0, c_mesh.height * 0.5, 0.0)
		decor_group.add_child(cone)

func _build_bioluminescent_crystals() -> void:
	var crystal_group: Node3D = Node3D.new()
	crystal_group.name = "BioluminescentCrystals"
	add_child(crystal_group)

	var crystal_positions: Array[Vector3] = [
		Vector3(-6.5, 1.2, -4.5),
		Vector3(7.2, 1.4, 3.8),
		Vector3(-3.2, 0.8, 7.5),
		Vector3(4.8, 1.0, -6.8)
	]

	for i in range(crystal_positions.size()):
		var c_pos: Vector3 = crystal_positions[i]

		# Faceted crystal mesh
		var c_mesh_inst: MeshInstance3D = MeshInstance3D.new()
		var prism: PrismMesh = PrismMesh.new()
		prism.size = Vector3(0.45, 1.8, 0.45)
		c_mesh_inst.mesh = prism

		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.20, 0.95, 0.85, 0.92)
		mat.emission_enabled = true
		mat.emission = Color(0.15, 0.88, 0.82)
		mat.emission_energy_multiplier = 3.8
		mat.roughness = 0.15
		mat.refraction_enabled = true
		c_mesh_inst.material_override = mat

		c_mesh_inst.position = c_pos
		c_mesh_inst.rotation = Vector3(0.18 * float(i), 0.45 * float(i), -0.15 * float(i))
		crystal_group.add_child(c_mesh_inst)

		# Ambient soft glow omni light
		var light: OmniLight3D = OmniLight3D.new()
		light.name = "CrystalLight_%d" % i
		light.light_color = Color(0.25, 0.94, 0.88)
		light.light_energy = 2.2
		light.omni_range = 14.0
		light.omni_attenuation = 1.0
		light.shadow_enabled = false
		light.position = c_pos + Vector3(0.0, 0.6, 0.0)
		crystal_group.add_child(light)
		_crystal_lights.append(light)

func _build_subterranean_pool() -> void:
	_subterranean_pool = MeshInstance3D.new()
	_subterranean_pool.name = "SubterraneanPool"

	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 5.8
	cylinder.bottom_radius = 5.8
	cylinder.height = 0.04
	cylinder.radial_segments = 32
	_subterranean_pool.mesh = cylinder

	var water_shader: Shader = preload("res://presentation/shaders/water.gdshader")
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = water_shader
	mat.set_shader_parameter("water_depth_color", Color(0.04, 0.18, 0.24, 0.94))
	mat.set_shader_parameter("water_shallow_color", Color(0.12, 0.44, 0.48, 0.80))
	mat.set_shader_parameter("wave_amplitude", 0.015)
	mat.set_shader_parameter("wave_frequency", 0.40)
	mat.set_shader_parameter("roughness", 0.04)

	_subterranean_pool.material_override = mat
	_subterranean_pool.position = Vector3(0.0, -0.05, 0.0)
	_subterranean_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_subterranean_pool)

func _build_bioluminescent_spores() -> void:
	_spore_particles = CPUParticles3D.new()
	_spore_particles.name = "CavernSporeMotes"
	_spore_particles.amount = 45
	_spore_particles.lifetime = 4.5
	_spore_particles.preprocess = 0.8
	_spore_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_spore_particles.emission_sphere_radius = 8.5
	_spore_particles.direction = Vector3(0.0, 1.0, 0.0)
	_spore_particles.spread = 180.0
	_spore_particles.initial_velocity_min = 0.15
	_spore_particles.initial_velocity_max = 0.45
	_spore_particles.gravity = Vector3(0.0, -0.04, 0.0)

	var s_mesh: SphereMesh = SphereMesh.new()
	s_mesh.radius = 0.06
	s_mesh.height = 0.12

	var s_mat: StandardMaterial3D = StandardMaterial3D.new()
	s_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	s_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	s_mat.albedo_color = Color(0.20, 0.95, 0.88, 0.65)
	s_mesh.material = s_mat
	_spore_particles.mesh = s_mesh
	_spore_particles.position = Vector3(0.0, 3.5, 0.0)
	add_child(_spore_particles)

func _build_stalactite_drips() -> void:
	_drip_particles = CPUParticles3D.new()
	_drip_particles.name = "StalactiteDrips"
	_drip_particles.amount = 16
	_drip_particles.lifetime = 1.4
	_drip_particles.preprocess = 0.3
	_drip_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_drip_particles.emission_box_extents = Vector3(5.5, 0.2, 5.5)
	_drip_particles.direction = Vector3(0.0, -1.0, 0.0)
	_drip_particles.spread = 3.0
	_drip_particles.initial_velocity_min = 2.0
	_drip_particles.initial_velocity_max = 3.8
	_drip_particles.gravity = Vector3(0.0, -9.8, 0.0)

	var d_mesh: BoxMesh = BoxMesh.new()
	d_mesh.size = Vector3(0.025, 0.14, 0.025)

	var d_mat: StandardMaterial3D = StandardMaterial3D.new()
	d_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	d_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	d_mat.albedo_color = Color(0.70, 0.88, 0.96, 0.55)
	d_mesh.material = d_mat
	_drip_particles.mesh = d_mesh
	_drip_particles.position = Vector3(0.0, 7.2, 0.0)
	add_child(_drip_particles)

func _build_grotto_acoustics() -> void:
	_audio_emitter = AudioStreamPlayer3D.new()
	_audio_emitter.name = "CavernAudioEmitter"
	_audio_emitter.unit_size = 6.0
	_audio_emitter.max_distance = 28.0
	_audio_emitter.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_audio_emitter.volume_db = -12.0
	_audio_emitter.bus = "Master"
	add_child(_audio_emitter)

func get_grotto_center() -> Vector3:
	return grotto_center

func is_player_inside(pos: Vector3) -> bool:
	var d: Vector2 = Vector2(pos.x - grotto_center.x, pos.z - grotto_center.z)
	return d.length() < cavern_radius and pos.y >= (grotto_center.y - 1.0) and pos.y <= (grotto_center.y + 9.0)

func _build_grand_entrance_portal() -> void:
	var portal_root: Node3D = Node3D.new()
	portal_root.name = "CavernEntrancePortal"
	add_child(portal_root)

	# 1. Flanking Grand Entrance Monoliths facing South (+Z) towards meadow glade
	var left_pillar: RockBoulder = RockBoulder.new()
	left_pillar.archetype = RockBoulder.RockArchetype.PROMINENT_CRAG
	left_pillar.rock_scale = 4.2
	left_pillar.position = Vector3(-5.5, 0.0, 13.5)
	left_pillar.rotation = Vector3(0.08, 0.35, -0.05)
	portal_root.add_child(left_pillar)

	var right_pillar: RockBoulder = RockBoulder.new()
	right_pillar.archetype = RockBoulder.RockArchetype.PROMINENT_CRAG
	right_pillar.rock_scale = 4.2
	right_pillar.position = Vector3(5.5, 0.0, 13.5)
	right_pillar.rotation = Vector3(0.08, -0.35, 0.05)
	portal_root.add_child(right_pillar)

	# 2. Overarching Stone Lintel Arch
	var lintel: RockBoulder = RockBoulder.new()
	lintel.archetype = RockBoulder.RockArchetype.TALUS_SCREE
	lintel.rock_scale = 4.0
	lintel.position = Vector3(0.0, 7.5, 13.5)
	lintel.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)
	portal_root.add_child(lintel)

	# 3. Flanking Flame Braziers for Far-Distance Night and Dusk Visibility
	for b_idx in [-1, 1]:
		var b_x: float = float(b_idx) * 4.6
		var brazier_root: Node3D = Node3D.new()
		brazier_root.name = "EntranceBrazier_%d" % b_idx
		brazier_root.position = Vector3(b_x, 0.0, 14.8)
		portal_root.add_child(brazier_root)

		# Stone pedestal
		var ped: MeshInstance3D = MeshInstance3D.new()
		var p_cyl: CylinderMesh = CylinderMesh.new()
		p_cyl.top_radius = 0.32
		p_cyl.bottom_radius = 0.42
		p_cyl.height = 1.35
		ped.mesh = p_cyl
		var p_mat: StandardMaterial3D = StandardMaterial3D.new()
		p_mat.albedo_color = Color(0.25, 0.23, 0.22)
		p_mat.roughness = 0.90
		ped.material_override = p_mat
		ped.position = Vector3(0.0, 0.675, 0.0)
		brazier_root.add_child(ped)

		# Flaming ember bowl
		var bowl: MeshInstance3D = MeshInstance3D.new()
		var b_mesh: CylinderMesh = CylinderMesh.new()
		b_mesh.top_radius = 0.45
		b_mesh.bottom_radius = 0.28
		b_mesh.height = 0.35
		bowl.mesh = b_mesh
		var b_mat: StandardMaterial3D = StandardMaterial3D.new()
		b_mat.albedo_color = Color(1.0, 0.45, 0.12)
		b_mat.emission_enabled = true
		b_mat.emission = Color(1.0, 0.42, 0.08)
		b_mat.emission_energy_multiplier = 3.2
		bowl.material_override = b_mat
		bowl.position = Vector3(0.0, 1.45, 0.0)
		brazier_root.add_child(bowl)

		# Warm flickering torch light
		var b_light: OmniLight3D = OmniLight3D.new()
		b_light.light_color = Color(1.0, 0.60, 0.22)
		b_light.light_energy = 2.4
		b_light.omni_range = 14.0
		b_light.position = Vector3(0.0, 1.8, 0.0)
		brazier_root.add_child(b_light)

	# 4. Entrance Floating 3D Title Sign
	var sign_lbl: Label3D = Label3D.new()
	sign_lbl.name = "CavernSign"
	sign_lbl.text = "💎 HANG ĐỘNG HUYỀN BÍ (WHISPERING GROTTO)"
	sign_lbl.font_size = 22
	sign_lbl.modulate = Color(0.35, 0.95, 0.90)
	sign_lbl.outline_modulate = Color(0.04, 0.08, 0.12, 0.95)
	sign_lbl.outline_size = 6
	sign_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_lbl.position = Vector3(0.0, 5.2, 14.0)
	portal_root.add_child(sign_lbl)

	# 5. Stepping Stone Entry Pathway
	for step_i in range(5):
		var step_mesh: MeshInstance3D = MeshInstance3D.new()
		var s_box: BoxMesh = BoxMesh.new()
		s_box.size = Vector3(1.6, 0.15, 1.2)
		step_mesh.mesh = s_box
		var s_mat: StandardMaterial3D = StandardMaterial3D.new()
		s_mat.albedo_color = Color(0.38, 0.36, 0.34)
		s_mat.roughness = 0.88
		step_mesh.material_override = s_mat
		var z_step: float = 14.0 + float(step_i) * 1.3
		step_mesh.position = Vector3(sin(float(step_i) * 0.8) * 0.35, 0.08, z_step)
		portal_root.add_child(step_mesh)
