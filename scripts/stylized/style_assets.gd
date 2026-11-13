@tool
class_name StyleAssets
extends RefCounted
## Catalogue des MODULES du Bureau des rêves (3D stylisée). Chaque fonction décrit un module avec StyleKit et renvoie un
## ModuleBuilder ; tools/authoring/build_stylized_assets.gd les enregistre tous (assets/stylized/modules/*.tscn).
## Repère commun : origine au sol, module centré en x ; face avant vers +Z ; un module « mural » s'adosse au plan z = 0.

const GOLD := "or"

static func all_ids() -> PackedStringArray:
	return PackedStringArray([
		"colonne", "colonne_courte", "pilastre", "arcade", "porte_hotel", "porte_chambre", "applique", "lanterne",
		"balustrade_3m", "balustrade_4_5m", "fenetre_haute", "fenetre_chambre", "banniere", "lustre_astronomique",
		"horloge_celeste", "bureau_reception", "escalier_grand", "glycine", "arbre_de_lune", "chariot_bagages",
		"table_globe", "banc_velours", "jardiniere", "panneau_directions", "travee_couloir", "travee_couloir_ouverte",
		"lit_reveur", "table_chevet", "armoire", "bureau_ecriture", "fauteuil", "tapis_rond", "etagere_livres",
		"mobile_etoiles", "porte_double_entree",
	]) + StyleAssetsAtrium.ids() + StyleAssetsChambre.ids()

static func make(id: String) -> ModuleBuilder:
	match id:
		"colonne": return colonne("colonne", 5.75)
		"colonne_courte": return colonne("colonne_courte", 4.2)
		"pilastre": return pilastre("pilastre", 8.0)
		"arcade": return arcade()
		"porte_hotel": return porte("porte_hotel", true)
		"porte_chambre": return porte("porte_chambre", false)
		"applique": return applique()
		"lanterne": return lanterne()
		"balustrade_3m": return balustrade("balustrade_3m", 3.0)
		"balustrade_4_5m": return balustrade("balustrade_4_5m", 4.5)
		"fenetre_haute": return fenetre("fenetre_haute", 3.6, 9.0, "vue_nuit_a")
		"fenetre_chambre": return fenetre("fenetre_chambre", 2.2, 3.4, "vue_nuit_c")
		"banniere": return banniere()
		"lustre_astronomique": return lustre()
		"horloge_celeste": return horloge()
		"bureau_reception": return reception()
		"escalier_grand": return escalier()
		"glycine": return glycine()
		"arbre_de_lune": return arbre()
		"chariot_bagages": return chariot()
		"table_globe": return table_globe()
		"banc_velours": return banc()
		"jardiniere": return jardiniere()
		"panneau_directions": return panneau()
		"travee_couloir": return travee(false)
		"travee_couloir_ouverte": return travee(true)
		"lit_reveur": return lit()
		"table_chevet": return chevet()
		"armoire": return armoire()
		"bureau_ecriture": return bureau_ecriture()
		"fauteuil": return fauteuil()
		"tapis_rond": return tapis()
		"etagere_livres": return etagere()
		"mobile_etoiles": return mobile()
		"porte_double_entree": return porte_double()
	var b := StyleAssetsAtrium.make(id)
	if b == null:
		b = StyleAssetsChambre.make(id)
	return b

static func M(n: String) -> Material:
	return StyleMaterials.get_mat(n)

static func P(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in arr:
		out.append(Vector2(v[0], v[1]))
	return out

# ================================================================== architecture

## Colonne : socle, tores, fût légèrement galbé avec bague dorée, chapiteau évasé, tailloir.
static func colonne(id: String, h: float) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	b.box(Vector3(0.95, 0.34, 0.95), 0.07, "pierre_sombre", Vector3(0, 0.17, 0))
	b.add(StyleKit.torus(0.38, 0.07, M(GOLD), 28, 8), ModuleBuilder.at(Vector3(0, 0.41, 0)))
	b.add(StyleKit.torus(0.34, 0.06, M("pierre_claire"), 28, 8), ModuleBuilder.at(Vector3(0, 0.53, 0)))
	var top := h - 0.75
	b.add(StyleKit.lathe(P([[0.31, 0.5], [0.325, 0.5 + (top - 0.5) * 0.33], [0.3, top - 0.2], [0.29, top]]), 24, M("pierre_claire")))
	b.add(StyleKit.torus(0.315, 0.035, M(GOLD), 28, 6), ModuleBuilder.at(Vector3(0, 0.5 + (top - 0.5) * 0.33, 0)))
	b.add(StyleKit.torus(0.3, 0.045, M(GOLD), 28, 6), ModuleBuilder.at(Vector3(0, top + 0.05, 0)))
	b.add(StyleKit.lathe(P([[0.29, top], [0.3, top + 0.12], [0.4, top + 0.38], [0.5, top + 0.5]]), 24, M("pierre_claire"), false, true))
	b.box(Vector3(1.08, 0.25, 1.08), 0.06, "pierre_claire", Vector3(0, h - 0.125, 0))
	b.box(Vector3(1.12, 0.05, 1.12), 0.02, GOLD, Vector3(0, h - 0.27, 0))
	b.collide(Vector3(0.8, h, 0.8), Vector3(0, h * 0.5, 0))
	return b

## Pilastre mural (adossé à z = 0, saillie 0,35 m) avec base, chapiteau doré.
static func pilastre(id: String, h: float) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	b.box(Vector3(0.9, 0.5, 0.45), 0.06, "pierre_sombre", Vector3(0, 0.25, 0.2))
	b.box(Vector3(0.7, h - 1.0, 0.3), 0.08, "pierre_claire", Vector3(0, 0.5 + (h - 1.0) * 0.5, 0.15))
	b.box(Vector3(0.74, 0.08, 0.34), 0.03, GOLD, Vector3(0, 1.4, 0.16))
	b.box(Vector3(0.95, 0.35, 0.45), 0.08, "pierre_claire", Vector3(0, h - 0.33, 0.2))
	b.box(Vector3(0.85, 0.08, 0.4), 0.03, GOLD, Vector3(0, h - 0.56, 0.19))
	b.add(StyleKit.extrude(StyleKit.star_outline(0.14, 0.06, 4), 0.06, M("etoile_or"), 0.015), ModuleBuilder.at(Vector3(0, h - 0.33, 0.43)))
	b.collide(Vector3(0.9, h, 0.45), Vector3(0, h * 0.5, 0.2))
	return b

## Arc décoratif reliant deux colonnes espacées de 6 m (sous les galeries) : bandeau de pierre et filet doré.
static func arcade() -> ModuleBuilder:
	var b := ModuleBuilder.new("arcade")
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(5.0, 5.75, 0.38, 22), 0.6, M("pierre_claire"), 0.06))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(5.0, 5.75, 0.05, 22), 0.64, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0, 0)))
	# clé de voûte
	b.box(Vector3(0.5, 0.7, 0.7), 0.08, "pierre_claire", Vector3(0, 5.75 + 0.1, 0))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.18, 0.6), 0.05, M("etoile_or"), 0.01), ModuleBuilder.at(Vector3(0, 5.85, 0.36)))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.18, 0.6), 0.05, M("etoile_or"), 0.01), ModuleBuilder.at(Vector3(0, 5.85, -0.36), Vector3(0, 180, 0)))
	return b

