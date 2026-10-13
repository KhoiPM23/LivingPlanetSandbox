class_name CausalTracker
extends RefCounted

## Tracks player environmental interventions (heatwaves, frosts, droughts, fertilizations)
## and establishes causal links to downstream ecological events (mortality, blooming, migrations).
## Emits structured causal explanations for UI event logging and inspector telemetry.

signal causal_cascade_detected(event_data: Dictionary)

const MAX_INTERVENTIONS: int = 50
const MAX_CAUSAL_HISTORY: int = 40

var _interventions: Array[Dictionary] = []
var _causal_history: Array[Dictionary] = []
var _clock: WorldClock = null

func _init(clock: WorldClock = null) -> void:
	_clock = clock

func record_intervention(type: String, pos: Vector3, radius: float, details: Dictionary = {}, sim_time: float = -1.0) -> void:
	var t: float = sim_time
	if t < 0.0:
		t = _clock.simulation_time if _clock != null else 0.0

	var entry: Dictionary = {
		"type": type,
		"pos": pos,
		"radius": radius,
		"time": t,
		"details": details
	}
	_interventions.append(entry)
	if _interventions.size() > MAX_INTERVENTIONS:
		_interventions.pop_front()

func get_interventions() -> Array[Dictionary]:
	return _interventions

func get_causal_history() -> Array[Dictionary]:
	return _causal_history

func find_recent_intervention_near(pos: Vector3, max_dist_margin: float = 12.0, max_age: float = 60.0) -> Dictionary:
	var cur_time: float = _clock.simulation_time if _clock != null else 0.0
	for i in range(_interventions.size() - 1, -1, -1):
		var interv: Dictionary = _interventions[i]
		var age: float = cur_time - float(interv.get("time", 0.0))
		if age < 0.0 or age > max_age:
			continue
		var interv_pos: Vector3 = interv.get("pos", Vector3.ZERO)
		var rad: float = float(interv.get("radius", 8.0))
		var max_dist: float = rad + max_dist_margin
		var dist_sq: float = (Vector2(pos.x, pos.z) - Vector2(interv_pos.x, interv_pos.z)).length_squared()
		if dist_sq <= max_dist * max_dist:
			return interv
	return {}

func get_causal_status_at(pos: Vector3) -> String:
	var interv: Dictionary = find_recent_intervention_near(pos, 6.0, 50.0)
	if interv.is_empty():
		return "Natural equilibrium"

	var cur_time: float = _clock.simulation_time if _clock != null else 0.0
	var age: float = maxf(0.0, cur_time - float(interv.get("time", 0.0)))
	var itype: String = interv.get("type", "")
	match itype:
		"heatwave":
			return "Heatwave stress (+8°C, %.0fs ago) — accelerated transpiration" % age
		"frost":
			return "Frost chill (-8°C, %.0fs ago) — reduced metabolic activity" % age
		"fertilize":
			return "Fertilized soil (2.5x, %.0fs ago) — accelerated biomass growth" % age
		"moisture_add":
			return "Moisture saturated (%.0fs ago) — optimal hydration" % age
		"moisture_sub":
			return "Desiccated soil (%.0fs ago) — drought moisture deficit" % age
		"disaster_shock":
			return "Disaster shock (%.0fs ago) — severe heat and desiccation" % age
		_:
			return "Intervened (%s, %.0fs ago)" % [itype, age]

func process_plant_death(plant_id: int, pos: Vector3, reason: String, sim_time: float = -1.0) -> Dictionary:
	var t: float = sim_time if sim_time >= 0.0 else (_clock.simulation_time if _clock != null else 0.0)
	var interv: Dictionary = find_recent_intervention_near(pos, 8.0, 60.0)
	if interv.is_empty():
		return {}

	var itype: String = interv.get("type", "")
	var headline: String = ""
	var narrative: String = ""

	if reason == "drought" and (itype == "moisture_sub" or itype == "disaster_shock" or itype == "heatwave"):
		headline = "Drought mortality triggered by player intervention"
		narrative = "Plant #%d withered due to induced moisture deficit following player %s at (%.1f, %.1f)." % [
			plant_id, itype, interv["pos"].x, interv["pos"].z
		]
	elif reason == "heatwave" and (itype == "heatwave" or itype == "disaster_shock"):
		headline = "Extreme heat scorch caused plant death"
		narrative = "Plant #%d succumbed to thermal stress following player heatwave at (%.1f, %.1f)." % [
			plant_id, interv["pos"].x, interv["pos"].z
		]
	elif reason == "frost" and itype == "frost":
		headline = "Frost necrosis destroyed vegetation"
		narrative = "Plant #%d froze following player frost cooling at (%.1f, %.1f)." % [
			plant_id, interv["pos"].x, interv["pos"].z
		]
	else:
		return {}

	var event: Dictionary = {
		"cause": itype,
		"effect": "plant_mortality",
		"headline": headline,
		"narrative": narrative,
		"position": pos,
		"timestamp": t
	}
	_log_causal_event(event)
	return event

func process_fauna_starvation(fauna_id: int, pos: Vector3, sim_time: float = -1.0) -> Dictionary:
	var t: float = sim_time if sim_time >= 0.0 else (_clock.simulation_time if _clock != null else 0.0)
	var interv: Dictionary = find_recent_intervention_near(pos, 16.0, 90.0)
	if interv.is_empty():
		return {}

	var itype: String = interv.get("type", "")
	if itype == "moisture_sub" or itype == "heatwave" or itype == "disaster_shock":
		var event: Dictionary = {
			"cause": itype,
			"effect": "fauna_starvation",
			"headline": "Herbivore starved following habitat desiccation",
			"narrative": "Herbivore #%d starved after player %s depleted edible vegetation in sector (%.1f, %.1f)." % [
				fauna_id, itype, interv["pos"].x, interv["pos"].z
			],
			"position": pos,
			"timestamp": t
		}
		_log_causal_event(event)
		return event
	return {}

func process_fertilizer_bloom(pos: Vector3, affected_count: int, sim_time: float = -1.0) -> Dictionary:
	var t: float = sim_time if sim_time >= 0.0 else (_clock.simulation_time if _clock != null else 0.0)
	var event: Dictionary = {
		"cause": "fertilize",
		"effect": "vegetation_bloom",
		"headline": "Nutrient bloom boosted local primary productivity",
		"narrative": "Vegetation growth accelerated (2.5x) across %d plants following player soil fertilization." % affected_count,
		"position": pos,
		"timestamp": t
	}
	_log_causal_event(event)
	return event

func _log_causal_event(event: Dictionary) -> void:
	_causal_history.append(event)
	if _causal_history.size() > MAX_CAUSAL_HISTORY:
		_causal_history.pop_front()
	causal_cascade_detected.emit(event)

func serialize() -> Array[Dictionary]:
	return _interventions.duplicate()

func deserialize(data: Array) -> void:
	_interventions.clear()
	for item in data:
		if item is Dictionary:
			_interventions.append(item)

func clear() -> void:
	_interventions.clear()
	_causal_history.clear()
