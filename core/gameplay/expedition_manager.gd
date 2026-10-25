class_name ExpeditionManager
extends Node

## Central Expedition & Naturalist Field Journal Director for Living Planet Sandbox.
## Tracks exploration progress across landmarks, fauna catalog, celestial phenomena,
## awards exploration milestone badges, and handles expedition persistence.

signal state_changed(old_state: int, new_state: int)
signal landmark_discovered(id: String, title: String, desc: String, count: int, total: int)
signal species_cataloged(species_id: String, title: String, role: String, count: int, total: int)
signal phenomenon_witnessed(phenom_id: String, title: String, count: int, total: int)
signal milestone_unlocked(milestone_id: String, title: String, badge_desc: String)
signal photo_saved(photo_data: Dictionary)
signal quest_completed(quest_id: String, title: String, reward_xp: int)
signal quest_accepted(quest_id: String, title: String)

enum GameState {
	TITLE_SCREEN,
	PLAYING,
	PAUSED,
	SUMMARY_MODAL
}

var current_state: GameState = GameState.TITLE_SCREEN
var game_mode: String = "Explorer" # "Explorer" or "Sandbox"
var active_seed: int = 1337

# --- PHOTOS & FIELD ALBUM ---
var _photos: Array[Dictionary] = []

# --- BIO-ACOUSTIC SOUND LOGS ---
var _sound_logs: Array[Dictionary] = []

# --- BOTANICAL PHENOLOGY SURVEYS ---
var _botanical_surveys: Dictionary = {}

# --- EXPEDITION COMMISSIONS & QUESTS ---
var _quests: Array[Dictionary] = []

# --- LANDMARKS (11 Total) ---
var _landmarks: Dictionary = {
	"field_camp": {
		"title": "⛺ Overgrown Field Camp",
		"desc": "A naturalist's abandoned canvas shelter and stone fire pit, reclaimed by forest moss.",
		"coords": Vector3(-5.5, 3.8, 0.5),
		"discovered": false
	},
	"antler_rub": {
		"title": "🦌 Stag Antler Rub",
		"desc": "A weathered cedar trunk polished smooth by seasonal velvet rubbing, nestled in trampled bedding grass.",
		"coords": Vector3(8.5, 3.1, 2.5),
		"discovered": false
	},
	"cove_mooring": {
		"title": "🛶 Emerald Cove Mooring",
		"desc": "An abandoned wooden canoe resting among cattails and sand ripples where animals gather to drink.",
		"coords": Vector3(13.8, 0.45, 8.8),
		"discovered": false
	},
	"bluff_overlook": {
		"title": "🦅 Granite Bluff Perch",
		"desc": "A windswept dead pine overlooking the entire basin, commanding panoramic views of the island.",
		"coords": Vector3(21.5, 8.2, 14.8),
		"discovered": false
	},
	"ancient_cairn": {
		"title": "🗿 Whispering Monoliths",
		"desc": "A prehistoric circle of weathered granite monoliths perched above the ocean surf.",
		"coords": Vector3(-16.5, 5.4, -12.5),
		"discovered": false
	},
	"skyspire_overlook": {
		"title": "🦅 Skyspire Alpine Peak & Cổ Đài",
		"desc": "The towering snow-capped apex of the continent (114m), crowned by the Ancient Anemo Spire Beacon Altar.",
		"coords": Vector3(-145.0, 114.0, -145.0),
		"discovered": false
	},
	"highland_ring": {
		"title": "🌲 Highland Megalith Ring",
		"desc": "An elevated plateau covered in ancient pine woods and monumental rock slabs.",
		"coords": Vector3(180.0, 24.0, -30.0),
		"discovered": false
	},
	"cape_solitude": {
		"title": "⚓ Cape Solitude Bluffs",
		"desc": "Sheer ocean cliffs facing the Southern breakers, where pelagic currents crash against granite tors.",
		"coords": Vector3(20.0, 18.0, 195.0),
		"discovered": false
	},
	"alpine_tarn": {
		"title": "💎 Skyspire Alpine Tarn",
		"desc": "A pristine high-altitude glacial lake (Y=36m) nestled inside the alpine mountain amphitheater.",
		"coords": Vector3(-125.0, 36.0, -110.0),
		"discovered": false
	},
	"whispering_grotto": {
		"title": "🔮 Whispering Grotto",
		"desc": "A vaulted subterranean rock cavern carved beneath the mountain roots, illuminated by azure crystals.",
		"coords": Vector3(-78.0, 16.5, -72.0),
		"discovered": false
	},
	"glacial_waterfall": {
		"title": "🌊 Silverveil Glacial Falls",
		"desc": "A thundering glacial mountain cascade spilling from the Alpine Tarn down stepped rock crags.",
		"coords": Vector3(-96.0, 26.5, -88.0),
		"discovered": false
	}
}

