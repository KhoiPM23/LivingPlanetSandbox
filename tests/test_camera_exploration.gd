class_name TestCameraExploration
extends RefCounted

## Verification contract suite for Block 1: Camera and World Exploration.

func test_camera_modes_enum_and_defaults() -> bool:
	var cam: FreeLookCamera = FreeLookCamera.new()
	cam._ready()

	var mode_default: bool = cam.current_mode == FreeLookCamera.CameraMode.FREE_LOOK
	var name_free: bool = cam.get_mode_name(FreeLookCamera.CameraMode.FREE_LOOK) == "Free Flight"
	var name_orbit: bool = cam.get_mode_name(FreeLookCamera.CameraMode.ORBIT_INSPECT) == "Orbit View"
	var name_follow: bool = cam.get_mode_name(FreeLookCamera.CameraMode.FOLLOW_ENTITY) == "Tracking Entity"
	var name_top: bool = cam.get_mode_name(FreeLookCamera.CameraMode.TOP_DOWN) == "Tactical Map"

	cam.free()
	return mode_default and name_free and name_orbit and name_follow and name_top

func test_free_look_movement_and_clearance() -> bool:
	var cam: FreeLookCamera = FreeLookCamera.new()
	cam.position = Vector3(100.0, -15.0, -100.0) # Outside bounds and underground
	cam._ready()
	cam._process(0.1)

	var clearance_valid: bool = cam.position.y >= 0.85
	var bounds_valid_x: bool = cam.position.x <= 76.0
	var bounds_valid_z: bool = cam.position.z >= -76.0

	cam.free()
	return clearance_valid and bounds_valid_x and bounds_valid_z

func test_orbit_inspect_math_and_zoom() -> bool:
	var cam: FreeLookCamera = FreeLookCamera.new()
	cam._ready()

	var target: Vector3 = Vector3(10.0, 5.0, 10.0)
	cam.start_orbit(target, 8.0, true)

	var mode_correct: bool = cam.current_mode == FreeLookCamera.CameraMode.ORBIT_INSPECT
	var dist_correct: bool = absf(cam.position.distance_to(target) - 8.0) < 0.2

	var init_dist: float = cam.orbit_distance
	cam._handle_zoom_in()
	var zoomed_in: bool = cam.orbit_distance < init_dist

	cam._handle_zoom_out()
	cam._handle_zoom_out()
	var zoomed_out: bool = cam.orbit_distance > init_dist

	cam.free()
	return mode_correct and dist_correct and zoomed_in and zoomed_out

func test_follow_entity_tracking() -> bool:
	var cam: FreeLookCamera = FreeLookCamera.new()
	cam._ready()

	var dummy: Node3D = Node3D.new()
	dummy.position = Vector3(5.0, 3.0, 5.0)

	cam.start_following_node(dummy, 6.0, 1001, true)
	var mode_follow: bool = cam.current_mode == FreeLookCamera.CameraMode.FOLLOW_ENTITY

	# Move dummy
	dummy.position = Vector3(12.0, 3.0, 18.0)
	cam._process(0.5)
	var tracking_updated: bool = cam.orbit_target.distance_to(dummy.position) < 5.0

	# Despawn / delete dummy
	dummy.free()
	cam._process(0.1)
	# Should fall back cleanly to ORBIT_INSPECT without crash
	var fallback_safe: bool = cam.current_mode == FreeLookCamera.CameraMode.ORBIT_INSPECT

	cam.free()
	return mode_follow and tracking_updated and fallback_safe

func test_top_down_mode_navigation() -> bool:
	var cam: FreeLookCamera = FreeLookCamera.new()
	cam._ready()

	cam.set_camera_mode(FreeLookCamera.CameraMode.TOP_DOWN, true)
	var mode_correct: bool = cam.current_mode == FreeLookCamera.CameraMode.TOP_DOWN
	var alt_correct: bool = absf(cam.position.y - cam.top_down_altitude) < 0.1
	var pitch_downward: bool = cam.rotation.x < -deg_to_rad(75.0)

	cam.free()
	return mode_correct and alt_correct and pitch_downward

func test_scenic_bookmarks_and_transitions() -> bool:
	var cam: FreeLookCamera = FreeLookCamera.new()
	cam._ready()

	var bookmarks: Array[Dictionary] = cam.get_bookmarks()
	if bookmarks.size() != 5:
		cam.free()
		return false

	# Jump to Summit Monolith (index 1)
	cam.jump_to_bookmark(1, true)
	var at_summit: bool = cam.position.distance_to(bookmarks[1]["pos"]) < 0.1
	var summit_mode: bool = cam.current_mode == bookmarks[1]["mode"]

	# Jump to Island Panorama (index 0)
	cam.jump_to_bookmark(0, true)
	var at_panorama: bool = cam.position.distance_to(bookmarks[0]["pos"]) < 0.1
	var pano_mode: bool = cam.current_mode == bookmarks[0]["mode"]

	cam.free()
	return at_summit and summit_mode and at_panorama and pano_mode

func test_compass_heading_and_cardinals() -> bool:
	var cam: FreeLookCamera = FreeLookCamera.new()
	cam._ready()

	# Looking North (-Z): transform.basis.z is +Z, forward is -Z -> yaw = 0
	cam.rotation = Vector3(0.0, 0.0, 0.0)
	var north_deg: float = cam.get_compass_heading_degrees()
	var north_card: String = cam.get_compass_cardinal()
	var is_north: bool = (north_deg < 5.0 or north_deg > 355.0) and north_card == "N"

	# Looking East (+X): rotate Y by -90 deg (-PI/2)
	cam.rotation = Vector3(0.0, -PI * 0.5, 0.0)
	var east_deg: float = cam.get_compass_heading_degrees()
	var east_card: String = cam.get_compass_cardinal()
	var is_east: bool = absf(east_deg - 90.0) < 5.0 and east_card == "E"

	# Looking South (+Z): rotate Y by PI
	cam.rotation = Vector3(0.0, PI, 0.0)
	var south_deg: float = cam.get_compass_heading_degrees()
	var south_card: String = cam.get_compass_cardinal()
	var is_south: bool = absf(south_deg - 180.0) < 5.0 and south_card == "S"

	# Looking West (-X): rotate Y by +90 deg (+PI/2)
	cam.rotation = Vector3(0.0, PI * 0.5, 0.0)
	var west_deg: float = cam.get_compass_heading_degrees()
	var west_card: String = cam.get_compass_cardinal()
	var is_west: bool = absf(west_deg - 270.0) < 5.0 and west_card == "W"

	cam.free()
	return is_north and is_east and is_south and is_west
