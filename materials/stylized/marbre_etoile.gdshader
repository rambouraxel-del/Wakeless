shader_type spatial;
// Sol de marbre nocturne (Wakeless) : marbre indigo poli à veines douces, joints de dalles et INCRUSTATIONS D'OR calculées
// en coordonnées monde (cercles concentriques, croissant de lune, étoiles à 8 branches, rayons) autour de `center`.
// `repeat_x` > 0 répète le motif le long de x (couloir). Les incrustations brillent légèrement.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 marble_dark : source_color = vec4(0.10, 0.08, 0.22, 1.0);
uniform vec4 marble_light : source_color = vec4(0.26, 0.20, 0.46, 1.0);
uniform vec4 vein_color : source_color = vec4(0.55, 0.48, 0.80, 1.0);
uniform vec4 gold : source_color = vec4(1.0, 0.76, 0.38, 1.0);
uniform float gold_glow = 0.55;
uniform float roughness : hint_range(0.0, 1.0) = 0.16;
uniform vec2 center = vec2(0.0, 0.0);
uniform float repeat_x = 0.0;
uniform float ring_radius = 6.0;
uniform float tile = 2.0;
uniform float pattern = 1.0;      // 0 = dalles seules

varying vec3 wp;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x), mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += vnoise(p) * a;
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}
float line(float d, float w) {
	return 1.0 - smoothstep(w * 0.5, w * 0.5 + fwidth(d) * 1.2, abs(d));
}
// étoile à 8 branches (distance approchée)
float star8(vec2 p, float r) {
	float a = atan(p.y, p.x);
	float k = abs(cos(a * 4.0));
	float rr = mix(r * 0.28, r, pow(k, 6.0));
	return 1.0 - smoothstep(rr - fwidth(length(p)), rr, length(p));
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wp.xz;
	// marbre : nuages + veines fines
	float m = fbm(p * 0.35);
	vec3 col = mix(marble_dark.rgb, marble_light.rgb, smoothstep(0.25, 0.85, m));
	float v = abs(fbm(p * 0.6 + vec2(m * 2.0)) - 0.5);
	col = mix(col, vein_color.rgb, (1.0 - smoothstep(0.0, 0.035, v)) * 0.45);
	// joints de dalles
	vec2 tp = p / tile;
	vec2 tf = abs(fract(tp) - 0.5);
	float joint = 1.0 - smoothstep(0.485, 0.495, max(tf.x, tf.y));
	col *= mix(0.75, 1.0, joint);
	// incrustations d'or
	float g = 0.0;
	if (pattern > 0.5) {
		vec2 c = center;
		vec2 q = p - c;
		if (repeat_x > 0.0) {
			q.x = mod(q.x + repeat_x * 0.5, repeat_x) - repeat_x * 0.5;
		}
		float r = length(q);
		float R = ring_radius;
		g = max(g, line(r - R, 0.07));
		g = max(g, line(r - R * 0.82, 0.04));
		g = max(g, line(r - R * 1.25, 0.03) * step(r, R * 1.4));
		// rayons (8) entre les cercles
		float ang = atan(q.y, q.x);
		float spoke = abs(sin(ang * 4.0)) * r;
		g = max(g, line(spoke, 0.035) * step(R * 0.82, r) * step(r, R * 1.25));
		// croissant au centre
		float moon = (1.0 - smoothstep(R * 0.42, R * 0.42 + 0.02, length(q))) * smoothstep(R * 0.36, R * 0.36 + 0.02, length(q - vec2(R * 0.16, -R * 0.06)));
		g = max(g, moon);
		// étoiles sur le grand cercle
		for (int i = 0; i < 8; i++) {
			float a = float(i) * 0.7853981 + 0.3926990;
			g = max(g, star8(q - vec2(cos(a), sin(a)) * R * 1.035, R * 0.075));
		}
		g = max(g, star8(q - vec2(-R * 0.12, R * 0.05), R * 0.12));
	}
	// petites étoiles semées dans les dalles (rares)
	vec2 cell = floor(p * 0.9);
	float h = hash21(cell);
	if (h > 0.93) {
		vec2 f = fract(p * 0.9) - 0.5;
		g = max(g, star8(f * 2.0, 0.16));
	}
	col = mix(col, gold.rgb, g);
	ALBEDO = col;
	METALLIC = g * 0.85;
	ROUGHNESS = mix(roughness, 0.3, g);
	SPECULAR = 0.6;
	EMISSION = gold.rgb * g * gold_glow;
}