## Porte en arche numérotée (ouverture 1,5 × 3,0 m), adossée au plan z = 0 : cadre mouluré, imposte lumineuse,
## battant de bois sombre à panneaux dorés, poignée, médaillon du numéro (texte posé par le niveau).
## `wall_backed` : porte d'apparat devant un mur plein ; sinon la porte ferme une ouverture (porte de chambre).
static func porte(id: String, wall_backed: bool) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	var w := 1.5
	var h := 3.0
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(w, h, 0.26, 20), 0.36, M("pierre_claire"), 0.05), ModuleBuilder.at(Vector3(0, 0, 0.1)))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(w + 0.38, h + 0.19, 0.06, 20), 0.4, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.1)))
	b.box(Vector3(w + 0.9, 0.12, 0.5), 0.04, "pierre_sombre", Vector3(0, 0.06, 0.15))
	# médaillon du numéro
	var disc := StyleKit.extrude(_circle(0.24, 24), 0.06, M(GOLD), 0.02)
	b.add(disc, ModuleBuilder.at(Vector3(0, h + 0.55, 0.22)))
	b.add(StyleKit.extrude(_circle(0.19, 24), 0.03, M("pierre_sombre"), 0.0), ModuleBuilder.at(Vector3(0, h + 0.55, 0.26)))
	b.label("", Vector3(0, h + 0.53, 0.285), 72, Color("#ffd98a"))
	(b.extras[0] as Label3D).name = "Numero"
	if wall_backed:
		b.add(StyleKit.extrude(StyleKit.arch_outline(w + 0.1, h + 0.05, 16), 0.1, M("pierre_sombre"), 0.0), ModuleBuilder.at(Vector3(0, 0, -0.02)))
	# battant (pivot à gauche de l'ouverture)
	var pivot := Node3D.new()
	pivot.name = "Battant"
	pivot.position = Vector3(-w * 0.5, 0, 0.06)
	var leaf := ModuleBuilder.new(id + "_battant")
	var lw := w - 0.04
	leaf.add(StyleKit.extrude(StyleKit.arch_outline(lw, h - 0.02, 18), 0.09, M("bois_porte"), 0.025), ModuleBuilder.at(Vector3(lw * 0.5, 0, 0)))
	for side in [1.0, -1.0]:
		var z: float = 0.05 * side
		leaf.add(StyleKit.extrude(StyleKit.arch_frame_outline(lw - 0.36, h - 0.36, 0.035, 16), 0.02, M(GOLD), 0.0), ModuleBuilder.at(Vector3(lw * 0.5, 0.18, z)))
		leaf.add(StyleKit.extrude(_rect(lw - 0.36, 0.035), 0.02, M(GOLD), 0.0), ModuleBuilder.at(Vector3(lw * 0.5, 1.2, z)))
		leaf.add(StyleKit.extrude(StyleKit.star_outline(0.17, 0.07, 4), 0.03, M("etoile_or"), 0.008), ModuleBuilder.at(Vector3(lw * 0.5, 1.75, z * 1.1)))
		# imposte vitrée chaude (demi-disque) avec rayons dorés
		leaf.add(StyleKit.extrude(_half_disc(0.5, 16), 0.02, M("verre_chaud"), 0.0), ModuleBuilder.at(Vector3(lw * 0.5, h - 0.02 - lw * 0.5 + 0.02, z * 1.05)))
		for i in 5:
			var a := 30.0 * (i + 1)
			leaf.add(StyleKit.rounded_box(Vector3(0.5, 0.03, 0.03), 0.01, M(GOLD), 1), ModuleBuilder.at(Vector3(lw * 0.5, h - 0.02 - lw * 0.5 + 0.02, z * 1.2), Vector3(0, 0, a)) * Transform3D(Basis.IDENTITY, Vector3(0.25, 0, 0)))
		leaf.add(StyleKit.sphere(0.055, M(GOLD), 12, 6), ModuleBuilder.at(Vector3(lw - 0.17, 1.15, z * 1.6)))
	var leaf_mesh := StyleKit.merge(leaf.parts)
	var lmi := MeshInstance3D.new()
	lmi.name = "MaillageBattant"
	lmi.mesh = leaf_mesh
	pivot.add_child(lmi)
	var body := StaticBody3D.new()
	body.name = "Collision"
	var cs := CollisionShape3D.new()
	cs.name = "Boite"
	var bs := BoxShape3D.new()
	bs.size = Vector3(lw, h, 0.14)
	cs.shape = bs
	cs.position = Vector3(lw * 0.5, h * 0.5, 0)
	body.add_child(cs)
	pivot.add_child(body)
	b.extras.append(pivot)
	b.collide(Vector3(0.3, h + 0.3, 0.4), Vector3(-w * 0.5 - 0.15, (h + 0.3) * 0.5, 0.15))
	b.collide(Vector3(0.3, h + 0.3, 0.4), Vector3(w * 0.5 + 0.15, (h + 0.3) * 0.5, 0.15))
	b.script_path = "res://scripts/level/hotel_door.gd"
	b.script_props = {"locked": wall_backed}
	return b

## Porte double d'entrée de l'atrium (décor fermé), 3,2 × 4,6 m.
static func porte_double() -> ModuleBuilder:
	var b := ModuleBuilder.new("porte_double_entree")
	var w := 3.2
	var h := 4.6
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(w, h, 0.4, 24), 0.5, M("pierre_claire"), 0.06), ModuleBuilder.at(Vector3(0, 0, 0.15)))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(w + 0.8, h + 0.4, 0.08, 24), 0.55, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.15)))
	b.add(StyleKit.extrude(StyleKit.arch_outline(w, h, 20), 0.12, M("bois_porte"), 0.03), ModuleBuilder.at(Vector3(0, 0, 0.02)))
	b.add(StyleKit.extrude(_rect(0.05, h - 0.4), 0.16, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, (h - 0.4) * 0.5, 0.02)))
	for x in [-0.8, 0.8]:
		b.add(StyleKit.extrude(StyleKit.arch_frame_outline(1.0, 2.6, 0.04, 14), 0.03, M(GOLD), 0.0), ModuleBuilder.at(Vector3(x, 0.4, 0.09)))
		b.add(StyleKit.extrude(StyleKit.star_outline(0.25, 0.1, 8), 0.04, M("etoile_or"), 0.01), ModuleBuilder.at(Vector3(x, 1.9, 0.1)))
		b.add(StyleKit.sphere(0.07, M(GOLD), 12, 6), ModuleBuilder.at(Vector3(x * 0.2, 1.4, 0.12)))
	b.add(StyleKit.extrude(_half_disc(1.6, 24), 0.03, M("verre_chaud"), 0.0), ModuleBuilder.at(Vector3(0, h - 1.6, 0.1)))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.5, 0.6), 0.06, M(GOLD), 0.015), ModuleBuilder.at(Vector3(0, h + 0.75, 0.42)))
	b.collide(Vector3(w + 1.0, h + 0.6, 0.5), Vector3(0, (h + 0.6) * 0.5, 0.1))
	return b

## Applique murale (adossée à z = 0) : platine de laiton, bras, lanterne vitrée chaude, lumière.
static func applique() -> ModuleBuilder:
	var b := ModuleBuilder.new("applique")
	b.box(Vector3(0.2, 0.42, 0.05), 0.02, GOLD, Vector3(0, 0, 0.025))
	b.add(StyleKit.cylinder(0.025, 0.28, M(GOLD), 8), ModuleBuilder.at(Vector3(0, -0.08, 0.03), Vector3(90, 0, 0)))
	b.add(StyleKit.lathe(P([[0.0, -0.25], [0.03, -0.24], [0.085, -0.2], [0.1, -0.12], [0.1, 0.06], [0.085, 0.1]]), 14, M("verre_chaud"), false, true), ModuleBuilder.at(Vector3(0, 0.0, 0.3)))
	b.add(StyleKit.lathe(P([[0.12, 0.08], [0.13, 0.11], [0.06, 0.2], [0.02, 0.25], [0.0, 0.27]]), 14, M(GOLD), true, false), ModuleBuilder.at(Vector3(0, 0.0, 0.3)))
	b.add(StyleKit.torus(0.105, 0.012, M(GOLD), 16, 4), ModuleBuilder.at(Vector3(0, -0.08, 0.3)))
	b.omni(Vector3(0, -0.05, 0.42), Color("#ffb066"), 1.4, 5.5, false, "Lumiere")
	b.cast_shadows = false
	return b

## Lanterne suspendue (sommet de chaîne à y = 0, lanterne 2,2 m plus bas).
static func lanterne() -> ModuleBuilder:
	var b := ModuleBuilder.new("lanterne")
	b.add(StyleKit.cylinder(0.015, 1.8, M(GOLD), 6), ModuleBuilder.at(Vector3(0, -1.8, 0)))
	b.add(StyleKit.torus(0.05, 0.012, M(GOLD), 12, 4), ModuleBuilder.at(Vector3(0, -1.82, 0), Vector3(90, 0, 0)))
	var y := -2.25
	b.add(StyleKit.lathe(P([[0.0, -0.22], [0.12, -0.2], [0.18, -0.08], [0.18, 0.12], [0.12, 0.2]]), 16, M("verre_chaud"), false, true), ModuleBuilder.at(Vector3(0, y, 0)))
	b.add(StyleKit.lathe(P([[0.2, 0.18], [0.21, 0.22], [0.1, 0.34], [0.03, 0.38], [0.0, 0.4]]), 16, M(GOLD), true, false), ModuleBuilder.at(Vector3(0, y, 0)))
	b.add(StyleKit.lathe(P([[0.0, -0.36], [0.05, -0.32], [0.14, -0.22], [0.16, -0.2]]), 16, M(GOLD), false, true), ModuleBuilder.at(Vector3(0, y, 0)))
	for i in 4:
		var a := deg_to_rad(45.0 + 90.0 * i)
		b.add(StyleKit.rounded_box(Vector3(0.025, 0.4, 0.025), 0.01, M(GOLD), 1), ModuleBuilder.at(Vector3(cos(a) * 0.185, y, sin(a) * 0.185)))
	b.add(StyleKit.extrude(StyleKit.star_outline(0.08, 0.035, 4), 0.02, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(0, y - 0.45, 0)))
	b.omni(Vector3(0, y, 0), Color("#ffb066"), 1.6, 7.5, false, "Lumiere")
	b.cast_shadows = false
	return b

## Balustrade : socle, balustres tournés, main courante dorée. Longueur L le long de x, hauteur 1,0 m.
static func balustrade(id: String, L: float) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	b.box(Vector3(L, 0.14, 0.32), 0.04, "pierre_sombre", Vector3(0, 0.07, 0))
	b.box(Vector3(L, 0.1, 0.3), 0.045, GOLD, Vector3(0, 0.98, 0))
	b.box(Vector3(L, 0.06, 0.22), 0.025, "pierre_claire", Vector3(0, 0.9, 0))
	var bal := StyleKit.lathe(P([[0.06, 0.0], [0.075, 0.06], [0.045, 0.16], [0.085, 0.36], [0.05, 0.6], [0.06, 0.66], [0.06, 0.73]]), 8, M("pierre_claire"), false, false)
	var n := int(round(L / 0.32))
	for i in n:
		var x := -L * 0.5 + (i + 0.5) * L / n
		b.add(bal, ModuleBuilder.at(Vector3(x, 0.14, 0)))
	b.collide(Vector3(L, 1.1, 0.3), Vector3(0, 0.55, 0))
	return b

