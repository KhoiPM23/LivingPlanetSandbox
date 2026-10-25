class_name TitleScreen
extends CanvasLayer

## Title Screen & Main Menu Director for Living Planet Sandbox.
## Displays glowing title branding, expedition setup modal, continue saved game,
## codex field guide, settings, credits, and exit desktop actions with procedural audio.

signal expedition_started(seed_val: int, game_mode: String, is_load: bool)
signal settings_saved()

const GameSettings = preload("res://core/config/game_settings.gd")
const UIAudioFeedback = preload("res://presentation/audio/ui_audio_feedback.gd")

var _container: Control
var _menu_vbox: VBoxContainer
var _continue_btn: Button

# Sub-Modals
var _setup_modal: PanelContainer
var _seed_input: LineEdit
var _mode_option_btn: OptionButton

var _settings_modal: PanelContainer
var _codex_modal: PanelContainer
var _credits_modal: PanelContainer

# Settings Controls
var _preset_low_btn: Button
var _preset_bal_btn: Button
var _preset_cin_btn: Button
var _win_mode_btn: Button
var _fog_toggle_btn: Button
var _master_slider: HSlider
var _master_lbl: Label
var _amb_slider: HSlider
var _amb_lbl: Label
var _sfx_slider: HSlider
var _sfx_lbl: Label
var _sens_slider: HSlider
var _sens_lbl: Label

const SAVE_PATH: String = "user://saves/world_save.json"

func _init() -> void:
	layer = 100

func _ready() -> void:
	_build_ui()
	_update_continue_state()

func _build_ui() -> void:
	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)

	# Dark vignette & glass background backing
	var bg_panel: Panel = Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.02, 0.04, 0.08, 0.72)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(bg_panel)

	# Left/Center Branding & Navigation VBox
	_menu_vbox = VBoxContainer.new()
	_menu_vbox.anchor_left = 0.08
	_menu_vbox.anchor_top = 0.14
	_menu_vbox.anchor_right = 0.45
	_menu_vbox.anchor_bottom = 0.88
	_menu_vbox.add_theme_constant_override("separation", 12)
	_container.add_child(_menu_vbox)

	# 1. Main Title Branding
	var title_lbl: Label = Label.new()
	title_lbl.text = "LIVING PLANET"
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 34)
	_menu_vbox.add_child(title_lbl)

	var sub_lbl: Label = Label.new()
	sub_lbl.text = "AN ECOLOGICAL EXPEDITION & SANDBOX"
	sub_lbl.add_theme_color_override("font_color", Color(0.72, 0.84, 0.95))
	sub_lbl.add_theme_font_size_override("font_size", 11)
	_menu_vbox.add_child(sub_lbl)

	var ver_lbl: Label = Label.new()
	ver_lbl.text = "v1.0 Commercial Release Candidate • Vulkan Forward+ 720p"
	ver_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.75))
	ver_lbl.add_theme_font_size_override("font_size", 9)
	_menu_vbox.add_child(ver_lbl)

	var div: HSeparator = HSeparator.new()
	_menu_vbox.add_child(div)

	# 2. Main Navigation Buttons
	var start_btn: Button = _create_menu_button("🧭  Start New Expedition", _on_start_pressed)
	_menu_vbox.add_child(start_btn)

	_continue_btn = _create_menu_button("💾  Continue Saved Expedition", _on_continue_pressed)
	_menu_vbox.add_child(_continue_btn)

	var codex_btn: Button = _create_menu_button("📖  Field Guide & Codex", _on_codex_pressed)
	_menu_vbox.add_child(codex_btn)

	var settings_btn: Button = _create_menu_button("⚙️  Settings & Audio/Video", _on_settings_pressed)
	_menu_vbox.add_child(settings_btn)

	var credits_btn: Button = _create_menu_button("📜  Credits & Attribution", _on_credits_pressed)
	_menu_vbox.add_child(credits_btn)

	var quit_btn: Button = _create_menu_button("✕  Quit to Desktop", _on_quit_pressed)
	_menu_vbox.add_child(quit_btn)

	# Bottom hint
	var hint_lbl: Label = Label.new()
	hint_lbl.text = "Press [Esc] or click buttons to configure • Intel Iris Xe Optimized"
	hint_lbl.add_theme_color_override("font_color", Color(0.5, 0.58, 0.68))
	hint_lbl.add_theme_font_size_override("font_size", 9)
	_menu_vbox.add_child(hint_lbl)

	# 3. Build Sub-Modals
	_build_setup_modal()
	_build_settings_modal()
	_build_codex_modal()
	_build_credits_modal()

