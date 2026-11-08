@tool
extends RefCounted
## Mobilier du Bureau des rêves (Wakeless) : lit, table de nuit à lampe, armoire, fauteuil, lampadaire de couloir.
## Même outil et même échelle que les assets d'Éclat (AssetKit, microvoxels de 2 cm, matières de config/palette.json) ;
## cuits ensuite par tools/bake_assets.gd. Façade de chaque objet vers +z.

static func build(args: Dictionary) -> VoxelAsset:
	match String(args["id"]):
		"hotel_bed": return _bed()
		"hotel_nightstand": return _nightstand()
		"hotel_wardrobe": return _wardrobe()
		"hotel_armchair": return _armchair()
		"hotel_floor_lamp": return _floor_lamp()
	return null

# ------------------------------------------------------------------ lit 1,60 × 2,10 m
static func _bed() -> VoxelAsset:
	var a := VoxelAsset.new("hotel_bed", "Lit d'hôtel", Vector3i(8, 6, 11), "Lit double, tête de lit en bois sombre, couvre-lit prune.")
	var k := AssetKit.new(Vector3i(80, 60, 105), 801)
	# pieds et cadre
	for x in [0, 74]:
		for z in [0, 99]:
			k.box(x, 0, z, x + 5, 12, z + 5, "wood_dark")
	k.box(0, 12, 0, 79, 21, 104, "wood_dark")
	k.box(1, 13, 1, 78, 20, 103, "wood_red")
	# sommier / matelas
	k.box(3, 21, 5, 76, 33, 101, "bed_linen")
	k.box(3, 33, 5, 76, 33, 101, "wood_pale_old")
	k.box(3, 33, 5, 76, 33, 8, "bed_linen")
	# couvre-lit prune, drapé sur les côtés, repli crème au niveau des oreillers
	k.box(2, 34, 38, 77, 36, 102, "velvet_plum")
	k.box(1, 24, 38, 2, 36, 102, "velvet_plum")
	k.box(77, 24, 38, 78, 36, 102, "velvet_plum")
	k.box(2, 24, 102, 77, 36, 103, "velvet_plum")
	k.box(2, 36, 36, 77, 37, 41, "bed_linen")
	k.box(2, 34, 41, 77, 36, 43, "carpet_gold")
	# oreillers
	for x0 in [8, 43]:
		k.box(x0, 34, 10, x0 + 28, 41, 32, "bed_linen")
		k.box(x0 + 2, 41, 12, x0 + 26, 42, 30, "bed_linen")
		k.box(x0 + 8, 40, 14, x0 + 20, 42, 28, "paper")
	# tête de lit : panneau haut, cadre, losanges de laiton
	k.box(0, 12, 0, 79, 58, 4, "wood_dark")
	k.box(4, 22, 3, 75, 52, 5, "wood_red")
	k.box(7, 26, 5, 38, 48, 5, "wood_honey")
	k.box(41, 26, 5, 72, 48, 5, "wood_honey")
	for x in [8, 71]:
		k.box(x - 3, 52, 0, x + 3, 59, 4, "wood_dark")
		k.box(x - 1, 59, 1, x + 1, 60, 3, "brass")
	k.box(0, 56, 0, 79, 58, 5, "wood_dark")
	# pied de lit bas
	k.box(2, 12, 100, 77, 30, 104, "wood_dark")
	k.box(5, 15, 104, 74, 27, 104, "wood_red")
	k.box(37, 20, 105 - 1, 42, 24, 104, "brass")
	a.add_part("structure", k)
	a.add_collider(Vector3i(0, 0, 0), Vector3i(79, 37, 104))
	a.add_collider(Vector3i(0, 37, 0), Vector3i(79, 59, 5))
	a.lod_ranges = [14.0, 36.0, 0.0]
	return a

# ------------------------------------------------------------------ table de nuit + lampe
static func _nightstand() -> VoxelAsset:
	var a := VoxelAsset.new("hotel_nightstand", "Table de nuit et lampe", Vector3i(3, 5, 2), "Petite table à tiroir, lampe à abat-jour chaud.")
	var k := AssetKit.new(Vector3i(28, 50, 22), 802)
	for x in [0, 23]:
		for z in [0, 17]:
			k.box(x, 0, z, x + 3, 17, z + 3, "wood_dark")
	k.box(0, 17, 0, 27, 30, 21, "wood_red")
	k.box(2, 19, 21, 25, 28, 21, "wood_honey")
	k.box(12, 23, 21, 15, 25, 22, "brass")
	k.box(0, 30, 0, 27, 32, 21, "wood_dark")
	# lampe : pied de laiton, tige, abat-jour
	k.cyl_y(13.5, 10.5, 32, 34, 4.5, "brass")
	k.cyl_y(13.5, 10.5, 35, 41, 1.2, "brass")
	k.cyl_y(13.5, 10.5, 42, 43, 2.4, "brass")
	k.cyl_y(13.5, 10.5, 44, 46, 6.0, "lamp_warm")
	k.cyl_y(13.5, 10.5, 47, 49, 4.6, "lamp_warm")
	k.cyl_y(13.5, 10.5, 50, 50, 3.2, "brass")
	a.add_part("structure", k)
	a.add_light(Vector3(13.5, 46, 10.5), Color("ffc27a"), 1.5, 4.5)
	a.add_collider(Vector3i(0, 0, 0), Vector3i(27, 32, 21))
	a.lod_ranges = [12.0, 32.0, 0.0]
	return a

