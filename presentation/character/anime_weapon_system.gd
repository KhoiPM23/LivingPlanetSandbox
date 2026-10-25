@tool
class_name AnimeWeaponSystem
extends Node3D

## Living Planet Sandbox — High-Fidelity Anime Weapon & Combat Stance System
## Features:
## - "Thanh Kiếm Gió Phong Linh" (Silverwind Anemo Blade): slender Japanese/Genshin-style sword
## - Dual-socket bone mounting: Slung across back (Sheathed) vs Held in right hand (Combat Stance)
## - 3-Hit Anemo blade slash combo with crescent slash trail VFX and whoosh sound synthesis
## - Interaction with training dummy & destructibles

signal weapon_state_changed(is_drawn: bool)
signal attack_performed(combo_index: int, damage: int)
signal hit_stop_triggered(duration: float)
signal hit_connected(target_name: String, hit_pos: Vector3, damage: int)

enum WeaponState {
	SHEATHED = 0,
	DRAWN = 1
}

var _skeleton: Skeleton3D = null
var _animator: RefCounted = null # AnimeCharacterAnimator

# Sockets
var _back_attachment: BoneAttachment3D = null
var _hand_attachment: BoneAttachment3D = null

# Visual nodes
var _scabbard_mesh: Node3D = null
var _blade_mesh: Node3D = null
var _slash_particles: GPUParticles3D = null
var _slash_arc_mesh: MeshInstance3D = null
var _slash_arc_timer: float = 0.0
var _audio_emitter: AudioStreamPlayer3D = null

# State
var is_drawn: bool = false
var _combo_stage: int = 0
var _combo_timer: float = 0.0
var _attack_cooldown: float = 0.0

# Procedural audio cache
static var _sword_draw_wav: AudioStreamWAV = null
static var _sword_sheathe_wav: AudioStreamWAV = null
static var _sword_slash_wavs: Array[AudioStreamWAV] = []

func setup(skeleton: Skeleton3D, animator: RefCounted = null) -> void:
	_skeleton = skeleton
	_animator = animator
	_init_audio_cache()
	_build_sockets_and_meshes()

func _init_audio_cache() -> void:
	if _sword_draw_wav == null:
		_sword_draw_wav = _generate_metal_ring_wav(0.28, 22050, 1450.0)
		_sword_sheathe_wav = _generate_metal_ring_wav(0.22, 22050, 850.0)
		_sword_slash_wavs = [
			_generate_sword_slash_wav(0.26, 22050, 950.0, 350.0),
			_generate_sword_slash_wav(0.28, 22050, 1150.0, 420.0),
			_generate_sword_slash_wav(0.34, 22050, 1350.0, 280.0)
		]

func _build_sockets_and_meshes() -> void:
	if not _skeleton:
		return

	# 1. Back Socket (Chest / Upper Spine)
	var chest_idx: int = _skeleton.find_bone("J_Bip_C_Chest")
	if chest_idx >= 0:
		_back_attachment = BoneAttachment3D.new()
		_back_attachment.name = "BackWeaponSocket"
		_back_attachment.bone_name = "J_Bip_C_Chest"
		_skeleton.add_child(_back_attachment)

	# 2. Hand Socket (Right Hand)
	var hand_idx: int = _skeleton.find_bone("J_Bip_R_Hand")
	if hand_idx >= 0:
		_hand_attachment = BoneAttachment3D.new()
		_hand_attachment.name = "RightHandWeaponSocket"
		_hand_attachment.bone_name = "J_Bip_R_Hand"
		_skeleton.add_child(_hand_attachment)

	# 3. Create Scabbard (Saya)
	_scabbard_mesh = _create_scabbard_node()
	if _back_attachment:
		_back_attachment.add_child(_scabbard_mesh)
		# Position angled across back from right shoulder to lower left hip
		_scabbard_mesh.position = Vector3(0.08, 0.05, -0.16)
		_scabbard_mesh.rotation = Vector3(deg_to_rad(-22.0), deg_to_rad(15.0), deg_to_rad(48.0))

	# 4. Create Blade (Katana)
	_blade_mesh = _create_blade_node()

	# 5. Build Slash Arc Particles and Crescent Ribbon Mesh
	_build_slash_particles()
	_build_slash_arc_mesh()

	# 6. Audio emitter
	_audio_emitter = AudioStreamPlayer3D.new()
	_audio_emitter.name = "WeaponAudioEmitter"
	_audio_emitter.unit_size = 3.5
	_audio_emitter.max_distance = 25.0
	add_child(_audio_emitter)

	# Start sheathed on back
	set_drawn(false)

