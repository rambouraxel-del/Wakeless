@tool
class_name HeightmapTerrain
extends Node3D
## Relief construit à la main : une image de hauteurs (1 pixel = 1 colonne de 20 cm, clair = haut) et, en option, une
## image de matières (peinture) dessinées dans n'importe quel logiciel d'images. Le terrain est « voxelisé » à la grille
## de 20 cm d'Éclat (mêmes matières, même shader, mêmes marches de 20 cm), maillé par chunks (maillage glouton,
## calculé en parallèle), avec une collision exacte par chunk.
##
## Cuisson : comme VoxelStructure, le résultat est rangé dans `baked_path` (.scn) ; le jeu ne charge que ce fichier.
## Éditeur : modifier les images, cocher « Recuire », enregistrer la scène. Le terrain est centré sur le nœud.
##
## Couleurs de la peinture (tolérance : couleur la plus proche) : noir = herbe de nuit, marron = sentier,
## gris = roche, vert foncé = mousse, beige = terre sèche, bleu = herbe humide/fougères.
## Les pentes fortes deviennent roche (sauf sentier).

const V := VoxelGrid.VOXEL_SIZE
const CHUNK := 32

const PAINT := [
	[Color(0, 0, 0), "grass_night"],
	[Color(0.55, 0.40, 0.25), "path_dirt"],
	[Color(0.5, 0.5, 0.5), "rock_grey"],
	[Color(0.16, 0.35, 0.2), "moss_dark"],
	[Color(0.75, 0.65, 0.45), "dirt_dry"],
	[Color(0.2, 0.4, 0.75), "grass_lush"],
]

@export_file("*.png") var height_map := ""
@export_file("*.png") var paint_map := ""
## Hauteur (m) d'un pixel blanc.
@export var max_height_m := 8.0
@export_file("*.scn") var baked_path := ""
@export var baked_signature := ""
@export var recuire := false:
	set(v):
		recuire = false
		if v and is_inside_tree() and Engine.is_editor_hint():
			bake()

var stats := {"columns": 0, "chunks": 0, "triangles": 0, "from_cache": false}
var heights := PackedInt32Array()           # sommet de chaque colonne (cellules, première cellule vide)
var nx := 0
var nz := 0
var _live: Node3D

func _ready() -> void:
	rebuild_view()

# ------------------------------------------------------------------ lecture des images

func _image(path: String) -> Image:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var tex := load(path) as Texture2D
	if tex == null:
		return null
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	return img

## Lit l'image de hauteurs (obligatoire pour cuire ou interroger le relief).
func prepare() -> bool:
	var img := _image(height_map)
	if img == null:
		push_error("HeightmapTerrain %s : image de hauteurs illisible (%s)" % [name, height_map])
		return false
	nx = img.get_width()
	nz = img.get_height()
	heights.resize(nx * nz)
	for z in nz:
		for x in nx:
			var r := img.get_pixel(x, z).r
			heights[x + z * nx] = maxi(roundi(r * max_height_m / V), 2)
	return true

## Hauteur de surface (m) au point (x, z) du repère du nœud (après prepare()).
func surface_y(x_m: float, z_m: float) -> float:
	if heights.is_empty():
		return 0.0
	var cx := clampi(floori(x_m / V + nx * 0.5), 0, nx - 1)
	var cz := clampi(floori(z_m / V + nz * 0.5), 0, nz - 1)
	return float(heights[cx + cz * nx]) * V

func signature() -> String:
	var h := PackedByteArray()
	for p in [height_map, paint_map]:
		if p != "" and FileAccess.file_exists(p):
			h.append_array(FileAccess.get_file_as_bytes(p))
	h.append_array(("%f" % max_height_m).to_utf8_buffer())
	return "%08x" % hash(h)

# ------------------------------------------------------------------ affichage

func rebuild_view() -> void:
	if _live != null:
		_live.queue_free()
		_live = null
	if baked_path != "" and ResourceLoader.exists(baked_path):
		# Dans le jeu exporté, les PNG bruts ne sont pas présents : la signature n'est contrôlée que depuis les sources.
		var verify := OS.has_feature("editor")
		if not verify or baked_signature == signature():
			var packed := load(baked_path) as PackedScene
			if packed != null:
				_live = packed.instantiate() as Node3D
				_live.name = "Cuit"
				add_child(_live)
				stats["from_cache"] = true
				return
		push_warning("HeightmapTerrain %s : fichier cuit périmé (images modifiées) — recalcul. Recuire dans l'éditeur." % name)
	if height_map == "":
		return
	_live = _make_node()
	if _live != null:
		_live.name = "Cuit"
		add_child(_live)
	stats["from_cache"] = false

