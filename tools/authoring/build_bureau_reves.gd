extends SceneTree
## Édition de départ du NOUVEAU Bureau des rêves (3D stylisée) : grand atrium sur deux niveaux, couloir des rêveurs,
## chambre du rêveur. Toutes les positions sont ÉCRITES ICI (mètres) ; aucune génération en jeu.
##   godot --headless -s tools/authoring/build_stylized_assets.gd     (modules, une fois)
##   godot --headless -s tools/authoring/build_bureau_reves.gd
## Écrit scenes/levels/bureau_des_reves.tscn (+ coque : scenes/levels/data/bureau_reves/*.res). Ensuite, la scène .tscn
## est la source de vérité, modifiable à la main dans l'éditeur Godot.
##
## Repère : x vers l'est, z vers le sud, y vers le haut ; sol = 0.
##   Atrium   : intérieur x -15…15, z -13…13, plafond à 20 m ; galeries à 6 m (nord, ouest, est) ; deux escaliers.
##   Couloir  : à l'est de l'atrium, x 15,6…51,6, largeur 6 m (z -3…3), 8 travées de 4,5 m.
##   Chambre  : au nord de la travée 4, x 26,85…35,85, z -11,5…-3,5, plafond à 5 m.

const DATA := "res://scenes/levels/data/bureau_reves/"
const MOD := "res://assets/stylized/modules/"
const CX0 := 15.6                     # début du couloir
const BAY := 4.5
const BAYS := 8

var lvl: Level
var arch: Node3D
var cols: StaticBody3D

func M(n: String) -> Material:
	return StyleMaterials.get_mat(n)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DATA))
	lvl = Level.new()
	lvl.name = "BureauDesReves"
	lvl.level_id = "bureau-des-reves"
	lvl.level_title = "Le Bureau des rêves"
	lvl.level_subtitle = "Grand atrium"
	lvl.lighting_preset = "bureau_nuit"
	lvl.default_spawn = "depart"
	lvl.interior = true
	lvl.first_person = false
	lvl.show_controls_hint = true
	lvl.kill_y = -10.0

	var spawns := _group(lvl, "Spawns")
	_marker(spawns, "depart", Vector3(0, 0.05, 10.5), 0.0)                 # entrée de l'atrium, regard vers le nord
	_marker(spawns, "couloir", Vector3(17.5, 0.05, 0.0), -90.0)           # entrée du couloir, regard vers l'est
	_marker(spawns, "reveil", Vector3(34.3, 0.85, -7.5), 90.0)            # sur le lit du rêveur (retour du rêve)

	arch = _group(lvl, "Architecture")
	cols = StaticBody3D.new()
	cols.name = "Collisions"
	arch.add_child(cols)
	_atrium_shell()
	_corridor_end()
	_room_shell()

	_atrium_modules(_group(lvl, "Atrium"))
	_corridor_modules(_group(lvl, "Couloir"))
	_room_modules(_group(lvl, "Chambre"))
	var lum := _group(lvl, "Lumieres")
	_lights_atrium(lum)
	_lights_couloir_chambre(lum)
	_ambiance(_group(lvl, "Ambiance"))

	_save()

# ================================================================== outils

func _group(parent: Node, nm: String) -> Node3D:
	var g := Node3D.new()
	g.name = nm
	parent.add_child(g)
	return g

func _marker(parent: Node, nm: String, p: Vector3, yaw: float) -> void:
	var m := Marker3D.new()
	m.name = nm
	m.position = p
	m.rotation_degrees = Vector3(0, yaw, 0)
	parent.add_child(m)

## Pièce de coque : boîte arrondie (taille, centre).
func _box(parts: Array, size: Vector3, mat: String, center: Vector3, r := 0.05, rot := Vector3.ZERO) -> void:
	parts.append([StyleKit.rounded_box(size, r, M(mat), 1), ModuleBuilder.at(center, rot)])

func _col(nm: String, size: Vector3, center: Vector3, rot := Vector3.ZERO) -> void:
	var cs := CollisionShape3D.new()
	cs.name = nm
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.transform = ModuleBuilder.at(center, rot)
	cols.add_child(cs)

func _mesh(nm: String, parts: Array, shadows := true) -> void:
	var mesh := StyleKit.merge(parts)
	var path := DATA + nm.to_snake_case() + ".res"
	ResourceSaver.save(mesh, path, ResourceSaver.FLAG_COMPRESS)
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = load(path)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arch.add_child(mi)
	print("coque %-22s %6d triangles" % [nm, StyleKit.triangles(mesh)])

func _inst(parent: Node, id: String, pos: Vector3, yaw := 0.0, nm := "") -> Node3D:
	var n := (load(MOD + id + ".tscn") as PackedScene).instantiate() as Node3D
	n.name = nm if nm != "" else id.to_pascal_case()
	n.position = pos
	n.rotation_degrees = Vector3(0, yaw, 0)
	parent.add_child(n)
	return n

