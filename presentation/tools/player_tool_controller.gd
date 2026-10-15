class_name PlayerToolController
extends Node3D

## Manages interactive player sandbox experiment tools:
## Inspection, Moisture Brush (+/-), Entity Placement/Deletion, Simulation speed & reset.
## Provides real simulation impact, 3D cursor visualization, validation, and feedback.

signal tool_changed(mode: ToolMode, mode_name: String)
signal inspection_performed(data: Dictionary)
signal action_feedback(message: String, is_success: bool)
signal radius_changed(new_radius: float)

enum ToolMode {
	NONE = 0,
	INSPECT = 1,
	MOISTURE_ADD = 2,
	MOISTURE_SUB = 3,
	SPAWN_PLANT = 4,
	SPAWN_HERBIVORE = 5,
	SPAWN_PREDATOR = 6,
	DELETE_ENTITY = 7,
	HEATWAVE = 8,
	FROST = 9,
	SOIL_FERTILIZE = 10,
	DISASTER_SHOCK = 11,
	MUTATE_POPULATION = 12,
	CLIMATE_PULSE = 13
}

@export var camera_path: NodePath
@export var bootstrap_path: NodePath
@export var terrain_path: NodePath

var active_tool: ToolMode = ToolMode.INSPECT
var brush_radius: float = 8.0
var moisture_step: float = 0.20
var input_blocked: bool = false

var _camera: Camera3D = null
var _bootstrap: WorldBootstrap = null
var _terrain: IslandTerrain = null

var _brush_visual: MeshInstance3D = null
var _brush_material: StandardMaterial3D = null
var _current_hit_point: Vector3 = Vector3.ZERO
var _has_hit: bool = false

func set_input_blocked(blocked: bool) -> void:
	input_blocked = blocked
	if input_blocked:
		_has_hit = false
		if _brush_visual:
			_brush_visual.visible = false

func is_input_blocked() -> bool:
	return input_blocked

func _ready() -> void:
	if has_node(camera_path):
		_camera = get_node(camera_path) as Camera3D
	if has_node(bootstrap_path):
		_bootstrap = get_node(bootstrap_path) as WorldBootstrap
	if has_node(terrain_path):
		_terrain = get_node(terrain_path) as IslandTerrain

	_create_brush_visual()
	set_tool(ToolMode.INSPECT)

func setup(p_camera: Camera3D, p_bootstrap: WorldBootstrap, p_terrain: IslandTerrain) -> void:
	_camera = p_camera
	_bootstrap = p_bootstrap
	_terrain = p_terrain

func _create_brush_visual() -> void:
	_brush_visual = MeshInstance3D.new()
	_brush_visual.name = "ToolBrushVisual3D"

	# Torus ring indicator
	var ring_mesh: TorusMesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.92
	ring_mesh.outer_radius = 1.0
	ring_mesh.rings = 32
	ring_mesh.ring_segments = 16

	_brush_material = StandardMaterial3D.new()
	_brush_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_brush_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_brush_material.albedo_color = Color(0.3, 0.8, 1.0, 0.75)
	_brush_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	_brush_visual.mesh = ring_mesh
	_brush_visual.material_override = _brush_material
	add_child(_brush_visual)
	_update_visual_radius()

func _update_visual_radius() -> void:
	if _brush_visual:
		_brush_visual.scale = Vector3(brush_radius, 1.0, brush_radius)

func set_tool(new_tool: ToolMode) -> void:
	active_tool = new_tool
	_update_tool_visual_style()
	tool_changed.emit(active_tool, get_tool_name(active_tool))

func get_tool_name(mode: ToolMode) -> String:
	match mode:
		ToolMode.INSPECT: return "Inspect"
		ToolMode.MOISTURE_ADD: return "+ Moisture"
		ToolMode.MOISTURE_SUB: return "- Moisture"
		ToolMode.SPAWN_PLANT: return "+ Plant"
		ToolMode.SPAWN_HERBIVORE: return "+ Herbivore"
		ToolMode.SPAWN_PREDATOR: return "+ Predator"
		ToolMode.DELETE_ENTITY: return "Delete"
		ToolMode.HEATWAVE: return "Heatwave (+8°C)"
		ToolMode.FROST: return "Frost (-8°C)"
		ToolMode.SOIL_FERTILIZE: return "Fertilize (Soil)"
		ToolMode.DISASTER_SHOCK: return "Disaster Shock"
		ToolMode.MUTATE_POPULATION: return "Mutate (Genes)"
		ToolMode.CLIMATE_PULSE: return "Pulse (Deluge)"
		_: return "None"

