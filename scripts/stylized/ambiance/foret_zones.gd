extends Node
## Ambiance par zones de la Forêt de la peur : interpole l'environnement global (brouillard, ambiance, lune, glow)
## selon la position z de la CAMÉRA active (sinon du joueur). Sans toucher au script du joueur ni à celui de la caméra.
##
##   lisière (0 → −22)      bleue, belle, brouillard léger
##   marais (−30 → −62)     brouillard cyan-vert plus dense, lune plus basse
##   bois noir (−65 → −108) très sombre, brouillard violet dense, lune étouffée
##   clairière (−110 → −140) ouverte, brouillard fin, lune forte, teinte lavande légèrement chaude
##
## Entre deux zones, les réglages sont fondus (smoothstep) entre les points de passage KEYS. Le nœud ne fait rien si le
## préréglage actif du LightingRig n'est plus « foret_peur » (touche L). Les valeurs de la lisière = celles du préréglage.
## Réglage : modifier KEYS ci-dessous. `zone_name(z)` et `settings_at(z)` sont publics (captures, tests).

const PRESET := "foret_peur"
# [z, nom, réglages]
const KEYS := [
	[10.0, "lisiere", {"fog_density": 0.013, "fog_color": "#1c2a5a", "ambient_energy": 1.3, "ambient_color": "#5a68a4", "sun_energy": 0.62, "sun_color": "#a9b5f8", "exposure": 1.3, "glow": 0.85}],
	[-20.0, "lisiere", {"fog_density": 0.015, "fog_color": "#1c2a5a", "ambient_energy": 1.3, "ambient_color": "#5a68a4", "sun_energy": 0.62, "sun_color": "#a9b5f8", "exposure": 1.3, "glow": 0.85}],
	[-32.0, "marais", {"fog_density": 0.019, "fog_color": "#123e52", "ambient_energy": 1.15, "ambient_color": "#3f6c98", "sun_energy": 0.48, "sun_color": "#8cbcec", "exposure": 1.28, "glow": 0.95}],
	[-60.0, "marais", {"fog_density": 0.020, "fog_color": "#143848", "ambient_energy": 1.12, "ambient_color": "#3a6290", "sun_energy": 0.45, "sun_color": "#8cbcec", "exposure": 1.28, "glow": 0.95}],
	[-70.0, "bois_noir", {"fog_density": 0.029, "fog_color": "#130f2e", "ambient_energy": 1.0, "ambient_color": "#44468c", "sun_energy": 0.26, "sun_color": "#8280d8", "exposure": 1.18, "glow": 0.8}],
	[-104.0, "bois_noir", {"fog_density": 0.031, "fog_color": "#0f0c26", "ambient_energy": 0.98, "ambient_color": "#42448a", "sun_energy": 0.22, "sun_color": "#8280d8", "exposure": 1.15, "glow": 0.8}],
	[-116.0, "clairiere", {"fog_density": 0.0075, "fog_color": "#2a3470", "ambient_energy": 1.4, "ambient_color": "#5a67ac", "sun_energy": 0.95, "sun_color": "#cfc6f6", "exposure": 1.35, "glow": 1.0}],
	[-145.0, "clairiere", {"fog_density": 0.0075, "fog_color": "#2e3874", "ambient_energy": 1.4, "ambient_color": "#5a67ac", "sun_energy": 0.95, "sun_color": "#d2c8f6", "exposure": 1.35, "glow": 1.0}],
]

var _rig: LightingRig
var _last_z := 1e9
var _synced := false

## Aligne l'eau sur le ciel du préréglage : direction de la lune et couleurs de reflet.
func _sync_materials() -> void:
	_synced = true
	var eau := StyleMaterials.get_mat("foret_eau") as ShaderMaterial
	if eau == null:
		return
	var p: Dictionary = _rig.presets[_rig.current_index]
	eau.set_shader_parameter("moon_dir", _rig.sun.global_transform.basis.z)
	eau.set_shader_parameter("sky_top", Color.html(p["sky_top"]).lightened(0.12))
	eau.set_shader_parameter("sky_horizon", Color.html(p["sky_horizon"]).lightened(0.08))

static func _lerp_val(a, b, k: float):
	if typeof(a) == TYPE_STRING:
		return Color.html(a).lerp(Color.html(b), k)
	return lerpf(float(a), float(b), k)

## Réglages interpolés à la profondeur z (couleurs en Color, nombres en float).
static func settings_at(z: float) -> Dictionary:
	var out := {}
	if z >= KEYS[0][0]:
		z = KEYS[0][0]
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if z <= a[0] and z >= b[0]:
			var k := smoothstep(0.0, 1.0, (a[0] - z) / maxf(a[0] - b[0], 0.001))
			for key in a[2]:
				out[key] = _lerp_val(a[2][key], b[2][key], k)
			return out
	var last: Dictionary = KEYS[KEYS.size() - 1][2]
	for key in last:
		out[key] = _lerp_val(last[key], last[key], 0.0)
	return out

static func zone_name(z: float) -> String:
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if z <= a[0] and z >= b[0]:
			return a[1] if a[1] == b[1] or (a[0] - z) < (z - b[0]) else b[1]
	return KEYS[KEYS.size() - 1][1] if z < KEYS[KEYS.size() - 1][0] else KEYS[0][1]

func _ready() -> void:
	set_process(true)

func _find_rig() -> LightingRig:
	var n: Node = self
	while n != null:
		if n is Level:
			return (n as Level).rig
		n = n.get_parent()
	return get_tree().get_first_node_in_group("lighting_rig") as LightingRig

func _focus() -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		return cam.global_position
	var n: Node = self
	while n != null:
		if n is Level and (n as Level).player != null:
			return (n as Level).player.global_position
		n = n.get_parent()
	return Vector3.ZERO

func _process(_delta: float) -> void:
	if _rig == null:
		_rig = _find_rig()
		if _rig == null:
			return
	if _rig.presets.is_empty() or _rig.presets[_rig.current_index].get("key", "") != PRESET or _rig.world_env == null:
		return
	if not _synced:
		_sync_materials()
	var z := _focus().z
	if absf(z - _last_z) < 0.02:
		return
	_last_z = z
	apply(_rig, settings_at(z))

## Applique les réglages à l'environnement et à la lune du rig.
static func apply(rig: LightingRig, s: Dictionary) -> void:
	var env := rig.world_env.environment
	env.fog_density = s["fog_density"]
	env.fog_light_color = s["fog_color"]
	env.ambient_light_energy = s["ambient_energy"]
	env.ambient_light_color = s["ambient_color"]
	env.tonemap_exposure = s["exposure"]
	env.glow_intensity = s["glow"]
	rig.sun.light_energy = s["sun_energy"]
	rig.sun.light_color = s["sun_color"]
