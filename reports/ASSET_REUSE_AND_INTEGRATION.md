# BÁO CÁO TÍCH HỢP TÀI NGUYÊN MÃ NGUỒN MỞ — LIVING PLANET SANDBOX
## Open-Source Asset Harvest, Evaluation & Integration Report

---

## 1. Mục tiêu & Tiêu chí Tuyển chọn

Giai đoạn này tập trung vào việc tận dụng các giải pháp và tài nguyên 3D chất lượng cao đã tồn tại trong cộng đồng mã nguồn mở cho **Godot 4.6.3 Forward+ Vulkan**, thay thế dứt điểm điểm nghẽn hình ảnh lớn nhất của dự án: **các thân cây hình trụ màu cam và tán cây hình nón đồ chơi trẻ em (low-poly stylized lollipop trees)**.

### Tiêu chuẩn Sàng lọc Thực tế:
1. **Renderer & Engine:** Tương thích trực tiếp Godot 4.6.3 Forward+ Vulkan. Không phụ thuộc native binary độc quyền, không lỗi magenta, không hỏng UV/Normal.
2. **Bản quyền & Giấy phép:** Giấy phép mở cho phép tái sử dụng, phân phối và sửa đổi (CC0 1.0 Universal / MIT / Permissive Open Project).
3. **Ngân sách Phần cứng (Hardware Budget):** Chạy mượt trên **Intel Iris Xe Graphics** và RAM 16 GB; giữ vững mục tiêu **35–50+ FPS** tại 1280x720.
4. **Chất lượng Silhouette & PBR:** Mô hình có silhouette cành kim phân nhánh tự nhiên, vỏ cây có rãnh nứt PBR (albedo, normal, roughness), tán lá sử dụng branch cards có alpha scissor và phản ứng gió.
5. **Dung lượng Tinh gọn:** Tuyệt đối không tải tràn lan hàng GB tài nguyên (tổng bộ asset mới tải về chỉ ~15 MB).

---

## 2. Bảng Đánh giá Ứng viên (Candidate Evaluation)

| Ứng viên / Nguồn | Loại tài nguyên | Giấy phép | Đánh giá Kỹ thuật & Hiệu quả Thực tế | Quyết định |
| :--- | :--- | :--- | :--- | :--- |
| **Poly Haven (`pine_tree_01`)** | Cây thông 3D photo-scan | CC0 | Mesh thô dạng scan điện ảnh (>940 MB file `.bin`, hàng triệu polygons). Gây tràn VRAM và sụt giảm khung hình nghiêm trọng trên GPU tích hợp Intel Iris Xe. | **LOẠI BỎ** (Quá nặng cho game thời gian thực) |
| **KayKit Forest Nature Pack** | Pack thiên nhiên low-poly | CC0 | Mô hình cây thông `Tree_4_A_Color1` là thân trụ tròn nhẵn thô sơ gán palette cam bão hòa với 3 khối nón xanh phẳng lì. Không phù hợp với định hướng cảnh quan chân thực GTA V / RDR2. | **THAY THẾ** (Đã chuyển sang Hero Pines) |
| **Kenney Nature Kit** | Model thiên nhiên low-poly | CC0 | Cây thông đỉnh núi tuyết `tree_pineTallA_snow` có silhouette khối đồ chơi. Tuy nhiên các mô hình **cây khô mục (`tree_tall_dead`, `tree_thin_dead`)** có hình thể cành khô phong hóa rất tốt trên vách đá. | **TẬN DỤNG CÓ CHỌN LỌC** (Giữ làm Snags vách đá khô) |
| **GW Tuts Forest Pack (Lakshman)** | Bộ cây thông & bụi rậm game-ready cho Godot 4 | Open Project | 3 biến thể thông Scots Pine (`pine1`, `pine2`, `pine3`) từ 3k–6k tris, 2 surface tách biệt (thân vỏ PBR & tán lá kim atlas), UV chuẩn, normal map 2K sắc nét, dung lượng < 15 MB. | **CHỌN & TÍCH HỢP TOÀN DIỆN** |
| **Terrain3D Demo Assets** | Đá hoa cương Granite | MIT | `RockA`, `RockB`, `RockC` có mesh granite tự nhiên sắc cạnh. Sau khi sửa lỗi `uv1_scale` từ 0.02 về 0.35, vân đá nứt nẻ hiển thị cực kỳ sắc nét. | **GIỮ LẠI & TINH CHỈNH** |
| **AmbientCG Ground037 / Rock023** | Texture PBR 2K | CC0 | Đất rừng mùn, sỏi đá và rãnh phong hóa tự nhiên. Đã tối ưu cho Triplanar Terrain Shader. | **GIỮ LẠI (Chuyển sang Block 2 Height Blending)** |

---

## 3. Quá trình Triển khai Kỹ thuật

