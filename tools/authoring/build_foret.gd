extends SceneTree
## Édition de départ du niveau « Forêt nocturne » : relief (images maps/foret/*.png), arbres, rochers, ruines et lumières
## posés à des coordonnées EXPLICITES, porte de retour vers le Bureau des rêves.
##   godot --headless -s tools/authoring/make_forest_maps.gd   (une fois : dessine les deux images)
##   godot --headless --import                                 (importe les images)
##   godot --headless -s tools/authoring/build_foret.gd
## Écrit scenes/levels/foret_nocturne.tscn et cuit le terrain (scenes/levels/data/foret_terrain.scn).
## Aucune graine ni dispersion aléatoire : chaque arbre, rocher et lumière est listé ci-dessous (x, z en mètres, centre
## de la forêt = la porte, en 0,0). La hauteur de chaque objet est lue sur le relief au moment de l'édition.
## Une fois la scène enregistrée, elle se modifie à la main dans l'éditeur Godot.

# Arbres : [espèce, x, z, rotation (°), échelle]. Espèces : tree_pine_1/2, tree_oak_1/2/3, tree_birch_1/2,
# tree_weeping_1/2, tree_parasol_1/2.
const TREES := [
	# nord (derrière la porte) : pins serrés, chênes et bouleaux pâles
	["tree_pine_1", -4.0, -9.5, 20, 1.1], ["tree_pine_2", 5.0, -10.5, 140, 1.0], ["tree_pine_1", -10.0, -13.0, 75, 1.2],
	["tree_pine_2", 9.0, -16.0, 200, 1.1], ["tree_pine_1", -16.0, -8.0, 310, 1.0], ["tree_pine_2", 13.0, -9.0, 15, 1.0],
	["tree_pine_1", -6.0, -19.0, 250, 1.2], ["tree_pine_2", 2.0, -22.0, 95, 1.1], ["tree_pine_1", -13.0, -23.0, 170, 1.0],
	["tree_pine_2", 8.0, -28.0, 330, 1.2], ["tree_pine_1", -22.0, -18.0, 60, 1.1], ["tree_pine_2", -2.0, -31.0, 220, 1.0],
	["tree_pine_1", -26.0, -9.0, 120, 1.1], ["tree_pine_2", 16.0, -31.0, 270, 1.0], ["tree_pine_1", -18.0, -30.0, 30, 1.2],
	["tree_oak_1", -12.0, -17.0, 40, 1.0], ["tree_oak_2", 11.0, -21.0, 185, 1.0], ["tree_oak_3", -1.0, -14.5, 300, 1.0],
	["tree_birch_1", -7.0, -26.0, 10, 1.0], ["tree_birch_2", 4.0, -17.0, 150, 1.0], ["tree_birch_1", -20.0, -14.0, 230, 1.0],
	["tree_birch_2", 14.0, -25.0, 80, 1.0],
	# ouest
	["tree_pine_1", -9.0, 2.0, 100, 1.1], ["tree_pine_2", -12.0, 7.0, 25, 1.0], ["tree_pine_1", -17.0, 1.0, 190, 1.2],
	["tree_pine_2", -24.0, 5.0, 340, 1.1], ["tree_pine_1", -29.0, -2.0, 70, 1.0], ["tree_pine_2", -21.0, -6.0, 160, 1.1],
	["tree_oak_1", -10.0, 11.0, 210, 1.0], ["tree_oak_2", -26.0, 10.0, 90, 1.1], ["tree_birch_1", -15.0, 12.0, 50, 1.0],
	["tree_birch_2", -19.0, 5.0, 280, 1.0],
	# sud-ouest
	["tree_pine_1", -8.0, 14.0, 130, 1.1], ["tree_pine_2", -14.0, 19.0, 255, 1.0], ["tree_pine_1", -6.0, 22.0, 5, 1.2],
	["tree_pine_2", -20.0, 22.0, 175, 1.1], ["tree_pine_1", -11.0, 27.0, 315, 1.0], ["tree_pine_2", -25.0, 18.0, 45, 1.2],
	["tree_pine_1", -3.0, 28.0, 205, 1.0], ["tree_oak_3", -17.0, 26.0, 120, 1.0], ["tree_oak_1", -1.5, 19.0, 335, 1.0],
	["tree_birch_1", -9.0, 20.0, 65, 1.0], ["tree_birch_2", -22.0, 14.0, 240, 1.0],
	# sud
	["tree_pine_1", 4.0, 26.0, 85, 1.1], ["tree_pine_2", 10.0, 28.0, 195, 1.0], ["tree_pine_1", 2.0, 31.0, 20, 1.2],
	["tree_pine_2", 15.0, 30.0, 300, 1.1], ["tree_oak_2", 7.0, 25.0, 150, 1.0],
	# sud-est
	["tree_pine_1", 19.0, 27.0, 110, 1.1], ["tree_pine_2", 25.0, 25.0, 235, 1.0], ["tree_pine_1", 31.0, 21.0, 355, 1.2],
	["tree_pine_2", 12.0, 17.0, 60, 1.0], ["tree_birch_1", 16.5, 27.0, 90, 1.0], ["tree_oak_3", 19.0, 13.0, 270, 1.0],
	["tree_oak_1", 31.0, 15.0, 140, 1.1],
	# est
	["tree_pine_2", 34.0, 10.0, 200, 1.1], ["tree_pine_1", 32.0, -2.0, 15, 1.0], ["tree_pine_2", 35.0, -8.0, 305, 1.2],
	["tree_pine_1", 29.0, -13.5, 75, 1.0], ["tree_pine_2", 23.0, -2.5, 165, 1.1], ["tree_oak_2", 34.0, 1.0, 40, 1.0],
	["tree_oak_3", 20.0, -8.5, 250, 1.0], ["tree_birch_2", 33.5, 6.0, 120, 1.0],
	# nord-est et ruines : saules pleureurs autour de la clairière des ruines
	["tree_pine_1", 29.0, -20.0, 10, 1.1], ["tree_pine_2", 31.0, -28.0, 180, 1.2], ["tree_pine_1", 14.0, -12.0, 290, 1.0],
	["tree_weeping_1", 15.5, -22.0, 20, 1.0], ["tree_weeping_2", 28.5, -23.0, 160, 1.0], ["tree_weeping_1", 18.0, -32.0, 310, 1.0],
	["tree_weeping_2", 27.0, -31.0, 90, 1.0],
	# arbres parasols : silhouettes en ombrelle, ponctuent la forêt
	["tree_parasol_1", -9.5, 9.0, 0, 1.0], ["tree_parasol_2", 9.0, -13.5, 90, 1.0], ["tree_parasol_1", -24.0, -20.0, 200, 1.0],
	["tree_parasol_2", 22.0, 30.0, 45, 1.0], ["tree_parasol_1", 34.0, -16.0, 270, 1.0], ["tree_parasol_2", -31.0, 15.0, 130, 1.0],
]