func _create_menu_button(label_text: String, callback: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(260, 36)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func():
		var fb = UIAudioFeedback.get_singleton()
		if fb: fb.play_click()
		callback.call()
	)
	btn.mouse_entered.connect(func():
		var fb = UIAudioFeedback.get_singleton()
		if fb: fb.play_hover()
	)
	return btn

func _update_continue_state() -> void:
	if not _continue_btn:
		return
	var has_save: bool = FileAccess.file_exists(SAVE_PATH)
	_continue_btn.disabled = not has_save
	if has_save:
		_continue_btn.text = "💾  Continue Saved Expedition [Ready]"
	else:
		_continue_btn.text = "💾  Continue Saved Expedition (No Save)"

# =========================================================================
# SUB-MODAL 1: EXPEDITION SETUP
# =========================================================================
func _build_setup_modal() -> void:
	_setup_modal = _create_glass_modal(Vector2(520, 380))
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	var title: Label = Label.new()
	title.text = "🧭 EXPEDITION COMMISSION & WORLD SETUP"
	title.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
	title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title)

	# Canonical World Map Display (Hardcoded Master Map)
	var seed_lbl: Label = Label.new()
	seed_lbl.text = "World Map (Canonical Fixed Continent):"
	seed_lbl.add_theme_font_size_override("font_size", 10)
	seed_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	vbox.add_child(seed_lbl)

	_seed_input = LineEdit.new()
	_seed_input.text = "1337"
	_seed_input.editable = false
	_seed_input.visible = false
	vbox.add_child(_seed_input)

	var map_card: PanelContainer = PanelContainer.new()
	var map_box: HBoxContainer = HBoxContainer.new()
	map_box.add_theme_constant_override("separation", 10)
	var map_icon: Label = Label.new()
	map_icon.text = "🗺️"
	map_icon.add_theme_font_size_override("font_size", 14)
	map_box.add_child(map_icon)
	var map_info: Label = Label.new()
	map_info.text = "Living Planet Master Sanctuary — Canonical Continent (Fixed #1337)"
	map_info.add_theme_font_size_override("font_size", 11)
	map_info.add_theme_color_override("font_color", Color(0.45, 0.92, 0.85))
	map_box.add_child(map_info)
	map_card.add_child(map_box)
	vbox.add_child(map_card)

	# Mode Selection
	var mode_lbl: Label = Label.new()
	mode_lbl.text = "Expedition Gameplay Mode:"
	mode_lbl.add_theme_font_size_override("font_size", 10)
	mode_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	vbox.add_child(mode_lbl)

	_mode_option_btn = OptionButton.new()
	_mode_option_btn.add_item("Naturalist Explorer (Immersive survival, journal mapping, clean HUD)")
	_mode_option_btn.add_item("God Sandbox (All experiment tools, live population curves & debug)")
	_mode_option_btn.select(0)
	vbox.add_child(_mode_option_btn)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Action buttons
	var act_hb: HBoxContainer = HBoxContainer.new()
	act_hb.add_theme_constant_override("separation", 10)

	var embark_btn: Button = Button.new()
	embark_btn.text = "🚀  Embark on Expedition"
	embark_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	embark_btn.custom_minimum_size = Vector2(0, 36)
	embark_btn.pressed.connect(_on_embark_confirmed)
	act_hb.add_child(embark_btn)

	var cancel_btn: Button = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(90, 36)
	cancel_btn.pressed.connect(func():
		var fb = UIAudioFeedback.get_singleton()
		if fb: fb.play_modal_close()
		_setup_modal.visible = false
	)
	act_hb.add_child(cancel_btn)
	vbox.add_child(act_hb)

	_setup_modal.add_child(vbox)
	_container.add_child(_setup_modal)

