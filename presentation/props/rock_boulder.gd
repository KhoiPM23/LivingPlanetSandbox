class_name RockBoulder
extends Node3D

## High-fidelity natural rock boulder with organic fissures and geological weathering.
## Sourced from CC0 KayKit Forest Pack.

@export var rock_scale: float = 1.0

static var _cached_rock_meshes: Array = []
static var _cached_rock_mat: StandardMaterial3D = null

static func _init_cache() -> void:
	if not _cached_rock_meshes.is_empty():
		return
	var gltf: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	var err: Error = gltf.append_from_file("res://presentation/assets/models/forest.glb", state)
	if err != OK:
		return
	var root: Node = gltf.generate_scene(state)
	if not root:
		return

	var rock_names: Array = ["Rock_1_D_Color1", "Rock_1_J_Color1", "Rock_2_C_Color1", "Rock_2_G_Color1", "Rock_3_E_Color1"]
	for rname in rock_names:
		var mi: MeshInstance3D = root.find_child(rname, true, false) as MeshInstance3D
		if mi and mi.mesh:
			_cached_rock_meshes.append(mi.mesh)
			if _cached_rock_mat == null and mi.mesh.get_surface_count() > 0:
				var m = mi.mesh.surface_get_material(0)
				if m is StandardMaterial3D:
					_cached_rock_mat = m

	root.free()

func _ready() -> void:
	_build_rock()

func _build_rock() -> void:
	scale = Vector3.ONE * rock_scale
	_init_cache()

	if not _cached_rock_meshes.is_empty():
		var idx: int = abs(int(position.x * 11.0 + position.z * 17.0)) % _cached_rock_meshes.size()
		var mesh: Mesh = _cached_rock_meshes[idx]

		var inst: MeshInstance3D = MeshInstance3D.new()
		inst.name = "RockModel"
		inst.mesh = mesh
		if _cached_rock_mat:
			inst.material_override = _cached_rock_mat
		add_child(inst)
		return

	# Fallback faceted sphere
	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = 1.2
	sphere_mesh.height = 1.8
	sphere_mesh.radial_segments = 6
	sphere_mesh.rings = 4

	var rock_mat: StandardMaterial3D = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.42, 0.44, 0.46)
	rock_mat.roughness = 0.95
	rock_mat.metallic_specular = 0.05

	var inst_fb: MeshInstance3D = MeshInstance3D.new()
	inst_fb.mesh = sphere_mesh
	inst_fb.material_override = rock_mat
	inst_fb.position = Vector3(0.0, 0.6, 0.0)
	inst_fb.rotation_degrees = Vector3(15.0, 30.0, -10.0)
	add_child(inst_fb)
