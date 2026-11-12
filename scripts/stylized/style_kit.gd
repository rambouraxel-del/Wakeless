@tool
class_name StyleKit
extends RefCounted
## Kit de modélisation de la 3D STYLISÉE de Wakeless (douce, légèrement arrondie, cohérente avec Star-Faced One).
## Fonctions pures qui renvoient des ArrayMesh : boîtes arrondies, révolutions (colonnes, balustres, lampes, sphères,
## tores), extrusions de profils 2D (arches, étoiles, croissants, cadres), marches. Les assets sont fabriqués UNE fois par
## tools/authoring/build_stylized_assets.gd et enregistrés en .res ; le jeu ne génère rien.
## Convention : 1 unité = 1 m ; y vers le haut.

# ------------------------------------------------------------------ outils

static func _commit(st: SurfaceTool, mat: Material = null) -> ArrayMesh:
	# Les triangles sont écrits dans le sens trigonométrique ; Godot affiche les faces dont les sommets tournent dans le
	# sens horaire (vu de face) : on inverse l'ordre des indices.
	st.index()
	st.generate_tangents()
	var arr := st.commit_to_arrays()
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	for i in range(0, idx.size() - 2, 3):
		var tmp := idx[i + 1]
		idx[i + 1] = idx[i + 2]
		idx[i + 2] = tmp
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	if mat != null:
		m.surface_set_material(0, mat)
	return m

## Fusionne plusieurs ArrayMesh (une surface par matériau, transformés) : moins d'appels de dessin.
## parts : [[mesh, Transform3D], ...]. Les surfaces de même matériau sont regroupées.
static func merge(parts: Array) -> ArrayMesh:
	var by_mat := {}
	var order := []
	for p in parts:
		var mesh: Mesh = p[0]
		var xf: Transform3D = p[1] if p.size() > 1 else Transform3D.IDENTITY
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var mat := mesh.surface_get_material(s)
			var key: Variant = mat if mat != null else "none"
			if not by_mat.has(key):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				by_mat[key] = st
				order.append(key)
			(by_mat[key] as SurfaceTool).append_from(mesh, s, xf)
	var out := ArrayMesh.new()
	for key in order:
		var st: SurfaceTool = by_mat[key]
		st.index()
		var arr := st.commit_to_arrays()
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		if key is Material:
			out.surface_set_material(out.get_surface_count() - 1, key)
	return out

static func triangles(mesh: Mesh) -> int:
	var n := 0
	if mesh == null:
		return 0
	for s in mesh.get_surface_count():
		var a := mesh.surface_get_arrays(s)
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		n += idx.size() / 3 if idx.size() > 0 else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return n

# ------------------------------------------------------------------ boîte arrondie

## Boîte de taille `size`, centrée sur l'origine, arêtes et coins arrondis de rayon `r` (`k` segments par arrondi).
## Chaque point d'une grille posée sur les faces est projeté sur la forme arrondie : normales lisses, pas de couture.
static func rounded_box(size: Vector3, r: float, mat: Material = null, k := 3, uv_scale := 1.0) -> ArrayMesh:
	var h := size * 0.5
	r = minf(r, minf(h.x, minf(h.y, h.z)) * 0.999)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var axes := [_grid_axis(h.x, r, k), _grid_axis(h.y, r, k), _grid_axis(h.z, r, k)]
	# 6 faces : (axe normal, signe, axe u, axe v), ordre (u, v) choisi pour que u × v = normale sortante
	var faces := [[0, 1, 1, 2], [0, -1, 2, 1], [1, 1, 2, 0], [1, -1, 0, 2], [2, 1, 0, 1], [2, -1, 1, 0]]
	var inner := h - Vector3(r, r, r)
	for f in faces:
		var n: int = f[0]
		var sgn: float = f[1]
		var ua: int = f[2]
		var va: int = f[3]
		var us: PackedFloat32Array = axes[ua]
		var vs: PackedFloat32Array = axes[va]
		for i in us.size() - 1:
			for j in vs.size() - 1:
				var quad := [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]
				var pts := []
				for q in quad:
					var p := Vector3.ZERO
					p[n] = h[n] * sgn
					p[ua] = us[q[0]]
					p[va] = vs[q[1]]
					var c := p.clamp(-inner, inner)
					var d := p - c
					var nn := d.normalized() if d.length() > 1e-6 else Vector3.ZERO
					if nn == Vector3.ZERO:
						nn[n] = sgn
					var pos := c + nn * r
					var uv := Vector2(pos[ua], pos[va]) * uv_scale
					pts.append([pos, nn, uv])
				for tri in [[0, 1, 2], [0, 2, 3]]:
					for t in tri:
						st.set_normal(pts[t][1])
						st.set_uv(pts[t][2])
						st.add_vertex(pts[t][0])
	return _commit(st, mat)

