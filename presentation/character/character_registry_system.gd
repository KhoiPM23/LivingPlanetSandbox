class_name CharacterRegistrySystem
extends RefCounted

## Living Planet Sandbox — Multi-Character Registry & Switching System.
## Decouples character roster management from locomotion physics and camera controllers.
## Follows Single Responsibility and Open-Closed principles with graceful SFW repository guarantees.

signal character_switched(index: int, character_id: String, display_name: String)

class CharacterEntry:
	var id: String = ""
	var display_name: String = ""
	var icon: String = ""
	var model_path: String = ""
	var instance_node: Node3D = null
	var skeleton: Skeleton3D = null
	var is_optional: bool = false
	var scale: Vector3 = Vector3.ONE

var _roster: Array[CharacterEntry] = []
var _active_index: int = 0
var _last_switch_ms: int = 0

func _init() -> void:
	_build_default_roster()

func _build_default_roster() -> void:
	_roster.clear()

	# Character 0: Canonical Anime Heroine (SFW, default protagonist)
	var anime_entry: CharacterEntry = CharacterEntry.new()
	anime_entry.id = "anime_heroine"
	anime_entry.display_name = "Anime Heroine ⚔️"
	anime_entry.icon = "⚔️"
	anime_entry.model_path = "res://presentation/assets/models/anime_character.glb"
	anime_entry.scale = Vector3(0.82, 1.0, 0.82)
	anime_entry.is_optional = false
	_roster.append(anime_entry)

	# Character 1: Douyin Asian Beauty (Optional local content; if absent, falls back to Human Rogue)
	var douyin_path: String = "res://presentation/assets/models/douyin_asian_character.glb"
	var has_douyin: bool = ResourceLoader.exists(douyin_path) or FileAccess.file_exists(ProjectSettings.globalize_path(douyin_path))

	if has_douyin:
		var douyin_entry: CharacterEntry = CharacterEntry.new()
		douyin_entry.id = "douyin_beauty"
		douyin_entry.display_name = "Douyin Asian Beauty 💃"
		douyin_entry.icon = "💃"
		douyin_entry.model_path = douyin_path
		douyin_entry.scale = Vector3.ONE * 0.88
		douyin_entry.is_optional = true
		_roster.append(douyin_entry)
	else:
		# SFW Fallback: Human Rogue
		var human_path: String = "res://presentation/assets/models/human_character.glb"
		if ResourceLoader.exists(human_path) or FileAccess.file_exists(ProjectSettings.globalize_path(human_path)):
			var human_entry: CharacterEntry = CharacterEntry.new()
			human_entry.id = "human_rogue"
			human_entry.display_name = "Human Rogue 🏹"
			human_entry.icon = "🏹"
			human_entry.model_path = human_path
			human_entry.scale = Vector3(0.82, 1.0, 0.82)
			human_entry.is_optional = false
			_roster.append(human_entry)

func get_roster_count() -> int:
	return _roster.size()

func get_available_characters() -> Array[CharacterEntry]:
	return _roster.duplicate()

func get_character_by_id(id: String) -> CharacterEntry:
	for entry in _roster:
		if entry.id == id:
			return entry
	return null

func get_active_index() -> int:
	return _active_index

func get_active_entry() -> CharacterEntry:
	if _roster.is_empty():
		return null
	return _roster[clamp(_active_index, 0, _roster.size() - 1)]

func get_active_name() -> String:
	var entry = get_active_entry()
	return entry.display_name if entry else "Nhân vật mặc định"

func get_active_icon() -> String:
	var entry = get_active_entry()
	return entry.icon if entry else "👤"

func set_active_index(index: int) -> int:
	if _roster.is_empty():
		return 0
	_active_index = posmod(index, _roster.size())
	var entry = get_active_entry()
	character_switched.emit(_active_index, entry.id, entry.display_name)
	return _active_index

func switch_character() -> int:
	var now: int = Time.get_ticks_msec()
	if now - _last_switch_ms < 250:
		return _active_index
	_last_switch_ms = now

	if _roster.size() <= 1:
		# If only 1 character exists in SFW mode, remain on it
		return _active_index

	var next_idx: int = (_active_index + 1) % _roster.size()
	return set_active_index(next_idx)

func is_douyin_available() -> bool:
	for entry in _roster:
		if entry.id == "douyin_beauty":
			return true
	return false
