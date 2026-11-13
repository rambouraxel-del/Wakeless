@tool
class_name StyleAssetsForet
extends RefCounted
## KIT ORGANIQUE PROVISOIRE de la Forêt de la peur (arbres, troncs, racines, rochers, plantes, ruines…).
## Assets temporaires stylisés, remplaçables plus tard par des modèles Blender : chaque module garde le même id,
## la même origine (au sol, centré) et la même empreinte de collision, pour qu'un remplacement ne touche pas au niveau.
## Hors de StyleAssets.all_ids() (budget du Bureau des rêves séparé) ; fabriqué par build_stylized_assets.gd.

static func ids() -> PackedStringArray:
	return PackedStringArray([])

static func make(id: String) -> ModuleBuilder:
	match id:
		_: pass
	return null
