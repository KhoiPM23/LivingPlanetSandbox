class_name WildernessTorchSystem
extends Node3D

## Wilderness Survival Torch & Elemental Combustion System for Living Planet Sandbox.
## Provides immersive night illumination, realistic environmental reactions, and ecological cycles:
## - Handheld torch with warm flicker lighting optimized for Intel Iris Xe (shadow-free, fillrate budgeted).
## - Placed torches with distance-budgeted lighting (strictly <= 3 active placed lights + 1 held light).
## - Water immersion & heavy rain extinguishment with procedural steam sizzle audio.
## - Controlled grass ignition depositing nutrient-rich ash to drive autonomous ecological regrowth.
## - Dynamic predator deterrence (wolves avoid torch fire) and nocturnal insect phototaxis.

signal torch_toggled(is_active: bool)
signal torch_placed(position: Vector3)
signal torch_extinguished(reason: String)
signal combustion_created(position: Vector3, radius: float)
signal campfire_placed(position: Vector3)
signal campfire_extinguished(reason: String)
signal shelter_placed(position: Vector3)
signal shelter_rested(new_sim_hour: float)
signal berries_harvested(berry_type: String, count: int, total_foraged: int)
signal herbivore_fed(herbivore_id: int, berry_type: String)

@export var torch_light_range: float = 16.0
@export var torch_light_energy: float = 1.8
@export var torch_light_color: Color = Color(1.0, 0.72, 0.35)

var is_torch_held: bool = false
var is_torch_lit: bool = true

var _held_torch_root: Node3D = null
var _held_light: OmniLight3D = null
var _held_flame_mesh: MeshInstance3D = null
var _held_sparks: CPUParticles3D = null
var _held_smoke: CPUParticles3D = null
var _audio_player: AudioStreamPlayer3D = null

var _placed_torches: Array[Node3D] = []
var _placed_campfires: Array[Node3D] = []
var _placed_shelters: Array[Node3D] = []
const MAX_PLACED_TORCHES: int = 24
const MAX_PLACED_CAMPFIRES: int = 6
const MAX_PLACED_SHELTERS: int = 4
const MAX_ACTIVE_PLACED_LIGHTS: int = 3

var _forage_bushes: Dictionary = {}
var foraged_berries_inventory: Dictionary = {
	"alpine_elderberry": 0,
	"glade_blueberry": 0,
	"amber_cloudberry": 0
}

var _weather: WeatherSystem = null
var _clock: WorldClock = null
var _fauna_sim: FaunaSimulation = null
var _env_grid: EnvironmentalGrid = null
var _flora_sim: FloraSimulation = null

var _water_height: float = 1.0
var _rain_burn_timer: float = 25.0
var _warmth_timer: float = 0.0
var _time_accum: float = 0.0
var _budget_check_timer: float = 0.0

# Procedural Audio Cache
static var _cached_whoosh_wav: AudioStreamWAV = null
static var _cached_sizzle_wav: AudioStreamWAV = null
static var _cached_crackle_wav: AudioStreamWAV = null

# Shared Materials for Batching
static var _mat_wood_handle: StandardMaterial3D = null
static var _mat_burlap_head: StandardMaterial3D = null
static var _mat_flame: StandardMaterial3D = null
static var _mat_ash_decal: StandardMaterial3D = null
static var _mat_stone: StandardMaterial3D = null
static var _mat_charcoal: StandardMaterial3D = null
static var _mat_canvas: StandardMaterial3D = null
static var _mat_bedroll: StandardMaterial3D = null
static var _mat_lantern: StandardMaterial3D = null

func _init() -> void:
	_init_materials()
	_init_audio_cache()

func setup(weather: WeatherSystem, clock: WorldClock, fauna: FaunaSimulation = null, grid: EnvironmentalGrid = null, flora: FloraSimulation = null, water_level: float = 1.0) -> void:
	_weather = weather
	_clock = clock
	_fauna_sim = fauna
	_env_grid = grid
	_flora_sim = flora
	_water_height = water_level

func _ready() -> void:
	_build_held_torch_rig()

func _init_materials() -> void:
	if _mat_wood_handle == null:
		_mat_wood_handle = StandardMaterial3D.new()
		_mat_wood_handle.albedo_color = Color(0.28, 0.18, 0.10)
		_mat_wood_handle.roughness = 0.92

	if _mat_burlap_head == null:
		_mat_burlap_head = StandardMaterial3D.new()
		_mat_burlap_head.albedo_color = Color(0.18, 0.15, 0.12)
		_mat_burlap_head.roughness = 0.95

	if _mat_flame == null:
		_mat_flame = StandardMaterial3D.new()
		_mat_flame.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_flame.albedo_color = Color(1.0, 0.75, 0.25, 0.95)
		_mat_flame.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_flame.cull_mode = BaseMaterial3D.CULL_DISABLED

	if _mat_ash_decal == null:
		_mat_ash_decal = StandardMaterial3D.new()
		_mat_ash_decal.albedo_color = Color(0.08, 0.08, 0.09, 0.88)
		_mat_ash_decal.roughness = 0.98
		_mat_ash_decal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	if _mat_stone == null:
		_mat_stone = StandardMaterial3D.new()
		_mat_stone.albedo_color = Color(0.38, 0.40, 0.42)
		_mat_stone.roughness = 0.90

	if _mat_charcoal == null:
		_mat_charcoal = StandardMaterial3D.new()
		_mat_charcoal.albedo_color = Color(0.12, 0.10, 0.09)
		_mat_charcoal.roughness = 0.95

	if _mat_canvas == null:
		_mat_canvas = StandardMaterial3D.new()
		_mat_canvas.albedo_color = Color(0.44, 0.46, 0.38)
		_mat_canvas.roughness = 0.92
		_mat_canvas.cull_mode = BaseMaterial3D.CULL_DISABLED

	if _mat_bedroll == null:
		_mat_bedroll = StandardMaterial3D.new()
		_mat_bedroll.albedo_color = Color(0.68, 0.62, 0.48)
		_mat_bedroll.roughness = 0.88

	if _mat_lantern == null:
		_mat_lantern = StandardMaterial3D.new()
		_mat_lantern.albedo_color = Color(0.72, 0.58, 0.32)
		_mat_lantern.metallic = 0.75
		_mat_lantern.roughness = 0.35

