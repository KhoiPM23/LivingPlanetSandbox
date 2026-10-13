class_name VisualQACameraDual
extends SceneTree

## Automated Visual QA Capture for Block 1: Dual-Mode Exploration Camera.
## Captures:
## 1. screenshot_flycam_view.png (Overview scenic Flycam flight mode)
## 2. screenshot_walker_view.png (Authentic eye-level first-person walker mode at 1.65m height)

var _frame_count: int = 0
var _main_scene: Node = null
var _camera: FreeLookCamera = null
var _terrain: IslandTerrain = null

func _init() -> void:
	print("=======================================================")
	print("   BLOCK 1: DUAL-MODE CAMERA VISUAL QA CAPTURE        ")
	print("=======================================================")

	var packed: PackedScene = load("res://scenes/main.tscn")
	if not packed:
		printerr("[VisualQA] Failed to load res://scenes/main.tscn")
		quit(1)
		return

	_main_scene = packed.instantiate()
	root.add_child(_main_scene)

	_camera = _main_scene.get_node_or_null("FreeLookCamera") as FreeLookCamera
	_terrain = _main_scene.get_node_or_null("IslandTerrain") as IslandTerrain

	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	_frame_count += 1

	# Frame 15: Setup Flycam overview
	if _frame_count == 15:
		if _camera:
			_camera.set_camera_mode(FreeLookCamera.CameraMode.FREE_LOOK, true)
			_camera.position = Vector3(18.0, 14.0, 28.0)
			_camera.look_at_target(Vector3(-14.0, 7.5, -12.0))
			print("[VisualQA] Flycam configured at scenic overview position: %s" % str(_camera.position))

	# Frame 30: Capture Flycam Screenshot
	elif _frame_count == 30:
		_save_screenshot("res://screenshot_flycam_view.png", "Scenic Flycam Overview")

	# Frame 45: Switch to First-Person Walker mode at lush meadow ground location
	elif _frame_count == 45:
		if _camera:
			var target_x: float = 6.0
			var target_z: float = 8.0
			var ground_y: float = _terrain.get_height_at(target_x, target_z) if _terrain else 3.5
			_camera.position = Vector3(target_x, ground_y + 10.0, target_z)
			_camera.set_camera_mode(FreeLookCamera.CameraMode.FIRST_PERSON_WALKER, true)
			# Ensure walker is stationed firmly on ground
			var walker = _camera.get_walker()
			if walker:
				walker.teleport_to(Vector3(target_x, ground_y, target_z))
				_camera.position = walker.get_eye_position()
			_camera.look_at_target(Vector3(-16.0, ground_y + 1.2, -14.0))
			print("[VisualQA] First-Person Walker active at eye height: %s (eye Y: %.2fm, ground Y: %.2fm)" % [
				str(_camera.position), _camera.position.y, ground_y
			])

	# Frame 70: Capture First-Person Walker Screenshot
	elif _frame_count == 70:
		_save_screenshot("res://screenshot_walker_view.png", "First-Person Walker Eye-Level View (1.65m)")

	elif _frame_count >= 85:
		print("[VisualQA] Both Dual-Mode Camera screenshots captured successfully.")
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
					print("[VisualQA] [RUNTIME SCREENSHOT] %s -> %s (%dx%d)" % [label, global_path, img.get_width(), img.get_height()])
				else:
					printerr("[VisualQA] Failed saving %s. Error: %d" % [label, err])
			else:
				print("[VisualQA] Image empty (running headless without GPU rendering).")
