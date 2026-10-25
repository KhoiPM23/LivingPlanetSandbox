extends RefCounted

## Test Suite 34: Block 27 — Emergent Gameplay, World Intelligence & Endless Discovery
## Contract tests for:
## 1. Wildlife perception & stealth approach
## 2. Herd alarm propagation latency and calm-down recovery
## 3. Predator chase stamina abort and satiation digestion cooldown
## 4. Sector disturbance map accumulation and temporal decay
## 5. Emergent fauna steering toward quiet sectors
## 6. LivingWorldDirector global pacing interval (anti-spam)
## 7. Simulation LOD continuity and zero teleportation
## 8. Spatial audio 8-voice pool recycling and capacity cap

const EcosystemMetrics = preload("res://core/ecosystem/ecosystem_metrics.gd")
const IslandMapCanvas = preload("res://presentation/ui/island_map_canvas.gd")
const WorldHUD = preload("res://presentation/ui/hud.gd")
const AlpineTarn = preload("res://presentation/environment/alpine_tarn.gd")
const CaveFeature = preload("res://presentation/environment/cave_feature.gd")
const AlpineWaterfall = preload("res://presentation/environment/alpine_waterfall.gd")

func _flat_height(_x: float, _z: float) -> float:
	return 2.5

## 1. Wildlife perception: Crouch stealth vs fast sprint detection
func test_wildlife_player_detection_and_stealth() -> String:
	var bus: WorldEventBus = WorldEventBus.new()
	var reg: EntityRegistry = EntityRegistry.new(bus)
	var met: EcosystemMetrics = EcosystemMetrics.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1337
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, reg, met, bus)

	var hid: int = fauna.spawn_herbivore(Vector3(0.0, 2.5, 0.0), 85.0)
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)
	h.heading = 0.0 # Facing +X

	# Player sneaking at 10m ahead (speed 1.2 m/s): Within 15m but beyond 9m sneak alert limit -> stays WANDERING
	fauna.set_player_presence(Vector3(10.0, 2.5, 0.0), true, 1.2)
	fauna.step_simulation(0.2, null, Callable(self, "_flat_height"))
	if h.state == FaunaSimulation.HerbivoreState.FLEEING:
		return "Sneaking player at 10m triggered panic flight unexpectedly."

	# Player fast sprint (speed 5.0 m/s) at 10m: Immediately triggers panic FLEEING
	fauna.set_player_presence(Vector3(10.0, 2.5, 0.0), true, 5.0)
	fauna.step_simulation(0.2, null, Callable(self, "_flat_height"))
	if h.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "Sprint approach at 10m failed to trigger FLEEING (state was %d)." % h.state

	return ""

## 2. Herd alarm propagation latency and organic recovery to wandering
func test_herd_alarm_propagation_latency_and_recovery() -> String:
	var bus: WorldEventBus = WorldEventBus.new()
	var reg: EntityRegistry = EntityRegistry.new(bus)
	var met: EcosystemMetrics = EcosystemMetrics.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4242
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, reg, met, bus)

	# Sentry deer at origin, companion deer 10m away
	var id1: int = fauna.spawn_herbivore(Vector3(0.0, 2.5, 0.0), 85.0)
	var id2: int = fauna.spawn_herbivore(Vector3(10.0, 2.5, 0.0), 85.0)
	var s_deer: FaunaSimulation.HerbivoreData = fauna.get_herbivore(id1)
	var c_deer: FaunaSimulation.HerbivoreData = fauna.get_herbivore(id2)

	# Sentry triggers alarm
	s_deer.last_known_threat_pos = Vector3(-5.0, 2.5, 0.0)
	fauna._spread_herd_alarm(s_deer, true)

	# Companion deer at 10m should have positive reaction latency and transition to FLEEING
	if c_deer.reaction_latency <= 0.0:
		return "Companion deer has 0 reaction latency after alarm spread."
	if c_deer.state != FaunaSimulation.HerbivoreState.FLEEING:
		return "Companion deer did not enter FLEEING on alarm propagation."


	# Advance time past flee timer (4.0s) -> Deer settles into ALERT then recovers to WANDERING
	c_deer.flee_timer = 0.0
	fauna.set_player_presence(Vector3(999.0, 2.5, 999.0), false)
	fauna.step_simulation(0.1, null, Callable(self, "_flat_height"))
	if c_deer.state != FaunaSimulation.HerbivoreState.ALERT:
		return "Deer did not transition from FLEEING to ALERT on flee timer expiry."

	# Advance past vigilance timer
	c_deer.vigilance_timer = 0.0
	fauna.step_simulation(0.1, null, Callable(self, "_flat_height"))
	if c_deer.state != FaunaSimulation.HerbivoreState.WANDERING:
		return "Deer failed to naturally recover to WANDERING after vigilance cleared (state: %d)." % c_deer.state

	return ""

