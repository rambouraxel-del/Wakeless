extends SceneTree
## Édition de départ de « La Forêt de la peur » (prototype jouable) : terrain façonné par points de contrôle, parcours en
## 5 zones, énigmes, collisions. Toutes les positions (mètres) sont ÉCRITES ICI ; rien n'est généré au lancement.
##   godot --headless -s tools/authoring/build_foret_peur.gd
## Écrit scenes/levels/foret_de_la_peur.tscn et ses données cuites (scenes/levels/data/foret_peur/*.res).
## Une fois la scène enregistrée, elle se modifie à la main dans l'éditeur Godot.
##
## Contrat de dimensions des substituts (à respecter par les modules de B pour un remplacement transparent) : origine au sol,
## centré ; arbres 9/11/13,5 m (collision cylindre r 0,55) ; arbre_echasses 8 m (r 1,0) ; arbre_ancien 18 m (r 1,9) ; tronc_couche
## 6 m d'axe Z, r 0,38 ; souche r 0,6 h 0,55 ; racines_arche 3 m de large (pieds à x ±1,3) ; ruine_porte_lune 5 m de large, pieds
## à x ±2,1, ouverture 3,4 m, pivots VantailG (x −1,5) / VantailD (x +1,5) ; cadre_porte_reve ouverture 1,6 × 2,5, face avant +Z ;
## fleur_lanterne : nœud « Corolle » (+ lumière enfant) à 1 m ; piedestal_lune : nœud « Pierre » à 1,35 m.
##
## Repère : x vers l'est, z vers le sud (le parcours va vers −Z, le nord), y vers le haut. Sol d'arrivée = 0.
##   Zone 1 lisière          z +12 → −22   point d'arrivée `depart` (0, 3.6), cadre de porte à (0, 8.6)
##   Zone 2 jeune fille      z −18 → −30   souche (−6.2, −23.6)
##   Zone 3 marais           z −30 → −64   étang (eau à y = −0,05) : passerelle de troncs (z −34,4 → −43,1) vers l'îlot
##                                          (0, −45,4) ; fleurs W (−13,5, −40,5), E (13,5, −41,5), îlot (−2,2, −46) ;
##                                          pont de racines de l'îlot à la rive nord (z −48,6 → −60,9)
##   Zone 4 bois noir        z −64 → −108  impasses E (13, −78) et E (13,2, −99,6) ; ruine latérale W (−17, −87,5)
##   Zone 5 porte + clairière  porte de lune z −108 ; clairière centrée (0, −128) ; porte « Se réveiller » (8,5, −127,5)
## Kit organique de Sonnet B : `_prop(...)` instancie assets/stylized/modules/<id>.tscn s'il existe, sinon un substitut simple
## aux bonnes dimensions (contrat de dimensions dans `_substitute`).

const DATA := "res://scenes/levels/data/foret_peur/"
const MOD := "res://assets/stylized/modules/"
const SCENE_OUT := "res://scenes/levels/foret_de_la_peur.tscn"

# ---------------------------------------------------------------- terrain : grille 0,5 m
const CS := 0.5
const X0 := -40.0
const Z0 := 14.0
const NX := 161                      # x −40 … +40
const NZ := 333                      # z +14 … −152
const WATER_Y := -0.05               # plan d'eau, hauteur FIXE
const LAND := 0.25                   # niveau des rives du marais
const DECK_Y := 0.32                 # dessus de la passerelle et du pont
const CORR_X := 1.5                  # demi-largeur du couloir de la passerelle / du pont
const BED_Y := -1.65

# profil d'altitude du chemin selon z : [z, y]
const ELEV := [[14.0, 0.0], [0.0, 0.0], [-14.0, 0.1], [-22.0, 0.9], [-30.0, 0.35], [-34.0, LAND], [-64.0, LAND],
	[-70.0, 0.45], [-80.0, 1.0], [-96.0, 1.7], [-108.0, 2.1], [-114.0, 2.1], [-125.0, 2.4], [-152.0, 3.2]]

# axe du chemin principal : [x, z, demi-largeur du sol praticable]
const PATH := [[0.0, 12.0, 6.5], [0.0, 3.0, 6.0], [0.0, -6.0, 4.5], [-1.5, -14.0, 4.0], [-3.0, -20.0, 3.8], [-4.0, -25.0, 4.5],
	[-2.0, -31.0, 4.0], [0.0, -36.0, 4.0], [0.0, -62.0, 3.0], [1.5, -68.0, 2.6], [-1.0, -76.0, 2.4], [2.0, -85.0, 2.3],
	[1.0, -92.0, 2.3], [-1.0, -99.0, 2.2], [0.0, -106.0, 1.9], [0.0, -110.0, 1.9], [0.0, -116.0, 3.0], [0.0, -124.0, 5.0]]

# embranchements : [z de départ sur le chemin, [x, z] ..., rayon]  (x du départ = x du chemin à ce z)
const BRANCHES := [
	["lisiere_ouest", -14.0, [[-7.0, -15.5], [-12.0, -17.0]], 1.6],
	["impasse_est_1", -73.0, [[7.0, -74.5], [11.0, -77.0]], 1.6],
	["ruine_ouest", -83.0, [[-8.0, -84.5], [-13.0, -86.0]], 1.7],
	["impasse_est_2", -93.0, [[7.0, -95.5], [11.5, -98.5]], 1.6]]
# poches circulaires : [x, z, rayon]
const POCKETS := [[0.0, 2.0, 8.0], [-5.0, -25.0, 8.0], [-13.0, -17.5, 3.4], [13.0, -78.2, 2.6], [-17.0, -87.5, 5.5],
	[13.2, -99.6, 2.6], [0.0, -128.0, 16.0]]
const MARSH_BOX := [0.0, -47.0, 22.0, 17.0, 5.0]       # cx, cz, demi-largeurs x et z, arrondi

# sentiers visibles (rubans) : tracés explicites en plus du chemin principal
const TRAILS := [
	["Sentier_marais_ouest", [[-2.0, -33.0], [-7.0, -35.5], [-12.0, -37.5], [-13.5, -40.5]]],
	["Sentier_marais_est", [[2.0, -33.0], [7.0, -35.0], [12.0, -38.0], [13.5, -41.5]]],
	["Sentier_lisiere", [[-1.5, -14.0], [-7.0, -15.5], [-12.0, -17.0]]],
	["Sentier_impasse_1", [[0.0, -73.0], [7.0, -74.5], [11.0, -77.0]]],
	["Sentier_ruine", [[-1.0, -83.0], [-8.0, -84.5], [-13.0, -86.0], [-16.5, -87.0]]],
	["Sentier_impasse_2", [[1.5, -93.0], [7.0, -95.5], [11.5, -98.5]]]]

# ---------------------------------------------------------------- arbres
# murs de troncs : z choisis à la main de chaque côté ; x trouvé en s'écartant du chemin jusqu'à la distance voulue du bord
const NEAR_L := [9.0, 4.5, -0.5, -5.0, -10.5, -15.0, -20.0, -25.5, -30.0, -34.0, -38.5, -43.0, -48.0, -53.0, -57.5, -62.0,
	-66.5, -71.0, -76.5, -81.0, -86.0, -90.5, -95.0, -100.0, -105.0, -110.0, -115.0, -120.0, -126.0, -132.0, -138.0, -143.0, -147.0]
const NEAR_R := [7.0, 2.0, -3.5, -8.0, -13.0, -18.5, -23.0, -28.0, -32.0, -37.0, -41.0, -46.0, -52.0, -56.0, -60.0, -64.0,
	-69.0, -73.5, -79.0, -84.0, -89.0, -93.0, -98.0, -103.5, -108.5, -113.0, -118.0, -124.0, -129.0, -135.0, -140.0, -145.0]
const FAR_L := [6.0, -4.0, -14.0, -23.0, -33.0, -44.0, -55.0, -65.0, -75.0, -85.0, -95.0, -105.0, -118.0, -130.0, -142.0]
const FAR_R := [3.0, -9.0, -19.0, -29.0, -40.0, -50.0, -61.0, -71.0, -81.0, -91.0, -101.0, -112.0, -125.0, -137.0, -147.0]
const WALL_IDS := ["arbre_tordu_c", "arbre_tordu_a", "arbre_tordu_c", "arbre_tordu_b", "arbre_mort", "arbre_tordu_c", "arbre_tordu_b"]
const OFFS := [[0.0, 0.0], [2.1, 1.3], [-1.8, 2.2], [1.2, -2.4], [-2.6, -1.1], [3.4, -1.0], [-0.4, 3.6]]
# masses sur le sol praticable : [x, z, nombre (3–7), écartement, rotation °, [espèces]]
const A_ := ["arbre_tordu_a", "arbre_tordu_b", "arbre_tordu_a"]
const B_ := ["arbre_tordu_b", "arbre_tordu_c", "arbre_tordu_a", "arbre_mort"]
const MASSES := [
	[-7.4, 7.0, 4, 1.5, 20.0, A_], [7.6, 5.5, 5, 1.6, 80.0, B_], [-7.4, -4.0, 3, 1.4, 140.0, A_], [6.4, -8.5, 5, 1.6, 200.0, B_],
	[-9.0, -9.5, 4, 1.4, 10.0, B_], [5.0, -18.0, 4, 1.5, 60.0, A_], [-9.5, -22.5, 5, 1.7, 100.0, B_], [4.5, -28.5, 3, 1.5, 300.0, A_],
	[-10.5, -29.0, 4, 1.5, 250.0, A_], [7.8, -64.0, 5, 1.6, 340.0, B_], [-7.2, -66.0, 4, 1.5, 30.0, B_],
	[6.5, -68.5, 3, 1.4, 90.0, B_], [-8.6, -77.0, 5, 1.6, 170.0, B_], [7.6, -83.5, 5, 1.6, 220.0, B_],
	[-7.0, -91.0, 4, 1.5, 120.0, B_], [8.4, -87.5, 3, 1.4, 50.0, B_], [-7.2, -97.5, 5, 1.6, 270.0, B_], [6.0, -104.5, 4, 1.5, 310.0, B_],
	[-7.0, -103.5, 3, 1.4, 15.0, B_],
	[-12.5, -120.0, 5, 1.8, 40.0, A_], [12.0, -118.0, 4, 1.6, 160.0, A_], [11.5, -136.0, 5, 1.8, 250.0, A_], [-13.0, -134.0, 4, 1.6, 330.0, A_]]
