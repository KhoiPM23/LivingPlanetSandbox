shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

// High-fidelity natural foliage shader with two-sided normal correction,
// synchronized wind sway, surface wetness sheen, and selective subsurface transmission.
// Enforces depth_draw_opaque to guarantee solid silhouettes without see-through voids or sorting artifacts.

uniform vec4 albedo_top : source_color = vec4(0.26, 0.48, 0.20, 1.0);
uniform vec4 albedo_bottom : source_color = vec4(0.14, 0.34, 0.12, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform bool use_texture = false;
uniform bool use_vertex_color = false;
uniform bool use_alpha_scissor = false;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;

uniform sampler2D normal_texture : hint_roughness_normal, filter_linear_mipmap;
uniform bool use_normal_texture = false;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;

uniform sampler2D roughness_texture : hint_roughness_r, filter_linear_mipmap;
uniform bool use_roughness_texture = false;

uniform float roughness : hint_range(0.0, 1.0) = 0.76;
uniform vec2 wind_dir = vec2(0.85, 0.52);
uniform float wind_speed : hint_range(0.1, 5.0) = 1.4;
uniform float wind_strength : hint_range(0.0, 2.0) = 0.25;
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform float backlight_strength : hint_range(0.0, 1.0) = 0.0;

uniform float blade_height : hint_range(0.05, 2.0) = 0.14;

varying vec3 v_local_pos;
varying float v_blade_height;

void vertex() {
	v_local_pos = VERTEX;
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height_factor = clamp((VERTEX.y + 0.05) / blade_height, 0.0, 2.0);

	// Grass height along blade normalized to actual mesh geometry bounds
	v_blade_height = clamp((VERTEX.y + 0.05) / blade_height, 0.0, 1.0);

	vec2 w_dir = normalize(wind_dir);
	// Spatial traveling wave offset: prevents uniform unison shaking across the island
	float wave_offset = dot(world_pos.xz, w_dir) * 0.32;
	float gust_wave = sin(world_pos.x * 0.07 + world_pos.z * 0.04 + TIME * 0.6) * 0.28 + 0.72;
	float wind_phase = TIME * wind_speed + wave_offset;
	// Organic dual-frequency sway with gust variation
	float sway = (sin(wind_phase) + sin(wind_phase * 0.45 + 1.25) * 0.35) * wind_strength * height_factor * gust_wave;

	VERTEX.x += sway * w_dir.x;
	VERTEX.z += sway * w_dir.y;
	VERTEX.y -= abs(sway) * 0.06; // Subtle natural vertical flex under heavy wind sway
}

void fragment() {
	// Two-sided normal correction: Invert normal for backfaces when cull_disabled is active
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;

	vec3 base_col;
	float base_alpha = 1.0;

	if (use_texture) {
		vec4 tex = texture(albedo_texture, UV);
		base_col = tex.rgb;
		base_alpha = tex.a;
	} else if (use_vertex_color) {
		base_col = COLOR.rgb;
	} else {
		// Procedural ground-to-tip gradient for grass blades based on actual vertex height
		base_col = mix(albedo_bottom.rgb, albedo_top.rgb, v_blade_height);
	}

	if (use_alpha_scissor) {
		ALPHA = base_alpha;
		ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	}

	float base_roughness = roughness;
	if (use_roughness_texture) {
		base_roughness = texture(roughness_texture, UV).r * roughness;
	}
	if (use_normal_texture) {
		NORMAL_MAP = texture(normal_texture, UV).xyz;
		NORMAL_MAP_DEPTH = normal_scale;
	}

	// Surface wetness reaction: wet foliage is darker with specular sheen
	ALBEDO = mix(base_col, base_col * 0.78, wetness);
	ROUGHNESS = mix(base_roughness, 0.18, wetness);
	SPECULAR = mix(0.15, 0.50, wetness);

	if (!use_texture && !use_vertex_color) {
		// Grass enhancements:
		// 1. Soften blade normals towards true world UP in view space (eliminates harsh low-poly faceted edges)
		vec3 world_up_in_view = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
		NORMAL = normalize(mix(NORMAL, world_up_in_view, 0.70));

		// 2. Ground-contact ambient occlusion: subtle darkening at base, preserving vitality
		float root_ao = mix(0.82, 1.0, smoothstep(0.0, 0.35, v_blade_height));
		AO = root_ao;
		AO_LIGHT_AFFECT = 0.45;
	} else {
		// Tree & canopy enhancements (KayKit textured & Kenney vertex-colored):
		bool is_canopy = (base_col.g > base_col.r * 1.05 && base_col.g > base_col.b);
		if (is_canopy) {
			// Shelf / tier self-occlusion: underside of foliage tiers is in contact shadow
			float shelf_ao = clamp(0.52 + 0.48 * smoothstep(-0.55, 0.45, NORMAL.y), 0.48, 1.0);

			// Radial core occlusion: inner canopy closer to trunk is deeper
			float radial_dist = length(v_local_pos.xz);
			float core_ao = clamp(0.68 + 0.32 * smoothstep(0.15, 1.25, radial_dist), 0.65, 1.0);

			// Vertical crown gradient: sunlit canopy top is bright, lower tiers richer
			float crown_lum = mix(0.86, 1.06, clamp((v_local_pos.y - 0.8) / 3.8, 0.0, 1.0));

			float canopy_ao = shelf_ao * core_ao;
			AO = canopy_ao;
			AO_LIGHT_AFFECT = 0.65;

			// Subtle albedo modulation for volumetric tier separation
			ALBEDO = ALBEDO * crown_lum * mix(vec3(0.84, 0.88, 0.82), vec3(1.0), core_ao);

			// Volumetric spherical normal softening to round out faceted low-poly clumps
			vec3 canopy_center = vec3(0.0, 2.6, 0.0);
			vec3 radial_norm = normalize(v_local_pos - canopy_center);
			NORMAL = normalize(mix(NORMAL, radial_norm, 0.25));
		}
	}

	// Controlled subsurface backlight transmission (disabled for solid trees, subtle for grass)
	if (backlight_strength > 0.001) {
		vec3 sss_color = mix(vec3(0.12, 0.22, 0.08), vec3(0.02), wetness);
		BACKLIGHT = sss_color * backlight_strength;
	} else {
		BACKLIGHT = vec3(0.0);
	}
}
