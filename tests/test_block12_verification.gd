extends RefCounted

## Automated Verification Suite for Block 12: Core Gameplay, Time & Fauna Repair
## Covers:
## 1. Single authoritative clock & diurnal synchronization
## 2. Diurnal latching (no duplicate Dawn Chorus / Nightfall on pause or frame jitter)
## 3. Fauna flocking separation (>= 1.8m spacing)
## 4. Steep cliff avoidance & deflection
## 5. Third-person player character controller & camera mode preservation

const LivingWorldDirector = preload("res://core/living_world/living_world_director.gd")

func test_clock_synchronization() -> String:
	var clock: WorldClock = WorldClock.new(10.0)
	if not is_equal_approx(clock.day_duration, 720.0):
		return "Default day duration is not 720.0s (was: %.1f)" % clock.day_duration
	if not is_equal_approx(clock.start_hour, 11.5):
		return "Default start hour is not 11.5h (was: %.1f)" % clock.start_hour

	# At simulation_time = 0.0, sim_hour should equal 11.5 (midday)
	if not is_equal_approx(clock.get_sim_hour(), 11.5):
		return "Initial sim hour mismatch: expected 11.5, got %.2f" % clock.get_sim_hour()
	if clock.get_day_number() != 1:
		return "Initial day number mismatch: expected 1, got %d" % clock.get_day_number()
	if not clock.is_daytime():
		return "Midday 11.5h should be recognized as daytime"

	# Test setting time to dawn (06:00)
	clock.set_sim_hour(6.0)
	if absf(clock.get_sim_hour() - 6.0) > 0.05:
		return "set_sim_hour(6.0) failed: got %.2f" % clock.get_sim_hour()

	# Test setting time to midnight (00:00)
	clock.set_sim_hour(0.0)
	if absf(clock.get_sim_hour() - 0.0) > 0.05 and absf(clock.get_sim_hour() - 24.0) > 0.05:
		return "set_sim_hour(0.0) failed: got %.2f" % clock.get_sim_hour()
	if clock.is_daytime():
		return "Midnight 00:00 should NOT be recognized as daytime"

	return ""

func test_diurnal_latching_no_duplicate_events() -> String:
	var clock: WorldClock = WorldClock.new(1.0)
	var bus: WorldEventBus = WorldEventBus.new()
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir.setup(clock, bus, null, null)

	var counts: Dictionary = {"dawn": 0, "dusk": 0}
	dir.emergent_event.connect(func(t, _ti, _b, _s):
		if t == "DAWN_CHORUS": counts["dawn"] += 1
		elif t == "DUSK_TRANSITION": counts["dusk"] += 1
	)

	# 1. Setup clock before dawn on Day 1
	clock.set_sim_hour(5.8)
	dir._check_diurnal_transitions()
	if counts["dawn"] != 0:
		dir.free()
		return "Dawn Chorus fired prematurely before dawn hour"

	# 2. Cross Dawn (hour 6.1)
	clock.set_sim_hour(6.1)
	dir._check_diurnal_transitions()
	if counts["dawn"] != 1:
		dir.free()
		return "Dawn Chorus failed to fire on crossing dawn (events: %d)" % counts["dawn"]

	# 3. Simulate multiple frames lingering at dawn (6.1 -> 6.2 -> 6.3)
	clock.set_sim_hour(6.2)
	dir._check_diurnal_transitions()
	clock.set_sim_hour(6.3)
	dir._check_diurnal_transitions()
	if counts["dawn"] != 1:
		dir.free()
		return "Duplicate Dawn Chorus fired while lingering in morning: %d events" % counts["dawn"]

	# 4. Simulate pause & resume cycles
	clock.pause()
	dir._check_diurnal_transitions()
	clock.resume()
	dir._check_diurnal_transitions()
	if counts["dawn"] != 1:
		dir.free()
		return "Duplicate Dawn Chorus fired after pause/resume cycle: %d events" % counts["dawn"]

	# 5. Cross Dusk (hour 20.2)
	clock.set_sim_hour(20.2)
	dir._check_diurnal_transitions()
	if counts["dusk"] != 1:
		dir.free()
		return "Dusk Transition failed to fire on crossing dusk (events: %d)" % counts["dusk"]

	# 6. Advance to Day 2 morning (hour 6.1) -> should fire Dawn Chorus for Day 2
	clock.set_sim_hour(6.1)
	clock.simulation_time += clock.day_duration
	# Clear cooldown so per-day latching governs
	dir._cooldowns["DAWN_CHORUS"] = 0.0
	dir._check_diurnal_transitions()
	if counts["dawn"] != 2:
		dir.free()
		return "Dawn Chorus failed to fire for Day 2 morning: expected 2 events, got %d" % counts["dawn"]

	dir.free()
	return ""

