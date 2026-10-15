shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Terrain Triplanar PBR Shader with Slope Blending & Biome Vertex Modulation
// Living Planet Sandbox — Designed for Intel Iris Xe & Vulkan Forward+

uniform sampler2D ground_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic;

uniform float uv_scale : hint_range(0.01, 1.0) = 0.22;
uniform float rock_uv_scale : hint_range(0.01, 1.0) = 0.14;
uniform float slope_threshold : hint_range(0.1, 0.9) = 0.25;
uniform float slope_blend : hint_range(0.02, 0.5) = 0.10;

uniform vec4 sand_color : source_color = vec4(0.58, 0.50, 0.38, 1.0);
uniform vec4 snow_color : source_color = vec4(0.93, 0.95, 0.99, 1.0);

uniform float wetness : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec4 v_vertex_color;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_vertex_color = COLOR;
}

vec3 get_triplanar_weights(vec3 norm) {
	vec3 weights = abs(norm);
	weights = pow(weights, vec3(4.0));
	return weights / (weights.x + weights.y + weights.z);
}

void fragment() {
	vec3 w_norm = normalize(v_world_normal);
	vec3 weights = get_triplanar_weights(w_norm);
	
	// Slope factor: 0.0 on flat plateau, 1.0 on vertical wall
	float slope = 1.0 - clamp(abs(w_norm.y), 0.0, 1.0);
	float rock_factor = smoothstep(slope_threshold - slope_blend, slope_threshold + slope_blend, slope);
	
	// 1. Ground texture with macro detiling (planar XZ projection)
	vec2 ground_uv = v_world_pos.xz * uv_scale;
	vec2 macro_uv = v_world_pos.xz * (uv_scale * 0.16);
	vec4 g_albedo_tex = texture(ground_albedo, ground_uv);
	vec4 g_normal_tex = texture(ground_normal, ground_uv);
	vec4 g_macro_tex = texture(ground_albedo, macro_uv);
	
	// Blend micro and macro samples to break repetition across large viewing distances
	vec3 ground_raw = mix(g_albedo_tex.rgb, g_albedo_tex.rgb * g_macro_tex.rgb * 1.05, 0.35);
	
	// Natural subalpine temperate coloration:
	// Forest loam & pine needle mulch for understory
	vec3 forest_loam = vec3(0.13, 0.09, 0.06) * (ground_raw * 0.75 + 0.32);
	
	// Natural olive-sage temperate meadow — muted, warm, not pure-green
	// Base: dark humus, tips: warm sage-olive in sun
	float grass_micro = clamp((g_albedo_tex.g * 0.70 + g_macro_tex.r * 0.30) * 1.25, 0.0, 1.0);
	vec3 grass_base = mix(vec3(0.10, 0.19, 0.07), vec3(0.18, 0.30, 0.11), grass_micro);
	vec3 grass_textured = mix(forest_loam * 0.65, grass_base, 0.85);
	
	// Blend between fertile meadow grass and woodland loam based on vertex color greenness
	float meadow_factor = clamp((v_vertex_color.g - v_vertex_color.r * 0.65) * 2.4, 0.0, 1.0);
	vec3 ground_col = mix(forest_loam, grass_textured, meadow_factor * 0.90);
	
	// Detect animal trail & compacted soil from vertex color (dark rich loam token)
	float trail_mask = clamp((v_vertex_color.r * 1.25 - v_vertex_color.g) * 3.0, 0.0, 1.0) * step(v_vertex_color.r, 0.34);
	vec3 trail_col = vec3(0.15, 0.10, 0.07) * (ground_raw * 0.70 + 0.30);
	ground_col = mix(ground_col, trail_col, trail_mask * 0.92);
	
	float ground_rough = mix(0.88, g_normal_tex.a, 0.65);
	
	// 2. Rock cliff texture (Triplanar projection for steep slopes)
	vec2 rock_uv_x = v_world_pos.zy * rock_uv_scale;
	vec2 rock_uv_y = v_world_pos.xz * rock_uv_scale;
	vec2 rock_uv_z = v_world_pos.xy * rock_uv_scale;
	
	vec4 rock_tex_x = texture(rock_albedo, rock_uv_x);
	vec4 rock_tex_y = texture(rock_albedo, rock_uv_y);
	vec4 rock_tex_z = texture(rock_albedo, rock_uv_z);
	vec3 rock_col = (rock_tex_x.rgb * weights.x + rock_tex_y.rgb * weights.y + rock_tex_z.rgb * weights.z);
	
	vec4 rock_nrm_x = texture(rock_normal, rock_uv_x);
	vec4 rock_nrm_y = texture(rock_normal, rock_uv_y);
	vec4 rock_nrm_z = texture(rock_normal, rock_uv_z);
	vec3 rock_norm_raw = (rock_nrm_x.rgb * weights.x + rock_nrm_y.rgb * weights.y + rock_nrm_z.rgb * weights.z);
	float rock_rough = (rock_nrm_x.a * weights.x + rock_nrm_y.a * weights.y + rock_nrm_z.a * weights.z);
	
	// 3. Contrast-preserving Height-Blending
	// Ground height stored in g_albedo_tex.a; Rock height stored in rock_tex_*.a
	float h_ground = g_albedo_tex.a;
	float h_rock = rock_tex_x.a * weights.x + rock_tex_y.a * weights.y + rock_tex_z.a * weights.z;
	float h_blend_depth = 0.18;
	float h_diff = (h_rock + rock_factor) - (h_ground + (1.0 - rock_factor));
	float blended_rock = clamp((h_diff / h_blend_depth) * 0.5 + 0.5, 0.0, 1.0);
	
	vec3 base_col = mix(ground_col, rock_col, blended_rock);
	float base_rough = mix(ground_rough, rock_rough, blended_rock);
	vec3 base_normal = mix(g_normal_tex.rgb, rock_norm_raw, blended_rock);
	
	// 4. Shoreline Sand & Capillary Wetness Blending (near waterline h < 1.8m)
	float h = v_world_pos.y;
	if (h < 1.8) {
		float sand_factor = clamp((1.8 - h) / 1.5, 0.0, 1.0) * (1.0 - blended_rock * 0.72);
		float sand_h_diff = (sand_factor + (1.0 - h_ground) * 0.35) - 0.22;
		float sand_blend = clamp(sand_h_diff / 0.20, 0.0, 1.0) * sand_factor;
		
		vec3 wet_pebble_col = mix(sand_color.rgb * 0.90, vec3(0.28, 0.24, 0.19), g_albedo_tex.r);
		if (h < 0.50) {
			float cap_wet = clamp((0.50 - h) / 0.55, 0.0, 1.0);
			wet_pebble_col = mix(wet_pebble_col, wet_pebble_col * 0.55, cap_wet);
			base_rough = mix(base_rough, 0.18, cap_wet * sand_blend);
		}
		base_col = mix(base_col, wet_pebble_col, sand_blend);
		base_rough = mix(base_rough, (h < 0.50 ? 0.18 : 0.45), sand_blend * 0.8);
	}
	
	// 5. Alpine Summit Snow Blending (elevation > 11.5m)
	if (h > 11.5) {
		float snow_factor = clamp((h - 11.5) / 2.8, 0.0, 1.0) * clamp(w_norm.y + 0.3, 0.0, 1.0);
		base_col = mix(base_col, snow_color.rgb, snow_factor);
		base_rough = mix(base_rough, 0.55, snow_factor);
	}
	
	// 6. Surface Wetness & Rain Response
	if (wetness > 0.01) {
		base_col = mix(base_col, base_col * 0.70, wetness);
		base_rough = mix(base_rough, 0.12, wetness * 0.92);
		SPECULAR = mix(0.12, 0.75, wetness);
	} else {
		SPECULAR = mix(0.12, 0.28, blended_rock);
	}
	
	ALBEDO = base_col;
	ROUGHNESS = base_rough;
	METALLIC = 0.02;
	NORMAL_MAP = base_normal;
	NORMAL_MAP_DEPTH = mix(1.45, 1.85, blended_rock);
	float h_map = mix(h_ground, h_rock, blended_rock);
	float cavity_ao = clamp(mix(0.55, 1.0, pow(h_map, 0.72)) * (g_normal_tex.b * 1.25), 0.35, 1.0);
	AO = cavity_ao;
	AO_LIGHT_AFFECT = 0.75;
}
