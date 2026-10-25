class_name TestBlock64ElementalReactionsAndFauna
extends RefCounted

## Living Planet Sandbox — Block 64 Automated Verification Suite
## Validates Genshin-Grade Elemental Reaction Matrix, Wildfire Updrafts,
## Walkable Ice Platforms, and RDR2/Genshin Living Fauna Reactive AI.

const ElementalReactionMatrix = preload("res://core/elements/elemental_reaction_matrix.gd")
const WildfireSpreadSystem = preload("res://presentation/elements/wildfire_spread_system.gd")
const IcePlatformSystem = preload("res://presentation/elements/ice_platform_system.gd")
const PlayerElementalController = preload("res://presentation/character/player_elemental_controller.gd")
const HighlandSheep = preload("res://presentation/props/highland_sheep.gd")
const LakeMallardDuck = preload("res://presentation/props/lake_mallard_duck.gd")

func get_suite_name() -> String:
	return "TestBlock64ElementalReactionsAndFauna"

func get_tests() -> Array[Callable]:
	return [
		Callable(self, "test_elemental_reaction_matrix_rules"),
		Callable(self, "test_wildfire_ignition_and_thermal_updraft"),
		Callable(self, "test_ice_platform_solidification_and_collision"),
		Callable(self, "test_player_elemental_controller_cycle_and_cast"),
		Callable(self, "test_living_fauna_reactive_threat_and_startle")
	]

func test_elemental_reaction_matrix_rules() -> String:
	# 1. Vaporize (Pyro on Hydro -> 1.5x, Hydro on Pyro -> 2.0x)
	var vap1: Dictionary = ElementalReactionMatrix.evaluate_reaction(ElementalReactionMatrix.Element.HYDRO, ElementalReactionMatrix.Element.PYRO)
	if vap1["reaction"] != ElementalReactionMatrix.ReactionType.VAPORIZE or vap1["damage_multiplier"] != 1.5:
		return "Expected Vaporize 1.5x on Hydro+Pyro, got %s (mult %f)" % [str(vap1["reaction"]), vap1["damage_multiplier"]]

	var vap2: Dictionary = ElementalReactionMatrix.evaluate_reaction(ElementalReactionMatrix.Element.PYRO, ElementalReactionMatrix.Element.HYDRO)
	if vap2["reaction"] != ElementalReactionMatrix.ReactionType.VAPORIZE or vap2["damage_multiplier"] != 2.0:
		return "Expected Vaporize 2.0x on Pyro+Hydro, got %s (mult %f)" % [str(vap2["reaction"]), vap2["damage_multiplier"]]

	# 2. Melt (Pyro on Cryo -> 2.0x)
	var melt1: Dictionary = ElementalReactionMatrix.evaluate_reaction(ElementalReactionMatrix.Element.CRYO, ElementalReactionMatrix.Element.PYRO)
	if melt1["reaction"] != ElementalReactionMatrix.ReactionType.MELT or melt1["damage_multiplier"] != 2.0:
		return "Expected Melt 2.0x on Cryo+Pyro, got %s" % str(melt1["reaction"])

	# 3. Frozen (Hydro + Cryo)
	var fz: Dictionary = ElementalReactionMatrix.evaluate_reaction(ElementalReactionMatrix.Element.HYDRO, ElementalReactionMatrix.Element.CRYO)
	if fz["reaction"] != ElementalReactionMatrix.ReactionType.FROZEN or not fz["creates_ice"]:
		return "Expected Frozen creates_ice = true, got %s" % str(fz)

	# 4. Swirl (Anemo on Pyro)
	var sw: Dictionary = ElementalReactionMatrix.evaluate_reaction(ElementalReactionMatrix.Element.PYRO, ElementalReactionMatrix.Element.ANEMO)
	if sw["reaction"] != ElementalReactionMatrix.ReactionType.SWIRL:
		return "Expected Swirl reaction, got %s" % str(sw["reaction"])

	return ""

func test_wildfire_ignition_and_thermal_updraft() -> String:
	var wildfire: WildfireSpreadSystem = WildfireSpreadSystem.new()
	var test_pos: Vector3 = Vector3(10.0, 1.5, 10.0)

	var ignited: bool = wildfire.ignite_at(test_pos, 2.5)
	if not ignited:
		wildfire.queue_free()
		return "Expected wildfire to ignite at (10, 1.5, 10)"

	if wildfire.get_active_fire_count() != 1:
		wildfire.queue_free()
		return "Expected 1 active fire, got %d" % wildfire.get_active_fire_count()

	if not wildfire.is_position_near_fire(test_pos, 3.0):
		wildfire.queue_free()
		return "Expected is_position_near_fire to return true"

	# Extinguish with Hydro / douse
	var doused: int = wildfire.douse_at(test_pos, 4.0)
	if doused != 1 or wildfire.get_active_fire_count() != 0:
		wildfire.queue_free()
		return "Expected 1 fire doused, remaining: %d" % wildfire.get_active_fire_count()

	wildfire.queue_free()
	return ""