# arbres à racines-échasses dans l'eau et sur les rives : [x, z, rotation, échelle]
const WATER_TREES := [[-9.0, -52.0, 20.0, 1.0], [-14.0, -55.5, 140.0, 1.1], [8.5, -53.5, 250.0, 1.0], [13.0, -51.0, 70.0, 1.1],
	[-6.0, -57.0, 310.0, 0.9], [6.5, -57.8, 180.0, 1.0], [-17.0, -50.0, 90.0, 1.0], [16.5, -56.0, 200.0, 1.0],
	[-17.5, -43.5, 40.0, 1.0], [17.0, -45.0, 300.0, 1.1], [-10.5, -33.5, 120.0, 0.9], [11.0, -34.5, 15.0, 1.0]]

# ---------------------------------------------------------------- état de l'édition
var terrain_h := PackedFloat32Array()
var terrain_d := PackedFloat32Array()
var segs: Array = []
var path_dense: Array = []              # [[x, z, r], ...]
var all_center: Array = []              # points d'axe (chemin + embranchements + sentiers) pour les contrôles de dégagement
var lvl: Level
var warn := 0
var _mats := {}
var _sub_cache := {}
var _tri_total := 0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DATA))
	_prepare_shapes()
	_bake_heights()
	lvl = Level.new()
	lvl.name = "ForetDeLaPeur"
	lvl.level_id = "foret-de-la-peur"
	lvl.level_title = "La Forêt de la peur"
	lvl.level_subtitle = "Rêve"
	lvl.lighting_preset = "foret_peur"
	lvl.default_spawn = "depart"
	lvl.interior = false
	lvl.first_person = false
	lvl.show_controls_hint = true
	lvl.kill_y = -9.0
	_spawns(_group(lvl, "Spawns"))
	_terrain_nodes(_group(lvl, "Architecture"))
	var decor := _group(lvl, "Decor")
	_trees(_group(decor, "Arbres"))
	_marsh_props(_group(decor, "Marais"))
	_ruins(_group(decor, "Ruines"))
	_clearing(_group(decor, "Clairiere"))
	_small_props(_group(decor, "Petits_elements"))
	_plants(_group(decor, "Plantes"))
	_limits(_group(lvl, "Limites"))
	_gameplay(_group(lvl, "Gameplay"))
	_lights(_group(lvl, "Lumieres"))
	var amb := _group(lvl, "Ambiance")
	_zones_meta()
	ForetAmbiance.build(lvl, amb)
	_save()

# ================================================================== outils

func _group(parent: Node, nm: String) -> Node3D:
	var g := Node3D.new()
	g.name = nm
	parent.add_child(g)
	return g

func _marker(parent: Node, nm: String, p: Vector3, yaw: float) -> Marker3D:
	var m := Marker3D.new()
	m.name = nm
	m.position = p
	m.rotation_degrees = Vector3(0, yaw, 0)
	parent.add_child(m)
	return m

func _mat(id: String, fallback: Material) -> Material:
	if ResourceLoader.exists(StyleMaterials.path_of(id)):
		return StyleMaterials.get_mat(id)
	return fallback

