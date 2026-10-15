shader_type spatial;
render_mode cull_back, depth_draw_always, diffuse_burley, specular_schlick_ggx;

// High-Fidelity Mountain Lake Water Shader
// Living Planet Sandbox — Designed for Forward+ Vulkan & Intel Iris Xe

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

uniform vec4 deep_color : source_color = vec4(0.04, 0.18, 0.22, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.18, 0.48, 0.45, 1.0);
uniform vec4 foam_color : source_color = vec4(0.94, 0.98, 1.0, 1.0);

// Depth settings
uniform float depth_distance : hint_range(0.5, 20.0) = 4.5;
uniform float extinction_rate : hint_range(0.1, 3.0) = 0.75;
uniform float foam_distance : hint_range(0.02, 1.5) = 0.12;
uniform float foam_scale : hint_range(1.0, 50.0) = 24.0;

// Surface material
uniform float metallic : hint_range(0.0, 1.0) = 0.05;
uniform float roughness : hint_range(0.0, 1.0) = 0.05;

// Wave dynamics
uniform vec2 wind_dir = vec2(0.85, 0.52);
uniform float wave_speed_1 = 1.1;
uniform float wave_speed_2 = 0.75;
uniform float wave_amplitude = 0.16;
uniform float wave_frequency = 0.24;
uniform float rain_ripple_strength : hint_range(0.0, 1.0) = 0.0;

float get_gerstner_wave(vec2 dir, float freq, float amp, float speed, vec2 pos, float time, inout vec3 normal) {
	vec2 d = normalize(dir);
	float phase = freq * dot(d, pos) + speed * time;
	float sin_p = sin(phase);
	float cos_p = cos(phase);

	// Normal derivatives
	normal.x -= d.x * freq * amp * cos_p;
	normal.z -= d.y * freq * amp * cos_p;

	return amp * sin_p;
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wave_normal = vec3(0.0, 1.0, 0.0);

	vec2 primary_dir = normalize(wind_dir);
	vec2 cross_dir = normalize(vec2(primary_dir.x * 0.57 - primary_dir.y * 0.82, primary_dir.x * 0.82 + primary_dir.y * 0.57));

	float h = 0.0;
	h += get_gerstner_wave(primary_dir, wave_frequency, wave_amplitude, wave_speed_1, world_pos.xz, TIME, wave_normal);
	h += get_gerstner_wave(cross_dir, wave_frequency * 2.2, wave_amplitude * 0.4, wave_speed_2, world_pos.xz, TIME, wave_normal);

	VERTEX.y += h;
	NORMAL = normalize(wave_normal);
}

void fragment() {
	// Sample raw depth buffer
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;

	float linear_depth = -view_pos.z;
	float vertex_depth = -VERTEX.z;

	// In Vulkan Forward+ (Reversed-Z), sky pixels have raw_depth near 0.0
	bool is_sky = (raw_depth <= 0.0001 || linear_depth > 350.0 || linear_depth < 0.0);

	float depth_diff = is_sky ? depth_distance : max(linear_depth - vertex_depth, 0.0);

	// Distance-attenuated micro ripples: eliminates distant grazing moire banding
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist_fade = clamp(1.0 - (vertex_depth / 45.0), 0.0, 1.0);
	vec2 uv_w1 = world_pos.xz * 0.45 + vec2(TIME * 0.08, TIME * 0.05);
	vec2 uv_w2 = world_pos.xz * 0.85 - vec2(TIME * 0.06, TIME * 0.09);
	float mw1 = sin(uv_w1.x * 6.0 + uv_w1.y * 5.0);
	float mw2 = cos(uv_w2.x * 7.0 - uv_w2.y * 6.0);
	vec3 micro_norm = normalize(vec3(mw1 * 0.08, 1.0, mw2 * 0.08));
	NORMAL = normalize(mix(NORMAL, micro_norm, 0.32 * dist_fade));

	// Natural Beer-Lambert physical depth absorption with alpine glacial turbidity
	float depth_factor = clamp(depth_diff / depth_distance, 0.0, 1.0);
	vec3 water_tint = mix(shallow_color.rgb, deep_color.rgb, depth_factor);
	// Minimum 0.70 optical alpha ensures water has rich body and never looks like an empty dry pit
	float optical_alpha = clamp(0.70 + 0.28 * (1.0 - exp(-depth_diff * extinction_rate)), 0.70, 0.98);

	// Shoreline organic wave foam with soft gradient falloff
	float foam_strength = 0.0;
	if (!is_sky) {
		vec2 foam_uv = world_pos.xz * (foam_scale * 0.08) + vec2(TIME * 0.06, TIME * 0.04);
		float foam_noise = sin(foam_uv.x * 5.0 + sin(foam_uv.y * 4.5)) * 0.5 + 0.5;
		float foam_mask = smoothstep(foam_distance, 0.01, depth_diff) * smoothstep(0.001, 0.03, depth_diff);
		foam_strength = clamp(foam_mask * (foam_noise * 0.6 + 0.4), 0.0, 0.85);
	}

	// Fresnel effect for natural grazing angle reflectivity
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.5);

	// Rain surface ripples
	if (rain_ripple_strength > 0.01) {
		vec2 r_pos = world_pos.xz * 5.0;
		float r1 = sin(r_pos.x * 6.0 + TIME * 16.0) * cos(r_pos.y * 6.0 + TIME * 14.0);
		float r2 = sin((r_pos.x + r_pos.y) * 7.0 - TIME * 18.0);
		vec3 ripple_norm = normalize(vec3(r1 * 0.35, 1.0, r2 * 0.35));
		NORMAL = normalize(mix(NORMAL, ripple_norm, rain_ripple_strength * 0.30));
	}

	ALBEDO = mix(water_tint, foam_color.rgb, foam_strength * 0.75);
	ALPHA = mix(optical_alpha, 0.92, foam_strength * 0.65);
	METALLIC = metallic;
	ROUGHNESS = mix(roughness, 0.015, fresnel);
	SPECULAR = mix(0.55, 0.95, fresnel);
}