func _door(parent: Node, id: String, pos: Vector3, yaw: float, number: String, locked: bool, msg := "Fermée à clé.") -> Node3D:
	var d := _inst(parent, id, pos, yaw, "Porte_" + number)
	d.set("number", number)
	d.set("locked", locked)
	d.set("locked_message", msg)
	return d

# ================================================================== coque de l'atrium

func _atrium_shell() -> void:
	# --- sol de marbre (4 dalles : les rendus modestes limitent le nombre de lumières par objet)
	var floor_parts := []
	for qx in [-1.0, 1.0]:
		for qz in [-1.0, 1.0]:
			_box(floor_parts, Vector3(15.6, 0.4, 13.6), "marbre_atrium", Vector3(qx * 7.8, -0.2, qz * 6.8), 0.02)
	_mesh("Atrium_Sol", floor_parts, false)
	_col("sol_atrium", Vector3(31.2, 0.4, 27.2), Vector3(0, -0.2, 0))
	# --- murs extérieurs (épaisseur 0,6), mur est percé pour le couloir
	var walls := []
	_box(walls, Vector3(31.2, 20.4, 0.6), "mur_violet", Vector3(0, 10.0, -13.3))
	_box(walls, Vector3(31.2, 20.4, 0.6), "mur_violet", Vector3(0, 10.0, 13.3))
	_box(walls, Vector3(0.6, 20.4, 26.0), "mur_violet", Vector3(-15.3, 10.0, 0))
	_box(walls, Vector3(0.6, 20.4, 10.0), "mur_violet", Vector3(15.3, 10.0, -8.0))
	_box(walls, Vector3(0.6, 20.4, 10.0), "mur_violet", Vector3(15.3, 10.0, 8.0))
	for half in [false, true]:
		var poly := StyleKit.arch_wall_half(6.0, 20.0, 4.6, 5.0, half, 14)
		walls.append([StyleKit.extrude(poly, 0.6, M("mur_violet"), 0.0), Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(15.3, 0, 0))])
	# encadrement de l'arche du couloir (côté atrium)
	walls.append([StyleKit.extrude(StyleKit.arch_frame_outline(4.6, 5.0, 0.4, 20), 0.5, M("pierre_claire"), 0.06), Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(14.95, 0, 0))])
	walls.append([StyleKit.extrude(StyleKit.arch_frame_outline(5.4, 5.4, 0.06, 20), 0.55, M("or"), 0.0), Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(14.95, 0, 0))])
	# soubassements et corniches dorées du rez-de-chaussée et de l'étage
	for spec in [[Vector3(30.0, 1.1, 0.12), Vector3(0, 0.55, -12.95)], [Vector3(30.0, 1.1, 0.12), Vector3(0, 0.55, 12.95)],
			[Vector3(0.12, 1.1, 26.0), Vector3(-14.95, 0.55, 0)], [Vector3(0.12, 1.1, 10.0), Vector3(14.95, 0.55, -8.0)], [Vector3(0.12, 1.1, 10.0), Vector3(14.95, 0.55, 8.0)]]:
		_box(walls, spec[0], "pierre_sombre", spec[1], 0.04)
	for y in [1.15, 18.4]:
		_box(walls, Vector3(30.0, 0.14, 0.2), "or", Vector3(0, y, -12.92), 0.05)
		_box(walls, Vector3(30.0, 0.14, 0.2), "or", Vector3(0, y, 12.92), 0.05)
		_box(walls, Vector3(0.2, 0.14, 26.0), "or", Vector3(-14.92, y, 0), 0.05)
		_box(walls, Vector3(0.2, 0.14, 26.0), "or", Vector3(14.92, y, 0), 0.05)
	for spec in [[Vector3(30.0, 0.5, 0.5), Vector3(0, 18.8, -12.8)], [Vector3(30.0, 0.5, 0.5), Vector3(0, 18.8, 12.8)],
			[Vector3(0.5, 0.5, 26.0), Vector3(-14.8, 18.8, 0)], [Vector3(0.5, 0.5, 26.0), Vector3(14.8, 18.8, 0)]]:
		_box(walls, spec[0], "pierre_claire", spec[1], 0.12)
	_mesh("Atrium_Murs", walls)
	_col("mur_nord", Vector3(31.2, 21.0, 0.6), Vector3(0, 10.0, -13.3))
	_col("mur_sud", Vector3(31.2, 21.0, 0.6), Vector3(0, 10.0, 13.3))
	_col("mur_ouest", Vector3(0.6, 21.0, 26.0), Vector3(-15.3, 10.0, 0))
	_col("mur_est_nord", Vector3(0.6, 21.0, 10.7), Vector3(15.3, 10.0, -8.35))
	_col("mur_est_sud", Vector3(0.6, 21.0, 10.7), Vector3(15.3, 10.0, 8.35))
	_col("mur_est_linteau", Vector3(0.6, 15.0, 6.0), Vector3(15.3, 12.5, 0))
	# --- galeries à 6 m (nord sur toute la largeur, ouest et est jusqu'au mur sud)
	var gal := []
	_box(gal, Vector3(30.0, 0.5, 3.5), "marbre_atrium", Vector3(0, 5.75, -11.25), 0.08)
	_box(gal, Vector3(3.5, 0.5, 22.5), "marbre_atrium", Vector3(-13.25, 5.75, 1.75), 0.08)
	_box(gal, Vector3(3.5, 0.5, 22.5), "marbre_atrium", Vector3(13.25, 5.75, 1.75), 0.08)
	# rives dorées et bandeau sculpté sous les galeries
	_box(gal, Vector3(23.0, 0.12, 0.2), "or", Vector3(0, 5.55, -9.45), 0.05)
	_box(gal, Vector3(0.2, 0.12, 22.5), "or", Vector3(-11.45, 5.55, 1.75), 0.05)
	_box(gal, Vector3(0.2, 0.12, 22.5), "or", Vector3(11.45, 5.55, 1.75), 0.05)
	_box(gal, Vector3(23.0, 0.6, 0.35), "pierre_claire", Vector3(0, 5.25, -9.6), 0.1)
	_box(gal, Vector3(0.35, 0.6, 22.5), "pierre_claire", Vector3(-11.6, 5.25, 1.75), 0.1)
	_box(gal, Vector3(0.35, 0.6, 22.5), "pierre_claire", Vector3(11.6, 5.25, 1.75), 0.1)
	_mesh("Atrium_Galeries", gal)
	_col("galerie_nord", Vector3(30.0, 0.5, 3.5), Vector3(0, 5.75, -11.25))
	_col("galerie_ouest", Vector3(3.5, 0.5, 22.5), Vector3(-13.25, 5.75, 1.75))
	_col("galerie_est", Vector3(3.5, 0.5, 22.5), Vector3(13.25, 5.75, 1.75))
	# garde-corps invisibles aux trouées de la galerie nord (entre les escaliers et les galeries latérales)
	for x in [-11.0, 11.0]:
		_col("garde_corps_%d" % int(x), Vector3(1.0, 1.2, 0.3), Vector3(x, 6.6, -9.4))
	# --- plafond étoilé et poutres
	var ceil := []
	_box(ceil, Vector3(31.2, 0.6, 27.2), "voute_etoilee", Vector3(0, 20.3, 0), 0.05)
	for x in [-9.0, -3.0, 3.0, 9.0]:
		_box(ceil, Vector3(0.6, 0.7, 26.0), "pierre_claire", Vector3(x, 19.65, 0), 0.15)
		_box(ceil, Vector3(0.66, 0.08, 26.0), "or", Vector3(x, 19.3, 0), 0.03)
	for z in [-7.0, 0.0, 7.0]:
		_box(ceil, Vector3(30.0, 0.6, 0.6), "pierre_claire", Vector3(0, 19.7, z), 0.15)
	_box(ceil, Vector3(6.6, 0.3, 6.6), "pierre_claire", Vector3(0, 19.85, 0), 0.12)
	ceil.append([StyleKit.torus(2.6, 0.12, M("or"), 48, 8), ModuleBuilder.at(Vector3(0, 19.6, 0))])
	_mesh("Atrium_Plafond", ceil, false)
	_col("plafond_atrium", Vector3(31.2, 0.6, 27.2), Vector3(0, 20.3, 0))

