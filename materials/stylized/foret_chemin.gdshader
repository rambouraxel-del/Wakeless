shader_type spatial;
// Ruban de chemin (maillage posé sur le sol) : UV.x = travers (0..1), UV.y = longueur. Plus clair, tassé, chaud-gris,
// bords fondus par un alpha bruité. Sert quand le chemin est un ruban plutôt que peint dans le sol.
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.470, 0.415, 0.370, 1.0);
uniform vec4 wear_color : source_color = vec4(0.580, 0.520, 0.450, 1.0);
uniform vec4 edge_color : source_color = vec4(0.150, 0.150, 0.170, 1.0);
uniform float edge_soft : hint_range(0.02, 0.5) = 0.28;
uniform float opacity : hint_range(0.0, 1.0) = 0.96;

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
	vec2 p = wpos.xz;
	float across = abs(UV.x - 0.5) * 2.0;                       // 0 au centre, 1 au bord
	float wob = (vn(p * 0.8 + 9.0) - 0.5) * 0.35 + (vn(p * 2.7) - 0.5) * 0.12;
	float e = 1.0 - smoothstep(1.0 - edge_soft * 2.0, 1.0, across + wob);
	float wear = smoothstep(0.3, 0.8, vn(p * 0.6 + 3.0));
	vec3 c = mix(base_color.rgb, wear_color.rgb, wear * 0.55 * (1.0 - across));
	c = mix(edge_color.rgb, c, smoothstep(0.0, 0.7, e));         // bord plus sombre et terreux
	c *= 0.88 + vn(p * 9.0) * 0.26;
	vec2 pc2 = p * 5.0;
	vec2 pcell = floor(pc2);
	vec2 pj = vec2(h21(pcell + 3.0), h21(pcell + 8.0));
	c += step(0.55, h21(pcell)) * (1.0 - smoothstep(0.10, 0.22, length(fract(pc2) - (0.25 + 0.5 * pj)))) * 0.04;
	ALBEDO = c;
	EMISSION = c * e * 0.07;
	ALPHA = e * opacity;
	ROUGHNESS = 0.88;
	SPECULAR = 0.15;
}
