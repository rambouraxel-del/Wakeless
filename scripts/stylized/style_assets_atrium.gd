@tool
class_name StyleAssetsAtrium
extends RefCounted
## Modules supplémentaires de l'atrium (finition esthétique) + bibliothèque de moulures : balayage de profils (cadres,
## corniches), rangées de denticules, fûts cannelés, constellations. Même repère et mêmes outils que StyleAssets
## (StyleKit, ModuleBuilder, StyleAssets.M). Aucun hasard : les variations sont déterministes (hash par index).

const GOLD := "or"

static func ids() -> PackedStringArray:
	return PackedStringArray(["casier_cles", "rosace_plafond", "vase_etoile", "fauteuil_hall", "tapis_hall", "rameau_glycine"])

static func make(id: String) -> ModuleBuilder:
	match id:
		"casier_cles": return casier_cles()
		"rosace_plafond": return rosace_plafond()
		"vase_etoile": return vase_etoile()
		"fauteuil_hall": return fauteuil_hall()
		"tapis_hall": return tapis_hall()
		"rameau_glycine": return rameau_glycine()
	return null

static func M(n: String) -> Material:
	return StyleMaterials.get_mat(n)

static func P(arr: Array) -> PackedVector2Array:
	return StyleAssets.P(arr)

static func hash01(i: int, salt := 0) -> float:
	var h: int = (i * 73856093) ^ (salt * 19349663) ^ 83492791
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 0xffff) / 65535.0

# ================================================================== primitives de maillage

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
	var gn := (b - a).cross(c - a)
	if gn.length_squared() < 1e-12:
		return
	if gn.dot(na + nb + nc) < 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
	var pts := [a, b, c]
	var nrm := [na, nb, nc]
	for i in 3:
		var p: Vector3 = pts[i]
		st.set_normal(nrm[i])
		st.set_uv(Vector2(p.x + p.z, p.y))
		st.add_vertex(p)

static func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, n0: Vector3, n1 := Vector3.ZERO, n2 := Vector3.ZERO, n3 := Vector3.ZERO) -> void:
	if n1 == Vector3.ZERO:
		n1 = n0
		n2 = n0
		n3 = n0
	_tri(st, p0, p1, p2, n0, n1, n2)
	_tri(st, p0, p2, p3, n0, n2, n3)

static func _finish(st: SurfaceTool, mat: Material) -> ArrayMesh:
	return StyleKit._commit(st, mat)

## Boîte à faces planes (12 triangles), centrée sur l'origine.
static func _box_into(st: SurfaceTool, c: Vector3, s: Vector3, xf := Transform3D.IDENTITY) -> void:
	var h := s * 0.5
	var faces := [[Vector3.RIGHT, Vector3.UP, Vector3.BACK], [Vector3.LEFT, Vector3.UP, Vector3.FORWARD], [Vector3.UP, Vector3.BACK, Vector3.RIGHT],
		[Vector3.DOWN, Vector3.BACK, Vector3.LEFT], [Vector3.BACK, Vector3.UP, Vector3.LEFT], [Vector3.FORWARD, Vector3.UP, Vector3.RIGHT]]
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var ctr := c + n * (h * n.abs()).length() * 0.0
		ctr = c + Vector3(n.x * h.x, n.y * h.y, n.z * h.z)
		var uh := Vector3(u.x * h.x, u.y * h.y, u.z * h.z)
		var vh := Vector3(v.x * h.x, v.y * h.y, v.z * h.z)
		var q := [ctr - uh - vh, ctr + uh - vh, ctr + uh + vh, ctr - uh + vh]
		var nn := xf.basis * n
		_quad(st, xf * q[0], xf * q[1], xf * q[2], xf * q[3], nn.normalized())

