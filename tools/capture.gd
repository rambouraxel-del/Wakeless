extends SceneTree
## Capture d'écran d'une scène (vérification visuelle, rendu logiciel sous Xvfb : voir tools/shot.sh).
## Usage : godot --rendering-driver opengl3 -s tools/capture.gd -- <scène.tscn> <sortie.png> px py pz tx ty tz [fov] [préréglage] [hud]
##   La caméra de capture remplace celle du joueur ; « hud » conserve l'interface (sinon masquée).
##   Sans coordonnées : vue du joueur à son point d'arrivée.
##   « spawn=<id> » : point d'arrivée ; « joueur=x,y,z,lacet° » : place Star-Faced One (vue de jeu à la 3e personne).

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[1]
	var inst := (load(args[0]) as PackedScene).instantiate()
	for a in args:
		if a.begins_with("spawn=") and inst is Level:
			(inst as Level).default_spawn = a.substr(6)
	var place := ""
	for a in args:
		if a.begins_with("joueur="):
			place = a.substr(7)
	args = PackedStringArray(Array(args).filter(func(a): return not (String(a).begins_with("spawn=") or String(a).begins_with("joueur="))))
	root.add_child(inst)
	await process_frame
	var level := inst as Level
	if level and place != "":
		var v := place.split_floats(",")
		level.player.teleport(Vector3(v[0], v[1], v[2]), deg_to_rad(v[3]))
		level.camera.yaw = deg_to_rad(v[3])
		level.camera.pitch = -0.12
		level.camera.snap()
	var show_hud := "hud" in args
	if args.has("hud"):
		args.remove_at(args.find("hud"))
	if level and not show_hud:
		level._hud.visible = false
	if args.size() >= 8:
		var cam := Camera3D.new()
		cam.fov = float(args[8]) if args.size() >= 9 else 70.0
		cam.near = 0.05
		cam.far = 400.0
		root.add_child(cam)
		cam.global_position = Vector3(float(args[2]), float(args[3]), float(args[4]))
		cam.look_at(Vector3(float(args[5]), float(args[6]), float(args[7])))
		cam.current = true
		if level:
			level.player.visible = true
			level.camera.set_process(false)
			if level.camera.cam:
				level.camera.cam.current = false
			cam.current = true
		if args.size() >= 10 and level:
			level.rig.apply_preset_key(args[9])
	for i in 45:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if out.ends_with(".jpg"):
		img.save_jpg(out, 0.88)
	else:
		img.save_png(out)
	var ri := RenderingServer
	print("rendu : %d objets, %d primitives, %d appels de dessin" % [
		ri.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		ri.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		ri.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	print("saved ", out)
	quit()
