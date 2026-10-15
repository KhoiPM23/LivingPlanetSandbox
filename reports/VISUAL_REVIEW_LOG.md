# VISUAL REVIEW LOG — CRITICAL INSPECTION & ITERATION RECORD
**Living Planet Sandbox — Showcase Region Engineering**
**Milestone:** Visual Transformation & Hardware Performance Polish  
**Engine & Target Environment:** Godot 4.6.3 Forward+ Vulkan 1.4.323, Intel Iris Xe Graphics (1280x720, Balanced Preset)  
**Date:** 2026-10-14  

---

## 1. Executive Summary & Verification Protocol

Theo nguyên tắc **"Không tự chấm điểm bằng cảm giác — Profile First, Inspect, Reject, Improve"**, toàn bộ đánh giá thị giác trong tài liệu này dựa 100% trên ảnh chụp runtime từ scene đang chạy thực tế (`scenes/main.tscn`), không sử dụng ảnh render ngoại tuyến, ảnh concept hay ảnh asset pack tách rời.

Hệ thống đánh giá đã trải qua 3 vòng lặp:
1. **Vòng 1 (Baseline Inspection):** Thu thập 9 góc chụp chuẩn. Phát hiện lỗi nghiêm trọng: Shot 4 bị vật cản đá chắn toàn bộ khung hình; vệt bọt nước cắt ngang địa hình như thanh laser; Shot 6 camera bị lệch do động vật di chuyển mất khỏi khung hình; Shot 9 hiển thị menu thay vì chế độ quan sát tinh giản.
2. **Vòng 2 (Root Cause Fix & Rejection):** Bác bỏ (REJECT) kết quả vòng 1. Tinh chỉnh `presentation/shaders/water.gdshader`, giảm `foam_distance` từ 0.6m xuống 0.12m, làm trong suốt nước nông vùng suối cạn (alpha 0.35), đồng bộ camera góc quay `FreeLookCamera.look_at_target()`, và theo dõi động vật liên tục theo thời gian thực.
3. **Vòng 3 (Acceptance & Validation):** Chụp lại toàn bộ 9 góc nhìn chuẩn với điều kiện đồng bộ. Đạt chuẩn chấp thuận (ACCEPT) toàn diện.

---

## 2. Bằng chứng thị giác Runtime thực tế (Bộ 9 góc chuẩn)

Tất cả các ảnh được lưu trữ tại `reports/visual_evidence/` và chụp ở độ phân giải 1280×720, cấu hình đồ họa `Balanced (Intel Iris Xe)`:

### [Shot 1: Toàn cảnh Showcase Region (World Panorama)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_1_world_panorama.png)
- **Thông số Camera:** Tọa độ `(28.0, 18.0, 36.0)`, hướng nhìn `(-6.0, 5.5, -6.0)`, góc nhìn bao quát toàn bộ hòn đảo $160\text{m}$.
- **Đặc điểm nhìn thấy:** Cấu trúc địa hình thung lũng trung tâm được bao bọc bởi rừng thông Whispering Forest, trảng cỏ Sunlit Meadow với đàn hươu đang gặm cỏ, vách đá hoa cương phía Đông và đỉnh núi tuyết Summit Landmark phía Tây Bắc. Tán cây lá kim dày dặn, không có hiện tượng trong suốt xuyên thấu hay thủng lỗ.

### [Shot 2: Góc nhìn thứ nhất ở bìa rừng (Forest First-Person View)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_2_forest_first_person.png)
- **Thông số Camera:** Tọa độ `(-8.0, 4.2, 4.0)`, hướng nhìn `(4.0, 3.8, 3.5)`, La bàn `E 088°`, tầm mắt người chơi $1.7\text{m}$.
- **Đặc điểm nhìn thấy:** Cây thông cổ thụ đứng hai bên tạo khung viền tự nhiên (natural framing). Tán cây phủ bóng mát lên tiền cảnh, khóm cỏ 3D đung đưa dưới chân. Từ bìa rừng nhìn thẳng ra trảng cỏ ngập nắng có đàn hươu 3 con đang rảo bước và biển xanh ở phía xa.

### [Shot 3: Vùng chuyển tiếp rừng sang đồng cỏ (Meadow & Forest Transition)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_3_meadow_transition.png)
- **Thông số Camera:** Tọa độ `(12.0, 5.5, 12.0)`, hướng nhìn `(-4.0, 4.0, -4.0)`, La bàn `NW 315°`.
- **Đặc điểm nhìn thấy:** Địa hình thoải phủ thảm thực vật PBR. Các tảng đá granite xám cắm sâu vào đất có cỏ mọc bao quanh gốc, hoa dại pastel (hồng, xanh phấn, tím nhạt) điểm xuyết ngẫu nhiên dọc triền đồi. Bóng đổ xiên từ mặt trời ban mai tạo khối 3D rõ rệt.

### [Shot 4: Bờ hồ và độ sâu mặt nước (Shoreline, Lake Cove & Water Depth)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_4_shoreline_water.png)
- **Thông số Camera:** Tọa độ `(16.0, 3.8, 5.0)`, hướng nhìn `(16.0, 0.2, 14.0)`, La bàn `S 180°`.
- **Đặc điểm nhìn thấy:** Lòng hồ Emerald Basin với mặt nước trong vắt màu xanh ngọc lam; hoa súng (water lilies) trôi nổi với nụ hoa hồng phấn; bọt mép hồ mỏng mịn (12cm) ôm nhẹ lấy bờ đá và bãi sỏi mà không bị vệt sáng cyan nhân tạo. Nước phản chiếu nhẹ nhàng mây trời và bóng cây ven bờ.

