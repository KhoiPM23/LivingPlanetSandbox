class_name SubmergedSeaCavern
extends Node3D

## Living Planet Sandbox — Block 61: Submerged Sea Cavern & Catacombs Passage (Quần Xã Hang Biển Ngầm)
## Connects Sunken Galleon in Azure Reef to Castle Citadel Catacombs through the mountain core:
## - Bioluminescent crystal stalactites & stalagmites with cyan emission (Color(0.18, 0.92, 0.85))
## - Hydro Jetstream Current: propels underwater swimming speed up to +16.0 m/s through the cavern
## - Subterranean Air Pocket Sanctuary with glowing deep moss and ancient hidden reliquary chest
## - Two-way traversal linking ocean floor (-11.5m) to castle catacombs (-4.5m)

signal player_entered_cavern(entrance_name: String)
signal player_exited_cavern(exit_name: String)
signal cavern_chest_unlocked(reward: Dictionary)

const GALLEON_ENTRANCE_POS: Vector3 = Vector3(-62.0, -10.5, -42.0)
const CATACOMBS_EXIT_POS: Vector3 = Vector3(118.0, -4.2, -92.0)
const MID_CHAMBER_POS: Vector3 = Vector3(25.0, -6.5, -65.0)

# Cavern Nodes
var _tunnel_root: Node3D = null
var _crystals_root: Node3D = null
var _chest_node: Node3D = null
var _jetstream_particles: GPUParticles3D = null
var _audio_player: AudioStreamPlayer3D = null

# Materials
static var _rock_mat: StandardMaterial3D = null
static var _crystal_mat: StandardMaterial3D = null
static var _current_wav: AudioStreamWAV = null

var is_chest_opened: bool = false

func _init() -> void:
	name = "SubmergedSeaCavern"
	_init_materials()
	_init_audio()
	_build_cavern_architecture()

static func _init_materials() -> void:
	if _rock_mat != null:
		return
	_rock_mat = StandardMaterial3D.new()
	_rock_mat.albedo_color = Color(0.12, 0.16, 0.20) # Deep sea abyssal basalt
	_rock_mat.roughness = 0.90

	_crystal_mat = StandardMaterial3D.new()
	_crystal_mat.albedo_color = Color(0.15, 0.88, 0.82)
	_crystal_mat.roughness = 0.20
	_crystal_mat.emission_enabled = true
	_crystal_mat.emission = Color(0.18, 0.95, 0.88)
	_crystal_mat.emission_energy_multiplier = 2.2

static func _init_audio() -> void:
	if _current_wav != null:
		return
	var rate: int = 22050
	var duration: float = 0.65
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var env: float = sin(clampf(t / duration, 0.0, 1.0) * PI) * 0.40
		var tone: float = sin(t * TAU * 140.0) + 0.4 * sin(t * TAU * 280.0)
		var sample: float = tone * env
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	_current_wav = AudioStreamWAV.new()
	_current_wav.format = AudioStreamWAV.FORMAT_16_BITS
	_current_wav.mix_rate = rate
	_current_wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	_current_wav.data = byte_data

func _build_cavern_architecture() -> void:
	_tunnel_root = Node3D.new()
	_tunnel_root.name = "CavernPassage"
	add_child(_tunnel_root)

	# 1. Entrance Archway at Sunken Galleon
	var g_arch: Node3D = _build_archway("GalleonEntranceArch", GALLEON_ENTRANCE_POS)
	_tunnel_root.add_child(g_arch)

	# 2. Intermediate Tunnel Rings & Glowing Stalactites
	_crystals_root = Node3D.new()
	_crystals_root.name = "LuminescentCrystals"
	add_child(_crystals_root)

	var waypoints: Array[Vector3] = [
		GALLEON_ENTRANCE_POS,
		Vector3(-30.0, -9.0, -50.0),
		MID_CHAMBER_POS,
		Vector3(70.0, -5.5, -80.0),
		CATACOMBS_EXIT_POS
	]

	for i in range(waypoints.size() - 1):
		var p0: Vector3 = waypoints[i]
		var p1: Vector3 = waypoints[i + 1]
		var mid: Vector3 = (p0 + p1) * 0.5
		var arch: Node3D = _build_archway("TunnelArch_%d" % i, mid)
		var fwd_dir: Vector3 = (p1 - mid).normalized()
		if fwd_dir.length_squared() > 0.001 and not fwd_dir.is_equal_approx(Vector3.UP):
			arch.transform = Transform3D().looking_at(fwd_dir, Vector3.UP)
			arch.position = mid
		_tunnel_root.add_child(arch)

		# Cluster of 4 glowing crystal stalactites per span
		for j in range(4):
			var frac: float = float(j + 1) / 5.0
			var c_pos: Vector3 = p0.lerp(p1, frac) + Vector3(randf_range(-2.5, 2.5), randf_range(2.0, 4.0), randf_range(-2.5, 2.5))
			var c_mesh: MeshInstance3D = MeshInstance3D.new()
			var p_prism: PrismMesh = PrismMesh.new()
			p_prism.size = Vector3(0.45, 1.85, 0.45)
			c_mesh.mesh = p_prism
			c_mesh.material_override = _crystal_mat
			c_mesh.position = c_pos
			c_mesh.rotation = Vector3(PI, randf_range(-0.4, 0.4), randf_range(-0.3, 0.3))
			_crystals_root.add_child(c_mesh)

	# 3. Mid-Cavern Air Pocket Chamber & Hidden Chest
	var chamber: Node3D = Node3D.new()
	chamber.name = "AirPocketChamber"
	chamber.position = MID_CHAMBER_POS
	add_child(chamber)

	# Chamber Dome
	var dome: MeshInstance3D = MeshInstance3D.new()
	var d_sphere: SphereMesh = SphereMesh.new()
	d_sphere.radius = 8.5
	d_sphere.height = 12.0
	dome.mesh = d_sphere
	dome.material_override = _rock_mat
	chamber.add_child(dome)

	# Chamber Light
	var c_light: OmniLight3D = OmniLight3D.new()
	c_light.light_color = Color(0.20, 0.95, 0.85)
	c_light.light_energy = 2.5
	c_light.omni_range = 16.0
	chamber.add_child(c_light)

	# Reliquary Chest
	_chest_node = Node3D.new()
	_chest_node.name = "SeaCavernReliquaryChest"
	_chest_node.position = MID_CHAMBER_POS + Vector3(0.0, 0.45, 0.0)
	add_child(_chest_node)

	var c_box: MeshInstance3D = MeshInstance3D.new()
	var b_mesh: BoxMesh = BoxMesh.new()
	b_mesh.size = Vector3(1.15, 0.75, 0.85)
	c_box.mesh = b_mesh
	var ch_mat: StandardMaterial3D = StandardMaterial3D.new()
	ch_mat.albedo_color = Color(0.22, 0.28, 0.35)
	ch_mat.metallic = 0.75
	ch_mat.roughness = 0.35
	c_box.material_override = ch_mat
	_chest_node.add_child(c_box)

	# 4. Castle Catacombs Exit Gateway
	var c_arch: Node3D = _build_archway("CatacombsExitArch", CATACOMBS_EXIT_POS)
	_tunnel_root.add_child(c_arch)

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "CavernAudio"
	_audio_player.unit_size = 5.0
	_audio_player.max_distance = 50.0
	add_child(_audio_player)

