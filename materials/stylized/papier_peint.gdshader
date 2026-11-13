shader_type spatial;
// Papier peint de la chambre 107 : damassé discret (treillis en losanges, petite étoile à quatre branches au centre de
// chaque losange), désaturé, plus sombre vers le plafond et vers le bas. Projection selon la normale dominante (monde).
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.54, 0.46, 0.57, 1.0);
uniform vec4 motif_color : source_color = vec4(0.64, 0.55, 0.68, 1.0);
uniform vec4 filet_color : source_color = vec4(0.59, 0.50, 0.62, 1.0);
uniform vec2 cell = vec2(0.46, 0.62);
uniform float bas_y = 1.0;       // sous cette hauteur : ombre portée du lambris
uniform float haut_y = 4.2;      // au-dessus : voile d'ombre du plafond
uniform float roughness : hint_range(0.0, 1.0) = 0.92;

varying vec3 world_pos;
varying vec3 world_nrm;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 an = abs(world_nrm);
	float u = an.x > an.z ? world_pos.z : world_pos.x;
	vec2 p = vec2(u, world_pos.y);
	// losanges décalés : deux grilles entrelacées
	vec2 q = p / cell;
	vec2 g1 = fract(q) - 0.5;
	vec2 g2 = fract(q + 0.5) - 0.5;
	float fw = fwidth(q.x) + fwidth(q.y) + 0.0001;
	float aa = clamp(1.0 - fw * 1.6, 0.0, 1.0);        // le motif s'estompe quand il devient plus fin que le pixel
	// petite étoile concave à quatre branches (astroïde) au centre de chaque losange ; fleuron rond entre les losanges
	vec2 pm = g1 * cell;
	float ast = sqrt(abs(pm.x)) + sqrt(abs(pm.y));
	float star = 1.0 - smoothstep(0.27, 0.27 + 0.05 + fw * 0.05, ast);
	vec2 pd = g2 * cell;
	float dot2 = 1.0 - smoothstep(0.022, 0.03 + fw * 0.01, length(pd));
	// treillis fin en diagonale (très discret)
	float d = abs(fract((q.x + q.y) * 0.5) - 0.5) * 2.0;
	float d2 = abs(fract((q.x - q.y) * 0.5) - 0.5) * 2.0;
	float lat = (1.0 - smoothstep(0.0, 0.025 + fw * 0.4, min(d, d2))) * 0.6;
	vec3 col = base_color.rgb;
	col = mix(col, filet_color.rgb, lat * aa);
	col = mix(col, motif_color.rgb, clamp(star + dot2 * 0.7, 0.0, 1.0) * aa);
	// ombrage vertical : bas du mur sous la cimaise, haut sous la corniche
	float low = smoothstep(bas_y - 0.2, bas_y + 1.2, world_pos.y);
	float high = 1.0 - smoothstep(haut_y, haut_y + 0.9, world_pos.y) * 0.5;
	col *= mix(0.6, 1.0, low) * high;
	ALBEDO = col;
	ROUGHNESS = roughness;
	SPECULAR = 0.25;
}
