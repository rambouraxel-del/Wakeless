extends SceneTree
## Édition de départ du niveau « Bureau des rêves » : couloir d'hôtel + chambre + porte vers la forêt.
##   godot --headless -s tools/authoring/build_bureau.gd
## Écrit scenes/levels/bureau_couloir.tscn et cuit l'architecture (scenes/levels/data/bureau_couloir.scn).
## Toutes les positions sont explicites (mètres, grille de 10 cm) ; aucune graine, aucun hasard.
## Une fois la scène enregistrée, elle se modifie à la main dans l'éditeur Godot (voir docs/NIVEAUX.md).
##
## Repère : x vers l'est (le couloir s'étend de 0 à 26), z vers le sud, y vers le haut ; sol = 0.
## Couloir : intérieur x 0…26, z -1,5…1,5, hauteur 3,2. Chambre : au nord, x 7,5…13,5, z -7,5…-1,8.

const L := 26.0                                   # longueur utile du couloir

var arch: VoxelStructure

func _initialize() -> void:
	VoxelMesher.palette_warmup()
	var root := Level.new()
	root.name = "BureauCouloir"
	root.level_id = "bureau-couloir"
	root.level_title = "Le Bureau des rêves"
	root.level_subtitle = "Couloir du troisième étage"
	root.lighting_preset = "hotel_reve"
	root.default_spawn = "depart"
	root.interior = true
	root.show_controls_hint = true

	var spawns := AuthorKit.group(root, "Spawns")
	AuthorKit.marker(spawns, "depart", Vector3(2.2, 0.05, 0.0), -90.0)               # regarde vers l'est, le long du couloir
	AuthorKit.marker(spawns, "retour_foret", Vector3(24.4, 0.05, 0.0), 90.0)         # sortie de la porte du rêve, regarde vers l'ouest

	arch = VoxelStructure.new()
	arch.name = "Architecture"
	arch.baked_path = "res://scenes/levels/data/bureau_couloir.scn"
	root.add_child(arch)
	_shell(AuthorKit.group(arch, "Coque"))
	_floor(AuthorKit.group(arch, "Sols"))
	_trim(AuthorKit.group(arch, "Moulures"))
	_paintings(AuthorKit.group(arch, "Tableaux"))
	_openings(AuthorKit.group(arch, "Ouvertures"))
	_bedroom(AuthorKit.group(arch, "Chambre"))
	_end_door_niche(AuthorKit.group(arch, "Porte_du_reve_niche"))
	_west_window(AuthorKit.group(arch, "Fenetre_ouest"))
	if not arch.bake():
		push_error("Cuisson de l'architecture impossible")
		quit(1)
		return
	print("architecture : %d cellules pleines, %d triangles, %d boîtes" % [arch.stats["cells"], arch.stats["triangles"], arch.stats["boxes"]])

	var decor := AuthorKit.group(root, "Decor")
	_furniture(decor)
	_lights(AuthorKit.group(root, "Lumieres"))
	_motes(decor)
	_doors(AuthorKit.group(root, "Portes"))

	AuthorKit.save_scene(root, "res://scenes/levels/bureau_couloir.tscn")
	root.free()
	quit(0)

# ------------------------------------------------------------------ coque

func _shell(g: Node3D) -> void:
	AuthorKit.box(g, "mur_nord", Vector3(-0.3, -0.3, -1.8), Vector3(L + 0.6, 3.8, 0.3), "wallpaper_teal")
	AuthorKit.box(g, "mur_sud", Vector3(-0.3, -0.3, 1.5), Vector3(L + 0.6, 3.8, 0.3), "wallpaper_teal")
	AuthorKit.box(g, "mur_ouest", Vector3(-0.3, -0.3, -1.8), Vector3(0.3, 3.8, 3.6), "wallpaper_teal")
	AuthorKit.box(g, "mur_est", Vector3(L, -0.3, -1.8), Vector3(0.3, 3.8, 3.6), "wallpaper_teal")
	AuthorKit.box(g, "plafond", Vector3(-0.3, 3.2, -1.8), Vector3(L + 0.6, 0.3, 3.6), "ceiling_dark")

# ------------------------------------------------------------------ sols

