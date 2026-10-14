# VISUAL AUDIT REPORT — LIVING PLANET SANDBOX
## Phase A: Phân tích toàn diện nguyên nhân đồ họa và lộ trình nâng cấp thị giác

**Ngày thực hiện:** 14/10/2026  
**Mục tiêu phần cứng:** Intel Iris Xe Graphics (96 EUs) / Vulkan Forward+ / 1280x720  
**Tài liệu tham chiếu định hướng:** Red Dead Redemption 2, Grand Theft Auto V, Eco / Living Nature Sandboxes  

---

### 1. TỔNG QUAN HIỆN TRẠNG (EXECUTIVE SUMMARY)

Báo cáo trước đó xác nhận hệ thống mô phỏng, logic sinh thái, di truyền, thời tiết và camera đều đã hoạt động về mặt kỹ thuật. Tuy nhiên, về mặt thị giác, dự án vẫn mang tính chất **prototype kỹ thuật hình khối thô sơ (whitebox/greybox primitive prototype)** vì các nguyên nhân cấu trúc sau:

1. **Địa hình không có Texture (Zero Texture Terrain):** Mặt đất 160m chỉ sử dụng màu đỉnh nội suy phẳng (`vertex_color_use_as_albedo = true`) trên lưới 128x128. Khi nhìn gần ở góc First-Person Walker (1.65m), mặt đất hoàn toàn là các mảng màu mờ đơn sắc, không có chi tiết đất, cỏ, sỏi đá, rãnh xói mòn hay Normal/Roughness maps.
2. **Thực vật mang tính chất hình học tối giản:**
   - Cây (`TreePine`): 1 hình trụ 6 cạnh làm thân và 3 hình nón 7 cạnh xếp chồng (`CylinderMesh`), màu xanh phẳng. Không có cành nhánh, không có tán lá xum xuê, không có cây lá rộng, không có cây bạch dương, không có cây con hay bụi rậm nhiều tầng.
   - Bụi cây: `SphereMesh` (hình cầu xanh tròn xoe).
   - Cỏ: Chỉ có 800 cá thể `PrismMesh` (tam giác phẳng đơn lẻ) rải ngẫu nhiên trên toàn đảo 160m (trung bình 1 tam giác cách nhau vài mét), khiến hòn đảo trông trơ trọi 95% đất trống.
3. **Động vật là các khối hộp ghép nối không có chân (Cardboard Box Animals):**
   - Hươu (`island_deer`): Ghép từ 2 khối hộp `BoxMesh` (thân, đầu) và 2 hình trụ `CylinderMesh` (sừng). Không có chân, không có khớp, không có tai, mắt, đuôi.
   - Thú săn (`mountain_stalker`): Ghép từ 1 khối hộp `BoxMesh`, 1 lăng kính `PrismMesh` và 2 quả cầu phát sáng.
   - Hoạt ảnh: Chỉ dịch chuyển vị trí và nảy tưng tưng theo hàm sin (`hop = absf(sin(_anim_time * 8.0))`), trượt trên mặt đất như khối hộp Minecraft không chân.
4. **Chiếu sáng & Khí quyển thiếu chiều sâu (Flat Ambient & Washed Out Fog):**
   - Ánh sáng môi trường phẳng (`ambient_light_energy = 0.6`, màu xanh nhạt) làm triệt tiêu độ tương phản bóng đổ.
   - Sương mù khoảng cách (`fog_depth_begin = 35.0, fog_depth_end = 140.0`) tạo cảm giác phủ một lớp sữa đục mờ chứ không tạo được chiều sâu phân lớp khí quyển như hẻm núi RDR2 hay đường bờ biển GTA V.
   - Bầu trời là `ProceduralSkyMaterial` mặc định 3 dải màu cơ bản.
5. **Tài nguyên PBR chất lượng cao bị bỏ quên:**
   - Thư mục `demo/assets/textures/` đã có sẵn bộ texture PBR CC0 chất lượng cao của AmbientCG (`ground037_alb_ht.png`, `ground037_nrm_rgh.png`, `rock023_alb_ht.png`, `rock023_nrm_rgh.png`) nhưng chưa hề được đưa vào shader địa hình chính.
   - Thư mục `demo/assets/models/` có các model đá 3D thật kèm LOD (`RockA.glb`, `RockB.glb`, `RockC.glb`), nhưng `rock_boulder.gd` lại tự sinh một hình cầu 6 cạnh thô.

---

### 2. CHI TIẾT AUDIT TỪNG HỆ THỐNG THỊ GIÁC

