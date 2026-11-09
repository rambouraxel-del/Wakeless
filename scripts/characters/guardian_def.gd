class_name GuardianDef
extends RefCounted
## Définition d'un gardien (config/guardians/<id>.json) : scène 3D, table d'animations, réglages de locomotion,
## de caméra et d'effets. Les neuf autres gardiens réutilisent la même mécanique : GLB + scène + JSON.

const DIR := "res://config/guardians/"

var id := ""
var display_name := ""
var scene_path := ""
var model_height := 1.0
var anims := {}                 # rôle (idle, forward…) → nom d'animation dans le GLB
var loops: Array = []
var cancellable: Array = []
var cancel_delay := 0.9
var run_ratio := 2.0
var smoothing := 9.0
var turn_rate := 8.0
var lean_accel_deg := 4.0
var cam_distance := 3.3
var cam_distance_interior := 1.5
var cam_target := 0.82
var cam_target_interior := 0.78
var fx := {}

static var _cache := {}

## Charge (et mémorise) la définition d'un gardien ; `null` si elle est absente ou invalide.
static func load_def(gid: String) -> GuardianDef:
	if gid == "":
		return null
	if _cache.has(gid):
		return _cache[gid]
	var path := DIR + gid + ".json"
	if not FileAccess.file_exists(path):
		return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(d) != TYPE_DICTIONARY:
		return null
	var g := GuardianDef.new()
	g.id = str(d.get("id", gid))
	g.display_name = str(d.get("nom", gid))
	g.scene_path = str(d.get("scene", ""))
	g.model_height = float(d.get("hauteur_modele_m", 1.0))
	g.anims = d.get("animations", {})
	g.loops = d.get("boucles", [])
	g.cancellable = d.get("gestes_annulables", [])
	g.cancel_delay = float(d.get("geste_delai_annulation_s", 0.9))
	var loc: Dictionary = d.get("locomotion", {})
	g.run_ratio = float(loc.get("vitesse_course_relative", 2.0))
	g.smoothing = float(loc.get("lissage", 9.0))
	g.turn_rate = float(loc.get("rotation_rad_s", 8.0))
	g.lean_accel_deg = float(loc.get("inclinaison_acceleration_deg", 4.0))
	var cam: Dictionary = d.get("camera", {})
	g.cam_distance = float(cam.get("distance", 3.3))
	g.cam_distance_interior = float(cam.get("distance_interieur", 1.5))
	g.cam_target = float(cam.get("cible_m", 0.82))
	g.cam_target_interior = float(cam.get("cible_interieur_m", 0.78))
	g.fx = d.get("effets", {})
	_cache[gid] = g
	return g

func fx_float(key: String, fallback: float) -> float:
	return float(fx.get(key, fallback))

func fx_bool(key: String, fallback: bool) -> bool:
	return bool(fx.get(key, fallback))