func _floor(g: Node3D) -> void:
	AuthorKit.box(g, "dalle", Vector3(-0.3, -0.3, -1.8), Vector3(L + 0.6, 0.2, 3.6), "marble_black")
	# bandes latérales : dalles de marbre alternées (1,0 × 0,6 m)
	var i := 0
	for x in range(0, int(L)):
		var m := "marble_cream" if (x % 2) == 0 else "marble_black"
		AuthorKit.box(g, "dalle_nord_%d" % i, Vector3(float(x), -0.1, -1.5), Vector3(1.0, 0.1, 0.6), m)
		AuthorKit.box(g, "dalle_sud_%d" % i, Vector3(float(x), -0.1, 0.9), Vector3(1.0, 0.1, 0.6), "marble_black" if (x % 2) == 0 else "marble_cream")
		i += 1
	# chemin de moquette lie-de-vin bordé de doré
	AuthorKit.box(g, "moquette_bord_nord", Vector3(0.0, -0.1, -0.9), Vector3(L, 0.1, 0.2), "carpet_gold")
	AuthorKit.box(g, "moquette_bord_sud", Vector3(0.0, -0.1, 0.7), Vector3(L, 0.1, 0.2), "carpet_gold")
	AuthorKit.box(g, "moquette", Vector3(0.0, -0.1, -0.7), Vector3(L, 0.1, 1.4), "carpet_wine")

# ------------------------------------------------------------------ moulures, pilastres, poutres

func _trim(g: Node3D) -> void:
	# nord : face intérieure z = -1,5 (moulures vers +z) ; sud : face intérieure z = 1,5 (moulures vers -z)
	for side in [["nord", -1.5, -1.5], ["sud", 1.4, 1.3]]:
		var nm: String = side[0]
		var z1: float = side[1]                              # coin z minimal d'une moulure de 0,1 m
		var z2: float = side[2]                              # coin z minimal d'une moulure de 0,2 m
		AuthorKit.box(g, "soubassement_" + nm, Vector3(0.0, 0.0, z1), Vector3(L, 1.0, 0.1), "wood_dark")
		AuthorKit.box(g, "plinthe_" + nm, Vector3(0.0, 0.0, z2), Vector3(L, 0.2, 0.2), "wood_dark")
		AuthorKit.box(g, "lisse_" + nm, Vector3(0.0, 1.0, z2), Vector3(L, 0.1, 0.2), "wood_honey")
		AuthorKit.box(g, "filet_" + nm, Vector3(0.0, 2.4, z1), Vector3(L, 0.1, 0.1), "wallpaper_stripe")
		AuthorKit.box(g, "corniche_" + nm, Vector3(0.0, 3.0, z2), Vector3(L, 0.2, 0.2), "plaster_cream")
	# pilastres de bois et poutres de plafond (mêmes abscisses : le rythme du couloir)
	for k in [1.5, 4.6, 8.0, 12.0, 15.0, 17.6, 23.0]:
		var nm := "%d" % roundi(k * 10.0)
		AuthorKit.box(g, "pilastre_nord_" + nm, Vector3(k, 0.2, -1.5), Vector3(0.3, 2.8, 0.2), "wood_dark")
		AuthorKit.box(g, "pilastre_sud_" + nm, Vector3(k, 0.2, 1.3), Vector3(0.3, 2.8, 0.2), "wood_dark")
		AuthorKit.box(g, "poutre_" + nm, Vector3(k, 2.9, -1.5), Vector3(0.3, 0.3, 3.0), "wood_dark")
		AuthorKit.box(g, "poutre_filet_" + nm, Vector3(k + 0.1, 2.8, -1.5), Vector3(0.1, 0.1, 3.0), "wallpaper_stripe")
	# appliques : platine de laiton, verre de lanterne, chapeau (les lumières sont dans _lights)
	for k in [4.6, 8.0, 12.0, 17.6, 23.0]:
		var nm := "%d" % roundi(k * 10.0)
		AuthorKit.box(g, "applique_n_" + nm + "_pied", Vector3(k + 0.1, 1.8, -1.3), Vector3(0.1, 0.1, 0.1), "brass")
		AuthorKit.box(g, "applique_n_" + nm + "_verre", Vector3(k + 0.1, 1.9, -1.3), Vector3(0.1, 0.3, 0.1), "lamp_warm")
		AuthorKit.box(g, "applique_n_" + nm + "_cap", Vector3(k + 0.1, 2.2, -1.3), Vector3(0.1, 0.1, 0.1), "brass")
		AuthorKit.box(g, "applique_s_" + nm + "_pied", Vector3(k + 0.1, 1.8, 1.2), Vector3(0.1, 0.1, 0.1), "brass")
		AuthorKit.box(g, "applique_s_" + nm + "_verre", Vector3(k + 0.1, 1.9, 1.2), Vector3(0.1, 0.3, 0.1), "lamp_warm")
		AuthorKit.box(g, "applique_s_" + nm + "_cap", Vector3(k + 0.1, 2.2, 1.2), Vector3(0.1, 0.1, 0.1), "brass")

