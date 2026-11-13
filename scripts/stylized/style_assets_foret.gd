@tool
class_name StyleAssetsForet
extends RefCounted
## KIT ORGANIQUE PROVISOIRE de la Forêt de la peur (arbres, troncs, racines, rochers, plantes, ruines, mise en scène).
##
## LOGIQUE DU KIT
## - Tout est généré par script (aucune texture, aucun import) : formes pleines et arrondies, ombrage lisse, silhouettes fortes
##   (troncs qui se tordent et se divisent, racines en arche, houppiers en 3 à 6 masses lisses, exagération onirique).
##   Trois primitives organiques maison, toutes à normales lisses (différences finies sur une grille de sommets) :
##     _tube : tube lissé (Catmull-Rom) à rayon variable, section ronde ou aplatie (feuilles, planches), bouts arrondis ;
##     _blob : ellipsoïde bosselé (houppiers, rochers, mousses, champignons) ; les bosses viennent de sinus déphasés par un
##             hachage de l'indice : AUCUN hasard à l'exécution, un module est identique à chaque fabrication ;
##     StyleKit.lathe / rounded_box / extrude : colonnes, pierres taillées, arches, cadres.
## - Un maillage fusionné par module (une surface par matériau, matériaux partagés : style_materials_foret.gd, ≤ 14, plus
##   quelques matériaux existants du Bureau des rêves : or, lune, lin_creme, lin_lavande, bois_sombre, verre_chaud).
##   Les pièces mobiles ou nommées (Corolle, Racine_N, VantailG/D, Debout/Assise, Pierre) sont des MeshInstance3D enfants.
## - Convention : 1 unité = 1 m, origine AU SOL et centrée, face avant = +Z (comme les portes du Bureau des rêves).
## - Collisions simples : cylindres (troncs, souches, pierres, colonnes) et boîtes (ruines, tronc couché, rochers) ; aucune sur
##   les petites plantes. Budgets : arbre ≤ 6 000 triangles (arbre_ancien ≤ 12 000), rocher / petit élément ≤ 2 000, plantes
##   répétées (herbes_touffe, fougere, champignons_lumineux, fleurs_blanches, nenuphars, roseaux) ≤ 600 (dispersées en MultiMesh).
##
## NŒUDS NOMMÉS POUR LE NIVEAU (Sonnet A)
##   fleur_lanterne      : Corolle (MeshInstance3D, matière « éteinte » nenuphar_lueur) + Lumiere (OmniLight3D cyan, visible = false).
##   pont_racines        : Racine_1…Racine_4 (pivots, méta « pose_couchee » = rotation en degrés, ici lever = rotation 0 ;
##                         pivot en bout sud, racine vers −Z) + PontCollision (StaticBody3D, activable : collision_layer = 0
##                         ou shape.disabled). Origine = niveau de l'eau, dessus de marche ≈ 0,45 m, longueur 7 m, largeur 1,7 m.
##   ruine_porte_lune    : VantailG / VantailD (pivots aux charnières, fermés = rotation 0, chacun avec Collision).
##   piedestal_lune      : Pierre (MeshInstance3D, la pierre de lune au sommet).
##   jeune_fille_provisoire : Debout et Assise (un seul visible : Debout). Assise : pieds / jupe à y = 0 → poser le module au
##                         niveau de l'assise (souche : ≈ 0,55 m).
##   cadre_porte_reve, silhouette_ombre : un seul maillage, face avant +Z.
##
## REMPLACEMENT PAR UN .glb BLENDER : garder le même id (assets/stylized/modules/<id>.tscn → scène issue du .glb), la même
## origine (au sol, centrée), la même orientation (+Z), la même empreinte de collision (StaticBody3D enfant) et les mêmes
## nœuds nommés ci-dessus. Le niveau n'a alors rien à changer.
## Hors de StyleAssets.all_ids() (budget du Bureau des rêves séparé) ; fabriqué par build_stylized_assets.gd.

static func ids() -> PackedStringArray:
	return PackedStringArray([
		"arbre_tordu_a", "arbre_tordu_b", "arbre_tordu_c", "arbre_echasses", "arbre_mort", "arbre_ancien",
		"tronc_couche", "souche", "racines_arche", "racines_basses",
		"rocher_a", "rocher_b", "rocher_c", "pierres_plates", "cercle_pierres",
		"arbuste_a", "arbuste_b", "fougere", "herbes_touffe", "roseaux", "champignons_lumineux", "nenuphars", "fleurs_blanches",
		"ruine_arche", "ruine_colonne", "ruine_mur", "ruine_porte_lune", "piedestal_lune",
		"cadre_porte_reve", "fleur_lanterne", "pont_racines", "silhouette_ombre", "jeune_fille_provisoire",
	])

static func make(id: String) -> ModuleBuilder:
	match id:
		"arbre_tordu_a": return _tree(id, {"seed": 3, "h": 9.5, "br": 0.52, "limbs": 3, "masses": 4, "lean": Vector2(0.16, 0.03), "sway": 0.07, "roots": 5, "fork": 0.5})
		"arbre_tordu_b": return _tree(id, {"seed": 11, "h": 11.5, "br": 0.58, "limbs": 3, "masses": 6, "lean": Vector2(-0.1, 0.14), "sway": 0.1, "roots": 5, "fork": 0.46})
		"arbre_tordu_c": return _tree(id, {"seed": 23, "h": 13.5, "br": 0.62, "limbs": 2, "masses": 3, "lean": Vector2(0.05, -0.18), "sway": 0.12, "roots": 6, "fork": 0.55, "mass_k": 1.2})
		"arbre_echasses": return _tree(id, {"seed": 37, "h": 10.0, "br": 0.5, "limbs": 3, "masses": 5, "lean": Vector2(0.06, 0.06), "sway": 0.05, "stilts": 7, "fork": 0.58})
		"arbre_mort": return _tree(id, {"seed": 53, "h": 8.5, "br": 0.46, "limbs": 3, "masses": 0, "lean": Vector2(-0.14, 0.1), "sway": 0.09, "roots": 4, "fork": 0.5, "dead": true})
		"arbre_ancien": return _ancien(id)
		"tronc_couche": return _tronc_couche(id)
		"souche": return _souche(id)
		"racines_arche": return _racines_arche(id)
		"racines_basses": return _racines_basses(id)
		"rocher_a": return _rocher(id, 0, 0.5)
		"rocher_b": return _rocher(id, 1, 0.8)
		"rocher_c": return _rocher(id, 2, 1.25)
		"pierres_plates": return _pierres_plates(id)
		"cercle_pierres": return _cercle_pierres(id)
		"arbuste_a": return _arbuste_a(id)
		"arbuste_b": return _arbuste_b(id)
		"fougere": return _fougere(id)
		"herbes_touffe": return _herbes(id)
		"roseaux": return _roseaux(id)
		"champignons_lumineux": return _champignons(id)
		"nenuphars": return _nenuphars(id)
		"fleurs_blanches": return _fleurs_blanches(id)
		"ruine_arche": return _ruine_arche(id)
		"ruine_colonne": return _ruine_colonne(id)
		"ruine_mur": return _ruine_mur(id)
		"ruine_porte_lune": return _porte_lune(id)
		"piedestal_lune": return _piedestal(id)
		"cadre_porte_reve": return _cadre(id)
		"fleur_lanterne": return _fleur_lanterne(id)
		"pont_racines": return _pont(id)
		"silhouette_ombre": return _silhouette(id)
		"jeune_fille_provisoire": return _fille(id)
	return null

# ================================================================== primitives organiques

static func M(n: String) -> Material:
	return StyleMaterials.get_mat(n)

static func _h(i: int, salt := 0) -> float:
	return StyleAssetsAtrium.hash01(i, salt)

## Maillage lisse à partir de rangées de sommets (même nombre par rangée, rangée fermée) : normales par différences finies,
## orientées vers l'extérieur (sens choisi par vote sur le maillage entier), rangées dégénérées (pôles) gérées.
static func _rows_mesh(rows: Array, centers: Array, mat: Material) -> ArrayMesh:
	var nr := rows.size()
	var nc: int = (rows[0] as PackedVector3Array).size()
	var raw: Array = []
	var total := 0.0
	for j in nr:
		var row: PackedVector3Array = rows[j]
		var rn := PackedVector3Array()
		rn.resize(nc)
		var up: PackedVector3Array = rows[mini(j + 1, nr - 1)]
		var dn: PackedVector3Array = rows[maxi(j - 1, 0)]
		for i in nc:
			var du: Vector3 = row[(i + 1) % nc] - row[(i - 1 + nc) % nc]
			var dv: Vector3 = up[i] - dn[i]
			var n := du.cross(dv)
			if n.length_squared() > 1e-14:
				var out: Vector3 = row[i] - (centers[j] as Vector3)
				if out.length_squared() > 1e-10:
					total += n.normalized().dot(out.normalized())
			rn[i] = n
		raw.append(rn)
	var sgn := -1.0 if total < 0.0 else 1.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nrm: Array = []
	for j in nr:
		var row: PackedVector3Array = rows[j]
		var rn: PackedVector3Array = raw[j]
		var fin := PackedVector3Array()
		fin.resize(nc)
		for i in nc:
			var n: Vector3 = rn[i]
			if n.length_squared() > 1e-14:
				fin[i] = n.normalized() * sgn
			else:
				var out: Vector3 = row[i] - (centers[j] as Vector3)
				fin[i] = out.normalized() if out.length_squared() > 1e-12 else Vector3.UP
		nrm.append(fin)
	for j in nr - 1:
		var r0: PackedVector3Array = rows[j]
		var r1: PackedVector3Array = rows[j + 1]
		var n0: PackedVector3Array = nrm[j]
		var n1: PackedVector3Array = nrm[j + 1]
		for i in nc:
			var i2 := (i + 1) % nc
			var p := [r0[i], r0[i2], r1[i2], r1[i]]
			var nn := [n0[i], n0[i2], n1[i2], n1[i]]
			var uv := [Vector2(float(i) / nc, float(j) / (nr - 1)), Vector2(float(i + 1) / nc, float(j) / (nr - 1)), Vector2(float(i + 1) / nc, float(j + 1) / (nr - 1)), Vector2(float(i) / nc, float(j + 1) / (nr - 1))]
			for tri in ([[0, 1, 2], [0, 2, 3]] if sgn > 0.0 else [[0, 2, 1], [0, 3, 2]]):
				var a: Vector3 = p[tri[0]]
				var b: Vector3 = p[tri[1]]
				var c: Vector3 = p[tri[2]]
				if (b - a).cross(c - a).length_squared() < 1e-12:
					continue
				for t in tri:
					st.set_normal(nn[t])
					st.set_uv(uv[t])
					st.add_vertex(p[t])
	return StyleKit._commit(st, mat)

