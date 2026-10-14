class_name ExperimentHistory
extends RefCounted

## Tracks scientific experiment history for Living Planet Sandbox:
## Seed, initial conditions baseline, interventions, timestamps, and pre/post comparative metrics.
## Allows players to compare ecological outcomes before and after interventions.

signal experiment_recorded(record: Dictionary)
signal experiment_evaluated(record: Dictionary)

const MAX_EXPERIMENTS: int = 50

var master_seed: int = 1337
var initial_baseline: Dictionary = {}
var records: Array[Dictionary] = []
var _pending_evaluations: Array[Dictionary] = []
var _clock: WorldClock = null
var _exp_id_counter: int = 1

func _init(clock: WorldClock = null, seed_val: int = 1337) -> void:
	_clock = clock
	master_seed = seed_val

func init_baseline(seed_val: int, metrics_snapshot: Dictionary, sim_time: float = 0.0) -> void:
	master_seed = seed_val
	initial_baseline = {
		"seed": seed_val,
		"sim_time": sim_time,
		"plant_count": metrics_snapshot.get("plant_count", 0),
		"plant_biomass": metrics_snapshot.get("total_biomass", 0.0),
		"herbivore_count": metrics_snapshot.get("herbivore_count", 0),
		"predator_count": metrics_snapshot.get("predator_count", 0),
		"avg_speed": metrics_snapshot.get("avg_speed", 1.0),
		"avg_size": metrics_snapshot.get("avg_size", 1.0),
		"avg_efficiency": metrics_snapshot.get("avg_efficiency", 1.0),
		"speed_variance": metrics_snapshot.get("speed_variance", 0.0),
		"diversity_index": metrics_snapshot.get("diversity_index", 0.0)
	}

func record_experiment(
	action_name: String,
	action_type: String,
	pos: Vector3,
	radius: float,
	current_metrics: Dictionary,
	sim_time: float = -1.0,
	eval_delay: float = 20.0
) -> Dictionary:
	var t: float = sim_time if sim_time >= 0.0 else (_clock.simulation_time if _clock != null else 0.0)
	var formatted_time: String = _format_sim_time(t)

	var record: Dictionary = {
		"id": _exp_id_counter,
		"name": action_name,
		"action": action_type,
		"pos": pos,
		"radius": radius,
		"sim_time": t,
		"time_formatted": formatted_time,
		"pre_metrics": current_metrics.duplicate(true),
		"post_metrics": {},
		"eval_target_time": t + eval_delay,
		"is_evaluated": false,
		"summary": "Observing immediate and downstream response (evaluating at %s)..." % _format_sim_time(t + eval_delay)
	}
	_exp_id_counter += 1

	records.append(record)
	if records.size() > MAX_EXPERIMENTS:
		records.pop_front()

	_pending_evaluations.append(record)
	experiment_recorded.emit(record)
	return record

func create_manual_checkpoint(label: String, current_metrics: Dictionary, sim_time: float = -1.0) -> Dictionary:
	var t: float = sim_time if sim_time >= 0.0 else (_clock.simulation_time if _clock != null else 0.0)
	var formatted_time: String = _format_sim_time(t)

	var record: Dictionary = {
		"id": _exp_id_counter,
		"name": "Checkpoint: " + label,
		"action": "manual_checkpoint",
		"pos": Vector3.ZERO,
		"radius": 0.0,
		"sim_time": t,
		"time_formatted": formatted_time,
		"pre_metrics": current_metrics.duplicate(true),
		"post_metrics": current_metrics.duplicate(true),
		"eval_target_time": t,
		"is_evaluated": true,
		"summary": "Manual ecological snapshot captured at %s" % formatted_time
	}
	_exp_id_counter += 1

	records.append(record)
	if records.size() > MAX_EXPERIMENTS:
		records.pop_front()

	experiment_recorded.emit(record)
	return record

func step(sim_time: float, current_metrics: Dictionary) -> void:
	var pending_idx: int = _pending_evaluations.size() - 1
	while pending_idx >= 0:
		var rec: Dictionary = _pending_evaluations[pending_idx]
		if sim_time >= float(rec.get("eval_target_time", 0.0)):
			rec["post_metrics"] = current_metrics.duplicate(true)
			rec["is_evaluated"] = true
			rec["summary"] = _generate_comparison_summary(rec["pre_metrics"], rec["post_metrics"], rec["action"])
			_pending_evaluations.remove_at(pending_idx)
			experiment_evaluated.emit(rec)
		pending_idx -= 1

func _generate_comparison_summary(pre: Dictionary, post: Dictionary, action: String) -> String:
	var pre_p: int = int(pre.get("plant_count", 0))
	var post_p: int = int(post.get("plant_count", 0))
	var p_diff: int = post_p - pre_p
	var p_pct: float = (float(p_diff) / float(pre_p) * 100.0) if pre_p > 0 else 0.0

	var pre_h: int = int(pre.get("herbivore_count", 0))
	var post_h: int = int(post.get("herbivore_count", 0))
	var h_diff: int = post_h - pre_h

	var pre_spd_var: float = float(pre.get("speed_variance", 0.0))
	var post_spd_var: float = float(post.get("speed_variance", 0.0))
	var var_diff: float = post_spd_var - pre_spd_var

	var pre_div: float = float(pre.get("diversity_index", 0.0))
	var post_div: float = float(post.get("diversity_index", 0.0))

	var lines: Array[String] = []

	if action == "mutate_population":
		lines.append("Genetic Trait Shift: Speed Var %.4f -> %.4f (%+.1f%%)" % [
			pre_spd_var, post_spd_var,
			((post_spd_var - pre_spd_var) / maxf(0.0001, pre_spd_var)) * 100.0
		])
		lines.append("Diversity Index: %.2f -> %.2f" % [pre_div, post_div])
	elif action == "climate_pulse" or action == "deluge":
		var pre_bio: float = float(pre.get("total_biomass", 0.0))
		var post_bio: float = float(post.get("total_biomass", 0.0))
		var bio_pct: float = ((post_bio - pre_bio) / maxf(0.1, pre_bio)) * 100.0
		lines.append("Biomass: %.1f -> %.1f kg (%+.1f%%)" % [pre_bio, post_bio, bio_pct])
		lines.append("Flora: %d -> %d (%+d)" % [pre_p, post_p, p_diff])
	else:
		lines.append("Flora: %d -> %d (%+.1f%%)" % [pre_p, post_p, p_pct])
		lines.append("Fauna: %d -> %d (%+d)" % [pre_h, post_h, h_diff])

	return " | ".join(lines)

func _format_sim_time(t: float) -> String:
	var day_duration: float = 120.0
	var sim_offset: float = t + (9.0 / 24.0) * day_duration
	var day_phase: float = fmod(sim_offset / day_duration, 1.0)
	var total_hours: float = day_phase * 24.0
	var hours: int = int(total_hours)
	var minutes: int = int((total_hours - float(hours)) * 60.0)
	return "%02d:%02d" % [hours, minutes]

func get_experiments() -> Array[Dictionary]:
	return records

func get_initial_baseline() -> Dictionary:
	return initial_baseline

func serialize() -> Dictionary:
	var rec_serialized: Array[Dictionary] = []
	for r in records:
		var copy: Dictionary = r.duplicate(true)
		if copy.has("pos") and copy["pos"] is Vector3:
			var v: Vector3 = copy["pos"]
			copy["pos"] = [v.x, v.y, v.z]
		rec_serialized.append(copy)

	return {
		"master_seed": master_seed,
		"initial_baseline": initial_baseline.duplicate(true),
		"records": rec_serialized
	}

func deserialize(data: Dictionary) -> void:
	master_seed = int(data.get("master_seed", 1337))
	initial_baseline = data.get("initial_baseline", {}).duplicate(true)
	records.clear()
	_pending_evaluations.clear()

	var recs: Array = data.get("records", [])
	for r in recs:
		if r is Dictionary:
			var copy: Dictionary = r.duplicate(true)
			if copy.has("pos") and copy["pos"] is Array:
				var arr: Array = copy["pos"]
				if arr.size() >= 3:
					copy["pos"] = Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
			records.append(copy)
			if not copy.get("is_evaluated", true):
				_pending_evaluations.append(copy)

func clear() -> void:
	records.clear()
	_pending_evaluations.clear()
	initial_baseline.clear()
