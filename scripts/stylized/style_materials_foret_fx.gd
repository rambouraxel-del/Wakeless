@tool
class_name StyleMaterialsForetFx
extends RefCounted
## Matériaux partagés d'ambiance de la forêt (sol, chemin, eau sombre, brume, lueurs, particules). Sonnet C.
## Ids : foret_sol, foret_chemin, foret_eau, foret_brume, foret_brume_dense, foret_brume_marais, foret_lueur_cyan,
## foret_lueur_chaude, foret_rayon, foret_luciole, foret_spore, foret_petale. `ids()` sert à n'enregistrer que ceux-ci.

const DIR := "res://materials/stylized/"
const IDS := ["foret_sol", "foret_chemin", "foret_eau", "foret_brume", "foret_brume_dense", "foret_brume_marais",
	"foret_lueur_cyan", "foret_lueur_chaude", "foret_rayon", "foret_luciole", "foret_spore", "foret_petale"]

static func ids() -> Array:
	return IDS

static func _shader(nm: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(DIR + nm + ".gdshader")
	return m

static func _soft_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	return t

static func _sprite(additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_texture()
	m.disable_receive_shadows = true
	m.disable_fog = additive
	return m

static func add(d: Dictionary) -> void:
	var sol := _shader("foret_sol")
	d["foret_sol"] = sol
	d["foret_chemin"] = _shader("foret_chemin")
	d["foret_eau"] = _shader("foret_eau")
	d["foret_brume"] = _shader("foret_brume")
	var dense := _shader("foret_brume")
	dense.set_shader_parameter("fog_color", Color("#0f0d26"))
	dense.set_shader_parameter("fog_color_hi", Color("#262a52"))
	dense.set_shader_parameter("density", 0.55)
	dense.set_shader_parameter("patchy", 0.4)
	dense.set_shader_parameter("noise_scale", 0.05)
	d["foret_brume_dense"] = dense
	var marais := _shader("foret_brume")
	marais.set_shader_parameter("fog_color", Color("#15405a"))
	marais.set_shader_parameter("fog_color_hi", Color("#2c7f90"))
	marais.set_shader_parameter("density", 0.42)
	marais.set_shader_parameter("scroll", Vector2(0.02, -0.01))
	d["foret_brume_marais"] = marais
	d["foret_lueur_cyan"] = _shader("foret_lueur")
	var chaude := _shader("foret_lueur")
	chaude.set_shader_parameter("core_color", Color("#fff4dc"))
	chaude.set_shader_parameter("halo_color", Color("#ffc890"))
	chaude.set_shader_parameter("energy", 2.0)
	chaude.set_shader_parameter("halo_energy", 0.8)
	chaude.set_shader_parameter("pulse_amount", 0.15)
	chaude.set_shader_parameter("pulse_speed", 0.9)
	d["foret_lueur_chaude"] = chaude
	d["foret_rayon"] = _shader("foret_rayon")
	d["foret_luciole"] = _sprite(true)
	d["foret_spore"] = _sprite(true)
	d["foret_petale"] = _sprite(false)
