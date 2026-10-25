class_name LivingWorldDirector
extends Node

## Living World Director — Block 10: Ecological Emergent Events & Gameplay Integration.
##
## Subscribes to existing WorldEventBus events and WorldClock signals to detect
## and broadcast meaningful gameplay moments without building parallel systems.
##
## Emergent events detected:
##   1. STORM_INCOMING — WeatherSystem transitions to RAIN or DROUGHT
##   2. PREDATION_OBSERVED — a herbivore dies by predation (wildlife kill)
##   3. POPULATION_COLLAPSE — herbivore count drops to or below the collapse threshold
##   4. POPULATION_RECOVERY — herbivore count rises above safe threshold after collapse
##   5. DAWN_CHORUS — WorldClock crosses sim-hour 6 (sunrise)
##   6. DUSK_TRANSITION — WorldClock crosses sim-hour 20 (sunset / nightfall)
##   7. CAUSAL_CASCADE — causal_cascade_observed event re-broadcast with HUD context
##   8. HERD_STAMPEDE — player approaches within 10m with 3+ herbivores fleeing simultaneously

signal emergent_event(event_type: String, title: String, body: String, severity: String)

# Severity constants for HUD badge colour
const SEV_INFO     = "info"       # Soft teal
const SEV_NOTICE   = "notice"     # Green
const SEV_WARNING  = "warning"    # Amber
const SEV_CRITICAL = "critical"   # Red

# Population collapse threshold
const COLLAPSE_THRESHOLD: int = 3
const RECOVERY_THRESHOLD: int = 8

# Time constants
const DAWN_HOUR: float = 6.0
const DUSK_HOUR: float = 20.0

# References — wired from main.gd via setup()
var _clock: WorldClock = null
var _event_bus: WorldEventBus = null
var _fauna_sim: FaunaSimulation = null
var _weather: WeatherSystem = null

# State tracking & diurnal latching
var _last_sim_hour: float = -1.0
var _last_day_num: int = -1
var _dawn_fired_day: int = -1
var _dusk_fired_day: int = -1
var _in_collapse: bool = false
var _last_herb_count: int = 0
var _stampede_cooldown: float = 0.0
var _stampede_cooldown_max: float = 30.0  # seconds real time

# Global event pacing (Block 27 — avoids theme-park spam, ensures quiet contemplation)
var _global_pacing_cooldown: float = 0.0
var _min_event_interval: float = 12.0 # Minimum seconds between non-critical emergent events
var _pacing_strict: bool = false

# Internal cooldowns per event type to avoid spam (real seconds)
var _cooldowns: Dictionary = {}
const COOLDOWN_DEFAULTS: Dictionary = {
	"STORM_INCOMING":       45.0,
	"PREDATION_OBSERVED":   20.0,
	"DAWN_CHORUS":         120.0,
	"DUSK_TRANSITION":     120.0,
	"CAUSAL_CASCADE":       15.0,
	"HERD_STAMPEDE":        30.0,
	"HERD_ALARM":           25.0,
	"THIRST_MIGRATION":      40.0,
	"NOCTURNAL_SANCTUARY":  60.0,
	"RAIN_SHELTER":         45.0,
	"HUNT_ABORTED":         25.0,
	"DISTANT_WILDLIFE_CALL": 35.0,
	"VALLEY_MIST_GUST":     45.0,
}


# =========================================================================
# SETUP
# =========================================================================
func setup(
	clock: WorldClock,
	event_bus: WorldEventBus,
	fauna_sim: FaunaSimulation,
	weather: WeatherSystem
) -> void:
	_clock = clock
	_event_bus = event_bus
	_fauna_sim = fauna_sim
	_weather = weather

	# Subscribe to bus events
	if _event_bus:
		_event_bus.subscribe("fauna_died", Callable(self, "_on_fauna_died"))
		_event_bus.subscribe("ecosystem_metrics_updated", Callable(self, "_on_metrics_updated"))
		_event_bus.subscribe("causal_cascade_observed", Callable(self, "_on_causal_cascade"))
		_event_bus.subscribe("weather_changed", Callable(self, "_on_weather_changed"))
		_event_bus.subscribe("ecosystem_populated", Callable(self, "_on_ecosystem_populated"))
		_event_bus.subscribe("predator_hunt_aborted", Callable(self, "_on_predator_hunt_aborted"))


