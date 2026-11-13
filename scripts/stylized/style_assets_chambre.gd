@tool
class_name StyleAssetsChambre
extends RefCounted
## Modules supplémentaires de la chambre 107 et du couloir (finition esthétique). Même repère et mêmes outils que StyleAssets
## (StyleKit, ModuleBuilder, StyleAssets.M). Les modules existants restent dans style_assets.gd et y sont améliorés.
## Convention : origine au sol (ou au plan du mur z = 0 pour les modules muraux), face avant vers +z.

const GOLD := "or"

static func ids() -> PackedStringArray:
	return PackedStringArray([
		"rideaux_fenetre", "banquette_fenetre", "tableau_paysage", "tableau_vertical", "tableau_ovale", "miroir_mural",
		"chaise_bureau", "pantoufles", "lampe_sur_pied", "console_vase", "console_horloge", "plateau_service", "chaussures_porte",
		"porte_parapluie", "carton_nd", "tapis_couloir",
	])

static func make(id: String) -> ModuleBuilder:
	match id:
		"rideaux_fenetre": return rideaux_fenetre()
		"banquette_fenetre": return banquette_fenetre()
		"tableau_paysage": return tableau("tableau_paysage", 1.05, 0.76, 0)
		"tableau_vertical": return tableau("tableau_vertical", 0.56, 0.82, 1)
		"tableau_ovale": return tableau("tableau_ovale", 0.62, 0.8, 2)
		"miroir_mural": return miroir()
		"chaise_bureau": return chaise()
		"pantoufles": return pantoufles()
		"lampe_sur_pied": return lampe()
		"console_vase": return console("console_vase", false)
		"console_horloge": return console("console_horloge", true)
		"plateau_service": return plateau()
		"chaussures_porte": return chaussures()
		"porte_parapluie": return parapluie()
		"carton_nd": return carton()
		"tapis_couloir": return tapis_couloir()
	return null

static func M(n: String) -> Material:
	return StyleMaterials.get_mat(n)

static func P(arr: Array) -> PackedVector2Array:
	return StyleAssets.P(arr)

static func _ellipse(rx: float, ry: float, n: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		p.append(Vector2(cos(a) * rx, sin(a) * ry))
	return p

## Plan elliptique à UV normalisées (toile ovale).
static func _oval_plane(rx: float, ry: float, mat: Material) -> ArrayMesh:
	var poly := _ellipse(rx, ry, 28)
	var tris := Geometry2D.triangulate_polygon(poly)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, tris.size(), 3):
		for k in [0, 2, 1]:
			var p := poly[tris[i + k]]
			st.set_normal(Vector3(0, 0, 1))
			st.set_uv(Vector2((p.x + rx) / (rx * 2.0), 1.0 - (p.y + ry) / (ry * 2.0)))
			st.add_vertex(Vector3(p.x, p.y, 0))
	st.index()
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m

# ================================================================== chambre

## Rideaux lourds de la fenêtre (adossés à z = 0, centrés sur la fenêtre de 2,2 m) : tringle dorée à embouts, lambrequin
## festonné, deux panneaux de velours retenus par des embrasses, voilage translucide devant la vitre.
static func rideaux_fenetre() -> ModuleBuilder:
	var b := ModuleBuilder.new("rideaux_fenetre")
	var zr := 0.74
	b.add(StyleKit.cylinder(0.025, 4.9, M(GOLD), 10), ModuleBuilder.at(Vector3(-2.45, 4.52, zr), Vector3(0, 0, -90)))
	for x in [-2.5, 2.5]:
		b.add(StyleKit.sphere(0.06, M(GOLD), 10, 5), ModuleBuilder.at(Vector3(x, 4.52, zr)))
	for sd in [-1.0, 1.0]:
		var ax: float = sd * 2.25
		var x0: float = ax if sd < 0.0 else 1.42
		var x1: float = -1.42 if sd < 0.0 else ax
		b.add(StyleAssets._curtain(minf(x0, x1), maxf(x0, x1), 4.5, 0.02, zr + 0.02, 5, 0.06, M("rideau_velours"), 1.55, 0.3, 0.35, sd < 0.0))
		var tx: float = sd * 2.12
		b.add(StyleKit.torus(0.12, 0.016, M(GOLD), 14, 4), ModuleBuilder.at(Vector3(tx, 1.55, zr + 0.02), Vector3(90, 0, 0), Vector3(1.0, 1.1, 1.5)))
		b.add(StyleKit.lathe(P([[0.0, 0.0], [0.02, -0.02], [0.04, -0.12], [0.024, -0.22], [0.0, -0.27]]), 8, M(GOLD), false, false), ModuleBuilder.at(Vector3(tx - sd * 0.07, 1.44, zr + 0.1)))
	var val := StyleAssets._valance(5.0, 6, "rideau_velours")
	b.add(val[0], ModuleBuilder.at(Vector3(0, 4.72, zr + 0.06)))
	if val[1] != null:
		b.add(val[1], ModuleBuilder.at(Vector3(0, 4.72, zr + 0.048)))
	for k in range(0, 7):
		b.add(StyleKit.lathe(P([[0.0, 0.0], [0.016, -0.02], [0.03, -0.08], [0.018, -0.13], [0.0, -0.15]]), 8, M(GOLD), false, false), ModuleBuilder.at(Vector3(-2.5 + 5.0 * k / 6.0, 4.5, zr + 0.1)))
	# voilage : deux pans translucides de part et d'autre de la vitre, devant l'appui
	for sd in [-1.0, 1.0]:
		var vx0: float = 0.5 if sd > 0.0 else -1.55
		b.add(StyleAssets._curtain(vx0, vx0 + 1.05, 4.46, 0.7, 0.62, 4, 0.045, M("voilage"), -1.0, 0.5, 0.0, sd < 0.0, 0.004))
	return b

