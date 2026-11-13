shader_type spatial;
// Eau sombre de la forêt : quasi noire bleutée, opaque, faux reflet de ciel par fresnel, reflet de lune (disque + traînée
// scintillante), ondulation lente, bord plus clair (profondeur lue ; sans profondeur : COLOR.r du maillage).
// Aucun SSR : tout est analytique, donc identique en rendu logiciel et GPU.
render_mode blend_mix, depth_draw_always, cull_back, specular_schlick_ggx;

uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec4 deep_color : source_color = vec4(0.008, 0.020, 0.040, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.030, 0.075, 0.100, 1.0);
uniform vec4 sky_top : source_color = vec4(0.12, 0.17, 0.42, 1.0);
uniform vec4 sky_horizon : source_color = vec4(0.22, 0.32, 0.55, 1.0);
uniform vec4 moon_color : source_color = vec4(0.72, 0.80, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.18, 0.45, 0.52, 1.0);
uniform vec3 moon_dir = vec3(-0.4, 0.6, -0.5);
uniform float moon_size = 0.045;
uniform float moon_strength = 2.2;
uniform float reflect_strength : hint_range(0.0, 2.0) = 0.9;
uniform float fresnel_power = 3.2;
uniform float ripple_scale = 0.9;
uniform float ripple_speed = 0.06;
uniform float ripple_height = 0.55;
uniform float opacity : hint_range(0.0, 1.0) = 0.93;
uniform float edge_width = 0.55;
uniform float edge_strength = 0.7;
uniform bool use_depth = true;
uniform float glint = 0.8;

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
float wave(vec2 p, float t) {
	float a = vn(p * ripple_scale + vec2(t, t * 0.7));
	float b = vn(p * ripple_scale * 2.3 + vec2(-t * 1.3, t * 0.9) + 7.0);
	float c = vn(p * ripple_scale * 5.1 + vec2(t * 0.6, -t * 1.7) + 19.0);
	return a * 0.55 + b * 0.3 + c * 0.15;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = TIME * ripple_speed;
	vec2 p = wpos.xz;
	float e = 0.06;
	float h0 = wave(p, t);
	float hx = wave(p + vec2(e, 0.0), t);
	float hz = wave(p + vec2(0.0, e), t);
	vec3 wn = normalize(vec3(-(hx - h0) / e * 0.05 * ripple_height * 10.0, 1.0, -(hz - h0) / e * 0.05 * ripple_height * 10.0));
	vec3 V = normalize(CAMERA_POSITION_WORLD - wpos);
	float ndv = clamp(dot(wn, V), 0.0, 1.0);
	float fres = 0.03 + 0.97 * pow(1.0 - ndv, fresnel_power);
	vec3 R = reflect(-V, wn);
	vec3 sky = mix(sky_horizon.rgb, sky_top.rgb, clamp(R.y * 1.6, 0.0, 1.0));
	// reflet de lune : disque doux + traînée scintillante qui danse avec l'ondulation
	vec3 md = normalize(moon_dir);
	float mdot = dot(R, md);
	float disc = smoothstep(cos(moon_size * 1.8), cos(moon_size * 0.7), mdot);
	float halo = pow(max(mdot, 0.0), 60.0) * 0.45;
	float spark = smoothstep(0.55, 0.9, vn(p * 6.0 + vec2(TIME * 0.35, -TIME * 0.2))) * pow(max(mdot, 0.0), 14.0) * glint;
	vec3 moon = moon_color.rgb * (disc + halo + spark) * moon_strength;
	// bord : plus clair près de la rive (profondeur) ou via COLOR.r
	float shore = COLOR.r;
	if (use_depth) {
		float d = texture(depth_tex, SCREEN_UV).r;
		vec3 ndc = vec3(SCREEN_UV, d) * 2.0 - 1.0;
		vec4 vv = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		vv.xyz /= vv.w;
		float diff = max(-vv.z + VERTEX.z, 0.0);
		shore = 1.0 - smoothstep(0.0, edge_width, diff);
	}
	shore *= 0.8 + 0.2 * vn(p * 3.0 + TIME * 0.1);
	vec3 body = mix(deep_color.rgb, shallow_color.rgb, clamp(shore * 0.8 + (1.0 - ndv) * 0.15, 0.0, 1.0));
	ALBEDO = body;
	ROUGHNESS = 0.12;
	SPECULAR = 0.35;
	EMISSION = sky * fres * reflect_strength + moon * (0.25 + fres) + edge_color.rgb * shore * edge_strength;
	ALPHA = clamp(opacity + shore * 0.04, 0.0, 1.0);
}
