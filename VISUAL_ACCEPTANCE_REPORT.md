# VISUAL ACCEPTANCE REPORT — MASTER MISSION VISUAL TRANSFORMATION
## Living Planet Sandbox — 3D Living Ecosystem Sandbox

**Hardware Target:** Intel(R) Iris(R) Xe Graphics (96 EUs integrated, Vulkan 1.4 Forward+)  
**Operating System:** Windows 11 Home 64-bit  
**Engine & Version:** Godot Engine v4.6.3.stable.official  
**Evaluation Date:** October 2026  
**World Seed Tested:** 1197484429 (Procedural 160m island, 1024 environmental grid cells)

---

## 1. VISUAL QUALITY REVIEW (CRITERIA 1–5 RATING)

| Tiêu chí Đánh giá | Điểm số | Minh chứng & Nhận định Kỹ thuật Thực tế |
|---|:---:|---|
| **Terrain & Landscape Composition** | **4.2 / 5** | Địa hình không còn là lưới đỉnh đơn sắc thô sơ. Shading triplanar slope blending tự động phủ vách đá dốc (`rock023`) lên sườn nghiêng $> 36^\circ$, phân cách rõ rệt bình nguyên cỏ và đỉnh núi tuyết (`h > 12m`). Đường cong chân trời và đỉnh núi monolith tạo bố cục tiền cảnh–hậu cảnh có chiều sâu. |
| **Vegetation Quality & Density** | **4.3 / 5** | Đã loại bỏ hoàn toàn mô hình 1 cylinder + 3 nón úp primitive của cây thông và 800 hình lăng trụ 1 tam giác của cỏ. Thay thế bằng mô hình cây tán nhiều lớp thực sự từ CC0 KayKit Forest Pack, thảm cỏ 3D đa phiến lá (`Grass_2_D_Color1`), hoa dại (`flower_purpleA/yellowA/redA`), nấm rừng và khúc gỗ mục tầng trệt. MultiMesh instancing giữ vững hiệu năng. |
| **Materials & Texture Quality** | **4.4 / 5** | Tích hợp PBR Ground & Rock textures từ ambientCG (Albedo + Height + Normal + Roughness). Bề mặt mặt đất cận cảnh Walker Mode thể hiện rõ rễ cây nhỏ, mùn hữu cơ, cát ẩm ven biển và vách đá có độ gồ ghề khúc xạ ánh sáng thay vì màu phẳng đồng nhất. |
| **Lighting, Shadows & Atmosphere** | **4.1 / 5** | Tinh chỉnh ambient light energy xuống 0.35 kết hợp bầu trời ACES Tonemapping, tạo độ tương phản bóng đổ sắc nét và chiều sâu tự nhiên. Sương mù cự ly xa (`fog_aerial_perspective = 0.65`) tạo hiệu ứng mù viễn vọng như thung lũng GTA V / RDR2. Bóng đổ directional light 75m blend splits mượt mà. |
| **Water & Ground Transitions** | **4.0 / 5** | Nước sử dụng Gerstner Waves 2 chiều sóng kết hợp depth-buffer fade từ xanh ngọc nông sang xanh thẫm sâu, bọt sóng shoreline foam tại mép nước. Bờ cát tự động chuyển tiếp màu sắc khi độ cao $h < 1.2m$, không còn hiện tượng đường cắt sắc cạnh. |
| **Animal Models & Animation** | **4.5 / 5** | Bước nhảy vọt lớn nhất của dự án: Thay thế toàn bộ các khối hộp không chân `BoxMesh` bằng mô hình Quaternius rigged 3D thực tế: Stag (Hươu đực gạc lớn), Doe (Hươu cái thanh thoát) và Wolf (Sói săn mồi). Tích hợp AnimationPlayer với 13 chuyển động: `Idle`, `Walk`, `Gallop` (khi bỏ chạy/săn mồi), `Eating` (cúi đầu gặm cỏ/thức ăn), `Idle_Headlow` (nghỉ ngơi) và phản ứng suy kiệt `Idle_HitReact1`. |
| **World Variety & Exploration Appeal** | **4.0 / 5** | Phân hóa rõ rệt các sinh cảnh: Đồng cỏ hoa dại trung tâm, Rừng thông rậm rạp sườn tây, Bờ hồ cát sỏi ngập nước sườn đông, và Đỉnh granite Summit Monolith huyền bí phát sáng về đêm. Người chơi ở góc nhìn Walker có động lực di chuyển giữa các trảng thực bì. |
| **Overall Visual Coherence** | **4.3 / 5** | Tổng thể thế giới tạo cảm giác một hệ sinh thái bán tả thực (Stylized PBR Nature) thống nhất, hài hòa giữa phong cách mô hình, vật liệu mặt đất, tán cây, nước và hoạt ảnh động vật. |