## Banquette de fenêtre sous l'appui (adossée à z = 0) : coffre de bois, assise de velours, trois coussins.
static func banquette_fenetre() -> ModuleBuilder:
	var b := ModuleBuilder.new("banquette_fenetre")
	b.box(Vector3(2.5, 0.38, 0.5), 0.05, "bois_sombre", Vector3(0, 0.25, 0.26), Vector3.ZERO, 1)
	b.box(Vector3(2.56, 0.04, 0.54), 0.02, GOLD, Vector3(0, 0.46, 0.27), Vector3.ZERO, 1)
	b.box(Vector3(2.4, 0.12, 0.46), 0.06, "rideau_velours", Vector3(0, 0.54, 0.26), Vector3.ZERO, 3)
	for x in [-1.1, 1.1]:
		b.add(StyleKit.sphere(0.04, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(x, 0.04, 0.26), Vector3.ZERO, Vector3(1, 0.7, 1)))
	StyleAssets._pillow(b, Vector3(0.42, 0.3, 0.12), "lin_creme", Vector3(-0.8, 0.74, 0.12), Vector3(-12, 8, 0))
	StyleAssets._pillow(b, Vector3(0.36, 0.3, 0.12), "lin_lavande", Vector3(-0.48, 0.72, 0.1), Vector3(-10, -6, 4))
	StyleAssets._pillow(b, Vector3(0.38, 0.28, 0.12), "rose_lune", Vector3(0.82, 0.72, 0.11), Vector3(-12, -10, -3))
	b.collide(Vector3(2.5, 0.6, 0.55), Vector3(0, 0.3, 0.27))
	return b

## Cadre doré avec toile de paysage nocturne. style 0 : paysage à cadre mouluré ; 1 : vertical simple ; 2 : ovale à nœud.
static func tableau(id: String, w: float, h: float, style: int) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	if style == 2:
		var rx := w * 0.5
		var ry := h * 0.5
		b.add(StyleKit.extrude(_ellipse(rx + 0.06, ry + 0.06, 32), 0.05, M(GOLD), 0.012), ModuleBuilder.at(Vector3(0, 0, 0.025)))
		b.add(StyleKit.extrude(_ellipse(rx + 0.012, ry + 0.012, 32), 0.054, M("pierre_sombre"), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.025)))
		b.add(_oval_plane(rx, ry, M("tableau_nuit")), ModuleBuilder.at(Vector3(0, 0, 0.0535)))
		b.add(StyleKit.extrude(StyleKit.star_outline(0.05, 0.02, 4), 0.02, M("or"), 0.004), ModuleBuilder.at(Vector3(0, ry + 0.1, 0.04)))
		b.add(StyleKit.torus(0.05, 0.012, M(GOLD), 10, 4), ModuleBuilder.at(Vector3(-0.03, ry + 0.04, 0.045), Vector3(90, 0, 0)))
		b.add(StyleKit.torus(0.05, 0.012, M(GOLD), 10, 4), ModuleBuilder.at(Vector3(0.03, ry + 0.04, 0.045), Vector3(90, 0, 0)))
	elif style == 1:
		StyleAssets._frame(b, w + 0.16, h + 0.16, 0.08, 0.05, Vector3(0, 0, 0.025))
	else:
		StyleAssets._frame(b, w + 0.24, h + 0.24, 0.12, 0.06, Vector3(0, 0, 0.03))
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				b.add(StyleKit.sphere(0.04, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(sx * (w * 0.5 + 0.12), sy * (h * 0.5 + 0.12), 0.06)))
		b.add(StyleKit.extrude(StyleKit.crescent_outline(0.06, 0.55), 0.03, M("etoile_or"), 0.006), ModuleBuilder.at(Vector3(0, h * 0.5 + 0.12, 0.07), Vector3(0, 0, 90)))
	b.cast_shadows = false
	return b

## Miroir ovale à cadre d'or, fronton croissant et étoile (adossé à z = 0), 0,7 × 1,3 m.
static func miroir() -> ModuleBuilder:
	var b := ModuleBuilder.new("miroir_mural")
	var rx := 0.36
	var ry := 0.62
	b.add(StyleKit.extrude(_ellipse(rx + 0.1, ry + 0.1, 36), 0.06, M(GOLD), 0.018), ModuleBuilder.at(Vector3(0, 0, 0.03)))
	b.add(StyleKit.extrude(_ellipse(rx + 0.02, ry + 0.02, 36), 0.064, M("pierre_sombre"), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.03)))
	b.add(StyleKit.extrude(_ellipse(rx, ry, 36), 0.066, M("miroir"), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.03)))
	for spec in [[Vector3(-0.1, 0.22, 0.0), 0.36, 0.034], [Vector3(0.0, 0.1, 0.0), 0.2, 0.016]]:
		b.add(StyleAssets._cube(Vector3(spec[2], spec[1], 0.002), M("verre_lune")), ModuleBuilder.at(Vector3(spec[0].x, spec[0].y, 0.0635), Vector3(0, 0, -28)))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.13, 0.55), 0.04, M("etoile_or"), 0.01), ModuleBuilder.at(Vector3(0, ry + 0.18, 0.04), Vector3(0, 0, 90)))
	b.add(StyleKit.extrude(StyleKit.star_outline(0.04, 0.016, 4), 0.03, M("or"), 0.005), ModuleBuilder.at(Vector3(0, ry + 0.32, 0.04)))
	for sx in [-1.0, 1.0]:
		b.add(StyleKit.sphere(0.035, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(sx * (rx + 0.1), 0.0, 0.06)))
	b.cast_shadows = false
	return b

