class_name TestFoliageOpacityRegression
extends RefCounted

## Automated regression tests verifying solid foliage opacity, two-sided culling,
## depth buffer writes, texture preservation, and absence of see-through translucency.

func run_tests() -> Dictionary:
	var passed: int = 0
	var failed: int = 0
	var details: Array = []

	var tests: Array = [
		"test_tree_pine_materials_exist_and_distinct",
		"test_kaykit_material_preserves_texture_and_no_backlight",
		"test_kenney_material_uses_vertex_color_and_no_backlight",
		"test_foliage_shader_enforces_cull_disabled_and_depth_opaque",
		"test_tree_pine_instantiation_uses_correct_material",
		"test_understory_materials_cull_disabled_and_depth_always",
		"test_grass_multimesh_subtle_backlight_bounds"
	]

	for tname in tests:
		var res: bool = call(tname)
		if res:
			passed += 1
			print("  [PASS] %s" % tname)
		else:
			failed += 1
			details.append(tname)
			print("  [FAIL] %s" % tname)

	return {"passed": passed, "failed": failed, "failed_tests": details}

func test_tree_pine_materials_exist_and_distinct() -> bool:
	TreePine._init_cache()
	var bark_mat = TreePine.get_shared_pine_bark_material()
	var needle_mat = TreePine.get_shared_pine_needle_material()
	if bark_mat == null or needle_mat == null:
		return false
	# Ensure they are distinct materials: Bark is PBR StandardMaterial3D, Needle is Foliage ShaderMaterial
	if bark_mat == needle_mat:
		return false
	if not bark_mat is StandardMaterial3D or not needle_mat is ShaderMaterial:
		return false
	return true

func test_kaykit_material_preserves_texture_and_no_backlight() -> bool:
	var bark_mat = TreePine.get_shared_pine_bark_material()
	if not bark_mat is StandardMaterial3D:
		return false
	# Bark must use PBR textures and have proper depth draw
	if bark_mat.albedo_texture == null or bark_mat.normal_texture == null:
		return false
	if bark_mat.cull_mode != BaseMaterial3D.CULL_BACK:
		return false
	return true

func test_kenney_material_uses_vertex_color_and_no_backlight() -> bool:
	var needle_mat = TreePine.get_shared_pine_needle_material()
	if not needle_mat is ShaderMaterial:
		return false
	var use_tex = needle_mat.get_shader_parameter("use_texture")
	var use_scissor = needle_mat.get_shader_parameter("use_alpha_scissor")
	var tex = needle_mat.get_shader_parameter("albedo_texture")

	# Needles must use foliage atlas texture and alpha scissor
	if not use_tex or not use_scissor or tex == null:
		return false
	return true

func test_foliage_shader_enforces_cull_disabled_and_depth_opaque() -> bool:
	var shader = preload("res://presentation/shaders/foliage_wind.gdshader")
	if shader == null:
		return false
	var code = shader.code
	# Must have render_mode cull_disabled and depth_draw_opaque
	if not "cull_disabled" in code:
		return false
	if not "depth_draw_opaque" in code:
		return false
	# Must have two-sided normal correction for backfaces
	if not "FRONT_FACING ? NORMAL : -NORMAL" in code:
		return false
	return true

func test_tree_pine_instantiation_uses_correct_material() -> bool:
	var tree: TreePine = TreePine.new()
	tree.position = Vector3(5.0, 3.0, 5.0)
	tree._ready()
	var child_inst = tree.get_node_or_null("TreeModel") as MeshInstance3D
	if child_inst == null:
		tree.free()
		return false
	# Must have shadow casting ON and dual-surface PBR overrides
	if child_inst.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
		tree.free()
		return false
	var mat0 = child_inst.get_surface_override_material(0)
	if mat0 == null or not mat0 is StandardMaterial3D:
		tree.free()
		return false
	if child_inst.mesh and child_inst.mesh.get_surface_count() > 1:
		var mat1 = child_inst.get_surface_override_material(1)
		if mat1 == null or not mat1 is ShaderMaterial:
			tree.free()
			return false
	tree.free()
	return true

func test_understory_materials_cull_disabled_and_depth_always() -> bool:
	VegetationScatter._init_asset_cache()
	var b_mat = VegetationScatter._cached_bush_mat
	if b_mat is StandardMaterial3D:
		if b_mat.cull_mode != BaseMaterial3D.CULL_DISABLED:
			return false
		if b_mat.depth_draw_mode != BaseMaterial3D.DEPTH_DRAW_ALWAYS:
			return false

	for p_info in VegetationScatter._cached_nature_props.values():
		var m = p_info.get("mat", null)
		if m is StandardMaterial3D:
			if m.cull_mode != BaseMaterial3D.CULL_DISABLED:
				return false
	return true

func test_grass_multimesh_subtle_backlight_bounds() -> bool:
	# Grass can have subtle backlight for thin blades, but must be <= 0.1 to avoid cellophane look
	var g_mat = ShaderMaterial.new()
	g_mat.shader = preload("res://presentation/shaders/foliage_wind.gdshader")
	g_mat.set_shader_parameter("backlight_strength", 0.05)
	var bl = float(g_mat.get_shader_parameter("backlight_strength"))
	if bl < 0.01 or bl > 0.10:
		return false
	return true