func set_brush_radius(radius: float) -> void:
	brush_radius = clampf(radius, 3.0, 25.0)
	_update_visual_radius()
	radius_changed.emit(brush_radius)

func _update_tool_visual_style() -> void:
	if not _brush_material:
		return
	var col: Color = Color(1, 1, 1, 0.7)
	match active_tool:
		ToolMode.INSPECT:
			col = Color(0.4, 0.85, 1.0, 0.6)
		ToolMode.MOISTURE_ADD:
			col = Color(0.2, 0.65, 1.0, 0.8)
		ToolMode.MOISTURE_SUB:
			col = Color(1.0, 0.55, 0.2, 0.8)
		ToolMode.SPAWN_PLANT:
			col = Color(0.3, 0.95, 0.4, 0.8)
		ToolMode.SPAWN_HERBIVORE:
			col = Color(1.0, 0.85, 0.35, 0.8)
		ToolMode.SPAWN_PREDATOR:
			col = Color(1.0, 0.25, 0.35, 0.8)
		ToolMode.DELETE_ENTITY:
			col = Color(1.0, 0.15, 0.15, 0.85)
		ToolMode.HEATWAVE:
			col = Color(1.0, 0.45, 0.1, 0.85)
		ToolMode.FROST:
			col = Color(0.2, 0.88, 1.0, 0.85)
		ToolMode.SOIL_FERTILIZE:
			col = Color(0.1, 1.0, 0.4, 0.85)
		ToolMode.DISASTER_SHOCK:
			col = Color(0.95, 0.15, 0.35, 0.85)
		ToolMode.MUTATE_POPULATION:
			col = Color(0.85, 0.25, 1.0, 0.85)
		ToolMode.CLIMATE_PULSE:
			col = Color(0.15, 0.95, 0.90, 0.85)
		_:
			col = Color(0.5, 0.5, 0.5, 0.0)
	_brush_material.albedo_color = col

func _process(_delta: float) -> void:
	if input_blocked:
		_has_hit = false
		if _brush_visual:
			_brush_visual.visible = false
		return
	_update_mouse_raycast()

func _update_mouse_raycast() -> void:
	if input_blocked:
		_has_hit = false
		if _brush_visual:
			_brush_visual.visible = false
		return

	if not _camera:
		var vp: Viewport = get_viewport()
		if vp:
			_camera = vp.get_camera_3d()
	if not _camera:
		_has_hit = false
		if _brush_visual:
			_brush_visual.visible = false
		return

	var mouse_pos: Vector2 = Vector2.ZERO
	var vp_node: Viewport = get_viewport()
	if _camera is FreeLookCamera and (_camera as FreeLookCamera).current_mode == FreeLookCamera.CameraMode.FIRST_PERSON_WALKER:
		if vp_node:
			mouse_pos = vp_node.get_visible_rect().size * 0.5
	else:
		if vp_node:
			mouse_pos = vp_node.get_mouse_position()

	# Don't display 3D tool cursor if mouse is uninitialized at (0, 0) or off-screen
	if mouse_pos == Vector2.ZERO:
		_has_hit = false
		if _brush_visual:
			_brush_visual.visible = false
		return

	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = _camera.project_ray_normal(mouse_pos)

	# Raycast onto terrain static collider
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state if is_inside_tree() else null
	if space_state:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			ray_origin,
			ray_origin + ray_dir * 300.0
		)
		var result: Dictionary = space_state.intersect_ray(query)
		if not result.is_empty():
			_current_hit_point = result.get("position", Vector3.ZERO)
			_has_hit = true
			if _brush_visual:
				_brush_visual.visible = true
				_brush_visual.position = _current_hit_point + Vector3(0.0, 0.08, 0.0)
			return

	# Fallback: intersect with flat ground plane Y = 0
	if absf(ray_dir.y) > 0.001:
		var t: float = -ray_origin.y / ray_dir.y
		if t > 0.0:
			_current_hit_point = ray_origin + ray_dir * t
			if _terrain:
				_current_hit_point.y = _terrain.get_height_at(_current_hit_point.x, _current_hit_point.z)
			_has_hit = true
			if _brush_visual:
				_brush_visual.visible = true
				_brush_visual.position = _current_hit_point + Vector3(0.0, 0.08, 0.0)
			return

	_has_hit = false
	if _brush_visual:
		_brush_visual.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if input_blocked:
		return

	# Tool selection hotkeys [1 - 7]
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_1: set_tool(ToolMode.INSPECT)
			KEY_2: set_tool(ToolMode.MOISTURE_ADD)
			KEY_3: set_tool(ToolMode.MOISTURE_SUB)
			KEY_4: set_tool(ToolMode.SPAWN_PLANT)
			KEY_5: set_tool(ToolMode.SPAWN_HERBIVORE)
			KEY_6: set_tool(ToolMode.SPAWN_PREDATOR)
			KEY_7: set_tool(ToolMode.DELETE_ENTITY)
			KEY_8: set_tool(ToolMode.HEATWAVE)
			KEY_9: set_tool(ToolMode.FROST)
			KEY_0: set_tool(ToolMode.SOIL_FERTILIZE)
			KEY_MINUS: set_tool(ToolMode.DISASTER_SHOCK)
			KEY_EQUAL: set_tool(ToolMode.MUTATE_POPULATION)
			KEY_SEMICOLON: set_tool(ToolMode.CLIMATE_PULSE)
			KEY_BRACKETLEFT:
				set_brush_radius(brush_radius - 2.0)
				action_feedback.emit("Brush radius: %.1fm" % brush_radius, true)
			KEY_BRACKETRIGHT:
				set_brush_radius(brush_radius + 2.0)
				action_feedback.emit("Brush radius: %.1fm" % brush_radius, true)

	# Mouse click action
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			execute_active_tool()