## Grande fenêtre en arche (adossée à z = 0) : paysage nocturne peint par shader dans l'arche, cadre mouluré, meneaux et
## rayons dorés, appui. Pas d'ouverture réelle dans le mur : la vue est un plan émissif juste devant le mur.
static func fenetre(id: String, w: float, h: float, vista: String) -> ModuleBuilder:
	var b := ModuleBuilder.new(id)
	b.add(_arch_plane(w, h, 20, M(vista)), ModuleBuilder.at(Vector3(0, 0, 0.03)))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(w, h, 0.28, 24), 0.5, M("pierre_claire"), 0.06), ModuleBuilder.at(Vector3(0, 0, 0.25)))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(w + 0.56, h + 0.28, 0.06, 24), 0.54, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.25)))
	var spring := h - w * 0.5
	var bar := 0.07
	for x in [-w / 6.0, w / 6.0]:
		b.box(Vector3(bar, spring, bar), 0.02, GOLD, Vector3(x * 1.5, spring * 0.5, 0.12), Vector3.ZERO, 1)
	var rows := int(spring / 1.6)
	for i in range(1, rows + 1):
		var y := spring * float(i) / (rows + 1)
		b.box(Vector3(w, bar, bar), 0.02, GOLD, Vector3(0, y, 0.12), Vector3.ZERO, 1)
	b.box(Vector3(w, bar, bar), 0.02, GOLD, Vector3(0, spring, 0.12), Vector3.ZERO, 1)
	for i in 5:
		var a := 30.0 * (i + 1)
		b.add(StyleKit.rounded_box(Vector3(w * 0.5, bar, bar), 0.02, M(GOLD), 1), Transform3D(Basis(Vector3.BACK, deg_to_rad(a)), Vector3(0, spring, 0.12)) * Transform3D(Basis.IDENTITY, Vector3(w * 0.25, 0, 0)))
	b.add(StyleKit.torus(w * 0.18, 0.04, M(GOLD), 24, 6), ModuleBuilder.at(Vector3(0, spring, 0.12), Vector3(90, 0, 0)))
	b.box(Vector3(w + 0.8, 0.22, 0.55), 0.06, "pierre_claire", Vector3(0, -0.06, 0.27))
	return b

static func banniere() -> ModuleBuilder:
	var b := ModuleBuilder.new("banniere")
	var w := 0.95
	var h := 2.8
	b.add(StyleKit.cylinder(0.035, w + 0.4, M(GOLD), 10), ModuleBuilder.at(Vector3(-(w + 0.4) * 0.5, 0, 0.05), Vector3(0, 0, -90)))
	for x in [-(w + 0.4) * 0.5, (w + 0.4) * 0.5]:
		b.add(StyleKit.sphere(0.06, M(GOLD), 10, 6), ModuleBuilder.at(Vector3(x, 0, 0.05)))
	var cloth := P([[-w * 0.5, 0], [w * 0.5, 0], [w * 0.5, -h + 0.35], [0, -h], [-w * 0.5, -h + 0.35]])
	var border := P([[-w * 0.5 - 0.05, 0], [w * 0.5 + 0.05, 0], [w * 0.5 + 0.05, -h + 0.33], [0, -h - 0.07], [-w * 0.5 - 0.05, -h + 0.33]])
	b.add(StyleKit.extrude(border, 0.025, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, -0.05, 0.03)))
	b.add(StyleKit.extrude(cloth, 0.04, M("banniere"), 0.01), ModuleBuilder.at(Vector3(0, -0.05, 0.05)))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.26, 0.6), 0.03, M("etoile_or"), 0.008), ModuleBuilder.at(Vector3(0, -1.05, 0.08), Vector3(0, 0, 90)))
	b.add(StyleKit.extrude(StyleKit.star_outline(0.11, 0.045, 4), 0.03, M("etoile_or"), 0.008), ModuleBuilder.at(Vector3(0, -1.75, 0.08)))
	b.add(StyleKit.extrude(StyleKit.star_outline(0.06, 0.025, 4), 0.03, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(0.22, -0.6, 0.08)))
	b.cast_shadows = false
	return b

# ================================================================== pièces maîtresses

## Lustre astronomique : lune centrale lumineuse, trois anneaux dorés inclinés portant des planètes (animés),
## pendeloques d'étoiles, chaînes. Origine = point d'attache au plafond ; la lune est 6,5 m plus bas.
static func lustre() -> ModuleBuilder:
	var b := ModuleBuilder.new("lustre_astronomique")
	var cy := -6.5
	for i in 3:
		var a := deg_to_rad(120.0 * i)
		var top := Vector3(cos(a) * 1.6, 0, sin(a) * 1.6)
		var bot := Vector3(cos(a) * 2.7, cy + 0.2, sin(a) * 2.7)
		var d := bot - top
		var basis := Basis(Quaternion(Vector3.UP, d.normalized()))
		b.add(StyleKit.cylinder(0.02, d.length(), M(GOLD), 6), Transform3D(basis, top))
	b.add(StyleKit.cylinder(0.03, -cy - 0.7, M(GOLD), 8), ModuleBuilder.at(Vector3(0, cy + 0.7, 0)))
	b.add(StyleKit.lathe(P([[0.0, -0.1], [0.5, 0.0], [0.25, 0.25], [0.0, 0.3]]), 24, M(GOLD), false, false), ModuleBuilder.at(Vector3.ZERO))
	b.add(StyleKit.sphere(0.75, M("lune"), 28, 14), ModuleBuilder.at(Vector3(0, cy, 0)))
	b.add(StyleKit.torus(0.95, 0.05, M(GOLD), 40, 8), ModuleBuilder.at(Vector3(0, cy, 0)))
	b.add(StyleKit.torus(2.8, 0.06, M(GOLD), 64, 8), ModuleBuilder.at(Vector3(0, cy + 0.2, 0)))
	# pendeloques : étoiles suspendues à l'anneau extérieur
	for i in 12:
		var a := TAU * i / 12.0
		var p := Vector3(cos(a) * 2.8, cy + 0.2, sin(a) * 2.8)
		var drop := 0.5 + 0.35 * float(i % 3)
		b.add(StyleKit.cylinder(0.008, drop, M(GOLD), 4), ModuleBuilder.at(p - Vector3(0, drop, 0)))
		b.add(StyleKit.extrude(StyleKit.star_outline(0.14, 0.055, 5), 0.04, M("etoile_or"), 0.01), Transform3D(Basis(Vector3.UP, a + PI * 0.5), p - Vector3(0, drop + 0.12, 0)))
	# anneaux animés (nœuds séparés)
	var specs := [[2.0, Vector3(70, 0, 15), 5.0, "AnneauA"], [1.55, Vector3(-60, 30, 0), -7.0, "AnneauB"], [2.35, Vector3(20, 0, -75), 3.5, "AnneauC"]]
	for s in specs:
		var R: float = s[0]
		var ring := Node3D.new()
		ring.name = s[3]
		ring.position = Vector3(0, cy, 0)
		ring.rotation_degrees = s[1]
		ring.set_script(load("res://scripts/stylized/rotator.gd"))
		ring.set("axis", Vector3.UP)
		ring.set("degrees_per_second", s[2])
		var rb := ModuleBuilder.new("tmp")
		rb.add(StyleKit.torus(R, 0.035, M(GOLD), 48, 6))
		rb.add(StyleKit.sphere(0.2, M("velours"), 16, 8), ModuleBuilder.at(Vector3(R, 0, 0)))
		rb.add(StyleKit.torus(0.3, 0.02, M(GOLD), 20, 4), ModuleBuilder.at(Vector3(R, 0, 0), Vector3(20, 0, 10)))
		rb.add(StyleKit.sphere(0.13, M("lune"), 14, 7), ModuleBuilder.at(Vector3(-R, 0, 0)))
		rb.add(StyleKit.sphere(0.09, M(GOLD), 12, 6), ModuleBuilder.at(Vector3(0, 0, R)))
		var mi := MeshInstance3D.new()
		mi.name = "Maillage" + String(s[3])
		mi.mesh = StyleKit.merge(rb.parts)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.add_child(mi)
		b.extras.append(ring)
	b.omni(Vector3(0, cy, 0), Color("#ffcf96"), 3.2, 26.0, true, "LumiereLune")
	b.omni(Vector3(0, cy - 2.5, 0), Color("#c8b0ff"), 1.0, 12.0, false, "LueurBasse")
	b.cast_shadows = false
	return b

