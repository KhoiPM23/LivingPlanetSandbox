class_name EntityRegistry
extends RefCounted

## Tracks living simulation entities purely by data components without mandatory scene nodes.

var _entities: Dictionary = {} # int -> Dictionary
var _next_id: int = 1
var _type_indices: Dictionary = {} # String -> Array[int]
var _event_bus: WorldEventBus = null

func _init(event_bus: WorldEventBus = null) -> void:
	_event_bus = event_bus

func set_event_bus(event_bus: WorldEventBus) -> void:
	_event_bus = event_bus

func spawn_entity(entity_type: String, position: Vector3, properties: Dictionary = {}, forced_id: int = -1) -> int:
	var id: int = _next_id
	if forced_id > 0:
		id = forced_id
		_next_id = maxi(_next_id, id + 1)
	else:
		_next_id += 1
	
	var data: Dictionary = {
		"id": id,
		"type": entity_type,
		"position": position,
		"alive": true,
		"health": properties.get("health", 100.0),
		"energy": properties.get("energy", 100.0),
		"age": properties.get("age", 0.0),
		"properties": properties.duplicate()
	}
	
	_entities[id] = data
	
	if not _type_indices.has(entity_type):
		_type_indices[entity_type] = []
	_type_indices[entity_type].append(id)
	
	if _event_bus:
		_event_bus.entity_spawned.emit(id, entity_type, position)
		_event_bus.publish("entity_spawned", {"id": id, "type": entity_type, "position": position})
		
	return id

func despawn_entity(id: int, reason: String = "removed") -> bool:
	if not _entities.has(id):
		return false
		
	var data: Dictionary = _entities[id]
	var entity_type: String = data["type"]
	
	if _type_indices.has(entity_type):
		_type_indices[entity_type].erase(id)
		
	_entities.erase(id)
	
	if _event_bus:
		_event_bus.entity_despawned.emit(id, reason)
		_event_bus.publish("entity_despawned", {"id": id, "reason": reason})
		
	return true

func get_entity(id: int) -> Dictionary:
	return _entities.get(id, {})

func has_entity(id: int) -> bool:
	return _entities.has(id)

func update_property(id: int, key: String, new_val: Variant) -> void:
	if not _entities.has(id):
		return
	var old_val: Variant = _entities[id].get(key, null)
	_entities[id][key] = new_val
	
	if _event_bus:
		_event_bus.entity_state_changed.emit(id, key, old_val, new_val)

func get_all_ids() -> Array:
	return _entities.keys()

func get_entities_by_type(entity_type: String) -> Array:
	return _type_indices.get(entity_type, []).duplicate()

func get_count() -> int:
	return _entities.size()

func get_count_by_type(entity_type: String) -> int:
	if _type_indices.has(entity_type):
		return _type_indices[entity_type].size()
	return 0

func clear() -> void:
	_entities.clear()
	_type_indices.clear()
	_next_id = 1
