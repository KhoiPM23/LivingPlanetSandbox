class_name TestBlock53LivingWorldAtmosphereAndExploration
extends RefCounted

## Living Planet Sandbox — Block 53 Automated Regression Test Suite
## Validates Magical Atmosphere Director, Highland Sheep & Mallard Ducks,
## Exploration Treasure Chests, Anemo Monument, and Circular Minimap Radar HUD.

const MagicalAtmosphereDirectorScript = preload("res://presentation/environment/magical_atmosphere_director.gd")
const ExplorationChestSystemScript = preload("res://presentation/environment/exploration_chest_system.gd")
const CircularMinimapHUDScript = preload("res://presentation/ui/circular_minimap_hud.gd")
const HighlandSheepScript = preload("res://presentation/props/highland_sheep.gd")
const LakeMallardDuckScript = preload("res://presentation/props/lake_mallard_duck.gd")

func test_magical_atmosphere_director_particles_and_sun_rays() -> String:
	var director = MagicalAtmosphereDirectorScript.new()
	if director == null:
		return "Failed to instantiate MagicalAtmosphereDirector"

	var dandelion = director.get_node_or_null("DandelionPetalParticles")
	if dandelion == null:
		return "Missing DandelionPetalParticles node"
	if not (dandelion is GPUParticles3D):
		return "DandelionPetalParticles is not GPUParticles3D"

	var fireflies = director.get_node_or_null("NocturnalFireflies")
	if fireflies == null:
		return "Missing NocturnalFireflies node"
	if not (fireflies is GPUParticles3D):
		return "NocturnalFireflies is not GPUParticles3D"

	var sun_rays = director.get_node_or_null("VolumetricSunRays")
	if sun_rays == null:
		return "Missing VolumetricSunRays node"
	if director._ray_mesh_instances.size() != 4:
		return "Expected 4 volumetric sun ray light shafts, got %d" % director._ray_mesh_instances.size()

	# Test Day/Night state switching
	var mock_dn = MockDayNightCycle.new()
	var dummy_player = Node3D.new()

	director.setup(dummy_player, mock_dn)
	mock_dn.night = false # Daytime
	director._process(0.1)

	if not dandelion.emitting:
		return "Dandelions should emit during daytime"
	if fireflies.emitting:
		return "Fireflies should be inactive during daytime"

	mock_dn.night = true # Nighttime
	director._process(0.1)

	if dandelion.emitting:
		return "Dandelions should be inactive during nighttime"
	if not fireflies.emitting:
		return "Fireflies should emit during nighttime"

	director.free()
	dummy_player.free()
	mock_dn.free()
	return ""

func test_highland_sheep_behavior_and_petting() -> String:
	var sheep = HighlandSheepScript.new()
	if sheep == null:
		return "Failed to instantiate HighlandSheep"

	if sheep._body_mesh == null:
		return "HighlandSheep missing _body_mesh"
	if sheep._head_root == null:
		return "HighlandSheep missing _head_root"
	if sheep._legs.size() != 4:
		return "HighlandSheep expected 4 legs, got %d" % sheep._legs.size()
	if sheep._tail_mesh == null:
		return "HighlandSheep missing _tail_mesh"
	if sheep._heart_particles == null:
		return "HighlandSheep missing _heart_particles"
	if sheep._audio_player == null:
		return "HighlandSheep missing _audio_player"
	if sheep._baa_wav == null or sheep._baa_wav.data.is_empty():
		return "HighlandSheep procedural baa WAV audio stream is empty"

	# Test petting interaction
	var petted: Array = [false]
	sheep.sheep_petted.connect(func(): petted[0] = true)
	sheep.pet_sheep()

	if not petted[0]:
		return "sheep_petted signal was not emitted"
	if sheep.current_state != HighlandSheepScript.SheepState.HAPPY_PET:
		return "Sheep state did not transition to HAPPY_PET on petting"
	if sheep._pet_time <= 0.0:
		return "Sheep pet_time was not set"

	# Simulate process tick
	sheep.update_behavior(0.1, Vector3.ZERO)

	sheep.free()
	return ""

