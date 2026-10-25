shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley;

// Living Planet Sandbox — Underwater Marine Flora Shader (Kelp & Seagrass)
// Synchronized underwater ocean current sway, subsurface light transmission,
// and depth-attenuated aquatic coloration. Designed for Forward+ Vulkan on Intel Iris Xe.

uniform vec4 root_color : source_color = vec4(0.04, 0.18, 0.12, 1.0);
uniform vec4 tip_color : source_color = vec4(0.18, 0.48, 0.28, 1.0);
uniform float current_speed : hint_range(0.2, 4.0) = 1.35;
uniform float current_strength : hint_range(0.05, 1.5) = 0.28;
uniform vec2 current_dir = vec2(0.707, 0.707);
uniform float roughness : hint_range(0.0, 1.0) = 0.35;
uniform float plant_height : hint_range(0.5, 8.0) = 4.5;

varying float v_height_factor;
varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_height_factor = clamp((VERTEX.y + 0.1) / plant_height, 0.0, 1.0);

	vec2 c_dir = normalize(current_dir);
	// Traveling wave phase through water column
	float phase = TIME * current_speed + (v_world_pos.x * 0.25) + (v_world_pos.z * 0.25);
	// Double-harmonic fluid oscillation (stronger at the tips, zero at the rooted base)
	float sway = (sin(phase) + sin(phase * 0.48 + 1.1) * 0.45) * current_strength * (v_height_factor * v_height_factor);

	VERTEX.x += sway * c_dir.x;
	VERTEX.z += sway * c_dir.y;
	VERTEX.y -= abs(sway) * 0.12;
}

void fragment() {
	// Two-sided normal correction for thin blade cards
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;

	// Gradient from deep anchor stipe to sunlit frond tips
	vec3 col = mix(root_color.rgb, tip_color.rgb, v_height_factor);

	// Subtle water column depth darkening: deeper water absorbs red/green spectrum
	float water_depth = max(0.0, -v_world_pos.y);
	float depth_atten = clamp(1.0 - (water_depth * 0.08), 0.35, 1.0);
	col *= depth_atten;

	ALBEDO = col;
	ROUGHNESS = roughness;
	METALLIC = 0.05;
	SPECULAR = 0.45;
}
