# ROADMAP — Living Planet Sandbox
## Project Execution & Milestone Tracker

Living Planet Sandbox is developed across 8 structured milestones with rigorous quality gates, automated testing, and target hardware verification on Windows 11 with Intel Iris Xe integrated graphics.

---

### Milestone Status Overview

- [x] **BLOCK 0: Repository Reconnaissance & Technical Selection**
  - Inspected 9 repository candidates and architectural archetypes.
  - Formulated architectural decision: Clean Godot 4 + GDScript + selective module reuse.
  - Established offline-first, Windows-first, Intel Iris Xe hardware constraints.

- [x] **BLOCK 1: Environment Setup, Repository Preflight & Project Foundation**
  - Verified Godot 4.6.3 toolchain and Git tracking.
  - Implemented core decoupled architecture contracts: `WorldBootstrap`, `WorldSeed`, `WorldClock`, `WorldEventBus`, `EntityRegistry`, `SimulationScheduler`, `WorldPersistence`, `PerformanceMonitor`.
  - Established automated headless test runner (Suites 1–5: 11 tests passing).

- [x] **BLOCK 2: First Playable World & Visual Quality Gate**
  - Implemented free-look 3D exploration camera with smooth damping.
  - Built bounded procedural island terrain with dual-octave heightmap.
  - Implemented depth-clipped Gerstner wave ocean shader and dynamic celestial day/night dome.
  - Multi-mesh instanced foliage scatter (pine trees, rocks, grass patches).
  - Passed Suite 6 (TestPlayableWorld: 4 tests).

- [x] **BLOCK 3: Modular World Generation & Environmental Systems**
  - Deterministic procedural world generation with isolated sub-RNG streams.
  - Discrete 32x32 environmental simulation grid (soil moisture, temperature, biome classification).
  - 4-state Markov chain weather system (Clear, Overcast, Rain, Storm) coupled to moisture accumulation and evaporation.
  - Diurnal celestial cycle (Sun, Moon, Ambient energy, Horizon atmospheric tinting).
  - Passed Suite 7 (TestEnvironmentSystems: 6 tests).

- [x] **BLOCK 4: Living Ecosystem & Causal Simulation**
  - Decoupled discrete 2Hz simulation loop independent of render framerate.
  - Spatial partitioning grid (8x8 cells) with O(1) grazing and hunting lookups.
  - Flora simulation: growth stages, biomass, health, water/temperature affinity, propagation, and decay.
  - Herbivore simulation: metabolic decay, grazing, starvation, reproduction, and fleeing.
  - Predator simulation: stamina, hunting behavior, threat radius, and territorial roaming.
  - Causal drought verification experiment proving verifiable ecological causality.
  - Passed Suite 8 (TestCausalEcosystem: 7 tests).

- [x] **BLOCK 5: Player Experiment Tools, Observability & Save/Load**
  - Decoupled `PlayerToolController` with 3D physical raycasting and surface ring visualization.
  - 7 interactive tools: Inspect, +Moisture Brush, -Moisture Brush, +Plant, +Deer, +Stalker, Delete Entity.
  - Glassmorphic HUD with time controls (0.5x, 1x, 2x, 5x, Pause), seed display, and live event log.
  - Authentic rolling-window population & biomass line chart via CanvasItem `_draw()`.
  - Schema v2 complete state serialization with atomic file writing (`.tmp`), backup rotation (`.bak`), and fallback recovery.
  - Passed Suite 9 (TestExperimentToolsAndPersistence: 6 tests).

- [x] **BLOCK 6: Performance Profiling, Stability & Regression**
  - Empirical benchmarking on Windows 11 with Intel Iris Xe integrated graphics.
  - Profiling revealed draw call bottlenecks (1,523 peak draw calls, 1.37M primitives).
  - Implemented shadow distance clamping (95m), shared static resource flyweights, and micro-vegetation shadow disabling.
  - Reduced draw calls by 33.7% (1,009 peak), primitives by 40.2% (822k peak), and p95 frame time by 38.1% (47.24 ms).
  - Stress testing: rapid pause/resume, repeated save/load, mass starvation, and population boom.
  - Passed Suite 10 (TestStabilityAndRegression: 6 tests).

- [x] **BLOCK 7: Visual Polish, UX & Gameplay Feedback**
  - Refined terrain vertex shading: slope cliff rock blending, shoreline beach sand, summit snow dusting.
  - Atmospheric depth distance fog ($35\text{m} \to 140\text{m}$) synced with diurnal celestial horizon color.
  - Camera collision clearance clamping above terrain and water; scroll-wheel flight speed control ($8 \to 38\text{ m/s}$).
  - Authentic behavioral fauna animations: resting, eating, sprinting, shivering/starving, stalking.
  - Transient 3D tool pulse rings on intervention, in-world cyan selection ring, and ASCII vitality/metabolism inspector bars.
  - In-engine glassmorphic Menu & Settings modal (`[Esc]`) with Simulation controls, functional Settings, and Controls/Guide tab (`[F1]`).
  - Passed Suite 11 (TestVisualPolishAndUX: 5 tests; total 45/45 passing).
  - Captured 7 authentic runtime screenshots.

- [x] **BLOCK 8: Release Candidate, Reproducible Build & Final Handoff** *(Current)*
  - Windows Desktop x64 Release export configuration (`export_presets.cfg`).
  - Installation of official Godot 4.6.3 export templates.
  - Standalone release packaging into `build/release/LivingPlanetSandbox.exe`.
  - Zero-debris release packaging with clean-room license manifest (`THIRD_PARTY_COMPONENTS.md`).
  - Standalone binary runtime verification and smoke testing.
  - Comprehensive documentation handoff (`README.md`, `ARCHITECTURE.md`, `CURRENT_STATE.md`, etc.).
