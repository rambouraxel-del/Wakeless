class_name SilhouetteOmbre
extends Node3D
## Silhouette d'ombre du bois noir : visible de loin, elle se dissout quand le joueur passe à moins de `rayon` mètres
## (ou la regarde de près, jusqu'à `rayon_regard`). Ne bloque rien (aucune collision).

@export var rayon := 9.0
@export var rayon_regard := 14.0
@export var duree := 1.4

var dissoute := false
var _t := 0.0
var _debut := false
var _lv: Level
var _geoms: Array[GeometryInstance3D] = []

func _ready() -> void:
	for g in find_children("*", "GeometryInstance3D", true, false):
		_geoms.append(g as GeometryInstance3D)
	var n := get_parent()
	while n != null and not (n is Level):
		n = n.get_parent()
	_lv = n as Level

func _physics_process(delta: float) -> void:
	if dissoute:
		return
	if not _debut:
		if _lv == null or _lv.player == null:
			return
		var to := _lv.player.global_position - global_position
		to.y = 0.0
		var d := to.length()
		var proche := d < rayon
		if not proche and d < rayon_regard and _lv.camera != null and _lv.camera.cam != null:
			var fwd := -_lv.camera.cam.global_transform.basis.z
			fwd.y = 0.0
			proche = fwd.normalized().dot((-to).normalized()) > 0.8
		if not proche:
			return
		_debut = true
	_t += delta
	var k := clampf(_t / duree, 0.0, 1.0)
	scale = Vector3.ONE * lerpf(1.0, 0.4, k)
	for g in _geoms:
		g.transparency = k
	if k >= 1.0:
		dissoute = true
		visible = false
		set_physics_process(false)