# --- FAUNA SPECIES (4 Total) ---
var _species: Dictionary = {
	"red_deer": {
		"title": "🦌 Red Deer (Cervus elaphus)",
		"role": "Keystone Herbivore",
		"desc": "Gentle grazers feeding on meadow flora. Highly alert to sounds, fleeing when sprinted upon.",
		"cataloged": false
	},
	"gray_wolf": {
		"title": "🐺 Gray Wolf (Canis lupus)",
		"role": "Apex Pack Predator",
		"desc": "Solitary and pack hunters patrolling mountain ridges. Regulates deer populations to prevent overgrazing.",
		"cataloged": false
	},
	"forest_songbird": {
		"title": "🐦 Alpine Songbird (Passeriformes)",
		"role": "Diurnal Canopy Indicator",
		"desc": "Diurnal forest birds filling the sunlit canopy with resonant morning and midday warbles.",
		"cataloged": false
	},
	"meadow_firefly": {
		"title": "✨ Bioluminescent Firefly (Photinus pyralis)",
		"role": "Nocturnal Glade Bio-Indicator",
		"desc": "Warm floating bioluminescent motes appearing in sheltered meadows at dusk and through the night.",
		"cataloged": false
	}
}

# --- PHENOMENA (4 Total) ---
var _phenomena: Dictionary = {
	"aurora_borealis": {
		"title": "🌌 Celestial Aurora Borealis",
		"desc": "Undulating green-to-magenta magnetic curtains dancing across the northern night sky.",
		"witnessed": false
	},
	"shooting_star": {
		"title": "🌠 Celestial Shooting Star",
		"desc": "A flash of meteor dust streaking across the starlit firmament.",
		"witnessed": false
	},
	"glacial_blizzard": {
		"title": "❄️ Skyspire Summit Blizzard",
		"desc": "High-altitude spindrift ice needles swirling along the windswept 86m arête.",
		"witnessed": false
	},
	"monsoon_rain": {
		"title": "🌧️ Temperate Island Rainstorm",
		"desc": "Heavy cloud cover and pelting raindrops creating dynamic surface puddles and ripples.",
		"witnessed": false
	}
}

# --- MILESTONES ---
var _milestones_unlocked: Dictionary = {}

var _discovered_landmarks_count: int = 0
var _cataloged_species_count: int = 0
var _witnessed_phenomena_count: int = 0

var _expedition_start_time: float = 0.0
var _elapsed_expedition_seconds: float = 0.0
var _distance_traveled: float = 0.0
var _last_player_pos: Vector3 = Vector3.ZERO
var _has_last_pos: bool = false
var _expedition_points: int = 0

const JOURNAL_SAVE_PATH: String = "user://expedition_journal.json"

func add_expedition_points(points: int) -> void:
	_expedition_points += points
	print("[ExpeditionManager] Expedition points +%d (Total: %d)" % [points, _expedition_points])

func get_expedition_points() -> int:
	return _expedition_points

func _init() -> void:
	pass

func set_game_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	var old: GameState = current_state
	current_state = new_state
	state_changed.emit(old, new_state)

func record_player_step(current_pos: Vector3, delta: float) -> void:
	if current_state != GameState.PLAYING:
		return
	_elapsed_expedition_seconds += delta
	if not _has_last_pos:
		_last_player_pos = current_pos
		_has_last_pos = true
		return
	var step_dist: float = Vector2(current_pos.x - _last_player_pos.x, current_pos.z - _last_player_pos.z).length()
	if step_dist > 0.05 and step_dist < 20.0:
		_distance_traveled += step_dist
	_last_player_pos = current_pos

# =========================================================================
# DISCOVERY REGISTRATION
# =========================================================================
func register_landmark_discovery(id: String) -> bool:
	if not _landmarks.has(id):
		return false
	var entry: Dictionary = _landmarks[id]
	if entry["discovered"]:
		return false
	entry["discovered"] = true
	_discovered_landmarks_count += 1
	landmark_discovered.emit(id, entry["title"], entry["desc"], _discovered_landmarks_count, _landmarks.size())
	_check_milestones()
	return true

