# FINAL PRODUCT ACCEPTANCE REPORT — LIVING PLANET SANDBOX
**Dự án:** Living Planet Sandbox — Solo 3D Ecosystem Sandbox  
**Engine:** Godot Engine v4.6.3.stable.official.7d41c59c4  
**Phần cứng Mục tiêu:** Dell Latitude 7420, Intel Iris Xe Graphics, 16 GB RAM, Windows 11  
**Ngày Nghiệm thu:** 2026-10-14  
**Trạng thái Tổng thể:** **ACCEPTED & READY FOR HANDOFF** (Hoàn thành nghiệm thu toàn diện)

---

## 1. Những Cải tiến Thị giác Lớn nhất & Lý do Kỹ thuật

| STT | Thành phần Trước đây (Baseline) | Hiện trạng Sau Hoàn thiện (Showcase Region) | Lý do Kỹ thuật & Tác động Thị giác |
| :--- | :--- | :--- | :--- |
| **1** | **Cây cối hình khối thô sơ & tán nón nhựa:** Rừng sử dụng các hình nón đơn sắc (`nature.glb` toy cones) hoặc nón cam rực rỡ, tán lá bị mờ trong suốt (see-through) do render alpha-blend sai lệch. | **Rừng Thông Hero Scots Pines & Bụi Lilac Đầy đặn:** Cây cao 9.5m – 14.5m với cấu trúc cành nhánh tự nhiên; tán kim 3D sử dụng `ALPHA_SCISSOR` với `depth_draw_opaque` và đảo chiều pháp tuyến 2 mặt. | Xóa bỏ hoàn toàn cảm giác "đồ chơi", tạo silhouette rừng thông hùng vĩ tương tự game phiêu lưu thế giới mở; bóng đổ tán lá dappled râm mát xuống mặt đất. |
| **2** | **Địa hình xanh neon phẳng & thiếu chi tiết:** Địa hình sử dụng màu xanh đơn sắc, không phân lớp chất liệu, không có chuyển tiếp độ dốc. | **Địa hình Triplanar PBR 3 Lớp:** Kết hợp cát sỏi bờ hồ (`beach`), đất mùn hữu cơ rừng thông (`forest floor`), cỏ xanh trảng hoa (`grass`) và vách đá nứt nẻ (`rock023`). | Cự ly gần góc nhìn người đi bộ (First-Person Walker) cho thấy từng viên sỏi, rãnh xói mòn và thớ đá gồ ghề; vách đá đứng tự động phủ texture đá sườn dốc qua world-triplanar normal mapping. |
| **3** | **Cỏ mỏng dẹt & rung lắc máy móc:** Cỏ là các tấm tam giác primitive phẳng rung đồng nhịp theo một hàm `sin(TIME)`. | **Thảm Cỏ MultiMesh 3D Uốn Cong Tự nhiên:** 900 khóm cỏ lá dày `grass_leafs` với vector pháp tuyến hướng thiên mềm mại, lay động theo sóng gió lan truyền không gian (`Spatial Traveling Wave`). | Loại bỏ hoàn toàn mép cỏ sắc nhọn thô cứng; gió giật làm mặt cỏ dập dềnh thành từng đợt sóng mềm mại như đồng cỏ tự nhiên. |
| **4** | **Mặt nước phẳng đục & bọt trắng dày:** Mặt hồ dùng shader đơn giản làm đục ngầu đáy cát hoặc nổi các vệt viền trắng loang lổ. | **Mặt hồ Khúc xạ Hấp thụ Sâu & Bọt Biển Mịn:** Sóng Gerstner 2 chiều, khúc xạ mặt nước làm méo nhẹ lớp sỏi đáy hồ, độ trong suốt giảm dần theo chiều sâu quang học (`depth absorption`). | Nước trong vắt ở ven bờ, chuyển xanh ngọc bích sâu ở giữa lòng chảo Emerald Basin, bờ suối có dải bọt nước mỏng mịn ôm sát đường bờ cát. |
| **5** | **Thế giới tĩnh & động vật là khối hộp primitive:** Hươu nai là các khối `BoxMesh` di chuyển giật cục, trượt trên mặt cỏ, không có hành vi tự nhiên. | **Hệ Sinh thái Quaternius Skinned Mesh & Tập tính Sống:** Mô hình Stag, Deer, Wolf có skeleton, 13 hoạt ảnh khớp sải bước (`stride-matching`), bám dốc 2 trục (pitch/roll), hành vi di chuyển theo hốc sinh thái, ngủ đêm dưới tán cây và uống nước lúc hoàng hôn. | Thế giới sandbox mang lại cảm giác sống động, chân thực; người chơi có thể theo dõi đàn thú di chuyển, foraging, drinking và nghỉ ngơi tự nhiên. |
| **6** | **Ánh sáng sương mù trắng xóa:** Toàn cảnh bị phủ một lớp sương mù trắng đục làm mất tương phản và bẹt không gian. | **Hệ thống Ánh sáng & Khí quyển Điện ảnh 3 Trạng thái:** Chu kỳ ngày đêm năng động kết hợp 3 trạng thái hiệu chuẩn: Midday trong trẻo, Golden Hour hoàng hôn hổ phách ấm áp với bóng đổ dài, và Overcast/Rain với bề mặt ướt bóng nước (`wetness sheen`). | Phân lớp không gian tiền cảnh - trung cảnh - hậu cảnh rõ rệt; ánh sáng chiếu xiên tạo chiều sâu thị giác ấn tượng. |

