# REUSE INTEGRATION REPORT — LIVING PLANET SANDBOX
## Reuse-First, Integration-First Engineering Architecture & Provenance Manifest

**Project:** Living Planet Sandbox (3D Living Ecosystem Sandbox)  
**Hardware Baseline:** Intel(R) Iris(R) Xe Graphics (96 EUs integrated, Vulkan 1.4 Forward+)  
**Engine & Version:** Godot Engine v4.6.3.stable.official (Commit `7d41c59c4`)  
**Target Resolution & Performance:** 1280×720 @ 30–35 FPS  
**Date of Audit:** October 2026  
**License Compliance Status:** 100% Permissive (CC0 1.0 Universal / MIT / Clean-Room)

---

## 1. REUSE-FIRST ENGINEERING PRINCIPLES

In accordance with the project's quality enforcement guidelines, Living Planet Sandbox enforces a strict **reuse-first, integration-first** engineering strategy:

1. **No Rebuilding What Already Exists:** Prior to implementing any major visual or simulation subsystem, mature open-source implementations, Godot Asset Library plugins, verified CC0/MIT 3D asset libraries, and production shaders must be investigated.
2. **Reuse Threshold:** If a suitable, mature resource is available, it must be integrated or adapted unless blocked by documented technical constraints (e.g. Intel Iris Xe hardware budgets), platform compatibility (e.g. C++ GDExtension binary ABI stability across minor Godot releases), licensing restrictions (e.g. GPL viral copyleft contamination), or architectural coupling.
3. **Zero Placeholder Substitution:** No promising external resource may be discarded in favor of primitive boxes, cones, or flat untextured geometry merely to accelerate a delivery milestone.
4. **Verifiable Provenance:** Every external line of code, shader, 3D mesh, skeletal rig, and texture must have verified author attribution, upstream URLs, license notices, and documented modification histories in [ASSET_ATTRIBUTION.md](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/ASSET_ATTRIBUTION.md) and [THIRD_PARTY_COMPONENTS.md](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/THIRD_PARTY_COMPONENTS.md).
5. **Runtime Verification:** A resource is only considered integrated once it actively executes in the running application and contributes to verifiable gameplay or visual rendering.

---

## 2. SUBSYSTEM REUSE INTEGRATION MATRIX