func _std(color: Color, rough := 0.9, emis := 0.0, vcol := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if emis > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emis
	m.vertex_color_use_as_albedo = vcol
	return m

func _sm(key: String, color: Color, rough := 0.9, emis := 0.0) -> StandardMaterial3D:
	if not _mats.has(key):
		_mats[key] = _std(color, rough, emis)
	return _mats[key]

func _smoothstep(a: float, b: float, x: float) -> float:
	return smoothstep(a, b, x)

# ================================================================== terrain : fonctions de forme

func _catmull(pts: Array, step: float) -> Array:
	var out: Array = []
	for i in pts.size() - 1:
		var p0: Array = pts[maxi(i - 1, 0)]
		var p1: Array = pts[i]
		var p2: Array = pts[i + 1]
		var p3: Array = pts[mini(i + 2, pts.size() - 1)]
		var len := Vector2(p1[0], p1[1]).distance_to(Vector2(p2[0], p2[1]))
		var n := maxi(int(ceil(len / step)), 1)
		for k in n:
			var t := float(k) / n
			var t2 := t * t
			var t3 := t2 * t
			var x: float = 0.5 * ((2.0 * p1[0]) + (-p0[0] + p2[0]) * t + (2.0 * p0[0] - 5.0 * p1[0] + 4.0 * p2[0] - p3[0]) * t2 + (-p0[0] + 3.0 * p1[0] - 3.0 * p2[0] + p3[0]) * t3)
			var z: float = 0.5 * ((2.0 * p1[1]) + (-p0[1] + p2[1]) * t + (2.0 * p0[1] - 5.0 * p1[1] + 4.0 * p2[1] - p3[1]) * t2 + (-p0[1] + 3.0 * p1[1] - 3.0 * p2[1] + p3[1]) * t3)
			out.append([x, z, lerpf(p1[2], p2[2], t)])
	var last: Array = pts[pts.size() - 1]
	out.append([last[0], last[1], last[2]])
	return out

## x du chemin principal à la profondeur z (interpolation sur l'axe échantillonné).
func _px(z: float) -> float:
	for k in path_dense.size() - 1:
		var a: Array = path_dense[k]
		var b: Array = path_dense[k + 1]
		if (a[1] >= z and b[1] <= z) or (a[1] <= z and b[1] >= z):
			var d: float = b[1] - a[1]
			var t: float = 0.0 if absf(d) < 1e-6 else (z - a[1]) / d
			return lerpf(a[0], b[0], t)
	return 0.0

func _add_seg(ax: float, az: float, bx: float, bz: float, ra: float, rb: float) -> void:
	var r := maxf(ra, rb) + 15.0
	segs.append([ax, az, bx, bz, ra, rb, minf(ax, bx) - r, maxf(ax, bx) + r, minf(az, bz) - r, maxf(az, bz) + r])

func _prepare_shapes() -> void:
	path_dense = _catmull(PATH, 1.5)
	for k in path_dense.size() - 1:
		var a: Array = path_dense[k]
		var b: Array = path_dense[k + 1]
		_add_seg(a[0], a[1], b[0], b[1], a[2], b[2])
		all_center.append(Vector2(a[0], a[1]))
	for br in BRANCHES:
		var pts: Array = [[_px(br[1]), br[1]]]
		pts.append_array(br[2])
		for k in pts.size() - 1:
			_add_seg(pts[k][0], pts[k][1], pts[k + 1][0], pts[k + 1][1], br[3], br[3])
		for k in pts.size() - 1:
			for s in 4:
				var t := float(s) / 4.0
				all_center.append(Vector2(lerpf(pts[k][0], pts[k + 1][0], t), lerpf(pts[k][1], pts[k + 1][1], t)))
	for p in POCKETS:
		_add_seg(p[0], p[1], p[0], p[1], p[2], p[2])
	for tr in TRAILS:
		var pts: Array = tr[1]
		for k in pts.size() - 1:
			for s in 4:
				var t := float(s) / 4.0
				all_center.append(Vector2(lerpf(pts[k][0], pts[k + 1][0], t), lerpf(pts[k][1], pts[k + 1][1], t)))

func _elev(z: float) -> float:
	if z >= ELEV[0][0]:
		return ELEV[0][1]
	for k in ELEV.size() - 1:
		var a: Array = ELEV[k]
		var b: Array = ELEV[k + 1]
		if z <= a[0] and z >= b[0]:
			var t: float = (z - a[0]) / (b[0] - a[0])
			return lerpf(a[1], b[1], smoothstep(0.0, 1.0, t))
	return ELEV[ELEV.size() - 1][1]

func _undul(x: float, z: float) -> float:
	var amp := 0.16 * clampf((absf(z + 46.0) - 22.0) / 4.0, 0.0, 1.0) * clampf((absf(z + 108.0) - 5.0) / 3.0, 0.0, 1.0)
	return amp * (0.55 * sin(x * 0.31 + z * 0.17) + 0.4 * sin(x * 0.13 - z * 0.29 + 1.3))

func _box_sd(x: float, z: float, cx: float, cz: float, hx: float, hz: float, rr: float) -> float:
	var qx := absf(x - cx) - hx + rr
	var qz := absf(z - cz) - hz + rr
	return Vector2(maxf(qx, 0.0), maxf(qz, 0.0)).length() + minf(maxf(qx, qz), 0.0) - rr

## Distance signée au sol praticable (négative dedans).
func _dplay(x: float, z: float) -> float:
	var best := 15.0
	for s in segs:
		if x < s[6] or x > s[7] or z < s[8] or z > s[9]:
			continue
		var abx: float = s[2] - s[0]
		var abz: float = s[3] - s[1]
		var l2 := abx * abx + abz * abz
		var t := 0.0
		if l2 > 1e-9:
			t = clampf(((x - s[0]) * abx + (z - s[1]) * abz) / l2, 0.0, 1.0)
		var px: float = s[0] + abx * t - x
		var pz: float = s[1] + abz * t - z
		var d := sqrt(px * px + pz * pz) - lerpf(s[4], s[5], t)
		if d < best:
			best = d
	var mb := MARSH_BOX
	best = minf(best, _box_sd(x, z, mb[0], mb[1], mb[2], mb[3], mb[4]))
	return best

## Distance signée à l'eau (négative dans l'eau) : rectangle de l'étang moins les rives W/E et l'îlot.
func _water_sd(x: float, z: float) -> float:
	var r := _box_sd(x, z, 0.0, -47.0, 30.0, 11.5, 0.0) + 0.6 + 0.6 * sin(x * 0.5 + 1.0) + 0.4 * sin(x * 1.1 + 2.0)   # rives sinueuses (l'eau recule de 0,6 m en moyenne)
	if r > 3.5:
		return r
	var w := _box_sd(x, z, -19.25, -42.0, 10.75, 6.0, 0.5)
	var e := _box_sd(x, z, 19.25, -42.0, 10.75, 6.0, 0.5)
	var ex := x / 5.2
	var ez := (z + 45.4) / 3.2
	var isl := (sqrt(ex * ex + ez * ez) - 1.0) * 3.2
	return maxf(r, -minf(minf(w, e), isl))

func _talus(d: float, x: float, z: float) -> float:
	if d <= 0.0:
		return 0.0
	var t := 1.7 * d if d <= 3.5 else 5.95 + 1.15 * (d - 3.5)
	t = minf(t, 17.0)
	if d > 2.0:
		t += 0.55 * sin(x * 0.8 + z * 0.6) * smoothstep(2.0, 6.0, d) + 0.4 * sin(x * 0.37 - z * 0.83) * smoothstep(2.0, 8.0, d)
	return t

func _h(x: float, z: float, d: float) -> float:
	var base := _elev(z) + _undul(x, z)
	var ws := _water_sd(x, z)
	if ws < 0.0:
		var w := smoothstep(0.0, 1.5, -ws)
		base = lerpf(base, BED_Y + 0.18 * sin(x * 0.45 + z * 0.3), w)
	return base + _talus(d, x, z)

func _bake_heights() -> void:
	terrain_h.resize(NX * NZ)
	terrain_d.resize(NX * NZ)
	for j in NZ:
		var z := Z0 - j * CS
		for i in NX:
			var x := X0 + i * CS
			var d := _dplay(x, z)
			terrain_d[j * NX + i] = d
			terrain_h[j * NX + i] = _h(x, z, d)
	print("relief : %d sommets calculés" % (NX * NZ))

## Altitude exacte du maillage (même triangulation que le maillage et la collision).
func ground(x: float, z: float) -> float:
	var fi := (x - X0) / CS
	var fj := (Z0 - z) / CS
	var i := clampi(int(floor(fi)), 0, NX - 2)
	var j := clampi(int(floor(fj)), 0, NZ - 2)
	var u := clampf(fi - i, 0.0, 1.0)
	var v := clampf(fj - j, 0.0, 1.0)                   # 0 au sud de la case, 1 au nord
	var h00 := terrain_h[j * NX + i]
	var h10 := terrain_h[j * NX + i + 1]
	var h01 := terrain_h[(j + 1) * NX + i]
	var h11 := terrain_h[(j + 1) * NX + i + 1]
	if u > v:
		return h00 + (h10 - h00) * u + (h11 - h10) * v
	return h00 + (h01 - h00) * v + (h11 - h01) * u

func _at(x: float, z: float, dy := 0.0) -> Vector3:
	return Vector3(x, ground(x, z) + dy, z)

# ================================================================== terrain : maillage, collision, eau, chemin

func _terrain_nodes(arch: Node3D) -> void:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	verts.resize(NX * NZ)
	norms.resize(NX * NZ)
	cols.resize(NX * NZ)
	uvs.resize(NX * NZ)
	for j in NZ:
		for i in NX:
			var k := j * NX + i
			var x := X0 + i * CS
			var z := Z0 - j * CS
			verts[k] = Vector3(x, terrain_h[k], z)
			var hl := terrain_h[j * NX + maxi(i - 1, 0)]
			var hr := terrain_h[j * NX + mini(i + 1, NX - 1)]
			var hs := terrain_h[maxi(j - 1, 0) * NX + i]               # j−1 = plus au sud
			var hn := terrain_h[mini(j + 1, NZ - 1) * NX + i]
			var dx := (hr - hl) / (CS * (2.0 if (i > 0 and i < NX - 1) else 1.0))
			var dz := (hs - hn) / (CS * (2.0 if (j > 0 and j < NZ - 1) else 1.0))
			norms[k] = Vector3(-dx, 1.0, -dz).normalized()
			var d := terrain_d[k]
			var c := lerpf(1.0, 0.42, smoothstep(0.0, 7.0, d))
			cols[k] = Color(c, c, c * 1.05, 1.0)
			uvs[k] = Vector2(x * 0.25, z * 0.25)
	var idx := PackedInt32Array()
	var faces := PackedVector3Array()
	for j in NZ - 1:
		for i in NX - 1:
			var v00 := j * NX + i
			var v10 := v00 + 1
			var v01 := (j + 1) * NX + i
			var v11 := v01 + 1
			var dmin := minf(minf(terrain_d[v00], terrain_d[v10]), minf(terrain_d[v01], terrain_d[v11]))
			if dmin > 14.0:
				continue                                              # loin derrière les talus : jamais vu, jamais touché
			idx.append_array(PackedInt32Array([v00, v01, v11, v00, v11, v10]))
			if dmin < 12.0:
				faces.append_array(PackedVector3Array([verts[v00], verts[v01], verts[v11], verts[v00], verts[v11], verts[v10]]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _mat("foret_sol", _std(Color(0.10, 0.16, 0.2), 0.95, 0.0, true)))
	ResourceSaver.save(mesh, DATA + "relief_maillage.res", ResourceSaver.FLAG_COMPRESS)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	ResourceSaver.save(shape, DATA + "relief_collision.res", ResourceSaver.FLAG_COMPRESS)
	print("relief : %d triangles visibles, %d de collision" % [idx.size() / 3, faces.size() / 3])
	_tri_total += idx.size() / 3

	var body := StaticBody3D.new()
	body.name = "Relief"
	arch.add_child(body)
	var mi := MeshInstance3D.new()
	mi.name = "Sol"
	mi.mesh = load(DATA + "relief_maillage.res")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "Collision"
	cs.shape = load(DATA + "relief_collision.res")
	body.add_child(cs)

	# chemin principal en deux rubans (avant et après l'étang) + sentiers
	var main_a: Array = []
	var main_b: Array = []
	for p in path_dense:
		if p[1] <= 8.0 and p[1] >= -35.0:
			main_a.append(Vector2(p[0], p[1]))
		elif p[1] <= -60.5 and p[1] >= -124.0:
			main_b.append(Vector2(p[0], p[1]))
	_ribbon(arch, "Chemin_sud", main_a, 2.8)
	_ribbon(arch, "Chemin_nord", main_b, 2.6)
	for tr in TRAILS:
		var pts: Array = []
		for p in tr[1]:
			pts.append(Vector2(p[0], p[1]))
		_ribbon(arch, tr[0], _catmull_v2(pts), 2.2)
	_water(arch)
	_water_walls(arch)

func _catmull_v2(pts: Array) -> Array:
	var src: Array = []
	for p in pts:
		src.append([p.x, p.y, 0.0])
	var out: Array = []
	for q in _catmull(src, 1.0):
		out.append(Vector2(q[0], q[1]))
	return out

## Ruban posé sur le relief : sol tassé et plus clair qui guide le regard.
func _ribbon(parent: Node, nm: String, pts: Array, width: float) -> void:
	if pts.size() < 2:
		return
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var run := 0.0
	for k in pts.size():
		var p: Vector2 = pts[k]
		var a: Vector2 = pts[maxi(k - 1, 0)]
		var b: Vector2 = pts[mini(k + 1, pts.size() - 1)]
		var t := (b - a).normalized()
		var n := Vector2(-t.y, t.x)
		if k > 0:
			run += p.distance_to(pts[k - 1])
		for side in [-1.0, 1.0]:
			var q: Vector2 = p + n * side * width * 0.5
			verts.append(Vector3(q.x, ground(q.x, q.y) + 0.05, q.y))
			norms.append(Vector3.UP)
			uvs.append(Vector2(0.0 if side < 0.0 else 1.0, run / 3.0))
		if k > 0:
			var b0 := (k - 1) * 2
			idx.append_array(PackedInt32Array([b0, b0 + 1, b0 + 3, b0, b0 + 3, b0 + 2]))
	# sens des faces : vers le haut
	for q in range(0, idx.size(), 3):
		var cr := (verts[idx[q + 1]] - verts[idx[q]]).cross(verts[idx[q + 2]] - verts[idx[q]])
		if cr.y > 0.0:
			var tmp := idx[q + 1]
			idx[q + 1] = idx[q + 2]
			idx[q + 2] = tmp
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _mat("foret_chemin", _std(Color(0.22, 0.28, 0.34), 0.9)))
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_tri_total += idx.size() / 3

func _water(arch: Node3D) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(60.0, 25.0)
	pm.subdivide_width = 30
	pm.subdivide_depth = 12
	pm.material = _mat("foret_eau", _water_fallback())
	var mi := MeshInstance3D.new()
	mi.name = "Eau"
	mi.mesh = pm
	mi.position = Vector3(0.0, WATER_Y, -47.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arch.add_child(mi)
	_tri_total += 30 * 12 * 2

func _water_fallback() -> Material:
	var m := _std(Color(0.03, 0.08, 0.13, 0.85), 0.05)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.6
	return m

func _exempt(cx: float, cz: float) -> bool:
	return absf(cx) <= CORR_X and ((cz <= -34.0 and cz >= -43.0) or (cz <= -47.5 and cz >= -61.0))

## Murs invisibles sur les contours de l'eau : infranchissable, sauf le couloir de la passerelle et du pont
## (dont les rives sont elles-mêmes ces murs).
func _water_walls(arch: Node3D) -> void:
	var blocked := PackedByteArray()
	blocked.resize((NX - 1) * (NZ - 1))
	for j in NZ - 1:
		for i in NX - 1:
			var h := (terrain_h[j * NX + i] + terrain_h[j * NX + i + 1] + terrain_h[(j + 1) * NX + i] + terrain_h[(j + 1) * NX + i + 1]) * 0.25
			var cx := X0 + (i + 0.5) * CS
			var cz := Z0 - (j + 0.5) * CS
			blocked[j * (NX - 1) + i] = 1 if (h < WATER_Y - 0.02 and not _exempt(cx, cz) and cz < -30.0 and cz > -65.0) else 0
	var faces := PackedVector3Array()
	var y0 := WATER_Y - 2.4
	var y1 := WATER_Y + 1.7
	for j in NZ - 1:
		for i in NX - 1:
			if blocked[j * (NX - 1) + i] == 0:
				continue
			var xw := X0 + i * CS
			var xe := xw + CS
			var zs := Z0 - j * CS
			var zn := zs - CS
			for dir in [[-1, 0], [1, 0], [0, -1], [0, 1]]:
				var ni: int = i + dir[0]
				var nj: int = j + dir[1]
				if ni < 0 or nj < 0 or ni >= NX - 1 or nj >= NZ - 1:
					continue
				if blocked[nj * (NX - 1) + ni] == 1:
					continue
				var a: Vector3
				var b: Vector3
				if dir[0] == -1:
					a = Vector3(xw, 0, zs); b = Vector3(xw, 0, zn)
				elif dir[0] == 1:
					a = Vector3(xe, 0, zs); b = Vector3(xe, 0, zn)
				elif dir[1] == -1:
					a = Vector3(xw, 0, zs); b = Vector3(xe, 0, zs)
				else:
					a = Vector3(xw, 0, zn); b = Vector3(xe, 0, zn)
				var a0 := Vector3(a.x, y0, a.z)
				var a1 := Vector3(a.x, y1, a.z)
				var b0 := Vector3(b.x, y0, b.z)
				var b1 := Vector3(b.x, y1, b.z)
				faces.append_array(PackedVector3Array([a0, a1, b1, a0, b1, b0]))
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var body := StaticBody3D.new()
	body.name = "Eau_barriere"
	var cs := CollisionShape3D.new()
	cs.name = "Collision"
	cs.shape = shape
	body.add_child(cs)
	arch.add_child(body)
	print("eau : %d faces de barrière" % (faces.size() / 3))

# ================================================================== substituts du kit organique (contrat de dimensions)

func _cyl(r_bottom: float, r_top: float, h: float, mat: Material, seg := 10) -> ArrayMesh:
	return StyleKit.lathe(PackedVector2Array([Vector2(r_bottom, 0.0), Vector2((r_bottom + r_top) * 0.5 * 1.04, h * 0.5), Vector2(r_top, h)]), seg, mat)

func _blob(r: float, mat: Material, sy := 0.8) -> ArrayMesh:
	var m := StyleKit.sphere(r, mat, 10, 6)
	return m

func _xf(p: Vector3, rot := Vector3.ZERO, s := Vector3.ONE) -> Transform3D:
	return ModuleBuilder.at(p, rot, s)

func _mi(parent: Node, nm: String, mesh: Mesh, p := Vector3.ZERO, shadows := true) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	m.mesh = mesh
	m.position = p
	if not shadows:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m

func _body_cyl(parent: Node, r: float, h: float, y := 0.0) -> void:
	var b := StaticBody3D.new()
	b.name = "Collision"
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	cs.position = Vector3(0, y + h * 0.5, 0)
	b.add_child(cs)
	parent.add_child(b)

func _body_box(parent: Node, size: Vector3, pos: Vector3, nm := "Collision", rot := Vector3.ZERO) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = nm
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = _xf(pos, rot)
	b.add_child(cs)
	parent.add_child(b)
	return b

func _cached(key: String, builder: Callable) -> Mesh:
	if not _sub_cache.has(key):
		_sub_cache[key] = builder.call()
	return _sub_cache[key]

func _tree_mesh(key: String, h: float, rb: float, canopy: float, n_blobs: int) -> Mesh:
	return _cached(key, func() -> Mesh:
		var bark := _sm("ecorce", Color(0.13, 0.12, 0.17))
		var leaf := _sm("feuillage", Color(0.09, 0.2, 0.24))
		var parts := [[_cyl(rb, rb * 0.45, h * 0.85, bark, 9), _xf(Vector3.ZERO)]]
		for k in n_blobs:
			var a := TAU * float(k) / n_blobs + 0.6
			var off := Vector3(cos(a) * canopy * 0.55, h * (0.78 + 0.07 * (k % 3)), sin(a) * canopy * 0.55)
			parts.append([_blob(canopy * (0.8 + 0.1 * (k % 2)), leaf), _xf(off)])
		parts.append([_blob(canopy, leaf), _xf(Vector3(0, h * 0.95, 0))])
		return StyleKit.merge(parts))

## Substitut d'un module du kit organique. CONTRAT : origine au sol, centré ; dimensions ci-dessous.
func _substitute(id: String) -> Node3D:
	var n := Node3D.new()
	var bark := _sm("ecorce", Color(0.13, 0.12, 0.17))
	var stone := _sm("pierre", Color(0.2, 0.23, 0.31))
	var moss := _sm("mousse", Color(0.12, 0.22, 0.2))
	var glow := _sm("lueur", Color(0.5, 0.95, 1.0), 0.5, 2.0)
	match id:
		"arbre_tordu_a", "arbre_tordu_b", "arbre_tordu_c":
			var h := {"arbre_tordu_a": 9.0, "arbre_tordu_b": 11.0, "arbre_tordu_c": 13.5}[id] as float
			_mi(n, "Maillage", _tree_mesh(id, h, 0.5, h * 0.2, 4))
			_body_cyl(n, 0.55, 6.0)
		"arbre_echasses":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var parts := [[_cyl(0.42, 0.28, 8.0, bark, 8), _xf(Vector3(0, 1.3, 0))], [_blob(2.2, _sm("feuillage", Color(0.09, 0.2, 0.24))), _xf(Vector3(0, 8.2, 0))]]
				for k in 5:
					var a := TAU * float(k) / 5.0
					parts.append([_cyl(0.16, 0.08, 2.2, bark, 6), _xf(Vector3(cos(a) * 0.9, 0.0, sin(a) * 0.9), Vector3(sin(a) * 28.0, 0, -cos(a) * 28.0))])
				return StyleKit.merge(parts)))
			_body_cyl(n, 1.0, 3.0)
		"arbre_mort":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var parts := [[_cyl(0.42, 0.14, 7.0, bark, 8), _xf(Vector3.ZERO)], [_cyl(0.12, 0.04, 2.4, bark, 6), _xf(Vector3(0.2, 4.6, 0), Vector3(0, 0, -58))], [_cyl(0.1, 0.03, 2.0, bark, 6), _xf(Vector3(-0.1, 3.4, 0), Vector3(0, 0, 55))]]
				return StyleKit.merge(parts)))
			_body_cyl(n, 0.45, 4.0)
		"arbre_ancien":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var leaf := _sm("feuillage_clair", Color(0.22, 0.4, 0.42), 0.8, 0.25)
				var parts := [[_cyl(1.9, 0.9, 14.0, bark, 14), _xf(Vector3.ZERO)], [_blob(6.5, leaf), _xf(Vector3(0, 15.5, 0))],
					[_blob(4.6, leaf), _xf(Vector3(4.2, 13.5, 1.0))], [_blob(4.6, leaf), _xf(Vector3(-3.8, 14.0, -1.6))], [_blob(4.0, leaf), _xf(Vector3(0.6, 12.5, 4.2))]]
				return StyleKit.merge(parts)))
			_body_cyl(n, 1.9, 6.0)
		"tronc_couche":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				return StyleKit.merge([[_cyl(0.38, 0.34, 6.0, bark, 9), _xf(Vector3(0, 0.38, -3.0), Vector3(90, 0, 0))]])))
			_body_box(n, Vector3(0.76, 0.76, 6.0), Vector3(0, 0.38, 0))
		"souche":
			_mi(n, "Maillage", _cached(id, func() -> Mesh: return _cyl(0.62, 0.5, 0.55, bark, 10)))
			_body_cyl(n, 0.6, 0.55)
		"racines_arche":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var parts := [[StyleKit.torus(1.3, 0.3, bark, 14, 6), _xf(Vector3(0, 1.1, 0), Vector3(90, 0, 0))]]
				return StyleKit.merge(parts)))
			_body_box(n, Vector3(0.6, 1.2, 0.6), Vector3(-1.3, 0.6, 0))
			_body_box(n, Vector3(0.6, 1.2, 0.6), Vector3(1.3, 0.6, 0), "Collision2")
		"racines_basses":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var parts := []
				for k in 4:
					var a := TAU * float(k) / 4.0 + 0.4
					parts.append([_cyl(0.2, 0.06, 1.6, bark, 6), _xf(Vector3.ZERO, Vector3(sin(a) * 82.0, 0, -cos(a) * 82.0))])
				return StyleKit.merge(parts)))
		"rocher_a", "rocher_b", "rocher_c":
			var s := {"rocher_a": 0.6, "rocher_b": 1.4, "rocher_c": 2.5}[id] as float
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				return StyleKit.merge([[StyleKit.sphere(0.5, stone, 8, 5), _xf(Vector3(0, s * 0.35, 0), Vector3.ZERO, Vector3(s * 1.0, s * 0.7, s * 0.85))],
					[StyleKit.sphere(0.5, moss, 8, 4), _xf(Vector3(0, s * 0.62, 0), Vector3.ZERO, Vector3(s * 0.7, s * 0.2, s * 0.6))]])))
			_body_cyl(n, s * 0.45, s * 0.7)
		"pierres_plates":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var parts := []
				for p in [[0.0, 0.0], [0.9, 0.5], [-0.7, 1.1], [0.3, -1.1]]:
					parts.append([_cyl(0.42, 0.38, 0.07, stone, 8), _xf(Vector3(p[0], 0.0, p[1]))])
				return StyleKit.merge(parts)))
		"cercle_pierres":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var parts := []
				for k in 9:
					var a := TAU * float(k) / 9.0
					parts.append([StyleKit.rounded_box(Vector3(0.55, 1.1 + 0.15 * (k % 3), 0.38), 0.08, stone, 2), _xf(Vector3(cos(a) * 3.4, 0.55, sin(a) * 3.4), Vector3(0, -rad_to_deg(a), 0))])
				return StyleKit.merge(parts)))
		"arbuste_a", "arbuste_b", "fougere", "herbes_touffe":
			var r := {"arbuste_a": 0.8, "arbuste_b": 0.6, "fougere": 0.55, "herbes_touffe": 0.35}[id] as float
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				return StyleKit.merge([[_blob(r, _sm("plante", Color(0.1, 0.24, 0.22))), _xf(Vector3(0, r * 0.45, 0), Vector3.ZERO, Vector3(1.0, 0.7, 1.0))]])))
		"roseaux":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var parts := []
				for k in 6:
					var a := TAU * float(k) / 6.0
					parts.append([_cyl(0.04, 0.01, 1.8 + 0.2 * (k % 3), _sm("roseau", Color(0.14, 0.26, 0.2)), 4), _xf(Vector3(cos(a) * 0.3, 0, sin(a) * 0.3), Vector3(sin(a) * 6.0, 0, 0))])
				return StyleKit.merge(parts)))
		"nenuphars":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var parts := []
				for p in [[0.0, 0.0, 0.5], [1.0, 0.5, 0.38], [-0.8, 0.9, 0.42]]:
					parts.append([_cyl(p[2], p[2], 0.03, _sm("nenuphar", Color(0.3, 0.8, 0.85), 0.5, 1.4), 10), _xf(Vector3(p[0], 0.0, p[1]))])
				return StyleKit.merge(parts)))
		"champignons_lumineux":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var parts := []
				for p in [[0.0, 0.0, 0.2], [0.3, 0.2, 0.14], [-0.25, 0.25, 0.12]]:
					parts.append([_cyl(0.03, 0.03, p[2], bark, 5), _xf(Vector3(p[0], 0, p[1]))])
					parts.append([StyleKit.sphere(p[2] * 0.7, glow, 6, 4), _xf(Vector3(p[0], p[2], p[1]), Vector3.ZERO, Vector3(1, 0.5, 1))])
				return StyleKit.merge(parts)))
		"fleurs_blanches":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var parts := []
				for p in [[0.0, 0.0], [0.25, 0.1], [-0.2, 0.2], [0.1, -0.25]]:
					parts.append([_cyl(0.015, 0.01, 0.4, moss, 4), _xf(Vector3(p[0], 0, p[1]))])
					parts.append([StyleKit.sphere(0.07, _sm("fleur_blanche", Color(0.95, 0.97, 1.0), 0.6, 1.2), 6, 4), _xf(Vector3(p[0], 0.42, p[1]))])
				return StyleKit.merge(parts)))
		"ruine_arche":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				return StyleKit.merge([[StyleKit.rounded_box(Vector3(0.7, 3.4, 1.0), 0.06, stone, 2), _xf(Vector3(-1.85, 1.7, 0))], [StyleKit.rounded_box(Vector3(0.7, 3.4, 1.0), 0.06, stone, 2), _xf(Vector3(1.85, 1.7, 0))],
					[StyleKit.extrude(StyleKit.arch_frame_outline(3.0, 3.6, 0.5, 14), 1.0, stone, 0.04), _xf(Vector3(0, 0.0, 0))]])))
			_body_box(n, Vector3(0.7, 3.4, 1.0), Vector3(-1.85, 1.7, 0))
			_body_box(n, Vector3(0.7, 3.4, 1.0), Vector3(1.85, 1.7, 0), "Collision2")
		"ruine_colonne":
			_mi(n, "Maillage", _cached(id, func() -> Mesh: return _cyl(0.46, 0.4, 3.2, stone, 10)))
			_body_cyl(n, 0.46, 3.2)
		"ruine_mur":
			_mi(n, "Maillage", _cached(id, func() -> Mesh: return StyleKit.rounded_box(Vector3(4.0, 2.6, 0.6), 0.06, stone, 2)))
			_mi(n, "Mousse", _cached("ruine_mur_m", func() -> Mesh: return StyleKit.rounded_box(Vector3(4.0, 0.2, 0.7), 0.05, moss, 2)), Vector3(0, 2.6, 0))
			n.get_child(0).position = Vector3(0, 1.3, 0)
			_body_box(n, Vector3(4.0, 2.6, 0.6), Vector3(0, 1.3, 0))
		"ruine_porte_lune":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				return StyleKit.merge([[StyleKit.rounded_box(Vector3(0.8, 4.0, 1.1), 0.06, stone, 2), _xf(Vector3(-2.1, 2.0, 0))], [StyleKit.rounded_box(Vector3(0.8, 4.0, 1.1), 0.06, stone, 2), _xf(Vector3(2.1, 2.0, 0))],
					[StyleKit.rounded_box(Vector3(5.0, 0.9, 1.1), 0.06, stone, 2), _xf(Vector3(0, 4.35, 0))], [StyleKit.sphere(0.32, glow, 10, 6), _xf(Vector3(0, 4.35, 0.6))]])))
			_body_box(n, Vector3(0.8, 4.0, 1.1), Vector3(-2.1, 2.0, 0))
			_body_box(n, Vector3(0.8, 4.0, 1.1), Vector3(2.1, 2.0, 0), "Collision2")
			_body_box(n, Vector3(5.0, 0.9, 1.1), Vector3(0, 4.35, 0), "Collision3")
			for side in [["VantailG", -1.5, 0.75], ["VantailD", 1.5, -0.75]]:
				var pv := Node3D.new()
				pv.name = side[0]
				pv.position = Vector3(side[1], 0.0, 0.0)
				n.add_child(pv)
				_mi(pv, "Battant", _cached("vantail", func() -> Mesh: return StyleKit.rounded_box(Vector3(1.48, 3.8, 0.2), 0.04, _sm("bois_ruine", Color(0.16, 0.14, 0.2)), 2)), Vector3(side[2], 1.9, 0.0))
		"piedestal_lune":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				return StyleKit.merge([[_cyl(0.42, 0.34, 1.1, stone, 10), _xf(Vector3.ZERO)], [StyleKit.torus(0.32, 0.05, stone, 12, 5), _xf(Vector3(0, 1.1, 0))]])))
			_body_cyl(n, 0.42, 1.1)
			var pierre := _mi(n, "Pierre", _cached("pierre_lune", func() -> Mesh: return StyleKit.sphere(0.2, glow, 10, 6)), Vector3(0, 1.35, 0), false)
			var l := OmniLight3D.new()
			l.name = "Lumiere"
			l.position = Vector3(0, 1.35, 0)
			l.light_color = Color(0.6, 0.9, 1.0)
			l.light_energy = 1.4
			l.omni_range = 5.0
			pierre.get_parent().add_child(l)
		"cadre_porte_reve":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var c := _sm("cadre_pierre", Color(0.26, 0.28, 0.36))
				return StyleKit.merge([[StyleKit.rounded_box(Vector3(0.3, 2.7, 0.4), 0.05, c, 2), _xf(Vector3(-0.8, 1.35, 0))], [StyleKit.rounded_box(Vector3(0.3, 2.7, 0.4), 0.05, c, 2), _xf(Vector3(0.8, 1.35, 0))],
					[StyleKit.rounded_box(Vector3(1.9, 0.3, 0.4), 0.05, c, 2), _xf(Vector3(0, 2.55, 0))], [StyleKit.rounded_box(Vector3(2.0, 0.12, 0.7), 0.04, c, 2), _xf(Vector3(0, 0.06, 0))]])))
			_body_box(n, Vector3(0.3, 2.7, 0.4), Vector3(-0.8, 1.35, 0))
			_body_box(n, Vector3(0.3, 2.7, 0.4), Vector3(0.8, 1.35, 0), "Collision2")
			_body_box(n, Vector3(1.9, 0.3, 0.4), Vector3(0, 2.55, 0), "Collision3")
		"fleur_lanterne":
			_mi(n, "Tige", _cached("fl_tige", func() -> Mesh: return _cyl(0.05, 0.03, 0.85, moss, 6)))
			var cor := MeshInstance3D.new()
			cor.name = "Corolle"
			cor.mesh = _cached("fl_cor", func() -> Mesh: return StyleKit.sphere(0.2, _sm("corolle", Color(0.55, 0.8, 0.9), 0.5), 10, 6))
			cor.position = Vector3(0, 1.0, 0)
			n.add_child(cor)
			var l := OmniLight3D.new()
			l.name = "Lumiere"
			l.light_color = Color(0.55, 0.95, 1.0)
			l.light_energy = 2.0
			l.omni_range = 5.5
			cor.add_child(l)
			_body_cyl(n, 0.12, 0.9)
		"silhouette_ombre":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var d := _sm("ombre", Color(0.01, 0.01, 0.03), 1.0)
				return StyleKit.merge([[_cyl(0.55, 0.18, 1.7, d, 8), _xf(Vector3.ZERO)], [StyleKit.sphere(0.22, d, 8, 5), _xf(Vector3(0, 1.9, 0))]])), Vector3.ZERO, false)
		"jeune_fille_provisoire":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				var cape := _sm("cape", Color(0.62, 0.46, 0.3), 0.9, 0.15)
				var peau := _sm("peau", Color(0.8, 0.68, 0.6))
				var cheveux := _sm("cheveux", Color(0.1, 0.07, 0.07))
				return StyleKit.merge([[_cyl(0.34, 0.12, 0.72, cape, 10), _xf(Vector3.ZERO)], [StyleKit.sphere(0.15, peau, 10, 6), _xf(Vector3(0, 0.85, 0))],
					[StyleKit.sphere(0.17, cheveux, 10, 6), _xf(Vector3(0, 0.9, 0.03))]])))
		"lanterne_eteinte":
			_mi(n, "Maillage", _cached(id, func() -> Mesh:
				return StyleKit.merge([[_cyl(0.12, 0.1, 0.3, _sm("fer", Color(0.1, 0.1, 0.13)), 8), _xf(Vector3.ZERO)], [StyleKit.sphere(0.1, _sm("verre_eteint", Color(0.2, 0.25, 0.3)), 8, 5), _xf(Vector3(0, 0.34, 0))]])))
		_:
			_mi(n, "Maillage", _cached("inconnu", func() -> Mesh: return StyleKit.rounded_box(Vector3(1, 1, 1), 0.1, _sm("inconnu", Color(1, 0, 1)), 2)), Vector3(0, 0.5, 0))
	return n