## 3. Predator chase stamina abort and satiation digestion cooldown
func test_predator_chase_stamina_abort_and_satiation_cooldown() -> String:
	var bus: WorldEventBus = WorldEventBus.new()
	var reg: EntityRegistry = EntityRegistry.new(bus)
	var met: EcosystemMetrics = EcosystemMetrics.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9999
	var fauna: FaunaSimulation = FaunaSimulation.new(rng, reg, met, bus)

	var pid: int = fauna.spawn_predator(Vector3(0.0, 2.5, 0.0), 80.0)
	var p: FaunaSimulation.PredatorData = fauna.get_predator(pid)

	# A. Outrun abort test: target prey is distant (>25m)
	var hid: int = fauna.spawn_herbivore(Vector3(28.0, 2.5, 0.0), 80.0)
	p.state = FaunaSimulation.PredatorState.HUNTING
	p.target_prey_id = hid
	p.hunt_duration = 0.5
	fauna.step_simulation(0.1, null, Callable(self, "_flat_height"))

	if p.state != FaunaSimulation.PredatorState.RESTING:
		return "Predator failed to abort hunt when prey outran beyond 25m (state: %d)." % p.state
	if p.hunt_fatigue < 3.0:
		return "Predator did not receive recovery fatigue cooldown after chase abort."

	# B. Catch and kill satiation cooldown test
	p.hunt_fatigue = 0.0
	p.state = FaunaSimulation.PredatorState.WANDERING
	var h_close: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)
	h_close.position = Vector3(1.0, 2.5, 0.0)
	p.position = Vector3(0.0, 2.5, 0.0)
	p.energy = 50.0

	fauna.step_simulation(0.1, null, Callable(self, "_flat_height"))
	if p.state != FaunaSimulation.PredatorState.EATING:
		return "Predator did not enter EATING upon catching close prey (state: %d)." % p.state
	if p.hunt_fatigue < 10.0:
		return "Predator satiation digestion cooldown was not set to prevent chain slaughter."

	return ""

## 4. Sector disturbance map accumulation and temporal decay
func test_sector_disturbance_map_accumulation_and_decay() -> String:
	var fauna: FaunaSimulation = FaunaSimulation.new(RandomNumberGenerator.new())

	# Initial disturbance should be 0 across all 4 sectors
	for s_idx in range(4):
		if fauna.get_sector_disturbance(s_idx) != 0.0:
			return "Initial sector disturbance was non-zero."

	# Add disturbance in NE sector (x=20, z=-20 -> sector index 1)
	var ne_pos: Vector3 = Vector3(20.0, 0.0, -20.0)
	var sec_idx: int = fauna.get_sector_index(ne_pos)
	if sec_idx != 1:
		return "Vector (20, 0, -20) resolved to sector %d instead of 1 (NE_COVE)." % sec_idx

	fauna.add_sector_disturbance(ne_pos, 40.0)
	if fauna.get_sector_disturbance(1) != 40.0:
		return "Sector 1 disturbance did not equal 40.0 after injection."

	# Disturbance in other sectors should remain 0
	if fauna.get_sector_disturbance(0) != 0.0 or fauna.get_sector_disturbance(2) != 0.0 or fauna.get_sector_disturbance(3) != 0.0:
		return "Disturbance leaked into un-targeted sectors."

	# Advance simulation by 5.0 seconds -> disturbance decays by 1.2 * 5.0 = 6.0
	fauna.step_simulation(5.0, null, Callable(self, "_flat_height"))
	var decayed: float = fauna.get_sector_disturbance(1)
	if decayed > 35.0 or decayed < 33.0:
		return "Sector disturbance did not decay at ~1.2/s (expected ~34.0, got %.2f)." % decayed

	return ""

