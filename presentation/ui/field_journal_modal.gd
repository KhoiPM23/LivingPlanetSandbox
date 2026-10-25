class_name FieldJournalModal
extends PanelContainer

## Naturalist Field Journal & Island Codex Modal (Hotkey: [J]).
## Displays categorized exploration progress for Landmarks, Fauna, Atmospheric Phenomena,
## and Expedition Statistics with interactive UI audio feedback.

signal closed()
signal milestone_summary_requested()

const ExpeditionManager = preload("res://core/gameplay/expedition_manager.gd")
const UIAudioFeedback = preload("res://presentation/audio/ui_audio_feedback.gd")

var _manager: ExpeditionManager = null
var _tab_container: TabContainer

# Progress Bars
var _landmark_progress_bar: ProgressBar
var _landmark_progress_lbl: Label
var _fauna_progress_bar: ProgressBar
var _fauna_progress_lbl: Label
var _phenom_progress_bar: ProgressBar
var _phenom_progress_lbl: Label

# Lists / Cards
var _landmark_vbox: VBoxContainer
var _fauna_vbox: VBoxContainer
var _phenom_vbox: VBoxContainer
var _stats_vbox: VBoxContainer
var _photo_vbox: VBoxContainer
var _photo_count_lbl: Label
var _sound_vbox: VBoxContainer
var _sound_count_lbl: Label
var _quest_vbox: VBoxContainer
var _compendium_vbox: VBoxContainer
var _compendium_count_lbl: Label

func _ready() -> void:
	custom_minimum_size = Vector2(780, 520)
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -390
	offset_top = -260
	offset_right = 390
	offset_bottom = 260
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	_build_ui()
	visible = false

func setup(manager: ExpeditionManager) -> void:
	if _tab_container == null:
		_ready()
	_manager = manager
	if _manager:
		if not _manager.landmark_discovered.is_connected(_on_manager_update):
			_manager.landmark_discovered.connect(_on_manager_update)
		if not _manager.species_cataloged.is_connected(_on_manager_update):
			_manager.species_cataloged.connect(_on_manager_update)
		if not _manager.phenomenon_witnessed.is_connected(_on_manager_update):
			_manager.phenomenon_witnessed.connect(_on_manager_update)
		if not _manager.photo_saved.is_connected(_on_manager_update):
			_manager.photo_saved.connect(_on_manager_update)
		if not _manager.quest_completed.is_connected(_on_manager_update):
			_manager.quest_completed.connect(_on_manager_update)
	refresh_display()

func _on_manager_update(_a=null, _b=null, _c=null, _d=null, _e=null) -> void:
	if visible:
		refresh_display()

