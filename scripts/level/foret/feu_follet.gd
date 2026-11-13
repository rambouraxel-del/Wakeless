class_name FeuFollet
extends Node3D
## Feu follet trompeur : une lueur qui recule dans une impasse quand on s'en approche (jamais atteignable), puis
## revient doucement quand le joueur s'éloigne. `repli` : position locale (au parent) où il s'arrête, au fond de l'impasse.

@export var repli := Vector3.ZERO
@export var declenche := 6.0
@export var vitesse := 2.8
@export var retour := 14.0

var _origine := Vector3.ZERO
var _t := 0.0
var _base := Vector3.ZERO
var _lv: Level

func _ready() -> void:
	_origine = position
	_base = position
	var n := get_parent()
	while n != null and not (n is Level):
		n = n.get_parent()
	_lv = n as Level

func _physics_process(delta: float) -> void:
	_t += delta
	if _lv != null and _lv.player != null:
		var d := _lv.player.global_position.distance_to(global_position + Vector3(0, -1.0, 0))
		if d < declenche:
			_base = _base.move_toward(repli, vitesse * delta)
		elif d > retour:
			_base = _base.move_toward(_origine, vitesse * 0.4 * delta)
	position = _base + Vector3(0.0, sin(_t * 1.7) * 0.18, 0.0)
