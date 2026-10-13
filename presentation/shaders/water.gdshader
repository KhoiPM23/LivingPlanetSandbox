shader_type spatial;
render_mode cull_back;

// Screen & Depth samplers
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

// Water Colors
uniform vec4 deep_color : source_color = vec4(0.03, 0.14, 0.28, 0.95);
uniform vec4 shallow_color : source_color = vec4(0.12, 0.58, 0.68, 0.75);
uniform vec4 foam_color : source_color = vec4(0.92, 0.98, 1.0, 1.0);

// Depth settings
uniform float depth_distance : hint_range(0.5, 20.0) = 4.0;
uniform float foam_distance : hint_range(0.05, 3.0) = 0.6;
uniform float foam_scale : hint_range(1.0, 50.0) = 16.0;

// Surface material
uniform float metallic : hint_range(0.0, 1.0) = 0.1;
uniform float roughness : hint_range(0.0, 1.0) = 0.08;

// Wave dynamics
uniform vec2 wave_dir_1 = vec2(1.0, 0.3);
uniform vec2 wave_dir_2 = vec2(-0.4, 0.9);
uniform float wave_speed_1 = 1.2;
uniform float wave_speed_2 = 0.8;
uniform float wave_amplitude = 0.25;
uniform float wave_frequency = 0.15;

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
	
	float h = 0.0;
	h += get_gerstner_wave(wave_dir_1, wave_frequency, wave_amplitude, wave_speed_1, world_pos.xz, TIME, wave_normal);
	h += get_gerstner_wave(wave_dir_2, wave_frequency * 2.1, wave_amplitude * 0.45, wave_speed_2, world_pos.xz, TIME, wave_normal);
	
	VERTEX.y += h;
	NORMAL = normalize(wave_normal);
}

void fragment() {
	// Sample depth buffer
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	
	float linear_depth = -view_pos.z;
	float vertex_depth = -VERTEX.z;
	
	// If opaque geometry is closer to camera than water surface, terrain is above waterline
	if (linear_depth < vertex_depth) {
		discard;
	}
	
	float depth_diff = linear_depth - vertex_depth;
	
	// Depth gradient factor
	float depth_factor = clamp(depth_diff / depth_distance, 0.0, 1.0);
	vec4 water_color = mix(shallow_color, deep_color, depth_factor);
	
	// Procedural foam modulation at waterlines
	vec2 foam_uv = UV * foam_scale + vec2(TIME * 0.05, TIME * 0.03);
	float foam_noise = sin(foam_uv.x * 6.0 + sin(foam_uv.y * 5.0)) * 0.5 + 0.5;
	float foam_threshold = smoothstep(foam_distance, 0.0, depth_diff + (foam_noise * 0.15 - 0.075));
	
	// Final Albedo blend
	vec3 final_rgb = mix(water_color.rgb, foam_color.rgb, foam_threshold);
	float final_alpha = mix(water_color.a, 1.0, foam_threshold);
	
	ALBEDO = final_rgb;
	ALPHA = final_alpha;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = 0.6;
}
