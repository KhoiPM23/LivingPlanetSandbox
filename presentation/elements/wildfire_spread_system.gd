class_name WildfireSpreadSystem
extends Node3D

## Living Planet Sandbox — Genshin/BotW-Style Wildfire & Thermal Updraft System (Block 64)
## Features:
## 1. Dynamic Grass Combustion: Ignites on Pyro attack or campfire ember contact.
## 2. Wind-Driven Flame Propagation: Spreads downwind along IslandTerrain surface.
## 3. Convective Thermal Updraft Column: Generates real-time UpdraftVent3D on burning grass,
##    enabling instant ground-level Anemo Glider launch (Genshin signature mechanic).
## 4. Hydro / Rain Extinguishment: Water skills or rain douse fire with steam sizzle.
## 5. Performance Budgeted: Max 12 active flame patches, shared materials, GPU particles.

const UpdraftVent3D = preload("res://presentation/environment/updraft_vent.gd")

signal fire_ignited(pos: Vector3)
signal fire_doused(pos: Vector3)
signal fire_spread(from_pos: Vector3, to_pos: Vector3)

const MAX_ACTIVE_FIRES: int = 12
const DEFAULT_BURN_DURATION: float = 12.0
const SPREAD_INTERVAL: float = 2.4
const SPREAD_DISTANCE: float = 3.6

# Materials (Shared)
static var _fire_particle_mat: ParticleProcessMaterial = null
static var _ember_mesh: SphereMesh = null
static var _ember_mat: StandardMaterial3D = null
static var _charred_mat: StandardMaterial3D = null
static var _sizzle_wav: AudioStreamWAV = null

# Active Fires
var _active_fires: Array[Dictionary] = []
var _terrain_ref: Node = null
var _wind_dir: Vector2 = Vector2(0.85, 0.52).normalized()
var _wind_speed: float = 1.4

func _init() -> void:
	name = "WildfireSpreadSystem"
	_init_materials()
	_init_audio()

func setup(terrain: Node = null) -> void:
	_terrain_ref = terrain

func set_wind(dir: Vector2, speed: float) -> void:
	_wind_dir = dir.normalized() if dir.length_squared() > 0.001 else Vector2(1.0, 0.0)
	_wind_speed = clampf(speed, 0.2, 5.0)

static func _init_materials() -> void:
	if _ember_mat != null:
		return

	_ember_mat = StandardMaterial3D.new()
	_ember_mat.albedo_color = Color(1.0, 0.45, 0.12)
	_ember_mat.emission_enabled = true
	_ember_mat.emission = Color(1.0, 0.55, 0.18)
	_ember_mat.emission_energy_multiplier = 3.5
	_ember_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_ember_mesh = SphereMesh.new()
	_ember_mesh.radius = 0.12
	_ember_mesh.height = 0.24
	_ember_mesh.radial_segments = 6
	_ember_mesh.rings = 4
	_ember_mesh.material = _ember_mat

	_fire_particle_mat = ParticleProcessMaterial.new()
	_fire_particle_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	_fire_particle_mat.emission_sphere_radius = 1.2
	_fire_particle_mat.direction = Vector3(0.0, 1.0, 0.0)
	_fire_particle_mat.spread = 22.0
	_fire_particle_mat.initial_velocity_min = 1.8
	_fire_particle_mat.initial_velocity_max = 3.2
	_fire_particle_mat.gravity = Vector3(0.0, 1.2, 0.0) # Upward heat draft
	_fire_particle_mat.scale_min = 0.6
	_fire_particle_mat.scale_max = 1.4

	_charred_mat = StandardMaterial3D.new()
	_charred_mat.albedo_color = Color(0.12, 0.10, 0.08) # Soot black
	_charred_mat.roughness = 0.95

static func _init_audio() -> void:
	if _sizzle_wav != null:
		return
	_sizzle_wav = _generate_sizzle_wav()

## Ignites grass fire at world position. Returns true if flame was successfully created.
func ignite_at(world_pos: Vector3, radius: float = 2.0) -> bool:
	if _active_fires.size() >= MAX_ACTIVE_FIRES:
		# Recycle oldest fire
		_extinguish_fire(0, false)

	# Snap to terrain if available
	var ground_y: float = world_pos.y
	if _terrain_ref and _terrain_ref.has_method("get_height_at"):
		ground_y = _terrain_ref.get_height_at(world_pos.x, world_pos.z)
	
	# Prevent burning underwater (water level ~0.0)
	if ground_y < 0.2:
		return false

	var fire_pos: Vector3 = Vector3(world_pos.x, ground_y + 0.1, world_pos.z)

	# 1. Visual Root
	var root: Node3D = Node3D.new()
	root.name = "WildfirePatch_%d" % (_active_fires.size() + 1)
	root.position = fire_pos
	add_child(root)

	# 2. Fire Light (Warm flickering campfire glow)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1.0, 0.58, 0.22)
	light.light_energy = 2.8
	light.omni_range = 8.5
	light.omni_attenuation = 1.2
	light.position = Vector3(0.0, 0.8, 0.0)
	root.add_child(light)

	# 3. Flame Embers GPUParticles3D
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.amount = 24
	particles.lifetime = 0.9
	particles.process_material = _fire_particle_mat
	particles.draw_pass_1 = _ember_mesh
	particles.position = Vector3(0.0, 0.2, 0.0)
	root.add_child(particles)

	# 4. Thermal Updraft Vent (Signature Genshin Glider mechanic)
	var updraft: UpdraftVent3D = UpdraftVent3D.new()
	updraft.name = "ThermalUpdraft"
	updraft.updraft_power = 15.5
	updraft.updraft_height = 14.5
	updraft.updraft_radius = 3.2
	root.add_child(updraft)

	# 5. Charred Decal / Scorch Circle
	var scorch: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius * 0.95
	cyl.bottom_radius = radius * 1.05
	cyl.height = 0.06
	cyl.radial_segments = 12
	scorch.mesh = cyl
	scorch.material_override = _charred_mat
	scorch.position = Vector3(0.0, 0.02, 0.0)
	root.add_child(scorch)

	var fire_data: Dictionary = {
		"root": root,
		"light": light,
		"particles": particles,
		"updraft": updraft,
		"pos": fire_pos,
		"radius": radius,
		"time_left": DEFAULT_BURN_DURATION,
		"spread_timer": SPREAD_INTERVAL,
		"can_spread": true
	}
	_active_fires.append(fire_data)
	fire_ignited.emit(fire_pos)
	return true

