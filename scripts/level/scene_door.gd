@tool
class_name SceneDoor
extends Interactable
## Porte voxel (battant de 2 cm de pixel, pivotant sur sa charnière), construite par code à partir de réglages simples.
## Trois usages :
##   - fermée à clé (`locked`) : décor, message court ;
##   - ouverture sur place (`target_scene` vide) : le battant s'ouvre et le reste ;
##   - transition (`target_scene` + `target_spawn`) : le battant s'ouvre, fondu au noir, la scène cible se charge
##     (un niveau = une scène distincte, jamais de monde continu).
##
## Repère : l'origine est la CHARNIÈRE au sol ; le battant s'étend vers +X ; la face avant (côté du joueur) est +Z ;
## le battant s'ouvre vers -Z. Orienter la porte = tourner le nœud autour de Y.
## `build_frame` : ajoute un encadrement autonome (porte isolée, ex. dans la forêt).

enum Look { HOTEL, REVE, ANCIENNE }

@export var target_scene := ""
@export var target_spawn := "depart"
@export var locked := false
@export var locked_message := "Fermée à clé."
@export var look: Look = Look.HOTEL
@export var leaf_width := 1.0
@export var leaf_height := 2.1
@export var build_frame := false
@export var open_angle_deg := 100.0
## Lueur derrière le battant (lumière + panneau émissif) : visible quand la porte s'ouvre.
@export var portal_glow := false

var is_open := false
var _pivot: Node3D
var _body: StaticBody3D
var _glow_panel: MeshInstance3D
var _glow_light: OmniLight3D
var _busy := false

const G := 0.02

func _ready() -> void:
	super()
	if prompt == "Interagir":
		prompt = "Ouvrir la porte"
	_build()

func focus_point() -> Vector3:
	return global_transform * Vector3(leaf_width * 0.5, leaf_height * 0.5, 0.0)

## Le joueur doit être du côté avant (+Z local) de la porte.
func can_use(player: Node3D) -> bool:
	if not enabled or is_open or _busy:
		return false
	var local := global_transform.affine_inverse() * player.global_position
	return local.z > -0.2 and absf(local.x - leaf_width * 0.5) < leaf_width * 1.6

func prompt_text() -> String:
	return "Essayer la porte" if locked else prompt

## Porte fermée à clé : rien ne se passe, donc pas de geste. Sinon le personnage actionne la porte.
func gesture_for(_player: Node3D) -> StringName:
	return &"" if locked else gesture

func use(level: Level) -> void:
	if _busy or is_open:
		return
	if locked:
		level.toast(locked_message)
		return
	_busy = true
	used.emit(level.player)
	if target_scene != "":
		level.player.control_enabled = false
	await open_door()
	if target_scene != "":
		var a := level.app()
		if a != null:
			a.open(target_scene, {"spawn": target_spawn})
	_busy = false

