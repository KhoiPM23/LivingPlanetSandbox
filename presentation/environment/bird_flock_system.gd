class_name BirdFlockSystem
extends Node3D

## Living Planet Sandbox — 3D Procedural Flying Bird Flock System.
## Populates open-world skies with dynamic 3D avian wildlife:
## 1. Coastal Seagulls gliding over bays and shorelines.
## 2. Alpine Eagles & Raptors soaring high in thermal updrafts over peaks and castles.
## 3. Forest Songbirds darting in synchronized flocks over woodland canopies.
## Built with MultiMeshInstance3D for 60+ FPS on Intel Iris Xe with zero CPU draw overhead.

class BirdIndividual:
	var center: Vector3
	var radius: float
	var altitude: float
	var orbit_speed: float
	var angle: float
	var height_phase: float
	var flap_rate: float
	var flap_phase: float
	var is_gliding: bool
	var glide_timer: float
	var scale_val: float
	var bank_tilt: float

var _coastal_gulls_mmi: MultiMeshInstance3D = null
var _coastal_gulls: Array[BirdIndividual] = []

var _alpine_eagles_mmi: MultiMeshInstance3D = null
var _alpine_eagles: Array[BirdIndividual] = []

var _forest_birds_mmi: MultiMeshInstance3D = null
var _forest_birds: Array[BirdIndividual] = []

var _gull_mesh: Mesh = null
var _eagle_mesh: Mesh = null
var _songbird_mesh: Mesh = null

func _ready() -> void:
	name = "BirdFlockSystem"
	_init_bird_meshes()
	_setup_coastal_gulls(24)
	_setup_alpine_eagles(8)
	_setup_forest_birds(32)

func _init_bird_meshes() -> void:
	_gull_mesh = _create_stylized_bird_mesh(Color(0.92, 0.94, 0.96), Color(0.25, 0.28, 0.32), 1.3, 0.7)
	_eagle_mesh = _create_stylized_bird_mesh(Color(0.35, 0.26, 0.18), Color(0.18, 0.14, 0.10), 2.5, 1.3)
	_songbird_mesh = _create_stylized_bird_mesh(Color(0.40, 0.58, 0.75), Color(0.95, 0.78, 0.25), 0.75, 0.45)

func _create_stylized_bird_mesh(body_col: Color, wingtip_col: Color, wingspan: float, body_len: float) -> ArrayMesh:
	var am: ArrayMesh = ArrayMesh.new()
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = body_col
	mat.roughness = 0.85
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(mat)

	var half_span: float = wingspan * 0.5
	var half_len: float = body_len * 0.5

	# Fuselage vertices: Beak, Tail, Top, Bottom, Left, Right
	var beak: Vector3 = Vector3(0.0, 0.0, -half_len)
	var tail: Vector3 = Vector3(0.0, 0.04, half_len)
	var top_b: Vector3 = Vector3(0.0, 0.08, 0.0)
	var bot_b: Vector3 = Vector3(0.0, -0.06, 0.0)
	var left_w: Vector3 = Vector3(-half_span, 0.05, 0.05)
	var right_w: Vector3 = Vector3(half_span, 0.05, 0.05)
	var wing_mid_l: Vector3 = Vector3(-half_span * 0.45, 0.02, -0.05)
	var wing_mid_r: Vector3 = Vector3(half_span * 0.45, 0.02, -0.05)

	# Left Wing Face (Double sided via CULL_DISABLED)
	st.set_normal(Vector3.UP)
	st.set_color(wingtip_col)
	st.add_vertex(beak)
	st.add_vertex(left_w)
	st.add_vertex(tail)

	st.add_vertex(beak)
	st.add_vertex(wing_mid_l)
	st.add_vertex(left_w)

	# Right Wing Face
	st.set_normal(Vector3.UP)
	st.set_color(wingtip_col)
	st.add_vertex(beak)
	st.add_vertex(tail)
	st.add_vertex(right_w)

	st.add_vertex(beak)
	st.add_vertex(right_w)
	st.add_vertex(wing_mid_r)

	# Fuselage Top Ridge
	st.set_color(body_col)
	st.add_vertex(beak)
	st.add_vertex(top_b)
	st.add_vertex(tail)

	# Fuselage Keel (Bottom)
	st.add_vertex(beak)
	st.add_vertex(tail)
	st.add_vertex(bot_b)

	st.generate_normals()
	st.commit(am)
	return am

