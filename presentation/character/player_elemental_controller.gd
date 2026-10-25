class_name PlayerElementalController
extends Node3D

## Living Planet Sandbox — Genshin-Style Player Elemental Arts & Reaction Controller (Block 64)
## Implements:
## 1. Elemental Affinity Cycling [Z]: Anemo (Phong) -> Pyro (Hỏa) -> Hydro (Thủy) -> Cryo (Băng).
## 2. Elemental Skill Cast [Q]:
##    - Pyro: Casts flame arc, ignites wildfire, spawns thermal updrafts, melts ice.
##    - Hydro: Casts water crescent, saturates soil, douses wildfires, revives flora.
##    - Cryo: Casts frost nova, freezes water into walkable ice platforms, freezes wet targets.
##    - Anemo: Casts vortex pulse, swirls elements and boosts glider flight.
## 3. Elemental Reaction Matrix integration (Vaporize, Melt, Frozen, Swirl).
## 4. Audio & VFX synthesis tailored for 60 FPS on Intel Iris Xe.

const ElementalReactionMatrix = preload("res://core/elements/elemental_reaction_matrix.gd")
const WildfireSpreadSystem = preload("res://presentation/elements/wildfire_spread_system.gd")
const IcePlatformSystem = preload("res://presentation/elements/ice_platform_system.gd")

signal element_changed(elem: int, elem_name: String, icon: String, color: Color)
signal skill_cast(elem: int, origin: Vector3, dir: Vector3)
signal reaction_triggered(reaction_type: int, reaction_name: String, pos: Vector3, color: Color)
signal soil_irrigated(grid_cell: Vector2i)

const SKILL_COOLDOWN_TIME: float = 3.5

# State
var current_element: int = ElementalReactionMatrix.Element.ANEMO
var skill_cooldown: float = 0.0
var _anim_time: float = 0.0

# System references
var _wildfire_sys: WildfireSpreadSystem = null
var _ice_sys: IcePlatformSystem = null
var _env_grid: RefCounted = null # EnvironmentalGrid
var _flora_sim: RefCounted = null # FloraSimulation
var _terrain_ref: Node = null

# Audio
static var _pyro_wav: AudioStreamWAV = null
static var _hydro_wav: AudioStreamWAV = null
static var _cryo_wav: AudioStreamWAV = null
static var _anemo_wav: AudioStreamWAV = null
var _audio_player: AudioStreamPlayer3D = null

func _init() -> void:
	name = "PlayerElementalController"
	_init_audio()

func setup(wildfire_sys: WildfireSpreadSystem = null, ice_sys: IcePlatformSystem = null, env_grid: RefCounted = null, flora_sim: RefCounted = null, terrain: Node = null) -> void:
	_wildfire_sys = wildfire_sys
	_ice_sys = ice_sys
	_env_grid = env_grid
	_flora_sim = flora_sim
	_terrain_ref = terrain
	_build_audio_emitter()

func _build_audio_emitter() -> void:
	if _audio_player != null:
		return
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "ElementalAudioPlayer"
	_audio_player.unit_size = 5.0
	_audio_player.max_distance = 25.0
	add_child(_audio_player)

static func _init_audio() -> void:
	if _pyro_wav != null:
		return
	_pyro_wav = _generate_element_wav(650.0, 180.0, 0.38) # Deep flame roar
	_hydro_wav = _generate_element_wav(850.0, 320.0, 0.42) # Liquid splash surge
	_cryo_wav = _generate_element_wav(1450.0, 800.0, 0.35) # High crystal chime
	_anemo_wav = _generate_element_wav(520.0, 1100.0, 0.40) # Swirling wind gust

func update(delta: float) -> void:
	_anim_time += delta
	if skill_cooldown > 0.0:
		skill_cooldown = maxf(0.0, skill_cooldown - delta)

func cycle_element() -> int:
	match current_element:
		ElementalReactionMatrix.Element.ANEMO:
			current_element = ElementalReactionMatrix.Element.PYRO
		ElementalReactionMatrix.Element.PYRO:
			current_element = ElementalReactionMatrix.Element.HYDRO
		ElementalReactionMatrix.Element.HYDRO:
			current_element = ElementalReactionMatrix.Element.CRYO
		ElementalReactionMatrix.Element.CRYO:
			current_element = ElementalReactionMatrix.Element.ANEMO
		_:
			current_element = ElementalReactionMatrix.Element.ANEMO

	var e_name: String = ElementalReactionMatrix.get_element_name(current_element)
	var icon: String = ElementalReactionMatrix.get_element_icon(current_element)
	var col: Color = ElementalReactionMatrix.get_element_color(current_element)
	element_changed.emit(current_element, e_name, icon, col)
	return current_element

func set_element(elem: int) -> void:
	current_element = elem
	var e_name: String = ElementalReactionMatrix.get_element_name(current_element)
	var icon: String = ElementalReactionMatrix.get_element_icon(current_element)
	var col: Color = ElementalReactionMatrix.get_element_color(current_element)
	element_changed.emit(current_element, e_name, icon, col)

func is_skill_ready() -> bool:
	return skill_cooldown <= 0.0

func get_cooldown_ratio() -> float:
	return clampf(skill_cooldown / SKILL_COOLDOWN_TIME, 0.0, 1.0)

## Casts active elemental skill in direction. Returns Dictionary of results.
func cast_skill(origin: Vector3, forward_dir: Vector3) -> Dictionary:
	if not is_skill_ready():
		return {"success": false, "reason": "cooldown", "time_left": skill_cooldown}

	skill_cooldown = SKILL_COOLDOWN_TIME
	var dir: Vector3 = forward_dir.normalized()
	if dir.length_squared() < 0.001:
		dir = Vector3.FORWARD

	var target_pos: Vector3 = origin + dir * 6.5
	if _terrain_ref and _terrain_ref.has_method("get_height_at"):
		var h: float = _terrain_ref.get_height_at(target_pos.x, target_pos.z)
		target_pos.y = maxf(h, target_pos.y)

	var result: Dictionary = {
		"success": true,
		"element": current_element,
		"element_name": ElementalReactionMatrix.get_element_name(current_element),
		"origin": origin,
		"target_pos": target_pos,
		"reactions": []
	}

	_play_element_audio(current_element, origin)

	# 1. Spawn Visual Elemental Arc Mesh / Blast
	_spawn_skill_vfx(current_element, origin, dir)

	# 2. Execute Element-Specific World Reactions
	match current_element:
		ElementalReactionMatrix.Element.PYRO:
			_execute_pyro_skill(target_pos, result)
		ElementalReactionMatrix.Element.HYDRO:
			_execute_hydro_skill(target_pos, result)
		ElementalReactionMatrix.Element.CRYO:
			_execute_cryo_skill(target_pos, result)
		ElementalReactionMatrix.Element.ANEMO:
			_execute_anemo_skill(target_pos, result)

	skill_cast.emit(current_element, origin, dir)
	return result

func _execute_pyro_skill(target_pos: Vector3, result: Dictionary) -> void:
	# 1. Melt any IcePlatform within radius
	if _ice_sys:
		var melted: int = _ice_sys.melt_at(target_pos, 4.5)
		if melted > 0:
			result["reactions"].append("MELT")
			reaction_triggered.emit(ElementalReactionMatrix.ReactionType.MELT, "TAN CHẢY (MELT)", target_pos, Color(1.0, 0.65, 0.3))

	# 2. Check if near water/douse -> Vaporize
	if target_pos.y <= 0.3:
		result["reactions"].append("VAPORIZE")
		reaction_triggered.emit(ElementalReactionMatrix.ReactionType.VAPORIZE, "BỐC HƠI (VAPORIZE)", target_pos, Color(0.85, 0.85, 1.0))
	else:
		# 3. Ignite grassland & spawn thermal updrafts
		if _wildfire_sys:
			var ignited: bool = _wildfire_sys.ignite_at(target_pos, 2.8)
			if ignited:
				result["reactions"].append("BURNING")
				reaction_triggered.emit(ElementalReactionMatrix.ReactionType.BURNING, "ĐỐT CHÁY (BURNING & UPDRAFT)", target_pos, Color(1.0, 0.45, 0.15))

func _execute_hydro_skill(target_pos: Vector3, result: Dictionary) -> void:
	# 1. Douse any wildfire within radius with vaporize steam
	if _wildfire_sys:
		var doused: int = _wildfire_sys.douse_at(target_pos, 5.0)
		if doused > 0:
			result["reactions"].append("VAPORIZE")
			reaction_triggered.emit(ElementalReactionMatrix.ReactionType.VAPORIZE, "BỐC HƠI DẬP LỬA (VAPORIZE)", target_pos, Color(0.75, 0.9, 1.0))

	# 2. Saturate soil in EnvironmentalGrid
	if _env_grid and _env_grid.has_method("get_cell_coords") and _env_grid.has_method("get_cell"):
		var coords: Vector2i = _env_grid.get_cell_coords(Vector2(target_pos.x, target_pos.z))
		var cell = _env_grid.get_cell(coords.x, coords.y)
		if cell:
			cell.soil_moisture = 1.0
			cell.water_availability = 1.0
			soil_irrigated.emit(coords)
			result["reactions"].append("IRRIGATED")

	# 3. Revitalize wilted plants in FloraSimulation
	if _flora_sim and _flora_sim.has_method("get_plants_in_radius"):
		var plants: Array = _flora_sim.get_plants_in_radius(target_pos, 8.0)
		for p in plants:
			if "vitality" in p:
				p.vitality = minf(100.0, p.vitality + 35.0)
			if "growth_stage" in p and p.growth_stage == 4: # DECAYING
				p.growth_stage = 3 # MATURE

func _execute_cryo_skill(target_pos: Vector3, result: Dictionary) -> void:
	# 1. Freeze water surface into traversable ice sheet
	if target_pos.y <= 0.4 and _ice_sys:
		var frozen: bool = _ice_sys.freeze_at(target_pos, 3.4)
		if frozen:
			result["reactions"].append("FROZEN")
			reaction_triggered.emit(ElementalReactionMatrix.ReactionType.FROZEN, "ĐÓNG BĂNG MẶT NƯỚC (FROZEN ICE SHEET)", target_pos, Color(0.45, 0.88, 1.0))

	# 2. Extinguish fires in smaller radius (smothers flame)
	if _wildfire_sys:
		var doused: int = _wildfire_sys.douse_at(target_pos, 3.2)
		if doused > 0:
			result["reactions"].append("MELT")

func _execute_anemo_skill(target_pos: Vector3, result: Dictionary) -> void:
	# Swirl dispersion
	var has_fire: bool = _wildfire_sys.is_position_near_fire(target_pos, 5.0) if _wildfire_sys else false
	var has_ice: bool = _ice_sys.is_position_on_ice(target_pos, 2.0) if _ice_sys else false

	if has_fire:
		result["reactions"].append("SWIRL_PYRO")
		reaction_triggered.emit(ElementalReactionMatrix.ReactionType.SWIRL, "KHUẾCH TÁN HỎA (PYRO SWIRL)", target_pos, Color(1.0, 0.5, 0.2))
	elif has_ice:
		result["reactions"].append("SWIRL_CRYO")
		reaction_triggered.emit(ElementalReactionMatrix.ReactionType.SWIRL, "KHUẾCH TÁN BĂNG (CRYO SWIRL)", target_pos, Color(0.6, 0.9, 1.0))
	else:
		result["reactions"].append("SWIRL_ANEMO")
		reaction_triggered.emit(ElementalReactionMatrix.ReactionType.SWIRL, "PHONG ÁP LỐC XOÁY (ANEMO VORTEX)", target_pos, Color(0.35, 0.95, 0.78))

func _spawn_skill_vfx(elem: int, origin: Vector3, dir: Vector3) -> void:
	var vfx_node: Node3D = Node3D.new()
	vfx_node.position = origin + dir * 1.2
	if dir.length_squared() > 0.001:
		var safe_up: Vector3 = Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.98 else Vector3.FORWARD
		vfx_node.basis = Basis.looking_at(dir, safe_up)
	add_child(vfx_node)

	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var col: Color = ElementalReactionMatrix.get_element_color(elem)

	# Curved energy slash arc
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.35
	torus.rings = 10
	torus.ring_segments = 6
	mesh_inst.mesh = torus

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	mesh_inst.rotation.x = deg_to_rad(90.0)
	vfx_node.add_child(mesh_inst)

	# Animate forward and fade
	var tween: Tween = create_tween()
	tween.tween_property(vfx_node, "position", origin + dir * 6.5, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(vfx_node, "scale", Vector3(1.8, 1.8, 1.8), 0.32)
	tween.tween_callback(vfx_node.queue_free)

func _play_element_audio(elem: int, pos: Vector3) -> void:
	if not _audio_player or not is_inside_tree():
		return
	var stream: AudioStreamWAV = null
	match elem:
		ElementalReactionMatrix.Element.PYRO: stream = _pyro_wav
		ElementalReactionMatrix.Element.HYDRO: stream = _hydro_wav
		ElementalReactionMatrix.Element.CRYO: stream = _cryo_wav
		ElementalReactionMatrix.Element.ANEMO: stream = _anemo_wav
	if stream:
		_audio_player.stream = stream
		_audio_player.position = pos
		_audio_player.pitch_scale = randf_range(0.96, 1.04)
		_audio_player.play()

static func _generate_element_wav(base_freq: float, end_freq: float, dur: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * dur)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var progress: float = t / dur
		var freq: float = lerpf(base_freq, end_freq, progress)
		var env: float = sin(PI * progress) # Smooth attack & decay
		var s: float = sin(2.0 * PI * freq * t) * 0.65
		var overtone: float = sin(2.0 * PI * freq * 2.02 * t) * 0.35
		var sample: float = (s + overtone) * env * 0.7
		var val_16: int = int(clampf(sample * 32767.0, -32768.0, 32767.0))
		byte_array.encode_s16(i * 2, val_16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav
