@tool
class_name ForetAmbiance
extends RefCounted
## Lumières, brume, particules, feux follets et zones d'ambiance de la Forêt de la peur (Sonnet C).
## Appelé par tools/authoring/build_foret_peur.gd (Sonnet A) : ForetAmbiance.build(niveau, groupe).
##
## Réglages avant l'appel (tous facultatifs) :
##   ForetAmbiance.chemin  : polyligne [[x, z], …] du chemin principal (lucioles, lueurs, rayons s'y alignent).
##   ForetAmbiance.sol_y   : Callable(x, z) -> float, hauteur du sol (sinon détectée sur un nœud ayant `surface_y`, sinon 0).
## Budgets : ≤ 600 particules, ≤ 24 lumières (aucune à ombres ; l'ombre unique est celle de la lune du LightingRig).
## Zones (z en m, −Z = nord) : lisière 0 → −22, marais −30 → −62, bois noir −65 → −108, clairière −110 → −140.
## Aucune graine ni hasard : chaque grappe est listée ci-dessous.

const FX := preload("res://scripts/stylized/ambiance/foret_fx.gd")
const ZONES := preload("res://scripts/stylized/ambiance/foret_zones.gd")

## Chemin principal provisoire (à recaler sur celui du niveau).
static var chemin: Array = [[0.0, 3.0], [1.0, -10.0], [-1.0, -22.0], [-3.0, -34.0], [0.0, -46.0], [3.0, -58.0],
	[2.0, -70.0], [-2.0, -84.0], [1.0, -98.0], [0.0, -110.0], [0.0, -126.0]]
static var sol_y: Callable = Callable()
## Comptes de la dernière construction (particules, lumières, follets).
static var stats := {}

const CYAN := Color("#4ff0ff")
const LUCIOLE_VERTE := Color(1.9, 2.4, 0.8)
const LUCIOLE_CYAN := Color(0.7, 2.2, 2.4)
const LUCIOLE_CHAUDE := Color(2.4, 1.9, 1.0)

static func x_at(z: float) -> float:
	for i in chemin.size() - 1:
		var a: Array = chemin[i]
		var b: Array = chemin[i + 1]
		if z <= a[1] and z >= b[1]:
			return lerpf(a[0], b[0], smoothstep(0.0, 1.0, (a[1] - z) / maxf(a[1] - b[1], 0.001)))
	return chemin[chemin.size() - 1][0] if z < chemin[chemin.size() - 1][1] else chemin[0][0]

static func _ground(level: Node3D, x: float, z: float) -> float:
	if sol_y.is_valid():
		return float(sol_y.call(x, z))
	for c in level.get_children():
		for cc in c.get_children():
			if cc.has_method("surface_y"):
				return float(cc.surface_y(x, z))
	return 0.0

static func _light(g: Node3D, nm: String, p: Vector3, color: Color, energy: float, range_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = nm
	l.position = p
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_m
	l.omni_attenuation = 1.5
	l.shadow_enabled = false
	g.add_child(l)
	return l

static func moon_vec() -> Vector3:
	for p in LightingRig.load_presets():
		if p["key"] == "foret_peur":
			return Basis.from_euler(Vector3(deg_to_rad(-float(p["sun_angle"])), deg_to_rad(float(p["sun_heading"])), 0.0)).z
	return Vector3(0, 0.5, -0.8)

static func build(level: Node3D, g: Node3D) -> void:
	var moon := moon_vec()
	var gy := func(x: float, z: float) -> float: return _ground(level, x, z)
	# remplissage froid sans ombre, venu de derrière le joueur : silhouette de Star-Faced One et chemin lisibles
	var fill := DirectionalLight3D.new()
	fill.name = "Remplissage_lune"
	fill.light_color = Color("#7587d0")
	fill.light_energy = 0.45
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-48.0, 15.0, 0.0)
	g.add_child(fill)
	var zones := Node.new()
	zones.set_script(ZONES)
	zones.name = "Zones"
	g.add_child(zones)
	_lisiere(g, gy, moon)
	_marais(g, gy)
	_bois_noir(g, gy)
	_clairiere(g, gy, moon)
	_count(g)

