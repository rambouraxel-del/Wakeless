@tool
class_name StyleAssetsChambre
extends RefCounted
## Modules supplémentaires de la chambre 107 et du couloir (finition esthétique). Même repère et mêmes outils que StyleAssets
## (StyleKit, ModuleBuilder, StyleAssets.M). Les modules existants restent dans style_assets.gd et y sont améliorés.

static func ids() -> PackedStringArray:
	return PackedStringArray([])

static func make(id: String) -> ModuleBuilder:
	match id:
		_: pass
	return null
