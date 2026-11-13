extends SceneTree
## Contrôles de « La Forêt de la peur » (sans carte graphique, vraie physique) :
##   godot --headless -s tests/run_checks_foret.gd
## Structure, budgets, props posés au sol, puis parcours JOUÉ : lisière, jeune fille, étang infranchissable, passerelle,
## trois fleurs → pont de racines, bois noir, porte de lune (fermée puis ouverte), clairière, porte de réveil.

const LEVEL := "res://scenes/levels/foret_de_la_peur.tscn"
const BUREAU := "res://scenes/levels/bureau_des_reves.tscn"

var _ok := 0
var _fail := 0

func check(name: String, cond: bool, detail := "") -> void:
	if cond:
		_ok += 1
	else:
		_fail += 1
		print("  ÉCHEC  %s %s" % [name, detail])

func _initialize() -> void:
	ForetEtat.effacer()
	_static()
	await _played()
	ForetEtat.effacer()
	print("== Forêt de la peur : %d vérifications réussies, %d échec(s)" % [_ok, _fail])
	quit(1 if _fail > 0 else 0)

# ------------------------------------------------------------------ structure et budgets

func _static() -> void:
	print("-- structure et budgets")
	check("scène présente", ResourceLoader.exists(LEVEL))
	var lv := (load(LEVEL) as PackedScene).instantiate() as Level
	check("racine Level", lv != null)
	check("identifiant « foret-de-la-peur »", lv.level_id == "foret-de-la-peur")
	check("titre « La Forêt de la peur »", lv.level_title == "La Forêt de la peur")
	check("préréglage « foret_peur »", lv.lighting_preset == "foret_peur")
	check("extérieur, 3e personne, rappel des commandes", not lv.interior and not lv.first_person and lv.show_controls_hint)
	check("kill_y de sécurité", lv.kill_y < -3.0 and lv.kill_y > -40.0, str(lv.kill_y))
	for sp in ["depart", "marais", "bois_noir", "clairiere"]:
		check("arrivée « %s »" % sp, lv.get_node_or_null("Spawns/" + sp) is Marker3D)
	for path in ["Architecture/Relief", "Architecture/Eau", "Architecture/Eau_barriere", "Architecture/Chemin_sud", "Architecture/Chemin_nord",
			"Gameplay/Etat", "Gameplay/JeuneFille", "Gameplay/Etapes", "Gameplay/Fleurs/Fleur_1", "Gameplay/Fleurs/Fleur_2", "Gameplay/Fleurs/Fleur_3",
			"Gameplay/PontRacines", "Gameplay/PontRacines/Racine_1", "Gameplay/PontRacines/Racine_5", "Gameplay/Piedestal", "Gameplay/Porte_de_lune/PorteLune",
			"Gameplay/Porte_de_lune/Ruine/VantailG", "Gameplay/Porte_de_lune/Ruine/VantailD", "Gameplay/Feux_follets/Feu_follet_1", "Gameplay/Silhouettes/Silhouette_1",
			"Gameplay/Portes/Porte_du_reve", "Gameplay/Portes/Cadre_porte_reve", "Decor/Arbres/Murs_de_troncs", "Limites/MursInvisibles"]:
		check("nœud %s" % path, lv.get_node_or_null(path) != null)
	check("aucune structure voxel", lv.find_children("*", "VoxelStructure", true, false).is_empty())
	var door := lv.get_node("Gameplay/Portes/Porte_du_reve") as PorteReveil
	check("porte « Se réveiller » : vers le Bureau des rêves, lit (reveil)", door.target_scene == BUREAU and door.target_spawn == "reveil")
	var etapes := lv.get_node("Gameplay/Etapes").get_children()
	check("jeune fille : étapes posées à la main (≥ 15, %d)" % etapes.size(), etapes.size() >= 15)
	check("jeune fille : dernière étape « fin »", bool(etapes[etapes.size() - 1].get_meta("fin", false)))
	# budgets : triangles, lumières, ombres
	var tris := 0
	for mi in lv.find_children("*", "MeshInstance3D", true, false):
		tris += StyleKit.triangles((mi as MeshInstance3D).mesh)
	for mm in lv.find_children("*", "MultiMeshInstance3D", true, false):
		var m := (mm as MultiMeshInstance3D).multimesh
		tris += StyleKit.triangles(m.mesh) * m.instance_count
	var lights := lv.find_children("*", "Light3D", true, false)
	print("   %d triangles, %d lumières (hors éclairage du niveau)" % [tris, lights.size()])
	check("budget : ≤ 600 000 triangles (%d)" % tris, tris <= 600000)
	check("budget : ≤ 40 lumières (%d)" % lights.size(), lights.size() <= 40)
	lv.free()

