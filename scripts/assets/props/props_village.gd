@tool
extends RefCounted
## Mobilier d'extérieur (planches 2 et 3) : jardinière, tonneaux, sanctuaire, caisses, clôture. Microvoxels de 2 cm.
## build(args) : args["id"] choisit le modèle.

static func build(args: Dictionary) -> VoxelAsset:
	match String(args["id"]):
		"large_planter": return _planter()
		"barrel_set": return _barrels()
		"shrine_marker": return _shrine()
		"crate_stack": return _crates()
		"garden_fence": return _fence()
	return null

# ------------------------------------------------------------------ jardinière
static func _planter() -> VoxelAsset:
	var a := VoxelAsset.new("large_planter", "Grande jardinière", Vector3i(8, 5, 3), "Bac de pierre cerclé de bois et de cuivre, fleurs et lavande.")
	var k := AssetKit.new(Vector3i(80, 50, 30), 704)
	k.masonry(0, 0, 0, 79, 17, 29, 16, 9, 3)
	k.box(0, 18, 0, 79, 20, 29, "stone_carved")
	k.box(3, 19, 3, 76, 20, 26, "")
	k.box(3, 17, 3, 76, 19, 26, "potting_soil")
	k.planks(2, 6, 0, 77, 11, 0, 0, 1, 3, ["wood_planks", "wood_honey"], false)
	for x in [0, 77]:
		k.corner_plate(x, 0, 1 if x == 0 else -1, 1, 4, 17, 5)
		k.corner_plate(x + (2 if x == 77 else 0), 29, 1 if x == 0 else -1, -1, 4, 17, 5)
	# Motif de losange de cuivre sur la face avant.
	for dy in range(-4, 5):
		var w := 4 - absi(dy)
		k.box(40 - w, 10 + dy, 0, 40 + w, 10 + dy, 0, "copper")
	k.bush(Vector3(20, 22, 15), Vector3(16, 8, 11), "flower_white", 0.2)
	k.bush(Vector3(55, 22, 14), Vector3(15, 7, 10), "flower_pink", 0.18)
	# Lavande : tiges bleues.
	for i in 36:
		var x := 28 + i
		var z := 8 + (i * 7) % 14
		k.line(Vector3(x, 19, z), Vector3(x + 0.4, 29 + (i % 5), z), 1, "leaf_olive")
		k.box(x, 29 + (i % 5), z, x, 33 + (i % 5), z, "flower_blue")
	k.ivy(Vector3i(70, 22, 1), 12, Vector3i(1, 0, 0), 0.1)
	k.ivy(Vector3i(4, 22, 1), 13, Vector3i(1, 0, 0), 0.1)
	a.add_part("structure", k)
	a.add_collider(Vector3i(0, 0, 0), Vector3i(79, 22, 29))
	a.lod_ranges = [10.0, 28.0, 0.0]
	return a

# ------------------------------------------------------------------ tonneaux
static func _barrels() -> VoxelAsset:
	var a := VoxelAsset.new("barrel_set", "Tonneaux et caisse", Vector3i(7, 5, 5), "Deux tonneaux cerclés de cuivre, une caisse, une jarre et un cordage.")
	var k := AssetKit.new(Vector3i(70, 54, 50), 708)
	k.barrel(20, 22, 0, 50, 15.0, 11.5)
	k.barrel(49, 15, 0, 38, 12.0, 9.5, "wood_honey", "iron")
	k.crate(54, 0, 28, 68, 14, 42, "wood_planks", "copper")
	# Jarre en terre cuite.
	for y in 22:
		var r := 7.0 * sin(PI * (y + 3) / 28.0) + 1.5
		k.cyl_y(44, 38, y, y, r, "terracotta")
	k.cyl_y(44, 38, 22, 24, 4.2, "terracotta", 2.8)
	# Cordage au sol.
	for t in 80:
		var ang := t * 0.3
		k.set_if_empty(int(8 + cos(ang) * (4 + t * 0.06)), 0, int(40 + sin(ang) * (4 + t * 0.06)), "rope")
	k.banner(7, 49, 5, 14, 20, 2, 3)
	a.add_part("structure", k)
	a.add_collider(Vector3i(0, 0, 0), Vector3i(69, 50, 49))
	a.lod_ranges = [10.0, 28.0, 0.0]
	return a

