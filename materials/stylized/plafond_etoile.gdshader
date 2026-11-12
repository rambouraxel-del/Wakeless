shader_type spatial;
// Voûte nocturne : bleu nuit profond, constellations scintillantes (points et fines lignes), léger dégradé.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley;

uniform vec4 base_color : source_color = vec4(0.08, 0.06, 0.20, 1.0);
uniform vec4 glow_color : source_color = vec4(0.30, 0.20, 0.55, 1.0);
uniform vec4 star_color : source_color = vec4(1.0, 0.86, 0.6, 1.0);
uniform float density = 0.06;
uniform float scale = 1.6;

varying vec3 wp;
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
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
		float tw = 0.65 + 0.35 * sin(TIME * (0.6 + h * 9.0) + h * 40.0);
		s = (1.0 - smoothstep(0.0, 0.09, d)) * tw + exp(-d * 18.0) * 0.4 * tw;
	}
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.9;
	EMISSION = glow_color.rgb * 0.15 + star_color.rgb * s * 1.6;
}
