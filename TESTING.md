# TESTING STRATEGY & RESULTS — Living Planet Sandbox

## 1. Test Philosophy
- **Deterministic & Automated:** Core simulation contracts (`WorldSeed`, `WorldClock`, `EntityRegistry`, `WorldPersistence`, `WorldEventBus`) and world generation contracts execute in headless mode via `godot --headless --script res://tests/test_runner.gd`.
- **Zero Heavy Test Frameworks:** Minimal, zero-overhead standalone test runner written in GDScript to eliminate third-party test framework friction.
- **Verification Levels:**
  1. Static analysis & class registration (`godot --headless --editor --quit`).
  2. Automated unit/contract tests (`godot --headless --script res://tests/test_runner.gd`).
  3. Standalone test suite execution (`godot --headless --script res://tests/test_playable_world.gd`).
  4. Runtime GPU benchmark & live screenshot capture (`godot --script res://tests/benchmark_world.gd`).

## 2. Test Execution Commands
```powershell
# Run full automated test suite (Headless)
cmd.exe /c "godot --headless --script res://tests/test_runner.gd"

# Run GPU Vulkan performance benchmark (Windowed)
cmd.exe /c "godot --script res://tests/benchmark_world.gd"
```

## 3. Test Suite Registry & Results (Block 1 & 2)

| Test Suite | Method | Covered Capabilities | Status |
| :--- | :--- | :--- | :--- |
| `test_world_seed.gd` | `test_seed_determinism` | Seed hashing, repeatable float sequence across instances | **PASS** |
| `test_world_seed.gd` | `test_stream_isolation` | Independent sub-streams for terrain vs. vegetation | **PASS** |
| `test_world_clock.gd` | `test_clock_tick_advancement` | Discrete 10Hz tick counting and elapsed simulation seconds | **PASS** |
| `test_world_clock.gd` | `test_clock_pause` | Clock halting on pause and clean resume | **PASS** |
| `test_world_clock.gd` | `test_clock_time_scale` | 2.0x time dilation tick proportionality | **PASS** |
| `test_world_event_bus.gd` | `test_event_bus_pub_sub` | Payload dispatch, multiple subscriber isolation, unsubscription | **PASS** |
| `test_world_event_bus.gd` | `test_event_bus_signals` | Typed Godot signal emission and data delivery | **PASS** |
| `test_entity_registry.gd` | `test_spawn_and_retrieve` | Entity ID sequencing, component dictionary storage | **PASS** |
| `test_entity_registry.gd` | `test_update_and_despawn` | In-place attribute mutation, index purging, cleanup | **PASS** |
| `test_world_persistence.gd` | `test_save_and_load_roundtrip` | Full JSON serialization and Vector3 restoration | **PASS** |
| `test_world_persistence.gd` | `test_backup_rotation` | Atomic save promotion and `.bak` rotation | **PASS** |
| `test_playable_world.gd` | `test_terrain_elevation_and_shape` | Island elevation formula, dry land base, summit peak height | **PASS** |
| `test_playable_world.gd` | `test_terrain_collision_and_boundaries` | Concave trimesh collision generation and 4 perimeter wall barriers | **PASS** |
| `test_playable_world.gd` | `test_water_plane_and_shader` | PlaneMesh configuration, Gerstner wave shader assignment | **PASS** |
| `test_playable_world.gd` | `test_vegetation_scatter_and_instancing` | Scatter placement, summit monolith, MultiMesh grass, registry tracking | **PASS** |
| `test_environment_systems.gd` | `test_generation_config_validation` | Seed clamping, config validation, dictionary serialization | **PASS** |
| `test_environment_systems.gd` | `test_seed_generation_reproducibility` | Stream isolation, determinism across identical seeds, divergence across different seeds | **PASS** |
| `test_environment_systems.gd` | `test_environmental_grid_ranges` | Grid cell bounds, temperature, moisture, and water availability sanity ranges | **PASS** |
| `test_environment_systems.gd` | `test_diurnal_cycle_simulation` | Thermal lag diurnal swing, day vs night temperature differential | **PASS** |
| `test_environment_systems.gd` | `test_weather_system_state_machine_and_effects` | Weather transitions, solar attenuation, precipitation moisture rates, event bus broadcast | **PASS** |
| `test_environment_systems.gd` | `test_biome_classification_consistency` | Whittaker logic consistency, coastal vs summit vs wetland classification, explainability | **PASS** |
| `test_causal_ecosystem.gd` | `test_plant_growth_and_decay` | Biomass accumulation under optimal moisture & sunlight, drought stress decay | **PASS** |
| `test_causal_ecosystem.gd` | `test_herbivore_resource_consumption_and_metabolism` | Grazing biomass intake, energy recovery, starvation in barren lands | **PASS** |
| `test_causal_ecosystem.gd` | `test_predator_threat_and_predation` | Herbivore fleeing response, predator hunting chase, lethal catch, energy restoration | **PASS** |
| `test_causal_ecosystem.gd` | `test_reproduction_and_population_dynamics` | Adult herbivore reproduction threshold, juvenile offspring birth | **PASS** |
| `test_causal_ecosystem.gd` | `test_causal_drought_experiment` | Paired 70-step experiment: drought induces withering & starvation vs control flourishing | **PASS** |
| `test_causal_ecosystem.gd` | `test_ecosystem_pause_and_time_scale` | Simulation freeze on WorldClock pause, proportional time dilation advancement | **PASS** |
| `test_causal_ecosystem.gd` | `test_performance_scaling` | Stress test with 120 plants + 35 herbivores + 6 predators runs < 8.0ms per tick | **PASS** |
| `test_experiment_tools_and_persistence.gd` | `test_save_and_load_roundtrip_v2` | Schema v2 roundtrip: restores seed, clock, weather, grid cells, flora, fauna, registry | **PASS** |
| `test_experiment_tools_and_persistence.gd` | `test_corrupted_file_and_schema_validation` | Handles corrupt JSON, automatic .bak recovery, future schema rejection, missing keys | **PASS** |
| `test_experiment_tools_and_persistence.gd` | `test_atomic_save_and_backup_rotation` | Atomic .tmp write, promotion, and .bak rotation validation | **PASS** |
| `test_experiment_tools_and_persistence.gd` | `test_clean_world_reset` | World reset wipes old entities, zero ghost state, clock zeroed, seed updated | **PASS** |
| `test_experiment_tools_and_persistence.gd` | `test_player_moisture_brush_intervention` | Bounded moisture brush modifies local cells, leaves distant cells untouched | **PASS** |
| `test_experiment_tools_and_persistence.gd` | `test_entity_spawn_inspect_and_delete_tools` | Spawns, inspects, and deletes fauna/flora with synchronized registry & metrics | **PASS** |