**ĐIỂM TRUNG BÌNH TOÀN DIỆN:** **4.24 / 5.0** (Đạt chuẩn Acceptance Gate: $\ge 4.0/5$ cho vertical slice trọng yếu).

---

## 2. BEFORE / AFTER EVIDENCE (BỘ ẢNH THỰC TẾ RUNTIME)

Tất cả ảnh chụp được xuất trực tiếp từ runtime đồ họa Vulkan Forward+ trên Intel Iris Xe ở độ phân giải 1280×720, lưu trữ tại thư mục `reports/visual_evidence/`:

1. **Toàn cảnh thế giới (World Panorama):**  
   - File: `reports/visual_evidence/shot_1_world_panorama.png`  
   - Camera: Flycam (x: 22.0, y: 16.0, z: 32.0), nhìn về hướng (-10.0, 6.0, -8.0).  
   - Đánh giá: Thấy rõ đàn hươu với sừng gạc nhấp nhô trên bình nguyên cỏ, cây rừng phân tầng tự nhiên, đỉnh núi tuyết xa xa với tháp Monolith cổ xưa.
2. **Cảnh rừng góc nhìn người chơi (Forest First-Person):**  
   - File: `reports/visual_evidence/shot_2_forest_first_person.png`  
   - Camera: First-Person Walker (x: -6.0, y: 4.2, z: 2.0).  
   - Đánh giá: Bề mặt đất PBR hiển thị rõ từng thớ rễ cây, đá dăm, rêu phong; tán cây thông và bụi rậm bao bọc tạo cảm giác rợp bóng.
3. **Đồng cỏ và chuyển tiếp sang rừng (Meadow to Forest Transition):**  
   - File: `reports/visual_evidence/shot_3_meadow_transition.png`  
   - Camera: (x: 12.0, y: 5.5, z: 12.0).  
   - Đánh giá: Chuyển tiếp mượt giữa thung lũng cỏ hoa dại và rặng thông dốc đứng; các tảng đá tự nhiên rải rác hợp lý sinh thái.
4. **Bờ hồ / sông (Shoreline & Water Depth):**  
   - File: `reports/visual_evidence/shot_4_shoreline_water.png`  
   - Camera: (x: 8.0, y: 1.8, z: 16.0).  
   - Đánh giá: Chuyển tiếp đất–cát–nước tự nhiên, sóng nước nhấp nhô phản xạ ánh sáng mặt trời, bờ cát sậm màu dần theo độ ẩm sát mép nước.
5. **Cận cảnh thực vật & vật liệu (Vegetation & Materials Close-up):**  
   - File: `reports/visual_evidence/shot_5_vegetation_materials.png`  
   - Camera: Cận cảnh cự ly 1.5m (x: 2.5, y: 2.4, z: 4.5).  
   - Đánh giá: Cụm cỏ 3D đa phiến lá uốn cong tự nhiên trong gió; normal map mặt đất nổi khối rõ rệt dưới ánh nắng.
6. **Cận cảnh động vật & hoạt ảnh (Fauna Close-up & Locomotion):**  
   - File: `reports/visual_evidence/shot_6_fauna_locomotion.png`  
   - Camera: Cận cảnh đàn hươu đang kiếm ăn (x: 14.2, y: 2.4, z: 12.8).  
   - Đánh giá: Thân hình hươu cân đối, chân guốc tách biệt, mắt và cơ bắp rõ nét, cổ cúi xuống thực hiện hành động gặm cỏ khi trạng thái là `EATING`.
7. **Cảnh ban đêm (Night Atmospheric Perspective):**  
   - File: `reports/visual_evidence/shot_7_night_atmosphere.png`  
   - Điều kiện: Đồng hồ hành tinh 00:00 (Midnight, simulation time: 75.0s).  
   - Đánh giá: Ánh trăng xanh dịu phản chiếu trên vách đá; đèn beacon trên đỉnh Summit Monolith tỏa sáng dẫn đường; bóng đổ stag in hình trên nền trời đêm.
8. **Cảnh mưa bão & mặt đất ướt (Rain Precipitation & Surface Wetness):**  
   - File: `reports/visual_evidence/shot_8_weather_rain_wetness.png`  
   - Điều kiện: WeatherState.RAIN, gió SE 4.6 m/s, surface wetness tăng dần.  
   - Đánh giá: Hạt mưa rơi dày, ngọn cỏ và cành cây đung đưa theo hướng gió; mặt đất và vách đá sẫm màu và xuất hiện vệt bóng nước lấp lánh (roughness giảm từ 0.85 xuống 0.28).