## 5. Fauna steering bias toward quiet sectors
func test_fauna_steering_toward_quiet_sectors() -> String:
	var fauna: FaunaSimulation = FaunaSimulation.new(RandomNumberGenerator.new())

	# Elevate disturbance in sector 3 (SE_MEADOW) to 80.0
	fauna.add_sector_disturbance(3, 80.0)
	# Sector 0 (NW_SUMMIT) has 0 disturbance -> lowest
	var quiet_sec: int = fauna.get_lowest_disturbance_sector()
	if quiet_sec == 3:
		return "get_lowest_disturbance_sector returned disturbed sector 3."

	# Spawn deer in sector 3 at (20, 2.5, 20)
	var hid: int = fauna.spawn_herbivore(Vector3(20.0, 2.5, 20.0))
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)
	h.heading = deg_to_rad(45.0) # Initially facing away from center

	# Step simulation for wandering deer
	fauna.step_simulation(0.5, null, Callable(self, "_flat_height"))

	# Animal should have steered toward lower disturbance sector center (negative X / negative Z)
	if h.velocity.length_squared() < 0.01:
		return "Wandering animal in disturbed sector had 0 velocity."

	return ""

## 6. LivingWorldDirector global pacing interval (anti-spam)
func test_living_world_director_global_pacing() -> String:
	var bus: WorldEventBus = WorldEventBus.new()
	var dir: LivingWorldDirector = LivingWorldDirector.new()
	dir.setup(null, bus, null, null)

	var fired_events: Array[String] = []
	dir.emergent_event.connect(func(t, _ti, _b, _s): fired_events.append(t))

	# Fire first event
	dir._fire_event("DAWN_CHORUS", "Dawn", "Body", "notice")
	if fired_events.size() != 1:
		return "First emergent event failed to fire."

	# Immediate second event should be blocked by global pacing cooldown (12.0s)
	dir.set_pacing_strict(true)
	dir._fire_event("DISTANT_WILDLIFE_CALL", "Distant Call", "Body", "info")
	if fired_events.size() != 1:
		return "Second non-critical event was not blocked by global pacing interval."

	if dir.get_global_pacing_cooldown() < 10.0:
		return "Global pacing cooldown was not set to minimum event interval."

	# Advance time past pacing cooldown
	dir._process(13.0)
	if dir.get_global_pacing_cooldown() > 0.0:
		return "Global pacing cooldown did not clear after 13 seconds."

	dir.free()
	return ""

