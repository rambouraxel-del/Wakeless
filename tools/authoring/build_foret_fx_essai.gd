extends SceneTree
## Scène d'essai de l'ambiance de la Forêt de la peur (Sonnet C) : sol ondulé + chemin, marais avec eau, troncs-cylindres et
## houppiers-sphères sombres en substituts, ForetAmbiance complète. Écrit scenes/tests/foret_fx_essai.tscn.
##   godot --headless -s tools/authoring/build_foret_fx_essai.gd      (après --import)
## Enregistre aussi les matériaux foret_* (materials/stylized/foret_*.tres) : seuls ceux-ci, rien d'autre.

const Z0 := 14.0
const Z1 := -152.0
const XH := 46.0

static func hsol(x: float, z: float) -> float:
	var h := 0.55 * sin(x * 0.11 + z * 0.07) + 0.35 * sin(x * 0.23 - z * 0.13 + 1.3) + 0.12 * sin(x * 0.7 + z * 0.55)
	# les bords montent doucement : encadrent le parcours
	h += 0.0014 * x * x
	# marais : cuvette à l'ouest du chemin
	h -= 2.0 * exp(-(pow(x + 10.0, 2.0) + pow(z + 48.0, 2.0)) / 110.0)
	# chemin plus plat
	var d := absf(x - ForetAmbiance.x_at(z))
	h *= lerpf(0.35, 1.0, smoothstep(1.5, 6.0, d))
	return h

## Godot écrit « = null » pour les uniforms laissés à leur défaut : on retire ces lignes (le shader garde ses défauts).
func _strip_nulls(res_path: String) -> void:
	var f := FileAccess.open(res_path, FileAccess.READ)
	if f == null:
		return
	var out := PackedStringArray()
	for line in f.get_as_text().split("\n"):
		if not line.ends_with(" = null"):
			out.append(line)
	f.close()
	var w := FileAccess.open(res_path, FileAccess.WRITE)
	w.store_string("\n".join(out))
	w.close()

func _hash(i: int, k: float) -> float:
	return fposmod(sin(float(i) * 12.9898 + k * 78.233) * 43758.5453, 1.0)