func register_species_cataloged(species_id: String) -> bool:
	if not _species.has(species_id):
		return false
	var entry: Dictionary = _species[species_id]
	if entry["cataloged"]:
		return false
	entry["cataloged"] = true
	_cataloged_species_count += 1
	species_cataloged.emit(species_id, entry["title"], entry["role"], _cataloged_species_count, _species.size())
	_check_milestones()
	return true

func register_phenomenon_witnessed(phenom_id: String) -> bool:
	if not _phenomena.has(phenom_id):
		return false
	var entry: Dictionary = _phenomena[phenom_id]
	if entry["witnessed"]:
		return false
	entry["witnessed"] = true
	_witnessed_phenomena_count += 1
	phenomenon_witnessed.emit(phenom_id, entry["title"], _witnessed_phenomena_count, _phenomena.size())
	_check_milestones()
	return true

func _check_milestones() -> void:
	if _discovered_landmarks_count >= 1 and not _milestones_unlocked.has("first_steps"):
		_unlock_milestone("first_steps", "🧭 First Steps", "Discovered your first ancient island landmark.")
	if _discovered_landmarks_count >= 5 and not _milestones_unlocked.has("isle_scout"):
		_unlock_milestone("isle_scout", "🗺️ Island Scout", "Mapped 5 of the 11 ancient island landmarks.")
	if _discovered_landmarks_count >= _landmarks.size() and not _milestones_unlocked.has("master_cartographer"):
		_unlock_milestone("master_cartographer", "🏆 Master Cartographer", "Mapped every single geological landmark on the 720m continent!")
	if _cataloged_species_count >= _species.size() and not _milestones_unlocked.has("wildlife_scholar"):
		_unlock_milestone("wildlife_scholar", "🐾 Wildlife Naturalist", "Cataloged all native animal and bird species.")
	if _witnessed_phenomena_count >= _phenomena.size() and not _milestones_unlocked.has("aurora_seer"):
		_unlock_milestone("aurora_seer", "🌌 Sky Watcher", "Witnessed all celestial and atmospheric spectacles.")
	if _photos.size() >= 1 and not _milestones_unlocked.has("shutter_novice"):
		_unlock_milestone("shutter_novice", "📸 Shutter Novice", "Captured your first naturalist field photograph.")
	if _photos.size() >= 3 and not _milestones_unlocked.has("wildlife_chronicler"):
		_unlock_milestone("wildlife_chronicler", "🦁 Wildlife Chronicler", "Documented 3 field photographs in the naturalist journal.")
	if _photos.size() >= 5 and not _milestones_unlocked.has("master_photographer"):
		_unlock_milestone("master_photographer", "🎨 Master of Light", "Captured 5 field photographs across different optical spectrums and biomes.")
	if get_botanical_survey_count() >= 3 and not _milestones_unlocked.has("master_botanist"):
		_unlock_milestone("master_botanist", "🌿 Island Herbalist", "Cataloged and surveyed distinct flora across seasonal phenological cycles.")
	if _sound_logs.size() >= 3 and not _milestones_unlocked.has("acoustic_naturalist"):
		_unlock_milestone("acoustic_naturalist", "🎙️ Master of Island Voices", "Recorded and analyzed 3 distinct wildlife bio-acoustic audio logs.")

func _unlock_milestone(id: String, title: String, desc: String) -> void:
	_milestones_unlocked[id] = {
		"title": title,
		"desc": desc,
		"time": _elapsed_expedition_seconds
	}
	milestone_unlocked.emit(id, title, desc)

# =========================================================================
# BOTANICAL PHENOLOGY SURVEYS
# =========================================================================
func register_botanical_survey(species: String, season_name: String = "Spring") -> bool:
	if not _botanical_surveys.has(species):
		_botanical_surveys[species] = []
	var list: Array = _botanical_surveys[species]
	if not list.has(season_name):
		list.append(season_name)
		_check_milestones()
		return true
	return false

func get_botanical_survey_count() -> int:
	var total: int = 0
	for k in _botanical_surveys:
		total += (_botanical_surveys[k] as Array).size()
	return total

func get_botanical_surveys() -> Dictionary:
	return _botanical_surveys

# =========================================================================
# BIO-ACOUSTIC SOUND LOGS
# =========================================================================
func save_sound_log(species_name: String, frequency_hz: float, decibels: float, bearing_degrees: float, location_name: String, timestamp_str: String) -> Dictionary:
	var log_id: int = _sound_logs.size() + 1
	var log_entry: Dictionary = {
		"id": log_id,
		"species": species_name,
		"frequency_hz": frequency_hz,
		"decibels": decibels,
		"bearing": bearing_degrees,
		"location": location_name,
		"timestamp": timestamp_str
	}
	_sound_logs.append(log_entry)
	_check_milestones()
	return log_entry

