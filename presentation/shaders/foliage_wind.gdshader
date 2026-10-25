shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

// High-fidelity natural foliage shader with two-sided normal correction,
// synchronized wind sway, surface wetness sheen, and selective subsurface transmission.
// Enforces depth_draw_opaque to guarantee solid silhouettes without see-through voids or sorting artifacts.

uniform vec4 albedo_top : source_color = vec4(0.42, 0.76, 0.26, 1.0);
uniform vec4 albedo_bottom : source_color = vec4(0.24, 0.46, 0.18, 1.0);
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
uniform float backlight_strength : hint_range(0.0, 1.0) = 0.40;

uniform float blade_height : hint_range(0.05, 2.0) = 0.14;
uniform float max_draw_distance : hint_range(0.0, 500.0) = 0.0;

// Interactive Actor Trampling & Foliage Parting (Zelda BotW & RDR2 Feel)
uniform vec3 player_pos = vec3(0.0);
uniform float player_radius : hint_range(0.5, 4.0) = 1.45;
uniform float player_push_strength : hint_range(0.0, 2.0) = 0.65;

// Seasonal phenology uniforms
uniform vec3 season_tint = vec3(1.0, 1.0, 1.0);
uniform float season_tint_weight : hint_range(0.0, 1.0) = 0.0;
uniform float frost_amount : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_local_pos;
varying float v_blade_height;
varying float v_field_wave;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float fade = 1.0;

	v_local_pos = VERTEX;
	float height_factor = clamp((VERTEX.y + 0.05) / blade_height, 0.0, 2.0);

	// Grass height along blade normalized to actual mesh geometry bounds
	v_blade_height = clamp((VERTEX.y + 0.05) / blade_height, 0.0, 1.0);

	vec2 w_dir1 = normalize(wind_dir);
	vec2 w_dir2 = normalize(vec2(-w_dir1.y * 0.45 + w_dir1.x * 0.89, w_dir1.x * 0.45 + w_dir1.y * 0.89));
	
	// Spatial traveling wave offset: prevents uniform unison shaking across the island
	float wave_offset = dot(world_pos.xz, w_dir1) * 0.28;
	float gust_wave = sin(world_pos.x * 0.065 + world_pos.z * 0.042 + TIME * 0.55) * 0.25 + 0.75;
	float wind_phase = TIME * wind_speed + wave_offset;

	// Multi-Octave Curvilinear Wind Swirls across meadow plains (Genshin / Ghibli rolling sea of grass)
	float wave1 = sin(dot(world_pos.xz, w_dir1) * 0.11 - TIME * wind_speed * 1.45);
	float wave2 = sin(dot(world_pos.xz, w_dir2) * 0.17 - TIME * wind_speed * 1.85 + 1.25);
	float field_wave = clamp((wave1 * 0.55 + wave2 * 0.45) * 0.5 + 0.5, 0.0, 1.0);
	v_field_wave = field_wave;

	// Organic dual-frequency sway with gust variation and field wave surge
	float sway = (sin(wind_phase) * 0.65 + wave2 * 0.35 + field_wave * 0.45) * wind_strength * height_factor * gust_wave * fade;

	VERTEX.x += sway * w_dir1.x;
	VERTEX.z += sway * w_dir1.y;
	VERTEX.y -= abs(sway) * 0.05;

	// Interactive Foliage Trampling with smooth quadratic damping
	vec3 to_player = world_pos - player_pos;
	to_player.y = 0.0;
	float dist_to_player = length(to_player);
	if (dist_to_player < player_radius && dist_to_player > 0.001) {
		float norm_dist = dist_to_player / player_radius;
		float push_curve = 1.0 - (norm_dist * norm_dist);
		float push_factor = push_curve * height_factor;
		vec3 push_dir = normalize(to_player);
		VERTEX.x += push_dir.x * push_factor * player_push_strength;
		VERTEX.z += push_dir.z * push_factor * player_push_strength;
		VERTEX.y -= push_factor * 0.18;
	}

	// Minecraft-shader style gentle leaf flutter on branch cards and canopy foliage
	if (use_alpha_scissor || use_texture) {
		float leaf_flutter = sin(wind_phase * 2.2 + world_pos.x * 1.4 + world_pos.z * 1.1) * 0.026 * wind_strength;
		float leaf_lift = cos(wind_phase * 1.6 + world_pos.y * 1.8) * 0.016 * wind_strength;
		VERTEX.x += leaf_flutter * w_dir1.y;
		VERTEX.z += leaf_flutter * w_dir1.x;
		VERTEX.y += leaf_lift;
	}
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

	// Seasonal Phenology Modulation
	if (season_tint_weight > 0.001) {
		base_col = mix(base_col, base_col * season_tint, season_tint_weight);
	}
	if (frost_amount > 0.001) {
		float rime = clamp((NORMAL.y - 0.15) * 1.6, 0.0, 1.0) * frost_amount;
		base_col = mix(base_col, vec3(0.86, 0.93, 1.0), rime * 0.75);
		base_roughness = mix(base_roughness, 0.45, rime);
	}

	// Surface wetness reaction: wet foliage is darker with specular sheen
	ALBEDO = mix(base_col, base_col * 0.78, wetness);
	ROUGHNESS = mix(base_roughness, 0.18, wetness);
	SPECULAR = mix(0.15, 0.50, wetness);

	if (!use_texture && !use_vertex_color) {
		// Grass enhancements:
		// 1. Genshin/Ghost of Tsushima rolling field wind wave sunlight modulation
		vec3 wave_shimmer = mix(vec3(1.0), vec3(1.18, 1.30, 1.06), v_field_wave * v_blade_height * 0.85);
		ALBEDO = ALBEDO * wave_shimmer;

		// 2. Soften blade normals towards true world UP in view space (eliminates harsh low-poly faceted edges)
		vec3 world_up_in_view = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
		NORMAL = normalize(mix(NORMAL, world_up_in_view, 0.72));

		// 3. Ground-contact ambient occlusion: subtle darkening at base, preserving vitality
		float root_ao = mix(0.80, 1.0, smoothstep(0.0, 0.35, v_blade_height));
		AO = root_ao;
		AO_LIGHT_AFFECT = 0.45;

		// 4. Chlorophyll Subsurface Backlight Transmission (Warm glow against the sun)
		BACKLIGHT = vec3(0.38, 0.70, 0.18) * backlight_strength * (0.40 + 0.60 * v_field_wave);
	} else {
		// Tree & canopy enhancements (KayKit textured & Kenney vertex-colored):
		bool is_canopy = (base_col.g > base_col.r * 1.05 && base_col.g > base_col.b);
		if (is_canopy) {
			BACKLIGHT = vec3(0.34, 0.64, 0.16) * backlight_strength * 0.75;
		}
			// Shelf / tier self-occlusion: underside of foliage tiers is in contact shadow (using world normal Y)
			float world_norm_y = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y;
			float shelf_ao = clamp(0.52 + 0.48 * smoothstep(-0.55, 0.45, world_norm_y), 0.48, 1.0);

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

			// Volumetric spherical normal softening to round out faceted low-poly clumps (transformed to View space)
			vec3 canopy_center = vec3(0.0, 2.6, 0.0);
			vec3 radial_norm_local = normalize(v_local_pos - canopy_center);
			vec3 radial_norm_view = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(radial_norm_local, 0.0)).xyz);
			NORMAL = normalize(mix(NORMAL, radial_norm_view, 0.25));
	}
}