static func fbox(size: Vector3, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box_into(st, Vector3.ZERO, size)
	return _finish(st, mat)

## Quadrilatère plat (plan XY, face +z), centré.
static func flat_quad(w: float, h: float, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := w * 0.5
	var hh := h * 0.5
	_quad(st, Vector3(-hw, -hh, 0), Vector3(hw, -hh, 0), Vector3(hw, hh, 0), Vector3(-hw, hh, 0), Vector3(0, 0, 1))
	return _finish(st, mat)

static func _seg_normals(prof: Array, kind: int) -> Array:
	# normales plates par segment. kind 0 (cadre) : profil [o, z] ; kind 1 (bande) : profil [y, z] ; renvoie des Vector2
	var out := []
	for i in prof.size() - 1:
		var da: float = float(prof[i + 1][0]) - float(prof[i][0])
		var db: float = float(prof[i + 1][1]) - float(prof[i][1])
		var n := Vector2.ZERO
		if kind == 0:
			n = Vector2(db, -da)      # (composante vers l'extérieur, composante z)
		else:
			n = Vector2(-db, da)      # (composante y, composante z)
		out.append(n.normalized() if n.length() > 1e-9 else Vector2(0, 1))
	return out

static func _vert_normal(sn: Array, j: int, end: bool) -> Vector2:
	# normale au sommet j du segment j (début) ou j-1 (fin) : lissée si l'angle est faible
	var cur: Vector2 = sn[j if not end else j - 1]
	var other_idx := (j - 1) if not end else j
	if other_idx < 0 or other_idx >= sn.size():
		return cur
	var oth: Vector2 = sn[other_idx]
	if cur.dot(oth) > 0.55:
		return (cur + oth).normalized()
	return cur

## Balayage d'un profil [o, z] (du bord extérieur vers l'intérieur ; o > 0 vers l'extérieur du rectangle de référence)
## autour d'un rectangle de demi-dimensions (hw, hh) dans le plan XY, face visible vers +z. Angles à onglet.
static func frame_sweep(hw: float, hh: float, prof: Array, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sn := _seg_normals(prof, 0)
	var dirs := [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, -1, 0)]
	for side in 4:
		var d: Vector3 = dirs[side]
		var ca: Callable = func(o: float, z: float) -> Vector3:
			match side:
				0: return Vector3(hw + o, -(hh + o), z)
				1: return Vector3(hw + o, hh + o, z)
				2: return Vector3(-(hw + o), hh + o, z)
				_: return Vector3(-(hw + o), -(hh + o), z)
		var cb: Callable = func(o: float, z: float) -> Vector3:
			match side:
				0: return Vector3(hw + o, hh + o, z)
				1: return Vector3(-(hw + o), hh + o, z)
				2: return Vector3(-(hw + o), -(hh + o), z)
				_: return Vector3(hw + o, -(hh + o), z)
		for j in prof.size() - 1:
			var o0: float = prof[j][0]
			var z0: float = prof[j][1]
			var o1: float = prof[j + 1][0]
			var z1: float = prof[j + 1][1]
			var n0 := _vert_normal(sn, j, false)
			var n1 := _vert_normal(sn, j + 1, true)
			var w0 := d * n0.x + Vector3(0, 0, n0.y)
			var w1 := d * n1.x + Vector3(0, 0, n1.y)
			_quad(st, ca.call(o0, z0), cb.call(o0, z0), cb.call(o1, z1), ca.call(o1, z1), w0, w0, w1, w1)
	return _finish(st, mat)

## Bande moulurée le long de x (longueur `len`, centrée) : profil [y, z] du bas (contre le mur) au haut (contre le mur).
static func strip(len: float, prof: Array, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sn := _seg_normals(prof, 1)
	var hl := len * 0.5
	for j in prof.size() - 1:
		var y0: float = prof[j][0]
		var z0: float = prof[j][1]
		var y1: float = prof[j + 1][0]
		var z1: float = prof[j + 1][1]
		var n0 := _vert_normal(sn, j, false)
		var n1 := _vert_normal(sn, j + 1, true)
		var w0 := Vector3(0, n0.x, n0.y)
		var w1 := Vector3(0, n1.x, n1.y)
		_quad(st, Vector3(-hl, y0, z0), Vector3(hl, y0, z0), Vector3(hl, y1, z1), Vector3(-hl, y1, z1), w0, w0, w1, w1)
	# onglets de fermeture aux deux bouts (faces planes) : fermeture simple par éventail
	for side in [-1.0, 1.0]:
		var n := Vector3(side, 0, 0)
		var c := Vector3(side * hl, 0, 0)
		for j in prof.size() - 1:
			var a := Vector3(side * hl, prof[j][0], prof[j][1])
			var b := Vector3(side * hl, prof[j + 1][0], prof[j + 1][1])
			var base := Vector3(side * hl, prof[0][0], 0)
			_tri(st, base, a, b, n, n, n)
			c = c
	return _finish(st, mat)

## Rangée de denticules (boîtes planes) le long de x : [y0, y1] vertical, saillie de z0 à z1.
static func dentils(len: float, w: float, pitch: float, y0: float, y1: float, z0: float, z1: float, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := int(floor(len / pitch))
	var x0 := -float(n - 1) * pitch * 0.5
	for i in n:
		_box_into(st, Vector3(x0 + i * pitch, (y0 + y1) * 0.5, (z0 + z1) * 0.5), Vector3(w, y1 - y0, z1 - z0))
	return _finish(st, mat)

## Panneau cannelé (plan XY, face +z) : `flutes` cannelures douces de profondeur `depth`.
static func fluted_panel(w: float, h: float, flutes: int, depth: float, mat: Material, sub := 4) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := flutes * sub
	for k in n:
		var xs := [-w * 0.5 + w * float(k) / n, -w * 0.5 + w * float(k + 1) / n]
		var zs := []
		var ns := []
		for x in xs:
			var phase := (float(x) + w * 0.5) / w * flutes
			zs.append(-depth * (0.5 + 0.5 * cos(TAU * phase)))
			var dz := depth * 0.5 * sin(TAU * phase) * TAU * flutes / w
			ns.append(Vector3(-dz, 0, 1).normalized())
		_quad(st, Vector3(xs[0], 0, zs[0]), Vector3(xs[1], 0, zs[1]), Vector3(xs[1], h, zs[1]), Vector3(xs[0], h, zs[0]), ns[0], ns[1], ns[1], ns[0])
	return _finish(st, mat)

## Révolution cannelée : profil [(rayon, y)…], `flutes` cannelures de profondeur relative `depth` (fraction du rayon),
## `sub` segments par cannelure. Les cannelures s'estompent près des deux extrémités du profil.
static func fluted_lathe(profile: Array, flutes: int, depth: float, sub: int, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := flutes * sub
	var rings := profile.size()
	var y_min: float = profile[0][1]
	var y_max: float = profile[rings - 1][1]
	var span := maxf(y_max - y_min, 0.001)
	var grid := []
	for i in rings:
		var row := []
		var r0: float = profile[i][0]
		var y: float = profile[i][1]
		var t := (y - y_min) / span
		var taper := smoothstep(0.0, 0.1, t) * (1.0 - smoothstep(0.88, 1.0, t))
		var dr_dy := 0.0
		if i > 0 and i < rings - 1:
			dr_dy = (float(profile[i + 1][0]) - float(profile[i - 1][0])) / (float(profile[i + 1][1]) - float(profile[i - 1][1]))
		for k in n + 1:
			var th := TAU * float(k) / n
			var g := 0.5 + 0.5 * cos(float(flutes) * th)
			var r := r0 * (1.0 - depth * g * taper)
			var dr_dth := r0 * depth * taper * 0.5 * float(flutes) * sin(float(flutes) * th)
			var er := Vector3(cos(th), 0, sin(th))
			var et := Vector3(-sin(th), 0, cos(th))
			var nn := (er - et * (dr_dth / maxf(r, 0.001)) - Vector3(0, dr_dy, 0)).normalized()
			row.append([Vector3(er.x * r, y, er.z * r), nn])
		grid.append(row)
	for i in rings - 1:
		for k in n:
			var a: Array = grid[i][k]
			var b: Array = grid[i][k + 1]
			var c: Array = grid[i + 1][k + 1]
			var d: Array = grid[i + 1][k]
			_quad(st, a[0], b[0], c[0], d[0], a[1], b[1], c[1], d[1])
	return _finish(st, mat)

## Étoile à 4 branches fine (extrusion peu profonde), partagée.
static var _star_cache := {}
static func star_mesh(r: float, mat_id: String, depth := 0.03) -> ArrayMesh:
	var key := "%s_%.3f_%.3f" % [mat_id, r, depth]
	if not _star_cache.has(key):
		_star_cache[key] = StyleKit.extrude(StyleKit.star_outline(r, r * 0.38, 4), depth, M(mat_id), 0.0)
	return _star_cache[key]

## Filet fin entre deux points (boîte plate), dans un repère donné.
static func line_between(a: Vector3, b: Vector3, thick: float, depth: float, mat: Material) -> Array:
	var d := b - a
	var len := d.length()
	var ang := atan2(d.y, d.x)
	var basis := Basis(Vector3.BACK, ang)
	return [fbox(Vector3(len, thick, depth), mat), Transform3D(basis, (a + b) * 0.5)]

## Constellation : étoiles reliées par des filets. pts : Array de Vector2 (plan local x, y) ; links : paires d'index.
static func constellation(pts: Array, links: Array, star_r: float, scale: float, origin: Transform3D, parts: Array, star_mat := "or_vieilli", line_mat := "or_vieilli") -> void:
	for l in links:
		var pa: Vector2 = pts[l[0]] * scale
		var pb: Vector2 = pts[l[1]] * scale
		var d := pb - pa
		var dn := d.normalized()
		var a3 := Vector3(pa.x, pa.y, 0) + Vector3(dn.x, dn.y, 0) * star_r * 0.9
		var b3 := Vector3(pb.x, pb.y, 0) - Vector3(dn.x, dn.y, 0) * star_r * 0.9
		if (b3 - a3).length() < 0.02:
			continue
		var ln := line_between(a3, b3, 0.022, 0.022, M(line_mat))
		parts.append([ln[0], origin * (ln[1] as Transform3D)])
	for i in pts.size():
		var p: Vector2 = pts[i] * scale
		var r := star_r * (0.75 + 0.5 * hash01(i, 5))
		parts.append([star_mesh(r, star_mat), origin * Transform3D(Basis.IDENTITY, Vector3(p.x, p.y, 0.0))])

## Modèles de constellations (coordonnées 0..1) : paires [points, liens].
static func constellation_model(k: int) -> Array:
	match k % 5:
		0: return [[Vector2(0.0, 0.2), Vector2(0.18, 0.55), Vector2(0.4, 0.4), Vector2(0.62, 0.75), Vector2(0.85, 0.5), Vector2(1.0, 0.8)], [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5]]]
		1: return [[Vector2(0.0, 0.5), Vector2(0.25, 0.8), Vector2(0.5, 0.45), Vector2(0.75, 0.2), Vector2(1.0, 0.55), Vector2(0.5, 0.0)], [[0, 1], [1, 2], [2, 3], [3, 4], [2, 5]]]
		2: return [[Vector2(0.0, 0.7), Vector2(0.3, 0.3), Vector2(0.55, 0.65), Vector2(0.8, 0.25), Vector2(1.0, 0.6)], [[0, 1], [1, 2], [2, 3], [3, 4]]]
		3: return [[Vector2(0.0, 0.3), Vector2(0.3, 0.6), Vector2(0.45, 0.2), Vector2(0.7, 0.8), Vector2(1.0, 0.4), Vector2(0.7, 0.1)], [[0, 1], [1, 2], [1, 3], [3, 4], [4, 5], [2, 5]]]
	return [[Vector2(0.0, 0.5), Vector2(0.2, 0.15), Vector2(0.45, 0.7), Vector2(0.7, 0.3), Vector2(0.95, 0.85)], [[0, 1], [1, 2], [2, 3], [3, 4]]]

# ================================================================== pilastre (module et coque)

## Pièces d'un pilastre adossé à z = 0 (base au sol local y = 0) : socle lambrissé, fût cannelé, chapiteau doré.
## Renvoie [[mesh, Transform3D], …].
static func pilaster_parts(h: float, base_h := 1.25, cap_h := 0.8) -> Array:
	var parts := []
	var bw := 0.98
	var gold := M("or_vieilli")
	var stone := M("moulure_pierre")
	parts.append([fbox(Vector3(bw, base_h, 0.5), M("boiserie_prune")), ModuleBuilder.at(Vector3(0, base_h * 0.5, 0.25))])
	parts.append([fbox(Vector3(bw + 0.08, 0.12, 0.58), stone), ModuleBuilder.at(Vector3(0, base_h + 0.04, 0.27))])
	parts.append([fbox(Vector3(bw + 0.04, 0.04, 0.54), gold), ModuleBuilder.at(Vector3(0, base_h + 0.12, 0.26))])
	var sh_bot := base_h + 0.15
	var sh_top := h - cap_h
	parts.append([fbox(Vector3(0.7, sh_top - sh_bot, 0.3), stone), ModuleBuilder.at(Vector3(0, (sh_bot + sh_top) * 0.5, 0.15))])
	parts.append([fluted_panel(0.7, sh_top - sh_bot, 5, 0.03, stone, 3), ModuleBuilder.at(Vector3(0, sh_bot, 0.305))])
	parts.append([fbox(Vector3(0.76, 0.06, 0.34), gold), ModuleBuilder.at(Vector3(0, sh_bot + 0.02, 0.17))])
	parts.append([fbox(Vector3(0.76, 0.06, 0.34), gold), ModuleBuilder.at(Vector3(0, sh_top - 0.02, 0.17))])
	# chapiteau : bloc évasé, bague d'or, croissant et étoile
	parts.append([fbox(Vector3(0.86, 0.22, 0.4), stone), ModuleBuilder.at(Vector3(0, sh_top + 0.12, 0.2))])
	parts.append([fbox(Vector3(0.92, 0.06, 0.46), gold), ModuleBuilder.at(Vector3(0, sh_top + 0.25, 0.22))])
	parts.append([StyleKit.rounded_box(Vector3(1.0, cap_h - 0.34, 0.5), 0.07, stone, 1), ModuleBuilder.at(Vector3(0, h - 0.17 - (cap_h - 0.34) * 0.5, 0.24))])
	parts.append([fbox(Vector3(1.08, 0.12, 0.56), stone), ModuleBuilder.at(Vector3(0, h - 0.06, 0.26))])
	var my := h - 0.17 - (cap_h - 0.34) * 0.5
	parts.append([_small_crescent(), ModuleBuilder.at(Vector3(-0.12, my, 0.5), Vector3(0, 0, 90))])
	parts.append([star_mesh(0.09, "or_vieilli", 0.03), ModuleBuilder.at(Vector3(0.14, my, 0.5))])
	return parts

static var _cres_cache: ArrayMesh = null
static func _small_crescent() -> ArrayMesh:
	if _cres_cache == null:
		_cres_cache = StyleKit.extrude(StyleKit.crescent_outline(0.12, 0.55, 8), 0.03, M("or_vieilli"), 0.0)
	return _cres_cache

# ================================================================== habillage des murs de l'atrium

const WALLS := {
	"N": {"o": Vector3(0, 0, -13), "yaw": 0.0, "sg": 1.0, "t0": -12.9, "t1": 12.9},
	"S": {"o": Vector3(0, 0, 13), "yaw": PI, "sg": -1.0, "t0": -12.9, "t1": 12.9},
	"W": {"o": Vector3(-15, 0, 0), "yaw": PI * 0.5, "sg": -1.0, "t0": -12.9, "t1": 12.9},
	"E": {"o": Vector3(15, 0, 0), "yaw": -PI * 0.5, "sg": 1.0, "t0": -12.9, "t1": 12.9},
}

## Repère d'un point (t le long du mur en coordonnées monde, v hauteur, n saillie vers la salle) pour un mur ou une rive.
static func wall_xf(w: Dictionary, t: float, v: float, n := 0.0) -> Transform3D:
	var b := Basis(Vector3.UP, float(w["yaw"]))
	var o: Vector3 = w["o"]
	return Transform3D(b, o + b * Vector3(float(w["sg"]) * t, v, n))

## Implantation des pilastres et des obstacles (portes, fenêtres, arche) : positions le long du mur.
static func layout(name: String) -> Dictionary:
	match name:
		"N": return {"lp": [-14.3, -8.28, -4.72, 4.72, 8.28, 14.3], "lo": [[-7.7, -5.3], [5.3, 7.7]],
			"up": [-14.3, -12.44, -6.56, -3.5, 3.5, 6.56, 12.44, 14.3], "uo": [[-11.86, -7.14], [7.14, 11.86], [-2.8, 2.8]], "co": []}
		"S": return {"lp": [-14.3, -4.4, 4.4, 14.3], "lo": [[-2.5, 2.5]],
			"up": [-14.3, -12.44, -6.56, -3.5, 3.5, 6.56, 12.44, 14.3], "uo": [[-11.86, -7.14], [7.14, 11.86], [-2.9, 2.9]], "co": [[-2.8, 2.8]]}
		"W": return {"lp": [-11.7, -7.78, -4.22, -1.78, 1.78, 4.22, 7.78, 11.7], "lo": [[-7.2, -4.8], [-1.2, 1.2], [4.8, 7.2]],
			"up": [-11.7, -7.94, -2.07, 3.07, 8.94, 11.7], "uo": [[-7.36, -2.64], [3.64, 8.36]], "co": []}
	return {"lp": [-11.7, -9.275, -5.725, -3.33, 3.33, 5.725, 9.275, 11.7], "lo": [[-8.7, -6.3], [6.3, 8.7], [-2.76, 2.76]],
		"up": [-11.7, -7.94, -2.07, 3.07, 8.94, 11.7], "uo": [[-7.36, -2.64], [3.64, 8.36]], "co": [[-3.05, 3.05]]}

static func _hits(a: float, b: float, obst: Array) -> bool:
	for o in obst:
		if a < float(o[1]) and b > float(o[0]):
			return true
	return false

## Intervalles libres [a, b] d'un mur entre obstacles.
static func _free_spans(t0: float, t1: float, obst: Array) -> Array:
	var sorted := obst.duplicate()
	sorted.sort_custom(func(x, y): return float(x[0]) < float(y[0]))
	var out := []
	var cur := t0
	for o in sorted:
		if float(o[0]) > cur:
			out.append([cur, minf(float(o[0]), t1)])
		cur = maxf(cur, float(o[1]))
	if cur < t1:
		out.append([cur, t1])
	return out

static func _bays(pil: Array, obst: Array, min_w := 0.8) -> Array:
	var out := []
	for i in pil.size() - 1:
		var a: float = float(pil[i]) + 0.475 + 0.1
		var b: float = float(pil[i + 1]) - 0.475 - 0.1
		if b - a >= min_w and not _hits(a, b, obst):
			out.append([a, b])
	return out

static func _split(a: float, b: float, max_w: float, gap: float) -> Array:
	var n := maxi(1, int(ceil((b - a - 0.01) / max_w)))
	var w := ((b - a) - gap * (n - 1)) / n
	var out := []
	for i in n:
		out.append([a + i * (w + gap), a + i * (w + gap) + w])
	return out

# profils
const PROF_FRAME := [[0.20, 0.0], [0.20, 0.035], [0.17, 0.065], [0.125, 0.082], [0.09, 0.082], [0.07, 0.056], [0.035, 0.044], [0.0, 0.044]]
const PROF_FILLET := [[0.034, 0.04], [0.034, 0.066], [0.02, 0.078], [0.0, 0.078]]
const PROF_PANEL := [[0.09, 0.0], [0.09, 0.03], [0.07, 0.05], [0.045, 0.055], [0.0, 0.055]]
const PROF_PLINTH := [[0.0, 0.0], [0.0, 0.14], [0.2, 0.14], [0.27, 0.1], [0.32, 0.0]]
const PROF_RAIL := [[1.12, 0.0], [1.12, 0.06], [1.16, 0.10], [1.2, 0.115], [1.245, 0.10], [1.28, 0.06], [1.28, 0.0]]
const PROF_RAIL_GOLD := [[1.275, 0.05], [1.275, 0.075], [1.31, 0.075], [1.31, 0.0]]
const PROF_CORNICE_LOW := [[4.85, 0.0], [4.85, 0.12], [4.92, 0.18], [5.0, 0.20], [5.22, 0.20], [5.22, 0.34], [5.30, 0.40], [5.40, 0.44], [5.5, 0.44], [5.5, 0.0]]
const PROF_CORNICE_TOP := [[18.2, 0.0], [18.2, 0.22], [18.3, 0.30], [18.45, 0.34], [18.85, 0.34], [18.85, 0.56], [18.95, 0.69], [19.1, 0.75], [19.25, 0.75], [19.3, 0.72],
	[19.42, 0.46], [19.58, 0.28], [19.78, 0.14], [20.0, 0.0]]
const PROF_STRING := [[0.0, 0.0], [0.0, 0.12], [0.1, 0.19], [0.2, 0.19], [0.27, 0.14], [0.33, 0.1], [0.36, 0.0]]

## Habillage complet des quatre murs : lambris, cadres moulurés à filet d'or, pilastres, corniches à denticules, frise.
## Les pièces sont ajoutées à `parts` ([mesh, Transform3D]).
static func dress_walls(parts: Array) -> void:
	var cache := {}
	var constel_i := 0
	for name in ["N", "S", "W", "E"]:
		var w: Dictionary = WALLS[name]
		var lay := layout(name)
		var lp: Array = lay["lp"]
		var up: Array = lay["up"]
		var lo: Array = lay["lo"]
		var uo: Array = lay["uo"]
		var co: Array = lay["co"]
		var t0: float = w["t0"]
		var t1: float = w["t1"]
		# --- socle : plinthe et cimaise sur les intervalles libres de portes
		for sp in _free_spans(t0, t1, lo):
			var a: float = sp[0]
			var b: float = sp[1]
			if b - a < 0.3:
				continue
			var xf := wall_xf(w, (a + b) * 0.5, 0.0)
			parts.append([strip(b - a, PROF_PLINTH, M("boiserie_prune")), xf])
			parts.append([strip(b - a, PROF_RAIL, M("boiserie_prune")), xf])
			parts.append([strip(b - a, PROF_RAIL_GOLD, M("or_vieilli")), xf])
		# --- panneaux du lambris et cadres du rez-de-chaussée
		for bay in _bays(lp, lo):
			var a: float = bay[0]
			var b: float = bay[1]
			for pn in _split(a, b, 1.15, 0.16):
				var cw: float = float(pn[1]) - float(pn[0])
				var key := "pan_%.2f" % cw
				if not cache.has(key):
					cache[key] = [frame_sweep(cw * 0.5 - 0.06, 0.34, PROF_PANEL, M("boiserie_prune")), flat_quad(cw - 0.12, 0.68, M("boiserie_prune"))]
				var cx := (float(pn[0]) + float(pn[1])) * 0.5
				parts.append([cache[key][0], wall_xf(w, cx, 0.62, 0.115)])
			for fr in _split(a, b, 3.3, 0.35):
				_frame_into(parts, cache, w, float(fr[0]), float(fr[1]), 1.5, 4.6, true)
		# --- cadres de l'étage (deux rangées), étoile centrale
		for bay in _bays(up, uo):
			for fr in _split(float(bay[0]), float(bay[1]), 3.3, 0.35):
				_frame_into(parts, cache, w, float(fr[0]), float(fr[1]), 6.75, 11.4, false)
				_frame_into(parts, cache, w, float(fr[0]), float(fr[1]), 11.8, 16.45, false)
		# --- pilastres
		for p in lp:
			parts.append_array(_placed(_pilaster_cached(cache, 4.85, 1.2, 0.8), wall_xf(w, float(p), 0.0)))
		for p in up:
			parts.append_array(_placed(_pilaster_cached(cache, 12.1, 0.9, 1.0), wall_xf(w, float(p), 6.0)))
		# --- corniche sous la galerie (interrompue au-dessus de l'entrée / de l'arche)
		for sp in _free_spans(t0, t1, co):
			var a: float = sp[0]
			var b: float = sp[1]
			if b - a < 0.3:
				continue
			var xf := wall_xf(w, (a + b) * 0.5, 0.0)
			parts.append([strip(b - a, PROF_CORNICE_LOW, M("moulure_pierre")), xf])
			parts.append([dentils(b - a - 0.1, 0.14, 0.28, 5.0, 5.22, 0.20, 0.32, M("moulure_pierre")), xf])
			parts.append([strip(b - a, [[4.99, 0.19], [4.99, 0.235], [5.02, 0.235], [5.02, 0.19]], M("or_vieilli")), xf])
			parts.append([strip(b - a, [[5.215, 0.34], [5.215, 0.375], [5.25, 0.375], [5.25, 0.34]], M("or_vieilli")), xf])
		# --- bandeau et plinthe de l'étage (sur la galerie)
		var span := t1 - t0
		var mid := (t0 + t1) * 0.5
		parts.append([strip(span, PROF_STRING, M("moulure_pierre")), wall_xf(w, mid, 6.0)])
		parts.append([strip(span, [[0.31, 0.11], [0.31, 0.14], [0.35, 0.14], [0.35, 0.0]], M("or_vieilli")), wall_xf(w, mid, 6.0)])
		# --- frise de constellations au-dessus des fenêtres
		parts.append([flat_quad(span, 1.0, M("pierre_sombre")), wall_xf(w, mid, 17.6, 0.02)])
		parts.append([strip(span, [[17.08, 0.0], [17.08, 0.05], [17.12, 0.06], [17.16, 0.05], [17.16, 0.0]], M("or_vieilli")), wall_xf(w, mid, 0.0)])
		parts.append([strip(span, [[18.04, 0.0], [18.04, 0.05], [18.08, 0.06], [18.12, 0.05], [18.12, 0.0]], M("or_vieilli")), wall_xf(w, mid, 0.0)])
		var cons := []
		for i in up.size() - 1:
			var a: float = float(up[i]) + 0.8
			var b: float = float(up[i + 1]) - 0.8
			if b - a >= 1.6:
				cons.append([a, b])
		for c in cons:
			var span_c := minf(float(c[1]) - float(c[0]), 5.5)
			var cx := (float(c[0]) + float(c[1])) * 0.5
			var model := constellation_model(constel_i)
			constel_i += 1
			var pts: Array = model[0]
			var sc := Vector2(span_c, 0.55)
			# la constellation est dessinée dans le repère local (x le long du mur) : conversion t -> u
			var origin := wall_xf(w, cx, 17.6 - 0.31, 0.045)
			var scaled := []
			for q in pts:
				var qq: Vector2 = q
				scaled.append(Vector2((qq.x - 0.5) * sc.x * float(w["sg"]) * 1.0, qq.y * sc.y))
			constellation(scaled, model[1], 0.045, 1.0, origin, parts)
		# --- corniche haute à denticules (sous le plafond)
		var xf_top := wall_xf(w, mid, 0.0)
		parts.append([strip(span, PROF_CORNICE_TOP, M("moulure_pierre")), xf_top])
		parts.append([dentils(span - 0.1, 0.24, 0.5, 18.45, 18.85, 0.34, 0.52, M("moulure_pierre")), xf_top])
		parts.append([strip(span, [[18.43, 0.33], [18.43, 0.39], [18.47, 0.39], [18.47, 0.33]], M("or_vieilli")), xf_top])
		parts.append([strip(span, [[18.84, 0.52], [18.84, 0.58], [18.88, 0.58], [18.88, 0.52]], M("or_vieilli")), xf_top])
		parts.append([strip(span, [[19.27, 0.75], [19.27, 0.78], [19.31, 0.78], [19.31, 0.72]], M("or_vieilli")), xf_top])
		if name == "S":
			_medallion(parts, w, 0.0, 11.4)

static func _pilaster_cached(cache: Dictionary, h: float, bh: float, ch: float) -> Array:
	var key := "pil_%.2f_%.2f" % [h, bh]
	if not cache.has(key):
		cache[key] = pilaster_parts(h, bh, ch)
	return cache[key]

static func _placed(src: Array, xf: Transform3D) -> Array:
	var out := []
	for p in src:
		out.append([p[0], xf * (p[1] as Transform3D)])
	return out

## Cadre mouluré entre deux positions t, de v0 à v1 : moulure de pierre, filet d'or, fond d'enduit plus sombre.
static func _frame_into(parts: Array, cache: Dictionary, w: Dictionary, ta: float, tb: float, v0: float, v1: float, low: bool) -> void:
	var fw := tb - ta
	var fh := v1 - v0
	var key := "fr_%.2f_%.2f" % [fw, fh]
	if not cache.has(key):
		var hw := fw * 0.5 - 0.2
		var hh := fh * 0.5 - 0.2
		cache[key] = [frame_sweep(hw, hh, PROF_FRAME, M("moulure_pierre")), frame_sweep(hw, hh, PROF_FILLET, M("or_vieilli")),
			flat_quad(hw * 2.0 + 0.02, hh * 2.0 + 0.02, M("enduit_panneau"))]
	var xf := wall_xf(w, (ta + tb) * 0.5, (v0 + v1) * 0.5, 0.0)
	parts.append([cache[key][0], xf])
	parts.append([cache[key][1], xf])
	parts.append([cache[key][2], xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.025))])

## Grand médaillon doré (mur sud) : anneaux, étoile à huit branches, croissant.
static func _medallion(parts: Array, w: Dictionary, t: float, v: float) -> void:
	var xf := wall_xf(w, t, v, 0.0)
	parts.append([StyleKit.extrude(StyleAssets._circle(2.5, 48), 0.05, M("enduit_panneau"), 0.0), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.03))])
	parts.append([StyleKit.extrude(StyleAssets._ring(2.5, 2.3, 48), 0.12, M("moulure_pierre"), 0.02), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.05))])
	parts.append([StyleKit.extrude(StyleAssets._ring(2.3, 2.26, 48), 0.14, M("or_vieilli"), 0.0), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.05))])
	parts.append([StyleKit.extrude(StyleAssets._ring(1.5, 1.46, 40), 0.1, M("or_vieilli"), 0.0), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.05))])
	parts.append([StyleKit.extrude(StyleKit.star_outline(1.35, 0.5, 8), 0.07, M("or_vieilli"), 0.01), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.07))])
	parts.append([StyleKit.extrude(StyleKit.crescent_outline(0.5, 0.55), 0.06, M("lune"), 0.01), xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0.05, 0.1))])
	for i in 12:
		var a := TAU * i / 12.0
		parts.append([star_mesh(0.1, "or_vieilli", 0.04), xf * Transform3D(Basis.IDENTITY, Vector3(cos(a) * 1.9, sin(a) * 1.9, 0.08))])

