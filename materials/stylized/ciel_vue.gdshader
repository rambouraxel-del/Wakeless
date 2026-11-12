shader_type spatial;
// Paysage nocturne derrière les grandes fenêtres (Wakeless) : plan non éclairé. Dégradé violet, lune et halo, étoiles,
// nuages en bandes douces, silhouettes de tours et de collines avec fenêtres allumées, brume. Paramétrable par fenêtre
// (position de la lune, graine des silhouettes) : aucune image.
render_mode unshaded, cull_disabled, depth_draw_opaque, fog_disabled;

uniform vec4 sky_top : source_color = vec4(0.07, 0.05, 0.22, 1.0);
uniform vec4 sky_horizon : source_color = vec4(0.42, 0.28, 0.70, 1.0);
uniform vec4 mist : source_color = vec4(0.55, 0.42, 0.85, 1.0);
uniform vec4 silhouette : source_color = vec4(0.13, 0.09, 0.28, 1.0);
uniform vec4 window_light : source_color = vec4(1.0, 0.78, 0.45, 1.0);
uniform vec2 moon_pos = vec2(0.7, 0.75);
uniform float moon_size = 0.07;
uniform float seed = 1.0;
uniform float brightness = 1.0;
// taille du plan en mètres (pour garder des proportions justes quelle que soit la fenêtre)
uniform vec2 plane_size = vec2(4.0, 8.0);

float hash(float x) { return fract(sin(x * 91.3458 + seed * 17.13) * 47453.5453); }
float hash2(vec2 p) { return fract(sin(dot(p + seed, vec2(12.9898, 78.233))) * 43758.5453); }
float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), f);
}

void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	vec2 m = uv * plane_size / plane_size.y;            // coordonnées en hauteurs de fenêtre
	vec3 col = mix(sky_horizon.rgb, sky_top.rgb, smoothstep(0.05, 0.95, uv.y));
	// étoiles
	vec2 sc = floor(m * 90.0);
	float s = hash2(sc);
	if (s > 0.985) {
		vec2 f = fract(m * 90.0) - 0.5;
		col += vec3(0.9, 0.85, 1.0) * (1.0 - smoothstep(0.0, 0.35, length(f))) * smoothstep(0.3, 0.8, uv.y) * 1.2;
	}
	// lune et halo
	vec2 mp = vec2(moon_pos.x * plane_size.x / plane_size.y, moon_pos.y);
	float d = length(m - mp);
	col += vec3(0.75, 0.68, 1.0) * exp(-d * 9.0) * 0.6;
	float disc = 1.0 - smoothstep(moon_size - 0.004, moon_size, d);
	float shade = smoothstep(moon_size * 0.6, moon_size * 1.1, length(m - mp - vec2(moon_size * 0.55, moon_size * 0.25)));
	col = mix(col, vec3(0.98, 0.95, 1.0), disc * shade);
	// nuages en bandes
	float cl = noise1(m.x * 3.0 + seed) * 0.5 + noise1(m.x * 7.0 - seed) * 0.25;
	float band = smoothstep(0.03, 0.0, abs(uv.y - (0.42 + cl * 0.12))) * 0.6;
	col = mix(col, mist.rgb * 1.1, band * 0.5);
	// silhouettes lointaines (collines) puis proches (tours)
	float far = 0.18 + noise1(m.x * 2.5 + seed * 3.0) * 0.1;
	if (uv.y < far) {
		col = mix(silhouette.rgb * 1.6, mist.rgb, 0.45);
	}
	float tx = m.x * 9.0;
	float ti = floor(tx);
	float th = 0.08 + hash(ti) * 0.22;
	float tw = 0.25 + hash(ti + 0.5) * 0.4;
	float inside = step(abs(fract(tx) - 0.5), tw * 0.5);
	float roof = th + 0.06 * (1.0 - abs(fract(tx) - 0.5) / max(tw * 0.5, 0.01)) * step(0.6, hash(ti + 2.0));
	if (uv.y < roof && inside > 0.5) {
		col = silhouette.rgb;
		vec2 wcell = floor(vec2(fract(tx) * 6.0, uv.y * 60.0));
		if (hash2(wcell + ti) > 0.82 && uv.y < th - 0.01) {
			col = window_light.rgb;
		}
	}
	// brume au ras de l'horizon
	col = mix(col, mist.rgb, smoothstep(0.16, 0.0, uv.y) * 0.5);
	ALBEDO = col * brightness;
}
