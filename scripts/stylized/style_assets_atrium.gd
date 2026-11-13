@tool
class_name StyleAssetsAtrium
extends RefCounted
## Modules supplémentaires de l'atrium (finition esthétique). Même repère et mêmes outils que StyleAssets
## (StyleKit, ModuleBuilder, StyleAssets.M). Les modules existants restent dans style_assets.gd et y sont améliorés.

static func ids() -> PackedStringArray:
	return PackedStringArray([])

static func make(id: String) -> ModuleBuilder:
	match id:
		_: pass
	return null
