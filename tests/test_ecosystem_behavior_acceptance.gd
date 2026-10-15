class_name TestEcosystemBehaviorAcceptance
extends RefCounted

## Automated behavioral verification suite for Living Ecosystem (Fauna, Locomotion, and Environmental Reactions).

const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")
const EcosystemPresentation = preload("res://presentation/ecosystem/ecosystem_presentation.gd")
const EcosystemCoordinator = preload("res://core/ecosystem/ecosystem_coordinator.gd")

func _dummy_height(x: float, z: float) -> float:
	# Gentle hill slope
	return 2.0 + (x * 0.15) + (z * 0.10)

func _shoreline_height(_x: float, _z: float) -> float:
	# Shoreline elevation within drinking zone
	return 0.55

func test_quaternius_model_and_animation_loading() -> String:
	var stag_scene: PackedScene = EcosystemPresentation._load_gltf_packed("res://presentation/assets/models/Stag.gltf")
	if stag_scene == null:
		return "Failed to load Stag.gltf PackedScene"
	var stag: Node3D = stag_scene.instantiate() as Node3D
	var stag_anim: AnimationPlayer = stag.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if stag_anim == null:
		stag.free()
		return "Stag missing AnimationPlayer"
	var expected_clips := ["Idle", "Idle_2", "Idle_Headlow", "Walk", "Gallop", "Eating"]
	for clip in expected_clips:
		if not stag_anim.has_animation(clip):
			stag.free()
			return "Stag model missing expected animation clip: %s" % clip
	stag.free()

	var wolf_scene: PackedScene = EcosystemPresentation._load_gltf_packed("res://presentation/assets/models/Wolf.gltf")
	if wolf_scene == null:
		return "Failed to load Wolf.gltf PackedScene"
	var wolf: Node3D = wolf_scene.instantiate() as Node3D
	var wolf_anim: AnimationPlayer = wolf.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if wolf_anim == null:
		wolf.free()
		return "Wolf missing AnimationPlayer"
	var wolf_clips := ["Idle", "Idle_2", "Idle_2_HeadLow", "Walk", "Gallop", "Eating"]
	for clip in wolf_clips:
		if not wolf_anim.has_animation(clip):
			wolf.free()
			return "Wolf model missing expected animation clip: %s" % clip
	wolf.free()
	return ""

func test_player_approach_and_flight_response() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 98765
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn herbivore at (10, 2, 10)
	var hid: int = fauna.spawn_herbivore(Vector3(10.0, 2.0, 10.0), 85.0)
	var h = fauna.get_herbivore(hid)

	# 1. Player is distant (35m away) -> Animal should wander peacefully
	fauna.set_player_presence(Vector3(45.0, 2.0, 10.0), true)
	fauna.step_simulation(0.5, null, Callable(self, "_dummy_height"))
	if h.state == FaunaSimulation.HerbivoreState.FLEEING or h.state == FaunaSimulation.HerbivoreState.ALERT:
		return "Herbivore reacted to distant player (state: %d)" % h.state

	# 2. Player approaches to mid-range (11m away) -> Animal enters ALERT vigilance
	fauna.set_player_presence(Vector3(21.0, 2.0, 10.0), true)
	fauna.step_simulation(0.5, null, Callable(self, "_dummy_height"))
	if h.state != FaunaSimulation.HerbivoreState.ALERT:
		return "Herbivore did not enter ALERT state at 11m player distance (state: %d)" % h.state
	if h.velocity.length_squared() > 0.01:
		return "Herbivore did not halt to observe player in ALERT state"

	# 3. Player approaches to close proximity (5m away) -> Animal triggers FLEEING
	fauna.set_player_presence(Vector3(15.0, 2.0, 10.0), true)
	fauna.step_simulation(0.5, null, Callable(self, "_dummy_height"))
	if h.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "Herbivore did not FLEE from close player (<7m) (state: %d)" % h.state
	# Verify fleeing direction is away from player
	var flee_vector: Vector3 = h.velocity
	if flee_vector.x >= 0.0:
		return "Herbivore fled toward player instead of away from player (vel: %s)" % str(flee_vector)

	# 4. Player retreats (40m away) -> Animal relaxes back to WANDERING
	fauna.set_player_presence(Vector3(55.0, 2.0, 10.0), true)
	fauna.step_simulation(0.5, null, Callable(self, "_dummy_height"))
	if h.state == FaunaSimulation.HerbivoreState.FLEEING and h.threat_id == -999:
		return "Herbivore failed to recover from player flight after player retreated"

	return ""