## Horloge céleste murale (Ø 5,6 m), adossée à z = 0 : cadran étoilé, chiffres romains dorés, anneau des constellations,
## aiguilles (heure réelle). Centre du cadran à l'origine.
static func horloge() -> ModuleBuilder:
	var b := ModuleBuilder.new("horloge_celeste")
	b.add(StyleKit.extrude(_circle(2.8, 64), 0.25, M("pierre_sombre"), 0.06), ModuleBuilder.at(Vector3(0, 0, 0.12)))
	b.add(StyleKit.extrude(_ring(2.8, 2.55, 64), 0.32, M(GOLD), 0.03), ModuleBuilder.at(Vector3(0, 0, 0.14)))
	b.add(StyleKit.extrude(_ring(1.9, 1.84, 48), 0.27, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.14)))
	b.add(StyleKit.extrude(_circle(2.52, 64), 0.02, M("voute_etoilee"), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.26)))
	var numerals := ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
	for i in 12:
		var a := PI * 0.5 - TAU * i / 12.0
		var lb := b.label(numerals[i], Vector3(cos(a) * 2.2, sin(a) * 2.2, 0.3), 120, Color("#ffd27a"), Vector3.ZERO, 0.004)
		lb.outline_size = 8
		lb.outline_modulate = Color("#5a3a10")
		b.add(StyleKit.extrude(StyleKit.star_outline(0.06, 0.025, 4), 0.03, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(cos(a + PI / 12.0) * 2.67, sin(a + PI / 12.0) * 2.67, 0.32)))
	# anneau tournant : croissant et étoiles
	var ring := Node3D.new()
	ring.name = "Anneau"
	ring.position = Vector3(0, 0, 0.29)
	var rb := ModuleBuilder.new("tmp")
	rb.add(StyleKit.extrude(_ring(1.5, 1.46, 40), 0.02, M(GOLD), 0.0))
	rb.add(StyleKit.extrude(StyleKit.crescent_outline(0.32, 0.55), 0.03, M("lune"), 0.0), ModuleBuilder.at(Vector3(0, 1.1, 0)))
	for i in 7:
		var a := TAU * (i + 0.5) / 7.0
		rb.add(StyleKit.extrude(StyleKit.star_outline(0.1, 0.04, 5), 0.03, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(cos(a) * 1.1, sin(a) * 1.1, 0)))
	var rmi := MeshInstance3D.new()
	rmi.name = "MaillageAnneau"
	rmi.mesh = StyleKit.merge(rb.parts)
	ring.add_child(rmi)
	b.extras.append(ring)
	for hand in [["Heures", 1.3, 0.12], ["Minutes", 1.95, 0.08]]:
		var pv := Node3D.new()
		pv.name = hand[0]
		pv.position = Vector3(0, 0, 0.36 if hand[0] == "Minutes" else 0.33)
		var hb := ModuleBuilder.new("tmp")
		var L: float = hand[1]
		var wdt: float = hand[2]
		hb.add(StyleKit.extrude(P([[-wdt * 0.5, -0.25], [wdt * 0.5, -0.25], [wdt * 0.3, L - 0.25], [0, L], [-wdt * 0.3, L - 0.25]]), 0.03, M(GOLD), 0.0))
		hb.add(StyleKit.extrude(StyleKit.star_outline(0.12, 0.05, 4), 0.03, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(0, L * 0.7, 0.02)))
		var hmi := MeshInstance3D.new()
		hmi.name = "Maillage" + String(hand[0])
		hmi.mesh = StyleKit.merge(hb.parts)
		pv.add_child(hmi)
		b.extras.append(pv)
	b.add(StyleKit.sphere(0.14, M(GOLD), 16, 8), ModuleBuilder.at(Vector3(0, 0, 0.38)))
	b.script_path = "res://scripts/stylized/celestial_clock.gd"
	b.omni(Vector3(0, -0.5, 2.5), Color("#ffd29a"), 1.2, 7.0, false, "Eclairage")
	return b

## Comptoir de réception en arc (convexe vers +Z), lampes, sphère armillaire, cloche, registre.
static func reception() -> ModuleBuilder:
	var b := ModuleBuilder.new("bureau_reception")
	var R0 := 2.1
	var R1 := 2.75
	var a0 := 25.0
	var a1 := 155.0
	b.add(_arc_slab(R0, R1, a0, a1, 1.0, M("bois_sombre")), ModuleBuilder.at(Vector3(0, 0.12, 0)))
	b.add(_arc_slab(R0 - 0.05, R1 + 0.08, a0 - 1.0, a1 + 1.0, 0.12, M("pierre_sombre")), ModuleBuilder.at(Vector3(0, 0, 0)))
	b.add(_arc_slab(R0 - 0.1, R1 + 0.15, a0 - 2.0, a1 + 2.0, 0.09, M("pierre_claire")), ModuleBuilder.at(Vector3(0, 1.12, 0)))
	b.add(_arc_slab(R1 - 0.01, R1 + 0.03, a0, a1, 0.05, M(GOLD)), ModuleBuilder.at(Vector3(0, 0.95, 0)))
	b.add(_arc_slab(R1 - 0.01, R1 + 0.03, a0, a1, 0.04, M(GOLD)), ModuleBuilder.at(Vector3(0, 0.22, 0)))
	for ang in [45.0, 70.0, 90.0, 110.0, 135.0]:
		var a := deg_to_rad(ang)
		var p := Vector3(cos(a) * (R1 + 0.02), 0.58, sin(a) * (R1 + 0.02))
		var basis := Basis(Vector3.UP, -a + PI * 0.5)
		var shape := StyleKit.star_outline(0.17, 0.07, 8) if ang == 90.0 else StyleKit.crescent_outline(0.12, 0.55)
		b.add(StyleKit.extrude(shape, 0.04, M("etoile_or"), 0.01), Transform3D(basis, p))
	# lampes à abat-jour
	for ang in [40.0, 140.0]:
		var a := deg_to_rad(ang)
		var p := Vector3(cos(a) * 2.42, 1.17, sin(a) * 2.42)
		b.add(StyleKit.lathe(P([[0.12, 0.0], [0.1, 0.04], [0.025, 0.1], [0.025, 0.45], [0.05, 0.48]]), 12, M(GOLD), true, true), ModuleBuilder.at(p))
		b.add(StyleKit.lathe(P([[0.24, 0.42], [0.16, 0.66], [0.15, 0.68]]), 18, M("verre_chaud"), true, true), ModuleBuilder.at(p))
		b.omni(p + Vector3(0, 0.5, 0), Color("#ffbf7a"), 1.3, 5.0, false)
	# sphère armillaire
	var c := Vector3(0, 1.17, 2.42)
	b.add(StyleKit.lathe(P([[0.16, 0.0], [0.12, 0.05], [0.04, 0.12], [0.03, 0.3]]), 12, M(GOLD)), ModuleBuilder.at(c))
	for rot in [Vector3(0, 0, 0), Vector3(90, 0, 0), Vector3(90, 60, 0), Vector3(23, 0, 0)]:
		b.add(StyleKit.torus(0.26, 0.012, M(GOLD), 28, 4), ModuleBuilder.at(c + Vector3(0, 0.56, 0), rot))
	b.add(StyleKit.sphere(0.08, M("lune"), 12, 6), ModuleBuilder.at(c + Vector3(0, 0.56, 0)))
	# cloche et registre
	b.add(StyleKit.lathe(P([[0.08, 0.0], [0.075, 0.02], [0.05, 0.06], [0.01, 0.1], [0.0, 0.11]]), 14, M(GOLD), true, false), ModuleBuilder.at(Vector3(cos(deg_to_rad(65)) * 2.42, 1.17, sin(deg_to_rad(65)) * 2.42)))
	b.box(Vector3(0.5, 0.06, 0.36), 0.02, "livre_a", Vector3(cos(deg_to_rad(112)) * 2.4, 1.2, sin(deg_to_rad(112)) * 2.4), Vector3(0, -22, 0))
	b.box(Vector3(0.46, 0.015, 0.32), 0.005, "draps", Vector3(cos(deg_to_rad(112)) * 2.4, 1.24, sin(deg_to_rad(112)) * 2.4), Vector3(0, -22, 0))
	for ang in [30.0, 55.0, 80.0, 100.0, 125.0, 150.0]:
		var a := deg_to_rad(ang)
		b.collide(Vector3(0.9, 1.25, 0.7), Vector3(cos(a) * 2.42, 0.62, sin(a) * 2.42), Vector3(0, -ang + 90.0, 0))
	return b

## Grand escalier droit (largeur 3 m, 24 marches de 25 cm : 6 m de haut, 8,4 m de long), montant vers -Z ; balustrades
## inclinées, tapis central. Collision : une rampe lisse sous les nez de marche (déplacement fluide).
static func escalier() -> ModuleBuilder:
	var b := ModuleBuilder.new("escalier_grand")
	var steps := 24
	var rise := 0.25
	var run := 0.35
	var w := 3.0
	b.add(StyleKit.stairs(steps, rise, run, w, M("pierre_claire"), 0.035))
	var H := rise * steps
	var Lz := run * steps
	var slope := sqrt(H * H + Lz * Lz)
	var ang := rad_to_deg(atan2(H, Lz))
	# tapis : bande inclinée posée sur les nez
	b.box(Vector3(1.5, 0.04, slope), 0.02, "velours", Vector3(0, H * 0.5 + 0.13, -Lz * 0.5), Vector3(ang, 0, 0), 1)
	# limons latéraux et mains courantes
	for side in [-1.0, 1.0]:
		var x: float = side * (w * 0.5 + 0.12)
		b.box(Vector3(0.24, 0.5, slope + 0.2), 0.06, "pierre_sombre", Vector3(x, H * 0.5 + 0.05, -Lz * 0.5), Vector3(ang, 0, 0))
		b.box(Vector3(0.14, 0.09, slope + 0.2), 0.04, GOLD, Vector3(x, H * 0.5 + 1.05, -Lz * 0.5), Vector3(ang, 0, 0))
		for i in range(0, steps + 1, 2):
			var y := rise * i + 0.3
			var z := -run * i - 0.1
			b.add(StyleKit.lathe(P([[0.04, 0.0], [0.055, 0.05], [0.03, 0.15], [0.055, 0.35], [0.035, 0.55], [0.04, 0.72]]), 8, M("pierre_claire"), false, false), ModuleBuilder.at(Vector3(x, y, z)))
		for end in [0.0, 1.0]:
			var p := Vector3(x, rise * steps * end + 0.0, -Lz * end)
			b.add(StyleKit.lathe(P([[0.16, 0.0], [0.16, 0.2], [0.11, 0.3], [0.11, 1.05], [0.15, 1.15], [0.15, 1.25]]), 12, M("pierre_claire")), ModuleBuilder.at(p))
			b.add(StyleKit.sphere(0.12, M(GOLD), 14, 7), ModuleBuilder.at(p + Vector3(0, 1.36, 0)))
		b.collide(Vector3(0.3, 1.3, slope), Vector3(x, H * 0.5 + 0.6, -Lz * 0.5), Vector3(ang, 0, 0))
	# rampe de collision : son dessus passe par les nez de marche
	var thick := 0.4
	var n := Vector3(0, cos(deg_to_rad(ang)), sin(deg_to_rad(ang)))
	b.collide(Vector3(w, thick, slope + 0.6), Vector3(0, H * 0.5, -Lz * 0.5) - n * (thick * 0.5) + Vector3(0, 0.02, 0), Vector3(ang, 0, 0))
	return b