func execute_active_tool() -> void:
	if input_blocked or not _has_hit or not _bootstrap:
		return

	match active_tool:
		ToolMode.INSPECT:
			_execute_inspect()
		ToolMode.MOISTURE_ADD:
			_execute_moisture_brush(moisture_step)
		ToolMode.MOISTURE_SUB:
			_execute_moisture_brush(-moisture_step)
		ToolMode.SPAWN_PLANT:
			_execute_spawn_plant()
		ToolMode.SPAWN_HERBIVORE:
			_execute_spawn_herbivore()
		ToolMode.SPAWN_PREDATOR:
			_execute_spawn_predator()
		ToolMode.DELETE_ENTITY:
			_execute_delete_entity()
		ToolMode.HEATWAVE:
			_execute_heatwave()
		ToolMode.FROST:
			_execute_frost()
		ToolMode.SOIL_FERTILIZE:
			_execute_fertilize()
		ToolMode.DISASTER_SHOCK:
			_execute_disaster_shock()
		ToolMode.MUTATE_POPULATION:
			_execute_mutate_population()
		ToolMode.CLIMATE_PULSE:
			_execute_climate_pulse()

func _execute_inspect() -> void:
	var result: Dictionary = {
		"position": _current_hit_point,
		"entity": null,
		"environment": null
	}

	# 1. Sample Environment
	if _bootstrap.environmental_grid:
		var env: Dictionary = _bootstrap.environmental_grid.get_environment_at(_current_hit_point.x, _current_hit_point.z)
		if _bootstrap.ecosystem_coordinator and _bootstrap.ecosystem_coordinator.causal_tracker:
			env["causal_status"] = _bootstrap.ecosystem_coordinator.causal_tracker.get_causal_status_at(_current_hit_point)
		result["environment"] = env

	# 2. Check for nearby fauna or flora entity
	var closest_entity: Dictionary = _find_closest_entity(_current_hit_point, 3.5)
	if not closest_entity.is_empty():
		result["entity"] = closest_entity
		var id: int = closest_entity.get("id", 0)
		var desc: String = "%s #%d" % [closest_entity.get("species", "Entity"), id]
		action_feedback.emit("Inspected %s" % desc, true)
		_highlight_inspected_entity(id)
	else:
		action_feedback.emit("Inspected terrain at (%.1f, %.1f)" % [_current_hit_point.x, _current_hit_point.z], true)
		_highlight_inspected_entity(-1)

	_spawn_tool_pulse(_current_hit_point, Color(0.3, 0.85, 1.0, 0.9), 1.5)
	inspection_performed.emit(result)