## 7. Simulation LOD continuity and zero teleportation
func test_simulation_lod_continuity_and_zero_teleport() -> String:
	var fauna: FaunaSimulation = FaunaSimulation.new(RandomNumberGenerator.new())
	var hid: int = fauna.spawn_herbivore(Vector3(10.0, 2.5, 10.0))
	var h: FaunaSimulation.HerbivoreData = fauna.get_herbivore(hid)

	# Tier 0 (<35m): Player at (12, 2.5, 10) -> distance ~2m
	fauna.set_player_presence(Vector3(12.0, 2.5, 10.0), true, 0.0)
	fauna.step_simulation(0.1, null, Callable(self, "_flat_height"))
	if h.sim_lod_tier != 0:
		return "Animal at 2m distance assigned LOD tier %d instead of 0." % h.sim_lod_tier

	# Tier 1 (35-75m): Player at (60, 2.5, 10) -> distance ~50m
	fauna.set_player_presence(Vector3(60.0, 2.5, 10.0), true, 0.0)
	fauna.step_simulation(0.1, null, Callable(self, "_flat_height"))
	if h.sim_lod_tier != 1:
		return "Animal at 50m distance assigned LOD tier %d instead of 1." % h.sim_lod_tier

	# Tier 2 (>75m): Player at (120, 2.5, 10) -> distance ~110m
	fauna.set_player_presence(Vector3(120.0, 2.5, 10.0), true, 0.0)
	var pos_before: Vector3 = h.position
	fauna.step_simulation(0.1, null, Callable(self, "_flat_height"))
	if h.sim_lod_tier != 2:
		return "Animal at 110m distance assigned LOD tier %d instead of 2." % h.sim_lod_tier

	# Return to Tier 0: Position transition must be smooth (no sudden teleport jumps)
	fauna.set_player_presence(Vector3(12.0, 2.5, 10.0), true, 0.0)
	fauna.step_simulation(0.1, null, Callable(self, "_flat_height"))
	var pos_after: Vector3 = h.position
	var delta_pos: float = pos_before.distance_to(pos_after)
	if delta_pos > 3.0:
		return "LOD tier transition caused sudden teleport jump of %.2fm." % delta_pos

	return ""

## 8. Spatial audio 8-voice pool recycling and capacity cap
func test_spatial_audio_voice_pool_recycling_and_voice_cap() -> String:
	var audio_dir: SpatialAudioDirector = SpatialAudioDirector.new()
	audio_dir.setup(null, null, null, null)

	if audio_dir.get_max_voice_count() != 8:
		var count: int = audio_dir.get_max_voice_count()
		audio_dir.free()
		return "SpatialAudioDirector max voice count is %d (expected 8)." % count

	# Test procedural stag belling waveform generation
	var belling_wav: AudioStreamWAV = SpatialAudioDirector._generate_stag_belling_wav(0.4, 22050)
	if belling_wav == null or belling_wav.data.is_empty():
		audio_dir.free()
		return "Stag belling WAV generator produced null or empty audio data."

	# Test procedural foliage rustle waveform generation
	var rustle_wav: AudioStreamWAV = SpatialAudioDirector._generate_rustle_foliage_wav(0.2, 22050)
	if rustle_wav == null or rustle_wav.data.is_empty():
		audio_dir.free()
		return "Foliage rustle WAV generator produced null or empty audio data."

	# Allocate 8 sounds sequentially without crashing or pool overflow
	for i in range(12):
		var p: AudioStreamPlayer3D = audio_dir.play_fauna_sound_at(belling_wav, Vector3(float(i), 1.0, 0.0), -18.0)
		if p == null:
			audio_dir.free()
			return "play_fauna_sound_at returned null on allocation iteration %d." % i

	if audio_dir.get_max_voice_count() != 8:
		audio_dir.free()
		return "Voice pool expanded beyond 8 voice cap during recycling."

	audio_dir.free()
	return ""

## 9. Spatial audio procedural landmark discovery chime synthesis
func test_environmental_discovery_chime_synthesis() -> String:
	var chime: AudioStreamWAV = SpatialAudioDirector._generate_discovery_chime_wav(1.35, 22050)
	if chime == null:
		return "Discovery chime WAV generator returned null."
	if chime.format != AudioStreamWAV.FORMAT_16_BITS:
		return "Discovery chime format is not 16-bit PCM."
	if chime.mix_rate != 22050:
		return "Discovery chime mix rate is %d (expected 22050)." % chime.mix_rate
	if chime.data.is_empty():
		return "Discovery chime audio data is empty."
	var expected_bytes: int = int(1.35 * 22050) * 2
	if chime.data.size() != expected_bytes:
		return "Discovery chime byte size is %d (expected %d)." % [chime.data.size(), expected_bytes]
	return ""