func get_sound_logs() -> Array[Dictionary]:
	return _sound_logs

func get_sound_log_count() -> int:
	return _sound_logs.size()

# =========================================================================
# PHOTO SNAPSHOT MANAGEMENT
# =========================================================================
func save_photo(subject_name: String, subject_type: String, distance: float, quality_score: int, location_name: String, timestamp_str: String, stealth_bonus: bool = false, filter_name: String = "Natural Spectrum") -> Dictionary:
	var photo_id: int = _photos.size() + 1
	var photo_entry: Dictionary = {
		"id": photo_id,
		"subject": subject_name,
		"type": subject_type, # "FAUNA", "LANDMARK", "PHENOMENON", "LANDSCAPE"
		"distance": distance,
		"score": quality_score,
		"stealth": stealth_bonus,
		"location": location_name,
		"timestamp": timestamp_str,
		"quality_score": quality_score,
		"quality_rating": clampi(int(round(float(quality_score) / 20.0)), 1, 5),
		"stealth_unalerted": stealth_bonus,
		"filter": filter_name
	}
	_photos.append(photo_entry)
	photo_saved.emit(photo_entry)
	_check_milestones()
	check_quest_progress("PHOTO_TAKEN", photo_entry)
	return photo_entry

func get_photos() -> Array[Dictionary]:
	return _photos

func get_photo_count() -> int:
	return _photos.size()

# =========================================================================
# EXPEDITION COMMISSIONS & QUESTS
# =========================================================================
func generate_seed_quests(seed_val: int) -> void:
	_quests.clear()
	# Contract 1: Geographical survey
	_quests.append({
		"id": "survey_summit",
		"title": "🏔️ Skyspire Alpine Expedition",
		"desc": "Scale the Skyspire Alpine Peak or Alpine Tarn (altitude Y >= 50m).",
		"category": "SURVEY",
		"target_progress": 50,
		"current_progress": 0,
		"progress": 0,
		"target": 50,
		"completed": false,
		"xp": 150
	})
	# Contract 2: Wildlife Photography
	_quests.append({
		"id": "photo_deer_stealth",
		"title": "🦌 Stealth Wildlife Photography",
		"desc": "Capture 2 field photographs of living fauna (Red Deer / Gray Wolf).",
		"category": "FAUNA_PHOTO",
		"target_progress": 2,
		"current_progress": 0,
		"progress": 0,
		"target": 2,
		"completed": false,
		"xp": 200
	})
	# Contract 3: Natural Wonders
	_quests.append({
		"id": "survey_landmarks",
		"title": "🗿 Island Heritage Survey",
		"desc": "Discover at least 1 natural landmark or ancient ruin across the island.",
		"category": "LANDMARKS",
		"target_progress": 1,
		"current_progress": 0,
		"progress": 0,
		"target": 1,
		"completed": false,
		"xp": 250
	})
func register_skyspire_quests() -> void:
	for q in _quests:
		if q.get("id", "") == "skyspire_ascent_phase1":
			return
	_quests.append({
		"id": "skyspire_ascent_phase1",
		"title": "🏔️ Skyspire Expedition: The Glacial Approach",
		"desc": "Advance into the Northwest Massif and reach the Alpine Tarn (Altitude Y >= 35m).",
		"category": "SKYSPIRE_ASCENT",
		"target_progress": 35,
		"current_progress": 0,
		"progress": 0,
		"target": 35,
		"completed": false,
		"xp": 300
	})
	_quests.append({
		"id": "skyspire_ascent_phase2",
		"title": "🧗 Skyspire Expedition: The Frostbite Arête",
		"desc": "Conquer sheer snow-slicked cliffs using stamina-managed climbing (Altitude Y >= 70m).",
		"category": "SKYSPIRE_ASCENT",
		"target_progress": 70,
		"current_progress": 0,
		"progress": 0,
		"target": 70,
		"completed": false,
		"xp": 500
	})
	_quests.append({
		"id": "skyspire_ascent_phase3",
		"title": "👑 Skyspire Expedition: Crown of the Heavens",
		"desc": "Reach the 114m soaring summit and awaken the Ancient Anemo Spire Beacon Altar.",
		"category": "SKYSPIRE_ASCENT",
		"target_progress": 110,
		"current_progress": 0,
		"progress": 0,
		"target": 110,
		"completed": false,
		"xp": 1000
	})

