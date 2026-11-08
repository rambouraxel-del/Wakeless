extends SceneTree
## Compile tous les scripts GDScript du projet (erreurs de syntaxe ou de référence = échec).
##   godot --headless -s tools/check_scripts.gd

func _initialize() -> void:
	var files := _scan("res://scripts") + _scan("res://tools") + _scan("res://tests")
	var bad := 0
	for f in files:
		var s := load(f) as GDScript
		if s == null or not s.can_instantiate() and not s.is_tool() and s.get_instance_base_type() == &"":
			print("ÉCHEC  ", f)
			bad += 1
	print("%d scripts compilés, %d en échec" % [files.size(), bad])
	quit(1 if bad > 0 else 0)

func _scan(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for sub in d.get_directories():
		out += _scan(dir + "/" + sub)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	return out
