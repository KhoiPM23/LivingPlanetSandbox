class_name ForagingNodes
extends Node3D

## Living Planet Sandbox — Block 48 Genshin-Style Collectible Flora & Island Foraging System
## Scatters interactive glowing plants, berries, frostmint herbs, and starconches across biomes.
## Provides proximity detection and interactive harvest mechanics with item pickup toasts.

signal item_foraged(item_id: String, item_name: String, count: int, icon: String)

class ForageNodeData:
	var id: String
	var type: String
	var item_id: String
	var item_name: String
	var icon: String
	var pos: Vector3
	var is_collected: bool = false
	var respawn_timer: float = 0.0
	var visual_root: Node3D = null
	var light: OmniLight3D = null

var nodes: Array[ForageNodeData] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

const RESPAWN_DELAY: float = 120.0 # 2 minutes

func _init() -> void:
	name = "ForagingNodes"

func setup(terrain: IslandTerrain, seed_val: int = 1337) -> void:
	_rng.seed = seed_val ^ 0xFEED5EED
	_clear_existing()

	# Define distribution clusters across Island Biomes (720m island scale)
	# 1. Glade & Forest Berries
	_scatter_cluster(terrain, "amber_berries", "forest_berries", "Dâu Rừng Hổ Phách", "🍓", 10, 8.0, 75.0, 2.0, 18.0, Color(1.0, 0.65, 0.20))

	# 2. Alpine Windwheel Herbs
	_scatter_cluster(terrain, "windwheel_aster", "mountain_herbs", "Cỏ Gió Vực Thẳm", "🌸", 8, 45.0, 160.0, 18.0, 48.0, Color(0.35, 0.95, 0.85))

	# 3. Skyspire Frostmint
	_scatter_cluster(terrain, "frostmint_herbs", "mountain_herbs", "Thảo Dược Băng Sơn", "❄️", 6, 20.0, 90.0, 48.0, 80.0, Color(0.65, 0.85, 1.0))

	# 4. Coastal Shoreline Starconch
	_scatter_coastal_cluster(terrain, "starconch", "pearl_oyster", "Vỏ Ốc Ngôi Sao", "🐚", 8, 240.0, 310.0, Color(0.40, 0.90, 1.0))

	print("[ForagingNodes] Initialized %d interactive foraging nodes across island biomes." % nodes.size())

func _clear_existing() -> void:
	for n in nodes:
		if n.visual_root and is_instance_valid(n.visual_root):
			n.visual_root.queue_free()
	nodes.clear()

func _scatter_cluster(
	terrain: IslandTerrain,
	type: String,
	item_id: String,
	item_name: String,
	icon: String,
	count: int,
	min_radius: float,
	max_radius: float,
	min_height: float,
	max_height: float,
	glow_color: Color
) -> void:
	for i in range(count):
		var angle: float = _rng.randf_range(0.0, TAU)
		var rad: float = _rng.randf_range(min_radius, max_radius)
		var x: float = cos(angle) * rad
		var z: float = sin(angle) * rad

		var h: float = 3.0
		if terrain:
			h = terrain.get_height_at(x, z)

		if h < min_height or h > max_height:
			continue

		var pos: Vector3 = Vector3(x, h, z)
		var data: ForageNodeData = ForageNodeData.new()
		data.id = "%s_%d" % [type, nodes.size()]
		data.type = type
		data.item_id = item_id
		data.item_name = item_name
		data.icon = icon
		data.pos = pos

		_create_visual(data, glow_color)
		nodes.append(data)

func _scatter_coastal_cluster(
	terrain: IslandTerrain,
	type: String,
	item_id: String,
	item_name: String,
	icon: String,
	count: int,
	min_radius: float,
	max_radius: float,
	glow_color: Color
) -> void:
	for i in range(count):
		var angle: float = _rng.randf_range(0.0, TAU)
		var rad: float = _rng.randf_range(min_radius, max_radius)
		var x: float = cos(angle) * rad
		var z: float = sin(angle) * rad

		var h: float = 0.5
		if terrain:
			h = terrain.get_height_at(x, z)

		if h < 0.2 or h > 1.8:
			continue

		var pos: Vector3 = Vector3(x, h, z)
		var data: ForageNodeData = ForageNodeData.new()
		data.id = "%s_%d" % [type, nodes.size()]
		data.type = type
		data.item_id = item_id
		data.item_name = item_name
		data.icon = icon
		data.pos = pos

		_create_visual(data, glow_color)
		nodes.append(data)

