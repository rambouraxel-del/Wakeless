@tool
class_name StyleMaterials
extends RefCounted
## Matériaux PARTAGÉS de la 3D stylisée (materials/stylized/*.tres). Une vingtaine de matériaux pour tout le Bureau des
## rêves : chaque mur, meuble ou ornement réutilise les mêmes (moins de changements d'état, rendu cohérent).
## `build_all()` les (re)crée et les enregistre (outil d'édition) ; `get_mat()` les charge en jeu.

const DIR := "res://materials/stylized/"
const SURFACE := DIR + "stylized_surface.gdshader"

static var _cache := {}

static func path_of(id: String) -> String:
	return DIR + id + ".tres"

static func get_mat(id: String) -> Material:
	if not _cache.has(id):
		_cache[id] = load(path_of(id))
	return _cache[id]

static func _surface(base: String, top: String, rough: float, extra := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SURFACE)
	m.set_shader_parameter("base_color", Color(base))
	m.set_shader_parameter("top_color", Color(top))
	m.set_shader_parameter("roughness", rough)
	m.set_shader_parameter("rim_power", 4.5)        # liseré fin par défaut
	for k in extra:
		var v = extra[k]
		m.set_shader_parameter(k, Color(v) if typeof(v) == TYPE_STRING else v)
	return m

