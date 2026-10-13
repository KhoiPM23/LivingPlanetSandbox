# THIRD-PARTY COMPONENTS MANIFEST & LICENSE INVENTORY
## Living Planet Sandbox — Release Candidate (Block 8/8)

This document tracks all external software, game engine components, addons, shaders, fonts, and design references integrated into or referenced by **Living Planet Sandbox**.

---

### 1. Component License Table

| Component Name | Source Repository / Origin | Version / Commit | License | Role in Sandbox | Audit & Inclusion Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Godot Engine** | [godotengine/godot](https://github.com/godotengine/godot) | `4.6.3-stable` (Commit `7d41c59c4`) | MIT License | Core game engine runtime, Vulkan Forward+ renderer, SceneTree, and audio/input system | **Bundled in Release**: Export template binary `windows_release_x86_64.exe` |
| **Water Shader** | [LesusX/Water-Shader](https://github.com/LesusX/Water-Shader) | Commit `b2f11857` | MIT License | Gerstner wave ocean simulation, surface foam, and depth extinction math | **Adapted & Included**: In `res://presentation/shaders/water.gdshader` with bespoke depth-buffer clipping and vertex color modulation |
| **FastNoiseLite** | Embedded in Godot Engine core (Auburn/FastNoiseLite) | Godot 4.6.3 built-in | MIT License | Procedural simplex and cellular heightmap generation for island geography | **Compiled in Engine**: Zero external dependencies |
| **Default Typography** | Godot Engine Embedded Fonts (Libre Baskerville / Montserrat / Open Sans) | Godot 4.6.3 default theme | SIL Open Font License 1.1 / Apache 2.0 | In-engine UI typography, HUD panels, and modal dialogs | **Embedded in Binary**: Built-in vector glyphs |
| **Terrain3D** | [TokisanGames/Terrain3D](https://github.com/TokisanGames/Terrain3D) | Tag `v1.0.2-stable` (Commit `854a4575`) | MIT License | GPU clipmap terrain rendering and foliage instancing reference | **Evaluated / Reference Only**: Native bounded `IslandTerrain` retained as zero-dependency foundation |
| **Sky3D** | [TokisanGames/Sky3D](https://github.com/TokisanGames/Sky3D) | Commit `6e151bc3` | MIT License | Atmospheric scattering and celestial day/night positioning reference | **Evaluated / Reference Only**: Native bespoke celestial controller in `DayNightCycle` active |
| **OpenAcre (Design)** | [OpenAcre-Project/OpenAcre](https://github.com/OpenAcre-Project/OpenAcre) | Commit `f6c82a6c` | GPL-3.0 | Clean-room architectural design reference for atomic save/load rotation and registry patterns | **Design Reference Only**: Clean-room implementation in GDScript, 0 lines of external GPL code copied |

---

### 2. Proprietary & Art Asset Verification (Zero Third-Party Media Assets)

- **3D Meshes**: 100% Procedurally generated using Godot's built-in `PrimitiveMesh` classes (`PlaneMesh`, `BoxMesh`, `CylinderMesh`, `TorusMesh`, `PrismMesh`) and algorithmic vertex-colored surface generation (`IslandTerrain`). Zero third-party 3D model files (`.gltf`, `.fbx`, `.obj`) exist in the project tree.
- **2D Textures & Sprites**: All materials utilize pure procedural unshaded and StandardMaterial3D vertex colors and algorithmic noise. Zero external raster textures (`.png`, `.jpg`, `.dds`) are required for world presentation.
- **Audio & Sound Effects**: No third-party sound banks or copyrighted music files exist in the project repository.
- **Attribution Integrity**: All code modifications made to adapted shaders retain original author copyright and license headers.

---

### 3. Removal & Substitution Procedure

All third-party addons reside exclusively in `res://addons/<component_name>/` or isolated presentation folders (`res://presentation/shaders/<component_name>/`). Any module can be toggled or uninstalled without preventing the core simulation engine (`res://core/`) from executing headlessly or running automated tests.

---

### 4. Full License Texts

#### A. Godot Engine License (MIT)
```text
Copyright (c) 2014-present Godot Engine contributors.
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

#### B. Water Shader License (MIT)
```text
Copyright (c) 2023 LesusX

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
