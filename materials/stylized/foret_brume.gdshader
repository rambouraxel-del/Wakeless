shader_type spatial;
// Brume basse : plans horizontaux (ou verticaux) à bords fondus, bruit défilant lentement, fondu au contact du sol
// (profondeur) et près de la caméra. Non éclairé. UV 0..1 sur le plan.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec4 fog_color : source_color = vec4(0.17, 0.22, 0.34, 1.0);
uniform vec4 fog_color_hi : source_color = vec4(0.28, 0.35, 0.48, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.35;
uniform vec2 scroll = vec2(0.012, 0.006);
uniform float noise_scale = 0.07;
uniform float edge_fade : hint_range(0.01, 0.5) = 0.28;
uniform float contact_fade = 1.1;
uniform float near_fade_start = 0.8;
uniform float near_fade_end = 4.5;
uniform float patchy : hint_range(0.0, 1.0) = 0.55;
uniform bool use_depth = true;

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
	vec2 q = wpos.xz + wpos.y * 3.0;
	vec2 sc = scroll * TIME;
	float n = vn(q * noise_scale + sc) * 0.5 + vn(q * noise_scale * 2.1 - sc * 1.7 + 4.0) * 0.32 + vn(q * noise_scale * 4.3 + sc * 0.6 + 9.0) * 0.18;
	float mask = mix(1.0, smoothstep(0.28, 0.72, n), patchy);
	float rr = length((UV - 0.5) * 2.0);
	float edge = 1.0 - smoothstep(0.25, 1.0, rr);
	edge *= edge;
	float a = density * mask * edge;
	if (use_depth) {
		float d = texture(depth_tex, SCREEN_UV).r;
		vec3 ndc = vec3(SCREEN_UV, d) * 2.0 - 1.0;
		vec4 vv = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		vv.xyz /= vv.w;
		float diff = max(-vv.z + VERTEX.z, 0.0);
		a *= smoothstep(0.0, contact_fade, diff);
	}
	float dist = length(VERTEX);
	a *= smoothstep(near_fade_start, near_fade_end, dist);
	vec3 col = mix(fog_color.rgb, fog_color_hi.rgb, smoothstep(0.4, 0.85, n));
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 1.0);
}
