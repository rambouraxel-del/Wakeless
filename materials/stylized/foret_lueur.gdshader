shader_type spatial;
// Orbe lumineux en sprite (feux follets, lueurs de nénuphars, fleurs-lanternes) : coeur vif + halo doux, additif,
// palpitation lente décalée selon la position (pas de hasard). Billboard.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform vec4 core_color : source_color = vec4(0.85, 1.0, 1.0, 1.0);
uniform vec4 halo_color : source_color = vec4(0.20, 0.90, 1.0, 1.0);
uniform float energy = 3.0;
uniform float halo_energy = 1.2;
uniform float core_size : hint_range(0.01, 0.5) = 0.12;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.35;
uniform float pulse_speed = 2.2;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;

varying float pulse;

void vertex() {
	vec3 center = MODEL_MATRIX[3].xyz;
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(sx, 0, 0, 0), vec4(0, sy, 0, 0), vec4(0, 0, 1, 0), vec4(0, 0, 0, 1));
	float ph = center.x * 1.7 + center.z * 2.3;
	pulse = 1.0 + pulse_amount * (0.65 * sin(TIME * pulse_speed + ph) + 0.35 * sin(TIME * pulse_speed * 2.7 + ph * 1.9));
}

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float core = exp(-pow(r / core_size, 2.0));
	float halo = pow(max(1.0 - r, 0.0), 2.6);
	vec3 c = core_color.rgb * core * energy + halo_color.rgb * halo * halo_energy;
	c *= pulse * intensity;
	ALBEDO = c;
	ALPHA = clamp(max(core, halo) * intensity, 0.0, 1.0);
}