## Instancie un module du kit s'il existe, sinon son substitut. `p` = position monde (y = sol).
func _prop(parent: Node, id: String, p: Vector3, yaw := 0.0, scale := 1.0, nm := "") -> Node3D:
	var path := MOD + id + ".tscn"
	var n: Node3D
	if ResourceLoader.exists(path):
		n = (load(path) as PackedScene).instantiate() as Node3D
	else:
		n = _substitute(id)
	n.name = nm if nm != "" else id.to_pascal_case()
	n.position = p
	n.rotation_degrees = Vector3(0, yaw, 0)
	if absf(scale - 1.0) > 0.001:
		n.scale = Vector3.ONE * scale
	parent.add_child(n)
	n.set_meta("kit_id", id)
	return n

func _prop_g(parent: Node, id: String, x: float, z: float, yaw := 0.0, scale := 1.0, nm := "") -> Node3D:
	return _prop(parent, id, _at(x, z), yaw, scale, nm)

# ================================================================== arbres

func _clear_check(id: String, x: float, z: float, min_dist := 2.5) -> void:
	var p := Vector2(x, z)
	for c in all_center:
		if p.distance_to(c) < min_dist:
			print("AVERTISSEMENT : %s (%.1f, %.1f) à %.1f m de l'axe du chemin" % [id, x, z, p.distance_to(c)])
			warn += 1
			return
	if z < -33.0 and z > -64.0 and ground(x, z) < WATER_Y + 0.15 and id != "arbre_echasses":
		print("AVERTISSEMENT : %s (%.1f, %.1f) dans l'eau" % [id, x, z])
		warn += 1

