class_name TestBlock59GrizzlyHydroPuzzleAndLighting
extends RefCounted

## Unit & Integration Test Suite 59:
## Exquisite Lighting Pipeline, Legendary Grizzly Patriarch & Hydro Lake Sanctuary Puzzle (Block 59)

const DayNightCycleScript = preload("res://presentation/environment/day_night_cycle.gd")
const LegendaryGrizzlyPatriarchScript = preload("res://presentation/fauna/legendary_grizzly_patriarch.gd")
const HydroLakeSanctuaryPuzzleScript = preload("res://presentation/environment/hydro_lake_sanctuary_puzzle.gd")
const CircularMinimapHUDScript = preload("res://presentation/ui/circular_minimap_hud.gd")

func test_exquisite_lighting_pipeline_calibration() -> bool:
	var cycle: DayNightCycle = DayNightCycleScript.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	var env_node: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	var sky: Sky = Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env_node.environment = env

	cycle.setup(null, sun, env_node, null)

	# Verify ACES Tonemapper
	if env.tonemap_mode != Environment.TONE_MAPPER_ACES:
		push_error("Expected ACES tonemap mode (3), got: %d" % env.tonemap_mode)
		return false
	if not is_equal_approx(env.tonemap_exposure, 0.96):
		push_error("Expected tonemap exposure 0.96, got: %f" % env.tonemap_exposure)
		return false

	# Verify Softlight Bloom & Glow
	if not env.glow_enabled:
		push_error("Expected glow to be enabled")
		return false
	if env.glow_blend_mode != Environment.GLOW_BLEND_MODE_SOFTLIGHT:
		push_error("Expected GLOW_BLEND_MODE_SOFTLIGHT (2), got: %d" % env.glow_blend_mode)
		return false
	if not is_equal_approx(env.glow_bloom, 0.08):
		push_error("Expected glow bloom 0.08, got: %f" % env.glow_bloom)
		return false

	# Verify Cinematic Color Grading
	if not env.adjustment_enabled:
		push_error("Expected adjustment to be enabled")
		return false
	if not is_equal_approx(env.adjustment_saturation, 1.04):
		push_error("Expected adjustment saturation 1.04, got: %f" % env.adjustment_saturation)
		return false
	if not is_equal_approx(env.adjustment_contrast, 1.04):
		push_error("Expected adjustment contrast 1.04, got: %f" % env.adjustment_contrast)
		return false

	# Verify Presets apply calibrated ambient light
	cycle.set_midday()
	if not is_equal_approx(env.ambient_light_energy, 0.72):
		push_error("Expected midday ambient energy 0.72, got: %f" % env.ambient_light_energy)
		return false

	cycle.set_golden_hour()
	if not is_equal_approx(env.ambient_light_energy, 0.64):
		push_error("Expected golden hour ambient energy 0.64, got: %f" % env.ambient_light_energy)
		return false

	cycle.free()
	sun.free()
	env_node.free()
	return true

func test_legendary_grizzly_patriarch_model_and_hierarchy() -> bool:
	var bear = LegendaryGrizzlyPatriarchScript.new()
	if bear == null:
		push_error("Failed to instantiate LegendaryGrizzlyPatriarch")
		return false

	if bear._body_pivot == null or bear._torso_mesh == null or bear._hump_mesh == null:
		push_error("Bear body, torso, or hump mesh missing")
		bear.free()
		return false

	if bear._head_pivot == null or bear._snout_mesh == null:
		push_error("Bear head or snout missing")
		bear.free()
		return false

	if bear._legs.size() != 4:
		push_error("Expected 4 legs, got: %d" % bear._legs.size())
		bear.free()
		return false

	if bear._frost_breath == null:
		push_error("Bear frost breath particle system missing")
		bear.free()
		return false

	bear.free()
	return true

func test_legendary_grizzly_patriarch_fsm_and_audio() -> bool:
	var bear = LegendaryGrizzlyPatriarchScript.new()
	if bear.current_state != LegendaryGrizzlyPatriarchScript.BearState.PROWLING:
		push_error("Expected initial state to be PROWLING")
		bear.free()
		return false

	# Audio stream validation
	if bear._roar_wav == null:
		push_error("Procedural roar WAV was not synthesized")
		bear.free()
		return false
	if bear._roar_wav.format != AudioStreamWAV.FORMAT_16_BITS:
		push_error("Expected 16-bit WAV format")
		bear.free()
		return false

	var roared: Array[bool] = [false]
	bear.roar_emitted.connect(func(_pos): roared[0] = true)
	bear._transition_to_state(LegendaryGrizzlyPatriarchScript.BearState.TERRITORIAL_ROAR)

	if bear.current_state != LegendaryGrizzlyPatriarchScript.BearState.TERRITORIAL_ROAR:
		push_error("Failed state transition to TERRITORIAL_ROAR")
		bear.free()
		return false
	if not roared[0]:
		push_error("roar_emitted signal was not emitted")
		bear.free()
		return false

	bear.free()
	return true

