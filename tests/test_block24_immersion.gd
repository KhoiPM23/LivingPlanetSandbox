class_name TestBlock24Immersion
extends RefCounted

## Verification Suite for Block 24: Living World Depth, Ecological Realism & Environmental Immersion.
## Contract tests:
## 1. Diurnal Circadian Wildlife Cycles (Resting under canopy at night, waking at dawn).
## 2. Weather-Coupled Animal Sheltering (Seeking canopy refuge during rain downpours).
## 3. Player Crouch / Stealth Locomotion & Reduced Detection Profile.
## 4. Flight Hysteresis & Recovery (Calming down into vigilant alert, then returning to normal routine).
## 5. Predator Stalking, Ambush Sprint & Satiation Digestion Cooldown.
## 6. Ancient Cairn Landmark Grounding, Collision & Wordless Discovery.
## 7. Contextual Spatial Audio Day/Night Crossfade & 3D Cove Localization.

const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")
const WorldClock = preload("res://core/clock/world_clock.gd")
const WeatherSystem = preload("res://core/environment/weather_system.gd")
const WorldEventBus = preload("res://core/events/world_event_bus.gd")
const SpatialAudioDirector = preload("res://presentation/audio/spatial_audio_director.gd")
const EnvironmentalStorytelling = preload("res://presentation/environment/environmental_storytelling.gd")
const IslandTerrain = preload("res://presentation/environment/island_terrain.gd")
const FirstPersonWalker = preload("res://presentation/camera/first_person_walker.gd")

func _flat_height(_x: float, _z: float) -> float:
	return 2.5

func test_diurnal_wildlife_circadian_rhythm() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2401
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# 1. Spawn deer inside Whispering Forest canopy at night (sim_hour = 23.0)
	var hid: int = fauna.spawn_herbivore(Vector3(-5.0, 2.5, -1.0), 80.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)

	fauna.step_simulation(1.0, null, Callable(self, "_flat_height"), null, 23.0)
	if h.state != FaunaSimulation.HerbivoreState.RESTING:
		return "Herbivore under canopy at night did not enter RESTING state (got %d)" % h.state
	if not h.is_sheltered:
		return "Herbivore under canopy at night should be sheltered"
	if h.velocity.length_squared() > 0.001:
		return "Resting herbivore should have zero velocity (got %.2f)" % h.velocity.length()

	# 2. Advance time to dawn (sim_hour = 6.0): Deer should awaken and return to wandering/foraging
	h.state_timer = 28.0
	fauna.step_simulation(1.0, null, Callable(self, "_flat_height"), null, 6.0)
	if h.state == FaunaSimulation.HerbivoreState.RESTING:
		return "Herbivore should awaken from rest at dawn (sim_hour = 6.0)"

	return ""

func test_weather_rain_wildlife_sheltering() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2402
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	var bus: WorldEventBus = WorldEventBus.new()
	var weather: WeatherSystem = WeatherSystem.new(rng, bus)
	weather.set_manual_state(WeatherSystem.WeatherState.RAIN)

	# Spawn deer in open meadow (10.0, 2.5, 4.0)
	var hid: int = fauna.spawn_herbivore(Vector3(10.0, 2.5, 4.0), 85.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)

	# Step under rain: Deer should steer toward canopy shelter (-6.0, 0, -1.5)
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"), weather, 12.0)
	var to_shelter: Vector3 = (Vector3(-6.0, 2.5, -1.5) - h.position).normalized()
	var move_dir: Vector3 = h.velocity.normalized()
	if move_dir.dot(to_shelter) < 0.3:
		return "Herbivore in rain did not steer toward forest canopy shelter"

	# Teleport inside canopy: Deer should bed down into RESTING under rain
	h.position = Vector3(-6.0, 2.5, -1.5)
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"), weather, 12.0)
	if h.state != FaunaSimulation.HerbivoreState.RESTING:
		return "Herbivore under canopy in rain did not bed down into RESTING (got %d)" % h.state
	if not h.is_sheltered:
		return "Herbivore under canopy in rain was not marked as sheltered"

	return ""

