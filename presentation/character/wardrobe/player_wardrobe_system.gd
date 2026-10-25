class_name PlayerWardrobeSystem
extends RefCounted

## Living Planet Sandbox — Player Wardrobe & Appearance System.
## Low Coupling & High Cohesion: Handles multi-outfit switching, mesh sculpt caches,
## and material management without polluting player locomotion physics.
## Features graceful degradation for optional / gitignored untracked textures.

signal outfit_changed(outfit_id: String, display_name: String, is_bikini: bool)

enum AnimeOutfitMode {
	STANDARD = 0,
	BIKINI = 1,
	CUSTOM = 2,
	ROGUE = 3
}

enum DouyinOutfitMode {
	BIKINI = 0,
	NUDE = 1
}

# --- ANIME CHARACTER REFERENCES ---
var anime_body_mesh_instance: MeshInstance3D = null
var anime_skeleton: Skeleton3D = null
var anime_default_body_mesh: Mesh = null
var anime_default_materials: Array[Material] = []
var anime_bikini_body_mesh: ArrayMesh = null
var anime_nude_body_mesh: ArrayMesh = null
var anime_bikini_mat: StandardMaterial3D = null
var anime_custom_mat: StandardMaterial3D = null
var anime_outfit_mode: int = AnimeOutfitMode.STANDARD

# Anime Bone IDs
var anime_bust_l1_bone: int = -1
var anime_bust_l2_bone: int = -1
var anime_bust_r1_bone: int = -1
var anime_bust_r2_bone: int = -1
var anime_hips_bone: int = -1
var anime_spine_bone: int = -1
var anime_shoulder_l_bone: int = -1
var anime_shoulder_r_bone: int = -1

# --- DOUYIN CHARACTER REFERENCES ---
var douyin_body_mesh_instance: MeshInstance3D = null
var douyin_skeleton: Skeleton3D = null
var douyin_default_body_mesh: Mesh = null
var douyin_default_materials: Array[Material] = []
var douyin_bikini_body_mesh: ArrayMesh = null
var douyin_nude_body_mesh: ArrayMesh = null
var douyin_bikini_mat: StandardMaterial3D = null
var douyin_nude_mat: StandardMaterial3D = null
var douyin_outfit_mode: int = DouyinOutfitMode.BIKINI

# Douyin Bone IDs
var douyin_bust_l1_bone: int = -1
var douyin_bust_l2_bone: int = -1
var douyin_bust_r1_bone: int = -1
var douyin_bust_r2_bone: int = -1
var douyin_hips_bone: int = -1
var douyin_spine_bone: int = -1
var douyin_shoulder_l_bone: int = -1
var douyin_shoulder_r_bone: int = -1

# Optional Bra Root Node
var douyin_bra_root: Node3D = null

# Callback hook for weapon system visibility
var on_weapon_visibility_changed: Callable = Callable()
var on_face_material_requested: Callable = Callable()

# =========================================================================
# INITIALIZATION & SETUP
# =========================================================================

func setup_anime(mi: MeshInstance3D, sk: Skeleton3D, default_mats: Array[Material]) -> void:
	anime_body_mesh_instance = mi
	anime_skeleton = sk
	if mi and mi.mesh:
		anime_default_body_mesh = mi.mesh
	anime_default_materials = default_mats.duplicate()

	if sk:
		anime_bust_l1_bone = sk.find_bone("J_Sec_L_Bust1")
		anime_bust_l2_bone = sk.find_bone("J_Sec_L_Bust2")
		anime_bust_r1_bone = sk.find_bone("J_Sec_R_Bust1")
		anime_bust_r2_bone = sk.find_bone("J_Sec_R_Bust2")
		anime_hips_bone = sk.find_bone("J_Bip_C_Hips")
		anime_spine_bone = sk.find_bone("J_Bip_C_Spine")
		anime_shoulder_l_bone = sk.find_bone("J_Bip_L_Shoulder")
		anime_shoulder_r_bone = sk.find_bone("J_Bip_R_Shoulder")

	_init_anime_materials()