# ================================================================== galeries : rives, consoles, sous-faces

const RIMS := {
	"N": {"o": Vector3(0, 0, -9.5), "yaw": 0.0, "sg": 1.0, "t0": -11.5, "t1": 11.5, "cons": [-5.3, 5.3], "gal": [-15.0, 15.0, 3.2, -11.4]},
	"W": {"o": Vector3(-11.5, 0, 0), "yaw": PI * 0.5, "sg": -1.0, "t0": -9.5, "t1": 13.0, "cons": [-6.5, 10.75], "gal": [-9.5, 13.0, 3.2, -13.4]},
	"E": {"o": Vector3(11.5, 0, 0), "yaw": -PI * 0.5, "sg": 1.0, "t0": -9.5, "t1": 13.0, "cons": [-6.5, 10.75], "gal": [-9.5, 13.0, 3.2, 13.4]},
}
const PROF_RIM_SLAB := [[5.5, 0.0], [5.5, 0.1], [5.56, 0.15], [5.64, 0.15], [5.68, 0.11], [5.72, 0.11], [5.8, 0.16], [5.88, 0.16], [5.93, 0.12], [6.0, 0.12], [6.0, 0.0]]
const PROF_ARCHITRAVE := [[4.95, 0.0], [4.95, 0.10], [5.0, 0.145], [5.06, 0.145], [5.09, 0.105], [5.22, 0.105], [5.26, 0.135], [5.3, 0.135], [5.34, 0.095], [5.5, 0.095], [5.5, 0.0]]
const PROF_COFFER := [[0.17, 0.0], [0.17, 0.04], [0.13, 0.09], [0.08, 0.105], [0.0, 0.085]]
const CONSOLE := [[0.0, 0.0], [0.32, 0.0], [0.345, -0.07], [0.31, -0.16], [0.23, -0.27], [0.18, -0.4], [0.17, -0.54], [0.21, -0.67], [0.18, -0.79], [0.1, -0.85], [0.03, -0.8], [0.04, -0.7], [0.0, -0.6]]

## Rives des galeries : bandeau mouluré de rive, architrave, consoles galbées, sous-face à caissons dorés.
static func dress_galleries(parts: Array) -> void:
	var big := []
	for q in CONSOLE:
		big.append([float(q[0]) * 1.5, float(q[1]) * 1.4])
	var console_mesh := StyleKit.extrude(P(big), 0.42, M("moulure_pierre"), 0.04)
	var bead := StyleKit.sphere(0.05, M("or_vieilli"), 10, 5)
	for name in ["N", "W", "E"]:
		var r: Dictionary = RIMS[name]
		var t0: float = r["t0"]
		var t1: float = r["t1"]
		var mid := (t0 + t1) * 0.5
		var len := t1 - t0
		var xf := wall_xf(r, mid, 0.0)
		parts.append([strip(len, PROF_RIM_SLAB, M("moulure_pierre")), xf])
		parts.append([strip(len, [[5.7, 0.11], [5.7, 0.175], [5.74, 0.175], [5.74, 0.11]], M("or_vieilli")), xf])
		parts.append([strip(len, PROF_ARCHITRAVE, M("moulure_pierre")), xf])
		parts.append([fbox(Vector3(len, 0.55, 0.3), M("moulure_pierre")), xf * Transform3D(Basis.IDENTITY, Vector3(0, 5.225, -0.15))])
		parts.append([strip(len, [[5.04, 0.14], [5.04, 0.16], [5.07, 0.16], [5.07, 0.135]], M("or_vieilli")), xf])
		parts.append([strip(len, [[5.285, 0.13], [5.285, 0.15], [5.31, 0.15], [5.31, 0.13]], M("or_vieilli")), xf])
		for c in r["cons"]:
			var cxf := wall_xf(r, float(c), 4.97, 0.0) * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3.ZERO)
			parts.append([console_mesh, cxf])
			parts.append([bead, cxf * Transform3D(Basis.IDENTITY, Vector3(0.18, -1.1, 0.0))])
			parts.append([star_mesh(0.1, "or_vieilli", 0.03), cxf * Transform3D(Basis.IDENTITY, Vector3(0.3, -0.45, 0.22))])
			parts.append([star_mesh(0.1, "or_vieilli", 0.03), cxf * Transform3D(Basis.IDENTITY, Vector3(0.3, -0.45, -0.22))])
			parts.append([fbox(Vector3(0.54, 0.05, 0.5), M("or_vieilli")), cxf * Transform3D(Basis.IDENTITY, Vector3(0.26, 0.03, 0.0))])
		# sous-face à caissons
		var g: Array = r["gal"]
		var ga: float = g[0]
		var gb: float = g[1]
		var depth: float = g[2]
		var cz: float = g[3]
		var n := int(round((gb - ga) / 2.6))
		var pitch := (gb - ga) / n
		var down := Basis(Vector3.RIGHT, PI * 0.5)       # z local -> vers le bas, y local -> +z
		for i in n:
			var c := ga + pitch * (i + 0.5)
			var hw := pitch * 0.5 - 0.3
			var hh := depth * 0.5 - 0.18
			var key := "cof_%.2f" % pitch
			var pos := Vector3.ZERO
			var rot := down
			match name:
				"N":
					pos = Vector3(c, 5.5, cz)
				"W":
					pos = Vector3(cz, 5.5, c)
					rot = Basis(Vector3.UP, PI * 0.5) * down
				_:
					pos = Vector3(cz, 5.5, c)
					rot = Basis(Vector3.UP, PI * 0.5) * down
			var xfc := Transform3D(rot, pos)
			var hw2 := hw
			var hh2 := hh
			if name != "N":
				hw2 = hh
				hh2 = hw
				# repère local (x,y) = (monde x, monde z) après `down` ; pour W/E on échange les demi-dimensions
				xfc = Transform3D(down, pos)
			parts.append([frame_sweep(hw2, hh2, PROF_COFFER, M("moulure_pierre")), xfc])
			parts.append([frame_sweep(hw2, hh2, [[0.035, 0.07], [0.035, 0.095], [0.0, 0.095]], M("or_vieilli")), xfc])
			parts.append([flat_quad(hw2 * 2.0 + 0.02, hh2 * 2.0 + 0.02, M("enduit_panneau")), xfc * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.02))])

# ================================================================== plafond : caissons, constellations

static func dress_ceiling(parts: Array) -> void:
	var xs := [[-15.0, -9.33], [-8.67, -3.33], [-2.67, 2.67], [3.33, 8.67], [9.33, 15.0]]
	var zs := [[-13.0, -7.3], [-6.7, -0.3], [0.3, 6.7], [7.3, 13.0]]
	var down := Basis(Vector3.RIGHT, PI * 0.5)
	var k := 0
	for i in xs.size():
		for j in zs.size():
			k += 1
			if i == 2 and (j == 1 or j == 2):
				continue
			var x0: float = xs[i][0]
			var x1: float = xs[i][1]
			var z0: float = zs[j][0]
			var z1: float = zs[j][1]
			var cx := (x0 + x1) * 0.5
			var cz := (z0 + z1) * 0.5
			var hw := (x1 - x0) * 0.5 - 0.45
			var hh := (z1 - z0) * 0.5 - 0.45
			var xf := Transform3D(down, Vector3(cx, 20.0, cz))
			parts.append([frame_sweep(hw, hh, [[0.2, 0.0], [0.2, 0.04], [0.15, 0.1], [0.1, 0.12], [0.0, 0.1]], M("moulure_pierre")), xf])
			parts.append([frame_sweep(hw, hh, [[0.04, 0.09], [0.04, 0.125], [0.0, 0.125]], M("or_vieilli")), xf])
			parts.append([frame_sweep(hw - 0.4, hh - 0.4, [[0.03, 0.0], [0.03, 0.03], [0.0, 0.03]], M("or_vieilli")), xf])
			# constellation propre à chaque caisson
			var model := constellation_model(k * 3 + i)
			var pts := []
			for q in model[0]:
				var qq: Vector2 = q
				pts.append(Vector2((qq.x - 0.5) * (hw * 1.2), (qq.y - 0.5) * (hh * 0.9)))
			constellation(pts, model[1], 0.11, 1.0, xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.035)), parts)

# ================================================================== modules nouveaux

## Rosace du plafond autour du lustre (origine = plan du plafond, la rosace descend de 0,7 m).
static func rosace_plafond() -> ModuleBuilder:
	var b := ModuleBuilder.new("rosace_plafond")
	b.add(StyleKit.cylinder(3.6, 0.16, M("moulure_pierre"), 48), ModuleBuilder.at(Vector3(0, -0.16, 0)))
	b.add(StyleKit.torus(3.45, 0.07, M("or_vieilli"), 56, 8), ModuleBuilder.at(Vector3(0, -0.17, 0)))
	b.add(StyleKit.cylinder(3.1, 0.16, M("moulure_pierre"), 48), ModuleBuilder.at(Vector3(0, -0.3, 0)))
	b.add(StyleKit.torus(2.95, 0.05, M("or_vieilli"), 56, 6), ModuleBuilder.at(Vector3(0, -0.31, 0)))
	b.add(StyleKit.cylinder(2.5, 0.14, M("enduit_panneau"), 48), ModuleBuilder.at(Vector3(0, -0.42, 0)))
	b.add(StyleKit.torus(2.35, 0.06, M("moulure_pierre"), 48, 8), ModuleBuilder.at(Vector3(0, -0.43, 0)))
	b.add(StyleKit.torus(2.2, 0.03, M("or_vieilli"), 48, 6), ModuleBuilder.at(Vector3(0, -0.43, 0)))
	b.add(StyleKit.cylinder(1.3, 0.14, M("moulure_pierre"), 40), ModuleBuilder.at(Vector3(0, -0.56, 0)))
	b.add(StyleKit.torus(1.3, 0.05, M("or_vieilli"), 40, 6), ModuleBuilder.at(Vector3(0, -0.57, 0)))
	b.add(StyleKit.cylinder(0.6, 0.12, M("or_vieilli"), 32), ModuleBuilder.at(Vector3(0, -0.68, 0)))
	var ray := fbox(Vector3(1.0, 0.03, 0.06), M("or_vieilli"))
	var petal := StyleKit.extrude(P([[0.0, 0.0], [0.5, 0.1], [0.9, 0.0], [0.5, -0.1]]), 0.02, M("or_vieilli"), 0.0)
	for i in 16:
		var a := TAU * i / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		b.add(ray, Transform3D(Basis(Vector3.UP, -a), d * 1.85 + Vector3(0, -0.5, 0)))
		b.add(star_mesh(0.1, "or_vieilli", 0.03), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), d * 2.78 + Vector3(0, -0.31, 0)) * Transform3D(Basis.IDENTITY, Vector3.ZERO))
		b.add(petal, Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.RIGHT, PI * 0.5), d * 0.62 + Vector3(0, -0.745, 0)))
	b.cast_shadows = false
	return b