# ================================================================== fond du couloir

func _corridor_end() -> void:
	var parts := []
	var xe := CX0 + BAY * BAYS
	_box(parts, Vector3(0.6, 11.6, 7.0), "mur_couloir", Vector3(xe + 0.3, 5.6, 0))
	_box(parts, Vector3(0.12, 1.0, 6.0), "pierre_sombre", Vector3(xe - 0.05, 0.5, 0), 0.04)
	_box(parts, Vector3(0.14, 0.16, 6.0), "bois_sombre", Vector3(xe - 0.07, 0.08, 0), 0.03)
	_box(parts, Vector3(0.16, 0.12, 6.0), "or", Vector3(xe - 0.08, 1.02, 0), 0.04)
	# pilastres de l'entrée du couloir (chaque travée ne porte que son pilastre côté est : plus de boîtes confondues)
	parts.append_array(StyleAssetsChambre.corridor_start_parts(CX0))
	_mesh("Couloir_Fond", parts)
	_col("couloir_fond", Vector3(0.6, 12.0, 7.0), Vector3(xe + 0.3, 6.0, 0))

# ================================================================== coque de la chambre

func _room_shell() -> void:
	var x0 := 26.85
	var x1 := 35.85
	var z0 := -11.5
	var z1 := -3.5
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	# la coque (parquet, papier peint, lambris, corniche, plafond à poutres, flaque de lune) est modelée dans StyleAssetsChambre
	_mesh("Chambre_Coque", StyleAssetsChambre.room_shell(x0, x1, z0, z1))
	_col("chambre_sol", Vector3(x1 - x0 + 1.0, 0.4, z1 - z0 + 0.5), Vector3(cx, -0.2, cz - 0.25))
	_col("chambre_ouest", Vector3(0.5, 6.0, z1 - z0 + 1.0), Vector3(x0 - 0.25, 3.0, cz - 0.5))
	_col("chambre_est", Vector3(0.5, 6.0, z1 - z0 + 1.0), Vector3(x1 + 0.25, 3.0, cz - 0.5))
	_col("chambre_nord", Vector3(x1 - x0 + 1.0, 6.0, 0.5), Vector3(cx, 3.0, z0 - 0.25))
	_col("chambre_plafond", Vector3(x1 - x0 + 1.0, 0.4, z1 - z0 + 1.0), Vector3(cx, 5.2, cz - 0.5))