func setup_douyin(mi: MeshInstance3D, sk: Skeleton3D, default_mats: Array[Material]) -> void:
	douyin_body_mesh_instance = mi
	douyin_skeleton = sk
	if mi and mi.mesh:
		douyin_default_body_mesh = mi.mesh
	douyin_default_materials = default_mats.duplicate()

	if sk:
		douyin_bust_l1_bone = sk.find_bone("J_Sec_L_Bust1")
		douyin_bust_l2_bone = sk.find_bone("J_Sec_L_Bust2")
		douyin_bust_r1_bone = sk.find_bone("J_Sec_R_Bust1")
		douyin_bust_r2_bone = sk.find_bone("J_Sec_R_Bust2")
		douyin_hips_bone = sk.find_bone("J_Bip_C_Hips")
		douyin_spine_bone = sk.find_bone("J_Bip_C_Spine")
		douyin_shoulder_l_bone = sk.find_bone("J_Bip_L_Shoulder")
		douyin_shoulder_r_bone = sk.find_bone("J_Bip_R_Shoulder")

	_init_douyin_materials()

# =========================================================================
# MATERIAL HELPERS & ASSET CHECKING
# =========================================================================

func _load_texture_safe(res_path: String) -> Texture2D:
	var global_path: String = ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(global_path):
		var img: Image = Image.load_from_file(global_path)
		if img:
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(res_path):
		return load(res_path) as Texture2D
	return null

func _init_anime_materials() -> void:
	if anime_default_materials.is_empty():
		return

	var base_mat = anime_default_materials[0]
	if not base_mat is BaseMaterial3D:
		return

	# 1. Bikini Skin Material
	anime_bikini_mat = base_mat.duplicate() as StandardMaterial3D
	anime_bikini_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	anime_bikini_mat.next_pass = null
	anime_bikini_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	anime_bikini_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	anime_bikini_mat.roughness = 0.62
	anime_bikini_mat.metallic = 0.0
	anime_bikini_mat.metallic_specular = 0.35
	anime_bikini_mat.albedo_color = Color(1.0, 0.98, 0.96, 1.0)
	anime_bikini_mat.subsurf_scatter_enabled = true
	anime_bikini_mat.subsurf_scatter_strength = 0.16
	anime_bikini_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

	var tex_b = _load_texture_safe("res://presentation/assets/models/anime_character_bikini.png")
	if tex_b:
		anime_bikini_mat.albedo_texture = tex_b
		anime_bikini_mat.albedo_color = Color.WHITE
	var nrm_b = _load_texture_safe("res://presentation/assets/models/anime_character_bikini_normal.png")
	if nrm_b:
		anime_bikini_mat.normal_enabled = true
		anime_bikini_mat.normal_scale = 1.0
		anime_bikini_mat.normal_texture = nrm_b

	# 2. Custom Nude Material
	anime_custom_mat = base_mat.duplicate() as StandardMaterial3D
	anime_custom_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	anime_custom_mat.next_pass = null
	anime_custom_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	anime_custom_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	anime_custom_mat.roughness = 0.62
	anime_custom_mat.metallic = 0.0
	anime_custom_mat.metallic_specular = 0.35
	anime_custom_mat.albedo_color = Color(1.0, 0.98, 0.96, 1.0)
	anime_custom_mat.subsurf_scatter_enabled = true
	anime_custom_mat.subsurf_scatter_strength = 0.16

	var tex_c = _load_texture_safe("res://presentation/assets/models/anime_character_custom.png")
	if tex_c:
		anime_custom_mat.albedo_texture = tex_c
		anime_custom_mat.albedo_color = Color.WHITE
	var nrm_c = _load_texture_safe("res://presentation/assets/models/anime_character_custom_normal.png")
	if nrm_c:
		anime_custom_mat.normal_enabled = true
		anime_custom_mat.normal_scale = 1.0
		anime_custom_mat.normal_texture = nrm_c

