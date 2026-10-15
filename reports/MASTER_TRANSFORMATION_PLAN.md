# MASTER TRANSFORMATION PLAN — LIVING PLANET SANDBOX
## Thiết lập lại lộ trình thực thi & Chuyển đổi chất lượng đồ họa sang chuẩn GTA V / RDR2
**Mục tiêu tối thượng:** Chuyển dịch toàn diện LivingPlanetSandbox từ hiện trạng prototype low-poly sơ sài sang một thế giới thiên nhiên sandbox có chất lượng hình ảnh cao, có thể tự do khám phá và sở hữu một hệ sinh thái sống động theo thời gian thực.  
**Tham chiếu thị giác:** Cảnh quan hoang dã của *Red Dead Redemption 2* (Roanoke Ridge / Big Valley) và *Grand Theft Auto V* (Mount Chiliad / Blaine County), trong giới hạn phần cứng mục tiêu: **Godot 4.6.3 Forward+ Vulkan, Intel Iris Xe Graphics, 16 GB RAM, độ phân giải 1280×720 @ 35–50+ FPS**.  
**Phạm vi:** Tập trung toàn lực vào một khu vực liên tục (Showcase Region $160\text{m} \times 160\text{m}$), có chiều sâu địa lý, đa tầng thực vật, khí quyển điện ảnh; không mở rộng bản đồ tràn lan để đếm số lượng.

---

## 1. Hiện trạng thực tế & Xác minh môi trường (Baseline Verification)

### 1.1. Hạ tầng kỹ thuật & Git Status
- **Repository:** `https://github.com/KhoiPM23/LivingPlanetSandbox.git`
- **Branch:** `main` (Up to date với `origin/main` tại commit `6256423`)
- **Đường dẫn cục bộ:** `D:\Personal_Projects\Living Planet Sandbox`
- **Engine Runtime:** `Godot Engine v4.6.3.stable.official.7d41c59c4` (Vulkan 1.4.323 Forward+ Renderer)
- **Thiết bị kiểm thử thực tế:** `Intel(R) Iris(R) Xe Graphics`, 16 GB RAM, Windows 11 Desktop
- **Git Status:** 34 file modified, 22 file untracked (toàn bộ tiến trình nghiên cứu trước được bảo toàn nguyên vẹn; không force-pull hay reset).

### 1.2. Đối chiếu thực tế vs Báo cáo cũ (Ruthless Forensic Audit)
- **Sự thật thị giác:** Các báo cáo trước đó (`VISUAL_ACCEPTANCE_REPORT.md`, `VISUAL_REVIEW_LOG.md`) tự đánh giá điểm số cao (4.54/5.0) và tự gắn nhãn "ACCEPTANCE HOÀN TOÀN" dựa trên việc chạy pass test unit/shader. Tuy nhiên, khi kiểm tra ảnh runtime thực tế (`screenshot_first_playable.png`, `reports/visual_evidence/shot_1` đến `shot_9`):
  1. **Cây cối:** Là các khối hình nón faceted low-poly đồ chơi trẻ em với thân cây màu cam cà rốt chói lọi (`Tree_4_A`, `Tree_4_C` từ KayKit).
  2. **Địa hình:** Một mô đất mấp mô nhẵn thín phủ lớp texture xanh đen bùn lầy, thiếu hẳn vi địa hình (micro-relief), normal map bị phủ mờ bởi màu tô toán học.
  3. **Bầu trời & Khí quyển:** Bầu trời `ProceduralSky` đơn điệu kết hợp một dải sương mù xám đục từ $42\text{m}$ đến $190\text{m}$, triệt tiêu toàn bộ cảm giác chiều sâu không gian và biến đường chân trời thành một mớ súp mờ đục.
  4. **Mặt nước:** Nước hồ Emerald Cove bị lỗi hòa trộn khúc xạ kép (refraction double-add) trong shader, biến mặt hồ thành một tấm thạch silicon xám đục phẳng lì.
  5. **Giao diện (HUD):** Hai thanh sidebar đen đặc chiếm tới gần 40% diện tích màn hình hiển thị danh sách phím tắt và biểu đồ telemetry, phá nát tính nhập tâm thị giác.

