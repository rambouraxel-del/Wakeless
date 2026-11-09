extends SceneTree
## Outil d'édition : (re)construit scenes/characters/star_faced_one.tscn.
##   godot --headless --path . -s tools/authoring/build_star_faced_one_scene.gd
## Le GLB (assets/characters/star_faced_one/star_faced_one.glb) n'est jamais modifié. La scène est ensuite éditable
## normalement dans Godot : réglages des particules, de la lumière du visage, hauteur du modèle…
##
## Arbre produit :
##   StarFacedOne (Node3D, StarFacedOneModel)
##     Tilt (Node3D)               inclinaison d'accélération, dans le repère du modèle (regard vers -z)
##       Visual (Node3D)           tourné de 180° : le GLB regarde vers +z
##         Model                   GLB instancié (squelette, 28 maillages, 11 animations)
##     FaceGlow (OmniLight3D)      lueur chaude du visage (suit l'os « face », voir le script)
##     Fx
##       Motes (GPUParticles3D)    petites étoiles qui flottent autour du personnage
##       Trail (GPUParticles3D)    traînée discrète pendant les déplacements
## Le maillage d'étoile des particules est fourni au lancement par GuardianFx (pas de .res binaire dans le dépôt).

const GLB := "res://assets/characters/star_faced_one/star_faced_one.glb"
const OUT_SCENE := "res://scenes/characters/star_faced_one.tscn"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_SCENE.get_base_dir())
	var root := Node3D.new()
	root.name = "StarFacedOne"
	root.set_script(load("res://scripts/characters/star_faced_one_model.gd"))
	var tilt := Node3D.new()
	tilt.name = "Tilt"
	root.add_child(tilt)
	var visual := Node3D.new()
	visual.name = "Visual"
	visual.rotation = Vector3(0.0, PI, 0.0)
	tilt.add_child(visual)
	var model := (load(GLB) as PackedScene).instantiate()
	model.name = "Model"
	visual.add_child(model)

	var light := OmniLight3D.new()
	light.name = "FaceGlow"
	light.light_color = Color(1.0, 0.8, 0.45)
	light.light_energy = 0.5
	light.omni_range = 3.0
	light.omni_attenuation = 1.6
	light.shadow_enabled = false
	light.position = Vector3(0.0, 0.75, -0.2)
	root.add_child(light)

	var fx := Node3D.new()
	fx.name = "Fx"
	root.add_child(fx)
	fx.add_child(_motes())
	fx.add_child(_trail())

	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	var err := ResourceSaver.save(ps, OUT_SCENE)
	print("scène : ", OUT_SCENE, " (", error_string(err), ")")
	quit(0 if err == OK else 1)

func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		if c.scene_file_path == "":
			_own(c, owner_node)

func _alpha_ramp(peak: float, fade_in: float) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, fade_in, 0.7, 1.0])
	g.colors = PackedColorArray([
		Color(1.0, 0.82, 0.45, 0.0), Color(1.0, 0.88, 0.55, peak),
		Color(1.0, 0.8, 0.45, peak * 0.55), Color(1.0, 0.75, 0.4, 0.0)])
	var t := GradientTexture1D.new()
	t.gradient = g
	return t

func _shrink_curve() -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.6))
	c.add_point(Vector2(0.25, 1.0))
	c.add_point(Vector2(1.0, 0.15))
	var t := CurveTexture.new()
	t.curve = c
	return t

func _motes() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Motes"
	p.amount = 14
	p.lifetime = 4.5
	p.preprocess = 4.5
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 3, 4))
	p.draw_order = GPUParticles3D.DRAW_ORDER_INDEX
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
	pm.emission_sphere_radius = 0.62
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.06
	pm.gravity = Vector3(0, 0.035, 0)
	pm.damping_min = 0.1
	pm.damping_max = 0.2
	pm.scale_min = 0.020
	pm.scale_max = 0.042
	pm.scale_curve = _shrink_curve()
	pm.color_ramp = _alpha_ramp(0.8, 0.2)
	p.process_material = pm
	p.position = Vector3(0.0, 0.62, 0.0)
	return p

func _trail() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Trail"
	p.amount = 26
	p.lifetime = 0.9
	p.local_coords = false
	p.emitting = false
	p.visibility_aabb = AABB(Vector3(-3, -0.5, -3), Vector3(6, 3, 6))
	p.draw_order = GPUParticles3D.DRAW_ORDER_INDEX
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.26
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.12
	pm.gravity = Vector3(0, 0.08, 0)
	pm.damping_min = 0.8
	pm.damping_max = 1.4
	pm.scale_min = 0.016
	pm.scale_max = 0.034
	pm.scale_curve = _shrink_curve()
	pm.color_ramp = _alpha_ramp(0.75, 0.12)
	p.process_material = pm
	p.position = Vector3(0.0, 0.14, 0.18)      # derrière le personnage (le regard est vers -z)
	return p