# ------------------------------------------------------------------ outils de parcours

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _xz(p: Node3D) -> Vector2:
	return Vector2(p.global_position.x, p.global_position.z)

func _walk_to(p: Explorer, target: Vector2, max_frames := 1200, sprint := true, tol := 0.7) -> bool:
	p.auto_active = true
	p.auto_sprint = sprint
	var guard := 0
	while _xz(p).distance_to(target) > tol and guard < max_frames:
		p.auto_dir = (target - _xz(p)).normalized()
		await physics_frame
		guard += 1
	p.auto_active = false
	p.auto_dir = Vector2.ZERO
	return guard < max_frames

func _route(p: Explorer, pts: Array, sprint := true) -> bool:
	for q in pts:
		if not await _walk_to(p, Vector2(q[0], q[1]), 1500, sprint):
			return false
	return true

## Pose le joueur à (x, z), juste au-dessus du relief.
func _tp(lv: Level, p: Explorer, x: float, z: float) -> void:
	p.teleport(Vector3(x, _ground_y(lv, x, z) + 0.15, z))
	await _frames(8)

## Pousse le joueur dans une direction pendant `frames` images (mur ? eau ?).
func _push(p: Explorer, dir: Vector2, frames: int) -> void:
	p.auto_active = true
	p.auto_sprint = true
	p.auto_dir = dir.normalized()
	await _frames(frames)
	p.auto_active = false
	p.auto_dir = Vector2.ZERO

func _aim_at(lv: Level, target: Vector3) -> void:
	var pp := lv.player.global_position
	var d := target - pp
	var yaw := atan2(-d.x, -d.z)
	lv.player.face(yaw)
	lv.camera.yaw = yaw
	lv.camera.pitch = -0.1
	lv.camera.snap()
	await _frames(2)
	lv._update_focus()

func _press_e(lv: Level) -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	lv._unhandled_input(ev)

func _ground_y(lv: Level, x: float, z: float) -> float:
	var space := lv.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 30.0, z), Vector3(x, -10.0, z), 1)
	var hit := space.intersect_ray(q)
	return float(hit["position"].y) if not hit.is_empty() else NAN

# ------------------------------------------------------------------ parcours joué

