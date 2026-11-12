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
	# --- maçonnerie et enduits
	d["mur_violet"] = _surface("#6c4ea6", "#46327f", 0.85, {"gradient_top": 16.0, "variation": 0.07, "rim_strength": 0.08})
	d["mur_couloir"] = _surface("#4f3d86", "#33285f", 0.85, {"gradient_top": 9.0, "variation": 0.06, "rim_strength": 0.08})
	d["mur_chambre"] = _surface("#5a4a8e", "#45376f", 0.9, {"gradient_top": 5.0, "variation": 0.05, "rim_strength": 0.06})
	d["pierre_claire"] = _surface("#8d7cc8", "#7564b3", 0.7, {"gradient_top": 16.0, "variation": 0.06, "rim_strength": 0.14})
	d["pierre_sombre"] = _surface("#2d2352", "#2a2049", 0.65, {"variation": 0.05, "rim_strength": 0.1})
	# --- métaux
	d["or"] = _surface("#e5b466", "#d9a557", 0.3, {"metallic": 0.65, "specular": 0.7, "variation": 0.04, "rim_color": "#ffd890", "rim_strength": 0.35, "emission_color": "#b07a30", "emission_energy": 0.18})
	d["fer_sombre"] = _surface("#2b2440", "#2b2440", 0.45, {"metallic": 0.5, "rim_strength": 0.15, "rim_color": "#9a86d8"})
	# --- bois et tissus
	d["bois_sombre"] = _surface("#3d2549", "#33203f", 0.6, {"variation": 0.1, "variation_scale": 1.2, "rim_strength": 0.1})
	d["bois_porte"] = _surface("#4b2d62", "#41285a", 0.55, {"variation": 0.08, "variation_scale": 1.5, "rim_strength": 0.12})
	d["velours"] = _surface("#5d3c9a", "#4c3187", 0.95, {"rim_color": "#b994ff", "rim_strength": 0.3})
	d["tissu_etoile"] = _surface("#33277a", "#2c2269", 0.9, {"star_density": 0.28, "star_scale": 4.0, "rim_strength": 0.2, "rim_color": "#9a7aff"})
	d["banniere"] = _surface("#2c2163", "#261c57", 0.9, {"rim_strength": 0.15})
	d["tapis"] = _surface("#4a2a6e", "#4a2a6e", 0.95, {"variation": 0.04, "rim_strength": 0.05})
	d["draps"] = _surface("#d9d0f2", "#cbbfee", 0.85, {"rim_strength": 0.1})
	d["parquet"] = _surface("#53364c", "#53364c", 0.55, {"variation": 0.12, "variation_scale": 2.0, "rim_strength": 0.05})
	d["livre_a"] = _surface("#7a2e4e", "#7a2e4e", 0.7)
	d["livre_b"] = _surface("#2f3f7a", "#2f3f7a", 0.7)
	d["livre_c"] = _surface("#2f6a6a", "#2f6a6a", 0.7)
	# --- végétal
	d["glycine"] = _surface("#b08ef0", "#8a66d6", 0.9, {"gradient_bottom": -1.2, "gradient_top": 0.0, "emission_color": "#7a4ed8", "emission_energy": 0.35, "rim_strength": 0.3, "rim_color": "#e0c8ff"})
	d["feuillage"] = _surface("#3e4a7e", "#4d5a94", 0.9, {"rim_strength": 0.15})
	d["fleur_arbre"] = _surface("#c39cf5", "#a57ee6", 0.9, {"emission_color": "#8e5ee8", "emission_energy": 0.45, "rim_strength": 0.35, "rim_color": "#f0dcff"})
	d["ecorce"] = _surface("#3a2a46", "#3a2a46", 0.85, {"variation": 0.15, "variation_scale": 3.0})
	# --- lumières (verres émissifs)
	d["verre_chaud"] = _glow("#ffd59a", "#ffb35c", 2.6)
	d["verre_lune"] = _glow("#e5dcff", "#c9b8ff", 1.8)
	d["lune"] = _glow("#f4eeff", "#e6dcff", 2.4)
	d["etoile_or"] = _glow("#ffd98a", "#ffc25a", 1.6)
	# --- sols, voûtes, paysages
	var ms := ShaderMaterial.new()
	ms.shader = load(DIR + "marbre_etoile.gdshader")
	ms.set_shader_parameter("center", Vector2(0.0, 6.5))
	ms.set_shader_parameter("ring_radius", 3.2)
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