# ================================================================== atrium : modules posés à la main

func _atrium_modules(g: Node3D) -> void:
	# colonnes sous les rives des galeries, arcades entre elles
	var cols_g := _group(g, "Colonnes")
	var north := [-12.0, -3.0, 3.0, 12.0]
	for x in north:
		_inst(cols_g, "colonne", Vector3(x, 0, -9.6), 0.0, "Colonne_N_%d" % int(x))
	for z in [-3.5, 2.5, 8.5]:
		_inst(cols_g, "colonne", Vector3(-11.6, 0, z), 0.0, "Colonne_O_%d" % int(z))
		_inst(cols_g, "colonne", Vector3(11.6, 0, z), 0.0, "Colonne_E_%d" % int(z))
	_inst(cols_g, "arcade", Vector3(0, 0, -9.6), 0.0, "Arcade_N")
	for z in [-0.5, 5.5]:
		_inst(cols_g, "arcade", Vector3(-11.6, 0, z), 90.0, "Arcade_O_%d" % int(z))
		_inst(cols_g, "arcade", Vector3(11.6, 0, z), 90.0, "Arcade_E_%d" % int(z))
	# balustrades des galeries (le long des rives ; trouées laissées aux arrivées d'escalier)
	var bal := _group(g, "Balustrades")
	for x in [-6.0, -3.0, 0.0, 3.0, 6.0]:
		_inst(bal, "balustrade_3m", Vector3(x, 6.0, -9.65), 0.0, "Bal_N_%d" % int(x))
	for z in [-8.0, -5.0, -2.0, 1.0, 4.0, 7.0, 10.0]:
		_inst(bal, "balustrade_3m", Vector3(-11.65, 6.0, z), 90.0, "Bal_O_%d" % int(z))
		_inst(bal, "balustrade_3m", Vector3(11.65, 6.0, z), 90.0, "Bal_E_%d" % int(z))
	# escaliers : pied au sol, arrivée sur la galerie nord
	_inst(g, "escalier_grand", Vector3(-9.0, 0, -1.1), 0.0, "Escalier_Ouest")
	_inst(g, "escalier_grand", Vector3(9.0, 0, -1.1), 0.0, "Escalier_Est")
	# grandes fenêtres de l'étage (paysage nocturne), horloge céleste au nord
	var win := _group(g, "Fenetres")
	for x in [-9.5, 9.5]:
		_inst(win, "fenetre_haute", Vector3(x, 7.4, -13.0), 0.0, "Fenetre_N_%d" % int(x))
		_inst(win, "fenetre_haute", Vector3(x, 7.4, 13.0), 180.0, "Fenetre_S_%d" % int(x))
	for z in [-5.0, 6.0]:
		_inst(win, "fenetre_haute", Vector3(-15.0, 7.4, z), 90.0, "Fenetre_O_%d" % int(z))
		_inst(win, "fenetre_haute", Vector3(15.0, 7.4, z), -90.0, "Fenetre_E_%d" % int(z))
	_inst(g, "horloge_celeste", Vector3(0, 12.2, -13.0), 0.0, "Horloge_Celeste")
	_inst(g, "lustre_astronomique", Vector3(0, 20.0, 0.0), 0.0, "Lustre_Astronomique")
	# réception et arbre de lune
	_inst(g, "bureau_reception", Vector3(0, 0, 0.5), 0.0, "Reception")
	_inst(g, "arbre_de_lune", Vector3(0, 0, -4.2), 0.0, "Arbre_de_lune")
	# portes numérotées du rez-de-chaussée (fermées), porte d'entrée, archives
	var doors := _group(g, "Portes")
	_door(doors, "porte_hotel", Vector3(-15.0, 0, -6.0), 90.0, "1", true)
	_door(doors, "porte_hotel", Vector3(-15.0, 0, 0.0), 90.0, "2", true, "Quelqu'un dort derrière cette porte.")
	_door(doors, "porte_hotel", Vector3(-15.0, 0, 6.0), 90.0, "3", true)
	_door(doors, "porte_hotel", Vector3(15.0, 0, -7.5), -90.0, "4", true)
	_door(doors, "porte_hotel", Vector3(15.0, 0, 7.5), -90.0, "5", true)
	_door(doors, "porte_hotel", Vector3(-6.5, 0, -13.0), 0.0, "6", true, "Les archives sont fermées la nuit.")
	_door(doors, "porte_hotel", Vector3(6.5, 0, -13.0), 0.0, "7", true, "Un murmure… puis plus rien.")
	_inst(doors, "porte_double_entree", Vector3(0, 0, 13.0), 180.0, "Entree")
	# appliques (rez-de-chaussée)
	var sc := _group(g, "Appliques")
	for z in [-9.0, -3.0, 3.0, 9.0]:
		_inst(sc, "applique", Vector3(-15.0, 2.9, z), 90.0, "App_O_%d" % int(z))
	for z in [-10.5, -4.0, 4.0, 10.5]:
		_inst(sc, "applique", Vector3(15.0, 2.9, z), -90.0, "App_E_%d" % int(z))
	for x in [-10.0, -3.2, 3.2, 10.0]:
		_inst(sc, "applique", Vector3(x, 2.9, -13.0), 0.0, "App_N_%d" % int(x))
	for x in [-3.2, 3.2, -9.0, 9.0]:
		_inst(sc, "applique", Vector3(x, 2.9, 13.0), 180.0, "App_S_%d" % int(x))
	# lanternes sous les galeries
	for p in [Vector3(-13.3, 5.5, -11.3), Vector3(13.3, 5.5, -11.3), Vector3(-13.3, 5.5, 11.0), Vector3(13.3, 5.5, 11.0), Vector3(0, 5.5, -11.3)]:
		_inst(sc, "lanterne", p, 0.0, "Lanterne_%d_%d" % [int(p.x), int(p.z)])
	# bannières pendues aux balustrades, glycines aux rives
	var deco := _group(g, "Decor")
	for x in [-1.5, 1.5]:
		_inst(deco, "banniere", Vector3(x, 6.95, -9.45), 0.0, "Banniere_N_%d" % int(x * 10.0))
	for z in [-0.5, 5.5]:
		_inst(deco, "banniere", Vector3(-11.45, 6.95, z), 90.0, "Banniere_O_%d" % int(z))
		_inst(deco, "banniere", Vector3(11.45, 6.95, z), -90.0, "Banniere_E_%d" % int(z))
	for x in [-10.0, -5.5, 5.5, 10.0]:
		_inst(deco, "glycine", Vector3(x, 5.45, -9.5), float(int(x * 37.0) % 360), "Glycine_N_%d" % int(x * 10.0))
	for z in [-6.5, -2.0, 4.0, 11.0]:
		_inst(deco, "glycine", Vector3(-11.5, 5.45, z), float(int(z * 53.0) % 360), "Glycine_O_%d" % int(z * 10.0))
		_inst(deco, "glycine", Vector3(11.5, 5.45, z), float(int(z * 29.0) % 360), "Glycine_E_%d" % int(z * 10.0))
	for p in [Vector3(-8.0, 7.0, -9.55), Vector3(8.0, 7.0, -9.55)]:
		_inst(deco, "glycine", p, 30.0, "Glycine_haut_%d" % int(p.x))
	# mobilier d'apparat
	_inst(deco, "panneau_directions", Vector3(4.6, 0, 8.6), 0.0, "Panneau")
	_inst(deco, "chariot_bagages", Vector3(-5.2, 0, 10.2), 25.0, "Chariot")
	_inst(deco, "table_globe", Vector3(6.8, 0, 3.2), 0.0, "Table_globe_E")
	_inst(deco, "table_globe", Vector3(-6.8, 0, 3.2), 0.0, "Table_globe_O")
	_inst(deco, "banc_velours", Vector3(-13.6, 0, 3.0), 90.0, "Banc_O")
	_inst(deco, "banc_velours", Vector3(13.6, 0, 3.0), -90.0, "Banc_E")
	for p in [Vector3(-13.6, 0, -11.5), Vector3(13.6, 0, -11.5), Vector3(-13.6, 0, 11.6), Vector3(13.6, 0, 11.6), Vector3(-3.0, 0, 11.8), Vector3(3.0, 0, 11.8)]:
		_inst(deco, "jardiniere", p, 0.0, "Jardiniere_%d_%d" % [int(p.x), int(p.z)])