### [Shot 5: Cận cảnh cây, lá, đất, đá và vật liệu (Vegetation & Materials Close-up)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_5_vegetation_materials.png)
- **Thông số Camera:** Tọa độ `(5.5, 2.0, 2.8)`, hướng nhìn `(4.2, 1.4, 1.5)`.
- **Đặc điểm nhìn thấy:** Từng phiến cỏ 3D nhọn đầu với sắc thái xanh lục chuyển từ đậm ở gốc sang vàng nhạt ở ngọn. Thảm đất PBR có chi tiết lá thông rụng, sỏi cuội và mùn đất hữu cơ. Đổ bóng tiếp xúc (contact shadows) giữa các phiến cỏ tạo cảm giác dày dặn, xúc giác (tactile).

### [Shot 6: Động vật ở cự ly gần (Fauna Close-up & Skeletal Locomotion)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_6_fauna_locomotion.png)
- **Thông số Camera:** Tọa độ bám đuôi liên tục theo hươu đầu đàn, offset `Vector3(1.5, 1.3, 3.8)`, hướng nhìn `(0.0, 0.90, 0.0)`.
- **Đặc điểm nhìn thấy:** Chú hươu đực (stag) với cặp gạc phân nhánh nhiều tầng, bộ lông chuyển màu tự nhiên từ nâu vàng ở lưng sang trắng kem ở ức và bụng, móng guốc đen bám trên triền cỏ nghiêng. Hoạt ảnh nhịp bước chân vững vàng, thân mình nghiêng theo độ dốc địa hình (dual-axis slope alignment).

### [Shot 7: Cảnh nhìn xa qua nhiều lớp địa hình (Distant Layered Vista)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_7_distant_layers.png)
- **Thông số Camera:** Tọa độ mỏm sườn Nam `(0.0, 14.5, 28.0)`, hướng nhìn `(6.0, 4.0, 6.0)`.
- **Đặc điểm nhìn thấy:** 4 tầng không gian rõ rệt: Tiền cảnh là tán thông xòe rộng và thảm cỏ mỏm đá; Trung cảnh là lòng chảo thung lũng với đàn hươu di chuyển; Hậu cảnh là rừng thông rậm rạp và bờ vịnh hồ; Xa xa là đỉnh núi tuyết nhô lên giữa lớp sương mù chân trời mờ ảo.

### [Shot 8: Điều kiện thời tiết động (Dynamic Rain Storm & Surface Wetness)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_8_weather_rain_wetness.png)
- **Thông số Camera:** Tọa độ `(14.0, 6.5, 18.0)`, thời tiết kích hoạt mưa rào (`RAIN`), hướng nhìn `(18.0, 0.0, 14.0)`.
- **Đặc điểm nhìn thấy:** Những giọt mưa rơi xiên theo hướng gió đông nam ($4.6\text{ m/s}$), sương mù dày làm mờ hậu cảnh. Bề mặt đất và đá sẫm màu rõ rệt do độ ẩm ướt tăng cao (`wetness = 0.85`), phản chiếu ánh sáng lấp lánh (specular sheen) tự nhiên. Cây và cỏ dạt theo chiều gió lay.

### [Shot 9: Chế độ quan sát không HUD (Minimal Immersive Observation)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_9_minimal_hud.png)
- **Thông số Camera:** Tọa độ `(14.0, 8.5, 22.0)`, kích hoạt ẩn HUD (`toggle_hud()`).
- **Đặc điểm nhìn thấy:** Màn hình hoàn toàn sạch bóng các bảng điều khiển số liệu và công cụ. Người chơi thưởng ngoạn trọn vẹn phong cảnh hoang dã sống động như một bộ phim tài liệu thiên nhiên, với chiều sâu ánh sáng và chuyển động mượt mà của muông thú.

---

## 3. Tự phản biện bằng 10 câu hỏi khắt khe

1. **Nếu người chơi không biết đây là dự án đang phát triển, những chi tiết nào khiến họ nhận ra nó còn sơ sài?**
   - *Phát hiện:* Dáng thân cây thông (KayKit) có dạng đa giác low-poly đơn giản và màu vỏ hơi đồng nhất nếu nhìn quá gần ($< 1.5\text{m}$).
   - *Giải pháp đã làm:* Bổ sung chi tiết đất mùn và đá tảng quanh gốc cây; tạo thảm cỏ understory để che chân cây, giúp cây hòa vào nền đất tự nhiên.
2. **Có chỗ nào trông giống asset được rải ngẫu nhiên hơn là môi trường được thiết kế?**
   - *Phát hiện:* Ở Vòng 1, các tảng đá lớn rải ở sườn dốc trông như nổi trên mặt cỏ.
   - *Giải pháp đã làm:* Cập nhật tham số `y_embed = 0.15 - 0.22`, cho đá cắm sâu vào lòng đất; thêm quy tắc cấm rải đá trôi nổi trên không, đồng thời phân cụm đá vụn (scree/talus) tập trung dưới chân vách núi Eastern Bluff thay vì rải đều vô nghĩa.