# ================================================================== végétal, mobilier d'apparat

## Grappe de glycine suspendue (attache à y = 0, ~1,4 m de long) : trois grappes ondulées, quelques feuilles.
static func glycine() -> ModuleBuilder:
	var b := ModuleBuilder.new("glycine")
	var berry := StyleKit.sphere(1.0, M("glycine"), 8, 5)
	var strands := [[Vector3(0, 0, 0), 1.35, 0.15], [Vector3(0.24, 0.02, 0.1), 1.0, 0.12], [Vector3(-0.22, 0.0, -0.08), 1.15, 0.13],
		[Vector3(0.05, 0.02, -0.25), 0.8, 0.11], [Vector3(-0.1, 0.0, 0.24), 0.95, 0.12]]
	var k := 0
	for s in strands:
		var base: Vector3 = s[0]
		var L: float = s[1]
		var R: float = s[2]
		var n := 9
		for i in n:
			var t := float(i) / (n - 1)
			var r := R * (1.0 - t * 0.7)
			var wob := Vector3(sin(float(i + k) * 1.7) * 0.03, 0, cos(float(i + k) * 2.3) * 0.03)
			b.add(berry, ModuleBuilder.at(base + wob + Vector3(0, -t * L - r, 0), Vector3(0, i * 40.0, 0), Vector3(r, r * 1.15, r)))
		k += 3
	for i in 7:
		var a := TAU * i / 7.0
		b.add(StyleKit.rounded_box(Vector3(0.26, 0.03, 0.1), 0.012, M("feuillage"), 1), ModuleBuilder.at(Vector3(cos(a) * 0.2, -0.03 - 0.05 * (i % 2), sin(a) * 0.2), Vector3(0, -rad_to_deg(a), 25)))
	b.cast_shadows = false
	return b

## Arbre de lune (pièce centrale derrière la réception) : vasque de pierre et d'or, tronc tourné, frondaison mauve lumineuse.
static func arbre() -> ModuleBuilder:
	var b := ModuleBuilder.new("arbre_de_lune")
	b.add(StyleKit.lathe(P([[1.5, 0.0], [1.55, 0.1], [1.45, 0.6], [1.6, 0.75], [1.6, 0.85], [1.4, 0.85]]), 32, M("pierre_claire"), true, true))
	b.add(StyleKit.torus(1.58, 0.06, M(GOLD), 40, 6), ModuleBuilder.at(Vector3(0, 0.8, 0)))
	b.add(StyleKit.cylinder(1.42, 0.82, M("parquet"), 32))
	var trunk := P([[0.32, 0.8], [0.26, 1.3], [0.22, 2.2], [0.24, 2.8], [0.2, 3.2], [0.12, 3.7]])
	b.add(StyleKit.lathe(trunk, 12, M("ecorce"), false, true))
	var branches := [[Vector3(0, 2.6, 0), Vector3(1.2, 1.1, 0.3)], [Vector3(0, 2.9, 0), Vector3(-1.0, 1.0, 0.6)], [Vector3(0, 3.1, 0), Vector3(0.2, 1.0, -1.1)], [Vector3(0, 2.4, 0), Vector3(-0.5, 0.8, -0.9)]]
	for br in branches:
		var d: Vector3 = br[1]
		b.add(StyleKit.lathe(P([[0.12, 0.0], [0.05, d.length()]]), 8, M("ecorce"), false, true), Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), br[0]))
	var blooms := [[Vector3(0, 4.3, 0), 1.25], [Vector3(1.3, 3.8, 0.3), 0.95], [Vector3(-1.1, 3.9, 0.6), 1.0], [Vector3(0.3, 4.0, -1.1), 0.95],
		[Vector3(-0.6, 3.4, -0.9), 0.75], [Vector3(0.9, 4.6, -0.4), 0.8], [Vector3(-0.7, 4.7, 0.2), 0.8], [Vector3(0.5, 3.5, 1.0), 0.7]]
	for bl in blooms:
		b.add(StyleKit.sphere(bl[1], M("fleur_arbre"), 14, 8), ModuleBuilder.at(bl[0], Vector3.ZERO, Vector3(1.0, 0.82, 1.0)))
	# pétales lumineux au sol de la vasque
	for i in 10:
		var a := TAU * i / 10.0 + 0.3
		b.add(StyleKit.sphere(0.07, M("fleur_arbre"), 8, 4), ModuleBuilder.at(Vector3(cos(a) * (0.6 + 0.08 * (i % 3)), 0.85, sin(a) * (0.6 + 0.08 * (i % 3)))))
	b.omni(Vector3(0, 3.6, 0), Color("#c9a0ff"), 1.4, 8.0, false, "Lueur")
	b.collide(Vector3(3.1, 0.9, 3.1), Vector3(0, 0.45, 0))
	return b

static func chariot() -> ModuleBuilder:
	var b := ModuleBuilder.new("chariot_bagages")
	b.box(Vector3(1.3, 0.1, 0.8), 0.04, "bois_sombre", Vector3(0, 0.3, 0))
	b.box(Vector3(1.36, 0.05, 0.86), 0.02, GOLD, Vector3(0, 0.37, 0))
	for x in [-0.62, 0.62]:
		for z in [-0.36, 0.36]:
			b.add(StyleKit.torus(0.12, 0.035, M("fer_sombre"), 16, 6), ModuleBuilder.at(Vector3(x, 0.15, z), Vector3(90, 0, 0)))
		b.add(StyleKit.cylinder(0.035, 1.55, M(GOLD), 10), ModuleBuilder.at(Vector3(x, 0.35, 0)))
	b.add(StyleKit.torus(0.62, 0.035, M(GOLD), 32, 6), ModuleBuilder.at(Vector3(0, 1.9, 0), Vector3(90, 0, 0), Vector3(1, 1, 0.6)))
	var cases := [[Vector3(0.95, 0.42, 0.62), "velours", 0.6], [Vector3(0.8, 0.36, 0.55), "bois_porte", 1.02], [Vector3(0.6, 0.3, 0.46), "banniere", 1.36]]
	for c in cases:
		var s: Vector3 = c[0]
		b.box(s, 0.06, c[1], Vector3(-0.05, float(c[2]), 0), Vector3(0, 6.0 * float(c[2]), 0))
		b.box(Vector3(s.x + 0.02, 0.05, s.z + 0.02), 0.02, GOLD, Vector3(-0.05, float(c[2]), 0), Vector3(0, 6.0 * float(c[2]), 0))
		b.add(StyleKit.torus(0.07, 0.015, M(GOLD), 12, 4), ModuleBuilder.at(Vector3(-0.05, float(c[2]) + s.y * 0.5 + 0.03, 0), Vector3(90, 6.0 * float(c[2]), 0)))
	b.collide(Vector3(1.4, 1.95, 0.9), Vector3(0, 0.98, 0))
	return b

static func table_globe() -> ModuleBuilder:
	var b := ModuleBuilder.new("table_globe")
	b.add(StyleKit.lathe(P([[0.35, 0.0], [0.3, 0.05], [0.07, 0.15], [0.05, 0.7], [0.1, 0.75]]), 18, M(GOLD), true, false))
	b.add(StyleKit.cylinder(0.5, 0.06, M("pierre_sombre"), 28), ModuleBuilder.at(Vector3(0, 0.75, 0)))
	b.add(StyleKit.torus(0.5, 0.025, M(GOLD), 28, 6), ModuleBuilder.at(Vector3(0, 0.81, 0)))
	b.add(StyleKit.lathe(P([[0.1, 0.0], [0.06, 0.06], [0.05, 0.1]]), 12, M(GOLD)), ModuleBuilder.at(Vector3(0, 0.81, 0)))
	b.add(StyleKit.sphere(0.2, M("verre_lune"), 20, 10), ModuleBuilder.at(Vector3(0, 1.08, 0)))
	b.add(StyleKit.torus(0.24, 0.012, M(GOLD), 24, 4), ModuleBuilder.at(Vector3(0, 1.08, 0), Vector3(75, 0, 20)))
	b.omni(Vector3(0, 1.2, 0), Color("#c4b2ff"), 0.9, 3.5, false)
	b.collide(Vector3(1.0, 0.85, 1.0), Vector3(0, 0.42, 0))
	return b