# =========================================================================
# SUB-MODAL 2: SETTINGS (AUDIO, GRAPHICS, CONTROLS)
# =========================================================================
func _build_settings_modal() -> void:
	_settings_modal = _create_glass_modal(Vector2(620, 480))
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	var title_hb: HBoxContainer = HBoxContainer.new()
	var title: Label = Label.new()
	title.text = "⚙️ SETTINGS & PREFERENCES"
	title.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
	title.add_theme_font_size_override("font_size", 13)
	title_hb.add_child(title)

	var sp: Control = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hb.add_child(sp)

	var close_btn: Button = Button.new()
	close_btn.text = "  ✕  "
	close_btn.pressed.connect(func():
		var fb = UIAudioFeedback.get_singleton()
		if fb: fb.play_modal_close()
		_settings_modal.visible = false
	)
	title_hb.add_child(close_btn)
	vbox.add_child(title_hb)

	var tabs: TabContainer = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# --- GRAPHICS TAB ---
	var tab_gfx: VBoxContainer = VBoxContainer.new()
	tab_gfx.name = "Graphics & Display"
	tab_gfx.add_theme_constant_override("separation", 8)

	var p_hdr: Label = Label.new()
	p_hdr.text = "GRAPHICS QUALITY PRESET:"
	p_hdr.add_theme_font_size_override("font_size", 11)
	tab_gfx.add_child(p_hdr)

	var p_hb: HBoxContainer = HBoxContainer.new()
	p_hb.add_theme_constant_override("separation", 6)
	_preset_low_btn = Button.new()
	_preset_low_btn.text = "Low (75% FSR, Fast)"
	_preset_low_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preset_low_btn.pressed.connect(func(): _apply_preset_choice(0))
	p_hb.add_child(_preset_low_btn)

	_preset_bal_btn = Button.new()
	_preset_bal_btn.text = "Balanced (Iris Xe Recommended)"
	_preset_bal_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preset_bal_btn.pressed.connect(func(): _apply_preset_choice(1))
	p_hb.add_child(_preset_bal_btn)

	_preset_cin_btn = Button.new()
	_preset_cin_btn.text = "Cinematic (100% Native, High Shadows)"
	_preset_cin_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preset_cin_btn.pressed.connect(func(): _apply_preset_choice(2))
	p_hb.add_child(_preset_cin_btn)
	tab_gfx.add_child(p_hb)

	_win_mode_btn = Button.new()
	_win_mode_btn.text = "Window Mode: Windowed (1280x720) [Click to Toggle]"
	_win_mode_btn.custom_minimum_size = Vector2(0, 32)
	_win_mode_btn.pressed.connect(_on_toggle_window_mode)
	tab_gfx.add_child(_win_mode_btn)

	_fog_toggle_btn = Button.new()
	_fog_toggle_btn.text = "Atmospheric Distance Fog: ON [Click to Toggle]"
	_fog_toggle_btn.custom_minimum_size = Vector2(0, 32)
	_fog_toggle_btn.pressed.connect(_on_toggle_fog)
	tab_gfx.add_child(_fog_toggle_btn)
	tabs.add_child(tab_gfx)

	# --- AUDIO TAB ---
	var tab_aud: VBoxContainer = VBoxContainer.new()
	tab_aud.name = "Audio Volumes"
	tab_aud.add_theme_constant_override("separation", 10)

	# Master
	var m_hb: HBoxContainer = HBoxContainer.new()
	var m_t: Label = Label.new()
	m_t.text = "Master Audio Volume:"
	m_hb.add_child(m_t)
	var m_sp: Control = Control.new()
	m_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_hb.add_child(m_sp)
	_master_lbl = Label.new()
	_master_lbl.text = "85%"
	m_hb.add_child(_master_lbl)
	tab_aud.add_child(m_hb)

	_master_slider = HSlider.new()
	_master_slider.min_value = 0.0
	_master_slider.max_value = 1.0
	_master_slider.step = 0.05
	_master_slider.value = 0.85
	_master_slider.value_changed.connect(_on_master_changed)
	tab_aud.add_child(_master_slider)

	# Ambience
	var a_hb: HBoxContainer = HBoxContainer.new()
	var a_t: Label = Label.new()
	a_t.text = "Nature Ambience & Wind:"
	a_hb.add_child(a_t)
	var a_sp: Control = Control.new()
	a_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a_hb.add_child(a_sp)
	_amb_lbl = Label.new()
	_amb_lbl.text = "85%"
	a_hb.add_child(_amb_lbl)
	tab_aud.add_child(a_hb)

	_amb_slider = HSlider.new()
	_amb_slider.min_value = 0.0
	_amb_slider.max_value = 1.0
	_amb_slider.step = 0.05
	_amb_slider.value = 0.85
	_amb_slider.value_changed.connect(_on_amb_changed)
	tab_aud.add_child(_amb_slider)

	# SFX
	var s_hb: HBoxContainer = HBoxContainer.new()
	var s_t: Label = Label.new()
	s_t.text = "UI & Expedition SFX:"
	s_hb.add_child(s_t)
	var s_sp: Control = Control.new()
	s_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s_hb.add_child(s_sp)
	_sfx_lbl = Label.new()
	_sfx_lbl.text = "85%"
	s_hb.add_child(_sfx_lbl)
	tab_aud.add_child(s_hb)

	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 1.0
	_sfx_slider.step = 0.05
	_sfx_slider.value = 0.85
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	tab_aud.add_child(_sfx_slider)
	tabs.add_child(tab_aud)

	# --- CONTROLS TAB ---
	var tab_ctl: VBoxContainer = VBoxContainer.new()
	tab_ctl.name = "Controls & Sens"
	tab_ctl.add_theme_constant_override("separation", 10)

	var sens_hb: HBoxContainer = HBoxContainer.new()
	var sens_t: Label = Label.new()
	sens_t.text = "Mouse Look Sensitivity:"
	sens_hb.add_child(sens_t)
	var sens_sp: Control = Control.new()
	sens_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sens_hb.add_child(sens_sp)
	_sens_lbl = Label.new()
	_sens_lbl.text = "0.0030"
	sens_hb.add_child(_sens_lbl)
	tab_ctl.add_child(sens_hb)

	_sens_slider = HSlider.new()
	_sens_slider.min_value = 0.001
	_sens_slider.max_value = 0.008
	_sens_slider.step = 0.0005
	_sens_slider.value = 0.003
	_sens_slider.value_changed.connect(_on_sens_changed)
	tab_ctl.add_child(_sens_slider)

	var key_help: Label = Label.new()
	key_help.text = """DEFAULT KEYBOARD SHORTCUTS:
• [W/A/S/D] - Locomotion & Direction
• [Shift] - Sprint Traverse
• [C] - Crouch & Stealth (Reduces wildlife alarm)
• [Space] - Jump / Surface Vault
• [V] - Toggle Third-Person / First-Person / Flycam
• [J] - Open Naturalist Field Journal & Codex
• [M] - Open Island Cartography Map
• [Esc] - Pause & Settings Modal"""
	key_help.add_theme_font_size_override("font_size", 10)
	key_help.add_theme_color_override("font_color", Color(0.8, 0.88, 0.95))
	tab_ctl.add_child(key_help)
	tabs.add_child(tab_ctl)

	vbox.add_child(tabs)
	_settings_modal.add_child(vbox)
	_container.add_child(_settings_modal)

