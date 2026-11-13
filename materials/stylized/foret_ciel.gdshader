shader_type sky;
// Ciel de la Forêt de la peur : nuit profonde dégradée vers un horizon indigo-violet, étoiles fines et rondes (pas de blocs),
// grande lune froide avec halo, voile de nuages argentés par la lune. Mêmes noms de paramètres que materials/sky_clouds.gdshader
// (le LightingRig les renseigne) : activé par la clé « sky_shader » d'un préréglage.
uniform vec3 sky_top : source_color = vec3(0.016, 0.024, 0.10);
uniform vec3 sky_horizon : source_color = vec3(0.12, 0.15, 0.31);
uniform vec3 ground_horizon : source_color = vec3(0.12, 0.15, 0.31);
uniform vec3 ground_bottom : source_color = vec3(0.05, 0.07, 0.18);
uniform vec3 moon_dir = vec3(-0.4, 0.6, -0.5);
uniform float moon_amount : hint_range(0.0, 1.0) = 1.0;
uniform float moon_size = 0.055;
uniform vec3 moon_tint : source_color = vec3(0.95, 0.85, 0.66);
uniform vec3 cloud_light : source_color = vec3(0.35, 0.42, 0.70);
uniform vec3 cloud_shadow : source_color = vec3(0.08, 0.10, 0.25);
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.25;
uniform float star_amount : hint_range(0.0, 1.0) = 1.0;
uniform float star_density = 0.035;

float h3(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}
float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float vn(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	return 0.5 * vn(p) + 0.27 * vn(p * 2.1 + 7.0) + 0.15 * vn(p * 4.3 + 3.0) + 0.08 * vn(p * 8.7 + 1.0);
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float up = dir.y;
	vec3 md = normalize(moon_dir);
	vec3 col;
	if (up >= 0.0) {
		col = mix(sky_horizon, sky_top, pow(clamp(up, 0.0, 1.0), 0.55));
		// étoiles rondes : un point jeté par cellule de l'espace des directions
		float K = 85.0;
		vec3 cell = floor(dir * K);
		float hh = h3(cell);
		if (hh < star_density) {
			vec3 c = (cell + 0.2 + 0.6 * vec3(h3(cell + 3.7), h3(cell + 9.1), h3(cell + 1.3))) / K;
			float d = length(dir - c) * K;
			float mag = 0.35 + 0.65 * h3(cell + 5.5);
			float tw = 0.85 + 0.15 * sin(TIME * (0.8 + 2.0 * h3(cell + 2.0)) + hh * 60.0);
			float s = exp(-d * d * 38.0) * mag * tw;
			col += vec3(0.85, 0.9, 1.0) * s * 1.6 * star_amount * smoothstep(0.01, 0.25, up);
		}
		// nuages : voile fin, bords argentés près de la lune
		vec2 uv = dir.xz / (up + 0.25);
		float d1 = fbm(uv * 0.9 + vec2(3.0, 9.0) + TIME * 0.002);
		float dens = smoothstep(1.0 - cloud_cover, 1.0 - cloud_cover + 0.35, d1) * smoothstep(0.02, 0.3, up);
		float near_moon = pow(max(dot(dir, md), 0.0), 6.0);
		vec3 cc = mix(cloud_shadow, cloud_light, clamp(0.25 + near_moon * 1.2 + (d1 - 0.5), 0.0, 1.0));
		col = mix(col, cc, dens * 0.8);
		// lune : disque à bord doux, taches sombres, halo large
		float md_d = dot(dir, md);
		float ang = acos(clamp(md_d, -1.0, 1.0));
		float disc = 1.0 - smoothstep(moon_size * 0.92, moon_size, ang);
		vec3 tex = moon_tint * (0.85 + 0.15 * vn((dir.xz - md.xz) * 90.0)) * (1.0 - 0.18 * smoothstep(0.55, 0.0, abs(ang / moon_size - 0.35)) * vn((dir.xy + md.zy) * 55.0));
		float limb = 1.0 - 0.25 * smoothstep(0.5, 1.0, ang / moon_size);
		col = mix(col, tex * limb * 0.55, disc * moon_amount);
		col += moon_tint * pow(max(md_d, 0.0), 160.0) * 0.18 * moon_amount;
		col += vec3(0.34, 0.36, 0.55) * pow(max(md_d, 0.0), 22.0) * 0.34 * moon_amount;
		col += vec3(0.20, 0.22, 0.55) * pow(max(md_d, 0.0), 4.0) * 0.12 * moon_amount;
	} else {
		float t = clamp(-up, 0.0, 1.0);
		col = mix(ground_horizon, ground_bottom, pow(t, 0.45));
	}
	float hz = 1.0 - smoothstep(0.0, 0.09, abs(up));
	col = mix(col, mix(ground_horizon, sky_horizon, 0.5), hz * 0.85);
	COLOR = col;
}