# ------------------------------------------------------------------ tableaux

func _paintings(g: Node3D) -> void:
	# [mur, x, matière du ciel, matière du sol]
	var north := [[5.2, "fabric_blue", "moss_dark"], [13.2, "velvet_plum", "iron_dark"], [18.4, "fabric_teal", "leaf_dark"]]
	var south := [[2.5, "fabric_teal", "moss_dark"], [9.4, "wallpaper_teal_dark", "velvet_plum"], [15.9, "fabric_blue", "iron_dark"], [21.0, "velvet_plum", "leaf_dark"], [23.6, "fabric_teal", "iron_dark"]]
	var n := 0
	for p in north:
		_painting(g, "tn%d" % n, -1, p[0], p[1], p[2])
		n += 1
	for p in south:
		_painting(g, "ts%d" % n, 1, p[0], p[1], p[2])
		n += 1

## Cadre doré en saillie, toile en retrait (ciel, sol, petite lune).
func _painting(g: Node3D, nm: String, side: int, x: float, sky: String, ground: String) -> void:
	var w := 1.2
	var y := 1.4
	var h := 0.9
	var z0 := -1.5 if side < 0 else 1.3                      # coin z minimal du cadre (0,2 m d'épaisseur)
	var zc := -1.5 if side < 0 else 1.4                      # plan de la toile (0,1 m contre le mur)
	AuthorKit.box(g, nm + "_cadre", Vector3(x, y, z0), Vector3(w, h, 0.2), "gold")
	AuthorKit.box(g, nm + "_ciel", Vector3(x + 0.1, y + 0.1, zc), Vector3(w - 0.2, h - 0.2, 0.1), sky)
	AuthorKit.box(g, nm + "_sol", Vector3(x + 0.1, y + 0.1, zc), Vector3(w - 0.2, 0.3, 0.1), ground)
	AuthorKit.box(g, nm + "_lune", Vector3(x + w - 0.5, y + h - 0.4, zc), Vector3(0.2, 0.2, 0.1), "crystal_ice")
	AuthorKit.carve(g, nm + "_creux", Vector3(x + 0.1, y + 0.1, -1.4 if side < 0 else 1.3), Vector3(w - 0.2, h - 0.2, 0.1))

# ------------------------------------------------------------------ portes : ouvertures et cadres

func _openings(g: Node3D) -> void:
	# Portes du nord (charnière à gauche de l'ouverture, battant de 1,0 m vers l'est) : 3 fermées + la chambre.
	for h in [3.0, 10.0, 16.0, 21.0]:
		var nm := "n%d" % roundi(h * 10.0)
		var chambre: bool = (h == 10.0)
		# fermées : niche de 0,3 m (reste 0,1 m de mur derrière) ; chambre : percée complète
		AuthorKit.carve(g, "ouv_" + nm, Vector3(h, 0.0, -1.8 if chambre else -1.7), Vector3(1.0, 2.2, 0.5 if chambre else 0.4))
		_frame_north(g, nm, h)
	# Portes du sud (charnière à droite, battant vers l'ouest) : toutes fermées, ouvertures [x, x+1]
	for h in [6.5, 13.5, 19.0]:
		var nm := "s%d" % roundi(h * 10.0)
		AuthorKit.carve(g, "ouv_" + nm, Vector3(h, 0.0, 1.3), Vector3(1.0, 2.2, 0.4))
		_frame_south(g, nm, h)
	# seuils lumineux : la lumière du rêve filtre sous les portes fermées (plaque à fleur de sol)
	for h in [3.0, 16.0, 21.0]:
		AuthorKit.box(g, "seuil_n%d" % roundi(h * 10.0), Vector3(h + 0.1, -0.1, -1.5), Vector3(0.8, 0.1, 0.1), "dream_glow")
	for h in [6.5, 13.5, 19.0]:
		AuthorKit.box(g, "seuil_s%d" % roundi(h * 10.0), Vector3(h + 0.1, -0.1, 1.4), Vector3(0.8, 0.1, 0.1), "dream_glow")
	AuthorKit.box(g, "seuil_chambre", Vector3(10.0, -0.1, -1.8), Vector3(1.0, 0.1, 0.4), "wood_honey")