func _create_blade_node() -> Node3D:
	var blade_root: Node3D = Node3D.new()
	blade_root.name = "SilverwindAnemoBlade"

	# Steel Blade Material
	var steel_mat: StandardMaterial3D = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.92, 0.95, 0.98) # Polished chrome silver
	steel_mat.metallic = 0.95
	steel_mat.roughness = 0.18
	steel_mat.emission_enabled = true
	steel_mat.emission = Color(0.18, 0.88, 0.82) # Cyan Anemo rune glow
	steel_mat.emission_energy_multiplier = 0.85

	# Gold/Brass Fittings Material
	var gold_mat: StandardMaterial3D = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.78, 0.25)
	gold_mat.metallic = 0.85
	gold_mat.roughness = 0.32

	# Navy Grip Material
	var grip_mat: StandardMaterial3D = StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.14, 0.16, 0.24)
	grip_mat.roughness = 0.75

	# Emerald Gem Material
	var gem_mat: StandardMaterial3D = StandardMaterial3D.new()
	gem_mat.albedo_color = Color(0.15, 0.92, 0.65)
	gem_mat.emission_enabled = true
	gem_mat.emission = Color(0.12, 0.85, 0.58)
	gem_mat.emission_energy_multiplier = 1.6

	# Blade steel geometry
	var blade_mesh: BoxMesh = BoxMesh.new()
	blade_mesh.size = Vector3(0.032, 0.92, 0.008)
	var blade_inst: MeshInstance3D = MeshInstance3D.new()
	blade_inst.name = "BladeMesh"
	blade_inst.mesh = blade_mesh
	blade_inst.material_override = steel_mat
	blade_inst.position = Vector3(0.0, 0.52, 0.0)
	blade_root.add_child(blade_inst)

	# Tsuba (Guard)
	var guard_mesh: BoxMesh = BoxMesh.new()
	guard_mesh.size = Vector3(0.10, 0.016, 0.075)
	var guard_inst: MeshInstance3D = MeshInstance3D.new()
	guard_inst.name = "TsubaGuard"
	guard_inst.mesh = guard_mesh
	guard_inst.material_override = gold_mat
	guard_inst.position = Vector3(0.0, 0.06, 0.0)
	blade_root.add_child(guard_inst)

	# Guard Center Emerald
	var gem_mesh: SphereMesh = SphereMesh.new()
	gem_mesh.radius = 0.02
	gem_mesh.height = 0.04
	var gem_inst: MeshInstance3D = MeshInstance3D.new()
	gem_inst.name = "AnemoGem"
	gem_inst.mesh = gem_mesh
	gem_inst.material_override = gem_mat
	gem_inst.position = Vector3(0.0, 0.06, 0.038)
	blade_root.add_child(gem_inst)

	# Tsuka (Handle / Grip)
	var grip_mesh: CylinderMesh = CylinderMesh.new()
	grip_mesh.top_radius = 0.022
	grip_mesh.bottom_radius = 0.024
	grip_mesh.height = 0.26
	var grip_inst: MeshInstance3D = MeshInstance3D.new()
	grip_inst.name = "TsukaGrip"
	grip_inst.mesh = grip_mesh
	grip_inst.material_override = grip_mat
	grip_inst.position = Vector3(0.0, -0.07, 0.0)
	blade_root.add_child(grip_inst)

	# Kashira (Pommel)
	var pommel_mesh: BoxMesh = BoxMesh.new()
	pommel_mesh.size = Vector3(0.045, 0.025, 0.045)
	var pommel_inst: MeshInstance3D = MeshInstance3D.new()
	pommel_inst.name = "KashiraPommel"
	pommel_inst.mesh = pommel_mesh
	pommel_inst.material_override = gold_mat
	pommel_inst.position = Vector3(0.0, -0.20, 0.0)
	blade_root.add_child(pommel_inst)

	return blade_root

