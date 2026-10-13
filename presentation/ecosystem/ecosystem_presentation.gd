class_name EcosystemPresentation
extends Node3D

## Visual presentation layer for living fauna and dynamic flora.
## Purely reflects simulation state. Zero business logic or simulation state mutation.
## Optimized: Shared static meshes & materials, selective shadow culling, dirty transform caching.

var _coordinator: EcosystemCoordinator = null
var _herbivore_nodes: Dictionary = {} # int id -> Node3D
var _predator_nodes: Dictionary = {} # int id -> Node3D
var _plant_nodes: Dictionary = {} # int id -> Node3D

var _anim_time: float = 0.0

# --- SHARED STATIC MESHES & MATERIALS (Vulkan Pipeline State Caching) ---
var _mesh_herb_body: BoxMesh
var _mat_herb_body: StandardMaterial3D
var _mesh_herb_head: BoxMesh
var _mat_herb_head: StandardMaterial3D
var _mesh_herb_horn: CylinderMesh
var _mat_herb_horn: StandardMaterial3D

var _mesh_pred_body: BoxMesh
var _mat_pred_body: StandardMaterial3D
var _mesh_pred_head: PrismMesh
var _mat_pred_head: StandardMaterial3D
var _mesh_pred_eye: SphereMesh
var _mat_pred_eye: StandardMaterial3D

var _mesh_shrub: SphereMesh
var _mat_shrub: StandardMaterial3D
var _mesh_grass: SphereMesh
var _mat_grass: StandardMaterial3D

func _init() -> void:
	_init_shared_resources()

func _init_shared_resources() -> void:
	# Herbivore resources
	_mesh_herb_body = BoxMesh.new()
	_mesh_herb_body.size = Vector3(0.7, 0.6, 1.2)
	_mat_herb_body = StandardMaterial3D.new()
	_mat_herb_body.albedo_color = Color(0.72, 0.55, 0.38)
	_mat_herb_body.roughness = 0.85

	_mesh_herb_head = BoxMesh.new()
	_mesh_herb_head.size = Vector3(0.4, 0.4, 0.5)
	_mat_herb_head = StandardMaterial3D.new()
	_mat_herb_head.albedo_color = Color(0.65, 0.48, 0.32)
	_mat_herb_head.roughness = 0.85

	_mesh_herb_horn = CylinderMesh.new()
	_mesh_herb_horn.top_radius = 0.02
	_mesh_herb_horn.bottom_radius = 0.06
	_mesh_herb_horn.height = 0.35
	_mat_herb_horn = StandardMaterial3D.new()
	_mat_herb_horn.albedo_color = Color(0.85, 0.82, 0.72)

	# Predator resources
	_mesh_pred_body = BoxMesh.new()
	_mesh_pred_body.size = Vector3(0.65, 0.55, 1.4)
	_mat_pred_body = StandardMaterial3D.new()
	_mat_pred_body.albedo_color = Color(0.22, 0.25, 0.30)
	_mat_pred_body.roughness = 0.75

	_mesh_pred_head = PrismMesh.new()
	_mesh_pred_head.size = Vector3(0.45, 0.45, 0.6)
	_mat_pred_head = StandardMaterial3D.new()
	_mat_pred_head.albedo_color = Color(0.16, 0.18, 0.22)

	_mesh_pred_eye = SphereMesh.new()
	_mesh_pred_eye.radius = 0.05
	_mesh_pred_eye.height = 0.1
	_mat_pred_eye = StandardMaterial3D.new()
	_mat_pred_eye.albedo_color = Color(1.0, 0.6, 0.1)
	_mat_pred_eye.emission_enabled = true
	_mat_pred_eye.emission = Color(1.0, 0.6, 0.1)
	_mat_pred_eye.emission_energy_multiplier = 2.0

	# Flora resources
	_mesh_shrub = SphereMesh.new()
	_mesh_shrub.radius = 0.5
	_mesh_shrub.height = 0.8
	_mat_shrub = StandardMaterial3D.new()
	_mat_shrub.albedo_color = Color(0.24, 0.52, 0.28)
	_mat_shrub.roughness = 0.9

	_mesh_grass = SphereMesh.new()
	_mesh_grass.radius = 0.35
	_mesh_grass.height = 0.5
	_mat_grass = StandardMaterial3D.new()
	_mat_grass.albedo_color = Color(0.38, 0.72, 0.32)
	_mat_grass.roughness = 0.9

	# Selection Indicator Resources
	_mesh_select_ring = TorusMesh.new()
	_mesh_select_ring.inner_radius = 0.95
	_mesh_select_ring.outer_radius = 1.15
	_mesh_select_ring.rings = 24
	_mesh_select_ring.ring_segments = 12
	_mat_select_ring = StandardMaterial3D.new()
	_mat_select_ring.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_select_ring.albedo_color = Color(0.25, 0.85, 1.0, 0.85)
	_mat_select_ring.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Setup Selection Marker Node
	_selection_marker = MeshInstance3D.new()
	_selection_marker.name = "InspectionSelectionRing"
	_selection_marker.mesh = _mesh_select_ring
	_selection_marker.material_override = _mat_select_ring
	_selection_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_selection_marker.visible = false
	add_child(_selection_marker)