func _frame_north(g: Node3D, nm: String, h: float) -> void:
	AuthorKit.box(g, "cadre_g_" + nm, Vector3(h - 0.2, 0.0, -1.5), Vector3(0.2, 2.4, 0.2), "wood_honey")
	AuthorKit.box(g, "cadre_d_" + nm, Vector3(h + 1.0, 0.0, -1.5), Vector3(0.2, 2.4, 0.2), "wood_honey")
	AuthorKit.box(g, "cadre_h_" + nm, Vector3(h - 0.2, 2.2, -1.5), Vector3(1.4, 0.2, 0.2), "wood_honey")
	AuthorKit.box(g, "fronton_" + nm, Vector3(h - 0.1, 2.4, -1.5), Vector3(1.2, 0.1, 0.1), "gold")

func _frame_south(g: Node3D, nm: String, h: float) -> void:
	AuthorKit.box(g, "cadre_g_" + nm, Vector3(h - 0.2, 0.0, 1.3), Vector3(0.2, 2.4, 0.2), "wood_honey")
	AuthorKit.box(g, "cadre_d_" + nm, Vector3(h + 1.0, 0.0, 1.3), Vector3(0.2, 2.4, 0.2), "wood_honey")
	AuthorKit.box(g, "cadre_h_" + nm, Vector3(h - 0.2, 2.2, 1.3), Vector3(1.4, 0.2, 0.2), "wood_honey")
	AuthorKit.box(g, "fronton_" + nm, Vector3(h - 0.1, 2.4, 1.4), Vector3(1.2, 0.1, 0.1), "gold")

# ------------------------------------------------------------------ porte du rêve (extrémité est)

func _end_door_niche(g: Node3D) -> void:
	AuthorKit.carve(g, "niche", Vector3(L, 0.0, -0.9), Vector3(0.3, 2.8, 1.8))
	# filets de lumière de part et d'autre de la niche
	AuthorKit.box(g, "lueur_g", Vector3(L - 0.1, 0.0, -1.1), Vector3(0.1, 2.9, 0.1), "dream_glow")
	AuthorKit.box(g, "lueur_d", Vector3(L - 0.1, 0.0, 1.0), Vector3(0.1, 2.9, 0.1), "dream_glow")
	AuthorKit.box(g, "lueur_h", Vector3(L - 0.1, 2.9, -1.1), Vector3(0.1, 0.1, 2.2), "dream_glow")
	AuthorKit.box(g, "seuil_reve", Vector3(L - 0.6, 0.0, -0.9), Vector3(0.6, 0.1, 1.8), "dream_glow")
	# marches basses de marbre devant la porte (10 cm : ni obstacle ni piège)
	AuthorKit.box(g, "marche_reve", Vector3(L - 1.0, 0.0, -1.0), Vector3(0.4, 0.1, 2.0), "marble_cream")

# ------------------------------------------------------------------ fenêtre de lune (extrémité ouest)

