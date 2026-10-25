class_name Main
extends Node3D

## Primary entry point scene connecting WorldBootstrap, IslandTerrain, EnvironmentalGrid, Atmosphere, HUD,
## TitleScreen, ExpeditionManager, FieldJournal, and UIAudioFeedback into a complete commercial release loop.

const AtmosphereDirector = preload("res://presentation/environment/atmosphere_director.gd")
const SpatialAudioDirector = preload("res://presentation/audio/spatial_audio_director.gd")
const LivingWorldDirector = preload("res://core/living_world/living_world_director.gd")
const EnvironmentalStorytelling = preload("res://presentation/environment/environmental_storytelling.gd")
const UIAudioFeedback = preload("res://presentation/audio/ui_audio_feedback.gd")
const ExpeditionManager = preload("res://core/gameplay/expedition_manager.gd")
const GameSettings = preload("res://core/config/game_settings.gd")
const TitleScreen = preload("res://presentation/ui/title_screen.gd")
const IntroTitleCard = preload("res://presentation/ui/intro_title_card.gd")
const MedievalHavenVillage = preload("res://presentation/environment/medieval_haven_village.gd")
const DialogueModal = preload("res://presentation/ui/dialogue_modal.gd")
const DrivableBoat = preload("res://presentation/vehicles/drivable_boat.gd")
const AncientCastleCitadel = preload("res://presentation/environment/ancient_castle_citadel.gd")
const AlchemyCraftingSystem = preload("res://core/gameplay/alchemy_crafting_system.gd")
const AlchemyModal = preload("res://presentation/ui/alchemy_modal.gd")
const FishingSystem = preload("res://core/gameplay/fishing_system.gd")
const HUDCompassBar = preload("res://presentation/ui/hud_compass_bar.gd")
const WindWispsParticles3D = preload("res://presentation/environment/wind_wisps_particles.gd")
const UpdraftVent3D = preload("res://presentation/environment/updraft_vent.gd")
const InteractionPromptHUD = preload("res://presentation/ui/interaction_prompt_hud.gd")
const ForagingNodes = preload("res://presentation/environment/foraging_nodes.gd")
const BirdFlockSystem = preload("res://presentation/environment/bird_flock_system.gd")
const WaypointNetworkManager = preload("res://presentation/environment/waypoint_network_manager.gd")
const WaypointTeleportModal = preload("res://presentation/ui/waypoint_teleport_modal.gd")
const GrandEmeraldLakeFeaturesScript = preload("res://presentation/environment/grand_emerald_lake_features.gd")
const WorldLandmarksExpansionScript = preload("res://presentation/environment/world_landmarks_expansion.gd")
const MagicalAtmosphereDirectorScript = preload("res://presentation/environment/magical_atmosphere_director.gd")
const ExplorationChestSystemScript = preload("res://presentation/environment/exploration_chest_system.gd")
const CircularMinimapHUDScript = preload("res://presentation/ui/circular_minimap_hud.gd")
const HighlandSheepScript = preload("res://presentation/props/highland_sheep.gd")
const LakeMallardDuckScript = preload("res://presentation/props/lake_mallard_duck.gd")
const AnemoFlightRingsScript = preload("res://presentation/environment/anemo_flight_rings.gd")
const LuminescentNightFloraScript = preload("res://presentation/props/luminescent_night_flora.gd")
const LakeEmeraldFrogScript = preload("res://presentation/props/lake_emerald_frog.gd")
const AnemoCrystalflySwarmScript = preload("res://presentation/environment/anemo_crystalfly_swarm.gd")
const WanderingSeelieScript = preload("res://presentation/environment/wandering_seelie.gd")
const WildernessCampfireSanctuaryScript = preload("res://presentation/environment/wilderness_campfire_sanctuary.gd")
const AncientAnemoStatueScript = preload("res://presentation/environment/ancient_anemo_statue.gd")
const WildernessGroundDressingScript = preload("res://presentation/props/wilderness_ground_dressing.gd")
const WoodlandWildlifeEcosystemScript = preload("res://presentation/fauna/woodland_wildlife_ecosystem.gd")
const CampfireWeatherDirectorScript = preload("res://presentation/environment/campfire_weather_director.gd")
const ShrineOfDepthsScript = preload("res://presentation/environment/shrine_of_depths.gd")
const ElementalTorchPuzzleScript = preload("res://presentation/environment/elemental_torch_puzzle.gd")
const HunterEagleEyeSystemScript = preload("res://presentation/systems/hunter_eagle_eye_system.gd")
const AnemoWindGeyserScript = preload("res://presentation/environment/anemo_wind_geyser.gd")
const AncientSteleInscriptionScript = preload("res://presentation/environment/ancient_stele_inscription.gd")
const LegendaryMythicStagScript = preload("res://presentation/fauna/legendary_mythic_stag.gd")
const AerialRingTrialCourseScript = preload("res://presentation/environment/aerial_ring_trial_course.gd")
const CanopySunShaftsScript = preload("res://presentation/environment/canopy_sun_shafts.gd")
const LegendaryGrizzlyPatriarchScript = preload("res://presentation/fauna/legendary_grizzly_patriarch.gd")
const HydroLakeSanctuaryPuzzleScript = preload("res://presentation/environment/hydro_lake_sanctuary_puzzle.gd")
const EcosystemStateInterpolatorScript = preload("res://presentation/ecosystem/ecosystem_state_interpolator.gd")
const MountableSteedControllerScript = preload("res://presentation/fauna/mountable_steed_controller.gd")
const SubmergedSeaCavernScript = preload("res://presentation/environment/submerged_sea_cavern.gd")
const ElementalReactionMatrixScript = preload("res://core/elements/elemental_reaction_matrix.gd")
const WildfireSpreadSystemScript = preload("res://presentation/elements/wildfire_spread_system.gd")
const IcePlatformSystemScript = preload("res://presentation/elements/ice_platform_system.gd")
const PlayerElementalControllerScript = preload("res://presentation/character/player_elemental_controller.gd")
const FoliageLODSystemScript = preload("res://presentation/environment/foliage_lod_system.gd")
const GlassmorphicDiegeticHUDScript = preload("res://presentation/ui/glassmorphic_diegetic_hud.gd")
const AcousticLandscapeSystemScript = preload("res://presentation/audio/acoustic_landscape_system.gd")
const SkyspireBeaconAltarScript = preload("res://presentation/environment/skyspire_beacon_altar.gd")

@onready var bootstrap: WorldBootstrap = $WorldBootstrap
@onready var terrain: IslandTerrain = $IslandTerrain
@onready var water: WaterPlane = $WaterPlane
@onready var day_night: DayNightCycle = $DayNightCycle
@onready var scatter: VegetationScatter = $VegetationScatter
@onready var camera: FreeLookCamera = $FreeLookCamera
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var env: WorldEnvironment = $WorldEnvironment
@onready var hud: WorldHUD = $WorldHUD
@onready var debug_overlay: DebugOverlay = $DebugOverlay

var ui_audio: UIAudioFeedback = null
var expedition: ExpeditionManager = null
var intro_card: IntroTitleCard = null
var title_screen: TitleScreen = null
var village: MedievalHavenVillage = null
var dialogue_modal: DialogueModal = null
var castle: AncientCastleCitadel = null
var alchemy_system: AlchemyCraftingSystem = null
var alchemy_modal: AlchemyModal = null
var fishing_system: FishingSystem = null
var compass_bar: HUDCompassBar = null
var wind_wisps: WindWispsParticles3D = null
var updraft_vents: Array[UpdraftVent3D] = []
var interaction_hud: InteractionPromptHUD = null
var foraging_nodes: ForagingNodes = null
var bird_system: BirdFlockSystem = null
var waypoint_network: Node3D = null
var waypoint_modal: Control = null
var lake_features: Node3D = null
var world_landmarks: Node3D = null
var atmosphere_director: Node3D = null
var chest_system: Node3D = null
var minimap_hud: Control = null
var sheep_flock: Array[Node3D] = []
var duck_flock: Array[Node3D] = []
var flight_rings: Node3D = null
var luminescent_flora: Node3D = null
var frog_flock: Array[Node3D] = []
var crystalfly_swarm: Node3D = null
var wandering_seelie: Node3D = null
var wilderness_camp: Node3D = null
var anemo_statue: Node3D = null
var ground_dressing: Node3D = null
var wildlife_ecosystem: Node3D = null
var campfire_director: Node3D = null
var shrine_of_depths: Node3D = null
var torch_puzzle: Node3D = null
var hunter_eagle_eye: Node3D = null
var anemo_geyser: Node3D = null
var ancient_stele: Node3D = null
var mythic_stag: Node3D = null
var aerial_trial: Node3D = null
var sun_shafts: Node3D = null
var grizzly_patriarch: Node3D = null
var hydro_puzzle: Node3D = null
var state_interpolator: Node = null
var prairie_steed: Node3D = null
var sea_cavern: Node3D = null
var stamina_wheel: Control = null
var wildfire_system: Node3D = null
var ice_system: Node3D = null
var elemental_controller: Node3D = null
var foliage_lod_system: Node3D = null
var glassmorphic_hud: CanvasLayer = null
var acoustic_system: Node3D = null
var acoustic_landscape: Node3D = null
var skyspire_beacon: Node3D = null

var _scenic_orbit_angle: float = 0.85
var _spawn_pos: Vector3 = Vector3(7.5, 3.8, 16.5)
var _fauna_check_timer: float = 0.0

