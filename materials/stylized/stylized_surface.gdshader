shader_type spatial;
// Surface STYLISÉE commune (Wakeless, 3D douce) : couleur de base, léger dégradé vertical en coordonnées monde,
// variation douce à grande échelle (pas de texture image), liseré lumineux (fresnel) discret qui arrondit les volumes,
// motif d'étoiles optionnel (tissus, plafonds). Un seul shader pour murs, bois, velours, pierre claire : rendu cohérent.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.36, 0.28, 0.58, 1.0);
uniform vec4 top_color : source_color = vec4(0.30, 0.24, 0.52, 1.0);
uniform float gradient_bottom = 0.0;
uniform float gradient_top = 12.0;
uniform float variation : hint_range(0.0, 0.5) = 0.08;
uniform float variation_scale = 0.35;
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.4;
uniform vec4 rim_color : source_color = vec4(0.75, 0.62, 1.0, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.12;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
// motif d'étoiles (0 = aucun) : petites étoiles dorées semées (tissus, couvre-lits, plafonds)
uniform float star_density = 0.0;
uniform float star_scale = 6.0;
uniform vec4 star_color : source_color = vec4(1.0, 0.82, 0.45, 1.0);
uniform float star_glow = 0.6;

varying vec3 world_pos;
varying vec3 world_nrm;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i.xy + i.z * 17.0);
	float b = hash21(i.xy + vec2(1.0, 0.0) + i.z * 17.0);
	float c = hash21(i.xy + vec2(0.0, 1.0) + i.z * 17.0);
	float d = hash21(i.xy + vec2(1.0, 1.0) + i.z * 17.0);
	float a2 = hash21(i.xy + (i.z + 1.0) * 17.0);
	float b2 = hash21(i.xy + vec2(1.0, 0.0) + (i.z + 1.0) * 17.0);
	float c2 = hash21(i.xy + vec2(0.0, 1.0) + (i.z + 1.0) * 17.0);
	float d2 = hash21(i.xy + vec2(1.0, 1.0) + (i.z + 1.0) * 17.0);
	float l1 = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
	float l2 = mix(mix(a2, b2, f.x), mix(c2, d2, f.x), f.y);
	return mix(l1, l2, f.z);
}
// distance à une étoile à 4 branches dans une cellule
float star4(vec2 uv, float size) {
	vec2 a = abs(uv);
	float d = a.x * a.y * 40.0 + length(uv) * 1.2;
	return 1.0 - smoothstep(size * 0.25, size, d);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float g = smoothstep(gradient_bottom, gradient_top, world_pos.y);
	vec3 col = mix(base_color.rgb, top_color.rgb, g);
	float n = vnoise(world_pos * variation_scale) * 0.65 + vnoise(world_pos * variation_scale * 3.1) * 0.35;
	col *= 1.0 + (n - 0.5) * 2.0 * variation;
	vec3 emis = emission_color.rgb * emission_energy;
	if (star_density > 0.0) {
		// projection triplanaire simple selon la normale dominante
		vec3 an = abs(world_nrm);
		vec2 p = an.y > max(an.x, an.z) ? world_pos.xz : (an.x > an.z ? world_pos.zy : world_pos.xy);
		vec2 cell = floor(p * star_scale);
		vec2 f = fract(p * star_scale) - 0.5;
		float h = hash21(cell);
		if (h < star_density) {
			vec2 o = (vec2(hash21(cell + 3.1), hash21(cell + 7.7)) - 0.5) * 0.4;
			float s = star4(f - o, 0.12 + 0.1 * hash21(cell + 1.3));
			col = mix(col, star_color.rgb, s);
			emis += star_color.rgb * s * star_glow;
		}
	}
	ALBEDO = col;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = emis + rim_color.rgb * fres * rim_strength;
}
