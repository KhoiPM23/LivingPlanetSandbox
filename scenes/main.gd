class_name Main
extends Node3D

## Primary entry point scene connecting WorldBootstrap, IslandTerrain, EnvironmentalGrid, Atmosphere, and HUD.

const AtmosphereDirector = preload("res://presentation/environment/atmosphere_director.gd")
const SpatialAudioDirector = preload("res://presentation/audio/spatial_audio_director.gd")

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

func _ready() -> void:
	print("[Main] Initializing Living Planet Sandbox Procedural World & Environment Systems...")
	var seed_val: int = bootstrap.world_seed.master_seed if (bootstrap and bootstrap.world_seed) else 1337
	var config: WorldGenerationConfig = bootstrap.world_config if bootstrap else null
	var grid: EnvironmentalGrid = bootstrap.environmental_grid if bootstrap else null
	var weather: WeatherSystem = bootstrap.weather_system if bootstrap else null

	# 1. Generate Procedural Island Terrain bound to EnvironmentalGrid
	if terrain:
		terrain.generate_island(config if config != null else seed_val, grid)
		print("[Main] Procedural island generated (size: %.0fm, max height: %.1fm)." % [terrain.island_size, terrain.max_height])
		if grid:
			print("[Main] Environmental grid initialized: %d cells (size: %.1fm)." % [grid.get_cell_count(), grid._cell_size])

	# 2. Setup Day/Night celestial cycle and Weather link
	if day_night and bootstrap:
		day_night.setup(bootstrap.world_clock, sun, env, weather)
		print("[Main] Day/Night cycle bound to WorldClock and WeatherSystem.")

	# 3. Scatter flora, boulders, summit landmark, and instanced grass filtered by Biomes
	if scatter and terrain:
		scatter.scatter(terrain, seed_val, bootstrap.entity_registry, grid, config)
		var entity_count: int = bootstrap.entity_registry.get_count() if (bootstrap and bootstrap.entity_registry) else 0
		print("[Main] Biome props & foliage scattered. Tracked entities: %d" % entity_count)

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
		audio_dir.setup(bootstrap.world_clock, weather, camera)
		print("[Main] Procedural spatial audio initialized: wind gusts, lake shore ripples, bird calls & night crickets.")

	# 4. Initialize Causal Ecosystem Simulation & Presentation
	var eco_presentation: EcosystemPresentation = null
	if bootstrap and bootstrap.ecosystem_coordinator and terrain:
		bootstrap.ecosystem_coordinator.bind_terrain_height(Callable(terrain, "get_height_at"))
		bootstrap.ecosystem_coordinator.populate_initial_ecosystem(55, 14, 2)

		eco_presentation = EcosystemPresentation.new()
		eco_presentation.name = "EcosystemPresentation"
		add_child(eco_presentation)
		eco_presentation.setup(bootstrap.ecosystem_coordinator)
		print("[Main] Causal ecosystem simulation initialized: %d plants, %d herbivores, %d predators." % [
			bootstrap.ecosystem_coordinator.flora_sim.get_plant_count(),
			bootstrap.ecosystem_coordinator.fauna_sim.get_herbivore_count(),
			bootstrap.ecosystem_coordinator.fauna_sim.get_predator_count()
		])

	# 5. Position camera overlooking the island from a scenic vantage point
	if camera:
		camera.position = Vector3(14.0, 10.5, 22.0)
		camera.look_at_target(Vector3(-16.0, 9.0, -14.0))
		print("[Main] Camera positioned at scenic overview: %s" % str(camera.position))

	# 6. Initialize Player Experiment Tool Controller & HUD
	var tool_controller: PlayerToolController = PlayerToolController.new()
	tool_controller.name = "PlayerToolController"
	add_child(tool_controller)
	tool_controller.setup(camera, bootstrap, terrain)

	if hud:
		hud.setup_controllers(bootstrap, tool_controller, camera)
		print("[Main] Player experiment tools & observability HUD initialized.")

	# 7. Apply persistent Graphics Quality Preset (Default: BALANCED for Intel Iris Xe)
	var active_preset: GraphicsPresets.Preset = GraphicsPresets.load_from_config()
	GraphicsPresets.apply_preset(active_preset, self)
	print("[Main] Applied graphics preset: %s" % GraphicsPresets.get_preset_name(active_preset))

func _process(_delta: float) -> void:
	if bootstrap and bootstrap.ecosystem_coordinator and camera:
		var cam_pos: Vector3 = camera.global_position if camera.is_inside_tree() else camera.position
		var is_character: bool = (camera.current_mode == FreeLookCamera.CameraMode.FIRST_PERSON_WALKER or camera.current_mode == FreeLookCamera.CameraMode.THIRD_PERSON_CHARACTER)
		var is_grounded: bool = is_character or (cam_pos.y < 12.0)
		var presence_pos: Vector3 = cam_pos
		if is_character and camera.get_walker():
			var walker: FirstPersonWalker = camera.get_walker()
			presence_pos = walker.global_position if walker.is_inside_tree() else walker.position
		bootstrap.ecosystem_coordinator.set_player_presence(presence_pos, is_grounded)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F12:
			capture_screenshot("res://screenshot_first_playable.png")
		elif event.keycode == KEY_H or event.keycode == KEY_F1:
			if hud:
				hud.visible = not hud.visible
				print("[Main] HUD toggled: %s" % ("Visible" if hud.visible else "Hidden"))

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