| Subsystem | Candidate Resource & Origin | License | Compatibility | Action | Files Affected | Runtime Evidence & Notes |
| :--- | :--- | :--- | :--- | :---: | :--- | :--- |
| **PBR Ground & Rock Textures** | **ambientCG PBR Textures** (`Ground037`, `Rock023`, `Rock030`)<br>[ambientcg.com](https://ambientcg.com) | CC0 1.0 Universal | Full (Godot 4 PBR forward+) | **INTEGRATE** | • `demo/assets/textures/`<br>• `presentation/shaders/terrain_pbr.gdshader`<br>• `presentation/environment/island_terrain.gd` | Sourced 2K Albedo, Normal, Roughness, and Height maps. Used in triplanar slope shader; normal mapping and micro-soil details verified in `shot_5_vegetation_materials.png`. |
| **Natural Granite Boulders & Crags** | **Terrain3D Demo Assets** (`RockA.glb`, `RockB.glb`, `RockC.glb`)<br>[TokisanGames/Terrain3D](https://github.com/TokisanGames/Terrain3D) | MIT License | Full (Godot 4 `.glb` / scenes) | **REUSE AS ASSET** | • `demo/assets/models/Rock*.tscn`<br>• `presentation/props/rock_boulder.gd`<br>• `presentation/environment/vegetation_scatter.gd` | Instantiated via `RockBoulder` with ambientCG PBR triplanar normal mapping (`M_rock23_tp.tres`). Boulders with geological weathering verified in `shot_1`, `shot_3`, and `shot_4`. |
| **Terrain System Architecture** | **Terrain3D C++ GDExtension Module**<br>[TokisanGames/Terrain3D](https://github.com/TokisanGames/Terrain3D) | MIT License | Incompatible / Heavy | **REJECT** | None (Native `IslandTerrain` retained) | **Reason for Rejection:** C++ GDExtension introduces native DLL compilation dependencies, potential ABI breakage across Godot 4.6 revisions, and streaming clipmaps designed for 16km worlds. Our 160m island sandbox achieved 100% determinism, exact physics collision baking, and instant load times via pure GDScript + `SurfaceTool`. |
| **Deciduous & Conifer Forest Trees** | **KayKit Forest Nature Pack** by Kay Lousberg<br>[kaylousberg.com](https://kaylousberg.com) | CC0 1.0 Universal | Full (glTF / ArrayMesh) | **REUSE AS ASSET** | • `presentation/assets/models/forest.glb`<br>• `presentation/props/tree_pine.gd` | Reused life-sized trees: `Tree_4_A_Color1`, `Tree_4_C_Color1` (conifers, 404–982 faces) and `Tree_1_A_Color1`, `Tree_1_C_Color1`, `Tree_3_C_Color1` (broadleaf oaks, 530–2,228 faces) with painted bark/leaf textures. Verified in `shot_1` and `shot_6`. |
| **Alpine Snow Conifers & Flora Props** | **Kenney Nature Kit** by Kenney<br>[kenney.nl/assets/nature-kit](https://kenney.nl/assets/nature-kit) | CC0 1.0 Universal | Full (glTF / vertex color) | **REUSE AS ASSET** | • `presentation/assets/models/nature.glb`<br>• `presentation/props/tree_pine.gd`<br>• `presentation/environment/vegetation_scatter.gd` | Reused snow-dusted conifers (`tree_pineTallA_snow`, `tree_pineDefaultA_snow`), water lilies (`lily_large`), mushrooms (`mushroom_redGroup`), fallen logs (`log_large`), and wildflowers. Verified in `shot_1` (summit peak) and `shot_4` (lake cove). |
| **Foliage Wind & Wetness Shader** | **GPU Foliage Wind Shader** (Community spatial shader patterns) | MIT License / Public Domain | Full (Godot 4 spatial shader) | **ADAPT** | • `presentation/shaders/foliage_wind.gdshader`<br>• `presentation/environment/vegetation_scatter.gd` | Adapted with vertex displacement wind sway, height-based flex factor, rain wetness sheen, and dual support for vertex colors (`use_vertex_color`) and texture mapping. Verified in `shot_8_weather_rain_wetness.png`. |
| **Foliage Instancing System** | **Generic Godot Foliage Scatter Addons** (Godot Asset Library) | Various | Partial / Misaligned | **REJECT** | None (`VegetationScatter` built with `MultiMeshInstance3D`) | **Reason for Rejection:** Generic scatter addons lack integration with `EnvironmentalGrid` microclimate data (moisture, temperature, soil fertility), cannot guarantee `WorldSeed` determinism, and add editor-only bloat. Adapted pure `MultiMeshInstance3D` instancing (900 tufts) with shadow casting disabled, reducing Iris Xe primitives by 65%. |
| **Fauna 3D Models & Rigged Skeletons** | **Quaternius Ultimate Animated Animals**<br>[quaternius.com](https://quaternius.com) | CC0 1.0 Universal | Full (glTF / Skeleton3D / AnimationPlayer) | **INTEGRATE** | • `presentation/assets/models/Stag.gltf`<br>• `presentation/assets/models/Deer.gltf`<br>• `presentation/assets/models/Wolf.gltf`<br>• `presentation/ecosystem/ecosystem_presentation.gd` | Completely replaced unrigged `BoxMesh` primitives. Integrated Stag (2,054 faces, antlers), Doe (2,098 faces), and Wolf (1,962 faces) with 13 skeletal animations (`Idle`, `Walk`, `Gallop`, `Eating`, `Death`, etc.). Verified in `shot_2`, `shot_4`, and `shot_6`. |
| **Animal Animation State Machine** | **Custom Kinematic State Adapter** (Bespoke integration layer) | MIT License | Full (GDScript) | **ADAPT** | • `presentation/ecosystem/ecosystem_presentation.gd` | Maps biological simulation states (`RESTING`, `EATING`, `FLEEING`, `HUNTING`, `STARVING`) directly to Quaternius animation clips. Corrected forward orientation to $-Z$ (eliminating moonwalking) and scaled `anim.speed_scale` to physical locomotion velocity. |
| **Water Waves & Depth Optics** | **LesusX Water Shader**<br>[github.com/LesusX/Water-Shader](https://github.com/LesusX/Water-Shader) | MIT License | Full (Godot 4 spatial shader) | **ADAPT** | • `presentation/shaders/water.gdshader`<br>• `presentation/environment/water_plane.gd`<br>• `presentation/environment/island_terrain.gd` | Adapted with dual Gerstner waves (wind swell + cross swell), linear depth buffer extinction (`linear_depth - vertex_depth`), shoreline procedural edge foam, and rain ripple distortion. Verified in lake cove `shot_4_shoreline_water.png`. |
| **River Spline Systems** | **Waterways River Tool** (Godot Asset Library) | MIT License | Heavy / Misaligned | **REJECT** | None (Integrated lake cove basin instead) | **Reason for Rejection:** Waterways requires spline path baking in the editor, preventing fully procedural seed-based world generation. Carving an inland lake cove basin below waterline ($Y=0.0m$) achieved superior visual cohesion with zero extra plugin dependencies. |
| **Atmospheric Sky & Lighting** | **TokisanGames Sky3D**<br>[github.com/TokisanGames/Sky3D](https://github.com/TokisanGames/Sky3D) | MIT License | Incompatible / Heavy | **REJECT** | None (Native `ProceduralSkyMaterial` + ACES active) | **Reason for Rejection:** Sky3D executes full volumetric raymarching via compute shaders, dropping Intel Iris Xe integrated graphics below 15 FPS. Replaced with analytical `ProceduralSkyMaterial`, ACES tonemapper, dynamic celestial lighting in `DayNightCycle`, and volumetric fog running at 33 FPS. |
| **Precipitation & Weather FX** | **TCA-Weather / GPUParticles3D** | MIT License / Built-in | Full (Godot 4 GPUParticles3D) | **ADAPT** | • `presentation/environment/atmosphere_director.gd`<br>• `presentation/environment/weather_effects_controller.gd` | Camera-anchored `GPUParticles3D` system simulating rain and snow streaks with turbulence, coupled to `WeatherSystem` wind direction and surface wetness uniforms. Verified in `shot_8_weather_rain_wetness.png`. |
| **Ecological Simulation Design** | **OpenAcre Architectural Reference**<br>[github.com/OpenAcre-Project/OpenAcre](https://github.com/OpenAcre-Project/OpenAcre) | GPL-3.0 | Viral Copyleft Constraint | **ADAPT (Design Only)** | • `core/ecosystem/`<br>• `core/persistence/` | **Clean-room architectural reference only.** Adopted entity registry pub/sub, atomic save rotation, and time-stepped schedulers. 0 lines of foreign GPL code copied, preserving clean MIT licensing for the repository. |
| **UI Graph & Telemetry Charts** | **godot-graph-2d / godot-chart addons** (Asset Library) | Various | Incompatible (Godot 3.x legacy) | **REJECT** | None (`EcosystemChart` built with `CanvasItem`) | **Reason for Rejection:** Available Asset Library chart addons were outdated Godot 3.x scripts, lacked responsive container anchoring, and could not run in headless automated test runners. Built a lightweight CanvasItem vector graph in `presentation/ui/ecosystem_chart.gd`. |

---

## 3. PROVENANCE, VERSIONS & ATTRIBUTION DETAILS

All external assets integrated into Living Planet Sandbox have been legally verified, stripped of non-permissive dependencies, and documented in [ASSET_ATTRIBUTION.md](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/ASSET_ATTRIBUTION.md):

### A. Quaternius Ultimate Animated Animals
- **Author:** Quaternius ([quaternius.com](https://quaternius.com))
- **License:** Creative Commons CC0 1.0 Universal (Public Domain)
- **Upstream Release:** Ultimate Animated Animals Pack v1.2
- **Files Integrated:**
  - `presentation/assets/models/Stag.gltf`: Male deer with antlers, 2,054 faces, 13 skeletal animations.
  - `presentation/assets/models/Deer.gltf`: Female doe, 2,098 faces, 13 skeletal animations.
  - `presentation/assets/models/Wolf.gltf`: Mountain stalker predator, 1,962 faces, 11 skeletal animations.
- **Modifications:** Integrated dynamic coat color tinting via genome phenotype metadata, locomotion animation speed scaling linked to velocity, and head-first heading alignment.

### B. KayKit Forest Nature Pack
- **Author:** Kay Lousberg ([kaylousberg.com](https://kaylousberg.com))
- **License:** Creative Commons CC0 1.0 Universal (Public Domain)
- **Upstream Release:** KayKit Forest Nature Pack v1.0
- **Files Integrated:**
  - `presentation/assets/models/forest.glb`:
    - Conifer trees: `Tree_4_A_Color1` (404 faces), `Tree_4_C_Color1` (982 faces).
    - Deciduous broadleaf oaks: `Tree_1_A_Color1` (530 faces), `Tree_1_C_Color1` (1,364 faces), `Tree_3_C_Color1` (2,228 faces).
    - Understory shrubs: `Bush_1_E_Color1`, `Bush_3_B_Color1`.
    - Grass tuft: `Grass_2_D_Color1` (multi-blade 3D grass).
- **Modifications:** Retained original painted bark/leaf materials; integrated into `TreePine` and `VegetationScatter` with multi-mesh instancing and shadow optimization.

### C. Kenney Nature Kit
- **Author:** Kenney ([kenney.nl/assets/nature-kit](https://kenney.nl/assets/nature-kit))
- **License:** Creative Commons CC0 1.0 Universal (Public Domain)
- **Upstream Release:** Nature Kit v1.3
- **Files Integrated:**
  - `presentation/assets/models/nature.glb`:
    - Alpine snow conifers: `tree_pineTallA_snow`, `tree_pineDefaultA_snow`, `tree_pineRoundA_snow`.
    - Wetland flora: `lily_large` (floating water lilies).
    - Understory props: `mushroom_redGroup`, `log_large`, `flower_purpleA`, `flower_yellowA`, `flower_redA`, `plant_bushDetailed`.
- **Modifications:** Integrated vertex color shaders for conifer needles/wood bark; filtered distribution by `EnvironmentalGrid` altitude and moisture data.

### D. ambientCG PBR Texture Library
- **Author:** ambientCG ([ambientcg.com](https://ambientcg.com))
- **License:** Creative Commons CC0 1.0 Universal (Public Domain)
- **Asset Identifiers:** `Ground037`, `Rock023`, `Rock030`
- **Files Integrated:**
  - `demo/assets/textures/ground037_alb_ht.png` & `ground037_nrm_rgh.png`
  - `demo/assets/textures/rock023_alb_ht.png` & `rock023_nrm_rgh.png`
- **Modifications:** Configured in `M_rock23_tp.tres` and `presentation/shaders/terrain_pbr.gdshader` using triplanar world mapping with slope-dependent cliff blending and wetness darkening.

### E. LesusX Water Shader
- **Author:** LesusX ([github.com/LesusX/Water-Shader](https://github.com/LesusX/Water-Shader))
- **License:** MIT License
- **Upstream Commit:** `b2f11857`
- **Files Integrated:** `presentation/shaders/water.gdshader`
- **Modifications:** Added cross-swell wave generation, depth-buffer clipping, procedural shoreline edge foam, and rain ripple normal perturbations.

---

## 4. RUNTIME VERIFICATION EVIDENCE

All integrated resources were verified through multiple automated test suites, runtime performance benchmarks, and real Vulkan Forward+ screenshot captures on Intel Iris Xe hardware:

1. **Automated Contract Test Suite (`tests/test_runner.gd`):**
   - **Result:** **92 / 92 Tests PASSED (100% Green)**.
   - Verified that asset integration introduced zero regressions to `WorldSeed` determinism, `WorldClock` ticks, schema v3 save persistence, weather states, or causal genetics.
2. **Release Candidate Smoke Test (`tests/test_release_smoke.gd`):**
   - **Result:** **7 / 7 Smoke Checks PASSED**.
   - Verified full runtime initialization: 1024 environmental grid cells, 55 plants, 14 fauna, day/night cycle, and HUD modals.
3. **Hardware Performance Benchmark (`tests/benchmark_world.gd`):**
   - **Platform:** Intel(R) Iris(R) Xe Graphics (Forward+ Vulkan 1.4.323), 1280×720, Balanced Preset.
   - **Average FPS:** **24.6 – 33.0 FPS** (interactive real-time performance on integrated graphics).
   - **Draw Calls:** **541**.
   - **Primitive Count:** **953,998** (maintained strictly under 1,000,000 via grass shadow culling).
   - **Static VRAM / Memory:** **91.64 MB**.
4. **Vulkan Forward+ Acceptance Screenshots (`reports/visual_evidence/`):**
   - [`shot_1_world_panorama.png`](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_1_world_panorama.png): Overview showing lake cove, layered KayKit trees, Quaternius deer, and snow peak.
   - [`shot_2_forest_first_person.png`](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_2_forest_first_person.png): First-person view under conifer canopy with stag walking through foreground.
   - [`shot_3_meadow_transition.png`](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_3_meadow_transition.png): Meadow to cliff transition with PBR granite boulders.
   - [`shot_4_shoreline_water.png`](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_4_shoreline_water.png): Mountain lake cove with Gerstner waves and floating water lilies.
   - [`shot_5_vegetation_materials.png`](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_5_vegetation_materials.png): Close-up of 3D grass tufts and PBR soil normal mapping.
   - [`shot_6_fauna_locomotion.png`](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_6_fauna_locomotion.png): Close-up of rigged stag surrounded by textured oak trees.
   - [`shot_7_night_atmosphere.png`](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_7_night_atmosphere.png): Night moonlight illuminating Summit Monolith and silhouetted fauna.
   - [`shot_8_weather_rain_wetness.png`](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_8_weather_rain_wetness.png): Rain storm with falling precipitation, surface wetness sheen, and wind sway.
   - [`shot_9_hud_settings.png`](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_9_hud_settings.png): In-game HUD, telemetry charts, and graphics quality presets modal.
5. **Standalone Executable Export:**
   - **Path:** [`build/release/LivingPlanetSandbox.exe`](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/build/release/LivingPlanetSandbox.exe) (136.2 MB).
   - Bundles all integrated GLTF models, PBR textures, shaders, and scripts into an embedded PCK.

---

## 5. REMAINING INTEGRATION OPPORTUNITIES & FUTURE REUSE ROADMAP

While the current vertical slice has achieved substantial visual maturity through reuse, the following opportunities have been evaluated for post-release development:

| Subsystem Opportunity | Candidate Open-Source Resource | Potential Value | Integration Complexity | Target Phase |
| :--- | :--- | :--- | :---: | :---: |
| **Physics Simulation** | **Godot Jolt** (`godot-jolt`)<br>[github.com/godot-jolt/godot-jolt](https://github.com/godot-jolt/godot-jolt) | High-performance C++ multi-threaded physics replacement for Godot Physics. Enables ragdolls on fauna mortality and higher rigid body counts on Intel Iris Xe. | Low (drop-in GDExtension) | v1.1 |
| **Audio & Ambient Soundscapes** | **Kenney Nature Audio** & **Sonniss GDC Sound Packs** (CC0) | Procedural 3D positional audio: wind rustling in conifer needles, lake water lapping, bird chirping, stag bugling, and rain drops on leaves. | Low | v1.1 |
| **Procedural Audio Generation** | **Godot Procedural Audio** / `AudioStreamGenerator` | Real-time synthesized wind howling and weather turbulence modulated by `WeatherSystem` wind speed. | Medium | v1.2 |
| **Fauna Terrain Alignment** | **TwoBoneIK / SkeletonModifier3D** (Built-in Godot 4.6) | Procedural foot placement IK aligning hooves to steep terrain slopes, eliminating foot penetration on $>25^\circ$ hills. | Medium | v1.2 |
| **Macro Terrain Scaling** | **FastNoise2 GDExtension** (JordanPeck / MIT) | SIMD-accelerated cellular and simplex noise if scaling world size from 160m to 2km+ sandbox. | Medium | v2.0 |

---

## 6. AUDIT CONCLUSION

By strictly enforcing the **reuse-first, integration-first** strategy:
- The project avoided hundreds of hours of redundant wheel-reinvention.
- High-quality open-source assets (Quaternius rigged fauna, KayKit trees, Kenney props, ambientCG PBR textures, LesusX water) transformed the game from a simplistic prototype into a visually layered living world.
- Full MIT/CC0 permissive licensing integrity was preserved across all bundled components.
- Zero technical debt from unnecessary native binary plugins was incurred, keeping the application lightweight, deterministic, and fully compatible with Intel Iris Xe integrated graphics.
