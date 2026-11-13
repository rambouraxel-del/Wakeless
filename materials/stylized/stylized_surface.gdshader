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
// --- finition matières (valeurs par défaut neutres : sans effet)
uniform float rim_power = 3.0;                 // plus grand = liseré plus fin
uniform float foot_dark : hint_range(0.0, 1.0) = 0.0;   // assombrissement du bas (occlusion de pied de mur)
uniform float foot_height = 1.4;
uniform float dirt : hint_range(0.0, 1.0) = 0.0;        // salissure en taches douces
uniform float grain : hint_range(0.0, 0.3) = 0.0;       // grain d'enduit fin
uniform float wood : hint_range(0.0, 1.0) = 0.0;        // veinage en bandes
uniform vec3 wood_dir = vec3(0.0, 1.0, 0.0);            // direction du fil
uniform float wood_freq = 9.0;
uniform float fake_reflect : hint_range(0.0, 2.0) = 0.0; // faux reflet d'environnement (métal, vernis)
uniform vec4 reflect_color : source_color = vec4(1.0, 0.8, 0.5, 1.0);

uniform vec4 pool = vec4(0.0);          // flaque de lune au sol : centre xz, demi-tailles
uniform float pool_rot = 0.0;
uniform float pool_strength = 0.0;
uniform vec4 moon_color : source_color = vec4(0.66, 0.69, 1.0, 1.0);

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
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float g = smoothstep(gradient_bottom, gradient_top, world_pos.y);
	vec3 col = mix(base_color.rgb, top_color.rgb, g);
	// variation multi-échelle (grandes plaques, taches moyennes, fin)
	float n = vnoise(world_pos * variation_scale * 0.31) * 0.4 + vnoise(world_pos * variation_scale) * 0.4 + vnoise(world_pos * variation_scale * 3.1) * 0.2;
	col *= 1.0 + (n - 0.5) * 2.0 * variation;
	if (dirt > 0.0) {
		float dn = vnoise(world_pos * vec3(1.3, 0.8, 1.3) + 7.0) * 0.6 + vnoise(world_pos * 4.7) * 0.4;
		col *= 1.0 - dirt * smoothstep(0.5, 0.85, dn) * (1.0 - g * 0.5);
	}
	if (grain > 0.0) {
		col *= 1.0 + (vnoise(world_pos * 23.0) - 0.5) * grain * 2.0;
	}
	if (foot_dark > 0.0) {
		col *= 1.0 - foot_dark * (1.0 - smoothstep(0.0, foot_height, world_pos.y - gradient_bottom));
	}
	if (wood > 0.0) {
		vec3 wd = normalize(wood_dir);
		vec3 pp = world_pos - wd * dot(world_pos, wd);
		float t = (pp.x + pp.y * 0.93 + pp.z * 1.07) * wood_freq + vnoise(world_pos * 1.9) * 1.6;
		float band = 0.5 + 0.5 * sin(t) * (0.6 + 0.4 * sin(t * 0.37 + 1.3));
		float fine = vnoise(pp * 60.0 + dot(world_pos, wd) * 2.0);
		float w = band * 0.75 + fine * 0.25;
		col *= 1.0 - wood * 0.26 * smoothstep(0.55, 0.95, w);
		col *= 1.0 + wood * 0.10 * (1.0 - w);
	}
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
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	emis += rim_color.rgb * fres * rim_strength;
	if (fake_reflect > 0.0) {
		vec3 rw = (INV_VIEW_MATRIX * vec4(reflect(-VIEW, NORMAL), 0.0)).xyz;
		// environnement stylisé : plafond sombre, bande claire (fenêtres) à l'horizon, sol chaud faible
		float horizon = exp(-pow((rw.y - 0.12) * 5.0, 2.0));
		float up = smoothstep(0.35, 0.95, rw.y) * 0.25;
		float lamp = pow(max(dot(normalize(rw.xz + 0.001), vec2(0.6, 0.8)), 0.0), 6.0) * horizon;
		vec3 env = reflect_color.rgb * (horizon * 0.35 + lamp * 0.9 + up);
		emis += col * env * fake_reflect;
	}
	if (pool_strength > 0.0 && world_nrm.y > 0.7) {
		emis += moon_color.rgb * (col * 3.0 + 0.04) * moon_pool(world_pos.xz, pool.xy, pool_rot, pool.zw) * pool_strength;
	}
	EMISSION = emis;
}
