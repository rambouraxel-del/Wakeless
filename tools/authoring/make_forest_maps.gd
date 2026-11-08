extends SceneTree
## Dessine les deux images du relief de la forêt nocturne à partir de formes ÉCRITES ICI (collines, clairière, sentier,
## ruines) : aucune graine, aucun hasard. Les PNG produits (maps/foret/relief.png et peinture.png) sont ensuite la source
## de vérité : on peut les retoucher dans n'importe quel logiciel d'images, puis « Recuire » le terrain (docs/NIVEAUX.md).
##   godot --headless -s tools/authoring/make_forest_maps.gd
## Image de 400 × 400 pixels = 80 × 80 m (1 pixel = 1 colonne de 20 cm), centrée sur l'origine ; clair = haut (blanc = 10,2 m).

const N := 400
const MAX_H := 10.2
const HALF := 40.0

# Collines douces : [centre x, centre z, rayon, hauteur]
const HILLS := [
	[-14.0, -10.0, 9.0, 1.6], [16.0, -14.0, 9.0, 1.9], [-20.0, 14.0, 8.0, 1.2], [13.0, 14.0, 7.0, 1.2],
	[4.0, -26.0, 7.0, 1.8], [-6.0, 24.0, 8.0, 1.0], [30.0, 2.0, 6.0, 1.4], [-27.0, -4.0, 8.0, 1.7],
]
# Pourtour : crête qui monte vers les bords, avec des creux et des bosses (angle en degrés, amplitude en mètres)
const RIDGE := [[0, 5.2], [40, 6.6], [80, 5.4], [125, 6.9], [165, 5.0], [205, 6.4], [250, 5.6], [290, 6.8], [330, 5.3]]
# Sentier : de la porte vers le sud, puis tour de la forêt jusqu'aux ruines (x, z) ; demi-largeur 1,2 m
const PATH := [[0.0, 3.0], [0.0, 9.0], [2.0, 15.0], [7.0, 20.0], [14.0, 22.0], [21.0, 19.0], [27.0, 12.0], [29.0, 4.0],
	[26.0, -6.0], [22.0, -14.0], [21.0, -21.0]]
const PATH_HW := 1.2
const CLEARING := [0.0, 0.0, 6.5]          # clairière de la porte : x, z, rayon
const PLINTH := [0.0, 0.0, 3.0]            # socle de pierre sous la porte
const RUINS := [22.0, -26.0, 6.5]          # clairière des ruines
# Taches de mousse et de fougères (peinture) : [x, z, rayon, "mousse" | "humide"]
const PATCHES := [[-9.0, 6.0, 4.0, "mousse"], [-18.0, -2.0, 5.0, "humide"], [10.0, -6.0, 4.5, "mousse"], [6.0, 24.0, 5.0, "humide"],
	[28.0, -12.0, 4.0, "mousse"], [-4.0, -18.0, 5.0, "humide"], [17.0, 8.0, 3.5, "mousse"], [-22.0, 20.0, 4.5, "mousse"]]

