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
- **Tích hợp:** Rải tại chân núi, bãi biển và các trảng đá cheo leo.
