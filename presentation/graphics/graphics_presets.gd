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
		Preset.LOW: return "3D Scale 75%, MSAA Off, Shadows Off, Fog Off, Scaled Grass, 160 Rain"
		Preset.BALANCED: return "3D Scale 85%, ACES Tonemap, 2-Split Shadows (60m), Foliage SSS, Depth Fog, Scaled Grass, 350 Rain"
		Preset.CINEMATIC, Preset.HIGH: return "Native 100%, MSAA 2X, High Shadows (110m), SSAO & Volumetric Fog, Full Grass, 550 Rain"
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
	var target_scaling_mode: Viewport.Scaling3DMode = Viewport.SCALING_3D_MODE_BILINEAR
	var target_fsr_sharpness: float = 0.20
	match preset:
		Preset.LOW:
			target_scale = 0.75
			target_scaling_mode = Viewport.SCALING_3D_MODE_FSR
			target_fsr_sharpness = 0.35
			target_msaa = Viewport.MSAA_DISABLED
		Preset.BALANCED:
			target_scale = 0.85
			target_scaling_mode = Viewport.SCALING_3D_MODE_FSR
			target_fsr_sharpness = 0.22
			target_msaa = Viewport.MSAA_DISABLED
		Preset.CINEMATIC, Preset.HIGH:
			target_scale = 1.0
			target_scaling_mode = Viewport.SCALING_3D_MODE_BILINEAR
			target_msaa = Viewport.MSAA_2X

	changes["scaling_3d_scale"] = target_scale
	changes["msaa_3d"] = target_msaa

	var viewport: Viewport = scene_root.get_viewport() if scene_root else null
	if viewport:
		viewport.scaling_3d_scale = target_scale
		viewport.scaling_3d_mode = target_scaling_mode
		viewport.fsr_sharpness = target_fsr_sharpness
		viewport.msaa_3d = target_msaa
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if (preset == Preset.CINEMATIC or preset == Preset.HIGH) else Viewport.SCREEN_SPACE_AA_DISABLED

	# 2. Lighting & Shadows (DirectionalLight3D)
	var sun: DirectionalLight3D = scene_root.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	if sun:
		match preset:
			Preset.LOW:
				sun.shadow_enabled = false
				changes["shadow_enabled"] = false
			Preset.BALANCED:
				sun.shadow_enabled = true
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
				sun.directional_shadow_blend_splits = false
				sun.directional_shadow_fade_start = 0.85
				sun.directional_shadow_max_distance = 60.0
				sun.shadow_blur = 1.6
				sun.shadow_bias = 0.015
				sun.shadow_normal_bias = 1.4
				sun.light_angular_distance = 0.65
				sun.light_volumetric_fog_energy = 1.0
				changes["shadow_enabled"] = true
			Preset.CINEMATIC:
				sun.shadow_enabled = true
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
				sun.directional_shadow_blend_splits = true
				sun.directional_shadow_max_distance = 360.0
				sun.directional_shadow_split_1 = 0.035
				sun.directional_shadow_split_2 = 0.12
				sun.directional_shadow_split_3 = 0.35
				sun.directional_shadow_fade_start = 0.85
				sun.shadow_blur = 1.5
				sun.shadow_bias = 0.012
				sun.shadow_normal_bias = 1.1
				sun.light_angular_distance = 0.5
				sun.light_volumetric_fog_energy = 1.35
				changes["shadow_enabled"] = true
			Preset.HIGH:
				sun.shadow_enabled = true
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
				sun.directional_shadow_blend_splits = true
				sun.directional_shadow_max_distance = 110.0
				sun.shadow_blur = 1.6
				sun.shadow_bias = 0.015
				sun.shadow_normal_bias = 1.4
				sun.light_angular_distance = 0.65
				sun.light_volumetric_fog_energy = 1.35
				changes["shadow_enabled"] = true

	# 3. Post-Processing & Fog (WorldEnvironment)
	var env_node: WorldEnvironment = scene_root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if env_node and env_node.environment:
		var env: Environment = env_node.environment
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_exposure = 0.96
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		env.glow_hdr_threshold = 1.06
		env.adjustment_enabled = true
		env.adjustment_saturation = 1.04
		env.adjustment_contrast = 1.04
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
				env.ssao_enabled = false
				env.glow_enabled = true
				env.glow_bloom = 0.08
				env.glow_intensity = 0.28
				env.fog_enabled = true
				env.fog_mode = Environment.FOG_MODE_DEPTH
				env.fog_depth_begin = 95.0
				env.fog_depth_end = 620.0
				env.fog_depth_curve = 1.18
				env.volumetric_fog_enabled = false
				changes["ssao_enabled"] = false
				changes["glow_enabled"] = true
				changes["fog_enabled"] = true
				changes["volumetric_fog_enabled"] = false
			Preset.CINEMATIC, Preset.HIGH:
				# High-fidelity calibrated SSAO without sky edge bleeding
				env.ssao_enabled = true
				env.ssao_radius = 1.1
				env.ssao_intensity = 1.05
				env.ssao_power = 1.2
				env.ssao_detail = 0.5
				env.glow_enabled = true
				env.glow_bloom = 0.10
				env.glow_intensity = 0.32
				env.fog_enabled = true
				env.fog_mode = Environment.FOG_MODE_DEPTH
				env.fog_depth_begin = 85.0
				env.fog_depth_end = 680.0
				env.fog_depth_curve = 1.18
				# Cinematic volumetric fog calibrated with soft density and smooth falloff
				env.volumetric_fog_enabled = true
				env.volumetric_fog_density = 0.0032
				env.volumetric_fog_length = 115.0
				env.volumetric_fog_ambient_inject = 0.22
				changes["ssao_enabled"] = true
				changes["glow_enabled"] = true
				changes["fog_enabled"] = true
				changes["volumetric_fog_enabled"] = true

	# 4. Foliage & Tree MultiMesh Density and Distance Culling (VegetationScatter)
	var scatter: VegetationScatter = scene_root.find_child("VegetationScatter", true, false) as VegetationScatter
	if scatter:
		# 4a. Ground Grass MultiMesh
		if scatter._grass_multimesh and scatter._grass_multimesh.multimesh:
			var mm: MultiMesh = scatter._grass_multimesh.multimesh
			var target_instances: int = mm.instance_count
			if mm.instance_count > 1500:
				match preset:
					Preset.LOW: target_instances = int(mm.instance_count * 0.45)
					Preset.BALANCED: target_instances = int(mm.instance_count * 0.85)
					Preset.CINEMATIC, Preset.HIGH: target_instances = mm.instance_count
			else:
				match preset:
					Preset.LOW: target_instances = 450
					Preset.BALANCED: target_instances = 900
					Preset.CINEMATIC, Preset.HIGH: target_instances = 1400
			mm.visible_instance_count = mini(target_instances, mm.instance_count)
			changes["grass_count"] = mm.visible_instance_count

			match preset:
				Preset.LOW:
					scatter._grass_multimesh.visibility_range_end = 32.0
					scatter._grass_multimesh.visibility_range_end_margin = 6.0
				Preset.BALANCED:
					scatter._grass_multimesh.visibility_range_end = 38.0
					scatter._grass_multimesh.visibility_range_end_margin = 8.0
				Preset.CINEMATIC, Preset.HIGH:
					scatter._grass_multimesh.visibility_range_end = 75.0
					scatter._grass_multimesh.visibility_range_end_margin = 15.0
			scatter._grass_multimesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

		# 4b. Tall Grass MultiMesh
		var tall_mmi: MultiMeshInstance3D = scatter.find_child("TallGrassMultiMesh", true, false) as MultiMeshInstance3D
		if tall_mmi and tall_mmi.multimesh:
			var tall_mm: MultiMesh = tall_mmi.multimesh
			match preset:
				Preset.LOW:
					tall_mm.visible_instance_count = mini(100, int(tall_mm.instance_count * 0.30))
					tall_mmi.visibility_range_end = 24.0
					tall_mmi.visibility_range_end_margin = 6.0
				Preset.BALANCED:
					tall_mm.visible_instance_count = mini(200, int(tall_mm.instance_count * 0.60))
					tall_mmi.visibility_range_end = 30.0
					tall_mmi.visibility_range_end_margin = 6.0
				Preset.CINEMATIC, Preset.HIGH:
					tall_mm.visible_instance_count = tall_mm.instance_count
					tall_mmi.visibility_range_end = 65.0
					tall_mmi.visibility_range_end_margin = 12.0
			tall_mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

		# 4c. Pine Canopy MultiMeshes (High Triangle Count Optimization)
		for tname in ["PineCanopyMultiMesh", "PineDenseMultiMesh", "PineSubcanopyMultiMesh"]:
			var tmmi: MultiMeshInstance3D = scatter.find_child(tname, true, false) as MultiMeshInstance3D
			if tmmi and tmmi.multimesh:
				var t_mm: MultiMesh = tmmi.multimesh
				t_mm.visible_instance_count = t_mm.instance_count
				match preset:
					Preset.LOW:
						tmmi.visibility_range_end = 360.0
						tmmi.visibility_range_end_margin = 40.0
						tmmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					Preset.BALANCED:
						tmmi.visibility_range_end = 520.0
						tmmi.visibility_range_end_margin = 50.0
						tmmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					Preset.CINEMATIC, Preset.HIGH:
						tmmi.visibility_range_end = 650.0
						tmmi.visibility_range_end_margin = 60.0
						tmmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if tname == "PineSubcanopyMultiMesh" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				tmmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

		# 4d. Tropical and Shrub MultiMeshes
		for trname in ["TropicalUndergrowthMultiMesh", "TropicalCanopyMultiMesh", "TropicalSubcanopyMultiMesh", "TropicalFernsMultiMesh"]:
			var trmmi: MultiMeshInstance3D = scatter.find_child(trname, true, false) as MultiMeshInstance3D
			if trmmi and trmmi.multimesh:
				var tr_mm: MultiMesh = trmmi.multimesh
				tr_mm.visible_instance_count = tr_mm.instance_count
				match preset:
					Preset.LOW:
						trmmi.visibility_range_end = 200.0
						trmmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					Preset.BALANCED:
						trmmi.visibility_range_end = 380.0
						trmmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					Preset.CINEMATIC, Preset.HIGH:
						trmmi.visibility_range_end = 500.0
						trmmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				trmmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

		# 4e. Needle Shader Max Draw Distance & Flower Distance Culling
		var needle_mat: ShaderMaterial = TreePine.get_shared_pine_needle_material()
		if needle_mat:
			match preset:
				Preset.LOW: needle_mat.set_shader_parameter("max_draw_distance", 0.0)
				Preset.BALANCED: needle_mat.set_shader_parameter("max_draw_distance", 0.0)
				Preset.CINEMATIC, Preset.HIGH: needle_mat.set_shader_parameter("max_draw_distance", 0.0)

		for c in scatter.get_children():
			if c is MultiMeshInstance3D and c.name.begins_with("Flowers"):
				c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				match preset:
					Preset.LOW:
						c.visibility_range_end = 35.0
						c.visibility_range_end_margin = 8.0
					Preset.BALANCED:
						c.visibility_range_end = 65.0
						c.visibility_range_end_margin = 12.0
					Preset.CINEMATIC, Preset.HIGH:
						c.visibility_range_end = 120.0
						c.visibility_range_end_margin = 18.0
				c.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

		# 4f. Standalone Hero Trees (TreePine & Broadleaf Deciduous)
		for child in scatter.get_children():
			if child is TreePine:
				var tm: MeshInstance3D = child.find_child("TreeModel", true, false) as MeshInstance3D
				if tm:
					match preset:
						Preset.LOW:
							tm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
							tm.visibility_range_end = 180.0
						Preset.BALANCED:
							var dist: float = child.position.length()
							if dist > 32.0:
								tm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
							else:
								tm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
							tm.visibility_range_end = 380.0
						Preset.CINEMATIC, Preset.HIGH:
							tm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
							tm.visibility_range_end = 650.0
					tm.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			elif child is MeshInstance3D and child.name != "GrassMultiMesh":
				match preset:
					Preset.LOW:
						child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
						child.visibility_range_end = 140.0
					Preset.BALANCED:
						if child.position.length() > 32.0:
							child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
						child.visibility_range_end = 280.0
					Preset.CINEMATIC, Preset.HIGH:
						child.visibility_range_end = 450.0

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