# Rochers : [asset, x, z, rotation (°), échelle]
const ROCKS := [
	["boulder_2", -15.0, -11.0, 20, 1.0], ["boulder_1", -13.0, -9.0, 100, 1.0], ["boulder_3", -16.5, -8.5, 250, 1.0],
	["boulder_3", -6.5, -2.0, 70, 1.0], ["boulder_1", 6.8, -4.0, 200, 1.0],
	["boulder_3", 5.0, 14.0, 130, 1.0], ["boulder_1", 10.5, 24.5, 330, 1.0],
	["boulder_4", 19.0, -28.5, 40, 1.0], ["boulder_1", 26.5, -22.0, 160, 1.0], ["boulder_2", 17.0, -27.5, 285, 1.0],
	["boulder_4", 31.0, -4.0, 90, 1.0], ["boulder_2", 32.0, -6.5, 210, 1.0],
]

# Lampadaires à éclat le long du sentier : [x, z] (le côté du sentier est choisi à la main)
const LAMPS := [[1.8, 10.0], [6.5, 17.0], [14.0, 19.8], [23.5, 17.0], [28.5, 8.0], [24.5, -4.0], [21.0, -12.5], [19.4, -19.5]]

# Cristaux lumineux : [asset, x, z, rotation (°)]
const CRYSTALS := [["crystal_cluster", 24.0, -26.0, 30], ["crystal_cluster", 18.8, -23.5, 200], ["crystal_cluster", -17.5, -4.0, 80],
	["crystal_cluster", 11.5, -6.5, 310], ["crystal_cluster", -8.0, 7.5, 150], ["crystal_cluster", 5.0, 23.0, 20]]