func _initialize() -> void:
	# matériaux
	var defs := StyleMaterials.definitions()
	for id in StyleMaterialsForetFx.ids():
		ResourceSaver.save(defs[id], StyleMaterials.path_of(id))
		_strip_nulls(StyleMaterials.path_of(id))
	StyleMaterials._cache.clear()

	var root := Level.new()
	root.name = "ForetFxEssai"
	root.level_id = "foret-fx-essai"
	root.level_title = "Essai d'ambiance"
	root.lighting_preset = "foret_peur"
	root.kill_y = -40.0
	var spawns := AuthorKit.group(root, "Spawns")
	AuthorKit.marker(spawns, "depart", Vector3(0.0, hsol(0.0, 3.0) + 0.05, 3.0), 0.0)
	var arch := AuthorKit.group(root, "Architecture")
	var decor := AuthorKit.group(root, "Decor")
	var amb := AuthorKit.group(root, "Ambiance")

	# --- sol
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := 1.5
	var nx := int(2.0 * XH / step)
	var nz := int((Z0 - Z1) / step)
	for iz in nz:
		for ix in nx:
			var x0 := -XH + ix * step
			var z0 := Z0 - iz * step
			var q := [Vector3(x0, hsol(x0, z0), z0), Vector3(x0 + step, hsol(x0 + step, z0), z0), Vector3(x0 + step, hsol(x0 + step, z0 - step), z0 - step), Vector3(x0, hsol(x0, z0 - step), z0 - step)]
			for k in [0, 2, 1, 0, 3, 2]:
				st.add_vertex(q[k])
	st.generate_normals()
	var sol := MeshInstance3D.new()
	sol.name = "Sol"
	sol.mesh = st.commit()
	var mat := (StyleMaterials.definitions()["foret_sol"] as ShaderMaterial)
	var pts := PackedVector4Array()
	for p in ForetAmbiance.chemin:
		pts.append(Vector4(p[0], p[1], 0, 0))
	while pts.size() < 32:
		pts.append(Vector4(0, 0, 0, 0))
	mat.set_shader_parameter("path_pts", pts)
	mat.set_shader_parameter("path_count", ForetAmbiance.chemin.size())
	sol.material_override = mat
	arch.add_child(sol)

	# --- ruban de chemin : un embranchement (teste foret_chemin)
	var rib := SurfaceTool.new()
	rib.begin(Mesh.PRIMITIVE_TRIANGLES)
	var branch := [[1.0, -10.0], [5.0, -13.0], [9.0, -18.0], [11.0, -25.0]]
	var prev := []
	for i in 40:
		var t := float(i) / 39.0
		var seg := mini(int(t * 3.0), 2)
		var lt := t * 3.0 - seg
		var a: Array = branch[seg]
		var b: Array = branch[seg + 1]
		var px := lerpf(a[0], b[0], lt)
		var pz := lerpf(a[1], b[1], lt)
		var dir := Vector2(b[0] - a[0], b[1] - a[1]).normalized()
		var nrm := Vector2(-dir.y, dir.x) * 1.0
		var w := 1.0
		var l := Vector3(px - nrm.x * w, hsol(px - nrm.x * w, pz - nrm.y * w) + 0.03, pz - nrm.y * w)
		var r := Vector3(px + nrm.x * w, hsol(px + nrm.x * w, pz + nrm.y * w) + 0.03, pz + nrm.y * w)
		if not prev.is_empty():
			rib.set_uv(Vector2(0, t)); rib.add_vertex(prev[0])
			rib.set_uv(Vector2(1, t)); rib.add_vertex(prev[1])
			rib.set_uv(Vector2(0, t)); rib.add_vertex(l)
			rib.set_uv(Vector2(1, t)); rib.add_vertex(prev[1])
			rib.set_uv(Vector2(1, t)); rib.add_vertex(r)
			rib.set_uv(Vector2(0, t)); rib.add_vertex(l)
		prev = [l, r]
	rib.generate_normals()
	var rm := MeshInstance3D.new()
	rm.name = "CheminRuban"
	rm.mesh = rib.commit()
	rm.material_override = StyleMaterials.definitions()["foret_chemin"]
	arch.add_child(rm)

	# --- eau du marais
	ForetFx().eau(decor, "Eau", Vector3(-10.0, -0.45, -48.0), Vector2(30, 26))
	# flaque près de l'arrivée
	ForetFx().eau(decor, "Flaque", Vector3(-5.5, hsol(-5.5, -8.0) - 0.02, -8.0), Vector2(4.5, 3.2))

	# --- troncs et houppiers (substituts)
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color("#1e1829")
	tm.roughness = 0.95
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color("#0c1230")
	cm.roughness = 1.0
	var n := 0
	for iz in 70:
		var z := -2.0 - iz * 2.1
		for side in [-1, 1]:
			var zone_dense := 1.0 if (z < -65.0 and z > -110.0) else (0.55 if z > -110.0 else 0.0)
			if z < -110.0:
				# clairière : cercle de troncs lointains seulement
				if absf(z + 130.0) < 12.0 and side != 0 and iz % 2 == 0:
					pass
				else:
					continue
			if _hash(n, 1.0) > zone_dense + 0.1:
				n += 1
				continue
			var off := 3.5 + _hash(n, 2.0) * (14.0 if zone_dense < 1.0 else 11.0)
			var x: float = ForetAmbiance.x_at(z) + float(side) * off
			if z < -110.0:
				x = float(side) * (14.0 + _hash(n, 4.0) * 8.0)
			if z < -38.0 and z > -58.0 and x < -2.0 and x > -26.0:
				n += 1
				continue
			var gy := hsol(x, z)
			var hgt := 8.0 + _hash(n, 3.0) * 6.0
			var tr := MeshInstance3D.new()
			tr.name = "Tronc_%d" % n
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.28
			cyl.bottom_radius = 0.5 + _hash(n, 5.0) * 0.3
			cyl.height = hgt
			cyl.material = tm
			tr.mesh = cyl
			tr.position = Vector3(x, gy + hgt * 0.5, z)
			decor.add_child(tr)
			if z < -110.0:
				n += 1
				continue
			var cr := MeshInstance3D.new()
			cr.name = "Houppier_%d" % n
			var sp := SphereMesh.new()
			sp.radius = 3.0 + _hash(n, 6.0) * 1.8
			sp.height = sp.radius * 1.5
			sp.material = cm
			cr.mesh = sp
			cr.position = Vector3(x, gy + hgt + 0.8, z)
			decor.add_child(cr)
			n += 1
	# arbre ancien de la clairière (substitut clair doux)
	var anc := MeshInstance3D.new()
	anc.name = "ArbreAncien"
	var ac := CylinderMesh.new()
	ac.top_radius = 0.9
	ac.bottom_radius = 1.6
	ac.height = 12.0
	ac.material = tm
	anc.mesh = ac
	anc.position = Vector3(0.0, hsol(0.0, -128.0) + 6.0, -128.0)
	decor.add_child(anc)
	# rochers sombres (sphères écrasées) près du chemin
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color("#2a2c3c")
	rock.roughness = 0.9
	for i in 16:
		var rz := -6.0 - i * 8.5
		var rx := ForetAmbiance.x_at(rz) + (3.2 if i % 2 == 0 else -3.4) * (1.0 + _hash(i, 8.0))
		var rm2 := MeshInstance3D.new()
		rm2.name = "Rocher_%d" % i
		var s := SphereMesh.new()
		s.radius = 0.7 + _hash(i, 9.0) * 0.6
		s.height = s.radius * 1.3
		s.material = rock
		rm2.mesh = s
		rm2.position = Vector3(rx, hsol(rx, rz) + 0.1, rz)
		decor.add_child(rm2)

	ForetAmbiance.sol_y = Callable(self, "_h2")
	ForetAmbiance.build(root, amb)
	AuthorKit.save_scene(root, "res://scenes/tests/foret_fx_essai.tscn")
	root.free()
	quit()

func _h2(x: float, z: float) -> float:
	return hsol(x, z)

func ForetFx() -> GDScript:
	return load("res://scripts/stylized/ambiance/foret_fx.gd")
