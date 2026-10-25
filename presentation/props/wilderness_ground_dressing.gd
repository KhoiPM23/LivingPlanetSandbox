class_name WildernessGroundDressing
extends Node3D

## Living Planet Sandbox — RDR2-Style Wilderness Ground Dressing & Forageable Bushes (Block 55)
## Features:
## 1. Fallen Mossy Cedar Logs across woodland gullies with orange bracket fungi (chanterelles).
## 2. Sun-bleached Shoreline Driftwood logs washed up on lake and coastal sandbars.
## 3. Interactive Wild Raspberry Bushes (Bụi Mâm Xôi Dại) yielding wild_raspberry (+15 EXP).
## 4. Intel Iris Xe optimized: shared standard materials, low polygon counts, 60 FPS budgeted.

signal berry_foraged(bush_id: String, item_id: String, pos: Vector3)

var _bushes: Array[Dictionary] = []

# Shared Materials
static var _log_bark_mat: StandardMaterial3D = null
static var _moss_mat: StandardMaterial3D = null
static var _driftwood_mat: StandardMaterial3D = null
static var _fungi_mat: StandardMaterial3D = null
static var _bush_leaf_mat: StandardMaterial3D = null
static var _berry_mat: StandardMaterial3D = null

func _init() -> void:
	name = "WildernessGroundDressing"
	_init_materials()
	_spawn_fallen_logs()
	_spawn_shoreline_driftwood()
	_spawn_wild_raspberry_bushes()

static func _init_materials() -> void:
	if _log_bark_mat != null:
		return

	# Dark Mossy Cedar Bark
	_log_bark_mat = StandardMaterial3D.new()
	_log_bark_mat.albedo_color = Color(0.26, 0.18, 0.12)
	_log_bark_mat.roughness = 0.90

	# Green Velvety Moss
	_moss_mat = StandardMaterial3D.new()
	_moss_mat.albedo_color = Color(0.24, 0.48, 0.18)
	_moss_mat.roughness = 0.95

	# Bleached Grey Driftwood
	_driftwood_mat = StandardMaterial3D.new()
	_driftwood_mat.albedo_color = Color(0.65, 0.62, 0.58)
	_driftwood_mat.roughness = 0.82

	# Wild Orange Bracket Fungi
	_fungi_mat = StandardMaterial3D.new()
	_fungi_mat.albedo_color = Color(0.95, 0.48, 0.15)
	_fungi_mat.roughness = 0.65

	# Raspberry Bush Foliage
	_bush_leaf_mat = StandardMaterial3D.new()
	_bush_leaf_mat.albedo_color = Color(0.18, 0.52, 0.22)
	_bush_leaf_mat.roughness = 0.70

	# Ruby Red Berries
	_berry_mat = StandardMaterial3D.new()
	_berry_mat.albedo_color = Color(0.92, 0.12, 0.25)
	_berry_mat.roughness = 0.35

func _spawn_fallen_logs() -> void:
	var log_data = [
		{"pos": Vector3(-4.0, 4.5, 38.0), "yaw": deg_to_rad(40.0), "len": 5.2},
		{"pos": Vector3(15.0, 3.8, 32.0), "yaw": deg_to_rad(-25.0), "len": 4.6},
		{"pos": Vector3(28.0, 3.2, 34.0), "yaw": deg_to_rad(75.0), "len": 4.8}
	]

	for i in range(log_data.size()):
		var ld = log_data[i]
		var log_root = Node3D.new()
		log_root.name = "FallenLog_%d" % i
		log_root.position = ld["pos"]
		log_root.rotation.y = ld["yaw"]
		add_child(log_root)

		# Trunk Cylinder
		var trunk = CylinderMesh.new()
		trunk.top_radius = 0.26
		trunk.bottom_radius = 0.32
		trunk.height = ld["len"]
		var t_mi = MeshInstance3D.new()
		t_mi.mesh = trunk
		t_mi.material_override = _log_bark_mat
		t_mi.position.y = 0.26
		t_mi.rotation.z = PI * 0.5
		log_root.add_child(t_mi)

		# Moss Layer on Top
		var moss = BoxMesh.new()
		moss.size = Vector3(ld["len"] * 0.75, 0.04, 0.28)
		var m_mi = MeshInstance3D.new()
		m_mi.mesh = moss
		m_mi.material_override = _moss_mat
		m_mi.position.y = 0.54
		log_root.add_child(m_mi)

		# Bracket Fungi clusters along trunk
		for f_i in range(3):
			var fungi = SphereMesh.new()
			fungi.radius = 0.08
			fungi.height = 0.04
			var f_mi = MeshInstance3D.new()
			f_mi.mesh = fungi
			f_mi.material_override = _fungi_mat
			f_mi.position = Vector3((float(f_i) - 1.0) * 1.1, 0.35, 0.26)
			log_root.add_child(f_mi)

