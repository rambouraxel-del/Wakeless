extends SceneTree
## Contrôles du NOUVEAU Bureau des rêves (3D stylisée), sans carte graphique, avec la vraie physique :
##   godot --headless -s tests/run_checks_bureau.gd
## Modules, matériaux partagés, budgets, structure du niveau, puis parcours joué : atrium, escaliers, galeries,
## couloir, porte 107, chambre, lit (endormissement).

const LEVEL := "res://scenes/levels/bureau_des_reves.tscn"

var _ok := 0
var _fail := 0

func check(name: String, cond: bool, detail := "") -> void:
	if cond:
		_ok += 1
	else:
		_fail += 1
		print("  ÉCHEC  %s %s" % [name, detail])

func _initialize() -> void:
	_modules()
	_level_static()
	await _level_played()
	print("== Bureau des rêves : %d vérifications réussies, %d échec(s)" % [_ok, _fail])
	quit(1 if _fail > 0 else 0)

# ------------------------------------------------------------------ modules et matériaux

func _modules() -> void:
	print("-- modules stylisés")
	var ids := StyleAssets.all_ids()
	check("modules : catalogue (≥ 30)", ids.size() >= 30, str(ids.size()))
	var shared := {}
	for id in ids:
		var path := "res://assets/stylized/modules/%s.tscn" % id
		check("module %s : scène présente" % id, ResourceLoader.exists(path))
		if not ResourceLoader.exists(path):
			continue
		var n := (load(path) as PackedScene).instantiate()
		var meshes := n.find_children("*", "MeshInstance3D", true, false)
		check("module %s : au moins un maillage" % id, not meshes.is_empty())
		var tris := 0
		for mi in meshes:
			var mesh := (mi as MeshInstance3D).mesh
			tris += StyleKit.triangles(mesh)
			for s in mesh.get_surface_count():
				var mat := mesh.surface_get_material(s)
				check("module %s : chaque surface a un matériau partagé" % id, mat != null and mat.resource_path.begins_with("res://materials/stylized/"), str(mat.resource_path if mat else "aucun"))
				if mat:
					shared[mat.resource_path] = true
		check("module %s : géométrie maîtrisée (≤ 16 000 triangles, %d)" % [id, tris], tris <= 16000)
		n.free()
	check("matériaux : partagés et peu nombreux (≤ 40, %d)" % shared.size(), shared.size() <= 40)
	# kit : orientation des faces conforme à Godot (faces avant dans le sens horaire)
	var m := StyleKit.rounded_box(Vector3(1, 1, 1), 0.2)
	var a := m.surface_get_arrays(0)
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var nn: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var bad := 0
	for i in range(0, idx.size(), 3):
		var g := (v[idx[i + 2]] - v[idx[i]]).cross(v[idx[i + 1]] - v[idx[i]])
		if g.length() > 1e-9 and g.dot(nn[idx[i]] + nn[idx[i + 1]] + nn[idx[i + 2]]) < 0.0:
			bad += 1
	check("kit : faces orientées vers l'extérieur", bad == 0, str(bad))

# ------------------------------------------------------------------ niveau (structure)

