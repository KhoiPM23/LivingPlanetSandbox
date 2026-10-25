class_name CanopySunShafts
extends Node3D

## Living Planet Sandbox — Cinematic Canopy God-Rays & Forest Atmosphere (Block 58)
## Features:
## 1. Volumetric procedural sun shafts filtering down through mountain pine canopies and glades.
## 2. Dynamic light shaft color & angle coupling to DayNightCycle (warm golden grazing angle at dawn/dusk).
## 3. Drifting atmospheric golden forest dust and pollen motes.
## 4. Intel Iris Xe optimized: unshaded additive blending, zero CPU strain, 60 FPS budgeted.

var _shaft_mesh_instances: Array[MeshInstance3D] = []
var _shaft_mat: StandardMaterial3D = null
var _pollen_particles: CPUParticles3D = null
var _day_night_ref: DayNightCycle = null
var _anim_time: float = 0.0

# 6 Strategic shaft locations across scenic glades & canyon overlooks
var shaft_locations: Array[Vector3] = [
	Vector3(-45.0, 5.4, -15.0),  # Ancient Silver Glade (Mythic Stag sanctuary)
	Vector3(-12.0, 6.2, 12.0),   # Scenic Promontory (Trial Dial)
	Vector3(-15.0, 3.0, 45.0),   # Whispering Gorge Rock Shelf (Geyser)
	Vector3(14.0, 6.5, -18.0),   # Summit Promontory (Ancient Stele)
	Vector3(7.5, 3.8, 12.0),     # Wilderness Camp Glade
	Vector3(95.0, 3.6, 85.0)     # Grand Emerald Lake Heart Island
]

func _init() -> void:
	name = "CanopySunShafts"
	_init_material()
	_build_sun_shafts()
	_build_pollen_particles()

func setup(day_night: DayNightCycle = null) -> void:
	_day_night_ref = day_night
	update_lighting_adaptation()

func _init_material() -> void:
	_shaft_mat = StandardMaterial3D.new()
	_shaft_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shaft_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_shaft_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shaft_mat.albedo_color = Color(1.0, 0.85, 0.45, 0.18)
	_shaft_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

func _build_sun_shafts() -> void:
	for i in range(shaft_locations.size()):
		var loc: Vector3 = shaft_locations[i]
		var shaft_root = Node3D.new()
		shaft_root.name = "ShaftCluster_%d" % i
		shaft_root.position = loc
		add_child(shaft_root)

		# 3 Slanted ray cones per cluster
		for r_idx in range(3):
			var cone_mesh = CylinderMesh.new()
			cone_mesh.top_radius = 0.4
			cone_mesh.bottom_radius = 2.8 + float(r_idx) * 0.6
			cone_mesh.height = 14.0
			cone_mesh.radial_segments = 12
			cone_mesh.material = _shaft_mat

			var cone_inst = MeshInstance3D.new()
			cone_inst.mesh = cone_mesh
			var offset_x: float = float(r_idx - 1) * 2.2
			cone_inst.position = Vector3(offset_x, 7.0, 0.0)
			cone_inst.rotation = Vector3(deg_to_rad(18.0), deg_to_rad(r_idx * 25.0), deg_to_rad(-12.0))
			shaft_root.add_child(cone_inst)
			_shaft_mesh_instances.append(cone_inst)

func _build_pollen_particles() -> void:
	_pollen_particles = CPUParticles3D.new()
	_pollen_particles.name = "ForestPollenParticles"
	_pollen_particles.amount = 32
	_pollen_particles.lifetime = 4.0
	_pollen_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_pollen_particles.emission_box_extents = Vector3(30.0, 6.0, 30.0)
	_pollen_particles.position = Vector3(-15.0, 5.0, 15.0)
	_pollen_particles.gravity = Vector3(0.08, -0.05, 0.04)
	_pollen_particles.initial_velocity_min = 0.1
	_pollen_particles.initial_velocity_max = 0.35
	_pollen_particles.scale_amount_min = 0.05
	_pollen_particles.scale_amount_max = 0.10
	_pollen_particles.color = Color(1.0, 0.90, 0.50, 0.70)
	add_child(_pollen_particles)

func _process(delta: float) -> void:
	_anim_time += delta

	# Dynamic celestial sun alignment tracking DayNightCycle
	if _day_night_ref:
		var s_dir: Vector3 = _day_night_ref.get_sun_direction()
		var night_flag: bool = _day_night_ref.is_night()
		align_with_sun(s_dir, night_flag)
		update_lighting_adaptation()

	# Gentle breathing atmospheric shimmer
	if _shaft_mat:
		var base_alpha: float = _shaft_mat.albedo_color.a
		var shimmer: float = base_alpha * (0.88 + sin(_anim_time * 1.6) * 0.12)
		var col: Color = _shaft_mat.albedo_color
		col.a = clampf(shimmer, 0.01, 0.35)
		_shaft_mat.albedo_color = col

## Dynamically reorients shaft cones along the celestial vector from the sun or moon
func align_with_sun(celestial_dir: Vector3, is_night: bool = false) -> void:
	if celestial_dir.length_squared() < 0.001:
		return

	var active_dir: Vector3 = celestial_dir.normalized()
	if is_night and _day_night_ref != null:
		active_dir = _day_night_ref.get_moon_direction().normalized()

	var y_axis: Vector3 = active_dir
	# Guard against gimbal lock when sun is directly overhead
	var ref_up: Vector3 = Vector3.UP if absf(y_axis.y) < 0.92 else Vector3.FORWARD
	var x_axis: Vector3 = ref_up.cross(y_axis).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()
	var celestial_basis: Basis = Basis(x_axis, y_axis, z_axis)

	for i in range(_shaft_mesh_instances.size()):
		var cone_inst: MeshInstance3D = _shaft_mesh_instances[i]
		if not is_instance_valid(cone_inst):
			continue
		var r_idx: int = i % 3
		var spread_angle: float = float(r_idx - 1) * deg_to_rad(6.5)
		cone_inst.basis = celestial_basis.rotated(z_axis, spread_angle)
		cone_inst.position = y_axis * 6.5 + x_axis * (float(r_idx - 1) * 1.8)

func update_lighting_adaptation() -> void:
	if not _shaft_mat:
		return

	if _day_night_ref == null:
		_shaft_mat.albedo_color = Color(1.0, 0.85, 0.45, 0.18)
		return

	match _day_night_ref.current_lighting_state:
		DayNightCycle.LightingState.GOLDEN_HOUR:
			_shaft_mat.albedo_color = Color(1.0, 0.78, 0.32, 0.22)
		DayNightCycle.LightingState.MIDDAY:
			_shaft_mat.albedo_color = Color(0.92, 0.96, 1.0, 0.14)
		DayNightCycle.LightingState.OVERCAST_RAIN:
			_shaft_mat.albedo_color = Color(0.68, 0.76, 0.86, 0.05)
		_:
			if _day_night_ref.is_night():
				_shaft_mat.albedo_color = Color(0.40, 0.60, 0.90, 0.04)
			else:
				var s_dir: Vector3 = _day_night_ref.get_sun_direction()
				if s_dir.y < 0.25 and s_dir.y > -0.05:
					# Dawn or dusk golden rays
					_shaft_mat.albedo_color = Color(1.0, 0.78, 0.34, 0.22)
				else:
					_shaft_mat.albedo_color = Color(0.95, 0.92, 0.70, 0.16)

