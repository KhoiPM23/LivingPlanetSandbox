class_name TestBlock60ShaderGraphicsAndPresets
extends RefCounted

## Unit & Integration Test Suite 60:
## Minecraft-Shader Quality Pipeline, Pragmatic Forward+ Presets & Visual Realism (Block 60)

const FoliageShaderPath = "res://presentation/shaders/foliage_wind.gdshader"
const WaterShaderPath = "res://presentation/shaders/water.gdshader"
const TerrainShaderPath = "res://presentation/shaders/terrain_pbr.gdshader"

func test_foliage_shader_leaf_flutter_and_vibrant_backlight() -> bool:
	var f = FileAccess.open(FoliageShaderPath, FileAccess.READ)
	if not f:
		push_error("Failed to open foliage_wind.gdshader")
		return false
	var code = f.get_as_text()
	f.close()

	# 1. Leaf flutter wave calculation in vertex()
	if not code.contains("leaf_flutter"):
		push_error("Missing leaf_flutter in foliage_wind.gdshader vertex pass")
		return false
	if not code.contains("use_alpha_scissor || use_texture"):
		push_error("Missing canopy leaf flutter branch condition in vertex pass")
		return false

	# 2. Vibrant chlorophyll subsurface backlight transmission in fragment()
	if not code.contains("BACKLIGHT = sss_color * backlight_strength;"):
		push_error("Missing BACKLIGHT assignment in foliage_wind.gdshader fragment pass")
		return false
	if not code.contains("vec3(0.42, 0.72, 0.20)"):
		push_error("Missing grass blade vibrant chlorophyll color term in foliage_wind.gdshader")
		return false
	if not code.contains("vec3(0.40, 0.70, 0.18)"):
		push_error("Missing tree canopy vibrant chlorophyll color term in foliage_wind.gdshader")
		return false

	return true

func test_water_shader_caustics_and_fresnel_glint() -> bool:
	var f = FileAccess.open(WaterShaderPath, FileAccess.READ)
	if not f:
		push_error("Failed to open water.gdshader")
		return false
	var code = f.get_as_text()
	f.close()

	# 1. Analytical shallow water caustics with dual-wave interference
	if not code.contains("caustics ="):
		push_error("Missing caustics assignment in water.gdshader")
		return false
	if not code.contains("depth_diff < 3.8"):
		push_error("Missing shallow water caustics depth cutoff (< 3.8) in water.gdshader")
		return false
	if not code.contains("pow(abs(c1 + c2) * 0.5, 3.2)"):
		push_error("Missing dual wave caustic interference formula in water.gdshader")
		return false

	# 2. Specular wave crest glint & grazing fresnel roughness
	if not code.contains("SPECULAR = mix(0.55, 0.96, fresnel)"):
		push_error("Missing grazing angle specular glint boost in water.gdshader")
		return false
	if not code.contains("ROUGHNESS = mix(roughness, 0.015, fresnel)"):
		push_error("Missing mirror-like grazing angle roughness modulation in water.gdshader")
		return false

	return true

func test_terrain_shader_crevice_ambient_occlusion() -> bool:
	var f = FileAccess.open(TerrainShaderPath, FileAccess.READ)
	if not f:
		push_error("Failed to open terrain_pbr.gdshader")
		return false
	var code = f.get_as_text()
	f.close()

	# Slope-dependent crevice contact ambient occlusion
	if not code.contains("crevice_ao"):
		push_error("Missing crevice_ao calculation in terrain_pbr.gdshader")
		return false
	if not code.contains("AO = crevice_ao;"):
		push_error("Missing AO assignment in terrain_pbr.gdshader")
		return false
	if not code.contains("AO_LIGHT_AFFECT = 0.50;"):
		push_error("Missing AO_LIGHT_AFFECT assignment in terrain_pbr.gdshader")
		return false

	return true