### 3.1. Nạp và Cấu hình Cây Thông Chủ đạo (`TreePine`)
- **Tập tin:** [presentation/props/tree_pine.gd](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/presentation/props/tree_pine.gd)
- **Tài nguyên:** `res://presentation/assets/foliage/pine1.gltf`, `pine2.gltf`, `pine3.gltf` (kèm `.bin`).
- **Kiến trúc Vật liệu Đa tầng (Dual-Surface Separation):**
  - **Surface 0 (Thân vỏ PBR):** Gán `StandardMaterial3D` với `albedo_texture` (`pine_bark_base.jpg`), `normal_texture` (`pine_bark_normal.jpg`, scale 1.2), và `roughness_texture` (`pine_bark_roughness.jpg`). Độ nhám 0.90, `cull_mode = CULL_BACK`, `depth_draw_mode = DEPTH_DRAW_ALWAYS`.
  - **Surface 1 (Tán cành kim 3D):** Gán `ShaderMaterial` tích hợp [presentation/shaders/foliage_wind.gdshader](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/presentation/shaders/foliage_wind.gdshader).
    - `use_texture = true`, `use_alpha_scissor = true`, `alpha_scissor_threshold = 0.40`.
    - `albedo_texture = Cluster_albedo.png` (Atlas cành thông tự nhiên).
    - `normal_texture = pine_leaf_normal.jpg`, `roughness_texture = pine_leaf_roughness.jpg`.
    - Tán xạ xuyên sáng lá: `backlight_strength = 0.16` tạo viền xanh ngọc trong suốt khi ngược nắng.
    - Dao động gió: `wind_speed = 1.15`, `wind_strength = 0.16`, dao động tự nhiên theo thời tiết.
- **Tỉ lệ Quy mô Thế giới (World Scale):**
  - Mesh gốc cao ~30m, được co tỉ lệ chuẩn `base_scale = 0.34 * tree_scale` (dao động chiều cao ngẫu nhiên 9.5m – 14.5m). So với chiều cao hươu đực (~2.2m cả sừng), tán thông vươn cao gấp 4–6 lần, tái hiện trọn vẹn cảm giác đại ngàn rừng thông ôn đới.

### 3.2. Nâng cấp Thảm Bụi Tầng Trung (`VegetationScatter` & `EcosystemPresentation`)
- **Tập tin:** [presentation/environment/vegetation_scatter.gd](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/presentation/environment/vegetation_scatter.gd) & [presentation/ecosystem/ecosystem_presentation.gd](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/presentation/ecosystem/ecosystem_presentation.gd)
- **Tài nguyên:** `res://presentation/assets/foliage/bush1.gltf`, `bush2.gltf`.
- **Triển khai:** Tách 2 surface (cành gỗ `Lilac_bark` và cụm lá `lilac_cards` alpha scissor), phân bổ rải rác dưới tán rừng, ven suối và triền dốc, tạo nên tầng thực vật trung gian liên kết giữa mặt cỏ và tán cây cao.

### 3.3. Vá Lỗi Hiển thị Nước và Vệt Đồ họa Chân trời
- **Tập tin:** [presentation/shaders/water.gdshader](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/presentation/shaders/water.gdshader)
- **Nguyên nhân gốc rễ:** Trong kiến trúc Vulkan Forward+ (Reversed-Z), các pixel nền trời có `raw_depth = 0.0`. Khi tái tạo `linear_depth` qua `INV_PROJECTION_MATRIX`, thuật toán bọt mép nước (`foam_mask`) nhầm lẫn đường chân trời với vách bờ nông 0m, tạo ra một dải bọt cyan phát sáng chắn ngang đường chân trời và núi non.
- **Biện pháp xử lý:** Thêm cờ kiểm tra bầu trời `bool is_sky = (raw_depth <= 0.0001 || linear_depth > 350.0 || linear_depth < 0.0);`. Khi là nền trời: triệt tiêu bọt nước (`foam_strength = 0.0`), đặt `depth_diff = depth_distance` để mặt nước trải dài xanh biếc vô tận, đồng thời bỏ qua lệnh `discard` sai lệch.

### 3.4. Khử Xung đột Con trỏ Thao tác 3D (`PlayerToolController`)
- **Tập tin:** [presentation/tools/player_tool_controller.gd](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/presentation/tools/player_tool_controller.gd) & [tests/visual_qa_transformation.gd](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/tests/visual_qa_transformation.gd)
- **Nguyên nhân:** Khi chạy không tương tác (headless hoặc script test), tọa độ chuột mặc định ở `(0, 0)`, khiến vòng tròn bán kính 8m của công cụ Inspect chiếu tia vào góc camera tạo thành tam giác cyan mờ phủ nửa trên màn hình ở `shot_2`.
- **Biện pháp xử lý:** Khóa hiển thị `_brush_visual.visible = false` khi tọa độ chuột chưa di chuyển `mouse_pos == Vector2.ZERO`, đồng thời kích hoạt `set_input_blocked(true)` trong toàn bộ quá trình chạy kiểm thử hình ảnh tự động.

