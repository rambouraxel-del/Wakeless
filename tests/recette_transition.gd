extends Node
## Recette jouée du jeu COMPLET (autoload App, vrais niveaux, vraie physique, sans rendu) : couloir → forêt → couloir.
##   godot --headless --path . -- --recette=res://tests/recette_transition.gd
## Le script est ajouté par l'autoload App au-dessus de la scène principale (le Bureau des rêves).

var _fail := 0
var _ok := 0

func check(name: String, cond: bool, detail := "") -> void:
	if cond:
		_ok += 1
	else:
		_fail += 1
		print("  ÉCHEC  %s %s" % [name, detail])

func _ready() -> void:
	_run()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _wait_scene(path: String, timeout_s := 15.0) -> bool:
	var t := 0.0
	while t < timeout_s:
		await get_tree().process_frame
		t += get_process_delta_time()
		var cs := get_tree().current_scene
		if cs != null and cs.scene_file_path == path and not App.transitioning:
			return true
	return false

func _run() -> void:
	await _frames(20)
	var cs := get_tree().current_scene as Level
	check("lancement : le Bureau des rêves est la scène principale", cs != null and cs.level_id == "bureau-couloir")
	check("lancement : App connaît la scène", App.current_path == "res://scenes/levels/bureau_couloir.tscn", App.current_path)
	# --- couloir → forêt : face à la porte du rêve, E
	var p := cs.player
	p.teleport(Vector3(24.4, 0.05, 0.0), deg_to_rad(-90.0))
	cs.camera.yaw = deg_to_rad(-90.0)
	cs.camera.pitch = 0.0
	cs.camera.snap()
	await _frames(3)
	cs._update_focus()
	check("transition : porte du rêve visée", cs.focused != null and cs.focused.name == "Porte_du_reve")
	var door := cs.focused as SceneDoor
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	cs._unhandled_input(ev)                       # même chemin que la touche E
	check("transition : porte ouverte au battant", door.is_open)
	check("transition : commandes du joueur gelées pendant la transition", not p.control_enabled)
	var arrived := await _wait_scene("res://scenes/levels/foret_nocturne.tscn")
	check("transition : la forêt est chargée (scène distincte)", arrived)
	await _frames(40)
	var fo := get_tree().current_scene as Level
	check("forêt : niveau courant", fo != null and fo.level_id == "foret-nocturne")
	check("forêt : l'ancienne scène est déchargée", get_tree().root.get_children().filter(func(n): return n is Level).size() == 1)
	check("forêt : arrivée sur le point « depart »", fo.spawn_id == "depart" and fo.player.global_position.distance_to(fo.get_node("Spawns/depart").global_position) < 0.3, str(fo.player.global_position))
	check("forêt : joueur au sol", fo.player.is_on_floor())
	check("forêt : lumière de lune et ambiance appliquées", fo.rig.current_name() == "Forêt · nuit", fo.rig.current_name())
	# --- forêt → couloir : porte de retour
	fo.player.teleport(Vector3(0.0, fo.player.global_position.y, 2.4), PI)
	fo.camera.yaw = 0.0
	fo.camera.pitch = 0.0
	fo.camera.snap()
	await _frames(3)
	fo._update_focus()
	check("retour : porte de retour visée", fo.focused != null and fo.focused.name == "Porte_du_reve")
	fo._unhandled_input(ev)
	var back := await _wait_scene("res://scenes/levels/bureau_couloir.tscn")
	check("retour : le couloir est rechargé", back)
	await _frames(40)
	var cs2 := get_tree().current_scene as Level
	check("retour : arrivée sur « retour_foret » devant la porte", cs2.spawn_id == "retour_foret" and cs2.player.global_position.distance_to(cs2.get_node("Spawns/retour_foret").global_position) < 0.3, str(cs2.player.global_position))
	check("retour : joueur au sol", cs2.player.is_on_floor())
	check("retour : éclairage de l'hôtel", cs2.rig.current_name().begins_with("Bureau des rêves"), cs2.rig.current_name())
	# pause : Échap met le jeu en pause, la reprise le relance
	App.pause()
	check("pause : arbre en pause", get_tree().paused and App.paused_menu)
	App.resume()
	check("pause : reprise", not get_tree().paused)
	# sauvegarde : les deux niveaux ont été notés comme visités
	check("sauvegarde : niveaux visités", GameSave.level("bureau-couloir").get("visited") == true and GameSave.level("foret-nocturne").get("visited") == true)
	print("== recette de transition : %d vérifications réussies, %d échec(s)" % [_ok, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