# =========================================================================
# SUB-MODAL 3: FIELD GUIDE & CODEX
# =========================================================================
func _build_codex_modal() -> void:
	_codex_modal = _create_glass_modal(Vector2(640, 460))
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	var title_hb: HBoxContainer = HBoxContainer.new()
	var title: Label = Label.new()
	title.text = "📖 CONTINENTAL FIELD GUIDE & NATURALIST CODEX"
	title.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
	title.add_theme_font_size_override("font_size", 13)
	title_hb.add_child(title)

	var sp: Control = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hb.add_child(sp)

	var close_btn: Button = Button.new()
	close_btn.text = "  ✕  "
	close_btn.pressed.connect(func():
		var fb = UIAudioFeedback.get_singleton()
		if fb: fb.play_modal_close()
		_codex_modal.visible = false
	)
	title_hb.add_child(close_btn)
	vbox.add_child(title_hb)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var text_lbl: Label = Label.new()
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_lbl.text = """[ISLAND BIOMES & GEOGRAPHY]
1. Emerald Glade & Basin: Lush sunlit meadow biome cradling the central lake, rich in wildflowers and soft grasses where herbivores bed.
2. Skyspire Alpine Massif: The continent's crowning 86m peak. Characterized by snowfields, talus scree boulders, and spindrift blizzards.
3. Skyspire Alpine Tarn: A high-altitude glacial basin lake nestled at Y=36m beneath granite crags.
4. Silverveil Glacial Falls: Rushing stepped cascade ribbons tumbling from the Tarn into the lower canyon valley.
5. Whispering Grotto: A cavern cathedral carved beneath the mountain roots, featuring hanging stalactites, dripping water, and glowing azure crystal prisms.

[LIVING FAUNA DYNAMICS]
• Red Deer: Keystone herbivores that graze upon mature grasses. Highly sensitive to auditory disturbance; sprinting within 18m triggers alarm and flight.
• Gray Wolf: Solitary and pack apex predators that stalk grazing herds. Maintain ecological equilibrium to prevent catastrophic overgrazing.
• Alpine Songbirds: Resonant diurnal canopy callers that vocalize at dawn and midday, ceasing when rain arrives.
• Meadow Fireflies: Delicate bioluminescent bio-indicators emerging in meadow glades at twilight.

[ATMOSPHERIC SPECTACLES]
• Celestial Aurora: Green-to-violet harmonic curtains undulating across northern skies during clear nights.
• Celestial Shooting Stars: Periodic meteor flashes cutting across the dark night firmament.
• Dynamic Weather: Transitions between radiant sun, overcast skies, and thundering monsoons."""
	text_lbl.add_theme_color_override("font_color", Color(0.88, 0.93, 0.98))
	text_lbl.add_theme_font_size_override("font_size", 11)
	scroll.add_child(text_lbl)
	vbox.add_child(scroll)

	_codex_modal.add_child(vbox)
	_container.add_child(_codex_modal)