func _init_douyin_materials() -> void:
	var douyin_skin_mat: StandardMaterial3D = StandardMaterial3D.new()
	douyin_skin_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	douyin_skin_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	douyin_skin_mat.roughness = 0.62
	douyin_skin_mat.metallic = 0.0
	douyin_skin_mat.metallic_specular = 0.35
	douyin_skin_mat.albedo_color = Color(0.937, 0.808, 0.686, 1.0)
	douyin_skin_mat.subsurf_scatter_enabled = true
	douyin_skin_mat.subsurf_scatter_strength = 0.16

	var tex_bikini = _load_texture_safe("res://presentation/assets/models/asian_beauty/douyin_skin_bikini.png")
	if not tex_bikini:
		tex_bikini = _load_texture_safe("res://presentation/assets/models/douyin_asian_character_bikini.png")
	var tex_nude = _load_texture_safe("res://presentation/assets/models/asian_beauty/douyin_skin_nude.png")
	if not tex_nude:
		tex_nude = _load_texture_safe("res://presentation/assets/models/douyin_asian_character_nude.png")
	var tex_nrm_bikini = _load_texture_safe("res://presentation/assets/models/asian_beauty/douyin_skin_bikini_normal.png")
	if not tex_nrm_bikini:
		tex_nrm_bikini = _load_texture_safe("res://presentation/assets/models/douyin_asian_character_bikini_normal.png")
	var tex_nrm_nude = _load_texture_safe("res://presentation/assets/models/asian_beauty/douyin_skin_nude_normal.png")
	if not tex_nrm_nude:
		tex_nrm_nude = _load_texture_safe("res://presentation/assets/models/douyin_asian_character_nude_normal.png")

	douyin_bikini_mat = douyin_skin_mat.duplicate() as StandardMaterial3D
	if tex_bikini:
		douyin_bikini_mat.albedo_texture = tex_bikini
		douyin_bikini_mat.albedo_color = Color.WHITE
	if tex_nrm_bikini:
		douyin_bikini_mat.normal_enabled = true
		douyin_bikini_mat.normal_scale = 1.0
		douyin_bikini_mat.normal_texture = tex_nrm_bikini

	douyin_nude_mat = douyin_skin_mat.duplicate() as StandardMaterial3D
	if tex_nude:
		douyin_nude_mat.albedo_texture = tex_nude
		douyin_nude_mat.albedo_color = Color.WHITE
	if tex_nrm_nude:
		douyin_nude_mat.normal_enabled = true
		douyin_nude_mat.normal_scale = 1.0
		douyin_nude_mat.normal_texture = tex_nrm_nude

# =========================================================================
# OUTFIT CONTROL — ANIME HEROINE
# =========================================================================

func cycle_anime_outfit() -> int:
	var next_mode: int = (anime_outfit_mode + 1) % 3
	set_anime_outfit_mode(next_mode)
	return anime_outfit_mode

func set_anime_outfit_mode(mode: int) -> void:
	anime_outfit_mode = mode
	var is_bikini: bool = (mode != AnimeOutfitMode.STANDARD)

	if on_weapon_visibility_changed.is_valid():
		on_weapon_visibility_changed.call(mode == AnimeOutfitMode.STANDARD)

	if not anime_body_mesh_instance or anime_default_materials.size() < 4:
		outfit_changed.emit("anime_outfit", _get_anime_outfit_name(mode), is_bikini)
		return

	if not anime_bikini_mat:
		_init_anime_materials()

	match mode:
		AnimeOutfitMode.STANDARD:
			if anime_default_body_mesh and anime_body_mesh_instance.mesh != anime_default_body_mesh:
				anime_body_mesh_instance.mesh = anime_default_body_mesh
			for s in range(min(anime_body_mesh_instance.mesh.get_surface_count(), anime_default_materials.size())):
				anime_body_mesh_instance.set_surface_override_material(s, anime_default_materials[s])
			if on_face_material_requested.is_valid():
				on_face_material_requested.call(null)
			_reset_anime_bones()

		AnimeOutfitMode.BIKINI:
			if not anime_bikini_body_mesh:
				_build_anime_bikini_body_mesh()
			if anime_bikini_body_mesh:
				anime_body_mesh_instance.mesh = anime_bikini_body_mesh
			if anime_bikini_mat:
				anime_body_mesh_instance.set_surface_override_material(0, anime_bikini_mat)
			for s in range(1, anime_body_mesh_instance.get_surface_override_material_count()):
				anime_body_mesh_instance.set_surface_override_material(s, null)
			_apply_anime_bikini_bones()

		AnimeOutfitMode.CUSTOM:
			if not anime_nude_body_mesh:
				_build_anime_nude_body_mesh()
			if anime_nude_body_mesh:
				anime_body_mesh_instance.mesh = anime_nude_body_mesh
			var target_mat = anime_custom_mat if anime_custom_mat else anime_bikini_mat
			if target_mat:
				anime_body_mesh_instance.set_surface_override_material(0, target_mat)
			for s in range(1, anime_body_mesh_instance.get_surface_override_material_count()):
				anime_body_mesh_instance.set_surface_override_material(s, null)
			_apply_anime_nude_bones()

	outfit_changed.emit("anime_outfit", _get_anime_outfit_name(mode), is_bikini)

