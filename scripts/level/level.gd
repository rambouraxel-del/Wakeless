class_name Level
extends Node3D
## Racine commune de tous les niveaux (une scène = une carte construite à la main dans l'éditeur Godot).
## Au démarrage : éclairage choisi par `lighting_preset`, joueur et caméra posés sur le point d'arrivée demandé
## (paramètre « spawn » reçu de l'autoload App, sinon `default_spawn`), interface minimale (invite d'interaction, titre du lieu), sauvegarde.
##
## Structure attendue de la scène (voir docs/NIVEAUX.md) :
##   Level (ce script)
##     Spawns/        Marker3D nommés : points d'arrivée (le -Z du marqueur = direction du regard)
##     Architecture/  VoxelStructure (murs, sols) ou HeightmapTerrain (relief)
##     Decor/         assets cuits (assets/props/*), lumières
##     Portes/        SceneDoor et autres Interactable

signal player_ready(player: Explorer)

@export var level_id := ""
@export var level_title := ""
@export var level_subtitle := ""
@export_enum("day", "dusk", "presentation", "foret_nuit", "hotel_reve", "bureau_nuit") var lighting_preset := "hotel_reve"
@export var default_spawn := "depart"
## Intérieur : la caméra à la 3e personne se rapproche (comme dans les maisons d'Éclat).
@export var interior := false
@export var first_person := true
## Rappel des commandes au premier niveau (quelques secondes après le fondu).
@export var show_controls_hint := false
## Hauteur sous laquelle le joueur est ramené à son point d'arrivée.
@export var kill_y := -25.0

var player: Explorer
var camera: ThirdPersonCamera
var rig: LightingRig
var spawn_id := ""
var focused: Interactable

var _prompt: Label
var _toast: Label
var _toast_t := 0.0
var _title_box: Control
var _hud: CanvasLayer

## L'autoload App n'est pas disponible dans les scripts d'édition lancés avec -s (accès dynamique, jamais d'identifiant global).
func app() -> Node:
	return get_node_or_null("/root/App")

func _app_get(prop: String, fallback: Variant) -> Variant:
	var a := app()
	return a.get(prop) if a != null else fallback

func _ready() -> void:
	GameInput.ensure()
	PlayerConfig.ensure()
	var a := app()
	if a != null:
		a.register_level(scene_file_path)
	_setup_lighting()
	_setup_player()
	_setup_hud()
	GameSave.set_level(level_id if level_id != "" else name, {"visited": true, "spawn": spawn_id})
	if DisplayServer.get_name() != "headless":
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if a != null:
			a.capture_on_resume = true
	player_ready.emit(player)
	if bool((_app_get("launch", {}) as Dictionary).get("reveil", false)) or spawn_id.begins_with("reveil"):
		_wake_up.call_deferred()                    # retour d'un rêve : le personnage se réveille sur son lit
	_intro()

func _setup_lighting() -> void:
	rig = get_node_or_null("LightingRig") as LightingRig
	if rig == null:
		rig = LightingRig.new()
		rig.name = "LightingRig"
		rig.shadow_distance = 60.0
		add_child(rig)
	rig.start_preset = lighting_preset

## Point d'arrivée : Marker3D de « Spawns » portant l'identifiant demandé.
func spawn_marker(id: String) -> Marker3D:
	var holder := get_node_or_null("Spawns")
	if holder == null:
		return null
	return holder.get_node_or_null(id) as Marker3D

func _setup_player() -> void:
	spawn_id = String((_app_get("launch", {}) as Dictionary).get("spawn", default_spawn))
	var m := spawn_marker(spawn_id)
	if m == null:
		m = spawn_marker(default_spawn)
		push_warning("Level %s : point d'arrivée « %s » introuvable, repli sur « %s »." % [name, spawn_id, default_spawn])
		spawn_id = default_spawn
	var pos := m.global_position if m else Vector3(0, 1, 0)
	var yaw := m.global_rotation.y if m else 0.0
	player = Explorer.new()
	player.name = "Joueur"
	player.kill_y = kill_y
	add_child(player)
	player.global_position = pos
	player.cam_yaw = yaw
	player.face(yaw)
	player.fell.connect(func() -> void:
		player.teleport(pos, yaw)
		player.play_gesture(&"surprised"))            # tombé dans le vide, ramené au point d'arrivée : sursaut
	camera = ThirdPersonCamera.new()
	camera.name = "Camera"
	camera.target = player
	camera.yaw = yaw
	camera.pitch = 0.0
	camera.interior = interior
	camera.first_person = first_person and not PlayerConfig.third_person_start
	add_child(camera)
	camera.snap()

