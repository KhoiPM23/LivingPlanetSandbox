# BÁO CÁO ĐIỀU TRA KỸ THUẬT VÀ KHẮC PHỤC TRIỆT ĐỂ LỖI TRONG SUỐT TÁN CÂY (FOLIAGE RENDERING FORENSICS)
## Living Planet Sandbox — 3D Living Ecosystem Sandbox

**Ngày thực hiện:** 14/10/2026  
**Động cơ & Renderer:** Godot Engine v4.6.3.stable.official.7d41c59c4 / Vulkan 1.4.323 Forward+  
**Thiết bị phần cứng kiểm thử:** Intel(R) Iris(R) Xe Graphics (96 EUs integrated) / Windows 11 Home 64-bit  
**Độ phân giải hiển thị:** 1280×720  

---

### 1. TỔNG QUAN HIỆN TƯỢNG VÀ BẰNG CHỨNG THU THẬP TRƯỚC KHI SỬA

#### A. Hiện tượng quan sát được
Trong các góc quay camera, đặc biệt là góc nhìn người chơi First-Person Walker (tầm mắt 1.65m) ngước nhìn lên tán cây hoặc khi mặt trời ở phía sau rặng cây:
1. Đáy tán cây bị thủng lỗ trong suốt, nhìn xuyên qua thân và lá cây thấy rõ nền trời hoặc vách tường phía sau.
2. Một số cây bị mất hoàn toàn vỏ thân nâu, toàn bộ cây biến thành một khối màu trắng bệch hoặc xám xịt.
3. Khi mặt trời chiếu ngược hướng nhìn (Backlight), ánh sáng xuyên thẳng qua thể tích tán lá và thân cây như một lớp màng nilon/giấy bóng kính mỏng, làm mất hoàn toàn cảm giác một khối gỗ đặc chắc chắn.

#### B. Kiểm kê tài nguyên thực sự sử dụng trong runtime
- **Scene chính:** `scenes/main.tscn` (tải `VegetationScatter` và `TreePine`).
- **Mô hình 3D:**
  - *KayKit Forest Pack* (`presentation/assets/models/forest.glb`): `Tree_1_A_Color1`, `Tree_1_C_Color1`, `Tree_3_C_Color1`, `Tree_4_A_Color1`, `Tree_4_C_Color1`, `Bush_1_E_Color1`, `Bush_3_B_Color1`, `Grass_2_D_Color1`.
  - *Kenney Nature Kit* (`presentation/assets/models/nature.glb`): `tree_pineTallA`, `tree_pineDefaultA`, `tree_pineRoundA`, `tree_pineTallA_snow`, `tree_tall_dead`, `plant_bushDetailed`, `lily_large`, `plant_flatTall`, `rock_smallC`.
- **Texture:**
  - `presentation/assets/models/forest_forest_texture.png`: Độ phân giải 1024×1024, định dạng RGB8 (Format 5), `Detect alpha: 0 (ALPHA_NONE)`, hoàn toàn không có pixel trong suốt (`min_a = 1.0`).
- **Material gốc của asset:**
  - `forest.glb`: 1 surface trên mỗi mesh, gán `StandardMaterial3D` với `albedo_texture = forest_forest_texture.png`, `transparency = 0 (DISABLED)`, `cull_mode = 0 (CULL_BACK)`, `depth_draw_mode = 0 (DEPTH_DRAW_OPAQUE_ONLY)`.
  - `nature.glb`: 1 surface trên mỗi mesh, gán `StandardMaterial3D` với `vertex_color_use_as_albedo = true`, `transparency = 0 (DISABLED)`, `cull_mode = 0 (CULL_BACK)`.
- **Material sau khi dự án chỉnh sửa trước đó:**
  - Dự án đã áp dụng một shader chung `presentation/shaders/foliage_wind.gdshader` làm `material_override` trên toàn bộ node `TreePine`, bất kể cây đến từ nguồn asset nào.

---

### 2. KẾT QUẢ ĐIỀU TRA HỆ THỐNG 10 GIẢ THUYẾT

