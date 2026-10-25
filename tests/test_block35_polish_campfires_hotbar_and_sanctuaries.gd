class_name TestBlock35PolishCampfiresHotbarAndSanctuaries
extends RefCounted

## Automated Contract Test Suite for Block 35:
## 1. Wilderness Campfire Structure, Warmth Aura, and Micro-Particles.
## 2. Bottom Ergonomic Tool Hotbar & Context Action HUD.
## 3. Nocturnal Wildlife Predator-Free Sanctuary & Circadian Sleep.

const WildernessTorchSystem = preload("res://presentation/tools/wilderness_torch_system.gd")
const PlayerToolController = preload("res://presentation/tools/player_tool_controller.gd")
const WorldHUD = preload("res://presentation/ui/hud.gd")
const FaunaSimulation = preload("res://core/ecosystem/fauna_simulation.gd")
const FloraSimulation = preload("res://core/ecosystem/flora_simulation.gd")
const EnvironmentalGrid = preload("res://core/environment/environmental_grid.gd")
const WorldGenerationConfig = preload("res://core/environment/world_generation_config.gd")

func run_all() -> int:
	var passed: int = 0
	passed += _test("test_campfire_placement_and_visual_elements", Callable(self, "test_campfire_placement_and_visual_elements"))
	passed += _test("test_campfire_water_immersion_and_extinguish", Callable(self, "test_campfire_water_immersion_and_extinguish"))
	passed += _test("test_torch_micro_particles_synchronization", Callable(self, "test_torch_micro_particles_synchronization"))
	passed += _test("test_fauna_sanctuary_gathering_and_circadian_sleep", Callable(self, "test_fauna_sanctuary_gathering_and_circadian_sleep"))
	passed += _test("test_predator_deterrence_and_sanctuary_protection", Callable(self, "test_predator_deterrence_and_sanctuary_protection"))
	passed += _test("test_player_tool_controller_campfire_and_hotkey", Callable(self, "test_player_tool_controller_campfire_and_hotkey"))
	passed += _test("test_hud_hotbar_and_contextual_action_guidance", Callable(self, "test_hud_hotbar_and_contextual_action_guidance"))
	return passed

func _test(test_name: String, callable: Callable) -> int:
	print("  [RUN] %s" % test_name)
	var err: String = callable.call()
	if err == "":
		print("  [PASS] %s" % test_name)
		return 1
	else:
		printerr("  [FAIL] %s: %s" % [test_name, err])
		return 0

func test_campfire_placement_and_visual_elements() -> String:
	var torch_sys: WildernessTorchSystem = WildernessTorchSystem.new()
	torch_sys._ready()

	var camp_pos: Vector3 = Vector3(15.0, 1.2, 10.0)
	var camp: Node3D = torch_sys.place_campfire_at(camp_pos)
	if camp == null:
		torch_sys.free()
		return "Failed to place campfire at target position"

	if not camp.get_meta("is_lit", false):
		torch_sys.free()
		return "Campfire is not marked as lit upon placement"

	if float(camp.get_meta("warmth_radius", 0.0)) != 7.0:
		torch_sys.free()
		return "Campfire warmth radius should be 7.0m"

	var omni: OmniLight3D = camp.get_meta("omni_ref", null) as OmniLight3D
	if omni == null or not omni.visible:
		torch_sys.free()
		return "Campfire OmniLight3D reference missing or invisible"

	# Hardware fillrate budget check for Iris Xe: must be shadow-free
	if omni.shadow_enabled != false:
		torch_sys.free()
		return "Campfire OmniLight3D must have shadow_enabled = false for fillrate budget"

	if omni.light_energy < 2.0 or omni.omni_range < 15.0:
		torch_sys.free()
		return "Campfire OmniLight3D range or energy below required illumination budget"

	# Verify micro-particles
	var sparks: CPUParticles3D = camp.get_meta("sparks_ref", null) as CPUParticles3D
	var smoke: CPUParticles3D = camp.get_meta("smoke_ref", null) as CPUParticles3D
	if sparks == null or not sparks.emitting or sparks.amount > 16:
		torch_sys.free()
		return "Campfire sparks missing, not emitting, or exceeded particle budget"
	if smoke == null or not smoke.emitting or smoke.amount > 12:
		torch_sys.free()
		return "Campfire smoke missing, not emitting, or exceeded particle budget"

	# Verify crackle audio player
	var audio: AudioStreamPlayer3D = camp.find_child("CampfireAudio", true, false) as AudioStreamPlayer3D
	if audio == null or audio.stream == null:
		torch_sys.free()
		return "Campfire crackle audio player or stream missing"

	# Check active lights list contains campfire
	var active_lights: Array[Vector3] = torch_sys.get_all_active_light_positions()
	if not active_lights.has(camp_pos):
		torch_sys.free()
		return "Active light positions does not contain placed campfire"

	torch_sys.free()
	return ""

