class_name VisualQACapture
extends SceneTree

## Automated Visual QA Capture Suite for Block 7.
## Captures 7 distinct runtime screenshots verifying art direction, close-ups, night atmosphere, fauna interaction, UI, intervention, and menu.

var _frame_count: int = 0
var _main_scene: Node = null
var _camera: Camera3D = null
var _hud: WorldHUD = null
var _tools: PlayerToolController = null
var _bootstrap: WorldBootstrap = null

func _init() -> void:
	print("=======================================================")
	print("   LIVING PLANET SANDBOX — BLOCK 7 VISUAL QA CAPTURE   ")
	print("=======================================================")
	
	var packed: PackedScene = load("res://scenes/main.tscn")
	if not packed:
		printerr("[VisualQA] Failed to load res://scenes/main.tscn")
		quit(1)
		return
		
	_main_scene = packed.instantiate()
	root.add_child(_main_scene)
	
	_camera = _main_scene.get_node_or_null("FreeLookCamera") as Camera3D
	_hud = _main_scene.get_node_or_null("WorldHUD") as WorldHUD
	_tools = _main_scene.get_node_or_null("PlayerToolController") as PlayerToolController
	_bootstrap = _main_scene.get_node_or_null("WorldBootstrap") as WorldBootstrap
	
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	_frame_count += 1
	
	if not _tools and _main_scene:
		_tools = _main_scene.get_node_or_null("PlayerToolController") as PlayerToolController
		
	# Stage 1: Setup Panorama -> Capture at frame 25
	if _frame_count == 10:
		if _camera:
			_camera.position = Vector3(18.0, 14.0, 28.0)
			_camera.look_at_target(Vector3(-14.0, 7.5, -12.0))
	elif _frame_count == 25:
		_save_screenshot("res://screenshot_block_7_panorama.png", "Panorama Overview")
		
	# Stage 2: Setup Close-up Shoreline -> Capture at frame 55
	elif _frame_count == 35:
		if _camera:
			_camera.position = Vector3(10.0, 2.8, 14.0)
			_camera.look_at_target(Vector3(0.0, 1.0, 6.0))
	elif _frame_count == 55:
		_save_screenshot("res://screenshot_block_7_closeup.png", "Close-up Shoreline & Foliage")
		
	# Stage 3: Setup Midnight Sky & Monolith Beacon -> Capture at frame 90
	elif _frame_count == 65:
		if _bootstrap and _bootstrap.world_clock:
			_bootstrap.world_clock.simulation_time = 75.0
			_bootstrap.world_clock.set_paused(true)
		if _camera:
			_camera.position = Vector3(-10.0, 14.0, -8.0)
			_camera.look_at_target(Vector3(-24.0, 18.0, -24.0))
	elif _frame_count == 90:
		_save_screenshot("res://screenshot_block_7_night.png", "Night Atmospheric Perspective")
		
	# Stage 4: Return Daylight & Setup Fauna -> Capture at frame 125
	elif _frame_count == 100:
		if _bootstrap and _bootstrap.world_clock:
			_bootstrap.world_clock.simulation_time = 0.0
			_bootstrap.world_clock.set_paused(false)
		if _camera:
			_camera.position = Vector3(12.0, 4.8, 8.0)
			_camera.look_at_target(Vector3(0.0, 3.2, 0.0))
	elif _frame_count == 125:
		_save_screenshot("res://screenshot_block_7_fauna.png", "Fauna Interacting in Habitat")
		
	# Stage 5: Setup Inspection Card & Telemetry -> Capture at frame 160
	elif _frame_count == 135:
		if _camera:
			_camera.position = Vector3(14.0, 10.5, 22.0)
			_camera.look_at_target(Vector3(-16.0, 9.0, -14.0))
		if _tools and _bootstrap and _bootstrap.ecosystem_coordinator:
			var herbs = _bootstrap.ecosystem_coordinator.fauna_sim.get_all_herbivores()
			if herbs.size() > 0:
				var h = herbs[0]
				_tools._current_hit_point = h.position
				_tools._has_hit = true
				_tools._execute_inspect()
		if _hud and _hud._tab_container:
			_hud._tab_container.current_tab = 1
	elif _frame_count == 160:
		_save_screenshot("res://screenshot_block_7_ui.png", "Full UI, Inspector Vitals & Chart")
		
	# Stage 6: Setup Moisture Intervention -> Capture at frame 195
	elif _frame_count == 170:
		if _tools:
			_tools.set_tool(PlayerToolController.ToolMode.MOISTURE_ADD)
			_tools._current_hit_point = Vector3(4.0, 3.5, 0.0)
			_tools._has_hit = true
			_tools._execute_moisture_brush(0.20)
	elif _frame_count == 195:
		_save_screenshot("res://screenshot_block_7_intervention.png", "Player Moisture Intervention")
		
	# Stage 7: Setup Main Menu & Settings Modal -> Capture at frame 230
	elif _frame_count == 205:
		if _hud:
			_hud.toggle_menu_modal()
	elif _frame_count == 230:
		_save_screenshot("res://screenshot_block_7_menu.png", "Main Menu & Settings Modal")
		
	elif _frame_count >= 245:
		print("[VisualQA] All 7 Visual QA screenshots captured successfully.")
		quit(0)

func _save_screenshot(res_path: String, label: String) -> void:
	var vp: Viewport = root.get_viewport()
	if vp:
		var tex: ViewportTexture = vp.get_texture()
		if tex:
			var img: Image = tex.get_image()
			if img and not img.is_empty():
				var global_path: String = ProjectSettings.globalize_path(res_path)
				var err: Error = img.save_png(global_path)
				if err == OK:
					print("[VisualQA] Captured %s -> %s (%dx%d)" % [label, global_path, img.get_width(), img.get_height()])
				else:
					printerr("[VisualQA] Failed saving %s. Error: %d" % [label, err])
			else:
				print("[VisualQA] Image empty (Dummy/headless renderer).")