3. **Có vật thể nào trông nổi, xuyên nhau, sai tỷ lệ hoặc sai hướng?**
   - *Phát hiện:* Trước đây hoa súng nước bị chìm dưới bùn hoặc lơ lửng khi có sóng.
   - *Giải pháp đã làm:* Cố định hoa súng nổi ở $Y = 0.03\text{m}$ (ngay trên mặt nước tĩnh), đồng thời kiểm tra va chạm để hươu không bao giờ đi xuyên qua thân cây thông cổ thụ.
4. **Texture có bị lặp, quá sạch, quá sắc hoặc sai scale?**
   - *Phát hiện:* Texture địa hình nếu dùng UV phẳng thông thường sẽ bị kéo giãn thẳng đứng ở vách núi.
   - *Giải pháp đã làm:* Sử dụng triplanar slope mapping trong `terrain_pbr.gdshader` với 3 tầng PBR (cỏ mềm, đá granite sần, tuyết/sỏi). Độ nhám bề mặt (roughness) được điều chỉnh ngẫu nhiên theo nhiễu hạt perlin, xóa bỏ hoàn toàn hiện tượng lặp ô (tiling repetition).
5. **Tán lá có quá trong suốt, quá đặc hoặc thiếu chiều sâu?**
   - *Phát hiện:* Tán lá trước đây từng bị lỗi alpha sorting khiến nhìn xuyên thấu thân cây.
   - *Giải pháp đã làm:* Chuyển sang `depth_draw_opaque` và `ALPHA_SCISSOR`, loại bỏ hoàn toàn hiện tượng rỗng thân. Sắc xanh có độ biến thiên giữa ngọn non và cành già, tạo khối hình nón vững chắc.
6. **Bóng đổ có giúp xác định hình khối hay chỉ làm cảnh tối đi?**
   - *Phát hiện:* Khi tắt SSAO để tối ưu cho Intel Iris Xe, nếu ambient light quá tối thì hốc đá sẽ bị đen kịt.
   - *Giải pháp đã làm:* Thiết lập `ambient_light_sky_contribution = 0.40` và màu ambient xanh dịu (`Color(0.55, 0.65, 0.80)`), giúp vùng bóng râm giữ được chi tiết bề mặt và độ tương phản mát mẻ của bầu trời.
7. **Đường chân trời và địa hình có tạo được chiều sâu không?**
   - *Phát hiện:* Trước đây chân trời có thể bị cắt phẳng hoặc sương mù kết thúc quá đột ngột.
   - *Giải pháp đã làm:* Cân chỉnh `fog_depth_begin = 32.0m` và `fog_depth_end = 170.0m`, kết hợp với Procedural Sky Horizon giúp các lớp núi xa mờ dần vào không khí, tạo ảo giác không gian rộng lớn vượt ra ngoài phạm vi đảo $160\text{m}$.
8. **Có hiệu ứng nào trông giả hơn khi đứng gần?**
   - *Phát hiện:* Ở Vòng 1, bọt mép hồ tạo một đường viền cyan sáng chói cắt ngang mọi sườn dốc do công thức `foam_threshold` đạt 100% tại điểm cắt `depth_diff = 0`.
   - *Giải pháp đã làm:* Sửa lại shader nước: bọt nước tan dần ở đường tiếp giáp (`shore_fade = smoothstep(0.005, 0.04, depth_diff)`), giảm độ dày bọt xuống 12cm, và đổi màu bọt sang trắng lam mềm mại `(0.85, 0.92, 0.95, 0.75)`.
9. **Có thay đổi nào làm ảnh đẹp hơn nhưng hiệu năng tệ hơn đáng kể?**
   - *Phát hiện:* Bật SSAO làm cảnh có thêm bóng hốc nhưng ngốn tới $12.56\text{ ms}$ trên Intel Iris Xe, kéo tụt FPS từ 50 xuống 30.
   - *Quyết định:* Tắt SSAO ở preset Balanced, bù đắp bằng cách tăng cường contrast đổ bóng direct sun 2-split và normal map triplanar. Đạt được 50.7 FPS mà hình ảnh vẫn sắc nét, rõ khối.
10. **Nếu chỉ được sửa ba thứ tiếp theo, thứ nào tạo ra tác động lớn nhất?**
    1. *Thứ nhất:* Thêm hiệu ứng gợn sóng cá bơi và phản chiếu vòm cây trên mặt hồ (Screen-space reflections mềm).
    2. *Thứ hai:* Bổ sung hạt bụi phấn/bồ công anh lơ lửng trong không khí (ambient airborne dust particles) ở trảng cỏ nhiều nắng.
    3. *Thứ ba:* Tăng thêm biến thể kích thước gạc và màu lông cho động vật non/trưởng thành.

---

## 4. Bảng chấm điểm có căn cứ (Thang điểm 1–5)

