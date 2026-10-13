shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo_top : source_color = vec4(0.35, 0.68, 0.28, 1.0);
uniform vec4 albedo_bottom : source_color = vec4(0.18, 0.42, 0.16, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
uniform vec2 wind_dir = vec2(0.85, 0.52);
uniform float wind_speed : hint_range(0.1, 5.0) = 1.5;
uniform float wind_strength : hint_range(0.0, 2.0) = 0.35;
uniform float wetness : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height_factor = clamp(VERTEX.y, 0.0, 2.0);

	vec2 w_dir = normalize(wind_dir);
	// Wind oscillation projected along wind direction
	float wind_phase = TIME * wind_speed + dot(world_pos.xz, w_dir) * 0.45;
	float sway = sin(wind_phase) * cos(wind_phase * 0.5) * wind_strength * height_factor;

	VERTEX.x += sway * w_dir.x;
	VERTEX.z += sway * w_dir.y;
	VERTEX.y -= abs(sway) * 0.12; // Realistic downward flex under wind sway
}

void fragment() {
	// Gradient from ground to tip
	float v_gradient = clamp(UV.y, 0.0, 1.0);
	vec3 base_col = mix(albedo_top.rgb, albedo_bottom.rgb, v_gradient);

	// Wet foliage is slightly darker and specular
	ALBEDO = mix(base_col, base_col * 0.82, wetness);
	ROUGHNESS = mix(roughness, 0.22, wetness);
	SPECULAR = mix(0.15, 0.45, wetness);
}
