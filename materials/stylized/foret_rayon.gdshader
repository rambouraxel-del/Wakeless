shader_type spatial;
// Rayon de lune : plan vertical très doux, additif, qui s'estompe sur les bords, en haut et près de la caméra.
// Poussière et spores (particules) s'y logent. Non éclairé.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform vec4 ray_color : source_color = vec4(0.45, 0.58, 0.95, 1.0);
uniform float strength = 0.12;
uniform float near_fade_end = 6.0;

varying vec3 wpos;

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
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float side = 1.0 - pow(abs(UV.x - 0.5) * 2.0, 1.6);
	float along = smoothstep(0.0, 0.25, UV.y) * (1.0 - smoothstep(0.55, 1.0, UV.y));
	float n = 0.75 + 0.25 * vn(vec2(wpos.x * 0.8 + wpos.z * 0.8, wpos.y * 0.3 - TIME * 0.05));
	float near = smoothstep(1.5, near_fade_end, length(VERTEX));
	ALBEDO = ray_color.rgb * strength * side * along * n * near;
	ALPHA = side * along * near;
}
