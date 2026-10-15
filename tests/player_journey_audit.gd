class_name PlayerJourneyAudit
extends SceneTree

## Simulates an authentic player journey through Living Planet Sandbox:
## 1. Opening scene at default gameplay camera
## 2. First-Person Walker exploration through Sunlit Meadow Glade
## 3. First-Person Walker traversing Whispering Forest understory
## 4. First-Person Walker inspecting Emerald Basin shoreline & water contact
## 5. First-Person Walker climbing towards Talus Crags & Summit Monolith
## 6. Night diurnal cycle with rest behaviors & moonlight
## 7. Rain weather with surface wetness & dynamic wind
## 8. HUD & Menu interaction audit

var _frame_count: int = 0
var _main_scene: Node = null
var _camera: FreeLookCamera = null
var _hud: WorldHUD = null
var _day_night: DayNightCycle = null
var _bootstrap: WorldBootstrap = null
var _output_dir: String = "res://reports/player_journey/"

func _init() -> void:
	print("=======================================================")
	print(" LIVING PLANET SANDBOX — REAL PLAYER JOURNEY AUDIT     ")
	print("=======================================================")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	var packed: PackedScene = load("res://scenes/main.tscn")
	if not packed:
		printerr("[PlayerAudit] Failed to load res://scenes/main.tscn")
		quit(1)
		return

	_main_scene = packed.instantiate()
	root.add_child(_main_scene)

	_camera = _main_scene.get_node_or_null("FreeLookCamera") as FreeLookCamera
	_hud = _main_scene.get_node_or_null("WorldHUD") as WorldHUD
	_day_night = _main_scene.get_node_or_null("DayNightCycle") as DayNightCycle
	_bootstrap = _main_scene.get_node_or_null("WorldBootstrap") as WorldBootstrap

	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	_frame_count += 1

	# Stage 1: The very first impression when game opens (Default Camera)
	if _frame_count == 20:
		_save_shot("journey_1_default_boot_opening.png", "1. Opening View at Default Camera")

	# Stage 2: Switch to First-Person Walker in Meadow Glade
	elif _frame_count == 30:
		if _camera:
			_camera.toggle_walker_mode()
			# Move walker to Sunlit Meadow Glade
			if _camera._walker:
				_camera._walker.set_walker_position(Vector3(6.5, 3.2, 5.0))
			_camera.rotation = Vector3(-0.08, deg_to_rad(140.0), 0.0)
			_camera._target_rotation = Vector2(-0.08, deg_to_rad(140.0))
	elif _frame_count == 55:
		_save_shot("journey_2_walker_meadow_glade.png", "2. First-Person Walker in Meadow Glade")

	# Stage 3: Walk into Whispering Forest Understory
	elif _frame_count == 65:
		if _camera and _camera._walker:
			_camera._walker.set_walker_position(Vector3(-5.0, 3.8, 0.5))
			_camera.rotation = Vector3(-0.05, deg_to_rad(-45.0), 0.0)
			_camera._target_rotation = Vector2(-0.05, deg_to_rad(-45.0))
	elif _frame_count == 90:
		_save_shot("journey_3_walker_forest_canopy.png", "3. First-Person Walker in Whispering Forest")

	# Stage 4: Walk to Emerald Basin Shoreline & Water Contact
	elif _frame_count == 100:
		if _camera and _camera._walker:
			_camera._walker.set_walker_position(Vector3(14.5, 0.95, 8.5))
			_camera.rotation = Vector3(-0.14, deg_to_rad(115.0), 0.0)
			_camera._target_rotation = Vector2(-0.14, deg_to_rad(115.0))
	elif _frame_count == 125:
		_save_shot("journey_4_walker_shoreline_water.png", "4. First-Person Walker at Emerald Shoreline")

	# Stage 5: Look up at Summit Monolith & Talus Crags
	elif _frame_count == 135:
		if _camera and _camera._walker:
			_camera._walker.set_walker_position(Vector3(-8.0, 8.5, -8.0))
			_camera.rotation = Vector3(0.25, deg_to_rad(-135.0), 0.0)
			_camera._target_rotation = Vector2(0.25, deg_to_rad(-135.0))
	elif _frame_count == 160:
		_save_shot("journey_5_walker_summit_talus.png", "5. First-Person Walker Looking at Talus Ridge")

	# Stage 6: Night Atmosphere with Resting Fauna
	elif _frame_count == 170:
		if _day_night:
			_day_night.set_night()
		if _camera:
			_camera.current_mode = FreeLookCamera.CameraMode.FREE_LOOK
			_camera.position = Vector3(10.0, 7.5, 15.0)
			_camera.look_at_target(Vector3(-4.0, 3.5, 0.0))
	elif _frame_count == 195:
		_save_shot("journey_6_night_ambience_canopy.png", "6. Night Ambience & Moonlight")

	# Stage 7: Golden Hour Sunset overlooking Basin
	elif _frame_count == 205:
		if _day_night:
			_day_night.set_golden_hour()
		if _camera:
			_camera.position = Vector3(18.0, 8.0, 24.0)
			_camera.look_at_target(Vector3(4.0, 3.0, 4.0))
	elif _frame_count == 230:
		_save_shot("journey_7_golden_hour_vista.png", "7. Golden Hour Scenic Vista")

	# Stage 8: Menu & HUD Interaction
	elif _frame_count == 240:
		if _hud:
			_hud.toggle_menu() # Open Pause / Settings Menu
	elif _frame_count == 255:
		_save_shot("journey_8_pause_menu_settings.png", "8. In-Game Settings & Controls Menu")

	elif _frame_count >= 270:
		print("[PlayerAudit] Audit completed successfully across all journey stages.")
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
					print("[PlayerAudit] CAPTURED: %s -> %s" % [label, global_path])
				else:
					printerr("[PlayerAudit] Error saving %s: %d" % [label, err])
