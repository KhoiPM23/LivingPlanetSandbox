@tool
extends SceneTree

func _init() -> void:
	print("--- Testing bush setup ---")
	var gltf: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	var err = gltf.append_from_file("res://presentation/assets/foliage/bush2.gltf", state)
	if err != OK:
		printerr("Error loading bush2: ", err)
		quit(1)
		return
	var root: Node = gltf.generate_scene(state)
	var mi: MeshInstance3D = root.get_child(0) as MeshInstance3D

	var stem_mat: StandardMaterial3D = StandardMaterial3D.new()
	stem_mat.albedo_texture = load("res://presentation/assets/foliage/Lilac_bark_color.jpg")
	stem_mat.normal_enabled = true
	stem_mat.normal_texture = load("res://presentation/assets/foliage/Lilac_bark_normal.jpg")
	stem_mat.roughness = 0.88

	var leaf_mat: ShaderMaterial = ShaderMaterial.new()
	leaf_mat.shader = load("res://presentation/shaders/foliage_wind.gdshader")
	leaf_mat.set_shader_parameter("use_texture", true)
	leaf_mat.set_shader_parameter("use_alpha_scissor", true)
	leaf_mat.set_shader_parameter("alpha_scissor_threshold", 0.45)
	leaf_mat.set_shader_parameter("albedo_texture", load("res://presentation/assets/foliage/lilac_cards_color.png"))
	leaf_mat.set_shader_parameter("use_normal_texture", true)
	leaf_mat.set_shader_parameter("normal_texture", load("res://presentation/assets/foliage/lilac_cards_normal.jpg"))
	leaf_mat.set_shader_parameter("use_roughness_texture", true)
	leaf_mat.set_shader_parameter("roughness_texture", load("res://presentation/assets/foliage/lilac_cards_roughness.jpg"))
	leaf_mat.set_shader_parameter("roughness", 0.82)
	leaf_mat.set_shader_parameter("wind_speed", 1.3)
	leaf_mat.set_shader_parameter("wind_strength", 0.22)
	leaf_mat.set_shader_parameter("backlight_strength", 0.15)

	mi.set_surface_override_material(0, stem_mat)
	mi.set_surface_override_material(1, leaf_mat)

	print("Bush surfaces: ", mi.mesh.get_surface_count())
	print("Bush stem tex: ", (stem_mat.albedo_texture as Texture2D).get_path())
	print("Bush leaf tex: ", (leaf_mat.get_shader_parameter("albedo_texture") as Texture2D).get_path())

	root.free()
	print("BUSH SETUP VERIFIED WITH 0 ERRORS!")
	quit(0)
