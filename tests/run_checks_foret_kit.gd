extends SceneTree
## Contrôles du KIT ORGANIQUE PROVISOIRE de la Forêt de la peur (scripts/stylized/style_assets_foret.gd) :
## chaque module est construit et enregistré, budget de triangles, un matériau partagé par surface, collisions simples
## présentes (et absentes des petites plantes), nœuds nommés pour le niveau, pas de hasard à l'exécution, modules à jour.
## Lancer : godot --headless -s tests/run_checks_foret_kit.gd
var ok := 0
var fail := 0

# Budgets (triangles) : arbres 6 000 (arbre_ancien 12 000), plantes répétées 600, rochers / petits éléments 2 000.
const ARBRES := ["arbre_tordu_a", "arbre_tordu_b", "arbre_tordu_c", "arbre_echasses", "arbre_mort"]
const PLANTES := ["herbes_touffe", "fougere", "champignons_lumineux", "fleurs_blanches", "nenuphars", "roseaux"]
const PETITS := ["souche", "rocher_a", "rocher_b", "rocher_c", "pierres_plates", "cercle_pierres", "arbuste_a", "arbuste_b",
	"tronc_couche", "racines_arche", "racines_basses", "ruine_colonne", "piedestal_lune", "fleur_lanterne", "silhouette_ombre"]
# Avec collision : troncs, rochers, ruines, souches, troncs couchés (+ mise en scène solide).
const SOLIDES := ["arbre_tordu_a", "arbre_tordu_b", "arbre_tordu_c", "arbre_echasses", "arbre_mort", "arbre_ancien", "tronc_couche",
	"souche", "racines_arche", "rocher_a", "rocher_b", "rocher_c", "cercle_pierres", "ruine_arche", "ruine_colonne", "ruine_mur",
	"ruine_porte_lune", "piedestal_lune", "cadre_porte_reve", "pont_racines"]

func check(label: String, cond: bool, detail := "") -> void:
	if cond:
		ok += 1
	else:
		fail += 1
		print("  ECHEC : ", label, " ", detail)

func _tris(n: Node) -> int:
	var t := 0
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		t += StyleKit.triangles((mi as MeshInstance3D).mesh)
	return t

## Boîte englobante (repère du module) de tous les maillages, pivots compris.
func _aabb(root: Node3D, only_visible := false) -> AABB:
	var box := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if only_visible:
			var vis := true
			var n: Node = m
			while n != root and n != null:
				if n is Node3D and not (n as Node3D).visible:
					vis = false
				n = n.get_parent()
			if not vis:
				continue
		var xf := Transform3D.IDENTITY
		var n2: Node = m
		while n2 != root and n2 != null:
			xf = (n2 as Node3D).transform * xf
			n2 = n2.get_parent()
		var bb := xf * m.mesh.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	return box

func _shapes(n: Node) -> int:
	var c := 0
	for cs in n.find_children("*", "CollisionShape3D", true, false):
		if (cs as CollisionShape3D).shape != null:
			c += 1
	return c