func _create_scabbard_node() -> Node3D:
	var scabbard_root: Node3D = Node3D.new()
	scabbard_root.name = "SilverwindScabbard"

	var saya_mat: StandardMaterial3D = StandardMaterial3D.new()
	saya_mat.albedo_color = Color(0.12, 0.12, 0.18) # Deep lacquer indigo
	saya_mat.roughness = 0.35

	var gold_mat: StandardMaterial3D = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.78, 0.25)
	gold_mat.metallic = 0.85
	gold_mat.roughness = 0.35

	# Scabbard body
	var saya_mesh: BoxMesh = BoxMesh.new()
	saya_mesh.size = Vector3(0.045, 0.95, 0.022)
	var saya_inst: MeshInstance3D = MeshInstance3D.new()
	saya_inst.mesh = saya_mesh
	saya_inst.material_override = saya_mat
	saya_inst.position = Vector3(0.0, 0.48, 0.0)
	scabbard_root.add_child(saya_inst)

	# Gold Collar (Koiguchi)
	var collar_mesh: BoxMesh = BoxMesh.new()
	collar_mesh.size = Vector3(0.052, 0.035, 0.028)
	var collar_inst: MeshInstance3D = MeshInstance3D.new()
	collar_inst.mesh = collar_mesh
	collar_inst.material_override = gold_mat
	collar_inst.position = Vector3(0.0, 0.95, 0.0)
	scabbard_root.add_child(collar_inst)

	return scabbard_root

func _build_slash_particles() -> void:
	_slash_particles = GPUParticles3D.new()
	_slash_particles.name = "AnemoSlashTrail"
	_slash_particles.amount = 14
	_slash_particles.lifetime = 0.25
	_slash_particles.emitting = false
	_slash_particles.one_shot = true

	var pp_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pp_mat.direction = Vector3(0.0, 0.0, 1.0)
	pp_mat.spread = 25.0
	pp_mat.initial_velocity_min = 2.0
	pp_mat.initial_velocity_max = 4.5
	pp_mat.gravity = Vector3(0.0, -1.0, 0.0)
	pp_mat.scale_min = 0.12
	pp_mat.scale_max = 0.35
	pp_mat.color = Color(0.25, 0.95, 0.85, 0.85)
	_slash_particles.process_material = pp_mat

	var p_mesh: RibbonTrailMesh = RibbonTrailMesh.new()
	p_mesh.size = 0.18
	var p_mat: StandardMaterial3D = StandardMaterial3D.new()
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.albedo_color = Color(0.35, 1.0, 0.90, 0.70)
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mesh.material = p_mat
	_slash_particles.draw_pass_1 = p_mesh
	add_child(_slash_particles)

func _build_slash_arc_mesh() -> void:
	if _slash_arc_mesh:
		return
	_slash_arc_mesh = MeshInstance3D.new()
	_slash_arc_mesh.name = "AnemoCrescentArcMesh"
	_slash_arc_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.35, 1.0, 0.92, 0.88)

	_slash_arc_mesh.material_override = mat
	_slash_arc_mesh.mesh = _generate_crescent_ribbon_mesh(1.35, 0.36, deg_to_rad(130.0))
	_slash_arc_mesh.visible = false
	add_child(_slash_arc_mesh)