## Casier à clés derrière le comptoir (face vers +z, adossé à z = 0) : 24 crochets numérotés 101–124 ; le 107 est vide.
static func casier_cles() -> ModuleBuilder:
	var b := ModuleBuilder.new("casier_cles")
	var W := 2.7
	var H := 1.38
	b.box(Vector3(W, 0.5, 0.45), 0.04, "boiserie_prune", Vector3(0, 0.25, 0.225))
	b.box(Vector3(W + 0.1, 0.07, 0.5), 0.03, "moulure_pierre", Vector3(0, 0.535, 0.25))
	for i in 4:
		var x := (i - 1.5) * 0.66
		b.add(frame_sweep(0.24, 0.17, PROF_PANEL, M("boiserie_prune")), ModuleBuilder.at(Vector3(x, 0.26, 0.46)))
		b.add(StyleKit.sphere(0.025, M("or_vieilli"), 6, 3), ModuleBuilder.at(Vector3(x + (0.17 if i % 2 == 0 else -0.17), 0.3, 0.5)))
	b.add(fbox(Vector3(W, H - 0.57, 0.1), M("tapis_prune")), ModuleBuilder.at(Vector3(0, (0.57 + H) * 0.5, 0.05)))
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.1, H - 0.5, 0.18), 0.03, "boiserie_prune", Vector3(sx * (W * 0.5), (0.5 + H) * 0.5, 0.09))
	b.box(Vector3(W + 0.2, 0.1, 0.3), 0.04, "boiserie_prune", Vector3(0, H + 0.03, 0.14))
	b.add(StyleKit.rounded_box(Vector3(W + 0.24, 0.03, 0.34), 0.012, M("or_vieilli"), 1), ModuleBuilder.at(Vector3(0, H + 0.1, 0.15)))
	var key_mesh := _key_mesh()
	for row in 2:
		var y := 0.98 + row * 0.36
		for col in 8:
			var num := 101 + row * 8 + col
			var x := (col - 3.5) * 0.32
			b.add(StyleKit.sphere(0.024, M("or_vieilli"), 6, 3), ModuleBuilder.at(Vector3(x, y, 0.16)))
			b.add(StyleKit.cylinder(0.009, 0.06, M("or_vieilli"), 5), ModuleBuilder.at(Vector3(x, y - 0.02, 0.19), Vector3(90, 0, 0)))
			b.add(fbox(Vector3(0.15, 0.07, 0.012), M("draps")), ModuleBuilder.at(Vector3(x, y - 0.25, 0.12)))
			var lb := b.label(str(num), Vector3(x, y - 0.25, 0.1265), 22, Color("#3a2430"), Vector3.ZERO, 0.0012)
			lb.name = "Plaque_%d" % num
			if num != 107:
				b.add(key_mesh, ModuleBuilder.at(Vector3(x, y - 0.02, 0.205), Vector3.ZERO, Vector3(0.72, 0.72, 0.72)))
	b.omni(Vector3(0, 1.5, 1.2), Color("#ffb066"), 1.0, 4.0, false, "LumiereCasier")
	b.collide(Vector3(W + 0.2, 1.3, 0.5), Vector3(0, 0.65, 0.25))
	b.cast_shadows = false
	return b

static var _key_cache: ArrayMesh = null
## Petite clé dorée pendue (anneau, tige, panneton), le haut à l'origine.
static func _key_mesh() -> ArrayMesh:
	if _key_cache == null:
		var parts := []
		parts.append([StyleKit.torus(0.032, 0.008, M("or_vieilli"), 12, 4), ModuleBuilder.at(Vector3(0, -0.06, 0), Vector3(90, 0, 0))])
		parts.append([fbox(Vector3(0.014, 0.17, 0.014), M("or_vieilli")), ModuleBuilder.at(Vector3(0, -0.17, 0))])
		parts.append([fbox(Vector3(0.05, 0.02, 0.014), M("or_vieilli")), ModuleBuilder.at(Vector3(0.025, -0.24, 0))])
		parts.append([fbox(Vector3(0.035, 0.02, 0.014), M("or_vieilli")), ModuleBuilder.at(Vector3(0.018, -0.2, 0))])
		_key_cache = StyleKit.merge(parts)
	return _key_cache

## Vase d'apparat sur piédestal (hauteur 1,5 m) : panse ventrue, anses, bague d'or, étoile ; fleurs séchées lavande.
static func vase_etoile() -> ModuleBuilder:
	var b := ModuleBuilder.new("vase_etoile")
	b.add(StyleKit.lathe(P([[0.34, 0.0], [0.34, 0.08], [0.3, 0.12], [0.24, 0.16], [0.22, 0.4], [0.27, 0.46], [0.3, 0.5], [0.3, 0.56], [0.0, 0.56]]), 20, M("boiserie_prune"), true, true))
	b.add(StyleKit.torus(0.3, 0.025, M("or_vieilli"), 20, 6), ModuleBuilder.at(Vector3(0, 0.56, 0)))
	b.add(StyleKit.lathe(P([[0.0, 0.0], [0.15, 0.0], [0.19, 0.04], [0.31, 0.2], [0.35, 0.38], [0.3, 0.56], [0.17, 0.7], [0.12, 0.8], [0.13, 0.86], [0.19, 0.92], [0.21, 0.98]]), 22, M("pierre_sombre"), true, false), ModuleBuilder.at(Vector3(0, 0.58, 0)))
	b.add(StyleKit.torus(0.355, 0.02, M("or_vieilli"), 22, 6), ModuleBuilder.at(Vector3(0, 0.96, 0)))
	b.add(StyleKit.torus(0.21, 0.02, M("or_vieilli"), 22, 6), ModuleBuilder.at(Vector3(0, 1.56, 0)))
	b.add(StyleKit.torus(0.13, 0.018, M("or_vieilli"), 16, 6), ModuleBuilder.at(Vector3(0, 1.38, 0)))
	for sx in [-1.0, 1.0]:
		b.add(StyleKit.torus(0.13, 0.02, M("or_vieilli"), 14, 5), ModuleBuilder.at(Vector3(sx * 0.2, 1.3, 0), Vector3(90, 0, 0)))
	b.add(star_mesh(0.14, "or_vieilli", 0.03), ModuleBuilder.at(Vector3(0, 1.0, 0.345)))
	b.add(star_mesh(0.14, "or_vieilli", 0.03), ModuleBuilder.at(Vector3(0, 1.0, -0.345), Vector3(0, 180, 0)))
	# gerbe de fleurs séchées
	for i in 9:
		var a := TAU * i / 9.0
		var tilt := 14.0 + 12.0 * hash01(i, 2)
		var L := 0.55 + 0.25 * hash01(i, 3)
		b.add(StyleKit.cylinder(0.008, L, M("ecorce"), 5), ModuleBuilder.at(Vector3(cos(a) * 0.04, 1.54, sin(a) * 0.04), Vector3(cos(a) * tilt, 0, -sin(a) * tilt)))
		var tip := Vector3(cos(a) * 0.04 + sin(deg_to_rad(tilt)) * L * cos(a), 1.54 + L * cos(deg_to_rad(tilt)), sin(a) * 0.04 + sin(deg_to_rad(tilt)) * L * sin(a))
		b.add(StyleKit.sphere(0.05, M("fleur_lavande" if i % 3 != 0 else "fleur_rose"), 8, 4), ModuleBuilder.at(tip, Vector3.ZERO, Vector3(1, 1.3, 1)))
	b.collide(Vector3(0.7, 1.6, 0.7), Vector3(0, 0.8, 0))
	b.cast_shadows = false
	return b

## Fauteuil d'apparat du hall (velours, bois sombre, pieds tournés dorés). Face vers +z.
static func fauteuil_hall() -> ModuleBuilder:
	var b := ModuleBuilder.new("fauteuil_hall")
	b.box(Vector3(0.9, 0.2, 0.85), 0.09, "velours", Vector3(0, 0.5, 0), Vector3.ZERO, 2)
	b.box(Vector3(0.95, 0.1, 0.9), 0.04, "boiserie_prune", Vector3(0, 0.36, 0))
	b.box(Vector3(0.9, 0.85, 0.2), 0.09, "velours", Vector3(0, 0.95, -0.34), Vector3(-6, 0, 0), 2)
	b.box(Vector3(0.96, 0.1, 0.26), 0.04, "boiserie_prune", Vector3(0, 1.42, -0.36), Vector3(-6, 0, 0))
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.16, 0.2, 0.72), 0.07, "velours", Vector3(sx * 0.5, 0.75, 0.0), Vector3.ZERO, 2)
		b.add(StyleKit.lathe(P([[0.04, 0.0], [0.05, 0.12], [0.035, 0.28]]), 8, M("boiserie_prune"), true, true), ModuleBuilder.at(Vector3(sx * 0.5, 0.48, 0.25)))
		for sz in [-1.0, 1.0]:
			b.add(StyleKit.lathe(P([[0.04, 0.0], [0.06, 0.05], [0.04, 0.14], [0.065, 0.24], [0.04, 0.34]]), 10, M("boiserie_prune"), true, true), ModuleBuilder.at(Vector3(sx * 0.42, 0.0, sz * 0.37)))
			b.add(StyleKit.sphere(0.035, M("or_vieilli"), 8, 4), ModuleBuilder.at(Vector3(sx * 0.42, 0.1, sz * 0.37)))
	b.add(star_mesh(0.1, "or_vieilli", 0.03), ModuleBuilder.at(Vector3(0, 1.0, -0.23), Vector3(-6, 0, 0)))
	b.collide(Vector3(1.0, 0.95, 0.95), Vector3(0, 0.48, 0))
	b.cast_shadows = false
	return b

## Tapis en arc devant le comptoir (centre = centre du comptoir, comme `bureau_reception`).
static func tapis_hall() -> ModuleBuilder:
	var b := ModuleBuilder.new("tapis_hall")
	var r0 := 3.05
	var r1 := 4.35
	b.add(StyleAssets._arc_slab(r0, r1, 22.0, 158.0, 0.025, M("rideau_velours")), ModuleBuilder.at(Vector3(0, 0.002, 0)))
	b.add(StyleAssets._arc_slab(r0, r0 + 0.07, 22.0, 158.0, 0.03, M("or_vieilli")), ModuleBuilder.at(Vector3(0, 0.002, 0)))
	b.add(StyleAssets._arc_slab(r1 - 0.07, r1, 22.0, 158.0, 0.03, M("or_vieilli")), ModuleBuilder.at(Vector3(0, 0.002, 0)))
	b.add(StyleAssets._arc_slab(r0 + 0.16, r0 + 0.19, 24.0, 156.0, 0.03, M("or_vieilli")), ModuleBuilder.at(Vector3(0, 0.002, 0)))
	b.add(StyleAssets._arc_slab(r1 - 0.19, r1 - 0.16, 24.0, 156.0, 0.03, M("or_vieilli")), ModuleBuilder.at(Vector3(0, 0.002, 0)))
	var rm := (r0 + r1) * 0.5
	for i in 9:
		var a := deg_to_rad(30.0 + 15.0 * i)
		var p := Vector3(cos(a) * rm, 0.034, sin(a) * rm)
		if i % 2 == 0:
			b.add(star_mesh(0.18, "or_vieilli", 0.01), Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.RIGHT, -PI * 0.5), p))
		else:
			b.add(StyleKit.extrude(StyleKit.crescent_outline(0.15, 0.55), 0.01, M("or_vieilli"), 0.0), Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.RIGHT, -PI * 0.5), p))
	b.cast_shadows = false
	return b

# ================================================================== modules refaits (appelés par style_assets.gd)

## Tube conique entre deux points (révolution orientée), pour troncs, branches, chaînes, rameaux.
static func tube(b: ModuleBuilder, p0: Vector3, p1: Vector3, r0: float, r1: float, mat: Material, segs := 8, caps := false) -> void:
	var d := p1 - p0
	var len := d.length()
	if len < 0.0005:
		return
	var basis := Basis(Quaternion(Vector3.UP, d / len))
	b.add(StyleKit.lathe(P([[r0, 0.0], [r1, len]]), segs, mat, caps, caps), Transform3D(basis, p0))

static func _ball(b: ModuleBuilder, p: Vector3, r: float, mat: Material, segs := 7, rings := 4, squash := 1.0) -> void:
	var yaw := hash01(int(p.x * 997.0) + int(p.y * 389.0) * 31 + int(p.z * 613.0) * 17, 3) * TAU
	b.add(_unit_sphere(mat, segs, rings), Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(r, r * squash, r)), p))

static var _sph_cache := {}
static func _unit_sphere(mat: Material, segs: int, rings: int) -> ArrayMesh:
	var key := "%s_%d_%d" % [mat.resource_path, segs, rings]
	if not _sph_cache.has(key):
		_sph_cache[key] = StyleKit.sphere(1.0, mat, segs, rings)
	return _sph_cache[key]