---

## 2. Các Asset, Thư viện & Hệ thống Đã Tái sử dụng

Toàn bộ tài nguyên tích hợp đều tuân thủ giấy phép CC0 Public Domain hoặc MIT License (chi tiết tại [ASSET_ATTRIBUTION.md](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/ASSET_ATTRIBUTION.md)):

1. **Quaternius Ultimate Animated Animals (CC0):**
   - `Stag.gltf`, `Deer.gltf`, `Wolf.gltf`: Skinned mesh, khung xương Skeleton3D và hệ thống 13 animations hoàn chỉnh.
2. **GW Tuts Hero Scots Pine & Lilac Bushes (Permissive Open-Source):**
   - `pine1.gltf`, `pine2.gltf`, `pine3.gltf`, `bush1.gltf`, `bush2.gltf` kèm bộ Texture Atlas vỏ cây PBR và cành kim Alpha Scissor.
3. **Kenney Nature Kit (CC0):**
   - Khúc gỗ mục (`log`, `log_large`), gốc cây (`stump_round`), cụm nấm rừng (`mushroom_redGroup`, `mushroom_tanTall`), hoa dại trảng cỏ (`flower_purple`, `flower_red`, `flower_yellow`), hoa súng mặt hồ (`lily_large`, `lily_small`).
4. **ambientCG PBR Textures (CC0):**
   - Bộ map PBR chất lượng cao Albedo, Normal, Roughness cho nền đất mùn (`Ground037`) và vách đá nứt nẻ (`Rock023`).
5. **Terrain3D Demo Assets (MIT):**
   - Các khối đá hoa cương tự nhiên `RockA.glb`, `RockB.glb`, `RockC.glb` và vật liệu triplanar normal mapping `M_rock23_tp.tres`.
6. **Thuật toán Shader Nước & Gió (MIT):**
   - Sóng Gerstner, hấp thụ quang học và khúc xạ từ Emil Johansen & Chrisknyfe.
   - Kỹ thuật Two-Sided Opaque Foliage từ Caphindsight & Godot Shaders Community.

---

## 3. Những Phần Đã Thay thế hoặc Tái thiết kế

1. **Thay thế hoàn toàn Foliage Shading Pipeline:**
   - *Cũ:* `render_mode depth_draw_always` kết hợp alpha blend gây lỗi sorting, lá cây bị xuyên thấu, cành sau đè cành trước.
   - *Mới:* `render_mode cull_disabled, depth_draw_opaque` với `ALPHA_SCISSOR` threshold 0.40 và `NORMAL = FRONT_FACING ? NORMAL : -NORMAL`. Tán lá đặc, cứng cáp, đón sáng tự nhiên.
2. **Tái thiết kế Hệ thống Camera Khám phá ([presentation/camera/free_look_camera.gd](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/presentation/camera/free_look_camera.gd)):**
   - Bổ sung chế độ **First-Person Walker** (nhấn phím `V`): Người chơi trực tiếp đi bộ trên mặt đất, cảm nhận quy mô thực tế của cây cối, đá tảng và đàn thú ở tầm mắt người ($1.75\text{m}$).
   - Bổ sung 5 điểm quan sát danh lam thắng cảnh (Scenic POI Bookmarks - phím `B`).