## Ouvre le battant (animation) ; la collision du battant est retirée.
func open_door(duration := 0.8) -> void:
	if is_open:
		return
	is_open = true
	if _body:
		_body.collision_layer = 0
	if _glow_panel:
		_glow_panel.visible = true
		_glow_light.visible = true
	if not is_inside_tree() or DisplayServer.get_name() == "headless":
		_pivot.rotation.y = deg_to_rad(open_angle_deg)
		return
	var tw := create_tween()
	tw.tween_property(_pivot, "rotation:y", deg_to_rad(open_angle_deg), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

# ------------------------------------------------------------------ construction

func _mesh_node(b: VoxelModelBuilder, pos: Vector3, node_name: String) -> MeshInstance3D:
	var mesh := VoxelMesher.build(b.volume, G, Vector3i.ZERO, Vector3i(-1, -1, -1), PackedByteArray(), Vector3i.ZERO, 0, VoxelMesher.Style.DETAIL)
	if mesh == null:
		return null
	mesh.surface_set_material(0, VoxelMaterials.props_material())
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = pos
	return mi

func _build() -> void:
	for c in get_children():
		c.queue_free()
	_pivot = Node3D.new()
	_pivot.name = "Battant"
	add_child(_pivot)
	var w := roundi(leaf_width / G)
	var h := roundi(leaf_height / G)
	var t := 4                           # épaisseur du battant : 8 cm (+1 cellule de saillie de chaque côté)
	var b := VoxelModelBuilder.new(Vector3i(w, h, t + 2))
	var base := "wood_red"
	var rail := "wood_dark"
	var panel := "wood_honey"
	match look:
		Look.REVE:
			base = "wood_aged_dark"; rail = "iron_dark"; panel = "dream_panel"
		Look.ANCIENNE:
			base = "wood_aged"; rail = "wood_aged_dark"; panel = "wood_pale_old"
	var z0 := 1                          # première / dernière couche du battant
	var z1 := t
	b.box(0, 0, z0, w - 1, h - 1, z1, base)
	# montants et traverses (sur les deux faces), quatre panneaux
	var m := 5
	for fz in [z0, z1]:
		b.box(0, 0, fz, m - 1, h - 1, fz, rail)
		b.box(w - m, 0, fz, w - 1, h - 1, fz, rail)
		b.box(m, 0, fz, w - m - 1, 7, fz, rail)                       # traverse basse
		b.box(m, h - 8, fz, w - m - 1, h - 1, fz, rail)             # traverse haute
		b.box(m, h / 2 - 3, fz, w - m - 1, h / 2 + 2, fz, rail)    # traverse médiane
		var pw := (w - 2 * m - 6) / 2
		for col in 2:
			var x0 := m + 3 + col * pw
			b.box(x0, 11, fz, x0 + pw - 1, h / 2 - 6, fz, panel)
			b.box(x0, h / 2 + 5, fz, x0 + pw - 1, h - 12, fz, panel)
		if look == Look.REVE:
			b.box(m - 1, 8, fz, m - 1, h - 9, fz, "gold")        # filets dorés
			b.box(w - m, 8, fz, w - m, h - 9, fz, "gold")
	# poignée et plaque en laiton (en saillie), côté opposé aux charnières
	for fz in [0, t + 1]:
		b.box(w - 14, h / 2 - 7, fz, w - 8, h / 2 - 7, fz, "brass")
		b.box(w - 12, h / 2 - 6, fz, w - 9, h / 2 - 2, fz, "brass")
	# petite plaque de numéro au-dessus de la poignée (hôtel)
	if look == Look.HOTEL:
		b.box(w / 2 - 4, h - 20, 0, w / 2 + 3, h - 16, 0, "brass")
		b.box(w / 2 - 3, h - 19, 0, w / 2 + 2, h - 17, 0, "wood_dark")
	# charnières
	for hy in [12, h / 2, h - 14]:
		b.box(0, hy, t + 1, 1, hy + 5, t + 1, "iron_dark")
	var leaf := _mesh_node(b, Vector3(0, 0, -(t + 2) * G * 0.5), "BattantVoxels")
	if leaf:
		_pivot.add_child(leaf)
	# collision du battant fermé
	_body = StaticBody3D.new()
	_body.name = "Collision"
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(leaf_width, leaf_height, t * G)
	cs.shape = bs
	cs.position = Vector3(leaf_width * 0.5, leaf_height * 0.5, 0)
	_body.add_child(cs)
	_pivot.add_child(_body)
	if build_frame:
		_build_frame()
	if portal_glow:
		_build_glow()

func _build_frame() -> void:
	var fw := 0.22                                   # largeur des montants
	var fd := 0.26                                   # profondeur
	var total_w := leaf_width + fw * 2.0
	var total_h := leaf_height + fw + 0.1
	var cw := roundi(total_w / G)
	var ch := roundi(total_h / G)
	var cd := roundi(fd / G)
	var f := VoxelModelBuilder.new(Vector3i(cw, ch, cd))
	var stone := "stone_ashlar" if look != Look.REVE else "stone_carved"
	var trim := "gold" if look == Look.REVE else "stone_shade"
	var pw := roundi(fw / G)
	f.box(0, 0, 0, pw - 1, ch - 1, cd - 1, stone)
	f.box(cw - pw, 0, 0, cw - 1, ch - 1, cd - 1, stone)
	f.box(0, ch - pw - 5, 0, cw - 1, ch - 1, cd - 1, stone)
	f.box(pw, ch - pw - 5, 0, cw - pw - 1, ch - pw - 5, cd - 1, trim)           # filet sous le linteau
	f.box(pw - 1, 0, 0, pw - 1, ch - pw - 6, cd - 1, trim)
	f.box(cw - pw, 0, 0, cw - pw, ch - pw - 6, cd - 1, trim)
	f.box(-0 + 3, ch - pw + 1, 2, cw - 4, ch - 3, 3, trim)                      # corniche
	f.box(0, 0, 0, cw - 1, 3, cd - 1, "stone_ashlar_dark")                       # seuil
	f.box(pw, 0, 0, cw - pw - 1, 1, cd - 1, "stone_ashlar_dark")
	var node := _mesh_node(f, Vector3(-fw, 0, -fd * 0.5), "Encadrement")
	if node:
		add_child(node)
	var body := StaticBody3D.new()
	body.name = "CollisionCadre"
	for box in [[Vector3(fw, total_h, fd), Vector3(-fw * 0.5, total_h * 0.5, 0)],
			[Vector3(fw, total_h, fd), Vector3(leaf_width + fw * 0.5, total_h * 0.5, 0)],
			[Vector3(total_w, fw + 0.1, fd), Vector3(leaf_width * 0.5, total_h - (fw + 0.1) * 0.5, 0)]]:
		var s := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = box[0]
		s.shape = sh
		s.position = box[1]
		body.add_child(s)
	add_child(body)

func _build_glow() -> void:
	# panneau émissif derrière le battant (visible seulement quand il s'ouvre) + lumière
	var quad := QuadMesh.new()
	quad.size = Vector2(leaf_width, leaf_height)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.72, 1.0, 0.95)
	mat.emission_enabled = true
	mat.emission = Color(0.55, 1.0, 0.92)
	mat.emission_energy_multiplier = 2.2
	quad.material = mat
	_glow_panel = MeshInstance3D.new()
	_glow_panel.name = "Lueur"
	_glow_panel.mesh = quad
	_glow_panel.position = Vector3(leaf_width * 0.5, leaf_height * 0.5, -0.12)
	_glow_panel.rotation.y = PI
	_glow_panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glow_panel.visible = false
	add_child(_glow_panel)
	_glow_light = OmniLight3D.new()
	_glow_light.name = "LumiereLueur"
	_glow_light.position = Vector3(leaf_width * 0.5, leaf_height * 0.5, 0.45)
	_glow_light.light_color = Color(0.55, 1.0, 0.92)
	_glow_light.light_energy = 3.0
	_glow_light.omni_range = 7.0
	_glow_light.visible = false
	add_child(_glow_light)