func _build_ui() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.13, 0.96)
	style.border_color = Color(0.32, 0.72, 0.95, 0.85)
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
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)

	# --- HEADER ---
	var header_hbox: HBoxContainer = HBoxContainer.new()
	var title_lbl: Label = Label.new()
	title_lbl.text = "📖 NATURALIST FIELD JOURNAL & ISLAND CODEX [J]"
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 13)
	header_hbox.add_child(title_lbl)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	var close_btn: Button = Button.new()
	close_btn.text = "  ✕  "
	close_btn.pressed.connect(func():
		var fb = UIAudioFeedback.get_singleton()
		if fb: fb.play_modal_close()
		hide_journal()
	)
	header_hbox.add_child(close_btn)
	root_vbox.add_child(header_hbox)

	# --- TAB CONTAINER ---
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# 1. LANDMARKS TAB
	var tab_landmarks: VBoxContainer = VBoxContainer.new()
	tab_landmarks.name = "Landmarks (11)"
	tab_landmarks.add_theme_constant_override("separation", 8)

	var lm_hdr_hbox: HBoxContainer = HBoxContainer.new()
	_landmark_progress_lbl = Label.new()
	_landmark_progress_lbl.text = "MAPPED LANDMARKS: 0 / 11 (0%)"
	_landmark_progress_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
	_landmark_progress_lbl.add_theme_font_size_override("font_size", 11)
	lm_hdr_hbox.add_child(_landmark_progress_lbl)

	var lm_spacer: Control = Control.new()
	lm_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lm_hdr_hbox.add_child(lm_spacer)

	_landmark_progress_bar = ProgressBar.new()
	_landmark_progress_bar.custom_minimum_size = Vector2(220, 16)
	_landmark_progress_bar.max_value = 11.0
	_landmark_progress_bar.show_percentage = false
	lm_hdr_hbox.add_child(_landmark_progress_bar)
	tab_landmarks.add_child(lm_hdr_hbox)

	var lm_scroll: ScrollContainer = ScrollContainer.new()
	lm_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_landmark_vbox = VBoxContainer.new()
	_landmark_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_landmark_vbox.add_theme_constant_override("separation", 6)
	lm_scroll.add_child(_landmark_vbox)
	tab_landmarks.add_child(lm_scroll)
	_tab_container.add_child(tab_landmarks)

	# 2. FAUNA CATALOG TAB
	var tab_fauna: VBoxContainer = VBoxContainer.new()
	tab_fauna.name = "Fauna Catalog (4)"
	tab_fauna.add_theme_constant_override("separation", 8)

	var fauna_hdr_hbox: HBoxContainer = HBoxContainer.new()
	_fauna_progress_lbl = Label.new()
	_fauna_progress_lbl.text = "CATALOGED SPECIES: 0 / 4 (0%)"
	_fauna_progress_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
	_fauna_progress_lbl.add_theme_font_size_override("font_size", 11)
	fauna_hdr_hbox.add_child(_fauna_progress_lbl)

	var f_spacer: Control = Control.new()
	f_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fauna_hdr_hbox.add_child(f_spacer)

	_fauna_progress_bar = ProgressBar.new()
	_fauna_progress_bar.custom_minimum_size = Vector2(220, 16)
	_fauna_progress_bar.max_value = 4.0
	_fauna_progress_bar.show_percentage = false
	fauna_hdr_hbox.add_child(_fauna_progress_bar)
	tab_fauna.add_child(fauna_hdr_hbox)

	var fauna_scroll: ScrollContainer = ScrollContainer.new()
	fauna_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fauna_vbox = VBoxContainer.new()
	_fauna_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fauna_vbox.add_theme_constant_override("separation", 8)
	fauna_scroll.add_child(_fauna_vbox)
	tab_fauna.add_child(fauna_scroll)
	_tab_container.add_child(tab_fauna)

	# 3. ATMOSPHERIC PHENOMENA TAB
	var tab_phenom: VBoxContainer = VBoxContainer.new()
	tab_phenom.name = "Sky & Weather (4)"
	tab_phenom.add_theme_constant_override("separation", 8)

	var phenom_hdr_hbox: HBoxContainer = HBoxContainer.new()
	_phenom_progress_lbl = Label.new()
	_phenom_progress_lbl.text = "WITNESSED PHENOMENA: 0 / 4 (0%)"
	_phenom_progress_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
	_phenom_progress_lbl.add_theme_font_size_override("font_size", 11)
	phenom_hdr_hbox.add_child(_phenom_progress_lbl)

	var p_spacer: Control = Control.new()
	p_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phenom_hdr_hbox.add_child(p_spacer)

	_phenom_progress_bar = ProgressBar.new()
	_phenom_progress_bar.custom_minimum_size = Vector2(220, 16)
	_phenom_progress_bar.max_value = 4.0
	_phenom_progress_bar.show_percentage = false
	phenom_hdr_hbox.add_child(_phenom_progress_bar)
	tab_phenom.add_child(phenom_hdr_hbox)

	var phenom_scroll: ScrollContainer = ScrollContainer.new()
	phenom_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_phenom_vbox = VBoxContainer.new()
	_phenom_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_phenom_vbox.add_theme_constant_override("separation", 8)
	phenom_scroll.add_child(_phenom_vbox)
	tab_phenom.add_child(phenom_scroll)
	_tab_container.add_child(tab_phenom)

	# 4. EXPEDITION STATS & MILESTONES TAB
	var tab_stats: VBoxContainer = VBoxContainer.new()
	tab_stats.name = "Expedition Stats & Badges"
	tab_stats.add_theme_constant_override("separation", 10)

	var stats_scroll: ScrollContainer = ScrollContainer.new()
	stats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stats_vbox = VBoxContainer.new()
	_stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_vbox.add_theme_constant_override("separation", 10)
	stats_scroll.add_child(_stats_vbox)
	tab_stats.add_child(stats_scroll)
	_tab_container.add_child(tab_stats)

	# 5. PHOTO ALBUM TAB
	var tab_photos: VBoxContainer = VBoxContainer.new()
	tab_photos.name = "📸 Photo Album"
	tab_photos.add_theme_constant_override("separation", 8)

	_photo_count_lbl = Label.new()
	_photo_count_lbl.text = "FIELD PHOTOGRAPHS: 0 Snapshots Recorded"
	_photo_count_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.75))
	_photo_count_lbl.add_theme_font_size_override("font_size", 10)
	tab_photos.add_child(_photo_count_lbl)

	var photo_scroll: ScrollContainer = ScrollContainer.new()
	photo_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_photo_vbox = VBoxContainer.new()
	_photo_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_photo_vbox.add_theme_constant_override("separation", 8)
	photo_scroll.add_child(_photo_vbox)
	tab_photos.add_child(photo_scroll)
	_tab_container.add_child(tab_photos)

	# 6. BIO-ACOUSTIC SOUND LOGS TAB
	var tab_sounds: VBoxContainer = VBoxContainer.new()
	tab_sounds.name = "Bio-Acoustics"
	tab_sounds.add_theme_constant_override("separation", 8)

	_sound_count_lbl = Label.new()
	_sound_count_lbl.text = "ACOUSTIC TAPE REELS: 0 Sounds Recorded"
	_sound_count_lbl.add_theme_color_override("font_color", Color(0.25, 0.92, 0.82))
	_sound_count_lbl.add_theme_font_size_override("font_size", 10)
	tab_sounds.add_child(_sound_count_lbl)

	var sound_scroll: ScrollContainer = ScrollContainer.new()
	sound_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sound_vbox = VBoxContainer.new()
	_sound_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sound_vbox.add_theme_constant_override("separation", 8)
	sound_scroll.add_child(_sound_vbox)
	tab_sounds.add_child(sound_scroll)
	_tab_container.add_child(tab_sounds)

	# 7. MARINE & ALCHEMY COMPENDIUM TAB (Block 47)
	var tab_compendium: VBoxContainer = VBoxContainer.new()
	tab_compendium.name = "Compendium & Recipes"
	tab_compendium.add_theme_constant_override("separation", 8)

	_compendium_count_lbl = Label.new()
	_compendium_count_lbl.text = "ISLAND ARCHIVE: Marine Catches, Botanical Elixirs & Ancient Relics"
	_compendium_count_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.85))
	_compendium_count_lbl.add_theme_font_size_override("font_size", 10)
	tab_compendium.add_child(_compendium_count_lbl)

	var comp_scroll: ScrollContainer = ScrollContainer.new()
	comp_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_compendium_vbox = VBoxContainer.new()
	_compendium_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compendium_vbox.add_theme_constant_override("separation", 8)
	comp_scroll.add_child(_compendium_vbox)
	tab_compendium.add_child(comp_scroll)
	_tab_container.add_child(tab_compendium)

	root_vbox.add_child(_tab_container)
	add_child(root_vbox)