func _get_anime_outfit_name(mode: int) -> String:
	match mode:
		AnimeOutfitMode.STANDARD:
			return "Trang Phục: Standard Adventurer"
		AnimeOutfitMode.BIKINI:
			return "Trang Phục: Summer Micro-Bikini"
		AnimeOutfitMode.CUSTOM:
			return "Trang Phục: Nude Custom Skin"
		_:
			return "Trang Phục Chuẩn"

func _reset_anime_bones() -> void:
	if not anime_skeleton:
		return
	if anime_hips_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_hips_bone, Vector3.ONE)
	if anime_spine_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_spine_bone, Vector3.ONE)
	if anime_shoulder_l_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_shoulder_l_bone, Vector3.ONE)
		anime_skeleton.set_bone_pose_position(anime_shoulder_l_bone, anime_skeleton.get_bone_rest(anime_shoulder_l_bone).origin)
	if anime_shoulder_r_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_shoulder_r_bone, Vector3.ONE)
		anime_skeleton.set_bone_pose_position(anime_shoulder_r_bone, anime_skeleton.get_bone_rest(anime_shoulder_r_bone).origin)
	if anime_bust_l1_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_bust_l1_bone, Vector3.ONE)
		anime_skeleton.set_bone_pose_position(anime_bust_l1_bone, anime_skeleton.get_bone_rest(anime_bust_l1_bone).origin)
	if anime_bust_l2_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_bust_l2_bone, Vector3.ONE)
	if anime_bust_r1_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_bust_r1_bone, Vector3.ONE)
		anime_skeleton.set_bone_pose_position(anime_bust_r1_bone, anime_skeleton.get_bone_rest(anime_bust_r1_bone).origin)
	if anime_bust_r2_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_bust_r2_bone, Vector3.ONE)

func _apply_anime_bikini_bones() -> void:
	if not anime_skeleton:
		return
	if anime_shoulder_l_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_shoulder_l_bone, Vector3(1.14, 1.05, 1.08))
		var rest_sh_l = anime_skeleton.get_bone_rest(anime_shoulder_l_bone).origin
		anime_skeleton.set_bone_pose_position(anime_shoulder_l_bone, rest_sh_l + Vector3(0.012, 0.0, 0.0))
	if anime_shoulder_r_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_shoulder_r_bone, Vector3(1.14, 1.05, 1.08))
		var rest_sh_r = anime_skeleton.get_bone_rest(anime_shoulder_r_bone).origin
		anime_skeleton.set_bone_pose_position(anime_shoulder_r_bone, rest_sh_r + Vector3(-0.012, 0.0, 0.0))
	if anime_hips_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_hips_bone, Vector3(1.20, 1.03, 1.30))
	if anime_spine_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_spine_bone, Vector3(0.80, 1.0, 0.77))
	if anime_bust_l1_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_bust_l1_bone, Vector3(1.18, 1.14, 1.22))
		var rest_pos_l = anime_skeleton.get_bone_rest(anime_bust_l1_bone).origin
		anime_skeleton.set_bone_pose_position(anime_bust_l1_bone, rest_pos_l + Vector3(-0.003, 0.006, 0.004))
	if anime_bust_r1_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_bust_r1_bone, Vector3(1.18, 1.14, 1.22))
		var rest_pos_r = anime_skeleton.get_bone_rest(anime_bust_r1_bone).origin
		anime_skeleton.set_bone_pose_position(anime_bust_r1_bone, rest_pos_r + Vector3(0.003, 0.006, 0.004))