# ================================================================== couloir des rêveurs

func _corridor_modules(g: Node3D) -> void:
	var bays := _group(g, "Travees")
	var doors := _group(g, "Portes")
	var sc := _group(g, "Appliques")
	var deco := _group(g, "Decor")
	for i in BAYS:
		var cx := CX0 + BAY * (i + 0.5)
		var open := i == 3
		_inst(bays, "travee_couloir_ouverte" if open else "travee_couloir", Vector3(cx, 0, 0), 0.0, "Travee_%d" % (i + 1))
		var n_north := str(101 + 2 * i)
		var n_south := str(102 + 2 * i)
		if open:
			var d := _door(doors, "porte_chambre", Vector3(cx, 0, -2.95), 0.0, n_north, false)
			d.set("prompt", "Entrer dans la chambre %s" % n_north)
		else:
			_door(doors, "porte_hotel", Vector3(cx, 0, -2.95), 0.0, n_north, true, ["Fermée à clé.", "Un rêveur dort ici.", "On entend une boîte à musique…"][i % 3])
		_door(doors, "porte_hotel", Vector3(cx, 0, 2.95), 180.0, n_south, true, ["Fermée à clé.", "« Ne pas déranger »", "Fermée à clé."][i % 3])
		# balcons : balustrades, bannières au-dessus des portes, glycines une travée sur deux
		_inst(deco, "balustrade_4_5m", Vector3(cx, 4.62, -1.95), 0.0, "Balcon_N_%d" % (i + 1))
		_inst(deco, "balustrade_4_5m", Vector3(cx, 4.62, 1.95), 180.0, "Balcon_S_%d" % (i + 1))
		_inst(deco, "banniere", Vector3(cx, 7.6, -2.95), 0.0, "Banniere_N_%d" % (i + 1))
		_inst(deco, "banniere", Vector3(cx, 7.6, 2.95), 180.0, "Banniere_S_%d" % (i + 1))
		if i % 2 == 0:
			_inst(deco, "glycine", Vector3(cx - 1.2, 4.25, -1.95), 20.0 * i, "Glycine_N_%d" % (i + 1))
			_inst(deco, "glycine", Vector3(cx + 1.3, 4.25, 1.95), 15.0 * i + 90.0, "Glycine_S_%d" % (i + 1))
	# appliques sur les pilastres (limites de travées)
	for k in range(1, BAYS):
		var x := CX0 + BAY * k
		_inst(sc, "applique", Vector3(x, 2.9, -2.7), 0.0, "App_N_%d" % k)
		_inst(sc, "applique", Vector3(x, 2.9, 2.7), 180.0, "App_S_%d" % k)
	# fond du couloir : grande fenêtre de lune, banc, jardinières
	var xe := CX0 + BAY * BAYS
	_inst(deco, "fenetre_haute", Vector3(xe, 0.9, 0), -90.0, "Fenetre_fond")
	_inst(deco, "banc_velours", Vector3(xe - 1.6, 0, 0), -90.0, "Banc_fond")
	_inst(deco, "jardiniere", Vector3(xe - 0.9, 0, -2.2), 0.0, "Jardiniere_fond_N")
	_inst(deco, "jardiniere", Vector3(xe - 0.9, 0, 2.2), 0.0, "Jardiniere_fond_S")
	_inst(deco, "chariot_bagages", Vector3(CX0 + 7.0, 0, 2.0), -80.0, "Chariot_couloir")
	_inst(deco, "table_globe", Vector3(CX0 + 25.0, 0, 2.25), 0.0, "Table_globe_couloir")
	# --- finition : chemin de tapis, tableaux, consoles, objets laissés devant les portes (variations déterministes par travée)
	var fin := _group(g, "Finition")
	for i in BAYS:
		var cx := CX0 + BAY * (i + 0.5)
		_inst(fin, "tapis_couloir", Vector3(cx, 0, 0), 0.0, "Tapis_%d" % (i + 1))
	# plan des murs : [côté (-1 nord, +1 sud), côté de la porte (-1 gauche, +1 droite), élément]
	var plan := [
		[[-1, -1, "tv"], [-1, 1, "ch"], [1, -1, "pp"], [1, 1, "tp"]],
		[[-1, -1, "tp"], [-1, 1, "to"], [1, -1, "tv"], [1, 1, "cv"]],
		[[-1, -1, "cv"], [-1, 1, "tv"], [1, -1, "ch"], [1, 1, "to"]],
		[[-1, -1, "tp"], [-1, 1, "to"], [1, -1, "tv"], [1, 1, "pp"]],
		[[-1, -1, "cv"], [-1, 1, "tp"], [1, -1, "to"], [1, 1, "tv"]],
		[[-1, -1, "to"], [-1, 1, "tv"], [1, -1, "ch"], [1, 1, "cv"]],
		[[-1, -1, "pp"], [-1, 1, "tp"], [1, -1, "tv"], [1, 1, "ch"]],
		[[-1, -1, "tv"], [-1, 1, "cv"], [1, -1, "tp"], [1, 1, "to"]],
	]
	var painting := {"tp": "tableau_paysage", "tv": "tableau_vertical", "to": "tableau_ovale"}
	for i in BAYS:
		var cx := CX0 + BAY * (i + 0.5)
		for e in plan[i]:
			var side: float = e[0]
			var x: float = cx + 1.52 * e[1]
			var yaw := 0.0 if side < 0.0 else 180.0
			var nm := "%s_%d_%s%d" % [e[2], i + 1, "N" if side < 0.0 else "S", 1 if e[1] < 0 else 2]
			match e[2]:
				"cv":
					_inst(fin, "console_vase", Vector3(x, 0, side * 2.8), yaw, "Console_" + nm)
					_inst(fin, "tableau_ovale", Vector3(x, 2.15, side * 2.995), yaw, "Tableau_" + nm)
				"ch":
					_inst(fin, "console_horloge", Vector3(x, 0, side * 2.8), yaw, "Console_" + nm)
					_inst(fin, "tableau_paysage", Vector3(x, 2.1, side * 2.995), yaw, "Tableau_" + nm).scale = Vector3(0.74, 0.74, 0.74)
				"pp":
					_inst(fin, "porte_parapluie", Vector3(x, 0, side * 2.8), yaw, "Parapluies_" + nm)
					_inst(fin, "tableau_vertical", Vector3(x, 2.15, side * 2.995), yaw, "Tableau_" + nm)
				"tp":
					_inst(fin, "tableau_paysage", Vector3(x, 2.05, side * 2.995), yaw, "Tableau_" + nm).scale = Vector3(0.74, 0.74, 0.74)
				_:
					_inst(fin, painting[e[2]], Vector3(x, 2.05, side * 2.995), yaw, "Tableau_" + nm)
	# objets devant les portes : [travée, côté, objet]  (souliers, plateau de room-service, carton « ne pas déranger »)
	for e in [[0, 1, "sho"], [1, -1, "plat"], [1, 1, "nd"], [2, -1, "sho"], [4, 1, "plat"], [4, -1, "nd"], [5, -1, "sho"], [6, 1, "sho"], [7, -1, "plat"]]:
		var cx: float = CX0 + BAY * (float(e[0]) + 0.5)
		var side: float = e[1]
		match e[2]:
			"sho":
				_inst(fin, "chaussures_porte", Vector3(cx - 0.35 * side, 0, side * 2.5), 0.0 if side > 0.0 else 180.0, "Souliers_%d_%s" % [e[0] + 1, "N" if side < 0.0 else "S"])
			"plat":
				_inst(fin, "plateau_service", Vector3(cx + 0.45 * side, 0, side * 2.45), 25.0, "Plateau_%d_%s" % [e[0] + 1, "N" if side < 0.0 else "S"])
			"nd":
				# accroché au levier (côté couloir) : repère de la porte, levier à 0,53 m du pivot, 1,1 m de haut
				_inst(fin, "carton_nd", Vector3(cx + 0.53 * (1.0 if side < 0.0 else -1.0), 1.11, side * 2.95 - side * 0.2), 0.0 if side < 0.0 else 180.0, "Carton_ND_%d_%s" % [e[0] + 1, "N" if side < 0.0 else "S"])

