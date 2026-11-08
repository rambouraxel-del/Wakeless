@tool
extends RefCounted
## Rangement (planche 4) : coffre de ravitaillement. Microvoxels de 2 cm.

static func build(args: Dictionary) -> VoxelAsset:
	match String(args["id"]):
		"supply_chest": return _supply_chest()
	return null

# ------------------------------------------------------------------ coffre de ravitaillement
static func _supply_chest() -> VoxelAsset:
	var a := VoxelAsset.new("supply_chest", "Coffre de ravitaillement", Vector3i(6, 3, 3), "Long coffre de bois cerclé de cuivre à coins de pierre, bande de toile bleue.")
	var k := AssetKit.new(Vector3i(60, 32, 30), 734)
	k.planks(0, 0, 0, 59, 20, 29, 0, 1, 4, ["wood_planks", "wood_honey", "wood_planks"], true)
	k.box(0, 21, 0, 59, 23, 29, "wood_dark")
	for i in 5:
		k.planks(2 + i, 24 + i, 3 + i, 57 - i, 24 + i, 26 - i, 0, 2, 4, ["wood_honey", "wood_planks"], false)
	for x in [0, 52]:
		k.stone_block(x, 0, 0, x + 7, 22, 7, 3)
		k.stone_block(x, 0, 22, x + 7, 22, 29, 3)
	for x in [16, 38]:
		k.box(x, 0, 0, x + 3, 28, 0, "copper")
		k.box(x, 0, 29, x + 3, 28, 29, "copper")
		k.box(x, 24, 4, x + 3, 28, 25, "copper")
	k.box(28, 12, 29, 33, 22, 30, "copper")
	k.box(29, 14, 30, 32, 17, 31, "iron_dark")
	k.runner(22, 14, 6, 24, 25, 12, 3)
	k.ivy(Vector3i(2, 23, 2), 14, Vector3i(0, 0, 1), 0.08)
	a.add_part("structure", k)
	a.add_collider(Vector3i(0, 0, 0), Vector3i(59, 28, 29))
	a.lod_ranges = [10.0, 26.0, 0.0]
	return a
