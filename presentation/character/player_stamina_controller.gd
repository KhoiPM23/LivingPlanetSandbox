class_name PlayerStaminaController
extends RefCounted

## Living Planet Sandbox — Block 63: Genshin-Grade Player Stamina System
## Drives traversal stamina expenditure and regeneration:
## - Drains during Sprinting (14.0/s), Gliding (7.5/s), Climbing (16.0/s), Wall Leaps (18.0 chunk)
## - Regenerates smoothly at 28.0/s after a 0.75s grace period when on ground/idle
## - Emits signals for HUD synchronization and exhaustion/recovery callbacks

signal stamina_changed(current: float, max_stamina: float, ratio: float)
signal stamina_exhausted()
signal stamina_recovered()

var max_stamina: float = 100.0
var current_stamina: float = 100.0
var current: float:
	get:
		return current_stamina
	set(v):
		current_stamina = v

var regen_rate: float = 28.0
var regen_delay: float = 0.75

var sprint_drain_rate: float = 14.0
var glide_drain_rate: float = 7.5
var climb_drain_rate: float = 16.0
var climb_idle_drain_rate: float = 3.5
var climb_jump_cost: float = 18.0

var is_exhausted: bool = false
var _regen_timer: float = 0.0

func _init(p_max_stamina: float = 100.0) -> void:
	max_stamina = p_max_stamina
	current_stamina = max_stamina

func drain(rate_per_second: float, delta: float) -> bool:
	if is_exhausted:
		return false

	var cost: float = rate_per_second * delta
	current_stamina = maxf(0.0, current_stamina - cost)
	_regen_timer = regen_delay

	var ratio: float = get_ratio()
	stamina_changed.emit(current_stamina, max_stamina, ratio)

	if current_stamina <= 0.001:
		is_exhausted = true
		stamina_exhausted.emit()
		return false

	return true

func consume_chunk(amount: float) -> bool:
	if is_exhausted or current_stamina < amount * 0.4:
		return false

	current_stamina = maxf(0.0, current_stamina - amount)
	_regen_timer = regen_delay * 1.25

	var ratio: float = get_ratio()
	stamina_changed.emit(current_stamina, max_stamina, ratio)

	if current_stamina <= 0.001:
		is_exhausted = true
		stamina_exhausted.emit()
		return false

	return true

func update(delta: float, is_active_drain: bool) -> void:
	if is_active_drain:
		_regen_timer = regen_delay
		return

	if _regen_timer > 0.0:
		_regen_timer = maxf(0.0, _regen_timer - delta)
		return

	if current_stamina < max_stamina:
		current_stamina = minf(max_stamina, current_stamina + regen_rate * delta)
		var ratio: float = get_ratio()
		stamina_changed.emit(current_stamina, max_stamina, ratio)

		if is_exhausted and current_stamina >= max_stamina * 0.25:
			is_exhausted = false
			stamina_recovered.emit()

func get_ratio() -> float:
	return clampf(current_stamina / max_stamina, 0.0, 1.0)

func is_full() -> bool:
	return current_stamina >= max_stamina - 0.001

func reset() -> void:
	current_stamina = max_stamina
	is_exhausted = false
	_regen_timer = 0.0
	stamina_changed.emit(current_stamina, max_stamina, 1.0)