func test_campfire_water_immersion_and_extinguish() -> String:
	var torch_sys: WildernessTorchSystem = WildernessTorchSystem.new()
	torch_sys._ready()
	torch_sys.setup(null, null, null, null, null, 2.0)

	# Place campfire submerged in water (Y = 1.8 < water 2.0 + 0.35)
	var submerged_pos: Vector3 = Vector3(4.0, 1.8, 4.0)
	var camp: Node3D = torch_sys.place_campfire_at(submerged_pos)
	if camp == null:
		torch_sys.free()
		return "Failed to place campfire"

	# Process simulation step to trigger water immersion extinguishment
	torch_sys._process(0.1)

	if camp.get_meta("is_lit", true) != false:
		torch_sys.free()
		return "Campfire remained lit despite being submerged below water level threshold"

	var omni: OmniLight3D = camp.get_meta("omni_ref", null) as OmniLight3D
	if omni != null and omni.visible:
		torch_sys.free()
		return "OmniLight3D remained visible on extinguished campfire"

	var sparks: CPUParticles3D = camp.get_meta("sparks_ref", null) as CPUParticles3D
	if sparks != null and sparks.emitting:
		torch_sys.free()
		return "Sparks remained emitting on extinguished campfire"

	torch_sys.free()
	return ""

func test_torch_micro_particles_synchronization() -> String:
	var torch_sys: WildernessTorchSystem = WildernessTorchSystem.new()
	torch_sys._ready()

	torch_sys.equip_held_torch()
	if torch_sys._held_sparks == null or not torch_sys._held_sparks.emitting:
		torch_sys.free()
		return "Held torch sparks not emitting when equipped"
	if torch_sys._held_smoke == null or not torch_sys._held_smoke.emitting:
		torch_sys.free()
		return "Held torch smoke not emitting when equipped"

	# Extinguish
	torch_sys.extinguish_held_torch("water")
	if torch_sys._held_sparks.emitting:
		torch_sys.free()
		return "Held torch sparks continued emitting when extinguished"
	if torch_sys._held_smoke.emitting:
		torch_sys.free()
		return "Held torch smoke continued emitting when extinguished"

	# Reignite
	torch_sys.reignite_held_torch()
	if not torch_sys._held_sparks.emitting or not torch_sys._held_smoke.emitting:
		torch_sys.free()
		return "Held torch particles failed to restart on reignite"

	torch_sys.free()
	return ""

func test_fauna_sanctuary_gathering_and_circadian_sleep() -> String:
	var fauna: FaunaSimulation = FaunaSimulation.new()
	var fire_pos: Vector3 = Vector3(10.0, 1.0, 10.0)
	fauna.register_light_source(fire_pos)

	# Spawn deer in sanctuary perimeter (5m away from fire)
	var deer_pos: Vector3 = fire_pos + Vector3(5.0, 0.0, 0.0)
	var hid: int = fauna.spawn_herbivore(deer_pos, 85.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)
	if h == null:
		return "Failed to spawn herbivore"

	var height_fn: Callable = Callable(func(_x: float, _z: float) -> float: return 1.0)

	# Deep night (sim_hour = 2.0): Deer should rest & deep sleep inside sanctuary
	fauna.step_simulation(0.2, null, height_fn, null, 2.0)
	if not h.is_in_sanctuary:
		return "Herbivore within 5m of fire did not enter sanctuary at night"
	if h.state != FaunaSimulation.HerbivoreState.RESTING:
		return "Herbivore in sanctuary should be in RESTING state, was: %d" % h.state
	if not h.is_sleeping:
		return "Herbivore in sanctuary during deep night (02:00) should be sleeping"

	# Daytime (sim_hour = 12.0): Sanctuary mode and sleep should clear
	fauna.step_simulation(0.2, null, height_fn, null, 12.0)
	if h.is_in_sanctuary:
		return "Herbivore should exit sanctuary during daytime"
	if h.is_sleeping:
		return "Herbivore should wake up during daytime"

	return ""

