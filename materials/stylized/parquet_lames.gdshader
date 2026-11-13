shader_type spatial;
// Parquet à lames de la chambre 107 : lames de 15 cm le long de l'axe x, joints décalés rangée par rangée (déterministe),
// teinte prune-brun chaude propre à chaque lame, fibre allongée, joints sombres, brillance douce.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 colour_a : source_color = vec4(0.30, 0.17, 0.20, 1.0);
uniform vec4 colour_b : source_color = vec4(0.40, 0.23, 0.24, 1.0);
uniform float plank_w = 0.16;
uniform float plank_l = 1.25;
uniform float roughness : hint_range(0.0, 1.0) = 0.42;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x), mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = vec2(world_pos.x, world_pos.z);
	float row = floor(p.y / plank_w);
	float off = hash21(vec2(row, 3.7)) * plank_l;
	float cx = (p.x + off) / plank_l;
	float col_i = floor(cx);
	vec2 id = vec2(col_i, row);
	float h = hash21(id);
	vec3 c = mix(colour_a.rgb, colour_b.rgb, h);
	// fibre : bruit étiré le long des lames
	float grain = vnoise(vec2(p.x * 3.0 + h * 40.0, p.y * 38.0)) * 0.6 + vnoise(vec2(p.x * 9.0, p.y * 90.0 + h * 10.0)) * 0.4;
	c *= 0.88 + grain * 0.24;
	// joints
	float fy = fract(p.y / plank_w);
	float fx = fract(cx);
	float aa = fwidth(p.y / plank_w) * 1.5 + 0.01;
	float aax = fwidth(cx) * 1.5 + 0.004;
	float joint = 1.0 - smoothstep(0.0, aa + 0.035, min(fy, 1.0 - fy));
	joint = max(joint, 1.0 - smoothstep(0.0, aax + 0.004, min(fx, 1.0 - fx)));
	c *= 1.0 - joint * 0.55;
	ALBEDO = c;
	ROUGHNESS = roughness - h * 0.1;
	SPECULAR = 0.55;
}
