class_name BenchmarkWorld
extends SceneTree

## Headless and Windowed Benchmark for Block 2 First Playable World.
## Measures FPS, frame times, draw calls, primitive count, and captures runtime screenshot.

var _frame_count: int = 0
var _max_frames: int = 180
var _fps_samples: Array[float] = []
var _process_times: Array[float] = []
var _draw_calls: Array[float] = []
var _primitives: Array[float] = []

var _main_scene: Node = null

func _init() -> void:
	print("=======================================================")
	print("   LIVING PLANET SANDBOX — RUNTIME PERFORMANCE BENCHMARK")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var packed: PackedScene = load("res://scenes/main.tscn")
	if not packed:
		printerr("[Benchmark] Failed to load res://scenes/main.tscn")
		quit(1)
		return
		
	_main_scene = packed.instantiate()
	root.add_child(_main_scene)
	
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	_frame_count += 1
	
	# Skip first 15 frames for pipeline warmup & shader compilation
	if _frame_count > 15:
		_fps_samples.append(Performance.get_monitor(Performance.TIME_FPS))
		_process_times.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0) # ms
		_draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		_primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		
	if _frame_count >= _max_frames:
		_finish_benchmark()

func _attempt_screenshot() -> void:
	var vp: Viewport = root.get_viewport()
	if vp:
		var tex: ViewportTexture = vp.get_texture()
		if tex:
			var img: Image = tex.get_image()
			if img and not img.is_empty():
				var target_path: String = "res://screenshot_block_6.png"
				var global_path: String = ProjectSettings.globalize_path(target_path)
				var err: Error = img.save_png(global_path)
				img.save_png(ProjectSettings.globalize_path("res://screenshot_block_5.png"))
				img.save_png(ProjectSettings.globalize_path("res://screenshot_first_playable.png"))
				if err == OK:
					print("[Benchmark] Runtime screenshot captured to: %s (Size: %dx%d)" % [global_path, img.get_width(), img.get_height()])
				else:
					print("[Benchmark] Viewport image capture returned error code: %d" % err)
			else:
				print("[Benchmark] Viewport image empty (Dummy headless renderer active).")
		else:
			print("[Benchmark] No viewport texture available.")

func _finish_benchmark() -> void:
	var count: int = _fps_samples.size()
	if count == 0:
		print("[Benchmark] No samples collected.")
		quit(0)
		return
		
	var avg_fps: float = 0.0
	var min_fps: float = 99999.0
	var max_fps: float = 0.0
	for f in _fps_samples:
		avg_fps += f
		if f < min_fps: min_fps = f
		if f > max_fps: max_fps = f
	avg_fps /= float(count)
	
	var avg_ms: float = 0.0
	for t in _process_times:
		avg_ms += t
	avg_ms /= float(count)
	
	var max_dc: float = 0.0
	for dc in _draw_calls:
		if dc > max_dc: max_dc = dc
		
	var max_prim: float = 0.0
	for p in _primitives:
		if p > max_prim: max_prim = p
		
	var mem_static: float = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var renderer_name: String = ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus")
	
	var bs = _main_scene.get_node_or_null("WorldBootstrap") if _main_scene else null
	var tracked_ent: int = bs.entity_registry.get_count() if (bs and "entity_registry" in bs and bs.entity_registry) else 0
	var eco_summary: String = "N/A"
	if bs and "ecosystem_coordinator" in bs and bs.ecosystem_coordinator and bs.ecosystem_coordinator.metrics:
		var m = bs.ecosystem_coordinator.metrics
		eco_summary = "Plants: %d (%.1f kg) | Herbivores: %d | Predators: %d | Births: %d | Deaths: %d" % [
			m.plant_count, m.total_biomass, m.herbivore_count, m.predator_count, m.births_total, m.deaths_total
		]
	
	var summary_text: String = ""
	summary_text += "\n--- BENCHMARK RESULTS ---\n"
	summary_text += "Renderer:            %s\n" % renderer_name
	summary_text += "Sampled Frames:      %d\n" % count
	summary_text += "Avg FPS:             %.1f\n" % avg_fps
	summary_text += "Min / Max FPS:       %.1f / %.1f\n" % [min_fps, max_fps]
	summary_text += "Avg Frame Time:      %.2f ms\n" % avg_ms
	summary_text += "Max Draw Calls:      %.0f\n" % max_dc
	summary_text += "Max Primitives:      %.0f\n" % max_prim
	summary_text += "Static Memory:       %.2f MB\n" % mem_static
	summary_text += "Entities Tracked:    %d\n" % tracked_ent
	summary_text += "Ecosystem State:     %s\n" % eco_summary
	summary_text += "-------------------------\n"
	print(summary_text)

	var save_path: String = ProjectSettings.globalize_path("res://reports/benchmark_summary.txt")
	var f = FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(summary_text)
		f.close()
	_attempt_screenshot()
	quit(0)