func test_legendary_grizzly_patriarch_photography_interaction() -> bool:
	var bear = LegendaryGrizzlyPatriarchScript.new()
	bear.position = Vector3(-135.0, 72.0, -130.0)

	# Distance checks
	if not bear.is_player_near(Vector3(-133.0, 72.0, -128.0)):
		push_error("Expected player at (-133, 72, -128) to be near bear")
		bear.free()
		return false
	if bear.is_player_near(Vector3(0.0, 52.0, 0.0)):
		push_error("Expected player at (0, 52, 0) to be far from bear")
		bear.free()
		return false

	# Wildlife Photo Reward
	var photo_reward: Array[Dictionary] = []
	bear.photo_taken.connect(func(r): photo_reward.append(r))
	var res: Dictionary = bear.take_wildlife_photo()

	if res.get("exp", 0) != 350 or res.get("coins", 0) != 120 or res.get("item", "") != "grizzly_silver_claw":
		push_error("Unexpected photo reward: %s" % str(res))
		bear.free()
		return false
	if photo_reward.size() != 1:
		push_error("photo_taken signal was not emitted")
		bear.free()
		return false

	bear.free()
	return true

func test_hydro_lake_sanctuary_puzzle_activation_sequence() -> bool:
	var puzzle = HydroLakeSanctuaryPuzzleScript.new()

	if puzzle.seal_positions.size() != 3:
		push_error("Expected 3 seal positions, got: %d" % puzzle.seal_positions.size())
		puzzle.free()
		return false

	if puzzle.get_total_active_seals() != 0:
		push_error("Expected 0 initial active seals")
		puzzle.free()
		return false

	# Activate seal 0
	puzzle.activate_seal(0)
	if puzzle.get_total_active_seals() != 1 or puzzle.is_spout_active:
		push_error("Seal 0 activation failed or spout prematurely erupted")
		puzzle.free()
		return false

	# Activate seal 1
	puzzle.activate_seal(1)
	if puzzle.get_total_active_seals() != 2 or puzzle.is_spout_active:
		push_error("Seal 1 activation failed")
		puzzle.free()
		return false

	# Activate seal 2 -> triggers spout eruption
	var spout_signaled: Array[bool] = [false]
	puzzle.spout_erupted.connect(func(_pos): spout_signaled[0] = true)
	puzzle.activate_seal(2)

	if puzzle.get_total_active_seals() != 3 or not puzzle.is_spout_active:
		push_error("Expected all 3 seals active and spout active")
		puzzle.free()
		return false
	if not spout_signaled[0]:
		push_error("spout_erupted signal was not received")
		puzzle.free()
		return false

	puzzle.free()
	return true

func test_hydro_spout_launch_and_luxurious_chest_rewards() -> bool:
	var puzzle = HydroLakeSanctuaryPuzzleScript.new()
	puzzle.activate_seal(0)
	puzzle.activate_seal(1)
	puzzle.activate_seal(2)

	# Mock Character Walker Node
	var mock_walker: CharacterBody3D = CharacterBody3D.new()
	mock_walker.velocity = Vector3.ZERO

	var launch_signaled: Array[bool] = [false]
	puzzle.player_launched.connect(func(_v): launch_signaled[0] = true)

	# Near water spout base
	var launched: bool = puzzle.check_player_launch(puzzle.SPOUT_CENTER + Vector3(0.5, 0.5, 0.5), mock_walker)
	if not launched or not launch_signaled[0]:
		push_error("Expected player near spout base to be launched skyward")
		mock_walker.free()
		puzzle.free()
		return false

	var vel: Vector3 = mock_walker.velocity
	if vel.y < 26.0:
		push_error("Expected upward velocity >= 26.0, got: %f" % vel.y)
		mock_walker.free()
		puzzle.free()
		return false

	# Check Luxurious Island Chest on islet
	if not puzzle.is_player_near_chest(puzzle.ISLET_CENTER + Vector3(0.5, 0.5, 0.5)):
		push_error("Expected player on islet to be near luxurious chest")
		mock_walker.free()
		puzzle.free()
		return false

	var chest_reward: Array[Dictionary] = []
	puzzle.luxurious_chest_opened.connect(func(r): chest_reward.append(r))
	var c_res: Dictionary = puzzle.open_luxurious_chest()

	if c_res.get("exp", 0) != 500 or c_res.get("coins", 0) != 200 or c_res.get("item", "") != "hydro_heart_pearl":
		push_error("Unexpected chest reward: %s" % str(c_res))
		mock_walker.free()
		puzzle.free()
		return false
	if not puzzle.is_chest_opened or chest_reward.size() != 1:
		push_error("Chest open state or signal failure")
		mock_walker.free()
		puzzle.free()
		return false

	mock_walker.free()
	puzzle.free()
	return true
