@tool
class_name StyleMaterialsForet
extends RefCounted
## Matériaux partagés du kit organique provisoire de la Forêt de la peur (14 au total, un par « rôle »).
## Même shader « stylized_surface » que le Bureau des rêves, mais sans les réchauffements d'appliques (warm_*),
## qui n'ont aucun sens dehors. Palette : écorces bleu-gris / violet sombre, mousses et feuillages verts désaturés
## tirant vers le bleu, lueurs cyan froid, un seul accent chaud (la jeune fille), cadre de porte crème.
## Le kit réutilise aussi quelques matériaux existants : « or » (cadre de porte), « lune » (pierre de lune),
## « lin_creme » (peau), « lin_lavande » (cape), « bois_sombre » (cheveux), « verre_chaud », « bois_porte ».

const IDS := [
	"ecorce_foret", "ecorce_morte", "mousse", "feuillage_sombre", "feuillage_bleu", "pierre_mousse", "pierre_ruine",
	"plante_sombre", "champi_lueur", "nenuphar_lueur", "fleur_blanche", "chaud_fille", "ombre_foret", "creme_cadre",
]

## Ombre : opaque au cœur, de plus en plus transparente vers les bords (fresnel inversé) → silhouette floue.
const OMBRE_SHADER := """shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, unshaded;
uniform vec4 couleur : source_color = vec4(0.02, 0.02, 0.06, 1.0);
uniform float opacite = 0.92;
uniform float douceur = 1.6;
void fragment() {
	float f = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	ALBEDO = couleur.rgb;
	ALPHA = opacite * pow(f, douceur);
}
"""

static func _s(base: String, top: String, rough: float, extra := {}) -> ShaderMaterial:
	var m := StyleMaterials._surface(base, top, rough, extra)
	m.set_shader_parameter("warm_low", 0.0)
	m.set_shader_parameter("warm_strength", 0.0)
	return m

static func add(d: Dictionary) -> void:
	# --- bois
	d["ecorce_foret"] = _s("#5e4a58", "#4a3a50", 0.9, {"gradient_top": 14.0, "variation": 0.16, "variation_scale": 2.2, "wood": 0.5, "wood_freq": 13.0, "rim_strength": 0.22, "rim_power": 3.0, "rim_color": "#7088cc", "specular": 0.15})
	d["ecorce_morte"] = _s("#a39ca4", "#8e8896", 0.95, {"gradient_top": 8.0, "variation": 0.18, "variation_scale": 2.0, "wood": 0.7, "wood_freq": 9.0, "rim_strength": 0.2, "rim_power": 3.0, "rim_color": "#b8c4f0", "specular": 0.1})
	# --- végétal
	d["mousse"] = _s("#547c4c", "#6a9458", 0.95, {"gradient_top": 6.0, "variation": 0.2, "variation_scale": 3.0, "rim_strength": 0.26, "rim_power": 2.6, "rim_color": "#a0e8d0", "specular": 0.05})
	d["feuillage_sombre"] = _s("#3a6a4c", "#4e8660", 0.92, {"gradient_top": 14.0, "variation": 0.16, "variation_scale": 0.9, "rim_strength": 0.2, "rim_power": 2.6, "rim_color": "#78c4cc", "specular": 0.05})
	d["feuillage_bleu"] = _s("#4a8a7c", "#6cb09c", 0.9, {"gradient_top": 14.0, "variation": 0.16, "variation_scale": 0.8, "emission_color": "#3a8cb4", "emission_energy": 0.07, "rim_strength": 0.28, "rim_power": 2.4, "rim_color": "#a4eaf4", "specular": 0.05})
	d["plante_sombre"] = _s("#24433f", "#3a6c5c", 0.9, {"gradient_top": 2.0, "variation": 0.14, "variation_scale": 2.0, "rim_strength": 0.24, "rim_power": 2.6, "rim_color": "#84d8bc", "specular": 0.08})
	# --- pierre
	d["pierre_mousse"] = _s("#5e5c68", "#524f60", 0.88, {"gradient_top": 5.0, "variation": 0.14, "variation_scale": 1.5, "dirt": 0.25, "rim_strength": 0.16, "rim_power": 3.0, "rim_color": "#90a4d8", "specular": 0.2})
	d["pierre_ruine"] = _s("#74707e", "#656270", 0.85, {"gradient_top": 6.0, "variation": 0.12, "variation_scale": 1.2, "dirt": 0.3, "rim_strength": 0.18, "rim_power": 3.0, "rim_color": "#b4bcec", "specular": 0.25})
	# --- lueurs (champignons, nénuphars, fleurs) : cyan froid, un cœur plus lumineux
	d["champi_lueur"] = _s("#1d5c6c", "#2a7a88", 0.5, {"emission_color": "#4fe6ff", "emission_energy": 1.1, "core_boost": 1.0, "rim_strength": 0.4, "rim_power": 2.2, "rim_color": "#c4fbff", "specular": 0.3})
	d["nenuphar_lueur"] = _s("#1f4a48", "#2a625c", 0.6, {"emission_color": "#36c4d4", "emission_energy": 0.5, "rim_strength": 0.3, "rim_power": 2.4, "rim_color": "#a0f0f0", "specular": 0.25})
	d["fleur_blanche"] = _s("#cfdcf0", "#e8f0ff", 0.7, {"emission_color": "#a8d4ff", "emission_energy": 0.4, "rim_strength": 0.4, "rim_power": 2.2, "rim_color": "#ffffff", "specular": 0.1})
	# --- accent chaud (écharpe de la jeune fille) et cadre de porte crème
	d["chaud_fille"] = _s("#c27a45", "#c27a45", 0.8, {"emission_color": "#e08a3c", "emission_energy": 0.25, "rim_strength": 0.3, "rim_power": 2.4, "rim_color": "#ffd0a0", "specular": 0.1})
	d["creme_cadre"] = _s("#bcb09e", "#a89c8e", 0.6, {"gradient_top": 4.0, "variation": 0.07, "variation_scale": 1.0, "dirt": 0.2, "rim_strength": 0.15, "rim_color": "#f0e6d0", "specular": 0.3})
	# --- ombre : silhouette floue (shader en ligne)
	var sh := Shader.new()
	sh.code = OMBRE_SHADER
	var mo := ShaderMaterial.new()
	mo.shader = sh
	mo.render_priority = 1
	d["ombre_foret"] = mo