func _highlight_inspected_entity(id: int) -> void:
	var root_node: Node = get_tree().root if get_tree() else null
	if root_node:
		var eco: EcosystemPresentation = root_node.find_child("EcosystemPresentation", true, false) as EcosystemPresentation
		if eco:
			eco.set_inspected_entity(id)

func _spawn_tool_pulse(pos: Vector3, col: Color, radius: float) -> void:
	var pulse: MeshInstance3D = MeshInstance3D.new()
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = 0.85
	mesh.outer_radius = 1.0
	mesh.rings = 20
	mesh.ring_segments = 12
	pulse.mesh = mesh
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = col
	pulse.material_override = mat
	pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	pulse.position = pos + Vector3(0.0, 0.08, 0.0)
	pulse.scale = Vector3(0.2, 1.0, 0.2)
	add_child(pulse)
	
	var tween: Tween = create_tween()
	if tween:
		tween.set_parallel(true)
		tween.tween_property(pulse, "scale", Vector3(radius, 1.0, radius), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.35)
		tween.finished.connect(pulse.queue_free)
	else:
		pulse.queue_free()

func _execute_moisture_brush(delta: float) -> void:
	if not _bootstrap.environmental_grid:
		return

	var affected: int = _bootstrap.environmental_grid.apply_moisture_brush(
		_current_hit_point.x,
		_current_hit_point.z,
		brush_radius,
		delta
	)

	var pulse_col: Color = Color(0.2, 0.65, 1.0, 0.9) if delta > 0.0 else Color(1.0, 0.55, 0.2, 0.9)
	_spawn_tool_pulse(_current_hit_point, pulse_col, brush_radius)

	var msg: String = ""
	if delta > 0.0:
		msg = "+Moisture (+20%%) across %d cells — Soil saturated, promoting plant growth." % affected
	else:
		msg = "-Moisture (-20%%) across %d cells — Drought stress induced on vegetation." % affected
	action_feedback.emit(msg, true)

	if _bootstrap.ecosystem_coordinator and _bootstrap.ecosystem_coordinator.causal_tracker:
		var act: String = "moisture_add" if delta > 0.0 else "moisture_sub"
		_bootstrap.ecosystem_coordinator.causal_tracker.record_intervention(act, _current_hit_point, brush_radius, {"delta": delta, "cells": affected})

	if _bootstrap.world_event_bus:
		_bootstrap.world_event_bus.publish("player_intervention", {
			"action": "moisture_brush",
			"delta": delta,
			"pos": _current_hit_point,
			"cells_affected": affected
		})

	_record_experiment_history("+Moisture" if delta > 0.0 else "-Moisture", "moisture_brush")

func _execute_heatwave() -> void:
	if not _bootstrap.environmental_grid:
		return
	var affected: int = _bootstrap.environmental_grid.apply_temperature_brush(
		_current_hit_point.x,
		_current_hit_point.z,
		brush_radius,
		8.0
	)
	_spawn_tool_pulse(_current_hit_point, Color(1.0, 0.45, 0.1, 0.9), brush_radius)
	var msg: String = "Heatwave (+8°C) across %d cells — Accelerates evaporation & heat stress." % affected
	action_feedback.emit(msg, true)

	if _bootstrap.ecosystem_coordinator and _bootstrap.ecosystem_coordinator.causal_tracker:
		_bootstrap.ecosystem_coordinator.causal_tracker.record_intervention("heatwave", _current_hit_point, brush_radius, {"delta_temp": 8.0, "cells": affected})

	if _bootstrap.world_event_bus:
		_bootstrap.world_event_bus.publish("player_intervention", {
			"action": "heatwave",
			"delta": 8.0,
			"pos": _current_hit_point,
			"cells_affected": affected
		})

	_record_experiment_history("Heatwave (+8°C)", "heatwave")

func _execute_frost() -> void:
	if not _bootstrap.environmental_grid:
		return
	var affected: int = _bootstrap.environmental_grid.apply_temperature_brush(
		_current_hit_point.x,
		_current_hit_point.z,
		brush_radius,
		-8.0
	)
	_spawn_tool_pulse(_current_hit_point, Color(0.2, 0.88, 1.0, 0.9), brush_radius)
	var msg: String = "Frost (-8°C) across %d cells — Slows metabolism & induces plant dormancy." % affected
	action_feedback.emit(msg, true)

	if _bootstrap.ecosystem_coordinator and _bootstrap.ecosystem_coordinator.causal_tracker:
		_bootstrap.ecosystem_coordinator.causal_tracker.record_intervention("frost", _current_hit_point, brush_radius, {"delta_temp": -8.0, "cells": affected})

	if _bootstrap.world_event_bus:
		_bootstrap.world_event_bus.publish("player_intervention", {
			"action": "frost",
			"delta": -8.0,
			"pos": _current_hit_point,
			"cells_affected": affected
		})

	_record_experiment_history("Frost (-8°C)", "frost")

