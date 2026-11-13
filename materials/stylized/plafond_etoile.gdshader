shader_type spatial;
// Voûte nocturne : bleu nuit profond, étoiles fines au scintillement lent, quelques constellations très faibles.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley;

uniform vec4 base_color : source_color = vec4(0.075, 0.075, 0.20, 1.0);
uniform vec4 glow_color : source_color = vec4(0.20, 0.19, 0.44, 1.0);
uniform vec4 star_color : source_color = vec4(0.95, 0.88, 0.72, 1.0);
uniform float density = 0.06;
uniform float scale = 1.6;
uniform float constellations : hint_range(0.0, 1.0) = 1.0;

varying vec3 wp;
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wp.xz * scale + wp.y * 0.37;
	vec2 c = floor(p);
	vec2 f = fract(p) - 0.5;
	float h = hash21(c);
	float s = 0.0;
	if (h < density) {
		vec2 o = (vec2(hash21(c + 1.1), hash21(c + 2.3)) - 0.5) * 0.5;
		float d = length(f - o);
		float tw = 0.7 + 0.3 * sin(TIME * (0.12 + h * 3.0) + h * 40.0);     // scintillement lent
		float size = 0.035 + 0.035 * hash21(c + 4.4);
		s = ((1.0 - smoothstep(0.0, size, d)) + exp(-d * 26.0) * 0.22) * tw;
	}
	// constellations : cellules larges, 4 points reliés par un fil très fin
	float cons = 0.0;
	if (constellations > 0.0) {
		vec2 q = p / 7.0;
		vec2 qc = floor(q);
		vec2 qf = fract(q);
		float hh = hash21(qc + 9.0);
		if (hh < 0.4) {
			vec2 a = vec2(0.2 + 0.2 * hash21(qc + 1.0), 0.2 + 0.6 * hash21(qc + 2.0));
			vec2 b = a + vec2(0.1 + 0.15 * hash21(qc + 3.0), (hash21(qc + 4.0) - 0.5) * 0.3);
			vec2 e = b + vec2(0.08 + 0.15 * hash21(qc + 5.0), (hash21(qc + 6.0) - 0.5) * 0.35);
			vec2 g = e + vec2(0.05 + 0.12 * hash21(qc + 7.0), (hash21(qc + 8.0) - 0.5) * 0.4);
			float dl = min(seg(qf, a, b), min(seg(qf, b, e), seg(qf, e, g)));
			float dp = min(min(length(qf - a), length(qf - b)), min(length(qf - e), length(qf - g)));
			cons = (1.0 - smoothstep(0.0, 0.0035, dl)) * 0.16 + (1.0 - smoothstep(0.0, 0.014, dp)) * 0.7;
			cons *= 0.75 + 0.25 * sin(TIME * 0.2 + hh * 30.0);
		}
	}
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.9;
	EMISSION = glow_color.rgb * 0.34 * (0.7 + 0.3 * clamp(wp.y * 0.1, 0.0, 1.0)) + star_color.rgb * (s * 1.7 + cons * 0.8 * constellations);
}