func _level_static() -> void:
	print("-- niveau (structure)")
	check("niveau : scène présente", ResourceLoader.exists(LEVEL))
	var lv := (load(LEVEL) as PackedScene).instantiate() as Level
	check("niveau : racine Level", lv != null)
	check("niveau : scène de démarrage du jeu", ProjectSettings.get_setting("application/run/main_scene") == LEVEL)
	check("niveau : préréglage « bureau_nuit »", lv.lighting_preset == "bureau_nuit")
	for sp in ["depart", "couloir", "reveil"]:
		check("niveau : arrivée « %s »" % sp, lv.get_node_or_null("Spawns/" + sp) is Marker3D)
	check("niveau : aucune structure voxel (nouvelle direction artistique)", lv.find_children("*", "VoxelStructure", true, false).is_empty() and lv.find_children("*", "HeightmapTerrain", true, false).is_empty())
	for path in ["Atrium/Reception", "Atrium/Arbre_de_lune", "Atrium/Lustre_Astronomique", "Atrium/Horloge_Celeste", "Atrium/Escalier_Ouest", "Atrium/Escalier_Est", "Chambre/Lit", "Chambre/Lit_du_reveur", "Couloir/Portes/Porte_107"]:
		check("niveau : %s" % path, lv.get_node_or_null(path) != null)
	var doors := lv.find_children("*", "", true, false).filter(func(n): return n is HotelDoor)
	check("niveau : portes numérotées (≥ 20, %d)" % doors.size(), doors.size() >= 20)
	var numbers := {}
	for d in doors:
		numbers[(d as HotelDoor).number] = true
	check("niveau : numéros uniques", numbers.size() == doors.size())
	check("niveau : une seule porte ouvrable (chambre 107)", doors.filter(func(d): return not (d as HotelDoor).locked).size() == 1)
	var bed := lv.get_node("Chambre/Lit_du_reveur") as DreamBed
	check("lit : mène au rêve (La Forêt de la peur)", bed.dream_scene == "res://scenes/levels/foret_de_la_peur.tscn" and ResourceLoader.exists(bed.dream_scene))
	check("lit : point de coucher", bed.get_node_or_null("Coucher") is Marker3D)
	# la forêt renvoie au réveil dans la chambre
	var fo := (load("res://scenes/levels/foret_de_la_peur.tscn") as PackedScene).instantiate()
	var fd := fo.get_node("Gameplay/Portes/Porte_du_reve") as PorteReveil
	check("forêt : la porte réveille le joueur dans la chambre", fd.target_scene == LEVEL and fd.target_spawn == "reveil")
	fo.free()
	# budgets : triangles, lumières, ombres
	var tris := 0
	for mi in lv.find_children("*", "MeshInstance3D", true, false):
		tris += StyleKit.triangles((mi as MeshInstance3D).mesh)
	var lights := lv.find_children("*", "Light3D", true, false)
	var shadows := lights.filter(func(l): return (l as Light3D).shadow_enabled).size()
	print("   %d triangles au total, %d lumières, %d avec ombres" % [tris, lights.size(), shadows])
	check("budget : ≤ 900 000 triangles pour tout le secteur (%d)" % tris, tris <= 900000)
	check("budget : ≤ 110 lumières (%d)" % lights.size(), lights.size() <= 110)
	check("budget : ≤ 2 lumières à ombres (%d)" % shadows, shadows <= 2)
	lv.free()

# ------------------------------------------------------------------ parcours joué (physique réelle)

func _walk_to(p: Explorer, target: Vector2, max_frames := 900, sprint := false) -> bool:
	p.auto_active = true
	p.auto_sprint = sprint
	var guard := 0
	while Vector2(p.global_position.x, p.global_position.z).distance_to(target) > 0.6 and guard < max_frames:
		p.auto_dir = (target - Vector2(p.global_position.x, p.global_position.z)).normalized()
		await physics_frame
		guard += 1
	p.auto_active = false
	p.auto_dir = Vector2.ZERO
	return guard < max_frames

func _face(lv: Level, yaw_deg: float) -> void:
	lv.camera.yaw = deg_to_rad(yaw_deg)
	lv.camera.pitch = -0.1
	lv.camera.snap()