## Colonne : plinthe, tore, fût galbé à cannelures douces, bague d'or, chapiteau évasé à bague d'or et motifs lune / étoile.
static func colonne(id: String, h: float) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	b.box(Vector3(1.0, 0.3, 1.0), 0.07, "pierre_sombre", Vector3(0, 0.15, 0))
	b.add(StyleKit.torus(0.4, 0.085, M("moulure_pierre"), 28, 8), ModuleBuilder.at(Vector3(0, 0.38, 0)))
	b.add(StyleKit.torus(0.36, 0.035, M(GOLD), 28, 6), ModuleBuilder.at(Vector3(0, 0.5, 0)))
	var top := h - 0.75
	var y0 := 0.55
	var prof := []
	var n := 7
	for i in n:
		var t := float(i) / (n - 1)
		var y := y0 + (top - y0) * t
		var r := 0.325 + 0.03 * sin(PI * minf(t * 1.25, 1.0)) - 0.035 * t
		prof.append([r, y])
	b.add(fluted_lathe(prof, 12, 0.075, 3, M("moulure_pierre")))
	b.add(StyleKit.torus(0.335, 0.03, M(GOLD), 28, 6), ModuleBuilder.at(Vector3(0, y0 + 0.02, 0)))
	b.add(StyleKit.torus(0.3, 0.05, M(GOLD), 28, 6), ModuleBuilder.at(Vector3(0, top + 0.04, 0)))
	b.add(StyleKit.lathe(P([[0.3, top], [0.33, top + 0.07], [0.4, top + 0.22], [0.49, top + 0.4], [0.52, top + 0.5]]), 24, M("moulure_pierre"), false, true))
	b.add(StyleKit.torus(0.405, 0.032, M(GOLD), 28, 6), ModuleBuilder.at(Vector3(0, top + 0.22, 0)))
	for i in 4:
		var a := PI * 0.5 * i
		var r := 0.47
		var basis := Basis(Vector3.UP, -a + PI * 0.5)
		var p := Vector3(cos(a) * r, top + 0.34, sin(a) * r)
		var shape: ArrayMesh = _small_crescent() if i % 2 == 0 else star_mesh(0.075, "or_vieilli", 0.025)
		b.add(shape, Transform3D(basis * Basis(Vector3.BACK, PI * 0.5 if i % 2 == 0 else 0.0), p))
	b.box(Vector3(1.1, 0.2, 1.1), 0.05, "moulure_pierre", Vector3(0, h - 0.1, 0))
	b.box(Vector3(1.14, 0.04, 1.14), 0.015, GOLD, Vector3(0, h - 0.24, 0), Vector3.ZERO, 1)
	b.collide(Vector3(0.8, h, 0.8), Vector3(0, h * 0.5, 0))
	return b

static func pilastre(id: String, h: float) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	for p in pilaster_parts(h, 1.25, 0.9):
		b.add(p[0], p[1])
	b.collide(Vector3(0.9, h, 0.45), Vector3(0, h * 0.5, 0.2))
	return b

## Arcade entre deux colonnes espacées de 6 m : archivolte moulurée à trois bandes, filets d'or, clé de voûte en étoile.
static func arcade() -> ModuleBuilder:
	var b := ModuleBuilder.new("arcade")
	var H := 5.0
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(5.0, H, 0.2, 22), 0.62, M("moulure_pierre"), 0.045))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(5.0 + 0.4, H + 0.2, 0.2, 22), 0.5, M("moulure_pierre"), 0.04))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(5.0, H, 0.045, 22), 0.7, M("or_vieilli"), 0.0))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(5.0 + 0.4, H + 0.2, 0.04, 22), 0.64, M("or_vieilli"), 0.0))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(5.0 + 0.8, H + 0.4, 0.04, 22), 0.52, M("or_vieilli"), 0.0))
	var top := H + 0.0
	# clé de voûte (trapèze) et étoile
	b.add(StyleKit.extrude(P([[-0.2, top - 0.2], [0.2, top - 0.2], [0.3, top + 0.5], [-0.3, top + 0.5]]), 0.78, M("moulure_pierre"), 0.035))
	b.add(star_mesh(0.14, "or_vieilli", 0.04), ModuleBuilder.at(Vector3(0, top + 0.16, 0.4)))
	b.add(star_mesh(0.14, "or_vieilli", 0.04), ModuleBuilder.at(Vector3(0, top + 0.16, -0.4)))
	# cabochons dorés le long de l'archivolte
	var cab := StyleKit.sphere(0.035, M("or_vieilli"), 6, 3)
	for i in 9:
		var a := PI * (i + 1.0) / 10.0
		var R := 2.5 + 0.1
		var c := Vector3(cos(a) * R, 2.5 + sin(a) * R, 0.33)
		b.add(cab, Transform3D(Basis.IDENTITY, c))
		b.add(cab, Transform3D(Basis.IDENTITY, Vector3(c.x, c.y, -0.33)))
	return b

## Balustrade : socle mouluré, balustres ventrus tournés, main courante dorée arrondie. Longueur L le long de x, hauteur 1,0 m.
static func balustrade(id: String, L: float) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	b.box(Vector3(L, 0.14, 0.34), 0.05, "moulure_pierre", Vector3(0, 0.07, 0))
	b.box(Vector3(L, 0.04, 0.38), 0.015, GOLD, Vector3(0, 0.155, 0), Vector3.ZERO, 1)
	b.box(Vector3(L, 0.13, 0.27), 0.06, GOLD, Vector3(0, 0.975, 0), Vector3.ZERO, 3)
	b.box(Vector3(L, 0.06, 0.2), 0.025, "moulure_pierre", Vector3(0, 0.88, 0), Vector3.ZERO, 1)
	var bal := StyleKit.lathe(P([[0.06, 0.0], [0.08, 0.035], [0.055, 0.08], [0.055, 0.13], [0.09, 0.22], [0.12, 0.34], [0.105, 0.45], [0.07, 0.57], [0.055, 0.63], [0.07, 0.69], [0.06, 0.72]]), 9, M("moulure_pierre"), false, false)
	var n := int(round(L / 0.34))
	for i in n:
		var x := -L * 0.5 + (i + 0.5) * L / n
		b.add(bal, ModuleBuilder.at(Vector3(x, 0.17, 0)))
	b.collide(Vector3(L, 1.1, 0.3), Vector3(0, 0.55, 0))
	return b

## Grande fenêtre en arche (adossée à z = 0) : paysage peint par shader, archivolte à deux bandes, clé de voûte étoilée,
## meneaux et rayons dorés, appui sur consoles.
static func fenetre(id: String, w: float, h: float, vista: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	b.add(StyleAssets._arch_plane(w, h, 20, M(vista)), ModuleBuilder.at(Vector3(0, 0, 0.03)))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(w, h, 0.28, 24), 0.5, M("moulure_pierre"), 0.06), ModuleBuilder.at(Vector3(0, 0, 0.25)))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(w + 0.56, h + 0.28, 0.2, 24), 0.4, M("moulure_pierre"), 0.04), ModuleBuilder.at(Vector3(0, 0, 0.2)))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(w + 0.96, h + 0.48, 0.06, 24), 0.44, M("or_vieilli"), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.2)))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(w, h, 0.05, 24), 0.56, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.25)))
	var spring := h - w * 0.5
	var bar := 0.07
	for x in [-w / 6.0, w / 6.0]:
		b.box(Vector3(bar, spring, bar), 0.02, GOLD, Vector3(x * 1.5, spring * 0.5, 0.12), Vector3.ZERO, 1)
	var rows := int(spring / 1.6)
	for i in range(1, rows + 1):
		var y := spring * float(i) / (rows + 1)
		b.box(Vector3(w, bar, bar), 0.02, GOLD, Vector3(0, y, 0.12), Vector3.ZERO, 1)
	b.box(Vector3(w, bar, bar), 0.02, GOLD, Vector3(0, spring, 0.12), Vector3.ZERO, 1)
	for i in 5:
		var a := 30.0 * (i + 1)
		b.add(StyleKit.rounded_box(Vector3(w * 0.5, bar, bar), 0.02, M(GOLD), 1), Transform3D(Basis(Vector3.BACK, deg_to_rad(a)), Vector3(0, spring, 0.12)) * Transform3D(Basis.IDENTITY, Vector3(w * 0.25, 0, 0)))
	b.add(StyleKit.torus(w * 0.18, 0.04, M(GOLD), 24, 6), ModuleBuilder.at(Vector3(0, spring, 0.12), Vector3(90, 0, 0)))
	# clé de voûte étoilée au sommet
	var top := h + 0.48
	b.add(StyleKit.extrude(P([[-0.28, top - 0.55], [0.28, top - 0.55], [0.4, top + 0.35], [-0.4, top + 0.35]]), 0.5, M("moulure_pierre"), 0.04), ModuleBuilder.at(Vector3(0, 0, 0.28)))
	b.add(star_mesh(0.2, "or_vieilli", 0.04), ModuleBuilder.at(Vector3(0, top - 0.1, 0.55)))
	# appui mouluré sur consoles
	b.box(Vector3(w + 0.8, 0.2, 0.6), 0.06, "moulure_pierre", Vector3(0, -0.06, 0.3))
	b.box(Vector3(w + 0.9, 0.05, 0.64), 0.02, "or_vieilli", Vector3(0, 0.07, 0.3), Vector3.ZERO, 1)
	var console := StyleKit.extrude(P(CONSOLE), 0.24, M("moulure_pierre"), 0.03)
	for sx in [-1.0, 1.0]:
		b.add(console, Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(sx * (w * 0.5 + 0.05), -0.15, 0.0)))
	return b

## Lustre astronomique : cœur lunaire réduit dans une cage armillaire, anneaux d'orfèvrerie, chaînes, bougies-lampes,
## pendeloques d'étoiles et trois anneaux de planètes animés. Origine = attache au plafond.
static func lustre() -> ModuleBuilder:
	var b := ModuleBuilder.new("lustre_astronomique")
	var cy := -6.5
	var gold := M(GOLD)
	var old := M("or_vieilli")
	# chaînes de suspension (maillons)
	for i in 3:
		var a := deg_to_rad(120.0 * i + 30.0)
		var top := Vector3(cos(a) * 1.6, 0, sin(a) * 1.6)
		var bot := Vector3(cos(a) * 2.7, cy + 0.2, sin(a) * 2.7)
		var d := bot - top
		var nlinks := 12
		for k in nlinks:
			var t := (k + 0.5) / nlinks
			var p := top + d * t
			var basis := Basis(Quaternion(Vector3.UP, d.normalized())) * Basis(Vector3.UP, k * PI * 0.5)
			b.add(StyleKit.torus(0.05, 0.011, old, 6, 3), Transform3D(basis * Basis(Vector3.RIGHT, PI * 0.5), p))
		b.add(StyleKit.sphere(0.06, gold, 8, 4), Transform3D(Basis.IDENTITY, bot))
	b.add(StyleKit.cylinder(0.03, -cy - 0.9, gold, 8), ModuleBuilder.at(Vector3(0, cy + 0.9, 0)))
	b.add(StyleKit.lathe(P([[0.0, -0.1], [0.5, 0.0], [0.25, 0.25], [0.0, 0.3]]), 24, gold, false, false), ModuleBuilder.at(Vector3.ZERO))
	b.add(StyleKit.torus(0.42, 0.04, gold, 28, 6), ModuleBuilder.at(Vector3(0, -0.35, 0)))
	# cœur lunaire (petit) dans une cage armillaire
	b.add(StyleKit.sphere(0.5, M("lune"), 24, 12), ModuleBuilder.at(Vector3(0, cy, 0)))
	for rot in [Vector3(0, 0, 0), Vector3(90, 0, 0), Vector3(90, 60, 0), Vector3(90, 120, 0)]:
		b.add(StyleKit.torus(0.66, 0.022, gold, 28, 4), ModuleBuilder.at(Vector3(0, cy, 0), rot))
	b.add(StyleKit.torus(1.0, 0.045, gold, 40, 8), ModuleBuilder.at(Vector3(0, cy, 0)))
	b.add(StyleKit.torus(1.0, 0.012, old, 40, 4), ModuleBuilder.at(Vector3(0, cy + 0.07, 0)))
	# anneau extérieur : double filet, perles, bougies-lampes
	b.add(StyleKit.torus(2.8, 0.06, gold, 56, 6), ModuleBuilder.at(Vector3(0, cy + 0.2, 0)))
	b.add(StyleKit.torus(2.8, 0.02, old, 56, 3), ModuleBuilder.at(Vector3(0, cy + 0.32, 0)))
	b.add(StyleKit.torus(2.62, 0.03, old, 48, 4), ModuleBuilder.at(Vector3(0, cy + 0.12, 0)))
	var pearl := StyleKit.sphere(0.04, old, 5, 3)
	for i in 24:
		var a := TAU * i / 24.0
		b.add(pearl, Transform3D(Basis.IDENTITY, Vector3(cos(a) * 2.8, cy + 0.2 + 0.075, sin(a) * 2.8)))
	for i in 12:
		var a := TAU * (i + 0.5) / 12.0
		var p := Vector3(cos(a) * 2.8, cy + 0.2, sin(a) * 2.8)
		b.add(StyleKit.lathe(P([[0.0, 0.0], [0.06, 0.0], [0.09, 0.05], [0.12, 0.1], [0.06, 0.11]]), 6, gold, false, false), Transform3D(Basis.IDENTITY, p + Vector3(0, 0.06, 0)))
		b.add(StyleKit.cylinder(0.026, 0.14, M("draps"), 5), Transform3D(Basis.IDENTITY, p + Vector3(0, 0.17, 0)))
		b.add(StyleKit.sphere(0.034, M("abat_jour"), 5, 3), Transform3D(Basis.IDENTITY.scaled(Vector3(1, 1.5, 1)), p + Vector3(0, 0.36, 0)))
	# bras galbés : de l'anneau intérieur à l'anneau extérieur (polylignes)
	for i in 6:
		var a := TAU * i / 6.0
		var prev := Vector3(cos(a) * 1.0, cy, sin(a) * 1.0)
		for k in range(1, 9):
			var t := float(k) / 8.0
			var rr := 1.0 + 1.8 * t
			var yy := cy + 0.2 * t - 0.28 * sin(PI * t)
			var aa := a + 0.35 * sin(PI * t)
			var p := Vector3(cos(aa) * rr, yy, sin(aa) * rr)
			tube(b, prev, p, 0.028 - 0.008 * t, 0.028 - 0.008 * t, old, 5)
			prev = p
		b.add(star_mesh(0.12, "etoile_or", 0.03), Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * 1.9, cy - 0.12, sin(a) * 1.9)))
	# pendeloques : étoiles suspendues à l'anneau extérieur
	for i in 12:
		var a := TAU * i / 12.0
		var p := Vector3(cos(a) * 2.8, cy + 0.2, sin(a) * 2.8)
		var drop := 0.5 + 0.35 * float(i % 3)
		b.add(StyleKit.cylinder(0.008, drop, gold, 4), ModuleBuilder.at(p - Vector3(0, drop, 0)))
		b.add(star_mesh(0.14, "etoile_or", 0.04), Transform3D(Basis(Vector3.UP, a + PI * 0.5), p - Vector3(0, drop + 0.12, 0)))
		b.add(pearl, Transform3D(Basis.IDENTITY, p - Vector3(0, 0.04, 0)))
	# anneaux animés (nœuds séparés)
	var specs := [[2.0, Vector3(70, 0, 15), 5.0, "AnneauA"], [1.55, Vector3(-60, 30, 0), -7.0, "AnneauB"], [2.35, Vector3(20, 0, -75), 3.5, "AnneauC"]]
	for s in specs:
		var R: float = s[0]
		var ring := Node3D.new()
		ring.name = s[3]
		ring.position = Vector3(0, cy, 0)
		ring.rotation_degrees = s[1]
		ring.set_script(load("res://scripts/stylized/rotator.gd"))
		ring.set("axis", Vector3.UP)
		ring.set("degrees_per_second", s[2])
		var rb := ModuleBuilder.new("tmp")
		rb.add(StyleKit.torus(R, 0.035, gold, 44, 5))
		rb.add(StyleKit.torus(R, 0.012, old, 44, 3), ModuleBuilder.at(Vector3(0, 0.05, 0)))
		rb.add(StyleKit.sphere(0.2, M("velours"), 16, 8), ModuleBuilder.at(Vector3(R, 0, 0)))
		rb.add(StyleKit.torus(0.3, 0.02, gold, 20, 4), ModuleBuilder.at(Vector3(R, 0, 0), Vector3(20, 0, 10)))
		rb.add(StyleKit.sphere(0.13, M("lune"), 14, 7), ModuleBuilder.at(Vector3(-R, 0, 0)))
		rb.add(StyleKit.sphere(0.09, gold, 12, 6), ModuleBuilder.at(Vector3(0, 0, R)))
		for k in 6:
			var a := TAU * (k + 0.5) / 6.0 + 0.2
			rb.add(star_mesh(0.07, "etoile_or", 0.02), ModuleBuilder.at(Vector3(cos(a) * R, 0.0, sin(a) * R), Vector3(90, 0, 0)))
		var mi := MeshInstance3D.new()
		mi.name = "Maillage" + String(s[3])
		mi.mesh = StyleKit.merge(rb.parts)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.add_child(mi)
		b.extras.append(ring)
	b.omni(Vector3(0, cy, 0), Color("#ffcf96"), 3.2, 26.0, true, "LumiereLune")
	b.omni(Vector3(0, cy - 2.5, 0), Color("#c8b0ff"), 1.0, 12.0, false, "LueurBasse")
	b.cast_shadows = false
	return b

