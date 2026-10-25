# LIVINGPLANETSANDBOX — ASSET-FIRST RECOVERY & VISUAL VERTICAL SLICE AUDIT
## Báo Cáo Kiểm Kê Tài Nguyên, Đánh Giá Thị Giác & Kế Hoạch Vertical Slice

**Ngày thực hiện:** 17/10/2026  
**Môi trường phần cứng:** Dell Latitude 7420, Intel Iris Xe Graphics, 16 GB RAM, Windows 11  
**Engine & Renderer:** Godot Engine v4.6.3.stable.official (Forward+ Vulkan 1.4)  
**Tình trạng kiểm kê:** Độc lập, khách quan, dựa trên bằng chứng runtime và tham chiếu thực tế; không refactor bừa bãi, không commit/push, không xóa file.

---

## 1. Trạng Thái Repository & Công Việc Block 27

### 1.1. Git Status & Branch
- **Branch hiện tại:** `main`.
- **Trạng thái đồng bộ:** Ahead of `origin/main` 1 commit (`a4c330f: feat: implement Block 26 world generation...`).
- **Thay đổi chưa commit (Uncommitted changes):**
  - **34 files modified:** Các file cốt lõi đã được nâng cấp qua Block 24–27 (`core/ecosystem/fauna_simulation.gd`, `core/living_world/living_world_director.gd`, `presentation/audio/spatial_audio_director.gd`, `presentation/debug/debug_overlay.gd`, `scenes/main.gd`, `scenes/main.tscn`, `tests/test_runner.gd`, v.v.).
  - **89 files untracked:** Bao gồm các file log (`*.log`), báo cáo nghiệm thu (`BLOCK22` đến `BLOCK27_ACCEPTANCE_REPORT.md`), và 7 ảnh chụp màn hình Vulkan Forward+ của Block 27 (`reports/block27_01_*.png` đến `07_*.png`).
- **Cam kết an toàn:** Không chạy `git reset`, `clean -f`, `force pull`, `checkout --`, không tạo commit mới, không push lên remote.

### 1.2. Trạng Thái Kiểm Thử & Quá Trình Đang Chạy
- **Tiến trình nền:** Kiểm tra `Get-Process godot*` và `manage_task`: **0 tiến trình Godot đang chạy ngầm**, không có test suite nào chạy trùng lặp.
- **Kết quả kiểm thử tự động gần nhất:**
  - File kết quả: `reports/test_results.txt`.
  - Toàn bộ **34 test suites** (từ `WorldSeed` đến `TestBlock27EmergentGameplay`) đã chạy hoàn tất: **216 / 216 tests PASS (0 FAIL, exit code 0)**.
- **Hardware Telemetry gần nhất (Block 27 Forward+ Vulkan trên Intel Iris Xe):**
  - File telemetry: `reports/block27_world_telemetry.json`.
  - Frame rate trung bình: **24.8 FPS** (Frame time: 40.4 ms, tải 1280x720 Forward+).
  - Draw Calls: **299 avg** (Đỉnh 685, ngân sách < 800).
  - Primitives Rendered: **1,051,494 avg** (Đỉnh 2,051,683).
  - Static Memory: **110.39 MB** (Ngân sách < 500 MB).
  - Fauna Simulation Step: **~6.29 ms – 9.3 ms**.

---

## 2. Bản Đồ Cấu Trúc Dự Án (Project Structure Map)

Tất cả các file trong workspace được phân loại dựa trên kiểm tra tham chiếu thực tế (grep/scene dependency):

```
LivingPlanetSandbox/
├── core/                        [NHÓM A: Runtime Source - Mô phỏng thế giới, sinh thái, thời tiết]
├── presentation/                [NHÓM A & B: Runtime Source & Game Assets - Render, Camera, Shaders]
│   ├── assets/
│   │   ├── foliage/             [NHÓM B: Hero Scots Pines & Lilac Bushes PBR]
│   │   └── models/              [NHÓM B: Quaternius Animals, Humanoid Character, Nature Kit]
│   ├── audio/                   [NHÓM A: Spatial Audio Synthesis Director]
│   ├── camera/                  [NHÓM A: Third-Person & First-Person Locomotion]
│   ├── environment/             [NHÓM A: IslandTerrain, VegetationScatter, Weather, DayNight]
│   └── shaders/                 [NHÓM A: terrain_pbr, water, foliage_wind, clouds_procedural]
├── scenes/                      [NHÓM A: main.tscn, main.gd]
├── demo/                        [NHÓM B & F: Tài nguyên Terrain3D - Giữ RockA/B/C & Texture, loại demo data]
├── addons/                      [NHÓM F: Terrain3D C++ GDExtension plugin - Đã đánh giá reject runtime]
├── build/                       [NHÓM F: 741.5 MB binary build cũ, file .bak, crash backups]
├── tests/                       [NHÓM C & F: 34 Active Test Suites + Scripts chẩn đoán cũ]
└── reports/                     [NHÓM D & E: Báo cáo nghiệm thu, bằng chứng ảnh runtime, telemetry]
```

### Chi tiết phân loại:

