shader_type spatial;
// Sol de marbre nocturne (Wakeless) : marbre indigo poli à veines douces, joints de dalles et INCRUSTATIONS D'OR calculées
// en coordonnées monde (cercles concentriques, croissant de lune, étoiles à 8 branches, rayons) autour de `center`.
// `repeat_x` > 0 répète le motif le long de x (couloir). Les incrustations brillent légèrement.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 marble_dark : source_color = vec4(0.065, 0.06, 0.15, 1.0);
uniform vec4 marble_light : source_color = vec4(0.19, 0.17, 0.35, 1.0);
uniform vec4 vein_color : source_color = vec4(0.86, 0.80, 0.68, 1.0);
uniform vec4 gold : source_color = vec4(0.79, 0.63, 0.37, 1.0);
uniform float gold_glow = 0.04;
uniform float roughness : hint_range(0.0, 1.0) = 0.07;
uniform vec2 center = vec2(0.0, 0.0);
uniform float repeat_x = 0.0;
uniform float ring_radius = 6.0;
uniform float tile = 2.0;
uniform float pattern = 1.0;      // 0 = dalles seules

uniform vec4 pool_x = vec4(0.0);          // flaques de lune (fenêtres) : centres, rotation, demi-tailles
uniform vec4 pool_z = vec4(0.0);
uniform vec4 pool_rot = vec4(0.0);
uniform vec2 pool_hs = vec2(1.2, 2.4);
uniform float pool_strength = 0.0;
uniform vec4 moon_color : source_color = vec4(0.66, 0.69, 1.0, 1.0);

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

float moon_pool(vec2 p, vec2 c, float rot, vec2 hs) {
	vec2 q = p - c;
	float cs = cos(rot);
	float sn = sin(rot);
	q = vec2(cs * q.x - sn * q.y, sn * q.x + cs * q.y);
	vec2 a = abs(q) / hs;
	float edge = 1.0 - smoothstep(0.6, 1.0, max(a.x, a.y));
	// ombre des meneaux de la fenêtre dans le rayon
	float sx = hs.x * 0.8;
	float sy = hs.y * 0.55;
	float bx = abs(fract(q.x / sx + 0.5) - 0.5) * sx;
	float by = abs(fract(q.y / sy + 0.5) - 0.5) * sy;
	float bars = (1.0 - smoothstep(0.03, 0.10, bx)) + (1.0 - smoothstep(0.03, 0.10, by));
	return edge * (1.0 - 0.7 * clamp(bars, 0.0, 1.0)) * (0.65 + 0.35 * (1.0 - a.y * 0.6));
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wp.xz;
	// marbre : nuages + veines fines
	float m = fbm(p * 0.35);
	vec3 col = mix(marble_dark.rgb, marble_light.rgb, smoothstep(0.25, 0.85, m));
	// veines crème fines et irrégulières : deux réseaux, épaisseur modulée par un bruit lent
	vec2 warp = vec2(fbm(p * 0.9 + 3.1), fbm(p * 0.9 + 8.7)) * 1.6;
	float f1 = fbm(p * 0.55 + warp * 0.6);
	float f2 = fbm(p * 1.35 + warp + 11.0);
	float v1 = abs(f1 - 0.5);
	float v2 = abs(f2 - 0.5);
	// épaisseur CONSTANTE en mètres (rapport du gradient du bruit) : fil fin quelle que soit la distance
	float ps = max(fwidth(p.x) + fwidth(p.y), 1e-4);
	float g1 = max(fwidth(f1) / ps, 0.05);
	float g2 = max(fwidth(f2) / ps, 0.05);
	float thick = 0.5 + 1.0 * vnoise(p * 0.8 + 5.0);
	float vein = (1.0 - smoothstep(0.0, max(0.011 * thick * g1, fwidth(f1)), v1)) * 0.85 + (1.0 - smoothstep(0.0, max(0.006 * thick * g2, fwidth(f2)), v2)) * 0.5;
	float vmask = smoothstep(0.56, 0.74, fbm(p * 0.22 + 20.0));      // veines par zones : le marbre respire
	col = mix(col, vein_color.rgb * 0.8, clamp(vein * vmask, 0.0, 1.0) * 0.36);
	col += vec3(0.05, 0.05, 0.10) * smoothstep(0.35, 0.8, fbm(p * 0.28 + 40.0));   // nuage doux dans l'indigo
	col += vec3(0.02, 0.02, 0.05) * smoothstep(0.55, 0.9, fbm(p * 2.2));
	// joints de dalles
	vec2 tp = p / tile;
	vec2 tf = abs(fract(tp) - 0.5);
	float joint = 1.0 - smoothstep(0.485, 0.495, max(tf.x, tf.y));
	col *= mix(0.6, 1.0, joint);
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
		g = max(g, line(r - R, 0.045));
		g = max(g, line(r - R * 0.82, 0.026));
		g = max(g, line(r - R * 1.25, 0.02) * step(r, R * 1.4));
		// rayons (8) entre les cercles
		float ang = atan(q.y, q.x);
		float spoke = abs(sin(ang * 4.0)) * r;
		g = max(g, line(spoke, 0.022) * step(R * 0.82, r) * step(r, R * 1.25));
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
	float edge = clamp(g - 0.0, 0.0, 1.0);
	col = mix(col, gold.rgb * mix(0.55, 1.0, smoothstep(0.4, 1.0, edge)), g);
	vec3 pool_em = vec3(0.0);
	if (pool_strength > 0.0) {
		float pl = 0.0;
		for (int i = 0; i < 4; i++) {
			pl = max(pl, moon_pool(p, vec2(pool_x[i], pool_z[i]), pool_rot[i], pool_hs));
		}
		pool_em = moon_color.rgb * (col * 3.0 + 0.04) * pl * pool_strength;
	}
	ALBEDO = col;
	METALLIC = g * 0.7;
	ROUGHNESS = mix(roughness, 0.26, g);
	SPECULAR = 0.85;
	// filet sombre le long de l'or (creux) pour qu'il se lise comme un métal incrusté
	EMISSION = gold.rgb * g * gold_glow + pool_em;
}
