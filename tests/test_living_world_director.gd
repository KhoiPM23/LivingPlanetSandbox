extends RefCounted

## Contract tests for LivingWorldDirector — Block 10 Living World & Emergent Events.

const LivingWorldDirector = preload("res://core/living_world/living_world_director.gd")

func test_director_instantiation() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	var ok: bool = dir != null
	dir.free()
	return ok


func test_director_setup_with_real_systems() -> bool:
	var seed: WorldSeed = WorldSeed.new(42)
	var clock: WorldClock = WorldClock.new(10.0)
	var bus: WorldEventBus = WorldEventBus.new()
	var registry: EntityRegistry = EntityRegistry.new(bus)
	var metrics_cls = preload("res://core/ecosystem/ecosystem_metrics.gd")
	var metrics = metrics_cls.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(RandomNumberGenerator.new(), registry, metrics, bus)
	var weather: WeatherSystem = WeatherSystem.new(null, bus)

	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir.setup(clock, bus, fauna, weather)

	var ok: bool = dir._clock == clock and dir._event_bus == bus and dir._fauna_sim == fauna and dir._weather == weather
	dir.free()
	return ok


func test_cooldown_system() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	# Initially all cooldowns are 0 — can fire
	var can_fire_fresh: bool = dir._can_fire("STORM_INCOMING")
	# After firing, cooldown is set
	dir._fire_event("STORM_INCOMING", "Test", "body", "info")
	var cannot_fire_after: bool = not dir._can_fire("STORM_INCOMING")
	# After advancing time past cooldown
	dir._cooldowns["STORM_INCOMING"] = 0.0
	var can_fire_again: bool = dir._can_fire("STORM_INCOMING")
	dir.free()
	return can_fire_fresh and cannot_fire_after and can_fire_again


func test_emergent_event_signal_emitted() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()

	var received: Array = []
	dir.emergent_event.connect(func(t, _title, _body, sev): received.append({"type": t, "sev": sev}))

	dir._fire_event("DAWN_CHORUS", "Test Dawn", "Body text", "notice")

	var ok: bool = received.size() == 1 and received[0]["type"] == "DAWN_CHORUS" and received[0]["sev"] == "notice"
	dir.free()
	return ok


func test_bypass_cooldown() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	var events: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): events.append(t))

	# Fire normally — sets cooldown
	dir._fire_event("POPULATION_COLLAPSE", "Collapse", "body", "critical")
	# Fire again without bypass — should be blocked by cooldown
	dir._fire_event("POPULATION_COLLAPSE", "Collapse 2", "body", "critical")
	# Fire with bypass — should succeed despite cooldown
	dir._fire_event("POPULATION_COLLAPSE", "Collapse 3", "body", "critical", true)

	dir.free()
	# Should have received 2 events (first + bypass), not 3 (blocked by cooldown)
	return events.size() == 2


func test_weather_changed_rain_fires_event() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	var received: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): if t == "STORM_INCOMING": received.append(t))

	dir._on_weather_changed({"old_weather": "Clear Skies", "new_weather": "Gentle Rain"})

	dir.free()
	return received.size() == 1


func test_weather_changed_drought_fires_event() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	var received: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): if t == "STORM_INCOMING": received.append(t))

	dir._on_weather_changed({"old_weather": "Clear Skies", "new_weather": "Arid Drought"})

	dir.free()
	return received.size() == 1


func test_fauna_died_predation_fires_event() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	var received: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): if t == "PREDATION_OBSERVED": received.append(t))

	dir._on_fauna_died({"type": "herbivore", "reason": "predation", "id": 1001, "position": Vector3.ZERO})

	dir.free()
	return received.size() == 1


func test_fauna_died_starvation_no_predation_event() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	var received: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): if t == "PREDATION_OBSERVED": received.append(t))

	dir._on_fauna_died({"type": "herbivore", "reason": "starvation", "id": 1002, "position": Vector3.ZERO})

	dir.free()
	return received.is_empty()  # starvation should NOT fire PREDATION_OBSERVED


func test_population_collapse_threshold() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir._last_herb_count = 10
	dir._in_collapse = false

	var received: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): if t == "POPULATION_COLLAPSE": received.append(t))

	# Simulate metrics updated with count dropping to collapse threshold
	dir._on_metrics_updated({"herbivore_count": LivingWorldDirector.COLLAPSE_THRESHOLD, "predator_count": 2})

	dir.free()
	return received.size() == 1


func test_population_recovery_after_collapse() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir._last_herb_count = 2
	dir._in_collapse = true

	var received: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): if t == "POPULATION_RECOVERY": received.append(t))

	# Simulate metrics updated with count rising above recovery threshold
	dir._on_metrics_updated({"herbivore_count": LivingWorldDirector.RECOVERY_THRESHOLD + 1})

	dir.free()
	return received.size() == 1


func test_collapse_not_repeated_without_recovery() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir._last_herb_count = 10
	dir._in_collapse = false

	var received: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): if t == "POPULATION_COLLAPSE": received.append(t))

	# First collapse
	dir._on_metrics_updated({"herbivore_count": 2})
	# Second trigger at same low count — should NOT fire again (already in collapse)
	dir._on_metrics_updated({"herbivore_count": 1})

	dir.free()
	return received.size() == 1  # exactly once


func test_causal_cascade_logged() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	var received: Array = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): if t == "CAUSAL_CASCADE": received.append(t))

	dir._on_causal_cascade({
		"headline": "Drought killed Plant #42",
		"narrative": "Plant #42 withered due to induced moisture deficit.",
		"type": "plant_death"
	})

	dir.free()
	return received.size() == 1


func test_causal_cascade_empty_headline_ignored() -> bool:
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	var received: Array = []
	dir.emergent_event.connect(func(_t, _ti, _b, _s): received.append(true))

	dir._on_causal_cascade({"headline": "", "narrative": "no headline"})

	dir.free()
	return received.is_empty()  # empty headline should be silently ignored


func test_event_bus_publishing() -> bool:
	var bus: WorldEventBus = WorldEventBus.new()
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir.setup(null, bus, null, null)

	var bus_received: Array = []
	bus.subscribe("living_world_event", func(payload: Dictionary): bus_received.append(payload))

	dir._fire_event("DAWN_CHORUS", "Dawn", "Body", "notice")

	var ok: bool = bus_received.size() == 1 and bus_received[0].get("type") == "DAWN_CHORUS"
	dir.free()
	return ok


func test_spatial_audio_event_reaction() -> bool:
	var bus: WorldEventBus = WorldEventBus.new()
	var audio_cls = preload("res://presentation/audio/spatial_audio_director.gd")
	var audio = audio_cls.new()
	audio.setup(null, null, null, bus)

	# Publish living_world_event
	bus.publish("living_world_event", {"type": "PREDATION_OBSERVED"})

	# Verify audio did not crash and fauna player was loaded
	var ok: bool = audio._player_fauna != null and audio._player_fauna.stream != null
	audio.free()
	return ok