func _west_window(g: Node3D) -> void:
	AuthorKit.carve(g, "fenetre", Vector3(-0.3, 0.9, -0.7), Vector3(0.3, 1.9, 1.4))
	AuthorKit.box(g, "vitre_lune", Vector3(-0.4, 0.9, -0.7), Vector3(0.1, 1.9, 1.4), "moon_glass")
	AuthorKit.box(g, "meneau_v", Vector3(0.0, 0.8, -0.1), Vector3(0.1, 2.1, 0.2), "wood_dark")
	AuthorKit.box(g, "meneau_h", Vector3(0.0, 1.7, -0.8), Vector3(0.1, 0.2, 1.6), "wood_dark")
	AuthorKit.box(g, "cadre_haut", Vector3(0.0, 2.8, -0.8), Vector3(0.1, 0.1, 1.6), "wood_dark")
	AuthorKit.box(g, "appui", Vector3(0.0, 0.8, -0.9), Vector3(0.3, 0.1, 1.8), "stone_carved")
	AuthorKit.box(g, "rideau_g", Vector3(0.0, 0.5, -1.3), Vector3(0.2, 2.5, 0.4), "velvet_plum")
	AuthorKit.box(g, "rideau_d", Vector3(0.0, 0.5, 0.9), Vector3(0.2, 2.5, 0.4), "velvet_plum")
	AuthorKit.box(g, "tringle", Vector3(0.0, 3.0, -1.4), Vector3(0.3, 0.1, 2.8), "brass")

# ------------------------------------------------------------------ chambre

func _bedroom(g: Node3D) -> void:
	var wall := "wallpaper_teal_dark"
	AuthorKit.box(g, "mur_o", Vector3(7.2, -0.3, -7.8), Vector3(0.3, 3.6, 6.3), wall)
	AuthorKit.box(g, "mur_e", Vector3(13.5, -0.3, -7.8), Vector3(0.3, 3.6, 6.3), wall)
	AuthorKit.box(g, "mur_n", Vector3(7.2, -0.3, -7.8), Vector3(6.6, 3.6, 0.3), wall)
	AuthorKit.box(g, "plafond", Vector3(7.2, 3.0, -7.8), Vector3(6.6, 0.3, 6.3), "ceiling_dark")
	# parquet : dalle, plancher à fleur de sol, tapis
	AuthorKit.box(g, "dalle", Vector3(7.2, -0.3, -7.8), Vector3(6.6, 0.2, 6.3), "floor_planks")
	AuthorKit.box(g, "plancher", Vector3(7.5, -0.1, -7.5), Vector3(6.0, 0.1, 5.7), "floor_planks")
	AuthorKit.box(g, "tapis_bord", Vector3(8.6, -0.1, -6.9), Vector3(3.8, 0.1, 3.8), "carpet_gold")
	AuthorKit.box(g, "tapis", Vector3(8.8, -0.1, -6.7), Vector3(3.4, 0.1, 3.4), "carpet_wine")
	# soubassements, lisses, corniches
	AuthorKit.box(g, "soubassement_o", Vector3(7.5, 0.0, -7.5), Vector3(0.1, 1.0, 5.7), "wood_dark")
	AuthorKit.box(g, "soubassement_e", Vector3(13.4, 0.0, -7.5), Vector3(0.1, 1.0, 5.7), "wood_dark")
	AuthorKit.box(g, "soubassement_n", Vector3(7.5, 0.0, -7.5), Vector3(6.0, 1.0, 0.1), "wood_dark")
	AuthorKit.box(g, "lisse_o", Vector3(7.5, 1.0, -7.5), Vector3(0.2, 0.1, 5.7), "wood_honey")
	AuthorKit.box(g, "lisse_e", Vector3(13.3, 1.0, -7.5), Vector3(0.2, 0.1, 5.7), "wood_honey")
	AuthorKit.box(g, "lisse_n", Vector3(7.5, 1.0, -7.5), Vector3(6.0, 0.1, 0.2), "wood_honey")
	AuthorKit.box(g, "corniche_o", Vector3(7.5, 2.8, -7.5), Vector3(0.2, 0.2, 5.7), "plaster_cream")
	AuthorKit.box(g, "corniche_e", Vector3(13.3, 2.8, -7.5), Vector3(0.2, 0.2, 5.7), "plaster_cream")
	AuthorKit.box(g, "corniche_n", Vector3(7.5, 2.8, -7.5), Vector3(6.0, 0.2, 0.2), "plaster_cream")
	AuthorKit.box(g, "filet_n", Vector3(7.5, 2.4, -7.5), Vector3(6.0, 0.1, 0.1), "wallpaper_stripe")
	# fenêtre du mur nord, vitre de lune, meneaux, appui, rideaux
	AuthorKit.carve(g, "fenetre", Vector3(9.6, 0.9, -7.8), Vector3(2.0, 1.7, 0.4))
	AuthorKit.box(g, "vitre_lune", Vector3(9.6, 0.9, -7.9), Vector3(2.0, 1.7, 0.1), "moon_glass")
	AuthorKit.box(g, "meneau_v", Vector3(10.5, 0.8, -7.5), Vector3(0.2, 1.9, 0.1), "wood_dark")
	AuthorKit.box(g, "meneau_h", Vector3(9.5, 1.6, -7.5), Vector3(2.2, 0.1, 0.1), "wood_dark")
	AuthorKit.box(g, "cadre_haut", Vector3(9.5, 2.6, -7.5), Vector3(2.2, 0.1, 0.1), "wood_dark")
	AuthorKit.box(g, "cadre_g", Vector3(9.5, 0.8, -7.5), Vector3(0.1, 1.9, 0.1), "wood_dark")
	AuthorKit.box(g, "cadre_d", Vector3(11.6, 0.8, -7.5), Vector3(0.1, 1.9, 0.1), "wood_dark")
	AuthorKit.box(g, "appui", Vector3(9.4, 0.7, -7.5), Vector3(2.4, 0.1, 0.3), "stone_carved")
	AuthorKit.box(g, "rideau_g", Vector3(8.9, 0.5, -7.5), Vector3(0.6, 2.3, 0.2), "velvet_plum")
	AuthorKit.box(g, "rideau_d", Vector3(11.7, 0.5, -7.5), Vector3(0.6, 2.3, 0.2), "velvet_plum")
	AuthorKit.box(g, "tringle", Vector3(8.8, 2.8, -7.5), Vector3(3.6, 0.1, 0.1), "brass")
	# plafonnier : disque de laiton et verre chaud
	AuthorKit.box(g, "plafonnier_base", Vector3(10.0, 2.9, -4.7), Vector3(0.8, 0.1, 0.8), "brass")
	AuthorKit.box(g, "plafonnier_verre", Vector3(10.1, 2.8, -4.6), Vector3(0.6, 0.1, 0.6), "lamp_warm")
	# cadre de la porte de chambre côté chambre (retour de mur)
	AuthorKit.box(g, "ebrasement_g", Vector3(9.8, 0.0, -1.8), Vector3(0.2, 2.3, 0.1), "wood_honey")
	AuthorKit.box(g, "ebrasement_d", Vector3(11.0, 0.0, -1.8), Vector3(0.2, 2.3, 0.1), "wood_honey")