## Chaise de bureau : assise de velours, dossier ajouré, pieds tournés (face +z = devant).
static func chaise() -> ModuleBuilder:
	var b := ModuleBuilder.new("chaise_bureau")
	b.box(Vector3(0.46, 0.08, 0.44), 0.03, "bois_sombre", Vector3(0, 0.44, 0), Vector3.ZERO, 1)
	b.box(Vector3(0.42, 0.07, 0.4), 0.03, "rideau_velours", Vector3(0, 0.5, 0.0), Vector3.ZERO, 2)
	for x in [-0.2, 0.2]:
		for z in [-0.18, 0.18]:
			StyleAssets._turn(b, [[0.03, 0.0], [0.022, 0.1], [0.034, 0.22], [0.024, 0.4], [0.028, 0.44]], "bois_sombre", Vector3(x, 0, z), 8)
		b.box(Vector3(0.045, 0.5, 0.04), 0.015, "bois_sombre", Vector3(x, 0.74, -0.2), Vector3(-6, 0, 0), 1)
	b.box(Vector3(0.46, 0.06, 0.04), 0.02, "bois_sombre", Vector3(0, 1.0, -0.225), Vector3(-6, 0, 0), 1)
	b.box(Vector3(0.38, 0.1, 0.03), 0.015, "bois_porte", Vector3(0, 0.82, -0.215), Vector3(-6, 0, 0), 1)
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.05, 0.55), 0.015, M("etoile_or"), 0.003), ModuleBuilder.at(Vector3(0, 0.82, -0.2), Vector3(-6, 0, 90)))
	b.collide(Vector3(0.5, 0.95, 0.48), Vector3(0, 0.47, 0))
	return b

## Pantoufles de feutre au pied du lit : une droite, une renversée (traces d'une vie).
static func pantoufles() -> ModuleBuilder:
	var b := ModuleBuilder.new("pantoufles")
	for spec in [[Vector3(-0.1, 0, 0), 8.0, false], [Vector3(0.12, 0, 0.1), -35.0, true]]:
		var T := ModuleBuilder.at(spec[0], Vector3(0, spec[1], 0))
		if spec[2]:
			T = T * Transform3D(Basis(Vector3.BACK, PI * 0.5 * 0.75), Vector3(0, 0.05, 0))
		b.add(StyleKit.rounded_box(Vector3(0.1, 0.022, 0.27), 0.01, M("bois_porte"), 1), T * Transform3D(Basis.IDENTITY, Vector3(0, 0.011, 0)))
		b.add(StyleKit.rounded_box(Vector3(0.095, 0.055, 0.15), 0.025, M("rose_lune"), 2), T * Transform3D(Basis.IDENTITY, Vector3(0, 0.045, 0.045)))
		b.add(StyleKit.rounded_box(Vector3(0.09, 0.05, 0.1), 0.02, M("lin_creme"), 1), T * Transform3D(Basis.IDENTITY, Vector3(0, 0.05, -0.06)))
	b.cast_shadows = false
	return b

## Lampe sur pied (fauteuil de lecture) : trépied tourné, abat-jour de tissu, lumière ambre.
static func lampe() -> ModuleBuilder:
	var b := ModuleBuilder.new("lampe_sur_pied")
	StyleAssets._turn(b, [[0.2, 0.0], [0.19, 0.03], [0.07, 0.07], [0.03, 0.14], [0.026, 1.25], [0.045, 1.3]], GOLD, Vector3.ZERO, 16)
	StyleAssets._turn(b, [[0.045, 0.45], [0.04, 0.5], [0.05, 0.55]], GOLD, Vector3.ZERO, 10)
	StyleAssets._turn(b, [[0.2, 1.28], [0.13, 1.62]], "abat_jour", Vector3.ZERO, 20, Vector3.ZERO, Vector3.ONE, false, true)
	b.add(StyleKit.torus(0.2, 0.008, M(GOLD), 20, 4), ModuleBuilder.at(Vector3(0, 1.28, 0)))
	b.add(StyleKit.sphere(0.022, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(0, 1.65, 0)))
	b.omni(Vector3(0, 1.4, 0), Color("#ffb066"), 1.2, 4.0, false)
	b.collide(Vector3(0.4, 1.6, 0.4), Vector3(0, 0.8, 0))
	return b

# ================================================================== couloir