func _trees(g: Node3D) -> void:
	var walls := _group(g, "Murs_de_troncs")
	var k := 0
	for side in [[-1.0, NEAR_L, 1.5, "G"], [1.0, NEAR_R, 1.5, "D"], [-1.0, FAR_L, 5.5, "Gf"], [1.0, FAR_R, 5.5, "Df"]]:
		for z in side[1]:
			var x := _px(z)
			var guard := 0
			while _dplay(x, z) < float(side[2]) and guard < 160:
				x += side[0] * 0.25
				guard += 1
			var id: String = WALL_IDS[(k * 3 + 1) % WALL_IDS.size()]
			var sc := 0.9 + 0.12 * float((k * 5) % 4)
			var yaw := float((k * 67) % 360)
			var pos := Vector3(x, ground(x, z) - 0.05, z)
			_prop(walls, id, pos, yaw, sc, "Tronc_%s_%d" % [side[3], k])
			k += 1
	var masses := _group(g, "Masses")
	var mi := 0
	for m in MASSES:
		var rot := deg_to_rad(float(m[4]))
		for t in m[2]:
			var o: Array = OFFS[t]
			var ox: float = (o[0] * cos(rot) - o[1] * sin(rot)) * float(m[3])
			var oz: float = (o[0] * sin(rot) + o[1] * cos(rot)) * float(m[3])
			var x: float = m[0] + ox
			var z: float = m[1] + oz
			var ids: Array = m[5]
			var id: String = ids[(t + mi) % ids.size()]
			if _dplay(x, z) > 12.0:
				print("arbre %s (%.1f, %.1f) trop loin du sol praticable : ignoré" % [id, x, z])
				continue
			_clear_check(id, x, z)
			_prop(masses, id, _at(x, z, -0.05), float((mi * 53 + t * 91) % 360), 0.95 + 0.1 * float((mi + t) % 3), "Arbre_%d_%d" % [mi, t])
		mi += 1

