class_name JeuneFille
extends Interactable
## La jeune fille de la forêt. Assise sur sa souche : E « La rassurer » (geste « comfort ») → elle se lève et GUIDE.
## Elle suit une liste d'étapes (Marker3D posés à la main sous `etapes`) : quand le joueur arrive à moins de `declenche`
## mètres de son étape courante, elle va à la suivante (déplacement interpolé, pas de navigation). Méta d'une étape :
##   « requiert » = « pont » | « porte » (elle attend que l'énigme soit résolue), « proche » = true (bois noir : elle reste
##   2–3 m devant le joueur), « fin » = true (dernière étape : elle s'assoit ; E « S'asseoir près d'elle »).
## Signaux : `rassuree`, `apaisement` (l'ambiance peut s'y brancher).

signal rassuree
signal apaisement

enum Etat { ASSISE, GUIDE, ARRIVEE, APAISEE }

@export var etapes: NodePath = ^"../../Etapes"
@export var declenche := 6.0
@export var vitesse := 2.0
@export var distance_proche := 2.6

var etat := Etat.ASSISE
var idx := 0
var _etapes: Array[Node3D] = []
var _modele: Node3D
var _debout := 0.0                     # 0 = recroquevillée sur la souche, 1 = debout
var _debout_cible := 0.0
var _lv: Level
var _y_sol := 0.0

func _ready() -> void:
	super()
	prompt = "La rassurer"
	gesture = &"comfort"
	reach = 3.2
	_modele = get_node_or_null("Modele") as Node3D
	var holder := get_node_or_null(etapes)
	if holder:
		for c in holder.get_children():
			if c is Node3D:
				_etapes.append(c as Node3D)
	var n := get_parent()
	while n != null and not (n is Level):
		n = n.get_parent()
	_lv = n as Level
	_y_sol = global_position.y
	_applique_pose()

func focus_point() -> Vector3:
	return global_position + Vector3(0, 0.7 if etat == Etat.ASSISE or etat == Etat.ARRIVEE else 0.9, 0)

func can_use(_player: Node3D) -> bool:
	return enabled and (etat == Etat.ASSISE or etat == Etat.ARRIVEE)

func prompt_text() -> String:
	return "La rassurer" if etat == Etat.ASSISE else "S'asseoir près d'elle"

func gesture_for(_player: Node3D) -> StringName:
	return &"comfort" if etat == Etat.ASSISE else &""

func use(level: Level) -> void:
	if etat == Etat.ASSISE:
		super.use(level)
		etat = Etat.GUIDE
		idx = 0
		_debout_cible = 1.0
		level.toast("Elle lève les yeux, hésite, puis se met debout. « Reste près de moi… »", 4.0)
		rassuree.emit()
	elif etat == Etat.ARRIVEE:
		super.use(level)
		etat = Etat.APAISEE
		var et := ForetEtat.trouver(self)
		if et != null:
			et.marquer(&"apaisee", true)
		level.toast("Vous restez là, côte à côte. La peur s'éloigne, tout doucement.", 5.0)
		apaisement.emit()

func _req_ok(e: Node3D) -> bool:
	var r := String(e.get_meta("requiert", ""))
	if r == "":
		return true
	var et := ForetEtat.trouver(self)
	if et == null:
		return false
	return (r == "pont" and et.pont_ouvert) or (r == "porte" and et.porte_ouverte)

func _dxz(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _applique_pose() -> void:
	if _modele:
		var k := _debout
		_modele.scale = Vector3(1.0, lerpf(0.62, 1.0, k), 1.0)
		_modele.position.y = lerpf(0.0, 0.0, k)

func _physics_process(delta: float) -> void:
	_debout = move_toward(_debout, _debout_cible, delta / 0.9)
	_applique_pose()
	if etat != Etat.GUIDE or _lv == null or _lv.player == null or _etapes.is_empty():
		return
	var pp := _lv.player.global_position
	var cur := _etapes[idx]
	if bool(cur.get_meta("proche", false)):
		while idx + 1 < _etapes.size() and _dxz(pp, _etapes[idx].global_position) < distance_proche and _req_ok(_etapes[idx + 1]):
			idx += 1
		cur = _etapes[idx]
	elif idx + 1 < _etapes.size() and _dxz(pp, cur.global_position) < float(cur.get_meta("declenche", declenche)) and _req_ok(_etapes[idx + 1]):
		idx += 1
		cur = _etapes[idx]
	# déplacement vers l'étape courante (plus vite si elle est loin derrière : elle rattrape le joueur pressé)
	var cible := cur.global_position
	var vers := Vector3(cible.x - global_position.x, 0.0, cible.z - global_position.z)
	var dist := vers.length()
	var v := vitesse * (2.2 if bool(cur.get_meta("proche", false)) and _dxz(pp, global_position) > 4.5 else 1.0)
	if dist > 0.05:
		var pas := minf(v * delta, dist)
		var dir := vers / dist
		global_position += dir * pas
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(8.0 * delta, 0.0, 1.0))
	_suit_sol(cible)
	if bool(cur.get_meta("fin", false)) and dist < 0.15 and idx == _etapes.size() - 1:
		etat = Etat.ARRIVEE
		_debout_cible = 0.0
		var face := Vector3(pp.x - global_position.x, 0.0, pp.z - global_position.z)
		if face.length() > 0.1:
			rotation.y = atan2(-face.x, -face.z)

## Garde les pieds sur le sol : rayon vers le bas (couche 1), lissé ; à défaut, la hauteur de l'étape.
func _suit_sol(cible: Vector3) -> void:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 3.0, 0), global_position + Vector3(0, -4.0, 0), 1)
	var hit := space.intersect_ray(q)
	var y := float(hit["position"].y) if not hit.is_empty() else cible.y
	global_position.y = lerpf(global_position.y, y, 0.25)