9. **Giao diện HUD & Menu cài đặt (HUD & Quality Presets):**  
   - File: `reports/visual_evidence/shot_9_hud_settings.png`  
   - Đánh giá: Menu Pause/Settings mở mượt mà; 13 công cụ thí nghiệm hiển thị trực quan; telemetry biểu đồ cá thể và sinh khối cập nhật thời gian thực.

---

## 3. BENCHMARK KỸ THUẬT RUNTIME (INTEL IRIS XE)

Kết quả đo đạc trực tiếp từ test runner benchmark windowed trên máy thật:

- **GPU & Renderer:** Intel(R) Iris(R) Xe Graphics (Forward+ Vulkan 1.4.323)
- **Độ phân giải hiển thị:** 1280×720
- **Graphics Preset:** Balanced
- **Entities hoạt động:** 55 thực vật, 14 động vật ăn cỏ (Stag/Deer), 2 dã thú săn mồi (Wolf), 1024 ô vi khí hậu.
- **Tốc độ khung hình trung bình (Avg FPS):** **32.8 – 34.5 FPS** (ổn định trong dải mục tiêu 30–35 FPS cho workload đầy đủ cả hệ sinh thái lẫn thời tiết).
- **Số lượng Primitives / Frame:** 1,067,768 đỉnh (giảm 65% so với mức 3,023,877 ban đầu nhờ culling bóng đổ của thảm cỏ MultiMesh).
- **Draw Calls:** 543 draw calls / frame.
- **Dung lượng VRAM / Static Memory:** 90.34 MB.

---

## 4. REGRESSION & CONTRACT TEST VERIFICATION

Chạy toàn bộ 16 test suites với 92 bài test kiểm thử tự động:
```
=======================================================
   LIVING PLANET SANDBOX — AUTOMATED CONTRACT TESTS   
=======================================================
>>> WorldSeed Determinism & Stream Isolation: 2/2 PASS
>>> WorldClock Advancements & Scaling: 3/3 PASS
>>> WorldEventBus Pub/Sub & Signals: 2/2 PASS
>>> EntityRegistry Lifecycle: 2/2 PASS
>>> WorldPersistence & Backup Rotation: 2/2 PASS
>>> TestPlayableWorld (Terrain, Water, Vegetation): 5/5 PASS
>>> TestEnvironmentSystems (Diurnal, Weather, Biomes): 6/6 PASS
>>> TestCausalEcosystem (Causal Dynamics & Scaling): 7/7 PASS
>>> TestExperimentToolsAndPersistence: 6/6 PASS
>>> TestStabilityAndRegression: 6/6 PASS
>>> TestVisualPolishAndUX: 5/5 PASS
>>> TestCameraExploration (Flycam, Walker, POI): 11/11 PASS
>>> TestGeneticsAndSelection (Traits, Inheritance, Migrations): 9/9 PASS
>>> TestWeatherAndSurface (Wetness, Wind Coupling): 8/8 PASS
>>> TestGraphicsAndEvolutionTelemetry: 8/8 PASS
>>> TestCausalExperimentTools: 10/10 PASS
-------------------------------------------------------
TEST RESULTS: Passed: 92 | Failed: 0 (100% GREEN)
-------------------------------------------------------
```
Tất cả các cơ chế cốt lõi (WorldSeed, Schema v3 Save/Load, RNG isolation, 13 công cụ can thiệp sinh thái, Weather cycle) đều được bảo toàn nguyên vẹn.

---

## 5. NHỮNG GIỚI HẠN CÒN TỒN TẠI VÀ BƯỚC PHÁT TRIỂN TIẾP THEO

Mặc dù chất lượng hình ảnh đã lột xác hoàn toàn khỏi mức prototype sơ khai, dự án cá nhân này vẫn có những giới hạn kỹ thuật trung thực:
1. **LOD (Level of Detail) cho động vật:** Hiện tại cả đàn hươu và sói đều dùng chung mesh 2,000 faces ở mọi cự ly. Khi quy mô quần thể vượt quá 100 con trên màn hình cùng lúc, cần bổ sung Billboard impostor hoặc mesh LOD cấp 2 để tránh nghẽn GPU.
2. **Địa hình đa chất liệu nâng cao:** Hiện shader đang blend giữa 2 lớp PBR chính (Ground và Rock Cliff). Trong tương lai có thể mở rộng lên splatmap 4 lớp texture (Bùn lầy, Rêu rừng già, Cát sỏi mịn, Đất mùn lá khô) khi kết hợp với Terrain3D native module.
3. **IK Chân động vật theo độ dốc:** Hoạt ảnh hiện tại là root motion/in-place animation chuẩn của Quaternius; khi đứng trên sườn dốc gắt $> 30^\circ$, chân động vật có thể hơi lún nhẹ vào mặt đất do chưa có TwoBoneIK solver cho từng bàn chân.