func _initialize() -> void:
	var ids := StyleAssetsForet.ids()
	check("33 modules déclarés (%d)" % ids.size(), ids.size() == 33)
	# matériaux de la forêt : ≤ 14, tous enregistrés
	check("≤ 14 matériaux de forêt (%d)" % StyleMaterialsForet.IDS.size(), StyleMaterialsForet.IDS.size() <= 14)
	for m in StyleMaterialsForet.IDS:
		check("matériau %s enregistré" % m, ResourceLoader.exists(StyleMaterials.path_of(m)))
	var stats := {}
	for id in ids:
		var path := "res://assets/stylized/modules/%s.tscn" % id
		check("%s : scène présente" % id, ResourceLoader.exists(path))
		if not ResourceLoader.exists(path):
			continue
		var node := (load(path) as PackedScene).instantiate() as Node3D
		var tris := _tris(node)
		stats[id] = tris
		var budget := 2000
		if id == "arbre_ancien":
			budget = 12000
		elif id in ARBRES:
			budget = 6000
		elif id in PLANTES:
			budget = 600
		elif id in PETITS:
			budget = 2000
		else:
			budget = 5000          # ruines, cadre, pont : ensembles composés (pas de budget imposé par le document)
		if id == "jeune_fille_provisoire":
			budget = 9000          # deux poses (une seule visible)
		check("%s : %d triangles ≤ %d" % [id, tris, budget], tris > 0 and tris <= budget)
		# un matériau partagé (fichier .tres) par surface, jamais deux surfaces identiques dans un même maillage
		var mats_ok := true
		var dup := false
		for mi in node.find_children("*", "MeshInstance3D", true, false):
			var mesh := (mi as MeshInstance3D).mesh
			var seen := {}
			for s in mesh.get_surface_count():
				var mat := mesh.surface_get_material(s)
				if mat == null or not mat.resource_path.begins_with("res://materials/stylized/"):
					mats_ok = false
				elif seen.has(mat.resource_path):
					dup = true
				else:
					seen[mat.resource_path] = true
		check("%s : chaque surface a un matériau partagé" % id, mats_ok)
		check("%s : une seule surface par matériau (maillage fusionné)" % id, not dup)
		# collisions
		var shapes := _shapes(node)
		if id in SOLIDES:
			check("%s : collision présente (%d forme(s))" % [id, shapes], shapes > 0)
		elif id in PLANTES or id in ["arbuste_a", "arbuste_b", "racines_basses", "pierres_plates", "silhouette_ombre", "fleur_lanterne", "jeune_fille_provisoire"]:
			check("%s : aucune collision" % id, shapes == 0)
		# origine au sol (le pont a son origine au niveau de l'eau)
		var bb := _aabb(node)
		check("%s : origine au sol (y min %.2f)" % [id, bb.position.y], bb.position.y > -0.85 and bb.position.y < 0.15)   # bouts de racines enterrés
		node.free()
	# --- gabarits
	var gab := {"arbre_tordu_a": [11.0, 17.0], "arbre_tordu_b": [11.0, 17.0], "arbre_tordu_c": [12.0, 17.0], "arbre_ancien": [13.0, 20.0],
		"tronc_couche": [0.7, 1.4], "ruine_porte_lune": [3.8, 4.6], "ruine_arche": [3.0, 5.0], "silhouette_ombre": [2.4, 3.2], "fleur_lanterne": [1.2, 2.0]}
	for id in gab:
		var n := (load("res://assets/stylized/modules/%s.tscn" % id) as PackedScene).instantiate() as Node3D
		var h := _aabb(n).end.y
		print("  hauteur %s : %.2f m" % [id, h])
		check("%s : hauteur %.2f m dans [%.1f ; %.1f]" % [id, h, gab[id][0], gab[id][1]], h >= gab[id][0] and h <= gab[id][1])
		n.free()
	# tronc couché : 6 m, dessus de collision à ≈ 0,9 m (marchable)
	var tc := (load("res://assets/stylized/modules/tronc_couche.tscn") as PackedScene).instantiate() as Node3D
	var tcb := (tc.find_children("*", "CollisionShape3D", true, false)[0] as CollisionShape3D)
	var tcs := (tcb.shape as BoxShape3D).size
	check("tronc_couche : 6 m de long, dessus plat marchable (%.1f × %.2f)" % [tcs.x, tcb.position.y + tcs.y * 0.5], absf(tcs.x - 6.0) < 0.01 and tcs.z >= 0.6 and absf(tcb.position.y + tcs.y * 0.5 - 0.9) < 0.05)
	tc.free()
	# --- nœuds nommés pour le niveau
	var fl := (load("res://assets/stylized/modules/fleur_lanterne.tscn") as PackedScene).instantiate() as Node3D
	check("fleur_lanterne : Corolle", fl.get_node_or_null("Corolle") is MeshInstance3D)
	var lights := fl.find_children("*", "OmniLight3D", false, false)
	check("fleur_lanterne : OmniLight3D enfant, invisible au départ", lights.size() == 1 and not (lights[0] as OmniLight3D).visible)
	fl.free()
	var pont := (load("res://assets/stylized/modules/pont_racines.tscn") as PackedScene).instantiate() as Node3D
	var nroot := 0
	var z_min := 1e9
	var z_max := -1e9
	for c in pont.get_children():
		if String(c.name).begins_with("Racine_"):
			nroot += 1
			check("%s : pivot avec pose couchée" % c.name, c is Node3D and c.has_meta("pose_couchee"))
			var bb := _aabb(c as Node3D)
			z_min = minf(z_min, (c as Node3D).position.z + bb.position.z)
			z_max = maxf(z_max, (c as Node3D).position.z + bb.end.z)
	check("pont_racines : Racine_1…Racine_N (%d)" % nroot, nroot >= 3)
	check("pont_racines : ≈ 7 m (%.1f)" % (z_max - z_min), absf((z_max - z_min) - 7.0) < 0.8)
	var pc := pont.get_node_or_null("PontCollision") as StaticBody3D
	check("pont_racines : PontCollision, largeur ≥ 1,6 m", pc != null and ((pc.get_child(0) as CollisionShape3D).shape as BoxShape3D).size.x >= 1.6)
	var pw := _aabb(pont.get_node("Racine_2") as Node3D)
	check("pont_racines : largeur visible ≥ 1,6 m (%.2f)" % pw.size.x, pw.size.x >= 1.6)
	pont.free()
	var porte := (load("res://assets/stylized/modules/ruine_porte_lune.tscn") as PackedScene).instantiate() as Node3D
	for v in ["VantailG", "VantailD"]:
		var vn := porte.get_node_or_null(v) as Node3D
		check("ruine_porte_lune : %s (pivot) avec collision" % v, vn != null and _shapes(vn) > 0 and vn.find_children("*", "MeshInstance3D", true, false).size() > 0)
	porte.free()
	var pied := (load("res://assets/stylized/modules/piedestal_lune.tscn") as PackedScene).instantiate() as Node3D
	check("piedestal_lune : nœud Pierre", pied.get_node_or_null("Pierre") is MeshInstance3D)
	pied.free()
	var fille := (load("res://assets/stylized/modules/jeune_fille_provisoire.tscn") as PackedScene).instantiate() as Node3D
	var deb := fille.get_node_or_null("Debout") as Node3D
	var ass := fille.get_node_or_null("Assise") as Node3D
	check("jeune_fille : Debout visible, Assise masquée", deb != null and ass != null and deb.visible and not ass.visible)
	if deb != null:
		var fh := _aabb(deb).end.y
		check("jeune_fille : ≈ 1,35 m debout (%.2f)" % fh, fh > 1.25 and fh < 1.5)
	fille.free()
	var sil := (load("res://assets/stylized/modules/silhouette_ombre.tscn") as PackedScene).instantiate() as Node3D
	var sb := _aabb(sil)
	check("silhouette_ombre : haute et mince (%.1f × %.1f)" % [sb.size.y, sb.size.x], sb.size.y > 2.4 and sb.size.x < 1.2)
	sil.free()
	var cad := (load("res://assets/stylized/modules/cadre_porte_reve.tscn") as PackedScene).instantiate() as Node3D
	var cb := _aabb(cad)
	check("cadre_porte_reve : cadre de porte, racines comprises (%.1f × %.1f)" % [cb.size.x, cb.size.y], cb.size.y > 2.2 and cb.size.y < 3.2 and cb.size.x > 1.2 and cb.size.x < 3.2)
	cad.free()
	# --- pas de hasard à l'exécution, modules à jour (reconstruction identique, deux fois, aux modules enregistrés)
	for path in ["res://scripts/stylized/style_assets_foret.gd", "res://scripts/stylized/style_materials_foret.gd"]:
		var src := FileAccess.get_file_as_string(path)
		check("%s : aucun randf / RandomNumberGenerator / randi" % path.get_file(), not src.contains("randf") and not src.contains("RandomNumberGenerator") and not src.contains("randi"))
	var drift: Array = []
	for id in ids:
		var b1 := StyleAssetsForet.make(id)
		var b2 := StyleAssetsForet.make(id)
		var n1 := b1.build_node()
		var n2 := b2.build_node()
		var same := _tris(n1) == _tris(n2)
		if same:
			var m1 := (n1.find_children("*", "MeshInstance3D", true, false))
			var m2 := (n2.find_children("*", "MeshInstance3D", true, false))
			for i in m1.size():
				for s in (m1[i] as MeshInstance3D).mesh.get_surface_count():
					var v1: PackedVector3Array = (m1[i] as MeshInstance3D).mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
					var v2: PackedVector3Array = (m2[i] as MeshInstance3D).mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
					if v1 != v2:
						same = false
		check("%s : fabrication déterministe" % id, same)
		if stats.has(id) and _tris(n1) != stats[id]:
			drift.append(id)
		n1.free()
		n2.free()
	check("modules enregistrés à jour (écart : %s)" % str(drift), drift.is_empty())
	print("== forêt, kit organique : %d vérifications réussies, %d échec(s)" % [ok, fail])
	quit(1 if fail > 0 else 0)