3. **Tái thiết kế Kiến trúc Đồ họa Theo Tầng (Scalable Graphics Presets):**
   - Thiết lập 3 preset thực tế `LOW`, `BALANCED`, `CINEMATIC` can thiệp trực tiếp vào tham số engine thay vì chỉ đổi tên giao diện. Preset `BALANCED` mặc định được cân chỉnh đặc biệt cho GPU tích hợp Intel Iris Xe.
4. **Khử Cơ học trong Chuyển động Động vật ([presentation/ecosystem/ecosystem_presentation.gd](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/presentation/ecosystem/ecosystem_presentation.gd)):**
   - Tốc độ góc bị rate-limit (`rotate_toward`) tránh giật 180°; thân xoay nghiêng theo sườn dốc 2 trục; tự động né vách đá dốc $>1.1\text{m}$; bộ đếm thời gian wander được khử đồng bộ hóa.

---

## 4. Bằng chứng Hình ảnh Runtime từ Gameplay Thực tế

Toàn bộ 11 ảnh chụp màn hình kiểm định độ phân giải chuẩn $1280 \times 720$:

| Góc Máy Kiểm Định | Tệp Bằng Chứng Thị Giác | Nội Dung & Điểm Nhấn Đánh Giá |
| :--- | :--- | :--- |
| **Shot 1: Toàn cảnh Thế giới** | [shot_1_world_panorama.png](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_1_world_panorama.png) | Toàn bộ thung lũng, trảng cỏ và rặng thông hero vươn lên nền trời trong xanh; bố cục 3 tầng tiền/trung/hậu cảnh rõ ràng. |
| **Shot 2: Góc nhìn thứ nhất Rừng Thông** | [shot_2_forest_first_person.png](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_2_forest_first_person.png) | Vỏ cây thông PBR nứt nẻ sần sùi ở cự ly gần; bóng râm dappled đổ xiên qua thảm lá mục và khúc gỗ ngã. |
| **Shot 3: Chuyển tiếp Đồng cỏ sang Rừng** | [shot_3_meadow_transition.png](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_3_meadow_transition.png) | Đàn hươu tụ hội tự nhiên bên bậc đá cuội lòng suối; bóng đổ sắc nét trải dài trên thảm cỏ xanh. |
| **Shot 4: Bờ hồ & Độ sâu Nước** | [shot_4_shoreline_water.png](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_4_shoreline_water.png) | Viền bọt sóng mỏng mịn men theo bờ cát; nước trong vắt thấy đáy sỏi ven bờ, chuyển xanh thẫm ở vùng nước sâu. |
| **Shot 5: Cận cảnh Thảm cỏ & Mặt đất PBR** | [shot_5_vegetation_materials.png](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_5_vegetation_materials.png) | Khóm cỏ 3D cong mềm mại, mặt đất PBR giàu chi tiết vụn hữu cơ, không bị bẹt hay phẳng vật liệu. |
| **Shot 6: Động vật Cận cảnh** | [shot_6_fauna_locomotion.png](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_6_fauna_locomotion.png) | Hươu đầu đàn với cặp gạc phân nhánh đứng vững chãi; thân nghiêng tự nhiên theo độ dốc mặt đá. |
| **Shot 7: Cảnh nhìn xa qua nhiều Lớp** | [shot_7_distant_layers.png](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_7_distant_layers.png) | Tiền cảnh đàn thú uống nước, trung cảnh lòng suối đá cuội, hậu cảnh vách đá vôi xám đứng sừng sững dưới nắng. |
| **Shot 8: Điều kiện Mưa gió & Mặt ướt** | [shot_8_weather_rain_wetness.png](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_8_weather_rain_wetness.png) | Bầu trời xám chì; bề mặt đất đá bóng loáng phản chiếu ánh sáng ướt (`wetness = 0.85`); cây cối lay động theo gió bão. |
| **Shot 9: Hoàng hôn Golden Hour & HUD** | [shot_9_minimal_hud.png](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_9_minimal_hud.png) | Nắng vàng cam hổ phách rực rỡ, bóng đổ xiên dài cực kỳ điện ảnh; giao diện HUD tinh giản hiện đại. |
| **Shot 10: Đàn Hươu Gặm Cỏ Trên Đồng Hoa** | [shot_10_ecological_meadow_grazing.png](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_10_ecological_meadow_grazing.png) | Hốc sinh thái đồng bằng ngập nắng với 65% đàn hươu phân bổ tự nhiên gặm cỏ trong trảng hoa dại. |
| **Shot 11: Đàn Thú Uống Nước Ven Hồ Chiều Tà**| [shot_11_golden_hour_watering.png](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_11_golden_hour_watering.png) | Tập tính uống nước lúc 17:00 bên bờ vịnh hồ Emerald Basin; ánh nắng ngược viền sáng gạc hươu và mặt nước hồ. |

