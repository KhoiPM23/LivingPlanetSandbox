class_name RockBoulder
extends Node3D

## High-fidelity natural rock boulder with organic fissures and geological weathering.
## Integrates multi-source PBR rock assets (AmbientCG, KayKit, Kenney) with unified World-Triplanar granite PBR mapping.

enum RockArchetype {
	AUTO = 0,
	TALUS_SCREE = 1, # Sharp, angular faceted granite slabs for scree fields & mountain bluffs
	RIVER_STONE = 2, # Water-smoothed rounded boulders for creek bed & shoreline
	PROMINENT_CRAG = 3 # Towering anchor monoliths & meadow crags
}

@export var rock_scale: float = 1.0
@export var archetype: RockArchetype = RockArchetype.AUTO

static var _cached_scenes: Array[PackedScene] = []
static var _cached_granite_meshes: Array[Mesh] = []
static var _cached_cliff_meshes: Array[Mesh] = []
static var _shared_rock_pbr_mat: Material = null

static func _init_cache() -> void:
	if _shared_rock_pbr_mat == null:
		var tp_mat = load("res://demo/assets/materials/M_rock23_tp.tres")
		if tp_mat is Material:
			_shared_rock_pbr_mat = tp_mat
		else:
			var std_mat: StandardMaterial3D = StandardMaterial3D.new()
			var alb = load("res://demo/assets/textures/rock023_alb_ht.png")
			if alb is Texture2D:
				std_mat.albedo_texture = alb
			var nrm = load("res://demo/assets/textures/rock023_nrm_rgh.png")
			if nrm is Texture2D:
				std_mat.normal_enabled = true
				std_mat.normal_texture = nrm
			std_mat.roughness = 0.90
			std_mat.uv1_triplanar = true
			std_mat.uv1_world_triplanar = true
			std_mat.uv1_scale = Vector3(0.35, 0.35, 0.35)
			_shared_rock_pbr_mat = std_mat

	if not _cached_scenes.is_empty() and not _cached_granite_meshes.is_empty():
		return

	# 1. AmbientCG Rounded Boulders (River & Shoreline)
	for path in [
		"res://demo/assets/models/RockA.tscn",
		"res://demo/assets/models/RockB.tscn",
		"res://demo/assets/models/RockC.tscn"
	]:
		if ResourceLoader.exists(path):
			var scn: PackedScene = load(path) as PackedScene
			if scn:
				_cached_scenes.append(scn)

	# 2. KayKit Faceted Granite Slabs (Talus & Scree)
	var f_scn = load("res://presentation/assets/models/forest.glb") as PackedScene
	if f_scn:
		var root: Node = f_scn.instantiate()
		if root:
			var rock_names: Array = ["Rock_1_D_Color1", "Rock_1_J_Color1", "Rock_2_C_Color1", "Rock_2_G_Color1", "Rock_3_E_Color1"]
			for rname in rock_names:
				var mi: MeshInstance3D = root.find_child(rname, true, false) as MeshInstance3D
				if mi and mi.mesh:
					_cached_granite_meshes.append(mi.mesh)
			root.free()

	# 3. Kenney Angular Cliff Crags
	var n_scn = load("res://presentation/assets/models/nature.glb") as PackedScene
	if n_scn:
		var n_root: Node = n_scn.instantiate()
		if n_root:
			for cname in ["rock_largeA", "rock_tallA", "rock_tallC"]:
				var mi: MeshInstance3D = n_root.find_child(cname, true, false) as MeshInstance3D
				if mi and mi.mesh:
					_cached_cliff_meshes.append(mi.mesh)
			n_root.free()

func _ready() -> void:
	_build_rock()