func _initialize() -> void:
	var h := PackedFloat32Array()
	h.resize(N * N)
	var paint := Image.create(N, N, false, Image.FORMAT_RGB8)
	paint.fill(Color(0, 0, 0))
	var polys := _path_samples()
	for j in N:
		for i in N:
			var x := (float(i) + 0.5) / N * 2.0 * HALF - HALF
			var z := (float(j) + 0.5) / N * 2.0 * HALF - HALF
			var v := 0.8 + 0.5 * _grain(x, z)
			for hill in HILLS:
				var d: float = Vector2(x - hill[0], z - hill[1]).length() / hill[2]
				if d < 1.0:
					v += hill[3] * _smooth(1.0 - d)
			# pourtour : distance au centre en « carré arrondi » ; amplitude interpolée selon l'angle
			var r := pow(pow(absf(x), 4.0) + pow(absf(z), 4.0), 0.25)
			v += _ridge_amp(atan2(z, x)) * _smooth((r - 24.0) / 13.0)
			# clairières : aplanies avec un fondu large
			v = _flatten(v, x, z, CLEARING, 1.2, 3.5)
			v = _flatten(v, x, z, PLINTH, 1.4, 1.0)
			v = _flatten(v, x, z, RUINS, 1.8, 3.0)
			h[i + j * N] = v
			# peinture
			var c := Color(0, 0, 0)
			for p in PATCHES:
				if Vector2(x - p[0], z - p[1]).length() < p[2] * (0.8 + 0.25 * _grain(x * 2.0, z * 2.0)):
					c = Color(0.16, 0.35, 0.2) if p[3] == "mousse" else Color(0.2, 0.4, 0.75)
			if Vector2(x - CLEARING[0], z - CLEARING[1]).length() < CLEARING[2] * 0.85:
				c = Color(0.75, 0.65, 0.45) if Vector2(x, z).length() > PLINTH[2] else Color(0.5, 0.5, 0.5)
			if Vector2(x - RUINS[0], z - RUINS[1]).length() < RUINS[2] * 0.7:
				c = Color(0.5, 0.5, 0.5) if Vector2(x - RUINS[0], z - RUINS[1]).length() < 3.2 else Color(0.16, 0.35, 0.2)
			if _dist_path(polys, x, z) < PATH_HW:
				c = Color(0.55, 0.40, 0.25)
			paint.set_pixel(i, j, c)
	var img := Image.create(N, N, false, Image.FORMAT_RGB8)
	for j in N:
		for i in N:
			var g := clampf(h[i + j * N] / MAX_H, 0.0, 1.0)
			img.set_pixel(i, j, Color(g, g, g))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://maps/foret"))
	print("relief : ", img.save_png("res://maps/foret/relief.png"), " · peinture : ", paint.save_png("res://maps/foret/peinture.png"))
	quit()

static func _smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

## Relief fin déterministe : bruit de valeur sur une grille de 3 m (table de hachage entière, pas de graine aléatoire).
static func _grain(x: float, z: float) -> float:
	var gx := x / 3.0
	var gz := z / 3.0
	var x0 := floori(gx)
	var z0 := floori(gz)
	var fx := _smooth(gx - x0)
	var fz := _smooth(gz - z0)
	var a := VoxelGrid.hash01(x0, 0, z0, 11)
	var b := VoxelGrid.hash01(x0 + 1, 0, z0, 11)
	var c := VoxelGrid.hash01(x0, 0, z0 + 1, 11)
	var d := VoxelGrid.hash01(x0 + 1, 0, z0 + 1, 11)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fz) - 0.5

static func _ridge_amp(angle: float) -> float:
	var deg := fposmod(rad_to_deg(angle), 360.0)
	for k in RIDGE.size():
		var a: Array = RIDGE[k]
		var b: Array = RIDGE[(k + 1) % RIDGE.size()]
		var a0: float = a[0]
		var b0: float = b[0] if b[0] > a[0] else b[0] + 360.0
		var d := deg if deg >= a0 else deg + 360.0
		if d >= a0 and d <= b0:
			return lerpf(a[1], b[1], _smooth((d - a0) / (b0 - a0)))
	return RIDGE[0][1]

static func _flatten(v: float, x: float, z: float, zone: Array, level: float, blend: float) -> float:
	var d := Vector2(x - zone[0], z - zone[1]).length()
	var r: float = zone[2]
	if d <= r:
		return level
	if d < r + blend:
		return lerpf(level, v, _smooth((d - r) / blend))
	return v

func _path_samples() -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in PATH:
		out.append(Vector2(q[0], q[1]))
	return out

## Distance du point (x, z) à la polyligne du sentier (segments).
static func _dist_path(pts: PackedVector2Array, x: float, z: float) -> float:
	var best := 1e9
	var p := Vector2(x, z)
	for k in pts.size() - 1:
		var a := pts[k]
		var ab := pts[k + 1] - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best