static func _glow(color: String, emission: String, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.emission_enabled = true
	m.emission = Color(emission)
	m.emission_energy_multiplier = energy
	m.roughness = 0.3
	return m

static func _vista(moon: Vector2, seed: float, size: Vector2) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(DIR + "ciel_vue.gdshader")
	m.set_shader_parameter("moon_pos", moon)
	m.set_shader_parameter("seed", seed)
	m.set_shader_parameter("plane_size", size)
	return m

## Définition de tous les matériaux (id → matériau).
static func definitions() -> Dictionary:
	var d := {}
	# --- maçonnerie et enduits (palette 60/30/10 : indigo nuit en grands fonds, lavande poussiéreuse en tons moyens)
	d["mur_violet"] = _surface("#575184", "#29254f", 0.9, {"gradient_top": 17.0, "variation": 0.09, "variation_scale": 0.3, "rim_strength": 0.04, "foot_dark": 0.5, "foot_height": 1.7, "dirt": 0.14, "grain": 0.04, "specular": 0.2})
	d["mur_couloir"] = _surface("#4d4876", "#25214a", 0.9, {"gradient_top": 8.5, "variation": 0.08, "rim_strength": 0.04, "foot_dark": 0.45, "foot_height": 1.4, "dirt": 0.2, "grain": 0.05, "specular": 0.2})
	d["mur_chambre"] = _surface("#524e78", "#2b2850", 0.92, {"gradient_top": 4.6, "variation": 0.07, "rim_strength": 0.03, "foot_dark": 0.4, "foot_height": 1.2, "dirt": 0.18, "grain": 0.06, "specular": 0.15})
	d["pierre_claire"] = _surface("#a69db0", "#756e8e", 0.72, {"gradient_top": 17.0, "variation": 0.09, "variation_scale": 0.5, "rim_strength": 0.07, "rim_color": "#d6d0f0", "foot_dark": 0.3, "foot_height": 1.2, "dirt": 0.2, "grain": 0.04, "specular": 0.3})
	d["pierre_sombre"] = _surface("#241f48", "#1b1738", 0.6, {"variation": 0.07, "rim_strength": 0.06, "dirt": 0.15, "specular": 0.45, "fake_reflect": 0.25, "reflect_color": "#8a8ccf"})
	# --- métaux : l'or est un MÉTAL (reflet net, valeur sombre, creux), jamais un aplat jaune
	d["or"] = _surface("#9a7a42", "#7e6234", 0.3, {"metallic": 0.85, "specular": 0.8, "variation": 0.08, "variation_scale": 1.4, "rim_color": "#ffd9a0", "rim_strength": 0.5, "rim_power": 6.0, "fake_reflect": 1.3, "reflect_color": "#ffc98a", "foot_dark": 0.35, "foot_height": 0.5, "dirt": 0.35})
	d["fer_sombre"] = _surface("#241f3a", "#241f3a", 0.4, {"metallic": 0.7, "rim_strength": 0.2, "rim_power": 5.0, "rim_color": "#8f93d8", "fake_reflect": 0.6, "reflect_color": "#8f93d8"})
	# --- bois et tissus
	d["bois_sombre"] = _surface("#35223f", "#2a1b35", 0.55, {"variation": 0.1, "variation_scale": 1.2, "rim_strength": 0.06, "wood": 0.8, "wood_freq": 11.0, "specular": 0.5, "fake_reflect": 0.25, "reflect_color": "#c8a0a0", "dirt": 0.2})
	d["bois_porte"] = _surface("#472b52", "#3a2447", 0.5, {"variation": 0.08, "variation_scale": 1.5, "rim_strength": 0.07, "wood": 0.9, "wood_freq": 8.0, "specular": 0.5, "fake_reflect": 0.3, "reflect_color": "#e0b098", "dirt": 0.25})
	d["velours"] = _surface("#4e3487", "#3b2870", 0.95, {"rim_color": "#a98cf0", "rim_strength": 0.55, "rim_power": 1.8, "specular": 0.05})
	d["tissu_etoile"] = _surface("#2a2268", "#241d5a", 0.95, {"star_density": 0.28, "star_scale": 4.0, "rim_strength": 0.2, "rim_power": 2.2, "rim_color": "#8a80e0", "specular": 0.05, "star_color": "#e0c080", "star_glow": 0.35, "variation": 0.1})
	d["banniere"] = _surface("#241c58", "#1c1646", 0.95, {"rim_strength": 0.12, "rim_power": 2.5, "specular": 0.05, "variation": 0.1})
	d["tapis"] = _surface("#40285f", "#40285f", 0.98, {"variation": 0.1, "variation_scale": 2.0, "rim_strength": 0.05, "specular": 0.03, "dirt": 0.15})
	d["draps"] = _surface("#d6cfe6", "#c4bcdc", 0.95, {"rim_strength": 0.05, "specular": 0.04, "variation": 0.07, "variation_scale": 2.4, "grain": 0.04})
	d["parquet"] = _surface("#473447", "#473447", 0.5, {"variation": 0.12, "variation_scale": 2.0, "rim_strength": 0.03, "wood": 0.9, "wood_dir": Vector3(1, 0, 0), "wood_freq": 14.0, "pool": Vector4(31.35, -9.5, 1.0, 1.5), "pool_rot": 0.0, "pool_strength": 0.75, "specular": 0.5, "fake_reflect": 0.35, "reflect_color": "#d8b0a0", "dirt": 0.2})
	d["livre_a"] = _surface("#6a2e4a", "#6a2e4a", 0.7, {"specular": 0.3})
	d["livre_b"] = _surface("#2c3a70", "#2c3a70", 0.7, {"specular": 0.3})
	d["livre_c"] = _surface("#2c5d5e", "#2c5d5e", 0.7, {"specular": 0.3})
	# --- végétal
	d["glycine"] = _surface("#a290e0", "#7a62c0", 0.9, {"gradient_bottom": -1.2, "gradient_top": 0.0, "emission_color": "#6a54c0", "emission_energy": 0.1, "rim_strength": 0.2, "rim_color": "#d8c8f8", "variation": 0.14})
	d["feuillage"] = _surface("#364372", "#46528a", 0.9, {"rim_strength": 0.12, "variation": 0.14})
	d["fleur_arbre"] = _surface("#bda8e6", "#9a86d4", 0.9, {"emission_color": "#7a64c8", "emission_energy": 0.12, "rim_strength": 0.22, "rim_color": "#e8dcff", "variation": 0.14})
	d["ecorce"] = _surface("#33263e", "#33263e", 0.85, {"variation": 0.18, "variation_scale": 3.0, "wood": 0.6, "wood_freq": 16.0})
	# --- lumières (verres émissifs : modérés, seule l'ampoule et le coeur de lune approchent le blanc)
	d["verre_chaud"] = _glow("#6a4c30", "#ffa850", 0.7)
	d["verre_lune"] = _glow("#3a3a60", "#aab0ff", 0.7)
	d["lune"] = _glow("#4a4a70", "#c4c8f4", 0.95)
	d["etoile_or"] = _glow("#e8c47a", "#f0b050", 0.8)
	# --- sols, voûtes, paysages
	var ms := ShaderMaterial.new()
	ms.shader = load(DIR + "marbre_etoile.gdshader")
	ms.set_shader_parameter("center", Vector2(0.0, 6.5))
	ms.set_shader_parameter("ring_radius", 3.2)
	ms.set_shader_parameter("pool_x", Vector4(-6.2, 6.2, -6.2, 6.2))        # flaques de lune des grandes fenêtres nord et sud
	ms.set_shader_parameter("pool_z", Vector4(-6.0, -6.0, 6.5, 6.5))
	ms.set_shader_parameter("pool_rot", Vector4(0.35, -0.35, -0.35, 0.35))
	ms.set_shader_parameter("pool_hs", Vector2(1.5, 2.6))
	ms.set_shader_parameter("pool_strength", 0.45)
	d["marbre_atrium"] = ms
	var mc := ShaderMaterial.new()
	mc.shader = load(DIR + "marbre_etoile.gdshader")
	mc.set_shader_parameter("center", Vector2(17.85, 0.0))
	mc.set_shader_parameter("repeat_x", 9.0)
	mc.set_shader_parameter("ring_radius", 1.5)
	mc.set_shader_parameter("tile", 1.5)
	d["marbre_couloir"] = mc
	var pv := ShaderMaterial.new()
	pv.shader = load(DIR + "plafond_etoile.gdshader")
	d["voute_etoilee"] = pv
	d["vue_nuit_a"] = _vista(Vector2(0.68, 0.78), 1.0, Vector2(4.0, 9.0))
	d["vue_nuit_b"] = _vista(Vector2(2.0, 2.0), 2.0, Vector2(4.0, 9.0))          # sans lune visible
	d["vue_nuit_c"] = _vista(Vector2(0.3, 0.7), 3.0, Vector2(3.0, 3.6))           # fenêtre de chambre
	StyleMaterialsAtrium.add(d)       # matériaux propres à l'atrium
	StyleMaterialsChambre.add(d)      # matériaux propres à la chambre et au couloir
	return d

## (Re)crée et enregistre tous les matériaux. Renvoie le nombre écrit.
static func build_all() -> int:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var n := 0
	var defs := definitions()
	for id in defs:
		if ResourceSaver.save(defs[id], path_of(id)) == OK:
			n += 1
	_cache.clear()
	return n