- **Nhóm A — Runtime source đang được sử dụng trực tiếp:**
  - `core/bootstrap/world_bootstrap.gd`, `core/clock/world_clock.gd`, `core/debug/performance_monitor.gd`, `core/ecosystem/*.gd` (7 files: coordinator, fauna, flora, genome, metrics, causal tracker, experiment history).
  - `core/environment/*.gd` (4 files: grid, weather, biome, config), `core/events/world_event_bus.gd`, `core/living_world/living_world_director.gd`, `core/persistence/world_persistence.gd`, `core/registry/entity_registry.gd`, `core/scheduler/simulation_scheduler.gd`, `core/seed/world_seed.gd`.
  - `presentation/audio/spatial_audio_director.gd`, `presentation/camera/first_person_walker.gd`, `presentation/camera/free_look_camera.gd`, `presentation/character/player_character.gd`, `presentation/debug/debug_overlay.gd`, `presentation/ecosystem/ecosystem_presentation.gd`.
  - `presentation/environment/*.gd` (atmosphere_director, day_night_cycle, environmental_storytelling, island_terrain, vegetation_scatter, water_plane, weather_effects_controller).
  - `presentation/graphics/graphics_presets.gd`, `presentation/props/*.gd` (landmark_monolith, rock_boulder, tree_pine), `presentation/tools/player_tool_controller.gd`, `presentation/ui/*.gd` (hud, ecosystem_chart).
  - Shaders: `clouds_procedural.gdshader`, `foliage_wind.gdshader`, `terrain_pbr.gdshader`, `water.gdshader`.
  - `scenes/main.tscn`, `scenes/main.gd`, `project.godot`.

- **Nhóm B — Game assets đang được tham chiếu trong scene/code:**
  - 3D Models: `human_character.glb` (nhân vật), `Stag.gltf`, `Deer.gltf`, `Wolf.gltf` (động vật), `pine1/2/3.gltf` + `.bin` (cây thông hero), `bush1/2.gltf` + `.bin` (bụi cây hero), `nature.glb` (kenney props), `forest.glb` (cỏ & đá tảng), `demo/assets/models/RockA/B/C.glb` + `.tscn` (đá hoa cương).
  - PBR Textures: `demo/assets/textures/ground037_alb_ht.png`, `ground037_nrm_rgh.png` (cỏ/đất ambientCG), `rock023_alb_ht.png`, `rock023_nrm_rgh.png` (vách đá ambientCG), `presentation/assets/foliage/` (10 texture PBR vỏ thông, lá kim, vỏ lilac, lá lilac), `demo/assets/materials/M_rock23_tp.tres`.

- **Nhóm C — Automated tests và verification suites có giá trị:**
  - `tests/test_runner.gd` (Trình chạy test headless).
  - 34 Test suites chính thức trong `test_runner.gd` (tất cả 216 test cases).
  - Các script benchmark & verification runtime Vulkan còn hoạt động: `tests/block27_gameplay_verification.gd`, `tests/block26_world_verification.gd`, `tests/block25_rc_verification.gd`, `tests/benchmark_suite.gd`, `tests/benchmark_world.gd`, `tests/benchmark_diagnostics.gd`.

- **Nhóm D — Reports, screenshots, telemetry và logs của các block cũ:**
  - Báo cáo milestone: `reports/BLOCK22_ACCEPTANCE_REPORT.md` đến `reports/BLOCK27_ACCEPTANCE_REPORT.md`.
  - Báo cáo chuyên đề: `ASSET_AND_TECHNOLOGY_EVALUATION.md`, `ASSET_REUSE_AND_INTEGRATION.md`, `MASTER_TRANSFORMATION_PLAN.md`, `FOLIAGE_RENDERING_INVESTIGATION.md`, `SHOWCASE_REGION_ART_DIRECTION.md`, `visual_reality_check.md`.
  - Ảnh bằng chứng runtime chuẩn: `reports/block27_*.png` (7 ảnh), `reports/block26_*.png` (7 ảnh), `reports/block25_rc_*.png` (7 ảnh), `reports/visual_evidence/` (subdirs `block21/`, `block22/`, `block23/`).
  - Dữ liệu đo đạc: `block27_world_telemetry.json`, `block26_world_telemetry.json`, `block25_rc_telemetry.json`.

- **Nhóm E — Temporary/generated artifacts có thể tái tạo bất kỳ lúc nào:**
  - 26 file `.log` sinh ra ở thư mục gốc (`boot_main.log`, `test_run*.log`, `rc_qa*.log`, `qa*.log`, v.v.).
  - File xuất API: `extension_api.json` (10.9 MB) và `out.txt`.
  - Các file text dump chẩn đoán cục bộ trong `reports/`: `anim_debug.txt`, `char_motion.txt`, `diag_char.txt`, `foot_normals.txt`, `glow_verts.txt`, `knee_eval.txt`, `locomotion_facings.txt`, `play_forward.txt`, `robot_details.txt`, `root_bone_tracks.txt`, `test_results.txt`, `trace_rot.txt`, `walk_eval.txt`.

- **Nhóm F — File trùng, lỗi thời hoặc không còn được tham chiếu (Đánh dấu ứng viên, chưa xóa):**
  - Xem danh sách chi tiết ở Mục 4.

---

## 3. Đánh Giá Asset-First (Kiểm Kê Tài Nguyên & Khả Năng Tái Sử Dụng)

