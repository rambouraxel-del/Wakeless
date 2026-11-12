@tool
class_name ModuleBuilder
extends RefCounted
## Assemble un MODULE réutilisable (colonne, porte, applique, escalier, lit…) : pièces de maillage fusionnées par matériau
## (un seul MeshInstance3D, quelques surfaces), boîtes de collision, lumières, nœuds supplémentaires (textes, pivots animés).
## `save()` écrit assets/stylized/meshes/<id>.res et assets/stylized/modules/<id>.tscn (scène instanciable dans un niveau).

const MESH_DIR := "res://assets/stylized/meshes/"
const MODULE_DIR := "res://assets/stylized/modules/"

var id := ""
var parts: Array = []           # [mesh, Transform3D]
var colliders: Array = []       # [Vector3 taille, Transform3D]
var lights: Array = []          # [Light3D]
var extras: Array = []          # [Node3D] (enfants supplémentaires, avec leurs propres enfants)
var script_path := ""
var script_props := {}
var cast_shadows := true

func _init(p_id: String) -> void:
	id = p_id

static func M(name: String) -> Material:
	return StyleMaterials.get_mat(name)

static func at(p: Vector3, rot_deg := Vector3.ZERO, scale := Vector3.ONE) -> Transform3D:
	var b := Basis.from_euler(rot_deg * (PI / 180.0)).scaled(scale)
	return Transform3D(b, p)

func add(mesh: Mesh, xf := Transform3D.IDENTITY) -> void:
	parts.append([mesh, xf])

func box(size: Vector3, r: float, mat: String, pos: Vector3, rot_deg := Vector3.ZERO, k := 2) -> void:
	add(StyleKit.rounded_box(size, r, M(mat), k), at(pos, rot_deg))

func collide(size: Vector3, pos: Vector3, rot_deg := Vector3.ZERO) -> void:
	colliders.append([size, at(pos, rot_deg)])

func omni(pos: Vector3, color: Color, energy: float, range_m: float, shadow := false, nm := "") -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = nm if nm != "" else "Lumiere%d" % (lights.size() + 1)
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_m
	l.omni_attenuation = 1.4
	l.shadow_enabled = shadow
	l.distance_fade_enabled = true
	l.distance_fade_begin = 32.0
	l.distance_fade_shadow = 18.0
	l.distance_fade_length = 10.0
	lights.append(l)
	return l

func spot(pos: Vector3, rot_deg: Vector3, color: Color, energy: float, range_m: float, angle: float, nm := "") -> SpotLight3D:
	var l := SpotLight3D.new()
	l.name = nm if nm != "" else "Spot%d" % (lights.size() + 1)
	l.position = pos
	l.rotation_degrees = rot_deg
	l.light_color = color
	l.light_energy = energy
	l.spot_range = range_m
	l.spot_angle = angle
	l.spot_angle_attenuation = 0.6
	l.shadow_enabled = false
	lights.append(l)
	return l

func label(text: String, pos: Vector3, size := 64, color := Color("#2a1c4e"), rot_deg := Vector3.ZERO, pixel := 0.004) -> Label3D:
	var lb := Label3D.new()
	lb.name = "Texte_%d" % extras.size()
	lb.text = text
	lb.position = pos
	lb.rotation_degrees = rot_deg
	lb.font_size = size
	lb.pixel_size = pixel
	lb.modulate = color
	lb.outline_size = 0
	lb.double_sided = false
	lb.shaded = false
	extras.append(lb)
	return lb

## Construit la scène (sans l'enregistrer).
func build_node() -> Node3D:
	var root := Node3D.new()
	root.name = id.to_pascal_case()
	var mesh := StyleKit.merge(parts)
	if mesh.get_surface_count() > 0:
		var mi := MeshInstance3D.new()
		mi.name = "Maillage"
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	if not colliders.is_empty():
		var body := StaticBody3D.new()
		body.name = "Collision"
		root.add_child(body)
		for i in colliders.size():
			var cs := CollisionShape3D.new()
			cs.name = "Boite%d" % (i + 1)
			var bs := BoxShape3D.new()
			bs.size = colliders[i][0]
			cs.shape = bs
			cs.transform = colliders[i][1]
			body.add_child(cs)
	for l in lights:
		root.add_child(l)
	for e in extras:
		root.add_child(e)
	if script_path != "":
		root.set_script(load(script_path))
		for k in script_props:
			root.set(k, script_props[k])
	return root

## Enregistre le maillage (.res) et la scène (.tscn). Renvoie le nombre de triangles.
func save() -> int:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MODULE_DIR))
	var root := build_node()
	var tris := 0
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := (mi as MeshInstance3D).mesh
		tris += StyleKit.triangles(m)
		var mp := MESH_DIR + id + ("" if mi.name == "Maillage" else "_" + String(mi.name).to_snake_case()) + ".res"
		ResourceSaver.save(m, mp, ResourceSaver.FLAG_COMPRESS)
		(mi as MeshInstance3D).mesh = load(mp)
	_own(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, MODULE_DIR + id + ".tscn")
	root.free()
	return tris

static func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)
