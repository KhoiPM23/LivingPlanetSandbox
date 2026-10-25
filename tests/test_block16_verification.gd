class_name TestBlock16Verification
extends RefCounted

## Automated verification suite for Block 16 (Environmental Storytelling & World Discovery).
## Runs purely headless with 0% GPU load.

const EnvironmentalStorytelling = preload("res://presentation/environment/environmental_storytelling.gd")
const IslandTerrain = preload("res://presentation/environment/island_terrain.gd")
const WorldEventBus = preload("res://core/events/world_event_bus.gd")

func test_environmental_storytelling_poi_generation() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	var storytelling: EnvironmentalStorytelling = EnvironmentalStorytelling.new()
	storytelling.setup(terrain, null, null, null, 1337)

	if storytelling.get_poi_count() < 4:
		terrain.free()
		storytelling.free()
		return "Expected at least 4 hero narrative POIs, got %d" % storytelling.get_poi_count()

	var required_ids: Array[String] = ["field_camp", "antler_rub", "cove_mooring", "bluff_overlook"]
	for rid in required_ids:
		var poi: Dictionary = storytelling.get_poi_by_id(rid)
		if poi.is_empty():
			terrain.free()
			storytelling.free()
			return "Missing required POI: %s" % rid
		if poi["title"].is_empty():
			terrain.free()
			storytelling.free()
			return "POI %s has empty title" % rid
		if poi["body"].is_empty():
			terrain.free()
			storytelling.free()
			return "POI %s has empty body description" % rid
		if poi["radius"] <= 1.0:
			terrain.free()
			storytelling.free()
			return "POI %s has invalid trigger radius (%.2f)" % [rid, poi["radius"]]

	terrain.free()
	storytelling.free()
	return ""

func test_narrative_poi_grounding_and_collision() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	var storytelling: EnvironmentalStorytelling = EnvironmentalStorytelling.new()
	storytelling.setup(terrain, null, null, null, 1337)

	for poi in storytelling.get_all_pois():
		var pos: Vector3 = poi["position"]
		var terrain_y: float = terrain.get_height_at(pos.x, pos.z)
		# Verify vertical grounding within ±0.3m of terrain height
		if absf(pos.y - terrain_y) > 0.35:
			terrain.free()
			storytelling.free()
			return "POI %s not grounded on terrain: pos.y=%.2f vs terrain_y=%.2f" % [poi["id"], pos.y, terrain_y]

	# Verify StaticBody3D collision nodes exist in the children hierarchy
	var static_bodies: Array[Node] = []
	_collect_nodes_of_type(storytelling, "StaticBody3D", static_bodies)
	if static_bodies.size() < 3:
		terrain.free()
		storytelling.free()
		return "Expected at least 3 static collision bodies on storytelling props, found %d" % static_bodies.size()

	terrain.free()
	storytelling.free()
	return ""

func test_wordless_discovery_engine_proximity_detection() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	# Mock camera node representing player position
	var mock_player: Node3D = Node3D.new()
	mock_player.position = Vector3(50.0, 10.0, 50.0) # Far away initially

	var storytelling: EnvironmentalStorytelling = EnvironmentalStorytelling.new()
	storytelling.setup(terrain, null, mock_player, null, 1337)

	var discovered_ids: Array[String] = []
	storytelling.discovery_unlocked.connect(func(id: String, _t: String, _b: String): discovered_ids.append(id))

	# 1. Update while far away -> no discoveries
	storytelling._process(0.3)
	if storytelling.get_discovered_count() != 0:
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "Discovered POIs prematurely while player was far away"

	# 2. Walk player to POI: Stag Antler Rub (8.5, 2.5)
	var antler_poi: Dictionary = storytelling.get_poi_by_id("antler_rub")
	mock_player.position = antler_poi["position"] + Vector3(0.5, 0.0, 0.5)

	storytelling._process(0.3)

	if storytelling.get_discovered_count() != 1:
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "Expected 1 discovery, got %d" % storytelling.get_discovered_count()

	if not discovered_ids.has("antler_rub"):
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "Expected 'antler_rub' to be unlocked"

	# 3. Walk to POI: Emerald Cove Mooring (13.8, 8.8)
	var cove_poi: Dictionary = storytelling.get_poi_by_id("cove_mooring")
	mock_player.position = cove_poi["position"] + Vector3(0.2, 0.0, 0.2)

	storytelling._process(0.3)

	if storytelling.get_discovered_count() != 2:
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "Expected 2 discoveries, got %d" % storytelling.get_discovered_count()

	terrain.free()
	mock_player.free()
	storytelling.free()
	return ""

func test_event_bus_dispatch() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)
	var bus: WorldEventBus = WorldEventBus.new()

	var events_received: Array[Dictionary] = []
	bus.subscribe("environmental_discovery", func(payload: Dictionary): events_received.append(payload))

	var mock_player: Node3D = Node3D.new()
	var storytelling: EnvironmentalStorytelling = EnvironmentalStorytelling.new()
	storytelling.setup(terrain, bus, mock_player, null, 1337)

	# Walk to Field Camp
	var camp_poi: Dictionary = storytelling.get_poi_by_id("field_camp")
	mock_player.position = camp_poi["position"]
	storytelling._process(0.3)

	if events_received.is_empty():
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "WorldEventBus did not receive 'environmental_discovery' notification"

	var event: Dictionary = events_received[0]
	if event.get("id", "") != "field_camp":
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "Event payload id mismatch (got %s)" % event.get("id", "")

	terrain.free()
	mock_player.free()
	storytelling.free()
	return ""

func test_exploration_journey_from_spawn_to_lake() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	var mock_player: Node3D = Node3D.new()
	var storytelling: EnvironmentalStorytelling = EnvironmentalStorytelling.new()
	storytelling.setup(terrain, null, mock_player, null, 1337)

	# Simulate player stepping along animal trail:
	# Waypoints:
	# 1. Spawn in Meadow: (7.5, Y, 3.5)
	# 2. Trail midpoint: (10.0, Y, 5.5)
	# 3. Cove arrival: (13.8, Y, 8.8)
	var waypoints: Array[Vector3] = [
		Vector3(7.5, terrain.get_height_at(7.5, 3.5), 3.5),
		Vector3(8.5, terrain.get_height_at(8.5, 2.5), 2.5), # Meadow Antler Rub
		Vector3(10.5, terrain.get_height_at(10.5, 5.5), 5.5),
		Vector3(13.8, terrain.get_height_at(13.8, 8.8), 8.8) # Cove Mooring Canoe
	]

	for wp in waypoints:
		mock_player.position = wp
		storytelling._process(0.3)

	# Along this primary route, player should discover at least 2 distinct POIs (Antler Rub and Cove Mooring)
	if storytelling.get_discovered_count() < 2:
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "Natural journey from spawn to lake did not discover expected POIs (discovered: %d)" % storytelling.get_discovered_count()

	terrain.free()
	mock_player.free()
	storytelling.free()
	return ""

func _collect_nodes_of_type(parent: Node, type_name: String, result: Array[Node]) -> void:
	if parent.is_class(type_name) or parent.get_class() == type_name:
		result.append(parent)
	for child in parent.get_children():
		_collect_nodes_of_type(child, type_name, result)