| Nhóm Tài Nguyên | Asset Hiện Có | Nguồn & Giấy Phép | Định Dạng & Dung Lượng | Chất Lượng Hình Ảnh & Lỗi Nhận Thấy | Đánh Giá Tái Sử Dụng | Giải Pháp Tối Ưu Cho Vertical Slice |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Nhân vật người chơi (Character)** | `human_character.glb` | Quaternius CC0 | glTF 2.0 Binary, 392 KB, 1,450 tris, rigged skeleton (38 bones), 8 anim clips | Mô hình phi hành gia robot màu xanh/trắng ngộ nghĩnh. **Lệch tông hoàn toàn** với bối cảnh thiên nhiên hoang dã RDR2. Khi đi bộ tạo cảm giác game hoạt hình sci-fi. | **Thay thế trong Vertical Slice** (hoặc ẩn chuyển sang First-Person) | Chuyển mặc định sang First-Person Walker để tập trung vào thiên nhiên; hoặc thay bằng mô hình nhà thám hiểm/kiểm lâm CC0 từ Quaternius Survival Kit. |
| **Động vật hoang dã (Fauna)** | `Stag.gltf`, `Deer.gltf`, `Wolf.gltf` | Quaternius CC0 | glTF separate (.gltf + colormap.png), ~3.2 MB mỗi con, ~2,000 tris, 11–13 clips | Animation di chuyển mượt mà (Walk, Gallop, Idle, Alert, Eating). Tuy nhiên hình học dạng low-poly đa giác sắc cạnh (faceted papercraft), texture colormap phẳng, hay bị clip xuyên qua đá tảng. | **Tái sử dụng trực tiếp** kèm tinh chỉnh material | Giữ nguyên animation và skeleton; thêm shader làm mềm bề mặt hoặc áp dụng fur micro-roughness nhẹ; sửa logic raycast tiếp xúc đất để tránh xuyên đá. |
| **Cây thông (Pine Trees)** | `pine1.gltf`, `pine2.gltf`, `pine3.gltf` + `.bin` | Lakshman / GW Tuts (Open-Source Permissive) | glTF + binary, ~550 KB mỗi cây, 2 surfaces (thân vỏ & tán lá kim) | Tán lá kim 3D alpha-scissor có độ phồng và đón gió tự nhiên. Lỗi: Vỏ thân cây (`pine_bark_base.jpg`) bị lặp texture thô thiển khi nhìn gần; gốc cây bị lơ lửng 10–15cm trên sườn dốc (`block27_05`). | **Tái sử dụng trực tiếp** kèm căn chỉnh gốc | Giữ nguyên mesh và tán kim; tinh chỉnh UV scale vỏ cây; gắn raycast để gốc cây ăn chặt xuống mặt đất dốc. |
| **Bụi rậm tầng trung (Bushes)** | `bush1.gltf`, `bush2.gltf` + `.bin` | Lakshman / GW Tuts (Open-Source Permissive) | glTF + binary, 2 surfaces, texture lilac cards PBR | Tán lá mềm mại, có normal map và roughness, phản hồi gió tốt. Lỗi: Số lượng quá ít (chỉ 45 cây rải trên 160m) khiến mặt đất trông trơ trọi. | **Tái sử dụng trực tiếp** & tăng mật độ | Tập trung mật độ vào dải rìa rừng Whispering Forest để tạo tầng thực vật chuyển tiếp đẹp mắt. |
| **Cây & đạo cụ hoạt hình (Nature Kit)** | `presentation/assets/models/nature.glb` | Kenney CC0 | glTF binary, 1.22 MB, 82 submeshes | Cây nón cam đồ chơi, nấm màu cam neon, hoa tulip đa giác màu pastel, đá khối Minecraft. **Phá vỡ tính chân thực của đồ họa**, tạo cảm giác "chắp vá" giữa game đồ chơi và PBR. | **Nên thay thế / Loại bỏ khỏi cảnh Hero** | Loại bỏ hoàn toàn các cây nón cam, nấm neon và hoa tulip đồ chơi khỏi khu vực Vertical Slice. Chỉ giữ lại khúc gỗ mục (`log_large`) và chiếc thuyền (`canoe`) cho điểm khám phá POI. |
| **Thảm cỏ (Grass)** | `forest.glb` (`Grass_2_D_Color1`) | KayKit CC0 | glTF submesh, vertex color, không có texture thẻ lá | Khóm cỏ gồm 6–8 phiến dày cộp như nhựa đồ chơi cắm trên đất phẳng (`block27_01`). Không có độ rủ, không có cảm giác gió mượt. | **Nên thay thế** | Thay thế bằng cụm cỏ thẻ lá (foliage card grass tuft) từ thư viện CC0 (ambientCG / Kenney Foliage Cards) có alpha scissor và shader đón gió. |
| **Đá tảng & Vách đá (Rocks)** | `RockA.glb`, `RockB.glb`, `RockC.glb` (`demo/`) | Terrain3D Contributors (MIT) | glTF, 8–9 KB, nạp qua `RockBoulder` với vật liệu `M_rock23_tp.tres` | **Chất lượng hình ảnh rất cao.** Vân đá hoa cương nứt nẻ sắc nét, world-triplanar PBR hòa trộn rất tốt với vách núi. | **GIỮ LẠI VÀ TÁI SỬ DỤNG LÀM TRỤ CỘT** | Sử dụng làm các khối đá điểm nhấn (Anchor Monoliths) và bãi đá Talus dưới chân vách núi và ven hồ. |
| **Vật liệu địa hình (Terrain Textures)** | `ground037` (cỏ/đất) & `rock023` (vách đá) | ambientCG CC0 1.0 Universal | 4 file PNG (Albedo+Height, Normal+Roughness), 2048x2048, ~12 MB | Bộ texture PBR chất lượng cao của ambientCG. Lỗi: Shader địa hình trộn màu quá bão hòa khiến mặt cỏ trông như đất nặn playdough màu xanh nhạt phẳng lì (`block27_01`). | **Tái sử dụng & Tinh chỉnh Shader** | Tinh chỉnh lại tham số `terrain_pbr.gdshader`: tăng độ tương phản của micro-normal, thêm lớp mùn lá thông (forest needle mulch) dưới tán cây. |
| **Mặt nước & Bờ hồ (Water)** | `water.gdshader` + `water_plane.gd` | Emil Johansen & Chrisknyfe (MIT) | Custom GDShader + MeshInstance3D | Sóng Gerstner 2 chiều, hấp thụ quang học Beer-Lambert theo độ sâu, khúc xạ đáy hồ. Lỗi: Đường bờ (shoreline) thiếu lớp cát ướt sẫm màu và bọt sóng bờ hồ bị cứng. | **Tái sử dụng & Tinh chỉnh nhẹ** | Bổ sung dải cát ướt sẫm màu dọc mép nước và làm mềm bọt sóng ven bờ. |
| **Bầu trời & Thời tiết (Sky & Clouds)** | `clouds_procedural.gdshader` + `day_night_cycle.gd` | Custom Clean-Room | GDShader Procedural Sky | Mây tích trôi theo gió, chu kỳ bình minh/hoàng hôn/đêm trăng. Lỗi: Ánh sáng ban ngày quá chói (Light Energy = 2.0), làm cháy sáng bề mặt cỏ và đá. | **Tái sử dụng & Cân bằng Ánh Sáng** | Hạ Light Energy từ 2.0 xuống 1.35; tăng cường Ambient Indirect Light để bóng đổ dưới tán cây có chiều sâu hơn. |
| **Âm thanh không gian (Audio)** | `spatial_audio_director.gd` | Clean-Room Procedural Synthesis | 16-bit PCM WAV tổng hợp trong RAM (0 byte đĩa) | Gió núi theo thời tiết, sóng vỗ bờ hồ 3D, tiếng chim rừng ban ngày, dế đêm, tiếng nai gọi bầy, tiếng sói hú, bước chân trên cỏ/đá/nước. | **GIỮ NGUYÊN 100%** | Hệ thống chạy cực nhẹ, không phụ thuộc file âm thanh ngoài, chất lượng âm thanh định vị rất tốt. |