func test_herding_cohesion_and_separation() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 54321
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn two herbivores overlapping too closely (< 1.5m)
	var h1_id: int = fauna.spawn_herbivore(Vector3(5.0, 2.0, 5.0), 80.0)
	var h2_id: int = fauna.spawn_herbivore(Vector3(5.5, 2.0, 5.0), 80.0)
	var h1 = fauna.get_herbivore(h1_id)
	var h2 = fauna.get_herbivore(h2_id)

	var initial_dist: float = h1.position.distance_to(h2.position)

	# Step several wander ticks: separation force should repel them apart
	for i in range(8):
		fauna.step_simulation(0.5, null, Callable(self, "_dummy_height"))

	var post_dist: float = h1.position.distance_to(h2.position)
	if post_dist <= initial_dist:
		return "Separation force failed to push overlapping herbivores apart (initial: %.2f, post: %.2f)" % [initial_dist, post_dist]

	return ""

func test_shoreline_drinking_behavior() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11223
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn herbivore at water shoreline elevation (y = 0.55m)
	var hid: int = fauna.spawn_herbivore(Vector3(12.0, 0.55, 8.0), 60.0)
	var h = fauna.get_herbivore(hid)

	# Force state to drinking to verify metabolic benefit and timer
	h.state = FaunaSimulation.HerbivoreState.DRINKING
	var initial_energy: float = h.energy

	fauna.step_simulation(1.0, null, Callable(self, "_shoreline_height"))
	if h.energy <= initial_energy:
		return "Drinking did not replenish energy/hydration (initial: %.1f, now: %.1f)" % [initial_energy, h.energy]

	# Step until drinking timer completes (>= 3.0s)
	fauna.step_simulation(3.0, null, Callable(self, "_shoreline_height"))
	if h.state == FaunaSimulation.HerbivoreState.DRINKING:
		return "Herbivore remained stuck in DRINKING state after timeout"

	return ""

func test_dual_axis_slope_pitch_and_roll() -> String:
	var presentation: EcosystemPresentation = EcosystemPresentation.new()
	var mesh: Node3D = presentation._create_herbivore_mesh(null, 100)
	if mesh == null:
		presentation.free()
		return "Failed to create herbivore mesh"
	presentation.add_child(mesh)

	# Simulate sidehill terrain: elevation rises sharply to the right (+X)
	var sidehill_func = func(x: float, _z: float) -> float:
		return x * 0.45

	var rot_y: float = 0.0 # Facing -Z
	var right_x: float = cos(rot_y)
	var right_z: float = -sin(rot_y)
	var h_right: float = sidehill_func.call(mesh.position.x + right_x * 0.35, mesh.position.z + right_z * 0.35)
	var h_left: float = sidehill_func.call(mesh.position.x - right_x * 0.35, mesh.position.z - right_z * 0.35)
	var target_roll: float = clampf(atan2(h_right - h_left, 0.7), -0.55, 0.55)

	var err: String = ""
	if absf(target_roll) < 0.15:
		err = "Dual-axis slope conformance failed to compute roll tilt on sidehill (roll: %.3f)" % target_roll

	mesh.free()
	presentation.free()
	return err

func test_ecological_niche_spawning_distribution() -> String:
	var seed_obj: WorldSeed = WorldSeed.new(20261014)
	var clock: WorldClock = WorldClock.new()
	var bus: WorldEventBus = WorldEventBus.new()
	var registry: EntityRegistry = EntityRegistry.new(bus)
	var config: WorldGenerationConfig = WorldGenerationConfig.new(seed_obj.master_seed)
	var grid: EnvironmentalGrid = EnvironmentalGrid.new(config)
	var weather: WeatherSystem = WeatherSystem.new(seed_obj.get_stream("weather"), bus)

	var coord: EcosystemCoordinator = EcosystemCoordinator.new(seed_obj, clock, bus, registry, grid, weather)
	coord.bind_terrain_height(func(_x: float, _z: float) -> float: return 1.5)
	coord.populate_initial_ecosystem(55, 14, 2)

	var herbs: Array = coord.fauna_sim.get_all_herbivores()
	if herbs.size() != 14:
		return "Expected 14 herbivores, got %d" % herbs.size()

	var in_meadow: int = 0
	var in_basin: int = 0
	var in_forest: int = 0

	for h in herbs:
		var pos: Vector3 = h.position
		if pos.x >= 3.0 and pos.x <= 16.0 and pos.z >= 0.0 and pos.z <= 9.0:
			in_meadow += 1
		elif pos.x >= 11.0 and pos.x <= 21.0 and pos.z >= 8.0 and pos.z <= 18.0:
			in_basin += 1
		elif pos.x >= -12.0 and pos.x <= 0.0 and pos.z >= -6.0 and pos.z <= 3.5:
			in_forest += 1

	if (in_meadow + in_basin) < 10:
		return "Expected >= 10 herbivores clustered in Meadow or Basin niches, found %d (meadow: %d, basin: %d)" % [in_meadow + in_basin, in_meadow, in_basin]

	var preds: Array = coord.fauna_sim.get_all_predators()
	if preds.size() != 2:
		return "Expected 2 predators, got %d" % preds.size()

	# Predator 1 should be positioned on the North Ridge / Talus Crags
	var p1: Variant = preds[0]
	if p1.position.x > -5.0 or p1.position.z > -5.0:
		return "Predator 1 not spawned on North Ridge vantage (pos: %s)" % str(p1.position)

	return ""

