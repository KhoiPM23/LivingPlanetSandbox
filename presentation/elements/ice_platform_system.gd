class_name IcePlatformSystem
extends Node3D

## Living Planet Sandbox — Genshin/BotW-Style Cryo Ice Sheet Traversability (Block 64)
## Features:
## 1. Cryo Water Solidification: Cryo attacks freeze water into solid walkable ice platforms.
## 2. Full Collision Physics: StaticBody3D with collision shape allows player, horse, and fauna
##    to sprint across lakes without swimming.
## 3. Natural Thawing: Ice slowly melts over 18s with visual shrinking and cracking cues.
## 4. Pyro Melt Reaction: Pyro attacks immediately dissolve ice platforms with steam.
## 5. Performance Budgeted: Max 16 concurrent ice sheets, shared materials.

signal ice_formed(pos: Vector3)
signal ice_melted(pos: Vector3, is_pyro_melt: bool)

const MAX_ICE_PLATFORMS: int = 16
const DEFAULT_LIFETIME: float = 18.0
const PLATFORM_RADIUS: float = 3.2
const PLATFORM_THICKNESS: float = 0.35

# Materials (Shared)
static var _ice_mat: StandardMaterial3D = null
static var _ice_mesh: CylinderMesh = null
static var _fish_mat: StandardMaterial3D = null
static var _fish_mesh: ArrayMesh = null
static var _splash_mat: StandardMaterial3D = null
static var _splash_mesh: TorusMesh = null
static var _freeze_wav: AudioStreamWAV = null

# Active Platforms
var _active_platforms: Array[Dictionary] = []

func _init() -> void:
	name = "IcePlatformSystem"
	_init_materials()
	_init_audio()

static func _init_materials() -> void:
	if _ice_mat != null:
		return

	# Translucent crystalline ice sheet (allows player to see shadowy fish swimming below)
	_ice_mat = StandardMaterial3D.new()
	_ice_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ice_mat.albedo_color = Color(0.68, 0.88, 0.98, 0.86)
	_ice_mat.roughness = 0.06
	_ice_mat.metallic = 0.10
	_ice_mat.metallic_specular = 0.85
	_ice_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ice_mat.rim_enabled = true
	_ice_mat.rim = 0.85
	_ice_mat.rim_tint = 0.90
	_ice_mat.emission_enabled = true
	_ice_mat.emission = Color(0.35, 0.75, 0.95)
	_ice_mat.emission_energy_multiplier = 0.22

	_ice_mesh = CylinderMesh.new()
	_ice_mesh.top_radius = PLATFORM_RADIUS
	_ice_mesh.bottom_radius = PLATFORM_RADIUS * 1.05
	_ice_mesh.height = PLATFORM_THICKNESS
	_ice_mesh.radial_segments = 16
	_ice_mesh.material = _ice_mat

	# Shadowy aquatic fish swimming beneath ice
	_fish_mat = StandardMaterial3D.new()
	_fish_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fish_mat.albedo_color = Color(0.12, 0.26, 0.38, 0.82)
	_fish_mat.roughness = 0.25
	_fish_mat.metallic = 0.20

	_fish_mesh = _create_fish_mesh()

	# Water splash ripple ring on fish re-entry
	_splash_mat = StandardMaterial3D.new()
	_splash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_splash_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.75)
	_splash_mat.roughness = 0.1
	_splash_mat.emission_enabled = true
	_splash_mat.emission = Color(0.5, 0.8, 1.0)
	_splash_mat.emission_energy_multiplier = 0.3

	_splash_mesh = TorusMesh.new()
	_splash_mesh.inner_radius = 0.25
	_splash_mesh.outer_radius = 0.45
	_splash_mesh.rings = 8
	_splash_mesh.ring_segments = 6
	_splash_mesh.material = _splash_mat

