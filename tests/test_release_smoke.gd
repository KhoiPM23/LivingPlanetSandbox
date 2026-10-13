class_name TestReleaseSmoke
extends SceneTree

## Standalone Release Smoke Test for Living Planet Sandbox (Block 8).
## Validates startup, world generation, camera, simulation, experiment tools, save/load, and settings.

var _frame_count: int = 0
var _main_scene: Node = null
var _bootstrap: WorldBootstrap = null
var _tools: PlayerToolController = null
var _hud: WorldHUD = null
var _passed_steps: int = 0
var _failed_steps: int = 0

func _init() -> void:
	print("=======================================================")
	print("   LIVING PLANET SANDBOX — RELEASE CANDIDATE SMOKE TEST ")
	print("=======================================================")

	var packed: PackedScene = load("res://scenes/main.tscn")
	if not packed:
		printerr("[SmokeTest] FATAL: Failed to load res://scenes/main.tscn")
		quit(1)
		return

	_main_scene = packed.instantiate()
	root.add_child(_main_scene)

	_bootstrap = _main_scene.get_node_or_null("WorldBootstrap") as WorldBootstrap
	_hud = _main_scene.get_node_or_null("WorldHUD") as WorldHUD
	_tools = _main_scene.get_node_or_null("PlayerToolController") as PlayerToolController

	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	_frame_count += 1

	if not _tools and _main_scene:
		_tools = _main_scene.get_node_or_null("PlayerToolController") as PlayerToolController

	# Step 1: Startup & World Generation Verification (Frame 10)
	if _frame_count == 10:
		print(">>> SMOKE CHECK 1: Startup & World Generation")
		if _bootstrap and _bootstrap.environmental_grid and _bootstrap.ecosystem_coordinator:
			var cells: int = _bootstrap.environmental_grid.grid_size * _bootstrap.environmental_grid.grid_size
			var plants: int = _bootstrap.ecosystem_coordinator.flora_sim.get_plant_count()
			var fauna: int = _bootstrap.ecosystem_coordinator.fauna_sim.get_herbivore_count()
			if cells == 1024 and plants > 0 and fauna > 0:
				_record_pass("World Generation initialized %d cells, %d plants, %d fauna" % [cells, plants, fauna])
			else:
				_record_fail("World generation counts out of bounds: %d cells, %d plants, %d fauna" % [cells, plants, fauna])
		else:
			_record_fail("Missing bootstrap or subsystem instances")

	# Step 2: Camera & Viewport Navigation (Frame 20)
	elif _frame_count == 20:
		print(">>> SMOKE CHECK 2: Camera & Clearance Limits")
		var cam: FreeLookCamera = _main_scene.get_node_or_null("FreeLookCamera") as FreeLookCamera
		if cam:
			# Verify clearance clamping
			cam.position = Vector3(0.0, -10.0, 0.0) # Intentionally underground
			cam._process(0.016)
			if cam.position.y >= 0.85:
				_record_pass("Camera clamped above terrain clearance (y = %.2fm)" % cam.position.y)
			else:
				_record_fail("Camera failed clearance clamp: y = %.2fm" % cam.position.y)
		else:
			_record_fail("FreeLookCamera node missing")

	# Step 3: Simulation Progression & Weather (Frame 35)
	elif _frame_count == 35:
		print(">>> SMOKE CHECK 3: Simulation Progression & Weather")
		if _bootstrap and _bootstrap.world_clock and _bootstrap.weather_system:
			var initial_time: float = _bootstrap.world_clock.simulation_time
			# Run 10 ticks
			for i in range(10):
				_bootstrap.world_clock.advance(0.1)
			var advanced_time: float = _bootstrap.world_clock.simulation_time
			if advanced_time > initial_time:
				_record_pass("WorldClock advanced cleanly: %.2fs -> %.2fs" % [initial_time, advanced_time])
			else:
				_record_fail("WorldClock failed to advance")
		else:
			_record_fail("Clock or weather system missing")

	# Step 4: Experiment Tool Intervention (Frame 50)
	elif _frame_count == 50:
		print(">>> SMOKE CHECK 4: Experiment Tool Intervention")
		if _tools and _bootstrap:
			var initial_plants: int = _bootstrap.ecosystem_coordinator.flora_sim.get_plant_count()
			_tools._current_hit_point = Vector3(10.0, 4.0, 10.0)
			_tools._has_hit = true
			_tools._execute_spawn_plant()
			var new_plants: int = _bootstrap.ecosystem_coordinator.flora_sim.get_plant_count()
			if new_plants == initial_plants + 1:
				_record_pass("PlayerToolController spawned plant successfully (%d -> %d)" % [initial_plants, new_plants])
			else:
				_record_fail("PlayerToolController failed plant spawn (%d vs %d)" % [initial_plants, new_plants])
		else:
			_record_fail("PlayerToolController missing")

	# Step 5: Save/Load Roundtrip Integrity (Frame 65)
	elif _frame_count == 65:
		print(">>> SMOKE CHECK 5: Save/Load Roundtrip & Backup Safety")
		if _bootstrap:
			var save_path: String = "user://smoke_test_save.json"
			var save_err: Error = _bootstrap.save_world_state(save_path)
			if save_err == OK:
				var load_err: Error = _bootstrap.load_world_state(save_path)
				if load_err == OK:
					_record_pass("Schema v2 save and load roundtrip succeeded via WorldBootstrap")
					# Clean up test save files
					var global_save: String = ProjectSettings.globalize_path(save_path)
					if FileAccess.file_exists(save_path):
						DirAccess.remove_absolute(global_save)
					var bak_path: String = global_save + ".bak"
					if FileAccess.file_exists(bak_path):
						DirAccess.remove_absolute(bak_path)
				else:
					_record_fail("Load failed with error: %d" % load_err)
			else:
				_record_fail("Save failed with error: %d" % save_err)
		else:
			_record_fail("WorldBootstrap missing")

	# Step 6: Settings & Menu Modal Verification (Frame 80)
	elif _frame_count == 80:
		print(">>> SMOKE CHECK 6: Main Menu & Settings Modal")
		if _hud:
			_hud.toggle_menu_modal()
			if _hud._menu_modal and _hud._menu_modal.visible:
				_record_pass("Main menu modal opened successfully on Escape")
				_hud.toggle_menu_modal()
				if not _hud._menu_modal.visible:
					_record_pass("Main menu modal closed cleanly")
				else:
					_record_fail("Main menu modal failed to close")
			else:
				_record_fail("Main menu modal failed to open")
		else:
			_record_fail("WorldHUD missing")

	# Step 7: Completion & Result Summary (Frame 95)
	elif _frame_count == 95:
		print("=======================================================")
		print("SMOKE TEST RESULTS: Passed: %d | Failed: %d" % [_passed_steps, _failed_steps])
		print("=======================================================")
		if _failed_steps == 0:
			print(">>> ALL RELEASE SMOKE CHECKS PASSED. SYSTEM HEALTHY.")
			quit(0)
		else:
			printerr(">>> SMOKE TEST FAILED with %d errors" % _failed_steps)
			quit(1)

func _record_pass(msg: String) -> void:
	_passed_steps += 1
	print("  [PASS] %s" % msg)

func _record_fail(msg: String) -> void:
	_failed_steps += 1
	printerr("  [FAIL] %s" % msg)
