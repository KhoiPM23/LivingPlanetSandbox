class_name WorldEventBus
extends RefCounted

## Typed event broker decoupling simulation, environmental events, presentation, and UI.

signal entity_spawned(entity_id: int, entity_type: String, position: Vector3)
signal entity_despawned(entity_id: int, reason: String)
signal entity_state_changed(entity_id: int, key: String, old_val: Variant, new_val: Variant)
signal environment_parameter_changed(param_name: String, value: Variant)
signal player_intervention(action_name: String, position: Vector3, parameters: Dictionary)
signal notification_logged(category: String, message: String)

var _subscribers: Dictionary = {} # String -> Array[Callable]

func subscribe(event_name: String, callback: Callable) -> void:
	if not _subscribers.has(event_name):
		_subscribers[event_name] = []
	if not _subscribers[event_name].has(callback):
		_subscribers[event_name].append(callback)

func unsubscribe(event_name: String, callback: Callable) -> void:
	if _subscribers.has(event_name):
		_subscribers[event_name].erase(callback)

func publish(event_name: String, payload: Dictionary = {}) -> void:
	if _subscribers.has(event_name):
		# Copy list to allow safe unsubscribe during callbacks
		var list: Array = _subscribers[event_name].duplicate()
		for cb: Callable in list:
			if cb.is_valid():
				cb.call(payload)
			else:
				_subscribers[event_name].erase(cb)

func clear_all() -> void:
	_subscribers.clear()