| `test_stability_and_regression.gd` | `test_rapid_pause_resume_cycles` | 50 rapid pause/resume cycles verify zero simulation time leakage and state integrity | **PASS** |
| `test_stability_and_regression.gd` | `test_repeated_save_load_stress` | 5 consecutive save/load roundtrips verify zero drift in biomass or entity counts | **PASS** |
| `test_stability_and_regression.gd` | `test_rapid_world_resets` | 10 rapid world resets verify clean entity purging and zero dangling references | **PASS** |
| `test_stability_and_regression.gd` | `test_mass_starvation_and_collapse_event` | Extreme zero-biomass desert collapse verifies correct mortality dynamics without crashing | **PASS** |
| `test_stability_and_regression.gd` | `test_population_boom_and_carrying_capacity` | Exponential population growth caps cleanly at maximum carrying capacity (200 fauna) | **PASS** |
| `test_stability_and_regression.gd` | `test_invalid_inputs_and_edge_cases` | Handles NaN/Inf coords, empty schemas, null registry lookups, negative deltas safely | **PASS** |
| `test_visual_polish_and_ux.gd` | `test_menu_modal_toggle_and_tabs` | Modal toggling via [Esc], tab switching, button state validation | **PASS** |
| `test_visual_polish_and_ux.gd` | `test_camera_clearance_and_speed_control` | Terrain and ocean clearance boundary clamping; scroll-wheel flight speed limits | **PASS** |
| `test_visual_polish_and_ux.gd` | `test_inspector_vitals_formatting` | Formatted ASCII vitality/metabolism bars, behavioral status text | **PASS** |
| `test_visual_polish_and_ux.gd` | `test_presentation_selection_highlight` | Pre-allocated selection torus ring tracks inspected entity | **PASS** |
| `test_visual_polish_and_ux.gd` | `test_tool_pulse_feedback_lifecycle` | Transient animated 3D pulse ring instantiation, tween expansion, and cleanup | **PASS** |

