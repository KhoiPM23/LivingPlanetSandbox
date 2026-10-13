class_name LandmarkMonolith
extends Node3D

## Ancient stone obelisk landmark marking the high peak of the island.

func _ready() -> void:
	_build_monolith()

func _build_monolith() -> void:
	# Monolith base altar
	var base_mesh: BoxMesh = BoxMesh.new()
	base_mesh.size = Vector3(4.0, 0.8, 4.0)
	var stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.28, 0.30, 0.35)
	stone_mat.roughness = 0.85
	
	var base_inst: MeshInstance3D = MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.material_override = stone_mat
	base_inst.position = Vector3(0.0, 0.4, 0.0)
	add_child(base_inst)
	
	# Obelisk Spire
	var spire_mesh: PrismMesh = PrismMesh.new()
	spire_mesh.size = Vector3(2.2, 7.5, 2.2)
	
	var spire_inst: MeshInstance3D = MeshInstance3D.new()
	spire_inst.mesh = spire_mesh
	spire_inst.material_override = stone_mat
	spire_inst.position = Vector3(0.0, 4.5, 0.0)
	add_child(spire_inst)
	
	# Glowing Apex Crystal
	var crystal_mesh: SphereMesh = SphereMesh.new()
	crystal_mesh.radius = 0.45
	crystal_mesh.height = 0.9
	crystal_mesh.radial_segments = 5
	crystal_mesh.rings = 3
	
	var glow_mat: StandardMaterial3D = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.4, 0.85, 1.0)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.2, 0.7, 1.0)
	glow_mat.emission_energy_multiplier = 2.5
	
	var crystal_inst: MeshInstance3D = MeshInstance3D.new()
	crystal_inst.mesh = crystal_mesh
	crystal_inst.material_override = glow_mat
	crystal_inst.position = Vector3(0.0, 8.5, 0.0)
	add_child(crystal_inst)
	
	# OmniLight for nighttime beacon
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(0.3, 0.8, 1.0)
	light.light_energy = 1.8
	light.omni_range = 14.0
	light.position = Vector3(0.0, 8.5, 0.0)
	add_child(light)
