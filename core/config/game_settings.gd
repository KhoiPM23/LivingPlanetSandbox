class_name GameSettings
extends RefCounted

## GameSettings: Centralized player configuration management with disk persistence.
## Manages Graphics Presets, Audio Bus Volumes, Display Modes, and Camera Controls.

const CONFIG_PATH: String = "user://settings.cfg"
const UIAudioFeedback = preload("res://presentation/audio/ui_audio_feedback.gd")

# Graphics
var graphics_preset: int = 1 # 0: Low, 1: Balanced (Default Iris Xe), 2: Cinematic
var window_mode: int = 0     # 0: Windowed (1280x720), 1: Fullscreen
var fog_enabled: bool = true
var render_scale: float = 0.85

# Audio (Linear 0.0 - 1.0)
var master_volume: float = 0.85
var ambience_volume: float = 0.85
var sfx_volume: float = 0.85

# Controls
var mouse_sensitivity: float = 0.003
var flight_speed: float = 18.0
var invert_y: bool = false

static var _current = null

static func get_current():
	if _current == null:
		_current = new()
		_current.load_from_disk()
	return _current

func save_to_disk(path: String = CONFIG_PATH) -> Error:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("graphics", "preset", graphics_preset)
	cfg.set_value("graphics", "window_mode", window_mode)
	cfg.set_value("graphics", "fog_enabled", fog_enabled)
	cfg.set_value("graphics", "render_scale", render_scale)

	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "ambience_volume", ambience_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)

	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "flight_speed", flight_speed)
	cfg.set_value("controls", "invert_y", invert_y)

	return cfg.save(path)

func load_from_disk(path: String = CONFIG_PATH) -> Error:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(path)
	if err != OK:
		# Use robust defaults
		return err

	graphics_preset = cfg.get_value("graphics", "preset", 1)
	window_mode = cfg.get_value("graphics", "window_mode", 0)
	fog_enabled = cfg.get_value("graphics", "fog_enabled", true)
	render_scale = cfg.get_value("graphics", "render_scale", 0.85)

	master_volume = cfg.get_value("audio", "master_volume", 0.85)
	ambience_volume = cfg.get_value("audio", "ambience_volume", 0.85)
	sfx_volume = cfg.get_value("audio", "sfx_volume", 0.85)

	mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", 0.003)
	flight_speed = cfg.get_value("controls", "flight_speed", 18.0)
	invert_y = cfg.get_value("controls", "invert_y", false)
	return OK

func apply_all(root_node: Node) -> void:
	if root_node == null:
		return

	# 1. Apply Graphics Preset
	GraphicsPresets.apply_preset(graphics_preset as GraphicsPresets.Preset, root_node)

	# 2. Apply Display Window Mode
	if window_mode == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# 3. Apply Fog
	var env_node: WorldEnvironment = root_node.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if env_node and env_node.environment:
		env_node.environment.fog_enabled = fog_enabled

	# 4. Apply Audio Volumes
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		if master_volume <= 0.01:
			AudioServer.set_bus_mute(master_idx, true)
		else:
			AudioServer.set_bus_mute(master_idx, false)
			AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))

	var audio_feedback: UIAudioFeedback = UIAudioFeedback.get_singleton()
	if audio_feedback:
		audio_feedback.set_sfx_volume_scale(sfx_volume)

	var audio_dir = root_node.find_child("SpatialAudioDirector", true, false)
	if audio_dir and audio_dir.has_method("set_ambience_volume_scale"):
		audio_dir.call("set_ambience_volume_scale", ambience_volume)

	# 5. Apply Camera Controls
	var cam: FreeLookCamera = root_node.find_child("FreeLookCamera", true, false) as FreeLookCamera
	if cam:
		cam.mouse_sensitivity = mouse_sensitivity
		cam.move_speed = flight_speed
		cam.fast_move_speed = flight_speed * 2.2
