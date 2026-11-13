extends Node
## Recette jouée du jeu COMPLET (autoload App, vrais niveaux, vraie physique, sans rendu) :
## Bureau des rêves → porte de la chambre 107 → s'endormir dans le lit → forêt (le rêve) → se réveiller sur le lit.
##   godot --headless --path . -- --recette=res://tests/recette_transition.gd
## Le script est ajouté par l'autoload App au-dessus de la scène principale (le Bureau des rêves).

const BUREAU := "res://scenes/levels/bureau_des_reves.tscn"
const FORET := "res://scenes/levels/foret_de_la_peur.tscn"

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

func _press_e(lv: Level) -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	lv._unhandled_input(ev)                       # même chemin que la touche E

func _aim(lv: Level, pos: Vector3, yaw_deg: float) -> void:
	lv.player.teleport(pos, deg_to_rad(yaw_deg))
	lv.camera.yaw = deg_to_rad(yaw_deg)
	lv.camera.pitch = -0.1
	lv.camera.snap()
	await _frames(3)
	lv._update_focus()

func _run() -> void:
	await _frames(20)
	var cs := get_tree().current_scene as Level
	check("lancement : le Bureau des rêves est la scène principale", cs != null and cs.level_id == "bureau-des-reves")
	check("lancement : App connaît la scène", App.current_path == BUREAU, App.current_path)
	check("lancement : arrivée dans l'atrium", cs.spawn_id == "depart")
	# --- la chambre 107 : ouvrir la porte avec E
	await _aim(cs, Vector3(15.6 + 4.5 * 3.5, 0.05, -1.2), 0.0)
	check("chambre : porte 107 visée", cs.focused != null and cs.focused.name == "Porte_107")
	_press_e(cs)
	await _frames(2)
	check("chambre : porte 107 ouverte", (cs.get_node("Couloir/Portes/Porte_107") as HotelDoor).is_open)
	# --- s'endormir dans le lit : on entre dans le rêve (scène distincte)
	await _aim(cs, Vector3(33.2, 0.05, -5.4), -60.0)
	check("lit : visé", cs.focused is DreamBed)
	_press_e(cs)
	check("lit : commandes gelées (endormissement)", not cs.player.control_enabled)
	var arrived := await _wait_scene(FORET)
	check("rêve : La Forêt de la peur est chargée", arrived)
	await _frames(40)
	var fo := get_tree().current_scene as Level
	check("rêve : niveau courant", fo != null and fo.level_id == "foret-de-la-peur")
	check("rêve : l'hôtel est déchargé", get_tree().root.get_children().filter(func(n): return n is Level).size() == 1)
	check("rêve : arrivée sur « depart »", fo.spawn_id == "depart" and fo.player.global_position.distance_to(fo.get_node("Spawns/depart").global_position) < 0.3, str(fo.player.global_position))
	check("rêve : joueur au sol", fo.player.is_on_floor())
	check("rêve : ambiance « Forêt de la peur »", fo.rig.current_name() == "Forêt de la peur", fo.rig.current_name())
	# --- on traverse la forêt jusqu'à la clairière (arrivée « clairiere ») puis on se réveille par la porte
	fo.move_player_to("clairiere")
	await _frames(30)
	check("rêve : arrivée « clairiere » au sol", fo.player.is_on_floor(), str(fo.player.global_position))
	var porte := fo.get_node("Gameplay/Portes/Porte_du_reve") as Node3D
	var from := porte.global_position + Vector3(0, 0.0, 0) + Vector3(-2.9, 0.6, 0.0)
	await _aim(fo, from, -90.0)
	check("réveil : porte de la clairière visée", fo.focused != null and fo.focused.name == "Porte_du_reve", str(fo.focused))
	check("réveil : invite « Se réveiller »", fo._prompt.text.contains("réveiller"), fo._prompt.text)
	_press_e(fo)
	var back := await _wait_scene(BUREAU)
	check("réveil : retour au Bureau des rêves", back)
	await _frames(40)
	var cs2 := get_tree().current_scene as Level
	check("réveil : arrivée sur le lit (« reveil »)", cs2.spawn_id == "reveil" and cs2.player.global_position.distance_to(cs2.get_node("Spawns/reveil").global_position) < 0.5, str(cs2.player.global_position))
	check("réveil : ambiance de l'hôtel", cs2.rig.current_name().begins_with("Bureau des rêves"), cs2.rig.current_name())
	# pause : Échap met le jeu en pause, la reprise le relance
	App.pause()
	check("pause : arbre en pause", get_tree().paused and App.paused_menu)
	App.resume()
	check("pause : reprise", not get_tree().paused)
	check("sauvegarde : niveaux visités", GameSave.level("bureau-des-reves").get("visited") == true and GameSave.level("foret-de-la-peur").get("visited") == true)
	# l'ancien couloir voxel reste accessible (F4)
	App.open(App.SCENE_COULOIR)
	check("ancien couloir voxel : toujours chargeable (F4)", await _wait_scene(App.SCENE_COULOIR))
	print("== recette : %d vérifications réussies, %d échec(s)" % [_ok, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