func _build_rock() -> void:
	_init_cache()

	var seed_hash: int = abs(int(position.x * 13.0 + position.z * 19.0))
	rotation.y = deg_to_rad(float(seed_hash % 360))

	# Determine geological archetype
	var effective_archetype: RockArchetype = archetype
	if effective_archetype == RockArchetype.AUTO:
		# Eastern Bluff Talus (X > 18.0, Z > 10.0) -> TALUS_SCREE
		if position.x >= 18.0 and position.z >= 10.0:
			effective_archetype = RockArchetype.TALUS_SCREE
		# Creek bed / shoreline (X between -3.0 and 14.0, Y < 1.5) -> RIVER_STONE
		elif position.y < 1.6 and position.x >= -3.0 and position.x <= 15.0:
			effective_archetype = RockArchetype.RIVER_STONE
		elif rock_scale > 1.6:
			effective_archetype = RockArchetype.PROMINENT_CRAG
		else:
			effective_archetype = RockArchetype.TALUS_SCREE if (seed_hash % 2 == 0) else RockArchetype.RIVER_STONE

	match effective_archetype:
		RockArchetype.TALUS_SCREE:
			# Sharp angular granite boulders
			if not _cached_granite_meshes.is_empty():
				var idx: int = seed_hash % _cached_granite_meshes.size()
				var mesh: Mesh = _cached_granite_meshes[idx]
				var inst: MeshInstance3D = MeshInstance3D.new()
				inst.name = "GraniteTalusModel"
				inst.mesh = mesh
				inst.material_override = _shared_rock_pbr_mat
				# Natural bedding scale (1.2 to 2.4m)
				var s: float = (1.1 + 0.15 * float(seed_hash % 10)) * rock_scale
				inst.scale = Vector3.ONE * s
				# Angular geological bedding tilt
				inst.rotation_degrees = Vector3(
					float((seed_hash % 20) - 10),
					0.0,
					float(((seed_hash / 10) % 20) - 10)
				)
				inst.visibility_range_end = 120.0
				inst.visibility_range_end_margin = 15.0
				inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				add_child(inst)
				return

		RockArchetype.PROMINENT_CRAG:
			# Towering crag monoliths
			if not _cached_cliff_meshes.is_empty():
				var idx: int = seed_hash % _cached_cliff_meshes.size()
				var mesh: Mesh = _cached_cliff_meshes[idx]
				var inst: MeshInstance3D = MeshInstance3D.new()
				inst.name = "ProminentCragModel"
				inst.mesh = mesh
				inst.material_override = _shared_rock_pbr_mat
				var s: float = (1.3 + 0.18 * float(seed_hash % 10)) * rock_scale
				inst.scale = Vector3.ONE * s
				inst.visibility_range_end = 135.0
				inst.visibility_range_end_margin = 15.0
				inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				add_child(inst)
				return

		RockArchetype.RIVER_STONE:
			# Water-smoothed river boulders
			if not _cached_scenes.is_empty():
				var idx: int = seed_hash % _cached_scenes.size()
				var scn: PackedScene = _cached_scenes[idx]
				var rock_node: Node3D = scn.instantiate() as Node3D
				if rock_node:
					var s_var: float = 0.25 + 0.08 * float((seed_hash % 100)) / 100.0
					rock_node.scale = Vector3.ONE * (s_var * rock_scale)
					rock_node.rotation_degrees = Vector3(
						float((seed_hash % 12) - 6),
						0.0,
						float(((seed_hash / 10) % 12) - 6)
					)
					for child in rock_node.get_children():
						if child is GeometryInstance3D:
							child.material_override = _shared_rock_pbr_mat
							child.visibility_range_end = 115.0
							child.visibility_range_end_margin = 15.0
							child.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
					add_child(rock_node)
					return

	# Fallback faceted rock instance
	var inst: MeshInstance3D = MeshInstance3D.new()
	inst.name = "RockFallback"
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.2 * rock_scale
	sphere.height = 1.8 * rock_scale
	sphere.radial_segments = 6
	sphere.rings = 4
	inst.mesh = sphere
	inst.material_override = _shared_rock_pbr_mat
	add_child(inst)
