class_name HotelDoor
extends Interactable
## Porte de l'hôtel (3D stylisée) : battant en arche monté sur un pivot « Battant » (charnière à gauche, côté -X de
## l'ouverture), poignée, numéro. Fermée à clé (`locked`) : un message, aucun geste. Sinon le personnage pousse la porte,
## le battant pivote (vers -Z, loin du joueur) et reste ouvert ; sa collision est retirée.
## Repère du module : origine au pied de l'ouverture, centre ; face avant (couloir) vers +Z.

@export var locked := true
@export var locked_message := "Fermée à clé."
@export var number := ""
@export var open_angle_deg := 95.0
@export var leaf_width := 1.5
@export var leaf_height := 3.0

var is_open := false
var _busy := false

func _ready() -> void:
	super()
	if prompt == "Interagir":
		prompt = "Ouvrir la porte"
	var lb := get_node_or_null("Numero") as Label3D
	if lb:
		lb.text = number

func focus_point() -> Vector3:
	return global_transform * Vector3(0.0, 1.0, 0.1)

func can_use(player: Node3D) -> bool:
	if not enabled or is_open or _busy:
		return false
	var local := global_transform.affine_inverse() * player.global_position
	return local.z > -0.2 and absf(local.x) < leaf_width * 1.5

func prompt_text() -> String:
	return ("Chambre %s · essayer la porte" % number if number != "" else "Essayer la porte") if locked else prompt

func gesture_for(_player: Node3D) -> StringName:
	return &"" if locked else gesture

func use(level: Level) -> void:
	if _busy or is_open:
		return
	if locked:
		level.toast(locked_message)
		return
	_busy = true
	used.emit(level.player)
	await open_door()
	_busy = false

func open_door(duration := 0.9) -> void:
	if is_open:
		return
	is_open = true
	var pivot := get_node_or_null("Battant") as Node3D
	var body := get_node_or_null("Battant/Collision") as CollisionObject3D
	if body:
		body.collision_layer = 0
	if pivot == null:
		return
	if not is_inside_tree() or DisplayServer.get_name() == "headless":
		pivot.rotation.y = deg_to_rad(open_angle_deg)
		return
	var tw := create_tween()
	tw.tween_property(pivot, "rotation:y", deg_to_rad(open_angle_deg), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
