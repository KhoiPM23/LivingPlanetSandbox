class_name TestBlock1314Verification
extends RefCounted

## Automated contract and verification suite for Block 13 (Showcase Region) & Block 14 (Deep Immersion & Cognition).
## Runs purely headless with 0% GPU load.

const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")
const WorldClock = preload("res://core/clock/world_clock.gd")
const WorldEventBus = preload("res://core/events/world_event_bus.gd")
const LivingWorldDirector = preload("res://core/living_world/living_world_director.gd")
const IslandTerrain = preload("res://presentation/environment/island_terrain.gd")

func _flat_height(_x: float, _z: float) -> float:
	return 2.5

func _shoreline_height(x: float, z: float) -> float:
	var dist_to_lake: float = Vector2(x - 16.0, z - 14.0).length()
	if dist_to_lake < 10.0:
		return 0.50 # Water's edge
	return 2.5

func test_showcase_region_trail_and_bounds() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.generate_island(1337)

	# Verify animal trail from forest (-6, -1) through meadow (1, 3.5), (6, 6) to shore (12.5, 8.5)
	var trail_start: float = terrain.get_trail_factor(-6.0, -1.0)
	var trail_mid: float = terrain.get_trail_factor(6.0, 6.8)
	var trail_shore: float = terrain.get_trail_factor(12.5, 8.5)
	var trail_off: float = terrain.get_trail_factor(6.0, 15.0) # Far off path

	if trail_start <= 0.5:
		terrain.free()
		return "Trail factor at forest start too low (%.2f)" % trail_start
	if trail_mid <= 0.5:
		terrain.free()
		return "Trail factor at meadow mid too low (%.2f)" % trail_mid
	if trail_shore <= 0.5:
		terrain.free()
		return "Trail factor at lake shore too low (%.2f)" % trail_shore
	if trail_off > 0.01:
		terrain.free()
		return "Trail factor off-path should be 0.0 (got %.2f)" % trail_off

	terrain.free()
	return ""

func test_fauna_hydration_depletion_and_shoreline_drinking() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261015
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# 1. Verify initial hydration
	var hid: int = fauna.spawn_herbivore(Vector3(8.0, 2.5, 3.5), 90.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)
	if h.hydration < 80.0:
		return "Initial hydration was lower than expected (%.1f)" % h.hydration

	# 2. Step simulation: hydration must deplete
	var initial_hydration: float = h.hydration
	fauna.step_simulation(10.0, null, Callable(self, "_flat_height"))
	if h.hydration >= initial_hydration:
		return "Hydration did not deplete during simulation (was %.1f, now %.1f)" % [initial_hydration, h.hydration]

	# 3. Simulate thirst and arrival at shoreline
	h.hydration = 30.0
	h.position = Vector3(14.0, 0.50, 10.0) # Shoreline of Emerald Basin
	fauna.step_simulation(0.5, null, Callable(self, "_shoreline_height"), null, 16.0)

	if h.state != FaunaSimulation.HerbivoreState.DRINKING:
		return "Thirsty herbivore at shoreline did not transition to DRINKING (state: %d)" % h.state

	# 4. Drinking replenishes hydration to full
	var pre_drink_hydration: float = h.hydration
	fauna.step_simulation(2.0, null, Callable(self, "_shoreline_height"), null, 16.0)
	if h.hydration <= pre_drink_hydration:
		return "Drinking did not replenish hydration (pre: %.1f, now: %.1f)" % [pre_drink_hydration, h.hydration]

	return ""

func test_velocity_aware_flight_and_herd_alarm_contagion() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 334455
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn two herbivores in the same herd (distance 4.0m < 10.0m alarm radius)
	var h1_id: int = fauna.spawn_herbivore(Vector3(10.0, 2.5, 10.0), 85.0)
	var h2_id: int = fauna.spawn_herbivore(Vector3(14.0, 2.5, 10.0), 85.0)
	var h1: FaunaSimulation.HerbivoreData = fauna.get_herbivore(h1_id)
	var h2: FaunaSimulation.HerbivoreData = fauna.get_herbivore(h2_id)

	# 1. Player approaching slowly / still at 11m distance: H1 enters ALERT
	fauna.set_player_presence(Vector3(21.0, 2.5, 10.0), true) # 11m away
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"))
	if h1.state != FaunaSimulation.HerbivoreState.ALERT:
		return "H1 did not enter ALERT upon slow player approach at 11m (state: %d)" % h1.state

	# 2. Player rushes at high speed: simulate sudden sprint approach
	fauna._player_speed = 4.2 # sprinting
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"))
	if h1.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "H1 did not enter FLEEING on fast player sprint approach (state: %d)" % h1.state

	# 3. Verify Herd Alarm Contagion: H2 should have caught the panic and entered FLEEING
	if h2.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "Herd alarm contagion failed: H2 did not enter FLEEING when nearby H1 panicked (state: %d)" % h2.state

	return ""

