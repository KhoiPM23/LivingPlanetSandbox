# LIVINGPLANETSANDBOX — QA LOOP LOG (PHASE 8)

**Date:** October 18, 2026  
**Hardware Profile:** Intel Iris Xe Integrated Graphics (1280x720, Forward+ Vulkan), 16 GB Shared RAM, Windows 11  
**Engine:** Godot 4.6.3 Stable  

---

## 1. Ranked Defect Backlog & Resolutions

### [DEF-FIN-01] NaN Elevation & Non-Finite Transform Engine Flood
- **Severity:** BLOCKER
- **Category:** RELIABILITY / ENGINE / VISUAL
- **Reproduction:** Load world with standard seed (1337) and allow camera/fauna to traverse lake center around `(16.0, 14.0)`.
- **Evidence:** `ERROR: Condition "!v.is_finite()" is true` flooding console at `servers/rendering/renderer_scene_cull.cpp:991`.
- **User Impact:** Spammed thousands of error logs per frame, degraded Vulkan culling performance, corrupted node transforms (`(16.3, NaN, 14.8)`), and broke fauna spatial stability.
- **Root Cause:** In `presentation/environment/island_terrain.gd:191`, lake carving calculated `pow(lake_ellipse + lake_shore_noise, 2.2)`. Near the lake center, the inner sum evaluated to small negative values (`-0.15`), producing `NaN` in floating-point math.
- **Fix:** Clamped lake radius argument: `var lake_rad: float = maxf(0.0, (lake_ellipse + lake_shore_noise) / 1.0)` prior to computing `pow()`.
- **Verification:** Ran `diagnose_non_finite.gd` and `phase7_immersion_verification.gd`. Log output confirmed 0 non-finite errors and 0 transform glitches.
- **Status:** VERIFIED PASS

---

### [DEF-FIN-02] MultiMesh with Null Mesh in Tall Grass Instancing
- **Severity:** HIGH
- **Category:** RELIABILITY / RENDERING
- **Reproduction:** Launch world with dense vegetation scattering enabled.
- **Evidence:** `ERROR: Condition "multimesh->mesh.is_null()" is true` spammed in Godot console at `servers/rendering/renderer_scene_cull.cpp`.
- **User Impact:** Engine error spam, skipped render draws, potential render pipeline stalls.
- **Root Cause:** In `presentation/environment/vegetation_scatter.gd:1448`, `tall_mm.mesh` was never assigned before instancing.
- **Fix:** Assigned `tall_mm.mesh = _cached_nature_props["grass_large"]["mesh"]` during instantiation.
- **Verification:** Headless and Forward+ test runs confirm 0 null mesh errors during vegetation scatter.
- **Status:** VERIFIED PASS

---

### [DEF-FIN-03] LivingWorldDirector False Nightfall Banner on Morning Launch
- **Severity:** MEDIUM
- **Category:** UX / GAMEPLAY
- **Reproduction:** Launch the game at 10:00 AM (`sim_hour = 10.3`).
- **Evidence:** Captured in `phase7_01_movement_third_person.png` displaying `"🌙 Nightfall: Darkness spreads across the island..."` at 10:32 AM.
- **User Impact:** Immersion-breaking contradiction between visual sunlight and HUD event banner.
- **Root Cause:** In `core/living_world/living_world_director.gd:146-154`, the midnight day-rollover logic set `crossed_dusk = _last_sim_hour < DUSK_HOUR and sim_hour < DUSK_HOUR`, evaluating to true at 10:00 AM on initial tick.
- **Fix:** Corrected condition to require `sim_hour >= DUSK_HOUR` for dusk triggering.
- **Verification:** Re-ran `phase7_immersion_verification.gd`. Fresh screenshot `phase7_01_movement_third_person.png` verified banner now correctly displays `"🌅 Dawn Chorus: Sunrise over the island"`.
- **Status:** VERIFIED PASS

---

### [DEF-FIN-04] Walker Locomotion Speed Reduction in Headless Tests
- **Severity:** HIGH
- **Category:** RELIABILITY / PHYSICS
- **Reproduction:** Run `test_block23_verification.gd:test_player_framerate_independent_locomotion`.
- **Evidence:** Test failed asserting speed was 2.52 m/s instead of 3.60 m/s.
- **User Impact:** Walkers placed without active terrain were treated as being underwater (`Y < 0.2m`), applying 0.70x water drag.
- **Root Cause:** In `presentation/camera/first_person_walker.gd:377`, `global_position.y < 0.2` triggered water drag unconditionally even when unplaced in headless tests without terrain.
- **Fix:** Added `_resolve_terrain() != null` guard to water drag detection.
- **Verification:** Automated unit test suite passes with speed exactly matching 3.60 m/s.
- **Status:** VERIFIED PASS

---

### [DEF-FIN-05] Test Suite RefCounted Object Deallocation Warnings
- **Severity:** MEDIUM
- **Category:** RELIABILITY / CODE QUALITY
- **Reproduction:** Run `test_runner.gd`.
- **Evidence:** `ERROR: Can't free a RefCounted object` and `SCRIPT ERROR: Attempted to free a RefCounted object` at `test_block23_addendum.gd:112`.
- **User Impact:** No crash, but polluted test logs with engine runtime warnings.
- **Root Cause:** Calling `.free()` on `EcosystemCoordinator`, which extends `RefCounted`.
- **Fix:** Removed manual `.free()` calls on RefCounted references.
- **Verification:** Re-ran `test_runner.gd`. 0 script errors reported.
- **Status:** VERIFIED PASS

---

## 2. Verification Summary
- **Total Test Suites:** 34
- **Total Assertions:** 216 / 216 PASS
- **Test Exit Code:** 0
- **Engine Error Log:** Clean (0 non-finite errors, 0 null-mesh errors, 0 script errors)
- **Standalone Build:** `build/release/LivingPlanetSandbox.exe` exported and verified.