**Summary: 45 Passed across 11 suites | 0 Failed | Exit Code 0**

## 4. Reproducible Benchmark Harness (`tests/benchmark_suite.gd`)
A dedicated multi-tier automated benchmark harness measuring render and simulation metrics over reproducible 360° orbital camera paths with fixed seeds:
```powershell
# Run Target tier benchmark (Default: 55 plants, 14 herbivores, 2 predators)
cmd.exe /c "godot --script res://tests/benchmark_suite.gd -- --target"

# Run Light tier benchmark (25 plants, 6 herbivores, 1 predator)
cmd.exe /c "godot --script res://tests/benchmark_suite.gd -- --light"

# Run Stress tier benchmark (140 plants, 38 herbivores, 6 predators)
cmd.exe /c "godot --script res://tests/benchmark_suite.gd -- --stress"
```

### Reproducible Setup:
- **Seed:** Fixed `1337`.
- **Resolution:** 1280 x 720 Windowed.
- **Warmup:** 25 frames (pipeline cache & shader compilation).
- **Measurement:** 160 frames over automated 360° orbital camera trajectory.
- **Hardware:** Intel(R) Iris(R) Xe Graphics (Integrated GPU, 16 GB RAM, Windows 11).
- **Renderer:** Vulkan 1.4.323 Forward+ (`forward_plus`).

### Multi-Tier Benchmark Results (Post-Optimization):
| Metric | Light Tier | Target Tier | Stress Tier |
| :--- | :--- | :--- | :--- |
| **Config Entities** | 25 plants, 6 deer, 1 stalker | 55 plants, 14 deer, 2 stalkers | 140 plants, 38 deer, 6 stalkers |
| **Average FPS** | **29.3 FPS** | **30.8 FPS** | **30.5 FPS** |
| **Min / Max FPS** | 25.0 / 33.0 FPS | 13.0 / 33.0 FPS | 13.0 / 33.0 FPS |
| **Avg Frame Time** | **34.19 ms** | **32.48 ms** | **32.84 ms** |
| **p95 Frame Time** | **39.53 ms** | **47.24 ms** | **51.35 ms** |
| **p99 Frame Time** | **40.00 ms** | **68.97 ms** | **68.97 ms** |
| **Max Draw Calls** | **948** | **1,009** | **1,012** |
| **Max Primitives** | **787,034** | **822,834** | **823,018** |
| **Sim Step Time** | **0.82 ms** | **1.24 ms** | **2.88 ms** |
| **World Gen Time** | **124.6 ms** | **138.2 ms** | **162.4 ms** |
| **Static Memory** | **74.32 MB** | **74.43 MB** | **74.88 MB** |

## 5. Evidence-Based Optimization Results (Target Tier Comparison)

| Metric | Pre-Optimization Baseline | Post-Optimization | Improvement | Impact / Root Cause |
| :--- | :--- | :--- | :--- | :--- |
| **Max Draw Calls** | 1,523 | **1,009** | **-33.7% (-514 calls)** | Reduced shadow max distance from 180m to 95m (island radius 68m); culled distant cascade passes; disabled shadows on high-density grass patches. |
| **Max Primitives** | 1,376,164 | **822,834** | **-40.2% (-553k prims)** | Bounded shadow projection frustum no longer duplicates off-island terrain and ocean geometry across all 4 shadow splits. |
| **p95 Frame Time** | 76.33 ms | **47.24 ms** | **-38.1% (smoother)** | Shared static mesh/material pools eliminated per-frame GPU pipeline rebuilds; cached scale transforms eliminated scene graph dirties. |
| **Simulation Step** | 1.85 ms | **1.24 ms** | **-33.0%** | In-place biomass updates and isolated ID spaces reduced allocation overhead. |
| **Static Memory** | 76.25 MB | **74.43 MB** | **-1.82 MB** | Single shared `StandardMaterial3D` and primitive meshes reused across all flora and fauna instances. |
| **Runtime Errors** | 0 | **0** | **Clean** | Zero console/shader warnings; 40/40 tests passing. |