func bake() -> bool:
	if baked_path == "":
		push_error("HeightmapTerrain %s : renseigner baked_path avant de cuire." % name)
		return false
	var node := _make_node()
	if node == null:
		return false
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

# ------------------------------------------------------------------ voxelisation

func _paint_key(c: Color) -> String:
	var best := 1e9
	var key := "grass_night"
	for e in PAINT:
		var col: Color = e[0]
		var d := (c.r - col.r) * (c.r - col.r) + (c.g - col.g) * (c.g - col.g) + (c.b - col.b) * (c.b - col.b)
		if d < best:
			best = d
			key = e[1]
	return key

func _make_node() -> Node3D:
	if not prepare():
		return null
	var pal := VoxelPalette.get_default()
	var paint := _image(paint_map)
	if paint != null and (paint.get_width() != nx or paint.get_height() != nz):
		paint.resize(nx, nz, Image.INTERPOLATE_NEAREST)
	var max_h := 0
	for h in heights:
		max_h = maxi(max_h, h)
	var vol := VoxelVolume.new(Vector3i(nx, max_h + 1, nz))
	var sx := nx
	var syz := nx * nz
	var id_dirt := pal.id("dirt")
	var id_stone := pal.id("stone_dark")
	var id_rock := pal.id("rock_grey")
	var ids := {}
	for e in PAINT:
		ids[e[1]] = pal.id(e[1])
	var data := vol.data
	for z in nz:
		for x in nx:
			var top := heights[x + z * nx]            # cellules 0 … top-1 pleines
			var key := "grass_night"
			if paint != null:
				key = _paint_key(paint.get_pixel(x, z))
			# pente : écart maximal avec les 4 voisines
			var steep := 0
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var xx: int = clampi(x + d.x, 0, nx - 1)
				var zz: int = clampi(z + d.y, 0, nz - 1)
				steep = maxi(steep, absi(heights[xx + zz * nx] - top))
			var top_id: int = ids[key]
			if steep >= 3 and key != "path_dirt":
				top_id = id_rock
			var col := x + z * sx
			for y in top - 1:
				data[col + y * syz] = id_dirt if y >= top - 3 else id_stone
			data[col + (top - 1) * syz] = top_id
	vol.data = data
	stats["columns"] = nx * nz
	# chunks maillés en parallèle (régions de CHUNK × hauteur × CHUNK)
	var jobs := []
	for cz in range(0, nz, CHUNK):
		for cx in range(0, nx, CHUNK):
			jobs.append([Vector3i(cx, 0, cz), Vector3i(mini(cx + CHUNK, nx) - 1, max_h, mini(cz + CHUNK, nz) - 1)])
	var results := []
	results.resize(jobs.size())
	VoxelMesher.palette_warmup()
	var task := WorkerThreadPool.add_group_task(func(i: int) -> void:
		var j: Array = jobs[i]
		results[i] = VoxelMesher.build_arrays(vol, V, j[0], j[1], PackedByteArray(), Vector3i.ZERO, 0, VoxelMesher.Style.STYLIZED),
		jobs.size(), -1, true, "HeightmapTerrain meshing")
	WorkerThreadPool.wait_for_group_task_completion(task)
	var root := Node3D.new()
	root.name = "Cuit"
	var origin := Vector3(-nx * V * 0.5, 0.0, -nz * V * 0.5)
	var body := StaticBody3D.new()
	body.name = "Collision"
	root.add_child(body)
	var tris := 0
	var chunks := 0
	for i in jobs.size():
		var mesh := VoxelMesher.arrays_to_mesh(results[i], VoxelMesher.Style.STYLIZED)
		if mesh == null:
			continue
		var rmin: Vector3i = jobs[i][0]
		var mi := MeshInstance3D.new()
		mi.name = "Chunk_%d_%d" % [rmin.x / CHUNK, rmin.z / CHUNK]
		mi.mesh = mesh
		mi.position = origin
		root.add_child(mi)
		var cs := CollisionShape3D.new()
		cs.name = "Forme_%d_%d" % [rmin.x / CHUNK, rmin.z / CHUNK]
		cs.shape = mesh.create_trimesh_shape()
		cs.position = origin
		body.add_child(cs)
		tris += VoxelMesher.triangle_count(mesh)
		chunks += 1
	stats["chunks"] = chunks
	stats["triangles"] = tris
	return root
