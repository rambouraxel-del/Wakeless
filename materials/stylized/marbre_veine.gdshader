shader_type spatial;
// Marbre à veines crème (plateau de la réception, tablettes) : indigo profond, veines crème brillantes en coordonnées
// monde, poli. Propre à l'atrium.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_a : source_color = vec4(0.10, 0.09, 0.24, 1.0);
uniform vec4 base_b : source_color = vec4(0.20, 0.17, 0.38, 1.0);
uniform vec4 vein : source_color = vec4(0.94, 0.89, 0.81, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.14;
uniform float scale = 1.3;

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

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = vec2(wp.x + wp.z * 0.7, wp.y * 0.7 + wp.z * 0.3) * scale;
	float cloud = fbm(p * 0.6);
	vec3 col = mix(base_a.rgb, base_b.rgb, cloud);
	float w = fbm(p * 0.9 + vec2(3.1, 7.7));
	float ridge = 1.0 - abs(w * 2.0 - 1.0);
	float v = smoothstep(0.93, 0.985, ridge);
	float v2 = smoothstep(0.88, 0.99, 1.0 - abs(fbm(p * 1.9 + vec2(8.4, 1.3)) * 2.0 - 1.0)) * 0.35;
	col = mix(col, vein.rgb, clamp(v + v2, 0.0, 1.0));
	ALBEDO = col;
	ROUGHNESS = roughness;
	SPECULAR = 0.8;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = vein.rgb * (v + v2) * 0.12 + vec3(0.5, 0.45, 0.8) * fres * 0.12;
}