func _marsh_props(g: Node3D) -> void:
	var wt := _group(g, "Arbres_echasses")
	var i := 0
	for t in WATER_TREES:
		_prop(wt, "arbre_echasses", _at(t[0], t[1], -0.05), t[2], t[3], "Echasses_%d" % i)
		i += 1
	# roseaux sur les rives, nénuphars sur l'eau (origine au plan d'eau)
	var reeds := _group(g, "Roseaux")
	i = 0
	for r in [[-10.5, -36.4], [-8.4, -37.2], [10.0, -36.6], [8.6, -38.0], [-9.2, -47.8], [9.4, -48.2], [-14.5, -48.6], [14.0, -47.4], [-12.0, -59.4], [11.0, -59.0], [-6.0, -60.0], [5.0, -60.5]]:
		_prop(reeds, "roseaux", _at(r[0], r[1]), float(i * 47 % 360), 1.0, "Roseaux_%d" % i)
		i += 1
	var lily := _group(g, "Nenuphars")
	i = 0
	for r in [[-4.5, -38.5], [4.8, -40.0], [-6.0, -44.0], [6.5, -46.5], [-5.0, -53.0], [3.5, -52.0], [-11.0, -53.5], [10.5, -55.0], [7.5, -50.5]]:
		_prop(lily, "nenuphars", Vector3(r[0], WATER_Y, r[1]), float(i * 61 % 360), 1.0, "Nenuphars_%d" % i)
		i += 1

func _ruins(g: Node3D) -> void:
	# ruine latérale du bois noir : cercle de murs et de colonnes brisées autour du piédestal (−18,5, −88,5)
	var c := Vector2(-17.0, -87.5)
	_prop_g(g, "ruine_mur", -14.0, -91.0, 20.0, 1.0, "Ruine_mur_1")
	_prop_g(g, "ruine_mur", -20.5, -84.0, 115.0, 1.0, "Ruine_mur_2")
	_prop_g(g, "ruine_mur", -21.8, -90.2, 80.0, 0.9, "Ruine_mur_3")
	_prop_g(g, "ruine_colonne", -14.5, -83.6, 0.0, 1.0, "Ruine_colonne_1")
	_prop_g(g, "ruine_colonne", -19.5, -92.2, 0.0, 0.8, "Ruine_colonne_2")
	_prop_g(g, "ruine_arche", -16.5, -80.2, 30.0, 0.8, "Ruine_arche_laterale")
	_prop_g(g, "rocher_b", -22.5, -86.0, 40.0, 1.0, "Ruine_rocher")
	_prop_g(g, "racines_basses", -13.4, -89.4, 70.0, 1.0, "Ruine_racines")
	# la porte de ruine (z −108) et ses murs d'encadrement
	var pd := _group(g, "Porte_de_ruine")
	_prop_g(pd, "ruine_mur", -3.4, -108.0, 0.0, 0.6, "Mur_G")
	_prop_g(pd, "ruine_mur", 3.4, -108.0, 0.0, 0.6, "Mur_D")
	_prop_g(g, "ruine_colonne", -2.8, -104.4, 0.0, 0.9, "Porte_colonne_G")
	_prop_g(g, "ruine_colonne", 2.9, -104.0, 0.0, 0.8, "Porte_colonne_D")
	_prop_g(g, "racines_arche", 0.0, -62.4, 0.0, 1.15, "Racines_arche_nord")

func _clearing(g: Node3D) -> void:
	_prop_g(g, "arbre_ancien", 0.0, -141.0, 0.0, 1.0, "Arbre_ancien")
	_prop_g(g, "cercle_pierres", -1.0, -131.0, 0.0, 1.0, "Cercle_pierres")
	for r in [[-9.0, -121.0], [8.0, -118.5], [10.5, -133.0], [-10.0, -137.0]]:
		_prop_g(g, "rocher_b" if r[0] < 0 else "rocher_a", r[0], r[1], float(r[1] * 7.0), 1.0, "Rocher_%d_%d" % [int(r[0]), int(r[1])])
	var fl := 0
	for r in [[-5.0, -135.0], [-3.5, -137.0], [3.0, -135.5], [4.5, -138.0], [-7.0, -128.0], [6.5, -123.0], [-2.0, -119.5], [2.5, -121.0], [0.5, -133.5], [-4.0, -131.5]]:
		_prop_g(g, "fleurs_blanches", r[0], r[1], float(fl * 41 % 360), 1.0, "Fleurs_blanches_%d" % fl)
		fl += 1

