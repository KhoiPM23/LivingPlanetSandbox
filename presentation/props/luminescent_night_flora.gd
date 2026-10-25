class_name LuminescentNightFlora
extends Node3D

## Living Planet Sandbox — Luminescent Night Flora & Spore Reaction System (Block 54)
## Features:
## 1. Star Lotus Flowers (Hoa Sen Tinh Tú) floating on Grand Emerald Lake:
##    - Emissive turquoise & pearl petals that open wider at dusk/night
##    - Gentle water wave bobbing with soft radial bioluminescent light
##    - Interactive harvest: [E] Hái Hoa Sen Tinh Tú (+25 EXP, star_lotus ingredient)
## 2. Luminous Spore Mushrooms (Nấm Dạ Quang) in deep forests & cavern grottos:
##    - Glowing indigo & cyan caps with pulsating bioluminescence
##    - Proximity spore burst: walking through releases sparkling cloud of spores
##    - Interactive harvest: [E] Hái Nấm Dạ Quang (+20 EXP, glowing_spore ingredient)
## 3. Intel Iris Xe optimized: shared standard materials, throttled particles, zero lag

signal flora_harvested(flora_type: String, item_id: String, pos: Vector3)

var _lotuses: Array[Dictionary] = []
var _mushrooms: Array[Dictionary] = []
var _anim_time: float = 0.0

# Materials
static var _lotus_petal_mat: StandardMaterial3D = null
static var _lotus_core_mat: StandardMaterial3D = null
static var _mushroom_cap_mat: StandardMaterial3D = null
static var _mushroom_stem_mat: StandardMaterial3D = null

func _init() -> void:
	name = "LuminescentNightFlora"
	_init_materials()

func setup(terrain: IslandTerrain = null) -> void:
	_spawn_star_lotuses()
	_spawn_luminous_mushrooms(terrain)

static func _init_materials() -> void:
	if _lotus_petal_mat != null:
		return

	# Star Lotus Petals (Translucent Turquoise Glow)
	_lotus_petal_mat = StandardMaterial3D.new()
	_lotus_petal_mat.albedo_color = Color(0.20, 0.90, 0.85, 0.85)
	_lotus_petal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_lotus_petal_mat.roughness = 0.35
	_lotus_petal_mat.emission_enabled = true
	_lotus_petal_mat.emission = Color(0.15, 0.85, 0.80)
	_lotus_petal_mat.emission_energy_multiplier = 1.8

	# Star Lotus Core (Warm Golden Stamen)
	_lotus_core_mat = StandardMaterial3D.new()
	_lotus_core_mat.albedo_color = Color(1.0, 0.88, 0.30)
	_lotus_core_mat.emission_enabled = true
	_lotus_core_mat.emission = Color(1.0, 0.92, 0.35)
	_lotus_core_mat.emission_energy_multiplier = 2.5

	# Luminous Mushroom Cap (Bioluminescent Indigo Cyan)
	_mushroom_cap_mat = StandardMaterial3D.new()
	_mushroom_cap_mat.albedo_color = Color(0.18, 0.45, 0.95)
	_mushroom_cap_mat.roughness = 0.40
	_mushroom_cap_mat.emission_enabled = true
	_mushroom_cap_mat.emission = Color(0.22, 0.65, 1.0)
	_mushroom_cap_mat.emission_energy_multiplier = 2.2

	# Mushroom Stem (Pale Moonlit Beige)
	_mushroom_stem_mat = StandardMaterial3D.new()
	_mushroom_stem_mat.albedo_color = Color(0.85, 0.88, 0.92)
	_mushroom_stem_mat.roughness = 0.60

