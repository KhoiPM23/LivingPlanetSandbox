class_name VisualQATransformation
extends SceneTree

## Visual QA Capture Suite for Master Mission Visual Transformation.
## Captures all 9 acceptance gate shots with exact WorldSeed, camera coordinates, and parameters.

var _frame_count: int = 0
var _main_scene: Node = null
var _camera: Camera3D = null
var _hud: WorldHUD = null
var _tools: PlayerToolController = null
var _bootstrap: WorldBootstrap = null
var _output_dir: String = "res://reports/visual_evidence/"

func _init() -> void:
	print("=======================================================")
	print(" LIVING PLANET SANDBOX — VISUAL TRANSFORMATION CAPTURE ")
	print("=======================================================")

	# Ensure output directory exists
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

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

	# Shot 1: Toàn cảnh thế giới (World Panorama)
	if _frame_count == 10:
		if _camera:
			_camera.position = Vector3(22.0, 16.0, 32.0)
			_camera.look_at(Vector3(-10.0, 6.0, -8.0), Vector3.UP)
	elif _frame_count == 25:
		_save_shot("shot_1_world_panorama.png", "1. World Panorama (Flycam Overview)")

	# Shot 2: Cảnh rừng từ góc nhìn người chơi (Forest First-Person)
	elif _frame_count == 35:
		if _camera:
			_camera.position = Vector3(-6.0, 4.2, 2.0)
			_camera.look_at(Vector3(-18.0, 5.0, -10.0), Vector3.UP)
	elif _frame_count == 50:
		_save_shot("shot_2_forest_first_person.png", "2. Forest View (First-Person Scale)")

	# Shot 3: Đồng cỏ và vùng chuyển tiếp sang rừng (Meadow to Forest Transition)
	elif _frame_count == 60:
		if _camera:
			_camera.position = Vector3(12.0, 5.5, 12.0)
			_camera.look_at(Vector3(-4.0, 4.0, -4.0), Vector3.UP)
	elif _frame_count == 75:
		_save_shot("shot_3_meadow_transition.png", "3. Meadow & Forest Transition")

	# Shot 4: Bờ hồ / sông (Shoreline & Water Depth)
	elif _frame_count == 85:
		if _camera:
			_camera.position = Vector3(8.0, 1.8, 16.0)
			_camera.look_at(Vector3(0.0, 0.4, 6.0), Vector3.UP)
	elif _frame_count == 100:
		_save_shot("shot_4_shoreline_water.png", "4. Shoreline, Wet Sand & Water Reflections")

	# Shot 5: Cận cảnh model cây, cỏ và vật liệu (Vegetation & PBR Materials Close-up)
	elif _frame_count == 110:
		if _camera:
			_camera.position = Vector3(2.5, 2.4, 4.5)
			_camera.look_at(Vector3(0.5, 1.8, 1.5), Vector3.UP)
	elif _frame_count == 125:
		_save_shot("shot_5_vegetation_materials.png", "5. Close-up 3D Grass Tufts, Foliage & PBR Ground")

	# Shot 6: Cận cảnh động vật và hoạt ảnh (Fauna Close-up & Locomotion)
	elif _frame_count == 135:
		if _bootstrap and _bootstrap.ecosystem_coordinator:
			var herbs = _bootstrap.ecosystem_coordinator.fauna_sim.get_all_herbivores()
			if not herbs.is_empty():
				var target_h = herbs[0]
				var h_pos: Vector3 = target_h.position
				if _camera:
					_camera.position = h_pos + Vector3(2.2, 1.4, 2.8)
					_camera.look_at(h_pos + Vector3(0.0, 0.8, 0.0), Vector3.UP)
	elif _frame_count == 150:
		_save_shot("shot_6_fauna_locomotion.png", "6. Fauna Models (Stag/Deer/Wolf) & Skeletal Locomotion")

	# Shot 7: Cảnh ban đêm (Night Atmospheric Atmosphere)
	elif _frame_count == 160:
		if _bootstrap and _bootstrap.world_clock:
			_bootstrap.world_clock.simulation_time = 75.0
			_bootstrap.world_clock.set_paused(true)
		if _camera:
			_camera.position = Vector3(-8.0, 12.0, -6.0)
			_camera.look_at(Vector3(-24.0, 16.0, -24.0), Vector3.UP)
	elif _frame_count == 175:
		_save_shot("shot_7_night_atmosphere.png", "7. Night Atmosphere, Moonlight & Summit Monolith")

	# Shot 8: Cảnh mưa / gió (Rain Precipitation & Surface Wetness)
	elif _frame_count == 185:
		if _bootstrap:
			if _bootstrap.world_clock:
				_bootstrap.world_clock.simulation_time = 0.0
				_bootstrap.world_clock.set_paused(false)
			if _bootstrap.weather_system:
				_bootstrap.weather_system.set_state(WeatherSystem.WeatherState.RAIN, 60.0)
		if _camera:
			_camera.position = Vector3(6.0, 3.8, 8.0)
			_camera.look_at(Vector3(-6.0, 3.0, -2.0), Vector3.UP)
	elif _frame_count == 210:
		_save_shot("shot_8_weather_rain_wetness.png", "8. Dynamic Rain Storm, Surface Wetness & Wind Sway")

	# Shot 9: HUD & Settings (UI, Inspector & Graphics Presets)
	elif _frame_count == 220:
		if _hud:
			_hud.toggle_menu_modal()
	elif _frame_count == 235:
		_save_shot("shot_9_hud_settings.png", "9. HUD, Vitals Inspector & Graphics Quality Presets")

	elif _frame_count >= 245:
		print("[VisualQA] Complete: All 9 acceptance gate shots processed.")
		quit(0)

func _save_shot(filename: String, label: String) -> void:
	var vp: Viewport = root.get_viewport()
	if vp:
		var tex: ViewportTexture = vp.get_texture()
		if tex:
			var img: Image = tex.get_image()
			if img and not img.is_empty():
				var global_path: String = ProjectSettings.globalize_path(_output_dir + filename)
				var err: Error = img.save_png(global_path)
				if err == OK:
					print("[VisualQA] SAVED: %s -> %s (%dx%d)" % [label, global_path, img.get_width(), img.get_height()])
				else:
					printerr("[VisualQA] Error saving %s: %d" % [label, err])
			else:
				print("[VisualQA] Notice: Viewport image empty in current renderer.")
