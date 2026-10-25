class_name AlpineTarn
extends Node3D

## High-Altitude Glacial Alpine Tarn nestled within the Skyspire cirque amphitheater.
## Renders a pristine glacial turquoise water disc at Y = 36.0m with soft foam,
## natural granite perimeter boulders, and positional glacial water acoustics.

const RockBoulder = preload("res://presentation/props/rock_boulder.gd")

@export var tarn_position: Vector3 = Vector3(-125.0, 36.0, -110.0)
@export var tarn_radius: float = 22.0

var _water_mesh: MeshInstance3D = null
var _audio_emitter: AudioStreamPlayer3D = null
var _boulder_cluster: Node3D = null

func _init() -> void:
	name = "AlpineTarn"
	position = tarn_position
	_build_tarn_water()
	_build_moraine_boulders()

func _build_tarn_water() -> void:
	_water_mesh = MeshInstance3D.new()
	_water_mesh.name = "TarnWaterPlane"

	# Circular / oval plane mesh for mountain cirque lake
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = tarn_radius
	cylinder.bottom_radius = tarn_radius
	cylinder.height = 0.05
	cylinder.radial_segments = 48
	cylinder.rings = 6

	_water_mesh.mesh = cylinder

	# Glacial crystal-clear turquoise alpine water material
	var water_shader: Shader = preload("res://presentation/shaders/water.gdshader")
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = water_shader
	mat.set_shader_parameter("water_depth_color", Color(0.05, 0.22, 0.32, 0.92))
	mat.set_shader_parameter("water_shallow_color", Color(0.18, 0.58, 0.65, 0.75))
	mat.set_shader_parameter("foam_color", Color(0.92, 0.98, 1.0, 0.85))
	mat.set_shader_parameter("wave_amplitude", 0.04)
	mat.set_shader_parameter("wave_frequency", 0.85)
	mat.set_shader_parameter("roughness", 0.06)

	_water_mesh.material_override = mat
	_water_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water_mesh)

func _build_moraine_boulders() -> void:
	_boulder_cluster = Node3D.new()
	_boulder_cluster.name = "MoraineBoulders"
	add_child(_boulder_cluster)

	# Natural perimeter boulders along the glacial moraine threshold
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7711

	for i in range(16):
		var angle: float = (float(i) / 16.0) * TAU + rng.randf_range(-0.15, 0.15)
		var rad_dist: float = tarn_radius + rng.randf_range(0.5, 4.5)
		var b_pos: Vector3 = Vector3(cos(angle) * rad_dist, rng.randf_range(-0.4, 0.8), sin(angle) * rad_dist)

		var boulder: RockBoulder = RockBoulder.new()
		boulder.archetype = RockBoulder.RockArchetype.TALUS_SCREE
		boulder.rock_scale = rng.randf_range(1.2, 2.6)
		boulder.position = b_pos
		boulder.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.0, TAU), rng.randf_range(-0.2, 0.2))
		_boulder_cluster.add_child(boulder)

func get_water_elevation() -> float:
	return tarn_position.y

func is_point_in_tarn(world_x: float, world_z: float) -> bool:
	var dx: float = world_x - tarn_position.x
	var dz: float = world_z - tarn_position.z
	return (dx * dx + dz * dz) <= (tarn_radius * tarn_radius)
