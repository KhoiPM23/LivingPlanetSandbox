# ART DIRECTION & SHOWCASE REGION SPECIFICATION
## Living Planet Sandbox — "Whispering Glade & Emerald Basin"

**Phiên bản:** 1.0 (Art Direction & Environment Reconstruction Pass)  
**Ngày phê chuẩn:** 14/10/2026  
**Định hướng thị giác:** **Painterly Naturalism / Stylized Realism (Bán Chân Thực)**  
**Hệ quy chiếu thẩm mỹ:** *The Witness*, *Firewatch*, *Valheim*, *Red Dead Redemption 2* (Wilderness Naturalism scaled for 3D Sandbox)  
**Phần cứng mục tiêu:** Intel(R) Iris(R) Xe Graphics (96 EUs) / Vulkan Forward+ / 1280×720 / 30–45 FPS  

---

### 1. NGUYÊN TẮC ART DIRECTION CÓ CHỦ ĐÍCH

#### A. Triết lý thẩm mỹ: "Bán Chân Thực Có Tính Chọn Lọc" (Stylized Realism)
Thay vì cố gắng nhồi nhét texture ảnh chụp photogrammetry độ phân giải 4K khiến khung hình sụt giảm và xung đột với mô hình đa giác, LivingPlanetSandbox theo đuổi phong cách **Painterly Naturalism**:
1. **Silhouette & Tỷ lệ giải phẫu chân thực:** Mọi cây cối, tảng đá, hoa cỏ và động vật đều có tỷ lệ sinh học chuẩn xác trong thế giới thực, không có hình khối đồ chơi hay tỷ lệ phóng đại vô lý.
2. **Bề mặt vật liệu giàu chất cảm (Tactile PBR):** Mặt đất thể hiện rõ sự gồ ghề của đá dăm, rêu ẩm, mùn lá thông và cát ướt thông qua Normal/Roughness PBR; vỏ thân cây có vân rãnh tự nhiên; tán lá có độ bóng specular và đung đưa nhịp nhàng theo vector gió.
3. **Bảng màu hài hòa (Muted Alpine Palette):** Loại bỏ hoàn toàn các màu cơ bản rực rỡ giả tạo (xanh lá búp chuối, nâu cam hoạt hình). Sử dụng dải màu tự nhiên của vùng rừng ôn đới Bắc bán cầu: xanh thông trầm, rêu sẫm, lục mạ non, đá phiến xám tro và nước hồ ngọc bích.
4. **Ánh sáng & Phân lớp chiều sâu (Atmospheric Depth):** Tạo chiều sâu không gian thông qua bóng đổ tiếp xúc (SSAO), độ tương phản ánh sáng xiên (Golden Hour), và sương mù viễn vọng xanh lam nhạt thay vì phủ lớp sương trắng đục.

#### B. Bảng màu chuẩn hóa (Palette Tokens)

| Thành phần | Token Hex | Mô tả chất cảm thị giác |
| :--- | :--- | :--- |
| **Boreal Conifer Needles** | `#1b3a24` | Lục thông sẫm, độ nhám 0.80, cản sáng tuyệt đối |
| **Deciduous Oak Foliage** | `#325e28` | Lục sồi mượt mà, tán lá dày, độ nhám 0.75 |
| **Meadow Grass (Top)** | `#5a7d2c` | Lục mạ non đón nắng trên đỉnh ngọn cỏ |
| **Meadow Grass (Base)** | `#244218` | Lục rêu sẫm ẩm ướt sát mặt đất |
| **Forest Loam & Bark** | `#33241b` | Nâu đất mùn rừng già, vỏ cây thông phong hóa |
| **Shoreline Sand & Silt** | `#6e634e` | Cát ẩm phù sa ven hồ, mịn và sẫm màu |
| **Granite Bluff & Scree** | `#4d5054` | Đá hoa cương xám tro có vệt phong hóa oxit sắt |
| **Lichen & Rock Moss** | `#525e40` | Rêu đá vàng lục bám trên vách dốc |
| **Emerald Cove Water** | `#264d54` | Nước hồ băng tan xanh ngọc bích trong vắt |
| **Alpine Summit Snow** | `#e8edf5` | Tuyết trắng ánh xanh xám trên đỉnh granite |
| **Fauna: Stag Coat** | `#755234` | Lông hươu đực nâu sẫm, đốm cổ kem, sừng ngà |
| **Fauna: Wolf Fur** | `#2e3136` | Lông sói xám tro pha đen, mắt hổ phách phát sáng nhẹ |

