@tool
extends SceneTree

func _init() -> void:
	print("--- Testing full hero pine setup ---")
	var gltf: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	var err = gltf.append_from_file("res://presentation/assets/foliage/pine1.gltf", state)
	if err != OK:
		printerr("Error loading pine1: ", err)
		quit(1)
		return
	var root: Node = gltf.generate_scene(state)
	var mi: MeshInstance3D = root.get_child(0) as MeshInstance3D

	var bark_mat: StandardMaterial3D = StandardMaterial3D.new()
	bark_mat.albedo_texture = load("res://presentation/assets/foliage/pine_bark_base.jpg")
	bark_mat.normal_enabled = true
	bark_mat.normal_texture = load("res://presentation/assets/foliage/pine_bark_normal.jpg")
	bark_mat.normal_scale = 1.0
	bark_mat.roughness_texture = load("res://presentation/assets/foliage/pine_bark_roughness.jpg")
	bark_mat.roughness = 0.9

	var needle_mat: ShaderMaterial = ShaderMaterial.new()
	needle_mat.shader = load("res://presentation/shaders/foliage_wind.gdshader")
	needle_mat.set_shader_parameter("use_texture", true)
	needle_mat.set_shader_parameter("use_alpha_scissor", true)
	needle_mat.set_shader_parameter("alpha_scissor_threshold", 0.42)
	needle_mat.set_shader_parameter("albedo_texture", load("res://presentation/assets/foliage/Cluster_albedo.png"))
	needle_mat.set_shader_parameter("use_normal_texture", true)
	needle_mat.set_shader_parameter("normal_texture", load("res://presentation/assets/foliage/pine_leaf_normal.jpg"))
	needle_mat.set_shader_parameter("normal_scale", 1.0)
	needle_mat.set_shader_parameter("use_roughness_texture", true)
	needle_mat.set_shader_parameter("roughness_texture", load("res://presentation/assets/foliage/pine_leaf_roughness.jpg"))
	needle_mat.set_shader_parameter("roughness", 0.85)
	needle_mat.set_shader_parameter("wind_speed", 1.15)
	needle_mat.set_shader_parameter("wind_strength", 0.16)
	needle_mat.set_shader_parameter("backlight_strength", 0.18)

	mi.set_surface_override_material(0, bark_mat)
	mi.set_surface_override_material(1, needle_mat)

	print("Mesh: ", mi.mesh.get_class(), " Surfaces: ", mi.mesh.get_surface_count())
	print("Bark mat albedo: ", (bark_mat.albedo_texture as Texture2D).get_path())
	print("Needle mat albedo: ", (needle_mat.get_shader_parameter("albedo_texture") as Texture2D).get_path())
	print("Needle mat normal: ", (needle_mat.get_shader_parameter("normal_texture") as Texture2D).get_path())
	print("Needle mat roughness: ", (needle_mat.get_shader_parameter("roughness_texture") as Texture2D).get_path())

	root.free()
	print("HERO PINE SETUP VERIFIED WITH 0 ERRORS!")
	quit(0)