func test_lake_mallard_duck_flock_and_dabbling() -> String:
	var duck = LakeMallardDuckScript.new()
	if duck == null:
		return "Failed to instantiate LakeMallardDuck"

	if duck._body_mesh == null:
		return "LakeMallardDuck missing _body_mesh"
	if duck._head_root == null:
		return "LakeMallardDuck missing _head_root"
	if duck._audio_player == null:
		return "LakeMallardDuck missing _audio_player"
	if duck._quack_wav == null or duck._quack_wav.data.is_empty():
		return "LakeMallardDuck procedural quack WAV audio stream is empty"

	var initial_pos = duck.position
	duck.swim_center = Vector3(45.0, 0.05, 82.0)
	duck.swim_radius = 8.0
	duck.swim_speed = 1.0

	# Tick simulation
	duck.update_behavior(1.0)
	if duck.position == initial_pos:
		return "LakeMallardDuck did not advance position during swimming update"

	duck.free()
	return ""

func test_exploration_chest_system_and_monument() -> String:
	var chest_sys = ExplorationChestSystemScript.new()
	if chest_sys == null:
		return "Failed to instantiate ExplorationChestSystem"

	chest_sys.setup(null)

	if chest_sys.get_chest_count() != 6:
		return "Expected 6 exploration chests, got %d" % chest_sys.get_chest_count()
	if chest_sys.get_unopened_count() != 6:
		return "Expected 6 unopened chests, got %d" % chest_sys.get_unopened_count()

	# Test proximity detection
	var near_id = chest_sys.get_nearest_unopened_chest(Vector3(95.0, 3.8, 88.0), 3.0)
	if near_id != "lake_island_chest":
		return "Expected lake_island_chest near (95, 3.8, 88), got '%s'" % near_id

	# Test opening chest
	var opened: Array = ["", {}]
	chest_sys.chest_opened.connect(func(cid, rew):
		opened[0] = cid
		opened[1] = rew
	)

	var reward = chest_sys.open_chest("lake_island_chest")
	if reward.is_empty():
		return "Failed to open lake_island_chest"
	if opened[0] != "lake_island_chest":
		return "chest_opened signal not received with correct id"
	if reward.get("coins", 0) != 150:
		return "Expected 150 coins from lake_island_chest, got %d" % reward.get("coins", 0)
	if reward.get("item", "") != "anemo_gem":
		return "Expected anemo_gem item from lake_island_chest, got '%s'" % reward.get("item", "")
	if chest_sys.get_unopened_count() != 5:
		return "Expected 5 unopened chests remaining, got %d" % chest_sys.get_unopened_count()

	# Test Anemo Elemental Monument
	if chest_sys._monument_root == null:
		return "Missing Anemo Elemental Monument root"
	if chest_sys._monument_propeller == null:
		return "Missing Anemo Elemental Monument propeller"

	var monument_hit: Array = [false]
	chest_sys.monument_activated.connect(func(_mid): monument_hit[0] = true)
	chest_sys.strike_monument()

	if not monument_hit[0]:
		return "monument_activated signal not emitted upon strike"
	if chest_sys._monument_spin_speed < 10.0:
		return "Monument spin speed did not accelerate upon strike"

	# Tick process to ensure decay logic
	chest_sys._process(0.1)

	chest_sys.free()
	return ""

func test_circular_minimap_hud_telemetry() -> String:
	var hud = CircularMinimapHUDScript.new()
	if hud == null:
		return "Failed to instantiate CircularMinimapHUD"

	if hud.landmarks.size() < 6:
		return "Expected at least 6 landmarks registered in circular minimap"

	var dummy_p = Node3D.new()
	dummy_p.position = Vector3(95.0, 3.5, 85.0)
	dummy_p.rotation.y = 0.0

	var dummy_cam = Camera3D.new()
	dummy_cam.rotation.y = 0.0

	hud.setup(dummy_p, dummy_cam, null, null)
	hud._process(0.016)

	# Verify location resolution near Grand Emerald Lake / Heart Island
	if hud.current_location_name != "Đảo Trái Tim" and hud.current_location_name != "Hồ Ngọc Bích":
		return "Expected location name 'Đảo Trái Tim' or 'Hồ Ngọc Bích' at (95, 85), got '%s'" % hud.current_location_name

	# Test radar projection
	var r_data = hud._world_to_radar(95.0, 85.0, Vector2(80, 80), CircularMinimapHUDScript.MINIMAP_RADIUS)
	if not r_data.has("pos") or not r_data.has("clamped"):
		return "_world_to_radar returned invalid structure"
	var screen_pos: Vector2 = r_data["pos"]
	if screen_pos.distance_to(Vector2(80, 80)) > 2.0:
		return "Player position should map to minimap center (80, 80), got %s" % str(screen_pos)

	hud.free()
	dummy_p.free()
	dummy_cam.free()
	return ""

class MockDayNightCycle:
	extends Node
	var night: bool = false
	func is_night() -> bool:
		return night
