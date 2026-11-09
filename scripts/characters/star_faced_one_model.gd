class_name StarFacedOneModel
extends GuardianModel
## Star-Faced One : modèle 3D skinné (GLB), animations sur place pilotées par un AnimationTree, effets lumineux.
##
## Chaîne : Explorer.drive(vitesse monde) → BlendSpace2D de locomotion (x = latéral, y = avant/arrière, en multiples de la
## marche) → machine à états des gestes (interact, surprised, comfort, sleep, wake) qui reviennent à la locomotion.
## Toute la logique est lue dans la définition GuardianDef (config/guardians/star_faced_one.json) : un autre gardien
## n'a besoin que de sa scène, de son GLB et de son JSON.
##
## Repère : le GLB regarde vers +z (glTF) ; le nœud « Visual » est tourné de 180° pour regarder vers -z comme Explorer.
## Pieds en y = 0 ; la lévitation (4,5 cm) est portée par les animations (os « body »), jamais par la physique.

@export var guardian_id := "star_faced_one"

const LOCO := &"locomotion"
const GESTES: Array[StringName] = [&"interact", &"surprised", &"comfort", &"sleep", &"wake"]
const COND_RETURN := &"parameters/conditions/retour"
const FACE_LAYER := 1 << 19          # calque de rendu 20 : étoile + yeux, hors de la lumière du visage

var def: GuardianDef
var _player: AnimationPlayer
var _tree: AnimationTree
var _sm: AnimationNodeStateMachinePlayback
var _skeleton: Skeleton3D
var _tilt: Node3D
var _light: OmniLight3D
var _trail: GPUParticles3D
var _motes: GPUParticles3D
var _face_bone := -1

var _blend := Vector2.ZERO            # position lissée dans le BlendSpace2D
var _speed := 0.0                     # vitesse lissée (multiples de la marche)
var _prev_vel := Vector3.ZERO
var _accel_local := Vector3.ZERO
var _boost := 0.0                     # renfort d'effets pendant les accélérations (0..1)
var _tilt_cur := Vector2.ZERO
var _action: StringName = &""
var _action_t := 0.0
var _sleeping := false
var _return_pulse := 0
var _t := 0.0

var _face_mat: StandardMaterial3D
var _halo_mat: StandardMaterial3D
var _face_base := 1.0
var _halo_base := 1.0
var _light_base := 1.0
var _light_offset := 0.4

func _ready() -> void:
	def = GuardianDef.load_def(guardian_id)
	if def == null:
		push_error("StarFacedOneModel : définition « %s » introuvable." % guardian_id)
		return
	native_height = def.model_height
	turn_rate = def.turn_rate
	_tilt = get_node_or_null("Tilt") as Node3D
	_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	_skeleton = find_child("Skeleton3D", true, false) as Skeleton3D
	if _player == null or _skeleton == null:
		push_error("StarFacedOneModel : AnimationPlayer ou Skeleton3D absent du GLB.")
		return
	_set_loops()
	_build_tree()
	_setup_materials()
	_setup_fx()

# ------------------------------------------------------------------ animations

func _anim(role: String) -> String:
	return str(def.anims.get(role, ""))

## Les 6 déplacements bouclent ; les gestes jouent une fois (sleep reste sur sa dernière pose).
func _set_loops() -> void:
	for role in def.anims:
		var a := _player.get_animation(_anim(role))
		if a != null:
			a.loop_mode = Animation.LOOP_LINEAR if role in def.loops else Animation.LOOP_NONE

func _anim_node(role: String) -> AnimationNodeAnimation:
	var n := AnimationNodeAnimation.new()
	n.animation = _anim(role)
	return n

func _transition(xfade: float, auto := false, condition := &"") -> AnimationNodeStateMachineTransition:
	var t := AnimationNodeStateMachineTransition.new()
	t.xfade_time = xfade
	if auto:
		t.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
		t.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
		if condition != &"":
			t.advance_condition = condition
	return t

