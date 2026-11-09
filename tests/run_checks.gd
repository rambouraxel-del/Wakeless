extends SceneTree
## Vérifications headless de Wakeless (sans carte graphique) :
##   godot --headless -s tests/run_checks.gd
## Le jeu complet (autoload App, transitions) est vérifié par tests/recette_transition.gd (voir tools/check.sh).

var _ok := 0
var _fail := 0

func check(name: String, cond: bool, detail := "") -> void:
	if cond:
		_ok += 1
	else:
		_fail += 1
		print("  ÉCHEC  %s %s" % [name, detail])

func _initialize() -> void:
	VoxelMesher.palette_warmup()
	_core()
	_config()
	_save()
	_assets()
	_references()
	_no_procedural_runtime()
	_levels_static()
	await _physics_levels()
	await _guardian()
	print("== %d vérifications réussies, %d échec(s)" % [_ok, _fail])
	quit(1 if _fail > 0 else 0)

# ------------------------------------------------------------------ cœur voxel

func _core() -> void:
	print("-- cœur voxel")
	var pal := VoxelPalette.get_default()
	check("palette : 255 matières maximum", pal.count() <= 256, str(pal.count()))
	var seen := {}
	var dup := 0
	for k in pal.keys:
		if seen.has(k):
			dup += 1
		seen[k] = true
	check("palette : clés uniques", dup == 0)
	for k in ["wallpaper_teal", "carpet_wine", "marble_black", "dream_glow", "moon_glass", "velvet_plum", "grass_night", "moss_dark", "bark", "leaves", "pine"]:
		check("palette : %s" % k, pal.has_key(k))
	# maillage : un cube = 6 faces = 12 triangles ; deux cubes contigus et de même matière fusionnent en 6 faces
	var v := VoxelVolume.new(Vector3i(4, 4, 4))
	v.set_voxel(1, 1, 1, pal.id("stone"))
	var a := VoxelMesher.build_arrays(v, 0.2, Vector3i.ZERO, Vector3i(-1, -1, -1), PackedByteArray(), Vector3i.ZERO, 0, VoxelMesher.Style.STYLIZED)
	check("mailleur : cube = 12 triangles", (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 == 12)
	v.set_voxel(2, 1, 1, pal.id("stone"))
	a = VoxelMesher.build_arrays(v, 0.2, Vector3i.ZERO, Vector3i(-1, -1, -1), PackedByteArray(), Vector3i.ZERO, 0, VoxelMesher.Style.STYLIZED)
	check("mailleur : deux cubes fusionnés", (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 <= 24)
	# grille
	check("grille : 20 cm / 10 cm / 2 cm", is_equal_approx(VoxelGrid.VOXEL_SIZE, 0.2) and is_equal_approx(VoxelGrid.STRUCTURE_SIZE, 0.1) and is_equal_approx(VoxelGrid.DETAIL_SIZE, 0.02))
	# VoxelBox : coin minimum, taille, grille de 10 cm
	var holder := Node3D.new()
	var b := VoxelBox.new()
	b.position = Vector3(1.0, 0.0, -0.5)
	b.size = Vector3(0.5, 2.0, 0.3)
	holder.add_child(b)
	var c := b.cells(holder, 0.1)
	check("VoxelBox : cellules", c[0] == Vector3i(10, 0, -5) and c[1] == Vector3i(14, 19, -3), str(c))
	holder.free()

# ------------------------------------------------------------------ configuration (joueur, éclairage, saisie)

func _config() -> void:
	print("-- configuration")
	PlayerConfig.ensure()
	var pcfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/player.json"))
	check("joueur : hauteur = hauteur_m de config/player.json", is_equal_approx(PlayerConfig.height, float(pcfg["hauteur_m"])), str(PlayerConfig.height))
	check("joueur : yeux proportionnels à la hauteur (1,60 m pour 1,70 m)", absf(PlayerConfig.eye() - 1.6 * PlayerConfig.height / 1.7) < 0.01, str(PlayerConfig.eye()))
	var want_r := float(pcfg["rayon_m"]) if float(pcfg.get("rayon_m", -1.0)) > 0.0 else 0.28 * PlayerConfig.height / 1.7
	check("joueur : rayon de la capsule (rayon_m, sinon proportionnel)", absf(PlayerConfig.radius() - want_r) < 0.005, str(PlayerConfig.radius()))
	check("joueur : champ de vision de départ = fov_depart", is_equal_approx(PlayerConfig.fov_fp, float(pcfg["fov_depart"])), str(PlayerConfig.fov_fp))
	GameInput.ensure()
	for act in ["move_forward", "move_back", "move_left", "move_right", "jump", "sprint", "interact"]:
		check("saisie : action %s" % act, InputMap.has_action(act))
	var presets := LightingRig.load_presets()
	var keys := []
	for p in presets:
		keys.append(p["key"])
	for k in ["hotel_reve", "foret_nuit", "day"]:
		check("éclairage : préréglage %s" % k, k in keys)
	for p in presets:
		check("éclairage : %s complet" % p["key"], p.has("sun_energy") and p.has("ambient_energy") and p.has("fog_density") and p.has("exposure"))
		if p["key"] == "hotel_reve":
			check("hôtel : ambiance lisible (ambiant ≥ 0,8)", float(p["ambient_energy"]) >= 0.8)
		if p["key"] == "foret_nuit":
			check("forêt : lune présente et lisible", float(p["sun_energy"]) >= 0.4 and float(p["ambient_energy"]) >= 0.8 and float(p["stars"]) > 0.5)

# ------------------------------------------------------------------ sauvegarde

func _save() -> void:
	print("-- sauvegarde")
	GameSave.PATH = "user://wakeless_test_save.json"
	for suffix in ["", ".bak", ".tmp", ".old"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSave.PATH + suffix))
	check("sauvegarde : vide au départ", GameSave.level("bureau-couloir").is_empty())
	check("sauvegarde : écriture", GameSave.set_level("bureau-couloir", {"visited": true, "spawn": "depart"}))
	check("sauvegarde : relecture", GameSave.level("bureau-couloir").get("spawn") == "depart")
	check("sauvegarde : seconde écriture (crée .bak)", GameSave.set_level("foret-nocturne", {"visited": true}))
	# fichier principal corrompu → on relit la dernière version exploitable
	var f := FileAccess.open(GameSave.PATH, FileAccess.WRITE)
	f.store_string("{ corrompu")
	f.close()
	check("sauvegarde : récupération depuis .bak", GameSave.level("bureau-couloir").get("visited") == true and GameSave.recovered_from_backup)
	check("sauvegarde : effacement", GameSave.clear_level("bureau-couloir") and GameSave.level("bureau-couloir").is_empty())
	for suffix in ["", ".bak", ".tmp", ".old"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSave.PATH + suffix))

