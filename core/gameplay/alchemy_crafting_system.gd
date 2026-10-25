class_name AlchemyCraftingSystem
extends Node

## Living Planet Sandbox — Block 40 Botanical Alchemy & Crafting Director
## Manages natural ingredient foraging inventory, potion brewing recipes,
## and active consumable buffs (Sprint Boost, Night Glow, Fish Lure).

signal inventory_updated(inventory: Dictionary)
signal coins_updated(total_coins: int)
signal potion_crafted(potion_id: String, potion_name: String)
signal potion_consumed(potion_id: String, duration: float)
signal buff_expired(potion_id: String)

var inventory: Dictionary = {
	"kelp_fronds": 2,
	"forest_berries": 2,
	"mountain_herbs": 2,
	"emerald_salmon": 0,
	"golden_sunfish": 0,
	"pearl_oyster": 0,
	"ancient_royal_seal": 0
}

var coins: int = 50
var active_buffs: Dictionary = {} # potion_id -> remaining_time (float)

const RECIPES: Dictionary = {
	"swiftness_elixir": {
		"title": "⚡ Thuốc Trường Tốc (Elixir of Swiftness)",
		"desc": "Tăng 35% tốc độ di chuyển và lướt gió trong 45 giây.",
		"cost": {"forest_berries": 1, "mountain_herbs": 1},
		"duration": 45.0,
		"icon": "⚡"
	},
	"night_luminescence": {
		"title": "✨ Dược Thủy Dạ Quang (Night Luminescence)",
		"desc": "Tỏa ra quầng sáng dịu êm bán kính 14m soi sáng đêm tối trong 60 giây.",
		"cost": {"kelp_fronds": 1, "forest_berries": 1},
		"duration": 60.0,
		"icon": "✨"
	},
	"fishermans_tonic": {
		"title": "🐟 Dược Trà Ngư Phủ (Oceanic Fish Tonic)",
		"desc": "Thu hút đàn cá cắn câu nhanh gấp đôi và bơi theo thuyền trong 60 giây.",
		"cost": {"kelp_fronds": 2},
		"duration": 60.0,
		"icon": "🐟"
	},
	"herb_salmon_soup": {
		"title": "🍲 Súp Cá Hồi Thảo Mộc (Herb Salmon Stew)",
		"desc": "Món súp bồi bổ thể lực, hồi phục năng lượng và tăng 40% tốc độ chạy trong 60 giây.",
		"cost": {"emerald_salmon": 1, "mountain_herbs": 1},
		"duration": 60.0,
		"icon": "🍲"
	},
	"abyssal_clarity_elixir": {
		"title": "🌊 Dược Tinh Hoa Biển Sâu (Abyssal Ocean Elixir)",
		"desc": "Thanh lọc tầm nhìn đáy biển, tăng tốc độ bơi lội và lặn sâu trong 90 giây.",
		"cost": {"pearl_oyster": 1, "kelp_fronds": 2},
		"duration": 90.0,
		"icon": "🌊"
	},
	"solar_sovereign_tonic": {
		"title": "👑 Linh Dược Thái Dương (Solar Sovereign Tonic)",
		"desc": "Linh dược bào chế từ Cá Mặt Trời Hoàng Kim và Dâu Rừng, tăng 60% tốc độ trong 120 giây.",
		"cost": {"golden_sunfish": 1, "forest_berries": 2},
		"duration": 120.0,
		"icon": "👑"
	}
}

func add_coins(amount: int) -> void:
	coins += amount
	coins_updated.emit(coins)
	print("[Economy] Haven Coins +%d (Total: %d)" % [amount, coins])

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_updated.emit(coins)
	print("[Economy] Haven Coins -%d (Remaining: %d)" % [amount, coins])
	return true

func get_coins() -> int:
	return coins

func remove_ingredient(item_id: String, count: int = 1) -> bool:
	var current: int = inventory.get(item_id, 0)
	if current < count:
		return false
	inventory[item_id] = current - count
	inventory_updated.emit(inventory)
	return true

func add_ingredient(item_id: String, count: int = 1) -> void:
	var current: int = inventory.get(item_id, 0)
	inventory[item_id] = current + count
	inventory_updated.emit(inventory)
	print("[Alchemy] Gathered %s +%d (Total: %d)" % [item_id, count, inventory[item_id]])

func can_craft(recipe_id: String) -> bool:
	if not RECIPES.has(recipe_id):
		return false
	var cost: Dictionary = RECIPES[recipe_id]["cost"]
	for item in cost:
		if inventory.get(item, 0) < cost[item]:
			return false
	return true

func craft_potion(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		return false

	var cost: Dictionary = RECIPES[recipe_id]["cost"]
	for item in cost:
		inventory[item] -= cost[item]

	var title: String = RECIPES[recipe_id]["title"]
	var dur: float = RECIPES[recipe_id]["duration"]
	active_buffs[recipe_id] = dur

	inventory_updated.emit(inventory)
	potion_crafted.emit(recipe_id, title)
	potion_consumed.emit(recipe_id, dur)
	print("[Alchemy] Crafted and drank: %s" % title)
	return true

func is_buff_active(potion_id: String) -> bool:
	return active_buffs.get(potion_id, 0.0) > 0.0

func get_buff_remaining(potion_id: String) -> float:
	return active_buffs.get(potion_id, 0.0)

func _process(delta: float) -> void:
	if active_buffs.is_empty():
		return

	var expired: Array[String] = []
	for b in active_buffs.keys():
		active_buffs[b] -= delta
		if active_buffs[b] <= 0.0:
			expired.append(b)

	for b in expired:
		active_buffs.erase(b)
		buff_expired.emit(b)
		print("[Alchemy] Buff expired: %s" % b)