var _mesh_select_ring: TorusMesh
var _mat_select_ring: StandardMaterial3D
var _selection_marker: MeshInstance3D
var inspected_entity_id: int = -1

func set_inspected_entity(id: int) -> void:
	inspected_entity_id = id
	if not _selection_marker:
		return
	if id <= 0:
		_selection_marker.visible = false
	else:
		_selection_marker.visible = true

func setup(coordinator: EcosystemCoordinator) -> void:
	_coordinator = coordinator

func _process(delta: float) -> void:
	if not _coordinator or not is_visible_in_tree():
		return

	_anim_time += delta
	_update_herbivores(delta)
	_update_predators(delta)
	_update_plants()
	_update_selection_marker(delta)

func _update_selection_marker(delta: float) -> void:
	if not _selection_marker or not _selection_marker.visible:
		return
	_selection_marker.rotation.y += delta * 2.0

	var target_node: Node3D = null
	if _herbivore_nodes.has(inspected_entity_id):
		target_node = _herbivore_nodes[inspected_entity_id]
	elif _predator_nodes.has(inspected_entity_id):
		target_node = _predator_nodes[inspected_entity_id]
	elif _plant_nodes.has(inspected_entity_id):
		target_node = _plant_nodes[inspected_entity_id]

	if target_node and is_instance_valid(target_node):
		_selection_marker.position = target_node.position + Vector3(0.0, 0.05, 0.0)
		var base_scale: float = target_node.scale.x * 1.15
		_selection_marker.scale = Vector3(base_scale, 1.0, base_scale)
	else:
		_selection_marker.visible = false

func _update_herbivores(delta: float) -> void:
	var active_herbivores: Array = _coordinator.fauna_sim.get_all_herbivores()
	var active_ids: Dictionary = {}

	for h in active_herbivores:
		active_ids[h.id] = true
		var node: Node3D = _herbivore_nodes.get(h.id, null)
		if node == null:
			node = _create_herbivore_mesh()
			add_child(node)
			_herbivore_nodes[h.id] = node
			node.position = h.position

		var target_pos: Vector3 = h.position
		var head_node: Node3D = node.get_node_or_null("Head") as Node3D
		var is_moving: bool = h.velocity.length_squared() > 0.1
		var hop: float = 0.0

		# Dynamic behavior animation reflecting simulation state
		match h.state:
			FaunaSimulation.HerbivoreState.RESTING:
				target_pos.y -= 0.18
				target_pos.y += sin(_anim_time * 2.5) * 0.02
				if head_node:
					head_node.position.y = lerpf(head_node.position.y, 0.62, clampf(delta * 8.0, 0.0, 1.0))
					head_node.rotation.x = lerp_angle(head_node.rotation.x, deg_to_rad(15.0), clampf(delta * 8.0, 0.0, 1.0))
			FaunaSimulation.HerbivoreState.EATING:
				target_pos.y -= 0.04
				if head_node:
					var chew_bob: float = sin(_anim_time * 12.0) * 0.03
					head_node.position.y = lerpf(head_node.position.y, 0.45 + chew_bob, clampf(delta * 10.0, 0.0, 1.0))
					head_node.rotation.x = lerp_angle(head_node.rotation.x, deg_to_rad(32.0), clampf(delta * 10.0, 0.0, 1.0))
			FaunaSimulation.HerbivoreState.FLEEING:
				hop = absf(sin(_anim_time * 16.0)) * 0.22 if is_moving else 0.0
				target_pos.y += hop
				node.rotation.x = lerp_angle(node.rotation.x, deg_to_rad(10.0), clampf(delta * 10.0, 0.0, 1.0))
				if head_node:
					head_node.position.y = lerpf(head_node.position.y, 0.85, clampf(delta * 10.0, 0.0, 1.0))
					head_node.rotation.x = lerp_angle(head_node.rotation.x, 0.0, clampf(delta * 10.0, 0.0, 1.0))
			FaunaSimulation.HerbivoreState.STARVING:
				target_pos.x += sin(_anim_time * 26.0) * 0.03
				target_pos.y -= 0.08
				hop = absf(sin(_anim_time * 4.0)) * 0.06 if is_moving else 0.0
				target_pos.y += hop
				if head_node:
					head_node.position.y = lerpf(head_node.position.y, 0.58, clampf(delta * 6.0, 0.0, 1.0))
					head_node.rotation.x = lerp_angle(head_node.rotation.x, deg_to_rad(20.0), clampf(delta * 6.0, 0.0, 1.0))
			_: # WANDERING, FORAGING
				hop = absf(sin(_anim_time * 8.0)) * 0.14 if is_moving else 0.0
				target_pos.y += hop
				node.rotation.x = lerp_angle(node.rotation.x, 0.0, clampf(delta * 8.0, 0.0, 1.0))
				if head_node:
					head_node.position.y = lerpf(head_node.position.y, 0.85, clampf(delta * 8.0, 0.0, 1.0))
					head_node.rotation.x = lerp_angle(head_node.rotation.x, 0.0, clampf(delta * 8.0, 0.0, 1.0))

		node.position = node.position.lerp(target_pos, clampf(delta * 12.0, 0.0, 1.0))

		if is_moving:
			var target_rot_y: float = -h.heading + PI * 0.5
			node.rotation.y = lerp_angle(node.rotation.y, target_rot_y, clampf(delta * 10.0, 0.0, 1.0))

		var target_scale: float = 0.6 if h.life_stage == FaunaSimulation.LifeStage.JUVENILE else 1.0
		if not is_equal_approx(node.scale.x, target_scale):
			node.scale = Vector3(target_scale, target_scale, target_scale)

	for id: int in _herbivore_nodes.keys():
		if not active_ids.has(id):
			_herbivore_nodes[id].queue_free()
			_herbivore_nodes.erase(id)