func _ready() -> void:
	print("[Main] Initializing Living Planet Sandbox Procedural World & Environment Systems...")
	var seed_val: int = bootstrap.world_seed.master_seed if (bootstrap and bootstrap.world_seed) else 1337
	var config: WorldGenerationConfig = bootstrap.world_config if bootstrap else null
	var grid: EnvironmentalGrid = bootstrap.environmental_grid if bootstrap else null
	var weather: WeatherSystem = bootstrap.weather_system if bootstrap else null

	# 0. Initialize Procedural Audio Synthesizer & Expedition Director
	ui_audio = UIAudioFeedback.new()
	ui_audio.name = "UIAudioFeedback"
	add_child(ui_audio)

	expedition = ExpeditionManager.new()
	expedition.name = "ExpeditionManager"
	expedition.active_seed = seed_val
	add_child(expedition)

	intro_card = IntroTitleCard.new()
	intro_card.name = "IntroTitleCard"
	add_child(intro_card)

	# 1. Generate Procedural Island Terrain bound to EnvironmentalGrid
	if terrain:
		terrain.island_size = 720.0
		if config:
			config.island_size = 720.0
		terrain.generate_island(config if config != null else seed_val, grid)
		print("[Main] Procedural island generated (size: %.0fm, max height: %.1fm)." % [terrain.island_size, terrain.max_height])
		if grid:
			print("[Main] Environmental grid initialized: %d cells (size: %.1fm)." % [grid.get_cell_count(), grid._cell_size])

	# 1b. Expand Water Plane for 720m world scale (960m ocean)
	if water:
		water.set_water_size(960.0, 90)

	# 1c. High-Altitude Glacial Alpine Tarn & Traversable Whispering Grotto
	if terrain and terrain.island_size > 200.0:
		var tarn_scn = preload("res://presentation/environment/alpine_tarn.gd")
		var tarn = tarn_scn.new()
		tarn.name = "AlpineTarn"
		add_child(tarn)
		print("[Main] Skyspire Alpine Tarn glacial lake instantiated at Y = 36.0m.")

		var cave_scn = preload("res://presentation/environment/cave_feature.gd")
		var cave = cave_scn.new()
		cave.name = "WhisperingGrotto"
		add_child(cave)
		print("[Main] Whispering Grotto traversable cavern instantiated.")

		var waterfall_scn = preload("res://presentation/environment/alpine_waterfall.gd")
		var waterfall = waterfall_scn.new()
		waterfall.name = "AlpineWaterfall"
		add_child(waterfall)
		print("[Main] Silverveil Glacial Waterfall cascade instantiated.")

	# 1d. Marine Ecosystem: Underwater Kelp Forests, Seagrass Meadows, Schooling Fish, Coastal Pier & Moored Skiff
	var marine_scn = preload("res://presentation/environment/marine_ecosystem.gd")
	var marine = marine_scn.new()
	marine.name = "MarineEcosystem"
	add_child(marine)
	marine.setup(terrain, null, seed_val)
	print("[Main] Marine Ecosystem initialized: underwater kelp forests, seagrass meadows, schooling fish & coastal pier.")

	# 1d-2. Grand Emerald Lake Features (Jade Arch Bridge, Anemo Pavilion, Boathouse Pier & Cascade)
	lake_features = GrandEmeraldLakeFeaturesScript.new()
	lake_features.name = "GrandEmeraldLakeFeatures"
	add_child(lake_features)
	lake_features.setup(terrain, null)
	print("[Main] Grand Emerald Lake Fjord Basin & Island Sanctuary active.")

	# 1d-3. World Landmarks & Regional Architecture Expansion (Great Windmill, Farmstead, Suspension Bridge, Watchtower)
	world_landmarks = WorldLandmarksExpansionScript.new()
	world_landmarks.name = "WorldLandmarksExpansion"
	add_child(world_landmarks)
	world_landmarks.setup(terrain, null)
	print("[Main] World Landmarks & Regional Architecture Expansion active.")

	# 1e. Coastal Haven Medieval Village: Watchtower, Cottages, Village Square & Living NPCs
	village = MedievalHavenVillage.new()
	village.name = "MedievalHavenVillage"
	add_child(village)
	village.setup(terrain, null)
	print("[Main] Medieval Haven Village & Living NPCs initialized.")

	# 1f. Genshin-Style Dialogue Modal & Narrative Quest Director
	dialogue_modal = DialogueModal.new()
	dialogue_modal.name = "DialogueModal"
	add_child(dialogue_modal)
	dialogue_modal.quest_assigned.connect(_on_dialogue_quest_assigned)

	# 1g. Ancient Ruined Castle Citadel & Spectral Warden
	castle = AncientCastleCitadel.new()
	castle.name = "AncientCastleCitadel"
	add_child(castle)
	castle.setup(terrain, null)
	print("[Main] Ancient Castle Citadel & Spectral Warden initialized.")

	# 1h. Botanical Alchemy & Crafting Director
	alchemy_system = AlchemyCraftingSystem.new()
	alchemy_system.name = "AlchemyCraftingSystem"
	add_child(alchemy_system)
	alchemy_system.potion_consumed.connect(_on_potion_consumed)
	alchemy_system.buff_expired.connect(_on_potion_buff_expired)

	alchemy_modal = AlchemyModal.new()
	alchemy_modal.name = "AlchemyModal"
	add_child(alchemy_modal)
	alchemy_modal.setup(alchemy_system)
	print("[Main] Botanical Alchemy & Crafting system active.")

	# 1i. Marine & Shore Angling System (Block 43)
	fishing_system = FishingSystem.new()
	fishing_system.name = "FishingSystem"
	add_child(fishing_system)
	fishing_system.fish_biting.connect(_on_fish_biting)
	fishing_system.fish_caught.connect(_on_fish_caught)
	fishing_system.fish_escaped.connect(_on_fish_escaped)

	# 1j. Genshin-Style Dynamic Waypoint Compass Bar (Block 45)
	compass_bar = HUDCompassBar.new()
	compass_bar.name = "HUDCompassBar"
	add_child(compass_bar)

	# 1k. Genshin-Style Floating Wind Wisps Particles (Block 45)
	wind_wisps = WindWispsParticles3D.new()
	wind_wisps.name = "WindWispsParticles3D"
	add_child(wind_wisps)

	# 1l. Genshin-Style Elemental Anemo Updraft Vents (Block 46)
	var vent_coords: Array[Vector3] = [
		Vector3(-45.0, 31.5, -18.0), # Skyspire Alpine Tarn Cliff
		Vector3(-28.0, 14.5, -42.0), # Castle Citadel Bluffs
		Vector3(-12.0, 6.2, 38.0),   # Whispering Grotto Ridge
		Vector3(26.0, 4.8, 55.0)     # Haven Village Pier Overlook
	]
	for idx in range(vent_coords.size()):
		var vent_pos: Vector3 = vent_coords[idx]
		if terrain:
			var gh: float = terrain.get_height_at(vent_pos.x, vent_pos.z)
			vent_pos.y = maxf(vent_pos.y, gh)
		var vent: UpdraftVent3D = UpdraftVent3D.new()
		vent.name = "UpdraftVent_%d" % idx
		vent.setup(vent_pos, 14.5, 15.0)
		add_child(vent)
		updraft_vents.append(vent)
	print("[Main] Elemental Anemo Updraft Vents instantiated across 4 scenic launch bluffs.")

	# 1m. Genshin-Style Dynamic Interaction & Foraging Prompt HUD (Block 48)
	interaction_hud = InteractionPromptHUD.new()
	interaction_hud.name = "InteractionPromptHUD"
	add_child(interaction_hud)

	# 1n. Genshin-Style Collectible Flora & Island Foraging System (Block 48)
	foraging_nodes = ForagingNodes.new()
	foraging_nodes.name = "ForagingNodes"
	add_child(foraging_nodes)
	foraging_nodes.setup(terrain, seed_val)
	foraging_nodes.item_foraged.connect(_on_item_foraged)
	print("[Main] Genshin-Style Interaction Prompt HUD & Foraging System initialized.")

	# 1o. Genshin-Style Ancient Teleport Waypoint Network (Block 51)
	waypoint_network = WaypointNetworkManager.new()
	waypoint_network.name = "WaypointNetworkManager"
	add_child(waypoint_network)
	waypoint_network.setup(terrain)
	waypoint_network.waypoint_activated.connect(_on_waypoint_activated)

	waypoint_modal = WaypointTeleportModal.new()
	waypoint_modal.name = "WaypointTeleportModal"
	add_child(waypoint_modal)
	waypoint_modal.setup(waypoint_network)
	waypoint_modal.teleport_requested.connect(_on_waypoint_teleport_requested)
	print("[Main] Genshin-Style Ancient Teleport Waypoint Network & Fast Travel active.")

	# 1p. Hidden Scenic Exploration Chests & Anemo Elemental Monument (Block 53)
	chest_system = ExplorationChestSystemScript.new()
	chest_system.name = "ExplorationChestSystem"
	add_child(chest_system)
	chest_system.setup(terrain)
	chest_system.chest_opened.connect(_on_exploration_chest_opened)
	chest_system.monument_activated.connect(_on_anemo_monument_activated)
	print("[Main] Exploration Chests & Anemo Elemental Monument active.")

	# 1q. Cinematic Magical Atmosphere & Atmospheric FX Director (Block 53)
	atmosphere_director = MagicalAtmosphereDirectorScript.new()
	atmosphere_director.name = "MagicalAtmosphereDirector"
	add_child(atmosphere_director)

	# 1r. Genshin-Style Circular Radar Minimap HUD (Block 53)
	minimap_hud = CircularMinimapHUDScript.new()
	minimap_hud.name = "CircularMinimapHUD"
	add_child(minimap_hud)

	# 1s. Fluffy Highland Sheep Flock at Windmill Pasture (Block 53)
	var sheep_coords = [
		Vector3(100.0, 16.8, -58.0),
		Vector3(103.5, 16.8, -55.0),
		Vector3(97.0, 16.8, -60.0),
		Vector3(105.0, 16.8, -62.0)
	]
	for s_idx in range(sheep_coords.size()):
		var s_pos: Vector3 = sheep_coords[s_idx]
		if terrain:
			s_pos.y = maxf(terrain.get_height_at(s_pos.x, s_pos.z), 16.0)
		var sheep = HighlandSheepScript.new()
		sheep.name = "HighlandSheep_%d" % s_idx
		sheep.position = s_pos
		add_child(sheep)
		sheep_flock.append(sheep)
	print("[Main] Highland Sheep flock spawned at windmill farmstead pasture.")

	# 1t. Lake Mallard Duck Flock at Grand Emerald Lake (Block 53)
	var duck_centers = [
		Vector3(38.0, 0.05, 82.0),
		Vector3(44.0, 0.05, 86.0),
		Vector3(50.0, 0.05, 78.0),
		Vector3(34.0, 0.05, 90.0)
	]
	for d_idx in range(duck_centers.size()):
		var duck = LakeMallardDuckScript.new()
		duck.name = "LakeMallardDuck_%d" % d_idx
		duck.position = duck_centers[d_idx]
		duck.swim_center = duck_centers[d_idx]
		duck.swim_radius = randf_range(6.0, 10.0)
		duck.swim_speed = randf_range(0.7, 1.1)
		add_child(duck)
		duck_flock.append(duck)
	print("[Main] Lake Mallard Duck flock paddling on Grand Emerald Lake.")

	# 1u. Anemo Aerial Flight Rings & Gliding Wind Highway (Block 54)
	flight_rings = AnemoFlightRingsScript.new()
	flight_rings.name = "AnemoFlightRings"
	add_child(flight_rings)
	flight_rings.ring_passed.connect(_on_flight_ring_passed)
	print("[Main] Anemo Flight Rings Highway initialized across 6 aerial sky coordinates.")

	# 1v. Luminescent Night Flora & Spore Reaction System (Block 54)
	luminescent_flora = LuminescentNightFloraScript.new()
	luminescent_flora.name = "LuminescentNightFlora"
	add_child(luminescent_flora)
	luminescent_flora.setup(terrain)
	luminescent_flora.flora_harvested.connect(_on_flora_harvested)
	print("[Main] Luminescent Night Flora (Star Lotus & Glowing Spores) populated.")

	# 1w. Lake Emerald Tree Frog & Lily Pad Perch (Block 54)
	var frog_coords = [
		Vector3(38.0, 0.05, 84.0),
		Vector3(56.0, 0.05, 78.0),
		Vector3(72.0, 0.05, 86.0),
		Vector3(44.0, 0.05, 92.0)
	]
	for fr_idx in range(frog_coords.size()):
		var frog = LakeEmeraldFrogScript.new()
		frog.name = "LakeEmeraldFrog_%d" % fr_idx
		frog.position = frog_coords[fr_idx]
		add_child(frog)
		frog_flock.append(frog)
	print("[Main] Lake Emerald Tree Frogs perched on lily pads across Grand Emerald Lake.")

	# 1x. Genshin-Style Anemo Crystalfly Swarm (Block 55)
	crystalfly_swarm = AnemoCrystalflySwarmScript.new()
	crystalfly_swarm.name = "AnemoCrystalflySwarm"
	add_child(crystalfly_swarm)
	crystalfly_swarm.crystalfly_caught.connect(_on_crystalfly_caught)

	# 1y. Genshin-Style Wandering Seelie & Seelie Court (Block 55)
	wandering_seelie = WanderingSeelieScript.new()
	wandering_seelie.name = "WanderingSeelie"
	add_child(wandering_seelie)
	wandering_seelie.seelie_reached_court.connect(_on_seelie_reached_court)
	wandering_seelie.seelie_chest_opened.connect(_on_seelie_chest_opened)

	# 1z. RDR2-Style Wilderness Campfire & Bivouac Sanctuary (Block 55)
	wilderness_camp = WildernessCampfireSanctuaryScript.new()
	wilderness_camp.name = "WildernessCampfireSanctuary"
	wilderness_camp.position = Vector3(7.5, 3.8, 12.0)
	if terrain:
		wilderness_camp.position.y = maxf(terrain.get_height_at(7.5, 12.0), 3.0)
	add_child(wilderness_camp)

	# 1aa. Genshin-Style Ancient Anemo Statue & Gliding Time Trial (Block 55)
	anemo_statue = AncientAnemoStatueScript.new()
	anemo_statue.name = "AncientAnemoStatue"
	anemo_statue.position = Vector3(-18.0, 16.1, -18.0)
	if terrain:
		anemo_statue.position.y = maxf(terrain.get_height_at(-18.0, -18.0), 16.0)
	add_child(anemo_statue)
	anemo_statue.statue_prayed.connect(_on_statue_prayed)
	anemo_statue.time_trial_started.connect(_on_time_trial_started)
	anemo_statue.time_trial_completed.connect(_on_time_trial_completed)
	anemo_statue.time_trial_failed.connect(_on_time_trial_failed)

	# 1bb. RDR2-Style Wilderness Ground Dressing & Raspberry Bushes (Block 55)
	ground_dressing = WildernessGroundDressingScript.new()
	ground_dressing.name = "WildernessGroundDressing"
	add_child(ground_dressing)
	ground_dressing.berry_foraged.connect(_on_berry_foraged)

	# 1cc. RDR2-Style Woodland Wildlife Ecosystem (Block 56)
	wildlife_ecosystem = WoodlandWildlifeEcosystemScript.new()
	wildlife_ecosystem.name = "WoodlandWildlifeEcosystem"
	add_child(wildlife_ecosystem)
	wildlife_ecosystem.setup(terrain)
	wildlife_ecosystem.animal_spotted.connect(_on_animal_spotted)

	# 1dd. Campfire Weather & Cooking Director (Block 56)
	campfire_director = CampfireWeatherDirectorScript.new()
	campfire_director.name = "CampfireWeatherDirector"
	add_child(campfire_director)
	campfire_director.setup(wilderness_camp, weather)
	campfire_director.dish_cooked.connect(_on_dish_cooked)

	# 1ee. Genshin-Style Shrine of Depths (Block 56)
	shrine_of_depths = ShrineOfDepthsScript.new()
	shrine_of_depths.name = "ShrineOfDepths"
	shrine_of_depths.position = Vector3(-30.0, 4.2, 25.0)
	if terrain:
		shrine_of_depths.position.y = maxf(terrain.get_height_at(-30.0, 25.0), 3.5)
	add_child(shrine_of_depths)
	shrine_of_depths.shrine_unlocked.connect(_on_shrine_unlocked)
	shrine_of_depths.luxurious_chest_opened.connect(_on_luxurious_chest_opened)

	# 1ff. Genshin-Style Elemental Pyro Torch Puzzle (Block 56)
	torch_puzzle = ElementalTorchPuzzleScript.new()
	torch_puzzle.name = "ElementalTorchPuzzle"
	torch_puzzle.position = Vector3(25.0, 3.9, -25.0)
	if terrain:
		torch_puzzle.position.y = maxf(terrain.get_height_at(25.0, -25.0), 3.0)
	add_child(torch_puzzle)
	torch_puzzle.torch_lit.connect(_on_torch_lit)
	torch_puzzle.puzzle_solved.connect(_on_puzzle_solved)
	torch_puzzle.puzzle_chest_opened.connect(_on_puzzle_chest_opened)

	# 1gg. RDR2-Style Hunter Eagle Eye & Animal Tracking System (Block 57)
	hunter_eagle_eye = HunterEagleEyeSystemScript.new()
	hunter_eagle_eye.name = "HunterEagleEyeSystem"
	add_child(hunter_eagle_eye)
	hunter_eagle_eye.track_clue_inspected.connect(_on_track_clue_inspected)

	# 1hh. Genshin-Style Anemo Wind Geyser (Block 57)
	anemo_geyser = AnemoWindGeyserScript.new()
	anemo_geyser.name = "AnemoWindGeyser"
	anemo_geyser.position = Vector3(-15.0, 5.0, 45.0)
	if terrain:
		anemo_geyser.position.y = terrain.get_height_at(-15.0, 45.0)
	add_child(anemo_geyser)
	anemo_geyser.geyser_unsealed.connect(_on_geyser_unsealed)
	anemo_geyser.geyser_propelled.connect(_on_geyser_propelled)

	# 1ii. Genshin-Style Ancient Stele Inscription (Block 57)
	ancient_stele = AncientSteleInscriptionScript.new()
	ancient_stele.name = "AncientSteleInscription"
	ancient_stele.position = Vector3(14.0, 16.5, -18.0)
	if terrain:
		ancient_stele.position.y = terrain.get_height_at(14.0, -18.0)
	add_child(ancient_stele)
	ancient_stele.stele_read.connect(_on_stele_read)
	print("[Main] Block 57 Eagle Eye, Anemo Geyser & Ancient Stele systems initialized.")

	# 1jj. RDR2-Style Legendary Mythic White Stag (Block 58)
	mythic_stag = LegendaryMythicStagScript.new()
	mythic_stag.name = "LegendaryMythicStag"
	mythic_stag.position = Vector3(-45.0, 5.4, -15.0)
	if terrain:
		mythic_stag.position.y = terrain.get_height_at(-45.0, -15.0)
		mythic_stag.setup(terrain)
	add_child(mythic_stag)
	mythic_stag.stag_spotted.connect(_on_stag_spotted)
	mythic_stag.stag_communed.connect(_on_stag_communed)

	# 1kk. Genshin-Style Aerial Ring Time-Trial Course (Block 58)
	aerial_trial = AerialRingTrialCourseScript.new()
	aerial_trial.name = "AerialRingTrialCourse"
	aerial_trial.position = Vector3(-12.0, 6.25, 12.0)
	if terrain:
		aerial_trial.position.y = terrain.get_height_at(-12.0, 12.0)
	add_child(aerial_trial)
	aerial_trial.trial_started.connect(_on_trial_started)
	aerial_trial.ring_cleared.connect(_on_ring_cleared)
	aerial_trial.trial_completed.connect(_on_trial_completed)
	aerial_trial.trial_failed.connect(_on_trial_failed)
	aerial_trial.chest_opened.connect(_on_trial_chest_opened)

	# 1ll. Cinematic Canopy Sun Shafts & Atmosphere (Block 58)
	sun_shafts = CanopySunShaftsScript.new()
	sun_shafts.name = "CanopySunShafts"
	add_child(sun_shafts)
	if day_night:
		sun_shafts.setup(day_night)
	print("[Main] Block 58 Mythic White Stag, Aerial Ring Trial & Sun Shafts initialized.")

	# 1mm. RDR2-Style Legendary Grizzly Patriarch (Block 59)
	grizzly_patriarch = LegendaryGrizzlyPatriarchScript.new()
	grizzly_patriarch.name = "LegendaryGrizzlyPatriarch"
	grizzly_patriarch.position = Vector3(-135.0, 72.0, -130.0)
	if terrain:
		grizzly_patriarch.position.y = terrain.get_height_at(-135.0, -130.0)
		grizzly_patriarch.setup(terrain)
	add_child(grizzly_patriarch)
	grizzly_patriarch.bear_spotted.connect(_on_bear_spotted)
	grizzly_patriarch.photo_taken.connect(_on_bear_photo_taken)
	grizzly_patriarch.roar_emitted.connect(_on_bear_roar_emitted)

	# 1nn. Genshin-Style Hydro Lake Sanctuary & Water Spout Puzzle (Block 59)
	hydro_puzzle = HydroLakeSanctuaryPuzzleScript.new()
	hydro_puzzle.name = "HydroLakeSanctuaryPuzzle"
	add_child(hydro_puzzle)
	hydro_puzzle.seal_activated.connect(_on_hydro_seal_activated)
	hydro_puzzle.spout_erupted.connect(_on_hydro_spout_erupted)
	hydro_puzzle.player_launched.connect(_on_hydro_player_launched)
	hydro_puzzle.luxurious_chest_opened.connect(_on_hydro_island_chest_opened)
	print("[Main] Block 59 Legendary Grizzly Patriarch & Hydro Lake Sanctuary Puzzle initialized.")

	# 1oo. Block 61: State Interpolation & Anti-Jank Engine (Giai đoạn 1.1)
	state_interpolator = EcosystemStateInterpolatorScript.new()
	state_interpolator.name = "EcosystemStateInterpolator"
	add_child(state_interpolator)

	# 1pp. Block 61: Mountable Prairie Steed (Thú Cưỡi Thảo Nguyên)
	prairie_steed = MountableSteedControllerScript.new()
	prairie_steed.name = "MountablePrairieSteed"
	prairie_steed.position = Vector3(-15.0, 4.2, 22.0)
	if terrain:
		prairie_steed.position.y = terrain.get_height_at(-15.0, 22.0)
		prairie_steed.setup(terrain)
	add_child(prairie_steed)
	prairie_steed.player_mounted.connect(_on_steed_player_mounted)
	prairie_steed.player_dismounted.connect(_on_steed_player_dismounted)

	# 1qq. Block 61: Submerged Sea Cavern & Catacombs Passage (Hang Biển Ngầm)
	sea_cavern = SubmergedSeaCavernScript.new()
	sea_cavern.name = "SubmergedSeaCavern"
	add_child(sea_cavern)
	sea_cavern.player_entered_cavern.connect(_on_sea_cavern_entered)
	sea_cavern.cavern_chest_unlocked.connect(_on_cavern_chest_unlocked)
	print("[Main] Block 61 Anti-Jank Interpolator, Prairie Steed Mount & Sea Cavern initialized.")

	# 1rr. Block 64: Genshin Elemental Reaction Matrix, Wildfire & Ice Platform Systems
	wildfire_system = WildfireSpreadSystemScript.new()
	wildfire_system.name = "WildfireSpreadSystem"
	wildfire_system.setup(terrain)
	add_child(wildfire_system)

	ice_system = IcePlatformSystemScript.new()
	ice_system.name = "IcePlatformSystem"
	add_child(ice_system)

	elemental_controller = PlayerElementalControllerScript.new()
	var f_sim = bootstrap.ecosystem_coordinator.flora_sim if (bootstrap and bootstrap.ecosystem_coordinator) else null
	elemental_controller.setup(wildfire_system, ice_system, grid, f_sim, terrain)
	add_child(elemental_controller)
	elemental_controller.element_changed.connect(_on_element_changed)
	elemental_controller.reaction_triggered.connect(_on_elemental_reaction_triggered)
	print("[Main] Block 64 Elemental Reaction Matrix, Wildfire Updrafts & Ice Platforms initialized.")

	# Block 65 Phase 5 Systems (Foliage LOD, Glassmorphic HUD, Acoustic Landscape)
	foliage_lod_system = FoliageLODSystemScript.new()
	foliage_lod_system.setup(terrain, camera)
	add_child(foliage_lod_system)

	glassmorphic_hud = GlassmorphicDiegeticHUDScript.new()
	add_child(glassmorphic_hud)

	acoustic_system = AcousticLandscapeSystemScript.new()
	acoustic_landscape = acoustic_system
	acoustic_system.setup(camera, weather)
	add_child(acoustic_system)
	print("[Main] Block 65 Phase 5 Foliage LOD, Glassmorphic HUD & Acoustic Landscape initialized.")

	# 1uu. Block 67: Skyspire Apex Ancient Anemo Spire Beacon Altar (114m Peak)
	skyspire_beacon = SkyspireBeaconAltarScript.new()
	skyspire_beacon.name = "SkyspireBeaconAltar"
	var sb_pos: Vector3 = Vector3(-145.0, 114.0, -145.0)
	if terrain:
		sb_pos.y = maxf(terrain.get_height_at(-145.0, -145.0), 108.0)
	skyspire_beacon.position = sb_pos
	add_child(skyspire_beacon)
	skyspire_beacon.beacon_activated.connect(_on_skyspire_beacon_activated)
	print("[Main] Block 67 Skyspire Beacon Altar initialized on 114m summit.")

	# Pump OS message queue to prevent Windows "Not Responding" detection during generation
	if is_inside_tree() and get_tree():
		await get_tree().process_frame

	# 2. Setup Day/Night celestial cycle and Weather link
	if day_night and bootstrap:
		day_night.setup(bootstrap.world_clock, sun, env, weather)
		print("[Main] Day/Night cycle bound to WorldClock and WeatherSystem.")

	# 3. Scatter flora, boulders, summit landmark, and instanced grass filtered by Biomes
	if scatter and terrain:
		scatter.scatter(terrain, seed_val, bootstrap.entity_registry, grid, config)
		var entity_count: int = bootstrap.entity_registry.get_count() if (bootstrap and bootstrap.entity_registry) else 0
		print("[Main] Biome props & foliage scattered. Tracked entities: %d" % entity_count)

	# Pump OS message queue after heavy 3D GLTF asset loading and shader variant compiles
	if is_inside_tree() and get_tree():
		await get_tree().process_frame

	# 3b. Setup Dynamic Atmosphere Director & Wind-Surface Reactions
	var weather_fx: WeatherEffectsController = AtmosphereDirector.new()
	weather_fx.name = "WeatherEffectsController"
	add_child(weather_fx)
	if weather and terrain:
		weather_fx.setup(weather, terrain, water, scatter, camera, env, sun)
		print("[Main] Weather effects & surface reaction simulation initialized.")

	# 3c. Setup Procedural Spatial Audio Director for Living World Immersion
	var audio_dir: SpatialAudioDirector = SpatialAudioDirector.new()
	audio_dir.name = "SpatialAudioDirector"
	add_child(audio_dir)
	if bootstrap and bootstrap.world_clock and weather:
		audio_dir.setup(bootstrap.world_clock, weather, camera, bootstrap.world_event_bus)
		print("[Main] Procedural spatial audio initialized: wind gusts, lake shore ripples, bird calls & night crickets.")

	# 3d. Setup 3D Procedural Flying Bird Flock System (Seagulls, Alpine Eagles, Forest Songbirds)
	bird_system = BirdFlockSystem.new()
	bird_system.name = "BirdFlockSystem"
	add_child(bird_system)
	print("[Main] 3D Procedural flying bird flocks active in sky (seagulls, alpine eagles, forest songbirds).")

	# 4. Initialize Causal Ecosystem Simulation & Presentation
	var eco_presentation: EcosystemPresentation = null
	if bootstrap and bootstrap.ecosystem_coordinator and terrain:
		bootstrap.ecosystem_coordinator.bind_terrain_height(Callable(terrain, "get_height_at"))
		if bootstrap.ecosystem_coordinator.fauna_sim:
			bootstrap.ecosystem_coordinator.fauna_sim.set_boundary_radius(340.0)
		bootstrap.ecosystem_coordinator.populate_initial_ecosystem(90, 58, 8)

		eco_presentation = EcosystemPresentation.new()
		eco_presentation.name = "EcosystemPresentation"
		add_child(eco_presentation)
		eco_presentation.setup(bootstrap.ecosystem_coordinator)
		print("[Main] Causal ecosystem simulation initialized: %d plants, %d herbivores, %d predators." % [
			bootstrap.ecosystem_coordinator.flora_sim.get_plant_count(),
			bootstrap.ecosystem_coordinator.fauna_sim.get_herbivore_count(),
			bootstrap.ecosystem_coordinator.fauna_sim.get_predator_count()
		])

	# Pump OS message queue before character spawning & presentation
	if is_inside_tree() and get_tree():
		await get_tree().process_frame

	# 5. Calculate Playable Character Spawn Position in Sunlit Meadow
	var spawn_x: float = 7.5
	var spawn_z: float = 16.5
	if terrain and terrain.island_seed != 1337:
		var glade: Vector2 = terrain.get_glade_position()
		spawn_x = glade.x - 1.5
		spawn_z = glade.y
	var ground_y: float = terrain.get_height_at(spawn_x, spawn_z) if terrain else 3.8
	_spawn_pos = Vector3(spawn_x, ground_y, spawn_z)

	# 6. Initialize Player Experiment Tool Controller & HUD
	var tool_controller: PlayerToolController = PlayerToolController.new()
	tool_controller.name = "PlayerToolController"
	add_child(tool_controller)
	tool_controller.setup(camera, bootstrap, terrain)

	if hud:
		hud.setup_controllers(bootstrap, tool_controller, camera)
		hud.set_expedition_manager(expedition)
		hud.return_to_title_requested.connect(_on_return_to_title_requested)
		print("[Main] Player experiment tools & observability HUD initialized.")

	# 8. Initialize Living World Director — emergent ecological event system
	var living_world: LivingWorldDirector = LivingWorldDirector.new()
	living_world.name = "LivingWorldDirector"
	add_child(living_world)
	if bootstrap and bootstrap.world_clock and bootstrap.world_event_bus and bootstrap.ecosystem_coordinator and bootstrap.weather_system:
		living_world.setup(
			bootstrap.world_clock,
			bootstrap.world_event_bus,
			bootstrap.ecosystem_coordinator.fauna_sim,
			bootstrap.weather_system
		)
		# Wire emergent events to HUD banner display and Expedition manager
		if hud:
			living_world.emergent_event.connect(Callable(hud, "_on_emergent_event"))
		living_world.emergent_event.connect(_on_living_world_event)
		print("[Main] Living World Director initialized — emergent ecological events active.")

	# 9. Initialize Environmental Storytelling & Wordless World Discovery
	var storytelling: EnvironmentalStorytelling = EnvironmentalStorytelling.new()
	storytelling.name = "EnvironmentalStorytelling"
	add_child(storytelling)
	if terrain and bootstrap and bootstrap.world_event_bus:
		storytelling.setup(terrain, bootstrap.world_event_bus, camera, hud, seed_val)
		storytelling.discovery_unlocked.connect(_on_environmental_discovery)
		print("[Main] Environmental storytelling & hero POI discoveries active.")

	# 10. Apply persistent Game Settings (Audio, Graphics, Controls)
	var settings = GameSettings.get_current()
	settings.apply_all(self)
	print("[Main] Applied persistent game settings: preset=%d, master=%.2f, sens=%.4f" % [
		settings.graphics_preset, settings.master_volume, settings.mouse_sensitivity
	])

	# 11. Determine Flow: Headless / Test Runner / Script Runner VS Full Interactive Title Screen
	# 11. Determine Flow: Direct Action-Adventure Character Gameplay as default
	var is_headless: bool = DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--headless") or OS.get_cmdline_args().has("-s") or OS.get_cmdline_args().has("--script") or has_meta("skip_title_screen")
	if is_headless:
		# Fast path for automated contract tests
		_boot_into_character_gameplay(false)
		expedition.set_game_state(ExpeditionManager.GameState.PLAYING)
	else:
		# Direct Genshin-style immersion: Player starts immediately controlling anime heroine in third-person!
		_boot_into_character_gameplay(true)
		expedition.set_game_state(ExpeditionManager.GameState.PLAYING)
		print("[Main] Booted directly into Third-Person Anime Hero Gameplay at glade sanctuary.")