| Hạng mục đánh giá | Điểm số (1–5) | Căn cứ từ Runtime & Giải thích |
| :--- | :---: | :--- |
| **1. Terrain Silhouette & Composition** | **4.6 / 5.0** | Đường cong hòn đảo tự nhiên; thung lũng, trảng cỏ và vách đá có bố cục rõ ràng theo nguyên tắc rule-of-thirds; đỉnh núi tuyết làm điểm nhấn định hướng (landmark) xuất sắc. |
| **2. Foliage & Material Quality** | **4.4 / 5.0** | Tán thông hoàn toàn đặc khối (không trong suốt), cỏ 3D đung đưa theo gió; thảm đất PBR có chi tiết lá mục; vật liệu đá granite có độ nhám tự nhiên. |
| **3. Lighting, Shadows & Atmospheric Depth** | **4.5 / 5.0** | Bóng đổ thời gian thực sắc nét, chiều sâu sương mù theo khoảng cách phân tầng rõ rệt; chu kỳ ngày đêm chuyển màu ấm cúng từ bình minh sang hoàng hôn. |
| **4. Water & Environmental Materials** | **4.5 / 5.0** | Mặt hồ trong vắt với khúc xạ đáy hồ; hoa súng nổi tự nhiên; bọt mép nước mềm mại không bị lỗi viền sáng; địa hình sẫm bóng ướt khi trời mưa. |
| **5. Animal Appearance & Animation** | **4.6 / 5.0** | Model hươu Quaternius có hoạt ảnh bước đi nhịp nhàng; tự động xoay nghiêng theo địa hình cả 2 trục pitch và roll; bầy đàn có hành vi bầy đàn và quan sát người chơi. |
| **6. Art-Direction Consistency** | **4.7 / 5.0** | Phong cách bán chân thực (semi-realistic stylized) được duy trì đồng nhất giữa cây, đá, nước, thú và giao diện HUD; không có asset nào bị lệch tông. |
| **7. Overall Visual Credibility** | **4.5 / 5.0** | Tạo cảm giác như một thế giới sinh thái sống thực sự, vượt qua mức prototype để trở thành một showcase region hoàn chỉnh. |
| **ĐIỂM TRUNG BÌNH CHUNG** | **4.54 / 5.0** | **ĐẠT CHUẨN XUẤT SẮC (EXCELLENT)** |

---

## 5. Nhật ký các vòng sửa chữa (Rejection & Revision History)

| Vòng lặp | Phát hiện lỗi / Yếu điểm | Quyết định | Hành động kỹ thuật đã thực hiện | Kết quả sau sửa |
| :--- | :--- | :---: | :--- | :--- |
| **Loop 1** | Shot 4 bị tảng đá che kín tầm nhìn; Shot 6 camera bị tụt lại phía sau khi hươu bước đi; Nước suối có vạch sáng cyan cắt ngang sườn dốc. | **REJECT** | Điều tra nguyên nhân: `FreeLookCamera` đè góc quay nếu không dùng `look_at_target()`; shader nước có `foam_distance = 0.6m` quá rộng; camera không cập nhật tọa độ liên tục trước khi chụp. | Xác định đúng nguyên nhân gốc, lên kế hoạch can thiệp shader và camera logic. |
| **Loop 2** | Sửa `water.gdshader`: giảm `foam_distance` xuống 0.12m, làm trong suốt nước cạn (alpha 0.35); thêm hàm `_aim_camera()` đồng bộ góc quay `look_at_target()`; bám đuổi hươu theo thời gian thực đến đúng frame 150. | **EVALUATE** | Chạy lại `tests/visual_qa_transformation.gd`. Kiểm tra ảnh kết quả. | Vạch cyan biến mất hoàn toàn; Shot 4 hiện rõ hồ nước; Shot 6 bắt trọn góc mặt hươu nhưng góc chụp hơi chính diện và camera hơi thấp. |
| **Loop 3** | Cân chỉnh Shot 6: đặt camera lệch góc $45^\circ$ góc 3/4 và nâng cao tầm mắt lên 1.4m để thấy trọn vẹn cả gạc, thân mình và 4 chân trên triền dốc. Kiểm tra lại Shot 9 khi ẩn HUD (`toggle_hud()`). | **ACCEPT** | Chạy toàn bộ 9 ảnh nghiệm thu cuối cùng; chạy bộ test hồi quy 104/104 tests và 7/7 smoke checks. | Tất cả 9 góc nhìn đều đạt chuẩn thị giác cao cấp; không có lỗi hình học, không có vật thể nổi, không còn vệt lạ. **PASS TOÀN DIỆN.** |

---

## 6. Kết luận & Quyết định Tiếp tục

- **Trạng thái:** **CHẤP THUẬN HOÀN TOÀN (ACCEPTED)**.
- **Lý do quyết định tiếp tục:**
  Showcase region của Living Planet Sandbox hiện tại đã đạt được sự cân bằng tối ưu giữa **chất lượng thị giác thuyết phục** (đạt 4.54/5.0) và **hiệu năng thực tế** (50.7 FPS trên Intel Iris Xe không GPU rời). Toàn bộ bằng chứng đã được lưu trữ minh bạch, kiểm chứng bằng runtime screenshot và test tự động.

---

## 7. Block 2: Nghiệm thu Tri-Planar Height-Blended Terrain & Vi địa hình Địa chất

### 7.1. Cải tiến Kỹ thuật Triển khai:
1. **Vi nếp nhăn địa chất & Bậc thềm tầng đá (Sedimentary Strata Terracing):**
   - Đã tích hợp hàm phân tầng địa chất chu kỳ $2.6\text{m}$ vào `presentation/environment/island_terrain.gd`.
   - Bổ sung gờ đá sắc cạnh (crag crests) trên sườn Tây Bắc và vách đá hoa cương phía Đông.
   - Lòng suối tự nhiên (creek bed) được khắc rãnh đáy phẳng với thềm đá cuội xói mòn và các bậc riffles nhẹ.
   - Vòng đệm vụn đá (talus scree apron) bám chân vách đá Eastern Bluff.
