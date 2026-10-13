class_name BenchmarkSuite
extends SceneTree

## Comprehensive, reproducible benchmark harness for Living Planet Sandbox.
## Evaluates Light, Target, and Stress workloads on Windows 11 / Intel Iris Xe graphics.
## Measures Avg FPS, p95/p99 frame times, sim tick times, draw calls, and memory footprint.

const FIXED_BENCHMARK_SEED: int = 1337

enum LoadTier {
	LIGHT = 0,
	TARGET = 1,
	STRESS = 2
}

var _current_tier: LoadTier = LoadTier.TARGET
var _tier_names: Dictionary = {
	LoadTier.LIGHT: "Light Workload (Minimal Entities)",
	LoadTier.TARGET: "Target Workload (Standard Sandbox Gameplay)",
	LoadTier.STRESS: "Stress Workload (Heavy Population Density)"
}

var _tier_configs: Dictionary = {
	LoadTier.LIGHT: {"plants": 25, "herbivores": 6, "predators": 1},
	LoadTier.TARGET: {"plants": 55, "herbivores": 14, "predators": 2},
	LoadTier.STRESS: {"plants": 140, "herbivores": 38, "predators": 6}
}

var _main_scene: Node = null
var _frame_count: int = 0
const WARMUP_FRAMES: int = 25
const MEASURE_FRAMES: int = 160

# Telemetry sample buffers
var _frame_times: Array[float] = []
var _fps_samples: Array[float] = []
var _draw_calls: Array[float] = []
var _primitives: Array[float] = []
var _sim_step_times: Array[float] = []

var _gen_duration_ms: float = 0.0
var _camera: Camera3D = null
var _cam_angle: float = 0.0

func _init() -> void:
	print("\n=======================================================")
	print("   LIVING PLANET SANDBOX — REPRODUCIBLE BENCHMARK SUITE")
	print("=======================================================")

	# Parse command line argument if specified
	var all_args: Array = []
	all_args.append_array(OS.get_cmdline_args())
	all_args.append_array(OS.get_cmdline_user_args())
	for arg in all_args:
		if arg == "--light": _current_tier = LoadTier.LIGHT
		elif arg == "--target": _current_tier = LoadTier.TARGET
		elif arg == "--stress": _current_tier = LoadTier.STRESS

	_launch_tier(_current_tier)


func _launch_tier(tier: LoadTier) -> void:
	var cfg: Dictionary = _tier_configs[tier]
	print("\n>>> INITIALIZING BENCHMARK TIER: %s" % _tier_names[tier])
	print("    Configuration: %d Plants | %d Herbivores | %d Predators" % [cfg["plants"], cfg["herbivores"], cfg["predators"]])
	print("    Seed: %d | Resolution: 1280x720 | Renderer: %s" % [
		FIXED_BENCHMARK_SEED,
		ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus")
	])

	var gen_start_usec: int = Time.get_ticks_usec()
	var packed: PackedScene = load("res://scenes/main.tscn")
	if not packed:
		printerr("[BenchmarkSuite] Failed to load res://scenes/main.tscn")
		quit(1)
		return

	_main_scene = packed.instantiate()
	root.add_child(_main_scene)

	var bs: WorldBootstrap = _main_scene.get_node_or_null("WorldBootstrap") as WorldBootstrap
	if bs and bs.ecosystem_coordinator:
		bs.ecosystem_coordinator.populate_initial_ecosystem(cfg["plants"], cfg["herbivores"], cfg["predators"])


	_gen_duration_ms = float(Time.get_ticks_usec() - gen_start_usec) / 1000.0
	print("    World Generation & Population Time: %.2f ms" % _gen_duration_ms)

	_camera = _main_scene.get_node_or_null("FreeLookCamera") as Camera3D

	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	_frame_count += 1

	# Repeatable camera trajectory: Smooth scenic orbit around the island center
	if _camera:
		_cam_angle += 0.018 # ~1 degree per frame
		var orbit_dist: float = 38.0
		var cam_h: float = 17.5 + sin(_cam_angle * 0.5) * 3.5
		var cam_x: float = cos(_cam_angle) * orbit_dist
		var cam_z: float = sin(_cam_angle) * orbit_dist
		_camera.position = Vector3(cam_x, cam_h, cam_z)
		_camera.look_at_target(Vector3(0.0, 4.0, 0.0))

	# Collect sim step duration from metrics
	var bs: WorldBootstrap = _main_scene.get_node_or_null("WorldBootstrap") as WorldBootstrap
	if bs and bs.ecosystem_coordinator and bs.ecosystem_coordinator.metrics:
		var sim_dur: float = bs.ecosystem_coordinator.metrics.last_sim_step_duration_ms
		if sim_dur > 0.0:
			_sim_step_times.append(sim_dur)

	# Warm-up phase bypass
	if _frame_count <= WARMUP_FRAMES:
		return

	# Measurement phase
	var dt_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var dc: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var prim: float = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)

	_frame_times.append(dt_ms)
	_fps_samples.append(fps)
	_draw_calls.append(dc)
	_primitives.append(prim)

	if _frame_count >= (WARMUP_FRAMES + MEASURE_FRAMES):
		_conclude_tier_benchmark()