---

## 4. Danh Sách File/Artifact Đề Xuất Dọn Dẹp (Có Kiểm Tra Tham Chiếu)

> [!IMPORTANT]
> **Quy tắc an toàn tuyệt đối:** Đây chỉ là danh sách đánh giá và đánh dấu ứng viên. **Không có bất kỳ file nào bị xóa trong lượt này.**

### 4.1. File Build Cũ & Binary Crash (Chiếm ~741.5 MB đĩa)
Kiểm tra: Nằm trong `build/`, không bao giờ được tham chiếu bởi Godot project hay test suite.
- `build/release/LivingPlanetSandbox.exe.bak` (126.6 MB) — Bản backup build cũ từ ngày 14/10.
- `build/release/LivingPlanetSandbox.exe.bak2` (164.3 MB) — Bản backup build cũ từ ngày 15/10.
- `build/release/LivingPlanetSandbox.exe.old` (127.3 MB) — Bản backup build cũ từ ngày 14/10.
- `build/release/libterrain.windows.release.x86_64.dll~RFea8114c.TMP` (3.5 MB) — File tạm lock khi build DLL.
- `build/release_backup_crash/` (130.2 MB) — Bản sao lưu sau crash từ ngày 14/10.
- **Lý do đề xuất dọn dẹp:** Chiếm gần ba phần tư dung lượng repo (741.5 MB), hoàn toàn vô dụng cho quá trình phát triển tiếp theo.

### 4.2. File Mô Hình Lỗi Thời Không Còn Dùng
- `presentation/assets/models/character.glb` (87 KB):
  - *Kiểm tra tham chiếu:* Chỉ xuất hiện trong `tests/inspect_character.gd` và `tests/inspect_kenney_dim.gd`. **0 tham chiếu** trong toàn bộ runtime source (`first_person_walker.gd` đã chuyển hẳn sang dùng `human_character.glb`).
  - *Lý do:* Là mô hình robot Kenney cũ bị bỏ rơi sau khi tích hợp `human_character.glb`.