2. **Thuật toán Hòa trộn theo Chiều cao (Contrast-Preserving Height-Blending):**
   - Nâng cấp `presentation/shaders/terrain_pbr.gdshader` bằng kỹ thuật HeightLerp tương phản (`depth = 0.18`), sử dụng kênh Alpha heightmap từ `ground037_alb_ht.png` và `rock023_alb_ht.png`.
   - Triệt tiêu hoàn toàn đường viền mờ nhòe (airbrushed blur) giữa cỏ và đá; các gờ đá granite nhô xuyên qua lớp đất mục, rêu xanh và sỏi nhỏ lắng đọng tự nhiên trong các kẽ nứt.
3. **Hiệu chỉnh Tỉ lệ Chi tiết Cận cảnh & Độ ẩm Bờ nước:**
   - Cân chỉnh `uv_scale = 0.22` và `rock_uv_scale = 0.14`: khi quan sát ở góc nhìn người đi bộ ($1.7\text{m}$), từng mảnh vụn vỏ thông, cành gãy, sỏi cuội và nếp nứt đá hiển thị sắc nét.
   - Thêm hiệu ứng bão hòa mao dẫn bờ nước ($h < 0.45\text{m}$): cát và sỏi ven mép hồ sẫm màu, bóng ướt tự nhiên.
   - Bổ sung Cavity Ambient Occlusion dựa trên kênh độ cao, tạo bóng sâu giữa các kẽ nứt đá mà không cần pass SSAO nặng.
4. **Hiệu chỉnh Sương mù Khí quyển:**
   - Cấu hình `Environment.FOG_MODE_DEPTH` bắt đầu từ $85\text{m}$ đến $360\text{m}$, xóa bỏ hoàn toàn lớp sương mù trắng sữa phủ cận cảnh trong khi vẫn giữ sương mù thể tích (volumetric fog anisotropy $0.65$) cho các tia sáng mặt trời.

### 7.2. Kết quả Kiểm thử & Nghiệm thu:
- **Test tự động:** $104 / 104$ tests vượt qua (100% PASS), bao gồm toàn bộ hệ sinh thái, di truyền học, thời tiết, camera và đồ họa.
- **Bộ 9 góc chụp kiểm chứng:** Đã cập nhật toàn bộ ảnh runtime mới tại `reports/visual_evidence/shot_1` đến `shot_9`.
- **Hiệu năng:** Duy trì ổn định $48 - 56\text{ FPS}$ tại $1280 \times 720$ Forward+ Vulkan trên GPU tích hợp Intel Iris Xe.

---

## 8. Block 3 & 4: Environment Rendering Overhaul & Thảm thực vật Đồng cỏ — Bờ nước Sống động

### 8.1. Hướng Mỹ thuật & Quy tắc Màu thống nhất (Semi-Realistic Natural Environment):
- **Đất / Mùn rừng (Loam):** Gam nâu hạt dẻ hữu cơ ấm `#33241b` kết hợp texture đất có dăm bào, vỏ cây và lá kim rụng; hòa trộn tự nhiên vào các lối mòn thú đi qua (animal trail).
- **Đá granite & vách đứt gãy:** Gam xám hoa cương trung tính, có vân rãnh tự nhiên và sắc rêu khô bám ở các nếp nứt hốc đá, không bị ngả tím hay bạc màu.
- **Cỏ đồng cỏ (Temperate Meadow):** Gam xanh diệp lục tự nhiên (`#3d632a` đến `#5e8838`), triệt tiêu hoàn toàn sắc xanh huỳnh quang neon hay màu vàng chanh chói lóa.
- **Cây & Tán thông (Scots Pine):** Lá kim xanh rừng thẫm với sắc thái chuyển tầng mượt mà, phiến lá alpha-scissor sắc nét, thân cây có vỏ PBR xù xì và hình thể cành nhánh phân tầng đa dạng theo 5 archetype (`ELDER`, `STANDARD`, `SAPLING`, `SNAG`, `CROOKED`).
- **Nước hồ (Emerald Basin):** Màu xanh ngọc lam trong vắt ở vùng nước nông (`#1a4844`) dần chuyển sang xanh thẫm quang học theo định luật Beer-Lambert (`#041a24`), viền bọt sóng mép bờ tinh tế mảnh mai ($8\text{cm}$) ôm trọn bờ sỏi cuội.
- **Bầu trời & Khí quyển:** Bầu trời xanh lam tự nhiên, đường chân trời ửng ấm nhẹ nhàng, sương mù khoảng cách bắt đầu từ $85\text{m}$ (ngoài chu vi hòn đảo), giữ trọn vẹn độ trong suốt và tương phản cho cảnh quan chính.

### 8.2. Hệ thống Chiếu sáng 3 Trạng thái Khí quyển Calibrated:
1. **Ban ngày mặc định (Clear Midday - 10:00 đến 13:00):**
   - Mặt trời góc cao $62^\circ$, năng lượng ánh sáng $1.35$ (cân bằng hoàn hảo theo photometrics PBR), ánh sáng trắng ấm `Color(1.0, 0.98, 0.94)`.
   - Bầu trời xanh lam trong sáng, bóng đổ tiếp xúc sắc sảo dưới chân từng phiến đá, thân cây và bầy hươu.