| Hệ thống | File / Resource liên quan | Hiện trạng kỹ thuật | Tác động quan sát được |
| :--- | :--- | :--- | :--- |
| **Terrain Mesh & Texturing** | `presentation/environment/island_terrain.gd` | Sử dụng `SurfaceTool` gán màu đỉnh (`st.set_color(col)`), vật liệu `StandardMaterial3D` với `vertex_color_use_as_albedo = true`. Không có texture, không có normal map, không có triplanar mapping. | Mặt đất nhìn như tranh vẽ mẫu giáo; ở cự ly gần hoàn toàn mờ tịt, không có cảm giác chất liệu đất cát, rêu phong hay vách đá dựng đứng. |
| **Vegetation Architecture** | `presentation/props/tree_pine.gd`, `presentation/environment/vegetation_scatter.gd` | Cây chỉ gồm các cylinder/cone thô ghép lại; chỉ có duy nhất 1 loài thông; không có cây lá rộng (oak/birch), không có dương xỉ, không có hoa dại, không có khúc gỗ đổ. Cỏ chỉ 800 tam giác đơn lẻ. | Rừng trông như các que cọc cắm rải rác; thiếu thảm thực vật nhiều tầng (canopy layer, understory layer, ground cover); hòn đảo trống trải và đơn điệu. |
| **Fauna Mesh & Rigs** | `presentation/ecosystem/ecosystem_presentation.gd` | Sinh vật được dựng bằng `BoxMesh` và `CylinderMesh`. Không có rig xương, không có chi, không có da lông. | Động vật trông như các khối hộp đồ chơi trượt trên cỏ; phá vỡ hoàn toàn cảm giác một hệ sinh thái sống động. |
| **Fauna Animation & Locomotion** | `presentation/ecosystem/ecosystem_presentation.gd` | Hoạt ảnh hoàn toàn là hàm toán học dịch chuyển `target_pos.y += hop` và xoay đầu thô sơ. | Chuyển động lặp máy móc, trượt chân vô lý, không có tư thế cúi đầu gặm cỏ tự nhiên chạm sát mặt cỏ. |
| **Lighting & Sky Atmosphere** | `scenes/main.tscn`, `presentation/environment/day_night_cycle.gd` | Sky procedural cơ bản 3 màu; ambient light quá sáng triệt tiêu bóng tối dưới tán cây; tone mapping Reinhard/Filmic chưa tinh chỉnh độ tương phản. | Toàn cảnh bị cháy sáng hoặc nhờ nhờ đục; không có ánh sáng xuyên tán lá (god rays), bóng đổ thiếu chiều sâu. |
| **Water & Shoreline Transition** | `presentation/shaders/water.gdshader`, `presentation/environment/water_plane.gd` | Nước có sóng Gerstner và bọt mép nước, nhưng mép bờ biển không có bãi sỏi, không có đá cuội, không có rong rêu hay sự chuyển tiếp độ ẩm tự nhiên của cát ẩm. | Ranh giới giữa đất và nước phẳng lì, thiếu sức sống sinh thái ven bờ. |
| **Graphics Presets vs Visuals** | `presentation/graphics/graphics_presets.gd` | Preset chủ yếu tắt bóng hoặc hạ độ phân giải (75%/85%/100%), không thay đổi chất lượng LOD mesh hay độ phong phú của cảnh quan. | Chuyển preset chỉ làm mờ ảnh hoặc tắt bóng chứ không cải thiện bản chất nghệ thuật. |

---

### 3. MA TRẬN ƯU TIÊN CAN THIỆP (PRIORITY MATRIX)

#### P0 — Bắt buộc phải thay thế ngay (Phá vỡ hình ảnh prototype)
1. **P0.1: Terrain Triplanar PBR Shader:** Chuyển đổi `IslandTerrain` sang shader kết hợp PBR đa vật liệu (Cỏ mượt/Đất ẩm phẳng, Vách đá dựng đứng với triplanar normal mapping, Bãi cát ven biển có độ nhám tự nhiên). Tận dụng ngay bộ texture CC0 của AmbientCG đã có sẵn.
2. **P0.2: Thay thế Model Cây & Thảm thực vật:** Loại bỏ cây hình nón xếp chồng. Tích hợp các model 3D cây thông thật, cây lá rộng/bạch dương, bụi rậm nhiều nhánh, hoa dại và cụm cỏ tự nhiên (grass tufts) thay vì tam giác đơn lẻ.
3. **P0.3: Thay thế Model Động vật & Chân thực hóa Locomotion:** Thay thế khối hộp của Hươu và Thú săn bằng các model sinh vật 3D có tỷ lệ giải phẫu chân thực, có chân, đầu, tai, thân mình rõ rệt; nâng cấp chuyển động đi/chạy/gặm cỏ có sự gập khớp và hạ thấp đầu chạm mặt cỏ.

#### P1 — Nâng cấp độ tự nhiên và chiều sâu khám phá
1. **P1.1: Multi-tier Foliage Layering (Rừng nhiều tầng):** Bố trí thực vật theo cụm sinh thái: cây cổ thụ cao vút che bóng, bên dưới là bụi rậm tầng trung, dương xỉ và thảm cỏ dày tầng trệt; tạo lối mòn và trảng cỏ quang đãng.
2. **P1.2: Bờ nước & Chi tiết ven sông/hồ:** Tích hợp đá cuội ven bờ (`RockA`, `RockB`, `RockC`), lau sậy, gỗ mục rải rác tạo điểm nhấn tự nhiên.
3. **P1.3: Cân chỉnh Ánh sáng, Bầu trời & Chiều sâu Khí quyển:** Điều chỉnh `WorldEnvironment`, giảm ambient wash, tăng độ tương phản bóng đổ đổ dài lúc bình minh/hoàng hôn, tinh chỉnh volumetric fog nhẹ để tạo lớp mờ xa xa (distance depth) như RDR2/GTA V.

#### P2 — Tinh chỉnh và hoàn thiện cảm giác thế giới
1. **P2.1: Phân hóa Biome rõ nét:** Khu vực đỉnh núi đá tuyết có mỏm đá nhọn sắc nét; thung lũng ẩm ướt có dương xỉ rậm rạp; trảng cỏ khô có bụi cây gai và đất nứt nẻ.
2. **P2.2: Tối ưu hóa hiệu năng Intel Iris Xe:** Đảm bảo tất cả cỏ và cây bụi dùng `MultiMeshInstance3D` chia cụm (chunked), LOD khoảng cách hiển thị và shadow cutoff hợp lý để duy trì >35 FPS.

---

### 4. KẾ HOẠCH HÀNH ĐỘNG TIẾP THEO
Tiếp tục bước sang **PHASE B** để kiểm kê, tải và chuẩn bị các asset 3D thực vật/sinh vật mã nguồn mở CC0/MIT hợp lệ, sau đó triển khai trực tiếp vào Vertical Slice mẫu ở **PHASE C**.
