# LIVINGPLANETSANDBOX — SCREENSHOT INDEX

**Hardware Profile:** Intel Iris Xe Integrated Graphics (1280x720, Balanced Preset, Forward+ Vulkan)  
**Engine:** Godot 4.6.3 Stable  
**Verification Date:** October 18, 2026  

---

## 1. Phase 9 Final Acceptance Matrix Views (`reports/final_acceptance/`)

| Index | View & Filename | Scene Condition & Location | Evaluation | Verified Polish Highlights |
|:---:|---|---|:---:|---|
| **01** | `final_01_opening_panorama.png` | Sunlit Meadow Glade (7.5, 3.5), 10:30 AM, Clear Skies | **PASS** | Clear camera pullback, zero grass clipping, third-person adventurer character, grazing stags, lilac flowering shrubs, granite boulders, and correct "Dawn Chorus" banner. |
| **02** | `final_02_dense_forest_interior.png` | Whispering Forest (-10.0, -10.0), 11:00 AM, High Canopy | **PASS** | Multi-tier evergreen pine canopy, dappled sunlight on mossy needle floor, understory log/stump props, distant deer herd grazing in underbrush. |
| **03** | `final_03_forest_path_depth.png` | Meadow-to-Cove Trail (6.0, 7.5), 13:30 PM, Eye-Level Path | **PASS** | Natural animal trail winding between textured granite monoliths and lilac shrubs with true visual depth into the glade. |
| **04** | `final_04_open_biome_meadow.png` | Central Wildflower Glade (6.0, 1.0), 11:30 AM, High Sun | **PASS** | Expansive continuous grass carpet, multicolored wildflower blooms, soft terrain elevation contours, distant pine silhouettes. |
| **05** | `final_05_biome_transition.png` | Pine Ridge into Sunlit Glade (0.0, -2.0), 14:00 PM | **PASS** | Natural vegetation density gradient from dense boreal conifer forest into open sunny meadow and rocky slope. |
| **06** | `final_06_lake_water_edge_vista.png` | Emerald Cove Shoreline (20.0, 12.0), 15:00 PM | **PASS** | Animated Gerstner water shader with Beer's law depth, floating water lilies, shoreline pebbles, and hero wooden canoe POI. |
| **07** | `final_07_distant_overlook.png` | Summit Ridge Monolith Overlook (-24.0, 28.5, -24.0), 12:30 PM | **PASS** | Majestic 720m island panorama: snow-capped alpine ridge, winding lake basin, pine forest canopy, lilac blossoms, and crisp ocean horizon. |
| **08** | `final_08_midday_lighting.png` | Central Valley (10.0, 5.0), 12:00 PM Midday | **PASS** | High solar elevation, crisp directional shadows under trees and boulders, bright atmospheric illumination, zero shadow acne. |
| **09** | `final_09_golden_hour_lighting.png` | Glade Overlook (8.0, 2.0), 18:30 PM Sunset | **PASS** | Warm amber sunlight, elongated soft shadows, warm atmospheric haze scattering, rich PBR ground surface contrast. |
| **10** | `final_10_night_celestial.png` | Night Meadow (12.0, 6.0), 23:30 PM Midnight | **PASS** | Deep indigo night sky, twinkling procedural stars, soft directional moonlight, dark shadowed trees, deer resting near rock shelter, "Nightfall" banner. |
| **11** | `final_11_representative_gameplay.png` | Third-Person Character Trekking (7.5, 3.5), 14:30 PM | **PASS** | Playable KayKit Adventurer model with cape and hair, animated stride matching, camera clearance, complete HUD controls bar. |
| **12** | `final_12_demanding_scene_perf.png` | Dense Forest Rain Storm (-8.0, -8.0), 16:00 PM | **PASS** | Heavy overcast storm front, wet ground sheen, rain particles, active black wolf predator prowling down pine slope, steady 17.6+ FPS. |

---

## 2. Phase 7 & 8 Immersion & QA Loop Captures (`reports/visual_phase7/`)

