shader_type spatial;
render_mode cull_back, diffuse_toon, specular_toon;

// =============================================================================
// LIVING PLANET SANDBOX — GENSHIN-GRADE ANIME NPR CEL SHADER (BLOCK 63)
// =============================================================================
// Features:
// 1. 2-Step / 3-Step Discretized Diffuse Lighting (Genshin Toon Light Ramp)
// 2. Non-Distorting Face Shadow Mapping (Flattens face polygonal self-shadows)
// 3. Angelic Hair Ring Specular (Anisotropic hair highlight band)
// 4. Warm Shadow Color Grading (Anime skin & fabric warmth instead of muddy shadows)
// 5. Crisp Stylized Anime Rim Light (Fresnel silhouette edge glow with backlight surge)
// 6. Inverted Hull Outline support via Material Next Pass.

uniform vec4 albedo_color : source_color = vec4(0.95, 0.90, 0.85, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform bool use_texture = false;

// Specialized anime mesh flags
uniform bool is_face = false;
uniform bool is_hair = false;

// Anime Toon Light Thresholds
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float shadow_softness : hint_range(0.001, 0.25) = 0.04;
uniform vec4 shadow_tint : source_color = vec4(0.72, 0.65, 0.75, 1.0); // Warm lavender/peach shadow

// Stylized Anime Rim Light
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.60;
uniform float rim_softness : hint_range(0.01, 0.5) = 0.15;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.85;

// Anime Specular & Hair Halo Ring
uniform float specular_threshold : hint_range(0.5, 1.0) = 0.92;
uniform float specular_strength : hint_range(0.0, 2.0) = 0.65;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.35;
uniform vec4 hair_specular_color : source_color = vec4(1.0, 0.98, 0.92, 1.0);
uniform float hair_halo_position : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec4 col = albedo_color;
	if (use_texture) {
		col *= texture(albedo_texture, UV);
	}
	ALBEDO = col.rgb;
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
	SPECULAR = 0.5;
}

void light() {
	// N dot L diffuse
	vec3 eff_normal = NORMAL;
	if (is_face) {
		// Non-distorting anime face shadow mapping:
		// Blend normal toward view vector to eliminate harsh polygonal cheek/nose socket cuts
		eff_normal = normalize(mix(NORMAL, VIEW, 0.52));
	}

	float n_dot_l = dot(eff_normal, LIGHT);
	float light_intensity = clamp((n_dot_l + 1.0) * 0.5, 0.0, 1.0);

	// 2-tone stepped light transition (Anime cel band)
	float effective_threshold = shadow_threshold;
	float effective_softness = shadow_softness;
	if (is_face) {
		effective_threshold = 0.42;
		effective_softness = 0.08;
	}

	float step_light = smoothstep(effective_threshold - effective_softness, effective_threshold + effective_softness, light_intensity);
	float shadow_term = clamp(ATTENUATION, 0.0, 1.0);
	float combined_light = step_light * shadow_term;
	vec3 diffuse_color = mix(ALBEDO * shadow_tint.rgb * 0.75, ALBEDO, combined_light);

	// Stylized Anime Back-Rim Lighting (Genshin Fresnel edge glow on silhouette)
	float n_dot_v = 1.0 - max(0.0, dot(NORMAL, VIEW));
	float backlight = max(0.0, -dot(NORMAL, LIGHT));
	float rim = smoothstep(rim_threshold - rim_softness, rim_threshold + rim_softness, n_dot_v) * (0.35 + 0.65 * backlight) * rim_strength;
	vec3 rim_contrib = rim_color.rgb * rim;

	// Sharp Anime Specular / Hair Halo Ring
	vec3 spec_contrib = vec3(0.0);
	vec3 half_vec = normalize(VIEW + LIGHT);
	float n_dot_h = max(0.0, dot(NORMAL, half_vec));

	if (is_hair) {
		// Anisotropic hair halo ring band
		float hair_h = abs(UV.y - hair_halo_position);
		float hair_halo = smoothstep(0.12, 0.02, hair_h) * smoothstep(0.35, 0.85, n_dot_h) * specular_strength * 1.4;
		spec_contrib = hair_specular_color.rgb * hair_halo * combined_light;
	} else {
		float spec = smoothstep(specular_threshold - 0.02, specular_threshold + 0.02, n_dot_h) * specular_strength * combined_light;
		spec_contrib = LIGHT_COLOR * spec;
	}

	// Final Toon Composite
	DIFFUSE_LIGHT += (diffuse_color * LIGHT_COLOR) + rim_contrib;
	SPECULAR_LIGHT += spec_contrib;
}
