extends Node
## Autoload « App » : navigation entre niveaux (scènes distinctes, jamais de monde continu), fondu au noir,
## pause (Échap), informations techniques (F3), plein écran (F11).
##
##   App.open(chemin_de_scène, {"spawn": "id_du_point_d_arrivée"})   fondu → chargement → fondu
##   App.launch                                                         paramètres reçus par la scène qui s'ouvre
##
## Raccourcis de développement : F1 Bureau des rêves · F2 Forêt de la peur · F4 ancien couloir voxel · F5 ancienne forêt nocturne · L ambiance suivante · F3 infos · F11 plein écran.
## Recette automatique : godot … -- --recette=<chemin du script> (un script Node est ajouté au-dessus du jeu, voir tests/recette_transition.gd).

const SCENE_BUREAU := "res://scenes/levels/bureau_des_reves.tscn"            # Bureau des rêves (3D stylisée)
const SCENE_COULOIR := "res://scenes/levels/bureau_couloir.tscn"           # ancien couloir voxel (prototype, conservé)
const SCENE_FORET := "res://scenes/levels/foret_de_la_peur.tscn"                 # La Forêt de la peur (le rêve du lit)
const SCENE_FORET_ANCIENNE := "res://scenes/levels/foret_nocturne.tscn"   # ancienne forêt nocturne (prototype, conservée)
const DEV_SCENES := {KEY_F1: SCENE_BUREAU, KEY_F2: SCENE_FORET, KEY_F4: SCENE_COULOIR, KEY_F5: SCENE_FORET_ANCIENNE}
const FADE_TIME := 0.45

signal scene_opened(path: String)

## Paramètres transmis à la scène qui s'ouvre (ex. {"spawn": "reveil"}).
var launch := {}
var current_path := ""
var paused_menu := false
var transitioning := false
## La scène courante est un niveau jouable : la souris est (re)capturée à la reprise.
var capture_on_resume := false

var _hud: Label
var _hud_layer: CanvasLayer
var _fade_layer: CanvasLayer
var _fade: ColorRect
var _fade_label: Label
var _pause_layer: CanvasLayer
var _pause_panel: Control
var _controls_help := PackedStringArray()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--recette="):
			GameSave.PATH = "user://wakeless_recette_sauvegarde.json"        # la recette n'écrase jamais la vraie progression
			var sc := load(a.substr(10)) as Script
			if sc != null:
				var n := Node.new()
				n.set_script(sc)
				n.name = "Recette"
				n.process_mode = Node.PROCESS_MODE_ALWAYS
				add_child.call_deferred(n)
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 10
	_hud_layer.visible = false
	add_child(_hud_layer)
	_hud = Label.new()
	_hud.position = Vector2(14, 10)
	_hud.add_theme_font_size_override("font_size", 15)
	_hud.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	_hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_hud.add_theme_constant_override("shadow_offset_x", 1)
	_hud.add_theme_constant_override("shadow_offset_y", 1)
	_hud_layer.add_child(_hud)
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 40
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.01, 0.015, 0.025, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade)
	_fade_label = Label.new()
	_fade_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fade_label.add_theme_font_size_override("font_size", 26)
	_fade_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.8))
	_fade.add_child(_fade_label)

# ------------------------------------------------------------------ navigation

## Ouvre une scène (niveau) : fondu au noir, chargement, fondu retour. Ignoré pendant une transition.
func open(path: String, params := {}) -> void:
	if transitioning:
		return
	if not ResourceLoader.exists(path):
		push_error("App.open : scène introuvable (%s)" % path)
		return
	transitioning = true
	_hide_pause()
	await _fade_to(1.0, FADE_TIME)
	launch = params
	_controls_help = PackedStringArray()
	capture_on_resume = false
	current_path = path
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0, FADE_TIME)
	transitioning = false
	scene_opened.emit(path)

## Appelé par le niveau qui démarre : il est la scène courante (lancement direct depuis l'éditeur compris).
func register_level(path: String) -> void:
	current_path = path

func _fade_to(alpha: float, duration: float) -> void:
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_fade, "color:a", alpha, duration)
	await t.finished