## Console galbée adossée au mur (face +z), 0,9 × 0,32 m : plateau de marbre, pieds en S dorés, tiroir. Vase de fleurs
## séchées (lavande), ou pendulette à cadran avec bougie et petite lumière (`horloge`).
static func console(id: String, horloge: bool) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var D := 0.32
	b.box(Vector3(0.92, 0.05, D), 0.02, "pierre_claire", Vector3(0, 0.83, D * 0.5), Vector3.ZERO, 1)
	b.box(Vector3(0.94, 0.03, D + 0.02), 0.012, GOLD, Vector3(0, 0.795, D * 0.5), Vector3.ZERO, 1)
	b.box(Vector3(0.8, 0.12, D - 0.04), 0.03, "bois_sombre", Vector3(0, 0.72, D * 0.5 - 0.01), Vector3.ZERO, 1)
	b.add(StyleKit.sphere(0.018, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(0, 0.72, D - 0.015)))
	for x in [-0.4, 0.4]:
		_leg(b, x, D)
	b.box(Vector3(0.7, 0.025, 0.04), 0.01, GOLD, Vector3(0, 0.18, 0.06), Vector3.ZERO, 1)
	var ty := 0.855
	if horloge:
		# pendulette d'arche : socle, boîtier, cadran, aiguilles (arrêtée sur 10 h 10), bougie
		b.box(Vector3(0.3, 0.04, 0.16), 0.018, GOLD, Vector3(-0.12, ty + 0.02, 0.16), Vector3.ZERO, 1)
		b.add(StyleKit.extrude(StyleKit.arch_outline(0.24, 0.32, 14), 0.12, M("bois_sombre"), 0.025), ModuleBuilder.at(Vector3(-0.12, ty + 0.04, 0.16)))
		b.add(StyleKit.extrude(_circle(0.095, 22), 0.01, M(GOLD), 0.0), ModuleBuilder.at(Vector3(-0.12, ty + 0.2, 0.225)))
		b.add(StyleKit.extrude(_circle(0.08, 22), 0.012, M("lin_creme"), 0.0), ModuleBuilder.at(Vector3(-0.12, ty + 0.2, 0.226)))
		for spec in [[-60.0, 0.05], [60.0, 0.07]]:
			var a: float = deg_to_rad(spec[0])
			var l: float = spec[1]
			b.add(StyleAssets._cube(Vector3(0.008, l, 0.004), M("fer_sombre")), ModuleBuilder.at(Vector3(-0.12 + sin(a) * l * 0.5, ty + 0.2 + cos(a) * l * 0.5, 0.234), Vector3(0, 0, -spec[0])))
		b.add(StyleKit.sphere(0.04, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(-0.12, ty + 0.38, 0.16)))
		StyleAssets._turn(b, [[0.045, 0.0], [0.025, 0.02], [0.016, 0.07], [0.035, 0.1]], GOLD, Vector3(0.26, ty, 0.16), 10)
		b.add(StyleKit.cylinder(0.014, 0.09, M("lin_creme"), 8), ModuleBuilder.at(Vector3(0.26, ty + 0.1, 0.16)))
		b.add(StyleKit.lathe(P([[0.0, 0.0], [0.011, 0.015], [0.0, 0.05]]), 8, M("verre_chaud"), false, false), ModuleBuilder.at(Vector3(0.26, ty + 0.19, 0.16)))
		b.omni(Vector3(0.2, ty + 0.4, 0.3), Color("#ffb066"), 0.9, 3.0, false)
	else:
		# vase de grès, tiges de lavande séchée, deux livres
		StyleAssets._turn(b, [[0.045, 0.0], [0.07, 0.07], [0.085, 0.15], [0.05, 0.25], [0.04, 0.3], [0.055, 0.32]], "banniere", Vector3(-0.18, ty, 0.16), 14)
		b.add(StyleKit.torus(0.055, 0.008, M(GOLD), 12, 4), ModuleBuilder.at(Vector3(-0.18, ty + 0.31, 0.16)))
		for k in 7:
			var a := TAU * k / 7.0
			var lean := 9.0 + 6.0 * float(k % 3)
			var tip := Vector3(-0.18 + cos(a) * 0.1, ty + 0.62 + 0.04 * float(k % 2), 0.16 + sin(a) * 0.08)
			var base := Vector3(-0.18, ty + 0.3, 0.16)
			var mid := (base + tip) * 0.5
			var d := tip - base
			b.add(StyleKit.cylinder(0.004, d.length(), M("feuillage"), 4), Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), base))
			b.add(StyleKit.sphere(0.022, M("glycine"), 6, 3), ModuleBuilder.at(tip, Vector3.ZERO, Vector3(0.7, 1.7, 0.7)))
		StyleAssets._book(b, Vector3(0.2, ty + 0.02, 0.16), Vector3(0.22, 0.04, 0.16), "livre_b", Vector3(0, 8, 0), true)
		StyleAssets._book(b, Vector3(0.2, ty + 0.057, 0.16), Vector3(0.19, 0.034, 0.14), "livre_a", Vector3(0, -6, 0))
	b.collide(Vector3(0.94, 0.88, D + 0.02), Vector3(0, 0.44, D * 0.5))
	return b

static func _leg(b: ModuleBuilder, x: float, D: float) -> void:
	StyleAssets._turn(b, [[0.035, 0.0], [0.03, 0.08], [0.045, 0.18], [0.028, 0.35], [0.035, 0.5], [0.03, 0.78]], "bois_sombre", Vector3(x, 0, D * 0.5 + 0.0), 8)
	b.add(StyleKit.sphere(0.034, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(x, 0.03, D * 0.5), Vector3.ZERO, Vector3(1, 0.6, 1)))

static func _circle(r: float, n: int) -> PackedVector2Array:
	return StyleAssets._circle(r, n)

## Plateau de room-service posé devant une porte : plateau doré, cloche, tasse et soucoupe, serviette pliée, rose.
static func plateau() -> ModuleBuilder:
	var b := ModuleBuilder.new("plateau_service")
	b.add(StyleKit.cylinder(0.27, 0.025, M(GOLD), 28), ModuleBuilder.at(Vector3(0, 0.0, 0)))
	b.add(StyleKit.torus(0.27, 0.016, M(GOLD), 28, 5), ModuleBuilder.at(Vector3(0, 0.025, 0)))
	b.add(StyleKit.cylinder(0.24, 0.006, M("lin_creme"), 24), ModuleBuilder.at(Vector3(0, 0.025, 0)))
	StyleAssets._turn(b, [[0.12, 0.0], [0.11, 0.03], [0.085, 0.09], [0.04, 0.14], [0.012, 0.16]], GOLD, Vector3(-0.07, 0.031, 0.02), 18, Vector3.ZERO, Vector3.ONE, false, false)
	b.add(StyleKit.sphere(0.02, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(-0.07, 0.2, 0.02)))
	StyleAssets._turn(b, [[0.05, 0.0], [0.03, 0.01], [0.027, 0.012]], "lin_creme", Vector3(0.12, 0.031, 0.1), 14)
	StyleAssets._turn(b, [[0.03, 0.01], [0.034, 0.05], [0.036, 0.062]], "lin_creme", Vector3(0.12, 0.031, 0.1), 14, Vector3.ZERO, Vector3.ONE, false, false)
	b.add(StyleKit.torus(0.016, 0.004, M("lin_creme"), 8, 4), ModuleBuilder.at(Vector3(0.162, 0.06, 0.1), Vector3(90, 0, 0)))
	StyleAssets._cb(b, Vector3(0.12, 0.012, 0.09), "rose_lune", Vector3(0.12, 0.034, -0.12), Vector3(0, 18, 0))
	StyleAssets._cb(b, Vector3(0.12, 0.012, 0.045), "rose_lune", Vector3(0.12, 0.046, -0.13), Vector3(0, 18, 0))
	StyleAssets._turn(b, [[0.02, 0.0], [0.016, 0.05], [0.026, 0.1]], "voilage", Vector3(-0.1, 0.031, -0.14), 8, Vector3.ZERO, Vector3.ONE, true, false)
	b.add(StyleKit.sphere(0.03, M("rose_lune"), 8, 4), ModuleBuilder.at(Vector3(-0.1, 0.15, -0.14), Vector3.ZERO, Vector3(1, 0.8, 1)))
	b.add(StyleKit.cylinder(0.003, 0.1, M("feuillage"), 4), ModuleBuilder.at(Vector3(-0.1, 0.06, -0.14)))
	b.collide(Vector3(0.56, 0.12, 0.56), Vector3(0, 0.06, 0))
	b.cast_shadows = false
	return b