# ------------------------------------------------------------------ armoire 1,20 × 0,55 × 2,20 m
static func _wardrobe() -> VoxelAsset:
	var a := VoxelAsset.new("hotel_wardrobe", "Armoire", Vector3i(6, 11, 3), "Armoire à deux portes, corniche moulurée, poignées de laiton.")
	var k := AssetKit.new(Vector3i(60, 110, 28), 803)
	k.box(2, 0, 2, 5, 5, 5, "wood_dark")
	k.box(54, 0, 2, 57, 5, 5, "wood_dark")
	k.box(2, 0, 22, 5, 5, 25, "wood_dark")
	k.box(54, 0, 22, 57, 5, 25, "wood_dark")
	k.box(0, 6, 0, 59, 100, 27, "wood_aged_dark")
	# corniche et plinthe
	k.box(0, 101, 0, 59, 104, 27, "wood_dark")
	k.box(2, 105, 1, 57, 107, 26, "wood_aged_dark")
	k.box(0, 6, 0, 59, 9, 27, "wood_dark")
	# deux portes : cadre, panneaux enfoncés, filets
	for x0 in [3, 31]:
		k.box(x0, 11, 27, x0 + 25, 98, 27, "wood_red")
		k.box(x0 + 3, 16, 27, x0 + 22, 56, 27, "wood_honey")
		k.box(x0 + 3, 61, 27, x0 + 22, 93, 27, "wood_honey")
		k.box(x0 + 3, 16, 27, x0 + 22, 16, 27, "wood_dark")
		k.box(x0 + 3, 93, 27, x0 + 22, 93, 27, "wood_dark")
	k.box(29, 11, 27, 30, 98, 27, "wood_dark")
	for x in [26, 33]:
		k.box(x, 52, 27, x + 1, 62, 27, "brass")
	a.add_part("structure", k)
	a.add_collider(Vector3i(0, 0, 0), Vector3i(59, 107, 27))
	a.lod_ranges = [14.0, 36.0, 0.0]
	return a

# ------------------------------------------------------------------ fauteuil
static func _armchair() -> VoxelAsset:
	var a := VoxelAsset.new("hotel_armchair", "Fauteuil", Vector3i(4, 5, 4), "Fauteuil club en velours prune sur pieds de bois.")
	var k := AssetKit.new(Vector3i(42, 46, 42), 804)
	for x in [2, 36]:
		for z in [2, 36]:
			k.box(x, 0, z, x + 3, 9, z + 3, "wood_dark")
	k.box(1, 9, 1, 40, 14, 40, "wood_dark")
	k.box(5, 14, 7, 36, 21, 40, "velvet_plum")          # assise
	k.box(3, 14, 1, 38, 40, 9, "velvet_plum")           # dossier
	k.box(5, 22, 2, 36, 38, 2, "velvet_plum")
	for x in [0, 35]:
		k.box(x, 14, 3, x + 5, 28, 40, "velvet_plum")   # accoudoirs
		k.box(x, 28, 3, x + 5, 29, 40, "wood_dark")
	for x in [14, 27]:
		for y in [26, 32]:
			k.box(x, y, 9, x, y, 9, "brass")            # boutons capitonnés
	a.add_part("structure", k)
	a.add_collider(Vector3i(0, 0, 0), Vector3i(40, 40, 40))
	a.lod_ranges = [12.0, 32.0, 0.0]
	return a

# ------------------------------------------------------------------ lampadaire de couloir
static func _floor_lamp() -> VoxelAsset:
	var a := VoxelAsset.new("hotel_floor_lamp", "Lampadaire d'hôtel", Vector3i(2, 9, 2), "Lampadaire de laiton à abat-jour chaud.")
	var k := AssetKit.new(Vector3i(20, 88, 20), 805)
	k.cyl_y(9.5, 9.5, 0, 2, 8.5, "brass")
	k.cyl_y(9.5, 9.5, 3, 4, 5.0, "brass")
	k.cyl_y(9.5, 9.5, 5, 56, 1.4, "brass")
	k.cyl_y(9.5, 9.5, 28, 30, 2.4, "brass")
	k.cyl_y(9.5, 9.5, 57, 58, 2.6, "brass")
	k.cyl_y(9.5, 9.5, 59, 62, 8.0, "lamp_warm")
	k.cyl_y(9.5, 9.5, 63, 72, 6.8, "lamp_warm")
	k.cyl_y(9.5, 9.5, 73, 76, 5.4, "lamp_warm")
	k.cyl_y(9.5, 9.5, 77, 78, 8.2, "brass")
	k.cyl_y(9.5, 9.5, 58, 58, 8.4, "brass")
	a.add_part("structure", k)
	a.add_light(Vector3(9.5, 66, 9.5), Color("ffc27a"), 1.7, 6.0)
	a.add_collider(Vector3i(2, 0, 2), Vector3i(17, 80, 17))
	a.lod_ranges = [12.0, 32.0, 0.0]
	return a