# ------------------------------------------------------------------ mobilier (assets cuits)

func _furniture(g: Node3D) -> void:
	# couloir, côté fenêtre : banc sous la fenêtre, deux lampadaires
	AuthorKit.asset(g, "decorative_bench", Vector2(0.45, 0.0), 0.0, 90.0)
	AuthorKit.asset(g, "hotel_floor_lamp", Vector2(0.55, -1.15), 0.0, 0.0)
	AuthorKit.asset(g, "hotel_floor_lamp", Vector2(0.55, 1.15), 0.0, 0.0)
	# chambre : lit tête à l'est, tables de nuit, armoire à l'ouest, fauteuil près de la fenêtre
	AuthorKit.asset(g, "hotel_bed", Vector2(12.35, -4.6), 0.0, -90.0)
	AuthorKit.asset(g, "hotel_nightstand", Vector2(13.15, -3.45), 0.0, -90.0)
	AuthorKit.asset(g, "hotel_nightstand", Vector2(13.15, -5.75), 0.0, -90.0)
	AuthorKit.asset(g, "hotel_wardrobe", Vector2(7.9, -6.4), 0.0, 90.0)
	AuthorKit.asset(g, "hotel_armchair", Vector2(8.9, -6.9), 0.0, 25.0)

# ------------------------------------------------------------------ lumières