## Chaussures laissées devant la porte : une paire de souliers de cuir vernis, un soulier couché.
static func chaussures() -> ModuleBuilder:
	var b := ModuleBuilder.new("chaussures_porte")
	for spec in [[Vector3(-0.09, 0, 0), 4.0, false, "bois_porte"], [Vector3(0.09, 0, 0.03), -8.0, false, "bois_porte"], [Vector3(0.38, 0, 0.1), 70.0, true, "livre_a"]]:
		var T := ModuleBuilder.at(spec[0], Vector3(0, spec[1], 0))
		if spec[2]:
			T = T * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0.05, 0))
		var mat: String = spec[3]
		b.add(StyleKit.rounded_box(Vector3(0.095, 0.022, 0.29), 0.011, M("fer_sombre"), 1), T * Transform3D(Basis.IDENTITY, Vector3(0, 0.011, 0)))
		b.add(StyleKit.rounded_box(Vector3(0.09, 0.07, 0.17), 0.03, M(mat), 1), T * Transform3D(Basis.IDENTITY, Vector3(0, 0.055, 0.055)))
		b.add(StyleKit.rounded_box(Vector3(0.085, 0.055, 0.1), 0.026, M(mat), 1), T * Transform3D(Basis.IDENTITY, Vector3(0, 0.07, -0.07)))
		b.add(StyleKit.rounded_box(Vector3(0.09, 0.03, 0.05), 0.012, M("fer_sombre"), 1), T * Transform3D(Basis.IDENTITY, Vector3(0, 0.03, -0.12)))
		b.add(StyleKit.sphere(0.012, M(GOLD), 6, 3), T * Transform3D(Basis.IDENTITY, Vector3(0, 0.105, 0.0)))
	b.cast_shadows = false
	return b

## Porte-parapluie : fût de fer à bagues d'or, deux parapluies roulés (crosse en cane), collé au mur (face +z).
static func parapluie() -> ModuleBuilder:
	var b := ModuleBuilder.new("porte_parapluie")
	StyleAssets._turn(b, [[0.14, 0.0], [0.15, 0.04], [0.16, 0.45], [0.18, 0.62], [0.17, 0.66]], "fer_sombre", Vector3(0, 0, 0.2), 18, Vector3.ZERO, Vector3.ONE, true, false)
	b.add(StyleKit.torus(0.165, 0.014, M(GOLD), 18, 4), ModuleBuilder.at(Vector3(0, 0.6, 0.2)))
	b.add(StyleKit.torus(0.152, 0.012, M(GOLD), 18, 4), ModuleBuilder.at(Vector3(0, 0.1, 0.2)))
	b.add(StyleKit.torus(0.16, 0.012, M(GOLD), 18, 4), ModuleBuilder.at(Vector3(0, 0.3, 0.2)))
	for spec in [[Vector3(-0.045, 0.1, 0.17), Vector3(8, 0, 6), "banniere", 0.92], [Vector3(0.05, 0.1, 0.23), Vector3(-6, 0, -9), "rideau_velours", 0.86]]:
		var T := ModuleBuilder.at(spec[0], spec[1])
		var len: float = spec[3]
		b.add(StyleKit.lathe(P([[0.0, 0.0], [0.026, 0.05], [0.036, 0.3], [0.03, len * 0.8], [0.0, len]]), 8, M(spec[2]), false, false), T)
		b.add(StyleKit.cylinder(0.008, 0.18, M("bois_porte"), 6), T * Transform3D(Basis.IDENTITY, Vector3(0, len - 0.02, 0)))
		b.add(StyleKit.torus(0.04, 0.009, M("bois_porte"), 10, 4), T * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.04, len + 0.12, 0)))
		b.add(StyleKit.sphere(0.014, M(GOLD), 6, 3), T * Transform3D(Basis.IDENTITY, Vector3(0, len * 0.55, 0.03)))
	b.collide(Vector3(0.36, 0.7, 0.36), Vector3(0, 0.35, 0.2))
	return b

## Carton « Ne pas déranger » à accrocher à une poignée (origine au point d'accroche, pend vers -y) : carton rose lunaire
## arrondi, trou cerclé d'or, croissant doré ; pas de texte.
static func carton() -> ModuleBuilder:
	var b := ModuleBuilder.new("carton_nd")
	b.add(StyleKit.torus(0.03, 0.004, M(GOLD), 14, 4), ModuleBuilder.at(Vector3(0, -0.03, 0), Vector3(0, 0, 90)))
	var poly := StyleKit.arch_outline(0.11, 0.28, 10)
	b.add(StyleKit.extrude(poly, 0.008, M("rose_lune"), 0.002), ModuleBuilder.at(Vector3(0, -0.29, 0.0)))
	b.add(StyleKit.extrude(_circle(0.014, 10), 0.01, M("pierre_sombre"), 0.0), ModuleBuilder.at(Vector3(0, -0.04, 0.0)))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.028, 0.55), 0.004, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(0, -0.17, 0.006), Vector3(0, 0, 90)))
	b.cast_shadows = false
	return b

