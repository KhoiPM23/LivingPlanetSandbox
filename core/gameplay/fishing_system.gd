class_name FishingSystem
extends Node

## Living Planet Sandbox — Block 43 Marine & Shore Angling System
## Manages boat and shore fishing states, wait/bite timers, strike windows,
## and marine species catch tables (Emerald Salmon, Golden Sunfish, Pearl Oyster).

signal fishing_started(is_deep_sea: bool)
signal fishing_cast_complete()
signal fish_biting(species_hint: String)
signal fish_caught(species_id: String, species_name: String, exp_reward: int)
signal fish_escaped()
signal fishing_cancelled()

enum State {
	IDLE,
	CASTING,
	WAITING,
	BITING,
	REELING
}

var state: State = State.IDLE
var bite_wait_timer: float = 0.0
var bite_window_timer: float = 0.0
var bite_window_duration: float = 2.4
var is_deep_sea: bool = false
var has_lure_buff: bool = false
var active_bobber_pos: Vector3 = Vector3.ZERO
var caught_count: int = 0

const CATCH_TABLE: Dictionary = {
	"emerald_salmon": {
		"title": "🐟 Cá Hồi Ngọc Bích",
		"desc": "Loài cá bơi nhanh vảy màu ngọc lục bảo, thường sinh sống ở vịnh ngọc bích Emerald Cove.",
		"exp": 120
	},
	"golden_sunfish": {
		"title": "🐠 Cá Mặt Trời Hoàng Kim",
		"desc": "Cá biển sâu lấp lánh ánh kim, quý hiếm và giàu dinh dưỡng.",
		"exp": 250
	},
	"pearl_oyster": {
		"title": "🦪 Sò Điệp Ngọc Trai",
		"desc": "Sò điệp bám trên rạn san hô cổ, vỏ chứa ngọc trai sáng bóng.",
		"exp": 180
	}
}

func start_fishing(deep_sea: bool = false, lure_active: bool = false, bobber_origin: Vector3 = Vector3.ZERO) -> bool:
	if state != State.IDLE:
		return false

	state = State.CASTING
	is_deep_sea = deep_sea
	has_lure_buff = lure_active
	active_bobber_pos = bobber_origin

	# If Fisherman's Tonic is active, fish bite 2.5x faster
	if has_lure_buff:
		bite_wait_timer = randf_range(1.0, 2.2)
	else:
		bite_wait_timer = randf_range(2.5, 5.0)

	bite_window_timer = bite_window_duration
	fishing_started.emit(is_deep_sea)
	print("[FishingSystem] Line cast! DeepSea: %s, LureActive: %s (Wait: %.2fs)" % [str(deep_sea), str(lure_active), bite_wait_timer])
	return true

func update(delta: float) -> void:
	match state:
		State.CASTING:
			state = State.WAITING
			fishing_cast_complete.emit()

		State.WAITING:
			bite_wait_timer -= delta
			if bite_wait_timer <= 0.0:
				state = State.BITING
				bite_window_timer = bite_window_duration
				var hint_species: String = "golden_sunfish" if is_deep_sea else "emerald_salmon"
				fish_biting.emit(hint_species)
				print("[FishingSystem] Fish biting! Strike now!")

		State.BITING:
			bite_window_timer -= delta
			if bite_window_timer <= 0.0:
				state = State.IDLE
				fish_escaped.emit()
				print("[FishingSystem] Fish escaped! Too slow on the strike.")

		State.REELING:
			pass

func attempt_reel() -> Dictionary:
	if state == State.BITING:
		state = State.REELING
		var species_id: String = ""
		var roll: float = randf()

		if is_deep_sea:
			if roll < 0.60:
				species_id = "golden_sunfish"
			else:
				species_id = "pearl_oyster"
		else:
			if roll < 0.70:
				species_id = "emerald_salmon"
			else:
				species_id = "pearl_oyster"

		var info: Dictionary = CATCH_TABLE.get(species_id, {})
		var title: String = info.get("title", "Cá Biển Lạ")
		var exp: int = info.get("exp", 100)

		caught_count += 1
		state = State.IDLE
		fish_caught.emit(species_id, title, exp)
		print("[FishingSystem] Hooked and landed: %s (+%d EXP)!" % [title, exp])
		return {
			"success": true,
			"species_id": species_id,
			"species_name": title,
			"exp": exp
		}
	else:
		cancel_fishing()
		return {"success": false}

func cancel_fishing() -> void:
	if state != State.IDLE:
		state = State.IDLE
		fishing_cancelled.emit()
		print("[FishingSystem] Fishing cancelled.")

func is_fishing() -> bool:
	return state != State.IDLE

func is_biting() -> bool:
	return state == State.BITING