---

### 2. BỐ CỤC KHU VỰC SHOWCASE: "WHISPERING GLADE & EMERALD BASIN"

Khu vực trọng tâm (Showcase Region) được quy hoạch liền mạch trong phạm vi **65m × 65m** (tọa độ $X: -10.0 \to +35.0, Z: -8.0 \to +30.0$), bao gồm 5 tiểu vùng tự nhiên tiếp nối hài hòa:

```
                          [TÂY BẮC: ĐỈNH NÚI TUYẾT & MONOLITH]
                                         ^
                                         |
     [TIỂU VÙNG 1: BÌA RỪNG THÔNG] -----> [TIỂU VÙNG 2: TRẢNG CỎ QUANG ĐÃNG]
     (Canopy Pines, Lối mòn hươu đi)       (Đàn hươu gặm cỏ, hoa dại, view thoáng)
                                                        |
                                                        v
     [TIỂU VÙNG 5: HẬU CẢNH RỪNG XA] <--- [TIỂU VÙNG 3: VỊNH NGỌC & NGÃ BA SUỐI]
                                           (Emerald Basin, suối Valley Creek, hoa súng)
                                                        |
                                                        v
                                          [TIỂU VÙNG 4: VÁCH ĐÁ & BÃI ĐÁ ĐỔ]
                                          (Rocky Bluff 10m, Talus scree boulders)
```

#### Chi tiết 5 Tiểu vùng:
1. **Tiểu vùng 1 — Bìa Rừng & Lối Mòn Hươu Đi (Forest Edge & Whispering Trail):**
   - Vị trí: Tây Bắc khu vực showcase ($X: -6.0 \to +4.0, Z: -4.0 \to +6.0$).
   - Bố cục: Rặng thông cổ thụ mọc thành cụm tự nhiên (canopy cluster 5–7 cây) che bóng xuống nền đất. Dưới tán cây có thân gỗ mục nằm ngang (`log_large`), khóm nấm đỏ (`mushroom_redGroup`) và bụi rậm tầng trung (`Bush_1_E_Color1`).
   - Lối mòn tự nhiên (Animal Trail): Một vệt mòn uốn lượn hình chữ S từ mép rừng dẫn vào đồng cỏ; cỏ ở đây mòn sát đất để lộ lớp đất mùn sẫm màu và sỏi nhỏ.
2. **Tiểu vùng 2 — Trảng Cỏ Quang Đãng (The Sunlit Meadow Glade):**
   - Vị trí: Trung tâm khu vực showcase ($X: 6.0 \to 18.0, Z: 2.0 \to 12.0$).
   - Bố cục: Đồng cỏ bằng phẳng thoai thoải ($Y \approx 3.2m - 4.5m$). Tuyệt đối **không đặt cây lớn ở giữa** để tạo hành lang quan sát xuyên suốt (sight corridor).
   - Thảm thực vật: Cỏ 3D đa phiến lá uốn lượn theo gió, điểm xuyết hoa chuông tím (`flower_purpleA`), cúc vàng (`flower_yellowA`) và tảng đá hoa cương PBR cắm vững vào lòng đất. Đây là nơi đàn hươu thường xuyên dừng lại ăn cỏ.
3. **Tiểu vùng 3 — Vịnh Ngọc & Ngã Ba Suối (Emerald Basin & Creek Delta):**
   - Vị trí: Vịnh hồ phía Đông Nam ($X: 14.0 \to 24.0, Z: 10.0 \to 22.0$).
   - Bố cục: Vịnh nước hình bầu dục tự nhiên ($Y = 0.0m$). Dòng suối núi **Valley Creek** uốn lượn từ sườn đồi phía Tây đổ xuống qua một rãnh đá thoai thoải.
   - Chi tiết ven bờ: Mép nước chuyển tiếp từ cỏ sang bãi sỏi ẩm (`rock_smallC`) và cát phù sa mịn ($Y < 1.4m$). Bụi sậy lau (`plant_flatTall`) mọc sát mép nước; hoa súng nở (`lily_large`) trôi bập bềnh trên sóng nước lăn tăn.