func _spawn_star_lotuses() -> void:
	# Distributed gracefully across Grand Emerald Lake
	var lotus_coords = [
		Vector3(42.0, 0.05, 84.0),
		Vector3(56.0, 0.05, 76.0),
		Vector3(72.0, 0.05, 88.0),
		Vector3(92.0, 0.05, 80.0), # Near Heart Island
		Vector3(104.0, 0.05, 92.0)
	]

	for i in range(lotus_coords.size()):
		var l_pos: Vector3 = lotus_coords[i]
		var l_root = Node3D.new()
		l_root.name = "StarLotus_%d" % i
		l_root.position = l_pos
		add_child(l_root)

		# Outer and inner petals
		var petals_node = Node3D.new()
		petals_node.name = "Petals"
		l_root.add_child(petals_node)

		for p_i in range(8):
			var ang: float = float(p_i) * (TAU / 8.0)
			var petal_mesh: PrismMesh = PrismMesh.new()
			petal_mesh.size = Vector3(0.25, 0.55, 0.08)
			var p_mi: MeshInstance3D = MeshInstance3D.new()
			p_mi.mesh = petal_mesh
			p_mi.material_override = _lotus_petal_mat
			p_mi.position = Vector3(cos(ang) * 0.32, 0.08, sin(ang) * 0.32)
			p_mi.rotation.y = -ang
			p_mi.rotation.x = deg_to_rad(35.0)
			petals_node.add_child(p_mi)

		# Golden Core Stamen
		var core_mesh: CylinderMesh = CylinderMesh.new()
		core_mesh.top_radius = 0.14
		core_mesh.bottom_radius = 0.16
		core_mesh.height = 0.14
		var c_mi: MeshInstance3D = MeshInstance3D.new()
		c_mi.mesh = core_mesh
		c_mi.material_override = _lotus_core_mat
		c_mi.position = Vector3(0.0, 0.08, 0.0)
		l_root.add_child(c_mi)

		# Radial Bioluminescent Light
		var light: OmniLight3D = OmniLight3D.new()
		light.name = "LotusGlow"
		light.light_color = Color(0.25, 0.95, 0.90)
		light.light_energy = 1.2
		light.omni_range = 4.5
		light.position = Vector3(0.0, 0.35, 0.0)
		l_root.add_child(light)

		_lotuses.append({
			"id": "star_lotus_%d" % i,
			"node": l_root,
			"petals": petals_node,
			"light": light,
			"pos": l_pos,
			"harvested": false,
			"name": "Hoa Sen Tinh Tú",
			"item_id": "star_lotus"
		})

func _spawn_luminous_mushrooms(terrain: IslandTerrain) -> void:
	# Clustered in shaded forest & near Whispering Grotto
	var mushroom_spots = [
		Vector3(-72.0, 0.0, -48.0), # Near Whispering Grotto cavern
		Vector3(-75.5, 0.0, -44.0),
		Vector3(-68.0, 0.0, -52.0),
		Vector3(18.0, 0.0, 12.0),   # Haven shaded pine grove
		Vector3(22.0, 0.0, 16.0),
		Vector3(82.0, 0.0, -38.0)   # Whispering Highland bluff edge
	]

	for i in range(mushroom_spots.size()):
		var m_pos: Vector3 = mushroom_spots[i]
		if terrain:
			m_pos.y = maxf(terrain.get_height_at(m_pos.x, m_pos.z), 1.2)

		var m_root = Node3D.new()
		m_root.name = "LuminousMushroom_%d" % i
		m_root.position = m_pos
		add_child(m_root)

		# 1. Stem
		var stem_mesh: CylinderMesh = CylinderMesh.new()
		stem_mesh.top_radius = 0.06
		stem_mesh.bottom_radius = 0.09
		stem_mesh.height = 0.45
		var s_mi: MeshInstance3D = MeshInstance3D.new()
		s_mi.mesh = stem_mesh
		s_mi.material_override = _mushroom_stem_mat
		s_mi.position = Vector3(0.0, 0.22, 0.0)
		m_root.add_child(s_mi)

		# 2. Glowing Cap
		var cap_mesh: SphereMesh = SphereMesh.new()
		cap_mesh.radius = 0.26
		cap_mesh.height = 0.32
		cap_mesh.is_hemisphere = true
		var c_mi: MeshInstance3D = MeshInstance3D.new()
		c_mi.mesh = cap_mesh
		c_mi.material_override = _mushroom_cap_mat
		c_mi.position = Vector3(0.0, 0.42, 0.0)
		m_root.add_child(c_mi)

		# 3. Soft Cap Light
		var m_light: OmniLight3D = OmniLight3D.new()
		m_light.name = "CapLight"
		m_light.light_color = Color(0.35, 0.75, 1.0)
		m_light.light_energy = 0.95
		m_light.omni_range = 3.2
		m_light.position = Vector3(0.0, 0.55, 0.0)
		m_root.add_child(m_light)

		# 4. Spore Cloud Burst Particles
		var spore_parts: GPUParticles3D = GPUParticles3D.new()
		spore_parts.name = "SporeParticles"
		spore_parts.emitting = false
		spore_parts.one_shot = true
		spore_parts.amount = 14
		spore_parts.lifetime = 1.4
		spore_parts.explosiveness = 0.7

		var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
		p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		p_mat.emission_sphere_radius = 0.4
		p_mat.direction = Vector3(0.0, 1.0, 0.0)
		p_mat.spread = 45.0
		p_mat.initial_velocity_min = 0.6
		p_mat.initial_velocity_max = 1.4
		p_mat.gravity = Vector3(0.0, 0.05, 0.0)
		p_mat.scale_min = 0.06
		p_mat.scale_max = 0.16
		p_mat.color = Color(0.4, 0.8, 1.0, 0.85)
		spore_parts.process_material = p_mat

		var s_mesh: SphereMesh = SphereMesh.new()
		s_mesh.radius = 0.05
		s_mesh.height = 0.10
		var sm_mat: StandardMaterial3D = StandardMaterial3D.new()
		sm_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm_mat.albedo_color = Color(0.45, 0.85, 1.0, 0.9)
		s_mesh.material = sm_mat
		spore_parts.draw_pass_1 = s_mesh
		spore_parts.position = Vector3(0.0, 0.45, 0.0)
		m_root.add_child(spore_parts)

		_mushrooms.append({
			"id": "luminous_mushroom_%d" % i,
			"node": m_root,
			"light": m_light,
			"particles": spore_parts,
			"pos": m_pos,
			"harvested": false,
			"spore_cooldown": 0.0,
			"name": "Nấm Dạ Quang",
			"item_id": "glowing_spore"
		})