func test_predator_deterrence_and_sanctuary_protection() -> String:
	var fauna: FaunaSimulation = FaunaSimulation.new()
	var fire_pos: Vector3 = Vector3(0.0, 1.0, 0.0)
	fauna.register_light_source(fire_pos)

	# 1. Predator near fire should be repelled by fire
	var stalker_pos: Vector3 = fire_pos + Vector3(6.0, 0.0, 0.0)
	var pid: int = fauna.spawn_predator(stalker_pos, 80.0)
	var p: FaunaSimulation.PredatorData = fauna.get_predator(pid)
	if p == null:
		return "Failed to spawn predator"

	var height_fn: Callable = Callable(func(_x: float, _z: float) -> float: return 1.0)
	fauna.step_simulation(0.2, null, height_fn, null, 22.0)

	if not p.is_deterred_by_fire:
		return "Predator within 6m of active fire was not deterred by fire"

	# 2. Sanctuary herbivore protection: predator cannot target herbivore in sanctuary
	var deer_pos: Vector3 = fire_pos + Vector3(4.5, 0.0, 0.0)
	var hid: int = fauna.spawn_herbivore(deer_pos, 85.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)
	h.is_in_sanctuary = true

	var targeted_prey: FaunaSimulation.HerbivoreData = fauna._find_nearest_herbivore(p.position, 25.0)
	if targeted_prey != null:
		return "Predator was able to target a herbivore safely resting inside fire sanctuary"

	return ""

func test_player_tool_controller_campfire_and_hotkey() -> String:
	var ptc: PlayerToolController = PlayerToolController.new()
	ptc._ready()

	# Test hotkey KEY_8 sets tool to TORCH
	var event_8: InputEventKey = InputEventKey.new()
	event_8.pressed = true
	event_8.keycode = KEY_8
	ptc._unhandled_input(event_8)

	if ptc.active_tool != PlayerToolController.ToolMode.TORCH:
		ptc.free()
		return "Pressing KEY_8 did not select ToolMode.TORCH, was: %d" % ptc.active_tool

	# Verify tool name
	var tool_name: String = ptc.get_tool_name(ptc.active_tool)
	if not tool_name.contains("Torch"):
		ptc.free()
		return "Torch tool name did not contain 'Torch': %s" % tool_name

	ptc.free()
	return ""

func test_hud_hotbar_and_contextual_action_guidance() -> String:
	var hud: WorldHUD = WorldHUD.new()
	hud._ready()

	if hud._hotbar_buttons.size() < 8:
		var count: int = hud._hotbar_buttons.size()
		hud.free()
		return "HUD bottom hotbar has fewer than 8 quick slots, found: %d" % count

	if hud._tool_context_label == null:
		hud.free()
		return "HUD contextual tool action label is missing"

	# Switch tool to TORCH and verify contextual hint updates
	hud._on_tool_changed(PlayerToolController.ToolMode.TORCH, "Torch")
	var hint: String = hud._tool_context_label.text
	if not hint.contains("Campfire") or not hint.contains("Controlled Ash Burn"):
		hud.free()
		return "Contextual action hint for TORCH missing key instructions: %s" % hint

	# Switch tool to INSPECT and verify contextual hint updates
	hud._on_tool_changed(PlayerToolController.ToolMode.INSPECT, "Inspect")
	hint = hud._tool_context_label.text
	if not hint.contains("Inspect"):
		hud.free()
		return "Contextual action hint for INSPECT did not mention Inspect: %s" % hint

	hud.free()
	return ""