# =========================================================================
# MAIN LOOP — diurnal cycle & proximity checks
# =========================================================================
func _process(delta: float) -> void:
	# Advance cooldowns
	for key: String in _cooldowns.keys():
		_cooldowns[key] = maxf(0.0, _cooldowns[key] - delta)

	if _stampede_cooldown > 0.0:
		_stampede_cooldown -= delta

	if _global_pacing_cooldown > 0.0:
		_global_pacing_cooldown = maxf(0.0, _global_pacing_cooldown - delta)

	_check_diurnal_transitions()
	_check_player_stampede()
	_check_ecological_behaviors()


func _check_diurnal_transitions() -> void:
	if not _clock:
		return

	var sim_hour: float = _clock.get_sim_hour()
	var current_day: int = _clock.get_day_number()

	if _last_sim_hour < 0.0:
		_last_sim_hour = sim_hour
		_last_day_num = current_day
		# Initialize latching if starting midday or nighttime
		if sim_hour >= DAWN_HOUR:
			_dawn_fired_day = current_day
		if sim_hour >= DUSK_HOUR:
			_dusk_fired_day = current_day
		return

	# Handle time rewind or clock reset
	if current_day < _last_day_num or (current_day == _last_day_num and sim_hour < _last_sim_hour):
		if sim_hour < DAWN_HOUR:
			_dawn_fired_day = -1
		if sim_hour < DUSK_HOUR:
			_dusk_fired_day = -1

	# Detect hour boundary crossing
	var crossed_dawn: bool = false
	var crossed_dusk: bool = false

	if current_day == _last_day_num:
		crossed_dawn = _last_sim_hour < DAWN_HOUR and sim_hour >= DAWN_HOUR
		crossed_dusk = _last_sim_hour < DUSK_HOUR and sim_hour >= DUSK_HOUR
	else:
		# Crossed midnight into next day
		crossed_dawn = sim_hour >= DAWN_HOUR and sim_hour < DUSK_HOUR
		crossed_dusk = sim_hour >= DUSK_HOUR

	_last_sim_hour = sim_hour
	_last_day_num = current_day

	# Fire with strict per-day latching (impossible to double-fire on the same day)
	if crossed_dawn and _dawn_fired_day != current_day and _can_fire("DAWN_CHORUS"):
		_dawn_fired_day = current_day
		_fire_event(
			"DAWN_CHORUS",
			"🌅 Dawn Chorus",
			"Sunrise over the island. Birds erupt into song as the forest comes alive.",
			SEV_NOTICE
		)

	if crossed_dusk and _dusk_fired_day != current_day and _can_fire("DUSK_TRANSITION"):
		_dusk_fired_day = current_day
		_fire_event(
			"DUSK_TRANSITION",
			"🌙 Nightfall",
			"Darkness spreads across the island. Predators grow bolder under moonlight.",
			SEV_NOTICE
		)


func _check_player_stampede() -> void:
	if not _fauna_sim or not _fauna_sim.is_player_present():
		return
	if _stampede_cooldown > 0.0:
		return

	# Count herbivores currently fleeing from player
	var fleeing_count: int = 0
	var player_pos: Vector3 = _fauna_sim.get_player_position()

	for h: FaunaSimulation.HerbivoreData in _fauna_sim.get_all_herbivores():
		if h.state == FaunaSimulation.HerbivoreState.FLEEING:
			var dist: float = h.position.distance_to(player_pos)
			if dist < 18.0:  # within proximity zone
				fleeing_count += 1

	if fleeing_count >= 3 and _can_fire("HERD_STAMPEDE"):
		_stampede_cooldown = _stampede_cooldown_max
		_fire_event(
			"HERD_STAMPEDE",
			"🦌 Herd Stampede!",
			"%d deer flee at your approach — the meadow erupts in motion." % fleeing_count,
			SEV_WARNING
		)