static func _cr(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)

## Tube lissé passant par `pts` (Catmull-Rom), rayon interpolé entre les `radii`. Options : per (sous-divisions par tronçon),
## segs (côtés), cap0 / cap1 (bouts arrondis), capn (rangées d'arrondi), flat (aplatissement de la section),
## wdir (axe de la largeur, pour feuilles et planches ; sinon repère transporté).
static func _tube_mesh(pts: Array, radii: Array, mat: Material, o := {}) -> ArrayMesh:
	var per: int = o.get("per", 3)
	var segs: int = o.get("segs", 8)
	var cap0: bool = o.get("cap0", false)
	var cap1: bool = o.get("cap1", true)
	var capn: int = o.get("capn", 3)
	var flat: float = o.get("flat", 1.0)
	var wdir: Vector3 = o.get("wdir", Vector3.ZERO)
	var n := pts.size()
	var P: Array = []
	var R: Array = []
	for s in n - 1:
		var p0: Vector3 = pts[maxi(s - 1, 0)]
		var p1: Vector3 = pts[s]
		var p2: Vector3 = pts[s + 1]
		var p3: Vector3 = pts[mini(s + 2, n - 1)]
		for k in per:
			var t := float(k) / per
			P.append(_cr(p0, p1, p2, p3, t))
			R.append(lerpf(radii[s], radii[s + 1], t * t * (3.0 - 2.0 * t)))
	P.append(pts[n - 1])
	R.append(radii[n - 1])
	var m := P.size()
	var T: Array = []
	for k in m:
		var d: Vector3 = (P[mini(k + 1, m - 1)] as Vector3) - (P[maxi(k - 1, 0)] as Vector3)
		T.append(d.normalized() if d.length_squared() > 1e-12 else Vector3.UP)
	var rows: Array = []
	var centers: Array = []
	var W := Vector3.ZERO
	var angs: Array = []
	for i in segs:
		angs.append(TAU * float(i) / segs)
	var make_row := func(c: Vector3, t: Vector3, w: Vector3, r: float, shift: float) -> PackedVector3Array:
		var v := t.cross(w).normalized()
		var row := PackedVector3Array()
		for a in angs:
			row.append(c + t * shift + (w * cos(a) * r + v * sin(a) * r * flat))
		return row
	var start_rows: Array = []
	var end_rows: Array = []
	var start_frame := Vector3.ZERO
	for k in m:
		var t: Vector3 = T[k]
		if k == 0:
			if wdir != Vector3.ZERO:
				W = wdir - t * wdir.dot(t)
			else:
				W = t.cross(Vector3.RIGHT if absf(t.x) < 0.9 else Vector3.UP)
			W = W.normalized()
			start_frame = W
		else:
			if wdir != Vector3.ZERO:
				W = wdir - t * wdir.dot(t)
			else:
				W = W - t * W.dot(t)
			if W.length_squared() < 1e-10:
				W = t.cross(Vector3.RIGHT)
			W = W.normalized()
		rows.append(make_row.call(P[k], t, W, R[k], 0.0))
		centers.append(P[k])
		if k == m - 1 and cap1:
			for q in capn:
				var ph := (PI * 0.5) * float(q + 1) / capn
				ph = minf(ph, PI * 0.5)
				var lift: float = sin(ph) * float(R[k]) * 0.9
				var rr: float = cos(ph) * float(R[k])
				if q == capn - 1:
					rr = 0.0
				rows.append(make_row.call(P[k], t, W, rr, lift))
				centers.append(P[k])
		if k == 0 and cap0:
			for q in capn:
				var ph := (PI * 0.5) * float(q + 1) / capn
				var lift: float = -sin(ph) * float(R[0]) * 0.9
				var rr: float = cos(ph) * float(R[0])
				if q == capn - 1:
					rr = 0.0
				start_rows.append(make_row.call(P[0], t, W, rr, lift))
	if cap0:
		start_rows.reverse()
		var sc: Array = []
		for r in start_rows:
			sc.append(P[0])
		rows = start_rows + rows
		centers = sc + centers
	return _rows_mesh(rows, centers, mat)

## Pseudo-bruit lisse (somme de trois sinus orientés, déphasés par la graine) sur la direction `dir`, dans [-1, 1].
static func _lump(dir: Vector3, seed: int) -> float:
	var s := 0.0
	for k in 3:
		var a := _h(seed, 11 + k) * TAU
		var e := (_h(seed, 21 + k) - 0.5) * PI
		var axis := Vector3(cos(a) * cos(e), sin(e), sin(a) * cos(e))
		s += sin(dir.dot(axis) * (2.4 + 1.5 * k) + _h(seed, 31 + k) * TAU) / (1.0 + 0.7 * k)
	return clampf(s / 1.7, -1.0, 1.0)

## Ellipsoïde bosselé, centre `c`, demi-axes `r`, orienté par `rot_deg`.
static func _blob_mesh(c: Vector3, r: Vector3, mat: Material, seed: int, amp := 0.12, lon := 14, lat := 8, rot_deg := Vector3.ZERO) -> ArrayMesh:
	var basis := Basis.from_euler(rot_deg * (PI / 180.0))
	var rows: Array = []
	var centers: Array = []
	for j in lat + 1:
		var ph := -PI * 0.5 + PI * float(j) / lat
		var row := PackedVector3Array()
		for i in lon:
			var th := TAU * float(i) / lon
			var dir := Vector3(cos(ph) * cos(th), sin(ph), cos(ph) * sin(th))
			var k := 1.0 + amp * _lump(dir, seed)
			row.append(c + basis * (dir * r * k))
		rows.append(row)
		centers.append(c)
	return _rows_mesh(rows, centers, mat)

static func _tube(b: ModuleBuilder, pts: Array, radii: Array, mat: Material, o := {}) -> void:
	b.add(_tube_mesh(pts, radii, mat, o))

static func _blob(b: ModuleBuilder, c: Vector3, r: Vector3, mat: Material, seed: int, amp := 0.12, lon := 14, lat := 8, rot_deg := Vector3.ZERO) -> void:
	b.add(_blob_mesh(c, r, mat, seed, amp, lon, lat, rot_deg))

## Corps cylindrique de collision (troncs, souches, pierres, colonnes) : enfant « <nom> » du module.
static func _cyl(b: ModuleBuilder, radius: float, height: float, pos: Vector3, nm := "CollisionTronc") -> void:
	var body := StaticBody3D.new()
	body.name = nm
	var cs := CollisionShape3D.new()
	cs.name = "Cylindre"
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	cs.shape = sh
	cs.position = pos + Vector3(0, height * 0.5, 0)
	body.add_child(cs)
	b.extras.append(body)

