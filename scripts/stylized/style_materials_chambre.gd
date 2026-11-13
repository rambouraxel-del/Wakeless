@tool
class_name StyleMaterialsChambre
extends RefCounted
## Matériaux partagés supplémentaires de la chambre 107 et du couloir (finition esthétique). Utilise StyleMaterials._surface / _glow.
## Les 32 matériaux d'origine restent définis dans style_materials.gd. Palette désaturée (règle 60 / 30 / 10).
## Matériaux « de coque » (papier_peint, parquet_lames, moulure_lilas, flaque_lune) : utilisés par la coque de la chambre,
## pas par les modules ; les autres sont partagés par les modules (le test plafonne à 40 matériaux de modules).

static func add(d: Dictionary) -> void:
	# --- coque de la chambre
	var pp := ShaderMaterial.new()
	pp.shader = load(StyleMaterials.DIR + "papier_peint.gdshader")
	d["papier_peint"] = pp
	var pq := ShaderMaterial.new()
	pq.shader = load(StyleMaterials.DIR + "parquet_lames.gdshader")
	d["parquet_lames"] = pq
	d["moulure_lilas"] = StyleMaterials._surface("#7d7499", "#6f6790", 0.55, {"variation": 0.04, "rim_strength": 0.1, "rim_color": "#c9bfe8"})
	var fl := StandardMaterial3D.new()                      # flaque de clair de lune au sol (additive, très douce)
	fl.albedo_color = Color(0.45, 0.5, 0.9, 1.0)
	fl.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fl.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fl.vertex_color_use_as_albedo = true
	fl.cull_mode = BaseMaterial3D.CULL_DISABLED
	fl.no_depth_test = false
	d["flaque_lune"] = fl
	# --- tissus et objets (modules)
	d["rideau_velours"] = StyleMaterials._surface("#4a3068", "#3d2858", 0.95, {"variation": 0.05, "rim_color": "#a58bd8", "rim_strength": 0.3})
	d["lin_lavande"] = StyleMaterials._surface("#8c82b4", "#8379ab", 0.92, {"variation": 0.06, "variation_scale": 1.6, "rim_color": "#cfc6f0", "rim_strength": 0.22})
	d["lin_creme"] = StyleMaterials._surface("#e6d9c0", "#d8cbb4", 0.92, {"variation": 0.04, "rim_color": "#fff0d8", "rim_strength": 0.15})
	d["rose_lune"] = StyleMaterials._surface("#c597aa", "#b78a9d", 0.9, {"variation": 0.04, "rim_color": "#f0c8d6", "rim_strength": 0.25})
	d["abat_jour"] = StyleMaterials._glow("#d9954a", "#ff8a2e", 0.9)
	var vo := StandardMaterial3D.new()                      # voilage : toile translucide
	vo.albedo_color = Color(0.82, 0.8, 0.95, 0.33)
	vo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vo.cull_mode = BaseMaterial3D.CULL_DISABLED
	vo.roughness = 1.0
	vo.emission_enabled = true
	vo.emission = Color(0.35, 0.33, 0.55)
	vo.emission_energy_multiplier = 0.25
	d["voilage"] = vo
	d["tapis_prune"] = StyleMaterials._surface("#4e2e52", "#4e2e52", 0.97, {"variation": 0.05, "variation_scale": 2.5, "rim_strength": 0.04})
	var tb := ShaderMaterial.new()
	tb.shader = load(StyleMaterials.DIR + "tableau_nuit.gdshader")
	d["tableau_nuit"] = tb
	var mi := StandardMaterial3D.new()                      # miroir : verre argenté sombre
	mi.albedo_color = Color(0.5, 0.52, 0.72)
	mi.metallic = 0.7
	mi.roughness = 0.12
	mi.emission_enabled = true
	mi.emission = Color(0.2, 0.22, 0.45)
	mi.emission_energy_multiplier = 0.7
	d["miroir"] = mi