func _setup_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 12
	add_child(_hud)
	var dot := ColorRect.new()                  # point de visée discret
	dot.color = Color(1, 1, 1, 0.55)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.custom_minimum_size = Vector2(4, 4)
	dot.size = Vector2(4, 4)
	dot.position = Vector2(-2, -2)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(dot)
	_prompt = _label(24, Color(0.95, 0.98, 1.0))
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.anchor_left = 0.0
	_prompt.anchor_right = 1.0
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.offset_top = -150
	_prompt.offset_bottom = -110
	_hud.add_child(_prompt)
	_toast = _label(24, Color(1, 0.95, 0.75))
	_toast.anchor_left = 0.0
	_toast.anchor_right = 1.0
	_toast.offset_top = 96
	_toast.offset_bottom = 136
	_hud.add_child(_toast)

func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

## Fondu depuis le noir et titre du lieu.
func _intro() -> void:
	var text := level_title if level_subtitle == "" else "%s\n%s" % [level_title, level_subtitle]
	var a := app()
	if a == null or bool(_app_get("transitioning", false)) or DisplayServer.get_name() == "headless":
		return
	a.black_cut(text)
	await get_tree().create_timer(0.9).timeout
	await a.fade_in(1.0)
	if show_controls_hint:
		toast("%s : marcher · souris : regarder · Maj : courir · Espace : sauter · E : interagir · Échap : pause" % GameInput.move_keys_label(), 7.0)

func _wake_up() -> void:
	if player != null:
		player.play_gesture(&"wake")

## Message bref au centre haut de l'écran.
func toast(text: String, seconds := 2.2) -> void:
	_toast.text = text
	_toast_t = seconds

func _physics_process(_delta: float) -> void:
	if player != null and camera != null:
		player.cam_yaw = camera.yaw

func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast.text = ""
	_update_focus()

func _update_focus() -> void:
	focused = null
	if player == null or camera == null or not player.control_enabled or bool(_app_get("paused_menu", false)):
		_prompt.text = ""
		return
	var eye := camera.cam.global_position
	var forward := -camera.cam.global_transform.basis.z
	# Portée mesurée depuis les yeux du PERSONNAGE (à la 3e personne la caméra est à plusieurs mètres derrière lui) ;
	# le regard visé reste celui de la caméra.
	var origin := eye if camera.first_person else player.global_position + Vector3(0.0, PlayerConfig.eye(), 0.0)
	var best := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		var it := n as Interactable
		if it == null or not it.can_use(player):
			continue
		var to_it := it.focus_point() - eye
		var d := it.focus_point() - origin
		var dist := d.length()
		if dist > it.reach or dist < 0.01 or to_it.length() < 0.01:
			continue
		if forward.dot(to_it.normalized()) < 0.55:
			continue
		if dist < best:
			best = dist
			focused = it
	_prompt.text = "" if focused == null else "%s · %s" % [GameInput.key_label("interact"), focused.prompt_text()]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and focused != null and not bool(_app_get("paused_menu", false)):
		get_viewport().set_input_as_handled()
		var g := focused.gesture_for(player)
		if g != &"":
			player.play_gesture(g)             # geste contextuel : seulement quand l'action aboutit
		focused.use(self)

## Téléporte le joueur sur un point d'arrivée de ce niveau (outils, tests).
func move_player_to(id: String) -> void:
	var m := spawn_marker(id)
	if m == null:
		return
	player.teleport(m.global_position, m.global_rotation.y)
	camera.yaw = m.global_rotation.y
	camera.snap()