func _apply_anime_nude_bones() -> void:
	if not anime_skeleton:
		return
	if anime_shoulder_l_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_shoulder_l_bone, Vector3(1.12, 1.05, 1.06))
		var rest_sh_l = anime_skeleton.get_bone_rest(anime_shoulder_l_bone).origin
		anime_skeleton.set_bone_pose_position(anime_shoulder_l_bone, rest_sh_l + Vector3(0.016, 0.008, 0.0))
	if anime_shoulder_r_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_shoulder_r_bone, Vector3(1.12, 1.05, 1.06))
		var rest_sh_r = anime_skeleton.get_bone_rest(anime_shoulder_r_bone).origin
		anime_skeleton.set_bone_pose_position(anime_shoulder_r_bone, rest_sh_r + Vector3(-0.016, 0.008, 0.0))
	if anime_hips_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_hips_bone, Vector3(1.08, 1.01, 1.10))
	if anime_spine_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_spine_bone, Vector3(0.85, 1.0, 0.82))
	if anime_bust_l1_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_bust_l1_bone, Vector3(1.02, 1.02, 1.04))
		var rest_pos_l = anime_skeleton.get_bone_rest(anime_bust_l1_bone).origin
		anime_skeleton.set_bone_pose_position(anime_bust_l1_bone, rest_pos_l + Vector3(0.001, 0.002, 0.002))
	if anime_bust_r1_bone != -1:
		anime_skeleton.set_bone_pose_scale(anime_bust_r1_bone, Vector3(1.02, 1.02, 1.04))
		var rest_pos_r = anime_skeleton.get_bone_rest(anime_bust_r1_bone).origin
		anime_skeleton.set_bone_pose_position(anime_bust_r1_bone, rest_pos_r + Vector3(-0.001, 0.002, 0.002))

# =========================================================================
# OUTFIT CONTROL — DOUYIN BEAUTY
# =========================================================================

func cycle_douyin_outfit() -> int:
	var next_mode: int = (douyin_outfit_mode + 1) % 2
	set_douyin_outfit_mode(next_mode)
	return douyin_outfit_mode