func _execute_fertilize() -> void:
	if not _bootstrap.environmental_grid:
		return
	var affected: int = _bootstrap.environmental_grid.apply_fertilizer_brush(
		_current_hit_point.x,
		_current_hit_point.z,
		brush_radius,
		1.5
	)
	_spawn_tool_pulse(_current_hit_point, Color(0.1, 1.0, 0.4, 0.9), brush_radius)
	var msg: String = "Fertilized %d cells — Soil enriched 2.5x, boosting plant growth & seed spread." % affected
	action_feedback.emit(msg, true)

	if _bootstrap.ecosystem_coordinator and _bootstrap.ecosystem_coordinator.causal_tracker:
		_bootstrap.ecosystem_coordinator.causal_tracker.record_intervention("fertilize", _current_hit_point, brush_radius, {"delta_fertility": 1.5, "cells": affected})
		_bootstrap.ecosystem_coordinator.causal_tracker.process_fertilizer_bloom(_current_hit_point, affected)

	if _bootstrap.world_event_bus:
		_bootstrap.world_event_bus.publish("player_intervention", {
			"action": "fertilize",
			"delta": 1.5,
			"pos": _current_hit_point,
			"cells_affected": affected
		})

	_record_experiment_history("Fertilize (Soil)", "fertilize")

func _execute_disaster_shock() -> void:
	if not _bootstrap.environmental_grid:
		return
	var affected: int = _bootstrap.environmental_grid.apply_disaster_shock(
		_current_hit_point.x,
		_current_hit_point.z,
		brush_radius
	)
	_spawn_tool_pulse(_current_hit_point, Color(0.95, 0.15, 0.35, 0.95), brush_radius * 1.2)
	var msg: String = "Disaster Shock across %d cells — Extreme heat (+12°C) & desiccation (-45%% moisture)!" % affected
	action_feedback.emit(msg, true)

	if _bootstrap.ecosystem_coordinator and _bootstrap.ecosystem_coordinator.causal_tracker:
		_bootstrap.ecosystem_coordinator.causal_tracker.record_intervention("disaster_shock", _current_hit_point, brush_radius, {"cells": affected})

	if _bootstrap.world_event_bus:
		_bootstrap.world_event_bus.publish("player_intervention", {
			"action": "disaster_shock",
			"pos": _current_hit_point,
			"cells_affected": affected
		})

	_record_experiment_history("Disaster Shock", "disaster_shock")

func _execute_mutate_population() -> void:
	var coord: EcosystemCoordinator = _bootstrap.ecosystem_coordinator if _bootstrap else null
	if not coord:
		return
	var affected: int = coord.mutate_population_in_area(_current_hit_point, brush_radius)
	_spawn_tool_pulse(_current_hit_point, Color(0.85, 0.25, 1.0, 0.95), brush_radius)

	var msg: String = "Induced genetic mutation on %d entities in %.1fm radius — Alleles shifted within physiological bounds." % [affected, brush_radius]
	action_feedback.emit(msg, true)

	if coord.causal_tracker:
		coord.causal_tracker.record_intervention("mutate_population", _current_hit_point, brush_radius, {"affected": affected})

	_record_experiment_history("Mutate Population", "mutate_population")

	if _bootstrap.world_event_bus:
		_bootstrap.world_event_bus.publish("player_intervention", {
			"action": "mutate_population",
			"pos": _current_hit_point,
			"radius": brush_radius,
			"entities_affected": affected
		})