## Grappe de lucioles posée à (x, hauteur au-dessus du sol, z).
static func _grappe(g: Node3D, gy: Callable, nm: String, x: float, z: float, h: float, half: Vector3, n: int, col: Color, size := 0.09) -> void:
	g.add_child(FX.lucioles(nm, Vector3(x, gy.call(x, z) + h, z), half, n, col, size))

static func _lisiere(g: Node3D, gy: Callable, moon: Vector3) -> void:
	var z := Node3D.new()
	z.name = "Lisiere"
	g.add_child(z)
	# lueurs cyan de champignons et lumière de remplissage à l'arrivée
	_light(z, "LueurCyan_A", Vector3(-3.6, gy.call(-3.6, -4.0) + 0.9, -4.0), CYAN, 0.9, 6.5)
	_light(z, "LueurCyan_B", Vector3(3.8, gy.call(3.8, -10.0) + 0.9, -10.0), CYAN, 0.9, 6.5)
	_light(z, "LueurCyan_C", Vector3(-3.4, gy.call(-3.4, -17.0) + 1.0, -17.0), CYAN, 0.9, 6.5)
	_light(z, "Remplissage_arrivee", Vector3(0.0, gy.call(0.0, 1.0) + 2.8, 0.5), Color("#7a8cff"), 0.45, 10.0)
	# lucioles : grappes le long du chemin, alternance jaune-vert / cyan
	var zs := [-2.0, -7.0, -12.0, -16.5, -20.0, -4.5]
	for i in zs.size():
		var side := -2.4 if i % 2 == 0 else 2.6
		_grappe(z, gy, "Lucioles_%d" % i, x_at(zs[i]) + side, zs[i], 1.1, Vector3(1.8, 0.8, 2.4), 24, LUCIOLE_VERTE if i % 2 == 0 else LUCIOLE_CYAN)
	# rayons de lune et spores
	for i in 3:
		var rz: float = [-6.0, -13.0, -19.0][i]
		var rx: float = x_at(rz) + [2.8, -2.6, 2.4][i]
		FX.rayon(z, "Rayon_%d" % i, Vector3(rx, gy.call(rx, rz), rz), 6.0, 1.8, 25.0 + i * 40.0, moon)
		z.add_child(FX.spores("Spores_%d" % i, Vector3(rx, gy.call(rx, rz) + 1.8, rz), Vector3(1.3, 1.6, 1.3), 14, Color(0.7, 0.8, 1.2, 0.55)))
	# brume très légère au sol
	FX.plan_brume(z, "Brume_lisiere", Vector3(0, gy.call(0.0, -10.0) + 0.5, -10.0), Vector2(46, 34), "foret_brume", 0.0, 0.16)

static func _marais(g: Node3D, gy: Callable) -> void:
	var z := Node3D.new()
	z.name = "Marais"
	g.add_child(z)
	var lights := [[-6.0, -40.0], [5.0, -46.0], [-4.0, -54.0], [7.0, -58.0]]
	for i in lights.size():
		_light(z, "LueurNenuphar_%d" % i, Vector3(lights[i][0], gy.call(lights[i][0], lights[i][1]) + 0.9, lights[i][1]), Color("#3fe0ff"), 0.85, 7.5)
	for i in 4:
		var lz: float = [-36.0, -44.0, -52.0, -59.0][i]
		var lx: float = x_at(lz) + [-4.0, 4.5, -3.5, 3.0][i]
		_grappe(z, gy, "LuciolesMarais_%d" % i, lx, lz, 1.0, Vector3(2.4, 0.7, 2.8), 25, LUCIOLE_CYAN, 0.1)
	for i in 6:
		FX.plan_brume(z, "BrumeMarais_%d" % i, Vector3(0, gy.call(0.0, -46.0) + 0.3 + 0.42 * i, -46.0), Vector2(44, 40), "foret_brume_marais", 20.0 * i, 0.20 - 0.025 * i)