# Chemin du sentier (pour les contrôles de dégagement) : mêmes points que make_forest_maps.gd
const PATH := [[0.0, 3.0], [0.0, 9.0], [2.0, 15.0], [7.0, 20.0], [14.0, 22.0], [21.0, 19.0], [27.0, 12.0], [29.0, 4.0],
	[26.0, -6.0], [22.0, -14.0], [21.0, -21.0]]

var terrain: HeightmapTerrain

func _initialize() -> void:
	VoxelMesher.palette_warmup()
	var root := Level.new()
	root.name = "ForetNocturne"
	root.level_id = "foret-nocturne"
	root.level_title = "La forêt de l'autre côté"
	root.level_subtitle = "Nuit"
	root.lighting_preset = "foret_nuit"
	root.default_spawn = "depart"
	root.interior = false
	root.kill_y = -8.0

	terrain = HeightmapTerrain.new()
	terrain.name = "Relief"
	terrain.height_map = "res://maps/foret/relief.png"
	terrain.paint_map = "res://maps/foret/peinture.png"
	terrain.max_height_m = 10.2
	terrain.baked_path = "res://scenes/levels/data/foret_terrain.scn"
	root.add_child(terrain)
	if not terrain.bake():
		push_error("Cuisson du terrain impossible")
		quit(1)
		return
	print("terrain : %d colonnes, %d blocs, %d triangles" % [terrain.stats["columns"], terrain.stats["chunks"], terrain.stats["triangles"]])

	var door_y := terrain.surface_y(0.0, 0.0)
	var spawns := AuthorKit.group(root, "Spawns")
	AuthorKit.marker(spawns, "depart", Vector3(0.0, door_y + 0.05, 2.4), 180.0)         # sort de la porte, regarde vers le sud

	var decor := AuthorKit.group(root, "Decor")
	var warn := 0
	var trees := AuthorKit.group(decor, "Arbres")
	for t in TREES:
		warn += _check_clear(String(t[0]), t[1], t[2])
		var y := terrain.surface_y(t[1], t[2]) - 0.05
		AuthorKit.asset(trees, String(t[0]), Vector2(t[1], t[2]), y, t[3], t[4])
	var rocks := AuthorKit.group(decor, "Rochers")
	for r in ROCKS:
		AuthorKit.asset(rocks, String(r[0]), Vector2(r[1], r[2]), terrain.surface_y(r[1], r[2]) - 0.1, r[3], r[4])
	var lamps := AuthorKit.group(decor, "Lampadaires")
	for l in LAMPS:
		AuthorKit.asset(lamps, "crystal_lamp", Vector2(l[0], l[1]), terrain.surface_y(l[0], l[1]) - 0.02, _toward_path(l[0], l[1]))
	var crystals := AuthorKit.group(decor, "Cristaux")
	for c in CRYSTALS:
		AuthorKit.asset(crystals, String(c[0]), Vector2(c[1], c[2]), terrain.surface_y(c[1], c[2]) - 0.05, c[3])
	_ruins(AuthorKit.group(decor, "Ruines"))
	_fireflies(decor)
	_walls(AuthorKit.group(root, "Limites"))
	_lights(AuthorKit.group(root, "Lumieres"), door_y)
	_door(AuthorKit.group(root, "Portes"), door_y)
	print("contrôles de dégagement : %d avertissement(s)" % warn)
	AuthorKit.save_scene(root, "res://scenes/levels/foret_nocturne.tscn")
	root.free()
	quit(0)