---

## 2. Phân biệt rõ các tầng tài nguyên (Resource Provenance Tracking)

| Nhóm tài nguyên | Chi tiết trong dự án | Trạng thái hiện tại |
| :--- | :--- | :--- |
| **Tài nguyên đã tồn tại** | • `forest.glb` (KayKit, 396KB)<br>• `nature.glb` (Kenney, 1.2MB)<br>• `Stag.gltf`, `Deer.gltf`, `Wolf.gltf` (Quaternius, 3.2MB each)<br>• `RockA.glb`, `RockB.glb`, `RockC.glb` (Terrain3D MIT assets)<br>• `ground037_alb_ht.png`, `rock023_alb_ht.png` (ambientCG CC0 PBR textures 2K)<br>• `addons/terrain_3d/` (Terrain3D GDExtension v1.0.2 binaries) | Có sẵn trong thư mục dự án |
| **Tài nguyên đã tải** | • Đã giải nén và lưu trữ cục bộ đầy đủ trong `presentation/assets/`, `demo/assets/`, `addons/` | Đã có sẵn trên ổ cứng |
| **Tài nguyên đã tích hợp (Code level)** | • `forest.glb`, `nature.glb` được nạp trong `tree_pine.gd`, `vegetation_scatter.gd`<br>• `Stag`, `Deer`, `Wolf` nạp trong `ecosystem_presentation.gd`<br>• `ground037`, `rock023` nạp vào `terrain_pbr.gdshader`<br>• `RockA.tscn`, `RockB.tscn`, `RockC.tscn` nạp trong `rock_boulder.gd` | Đã import vào Godot |
| **Tài nguyên thực sự xuất hiện trong Runtime** | • Chỉ có `Tree_4_A` (thân cam, tán nón low-poly), cụm cỏ `Grass_2_D`, bụi đĩa bẹt `Bush_1_E`, hươu/sói Quaternius, và khối đá thô.<br>• *Phát hiện nghiêm trọng:* `RockA/B/C` có shader vật liệu `M_rock23_tp.tres` bị cấu hình sai `uv1_scale = 0.02` (kéo giãn 50 lần), khiến vân đá nứt nẻ PBR bị biến thành một vệt mờ xám không chi tiết! | Hiển thị kém chất lượng do shader và model sơ sài |

---

## 3. Phân loại thành phần hệ thống (Keep / Improve / Replace / Remove)

### 3.1. Giữ nguyên (Keep)
- **Hệ lõi mô phỏng (`core/`):** `EcosystemCoordinator`, `FloraSimulation`, `FaunaSimulation`, `EnvironmentalGrid`, `WeatherSystem`, `WorldClock`, `WorldSeed`, `WorldPersistence`.
  - *Lý do:* Chạy độc lập hoàn toàn với presentation, hiệu năng vượt trội (< 2ms/tick), mô phỏng chuỗi thức ăn, gen di truyền, khí hậu Whittaker và lưu trữ nguyên tử (atomic save) hoàn chỉnh.
- **Hệ thống Camera (`presentation/camera/free_look_camera.gd`):** Các chế độ Flycam, First-Person Walker, Orbit Inspect, Follow Entity và hệ thống Bookmark POI mượt mà.
- **Âm thanh không gian (`presentation/audio/spatial_audio_director.gd`):** Hệ thống tạo âm thanh gió hú, sóng nước vỗ bờ, chim hót ban ngày và dế đêm theo thời gian thực.