static func _create_fish_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Sleek low-poly fish fuselage
	var nose: Vector3 = Vector3(0.0, 0.0, -0.42)
	var mid_l: Vector3 = Vector3(-0.08, 0.0, 0.0)
	var mid_r: Vector3 = Vector3(0.08, 0.0, 0.0)
	var mid_t: Vector3 = Vector3(0.0, 0.08, 0.0)
	var mid_b: Vector3 = Vector3(0.0, -0.06, 0.0)
	var tail: Vector3 = Vector3(0.0, 0.0, 0.38)
	var fin_t: Vector3 = Vector3(0.0, 0.16, 0.52)
	var fin_b: Vector3 = Vector3(0.0, -0.14, 0.52)

	# Forebody
	st.add_vertex(nose); st.add_vertex(mid_t); st.add_vertex(mid_l)
	st.add_vertex(nose); st.add_vertex(mid_r); st.add_vertex(mid_t)
	st.add_vertex(nose); st.add_vertex(mid_l); st.add_vertex(mid_b)
	st.add_vertex(nose); st.add_vertex(mid_b); st.add_vertex(mid_r)

	# Aftbody
	st.add_vertex(mid_t); st.add_vertex(tail); st.add_vertex(mid_l)
	st.add_vertex(mid_t); st.add_vertex(mid_r); st.add_vertex(tail)
	st.add_vertex(mid_b); st.add_vertex(mid_l); st.add_vertex(tail)
	st.add_vertex(mid_b); st.add_vertex(tail); st.add_vertex(mid_r)

	# Caudal tail fin
	st.add_vertex(tail); st.add_vertex(fin_t); st.add_vertex(fin_b)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, _fish_mat)
	return mesh

static func _init_audio() -> void:
	if _freeze_wav != null:
		return
	_freeze_wav = _generate_freeze_wav()

## Freezes water surface at given world position.
func freeze_at(world_pos: Vector3, radius: float = PLATFORM_RADIUS) -> bool:
	if _active_platforms.size() >= MAX_ICE_PLATFORMS:
		# Recycle oldest platform
		_destroy_platform(0, false)

	# Water level is ~0.0
	var ice_y: float = 0.08 # Slightly above water surface
	var spawn_pos: Vector3 = Vector3(world_pos.x, ice_y, world_pos.z)

	# 1. StaticBody3D for player/steed physical collision
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "IcePlatform_%d" % (_active_platforms.size() + 1)
	body.position = spawn_pos
	add_child(body)

	# 2. Collision Shape
	var col: CollisionShape3D = CollisionShape3D.new()
	var cyl_shape: CylinderShape3D = CylinderShape3D.new()
	cyl_shape.radius = radius
	cyl_shape.height = PLATFORM_THICKNESS
	col.shape = cyl_shape
	body.add_child(col)

	# 3. Ice Mesh
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	mesh_inst.mesh = _ice_mesh
	mesh_inst.scale = Vector3(radius / PLATFORM_RADIUS, 1.0, radius / PLATFORM_RADIUS)
	body.add_child(mesh_inst)

	# 4. Shadowy Under-Ice Fish (visible swimming beneath translucent ice)
	var fish_instances: Array[Dictionary] = []
	var fish_count: int = randi_range(2, 3)
	for f_idx in range(fish_count):
		var f_mesh: MeshInstance3D = MeshInstance3D.new()
		f_mesh.mesh = _fish_mesh
		f_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(f_mesh)
		var orbit_r: float = randf_range(0.6, radius * 0.65)
		var orbit_ang: float = randf_range(0.0, TAU)
		var orbit_spd: float = randf_range(0.8, 1.4) * (1.0 if randf() > 0.4 else -1.0)
		var f_depth: float = randf_range(-0.45, -0.65)
		fish_instances.append({
			"node": f_mesh,
			"radius": orbit_r,
			"angle": orbit_ang,
			"speed": orbit_spd,
			"depth": f_depth,
			"wiggle_phase": randf_range(0.0, TAU)
		})

	# 5. Leaping Fish at ice sheet perimeter
	var leap_fish: MeshInstance3D = MeshInstance3D.new()
	leap_fish.mesh = _fish_mesh
	leap_fish.visible = false
	leap_fish.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(leap_fish)

	var splash_ring: MeshInstance3D = MeshInstance3D.new()
	splash_ring.mesh = _splash_mesh
	splash_ring.visible = false
	body.add_child(splash_ring)

	# 6. Sound
	if _freeze_wav and is_inside_tree():
		var snd: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		snd.stream = _freeze_wav
		snd.position = spawn_pos
		snd.unit_size = 5.0
		snd.max_distance = 25.0
		add_child(snd)
		snd.play()
		snd.finished.connect(snd.queue_free)

	var platform_data: Dictionary = {
		"body": body,
		"mesh": mesh_inst,
		"col": col,
		"pos": spawn_pos,
		"base_radius": radius,
		"time_left": DEFAULT_LIFETIME,
		"max_time": DEFAULT_LIFETIME,
		"under_fish": fish_instances,
		"leap_fish": leap_fish,
		"splash_ring": splash_ring,
		"leap_timer": randf_range(2.0, 4.5),
		"is_leaping": false,
		"leap_progress": 0.0,
		"leap_start": Vector3.ZERO,
		"leap_end": Vector3.ZERO,
		"splash_timer": 0.0
	}
	_active_platforms.append(platform_data)
	ice_formed.emit(spawn_pos)
	return true

