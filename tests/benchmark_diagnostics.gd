class_name BenchmarkDiagnostics
extends SceneTree

## Diagnostic isolation profiler for Intel Iris Xe performance levers.
## Measures baseline and tests each optimization lever independently:
## 1. Baseline (Raw Main Scene, 100% scale, SSAO on, 4 shadow splits)
## 2. Lever A: SSAO off
## 3. Lever B: 2 Shadow Splits + No Blend Splits (Shadow Optimization)
## 4. Lever C: 85% 3D Scale (FSR / Bilinear scaling)
## 5. Lever D: Grass MultiMesh budget (900 vs 1500 instances)
## 6. Combined Balanced Preset

var _frame_count: int = 0
var _current_phase: int = 0
var _phase_samples: Array[float] = []
var _phase_draw_calls: Array[float] = []
var _phase_primitives: Array[float] = []
var _results: Dictionary = {}

var _main_scene: Node = null
var _camera: Camera3D = null
var _sun: DirectionalLight3D = null
var _env: Environment = null
var _scatter: VegetationScatter = null
var _viewport: Viewport = null

const PHASE_WARMUP: int = 20
const PHASE_FRAMES: int = 80

const PHASES := [
	"1_Baseline_Raw",
	"2_SSAO_Off",
	"3_Shadow_2Splits",
	"4_Scale_85pct",
	"5_Grass_900_Tufts",
	"6_Combined_Balanced"
]

func _init() -> void:
	print("=======================================================")
	print(" LIVING PLANET SANDBOX — BOTTLENECK FORENSIC PROFILER  ")
	print("=======================================================")

	var packed: PackedScene = load("res://scenes/main.tscn")
	if not packed:
		quit(1)
		return

	_main_scene = packed.instantiate()
	root.add_child(_main_scene)

	_viewport = root.get_viewport()
	_camera = _main_scene.get_node_or_null("FreeLookCamera") as Camera3D
	_sun = _main_scene.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	var env_node = _main_scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node:
		_env = env_node.environment
	_scatter = _main_scene.get_node_or_null("VegetationScatter") as VegetationScatter

	# Fixed representative camera view: Whispering Forest to Sunlit Meadow Glade overview
	if _camera:
		_camera.position = Vector3(18.0, 11.5, 26.0)
		_camera.look_at_target(Vector3(-6.0, 5.0, -6.0))

	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_setup_phase(0)
	process_frame.connect(_on_process_frame)

func _setup_phase(idx: int) -> void:
	_frame_count = 0
	_phase_samples.clear()
	_phase_draw_calls.clear()
	_phase_primitives.clear()
	var pname = PHASES[idx]
	print("\n>>> PROFILING LEVER: %s" % pname)

	# Reset to baseline first
	if _viewport: _viewport.scaling_3d_scale = 1.0
	if _env: _env.ssao_enabled = true
	if _sun:
		_sun.shadow_enabled = true
		_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		_sun.directional_shadow_blend_splits = true
		_sun.directional_shadow_max_distance = 80.0
	if _scatter and _scatter._grass_multimesh and _scatter._grass_multimesh.multimesh:
		var ic: int = _scatter._grass_multimesh.multimesh.instance_count
		_scatter._grass_multimesh.multimesh.visible_instance_count = ic

	match idx:
		0: # Baseline Raw
			pass
		1: # SSAO Off only
			if _env: _env.ssao_enabled = false
		2: # Shadow 2 splits only
			if _sun:
				_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
				_sun.directional_shadow_blend_splits = false
				_sun.directional_shadow_max_distance = 60.0
		3: # 85% scale only
			if _viewport: _viewport.scaling_3d_scale = 0.85
		4: # Grass 900 instances only
			if _scatter and _scatter._grass_multimesh and _scatter._grass_multimesh.multimesh:
				var ic: int = _scatter._grass_multimesh.multimesh.instance_count
				_scatter._grass_multimesh.multimesh.visible_instance_count = mini(900, ic)
		5: # Combined Balanced
			if _env: _env.ssao_enabled = false
			if _sun:
				_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
				_sun.directional_shadow_blend_splits = false
				_sun.directional_shadow_max_distance = 60.0
			if _viewport: _viewport.scaling_3d_scale = 0.88
			if _scatter and _scatter._grass_multimesh and _scatter._grass_multimesh.multimesh:
				var ic: int = _scatter._grass_multimesh.multimesh.instance_count
				_scatter._grass_multimesh.multimesh.visible_instance_count = mini(900, ic)

func _on_process_frame() -> void:
	_frame_count += 1
	if _frame_count <= PHASE_WARMUP:
		return

	_phase_samples.append(Performance.get_monitor(Performance.TIME_FPS))
	_phase_draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_phase_primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))

	if _frame_count >= (PHASE_WARMUP + PHASE_FRAMES):
		_record_phase_results(_current_phase)
		_current_phase += 1
		if _current_phase < PHASES.size():
			_setup_phase(_current_phase)
		else:
			_print_final_comparison()

func _record_phase_results(idx: int) -> void:
	var count = _phase_samples.size()
	if count == 0: return
	var avg_fps = 0.0
	for f in _phase_samples: avg_fps += f
	avg_fps /= float(count)

	var max_dc = 0.0
	for dc in _phase_draw_calls:
		if dc > max_dc: max_dc = dc

	var max_prim = 0.0
	for p in _phase_primitives:
		if p > max_prim: max_prim = p

	var ms = (1000.0 / avg_fps) if avg_fps > 0.0 else 0.0
	_results[PHASES[idx]] = {
		"avg_fps": avg_fps,
		"avg_ms": ms,
		"max_dc": max_dc,
		"max_prim": max_prim
	}
	print("    -> Avg FPS: %.1f | Frame Time: %.2f ms | Draw Calls: %.0f | Prims: %.0f" % [
		avg_fps, ms, max_dc, max_prim
	])

func _print_final_comparison() -> void:
	print("\n=======================================================")
	print("   PROFILING RESULTS SUMMARY (INTEL IRIS XE)")
	print("=======================================================")
	print(String("%-22s | %-9s | %-10s | %-10s | %-10s" % ["Configuration", "Avg FPS", "Frame Time", "Draw Calls", "Primitives"]))
	print("----------------------------------------------------------------------------------")

	var baseline_ms = _results.get(PHASES[0], {}).get("avg_ms", 33.3)

	for pname in PHASES:
		var d = _results.get(pname, {})
		var fps = d.get("avg_fps", 0.0)
		var ms = d.get("avg_ms", 0.0)
		var dc = d.get("max_dc", 0.0)
		var prim = d.get("max_prim", 0.0)
		var delta_pct = ((baseline_ms - ms) / baseline_ms) * 100.0 if baseline_ms > 0.0 else 0.0
		print(String("%-22s | %6.1f FPS | %6.2f ms (%+4.1f%%) | %6.0f     | %8.0f" % [
			pname, fps, ms, delta_pct, dc, prim
		]))
	print("=======================================================\n")
	quit(0)