## Chemin de couloir : tapis prune à bande indigo, bordure dorée, médaillons en losange (4,5 m de long sur x).
static func tapis_couloir() -> ModuleBuilder:
	var b := ModuleBuilder.new("tapis_couloir")
	var L := 4.5
	var W := 1.9
	StyleAssets._cb(b, Vector3(L, 0.016, W), "banniere", Vector3(0, 0.008, 0))
	StyleAssets._cb(b, Vector3(L, 0.02, W - 0.16), "tapis_prune", Vector3(0, 0.01, 0))
	for s in [-1.0, 1.0]:
		StyleAssets._cb(b, Vector3(L, 0.024, 0.03), GOLD, Vector3(0, 0.012, s * (W * 0.5 - 0.1)))
		StyleAssets._cb(b, Vector3(L, 0.024, 0.016), GOLD, Vector3(0, 0.012, s * (W * 0.5 - 0.02)))
	# médaillon central en losange : filet d'or, champ ton sur ton, petite étoile brodée (mate)
	b.add(StyleKit.extrude(P([[-0.55, 0], [0, 0.3], [0.55, 0], [0, -0.3]]), 0.012, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0.024, 0), Vector3(-90, 0, 0)))
	b.add(StyleKit.extrude(P([[-0.5, 0], [0, 0.26], [0.5, 0], [0, -0.26]]), 0.014, M("rideau_velours"), 0.0), ModuleBuilder.at(Vector3(0, 0.025, 0), Vector3(-90, 0, 0)))
	b.add(StyleKit.extrude(StyleKit.star_outline(0.12, 0.045, 4), 0.012, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0.03, 0), Vector3(-90, 0, 0)))
	b.cast_shadows = false
	return b

# ================================================================== coque de la chambre 107 (appelée par le niveau)

static func _wm(axis: int, pos: float, inward: float, a: float, y: float, d: float) -> Vector3:
	return Vector3(pos + inward * d, y, a) if axis == 0 else Vector3(a, y, pos + inward * d)

static func _ws(axis: int, l: float, h: float, t: float) -> Vector3:
	return Vector3(t, h, l) if axis == 0 else Vector3(l, h, t)

static func _c(parts: Array, size: Vector3, mat: String, pos: Vector3) -> void:
	parts.append([StyleAssets._cube(size, M(mat)), Transform3D(Basis.IDENTITY, pos)])

static func _r(parts: Array, size: Vector3, r: float, mat: String, pos: Vector3, rot := Vector3.ZERO) -> void:
	parts.append([StyleKit.rounded_box(size, r, M(mat), 1), ModuleBuilder.at(pos, rot)])

## Lambris : soubassement à panneaux moulurés, cimaise (lilas et filet d'or), plinthe. Sur le mur (axe 0 : mur x = pos,
## longueur le long de z ; axe 1 : mur z = pos, longueur le long de x), de a0 à a1, en évitant les intervalles `skip`.
static func _wainscot(parts: Array, axis: int, pos: float, inward: float, a0: float, a1: float, skip := []) -> void:
	var runs := [[a0, a1]]
	for sk in skip:
		var nr := []
		for r in runs:
			if sk[1] <= r[0] or sk[0] >= r[1]:
				nr.append(r)
				continue
			if sk[0] > r[0]:
				nr.append([r[0], sk[0]])
			if sk[1] < r[1]:
				nr.append([sk[1], r[1]])
		runs = nr
	for r in runs:
		var lr: float = r[1] - r[0]
		var mid: float = (r[0] + r[1]) * 0.5
		if lr < 0.4:
			continue
		_c(parts, _ws(axis, lr, 1.0, 0.08), "bois_sombre", _wm(axis, pos, inward, mid, 0.5, 0.04))
		_c(parts, _ws(axis, lr, 0.17, 0.09), "bois_sombre", _wm(axis, pos, inward, mid, 0.085, 0.085 * 0.5 + 0.04))
		_c(parts, _ws(axis, lr, 0.028, 0.108), "moulure_lilas", _wm(axis, pos, inward, mid, 0.184, 0.054))
		_r(parts, _ws(axis, lr, 0.07, 0.11), 0.03, "moulure_lilas", _wm(axis, pos, inward, mid, 1.035, 0.055))
		_c(parts, _ws(axis, lr, 0.022, 0.126), "or", _wm(axis, pos, inward, mid, 1.078, 0.063))
		var n := maxi(1, int(round((lr - 0.12) / 1.0)))
		var st := 0.12
		var pw := (lr - st * (n + 1)) / n
		for k in n:
			var ac: float = r[0] + st + pw * 0.5 + k * (pw + st)
			var ph := 0.6
			parts.append([StyleKit.rounded_box(_ws(axis, pw, ph, 0.04), 0.02, M("bois_porte"), 1), ModuleBuilder.at(_wm(axis, pos, inward, ac, 0.6, 0.1))])
			for dy in [-1.0, 1.0]:
				_c(parts, _ws(axis, pw + 0.07, 0.034, 0.026), "moulure_lilas", _wm(axis, pos, inward, ac, 0.6 + dy * (ph * 0.5 + 0.017), 0.093))
			for da in [-1.0, 1.0]:
				_c(parts, _ws(axis, 0.034, ph, 0.026), "moulure_lilas", _wm(axis, pos, inward, ac + da * (pw * 0.5 + 0.017), 0.6, 0.093))
			if k % 2 == 0:
				parts.append([StyleKit.extrude(StyleKit.star_outline(0.035, 0.014, 4), 0.012, M("or"), 0.0), ModuleBuilder.at(_wm(axis, pos, inward, ac, 0.6, 0.123), Vector3(0, 90.0 if axis == 0 else 0.0, 0) if inward > 0.0 else Vector3(0, -90.0 if axis == 0 else 180.0, 0))])