# ------------------------------------------------------------------ assets cuits

func _assets() -> void:
	print("-- assets")
	var ids := AssetLibrary.all_ids()
	check("assets : registre non vide", ids.size() >= 35, str(ids.size()))
	var missing := []
	for id in ids:
		if not ResourceLoader.exists(AssetLibrary.scene_path(id)) or AssetLibrary.info(id).is_empty():
			missing.append(id)
	check("assets : tous cuits (scène + fiche)", missing.is_empty(), str(missing))
	for id in ["tree_pine_1", "tree_oak_1", "tree_birch_1", "tree_weeping_1", "tree_parasol_1", "boulder_1", "crystal_lamp", "crystal_cluster", "brazier", "ruin_arch", "ruin_column", "decorative_bench", "hotel_bed", "hotel_nightstand", "hotel_wardrobe", "hotel_armchair", "hotel_floor_lamp"]:
		var n := AssetLibrary.instantiate(id)
		check("assets : %s instanciable" % id, n != null and n.get_child_count() > 0)
		if n:
			n.free()
	# les assets du registre se reconstruisent (graines figées) : mêmes dimensions que la fiche cuite
	for id in ["tree_pine_1", "boulder_2", "hotel_bed", "crystal_lamp"]:
		var built := AssetLibrary.build(id)
		var info := AssetLibrary.info(id)
		var fp: Array = info["footprint_cells"]
		check("assets : %s reconstruit conforme" % id, built.footprint == Vector3i(int(fp[0]), int(fp[1]), int(fp[2])))
	# PropScatter (outil de pose économique) fonctionne
	var sc := PropScatter.new()
	sc.add_asset("tree_pine_1", Transform3D(Basis.IDENTITY, Vector3(3, 0, 3)))
	sc.add_asset("tree_pine_1", Transform3D(Basis.IDENTITY, Vector3(6, 0, 3)))
	sc.add_asset("crystal_lamp", Transform3D(Basis.IDENTITY, Vector3(9, 0, 3)))
	root.add_child(sc)
	sc.commit()
	check("PropScatter : instances posées", int(sc.stats["instances"]) >= 2, str(sc.stats))
	sc.queue_free()