func test_player_crouch_stealth_and_approach() -> String:
	var walker: FirstPersonWalker = FirstPersonWalker.new()

	# 1. Test locomotion crouch speeds
	if walker.crouch_speed >= walker.walk_speed:
		walker.free()
		return "Crouch speed (%.2f) must be slower than walk speed (%.2f)" % [walker.crouch_speed, walker.walk_speed]

	walker.move_character(0.016, Vector3.FORWARD, false, false, true)
	if not walker.is_crouching:
		walker.free()
		return "Walker failed to register is_crouching state"

	walker.free()

	# 2. Test stealth approach perception on wildlife
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2403
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	var hid: int = fauna.spawn_herbivore(Vector3(0.0, 2.5, 0.0), 85.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)
	h.heading = 0.0 # Facing +X

	# Case A: Sneaking slowly at 11m distance (speed = 1.3 m/s)
	fauna.set_player_presence(Vector3(11.0, 2.5, 0.0), true, 1.3)
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"), null, 12.0)
	if h.state == FaunaSimulation.HerbivoreState.FLEEING or h.state == FaunaSimulation.HerbivoreState.ALERT:
		return "Crouched stealth approach at 11m prematurely alarmed herbivore (state: %d)" % h.state

	# Case B: Fast sprinting approach at 11m distance (speed = 6.5 m/s)
	fauna.set_player_presence(Vector3(11.0, 2.5, 0.0), true, 6.5)
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"), null, 12.0)
	if h.state != FaunaSimulation.HerbivoreState.FLEEING and h.state != FaunaSimulation.HerbivoreState.ALERT:
		return "Sprinting player approach at 11m failed to trigger alert or flight (state: %d)" % h.state

	return ""

func test_flight_hysteresis_and_settling_recovery() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2404
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	var hid: int = fauna.spawn_herbivore(Vector3(0.0, 2.5, 0.0), 85.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)

	# 1. Trigger panic flight by close sprinting player (3m)
	fauna.set_player_presence(Vector3(3.0, 2.5, 0.0), true, 5.0)
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"), null, 12.0)
	if h.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "Herbivore failed to enter FLEEING on close threat (state: %d)" % h.state

	# 2. Player retreats beyond 20m: Herbivore should settle into ALERT vigilance rather than fleeing forever
	fauna.set_player_presence(Vector3(25.0, 2.5, 0.0), true, 0.0)
	h.flee_timer = 0.0 # timer expired
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"), null, 12.0)
	if h.state != FaunaSimulation.HerbivoreState.ALERT:
		return "Herbivore should transition from flight to settling ALERT when threat retreats (got %d)" % h.state
	if h.velocity.length_squared() > 0.001:
		return "Herbivore in settling ALERT should hold vigilant posture with zero velocity"

	# 3. Advance vigilance timer past 0: Herbivore recovers to peaceful routine
	h.vigilance_timer = 0.0
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"), null, 12.0)
	if h.state == FaunaSimulation.HerbivoreState.FLEEING or h.state == FaunaSimulation.HerbivoreState.ALERT:
		return "Herbivore failed to recover to peacetime routine after vigilance expired (got %d)" % h.state

	return ""