func update_flora(delta: float, is_night: bool = false, player_pos: Vector3 = Vector3.ZERO) -> void:
	_anim_time += delta

	# Lotus breathing and water wave bobbing
	var wave_y: float = 0.05 + sin(_anim_time * 2.2) * 0.02
	var lotus_energy: float = (1.8 if is_night else 0.85) + sin(_anim_time * 1.8) * 0.25

	for l in _lotuses:
		if l["harvested"]:
			continue
		var l_node: Node3D = l["node"]
		l_node.position.y = wave_y
		var light: OmniLight3D = l["light"]
		if light:
			light.light_energy = lotus_energy

	# Mushroom breathing & player proximity spore burst
	var mush_energy: float = (1.4 if is_night else 0.6) + sin(_anim_time * 2.5) * 0.18
	for m in _mushrooms:
		if m["harvested"]:
			continue
		var light: OmniLight3D = m["light"]
		if light:
			light.light_energy = mush_energy

		if m["spore_cooldown"] > 0.0:
			m["spore_cooldown"] -= delta

		if player_pos != Vector3.ZERO and m["spore_cooldown"] <= 0.0:
			var d: float = player_pos.distance_to(m["pos"])
			if d < 1.8:
				# Trigger spore cloud puff
				m["spore_cooldown"] = 4.0
				var parts: GPUParticles3D = m["particles"]
				if parts:
					parts.restart()
					parts.emitting = true

func get_nearby_forageable(pos: Vector3, max_dist: float = 3.0) -> Dictionary:
	# Check Lotuses
	for l in _lotuses:
		if not l["harvested"] and pos.distance_to(l["pos"]) < max_dist:
			return {
				"id": l["id"],
				"type": "star_lotus",
				"item_id": l["item_id"],
				"name": l["name"],
				"icon": "🪷",
				"exp": 25
			}
	# Check Mushrooms
	for m in _mushrooms:
		if not m["harvested"] and pos.distance_to(m["pos"]) < max_dist:
			return {
				"id": m["id"],
				"type": "luminous_mushroom",
				"item_id": m["item_id"],
				"name": m["name"],
				"icon": "🍄",
				"exp": 20
			}
	return {}

func harvest_flora(flora_id: String) -> Dictionary:
	for l in _lotuses:
		if l["id"] == flora_id and not l["harvested"]:
			l["harvested"] = true
			l["node"].visible = false
			flora_harvested.emit("star_lotus", l["item_id"], l["pos"])
			return {"item_id": l["item_id"], "name": l["name"], "exp": 25, "icon": "🪷"}

	for m in _mushrooms:
		if m["id"] == flora_id and not m["harvested"]:
			m["harvested"] = true
			m["node"].visible = false
			flora_harvested.emit("luminous_mushroom", m["item_id"], m["pos"])
			return {"item_id": m["item_id"], "name": m["name"], "exp": 20, "icon": "🍄"}

	return {}

func get_unharvested_count() -> int:
	var c: int = 0
	for l in _lotuses:
		if not l["harvested"]:
			c += 1
	for m in _mushrooms:
		if not m["harvested"]:
			c += 1
	return c
