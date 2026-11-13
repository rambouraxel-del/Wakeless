@tool
extends RefCounted
## Particules d'ambiance du Bureau des rêves (poussière dorée, pétales, poussière de chambre). Peu de particules, petites,
## peu lumineuses. Aucun hasard à l'exécution de notre côté : tout est déclaré ici ; le mouvement interne des particules
## GPU est celui du moteur (graine fixe). Utilisé par tools/authoring/build_bureau_reves.gd (_ambiance).

static var _soft: GradientTexture2D

static func soft_texture() -> GradientTexture2D:
	if _soft == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
		_soft = GradientTexture2D.new()
		_soft.gradient = g
		_soft.fill = GradientTexture2D.FILL_RADIAL
		_soft.fill_from = Vector2(0.5, 0.5)
		_soft.fill_to = Vector2(1.0, 0.5)
		_soft.width = 32
		_soft.height = 32
	return _soft

static func _sprite(additive: bool, size: Vector2) -> QuadMesh:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = soft_texture()
	m.disable_receive_shadows = true
	m.no_depth_test = false
	var q := QuadMesh.new()
	q.size = size
	q.material = m
	return q

static func _fade_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.18, 1.0))
	curve.add_point(Vector2(0.82, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

## Poussière en suspension dans un volume (boîte centrée sur `pos`, demi-dimensions `half`). CPUParticles3D : préchauffée,
## graine fixe (déterministe), identique sur tous les moteurs de rendu.
static func dust(nm: String, pos: Vector3, half: Vector3, amount: int, color: Color, size: float, rise := 0.02, life := 16.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = nm
	p.position = pos
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.fixed_fps = 30
	p.explosiveness = 0.0
	p.randomness = 1.0
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = half
	p.direction = Vector3(0.3, 1, 0.1)
	p.spread = 180.0
	p.gravity = Vector3(0, rise, 0)
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.05
	p.damping_min = 0.0
	p.damping_max = 0.02
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	p.scale_amount_curve = _fade_curve()
	p.color = color
	p.mesh = _sprite(true, Vector2(size, size))
	return p

## Pétales qui tombent lentement autour d'un point (cime de l'arbre de lune).
static func petals(nm: String, pos: Vector3, radius: float, amount: int, color: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = nm
	p.position = pos
	p.amount = amount
	p.lifetime = 18.0
	p.preprocess = 18.0
	p.fixed_fps = 30
	p.randomness = 1.0
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3(0, -1, 0)
	p.spread = 100.0
	p.gravity = Vector3(0, -0.26, 0)
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.12
	p.damping_min = 0.2
	p.damping_max = 0.4
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	p.scale_amount_curve = _fade_curve()
	p.color = color
	p.mesh = _sprite(false, Vector2(0.075, 0.045))
	return p
