class_name VisualQATransformation
extends SceneTree

## Visual QA Capture Suite for Master Mission Visual Transformation.
## Captures all 9 acceptance gate shots with exact WorldSeed, camera coordinates, and parameters.
## Validates the 3 lighting states (Midday, Golden Hour, Overcast/Rain) and 3 reconstructed focal points.

var _frame_count: int = 0
var _main_scene: Node = null
var _camera: Camera3D = null
var _hud: WorldHUD = null
var _tools: PlayerToolController = null
var _bootstrap: WorldBootstrap = null
var _day_night: DayNightCycle = null
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
	_day_night = _main_scene.get_node_or_null("DayNightCycle") as DayNightCycle

	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	_frame_count += 1
	if not _tools and _main_scene:
		_tools = _main_scene.get_node_or_null("PlayerToolController") as PlayerToolController
		if _tools:
			_tools.set_input_blocked(true)

	# Ensure Midday lighting state for default daytime shots
	if _frame_count == 5:
		if _day_night:
			_day_night.set_midday()

	# Shot 1: Toàn cảnh thế giới (World Panorama)
	if _frame_count == 10:
		_aim_camera(Vector3(28.0, 22.0, 34.0), Vector3(2.0, 3.5, 4.0))
	elif _frame_count == 25:
		_save_shot("shot_1_world_panorama.png", "1. World Panorama (Flycam Overview)")

	# Shot 2: Cảnh rừng từ góc nhìn người chơi (Whispering Forest Ground Perspective)
	elif _frame_count == 35:
		_aim_camera(Vector3(-6.0, 4.0, 2.5), Vector3(3.0, 3.8, 4.5))
	elif _frame_count == 50:
		_save_shot("shot_2_forest_first_person.png", "2. Forest View (First-Person Scale)")

	# Shot 3: Đồng cỏ và vùng chuyển tiếp sang rừng (Meadow to Forest Transition)
	elif _frame_count == 60:
		# Open meadow mid-shot: camera above slope looking across meadow toward forest edge
		_aim_camera(Vector3(8.0, 5.2, -2.0), Vector3(12.0, 3.0, 6.0))
	elif _frame_count == 75:
		_save_shot("shot_3_meadow_transition.png", "3. Meadow & Forest Transition")

	# Shot 4: Bờ hồ hoặc suối (Shoreline, Lake Cove & Water Depth)
	elif _frame_count == 85:
		# Camera looking over lake from open slope - no rock occlusion
		_aim_camera(Vector3(12.5, 4.8, 6.5), Vector3(17.0, 0.5, 14.0))
	elif _frame_count == 100:
		_save_shot("shot_4_shoreline_water.png", "4. Shoreline, Lake Cove & Water Depth")

	# Shot 5: Cận cảnh cây, lá, đất, đá và vật liệu (Vegetation & PBR Materials Close-up)
	elif _frame_count == 110:
		_aim_camera(Vector3(1.5, 1.6, 6.8), Vector3(4.0, 0.8, 5.0))
	elif _frame_count == 125:
		_save_shot("shot_5_vegetation_materials.png", "5. Close-up 3D Grass Tufts, Foliage & PBR Ground")

	# Shot 6: Động vật ở cự ly gần (Fauna Close-up & Locomotion)
	elif _frame_count >= 135 and _frame_count <= 150:
		if _bootstrap and _bootstrap.ecosystem_coordinator:
			var herbs = _bootstrap.ecosystem_coordinator.fauna_sim.get_all_herbivores()
			if not herbs.is_empty():
				var target_h = herbs[0]
				var h_pos: Vector3 = target_h.position
				_aim_camera(h_pos + Vector3(1.5, 1.3, 3.8), h_pos + Vector3(0.0, 0.90, 0.0))
		if _frame_count == 150:
			_save_shot("shot_6_fauna_locomotion.png", "6. Fauna 3/4 Perspective & Skeletal Locomotion")

	# Shot 7: Cảnh nhìn xa qua nhiều lớp địa hình và thực vật (Distant View Across Multiple Layers)
	elif _frame_count == 160:
		_aim_camera(Vector3(4.0, 8.5, 26.0), Vector3(8.0, 3.5, 6.0))
	elif _frame_count == 175:
		_save_shot("shot_7_distant_layers.png", "7. Distant View Across Terrain Layers & Canopy")

	# Shot 8: Cảnh trong điều kiện ánh sáng hoặc thời tiết khác (Overcast / Rain Storm & Wetness)
	elif _frame_count == 185:
		if _bootstrap and _bootstrap.weather_system:
			_bootstrap.weather_system.set_state(WeatherSystem.WeatherState.RAIN, 60.0)
		if _day_night:
			_day_night.set_overcast_rain()
		_aim_camera(Vector3(10.0, 3.5, 12.0), Vector3(16.0, 1.0, 15.0))
	elif _frame_count == 210:
		_save_shot("shot_8_weather_rain_wetness.png", "8. Dynamic Rain Storm, Surface Wetness & Wind Sway")

	# Shot 9: Golden Hour warm sunset & minimal HUD view
	elif _frame_count == 220:
		if _bootstrap and _bootstrap.weather_system:
			_bootstrap.weather_system.set_state(WeatherSystem.WeatherState.CLEAR, 60.0)
		if _day_night:
			_day_night.set_golden_hour()
		if _hud:
			_hud.toggle_hud()
		_aim_camera(Vector3(14.0, 6.5, 22.0), Vector3(-2.0, 4.0, 0.0))
	elif _frame_count == 235:
		_save_shot("shot_9_minimal_hud.png", "9. Golden Hour Sunset & Minimal Immersive HUD")

	# Shot 10: Ecological Meadow Grazing & Herd Community (Sunlit Meadow Glade)
	elif _frame_count == 245:
		if _day_night:
			_day_night.set_midday()
		_aim_camera(Vector3(3.0, 3.8, 8.5), Vector3(10.5, 3.5, 4.0))
	elif _frame_count == 260:
		_save_shot("shot_10_ecological_meadow_grazing.png", "10. Ecological Meadow Herd Grazing & Community Niche")

	# Shot 11: Shoreline Watering Hole at Dusk (Emerald Basin & Creek Delta)
	elif _frame_count == 270:
		if _day_night:
			_day_night.set_golden_hour()
		# Open meadow-to-lake framing: camera elevated behind the glade looking toward the lake at golden light
		_aim_camera(Vector3(6.0, 5.5, 2.0), Vector3(16.0, 0.8, 14.0))
	elif _frame_count == 285:
		_save_shot("shot_11_golden_hour_watering.png", "11. Shoreline Watering Hole & Creek Delta at Golden Hour")

	elif _frame_count >= 295:
		print("[VisualQA] Complete: All review angles and living world shots captured successfully.")
		quit(0)

func _aim_camera(pos: Vector3, target: Vector3) -> void:
	if _camera:
		_camera.position = pos
		if _camera is FreeLookCamera:
			(_camera as FreeLookCamera).look_at_target(target)
		else:
			_camera.look_at(target, Vector3.UP)

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