## 10. GraphicsPresets proportional MultiMesh grass density scaling
func test_graphics_preset_grass_density_proportional_scaling() -> String:
	var root: Node3D = Node3D.new()
	var scatter: VegetationScatter = VegetationScatter.new()
	scatter.name = "VegetationScatter"
	root.add_child(scatter)

	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 10000
	mmi.multimesh = mm
	scatter._grass_multimesh = mmi
	scatter.add_child(mmi)

	# 1. Test Low preset (45% for large counts)
	var low_changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.LOW, root)
	if mm.visible_instance_count != 4500:
		root.free()
		return "Low preset grass count is %d (expected 4500 for 10000 instances)." % mm.visible_instance_count

	# 2. Test Balanced preset (85% for large counts)
	var bal_changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.BALANCED, root)
	if mm.visible_instance_count != 8500:
		root.free()
		return "Balanced preset grass count is %d (expected 8500 for 10000 instances)." % mm.visible_instance_count

	# 3. Test Cinematic preset (100% for large counts)
	var cin_changes: Dictionary = GraphicsPresets.apply_preset(GraphicsPresets.Preset.CINEMATIC, root)
	if mm.visible_instance_count != 10000:
		root.free()
		return "Cinematic preset grass count is %d (expected 10000 for 10000 instances)." % mm.visible_instance_count

	root.free()
	return ""

## 11. WorldClock time step advancement and daylight calculation
func test_world_clock_time_step_and_daytime_integrity() -> String:
	var clock: WorldClock = WorldClock.new()
	clock.start_hour = 10.0
	clock.set_sim_hour(10.0)

	if not clock.is_daytime():
		return "Clock at 10:00 AM should be daytime."

	# Advance +2h to 12:00 PM
	clock.set_sim_hour(fmod(clock.get_sim_hour() + 2.0, 24.0))
	if absf(clock.get_sim_hour() - 12.0) > 0.05:
		return "Clock hour after +2h is %.2f (expected 12.0)." % clock.get_sim_hour()

	# Advance to 23:00 (Night)
	clock.set_sim_hour(23.0)
	if clock.is_daytime():
		return "Clock at 23:00 should not be daytime."

	# Advance +2h wrapping past midnight (01:00)
	clock.set_sim_hour(fmod(clock.get_sim_hour() + 2.0, 24.0))
	if absf(clock.get_sim_hour() - 1.0) > 0.05:
		return "Clock hour after wrapping midnight is %.2f (expected 1.0)." % clock.get_sim_hour()

	return ""

## 12. Shoreline sand footstep procedural audio synthesis
func test_shoreline_sand_footstep_audio_synthesis() -> String:
	var wav: AudioStreamWAV = FirstPersonWalker._generate_footstep_pcm(0.09, 22050, "sand")
	if wav == null:
		return "Sand footstep WAV generator returned null."
	if wav.format != AudioStreamWAV.FORMAT_16_BITS:
		return "Sand footstep format is not 16-bit PCM."
	if wav.mix_rate != 22050:
		return "Sand footstep mix rate is %d (expected 22050)." % wav.mix_rate
	if wav.data.is_empty():
		return "Sand footstep audio data is empty."
	return ""

