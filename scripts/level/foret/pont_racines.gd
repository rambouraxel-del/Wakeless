class_name PontRacines
extends Node3D
## Pont naturel du marais (module `pont_racines`) : les pivots « Racine_N » sont couchés (méta « pose_couchee » : rotation en
## degrés, pointant vers le sol) tant que les trois fleurs-lanternes ne brillent pas ; ils se redressent alors l'un après
## l'autre (rotation 0). `PontCollision` (StaticBody3D du module) n'a de collision qu'une fois le pont levé ; « Barriere »
## (enfant direct, facultatif) fait l'inverse : elle interdit l'entrée dans l'eau au droit du pont tant qu'il dort.
## `delai` : secondes d'attente avant de se lever (plusieurs ponts bout à bout).
## Animation pilotée par les images de physique (testable sans rendu).

signal leve

const FLEURS_REQUISES := 3
const DUREE := 1.1
const DECALAGE := 0.35

@export var delai := 0.0

var ouvert := false
var _racines: Array[Node3D] = []
var _couchee: Array[Vector3] = []
var _plancher: StaticBody3D
var _barriere: StaticBody3D
var _t := -1.0

func _ready() -> void:
	for n in find_children("Racine_*", "Node3D", true, false):
		_racines.append(n as Node3D)
	_racines.sort_custom(func(a: Node3D, b: Node3D) -> bool: return String(a.name) < String(b.name))
	for r in _racines:
		_couchee.append(r.get_meta("pose_couchee", Vector3(-90.0, 0.0, 0.0)))
	_plancher = find_child("PontCollision", true, false) as StaticBody3D
	if _plancher == null:
		_plancher = find_child("Plancher", true, false) as StaticBody3D
	_barriere = get_node_or_null("Barriere") as StaticBody3D
	_pose(0.0)
	_collision(false)
	var et := ForetEtat.trouver(self)
	if et != null:
		et.change.connect(_on_change)
		if et.pont_ouvert or et.fleurs.size() >= FLEURS_REQUISES:
			ouvrir(true)
	set_physics_process(false)

func _on_change(_cle: StringName) -> void:
	var et := ForetEtat.trouver(self)
	if et != null and et.fleurs.size() >= FLEURS_REQUISES:
		ouvrir(false)

func ouvrir(instant: bool) -> void:
	if ouvert:
		return
	ouvert = true
	var et := ForetEtat.trouver(self)
	if et != null and not et.pont_ouvert:
		et.marquer(&"pont_ouvert", true)
	if instant:
		_pose(1.0)
		_collision(true)
		leve.emit()
		return
	_t = -delai
	set_physics_process(true)

func _collision(on: bool) -> void:
	if _plancher:
		_plancher.collision_layer = 1 if on else 0
	if _barriere:
		_barriere.collision_layer = 0 if on else 1

func _pose(k: float) -> void:
	var n := _racines.size()
	for i in n:
		var local := clampf((k * (DUREE + DECALAGE * (n - 1)) - DECALAGE * i) / DUREE, 0.0, 1.0)
		var e := local * local * (3.0 - 2.0 * local)
		_racines[i].rotation_degrees = _couchee[i].lerp(Vector3.ZERO, e)

func _physics_process(delta: float) -> void:
	var total := DUREE + DECALAGE * maxf(_racines.size() - 1, 0)
	_t += delta
	if _t < 0.0:
		return
	var k := clampf(_t / total, 0.0, 1.0)
	_pose(k)
	if k > 0.8:
		_collision(true)
	if k >= 1.0:
		set_physics_process(false)
		leve.emit()