func _generate_crescent_ribbon_mesh(radius: float, width: float, angle_span: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = 24
	var half_span: float = angle_span * 0.5

	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle: float = lerpf(-half_span, half_span, t)
		var cos_a: float = cos(angle)
		var sin_a: float = sin(angle)

		# Edge taper at the crescent tips
		var tip_factor: float = sin(t * PI)
		var eff_width: float = width * (0.2 + 0.8 * tip_factor)
		var r_inner: float = radius - eff_width * 0.5
		var r_outer: float = radius + eff_width * 0.5

		var v_inner: Vector3 = Vector3(cos_a * r_inner, 0.0, sin_a * r_inner)
		var v_outer: Vector3 = Vector3(cos_a * r_outer, 0.0, sin_a * r_outer)

		var col: Color = Color(1.0, 1.0, 1.0, tip_factor)
		st.set_color(col)
		st.set_uv(Vector2(t, 0.0))
		st.add_vertex(v_inner)

		st.set_color(col)
		st.set_uv(Vector2(t, 1.0))
		st.add_vertex(v_outer)

	for i in range(segments):
		var i0: int = i * 2
		var i1: int = i * 2 + 1
		var i2: int = (i + 1) * 2
		var i3: int = (i + 1) * 2 + 1

		st.add_index(i0)
		st.add_index(i1)
		st.add_index(i2)

		st.add_index(i2)
		st.add_index(i1)
		st.add_index(i3)

	return st.commit()

func set_drawn(drawn: bool) -> void:
	is_drawn = drawn
	if not _blade_mesh:
		return

	if _blade_mesh.get_parent():
		_blade_mesh.get_parent().remove_child(_blade_mesh)

	if is_drawn:
		# Mount into Right Hand Socket
		if _hand_attachment:
			_hand_attachment.add_child(_blade_mesh)
			# Hand socket alignment: grip rests securely inside the curled palm
			# Blade points forward along the striking trajectory
			_blade_mesh.position = Vector3(-0.035, 0.015, 0.01)
			_blade_mesh.rotation = Vector3(deg_to_rad(-120.0), deg_to_rad(135.0), deg_to_rad(85.0))
		_play_sound(_sword_draw_wav, -12.0)
	else:
		# Mount into Back Socket (Inside Scabbard)
		if _back_attachment:
			_back_attachment.add_child(_blade_mesh)
			_blade_mesh.position = Vector3(0.08, 0.05, -0.16)
			_blade_mesh.rotation = Vector3(deg_to_rad(-22.0), deg_to_rad(15.0), deg_to_rad(48.0))
		_play_sound(_sword_sheathe_wav, -14.0)

	if _animator and _animator.has_method("set_combat_stance"):
		_animator.set_combat_stance(is_drawn)

	weapon_state_changed.emit(is_drawn)

func toggle_drawn() -> bool:
	set_drawn(not is_drawn)
	return is_drawn

func draw_weapon() -> void:
	set_drawn(true)

func holster_weapon() -> void:
	set_drawn(false)

func trigger_attack() -> bool:
	if _attack_cooldown > 0.0:
		return false

	# Automatically unsheathe if attacking while sheathed
	if not is_drawn:
		set_drawn(true)
		_attack_cooldown = 0.22
		return true

	# Progress combo
	if _combo_timer > 0.0:
		_combo_stage = (_combo_stage + 1) % 3
	else:
		_combo_stage = 0

	_combo_timer = 0.90 # 900ms combo continuation window
	_attack_cooldown = 0.32

	var damages: Array[int] = [45, 60, 95]
	var dmg: int = damages[_combo_stage]

	# Play slash sound
	if _combo_stage < _sword_slash_wavs.size():
		_play_sound(_sword_slash_wavs[_combo_stage], -11.0)

	# Trigger slash particles
	if _slash_particles:
		if is_inside_tree():
			_slash_particles.global_position = global_position + Vector3(0.0, 1.1, 0.0)
		else:
			_slash_particles.position = position + Vector3(0.0, 1.1, 0.0)
		_slash_particles.restart()

	# Activate dynamic crescent slash arc ribbon
	if _slash_arc_mesh:
		_slash_arc_mesh.visible = true
		_slash_arc_timer = 0.24
		_slash_arc_mesh.position = Vector3(0.0, 1.05, 0.0)
		match _combo_stage:
			0: # Horizontal Cleave
				_slash_arc_mesh.rotation = Vector3(deg_to_rad(-10.0), deg_to_rad(25.0), deg_to_rad(5.0))
				_slash_arc_mesh.scale = Vector3(1.0, 1.0, 1.0)
			1: # Rising Uppercut Slash
				_slash_arc_mesh.rotation = Vector3(deg_to_rad(35.0), deg_to_rad(40.0), deg_to_rad(-30.0))
				_slash_arc_mesh.scale = Vector3(1.15, 1.0, 1.15)
			2: # 360 Cyclone Finisher
				_slash_arc_mesh.rotation = Vector3(deg_to_rad(0.0), 0.0, deg_to_rad(0.0))
				_slash_arc_mesh.scale = Vector3(1.4, 1.0, 1.4)

	# Trigger animator attack kinematics
	if _animator and _animator.has_method("trigger_attack_anim"):
		_animator.trigger_attack_anim(_combo_stage)

	attack_performed.emit(_combo_stage, dmg)
	return true

var hit_stop_timer: float = 0.0

func trigger_hit_stop(duration: float = 0.065) -> void:
	hit_stop_timer = duration
	hit_stop_triggered.emit(duration)

func is_in_hit_stop() -> bool:
	return hit_stop_timer > 0.0

func register_hit(target_name: String, hit_pos: Vector3 = Vector3.ZERO) -> int:
	var damages: Array[int] = [45, 60, 95]
	var dmg: int = damages[_combo_stage] if _combo_stage < damages.size() else 50
	var freeze_dur: float = 0.065 if _combo_stage < 2 else 0.095
	trigger_hit_stop(freeze_dur)
	hit_connected.emit(target_name, hit_pos, dmg)
	return dmg

func update(delta: float) -> void:
	if hit_stop_timer > 0.0:
		hit_stop_timer -= delta
		return

	if _slash_arc_timer > 0.0:
		_slash_arc_timer -= delta
		if _slash_arc_timer <= 0.0:
			if _slash_arc_mesh:
				_slash_arc_mesh.visible = false
		elif _slash_arc_mesh and _slash_arc_mesh.material_override is StandardMaterial3D:
			var fade: float = clampf(_slash_arc_timer / 0.24, 0.0, 1.0)
			(_slash_arc_mesh.material_override as StandardMaterial3D).albedo_color.a = fade * 0.88

	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_stage = 0

	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

func _play_sound(wav: AudioStreamWAV, vol_db: float) -> void:
	if not _audio_emitter or wav == null or not is_inside_tree():
		return
	_audio_emitter.stream = wav
	_audio_emitter.volume_db = vol_db
	_audio_emitter.pitch_scale = randf_range(0.95, 1.05)
	_audio_emitter.play()

# =============================================================================
# SYNTHESIZERS (Metallic Ring & Sword Slashes)
# =============================================================================
static func _generate_metal_ring_wav(duration: float, rate: int, base_freq: float) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = exp(-12.0 * (t / duration))
		var chime: float = sin(t * base_freq * TAU) * 0.5 + sin(t * base_freq * 2.76 * TAU) * 0.35 + sin(t * base_freq * 5.4 * TAU) * 0.15
		var sample: float = chime * env * 0.45
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav

static func _generate_sword_slash_wav(duration: float, rate: int, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	var noise_state: float = 0.53
	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI) * 0.40
		var freq: float = lerpf(freq_start, freq_end, pow(t / duration, 1.5))
		noise_state = fmod(noise_state * 31.0 + 0.19, 1.0)
		var white: float = (noise_state * 2.0 - 1.0) * 0.4
		var tonal: float = sin(t * freq * TAU) * 0.6
		var sample: float = (tonal + white) * env
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = byte_data
	return wav
