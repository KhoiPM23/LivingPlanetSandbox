extends RefCounted

func test_spawn_and_retrieve() -> Variant:
	var registry: EntityRegistry = EntityRegistry.new()
	var id: int = registry.spawn_entity("tree", Vector3(1, 2, 3), {"health": 50.0})
	
	if id <= 0:
		return "Invalid entity ID returned: %d" % id
		
	var data: Dictionary = registry.get_entity(id)
	if data.is_empty():
		return "Failed to retrieve spawned entity"
		
	if data["type"] != "tree" or data["position"] != Vector3(1, 2, 3) or not is_equal_approx(data["health"], 50.0):
		return "Entity data mismatch: %s" % str(data)
		
	if registry.get_count() != 1 or registry.get_count_by_type("tree") != 1:
		return "Counts mismatch after spawn"
		
	return null

func test_update_and_despawn() -> Variant:
	var registry: EntityRegistry = EntityRegistry.new()
	var id: int = registry.spawn_entity("deer", Vector3.ZERO)
	
	registry.update_property(id, "health", 75.0)
	var data: Dictionary = registry.get_entity(id)
	if not is_equal_approx(data["health"], 75.0):
		return "Failed to update property"
		
	var removed: bool = registry.despawn_entity(id)
	if not removed:
		return "despawn_entity returned false"
		
	if registry.has_entity(id):
		return "Entity still present after despawn"
		
	if registry.get_count() != 0 or registry.get_count_by_type("deer") != 0:
		return "Counts not zero after despawn"
		
	return null