func _build_tree() -> void:
	var bs := AnimationNodeBlendSpace2D.new()
	bs.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_INTERPOLATED
	bs.min_space = Vector2(-1.0, -1.0)
	bs.max_space = Vector2(1.0, def.run_ratio)
	bs.sync = false
	var points := {
		"idle": Vector2(0, 0), "forward": Vector2(0, 1), "fast": Vector2(0, def.run_ratio),
		"backward": Vector2(0, -1), "strafe_left": Vector2(-1, 0), "strafe_right": Vector2(1, 0)}
	for role in points:
		# Appel dynamique : le 4e paramètre (nom du point) n'existe pas en Godot 4.3, mais évite un avertissement en 4.4+.
		if Engine.get_version_info()["hex"] >= 0x040400:
			bs.callv("add_blend_point", [_anim_node(role), points[role], -1, StringName(role)])
		else:
			bs.add_blend_point(_anim_node(role), points[role])
	var sm := AnimationNodeStateMachine.new()
	sm.add_node(LOCO, bs, Vector2(300, 100))
	for i in GESTES.size():
		sm.add_node(GESTES[i], _anim_node(String(GESTES[i])), Vector2(600, 40 + i * 90))
	sm.add_transition(&"Start", LOCO, _transition(0.0, true))
	for g in GESTES:
		# locomotion → geste : travel() ; geste → locomotion : quand le script lève la condition « retour »
		sm.add_transition(LOCO, g, _transition(0.22))
		if g == &"sleep":
			sm.add_transition(g, &"wake", _transition(0.3))
		else:
			sm.add_transition(g, LOCO, _transition(0.35, true, &"retour"))
	_tree = AnimationTree.new()
	_tree.name = "AnimationTree"
	_tree.tree_root = sm
	add_child(_tree)
	_tree.anim_player = _tree.get_path_to(_player)
	_tree.active = true
	_sm = _tree.get("parameters/playback")
	_sm.start(LOCO)

func supports(action: StringName) -> bool:
	return action in GESTES and _tree != null

func is_busy() -> bool:
	return _action != &""

func is_sleeping() -> bool:
	return _sleeping

## Le joueur ne bouge pas pendant sleep / wake, ni pendant le début d'un geste (avant son délai d'annulation).
func accepts_movement() -> bool:
	if _action == &"":
		return true
	if _action in def.cancellable:
		return _action_t >= def.cancel_delay
	return false

func play_action(action: StringName) -> bool:
	if not supports(action):
		return false
	if action == &"wake":
		if not _sleeping or _action == &"wake":
			return false
	elif _action != &"":
		return false
	_action = action
	_action_t = 0.0
	if action == &"wake":
		_sleeping = false
	_sm.travel(action)
	action_started.emit(action)
	return true

func current_state() -> StringName:
	return _sm.get_current_node() if _sm != null else &""

func _anim_length(action: StringName) -> float:
	var a := _player.get_animation(_anim(String(action)))
	return a.length if a != null else 1.0

func _update_action(delta: float, moving: bool) -> void:
	if _return_pulse > 0:
		_return_pulse -= 1
		if _return_pulse == 0:
			_tree.set(COND_RETURN, false)
	if _action == &"":
		return
	_action_t += delta
	var length := _anim_length(_action)
	if _action == &"sleep":
		if _action_t >= length and not _sleeping:
			_sleeping = true
			action_finished.emit(&"sleep")
		return
	var done := _action_t >= length - 0.05
	var cancelled := _action in def.cancellable and moving and _action_t >= def.cancel_delay
	if done or cancelled:
		var finished := _action
		_action = &""
		_tree.set(COND_RETURN, true)
		_return_pulse = 2
		action_finished.emit(finished)

# ------------------------------------------------------------------ pilotage par la physique

func drive(world_velocity: Vector3, walk_speed: float, grounded: bool, delta: float) -> void:
	if _tree == null:
		return
	var local := global_transform.basis.orthonormalized().inverse() * Vector3(world_velocity.x, 0.0, world_velocity.z)
	var target := Vector2(local.x, -local.z) / maxf(walk_speed, 0.01)     # x : droite+, y : avant+
	if target.length() < 0.04:
		target = Vector2.ZERO
	if target.length() > def.run_ratio:
		target = target.normalized() * def.run_ratio
	if not grounded:
		target = target.limit_length(1.0)               # en l'air : pas de course
	var k := 1.0 - exp(-def.smoothing * delta)
	_blend = _blend.lerp(target, k)
	_speed = lerpf(_speed, target.length(), k)
	_tree.set("parameters/locomotion/blend_position", _blend)
	# accélération (repère du modèle) → inclinaison subtile et renfort d'effets
	var acc := (world_velocity - _prev_vel) / maxf(delta, 0.0001)
	_prev_vel = world_velocity
	var al := global_transform.basis.orthonormalized().inverse() * Vector3(acc.x, 0.0, acc.z)
	_accel_local = _accel_local.lerp(al, 1.0 - exp(-14.0 * delta))
	_boost = maxf(_boost - delta * 1.6, clampf(Vector2(acc.x, acc.z).length() / 24.0, 0.0, 1.0))
	_update_action(delta, target.length() > 0.3)

# ------------------------------------------------------------------ rendu : inclinaison, lueurs, particules

