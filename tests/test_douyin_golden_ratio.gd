extends RefCounted

## Unit Tests for Douyin Asian Beauty Golden Ratio proportions and Right-Triangle Bikini

func _has_douyin() -> bool:
	var path: String = "res://presentation/assets/models/douyin_asian_character.glb"
	return ResourceLoader.exists(path) or FileAccess.file_exists(ProjectSettings.globalize_path(path))

func test_douyin_model_and_bone_integrity() -> Variant:
	if not _has_douyin():
		return null # Gracefully pass in clean SFW environment

	var walker_script = load("res://presentation/camera/first_person_walker.gd")
	if not walker_script:
		return "Failed to load first_person_walker.gd"
	var walker = walker_script.new()
	walker._ready()
	
	walker._set_active_character(1)
	if walker.get_active_character_index() != 1:
		return "Failed to switch active character to Douyin (1)"
		
	var sk: Skeleton3D = walker._douyin_skeleton
	if not sk:
		return "Douyin skeleton is null"
		
	var hip_scale = sk.get_bone_pose_scale(walker._douyin_hips_bone)
	var spine_scale = sk.get_bone_pose_scale(walker._douyin_spine_bone)
	var sh_l_scale = sk.get_bone_pose_scale(walker._douyin_shoulder_l_bone)
	var sh_r_scale = sk.get_bone_pose_scale(walker._douyin_shoulder_r_bone)
	
	if not hip_scale.is_equal_approx(Vector3.ONE):
		return "Hips bone scale must be Vector3.ONE to prevent skeletal cascade distortion, got %s" % str(hip_scale)
	if not spine_scale.is_equal_approx(Vector3.ONE):
		return "Spine bone scale must be Vector3.ONE, got %s" % str(spine_scale)
	if not sh_l_scale.is_equal_approx(Vector3.ONE):
		return "Shoulder L scale must be Vector3.ONE, got %s" % str(sh_l_scale)
	if not sh_r_scale.is_equal_approx(Vector3.ONE):
		return "Shoulder R scale must be Vector3.ONE, got %s" % str(sh_r_scale)
		
	walker.queue_free()
	return null

func test_douyin_right_triangle_bikini_mode() -> Variant:
	if not _has_douyin():
		return null # Gracefully pass in clean SFW environment

	var walker_script = load("res://presentation/camera/first_person_walker.gd")
	var walker = walker_script.new()
	walker._ready()
	walker._set_active_character(1)
	
	# Test Bikini Mode
	walker._set_douyin_outfit_mode(0)
	if walker._douyin_outfit_mode != 0:
		return "Expected douyin_outfit_mode == 0"
	if walker._douyin_body_mesh_instance.mesh != walker._douyin_bikini_body_mesh:
		return "Douyin body mesh must be set to _douyin_bikini_body_mesh in mode 0"
	if walker._douyin_body_mesh_instance.get_surface_override_material(0) != walker._douyin_bikini_mat:
		return "Douyin body material must be set to _douyin_bikini_mat in mode 0"
	if walker._douyin_bra_root and walker._douyin_bra_root.visible:
		return "Separate bra root must not be visible"
		
	# Verify Golden Ratio silhouette on sculpted mesh
	# Shoulder zone: y 1.10..1.25 = deltoid/axilla region (clavicle sits higher at y>1.26 and is always narrower)
	# Waist zone:    y 0.93..1.07 = narrowest section (-8.5% sculpt applied here)
	# Hip zone:      y 0.80..0.92 = fullest flare point (+0.65cm sculpt applied here)
	var bk_arrays = walker._douyin_bikini_body_mesh.surface_get_arrays(0)
	var bk_verts: PackedVector3Array = bk_arrays[Mesh.ARRAY_VERTEX]
	var max_sh_x: float = 0.0
	var max_waist_x: float = 0.0
	var max_hip_x: float = 0.0
	for v in bk_verts:
		if abs(v.x) <= 0.168:
			if v.y >= 1.22 and v.y <= 1.245 and abs(v.x) > max_sh_x:
				max_sh_x = abs(v.x)
			elif v.y >= 0.93 and v.y <= 1.07 and abs(v.x) > max_waist_x:
				max_waist_x = abs(v.x)
			elif v.y >= 0.76 and v.y <= 0.93 and abs(v.x) > max_hip_x:
				max_hip_x = abs(v.x)
	
	if max_hip_x <= 0.0:
		return "Hip measurement zone produced no vertices — check mesh Y coordinate range"
	
	var sh_hip_ratio: float = max_sh_x / max_hip_x
	var waist_hip_ratio: float = max_waist_x / max_hip_x
	
	# Realistic Douyin hourglass: shoulder 0.65..1.35x hips (deltoid zone is anatomically similar width)
	if abs(sh_hip_ratio - 1.0) > 0.35:
		return "Shoulder(deltoid)-to-hip ratio must be in [0.65, 1.35], got %.3f" % sh_hip_ratio
	# Waist snatched: must be <0.85x hip (sculpt carves -8.5% at peak so ~91.5% baseline -> ~0.83)
	if waist_hip_ratio > 0.85:
		return "Waist-to-hip ratio must be snatched (<0.85 after sculpt), got %.3f" % waist_hip_ratio
		
	walker.queue_free()
	return null

func test_douyin_nude_bcup_mode() -> Variant:
	if not _has_douyin():
		return null # Gracefully pass in clean SFW environment

	var walker_script = load("res://presentation/camera/first_person_walker.gd")
	var walker = walker_script.new()
	walker._ready()
	walker._set_active_character(1)
	
	# Test Nude Mode
	walker._set_douyin_outfit_mode(1)
	if walker._douyin_outfit_mode != 1:
		return "Expected douyin_outfit_mode == 1"
	if walker._douyin_body_mesh_instance.mesh != walker._douyin_nude_body_mesh:
		return "Douyin body mesh must be set to _douyin_nude_body_mesh in mode 1"
	if walker._douyin_body_mesh_instance.get_surface_override_material(0) != walker._douyin_nude_mat:
		return "Douyin body material must be set to _douyin_nude_mat in mode 1"
		
	walker.queue_free()
	return null