## MeshInstance3D nommé, issu de pièces [[mesh, xf], …] fusionnées (une surface par matériau).
static func _mesh_node(nm: String, parts: Array, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = StyleKit.merge(parts)
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

static func _box_body(nm: String, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = nm
	var cs := CollisionShape3D.new()
	cs.name = "Boite"
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	body.add_child(cs)
	return body

# ================================================================== arbres

static func _dir(a: float) -> Vector3:
	return Vector3(cos(a), 0.0, sin(a))

## Arbre tordu : tronc évasé qui sinue, fourche en 2-4 charpentières, branches latérales, 3-6 masses lisses de feuillage
## aux extrémités, grosses racines, mousse sur les racines et dans la fourche.
static func _tree(id: String, o: Dictionary) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var sd: int = o["seed"]
	var h: float = o["h"]
	var br: float = o["br"]
	var dead: bool = o.get("dead", false)
	var stilts: int = o.get("stilts", 0)
	var bark := M("ecorce_morte" if dead else "ecorce_foret")
	var moss := M("mousse")
	var fork_t: float = o.get("fork", 0.5)
	var lean: Vector2 = o.get("lean", Vector2.ZERO)
	var sway: float = float(o.get("sway", 0.07)) * h
	var ph := _h(sd, 1) * TAU
	var y0 := 1.5 if stilts > 0 else 0.0
	# --- tronc
	var pts: Array = []
	var rad: Array = []
	var nt := 5
	for k in nt + 1:
		var t := float(k) / nt
		var y := lerpf(y0 - (0.0 if stilts > 0 else 0.2), fork_t * h, t)
		pts.append(Vector3(lean.x * h * t * t * 0.5 + sway * sin(t * PI * 1.4 + ph) * t, y, lean.y * h * t * t * 0.5 + sway * cos(t * PI * 1.1 + ph) * t))
		rad.append(br * (0.66 + 0.34 * (1.0 - t)) * (1.0 + (0.0 if stilts > 0 else 0.55 * pow(1.0 - t, 5.0))))
	_tube(b, pts, rad, bark, {"per": 3, "segs": 14, "cap0": true})
	var base: Vector3 = pts[0]
	var F: Vector3 = pts[nt]
	var top_r: float = rad[nt]
	# --- racines
	var nr: int = stilts if stilts > 0 else int(o.get("roots", 5))
	for i in nr:
		var a := ph + TAU * float(i) / nr + (_h(sd, 40 + i) - 0.5) * 0.6
		var d := _dir(a)
		var side := Vector3(-d.z, 0, d.x)
		var wob := (_h(sd, 60 + i) - 0.5) * br * 1.2
		var rp: Array
		var rr: Array
		if stilts > 0:
			rp = [base + d * br * 0.2 + Vector3(0, 0.5, 0), base + d * br * 1.6 + Vector3(0, 0.9, 0) + side * wob * 0.3, base + d * 2.0 + Vector3(0, 0.15, 0) + side * wob, base + d * (2.8 + 0.6 * _h(sd, 70 + i)) + Vector3(0, -0.15, 0) + side * wob * 1.4]
			rr = [br * 0.5, br * 0.36, br * 0.26, br * 0.2]
		else:
			var len := 1.0 + 0.5 * _h(sd, 70 + i)
			rp = [base + d * br * 0.5 + Vector3(0, br * 1.5, 0), base + d * br * 1.6 * len + Vector3(0, br * 0.75, 0) + side * wob * 0.4, base + d * br * 2.6 * len + Vector3(0, br * 0.28, 0) + side * wob * 0.8, base + d * br * 3.8 * len + Vector3(0, -0.12, 0) + side * wob]
			rr = [br * 0.62, br * 0.42, br * 0.3, br * 0.2]
		_tube(b, rp, rr, bark, {"per": 2, "segs": 9})
		if i < 2 and not dead:
			var mc: Vector3 = rp[1] + Vector3(0, rr[1] * 0.7, 0)
			_blob(b, mc, Vector3(rr[1] * 1.5, rr[1] * 0.38, rr[1] * 1.5), moss, sd * 7 + i, 0.15, 10, 5)
	# --- charpentières
	var nl: int = o.get("limbs", 3)
	var tips: Array = []
	var twig_pts: Array = []
	for i in nl:
		var a := ph + 0.5 + TAU * float(i) / nl + (_h(sd, 80 + i) - 0.5) * 0.8
		var d := _dir(a)
		var side := Vector3(-d.z, 0, d.x) * (1.0 if _h(sd, 90 + i) > 0.5 else -1.0)
		var L := h * (0.34 + 0.12 * _h(sd, 100 + i))
		var lp := [F - Vector3(0, top_r * 0.3, 0), F + d * L * 0.2 + Vector3(0, L * 0.28, 0), F + d * L * 0.5 + side * L * 0.22 + Vector3(0, L * 0.52, 0), F + d * L * 0.95 - side * L * 0.1 + Vector3(0, L * 0.82 + (0.0 if dead else 0.0), 0)]
		var lr := [top_r * 0.85, top_r * 0.58, top_r * 0.34, top_r * 0.15]
		_tube(b, lp, lr, bark, {"per": 3, "segs": 10})
		tips.append(lp[3])
		# branche latérale
		var a2 := a + (1.0 if _h(sd, 110 + i) > 0.5 else -1.0) * (1.0 + 0.4 * _h(sd, 120 + i))
		var d2 := _dir(a2)
		var s0: Vector3 = lp[2]
		var sp := [s0 - Vector3(0, 0.05, 0), s0 + d2 * L * 0.25 + Vector3(0, L * 0.14, 0), s0 + d2 * L * 0.55 + Vector3(0, L * 0.3, 0)]
		_tube(b, sp, [top_r * 0.3, top_r * 0.2, top_r * 0.1], bark, {"per": 3, "segs": 8})
		tips.append(sp[2])
		twig_pts.append([lp[3], d])
		if dead:
			# brindilles cassées
			for q in 2:
				var dq := _dir(a + 1.3 + q * 2.4)
				var s1: Vector3 = lp[3]
				_tube(b, [s1 - Vector3(0, 0.1, 0), s1 + dq * 0.7 + Vector3(0, 0.6, 0), s1 + dq * 1.4 + Vector3(0, 0.9 + 0.3 * q, 0)], [top_r * 0.14, top_r * 0.09, top_r * 0.03], bark, {"per": 2, "segs": 6})
			_tube(b, [sp[2] - Vector3(0, 0.05, 0), sp[2] + d2 * 0.8 + Vector3(0, 0.7, 0)], [top_r * 0.1, top_r * 0.03], bark, {"per": 2, "segs": 6})
	b.add(_blob_mesh(F + Vector3(0, top_r * 0.8, 0), Vector3(top_r * 1.2, top_r * 0.3, top_r * 1.2), moss if not dead else bark, sd, 0.2, 10, 5))
	# --- houppiers : masses lisses
	var nm: int = o.get("masses", 4)
	var mk: float = o.get("mass_k", 1.0)
	var maxy := 0.0
	for t in tips:
		maxy = maxf(maxy, (t as Vector3).y)
	for i in mini(nm, tips.size()):
		var tip: Vector3 = tips[i]
		var R := h * 0.155 * mk * (0.85 + 0.3 * _h(sd, 130 + i))
		var mat := M("feuillage_bleu" if tip.y > maxy * 0.9 else "feuillage_sombre")
		_blob(b, tip + Vector3(0, R * 0.4, 0), Vector3(R, R * 0.74, R), mat, sd * 13 + i, 0.16, 18, 10, Vector3(0, 40.0 * i, 0))
	_cyl(b, br * 0.95, fork_t * h, base + Vector3(0, 0.0, 0))
	return b

## Arbre ancien de la clairière (≈ 18 m) : tronc massif à contreforts, six grosses masses doucement lumineuses.
static func _ancien(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var sd := 71
	var bark := M("ecorce_foret")
	var moss := M("mousse")
	var h := 18.0
	var br := 1.6
	var pts: Array = []
	var rad: Array = []
	for k in 6:
		var t := float(k) / 5.0
		pts.append(Vector3(0.9 * sin(t * 2.4) * t, t * 8.0 - (0.3 if k == 0 else 0.0), 0.7 * cos(t * 2.0 + 0.5) * t))
		rad.append(br * (0.7 + 0.3 * (1.0 - t)) * (1.0 + 0.5 * pow(1.0 - t, 4.0)))
	_tube(b, pts, rad, bark, {"per": 3, "segs": 18, "cap0": true})
	var base: Vector3 = pts[0]
	var F: Vector3 = pts[5]
	var top_r: float = rad[5]
	for i in 8:
		var a := 0.4 + TAU * float(i) / 8.0 + (_h(sd, 40 + i) - 0.5) * 0.4
		var d := _dir(a)
		var side := Vector3(-d.z, 0, d.x)
		var len := 1.0 + 0.5 * _h(sd, 70 + i)
		var wob := (_h(sd, 60 + i) - 0.5) * 1.6
		var rp := [base + d * br * 0.4 + Vector3(0, br * 2.2, 0), base + d * br * 1.5 * len + Vector3(0, br * 1.0, 0) + side * wob * 0.3, base + d * br * 2.6 * len + Vector3(0, br * 0.36, 0) + side * wob * 0.7, base + d * br * 3.8 * len + Vector3(0, -0.2, 0) + side * wob]
		var rr := [br * 0.62, br * 0.4, br * 0.28, br * 0.18]
		_tube(b, rp, rr, bark, {"per": 2, "segs": 10})
		if i % 2 == 0:
			_blob(b, rp[1] + Vector3(0, rr[1] * 0.8, 0), Vector3(rr[1] * 1.7, rr[1] * 0.4, rr[1] * 1.7), moss, sd + i, 0.15, 10, 5)
	var tips: Array = []
	for i in 4:
		var a := 0.9 + TAU * float(i) / 4.0
		var d := _dir(a)
		var side := Vector3(-d.z, 0, d.x) * (1.0 if i % 2 == 0 else -1.0)
		var L := 8.5 + 1.2 * _h(sd, 100 + i)
		var lp := [F - Vector3(0, 0.4, 0), F + d * L * 0.2 + Vector3(0, L * 0.3, 0), F + d * L * 0.5 + side * L * 0.2 + Vector3(0, L * 0.55, 0), F + d * L * 0.9 - side * L * 0.08 + Vector3(0, L * 0.78, 0)]
		_tube(b, lp, [top_r * 0.82, top_r * 0.55, top_r * 0.32, top_r * 0.15], bark, {"per": 3, "segs": 11})
		tips.append(lp[3])
		var s0: Vector3 = lp[2]
		var d2 := _dir(a + 1.4 * (1.0 if i % 2 == 0 else -1.0))
		var sp := [s0, s0 + d2 * L * 0.22 + Vector3(0, L * 0.12, 0), s0 + d2 * L * 0.5 + Vector3(0, L * 0.26, 0)]
		_tube(b, sp, [top_r * 0.28, top_r * 0.18, top_r * 0.09], bark, {"per": 3, "segs": 8})
		if i < 2:
			tips.append(sp[2])
	b.add(_blob_mesh(F + Vector3(0, top_r * 0.8, 0), Vector3(top_r * 1.2, top_r * 0.3, top_r * 1.2), moss, sd, 0.2, 10, 5))
	for i in mini(6, tips.size()):
		var tip: Vector3 = tips[i]
		var R := 3.6 * (0.85 + 0.3 * _h(sd, 130 + i))
		_blob(b, tip + Vector3(0, R * 0.4, 0), Vector3(R, R * 0.72, R), M("feuillage_bleu"), sd * 13 + i, 0.16, 20, 11, Vector3(0, 40.0 * i, 0))
	b.omni(Vector3(0, 11.0, 0), Color("#78e0ff"), 1.3, 15.0, false, "Lueur")
	_cyl(b, br * 1.15, 8.0, base)
	return b

# ================================================================== bois au sol

static func _tronc_couche(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var bark := M("ecorce_morte")
	var moss := M("mousse")
	var pts := [Vector3(-3.0, 0.44, 0.12), Vector3(-1.0, 0.47, -0.06), Vector3(1.5, 0.45, 0.08), Vector3(3.0, 0.4, -0.04)]
	_tube(b, pts, [0.5, 0.47, 0.46, 0.4], bark, {"per": 5, "segs": 14, "cap0": true})
	# bout brisé : racines dressées
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		var d := Vector3(0, sin(a), cos(a))
		_tube(b, [Vector3(-2.85, 0.44, 0.1), Vector3(-3.25, 0.44, 0.1) + d * 0.45 + Vector3(0, 0.1, 0), Vector3(-3.55, 0.3, 0.1) + d * 0.9 * Vector3(1, 1, 1)], [0.2, 0.13, 0.06], bark, {"per": 2, "segs": 7})
	# moignons de branches sur les flancs
	_tube(b, [Vector3(0.6, 0.5, 0.2), Vector3(0.9, 0.65, 0.65), Vector3(1.1, 0.7, 1.05)], [0.13, 0.1, 0.06], bark, {"per": 2, "segs": 7})
	_tube(b, [Vector3(-1.4, 0.4, -0.2), Vector3(-1.5, 0.55, -0.7), Vector3(-1.65, 0.62, -1.1)], [0.12, 0.09, 0.05], bark, {"per": 2, "segs": 7})
	for i in 4:
		var x := -2.2 + 1.5 * i + 0.4 * _h(i, 5)
		_blob(b, Vector3(x, 0.88, 0.02 * i), Vector3(0.5 + 0.2 * _h(i, 6), 0.1, 0.34), moss, 90 + i, 0.18, 10, 5)
	b.collide(Vector3(6.0, 0.9, 0.72), Vector3(0.0, 0.45, 0.02))
	return b

static func _souche(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var bark := M("ecorce_morte")
	b.add(StyleKit.lathe(PackedVector2Array([Vector2(0.95, 0.0), Vector2(0.78, 0.2), Vector2(0.66, 0.42), Vector2(0.64, 0.56), Vector2(0.52, 0.58)]), 18, bark, false, false))
	b.add(StyleKit.lathe(PackedVector2Array([Vector2(0.0, 0.575), Vector2(0.4, 0.57), Vector2(0.52, 0.58)]), 18, M("ecorce_foret"), false, true))
	for i in 5:
		var a := TAU * float(i) / 5.0 + 0.3
		var d := _dir(a)
		_tube(b, [d * 0.5 + Vector3(0, 0.45, 0), d * 0.9 + Vector3(0, 0.2, 0), d * 1.45 + Vector3(0, -0.06, 0)], [0.2, 0.14, 0.08], bark, {"per": 2, "segs": 8})
	_blob(b, Vector3(0.12, 0.6, -0.1), Vector3(0.3, 0.06, 0.26), M("mousse"), 5, 0.2, 10, 4)
	_cyl(b, 0.72, 0.58, Vector3.ZERO)
	return b

static func _racines_arche(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var bark := M("ecorce_foret")
	var moss := M("mousse")
	# deux grosses racines qui montent et se nouent au sommet, entrelacées de racines plus fines
	var left := [Vector3(-2.4, -0.2, 0.2), Vector3(-2.05, 0.9, 0.0), Vector3(-1.4, 1.95, -0.1), Vector3(-0.2, 2.55, 0.05), Vector3(0.9, 2.3, 0.0)]
	var right := [Vector3(2.5, -0.2, -0.2), Vector3(2.15, 0.8, 0.1), Vector3(1.5, 1.85, 0.05), Vector3(0.4, 2.55, -0.05), Vector3(-0.8, 2.3, 0.05)]
	_tube(b, left, [0.62, 0.46, 0.36, 0.3, 0.24], bark, {"per": 4, "segs": 11})
	_tube(b, right, [0.66, 0.48, 0.36, 0.3, 0.24], bark, {"per": 4, "segs": 11})
	for i in 3:
		var s := -1.0 if i % 2 == 0 else 1.0
		var x0 := 2.1 * s
		var pts := [Vector3(x0 + 0.5 * s, -0.15, 0.55 * (i - 1)), Vector3(x0 * 0.95, 0.7, -0.55 * (i - 1)), Vector3(x0 * 0.7, 1.7, 0.4 * (i - 1)), Vector3(x0 * 0.1, 2.35, -0.3 * (i - 1))]
		_tube(b, pts, [0.26, 0.2, 0.15, 0.1], bark, {"per": 3, "segs": 8})
	for sx in [-1.0, 1.0]:
		_blob(b, Vector3(2.35 * sx, 0.12, 0.0), Vector3(1.1, 0.35, 1.0), moss, 7 + int(sx), 0.2, 12, 6)
		_blob(b, Vector3(1.55 * sx, 2.05, 0.0), Vector3(0.5, 0.18, 0.55), moss, 9 + int(sx), 0.2, 10, 5)
	b.collide(Vector3(1.1, 2.0, 1.2), Vector3(-2.2, 1.0, 0.0))
	b.collide(Vector3(1.1, 2.0, 1.2), Vector3(2.3, 1.0, 0.0))
	b.collide(Vector3(3.6, 0.9, 1.0), Vector3(0.0, 2.25, 0.0))
	return b

static func _racines_basses(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var bark := M("ecorce_foret")
	var moss := M("mousse")
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.3 * _h(i, 3)
		var d := _dir(a)
		var side := Vector3(-d.z, 0, d.x)
		var len := 1.5 + 0.5 * _h(i, 4)
		var w := (_h(i, 5) - 0.5) * 1.2
		var pts := [d * 0.1 + Vector3(0, 0.3, 0), d * len * 0.35 + side * w * 0.3 + Vector3(0, 0.34, 0), d * len * 0.7 + side * w * 0.7 + Vector3(0, 0.15, 0), d * len + side * w + Vector3(0, -0.06, 0)]
		_tube(b, pts, [0.26, 0.2, 0.15, 0.1], bark, {"per": 3, "segs": 8})
		if i % 2 == 0:
			_blob(b, pts[1] + Vector3(0, 0.15, 0), Vector3(0.42, 0.1, 0.3), moss, 20 + i, 0.2, 10, 4, Vector3(0, a * 57.3, 0))
	_blob(b, Vector3(0, 0.25, 0), Vector3(0.5, 0.36, 0.5), bark, 3, 0.15, 12, 6)
	_blob(b, Vector3(0, 0.55, 0), Vector3(0.38, 0.1, 0.38), moss, 4, 0.2, 10, 4)
	return b

# ================================================================== pierre

## Rocher : 2 à 4 masses bosselées qui se chevauchent + calotte de mousse au sommet. variant 0 petit, 1 moyen haut, 2 grand.
static func _rocher(id: String, variant: int, s: float) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var rock := M("pierre_mousse")
	var moss := M("mousse")
	var sd := 200 + variant * 17
	var parts: Array = []
	match variant:
		0: parts = [[Vector3(0, 0.34, 0), Vector3(0.55, 0.42, 0.5)], [Vector3(0.38, 0.2, 0.12), Vector3(0.34, 0.26, 0.3)]]
		1: parts = [[Vector3(0, 0.62, 0), Vector3(0.7, 0.78, 0.58)], [Vector3(0.62, 0.3, 0.18), Vector3(0.48, 0.36, 0.42)], [Vector3(-0.5, 0.26, -0.2), Vector3(0.4, 0.3, 0.38)]]
		_: parts = [[Vector3(0, 1.05, 0), Vector3(1.15, 1.25, 1.0)], [Vector3(1.05, 0.55, 0.3), Vector3(0.8, 0.62, 0.7)], [Vector3(-0.95, 0.5, -0.35), Vector3(0.78, 0.6, 0.7)], [Vector3(0.1, 0.45, 0.95), Vector3(0.7, 0.5, 0.6)]]
	for i in parts.size():
		_blob(b, parts[i][0], parts[i][1], rock, sd + i * 3, 0.2, 18, 10, Vector3(0, 35.0 * i, 8.0 * i))
	var top: Vector3 = parts[0][0]
	var tr: Vector3 = parts[0][1]
	_blob(b, top + Vector3(0.04, tr.y * 0.78, -0.02), Vector3(tr.x * 0.72, tr.y * 0.3, tr.z * 0.72), moss, sd + 50, 0.18, 12, 6)
	if variant >= 1:
		var p1: Vector3 = parts[1][0]
		var r1: Vector3 = parts[1][1]
		_blob(b, p1 + Vector3(0, r1.y * 0.8, 0), Vector3(r1.x * 0.7, r1.y * 0.28, r1.z * 0.7), moss, sd + 51, 0.18, 10, 5)
	match variant:
		0: b.collide(Vector3(1.0, 0.65, 0.9), Vector3(0.1, 0.33, 0.05), Vector3(0, 20, 0))
		1: b.collide(Vector3(1.3, 1.2, 1.1), Vector3(0.0, 0.6, 0.0), Vector3(0, 25, 0))
		_:
			b.collide(Vector3(2.0, 2.2, 1.9), Vector3(0.0, 1.1, 0.0), Vector3(0, 20, 0))
			b.collide(Vector3(2.2, 1.0, 1.6), Vector3(0.2, 0.5, 0.2), Vector3(0, 55, 0))
	return b

static func _pierres_plates(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var rock := M("pierre_mousse")
	var moss := M("mousse")
	for i in 7:
		var t := float(i) / 6.0
		var c := Vector3(0.6 * sin(t * 3.2) + 0.15 * (_h(i, 1) - 0.5), 0.0, -3.0 + 6.0 * t)
		var r := Vector3(0.52 + 0.22 * _h(i, 2), 0.1, 0.46 + 0.2 * _h(i, 3))
		_blob(b, c + Vector3(0, 0.02, 0), r, rock, 300 + i, 0.14, 14, 5, Vector3(0, 360.0 * _h(i, 4), 3.0 * (_h(i, 5) - 0.5)))
		if i % 3 == 1:
			_blob(b, c + Vector3(0.1, 0.08, 0.05), Vector3(r.x * 0.5, 0.035, r.z * 0.5), moss, 330 + i, 0.2, 8, 3)
	return b

static func _cercle_pierres(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var rock := M("pierre_mousse")
	var moss := M("mousse")
	var n := 8
	for i in n:
		var a := TAU * float(i) / n + 0.2
		var c := _dir(a) * (3.8 + 0.25 * (_h(i, 1) - 0.5))
		var hgt := 1.0 + 0.55 * _h(i, 2)
		var rx := 0.5 + 0.12 * _h(i, 3)
		var lean := Vector3((_h(i, 4) - 0.5) * 10.0, 0.0, (_h(i, 5) - 0.5) * 10.0)
		_blob(b, c + Vector3(0, hgt * 0.8, 0), Vector3(rx, hgt, rx * 0.8), rock, 400 + i, 0.17, 12, 7, lean + Vector3(0, a * 57.3, 0))
		_blob(b, c + Vector3(0, hgt * 1.7, 0), Vector3(rx * 0.7, 0.12, rx * 0.6), moss, 430 + i, 0.2, 9, 4)
		_cyl(b, rx * 0.8, hgt * 1.7, c, "CollisionPierre%d" % (i + 1))
	return b

# ================================================================== plantes

static func _blade(b: ModuleBuilder, base: Vector3, heading: float, h: float, bend: float, w: float, mat: Material, segs := 4, spans := 3, per := 1) -> void:
	var d := _dir(heading)
	var pts: Array = [base, base + d * bend * 0.12 + Vector3(0, h * 0.4, 0), base + d * bend * 0.45 + Vector3(0, h * 0.8, 0), base + d * bend + Vector3(0, h * 0.92, 0)]
	if spans == 2:
		pts = [base, base + d * bend * 0.35 + Vector3(0, h * 0.62, 0), base + d * bend + Vector3(0, h * 0.9, 0)]
	var radii: Array = [w, w * 0.95, w * 0.62, w * 0.2] if spans == 3 else [w, w * 0.75, w * 0.2]
	_tube(b, pts, radii, mat, {"per": per, "segs": segs, "flat": 0.2, "wdir": Vector3(-d.z, 0, d.x), "capn": 2})

static func _herbes(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var mat := M("plante_sombre")
	for i in 11:
		var a := TAU * float(i) / 11.0 + 0.5 * _h(i, 1)
		var r0 := 0.04 + 0.06 * _h(i, 2)
		_blade(b, _dir(a) * r0, a + 0.3 * (_h(i, 3) - 0.5), 0.45 + 0.4 * _h(i, 4), 0.2 + 0.25 * _h(i, 5), 0.035, mat, 4, 3)
	return b

static func _fougere(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var mat := M("plante_sombre")
	for i in 7:
		var a := TAU * float(i) / 7.0 + 0.4 * _h(i, 1)
		var d := _dir(a)
		var h := 0.5 + 0.28 * _h(i, 2)
		var reach := 0.55 + 0.35 * _h(i, 3)
		var pts := [Vector3(0, 0, 0) + d * 0.04, d * reach * 0.25 + Vector3(0, h * 0.75, 0), d * reach * 0.6 + Vector3(0, h, 0), d * reach + Vector3(0, h * 0.55, 0)]
		_tube(b, pts, [0.05, 0.1, 0.095, 0.03], mat, {"per": 2, "segs": 4, "flat": 0.12, "wdir": Vector3(-d.z, 0, d.x), "capn": 2})
	return b

static func _roseaux(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var mat := M("plante_sombre")
	for i in 9:
		var a := TAU * float(i) / 9.0 + _h(i, 1)
		var r0 := 0.05 + 0.22 * _h(i, 2)
		var h := 1.7 + 0.8 * _h(i, 3)
		var d := _dir(a)
		var base := _dir(a + 1.0) * r0
		var bend := 0.1 + 0.35 * _h(i, 4)
		var pts := [base, base + d * bend * 0.3 + Vector3(0, h * 0.5, 0), base + d * bend + Vector3(0, h, 0)]
		_tube(b, pts, [0.016, 0.012, 0.007], mat, {"per": 1, "segs": 4, "capn": 2})
		if i % 2 == 0:
			var tip: Vector3 = pts[2]
			_blob(b, tip + Vector3(0, 0.05, 0), Vector3(0.028, 0.14, 0.028), M("ecorce_morte"), 500 + i, 0.1, 6, 3)
	return b

static func _champignon(b: ModuleBuilder, pos: Vector3, r: float, h: float, tilt: float, heading: float) -> void:
	var d := _dir(heading) * tilt
	b.add(StyleKit.lathe(PackedVector2Array([Vector2(r * 0.34, 0.0), Vector2(r * 0.26, h * 0.5), Vector2(r * 0.22, h)]), 6, M("fleur_blanche"), true, false), Transform3D(Basis(), pos))
	var cap := PackedVector2Array([Vector2(r * 0.26, h * 0.92), Vector2(r * 0.9, h * 0.98), Vector2(r * 1.0, h * 1.12), Vector2(r * 0.7, h * 1.38), Vector2(r * 0.0, h * 1.5)])
	b.add(StyleKit.lathe(cap, 8, M("champi_lueur"), true, false), Transform3D(Basis(), pos + d * h))

static func _champignons(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var spec := [[Vector3(0, 0, 0), 0.17, 0.3, 0.1, 0.5], [Vector3(0.24, 0, 0.1), 0.12, 0.2, 0.2, 1.8], [Vector3(-0.2, 0, 0.16), 0.1, 0.17, 0.15, 3.5], [Vector3(0.06, 0, -0.26), 0.13, 0.22, 0.2, 4.4], [Vector3(-0.22, 0, -0.16), 0.08, 0.12, 0.1, 5.2]]
	for s in spec:
		_champignon(b, s[0], s[1], s[2], s[3], s[4])
	return b

static func _nenuphars(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var pad := M("nenuphar_lueur")
	var specs := [[Vector3(0, 0, 0), 0.46], [Vector3(0.7, 0, 0.35), 0.34], [Vector3(-0.5, 0, 0.6), 0.28]]
	for s in specs:
		var r: float = s[1]
		var prof := PackedVector2Array([Vector2(0.0, 0.012), Vector2(r * 0.6, 0.014), Vector2(r * 0.95, 0.03), Vector2(r, 0.055), Vector2(r * 0.92, 0.05)])
		b.add(StyleKit.lathe(prof, 12, pad, false, false), Transform3D(Basis(), s[0]))
		b.add(StyleKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r * 0.92, 0.004)]), 12, pad, false, true), Transform3D(Basis(), s[0]))
	# une fleur lumineuse sur la grande feuille
	for i in 5:
		var a := TAU * float(i) / 5.0
		_blob(b, _dir(a) * 0.06 + Vector3(0, 0.1, 0), Vector3(0.035, 0.09, 0.07), M("champi_lueur"), 600 + i, 0.08, 6, 3, Vector3(0, -a * 57.3, 35.0))
	return b

static func _fleurs_blanches(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var stem := M("plante_sombre")
	var fl := M("fleur_blanche")
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.5
		var base := _dir(a) * (0.08 + 0.1 * _h(i, 1))
		var h := 0.42 + 0.24 * _h(i, 2)
		var d := _dir(a + 0.8)
		var pts := [base, base + d * 0.04 + Vector3(0, h * 0.5, 0), base + d * 0.09 + Vector3(0, h, 0)]
		_tube(b, pts, [0.012, 0.01, 0.008], stem, {"per": 1, "segs": 4, "capn": 2})
		var tip: Vector3 = pts[2]
		_blob(b, tip + Vector3(0, 0.02, 0), Vector3(0.075, 0.035, 0.075), fl, 700 + i, 0.18, 8, 3)
		_blob(b, tip + Vector3(0, 0.05, 0), Vector3(0.025, 0.02, 0.025), M("chaud_fille"), 710 + i, 0.05, 5, 2)
	for i in 3:
		var a := 1.3 + TAU * float(i) / 3.0
		_blade(b, _dir(a) * 0.05, a, 0.25, 0.14, 0.03, stem, 4, 2)
	return b

static func _arbuste_a(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		var d := _dir(a)
		_tube(b, [d * 0.05, d * 0.2 + Vector3(0, 0.35, 0), d * 0.4 + Vector3(0, 0.6, 0)], [0.04, 0.03, 0.02], M("ecorce_foret"), {"per": 2, "segs": 6})
	var blobs := [[Vector3(0, 0.55, 0), Vector3(0.55, 0.42, 0.52)], [Vector3(0.45, 0.4, 0.1), Vector3(0.4, 0.32, 0.38)], [Vector3(-0.35, 0.38, 0.28), Vector3(0.38, 0.3, 0.36)], [Vector3(-0.05, 0.4, -0.42), Vector3(0.42, 0.34, 0.38)], [Vector3(0.1, 0.9, 0.05), Vector3(0.3, 0.22, 0.3)]]
	for i in blobs.size():
		_blob(b, blobs[i][0], blobs[i][1], M("feuillage_sombre" if i % 2 == 0 else "feuillage_bleu"), 800 + i, 0.18, 14, 8, Vector3(0, 50.0 * i, 0))
	return b

static func _arbuste_b(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.3 * _h(i, 1)
		var d := _dir(a)
		var h := 0.9 + 0.5 * _h(i, 2)
		var reach := 0.5 + 0.35 * _h(i, 3)
		var pts := [d * 0.05, d * reach * 0.25 + Vector3(0, h * 0.7, 0), d * reach * 0.7 + Vector3(0, h, 0), d * reach + Vector3(0, h * 0.75, 0)]
		_tube(b, pts, [0.04, 0.03, 0.022, 0.014], M("ecorce_foret"), {"per": 2, "segs": 5})
		var tip: Vector3 = pts[3]
		_blob(b, tip + Vector3(0, 0.05, 0), Vector3(0.3, 0.26, 0.3), M("feuillage_bleu" if i % 2 == 0 else "feuillage_sombre"), 850 + i, 0.2, 10, 6)
		if i % 2 == 1:
			_blob(b, tip + d * 0.1 + Vector3(0, -0.28, 0), Vector3(0.05, 0.05, 0.05), M("champi_lueur"), 860 + i, 0.05, 6, 3)
	return b

# ================================================================== ruines

static func _stone(b: ModuleBuilder, size: Vector3, pos: Vector3, rot_deg := Vector3.ZERO, mat := "pierre_ruine") -> void:
	b.add(StyleKit.rounded_box(size, 0.07, M(mat), 1), ModuleBuilder.at(pos, rot_deg))

static func _ruine_arche(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var moss := M("mousse")
	var ys := 2.1
	var ri := 1.4
	# pilier gauche entier, droit brisé
	for k in 5:
		_stone(b, Vector3(0.95, 0.46, 1.0), Vector3(-ri - 0.45 + 0.04 * sin(k * 2.0), 0.23 + 0.45 * k, 0.03 * k), Vector3(0, 3.0 * (_h(k, 1) - 0.5), 0))
	for k in 3:
		_stone(b, Vector3(0.95, 0.46, 1.0), Vector3(ri + 0.45 - 0.05 * sin(k * 1.5), 0.23 + 0.45 * k, -0.03 * k), Vector3(0, 3.0 * (_h(k, 2) - 0.5), 0))
	# claveaux de l'arc (angle 180° → 60°)
	for i in 6:
		var th := PI - PI * 0.85 * float(i) / 5.0 * 0.78
		var rc := ri + 0.32
		var pos := Vector3(cos(th) * rc, ys + 0.2 + sin(th) * rc, 0.0)
		_stone(b, Vector3(0.64, 0.64, 1.0), pos, Vector3(0, 0, th * 57.3 - 90.0))
	# gravats
	_stone(b, Vector3(0.8, 0.45, 0.8), Vector3(ri + 1.3, 0.22, 0.6), Vector3(0, 25, 4))
	_stone(b, Vector3(0.7, 0.42, 0.7), Vector3(ri + 0.55, 0.2, 1.05), Vector3(0, -15, -3))
	_stone(b, Vector3(0.66, 0.6, 0.9), Vector3(1.3, 0.28, -0.4), Vector3(8, 40, 70))
	_blob(b, Vector3(-ri - 0.45, 2.55, 0.0), Vector3(0.6, 0.2, 0.62), moss, 910, 0.2, 10, 5)
	_blob(b, Vector3(ri + 0.4, 1.45, 0.0), Vector3(0.55, 0.16, 0.55), moss, 911, 0.2, 10, 5)
	_blob(b, Vector3(0.0, 0.1, 0.8), Vector3(1.4, 0.2, 0.6), moss, 912, 0.25, 12, 5)
	_tube(b, [Vector3(-ri - 0.1, 3.3, 0.55), Vector3(-ri - 0.35, 2.4, 0.56), Vector3(-ri - 0.2, 1.2, 0.58), Vector3(-ri - 0.5, 0.2, 0.7)], [0.03, 0.035, 0.03, 0.025], M("plante_sombre"), {"per": 3, "segs": 5})
	b.collide(Vector3(1.0, 2.3, 1.05), Vector3(-ri - 0.45, 1.15, 0.0))
	b.collide(Vector3(1.0, 1.4, 1.05), Vector3(ri + 0.45, 0.7, 0.0))
	b.collide(Vector3(2.4, 1.2, 1.0), Vector3(-0.6, 3.1, 0.0))
	return b

static func _ruine_colonne(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var mat := M("pierre_ruine")
	_stone(b, Vector3(1.15, 0.28, 1.15), Vector3(0, 0.14, 0))
	var prof := PackedVector2Array([Vector2(0.52, 0.28), Vector2(0.46, 0.4), Vector2(0.42, 0.9), Vector2(0.4, 1.8), Vector2(0.41, 2.5)])
	b.add(StyleKit.lathe(prof, 16, mat, false, false))
	b.add(StyleKit.torus(0.46, 0.05, mat, 16, 6), ModuleBuilder.at(Vector3(0, 0.42, 0)))
	_blob(b, Vector3(0.02, 2.5, 0.0), Vector3(0.44, 0.2, 0.42), mat, 930, 0.28, 14, 6)
	# tambour tombé
	b.add(StyleKit.lathe(PackedVector2Array([Vector2(0.4, -0.45), Vector2(0.4, 0.45)]), 14, mat, true, true), ModuleBuilder.at(Vector3(1.0, 0.4, 0.7), Vector3(0, 30, 90)))
	_blob(b, Vector3(0.0, 2.7, 0.0), Vector3(0.3, 0.07, 0.28), M("mousse"), 931, 0.2, 8, 4)
	_blob(b, Vector3(1.0, 0.82, 0.7), Vector3(0.3, 0.08, 0.34), M("mousse"), 932, 0.2, 8, 4)
	_cyl(b, 0.5, 2.6, Vector3.ZERO)
	b.collide(Vector3(0.9, 0.8, 1.0), Vector3(1.0, 0.4, 0.7), Vector3(0, 30, 0))
	return b

static func _ruine_mur(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var courses := [[7, 0.0], [6, 0.5], [4, 1.0], [2, 1.5]]
	for c in courses.size():
		var n: int = courses[c][0]
		var y := 0.21 + 0.42 * c
		for k in n:
			var w := 0.6 + 0.08 * _h(k + c * 7, 1)
			var x := -2.0 + 0.62 * k + (0.31 if c % 2 == 1 else 0.0) + 0.0
			_stone(b, Vector3(w, 0.4, 0.72 + 0.06 * _h(k, c)), Vector3(x - (0.0 if c < 2 else 0.4), y, 0.03 * _h(k, c + 4)), Vector3(0, 3.0 * (_h(k, 9 + c) - 0.5), 0))
	_stone(b, Vector3(0.7, 0.4, 0.7), Vector3(2.5, 0.2, 0.7), Vector3(0, 35, 3))
	_stone(b, Vector3(0.6, 0.38, 0.62), Vector3(2.0, 0.19, 1.1), Vector3(0, -20, -2))
	_blob(b, Vector3(-1.2, 1.9, 0.0), Vector3(0.8, 0.18, 0.5), M("mousse"), 940, 0.22, 10, 5)
	_blob(b, Vector3(0.8, 1.1, 0.0), Vector3(0.7, 0.14, 0.45), M("mousse"), 941, 0.22, 10, 5)
	_tube(b, [Vector3(1.2, 1.2, 0.4), Vector3(1.1, 0.7, 0.42), Vector3(1.3, 0.1, 0.5)], [0.03, 0.035, 0.03], M("plante_sombre"), {"per": 3, "segs": 5})
	b.collide(Vector3(4.2, 1.7, 0.8), Vector3(-0.4, 0.85, 0.0))
	b.collide(Vector3(1.6, 0.7, 1.6), Vector3(2.3, 0.35, 0.8))
	return b

## Porte de lune : arche d'environ 4 m dans un pan de mur, deux vantaux pivotants, croissant sur la clé de voûte.
static func _porte_lune(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var stone := M("pierre_ruine")
	var ow := 2.4
	var oh := 3.3
	var band := 0.65
	var frame := StyleKit.extrude(StyleKit.arch_frame_outline(ow, oh, band, 14), 1.0, stone, 0.08)
	b.add(frame)
	# pans de mur de part et d'autre (blocs superposés, plus bas à gauche)
	for side in [-1.0, 1.0]:
		var rows := 4 if side < 0.0 else 3
		for r in rows:
			var w := 1.5 - 0.1 * r
			_stone(b, Vector3(w, 0.52, 0.9), Vector3(side * (ow * 0.5 + band + w * 0.5 - 0.02), 0.26 + 0.52 * r, 0.02 * r), Vector3(0, 2.0 * (_h(r, 3) - 0.5), 0))
	# clé de voûte et croissant (inlay « lune »)
	_stone(b, Vector3(0.7, 0.55, 1.12), Vector3(0, oh + band * 0.5 - 0.05, 0.0))
	var cres := StyleKit.extrude(StyleKit.crescent_outline(0.2, 0.55), 0.05, M("lune"), 0.01)
	b.add(cres, ModuleBuilder.at(Vector3(0.0, oh + band * 0.5 - 0.05, 0.57), Vector3(0, 0, 90)))
	b.add(StyleKit.torus(0.3, 0.025, stone, 20, 5), ModuleBuilder.at(Vector3(0.0, oh + band * 0.5 - 0.05, 0.56), Vector3(90, 0, 0)))
	_blob(b, Vector3(-ow * 0.5 - band - 0.7, 2.25, 0.0), Vector3(0.9, 0.2, 0.6), M("mousse"), 950, 0.2, 10, 5)
	_blob(b, Vector3(ow * 0.5 + band + 0.6, 1.65, 0.0), Vector3(0.8, 0.18, 0.55), M("mousse"), 951, 0.2, 10, 5)
	_blob(b, Vector3(0.0, 0.08, 0.7), Vector3(1.9, 0.15, 0.6), M("mousse"), 952, 0.25, 12, 5)
	_tube(b, [Vector3(ow * 0.5 + 0.2, 4.0, 0.56), Vector3(ow * 0.5 + 0.35, 3.0, 0.6), Vector3(ow * 0.5 + 0.25, 1.8, 0.58), Vector3(ow * 0.5 + 0.5, 0.2, 0.7)], [0.035, 0.04, 0.035, 0.03], M("plante_sombre"), {"per": 3, "segs": 5})
	# collisions de l'encadrement et des murs
	b.collide(Vector3(band, oh, 1.0), Vector3(-(ow * 0.5 + band * 0.5), oh * 0.5, 0.0))
	b.collide(Vector3(band, oh, 1.0), Vector3(ow * 0.5 + band * 0.5, oh * 0.5, 0.0))
	b.collide(Vector3(ow + 2.0 * band, 0.75, 1.0), Vector3(0.0, oh + 0.3, 0.0))
	b.collide(Vector3(1.4, 2.1, 0.9), Vector3(-(ow * 0.5 + band + 0.7), 1.05, 0.0))
	b.collide(Vector3(1.4, 1.6, 0.9), Vector3(ow * 0.5 + band + 0.7, 0.8, 0.0))
	# vantaux : pivots aux charnières, collision chacun
	var r := ow * 0.5
	var spring := oh - r
	for side in [-1, 1]:
		# polygone dans le repère de la charnière : x = distance à la charnière (G : vers +x ; D : miroir, vers −x)
		var sx := 1.0 if side < 0 else -1.0
		var door := PackedVector2Array([Vector2(0.015 * sx, 0.0), Vector2((r - 0.015) * sx, 0.0)])
		for i in 10:
			var hh := (r - 0.015) * (1.0 - float(i) / 9.0)
			var u := r - hh
			door.append(Vector2(hh * sx, spring + sqrt(maxf(r * r - u * u, 0.0)) - 0.03))
		var m_door := StyleKit.extrude(door, 0.18, M("ecorce_foret"), 0.03)
		var nm := "VantailG" if side < 0 else "VantailD"
		var pivot := Node3D.new()
		pivot.name = nm
		pivot.position = Vector3(side * r, 0.0, 0.0)
		var parts: Array = [[m_door, Transform3D.IDENTITY]]
		for k in 3:
			parts.append([StyleKit.rounded_box(Vector3(r - 0.1, 0.1, 0.24), 0.03, M("pierre_mousse"), 1), ModuleBuilder.at(Vector3(sx * (r * 0.5), 0.7 + 0.9 * k, 0.0))])
		pivot.add_child(_mesh_node("Maillage" + nm, parts))
		pivot.add_child(_box_body("Collision", Vector3(r - 0.04, oh - 0.2, 0.22), Vector3(sx * r * 0.5, (oh - 0.2) * 0.5, 0.0)))
		b.extras.append(pivot)
	return b

static func _piedestal(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var stone := M("pierre_ruine")
	_stone(b, Vector3(1.2, 0.2, 1.2), Vector3(0, 0.1, 0))
	_stone(b, Vector3(0.95, 0.2, 0.95), Vector3(0, 0.3, 0))
	b.add(StyleKit.lathe(PackedVector2Array([Vector2(0.34, 0.4), Vector2(0.28, 0.6), Vector2(0.25, 0.95), Vector2(0.3, 1.12), Vector2(0.42, 1.18), Vector2(0.42, 1.24)]), 14, stone, false, true))
	b.add(StyleKit.torus(0.3, 0.035, stone, 14, 6), ModuleBuilder.at(Vector3(0, 1.1, 0)))
	var cres := StyleKit.extrude(StyleKit.crescent_outline(0.13, 0.55), 0.03, M("lune"), 0.008)
	b.add(cres, ModuleBuilder.at(Vector3(0, 0.74, 0.27), Vector3(0, 0, 90)))
	_blob(b, Vector3(0.45, 0.2, 0.4), Vector3(0.5, 0.12, 0.4), M("mousse"), 960, 0.25, 10, 4)
	_blob(b, Vector3(-0.3, 0.42, -0.1), Vector3(0.3, 0.07, 0.3), M("mousse"), 961, 0.25, 8, 4)
	var pierre := MeshInstance3D.new()
	pierre.name = "Pierre"
	pierre.mesh = _blob_mesh(Vector3.ZERO, Vector3(0.15, 0.13, 0.15), M("lune"), 962, 0.04, 14, 8)
	pierre.position = Vector3(0, 1.4, 0)
	b.extras.append(pierre)
	b.collide(Vector3(1.0, 1.25, 1.0), Vector3(0, 0.62, 0))
	return b

# ================================================================== mise en scène

static func _cadre(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var cr := "creme_cadre"
	var W := 1.1
	var H := 2.2
	var t := 0.16
	var d := 0.24
	b.box(Vector3(t, H, d), 0.04, cr, Vector3(-W * 0.5 - t * 0.5, H * 0.5, 0))
	b.box(Vector3(t, H, d), 0.04, cr, Vector3(W * 0.5 + t * 0.5, H * 0.5, 0))
	b.box(Vector3(W + 2.0 * t + 0.1, 0.22, d + 0.06), 0.05, cr, Vector3(0, H + 0.05, 0))
	b.box(Vector3(W + 2.0 * t + 0.4, 0.07, d + 0.3), 0.03, cr, Vector3(0, 0.035, 0))
	# liserés dorés intérieurs et corniche
	b.box(Vector3(0.035, H - 0.05, d + 0.02), 0.012, "or", Vector3(-W * 0.5 + 0.02, H * 0.5 + 0.02, 0))
	b.box(Vector3(0.035, H - 0.05, d + 0.02), 0.012, "or", Vector3(W * 0.5 - 0.02, H * 0.5 + 0.02, 0))
	b.box(Vector3(W, 0.035, d + 0.02), 0.012, "or", Vector3(0, H - 0.01, 0))
	b.box(Vector3(W + 2.0 * t + 0.2, 0.035, d + 0.1), 0.012, "or", Vector3(0, H + 0.17, 0))
	b.box(Vector3(0.3, 0.12, 0.03), 0.015, "or", Vector3(0, H + 0.05, d * 0.5 + 0.045))
	# racines qui envahissent le cadre
	var bark := M("ecorce_foret")
	_tube(b, [Vector3(-W * 0.5 - 0.5, -0.05, 0.2), Vector3(-W * 0.5 - 0.1, 0.5, 0.2), Vector3(-W * 0.5 - 0.22, 1.2, 0.15), Vector3(-W * 0.5 + 0.12, 1.9, 0.14), Vector3(0.2, H + 0.2, 0.12)], [0.09, 0.07, 0.06, 0.045, 0.03], bark, {"per": 3, "segs": 7})
	_tube(b, [Vector3(-W * 0.5 - 0.35, -0.05, -0.2), Vector3(-W * 0.5 - 0.25, 0.6, -0.15), Vector3(-W * 0.5 + 0.1, 1.4, -0.14), Vector3(-W * 0.5 - 0.02, 2.0, -0.1)], [0.07, 0.055, 0.04, 0.025], bark, {"per": 3, "segs": 7})
	_tube(b, [Vector3(W * 0.5 + 0.55, -0.05, 0.25), Vector3(W * 0.5 + 0.3, 0.3, 0.22), Vector3(W * 0.5 + 0.2, 0.8, 0.2)], [0.08, 0.06, 0.035], bark, {"per": 3, "segs": 7})
	_tube(b, [Vector3(0.1, H + 0.2, -0.1), Vector3(0.5, H + 0.35, -0.05), Vector3(0.9, H + 0.1, 0.1), Vector3(W * 0.5 + 0.2, 1.6, 0.16)], [0.05, 0.045, 0.04, 0.025], bark, {"per": 3, "segs": 7})
	var moss := M("mousse")
	_blob(b, Vector3(-0.15, H + 0.24, 0.0), Vector3(0.5, 0.1, 0.22), moss, 970, 0.2, 10, 5)
	_blob(b, Vector3(-W * 0.5 - 0.55, 0.1, 0.1), Vector3(0.4, 0.14, 0.4), moss, 971, 0.22, 10, 5)
	_blob(b, Vector3(W * 0.5 + 0.45, 0.1, 0.0), Vector3(0.4, 0.12, 0.35), moss, 972, 0.22, 10, 5)
	_blob(b, Vector3(0.0, 0.1, 0.0), Vector3(0.4, 0.08, 0.2), moss, 973, 0.22, 8, 4)
	b.collide(Vector3(t, H, d), Vector3(-W * 0.5 - t * 0.5, H * 0.5, 0))
	b.collide(Vector3(t, H, d), Vector3(W * 0.5 + t * 0.5, H * 0.5, 0))
	b.collide(Vector3(W + 2.0 * t, 0.3, d), Vector3(0, H + 0.1, 0))
	return b

static func _fleur_lanterne(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var stem := M("plante_sombre")
	_blob(b, Vector3(0, 0.12, 0), Vector3(0.28, 0.16, 0.28), M("mousse"), 980, 0.2, 10, 5)
	_tube(b, [Vector3(0, 0, 0), Vector3(0.1, 0.5, 0.05), Vector3(-0.08, 1.0, 0.0), Vector3(0.0, 1.35, 0.02)], [0.07, 0.05, 0.042, 0.035], stem, {"per": 3, "segs": 8})
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.7
		_blade(b, _dir(a) * 0.05, a, 0.7 + 0.2 * _h(i, 1), 0.5, 0.11, stem, 5, 3, 2)
	# feuilles-bractées sous la corolle
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.2
		_blade(b, Vector3(0, 1.0, 0) + _dir(a) * 0.03, a, 0.3, 0.3, 0.06, stem, 4, 2)
	var parts: Array = []
	for i in 6:
		var a := TAU * float(i) / 6.0
		parts.append([_blob_mesh(Vector3.ZERO, Vector3(0.07, 0.24, 0.16), M("nenuphar_lueur"), 990 + i, 0.08, 8, 5), Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.BACK, deg_to_rad(-16.0)), Vector3(0, 1.62, 0) + _dir(a) * 0.15)])
	parts.append([_blob_mesh(Vector3(0, 1.55, 0), Vector3(0.11, 0.12, 0.11), M("fleur_blanche"), 999, 0.05, 8, 5), Transform3D.IDENTITY])
	var cor := _mesh_node("Corolle", parts)
	b.extras.append(cor)
	var l := b.omni(Vector3(0, 1.6, 0), Color("#6fe8ff"), 1.6, 7.0, false, "Lumiere")
	l.visible = false
	return b

static func _pont(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var bark := M("ecorce_foret")
	var moss := M("mousse")
	var py := 0.22
	var n := 4
	for k in n:
		var z0 := 3.5 - 1.75 * k
		var parts: Array = []
		var pivot := Node3D.new()
		pivot.name = "Racine_%d" % (k + 1)
		pivot.position = Vector3(0, py, z0)
		pivot.set_meta("pose_couchee", Vector3(-90.0, 0.0, 0.0))
		for s in 3:
			var x := (s - 1) * 0.52
			var r := 0.4 if s == 1 else 0.32
			var pts := [Vector3(x, 0.0, 0.15), Vector3(x + 0.04 * (k % 2 * 2 - 1), 0.05, -0.65), Vector3(x - 0.03, 0.08, -1.3), Vector3(x, 0.0, -2.0)]
			parts.append([_tube_mesh(pts, [r * 0.95, r, r * 0.96, r * 0.9], bark, {"per": 2, "segs": 9, "cap0": true, "capn": 2}), Transform3D.IDENTITY])
		for s in 2:
			var sg := -1.0 if s == 0 else 1.0
			var pts := [Vector3(-0.5 * sg, 0.28, 0.1), Vector3(0.45 * sg, 0.4, -0.6), Vector3(-0.4 * sg, 0.4, -1.3), Vector3(0.1 * sg, 0.26, -1.9)]
			parts.append([_tube_mesh(pts, [0.1, 0.11, 0.1, 0.08], bark, {"per": 3, "segs": 6}), Transform3D.IDENTITY])
		parts.append([_blob_mesh(Vector3(0.1, 0.46, -0.9), Vector3(0.45, 0.08, 0.5), moss, 1000 + k, 0.2, 10, 4), Transform3D.IDENTITY])
		pivot.add_child(_mesh_node("MaillageRacine%d" % (k + 1), parts))
		b.extras.append(pivot)
	# talus fixes aux deux rives
	_blob(b, Vector3(0.0, 0.05, 4.1), Vector3(1.3, 0.35, 0.9), moss, 1010, 0.2, 12, 6)
	_blob(b, Vector3(0.0, 0.05, -4.1), Vector3(1.3, 0.35, 0.9), moss, 1011, 0.2, 12, 6)
	_tube(b, [Vector3(-0.7, 0.0, 4.4), Vector3(-0.8, 0.4, 3.7), Vector3(-0.4, 0.55, 3.3)], [0.2, 0.17, 0.12], bark, {"per": 2, "segs": 8})
	_tube(b, [Vector3(0.7, 0.0, -4.4), Vector3(0.8, 0.4, -3.7), Vector3(0.4, 0.55, -3.3)], [0.2, 0.17, 0.12], bark, {"per": 2, "segs": 8})
	b.extras.append(_box_body("PontCollision", Vector3(1.7, 0.2, 7.0), Vector3(0, 0.35, 0)))
	return b

static func _silhouette(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	b.cast_shadows = false
	var m := M("ombre_foret")
	# longue robe qui se délite vers le sol, buste étroit, cou long, tête allongée, bras pendants trop longs
	_tube(b, [Vector3(0, 0.0, 0), Vector3(0, 0.7, 0.02), Vector3(0.0, 1.5, 0.0), Vector3(0, 2.05, 0.04)], [0.34, 0.26, 0.2, 0.12], m, {"per": 3, "segs": 12, "cap0": true})
	_tube(b, [Vector3(0, 1.95, 0.04), Vector3(0, 2.3, 0.08), Vector3(0, 2.48, 0.1)], [0.09, 0.06, 0.06], m, {"per": 2, "segs": 10, "cap1": false})
	_blob(b, Vector3(0, 2.62, 0.12), Vector3(0.14, 0.2, 0.15), m, 1020, 0.05, 12, 8)
	for s in [-1.0, 1.0]:
		_tube(b, [Vector3(0.14 * s, 1.95, 0.0), Vector3(0.3 * s, 1.4, 0.04), Vector3(0.34 * s, 0.7, 0.1), Vector3(0.32 * s, 0.1, 0.1)], [0.06, 0.05, 0.04, 0.025], m, {"per": 3, "segs": 8})
	# deux minuscules points pâles
	for s in [-1.0, 1.0]:
		_blob(b, Vector3(0.05 * s, 2.64, 0.265), Vector3(0.011, 0.011, 0.011), M("fleur_blanche"), 1030, 0.0, 6, 4)
	return b

# ------------------------------------------------------------------ la jeune fille (provisoire)

static func _fille_commun(parts: Array, head: Vector3, head_tilt: float) -> void:
	var skin := M("lin_creme")
	var hair := M("bois_sombre")
	var scarf := M("chaud_fille")
	# tête (grosse, douce, sans traits), cheveux, frange, deux nattes
	parts.append([_blob_mesh(head, Vector3(0.118, 0.128, 0.118), skin, 1040, 0.02, 16, 10, Vector3(head_tilt, 0, 0)), Transform3D.IDENTITY])
	var hb := Basis.from_euler(Vector3(deg_to_rad(head_tilt), 0, 0))
	parts.append([_blob_mesh(head + hb * Vector3(0, 0.02, -0.03), Vector3(0.138, 0.14, 0.135), hair, 1041, 0.04, 16, 10, Vector3(head_tilt, 0, 0)), Transform3D.IDENTITY])
	parts.append([_blob_mesh(head + hb * Vector3(0, 0.085, 0.07), Vector3(0.115, 0.05, 0.065), hair, 1042, 0.06, 12, 6, Vector3(head_tilt - 15.0, 0, 0)), Transform3D.IDENTITY])
	for s in [-1.0, 1.0]:
		var p0 := head + hb * Vector3(0.1 * s, -0.04, -0.04)
		parts.append([_tube_mesh([p0, p0 + Vector3(0.05 * s, -0.16, -0.05), p0 + Vector3(0.06 * s, -0.34, -0.07)], [0.03, 0.028, 0.02], hair, {"per": 2, "segs": 6}), Transform3D.IDENTITY])
	# écharpe chaude : l'accent
	var neck := head + hb * Vector3(0, -0.13, 0.0)
	parts.append([StyleKit.torus(0.095, 0.034, scarf, 14, 6), Transform3D(Basis(), neck)])
	parts.append([_tube_mesh([neck + Vector3(0.06, -0.02, 0.08), neck + Vector3(0.1, -0.14, 0.1), neck + Vector3(0.1, -0.3, 0.07)], [0.03, 0.032, 0.026], scarf, {"per": 2, "segs": 6, "flat": 0.5}), Transform3D.IDENTITY])

static func _fille(id: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var dress := M("lin_lavande")
	var cape := M("feuillage_sombre")
	var skin := M("lin_creme")
	var hair := M("bois_sombre")
	# ---------------- debout (≈ 1,35 m)
	var p: Array = []
	p.append([StyleKit.lathe(PackedVector2Array([Vector2(0.27, 0.38), Vector2(0.25, 0.5), Vector2(0.19, 0.72), Vector2(0.12, 0.92), Vector2(0.095, 1.0), Vector2(0.115, 1.08), Vector2(0.07, 1.14)]), 16, dress, false, true), Transform3D.IDENTITY])
	for s in [-1.0, 1.0]:
		p.append([_tube_mesh([Vector3(0.05 * s, 0.42, 0.0), Vector3(0.055 * s, 0.2, 0.02), Vector3(0.055 * s, 0.05, 0.02)], [0.035, 0.03, 0.028], skin, {"per": 2, "segs": 6}), Transform3D.IDENTITY])
		p.append([_blob_mesh(Vector3(0.055 * s, 0.03, 0.05), Vector3(0.045, 0.035, 0.07), hair, 1050, 0.05, 8, 5), Transform3D.IDENTITY])
		p.append([_tube_mesh([Vector3(0.1 * s, 1.07, 0.0), Vector3(0.15 * s, 0.88, 0.04), Vector3(0.15 * s, 0.7, 0.1)], [0.04, 0.036, 0.03], dress, {"per": 2, "segs": 7}), Transform3D.IDENTITY])
		p.append([_blob_mesh(Vector3(0.15 * s, 0.67, 0.12), Vector3(0.03, 0.035, 0.03), skin, 1051, 0.05, 8, 5), Transform3D.IDENTITY])
	# cape sur le dos et capuche
	p.append([_blob_mesh(Vector3(0, 0.78, -0.07), Vector3(0.2, 0.42, 0.11), cape, 1052, 0.05, 14, 9, Vector3(-6, 0, 0)), Transform3D.IDENTITY])
	p.append([_blob_mesh(Vector3(0, 1.12, -0.07), Vector3(0.18, 0.1, 0.12), cape, 1053, 0.05, 12, 6), Transform3D.IDENTITY])
	_fille_commun(p, Vector3(0, 1.2, 0.0), 0.0)
	var deb := _mesh_node("MaillageDebout", p)
	var nd := Node3D.new()
	nd.name = "Debout"
	nd.add_child(deb)
	b.extras.append(nd)
	# ---------------- assise, recroquevillée : genoux remontés, bras autour, tête penchée
	var q: Array = []
	q.append([_blob_mesh(Vector3(0, 0.17, 0.0), Vector3(0.27, 0.17, 0.27), dress, 1060, 0.05, 14, 8), Transform3D.IDENTITY])
	q.append([_tube_mesh([Vector3(0, 0.2, -0.06), Vector3(0, 0.38, -0.04), Vector3(0, 0.52, 0.0)], [0.14, 0.12, 0.09], dress, {"per": 3, "segs": 10, "cap0": true}), Transform3D.IDENTITY])
	for s in [-1.0, 1.0]:
		q.append([_tube_mesh([Vector3(0.09 * s, 0.17, 0.0), Vector3(0.1 * s, 0.34, 0.2), Vector3(0.1 * s, 0.34, 0.3)], [0.07, 0.065, 0.06], dress, {"per": 3, "segs": 8}), Transform3D.IDENTITY])
		q.append([_blob_mesh(Vector3(0.07 * s, 0.03, 0.31), Vector3(0.045, 0.035, 0.07), hair, 1061, 0.05, 8, 5), Transform3D.IDENTITY])
		q.append([_tube_mesh([Vector3(0.1 * s, 0.52, 0.0), Vector3(0.18 * s, 0.46, 0.2), Vector3(0.08 * s, 0.42, 0.36)], [0.04, 0.036, 0.03], dress, {"per": 2, "segs": 7}), Transform3D.IDENTITY])
		q.append([_blob_mesh(Vector3(0.05 * s, 0.42, 0.38), Vector3(0.03, 0.03, 0.035), skin, 1062, 0.05, 8, 5), Transform3D.IDENTITY])
	q.append([_blob_mesh(Vector3(0, 0.34, -0.1), Vector3(0.27, 0.34, 0.2), cape, 1063, 0.06, 14, 9, Vector3(10, 0, 0)), Transform3D.IDENTITY])
	q.append([_blob_mesh(Vector3(0, 0.6, -0.08), Vector3(0.17, 0.1, 0.12), cape, 1064, 0.05, 12, 6), Transform3D.IDENTITY])
	_fille_commun(q, Vector3(0, 0.66, 0.14), 28.0)
	var ass := _mesh_node("MaillageAssise", q)
	var na := Node3D.new()
	na.name = "Assise"
	na.add_child(ass)
	na.visible = false
	b.extras.append(na)
	return b