func test_graphics_presets_balanced_and_high_shadow_distances() -> bool:
	var root = Node3D.new()
	var sun = DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	root.add_child(sun)

	var env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env = Environment.new()
	env_node.environment = env
	root.add_child(env_node)

	# Balanced Preset Verification (The "Minecraft Shader" Sweet Spot)
	var balanced_res = GraphicsPresets.apply_preset(GraphicsPresets.Preset.BALANCED, root)
	if not sun.shadow_enabled:
		push_error("Expected shadow_enabled == true in Balanced preset")
		root.free()
		return false
	if not is_equal_approx(sun.directional_shadow_max_distance, 60.0):
		push_error("Expected Balanced shadow max distance 60.0m, got: %f" % sun.directional_shadow_max_distance)
		root.free()
		return false
	if not is_equal_approx(sun.directional_shadow_fade_start, 0.85):
		push_error("Expected Balanced shadow fade start 0.85, got: %f" % sun.directional_shadow_fade_start)
		root.free()
		return false
	if sun.directional_shadow_mode != DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS:
		push_error("Expected 2-splits shadow mode in Balanced preset")
		root.free()
		return false

	# High / Cinematic Preset Verification
	var high_res = GraphicsPresets.apply_preset(GraphicsPresets.Preset.CINEMATIC, root)
	if not sun.shadow_enabled:
		push_error("Expected shadow_enabled == true in High/Cinematic preset")
		root.free()
		return false
	if not is_equal_approx(sun.directional_shadow_max_distance, 110.0):
		push_error("Expected High shadow max distance 110.0m, got: %f" % sun.directional_shadow_max_distance)
		root.free()
		return false
	if sun.directional_shadow_mode != DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS:
		push_error("Expected 4-splits shadow mode in High/Cinematic preset")
		root.free()
		return false
	if not sun.directional_shadow_blend_splits:
		push_error("Expected cascade blend splits enabled in High/Cinematic preset")
		root.free()
		return false

	root.free()
	return true

func test_graphics_presets_aces_tonemap_preservation() -> bool:
	var root = Node3D.new()
	var env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env = Environment.new()
	env_node.environment = env
	root.add_child(env_node)

	GraphicsPresets.apply_preset(GraphicsPresets.Preset.BALANCED, root)
	if env.tonemap_mode != Environment.TONE_MAPPER_ACES:
		push_error("Expected ACES tonemapper in Balanced, got: %d" % env.tonemap_mode)
		root.free()
		return false
	if not is_equal_approx(env.tonemap_exposure, 0.96):
		push_error("Expected tonemap exposure 0.96, got: %f" % env.tonemap_exposure)
		root.free()
		return false
	if env.glow_blend_mode != Environment.GLOW_BLEND_MODE_SOFTLIGHT:
		push_error("Expected softlight glow blend mode, got: %d" % env.glow_blend_mode)
		root.free()
		return false
	if not is_equal_approx(env.glow_bloom, 0.08):
		push_error("Expected glow bloom 0.08, got: %f" % env.glow_bloom)
		root.free()
		return false
	if not env.adjustment_enabled or not is_equal_approx(env.adjustment_saturation, 1.04):
		push_error("Expected adjustment saturation 1.04 enabled")
		root.free()
		return false

	root.free()
	return true

func test_graphics_presets_ssao_and_volumetric_fog_calibration() -> bool:
	var root = Node3D.new()
	var env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env = Environment.new()
	env_node.environment = env
	root.add_child(env_node)

	# In Balanced: SSAO and Volumetric fog are OFF (ensuring high framerates on Iris Xe)
	GraphicsPresets.apply_preset(GraphicsPresets.Preset.BALANCED, root)
	if env.ssao_enabled:
		push_error("Expected SSAO disabled in Balanced preset for Iris Xe performance")
		root.free()
		return false
	if env.volumetric_fog_enabled:
		push_error("Expected volumetric fog disabled in Balanced preset for Iris Xe performance")
		root.free()
		return false
	if not env.fog_enabled or env.fog_mode != Environment.FOG_MODE_DEPTH:
		push_error("Expected depth fog enabled in Balanced preset")
		root.free()
		return false

	# In High / Cinematic: SSAO and Volumetric fog are ON with tuned gentle parameters
	GraphicsPresets.apply_preset(GraphicsPresets.Preset.CINEMATIC, root)
	if not env.ssao_enabled:
		push_error("Expected SSAO enabled in Cinematic preset")
		root.free()
		return false
	if not is_equal_approx(env.ssao_radius, 1.1) or not is_equal_approx(env.ssao_intensity, 1.05):
		push_error("Expected SSAO radius 1.1 and intensity 1.05 in Cinematic preset")
		root.free()
		return false
	if not env.volumetric_fog_enabled:
		push_error("Expected volumetric fog enabled in Cinematic preset")
		root.free()
		return false
	if not is_equal_approx(env.volumetric_fog_density, 0.0032) or not is_equal_approx(env.volumetric_fog_length, 115.0):
		push_error("Expected volumetric fog density 0.0032 and length 115m in Cinematic preset")
		root.free()
		return false

	root.free()
	return true