## Horloge céleste murale (Ø 5,6 m), adossée à z = 0 : cadre profond à gradins, cadran étoilé, rayons dorés, chiffres
## romains, anneau des constellations tournant, cadran des phases de lune, aiguilles (heure réelle). Centre à l'origine.
static func horloge() -> ModuleBuilder:
	var b := ModuleBuilder.new("horloge_celeste")
	var gold := M(GOLD)
	var old := M("or_vieilli")
	# cadre profond : trois gradins, torique doré, cabochons
	b.add(StyleKit.extrude(StyleAssets._circle(3.35, 64), 0.2, M("moulure_pierre"), 0.05), ModuleBuilder.at(Vector3(0, 0, 0.1)))
	b.add(StyleKit.extrude(StyleAssets._ring(3.15, 2.85, 64), 0.5, M("moulure_pierre"), 0.07), ModuleBuilder.at(Vector3(0, 0, 0.25)))
	b.add(StyleKit.extrude(StyleAssets._ring(3.0, 2.95, 64), 0.56, old, 0.0), ModuleBuilder.at(Vector3(0, 0, 0.25)))
	b.add(StyleKit.extrude(StyleAssets._ring(2.82, 2.55, 64), 0.4, gold, 0.03), ModuleBuilder.at(Vector3(0, 0, 0.22)))
	b.add(StyleKit.extrude(StyleAssets._circle(2.56, 64), 0.3, M("pierre_sombre"), 0.04), ModuleBuilder.at(Vector3(0, 0, 0.15)))
	b.add(StyleKit.extrude(StyleAssets._ring(1.9, 1.84, 48), 0.27, gold, 0.0), ModuleBuilder.at(Vector3(0, 0, 0.14)))
	b.add(StyleKit.extrude(StyleAssets._circle(2.52, 64), 0.02, M("voute_etoilee"), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.3)))
	var cab := StyleKit.sphere(0.07, old, 8, 4)
	for i in 24:
		var a := TAU * i / 24.0
		b.add(cab, Transform3D(Basis.IDENTITY, Vector3(cos(a) * 3.075, sin(a) * 3.075, 0.56)))
	# rayons dorés (soleil) autour du moyeu, sous l'anneau tournant
	var ray := StyleKit.extrude(P([[0.0, 0.2], [0.07, 0.55], [0.0, 1.38], [-0.07, 0.55]]), 0.015, gold, 0.0)
	for i in 16:
		b.add(ray, Transform3D(Basis(Vector3.BACK, TAU * i / 16.0), Vector3(0, 0, 0.32)))
	var numerals := ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
	for i in 12:
		var a := PI * 0.5 - TAU * i / 12.0
		var lb := b.label(numerals[i], Vector3(cos(a) * 2.2, sin(a) * 2.2, 0.34), 120, Color("#ffd27a"), Vector3.ZERO, 0.004)
		lb.outline_size = 8
		lb.outline_modulate = Color("#5a3a10")
		b.add(star_mesh(0.07, "etoile_or", 0.03), ModuleBuilder.at(Vector3(cos(a + PI / 12.0) * 2.67, sin(a + PI / 12.0) * 2.67, 0.36)))
	# cadran des phases de lune (sous le moyeu)
	var pc := Vector3(0, -1.0, 0.33)
	b.add(StyleKit.extrude(StyleAssets._circle(0.6, 32), 0.03, M("pierre_sombre"), 0.0), Transform3D(Basis.IDENTITY, pc))
	b.add(StyleKit.extrude(StyleAssets._ring(0.62, 0.57, 32), 0.05, gold, 0.0), Transform3D(Basis.IDENTITY, pc))
	for i in 8:
		var a := TAU * i / 8.0 + PI * 0.5
		var c := pc + Vector3(cos(a) * 0.43, sin(a) * 0.43, 0.02)
		var ph := float(i) / 8.0
		b.add(StyleKit.extrude(StyleAssets._circle(0.07, 12), 0.015, M("lune"), 0.0), Transform3D(Basis.IDENTITY, c))
		# ombre : disque sombre décalé selon la phase (pleine lune en haut, nouvelle lune en bas)
		var off := (ph - 0.0) * 2.0
		var shade := clampf(off if off <= 1.0 else 2.0 - off, 0.0, 1.0)
		if shade > 0.05:
			b.add(StyleKit.extrude(StyleAssets._circle(0.065, 12), 0.016, M("pierre_sombre"), 0.0), Transform3D(Basis.IDENTITY, c + Vector3((0.1 * shade) * (1.0 if ph < 0.5 else -1.0), 0, 0.006)))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.2, 0.55, 14), 0.03, M("lune"), 0.0), Transform3D(Basis.IDENTITY, pc + Vector3(-0.04, 0, 0.02)))
	b.add(star_mesh(0.07, "etoile_or", 0.03), Transform3D(Basis.IDENTITY, pc + Vector3(0.12, 0.05, 0.03)))
	# couronnement : croissant et étoile
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.46, 0.55), 0.08, gold, 0.015), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.0, 3.6, 0.2)))
	b.add(star_mesh(0.2, "etoile_or", 0.06), Transform3D(Basis.IDENTITY, Vector3(0, 3.95, 0.2)))
	# anneau tournant : croissant et étoiles
	var ring := Node3D.new()
	ring.name = "Anneau"
	ring.position = Vector3(0, 0, 0.35)
	var rb := ModuleBuilder.new("tmp")
	rb.add(StyleKit.extrude(StyleAssets._ring(1.5, 1.46, 40), 0.02, gold, 0.0))
	rb.add(StyleKit.extrude(StyleKit.crescent_outline(0.32, 0.55), 0.03, M("lune"), 0.0), ModuleBuilder.at(Vector3(0, 1.1, 0)))
	for i in 7:
		var a := TAU * (i + 0.5) / 7.0
		rb.add(StyleKit.extrude(StyleKit.star_outline(0.1, 0.04, 5), 0.03, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(cos(a) * 1.1, sin(a) * 1.1, 0)))
	var rmi := MeshInstance3D.new()
	rmi.name = "MaillageAnneau"
	rmi.mesh = StyleKit.merge(rb.parts)
	ring.add_child(rmi)
	b.extras.append(ring)
	for hand in [["Heures", 1.3, 0.12], ["Minutes", 1.95, 0.08]]:
		var pv := Node3D.new()
		pv.name = hand[0]
		pv.position = Vector3(0, 0, 0.45 if hand[0] == "Minutes" else 0.41)
		var hb := ModuleBuilder.new("tmp")
		var L: float = hand[1]
		var wdt: float = hand[2]
		hb.add(StyleKit.extrude(P([[-wdt * 0.5, -0.25], [wdt * 0.5, -0.25], [wdt * 0.3, L - 0.25], [0, L], [-wdt * 0.3, L - 0.25]]), 0.03, gold, 0.0))
		hb.add(StyleKit.extrude(StyleKit.star_outline(0.12, 0.05, 4), 0.03, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(0, L * 0.7, 0.02)))
		var hmi := MeshInstance3D.new()
		hmi.name = "Maillage" + String(hand[0])
		hmi.mesh = StyleKit.merge(hb.parts)
		pv.add_child(hmi)
		b.extras.append(pv)
	b.add(StyleKit.sphere(0.16, gold, 16, 8), ModuleBuilder.at(Vector3(0, 0, 0.5)))
	b.script_path = "res://scripts/stylized/celestial_clock.gd"
	b.omni(Vector3(0, -0.5, 2.5), Color("#ffd29a"), 1.2, 7.0, false, "Eclairage")
	return b

## Comptoir de réception en arc (convexe vers +Z) : corps de bois à panneaux moulurés entre balustres tournés, plateau de
## marbre à veines crème, lampes à abat-jour, sphère armillaire, cloche, registre ouvert, encrier et plume.
static func reception() -> ModuleBuilder:
	var b := ModuleBuilder.new("bureau_reception")
	var R0 := 2.1
	var R1 := 2.75
	var a0 := 25.0
	var a1 := 155.0
	b.add(StyleAssets._arc_slab(R0, R1, a0, a1, 1.0, M("boiserie_prune")), ModuleBuilder.at(Vector3(0, 0.12, 0)))
	b.add(StyleAssets._arc_slab(R0 - 0.05, R1 + 0.1, a0 - 1.0, a1 + 1.0, 0.13, M("pierre_sombre")), ModuleBuilder.at(Vector3(0, 0, 0)))
	b.add(StyleAssets._arc_slab(R1 + 0.1, R1 + 0.14, a0 - 1.0, a1 + 1.0, 0.04, M(GOLD)), ModuleBuilder.at(Vector3(0, 0.13, 0)))
	b.add(StyleAssets._arc_slab(R0 - 0.1, R1 + 0.17, a0 - 2.0, a1 + 2.0, 0.1, M("marbre_comptoir")), ModuleBuilder.at(Vector3(0, 1.12, 0)))
	b.add(StyleAssets._arc_slab(R1 + 0.15, R1 + 0.19, a0 - 2.0, a1 + 2.0, 0.035, M(GOLD)), ModuleBuilder.at(Vector3(0, 1.1, 0)))
	b.add(StyleAssets._arc_slab(R1 - 0.01, R1 + 0.04, a0, a1, 0.05, M("or_vieilli")), ModuleBuilder.at(Vector3(0, 0.98, 0)))
	b.add(StyleAssets._arc_slab(R1 - 0.01, R1 + 0.04, a0, a1, 0.04, M("or_vieilli")), ModuleBuilder.at(Vector3(0, 0.22, 0)))
	# panneaux moulurés entre balustres tournés
	var n := 8
	var post := StyleKit.lathe(P([[0.075, 0.0], [0.085, 0.05], [0.055, 0.1], [0.06, 0.2], [0.085, 0.4], [0.07, 0.6], [0.095, 0.82], [0.075, 0.88]]), 10, M("boiserie_prune"), false, true)
	for k in n + 1:
		var a := deg_to_rad(a0 + (a1 - a0) * k / n)
		b.add(post, Transform3D(Basis.IDENTITY, Vector3(cos(a) * (R1 + 0.035), 0.19, sin(a) * (R1 + 0.035))))
		b.add(StyleKit.sphere(0.04, M("or_vieilli"), 8, 4), Transform3D(Basis.IDENTITY, Vector3(cos(a) * (R1 + 0.035), 1.1, sin(a) * (R1 + 0.035))))
	for k in n:
		var a := deg_to_rad(a0 + (a1 - a0) * (k + 0.5) / n)
		var xf := Transform3D(Basis(Vector3.UP, PI * 0.5 - a), Vector3(cos(a) * (R1 + 0.0), 0.62, sin(a) * (R1 + 0.0)))
		var hw := 2.0 * R1 * sin(deg_to_rad((a1 - a0) / n) * 0.5) * 0.5 - 0.13
		b.add(frame_sweep(hw, 0.3, PROF_PANEL, M("boiserie_prune")), xf)
		b.add(frame_sweep(hw - 0.06, 0.24, [[0.02, 0.03], [0.02, 0.05], [0.0, 0.05]], M("or_vieilli")), xf)
		var shape: ArrayMesh = star_mesh(0.11, "etoile_or", 0.025) if k % 2 == 1 else StyleKit.extrude(StyleKit.crescent_outline(0.1, 0.55, 12), 0.025, M("etoile_or"), 0.0)
		b.add(shape, xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.04)))
	# lampes à abat-jour
	for ang in [40.0, 140.0]:
		var a := deg_to_rad(ang)
		var p := Vector3(cos(a) * 2.42, 1.22, sin(a) * 2.42)
		b.add(StyleKit.lathe(P([[0.12, 0.0], [0.1, 0.04], [0.025, 0.1], [0.025, 0.45], [0.05, 0.48]]), 12, M(GOLD), true, true), ModuleBuilder.at(p))
		b.add(StyleKit.torus(0.07, 0.015, M("or_vieilli"), 12, 4), ModuleBuilder.at(p + Vector3(0, 0.2, 0)))
		b.add(StyleKit.lathe(P([[0.24, 0.42], [0.16, 0.66], [0.15, 0.68]]), 18, M("abat_jour"), true, true), ModuleBuilder.at(p))
		b.add(StyleKit.torus(0.24, 0.012, M("or_vieilli"), 18, 4), ModuleBuilder.at(p + Vector3(0, 0.42, 0)))
		b.omni(p + Vector3(0, 0.5, 0), Color("#ffbf7a"), 1.3, 5.0, false)
	# sphère armillaire au centre
	var c := Vector3(0, 1.22, 2.42)
	b.add(StyleKit.lathe(P([[0.16, 0.0], [0.12, 0.05], [0.04, 0.12], [0.03, 0.3]]), 12, M(GOLD)), ModuleBuilder.at(c))
	for rot in [Vector3(0, 0, 0), Vector3(90, 0, 0), Vector3(90, 60, 0), Vector3(23, 0, 0)]:
		b.add(StyleKit.torus(0.26, 0.012, M(GOLD), 28, 4), ModuleBuilder.at(c + Vector3(0, 0.56, 0), rot))
	b.add(StyleKit.sphere(0.06, M("abat_jour"), 12, 6), ModuleBuilder.at(c + Vector3(0, 0.56, 0)))
	# cloche
	var bp := Vector3(cos(deg_to_rad(65)) * 2.42, 1.22, sin(deg_to_rad(65)) * 2.42)
	b.add(StyleKit.cylinder(0.1, 0.02, M("or_vieilli"), 14), ModuleBuilder.at(bp))
	b.add(StyleKit.lathe(P([[0.075, 0.02], [0.07, 0.05], [0.05, 0.1], [0.02, 0.14], [0.0, 0.15]]), 14, M(GOLD), false, false), ModuleBuilder.at(bp))
	b.add(StyleKit.sphere(0.018, M(GOLD), 6, 3), ModuleBuilder.at(bp + Vector3(0, 0.16, 0)))
	# registre ouvert, encrier et plume
	var rp := Vector3(cos(deg_to_rad(112)) * 2.4, 1.22, sin(deg_to_rad(112)) * 2.4)
	var ry := Vector3(0, -22, 0)
	b.box(Vector3(0.56, 0.035, 0.4), 0.012, "livre_a", rp + Vector3(0, 0.02, 0), ry, 1)
	for sx in [-1.0, 1.0]:
		var pg := Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(-22.0), deg_to_rad(-4.0 * sx))), rp + Basis.from_euler(Vector3(0, deg_to_rad(-22.0), 0)) * Vector3(sx * 0.13, 0.055, 0))
		b.add(fbox(Vector3(0.24, 0.016, 0.34), M("draps")), pg)
		for l in 4:
			b.add(fbox(Vector3(0.17, 0.002, 0.012), M("livre_b")), pg * Transform3D(Basis.IDENTITY, Vector3(0, 0.009, -0.1 + l * 0.06)))
	b.add(fbox(Vector3(0.012, 0.004, 0.36), M("or_vieilli")), Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(-22.0), 0)), rp + Vector3(0, 0.07, 0)))
	var ip := Vector3(cos(deg_to_rad(128)) * 2.38, 1.22, sin(deg_to_rad(128)) * 2.38)
	b.add(StyleKit.lathe(P([[0.06, 0.0], [0.07, 0.03], [0.055, 0.07], [0.03, 0.085]]), 12, M(GOLD), true, true), ModuleBuilder.at(ip))
	tube(b, ip + Vector3(0, 0.07, 0), ip + Vector3(0.1, 0.34, 0.07), 0.006, 0.003, M("draps"), 5)
	b.add(StyleKit.extrude(P([[0.0, 0.0], [0.03, 0.08], [0.0, 0.26], [-0.03, 0.08]]), 0.004, M("draps"), 0.0), Transform3D(Basis(Vector3.UP, 0.0) * Basis.from_euler(Vector3(0.1, 0, -0.3)), ip + Vector3(0.05, 0.2, 0.04)))
	for ang in [30.0, 55.0, 80.0, 100.0, 125.0, 150.0]:
		var a := deg_to_rad(ang)
		b.collide(Vector3(0.9, 1.25, 0.7), Vector3(cos(a) * 2.42, 0.62, sin(a) * 2.42), Vector3(0, -ang + 90.0, 0))
	return b

