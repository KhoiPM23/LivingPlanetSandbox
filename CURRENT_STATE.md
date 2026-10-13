# CURRENT STATE — Living Planet Sandbox
## Release Candidate Status (Block 8/8)

---

### 1. Phase Status
- **Current Milestone:** Overnight Orchestration — BLOCK 6 Completed (Regression, Release, Tài liệu và Bàn giao).
- **Engine Version:** Godot Engine v4.6.3.stable.official.7d41c59c4 (Windows x86_64).
- **Renderer:** Forward Plus (Vulkan 1.4.323 on Intel Iris Xe Graphics).
- **Git Branch:** `main`.
- **Remote Origin:** `https://github.com/KhoiPM23/LivingPlanetSandbox.git` (tracked).
- **Standalone Release Executable:** `build/release/LivingPlanetSandbox.exe` (127.3 MB, embedded PCK, tested).

---

### 2. Comprehensive Verification Matrix

| Component | Status | Verification Type | Notes |
| :--- | :--- | :--- | :--- |
| **Workspace Scaffolding** | PASS | File System / Git | Initialized `.git`, `.gitignore`, `.gitattributes`, core documentation suite |
| **Godot Toolchain** | PASS | CLI & Runtime | Godot 4.6.3 official executable, export templates in `$env:APPDATA\Godot\export_templates\4.6.3.stable\` |
| **Core Architecture Contracts** | PASS | 11/11 Unit Tests | Decoupled contracts: `WorldSeed`, `WorldClock`, `WorldEventBus`, `EntityRegistry`, `SimulationScheduler`, `WorldPersistence`, `PerformanceMonitor` |
| **Procedural Island Generation** | PASS | Unit Test / Runtime | Seed-reproducible parameters (`island_size`, `max_height`, `roughness`), isolated sub-RNG streams, trimesh collision |
| **Environmental State Grid** | PASS | Unit Test / Runtime | 32x32 macro grid (1024 cells) with soil moisture, surface temperature, elevation lapse rate, sun exposure, dynamic fertility & temp modifiers |
| **Dynamic Weather State Machine** | PASS | Unit Test / Runtime | 4 states (`CLEAR`, `CLOUDY`, `RAIN`, `DROUGHT`) with Markov transitions, solar attenuation, precipitation |
| **Whittaker Biome Classifier** | PASS | Unit Test / Runtime | 7 biomes (`OCEAN`, `COASTAL_BEACH`, `WETLAND`, `TEMPERATE_MEADOW`, `BOREAL_FOREST`, `ALPINE_SUMMIT`, `ARID_SHRUBLAND`) with explainable rationale |
| **Causal Flora Simulation** | PASS | Unit Test / Runtime | Plant life cycle, biomass growth from moisture & sunlight & fertility, drought/heatwave/frost stress, reproduction spreading, spatial hash |
| **Causal Fauna Simulation** | PASS | Unit Test / Runtime | Herbivore (`island_deer`) & Predator (`mountain_stalker`) state machines, metabolism, grazing, hunting, predation, starvation |
| **Genome & Natural Selection** | PASS | Unit Test / Runtime | Heritable traits (speed, metabolism, size, perception, drought tolerance, tints), trade-offs, offspring mutation, generational lineage |
| **Weather, Wind & Surface Reaction** | PASS | Unit Test / Runtime | 2D wind vector, harmonic gusts, wind-slanted rain particles, surface wetness gloss/darkening, Gerstner wind waves & rain ripples |
| **Graphics Presets & Evolution Telemetry** | PASS | Unit Test / Runtime | Scalable profiles (Low, Balanced/Iris Xe, High); allele variance, Shannon diversity index ($D$), genetic bottleneck warning, evolution snapshots |
| **Climate Experiment Tools** | PASS | Unit Test / Runtime | 11 interactive tools: Heatwave `[8]`, Frost `[9]`, Fertilizer `[0]`, Disaster Shock `[-]`, Moisture `[2]/[3]`, Inspect `[1]`, Spawners `[4-6]`, Delete `[7]` |
| **Causal Cascade Tracking & Telemetry** | PASS | Unit Test / Runtime | `CausalTracker` correlating player interventions to vegetation mortality, blooming, herbivore starvation, and displaying in HUD/Inspector |
| **Visual Polish & Shading** | PASS | Runtime Vulkan | Slope-dependent rock cliff vertex blending ($>0.38$), warm shoreline sand ($h < 1.1\text{m}$), alpine snow summits ($h > 12.0\text{m}$), simplex organic noise |
| **Atmospheric Depth Perspective** | PASS | Runtime Vulkan | Volumetric depth distance fog ($35\text{m} \to 140\text{m}$) synced with diurnal celestial horizon light color |
| **Multi-Mode Camera Exploration** | PASS | Unit Test / Runtime | 4 modes (`FREE_LOOK`, `ORBIT_INSPECT`, `FOLLOW_ENTITY`, `TOP_DOWN`), 5 scenic bookmarks, live compass telemetry, smooth easing |
| **State-Driven Fauna Animations** | PASS | Runtime Vulkan | Procedural animations reflecting simulation state: resting, grazing, sprinting, shivering/starving, stalking |
| **In-Engine Menu Modal & Settings** | PASS | Unit Test / Runtime | Centered glassmorphic modal (`[Esc]`) with Simulation controls (Resume, Re-roll, Save, Load, Reset, Quit), functional Settings, and Controls/Guide tab (`[F1]`) |
| **Schema v2 World Persistence** | PASS | Unit Test / Runtime | Complete state serialization (seed, clock, weather with wind vector, 1024 cells with fertilities, flora, fauna with genomes, metrics, interventions) |
| **Observability Dashboard & HUD** | PASS | Runtime Vulkan | Glassmorphic HUD: clock, compass, weather cycle button `[Y]`, live wind & wetness telemetry, camera modes, POI selector, tool palette, Inspector, charts |
| **Automated Test Runner** | PASS | Headless Test Suite | All 16 suites, 74 contract tests passing with 0 failures |
| **GPU Performance Optimization** | PASS | Vulkan 1.4 Benchmark | Draw calls cut -33.7% (1,009 peak), primitives cut -40.2% (822k peak), p95 frame time 47.24 ms on Intel Iris Xe; 41.5 average FPS |
| **Windows Release Export** | PASS | CLI & Standalone Executable | Compiled Windows x64 release package at `build/release/LivingPlanetSandbox.exe` |
| **Visual QA Capture** | PASS | Viewport Capture | 7 authentic runtime screenshots captured from Vulkan Forward+ runtime |
