class_name TestVisualPolishAndUX
extends RefCounted

## Verification suite for Block 7: Visual Polish, UX & Gameplay Feedback.

func test_menu_modal_toggle_and_tabs() -> bool:
	var hud: WorldHUD = WorldHUD.new()
	hud._build_ui()
	
	if hud._menu_modal == null or hud._modal_tab_container == null:
		hud.free()
		return false
		
	# Initially hidden
	var initially_hidden: bool = not hud._menu_modal.visible
	
	# Toggle open
	hud.toggle_menu_modal()
	var opened: bool = hud._menu_modal.visible
	
	# Open Help Modal makes visible and targets help tab
	hud.open_help_modal()
	var help_opened: bool = hud._menu_modal.visible and hud._modal_tab_container.get_tab_count() == 3
	
	# Toggle closed
	hud.toggle_menu_modal()
	var closed: bool = not hud._menu_modal.visible
	
	hud.free()
	return initially_hidden and opened and help_opened and closed

func test_camera_clearance_and_speed_control() -> bool:
	var cam: FreeLookCamera = FreeLookCamera.new()
	cam.position = Vector3(0.0, -10.0, 0.0) # underground
	cam._ready()
	cam._process(0.1)
	
	# Minimum height clearance must enforce >= 0.85m
	var valid_height: bool = cam.position.y >= 0.85
	
	# Test scroll wheel speed adjustment
	var initial_speed: float = cam.move_speed
	var mb_up: InputEventMouseButton = InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_WHEEL_UP
	mb_up.pressed = true
	cam._unhandled_input(mb_up)
	var speed_increased: bool = cam.move_speed > initial_speed
	
	cam.free()
	return valid_height and speed_increased

func test_inspector_vitals_formatting() -> bool:
	var hud: WorldHUD = WorldHUD.new()
	var bar_half: String = hud._format_bar(50.0, 100.0, 10)
	var bar_full: String = hud._format_bar(100.0, 100.0, 10)
	var bar_zero: String = hud._format_bar(0.0, 100.0, 10)
	
	var valid_half: bool = bar_half.contains("█████░░░░░") and bar_half.contains("50.0%")
	var valid_full: bool = bar_full.contains("██████████") and bar_full.contains("100.0%")
	var valid_zero: bool = bar_zero.contains("░░░░░░░░░░") and bar_zero.contains("0.0%")
	
	hud.free()
	return valid_half and valid_full and valid_zero

func test_presentation_selection_highlight() -> bool:
	var eco: EcosystemPresentation = EcosystemPresentation.new()
	eco.set_inspected_entity(1020)
	var marker_visible: bool = eco._selection_marker != null and eco._selection_marker.visible and eco.inspected_entity_id == 1020
	eco.set_inspected_entity(-1)
	var marker_hidden: bool = not eco._selection_marker.visible and eco.inspected_entity_id == -1
	eco.free()
	return marker_visible and marker_hidden

func test_tool_pulse_feedback_lifecycle() -> bool:
	var ptc: PlayerToolController = PlayerToolController.new()
	ptc._spawn_tool_pulse(Vector3(10.0, 2.0, 10.0), Color.CYAN, 5.0)
	var pulse_found: bool = false
	for child in ptc.get_children():
		if child is MeshInstance3D and child.position.x == 10.0:
			pulse_found = true
			break
	ptc.free()
	return pulse_found