# ================================================================== chambre du rêveur

func _room_modules(g: Node3D) -> void:
	var cx := 31.35
	_inst(g, "fenetre_chambre", Vector3(cx, 1.0, -11.5), 0.0, "Fenetre")
	_inst(g, "rideaux_fenetre", Vector3(cx, 0, -11.5), 0.0, "Rideaux")
	_inst(g, "banquette_fenetre", Vector3(cx, 0, -11.5), 0.0, "Banquette_fenetre")
	_inst(g, "lit_reveur", Vector3(34.5, 0, -7.5), -90.0, "Lit")
	_inst(g, "mobile_etoiles", Vector3(34.5, 2.85, -7.5), 0.0, "Mobile")
	_inst(g, "table_chevet", Vector3(35.45, 0, -5.95), -90.0, "Chevet_S")
	_inst(g, "table_chevet", Vector3(35.45, 0, -9.05), -90.0, "Chevet_N")
	_inst(g, "armoire", Vector3(27.25, 0, -9.4), 90.0, "Armoire")
	_inst(g, "etagere_livres", Vector3(27.12, 0, -5.9), 90.0, "Etagere")
	_inst(g, "bureau_ecriture", Vector3(28.3, 0, -11.1), 0.0, "Bureau")
	_inst(g, "chaise_bureau", Vector3(28.45, 0, -10.2), 172.0, "Chaise_bureau")
	_inst(g, "fauteuil", Vector3(33.7, 0, -10.2), -40.0, "Fauteuil")
	_inst(g, "lampe_sur_pied", Vector3(34.85, 0, -10.95), 0.0, "Lampe_fauteuil")
	_inst(g, "tapis_rond", Vector3(31.0, 0.0, -7.2), 0.0, "Tapis")
	_inst(g, "banc_velours", Vector3(32.75, 0, -7.5), 90.0, "Banc_pied_de_lit")
	_inst(g, "pantoufles", Vector3(33.95, 0, -6.2), -25.0, "Pantoufles")
	_inst(g, "lanterne", Vector3(31.0, 5.0, -7.2), 0.0, "Lanterne")
	_inst(g, "banniere", Vector3(26.9, 4.3, -7.6), 90.0, "Banniere")
	# mur de la porte (sud) : miroir sur sa console, tableau sur la pendulette (le dos des objets contre le papier peint à z = -3,56)
	_inst(g, "console_vase", Vector3(28.6, 0, -3.56), 180.0, "Console_miroir")
	_inst(g, "miroir_mural", Vector3(28.6, 2.5, -3.56), 180.0, "Miroir")
	_inst(g, "console_horloge", Vector3(33.6, 0, -3.56), 180.0, "Console_pendulette")
	_inst(g, "tableau_paysage", Vector3(33.6, 2.95, -3.56), 180.0, "Tableau_porte")
	# autres murs : tableaux dans leurs cadres moulurés
	_inst(g, "tableau_paysage", Vector3(34.3, 2.95, -11.5), 0.0, "Tableau_fauteuil")
	_inst(g, "tableau_ovale", Vector3(28.1, 3.05, -11.5), 0.0, "Tableau_bureau")
	_inst(g, "tableau_vertical", Vector3(35.84, 2.9, -4.55), -90.0, "Tableau_est")
	_inst(g, "tableau_ovale", Vector3(26.86, 3.65, -5.9), 90.0, "Tableau_ouest")
	# le lit : s'endormir pour entrer dans le rêve (forêt nocturne)
	var bed := DreamBed.new()
	bed.name = "Lit_du_reveur"
	bed.position = Vector3(34.5, 0, -7.5)
	bed.reach = 3.0
	bed.dream_scene = "res://scenes/levels/foret_nocturne.tscn"
	bed.dream_spawn = "depart"
	g.add_child(bed)
	var lie := Marker3D.new()
	lie.name = "Coucher"
	lie.position = Vector3(-0.2, 0.85, 0.0)
	lie.rotation_degrees = Vector3(0, 90, 0)
	bed.add_child(lie)

