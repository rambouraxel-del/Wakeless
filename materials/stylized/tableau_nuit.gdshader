shader_type spatial;
// Tableau de paysage nocturne (cadres de la chambre et du couloir) : ciel indigo, lune ou croissant, collines en plans
// successifs, petits points d'étoiles ; trois variantes tirées de la position de l'objet dans le monde (déterministe).
// Légèrement émissif pour rester lisible dans la pénombre ; aucune image.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley;

uniform vec4 ciel_haut : source_color = vec4(0.07, 0.07, 0.20, 1.0);
uniform vec4 ciel_bas : source_color = vec4(0.36, 0.28, 0.55, 1.0);
uniform vec4 colline : source_color = vec4(0.10, 0.09, 0.24, 1.0);
uniform vec4 brume : source_color = vec4(0.45, 0.38, 0.65, 1.0);
uniform float emission_part = 0.35;

varying vec3 origin;

float hash(float x) { return fract(sin(x * 91.3458) * 47453.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float nz(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), f);
}

void vertex() {
	origin = MODEL_MATRIX[3].xyz;
}

void fragment() {
	float seed = floor(mod(origin.x * 3.0 + origin.z * 7.0, 3.0));       // 0, 1 ou 2
	float s = seed + floor(origin.x) * 0.37;
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	vec3 col = mix(ciel_bas.rgb, ciel_haut.rgb, smoothstep(0.15, 1.0, uv.y));
	// étoiles
	vec2 sc = floor(uv * vec2(70.0, 50.0));
	if (hash2(sc + s) > 0.985) {
		col += vec3(0.9, 0.85, 1.0) * 0.8 * smoothstep(0.3, 0.8, uv.y);
	}
	// lune (pleine, ou plus basse et chaude selon la variante)
	vec2 mp = seed < 1.0 ? vec2(0.72, 0.72) : (seed < 2.0 ? vec2(0.3, 0.62) : vec2(0.55, 0.8));
	float aspect = 1.35;
	vec2 d = (uv - mp) * vec2(aspect, 1.0);
	float r = length(d);
	col += vec3(0.7, 0.62, 1.0) * exp(-r * 7.0) * 0.5;
	float disc = 1.0 - smoothstep(0.085, 0.095, r);
	float bite = seed > 1.5 ? smoothstep(0.075, 0.09, length(d - vec2(0.045, 0.02))) : 1.0;     // croissant
	col = mix(col, vec3(0.97, 0.93, 0.86), disc * bite);
	// collines : trois plans
	float h1 = 0.30 + nz(uv.x * 3.0 + s) * 0.14;
	float h2 = 0.19 + nz(uv.x * 4.5 + s * 2.0 + 5.0) * 0.1;
	float h3 = 0.08 + nz(uv.x * 6.0 + s * 3.0 + 9.0) * 0.06;
	if (uv.y < h1) col = mix(brume.rgb * 0.8, colline.rgb * 1.7, 0.6);
	if (uv.y < h2) col = colline.rgb * 1.3;
	if (uv.y < h3) col = colline.rgb * 0.8;
	// petites fenêtres allumées sur la colline moyenne
	if (uv.y < h2 - 0.02 && uv.y > h3 + 0.02) {
		vec2 wc = floor(vec2(uv.x * 40.0, uv.y * 40.0));
		if (hash2(wc + s) > 0.93) col = vec3(1.0, 0.76, 0.42);
	}
	ALBEDO = col * 0.85;
	EMISSION = col * emission_part;
	ROUGHNESS = 0.6;
}
