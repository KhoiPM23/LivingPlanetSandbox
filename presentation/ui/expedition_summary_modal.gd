class_name ExpeditionSummaryModal
extends PanelContainer

## Climax & Honorary Recognition Certificate Modal for Living Planet Sandbox.
## Displays final expedition achievement metrics, unlocked badges, and navigation choices.

signal continue_requested()
signal journal_requested()
signal main_menu_requested()

const ExpeditionManager = preload("res://core/gameplay/expedition_manager.gd")
const UIAudioFeedback = preload("res://presentation/audio/ui_audio_feedback.gd")

var _manager: ExpeditionManager = null

var _title_lbl: Label
var _sub_lbl: Label
var _stats_lbl: Label
var _badges_vbox: VBoxContainer

func _ready() -> void:
	custom_minimum_size = Vector2(640, 480)
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -320
	offset_top = -240
	offset_right = 320
	offset_bottom = 240
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	_build_ui()
	visible = false

func setup(manager: ExpeditionManager) -> void:
	_manager = manager

func _build_ui() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.14, 0.98)
	style.border_color = Color(0.95, 0.8, 0.35, 0.9)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", style)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)

	# --- HEADER ---
	_title_lbl = Label.new()
	_title_lbl.text = "🏆 EXPEDITION RECOGNITION: MASTER NATURALIST"
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	_title_lbl.add_theme_font_size_override("font_size", 15)
	root_vbox.add_child(_title_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.text = "SKYSPIRE CONTINENTAL SURVEY & ECOLOGICAL EXPEDITION"
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.add_theme_color_override("font_color", Color(0.65, 0.78, 0.9))
	_sub_lbl.add_theme_font_size_override("font_size", 10)
	root_vbox.add_child(_sub_lbl)

	var divider: HSeparator = HSeparator.new()
	root_vbox.add_child(divider)

	# --- NARRATIVE PRAISE ---
	var intro_p: Label = Label.new()
	intro_p.text = "Having traversed the rugged 720m island continent, mapped its ancient monoliths, ascended the 86m Skyspire peak, braved the subterranean Whispering Grotto, and cataloged the living wildlife, your exploratory achievement is officially recorded in the Continental Archives."
	intro_p.autowrap_mode = TextServer.AUTOWRAP_WORD
	intro_p.add_theme_color_override("font_color", Color(0.88, 0.93, 0.98))
	intro_p.add_theme_font_size_override("font_size", 11)
	root_vbox.add_child(intro_p)

	# --- EXPEDITION METRICS ---
	_stats_lbl = Label.new()
	_stats_lbl.text = "• Landmarks Mapped: 0 / 11\n• Fauna Species Cataloged: 0 / 4\n• Phenomena Witnessed: 0 / 4"
	_stats_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.75))
	_stats_lbl.add_theme_font_size_override("font_size", 11)
	root_vbox.add_child(_stats_lbl)

	# --- BADGES SCROLL ---
	var badges_lbl: Label = Label.new()
	badges_lbl.text = "HONORARY CITATIONS & BADGES EARNED:"
	badges_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	badges_lbl.add_theme_font_size_override("font_size", 11)
	root_vbox.add_child(badges_lbl)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_badges_vbox = VBoxContainer.new()
	_badges_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_badges_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(_badges_vbox)
	root_vbox.add_child(scroll)

	# --- ACTION BUTTONS ---
	var btn_hbox: HBoxContainer = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)

	var cont_btn: Button = Button.new()
	cont_btn.text = "🧭 Continue Exploring"
	cont_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont_btn.custom_minimum_size = Vector2(0, 36)
	cont_btn.pressed.connect(func():
		var fb = UIAudioFeedback.get_singleton()
		if fb: fb.play_click()
		visible = false
		continue_requested.emit()
	)
	btn_hbox.add_child(cont_btn)

	var jnl_btn: Button = Button.new()
	jnl_btn.text = "📖 Review Field Journal [J]"
	jnl_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jnl_btn.custom_minimum_size = Vector2(0, 36)
	jnl_btn.pressed.connect(func():
		var fb = UIAudioFeedback.get_singleton()
		if fb: fb.play_click()
		visible = false
		journal_requested.emit()
	)
	btn_hbox.add_child(jnl_btn)

	var menu_btn: Button = Button.new()
	menu_btn.text = "🏠 Return to Title Screen"
	menu_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_btn.custom_minimum_size = Vector2(0, 36)
	menu_btn.pressed.connect(func():
		var fb = UIAudioFeedback.get_singleton()
		if fb: fb.play_click()
		visible = false
		main_menu_requested.emit()
	)
	btn_hbox.add_child(menu_btn)

	root_vbox.add_child(btn_hbox)
	add_child(root_vbox)

func show_summary() -> void:
	refresh_content()
	visible = true
	var fb = UIAudioFeedback.get_singleton()
	if fb: fb.play_milestone()

func refresh_content() -> void:
	if not _manager:
		return

	var lm_prog: Dictionary = _manager.get_landmark_progress()
	var f_prog: Dictionary = _manager.get_species_progress()
	var p_prog: Dictionary = _manager.get_phenomena_progress()
	var dist_m: float = _manager.get_distance_traveled_meters()
	var elapsed_min: int = int(_manager.get_elapsed_seconds() / 60.0)
	var elapsed_sec: int = int(_manager.get_elapsed_seconds()) % 60

	_stats_lbl.text = """• Landmarks Mapped: %d / %d (%d%%)
• Native Fauna Cataloged: %d / %d (%d%%)
• Atmospheric Spectacles Witnessed: %d / %d (%d%%)
• Total Foot Traverse Distance: %.1f meters
• Continental Time Elapsed: %02dm %02ds (Seed #%d)""" % [
		lm_prog["discovered"], lm_prog["total"], lm_prog["percentage"],
		f_prog["cataloged"], f_prog["total"], f_prog["percentage"],
		p_prog["witnessed"], p_prog["total"], p_prog["percentage"],
		dist_m, elapsed_min, elapsed_sec, _manager.active_seed
	]

	for c in _badges_vbox.get_children():
		c.queue_free()

	var badges: Dictionary = _manager.get_milestones()
	if badges.is_empty():
		var b_lbl: Label = Label.new()
		b_lbl.text = "• Island Novice — Keep charting unexplored biomes to earn citations."
		b_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
		b_lbl.add_theme_font_size_override("font_size", 10)
		_badges_vbox.add_child(b_lbl)
	else:
		for k in badges:
			var b: Dictionary = badges[k]
			var b_lbl: Label = Label.new()
			b_lbl.text = "🎖️ %s — %s" % [b["title"], b["desc"]]
			b_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6))
			b_lbl.add_theme_font_size_override("font_size", 11)
			_badges_vbox.add_child(b_lbl)