func trigger_player_proximity_event(player_pos: Vector3) -> void:
	if _fauna_sim:
		_fauna_sim.update_player(player_pos, 5.5, true)
	_check_player_stampede()

func _check_ecological_behaviors() -> void:
	if not _fauna_sim:
		return

	var alert_count: int = 0
	var drinking_count: int = 0
	var sheltered_resting_count: int = 0

	for h: FaunaSimulation.HerbivoreData in _fauna_sim.get_all_herbivores():
		if h.state == FaunaSimulation.HerbivoreState.ALERT:
			alert_count += 1
		elif h.state == FaunaSimulation.HerbivoreState.DRINKING:
			drinking_count += 1
		elif h.state == FaunaSimulation.HerbivoreState.RESTING and h.is_sheltered:
			sheltered_resting_count += 1

	if alert_count >= 2 and _can_fire("HERD_ALARM"):
		_fire_event(
			"HERD_ALARM",
			"⚠️ Herd Alert",
			"Stags raise their heads in vigilant watchfulness, scanning the clearing.",
			SEV_INFO
		)
	elif drinking_count >= 2 and _can_fire("THIRST_MIGRATION"):
		_fire_event(
			"THIRST_MIGRATION",
			"🌊 Shoreline Watering",
			"A band of deer gathers along the pebble shore of Emerald Basin to drink.",
			SEV_NOTICE
		)
	elif sheltered_resting_count >= 2 and _can_fire("NOCTURNAL_SANCTUARY"):
		_fire_event(
			"NOCTURNAL_SANCTUARY",
			"🌙 Night Canopy Shelter",
			"Fauna beds down beneath the protective Whispering Forest canopy.",
			SEV_INFO
		)
	elif (_weather != null and _weather.current_state == WeatherSystem.WeatherState.RAIN) and sheltered_resting_count >= 2 and _can_fire("RAIN_SHELTER"):
		_fire_event(
			"RAIN_SHELTER",
			"🌧️ Rain Canopy Refuge",
			"Fauna seeks shelter beneath dense Whispering Forest boughs as rain drenches the island.",
			SEV_INFO
		)
	elif _global_pacing_cooldown <= 0.0 and _can_fire("DISTANT_WILDLIFE_CALL"):
		if _fauna_sim and _fauna_sim.get_herbivore_count() >= 3:
			var rand_sec: int = randi() % 4
			_fire_event(
				"DISTANT_WILDLIFE_CALL",
				"📯 Distant Stag Belling",
				"A resonant rutting call echoes through the %s sector beyond the ridges." % FaunaSimulation.SECTOR_NAMES[rand_sec],
				SEV_INFO
			)



# =========================================================================
# EVENT BUS CALLBACKS
# =========================================================================
func _on_fauna_died(payload: Dictionary) -> void:
	var reason: String = payload.get("reason", "natural")
	var ftype: String = payload.get("type", "herbivore")

	if reason == "predation" and ftype == "herbivore" and _can_fire("PREDATION_OBSERVED"):
		_fire_event(
			"PREDATION_OBSERVED",
			"🐺 Predator Kill",
			"A stalker brought down a deer in the wilderness. The cycle of life continues.",
			SEV_WARNING
		)

func _on_predator_hunt_aborted(payload: Dictionary) -> void:
	if _can_fire("HUNT_ABORTED"):
		_fire_event(
			"HUNT_ABORTED",
			"🦌 Prey Outruns Stalker",
			"The stag's endurance prevails — the predator breaks off pursuit to recover breath.",
			SEV_INFO
		)