## Pose un fondu au noir immédiat (utilisé quand un niveau démarre : il s'éclaircit ensuite lui-même).
func black_cut(label := "") -> void:
	_fade.color.a = 1.0
	_fade_label.text = label

func fade_in(duration := FADE_TIME) -> void:
	await _fade_to(0.0, duration)
	_fade_label.text = ""

func set_controls_help(lines: PackedStringArray) -> void:
	_controls_help = lines

# ------------------------------------------------------------------ pause

func can_pause() -> bool:
	return current_path != "" and not transitioning

func toggle_pause() -> void:
	if paused_menu:
		resume()
	elif can_pause():
		pause()

func pause() -> void:
	if paused_menu or not can_pause():
		return
	paused_menu = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if DisplayServer.get_name() == "headless":
		return
	_build_pause()
	_pause_layer.visible = true
	(_pause_panel.find_child("Reprendre", true, false) as Control).grab_focus()

func resume() -> void:
	if not paused_menu:
		return
	paused_menu = false
	_hide_pause()
	get_tree().paused = false
	if capture_on_resume and DisplayServer.get_name() != "headless":
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func quit_game() -> void:
	get_tree().quit()

func _hide_pause() -> void:
	paused_menu = false
	if _pause_layer:
		_pause_layer.visible = false

func _build_pause() -> void:
	if _pause_layer != null:
		return
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 25
	add_child(_pause_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.62)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(shade)
	_pause_panel = MenuStyle.panel(Vector2(440, 400))
	_pause_layer.add_child(_pause_panel)
	var box := _pause_panel.get_child(0) as VBoxContainer
	box.add_child(MenuStyle.title("Pause", 40))
	box.add_child(MenuStyle.spacer(10))
	var b1 := MenuStyle.button("Reprendre")
	b1.name = "Reprendre"
	b1.pressed.connect(resume)
	box.add_child(b1)
	var b2 := MenuStyle.button("Retour au Bureau des rêves")
	b2.pressed.connect(func() -> void: open(SCENE_BUREAU))
	box.add_child(b2)
	var b3 := MenuStyle.button("Quitter")
	b3.pressed.connect(quit_game)
	box.add_child(b3)
	box.add_child(MenuStyle.spacer(6))
	box.add_child(MenuStyle.note("Échap : reprendre · F3 : informations techniques"))

# ------------------------------------------------------------------ entrées globales

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE:
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if paused_menu:
		return
	if DEV_SCENES.has(key.keycode):
		open(DEV_SCENES[key.keycode])
	elif key.keycode == KEY_L:
		var rig := get_tree().get_first_node_in_group("lighting_rig") as LightingRig
		if rig:
			rig.next_preset()
	elif key.keycode == KEY_F3:
		_hud_layer.visible = not _hud_layer.visible
	elif key.keycode == KEY_F11:
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _process(_delta: float) -> void:
	if _hud == null or not _hud_layer.visible:
		return
	var cam := get_viewport().get_camera_3d()
	var rig := get_tree().get_first_node_in_group("lighting_rig") as LightingRig
	var lines := PackedStringArray()
	lines.append("WAKELESS — informations techniques   %d FPS" % Engine.get_frames_per_second())
	if cam:
		var p := cam.global_position
		lines.append("Position %.1f, %.1f, %.1f m" % [p.x, p.y, p.z])
	var rs := RenderingServer
	lines.append("Rendu : %d objets · %dk triangles · %d appels de dessin" % [
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	if rig:
		lines.append("Éclairage : %s" % rig.current_name())
	lines.append("")
	if _controls_help.is_empty():
		lines.append("ZQSD/WASD bouger · souris regarder · Maj courir · Espace sauter · E interagir")
	else:
		lines.append_array(_controls_help)
	lines.append("V vue 1re/3e personne · F champ de vision · L ambiance · F1 Bureau des rêves · F2 Forêt de la peur · F4 ancien couloir · F5 ancienne forêt · F3 infos · F11 plein écran · Échap pause")
	_hud.text = "\n".join(lines)
