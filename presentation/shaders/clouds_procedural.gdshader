shader_type spatial;
render_mode unshaded, blend_mix, cull_front, depth_draw_never;

// =============================================================================
// LIVING PLANET SANDBOX — CELESTIAL SKY, SUN, MOON, STARS & CLOUD DOME SHADER
// =============================================================================
// High-fidelity procedural atmosphere and celestial sphere:
// 1. Atmospheric Rayleigh & Mie scattering gradient with seamless horizon haze
// 2. Physical Solar Disc with limb darkening, sunset refraction, and luminous corona
// 3. Physical Lunar Disc with procedural maria, craters, terminator phase & earthshine
// 4. 3D Spherical Starfield with magnitude variation, twinkle, and Milky Way galactic band
// 5. Layered Multi-scale Animated Clouds (drifting cumulus + wispy cirrus) coupled to Weather
// Designed for steady 30+ FPS Forward+ Vulkan on Intel Iris Xe Graphics.

// Weather & Diurnal uniforms
uniform float day_factor : hint_range(0.0, 1.0) = 1.0;
uniform float golden_factor : hint_range(0.0, 1.0) = 0.0;
uniform float twilight_factor : hint_range(0.0, 1.0) = 0.0;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.25;
uniform float rain_factor : hint_range(0.0, 1.0) = 0.0;

// Celestial vectors
uniform vec3 sun_dir = vec3(0.45, 0.75, 0.35);
uniform vec3 moon_dir = vec3(-0.45, 0.75, -0.35);
uniform float moon_phase : hint_range(0.0, 1.0) = 0.50; // 0.0=New, 0.25=First Quarter, 0.5=Full, 0.75=Last Quarter

// Wind dynamics
uniform vec2 wind_dir = vec2(0.85, 0.52);
uniform float wind_speed : hint_range(0.1, 10.0) = 1.5;

// Color palettes
uniform vec3 cloud_color_day : source_color = vec3(0.96, 0.98, 1.0);
uniform vec3 cloud_color_shadow : source_color = vec3(0.44, 0.50, 0.62);
uniform vec3 cloud_color_golden : source_color = vec3(1.0, 0.62, 0.28);
uniform vec3 cloud_color_night : source_color = vec3(0.08, 0.12, 0.20);
uniform vec3 moon_disc_color : source_color = vec3(0.94, 0.96, 1.0);

// --- PROCEDURAL HASH & NOISE FUNCTIONS ---
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p3) {
	p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yxz + 33.33);
	return fract((p3.xxy + p3.yxx) * p3.zyx);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm2d(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8));
	for (int i = 0; i < 4; i++) {
		val += amp * noise2d(p);
		p = rot * p * 2.02;
		amp *= 0.5;
	}
	return val;
}

float fbm2d_3(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8));
	for (int i = 0; i < 3; i++) {
		val += amp * noise2d(p);
		p = rot * p * 2.02;
		amp *= 0.5;
	}
	return val;
}

float fbm2d_2(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8));
	for (int i = 0; i < 2; i++) {
		val += amp * noise2d(p);
		p = rot * p * 2.02;
		amp *= 0.5;
	}
	return val;
}

// 3D noise for celestial features & maria
float noise3d(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
	float x00 = mix(n000, n100, f.x);
	float x10 = mix(n010, n110, f.x);
	float x01 = mix(n001, n101, f.x);
	float x11 = mix(n011, n111, f.x);
	float y0 = mix(x00, x10, f.y);
	float y1 = mix(x01, x11, f.y);
	return mix(y0, y1, f.z);
}

