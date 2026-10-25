extends RefCounted

## Scenario Acceptance & Stress Tests for Block 10: Living World, Emergent Events & Gameplay Integration.
## Verifies the 8 required real-world ecological scenarios deterministically.

const LivingWorldDirector = preload("res://core/living_world/living_world_director.gd")
const SpatialAudioDirector = preload("res://presentation/audio/spatial_audio_director.gd")

# 1. Early morning dawn chorus
func test_scenario_1_dawn_chorus() -> bool:
	var seed_gen: WorldSeed = WorldSeed.new(101)
	var clock: WorldClock = WorldClock.new(1.0)
	var bus: WorldEventBus = WorldEventBus.new()
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir.setup(clock, bus, null, null)

	var events: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): events.append(t))

	# Advance clock to hour 5.9 (before dawn)
	clock.set_sim_hour(5.9)
	dir._check_diurnal_transitions()
	var events_before: int = events.size()

	# Advance clock across dawn (hour 6.1)
	clock.set_sim_hour(6.1)
	dir._check_diurnal_transitions()

	var fired_dawn: bool = events.size() > events_before and events.has("DAWN_CHORUS")
	dir.free()
	return fired_dawn


# 2. Player approaches deer herd triggering stampede
func test_scenario_2_herd_stampede_on_player_proximity() -> bool:
	var bus: WorldEventBus = WorldEventBus.new()
	var registry: EntityRegistry = EntityRegistry.new(bus)
	var metrics_cls = preload("res://core/ecosystem/ecosystem_metrics.gd")
	var metrics = metrics_cls.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(RandomNumberGenerator.new(), registry, metrics, bus)

	# Spawn 4 herbivores near (10, 0, 10)
	var id1: int = fauna.spawn_herbivore(Vector3(10.0, 0.0, 10.0))
	var id2: int = fauna.spawn_herbivore(Vector3(11.0, 0.0, 10.5))
	var id3: int = fauna.spawn_herbivore(Vector3(10.5, 0.0, 11.0))
	var id4: int = fauna.spawn_herbivore(Vector3(9.5, 0.0, 10.0))

	var h1: FaunaSimulation.HerbivoreData = fauna.get_herbivore(id1)
	var h2: FaunaSimulation.HerbivoreData = fauna.get_herbivore(id2)
	var h3: FaunaSimulation.HerbivoreData = fauna.get_herbivore(id3)
	var h4: FaunaSimulation.HerbivoreData = fauna.get_herbivore(id4)

	# Set their state to FLEEING (simulating chain alert)
	h1.state = FaunaSimulation.HerbivoreState.FLEEING
	h2.state = FaunaSimulation.HerbivoreState.FLEEING
	h3.state = FaunaSimulation.HerbivoreState.FLEEING
	h4.state = FaunaSimulation.HerbivoreState.FLEEING

	# Player is at (10, 0, 12) — within 2m
	fauna.set_player_presence(Vector3(10.0, 0.0, 12.0), true)

	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir.setup(null, bus, fauna, null)

	var events: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): events.append(t))

	dir._check_player_stampede()

	var ok: bool = events.has("HERD_STAMPEDE")
	dir.free()
	return ok


# 3. Deer shoreline drinking migration behavior
func test_scenario_3_shoreline_drinking_behavior() -> bool:
	var bus: WorldEventBus = WorldEventBus.new()
	var registry: EntityRegistry = EntityRegistry.new(bus)
	var metrics_cls = preload("res://core/ecosystem/ecosystem_metrics.gd")
	var metrics = metrics_cls.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(RandomNumberGenerator.new(), registry, metrics, bus)

	var hid: int = fauna.spawn_herbivore(Vector3(14.0, 0.55, 12.0), 50.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)
	h.state = FaunaSimulation.HerbivoreState.DRINKING
	var initial_energy: float = h.energy

	var height_func = func(_x: float, _z: float) -> float: return 0.55
	fauna.step_simulation(1.0, null, height_func)

	return h.energy > initial_energy


# 4. Predator stalk and kill event
func test_scenario_4_predator_hunt_event() -> bool:
	var bus: WorldEventBus = WorldEventBus.new()
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir.setup(null, bus, null, null)

	var events: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): events.append(t))

	# Fire fauna_died with predation reason
	bus.publish("fauna_died", {
		"type": "herbivore",
		"reason": "predation",
		"id": 999,
		"position": Vector3(15.0, 2.0, -8.0)
	})

	var ok: bool = events.has("PREDATION_OBSERVED")
	dir.free()
	return ok


# 5. Weather transition from Clear to Rain
func test_scenario_5_weather_transition_rain() -> bool:
	var bus: WorldEventBus = WorldEventBus.new()
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir.setup(null, bus, null, null)

	var events: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): events.append(t))

	bus.publish("weather_changed", {
		"old_weather": "Clear Skies",
		"new_weather": "Gentle Rain",
		"wind_speed": 4.5
	})

	var ok: bool = events.has("STORM_INCOMING")
	dir.free()
	return ok


# 6. Dusk golden hour transition
func test_scenario_6_dusk_transition() -> bool:
	var clock: WorldClock = WorldClock.new(1.0)
	var bus: WorldEventBus = WorldEventBus.new()
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir.setup(clock, bus, null, null)

	var events: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): events.append(t))

	# Hour 19.9
	clock.set_sim_hour(19.9)
	dir._check_diurnal_transitions()

	# Cross to Hour 20.1
	clock.set_sim_hour(20.1)
	dir._check_diurnal_transitions()

	var ok: bool = events.has("DUSK_TRANSITION")
	dir.free()
	return ok


# 7. Concurrent events without conflict or corruption
func test_scenario_7_concurrent_events_no_conflict() -> bool:
	var bus: WorldEventBus = WorldEventBus.new()
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir.setup(null, bus, null, null)

	var events: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): events.append(t))

	# Fire multiple events simultaneously
	dir._fire_event("STORM_INCOMING", "Rain", "body", "notice")
	dir._fire_event("PREDATION_OBSERVED", "Kill", "body", "warning")
	dir._fire_event("CAUSAL_CASCADE", "Cascade", "body", "info")

	var ok: bool = events.size() == 3 and events[0] == "STORM_INCOMING" and events[1] == "PREDATION_OBSERVED" and events[2] == "CAUSAL_CASCADE"
	dir.free()
	return ok


# 8. High population stress and recovery cycle
func test_scenario_8_population_stress_and_recovery() -> bool:
	var bus: WorldEventBus = WorldEventBus.new()
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir.setup(null, bus, null, null)

	var counts = {"collapse": 0, "recovery": 0}
	dir.emergent_event.connect(func(t, _ti, _b, _s):
		if t == "POPULATION_COLLAPSE":
			counts["collapse"] += 1
		elif t == "POPULATION_RECOVERY":
			counts["recovery"] += 1
	)

	# Initialize with boom population
	dir._last_herb_count = 60
	dir._in_collapse = false

	# Rapid crash to 2
	dir._on_metrics_updated({"herbivore_count": 2})
	# Still low — should not double fire
	dir._on_metrics_updated({"herbivore_count": 1})
	dir._on_metrics_updated({"herbivore_count": 2})

	# Recovery to 12
	dir._on_metrics_updated({"herbivore_count": 12})
	# Still high — should not double fire recovery
	dir._on_metrics_updated({"herbivore_count": 15})

	var ok: bool = (counts["collapse"] == 1 and counts["recovery"] == 1)
	dir.free()
	return ok
