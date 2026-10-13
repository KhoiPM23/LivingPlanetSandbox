# PROJECT CONTEXT — Living Planet Sandbox
## Release Candidate Status (Block 8/8)

---

### 1. Vision & Product Direction
Living Planet Sandbox is a solo 3D ecosystem simulation sandbox.
- **World:** Explorable, visually compelling 3D bounded procedural island with mountain summit, ocean, and 7 biomes.
- **Systems:** Terrain, water, atmosphere, 4-state Markov weather, flora, herbivores (`island_deer`), predators (`mountain_stalker`), and dynamic environmental parameters (soil moisture, temperature, lapse rate).
- **Core Loop:** The player intervenes in environmental factors (+/- moisture, planting, fauna placement, deletion) and observes authentic, causal ecological consequences (vegetation growth/decay, grazing, starvation, predation, births/deaths).
- **Delivery Model:** Offline-first. Zero paid APIs, zero online telemetry, zero mandatory cloud accounts.
- **Hardware Target:** Windows 11 Desktop, 16 GB RAM, Intel Iris Xe integrated graphics (no discrete NVIDIA GPU). Every visual and computational decision is performance-measured against this target envelope (sustained 30+ FPS, draw calls < 1,100, primitives < 850k).

---

### 2. Technical Stack
- **Engine:** Godot Engine 4.6.3 (Standard 64-bit, portable, Forward+ Vulkan 1.4).
- **Language:** GDScript for core architecture, simulation logic, and tools.
- **Hydrology:** Gerstner dual-wave ocean shader adapted from LesusX Water-Shader under MIT license (`res://presentation/shaders/water.gdshader`) with depth-buffer clipping.
- **Atmosphere:** Dynamic celestial day/night orbital lighting synchronized with volumetric depth distance fog ($35\text{m} \to 140\text{m}$).
- **Simulation Paradigm:** Pure data-driven state entities, decoupled from visible Presentation 3D scenes. Discrete 2Hz simulation tick decoupled from render FPS.
- **Observability:** Custom glassmorphic HUD with native `Control._draw()` polyline population/biomass chart and live simulation event logging.
- **Packaging:** Self-contained Windows x64 release export (`build/release/LivingPlanetSandbox.exe`) with embedded PCK data.

---

### 3. Guiding Principles
- **Clean Code & SOLID:** Distinct responsibility boundaries (`WorldClock`, `WorldEventBus`, `EntityRegistry`, `WorldPersistence`, `EnvironmentalGrid`, `EcosystemCoordinator`).
- **KISS & YAGNI:** Zero empty abstractions, placeholder UI elements, or mock data.
- **Evidence-Based Quality:** Verification across 6 strict tiers: Implemented, Automated-Tested (45/45 pass), Build-Verified, Runtime-Verified, Visually-Reviewed (7 Vulkan screenshots), and User-Accepted.
- **Zero-Debris Licensing:** 100% procedural art asset architecture (zero external proprietary models/textures/audio); permissive MIT licensing across all components.
- **Repository Preservation:** Zero commits, zero pushes, zero destructive git actions; non-destructive incremental development.