func set_douyin_outfit_mode(mode: int) -> void:
	douyin_outfit_mode = mode
	if not douyin_body_mesh_instance:
		return

	if douyin_bra_root:
		douyin_bra_root.visible = false

	match mode:
		DouyinOutfitMode.BIKINI:
			if not douyin_bikini_body_mesh:
				_build_douyin_bikini_body_mesh()
			if douyin_bikini_body_mesh:
				douyin_body_mesh_instance.mesh = douyin_bikini_body_mesh
			if douyin_bikini_mat:
				douyin_body_mesh_instance.set_surface_override_material(0, douyin_bikini_mat)
			if douyin_skeleton:
				if douyin_bust_l1_bone != -1:
					douyin_skeleton.set_bone_pose_scale(douyin_bust_l1_bone, Vector3(1.02, 1.02, 1.04))
					var lp = douyin_skeleton.get_bone_rest(douyin_bust_l1_bone).origin
					douyin_skeleton.set_bone_pose_position(douyin_bust_l1_bone, lp + Vector3(0.0, 0.003, 0.003))
					douyin_skeleton.set_bone_pose_rotation(douyin_bust_l1_bone, Quaternion.IDENTITY)
				if douyin_bust_r1_bone != -1:
					douyin_skeleton.set_bone_pose_scale(douyin_bust_r1_bone, Vector3(1.02, 1.02, 1.04))
					var rp = douyin_skeleton.get_bone_rest(douyin_bust_r1_bone).origin
					douyin_skeleton.set_bone_pose_position(douyin_bust_r1_bone, rp + Vector3(0.0, 0.003, 0.003))
					douyin_skeleton.set_bone_pose_rotation(douyin_bust_r1_bone, Quaternion.IDENTITY)

		DouyinOutfitMode.NUDE:
			if not douyin_nude_body_mesh:
				_build_douyin_nude_body_mesh()
			if douyin_nude_body_mesh:
				douyin_body_mesh_instance.mesh = douyin_nude_body_mesh
			if douyin_nude_mat:
				douyin_body_mesh_instance.set_surface_override_material(0, douyin_nude_mat)
			if douyin_skeleton:
				if douyin_bust_l1_bone != -1:
					douyin_skeleton.set_bone_pose_scale(douyin_bust_l1_bone, Vector3(0.98, 0.98, 1.00))
					var lp = douyin_skeleton.get_bone_rest(douyin_bust_l1_bone).origin
					douyin_skeleton.set_bone_pose_position(douyin_bust_l1_bone, lp + Vector3(0.001, 0.002, 0.001))
					douyin_skeleton.set_bone_pose_rotation(douyin_bust_l1_bone, Quaternion.IDENTITY)
				if douyin_bust_r1_bone != -1:
					douyin_skeleton.set_bone_pose_scale(douyin_bust_r1_bone, Vector3(0.98, 0.98, 1.00))
					var rp = douyin_skeleton.get_bone_rest(douyin_bust_r1_bone).origin
					douyin_skeleton.set_bone_pose_position(douyin_bust_r1_bone, rp + Vector3(-0.001, 0.002, 0.001))
					douyin_skeleton.set_bone_pose_rotation(douyin_bust_r1_bone, Quaternion.IDENTITY)

	outfit_changed.emit("douyin_outfit", "Bikini Trắng 👙" if mode == 0 else "Nude ✨", true)

# =========================================================================
# PROCEDURAL MESH SCULPTING (ENCAPSULATED)
# =========================================================================

