# ASSET ATTRIBUTION MANIFEST — LIVING PLANET SANDBOX
## Open-Source Assets & Third-Party Attribution

Tất cả tài nguyên 3D, vật liệu và âm thanh tích hợp vào Living Planet Sandbox đều tuân thủ nghiêm ngặt yêu cầu pháp lý, có giấy phép rõ ràng (Public Domain CC0 hoặc MIT License) và tương thích hoàn toàn với Godot 4.x.

---

### 1. QUATERNIUS ULTIMATE ANIMATED ANIMALS
- **Tác giả:** Quaternius ([https://quaternius.com](https://quaternius.com))
- **Giấy phép:** [Creative Commons CC0 1.0 Universal (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/)
- **Tài nguyên sử dụng:**
  - `presentation/assets/models/Stag.gltf`: Mô hình hươu đực có sừng gạc (`Stag_Horns`), Skeleton3D, Skinned ArrayMesh (2,054 faces), AnimationPlayer chứa 13 hoạt ảnh: `Idle`, `Idle_2`, `Idle_Headlow`, `Walk`, `Gallop`, `Eating`, `Attack_Headbutt`, `Death`, v.v.
  - `presentation/assets/models/Deer.gltf`: Mô hình hươu cái, Skeleton3D, Skinned ArrayMesh (2,098 faces), AnimationPlayer 13 hoạt ảnh.
  - `presentation/assets/models/Wolf.gltf`: Mô hình sói săn mồi (Mountain Stalker), Skeleton3D, Skinned ArrayMesh (1,962 faces), AnimationPlayer chứa 11 hoạt ảnh: `Idle`, `Idle_2`, `Walk`, `Gallop`, `Eating`, `Attack`, `Death`, v.v.
- **Tích hợp:** Nạp vào `EcosystemPresentation` để thay thế hoàn toàn các khối hộp primitive `BoxMesh`, đồng bộ các clip hoạt ảnh `Idle`, `Walk`, `Gallop`, `Eating` tương ứng với state machine của `FaunaSimulation`.

---

### 2. KAYKIT FOREST NATURE PACK
- **Tác giả:** Kay Lousberg ([https://kaylousberg.com](https://kaylousberg.com))
- **Giấy phép:** [Creative Commons CC0 1.0 Universal (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/)
- **Tài nguyên sử dụng:**
  - `presentation/assets/models/forest.glb`:
    - Cây lá rộng & phong thái tự nhiên: `Tree_1_A_Color1`, `Tree_1_C_Color1`, `Tree_3_A_Color1`, `Tree_3_C_Color1`, `Tree_4_A_Color1`, `Tree_4_C_Color1`.
    - Cụm bụi rậm tầng trung: `Bush_1_E_Color1`, `Bush_3_B_Color1`.
    - Cụm cỏ nhiều lá dày (Grass Tuft): `Grass_2_D_Color1`.
    - Đá tảng tự nhiên: `Rock_1_D`, `Rock_1_J`, `Rock_2_C`, `Rock_2_G`, `Rock_3_E`, `Rock_3_L`, `Rock_3_Q`.
- **Tích hợp:** Nạp vào `VegetationScatter` và `IslandTerrain` làm thảm thực vật tầng trung và tầng trệt đa dạng.

---

### 3. KENNEY NATURE KIT
- **Tác giả:** Kenney ([https://kenney.nl/assets/nature-kit](https://kenney.nl/assets/nature-kit))
- **Giấy phép:** [Creative Commons CC0 1.0 Universal (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/)
- **Tài nguyên sử dụng:**
  - `presentation/assets/models/nature.glb`:
    - Cây thông cao cấp: `tree_pineTallA`, `tree_pineTallB`, `tree_pineDefaultA`, `tree_pineRoundA`, `tree_pineSmallA`, `tree_pineSmallB` (kèm các biến thể có tuyết đỉnh núi `tree_pineTallA_snow`).
    - Cây sồi / cổ thụ: `tree_oak_jungle`, `tree_detailed_jungle`, `tree_tall_jungle`.
    - Chi tiết môi trường: Khúc gỗ mục nằm ngang (`log`, `log_large`), gốc cây (`stump_round`), nấm rừng (`mushroom_redGroup`, `mushroom_tanTall`), hoa dại (`flower_purpleA`, `flower_redA`, `flower_yellowA`), hoa súng mặt nước (`lily_large`, `lily_small`).
- **Tích hợp:** Phân bổ theo luật sinh thái của `EnvironmentalGrid` (thông ở đồi núi và sườn dốc, sồi ở thung lũng màu mỡ, hoa và nấm dưới tán rừng, hoa súng ven hồ).

---

### 4. AMBIENTCG PBR TEXTURES
- **Tác giả:** ambientCG ([https://ambientcg.com](https://ambientcg.com))
- **Giấy phép:** [Creative Commons CC0 1.0 Universal (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/)
- **Tài nguyên sử dụng:**
  - `demo/assets/textures/ground037_alb_ht.png` & `ground037_nrm_rgh.png` (Ground037): Cỏ tự nhiên, đất mùn và rễ cây nhỏ.
  - `demo/assets/textures/rock023_alb_ht.png` & `rock023_nrm_rgh.png` (Rock023): Vách đá nứt nẻ, gồ ghề tự nhiên với rãnh xói mòn.
- **Tích hợp:** Sử dụng trong Triplanar PBR Terrain Shader của `IslandTerrain`, tạo độ sần và chi tiết bề mặt sắc nét ở cự ly gần góc nhìn Walker.

---

### 5. TERRAIN3D DEMO ASSETS
- **Tác giả:** Terrain3D Contributors ([https://github.com/TokisanGames/Terrain3D](https://github.com/TokisanGames/Terrain3D))
- **Giấy phép:** [MIT License](https://github.com/TokisanGames/Terrain3D/blob/main/LICENSE.txt)
- **Tài nguyên sử dụng:**
  - `demo/assets/models/RockA.glb`, `RockB.glb`, `RockC.glb`: Các khối đá hoa cương tự nhiên có cấp độ chi tiết LOD.
  - `demo/assets/materials/M_rock23_tp.tres`: Vật liệu World-Triplanar Normal PBR cho đá tảng.
- **Tích hợp:** Nạp vào `RockBoulder` và rải tại bãi đá đổ Talus dưới chân vách Eastern Granite Bluff và lòng suối Valley Creek.

---

### 6. OPEN-SOURCE WATER SHADER TECHNIQUES
- **Tác giả & Tham chiếu:**
  - Emil Johansen (`emilje/godot-water-shader`: [https://github.com/emilje/godot-water-shader](https://github.com/emilje/godot-water-shader))
  - Chrisknyfe (`Chrisknyfe/boujie_water_shader`: [https://github.com/Chrisknyfe/boujie_water_shader](https://github.com/Chrisknyfe/boujie_water_shader))
- **Giấy phép:** [MIT License](https://opensource.org/licenses/MIT)
- **Thuật toán & Kỹ thuật tích hợp:**
  - `presentation/shaders/water.gdshader`: Triển khai sóng Gerstner 2 chiều, hấp thụ quang học theo độ sâu, khúc xạ quang học mặt nước (`screen_texture` refraction) làm méo hình sỏi đáy hồ, vi sóng gợn và bọt sóng shoreline foam.

---

### 7. OPEN-SOURCE FOLIAGE WIND SHADER TECHNIQUES
- **Tác giả & Tham chiếu:**
  - Caphindsight (`caphindsight/Foliage3D`: [https://github.com/caphindsight/Foliage3D](https://github.com/caphindsight/Foliage3D))
  - Godot Shaders Community ([https://godotshaders.com](https://godotshaders.com))
- **Giấy phép:** [MIT License](https://opensource.org/licenses/MIT)
- **Thuật toán & Kỹ thuật tích hợp:**
  - `presentation/shaders/foliage_wind.gdshader`: Triển khai Two-Sided Opaque Foliage Rendering (`render_mode cull_disabled, depth_draw_opaque;`), đảo chiều pháp tuyến mặt sau (`NORMAL = FRONT_FACING ? NORMAL : -NORMAL;`), dao động gió theo vector thời tiết, phản ứng mặt lá ướt và kiểm soát ánh sáng tán xạ (subsurface backlight).

---

### 8. GW TUTS GAME-READY HERO FOLIAGE & BOTANICAL ASSETS
- **Tác giả:** Lakshman (GW Tuts: [https://github.com/Lakshman-YT/Forest-Godot4](https://github.com/Lakshman-YT/Forest-Godot4))
- **Giấy phép:** [Open-Source Permissive Free Project](https://github.com/Lakshman-YT/Forest-Godot4/blob/main/README.md)
- **Tài nguyên sử dụng:**
  - **Mô hình thông tự nhiên (Hero Scots Pines):**
    - `presentation/assets/foliage/pine1.gltf`, `pine1.bin` (ArrayMesh 2 surfaces: thân vỏ PBR & tán cành kim 3D).
    - `presentation/assets/foliage/pine2.gltf`, `pine2.bin`.
    - `presentation/assets/foliage/pine3.gltf`, `pine3.bin`.
  - **Mô hình bụi hoa rậm (Hero Lilac Bushes):**
    - `presentation/assets/foliage/bush1.gltf`, `bush1.bin` (Lilac sapling 2 surfaces: cành nhánh & cụm lá).
    - `presentation/assets/foliage/bush2.gltf`, `bush2.bin`.
  - **Bộ Texture PBR & Foliage Card Atlases:**
    - `Cluster_albedo.png`, `pine_leaf_normal.jpg`, `pine_leaf_roughness.jpg`: Atlas cành lá kim thông chi tiết cao với kênh alpha cutout.
    - `pine_bark_base.jpg`, `pine_bark_normal.jpg`, `pine_bark_roughness.jpg`: Vỏ cây thông nứt nẻ gồ ghề chân thực.
    - `lilac_cards_color.png`, `lilac_cards_normal.jpg`, `lilac_cards_roughness.jpg`: Tấm lá bụi rậm lilac.
    - `Lilac_bark_color.jpg`, `Lilac_bark_normal.jpg`: Vỏ cành thân bụi rậm.
- **Tích hợp & Sửa đổi:**
  - Tích hợp vào `TreePine` (`presentation/props/tree_pine.gd`), `VegetationScatter` (`presentation/environment/vegetation_scatter.gd`) và `EcosystemPresentation` (`presentation/ecosystem/ecosystem_presentation.gd`).
  - Thay thế hoàn toàn các khối trụ cam sặc sỡ và nón hình học thô sơ (`Tree_4_A_Color1` / `nature.glb` toy cones) bằng mô hình thông có tỉ lệ sinh học chuẩn xác (cao 9.5m – 14.5m), phân bố thành các rặng thông tự nhiên.
  - Phân tách 2 surface độc lập: Surface 0 sử dụng `StandardMaterial3D` với normal map và roughness map vỏ cây; Surface 1 sử dụng `foliage_wind.gdshader` với kỹ thuật Alpha Scissor (ngưỡng 0.40–0.45), Two-sided Normal Inversion, dao động cành theo gió và tán xạ ngược ánh sáng mặt trời (backlight translucency).

