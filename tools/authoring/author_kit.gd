@tool
class_name AuthorKit
extends RefCounted
## Aides des scripts d'édition (tools/authoring/*.gd) : posent des boîtes, assets cuits, lumières et portes avec des
## coordonnées EXPLICITES (mètres), puis enregistrent la scène. Ces scripts sont des outils de départ : une fois la
## scène (.tscn) enregistrée, c'est elle la source de vérité, modifiable à la main dans l'éditeur Godot.
## Aucune génération aléatoire : chaque position est écrite dans le script.

const A := VoxelBox.Mode.AJOUTER
const C := VoxelBox.Mode.CREUSER

## Boîte de construction : `p` = coin minimum (m), `s` = taille (m), `m` = matière de la palette.
static func box(parent: Node, nm: String, p: Vector3, s: Vector3, m: String, mode := A) -> VoxelBox:
	var b := VoxelBox.new()
	b.name = nm
	b.position = p
	b.size = s
	b.material = m
	b.mode = mode
	parent.add_child(b)
	return b

static func carve(parent: Node, nm: String, p: Vector3, s: Vector3) -> VoxelBox:
	return box(parent, nm, p, s, "air", C)

static func group(parent: Node, nm: String) -> Node3D:
	var g := Node3D.new()
	g.name = nm
	parent.add_child(g)
	return g

static func omni(parent: Node, nm: String, p: Vector3, color: Color, energy: float, range_m: float, shadow := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = nm
	l.position = p
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_m
	l.shadow_enabled = shadow
	l.distance_fade_enabled = true
	l.distance_fade_begin = 30.0
	l.distance_fade_shadow = 16.0
	l.distance_fade_length = 10.0
	parent.add_child(l)
	return l

static func marker(parent: Node, nm: String, p: Vector3, yaw_deg: float) -> Marker3D:
	var m := Marker3D.new()
	m.name = nm
	m.position = p
	m.rotation_degrees = Vector3(0, yaw_deg, 0)
	parent.add_child(m)
	return m

## Pose un asset cuit : `c` = point (x, z) où se trouve le CENTRE de son emprise au sol ; `y` = hauteur du sol.
## `yaw_deg` tourne autour de ce centre. L'origine d'un asset est le coin minimum de son emprise.
static func asset(parent: Node, id: String, c: Vector2, y: float, yaw_deg := 0.0, scale := 1.0, nm := "") -> Node3D:
	var node := AssetLibrary.instantiate(id)
	if node == null:
		push_error("Asset cuit introuvable : %s" % id)
		return null
	var fp: Array = AssetLibrary.info(id).get("footprint_cells", [1, 1, 1])
	var size := Vector3(float(fp[0]), float(fp[1]), float(fp[2])) * VoxelGrid.VOXEL_SIZE
	var basis := Basis(Vector3.UP, deg_to_rad(yaw_deg)).scaled(Vector3.ONE * scale)
	node.name = nm if nm != "" else id.to_pascal_case()
	node.transform = Transform3D(basis, Vector3(c.x, y, c.y) - basis * Vector3(size.x * 0.5, 0.0, size.z * 0.5))
	parent.add_child(node)
	return node

## Donne un propriétaire à tous les nœuds créés (sauf l'intérieur des scènes instanciées) pour pouvoir les enregistrer.
static func set_owners(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		if c.scene_file_path == "":
			set_owners(c, owner_node)

static func save_scene(root: Node, path: String) -> bool:
	set_owners(root, root)
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		push_error("Impossible d'empaqueter %s" % path)
		return false
	var err := ResourceSaver.save(packed, path)
	print("scène enregistrée : %s (%s)" % [path, "ok" if err == OK else "ERREUR %d" % err])
	return err == OK
