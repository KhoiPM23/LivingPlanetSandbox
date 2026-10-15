class_name GraphicsPresets
extends RefCounted

## Manages scalable rendering quality presets tailored for Intel Iris Xe integrated GPUs,
## battery saving profiles, and dedicated desktop hardware.

enum Preset {
	LOW = 0,       # Performance / Battery Saver
	BALANCED = 1,  # Intel Iris Xe Optimized (Default)
	CINEMATIC = 2, # High Fidelity / Desktop GPU
	HIGH = 3       # Compatibility alias for CINEMATIC
}

const CONFIG_PATH: String = "user://settings_graphics.cfg"

static var current_preset: Preset = Preset.BALANCED

static func get_preset_name(preset: Preset) -> String:
	match preset:
		Preset.LOW: return "Low"
		Preset.BALANCED: return "Balanced (Intel Iris Xe)"
		Preset.CINEMATIC, Preset.HIGH: return "Cinematic"
		_: return "Balanced (Intel Iris Xe)"

static func get_preset_description(preset: Preset) -> String:
	match preset:
		Preset.LOW: return "3D Scale 75%, MSAA Off, Shadows Off, Fog Off, 450 Grass, 160 Rain"
		Preset.BALANCED: return "3D Scale 85%, MSAA Off, 2-Split Shadows (65m), Depth Fog, 900 Grass, 350 Rain"
		Preset.CINEMATIC, Preset.HIGH: return "Native 100%, MSAA 2X, High Shadows (110m), SSAO & Volumetric Fog, 1400 Grass, 550 Rain"
		_: return ""