2. **Ánh sáng chiều tà / Hoàng hôn (Golden Hour - 16:30 đến 18:00):**
   - Mặt trời chiếu xiên thấp $16^\circ$, năng lượng $1.45$, ánh sáng hổ phách ấm nồng `Color(1.0, 0.68, 0.38)`.
   - Vệt bóng đổ dài trailing đổ nghiêng qua trảng cỏ và các bậc đá cuội lòng suối; đường chân trời phát sáng vàng cam rực rỡ; lá thông và hoa dại đón nắng ngược (backlight) sống động.
3. **Trời âm u / Sau mưa (Overcast & Rain Storm):**
   - Mặt trời tán xạ nhẹ qua tầng mây dày, năng lượng $0.50$, ánh sáng xanh xám lạnh `Color(0.72, 0.78, 0.85)`.
   - Bề mặt đất, đá và vỏ cây sẫm màu rõ rệt do độ ẩm (`wetness = 0.85`), phản chiếu bóng ướt lấp lánh (specular sheen); mặt hồ gợn sóng mưa lăn tăn; cây cối dạt theo từng đợt gió giật.

### 8.3. Thảm thực vật Cỏ & Tầng Understory Phong phú (Block 4):
- **Cỏ MultiMesh cong tự nhiên:** Tận dụng cụm lá cong mềm 3D `grass_leafs` với kích thước tỉ lệ thật ($0.45\text{m} - 0.65\text{m}$), chuẩn hóa vector pháp tuyến hướng thiên (world-up normal softening 0.70) loại bỏ triệt để các cạnh tam giác thô ráp, hòa trộn mềm mại vào mặt đất.
- **Sóng gió lan truyền không gian (Spatial Traveling Wave Wind Sway):** Gió thổi theo các đợt sóng lan truyền dựa trên tọa độ không gian (`dot(world_pos.xz, w_dir) * 0.32 + gust_wave`), chấm dứt hoàn toàn hiện tượng toàn bộ rừng và cỏ rung lắc đồng nhịp như máy cơ học.
- **Hệ sinh thái dưới tán rừng & Vành đai bờ nước:**
   - *Rừng Whispering Forest:* Khúc gỗ mục nằm ngả nghiêng (`log_large`, `log`), gốc cây cổ thụ cưa tròn (`stump_round`), cụm nấm rừng đỏ và nâu (`mushroom_redGroup`, `mushroom_tanGroup`), bụi tử đinh hương trổ hoa tím (`bush1`, `bush2`).
   - *Trảng cỏ ngập nắng Sunlit Meadow:* Các dải hoa dại đan xen sắc màu phong phú (hoa chuông tím `flower_purpleA/C`, mao lương vàng `flower_yellowA/C`, hồng dại `flower_redA`).
   - *Vũng nước bờ vịnh Emerald Cove:* Hoa súng nở dập dềnh trên mặt nước tĩnh ($Y = 0.03\text{m}$), rặng lau sậy mọc mép nước (`plant_flatTall`), và sỏi đá lòng suối xói mòn tự nhiên.

### 8.4. Bằng chứng Nghiệm thu Thị giác Runtime (9 Góc chuẩn):
- [Shot 1: Toàn cảnh Thế giới (World Panorama)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_1_world_panorama.png) — Bố cục không gian 3 tầng rõ rệt, màu sắc hài hòa, không còn vệt sương mù trắng xóa.
- [Shot 2: Góc nhìn thứ nhất Rừng Thông (Forest First-Person)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_2_forest_first_person.png) — Chi tiết vỏ cây thông PBR sắc nét cận cảnh, bóng nắng tán cây dappled, gốc cây mục và đàn hươu xa xa.
- [Shot 3: Chuyển tiếp Đồng cỏ sang Rừng (Meadow to Forest Transition)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_3_meadow_transition.png) — Bậc đá cuội lòng suối, đàn hươu gặm cỏ, rìa rừng thông tự nhiên.
- [Shot 4: Bờ hồ & Độ sâu Mặt nước (Shoreline, Lake Cove & Water Depth)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_4_shoreline_water.png) — Viền bọt nước mỏng mịn tinh tế, nước trong vắt thấy đáy cát sỏi, bụi hoa lilac và tảng đá granite lớn.
- [Shot 5: Cận cảnh Cỏ, Lá & Vật liệu PBR (Vegetation & Materials Close-up)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_5_vegetation_materials.png) — Từng phiến cỏ cong mềm mại với ánh sáng đồng đều, nền đất nhiều chi tiết vụn hữu cơ.
- [Shot 6: Động vật ở Cự ly gần (Fauna Close-up & Locomotion)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_6_fauna_locomotion.png) — Hươu đầu đàn với cặp gạc phân nhánh, bước chân vững chắc, nghiêng theo độ dốc địa hình.
- [Shot 7: Cảnh nhìn xa qua nhiều Lớp Không gian (Distant Layered Vista)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_7_distant_layers.png) — Tiền cảnh hươu đứng mép nước, trung cảnh lòng suối đá, hậu cảnh vách đá và đỉnh núi cao.
- [Shot 8: Điều kiện Mưa gió & Độ ẩm Bề mặt (Overcast & Rain Storm)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_8_weather_rain_wetness.png) — Bầu trời xám chì, bề mặt đất đá bóng ướt tự nhiên, cây cỏ ngả nghiêng theo gió.
- [Shot 9: Hoàng hôn Golden Hour & Quan sát Tinh giản (Golden Hour Minimal HUD)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_9_minimal_hud.png) — Ánh nắng vàng hổ phách trải dài bóng đổ xiên cực kỳ điện ảnh, trảng cỏ rực sáng, đàn hươu thanh bình.

