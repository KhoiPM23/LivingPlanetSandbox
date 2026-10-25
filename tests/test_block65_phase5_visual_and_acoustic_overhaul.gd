class_name TestBlock65Phase5VisualAndAcousticOverhaul
extends RefCounted

## Living Planet Sandbox — Block 65 Automated Verification Suite
## Validates Phase 5:
## 5.1 MultiMesh & Impostor LOD (FoliageLODSystem)
## 5.2 Glassmorphic Diegetic HUD (GlassmorphicDiegeticHUD)
## 5.3 Acoustic Landscape & Spatial Soundscape (AcousticLandscapeSystem)
## + Shader Harmonization (Stylized PBR Strata & Multi-Octave Foliage Swirls)

const FoliageLODSystemScript = preload("res://presentation/environment/foliage_lod_system.gd")
const GlassmorphicDiegeticHUDScript = preload("res://presentation/ui/glassmorphic_diegetic_hud.gd")
const AcousticLandscapeSystemScript = preload("res://presentation/audio/acoustic_landscape_system.gd")

func get_suite_name() -> String:
	return "TestBlock65Phase5VisualAndAcousticOverhaul"

func get_tests() -> Array[Callable]:
	return [
		Callable(self, "test_terrain_pbr_stylized_strata_and_palette"),
		Callable(self, "test_foliage_wind_multi_octave_swirls_and_chlorophyll"),
		Callable(self, "test_foliage_lod_system_clustering_and_bands"),
		Callable(self, "test_glassmorphic_diegetic_hud_lifecycle"),
		Callable(self, "test_acoustic_landscape_system_footsteps_and_zones")
	]

func test_terrain_pbr_stylized_strata_and_palette() -> String:
	var shader = load("res://presentation/shaders/terrain_pbr.gdshader") as Shader
	if not shader:
		return "Failed to load res://presentation/shaders/terrain_pbr.gdshader"
	var code = shader.code
	if code.find("stylized_grass_ramp") == -1:
		return "terrain_pbr.gdshader must include stylized painterly grass ramp"
	if code.find("strata") == -1:
		return "terrain_pbr.gdshader must include geological strata banding"
	if code.find("bevel_crest") == -1:
		return "terrain_pbr.gdshader must include chiseled bevel edge highlight"
	return ""

func test_foliage_wind_multi_octave_swirls_and_chlorophyll() -> String:
	var shader = load("res://presentation/shaders/foliage_wind.gdshader") as Shader
	if not shader:
		return "Failed to load res://presentation/shaders/foliage_wind.gdshader"
	var code = shader.code
	if code.find("w_dir2") == -1:
		return "foliage_wind.gdshader must use dual-octave wind vectors"
	if code.find("field_wave") == -1:
		return "foliage_wind.gdshader must calculate multi-octave field wave"
	if code.find("BACKLIGHT") == -1:
		return "foliage_wind.gdshader must support chlorophyll subsurface transmission"
	if code.find("push_curve") == -1:
		return "foliage_wind.gdshader must use smooth quadratic actor trampling curve"
	return ""

func test_foliage_lod_system_clustering_and_bands() -> String:
	var lod_sys = FoliageLODSystemScript.new()
	if not lod_sys:
		return "Failed to instantiate FoliageLODSystem"
	lod_sys._build_lod_meshes()

	if lod_sys.get_lod_band(20.0) != 0:
		lod_sys.free()
		return "Expected Near Band 0 at 20m"
	if lod_sys.get_lod_band(75.0) != 1:
		lod_sys.free()
		return "Expected Mid Band 1 at 75m"
	if lod_sys.get_lod_band(200.0) != 2:
		lod_sys.free()
		return "Expected Far Impostor Band 2 at 200m"
	if lod_sys.get_lod_band(450.0) != 3:
		lod_sys.free()
		return "Expected culled Band 3 at 450m"
	if lod_sys.get_draw_call_estimate() > 4:
		lod_sys.free()
		return "Draw call estimate exceeds budget"

	lod_sys.free()
	return ""

func test_glassmorphic_diegetic_hud_lifecycle() -> String:
	var hud = GlassmorphicDiegeticHUDScript.new()
	if not hud:
		return "Failed to instantiate GlassmorphicDiegeticHUD"
	hud._build_ui()

	if not hud.is_hud_visible():
		hud.free()
		return "HUD should be visible by default"
	hud.toggle_visibility()
	if hud.is_hud_visible():
		hud.free()
		return "HUD should toggle to hidden"
	hud.toggle_visibility()
	if not hud.is_hud_visible():
		hud.free()
		return "HUD should toggle back to visible"

	hud.set_element(1) # Anemo
	if hud._current_element_symbol != "🌀":
		hud.free()
		return "Element 1 must be Anemo (🌀)"

	hud.set_element(2) # Pyro
	if hud._current_element_symbol != "🔥":
		hud.free()
		return "Element 2 must be Pyro (🔥)"

	hud.set_element(3) # Hydro
	if hud._current_element_symbol != "💧":
		hud.free()
		return "Element 3 must be Hydro (💧)"

	hud.set_element(4) # Cryo
	if hud._current_element_symbol != "❄️":
		hud.free()
		return "Element 4 must be Cryo (❄️)"

	hud.update_hud(0.1, true, 2, 0.75)
	if absf(hud._cooldown_progress - 0.75) > 0.01:
		hud.free()
		return "Cooldown progress not updated properly"

	hud.free()
	return ""

func test_acoustic_landscape_system_footsteps_and_zones() -> String:
	var acoustic = AcousticLandscapeSystemScript.new()
	if not acoustic:
		return "Failed to instantiate AcousticLandscapeSystem"
	acoustic._init_audio_players()
	acoustic._cache_footstep_audio()

	if not acoustic._step_sounds.has(AcousticLandscapeSystemScript.SurfaceType.MEADOW_GRASS):
		acoustic.free()
		return "Missing meadow grass sound"
	if not acoustic._step_sounds.has(AcousticLandscapeSystemScript.SurfaceType.GRANITE_ROCK):
		acoustic.free()
		return "Missing granite rock sound"
	if not acoustic._step_sounds.has(AcousticLandscapeSystemScript.SurfaceType.LAKE_MUD):
		acoustic.free()
		return "Missing lake mud sound"
	if not acoustic._step_sounds.has(AcousticLandscapeSystemScript.SurfaceType.CRYO_ICE):
		acoustic.free()
		return "Missing cryo ice sound"
	if not acoustic._step_sounds.has(AcousticLandscapeSystemScript.SurfaceType.SHALLOW_WATER):
		acoustic.free()
		return "Missing shallow water sound"
	if not acoustic._step_sounds.has(AcousticLandscapeSystemScript.SurfaceType.TIMBER_WOOD):
		acoustic.free()
		return "Missing timber wood sound"

	var summit_pos = Vector3(0.0, 36.0, 0.0)
	if acoustic.get_current_zone(summit_pos) != "Skyspire Summit":
		acoustic.free()
		return "Expected Skyspire Summit zone at Y=36m"

	var lake_pos = Vector3(45.0, 1.5, 65.0)
	if acoustic.get_current_zone(lake_pos) != "Grand Emerald Lake":
		acoustic.free()
		return "Expected Grand Emerald Lake zone"

	var sound_emitted = [false]
	acoustic.surface_sound_played.connect(func(s: String): sound_emitted[0] = true)
	acoustic.play_surface_footstep("meadow")
	if not sound_emitted[0]:
		acoustic.free()
		return "play_surface_footstep did not emit signal"

	acoustic.free()
	return ""
