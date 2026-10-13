class_name TestPlayableWorld
extends RefCounted

## Verification suite for Block 2: First Playable World & Visual Foundation.

func test_terrain_elevation_and_shape() -> bool:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)
	var center_h: float = terrain.get_height_at(0.0, 0.0)
	var edge_h: float = terrain.get_height_at(75.0, 75.0)
	var peak_h: float = terrain.get_height_at(-24.0, -24.0)
	terrain.free()
	return center_h > 0.0 and edge_h < 0.0 and peak_h > center_h

func test_terrain_collision_and_boundaries() -> bool:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)
	var col_shape: CollisionShape3D = terrain.get_node_or_null("TerrainCollisionShape") as CollisionShape3D
	var boundaries: Node3D = terrain.get_node_or_null("WorldBoundaries") as Node3D
	var valid: bool = col_shape != null and col_shape.shape is ConcavePolygonShape3D and boundaries != null and boundaries.get_child_count() == 4
	terrain.free()
	return valid

func test_water_plane_and_shader() -> bool:
	var water: WaterPlane = WaterPlane.new()
	water._ready()
	var valid: bool = water.mesh is PlaneMesh and water.material_override is ShaderMaterial
	water.free()
	return valid

func test_vegetation_scatter_and_instancing() -> bool:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)
	var registry: EntityRegistry = EntityRegistry.new()
	var scatter: VegetationScatter = VegetationScatter.new()
	scatter.scatter(terrain, 1337, registry)
	var landmark: LandmarkMonolith = scatter.get_node_or_null("SummitMonolith") as LandmarkMonolith
	var grass: MultiMeshInstance3D = scatter.get_node_or_null("GrassMultiMesh") as MultiMeshInstance3D
	var valid: bool = landmark != null and grass != null and grass.multimesh.instance_count > 0 and registry.get_count() > 0
	scatter.free()
	terrain.free()
	return valid

func test_terrain_mesh_normals_and_facing() -> bool:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)
	var mesh_inst: MeshInstance3D = terrain.get_node_or_null("TerrainMeshInstance") as MeshInstance3D
	if not mesh_inst or not mesh_inst.mesh is ArrayMesh:
		terrain.free()
		return false
	var arr_mesh: ArrayMesh = mesh_inst.mesh as ArrayMesh
	var arrays: Array = arr_mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	if normals.is_empty():
		terrain.free()
		return false
	var up_count: int = 0
	for n in normals:
		if n.y > 0.0:
			up_count += 1
	var up_ratio: float = float(up_count) / float(normals.size())
	terrain.free()
	return up_ratio > 0.95

