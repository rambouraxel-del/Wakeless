extends SceneTree
## Fabrique les matériaux et TOUS les modules de la 3D stylisée (Bureau des rêves) :
##   godot --headless -s tools/authoring/build_stylized_assets.gd            (tout)
##   godot --headless -s tools/authoring/build_stylized_assets.gd -- lit_reveur colonne
## Écrit materials/stylized/*.tres, assets/stylized/meshes/*.res, assets/stylized/modules/*.tscn et un rapport
## (assets/stylized/rapport_modules.json : triangles, lumières, collisions). Les niveaux instancient ces modules.

func _initialize() -> void:
	var n := StyleMaterials.build_all()
	print("matériaux : %d" % n)
	var ids: Array = Array(OS.get_cmdline_user_args())
	if ids.is_empty():
		ids = Array(StyleAssets.all_ids())
	var report := {}
	var path := "res://assets/stylized/rapport_modules.json"
	if FileAccess.file_exists(path):
		var old = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(old) == TYPE_DICTIONARY:
			report = old
	for id in ids:
		var b := StyleAssets.make(id)
		if b == null:
			push_error("module inconnu : %s" % id)
			continue
		var lights := b.lights.size()
		var cols := b.colliders.size()
		var tris := b.save()
		report[id] = {"triangles": tris, "lumieres": lights, "collisions": cols}
		print("%-24s %7d triangles · %d lumière(s) · %d boîte(s)" % [id, tris, lights, cols])
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t", true))
	f.close()
	quit()
