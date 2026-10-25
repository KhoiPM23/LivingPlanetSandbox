shader_type spatial;
render_mode cull_front, depth_draw_always;

// =============================================================================
// LIVING PLANET SANDBOX — GENSHIN-STYLE INVERTED HULL ANIME OUTLINE PASS
// =============================================================================
// Features:
// - Pushes vertices along normals outward and renders front-culled backfaces in dark outline ink.
// - Distance-compensated outline width so ink lines remain crisp and consistent from close-up to mid-range.

uniform vec4 outline_color : source_color = vec4(0.18, 0.12, 0.22, 1.0); // Stylized deep plum/charcoal ink
uniform float outline_width : hint_range(0.001, 0.05) = 0.006;

void vertex() {
	// Push along vertex normal with distance compensation
	float dist_factor = clamp(length(VERTEX) * 0.35, 0.85, 1.65);
	VERTEX += NORMAL * (outline_width * dist_factor);
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