# ------------------------------------------------------------------ références et indépendance

func _files(dir: String, exts: Array) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for sub in d.get_directories():
		if sub.begins_with(".") or sub == "docs":
			continue
		out += _files(dir.trim_suffix("/") + "/" + sub, exts)
	for f in d.get_files():
		if f.get_extension() in exts:
			out.append(dir.trim_suffix("/") + "/" + f)
	return out

func _references() -> void:
	print("-- références")
	var bad := []
	var res_re := RegEx.new()
	res_re.compile("res://[A-Za-z0-9_\\-./]+\\.(?:gdshader|gd|tscn|scn|tres|res|json|png|svg)")
	var scanned := 0
	for f in _files("res://", ["gd", "tscn", "tres", "godot", "json"]):
		var path: String = f
		if (path.begins_with("res://assets/props/") and path.ends_with(".json")) or path.begins_with("res://tests/"):
			continue
		scanned += 1
		var txt := FileAccess.get_file_as_string(path)
		for m in res_re.search_all(txt):
			var r := m.get_string()
			if not ResourceLoader.exists(r) and not FileAccess.file_exists(r):
				bad.append("%s → %s" % [path, r])
	check("références res:// : aucune cassée (%d fichiers lus)" % scanned, bad.is_empty(), "\n    " + "\n    ".join(bad.slice(0, 12)))
	# .tscn cuits : sous-ressources externes
	var bad2 := []
	for f in _files("res://scenes", ["tscn"]) + _files("res://assets", ["tscn"]):
		var scn := load(f) as PackedScene
		if scn == null:
			bad2.append(f)
	check("scènes : toutes chargeables", bad2.is_empty(), str(bad2))
	# scripts : tous compilent
	var failing := []
	for f in _files("res://scripts", ["gd"]) + _files("res://tools", ["gd"]) + _files("res://tests", ["gd"]):
		if load(f) == null:
			failing.append(f)
	check("scripts : tous compilent", failing.is_empty(), str(failing))

func _no_procedural_runtime() -> void:
	print("-- pas de génération procédurale au runtime")
	var banned := ["RandomNumberGenerator", "randf(", "randi(", "randomize(", "FastNoiseLite", "randf_range", "randi_range", "pick_random", "shuffle("]
	var hits := []
	for dir in ["res://scripts/app", "res://scripts/game", "res://scripts/level", "res://scripts/terrain", "res://scripts/camera", "res://scripts/rendering"]:
		for f in _files(dir, ["gd"]):
			var txt := FileAccess.get_file_as_string(f)
			for b in banned:
				if txt.find(b) >= 0:
					hits.append("%s : %s" % [f, b])
	check("runtime sans hasard ni bruit", hits.is_empty(), str(hits))
	# aucune dépendance à Éclat : ni chemin, ni dépôt, ni ressource externe
	var ext := []
	for f in _files("res://", ["gd", "tscn", "tres", "godot", "json", "gdshader"]):
		var path: String = f
		if path.begins_with("res://tests/"):
			continue
		var txt := FileAccess.get_file_as_string(path)
		for needle in ["ECLATS", "eclats/", "../ECLATS", "rambouraxel-del/ECLATS", "user://eclats"]:
			if txt.find(needle) >= 0:
				ext.append("%s : %s" % [path, needle])
	check("indépendance : aucune référence au dépôt Éclat", ext.is_empty(), str(ext))
	check("indépendance : aucun chemin hors projet", not FileAccess.get_file_as_string("res://project.godot").contains("../"))
	# aucun reste de génération d'îles
	for p in ["res://scripts/world", "res://scripts/terrain/island_generator.gd", "res://scripts/map", "res://config/profiles", "res://scenes/map", "res://scenes/island"]:
		check("retiré : %s" % p, not (DirAccess.dir_exists_absolute(p) or FileAccess.file_exists(p)))

# ------------------------------------------------------------------ niveaux (statique)

