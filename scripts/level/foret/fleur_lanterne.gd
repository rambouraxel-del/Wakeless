class_name FleurLanterne
extends Interactable
## Fleur-lanterne du marais : E « Réveiller la fleur » allume sa corolle (nœud « Corolle », lumière enfant).
## Quand les trois fleurs brillent, PontRacines se soulève (via ForetEtat).

signal allumee

var lit := false
var _corolle: Node3D
var _light: OmniLight3D
var _t := 1.0
var _energy := 2.2
var _mat_base: Material

func _ready() -> void:
	super()
	if prompt == "Interagir":
		prompt = "Réveiller la fleur"
	_corolle = find_child("Corolle", true, false) as Node3D
	var lights := find_children("*", "OmniLight3D", true, false)
	_light = lights[0] as OmniLight3D if not lights.is_empty() else null
	if _light == null:
		_light = OmniLight3D.new()
		_light.name = "Lumiere"
		_light.position = Vector3(0, 1.6, 0)
		_light.light_color = Color(0.55, 0.95, 1.0)
		_light.omni_range = 6.0
		add_child(_light)
	if _light.light_energy > 0.2:
		_energy = _light.light_energy
	if _corolle is MeshInstance3D:
		var m := (_corolle as MeshInstance3D).get_surface_override_material(0)
		if m == null and (_corolle as MeshInstance3D).mesh != null:
			m = (_corolle as MeshInstance3D).mesh.surface_get_material(0)
		_mat_base = m
	var et := ForetEtat.trouver(self)
	if et != null and et.fleurs.has(String(name)):
		_set_lit(true, 1.0)
	else:
		_set_lit(false, 0.0)
	set_physics_process(false)

func focus_point() -> Vector3:
	return global_position + Vector3(0, 1.3, 0)

func can_use(_player: Node3D) -> bool:
	return enabled and not lit

func gesture_for(_player: Node3D) -> StringName:
	return &"" if lit else gesture

func use(level: Level) -> void:
	if lit:
		return
	super.use(level)
	_set_lit(true, 0.0)
	_t = 0.0
	set_physics_process(true)
	level.toast("La fleur s'éveille et se met à briller.")
	var et := ForetEtat.trouver(self)
	if et != null:
		et.marquer(&"fleur", String(name))
	allumee.emit()

func _set_lit(on: bool, k: float) -> void:
	lit = on
	if _light:
		_light.visible = on
		_light.light_energy = _energy * k if on else 0.0
	if _corolle is MeshInstance3D and _mat_base != null:
		var mi := _corolle as MeshInstance3D
		var m := _mat_base.duplicate()
		if m is ShaderMaterial:
			(m as ShaderMaterial).set_shader_parameter("emission_energy", lerpf(0.5, 4.0, k) if on else 0.5)
		elif m is StandardMaterial3D:
			(m as StandardMaterial3D).emission_enabled = on
			(m as StandardMaterial3D).emission = Color(0.55, 0.95, 1.0)
			(m as StandardMaterial3D).emission_energy_multiplier = 2.5 * k
		mi.material_override = m

func _physics_process(delta: float) -> void:
	_t = minf(_t + delta / 1.4, 1.0)
	_set_lit(true, _t)
	if _t >= 1.0:
		set_physics_process(false)