func show_journal(tab_idx: int = 0) -> void:
	visible = true
	if _tab_container:
		_tab_container.current_tab = tab_idx
		var tb: TabBar = _tab_container.get_tab_bar()
		if tb:
			tb.current_tab = tab_idx
	refresh_display()
	var fb = UIAudioFeedback.get_singleton()
	if fb: fb.play_modal_open()

func hide_journal() -> void:
	visible = false
	closed.emit()

func refresh_display() -> void:
	if not _manager or not _landmark_vbox:
		return

	# 1. Update Landmarks
	var lm_dict: Dictionary = _manager.get_landmarks()
	var lm_prog: Dictionary = _manager.get_landmark_progress()
	if _landmark_progress_lbl:
		_landmark_progress_lbl.text = "MAPPED LANDMARKS: %d / %d (%d%%)" % [
			lm_prog["discovered"], lm_prog["total"], lm_prog["percentage"]
		]
	if _landmark_progress_bar:
		_landmark_progress_bar.max_value = float(lm_prog["total"])
		_landmark_progress_bar.value = float(lm_prog["discovered"])

	for c in _landmark_vbox.get_children():
		_landmark_vbox.remove_child(c)
		c.queue_free()

	for k in lm_dict:
		var item: Dictionary = lm_dict[k]
		var card: PanelContainer = _create_card(
			item["title"] if item["discovered"] else "❓ Undiscovered Island Feature",
			item["desc"] if item["discovered"] else "Traverse the continent to discover and record this geographical landmark.",
			"📍 Pos: (%.1f, %.1f, %.1f) [MAPPED]" % [item["coords"].x, item["coords"].y, item["coords"].z] if item["discovered"] else "📍 Status: Uncharted",
			item["discovered"]
		)
		_landmark_vbox.add_child(card)

	# 2. Update Fauna
	var f_dict: Dictionary = _manager.get_species()
	var f_prog: Dictionary = _manager.get_species_progress()
	if _fauna_progress_lbl:
		_fauna_progress_lbl.text = "CATALOGED SPECIES: %d / %d (%d%%)" % [
			f_prog["cataloged"], f_prog["total"], f_prog["percentage"]
		]
	if _fauna_progress_bar:
		_fauna_progress_bar.max_value = float(f_prog["total"])
		_fauna_progress_bar.value = float(f_prog["cataloged"])

	for c in _fauna_vbox.get_children():
		_fauna_vbox.remove_child(c)
		c.queue_free()

	for k in f_dict:
		var item: Dictionary = f_dict[k]
		var card: PanelContainer = _create_card(
			item["title"] if item["cataloged"] else "🐾 Unknown Species",
			item["desc"] if item["cataloged"] else "Explore meadows, ridge forests, and lakes to catalog this animal.",
			"Niche: %s [CATALOGED]" % item["role"] if item["cataloged"] else "Niche: Uncataloged",
			item["cataloged"]
		)
		_fauna_vbox.add_child(card)

	# 3. Update Phenomena
	var p_dict: Dictionary = _manager.get_phenomena()
	var p_prog: Dictionary = _manager.get_phenomena_progress()
	if _phenom_progress_lbl:
		_phenom_progress_lbl.text = "WITNESSED PHENOMENA: %d / %d (%d%%)" % [
			p_prog["witnessed"], p_prog["total"], p_prog["percentage"]
		]
	if _phenom_progress_bar:
		_phenom_progress_bar.max_value = float(p_prog["total"])
		_phenom_progress_bar.value = float(p_prog["witnessed"])

	for c in _phenom_vbox.get_children():
		_phenom_vbox.remove_child(c)
		c.queue_free()

	for k in p_dict:
		var item: Dictionary = p_dict[k]
		var card: PanelContainer = _create_card(
			item["title"] if item["witnessed"] else "🌌 Unobserved Atmospheric Phenomenon",
			item["desc"] if item["witnessed"] else "Observe clear night skies, storm fronts, and high peaks to witness.",
			"Status: [OBSERVED]" if item["witnessed"] else "Status: Pending Discovery",
			item["witnessed"]
		)
		_phenom_vbox.add_child(card)

	# 4. Update Stats & Badges
	for c in _stats_vbox.get_children():
		_stats_vbox.remove_child(c)
		c.queue_free()

	var stats_pnl: PanelContainer = PanelContainer.new()
	var stats_style: StyleBoxFlat = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.06, 0.10, 0.16, 0.8)
	stats_style.corner_radius_top_left = 6
	stats_style.corner_radius_top_right = 6
	stats_style.corner_radius_bottom_right = 6
	stats_style.corner_radius_bottom_left = 6
	stats_style.content_margin_left = 12
	stats_style.content_margin_right = 12
	stats_style.content_margin_top = 10
	stats_style.content_margin_bottom = 10
	stats_pnl.add_theme_stylebox_override("panel", stats_style)

	var s_vbox: VBoxContainer = VBoxContainer.new()
	s_vbox.add_theme_constant_override("separation", 6)

	var s_title: Label = Label.new()
	s_title.text = "EXPEDITION VITALS & LOG"
	s_title.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
	s_title.add_theme_font_size_override("font_size", 12)
	s_vbox.add_child(s_title)

	var elapsed_min: int = int(_manager.get_elapsed_seconds() / 60.0)
	var elapsed_sec: int = int(_manager.get_elapsed_seconds()) % 60
	var dist_m: float = _manager.get_distance_traveled_meters()
	var total_pct: int = _manager.get_total_completion_percentage()

	var details_lbl: Label = Label.new()
	details_lbl.text = """• Expedition Duration: %02dm %02ds
• Distance Traversed on Foot: %.1f meters
• Active Continental Seed: #%d
• Exploration Completion: %d%% Overall
• Game Mode: %s""" % [elapsed_min, elapsed_sec, dist_m, _manager.active_seed, total_pct, _manager.game_mode]
	details_lbl.add_theme_color_override("font_color", Color(0.9, 0.94, 0.98))
	details_lbl.add_theme_font_size_override("font_size", 11)
	s_vbox.add_child(details_lbl)
	stats_pnl.add_child(s_vbox)
	_stats_vbox.add_child(stats_pnl)

	# Active Expedition Commissions Card
	var quests_pnl: PanelContainer = PanelContainer.new()
	quests_pnl.add_theme_stylebox_override("panel", stats_style)
	var q_vbox: VBoxContainer = VBoxContainer.new()
	q_vbox.add_theme_constant_override("separation", 6)

	var q_title: Label = Label.new()
	q_title.text = "📜 EXPEDITION FIELD COMMISSIONS"
	q_title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	q_title.add_theme_font_size_override("font_size", 12)
	q_vbox.add_child(q_title)

	var quests: Array[Dictionary] = _manager.get_active_quests()
	if quests.is_empty():
		var no_q: Label = Label.new()
		no_q.text = "No active commissions. Embark on a new expedition to receive field tasks!"
		no_q.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
		no_q.add_theme_font_size_override("font_size", 10)
		q_vbox.add_child(no_q)
	else:
		for q in quests:
			var is_done: bool = q.get("completed", false)
			var status_str: String = "✓ COMPLETED (+%d XP)" % q.get("xp", 100) if is_done else "IN PROGRESS [%d/%d]" % [q.get("current_progress", 0), q.get("target_progress", 1)]
			var q_card: Label = Label.new()
			q_card.text = "%s %s\n   %s  •  %s" % ["✅" if is_done else "🧭", q.get("title", ""), q.get("desc", ""), status_str]
			q_card.add_theme_color_override("font_color", Color(0.45, 0.95, 0.65) if is_done else Color(0.85, 0.90, 0.95))
			q_card.add_theme_font_size_override("font_size", 10)
			q_vbox.add_child(q_card)

	quests_pnl.add_child(q_vbox)
	_stats_vbox.add_child(quests_pnl)

	# Milestone Badges Card
	var badges_pnl: PanelContainer = PanelContainer.new()
	badges_pnl.add_theme_stylebox_override("panel", stats_style)
	var b_vbox: VBoxContainer = VBoxContainer.new()
	b_vbox.add_theme_constant_override("separation", 6)

	var b_title: Label = Label.new()
	b_title.text = "HONORARY EXPEDITION MILESTONES & BADGES"
	b_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	b_title.add_theme_font_size_override("font_size", 12)
	b_vbox.add_child(b_title)

	var milestones: Dictionary = _manager.get_milestones()
	if milestones.is_empty():
		var no_b: Label = Label.new()
		no_b.text = "No milestones unlocked yet. Discover landmarks and take photos to earn honorary badges!"
		no_b.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
		no_b.add_theme_font_size_override("font_size", 10)
		b_vbox.add_child(no_b)
	else:
		for mid in milestones:
			var mb: Dictionary = milestones[mid]
			var b_card: Label = Label.new()
			b_card.text = "⭐ %s — %s" % [mb["title"], mb["desc"]]
			b_card.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6))
			b_card.add_theme_font_size_override("font_size", 11)
			b_vbox.add_child(b_card)

	var summary_btn: Button = Button.new()
	summary_btn.text = "🏆 Open Formal Expedition Recognition Summary"
	summary_btn.custom_minimum_size = Vector2(0, 32)
	summary_btn.pressed.connect(func():
		var fb = UIAudioFeedback.get_singleton()
		if fb: fb.play_click()
		milestone_summary_requested.emit()
	)
	b_vbox.add_child(summary_btn)

	badges_pnl.add_child(b_vbox)
	_stats_vbox.add_child(badges_pnl)

	# 5. Populate Photo Album
	if _photo_vbox:
		for c in _photo_vbox.get_children():
			_photo_vbox.remove_child(c)
			c.queue_free()

		var photos: Array[Dictionary] = _manager.get_photos()
		if _photo_count_lbl:
			_photo_count_lbl.text = "FIELD PHOTOGRAPHS: %d Snapshots Documented" % photos.size()

		if photos.is_empty():
			var empty_p: Label = Label.new()
			empty_p.text = "No field photographs recorded yet.\nEquip Field Binoculars / Camera with [Z] or [RMB] and press [Space / LMB] to capture wildlife & landscape photographs!"
			empty_p.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
			empty_p.add_theme_font_size_override("font_size", 11)
			_photo_vbox.add_child(empty_p)
		else:
			for p in photos:
				var filter_str: String = " • Filter: %s" % p.get("filter", "Natural Spectrum")
				var stealth_str: String = " • [🌿 Stealth Bonus]" if p.get("stealth", false) else ""
				var p_card: PanelContainer = _create_card(
					"📸 Photo #%d: %s" % [p.get("id", 1), p.get("subject", "Wilderness")],
					"Quality Score: %d/100 • Distance: %.1fm%s%s\nRecorded at %s (%s)" % [
						p.get("score", 75),
						p.get("distance", 15.0),
						filter_str,
						stealth_str,
						p.get("location", "Island Glade"),
						p.get("timestamp", "08:00")
					],
					"⭐ %d PTS" % p.get("score", 75),
					true
				)
				_photo_vbox.add_child(p_card)

	# 6. Populate Bio-Acoustics Sound Logs
	if _sound_vbox:
		for c in _sound_vbox.get_children():
			_sound_vbox.remove_child(c)
			c.queue_free()

		var sound_logs: Array[Dictionary] = _manager.get_sound_logs()
		if _sound_count_lbl:
			_sound_count_lbl.text = "ACOUSTIC TAPE REELS: %d Sounds Recorded" % sound_logs.size()

		if sound_logs.is_empty():
			var empty_s: Label = Label.new()
			empty_s.text = "No wildlife acoustic recordings logged yet.\nEquip Field Binoculars/Microphone with [Z] or [X] and press [R] to record wildlife vocalizations & bio-telemetry!"
			empty_s.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
			empty_s.add_theme_font_size_override("font_size", 11)
			_sound_vbox.add_child(empty_s)
		else:
			for s in sound_logs:
				var s_card: PanelContainer = _create_card(
					"🎙️ Audio Tape #%d: %s" % [s.get("id", 1), s.get("species", "Fauna Vocalization")],
					"Frequency: %.0f Hz • Amplitude: %.1f dB • Bearing: %03d°\nRecorded at %s (%s)" % [
						s.get("frequency_hz", 185.0),
						s.get("decibels", 52.0),
						int(s.get("bearing", 0.0)),
						s.get("location", "Wilderness"),
						s.get("timestamp", "12:00")
					],
					"🔊 16-BIT PCM",
					true
				)
				_sound_vbox.add_child(s_card)

	# 7. Populate Marine & Alchemy Compendium (Block 47)
	if _compendium_vbox:
		for c in _compendium_vbox.get_children():
			_compendium_vbox.remove_child(c)
			c.queue_free()

		var compendium_entries: Array[Dictionary] = [
			{
				"title": "🐟 Cá Hồi Lục Bảo (Emerald Salmon)",
				"desc": "Loài cá biển bơi nhanh ven rạn san hô và cửa vịnh Haven. Thịt thơm ngậy, nguyên liệu hảo hạng cho món Súp Thảo Mộc.",
				"tag": "🌊 CÂU ĐƯỢC [VEN BIỂN / THUYỀN]",
				"unlocked": true
			},
			{
				"title": "☀️ Cá Mặt Trời Hoàng Kim (Golden Sunfish)",
				"desc": "Cá biển sâu lấp lánh sắc vàng kim quanh xác tàu đắm Galleon. Dùng chưng cất Dược Tinh Hoa Biển Sâu và Thuốc Thái Dương.",
				"tag": "⭐ HIẾM [VỊNH SÂU]",
				"unlocked": true
			},
			{
				"title": "🦪 Hàu Ngọc Trai Phát Sáng (Luminous Pearl Oyster)",
				"desc": "Thân mềm phát huỳnh quang dưới đáy thảm cỏ biển. Chứa tinh thể ngọc trai tự nhiên đổi được nhiều Haven Coins.",
				"tag": "💎 TRÂN CHÂU [ĐÁY BIỂN]",
				"unlocked": true
			},
			{
				"title": "🍲 Súp Cá Hồi Thảo Mộc (Herb Salmon Soup)",
				"desc": "Món ăn ấm áp nấu tại Bếp Lò Quảng Trường Làng Haven từ Cá Hồi Lục Bảo, quả mọng Cổ Thụ và nấm địa y. Hồi phục 100% thể lực.",
				"tag": "🔥 ĐÃ MỞ KHÓA [BẾP LÒ LÀNG]",
				"unlocked": true
			},
			{
				"title": "🧪 Dược Tinh Hoa Biển Sâu (Abyssal Clarity Elixir)",
				"desc": "Thuốc giả kim chưng cất từ Cá Mặt Trời và Tảo Lam. Ban thị giác xuyên thấu làn nước biển và tăng tốc độ bơi lặn.",
				"tag": "✨ ĐÃ CHẾ TẠO [GIẢ KIM]",
				"unlocked": true
			},
			{
				"title": "🏺 Linh Dược Thái Dương (Solar Sovereign Tonic)",
				"desc": "Linh dược tối thượng kết hợp Hoa Lan Lửa Núi Cao và Cá Mặt Trời Hoàng Kim. Tăng tốc độ di chuyển và sức mạnh bật nhảy phi thường.",
				"tag": "👑 THẦN DƯỢC [GIẢ KIM BẬC CAO]",
				"unlocked": true
			},
			{
				"title": "🔱 Con Dấu Hoàng Gia Cổ Đại (Ancient Royal Seal)",
				"desc": "Ấn tín hoàng gia của Vua Raymond được phong ấn trong Quan tài Hầm mộ Lâu đài cổ, mở khóa bí mật đảo ngọc.",
				"tag": "🏰 DI VẬT HOÀNG GIA [HẦM MỘ]",
				"unlocked": true
			}
		]

		for entry in compendium_entries:
			var card: PanelContainer = _create_card(
				entry["title"],
				entry["desc"],
				entry["tag"],
				entry["unlocked"]
			)
			_compendium_vbox.add_child(card)