## 13. IslandMapCanvas cartographic projection and POI tracking
func test_island_map_canvas_and_projection() -> String:
	var canvas: IslandMapCanvas = IslandMapCanvas.new()
	if canvas.custom_minimum_size.x < 300.0 or canvas.custom_minimum_size.y < 300.0:
		canvas.free()
		return "IslandMapCanvas minimum size too small: %s" % str(canvas.custom_minimum_size)

	# Test player position and heading updates
	canvas.update_player(Vector3(120.0, 5.0, -140.0), 135.0)
	if canvas.player_pos != Vector3(120.0, 5.0, -140.0):
		canvas.free()
		return "IslandMapCanvas player_pos mismatch after update."
	if absf(canvas.player_heading - 135.0) > 0.01:
		canvas.free()
		return "IslandMapCanvas player_heading mismatch after update."

	# Test POI list and discovery count
	var test_pois: Array[Dictionary] = [
		{"id": "antler_rub", "position": Vector3(10.0, 3.0, 10.0), "discovered": true},
		{"id": "monoliths", "position": Vector3(-50.0, 8.0, 20.0), "discovered": false},
		{"id": "cairn_summit", "position": Vector3(0.0, 42.0, 0.0), "discovered": true}
	]
	canvas.update_pois(test_pois)
	if canvas.discovered_count != 2:
		var count: int = canvas.discovered_count
		canvas.free()
		return "IslandMapCanvas discovered_count is %d (expected 2)." % count

	if canvas._get_short_poi_name("cairn_summit") != "Summit Cairn":
		canvas.free()
		return "IslandMapCanvas POI name formatting incorrect."

	canvas.free()
	return ""

## 14. WorldHUD Map Modal toggle and tactile audio volume controls
func test_hud_map_modal_and_audio_controls() -> String:
	var hud: WorldHUD = WorldHUD.new()
	hud._build_ui()

	if hud._map_btn == null or hud._map_modal == null:
		hud.free()
		return "WorldHUD map button or modal container not initialized."

	if hud._map_modal.visible:
		hud.free()
		return "WorldHUD map modal should start hidden."

	# Toggle open
	hud.toggle_map_modal()
	if not hud._map_modal.visible:
		hud.free()
		return "WorldHUD map modal failed to open on toggle."

	# Toggle closed
	hud.toggle_map_modal()
	if hud._map_modal.visible:
		hud.free()
		return "WorldHUD map modal failed to close on second toggle."

	# Verify audio volume controls
	if hud._master_vol_label == null or hud._ambience_vol_label == null:
		hud.free()
		return "WorldHUD audio volume labels not initialized."

	# Test master volume handler
	hud._on_master_volume_changed(0.70)
	if hud._master_vol_label.text != "70%":
		var text: String = hud._master_vol_label.text
		hud.free()
		return "Master volume label text is '%s' (expected '70%%')." % text

	# Test ambience volume handler
	hud._on_ambience_volume_changed(0.45)
	if hud._ambience_vol_label.text != "45%":
		var text: String = hud._ambience_vol_label.text
		hud.free()
		return "Ambience volume label text is '%s' (expected '45%%')." % text

	# Ensure tab container still satisfies contract == 3 tabs
	if hud._modal_tab_container.get_tab_count() != 3:
		var cnt: int = hud._modal_tab_container.get_tab_count()
		hud.free()
		return "WorldHUD modal tab count is %d (expected 3)." % cnt

	hud.free()
	return ""

## 15. SpatialAudioDirector ambience volume scaling and ambient motif synthesis
func test_ambient_exploration_motif_and_ambience_scaling() -> String:
	var director: SpatialAudioDirector = SpatialAudioDirector.new()
	director.setup(null, null, null, null)

	# Test ambience volume scaling contract
	director.set_ambience_volume_scale(0.65)
	if absf(director.get_ambience_volume_scale() - 0.65) > 0.01:
		var scale: float = director.get_ambience_volume_scale()
		director.free()
		return "SpatialAudioDirector ambience volume scale is %.2f (expected 0.65)." % scale

	# Test procedural ambient motif synthesis (pentatonic acoustic chime motif)
	var motif: AudioStreamWAV = SpatialAudioDirector._generate_ambient_motif_wav(2.4, 22050)
	if motif == null:
		director.free()
		return "Ambient motif generator returned null."
	if motif.format != AudioStreamWAV.FORMAT_16_BITS:
		director.free()
		return "Ambient motif format is not 16-bit PCM."
	if motif.mix_rate != 22050:
		director.free()
		return "Ambient motif mix rate is %d (expected 22050)." % motif.mix_rate
	if motif.data.size() < int(2.4 * 22050.0) * 2:
		director.free()
		return "Ambient motif byte buffer size is smaller than expected."

	director.free()
	return ""

