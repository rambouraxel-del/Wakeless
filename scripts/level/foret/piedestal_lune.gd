class_name PiedestalLune
extends Interactable
## Piédestal de la ruine latérale : E « Prendre la pierre de lune » (le joueur la porte : simple drapeau dans ForetEtat).

signal prise

var _pierre: Node3D

func _ready() -> void:
	super()
	if prompt == "Interagir":
		prompt = "Prendre la pierre de lune"
	_pierre = find_child("Pierre", true, false) as Node3D
	var et := ForetEtat.trouver(self)
	if et != null and et.pierre_prise:
		_retirer()

func focus_point() -> Vector3:
	return global_position + Vector3(0, 1.2, 0)

func can_use(_player: Node3D) -> bool:
	var et := ForetEtat.trouver(self)
	return enabled and not (et != null and et.pierre_prise)

func _retirer() -> void:
	if _pierre:
		_pierre.visible = false
	for l in find_children("*", "Light3D", true, false):
		(l as Light3D).visible = false

func use(level: Level) -> void:
	var et := ForetEtat.trouver(self)
	if et == null or et.pierre_prise:
		return
	super.use(level)
	et.marquer(&"pierre_prise", true)
	_retirer()
	level.toast("Tu emportes la pierre de lune, froide et lumineuse.", 3.2)
	prise.emit()