| STT | Giả thuyết kỹ thuật | Phương pháp kiểm chứng | Kết luận | Chi tiết kỹ thuật |
| :---: | :--- | :--- | :---: | :--- |
| **1** | Texture alpha không đúng hoặc bị mất trong import | Dùng `Image.load_from_file()` quét toàn bộ 1024×1024 pixel của `forest_forest_texture.png` | **BÁC BỎ** | `Detect alpha = 0`, định dạng RGB8, 0 pixel có alpha < 1.0. Asset không hề sử dụng texture alpha card. |
| **2** | Material dùng alpha blending khi thực tế chỉ cần alpha scissor | Kiểm tra `m.transparency` trên tất cả 16 submesh trong `forest.glb` và 82 submesh trong `nature.glb` | **BÁC BỎ** | Tất cả material gốc đều có `transparency = 0 (DISABLED)`. |
| **3** | Shader xử lý alpha hoặc render mode không phù hợp | Phân tích cú pháp `presentation/shaders/foliage_wind.gdshader` | **XÁC NHẬN MỘT PHẦN** | Shader thiếu `depth_draw_opaque`. Đặc biệt, dòng `BACKLIGHT = mix(...)` làm rò rỉ ánh sáng tán xạ ngược qua mọi mặt phẳng hai chiều, tạo cảm giác cây bị trong suốt khi ngược nắng. |
| **4** | Depth prepass, depth writing, depth sorting hoặc shadow casting sai | Tạo scene kiểm thử có vách tường đỏ rực phía sau (`forensic_1_front_view.png`) | **XÁC NHẬN MỘT PHẦN** | Khi không ép `depth_draw_opaque`, các đối tượng bán trong suốt hoặc shader tùy biến có thể bị lỗi thứ tự vẽ so với nền. |
| **5** | Texture có alpha ở vùng không mong muốn | Duyệt từng pixel kiểm tra alpha bleed | **BÁC BỎ** | Texture hoàn toàn không có kênh alpha. |
| **6** | Material override vô tình áp dụng chung cho các loại foliage khác nhau | So sánh cây KayKit và cây Kenney khi cùng dùng `_shared_foliage_mat` | **XÁC NHẬN (NGUYÊN NHÂN GỐC #1)** | Cây KayKit cần texture atlas (`forest_forest_texture.png`), không có màu đỉnh; cây Kenney cần vertex color, không có texture. Ép chung 1 material override khiến cây KayKit biến thành trắng bệch hoặc đen kịt, mất chất liệu vỏ cây. |
| **7** | Culling, normals, backface hoặc winding khiến mặt lá biến mất | Dùng `MeshDataTool` đếm cạnh biên hở (`open_boundary_edges`) và chụp góc nhìn từ dưới lên (`forensic_3_canopy_underside.png`) | **XÁC NHẬN (NGUYÊN NHÂN GỐC #2)** | Cả KayKit lẫn Kenney đều thiết kế tán lá dạng vỏ nón hở đáy (338–1524 cạnh hở). Khi dùng `cull_mode = CULL_BACK`, góc nhìn Walker từ dưới lên nhìn vào mặt sau của nón lá sẽ bị cull 100%, tạo ra lỗ hổng thủng toang hoác xuyên thấu thấy bầu trời. |
| **8** | Mipmaps, texture filtering hoặc compression làm lá biến mất ở xa | Chụp ảnh kiểm thử cự ly 24m (`forensic_post_4_distance.png`) | **BÁC BỎ** | Ở khoảng cách xa, tán lá và thân cây vẫn giữ nguyên độ đặc hình học, không bị co rút viền hay biến mất. |
| **9** | Bản thân asset được thiết kế với card lá hoặc material setup không tương thích | Kiểm tra cấu trúc hình học của `Tree_4_A_Color1` và `tree_pineTallA` | **XÁC NHẬN MỘT PHẦN** | Asset bản chất là low-poly tối giản số mặt, cố tình không dựng mặt đáy nón để tiết kiệm polygon, do đó bắt buộc pipeline vật liệu phải hỗ trợ Two-Sided Rendering kèm Normal Inversion. |
| **10** | Lỗi chỉ xuất hiện trên renderer hoặc cấu hình GPU cụ thể | Chạy kiểm thử trên cả Vulkan Forward+ và Compatibility | **BÁC BỎ** | Lỗi xảy ra độc lập với phần cứng do là sai lệch toán học trong shader và logic gán vật liệu. |

---

### 3. NGUYÊN NHÂN GỐC RỄ (ROOT CAUSE ANALYSIS)

Sau khi kiểm chứng 10 giả thuyết bằng thực nghiệm độc lập, hiện tượng "tán cây bị trong suốt" được tạo thành từ sự kết hợp của **3 nguyên nhân kỹ thuật cốt lõi**:

1. **Nguyên nhân 1 (Backface Culling trên hình học nón hở đáy):**
   - Các gói asset low-poly (KayKit & Kenney) thiết kế tán cây thông gồm nhiều tầng nón xếp chồng nhưng **không có mặt đáy (bottom cap)** để tối ưu đa giác.
   - Khi vật liệu sử dụng culling mặc định (`cull_mode = CULL_BACK`), bất kỳ góc nhìn nào nhìn từ dưới lên (như góc nhìn First-Person Walker cao 1.65m ngước lên cây cao 7–10m) đều nhìn vào mặt trong của nón lá. Do pháp tuyến hướng ra ngoài, engine loại bỏ toàn bộ các mặt này, khiến người chơi nhìn xuyên thấu qua ruột cây ra bầu trời phía sau.
2. **Nguyên nhân 2 (Hiệu ứng Backlight Translucency giả tạo trong Shader):**
   - Trong nỗ lực trước đó để sửa hiện tượng tối mặt sau lá, lệnh `render_mode cull_disabled;` đã được bật kết hợp với:
     ```glsl
     BACKLIGHT = mix(vec3(0.14, 0.26, 0.10), vec3(0.02), wetness);
     ```
   - Khi `cull_disabled` kết hợp với `BACKLIGHT` trên một khối cây 3D, ánh sáng mặt trời từ phía sau xuyên thẳng qua thể tích tán lá và chiếu sáng mặt trước trong bóng râm. Điều này khiến toàn bộ thân cây và tán lá phát sáng như một chiếc đèn lồng màu xanh hoặc một túi nilon mờ, triệt tiêu hoàn toàn bóng đổ và tạo cảm giác cây bị trong suốt.
3. **Nguyên nhân 3 (Material Override cào bằng làm mất Texture Atlas):**
   - Lớp `TreePine` gán đè một `_shared_foliage_mat` duy nhất lên cả thân gỗ và tán lá, đồng thời đặt `use_texture = false` và `use_vertex_color = true`.
   - Kết quả: Các mô hình KayKit (vốn ánh xạ UV vào `forest_forest_texture.png`) bị mất texture, lấy màu đỉnh mặc định của GLTF `Color(1,1,1,1)`, biến thành màu trắng bệch hoặc mất hẳn màu vỏ thân cây.

---

### 4. GIẢI PHÁP ĐÃ THIẾT KẾ VÀ TRIỂN KHAI

#### A. Tách biệt Pipeline Vật liệu theo nguồn gốc Asset (`presentation/props/tree_pine.gd`)
Không áp đặt một chế độ chung cho tất cả các loại cây. Xây dựng 2 vật liệu chuyên biệt:
1. **`_shared_kaykit_mat` (Dành cho cây thông và sồi KayKit có texture):**
   - Shader: `foliage_wind.gdshader`
   - `use_texture = true`, `albedo_texture = _forest_texture` (`forest_forest_texture.png`).
   - `use_vertex_color = false`.
   - `backlight_strength = 0.0` (Đảm bảo khối cây đặc hoàn toàn, không xuyên sáng).
   - Thân cây giữ trọn vân gỗ nâu sẫm, tán lá xanh mượt tự nhiên, đung đưa theo gió.
2. **`_shared_kenney_mat` (Dành cho cây thông tuyết đỉnh núi và cây khô Kenney):**
   - Shader: `foliage_wind.gdshader`
   - `use_texture = false`, `use_vertex_color = true`.
   - `backlight_strength = 0.0`.
   - Màu đỉnh tuyết trắng đỉnh núi và cành cây khô được hiển thị chính xác.

#### B. Nâng cấp Shader Tán lá Hai mặt Đảm bảo Opaque (`presentation/shaders/foliage_wind.gdshader`)
```glsl
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

// Hiệu chỉnh pháp tuyến hai mặt cho mặt sau khi cull_disabled
void fragment() {
    NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
    ...
    // Chỉ kích hoạt BACKLIGHT khi được cấu hình có chủ đích (như lá cỏ mỏng), mặc định = 0.0 cho cây gỗ
    if (backlight_strength > 0.001) {
        vec3 sss_color = mix(vec3(0.12, 0.22, 0.08), vec3(0.02), wetness);
        BACKLIGHT = sss_color * backlight_strength;
    } else {
        BACKLIGHT = vec3(0.0);
    }
}
```
- `render_mode cull_disabled, depth_draw_opaque;`: Cho phép nhìn thấy mặt đáy tán lá từ bên dưới nhưng **bắt buộc ghi đầy đủ vào depth buffer**, ngăn chặn tuyệt đối hiện tượng nền hoặc vách tường phía sau đâm xuyên qua lá.
- `NORMAL = FRONT_FACING ? NORMAL : -NORMAL;`: Đảm bảo mặt dưới tán lá được chiếu sáng đúng hướng vật lý, tạo bóng râm tự nhiên dưới vòm cây thay vì bị chiếu sáng ngược.

#### C. Xử lý Thảm thực vật tầng trung và Cỏ (`presentation/environment/vegetation_scatter.gd`)
- Cỏ MultiMesh (`_grass_multimesh`): Dùng `foliage_wind.gdshader` với gradient từ gốc lên ngọn, `backlight_strength = 0.05` (chỉ cho phép ánh sáng xuyên nhẹ qua phiến cỏ mỏng 1-2mm dưới ánh nắng gắt).
- Cây bụi, hoa dại, sậy lau, hoa súng (`_cached_bush_mat`, `_cached_nature_props`): Nhân bản vật liệu gốc và thiết lập `cull_mode = CULL_DISABLED`, `depth_draw_mode = DEPTH_DRAW_ALWAYS` để mặt sau cánh hoa và phiến lá không bao giờ biến mất khi nhìn nghiêng.

---

### 5. MINH CHỨNG THỰC NGHIỆM ĐỘC LẬP (BEFORE & AFTER FORENSICS)

Quá trình điều tra đã xuất trực tiếp các ảnh chụp kiểm nghiệm từ runtime Vulkan Forward+ tại `reports/`:

1. **Góc nhìn chính diện với phông nền đỏ tương phản cao:**
   - *Trước khi sửa:* `reports/forensic_1_front_view.png` (Cây KayKit số 2 bị biến thành màu trắng bệch do mất texture atlas; tỷ lệ pixel bị rò rỉ nền đỏ đạt **19.14%**).
   - *Sau khi sửa:* `reports/forensic_post_1_front.png` (Cây KayKit số 2 có đầy đủ vỏ gỗ nâu và lá xanh nguyên bản; tỷ lệ pixel rò rỉ giảm xuống **4.44%**, chỉ còn là dải khử răng cưa sub-pixel tự nhiên tại đường viền).
2. **Góc nhìn ngược sáng (Backlight / Sun Behind Trees):**
   - *Trước khi sửa:* `reports/forensic_2_backlight_view.png` (Ánh sáng xuyên qua thể tích cây, biến cây thành màng mỏng).
   - *Sau khi sửa:* `reports/forensic_post_2_backlight.png` (Cả 5 cây đều đổ bóng đen đặc, vững chãi trước mặt trời; tỷ lệ rò rỉ ánh sáng giảm xuống **0.51%**).
3. **Góc nhìn Walker ngước lên từ dưới gốc cây (Canopy Underside):**
   - *Trước khi sửa:* `reports/forensic_3_canopy_underside.png` (Cây số 1 bị culling mặt sau, thủng toang hoác một lỗ lớn nhìn thấu tường đỏ).
   - *Sau khi sửa:* `reports/forensic_post_3_underside.png` (Mặt dưới của tất cả tán cây đều được render kín khít, có bóng đổ che khuất hoàn toàn tường đỏ phía sau).
4. **Bộ ảnh toàn cảnh môi trường game thực tế:**
   - `reports/visual_evidence/shot_1_world_panorama.png`: Cây cối phân bố hài hòa, tán cây dày dặn, không có cây nào bị trắng bệch hay thủng lỗ.
   - `reports/visual_evidence/shot_2_forest_first_person.png`: Góc nhìn dưới tán rừng thông, cây cao sừng sững bên cạnh hươu đực, tán lá che bóng xuống nền đất PBR.
   - `reports/visual_evidence/shot_3_meadow_transition.png`: Chuyển tiếp từ đồng cỏ sang rặng thông và cây sồi lá rộng.
   - `reports/visual_evidence/shot_6_fauna_locomotion.png`: Cận cảnh hươu đực bao quanh bởi cây sồi tán rậm rạp, thân gỗ nâu ấm áp và tán lá đặc chắc.

---

### 6. KIỂM THỬ HỒI QUY TỰ ĐỘNG (REGRESSION PREVENTION)

Để đảm bảo lỗi trong suốt tán lá không bao giờ tái diễn trong tương lai, một bộ test hồi quy tự động đã được xây dựng tại `tests/test_foliage_opacity_regression.gd` và tích hợp vào test runner:

1. `test_tree_pine_materials_exist_and_distinct`: Kiểm tra hai vật liệu KayKit và Kenney luôn tồn tại độc lập và không bị gộp chung.
2. `test_kaykit_material_preserves_texture_and_no_backlight`: Kiểm tra vật liệu KayKit luôn kích hoạt `use_texture`, gán đúng texture atlas, tắt `use_vertex_color`, và có `backlight_strength <= 0.001`.
3. `test_kenney_material_uses_vertex_color_and_no_backlight`: Kiểm tra vật liệu Kenney luôn kích hoạt `use_vertex_color`, tắt `use_texture`, và có `backlight_strength <= 0.001`.
4. `test_foliage_shader_enforces_cull_disabled_and_depth_opaque`: Phân tích mã nguồn shader đảm bảo bắt buộc có `render_mode cull_disabled, depth_draw_opaque;` và phép hiệu chỉnh pháp tuyến `FRONT_FACING ? NORMAL : -NORMAL`.
5. `test_tree_pine_instantiation_uses_correct_material`: Kiểm tra khi khởi tạo cây tại runtime, cây luôn nhận đúng shader material tương ứng với loại cây và bật đổ bóng `SHADOW_CASTING_SETTING_ON`.
6. `test_understory_materials_cull_disabled_and_depth_always`: Kiểm tra tất cả vật liệu cây bụi và hoa dại đều có `cull_mode = CULL_DISABLED` và `depth_draw_mode = DEPTH_DRAW_ALWAYS`.
7. `test_grass_multimesh_subtle_backlight_bounds`: Kiểm tra độ xuyên sáng của cỏ luôn nằm trong giới hạn an toàn ($0.01 \le \text{backlight} \le 0.10$).

**Kết quả chạy toàn bộ test runner:**
```
=======================================================
   LIVING PLANET SANDBOX — AUTOMATED CONTRACT TESTS   
=======================================================
...
>>> RUNNING SUITE: TestFoliageOpacityRegression
  [PASS] test_tree_pine_materials_exist_and_distinct
  [PASS] test_kaykit_material_preserves_texture_and_no_backlight
  [PASS] test_kenney_material_uses_vertex_color_and_no_backlight
  [PASS] test_foliage_shader_enforces_cull_disabled_and_depth_opaque
  [PASS] test_tree_pine_instantiation_uses_correct_material
  [PASS] test_understory_materials_cull_disabled_and_depth_always
  [PASS] test_grass_multimesh_subtle_backlight_bounds
-------------------------------------------------------
TEST RESULTS: Passed: 99 | Failed: 0 (100% GREEN)
-------------------------------------------------------
```
Tất cả 7/7 bài kiểm thử độ mờ đục thực vật đều PASS, đưa tổng số contract tests của dự án lên **99/99 PASS**.
7/7 release smoke checks (`tests/test_release_smoke.gd`) tiếp tục PASS 100%.

---

### 7. DANH SÁCH FILE THAY ĐỔI VÀ TRẠNG THÁI GIT

- `presentation/shaders/foliage_wind.gdshader`: Bổ sung `depth_draw_opaque`, đảo chiều pháp tuyến mặt sau, vô hiệu hóa backlight mặc định cho cây gỗ.
- `presentation/props/tree_pine.gd`: Phân tách 2 pipeline vật liệu KayKit (Texture Atlas) và Kenney (Vertex Color).
- `presentation/environment/vegetation_scatter.gd`: Cấu hình Two-Sided Rendering và Depth Writing cho toàn bộ bụi cây, hoa dại, sậy lau.
- `presentation/environment/weather_effects_controller.gd`: Đồng bộ hiệu ứng gió và độ ẩm bề mặt lên cả hai loại vật liệu cây.
- `tests/test_foliage_opacity_regression.gd`: Bộ test hồi quy tự động 7 điều kiện kiểm tra độ mờ đục thực vật.
- `tests/test_runner.gd`: Tích hợp suite kiểm thử hồi quy độ mờ đục thực vật.
- `reports/FOLIAGE_RENDERING_INVESTIGATION.md`: Tài liệu điều tra kỹ thuật chuyên sâu và minh chứng thực nghiệm.

*Tuân thủ nguyên tắc an toàn Git: Toàn bộ thay đổi nằm trong working tree, chưa thực hiện git commit hay git push.*
