extends SceneTree
## Contrôles de la finition esthétique (chambre 107 et couloir) : budgets avant/après, lit intact, pas de hasard à
## l'exécution, matériaux de coque enregistrés. Lancer : godot --headless -s tests/run_checks_finition_b.gd
const LEVEL := "res://scenes/levels/bureau_des_reves.tscn"
const TRIS_AVANT := 577662        # triangles du niveau avant la finition (9cd3f4a)
const LUMIERES_AVANT := 66
var ok := 0
var fail := 0

func check(label: String, cond: bool, detail := "") -> void:
	if cond:
		ok += 1
	else:
		fail += 1
		print("  ECHEC : ", label, " ", detail)

func _initialize() -> void:
	var lv := (load(LEVEL) as PackedScene).instantiate()
	var tris := 0
	for mi in lv.find_children("*", "MeshInstance3D", true, false):
		tris += StyleKit.triangles((mi as MeshInstance3D).mesh)
	var lights := lv.find_children("*", "Light3D", true, false).size()
	print("finition B : %d triangles (avant %d), %d lumières (avant %d)" % [tris, TRIS_AVANT, lights, LUMIERES_AVANT])
	check("budget finition : ≤ +120 000 triangles (%d)" % (tris - TRIS_AVANT), tris - TRIS_AVANT <= 120000)
	check("budget finition : ≤ +14 lumières (%d)" % (lights - LUMIERES_AVANT), lights - LUMIERES_AVANT <= 14)
	for id in StyleAssetsChambre.ids():
		check("module %s : scène présente" % id, ResourceLoader.exists("res://assets/stylized/modules/%s.tscn" % id))
	for m in ["papier_peint", "parquet_lames", "moulure_lilas", "flaque_lune", "rideau_velours", "lin_lavande", "lin_creme", "rose_lune", "abat_jour", "voilage", "tapis_prune", "tableau_nuit", "miroir"]:
		check("matériau %s enregistré" % m, ResourceLoader.exists(StyleMaterials.path_of(m)))
	# lit : collision de couchage inchangée (dessus à 0,72 m), marqueur de coucher, couette à 0,80 m
	var bed := lv.get_node("Chambre/Lit")
	var top := 0.0
	for cs in bed.find_children("*", "CollisionShape3D", true, false):
		var sh := (cs as CollisionShape3D).shape as BoxShape3D
		var t := cs as CollisionShape3D
		if sh.size.x > 1.5 and sh.size.z > 2.0:
			top = t.position.y + sh.size.y * 0.5
	check("lit : dessus de la collision à 0,72 m (%.2f)" % top, absf(top - 0.72) < 0.01)
	var lie := lv.get_node("Chambre/Lit_du_reveur/Coucher") as Marker3D
	check("lit : point de coucher à 0,85 m", absf(lie.position.y - 0.85) < 0.001)
	check("lit : duvet à 0,80 m", absf(StyleAssets.DUVET_Y - 0.80) < 0.001 and StyleAssets._duvet_top(0.0, 0.3) < 0.82)
	# pas de hasard à l'exécution dans les fichiers de la finition
	for path in ["res://scripts/stylized/style_assets_chambre.gd", "res://scripts/stylized/style_materials_chambre.gd"]:
		var src := FileAccess.get_file_as_string(path)
		check("%s : aucun randf / RandomNumberGenerator" % path.get_file(), not src.contains("randf") and not src.contains("RandomNumberGenerator"))
	lv.free()
	print("== finition B : %d vérifications réussies, %d échec(s)" % [ok, fail])
	quit(1 if fail > 0 else 0)