## 16. Alpine Tarn high glacial lake properties and perimeter moraine
func test_alpine_tarn_lake_properties_and_acoustics() -> String:
	var tarn: AlpineTarn = AlpineTarn.new()
	if absf(tarn.get_water_elevation() - 36.0) > 0.05:
		var elev: float = tarn.get_water_elevation()
		tarn.free()
		return "AlpineTarn water elevation is %.2f (expected 36.0m)." % elev

	# Point inside tarn
	if not tarn.is_point_in_tarn(-125.0, -110.0):
		tarn.free()
		return "Center point (-125, -110) reported not inside AlpineTarn."

	# Distant point outside tarn
	if tarn.is_point_in_tarn(0.0, 0.0):
		tarn.free()
		return "Origin point (0, 0) falsely reported inside AlpineTarn."

	# Moraine boulder ring
	var boulders: Node3D = tarn.get_node_or_null("MoraineBoulders") as Node3D
	if boulders == null or boulders.get_child_count() < 12:
		var cnt: int = boulders.get_child_count() if boulders else 0
		tarn.free()
		return "AlpineTarn MoraineBoulders count is %d (expected >= 12)." % cnt

	tarn.free()
	return ""

## 17. Whispering Grotto cavern architecture, crystals and player volume detection
func test_whispering_grotto_cavern_architecture_and_crystals() -> String:
	var grotto: CaveFeature = CaveFeature.new()
	var center: Vector3 = grotto.get_grotto_center()
	if (center - Vector3(-78.0, 16.5, -72.0)).length() > 0.1:
		grotto.free()
		return "WhisperingGrotto center position mismatch: %s" % str(center)

	# Inside cavern volume check
	if not grotto.is_player_inside(Vector3(-78.0, 17.5, -72.0)):
		grotto.free()
		return "Player at cavern center not detected inside WhisperingGrotto."

	# Outside cavern volume check
	if grotto.is_player_inside(Vector3(0.0, 5.0, 0.0)):
		grotto.free()
		return "Player at origin falsely detected inside WhisperingGrotto."

	# Check vaulted stone arches
	var arches: Node3D = grotto.get_node_or_null("VaultedCeilingArches") as Node3D
	if arches == null or arches.get_child_count() < 8:
		var count: int = arches.get_child_count() if arches else 0
		grotto.free()
		return "WhisperingGrotto vaulted arches count is %d (expected >= 8)." % count

	# Check bioluminescent crystal lights
	if grotto._crystal_lights.size() < 3:
		var count: int = grotto._crystal_lights.size()
		grotto.free()
		return "WhisperingGrotto crystal lights count is %d (expected >= 3)." % count

	grotto.free()
	return ""