## Grand escalier droit (largeur 3 m, 24 marches de 25 cm : 6 m de haut, 8,4 m de long), montant vers -Z. Contremarches
## sombres, tapis de velours à tringles d'or, limons moulurés, balustres ventrus, poteaux à globes lumineux. La rampe de
## collision et la géométrie des marches sont inchangées.
static func escalier() -> ModuleBuilder:
	var b := ModuleBuilder.new("escalier_grand")
	var steps := 24
	var rise := 0.25
	var run := 0.35
	var w := 3.0
	var step := StyleKit.rounded_box(Vector3(w, rise + 0.02, run + 0.04), 0.035, M("pierre_claire"), 1)
	for i in steps:
		b.add(step, Transform3D(Basis.IDENTITY, Vector3(0, rise * (i + 0.5), -run * (i + 0.5))))
	var H := rise * steps
	var Lz := run * steps
	var slope := sqrt(H * H + Lz * Lz)
	var ang := rad_to_deg(atan2(H, Lz))
	var ucen := Vector3(0, H * 0.5 - 0.18, -Lz * 0.5 + 0.08)
	b.add(StyleKit.rounded_box(Vector3(w * 0.98, 0.25, slope), 0.04, M("pierre_sombre"), 1), ModuleBuilder.at(ucen, Vector3(ang, 0, 0)))
	# sous-face à caissons dorés
	var sd := Vector3(0, sin(deg_to_rad(ang)), -cos(deg_to_rad(ang)))
	var nn := Vector3(0, cos(deg_to_rad(ang)), sin(deg_to_rad(ang)))
	var ub := Basis(Vector3(-1, 0, 0), sd, -nn)
	for k in 7:
		var off := (k - 3) * (slope / 7.0)
		var uc := ucen - nn * 0.127 + sd * off
		var hh := slope / 14.0 - 0.14
		b.add(frame_sweep(1.15, hh, PROF_COFFER, M("moulure_pierre")), Transform3D(ub, uc))
		b.add(frame_sweep(1.15, hh, [[0.035, 0.07], [0.035, 0.095], [0.0, 0.095]], M("or_vieilli")), Transform3D(ub, uc))
	# contremarches sombres, tapis (marche et contremarche) et tringles d'or
	var riser := fbox(Vector3(w - 0.08, rise - 0.045, 0.03), M("pierre_sombre"))
	var c_tread := fbox(Vector3(1.7, 0.022, run + 0.03), M("rideau_velours"))
	var c_riser := fbox(Vector3(1.7, rise + 0.012, 0.022), M("rideau_velours"))
	var rod := StyleKit.cylinder(0.014, 1.82, M("or_vieilli"), 6)
	for i in steps:
		b.add(riser, Transform3D(Basis.IDENTITY, Vector3(0, rise * (i + 0.5), -run * i + 0.03)))
		b.add(c_tread, Transform3D(Basis.IDENTITY, Vector3(0, rise * (i + 1) + 0.021, -run * (i + 0.5))))
		b.add(c_riser, Transform3D(Basis.IDENTITY, Vector3(0, rise * (i + 0.5) + 0.02, -run * i + 0.052)))
		b.add(rod, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.91, rise * i + 0.055, -run * i + 0.07)))
	var bal := StyleKit.lathe(P([[0.05, 0.0], [0.065, 0.04], [0.048, 0.1], [0.085, 0.2], [0.105, 0.32], [0.085, 0.45], [0.055, 0.57], [0.065, 0.66], [0.05, 0.72]]), 7, M("moulure_pierre"), false, false)
	var post := StyleKit.lathe(P([[0.17, 0.0], [0.17, 0.12], [0.12, 0.24], [0.13, 0.32], [0.1, 0.4], [0.115, 0.9], [0.15, 1.0], [0.15, 1.1], [0.12, 1.16]]), 12, M("moulure_pierre"))
	var nrm := Vector3(0, cos(deg_to_rad(ang)), sin(deg_to_rad(ang)))
	for side in [-1.0, 1.0]:
		var x: float = side * (w * 0.5 + 0.12)
		var c0 := Vector3(x, H * 0.5 + 0.05, -Lz * 0.5)
		var rot := Vector3(ang, 0, 0)
		b.box(Vector3(0.26, 0.5, slope + 0.2), 0.06, "enduit_panneau", c0, rot)
		for fy in [-0.22, 0.2]:
			b.add(fbox(Vector3(0.012, 0.022, slope + 0.2), M("or_vieilli")), ModuleBuilder.at(c0 + nrm * fy + Vector3(side * 0.134, 0, 0), rot))
		b.add(StyleKit.rounded_box(Vector3(0.32, 0.07, slope + 0.2), 0.03, M("moulure_pierre"), 1), ModuleBuilder.at(c0 + nrm * 0.285, rot))
		b.add(fbox(Vector3(0.1, 0.02, slope + 0.2), M("or_vieilli")), ModuleBuilder.at(c0 + nrm * 0.325, rot))
		b.box(Vector3(0.17, 0.11, slope + 0.2), 0.05, GOLD, Vector3(x, H * 0.5 + 1.05, -Lz * 0.5), rot, 3)
		# panneaux moulurés sur la face extérieure du limon
		var sdir := Vector3(0, sin(deg_to_rad(ang)), -cos(deg_to_rad(ang)))
		var px := Basis(sdir * side, nrm, Vector3(side, 0, 0))
		for k in 5:
			var off := (k - 2) * (slope / 5.0)
			var pc := c0 + sdir * off + Vector3(side * 0.131, 0, 0)
			b.add(frame_sweep(slope / 10.0 - 0.1, 0.13, PROF_PANEL, M("moulure_pierre")), Transform3D(px, pc))
			b.add(frame_sweep(slope / 10.0 - 0.16, 0.07, [[0.02, 0.03], [0.02, 0.05], [0.0, 0.05]], M("or_vieilli")), Transform3D(px, pc))
		for i in range(0, steps + 1, 2):
			var y := rise * i + 0.3
			var z := -run * i - 0.1
			b.add(bal, ModuleBuilder.at(Vector3(x, y, z)))
		for end in [0.0, 1.0]:
			var p := Vector3(x, rise * steps * end + 0.0, -Lz * end)
			b.add(post, ModuleBuilder.at(p))
			b.add(StyleKit.torus(0.13, 0.025, M(GOLD), 16, 4), ModuleBuilder.at(p + Vector3(0, 1.17, 0)))
			b.add(StyleKit.sphere(0.08, M("abat_jour"), 12, 6), ModuleBuilder.at(p + Vector3(0, 1.27, 0)))
			b.add(StyleKit.sphere(0.03, M(GOLD), 6, 3), ModuleBuilder.at(p + Vector3(0, 1.45, 0)))
		b.collide(Vector3(0.3, 1.3, slope), Vector3(x, H * 0.5 + 0.6, -Lz * 0.5), Vector3(ang, 0, 0))
	var thick := 0.4
	var n := Vector3(0, cos(deg_to_rad(ang)), sin(deg_to_rad(ang)))
	b.collide(Vector3(w, thick, slope + 0.6), Vector3(0, H * 0.5, -Lz * 0.5) - n * (thick * 0.5) + Vector3(0, 0.02, 0), Vector3(ang, 0, 0))
	return b

# ================================================================== végétal

## Grappe conique retombante : petites sphères décroissantes en spirale, deux teintes de glycine, courte tige.
static func _grappe(b: ModuleBuilder, top: Vector3, length: float, R: float, k: int, n := 14) -> void:
	var clair := M("fleur_lavande")
	var fonce := M("glycine")
	tube(b, top + Vector3(0.03, 0.22, 0), top, 0.011, 0.007, M("ecorce"), 5)
	for i in n:
		var t := float(i) / (n - 1)
		var r := R * (1.0 - 0.6 * t)
		var sw := sin(float(i + k) * 2.1) * 0.032 * (1.0 - t)
		var cw := cos(float(i + k) * 2.1) * 0.032 * (1.0 - t)
		var mat := clair if (i + k) % 2 == 0 else fonce
		_ball(b, top + Vector3(sw, -t * length - r, cw), r, mat, 8, 4, 1.15)
		if i % 3 == 1 and i < n - 2:
			_ball(b, top + Vector3(-sw * 1.8, -t * length - r * 1.4, -cw * 1.8), r * 0.75, fonce if mat == clair else clair, 8, 3, 1.1)

## Feuille effilée (extrusion mince), pointe vers +x, base à p.
static var _leaf_cache: ArrayMesh = null
static func _leaf(b: ModuleBuilder, p: Vector3, yaw_deg: float, roll_deg: float, size := 0.26) -> void:
	if _leaf_cache == null:
		_leaf_cache = StyleKit.extrude(P([[0.0, 0.0], [0.25, 0.4], [0.7, 0.45], [1.0, 0.0], [0.7, -0.45], [0.25, -0.4]]), 0.008, M("feuillage"), 0.0)
	b.add(_leaf_cache, Transform3D(Basis.from_euler(Vector3(deg_to_rad(-80.0 + roll_deg), deg_to_rad(yaw_deg), 0.0)).scaled(Vector3(size, size * 0.3, size)), p))

## Grappes de glycine suspendues (attache à y = 0, ~1,4 m de long) : cinq grappes coniques et quelques feuilles.
static func glycine() -> ModuleBuilder:
	var b := ModuleBuilder.new("glycine")
	var cl := [[Vector3(0, 0, 0), 1.45, 0.055], [Vector3(0.3, 0.02, 0.08), 1.1, 0.05], [Vector3(-0.28, 0.0, -0.06), 1.25, 0.052]]
	tube(b, Vector3(-0.42, 0.14, 0.0), Vector3(0.0, 0.2, 0.0), 0.02, 0.016, M("ecorce"), 5)
	tube(b, Vector3(0.0, 0.2, 0.0), Vector3(0.42, 0.13, 0.04), 0.016, 0.01, M("ecorce"), 5)
	var k := 0
	for c in cl:
		_grappe(b, c[0], c[1], c[2], k)
		k += 3
	for i in 6:
		var a := TAU * i / 6.0
		_leaf(b, Vector3(cos(a) * 0.2, 0.02 - 0.04 * (i % 2), sin(a) * 0.2), -rad_to_deg(a), 20.0)
	b.cast_shadows = false
	return b

## Rameau de glycine posé sur une main courante (2,8 m le long de x, face visible +z) : tige sinueuse, feuilles, grappes
## retombant vers la salle.
static func rameau_glycine() -> ModuleBuilder:
	var b := ModuleBuilder.new("rameau_glycine")
	var prev := Vector3(-1.45, 0.02, 0.1)
	for k in range(1, 15):
		var t := float(k) / 14.0
		var p := Vector3(-1.45 + 2.9 * t, 0.02 + 0.045 * sin(t * 9.0), 0.1 + 0.07 * cos(t * 7.0 + 1.0))
		tube(b, prev, p, 0.026 - 0.01 * t, 0.024 - 0.01 * t, M("ecorce"), 5)
		prev = p
	for i in 12:
		var x := -1.35 + 2.7 * (i + 0.5) / 12.0
		_leaf(b, Vector3(x, 0.05 + 0.03 * (i % 2), 0.1 + (0.1 if i % 2 == 0 else -0.04)), 30.0 * i, 25.0 * (1.0 if i % 2 == 0 else -1.0), 0.24)
	var xs := [-1.1, -0.35, 0.45, 1.15]
	for i in xs.size():
		var L := 0.6 + 0.35 * hash01(i, 11)
		_grappe(b, Vector3(float(xs[i]), 0.0, 0.2), L * 1.3, 0.05 + 0.008 * hash01(i, 4), i * 2, 12)
	b.cast_shadows = false
	return b

