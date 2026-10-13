class_name PerformanceMonitor
extends RefCounted

## Tracks real hardware and engine metrics on target machine (Intel Iris Xe).

static func get_snapshot(clock: WorldClock = null, registry: EntityRegistry = null) -> Dictionary:
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var process_time_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_time_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var static_mem_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var primitives: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var object_count: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var node_count: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	
	var snapshot: Dictionary = {
		"fps": fps,
		"frame_time_ms": process_time_ms,
		"physics_time_ms": physics_time_ms,
		"memory_mb": static_mem_mb,
		"draw_calls": draw_calls,
		"primitives": primitives,
		"objects": object_count,
		"nodes": node_count,
		"sim_ticks": clock.tick_count if clock else 0,
		"sim_time": clock.simulation_time if clock else 0.0,
		"sim_scale": clock.time_scale if clock else 1.0,
		"sim_paused": clock.is_paused if clock else false,
		"sim_entities": registry.get_count() if registry else 0
	}
	
	return snapshot

static func format_summary(clock: WorldClock = null, registry: EntityRegistry = null) -> String:
	var s: Dictionary = get_snapshot(clock, registry)
	return (
		"FPS: %d (%.2f ms) | DrawCalls: %d | Prims: %d\n" % [s["fps"], s["frame_time_ms"], s["draw_calls"], s["primitives"]] +
		"Mem: %.1f MB | Nodes: %d | Objects: %d\n" % [s["memory_mb"], s["nodes"], s["objects"]] +
		"Sim Time: %.1fs (Tick #%d) | Scale: %.1fx%s | Entities: %d" % [
			s["sim_time"], s["sim_ticks"], s["sim_scale"],
			" [PAUSED]" if s["sim_paused"] else "",
			s["sim_entities"]
		]
	)