# =========================================================================
# SUB-MODAL 4: CREDITS & ATTRIBUTION
# =========================================================================
func _build_credits_modal() -> void:
	_credits_modal = _create_glass_modal(Vector2(560, 380))
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	var title_hb: HBoxContainer = HBoxContainer.new()
	var title: Label = Label.new()
	title.text = "📜 CREDITS & OPEN-SOURCE ATTRIBUTIONS"
	title.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
	title.add_theme_font_size_override("font_size", 13)
	title_hb.add_child(title)

	var sp: Control = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hb.add_child(sp)

	var close_btn: Button = Button.new()
	close_btn.text = "  ✕  "
	close_btn.pressed.connect(func():
		var fb = UIAudioFeedback.get_singleton()
		if fb: fb.play_modal_close()
		_credits_modal.visible = false
	)
	title_hb.add_child(close_btn)
	vbox.add_child(title_hb)

	var lbl: Label = Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.text = """LIVING PLANET SANDBOX (v1.0 RC)
Engine: Godot Engine v4.6.3 (Forward+ Vulkan Renderer)
Architecture: Autonomous Living Ecosystem Simulation & Procedural Continental Terrain

OPEN SOURCE & CC0 ASSETS:
• KayKit Character Animations & Base Meshes (CC0)
• Kenney Nature & Environmental Kit (CC0)
• Procedural 16-bit PCM Audio Synthesizers (Clean-Room GDScript)
• Procedural PBR Terrain & Triplanar Cliff Shaders (Clean-Room GDScript)

SPECIAL THANKS:
• Godot Engine Community & Open-Source Contributors
• Google DeepMind Advanced Agentic Coding Pair Programming Team"""
	lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
	lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(lbl)

	_credits_modal.add_child(vbox)
	_container.add_child(_credits_modal)

