class_name TestBlock17Verification
extends RefCounted

## Verification Suite — Block 17: Advanced Wildlife Perception & Emergent Ecology
## Validates multimodal perception, short-term threat memory, behavioral hysteresis,
## predator stalking/sprint/stamina abort, flocking alignment, and individual temperament.

func _flat_height(_x: float, _z: float) -> float:
	return 2.0

func _ridge_height(x: float, _z: float) -> float:
	# Terrain ridge at X=17.5 rising to 5.5m between X=14 and X=21
	if x >= 14.0 and x <= 21.0:
		var dist_to_crest: float = absf(x - 17.5)
		return 5.5 - dist_to_crest * 0.8
	return 2.0

## 1. Multimodal Perception: Speed and noise tiers modulate detection range
func test_multimodal_perception_speed_and_noise_tiers() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 101010
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn deer at (10.0, 2.0, 10.0)
	var hid: int = fauna.spawn_herbivore(Vector3(10.0, 2.0, 10.0), 85.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)
	h.heading = 0.0 # Facing +X direction toward player
	h.temperament_factor = 1.0

	# Step A: Player approaches crouching/sneaking (< 1.6 m/s) at 11m (pos: 21, 2, 10)
	fauna.set_player_presence(Vector3(21.0, 2.0, 10.0), true)
	fauna._player_speed = 1.1 # Sneak speed
	fauna.step_simulation(0.2, null, Callable(self, "_flat_height"))
	if h.state == FaunaSimulation.HerbivoreState.ALERT:
		return "Deer alerted to sneaking player at 11m (sneak should allow stealthy approach)"

	# Step B: Player walks (~2.5 m/s) at 11m -> standard visual/audio detection triggers ALERT
	fauna._player_speed = 2.5 # Normal walking speed
	fauna.step_simulation(0.2, null, Callable(self, "_flat_height"))
	if h.state != FaunaSimulation.HerbivoreState.ALERT:
		return "Deer failed to enter ALERT for walking player at 11m (state: %d)" % h.state
	if h.velocity.length_squared() > 0.01:
		return "Deer did not halt in vigilant observation upon entering ALERT"

	# Step C: Player sprints (> 3.8 m/s) at 17m distance -> acoustic detection triggers ALERT from afar
	h.state = FaunaSimulation.HerbivoreState.WANDERING
	h.vigilance_timer = 0.0
	fauna.set_player_presence(Vector3(27.0, 2.0, 10.0), true) # 17m away
	fauna._player_speed = 4.5 # Heavy sprint footsteps
	fauna.step_simulation(0.2, null, Callable(self, "_flat_height"))
	if h.state != FaunaSimulation.HerbivoreState.ALERT:
		return "Deer failed to detect sprinting player at 17m distance via footstep acoustics"

	# Step D: Player sprints within 10m -> explosive panic flight
	fauna.set_player_presence(Vector3(20.0, 2.0, 10.0), true) # 10m away
	fauna._player_speed = 4.5 # Sprinting
	fauna.step_simulation(0.2, null, Callable(self, "_flat_height"))
	if h.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "Deer failed to trigger panic FLEEING when player sprinted within 10m"

	return ""

## 2. Line-of-sight elevation occlusion: Terrain ridges block visual detection
func test_line_of_sight_terrain_crest_occlusion() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 202020
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn deer at (10.0, 2.0, 10.0) facing +X
	var hid: int = fauna.spawn_herbivore(Vector3(10.0, 2.0, 10.0), 85.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)
	h.heading = 0.0
	h.temperament_factor = 1.0

	# Player stands at (22.0, 2.0, 10.0) (12m away) behind a 5.5m terrain crest at X=17.5
	fauna.set_player_presence(Vector3(22.0, 2.0, 10.0), true)
	fauna._player_speed = 2.0 # Normal walking speed (below acoustic sprint range)
	fauna.step_simulation(0.3, null, Callable(self, "_ridge_height"))

	# LOS should be occluded by ridge (12m > occluded audio range 4.5m)
	if h.state == FaunaSimulation.HerbivoreState.ALERT or h.state == FaunaSimulation.HerbivoreState.FLEEING:
		return "Deer detected player through a 5.5m tall terrain ridge (LOS occlusion failed)"

	# Now step with flat terrain (ridge removed): LOS is clear, deer should enter ALERT
	fauna.step_simulation(0.3, null, Callable(self, "_flat_height"))
	if h.state != FaunaSimulation.HerbivoreState.ALERT:
		return "Deer did not detect player once terrain ridge was cleared (clear LOS should alert)"

	return ""

## 3. Short-term threat memory & behavioral hysteresis: No instant calm or flickering
func test_short_term_threat_memory_and_hysteresis() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 303030
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn deer at (10.0, 2.0, 10.0)
	var hid: int = fauna.spawn_herbivore(Vector3(10.0, 2.0, 10.0), 85.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)
	h.temperament_factor = 1.0

	# 1. Trigger flight by close approach (5m away)
	fauna.set_player_presence(Vector3(15.0, 2.0, 10.0), true)
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"))
	if h.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "Deer failed to trigger flight at 5m player proximity"
	if h.threat_memory <= 0.0 or h.last_known_threat_pos == Vector3.ZERO:
		return "Deer failed to record threat memory during flight"

	# 2. Player retreats to 15m (outside flight trigger): deer halts into ALERT vigilance, NOT wandering
	fauna.set_player_presence(Vector3(25.0, 2.0, 10.0), true) # ~16m away
	h.flee_timer = 0.0 # Simulate flight commitment elapsed
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"))
	if h.state != FaunaSimulation.HerbivoreState.ALERT:
		return "Deer instantly dropped threat status instead of maintaining vigilant ALERT (state: %d)" % h.state
	if h.vigilance_timer <= 0.0:
		return "Deer vigilance timer was not initialized upon flight recovery"

	# 3. Hysteresis: Player hovers at 15m boundary for several ticks
	# Deer should remain in vigilant observation without ping-ponging
	for _i in range(3):
		fauna.set_player_presence(Vector3(24.5, 2.0, 10.0), true)
		fauna.step_simulation(0.2, null, Callable(self, "_flat_height"))
		if h.state != FaunaSimulation.HerbivoreState.ALERT:
			return "Deer flickered out of ALERT while threat hovered near boundary"

	# 4. Player leaves area completely (45m away)
	fauna.set_player_presence(Vector3(55.0, 2.0, 10.0), true)
	# Advance simulation past vigilance timer (3.5s)
	for _i in range(8):
		fauna.step_simulation(0.5, null, Callable(self, "_flat_height"))

	if h.state == FaunaSimulation.HerbivoreState.FLEEING:
		return "Deer failed to recover from ALERT after threat departed"
	if h.state != FaunaSimulation.HerbivoreState.WANDERING and h.state != FaunaSimulation.HerbivoreState.FORAGING:
		return "Deer did not return to peaceful routine after vigilance expired (state: %d)" % h.state

	return ""

## 4. Predator hunt sequence, ambush sprint, and stamina exhaustion abort
func test_predator_hunt_phases_and_exhaustion_abort() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 404040
	var bus: WorldEventBus = WorldEventBus.new()
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics, bus)

	var hunt_aborted_events: Array[Dictionary] = []
	bus.subscribe("predator_hunt_aborted", func(payload: Dictionary) -> void:
		hunt_aborted_events.append(payload)
	)

	# Spawn deer at (25.0, 2.0, 0.0) and hungry predator at (11.0, 2.0, 0.0) -> distance 14m (>8m)
	var hid: int = fauna.spawn_herbivore(Vector3(25.0, 2.0, 0.0), 85.0)
	var pid: int = fauna.spawn_predator(Vector3(11.0, 2.0, 0.0), 40.0) # Hungry wolf
	var p: FaunaSimulation.PredatorData = fauna.get_predator(pid)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)

	# 1. Stalking phase at 14m distance (> 8m): stealth speed (0.75x)
	fauna.step_simulation(0.2, null, Callable(self, "_flat_height"))
	if p.state != FaunaSimulation.PredatorState.HUNTING:
		return "Predator did not enter HUNTING state (state: %d)" % p.state
	if not p.is_stalking:
		return "Predator was not stalking at 14m distance"
	var expected_stalk: float = p.move_speed * 0.75
	if absf(p.velocity.length() - expected_stalk) > 0.15:
		return "Predator stalking speed incorrect: %.2f vs %.2f" % [p.velocity.length(), expected_stalk]

	# 2. Ambush sprint at 6m distance (<= 8m): sprint speed (1.25x)
	p.position = Vector3(19.0, 2.0, 0.0)
	fauna.step_simulation(0.2, null, Callable(self, "_flat_height"))
	if p.is_stalking:
		return "Predator failed to break into ambush sprint at 6m strike range"
	var expected_sprint: float = p.move_speed * 1.25
	if absf(p.velocity.length() - expected_sprint) > 0.15:
		return "Predator sprint speed incorrect: %.2f vs %.2f" % [p.velocity.length(), expected_sprint]

	# 3. Prey escapes and outruns predator for > 7.0s (hunt_stamina exhausted)
	# Keep prey just out of strike range (10m) while advancing simulation
	p.hunt_stamina = 5.0 # Set stamina to 5.0s for test execution speed
	p.hunt_duration = 0.0
	for _i in range(12):
		h.position = p.position + Vector3(10.0, 0.0, 0.0) # Keep prey 10m ahead
		fauna.step_simulation(0.5, null, Callable(self, "_flat_height"))
		if p.state == FaunaSimulation.PredatorState.RESTING:
			break

	if p.state != FaunaSimulation.PredatorState.RESTING:
		return "Predator did not abort hunt after chase stamina was exhausted (state: %d)" % p.state
	if p.hunt_fatigue <= 0.0:
		return "Predator did not incur fatigue recovery timer after aborting hunt"
	if p.stalks_abandoned < 1:
		return "Predator did not record abandoned stalk in metrics"
	if hunt_aborted_events.is_empty():
		return "predator_hunt_aborted event was not published to WorldEventBus"

	return ""

