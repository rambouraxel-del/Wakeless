shader_type spatial;
// Sol de la Forêt de la peur : terre sombre et mousse désaturée, variations douces à grande échelle (position monde,
// aucune UV). Un chemin optionnel (polyligne en x,z) y est tassé, plus clair, légèrement chaud-gris, au bord adouci.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 earth_dark : source_color = vec4(0.085, 0.090, 0.135, 1.0);
uniform vec4 earth_mid : source_color = vec4(0.125, 0.140, 0.150, 1.0);
uniform vec4 moss_dark : source_color = vec4(0.085, 0.130, 0.110, 1.0);
uniform vec4 moss_light : source_color = vec4(0.165, 0.227, 0.204, 1.0);
uniform vec4 leaf_tint : source_color = vec4(0.100, 0.075, 0.130, 1.0);
uniform float large_scale = 0.045;
uniform float mid_scale = 0.22;
uniform float fine_scale = 1.9;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.62;
uniform float roughness : hint_range(0.0, 1.0) = 0.95;
// chemin (0 segment = aucun) : points (x, z) successifs
uniform vec4 path_color : source_color = vec4(0.270, 0.255, 0.250, 1.0);
uniform vec4 path_wear : source_color = vec4(0.340, 0.320, 0.300, 1.0);
uniform vec4 path_pts[32];
uniform int path_count = 0;
uniform float path_width = 1.5;
uniform float path_soft = 0.9;
uniform float path_glow = 0.08;      // léger auto-éclairage : le chemin se lit même dans le bois noir

varying vec3 wpos;
varying vec3 wnrm;

float h21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vn(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	return vn(p) * 0.55 + vn(p * 2.03 + 5.2) * 0.3 + vn(p * 4.1 + 11.7) * 0.15;
}
float path_dist(vec2 p) {
	float best = 1e5;
	for (int i = 0; i < 31; i++) {
		if (i + 1 >= path_count) break;
		vec2 a = path_pts[i].xy;
		vec2 b = path_pts[i + 1].xy;
		vec2 ab = b - a;
		float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
		best = min(best, length(p - (a + ab * t)));
	}
	return best;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = wpos.xz;
	float big = fbm(p * large_scale + 3.1);
	float mid = fbm(p * mid_scale + 17.0);
	float fine = vn(p * fine_scale);
	// terre : deux tons, plaques douces
	vec3 col = mix(earth_dark.rgb, earth_mid.rgb, smoothstep(0.25, 0.75, big * 0.6 + mid * 0.4));
	// mousse : plus présente sur les replats et dans certaines grandes zones
	float flat_k = smoothstep(0.55, 0.95, wnrm.y);
	float mk = smoothstep(0.42, 0.66, big * 0.65 + mid * 0.45 - (1.0 - moss_amount) * 0.35) * flat_k;
	vec3 moss = mix(moss_dark.rgb, moss_light.rgb, smoothstep(0.3, 0.8, mid * 0.6 + fine * 0.4));
	col = mix(col, moss, mk * 0.85);
	// feuilles mortes violacées en taches
	float lk = smoothstep(0.62, 0.8, vn(p * 0.31 + 41.0) * 0.6 + vn(p * 1.3) * 0.4);
	col = mix(col, leaf_tint.rgb, lk * 0.5 * (1.0 - mk * 0.6));
	// grain fin
	col *= 0.9 + fine * 0.2 + (vn(p * 7.3) - 0.5) * 0.12;
	// chemin
	float pk = 0.0;
	if (path_count > 1) {
		float wob = (fbm(p * 0.9 + 70.0) - 0.5) * 0.7;
		float d = path_dist(p) + wob * path_soft * 0.6;
		pk = 1.0 - smoothstep(path_width * 0.5 - path_soft * 0.5, path_width * 0.5 + path_soft, d);
		float wear = smoothstep(0.35, 0.75, vn(p * 0.7 + 3.0));
		vec3 pc = mix(path_color.rgb, path_wear.rgb, wear * 0.6 * (1.0 - smoothstep(0.0, path_width * 0.5, d)));
		pc *= 0.88 + vn(p * 9.0) * 0.28;                       // petits cailloux et tassement
		vec2 pc2 = p * 5.0;
		vec2 pcell = floor(pc2);
		vec2 pj = vec2(h21(pcell + 3.0), h21(pcell + 8.0));
		float pebble = step(0.55, h21(pcell)) * (1.0 - smoothstep(0.10, 0.22, length(fract(pc2) - (0.25 + 0.5 * pj))));
		pc += pebble * 0.04;
		col = mix(col, pc, pk);
	}
	ALBEDO = col;
	EMISSION = col * pk * path_glow;
	ROUGHNESS = mix(roughness, 0.86, pk);
	SPECULAR = 0.15;
}