### 4.3. Demo Scene & Map Data Của Terrain3D (Không Dùng Trong Runtime)
Kiểm tra: Dự án chỉ dùng mesh `RockA/B/C.glb`, material `M_rock23_tp.tres`, và texture trong `demo/assets/textures/`. Toàn bộ phần còn lại của `demo/` là cảnh demo riêng của plugin Terrain3D:
- `demo/data/terrain3d_00-01.res` (4.0 MB)
- `demo/data/terrain3d_00-02.res` (4.1 MB)
- `demo/data/terrain3d_00_00.res` (3.9 MB)
- `demo/data/nav_mesh.res` (296 KB)
- `demo/assets/models/Tunnel.glb` + `.tscn` (458 KB)
- `demo/assets/models/CrystalC.tscn` (19 KB) + các material `M_crystal_*.tres`
- `demo/components/*.tscn` (7 demo scenes: Player, Enemy, Tunnel, UI, v.v.)
- `demo/src/*.gd` (8 demo scripts)
- `demo/Demo.tscn`, `demo/CodeGeneratedDemo.tscn`, `demo/NavigationDemo.tscn`
- *Lý do:* Chiếm ~13 MB tài nguyên thừa không liên quan đến hòn đảo sinh thái của dự án.

### 4.4. C++ GDExtension Terrain3D Plugin (`addons/terrain_3d/`)
- *Kiểm tra tham chiếu:* Trong `THIRD_PARTY_COMPONENTS.md` và `REUSE_INTEGRATION_REPORT.md` đã ghi rõ quyết định kiến trúc: **REJECT runtime engine của Terrain3D** vì phụ thuộc C++ DLL, gây rủi ro crash headless test trên máy không có card rời. Hòn đảo hiện chạy 100% bằng GDScript native `IslandTerrain`.
- *Lý do:* Tắt plugin khỏi `project.godot` và cô lập thư mục này sẽ loại bỏ hoàn toàn các cảnh báo binary DLL khi khởi động Godot.

### 4.5. File Log Tạm & File Xuất API Cũ Ở Thư Mục Gốc
- `boot_main.log`, `boot_main_err.log`
- `qa23_*.log`, `qa_*.log`, `rc_qa_*.log` (8 files)
- `test_*.log` (16 files)
- `out.txt`
- `extension_api.json` (10.9 MB)
- *Lý do:* File output tạm thời từ các đợt chạy test cũ của Block 21–27, có thể sinh lại bất cứ khi nào cần.

### 4.6. Các Script Chẩn Đoán Cũ Trong `tests/`
Kiểm tra: Không nằm trong danh sách 34 suite của `tests/test_runner.gd`, không có tham chiếu chéo nào từ runtime code.
- Các script inspect/diagnose 1 lần: `inspect_character.gd`, `inspect_grass*.gd`, `inspect_human*.gd`, `inspect_kenney_dim.gd`, `inspect_models.gd`, `inspect_nature_*.gd`, `diagnose_character_facing.gd`, `diagnose_cinematic_cause.gd`, `diagnose_memory_leak.gd`, `foliage_forensics.gd`.
- Các script test động tác cũ: `test_anim_debug.gd`, `test_anim_loops.gd`, `test_anim_tracks.gd`, `test_bush_render.gd`, `test_cam_near.gd`, `test_character_motion.gd`, `test_foot_normals.gd`, `test_glow_verts.gd`, `test_knee_eval.gd`, `test_play_forward.gd`, `test_robot_facing.gd`, `test_root_bone_tracks.gd`, `test_walk_feet.gd`.
- Các script visual QA cũ: `visual_qa_block21.gd` đến `visual_qa_block24.gd`.
- *Lý do:* Đã hoàn thành nhiệm vụ chẩn đoán trong các block trước. Có thể gom vào thư mục lưu trữ `tests/archive/` để giữ `tests/` gọn gàng.

---

## 5. Những Vấn Đề Hình Ảnh Lớn Nhất (Chứng Minh Bằng Screenshot Runtime)

Dựa trên việc kiểm tra trực tiếp các ảnh chụp màn hình Vulkan Forward+ thực tế gần nhất (`reports/block27_*.png` và `reports/block26_*.png`):

### Vấn đề 1: Xung Đột Phong Cách Thị Giác Nặng Nề (Cartoon Toy vs. Realistic PBR)
- **Bằng chứng ảnh:** `reports/block27_01_seed1337_wildlife_quiet_grazing.png`, `reports/block26_01_seed1337_panorama.png`, `reports/block27_07_seed1337_debug_overlay_telemetry.png`.
- **Hiện tượng thực tế:** Trong cùng một góc nhìn, chúng ta thấy:
  1. Một tảng đá hoa cương vân nứt nẻ cực kỳ chân thực (`RockA` của Terrain3D).
  2. Ngay sát bên là những cây nấm màu cam neon rực rỡ và những bông hoa tulip đa giác màu hồng/xanh pastel đồ chơi từ `nature.glb`.
  3. Cạnh đó là những tháp đá bậc thang vuông vức như khối Minecraft xếp chồng.
  4. Nhân vật chính là một chú robot phi hành gia màu xanh/trắng đi lại giữa đàn hươu.
- **Tác động:** Phá vỡ hoàn toàn cảm giác ngập tràn (immersion), khiến cảnh quan trông giống một khu triển lãm đồ chơi hơn là một vùng tự nhiên hoang dã lấy cảm hứng từ RDR2.