## Extinguishes all fires within radius of given position (Hydro / Rain / Cryo)
func douse_at(world_pos: Vector3, radius: float = 4.5) -> int:
	var doused_count: int = 0
	var i: int = _active_fires.size() - 1
	while i >= 0:
		var f: Dictionary = _active_fires[i]
		if f["pos"].distance_to(world_pos) <= (radius + f["radius"]):
			_extinguish_fire(i, true)
			doused_count += 1
		i -= 1
	return doused_count

func _extinguish_fire(idx: int, play_sizzle: bool = true) -> void:
	if idx < 0 or idx >= _active_fires.size():
		return
	var f: Dictionary = _active_fires[idx]
	var fire_pos: Vector3 = f["pos"]

	if play_sizzle and _sizzle_wav and is_inside_tree():
		var snd: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		snd.stream = _sizzle_wav
		snd.position = fire_pos
		snd.unit_size = 6.0
		snd.max_distance = 25.0
		add_child(snd)
		snd.play()
		snd.finished.connect(snd.queue_free)

	if is_instance_valid(f["root"]):
		f["root"].queue_free()

	_active_fires.remove_at(idx)
	fire_doused.emit(fire_pos)

func update_simulation(delta: float, player_ref: Node = null) -> void:
	var i: int = _active_fires.size() - 1
	while i >= 0:
		var f: Dictionary = _active_fires[i]
		f["time_left"] -= delta
		f["spread_timer"] -= delta

		# Light flicker
		if is_instance_valid(f["light"]):
			var light: OmniLight3D = f["light"]
			light.light_energy = 2.6 + sin(f["time_left"] * 18.0) * 0.45 + (randf() - 0.5) * 0.2

		# Update thermal updraft player attraction
		if is_instance_valid(f["updraft"]) and player_ref and f["updraft"].has_method("set_player_reference"):
			f["updraft"].set_player_reference(player_ref)

		# Spread fire downwind
		if f["can_spread"] and f["spread_timer"] <= 0.0 and _active_fires.size() < MAX_ACTIVE_FIRES:
			f["spread_timer"] = SPREAD_INTERVAL
			# Spread downwind with slight lateral variance
			var spread_offset: Vector2 = _wind_dir * SPREAD_DISTANCE
			var lateral_var: float = (randf() - 0.5) * 2.2
			var perp: Vector2 = Vector2(-_wind_dir.y, _wind_dir.x) * lateral_var
			var next_pos_2d: Vector2 = Vector2(f["pos"].x, f["pos"].z) + spread_offset + perp
			var next_pos: Vector3 = Vector3(next_pos_2d.x, f["pos"].y, next_pos_2d.y)

			# Only spread if far enough from existing fires
			var too_close: bool = false
			for other in _active_fires:
				if other["pos"].distance_to(next_pos) < 2.5:
					too_close = true
					break
			if not too_close:
				if ignite_at(next_pos, f["radius"] * 0.9):
					fire_spread.emit(f["pos"], next_pos)
					f["can_spread"] = false # Each patch only spawns once to prevent runaway fire storm

		# Burnout
		if f["time_left"] <= 0.0:
			_extinguish_fire(i, false)

		i -= 1

func get_active_fire_count() -> int:
	return _active_fires.size()

func get_fire_positions() -> Array[Vector3]:
	var poses: Array[Vector3] = []
	for f in _active_fires:
		poses.append(f["pos"])
	return poses

func is_position_near_fire(pos: Vector3, threshold: float = 6.0) -> bool:
	for f in _active_fires:
		if f["pos"].distance_to(pos) <= threshold:
			return true
	return false

static func _generate_sizzle_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.55
	var num_samples: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 5.0)
		# White noise hiss with modulated tone
		var noise: float = (randf() * 2.0 - 1.0) * 0.65
		var bubble: float = sin(2.0 * PI * (340.0 + sin(t * 40.0) * 120.0) * t) * 0.35
		var sample: float = (noise + bubble) * env * 0.5
		var val_16: int = int(clampf(sample * 32767.0, -32768.0, 32767.0))
		byte_array.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav
