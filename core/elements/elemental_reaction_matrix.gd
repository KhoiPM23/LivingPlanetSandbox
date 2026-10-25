class_name ElementalReactionMatrix
extends RefCounted

## Living Planet Sandbox — Genshin-Grade Elemental Reaction Matrix (Block 64)
## Implements deep interactive elemental physics:
## - ANEMO (Phong 🌀): Swirl dispersion, aerodynamic lift
## - PYRO (Hỏa 🔥): Wildfire combustion, creates thermal updrafts, melts cryo, vaporizes hydro
## - HYDRO (Thủy 💧): Soil saturation, flora revival, douses fires, freezes with cryo
## - CRYO (Băng ❄️): Cryo solidifies water into walkable ice sheets, melts with pyro, immobilizes wet targets

enum Element {
	NONE = 0,
	ANEMO = 1,
	PYRO = 2,
	HYDRO = 3,
	CRYO = 4
}

enum ReactionType {
	NONE = 0,
	VAPORIZE = 1, # Hydro + Pyro (Damage burst & steam cloud)
	MELT = 2,     # Cryo + Pyro (Damage burst & melts ice)
	FROZEN = 3,   # Hydro + Cryo (Freezes water & immobilizes targets)
	SWIRL = 4,    # Anemo + (Pyro/Hydro/Cryo) (Radial elemental explosion)
	BURNING = 5   # Pyro + Grass/Wood (Ignites wildfire & spawns updrafts)
}

static func get_element_name(elem: Element) -> String:
	match elem:
		Element.ANEMO: return "Phong (Anemo)"
		Element.PYRO: return "Hỏa (Pyro)"
		Element.HYDRO: return "Thủy (Hydro)"
		Element.CRYO: return "Băng (Cryo)"
		_: return "Vô Nguyên Tố"

static func get_element_icon(elem: Element) -> String:
	match elem:
		Element.ANEMO: return "🌀"
		Element.PYRO: return "🔥"
		Element.HYDRO: return "💧"
		Element.CRYO: return "❄️"
		_: return "⚪"

static func get_element_color(elem: Element) -> Color:
	match elem:
		Element.ANEMO: return Color(0.35, 0.95, 0.78) # Teal / Cyan
		Element.PYRO: return Color(1.0, 0.42, 0.15)   # Flame Orange
		Element.HYDRO: return Color(0.22, 0.65, 1.0)  # Azure Blue
		Element.CRYO: return Color(0.62, 0.92, 1.0)   # Frosted Ice
		_: return Color(0.9, 0.9, 0.9)

## Evaluates reaction between a target's existing element and an incoming element
static func evaluate_reaction(existing_elem: Element, incoming_elem: Element) -> Dictionary:
	var result: Dictionary = {
		"reaction": ReactionType.NONE,
		"reaction_name": "",
		"damage_multiplier": 1.0,
		"visual_color": Color.WHITE,
		"clears_element": false,
		"freeze_duration": 0.0,
		"creates_updraft": false,
		"creates_ice": false,
		"steam_cloud": false
	}

	if existing_elem == Element.NONE or incoming_elem == Element.NONE or existing_elem == incoming_elem:
		return result

	# 1. HYDRO + PYRO -> VAPORIZE
	if (existing_elem == Element.HYDRO and incoming_elem == Element.PYRO):
		result["reaction"] = ReactionType.VAPORIZE
		result["reaction_name"] = "BỐC HƠI (VAPORIZE)"
		result["damage_multiplier"] = 1.5 # Pyro triggers on Hydro
		result["visual_color"] = Color(0.92, 0.75, 0.95)
		result["clears_element"] = true
		result["steam_cloud"] = true
		return result
	elif (existing_elem == Element.PYRO and incoming_elem == Element.HYDRO):
		result["reaction"] = ReactionType.VAPORIZE
		result["reaction_name"] = "BỐC HƠI (VAPORIZE)"
		result["damage_multiplier"] = 2.0 # Hydro triggers on Pyro
		result["visual_color"] = Color(0.75, 0.88, 1.0)
		result["clears_element"] = true
		result["steam_cloud"] = true
		return result

	# 2. CRYO + PYRO -> MELT
	if (existing_elem == Element.CRYO and incoming_elem == Element.PYRO):
		result["reaction"] = ReactionType.MELT
		result["reaction_name"] = "TAN CHẢY (MELT)"
		result["damage_multiplier"] = 2.0 # Pyro triggers on Cryo
		result["visual_color"] = Color(1.0, 0.62, 0.25)
		result["clears_element"] = true
		return result
	elif (existing_elem == Element.PYRO and incoming_elem == Element.CRYO):
		result["reaction"] = ReactionType.MELT
		result["reaction_name"] = "TAN CHẢY (MELT)"
		result["damage_multiplier"] = 1.5 # Cryo triggers on Pyro
		result["visual_color"] = Color(0.85, 0.85, 1.0)
		result["clears_element"] = true
		return result

	# 3. HYDRO + CRYO -> FROZEN
	if (existing_elem == Element.HYDRO and incoming_elem == Element.CRYO) or (existing_elem == Element.CRYO and incoming_elem == Element.HYDRO):
		result["reaction"] = ReactionType.FROZEN
		result["reaction_name"] = "ĐÓNG BĂNG (FROZEN)"
		result["damage_multiplier"] = 1.0
		result["visual_color"] = Color(0.45, 0.85, 1.0)
		result["clears_element"] = false
		result["freeze_duration"] = 3.5
		result["creates_ice"] = true
		return result

	# 4. ANEMO + ANY -> SWIRL
	if incoming_elem == Element.ANEMO and existing_elem != Element.NONE:
		result["reaction"] = ReactionType.SWIRL
		result["reaction_name"] = "KHUẾCH TÁN (SWIRL)"
		result["damage_multiplier"] = 1.25
		result["visual_color"] = get_element_color(existing_elem)
		result["clears_element"] = false
		return result

	return result