func _update_predators(delta: float) -> void:
	var active_predators: Array = _coordinator.fauna_sim.get_all_predators()
	var active_ids: Dictionary = {}

	for p in active_predators:
		active_ids[p.id] = true
		var node: Node3D = _predator_nodes.get(p.id, null)
		if node == null:
			node = _create_predator_mesh()
			add_child(node)
			_predator_nodes[p.id] = node
			node.position = p.position

		var target_pos: Vector3 = p.position
		var head_node: Node3D = node.get_node_or_null("Head") as Node3D
		var is_moving: bool = p.velocity.length_squared() > 0.1
		var prowl_bob: float = 0.0

		match p.state:
			FaunaSimulation.PredatorState.RESTING:
				target_pos.y -= 0.18
				target_pos.y += sin(_anim_time * 2.2) * 0.015
			FaunaSimulation.PredatorState.EATING:
				target_pos.y -= 0.08
				if head_node:
					head_node.position.y = lerpf(head_node.position.y, 0.40, clampf(delta * 10.0, 0.0, 1.0))
			FaunaSimulation.PredatorState.HUNTING:
				target_pos.y -= 0.10
				prowl_bob = absf(sin(_anim_time * 14.0)) * 0.14 if is_moving else 0.0
				target_pos.y += prowl_bob
			FaunaSimulation.PredatorState.STARVING:
				target_pos.x += sin(_anim_time * 24.0) * 0.03
				prowl_bob = absf(sin(_anim_time * 4.0)) * 0.04 if is_moving else 0.0
				target_pos.y += prowl_bob
			_: # WANDERING
				prowl_bob = absf(sin(_anim_time * 6.0)) * 0.08 if is_moving else 0.0
				target_pos.y += prowl_bob
				if head_node:
					head_node.position.y = lerpf(head_node.position.y, 0.60, clampf(delta * 8.0, 0.0, 1.0))

		node.position = node.position.lerp(target_pos, clampf(delta * 12.0, 0.0, 1.0))

		if is_moving:
			var target_rot_y: float = -p.heading + PI * 0.5
			node.rotation.y = lerp_angle(node.rotation.y, target_rot_y, clampf(delta * 10.0, 0.0, 1.0))

	for id: int in _predator_nodes.keys():
		if not active_ids.has(id):
			_predator_nodes[id].queue_free()
			_predator_nodes.erase(id)

func _update_plants() -> void:
	var active_plants: Array = _coordinator.flora_sim.get_all_plants()
	var active_ids: Dictionary = {}

	for pl in active_plants:
		active_ids[pl.id] = true
		var node: Node3D = _plant_nodes.get(pl.id, null)
		if node == null:
			node = _create_plant_mesh(pl.species)
			add_child(node)
			_plant_nodes[pl.id] = node
			node.position = pl.position

		var target_scale: float = 0.4 + (pl.biomass / pl.max_biomass) * 0.8
		if absf(node.scale.x - target_scale) > 0.02:
			node.scale = Vector3(target_scale, target_scale, target_scale)

	for id: int in _plant_nodes.keys():
		if not active_ids.has(id):
			_plant_nodes[id].queue_free()
			_plant_nodes.erase(id)