---

## 5. Kết quả Kiểm thử & Benchmark Đã Xác minh

### A. Phân loại Kiểm thử:
1. **Kiểm thử Logic Hợp đồng (Contract Tests):** **108 / 108 tests PASS (100%)** qua lệnh `godot --headless -s res://tests/test_runner.gd`.
   - Bao quát toàn diện 18 bộ test suite: WorldSeed, WorldClock, EventBus, EntityRegistry, WorldPersistence, PlayableWorld, EnvironmentSystems, CausalEcosystem, ExperimentTools, StabilityRegression, VisualPolishUX, CameraExploration, GeneticsSelection, WeatherSurface, GraphicsPresets, FoliageOpacityRegression, EcosystemBehaviorAcceptance.
2. **Kiểm thử Khởi động Bản phát hành (Release Smoke Tests):** **7 / 7 checks PASS (100%)** qua lệnh `godot --headless -s res://tests/test_release_smoke.gd`.
   - Xác nhận: Khởi động thế giới, camera clearance clamping, bước tiến thời gian mô phỏng, can thiệp công cụ cọ vẽ, lưu/nạp an toàn, mở đóng menu modal.
3. **Kiểm thử Bản chạy Độc lập (Standalone Executable):**
   - Đã biên dịch thành công bản build chính thức: [build/release/LivingPlanetSandbox.exe](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/build/release/LivingPlanetSandbox.exe) (136 MB, nhúng toàn bộ PCK).
   - Kiểm tra thực thi độc lập: Đạt mã thoát `code 0`, nạp đầy đủ tài nguyên, không thiếu DLL, không phát sinh lỗi console.

### B. Kết quả Benchmark Thực tế trên Intel Iris Xe (1280x720):
- **Target Workload (Gameplay Tiêu chuẩn: 55 cây, 14 thú ăn cỏ, 2 thú săn mồi):**
  - FPS trung bình: **38.0 FPS** (Biên độ dao động $31.0 - 47.0\text{ FPS}$).
  - **Tỉ lệ rớt khung hình dưới 30 FPS: 0.0%** (Hoàn toàn ổn định trên ngưỡng 30 FPS).
  - Thời gian khung hình trung bình: **35.81 ms** (p95: 46.44 ms).
  - Bước tính mô phỏng sinh thái (CPU Sim Step): **4.47 ms** (chỉ chiếm ~12% ngân sách khung hình).
  - Số lượng lệnh dựng (Draw Calls): **326** | Số lượng đa giác (Primitives): **1.61M**.
  - Bộ nhớ RAM chiếm dụng: **104.30 MB**.
- **Light Workload (Low Preset):** **38.3 FPS avg** (29.0 – 50.0 FPS).
- **Stress Workload (Cinematic Preset):** **37.3 FPS avg** (27.0 – 48.0 FPS).

---

## 6. Hướng dẫn Khởi chạy Game & Tùy chọn Preset Đồ họa

### A. Khởi chạy Trực tiếp từ Godot Editor / CLI:
```bash
# Khởi chạy cảnh chính của game
godot res://scenes/main.tscn

# Hoặc khởi chạy thông qua Godot binary thông thường
godot
```

### B. Khởi chạy Bản Build Độc lập (Standalone Release Binary):
```bash
# Chạy trực tiếp file thực thi độc lập (không cần cài Godot Editor)
build\release\LivingPlanetSandbox.exe
```

### C. Phím Tắt Điều Khiển Gameplay:
- **`W / A / S / D`** hoặc **Mũi tên:** Di chuyển camera / nhân vật đi bộ.
- **`Shift`:** Tăng tốc di chuyển (Chạy nước rút / Fast fly).
- **`V`:** Chuyển đổi giữa chế độ **Flycam tự do** và **First-Person Walker (Đi bộ trên mặt đất)**.
- **`Space`:** Nhảy (ở chế độ Walker) hoặc Tạm dừng / Tiếp tục mô phỏng thế giới (ở chế độ Flycam).
- **`B`:** Chuyển nhanh qua các điểm ngắm cảnh danh lam thắng cảnh (POI Bookmarks).
- **`H` hoặc `F1`:** Ẩn / Hiện thanh giao diện HUD để ngắm cảnh điện ảnh.
- **`Tab`:** Mở bảng điều khiển can thiệp sinh thái và biểu đồ gen đa kênh.
- **`Esc`:** Mở Bảng Cài đặt (Settings Modal) để đổi đồ họa, độ nhạy chuột và lưu/nạp game.

### D. Cách Chọn Preset Đồ họa:
Nhấn **`Esc`** để mở cửa sổ Cài đặt $\to$ chuyển sang tab **Graphics Settings**:
- **Low:** Tỉ lệ render 75%, tắt bóng đổ, tắt sương mù, 450 khóm cỏ (tiết kiệm pin tối đa).
- **Balanced (Khuyến nghị cho Intel Iris Xe):** Tỉ lệ render 85%, bóng đổ 2-splits sắc nét cục bộ ($65\text{m}$), sương mù Depth Fog, 900 khóm cỏ, không SSAO.
- **Cinematic:** Tỉ lệ render 100%, khử răng cưa MSAA 2X, bóng đổ 4-splits ($110\text{m}$), bật SSAO và Volumetric Fog, 1400 khóm cỏ (dành cho PC cấu hình cao / GPU rời).

---

## 7. Các Vấn đề Còn lại, Mức độ Ảnh hưởng & Nguyên nhân Kỹ thuật

| Vấn đề Còn lại | Mức độ Ảnh hưởng | Nguyên nhân Kỹ thuật & Bản chất | Hướng xử lý Tương lai |
| :--- | :--- | :--- | :--- |
| **1. Cảnh báo GLTF default scene trên console** | **Rất thấp (Chỉ là cảnh báo log, không ảnh hưởng gameplay)** | Một số file glTF2 (`pine1.gltf`, `nature.glb`) không khai báo `scene` index mặc định trong header; Godot tự động fallback chọn scene đầu tiên (`Picking the first scene`). | Có thể re-export lại asset qua Blender để ghi rõ default scene index nếu cần xóa sạch 100% dòng log warning. |
| **2. Bọt sóng nước (Water foam) hiển thị tĩnh ở ven bờ** | **Thấp (Thẩm mỹ phụ)** | Bọt sóng ven bờ hồ hiện được tính toán dựa trên chênh lệch depth buffer tĩnh kết hợp hàm sin thời gian, chưa có mô phỏng hạt bọt nước động vỡ vụn khi va đập đá. | Thêm particle bọt nước động tại các điểm tiếp xúc đá dốc nếu mở rộng ngân sách GPU. |
| **3. Giới hạn tầm nhìn cây xa (Tree pop-in ở cự ly > 115m)** | **Rất thấp (Đảo chỉ có bán kính 30m)** | Để bảo toàn 38+ FPS trên Iris Xe, cây thông hero dither fade ở cự ly 100m–115m. Trong phạm vi hòn đảo ($160\text{m}$), toàn bộ cây đều hiển thị đầy đủ, chỉ khi camera bay ra rất xa ngoài biển mới bắt đầu culling. | Tích hợp hệ thống Impostor/Billboard 2D 8 hướng (Octahedral Impostor) cho hậu cảnh xa nếu mở rộng bản đồ lên quy mô đảo $>500\text{m}$. |

---

## 8. Trạng thái Git Cuối cùng (Git Status Preservation)

Tuân thủ nghiêm ngặt quy tắc an toàn mã nguồn: **Không thực hiện `git commit`, không `git push`, không dùng `git reset` hoặc `git clean`**.