func _init_audio_cache() -> void:
	if _cached_whoosh_wav == null:
		_cached_whoosh_wav = _generate_ignite_whoosh(0.35, 22050)
	if _cached_sizzle_wav == null:
		_cached_sizzle_wav = _generate_sizzle_wav(0.65, 22050)
	if _cached_crackle_wav == null:
		_cached_crackle_wav = _generate_crackle_loop(2.0, 22050)

func _build_held_torch_rig() -> void:
	_held_torch_root = Node3D.new()
	_held_torch_root.name = "HandheldTorchRig"
	_held_torch_root.visible = false
	add_child(_held_torch_root)

	# 1. Wooden handle
	var handle_mesh: CylinderMesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.032
	handle_mesh.bottom_radius = 0.024
	handle_mesh.height = 0.65
	var handle_inst: MeshInstance3D = MeshInstance3D.new()
	handle_inst.name = "Handle"
	handle_inst.mesh = handle_mesh
	handle_inst.material_override = _mat_wood_handle
	handle_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	handle_inst.position = Vector3(0.0, 0.28, 0.0)
	_held_torch_root.add_child(handle_inst)

	# 2. Wrapped burlap torch head
	var head_mesh: CylinderMesh = CylinderMesh.new()
	head_mesh.top_radius = 0.055
	head_mesh.bottom_radius = 0.045
	head_mesh.height = 0.16
	var head_inst: MeshInstance3D = MeshInstance3D.new()
	head_inst.name = "Head"
	head_inst.mesh = head_mesh
	head_inst.material_override = _mat_burlap_head
	head_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	head_inst.position = Vector3(0.0, 0.62, 0.0)
	_held_torch_root.add_child(head_inst)

	# 3. Emissive Flame Core Mesh
	var flame_mesh: SphereMesh = SphereMesh.new()
	flame_mesh.radius = 0.075
	flame_mesh.height = 0.18
	_held_flame_mesh = MeshInstance3D.new()
	_held_flame_mesh.name = "FlameCore"
	_held_flame_mesh.mesh = flame_mesh
	_held_flame_mesh.material_override = _mat_flame
	_held_flame_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_held_flame_mesh.position = Vector3(0.0, 0.74, 0.0)
	_held_torch_root.add_child(_held_flame_mesh)

	# 4. Intel Iris Xe Budgeted OmniLight3D (No shadows, tight attenuation)
	_held_light = OmniLight3D.new()
	_held_light.name = "TorchLight"
	_held_light.omni_range = torch_light_range
	_held_light.omni_attenuation = 1.35
	_held_light.light_energy = torch_light_energy
	_held_light.light_color = torch_light_color
	_held_light.shadow_enabled = false
	_held_light.position = Vector3(0.0, 0.78, 0.0)
	_held_torch_root.add_child(_held_light)

	# 4b. Floating embers & sparks (Intel Iris Xe safe: 8 particles, unshaded)
	_held_sparks = _create_spark_particles(8, 0.04)
	_held_sparks.position = Vector3(0.0, 0.76, 0.0)
	_held_torch_root.add_child(_held_sparks)

	# 4c. Soft rising smoke wisps (4 particles)
	_held_smoke = _create_smoke_particles(4, 0.07)
	_held_smoke.position = Vector3(0.0, 0.82, 0.0)
	_held_torch_root.add_child(_held_smoke)

	# 5. Audio Player for crackle & sizzle
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "TorchAudioPlayer"
	_audio_player.max_distance = 24.0
	_audio_player.unit_size = 3.0
	_held_torch_root.add_child(_audio_player)

## Toggles the handheld torch on/off
func toggle_held_torch() -> bool:
	if not is_torch_held:
		equip_held_torch()
	else:
		unequip_held_torch()
	return is_torch_held

func equip_held_torch() -> void:
	is_torch_held = true
	is_torch_lit = true
	if _held_torch_root:
		_held_torch_root.visible = true
	if _held_light:
		_held_light.visible = true
	if _held_flame_mesh:
		_held_flame_mesh.visible = true
	if _held_sparks:
		_held_sparks.emitting = true
		_held_sparks.visible = true
	if _held_smoke:
		_held_smoke.emitting = true
		_held_smoke.visible = true
	_play_audio(_cached_whoosh_wav, -8.0)
	torch_toggled.emit(true)
	_update_fauna_light_registry()

func unequip_held_torch() -> void:
	is_torch_held = false
	if _held_torch_root:
		_held_torch_root.visible = false
	if _held_light:
		_held_light.visible = false
	if _held_sparks:
		_held_sparks.emitting = false
	if _held_smoke:
		_held_smoke.emitting = false
	torch_toggled.emit(false)
	_update_fauna_light_registry()

func extinguish_held_torch(reason: String = "water") -> void:
	if not is_torch_lit:
		return
	is_torch_lit = false
	if _held_light:
		_held_light.visible = false
	if _held_flame_mesh:
		_held_flame_mesh.visible = false
	if _held_sparks:
		_held_sparks.emitting = false
	if _held_smoke:
		_held_smoke.emitting = false
	_play_audio(_cached_sizzle_wav, -6.0)
	torch_extinguished.emit(reason)
	_update_fauna_light_registry()

func reignite_held_torch() -> bool:
	if not is_torch_held:
		equip_held_torch()
		return true
	is_torch_lit = true
	_rain_burn_timer = 25.0
	if _held_light:
		_held_light.visible = true
	if _held_flame_mesh:
		_held_flame_mesh.visible = true
	if _held_sparks:
		_held_sparks.emitting = true
		_held_sparks.visible = true
	if _held_smoke:
		_held_smoke.emitting = true
		_held_smoke.visible = true
	_play_audio(_cached_whoosh_wav, -8.0)
	torch_toggled.emit(true)
	_update_fauna_light_registry()
	return true

## Places a permanent torch standing in the ground at target position
func place_torch_at(hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> Node3D:
	if _placed_torches.size() >= MAX_PLACED_TORCHES:
		var oldest: Node3D = _placed_torches.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var torch_node: Node3D = Node3D.new()
	torch_node.name = "PlacedTorch_%d" % _placed_torches.size()
	torch_node.position = hit_pos

	# Align with normal if slope
	if hit_normal.dot(Vector3.UP) < 0.98 and hit_normal.length_squared() > 0.1:
		var axis: Vector3 = Vector3.UP.cross(hit_normal).normalized()
		var angle: float = acos(clampf(Vector3.UP.dot(hit_normal), -1.0, 1.0))
		if axis.length_squared() > 0.01:
			torch_node.rotate(axis, angle * 0.45)

	# 1. Wooden stake post
	var post_mesh: CylinderMesh = CylinderMesh.new()
	post_mesh.top_radius = 0.035
	post_mesh.bottom_radius = 0.025
	post_mesh.height = 0.95
	var post_inst: MeshInstance3D = MeshInstance3D.new()
	post_inst.name = "Post"
	post_inst.mesh = post_mesh
	post_inst.material_override = _mat_wood_handle
	post_inst.position = Vector3(0.0, 0.45, 0.0)
	post_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	torch_node.add_child(post_inst)

	# 2. Wrapped head
	var head_mesh: CylinderMesh = CylinderMesh.new()
	head_mesh.top_radius = 0.058
	head_mesh.bottom_radius = 0.045
	head_mesh.height = 0.18
	var head_inst: MeshInstance3D = MeshInstance3D.new()
	head_inst.name = "BurlapHead"
	head_inst.mesh = head_mesh
	head_inst.material_override = _mat_burlap_head
	head_inst.position = Vector3(0.0, 0.92, 0.0)
	head_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	torch_node.add_child(head_inst)

	# 3. Flame core
	var flame_mesh: SphereMesh = SphereMesh.new()
	flame_mesh.radius = 0.08
	flame_mesh.height = 0.20
	var flame_inst: MeshInstance3D = MeshInstance3D.new()
	flame_inst.name = "Flame"
	flame_inst.mesh = flame_mesh
	flame_inst.material_override = _mat_flame
	flame_inst.position = Vector3(0.0, 1.06, 0.0)
	flame_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	torch_node.add_child(flame_inst)

	# 4. Optional OmniLight3D (managed dynamically by distance budget)
	var omni: OmniLight3D = OmniLight3D.new()
	omni.name = "PlacedLight"
	omni.omni_range = 13.0
	omni.omni_attenuation = 1.45
	omni.light_energy = 1.6
	omni.light_color = torch_light_color
	omni.shadow_enabled = false
	omni.position = Vector3(0.0, 1.10, 0.0)
	omni.visible = true
	torch_node.add_child(omni)

	# Sparks and smoke for placed torch
	var torch_sparks: CPUParticles3D = _create_spark_particles(6, 0.035)
	torch_sparks.position = Vector3(0.0, 1.08, 0.0)
	torch_node.add_child(torch_sparks)

	torch_node.set_meta("is_lit", true)
	torch_node.set_meta("omni_ref", omni)
	torch_node.set_meta("sparks_ref", torch_sparks)

	add_child(torch_node)
	_placed_torches.append(torch_node)

	_play_audio(_cached_whoosh_wav, -8.0)
	torch_placed.emit(hit_pos)
	_update_fauna_light_registry()
	_rebalance_light_budget()
	return torch_node

## Builds a cozy wilderness campfire with stone circle, crossed logs, rising smoke and warmth aura
func place_campfire_at(hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> Node3D:
	if _placed_campfires.size() >= MAX_PLACED_CAMPFIRES:
		var oldest: Node3D = _placed_campfires.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var camp_node: Node3D = Node3D.new()
	camp_node.name = "PlacedCampfire_%d" % _placed_campfires.size()
	camp_node.position = hit_pos

	# Align with normal if on slope
	if hit_normal.dot(Vector3.UP) < 0.98 and hit_normal.length_squared() > 0.1:
		var axis: Vector3 = Vector3.UP.cross(hit_normal).normalized()
		var angle: float = acos(clampf(Vector3.UP.dot(hit_normal), -1.0, 1.0))
		if axis.length_squared() > 0.01:
			camp_node.rotate(axis, angle * 0.35)

	# 1. Perimeter stone circle (8 stones around radius 0.62m)
	for i in range(8):
		var stone_mesh: SphereMesh = SphereMesh.new()
		stone_mesh.radius = 0.12
		stone_mesh.height = 0.16
		var stone_inst: MeshInstance3D = MeshInstance3D.new()
		stone_inst.mesh = stone_mesh
		stone_inst.material_override = _mat_stone
		stone_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ang: float = float(i) * (TAU / 8.0)
		stone_inst.position = Vector3(cos(ang) * 0.62, 0.08, sin(ang) * 0.62)
		camp_node.add_child(stone_inst)

	# 2. Crossed logs in the center (4 logs)
	for i in range(4):
		var log_mesh: CylinderMesh = CylinderMesh.new()
		log_mesh.top_radius = 0.055
		log_mesh.bottom_radius = 0.065
		log_mesh.height = 0.85
		var log_inst: MeshInstance3D = MeshInstance3D.new()
		log_inst.mesh = log_mesh
		log_inst.material_override = _mat_wood_handle
		log_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var log_ang: float = float(i) * (PI / 2.0) + 0.35
		log_inst.rotation = Vector3(0.25, log_ang, 0.25)
		log_inst.position = Vector3(0.0, 0.12, 0.0)
		camp_node.add_child(log_inst)

	# 3. Glowing ember core
	var ember_mesh: CylinderMesh = CylinderMesh.new()
	ember_mesh.top_radius = 0.30
	ember_mesh.bottom_radius = 0.35
	ember_mesh.height = 0.12
	var ember_inst: MeshInstance3D = MeshInstance3D.new()
	ember_inst.mesh = ember_mesh
	ember_inst.material_override = _mat_flame
	ember_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ember_inst.position = Vector3(0.0, 0.09, 0.0)
	camp_node.add_child(ember_inst)

	# 4. Floating fire sparks (12 particles)
	var sparks: CPUParticles3D = _create_spark_particles(12, 0.05)
	sparks.position = Vector3(0.0, 0.20, 0.0)
	camp_node.add_child(sparks)

	# 5. Rising smoke column (8 particles)
	var smoke: CPUParticles3D = _create_smoke_particles(8, 0.12)
	smoke.position = Vector3(0.0, 0.25, 0.0)
	camp_node.add_child(smoke)

	# 6. Warm campfire lighting (budgeted, shadow-free)
	var omni: OmniLight3D = OmniLight3D.new()
	omni.name = "CampfireLight"
	omni.omni_range = 18.0
	omni.omni_attenuation = 1.30
	omni.light_energy = 2.4
	omni.light_color = Color(1.0, 0.65, 0.28)
	omni.shadow_enabled = false
	omni.position = Vector3(0.0, 0.45, 0.0)
	omni.visible = true
	camp_node.add_child(omni)

	# 7. Campfire continuous audio crackle
	var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	audio.name = "CampfireAudio"
	audio.stream = _cached_crackle_wav
	audio.max_distance = 28.0
	audio.unit_size = 4.0
	audio.volume_db = -6.0
	audio.autoplay = true
	camp_node.add_child(audio)

	camp_node.set_meta("is_lit", true)
	camp_node.set_meta("omni_ref", omni)
	camp_node.set_meta("sparks_ref", sparks)
	camp_node.set_meta("smoke_ref", smoke)
	camp_node.set_meta("type", "campfire")
	camp_node.set_meta("warmth_radius", 7.0)

	add_child(camp_node)
	_placed_campfires.append(camp_node)

	# Apply initial warmth to surrounding soil
	if _env_grid:
		_env_grid.apply_temperature_brush(hit_pos.x, hit_pos.z, 7.0, 6.0)

	_play_audio(_cached_whoosh_wav, -6.0)
	campfire_placed.emit(hit_pos)
	_update_fauna_light_registry()
	return camp_node

func extinguish_campfire(camp_node: Node3D, reason: String = "water") -> void:
	if not is_instance_valid(camp_node) or not camp_node.get_meta("is_lit", true):
		return
	camp_node.set_meta("is_lit", false)
	var omni: OmniLight3D = camp_node.get_meta("omni_ref", null) as OmniLight3D
	if omni:
		omni.visible = false
	var sparks: CPUParticles3D = camp_node.get_meta("sparks_ref", null) as CPUParticles3D
	if sparks:
		sparks.emitting = false
	var smoke: CPUParticles3D = camp_node.get_meta("smoke_ref", null) as CPUParticles3D
	if smoke:
		smoke.emitting = false
	_play_audio(_cached_sizzle_wav, -5.0)
	campfire_extinguished.emit(reason)
	_update_fauna_light_registry()

## Pitches an expedition field lean-to canvas shelter with cedar posts, straw bedroll and camp lantern
func place_shelter_at(hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> Node3D:
	if _placed_shelters.size() >= MAX_PLACED_SHELTERS:
		var oldest: Node3D = _placed_shelters.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var shelter_node: Node3D = Node3D.new()
	shelter_node.name = "PlacedShelter_%d" % _placed_shelters.size()
	shelter_node.position = hit_pos

	# Align with slope normal
	if hit_normal.dot(Vector3.UP) < 0.98 and hit_normal.length_squared() > 0.1:
		var axis: Vector3 = Vector3.UP.cross(hit_normal).normalized()
		var angle: float = acos(clampf(Vector3.UP.dot(hit_normal), -1.0, 1.0))
		if axis.length_squared() > 0.01:
			shelter_node.rotate(axis, angle * 0.35)

	# 1. Two vertical cedar support posts
	for x_offset in [-1.1, 1.1]:
		var post_mesh: CylinderMesh = CylinderMesh.new()
		post_mesh.top_radius = 0.045
		post_mesh.bottom_radius = 0.055
		post_mesh.height = 1.65
		var post_inst: MeshInstance3D = MeshInstance3D.new()
		post_inst.mesh = post_mesh
		post_inst.material_override = _mat_wood_handle
		post_inst.position = Vector3(x_offset, 0.82, -0.6)
		shelter_node.add_child(post_inst)

	# 2. Horizontal cedar ridgepole
	var ridge_mesh: CylinderMesh = CylinderMesh.new()
	ridge_mesh.top_radius = 0.04
	ridge_mesh.bottom_radius = 0.04
	ridge_mesh.height = 2.4
	var ridge_inst: MeshInstance3D = MeshInstance3D.new()
	ridge_inst.mesh = ridge_mesh
	ridge_inst.material_override = _mat_wood_handle
	ridge_inst.rotation = Vector3(0.0, 0.0, PI / 2.0)
	ridge_inst.position = Vector3(0.0, 1.60, -0.6)
	shelter_node.add_child(ridge_inst)

	# 3. Slanted Weathered Canvas Lean-to Canopy
	var canvas_mesh: BoxMesh = BoxMesh.new()
	canvas_mesh.size = Vector3(2.35, 0.03, 1.85)
	var canvas_inst: MeshInstance3D = MeshInstance3D.new()
	canvas_inst.mesh = canvas_mesh
	canvas_inst.material_override = _mat_canvas
	canvas_inst.rotation = Vector3(deg_to_rad(40.0), 0.0, 0.0)
	canvas_inst.position = Vector3(0.0, 1.05, 0.15)
	shelter_node.add_child(canvas_inst)

	# 4. Straw bedroll mat inside shelter
	var bed_mesh: BoxMesh = BoxMesh.new()
	bed_mesh.size = Vector3(1.7, 0.08, 0.95)
	var bed_inst: MeshInstance3D = MeshInstance3D.new()
	bed_inst.mesh = bed_mesh
	bed_inst.material_override = _mat_bedroll
	bed_inst.position = Vector3(0.0, 0.04, 0.10)
	shelter_node.add_child(bed_inst)

	# 5. Hanging brass camp lantern with gentle warm glow
	var lantern_body: MeshInstance3D = MeshInstance3D.new()
	var l_mesh: CylinderMesh = CylinderMesh.new()
	l_mesh.top_radius = 0.06
	l_mesh.bottom_radius = 0.07
	l_mesh.height = 0.18
	lantern_body.mesh = l_mesh
	lantern_body.material_override = _mat_lantern
	lantern_body.position = Vector3(0.0, 1.45, -0.6)
	shelter_node.add_child(lantern_body)

	var omni: OmniLight3D = OmniLight3D.new()
	omni.name = "ShelterLanternLight"
	omni.omni_range = 7.5
	omni.omni_attenuation = 1.35
	omni.light_energy = 0.85
	omni.light_color = Color(1.0, 0.88, 0.55)
	omni.shadow_enabled = false
	omni.position = Vector3(0.0, 1.38, -0.6)
	shelter_node.add_child(omni)

	shelter_node.set_meta("is_shelter", true)
	shelter_node.set_meta("position", hit_pos)
	shelter_node.set_meta("protection_radius", 3.2)

	add_child(shelter_node)
	_placed_shelters.append(shelter_node)

	_play_audio(_cached_whoosh_wav, -6.0)
	shelter_placed.emit(hit_pos)
	return shelter_node

## Returns array of positions of all currently placed shelters
func get_all_shelter_positions() -> Array[Vector3]:
	var list: Array[Vector3] = []
	for s in _placed_shelters:
		if is_instance_valid(s):
			list.append(s.global_position if s.is_inside_tree() else s.position)
	return list

## Checks if target point is sheltered from rain storm under a placed tent
func is_point_sheltered(point: Vector3, max_dist: float = 3.2) -> bool:
	for s in _placed_shelters:
		if is_instance_valid(s):
			var sp: Vector3 = s.global_position if s.is_inside_tree() else s.position
			if point.distance_to(sp) <= max_dist:
				return true
	return false

## Rests inside shelter, fast-forwarding world clock to the next natural diurnal phase
func rest_in_shelter(world_clock: WorldClock = null) -> float:
	var clock_ref: WorldClock = world_clock if world_clock else _clock
	var cur_hour: float = clock_ref.get_time_of_day() if clock_ref else 12.0
	var next_hour: float = 6.0 # Default Dawn
	if cur_hour >= 20.0 or cur_hour < 5.0:
		next_hour = 6.0 # Dawn
	elif cur_hour >= 5.0 and cur_hour < 11.0:
		next_hour = 12.0 # Midday
	elif cur_hour >= 11.0 and cur_hour < 17.0:
		next_hour = 18.0 # Dusk
	elif cur_hour >= 17.0 and cur_hour < 20.0:
		next_hour = 22.0 # Midnight

	if clock_ref:
		clock_ref.set_time_of_day(next_hour)

	shelter_rested.emit(next_hour)
	return next_hour

## Registers a wild berry foraging bush at position
func register_forage_bush(pos: Vector3, berry_type: String = "alpine_elderberry") -> void:
	var key: String = "%.1f_%.1f" % [pos.x, pos.z]
	_forage_bushes[key] = {
		"position": pos,
		"berry_type": berry_type,
		"count": 3,
		"max_count": 3,
		"is_ripe": true,
		"regrowth_timer": 0.0
	}

## Returns the nearest wild berry bush within range
func get_nearest_forage_bush(pos: Vector3, max_dist: float = 4.5) -> Dictionary:
	var nearest: Dictionary = {}
	var min_d_sq: float = max_dist * max_dist
	for key: String in _forage_bushes.keys():
		var b: Dictionary = _forage_bushes[key]
		var b_pos: Vector3 = b["position"]
		var d_sq: float = pos.distance_squared_to(b_pos)
		if d_sq <= min_d_sq:
			min_d_sq = d_sq
			nearest = b
	return nearest

## Forages berries from bush at position
func harvest_bush_at(pos: Vector3) -> Dictionary:
	var bush: Dictionary = get_nearest_forage_bush(pos, 4.5)
	if bush.is_empty():
		register_forage_bush(pos, "alpine_elderberry")
		bush = _forage_bushes["%.1f_%.1f" % [pos.x, pos.z]]

	if not bush.get("is_ripe", false):
		return {
			"success": false,
			"reason": "dormant",
			"regrowth_left": bush.get("regrowth_timer", 0.0)
		}

	var berry_type: String = bush.get("berry_type", "alpine_elderberry")
	var count: int = bush.get("count", 3)
	bush["count"] = 0
	bush["is_ripe"] = false
	bush["regrowth_timer"] = 45.0

	foraged_berries_inventory[berry_type] = foraged_berries_inventory.get(berry_type, 0) + count
	var total: int = get_total_foraged_berries()

	berries_harvested.emit(berry_type, count, total)
	return {
		"success": true,
		"berry_type": berry_type,
		"count": count,
		"nutrition": float(count) * 18.0,
		"total_inventory": total
	}

## Feeds a nearby herbivore with foraged berries, calming it and boosting energy
func feed_nearby_herbivore(pos: Vector3, fauna_sim: FaunaSimulation = null, max_dist: float = 6.0) -> Dictionary:
	var total: int = get_total_foraged_berries()
	if total <= 0:
		return {"success": false, "reason": "no_berries"}

	var fsim: FaunaSimulation = fauna_sim if fauna_sim else _fauna_sim
	if not fsim:
		return {"success": false, "reason": "no_fauna_sim"}

	# Find closest herbivore
	var herbivores: Array = fsim.get_all_herbivores()
	var closest_h: Variant = null
	var min_dist: float = max_dist
	for h in herbivores:
		var d: float = pos.distance_to(h.position)
		if d < min_dist:
			min_dist = d
			closest_h = h

	if closest_h == null:
		return {"success": false, "reason": "no_herbivore_nearby"}

	var used_type: String = "alpine_elderberry"
	if foraged_berries_inventory.get("alpine_elderberry", 0) > 0:
		foraged_berries_inventory["alpine_elderberry"] -= 1
		used_type = "alpine_elderberry"
	elif foraged_berries_inventory.get("glade_blueberry", 0) > 0:
		foraged_berries_inventory["glade_blueberry"] -= 1
		used_type = "glade_blueberry"
	elif foraged_berries_inventory.get("amber_cloudberry", 0) > 0:
		foraged_berries_inventory["amber_cloudberry"] -= 1
		used_type = "amber_cloudberry"

	closest_h.energy = clampf(closest_h.energy + 35.0, 0.0, 100.0)
	closest_h.threat_memory = 0.0
	closest_h.flee_timer = 0.0
	closest_h.state = FaunaSimulation.HerbivoreState.EATING

	herbivore_fed.emit(closest_h.id, used_type)
	return {
		"success": true,
		"herbivore_id": closest_h.id,
		"berry_type": used_type,
		"herbivore_energy": closest_h.energy
	}

## Steps regrowth timers for harvested bushes
func step_foraging_simulation(delta: float) -> void:
	for key in _forage_bushes.keys():
		var b: Dictionary = _forage_bushes[key]
		if not b.get("is_ripe", false):
			var timer: float = b.get("regrowth_timer", 0.0) - delta
			if timer <= 0.0:
				b["is_ripe"] = true
				b["count"] = b.get("max_count", 3)
				b["regrowth_timer"] = 0.0
			else:
				b["regrowth_timer"] = timer

func get_total_foraged_berries() -> int:
	var sum_val: int = 0
	for k in foraged_berries_inventory.keys():
		sum_val += int(foraged_berries_inventory[k])
	return sum_val

func get_forage_inventory() -> Dictionary:
	return foraged_berries_inventory.duplicate()

## Ignites dry grass/brush creating a fertile ash circle that drives ecological regrowth
func ignite_ground_at(burn_center: Vector3, radius: float = 3.5) -> Dictionary:
	var result: Dictionary = {
		"position": burn_center,
		"radius": radius,
		"plants_cleared": 0,
		"cells_enriched": 0
	}

	# 1. Enrich soil in EnvironmentalGrid
	if _env_grid:
		result["cells_enriched"] = _env_grid.apply_ash_enrichment(burn_center.x, burn_center.z, radius + 1.5)

	# 2. Clear old biomass in FloraSimulation
	if _flora_sim:
		result["plants_cleared"] = _flora_sim.apply_fire_burn(burn_center, radius)

	# 3. Create visual Ash Decal on ground
	var decal_node: MeshInstance3D = MeshInstance3D.new()
	decal_node.name = "AshDecal"
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.03
	decal_node.mesh = disc
	decal_node.material_override = _mat_ash_decal
	decal_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	decal_node.position = burn_center + Vector3(0.0, 0.02, 0.0)
	add_child(decal_node)

	# Fade out decal over 120 seconds
	var tween: Tween = create_tween()
	if tween:
		tween.tween_property(decal_node, "scale", Vector3.ZERO, 120.0).set_delay(60.0)
		tween.tween_callback(Callable(decal_node, "queue_free"))

	_play_audio(_cached_whoosh_wav, -6.0)
	combustion_created.emit(burn_center, radius)
	return result

func _process(delta: float) -> void:
	_time_accum += delta

	# 1. Animate soft flickering flame on held torch
	if is_torch_held and is_torch_lit and _held_light:
		var flicker: float = sin(_time_accum * 13.5) * 0.12 + sin(_time_accum * 26.0) * 0.07 + (randf() - 0.5) * 0.03
		_held_light.light_energy = clampf(torch_light_energy + flicker, 1.2, 2.3)
		if _held_flame_mesh:
			var scale_flicker: float = 1.0 + flicker * 0.15
			_held_flame_mesh.scale = Vector3(scale_flicker, 1.0 + flicker * 0.30, scale_flicker)

	# 2. Water Immersion Extinguishment Check
	if is_torch_held and is_torch_lit:
		var cur_y: float = global_position.y if is_inside_tree() else position.y
		if cur_y <= (_water_height + 0.35):
			extinguish_held_torch("water")

	# 2b. Campfire Water Immersion Extinguishment Check
	for c in _placed_campfires:
		if is_instance_valid(c) and c.get_meta("is_lit", true):
			var cp: Vector3 = c.global_position if c.is_inside_tree() else c.position
			if cp.y <= (_water_height + 0.35):
				extinguish_campfire(c, "water")

	# 3. Heavy Rain Extinguishment Check
	if is_torch_held and is_torch_lit and _weather:
		if _weather.current_state == WeatherSystem.WeatherState.RAIN:
			# Check overhead clearance (unsheltered check)
			var is_under_roof: bool = _is_overhead_sheltered()
			if not is_under_roof:
				_rain_burn_timer -= delta
				if _rain_burn_timer <= 0.0:
					extinguish_held_torch("rain")
			else:
				_rain_burn_timer = 25.0
		else:
			_rain_burn_timer = 25.0

	# 3b. Campfire Warmth Aura Pulse (Every 2 seconds)
	_warmth_timer += delta
	if _warmth_timer >= 2.0:
		_warmth_timer = 0.0
		if _env_grid:
			for c in _placed_campfires:
				if is_instance_valid(c) and c.get_meta("is_lit", true):
					var cp: Vector3 = c.global_position if c.is_inside_tree() else c.position
					var r: float = float(c.get_meta("warmth_radius", 7.0))
					_env_grid.apply_temperature_brush(cp.x, cp.z, r, 1.5)

	# 4. Light budget culling periodically (every 0.5s)
	_budget_check_timer += delta
	if _budget_check_timer >= 0.5:
		_budget_check_timer = 0.0
		_rebalance_light_budget()
		_update_fauna_light_registry()

	# 5. Step wild berry regrowth timers
	step_foraging_simulation(delta)

func _is_overhead_sheltered() -> bool:
	var p: Vector3 = global_position if is_inside_tree() else position
	# Placed Lean-to Canvas Shelter protection
	if is_point_sheltered(p, 3.2):
		return true
	# Whispering Grotto cavern boundary (-125 to -60, -135 to -70)
	if p.x >= -125.0 and p.x <= -60.0 and p.z >= -135.0 and p.z <= -70.0:
		return true
	# Whispering Forest deep canopy stand (-185 to -5, -65 to 95)
	if p.x >= -60.0 and p.x <= -10.0 and p.z >= -30.0 and p.z <= 30.0:
		return true
	return false

func _rebalance_light_budget() -> void:
	if _placed_torches.is_empty():
		return

	var my_pos: Vector3 = global_position if is_inside_tree() else position
	# Sort placed torches by distance
	_placed_torches.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		var pos_a: Vector3 = a.global_position if a.is_inside_tree() else a.position
		var pos_b: Vector3 = b.global_position if b.is_inside_tree() else b.position
		return pos_a.distance_squared_to(my_pos) < pos_b.distance_squared_to(my_pos)
	)

	# Only first MAX_ACTIVE_PLACED_LIGHTS have active OmniLight3D
	for i in range(_placed_torches.size()):
		var t: Node3D = _placed_torches[i]
		if not is_instance_valid(t):
			continue
		var omni: OmniLight3D = t.get_meta("omni_ref", null) as OmniLight3D
		if omni:
			omni.visible = (i < MAX_ACTIVE_PLACED_LIGHTS)

func _update_fauna_light_registry() -> void:
	if not _fauna_sim:
		return

	var sources: Array[Vector3] = []
	if is_torch_held and is_torch_lit:
		sources.append(global_position if is_inside_tree() else position)

	for t in _placed_torches:
		if is_instance_valid(t) and t.get_meta("is_lit", true):
			sources.append(t.global_position if t.is_inside_tree() else t.position)

	for c in _placed_campfires:
		if is_instance_valid(c) and c.get_meta("is_lit", true):
			sources.append(c.global_position if c.is_inside_tree() else c.position)

	_fauna_sim.set_active_light_sources(sources)

func _play_audio(stream: AudioStream, volume_db: float = -10.0) -> void:
	if _audio_player and stream and is_inside_tree():
		_audio_player.stream = stream
		_audio_player.volume_db = volume_db
		_audio_player.pitch_scale = randf_range(0.95, 1.05)
		_audio_player.play()

func get_all_active_light_positions() -> Array[Vector3]:
	var list: Array[Vector3] = []
	if is_torch_held and is_torch_lit:
		list.append(global_position if is_inside_tree() else position)
	for t in _placed_torches:
		if is_instance_valid(t) and t.get_meta("is_lit", true):
			list.append(t.global_position if t.is_inside_tree() else t.position)
	for c in _placed_campfires:
		if is_instance_valid(c) and c.get_meta("is_lit", true):
			list.append(c.global_position if c.is_inside_tree() else c.position)
	return list

# Procedural Micro-Particle Generators for Fire Atmosphere (Intel Iris Xe safe)
static func _create_spark_particles(amount: int = 8, scale: float = 0.04) -> CPUParticles3D:
	var parts: CPUParticles3D = CPUParticles3D.new()
	parts.amount = amount
	parts.lifetime = 0.75
	parts.speed_scale = 1.0
	parts.explosiveness = 0.0
	parts.randomness = 0.6
	parts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	parts.emission_sphere_radius = 0.08
	parts.direction = Vector3(0.0, 1.0, 0.0)
	parts.spread = 30.0
	parts.gravity = Vector3(0.0, 1.8, 0.0)
	parts.initial_velocity_min = 0.4
	parts.initial_velocity_max = 1.1
	parts.scale_amount_min = scale * 0.7
	parts.scale_amount_max = scale * 1.3
	parts.color = Color(1.0, 0.65, 0.15, 0.95)

	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.025
	mesh.height = 0.05
	mesh.radial_segments = 4
	mesh.rings = 2
	parts.mesh = mesh
	parts.material_override = _mat_flame
	return parts

static func _create_smoke_particles(amount: int = 4, scale: float = 0.08) -> CPUParticles3D:
	var parts: CPUParticles3D = CPUParticles3D.new()
	parts.amount = amount
	parts.lifetime = 1.5
	parts.speed_scale = 0.85
	parts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	parts.emission_sphere_radius = 0.06
	parts.direction = Vector3(0.0, 1.0, 0.0)
	parts.spread = 18.0
	parts.gravity = Vector3(0.0, 0.8, 0.0)
	parts.initial_velocity_min = 0.25
	parts.initial_velocity_max = 0.65
	parts.scale_amount_min = scale * 0.8
	parts.scale_amount_max = scale * 2.2
	parts.color = Color(0.65, 0.65, 0.70, 0.20)

	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.035
	mesh.height = 0.07
	mesh.radial_segments = 4
	mesh.rings = 2
	parts.mesh = mesh
	parts.material_override = _mat_ash_decal
	return parts

# Procedural Audio Synthesizers (Clean CC0 16-bit PCM)
static func _generate_ignite_whoosh(duration: float = 0.35, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)
	var lp: float = 0.0

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var norm_t: float = t / duration
		var env: float = sin(norm_t * PI) * 0.45
		var white: float = (randf() * 2.0 - 1.0)
		# Lowpass sweep 320 -> 180 Hz
		var cutoff: float = lerpf(0.18, 0.08, norm_t)
		lp += cutoff * (white - lp)
		var sample: float = lp * env
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = byte_data
	return wav

static func _generate_sizzle_wav(duration: float = 0.65, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)
	var bp_y1: float = 0.0
	var bp_y2: float = 0.0

	for i in range(num_samples):
		var t: float = float(i) / float(rate)
		var norm_t: float = t / duration
		var env: float = exp(-norm_t * 5.2) * 0.38
		var white: float = (randf() * 2.0 - 1.0)
		# 3800 Hz steam hiss resonator
		var bp: float = 0.45 * white + 0.65 * bp_y1 - 0.40 * bp_y2
		bp_y2 = bp_y1
		bp_y1 = bp
		var sample: float = bp * env
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = byte_data
	return wav

static func _generate_crackle_loop(duration: float = 2.0, rate: int = 22050) -> AudioStreamWAV:
	var num_samples: int = int(duration * rate)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples * 2)

	for i in range(num_samples):
		var white: float = (randf() * 2.0 - 1.0) * 0.06
		# Occasional crisp ember snap pop
		var pop: float = 0.0
		if randf() < 0.003:
			pop = (randf() * 2.0 - 1.0) * 0.35
		var sample: float = white + pop
		var val_16: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = byte_data
	return wav