func _boot_into_character_gameplay(show_intro: bool = true) -> void:
	if not camera:
		return
	camera.position = _spawn_pos
	camera.set_camera_mode(FreeLookCamera.CameraMode.THIRD_PERSON_CHARACTER, true)
	var walker: FirstPersonWalker = camera.get_walker()
	if walker:
		walker.teleport_to(_spawn_pos)
		walker.set_perspective(true)
		if walker.has_signal("footstep_played") and not walker.footstep_played.is_connected(_on_walker_footstep_played):
			walker.footstep_played.connect(_on_walker_footstep_played)
		var ts: WildernessTorchSystem = walker.get_torch_system()
		if ts and bootstrap:
			var weather: WeatherSystem = bootstrap.weather_system
			var grid: EnvironmentalGrid = bootstrap.environmental_grid
			var fauna: FaunaSimulation = bootstrap.ecosystem_coordinator.fauna_sim if bootstrap.ecosystem_coordinator else null
			var flora: FloraSimulation = bootstrap.ecosystem_coordinator.flora_sim if bootstrap.ecosystem_coordinator else null
			var w_lvl: float = water.position.y if water else 0.0
			ts.setup(weather, bootstrap.world_clock, fauna, grid, flora, w_lvl)
		# Look Southeast towards Emerald Basin Cove and the lake
		walker._target_cam_yaw = deg_to_rad(-135.0)
		walker._cam_yaw = deg_to_rad(-135.0)
		walker._target_cam_pitch = deg_to_rad(-8.0)
		walker._cam_pitch = deg_to_rad(-8.0)
		walker._model_yaw = deg_to_rad(-135.0)
		walker.update_camera_rotation(0.016)
		var cam3d: Camera3D = walker.get_camera()
		if cam3d:
			camera.global_transform = cam3d.global_transform
		camera.capture_mouse()
		var marine = get_node_or_null("MarineEcosystem")
		if marine:
			marine._player_node = walker
		if village:
			village._player_node = walker
		if castle:
			castle._player_node = walker
		var skiff: DrivableBoat = marine.get_boat() if (marine and marine.has_method("get_boat")) else null
		if compass_bar:
			compass_bar.setup(camera, walker, skiff, waypoint_network)
		if wind_wisps:
			wind_wisps.setup(walker, null)
		if atmosphere_director:
			atmosphere_director.setup(walker, day_night)
		if minimap_hud:
			minimap_hud.setup(walker, walker.get_camera(), chest_system, waypoint_network, flight_rings, luminescent_flora)
		if walker.stamina:
			if not stamina_wheel:
				stamina_wheel = preload("res://presentation/ui/stamina_wheel_hud.gd").new()
				stamina_wheel.name = "StaminaWheelHUD"
				add_child(stamina_wheel)
			stamina_wheel.setup(walker.stamina)

	if hud:
		hud.visible = true

	if show_intro and intro_card:
		var seed_val: int = expedition.active_seed if expedition else 1337
		intro_card.display_intro("DAY 1 — 08:00", "EMERALD BASIN", seed_val)

	if expedition and expedition.get_active_quests().is_empty():
		var s_val: int = expedition.active_seed if expedition else 1337
		expedition.generate_seed_quests(s_val)
		expedition.register_skyspire_quests()

func _on_expedition_started(seed_val: int, mode: String, is_load: bool) -> void:
	if expedition:
		expedition.active_seed = seed_val
		expedition.game_mode = mode
		expedition.set_game_state(ExpeditionManager.GameState.PLAYING)
		expedition.generate_seed_quests(seed_val)
		expedition.register_skyspire_quests()

	_boot_into_character_gameplay(true)

	if is_load and hud:
		hud._on_quickload_pressed()

	print("[Main] Expedition Started: Seed #%d | Mode: %s | Load: %s" % [seed_val, mode, str(is_load)])

func _on_return_to_title_requested() -> void:
	if expedition:
		expedition.set_game_state(ExpeditionManager.GameState.TITLE_SCREEN)
		expedition.save_journal()

	if hud:
		hud.visible = false

	if camera:
		camera.position = Vector3(32.0, 22.0, 48.0)
		camera.look_at(Vector3(0.0, 6.0, 0.0), Vector3.UP)
		camera.set_camera_mode(FreeLookCamera.CameraMode.CINEMATIC, true)
		camera.release_mouse()

	if title_screen:
		title_screen.visible = true
		title_screen._update_continue_state()

	print("[Main] Returned to Title Screen.")

func _on_environmental_discovery(poi_id: String, _title: String, _body: String) -> void:
	if expedition:
		expedition.register_landmark_discovery(poi_id)
		expedition.check_quest_progress("LANDMARK_DISCOVERED", {"id": poi_id})

func _on_living_world_event(event_type: String, _headline: String, _detail: String, _level: String) -> void:
	if not expedition:
		return
	if event_type == "aurora" or event_type == "celestial":
		expedition.register_phenomenon_witnessed("aurora_borealis")
	elif event_type == "shooting_star" or event_type == "meteor":
		expedition.register_phenomenon_witnessed("shooting_star")
	elif event_type == "blizzard":
		expedition.register_phenomenon_witnessed("glacial_blizzard")
	elif event_type == "storm" or event_type == "rain":
		expedition.register_phenomenon_witnessed("monsoon_rain")

