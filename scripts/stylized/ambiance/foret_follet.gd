extends Node3D
## Feu follet / lueur : sprite additif (matériau foret_lueur_*) + lumière qui palpite, légère flottaison.
## `intensite` (0..1) estompe l'orbe et sa lumière : le comportement de recul (Sonnet A) peut le piloter ou le déplacer.
## Pas de hasard : la phase vient de la position.

@export var mat_id := "foret_lueur_cyan"
@export var light_color := Color("#58f0ff")
@export var light_energy := 1.1
@export var light_range := 6.0
@export var taille := 0.9
@export var flottaison := 0.12
@export_range(0.0, 1.0) var intensite := 1.0:
	set(v):
		intensite = v
		_apply()

var _sprite: MeshInstance3D
var _light: OmniLight3D
var _phase := 0.0

func _ready() -> void:
	_phase = position.x * 1.3 + position.z * 0.7
	_sprite = MeshInstance3D.new()
	_sprite.name = "Orbe"
	var q := QuadMesh.new()
	q.size = Vector2(taille, taille)
	q.material = StyleMaterials.get_mat(mat_id)
	_sprite.mesh = q
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sprite)
	_light = OmniLight3D.new()
	_light.name = "Lueur"
	_light.light_color = light_color
	_light.omni_range = light_range
	_light.omni_attenuation = 1.6
	_light.shadow_enabled = false
	add_child(_light)
	_apply()

func _apply() -> void:
	if _sprite == null:
		return
	_sprite.visible = intensite > 0.01
	_sprite.scale = Vector3.ONE * clampf(intensite, 0.05, 1.0)
	_light.visible = intensite > 0.01

func _process(_delta: float) -> void:
	if _light == null:
		return
	var t := Time.get_ticks_msec() * 0.001
	_sprite.position.y = sin(t * 0.8 + _phase) * flottaison
	_light.position.y = _sprite.position.y
	_light.light_energy = light_energy * intensite * (1.0 + 0.3 * sin(t * 2.2 + _phase) * sin(t * 0.7 + _phase * 2.0))