func add_custom_commission(id: String, title: String, desc: String, category: String = "VILLAGE", target: int = 1, xp: int = 350) -> void:
	for q in _quests:
		if q.get("id", "") == id:
			return # Already accepted
	var new_quest: Dictionary = {
		"id": id,
		"title": title,
		"desc": desc,
		"category": category,
		"target_progress": target,
		"current_progress": 0,
		"progress": 0,
		"target": target,
		"completed": false,
		"xp": xp
	}
	_quests.append(new_quest)
	quest_accepted.emit(id, title)
	print("[ExpeditionManager] New Commission Accepted: %s (%s)" % [title, id])

func check_quest_progress(event_type: String, data: Dictionary) -> bool:
	var any_completed: bool = false
	for q in _quests:
		if q.get("completed", false):
			continue
		match q.get("category", ""):
			"SKYSPIRE_ASCENT":
				if event_type == "PLAYER_POSITION":
					var pos: Vector3 = data.get("position", Vector3.ZERO)
					# Northwest Massif coordinates (X <= -35, Z <= -35)
					if pos.x <= -35.0 and pos.z <= -35.0:
						if int(pos.y) > int(q["current_progress"]):
							q["current_progress"] = int(pos.y)
							q["progress"] = q["current_progress"]
						if pos.y >= float(q["target_progress"]):
							q["completed"] = true
							any_completed = true
							quest_completed.emit(q["id"], q["title"], q["xp"])
				elif event_type == "BEACON_ACTIVATED" or event_type == "CUSTOM_OBJECTIVE":
					var act_id: String = data.get("id", data.get("action_id", ""))
					if act_id == "skyspire_beacon" or act_id == q["id"]:
						q["current_progress"] = q["target_progress"]
						q["progress"] = q["target_progress"]
						q["completed"] = true
						any_completed = true
						quest_completed.emit(q["id"], q["title"], q["xp"])
			"SURVEY":
				if event_type == "PLAYER_POSITION":
					var pos: Vector3 = data.get("position", Vector3.ZERO)
					q["current_progress"] = int(pos.y)
					q["progress"] = q["current_progress"]
					if pos.y >= float(q["target_progress"]):
						q["completed"] = true
						any_completed = true
						quest_completed.emit(q["id"], q["title"], q["xp"])
			"FAUNA_PHOTO":
				if event_type == "PHOTO_TAKEN" or event_type == "PHOTO_CAPTURED":
					var sub_type: String = data.get("type", data.get("target_type", ""))
					var dist: float = float(data.get("distance", 15.0))
					if (sub_type == "FAUNA" or sub_type.is_empty()) and dist <= 35.0:
						q["current_progress"] = int(q["current_progress"]) + 1
						q["progress"] = q["current_progress"]
						if q["current_progress"] >= q["target_progress"]:
							q["completed"] = true
							any_completed = true
							quest_completed.emit(q["id"], q["title"], q["xp"])
			"LANDMARKS":
				if event_type == "LANDMARK_DISCOVERED":
					var poi_id: String = data.get("id", "")
					if poi_id == "whispering_grotto" or not poi_id.is_empty():
						q["current_progress"] = int(q["current_progress"]) + 1
						q["progress"] = q["current_progress"]
						if q["current_progress"] >= q["target_progress"]:
							q["completed"] = true
							any_completed = true
							quest_completed.emit(q["id"], q["title"], q["xp"])
			"VILLAGE", "BOAT_VOYAGE", "HERBAL_DISCOVERY", "CASTLE_RUINS", "SUNKEN_GALLEON":
				if event_type == "VILLAGE_ACTION" or event_type == "CUSTOM_OBJECTIVE":
					var act_id: String = data.get("action_id", "")
					var q_id: String = data.get("quest_id", "")
					if act_id == q["id"] or q_id == q["id"] or event_type == q["category"]:
						q["current_progress"] = int(q["current_progress"]) + 1
						q["progress"] = q["current_progress"]
						if q["current_progress"] >= q["target_progress"]:
							q["completed"] = true
							any_completed = true
							quest_completed.emit(q["id"], q["title"], q["xp"])
	return any_completed

func get_active_quests() -> Array[Dictionary]:
	return _quests

func get_completed_quests_count() -> int:
	var count: int = 0
	for q in _quests:
		if q.get("completed", false):
			count += 1
	return count

func get_total_quests_count() -> int:
	return _quests.size()

