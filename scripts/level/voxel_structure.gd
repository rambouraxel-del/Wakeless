@tool
class_name VoxelStructure
extends Node3D
## Architecture construite à la main : rastérise les VoxelBox enfants (ordre de l'arbre) sur la grille de 10 cm
## (VoxelGrid.STRUCTURE_SIZE, matières de config/palette.json, shader voxel unique), produit UN maillage et UNE
## collision (ConcavePolygonShape3D).
##
## Cuisson : le maillage glouton est calculé hors jeu et rangé dans `baked_path` (scène binaire .scn). Au lancement,
## seule cette scène est chargée (instantané). Dans l'éditeur : après avoir modifié des boîtes, cocher « Recuire »
## (ou appeler `bake()`), puis enregistrer la scène. Si la signature des boîtes ne correspond plus au fichier cuit,
## le jeu recalcule la structure à la volée et le signale (avertissement) : rien n'est jamais silencieusement périmé.

const CELL := VoxelGrid.STRUCTURE_SIZE
const CHUNK := 64                       # cellules par bloc de maillage (6,4 m)

@export_file("*.scn") var baked_path := ""
@export var baked_signature := ""
@export var collision := true
@export var recuire := false:
	set(v):
		recuire = false
		if v and is_inside_tree() and Engine.is_editor_hint():
			bake()

var stats := {"cells": 0, "triangles": 0, "boxes": 0, "from_cache": false}
var _live: Node3D

func _ready() -> void:
	rebuild_view()

func boxes() -> Array[VoxelBox]:
	var out: Array[VoxelBox] = []
	_collect(self, out)
	return out

func _collect(n: Node, out: Array[VoxelBox]) -> void:
	for c in n.get_children():
		if c is VoxelBox:
			out.append(c)
		_collect(c, out)

## Empreinte du contenu des boîtes (positions en cellules, tailles, matières, modes).
func signature() -> String:
	var parts := PackedStringArray()
	for b in boxes():
		var c := b.cells(self, CELL)
		parts.append("%s|%s|%d|%d,%d,%d|%d,%d,%d" % [b.name, b.material, b.mode, c[0].x, c[0].y, c[0].z, c[1].x, c[1].y, c[1].z])
	return "%08x" % hash("\n".join(parts))

## (Re)crée le nœud visible : fichier cuit s'il est à jour, calcul à la volée sinon.
func rebuild_view() -> void:
	if _live != null:
		_live.queue_free()
		_live = null
	var sig := signature()
	if baked_path != "" and ResourceLoader.exists(baked_path) and baked_signature == sig:
		var packed := load(baked_path) as PackedScene
		if packed != null:
			_live = packed.instantiate() as Node3D
			_live.name = "Cuit"
			add_child(_live)
			stats["from_cache"] = true
			return
	if baked_path != "" and not Engine.is_editor_hint():
		push_warning("VoxelStructure %s : fichier cuit absent ou périmé (signature) — recalcul à la volée. Recuire dans l'éditeur." % name)
	_live = _make_node()
	_live.name = "Cuit"
	add_child(_live)
	stats["from_cache"] = false

## Cuit la structure et l'enregistre dans `baked_path`.
func bake() -> bool:
	if baked_path == "":
		push_error("VoxelStructure %s : renseigner baked_path avant de cuire." % name)
		return false
	var node := _make_node()
	_set_owner(node, node)
	var packed := PackedScene.new()
	if packed.pack(node) != OK:
		node.free()
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(baked_path.get_base_dir()))
	var err := ResourceSaver.save(packed, baked_path, ResourceSaver.FLAG_COMPRESS)
	node.free()
	baked_signature = signature()
	if is_inside_tree():
		rebuild_view()
	return err == OK

func _set_owner(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_set_owner(c, owner_node)

## Rastérise les boîtes et fabrique maillage + collision (sans dépendre de l'éditeur ni de la scène).
func _make_node() -> Node3D:
	var root := Node3D.new()
	root.name = "Cuit"
	var bx := boxes()
	stats["boxes"] = bx.size()
	var lo := Vector3i(1 << 30, 1 << 30, 1 << 30)
	var hi := Vector3i(-(1 << 30), -(1 << 30), -(1 << 30))
	var rects: Array = []
	for b in bx:
		var c := b.cells(self, CELL)
		rects.append(c)
		if b.mode == VoxelBox.Mode.AJOUTER:
			lo = Vector3i(mini(lo.x, c[0].x), mini(lo.y, c[0].y), mini(lo.z, c[0].z))
			hi = Vector3i(maxi(hi.x, c[1].x), maxi(hi.y, c[1].y), maxi(hi.z, c[1].z))
	if hi.x < lo.x:
		return root
	var size := hi - lo + Vector3i.ONE
	var kit := VoxelModelBuilder.new(size)
	for i in bx.size():
		var b := bx[i]
		var c: Array = rects[i]
		var key: String = b.material if b.mode == VoxelBox.Mode.AJOUTER else ""
		if key != "" and not VoxelPalette.get_default().has_key(key):
			push_error("VoxelBox %s : matière inconnue « %s »" % [b.name, key])
			continue
		kit.box(c[0].x - lo.x, c[0].y - lo.y, c[0].z - lo.z, c[1].x - lo.x, c[1].y - lo.y, c[1].z - lo.z, key)
	stats["cells"] = kit.volume.count_solid()
	# Maillage par blocs de 6,4 m (frustum culling, limite de lumières par objet des rendus modestes)
	var tris := 0
	var body := StaticBody3D.new()
	body.name = "Collision"
	var origin := Vector3(lo) * CELL
	for cz in range(0, size.z, CHUNK):
		for cx in range(0, size.x, CHUNK):
			var rmin := Vector3i(cx, 0, cz)
			var rmax := Vector3i(mini(cx + CHUNK, size.x), size.y, mini(cz + CHUNK, size.z)) - Vector3i.ONE
			var arrays := VoxelMesher.build_arrays(kit.volume, CELL, rmin, rmax, PackedByteArray(), Vector3i.ZERO, 0, VoxelMesher.Style.DETAIL)
			var mesh := VoxelMesher.arrays_to_mesh(arrays, VoxelMesher.Style.DETAIL)
			if mesh == null:
				continue
			mesh.surface_set_material(0, VoxelMaterials.props_material())
			tris += VoxelMesher.triangle_count(mesh)
			var mi := MeshInstance3D.new()
			mi.name = "Bloc_%d_%d" % [cx / CHUNK, cz / CHUNK]
			mi.mesh = mesh
			mi.position = origin
			root.add_child(mi)
			if collision:
				var cs := CollisionShape3D.new()
				cs.name = "Forme_%d_%d" % [cx / CHUNK, cz / CHUNK]
				cs.shape = mesh.create_trimesh_shape()
				cs.position = origin
				body.add_child(cs)
	stats["triangles"] = tris
	if collision:
		root.add_child(body)
	return root