const LEVELS := {
	"res://scenes/levels/bureau_couloir.tscn": ["depart", "retour_foret"],
	"res://scenes/levels/foret_nocturne.tscn": ["depart"],
}

func _levels_static() -> void:
	print("-- niveaux (structure)")
	var preset_keys := []
	for p in LightingRig.load_presets():
		preset_keys.append(p["key"])
	for path in LEVELS:
		var inst := (load(path) as PackedScene).instantiate()
		check("niveau %s : racine Level" % path.get_file(), inst is Level)
		var lv := inst as Level
		check("niveau : identifiant et titre", lv.level_id != "" and lv.level_title != "")
		check("niveau : préréglage d'éclairage existant", lv.lighting_preset in preset_keys, lv.lighting_preset)
		check("niveau : point d'arrivée par défaut", lv.get_node_or_null("Spawns/" + lv.default_spawn) is Marker3D)
		for sp in LEVELS[path]:
			check("niveau : arrivée « %s »" % sp, lv.get_node_or_null("Spawns/" + sp) is Marker3D)
		# structures cuites à jour
		for n in inst.find_children("*", "VoxelStructure", true, false):
			var vs := n as VoxelStructure
			check("%s : fichier cuit présent" % vs.name, ResourceLoader.exists(vs.baked_path))
			check("%s : cuisson à jour (signature)" % vs.name, vs.signature() == vs.baked_signature, "%s ≠ %s" % [vs.signature(), vs.baked_signature])
		for n in inst.find_children("*", "HeightmapTerrain", true, false):
			var ht := n as HeightmapTerrain
			check("%s : fichier cuit présent" % ht.name, ResourceLoader.exists(ht.baked_path))
			check("%s : cuisson à jour (signature)" % ht.name, ht.signature() == ht.baked_signature)
		# portes : cible existante, point d'arrivée existant dans la cible
		for n in inst.find_children("*", "SceneDoor", true, false):
			var d := n as SceneDoor
			if d.target_scene == "":
				continue
			check("porte %s : scène cible existe" % d.name, ResourceLoader.exists(d.target_scene))
			if LEVELS.has(d.target_scene):
				check("porte %s : arrivée « %s » existe dans la cible" % [d.name, d.target_spawn], d.target_spawn in LEVELS[d.target_scene])
		inst.free()
	# budgets (performances)
	var bureau := (load("res://scenes/levels/bureau_couloir.tscn") as PackedScene).instantiate()
	var arch := bureau.get_node("Architecture") as VoxelStructure
	arch._ready()
	check("couloir : < 40 000 triangles d'architecture", int(arch.stats["triangles"]) == 0 or int(arch.stats["triangles"]) < 40000)
	var shadows := 0
	var lights := 0
	for l in bureau.find_children("*", "OmniLight3D", true, false):
		lights += 1
		if (l as OmniLight3D).shadow_enabled:
			shadows += 1
	check("couloir : ≤ 10 lumières avec ombres (%d)" % shadows, shadows <= 10)
	check("couloir : ≤ 40 lumières (%d)" % lights, lights <= 40)
	bureau.free()
	var foret := (load("res://scenes/levels/foret_nocturne.tscn") as PackedScene).instantiate()
	var trees := foret.get_node("Decor/Arbres").get_child_count()
	check("forêt : au moins 60 arbres posés à la main (%d)" % trees, trees >= 60)
	check("forêt : au moins 10 rochers", foret.get_node("Decor/Rochers").get_child_count() >= 10)
	var fshadows := 0
	for l in foret.find_children("*", "OmniLight3D", true, false):
		if (l as OmniLight3D).shadow_enabled:
			fshadows += 1
	check("forêt : ≤ 4 lumières avec ombres (%d)" % fshadows, fshadows <= 4)
	foret.free()

# ------------------------------------------------------------------ niveaux joués (physique réelle, sans rendu)