# =========================================================================
# GETTERS & TELEMETRY
# =========================================================================
func get_landmarks() -> Dictionary:
	return _landmarks

func get_species() -> Dictionary:
	return _species

func get_phenomena() -> Dictionary:
	return _phenomena

func get_milestones() -> Dictionary:
	return _milestones_unlocked

func get_landmark_progress() -> Dictionary:
	return {
		"discovered": _discovered_landmarks_count,
		"total": _landmarks.size(),
		"percentage": int((float(_discovered_landmarks_count) / float(_landmarks.size())) * 100.0)
	}

func get_species_progress() -> Dictionary:
	return {
		"cataloged": _cataloged_species_count,
		"total": _species.size(),
		"percentage": int((float(_cataloged_species_count) / float(_species.size())) * 100.0)
	}

func get_phenomena_progress() -> Dictionary:
	return {
		"witnessed": _witnessed_phenomena_count,
		"total": _phenomena.size(),
		"percentage": int((float(_witnessed_phenomena_count) / float(_phenomena.size())) * 100.0)
	}

func get_total_completion_percentage() -> int:
	var total_items: int = _landmarks.size() + _species.size() + _phenomena.size()
	var done_items: int = _discovered_landmarks_count + _cataloged_species_count + _witnessed_phenomena_count
	return int((float(done_items) / float(total_items)) * 100.0)

func get_distance_traveled_meters() -> float:
	return _distance_traveled

func get_elapsed_seconds() -> float:
	return _elapsed_expedition_seconds

# =========================================================================
# PERSISTENCE (SAVE / LOAD JOURNAL)
# =========================================================================
func save_journal(path: String = JOURNAL_SAVE_PATH) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	var data: Dictionary = {
		"seed": active_seed,
		"mode": game_mode,
		"elapsed_seconds": _elapsed_expedition_seconds,
		"distance_meters": _distance_traveled,
		"landmarks": {},
		"species": {},
		"phenomena": {},
		"milestones": _milestones_unlocked,
		"photos": _photos,
		"sound_logs": _sound_logs,
		"botanical_surveys": _botanical_surveys,
		"quests": _quests
	}
	for k in _landmarks:
		data["landmarks"][k] = _landmarks[k]["discovered"]
	for k in _species:
		data["species"][k] = _species[k]["cataloged"]
	for k in _phenomena:
		data["phenomena"][k] = _phenomena[k]["witnessed"]

	file.store_string(JSON.stringify(data, "  "))
	file.close()
	return OK

func load_journal(path: String = JOURNAL_SAVE_PATH) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return FileAccess.get_open_error()
	var json_str: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_str)
	if not (parsed is Dictionary):
		return ERR_PARSE_ERROR

	var data: Dictionary = parsed as Dictionary
	active_seed = data.get("seed", 1337)
	game_mode = data.get("mode", "Explorer")
	_elapsed_expedition_seconds = data.get("elapsed_seconds", 0.0)
	_distance_traveled = data.get("distance_meters", 0.0)

	var saved_landmarks: Dictionary = data.get("landmarks", {})
	_discovered_landmarks_count = 0
	for k in saved_landmarks:
		if _landmarks.has(k):
			_landmarks[k]["discovered"] = saved_landmarks[k]
			if _landmarks[k]["discovered"]:
				_discovered_landmarks_count += 1

	var saved_species: Dictionary = data.get("species", {})
	_cataloged_species_count = 0
	for k in saved_species:
		if _species.has(k):
			_species[k]["cataloged"] = saved_species[k]
			if _species[k]["cataloged"]:
				_cataloged_species_count += 1

	var saved_phenomena: Dictionary = data.get("phenomena", {})
	_witnessed_phenomena_count = 0
	for k in saved_phenomena:
		if _phenomena.has(k):
			_phenomena[k]["witnessed"] = saved_phenomena[k]
			if _phenomena[k]["witnessed"]:
				_witnessed_phenomena_count += 1

	_milestones_unlocked = data.get("milestones", {})
	_photos = []
	var saved_photos: Array = data.get("photos", [])
	for p in saved_photos:
		if p is Dictionary:
			_photos.append(p)

	_sound_logs = []
	var saved_sound_logs: Array = data.get("sound_logs", [])
	for s in saved_sound_logs:
		if s is Dictionary:
			_sound_logs.append(s)

	_botanical_surveys = data.get("botanical_surveys", {})

	_quests = []
	var saved_quests: Array = data.get("quests", [])
	for q in saved_quests:
		if q is Dictionary:
			_quests.append(q)

	return OK