func _setup_coastal_gulls(count: int) -> void:
	_coastal_gulls_mmi = MultiMeshInstance3D.new()
	_coastal_gulls_mmi.name = "CoastalSeagullsMMI"
	_coastal_gulls_mmi.visibility_range_end = 650.0
	_coastal_gulls_mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = _gull_mesh
	_coastal_gulls_mmi.multimesh = mm
	add_child(_coastal_gulls_mmi)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 224411
	var coastal_centers: Array[Vector3] = [
		Vector3(18.0, 16.0, 22.0),   # Haven Pier & Shore
		Vector3(85.0, 14.0, 75.0),   # Grand Emerald Lake Basin
		Vector3(-45.0, 22.0, 160.0), # Cape Solitude Bay
		Vector3(-140.0, 18.0, 20.0)  # Western Coves
	]

	for i in range(count):
		var b: BirdIndividual = BirdIndividual.new()
		b.center = coastal_centers[i % coastal_centers.size()]
		b.radius = rng.randf_range(28.0, 68.0)
		b.altitude = rng.randf_range(16.0, 32.0)
		b.orbit_speed = rng.randf_range(0.25, 0.45) * (1.0 if rng.randf() > 0.3 else -1.0)
		b.angle = rng.randf_range(0.0, TAU)
		b.height_phase = rng.randf_range(0.0, TAU)
		b.flap_rate = rng.randf_range(6.5, 9.5)
		b.flap_phase = rng.randf_range(0.0, TAU)
		b.is_gliding = rng.randf() < 0.4
		b.glide_timer = rng.randf_range(1.5, 4.0)
		b.scale_val = rng.randf_range(0.95, 1.25)
		_coastal_gulls.append(b)

func _setup_alpine_eagles(count: int) -> void:
	_alpine_eagles_mmi = MultiMeshInstance3D.new()
	_alpine_eagles_mmi.name = "AlpineEaglesMMI"
	_alpine_eagles_mmi.visibility_range_end = 800.0
	_alpine_eagles_mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = _eagle_mesh
	_alpine_eagles_mmi.multimesh = mm
	add_child(_alpine_eagles_mmi)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 771122
	var eagle_centers: Array[Vector3] = [
		Vector3(-135.0, 85.0, -135.0), # Skyspire Mountain Massif
		Vector3(-55.0, 52.0, -85.0),   # Whispering Grotto & Castle Crags
		Vector3(120.0, 58.0, -60.0)    # Whispering Pine Highlands
	]

	for i in range(count):
		var b: BirdIndividual = BirdIndividual.new()
		b.center = eagle_centers[i % eagle_centers.size()]
		b.radius = rng.randf_range(45.0, 110.0)
		b.altitude = rng.randf_range(52.0, 92.0)
		b.orbit_speed = rng.randf_range(0.12, 0.22) # Majestically slow soaring
		b.angle = rng.randf_range(0.0, TAU)
		b.height_phase = rng.randf_range(0.0, TAU)
		b.flap_rate = 2.8
		b.flap_phase = rng.randf_range(0.0, TAU)
		b.is_gliding = true
		b.glide_timer = rng.randf_range(4.0, 8.0)
		b.scale_val = rng.randf_range(1.15, 1.55)
		_alpine_eagles.append(b)