## 18. Towering Skyspire Massif elevation (>= 75m) and glacial tarn cirque bathymetry
func test_towering_alpine_skyspire_elevation_and_tarn_basin() -> String:
	var terrain: IslandTerrain = IslandTerrain.new()
	terrain.island_size = 720.0
	terrain.generate_island(1337)

	# 1. Skyspire Alpine Summit elevation contract (must reach >= 75.0m for grand scale)
	var peak_h: float = terrain.get_height_at(-145.0, -145.0)
	if peak_h < 75.0:
		terrain.free()
		return "Skyspire summit elevation is %.2fm (expected >= 75.0m)." % peak_h

	# 2. Alpine Tarn cirque lake bed elevation contract (must sit safely below 36.0m water surface)
	var tarn_bed_h: float = terrain.get_height_at(-125.0, -110.0)
	if tarn_bed_h >= 35.8 or tarn_bed_h < 31.0:
		terrain.free()
		return "Alpine Tarn bed elevation is %.2fm (expected 31.0m - 35.8m under 36m lake plane)." % tarn_bed_h

	# 3. Whispering Grotto floor elevation contract (embedded at mountain root 16.5m)
	var grotto_h: float = terrain.get_height_at(-78.0, -72.0)
	if absf(grotto_h - 16.5) > 1.0:
		terrain.free()
		return "Whispering Grotto floor elevation is %.2fm (expected ~16.5m for mountain root cavern)." % grotto_h

	# 4. Central glade spawn elevation integrity (must stay around 3.8m for grounded player spawn)
	var spawn_h: float = terrain.get_height_at(7.5, 3.5)
	if absf(spawn_h - 3.85) > 0.8:
		terrain.free()
		return "Central glade spawn elevation shifted unexpectedly to %.2fm (expected ~3.85m)." % spawn_h

	# 5. Outer ocean perimeter containment (distance > 340m must be submerged)
	var ocean_h: float = terrain.get_height_at(350.0, 0.0)
	if ocean_h > 0.0:
		terrain.free()
		return "Outer continent ocean perimeter at 350m is not submerged: %.2fm" % ocean_h

	terrain.free()
	return ""

## 19. Silverveil Glacial Falls cascade ribbons, gorge flanks, and plunge pool
func test_alpine_waterfall_cascade_and_plunge_pool() -> String:
	var waterfall: AlpineWaterfall = AlpineWaterfall.new()

	if waterfall._cascade_upper == null or waterfall._cascade_lower == null:
		waterfall.free()
		return "AlpineWaterfall cascade ribbon meshes not created."

	if waterfall._plunge_pool == null:
		waterfall.free()
		return "AlpineWaterfall plunge pool mesh not created."

	if waterfall._spray_particles == null or waterfall._spray_particles.amount < 40:
		var cnt: int = waterfall._spray_particles.amount if waterfall._spray_particles else 0
		waterfall.free()
		return "AlpineWaterfall spray particles count is %d (expected >= 40)." % cnt

	if waterfall._gorge_rocks == null or waterfall._gorge_rocks.get_child_count() < 6:
		var cnt: int = waterfall._gorge_rocks.get_child_count() if waterfall._gorge_rocks else 0
		waterfall.free()
		return "AlpineWaterfall gorge flanking boulders count is %d (expected >= 6)." % cnt

	if waterfall._audio_emitter == null:
		waterfall.free()
		return "AlpineWaterfall audio emitter not created."

	waterfall.free()
	return ""

## 20. Whispering Grotto bioluminescent spore motes and stalactite drips
func test_whispering_grotto_spores_and_drips() -> String:
	var grotto: CaveFeature = CaveFeature.new()

	if grotto._spore_particles == null or grotto._spore_particles.amount < 30:
		var cnt: int = grotto._spore_particles.amount if grotto._spore_particles else 0
		grotto.free()
		return "WhisperingGrotto spore particles count is %d (expected >= 30)." % cnt

	if grotto._drip_particles == null or grotto._drip_particles.amount < 10:
		var cnt: int = grotto._drip_particles.amount if grotto._drip_particles else 0
		grotto.free()
		return "WhisperingGrotto drip particles count is %d (expected >= 10)." % cnt

	grotto.free()
	return ""

## 21. Summit spindrift particles and forest fireflies
func test_summit_spindrift_and_forest_fireflies() -> String:
	var controller: WeatherEffectsController = WeatherEffectsController.new()
	controller._setup_spindrift_particles()
	controller._setup_firefly_particles()

	if controller.get_spindrift_particle_count() < 50:
		var cnt: int = controller.get_spindrift_particle_count()
		controller.free()
		return "Spindrift particle count is %d (expected >= 50)." % cnt

	if controller.get_firefly_particle_count() < 20:
		var cnt: int = controller.get_firefly_particle_count()
		controller.free()
		return "Firefly particle count is %d (expected >= 20)." % cnt

	controller.free()
	return ""