func _lights(g: Node3D) -> void:
	var warm := Color(1.0, 0.76, 0.46)
	var cold := Color(0.55, 0.72, 1.0)
	var dream := Color(0.55, 1.0, 0.9)
	# appliques sur les pilastres (laiton + verre de lanterne), une lumière chaude chacune
	var i := 0
	for k in [4.6, 8.0, 12.0, 17.6, 23.0]:
		AuthorKit.omni(g, "applique_n_%d" % i, Vector3(k + 0.15, 2.0, -1.2), warm, 2.0, 6.5, i % 2 == 0)
		AuthorKit.omni(g, "applique_s_%d" % i, Vector3(k + 0.15, 2.0, 1.2), warm, 2.0, 6.5, i % 2 == 1)
		i += 1
	# lune derrière la fenêtre de l'extrémité ouest (froid) contre les lampadaires (chaud)
	AuthorKit.omni(g, "lune_couloir", Vector3(1.0, 1.9, 0.0), cold, 2.2, 7.0, true)
	# lueur du rêve : porte de l'extrémité est et seuils
	AuthorKit.omni(g, "reve_fond", Vector3(25.2, 1.4, 0.0), dream, 2.0, 8.0, false)
	for h in [3.5, 16.5, 21.5]:
		AuthorKit.omni(g, "reve_seuil_n_%d" % roundi(h * 10.0), Vector3(h, 0.15, -1.2), dream, 0.55, 2.6, false)
	for h in [7.0, 14.0, 19.5]:
		AuthorKit.omni(g, "reve_seuil_s_%d" % roundi(h * 10.0), Vector3(h, 0.15, 1.2), dream, 0.55, 2.6, false)
	# chambre : clair de lune par la fenêtre, lumière chaude des lampes (portée par les tables de nuit)
	AuthorKit.omni(g, "lune_chambre", Vector3(10.6, 1.8, -6.6), cold, 2.0, 6.5, true)
	AuthorKit.omni(g, "ambiance_chambre", Vector3(10.4, 2.5, -4.2), warm, 1.1, 7.5, false)

# ------------------------------------------------------------------ poussières de rêve (particules)

func _motes(g: Node3D) -> void:
	var p := GPUParticles3D.new()
	p.name = "Poussieres_de_reve"
	p.amount = 90
	p.lifetime = 14.0
	p.preprocess = 14.0
	p.position = Vector3(L * 0.5, 1.6, 0.0)
	p.visibility_aabb = AABB(Vector3(-L * 0.5 - 1.0, -2.0, -2.0), Vector3(L + 2.0, 4.0, 4.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(L * 0.5, 1.4, 1.4)
	pm.direction = Vector3(0.2, 1.0, 0.0)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.09
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.025, 0.025)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.6, 1.0, 0.9, 0.7)
	quad.material = mat
	p.draw_pass_1 = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.add_child(p)

# ------------------------------------------------------------------ portes interactives

func _doors(g: Node3D) -> void:
	var msgs := {"n30": "Fermée à clé.", "n160": "Fermée à clé.", "n210": "Personne ne répond.",
			"s65": "Fermée à clé.", "s135": "Fermée à clé.", "s190": "Une lumière filtre sous la porte… fermée."}
	for h in [3.0, 16.0, 21.0]:
		var key := "n%d" % roundi(h * 10.0)
		var d := _door(g, "Porte_" + key, Vector3(h, 0.0, -1.6), 0.0)
		d.locked = true
		d.locked_message = msgs[key]
	for h in [6.5, 13.5, 19.0]:
		var key := "s%d" % roundi(h * 10.0)
		var d := _door(g, "Porte_" + key, Vector3(h + 1.0, 0.0, 1.6), 180.0)
		d.locked = true
		d.locked_message = msgs[key]
	# la chambre : s'ouvre sur place et le reste
	var chambre := _door(g, "Porte_chambre", Vector3(10.0, 0.0, -1.6), 0.0)
	chambre.prompt = "Entrer dans la chambre"
	# la porte du rêve : transition vers la forêt nocturne
	var reve := _door(g, "Porte_du_reve", Vector3(L + 0.15, 0.0, -0.6), -90.0)
	reve.look = SceneDoor.Look.REVE
	reve.leaf_width = 1.2
	reve.leaf_height = 2.4
	reve.build_frame = true
	reve.portal_glow = true
	reve.target_scene = "res://scenes/levels/foret_nocturne.tscn"
	reve.target_spawn = "depart"
	reve.prompt = "Franchir la porte du rêve"

func _door(parent: Node, nm: String, pos: Vector3, yaw: float) -> SceneDoor:
	var d := SceneDoor.new()
	d.name = nm
	d.position = pos
	d.rotation_degrees = Vector3(0, yaw, 0)
	parent.add_child(d)
	return d