func _on_metrics_updated(payload: Dictionary) -> void:
	var herb_count: int = payload.get("herbivore_count", _last_herb_count)
	var old_count: int = _last_herb_count
	_last_herb_count = herb_count

	# Population collapse detection
	if herb_count <= COLLAPSE_THRESHOLD and old_count > COLLAPSE_THRESHOLD and not _in_collapse:
		_in_collapse = true
		_fire_event(
			"POPULATION_COLLAPSE",
			"💀 Population Collapse",
			"Herbivore population has crashed to %d — ecosystem balance is critical!" % herb_count,
			SEV_CRITICAL,
			true  # bypass cooldown: critical event
		)

	# Recovery after collapse
	elif herb_count >= RECOVERY_THRESHOLD and _in_collapse:
		_in_collapse = false
		_fire_event(
			"POPULATION_RECOVERY",
			"🌱 Ecosystem Recovery",
			"Deer population has recovered to %d. Ecological balance is restored." % herb_count,
			SEV_NOTICE,
			true
		)


func _on_causal_cascade(payload: Dictionary) -> void:
	if not _can_fire("CAUSAL_CASCADE"):
		return

	var headline: String = payload.get("headline", "")
	var narrative: String = payload.get("narrative", "")
	if headline.is_empty():
		return

	_fire_event(
		"CAUSAL_CASCADE",
		"🔗 " + headline,
		narrative,
		SEV_INFO
	)


func _on_weather_changed(payload: Dictionary) -> void:
	var new_weather: String = payload.get("new_weather", "")
	var old_weather: String = payload.get("old_weather", "")

	if new_weather == "Gentle Rain" and _can_fire("STORM_INCOMING"):
		_fire_event(
			"STORM_INCOMING",
			"🌧️ Rain Begins",
			"Clouds gather and rain falls across the island. Flora will absorb the moisture.",
			SEV_NOTICE
		)
	elif new_weather == "Arid Drought" and _can_fire("STORM_INCOMING"):
		_fire_event(
			"STORM_INCOMING",
			"☀️ Drought Setting In",
			"The sun beats down mercilessly. Soil moisture evaporates — plants will suffer.",
			SEV_WARNING
		)
	elif new_weather == "Clear Skies" and old_weather == "Gentle Rain" and _can_fire("STORM_INCOMING"):
		_fire_event(
			"STORM_INCOMING",
			"🌤️ Skies Clear",
			"The rain passes. Sunlight returns to the valley meadows.",
			SEV_INFO
		)


func _on_ecosystem_populated(payload: Dictionary) -> void:
	var plants: int = payload.get("plants", 0)
	var herbs: int = payload.get("herbivores", 0)
	var preds: int = payload.get("predators", 0)
	_last_herb_count = herbs
	_in_collapse = (herbs <= COLLAPSE_THRESHOLD)
	print("[LivingWorldDirector] Ecosystem ready: %d plants, %d deer, %d stalkers" % [plants, herbs, preds])


# =========================================================================
# INTERNAL HELPERS
# =========================================================================
func _can_fire(event_type: String) -> bool:
	return _cooldowns.get(event_type, 0.0) <= 0.0


func _fire_event(
	event_type: String,
	title: String,
	body: String,
	severity: String,
	bypass_cooldown: bool = false
) -> void:
	if not bypass_cooldown:
		if not _can_fire(event_type):
			return
		if _pacing_strict and _global_pacing_cooldown > 0.0:
			return
		if _global_pacing_cooldown > 0.0 and (event_type == "DISTANT_WILDLIFE_CALL" or event_type == "VALLEY_MIST_GUST"):
			return

	if not bypass_cooldown:
		_cooldowns[event_type] = COOLDOWN_DEFAULTS.get(event_type, 20.0)
		_global_pacing_cooldown = _min_event_interval

	emergent_event.emit(event_type, title, body, severity)

	if _event_bus:
		_event_bus.publish("living_world_event", {
			"type": event_type,
			"title": title,
			"body": body,
			"severity": severity
		})

	print("[LivingWorld] %s: %s" % [severity.to_upper(), title])

func set_pacing_strict(enabled: bool) -> void:
	_pacing_strict = enabled

func is_pacing_strict() -> bool:
	return _pacing_strict

func get_global_pacing_cooldown() -> float:
	return _global_pacing_cooldown

func set_global_pacing_cooldown(val: float) -> void:
	_global_pacing_cooldown = val

func get_min_event_interval() -> float:
	return _min_event_interval

func set_min_event_interval(val: float) -> void:
	_min_event_interval = val