| Screenshot Name | Scenario / Condition | Resolution | Verified Polish Highlights |
|---|---|---|---|
| `phase7_01_movement_third_person.png` | Third-Person Character Locomotion & Meadow Spawn | 1280×720 | Correct "Dawn Chorus" banner at 10:32 AM. Character cape, understory flora, stags grazing, clean HUD. |
| `phase7_02_trail_to_monolith_landmark.png` | Trek along Natural Trail toward Whispering Monoliths | 1280×720 | Natural winding path composition, rock formations, canopy sightlines, distant monolith silhouette. |
| `phase7_03_forest_to_meadow_transition.png` | Forest-to-Glade Biome Transition | 1280×720 | Density falloff from dense boreal pines to sunlit clearing, dappled lighting, multi-tier vegetation scatter. |
| `phase7_04_wildlife_stealth_approach.png` | Player Crouch-Stalking Deer Herd | 1280×720 | Stealth posture, lowered camera profile, unalerted grazing deer within 12m, high grass concealment. |
| `phase7_05_wildlife_alarm_reaction.png` | Sprinting Approach & Wildlife Flight Reaction | 1280×720 | Herd alarm state, fleeing animation poses, directional scattering away from player approach path. |
| `phase7_06_weather_rain_storm_state.png` | Overcast Rain & Island Surface Response | 1280×720 | Atmospheric mist, reduced ambient light, ground wetness sheen, wildlife sheltering under boughs. |
| `phase7_07_weather_clear_golden_state.png` | Golden Hour Sunset Lighting | 1280×720 | Warm amber sun angle (sim_hour 18.5), elongated shadows, atmospheric dust haze, high contrast terrain. |
| `phase7_08_water_cove_shoreline_interaction.png` | Emerald Cove Water Interaction & Canoe POI | 1280×720 | Water shader ripples, shoreline sand transition, hero canoe asset, shallow water player drag. |
| `phase7_09_hud_and_pause_controls.png` | Observability HUD, Compass & Controls Bar | 1280×720 | Compass heading, sim clock, weather indicator, context hotkeys, non-intrusive bottom bar. |
| `phase7_10_first_person_exploration.png` | First-Person Mountain Overlook | 1280×720 | Panoramic 720m island vista, ocean horizon containment, alpine scree, distant canopy layers. |

## 3. Phase 10 Extended Overnight Execution Captures (`reports/visual_phase10/`)

| Screenshot Name | Scenario / Condition | Resolution | Verified Polish Highlights |
|---|---|---|---|
| `phase10_01_time_step_midday.png` | Time of Day Step Midday (12:00 PM) | 1280×720 | Direct `[T]` hotkey step, high sun lighting, crisp directional shadows, active grazing herd. |
| `phase10_02_time_step_sunset.png` | Time of Day Step Golden Sunset (18:00 PM) | 1280×720 | Immediate diurnal sunset transition via `[T]`, elongated shadows, warm amber haze. |
| `phase10_03_time_step_night.png` | Time of Day Step Deep Night (22:30 PM) | 1280×720 | Indigo celestial sky, twinkling procedural stars, soft directional moonlight, nightfall banner. |
| `phase10_04_preset_balanced.png` | Balanced Preset (Intel Iris Xe Profile) | 1280×720 | 85% 3D resolution scale, proportional MultiMesh grass density, 2-split cascaded shadows. |
| `phase10_05_preset_cinematic.png` | Cinematic Preset (High Fidelity Profile) | 1280×720 | Native 100% resolution scale, calibrated SSAO contact shadows, volumetric fog scattering. |
| `phase10_06_landmark_discovery.png` | Overgrown Field Camp Discovery | 1280×720 | Arrival at abandoned camp with canvas shelter, fire pit, discovery toast + audio chime. |
| `phase10_07_shoreline_sand_footstep.png` | Emerald Cove Shoreline Sand Locomotion | 1280×720 | Beach terrain navigation, procedural granular sand footstep sound synthesis, water's edge. |

---

## 4. Phase 13 Unified 720m Island & Distinct Biomes (`reports/visual_unified/`)

