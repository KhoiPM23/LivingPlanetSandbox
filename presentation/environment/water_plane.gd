class_name WaterPlane
extends MeshInstance3D

## Renders animated Gerstner ocean plane surrounding the island.

@export var water_size: float = 260.0
@export var subdivisions: int = 70
@export var water_shader: Shader = preload("res://presentation/shaders/water.gdshader")

func _ready() -> void:
	_create_water_surface()

func set_water_size(new_size: float, new_subdivisions: int = -1) -> void:
	water_size = new_size
	if new_subdivisions > 0:
		subdivisions = new_subdivisions
	_create_water_surface()

func _create_water_surface() -> void:
	var plane_mesh: PlaneMesh = PlaneMesh.new()
	plane_mesh.size = Vector2(water_size, water_size)
	plane_mesh.subdivide_width = subdivisions
	plane_mesh.subdivide_depth = subdivisions
	
	mesh = plane_mesh
	
	if not material_override:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = water_shader
		material_override = mat
	
	position = Vector3(0.0, 0.0, 0.0) # Waterline at Y = 0