# ================================================================== lumières d'ambiance (clair de lune)

func _lights_atrium(g: Node3D) -> void:
	var moon := Color("#b9a8ff")
	# rayons de lune tombant des grandes fenêtres du nord et du sud (sans ombres : efficaces)
	for spec in [[Vector3(-9.5, 13.0, -11.0), Vector3(-50, 0, 0)], [Vector3(9.5, 13.0, -11.0), Vector3(-50, 0, 0)],
			[Vector3(-9.5, 13.0, 11.0), Vector3(-50, 180, 0)], [Vector3(9.5, 13.0, 11.0), Vector3(-50, 180, 0)]]:
		var s := SpotLight3D.new()
		s.name = "Clair_de_lune_%d_%d" % [int(spec[0].x), int(spec[0].z)]
		s.position = spec[0]
		s.rotation_degrees = spec[1]
		s.light_color = moon
		s.light_energy = 2.2
		s.spot_range = 22.0
		s.spot_angle = 24.0
		s.spot_angle_attenuation = 0.5
		g.add_child(s)
	# lueur froide des fenêtres de l'étage (remplissage des galeries)
	for p in [Vector3(-13.0, 9.5, -4.0), Vector3(13.0, 9.5, 5.0)]:
		var o := OmniLight3D.new()
		o.name = "Lueur_fenetres_%d" % int(p.x)
		o.position = p
		o.light_color = moon
		o.light_energy = 1.0
		o.omni_range = 11.0
		g.add_child(o)
	# lueurs chaudes au pied des colonnes (dorures et marbre réchauffés, sans ombres)
	var warm := Color("#ffae62")
	for p in [Vector3(-12.0, 1.4, -8.6), Vector3(-3.0, 1.4, -8.6), Vector3(3.0, 1.4, -8.6), Vector3(12.0, 1.4, -8.6),
			Vector3(-10.6, 1.4, -3.5), Vector3(-10.6, 1.4, 2.5), Vector3(-10.6, 1.4, 8.5), Vector3(10.6, 1.4, -3.5), Vector3(10.6, 1.4, 2.5), Vector3(10.6, 1.4, 8.5)]:
		var o := OmniLight3D.new()
		o.name = "Lueur_colonne_%d_%d" % [int(p.x), int(p.z)]
		o.position = p
		o.light_color = warm
		o.light_energy = 0.9
		o.omni_range = 4.5
		g.add_child(o)
