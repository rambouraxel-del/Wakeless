class_name GuardianFx
extends RefCounted
## Éléments partagés des effets de gardien : petite étoile à quatre branches pour les particules.
## Construite en code (9 sommets, entièrement déterministe) plutôt que sauvegardée en .res : un maillage binaire
## enregistré par une version récente de Godot ne se recharge pas forcément dans une version plus ancienne.

static var _mesh: ArrayMesh

## Étoile à quatre branches (plan XY, face +z) : branches longues + éclats diagonaux courts, avec son matériau.
static func star_mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector3] = []
	for i in 8:
		var a := PI * 0.5 + TAU * float(i) / 8.0
		var r := 1.0 if i % 2 == 0 else 0.34
		pts.append(Vector3(cos(a) * r, sin(a) * r, 0.0))
	for i in 8:
		var nx := pts[(i + 1) % 8]
		for v: Vector3 in [Vector3.ZERO, pts[i], nx]:
			st.set_normal(Vector3(0, 0, 1))
			st.set_uv(Vector2(v.x * 0.5 + 0.5, 0.5 - v.y * 0.5))
			st.add_vertex(v)
	_mesh = st.commit()
	_mesh.surface_set_material(0, particle_material())
	return _mesh

## Matériau des particules : additif, sans éclairage, couleur de sommet = couleur de la particule.
static func particle_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(1.0, 0.86, 0.5)
	m.disable_receive_shadows = true
	return m