static func _bois_noir(g: Node3D, gy: Callable) -> void:
	var z := Node3D.new()
	z.name = "BoisNoir"
	g.add_child(z)
	# feux follets trompeurs : vers deux impasses, hors du chemin ; A les déplace (escamotage « intensite »)
	var fol := [[-9.0, -78.0, 1.5], [10.0, -92.0, 1.6], [-8.5, -101.0, 1.4]]
	for i in fol.size():
		FX.follet(z, "FeuFollet_%d" % i, Vector3(fol[i][0], gy.call(fol[i][0], fol[i][1]) + fol[i][2], fol[i][1]), 1.0, 6.5)
	for i in 2:
		var lz: float = [-74.0, -96.0][i]
		_grappe(z, gy, "LuciolesBois_%d" % i, x_at(lz) + [2.2, -2.0][i], lz, 1.3, Vector3(1.5, 0.8, 2.0), 10, Color(0.9, 1.1, 0.4))
	for i in 8:
		FX.plan_brume(z, "BrumeBois_%d" % i, Vector3(0, gy.call(0.0, -88.0) + 0.3 + 0.55 * i, -88.0), Vector2(46, 52), "foret_brume_dense", 17.0 * i, 0.30 - 0.03 * i)

static func _clairiere(g: Node3D, gy: Callable, moon: Vector3) -> void:
	var z := Node3D.new()
	z.name = "Clairiere"
	g.add_child(z)
	_light(z, "Chaleur_arbre", Vector3(0.0, gy.call(0.0, -128.0) + 5.5, -128.0), Color("#ffd7a0"), 0.9, 18.0)
	_light(z, "Lune_remplissage", Vector3(-3.0, gy.call(-3.0, -122.0) + 7.0, -122.0), Color("#aab8ff"), 0.45, 20.0)
	_light(z, "Lueur_cercle", Vector3(0.0, gy.call(0.0, -131.0) + 0.8, -131.0), Color("#ffe6c0"), 0.55, 8.0)
	for i in 3:
		var lx: float = [-4.0, 4.5, 0.5][i]
		var lz: float = [-120.0, -126.0, -136.0][i]
		_grappe(z, gy, "LuciolesCalmes_%d" % i, lx, lz, 1.3, Vector3(3.0, 1.0, 3.0), 25, LUCIOLE_CHAUDE, 0.085)
	z.add_child(FX.petales("Petales", Vector3(0.0, gy.call(0.0, -128.0) + 6.0, -128.0), Vector3(6.0, 1.0, 6.0), 30, Color(0.95, 0.96, 1.0, 0.9)))
	for i in 4:
		var rx: float = [-5.0, 4.0, -1.5, 6.5][i]
		var rz: float = [-118.0, -123.0, -133.0, -138.0][i]
		FX.rayon(z, "Rayon_%d" % i, Vector3(rx, gy.call(rx, rz), rz), 7.0, 2.2, 15.0 + i * 37.0, moon)
	z.add_child(FX.spores("Spores", Vector3(0.0, gy.call(0.0, -128.0) + 2.0, -128.0), Vector3(7.0, 2.0, 8.0), 40, Color(0.85, 0.9, 1.3, 0.5)))
	FX.plan_brume(z, "Brume_clairiere", Vector3(0, gy.call(0.0, -128.0) + 0.35, -128.0), Vector2(40, 34), "foret_brume", 0.0, 0.12)

static func _count(g: Node3D) -> void:
	var parts := 0
	var lights := 0
	var follets := 0
	var stack: Array = [g]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is CPUParticles3D:
			parts += (n as CPUParticles3D).amount
		elif n is Light3D:
			lights += 1
		elif n.get_script() == FX.FOLLET:
			follets += 1
			lights += 1                # chaque follet porte une lumière créée à l'exécution
	stats = {"particules": parts, "lumieres": lights, "follets": follets}
	print("ForetAmbiance : %d particules, %d lumières d'ambiance, %d feux follets" % [parts, lights, follets])