func _level_played() -> void:
	print("-- parcours joué")
	var lv := (load(LEVEL) as PackedScene).instantiate() as Level
	root.add_child(lv)
	for i in 40:
		await physics_frame
	var p := lv.player
	check("arrivée : Star-Faced One au sol dans l'atrium", p.is_on_floor() and absf(p.global_position.y) < 0.15, str(p.global_position))
	check("arrivée : 3e personne", not lv.camera.first_person)
	# l'atrium : marcher jusqu'au comptoir, qui arrête le joueur
	var ok := await _walk_to(p, Vector2(0, -2.0), 300)
	check("atrium : le comptoir de réception bloque le passage", not ok and p.global_position.z > 2.5, str(p.global_position))
	# l'escalier ouest mène à la galerie nord (6 m)
	p.teleport(Vector3(-9.0, 0.1, 0.6), 0.0)
	await physics_frame
	ok = await _walk_to(p, Vector2(-9.0, -10.6), 900)
	check("escalier : montée jusqu'à la galerie", ok and p.global_position.y > 5.8, str(p.global_position))
	for i in 15:
		await physics_frame
	check("escalier : sur le sol de la galerie", p.is_on_floor(), str(p.global_position))
	# la galerie nord relie les deux escaliers ; on y circule à 6 m
	ok = await _walk_to(p, Vector2(9.0, -11.0), 900)
	check("galerie : traversée d'ouest en est à 6 m", ok and absf(p.global_position.y - 6.0) < 0.2, str(p.global_position))
	# galerie est jusqu'au mur sud
	ok = await _walk_to(p, Vector2(13.0, -9.0), 400)
	ok = ok and await _walk_to(p, Vector2(13.2, 11.5), 900)
	check("galerie est : jusqu'au fond, toujours à 6 m", ok and absf(p.global_position.y - 6.0) < 0.2, str(p.global_position))
	# la balustrade empêche de tomber de la galerie
	p.auto_active = true
	p.auto_dir = Vector2(-1, 0)
	for i in 180:
		await physics_frame
	p.auto_active = false
	check("galerie : la balustrade retient le joueur", p.global_position.y > 5.8 and p.global_position.x > 11.4, str(p.global_position))
	# descente par l'escalier est
	p.teleport(Vector3(9.0, 6.1, -10.2), PI)
	await physics_frame
	ok = await _walk_to(p, Vector2(9.0, 1.5), 900)
	check("escalier : descente jusqu'au rez-de-chaussée", ok and p.global_position.y < 0.3 and p.is_on_floor(), str(p.global_position))
	# vers le couloir par l'arche est
	ok = await _walk_to(p, Vector2(13.5, 0.0), 600)
	ok = ok and await _walk_to(p, Vector2(20.0, 0.0), 600)
	check("couloir : on y entre par l'arche de l'atrium", ok and p.global_position.x > 19.0, str(p.global_position))
	ok = await _walk_to(p, Vector2(49.5, 0.0), 1800, true)
	check("couloir : traversée complète (36 m)", ok, str(p.global_position))
	p.auto_active = true
	p.auto_dir = Vector2(1, 0)
	for i in 120:
		await physics_frame
	p.auto_active = false
	check("couloir : le mur du fond arrête le joueur", p.global_position.x < 51.6, str(p.global_position))
	p.auto_active = true
	p.auto_dir = Vector2(0, 1)
	for i in 200:
		await physics_frame
	p.auto_active = false
	check("couloir : les murs latéraux tiennent", p.global_position.z < 3.0, str(p.global_position))
	# une porte verrouillée : message, pas de geste
	p.teleport(Vector3(17.85, 0.05, -1.2), 0.0)
	_face(lv, 0.0)
	await physics_frame
	lv._update_focus()
	check("porte 101 : visée", lv.focused is HotelDoor and (lv.focused as HotelDoor).number == "101", str(lv.focused))
	if lv.focused:
		check("porte 101 : verrouillée → aucun geste", lv.focused.gesture_for(p) == &"")
		lv.focused.use(lv)
		check("porte 101 : message affiché", lv._toast.text != "")
	# la chambre 107 : la porte s'ouvre, on entre
	var x107 := 15.6 + 4.5 * 3.5
	p.teleport(Vector3(x107, 0.05, -1.2), 0.0)
	_face(lv, 0.0)
	await physics_frame
	lv._update_focus()
	var door := lv.get_node("Couloir/Portes/Porte_107") as HotelDoor
	check("porte 107 : visée", lv.focused == door, str(lv.focused))
	check("porte 107 : ouvrable → geste « interact »", door.gesture_for(p) == &"interact")
	door.use(lv)
	await physics_frame
	check("porte 107 : ouverte", door.is_open)
	ok = await _walk_to(p, Vector2(x107, -5.0), 600)
	check("chambre : on y entre", ok and p.global_position.z < -4.4, str(p.global_position))
	check("chambre : au sol", p.is_on_floor())
	# le lit : se coucher pour rêver
	p.teleport(Vector3(33.2, 0.05, -5.4), deg_to_rad(-60.0))
	_face(lv, -60.0)
	await physics_frame
	lv._update_focus()
	var bed := lv.get_node("Chambre/Lit_du_reveur") as DreamBed
	check("lit : visé (« Se coucher et rêver »)", lv.focused == bed and lv._prompt.text.contains("rêver"), "%s / %s" % [lv.focused, lv._prompt.text])
	bed.use(lv)
	for i in 10:
		await physics_frame
	check("lit : le joueur est couché sur le lit", p.global_position.distance_to(bed.get_node("Coucher").global_position) < 0.4 and p.global_position.y > 0.6, str(p.global_position))
	check("lit : commandes gelées pendant l'endormissement", not p.control_enabled)
	check("lit : Star-Faced One s'endort (geste « sleep »)", p.model.is_busy() or p.model.is_sleeping())
	lv.queue_free()
	await process_frame
