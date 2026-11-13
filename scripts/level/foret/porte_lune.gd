class_name PorteLune
extends Interactable
## Porte de ruine : les vantaux « VantailG » / « VantailD » pivotent quand on pose la pierre de lune.
## Convention : charnière de VantailG à gauche, de VantailD à droite (vu du sud) ; ils s'ouvrent vers le nord (−Z).
## Sans la pierre : « Une empreinte en forme de lune… ». Le blocage (StaticBody3D « Blocage ») disparaît à l'ouverture.

signal ouverte

const DUREE := 2.0
const ANGLE := 100.0

var ouvert := false
var _g: Node3D
var _d: Node3D
var _blocage: StaticBody3D
var _t := -1.0

func _ready() -> void:
	super()
	if prompt == "Interagir":
		prompt = "Poser la pierre de lune"
	reach = maxf(reach, 3.4)
	var root := get_parent()
	_g = root.find_child("VantailG", true, false) as Node3D if root else null
	_d = root.find_child("VantailD", true, false) as Node3D if root else null
	_blocage = get_node_or_null("Blocage") as StaticBody3D
	var et := ForetEtat.trouver(self)
	if et != null and et.porte_ouverte:
		_ouvrir(true)
	set_physics_process(false)

func _a_la_pierre() -> bool:
	var et := ForetEtat.trouver(self)
	return et != null and et.pierre_prise

func can_use(_player: Node3D) -> bool:
	return enabled and not ouvert

func prompt_text() -> String:
	return prompt if _a_la_pierre() else "Examiner l'empreinte"

func gesture_for(_player: Node3D) -> StringName:
	return gesture if _a_la_pierre() else &""

func use(level: Level) -> void:
	if ouvert:
		return
	if not _a_la_pierre():
		level.toast("Une empreinte en forme de lune…", 3.0)
		return
	super.use(level)
	level.toast("La pierre s'encastre. L'arche s'éveille.", 3.0)
	_ouvrir(false)

func _ouvrir(instant: bool) -> void:
	if ouvert:
		return
	ouvert = true
	var et := ForetEtat.trouver(self)
	if et != null and not et.porte_ouverte:
		et.marquer(&"porte_ouverte", true)
	if instant:
		_pose(1.0)
		if _blocage:
			_blocage.collision_layer = 0
		ouvert = true
		ouverte.emit()
		return
	_t = 0.0
	set_physics_process(true)

func _pose(k: float) -> void:
	var e := k * k * (3.0 - 2.0 * k)
	if _g:
		_g.rotation.y = deg_to_rad(ANGLE) * e
	if _d:
		_d.rotation.y = deg_to_rad(-ANGLE) * e

func _physics_process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / DUREE, 0.0, 1.0)
	_pose(k)
	if k > 0.5 and _blocage and _blocage.collision_layer != 0:
		_blocage.collision_layer = 0
	if k >= 1.0:
		set_physics_process(false)
		ouverte.emit()