## Low-poly stylized herbivore model using shared meshes and materials
func _create_herbivore_mesh() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "HerbivoreView"

	var body_inst: MeshInstance3D = MeshInstance3D.new()
	body_inst.name = "Body"
	body_inst.mesh = _mesh_herb_body
	body_inst.material_override = _mat_herb_body
	body_inst.position = Vector3(0.0, 0.5, 0.0)
	root.add_child(body_inst)

	var head_inst: MeshInstance3D = MeshInstance3D.new()
	head_inst.name = "Head"
	head_inst.mesh = _mesh_herb_head
	head_inst.material_override = _mat_herb_head
	head_inst.position = Vector3(0.0, 0.85, 0.5)
	root.add_child(head_inst)

	var horn_left: MeshInstance3D = MeshInstance3D.new()
	horn_left.name = "HornLeft"
	horn_left.mesh = _mesh_herb_horn
	horn_left.material_override = _mat_herb_horn
	horn_left.position = Vector3(-0.15, 1.15, 0.45)
	horn_left.rotation_degrees = Vector3(15, 0, -15)
	root.add_child(horn_left)

	var horn_right: MeshInstance3D = MeshInstance3D.new()
	horn_right.name = "HornRight"
	horn_right.mesh = _mesh_herb_horn
	horn_right.material_override = _mat_herb_horn
	horn_right.position = Vector3(0.15, 1.15, 0.45)
	horn_right.rotation_degrees = Vector3(15, 0, 15)
	root.add_child(horn_right)

	return root

## Low-poly stylized predator model using shared meshes and materials
func _create_predator_mesh() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "PredatorView"

	var body_inst: MeshInstance3D = MeshInstance3D.new()
	body_inst.name = "Body"
	body_inst.mesh = _mesh_pred_body
	body_inst.material_override = _mat_pred_body
	body_inst.position = Vector3(0.0, 0.45, 0.0)
	root.add_child(body_inst)

	var head_inst: MeshInstance3D = MeshInstance3D.new()
	head_inst.name = "Head"
	head_inst.mesh = _mesh_pred_head
	head_inst.material_override = _mat_pred_head
	head_inst.position = Vector3(0.0, 0.6, 0.7)
	head_inst.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(head_inst)

	var eye_l: MeshInstance3D = MeshInstance3D.new()
	eye_l.mesh = _mesh_pred_eye
	eye_l.material_override = _mat_pred_eye
	eye_l.position = Vector3(-0.12, 0.62, 0.82)
	root.add_child(eye_l)

	var eye_r: MeshInstance3D = MeshInstance3D.new()
	eye_r.mesh = _mesh_pred_eye
	eye_r.material_override = _mat_pred_eye
	eye_r.position = Vector3(0.12, 0.62, 0.82)
	root.add_child(eye_r)

	return root

## Stylized plant mesh using shared meshes, materials, and selective shadow casting
func _create_plant_mesh(species: String) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "PlantView_" + species

	var inst: MeshInstance3D = MeshInstance3D.new()
	if species == "shrub_bush":
		inst.mesh = _mesh_shrub
		inst.material_override = _mat_shrub
		inst.position = Vector3(0.0, _mesh_shrub.height * 0.5, 0.0)
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		inst.mesh = _mesh_grass
		inst.material_override = _mat_grass
		inst.position = Vector3(0.0, _mesh_grass.height * 0.5, 0.0)
		# Small ground grass patches don't need expensive shadow map passes
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	root.add_child(inst)
	return root

func clear() -> void:
	for node: Node3D in _herbivore_nodes.values():
		node.queue_free()
	_herbivore_nodes.clear()

	for node: Node3D in _predator_nodes.values():
		node.queue_free()
	_predator_nodes.clear()

	for node: Node3D in _plant_nodes.values():
		node.queue_free()
	_plant_nodes.clear()

## Returns the 3D visual scene node representing an entity, or null if uninstantiated
func get_entity_node(id: int) -> Node3D:
	if _herbivore_nodes.has(id):
		return _herbivore_nodes[id]
	if _predator_nodes.has(id):
		return _predator_nodes[id]
	if _plant_nodes.has(id):
		return _plant_nodes[id]
	return null

## Returns the current global position of an entity presentation node, or Vector3.ZERO
func get_entity_position(id: int) -> Vector3:
	var n: Node3D = get_entity_node(id)
	if is_instance_valid(n):
		return n.global_position
	return Vector3.ZERO