4. **Tiểu vùng 4 — Vách Đá Hoa Cương & Bãi Đá Đổ (The Granite Bluff & Scree Talus):**
   - Vị trí: Bờ Đông vịnh hồ ($X: 22.0 \to 30.0, Z: 12.0 \to 22.0$).
   - Bố cục: Vách đá dựng đứng cao 10m nhô ra bờ hồ, tạo điểm nhấn địa hình mạnh mẽ. Mặt vách thể hiện triplanar normal map granite nứt nẻ.
   - Chân vách đá (Talus Apron): Bãi đá đổ tự nhiên gồm các tảng đá tảng lớn nhỏ (`RockA`, `RockB`, `RockC`) rơi rải rác từ vách núi và chìm sâu vào nền đất sỏi dốc $25^\circ$.
   - Đỉnh vách: Các cây khô phong hóa (`tree_tall_dead`) khẳng khiu vươn lên nền trời.
5. **Tiểu vùng 5 — Hậu Cảnh Đỉnh Tuyết & Cổ Tháp (Distant NW Summit Backdrop):**
   - Vị trí: Góc Tây Bắc xa xăm ($X: -24.0, Z: -24.0, Y: 24.0m$).
   - Bố cục: Đỉnh núi tuyết sừng sững làm điểm tựa thị giác (landmark anchor), cổ tháp Summit Monolith phát sáng ngọn hải đăng tâm linh về đêm.

---

### 3. NGUYÊN TẮC PHÂN LỚP MÔI TRƯỜNG (ENVIRONMENTAL LAYERING)

Để xóa bỏ hoàn toàn cảm giác "bộ asset rải ngẫu nhiên lên mặt phẳng", mỗi khung hình của camera phải hội tụ đủ 4 tầng lớp thị giác:

1. **Foreground Layer (Tầng Cận Cảnh — 0m đến 4m từ Camera):**
   - Nhánh cây hoặc tán sồi vươn nhẹ qua góc trên khung hình tạo khung tự nhiên (natural framing).
   - Khóm cỏ 3D chi tiết cao, hoa dại, sỏi nhỏ, khúc gỗ mục ven bờ.
   - Tạo độ sâu thị sai (parallax) khi camera di chuyển.
2. **Midground Layer (Tầng Trung Cảnh — 4m đến 22m):**
   - Trọng tâm hành động: Đàn hươu đực gạc lớn đang gặm cỏ hoặc chạy nhảy.
   - Thảm cỏ trảng quang đãng, khối đá hoa cương có rêu bám, rặng thông rìa thung lũng.
   - Mặt nước hồ lăn tăn với hoa súng và bọt sóng ven bờ.
3. **Background Layer (Tầng Hậu Cảnh — 22m đến 80m+):**
   - Sườn đồi nghiêng rợp bóng thông, vách đá dựng đứng nhô cao.
   - Đỉnh núi tuyết NW và tháp cổ Monolith in bóng trên nền trời.
   - Sương mù khí quyển nhẹ làm dịu tương phản ở xa, tạo cảm giác không gian hùng vĩ.
4. **Ground Layer (Tầng Nền Địa Mạo):**
   - Chuyển tiếp vật liệu địa hình theo độ dốc và độ ẩm:
     - Dốc $< 15^\circ$: Thảm cỏ xanh mượt kết hợp đất mùn rễ cây.
     - Dốc $15^\circ - 30^\circ$: Đất đá dăm talus, rải rác sỏi vụn.
     - Dốc $> 30^\circ$: Vách đá granite dựng đứng với triplanar normal mapping.
     - Vùng nước ẩm $Y < 1.4m$: Cát phù sa ẩm sẫm màu và sỏi nhẵn.

---

### 4. PIPELINE VẬT LIỆU & ÁNH SÁNG PBR TRÊN INTEL IRIS XE

1. **Vật liệu Địa hình (`terrain_pbr.gdshader`):**
   - Texture PBR CC0 của ambientCG: `ground037` (đất mùn, rễ cây) và `rock023` (vách đá hoa cương).
   - Macro-variation detiling: Áp dụng nhiễu tần số thấp để triệt tiêu hiện tượng texture bị lặp ô bàn cờ ở khoảng cách xa.
   - Slope Triplanar Blending: Tự động chuyển tiếp mượt mà từ đất bằng sang vách đá đứng mà không có đường cắt sắc cạnh.
