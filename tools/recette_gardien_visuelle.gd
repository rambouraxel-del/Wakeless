extends Node
## Recette VISUELLE du gardien jouable, avec rendu réel (GPU) : le jeu complet est joué par script, du couloir à la forêt.
##   godot --path . -- --recette=res://tools/recette_gardien_visuelle.gd --sorties=<dossier> [--mode=captures|film|perf]
##   captures (défaut) : captures d'écran numérotées dans <dossier> ;
##   film              : même parcours sans captures (à lancer avec --write-movie <fichier.avi> --fixed-fps 30) ;
##   perf              : mesure des FPS (à lancer avec --disable-vsync) dans le couloir puis dans la forêt.
## L'autoload App ajoute ce script au-dessus de la scène principale (voir tests/recette_transition.gd).

var _out := "user://captures"
var _mode := "captures"
var _n := 0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sorties="):
			_out = a.substr(10)
		elif a.begins_with("--mode="):
			_mode = a.substr(7)
	DirAccess.make_dir_recursive_absolute(_out)
	_run()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _wait_scene(path: String, timeout_s := 20.0) -> bool:
	var t := 0.0
	while t < timeout_s:
		await get_tree().process_frame
		t += get_process_delta_time()
		var cs := get_tree().current_scene
		if cs != null and cs.scene_file_path == path and not App.transitioning:
			return true
	return false

func _shot(label: String) -> void:
	if _mode != "captures":
		return
	await RenderingServer.frame_post_draw
	_n += 1
	var img := get_viewport().get_texture().get_image()
	var p := "%s/%02d_%s.png" % [_out, _n, label]
	img.save_png(p)
	print("capture : ", p)

func _lvl() -> Level:
	return get_tree().current_scene as Level

## Marche automatique (physique réelle) : direction MONDE, course, verrouillage du regard sur la caméra (strafe).
func _go(dir: Vector2, sprint := false, lock := false) -> void:
	var p := _lvl().player
	p.auto_active = dir != Vector2.ZERO
	p.auto_dir = dir
	p.auto_sprint = sprint
	p.strafe_lock = lock

## Direction monde relative à la caméra : x droite, y avant.
func _rel(x: float, forward: float) -> Vector2:
	var yaw := _lvl().camera.yaw
	var v := Basis(Vector3.UP, yaw) * Vector3(x, 0.0, -forward)
	return Vector2(v.x, v.z)

func _perf(label: String, frames: int) -> void:
	var fps_sum := 0.0
	var worst := INF
	for i in frames:
		await get_tree().process_frame
		var f := Engine.get_frames_per_second()
		fps_sum += f
		worst = minf(worst, f)
	print("PERF %s : moyenne %.0f FPS, minimum %.0f FPS (%d images, %s)" % [label, fps_sum / frames, worst, frames, RenderingServer.get_video_adapter_name()])

func _run() -> void:
	await _frames(40)
	var lv := _lvl()
	var p := lv.player
	var cam := lv.camera
	print("MODELE : ", p.model.get_class(), " / ", p.model.name, " ; vue 3e personne : ", not cam.first_person)
	lv.rig.start_preset = "hotel_reve"
	await _frames(120)
	if _mode == "perf":
		await _perf("couloir, au repos", 240)
		_go(_rel(0, 1), true)
		await _perf("couloir, course", 240)
		_go(Vector2.ZERO)
	elif _mode == "film":
		await _frames(60)
		_go(_rel(0, 1))
		await _frames(110)
		_go(_rel(0, 1), true)
		await _frames(75)
		_go(_rel(1, 0), false, true)           # strafe à droite
		await _frames(80)
		_go(_rel(-1, 0), false, true)          # strafe à gauche
		await _frames(80)
		_go(_rel(0, -1), false, true)          # recul
		await _frames(80)
		_go(Vector2.ZERO)
		await _frames(90)
	else:
		await _shot("couloir_repos")
		_go(_rel(0, 1))
		await _frames(100)
		await _shot("couloir_marche")
		_go(_rel(0, 1), true)
		await _frames(50)
		await _shot("couloir_course")
		_go(_rel(1, 0), false, true)
		await _frames(70)
		await _shot("couloir_strafe_droite")
		_go(_rel(0, -1), false, true)
		await _frames(70)
		await _shot("couloir_recul")
		_go(Vector2.ZERO)
		await _frames(50)
	# --- porte du rêve : invite, geste, transition
	p.auto_active = false
	p.strafe_lock = false
	p.teleport(Vector3(23.4, 0.05, 0.0), deg_to_rad(-90.0))
	cam.yaw = deg_to_rad(-90.0)
	cam.pitch = -0.12
	cam.snap()
	await _frames(70)
	lv._update_focus()
	await _shot("porte_invite")
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	lv._unhandled_input(ev)
	await _frames(32)
	await _shot("porte_geste_interact")
	var arrived := await _wait_scene("res://scenes/levels/foret_nocturne.tscn")
	print("TRANSITION vers la forêt : ", arrived)
	await _frames(150)
	lv = _lvl()
	p = lv.player
	cam = lv.camera
	await _shot("foret_arrivee")
	if _mode == "perf":
		await _perf("forêt, au repos", 240)
		_go(_rel(0, 1), true)
		await _perf("forêt, course", 360)
		_go(Vector2.ZERO)
		print("FIN PERF")
		get_tree().quit()
		return
	# parcours sur le sentier : marche puis course, traînée de particules
	_go(_rel(0, 1))
	await _frames(120)
	await _shot("foret_marche")
	_go(_rel(0.3, 1), true)
	await _frames(90)
	await _shot("foret_course_trainee")
	_go(Vector2.ZERO)
	await _frames(240)
	await _shot("foret_repos_particules")
	# le personnage revient vers la caméra : on voit le visage étoilé, puis gros plan sur le visage et le halo
	_go(_rel(0, -1))
	await _frames(40)
	await _shot("foret_vers_la_camera")
	_go(Vector2.ZERO)
	await _frames(70)
	var d0 := cam.dist_out
	cam.dist_out = 1.6
	cam.pitch = -0.05
	await _frames(60)
	await _shot("foret_gros_plan_visage")
	cam.dist_out = d0
	# gestes contextuels
	p.play_gesture(&"surprised")
	await _frames(24)
	await _shot("geste_surprised")
	await _frames(70)
	p.play_gesture(&"comfort")
	await _frames(45)
	await _shot("geste_comfort")
	await _frames(100)
	p.play_gesture(&"sleep")
	await _frames(290)
	await _shot("geste_sleep")
	p.play_gesture(&"wake")
	await _frames(150)
	await _shot("geste_wake_retour")
	print("FIN CAPTURES")
	get_tree().quit()