func test_ice_platform_solidification_and_collision() -> String:
	var ice_sys: IcePlatformSystem = IcePlatformSystem.new()
	var water_pos: Vector3 = Vector3(25.0, 0.0, 30.0)

	var frozen: bool = ice_sys.freeze_at(water_pos, 3.2)
	if not frozen:
		ice_sys.queue_free()
		return "Expected Cryo to freeze water into ice platform"

	if ice_sys.get_active_ice_count() != 1:
		ice_sys.queue_free()
		return "Expected 1 active ice platform, got %d" % ice_sys.get_active_ice_count()

	if not ice_sys.is_position_on_ice(water_pos + Vector3(0.5, 0.08, 0.5)):
		ice_sys.queue_free()
		return "Expected position to register as standing on ice platform"

	# Melt with Pyro
	var melted: int = ice_sys.melt_at(water_pos, 4.0)
	if melted != 1 or ice_sys.get_active_ice_count() != 0:
		ice_sys.queue_free()
		return "Expected ice platform to melt under Pyro, remaining: %d" % ice_sys.get_active_ice_count()

	ice_sys.queue_free()
	return ""

func test_player_elemental_controller_cycle_and_cast() -> String:
	var ctrl: PlayerElementalController = PlayerElementalController.new()
	var wildfire: WildfireSpreadSystem = WildfireSpreadSystem.new()
	var ice_sys: IcePlatformSystem = IcePlatformSystem.new()
	ctrl.setup(wildfire, ice_sys)

	# Verify initial element is ANEMO
	if ctrl.current_element != ElementalReactionMatrix.Element.ANEMO:
		ctrl.queue_free()
		wildfire.queue_free()
		ice_sys.queue_free()
		return "Expected initial element ANEMO, got %d" % ctrl.current_element

	# Cycle through all elements
	var e1: int = ctrl.cycle_element() # PYRO
	if e1 != ElementalReactionMatrix.Element.PYRO:
		ctrl.queue_free()
		wildfire.queue_free()
		ice_sys.queue_free()
		return "Expected cycle to PYRO, got %d" % e1

	var e2: int = ctrl.cycle_element() # HYDRO
	var e3: int = ctrl.cycle_element() # CRYO
	var e4: int = ctrl.cycle_element() # back to ANEMO
	if e4 != ElementalReactionMatrix.Element.ANEMO:
		ctrl.queue_free()
		wildfire.queue_free()
		ice_sys.queue_free()
		return "Expected full cycle back to ANEMO, got %d" % e4

	# Cast Pyro skill
	ctrl.set_element(ElementalReactionMatrix.Element.PYRO)
	var res: Dictionary = ctrl.cast_skill(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD)
	if not res.get("success", false):
		ctrl.queue_free()
		wildfire.queue_free()
		ice_sys.queue_free()
		return "Expected skill cast to succeed, got %s" % str(res)

	# Should now be on cooldown
	if ctrl.is_skill_ready():
		ctrl.queue_free()
		wildfire.queue_free()
		ice_sys.queue_free()
		return "Expected skill to be on cooldown after casting"

	ctrl.queue_free()
	wildfire.queue_free()
	ice_sys.queue_free()
	return ""

func test_living_fauna_reactive_threat_and_startle() -> String:
	# 1. Highland Sheep Panic Flee
	var sheep: HighlandSheep = HighlandSheep.new()
	sheep.position = Vector3(10.0, 0.0, 10.0)
	var threat_pos: Vector3 = Vector3(12.0, 0.0, 10.0)

	sheep.alert_threat(threat_pos, true)
	if sheep.current_state != HighlandSheep.SheepState.PANIC_FLEE:
		sheep.queue_free()
		return "Expected sheep to enter PANIC_FLEE on immediate threat, got %d" % sheep.current_state

	sheep.set_wet(true)
	if not sheep.is_wet or sheep._shake_timer <= 0.0:
		sheep.queue_free()
		return "Expected sheep to register wetness and initiate shake timer"

	# 2. Lake Mallard Duck Startled Flight
	var duck: LakeMallardDuck = LakeMallardDuck.new()
	duck.position = Vector3(50.0, 0.05, 50.0)
	duck.startle_flight()

	if not duck.is_flying:
		sheep.queue_free()
		duck.queue_free()
		return "Expected duck to deploy wings and enter startled flight"

	duck.update_behavior(0.1, Vector3(50.0, 0.0, 50.0), true)
	if duck.position.y <= 0.05:
		sheep.queue_free()
		duck.queue_free()
		return "Expected flying duck to gain altitude above water surface"

	sheep.queue_free()
	duck.queue_free()
	return ""