static func banc() -> ModuleBuilder:
	var b := ModuleBuilder.new("banc_velours")
	b.box(Vector3(2.0, 0.22, 0.65), 0.1, "velours", Vector3(0, 0.52, 0), Vector3.ZERO, 3)
	b.box(Vector3(2.06, 0.1, 0.7), 0.04, "bois_sombre", Vector3(0, 0.37, 0))
	for x in [-0.88, 0.88]:
		b.add(StyleKit.lathe(P([[0.06, 0.0], [0.05, 0.1], [0.04, 0.32]]), 10, M(GOLD)), ModuleBuilder.at(Vector3(x, 0, -0.24)))
		b.add(StyleKit.lathe(P([[0.06, 0.0], [0.05, 0.1], [0.04, 0.32]]), 10, M(GOLD)), ModuleBuilder.at(Vector3(x, 0, 0.24)))
	for x in [-0.5, 0.0, 0.5]:
		b.add(StyleKit.sphere(0.02, M(GOLD), 6, 3), ModuleBuilder.at(Vector3(x, 0.635, 0)))
	b.collide(Vector3(2.0, 0.65, 0.7), Vector3(0, 0.33, 0))
	return b

static func jardiniere() -> ModuleBuilder:
	var b := ModuleBuilder.new("jardiniere")
	b.add(StyleKit.lathe(P([[0.3, 0.0], [0.36, 0.1], [0.5, 0.65], [0.55, 0.75], [0.5, 0.78]]), 20, M("pierre_claire"), true, true))
	b.add(StyleKit.torus(0.53, 0.03, M(GOLD), 24, 4), ModuleBuilder.at(Vector3(0, 0.72, 0)))
	var bush := [[Vector3(0, 1.05, 0), 0.42], [Vector3(0.25, 0.95, 0.1), 0.3], [Vector3(-0.22, 0.98, -0.12), 0.32], [Vector3(0.05, 1.35, 0.05), 0.26]]
	for p in bush:
		b.add(StyleKit.sphere(p[1], M("feuillage"), 12, 6), ModuleBuilder.at(p[0]))
	for i in 9:
		var a := TAU * i / 9.0
		b.add(StyleKit.lathe(P([[0.0, 0.0], [0.05, 0.05], [0.03, 0.35], [0.0, 0.4]]), 6, M("glycine"), false, false), ModuleBuilder.at(Vector3(cos(a) * 0.3, 1.1 + 0.15 * (i % 2), sin(a) * 0.3), Vector3(cos(a) * 20.0, 0, sin(a) * 20.0)))
	b.collide(Vector3(1.0, 1.2, 1.0), Vector3(0, 0.6, 0))
	return b

## Panneau indicateur de l'atrium (Chambres, Bibliothèque, Archives, Ascenseurs) : poteau doré et quatre flèches.
static func panneau() -> ModuleBuilder:
	var b := ModuleBuilder.new("panneau_directions")
	b.add(StyleKit.lathe(P([[0.3, 0.0], [0.28, 0.12], [0.12, 0.3], [0.07, 0.35], [0.06, 2.9], [0.09, 3.0]]), 16, M(GOLD), true, true))
	b.add(StyleKit.lathe(P([[0.18, 0.0], [0.24, 0.12], [0.0, 0.4]]), 12, M(GOLD)), ModuleBuilder.at(Vector3(0, 3.0, 0)))
	b.add(StyleKit.extrude(StyleKit.star_outline(0.2, 0.08, 4), 0.05, M("etoile_or"), 0.01), ModuleBuilder.at(Vector3(0, 3.6, 0)))
	var entries := [["Chambres  ›", 2.5, 1.0], ["Bibliothèque", 2.05, -1.0], ["Archives", 1.6, -1.0], ["Ascenseurs", 1.15, 1.0]]
	for e in entries:
		var dir: float = e[2]
		var poly := P([[0.0, -0.17], [1.15, -0.17], [1.38, 0.0], [1.15, 0.17], [0.0, 0.17]])
		var xf := ModuleBuilder.at(Vector3(0.05 * dir, float(e[1]), 0), Vector3(0, 0 if dir > 0 else 180, 0))
		b.add(StyleKit.extrude(poly, 0.06, M("pierre_sombre"), 0.015), xf)
		b.add(StyleKit.extrude(P([[-0.02, -0.2], [1.17, -0.2], [1.42, 0.0], [1.17, 0.2], [-0.02, 0.2]]), 0.04, M(GOLD), 0.0), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, -0.005)))
		for face in [1.0, -1.0]:
			var lb := b.label(e[0], Vector3(0.62 * dir, float(e[1]), 0.036 * face), 56, Color("#ffd98a"), Vector3(0, 0 if face > 0 else 180, 0), 0.0035)
			lb.outline_size = 6
			lb.outline_modulate = Color("#1a1030")
	b.collide(Vector3(0.6, 3.0, 0.6), Vector3(0, 1.5, 0))
	return b

# ================================================================== couloir modulaire

## Travée de couloir (4,5 m de long sur x, intérieur 6 m de large sur z, voûte à 8,5 m) : sol de marbre, murs, pilastres
## aux extrémités, balcons et balustrades à 4,5 m, voûte étoilée, arc doubleau. Les portes, appliques et bannières sont
## posées par le niveau (modules séparés). `open_north` : mur nord percé d'une ouverture en arche (porte de chambre).
static func travee(open_north: bool) -> ModuleBuilder:
	var b := ModuleBuilder.new("travee_couloir_ouverte" if open_north else "travee_couloir")
	var L := 4.5
	var hw := 3.0
	var wall_h := 6.0
	b.box(Vector3(L, 0.4, 2.0 * hw + 1.0), 0.02, "marbre_couloir", Vector3(0, -0.2, 0), Vector3.ZERO, 1)
	for side in [-1.0, 1.0]:
		var z: float = side * (hw + 0.25)
		if open_north and side < 0.0:
			for half in [false, true]:
				var poly := StyleKit.arch_wall_half(L, wall_h, 1.62, 3.08, half, 12)
				b.add(StyleKit.extrude(poly, 0.5, M("mur_couloir"), 0.0), ModuleBuilder.at(Vector3(0, 0, z), Vector3(0, 0, 0)))
		else:
			b.box(Vector3(L, wall_h, 0.5), 0.02, "mur_couloir", Vector3(0, wall_h * 0.5, z), Vector3.ZERO, 1)
		# soubassement et corniche
		b.box(Vector3(L, 1.0, 0.1), 0.03, "pierre_sombre", Vector3(0, 0.5, side * (hw - 0.05)), Vector3.ZERO, 1)
		b.box(Vector3(L, 0.12, 0.16), 0.04, GOLD, Vector3(0, 1.02, side * (hw - 0.06)), Vector3.ZERO, 1)
		# balcon (dalle en encorbellement) et balustrade
		b.box(Vector3(L, 0.35, 1.1), 0.08, "pierre_claire", Vector3(0, 4.45, side * (hw - 0.55)))
		b.box(Vector3(L, 0.06, 1.14), 0.02, GOLD, Vector3(0, 4.25, side * (hw - 0.55)), Vector3.ZERO, 1)
		b.box(Vector3(L, 1.8, 0.1), 0.03, "mur_couloir", Vector3(0, 6.9, side * (hw + 0.05)), Vector3.ZERO, 1)
		b.box(Vector3(L, 0.2, 0.3), 0.06, "pierre_claire", Vector3(0, 7.8, side * (hw - 0.1)))
		# pilastres aux deux extrémités de la travée
		for ex in [-L * 0.5, L * 0.5]:
			b.box(Vector3(0.5, 4.0, 0.3), 0.06, "pierre_claire", Vector3(ex, 2.0, side * (hw - 0.15)))
			b.box(Vector3(0.62, 0.3, 0.4), 0.06, "pierre_claire", Vector3(ex, 3.95, side * (hw - 0.2)))
			b.box(Vector3(0.56, 0.06, 0.36), 0.02, GOLD, Vector3(ex, 3.78, side * (hw - 0.19)), Vector3.ZERO, 1)
		if not (open_north and side < 0.0):
			b.collide(Vector3(L, wall_h + 3.0, 0.5), Vector3(0, (wall_h + 3.0) * 0.5, z))
	if open_north:
		var z := -(hw + 0.25)
		var side_w := (L - 1.62) * 0.5
		b.collide(Vector3(side_w, 9.0, 0.5), Vector3(-L * 0.5 + side_w * 0.5, 4.5, z))
		b.collide(Vector3(side_w, 9.0, 0.5), Vector3(L * 0.5 - side_w * 0.5, 4.5, z))
		b.collide(Vector3(1.62, 9.0 - 3.1, 0.5), Vector3(0, 3.1 + (9.0 - 3.1) * 0.5, z))
	# voûte en berceau (demi-anneau extrudé le long de x)
	var vault := _ring_half(hw + 0.4, hw - 0.05, 22)
	b.add(StyleKit.extrude(vault, L, M("voute_etoilee"), 0.0), Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 7.9, 0)))
	# arc doubleau doré à l'extrémité de la travée
	b.add(StyleKit.extrude(_ring_half(hw - 0.05, hw - 0.3, 22), 0.35, M("pierre_claire"), 0.04), Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(L * 0.5, 7.9, 0)))
	b.add(StyleKit.extrude(_ring_half(hw - 0.29, hw - 0.34, 22), 0.37, M(GOLD), 0.0), Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(L * 0.5, 7.9, 0)))
	b.collide(Vector3(L, 0.4, 2.0 * hw + 1.0), Vector3(0, -0.2, 0))
	b.collide(Vector3(L, 0.4, 2.0 * hw), Vector3(0, 11.2, 0))
	return b

# ================================================================== chambre du rêveur