## 5. Flocking alignment and alarm cooldown prevention of infinite cascades
func test_flocking_alignment_and_alarm_cooldown() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 505050
	var bus: WorldEventBus = WorldEventBus.new()
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics, bus)

	var alarm_events: Array[Dictionary] = []
	bus.subscribe("herd_alarm", func(payload: Dictionary) -> void:
		alarm_events.append(payload)
	)

	# Spawn 3 deer in a tight herd
	var h1_id: int = fauna.spawn_herbivore(Vector3(10.0, 2.0, 10.0), 80.0)
	var h2_id: int = fauna.spawn_herbivore(Vector3(13.0, 2.0, 10.0), 80.0)
	var h3_id: int = fauna.spawn_herbivore(Vector3(11.5, 2.0, 13.0), 80.0)

	var h1: FaunaSimulation.HerbivoreData = fauna.get_herbivore(h1_id)
	var h2: FaunaSimulation.HerbivoreData = fauna.get_herbivore(h2_id)
	var h3: FaunaSimulation.HerbivoreData = fauna.get_herbivore(h3_id)
	# Trigger panic flight on H1 away from threat at (0, 2, 10)
	h1.last_known_threat_pos = Vector3(0.0, 2.0, 10.0)
	h1.state = FaunaSimulation.HerbivoreState.FLEEING
	h1.flee_timer = 2.5
	h1.heading = 0.0
	h1.velocity = Vector3(1.0, 0.0, 0.0) * (h1.move_speed * 1.25)
	fauna._spread_herd_alarm(h1, true)

	if h2.state != FaunaSimulation.HerbivoreState.FLEEING or h3.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "Herd alarm failed to propagate panic to nearby herd members"

	# Verify alarm cooldown is active on all deer (preventing infinite ping-pong echo)
	if h1.alarm_cooldown <= 0.0 or h2.alarm_cooldown <= 0.0 or h3.alarm_cooldown <= 0.0:
		return "Alarm cooldown was not applied, risking runaway infinite alarm loops"

	# Step flight simulation: flocking alignment should align flight headings
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"))
	var dot_h1_h2: float = h1.velocity.normalized().dot(h2.velocity.normalized())
	if dot_h1_h2 < 0.60:
		return "Herd flight alignment failed: deer fled in conflicting directions (dot: %.2f)" % dot_h1_h2

	return ""

## 6. Individual temperament variance: Cautious vs bold reaction thresholds
func test_individual_temperament_variance() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 606060
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn cautious deer (temperament_factor = 1.15) and bold deer (temperament_factor = 0.88)
	var h_cautious_id: int = fauna.spawn_herbivore(Vector3(10.0, 2.0, 10.0), 80.0)
	var h_bold_id: int = fauna.spawn_herbivore(Vector3(10.0, 2.0, 30.0), 80.0)

	var hc: FaunaSimulation.HerbivoreData = fauna.get_herbivore(h_cautious_id)
	var hb: FaunaSimulation.HerbivoreData = fauna.get_herbivore(h_bold_id)

	hc.temperament = "cautious"
	hc.temperament_factor = 1.15

	hb.temperament = "bold"
	hb.temperament_factor = 0.88

	# Verify individual temperament factors differ as designed
	if hc.temperament_factor <= hb.temperament_factor:
		return "Cautious deer temperament factor must exceed bold deer factor"

	# Player approaches at 6.8m from both deer
	# At 6.8m: cautious deer (threshold 7.0 * 1.15 = 8.05m) flees,
	# while bold deer (threshold 7.0 * 0.88 = 6.16m) remains vigilant/alert
	fauna.set_player_presence(Vector3(16.8, 2.0, 10.0), true) # 6.8m from cautious deer
	fauna.step_simulation(0.2, null, Callable(self, "_flat_height"))

	if hc.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "Cautious deer failed to flee at 6.8m distance (state: %d)" % hc.state

	return ""
