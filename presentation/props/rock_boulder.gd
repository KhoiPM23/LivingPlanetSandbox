class_name RockBoulder
extends Node3D

## High-fidelity natural rock boulder with organic fissures and geological weathering.
## Uses authentic ambientCG PBR rock assets (RockA, RockB, RockC) with world-triplanar normal mapping.

@export var rock_scale: float = 1.0

static var _cached_scenes: Array[PackedScene] = []
static var _cached_fallback_meshes: Array = []
static var _cached_fallback_mat: StandardMaterial3D = null

static func _init_cache() -> void:
	if not _cached_scenes.is_empty():
		return
	
	for path in [
		"res://demo/assets/models/RockA.tscn",
		"res://demo/assets/models/RockB.tscn",
		"res://demo/assets/models/RockC.tscn"
	]:
		if ResourceLoader.exists(path):
			var scn: PackedScene = load(path)
			if scn:
				_cached_scenes.append(scn)
	
	if not _cached_scenes.is_empty():
		return

	# Secondary fallback: KayKit forest.glb rocks
	if ResourceLoader.exists("res://presentation/assets/models/forest.glb"):
		var gltf: GLTFDocument = GLTFDocument.new()
		var state: GLTFState = GLTFState.new()
		var err: Error = gltf.append_from_file("res://presentation/assets/models/forest.glb", state)
		if err == OK:
			var root: Node = gltf.generate_scene(state)
			if root:
				var rock_names: Array = ["Rock_1_D_Color1", "Rock_1_J_Color1", "Rock_2_C_Color1", "Rock_2_G_Color1", "Rock_3_E_Color1"]
				for rname in rock_names:
					var mi: MeshInstance3D = root.find_child(rname, true, false) as MeshInstance3D
					if mi and mi.mesh:
						_cached_fallback_meshes.append(mi.mesh)
						if _cached_fallback_mat == null and mi.mesh.get_surface_count() > 0:
							var m = mi.mesh.surface_get_material(0)
							if m is StandardMaterial3D:
								_cached_fallback_mat = m
				root.free()

func _ready() -> void:
	_build_rock()

func _build_rock() -> void:
	_init_cache()

	var seed_hash: int = abs(int(position.x * 13.0 + position.z * 19.0))
	var rot_y: float = deg_to_rad(float(seed_hash % 360))
	rotation.y = rot_y

	if not _cached_scenes.is_empty():
		var idx: int = seed_hash % _cached_scenes.size()
		var scn: PackedScene = _cached_scenes[idx]
		var rock_node: Node3D = scn.instantiate() as Node3D
		if rock_node:
			# Scale down from raw 7-10m mesh to natural 1.5-2.5m boulder size
			var s_var: float = 0.25 + 0.08 * float((seed_hash % 100)) / 100.0
			var final_scale: float = s_var * rock_scale
			rock_node.scale = Vector3.ONE * final_scale
			# Slight random tilt for natural bedding
			rock_node.rotation_degrees = Vector3(
				float((seed_hash % 15) - 7),
				0.0,
				float(((seed_hash / 10) % 15) - 7)
			)
			add_child(rock_node)
			return

	if not _cached_fallback_meshes.is_empty():
		scale = Vector3.ONE * rock_scale
		var idx: int = seed_hash % _cached_fallback_meshes.size()
		var mesh: Mesh = _cached_fallback_meshes[idx]
		var inst: MeshInstance3D = MeshInstance3D.new()
		inst.name = "RockModel"
		inst.mesh = mesh
		if _cached_fallback_mat:
			inst.material_override = _cached_fallback_mat
		add_child(inst)
		return

	# Fallback faceted sphere
	scale = Vector3.ONE * rock_scale
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