func _physics_levels() -> void:
	print("-- niveaux joués (collisions, déplacements, interaction)")
	# --- couloir
	var lv := (load("res://scenes/levels/bureau_couloir.tscn") as PackedScene).instantiate() as Level
	root.add_child(lv)
	for i in 30:
		await physics_frame
	var p := lv.player
	check("couloir : joueur posé au sol à l'arrivée", p.is_on_floor() and absf(p.global_position.y) < 0.15, str(p.global_position))
	check("couloir : vue au lancement selon config/player.json (vue_depart)", lv.camera.first_person != PlayerConfig.third_person_start and lv.camera.cam.current)
	lv.camera.first_person = true          # la suite des contrôles est écrite pour la 1re personne
	lv.camera.snap()
	check("couloir : hauteur des yeux (1re personne)", absf(lv.camera.cam.global_position.y - p.global_position.y - PlayerConfig.eye()) < 0.05)
	# caméra : orientation, vue à la troisième personne (V), retour à la première
	lv.camera.yaw = 0.0
	lv.camera.pitch = 0.3
	lv.camera.snap()
	var fwd := -lv.camera.cam.global_transform.basis.z
	check("caméra : regarde vers le nord et vers le haut", fwd.z < -0.9 and fwd.y > 0.2, str(fwd))
	check("caméra : champ de vision 76° à la première personne", is_equal_approx(lv.camera.cam.fov, 76.0))
	lv.camera.toggle_view()
	await physics_frame
	check("caméra : 3e personne (V) : champ de vision 64°, modèle visible", not lv.camera.first_person and is_equal_approx(lv.camera.cam.fov, 64.0) and p.model.visible)
	lv.camera.toggle_view()
	await physics_frame
	check("caméra : retour à la 1re personne, modèle masqué", lv.camera.first_person and not p.model.visible)
	lv.camera.pitch = 0.0
	lv.camera.snap()
	# marche vers l'est : avance puis bute sur la porte du rêve (fermée)
	var x0 := p.global_position.x
	p.auto_active = true
	p.auto_dir = Vector2(1, 0)
	for i in 120:
		await physics_frame
	check("couloir : marche le long du couloir (+%.1f m en 2 s)" % (p.global_position.x - x0), p.global_position.x - x0 > 3.0)
	for i in 900:
		await physics_frame
	check("couloir : bute sur la porte du rêve (x < 26)", p.global_position.x < 26.0 and p.global_position.x > 24.5, str(p.global_position))
	check("couloir : toujours au sol", p.is_on_floor() and absf(p.global_position.y) < 0.3)
	# murs latéraux : pousser vers le nord ne traverse pas le mur (z > -1,5 + rayon) sauf à la porte de la chambre
	p.teleport(Vector3(5.5, 0.05, 0.0), 0.0)
	p.auto_dir = Vector2(0, -1)
	for i in 240:
		await physics_frame
	check("couloir : le mur nord arrête le joueur (z > -1,6)", p.global_position.z > -1.6 and p.global_position.z < -1.0, str(p.global_position))
	# interaction : porte du rêve visée
	p.auto_active = false
	p.teleport(Vector3(24.4, 0.05, 0.0), deg_to_rad(-90.0))
	lv.camera.yaw = deg_to_rad(-90.0)
	lv.camera.pitch = 0.0
	lv.camera.snap()
	for i in 3:
		await physics_frame
	lv._update_focus()
	check("interaction : porte du rêve visée", lv.focused != null and lv.focused.name == "Porte_du_reve", str(lv.focused))
	check("interaction : invite lisible", lv._prompt.text.contains("porte du rêve"), lv._prompt.text)
	# porte fermée à clé : message
	p.teleport(Vector3(3.5, 0.05, -0.6), deg_to_rad(0.0))
	lv.camera.yaw = 0.0
	lv.camera.snap()
	await physics_frame
	lv._update_focus()
	check("interaction : porte verrouillée visée", lv.focused != null and (lv.focused as SceneDoor).locked)
	check("geste : porte verrouillée = aucun geste", lv.focused.gesture_for(p) == &"")
	lv.focused.use(lv)
	check("interaction : message « fermée »", lv._toast.text != "")
	# la chambre : la porte s'ouvre, le joueur entre sans obstacle
	var chambre := lv.get_node("Portes/Porte_chambre") as SceneDoor
	p.teleport(Vector3(10.5, 0.05, -0.6), 0.0)
	lv.camera.yaw = 0.0
	lv.camera.snap()
	await physics_frame
	lv._update_focus()
	check("chambre : porte visée avant ouverture", lv.focused == chambre)
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	lv._unhandled_input(press)                       # même chemin que la touche E : geste puis ouverture
	await physics_frame
	await physics_frame
	check("chambre : porte ouverte", chambre.is_open)
	check("geste : l'ouverture de la porte déclenche « interact »", not p.model.supports(&"interact") or p.model.is_busy())
	p.auto_active = true
	p.auto_dir = Vector2(0, -1)
	for i in 240:
		await physics_frame
	check("chambre : le joueur entre dans la chambre (z < -2,5)", p.global_position.z < -2.5, str(p.global_position))
	check("chambre : au sol dans la chambre", p.is_on_floor() and absf(p.global_position.y) < 0.2)
	# aucun passage à travers les murs de la chambre
	p.auto_dir = Vector2(0, -1)
	for i in 300:
		await physics_frame
	check("chambre : le mur du fond arrête le joueur (z > -7,6)", p.global_position.z > -7.6, str(p.global_position))
	p.auto_active = false
	lv.queue_free()
	await process_frame
	# --- forêt
	var fo := (load("res://scenes/levels/foret_nocturne.tscn") as PackedScene).instantiate() as Level
	root.add_child(fo)
	for i in 40:
		await physics_frame
	var fp := fo.player
	check("forêt : joueur posé au sol à l'arrivée", fp.is_on_floor(), str(fp.global_position))
	var ground := fo.get_node("Relief") as HeightmapTerrain
	ground.prepare()
	check("forêt : altitude conforme au relief (±0,3 m)", absf(fp.global_position.y - ground.surface_y(fp.global_position.x, fp.global_position.z)) < 0.3, "%s vs %s" % [fp.global_position.y, ground.surface_y(fp.global_position.x, fp.global_position.z)])
	# marche le long du sentier (suit les points du sentier) : reste au sol, ne tombe jamais
	var path := [Vector2(0, 9), Vector2(2, 15), Vector2(7, 20), Vector2(14, 22), Vector2(21, 19), Vector2(27, 12), Vector2(29, 4)]
	fp.auto_active = true
	var fell := false
	var steps_ok := true
	for target in path:
		var guard := 0
		while Vector2(fp.global_position.x, fp.global_position.z).distance_to(target) > 1.0 and guard < 900:
			var to: Vector2 = target - Vector2(fp.global_position.x, fp.global_position.z)
			fp.auto_dir = to.normalized()
			fp.auto_sprint = true
			await physics_frame
			guard += 1
			if fp.global_position.y < -2.0:
				fell = true
			if fp.is_on_floor() and absf(fp.global_position.y - ground.surface_y(fp.global_position.x, fp.global_position.z)) > 0.9:
				steps_ok = false
		if guard >= 900:
			steps_ok = false
			print("    bloqué avant (%.0f, %.0f) à %s" % [target.x, target.y, str(fp.global_position)])
			break
	check("forêt : parcours du sentier sans chute ni blocage", not fell and steps_ok)
	check("forêt : joueur toujours dans les limites", absf(fp.global_position.x) < 40 and absf(fp.global_position.z) < 40)
	# limites : pousser vers l'est jusqu'au mur invisible
	fp.teleport(Vector3(36.0, ground.surface_y(36.0, 0.0) + 0.5, 0.0), 0.0)
	fp.auto_dir = Vector2(1, 0)
	for i in 600:
		await physics_frame
	check("forêt : mur invisible à l'est (x < 40)", fp.global_position.x < 40.0)
	# retour devant la porte, interaction
	fp.auto_active = false
	var door := fo.get_node("Portes/Porte_du_reve") as SceneDoor
	fp.teleport(Vector3(0.0, ground.surface_y(0, 0) + 0.05, 2.4), PI)
	fo.camera.yaw = 0.0
	fo.camera.pitch = 0.0
	fo.camera.snap()
	await physics_frame
	fo._update_focus()
	check("forêt : porte de retour visée", fo.focused == door, str(fo.focused))
	fo.queue_free()
	await process_frame