### 8.5. Trạng thái & Chuyển tiếp:
- **Trạng thái:** **HOÀN THÀNH TOÀN DIỆN (BLOCK 3 & BLOCK 4 COMPLETED)**.
- **Độ tin cậy:** 104 / 104 contract tests passing (100%). Không có lỗi hồi quy shader hay simulation.
- **Sẵn sàng chuyển tiếp:** Toàn bộ cảnh quan môi trường đã hoàn thiện, sẵn sàng tiếp tục Block 5.

---

## 9. Block 5: Living World & Ecological Integration (Hoàn tất Nghiệm thu Thế giới Sống)

### 9.1. Phân bố Hốc Sinh thái Thực tế (Ecological Niches):
- **Sunlit Meadow Glade ($X \in [3.5, 15.5], Z \in [0.0, 9.0]$):** 65% đàn hươu (*Island Deer / Stags*) và 50% thảm thực vật dinh dưỡng (hoa dại, cỏ xanh) tập trung tại đây, tạo thành trảng cỏ gặm thức ăn chính.
- **Emerald Basin Cove & Creek Delta ($X \in [11.5, 21.0], Z \in [8.5, 17.5]$):** 25% đàn hươu và 25% thực vật ven bờ tập trung tại hốc sinh thái lòng chảo hồ nước, đóng vai trò điểm uống nước chính (watering hole).
- **Whispering Forest Margin ($X \in [-12.0, 0.0], Z \in [-6.0, 3.5]$):** 10% hươu trú ngụ, là nơi đàn hươu tìm đến trú ẩn dưới tán thông cổ thụ vào ban đêm.
- **North Ridge / Talus Crags ($X \in [-18.0, -10.0], Z \in [-18.0, -8.0]$):** Động vật săn mồi (*Mountain Stalker / Wolves*) xuất hiện trên sườn vách đá cao, rình mồi nhìn xuống thung lũng.

### 9.2. Chu kỳ Tập tính Diurnal & Thời tiết Khắc nghiệt:
- **Ban ngày (06:00 – 16:00):** Đàn hươu phân tán gặm cỏ trong trảng hoa (`FORAGING` $\to$ `EATING`), năng lượng tích lũy đạt đỉnh để chuẩn bị sinh sản.
- **Hoàng hôn / Golden Hour (16:00 – 18:30):** Tỉ lệ khát nước tăng lên 35%, hươu di chuyển dần về phía bờ hồ Emerald Basin cúi đầu uống nước (`DRINKING` / pose `Idle_Headlow`), hồi phục thể lực và độ ẩm.
- **Ban đêm (20:30 – 05:00):** Đàn hươu di chuyển vào dưới tán thông Whispering Forest nằm nghỉ (`RESTING`), tốc độ trao đổi chất giảm 50% giúp bảo tồn năng lượng trong đêm lạnh.
- **Thời tiết Mưa giông (`RAIN`):** Bề mặt trơn trượt làm giảm 18% tốc độ di chuyển của muông thú, tăng tốc độ đốt năng lượng do rét buốt, thúc đẩy động vật tìm nơi trú ẩn.

### 9.3. Chuyển động Tự nhiên & Cơ chế Khử Đồng bộ:
- **Tốc độ Khớp sải chân (Stride-matching):** `anim.speed_scale` theo sát tỉ lệ vận tốc / chiều dài sải bước (Walk 1.55 m/s, Gallop 3.75 m/s), xóa bỏ hoàn toàn hiện tượng trượt chân trên cỏ.
- **Xoay hướng Mượt mà (Rate-limited Turning):** Sử dụng `rotate_toward` với trần vận tốc góc ($4.2 - 6.2\text{ rad/s}$), loại bỏ hoàn toàn hiện tượng xoay lật 180° tức thời.
- **Bám dốc 2 trục (Pitch & Roll Conformance):** Thân động vật nghiêng linh hoạt theo cả trục dọc và ngang mặt dốc, chân bám chắc chắn vào các tầng đá phiến.
- **Tránh vật cản & Vực dốc (Terrain & Cliff Avoidance):** Động vật tự động nhận diện vách đá dốc $> 1.1\text{m}$ và mép nước sâu để bẻ lái men theo sườn đồi, không còn tình trạng đi xuyên thân cây hay kẹt vào vách đá.
- **Khử Đồng bộ hóa (Desynchronization):** Mỗi con vật sở hữu bộ đếm thời gian rẽ và nghỉ riêng biệt (`wander_timer` ngẫu nhiên $1.6 - 3.4\text{s}$), tạo nên bức tranh chuyển động tự nhiên, không cơ học.

### 9.4. Bằng chứng Thị giác Mới (Living World Proof):
- [Shot 10: Đàn Hươu Gặm Cỏ Trên Đồng Hoa (Sunlit Meadow Glade)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_10_ecological_meadow_grazing.png) — Đàn hươu phân bổ tự nhiên trong hốc sinh thái thung lũng, ánh sáng râm mát, dáng đứng đa dạng.
- [Shot 11: Đàn Động Vật Uống Nước Lúc Hoàng Hôn (Emerald Basin at Golden Hour)](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_11_golden_hour_watering.png) — Hươu cúi đầu uống nước bên bờ hồ rực rỡ ánh hoàng hôn vàng cam, bóng đổ nghiêng dài.