func _process(delta: float) -> void:
	if fishing_system:
		fishing_system.update(delta)

	if village and day_night and day_night.has_method("is_night"):
		village.set_night_lighting(day_night.is_night())

	# 1. Title Screen Scenic Camera Drift
	if expedition and expedition.current_state == ExpeditionManager.GameState.TITLE_SCREEN:
		_scenic_orbit_angle += delta * 0.04
		if camera and is_instance_valid(camera):
			var orbit_r: float = 62.0
			var cam_x: float = cos(_scenic_orbit_angle) * orbit_r
			var cam_z: float = sin(_scenic_orbit_angle) * orbit_r
			camera.position = Vector3(cam_x, 24.0, cam_z)
			camera.look_at(Vector3(0.0, 8.0, 0.0), Vector3.UP)
		return

	# 2. Active Gameplay Ecosystem Presence & Tracking
	if bootstrap and bootstrap.ecosystem_coordinator and camera:
		var cam_pos: Vector3 = camera.global_position if camera.is_inside_tree() else camera.position
		var is_character: bool = (camera.current_mode == FreeLookCamera.CameraMode.FIRST_PERSON_WALKER or camera.current_mode == FreeLookCamera.CameraMode.THIRD_PERSON_CHARACTER)
		var is_grounded: bool = is_character or (cam_pos.y < 12.0)
		var presence_pos: Vector3 = cam_pos
		var p_speed: float = 0.0
		var walker: FirstPersonWalker = camera.get_walker() if is_character else null
		if is_character and walker:
			presence_pos = walker.global_position if walker.is_inside_tree() else walker.position
			p_speed = Vector2(walker.velocity.x, walker.velocity.z).length()
		bootstrap.ecosystem_coordinator.set_player_presence(presence_pos, is_grounded, p_speed)

		# Dynamic Interactive Foliage Parting (Zelda BotW / RDR2 Physical Foliage Response)
		if scatter and scatter.has_method("update_actor_interaction"):
			var is_mounted: bool = (walker != null and walker.has_method("is_mounted") and walker.is_mounted())
			var f_radius: float = 2.2 if is_mounted else 1.45
			var f_strength: float = 0.85 if is_mounted else 0.65
			scatter.update_actor_interaction(presence_pos, f_radius, f_strength)

		# 3. Expedition Telemetry & Wildlife Discovery
		if expedition and expedition.current_state == ExpeditionManager.GameState.PLAYING:
			expedition.record_player_step(presence_pos, delta)
			expedition.check_quest_progress("PLAYER_POSITION", {"position": presence_pos})

			_fauna_check_timer += delta
			if _fauna_check_timer >= 0.5:
				_fauna_check_timer = 0.0
				_check_wildlife_and_phenomena_proximity(presence_pos)

		# 4. Update Wildlife Fauna (Sheep, Ducks & Frogs with RDR2/Genshin Reactive Threat Sensing)
		var is_sprinting: bool = (walker != null and p_speed > 5.0)
		var is_attacking: bool = (walker != null and walker.has_method("get_weapon_system") and walker.get_weapon_system() != null and walker.get_weapon_system().is_drawn)
		var near_fire: bool = wildfire_system.is_position_near_fire(presence_pos, 8.0) if wildfire_system else false

		for s in sheep_flock:
			if is_instance_valid(s) and s.has_method("update_behavior"):
				s.update_behavior(delta, presence_pos, is_sprinting, is_attacking, near_fire)
		for d in duck_flock:
			if is_instance_valid(d) and d.has_method("update_behavior"):
				d.update_behavior(delta, presence_pos, is_sprinting)
		for fr in frog_flock:
			if is_instance_valid(fr) and fr.has_method("update_behavior"):
				fr.update_behavior(delta, presence_pos)

		# 5. Block 64 Elemental & Wildfire Simulations
		if wildfire_system and wildfire_system.has_method("update_simulation"):
			var p_walker: Node = walker
			wildfire_system.update_simulation(delta, p_walker)
		if ice_system and ice_system.has_method("update_simulation"):
			ice_system.update_simulation(delta)
		if elemental_controller and elemental_controller.has_method("update"):
			elemental_controller.update(delta)

		# Block 65 Phase 5 Systems Update
		if foliage_lod_system and foliage_lod_system.has_method("update_lod"):
			foliage_lod_system.update_lod(delta, presence_pos)
		if glassmorphic_hud and glassmorphic_hud.has_method("update_hud") and elemental_controller:
			var is_acting: bool = (p_speed > 0.5 or is_attacking or is_sprinting)
			var cd_ratio: float = 1.0 - (elemental_controller.skill_cooldown / 6.0) if elemental_controller.skill_cooldown > 0.0 else 1.0
			glassmorphic_hud.update_hud(delta, is_acting, elemental_controller.current_element, cd_ratio)
		if acoustic_system and acoustic_system.has_method("update_ambience") and bootstrap and bootstrap.weather_system:
			var w_spd: float = bootstrap.weather_system.wind_speed
			acoustic_system.update_ambience(delta, presence_pos, w_spd)

		# 5. Update Luminescent Night Flora
		if luminescent_flora and luminescent_flora.has_method("update_flora"):
			var is_night: bool = day_night.is_night() if (day_night and day_night.has_method("is_night")) else false
			luminescent_flora.update_flora(delta, is_night, presence_pos)

		# 6. Update Aerial Flight Rings & Wind Highway Dynamics
		if flight_rings and flight_rings.has_method("update_flight_physics") and is_character and walker:
			var boost_res: Dictionary = flight_rings.update_flight_physics(delta, walker)
			if boost_res.get("boost", false):
				var b_dir: Vector3 = boost_res.get("boost_dir", Vector3.FORWARD)
				var b_spd: float = boost_res.get("boost_speed", 16.5)
				var l_imp: float = boost_res.get("lift_impulse", 3.2)
				walker.velocity.x = b_dir.x * b_spd
				walker.velocity.z = b_dir.z * b_spd
				walker.velocity.y = maxf(walker.velocity.y, l_imp)
				if walker.has_method("open_glider") and "is_gliding" in walker and not walker.is_gliding:
					walker.open_glider()

		# 7. Update Block 55 Living World Entities (Crystalflies & Seelie)
		if crystalfly_swarm and crystalfly_swarm.has_method("update_behavior"):
			crystalfly_swarm.update_behavior(delta, presence_pos, p_speed)
		if wandering_seelie and wandering_seelie.has_method("update_behavior"):
			wandering_seelie.update_behavior(delta, presence_pos)

		# 8. Update Block 56 RDR2 Wildlife Ecosystem & Campfire Director
		if wildlife_ecosystem and wildlife_ecosystem.has_method("update_behavior"):
			wildlife_ecosystem.update_behavior(delta, presence_pos, p_speed)
		if campfire_director and campfire_director.has_method("update_weather_reaction") and bootstrap and bootstrap.weather_system:
			var r_intensity: float = 0.85 if bootstrap.weather_system.current_state == WeatherSystem.WeatherState.RAIN else 0.0
			campfire_director.update_weather_reaction(delta, r_intensity)

		# 9. Update Block 57 Anemo Wind Geyser Aerodynamics
		if anemo_geyser and camera and camera.get_walker():
			anemo_geyser.check_character_propulsion(camera.get_walker())

		# 10. Update Block 58 Aerial Trial Ring Passage & Mythic Stag Proximity
		if aerial_trial and camera and camera.get_walker():
			var walker_node = camera.get_walker()
			if aerial_trial.is_trial_active and aerial_trial.check_character_ring_passage(walker_node.global_position):
				var boost_fwd: Vector3 = -walker_node.global_transform.basis.z
				boost_fwd.y = 0.0
				boost_fwd = boost_fwd.normalized()
				if "velocity" in walker_node:
					walker_node.velocity.x += boost_fwd.x * 8.5
					walker_node.velocity.z += boost_fwd.z * 8.5
					walker_node.velocity.y = maxf(walker_node.velocity.y, 2.5)
				if walker_node.has_method("open_glider") and "is_gliding" in walker_node and not walker_node.is_gliding:
					walker_node.open_glider()
		if mythic_stag and presence_pos.distance_to(mythic_stag.global_position if mythic_stag.is_inside_tree() else mythic_stag.position) <= 22.0:
			mythic_stag.alert_to_player(presence_pos)

		# 11. Update Block 59 Grizzly Patriarch Proximity & Hydro Spout Launch
		if grizzly_patriarch and grizzly_patriarch.has_method("check_player_spotted"):
			grizzly_patriarch.check_player_spotted(presence_pos)
		if hydro_puzzle and camera and camera.get_walker():
			hydro_puzzle.check_player_launch(presence_pos, camera.get_walker())

		_update_interaction_prompts(presence_pos)

func _check_wildlife_and_phenomena_proximity(p_pos: Vector3) -> void:
	if not expedition:
		return

	# High elevation blizzard check (Skyspire Massif summit)
	if p_pos.y >= 68.0:
		expedition.register_phenomenon_witnessed("glacial_blizzard")

	# Weather check
	if bootstrap and bootstrap.weather_system:
		if bootstrap.weather_system.current_state == WeatherSystem.WeatherState.RAIN:
			expedition.register_phenomenon_witnessed("monsoon_rain")

	# Diurnal celestial checks
	if bootstrap and bootstrap.world_clock:
		var is_day: bool = bootstrap.world_clock.is_daytime()
		if is_day:
			expedition.register_species_cataloged("forest_songbird")
		else:
			expedition.register_species_cataloged("meadow_firefly")
			if bootstrap.weather_system and bootstrap.weather_system.current_state == WeatherSystem.WeatherState.CLEAR:
				expedition.register_phenomenon_witnessed("aurora_borealis")

	# Proximity to Herbivores (Deer) & Predators (Wolf)
	if bootstrap and bootstrap.ecosystem_coordinator and bootstrap.ecosystem_coordinator.fauna_sim:
		var sim: FaunaSimulation = bootstrap.ecosystem_coordinator.fauna_sim
		for h in sim._herbivores.values():
			if p_pos.distance_to(h.position) < 18.0:
				expedition.register_species_cataloged("red_deer")
				break
		for p in sim._predators.values():
			if p_pos.distance_to(p.position) < 24.0:
				expedition.register_species_cataloged("gray_wolf")
				break

	# Marine Kelp & Underwater Flora quest check
	if p_pos.y < 0.2:
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "gather_kelp_flora"})

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_N:
			# Authoritative high-priority character switch (unblockable by UI controls)
			var walker: FirstPersonWalker = camera.get_walker() if camera else null
			if walker and walker.has_method("switch_character"):
				var char_idx: int = walker.switch_character()
				var reg = walker.get("character_registry")
				var char_name: String = reg.get_active_name() if reg else ("Nhân Vật %d" % char_idx)
				var char_icon: String = reg.get_active_icon() if reg else "👤"
				print("[Main] Character Switched via [N] -> %d (%s)" % [char_idx, char_name])
				if interaction_hud:
					interaction_hud.show_pickup_toast("Nhân Vật: %s" % char_name, 1, char_icon)
				if hud and hud.has_method("show_toast"):
					hud.show_toast("Nhân Vật: %s [N]" % char_name, true)
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_O:
			# Outfit cycle — authoritative in _input so HUD KEY_O never fires
			var walker: FirstPersonWalker = camera.get_walker() if camera else null
			if walker:
				var char_idx: int = walker.get_active_character_index() if walker.has_method("get_active_character_index") else 0
				if char_idx == 1 and walker.has_method("cycle_douyin_outfit"):
					var mode: int = walker.cycle_douyin_outfit()
					var outfit_name: String = "Bikini Trắng 👙" if mode == 0 else "Nude Tự Nhiên ✨"
					var outfit_icon: String = "👙" if mode == 0 else "✨"
					if interaction_hud:
						interaction_hud.show_pickup_toast("Douyin: %s" % outfit_name, 1, outfit_icon)
					if hud and hud.has_method("show_toast"):
						hud.show_toast("Outfit: %s [O]" % outfit_name, true)
				elif walker.has_method("cycle_outfit"):
					var mode: int = walker.cycle_outfit()
					var outfit_name: String = "Standard Adventurer"
					var outfit_icon: String = "👗"
					match mode:
						0:
							outfit_name = "Standard Adventurer"
							outfit_icon = "👗"
						1:
							outfit_name = "Summer Micro-Bikini"
							outfit_icon = "👙"
						2:
							outfit_name = "Nude Custom Skin"
							outfit_icon = "✨"
					if interaction_hud:
						interaction_hud.show_pickup_toast("Trang Phục: %s" % outfit_name, 1, outfit_icon)
					if hud and hud.has_method("show_toast"):
						hud.show_toast("Trang Phục: %s [O]" % outfit_name, true)
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F12:
			capture_screenshot("res://screenshot_first_playable.png")
		elif event.keycode == KEY_H or event.keycode == KEY_F1:
			if hud:
				hud.visible = not hud.visible
				print("[Main] HUD toggled: %s" % ("Visible" if hud.visible else "Hidden"))
			if glassmorphic_hud and glassmorphic_hud.has_method("toggle_visibility"):
				glassmorphic_hud.toggle_visibility()

		elif event.keycode == KEY_B:
			if alchemy_modal:
				if alchemy_modal.is_open():
					alchemy_modal.close_modal()
				else:
					alchemy_modal.open_modal()
		elif event.keycode == KEY_F:
			var walker: FirstPersonWalker = camera.get_walker() if camera else null
			if walker and walker.is_mounted():
				walker.dismount_steed()
				if interaction_hud:
					interaction_hud.show_pickup_toast("Đã Xuống Thú Cưỡi", 1, "🐎")
			elif walker and prairie_steed and walker.global_position.distance_to(prairie_steed.global_position) <= 3.8:
				walker.mount_steed(prairie_steed)
				if interaction_hud:
					interaction_hud.show_pickup_toast("Đã Cưỡi Hươu Thảo Nguyên! (WASD phi, SPACE nhảy, F xuống)", 1, "🦌")
			else:
				_handle_fishing_toggle()
		elif event.keycode == KEY_F3:
			var walker: FirstPersonWalker = camera.get_walker() if camera else null
			if walker and walker.has_method("toggle_selfie_mode"):
				var is_selfie: bool = walker.toggle_selfie_mode()
				if interaction_hud:
					interaction_hud.show_pickup_toast("Chế Độ Chụp Ảnh Selfie: BẬT (1-5 biểu cảm, Click/E chụp)" if is_selfie else "Chế Độ Chụp Ảnh: TẮT", 1, "📸")
		elif (event.keycode >= KEY_1 and event.keycode <= KEY_5):
			var walker: FirstPersonWalker = camera.get_walker() if camera else null
			if walker and walker.is_selfie_mode:
				var expr_idx: int = event.keycode - KEY_1 + 1
				walker.set_facial_expression_by_index(expr_idx)
				var expr_names: Array[String] = ["Nụ Cười Tươi", "Kinh Ngạc / Kỳ Thú", "Quyết Tâm / Chiến Đấu", "Nháy Mắt Tinh Nghịch", "Thư Thái / Tự Nhiên"]
				if interaction_hud:
					interaction_hud.show_pickup_toast("Biểu cảm: " + expr_names[expr_idx - 1], 1, "😊")
		elif event.keycode == KEY_R:
			var walker: FirstPersonWalker = camera.get_walker() if camera else null
			if walker and walker.has_method("toggle_weapon"):
				var is_drawn: bool = walker.toggle_weapon()
				if interaction_hud:
					interaction_hud.show_pickup_toast("Thế Chiến Đấu: Rút Kiếm" if is_drawn else "Bao Kiếm Sau Lưng", 1, "⚔️" if is_drawn else "🗡️")
		elif event.keycode == KEY_J:
			_handle_player_attack()
		elif event.keycode == KEY_Z:
			if elemental_controller:
				elemental_controller.cycle_element()
		elif event.keycode == KEY_Q:
			_handle_elemental_skill_cast()
		elif event.keycode == KEY_V:
			if hunter_eagle_eye:
				var active: bool = hunter_eagle_eye.toggle_eagle_eye()
				if interaction_hud:
					interaction_hud.show_pickup_toast("Giác Quan Thợ Săn: BẬT" if active else "Giác Quan Thợ Săn: TẮT", 1, "🦅" if active else "👁️")
		elif event.keycode == KEY_M:
			if waypoint_modal:
				if waypoint_modal.is_open():
					waypoint_modal.close_modal()
				else:
					waypoint_modal.open_modal()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_E:
			if fishing_system and fishing_system.is_biting():
				_handle_fishing_strike()
				return
			if event.keycode == KEY_E:
				_handle_player_interaction()
	elif event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if not (dialogue_modal and dialogue_modal.is_dialogue_open()) and not (alchemy_modal and alchemy_modal.is_open()) and not (waypoint_modal and waypoint_modal.is_open()):
			_handle_player_attack()

func _handle_player_attack() -> void:
	var walker: FirstPersonWalker = camera.get_walker() if camera else null
	if not walker or not walker.visible:
		return
	if walker.has_method("trigger_weapon_attack"):
		walker.trigger_weapon_attack()
		if village:
			var p_pos: Vector3 = walker.global_position
			var inter: Dictionary = village.get_nearby_interactable(p_pos)
			if inter.get("id", "") == "PracticeDummy":
				village.strike_practice_dummy()
				if walker.has_method("get_weapon_system") and walker.get_weapon_system():
					var ws = walker.get_weapon_system()
					if ws and ws.has_method("register_hit"):
						ws.register_hit("PracticeDummy", p_pos)
				if ui_audio:
					ui_audio.play_button_click()
				if expedition:
					expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "blacksmith_tinkering"})
					expedition.add_expedition_points(35)
		if chest_system and chest_system.has_method("strike_monument"):
			var mon = chest_system.get_node_or_null("AnemoElementalMonument")
			if mon:
				var m_pos: Vector3 = mon.global_position if mon.is_inside_tree() else mon.position
				if walker.global_position.distance_to(m_pos) < 5.0:
					chest_system.strike_monument()
					if walker.has_method("get_weapon_system") and walker.get_weapon_system():
						var ws = walker.get_weapon_system()
						if ws and ws.has_method("register_hit"):
							ws.register_hit("AnemoElementalMonument", m_pos)
					if ui_audio:
						ui_audio.play_milestone_fanfare()
					if interaction_hud:
						interaction_hud.show_pickup_toast("Kích Hoạt: Trụ Phong Nguyên Tố", 1, "🌀")
					if expedition:
						expedition.add_expedition_points(120)
		if torch_puzzle and not torch_puzzle._is_puzzle_solved:
			var inter: Dictionary = torch_puzzle.get_nearby_interactable(walker.global_position, 3.2)
			if inter.get("type", "") == "torch":
				torch_puzzle.ignite_torch(inter.get("index", 0))
		if anemo_geyser and anemo_geyser.is_sealed:
			if walker.global_position.distance_to(anemo_geyser.global_position) <= anemo_geyser.vent_radius + 2.0:
				anemo_geyser.damage_seal(1)
				if ui_audio:
					ui_audio.play_button_click()
				if interaction_hud:
					interaction_hud.show_pickup_toast("Công Phá Đá Phong Ấn! (Còn %d/3)" % anemo_geyser.seal_health, 1, "⛏️")
		if hydro_puzzle:
			var near_seal: int = hydro_puzzle.get_nearest_inactive_seal(walker.global_position)
			if near_seal != -1:
				hydro_puzzle.activate_seal(near_seal)

func _handle_elemental_skill_cast() -> void:
	var walker: FirstPersonWalker = camera.get_walker() if camera else null
	if not walker or not walker.visible or not elemental_controller:
		return

	var cam_yaw: float = walker.get_camera_yaw() if walker.has_method("get_camera_yaw") else camera.rotation.y
	var cam_forward: Vector3 = Vector3(-sin(cam_yaw), -0.15, -cos(cam_yaw)).normalized()
	var origin: Vector3 = walker.global_position + Vector3(0.0, 1.35, 0.0)

	var res: Dictionary = elemental_controller.cast_skill(origin, cam_forward)
	if res.get("success", false):
		if walker.has_method("trigger_weapon_attack"):
			walker.trigger_weapon_attack()
		_check_elemental_skill_targets(res)
	else:
		if interaction_hud and res.get("reason", "") == "cooldown":
			interaction_hud.show_pickup_toast("Kỹ Năng Đang Hồi: %.1fs" % res.get("time_left", 1.0), 1, "⏳")