# ------------------------------------------------------------------ sanctuaire
static func _shrine() -> VoxelAsset:
	var a := VoxelAsset.new("shrine_marker", "Sanctuaire", Vector3i(6, 12, 6), "Borne de pierre à niche ogivale, éclat bleu, bougies et bannière.")
	var k := AssetKit.new(Vector3i(60, 116, 60), 709)
	k.masonry(0, 0, 0, 59, 11, 59, 14, 8, 3)
	k.masonry(8, 12, 8, 51, 21, 51, 12, 8, 3)
	# Stèle : fût et niche ogivale creusée.
	k.stone_block(18, 22, 18, 41, 82, 41, 3, "stone_light")
	k.box(16, 22, 16, 43, 25, 43, "stone_carved")
	for y in range(26, 58):
		var half := 6 if y < 46 else maxi(6 - (y - 46) / 2, 0)
		if half > 0:
			k.box(30 - half, y, 41, 29 + half, y, 41, "")
	k.box(26, 26, 38, 33, 44, 40, "stone_shade")
	# Éclat dans la niche, cadre de cuivre.
	k.crystal(Vector3(30, 28, 39), 17.0, 3.0, Vector2.ZERO, "crystal_blue", 0.35)
	for y in range(26, 58):
		var half := 6 if y < 46 else maxi(6 - (y - 46) / 2, 0)
		if half > 0:
			k.set_cell(30 - half - 1, y, 41, "copper")
			k.set_cell(29 + half + 1, y, 41, "copper")
	# Chapiteau pyramidal et capuchon.
	for i in 8:
		k.stone_block(17 + i, 83 + i * 2, 17 + i, 42 - i, 84 + i * 2, 42 - i, 0, "stone_carved")
	k.copper_cap(26, 26, 100, 8, 4)
	k.banner(21, 80, 42, 18, 40, 2, 4)
	# Bougies sur le socle.
	for p in [Vector2i(6, 2), Vector2i(12, 4), Vector2i(48, 3)]:
		k.box(p.x, 12, p.y + 6, p.x + 2, 17, p.y + 8, "paper")
		k.box(p.x + 1, 18, p.y + 7, p.x + 1, 20, p.y + 7, "fire")
	k.moss_top(0, 0, 59, 59, 0.35, 9)
	k.bush(Vector3(6, 14, 50), Vector3(7, 5, 7), "flower_white", 0.22)
	k.bush(Vector3(54, 14, 8), Vector3(6, 4, 6), "flower_white", 0.2)
	k.ivy(Vector3i(40, 80, 18), 50, Vector3i(1, 0, 0), 0.1)
	a.add_part("structure", k)
	a.add_light(Vector3(30, 38, 46), Color("7fd2ff"), 0.8, 3.0)
	a.add_collider(Vector3i(0, 0, 0), Vector3i(59, 100, 59))
	a.lod_ranges = [14.0, 40.0, 0.0]
	return a

# ------------------------------------------------------------------ pile de caisses
static func _crates() -> VoxelAsset:
	var a := VoxelAsset.new("crate_stack", "Caisses empilées", Vector3i(5, 5, 5), "Caisses de bois cerclées de cuivre et sac de grain.")
	var k := AssetKit.new(Vector3i(50, 54, 50), 710)
	k.crate(0, 0, 0, 27, 21, 27, "wood_planks", "copper")
	k.crate(30, 0, 4, 47, 15, 22, "wood_honey", "iron")
	k.crate(3, 22, 3, 21, 37, 21, "wood_planks", "copper")
	k.ellipsoid(Vector3(38, 8, 38), Vector3(9, 8, 9), "fabric_cream")
	k.box(35, 15, 35, 41, 17, 41, "rope")
	k.line(Vector3(0, 22, 0), Vector3(27, 22, 27), 1, "iron_dark")
	k.ivy(Vector3i(24, 36, 8), 14, Vector3i(0, 0, 1), 0.0)
	a.add_part("structure", k)
	a.add_collider(Vector3i(0, 0, 0), Vector3i(49, 37, 49))
	a.lod_ranges = [10.0, 26.0, 0.0]
	return a

# ------------------------------------------------------------------ clôture (module de 1 m)
static func _fence() -> VoxelAsset:
	var a := VoxelAsset.new("garden_fence", "Clôture de jardin", Vector3i(5, 4, 1), "Module de clôture en lattes avec poteaux à chapeau de cuivre.")
	var k := AssetKit.new(Vector3i(50, 42, 6), 711)
	for x in [0, 45]:
		k.post(x, 0, 0, 36, 5, "wood_dark")
		k.copper_cap(x, 0, 37, 5, 2)
	k.box(5, 26, 1, 44, 29, 3, "wood_planks")
	k.box(5, 10, 1, 44, 13, 3, "wood_planks")
	for x in range(7, 44, 6):
		k.box(x, 4, 2, x + 3, 30, 3, "wood_honey")
		k.box(x, 31, 2, x + 3, 32, 3, "wood_honey")
	a.add_part("structure", k)
	a.add_collider(Vector3i(0, 0, 0), Vector3i(49, 36, 5))
	a.lod_ranges = [8.0, 22.0, 0.0]
	return a