## Arbre de lune : vasque ronde à bord doré, racines apparentes, tronc torsadé, branches visibles, houppier en grappes
## étagées de petites fleurs (lavande vers rose lunaire).
static func arbre() -> ModuleBuilder:
	var b := ModuleBuilder.new("arbre_de_lune")
	var gold := M(GOLD)
	b.add(StyleKit.lathe(P([[1.5, 0.0], [1.56, 0.08], [1.5, 0.3], [1.44, 0.6], [1.58, 0.74], [1.63, 0.82], [1.55, 0.88], [1.4, 0.86]]), 40, M("pierre_claire"), true, false))
	b.add(StyleKit.torus(1.6, 0.06, gold, 40, 6), ModuleBuilder.at(Vector3(0, 0.78, 0)))
	b.add(StyleKit.torus(1.5, 0.035, gold, 40, 6), ModuleBuilder.at(Vector3(0, 0.9, 0)))
	b.add(StyleKit.torus(1.5, 0.03, gold, 40, 5), ModuleBuilder.at(Vector3(0, 0.2, 0)))
	for i in 12:
		var a := TAU * i / 12.0
		var shape: ArrayMesh = star_mesh(0.14, "or_vieilli", 0.03) if i % 2 == 0 else _small_crescent()
		b.add(shape, Transform3D(Basis(Vector3.UP, PI * 0.5 - a) * Basis(Vector3.BACK, 0.0 if i % 2 == 0 else PI * 0.5), Vector3(cos(a) * 1.5, 0.46, sin(a) * 1.5)))
	b.add(StyleKit.cylinder(1.4, 0.84, M("ecorce"), 32))
	# racines apparentes
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		var d := Vector3(cos(a), 0, sin(a))
		var p0 := d * 0.12 + Vector3(0, 1.1, 0)
		var p1 := d * 0.42 + Vector3(0, 0.92, 0)
		var p2 := d * (0.85 + 0.2 * hash01(i, 7)) + Vector3(0, 0.84, 0)
		tube(b, p0, p1, 0.2, 0.12, M("ecorce"), 7)
		tube(b, p1, p2, 0.12, 0.04, M("ecorce"), 7)
	# tronc torsadé : deux brins enroulés autour d'un cœur
	b.add(StyleKit.lathe(P([[0.2, 0.8], [0.19, 2.2], [0.16, 3.0], [0.1, 3.5]]), 10, M("ecorce"), false, true))
	for s in 2:
		var prev := Vector3.ZERO
		for k in range(0, 13):
			var t := float(k) / 12.0
			var y := 0.95 + 2.5 * t
			var phi := t * 6.0 + PI * s
			var rho := 0.15 * (1.0 - 0.45 * t)
			var p := Vector3(cos(phi) * rho, y, sin(phi) * rho)
			if k > 0:
				tube(b, prev, p, 0.15 - 0.06 * (t - 1.0 / 12.0), 0.15 - 0.06 * t, M("ecorce"), 7)
			prev = p
	# branches (trois tronçons) menant à six masses fleuries
	var masses := [[Vector3(0, 4.75, 0), 1.0], [Vector3(1.55, 4.05, 0.3), 0.85], [Vector3(-1.4, 4.1, 0.7), 0.85], [Vector3(0.3, 4.1, -1.5), 0.85], [Vector3(-0.2, 4.0, 1.5), 0.8], [Vector3(-1.2, 4.0, -1.0), 0.8], [Vector3(1.1, 4.2, -1.1), 0.8]]
	for i in masses.size():
		var m: Vector3 = masses[i][0]
		var y0 := 2.5 + 0.2 * float(i % 4)
		var d := Vector3(m.x, 0, m.z)
		var pts := [Vector3(0, y0, 0) + d.normalized() * 0.08, d * 0.4 + Vector3(0, y0 + 0.5, 0), d * 0.75 + Vector3(0, (y0 + m.y - 0.4) * 0.5 + 0.2, 0), m - Vector3(0, 0.45, 0)]
		var rr := [0.11, 0.08, 0.055, 0.03]
		for k in 3:
			tube(b, pts[k], pts[k + 1], rr[k], rr[k + 1], M("ecorce"), 6)
		_bloom_mass(b, m, float(masses[i][1]), i)
	for i in 3:
		tube(b, Vector3(0, 3.45, 0), Vector3(cos(i * 2.1) * 0.3, 4.3, sin(i * 2.1) * 0.3), 0.07, 0.03, M("ecorce"), 6)
	# pétales tombés dans la vasque
	for i in 12:
		var a := TAU * i / 12.0 + 0.3
		var rr2 := 0.7 + 0.5 * hash01(i, 13)
		_ball(b, Vector3(cos(a) * rr2, 0.865, sin(a) * rr2), 0.05, M("fleur_rose" if i % 2 == 0 else "fleur_lavande"), 6, 4, 0.5)
	b.omni(Vector3(0, 3.6, 0), Color("#c9a0ff"), 1.4, 8.0, false, "Lueur")
	b.collide(Vector3(3.1, 0.9, 3.1), Vector3(0, 0.45, 0))
	return b

## Grappe étagée de petites fleurs : trois étages de sphères en couronne, de plus en plus petits vers le bas.
static func _bloom_cluster(b: ModuleBuilder, c: Vector3, scale: float, k: int) -> void:
	var mats := [M("fleur_lavande"), M("fleur_rose"), M("glycine")]
	for tier in 3:
		var y := c.y - tier * 0.24 * scale
		var R := (0.46 - 0.13 * tier) * scale
		var cnt: int = [6, 4, 3][tier]
		var rs := (0.125 - 0.02 * tier) * scale
		for i in cnt:
			var a := TAU * (i + 0.5 * tier) / cnt + k * 0.9
			var j := 0.85 + 0.3 * hash01(k * 7 + i, tier)
			var m: Material = mats[(tier + (1 if (i + k) % 3 == 0 else 0)) % 3]
			_ball(b, Vector3(c.x + cos(a) * R * j, y - 0.06 * hash01(i, k), c.z + sin(a) * R * j), rs, m, 7, 4, 0.9)
	_ball(b, c + Vector3(0, 0.1 * scale, 0), 0.14 * scale, mats[(k + 1) % 3], 7, 4, 0.9)
	_ball(b, c + Vector3(0, -0.72 * scale, 0), 0.07 * scale, mats[(k + 2) % 3], 7, 4, 1.2)

## Masse fleurie : ellipsoïde plein recouvert de petites fleurs qui se chevauchent (lavande en haut, rose lunaire en bas),
## quelques grappes retombantes sur les bords.
static func _bloom_mass(b: ModuleBuilder, c: Vector3, R: float, k: int) -> void:
	var lav := M("fleur_lavande")
	var ros := M("fleur_rose")
	var arb := M("glycine")
	# trois lobes lisses qui se chevauchent
	b.add(_unit_sphere(lav, 16, 8), Transform3D(Basis(Vector3.UP, k * 0.5).scaled(Vector3(R * 0.95, R * 0.74, R * 0.95)), c + Vector3(0, 0.08 * R, 0)))
	b.add(_unit_sphere(arb, 12, 6), Transform3D(Basis(Vector3.UP, k).scaled(Vector3(R * 0.62, R * 0.5, R * 0.62)), c + Vector3(cos(k * 2.0) * R * 0.55, -0.12 * R, sin(k * 2.0) * R * 0.55)))
	b.add(_unit_sphere(ros, 12, 6), Transform3D(Basis(Vector3.UP, k * 2.0).scaled(Vector3(R * 0.58, R * 0.46, R * 0.58)), c + Vector3(-cos(k * 2.0 + 0.8) * R * 0.5, -0.22 * R, -sin(k * 2.0 + 0.8) * R * 0.5)))
	# petites touffes lisses qui cassent la surface
	for i in 5:
		var a := i * 2.399963 + k * 0.9
		var yy := 0.75 - 0.32 * i
		var rad := sqrt(maxf(1.0 - yy * yy, 0.0))
		var mat: Material = ros if (i + k) % 2 == 0 else lav
		b.add(_unit_sphere(mat, 10, 5), Transform3D(Basis(Vector3.UP, a).scaled(Vector3(0.17 * R, 0.13 * R, 0.17 * R)), c + Vector3(cos(a) * rad * R * 0.9, yy * R * 0.68, sin(a) * rad * R * 0.9)))
	for j in 2:
		var a := TAU * j / 2.0 + k * 1.3
		var top := c + Vector3(cos(a) * R * 0.75, -R * 0.4, sin(a) * R * 0.75)
		for q in 3:
			b.add(_unit_sphere(ros if q % 2 == 0 else lav, 10, 5), Transform3D(Basis.IDENTITY.scaled(Vector3(0.075 - 0.015 * q, 0.09 - 0.015 * q, 0.075 - 0.015 * q)), top + Vector3(0, -q * 0.15, 0)))

## Jardinière ronde sur socle : vasque de pierre à bord doré, buisson fleuri en grappes étagées.
static func jardiniere() -> ModuleBuilder:
	var b := ModuleBuilder.new("jardiniere")
	b.add(StyleKit.lathe(P([[0.3, 0.0], [0.36, 0.1], [0.5, 0.65], [0.55, 0.75], [0.5, 0.78]]), 20, M("pierre_claire"), true, true))
	b.add(StyleKit.torus(0.53, 0.03, M(GOLD), 24, 4), ModuleBuilder.at(Vector3(0, 0.72, 0)))
	b.add(StyleKit.torus(0.4, 0.018, M("or_vieilli"), 20, 4), ModuleBuilder.at(Vector3(0, 0.3, 0)))
	b.add(StyleKit.cylinder(0.48, 0.78, M("ecorce"), 18))
	var bush := [[Vector3(0, 1.0, 0), 0.4], [Vector3(0.24, 0.92, 0.1), 0.28], [Vector3(-0.22, 0.95, -0.12), 0.3]]
	for p in bush:
		_ball(b, p[0], p[1], M("feuillage"), 9, 4, 0.9)
	for i in 2:
		var a := TAU * i / 2.0 + 0.4
		_bloom_cluster(b, Vector3(cos(a) * 0.22, 1.2 + 0.12 * (i % 2), sin(a) * 0.22), 0.55, i + 3)
	b.collide(Vector3(1.0, 1.2, 1.0), Vector3(0, 0.6, 0))
	return b

## Bannière : tringle dorée à embouts, étoffe brodée (croissant, étoiles), franges et gland doré.
static func banniere() -> ModuleBuilder:
	var b := ModuleBuilder.new("banniere")
	var w := 0.95
	var h := 2.8
	var gold := M(GOLD)
	b.add(StyleKit.cylinder(0.035, w + 0.4, gold, 10), ModuleBuilder.at(Vector3(-(w + 0.4) * 0.5, 0, 0.05), Vector3(0, 0, -90)))
	for x in [-(w + 0.4) * 0.5, (w + 0.4) * 0.5]:
		b.add(StyleKit.sphere(0.065, gold, 10, 6), ModuleBuilder.at(Vector3(x, 0, 0.05)))
		b.add(StyleKit.torus(0.05, 0.012, gold, 10, 4), ModuleBuilder.at(Vector3(x * 0.92, 0, 0.05), Vector3(0, 0, 90)))
	var cloth := P([[-w * 0.5, 0], [w * 0.5, 0], [w * 0.5, -h + 0.35], [0, -h], [-w * 0.5, -h + 0.35]])
	var border := P([[-w * 0.5 - 0.05, 0], [w * 0.5 + 0.05, 0], [w * 0.5 + 0.05, -h + 0.33], [0, -h - 0.07], [-w * 0.5 - 0.05, -h + 0.33]])
	b.add(StyleKit.extrude(border, 0.025, M("or_vieilli"), 0.0), ModuleBuilder.at(Vector3(0, -0.05, 0.03)))
	b.add(StyleKit.extrude(cloth, 0.04, M("banniere"), 0.01), ModuleBuilder.at(Vector3(0, -0.05, 0.05)))
	var inner := P([[-w * 0.5 + 0.08, -0.14], [w * 0.5 - 0.08, -0.14], [w * 0.5 - 0.08, -h + 0.42], [0, -h + 0.12], [-w * 0.5 + 0.08, -h + 0.42]])
	for k in inner.size():
		var a: Vector2 = inner[k]
		var c: Vector2 = inner[(k + 1) % inner.size()]
		var ln := line_between(Vector3(a.x, a.y, 0), Vector3(c.x, c.y, 0), 0.016, 0.012, M("or_vieilli"))
		b.add(ln[0], Transform3D(Basis.IDENTITY, Vector3(0, -0.05, 0.075)) * (ln[1] as Transform3D))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.26, 0.6), 0.03, M("etoile_or"), 0.008), ModuleBuilder.at(Vector3(0, -1.05, 0.08), Vector3(0, 0, 90)))
	b.add(star_mesh(0.12, "etoile_or", 0.03), ModuleBuilder.at(Vector3(0, -1.75, 0.08)))
	b.add(star_mesh(0.06, "etoile_or", 0.025), ModuleBuilder.at(Vector3(0.22, -0.6, 0.08)))
	b.add(star_mesh(0.06, "etoile_or", 0.025), ModuleBuilder.at(Vector3(-0.22, -0.6, 0.08)))
	# franges et gland
	var ball := StyleKit.sphere(0.022, M("or_vieilli"), 5, 3)
	for k in 7:
		var t := float(k) / 6.0
		var x := -w * 0.5 + w * t
		var y := -h + 0.35 - (1.0 - absf(t * 2.0 - 1.0)) * 0.35
		b.add(ball, Transform3D(Basis.IDENTITY, Vector3(x * 0.98, y - 0.07, 0.05)))
	tube(b, Vector3(0, -h - 0.04, 0.05), Vector3(0, -h - 0.22, 0.05), 0.012, 0.012, M("or_vieilli"), 5)
	b.add(StyleKit.lathe(P([[0.0, 0.0], [0.04, 0.03], [0.05, 0.1], [0.02, 0.17], [0.0, 0.18]]), 8, gold, false, false), ModuleBuilder.at(Vector3(0, -h - 0.4, 0.05)))
	b.cast_shadows = false
	return b