func _conclude_tier_benchmark() -> void:
	var count: int = _frame_times.size()
	if count == 0:
		quit(0)
		return

	# Sort frame times for percentiles
	var sorted_times: Array[float] = _frame_times.duplicate()
	sorted_times.sort()

	var p95_idx: int = clampi(int(float(count) * 0.95), 0, count - 1)
	var p99_idx: int = clampi(int(float(count) * 0.99), 0, count - 1)
	var p95_time: float = sorted_times[p95_idx]
	var p99_time: float = sorted_times[p99_idx]

	var avg_time: float = 0.0
	for t in _frame_times: avg_time += t
	avg_time /= float(count)

	var avg_fps: float = 0.0
	var min_fps: float = 99999.0
	var max_fps: float = 0.0
	for f in _fps_samples:
		avg_fps += f
		if f < min_fps: min_fps = f
		if f > max_fps: max_fps = f
	avg_fps /= float(count)

	var max_dc: float = 0.0
	for dc in _draw_calls:
		if dc > max_dc: max_dc = dc

	var max_prim: float = 0.0
	for pr in _primitives:
		if pr > max_prim: max_prim = pr

	var avg_sim_step: float = 0.0
	if _sim_step_times.size() > 0:
		for s in _sim_step_times: avg_sim_step += s
		avg_sim_step /= float(_sim_step_times.size())

	var mem_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)

	var bs: WorldBootstrap = _main_scene.get_node_or_null("WorldBootstrap") as WorldBootstrap
	var reg_count: int = bs.entity_registry.get_count() if (bs and bs.entity_registry) else 0

	print("\n-------------------------------------------------------")
	print("   BENCHMARK RESULTS: %s" % _tier_names[_current_tier].to_upper())
	print("-------------------------------------------------------")
	print("  Sampled Frames:       %d (Warmup: %d frames)" % [count, WARMUP_FRAMES])
	print("  Average FPS:          %.1f FPS" % avg_fps)
	print("  Min / Max FPS:        %.1f / %.1f FPS" % [min_fps, max_fps])
	print("  Average Frame Time:   %.2f ms" % avg_time)
	print("  p95 Frame Time:       %.2f ms" % p95_time)
	print("  p99 Frame Time:       %.2f ms" % p99_time)
	print("  Avg Sim Step Time:    %.2f ms" % avg_sim_step)
	print("  World Gen/Load Time:  %.2f ms" % _gen_duration_ms)
	print("  Max Draw Calls:       %.0f" % max_dc)
	print("  Max Primitives:       %.0f" % max_prim)
	print("  Static Memory:        %.2f MB" % mem_mb)
	print("  Tracked Entities:     %d" % reg_count)
	print("-------------------------------------------------------\n")

	quit(0)