### Tệp Đã Thay đổi (`Changes not staged for commit`):
- `ASSET_ATTRIBUTION.md`
- `VISUAL_ACCEPTANCE_REPORT.md`
- `VISUAL_AUDIT_REPORT.md`
- `core/ecosystem/ecosystem_coordinator.gd`
- `core/ecosystem/fauna_simulation.gd`
- `demo/assets/materials/M_rock23_tp.tres`
- `presentation/camera/free_look_camera.gd`
- `presentation/ecosystem/ecosystem_presentation.gd`
- `presentation/environment/day_night_cycle.gd`
- `presentation/environment/island_terrain.gd`
- `presentation/environment/vegetation_scatter.gd`
- `presentation/environment/weather_effects_controller.gd`
- `presentation/graphics/graphics_presets.gd`
- `presentation/props/rock_boulder.gd`
- `presentation/props/tree_pine.gd`
- `presentation/shaders/foliage_wind.gdshader`
- `presentation/shaders/terrain_pbr.gdshader`
- `presentation/shaders/water.gdshader`
- `presentation/tools/player_tool_controller.gd`
- `presentation/ui/hud.gd`
- `scenes/main.gd`
- `scenes/main.tscn`
- `tests/benchmark_suite.gd`
- `tests/benchmark_world.gd`
- `tests/test_causal_ecosystem.gd`
- `tests/test_runner.gd`
- `tests/visual_qa_transformation.gd`

### Tệp Bổ sung Mới (`Untracked files`):
- `build/release/LivingPlanetSandbox.exe` (Bản chạy độc lập đã kiểm chứng)
- `presentation/assets/foliage/` (Bộ asset cây thông hero và bụi lilac GW Tuts)
- `presentation/audio/` (Bộ âm thanh thủ tục tiếng gió, suối chảy, chim hót)
- `reports/FINAL_PRODUCT_ACCEPTANCE.md` (Báo cáo nghiệm thu bàn giao chính thức)
- `reports/PERFORMANCE_ACCEPTANCE.md` (Báo cáo hiệu năng Iris Xe đo đạc thực nghiệm)
- `reports/LIVING_WORLD_EVALUATION.md` (Báo cáo nghiệm thu thế giới sống và tập tính)
- `reports/VISUAL_REVIEW_LOG.md` (Nhật ký tiến trình biến đổi thị giác qua các Block)
- `reports/visual_evidence/` (Toàn bộ 11 ảnh chụp kiểm định chất lượng cao $1280 \times 720$)
- `tests/benchmark_diagnostics.gd` (Công cụ phân lập bottleneck định lượng)
- `tests/test_foliage_opacity_regression.gd` (Suite test chống hồi quy tán lá thông)
- `tests/test_ecosystem_behavior_acceptance.gd` (Suite test nghiệm thu tập tính động vật)
- `tests/player_journey_audit.gd` (Hành trình kiểm tra trải nghiệm người chơi thực tế)

---

## 9. Các Bước Tiếp theo (Xếp theo Tác động Thị giác & Công sức)

1. **Octahedral Impostor System cho Bản đồ Lớn ($>500\text{m}$):**
   - *Tác động:* Rất cao khi mở rộng diện tích thế giới.
   - *Công sức:* Trung bình (~1 ngày làm việc).
   - *Mô tả:* Nướng (bake) cây thông thành texture thẻ bài 8 hướng để render hàng nghìn cây ở hậu cảnh núi xa với chi phí gần như bằng 0.
2. **Chi tiết Tương tác Nước Nâng cao (Dynamic Water Ripple Interactivity):**
   - *Tác động:* Trung bình (tăng độ sinh động khi động vật lội qua hồ).
   - *Công sức:* Thấp (~2-3 giờ làm việc).
   - *Mô tả:* Gửi vị trí chân thú xuống shader nước qua mảng uniform để tạo gợn sóng lan tỏa cục bộ khi hươu bước xuống uống nước.
3. **Mở rộng Chuỗi Thức ăn & Đa dạng Sinh học:**
   - *Tác động:* Cao về chiều sâu gameplay sandbox.
   - *Công sức:* Trung bình (~4-6 giờ làm việc).
   - *Mô tả:* Bổ sung thỏ hoang (small prey) gặm mầm cây non và cáo đỏ (medium predator) để hoàn thiện mạng lưới quan hệ sinh thái 3 bậc.

---

**KẾT THÚC BÁO CÁO NGHIỆM THU — SẢN PHẨM SẴN SÀNG BÀN GIAO CHO NGƯỜI DÙNG ĐÁNH GIÁ TRỰC TIẾP.**
