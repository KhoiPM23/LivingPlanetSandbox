shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Terrain Triplanar PBR Shader with Slope Blending & Biome Vertex Modulation
// Living Planet Sandbox — Designed for Intel Iris Xe & Vulkan Forward+

uniform sampler2D ground_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic;

uniform float uv_scale : hint_range(0.01, 1.0) = 0.14;
uniform float rock_uv_scale : hint_range(0.01, 1.0) = 0.08;
uniform float slope_threshold : hint_range(0.1, 0.9) = 0.26;
uniform float slope_blend : hint_range(0.02, 0.5) = 0.12;

uniform vec4 sand_color : source_color = vec4(0.85, 0.78, 0.60, 1.0);
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
	
	// 1. Ground texture (planar XZ projection)
	vec2 ground_uv = v_world_pos.xz * uv_scale;
	vec4 g_albedo_tex = texture(ground_albedo, ground_uv);
	vec4 g_normal_tex = texture(ground_normal, ground_uv);
	
	// Natural biome modulation preserving photographic soil & pebble details
	vec3 biome_tint = mix(vec3(1.0), v_vertex_color.rgb * 1.35, 0.28);
	vec3 ground_col = g_albedo_tex.rgb * biome_tint;
	float ground_rough = mix(0.85, g_normal_tex.a, 0.70);
	
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
	
	// 3. Blend Ground and Rock
	vec3 base_col = mix(ground_col, rock_col, rock_factor);
	float base_rough = mix(ground_rough, rock_rough, rock_factor);
	
	// Normal vector blending
	vec3 base_normal = mix(g_normal_tex.rgb, rock_norm_raw, rock_factor);
	
	// 4. Shoreline Sand Blending (near waterline h < 1.6m)
	float h = v_world_pos.y;
	if (h < 1.6) {
		float sand_factor = clamp((1.6 - h) / 1.3, 0.0, 1.0) * (1.0 - rock_factor * 0.7);
		base_col = mix(base_col, sand_color.rgb * (g_albedo_tex.rgb * 0.75 + 0.35), sand_factor);
		base_rough = mix(base_rough, 0.65, sand_factor);
	}
	
	// 5. Alpine Summit Snow Blending (elevation > 11.5m)
	if (h > 11.5) {
		float snow_factor = clamp((h - 11.5) / 2.8, 0.0, 1.0) * clamp(w_norm.y + 0.3, 0.0, 1.0);
		base_col = mix(base_col, snow_color.rgb, snow_factor);
		base_rough = mix(base_rough, 0.55, snow_factor);
	}
	
	// 6. Surface Wetness & Rain Response
	if (wetness > 0.01) {
		base_col = mix(base_col, base_col * 0.76, wetness);
		base_rough = mix(base_rough, 0.16, wetness * 0.85);
		SPECULAR = mix(0.12, 0.65, wetness);
	} else {
		SPECULAR = mix(0.12, 0.25, rock_factor);
	}
	
	ALBEDO = base_col;
	ROUGHNESS = base_rough;
	METALLIC = 0.02;
	NORMAL_MAP = base_normal;
	NORMAL_MAP_DEPTH = mix(1.1, 1.6, rock_factor);
}