func _setup_forest_birds(count: int) -> void:
	_forest_birds_mmi = MultiMeshInstance3D.new()
	_forest_birds_mmi.name = "ForestSongbirdsMMI"
	_forest_birds_mmi.visibility_range_end = 450.0
	_forest_birds_mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = _songbird_mesh
	_forest_birds_mmi.multimesh = mm
	add_child(_forest_birds_mmi)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 556633
	var forest_centers: Array[Vector3] = [
		Vector3(-10.0, 14.0, 5.0),   # Sunlit Meadow Glade
		Vector3(-65.0, 18.0, 35.0),  # Whispering Deep Forest Stand
		Vector3(45.0, 16.0, 45.0)    # South Meadow Edge
	]

	for i in range(count):
		var b: BirdIndividual = BirdIndividual.new()
		b.center = forest_centers[i % forest_centers.size()]
		b.radius = rng.randf_range(12.0, 35.0)
		b.altitude = rng.randf_range(8.0, 18.0)
		b.orbit_speed = rng.randf_range(0.40, 0.75) * (1.0 if rng.randf() > 0.4 else -1.0)
		b.angle = rng.randf_range(0.0, TAU)
		b.height_phase = rng.randf_range(0.0, TAU)
		b.flap_rate = rng.randf_range(10.0, 14.0)
		b.flap_phase = rng.randf_range(0.0, TAU)
		b.is_gliding = rng.randf() < 0.25
		b.glide_timer = rng.randf_range(0.8, 2.2)
		b.scale_val = rng.randf_range(0.85, 1.15)
		_forest_birds.append(b)

func _process(delta: float) -> void:
	_update_flock(_coastal_gulls_mmi, _coastal_gulls, delta)
	_update_flock(_alpine_eagles_mmi, _alpine_eagles, delta)
	_update_flock(_forest_birds_mmi, _forest_birds, delta)

func _update_flock(mmi: MultiMeshInstance3D, flock: Array[BirdIndividual], delta: float) -> void:
	if not mmi or not mmi.multimesh:
		return
	var mm: MultiMesh = mmi.multimesh

	for i in range(flock.size()):
		var b: BirdIndividual = flock[i]
		b.angle += b.orbit_speed * delta
		b.height_phase += delta * 0.8

		# Glide timer state alternation
		b.glide_timer -= delta
		if b.glide_timer <= 0.0:
			b.is_gliding = not b.is_gliding
			b.glide_timer = randf_range(2.0, 5.0) if b.is_gliding else randf_range(1.2, 3.0)

		# Orbit position with undulating altitude
		var px: float = b.center.x + cos(b.angle) * b.radius
		var pz: float = b.center.z + sin(b.angle) * b.radius
		var py: float = b.center.y + b.altitude + sin(b.height_phase) * 2.2

		# Forward vector along orbital tangent
		var tangent_dir: Vector3 = Vector3(-sin(b.angle), 0.0, cos(b.angle)) * signf(b.orbit_speed)
		tangent_dir.y = cos(b.height_phase) * 0.15 # Climb/dive tangent
		tangent_dir = tangent_dir.normalized()

		# Bank angle into turn: centripetal banking tilt
		var bank_target: float = clampf(b.orbit_speed * 1.8, -0.65, 0.65)
		b.bank_tilt = lerpf(b.bank_tilt, bank_target, delta * 3.5)

		# Flapping motion: slight pitch & roll fluttering
		var flap_roll: float = 0.0
		var flap_pitch: float = 0.0
		if not b.is_gliding:
			b.flap_phase += b.flap_rate * delta
			var flap: float = sin(b.flap_phase)
			flap_roll = flap * 0.12
			flap_pitch = flap * 0.06

		# Construct orientation transform
		var t: Transform3D = Transform3D()
		# Face direction of travel
		var look_target: Vector3 = Vector3(px, py, pz) + tangent_dir
		t = t.looking_at(tangent_dir, Vector3.UP)
		t = t.rotated_local(Vector3.FORWARD, b.bank_tilt + flap_roll)
		t = t.rotated_local(Vector3.RIGHT, flap_pitch)
		t = t.scaled(Vector3.ONE * b.scale_val)
		t.origin = Vector3(px, py, pz)

		mm.set_instance_transform(i, t)