func _check_elemental_skill_targets(skill_res: Dictionary) -> void:
	var t_pos: Vector3 = skill_res.get("target_pos", Vector3.ZERO)
	var elem: int = skill_res.get("element", 1)

	# Check Practice Dummy
	if village:
		var dummy = village.get_node_or_null("PracticeDummy")
		if dummy:
			var d_pos: Vector3 = dummy.global_position if dummy.is_inside_tree() else dummy.position
			if t_pos.distance_to(d_pos) < 5.0:
				village.strike_practice_dummy()
				if interaction_hud:
					interaction_hud.show_pickup_toast("Sát Thương Nguyên Tố Trúng Bia Tập Kiếm!", 1, "⚔️")

	# Check Anemo Monument
	if chest_system and elem == 1: # ANEMO
		var mon = chest_system.get_node_or_null("AnemoElementalMonument")
		if mon:
			var m_pos: Vector3 = mon.global_position if mon.is_inside_tree() else mon.position
			if t_pos.distance_to(m_pos) < 6.5:
				chest_system.strike_monument()
				if interaction_hud:
					interaction_hud.show_pickup_toast("Kích Hoạt: Trụ Phong Nguyên Tố!", 1, "🌀")

	# Check Hydro Lake Sanctuary Puzzle
	if hydro_puzzle and elem == 3: # HYDRO
		var near_seal: int = hydro_puzzle.get_nearest_inactive_seal(t_pos)
		if near_seal != -1:
			hydro_puzzle.activate_seal(near_seal)

func _on_element_changed(elem: int, elem_name: String, icon: String, col: Color) -> void:
	if glassmorphic_hud and glassmorphic_hud.has_method("set_element"):
		glassmorphic_hud.set_element(elem)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Hệ Nguyên Tố: " + elem_name + " [Q: Dùng Chiêu]", 1, icon)
	if ui_audio:
		ui_audio.play_button_click()
	var walker: FirstPersonWalker = camera.get_walker() if camera else null
	if walker and walker.has_method("get_weapon_system") and walker.get_weapon_system():
		var ws = walker.get_weapon_system()
		if ws and "blade_color" in ws:
			ws.blade_color = col

func _on_walker_footstep_played(surface_type: String) -> void:
	if acoustic_system and camera:
		var walker: FirstPersonWalker = camera.get_walker()
		var p_pos: Vector3 = walker.global_position if walker else Vector3.ZERO
		acoustic_system.play_surface_footstep(surface_type, p_pos)

func _on_elemental_reaction_triggered(reaction_type: int, reaction_name: String, pos: Vector3, col: Color) -> void:
	if interaction_hud:
		interaction_hud.show_pickup_toast("Phản Ứng: " + reaction_name, 1, "💥")
	var walker: FirstPersonWalker = camera.get_walker() if camera else null
	if walker and walker.has_method("apply_camera_shake"):
		walker.apply_camera_shake(0.25, 1.4)
	if expedition:
		expedition.add_expedition_points(60)

func _handle_player_interaction() -> void:
	# 1. If boat is currently being rowed, dismount back onto shore
	var marine = get_node_or_null("MarineEcosystem")
	var boat: DrivableBoat = marine.get_boat() if (marine and marine.has_method("get_boat")) else null
	if boat and boat.is_driven:
		boat.dismount_player()
		return

	# 2. Check if player walker is active
	var walker: FirstPersonWalker = camera.get_walker() if camera else null
	if not walker or not walker.visible:
		return
	var p_pos: Vector3 = walker.global_position

	# 2a. If in selfie mode, capture snapshot on interaction
	if walker.is_selfie_mode:
		walker.capture_selfie()
		if interaction_hud:
			interaction_hud.show_pickup_toast("Đã Chụp Ảnh Kỷ Niệm! +150 EXP", 1, "📸")
		if expedition:
			expedition.add_expedition_points(150)
		return

	# 2b. Check Submerged Sea Cavern passages & secret chest
	if sea_cavern and sea_cavern.has_method("get_interaction_prompt"):
		var cav_i: Dictionary = sea_cavern.get_interaction_prompt(p_pos)
		if not cav_i.is_empty():
			var cav_res: Dictionary = sea_cavern.trigger_interaction(walker, cav_i["action"])
			if cav_res.get("success", false):
				if cav_i["action"] == "open_chest":
					if expedition:
						expedition.add_expedition_points(450)
						expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "salvage_sunken_chest"})
					if ui_audio:
						ui_audio.play_milestone_fanfare()
					if interaction_hud:
						interaction_hud.show_pickup_toast("Mở Rương Cổ Đáy Hang! Nhận Con Dấu Hoàng Gia", 1, "👑")
				else:
					if ui_audio:
						ui_audio.play_item_pickup()
					if interaction_hud:
						interaction_hud.show_pickup_toast("Dịch chuyển qua Hang Biển Ngầm", 1, "🌊")
				return

	# 3. If near boat, board the boat
	if boat and boat.can_interact(p_pos):
		boat.mount_player(walker, camera)
		if expedition:
			expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "boat_expedition"})
		return

	# 4. Check sunken galleon treasure chest
	if marine and marine.has_method("get_nearby_interactable"):
		var m_interact: Dictionary = marine.get_nearby_interactable(p_pos)
		if not m_interact.is_empty():
			if m_interact.get("id", "") == "SunkenChest":
				var _loot = marine.loot_sunken_chest()
				if expedition:
					expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "salvage_sunken_chest"})
				if ui_audio:
					ui_audio.play_landmark_chime()
				return

	# 5. Check castle citadel interactables (Raymond, Relic, Braziers, Sarcophagus)
	if castle:
		var c_interact: Dictionary = castle.get_nearby_interactable(p_pos)
		if not c_interact.is_empty():
			var c_id: String = c_interact.get("id", "")
			if c_id == "Raymond":
				_open_npc_dialogue("NPC", "Raymond")
				return
			elif c_id == "CastleRelic":
				if castle.activate_relic():
					if expedition:
						expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "castle_ruins_investigation"})
					if ui_audio:
						ui_audio.play_milestone_fanfare()
				return
			elif c_id == "CatacombBrazierAlpha" or c_id == "CatacombBrazierBeta":
				if castle.light_brazier(c_id):
					if ui_audio:
						ui_audio.play_item_pickup()
					if castle.are_both_braziers_lit():
						if ui_audio:
							ui_audio.play_milestone_fanfare()
				return
			elif c_id == "AncientSarcophagus":
				if not castle.are_both_braziers_lit():
					if ui_audio:
						ui_audio.play_button_click()
					return
				if not castle.is_sarcophagus_looted():
					var loot: Dictionary = castle.open_sarcophagus()
					if not loot.is_empty():
						if alchemy_system:
							alchemy_system.add_ingredient("ancient_royal_seal", 1)
						if expedition:
							expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "castle_ruins_investigation"})
						if ui_audio:
							ui_audio.play_milestone_fanfare()
					return

	# 6. If dialogue or alchemy is already open, do nothing
	if dialogue_modal and dialogue_modal.is_dialogue_open():
		return
	if alchemy_modal and alchemy_modal.is_open():
		return

	# 7. Check village NPC or signpost proximity
	if village:
		var interact: Dictionary = village.get_nearby_interactable(p_pos)
		if not interact.is_empty():
			var i_type: String = interact.get("type", "")
			var i_id: String = interact.get("id", "")
			if i_id == "PracticeDummy":
				village.strike_practice_dummy()
				if ui_audio:
					ui_audio.play_button_click()
				if expedition:
					expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "blacksmith_tinkering"})
				return
			elif i_id == "Buster":
				var b_res: Dictionary = village.pet_buster()
				var fc: RefCounted = walker.get_facial_controller() if walker.has_method("get_facial_controller") else null
				if fc and fc.has_method("trigger_joy"):
					fc.trigger_joy(3.5)
				walker.walk_speed = 3.6 * 1.15
				walker.sprint_speed = 7.5 * 1.15
				if interaction_hud:
					interaction_hud.show_pickup_toast(b_res.get("message", "Đã vuốt ve Buster!"), 1, "🐶")
				if expedition:
					expedition.add_expedition_points(60)
					expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "pet_village_animals"})
				return
			elif i_id == "Mimi":
				var m_res: Dictionary = village.pet_mimi()
				var fc: RefCounted = walker.get_facial_controller() if walker.has_method("get_facial_controller") else null
				if fc and fc.has_method("trigger_joy"):
					fc.trigger_joy(3.5)
				if interaction_hud:
					interaction_hud.show_pickup_toast(m_res.get("message", "Đã vuốt ve Mimi!"), 1, "🐱")
				if expedition:
					expedition.add_expedition_points(60)
					expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "pet_village_animals"})
				return
			_open_npc_dialogue(i_type, i_id)
			return

	# 8. Check wild foraging flora nodes
	if foraging_nodes:
		var f_i: Dictionary = foraging_nodes.get_nearby_forageable(p_pos)
		if not f_i.is_empty():
			var res: Dictionary = foraging_nodes.collect_node(f_i["id"])
			if not res.is_empty():
				if alchemy_system:
					alchemy_system.add_ingredient(res["item_id"], res["count"])
				if ui_audio:
					ui_audio.play_item_pickup()
				if interaction_hud:
					interaction_hud.show_pickup_toast(res["item_name"], res["count"], res["icon"])
				if expedition:
					expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "forage_wild_herbs"})
			return

	# 9. Check Ancient Teleport Waypoint proximity
	if waypoint_network:
		var wp_i: Dictionary = waypoint_network.get_nearby_interactable(p_pos)
		if not wp_i.is_empty():
			var wp_id: String = wp_i.get("id", "")
			var wp: Node3D = waypoint_network.get_waypoint(wp_id)
			if wp:
				if not wp.is_unlocked:
					if wp.unlock():
						var fc: RefCounted = walker.get_facial_controller() if walker.has_method("get_facial_controller") else null
						if fc and fc.has_method("trigger_surprise"):
							fc.trigger_surprise(2.8)
						if ui_audio:
							ui_audio.play_milestone_fanfare()
						if interaction_hud:
							interaction_hud.show_pickup_toast("Khai Mở: " + wp.waypoint_name, 1, "✨")
						if expedition:
							expedition.add_expedition_points(150)
							expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "unlock_waypoint"})
				else:
					if waypoint_modal:
						waypoint_modal.open_modal()
			return

	# 10. Check Exploration Treasure Chests
	if chest_system and chest_system.has_method("get_nearest_unopened_chest"):
		var near_cid: String = chest_system.get_nearest_unopened_chest(p_pos, 3.5)
		if not near_cid.is_empty():
			chest_system.open_chest(near_cid)
			return

	# 11. Check Highland Sheep Petting
	for s in sheep_flock:
		if is_instance_valid(s) and s.is_inside_tree():
			if s.global_position.distance_to(p_pos) < 3.0:
				s.pet_sheep()
				var fc: RefCounted = walker.get_facial_controller() if walker.has_method("get_facial_controller") else null
				if fc and fc.has_method("trigger_joy"):
					fc.trigger_joy(3.0)
				if interaction_hud:
					interaction_hud.show_pickup_toast("Đã vuốt ve Cừu (+50 EXP, +1 Lông Cừu)", 1, "🐑")
				if alchemy_system:
					alchemy_system.add_ingredient("sheep_wool", 1)
				if expedition:
					expedition.add_expedition_points(50)
					expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "pet_highland_sheep"})
				return

	# 11b. Check Luminescent Night Flora Harvest (Star Lotus / Spore Mushroom)
	if luminescent_flora and luminescent_flora.has_method("get_nearby_forageable"):
		var f_res: Dictionary = luminescent_flora.get_nearby_forageable(p_pos)
		if not f_res.is_empty():
			luminescent_flora.harvest_flora(f_res["id"])
			return

	# 11c. Check Anemo Crystalfly Catch
	if crystalfly_swarm and crystalfly_swarm.has_method("get_nearby_crystalfly"):
		var fly_res: Dictionary = crystalfly_swarm.get_nearby_crystalfly(p_pos)
		if not fly_res.is_empty():
			crystalfly_swarm.catch_crystalfly(fly_res["id"])
			return

	# 11d. Check Wandering Seelie Chest
	if wandering_seelie and wandering_seelie.has_method("get_nearby_interactable"):
		var s_inter: Dictionary = wandering_seelie.get_nearby_interactable(p_pos)
		if not s_inter.is_empty():
			wandering_seelie.open_seelie_chest()
			return

	# 11e. Check Ancient Anemo Statue (Prayer & Gliding Time Trial)
	if anemo_statue and anemo_statue.has_method("get_nearby_interactable"):
		var st_inter: Dictionary = anemo_statue.get_nearby_interactable(p_pos)
		if not st_inter.is_empty():
			var st_id: String = st_inter.get("id", "")
			if st_id == "anemo_time_trial":
				anemo_statue.start_time_trial()
				return
			elif st_id == "anemo_statue_prayer":
				anemo_statue.pray_at_statue(walker)
				return

	# 11f. Check Wilderness Campfire
	if wilderness_camp and wilderness_camp.has_method("get_nearby_interactable"):
		var cp_inter: Dictionary = wilderness_camp.get_nearby_interactable(p_pos)
		if not cp_inter.is_empty():
			var c_res: Dictionary = wilderness_camp.rest_at_campfire(walker)
			if interaction_hud:
				interaction_hud.show_pickup_toast(c_res.get("message", "Nghỉ ngơi bên lửa trại"), 1, "🏕️")
			if expedition:
				expedition.add_expedition_points(40)
			return

	# 11g. Check Wild Raspberry Bush
	if ground_dressing and ground_dressing.has_method("get_nearby_forageable"):
		var b_res: Dictionary = ground_dressing.get_nearby_forageable(p_pos)
		if not b_res.is_empty():
			ground_dressing.harvest_bush(b_res["id"])
			return

	# 11h. Check Genshin-Style Shrine of Depths
	if shrine_of_depths and shrine_of_depths.has_method("get_nearby_interactable"):
		var sh_inter: Dictionary = shrine_of_depths.get_nearby_interactable(p_pos)
		if not sh_inter.is_empty():
			var sh_id: String = sh_inter.get("id", "")
			if sh_id == "shrine_barrier":
				shrine_of_depths.unlock_shrine()
				return
			elif sh_id == "shrine_chest":
				shrine_of_depths.open_luxurious_chest()
				return

	# 11i. Check Elemental Pyro Torch Puzzle
	if torch_puzzle and torch_puzzle.has_method("get_nearby_interactable"):
		var tp_inter: Dictionary = torch_puzzle.get_nearby_interactable(p_pos)
		if not tp_inter.is_empty():
			var tp_id: String = tp_inter.get("id", "")
			if tp_id.begins_with("torch_"):
				var t_idx: int = tp_inter.get("index", 0)
				torch_puzzle.ignite_torch(t_idx)
				return
			elif tp_id == "torch_puzzle_chest":
				torch_puzzle.open_puzzle_chest()
				return

	# 11j. Check Hunter Eagle Eye Clue
	if hunter_eagle_eye and hunter_eagle_eye.has_method("get_nearest_clue"):
		var clue: Dictionary = hunter_eagle_eye.get_nearest_clue(p_pos)
		if not clue.is_empty() and not clue.get("is_inspected", false):
			hunter_eagle_eye.inspect_clue(clue["id"])
			return

	# 11k. Check Anemo Wind Geyser
	if anemo_geyser and anemo_geyser.is_sealed:
		if p_pos.distance_to(anemo_geyser.global_position) <= anemo_geyser.vent_radius + 1.2:
			anemo_geyser.damage_seal(1)
			if ui_audio:
				ui_audio.play_button_click()
			if interaction_hud:
				interaction_hud.show_pickup_toast("Khai Thông Mạch Gió! (Còn %d/3)" % anemo_geyser.seal_health, 1, "⛏️")
			return

	# 11l. Check Ancient Stele Inscription
	if ancient_stele and not ancient_stele.is_read:
		if p_pos.distance_to(ancient_stele.global_position) <= 3.5:
			ancient_stele.read_inscription()
			return

	# 11m. Check Aerial Ring Trial Dial
	if aerial_trial and not aerial_trial.is_trial_active:
		if aerial_trial.is_player_near_dial(p_pos):
			aerial_trial.start_trial()
			return

	# 11n. Check Aerial Ring Trial Precious Chest
	if aerial_trial and aerial_trial.is_player_near_chest(p_pos):
		aerial_trial.open_precious_chest()
		return

	# 11o. Check Mythic White Stag Communion
	if mythic_stag and mythic_stag.is_player_near(p_pos):
		mythic_stag.perform_communion()
		return

	# 11p. Check Hydro Lake Sanctuary Seals
	if hydro_puzzle:
		var seal_to_act: int = hydro_puzzle.get_nearest_inactive_seal(p_pos)
		if seal_to_act != -1:
			hydro_puzzle.activate_seal(seal_to_act)
			return

	# 11q. Check Luxurious Island Chest
	if hydro_puzzle and not hydro_puzzle.is_chest_opened and hydro_puzzle.is_player_near_chest(p_pos):
		hydro_puzzle.open_luxurious_chest()
		return

	# 11r. Check Legendary Grizzly Patriarch Photography
	if grizzly_patriarch and grizzly_patriarch.is_player_near(p_pos):
		grizzly_patriarch.take_wildlife_photo()
		return

	# 11s. Check Skyspire Beacon Altar (114m Peak)
	if skyspire_beacon and skyspire_beacon.has_method("can_interact") and skyspire_beacon.can_interact(p_pos):
		skyspire_beacon.activate_beacon()
		return

