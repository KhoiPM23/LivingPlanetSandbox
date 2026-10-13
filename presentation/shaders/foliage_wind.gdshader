shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo_top : source_color = vec4(0.35, 0.68, 0.28, 1.0);
uniform vec4 albedo_bottom : source_color = vec4(0.18, 0.42, 0.16, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
uniform float wind_speed : hint_range(0.1, 5.0) = 1.5;
uniform float wind_strength : hint_range(0.0, 2.0) = 0.35;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height_factor = clamp(VERTEX.y, 0.0, 2.0);
	
	// Wind oscillation based on world position and vertex height
	float wind_phase = TIME * wind_speed + world_pos.x * 0.4 + world_pos.z * 0.3;
	float sway = sin(wind_phase) * cos(wind_phase * 0.5) * wind_strength * height_factor;
	
	VERTEX.x += sway;
	VERTEX.z += sway * 0.5;
}

void fragment() {
	// Gradient from ground to tip
	float v_gradient = clamp(UV.y, 0.0, 1.0);
	ALBEDO = mix(albedo_top.rgb, albedo_bottom.rgb, v_gradient);
	ROUGHNESS = roughness;
	SPECULAR = 0.15;
}
