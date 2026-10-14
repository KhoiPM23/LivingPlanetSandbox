class_name GraphicsPresets
extends RefCounted

## Manages scalable rendering quality presets tailored for Intel Iris Xe integrated GPUs,
## battery saving profiles, and dedicated desktop hardware.

enum Preset {
	LOW = 0,      # Battery Saver / Integrated Low
	BALANCED = 1, # Intel Iris Xe Optimized (Default)
	HIGH = 2      # Desktop GPU / Maximum Fidelity
}

const CONFIG_PATH: String = "user://settings_graphics.cfg"

static var current_preset: Preset = Preset.BALANCED

static func get_preset_name(preset: Preset) -> String:
	match preset:
		Preset.LOW: return "Low (Battery Saver)"
		Preset.BALANCED: return "Balanced (Intel Iris Xe)"
		Preset.HIGH: return "High Fidelity"
		_: return "Balanced (Intel Iris Xe)"

static func get_preset_description(preset: Preset) -> String:
	match preset:
		Preset.LOW: return "3D Scale 75%, Shadows Off, 350 Grass, 150 Rain Particles"
		Preset.BALANCED: return "3D Scale 85%, Fast Shadows (2K), 700 Grass, 350 Rain Particles"
		Preset.HIGH: return "Native 100%, High Shadows (4K), 1000 Grass, 500 Rain Particles"
		_: return ""

## Applies rendering parameters across WorldEnvironment, DirectionalLight3D, and Viewport
static func apply_preset(preset: Preset, scene_root: Node) -> Dictionary:
	current_preset = preset
	var changes: Dictionary = {
		"preset": preset,
		"preset_name": get_preset_name(preset),
		"scaling_3d_scale": 1.0,
		"shadow_enabled": true,
		"glow_enabled": true,
		"fog_density": 0.004,
		"grass_count": 700,
		"rain_amount": 350
	}

	if not scene_root:
		return changes

	# 1. 3D Resolution Scaling (Viewport)
	var target_scale: float = 1.0
	match preset:
		Preset.LOW: target_scale = 0.75
		Preset.BALANCED: target_scale = 0.85
		Preset.HIGH: target_scale = 1.0
	changes["scaling_3d_scale"] = target_scale

	var viewport: Viewport = scene_root.get_viewport() if scene_root else null
	if viewport:
		viewport.scaling_3d_scale = target_scale

	# 2. Lighting & Shadows (DirectionalLight3D)
	var sun: DirectionalLight3D = scene_root.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	if sun:
		match preset:
			Preset.LOW:
				sun.shadow_enabled = false
				changes["shadow_enabled"] = false
			Preset.BALANCED:
				sun.shadow_enabled = true
				sun.directional_shadow_max_distance = 65.0
				changes["shadow_enabled"] = true
			Preset.HIGH:
				sun.shadow_enabled = true
				sun.directional_shadow_max_distance = 95.0
				changes["shadow_enabled"] = true

	# 3. Post-Processing & Fog (WorldEnvironment)
	var env_node: WorldEnvironment = scene_root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if env_node and env_node.environment:
		var env: Environment = env_node.environment
		match preset:
			Preset.LOW:
				env.glow_enabled = false
				env.fog_enabled = true
				env.fog_density = 0.003
				changes["glow_enabled"] = false
				changes["fog_density"] = 0.003
			Preset.BALANCED:
				env.glow_enabled = true
				env.glow_intensity = 0.25
				env.fog_enabled = true
				env.fog_density = 0.004
				changes["glow_enabled"] = true
				changes["fog_density"] = 0.004
			Preset.HIGH:
				env.glow_enabled = true
				env.glow_intensity = 0.35
				env.fog_enabled = true
				env.fog_density = 0.004
				changes["glow_enabled"] = true
				changes["fog_density"] = 0.004

	# 4. Grass MultiMesh Density (VegetationScatter)
	var scatter: VegetationScatter = scene_root.find_child("VegetationScatter", true, false) as VegetationScatter
	if scatter and scatter._grass_multimesh and scatter._grass_multimesh.multimesh:
		var mm: MultiMesh = scatter._grass_multimesh.multimesh
		var target_instances: int = 700
		match preset:
			Preset.LOW: target_instances = 350
			Preset.BALANCED: target_instances = 700
			Preset.HIGH: target_instances = 1000
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
			Preset.HIGH:
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
		current_preset = clamp(val, 0, 2) as Preset
	else:
		current_preset = Preset.BALANCED
	return current_preset