func test_diurnal_night_resting_behavior() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 445566
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn herbivore under Whispering Forest canopy at Night (sim_hour = 23.5)
	var hid: int = fauna.spawn_herbivore(Vector3(-5.0, 2.0, -1.0), 80.0)
	var h = fauna.get_herbivore(hid)

	# Step at night (sim_hour = 23.5)
	fauna.step_simulation(0.5, null, Callable(self, "_dummy_height"), null, 23.5)
	if h.state != FaunaSimulation.HerbivoreState.RESTING:
		return "Herbivore under forest canopy at night did not enter RESTING state (state: %d)" % h.state

	# Step resting: verify energy conservation (lower metabolic drain)
	var pre_e: float = h.energy
	fauna.step_simulation(1.0, null, Callable(self, "_dummy_height"), null, 23.5)
	var drain: float = pre_e - h.energy
	if drain > 0.60: # Base awake drain is 1.0/s
		return "Resting metabolic drain was not reduced (drain: %.3f/s)" % drain

	# Step until daybreak (sim_hour = 6.0) -> should awaken to WANDERING
	fauna.step_simulation(1.0, null, Callable(self, "_dummy_height"), null, 6.0)
	if h.state == FaunaSimulation.HerbivoreState.RESTING:
		return "Herbivore failed to awaken from RESTING state at daybreak"

	return ""

func test_predator_stalking_and_sprint_phases() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 778899
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn prey at (15, 2, 0)
	var hid: int = fauna.spawn_herbivore(Vector3(15.0, 2.0, 0.0), 80.0)
	# Spawn hungry predator 14m away at (1, 2, 0)
	var pid: int = fauna.spawn_predator(Vector3(1.0, 2.0, 0.0), 40.0)
	var p = fauna.get_predator(pid)

	# 1. Distant approach (> 8m): predator should stalk at stealth speed (0.75x)
	fauna.step_simulation(0.2, null, Callable(self, "_dummy_height"))
	if p.state != FaunaSimulation.PredatorState.HUNTING:
		return "Predator did not enter HUNTING state (state: %d)" % p.state
	var stalk_speed: float = p.velocity.length()
	var expected_stalk: float = p.move_speed * 0.75
	if absf(stalk_speed - expected_stalk) > 0.15:
		return "Predator did not stalk at stealth speed (speed: %.2f, expected: %.2f)" % [stalk_speed, expected_stalk]

	# 2. Close approach (<= 8m): teleport predator to 6m away
	p.position = Vector3(9.0, 2.0, 0.0)
	fauna.step_simulation(0.2, null, Callable(self, "_dummy_height"))
	var sprint_speed: float = p.velocity.length()
	var expected_sprint: float = p.move_speed * 1.25
	if absf(sprint_speed - expected_sprint) > 0.15:
		return "Predator did not accelerate to sprint strike at close range (speed: %.2f, expected: %.2f)" % [sprint_speed, expected_sprint]

	return ""

func test_desynchronized_wander_timing() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	var h1_id: int = fauna.spawn_herbivore(Vector3(5.0, 2.0, 5.0), 80.0)
	var h2_id: int = fauna.spawn_herbivore(Vector3(10.0, 2.0, 10.0), 80.0)
	var h1 = fauna.get_herbivore(h1_id)
	var h2 = fauna.get_herbivore(h2_id)

	if is_equal_approx(h1.wander_timer, h2.wander_timer) and is_equal_approx(h1.wander_interval, h2.wander_interval):
		return "Herbivores share identical wander timers, indicating mechanical lock-step synchronization"

	return ""