## Lit à baldaquin du rêveur (2,0 × 2,5 m, tête vers -Z) : colonnes tournées, ciel de lit, rideaux noués, couette étoilée,
## oreillers, tête de lit en arche avec croissant. Le point de coucher (DreamBed) est posé par le niveau.
static func lit() -> ModuleBuilder:
	var b := ModuleBuilder.new("lit_reveur")
	var W := 2.0
	var D := 2.5
	b.box(Vector3(W, 0.3, D), 0.08, "bois_sombre", Vector3(0, 0.3, 0))
	b.box(Vector3(W + 0.04, 0.05, D + 0.04), 0.02, GOLD, Vector3(0, 0.46, 0), Vector3.ZERO, 1)
	b.box(Vector3(W - 0.12, 0.26, D - 0.1), 0.12, "draps", Vector3(0, 0.6, 0.02), Vector3.ZERO, 3)
	b.box(Vector3(W - 0.02, 0.12, D * 0.62), 0.06, "tissu_etoile", Vector3(0, 0.74, D * 0.18), Vector3.ZERO, 3)
	b.box(Vector3(W - 0.0, 0.42, 0.06), 0.03, "tissu_etoile", Vector3(0, 0.55, D * 0.5 - 0.02), Vector3(8, 0, 0))
	for side in [-1.0, 1.0]:
		b.box(Vector3(0.06, 0.4, D * 0.62), 0.03, "tissu_etoile", Vector3(side * (W * 0.5 - 0.01), 0.58, D * 0.18), Vector3(0, 0, side * -6.0))
	b.box(Vector3(W - 0.2, 0.06, 0.28), 0.03, "draps", Vector3(0, 0.81, -D * 0.12), Vector3.ZERO, 2)
	for x in [-0.45, 0.45]:
		b.box(Vector3(0.75, 0.2, 0.45), 0.09, "draps", Vector3(x, 0.84, -D * 0.5 + 0.38), Vector3(-12, 0, 0), 3)
	b.box(Vector3(0.4, 0.4, 0.14), 0.07, "velours", Vector3(0, 0.88, -D * 0.5 + 0.62), Vector3(-25, 0, 0), 3)
	# tête de lit en arche
	b.add(StyleKit.extrude(StyleKit.arch_outline(W - 0.1, 1.9, 18), 0.12, M("bois_porte"), 0.03), ModuleBuilder.at(Vector3(0, 0.3, -D * 0.5 + 0.02)))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(W - 0.45, 1.6, 0.04, 18), 0.14, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0.45, -D * 0.5 + 0.03)))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.22, 0.55), 0.05, M("etoile_or"), 0.01), ModuleBuilder.at(Vector3(0, 1.75, -D * 0.5 + 0.1), Vector3(0, 0, 90)))
	# colonnes, ciel de lit, rideaux
	var H := 2.9
	for x in [-W * 0.5, W * 0.5]:
		for z in [-D * 0.5, D * 0.5]:
			b.add(StyleKit.lathe(P([[0.09, 0.0], [0.08, 0.5], [0.06, 0.65], [0.05, H - 0.2], [0.07, H - 0.1], [0.07, H]]), 12, M("bois_sombre")), ModuleBuilder.at(Vector3(x, 0, z)))
			b.add(StyleKit.sphere(0.07, M(GOLD), 10, 5), ModuleBuilder.at(Vector3(x, H + 0.1, z)))
			var zin: float = z * 0.92
			b.box(Vector3(0.32, H - 0.6, 0.08), 0.04, "velours", Vector3(x * 0.92, (H - 0.6) * 0.5 + 0.55, zin), Vector3(0, 0, 0), 2)
			b.add(StyleKit.torus(0.13, 0.025, M(GOLD), 14, 4), ModuleBuilder.at(Vector3(x * 0.92, 1.35, zin), Vector3(0, 0, 0), Vector3(1, 1.4, 0.6)))
	b.box(Vector3(W + 0.15, 0.16, D + 0.15), 0.05, "bois_sombre", Vector3(0, H, 0))
	b.box(Vector3(W + 0.2, 0.32, 0.05), 0.02, "velours", Vector3(0, H - 0.2, D * 0.5 + 0.08))
	b.box(Vector3(0.05, 0.32, D + 0.2), 0.02, "velours", Vector3(W * 0.5 + 0.08, H - 0.2, 0))
	b.box(Vector3(0.05, 0.32, D + 0.2), 0.02, "velours", Vector3(-W * 0.5 - 0.08, H - 0.2, 0))
	b.box(Vector3(W - 0.05, 0.04, D - 0.05), 0.01, "tissu_etoile", Vector3(0, H - 0.06, 0), Vector3.ZERO, 1)
	b.collide(Vector3(W, 0.72, D), Vector3(0, 0.36, 0))
	b.collide(Vector3(W, 1.9, 0.15), Vector3(0, 1.25, -D * 0.5 + 0.02))
	for x in [-W * 0.5, W * 0.5]:
		for z in [-D * 0.5, D * 0.5]:
			b.collide(Vector3(0.2, H, 0.2), Vector3(x, H * 0.5, z))
	return b

static func chevet() -> ModuleBuilder:
	var b := ModuleBuilder.new("table_chevet")
	b.box(Vector3(0.55, 0.55, 0.45), 0.06, "bois_sombre", Vector3(0, 0.38, 0))
	b.box(Vector3(0.6, 0.05, 0.5), 0.02, GOLD, Vector3(0, 0.67, 0), Vector3.ZERO, 1)
	b.box(Vector3(0.42, 0.18, 0.02), 0.01, "bois_porte", Vector3(0, 0.45, 0.23), Vector3.ZERO, 1)
	b.add(StyleKit.sphere(0.025, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(0, 0.45, 0.25)))
	for x in [-0.22, 0.22]:
		for z in [-0.17, 0.17]:
			b.add(StyleKit.cylinder(0.025, 0.12, M(GOLD), 6), ModuleBuilder.at(Vector3(x, 0, z)))
	b.add(StyleKit.lathe(P([[0.09, 0.0], [0.07, 0.03], [0.02, 0.08], [0.02, 0.3], [0.04, 0.32]]), 12, M(GOLD), true, true), ModuleBuilder.at(Vector3(0.05, 0.69, -0.03)))
	b.add(StyleKit.lathe(P([[0.16, 0.25], [0.1, 0.45], [0.09, 0.46]]), 14, M("verre_chaud"), true, true), ModuleBuilder.at(Vector3(0.05, 0.69, -0.03)))
	b.box(Vector3(0.18, 0.04, 0.24), 0.01, "livre_b", Vector3(-0.14, 0.71, 0.05), Vector3(0, 15, 0), 1)
	b.omni(Vector3(0.05, 1.15, 0.0), Color("#ffbd78"), 1.1, 4.0, false)
	b.collide(Vector3(0.6, 0.7, 0.5), Vector3(0, 0.35, 0))
	return b

static func armoire() -> ModuleBuilder:
	var b := ModuleBuilder.new("armoire")
	b.box(Vector3(1.4, 2.2, 0.62), 0.07, "bois_sombre", Vector3(0, 1.2, 0))
	b.box(Vector3(1.5, 0.16, 0.7), 0.05, "bois_sombre", Vector3(0, 2.35, 0))
	b.box(Vector3(1.52, 0.04, 0.72), 0.02, GOLD, Vector3(0, 2.25, 0), Vector3.ZERO, 1)
	for x in [-0.34, 0.34]:
		b.add(StyleKit.extrude(StyleKit.arch_outline(0.6, 1.95, 14), 0.04, M("bois_porte"), 0.012), ModuleBuilder.at(Vector3(x, 0.15, 0.31)))
		b.add(StyleKit.extrude(StyleKit.arch_frame_outline(0.42, 1.7, 0.025, 14), 0.05, M(GOLD), 0.0), ModuleBuilder.at(Vector3(x, 0.27, 0.32)))
		b.add(StyleKit.extrude(StyleKit.crescent_outline(0.08, 0.55), 0.03, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(x, 1.65, 0.345), Vector3(0, 0, 90)))
		b.add(StyleKit.sphere(0.03, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(x * 0.25, 1.1, 0.35)))
	for x in [-0.6, 0.6]:
		b.add(StyleKit.lathe(P([[0.06, 0.0], [0.04, 0.1]]), 8, M(GOLD)), ModuleBuilder.at(Vector3(x, 0, 0)))
	b.collide(Vector3(1.45, 2.45, 0.66), Vector3(0, 1.22, 0))
	return b