func test_nocturnal_canopy_shelter_resting() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 778899
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn herbivore under Whispering Forest canopy (X: -4.0, Z: -1.0)
	var hid: int = fauna.spawn_herbivore(Vector3(-4.0, 2.5, -1.0), 80.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)

	# Step at nighttime (sim_hour = 23.0)
	fauna.step_simulation(1.0, null, Callable(self, "_flat_height"), null, 23.0)

	if h.state != FaunaSimulation.HerbivoreState.RESTING:
		return "Herbivore under canopy at night did not enter RESTING state (state: %d)" % h.state
	if not h.is_sheltered:
		return "Herbivore under canopy did not register is_sheltered"

	return ""

func test_predator_stalking_vs_ambush_sprint() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 991122
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn prey at (25.0, 2.5, 10.0) and predator at (10.0, 2.5, 10.0) -> distance 15m (>8m stalking zone)
	var hid: int = fauna.spawn_herbivore(Vector3(25.0, 2.5, 10.0), 85.0)
	var pid: int = fauna.spawn_predator(Vector3(10.0, 2.5, 10.0), 50.0) # hungry predator
	var p: FaunaSimulation.PredatorData = fauna.get_predator(pid)

	# 1. Step simulation at 15m distance: predator should be HUNTING and is_stalking = true
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"))
	if p.state != FaunaSimulation.PredatorState.HUNTING:
		return "Hungry predator did not enter HUNTING state (state: %d)" % p.state
	if not p.is_stalking:
		return "Predator at 15m distance was not stalking (is_stalking should be true)"

	# 2. Teleport predator within pounce range (5m < 8m)
	p.position = Vector3(20.0, 2.5, 10.0)
	fauna.step_simulation(0.2, null, Callable(self, "_flat_height"))
	if p.is_stalking:
		return "Predator within 5m strike range should have broken into ambush sprint (is_stalking is still true)"

	return ""

func test_living_world_director_block14_events() -> String:
	var clock: WorldClock = WorldClock.new(720.0)
	clock.set_sim_hour(11.5)
	var bus: WorldEventBus = WorldEventBus.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 445566
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics, bus)

	var director: LivingWorldDirector = LivingWorldDirector.new()
	director.setup(clock, bus, fauna, null)

	var fired_events: Array[String] = []
	director.emergent_event.connect(func(type, _title, _body, _sev):
		fired_events.append(type)
	)

	# 1. Spawn two alert herbivores to trigger HERD_ALARM
	var h1_id: int = fauna.spawn_herbivore(Vector3(8.0, 2.5, 3.5), 85.0)
	var h2_id: int = fauna.spawn_herbivore(Vector3(9.5, 2.5, 3.5), 85.0)
	var h1 = fauna.get_herbivore(h1_id)
	var h2 = fauna.get_herbivore(h2_id)
	h1.state = FaunaSimulation.HerbivoreState.ALERT
	h2.state = FaunaSimulation.HerbivoreState.ALERT

	director._check_ecological_behaviors()
	if not fired_events.has("HERD_ALARM"):
		director.free()
		return "HERD_ALARM emergent event was not fired when 2 deer were ALERT"

	# 2. Transition both to DRINKING to trigger THIRST_MIGRATION
	h1.state = FaunaSimulation.HerbivoreState.DRINKING
	h2.state = FaunaSimulation.HerbivoreState.DRINKING
	director._check_ecological_behaviors()
	if not fired_events.has("THIRST_MIGRATION"):
		director.free()
		return "THIRST_MIGRATION emergent event was not fired when 2 deer were DRINKING"

	director.free()
	return ""
