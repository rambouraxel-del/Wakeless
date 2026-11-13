extends SceneTree
## Galerie du kit organique provisoire de la Forêt de la peur : tous les modules en rangées sur un sol sombre, éclairage de
## nuit simple (préréglage « foret_nuit ») ; sert aux captures de contrôle (docs/captures/foret/kit/).
##   godot --headless -s tools/authoring/build_stylized_assets.gd -- <ids du kit>     (fabrique d'abord les modules)
##   godot --headless -s tools/authoring/build_foret_kit_galerie.gd                   → scenes/tests/foret_kit_galerie.tscn
## Positions écrites à la main : x le long de la rangée, z = numéro de rangée.

# [id, x, z, rotation (°)]
const LAYOUT := [
	# arbres (rangée du fond)
	["arbre_tordu_a", -22.0, -30.0, 0], ["arbre_tordu_b", -8.0, -30.0, 40], ["arbre_tordu_c", 8.0, -30.0, 90],
	["arbre_echasses", 24.0, -30.0, 0], ["arbre_mort", 38.0, -30.0, 120], ["arbre_ancien", 62.0, -34.0, 0], ["arbre_lointain_a", -34.0, -30.0, 0], ["arbre_lointain_b", -44.0, -30.0, 0],
	# bois au sol et racines
	["tronc_couche", -22.0, -14.0, 0], ["souche", -14.0, -14.0, 0], ["racines_arche", -6.0, -14.0, 0], ["racines_basses", 4.0, -14.0, 0],
	# pierre
	["rocher_a", 12.0, -14.0, 0], ["rocher_b", 16.0, -14.0, 0], ["rocher_c", 22.0, -14.0, 0],
	["pierres_plates", 30.0, -14.0, 0], ["cercle_pierres", 42.0, -14.0, 0],
	# plantes et lueurs
	["arbuste_a", -22.0, 0.0, 0], ["arbuste_b", -18.0, 0.0, 0], ["fougere", -14.0, 0.0, 0], ["herbes_touffe", -11.0, 0.0, 0],
	["roseaux", -8.0, 0.0, 0], ["champignons_lumineux", -5.0, 0.0, 0], ["nenuphars", -2.0, 0.0, 0], ["fleurs_blanches", 1.0, 0.0, 0],
	["fleur_lanterne", 5.0, 0.0, 0],
	# ruines
	["ruine_arche", 14.0, 0.0, 0], ["ruine_colonne", 22.0, 0.0, 0], ["ruine_mur", 29.0, 0.0, 0],
	["ruine_porte_lune", 38.0, 0.0, 0], ["piedestal_lune", 46.0, 0.0, 0],
	# mise en scène
	["cadre_porte_reve", -22.0, 14.0, 0], ["pont_racines", -12.0, 14.0, 90], ["silhouette_ombre", -4.0, 14.0, 0],
	["jeune_fille_provisoire", 0.0, 14.0, 0],
]

func _initialize() -> void:
	var root := Level.new()
	root.name = "ForetKitGalerie"
	root.level_id = "foret-kit-galerie"
	root.lighting_preset = "foret_peur"
	root.default_spawn = "depart"
	root.kill_y = -50.0
	var spawns := AuthorKit.group(root, "Spawns")
	AuthorKit.marker(spawns, "depart", Vector3(0, 0.05, 60.0), 0.0)
	# sol sombre
	var ground := MeshInstance3D.new()
	ground.name = "Sol"
	var pm := PlaneMesh.new()
	pm.size = Vector2(240.0, 140.0)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#161e2b")
	gm.roughness = 1.0
	pm.material = gm
	ground.position = Vector3(20.0, 0.0, -10.0)
	root.add_child(ground)
	var body := StaticBody3D.new()
	body.name = "SolCollision"
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(240.0, 1.0, 140.0)
	cs.shape = bs
	cs.position = Vector3(20.0, -0.5, -10.0)
	body.add_child(cs)
	root.add_child(body)
	var decor := AuthorKit.group(root, "Modules")
	var missing := 0
	for e in LAYOUT:
		var packed := load("res://assets/stylized/modules/%s.tscn" % e[0]) as PackedScene
		if packed == null:
			push_error("module introuvable : %s" % e[0])
			missing += 1
			continue
		var n := packed.instantiate() as Node3D
		n.name = String(e[0]).to_pascal_case()
		n.position = Vector3(e[1], 0.0, e[2])
		n.rotation_degrees = Vector3(0, e[3], 0)
		decor.add_child(n)
	# la jeune fille en pose assise (pour la contrôler de près) : copie à plat du maillage de la pose « Assise »
	var as_packed := load("res://assets/stylized/modules/jeune_fille_provisoire.tscn") as PackedScene
	if as_packed != null:
		var src := as_packed.instantiate()
		var mi := (src.get_node("Assise/MaillageAssise") as MeshInstance3D).duplicate() as MeshInstance3D
		mi.name = "JeuneFilleAssise"
		mi.position = Vector3(3.0, 0.0, 14.0)
		decor.add_child(mi)
		src.free()
	AuthorKit.save_scene(root, "res://scenes/tests/foret_kit_galerie.tscn")
	root.free()
	quit(1 if missing > 0 else 0)