func _small_props(g: Node3D) -> void:
	# champignons lumineux : le long du chemin de la lisière, du bois noir et des impasses (leurres)
	var i := 0
	for r in [[-3.2, 0.0], [3.6, -3.5], [-3.4, -9.0], [3.0, -13.0], [-2.8, -18.5], [3.4, -22.0], [-7.6, -15.2], [-11.0, -16.3], [-10.0, -21.0],
			[-7.4, -86.2], [-11.0, -84.8], [3.6, -76.0], [8.6, -75.2], [10.4, -76.4], [8.0, -96.4], [-2.6, -88.0], [2.8, -80.5]]:
		_prop_g(g, "champignons_lumineux", r[0], r[1], float(i * 53 % 360), 1.0, "Champignons_%d" % i)
		i += 1
	# troncs couchés qui ferment les impasses ; souches et pierres plates le long du chemin
	_prop_g(g, "tronc_couche", 13.0, -80.0, 75.0, 1.0, "Impasse_1_tronc")
	_prop_g(g, "rocher_b", 11.0, -80.4, 120.0, 1.0, "Impasse_1_rocher")
	_prop_g(g, "tronc_couche", 14.6, -100.8, 20.0, 1.0, "Impasse_2_tronc")
	_prop_g(g, "rocher_c", 11.8, -101.2, 200.0, 1.0, "Impasse_2_rocher")
	_prop_g(g, "tronc_couche", -13.8, -17.6 + 3.2, 90.0, 1.0, "Lisiere_tronc")
	_prop_g(g, "racines_basses", -9.5, -17.8, 40.0, 1.0, "Lisiere_racines")
	_prop_g(g, "racines_arche", _px(-4.0), -4.0, 0.0, 1.15, "Lisiere_arche_racines")
	_prop_g(g, "rocher_a", -3.4, -6.0, 40.0, 1.0, "Lisiere_rocher_1")
	_prop_g(g, "rocher_b", 3.8, -14.4, 10.0, 1.0, "Lisiere_rocher_2")
	for r in [[0.0, -20.0], [-3.0, -33.0], [0.4, -64.0], [1.2, -69.0]]:
		_prop_g(g, "pierres_plates", r[0], r[1], 20.0, 1.0, "Pierres_%d" % int(-r[1]))
	# le cadre de porte d'arrivée, envahi de racines
	_prop_g(g, "racines_basses", -1.5, 9.0, 20.0, 1.2, "Cadre_racines_1")
	_prop_g(g, "racines_basses", 1.6, 9.2, 200.0, 1.2, "Cadre_racines_2")
	_prop_g(g, "racines_basses", 0.4, 7.4, 100.0, 1.0, "Cadre_racines_3")
	# autour de la jeune fille : souche, lanterne éteinte, fougères
	_prop_g(g, "lanterne_eteinte", -7.4, -22.4, 0.0, 1.0, "Lanterne_eteinte")
	for r in [[-8.0, -24.6], [-7.0, -26.2], [-5.8, -21.8], [-9.0, -22.8]]:
		_prop_g(g, "fougere", r[0], r[1], float(r[1] * 13.0), 1.0, "Fougere_jf_%d" % int(-r[1]))
	_prop_g(g, "arbre_tordu_c", -10.5, -24.5, 0.0, 1.1, "Arbre_jf")

# ================================================================== petites plantes (MultiMesh, déterministe)

## Taches de plantes : [id, x, z, rayon, nombre]. Positions : hachage entier déterministe (aucune graine aléatoire).
const PATCHES := [
	["fougere", -4.5, 2.0, 5.0, 26], ["fougere", 4.5, -6.0, 5.0, 22], ["herbes_touffe", 0.0, -9.0, 6.0, 30], ["fougere", -5.5, -15.0, 4.0, 18],
	["herbes_touffe", 3.0, -20.0, 5.0, 26], ["fougere", -9.0, -24.0, 5.0, 24], ["herbes_touffe", 0.0, -30.0, 6.0, 28],
	["herbes_touffe", -12.0, -38.0, 5.0, 24], ["herbes_touffe", 12.0, -39.0, 5.0, 24], ["herbes_touffe", 0.0, -63.0, 5.0, 22],
	["fougere", 3.0, -70.0, 4.0, 16], ["fougere", -3.0, -80.0, 4.0, 16], ["fougere", 3.5, -89.0, 4.0, 14], ["fougere", -3.0, -97.0, 3.5, 14],
	["fleurs_blanches", 0.0, -120.0, 8.0, 36], ["herbes_touffe", 5.0, -128.0, 9.0, 40], ["fleurs_blanches", -6.0, -128.0, 7.0, 30], ["herbes_touffe", -6.0, -115.0, 5.0, 22]]

func _hash(n: int) -> float:
	var h := (n * 73856093) ^ (n * 19349663) ^ (n * 83492791)
	return float(absi(h) % 10000) / 10000.0

func _plants(g: Node3D) -> void:
	var by_id := {}
	var pi := 0
	for p in PATCHES:
		if not by_id.has(p[0]):
			by_id[p[0]] = []
		for k in int(p[4]):
			var a := TAU * _hash(pi * 131 + k * 7 + 1)
			var r := float(p[3]) * sqrt(_hash(pi * 211 + k * 13 + 5))
			var x: float = p[1] + cos(a) * r
			var z: float = p[2] + sin(a) * r
			if _dplay(x, z) > -0.3 or ground(x, z) < WATER_Y + 0.2:
				continue                                              # seulement sur le sol praticable, jamais dans l'eau
			var onpath := false
			for c in all_center:
				if Vector2(x, z).distance_to(c) < 1.5:
					onpath = true
					break
			if onpath:
				continue
			(by_id[p[0]] as Array).append(Transform3D(Basis(Vector3.UP, TAU * _hash(pi * 17 + k)).scaled(Vector3.ONE * (0.8 + 0.5 * _hash(pi * 5 + k * 3))), Vector3(x, ground(x, z), z)))
		pi += 1
	for id in by_id:
		var xfs: Array = by_id[id]
		if xfs.is_empty():
			continue
		var src := _prop(g, id, Vector3.ZERO)
		var found := src.find_children("*", "MeshInstance3D", true, false)
		var mesh: Mesh = (found[0] as MeshInstance3D).mesh if not found.is_empty() else null
		src.free()
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xfs.size()
		for q in xfs.size():
			mm.set_instance_transform(q, xfs[q])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Plantes_" + String(id)
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(mmi)
		_tri_total += StyleKit.triangles(mesh) * xfs.size()
		print("plantes %-20s %d instances" % [id, xfs.size()])

# ================================================================== limites

func _limits(g: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "MursInvisibles"
	g.add_child(body)
	var minx := -39.0
	var maxx := 39.0
	for w in [["nord", Vector3(0, 12, -150.5), Vector3(82, 60, 1)], ["sud", Vector3(0, 12, 13.5), Vector3(82, 60, 1)],
			["ouest", Vector3(-39.5, 12, -68), Vector3(1, 60, 170)], ["est", Vector3(39.5, 12, -68), Vector3(1, 60, 170)]]:
		var cs := CollisionShape3D.new()
		cs.name = w[0]
		var bs := BoxShape3D.new()
		bs.size = w[2]
		cs.shape = bs
		cs.position = w[1]
		body.add_child(cs)

# ================================================================== repères d'arrivée

func _spawns(g: Node3D) -> void:
	_marker(g, "depart", _at(0.0, 3.6, 0.05), 0.0)               # devant le cadre de porte, regard vers le nord
	_marker(g, "marais", _at(0.0, -33.2, 0.05), 0.0)             # rive sud de l'étang
	_marker(g, "bois_noir", _at(0.0, -64.5, 0.05), 0.0)          # rive nord, entrée du bois noir
	_marker(g, "clairiere", _at(0.0, -114.0, 0.05), 0.0)         # entrée de la clairière, après la porte de lune

# ================================================================== gameplay

func _gameplay(g: Node3D) -> void:
	var etat := ForetEtat.new()
	etat.name = "Etat"
	g.add_child(etat)

	# cadre de porte isolé (arrivée) : on vient de l'hôtel
	var port := _group(g, "Portes")
	var cadre := _prop_g(port, "cadre_porte_reve", 0.0, 8.6, 0.0, 1.0, "Cadre_porte_reve")
	# porte « Se réveiller » dans la clairière
	var pr_pos := _at(8.5, -127.5)
	var pr := _prop(port, "cadre_porte_reve", pr_pos, -90.0, 1.0, "Cadre_reveil")
	var glow := MeshInstance3D.new()
	glow.name = "Lueur"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.3, 2.4)
	var gm := _std(Color(0.72, 1.0, 0.95), 0.5, 2.2)
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = gm
	glow.mesh = quad
	glow.position = Vector3(0, 1.25, 0.0)
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pr.add_child(glow)
	var door := PorteReveil.new()
	door.name = "Porte_du_reve"
	door.position = pr_pos + Vector3(0, 1.2, 0.0)
	door.rotation_degrees = Vector3(0, -90.0, 0)
	port.add_child(door)

	# énigme 1 : trois fleurs-lanternes et le pont de racines
	var fl := _group(g, "Fleurs")
	var fpos := [[-13.5, -40.5], [13.5, -41.5], [-2.2, -46.0]]
	var i := 1
	for p in fpos:
		var f := FleurLanterne.new()
		f.name = "Fleur_%d" % i
		f.position = _at(p[0], p[1])
		fl.add_child(f)
		var m := _prop(f, "fleur_lanterne", Vector3.ZERO, 0.0, 1.0, "Fleur")
		i += 1
	_passerelle(g)
	_pont(g)

	# énigme 2 : piédestal de lune (ruine latérale) et porte de ruine
	var ped := PiedestalLune.new()
	ped.name = "Piedestal"
	ped.position = _at(-18.5, -88.5)
	ped.reach = 3.4
	g.add_child(ped)
	_prop(ped, "piedestal_lune", Vector3.ZERO, 0.0, 1.0, "Module")
	# porte de lune : le module (vantaux VantailG / VantailD) et l'interaction partagent le même parent
	var door_root := _group(g, "Porte_de_lune")
	_prop_g(door_root, "ruine_porte_lune", 0.0, -108.0, 0.0, 1.0, "Ruine")
	var pl := PorteLune.new()
	pl.name = "PorteLune"
	pl.position = _at(0.0, -108.0) + Vector3(0, 1.3, 0.0)
	door_root.add_child(pl)
	_body_box(pl, Vector3(3.6, 3.8, 0.6), Vector3(0, 0.6, 0.0), "Blocage")

	_jeune_fille(g)
	_ombres_et_feux(g)