# ------------------------------------------------------------------ ruines

func _ruins(g: Node3D) -> void:
	var c := Vector2(22.0, -26.0)
	var y := terrain.surface_y(c.x, c.y)
	AuthorKit.asset(g, "ruin_arch", c, y - 0.05, 0.0)
	AuthorKit.asset(g, "ruin_column", Vector2(17.5, -25.0), terrain.surface_y(17.5, -25.0) - 0.05, 0.0)
	AuthorKit.asset(g, "ruin_column", Vector2(26.5, -25.0), terrain.surface_y(26.5, -25.0) - 0.05, 90.0)
	AuthorKit.asset(g, "ruin_column", Vector2(20.0, -29.5), terrain.surface_y(20.0, -29.5) - 0.05, 180.0)
	AuthorKit.asset(g, "ruin_column", Vector2(24.5, -30.0), terrain.surface_y(24.5, -30.0) - 0.05, 270.0)
	AuthorKit.asset(g, "decorative_bench", Vector2(22.0, -21.0), terrain.surface_y(22.0, -21.0) - 0.05, 180.0)
	AuthorKit.asset(g, "brazier", Vector2(19.5, -20.6), terrain.surface_y(19.5, -20.6) - 0.05, 0.0)
	AuthorKit.asset(g, "brazier", Vector2(24.5, -20.6), terrain.surface_y(24.5, -20.6) - 0.05, 0.0)
	AuthorKit.asset(g, "shrine_marker", Vector2(22.0, -24.0), terrain.surface_y(22.0, -24.0) - 0.05, 0.0)

# ------------------------------------------------------------------ lucioles (particules)

func _fireflies(g: Node3D) -> void:
	for spot in [["Lucioles_sentier_sud", Vector3(6.0, 1.6, 17.0)], ["Lucioles_sentier_est", Vector3(27.0, 2.0, 2.0)],
			["Lucioles_clairiere", Vector3(0.0, 2.4, 0.0)], ["Lucioles_ruines", Vector3(22.0, 2.8, -24.0)]]:
		var p := GPUParticles3D.new()
		p.name = spot[0]
		p.amount = 36
		p.lifetime = 9.0
		p.preprocess = 9.0
		p.position = spot[1]
		p.visibility_aabb = AABB(Vector3(-9, -3, -9), Vector3(18, 6, 18))
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(7.0, 1.2, 7.0)
		pm.direction = Vector3(0.3, 0.4, 0.1)
		pm.spread = 180.0
		pm.initial_velocity_min = 0.12
		pm.initial_velocity_max = 0.45
		pm.gravity = Vector3.ZERO
		pm.turbulence_enabled = true
		pm.turbulence_noise_strength = 0.4
		pm.turbulence_noise_scale = 2.0
		pm.scale_min = 0.7
		pm.scale_max = 1.5
		var curve := Curve.new()
		curve.add_point(Vector2(0.0, 0.0))
		curve.add_point(Vector2(0.25, 1.0))
		curve.add_point(Vector2(0.75, 1.0))
		curve.add_point(Vector2(1.0, 0.0))
		var ct := CurveTexture.new()
		ct.curve = curve
		pm.scale_curve = ct
		p.process_material = pm
		var quad := QuadMesh.new()
		quad.size = Vector2(0.06, 0.06)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_color = Color(0.85, 1.0, 0.45, 1.0)
		quad.material = mat
		p.draw_pass_1 = quad
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(p)

# ------------------------------------------------------------------ limites invisibles du niveau