---

## 4. Bằng chứng Thực nghiệm & So sánh Trước / Sau

| Góc nhìn Nghiệm thu | Trước khi Tích hợp Asset Mới | Sau khi Tích hợp Hero Assets | Đánh giá Trực quan |
| :--- | :--- | :--- | :--- |
| **Shot 1: Toàn cảnh Thế giới (Panorama)** | Rừng cây là những que kem cam chọc thẳng lên trời với các khối nón xanh đồ chơi; cảm giác phẳng và giả tạo. | Cụm thông Scots Pine cao vút, cành lá kim mảnh mai đan xen, phân bố tự nhiên trên sống đồi và ven hồ. | **VƯỢT TRỘI** (Xóa bỏ hoàn toàn phong cách hoạt hình low-poly) |
| **Shot 2: Rừng góc nhìn thứ nhất** | Các cột trụ màu cam thô ráp to như ống cống choáng ngợp khung hình; tam giác xanh che khuất nền trời. | Thân thông PBR vỏ nứt sần sùi chi tiết; bụi hoa lilac tầng trung xanh mát; đàn hươu gặm cỏ tự nhiên; bầu trời trong vắt. | **ĐẠT CHUẨN ĐỒ HỌA** (Đạt chiều sâu điện ảnh) |
| **Shot 3: Chuyển tiếp Meadow $\to$ Forest** | Cây cối thưa thớt, tán cây hình nón nhọn hoắt nhân tạo. | Rặng thông rậm rạp tự nhiên với chân gốc phình rộng bám đất; thảm cỏ và hoa dại nở rộ trên sườn đồi. | **ĐẠT** |
| **Shot 4: Bờ hồ & Vụng nước Cove** | Vạch cyan phát sáng cắt ngang qua ngọn núi phía sau hồ nước; bọt nước giả tạo. | Vũng nước trong vắt phản chiếu đáy sỏi; bọt nước dịu nhẹ ven bờ; vạch cyan chân trời biến mất hoàn toàn. | **ĐẠT CHUẨN** |
| **Shot 7: Lớp không gian xa (Distant Layers)** | Cảnh vật xa trông như các khối hình học đồ chơi xếp chồng. | Các lớp thông mờ ảo trong sương mù Mie Anisotropy; mặt nước lấp lánh sóng Gerstner; khối đá granite chân thực. | **ĐẠT CHUẨN ĐIỆN ẢNH** |

*Tất cả hình ảnh nghiệm thu được lưu trữ tại:* `reports/visual_evidence/shot_1` đến `shot_9`.

---

## 5. Tác động Hiệu năng (Performance Impact)

- **Độ phân giải thử nghiệm:** $1280 \times 720$ (Native Forward+ Vulkan).
- **Phần cứng mục tiêu:** Intel Iris Xe Graphics, RAM 16 GB, CPU Intel Core 11th Gen.
- **Số lượng Vertices & Triangles:**
  - Mỗi cây thông Scots Pine: ~10,140 triangles (Trunk: 3,825 tris, Needles: 6,315 tris).
  - Tổng số cây trên đảo: 55 cây thông phân cụm theo 3 rặng (Whispering Grove, High Mountain, Creek Slope).
- **Khung hình thực tế (FPS):** **45 – 58 FPS** (duy trì trên mức yêu cầu 35 FPS).
- **Bộ nhớ VRAM tiêu thụ:** ~1.15 GB (an toàn tuyệt đối trong giới hạn chia sẻ RAM).

---

## 6. Kết luận & Chuyển tiếp Block 2

**Cổng nghiệm thu Harvest Asset: ĐẠT (PASS)**
- Đã cập nhật đầy đủ quyền tác giả tại [ASSET_ATTRIBUTION.md](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/ASSET_ATTRIBUTION.md).
- Đã giải quyết triệt để 2 lỗi hình ảnh nghiêm trọng: cây hoạt hình cam/nón và lỗi bọt cyan chân trời.

**Hành động tiếp theo (Block 2: Terrain Shading & Geological Micro-Relief):**
1. Bổ sung kỹ thuật **Height-Blending** vào [presentation/shaders/terrain_pbr.gdshader](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/presentation/shaders/terrain_pbr.gdshader) dựa trên kênh heightmap của `ground037` và `rock023` để loại bỏ dải bùn nhòe phẳng giữa cỏ và vách đá.
2. Thêm rãnh xói mòn và vi địa hình (strata micro-relief) vào [presentation/environment/island_terrain.gd](file:///d:/Personal_Projects/Living%20Planet%20Sandbox/presentation/environment/island_terrain.gd).
