class_name RockBoulder
extends Node3D

## Stylized faceted granite boulder with mossy tint.

@export var rock_scale: float = 1.0

func _ready() -> void:
	_build_rock()

func _build_rock() -> void:
	scale = Vector3.ONE * rock_scale
	
	# Faceted sphere
	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = 1.2
	sphere_mesh.height = 1.8
	sphere_mesh.radial_segments = 6
	sphere_mesh.rings = 4
	
	var rock_mat: StandardMaterial3D = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.42, 0.44, 0.46)
	rock_mat.roughness = 0.95
	rock_mat.metallic_specular = 0.05
	
	var inst: MeshInstance3D = MeshInstance3D.new()
	inst.mesh = sphere_mesh
	inst.material_override = rock_mat
	inst.position = Vector3(0.0, 0.6, 0.0)
	inst.rotation_degrees = Vector3(15.0, 30.0, -10.0)
	add_child(inst)