static func _grid_axis(h: float, r: float, k: int) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	for i in k + 1:
		a.append(-h + r * (1.0 - cos(PI * 0.5 * float(i) / k)))
	var mid := maxi(1, int(ceil((2.0 * (h - r)) / 2.0)))       # grille intérieure ≈ 2 m (déformation, éclairage)
	for i in range(1, mid):
		a.append(-h + r + (2.0 * (h - r)) * float(i) / mid)
	for i in range(k, -1, -1):
		a.append(h - r * (1.0 - cos(PI * 0.5 * float(i) / k)))
	# dédoublonne (r ≈ h)
	var out := PackedFloat32Array()
	for v in a:
		if out.is_empty() or absf(v - out[out.size() - 1]) > 1e-5:
			out.append(v)
	return out

# ------------------------------------------------------------------ révolution

## Révolution d'un profil [(rayon, y), …] (de bas en haut) autour de Y. `segments` côtés. Normales lisses.
## `cap_bottom` / `cap_top` ferment les extrémités si le rayon n'y est pas nul.
static func lathe(profile: PackedVector2Array, segments: int, mat: Material = null, cap_bottom := true, cap_top := true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := profile.size()
	# normales du profil (2D) : moyenne des segments adjacents
	var pn := PackedVector2Array()
	for i in n:
		var a := profile[maxi(i - 1, 0)]
		var b := profile[mini(i + 1, n - 1)]
		var t := (b - a).normalized()
		pn.append(Vector2(t.y, -t.x))
	var vlen := PackedFloat32Array([0.0])
	for i in range(1, n):
		vlen.append(vlen[i - 1] + profile[i].distance_to(profile[i - 1]))
	for s in segments:
		var a0 := TAU * float(s) / segments
		var a1 := TAU * float(s + 1) / segments
		for i in n - 1:
			var quad := [[a0, i], [a1, i], [a1, i + 1], [a0, i + 1]]
			var pts := []
			for q in quad:
				var ang: float = q[0]
				var pi: int = q[1]
				var pr := profile[pi]
				var dir := Vector3(cos(ang), 0.0, sin(ang))
				var pos := dir * pr.x + Vector3(0, pr.y, 0)
				var nrm := (dir * pn[pi].x + Vector3(0, pn[pi].y, 0)).normalized()
				pts.append([pos, nrm, Vector2(ang / TAU * 4.0, vlen[pi])])
			for tri in [[0, 2, 1], [0, 3, 2]]:
				for t in tri:
					st.set_normal(pts[t][1])
					st.set_uv(pts[t][2])
					st.add_vertex(pts[t][0])
	for cap in [[0, cap_bottom, -1.0], [n - 1, cap_top, 1.0]]:
		var pi: int = cap[0]
		if not cap[1] or profile[pi].x < 1e-4:
			continue
		var y := profile[pi].y
		var up: float = cap[2]
		for s in segments:
			var a0 := TAU * float(s) / segments
			var a1 := TAU * float(s + 1) / segments
			var p0 := Vector3(cos(a0) * profile[pi].x, y, sin(a0) * profile[pi].x)
			var p1 := Vector3(cos(a1) * profile[pi].x, y, sin(a1) * profile[pi].x)
			var c := Vector3(0, y, 0)
			var tri := [c, p1, p0] if up > 0.0 else [c, p0, p1]
			for p in tri:
				st.set_normal(Vector3(0, up, 0))
				st.set_uv(Vector2(p.x, p.z))
				st.add_vertex(p)
	return _commit(st, mat)

static func sphere(radius: float, mat: Material = null, segments := 24, rings := 12) -> ArrayMesh:
	var prof := PackedVector2Array()
	for i in rings + 1:
		var a := -PI * 0.5 + PI * float(i) / rings
		prof.append(Vector2(cos(a) * radius, sin(a) * radius))
	return lathe(prof, segments, mat, false, false)

## Tore autour de Y : grand rayon R, rayon du tube r.
static func torus(R: float, r: float, mat: Material = null, segments := 48, tube := 10) -> ArrayMesh:
	var prof := PackedVector2Array()
	for i in tube + 1:
		var a := -PI * 0.5 - TAU * float(i) / tube
		prof.append(Vector2(R + cos(a) * r, sin(a) * r))
	return lathe(prof, segments, mat, false, false)

static func cylinder(radius: float, height: float, mat: Material = null, segments := 16) -> ArrayMesh:
	return lathe(PackedVector2Array([Vector2(radius, 0), Vector2(radius, height)]), segments, mat)

# ------------------------------------------------------------------ extrusion

## Extrude un polygone 2D (plan XY, sens quelconque) sur `depth` le long de Z (de -depth/2 à +depth/2).
## `bevel` > 0 : chanfrein doux sur les arêtes avant/arrière (aspect arrondi).
static func extrude(poly: PackedVector2Array, depth: float, mat: Material = null, bevel := 0.0, uv_scale := 1.0) -> ArrayMesh:
	if Geometry2D.is_polygon_clockwise(poly):
		poly.reverse()                                     # sens anti-horaire
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hz := depth * 0.5
	var tris := Geometry2D.triangulate_polygon(poly)
	var inset := poly
	if bevel > 0.0:
		var off := Geometry2D.offset_polygon(poly, -bevel, Geometry2D.JOIN_ROUND)
		if off.size() == 1 and off[0].size() >= 3:
			inset = off[0]
			if Geometry2D.is_polygon_clockwise(inset):
				inset.reverse()
			tris = Geometry2D.triangulate_polygon(inset)
		else:
			bevel = 0.0
			inset = poly
	# faces avant (+z) et arrière (-z)
	for side in [1.0, -1.0]:
		var z: float = hz * side
		for i in range(0, tris.size(), 3):
			var idx := [tris[i], tris[i + 1], tris[i + 2]] if side > 0 else [tris[i], tris[i + 2], tris[i + 1]]
			for t in idx:
				var p := inset[t]
				st.set_normal(Vector3(0, 0, side))
				st.set_uv(p * uv_scale)
				st.add_vertex(Vector3(p.x, p.y, z))
	# flancs : du contour extérieur (milieu) aux contours chanfreinés (faces)
	var outer := poly
	var m := outer.size()
	var rings := []           # [polygone, z]
	if bevel > 0.0:
		var inner_r := _resample(inset, outer)
		rings = [[inner_r, hz], [outer, hz - bevel], [outer, -hz + bevel], [inner_r, -hz]]
	else:
		rings = [[outer, hz], [outer, -hz]]
	var perim := PackedFloat32Array([0.0])
	for i in range(1, m + 1):
		perim.append(perim[i - 1] + outer[i % m].distance_to(outer[i - 1]))
	for ri in rings.size() - 1:
		var A: PackedVector2Array = rings[ri][0]
		var B: PackedVector2Array = rings[ri + 1][0]
		var za: float = rings[ri][1]
		var zb: float = rings[ri + 1][1]
		for i in m:
			var j := (i + 1) % m
			var pa := [Vector3(A[i].x, A[i].y, za), Vector3(A[j].x, A[j].y, za), Vector3(B[j].x, B[j].y, zb), Vector3(B[i].x, B[i].y, zb)]
			var p0: Vector3 = pa[0]
			var nrm: Vector3 = (pa[1] - p0).cross(pa[3] - p0).normalized()
			# normales lissées par sommet (moyenne des arêtes voisines) pour un aspect doux
			var ns := [_edge_normal(outer, i, za, zb, bevel, hz), _edge_normal(outer, j, za, zb, bevel, hz), _edge_normal(outer, j, zb, za, bevel, hz), _edge_normal(outer, i, zb, za, bevel, hz)]
			var uvs := [Vector2(perim[i], za), Vector2(perim[i + 1], za), Vector2(perim[i + 1], zb), Vector2(perim[i], zb)]
			if nrm.dot(Vector3(ns[0].x, ns[0].y, 0)) < 0.0 and absf(nrm.z) < 0.9:
				pass
			for tri in [[0, 2, 1], [0, 3, 2]]:
				for t in tri:
					var nn: Vector3 = ns[t]
					st.set_normal(nn)
					st.set_uv(uvs[t] * uv_scale)
					st.add_vertex(pa[t])
	return _commit(st, mat)

## Normale d'un sommet du contour (moyenne des deux arêtes), inclinée vers ±z sur les chanfreins.
static func _edge_normal(poly: PackedVector2Array, i: int, z_here: float, _z_other: float, bevel: float, hz: float) -> Vector3:
	var m := poly.size()
	var a := poly[(i - 1 + m) % m]
	var b := poly[i]
	var c := poly[(i + 1) % m]
	var e1 := (b - a).normalized()
	var e2 := (c - b).normalized()
	var n1 := Vector2(e1.y, -e1.x)
	var n2 := Vector2(e2.y, -e2.x)
	var n := (n1 + n2)
	n = n.normalized() if n.length() > 1e-5 else n1
	var v := Vector3(n.x, n.y, 0.0)
	if bevel > 0.0 and absf(z_here) >= hz - 1e-4:
		v = (v + Vector3(0, 0, signf(z_here))).normalized()
	elif bevel > 0.0:
		v = (v + Vector3(0, 0, signf(z_here) * 0.35)).normalized()
	return v

## Ré-échantillonne `inset` pour avoir autant de points que `outer` (point le plus proche, dans l'ordre).
static func _resample(inset: PackedVector2Array, outer: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in outer:
		var best := inset[0]
		var bd := INF
		for q in inset:
			var d := p.distance_squared_to(q)
			if d < bd:
				bd = d
				best = q
		out.append(best)
	return out

# ------------------------------------------------------------------ profils 2D

## Contour d'une arche pleine (rectangle surmonté d'un demi-cercle), base en y = 0, centrée en x = 0.
static func arch_outline(width: float, height: float, seg := 16) -> PackedVector2Array:
	var r := width * 0.5
	var spring := height - r
	var p := PackedVector2Array([Vector2(-r, 0), Vector2(r, 0)])
	for i in seg + 1:
		var a := PI * float(i) / seg
		p.append(Vector2(cos(a) * r, spring + sin(a) * r))
	return p

## Cadre d'arche (bandeau d'épaisseur `band`) autour d'une ouverture en arche : polygone simple en U.
static func arch_frame_outline(width: float, height: float, band: float, seg := 18) -> PackedVector2Array:
	var r := width * 0.5
	var spring := height - r
	var R := r + band
	var p := PackedVector2Array()
	p.append(Vector2(-R, 0))
	p.append(Vector2(-r, 0))
	for i in seg + 1:
		var a := PI - PI * float(i) / seg
		p.append(Vector2(cos(a) * r, spring + sin(a) * r))
	p.append(Vector2(r, 0))
	p.append(Vector2(R, 0))
	for i in seg + 1:
		var a := PI * float(i) / seg
		p.append(Vector2(cos(a) * R, spring + sin(a) * R))
	return p

## Mur percé d'une arche qui descend jusqu'au sol : moitié gauche (x < 0) ou droite. Polygone simple.
static func arch_wall_half(wall_w: float, wall_h: float, open_w: float, open_h: float, right: bool, seg := 12) -> PackedVector2Array:
	var r := open_w * 0.5
	var spring := open_h - r
	var p := PackedVector2Array()
	var W := wall_w * 0.5
	p.append(Vector2(-W, 0))
	p.append(Vector2(-r, 0))
	for i in seg + 1:
		var a := PI - PI * 0.5 * float(i) / seg
		p.append(Vector2(cos(a) * r, spring + sin(a) * r))
	p.append(Vector2(0, wall_h))
	p.append(Vector2(-W, wall_h))
	if right:
		var q := PackedVector2Array()
		for v in p:
			q.append(Vector2(-v.x, v.y))
		q.reverse()
		return q
	return p

static func star_outline(r_out: float, r_in: float, points := 5) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in points * 2:
		var a := PI * 0.5 + PI * float(i) / points
		var r := r_out if i % 2 == 0 else r_in
		p.append(Vector2(cos(a) * r, sin(a) * r))
	return p

## Croissant de lune : disque de rayon r moins le même disque décalé de `d` vers +x (ouvert vers +x).
static func crescent_outline(r: float, d: float = 0.55, seg := 24) -> PackedVector2Array:
	var dd := clampf(d, 0.1, 1.9) * r
	var y := sqrt(maxf(r * r - dd * dd * 0.25, 0.0))
	var th := atan2(y, dd * 0.5)                      # angle du point d'intersection haut (cercle principal)
	var p := PackedVector2Array()
	for i in seg + 1:                                 # bord extérieur : du haut vers le bas en passant par la gauche
		var a := th + (TAU - 2.0 * th) * float(i) / seg
		p.append(Vector2(cos(a), sin(a)) * r)
	var al := atan2(y, -dd * 0.5)                     # mêmes points vus du second cercle (centre (dd, 0))
	for i in range(1, seg):                           # bord intérieur : du bas vers le haut
		var a := (TAU - al) - (TAU - 2.0 * al) * float(i) / seg
		p.append(Vector2(dd, 0) + Vector2(cos(a), sin(a)) * r)
	return p

# ------------------------------------------------------------------ escalier

## Escalier droit : `steps` marches de hauteur `rise` et de giron `run`, largeur `width`, montant vers -z, départ en (0,0,0).
## Nez de marche arrondi (boîte arrondie par marche).
static func stairs(steps: int, rise: float, run: float, width: float, mat: Material, nose := 0.03) -> ArrayMesh:
	var parts := []
	var step := rounded_box(Vector3(width, rise + 0.02, run + 0.04), nose, mat, 2)
	for i in steps:
		var y := rise * (i + 0.5)
		var z := -run * (i + 0.5)
		parts.append([step, Transform3D(Basis.IDENTITY, Vector3(0, y, z))])
	# limon plein sous l'escalier (une boîte inclinée suffit à masquer le dessous)
	var total_h := rise * steps
	var total_l := run * steps
	var slope := sqrt(total_h * total_h + total_l * total_l)
	var under := rounded_box(Vector3(width * 0.98, 0.25, slope), 0.04, mat, 2)
	var ang := atan2(total_h, total_l)
	var b := Basis(Vector3.RIGHT, ang)
	parts.append([under, Transform3D(b, Vector3(0, total_h * 0.5 - 0.18, -total_l * 0.5 + 0.08))])
	return merge(parts)