### Vấn đề 2: Mặt Đất Nhìn Như "Đất Nặn Playdough" Phẳng Lì
- **Bằng chứng ảnh:** `reports/block27_01_seed1337_wildlife_quiet_grazing.png`, `reports/block26_01_seed1337_panorama.png`.
- **Hiện tượng thực tế:** Mặc dù dự án đã nạp texture 2K `ground037_alb_ht.png` và `ground037_nrm_rgh.png`, nhưng thuật toán trộn trong `terrain_pbr.gdshader` đã làm bão hòa màu thành một lớp màu xanh lá non đồng nhất, thiếu bóng đổ tế vi (micro-shadows), thiếu rãnh xói mòn đất, và không có lớp thảm mục (pine needle mulch, cành cây khô, đất đen ẩm) dưới các tán thông.
- **Tác động:** Mặt đất thiếu độ bám và chất cảm bề mặt, tạo cảm giác nhân vật và thú đang bước đi trên một tấm thảm cao su mỏng.

### Vấn đề 3: Cỏ Nhựa Đồ Chơi & Hiện Tượng Gốc Cây/Động Vật Bị Lơ Lửng, Xuyên Đá
- **Bằng chứng ảnh:** `reports/block27_01_seed1337_wildlife_quiet_grazing.png`, `reports/block27_05_seed1337_dusk_shoreline_watering.png`, `reports/block26_03_seed1337_emerald_cove_sunset.png`.
- **Hiện tượng thực tế:**
  1. Khóm cỏ `Grass_2_D_Color1` là những khối đa giác dày cộp, nhô thẳng đứng như đinh ghim nhựa cắm vào nền đất.
  2. Ở sườn dốc (`block27_05`), phần rễ cây thông bị nhô khỏi mặt đất khoảng 10–15cm, để lộ khoảng trống bên dưới vì pivot của mesh không thích ứng theo độ dốc.
  3. Đàn hươu khi di chuyển theo bầy thường xuyên bị clip xuyên thân qua các khối đá tảng (`block26_03`, nửa thân hươu biến mất bên trong vách đá).
- **Tác động:** Gây cảm giác kỹ thuật thô sơ, phá hủy ngay lập tức ảo ảnh về một thế giới vật lý sống động.

### Vấn đề 4: Ánh Sáng Ban Ngày Bị Cháy Sáng & Bóng Đổ Dưới Tán Cây Thiếu Chiều Sâu
- **Bằng chứng ảnh:** `reports/block27_01_seed1337_wildlife_quiet_grazing.png`, `reports/block26_01_seed1337_panorama.png`.
- **Hiện tượng thực tế:** Đèn mặt trời `DirectionalLight3D` có `light_energy = 2.0` và màu trắng gắt, kết hợp với exposure 0.95 làm các bề mặt hướng sáng bị lóa trắng, mất hết chi tiết vân đá và cỏ. Ngược lại, vì preset BALANCED tắt SSAO và Volumetric Fog để giữ FPS cho card Intel Iris Xe, nên các khu vực bóng râm dưới tán rừng bị bẹt dí, tối sầm mà không có ánh sáng tán xạ mềm (ambient bounce light).
- **Tác động:** Bức ảnh thiếu dải tương phản động (dynamic range), cảnh vật phẳng và thiếu chiều sâu quang học.

### Vấn đề 5: Tỷ Lệ Đảo Bé Nhỏ & Đường Chân Trời Đơn Điệu
- **Bằng chứng ảnh:** `reports/block26_01_seed1337_panorama.png`.
- **Hiện tượng thực tế:** Nhìn từ trên cao, hòn đảo 160m lộ rõ là một mô đất tròn đơn độc giữa một biển nước phẳng lặng với các đường gợn sóng lặp lại đều đặn. Ngọn núi tuyết chỉ là một hình chóp tam giác nhẵn thín phía sau, không tạo được cảm giác hùng vĩ hay bí ẩn của một vùng đất rộng lớn để khám phá.
- **Tác động:** Người chơi dễ cảm thấy thế giới quá chật hẹp và nhân tạo chỉ sau 1 phút bay camera.

---

## 6. Kế Hoạch Cho Một Vertical Slice Duy Nhất (Hero Environment)

Để giải quyết triệt để 5 vấn đề trên mà không làm phình to tính năng, dự án cần tập trung toàn bộ nguồn lực vào **một khu vực đại diện duy nhất**.

### 6.1. Lựa Chọn Khu Vực Hero: "Rìa Rừng Gió Thì Thầm & Vũng Nước Ngọc Bích" (Whispering Pines & Emerald Cove)
- **Tọa độ không gian:** Khu vực giới hạn **40m x 40m** (từ `X: 0 đến 40, Z: 0 đến 40`).
- **Lý do lựa chọn:**
  1. Đây là nơi hội tụ đầy đủ tất cả các thành phần sinh thái và địa hình: Tán rừng thông Scots Pines, trảng cỏ đón nắng Sunlit Meadow, vách đá hoa cương Granite Bluff, bờ sỏi thoải ven hồ Emerald Cove, và điểm khám phá chiếc thuyền mộc (`canoe`).
  2. Điểm xuất phát mặc định của người chơi (`spawn_pos: 7.5, 3.2, 3.5`) nằm ngay tại đây, tạo ấn tượng thị giác đầu tiên (First Impression) tốt nhất.
  3. Kích thước 40m x 40m vừa đủ để kiểm soát chặt chẽ từng chi tiết hình ảnh, ánh sáng và vật liệu mà không gây sụt FPS trên Intel Iris Xe.

### 6.2. Phân Bổ Tài Nguyên Cho Vertical Slice