func _process(delta: float) -> void:
	if _tree == null or not visible:
		return
	_t += delta
	if _tilt != null:
		var lim := deg_to_rad(def.lean_accel_deg)
		var want := Vector2(clampf(_accel_local.z / 30.0, -1.0, 1.0), clampf(-_accel_local.x / 30.0, -1.0, 1.0)) * lim
		_tilt_cur = _tilt_cur.lerp(want, 1.0 - exp(-9.0 * delta))
		_tilt.rotation = Vector3(_tilt_cur.x, 0.0, _tilt_cur.y)
	var boost := _boost * def.fx_float("renfort_acceleration", 0.6) + clampf(_speed - 1.0, 0.0, 1.0) * 0.25
	if _face_mat != null:
		var pulse := def.fx_float("visage_pulsation", 0.07)
		_face_mat.emission_energy_multiplier = _face_base * (1.0 + pulse * sin(_t * 2.1) + 0.35 * boost)
	if _halo_mat != null:
		var hp := def.fx_float("halo_pulsation", 0.12)
		_halo_mat.emission_energy_multiplier = _halo_base * (1.0 + hp * sin(_t * 1.7 + 1.3) + 0.3 * boost)
	if _light != null and _skeleton != null and _face_bone >= 0:
		var sc := global_transform.basis.get_scale()
		var face_pos := _skeleton.global_transform * _skeleton.get_bone_global_pose(_face_bone).origin
		var fwd := -global_transform.basis.orthonormalized().z
		_light.global_position = face_pos + fwd * _light_offset * sc.x + Vector3(0.0, 0.02 * sc.y, 0.0)
		_light.light_energy = _light_base * (1.0 + 0.5 * boost) * (0.55 if _sleeping else 1.0)
	if _trail != null:
		_trail.emitting = _speed > 0.25 and not _sleeping
		_trail.amount_ratio = clampf(0.2 + 0.3 * _speed + 0.4 * boost, 0.1, 1.0)
	if _motes != null:
		_motes.amount_ratio = lerpf(1.0, 0.4, clampf(_speed, 0.0, 1.0)) * (0.5 if _sleeping else 1.0)

func _setup_materials() -> void:
	var face := find_child("SFO2_FaceStar", true, false) as MeshInstance3D
	if face != null and face.get_active_material(0) is StandardMaterial3D:
		_face_mat = (face.get_active_material(0) as StandardMaterial3D).duplicate()
		_face_base = _face_mat.emission_energy_multiplier * def.fx_float("visage_emission", 1.0)
		face.set_surface_override_material(0, _face_mat)
	var small: Array[Node] = []
	for pattern in ["SFO2_HaloStar_*", "SFO2_Clasp", "SFO2_Const*_Star*"]:
		small.append_array(find_children(pattern, "MeshInstance3D", true, false))
	for n in small:
		var mi := n as MeshInstance3D
		if _halo_mat == null and mi.get_active_material(0) is StandardMaterial3D:
			_halo_mat = (mi.get_active_material(0) as StandardMaterial3D).duplicate()
			_halo_base = _halo_mat.emission_energy_multiplier * def.fx_float("halo_emission", 1.0)
		if _halo_mat != null:
			mi.set_surface_override_material(0, _halo_mat)

func _setup_fx() -> void:
	_face_bone = _skeleton.find_bone("face")
	_light = get_node_or_null("FaceGlow") as OmniLight3D
	if _light != null:
		_light.light_energy = def.fx_float("lumiere_visage_energie", 0.9)
		_light.omni_range = def.fx_float("lumiere_visage_portee_m", 3.2)
		_light.shadow_enabled = def.fx_bool("lumiere_visage_ombres", false)
		_light_base = _light.light_energy
		_light_offset = def.fx_float("lumiere_visage_decalage_m", 0.4)
		# L'étoile et les yeux ne reçoivent pas la lumière du visage (elle les brûlerait : yeux effacés) : ils sont seuls
		# sur le calque de rendu 20, que cette lumière ignore. La lune et les autres lumières les éclairent normalement.
		_light.light_cull_mask = 0xFFFFF & ~FACE_LAYER
		for n in ["SFO2_FaceStar", "SFO2_Eye_L", "SFO2_Eye_R"]:
			var mi := find_child(n, true, false) as MeshInstance3D
			if mi != null:
				mi.layers = FACE_LAYER
	_trail = get_node_or_null("Fx/Trail") as GPUParticles3D
	_motes = get_node_or_null("Fx/Motes") as GPUParticles3D
	for ps in [_trail, _motes]:
		if ps != null and ps.draw_pass_1 == null:
			ps.draw_pass_1 = GuardianFx.star_mesh()
	if _trail != null:
		_trail.emitting = false
		_trail.visible = def.fx_bool("particules_trainee", true)
	if _motes != null:
		_motes.visible = def.fx_bool("particules_repos", true)
