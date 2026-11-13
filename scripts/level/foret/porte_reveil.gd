class_name PorteReveil
extends Interactable
## Porte « Se réveiller » de la clairière : encadrement isolé (module `cadre_porte_reve`), lueur douce.
## E → fondu, retour au Bureau des rêves sur le lit (spawn « reveil »). Le joueur doit être du côté avant (+Z local).

@export var target_scene := "res://scenes/levels/bureau_des_reves.tscn"
@export var target_spawn := "reveil"

var _busy := false

func _ready() -> void:
	super()
	if prompt == "Interagir":
		prompt = "Se réveiller"
	reach = maxf(reach, 3.2)

func focus_point() -> Vector3:
	return global_position

func can_use(player: Node3D) -> bool:
	if not enabled or _busy:
		return false
	var local := global_transform.affine_inverse() * player.global_position
	return local.z > -0.6 and absf(local.x) < 3.0

func use(level: Level) -> void:
	if _busy:
		return
	_busy = true
	used.emit(level.player)
	level.player.control_enabled = false
	level.toast("Les contours de la forêt s'effacent…", 2.0)
	var a := level.app()
	if a != null:
		a.open(target_scene, {"spawn": target_spawn})
	else:
		_busy = false