```
+---------------------------------------------------------------------------------------+
|                               HERO VERTICAL SLICE (40m x 40m)                         |
|                                                                                       |
|  [GIỮ LẠI CỐT LÕI]             [LOẠI BỎ KHỎI HERO]           [TÍCH HỢP MỚI / SỬA]     |
|  - Scots Pines (pine1/2/3)     - Nấm neon cam (nature.glb)   - Thảm cỏ thẻ lá PBR     |
|  - Lilac Bushes (bush1/2)      - Hoa tulip nhựa (nature.glb) - Mulch lá thông mục     |
|  - Granite Boulders (RockA/B/C)- Cây nón cam đồ chơi         - Cát sỏi bờ hồ sẫm ẩm   |
|  - Thuyền mộc POI (canoe)      - Đá khối Minecraft           - Raycast cắm rễ cây     |
|  - Quaternius Stag/Deer/Wolf   - Robot phi hành gia (hoạt    - Fur shader nhẹ cho thú |
|  - Gerstner Water & Sound        cảnh sang First-Person)     - Cân bằng sáng 1.35     |
+---------------------------------------------------------------------------------------+
```

1. **Asset cần giữ lại:**
   - Cây thông Hero Scots Pines (`pine1/2/3.gltf`).
   - Bụi rậm Hero Lilac (`bush1/2.gltf`).
   - Đá hoa cương PBR `RockA`, `RockB`, `RockC` với vật liệu `M_rock23_tp.tres`.
   - Chiếc thuyền gỗ mục (`canoe`) và đống củi khô (`log_large`) làm điểm nhấn khám phá (POI).
   - Đàn hươu (`Stag`, `Deer`) và sói (`Wolf`) của Quaternius phục vụ mô phỏng sinh thái sống động.
   - Hệ thống âm thanh không gian procedural (`SpatialAudioDirector`).
   - Nền tảng điều khiển nhân vật mượt mà (`FirstPersonWalker`).

2. **Asset cần loại bỏ khỏi khu vực Hero:**
   - Loại bỏ 100% các đạo cụ hoạt hình của `nature.glb` trong phạm vi 40m này: cây nón cam, nấm neon, hoa tulip nhựa, đá khối vuông.
   - Ẩn mô hình robot hoạt hình bằng cách chuyển góc nhìn sang First-Person ngắm cảnh thiên nhiên chân thực.
   - Loại bỏ khóm cỏ nhựa `Grass_2_D_Color1`.

3. **Asset & Kỹ thuật bổ sung tối thiểu:**
   - **Thảm cỏ tự nhiên mới (Hero Foliage Cards):** Tích hợp khóm cỏ mỏng có alpha scissor và shader đung đưa theo gió, màu sắc sage-olive tự nhiên hòa quyện với mặt đất.
   - **Lớp thảm thực vật mục (Understory Needle Mulch):** Điều chỉnh shader địa hình để tại các vị trí dưới gốc thông, mặt đất chuyển sang màu nâu đen của lá thông mục và mùn ẩm.
   - **Căn chỉnh tiếp xúc vật lý (Ground Snapping):** Thêm 1 raycast đơn giản khi spawn cây và đá để rễ cây cắm ngập 5–10cm vào sườn đất, triệt tiêu hoàn toàn lỗi rễ cây bay lơ lửng.

### 6.3. Hệ Thống Gameplay: Giữ Lại vs. Tạm Hoãn

- **Hệ thống gameplay giữ lại:**
  1. Vòng lặp quan sát sinh thái tự nhiên: Đàn hươu thong thả gặm cỏ ở trảng cỏ, cử con đầu đàn cảnh giới (ALERT), di chuyển uống nước ở bờ hồ khi hoàng hôn đến.
  2. Cơ chế lén lút (Stealth Crouch): Người chơi ngồi xuống [C] để tiếp cận đàn thú trong cự ly 10m mà không làm chúng hoảng loạn bỏ chạy.
  3. Khám phá không lời (Wordless Storytelling): Đi theo lối mòn thú đi tới bờ hồ, phát hiện chiếc thuyền gỗ cổ và vách đá sừng sững.
  4. Chu kỳ thời gian và thời tiết: Chuyển biến từ nắng dịu sang chiều tà hoàng hôn phản chiếu mặt hồ.
  5. Âm thanh sinh thái chân thực: Tiếng chim ban ngày, tiếng nai gọi bầy văng vẳng, tiếng nước vỗ bờ mạn thuyền.

- **Hệ thống gameplay tạm hoãn (Không mở rộng trong Vertical Slice):**
  1. Tạm hoãn mở rộng bản đồ ra ngoài 160m hoặc tạo thêm biome mới.
  2. Tạm hoãn hệ thống di truyền (genetics/mutation) phức tạp — giữ mô hình hành vi hiện có.
  3. Tạm hoãn các công cụ can thiệp UI HUD đồ sộ (giữ chế độ ẩn HUD [H] làm mặc định khi thưởng ngoạn).
  4. Tạm hoãn việc cố gắng tích hợp C++ GDExtension Terrain3D — giữ vững runtime GDScript nhẹ nhàng và ổn định.

---

## 7. Kế Hoạch Thực Hiện Ưu Tiên (Priority Action Plan)

