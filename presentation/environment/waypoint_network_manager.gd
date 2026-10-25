@tool
class_name WaypointNetworkManager
extends Node3D

## Living Planet Sandbox — Island Waypoint Fast Travel Network
## Manages 4 strategic Anemo Teleport Waypoints across the 720m island:
## 1. Haven Village Pier (Trading & Maritime Hub)
## 2. Whispering Grotto Ridge (Subterranean Caverns & Alpine Lake)
## 3. Ancient Castle Citadel (Historic Ruins & Royal Crypt)
## 4. Skyspire Massif Summit (Highest Peak, 65m elevation, Glider Launchpad)

signal waypoint_activated(id: String, display_name: String)
signal player_teleported(id: String, target_pos: Vector3)

const TeleportWaypointScript = preload("res://presentation/environment/teleport_waypoint.gd")

var _terrain: IslandTerrain = null
var _waypoints: Dictionary = {} # id -> TeleportWaypoint3D

func setup(terrain: IslandTerrain) -> void:
	_terrain = terrain
	_spawn_all_waypoints()

func _spawn_all_waypoints() -> void:
	var waypoint_defs: Array[Dictionary] = [
		{
			"id": "haven_pier",
			"name": "Tiền Đồn Haven",
			"desc": "Cầu cảng buôn bán & cửa ngõ vịnh ngọc bích Emerald Cove.",
			"pos": Vector3(12.5, 1.2, 6.5)
		},
		{
			"id": "whispering_grotto",
			"name": "Đỉnh Gió Whispering Grotto",
			"desc": "Cổng vòm đá tự nhiên dẫn vào hang động thạch nhũ huyền bí.",
			"pos": Vector3(-14.0, 7.5, 34.0)
		},
		{
			"id": "castle_citadel",
			"name": "Thành Cổ Viễn Cổ",
			"desc": "Sân trong lâu đài cổ kính trên mỏm đá phía Bắc nhìn ra đại dương.",
			"pos": Vector3(-24.0, 14.8, -36.0)
		},
		{
			"id": "skyspire_summit",
			"name": "Đỉnh Núi Tuyết Skyspire",
			"desc": "Đỉnh núi cao nhất đảo (65m), bãi phóng Cánh Phong lướt gió toàn đảo.",
			"pos": Vector3(-48.0, 52.0, -16.0)
		}
	]

	for def in waypoint_defs:
		var wp_id: String = def["id"]
		var target_pos: Vector3 = def["pos"]
		if _terrain:
			var gh: float = _terrain.get_height_at(target_pos.x, target_pos.z)
			target_pos.y = maxf(target_pos.y, gh)

		var wp: Node3D = TeleportWaypointScript.new()
		wp.name = "Waypoint_" + wp_id
		add_child(wp)
		# By default, Haven Pier is unlocked at start so player has immediate fast travel anchor
		var start_unlocked: bool = (wp_id == "haven_pier")
		wp.setup(wp_id, def["name"], def["desc"], target_pos, start_unlocked)
		wp.waypoint_unlocked.connect(_on_waypoint_unlocked)
		_waypoints[wp_id] = wp

	print("[WaypointNetworkManager] 4 Teleport Waypoints initialized across island biomes.")

func _on_waypoint_unlocked(id: String, display_name: String) -> void:
	print("[WaypointNetworkManager] Teleport Waypoint Unlocked: %s (%s)" % [display_name, id])
	waypoint_activated.emit(id, display_name)

func get_waypoints() -> Array:
	return _waypoints.values()

func get_waypoint(id: String) -> Node3D:
	return _waypoints.get(id, null)

func get_unlocked_waypoints() -> Array:
	var res: Array = []
	for wp in _waypoints.values():
		if wp.is_unlocked:
			res.append(wp)
	return res

func get_nearby_interactable(player_pos: Vector3) -> Dictionary:
	for wp in _waypoints.values():
		if wp.can_interact(player_pos):
			if wp.is_unlocked:
				return {
					"type": "WAYPOINT",
					"id": wp.waypoint_id,
					"name": wp.waypoint_name,
					"unlocked": true,
					"prompt": "[E] Mở Bản Đồ Dịch Chuyển (%s)" % wp.waypoint_name
				}
			else:
				return {
					"type": "WAYPOINT",
					"id": wp.waypoint_id,
					"name": wp.waypoint_name,
					"unlocked": false,
					"prompt": "[E] Kích hoạt Điểm Dịch Chuyển (%s)" % wp.waypoint_name
				}
	return {}

func teleport_player(walker: CharacterBody3D, target_wp_id: String) -> bool:
	var wp: Node3D = get_waypoint(target_wp_id)
	if not wp or not wp.is_unlocked or not walker:
		return false

	var arrival_pos: Vector3 = wp.get_teleport_arrival_position()
	if walker.has_method("teleport_to"):
		walker.teleport_to(arrival_pos)
	else:
		walker.global_position = arrival_pos

	wp.play_teleport_arrival_fx()
	player_teleported.emit(target_wp_id, arrival_pos)
	return true