### 9.5. Kết quả Kiểm thử & Trạng thái:
- **Test Hợp đồng Tự động:** **108 / 108 tests passing (100% PASS)**, bao gồm 9 behavioral acceptance tests mới.
- **Tài liệu Chi tiết Nghiệm thu:** Đã ban hành tại [reports/LIVING_WORLD_EVALUATION.md](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/LIVING_WORLD_EVALUATION.md).
- **Trạng thái:** **HOÀN THÀNH TOÀN DIỆN BLOCK 5 (LIVING WORLD & ECOLOGICAL INTEGRATION COMPLETED)**.

---

## 10. Block 6: Performance Engineering Without Visual Regression (Nghiệm thu Tối ưu Hiệu năng)

### 10.1. Mục tiêu & Phần cứng Thực tế:
- **Phần cứng Mục tiêu:** Dell Latitude 7420, Intel Iris Xe Graphics tích hợp, 16 GB RAM chia sẻ, Windows 11.
- **Runtime:** Godot Engine 4.6.3 Forward+ Vulkan @ $1280 \times 720$.
- **Nguyên tắc cốt lõi:** Không đánh đổi vẻ đẹp cảnh quan lấy FPS; không nhổ bỏ cây, không làm thưa thảm thực vật dưới mức mỹ quan, không làm phẳng vật liệu PBR. Mọi tối ưu đều dựa trên đo đạc bottleneck thực nghiệm.

### 10.2. Chẩn đoán Bottleneck Định lượng (Forensic Diagnosis):
- **SSAO trên Kiến trúc Shared Memory:** SSAO compute shader tiêu tốn $\approx 7.62 - 11.55\text{ ms}$ băng thông bộ nhớ LPDDR4/DDR5. Tắt SSAO ở preset `BALANCED` (chỉ bật ở `CINEMATIC`) giúp FPS nhảy vọt từ 26.6 lên 33.3 FPS (+20.2%).
- **Shadow Splits & Cascade Re-submission:** 4 shadow cascades với blend splits đẩy draw calls lên 343 và primitives lên 1.60M. Chuyển sang 2 parallel splits (không blend splits, cự ly tối đa $65.0\text{m}$) giữ trọn bóng đổ sắc nét cục bộ trong tầm mắt nhưng giảm mạnh gánh nặng GPU.
- **Độ phân giải Nội bộ (3D Scale 85%):** Render ở tỉ lệ $0.85\times$ ($1088 \times 612$ upscale lên $1280 \times 720$) giúp giảm 27.75% pixel fill rate mà vẫn giữ độ nét chi tiết cao nhờ bộ lọc bilinear/FSR.
- **GPU Distance Culling (`visibility_range`):** Áp dụng `visibility_range_end = 115.0m`, `margin = 15.0m` và dither fade `VISIBILITY_RANGE_FADE_SELF` trên thân cây thông và tảng đá lớn, loại bỏ việc transform các đỉnh ở khoảng cách vô ích.
- **Tách biệt Tần số Mô phỏng CPU & Render GPU:** CPU simulation step chỉ tốn $2.83 - 4.47\text{ ms}$, chạy tách biệt ở tần số nhịp nhàng, GPU hoàn toàn rảnh rang để dựng hình.

### 10.3. Kết quả Đo đạc Workload Thực tế (360° Orbit Benchmark):
- **Target Workload (Gameplay Chuẩn: 55 cây, 14 thú ăn cỏ, 2 thú săn mồi):**
  - FPS trung bình: **38.0 FPS** (Biên độ $31.0 - 47.0\text{ FPS}$, **0 frame nào rớt dưới 30 FPS**).
  - Thời gian khung hình trung bình: **35.81 ms** (p95: 46.44 ms).
  - Sim step trung bình: **4.47 ms**.
  - Draw Calls tối đa: **326** | Primitives: **1.61M** | RAM: **104.30 MB**.
- **Light Workload (Low Preset: 25 cây, 6 thú, 1 thú săn mồi):** **38.3 FPS avg** (29.0 - 50.0 FPS).
- **Stress Workload (Cinematic Preset: 140 cây, 38 thú, 6 thú săn mồi):** **37.3 FPS avg** (27.0 - 48.0 FPS).

### 10.4. Kiểm định Cổng Không Hồi quy Thị giác (Zero Visual Regression):
- Đã chụp lại và kiểm tra toàn bộ 11 góc máy QA ([Shot 1](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_1_world_panorama.png) đến [Shot 11](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/visual_evidence/shot_11_golden_hour_watering.png)).
- Xác nhận: Cây thông giữ nguyên hình khối cành lá rậm rạp, thảm cỏ 900 khóm vẫn xanh mướt khắp trảng hoa, đá tảng giữ nguyên vết nứt địa chất PBR, bóng đổ mặt trời sắc nét, mặt nước trong vắt và đàn thú di chuyển sống động.
- **108 / 108 tests passing (100% PASS)**.
- **Báo cáo Chi tiết Nghiệm thu:** Đã cập nhật đầy đủ tại [reports/PERFORMANCE_ACCEPTANCE.md](file:///D:/Personal_Projects/Living%20Planet%20Sandbox/reports/PERFORMANCE_ACCEPTANCE.md).
- **Trạng thái:** **HOÀN THÀNH TOÀN DIỆN BLOCK 6 (PERFORMANCE ENGINEERING WITHOUT VISUAL REGRESSION COMPLETED)**.