## Applies rendering parameters across WorldEnvironment, DirectionalLight3D, and Viewport
static func apply_preset(preset: Preset, scene_root: Node) -> Dictionary:
	current_preset = preset
	var changes: Dictionary = {
		"preset": preset,
		"preset_name": get_preset_name(preset),
		"scaling_3d_scale": 1.0,
		"msaa_3d": Viewport.MSAA_DISABLED,
		"shadow_enabled": true,
		"glow_enabled": true,
		"fog_enabled": true,
		"fog_density": 0.004,
		"grass_count": 900,
		"rain_amount": 350,
		"snow_amount": 120
	}

	if not scene_root:
		return changes

	# 1. 3D Resolution Scaling & MSAA (Viewport)
	var target_scale: float = 1.0
	var target_msaa: Viewport.MSAA = Viewport.MSAA_DISABLED
	match preset:
		Preset.LOW:
			target_scale = 0.75
			target_msaa = Viewport.MSAA_DISABLED
		Preset.BALANCED:
			target_scale = 0.85
			target_msaa = Viewport.MSAA_DISABLED
		Preset.CINEMATIC, Preset.HIGH:
			target_scale = 1.0
			target_msaa = Viewport.MSAA_2X

	changes["scaling_3d_scale"] = target_scale
	changes["msaa_3d"] = target_msaa

	var viewport: Viewport = scene_root.get_viewport() if scene_root else null
	if viewport:
		viewport.scaling_3d_scale = target_scale
		viewport.msaa_3d = target_msaa
		if target_scale < 1.0:
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
			viewport.fsr_sharpness = 0.2
		else:
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR

	# 2. Lighting & Shadows (DirectionalLight3D)
	var sun: DirectionalLight3D = scene_root.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	if sun:
		match preset:
			Preset.LOW:
				sun.shadow_enabled = false
				changes["shadow_enabled"] = false
			Preset.BALANCED:
				sun.shadow_enabled = true
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
				sun.directional_shadow_blend_splits = true
				sun.directional_shadow_fade_start = 0.85
				sun.directional_shadow_max_distance = 100.0
				changes["shadow_enabled"] = true
			Preset.CINEMATIC, Preset.HIGH:
				sun.shadow_enabled = true
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
				sun.directional_shadow_blend_splits = true
				sun.directional_shadow_max_distance = 110.0
				changes["shadow_enabled"] = true

	# 3. Post-Processing & Fog (WorldEnvironment)
	var env_node: WorldEnvironment = scene_root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if env_node and env_node.environment:
		var env: Environment = env_node.environment
		match preset:
			Preset.LOW:
				env.ssao_enabled = false
				env.glow_enabled = false
				env.fog_enabled = false
				env.volumetric_fog_enabled = false
				changes["ssao_enabled"] = false
				changes["glow_enabled"] = false
				changes["fog_enabled"] = false
				changes["volumetric_fog_enabled"] = false
			Preset.BALANCED:
				env.ssao_enabled = true
				env.ssao_radius = 1.3
				env.ssao_intensity = 1.6
				env.ssao_power = 1.5
				env.ssao_detail = 0.5
				env.glow_enabled = true
				env.glow_intensity = 0.28
				env.fog_enabled = true
				env.fog_mode = Environment.FOG_MODE_DEPTH
				env.fog_depth_begin = 85.0
				env.fog_depth_end = 360.0
				env.fog_depth_curve = 1.0
				env.volumetric_fog_enabled = false
				changes["ssao_enabled"] = true
				changes["glow_enabled"] = true
				changes["fog_enabled"] = true
				changes["volumetric_fog_enabled"] = false
			Preset.CINEMATIC, Preset.HIGH:
				env.ssao_enabled = true
				env.ssao_radius = 1.6
				env.ssao_intensity = 2.2
				env.ssao_power = 1.5
				env.ssao_detail = 0.6
				env.glow_enabled = true
				env.glow_intensity = 0.35
				env.fog_enabled = true
				env.fog_mode = Environment.FOG_MODE_DEPTH
				env.fog_depth_begin = 85.0
				env.fog_depth_end = 360.0
				env.fog_depth_curve = 1.0
				env.volumetric_fog_enabled = true
				env.volumetric_fog_density = 0.0022
				env.volumetric_fog_anisotropy = 0.68
				changes["ssao_enabled"] = true
				changes["glow_enabled"] = true
				changes["fog_enabled"] = true
				changes["volumetric_fog_enabled"] = true
				changes["volumetric_fog_density"] = 0.0022

	# 4. Grass MultiMesh Density (VegetationScatter)
	var scatter: VegetationScatter = scene_root.find_child("VegetationScatter", true, false) as VegetationScatter
	if scatter and scatter._grass_multimesh and scatter._grass_multimesh.multimesh:
		var mm: MultiMesh = scatter._grass_multimesh.multimesh
		var target_instances: int = 900
		match preset:
			Preset.LOW: target_instances = 450
			Preset.BALANCED: target_instances = 900
			Preset.CINEMATIC, Preset.HIGH: target_instances = 1400
		mm.visible_instance_count = mini(target_instances, mm.instance_count)
		changes["grass_count"] = mm.visible_instance_count

	# 5. Precipitation Particle Volume (WeatherEffectsController / AtmosphereDirector)
	var weather_fx: WeatherEffectsController = scene_root.find_child("WeatherEffectsController", true, false) as WeatherEffectsController
	if weather_fx:
		match preset:
			Preset.LOW:
				weather_fx.set_particle_budget(160, 60)
				changes["rain_amount"] = 160
				changes["snow_amount"] = 60
			Preset.BALANCED:
				weather_fx.set_particle_budget(350, 120)
				changes["rain_amount"] = 350
				changes["snow_amount"] = 120
			Preset.CINEMATIC, Preset.HIGH:
				weather_fx.set_particle_budget(550, 200)
				changes["rain_amount"] = 550
				changes["snow_amount"] = 200

	return changes

static func save_to_config(preset: Preset, path: String = CONFIG_PATH) -> Error:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("graphics", "preset", int(preset))
	return cfg.save(path)

static func load_from_config(path: String = CONFIG_PATH) -> Preset:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(path)
	if err == OK:
		var val: int = cfg.get_value("graphics", "preset", int(Preset.BALANCED))
		current_preset = clamp(val, 0, 3) as Preset
	else:
		current_preset = Preset.BALANCED
	return current_preset