func _create_card(title: String, desc: String, tag: String, unlocked: bool) -> PanelContainer:
	var pnl: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if unlocked:
		style.bg_color = Color(0.06, 0.12, 0.18, 0.85)
		style.border_color = Color(0.28, 0.65, 0.9, 0.65)
	else:
		style.bg_color = Color(0.05, 0.07, 0.10, 0.65)
		style.border_color = Color(0.2, 0.25, 0.32, 0.4)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	pnl.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)

	var top_hb: HBoxContainer = HBoxContainer.new()
	var t_lbl: Label = Label.new()
	t_lbl.text = title
	t_lbl.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0) if unlocked else Color(0.65, 0.72, 0.8))
	t_lbl.add_theme_font_size_override("font_size", 11)
	top_hb.add_child(t_lbl)

	var sp: Control = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hb.add_child(sp)

	var tag_lbl: Label = Label.new()
	tag_lbl.text = tag
	tag_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 0.75) if unlocked else Color(0.5, 0.55, 0.62))
	tag_lbl.add_theme_font_size_override("font_size", 9)
	top_hb.add_child(tag_lbl)
	vbox.add_child(top_hb)

	var d_lbl: Label = Label.new()
	d_lbl.text = desc
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	d_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95) if unlocked else Color(0.55, 0.6, 0.66))
	d_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(d_lbl)

	pnl.add_child(vbox)
	return pnl