## Cadre mouluré rectangulaire sur le papier peint (lilas, filet d'or intérieur, rosettes aux angles).
static func _wall_frame(parts: Array, axis: int, pos: float, inward: float, a: float, y0: float, y1: float, w: float) -> void:
	var h := y1 - y0
	var yc := (y0 + y1) * 0.5
	for dy in [-1.0, 1.0]:
		_c(parts, _ws(axis, w, 0.06, 0.03), "moulure_lilas", _wm(axis, pos, inward, a, yc + dy * (h * 0.5 - 0.03), 0.015))
		_c(parts, _ws(axis, w - 0.16, 0.014, 0.036), "or", _wm(axis, pos, inward, a, yc + dy * (h * 0.5 - 0.1), 0.018))
	for da in [-1.0, 1.0]:
		_c(parts, _ws(axis, 0.06, h - 0.12, 0.03), "moulure_lilas", _wm(axis, pos, inward, a + da * (w * 0.5 - 0.03), yc, 0.015))
		_c(parts, _ws(axis, 0.014, h - 0.2, 0.036), "or", _wm(axis, pos, inward, a + da * (w * 0.5 - 0.1), yc, 0.018))
		for dy in [-1.0, 1.0]:
			parts.append([StyleKit.sphere(0.035, M("or"), 8, 4), Transform3D(Basis.IDENTITY, _wm(axis, pos, inward, a + da * (w * 0.5 - 0.1), yc + dy * (h * 0.5 - 0.1), 0.03))])
	# frise : croissant et étoiles d'or au centre des cadres bas
	if h < 1.5:
		var rot_s := Vector3(0, 90.0 if axis == 0 else 0.0, 0) if inward > 0.0 else Vector3(0, -90.0 if axis == 0 else 180.0, 0)
		parts.append([StyleKit.extrude(StyleKit.crescent_outline(0.17, 0.55, 14), 0.02, M("etoile_or"), 0.005), ModuleBuilder.at(_wm(axis, pos, inward, a, yc, 0.025), rot_s) * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO)])
		for da in [-1.0, 1.0]:
			for k in [1, 2]:
				var rr: float = 0.06 / float(k)
				parts.append([StyleKit.extrude(StyleKit.star_outline(rr * 1.2, rr * 0.5, 4), 0.014, M("or"), 0.003), ModuleBuilder.at(_wm(axis, pos, inward, a + da * 0.4 * float(k) * (1.8 if w > 3.0 else 1.0), yc, 0.022), rot_s)])

## Corniche moulurée et denticules sous le plafond (5,0 m) le long d'un mur.
static func _cornice(parts: Array, axis: int, pos: float, inward: float, a0: float, a1: float) -> void:
	var l := a1 - a0
	var mid := (a0 + a1) * 0.5
	_r(parts, _ws(axis, l, 0.2, 0.3), 0.05, "moulure_lilas", _wm(axis, pos, inward, mid, 4.9, 0.15))
	_c(parts, _ws(axis, l, 0.028, 0.33), "or", _wm(axis, pos, inward, mid, 4.785, 0.165))
	_r(parts, _ws(axis, l, 0.06, 0.22), 0.025, "bois_sombre", _wm(axis, pos, inward, mid, 4.74, 0.11))
	var n := int(l / 0.2)
	for i in n:
		var a := a0 + 0.1 + i * (l - 0.2) / maxf(n - 1, 1)
		_c(parts, _ws(axis, 0.07, 0.07, 0.07), "moulure_lilas", _wm(axis, pos, inward, a, 4.69, 0.095))

