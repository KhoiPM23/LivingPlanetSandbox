extends RefCounted

func test_event_bus_pub_sub() -> Variant:
	var bus: WorldEventBus = WorldEventBus.new()
	var received: Array = []
	
	var handler: Callable = func(data: Dictionary) -> void:
		received.append(data.get("val", 0))
		
	bus.subscribe("test_event", handler)
	bus.publish("test_event", {"val": 42})
	
	if received.size() != 1 or received[0] != 42:
		return "Failed to receive published event"
		
	bus.unsubscribe("test_event", handler)
	bus.publish("test_event", {"val": 99})
	
	if received.size() != 1:
		return "Received event after unsubscribe"
		
	return null

func test_event_bus_signals() -> Variant:
	var bus: WorldEventBus = WorldEventBus.new()
	var state: Dictionary = {"spawned_id": -1}
	
	bus.entity_spawned.connect(func(id: int, type: String, pos: Vector3) -> void:
		state["spawned_id"] = id
	)
	
	bus.entity_spawned.emit(105, "rabbit", Vector3.ZERO)
	if state["spawned_id"] != 105:
		return "Signal emission failed to deliver id: %d" % state["spawned_id"]
		
	return null
