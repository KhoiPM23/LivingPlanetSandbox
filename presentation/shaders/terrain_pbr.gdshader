shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_schlick_ggx;

// Terrain Triplanar PBR Shader with Slope Blending & Biome Vertex Modulation
// Living Planet Sandbox — Designed for Intel Iris Xe & Vulkan Forward+

uniform sampler2D ground_albedo : source_color, filter_linear_mipmap;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap;

uniform float uv_scale : hint_range(0.01, 1.0) = 0.32;
uniform float rock_uv_scale : hint_range(0.01, 1.0) = 0.16;
uniform float slope_threshold : hint_range(0.05, 0.9) = 0.18;
uniform float slope_blend : hint_range(0.02, 0.5) = 0.08;

uniform vec4 sand_color : source_color = vec4(0.58, 0.50, 0.38, 1.0);
uniform vec4 snow_color : source_color = vec4(0.93, 0.95, 0.99, 1.0);
uniform float snow_height : hint_range(5.0, 90.0) = 48.0;
uniform float snow_transition : hint_range(1.0, 20.0) = 8.0;

uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform float puddle_depth : hint_range(0.0, 1.0) = 0.0;
uniform float snow_drift_accretion : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec4 v_vertex_color;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_vertex_color = COLOR;
}

void fragment() {
	vec3 w_norm = normalize(v_world_normal);
	float h = v_world_pos.y;
	
	// Slope factor: 0.0 on flat plateau, 1.0 on vertical wall
	float slope = 1.0 - clamp(abs(w_norm.y), 0.0, 1.0);
	float rock_factor = smoothstep(slope_threshold - slope_blend, slope_threshold + slope_blend, slope);

	// Alpine elevation rockiness (higher mountains have exposed granite & scree even on moderate slopes)
	float alpine_elevation_rock = clamp((h - 22.0) / 16.0, 0.0, 1.0) * 0.48;
	rock_factor = clamp(rock_factor + alpine_elevation_rock, 0.0, 1.0);
	
	// 1. High-efficiency ground texture sample
	vec2 ground_uv = v_world_pos.xz * uv_scale;
	vec4 g_albedo_tex = texture(ground_albedo, ground_uv);
	vec4 g_normal_tex = texture(ground_normal, ground_uv);
	
	// Procedural macro detiling using smooth ALU interference (zero extra texture fetches)
	float macro_var = 0.90 + 0.18 * sin(v_world_pos.x * 0.048 + v_world_pos.z * 0.035) + 0.06 * cos(v_world_pos.z * 0.068);
	
	// Stylized Anime Painterly Ground:
	// Remap raw scanned luminance into curated hand-painted gradients, eliminating harsh photorealistic gravel noise
	float g_lum = dot(g_albedo_tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 painterly_humus = vec3(0.22, 0.16, 0.10) * (macro_var * 0.35 + 0.65);
	vec3 painterly_moss = vec3(0.32, 0.44, 0.18);
	vec3 painterly_emerald = vec3(0.42, 0.70, 0.24); // Harmonized directly with anime grass roots
	vec3 stylized_grass_ramp = mix(painterly_moss, painterly_emerald, smoothstep(0.28, 0.68, g_lum));
	
	// Forest loam & pine needle woodland understory
	vec3 forest_loam = mix(painterly_humus, vec3(0.28, 0.20, 0.13), g_lum * 0.5);
	// Radiant temperate meadow grass harmonized with character & foliage DNA
	vec3 grass_textured = mix(forest_loam * 0.78, stylized_grass_ramp, 0.72 + 0.28 * g_albedo_tex.a);
	
	// Blend between fertile meadow grass and woodland loam based on vertex color greenness
	float meadow_factor = clamp((v_vertex_color.g - v_vertex_color.r * 0.60) * 2.5, 0.0, 1.0);
	vec3 ground_col = mix(forest_loam, grass_textured, meadow_factor * 0.92);
	
	// Detect animal trail & compacted soil from vertex color (warm dark clay token)
	float trail_mask = clamp((v_vertex_color.r * 1.25 - v_vertex_color.g) * 3.0, 0.0, 1.0) * step(v_vertex_color.r, 0.34);
	vec3 trail_col = vec3(0.24, 0.18, 0.12) * (macro_var * 0.25 + 0.75);
	ground_col = mix(ground_col, trail_col, trail_mask * 0.90);
	
	float ground_rough = mix(0.85, g_normal_tex.a, 0.55);

	// High-frequency micro detail normal (distance-attenuated within 16m for close-up tactility)
	vec3 ground_norm_blended = g_normal_tex.rgb;
	float cam_dist = length(v_world_pos - (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
	if (cam_dist < 16.0) {
		vec2 detail_uv = v_world_pos.xz * (uv_scale * 3.6);
		vec2 dX_det = dFdx(detail_uv);
		vec2 dY_det = dFdy(detail_uv);
		vec4 g_detail_nrm = textureGrad(ground_normal, detail_uv, dX_det, dY_det);
		float detail_factor = clamp(1.0 - (cam_dist / 16.0), 0.0, 1.0);
		ground_norm_blended = mix(g_normal_tex.rgb, normalize(g_normal_tex.rgb + (g_detail_nrm.rgb - vec3(0.5)) * 0.40), detail_factor);
	}
	
	// 2. Rock cliff texture with Stylized Geological Strata & Chiseled Bevels
	vec3 base_col = ground_col;
	float base_rough = ground_rough;
	vec3 base_normal = ground_norm_blended;
	float h_ground = g_albedo_tex.a;
	float h_rock = 0.5;
	float blended_rock = 0.0;

	if (rock_factor > 0.05) {
		vec2 rock_uv;
		if (abs(w_norm.x) > abs(w_norm.z)) {
			rock_uv = v_world_pos.zy * rock_uv_scale;
		} else {
			rock_uv = v_world_pos.xy * rock_uv_scale;
		}

		vec2 dX_rock = dFdx(rock_uv);
		vec2 dY_rock = dFdy(rock_uv);
		vec4 rock_alb = textureGrad(rock_albedo, rock_uv, dX_rock, dY_rock);
		vec4 rock_nrm = textureGrad(rock_normal, rock_uv, dX_rock, dY_rock);

		// Stylized Geological Strata Banding (Genshin Liyue/Mondstadt Crag Aesthetics)
		float strata = sin(v_world_pos.y * 0.92 + sin(v_world_pos.x * 0.22 + v_world_pos.z * 0.22) * 1.35) * 0.5 + 0.5;
		vec3 rock_slate = vec3(0.42, 0.45, 0.47);
		vec3 rock_warm_strata = vec3(0.54, 0.49, 0.43);
		vec3 stylized_rock = mix(rock_slate, rock_warm_strata, strata * 0.40);
		float r_lum = dot(rock_alb.rgb, vec3(0.299, 0.587, 0.114));
		vec3 rock_refined = mix(stylized_rock, stylized_rock * (r_lum * 1.40), 0.35);

		// Chiseled Bevel Edge Highlight on Shelf Creasts
		float bevel_crest = pow(1.0 - abs(w_norm.y), 3.5) * clamp(w_norm.y * 2.2, 0.0, 1.0) * 0.18;
		rock_refined += vec3(0.14, 0.16, 0.13) * bevel_crest;

		// 3. Contrast-preserving Height-Blending
		h_rock = rock_alb.a;
		float h_blend_depth = 0.20;
		float h_diff = (h_rock + rock_factor) - (h_ground + (1.0 - rock_factor));
		blended_rock = clamp((h_diff / h_blend_depth) * 0.5 + 0.5, 0.0, 1.0);

		base_col = mix(ground_col, rock_refined, blended_rock);
		base_rough = mix(ground_rough, mix(0.72, rock_nrm.a, 0.50), blended_rock);
		base_normal = mix(ground_norm_blended, rock_nrm.rgb, blended_rock);

		// Northern Shaded Velvety Moss on Cliffs (RDR2 & TotK Atmospheric Naturalism)
		if (blended_rock > 0.02 && h < 38.0) {
			float north_bias = clamp(-w_norm.z * 1.5 + 0.25, 0.0, 1.0);
			float ledge_factor = clamp((w_norm.y - 0.12) / 0.50, 0.0, 1.0);
			float elev_moss = clamp((38.0 - h) / 28.0, 0.0, 1.0);
			float moss_weight = clamp(north_bias * (0.35 + 0.65 * ledge_factor) * elev_moss, 0.0, 1.0) * blended_rock;
			
			if (moss_weight > 0.01) {
				vec3 moss_col = vec3(0.22, 0.46, 0.16) * (macro_var * 0.35 + 0.65);
				base_col = mix(base_col, moss_col, moss_weight * 0.85);
				base_rough = mix(base_rough, 0.90, moss_weight * 0.80);
			}
		}
	}
	
	// 4. Shoreline Sand & Capillary Wetness Blending (near waterline h < 1.8m)
	if (h < 1.8) {
		float sand_factor = clamp((1.8 - h) / 1.5, 0.0, 1.0) * (1.0 - blended_rock * 0.72);
		float sand_h_diff = (sand_factor + (1.0 - h_ground) * 0.35) - 0.22;
		float sand_blend = clamp(sand_h_diff / 0.20, 0.0, 1.0) * sand_factor;
		
		vec3 sand_base = mix(sand_color.rgb * 0.95, vec3(0.32, 0.27, 0.22), g_albedo_tex.r);
		// Dynamic wave-synchronized lapping wetness fringe matching water.gdshader
		float wave_wash = 0.5 + 0.5 * sin(TIME * 1.5 + v_world_pos.x * 1.2 + v_world_pos.z * 1.0);
		float shoreline_wet = clamp((0.60 - h + wave_wash * 0.10) / 0.60, 0.0, 1.0);
		
		vec3 wet_sand = mix(sand_base, sand_base * 0.56, shoreline_wet);
		base_col = mix(base_col, wet_sand, sand_blend);
		base_rough = mix(base_rough, mix(0.48, 0.14, shoreline_wet), sand_blend);
	}
	
	// 4b. Lowland Lake Mud & Riparian Humus Blending (h between 1.2m and 3.4m away from open ocean)
	if (h >= 1.2 && h <= 3.6 && slope < 0.32) {
		float mud_band = clamp(1.0 - abs(h - 2.2) / 1.4, 0.0, 1.0);
		float lake_mud_weight = mud_band * (1.0 - blended_rock) * 0.48;
		vec3 rich_mud = vec3(0.19, 0.14, 0.09) * (painterly_humus * 0.65 + 0.35);
		base_col = mix(base_col, rich_mud, lake_mud_weight);
		base_rough = mix(base_rough, 0.82, lake_mud_weight);
	}
	
	// 5. Alpine Summit Snow & Glacial Frost Blending (elevation > snow_height)
	float snow_sparkle = 0.0;
	if (h > snow_height) {
		float snow_factor = clamp((h - snow_height) / snow_transition, 0.0, 1.0);
		// Snow adheres on gentler ledges, ridges, and cirques; sheer rock cliffs expose dark granite
		float slope_adherence = clamp((w_norm.y - 0.35) / 0.38, 0.0, 1.0);
		float final_snow = snow_factor * slope_adherence;
		
		// Alpine snow tint: crisp white with subtle glacial azurite depth
		vec3 alpine_snow = mix(snow_color.rgb, vec3(0.88, 0.94, 1.0), 0.25 * (1.0 - w_norm.y));
		base_col = mix(base_col, alpine_snow, final_snow);
		base_rough = mix(base_rough, 0.42, final_snow);
		snow_sparkle = final_snow;
	}
	
	// 6. Surface Wetness, Hydrological Puddle Pooling & Snow Accretion
	if (wetness > 0.01 || puddle_depth > 0.01) {
		float effective_wetness = max(wetness, puddle_depth * 0.75);
		base_col = mix(base_col, base_col * 0.70, effective_wetness);
		base_rough = mix(base_rough, 0.12, effective_wetness * 0.92);
		SPECULAR = mix(0.12, 0.75, effective_wetness);

		// Dynamic Rain Puddle pooling in low-slope terrain depressions:
		if (puddle_depth > 0.01 && slope < 0.22 && h > 0.6) {
			float depression = clamp((1.0 - h_ground) * 1.5 + (0.95 - macro_var) * 2.0, 0.0, 1.0);
			float puddle_mask = smoothstep(0.40, 0.85, depression * puddle_depth);
			if (puddle_mask > 0.01) {
				vec3 puddle_water_col = vec3(0.09, 0.14, 0.16);
				base_col = mix(base_col, puddle_water_col, puddle_mask * 0.85);
				base_rough = mix(base_rough, 0.02, puddle_mask);
				SPECULAR = mix(SPECULAR, 0.95, puddle_mask);
			}
		}
	} else {
		SPECULAR = mix(mix(0.12, 0.28, blended_rock), 0.55, snow_sparkle);
	}

	// 7. Winter Seasonal Snow Drift Accretion across lowlands
	if (snow_drift_accretion > 0.01) {
		float lowland_snow = clamp((w_norm.y - 0.40) / 0.35, 0.0, 1.0) * snow_drift_accretion;
		vec3 drift_color = mix(snow_color.rgb, vec3(0.90, 0.94, 0.98), 0.30);
		base_col = mix(base_col, drift_color, lowland_snow * 0.85);
		base_rough = mix(base_rough, 0.45, lowland_snow * 0.80);
	}
	
	ALBEDO = base_col;
	ROUGHNESS = base_rough;
	METALLIC = 0.02;
	vec3 eff_world_norm = normalize(v_world_normal);

	// Micro-Rain Ripple Normal Perturbation on Wet Surfaces (RDR2 Rainy Tactility)
	if (wetness > 0.02) {
		vec2 rip_uv1 = v_world_pos.xz * 12.0 + vec2(TIME * 7.5, TIME * 4.8);
		vec2 rip_uv2 = v_world_pos.xz * 16.5 - vec2(TIME * 5.2, TIME * 8.1);
		float rip1 = sin(rip_uv1.x) * cos(rip_uv1.y);
		float rip2 = sin(rip_uv2.x + 1.2) * cos(rip_uv2.y + 0.9);
		vec3 rip_norm = normalize(vec3(rip1 * 0.5 + rip2 * 0.5, 1.0, rip2 * 0.5 - rip1 * 0.5));
		eff_world_norm = normalize(mix(eff_world_norm, rip_norm, wetness * 0.22));
	}

	// NORMAL in Godot spatial fragment() must be in VIEW SPACE.
	// Transforming eff_world_norm to view space preserves identical light shading invariant of camera pitch/yaw.
	NORMAL = normalize(mat3(VIEW_MATRIX) * eff_world_norm);

	// Slope-dependent contact crevice ambient occlusion (Minecraft shader style deep crevices)
	float crevice_ao = clamp(0.74 + 0.26 * smoothstep(-0.2, 0.8, w_norm.y), 0.72, 1.0);
	AO = crevice_ao;
	AO_LIGHT_AFFECT = 0.50;
}