void fragment() {
	vec3 view_dir = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 0.0)).xyz);
	float up = clamp(view_dir.y, -0.05, 1.0);
	float up_pos = max(0.0, up);

	vec3 s_dir = normalize(sun_dir);
	vec3 m_dir = normalize(moon_dir);

	float sun_dot = dot(view_dir, s_dir);
	float moon_dot = dot(view_dir, m_dir);

	// =========================================================================
	// 1. ATMOSPHERIC RAYLEIGH & MIE SCATTERING SKY GRADIENT
	// =========================================================================
	// Palette definitions across diurnal states
	vec3 day_zenith = vec3(0.09, 0.32, 0.72);
	vec3 day_horizon = vec3(0.52, 0.68, 0.88);

	vec3 golden_zenith = vec3(0.08, 0.14, 0.38);
	vec3 golden_mid = vec3(0.72, 0.36, 0.32);
	vec3 golden_horizon = vec3(0.96, 0.54, 0.20);

	vec3 twilight_zenith = vec3(0.05, 0.08, 0.22);
	vec3 twilight_horizon = vec3(0.42, 0.20, 0.28);

	vec3 night_zenith = vec3(0.008, 0.015, 0.04);
	vec3 night_horizon = vec3(0.035, 0.065, 0.12);

	vec3 storm_zenith = vec3(0.14, 0.18, 0.24);
	vec3 storm_horizon = vec3(0.36, 0.40, 0.46);

	// Diurnal sky gradient calculation
	float h_weight = pow(clamp(1.0 - up_pos, 0.0, 1.0), 1.6);

	vec3 day_sky = mix(day_zenith, day_horizon, h_weight);
	vec3 golden_sky = mix(golden_zenith, mix(golden_mid, golden_horizon, h_weight), h_weight);
	vec3 twilight_sky = mix(twilight_zenith, twilight_horizon, h_weight);
	vec3 night_sky = mix(night_zenith, night_horizon, h_weight);

	// Blend diurnal states smoothly
	vec3 sky_base = mix(night_sky, day_sky, day_factor);
	if (golden_factor > 0.01) {
		sky_base = mix(sky_base, golden_sky, golden_factor * 0.85);
	}
	if (twilight_factor > 0.01) {
		sky_base = mix(sky_base, twilight_sky, twilight_factor * 0.70);
	}
	// Storm / Rain overcast sky blending
	if (rain_factor > 0.02) {
		vec3 storm_sky = mix(storm_zenith, storm_horizon, h_weight);
		sky_base = mix(sky_base, storm_sky, rain_factor * 0.88);
	}

	// Forward atmospheric scattering glow towards sun
	float sun_fwd = max(0.0, sun_dot);
	float mie_glow = pow(sun_fwd, 18.0) * (0.35 + golden_factor * 0.45) * day_factor;
	vec3 mie_color = mix(vec3(1.0, 0.95, 0.85), vec3(1.0, 0.65, 0.28), golden_factor);
	sky_base += mie_color * mie_glow;

	// =========================================================================
	// 2. THE SUN (Crisp Disc, Atmospheric Flattening & Luminous Corona)
	// =========================================================================
	float sun_disc = 0.0;
	float sun_corona = 0.0;
	vec3 sun_radiance = vec3(0.0);

	if (s_dir.y > -0.06 && day_factor > 0.04) {
		// Atmospheric vertical refraction compression near horizon
		vec3 s_diff = view_dir - s_dir;
		if (s_dir.y < 0.15) {
			s_diff.y *= (1.0 + (0.15 - max(0.0, s_dir.y)) * 1.8);
		}
		float s_ang = length(s_diff);

		// Solar angular radius: ~0.030 rad (~1.7 degrees - cinematic scale)
		if (s_ang < 0.038) {
			float disc_edge = smoothstep(0.030, 0.022, s_ang);
			float limb_darkening = 0.85 + 0.15 * sqrt(clamp(1.0 - (s_ang / 0.030), 0.0, 1.0));
			sun_disc = disc_edge * limb_darkening * min(1.0, (s_dir.y + 0.06) * 12.0);
		}

		// Silky-smooth continuous solar corona with zero sharp boundary steps (pure natural exponential falloff)
		float s_forward = max(0.0, sun_dot);
		float c_inner = pow(s_forward, 220.0) * 2.2;
		float c_outer = pow(s_forward, 45.0) * 0.42;
		sun_corona = (c_inner + c_outer) * min(1.0, (s_dir.y + 0.05) * 8.0);

		vec3 core_color = mix(vec3(1.0, 0.98, 0.92) * 3.2, vec3(1.0, 0.55, 0.18) * 2.8, golden_factor);
		vec3 halo_color = mix(vec3(1.0, 0.92, 0.78), vec3(1.0, 0.65, 0.25), golden_factor);
		sun_radiance = core_color * sun_disc + halo_color * sun_corona;
	}

	// =========================================================================
	// 3. THE MOON (Surface Maria, Craters, Phase Terminator & Earthshine)
	// =========================================================================
	float moon_disc = 0.0;
	vec3 moon_radiance = vec3(0.0);
	float moon_alpha_out = 0.0;

	if (m_dir.y > -0.04 && day_factor < 0.55) {
		vec3 m_diff = view_dir - m_dir;
		float m_ang = length(m_diff);

		// Lunar angular radius: ~0.040 rad (~2.3 degrees - cinematic open-world scale)
		if (m_ang < 0.048) {
			float m_edge = smoothstep(0.040, 0.034, m_ang);

			// Compute spherical tangent coordinates on lunar disc
			vec3 m_up = normalize(cross(m_dir, vec3(0.0, 1.0, 0.0)));
			vec3 m_right = cross(m_dir, m_up);
			vec2 m_plane = vec2(dot(m_diff, m_right), dot(m_diff, m_up)) / 0.040;
			float r_sq = dot(m_plane, m_plane);

			if (r_sq <= 1.0) {
				float z_sphere = sqrt(1.0 - r_sq);
				vec3 m_norm = normalize(vec3(m_plane.x, m_plane.y, z_sphere));

				// Procedural lunar maria (dark volcanic plains)
				float maria_n1 = noise3d(m_norm * 3.2);
				float maria_n2 = noise3d(m_norm * 6.5 + vec3(1.2, 3.4, 5.6));
				float maria = smoothstep(0.38, 0.68, maria_n1 * 0.65 + maria_n2 * 0.35);

				// Procedural ray craters
				float crater = smoothstep(0.72, 0.88, noise3d(m_norm * 14.0));
				vec3 surface_albedo = mix(vec3(0.82, 0.85, 0.90), vec3(0.42, 0.44, 0.48), maria) + vec3(0.12) * crater;

				// Lunar phase terminator illumination
				// moon_phase: 0.0 = New, 0.25 = First Quarter, 0.50 = Full, 0.75 = Last Quarter
				float phase_rad = moon_phase * TAU;
				vec3 light_dir_moon = normalize(vec3(sin(phase_rad), 0.0, cos(phase_rad)));
				float illum = clamp(dot(m_norm, light_dir_moon) * 1.5 + 0.12, 0.0, 1.0);

				// Earthshine on unlit portion of the moon
				vec3 earthshine = vec3(0.06, 0.09, 0.15);
				vec3 moon_lit = surface_albedo * illum * 2.2;
				vec3 moon_unlit = surface_albedo * earthshine;

				moon_disc = m_edge;
				float night_fade = clamp((0.45 - day_factor) / 0.45, 0.0, 1.0) * min(1.0, (m_dir.y + 0.04) * 12.0);
				moon_radiance = (moon_lit + moon_unlit) * moon_disc_color;
				moon_alpha_out = moon_disc * night_fade;
			}
		}

		// Silky-smooth lunar atmospheric halo with zero boundary step
		float m_forward = max(0.0, moon_dot);
		float m_halo = pow(m_forward, 78.0) * 0.32 * clamp((0.35 - day_factor) / 0.35, 0.0, 1.0);
		sky_base += moon_disc_color * m_halo;
	}

	// =========================================================================
	// 4. 3D SPHERICAL STARFIELD & MILKY WAY GALACTIC BAND
	// =========================================================================
	float star_lum = 0.0;
	vec3 star_color = vec3(0.92, 0.95, 1.0);
	vec3 milky_way = vec3(0.0);

	if (day_factor < 0.35 && up_pos > 0.02) {
		float night_stars_weight = clamp((0.32 - day_factor) / 0.30, 0.0, 1.0);
		// Atmospheric extinction near horizon (stars fade in bottom 6 degrees)
		float atmos_extinct = smoothstep(0.02, 0.16, up_pos);

		// 3D Spherical Voronoi star distribution (no polar distortion)
		vec3 star_sp = view_dir * 115.0;
		vec3 star_cell = floor(star_sp);
		vec3 star_rnd = hash33(star_cell);

		if (star_rnd.x > 0.76) {
			vec3 star_pt = star_cell + star_rnd;
			float d_star = length(star_sp - star_pt);

			// Magnitude variation: 1st, 2nd, 3rd magnitude stars
			float mag = star_rnd.y;
			float star_radius = 0.28;
			float star_bright = 1.0;
			if (mag > 0.95) {
				// Hero 1st magnitude star with subtle diffraction spike
				star_radius = 0.45;
				star_bright = 2.6;
				// Stellar spectral classification
				if (star_rnd.z < 0.25) {
					star_color = vec3(0.75, 0.88, 1.0); // Hot Blue-white O/B
				} else if (star_rnd.z < 0.65) {
					star_color = vec3(1.0, 0.96, 0.88); // Solar Yellow G
				} else {
					star_color = vec3(1.0, 0.68, 0.52); // Red Supergiant M
				}
			} else if (mag > 0.85) {
				star_radius = 0.34;
				star_bright = 1.8;
			}

			// Subtle twinkling animation
			float twinkle = 0.75 + 0.25 * sin(TIME * (2.0 + star_rnd.x * 4.0) + star_rnd.y * 62.0);
			star_lum = smoothstep(star_radius, 0.02, d_star) * star_bright * twinkle * night_stars_weight * atmos_extinct;
		}

		// Milky Way Galactic Band across celestial sphere
		// Galactic pole tilted at ~62 degrees to world axis
		vec3 gal_pole = normalize(vec3(0.55, 0.72, 0.42));
		float gal_dist = abs(dot(view_dir, gal_pole));

		if (gal_dist < 0.42) {
			float band_profile = smoothstep(0.42, 0.04, gal_dist);
			// 3D noise dust rifts and star cloud density
			float dust_n = noise3d(view_dir * 4.8);
			float cloud_n = noise3d(view_dir * 9.2 + vec3(2.1, 4.3, 1.5));
			float mw_intensity = band_profile * (0.65 + 0.35 * cloud_n) * smoothstep(0.25, 0.85, dust_n);

			vec3 mw_color = mix(vec3(0.12, 0.16, 0.26), vec3(0.24, 0.28, 0.42), cloud_n);
			milky_way = mw_color * mw_intensity * 0.90 * night_stars_weight * atmos_extinct;
		}
	}

	// =========================================================================
	// 4b. AURORA BOREALIS (Northern Polar Curtains) & SHOOTING STARS
	// =========================================================================
	vec3 aurora = vec3(0.0);
	vec3 shooting_star = vec3(0.0);

	if (day_factor < 0.35 && up_pos > 0.04) {
		float night_wt = clamp((0.32 - day_factor) / 0.30, 0.0, 1.0) * (1.0 - rain_factor * 0.85);

		// Aurora Ribbons active in northern night hemisphere (-Z world axis)
		if (view_dir.z < 0.35) {
			// Transform coordinates along polar magnetic arc
			float theta = atan(view_dir.x, -view_dir.z); // Northern azimuth centered at -Z
			float alt = up_pos;

			// Undulating magnetic curtains with multi-frequency waves
			float wave1 = sin(theta * 4.5 + TIME * 0.32) * 0.08 + sin(theta * 11.0 - TIME * 0.55) * 0.035;
			float wave2 = cos(theta * 6.5 - TIME * 0.25) * 0.07 + sin(theta * 14.0 + TIME * 0.45) * 0.025;

			// Curtain A: Primary Emerald Ribbon (altitude 0.14 - 0.48)
			float curt1_base = 0.14 + wave1;
			float d_curt1 = alt - curt1_base;
			if (d_curt1 > 0.0 && d_curt1 < 0.36) {
				float v1 = d_curt1 / 0.36;
				float rays1 = noise2d(vec2(theta * 36.0 + TIME * 0.06, v1 * 10.0));
				float ray_struct1 = 0.55 + 0.45 * sin(theta * 58.0 + rays1 * 3.5 + TIME * 0.18);
				float profile1 = smoothstep(0.0, 0.06, d_curt1) * pow(1.0 - v1, 1.35) * ray_struct1;

				// Emerald green to mystical violet gradient
				vec3 col_base1 = vec3(0.12, 0.96, 0.58);
				vec3 col_top1 = vec3(0.68, 0.22, 0.95);
				vec3 curt1_col = mix(col_base1, col_top1, smoothstep(0.20, 0.80, v1));
				aurora += curt1_col * profile1 * 1.75;
			}

			// Curtain B: Secondary Higher Shimmer (altitude 0.24 - 0.54)
			float curt2_base = 0.24 + wave2;
			float d_curt2 = alt - curt2_base;
			if (d_curt2 > 0.0 && d_curt2 < 0.30) {
				float v2 = d_curt2 / 0.30;
				float rays2 = noise2d(vec2(theta * 28.0 - TIME * 0.08, v2 * 8.0));
				float ray_struct2 = 0.60 + 0.40 * cos(theta * 42.0 + rays2 * 4.0);
				float profile2 = smoothstep(0.0, 0.05, d_curt2) * pow(1.0 - v2, 1.5) * ray_struct2;

				vec3 col_base2 = vec3(0.20, 0.78, 0.92);
				vec3 col_top2 = vec3(0.88, 0.20, 0.72);
				vec3 curt2_col = mix(col_base2, col_top2, v2);
				aurora += curt2_col * profile2 * 1.20;
			}

			aurora *= night_wt * smoothstep(0.04, 0.15, up_pos) * smoothstep(0.35, -0.10, view_dir.z);
		}

		// Periodic celestial shooting star across firmament (every 14s)
		if (up_pos > 0.22) {
			float m_time = mod(TIME + 4.0, 14.0);
			if (m_time < 0.95) {
				float m_t = m_time / 0.95;
				vec3 m_start = normalize(vec3(0.55, 0.85, -0.40));
				vec3 m_dir = normalize(vec3(-0.48, -0.62, 0.28));
				vec3 m_curr = normalize(m_start + m_dir * (m_t * 0.75));
				float d_m = length(view_dir - m_curr);
				if (d_m < 0.028) {
					float m_lum = smoothstep(0.028, 0.001, d_m) * (1.0 - abs(m_t - 0.5) * 1.9);
					shooting_star = vec3(0.92, 0.96, 1.0) * m_lum * 3.8 * night_wt;
				}
			}
		}
	}

	// =========================================================================
	// 5. LAYERED PROCEDURAL CLOUDS (Drifting Cumulus & Wispy Cirrus)
	// =========================================================================
	float total_cloud_density = 0.0;
	float cumulus_shape = 0.0;
	vec3 c_day = cloud_color_day;
	float moon_cloud_forward = 0.0;

	if (up_pos > 0.01) {
		// Planar sky projection to prevent zenith pinching
		vec2 sky_uv = view_dir.xz / (up_pos + 0.16) * 0.28;
		vec2 wind_norm = normalize(wind_dir);
		vec2 cumulus_drift = wind_norm * (TIME * 0.005 * (0.8 + wind_speed * 0.12));
		vec2 cirrus_drift = wind_norm * (TIME * 0.012 * (1.2 + wind_speed * 0.20));

		// Layer A: Low-Altitude Cumulus Deck (3 octaves + 2 octaves)
		vec2 c_uv = sky_uv + cumulus_drift;
		float cn1 = fbm2d_3(c_uv * 1.8);
		float cn2 = fbm2d_2(c_uv * 3.6 + vec2(0.4, 0.7) + cumulus_drift * 0.5);
		cumulus_shape = cn1 * 0.65 + cn2 * 0.35;

		// Layer B: High-Altitude Wispy Cirrus Streaks (2 octaves)
		vec2 cirrus_uv = sky_uv * 1.6 + cirrus_drift;
		float cirrus_shape = fbm2d_2(cirrus_uv * vec2(4.2, 1.2));

		// Coverage thresholds coupled to WeatherSystem
		float cov = clamp(cloud_coverage, 0.02, 0.95);
		float cumulus_density = smoothstep(1.05 - cov, 1.25 - cov * 0.65, cumulus_shape);
		float cirrus_density = smoothstep(0.68, 0.88, cirrus_shape) * clamp(cov * 1.4, 0.0, 0.55);

		total_cloud_density = clamp(cumulus_density + cirrus_density * 0.6, 0.0, 1.0);

		// Horizon fade: clouds dissolve smoothly into the atmospheric horizon haze
		float cloud_horizon_fade = smoothstep(0.02, 0.28, up_pos);
		total_cloud_density *= cloud_horizon_fade;

		// Cloud Lighting: directional top lighting & silver/golden lining
		float sun_cloud_forward = pow(max(0.0, sun_dot), 6.0);
		moon_cloud_forward = pow(max(0.0, moon_dot), 4.0);

		c_day = mix(cloud_color_shadow, cloud_color_day, smoothstep(0.2, 0.85, cumulus_shape));
		// Silver lining when looking toward high sun
		c_day += vec3(0.25, 0.28, 0.32) * sun_cloud_forward * day_factor;

		// Golden sunset rim glow
		if (golden_factor > 0.01) {
			vec3 rim_glow = mix(cloud_color_golden, vec3(1.0, 0.82, 0.55), sun_cloud_forward);
			c_day = mix(c_day, rim_glow, golden_factor * 0.85);
		}

		// Storm front darkening
		if (rain_factor > 0.05) {
			vec3 storm_cloud = vec3(0.18, 0.22, 0.28);
			c_day = mix(c_day, storm_cloud, rain_factor * 0.75);
		}
	}

	// Nocturnal moon-lit cloud shading
	vec3 c_night = mix(cloud_color_night, vec3(0.22, 0.28, 0.38), moon_cloud_forward * 0.6);
	vec3 cloud_lit_color = mix(c_night, c_day, day_factor);

	// =========================================================================
	// 6. FINAL COMPOSITE: SKY, STARS, SUN, MOON & CLOUD LAYERS
	// =========================================================================
	vec3 final_color = sky_base;

	// Add Milky Way, Stars & Aurora Borealis (occluded by clouds)
	float cloud_occlusion = clamp(1.0 - total_cloud_density * 1.2, 0.0, 1.0);
	final_color += (milky_way + star_color * star_lum + aurora + shooting_star) * cloud_occlusion;

	// Add Sun Radiance & Corona
	if (sun_disc > 0.001 || sun_corona > 0.001) {
		float sun_cloud_atten = mix(1.0, 0.22, total_cloud_density);
		final_color += sun_radiance * sun_cloud_atten;
	}

	// Add Moon Radiance (occluded by clouds)
	if (moon_alpha_out > 0.001) {
		float moon_cloud_atten = mix(1.0, 0.15, total_cloud_density);
		final_color = mix(final_color, moon_radiance, moon_alpha_out * moon_cloud_atten);
	}

	// Alpha-composite the volumetric cloud deck over the celestial background
	final_color = mix(final_color, cloud_lit_color, total_cloud_density * 0.94);

	// Seamless distance haze blend at the bottom rim to match mountain horizon
	float bottom_fade = smoothstep(-0.04, 0.08, up);
	float final_alpha = max(total_cloud_density * 0.94, clamp((sun_disc + sun_corona * 0.4), 0.0, 1.0));
	final_alpha = max(final_alpha, moon_alpha_out);
	final_alpha = max(final_alpha, min(1.0, star_lum + length(milky_way) + length(aurora) * 0.8));
	// Ensure background sky gradient is solidly visible
	final_alpha = max(final_alpha, clamp(1.0 - bottom_fade * 0.15, 0.75, 1.0));

	ALBEDO = final_color;
	ALPHA = clamp(final_alpha * bottom_fade, 0.0, 1.0);
}