static func bureau_ecriture() -> ModuleBuilder:
	var b := ModuleBuilder.new("bureau_ecriture")
	b.box(Vector3(1.5, 0.07, 0.75), 0.03, "bois_sombre", Vector3(0, 0.78, 0))
	b.box(Vector3(1.4, 0.18, 0.65), 0.04, "bois_sombre", Vector3(0, 0.66, 0))
	for x in [-0.66, 0.66]:
		for z in [-0.3, 0.3]:
			b.add(StyleKit.lathe(P([[0.04, 0.0], [0.035, 0.3], [0.045, 0.45], [0.035, 0.6]]), 8, M("bois_sombre")), ModuleBuilder.at(Vector3(x, 0, z)))
	b.box(Vector3(1.0, 0.45, 0.25), 0.03, "bois_sombre", Vector3(0, 1.04, -0.25))
	for i in 6:
		var mat: String = ["livre_a", "livre_b", "livre_c"][i % 3]
		b.box(Vector3(0.06, 0.26 + 0.03 * (i % 2), 0.18), 0.012, mat, Vector3(-0.38 + i * 0.075, 1.32, -0.25), Vector3.ZERO, 1)
	b.box(Vector3(0.42, 0.02, 0.3), 0.01, "draps", Vector3(0.15, 0.83, 0.1), Vector3(0, -8, 0), 1)
	b.box(Vector3(0.03, 0.03, 0.24), 0.01, "fer_sombre", Vector3(0.45, 0.84, 0.15), Vector3(0, 30, 0), 1)
	# bougeoir et flamme
	b.add(StyleKit.lathe(P([[0.06, 0.0], [0.03, 0.03], [0.02, 0.12], [0.04, 0.13]]), 10, M(GOLD), true, true), ModuleBuilder.at(Vector3(-0.55, 0.815, 0.15)))
	b.add(StyleKit.cylinder(0.02, 0.12, M("draps"), 8), ModuleBuilder.at(Vector3(-0.55, 0.945, 0.15)))
	b.add(StyleKit.lathe(P([[0.0, 0.0], [0.018, 0.02], [0.0, 0.07]]), 8, M("verre_chaud"), false, false), ModuleBuilder.at(Vector3(-0.55, 1.07, 0.15)))
	b.omni(Vector3(-0.55, 1.2, 0.2), Color("#ffb060"), 0.8, 3.0, false)
	b.collide(Vector3(1.5, 0.85, 0.75), Vector3(0, 0.42, 0))
	return b

static func fauteuil() -> ModuleBuilder:
	var b := ModuleBuilder.new("fauteuil")
	b.box(Vector3(0.85, 0.25, 0.8), 0.1, "velours", Vector3(0, 0.42, 0.03), Vector3.ZERO, 3)
	b.box(Vector3(0.85, 0.75, 0.2), 0.1, "velours", Vector3(0, 0.82, -0.32), Vector3(-8, 0, 0), 3)
	for x in [-0.4, 0.4]:
		b.box(Vector3(0.16, 0.38, 0.75), 0.07, "velours", Vector3(x, 0.6, 0.03), Vector3.ZERO, 3)
		for z in [-0.3, 0.3]:
			b.add(StyleKit.cylinder(0.03, 0.3, M(GOLD), 6), ModuleBuilder.at(Vector3(x, 0, z)))
	b.collide(Vector3(0.9, 0.9, 0.85), Vector3(0, 0.45, 0))
	return b

static func tapis() -> ModuleBuilder:
	var b := ModuleBuilder.new("tapis_rond")
	b.add(StyleKit.cylinder(1.7, 0.02, M("tapis"), 48))
	b.add(StyleKit.torus(1.55, 0.025, M(GOLD), 48, 4), ModuleBuilder.at(Vector3(0, 0.02, 0), Vector3.ZERO, Vector3(1, 0.4, 1)))
	b.add(StyleKit.cylinder(0.95, 0.025, M("tissu_etoile"), 40))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.5, 0.55), 0.02, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0.035, 0), Vector3(-90, 0, 0)))
	b.cast_shadows = false
	return b

static func etagere() -> ModuleBuilder:
	var b := ModuleBuilder.new("etagere_livres")
	var W := 1.6
	var H := 2.3
	b.box(Vector3(W, H, 0.08), 0.03, "bois_sombre", Vector3(0, H * 0.5, -0.18), Vector3.ZERO, 1)
	for x in [-W * 0.5, W * 0.5]:
		b.box(Vector3(0.08, H, 0.42), 0.03, "bois_sombre", Vector3(x, H * 0.5, 0))
	var mats := ["livre_a", "livre_b", "livre_c", "velours", "bois_porte"]
	for s in 5:
		var y := 0.1 + s * 0.52
		b.box(Vector3(W, 0.05, 0.42), 0.02, "bois_sombre", Vector3(0, y, 0), Vector3.ZERO, 1)
		if s == 4:
			continue
		var x := -W * 0.5 + 0.1
		var i := 0
		while x < W * 0.5 - 0.15:
			var bw := 0.05 + 0.03 * float((i * 7 + s * 3) % 3)
			var bh := 0.3 + 0.05 * float((i * 5 + s) % 4)
			var tilt := 8.0 if (i + s) % 9 == 4 else 0.0
			b.box(Vector3(bw, bh, 0.3), 0.012, mats[(i + s) % mats.size()], Vector3(x + bw * 0.5, y + 0.025 + bh * 0.5, 0.0), Vector3(0, 0, tilt), 1)
			x += bw + 0.012
			i += 1
	b.box(Vector3(W + 0.12, 0.1, 0.48), 0.03, "bois_sombre", Vector3(0, H + 0.05, 0))
	b.add(StyleKit.extrude(StyleKit.star_outline(0.12, 0.05, 4), 0.03, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(0, H + 0.25, 0.1)))
	b.collide(Vector3(W + 0.1, H + 0.1, 0.45), Vector3(0, (H + 0.1) * 0.5, 0))
	return b

## Mobile d'étoiles au-dessus du lit (attache à y = 0), tourne lentement.
static func mobile() -> ModuleBuilder:
	var b := ModuleBuilder.new("mobile_etoiles")
	b.add(StyleKit.cylinder(0.008, 0.4, M(GOLD), 4), ModuleBuilder.at(Vector3(0, -0.4, 0)))
	var rot := Node3D.new()
	rot.name = "Rotation"
	rot.position = Vector3(0, -0.4, 0)
	rot.set_script(load("res://scripts/stylized/rotator.gd"))
	rot.set("degrees_per_second", 9.0)
	var rb := ModuleBuilder.new("tmp")
	rb.add(StyleKit.torus(0.45, 0.012, M(GOLD), 28, 4))
	for i in 6:
		var a := TAU * i / 6.0
		var drop := 0.25 + 0.15 * float(i % 3)
		rb.add(StyleKit.cylinder(0.004, drop, M(GOLD), 3), ModuleBuilder.at(Vector3(cos(a) * 0.45, -drop, sin(a) * 0.45)))
		var shape := StyleKit.crescent_outline(0.1, 0.55) if i % 3 == 0 else StyleKit.star_outline(0.09, 0.04, 5)
		rb.add(StyleKit.extrude(shape, 0.02, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(cos(a) * 0.45, -drop - 0.09, sin(a) * 0.45), Vector3(0, rad_to_deg(-a), 0)))
	rb.add(StyleKit.sphere(0.07, M("lune"), 12, 6), ModuleBuilder.at(Vector3(0, -0.3, 0)))
	var mi := MeshInstance3D.new()
	mi.name = "MaillageMobile"
	mi.mesh = StyleKit.merge(rb.parts)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rot.add_child(mi)
	b.extras.append(rot)
	return b

# ================================================================== profils utilitaires

static func _circle(r: float, n: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		p.append(Vector2(cos(a), sin(a)) * r)
	return p

## Anneau plein (polygone simple « en C » très fermé : fente invisible de 0,2°).
static func _ring(r_out: float, r_in: float, n: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	var gap := 0.004
	for i in n + 1:
		var a := gap + (TAU - 2.0 * gap) * i / n
		p.append(Vector2(cos(a), sin(a)) * r_out)
	for i in range(n, -1, -1):
		var a := gap + (TAU - 2.0 * gap) * i / n
		p.append(Vector2(cos(a), sin(a)) * r_in)
	return p

## Demi-anneau supérieur (voûtes, arcs doubleaux), centré à l'origine.
static func _ring_half(r_out: float, r_in: float, n: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n + 1:
		var a := PI * i / n
		p.append(Vector2(cos(a), sin(a)) * r_out)
	for i in range(n, -1, -1):
		var a := PI * i / n
		p.append(Vector2(cos(a), sin(a)) * r_in)
	return p

static func _half_disc(r: float, n: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n + 1:
		var a := PI * i / n
		p.append(Vector2(cos(a), sin(a)) * r)
	return p

static func _rect(w: float, h: float) -> PackedVector2Array:
	return P([[-w * 0.5, -h * 0.5], [w * 0.5, -h * 0.5], [w * 0.5, h * 0.5], [-w * 0.5, h * 0.5]])

## Dalle en secteur d'anneau vue de dessus (angles en degrés, mesurés dans le plan XZ depuis +X vers +Z), épaisseur h.
static func _arc_slab(r0: float, r1: float, a0: float, a1: float, h: float, mat: Material, n := 24) -> ArrayMesh:
	var p := PackedVector2Array()
	for i in n + 1:
		var a := deg_to_rad(a0 + (a1 - a0) * i / n)
		p.append(Vector2(cos(a) * r1, -sin(a) * r1))
	for i in range(n, -1, -1):
		var a := deg_to_rad(a0 + (a1 - a0) * i / n)
		p.append(Vector2(cos(a) * r0, -sin(a) * r0))
	var m := StyleKit.extrude(p, h, mat, minf(0.03, h * 0.3))
	# extrusion le long de z → rotation pour que l'épaisseur soit verticale (y local = -z monde)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(m, 0, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, h * 0.5, 0)))
	var out := st.commit()
	out.surface_set_material(0, mat)
	return out

## Plan en arche avec UV normalisées (0..1) pour les paysages peints.
static func _arch_plane(w: float, h: float, seg: int, mat: Material) -> ArrayMesh:
	var poly := StyleKit.arch_outline(w, h, seg)
	var tris := Geometry2D.triangulate_polygon(poly)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, tris.size(), 3):
		for k in [0, 2, 1]:
			var p := poly[tris[i + k]]
			st.set_normal(Vector3(0, 0, 1))
			st.set_uv(Vector2((p.x + w * 0.5) / w, 1.0 - p.y / h))
			st.add_vertex(Vector3(p.x, p.y, 0))
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m