func _played() -> void:
	print("-- parcours joué")
	var lv := (load(LEVEL) as PackedScene).instantiate() as Level
	root.add_child(lv)
	await _frames(40)
	var p := lv.player
	var jf := lv.get_node("Gameplay/JeuneFille") as JeuneFille
	var pont := lv.get_node("Gameplay/PontRacines") as PontRacines
	var etat := lv.get_node("Gameplay/Etat") as ForetEtat
	var porte := lv.get_node("Gameplay/Porte_de_lune/PorteLune") as PorteLune
	check("GameSave : niveau marqué « visited »", GameSave.level("foret-de-la-peur").get("visited") == true)
	await _props_au_sol(lv)

	# --- spawns au sol
	for sp in ["depart", "marais", "bois_noir", "clairiere"]:
		lv.move_player_to(sp)
		await _frames(30)
		var m := lv.get_node("Spawns/" + sp) as Marker3D
		check("arrivée « %s » : joueur au sol" % sp, p.is_on_floor() and absf(p.global_position.y - _ground_y(lv, m.global_position.x, m.global_position.z)) < 0.15, str(p.global_position))
	lv.move_player_to("depart")
	await _frames(20)
	check("arrivée : regard vers le nord devant le cadre de porte", absf(lv.get_node("Spawns/depart").global_rotation.y) < 0.01 and lv.get_node("Gameplay/Portes/Cadre_porte_reve").global_position.z > p.global_position.z)

	# --- zone 1 : la lisière, jusqu'à la jeune fille
	var ok := await _route(p, [[0.0, -6.0], [-1.5, -14.0], [-3.0, -20.0]])
	check("lisière : chemin praticable jusqu'à la jeune fille", ok, str(p.global_position))
	check("lisière : joueur au sol", p.is_on_floor())
	check("jeune fille : assise au début", jf.etat == JeuneFille.Etat.ASSISE)
	await _tp(lv, p, -4.2, -22.0)
	await _aim_at(lv, jf.focus_point())
	check("jeune fille : visée (« La rassurer »)", lv.focused == jf and lv._prompt.text.contains("rassurer"), "%s / %s" % [lv.focused, lv._prompt.text])
	check("jeune fille : geste « comfort »", jf.gesture_for(p) == &"comfort")
	_press_e(lv)
	await _frames(5)
	check("jeune fille : rassurée → guide", jf.etat == JeuneFille.Etat.GUIDE)
	# --- zone 2 → 3 : elle avance quand le joueur approche
	var y0 := jf.global_position
	ok = await _route(p, [[-3.0, -26.0], [-2.0, -31.0], [0.0, -33.4]], false)
	check("marais : rive sud atteinte", ok, str(p.global_position))
	await _frames(240)
	check("jeune fille guide : elle a avancé avec le joueur (%.1f m)" % jf.global_position.distance_to(y0), jf.global_position.distance_to(y0) > 6.0)
	check("jeune fille guide : en vue du joueur (< 16 m)", Vector2(jf.global_position.x - p.global_position.x, jf.global_position.z - p.global_position.z).length() < 16.0, str(jf.global_position))

	# --- l'eau est infranchissable sans pont
	for x in [-6.5, -4.0, 4.0, 6.5]:
		await _tp(lv, p, x, -33.0)
		await _push(p, Vector2(0, -1), 220)
		check("eau : infranchissable depuis la rive sud (x = %.1f)" % x, p.global_position.z > -37.5 and p.global_position.y > -0.6, str(p.global_position))
	for x in [-14.0, 11.0, 15.0]:
		await _tp(lv, p, x, -36.0)
		await _push(p, Vector2(0, -1), 300)
		check("eau : les rives ne mènent pas au nord (x = %.0f)" % x, p.global_position.z > -48.9 and p.global_position.y > -0.6, str(p.global_position))
	# passerelle de troncs : traversée jusqu'à l'îlot
	p.teleport(Vector3(0.0, 0.4, -33.0))
	await _frames(10)
	ok = await _walk_to(p, Vector2(0.0, -44.5), 900, false)
	check("passerelle : traversée jusqu'à l'îlot", ok and p.global_position.z < -43.0, str(p.global_position))
	check("passerelle : sur le plancher, au-dessus de l'eau", p.global_position.y > 0.2 and p.is_on_floor(), str(p.global_position))
	# les bords de la passerelle retiennent le joueur
	p.teleport(Vector3(0.0, 0.5, -38.0))
	await _frames(10)
	await _push(p, Vector2(1, 0), 120)
	check("passerelle : le bord retient le joueur (est)", absf(p.global_position.x) < 1.5 and p.global_position.y > 0.2, str(p.global_position))
	await _push(p, Vector2(-1, 0), 240)
	check("passerelle : le bord retient le joueur (ouest)", absf(p.global_position.x) < 1.5 and p.global_position.y > 0.2, str(p.global_position))
	# depuis l'îlot, le nord est fermé tant que le pont dort
	p.teleport(Vector3(0.0, 0.4, -45.0))
	await _frames(10)
	check("pont : endormi (sans collision)", not pont.ouvert and (pont.get_node("Plancher") as StaticBody3D).collision_layer == 0)
	await _push(p, Vector2(0, -1), 240)
	check("pont : sans les fleurs, l'étang bloque la rive nord", p.global_position.z > -48.5 and p.global_position.y > -0.6, str(p.global_position))
	check("pont : aucune fleur allumée", etat.fleurs.is_empty())

	# --- énigme 1 : trois fleurs
	var f3 := lv.get_node("Gameplay/Fleurs/Fleur_3") as FleurLanterne
	p.teleport(Vector3(-0.2, 0.4, -45.0))
	await _frames(10)
	await _aim_at(lv, f3.focus_point())
	check("fleur 3 : visée (« Réveiller la fleur »)", lv.focused == f3 and lv._prompt.text.contains("Réveiller"), "%s / %s" % [lv.focused, lv._prompt.text])
	_press_e(lv)
	await _frames(100)
	check("fleur 3 : allumée", f3.lit and etat.fleurs.has("Fleur_3"))
	check("fleur 3 : lumière allumée", (f3.find_child("Lumiere", true, false) as Light3D).visible and (f3.find_child("Lumiere", true, false) as Light3D).light_energy > 0.5)
	check("pont : encore endormi avec une fleur", not pont.ouvert)
	# retour par la passerelle, puis fleur ouest et fleur est (par la rive)
	ok = await _walk_to(p, Vector2(0.0, -36.0), 900, false)
	ok = ok and await _route(p, [[0.0, -33.4], [-7.0, -34.2], [-12.0, -37.0], [-12.5, -39.5]])
	check("fleur 1 : rive ouest atteignable à pied", ok, str(p.global_position))
	var f1 := lv.get_node("Gameplay/Fleurs/Fleur_1") as FleurLanterne
	await _aim_at(lv, f1.focus_point())
	check("fleur 1 : visée", lv.focused == f1, str(lv.focused))
	_press_e(lv)
	await _frames(10)
	check("fleur 1 : allumée", f1.lit)
	check("pont : encore endormi avec deux fleurs", not pont.ouvert)
	ok = await _route(p, [[-12.0, -37.0], [-7.0, -34.2], [0.0, -33.4], [7.0, -34.8], [12.0, -38.5], [12.6, -40.7]])
	check("fleur 2 : rive est atteignable à pied", ok, str(p.global_position))
	var f2 := lv.get_node("Gameplay/Fleurs/Fleur_2") as FleurLanterne
	await _aim_at(lv, f2.focus_point())
	check("fleur 2 : visée", lv.focused == f2, str(lv.focused))
	_press_e(lv)
	await _frames(10)
	check("fleur 2 : allumée → les racines se soulèvent", f2.lit and etat.fleurs.size() == 3 and pont.ouvert)
	await _frames(240)
	check("pont : collision du plancher activée", (pont.get_node("Plancher") as StaticBody3D).collision_layer == 1 and (pont.get_node("Barriere") as StaticBody3D).collision_layer == 0)
	check("pont : racines levées (Racine_5 à y = 0)", absf(pont.get_node("Racine_5").position.y) < 0.02, str(pont.get_node("Racine_5").position))
	check("pont : état mémorisé", etat.pont_ouvert and GameSave.level("foret-de-la-peur").get("pont_ouvert") == true)
	# traversée : passerelle, îlot, pont, rive nord
	ok = await _route(p, [[7.0, -34.8], [0.0, -34.0], [0.0, -45.0]], false)
	ok = ok and await _walk_to(p, Vector2(0.0, -54.0), 900, false)
	check("pont : le joueur marche sur les racines", ok and p.global_position.y > 0.2 and p.is_on_floor(), str(p.global_position))
	ok = ok and await _walk_to(p, Vector2(0.0, -64.0), 900, false)
	check("pont : rive nord atteinte", ok and p.global_position.z < -62.0, str(p.global_position))
	await _frames(10)
	check("pont : au sol sur la rive nord", p.is_on_floor() and p.global_position.y > 0.1 and p.global_position.y < 0.6, str(p.global_position))
	# les bords du pont retiennent
	p.teleport(Vector3(0.0, 0.5, -54.0))
	await _frames(10)
	await _push(p, Vector2(1, 0), 120)
	check("pont : le bord retient le joueur", absf(p.global_position.x) < 1.5 and p.global_position.y > 0.2, str(p.global_position))
	await _frames(1)

	# --- zone 4 : le bois noir
	ok = await _walk_to(p, Vector2(0.0, -64.5), 300, false)
	var chem: PackedVector3Array = lv.get_meta("foret_zones")["chemin"]
	var pts := []
	for q in chem:
		if q.z < -64.0 and q.z > -105.5 and (int(-q.z) % 3 == 0 or true):
			pts.append([q.x, q.z])
	# on ne garde qu'un point sur 3 (axe du chemin)
	var thin := []
	for i in pts.size():
		if i % 3 == 0:
			thin.append(pts[i])
	ok = await _route(p, thin)
	check("bois noir : chemin praticable jusqu'à la porte de ruine", ok, str(p.global_position))
	check("bois noir : au sol", p.is_on_floor(), str(p.global_position))
	check("jeune fille : s'est avancée dans le bois noir (étape ≥ 6, %d)" % jf.idx, jf.idx >= 6)
	await _frames(60)
	var d_jf := Vector2(jf.global_position.x - p.global_position.x, jf.global_position.z - p.global_position.z).length()
	check("jeune fille : reste tout près dans le bois noir (%.1f m)" % d_jf, d_jf < 6.5)
	# silhouettes qui se dissolvent
	var diss := 0
	for s in lv.get_node("Gameplay/Silhouettes").get_children():
		if (s as SilhouetteOmbre).dissoute or not (s as Node3D).visible:
			diss += 1
	check("silhouettes : celles que le joueur a approchées se dissolvent (%d)" % diss, diss >= 3)
	# feux follets qui reculent
	var ff := lv.get_node("Gameplay/Feux_follets/Feu_follet_1") as FeuFollet
	await _tp(lv, p, _px_chemin(chem, -74.0), -74.0)
	var start_d := ff.global_position.distance_to(ff.repli + Vector3(0, 0, 0))
	await _walk_to(p, Vector2(6.0, -74.6), 600, false)
	await _frames(240)
	check("feu follet : recule dans l'impasse à l'approche du joueur (%.1f m du fond)" % ff.global_position.distance_to(ff.repli), ff.global_position.distance_to(ff.repli) < start_d - 3.0 and ff.global_position.distance_to(p.global_position) > 2.0)
	# porte de ruine fermée
	await _tp(lv, p, 0.0, -103.5)
	check("porte de lune : fermée au départ", not porte.ouvert)
	await _push(p, Vector2(0, -1), 240)
	check("porte de lune : le passage est fermé (z = %.1f)" % p.global_position.z, p.global_position.z > -107.9, str(p.global_position))
	await _aim_at(lv, porte.focus_point())
	check("porte de lune : visée", lv.focused == porte, str(lv.focused))
	_press_e(lv)
	check("porte de lune sans pierre : « Une empreinte en forme de lune… »", lv._toast.text.begins_with("Une empreinte"), lv._toast.text)
	check("porte de lune : toujours fermée", not porte.ouvert)
	# ruine latérale : la pierre de lune
	var ped := lv.get_node("Gameplay/Piedestal") as PiedestalLune
	ok = await _route(p, _chem_pts(chem, -100.0, -84.0, 3) + [[-1.0, -83.6], [-8.0, -84.8], [-13.0, -86.3], [-16.6, -88.0]])
	check("ruine latérale : atteignable par l'embranchement ouest", ok, str(p.global_position))
	await _aim_at(lv, ped.focus_point())
	check("piédestal : visé (« Prendre la pierre de lune »)", lv.focused == ped and lv._prompt.text.contains("pierre de lune"), "%s / %s" % [lv.focused, lv._prompt.text])
	_press_e(lv)
	await _frames(5)
	check("piédestal : pierre prise", etat.pierre_prise)
	# retour à la porte, poser la pierre
	ok = await _route(p, [[-13.0, -86.3], [-8.0, -84.8], [-1.0, -83.6]] + _chem_pts(chem, -86.0, -104.0, 3))
	ok = ok and await _walk_to(p, Vector2(0.0, -105.6), 300, false, 0.3)
	check("retour à la porte de lune", ok, str(p.global_position))
	await _aim_at(lv, porte.focus_point())
	check("porte de lune : « Poser la pierre de lune »", lv.focused == porte and lv._prompt.text.contains("Poser"), "%s / %s" % [lv.focused, lv._prompt.text])
	_press_e(lv)
	await _frames(180)
	check("porte de lune : ouverte", porte.ouvert and etat.porte_ouverte)
	check("porte de lune : vantaux pivotés", absf(lv.get_node("Gameplay/Porte_de_lune/Ruine/VantailG").rotation.y) > 1.5 and absf(lv.get_node("Gameplay/Porte_de_lune/Ruine/VantailD").rotation.y) > 1.5)
	ok = await _route(p, [[0.0, -108.0], [0.0, -112.0], [0.0, -116.0]], false)
	check("porte de lune : passage ouvert vers la clairière", ok and p.global_position.z < -114.0, str(p.global_position))

	# --- zone 5 : la clairière
	ok = await _route(p, [[0.0, -120.0], [-1.0, -124.0]], false)
	check("clairière atteinte", ok, str(p.global_position))
	await _frames(300)
	check("jeune fille : arrivée dans la clairière et assise", jf.etat == JeuneFille.Etat.ARRIVEE, str(jf.etat))
	await _walk_to(p, Vector2(-1.8, -125.0), 300, false, 0.25)
	await _aim_at(lv, jf.focus_point())
	check("jeune fille : « S'asseoir près d'elle »", lv.focused == jf and lv._prompt.text.contains("S'asseoir"), "%s / %s joueur %s fille %s focus %s cam %s" % [lv.focused, lv._prompt.text, p.global_position, jf.global_position, jf.focus_point(), lv.camera.cam.global_position])
	var got := [false]
	jf.apaisement.connect(func() -> void: got[0] = true)
	_press_e(lv)
	await _frames(3)
	check("apaisement : signal émis, toast, état mémorisé", got[0] and etat.apaisee and lv._toast.text != "")
	# porte « Se réveiller »
	var pr := lv.get_node("Gameplay/Portes/Porte_du_reve") as PorteReveil
	ok = await _walk_to(p, Vector2(6.4, -127.5), 600, false, 0.25)
	check("porte de réveil : atteignable", ok, str(p.global_position))
	await _aim_at(lv, pr.focus_point())
	check("porte de réveil : visée, invite « Se réveiller »", lv.focused == pr and lv._prompt.text.contains("réveiller"), "%s / %s" % [lv.focused, lv._prompt.text])
	check("porte de réveil : mène au lit du Bureau des rêves", pr.target_scene == BUREAU and pr.target_spawn == "reveil" and ResourceLoader.exists(pr.target_scene))
	# retour sur le lit : le Bureau des rêves pointe vers cette forêt
	var bd := (load(BUREAU) as PackedScene).instantiate()
	var bed := bd.get_node("Chambre/Lit_du_reveur") as DreamBed
	check("lit du rêveur : mène à la Forêt de la peur", bed.dream_scene == LEVEL and bed.dream_spawn == "depart")
	bd.free()
	lv.queue_free()
	await process_frame