func test_predator_stalking_ambush_and_satiation_cooldown() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2405
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Prey at (20.0, 2.5, 0.0) and Wolf at (5.0, 2.5, 0.0) -> dist 15m
	var hid: int = fauna.spawn_herbivore(Vector3(20.0, 2.5, 0.0), 80.0)
	var pid: int = fauna.spawn_predator(Vector3(5.0, 2.5, 0.0), 55.0)
	var p: FaunaSimulation.PredatorData = fauna.get_predator(pid)

	# 1. 15m distance: Wolf should be stalking
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"), null, 12.0)
	if p.state != FaunaSimulation.PredatorState.HUNTING or not p.is_stalking:
		return "Predator at 15m should be stalking prey (state: %d, is_stalking: %s)" % [p.state, str(p.is_stalking)]

	# 2. Strike within 1.0m: Catch and kill
	p.position = Vector3(19.2, 2.5, 0.0)
	fauna.step_simulation(0.2, null, Callable(self, "_flat_height"), null, 12.0)
	if p.state != FaunaSimulation.PredatorState.EATING:
		return "Predator upon catching prey should enter EATING state (got %d)" % p.state
	if p.hunt_fatigue < 5.0:
		return "Predator upon feeding should have satiation fatigue cooldown (got %.1f)" % p.hunt_fatigue

	# 3. Verify wolf does not instantly re-hunt another prey while in satiation fatigue
	fauna.spawn_herbivore(Vector3(22.0, 2.5, 0.0), 80.0)
	p.state = FaunaSimulation.PredatorState.RESTING
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"), null, 12.0)
	if p.state == FaunaSimulation.PredatorState.HUNTING:
		return "Satiated predator should not immediately hunt while hunt_fatigue is active"

	return ""

func test_ancient_cairn_landmark_grounding_and_discovery() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	var mock_player: Node3D = Node3D.new()
	mock_player.position = Vector3(40.0, 5.0, 40.0)

	var storytelling: EnvironmentalStorytelling = EnvironmentalStorytelling.new()
	storytelling.setup(terrain, null, mock_player, null, 1337)

	# 1. Verify POI count >= 5
	if storytelling.get_poi_count() < 5:
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "Expected at least 5 hero narrative POIs, got %d" % storytelling.get_poi_count()

	# 2. Verify ancient cairn POI properties
	var cairn: Dictionary = storytelling.get_poi_by_id("ancient_cairn")
	if cairn.is_empty():
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "Missing required 5th landmark POI: ancient_cairn"

	if not cairn["title"].begins_with("🗿"):
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "ancient_cairn title missing monolith icon"

	var pos: Vector3 = cairn["position"]
	var terrain_y: float = terrain.get_height_at(pos.x, pos.z)
	if absf(pos.y - terrain_y) > 0.35:
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "ancient_cairn not grounded to terrain: pos.y=%.2f vs terrain_y=%.2f" % [pos.y, terrain_y]

	# 3. Test proximity discovery
	var discovered: Array[String] = []
	storytelling.discovery_unlocked.connect(func(id: String, _t: String, _b: String): discovered.append(id))

	mock_player.position = pos + Vector3(0.5, 0.0, 0.5)
	storytelling._process(0.3)
	if not discovered.has("ancient_cairn"):
		terrain.free()
		mock_player.free()
		storytelling.free()
		return "Entering ancient cairn proximity did not trigger discovery_unlocked"

	terrain.free()
	mock_player.free()
	storytelling.free()
	return ""

func test_contextual_spatial_audio_transitions() -> String:
	var clock: WorldClock = WorldClock.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2407
	var bus: WorldEventBus = WorldEventBus.new()
	var weather: WeatherSystem = WeatherSystem.new(rng, bus)

	var audio: SpatialAudioDirector = SpatialAudioDirector.new()
	audio.setup(clock, weather, null, bus)

	# 1. Verify Lake Cove 3D Positional Audio coordinates
	var water_pos: Vector3 = audio._player_water.position
	if water_pos.distance_to(Vector3(16.0, 0.15, 14.0)) > 1.0:
		audio.free()
		return "Lake water audio not positioned at Emerald Cove: %s" % str(water_pos)

	if audio._player_water.attenuation_model != AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE:
		audio.free()
		return "Lake water audio must use ATTENUATION_INVERSE_DISTANCE"

	# 2. Test Rain Audio Activation
	weather.set_manual_state(WeatherSystem.WeatherState.RAIN)
	for _i in range(15):
		audio._process(0.1)
	var rain_vol: float = audio._player_rain.volume_db
	if rain_vol < -35.0:
		audio.free()
		return "Rain audio volume should increase during rainstorm (got %.1f dB)" % rain_vol

	audio.free()
	return ""