func _sculpt_body_vertices(verts: PackedVector3Array, norms: PackedVector3Array, uvs: PackedVector2Array, is_nude: bool, is_douyin: bool = false) -> PackedVector3Array:
	var new_verts: PackedVector3Array = verts.duplicate()
	var uv_l: Vector2 = Vector2(1154.0 / 2048.0, 530.0 / 2048.0) if is_douyin else Vector2(1146.0 / 2048.0, 528.0 / 2048.0)
	var uv_r: Vector2 = Vector2(894.0 / 2048.0, 530.0 / 2048.0) if is_douyin else Vector2(902.0 / 2048.0, 528.0 / 2048.0)
	var radius_uv: float = 0.0080

	var bust_y_bot: float = 1.08
	var bust_y_top: float = 1.26
	var bust_y_range: float = bust_y_top - bust_y_bot

	for i in range(verts.size()):
		var v: Vector3 = verts[i]
		var uv: Vector2 = uvs[i]

		# 1. 3D Butt Crack Groove & Lifted Round Butt Cheeks
		if v.y >= 0.79 and v.y <= 0.94 and v.z < -0.015:
			if abs(v.x) < 0.025:
				var butt_factor: float = cos(abs(v.x) / 0.025 * PI * 0.5)
				var y_falloff: float = sin((v.y - 0.79) / 0.15 * PI)
				new_verts[i].z += butt_factor * y_falloff * 0.008
			elif abs(v.x) >= 0.035 and abs(v.x) <= 0.14:
				var cheek_factor: float = sin((abs(v.x) - 0.035) / 0.105 * PI)
				var y_cheek: float = sin((v.y - 0.79) / 0.15 * PI)
				new_verts[i].z -= cheek_factor * y_cheek * 0.012
				new_verts[i].y += y_cheek * 0.004

		# 2. 3D Groin Cleft (Natural Pubic Crease)
		if is_nude and v.y >= 0.73 and v.y <= 0.82 and v.z > 0.005 and v.z < 0.065:
			if abs(v.x) < 0.018:
				var cleft_factor: float = cos(abs(v.x) / 0.018 * PI * 0.5)
				var cleft_y: float = sin((v.y - 0.73) / 0.09 * PI)
				new_verts[i].z -= cleft_factor * cleft_y * 0.0045
			elif abs(v.x) >= 0.018 and abs(v.x) <= 0.045:
				var labia_factor: float = sin((abs(v.x) - 0.018) / 0.027 * PI)
				var labia_y: float = sin((v.y - 0.73) / 0.09 * PI)
				new_verts[i].z += labia_factor * labia_y * 0.0035

		# 3. 3D Protruding Nipple Sculpt
		if is_nude:
			var d_l = uv.distance_to(uv_l)
			var d_r = uv.distance_to(uv_r)
			var is_near_nipple = (d_l < radius_uv or d_r < radius_uv)
			if is_near_nipple and v.z > 0.05 and v.y >= 1.10 and v.y <= 1.25:
				var dist = min(d_l, d_r)
				var t = clamp(1.0 - (dist / radius_uv), 0.0, 1.0)
				var bud_h = 0.0035 if is_douyin else 0.0042
				var areola_h = 0.0018 if is_douyin else 0.0022
				var profile = areola_h * sin(t * PI * 0.5)
				if t > 0.40:
					var bud_t = (t - 0.40) / 0.60
					profile += bud_h * sin(bud_t * PI * 0.5)
				var norm = norms[i] if norms.size() > i else Vector3(0, 0, 1)
				new_verts[i] += norm * profile

		# 4. Douyin Silhouette Sculpt
		if is_douyin:
			if v.y >= 0.93 and v.y <= 1.07 and abs(v.x) <= 0.168:
				var waist_t: float = sin((v.y - 0.93) / 0.14 * PI)
				new_verts[i].x *= (1.0 - 0.085 * waist_t)
				if v.z > 0.02:
					new_verts[i].z -= 0.004 * waist_t
			if v.y >= 0.76 and v.y <= 0.93 and abs(v.x) <= 0.18:
				var hip_t: float = sin((v.y - 0.76) / 0.17 * PI)
				new_verts[i].x += sign(v.x) * (0.0065 * hip_t)

		# 5. Natural Clavicle & Ribcage definition
		if v.y >= 1.26 and v.y <= 1.33 and v.z > 0.02:
			if abs(v.x) >= 0.035 and abs(v.x) <= 0.125:
				var col_f = sin((abs(v.x) - 0.035) / 0.090 * PI) * sin((v.y - 1.26) / 0.07 * PI)
				new_verts[i].z += col_f * 0.0032
				new_verts[i].y += col_f * 0.0012

	return new_verts

func _build_anime_bikini_body_mesh() -> void:
	if not anime_default_body_mesh:
		return
	var arrays = anime_default_body_mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var new_verts = _sculpt_body_vertices(verts, norms, uvs, false, false)
	arrays[Mesh.ARRAY_VERTEX] = new_verts
	var bikini = ArrayMesh.new()
	bikini.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	anime_bikini_body_mesh = bikini

func _build_anime_nude_body_mesh() -> void:
	if not anime_default_body_mesh:
		return
	var arrays = anime_default_body_mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var new_verts = _sculpt_body_vertices(verts, norms, uvs, true, false)
	arrays[Mesh.ARRAY_VERTEX] = new_verts
	var nude = ArrayMesh.new()
	nude.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	anime_nude_body_mesh = nude

func _build_douyin_bikini_body_mesh() -> void:
	if not douyin_default_body_mesh:
		return
	var arrays = douyin_default_body_mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var new_verts = _sculpt_body_vertices(verts, norms, uvs, false, true)
	arrays[Mesh.ARRAY_VERTEX] = new_verts
	var bikini = ArrayMesh.new()
	bikini.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	douyin_bikini_body_mesh = bikini

func _build_douyin_nude_body_mesh() -> void:
	if not douyin_default_body_mesh:
		return
	var arrays = douyin_default_body_mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var new_verts = _sculpt_body_vertices(verts, norms, uvs, true, true)
	arrays[Mesh.ARRAY_VERTEX] = new_verts
	var nude = ArrayMesh.new()
	nude.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	douyin_nude_body_mesh = nude