## Melts any ice platform within radius of given position (Pyro reaction or manual douse)
func melt_at(world_pos: Vector3, radius: float = 4.0) -> int:
	var melted_count: int = 0
	var i: int = _active_platforms.size() - 1
	while i >= 0:
		var p: Dictionary = _active_platforms[i]
		if p["pos"].distance_to(world_pos) <= (radius + p["base_radius"]):
			_destroy_platform(i, true)
			melted_count += 1
		i -= 1
	return melted_count

func _destroy_platform(idx: int, is_pyro: bool = false) -> void:
	if idx < 0 or idx >= _active_platforms.size():
		return
	var p: Dictionary = _active_platforms[idx]
	var pos: Vector3 = p["pos"]

	if is_instance_valid(p["body"]):
		p["body"].queue_free()

	_active_platforms.remove_at(idx)
	ice_melted.emit(pos, is_pyro)

func update_simulation(delta: float) -> void:
	var i: int = _active_platforms.size() - 1
	while i >= 0:
		var p: Dictionary = _active_platforms[i]
		p["time_left"] -= delta

		# Animate shadowy fish swimming beneath translucent ice sheet
		if p.has("under_fish"):
			for f in p["under_fish"]:
				f["angle"] += f["speed"] * delta
				f["wiggle_phase"] += delta * 9.0
				var f_node: MeshInstance3D = f["node"]
				if is_instance_valid(f_node):
					var fx: float = cos(f["angle"]) * f["radius"]
					var fz: float = sin(f["angle"]) * f["radius"]
					f_node.position = Vector3(fx, f["depth"], fz)
					# Heading tangent to circular orbit plus sinusoidal tail wiggle
					var heading: float = f["angle"] + (PI * 0.5 if f["speed"] > 0 else -PI * 0.5)
					var wag: float = sin(f["wiggle_phase"]) * 0.18
					f_node.rotation = Vector3(0.0, heading + wag, 0.0)

		# Animate periodic leaping fish at perimeter of ice platform into open water
		var leap_f: MeshInstance3D = p.get("leap_fish")
		var splash_r: MeshInstance3D = p.get("splash_ring")
		if is_instance_valid(leap_f):
			if not p["is_leaping"]:
				p["leap_timer"] -= delta
				if p["leap_timer"] <= 0.0:
					p["is_leaping"] = true
					p["leap_progress"] = 0.0
					p["leap_timer"] = randf_range(3.0, 5.5)
					var edge_ang: float = randf() * TAU
					var edge_r: float = p["base_radius"] * 1.05
					p["leap_start"] = Vector3(cos(edge_ang) * edge_r, -0.2, sin(edge_ang) * edge_r)
					var outward_dir: Vector3 = Vector3(cos(edge_ang + randf_range(-0.5, 0.5)), 0.0, sin(edge_ang + randf_range(-0.5, 0.5)))
					p["leap_end"] = p["leap_start"] + outward_dir * randf_range(1.8, 2.8)
					leap_f.visible = true
			else:
				p["leap_progress"] += delta * 1.4 # ~0.7s leap duration
				var t: float = clampf(p["leap_progress"], 0.0, 1.0)
				# Parabolic leap arc
				var horiz_pos: Vector3 = p["leap_start"].lerp(p["leap_end"], t)
				var arc_h: float = sin(t * PI) * 0.95
				leap_f.position = Vector3(horiz_pos.x, -0.2 + arc_h, horiz_pos.z)

				# Heading follows trajectory vector
				var tangent: Vector3 = (p["leap_end"] - p["leap_start"]).normalized()
				var pitch_ang: float = cos(t * PI) * deg_to_rad(45.0)
				var yaw_ang: float = atan2(-tangent.x, -tangent.z)
				leap_f.rotation = Vector3(pitch_ang, yaw_ang, 0.0)

				if t >= 1.0:
					p["is_leaping"] = false
					leap_f.visible = false
					# Trigger splash ring at re-entry location
					if is_instance_valid(splash_r):
						splash_r.position = Vector3(p["leap_end"].x, 0.04, p["leap_end"].z)
						splash_r.scale = Vector3(0.3, 0.3, 0.3)
						splash_r.visible = true
						p["splash_timer"] = 0.55

		# Fade splash ripple ring
		if is_instance_valid(splash_r) and splash_r.visible:
			p["splash_timer"] -= delta
			if p["splash_timer"] > 0.0:
				var sp_scale: float = lerpf(1.6, 0.3, p["splash_timer"] / 0.55)
				splash_r.scale = Vector3(sp_scale, 1.0, sp_scale)
			else:
				splash_r.visible = false

		# Shrink and sink slightly when melting in last 4 seconds
		if p["time_left"] < 4.0:
			var melt_ratio: float = clampf(p["time_left"] / 4.0, 0.1, 1.0)
			if is_instance_valid(p["mesh"]):
				p["mesh"].scale = Vector3(melt_ratio, melt_ratio, melt_ratio)
			if is_instance_valid(p["col"]):
				var cyl_shape: CylinderShape3D = p["col"].shape as CylinderShape3D
				if cyl_shape:
					cyl_shape.radius = p["base_radius"] * melt_ratio

		if p["time_left"] <= 0.0:
			_destroy_platform(i, false)

		i -= 1

func get_active_ice_count() -> int:
	return _active_platforms.size()

func is_position_on_ice(pos: Vector3, threshold: float = 0.5) -> bool:
	for p in _active_platforms:
		var d_horiz: float = Vector2(pos.x - p["pos"].x, pos.z - p["pos"].z).length()
		if d_horiz <= (p["base_radius"] + threshold) and absf(pos.y - p["pos"].y) < 1.0:
			return true
	return false

static func _generate_freeze_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.42
	var num_samples: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 6.5)
		# Crystal ice snap frequency
		var snap: float = sin(2.0 * PI * (1200.0 - t * 650.0) * t) * 0.45
		var overtone: float = sin(2.0 * PI * 2400.0 * t) * 0.25
		var crackle: float = (randf() * 2.0 - 1.0) * 0.25 if randf() < 0.2 else 0.0
		var sample: float = (snap + overtone + crackle) * env * 0.65
		var val_16: int = int(clampf(sample * 32767.0, -32768.0, 32767.0))
		byte_array.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav
