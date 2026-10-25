class_name AncientSteleInscription
extends Node3D

## Living Planet Sandbox — Genshin-Style Ancient Stele Inscription (Bia Cổ Ngữ Ngàn Đời) (Block 57)
## Ancient monumental stele inscribed with forgotten lore of the Wind Realm:
## 1. Monolithic Architecture:
##    - 2-tier stepped granite plinth with decorative gold filigree cornices.
##    - Tall monolithic upright slab with glowing runic glyph engravings.
##    - Nighttime & Eagle Eye luminescence: ancient glyphs pulse with cyan-gold emission.
## 2. Interaction & Lore Deciphering:
##    - Interacting [E] triggers reading ritual:
##      Deciphers ancient inscription: "Nơi phong linh thức giấc, ngàn đời bí mật sẽ mở lối..."
##    - Procedural 16-bit PCM resonant stone chime synthesizer.
##    - Victory rewards: +150 EXP, +60 Haven Coins, Title "Học Giả Cổ Ngữ".
## 3. Intel Iris Xe optimized: shared standard materials, 60 FPS budgeted.

signal stele_read(title: String, inscription_text: String, reward: Dictionary)

# State
var is_read: bool = false
var _anim_time: float = 0.0

# Node References
var _stele_slab: MeshInstance3D = null
var _glyph_bands: Array[MeshInstance3D] = []
var _audio_player: AudioStreamPlayer3D = null
var _stele_light: OmniLight3D = null

# Materials
static var _granite_mat: StandardMaterial3D = null
static var _glyph_glow_mat: StandardMaterial3D = null
static var _gold_filigree_mat: StandardMaterial3D = null
static var _stele_chime_wav: AudioStreamWAV = null

const ANCIENT_INSCRIPTION_TEXT: String = "«Nơi đại phong ngưng đọng trên đỉnh đá hoang vu, bốn ngọn lửa thần và cánh cổng ngàn đời sẽ thức tỉnh trước kẻ mang trái tim dũng cảm của gió trời.»"

func _init() -> void:
	name = "AncientSteleInscription"
	_init_materials()
	_init_audio()
	_build_stele_monument()

static func _init_materials() -> void:
	if _granite_mat != null:
		return

	# Ancient Weathered Dark Granite
	_granite_mat = StandardMaterial3D.new()
	_granite_mat.albedo_color = Color(0.32, 0.34, 0.36)
	_granite_mat.roughness = 0.88

	# Glowing Ancient Cyan Glyph Inscription
	_glyph_glow_mat = StandardMaterial3D.new()
	_glyph_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glyph_glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_glyph_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glyph_glow_mat.albedo_color = Color(0.28, 0.90, 0.85, 0.85)

	# Ornate Weathered Gold Trim
	_gold_filigree_mat = StandardMaterial3D.new()
	_gold_filigree_mat.albedo_color = Color(0.92, 0.78, 0.28)
	_gold_filigree_mat.metallic = 0.80
	_gold_filigree_mat.roughness = 0.35

func _init_audio() -> void:
	if _stele_chime_wav == null:
		_stele_chime_wav = _generate_stele_chime_wav()

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "SteleAudio"
	_audio_player.stream = _stele_chime_wav
	_audio_player.unit_size = 10.0
	_audio_player.max_distance = 45.0
	_audio_player.volume_db = 0.0
	add_child(_audio_player)

# =============================================================================
# MONUMENT ARCHITECTURE BUILDER
# =============================================================================
func _build_stele_monument() -> void:
	# 1. Stepped Plinth
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(2.4, 0.35, 1.8)
	var b_mi = MeshInstance3D.new()
	b_mi.mesh = base_mesh
	b_mi.material_override = _granite_mat
	b_mi.position.y = 0.175
	add_child(b_mi)

	var sub_mesh = BoxMesh.new()
	sub_mesh.size = Vector3(1.8, 0.25, 1.3)
	var s_mi = MeshInstance3D.new()
	s_mi.mesh = sub_mesh
	s_mi.material_override = _granite_mat
	s_mi.position.y = 0.475
	add_child(s_mi)

	# 2. Upright Monolithic Stele Slab
	var slab_mesh = BoxMesh.new()
	slab_mesh.size = Vector3(1.3, 3.2, 0.42)
	_stele_slab = MeshInstance3D.new()
	_stele_slab.mesh = slab_mesh
	_stele_slab.material_override = _granite_mat
	_stele_slab.position.y = 2.2
	add_child(_stele_slab)

	# 3. Triangular Peaked Capstone
	var cap_mesh = PrismMesh.new()
	cap_mesh.size = Vector3(1.4, 0.55, 0.48)
	var c_mi = MeshInstance3D.new()
	c_mi.mesh = cap_mesh
	c_mi.material_override = _gold_filigree_mat
	c_mi.position.y = 4.05
	add_child(c_mi)

	# 4. Inscribed Ancient Glyph Tablets (Front and Back faces)
	for face_z in [-0.22, 0.22]:
		for row in range(4):
			var glyph_mesh = BoxMesh.new()
			glyph_mesh.size = Vector3(0.85, 0.08, 0.02)
			var g_mi = MeshInstance3D.new()
			g_mi.mesh = glyph_mesh
			g_mi.material_override = _glyph_glow_mat
			g_mi.position = Vector3(0.0, 1.5 + float(row) * 0.45, face_z)
			add_child(g_mi)
			_glyph_bands.append(g_mi)

	# 5. Mystic Runelight
	_stele_light = OmniLight3D.new()
	_stele_light.light_color = Color(0.25, 0.90, 0.85)
	_stele_light.light_energy = 1.2
	_stele_light.omni_range = 8.5
	_stele_light.position.y = 2.2
	add_child(_stele_light)

# =============================================================================
# READING INTERACTION & UPDATE
# =============================================================================
func read_inscription() -> Dictionary:
	is_read = true

	if _audio_player and is_inside_tree():
		_audio_player.play()

	if _stele_light:
		_stele_light.light_energy = 2.8

	var reward = {
		"exp": 150,
		"coins": 60,
		"title": "Học Giả Cổ Ngữ",
		"lore": ANCIENT_INSCRIPTION_TEXT
	}
	stele_read.emit("Bia Cổ Ngữ Ngàn Đời", ANCIENT_INSCRIPTION_TEXT, reward)
	return reward

func _process(delta: float) -> void:
	_anim_time += delta

	# Subtle breathing glow on ancient runes
	var pulse = 0.85 + sin(_anim_time * 2.5) * 0.25
	if _stele_light:
		_stele_light.light_energy = pulse if not is_read else (pulse * 1.6)

	for g in _glyph_bands:
		g.scale.x = 1.0 + sin(_anim_time * 3.0) * 0.05

# =============================================================================
# PROCEDURAL 16-BIT PCM AUDIO SYNTHESIZER
# =============================================================================
func _generate_stele_chime_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 2.0
	var total_samples: int = int(sample_rate * duration)
	var byte_count: int = total_samples * 2
	var buffer: PackedByteArray = PackedByteArray()
	buffer.resize(byte_count)

	# Ancient tuned lithophone chime (A4 440Hz + E5 659.2Hz + harmonic A5 880Hz)
	var f0: float = 440.0
	var f1: float = 659.2
	var f2: float = 880.0

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		# Percussive metallic/stone mallet strike envelope
		var strike_env: float = exp(-t * 2.8)

		var wave: float = sin(t * f0 * TAU) * 0.50
		wave += sin(t * f1 * TAU) * 0.35
		wave += sin(t * f2 * TAU) * 0.20

		var sample_val: float = wave * strike_env * 0.75
		var int_val: int = int(clampf(sample_val, -1.0, 1.0) * 32767.0)

		var byte_idx: int = i * 2
		buffer[byte_idx] = int_val & 0xFF
		buffer[byte_idx + 1] = (int_val >> 8) & 0xFF

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = buffer
	return wav