### 3.2. Giữ nhưng cải tiến (Keep & Improve)
- **Địa hình đảo (`presentation/environment/island_terrain.gd` & `terrain_pbr.gdshader`):**
  - Nâng cấp thuật toán sinh lưới: Bổ sung vi nếp nhăn địa chất (terraces, erosion rills, talus slopes).
  - Tái cấu trúc triplanar PBR shader: Thay thế các mảng màu tô toán học bằng **Height-Blended Multi-Layer PBR** tận dụng kênh Heightmap có sẵn trong `ground037_alb_ht.png` và `rock023_alb_ht.png`, tạo ranh giới giao cắt sắc nét giữa rễ cây, đất ẩm, cỏ non và đá nứt.
- **Chiếu sáng & Khí quyển (`presentation/environment/day_night_cycle.gd` & `main.tscn`):**
  - Chuyển đổi sang hệ thống chiếu sáng tự nhiên: Cân chỉnh nhiệt độ màu mặt trời thực tế (Kelvin), tăng cường độ sáng trực tiếp (`light_energy = 2.2`), thêm sương mù tán xạ hướng sáng (Forward-Scattering Anisotropic Volumetric Fog).
  - Tối ưu hóa SSAO và Tonemapping (Filmic/ACES) cho Intel Iris Xe để tạo bóng tiếp xúc sâu mà không tụt khung hình.
- **Shader mặt nước (`presentation/shaders/water.gdshader`):**
  - Khắc phục lỗi double-render screen refraction.
  - Áp dụng định luật Beer-Lambert cho độ sâu quang học, sóng Gerstner tự nhiên với normal mapping, vi bọt bờ hồ mềm mại ôm lấy sỏi đá ven bờ.
- **Giao diện HUD (`presentation/ui/hud.gd`):**
  - Mặc định khởi động ở chế độ Cinematic Immersive: Ẩn các bảng số liệu nặng nề, chỉ giữ la bàn tối giản và tâm ngắm; toàn bộ công cụ khoa học/thao túng chỉ mở khi nhấn phím `[Tab]` hoặc `[H]`.

### 3.3. Thay bằng asset hoặc giải pháp có sẵn tốt hơn (Replace)
- **Cây cối & Tán rừng (`TreePine`):**
  - *Thay thế:* Loại bỏ các mô hình conifer hình nón đồ chơi của KayKit/Kenney. Thay bằng cây lá kim/cây rừng tự nhiên với thân cây gồ ghề vỏ PBR sẫm màu và các tầng tán lá dạng cành kim xòe rộng (branch cards) với normal hướng thiên cầu (spherical normals) và viền lá alpha-scissor sắc nét.
- **Thảm thực vật tầng trệt (`VegetationScatter`):**
  - *Thay thế:* Loại bỏ các đĩa bẹt `Bush_1_E` và cọc nhọn đơn điệu. Thay bằng MultiMesh cỏ nhiều phiến cong tự nhiên, bụi dương xỉ (ferns), hoa dại đa sắc thái và lá thông rụng understory.
- **Đá tảng (`RockBoulder` & `M_rock23_tp.tres`):**
  - *Thay thế/Sửa lỗi:* Hiệu chỉnh lại vật liệu `M_rock23_tp.tres` với `uv1_scale = Vector3(0.4, 0.4, 0.4)`, kích hoạt roughness channel 3 và normal map để hiển thị trọn vẹn vân đá hoa cương nứt nẻ từ các model `RockA/B/C`.

### 3.4. Loại bỏ (Remove)
- Xóa bỏ các hình học cylinder/cone sơ khai tạo cây hình nón giao thông trong `tree_pine.gd`.
- Xóa bỏ các patch màu vertex neon làm bẩn bề mặt PBR của địa hình.

---

## 4. Xếp hạng 5 nguyên nhân lớn nhất khiến game trông kém chất lượng

| Thứ hạng | Nguyên nhân gốc rễ | Tác động thị giác (1–10) | Công sức sửa chữa | Giải pháp khắc phục nhanh & triệt để nhất |
| :---: | :--- | :---: | :---: | :--- |
| **#1** | **Cây cối dạng đồ chơi low-poly** (thân cam rực rỡ, tán lá hình nón đặc quánh như đồ chơi xếp hình) | **10.0** | Trung bình | Tái thiết kế kiến trúc cây tự nhiên: vỏ cây PBR nứt nẻ, phân tầng cành lá cong tự nhiên, tán kim dạng card đan xen có ánh sáng xuyên tán (backlight subsurface) và normal cầu. |
| **#2** | **Ánh sáng phẳng & sương mù đục súp** (ProceduralSky cyan nhạt, sương mù tuyến tính xóa sổ chân trời, thiếu độ tương phản chiều sâu) | **9.5** | Thấp | Thiết lập lại `WorldEnvironment`: Tăng Direct Sun contrast, tinh chỉnh Volumetric Fog với forward anisotropy ($0.65$), kích hoạt SSAO bán kính $1.5\text{m}$, Filmic Tonemapping giữ chi tiết vùng sáng. |
| **#3** | **Địa hình bôi màu nhân tạo & thiếu vi địa hình** (Mô đất trơn nhẵn, texture bị nhuộm màu xanh vàng toán học, slope blend bùn lầy) | **9.0** | Trung bình | Viết lại `terrain_pbr.gdshader` dùng **Height-Blend PBR** (đá lồi, rãnh đất tụ mùn, cỏ mọc kẽ đá), tăng độ phân giải vi nếp nhăn địa hình của `IslandTerrain`. |
| **#4** | **Mặt nước như tấm nhựa silicon xám đục** (Lỗi nhân đôi màu nền refraction, bọt hồ nhân tạo, thiếu độ trong suốt quang học) | **8.5** | Thấp | Sửa `water.gdshader`: Triệt tiêu double-render albedo, tinh chỉnh độ hấp thụ Beer-Lambert, normal micro-ripples sắc sảo và bờ ẩm ven hồ. |
| **#5** | **Giao diện HUD che khuất 40% màn hình & đá bị giãn texture** (UI đồ sộ như phần mềm văn phòng, vật liệu đá bị scale sai 50 lần) | **8.0** | Rất thấp | Chuyển HUD về chế độ Cinematic Minimal mặc định. Sửa `M_rock23_tp.tres` UV scale từ $0.02 \to 0.40$ làm sắc nét toàn bộ đá hoa cương. |

---

## 5. Phương án công nghệ & Kế hoạch tái sử dụng

1. **Về Địa hình (Terrain):**
   - Giữ kiến trúc Bounded Procedural Island với Trimesh Collision trong `IslandTerrain` (để bảo toàn tính tức thời của hàm `get_height_at()` cho mô phỏng sinh thái và không phụ thuộc vào driver GDExtension khi test tự động).
   - Nâng cấp shader lên **Triplanar Height-Blended PBR**: Tận dụng triệt để kênh Alpha Heightmap có sẵn trong `ground037_alb_ht.png` và `rock023_alb_ht.png`.
2. **Về Đá & Cụm địa chất:**
   - Tái sử dụng trọn vẹn bộ model granite `RockA.glb`, `RockB.glb`, `RockC.glb` và vật liệu triplanar `M_rock23_tp.tres` sau khi sửa lỗi UV scale.
3. **Về Thảm thực vật (Foliage System):**
   - Nâng cấp `MultiMeshInstance3D` cho cỏ và cây bụi: Thiết kế cụm cỏ đa phiến có độ uốn cong tự nhiên, độ cao chuyển tiếp từ bìa rừng ra đồng cỏ, kết hợp hiệu ứng dạt gió mượt mà.
4. **Về Hệ sinh thái (Fauna):**
   - Giữ nguyên bộ khung xương và 13 hoạt ảnh của Quaternius (`Stag`, `Deer`, `Wolf`), tinh chỉnh lại shader lông động vật (Roughness PBR, loại bỏ ánh nhựa bóng) và điều chỉnh khoảng cách bầy đàn tự nhiên hơn.