2. **Vật liệu Thực vật (`foliage_wind.gdshader`):**
   - Two-Sided Rendering với `render_mode cull_disabled, depth_draw_opaque;`.
   - Đảo chiều pháp tuyến mặt sau `NORMAL = FRONT_FACING ? NORMAL : -NORMAL;` để đáy tán lá luôn nhận ánh sáng vật lý chính xác.
   - Khóa `backlight_strength = 0.0` cho cây gỗ lớn để loại bỏ hoàn toàn lỗi xuyên sáng màng nilon.
   - Bật `backlight_strength = 0.05` cho cỏ mỏng MultiMesh để ngọn cỏ phát sáng nhẹ tự nhiên dưới ánh nắng rọi xiên.
3. **Ánh sáng & Khí quyển (`Environment` & `DirectionalLight3D`):**
   - `ambient_light_energy = 0.25`, `ambient_light_sky_contribution = 0.40` để giữ bóng râm dưới tán cây sâu và tương phản.
   - Bật Screen-Space Ambient Occlusion (SSAO): bán kính 1.2m, cường độ 1.6 để tạo bóng tiếp xúc chân thực giữa chân đá, gốc cây và mặt đất.
   - ACES Tonemapping với exposure 1.08 tạo dải động rộng tự nhiên như máy ảnh điện ảnh.

---

### 5. DANH MỤC ASSET VÀ NGUYÊN TẮC TUYỂN CHỌN

| Asset | Nguồn & Tác giả | Giấy phép | Vai trò trong Composition | Lý do lựa chọn |
| :--- | :--- | :--- | :--- | :--- |
| **Conifer Trees (`Tree_4_A/C`)** | KayKit Forest Pack (Kay Lousberg) | CC0 1.0 Universal | Rừng thông sườn dốc & bìa rừng | Silhouette cây thông hùng vĩ, thân gỗ cong tự nhiên có vân rãnh, tán lá xếp lớp chân thực |
| **Broadleaf Oaks (`Tree_1_A/C`)** | KayKit Forest Pack (Kay Lousberg) | CC0 1.0 Universal | Cây sồi bóng mát ven suối & thung lũng | Thân gỗ nâu ấm áp uốn lượn, tán tròn rậm rạp che bóng tạo khung cận cảnh |
| **Alpine Snow Pines** | Kenney Nature Kit (Kenney) | CC0 1.0 Universal | Rặng thông đỉnh núi phủ tuyết | Đỉnh ngọn phủ tuyết tự nhiên bằng vertex color, làm điểm nhấn cho sống núi cao |
| **Weathered Snags (`tree_tall_dead`)** | Kenney Nature Kit (Kenney) | CC0 1.0 Universal | Cây khô trên vách đá hoa cương | Đường nét khẳng khiu, tăng tính hoang sơ cho sườn đá dốc |
| **Granite Boulders (`RockA/B/C`)** | Kenney / Open Asset PBR | CC0 1.0 Universal | Bãi đá đổ Talus & đá cuội lòng hồ | Mô hình đá 3D đa diện có vân nứt địa chất, cắm sâu vào nền đất chống cảm giác nổi |
| **Stag, Deer, Wolf** | Quaternius Nature Pack | CC0 1.0 Universal | Sinh vật sinh thái gặm cỏ & săn mồi | Rig xương giải phẫu hoàn chỉnh, tỷ lệ cân đối, hoạt ảnh ăn cỏ/bước đi nhịp nhàng |
| **Ground & Rock Textures** | ambientCG (Lennart Demes) | CC0 1.0 Universal | Bề mặt PBR đất rừng & vách đá | Độ phân giải 2K PBR chuẩn (Albedo, Normal, Roughness, AO) mang lại chi tiết cự ly gần |

---

### 6. NGHIỆM THU THỊ GIÁC & TIÊU CHUẨN HOÀN TẤT
1. Toàn bộ 5 tiểu vùng nối tiếp nhau mượt mà, không có ranh giới đột ngột hay khoảng trống vô nghĩa.
2. Góc nhìn Walker từ mặt đất có đầy đủ tiền cảnh (lá cỏ, tảng đá), trung cảnh (hươu gặm cỏ, mặt hồ), và hậu cảnh (vách đá, đỉnh núi).
3. Không có hiện tượng cây cối rải đều như bàn cờ; cây mọc theo cụm gia đình, có lối mòn và trảng cỏ quang đãng.
4. Hiệu năng duy trì ổn định $\ge 30$ FPS trên GPU Intel Iris Xe.