| Giai Đoạn | Tác Vụ Cụ Thể | Tác Động Thị Giác | Độ Phức Tạp | Rủi Ro Kỹ Thuật | Tiêu Chí Đo Lường Hoàn Thành |
| :---: | :--- | :---: | :---: | :---: | :--- |
| **P1** | **Dọn dẹp môi trường Hero 40x40m:**<br>Lọc bỏ toàn bộ cây nón cam, nấm neon, hoa tulip nhựa và đá khối Minecraft khỏi `vegetation_scatter.gd` trong phạm vi Hero. Chuyển camera mặc định sang góc nhìn thứ nhất (First-Person). | **Rất lớn**<br>(Xóa bỏ ngay cảm giác đồ chơi hoạt hình) | Thấp | Rất thấp (Chỉ lọc điều kiện scatter) | Ảnh chụp góc xuất phát không còn bất kỳ chi tiết hoạt hình nào. |
| **P2** | **Cân bằng ánh sáng & Môi trường:**<br>Hạ `light_energy` của mặt trời từ 2.0 xuống 1.35; chỉnh màu ánh sáng ấm hơn; tăng nhẹ ambient light contribution; tinh chỉnh fog horizon để ngọn núi phía xa có chiều sâu không khí (atmospheric perspective). | **Lớn**<br>(Hết cháy sáng, màu sắc tự nhiên) | Thấp | Không có rủi ro | Chi tiết vân đá và cỏ hiện rõ dưới nắng; bóng đổ râm mát. |
| **P3** | **Khắc phục lỗi gốc cây lơ lửng & Clip xuyên đá:**<br>Bổ sung raycast terrain snap cho rễ cây thông trên sườn dốc; thêm khoảng đệm tránh va chạm đá (rock obstacle repulsion) trong steering behavior của đàn hươu. | **Trung bình**<br>(Tăng tính vững chãi, sạch lỗi) | Thấp | Rất thấp | Chụp cận cảnh gốc cây bám sát đất; không có con hươu nào bị lọt thân vào đá. |
| **P4** | **Nâng cấp cỏ & Shader mặt đất Hero:**<br>Thay khóm cỏ khối bằng cụm cỏ lá kim alpha-scissor; kích hoạt lớp mùn lá thông nâu sẫm dưới tán cây trong `terrain_pbr.gdshader`; làm sẫm màu cát ướt ven hồ. | **Rất lớn**<br>(Xóa bỏ cảm giác đất nặn playdough) | Trung bình | Thấp (Đo FPS giữ vững >= 30 FPS) | Mặt đất có chiều sâu chất cảm, bờ hồ phản chiếu tự nhiên. |
| **P5** | **Kiểm thử nghiệm thu & Chụp ảnh đối chứng:**<br>Chạy lại 34 test suite để đảm bảo 0 regression; chạy verification Vulkan chụp ảnh đối chứng góc nhìn thật để so sánh trước và sau. | **Cốt lõi**<br>(Chứng minh bằng bằng chứng) | Trung bình | Không có rủi ro | Có ảnh so sánh trực tiếp Before / After chứng minh sự lột xác thị giác. |

---

## 8. Những Điều Chưa Thể Xác Minh

1. **Hiệu năng GPU ngoài máy người dùng:** Môi trường kiểm thử tự động headless không đo được GPU frametime thực tế; toàn bộ số liệu 24.8 FPS và draw call trong báo cáo này được trích xuất từ dữ liệu chạy thực tế của Block 27 trên GPU Intel Iris Xe của người dùng (`block27_world_telemetry.json`).
2. **Khả năng tương thích của các gói asset ngoài chưa tải về:** Trong khuôn khổ lượt kiểm kê này, chúng tôi **không tự ý tải về các gói asset lớn từ internet** nhằm bảo vệ sự sạch sẽ của repo và tránh vi phạm bản quyền. Mọi đánh giá tài nguyên đều dựa trên các asset đã có sẵn trong dự án.

---

## 9. Đề Xuất Cuối Cùng & Hướng Đi Tiếp Theo

**Kết luận ngắn gọn:**
Dự án **KHÔNG NÊN** mở rộng thêm bất kỳ subsystem hay tính năng gameplay nào mới trong giai đoạn này. Các hệ thống mô phỏng sinh thái, sự kiện thế giới và âm thanh hiện tại đã rất vững chắc (216 tests pass). Điểm nghẽn lớn nhất khiến dự án chưa đủ hấp dẫn nằm ở **sự xung đột phong cách asset** (đồ chơi hoạt hình lẫn với PBR chân thực) và **thiết lập ánh sáng/vật liệu mặt đất còn thô**.

**Đề xuất hành động tiếp theo:**
Thực hiện một **Đợt Tinh Chỉnh & Làm Đẹp Có Kiểm Soát (Controlled Visual Recovery Pass)** tập trung duy nhất vào khu vực **Vertical Slice 40m x 40m (Whispering Pines & Emerald Cove)** theo đúng thứ tự ưu tiên P1 → P5:
1. Dọn sạch các asset đồ chơi hoạt hình khỏi khu vực Hero.
2. Cân bằng lại ánh sáng để hết cháy lóa.
3. Cắm rễ cây chạm đất và chống xuyên đá cho động vật.
4. Nâng cấp cỏ và mặt đất rìa rừng.
5. Nghiệm thu bằng ảnh chụp so sánh thực tế.