## Points de l'axe du chemin entre deux profondeurs (un sur `pas`).
func _chem_pts(chem: PackedVector3Array, z_from: float, z_to: float, pas: int) -> Array:
	var out := []
	var k := 0
	for q in chem:
		if (z_from >= z_to and q.z <= z_from and q.z >= z_to) or (z_from < z_to and q.z >= z_from and q.z <= z_to):
			if k % pas == 0:
				out.append([q.x, q.z])
			k += 1
	return out

func _px_chemin(chem: PackedVector3Array, z: float) -> float:
	for i in chem.size() - 1:
		if (chem[i].z >= z and chem[i + 1].z <= z):
			return lerpf(chem[i].x, chem[i + 1].x, (chem[i].z - z) / maxf(chem[i].z - chem[i + 1].z, 0.001))
	return 0.0

## Rien d'enfoui ni de flottant : l'origine de chaque prop du kit est à moins de 0,3 m du relief.
func _props_au_sol(lv: Level) -> void:
	var relief := lv.get_node("Architecture/Relief") as StaticBody3D
	var exclude: Array[RID] = []
	for co in lv.find_children("*", "CollisionObject3D", true, false):
		if co != relief:
			exclude.append((co as CollisionObject3D).get_rid())
	var space := lv.get_world_3d().direct_space_state
	var exceptions := ["nenuphars", "jeune_fille_provisoire"]            # sur l'eau ; assise sur sa souche
	var bad := 0
	var n := 0
	for node in lv.find_children("*", "Node3D", true, false):
		if not node.has_meta("kit_id"):
			continue
		var id := String(node.get_meta("kit_id"))
		if exceptions.has(id):
			continue
		n += 1
		var gp := (node as Node3D).global_position
		var q := PhysicsRayQueryParameters3D.create(gp + Vector3(0, 12.0, 0), gp + Vector3(0, -12.0, 0), 1)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		var gy := float(hit["position"].y) if not hit.is_empty() else NAN
		if is_nan(gy) or absf(gp.y - gy) > 0.3:
			bad += 1
			print("   prop hors sol : %s (%s) y=%.2f sol=%.2f" % [node.name, id, gp.y, gy])
	check("props : %d vérifiés, tous posés au sol (< 0,3 m), %d hors sol" % [n, bad], bad == 0 and n > 100)