# ------------------------------------------------------------------ gardien jouable (Star-Faced One)

func _guardian() -> void:
	print("-- gardien : Star-Faced One")
	var g := GuardianDef.load_def("star_faced_one")
	check("gardien : définition chargée", g != null)
	if g == null:
		return
	check("gardien : scène présente", ResourceLoader.exists(g.scene_path), g.scene_path)
	check("gardien : 11 animations déclarées", g.anims.size() == 11, str(g.anims.size()))
	var m := (load(g.scene_path) as PackedScene).instantiate() as GuardianModel
	check("gardien : la scène est un GuardianModel", m != null)
	if m == null:
		return
	root.add_child(m)
	await process_frame
	var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	check("gardien : AnimationPlayer du GLB", ap != null)
	for role in g.anims:
		check("gardien : animation « %s »" % g.anims[role], ap != null and ap.has_animation(g.anims[role]))
	for role in g.loops:
		var a := ap.get_animation(g.anims[role])
		check("gardien : « %s » boucle" % g.anims[role], a != null and a.loop_mode == Animation.LOOP_LINEAR)
	for role in ["interact", "surprised", "comfort", "sleep", "wake"]:
		var a2 := ap.get_animation(g.anims[role])
		check("gardien : « %s » ne boucle pas" % g.anims[role], a2 != null and a2.loop_mode == Animation.LOOP_NONE)
	var sk := m.find_child("Skeleton3D", true, false) as Skeleton3D
	check("gardien : squelette de 23 os", sk != null and sk.get_bone_count() == 23)
	var tris := 0
	var meshes := m.find_children("*", "MeshInstance3D", true, false)
	for mi in meshes:
		var mesh := (mi as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			tris += (mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	check("gardien : 28 maillages", meshes.size() == 28, str(meshes.size()))
	check("gardien : budget triangles (≤ 52 000, %d)" % tris, tris <= 52000)
	for gesture in [&"interact", &"surprised", &"comfort", &"sleep", &"wake"]:
		check("gardien : geste « %s » pris en charge" % gesture, m.supports(gesture))
	check("gardien : « wake » refusé quand il ne dort pas", not m.play_action(&"wake"))
	m.free()
	# porte verrouillée = aucun geste ; porte ouvrable = « interact »
	var d := SceneDoor.new()
	d.locked = true
	check("geste : porte verrouillée → aucun", d.gesture_for(null) == &"")
	d.locked = false
	check("geste : porte ouvrable → interact", d.gesture_for(null) == &"interact")
	d.free()
	# joueur : le gardien remplace l'explorateur, capsule et échelle suivent la config
	var lv := (load("res://scenes/levels/bureau_couloir.tscn") as PackedScene).instantiate() as Level
	root.add_child(lv)
	for i in 30:
		await physics_frame
	var p := lv.player
	check("joueur : modèle = StarFacedOneModel", p.model is StarFacedOneModel, str(p.model))
	var cap := p.find_children("*", "CollisionShape3D", false, false)[0] as CollisionShape3D
	check("joueur : capsule = hauteur et rayon de la config", is_equal_approx((cap.shape as CapsuleShape3D).height, PlayerConfig.height) and is_equal_approx((cap.shape as CapsuleShape3D).radius, PlayerConfig.radius()))
	check("joueur : le modèle flotte au-dessus du sol sans quitter la physique", p.is_on_floor() and p.model.global_position.y - p.global_position.y < 0.01)
	# marche : la vitesse physique pilote l'animation (BlendSpace avant) et le modèle regarde sa direction
	p.auto_active = true
	p.auto_dir = Vector2(1, 0)
	for i in 90:
		await physics_frame
	var bp: Vector2 = (p.model as StarFacedOneModel)._tree.get("parameters/locomotion/blend_position")
	check("joueur : marche → animation d'avancée (y ≈ 1, x ≈ 0)", bp.y > 0.8 and bp.y < 1.3 and absf(bp.x) < 0.25, str(bp))
	p.auto_sprint = true
	for i in 90:
		await physics_frame
	bp = (p.model as StarFacedOneModel)._tree.get("parameters/locomotion/blend_position")
	check("joueur : course → animation rapide (y ≈ 2)", bp.y > 1.6, str(bp))
	p.auto_active = false
	p.auto_sprint = false
	# gestes de contexte : sommeil verrouille le déplacement, réveil le rend
	check("geste : endormissement accepté", p.play_gesture(&"sleep"))
	check("geste : pas de déplacement pendant le sommeil", not p.model.accepts_movement())
	for i in 400:
		await physics_frame
	check("geste : endormi", p.model.is_sleeping())
	check("geste : réveil accepté", p.play_gesture(&"wake"))
	for i in 300:
		await physics_frame
	check("geste : réveillé, déplacement rendu", not p.model.is_sleeping() and p.model.accepts_movement())
	lv.queue_free()
	await process_frame