func _walls(g: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "MursInvisibles"
	g.add_child(body)
	for w in [["nord", Vector3(0, 10, -40.5), Vector3(82, 40, 1)], ["sud", Vector3(0, 10, 40.5), Vector3(82, 40, 1)],
			["ouest", Vector3(-40.5, 10, 0), Vector3(1, 40, 82)], ["est", Vector3(40.5, 10, 0), Vector3(1, 40, 82)]]:
		var cs := CollisionShape3D.new()
		cs.name = w[0]
		var bs := BoxShape3D.new()
		bs.size = w[2]
		cs.shape = bs
		cs.position = w[1]
		body.add_child(cs)

# ------------------------------------------------------------------ lumières

func _lights(g: Node3D, door_y: float) -> void:
	var dream := Color(0.55, 1.0, 0.9)
	AuthorKit.omni(g, "porte_reve", Vector3(0.0, door_y + 1.4, 1.0), dream, 2.4, 9.0, true)
	AuthorKit.omni(g, "ruines_cristal", Vector3(22.0, terrain.surface_y(22.0, -26.0) + 1.6, -26.0), Color(0.45, 0.8, 1.0), 2.4, 9.0, false)
	AuthorKit.omni(g, "brasero_g", Vector3(19.5, terrain.surface_y(19.5, -20.6) + 1.0, -20.6), Color(1.0, 0.62, 0.3), 2.0, 7.0, false)
	AuthorKit.omni(g, "brasero_d", Vector3(24.5, terrain.surface_y(24.5, -20.6) + 1.0, -20.6), Color(1.0, 0.62, 0.3), 2.0, 7.0, false)
	for c in CRYSTALS:
		var nm := "lueur_%d_%d" % [roundi(c[1]), roundi(c[2])]
		AuthorKit.omni(g, nm, Vector3(c[1], terrain.surface_y(c[1], c[2]) + 0.8, c[2]), Color(0.5, 0.85, 1.0), 1.2, 5.0, false)

# ------------------------------------------------------------------ porte de retour (freestanding, sur son socle de pierre)

func _door(g: Node3D, door_y: float) -> void:
	var d := SceneDoor.new()
	d.name = "Porte_du_reve"
	d.position = Vector3(-0.6, door_y, 0.0)          # charnière ; l'ouverture est centrée sur x = 0
	d.look = SceneDoor.Look.REVE
	d.leaf_width = 1.2
	d.leaf_height = 2.4
	d.build_frame = true
	d.portal_glow = true
	d.target_scene = "res://scenes/levels/bureau_des_reves.tscn"
	d.target_spawn = "reveil"           # sortir du rêve = se réveiller sur le lit du rêveur
	d.prompt = "Se réveiller"
	g.add_child(d)

# ------------------------------------------------------------------ aides

## Orientation (°) d'un lampadaire : sa façade regarde le sentier le plus proche.
func _toward_path(x: float, z: float) -> float:
	var best := 1e9
	var dir := Vector2(0, 1)
	var p := Vector2(x, z)
	for k in PATH.size() - 1:
		var a := Vector2(PATH[k][0], PATH[k][1])
		var ab := Vector2(PATH[k + 1][0], PATH[k + 1][1]) - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var q := a + ab * t
		if p.distance_to(q) < best:
			best = p.distance_to(q)
			dir = q - p
	return rad_to_deg(atan2(dir.x, dir.y))

## Un arbre ne doit ni boucher le sentier (1,8 m du milieu), ni la clairière de la porte (rayon 7 m).
func _check_clear(id: String, x: float, z: float) -> int:
	var p := Vector2(x, z)
	var bad := 0
	if p.length() < 7.0:
		print("AVERTISSEMENT : %s (%.1f, %.1f) dans la clairière de la porte" % [id, x, z])
		bad += 1
	for k in PATH.size() - 1:
		var a := Vector2(PATH[k][0], PATH[k][1])
		var ab := Vector2(PATH[k + 1][0], PATH[k + 1][1]) - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if p.distance_to(a + ab * t) < 2.6:
			print("AVERTISSEMENT : %s (%.1f, %.1f) trop près du sentier (%.1f m)" % [id, x, z, p.distance_to(a + ab * t)])
			bad += 1
			break
	return bad