func _open_npc_dialogue(_i_type: String, i_id: String) -> void:
	if not dialogue_modal:
		return
	if i_id == "Alistair":
		dialogue_modal.open_dialogue(
			"Alistair",
			"THUYỀN TRƯỞNG ALISTAIR",
			"Trưởng Bến Cảng Tiền Đồn Haven",
			"⚓",
			"Chào mừng nhà thám hiểm đến với Tiền đồn Haven! Biển quanh vịnh ngọc bích Emerald Cove ẩn chứa rất nhiều rạn san hô và sinh vật kỳ bí. Chiếc thuyền gỗ ở cầu cảng đã sẵn sàng ra khơi, bạn có muốn nhận ủy thác thám hiểm hải trình vịnh ngọc bích không?",
			[
				{"label": "Nhận ủy thác: Hải Trình Vịnh Ngọc Bích", "quest_id": "boat_expedition", "quest_title": "⛵ Hải Trình Thám Hiểm Bến Cảng"},
				{"label": "Hỏi về bí ẩn vùng biển đảo hoang", "quest_id": "", "quest_title": ""},
				{"label": "Tạm biệt thuyền trưởng", "quest_id": "", "quest_title": ""}
			]
		)
	elif i_id == "Elowen":
		dialogue_modal.open_dialogue(
			"Elowen",
			"NHÀ THẢO DƯỢC ELOWEN",
			"Chuyên Gia Thực Vật Học & Giả Kim",
			"🌿",
			"Xin chào! Rừng rậm thảo dược và thềm lục địa san hô nơi đây lưu giữ rất nhiều mẫu thực vật quý giá. Ta có lò luyện thuốc giả kim ở đây, bạn có muốn bào chế dược liệu hoặc lặn biển khảo sát không?",
			[
				{"label": "Mở Bàn Chế Tác Giả Kim [B]", "quest_id": "open_alchemy", "quest_title": "⚗️ Giả Kim Thảo Dược"},
				{"label": "Nhận ủy thác: Khảo Sát Rừng Tảo Biển", "quest_id": "gather_kelp_flora", "quest_title": "🌿 Thu Thập Mẫu Tảo Biển & Thảo Dược"},
				{"label": "Hẹn gặp lại Elowen", "quest_id": "", "quest_title": ""}
			]
		)
	elif i_id == "HavenSign":
		dialogue_modal.open_dialogue(
			"HavenSign",
			"BIỂN CHỈ DẪN TIỀN ĐỒN HAVEN",
			"Bản Đồ Chỉ Dẫn",
			"📜",
			"← Bến Cảng & Cầu Thuyền Vịnh Ngọc Bích (Phía Đông) | Tháp Canh Haven & Ngọn Đuốc Hải Đăng (Phía Bắc) | Vườn Thảo Dược & Nhà Giả Kim (Phía Tây) | Đỉnh Núi Băng Skyspire (Phía Nam) →",
			[
				{"label": "Ghi nhận chỉ dẫn", "quest_id": "", "quest_title": ""}
			]
		)
	elif i_id == "Milo":
		var salmon_cnt: int = alchemy_system.inventory.get("emerald_salmon", 0) if alchemy_system else 0
		var sunfish_cnt: int = alchemy_system.inventory.get("golden_sunfish", 0) if alchemy_system else 0
		var oyster_cnt: int = alchemy_system.inventory.get("pearl_oyster", 0) if alchemy_system else 0
		var coins_cnt: int = alchemy_system.get_coins() if alchemy_system else 0
		dialogue_modal.open_dialogue(
			"Milo",
			"THƯƠNG NHÂN MILO",
			"Đội Trưởng Thương Hội Biển Đông",
			"💰",
			"Chào bạn! Ta thu mua các loại hải sản tươi sống và dược liệu từ ngư dân để cung ứng cho các chuyến thuyền buôn. Hiện tại bạn đang có %d Hải Tệ. Bạn có hải sản muốn giao dịch không?" % coins_cnt,
			[
				{"label": "Bán Cá Hồi Ngọc Bích (+30 Hải Tệ, có %d)" % salmon_cnt, "quest_id": "trade_salmon", "quest_title": "Bán Cá Hồi"},
				{"label": "Bán Cá Mặt Trời Hoàng Kim (+75 Hải Tệ, có %d)" % sunfish_cnt, "quest_id": "trade_sunfish", "quest_title": "Bán Cá Mặt Trời"},
				{"label": "Bán Sò Điệp Ngọc Trai (+50 Hải Tệ, có %d)" % oyster_cnt, "quest_id": "trade_oyster", "quest_title": "Bán Sò Điệp"},
				{"label": "Tạm biệt Thương nhân Milo", "quest_id": "", "quest_title": ""}
			]
		)
	elif i_id == "VillageHearth" or i_id == "BlacksmithForge":
		if alchemy_modal:
			alchemy_modal.open_modal()
	elif i_id == "Goran":
		dialogue_modal.open_dialogue(
			"Goran",
			"THỢ RÈN GORAN",
			"Bậc Thầy Luyện Kim & Rèn Đúc Haven",
			"🔨",
			"Keng! Keng! Chào nhà thám hiểm! Lò rèn làng Haven luôn đỏ lửa sẵn sàng phục vụ. Ngươi có muốn thử thách sức mạnh bằng cách tấn công bù nhìn tập luyện ở thao trường, hoặc thu thập thảo dược quý quanh đảo không?",
			[
				{"label": "Nhận ủy thác: Thử Luyện Thao Trường", "quest_id": "blacksmith_tinkering", "quest_title": "🔨 Thử Luyện Thao Trường"},
				{"label": "Nhận ủy thác: Thu Thập Dược Thảo Hoang Dã", "quest_id": "forage_wild_herbs", "quest_title": "🌿 Thu Thập Dược Thảo Hoang Dã"},
				{"label": "Mở Bàn Rèn Đúc [B]", "quest_id": "open_alchemy", "quest_title": "🔨 Bàn Rèn Đúc"},
				{"label": "Tạm biệt Thợ rèn Goran", "quest_id": "", "quest_title": ""}
			]
		)
	elif i_id == "Raymond":
		if castle and castle.has_royal_seal():
			dialogue_modal.open_dialogue(
				"Raymond",
				"HIỆP SĨ RAYMOND",
				"Hộ Vệ Tàn Tích Cổ — Giải Thoát",
				"🛡️",
				"Ngươi... Ngươi đã tìm thấy Ấn Tín Hoàng Gia Viễn Cổ từ Thạch Thất Hầm Mộ! Lời nguyền ngàn năm bảo vệ tàn tích của ta nay đã được giải thoát. Ta xin trao lại phước lành vương triều và lòng tri ân vĩnh cửu của các Hộ Vệ cho người thừa kế xứng đáng!",
				[
					{"label": "Nhận phước lành Hộ Vệ Viễn Cổ", "quest_id": "claim_warden_blessing", "quest_title": "Phước Lành Hộ Vệ Viễn Cổ"}
				]
			)
		else:
			dialogue_modal.open_dialogue(
				"Raymond",
				"HIỆP SĨ RAYMOND",
				"Hộ Vệ Tàn Tích Cổ",
				"🛡️",
				"Kẻ lạ mặt... Ngươi đã đặt chân đến Tàn tích Thành cổ của Vương quốc Viễn Cổ. Niêm phong trên đài tế cổ vật ở sân trong đang chờ người kế thừa thức tỉnh. Ngươi có dám bước tới kích hoạt Cổ Vật Khải Huyền không?",
				[
					{"label": "Nhận ủy thác: Giải Phong Ấn Thành Cổ", "quest_id": "castle_ruins_investigation", "quest_title": "🏰 Bí Mật Tàn Tích Lâu Đài Cổ"},
					{"label": "Hỏi về lịch sử Vương quốc cổ", "quest_id": "", "quest_title": ""},
					{"label": "Tạ từ Hiệp sĩ", "quest_id": "", "quest_title": ""}
				]
			)

func _handle_fishing_toggle() -> void:
	if not fishing_system:
		return
	var marine = get_node_or_null("MarineEcosystem")
	var boat: DrivableBoat = marine.get_boat() if (marine and marine.has_method("get_boat")) else null

	if boat and boat.is_driven:
		if fishing_system.is_fishing():
			if fishing_system.is_biting():
				_handle_fishing_strike()
			else:
				fishing_system.cancel_fishing()
				boat.set_fishing_visuals(false, false)
		else:
			var has_lure: bool = alchemy_system.is_buff_active("fishermans_tonic") if alchemy_system else false
			var is_deep: bool = boat.global_position.distance_to(Vector3.ZERO) > 60.0
			fishing_system.start_fishing(is_deep, has_lure)
			boat.set_fishing_visuals(true, false)
			if ui_audio:
				ui_audio.play_item_pickup()
	else:
		var walker: FirstPersonWalker = camera.get_walker() if camera else null
		if not walker:
			return
		var p_pos: Vector3 = walker.global_position
		if p_pos.y <= 1.8:
			if fishing_system.is_fishing():
				if fishing_system.is_biting():
					_handle_fishing_strike()
				else:
					fishing_system.cancel_fishing()
			else:
				var has_lure: bool = alchemy_system.is_buff_active("fishermans_tonic") if alchemy_system else false
				fishing_system.start_fishing(false, has_lure)
				if ui_audio:
					ui_audio.play_item_pickup()

func _handle_fishing_strike() -> void:
	if not fishing_system or not fishing_system.is_biting():
		return
	var catch: Dictionary = fishing_system.attempt_reel()
	if catch.get("success", false):
		var sp_id: String = catch.get("species_id", "")
		var sp_title: String = catch.get("species_name", "")
		var exp_rew: int = catch.get("exp", 100)
		if alchemy_system:
			alchemy_system.add_ingredient(sp_id, 1)
		if expedition:
			expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "catch_marine_fish"})
			expedition.add_expedition_points(exp_rew)
		if ui_audio:
			ui_audio.play_milestone_fanfare()
		print("[Main] Successfully landed fish: %s" % sp_title)
	var marine = get_node_or_null("MarineEcosystem")
	var boat: DrivableBoat = marine.get_boat() if (marine and marine.has_method("get_boat")) else null
	if boat:
		boat.set_fishing_visuals(false, false)

func _on_fish_biting(_species_hint: String) -> void:
	var marine = get_node_or_null("MarineEcosystem")
	var boat: DrivableBoat = marine.get_boat() if (marine and marine.has_method("get_boat")) else null
	if boat:
		boat.set_fishing_visuals(true, true)
	if ui_audio:
		ui_audio.play_button_hover()

func _on_fish_escaped() -> void:
	var marine = get_node_or_null("MarineEcosystem")
	var boat: DrivableBoat = marine.get_boat() if (marine and marine.has_method("get_boat")) else null
	if boat:
		boat.set_fishing_visuals(false, false)
	if ui_audio:
		ui_audio.play_button_click()

func _on_fish_caught(_sp_id: String, _sp_name: String, _exp_rew: int) -> void:
	var marine = get_node_or_null("MarineEcosystem")
	var boat: DrivableBoat = marine.get_boat() if (marine and marine.has_method("get_boat")) else null
	if boat:
		boat.set_fishing_visuals(false, false)

func _on_dialogue_quest_assigned(quest_id: String, quest_title: String) -> void:
	if expedition:
		if quest_id == "boat_expedition":
			expedition.add_custom_commission("boat_expedition", "⛵ Hải Trình Thám Hiểm Bến Cảng", "Lên thuyền tại cầu cảng và chèo quanh vịnh ngọc bích Emerald Cove.", "BOAT_VOYAGE", 1, 350)
		elif quest_id == "gather_kelp_flora":
			expedition.add_custom_commission("gather_kelp_flora", "🌿 Thu Thập Mẫu Tảo Biển & Thảo Dược", "Khám phá rừng tảo bẹ dưới đáy biển và thảo dược ven đảo.", "HERBAL_DISCOVERY", 1, 300)
		elif quest_id == "castle_ruins_investigation":
			expedition.add_custom_commission("castle_ruins_investigation", "🏰 Bí Mật Tàn Tích Lâu Đài Cổ", "Tiến vào sân trong thành cổ và kích hoạt Cổ Vật Khải Huyền.", "CASTLE_RUINS", 1, 400)
		elif quest_id == "forage_wild_herbs":
			expedition.add_custom_commission("forage_wild_herbs", "🌿 Thu Thập Dược Thảo Hoang Dã", "Thu thập 3 mẫu thảo dược hoang dã quanh các quần xã trên đảo.", "VILLAGE", 3, 300)
		elif quest_id == "blacksmith_tinkering":
			expedition.add_custom_commission("blacksmith_tinkering", "🔨 Rèn Đúc & Thử Luyện", "Tấn công bù nhìn tập luyện tại thao trường làng Haven.", "VILLAGE", 1, 250)
		elif quest_id == "open_alchemy":
			if alchemy_modal:
				alchemy_modal.open_modal()
		elif quest_id == "trade_salmon":
			if alchemy_system and alchemy_system.remove_ingredient("emerald_salmon", 1):
				alchemy_system.add_coins(30)
				if ui_audio:
					ui_audio.play_item_pickup()
		elif quest_id == "trade_sunfish":
			if alchemy_system and alchemy_system.remove_ingredient("golden_sunfish", 1):
				alchemy_system.add_coins(75)
				if ui_audio:
					ui_audio.play_item_pickup()
		elif quest_id == "trade_oyster":
			if alchemy_system and alchemy_system.remove_ingredient("pearl_oyster", 1):
				alchemy_system.add_coins(50)
				if ui_audio:
					ui_audio.play_item_pickup()
		elif quest_id == "claim_warden_blessing":
			expedition.add_expedition_points(500)
			if ui_audio:
				ui_audio.play_milestone_fanfare()
	if ui_audio:
		ui_audio.play_quest_complete()
	print("[Main] Accepted Village Quest/Trade: %s (%s)" % [quest_title, quest_id])

func _on_potion_consumed(potion_id: String, _dur: float) -> void:
	if ui_audio:
		ui_audio.play_item_pickup()
	var walker: FirstPersonWalker = camera.get_walker() if camera else null
	if walker and potion_id == "swiftness_elixir":
		walker.walk_speed = 3.6 * 1.35
		walker.sprint_speed = 7.5 * 1.35
		print("[Main] Swiftness buff active: +35% move speed.")

func _on_potion_buff_expired(potion_id: String) -> void:
	var walker: FirstPersonWalker = camera.get_walker() if camera else null
	if walker and potion_id == "swiftness_elixir":
		walker.walk_speed = 3.6
		walker.sprint_speed = 7.5
		print("[Main] Swiftness buff expired.")

func capture_screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var viewport: Viewport = get_viewport()
	if viewport:
		var tex: ViewportTexture = viewport.get_texture()
		if tex:
			var img: Image = tex.get_image()
			if img:
				var global_path: String = ProjectSettings.globalize_path(path)
				var err: Error = img.save_png(global_path)
				if err == OK:
					print("[Main] Screenshot saved successfully: %s" % global_path)
				else:
					printerr("[Main] Failed to save screenshot. Error code: %d" % err)

func _on_item_foraged(item_id: String, item_name: String, count: int, icon: String) -> void:
	if alchemy_system:
		alchemy_system.add_ingredient(item_id, count)
	if ui_audio:
		ui_audio.play_item_pickup()
	if interaction_hud:
		interaction_hud.show_pickup_toast(item_name, count, icon)
	if expedition:
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "forage_wild_herbs"})