| Screenshot Name | Scenario / Condition | Resolution | Verified Polish Highlights |
|---|---|---|---|
| [`unified_01_meadow_plains.png`](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_unified/unified_01_meadow_plains.png) | Expansive Sunlit Meadow Plains (Southeast Sector) | 1280×720 | Vast unbroken green grassland rolling toward distant hills, active deer herd grazing/running, blue wildflower drifts, solitary landmark boulder, complete exclusion of clutter trees. |
| [`unified_02_deep_forest_canopy.png`](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_unified/unified_02_deep_forest_canopy.png) | Whispering Deep Forest Stand (West/Southwest Sector) | 1280×720 | 1,400 MultiMesh pine canopy, dense trunks, sheltered shaded woodland understory, and natural forest edge transition. |
| [`unified_03_former_moat_healed.png`](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_unified/unified_03_former_moat_healed.png) | Former Moat Healed (r = 72m–98m boundary) | 1280×720 | Continuous, solid rolling terrain stretching outward with zero artificial moat trench, zero water division, and unbroken topography. |
| [`unified_04_mountain_overlook.png`](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_unified/unified_04_mountain_overlook.png) | Continental Mountain Overlook Vista | 1280×720 | High-elevation perspective framing dense pine forest foreground, rolling unified terrain, monolith POIs, and outer ocean envelope. |

---

## 5. Phase 14 Cinematic Landscape & Atmospheric Spectacle (`reports/visual_cinematic/`)

| Screenshot Name | Scenario / Condition | Resolution | Verified Polish Highlights |
|---|---|---|---|
| [`cinematic_06_aurora_borealis_night.png`](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_cinematic/cinematic_06_aurora_borealis_night.png) | Northern Aurora Borealis Curtain & Shooting Stars | 1280×720 | 2-layer harmonic magnetic curtains (emerald green `#1ff5a2` to violet-magenta tips) undulating above northern Skyspire mountain with periodic celestial shooting stars flashing across the starfield. |
| [`cinematic_07_silverveil_glacial_waterfall.png`](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_cinematic/cinematic_07_silverveil_glacial_waterfall.png) | Silverveil Glacial Falls & Gorge Chasm | 1280×720 | Multi-tier stepped glacial cascade ribbons spilling from Alpine Tarn ($Y = 36\text{m}$) down through granite crags into churning plunge pool with procedural soft radial mist particles and spatial audio. |
| [`cinematic_08_skyspire_summit_blizzard.png`](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_cinematic/cinematic_08_skyspire_summit_blizzard.png) | Skyspire Alpine Summit ($Y = 86\text{m}$) & Spindrift | 1280×720 | Snow-capped razor arête, talus scree boulders, high-velocity summit spindrift ice motes, and sweeping continental panoramic vista overlooking all lower biomes. |
| [`cinematic_09_whispering_grotto_bioluminescence.png`](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_cinematic/cinematic_09_whispering_grotto_bioluminescence.png) | Whispering Grotto Cavern & Subterranean Pool | 1280×720 | Vaulted granite monolith ceiling, hanging stalactites, dripping water droplets, glowing azure bioluminescent crystal prisms, and cyan spore motes. |
| [`cinematic_10_twilight_forest_fireflies.png`](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_cinematic/cinematic_10_twilight_forest_fireflies.png) | Twilight Forest Glade & Enchanted Fireflies | 1280×720 | Prowling wolf, resting deer herd, floating warm-gold firefly particles in low-elevation meadows, and radiant aurora curtain glowing across the twilight sky. |

---

## 6. Archival Visual Evidence Across Milestone Blocks
- `reports/block24_*.png` — Block 24 Wildlife and Immersion Captures
- `reports/block25_rc_*.png` — Block 25 Release Candidate Verification Captures
- `reports/visual_phase6/*.png` — Phase 6 Cinematic Landscape Transformations
- `reports/visual_phase10/*.png` — Phase 10 Extended Visual Evidence Matrix
- `reports/visual_unified/*.png` — Phase 13 Unified 720m Island Biomes

