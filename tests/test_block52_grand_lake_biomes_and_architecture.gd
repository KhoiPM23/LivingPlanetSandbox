class_name TestBlock52GrandLakeBiomesAndArchitecture
extends RefCounted

## Living Planet Sandbox — Block 52 Automated Test Suite
## Validates:
## 1. Grand Emerald Lake 140m Expansion & Central Heart Island bathymetry
## 2. Windshear Canyon Gorge depth & cliffside drop
## 3. GrandEmeraldLakeFeatures: Arch Bridge, Anemo Sanctuary, Boathouse Pier & Cascade Waterfall
## 4. WorldLandmarksExpansion: Great Highland Windmill, Farmstead, Suspension Bridge & Watchtower
## 5. MedievalHavenVillage: Harbor Fishery Warehouse & Hillside Suburban Cottage

const LakeFeaturesScript = preload("res://presentation/environment/grand_emerald_lake_features.gd")
const LandmarksScript = preload("res://presentation/environment/world_landmarks_expansion.gd")
const VillageScript = preload("res://presentation/environment/medieval_haven_village.gd")

func test_grand_emerald_lake_expansion_and_island_bathymetry() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.island_size = 720.0
	terrain.generate_island(1337)

	# 1. Heart Island (Đảo Thần Gió) at center (95.0, 85.0) must rise safely above waterline Y=0.0
	var island_h: float = terrain.get_height_at(95.0, 85.0)
	if island_h < 1.8:
		terrain.free()
		return "Expected Heart Island at (95, 85) to rise >= 1.8m above water, got %.2fm" % island_h

	# 2. Deep lake channel surrounding the island (radius 45m from center -> (95, 40)) must be submerged (< -1.0m)
	var channel_h: float = terrain.get_height_at(95.0, 40.0)
	if channel_h >= 0.0:
		terrain.free()
		return "Expected deep lake channel at (95, 40) to sit below waterline (< 0.0m), got %.2fm" % channel_h

	# 3. Outer lake basin (radius 100m -> (95, 185)) must be lower than surrounding highland ridges
	var outer_h: float = terrain.get_height_at(95.0, 180.0)
	var ridge_h: float = terrain.get_height_at(180.0, -25.0) # Highland ridge
	if outer_h >= ridge_h:
		terrain.free()
		return "Expected outer lake basin (%.2fm) to sit lower than highland ridge (%.2fm)" % [outer_h, ridge_h]

	terrain.free()
	return ""

func test_windshear_canyon_gorge_depth() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.island_size = 720.0
	terrain.generate_island(1337)

	# Canyon floor at X=-35.0, Z=145.0
	var floor_h: float = terrain.get_height_at(-35.0, 145.0)
	# Canyon cliff rims at X=-50.0 and X=-20.0
	var rim_west: float = terrain.get_height_at(-50.0, 145.0)
	var rim_east: float = terrain.get_height_at(-20.0, 145.0)

	var drop_w: float = rim_west - floor_h
	var drop_e: float = rim_east - floor_h

	if drop_w < 3.0 or drop_e < 3.0:
		terrain.free()
		return "Expected Windshear Canyon drop to exceed 3.0m (west drop: %.2fm, east drop: %.2fm)" % [drop_w, drop_e]

	terrain.free()
	return ""

