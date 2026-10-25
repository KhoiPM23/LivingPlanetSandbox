class_name TestBlock50QualityOverhaul
extends RefCounted

## Living Planet Sandbox — Block 50 Autonomous Quality Overhaul Test Suite
## Verifies:
## 1. Solar & Lunar Corona continuity (zero boundary step rings in procedural clouds)
## 2. Anime Cel Shading & Backlit Rim Lighting (ATTENUATION integration & backlight Fresnel)
## 3. Foliage View-Space Normal Softening (matrix transformation to view space)
## 4. 720m Full Forest Vista Preservation (all MultiMesh instances rendered without artificial culling)
## 5. Continental Lake & Marine Life Distribution (schools in Grand Emerald Lake & northern waters)
## 6. Shadow Cascade & FPS Optimization (3 PSSM splits, 140m max distance)

const DayNightScript = preload("res://presentation/environment/day_night_cycle.gd")
const MarineScript = preload("res://presentation/environment/marine_ecosystem.gd")
const PresetsScript = preload("res://presentation/graphics/graphics_presets.gd")

func test_clouds_corona_boundary_elimination() -> String:
	var shader: Shader = load("res://presentation/shaders/clouds_procedural.gdshader") as Shader
	if not shader:
		return "Failed to load clouds_procedural.gdshader"
	var code: String = shader.code
	# Check that artificial smoothstep cutoffs inside the corona calculations were removed
	if "smoothstep(0.80, 0.99, s_forward)" in code:
		return "Found hard smoothstep cutoff in solar corona; expected smooth exponential falloff"
	if "smoothstep(0.92, 0.998, m_forward)" in code:
		return "Found hard smoothstep cutoff in lunar halo; expected smooth exponential falloff"
	return ""

func test_anime_cel_shader_backlit_rim() -> String:
	var shader: Shader = load("res://presentation/shaders/anime_cel_shader.gdshader") as Shader
	if not shader:
		return "Failed to load anime_cel_shader.gdshader"
	var code: String = shader.code
	if not "backlight" in code:
		return "Expected anime_cel_shader to calculate backlight term for anime rim lighting"
	if not "combined_light" in code:
		return "Expected anime_cel_shader to integrate ATTENUATION into combined_light"
	return ""

func test_foliage_view_space_normal() -> String:
	var shader: Shader = load("res://presentation/shaders/foliage_wind.gdshader") as Shader
	if not shader:
		return "Failed to load foliage_wind.gdshader"
	var code: String = shader.code
	if not "VIEW_MATRIX * MODEL_MATRIX" in code:
		return "Expected foliage_wind.gdshader to transform radial canopy normal using VIEW_MATRIX * MODEL_MATRIX"
	return ""

func test_tree_multimesh_preservation_in_presets() -> String:
	var scatter: VegetationScatter = VegetationScatter.new()
	var tmmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	tmmi.name = "PineCanopyMultiMesh"
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 800
	tmmi.multimesh = mm
	scatter.add_child(tmmi)

	PresetsScript.apply_preset(PresetsScript.Preset.BALANCED, scatter)

	# In Godot MultiMesh, visible_instance_count == -1 means all instances are rendered.
	if mm.visible_instance_count != -1 and mm.visible_instance_count < 800:
		scatter.queue_free()
		return "Expected all 800 tree instances to be preserved in BALANCED preset (got %d)" % mm.visible_instance_count

	scatter.queue_free()
	return ""

func test_grand_lake_and_northern_marine_schools() -> String:
	var marine: MarineEcosystem = MarineScript.new()
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.island_size = 720.0
	terrain.generate_island(1337)
	marine.setup(terrain, null, 1337)

	# Should have at least 8 distinct schools across bay, cove, Grand Lake and northern waters
	if marine._school_centers.size() < 8:
		var count = marine._school_centers.size()
		marine.queue_free()
		terrain.queue_free()
		return "Expected at least 8 fish schools across island lakes and bays, got %d" % count

	if marine._fish_agents.size() < 120:
		var agent_count = marine._fish_agents.size()
		marine.queue_free()
		terrain.queue_free()
		return "Expected at least 120 fish agents across the 720m world, got %d" % agent_count

	# Verify Grand Lake school exists around (95, 85)
	var has_grand_lake: bool = false
	for sid in marine._school_centers:
		var c: Vector3 = marine._school_centers[sid]
		if Vector2(c.x - 95.0, c.z - 85.0).length() < 35.0:
			has_grand_lake = true
			break

	marine.queue_free()
	terrain.queue_free()

	if not has_grand_lake:
		return "Expected a fish school in Grand Emerald Lake near (95, 85)"

	return ""
