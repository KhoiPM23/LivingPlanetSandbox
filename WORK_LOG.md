# WORK LOG — Living Planet Sandbox

## 2026-10-13

### BLOCK 0 — Repository Reconnaissance (COMPLETED)
- Inspected 9 candidate repositories against Windows 11 / Intel Iris Xe constraints.
- Formally rejected Candidate 9 (`godot_procedural_infinite_world`) as whole-project foundation due to C#/.NET SDK lock-in and unoptimized CPU `ArrayMesh` chunk generation.
- Approved Option B: Clean Godot 4.6 GDScript project with selective module reuse.

### BLOCK 1 — Environment Setup & Foundation (COMPLETED)
- **Preflight:** Verified workspace `D:\Personal_Projects\Living Planet Sandbox` was clean; remote GitHub repo `https://github.com/KhoiPM23/LivingPlanetSandbox.git` was empty.
- **Git Scaffolding:** Initialized local Git repository with branch `main` and remote `origin`. Added `.gitignore` and `.gitattributes`. Zero commits created as required.
- **Toolchain:** Downloaded and verified `Godot_v4.6.3-stable_win64.exe` with SHA256 checksum `E39986A178D585CE7AC198FB8DE6EA436366DC0CC00E594810C2E3E104C04B90`. Installed to `$HOME\AppData\Local\Programs\Godot` and created `$HOME\bin\godot.cmd` wrapper in user PATH.
- **Durable Documentation:** Created all 8 durable markdown records (`PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, `CURRENT_STATE.md`, `WORK_LOG.md`, `DECISIONS.md`, `THIRD_PARTY_COMPONENTS.md`, `TESTING.md`, `ROADMAP.md`).
- **Core Architecture Contracts:**
  - `WorldSeed` (`res://core/seed/world_seed.gd`)
  - `WorldClock` (`res://core/clock/world_clock.gd`)
  - `WorldEventBus` (`res://core/events/world_event_bus.gd`)
  - `EntityRegistry` (`res://core/registry/entity_registry.gd`)
  - `SimulationScheduler` (`res://core/scheduler/simulation_scheduler.gd`)
  - `WorldPersistence` (`res://core/persistence/world_persistence.gd`)
  - `WorldBootstrap` (`res://core/bootstrap/world_bootstrap.gd`)
  - `PerformanceMonitor` (`res://core/debug/performance_monitor.gd`)
- **Addon Integration:** Downloaded and verified Terrain3D v1.0.2-stable. Extracted to `res://addons/terrain_3d/`. GDExtension verified and loaded without error.
- **Verification:** 11 unit tests passed, 0 failed.

### BLOCK 2 — First Playable World & Visual Foundation (COMPLETED)
- **Shaders:**
  - `res://presentation/shaders/water.gdshader`: Gerstner dual-wave vertex displacement, Beer's law depth coloring, animated waterline foam, and explicit depth-buffer `discard` to prevent transparent-pass depth fighting on integrated GPUs.
  - `res://presentation/shaders/foliage_wind.gdshader`: Height-attenuated vertex wind sway with vertical color gradient.
- **Procedural Island Environment (`res://presentation/environment/`):**
  - `IslandTerrain` (`island_terrain.gd`): 160m bounded world, 128x128 resolution procedural mesh via SurfaceTool, 3.5m dry land base, prominent Northwest summit peak (15.5m), trimesh collision generation, 4 perimeter boundary collision barriers, and vertex color transitions (Shoreline Sand, Emerald Meadow, Coniferous Forest, Granite Crag, Summit Snow).
  - `WaterPlane` (`water_plane.gd`): 260m subdivided ocean mesh centered at waterline Y = 0.0 with water shader.
  - `DayNightCycle` (`day_night_cycle.gd`): Celestial orbital controller coupled to `WorldClock`, 120s day cycle, 25° axial tilt, morning sunlight start (09:00 AM), dynamic directional light energy, and sky atmosphere gradient interpolation.
- **Biomes & Props (`res://presentation/props/`):**
  - `TreePine` (`tree_pine.gd`): Stylized evergreen pine with bark cylinder and 3 foliage cones.
  - `RockBoulder` (`rock_boulder.gd`): Low-poly faceted granite boulder with mossy tint.
  - `LandmarkMonolith` (`landmark_monolith.gd`): Ancient stone obelisk altar, spire, glowing apex crystal, and omni-light beacon marking the summit.
  - `VegetationScatter` (`vegetation_scatter.gd`): Height- and slope-filtered placement of 55 trees, 35 boulders, summit monolith, and 800 MultiMesh grass instances (1 single draw call for grass). Tracks living flora in `EntityRegistry`.
- **Camera & Presentation UI:**
  - `FreeLookCamera` (`res://presentation/camera/free_look_camera.gd`): Exploration flight camera with smooth mouse look, WASD flight, Shift speed boost, Space/C altitude controls, and direct key fallbacks.
  - `WorldHUD` (`res://presentation/ui/hud.gd`): Clean glassmorphic card displaying world clock, day phase, regional biome tracking (Azure Waters, Shoreline, Emerald Meadows, Pine Highlands, Summit Sanctuary), and simulation speed. Toggleable with `[H]`.
  - `DebugOverlay` (`res://presentation/debug/debug_overlay.gd`): Real-time metrics HUD showing FPS, process frame time, draw calls, primitives, memory, node counts, and simulation controls. Toggleable with `[F1]`.
- **Testing & Benchmarks:**
  - Added `tests/test_playable_world.gd` validating terrain elevation, boundaries, water plane, vegetation scatter, and MultiMesh grass.
  - Test suite runner (`tests/test_runner.gd`): **15 Passed, 0 Failed**.
  - Executed runtime GPU benchmark (`tests/benchmark_world.gd`) on Vulkan 1.4 Forward+ (Intel Iris Xe Graphics, 1280x720):
    - Sampled Frames: 165
    - Average FPS: 28.2 (Windowed Vulkan Forward+)
    - Max Draw Calls: 813
    - Max Primitives: 306,972
    - Static Memory: 67.4 MB
    - Entities Tracked: 56
  - Captured authentic runtime screenshot: `screenshot_first_playable.png` (1280x720, Vulkan runtime evidence).

### BLOCK 3 — Procedural World & Environment Systems (COMPLETED)
- **World Generation Configuration (`res://core/environment/world_generation_config.gd`):**
  - Pure data configuration resource specifying seed, world dimensions (160m), max height (24m), water level (0m), roughness (0.5), vegetation density (1.0), base temperature (22°C), base moisture (0.65), and elevation lapse rate (-6.5°C/km).
  - Enforces strict value clamping, semantic validation, and dictionary serialization/deserialization for save states.
- **Explainable Biome Classifier (`res://core/environment/biome_classifier.gd`):**
  - Whittaker-inspired ecological classification system into 7 distinct biomes: `OCEAN`, `COASTAL_BEACH`, `WETLAND`, `TEMPERATE_MEADOW`, `BOREAL_FOREST`, `ALPINE_SUMMIT`, `ARID_SHRUBLAND`.
  - Implemented `explain_biome()` producing human-readable deterministic causal explanations (e.g., "Elevation (18.2m) is near summit and temperature (-2.1°C) is sub-zero").
  - Provides standardized color palette lookup for vertex shaders, minimap, and HUD readouts.
- **Markov Weather State Machine (`res://core/environment/weather_system.gd`):**
  - 4 discrete states: `CLEAR`, `CLOUDY`, `RAIN`, `DROUGHT`.
  - Driven by independent `weather` PRNG stream from `WorldSeed`.
  - Configurable state durations and transition probability matrix.
  - Generates environmental modifiers: solar light attenuation (1.0 in clear -> 0.4 in rain), temperature offsets (-2.5°C in rain, +4.0°C in drought), and precipitation rates (0.0 to 0.45 mm/s).
  - Broadcasts typed `weather_changed` events via `WorldEventBus`.
- **Dynamic Environmental Grid (`res://core/environment/environmental_grid.gd`):**
  - 2D macro spatial grid (32x32 cells, ~5m resolution, 1024 cells total).
  - Simulates dynamic environmental fields per cell:
    - Temperature (°C) factoring elevation lapse rate and diurnal solar sinusoidal swing (±5.5°C, lagging noon by 2 hours).
    - Soil moisture [0, 1] modulated by weather precipitation, evaporation rate, and ocean capillary saturation.
    - Water availability [0, 1] derived from moisture and proximity to waterline.
    - Sun exposure [0, 1] derived from celestial solar altitude and cloud attenuation.
  - Dynamically recalculates cell biomes when climate variables shift.
  - Linked to `SimulationScheduler` at a low-frequency 2Hz macro tick, keeping frame budget overhead under 0.2ms.
- **Presentation Synchronization:**
  - `IslandTerrain`: Mesh vertex coloring driven by dynamic `EnvironmentalGrid` biomes and `WorldGenerationConfig`.
  - `DayNightCycle`: Coupled with `WeatherSystem` to interpolate directional sun energy and overcast sky gradients.
  - `VegetationScatter`: Filters pine trees, grass, and boulders by biome classification and soil moisture thresholds.
  - `WorldHUD`: Displays live weather state, countdown, microclimate temperature, humidity, sun exposure, and biome info. Hotkey `[T]` added to manually cycle weather states.
- **Testing & Benchmarks:**
  - Added `tests/test_environment_systems.gd` covering config validation, seed determinism & stream isolation, environmental grid ranges, diurnal simulation, weather transitions, and biome consistency.
  - Test runner (`tests/test_runner.gd`): **21 Passed across 7 suites, 0 Failed**.
  - Executed windowed Vulkan 1.4 Forward+ benchmark (`tests/benchmark_world.gd`) on Intel Iris Xe Graphics (1280x720):
    - Sampled Frames: 165
    - Average FPS: 26.5
    - Max Draw Calls: 892
    - Max Primitives: 313,248
    - Static Memory: 68.77 MB
    - Entities Tracked: 56
    - Console Errors: 0
  - Captured authentic runtime screenshot: `screenshot_block_3.png` (1280x720).

### BLOCK 4 — Causal Ecosystem Simulation (COMPLETED)
- **Causal Flora Simulation (`res://core/ecosystem/flora_simulation.gd`):**
  - Manages plant life cycles across discrete growth stages: `SEED`, `SPROUT`, `GROWING`, `MATURE`, `DECAYING`, `DEAD`.
  - Continuous physical biomass (kg) and vitality/health (0-100%).
  - Growth causally driven by `EnvironmentalGrid` moisture, temperature, and sunlight.
  - Moisture deficits below plant minimum trigger drought decay and gradual withering.
  - Mature healthy plants disperse seeds into adjacent habitable cells.
  - Spatial hash grid (10m cells) delivers O(1) neighbor lookups for grazing animals.
- **Causal Fauna Simulation (`res://core/ecosystem/fauna_simulation.gd`):**
  - Implemented Herbivores (`island_deer`) and Predators (`mountain_stalker`).
  - Strict behavior state machines:
    - Herbivores: `WANDERING`, `FORAGING`, `EATING`, `RESTING`, `FLEEING`, `STARVING`.
    - Predators: `WANDERING`, `HUNTING`, `EATING`, `RESTING`, `STARVING`.
  - True continuous metabolism: energy drains steadily; moving incurs extra energy expenditure.
  - Animals seek nearest plant biomass/prey, consume resources, and regain energy & health.
  - Starvation causes health damage and death.
  - High-energy adults reproduce with cooldowns, increasing herd population.
  - Predators hunt herbivores within scent range, kill prey when catching them, and restore energy.
- **Ecosystem Coordination & Metrics (`res://core/ecosystem/`):**
  - `EcosystemCoordinator`: Manages simulation ticks at 2Hz via `SimulationScheduler`.
  - `EcosystemMetrics`: Collects live telemetry: total plant biomass, herbivore/predator populations, average energy/health, cumulative births, and causes of death (starvation, predation, old age, decay).
  - Player interventions supported: `apply_drought()`, `apply_rain()`, and agent spawning.
- **Decoupled Visual Presentation (`res://presentation/ecosystem/`):**
  - `EcosystemPresentation`: Low-poly stylized 3D animal models (fawns with horns, dark charcoal stalkers with glowing amber eyes).
  - Code-based hopping and prowling animations purely reflecting simulation positions and headings.
  - Plant nodes visually scale according to biomass.
- **Testing & Causal Acceptance:**
  - Added `tests/test_causal_ecosystem.gd` with 7 comprehensive contract test suites.
  - Full reproducible 7-step Causal Acceptance Test (`test_causal_drought_experiment`):
    - Drought scenario leads to rapid plant decay, food collapse, and herbivore starvation deaths.
    - Control scenario under identical seed maintains high biomass, healthy herds, and zero starvation deaths.
  - Test runner (`tests/test_runner.gd`): **28 Passed across 8 suites, 0 Failed**.
  - Executed windowed Vulkan 1.4 Forward+ benchmark (`tests/benchmark_world.gd`) on Intel Iris Xe Graphics (1280x720):
    - Sampled Frames: 165
    - Average FPS: **27.3 FPS** (exceeds playable target on integrated GPU)
    - Max Draw Calls: 1268
    - Max Primitives: 1,309,662
    - Static Memory: 72.44 MB
    - Entities Tracked: 127
    - Console Errors: 0
  - Captured authentic runtime screenshot: `screenshot_block_4.png` (1280x720).

### BLOCK 5 — Experiment Tools, Observability & Save/Load (COMPLETED)
- **Interactive Player Experiment Tools (`res://presentation/tools/player_tool_controller.gd`):**
  - Implemented 7 fully functional player sandbox tools:
    1. `INSPECT` [1]: Raycasts onto terrain and entities within 3.5m, returning entity species, ID, health, energy, biomass, life stage, state, and local microclimate.
    2. `+ MOISTURE` [2]: Area brush (+20% moisture) within configurable radius (default 8.0m) modifying `EnvironmentalGrid` cells.
    3. `- MOISTURE` [3]: Area brush (-20% moisture) drying bounded cells and reclassifying biomes.
    4. `+ PLANT` [4]: Spawns shrubs/grass with physical boundary and water-level validation.
    5. `+ DEER` [5]: Spawns herbivores on habitable terrain above water level.
    6. `+ STALKER` [6]: Spawns apex predators on habitable terrain.
    7. `DELETE ENTITY` [7]: Despawns targeted entity from simulation, registry, and metrics.
  - 3D Torus Brush Indicator (`ToolBrushVisual3D`): Dynamic in-world ring following terrain surface with tool-specific color coding and radius scaling.
  - Physical boundary validation: Prohibits placement submerged in ocean or outside island bounds ($< 68\text{m}$).
- **World Persistence Schema v2 (`res://core/persistence/world_persistence.gd`):**
  - Full simulation serialization: Seed, GenerationConfig, discrete clock, Markov weather state and duration, 1024 environmental grid cell moistures and temperatures, flora instances, fauna instances, telemetry counters, and registry entries.
  - Atomic write strategy: Writes to `<path>.tmp`, flushes, rotates existing save to `<path>.bak`, and atomically renames `.tmp`.
  - Fault tolerance & schema validation: Detects corrupted JSON and automatically falls back to `.bak`. Rejects missing mandatory keys or future schema versions.
  - Backward compatibility: Seamlessly loads Schema v1 saves.
- **Observability Dashboard & Live Charting (`res://presentation/ui/`):**
  - `WorldHUD` (`hud.gd`):
    - Top header: Simulation clock, day phase, Play/Pause (`[Space]`), time dilation buttons (`0.5x`, `1.0x`, `2.0x`, `5.0x`), QuickSave (`[F5]`), QuickLoad (`[F9]`), Reset World, Hide HUD (`[H]`).
    - Left sidebar: Tool palette with active tool modulate highlight and radius adjustments (`[`, `]`).
    - Right sidebar: Tabbed panel with Telemetry, Inspector Card, and Simulation Event Log (`[HH:MM]` timestamps).
    - Toast feedback banner: 2.5s popup for tool actions, saves, loads, and validation errors.
  - `EcosystemChart` (`ecosystem_chart.gd`):
    - Native `Control._draw()` polyline rendering over a 40-sample rolling history buffer in `EcosystemMetrics`.
    - Real curves for plant biomass (green), deer (amber), and stalkers (red). Zero placeholder data.
- **Testing & Verification:**
  - Added `tests/test_experiment_tools_and_persistence.gd` covering:
    - Schema v2 save/load roundtrip with 100% fidelity.
    - Corrupt JSON and automatic backup fallback.
    - Schema validation (missing fields and future version rejection).
    - Atomic write and backup rotation.
    - Clean world reset (zero ghost entities, clock zeroed, seed updated).
    - Moisture brush localized impact (distant cells unaffected).
    - Entity spawn, inspect, and delete tools.
  - Automated test runner (`tests/test_runner.gd`): **34 Passed across 9 suites, 0 Failed**.
  - Windowed Vulkan 1.4 Forward+ benchmark (`tests/benchmark_world.gd`) on Intel Iris Xe Graphics (1280x720):
    - Sampled Frames: 165
    - Average FPS: **27.0 FPS** (Min: 1.0 warmup, Max: 33.0 FPS)
    - Max Draw Calls: 1316 (under 1500 ceiling)
    - Max Primitives: 1,311,292
    - Static Memory: 75.76 MB
    - Entities Tracked: 72
    - Console Errors: 0
  - Captured authentic runtime screenshot: `screenshot_block_5.png` (1280x720).

### BLOCK 6 — Performance, Stability & Regression (COMPLETED)
- **Reproducible Multi-Tier Benchmark Suite (`res://tests/benchmark_suite.gd`):**
  - Implemented automated multi-tier benchmark with fixed seed (`1337`), 25-frame warmup, 160-frame measurement over automated 360° orbital camera path.
  - Three distinct workload tiers:
    - `--light`: 25 plants, 6 herbivores, 1 predator (948 draw calls, 29.3 FPS, 34.2 ms avg frame time).
    - `--target`: 55 plants, 14 herbivores, 2 predators (1,009 draw calls, 30.8 FPS, 32.5 ms avg frame time, 47.2 ms p95).
    - `--stress`: 140 plants, 38 herbivores, 6 predators (1,012 draw calls, 30.5 FPS, 32.8 ms avg frame time, 51.4 ms p95).
- **Evidence-Based Hardware Optimizations (Intel Iris Xe):**
  - **Shadow Cascade Clamping:** Reduced `directional_shadow_max_distance` from 180.0m to 95.0m in `scenes/main.tscn`, matching island radius (68m). Enabled `directional_shadow_blend_splits` and `directional_shadow_fade_start = 0.85`. Eliminated 514 draw calls and 553,000 primitives from shadow passes over empty ocean.
  - **Shared Mesh & Material Pools:** Instantiated class-level shared static `StandardMaterial3D` and `Mesh` resource dictionaries in `EcosystemPresentation`, eliminating per-spawn allocations and Vulkan pipeline state churn.
  - **Selective Shadow Culling:** Disabled shadow casting (`SHADOW_CASTING_SETTING_OFF`) for high-density ground micro-vegetation (`grass_patch`), preserving dynamic shadows for shrubs, trees, herbivores, and predators.
  - **Scale Dirty Caching:** Added `_plant_scales` threshold check ($>0.02\text{ kg}$ biomass delta), eliminating 55+ redundant per-frame scene graph transform dirties.
  - **Entity ID Partitioning:** Partitioned ID spaces (`1..999` props, `1000..1999` fauna, `2000..4999` flora) and added explicit despawn sweeps to `FloraSimulation.clear()` and `FaunaSimulation.clear()`, preventing registry collisions.
- **Optimization Impact on Intel Iris Xe (Target Tier):**
  - Max Draw Calls: **1,523 -> 1,009** (-33.7%, well below 1,500 target ceiling).
  - Max Primitives: **1,376,164 -> 822,834** (-40.2%).
  - p95 Frame Time: **76.33 ms -> 47.24 ms** (-38.1% variance reduction).
  - Average FPS: **30.8 FPS** maintained smoothly.
  - Static Memory: **76.25 MB -> 74.43 MB** (-1.82 MB).
- **Stability & Regression Test Suite (`res://tests/test_stability_and_regression.gd`):**
  - Implemented 6 stress and edge-case contracts:
    1. `test_rapid_pause_resume_cycles`: 50 rapid toggle cycles with zero sim time leakage.
    2. `test_repeated_save_load_stress`: 5 consecutive save/load roundtrips with zero drift in biomass or populations.
    3. `test_rapid_world_resets`: 10 rapid world resets with clean entity purging and zero dangling references.
    4. `test_mass_starvation_and_collapse_event`: Total desert collapse verifies mortality dynamics and graceful extinction handling without crashing.
    5. `test_population_boom_and_carrying_capacity`: Exponential population growth bounded cleanly at 200 carrying capacity cap.
    6. `test_invalid_inputs_and_edge_cases`: Handles NaN/Inf coords, corrupt schemas, null registry queries, and negative deltas safely.
- **Testing & Verification:**
### BLOCK 7 — Visual Polish, UX & Gameplay Feedback (COMPLETED)
- **Art Direction & Terrain Shading:**
  - Enhanced `IslandTerrain` procedural vertex coloring with dynamic slope cliff blending (steepness $>0.38$ blends to weathered cliff rock), warm shoreline sand ($h < 1.1\text{m}$), and alpine summit snow ($h > 12.0\text{m}$).
  - Introduced micro simplex noise modulation ($\pm 3.5\%$) eliminating low-poly cell color banding.
- **Atmospheric Perspective & Celestial Distance Fog:**
  - Configured volumetric depth distance fog in `WorldEnvironment` ($35\text{m} \to 140\text{m}$) eliminating sharp horizon pop-in.
  - Coupled fog color to diurnal celestial horizon light in `DayNightCycle`, transitioning from warm golden sunrise to bright noon and moonlit midnight.
- **Exploration Camera Refinements:**
  - Ground and ocean collision clearance clamping: enforces $y \ge \text{terrain} + 0.9\text{m}$ and $y \ge 0.85\text{m}$ above ocean surface, preventing camera from dipping underwater or clipping through geometry.
  - Added mouse scroll wheel flight speed adjustment ($8.0 \to 38.0\text{ m/s}$).
- **State-Driven Fauna Animations:**
  - Implemented authentic behavioral procedural animations in `EcosystemPresentation` reflecting exact simulation states:
    - Herbivores: `RESTING` (lowered body bob), `EATING` (head dipping and chewing), `FLEEING` (rapid forward hop sprint), `STARVING` (trembling shivering), `WANDERING` (gentle walk hop).
    - Predators: `HUNTING` (low stalking crouch), `EATING` (head lowered to kill), `RESTING` (flat breathing), `STARVING` (shivering).
- **Interactive Tool Pulses & Causal Feedback:**
  - Added transient animated 3D pulse rings on player interventions that expand and fade over 0.35s at target point.
  - Pre-allocated unshaded cyan TorusMesh (`InspectionSelectionRing`) in `EcosystemPresentation` tracking inspected entity.
  - Formatted ASCII vitality and metabolism bars in inspector card with explicit ecological status explanations.
- **Main Menu, Settings & In-Engine HUD:**
  - Centered glassmorphic modal (`[Esc]`) featuring Simulation controls (Resume, Re-roll, QuickSave, QuickLoad, Reset, Quit), Settings (Windowed/Fullscreen, Fog toggle, Camera Sensitivity slider, Flight Speed slider), and Controls/Guide tab (`[F1]`).
- **Testing & Visual QA:**
  - Implemented `tests/test_visual_polish_and_ux.gd` with 5 contract tests: modal toggle, camera clearance, inspector vitals formatting, selection highlight, tool pulse lifecycle.
  - Test runner (`tests/test_runner.gd`): **45 Passed across 11 suites, 0 Failed**.
  - Captured 7 authentic runtime screenshots (`screenshot_block_7_*.png`) covering panorama, closeup, midnight, fauna, UI, intervention, and menu modal.

### BLOCK 8 — Release Candidate, Reproducible Build & Final Handoff (COMPLETED)
- **Windows Release Build & Export Packaging:**
  - Installed official Godot 4.6.3 export templates into `$env:APPDATA\Godot\export_templates\4.6.3.stable\`.
  - Configured `export_presets.cfg` for Windows Desktop Release (preset name `Windows_Desktop`, architecture `x86_64`, embedded PCK).
  - Built reproducible standalone release binary: `build/release/LivingPlanetSandbox.exe`.
  - Zero-debris packaging: verified no developer caches, temporary logs, or scratch files included.
- **Standalone Runtime Verification:**
  - Executed standalone release binary smoke tests verifying launch, world generation, simulation progression, save/load persistence, and clean exit.
- **License & Asset Audit:**
  - Completed `THIRD_PARTY_COMPONENTS.md` verifying 100% clean-room procedural assets and permissive MIT licensing across Godot Engine, shaders, and GDScript code.
- **Documentation & Verification Suite:**
  - Completed all 9 core durable documents: `README.md`, `PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, `CURRENT_STATE.md`, `WORK_LOG.md`, `DECISIONS.md`, `THIRD_PARTY_COMPONENTS.md`, `TESTING.md`, `ROADMAP.md`.
  - Verified 100% test pass rate (45/45 tests passing across 11 suites) and collected empirical Iris Xe benchmark metrics.
  - Zero git commits or pushes made.

## 2026-10-14 — OVERNIGHT EXECUTION ORCHESTRATION

### BLOCK 1 — Camera và Khám phá Thế giới (COMPLETED)
- **Multi-Mode Camera Exploration Architecture (`res://presentation/camera/free_look_camera.gd`):**
  - Expanded `FreeLookCamera` into a unified exploration system supporting 4 robust exploration modes:
    1. `FREE_LOOK`: 6-DOF free flight navigation with smooth damping, scroll-wheel speed control ($8 \to 38\text{ m/s}$), and terrain/ocean clearance protection ($y \ge \text{terrain} + 0.9\text{m}$, $y \ge 0.85\text{m}$).
    2. `ORBIT_INSPECT`: Spherical orbit around static targets or points of interest with spherical coordinates (azimuth, elevation, distance), mouse look rotation, and scroll zoom clamping ($2.0 \to 38.0\text{m}$).
    3. `FOLLOW_ENTITY`: Smooth dynamic third-person tracking camera locked onto living creatures (`_follow_node` or `_follow_callable`). Tracks moving animals as they graze, forage, or hunt across the landscape; gracefully falls back to `ORBIT_INSPECT` if entity despawns.
    4. `TOP_DOWN`: High-altitude tactical overview ($48\text{m}$ altitude, pitch $-85^\circ$) with planar WASD panning and scroll zoom ($18 \to 65\text{m}$) for god-game ecological observation.
  - Smooth Ease-In-Out transitions between modes and camera viewpoints ($0.6 \to 0.8\text{s}$ duration).
  - Out-of-tree safe mathematical fallback for `look_at_target` and entity node queries, ensuring 100% testability.
- **Scenic POI Bookmarks:**
  - Configured 5 predefined scenic viewpoints:
    1. `Island Panorama`: Northwest high scenic vantage.
    2. `Summit Monolith`: Orbit vantage around the ancient stone monolith altar.
    3. `Emerald Meadows`: Low-angle pasture view of living herbivore herds.
    4. `Coastal Shoreline`: Low vantage looking at the waterline and sandy beach.
    5. `Tactical Overview`: Straight down overhead tactical map.
  - Cycling via `[B]` key or HUD button.
- **Compass & Orientation Telemetry:**
  - Calculated exact horizontal yaw heading degrees ($0^\circ \to 360^\circ$ where $0^\circ = \text{North}$, $90^\circ = \text{East}$, $180^\circ = \text{South}$, $270^\circ = \text{West}$).
  - 8-wind cardinal string lookup (`N`, `NE`, `E`, `SE`, `S`, `SW`, `W`, `NW`).
- **HUD & UX Integration (`res://presentation/ui/hud.gd`):**
  - Top bar: Live compass readout (`🧭 NW 315°`), Camera Mode button (`🎥 Free [V]`), and Viewpoints button (`📍 POI [B]`).
  - Inspector card: Added `[🎯 Track Entity #ID [F]]` action button allowing one-click camera lock onto inspected herbivores/predators.
  - Hotkeys: `[V]` cycles camera modes; `[B]` cycles scenic viewpoints; `[F]` toggles tracking on inspected entities.
  - Toast feedback for mode changes, viewpoints reached, and tracked entity loss.
- **Ecosystem Presentation Hooks (`res://presentation/ecosystem/ecosystem_presentation.gd`):**
  - Added `get_entity_node(id)` and `get_entity_position(id)` enabling decoupled presentation queries.
- **Testing & Verification:**
  - Created `tests/test_camera_exploration.gd` with 7 contract tests:
    1. `test_camera_modes_enum_and_defaults`: Enum validation and mode names.
    2. `test_free_look_movement_and_clearance`: Minimum clearance and horizontal boundary clamping.
    3. `test_orbit_inspect_math_and_zoom`: Spherical orbit calculation and scroll zoom.
    4. `test_follow_entity_tracking`: Dynamic tracking of moving nodes and graceful fallback on entity loss.
    5. `test_top_down_mode_navigation`: Downward pitch lock, altitude bounds, planar panning.
    6. `test_scenic_bookmarks_and_transitions`: All 5 viewpoints and mode transitions.
    7. `test_compass_heading_and_cardinals`: Exact mathematical cardinal directions.
  - Registered suite in `tests/test_runner.gd`: **53 Passed across 12 suites, 0 Failed**.
  - Verified benchmark suite: **44.5 Avg FPS**, 7.00 ms avg frame time on Target Workload.
  - Verified release smoke test: **7/7 Passed**.

### BLOCK 2 — Gene, Di truyền và Chọn lọc Tự nhiên (COMPLETED)
- **Decoupled Genome Architecture (`res://core/ecosystem/genome.gd`):**
  - Implemented `EcosystemGenome` class representing heritable genotypes and phenotypic expressions for living entities:
    - **Fauna alleles:** `speed_mult` ($0.70 \to 1.50$), `metabolism_efficiency` ($0.70 \to 1.40$), `size_scale` ($0.75 \to 1.35$), `perception_radius` ($16.0 \to 44.0\text{m}$), and `coat_tint` (visual coloration).
    - **Flora alleles:** `drought_tolerance` ($0.10 \to 0.40$ min soil moisture), `growth_rate_mult` ($0.60 \to 1.50$), `seed_spread_radius` ($4.0 \to 14.0\text{m}$), and `foliage_tint` (visual pigment).
    - **Biological trade-offs:** Higher speed increases metabolic calorie burn rate ($P \propto \text{speed}^{1.4}$); larger size increases hunger demand; drought-resistant plants experience slightly lower peak growth rate during wet seasons; wide perception incurs cognitive energy overhead.
    - **Mutation & Lineage:** Controlled mutation with configurable rate (15%) and variance (8%), bounding traits within viable physiological ranges. Generational counters (`generation`) and parent tracking (`parent_id`) for lineage tracing.
    - **Full Serialization:** `to_dict()` and `from_dict()` for lossless persistence and save-state roundtripping.
- **Flora Simulation Genetics Integration (`res://core/ecosystem/flora_simulation.gd`):**
  - Plants store and pass their individual `EcosystemGenome`.
  - Growth and drought stress decay rates are governed by genome alleles. Plants with higher drought tolerance survive harsher soil aridity, while high-growth variants flourish rapidly under abundant moisture.
  - Offspring seeds inherit mutated parent genomes and disperse across `seed_spread_radius`.
- **Fauna Simulation Genetics Integration (`res://core/ecosystem/fauna_simulation.gd`):**
  - Herbivores and predators store individual `EcosystemGenome`.
  - Movement speed scales with `speed_mult`; calorie burn scales dynamically with speed and metabolism efficiency.
  - Perception radius for food and threat detection dynamically scales with `perception_radius`.
  - Offspring inherit parent genome with mutations, advancing the entity's `generation` counter.
- **Ecosystem Presentation Phenotypic Rendering (`res://presentation/ecosystem/ecosystem_presentation.gd`):**
  - Entity visual models physically scale in 3D according to `size_scale`.
  - Procedural material overrides apply heritable coat and foliage tints (`coat_tint` on animal meshes, `foliage_tint` on plant meshes) with individual distinct visual variety across generations.
- **HUD Genetic Telemetry & Inspector (`res://presentation/ui/hud.gd`):**
  - Telemetry bar displays live ecosystem genetics: Average Herbivore Speed (`Avg Spd`), Average Plant Drought Tolerance (`Avg Drg`), and Maximum Lineage Generation (`Max Gen`).
  - Inspector card displays detailed Gene Card: Species, Generation, Speed mult, Metabolism efficiency, Size scale, Perception radius, and Drought tolerance.
- **Schema v2 Backward-Compatible World Persistence (`res://core/persistence/world_persistence.gd`):**
  - Serializes `genome` dictionaries alongside flora and fauna entities.
  - Implements automatic migration: legacy saves without genomes gracefully synthesize default Gen 1 baseline genomes, preserving 100% save-file compatibility.
- **Testing & Verification:**
  - Created `tests/test_genetics_and_selection.gd` with 5 contract tests:
    1. `test_genome_initialization_and_tradeoffs`: Validates default alleles, trade-off formulas, and bounds.
    2. `test_genome_mutation_and_inheritance`: Validates reproduction mutation, generation advancement, and parent ID tracking.
    3. `test_genome_serialization_roundtrip`: Verifies 100% lossless dictionary roundtripping.
    4. `test_flora_inheritance_and_drought_selection`: Demonstrates natural selection where drought-tolerant plants survive arid soil while intolerant plants wither.
    5. `test_fauna_inheritance_and_speed_selection`: Validates heritable speed inheritance across generations and trait-driven metabolic burn.
  - Test runner: **58 Passed across 13 suites, 0 Failed**.
  - Release smoke test: **7/7 Passed**.