# ================================================================== lumières du couloir et de la chambre

func _lights_couloir_chambre(g: Node3D) -> void:
	var moon := Color("#b9a8ff")
	# fond du couloir et chambre : lune
	for spec in [[Vector3(CX0 + BAY * BAYS - 1.5, 5.0, 0.0), 1.4, 10.0, "Lune_fond_couloir"], [Vector3(31.35, 2.6, -10.3), 1.3, 7.0, "Lune_chambre"]]:
		var o := OmniLight3D.new()
		o.name = spec[3]
		o.position = spec[0]
		o.light_color = moon
		o.light_energy = spec[1]
		o.omni_range = spec[2]
		g.add_child(o)

# ================================================================== ambiance : particules et mouvements discrets

func _ambiance(g: Node3D) -> void:
	pass

# ================================================================== enregistrement

func _own(n: Node) -> void:
	for c in n.get_children():
		c.owner = lvl
		if c.scene_file_path == "":
			_own(c)

func _save() -> void:
	_own(lvl)
	var packed := PackedScene.new()
	packed.pack(lvl)
	var err := ResourceSaver.save(packed, "res://scenes/levels/bureau_des_reves.tscn")
	print("scène enregistrée : bureau_des_reves.tscn (%s)" % ("ok" if err == OK else "ERREUR %d" % err))
	lvl.free()
	quit()