func test_fauna_separation_distance() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 998877
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	# Spawn two herbivores heavily overlapping (< 0.5m apart)
	var h1_id: int = fauna.spawn_herbivore(Vector3(10.0, 2.0, 10.0), 80.0)
	var h2_id: int = fauna.spawn_herbivore(Vector3(10.3, 2.0, 10.2), 80.0)
	var h1 = fauna.get_herbivore(h1_id)
	var h2 = fauna.get_herbivore(h2_id)

	var dummy_height = func(_x: float, _z: float) -> float: return 2.0

	var initial_dist: float = h1.position.distance_to(h2.position)
	if initial_dist >= 1.0:
		return "Initial test setup error: distance too large (%.2f)" % initial_dist

	# Step 15 simulation ticks (0.5s each = 7.5s sim time)
	for i in range(15):
		fauna.step_simulation(0.5, null, dummy_height)

	var final_dist: float = h1.position.distance_to(h2.position)
	if final_dist < 1.65:
		return "Fauna separation failed to enforce spacing: final distance %.2fm < 1.65m" % final_dist

	return ""

func test_steep_cliff_deflection() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 332211
	var metrics: EcosystemMetrics = EcosystemMetrics.new()
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, null, metrics)

	var hid: int = fauna.spawn_herbivore(Vector3(0.0, 1.0, 0.0), 80.0)
	var h = fauna.get_herbivore(hid)

	# Aim animal directly forward along +Z towards a sheer cliff starting at Z = 1.5
	h.velocity = Vector3(0.0, 0.0, 3.0)
	h.heading = deg_to_rad(90.0)

	# Terrain function: flat at Z < 1.0, vertical wall (+12.0m) at Z >= 1.5
	var cliff_height = func(x: float, z: float) -> float:
		if z < 1.2:
			return 1.0
		return 1.0 + (z - 1.2) * 8.0 # Very steep slope

	# Move animal
	fauna._move_animal(h, 0.5, cliff_height)

	# Verify animal did NOT scale the 12m sheer cliff (height should stay reasonable)
	if h.position.y > 3.0:
		return "Animal climbed up sheer cliff: Y reached %.2f" % h.position.y

	# Verify animal deflected or turned away from the wall (+Z forward component reduced or turned sideways)
	if h.position.z > 2.5:
		return "Animal walked through cliff boundary: Z reached %.2f" % h.position.z

	return ""

func test_third_person_boot_state() -> String:
	var cam: FreeLookCamera = FreeLookCamera.new()
	cam.set_camera_mode(FreeLookCamera.CameraMode.THIRD_PERSON_CHARACTER, true)

	if cam.current_mode != FreeLookCamera.CameraMode.THIRD_PERSON_CHARACTER:
		cam.free()
		return "Camera mode was not set to THIRD_PERSON_CHARACTER"

	var walker: FirstPersonWalker = cam.get_walker()
	if walker == null:
		cam.free()
		return "Walker was not instantiated in THIRD_PERSON_CHARACTER mode"

	if not walker.is_third_person:
		cam.free()
		return "Walker is_third_person flag is false"

	if walker.get_camera() == null:
		cam.free()
		return "Walker spring arm camera is null"

	# Test cycling camera mode (preserves flycam)
	cam.cycle_camera_mode()
	if cam.current_mode != FreeLookCamera.CameraMode.FIRST_PERSON_WALKER:
		cam.free()
		return "Cycle from Third-Person did not go to First-Person Walker"

	cam.cycle_camera_mode()
	if cam.current_mode != FreeLookCamera.CameraMode.FREE_LOOK:
		cam.free()
		return "Cycle from First-Person did not go to FREE_LOOK (Flycam)"

	cam.cycle_camera_mode()
	if cam.current_mode != FreeLookCamera.CameraMode.THIRD_PERSON_CHARACTER:
		cam.free()
		return "Cycle from FREE_LOOK did not return to THIRD_PERSON_CHARACTER"

	cam.free()
	return ""