func test_grand_emerald_lake_features_hierarchy() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.island_size = 720.0

	var lake_feats: Node3D = LakeFeaturesScript.new()
	lake_feats.setup(terrain, null)

	# 1. Ancient Jade Arch Bridge
	var bridge = lake_feats.get_node_or_null("AncientJadeArchBridge")
	if not bridge:
		lake_feats.free()
		terrain.free()
		return "Expected AncientJadeArchBridge node to exist in LakeFeatures"

	var bridge_col = bridge.get_node_or_null("BridgeCollision")
	if not bridge_col or not (bridge_col is StaticBody3D):
		lake_feats.free()
		terrain.free()
		return "Expected StaticBody3D BridgeCollision for player traversal across arch bridge"

	# 2. Anemo Sanctuary Pavilion
	var pav = lake_feats.get_node_or_null("AnemoSanctuaryPavilion")
	if not pav:
		lake_feats.free()
		terrain.free()
		return "Expected AnemoSanctuaryPavilion node to exist in LakeFeatures"

	var relic_core = pav.get_node_or_null("AnemoRelicCore")
	if not relic_core:
		lake_feats.free()
		terrain.free()
		return "Expected AnemoRelicCore in AnemoSanctuaryPavilion"

	# 3. Lakeside Boathouse and Pier
	var boathouse = lake_feats.get_node_or_null("LakesideBoathouseAndPier")
	if not boathouse:
		lake_feats.free()
		terrain.free()
		return "Expected LakesideBoathouseAndPier node to exist in LakeFeatures"

	# 4. Emerald Cascade Waterfall
	var waterfall = lake_feats.get_node_or_null("EmeraldCascadeWaterfall")
	if not waterfall:
		lake_feats.free()
		terrain.free()
		return "Expected EmeraldCascadeWaterfall node to exist in LakeFeatures"

	# 5. Process test (rotation animation)
	lake_feats._process(0.016)
	if is_zero_approx(lake_feats._anim_time):
		lake_feats.free()
		terrain.free()
		return "Expected lake_feats._anim_time to increment during _process"

	lake_feats.free()
	terrain.free()
	return ""

func test_world_landmarks_expansion_hierarchy() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.island_size = 720.0

	var landmarks: Node3D = LandmarksScript.new()
	landmarks.setup(terrain, null)

	# 1. The Great Highland Windmill
	var windmill = landmarks.get_node_or_null("TheGreatHighlandWindmill")
	if not windmill:
		landmarks.free()
		terrain.free()
		return "Expected TheGreatHighlandWindmill to exist in WorldLandmarks"

	var hub = windmill.get_node_or_null("WindmillBladesHub")
	if not hub:
		landmarks.free()
		terrain.free()
		return "Expected WindmillBladesHub in TheGreatHighlandWindmill"

	# 2. Highland Farmstead
	var farm = landmarks.get_node_or_null("HighlandFarmstead")
	if not farm:
		landmarks.free()
		terrain.free()
		return "Expected HighlandFarmstead to exist in WorldLandmarks"

	# 3. Windshear Suspension Bridge
	var bridge = landmarks.get_node_or_null("WindshearSuspensionBridge")
	if not bridge:
		landmarks.free()
		terrain.free()
		return "Expected WindshearSuspensionBridge to exist in WorldLandmarks"

	# 4. Cape Lookout Watchtower
	var watchtower = landmarks.get_node_or_null("CapeLookoutWatchtower")
	if not watchtower:
		landmarks.free()
		terrain.free()
		return "Expected CapeLookoutWatchtower to exist in WorldLandmarks"

	# 5. Ancient Ruined Colonnade
	var colonnade = landmarks.get_node_or_null("AncientRuinedColonnade")
	if not colonnade:
		landmarks.free()
		terrain.free()
		return "Expected AncientRuinedColonnade to exist in WorldLandmarks"

	# 6. Windmill blade rotation during _process
	var initial_rot_z: float = hub.rotation.z
	landmarks._process(0.1)
	if is_equal_approx(hub.rotation.z, initial_rot_z):
		landmarks.free()
		terrain.free()
		return "Expected Windmill blade hub to rotate during _process"

	landmarks.free()
	terrain.free()
	return ""

func test_haven_village_expanded_buildings() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.island_size = 720.0

	var village: Node3D = VillageScript.new()
	village.setup(terrain, null)

	var warehouse = village.get_node_or_null("HarborFisheryWarehouse")
	if not warehouse:
		village.free()
		terrain.free()
		return "Expected HarborFisheryWarehouse to be built in Haven Village"

	var cottage = village.get_node_or_null("HillsideSuburbanCottage")
	if not cottage:
		village.free()
		terrain.free()
		return "Expected HillsideSuburbanCottage to be built in Haven Village"

	village.free()
	terrain.free()
	return ""
