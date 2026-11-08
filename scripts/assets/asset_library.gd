@tool
class_name AssetLibrary
extends RefCounted
## Registre des assets (objets, bâtiments, arbres, véhicule). Chaque entrée pointe vers un
## script de construction `build()` qui renvoie un VoxelAsset ; tools/bake_assets.gd génère
## ensuite scènes, maillages (avec niveaux de détail) et fiche JSON.
## Groupes : "prop", "tree".

const PROPS_DIR := "res://scripts/assets/props/"
const BUILDINGS_DIR := "res://scripts/assets/buildings/"
const ASSET_DIR := "res://assets/props"

# id → [groupe, script, arguments passés à build(args)]
# Wakeless : registre réduit aux assets réutilisés d'Éclat (végétation, rochers, éclairage, mobilier d'ambiance).
# Les maillages sont « cuits » (assets/props/<id>/) par tools/bake_assets.gd ; au runtime, rien n'est généré :
# le jeu instancie uniquement les scènes cuites. Les variantes d'arbres/rochers sont des graines FIGÉES ci-dessous.
const NATURE := "res://scripts/assets/nature/"
const REGISTRY := {}

static var _extra := {}
static var _info_cache := {}

static func all_ids() -> PackedStringArray:
	return PackedStringArray(_all().keys())

static func ids_in(group: String) -> PackedStringArray:
	var out := PackedStringArray()
	var all := _all()
	for k in all:
		if all[k][0] == group:
			out.append(k)
	return out

static func _all() -> Dictionary:
	if _extra.is_empty():
		_extra = _entries()
	return _extra

static func _entries() -> Dictionary:
	var d := {}
	# --- Arbres : espèces × variantes figées ---
	for spec in [["oak", "Chêne", 3], ["parasol", "Arbre parasol", 2], ["pine", "Pin", 2],
			["weeping", "Saule pleureur", 2], ["birch", "Bouleau", 2], ["fruit", "Arbre fruitier", 2]]:
		for v in spec[2]:
			d["tree_%s_%d" % [spec[0], v + 1]] = ["tree", NATURE + "trees.gd", {"species": spec[0], "seed": v + 1, "name": "%s %d" % [spec[1], v + 1]}]
	# --- Rochers (variantes figées : graine, taille, teinte) ---
	for v in [[1, 14, true], [2, 20, false], [3, 10, true], [4, 26, true]]:
		d["boulder_%d" % v[0]] = ["tree", NATURE + "rocks.gd", {"seed": v[0], "size": v[1], "warm": v[2]}]
	# --- Objets d'ambiance ---
	var props := "res://scripts/assets/props/"
	for id in ["large_planter", "barrel_set", "shrine_marker", "crate_stack", "garden_fence"]:
		d[id] = ["prop", props + "props_village.gd", {"id": id}]
	for id in ["crystal_lamp", "banner_stand", "signpost", "notice_board", "brazier"]:
		d[id] = ["prop", props + "props_decor.gd", {"id": id}]
	for id in ["supply_chest"]:
		d[id] = ["prop", props + "props_craft.gd", {"id": id}]
	for id in ["crystal_cluster", "ruin_column", "ruin_arch"]:
		d[id] = ["prop", props + "props_ancient.gd", {"id": id}]
	# --- Mobilier du Bureau des rêves (Wakeless) ---
	for id in ["hotel_bed", "hotel_nightstand", "hotel_wardrobe", "hotel_armchair", "hotel_floor_lamp"]:
		d[id] = ["prop", props + "props_hotel.gd", {"id": id}]
	d["decorative_bench"] = ["prop", props + "decorative_bench.gd"]
	d["ancient_chest"] = ["prop", props + "ancient_chest.gd"]
	return d

static func group_of(id: String) -> String:
	return _all()[id][0]

## Construit la description procédurale (voxels) d'un asset.
static func build(id: String) -> VoxelAsset:
	var entry: Array = _all()[id]
	var script: GDScript = load(entry[1])
	var asset: VoxelAsset = script.call("build", entry[2]) if entry.size() > 2 else script.call("build")
	if asset.id == "":
		asset.id = id
	asset.category = _all()[id][0]
	return asset

## Scène Godot générée par tools/bake_assets.gd.
static func scene_path(id: String) -> String:
	return "%s/%s/%s.tscn" % [ASSET_DIR, id, id]

static func info_path(id: String) -> String:
	return "%s/%s/%s.info.json" % [ASSET_DIR, id, id]

static func instantiate(id: String) -> Node3D:
	var packed := load(scene_path(id)) as PackedScene
	return packed.instantiate() as Node3D if packed else null

## Fiche générée (pièces, maillages par niveau de détail, lumières, collisions, statistiques).
static func info(id: String) -> Dictionary:
	if not _info_cache.has(id):
		var text := FileAccess.get_file_as_string(info_path(id))
		var parsed = JSON.parse_string(text)
		_info_cache[id] = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	return _info_cache[id]