func _create_visual(data: ForageNodeData, glow_color: Color) -> void:
	var root: Node3D = Node3D.new()
	root.name = data.id
	root.position = data.pos
	add_child(root)
	data.visual_root = root

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = glow_color
	mat.emission_enabled = true
	mat.emission = glow_color
	mat.emission_energy_multiplier = 1.4
	mat.roughness = 0.35

	match data.type:
		"amber_berries":
			# Shrub with glowing berries
			var stem: MeshInstance3D = MeshInstance3D.new()
			var cyl: CylinderMesh = CylinderMesh.new()
			cyl.top_radius = 0.25
			cyl.bottom_radius = 0.08
			cyl.height = 0.55
			stem.mesh = cyl
			var stem_mat: StandardMaterial3D = StandardMaterial3D.new()
			stem_mat.albedo_color = Color(0.18, 0.42, 0.16)
			stem.material_override = stem_mat
			stem.position.y = 0.28
			root.add_child(stem)

			for b in range(3):
				var berry: MeshInstance3D = MeshInstance3D.new()
				var sph: SphereMesh = SphereMesh.new()
				sph.radius = 0.11
				sph.height = 0.22
				berry.mesh = sph
				berry.material_override = mat
				var b_ang: float = b * (TAU / 3.0)
				berry.position = Vector3(cos(b_ang) * 0.22, 0.48, sin(b_ang) * 0.22)
				root.add_child(berry)

		"windwheel_aster":
			# Flower stalk + petal disc
			var stalk: MeshInstance3D = MeshInstance3D.new()
			var st_cyl: CylinderMesh = CylinderMesh.new()
			st_cyl.top_radius = 0.03
			st_cyl.bottom_radius = 0.04
			st_cyl.height = 0.65
			stalk.mesh = st_cyl
			var st_mat: StandardMaterial3D = StandardMaterial3D.new()
			st_mat.albedo_color = Color(0.2, 0.5, 0.25)
			stalk.material_override = st_mat
			stalk.position.y = 0.32
			root.add_child(stalk)

			var petals: MeshInstance3D = MeshInstance3D.new()
			var p_mesh: PrismMesh = PrismMesh.new()
			p_mesh.size = Vector3(0.42, 0.10, 0.42)
			petals.mesh = p_mesh
			petals.material_override = mat
			petals.position.y = 0.66
			root.add_child(petals)

		"frostmint_herbs":
			# Shimmering icy crystals
			var crystal: MeshInstance3D = MeshInstance3D.new()
			var c_mesh: PrismMesh = PrismMesh.new()
			c_mesh.size = Vector3(0.25, 0.70, 0.25)
			crystal.mesh = c_mesh
			crystal.material_override = mat
			crystal.position.y = 0.35
			root.add_child(crystal)

		"starconch":
			# Spiral cone shell on sand
			var shell: MeshInstance3D = MeshInstance3D.new()
			var sh_mesh: CylinderMesh = CylinderMesh.new()
			sh_mesh.top_radius = 0.18
			sh_mesh.bottom_radius = 0.02
			sh_mesh.height = 0.32
			shell.mesh = sh_mesh
			shell.material_override = mat
			shell.position.y = 0.12
			shell.rotation.z = deg_to_rad(35.0)
			root.add_child(shell)

	# Gentle beacon light
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = glow_color
	light.light_energy = 0.8
	light.omni_range = 3.5
	light.shadow_enabled = false
	light.position.y = 0.45
	root.add_child(light)
	data.light = light

func get_nearby_forageable(player_pos: Vector3, max_dist: float = 2.8) -> Dictionary:
	var best_dist: float = max_dist
	var best_node: ForageNodeData = null

	for n in nodes:
		if n.is_collected:
			continue
		var d: float = player_pos.distance_to(n.pos)
		if d < best_dist:
			best_dist = d
			best_node = n

	if best_node != null:
		return {
			"id": best_node.id,
			"type": best_node.type,
			"item_id": best_node.item_id,
			"item_name": best_node.item_name,
			"icon": best_node.icon,
			"pos": best_node.pos,
			"dist": best_dist
		}
	return {}

func collect_node(node_id: String) -> Dictionary:
	for n in nodes:
		if n.id == node_id and not n.is_collected:
			n.is_collected = true
			n.respawn_timer = RESPAWN_DELAY
			if n.visual_root:
				n.visual_root.visible = false
			if n.light:
				n.light.visible = false
			var count: int = 2 if n.type == "amber_berries" else 1
			item_foraged.emit(n.item_id, n.item_name, count, n.icon)
			return {
				"item_id": n.item_id,
				"item_name": n.item_name,
				"count": count,
				"icon": n.icon
			}
	return {}

func get_total_nodes() -> int:
	return nodes.size()

func get_uncollected_count() -> int:
	var cnt: int = 0
	for n in nodes:
		if not n.is_collected:
			cnt += 1
	return cnt

func _process(delta: float) -> void:
	# Handle gentle bobbing and respawns
	var time: float = Time.get_ticks_msec() * 0.002
	for n in nodes:
		if n.is_collected:
			n.respawn_timer -= delta
			if n.respawn_timer <= 0.0:
				n.is_collected = false
				if n.visual_root:
					n.visual_root.visible = true
				if n.light:
					n.light.visible = true
		elif n.visual_root:
			# Subtle pulsing rotation
			n.visual_root.rotation.y += delta * 0.75
			var bob: float = sin(time + float(n.id.hash() % 100)) * 0.04
			n.visual_root.position.y = n.pos.y + bob
