shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Living Planet Sandbox — Marine Fish Locomotion & Iridescent Scales Shader
// Procedural spine undulation and tail wagging synchronized to swim speed.
// Tail wags relative to head (-Z forward, +Z tail).

uniform vec4 body_color_top : source_color = vec4(0.12, 0.38, 0.62, 1.0);
uniform vec4 body_color_bottom : source_color = vec4(0.85, 0.92, 0.96, 1.0);
uniform vec4 fin_accent_color : source_color = vec4(0.95, 0.65, 0.22, 1.0);
uniform float swim_speed : hint_range(1.0, 15.0) = 5.5;
uniform float wag_amplitude : hint_range(0.01, 0.35) = 0.14;
uniform float scale_iridescence : hint_range(0.0, 1.0) = 0.65;
uniform float roughness : hint_range(0.0, 1.0) = 0.22;

varying vec3 v_local_pos;
varying float v_tail_factor;

void vertex() {
	v_local_pos = VERTEX;
	// Local forward is -Z (head), local back is +Z (tail)
	// Tail factor: 0.0 at head/gills (Z <= 0.0), smoothly rising to 1.0 at tail fin (Z > 0.0)
	v_tail_factor = smoothstep(-0.15, 0.55, VERTEX.z);

	// Organic sinusoidal spinal traveling wave: waves travel backwards along the fish body
	float wave_phase = (TIME * swim_speed) - (VERTEX.z * 4.2);
	float lateral_offset = sin(wave_phase) * wag_amplitude * v_tail_factor;

	// Apply lateral tail wagging to X axis
	VERTEX.x += lateral_offset;

	// Subtle secondary roll on tail fin during fast strokes
	float roll_angle = cos(wave_phase) * wag_amplitude * 0.45 * v_tail_factor;
	VERTEX.y += roll_angle * VERTEX.x;
}

void fragment() {
	// Counter-shading: darker dorsal top, silvery-white ventral belly
	float dorsal_factor = clamp((v_local_pos.y + 0.12) / 0.25, 0.0, 1.0);
	vec3 base_col = mix(body_color_bottom.rgb, body_color_top.rgb, dorsal_factor);

	// Fin tip accent
	if (v_tail_factor > 0.72) {
		base_col = mix(base_col, fin_accent_color.rgb, (v_tail_factor - 0.72) / 0.28);
	}

	// Dynamic angle-dependent iridescence (pearlescent scale shimmer)
	float view_angle = 1.0 - max(0.0, dot(NORMAL, VIEW));
	vec3 irid_tint = vec3(0.3, 0.8, 0.9) * pow(view_angle, 2.5) * scale_iridescence;

	ALBEDO = base_col + irid_tint;
	METALLIC = 0.42;
	ROUGHNESS = roughness;
	SPECULAR = 0.65;
}