func _spawn_shoreline_driftwood() -> void:
	var drift_data = [
		{"pos": Vector3(20.0, 0.45, 14.0), "yaw": deg_to_rad(-45.0), "len": 3.8},
		{"pos": Vector3(14.0, 0.45, 8.0), "yaw": deg_to_rad(60.0), "len": 4.2},
		{"pos": Vector3(22.0, 0.35, 12.0), "yaw": deg_to_rad(15.0), "len": 3.4}
	]

	for i in range(drift_data.size()):
		var dd = drift_data[i]
		var drift_root = Node3D.new()
		drift_root.name = "Driftwood_%d" % i
		drift_root.position = dd["pos"]
		drift_root.rotation.y = dd["yaw"]
		add_child(drift_root)

		var log_mesh = CylinderMesh.new()
		log_mesh.top_radius = 0.18
		log_mesh.bottom_radius = 0.24
		log_mesh.height = dd["len"]
		var l_mi = MeshInstance3D.new()
		l_mi.mesh = log_mesh
		l_mi.material_override = _driftwood_mat
		l_mi.position.y = 0.18
		l_mi.rotation.z = PI * 0.5
		drift_root.add_child(l_mi)

func _spawn_wild_raspberry_bushes() -> void:
	var bush_coords = [
		Vector3(-2.0, 4.5, 36.0),
		Vector3(12.0, 3.8, 30.0),
		Vector3(24.0, 3.2, 28.0),
		Vector3(29.0, 3.2, 33.0)
	]

	for i in range(bush_coords.size()):
		var b_pos: Vector3 = bush_coords[i]
		var b_root = Node3D.new()
		b_root.name = "RaspberryBush_%d" % i
		b_root.position = b_pos
		add_child(b_root)

		# Dense Bush Mound
		var b_sphere = SphereMesh.new()
		b_sphere.radius = 0.55
		b_sphere.height = 0.85
		var bs_mi = MeshInstance3D.new()
		bs_mi.mesh = b_sphere
		bs_mi.material_override = _bush_leaf_mat
		bs_mi.position.y = 0.425
		b_root.add_child(bs_mi)

		# Ruby Berry Nodes
		var berry_nodes: Array[MeshInstance3D] = []
		for b_i in range(5):
			var b_mesh = SphereMesh.new()
			b_mesh.radius = 0.05
			b_mesh.height = 0.10
			var bm_mi = MeshInstance3D.new()
			bm_mi.mesh = b_mesh
			bm_mi.material_override = _berry_mat
			var ang: float = float(b_i) * (TAU / 5.0)
			bm_mi.position = Vector3(cos(ang) * 0.45, 0.45 + randf_range(-0.1, 0.1), sin(ang) * 0.45)
			b_root.add_child(bm_mi)
			berry_nodes.append(bm_mi)

		_bushes.append({
			"id": "wild_raspberry_%d" % i,
			"root": b_root,
			"pos": b_pos,
			"berries": berry_nodes,
			"harvested": false,
			"name": "Bụi Mâm Xôi Dại",
			"item_id": "wild_raspberry"
		})

func get_nearby_forageable(pos: Vector3, max_dist: float = 2.4) -> Dictionary:
	for b in _bushes:
		if not b["harvested"] and pos.distance_to(b["pos"]) <= max_dist:
			return {
				"id": b["id"],
				"type": "bush",
				"name": b["name"],
				"item_id": b["item_id"],
				"icon": "🫐",
				"exp": 15,
				"pos": b["pos"]
			}
	return {}

func harvest_bush(bush_id: String) -> Dictionary:
	for b in _bushes:
		if b["id"] == bush_id and not b["harvested"]:
			b["harvested"] = true
			for mi in b["berries"]:
				mi.visible = false
			berry_foraged.emit(bush_id, b["item_id"], b["pos"])
			return {
				"item_id": b["item_id"],
				"name": b["name"],
				"icon": "🫐",
				"exp": 15,
				"message": "Đã hái Mâm Xôi Dại (+15 EXP, +1 Mâm Xôi Rừng)"
			}
	return {}

func get_unharvested_count() -> int:
	var c: int = 0
	for b in _bushes:
		if not b["harvested"]:
			c += 1
	return c
