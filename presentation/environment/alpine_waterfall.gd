class_name AlpineWaterfall
extends Node3D

## High-Altitude Glacial Mountain Cascade & Plunge Pool (Silverveil Glacial Falls).
## Connects the Alpine Tarn lake basin (Y = 36.0m) down through stepped granite gorges
## to the Whispering Grotto canyon valley (Y = 16.8m).
## Features stepped whitewater cascades, churning plunge pool, rock gorge flanks,
## airborne water mist particles, and spatial audio resonance.

const RockBoulder = preload("res://presentation/props/rock_boulder.gd")

@export var falls_start: Vector3 = Vector3(-108.0, 35.8, -98.0)
@export var falls_mid: Vector3 = Vector3(-96.0, 26.5, -88.0)
@export var falls_end: Vector3 = Vector3(-82.0, 16.8, -78.0)
@export var pool_radius: float = 7.5

var _cascade_upper: MeshInstance3D = null
var _cascade_lower: MeshInstance3D = null
var _plunge_pool: MeshInstance3D = null
var _spray_particles: CPUParticles3D = null
var _audio_emitter: AudioStreamPlayer3D = null
var _gorge_rocks: Node3D = null

func _init() -> void:
	name = "AlpineWaterfall"
	_build_gorge_flanks()
	_build_cascades()
	_build_plunge_pool()
	_build_mist_spray_particles()
	_build_spatial_audio()

func _build_gorge_flanks() -> void:
	_gorge_rocks = Node3D.new()
	_gorge_rocks.name = "GorgeFlanks"
	add_child(_gorge_rocks)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6677

	# Flanking granite crags along the descent path
	var gorge_waypoints: Array[Vector3] = [
		Vector3(-109.0, 35.5, -96.0),
		Vector3(-106.0, 35.2, -100.0),
		Vector3(-98.0, 27.0, -86.0),
		Vector3(-94.0, 26.8, -90.0),
		Vector3(-89.0, 21.0, -80.0),
		Vector3(-85.0, 20.5, -84.0),
		Vector3(-80.0, 17.5, -75.0),
		Vector3(-84.0, 17.2, -81.0)
	]

	for i in range(gorge_waypoints.size()):
		var rock_pos: Vector3 = gorge_waypoints[i]
		var boulder: RockBoulder = RockBoulder.new()
		boulder.archetype = RockBoulder.RockArchetype.PROMINENT_CRAG if (i % 2 == 0) else RockBoulder.RockArchetype.TALUS_SCREE
		boulder.rock_scale = rng.randf_range(2.6, 4.4)
		boulder.position = rock_pos
		boulder.rotation = Vector3(rng.randf_range(-0.25, 0.25), rng.randf_range(0.0, TAU), rng.randf_range(-0.25, 0.25))
		_gorge_rocks.add_child(boulder)

func _build_cascades() -> void:
	# Upper Cascade Ribbon (from tarn lip to mid shelf)
	_cascade_upper = _create_cascade_ribbon("CascadeUpper", falls_start, falls_mid, 4.8)
	add_child(_cascade_upper)

	# Lower Cascade Ribbon (from mid shelf to plunge pool)
	_cascade_lower = _create_cascade_ribbon("CascadeLower", falls_mid, falls_end, 5.5)
	add_child(_cascade_lower)

func _create_cascade_ribbon(p_name: String, p_start: Vector3, p_end: Vector3, p_width: float) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = p_name

	var length: float = p_start.distance_to(p_end)
	var quad: BoxMesh = BoxMesh.new()
	quad.size = Vector3(p_width, 0.22, length)
	mi.mesh = quad

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.88, 0.96, 1.0, 0.92)
	mat.roughness = 0.08
	mat.metallic = 0.05
	mat.emission_enabled = true
	mat.emission = Color(0.40, 0.75, 0.90)
	mat.emission_energy_multiplier = 0.65
	mi.material_override = mat

	# Position at midpoint and orient along travel vector
	var mid_pt: Vector3 = (p_start + p_end) * 0.5
	var fwd: Vector3 = (p_end - p_start).normalized()
	if absf(fwd.y) < 0.999:
		mi.transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), mid_pt)
	else:
		mi.position = mid_pt
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

func _build_plunge_pool() -> void:
	_plunge_pool = MeshInstance3D.new()
	_plunge_pool.name = "PlungePool"

	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = pool_radius
	cyl.bottom_radius = pool_radius
	cyl.height = 0.08
	cyl.radial_segments = 32
	_plunge_pool.mesh = cyl

	var water_shader: Shader = preload("res://presentation/shaders/water.gdshader")
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = water_shader
	mat.set_shader_parameter("water_depth_color", Color(0.06, 0.25, 0.35, 0.95))
	mat.set_shader_parameter("water_shallow_color", Color(0.25, 0.65, 0.78, 0.88))
	mat.set_shader_parameter("wave_amplitude", 0.08)
	mat.set_shader_parameter("wave_frequency", 1.2)
	mat.set_shader_parameter("roughness", 0.06)

	_plunge_pool.material_override = mat
	_plunge_pool.position = falls_end + Vector3(0.0, -0.04, 0.0)
	_plunge_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_plunge_pool)

func _build_mist_spray_particles() -> void:
	_spray_particles = CPUParticles3D.new()
	_spray_particles.name = "PlungeMistSpray"
	_spray_particles.amount = 75
	_spray_particles.lifetime = 2.4
	_spray_particles.preprocess = 0.5
	_spray_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_spray_particles.emission_sphere_radius = 5.0
	_spray_particles.direction = Vector3(0.0, 1.0, 0.0)
	_spray_particles.spread = 45.0
	_spray_particles.initial_velocity_min = 2.5
	_spray_particles.initial_velocity_max = 5.0
	_spray_particles.gravity = Vector3(0.0, 0.4, 0.0)

	var p_mesh: QuadMesh = QuadMesh.new()
	p_mesh.size = Vector2(1.2, 1.2)

	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var grad_tex: GradientTexture2D = GradientTexture2D.new()
	grad_tex.width = 64
	grad_tex.height = 64
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)
	grad_tex.gradient = grad

	var p_mat: StandardMaterial3D = StandardMaterial3D.new()
	p_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	p_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	p_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	p_mat.albedo_texture = grad_tex
	p_mat.albedo_color = Color(0.88, 0.95, 1.0, 0.16)
	p_mesh.material = p_mat
	_spray_particles.mesh = p_mesh

	_spray_particles.position = falls_end + Vector3(0.0, 1.2, 0.0)
	add_child(_spray_particles)

func _build_spatial_audio() -> void:
	_audio_emitter = AudioStreamPlayer3D.new()
	_audio_emitter.name = "WaterfallAudioEmitter"
	_audio_emitter.position = falls_mid
	_audio_emitter.unit_size = 8.0
	_audio_emitter.max_distance = 65.0
	_audio_emitter.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_audio_emitter.volume_db = -8.0
	_audio_emitter.bus = "Master"
	add_child(_audio_emitter)

func get_falls_position() -> Vector3:
	return falls_mid

func get_plunge_pool_position() -> Vector3:
	return falls_end