func _update_interaction_prompts(p_pos: Vector3) -> void:
	if not interaction_hud:
		return
	if dialogue_modal and dialogue_modal.is_dialogue_open():
		interaction_hud.hide_prompt()
		return
	if alchemy_modal and alchemy_modal.is_open():
		interaction_hud.hide_prompt()
		return

	# 1. Boat
	var marine = get_node_or_null("MarineEcosystem")
	var boat: DrivableBoat = marine.get_boat() if (marine and marine.has_method("get_boat")) else null
	if boat and boat.is_driven:
		interaction_hud.show_prompt("boat_dismount", "Cập bến", "Rời Thuyền Lên Bờ", "⚓")
		return
	elif boat and boat.can_interact(p_pos):
		interaction_hud.show_prompt("boat_board", "Chèo thuyền", "Thuyền Gỗ Skiff", "⛵")
		return

	# 2. Sunken chest
	if marine and marine.has_method("get_nearby_interactable"):
		var m_i: Dictionary = marine.get_nearby_interactable(p_pos)
		if not m_i.is_empty():
			interaction_hud.show_prompt("sunken_chest", "Mở rương", "Rương Báu Đắm Tàu", "📦")
			return

	# 3. Castle
	if castle:
		var c_i: Dictionary = castle.get_nearby_interactable(p_pos)
		if not c_i.is_empty():
			var c_id: String = c_i.get("id", "")
			match c_id:
				"Raymond":
					interaction_hud.show_prompt("raymond", "Trò chuyện", "Hiệp Sĩ Raymond", "🛡️")
				"CastleRelic":
					interaction_hud.show_prompt("relic", "Kích hoạt", "Đài Tế Cổ Vật Khải Huyền", "✨")
				"CatacombBrazierAlpha", "CatacombBrazierBeta":
					interaction_hud.show_prompt("brazier", "Thắp đuốc", "Hỏa Lò Hầm Mộ", "🔥")
				"AncientSarcophagus":
					interaction_hud.show_prompt("sarcophagus", "Mở nắp", "Thạch Thất Vương Tộc Viễn Cổ", "👑")
				_:
					interaction_hud.show_prompt("castle", "Tương tác", c_id, "🏰")
			return

	# 4. Village
	if village:
		var v_i: Dictionary = village.get_nearby_interactable(p_pos)
		if not v_i.is_empty():
			var v_id: String = v_i.get("id", "")
			match v_id:
				"Alistair":
					interaction_hud.show_prompt("alistair", "Trò chuyện", "Thuyền Trưởng Alistair", "⚓")
				"Elowen":
					interaction_hud.show_prompt("elowen", "Trò chuyện", "Nhà Thảo Dược Elowen", "🌿")
				"Milo":
					interaction_hud.show_prompt("milo", "Giao thương", "Thương Nhân Milo", "💰")
				"Goran":
					interaction_hud.show_prompt("goran", "Trò chuyện", "Thợ Rèn Goran", "🔨")
				"PracticeDummy":
					interaction_hud.show_prompt("dummy", "Tập kích", "Bù Nhìn Tập Luyện", "🎯")
				"BlacksmithForge":
					interaction_hud.show_prompt("forge", "Sử dụng", "Đe Rèn Tiền Đồn", "🔥")
				"VillageHearth":
					interaction_hud.show_prompt("hearth", "Nấu nướng", "Bếp Lửa Dã Ngoại", "🍲")
				"HavenSign":
					interaction_hud.show_prompt("sign", "Xem chỉ dẫn", "Biển Chỉ Dẫn Haven", "📜")
				"Buster":
					interaction_hud.show_prompt("buster", "Vuốt ve", "Chó Săn Buster", "🐶")
				"Mimi":
					interaction_hud.show_prompt("mimi", "Vuốt ve", "Mèo Mimi Lười Biếng", "🐱")
				_:
					interaction_hud.show_prompt("village", "Tương tác", v_id, "💬")
			return

	# 5. Foraging nodes
	if foraging_nodes:
		var f_i: Dictionary = foraging_nodes.get_nearby_forageable(p_pos)
		if not f_i.is_empty():
			interaction_hud.show_prompt(f_i["id"], "Thu thập", f_i["item_name"], f_i["icon"])
			return

	# 6. Ancient Teleport Waypoint Network
	if waypoint_network:
		var wp_i: Dictionary = waypoint_network.get_nearby_interactable(p_pos)
		if not wp_i.is_empty():
			var wp_title: String = wp_i.get("name", "Điểm Dịch Chuyển")
			if wp_i.get("unlocked", false):
				interaction_hud.show_prompt(wp_i["id"], "Mở bản đồ", "Điểm Dịch Chuyển: " + wp_title, "✨")
			else:
				interaction_hud.show_prompt(wp_i["id"], "Kích hoạt", "Điểm Dịch Chuyển: " + wp_title, "🔴")
			return

	# 7. Exploration Treasure Chests
	if chest_system and chest_system.has_method("get_nearest_unopened_chest"):
		var near_cid: String = chest_system.get_nearest_unopened_chest(p_pos, 3.5)
		if not near_cid.is_empty():
			var c_dict = chest_system.get("_chests")
			var c_name: String = "Rương Báu Thám Hiểm"
			if c_dict is Dictionary and c_dict.has(near_cid):
				c_name = c_dict[near_cid].get("name", c_name)
			interaction_hud.show_prompt(near_cid, "Mở rương", c_name, "📦")
			return

	# 8. Highland Sheep Petting
	for s in sheep_flock:
		if is_instance_valid(s) and s.is_inside_tree():
			if s.global_position.distance_to(p_pos) < 3.0:
				interaction_hud.show_prompt("highland_sheep", "Vuốt ve", "Cừu Cao Nguyên Fluffy", "🐑")
				return

	# 9. Anemo Elemental Monument
	if chest_system:
		var mon = chest_system.get_node_or_null("AnemoElementalMonument")
		if mon:
			var m_pos: Vector3 = mon.global_position if mon.is_inside_tree() else mon.position
			if p_pos.distance_to(m_pos) < 5.0:
				interaction_hud.show_prompt("anemo_monument", "Tấn công kích hoạt", "Trụ Nguyên Tố Phong", "🌀")
				return

	# 9b. Luminescent Night Flora (Star Lotus / Spore Mushroom)
	if luminescent_flora and luminescent_flora.has_method("get_nearby_forageable"):
		var fl_i: Dictionary = luminescent_flora.get_nearby_forageable(p_pos)
		if not fl_i.is_empty():
			var act_verb: String = "Hái Sen Tinh Tú" if fl_i.get("type", "") == "star_lotus" else "Thu hái nấm"
			interaction_hud.show_prompt(fl_i["id"], act_verb, fl_i["name"], fl_i["icon"])
			return

	# 9c. Anemo Crystalfly Catch
	if crystalfly_swarm and crystalfly_swarm.has_method("get_nearby_crystalfly"):
		var cf_i: Dictionary = crystalfly_swarm.get_nearby_crystalfly(p_pos)
		if not cf_i.is_empty():
			interaction_hud.show_prompt(cf_i["id"], "Bắt", cf_i["name"], cf_i["icon"])
			return

	# 9d. Wandering Seelie Chest
	if wandering_seelie and wandering_seelie.has_method("get_nearby_interactable"):
		var se_i: Dictionary = wandering_seelie.get_nearby_interactable(p_pos)
		if not se_i.is_empty():
			interaction_hud.show_prompt(se_i["id"], "Mở rương", se_i["name"], se_i["icon"])
			return

	# 9e. Ancient Anemo Statue & Gliding Time Trial
	if anemo_statue and anemo_statue.has_method("get_nearby_interactable"):
		var as_i: Dictionary = anemo_statue.get_nearby_interactable(p_pos)
		if not as_i.is_empty():
			var act_str: String = "Kích hoạt" if as_i.get("id", "").begins_with("anemo_time_trial") else "Cầu nguyện"
			interaction_hud.show_prompt(as_i["id"], act_str, as_i["name"], as_i["icon"])
			return

	# 9f. Wilderness Campfire
	if wilderness_camp and wilderness_camp.has_method("get_nearby_interactable"):
		var cmp_i: Dictionary = wilderness_camp.get_nearby_interactable(p_pos)
		if not cmp_i.is_empty():
			interaction_hud.show_prompt(cmp_i["id"], "Nghỉ ngơi", cmp_i["name"], cmp_i["icon"])
			return

	# 9g. Wild Raspberry Bush
	if ground_dressing and ground_dressing.has_method("get_nearby_forageable"):
		var rb_i: Dictionary = ground_dressing.get_nearby_forageable(p_pos)
		if not rb_i.is_empty():
			interaction_hud.show_prompt(rb_i["id"], "Thu hái", rb_i["name"], rb_i["icon"])
			return

	# 9h. Shrine of Depths (Đền Ngàn Đời Cổ Đại)
	if shrine_of_depths and shrine_of_depths.has_method("get_nearby_interactable"):
		var sh_i: Dictionary = shrine_of_depths.get_nearby_interactable(p_pos)
		if not sh_i.is_empty():
			var act_lbl: String = "Mở khóa đền" if sh_i["id"] == "shrine_barrier" else "Mở rương"
			interaction_hud.show_prompt(sh_i["id"], act_lbl, sh_i["name"], sh_i["icon"])
			return

	# 9i. Elemental Pyro Torch Puzzle (Đài Hỏa Viêm)
	if torch_puzzle and torch_puzzle.has_method("get_nearby_interactable"):
		var tp_i: Dictionary = torch_puzzle.get_nearby_interactable(p_pos)
		if not tp_i.is_empty():
			var act_lbl: String = "Thắp đuốc" if tp_i["id"].begins_with("torch_") else "Mở rương"
			interaction_hud.show_prompt(tp_i["id"], act_lbl, tp_i["name"], tp_i["icon"])
			return

	# 9j. Hunter Eagle Eye Clue
	if hunter_eagle_eye and hunter_eagle_eye.has_method("get_nearest_clue"):
		var clue: Dictionary = hunter_eagle_eye.get_nearest_clue(p_pos)
		if not clue.is_empty() and not clue.get("is_inspected", false):
			interaction_hud.show_prompt(clue["id"], "Khảo sát", clue["title"], "🐾")
			return

	# 9k. Anemo Wind Geyser
	if anemo_geyser and anemo_geyser.is_sealed:
		if p_pos.distance_to(anemo_geyser.global_position) <= anemo_geyser.vent_radius + 1.2:
			interaction_hud.show_prompt("anemo_geyser", "Khai thông", "Mạch Phong Cổ Đại (Đá %d/3)" % anemo_geyser.seal_health, "⛏️")
			return

	# 9l. Ancient Stele Inscription
	if ancient_stele and not ancient_stele.is_read:
		if p_pos.distance_to(ancient_stele.global_position) <= 3.5:
			interaction_hud.show_prompt("ancient_stele", "Khảo cứu", "Bia Cổ Ngữ Ngàn Đời", "📜")
			return

	# 9ll. Skyspire Apex Ancient Anemo Spire Beacon Altar (114m)
	if skyspire_beacon and skyspire_beacon.has_method("can_interact") and skyspire_beacon.can_interact(p_pos):
		if not skyspire_beacon.is_activated:
			interaction_hud.show_prompt("skyspire_beacon", "Khởi Động Cổ Đài Phong Ngân (114m)", "Đỉnh Trời Skyspire", "👑")
			return

	# 9m. Aerial Ring Trial Dial
	if aerial_trial and not aerial_trial.is_trial_active:
		if aerial_trial.is_player_near_dial(p_pos):
			interaction_hud.show_prompt("aerial_trial_dial", "Bắt đầu", "Thử Luyện Lướt Gió Thời Gian", "⏱️")
			return

	# 9n. Aerial Ring Trial Precious Chest
	if aerial_trial and aerial_trial.is_player_near_chest(p_pos):
		interaction_hud.show_prompt("aerial_trial_chest", "Mở rương", "Rương Quý Giá Đỉnh Trời", "🎁")
		return

	# 9o. Legendary Mythic White Stag Communion
	if mythic_stag and mythic_stag.is_player_near(p_pos):
		interaction_hud.show_prompt("mythic_stag_commune", "Kính cẩn thuần hóa", "Bạch Hươu Thần Thoại", "🦌")
		return

	# 9p. Hydro Lake Sanctuary Runic Seals
	if hydro_puzzle:
		var near_seal: int = hydro_puzzle.get_nearest_inactive_seal(p_pos)
		if near_seal != -1:
			interaction_hud.show_prompt("hydro_seal_%d" % near_seal, "Kích hoạt", "Ấn Thủy Thần #%d" % (near_seal + 1), "🌊")
			return

	# 9q. Luxurious Island Chest on Floating Islet
	if hydro_puzzle and not hydro_puzzle.is_chest_opened and hydro_puzzle.is_player_near_chest(p_pos):
		interaction_hud.show_prompt("luxurious_hydro_chest", "Mở rương", "Rương Thủy Thần Siêu Cấp", "🎁")
		return

	# 9r. Legendary Grizzly Patriarch Close-up Photography
	if grizzly_patriarch and grizzly_patriarch.is_player_near(p_pos):
		interaction_hud.show_prompt("grizzly_patriarch_photo", "Chụp ảnh cận cảnh", "Bá Vương Hùng Đỉnh Băng", "📷")
		return

	# 9s. Mountable Prairie Steed (Thú Cưỡi Thảo Nguyên)
	var walker_ref: FirstPersonWalker = camera.get_walker() if camera else null
	if walker_ref and walker_ref.is_mounted():
		interaction_hud.show_prompt("dismount_steed", "[F] / [C] Xuống", "Hươu Thảo Nguyên", "🐎")
		return
	elif prairie_steed and p_pos.distance_to(prairie_steed.global_position) <= 3.8:
		interaction_hud.show_prompt("mount_steed", "[F] Cưỡi Thú", "Hươu Thảo Nguyên", "🦌")
		return

	# 9t. Submerged Sea Cavern Passage & Secret Reliquary
	if sea_cavern and sea_cavern.has_method("get_interaction_prompt"):
		var cav_i: Dictionary = sea_cavern.get_interaction_prompt(p_pos)
		if not cav_i.is_empty():
			var cav_act: String = "Đi vào" if "enter" in cav_i.get("action", "") else "Mở rương"
			var cav_title: String = "Hang Biển Ngầm" if "enter" in cav_i.get("action", "") else "Rương Bí Mật Đáy Hang"
			var cav_icon: String = "🌊" if "enter" in cav_i.get("action", "") else "👑"
			interaction_hud.show_prompt("sea_cavern", cav_act, cav_title, cav_icon)
			return

	# 9u. Selfie Camera Active Mode
	if walker_ref and walker_ref.is_selfie_mode:
		interaction_hud.show_prompt("selfie_snap", "[Click] / [E] Chụp Ảnh | [1-5] Biểu Cảm", "Góc Nhìn Selfie [F3]", "📸")
		return

	# No interactable nearby
	interaction_hud.hide_prompt()

func _on_waypoint_activated(wp_id: String, _display_name: String) -> void:
	if expedition:
		expedition.register_landmark_discovery(wp_id)
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "unlock_waypoint"})
	if ui_audio:
		ui_audio.play_milestone()

func _on_waypoint_teleport_requested(target_wp_id: String) -> void:
	var walker: FirstPersonWalker = camera.get_walker() if camera else null
	if walker and waypoint_network:
		waypoint_network.teleport_player(walker, target_wp_id)
		if camera:
			camera.position = walker.position
		if ui_audio:
			ui_audio.play_discovery()
		print("[Main] Teleported to waypoint: %s" % target_wp_id)

func _on_exploration_chest_opened(chest_id: String, reward: Dictionary) -> void:
	if expedition:
		expedition.register_landmark_discovery("chest_" + chest_id)
		expedition.add_expedition_points(reward.get("exp", 100))
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "open_exploration_chest"})
	if alchemy_system:
		alchemy_system.add_coins(reward.get("coins", 50))
		if reward.has("item"):
			alchemy_system.add_ingredient(reward["item"], 1)
	if interaction_hud:
		var c_coins: int = reward.get("coins", 50)
		var c_exp: int = reward.get("exp", 100)
		interaction_hud.show_pickup_toast("Rương Báu Mở! (+%d Hải Tệ, +%d EXP)" % [c_coins, c_exp], 1, "📦")
	print("[Main] Opened exploration chest: %s -> %s" % [chest_id, str(reward)])

func _on_anemo_monument_activated(monument_id: String) -> void:
	if expedition:
		expedition.register_landmark_discovery(monument_id)
		expedition.add_expedition_points(150)
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Anemo Elemental Monument activated: %s" % monument_id)

func _on_flight_ring_passed(ring_index: int, total_passed: int) -> void:
	if anemo_statue and anemo_statue.has_method("register_ring_hit"):
		anemo_statue.register_ring_hit(ring_index, total_passed)
	if expedition:
		expedition.add_expedition_points(45)
		expedition.check_quest_progress("FLIGHT_RING", {"index": ring_index, "total": total_passed})
	if interaction_hud:
		interaction_hud.show_pickup_toast("Vòng Phong Tốc #%d (+45 EXP)" % (ring_index + 1), 1, "🌀")
	if ui_audio:
		ui_audio.play_item_pickup()

func _on_flora_harvested(_flora_type: String, item_id: String, _pos: Vector3) -> void:
	if alchemy_system:
		alchemy_system.add_ingredient(item_id, 1)
	if ui_audio:
		ui_audio.play_item_pickup()
	if interaction_hud:
		var d_name: String = "Hoa Sen Tinh Tú" if item_id == "star_lotus" else "Nấm Dạ Quang"
		var icon: String = "🪷" if item_id == "star_lotus" else "🍄"
		interaction_hud.show_pickup_toast(d_name, 1, icon)
	if expedition:
		var exp_gain: int = 25 if item_id == "star_lotus" else 20
		expedition.add_expedition_points(exp_gain)
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "forage_wild_herbs"})

func _on_crystalfly_caught(_fly_id: String, item_id: String, _pos: Vector3) -> void:
	if alchemy_system:
		alchemy_system.add_ingredient(item_id, 1)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Bắt Tinh Điệp Phong (+30 EXP, +1 Tinh Nhân)", 1, "🦋")
	if expedition:
		expedition.add_expedition_points(30)
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "catch_crystalfly"})

func _on_seelie_reached_court(pos: Vector3) -> void:
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	if interaction_hud:
		interaction_hud.show_pickup_toast("Tiên Linh Trở Về Bệ Thần! Rương Báu Đã Xuất Hiện", 1, "✨")
	if expedition:
		expedition.add_expedition_points(120)
		expedition.register_landmark_discovery("seelie_court_" + str(int(pos.x)))

func _on_seelie_chest_opened(reward: Dictionary) -> void:
	if alchemy_system:
		alchemy_system.add_coins(reward.get("coins", 65))
		if reward.has("item"):
			alchemy_system.add_ingredient(reward["item"], 1)
	if ui_audio:
		ui_audio.play_landmark_chime()
	if interaction_hud:
		interaction_hud.show_pickup_toast("Mở Rương Tiên Linh! (+%d Hải Tệ, +%d EXP)" % [reward.get("coins", 65), reward.get("exp", 180)], 1, "🎁")
	if expedition:
		expedition.add_expedition_points(reward.get("exp", 180))

func _on_statue_prayed(_player: Node3D, blessing: Dictionary) -> void:
	if interaction_hud:
		interaction_hud.show_pickup_toast(blessing.get("message", "Nhận Phước Lành Thần Gió"), 1, "✨")
	if expedition:
		expedition.add_expedition_points(blessing.get("exp", 200))
		expedition.register_landmark_discovery("ancient_anemo_statue")

func _on_time_trial_started(duration: float) -> void:
	if ui_audio:
		ui_audio.play_quest_accepted()
	if interaction_hud:
		interaction_hud.show_pickup_toast("Bắt Đầu Khiêu Chiến Lượn Gió! Thời gian: %.0fs" % duration, 1, "⏱️")

func _on_time_trial_completed(time_taken: float, reward: Dictionary) -> void:
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	if alchemy_system:
		alchemy_system.add_coins(reward.get("coins", 100))
	if interaction_hud:
		interaction_hud.show_pickup_toast("Hoàn Thành Khiêu Chiến trong %.1fs! (+%d EXP, +%d Hải Tệ)" % [time_taken, reward.get("exp", 300), reward.get("coins", 100)], 1, "🏆")
	if expedition:
		expedition.add_expedition_points(reward.get("exp", 300))
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "gliding_time_trial"})

func _on_time_trial_failed() -> void:
	if ui_audio:
		ui_audio.play_button_click()
	if interaction_hud:
		interaction_hud.show_pickup_toast("Khiêu Chiến Thất Bại! Đã hết thời gian", 1, "❌")

func _on_berry_foraged(_bush_id: String, item_id: String, _pos: Vector3) -> void:
	if alchemy_system:
		alchemy_system.add_ingredient(item_id, 1)
	if ui_audio:
		ui_audio.play_item_pickup()
	if interaction_hud:
		interaction_hud.show_pickup_toast("Thu hoạch Mâm Xôi Rừng (+15 EXP)", 1, "🫐")
	if expedition:
		expedition.add_expedition_points(15)
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "forage_wild_herbs"})

func _on_animal_spotted(species_id: String, animal_name: String, pos: Vector3) -> void:
	if expedition:
		expedition.register_species_cataloged(species_id)
		expedition.add_expedition_points(40)
	if interaction_hud:
		var icon: String = "🦊" if species_id.begins_with("fox") else "🐿️"
		interaction_hud.show_pickup_toast("Phát Hiện: " + animal_name + " (+40 EXP)", 1, icon)
	if ui_audio:
		ui_audio.play_item_pickup()
	print("[Main] Wildlife spotted: %s (%s) at %s" % [animal_name, species_id, str(pos)])

func _on_dish_cooked(dish_id: String, dish_name: String, buff: String) -> void:
	if expedition:
		expedition.add_expedition_points(80)
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "cook_campfire_dish"})
	if interaction_hud:
		interaction_hud.show_pickup_toast("Nấu thành công: %s (%s)" % [dish_name, buff], 1, "🍲")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Dish cooked: %s (%s)" % [dish_name, dish_id])

func _on_shrine_unlocked(shrine_pos: Vector3) -> void:
	if expedition:
		expedition.register_landmark_discovery("shrine_of_depths")
		expedition.add_expedition_points(250)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Phá Vỡ Phong Ấn: Đền Ngàn Đời Cổ Đại! (+250 EXP)", 1, "⛩️")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Shrine of Depths barrier unlocked at %s" % str(shrine_pos))

func _on_luxurious_chest_opened(reward: Dictionary) -> void:
	if expedition:
		expedition.add_expedition_points(reward.get("exp", 500))
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "open_luxurious_chest"})
	if alchemy_system:
		alchemy_system.add_coins(reward.get("coins", 200))
		if reward.has("artifact"):
			alchemy_system.add_ingredient(reward["artifact"], 1)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Mở Rương Thần Điện! (+%d Hải Tệ, +%d EXP, %s)" % [
			reward.get("coins", 200), reward.get("exp", 500), reward.get("artifact_title", "")
		], 1, "👑")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Opened Luxurious Shrine Chest -> Reward: %s" % str(reward))

func _on_skyspire_beacon_activated(pos: Vector3, reward_xp: int) -> void:
	if expedition:
		expedition.register_landmark_discovery("skyspire_beacon")
		expedition.check_quest_progress("BEACON_ACTIVATED", {"id": "skyspire_beacon", "position": pos})
		expedition.add_expedition_points(reward_xp)
	if interaction_hud:
		interaction_hud.show_pickup_toast("✨ Cổ Đài Phong Ngân Đã Khởi Động (+1000 EXP)! Hoàn Thành Chuỗi Thám Hiểm Đỉnh Skyspire (114m)!", 1, "👑")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Skyspire Beacon Altar awakened on 114m summit! Updraft vent active.")

func _on_torch_lit(index: int, total_lit: int) -> void:
	if interaction_hud:
		interaction_hud.show_pickup_toast("Thắp Đuốc #%d (%d/4 Đuốc Đang Cháy)" % [index + 1, total_lit], 1, "🔥")
	if ui_audio:
		ui_audio.play_item_pickup()
	print("[Main] Torch %d lit. Total lit: %d/4" % [index, total_lit])

func _on_puzzle_solved(pos: Vector3) -> void:
	if expedition:
		expedition.register_landmark_discovery("elemental_torch_puzzle")
		expedition.add_expedition_points(150)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Giải Mã Thành Công: Đài Hỏa Viêm Cổ Đại! (+150 EXP)", 1, "✨")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Elemental Torch Puzzle solved at %s" % str(pos))

func _on_puzzle_chest_opened(reward: Dictionary) -> void:
	if expedition:
		expedition.add_expedition_points(reward.get("exp", 220))
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "solve_torch_puzzle"})
	if alchemy_system:
		alchemy_system.add_coins(reward.get("coins", 75))
		if reward.has("item"):
			alchemy_system.add_ingredient(reward["item"], 1)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Mở Rương Hỏa Viêm! (+%d Hải Tệ, +%d EXP)" % [
			reward.get("coins", 75), reward.get("exp", 220)
		], 1, "🎁")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Opened Puzzle Exquisite Chest -> Reward: %s" % str(reward))

func _on_track_clue_inspected(clue_id: String, animal_species: String, clue_title: String, clue_pos: Vector3) -> void:
	if expedition:
		expedition.add_expedition_points(30)
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "inspect_animal_tracks"})
	if interaction_hud:
		interaction_hud.show_pickup_toast("Khảo Sát Dấu Vết: %s (+30 EXP)" % clue_title, 1, "🐾")
	if ui_audio:
		ui_audio.play_item_pickup()
	print("[Main] Track clue inspected: %s (%s) at %s" % [clue_title, animal_species, str(clue_pos)])

func _on_geyser_unsealed(geyser_pos: Vector3) -> void:
	if expedition:
		expedition.register_landmark_discovery("anemo_wind_geyser")
		expedition.add_expedition_points(250)
	if alchemy_system:
		alchemy_system.add_coins(80)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Khai Thông Mạch Phong Cổ Đại! (+250 EXP, +80 Hải Tệ)", 1, "🌪️")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Anemo Wind Geyser unsealed at %s" % str(geyser_pos))

func _on_geyser_propelled(character: Node3D, surge_velocity: float) -> void:
	if interaction_hud:
		interaction_hud.show_pickup_toast("Bay Vút Cùng Cuồng Phong! (+22.0 m/s)", 1, "🪂")
	print("[Main] Character propelled by Anemo Wind Geyser with velocity: %.1f m/s" % surge_velocity)

func _on_stele_read(title: String, inscription_text: String, reward: Dictionary) -> void:
	if expedition:
		expedition.register_landmark_discovery("ancient_stele_inscription")
		expedition.add_expedition_points(reward.get("exp", 150))
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "read_ancient_stele"})
	if alchemy_system:
		alchemy_system.add_coins(reward.get("coins", 60))
	if interaction_hud:
		interaction_hud.show_pickup_toast("Giải Mã: %s (+%d EXP, Danh hiệu: %s)" % [
			title, reward.get("exp", 150), reward.get("title", "")
		], 1, "📜")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Ancient stele read: %s" % title)

func _on_stag_spotted(stag_pos: Vector3) -> void:
	if expedition:
		expedition.register_species_cataloged("mythic_white_stag")
		expedition.add_expedition_points(80)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Phát Hiện Thần Thú: Bạch Hươu Tinh Linh (+80 EXP)", 1, "🦌")
	if ui_audio:
		ui_audio.play_landmark_chime()
	print("[Main] Mythic White Stag spotted at %s" % str(stag_pos))

func _on_stag_communed(reward: Dictionary) -> void:
	if expedition:
		expedition.add_expedition_points(reward.get("exp", 300))
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "commune_mythic_stag"})
	if alchemy_system:
		alchemy_system.add_coins(reward.get("coins", 100))
		alchemy_system.add_ingredient(reward.get("item", "mythic_star_antler"), 1)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Nhận Được: %s (+%d EXP, +%d Hải Tệ)" % [
			reward.get("buff_title", "Phúc Lành Bạch Hươu"), reward.get("exp", 300), reward.get("coins", 100)
		], 1, "🦌")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Sacred Communion with Mythic White Stag complete!")

func _on_trial_started() -> void:
	if interaction_hud:
		interaction_hud.show_pickup_toast("Bắt Đầu Thử Luyện: Chân Trời Cuồng Phong! (35s)", 1, "⏱️")
	if ui_audio:
		ui_audio.play_landmark_chime()
	print("[Main] Aerial Ring Time-Trial started!")

func _on_ring_cleared(ring_idx: int, total_cleared: int) -> void:
	if interaction_hud:
		interaction_hud.show_pickup_toast("Vòng Gió %d/5! (+Tốc Độ Lướt Gió)" % total_cleared, 1, "🌀")
	print("[Main] Aerial ring %d cleared! Total: %d/5" % [ring_idx + 1, total_cleared])

func _on_trial_completed(reward: Dictionary) -> void:
	if expedition:
		expedition.add_expedition_points(reward.get("exp", 280))
		expedition.register_landmark_discovery("aerial_ring_trial")
	if alchemy_system:
		alchemy_system.add_coins(reward.get("coins", 90))
	if interaction_hud:
		interaction_hud.show_pickup_toast("Hoàn Thành Thử Luyện! Rương Quý Giá Đã Xuất Hiện!", 1, "🏆")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Aerial Ring Time-Trial completed!")

func _on_trial_failed() -> void:
	if interaction_hud:
		interaction_hud.show_pickup_toast("Hết Thời Gian Thử Luyện! Hãy Thử Lại.", 1, "⌛")
	print("[Main] Aerial Ring Time-Trial failed or reset.")

func _on_trial_chest_opened(reward: Dictionary) -> void:
	if expedition:
		expedition.add_expedition_points(reward.get("exp", 280))
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "aerial_trial_chest"})
	if alchemy_system:
		alchemy_system.add_coins(reward.get("coins", 90))
		alchemy_system.add_ingredient(reward.get("item", "anemo_soaring_crest"), 1)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Mở Rương Quý Giá: %s (+%d EXP, +%d Hải Tệ)" % [
			reward.get("item_title", "Huy Hiệu Phong Thần"), reward.get("exp", 280), reward.get("coins", 90)
		], 1, "🎁")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Precious Aerial Chest opened!")

func _on_bear_spotted(bear_pos: Vector3) -> void:
	if expedition:
		expedition.register_species_cataloged("legendary_grizzly_patriarch")
		expedition.add_expedition_points(100)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Phát Hiện Dã Thú: Bá Vương Hùng (+100 EXP)", 1, "🐻")
	if ui_audio:
		ui_audio.play_landmark_chime()
	print("[Main] Legendary Grizzly Patriarch spotted at %s" % str(bear_pos))

func _on_bear_photo_taken(reward: Dictionary) -> void:
	if expedition:
		expedition.add_expedition_points(reward.get("exp", 350))
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "photo_grizzly_patriarch"})
	if alchemy_system:
		alchemy_system.add_coins(reward.get("coins", 120))
		alchemy_system.add_ingredient(reward.get("item", "grizzly_silver_claw"), 1)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Chụp Thành Công: %s (+%d EXP, +%d Hải Tệ)" % [
			reward.get("title", "Khoảnh Khắc Dã Sinh"), reward.get("exp", 350), reward.get("coins", 120)
		], 1, "📷")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Legendary Grizzly Patriarch close-up photo taken!")

func _on_bear_roar_emitted(roar_pos: Vector3) -> void:
	print("[Main] Bear roar resonated at %s" % str(roar_pos))

func _on_hydro_seal_activated(seal_idx: int, total_active: int) -> void:
	if interaction_hud:
		interaction_hud.show_pickup_toast("Kích Hoạt Ấn Thủy Thần #%d (%d/3)" % [seal_idx + 1, total_active], 1, "🌊")
	if ui_audio:
		ui_audio.play_landmark_chime()
	print("[Main] Hydro seal %d activated! (%d/3)" % [seal_idx + 1, total_active])

func _on_hydro_spout_erupted(spout_pos: Vector3) -> void:
	if expedition:
		expedition.register_landmark_discovery("hydro_lake_sanctuary")
		expedition.add_expedition_points(150)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Cột Nước Thủy Thần Bùng Nổ! (+150 EXP)", 1, "🌊")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Hydro water spout erupted at %s" % str(spout_pos))

func _on_hydro_player_launched(launch_velocity: Vector3) -> void:
	if interaction_hud:
		interaction_hud.show_pickup_toast("Cột Nước Cuồng Triều Phóng Lên Trời (+26.5 m/s)!", 1, "🌊")
	print("[Main] Player launched by hydro spout: %s" % str(launch_velocity))

func _on_hydro_island_chest_opened(reward: Dictionary) -> void:
	if expedition:
		expedition.add_expedition_points(reward.get("exp", 500))
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "luxurious_hydro_chest"})
	if alchemy_system:
		alchemy_system.add_coins(reward.get("coins", 200))
		alchemy_system.add_ingredient(reward.get("item", "hydro_heart_pearl"), 1)
	if interaction_hud:
		interaction_hud.show_pickup_toast("Mở Rương Thủy Thần Siêu Cấp: %s (+%d EXP, +%d Hải Tệ)" % [
			reward.get("item_title", "Ngọc Trái Tim Thủy Thần"), reward.get("exp", 500), reward.get("coins", 200)
		], 1, "🎁")
	if ui_audio:
		ui_audio.play_milestone_fanfare()
	print("[Main] Luxurious Island Chest opened!")

func _on_steed_player_mounted(_steed: Node3D) -> void:
	if ui_audio:
		ui_audio.play_item_pickup()
	if expedition:
		expedition.add_expedition_points(100)
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "mount_prairie_steed"})
	print("[Main] Player mounted Prairie Steed.")

func _on_steed_player_dismounted(_steed: Node3D) -> void:
	print("[Main] Player dismounted Prairie Steed.")

func _on_sea_cavern_entered(entrance_name: String) -> void:
	if expedition:
		expedition.register_landmark_discovery("submerged_sea_cavern")
		expedition.add_expedition_points(120)
	print("[Main] Player entered Submerged Sea Cavern from %s" % entrance_name)

func _on_cavern_chest_unlocked(reward: Dictionary) -> void:
	if alchemy_system:
		alchemy_system.add_ingredient("ancient_royal_seal", 1)
		alchemy_system.add_coins(reward.get("coins", 200))
	if expedition:
		expedition.add_expedition_points(reward.get("exp", 450))
		expedition.check_quest_progress("VILLAGE_ACTION", {"action_id": "salvage_sunken_chest"})
	print("[Main] Cavern reliquary chest unlocked!")