func _create_glass_modal(min_size: Vector2) -> PanelContainer:
	var pnl: PanelContainer = PanelContainer.new()
	pnl.custom_minimum_size = min_size
	pnl.anchor_left = 0.5
	pnl.anchor_top = 0.5
	pnl.anchor_right = 0.5
	pnl.anchor_bottom = 0.5
	pnl.offset_left = -min_size.x * 0.5
	pnl.offset_top = -min_size.y * 0.5
	pnl.offset_right = min_size.x * 0.5
	pnl.offset_bottom = min_size.y * 0.5
	pnl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pnl.grow_vertical = Control.GROW_DIRECTION_BOTH
	pnl.visible = false

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.13, 0.96)
	style.border_color = Color(0.35, 0.75, 0.95, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	pnl.add_theme_stylebox_override("panel", style)
	return pnl

# =========================================================================
# BUTTON HANDLERS
# =========================================================================
func _on_start_pressed() -> void:
	_close_all_submodals()
	_setup_modal.visible = true
	var fb = UIAudioFeedback.get_singleton()
	if fb: fb.play_modal_open()

func _on_continue_pressed() -> void:
	var seed_val: int = 1337
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var txt = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Dictionary and parsed.has("seed"):
				seed_val = int(parsed["seed"])
	fade_out_and_start(seed_val, "Explorer", true)

func _on_embark_confirmed() -> void:
	var seed_str: String = _seed_input.text.strip_edges()
	var seed_val: int = seed_str.to_int() if seed_str.is_valid_int() else 1337
	var mode: String = "Sandbox" if _mode_option_btn.selected == 1 else "Explorer"
	_setup_modal.visible = false
	fade_out_and_start(seed_val, mode, false)

func fade_out_and_start(seed_val: int, mode: String, is_load: bool) -> void:
	visible = false
	expedition_started.emit(seed_val, mode, is_load)

func _on_settings_pressed() -> void:
	_close_all_submodals()
	_sync_settings_ui()
	_settings_modal.visible = true
	var fb = UIAudioFeedback.get_singleton()
	if fb: fb.play_modal_open()

func _on_codex_pressed() -> void:
	_close_all_submodals()
	_codex_modal.visible = true
	var fb = UIAudioFeedback.get_singleton()
	if fb: fb.play_modal_open()

func _on_credits_pressed() -> void:
	_close_all_submodals()
	_credits_modal.visible = true
	var fb = UIAudioFeedback.get_singleton()
	if fb: fb.play_modal_open()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _close_all_submodals() -> void:
	_setup_modal.visible = false
	_settings_modal.visible = false
	_codex_modal.visible = false
	_credits_modal.visible = false

# Settings callbacks
func _sync_settings_ui() -> void:
	var settings = GameSettings.get_current()
	if _master_slider: _master_slider.value = settings.master_volume
	if _amb_slider: _amb_slider.value = settings.ambience_volume
	if _sfx_slider: _sfx_slider.value = settings.sfx_volume
	if _sens_slider: _sens_slider.value = settings.mouse_sensitivity
	_update_preset_buttons(settings.graphics_preset)

func _update_preset_buttons(active: int) -> void:
	if _preset_low_btn: _preset_low_btn.modulate = Color(1.3, 1.3, 0.9) if active == 0 else Color.WHITE
	if _preset_bal_btn: _preset_bal_btn.modulate = Color(1.3, 1.3, 0.9) if active == 1 else Color.WHITE
	if _preset_cin_btn: _preset_cin_btn.modulate = Color(1.3, 1.3, 0.9) if active == 2 else Color.WHITE

func _apply_preset_choice(idx: int) -> void:
	var settings = GameSettings.get_current()
	settings.graphics_preset = idx
	_update_preset_buttons(idx)
	settings.apply_all(get_tree().current_scene if get_tree() else null)
	settings.save_to_disk()
	settings_saved.emit()

func _on_toggle_window_mode() -> void:
	var settings = GameSettings.get_current()
	settings.window_mode = 1 if settings.window_mode == 0 else 0
	if settings.window_mode == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		if _win_mode_btn: _win_mode_btn.text = "Window Mode: Fullscreen [Click to Toggle]"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if _win_mode_btn: _win_mode_btn.text = "Window Mode: Windowed (1280x720) [Click to Toggle]"
	settings.save_to_disk()

func _on_toggle_fog() -> void:
	var settings = GameSettings.get_current()
	settings.fog_enabled = not settings.fog_enabled
	if _fog_toggle_btn:
		_fog_toggle_btn.text = "Atmospheric Distance Fog: " + ("ON" if settings.fog_enabled else "OFF") + " [Click to Toggle]"
	var env_node = get_tree().root.find_child("WorldEnvironment", true, false) if get_tree() else null
	if env_node and env_node.environment:
		env_node.environment.fog_enabled = settings.fog_enabled
	settings.save_to_disk()

func _on_master_changed(val: float) -> void:
	var settings = GameSettings.get_current()
	settings.master_volume = val
	if _master_lbl: _master_lbl.text = "%d%%" % int(val * 100.0)
	var idx = AudioServer.get_bus_index("Master")
	if idx >= 0:
		if val <= 0.01:
			AudioServer.set_bus_mute(idx, true)
		else:
			AudioServer.set_bus_mute(idx, false)
			AudioServer.set_bus_volume_db(idx, linear_to_db(val))
	settings.save_to_disk()

func _on_amb_changed(val: float) -> void:
	var settings = GameSettings.get_current()
	settings.ambience_volume = val
	if _amb_lbl: _amb_lbl.text = "%d%%" % int(val * 100.0)
	var audio_dir = get_tree().root.find_child("SpatialAudioDirector", true, false) if get_tree() else null
	if audio_dir and audio_dir.has_method("set_ambience_volume_scale"):
		audio_dir.call("set_ambience_volume_scale", val)
	settings.save_to_disk()

func _on_sfx_changed(val: float) -> void:
	var settings = GameSettings.get_current()
	settings.sfx_volume = val
	if _sfx_lbl: _sfx_lbl.text = "%d%%" % int(val * 100.0)
	var fb = UIAudioFeedback.get_singleton()
	if fb: fb.set_sfx_volume_scale(val)
	settings.save_to_disk()

func _on_sens_changed(val: float) -> void:
	var settings = GameSettings.get_current()
	settings.mouse_sensitivity = val
	if _sens_lbl: _sens_lbl.text = "%.4f" % val
	var cam = get_tree().root.find_child("FreeLookCamera", true, false) if get_tree() else null
	if cam: cam.mouse_sensitivity = val
	settings.save_to_disk()