func _execute_climate_pulse() -> void:
	var coord: EcosystemCoordinator = _bootstrap.ecosystem_coordinator if _bootstrap else null
	if not coord:
		return
	var pulse: Dictionary = coord.apply_climate_pulse(_current_hit_point, brush_radius, "deluge", 25.0)
	var affected: int = int(pulse.get("cells_affected", 0))
	_spawn_tool_pulse(_current_hit_point, Color(0.15, 0.95, 0.90, 0.95), brush_radius)

	var msg: String = "Triggered Climate Pulse (Deluge, 25s) across %d cells — Continuous rainfall & cooling." % affected
	action_feedback.emit(msg, true)

	if coord.causal_tracker:
		coord.causal_tracker.record_intervention("climate_pulse", _current_hit_point, brush_radius, {"cells": affected, "duration": 25.0, "type": "deluge"})

	_record_experiment_history("Climate Pulse (Deluge)", "climate_pulse")

	if _bootstrap.world_event_bus:
		_bootstrap.world_event_bus.publish("player_intervention", {
			"action": "climate_pulse",
			"pos": _current_hit_point,
			"radius": brush_radius,
			"cells_affected": affected
		})

func _record_experiment_history(action_name: String, action_type: String) -> void:
	if not _bootstrap or not _bootstrap.ecosystem_coordinator:
		return
	var coord: EcosystemCoordinator = _bootstrap.ecosystem_coordinator
	if coord.experiment_history and coord.metrics and coord.flora_sim and coord.fauna_sim:
		var sim_t: float = _bootstrap.world_clock.simulation_time if _bootstrap.world_clock else 0.0
		var metrics_snap: Dictionary = {
			"plant_count": coord.flora_sim.get_plant_count(),
			"total_biomass": coord.metrics.total_biomass,
			"herbivore_count": coord.fauna_sim.get_herbivore_count(),
			"predator_count": coord.fauna_sim.get_predator_count(),
			"avg_speed": coord.metrics.avg_herbivore_speed,
			"avg_size": coord.metrics.avg_herbivore_size,
			"avg_efficiency": coord.metrics.avg_herbivore_energy_efficiency,
			"speed_variance": coord.metrics.allele_speed_variance,
			"diversity_index": coord.metrics.genetic_diversity_index
		}
		coord.experiment_history.record_experiment(
			action_name,
			action_type,
			_current_hit_point,
			brush_radius,
			metrics_snap,
			sim_t,
			20.0
		)

func _execute_spawn_plant() -> void:
	# Validation: Above sea level and on island
	if _current_hit_point.y < 0.35:
		action_feedback.emit("Cannot plant below sea level!", false)
		return
	if Vector2(_current_hit_point.x, _current_hit_point.z).length() > 68.0:
		action_feedback.emit("Cannot plant outside island boundaries!", false)
		return

	var coord: EcosystemCoordinator = _bootstrap.ecosystem_coordinator
	if not coord or not coord.flora_sim:
		return

	var species: String = "shrub_bush" if (randf() < 0.4) else "grass_patch"
	var initial_bio: float = 4.0 if species == "shrub_bush" else 3.0
	var pid: int = coord.flora_sim.spawn_plant(species, _current_hit_point, initial_bio)

	_spawn_tool_pulse(_current_hit_point, Color(0.3, 0.95, 0.4, 0.9), 2.2)
	action_feedback.emit("Planted %s #%d — Absorbs moisture and feeds herbivores" % [species, pid], true)

func _execute_spawn_herbivore() -> void:
	if _current_hit_point.y < 0.35:
		action_feedback.emit("Cannot spawn herbivore in water!", false)
		return
	if Vector2(_current_hit_point.x, _current_hit_point.z).length() > 68.0:
		action_feedback.emit("Cannot spawn off-island!", false)
		return

	var coord: EcosystemCoordinator = _bootstrap.ecosystem_coordinator
	if not coord or not coord.fauna_sim:
		return

	var hid: int = coord.fauna_sim.spawn_herbivore(_current_hit_point, 85.0)
	_spawn_tool_pulse(_current_hit_point, Color(1.0, 0.85, 0.35, 0.9), 2.5)
	action_feedback.emit("Spawned Island Deer #%d — Grazes on shrubs and flees predators" % hid, true)

func _execute_spawn_predator() -> void:
	if _current_hit_point.y < 0.35:
		action_feedback.emit("Cannot spawn predator in water!", false)
		return
	if Vector2(_current_hit_point.x, _current_hit_point.z).length() > 68.0:
		action_feedback.emit("Cannot spawn off-island!", false)
		return

	var coord: EcosystemCoordinator = _bootstrap.ecosystem_coordinator
	if not coord or not coord.fauna_sim:
		return

	var prid: int = coord.fauna_sim.spawn_predator(_current_hit_point, 85.0)
	_spawn_tool_pulse(_current_hit_point, Color(1.0, 0.25, 0.35, 0.9), 2.8)
	action_feedback.emit("Spawned Mountain Stalker #%d — Carnivore hunting deer" % prid, true)

func _execute_delete_entity() -> void:
	var closest: Dictionary = _find_closest_entity(_current_hit_point, 3.5)
	if closest.is_empty():
		action_feedback.emit("No entity found within 3.5m to delete", false)
		return

	var id: int = closest.get("id", 0)
	var type: String = closest.get("type", "")
	var coord: EcosystemCoordinator = _bootstrap.ecosystem_coordinator
	if not coord:
		return

	_spawn_tool_pulse(_current_hit_point, Color(1.0, 0.15, 0.15, 0.9), 2.0)
	_highlight_inspected_entity(-1)

	match type:
		"herbivore":
			coord.fauna_sim.remove_herbivore(id, "player_deleted")
			action_feedback.emit("Deleted Herbivore #%d" % id, true)
		"predator":
			coord.fauna_sim.remove_predator(id, "player_deleted")
			action_feedback.emit("Deleted Predator #%d" % id, true)
		"plant":
			coord.flora_sim.remove_plant(id, "player_deleted")
			action_feedback.emit("Deleted Plant #%d" % id, true)
		_:
			if _bootstrap.entity_registry:
				_bootstrap.entity_registry.despawn_entity(id, "player_deleted")
			action_feedback.emit("Deleted Entity #%d" % id, true)

func _find_closest_entity(pos: Vector3, max_dist: float) -> Dictionary:
	var best_dist_sq: float = max_dist * max_dist
	var best_data: Dictionary = {}
	var coord: EcosystemCoordinator = _bootstrap.ecosystem_coordinator
	if not coord:
		return {}

	# Check Herbivores
	if coord.fauna_sim:
		for h in coord.fauna_sim.get_all_herbivores():
			var d_sq: float = pos.distance_squared_to(h.position)
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_data = {
					"id": h.id,
					"type": "herbivore",
					"species": h.species,
					"position": h.position,
					"health": h.health,
					"energy": h.energy,
					"age": h.age,
					"state_name": _get_herbivore_state_name(h.state),
					"life_stage_name": _get_life_stage_name(h.life_stage),
					"genome": h.genome.serialize() if h.genome else {}
				}

		# Check Predators
		for p in coord.fauna_sim.get_all_predators():
			var d_sq: float = pos.distance_squared_to(p.position)
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_data = {
					"id": p.id,
					"type": "predator",
					"species": p.species,
					"position": p.position,
					"health": p.health,
					"energy": p.energy,
					"age": p.age,
					"state_name": _get_predator_state_name(p.state),
					"life_stage_name": _get_life_stage_name(p.life_stage),
					"genome": p.genome.serialize() if p.genome else {}
				}

	# Check Plants
	if coord.flora_sim:
		for pl in coord.flora_sim.get_all_plants():
			var d_sq: float = pos.distance_squared_to(pl.position)
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_data = {
					"id": pl.id,
					"type": "plant",
					"species": pl.species,
					"position": pl.position,
					"health": pl.health,
					"biomass": pl.biomass,
					"max_biomass": pl.max_biomass,
					"age": pl.age,
					"stage_name": _get_growth_stage_name(pl.stage),
					"genome": pl.genome.serialize() if pl.genome else {}
				}

	return best_data

func _get_herbivore_state_name(state: int) -> String:
	match state:
		0: return "WANDERING"
		1: return "FORAGING"
		2: return "EATING"
		3: return "RESTING"
		4: return "FLEEING"
		5: return "STARVING"
		_: return "UNKNOWN"

func _get_predator_state_name(state: int) -> String:
	match state:
		0: return "WANDERING"
		1: return "HUNTING"
		2: return "EATING"
		3: return "RESTING"
		4: return "STARVING"
		_: return "UNKNOWN"

func _get_growth_stage_name(stage: int) -> String:
	match stage:
		0: return "SEED"
		1: return "SPROUT"
		2: return "GROWING"
		3: return "MATURE"
		4: return "DECAYING"
		5: return "DEAD"
		_: return "UNKNOWN"

func _get_life_stage_name(stage: int) -> String:
	match stage:
		0: return "JUVENILE"
		1: return "ADULT"
		2: return "ELDER"
		_: return "UNKNOWN"
