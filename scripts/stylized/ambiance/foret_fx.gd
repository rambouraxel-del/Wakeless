@tool
extends RefCounted
## Fabriques d'effets de la Forêt de la peur (Sonnet C) : lucioles, spores, pétales (CPUParticles3D : visibles en rendu
## logiciel, graine fixe), plans de brume, plan d'eau, rayons de lune, feux follets. Aucun hasard de notre côté.
## Utilisé par tools/authoring/foret_ambiance.gd. Les matériaux viennent de StyleMaterials (foret_*).

const FOLLET := preload("res://scripts/stylized/ambiance/foret_follet.gd")

static func _mat(id: String) -> Material:
	return StyleMaterials.get_mat(id)

static func _quad(mat: Material, size: Vector2) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = size
	q.material = mat
	return q

static func _twinkle(pulses: int) -> Gradient:
	# fondu d'entrée/sortie + scintillements lents (la rampe module la couleur, donc l'éclat)
	var g := Gradient.new()
	var offs := PackedFloat32Array([0.0, 0.12])
	var cols := PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1)])
	for i in pulses:
		var t := 0.2 + 0.6 * float(i) / float(maxi(pulses, 1))
		offs.append(t)
		cols.append(Color(1, 1, 1, 0.25))
		offs.append(t + 0.3 / float(pulses))
		cols.append(Color(1, 1, 1, 1))
	offs.append(1.0)
	cols.append(Color(1, 1, 1, 0))
	g.offsets = offs
	g.colors = cols
	return g

static func _base(nm: String, pos: Vector3, amount: int, life: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = nm
	p.position = pos
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.fixed_fps = 30
	p.explosiveness = 0.0
	p.randomness = 1.0
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	return p

## Lucioles : petits points qui dérivent lentement et scintillent, en grappe dans une boîte (demi-dimensions `half`).
## `color` peut dépasser 1 (HDR) pour que le glow les fasse briller.
static func lucioles(nm: String, pos: Vector3, half: Vector3, amount: int, color: Color, size := 0.09, life := 11.0) -> CPUParticles3D:
	var p := _base(nm, pos, amount, life)
	p.emission_box_extents = half
	p.direction = Vector3(0.2, 0.3, 0.1)
	p.spread = 180.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.22
	p.damping_min = 0.0
	p.damping_max = 0.05
	p.tangential_accel_min = -0.06
	p.tangential_accel_max = 0.06
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.4
	p.color = color
	p.color_ramp = _twinkle(3)
	p.mesh = _quad(_mat("foret_luciole"), Vector2(size, size))
	return p

## Spores et poussière dans les rayons de lune : plus fines, bleu pâle, montée presque immobile.
static func spores(nm: String, pos: Vector3, half: Vector3, amount: int, color: Color, size := 0.05) -> CPUParticles3D:
	var p := _base(nm, pos, amount, 16.0)
	p.emission_box_extents = half
	p.direction = Vector3(0.3, 1, 0.1)
	p.spread = 180.0
	p.gravity = Vector3(0, 0.012, 0)
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.05
	p.damping_min = 0.0
	p.damping_max = 0.03
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	p.color = color
	p.color_ramp = _twinkle(1)
	p.mesh = _quad(_mat("foret_spore"), Vector2(size, size))
	return p

## Pétales de la clairière : chute lente, blanc lunaire.
static func petales(nm: String, pos: Vector3, half: Vector3, amount: int, color: Color) -> CPUParticles3D:
	var p := _base(nm, pos, amount, 18.0)
	p.emission_box_extents = half
	p.direction = Vector3(0, -1, 0)
	p.spread = 70.0
	p.gravity = Vector3(0, -0.2, 0)
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.1
	p.damping_min = 0.2
	p.damping_max = 0.4
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	p.color_ramp = g
	p.color = color
	p.mesh = _quad(_mat("foret_petale"), Vector2(0.09, 0.055))
	return p

## Plan de brume horizontal (UV 0..1) : `size` en mètres, `mat_id` : foret_brume, foret_brume_marais, foret_brume_dense.
static func plan_brume(parent: Node, nm: String, center: Vector3, size: Vector2, mat_id := "foret_brume", yaw_deg := 0.0, density := -1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var pm := PlaneMesh.new()
	pm.size = size
	var mat := _mat(mat_id)
	if density >= 0.0:
		mat = mat.duplicate()
		(mat as ShaderMaterial).set_shader_parameter("density", density)
	pm.material = mat
	mi.mesh = pm
	mi.position = center
	mi.rotation_degrees.y = yaw_deg
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

## Plan d'eau sombre (matériau foret_eau). La lune est lue dans le LightingRig à l'exécution par ForetZones (moon_dir).
static func eau(parent: Node, nm: String, center: Vector3, size: Vector2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var pm := PlaneMesh.new()
	pm.size = size
	pm.material = _mat("foret_eau")
	mi.mesh = pm
	mi.position = center
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

## Rayon de lune : deux plans verticaux croisés, de `height` m, dont le pied est en `foot`. L'axe est incliné vers la lune.
static func rayon(parent: Node, nm: String, foot: Vector3, height: float, width: float, yaw_deg: float, toward_moon := Vector3(0, 0, 1)) -> Node3D:
	var n := Node3D.new()
	n.name = nm
	var axis := (Vector3.UP + Vector3(toward_moon.x, 0, toward_moon.z).normalized() * 0.3).normalized()
	for i in 2:
		var mi := MeshInstance3D.new()
		mi.name = "Plan%d" % i
		mi.mesh = _quad(_mat("foret_rayon"), Vector2(width, height))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var y := axis
		var x := y.cross(Vector3(0, 0, 1)).normalized()
		x = x.rotated(y, deg_to_rad(yaw_deg + 90.0 * i))
		var z := x.cross(y).normalized()
		mi.transform = Transform3D(Basis(x, y, z), axis * height * 0.5)
		n.add_child(mi)
	n.position = foot
	parent.add_child(n)
	return n

## Feu follet visuel : orbe cyan palpitant + lumière (script ForetFollet). A le déplace/escamote (propriété `intensite`).
static func follet(parent: Node, nm: String, pos: Vector3, energy := 1.1, range_m := 6.0, mat_id := "foret_lueur_cyan", color := Color("#58f0ff")) -> Node3D:
	var f := Node3D.new()
	f.set_script(FOLLET)
	f.name = nm
	f.position = pos
	f.set("mat_id", mat_id)
	f.set("light_color", color)
	f.set("light_energy", energy)
	f.set("light_range", range_m)
	parent.add_child(f)
	return f