## Coque de la chambre : parquet à lames, papier peint damassé, lambris à panneaux, cimaise, corniche à denticules, plafond
## à poutres et médaillon de lune, habillage du mur de la porte (fenêtre au nord), moulures murales, flaque de clair de lune.
static func room_shell(x0: float, x1: float, z0: float, z1: float) -> Array:
	var parts := []
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	_r(parts, Vector3(x1 - x0 + 1.0, 0.4, z1 - z0 + 0.5), 0.02, "parquet_lames", Vector3(cx, -0.2, cz - 0.25))
	_r(parts, Vector3(0.5, 5.6, z1 - z0 + 1.0), 0.03, "papier_peint", Vector3(x0 - 0.25, 2.8, cz - 0.5))
	_r(parts, Vector3(0.5, 5.6, z1 - z0 + 1.0), 0.03, "papier_peint", Vector3(x1 + 0.25, 2.8, cz - 0.5))
	_r(parts, Vector3(x1 - x0 + 1.0, 5.6, 0.5), 0.03, "papier_peint", Vector3(cx, 2.8, z0 - 0.25))
	_r(parts, Vector3(x1 - x0 + 1.0, 0.4, z1 - z0 + 1.0), 0.03, "voute_etoilee", Vector3(cx, 5.2, cz - 0.5))
	# mur sud (celui de la porte, côté chambre) : papier peint percé de l'arche, architrave
	for half in [false, true]:
		parts.append([StyleKit.extrude(StyleKit.arch_wall_half(x1 - x0, 5.0, 1.62, 3.08, half, 12), 0.06, M("papier_peint"), 0.0), Transform3D(Basis.IDENTITY, Vector3(cx, 0, z1 - 0.03))])
	parts.append([StyleKit.extrude(StyleKit.arch_frame_outline(1.62, 3.08, 0.17, 18), 0.09, M("moulure_lilas"), 0.02), Transform3D(Basis.IDENTITY, Vector3(cx, 0, z1 - 0.105))])
	parts.append([StyleKit.extrude(StyleKit.arch_frame_outline(1.66, 3.1, 0.026, 18), 0.1, M("or"), 0.0), Transform3D(Basis.IDENTITY, Vector3(cx, 0, z1 - 0.105))])
	# lambris sur les quatre murs (le mur sud évite l'arche), cimaise, plinthe
	_wainscot(parts, 0, x0, 1.0, z0, z1 - 0.06)
	_wainscot(parts, 0, x1, -1.0, z0, z1 - 0.06)
	_wainscot(parts, 1, z0, 1.0, x0, x1)
	_wainscot(parts, 1, z1 - 0.06, -1.0, x0, x1, [[cx - 1.1, cx + 1.1]])
	# moulures murales (cadres) : frises au-dessus des meubles, panneaux autour des tableaux et du miroir
	for a in [-9.4, -5.9]:
		_wall_frame(parts, 0, x0, 1.0, a, 3.15, 4.5, 1.7)
	_wall_frame(parts, 0, x1, -1.0, -7.5, 3.4, 4.55, 3.3)
	_wall_frame(parts, 0, x1, -1.0, -4.55, 1.5, 4.3, 1.3)
	_wall_frame(parts, 1, z0, 1.0, 28.1, 1.7, 4.4, 1.9)
	_wall_frame(parts, 1, z0, 1.0, 34.3, 1.5, 4.4, 1.9)
	_wall_frame(parts, 1, z1 - 0.06, -1.0, 28.6, 1.5, 4.4, 2.0)
	_wall_frame(parts, 1, z1 - 0.06, -1.0, 33.6, 1.5, 4.4, 2.0)
	# corniche
	_cornice(parts, 0, x0, 1.0, z0, z1)
	_cornice(parts, 0, x1, -1.0, z0, z1)
	_cornice(parts, 1, z0, 1.0, x0, x1)
	_cornice(parts, 1, z1 - 0.06, -1.0, x0, x1)
	# plafond : poutres (deux dans chaque sens) filetées d'or, caissons étoilés, médaillon de lune autour de la lanterne
	for bz in [-9.35, -5.05]:
		_r(parts, Vector3(x1 - x0, 0.24, 0.3), 0.04, "bois_porte", Vector3(cx, 4.88, bz))
		for s in [-1.0, 1.0]:
			_c(parts, Vector3(x1 - x0, 0.022, 0.026), "or", Vector3(cx, 4.765, bz + s * 0.12))
	for bx in [29.1, 33.6]:
		_r(parts, Vector3(0.3, 0.24, z1 - z0), 0.04, "bois_porte", Vector3(bx, 4.88, cz))
		for s in [-1.0, 1.0]:
			_c(parts, Vector3(0.026, 0.022, z1 - z0), "or", Vector3(bx + s * 0.12, 4.765, cz))
	# caissons : fond indigo moyen entre les poutres (le ciel étoilé reste visible autour)
	var xe := [29.1 - 0.15, 33.6 - 0.15, x1 - 0.3]
	for i in 3:
		for j in 3:
			var xa: float = [x0 + 0.3, 29.1 + 0.15, 33.6 + 0.15][i]
			var xb: float = xe[i]
			var za: float = [z0 + 0.3, -9.35 + 0.15, -5.05 + 0.15][j]
			var zb: float = [-9.35 - 0.15, -5.05 - 0.15, z1 - 0.3][j]
			_c(parts, Vector3(xb - xa, 0.01, zb - za), "mur_chambre", Vector3((xa + xb) * 0.5, 4.99, (za + zb) * 0.5))
	var mx := 31.0
	var mz := -7.2
	parts.append([StyleKit.cylinder(1.0, 0.035, M("bois_porte"), 36), Transform3D(Basis.IDENTITY, Vector3(mx, 4.965, mz))])
	parts.append([StyleKit.torus(1.0, 0.03, M("or"), 36, 5), Transform3D(Basis.IDENTITY, Vector3(mx, 4.96, mz))])
	parts.append([StyleKit.torus(0.7, 0.016, M("or"), 32, 4), Transform3D(Basis.IDENTITY, Vector3(mx, 4.955, mz))])
	parts.append([StyleKit.extrude(StyleKit.crescent_outline(0.34, 0.55), 0.03, M("etoile_or"), 0.008), ModuleBuilder.at(Vector3(mx + 0.05, 4.95, mz), Vector3(90, 0, 0))])
	for i in 8:
		var a := TAU * i / 8.0
		parts.append([StyleKit.extrude(StyleKit.star_outline(0.05, 0.02, 4), 0.016, M("or"), 0.003), ModuleBuilder.at(Vector3(mx + cos(a) * 0.85, 4.95, mz + sin(a) * 0.85), Vector3(90, 0, 0))])
	# flaque de clair de lune sous la fenêtre (quatre carreaux, additive)
	parts.append([flaque_lune(), Transform3D(Basis.IDENTITY, Vector3(cx, 0.052, z0))])
	return parts

## Flaque de clair de lune projetée par la fenêtre (origine : pied du mur nord, centre de la fenêtre) : trois colonnes de
## carreaux étirées vers le sud et glissant vers l'est, qui s'éteignent avec la distance. Matériau additif non éclairé.
static func flaque_lune() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := [[-1.08, -0.4], [-0.32, 0.32], [0.4, 1.08]]
	var rows := [[0.35, 1.25], [1.35, 2.35], [2.45, 3.5]]
	var shear := 0.38
	var base_a := [0.34, 0.26, 0.16]
	for ci in cols.size():
		for ri in rows.size():
			var c0: float = cols[ci][0]
			var c1: float = cols[ci][1]
			var r0: float = rows[ri][0]
			var r1: float = rows[ri][1]
			var a0: float = base_a[ri] * (1.0 - 0.18 * absf(float(ci) - 1.0))
			var a1: float = a0 * 0.55
			var pts := [Vector3(c0 + r0 * shear, 0, r0), Vector3(c1 + r0 * shear, 0, r0), Vector3(c1 + r1 * shear, 0, r1), Vector3(c0 + r1 * shear, 0, r1)]
			var cs := [a0, a0, a1, a1]
			for k in [0, 2, 1, 0, 3, 2]:
				st.set_color(Color(0.55, 0.6, 1.0, cs[k]))
				st.set_normal(Vector3.UP)
				st.add_vertex(pts[k])
	st.index()
	var m := st.commit()
	m.surface_set_material(0, M("flaque_lune"))
	return m

## Pilastres de l'entrée du couloir (x = début), uniques (les travées ne portent que leur pilastre +x), côtés nord et sud.
static func corridor_start_parts(x: float) -> Array:
	var parts := []
	for side in [-1.0, 1.0]:
		var zc: float = side * 2.85
		parts.append([StyleKit.rounded_box(Vector3(0.5, 4.0, 0.3), 0.06, M("pierre_claire"), 1), Transform3D(Basis.IDENTITY, Vector3(x, 2.0, zc))])
		parts.append([StyleKit.rounded_box(Vector3(0.62, 0.3, 0.4), 0.06, M("pierre_claire"), 2), Transform3D(Basis.IDENTITY, Vector3(x, 3.95, side * 2.8))])
		parts.append([StyleKit.rounded_box(Vector3(0.56, 0.06, 0.36), 0.02, M("or"), 1), Transform3D(Basis.IDENTITY, Vector3(x, 3.78, side * 2.81))])
	return parts
