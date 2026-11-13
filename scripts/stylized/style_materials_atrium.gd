@tool
class_name StyleMaterialsAtrium
extends RefCounted
## Matériaux partagés supplémentaires de l'atrium (finition esthétique). Utilise StyleMaterials._surface / _glow.
## Les 32 matériaux d'origine restent définis dans style_materials.gd.

static func add(d: Dictionary) -> void:
	# --- boiseries, enduits, moulures
	d["boiserie_prune"] = StyleMaterials._surface("#473052", "#3a2646", 0.55, {"gradient_top": 4.0, "variation": 0.12, "variation_scale": 1.6, "rim_strength": 0.14, "rim_color": "#a58ae0"})
	d["enduit_panneau"] = StyleMaterials._surface("#4a3d72", "#3b3162", 0.9, {"gradient_top": 18.0, "variation": 0.07, "variation_scale": 0.5, "rim_strength": 0.06})
	d["moulure_pierre"] = StyleMaterials._surface("#8a80a8", "#7a709a", 0.62, {"gradient_top": 18.0, "variation": 0.05, "rim_strength": 0.16, "rim_color": "#c9bfee"})
	d["or_vieilli"] = StyleMaterials._surface("#b38a47", "#a27c3e", 0.38, {"metallic": 0.7, "specular": 0.7, "variation": 0.06, "rim_color": "#ffd890", "rim_strength": 0.3, "emission_color": "#8a5e24", "emission_energy": 0.1})
	# --- tissus
	# --- marbre à veines crème (comptoir)
	var mv := ShaderMaterial.new()
	mv.shader = load(StyleMaterials.DIR + "marbre_veine.gdshader")
	d["marbre_comptoir"] = mv
	# --- végétal : fleurs étagées, glycines, feuilles
	d["fleur_lavande"] = StyleMaterials._surface("#b9a4f0", "#a28ae2", 0.85, {"emission_color": "#7a58d8", "emission_energy": 0.1, "rim_strength": 0.25, "rim_color": "#f0e4ff"})
	d["fleur_rose"] = StyleMaterials._surface("#e8b0c6", "#d89cb4", 0.85, {"emission_color": "#c0587e", "emission_energy": 0.1, "rim_strength": 0.25, "rim_color": "#fff0f4"})
	# --- petites lumières décoratives (modérées)