func _passerelle(g: Node3D) -> void:
	var p := _group(g, "Passerelle")
	var bark := _sm("ecorce", Color(0.13, 0.12, 0.17))
	var logs := _cached("passerelle_billes", func() -> Mesh:
		return StyleKit.merge([[_cyl(0.36, 0.34, 8.7, bark, 9), _xf(Vector3(0, 0, 0), Vector3(-90, 0, 0))]]))
	var i := 0
	for x in [-0.95, 0.0, 0.95]:
		var mi := _mi(p, "Bille_%d" % i, logs, Vector3(x, DECK_Y - 0.36, -34.4))
		i += 1
	# traverses (planches posées en travers)
	var plank := _cached("passerelle_traverse", func() -> Mesh: return StyleKit.rounded_box(Vector3(2.9, 0.08, 0.3), 0.02, bark, 1))
	i = 0
	for z in [-35.2, -36.8, -38.4, -40.0, -41.6, -42.8]:
		_mi(p, "Traverse_%d" % i, plank, Vector3(0, DECK_Y - 0.01, z))
		i += 1
	_body_box(p, Vector3(2.8, 0.3, 8.9), Vector3(0, DECK_Y - 0.15, -38.8), "Plancher")
	p.set_meta("sur_pont", true)

func _pont(g: Node3D) -> void:
	var pont := PontRacines.new()
	pont.name = "PontRacines"
	g.add_child(pont)
	var bark := _sm("ecorce", Color(0.15, 0.13, 0.18))
	var seg := _cached("racine_segment", func() -> Mesh:
		return StyleKit.merge([[StyleKit.rounded_box(Vector3(2.7, 0.36, 2.7), 0.1, bark, 2), _xf(Vector3(0, DECK_Y - 0.18, 0))],
			[_cyl(0.3, 0.22, 2.7, bark, 8), _xf(Vector3(-1.35, DECK_Y - 0.34, 1.35), Vector3(-90, 0, 0))], [_cyl(0.3, 0.22, 2.7, bark, 8), _xf(Vector3(1.35, DECK_Y - 0.34, 1.35), Vector3(-90, 0, 0))]]))
	for k in 5:
		var piv := Node3D.new()
		piv.name = "Racine_%d" % (k + 1)
		piv.position = Vector3(0.0, 0.0, -49.9 - 2.4 * k)
		pont.add_child(piv)
		_mi(piv, "Maillage", seg, Vector3.ZERO)
	var pl := _body_box(pont, Vector3(2.8, 0.3, 13.6), Vector3(0, DECK_Y - 0.15, -54.3), "Plancher")
	var ba := _body_box(pont, Vector3(3.0, 4.6, 13.6), Vector3(0, WATER_Y + 0.3, -54.3), "Barriere")
	pl.collision_layer = 0
	pont.set_meta("sur_pont", true)

func _jeune_fille(g: Node3D) -> void:
	var etapes := _group(g, "Etapes")
	var steps := [
		[-6.2, -23.6, {}], [-3.5, -29.0, {}], [0.0, -33.5, {}], [0.0, -46.0, {}],
		[0.0, -61.8, {"requiert": "pont"}], [1.5, -67.0, {"proche": true}]]
	for z in [-71.0, -75.5, -80.0, -84.5, -89.0, -93.5, -98.0, -102.0]:
		steps.append([_px(z), z, {"proche": true}])
	steps.append([0.0, -104.4, {"proche": true}])
	steps.append([0.0, -112.5, {"requiert": "porte"}])
	steps.append([0.0, -118.0, {}])
	steps.append([-1.0, -123.0, {}])
	steps.append([-3.0, -126.5, {"fin": true}])
	var i := 0
	for s in steps:
		var m := Marker3D.new()
		m.name = "Etape_%02d" % i
		m.position = _at(s[0], s[1])
		for key in (s[2] as Dictionary):
			m.set_meta(key, (s[2] as Dictionary)[key])
		etapes.add_child(m)
		i += 1
	var souche := _prop_g(g, "souche", -6.2, -23.6, 70.0, 1.0, "Souche_jeune_fille")
	var jf := JeuneFille.new()
	jf.name = "JeuneFille"
	jf.position = _at(-6.2, -23.6, 0.55)
	jf.rotation_degrees = Vector3(0, -110.0, 0)
	jf.etapes = ^"../Etapes"
	g.add_child(jf)
	_prop(jf, "jeune_fille_provisoire", Vector3.ZERO, 0.0, 1.0, "Modele")

func _ombres_et_feux(g: Node3D) -> void:
	var sh := _group(g, "Silhouettes")
	var i := 1
	for p in [[6.5, -69.5], [-6.0, -78.0], [7.5, -86.0], [-5.5, -95.0], [6.0, -102.0]]:
		var s := SilhouetteOmbre.new()
		s.name = "Silhouette_%d" % i
		s.position = _at(p[0], p[1])
		sh.add_child(s)
		_prop(s, "silhouette_ombre", Vector3.ZERO, 0.0, 1.0, "Modele")
		i += 1
	var ff := _group(g, "Feux_follets")
	for f in [["Feu_follet_1", [5.0, -74.0], [12.4, -78.0]], ["Feu_follet_2", [5.2, -94.6], [12.6, -99.2]], ["Feu_follet_3", [-6.0, -85.0], [-12.8, -86.2]]]:
		var w := FeuFollet.new()
		w.name = f[0]
		var p0: Vector3 = _at(f[1][0], f[1][1], 1.3)
		w.position = p0
		w.repli = _at(f[2][0], f[2][1], 1.3)
		ff.add_child(w)
		var orb := MeshInstance3D.new()
		orb.name = "Lueur"
		orb.mesh = _cached("feu_follet", func() -> Mesh: return StyleKit.sphere(0.13, _sm("feu_follet", Color(0.7, 1.0, 0.95), 0.4, 3.0), 10, 6))
		orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.add_child(orb)
		var l := OmniLight3D.new()
		l.name = "Lumiere"
		l.light_color = Color(0.6, 1.0, 0.95)
		l.light_energy = 1.2
		l.omni_range = 4.5
		w.add_child(l)

# ================================================================== lumières

func _lights(g: Node3D) -> void:
	var dream := Color(0.55, 1.0, 0.9)
	AuthorKit.omni(g, "cadre_arrivee", _at(0.0, 8.0, 1.5), dream, 2.2, 8.0)
	AuthorKit.omni(g, "jeune_fille", _at(-6.6, -23.6, 1.3), Color(1.0, 0.7, 0.4), 0.9, 4.5)
	AuthorKit.omni(g, "reveil", _at(7.6, -127.5, 1.4), Color(0.7, 1.0, 0.95), 2.4, 7.0)
	AuthorKit.omni(g, "ruine_ouest", _at(-17.0, -87.5, 2.2), Color(0.45, 0.7, 1.0), 1.0, 6.0)
	AuthorKit.omni(g, "porte_de_lune", _at(0.0, -105.8, 2.4), Color(0.55, 0.75, 1.0), 1.0, 5.0)

func _zones_meta() -> void:
	var chem := PackedVector3Array()
	for p in path_dense:
		chem.append(Vector3(p[0], _elev(p[1]), p[1]))
	lvl.set_meta("foret_zones", {
		"eau_y": WATER_Y, "eau_centre": Vector3(0, WATER_Y, -47.0), "eau_taille": Vector2(60.0, 25.0), "chemin": chem,
		"lisiere": Vector3(0, 0, -6), "jeune_fille": Vector3(-6.2, 0, -23.6), "marais": Vector3(0, LAND, -47.0), "ilot": Vector3(0, LAND, -45.4),
		"bois_noir": Vector3(0, 1.0, -86), "porte_de_ruine": Vector3(0, 2.1, -108), "clairiere": Vector3(0, 2.4, -128), "arbre_ancien": Vector3(0, 2.8, -141)})

# ================================================================== enregistrement

func _own(n: Node) -> void:
	for c in n.get_children():
		c.owner = lvl
		if c.scene_file_path == "":
			_own(c)

func _save() -> void:
	print("contrôles de dégagement : %d avertissement(s)" % warn)
	_own(lvl)
	var packed := PackedScene.new()
	var perr := packed.pack(lvl)
	var err := ResourceSaver.save(packed, SCENE_OUT)
	print("scène enregistrée : foret_de_la_peur.tscn (pack %d, save %s)" % [perr, "ok" if err == OK else "ERREUR %d" % err])
	lvl.free()
	quit()