---

## 6. Lộ trình thực thi (Transformation Blocks & Acceptance Gates)

### **BLOCK 1 — ÁNH SÁNG, KHÍ QUYỂN & SỬA LỖI VẬT LIỆU CỐT LÕI (Thực hiện ngay trong phiên này)**
- **Nhiệm vụ 1.1:** Tinh chỉnh `M_rock23_tp.tres` (sửa UV scale $0.02 \to 0.40$, gán roughness texture channel 3, normal map).
- **Nhiệm vụ 1.2:** Viết lại shader nước `water.gdshader` (xóa lỗi double-render, thiết lập Beer-Lambert depth transmission, vi sóng Gerstner sắc nét, bờ hồ trong vắt thấy đáy sỏi).
- **Nhiệm vụ 1.3:** Tái cấu trúc môi trường `WorldEnvironment` và `day_night_cycle.gd` (Direct sun energy $2.2$, Volumetric Fog anisotropic scattering, SSAO tuned for Iris Xe, ACES/Filmic tonemap).
- **Nhiệm vụ 1.4:** Thiết lập HUD Minimal Exploration Mode mặc định (`scenes/main.tscn` / `hud.gd`).
- **Nhiệm vụ 1.5:** Chụp kiểm chứng runtime thực tế và đánh giá trực quan.

### **BLOCK 2 — NÂNG CẤP ĐỊA HÌNH & TRI-PLANAR HEIGHT-BLENDED SHADING**
- **Nhiệm vụ 2.1:** Thêm vi nếp nhăn địa chất (strata terraces, eroded creek bed, rock outcrops) trong `island_terrain.gd`.
- **Nhiệm vụ 2.2:** Hoàn thiện `terrain_pbr.gdshader` với thuật toán Height-Blending PBR tự nhiên giữa đá nứt, đất ẩm rừng thông và đồng cỏ ngập nắng.
- **Nhiệm vụ 2.3:** Kiểm chứng góc nhìn Walker cận cảnh bề mặt đất đá ($1.7\text{m}$).

### **BLOCK 3 — CHUYỂN ĐỔI KIẾN TRÚC CÂY TỰ NHIÊN & TÁN RỪNG CHIỀU SÂU**
- **Nhiệm vụ 3.1:** Chấm dứt việc dùng conifer hình nón low-poly của KayKit. Thiết kế hệ thống cành nhánh tự nhiên với vỏ cây PBR tối màu và phiến lá kim xòe rộng.
- **Nhiệm vụ 3.2:** Tích hợp spherical normals và subsurface translucency cho tán cây.
- **Nhiệm vụ 3.3:** Đảm bảo rừng Whispering Forest tạo ra vòm lá tự nhiên (natural canopy framing) hùng vĩ.

### **BLOCK 4 — THẢM THỰC VẬT ĐỒNG CỎ & BỜ NƯỚC SỐNG ĐỘNG**
- **Nhiệm vụ 4.1:** MultiMesh cỏ PBR nhiều cụm lá, đan xen dương xỉ, hoa dại và rễ cây understory.
- **Nhiệm vụ 4.2:** Bãi sỏi talus và đá cuội ven bờ hồ với độ ẩm ướt chân sóng tự nhiên.

### **BLOCK 5 — ĐỒNG BỘ HỆ SINH THÁI, HIỆU NĂNG INTEL IRIS XE & NGHIỆM THU CUỐI CÙNG**
- **Nhiệm vụ 5.1:** Tinh chỉnh hành vi đàn hươu, dáng đứng và đổ bóng tiếp xúc của muông thú.
- **Nhiệm vụ 5.2:** Profile hiệu năng toàn diện trên Vulkan Forward+ (duy trì $\ge 40\text{ FPS}$ tại 1280×720).
- **Nhiệm vụ 5.3:** Xuất bản bộ 9 góc chụp kiểm chứng chuẩn và nghiệm thu sản phẩm.