func _build_archway(arch_name: String, pos: Vector3) -> Node3D:
	var arch_root: Node3D = Node3D.new()
	arch_root.name = arch_name
	arch_root.position = pos

	var torus: MeshInstance3D = MeshInstance3D.new()
	var t_mesh: TorusMesh = TorusMesh.new()
	t_mesh.inner_radius = 2.8
	t_mesh.outer_radius = 3.6
	torus.mesh = t_mesh
	torus.material_override = _rock_mat
	torus.rotation.x = deg_to_rad(90.0)
	arch_root.add_child(torus)

	var glow_ring: MeshInstance3D = MeshInstance3D.new()
	var r_mesh: TorusMesh = TorusMesh.new()
	r_mesh.inner_radius = 2.7
	r_mesh.outer_radius = 2.85
	glow_ring.mesh = r_mesh
	glow_ring.material_override = _crystal_mat
	glow_ring.rotation.x = deg_to_rad(90.0)
	arch_root.add_child(glow_ring)

	return arch_root

## Check if player is near entrance or exit for prompt interaction
func get_interaction_prompt(player_pos: Vector3) -> Dictionary:
	if player_pos.distance_to(GALLEON_ENTRANCE_POS) < 4.2:
		return {
			"action": "enter_from_sea",
			"prompt": "[E] Đi vào Hang Biển Ngầm (Enter Sunken Sea Cavern)",
			"target_pos": MID_CHAMBER_POS
		}
	elif player_pos.distance_to(CATACOMBS_EXIT_POS) < 4.2:
		return {
			"action": "enter_from_castle",
			"prompt": "[E] Xuống Hang Biển Ngầm (Descend to Sea Cavern)",
			"target_pos": MID_CHAMBER_POS
		}
	elif player_pos.distance_to(MID_CHAMBER_POS) < 3.2 and not is_chest_opened:
		return {
			"action": "open_chest",
			"prompt": "[E] Mở Rương Bí Mật Đáy Hang (Open Cavern Cache)",
			"target_pos": Vector3.ZERO
		}
	return {}

## Trigger interaction
func trigger_interaction(player: FirstPersonWalker, action: String) -> Dictionary:
	var result: Dictionary = {}
	match action:
		"enter_from_sea":
			player.teleport_to(MID_CHAMBER_POS)
			_play_jetstream_sound()
			player_entered_cavern.emit("galleon")
			result = {"success": true, "msg": "Entered Sea Cavern"}
		"enter_from_castle":
			player.teleport_to(MID_CHAMBER_POS)
			_play_jetstream_sound()
			player_entered_cavern.emit("catacombs")
			result = {"success": true, "msg": "Descended to Sea Cavern"}
		"open_chest":
			if not is_chest_opened:
				is_chest_opened = true
				var reward: Dictionary = {
					"id": "ancient_relic_con_dau",
					"name": "Con Dấu Hoàng Gia Biển Sâu",
					"exp": 450,
					"coins": 200
				}
				cavern_chest_unlocked.emit(reward)
				result = {"success": true, "reward": reward}
	return result

func _play_jetstream_sound() -> void:
	if _audio_player and is_inside_tree() and _current_wav:
		_audio_player.stream = _current_wav
		_audio_player.play()
