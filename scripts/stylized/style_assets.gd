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
	return StyleAssetsAtrium.colonne(id, h)
## Pilastre mural (adossé à z = 0, saillie 0,35 m) avec base, chapiteau doré.
static func pilastre(id: String, h: float) -> ModuleBuilder:
	return StyleAssetsAtrium.pilastre(id, h)
## Arc décoratif reliant deux colonnes espacées de 6 m (sous les galeries) : bandeau de pierre et filet doré.
static func arcade() -> ModuleBuilder:
	return StyleAssetsAtrium.arcade()
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
	# chambranle : filet d'or intérieur, socles aux pieds du cadre, clé d'arc
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(w + 0.04, h + 0.02, 0.03, 20), 0.42, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0, 0.1)))
	for sx in [-1.0, 1.0]:
		_cb(b, Vector3(0.28, 0.3, 0.42), "pierre_sombre", Vector3(sx * (w * 0.5 + 0.17), 0.15, 0.12))
		_cb(b, Vector3(0.3, 0.035, 0.38), GOLD, Vector3(sx * (w * 0.5 + 0.17), 0.31, 0.12))
	_cb(b, Vector3(0.2, 0.26, 0.4), "pierre_claire", Vector3(0, h + 0.14, 0.12))
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
		# poignée de laiton à levier (rosace, tige, levier), plaque de propreté et entrée de clé
		var sd: float = signf(side)
		var hx := lw - 0.17
		var rot := Vector3(90 * sd, 0, 0)
		leaf.add(StyleKit.cylinder(0.04, 0.014, M(GOLD), 10), ModuleBuilder.at(Vector3(hx, 1.1, z * 1.0), rot))
		leaf.add(StyleKit.cylinder(0.011, 0.06, M(GOLD), 8), ModuleBuilder.at(Vector3(hx, 1.1, z + sd * 0.012), rot))
		leaf.add(_cube(Vector3(0.14, 0.022, 0.022), M(GOLD)), ModuleBuilder.at(Vector3(hx - 0.05, 1.088, z + sd * 0.07)))
		leaf.add(_cube(Vector3(lw - 0.2, 0.2, 0.016), M(GOLD)), ModuleBuilder.at(Vector3(lw * 0.5, 0.16, z * 1.06)))
		leaf.add(StyleKit.cylinder(0.014, 0.008, M("pierre_sombre"), 8), ModuleBuilder.at(Vector3(hx, 0.98, z * 1.08), rot))
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
	b.add(StyleKit.extrude(_half_disc(1.6, 24), 0.03, M("abat_jour"), 0.0), ModuleBuilder.at(Vector3(0, h - 1.6, 0.1)))
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
	b.omni(Vector3(0, -0.05, 0.42), Color("#ffb066"), 1.5, 4.8, false, "Lumiere")
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
	b.omni(Vector3(0, y, 0), Color("#ffb066"), 2.0, 7.5, false, "Lumiere")
	b.cast_shadows = false
	return b

## Balustrade : socle, balustres tournés, main courante dorée. Longueur L le long de x, hauteur 1,0 m.
static func balustrade(id: String, L: float) -> ModuleBuilder:
	return StyleAssetsAtrium.balustrade(id, L)
## Grande fenêtre en arche (adossée à z = 0) : paysage nocturne peint par shader dans l'arche, cadre mouluré, meneaux et
## rayons dorés, appui. Pas d'ouverture réelle dans le mur : la vue est un plan émissif juste devant le mur.
static func fenetre(id: String, w: float, h: float, vista: String) -> ModuleBuilder:
	return StyleAssetsAtrium.fenetre(id, w, h, vista)
static func banniere() -> ModuleBuilder:
	return StyleAssetsAtrium.banniere()
# ================================================================== pièces maîtresses

## Lustre astronomique : lune centrale lumineuse, trois anneaux dorés inclinés portant des planètes (animés),
## pendeloques d'étoiles, chaînes. Origine = point d'attache au plafond ; la lune est 6,5 m plus bas.
static func lustre() -> ModuleBuilder:
	return StyleAssetsAtrium.lustre()
## Horloge céleste murale (Ø 5,6 m), adossée à z = 0 : cadran étoilé, chiffres romains dorés, anneau des constellations,
## aiguilles (heure réelle). Centre du cadran à l'origine.
static func horloge() -> ModuleBuilder:
	return StyleAssetsAtrium.horloge()
## Comptoir de réception en arc (convexe vers +Z), lampes, sphère armillaire, cloche, registre.
static func reception() -> ModuleBuilder:
	return StyleAssetsAtrium.reception()
## Grand escalier droit (largeur 3 m, 24 marches de 25 cm : 6 m de haut, 8,4 m de long), montant vers -Z ; balustrades
## inclinées, tapis central. Collision : une rampe lisse sous les nez de marche (déplacement fluide).
static func escalier() -> ModuleBuilder:
	return StyleAssetsAtrium.escalier()
# ================================================================== végétal, mobilier d'apparat

## Grappe de glycine suspendue (attache à y = 0, ~1,4 m de long) : trois grappes ondulées, quelques feuilles.
static func glycine() -> ModuleBuilder:
	return StyleAssetsAtrium.glycine()
## Arbre de lune (pièce centrale derrière la réception) : vasque de pierre et d'or, tronc tourné, frondaison mauve lumineuse.
static func arbre() -> ModuleBuilder:
	return StyleAssetsAtrium.arbre()
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
	return StyleAssetsAtrium.jardiniere()
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

# ================================================================== chambre du rêveur

## Console galbée (corbeau) sous un balcon : profil en S extrudé, 0,16 m d'épaisseur ; s'étend de x = 0 (mur) à x = 0,9.
static func _corbel(mat: Material) -> ArrayMesh:
	var poly := P([[0.0, 0.0], [0.9, 0.0], [0.9, -0.05], [0.7, -0.1], [0.5, -0.17], [0.34, -0.3], [0.22, -0.48], [0.1, -0.56], [0.0, -0.58]])
	return StyleKit.extrude(poly, 0.16, mat, 0.025)

## Travée de couloir (4,5 m de long sur x, intérieur 6 m de large sur z, voûte à 8,5 m) : sol de marbre, murs, pilastre à
## l'extrémité +x seulement (le pilastre -x est celui de la travée voisine : deux boîtes confondues faisaient scintiller des
## rayures), soubassement à panneaux moulurés et plinthe, balcons et balustrades à 4,5 m dont la sous-face est travaillée
## (caisson sombre fileté d'or, rosettes, consoles galbées), voûte étoilée, arc doubleau. Les portes, appliques, bannières
## et décors sont posés par le niveau. `open_north` : mur nord percé d'une ouverture en arche (porte de chambre).
static func travee(open_north: bool) -> ModuleBuilder:
	var b := ModuleBuilder.new("travee_couloir_ouverte" if open_north else "travee_couloir")
	var L := 4.5
	var hw := 3.0
	var wall_h := 6.0
	b.box(Vector3(L, 0.4, 2.0 * hw + 1.0), 0.02, "marbre_couloir", Vector3(0, -0.2, 0), Vector3.ZERO, 1)
	var corbel := _corbel(M("bois_sombre"))
	for side in [-1.0, 1.0]:
		var z: float = side * (hw + 0.25)
		if open_north and side < 0.0:
			for half in [false, true]:
				var poly := StyleKit.arch_wall_half(L, wall_h, 1.62, 3.08, half, 12)
				b.add(StyleKit.extrude(poly, 0.5, M("mur_couloir"), 0.0), ModuleBuilder.at(Vector3(0, 0, z), Vector3(0, 0, 0)))
		else:
			b.box(Vector3(L, wall_h, 0.5), 0.02, "mur_couloir", Vector3(0, wall_h * 0.5, z), Vector3.ZERO, 1)
		# soubassement, plinthe, panneaux moulurés de part et d'autre de la porte, cimaise dorée
		b.box(Vector3(L, 1.0, 0.1), 0.03, "pierre_sombre", Vector3(0, 0.5, side * (hw - 0.05)), Vector3.ZERO, 1)
		b.box(Vector3(L, 0.16, 0.1), 0.035, "bois_sombre", Vector3(0, 0.08, side * (hw - 0.15)), Vector3.ZERO, 1)
		b.box(Vector3(L, 0.12, 0.16), 0.04, GOLD, Vector3(0, 1.02, side * (hw - 0.06)), Vector3.ZERO, 1)
		for px in [-1.62, 1.62]:
			var pz: float = side * (hw - 0.115)
			b.box(Vector3(0.58, 0.62, 0.03), 0.02, "bois_porte", Vector3(px, 0.55, pz), Vector3.ZERO, 1)
			for dy in [-0.3, 0.3]:
				_cb(b, Vector3(0.62, 0.016, 0.02), GOLD, Vector3(px, 0.55 + dy, pz - side * 0.004))
			for dx in [-0.3, 0.3]:
				_cb(b, Vector3(0.016, 0.62, 0.02), GOLD, Vector3(px + dx, 0.55, pz - side * 0.004))
		# balcon (dalle en encorbellement) et balustrade
		b.box(Vector3(L, 0.35, 1.1), 0.08, "pierre_claire", Vector3(0, 4.45, side * (hw - 0.55)))
		b.box(Vector3(L, 0.06, 1.14), 0.02, GOLD, Vector3(0, 4.25, side * (hw - 0.55)), Vector3.ZERO, 1)
		# sous-face : caisson sombre, filet d'or, rosettes, consoles galbées
		var zc: float = side * (hw - 0.62)
		b.box(Vector3(L - 1.3, 0.04, 0.66), 0.015, "pierre_sombre", Vector3(0, 4.205, zc), Vector3.ZERO, 1)
		for dz in [-0.34, 0.34]:
			_cb(b, Vector3(L - 1.22, 0.03, 0.03), GOLD, Vector3(0, 4.195, zc + dz))
		for dx in [-(L - 1.3) * 0.5 - 0.02, (L - 1.3) * 0.5 + 0.02]:
			_cb(b, Vector3(0.03, 0.03, 0.72), GOLD, Vector3(dx, 4.195, zc))
		for rx in [-1.0, 0.0, 1.0]:
			b.add(StyleKit.torus(0.09, 0.014, M(GOLD), 12, 4), ModuleBuilder.at(Vector3(rx, 4.19, zc)))
			b.add(StyleKit.sphere(0.04, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(rx, 4.18, zc), Vector3.ZERO, Vector3(1, 0.6, 1)))
		for cx in [-1.15, 1.15]:
			b.add(corbel, ModuleBuilder.at(Vector3(cx, 4.22, side * hw), Vector3(0, 90.0 * side, 0)))
		b.box(Vector3(L, 1.8, 0.1), 0.03, "mur_couloir", Vector3(0, 6.9, side * (hw + 0.05)), Vector3.ZERO, 1)
		b.box(Vector3(L, 0.2, 0.3), 0.06, "pierre_claire", Vector3(0, 7.8, side * (hw - 0.1)))
		# pilastre à l'extrémité +x de la travée
		var ex := L * 0.5
		b.box(Vector3(0.5, 4.0, 0.3), 0.06, "pierre_claire", Vector3(ex, 2.0, side * (hw - 0.15)), Vector3.ZERO, 1)
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

# ================================================================== chambre du rêveur (finition)

## Hauteur de la couette (repère du lit) en un point de la surface : plateau avec léger affaissement au centre, plis doux
## en travers, bords qui retombent sur les côtés et au pied. Même fonction pour la couette et pour les objets posés dessus.
const BED_W := 2.0
const BED_D := 2.5
const DUVET_Y := 0.80

static func _duvet_top(x: float, z: float) -> float:
	var sag := 0.03 * exp(-pow(x / 0.62, 2.0)) * smoothstep(-0.5, 0.2, z) * (1.0 - smoothstep(0.7, 1.15, z))
	var folds := 0.026 * sin(5.2 * z + 0.5) * (1.0 - absf(x) * 0.35) + 0.012 * sin(6.5 * x + 2.2 * z + 0.6)
	var head := 0.07 * (1.0 - smoothstep(0.0, 0.14, z + 0.52))
	return DUVET_Y - sag + folds - head

## Couette qui enveloppe le matelas : grille de points (largeur × longueur), bords roulés puis retombant.
static func _duvet(mat: Material) -> ArrayMesh:
	var hw := BED_W * 0.5 - 0.12
	var R := 0.1
	var drop := 0.3
	var half := []
	for k in 5:
		half.append([hw * float(k) / 5.0, 0.0, 0.0])
	for k in range(0, 4):
		var a := PI * 0.5 * float(k) / 3.0
		half.append([hw + R * sin(a), -R * (1.0 - cos(a)), 0.0])
	for k in range(1, 4):
		half.append([hw + R, -R - drop * float(k) / 3.0, 0.0])
	var side := []
	for h in half:
		side.append(h)
	var us := []
	for k in range(side.size() - 1, 0, -1):
		us.append([-side[k][0], side[k][1]])
	for k in side.size():
		us.append([side[k][0], side[k][1]])
	var z0 := -0.5
	var z1 := BED_D * 0.5 - 0.14
	var vs := []
	for k in 9:
		vs.append([lerpf(z0, z1 - R, float(k) / 8.0), 0.0])
	for k in range(1, 4):
		var a := PI * 0.5 * float(k) / 3.0
		vs.append([z1 - R + R * sin(a), -R * (1.0 - cos(a))])
	for k in range(1, 4):
		vs.append([z1, -R - 0.22 * float(k) / 3.0])
	var P := []
	for u in us:
		var col := []
		for v in vs:
			var x: float = u[0]
			var z: float = v[0]
			var top := _duvet_top(clampf(x, -hw, hw), minf(z, z1 - R))
			col.append(Vector3(x, top + u[1] + v[1], z))
		P.append(col)
	return _grid_mesh(P, mat, true, 0.02)

## Tête de lit sculptée : épaulements en S, sommet bombé (profil de x).
static func _headboard_outline(w: float, h_side: float, h_mid: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2(-w * 0.5, 0.0))
	pts.append(Vector2(w * 0.5, 0.0))
	var n := 20
	for i in n + 1:
		var t := 1.0 - 2.0 * float(i) / n                       # +1 → -1
		var c := pow(maxf(cos(t * PI * 0.5), 0.0), 1.6)
		var ear := 0.06 * exp(-pow((absf(t) - 0.88) / 0.07, 2.0))   # petites oreilles aux épaules
		pts.append(Vector2(t * w * 0.5, h_side + (h_mid - h_side) * c + ear))
	return pts

## Lambrequin festonné : bande qui pend du ciel de lit, bas en festons, ligne dorée. Longueur L le long de x, face +z.
static func _valance(L: float, n: int, mat: String) -> Array:
	var poly := PackedVector2Array()
	poly.append(Vector2(-L * 0.5, 0.0))
	var ws := L / n
	for k in n:
		for i in 7:
			var t := float(i) / 6.0
			poly.append(Vector2(-L * 0.5 + ws * (k + t), -0.2 - 0.17 * sin(PI * t)))
	poly.append(Vector2(L * 0.5, 0.0))
	var body := StyleKit.extrude(poly, 0.05, M(mat), 0.0)
	var low := PackedVector2Array()
	for v in poly:
		low.append(Vector2(v.x * 1.0, v.y - (0.035 if v.y < -0.01 else 0.0)))
	var trim := StyleKit.extrude(low, 0.044, M(GOLD), 0.0)
	return [body, trim]

## Lit à baldaquin du rêveur (2,0 × 2,5 m, tête vers -Z), point focal : tête de lit épaisse sculptée à croissant et filet
## d'or, pied de lit, colonnes tournées, ciel de lit à lambrequin festonné, rideaux lourds retenus par des embrasses, matelas
## arrondi, couette lavande à plis doux et léger affaissement, drap retourné, cinq oreillers et coussins, plaid jeté au pied.
## Hauteur de couchage inchangée (couette à 0,80 m) ; le point de coucher (DreamBed) est posé par le niveau.
static func lit() -> ModuleBuilder:
	var b := ModuleBuilder.new("lit_reveur")
	var W := BED_W
	var D := BED_D
	var H := 2.9
	# cadre, filet d'or, matelas
	b.box(Vector3(W + 0.04, 0.22, D + 0.04), 0.05, "bois_sombre", Vector3(0, 0.31, 0), Vector3.ZERO, 2)
	b.box(Vector3(W + 0.08, 0.035, D + 0.08), 0.015, GOLD, Vector3(0, 0.43, 0), Vector3.ZERO, 1)
	b.box(Vector3(W + 0.1, 0.05, D + 0.1), 0.02, "bois_porte", Vector3(0, 0.19, 0), Vector3.ZERO, 1)
	b.box(Vector3(W - 0.1, 0.31, D - 0.1), 0.12, "lin_creme", Vector3(0, 0.585, 0.0), Vector3.ZERO, 2)
	b.add(_duvet(M("lin_lavande")), Transform3D.IDENTITY)
	# drap retourné (crème) au-dessus de la couette, avec ourlet roulé
	var hwd := W * 0.5 - 0.12
	var sp := []
	for i in 13:
		var col := []
		var x := lerpf(-(hwd - 0.04), hwd - 0.04, float(i) / 12.0)
		for j in 6:
			var z := lerpf(-0.5, -0.22, float(j) / 5.0)
			col.append(Vector3(x, _duvet_top(x, z) + 0.022 + 0.006 * sin(i * 1.7 + j), z))
		sp.append(col)
	b.add(_grid_mesh(sp, M("lin_creme"), true, 0.02))
	b.add(StyleKit.cylinder(0.024, (hwd - 0.04) * 2.0, M("lin_creme"), 10), ModuleBuilder.at(Vector3(hwd - 0.04, _duvet_top(0.0, -0.22) + 0.034, -0.22), Vector3(0, 0, 90)))
	# oreillers et coussins : deux crème adossés, un carré lavande, un rond rose lunaire, un petit étoilé
	var hz := -D * 0.5
	_pillow(b, Vector3(0.78, 0.2, 0.5), "lin_creme", Vector3(-0.47, 0.9, hz + 0.43), Vector3(-24, 4, 0))
	_pillow(b, Vector3(0.78, 0.2, 0.5), "lin_creme", Vector3(0.47, 0.9, hz + 0.43), Vector3(-24, -3, 0))
	_pillow(b, Vector3(0.52, 0.17, 0.5), "lin_lavande", Vector3(-0.3, 0.92, hz + 0.78), Vector3(-34, 10, 0))
	b.add(StyleKit.sphere(0.24, M("fleur_rose"), 16, 8), ModuleBuilder.at(Vector3(0.38, 0.93, hz + 0.8), Vector3(-48, 0, 0), Vector3(1, 1, 0.5)))
	_pillow(b, Vector3(0.34, 0.12, 0.22), "tissu_etoile", Vector3(0.05, 0.99, hz + 0.88), Vector3(-30, -16, 0))
	# plaid jeté au pied, qui retombe sur le côté de la porte
	var pp := []
	var pz := 0.62
	for i in 15:
		var x := lerpf(-0.65, hwd, float(i) / 14.0)
		pp.append(Vector3(x, _duvet_top(x, pz + 0.2) + 0.03, pz))
	var yt := _duvet_top(hwd, pz + 0.2) + 0.03
	for k in range(1, 6):
		var a := PI * 0.5 * float(k) / 5.0
		pp.append(Vector3(hwd + 0.13 * sin(a), yt - 0.13 * (1.0 - cos(a)), pz))
	for k in range(1, 4):
		pp.append(Vector3(hwd + 0.13, yt - 0.13 - 0.2 * float(k) / 3.0, pz))
	b.add(_cloth(pp, Vector3(0, 0, 0.42), 5, M("tissu_etoile"), 0.012, 0.28, 0.02, true))
	# tête de lit épaisse, sculptée : bois, panneau creux, filet d'or, croissant et étoiles
	var hb := _headboard_outline(W + 0.06, 1.62, 2.12)
	var hbz := hz + 0.08
	b.add(StyleKit.extrude(hb, 0.16, M("bois_porte"), 0.02), ModuleBuilder.at(Vector3(0, 0.12, hbz)))
	var inset := Geometry2D.offset_polygon(hb, -0.13, Geometry2D.JOIN_MITER)
	if inset.size() >= 1:
		b.add(StyleKit.extrude(inset[0], 0.17, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0.12, hbz + 0.0)))
		var inset2 := Geometry2D.offset_polygon(hb, -0.16, Geometry2D.JOIN_MITER)
		if inset2.size() >= 1:
			b.add(StyleKit.extrude(inset2[0], 0.178, M("bois_sombre"), 0.012), ModuleBuilder.at(Vector3(0, 0.12, hbz + 0.0)))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.3, 0.55, 14), 0.03, M("etoile_or"), 0.01), ModuleBuilder.at(Vector3(0, 1.62, hbz + 0.09), Vector3(0, 0, 90)))
	for spec in [[-0.5, 1.7, 0.07], [0.5, 1.6, 0.06], [-0.38, 1.38, 0.045], [0.35, 1.45, 0.05]]:
		b.add(StyleKit.extrude(StyleKit.star_outline(spec[2] * 0.7, spec[2] * 0.3, 4), 0.02, M(GOLD), 0.004), ModuleBuilder.at(Vector3(spec[0], spec[1], hbz + 0.09)))
	b.box(Vector3(W + 0.1, 0.1, 0.2), 0.04, "bois_sombre", Vector3(0, 0.62, hbz), Vector3.ZERO, 1)
	# pied de lit : bas panneau galbé
	var fb := _headboard_outline(W + 0.06, 0.74, 0.92)
	b.add(StyleKit.extrude(fb, 0.1, M("bois_porte"), 0.03), ModuleBuilder.at(Vector3(0, 0.12, D * 0.5 - 0.02)))
	var fin := Geometry2D.offset_polygon(fb, -0.1, Geometry2D.JOIN_MITER)
	if fin.size() >= 1:
		b.add(StyleKit.extrude(fin[0], 0.104, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0.12, D * 0.5 - 0.02)))
		var fin2 := Geometry2D.offset_polygon(fb, -0.125, Geometry2D.JOIN_MITER)
		if fin2.size() >= 1:
			b.add(StyleKit.extrude(fin2[0], 0.11, M("bois_sombre"), 0.01), ModuleBuilder.at(Vector3(0, 0.12, D * 0.5 - 0.02)))
	# colonnes tournées, ornements d'or
	var post := [[0.11, 0.0], [0.11, 0.08], [0.075, 0.15], [0.092, 0.25], [0.06, 0.34], [0.072, 0.41], [0.052, 0.5], [0.05, 1.0], [0.062, 1.12], [0.05, 1.24],
		[0.05, 1.9], [0.07, 2.02], [0.046, 2.14], [0.062, 2.26], [0.05, 2.4], [0.05, 2.7], [0.082, 2.78], [0.09, H - 0.12], [0.07, H - 0.06]]
	for x in [-W * 0.5, W * 0.5]:
		for z in [-D * 0.5, D * 0.5]:
			_turn(b, post, "bois_sombre", Vector3(x, 0, z), 10)
			for yy in [0.5, 1.12, 2.02, 2.78]:
				b.add(StyleKit.torus(0.075 if yy < 2.0 else 0.085, 0.011, M(GOLD), 14, 4), ModuleBuilder.at(Vector3(x, yy, z)))
			_turn(b, [[0.0, 0.0], [0.05, 0.025], [0.07, 0.08], [0.045, 0.16], [0.0, 0.22]], GOLD, Vector3(x, H - 0.06, z), 10)
	# ciel de lit : cadre, dessus capitonné, lambrequin festonné et glands
	b.box(Vector3(W + 0.2, 0.12, D + 0.2), 0.05, "bois_sombre", Vector3(0, H, 0), Vector3.ZERO, 1)
	b.box(Vector3(W + 0.22, 0.03, D + 0.22), 0.012, GOLD, Vector3(0, H + 0.075, 0), Vector3.ZERO, 1)
	b.box(Vector3(W - 0.0, 0.07, D - 0.0), 0.03, "rideau_velours", Vector3(0, H + 0.1, 0), Vector3.ZERO, 1)
	b.box(Vector3(W - 0.05, 0.04, D - 0.05), 0.012, "tissu_etoile", Vector3(0, H - 0.08, 0), Vector3.ZERO, 1)
	var vy := H - 0.06
	var sides := [[Vector3(0, vy, D * 0.5 + 0.1), 0.0, W + 0.2], [Vector3(0, vy, -D * 0.5 - 0.1), 180.0, W + 0.2],
		[Vector3(W * 0.5 + 0.1, vy, 0), 90.0, D + 0.2], [Vector3(-W * 0.5 - 0.1, vy, 0), -90.0, D + 0.2]]
	for sd in sides:
		var v2 := _valance(sd[2], 4 if sd[2] < 2.4 else 5, "rideau_velours")
		b.add(v2[0], ModuleBuilder.at(sd[0], Vector3(0, sd[1], 0)))
		if v2[1] != null:
			b.add(v2[1], ModuleBuilder.at(sd[0] + Vector3(0, 0, 0), Vector3(0, sd[1], 0)) * Transform3D(Basis.IDENTITY, Vector3(0, 0, -0.012)))
		var ws: float = sd[2] / (4 if sd[2] < 2.4 else 5)
		for k in range(0, (4 if sd[2] < 2.4 else 5) + 1):
			var lx: float = -sd[2] * 0.5 + ws * k
			var T := ModuleBuilder.at(sd[0], Vector3(0, sd[1], 0)) * Transform3D(Basis.IDENTITY, Vector3(lx, -0.2, 0.05))
			b.add(StyleKit.lathe(P([[0.0, 0.0], [0.016, -0.02], [0.03, -0.09], [0.018, -0.14], [0.0, -0.16]]), 8, M(GOLD), false, false), T)
	# rideaux lourds aux colonnes, retenus par des embrasses (cordon d'or et gland)
	var zc := D * 0.5 + 0.13
	var zh := -D * 0.5 + 0.19
	var curt := [[-W * 0.5 - 0.04, -W * 0.5 + 0.52, zc, true], [W * 0.5 - 0.52, W * 0.5 + 0.04, zc, false],
		[-W * 0.5 - 0.04, -W * 0.5 + 0.38, zh, true], [W * 0.5 - 0.38, W * 0.5 + 0.04, zh, false]]
	for c in curt:
		var cz: float = c[2]
		b.add(_curtain(c[0], c[1], H - 0.22, 0.04, cz, 3, 0.04, M("rideau_velours"), 1.25, 0.34, 0.5, c[3]))
		var ax: float = c[0] if c[3] else c[1]
		var tx: float = ax + (0.1 if c[3] else -0.1)
		b.add(StyleKit.torus(0.085, 0.012, M(GOLD), 12, 4), ModuleBuilder.at(Vector3(tx, 1.25, cz), Vector3(90, 0, 0), Vector3(0.8, 1.0, 1.5)))
		b.add(StyleKit.lathe(P([[0.0, 0.0], [0.014, -0.012], [0.03, -0.05], [0.032, -0.1], [0.02, -0.15], [0.0, -0.17]]), 8, M(GOLD), false, false), ModuleBuilder.at(Vector3(tx - (0.06 if c[3] else -0.06), 1.17, cz + 0.08), Vector3.ZERO, Vector3(0.7, 0.7, 0.7)))
	b.collide(Vector3(W, 0.72, D), Vector3(0, 0.36, 0))
	b.collide(Vector3(W, 1.9, 0.15), Vector3(0, 1.25, -D * 0.5 + 0.02))
	for x in [-W * 0.5, W * 0.5]:
		for z in [-D * 0.5, D * 0.5]:
			b.collide(Vector3(0.2, H, 0.2), Vector3(x, H * 0.5, z))
	return b

## Table de chevet (face +z, plateau à 0,72 m) : caisson à tiroir, pieds tournés, lampe à abat-jour de tissu, réveil arrêté
## (4 h 10), verre d'eau, pile de livres, lunettes. Lumière ambrée dans l'abat-jour.
static func chevet() -> ModuleBuilder:
	var b := ModuleBuilder.new("table_chevet")
	b.box(Vector3(0.5, 0.46, 0.4), 0.05, "bois_sombre", Vector3(0, 0.45, 0), Vector3.ZERO, 1)
	b.box(Vector3(0.6, 0.05, 0.48), 0.022, "bois_porte", Vector3(0, 0.695, 0), Vector3.ZERO, 1)
	b.box(Vector3(0.62, 0.02, 0.5), 0.01, GOLD, Vector3(0, 0.665, 0), Vector3.ZERO, 1)
	b.box(Vector3(0.4, 0.17, 0.02), 0.01, "bois_porte", Vector3(0, 0.56, 0.205), Vector3.ZERO, 1)
	b.box(Vector3(0.4, 0.12, 0.02), 0.01, "pierre_sombre", Vector3(0, 0.37, 0.205), Vector3.ZERO, 1)
	b.add(StyleKit.sphere(0.022, M(GOLD), 10, 5), ModuleBuilder.at(Vector3(0, 0.56, 0.225)))
	b.add(StyleKit.torus(0.034, 0.005, M(GOLD), 14, 4), ModuleBuilder.at(Vector3(0, 0.56, 0.217), Vector3(90, 0, 0)))
	for x in [-0.22, 0.22]:
		for z in [-0.16, 0.16]:
			_turn(b, [[0.04, 0.0], [0.028, 0.05], [0.038, 0.1], [0.03, 0.17], [0.036, 0.22]], "bois_sombre", Vector3(x, 0, z), 8)
			b.add(StyleKit.sphere(0.03, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(x, 0.025, z), Vector3.ZERO, Vector3(1, 0.5, 1)))
	var top := 0.72
	# lampe : pied tourné en laiton, abat-jour de tissu qui s'évase
	var lx := 0.13
	var lz := -0.05
	_turn(b, [[0.09, 0.0], [0.08, 0.025], [0.04, 0.07], [0.024, 0.12], [0.045, 0.17], [0.024, 0.22], [0.02, 0.3]], GOLD, Vector3(lx, top, lz), 14)
	_turn(b, [[0.15, 0.27], [0.1, 0.5]], "abat_jour", Vector3(lx, top, lz), 18, Vector3.ZERO, Vector3.ONE, false, true)
	b.add(StyleKit.torus(0.15, 0.007, M(GOLD), 18, 4), ModuleBuilder.at(Vector3(lx, top + 0.27, lz)))
	b.add(StyleKit.sphere(0.018, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(lx, top + 0.52, lz)))
	# réveil arrêté
	var c := Vector3(-0.17, top + 0.07, 0.09)
	b.add(StyleKit.cylinder(0.06, 0.045, M(GOLD), 18), ModuleBuilder.at(c, Vector3(90, 0, 0)))
	b.add(StyleKit.cylinder(0.05, 0.004, M("lin_creme"), 18), ModuleBuilder.at(c + Vector3(0, 0, 0.044), Vector3(90, 0, 0)))
	for s in [-1.0, 1.0]:
		b.add(StyleKit.sphere(0.02, M(GOLD), 8, 4), ModuleBuilder.at(c + Vector3(s * 0.04, 0.05, 0.02)))
		b.add(StyleKit.sphere(0.011, M(GOLD), 6, 3), ModuleBuilder.at(c + Vector3(s * 0.04, -0.062, 0.0)))
	for spec in [[125.0, 0.028], [60.0, 0.042]]:            # 4 h 10
		var a: float = deg_to_rad(spec[0])
		var l: float = spec[1]
		b.add(_cube(Vector3(0.006, l, 0.003), M("fer_sombre")), ModuleBuilder.at(c + Vector3(sin(a) * l * 0.5, cos(a) * l * 0.5, 0.0485), Vector3(0, 0, -spec[0])))
	# verre d'eau (translucide)
	_turn(b, [[0.026, 0.0], [0.03, 0.09]], "voilage", Vector3(-0.02, top, 0.15), 12, Vector3.ZERO, Vector3.ONE, true, false)
	# pile de livres et lunettes
	_book(b, Vector3(-0.18, top + 0.018, -0.08), Vector3(0.21, 0.036, 0.29), "livre_b", Vector3(0, 12, 0), true)
	_book(b, Vector3(-0.17, top + 0.052, -0.08), Vector3(0.18, 0.03, 0.25), "livre_a", Vector3(0, -9, 0), true)
	_book(b, Vector3(-0.18, top + 0.082, -0.07), Vector3(0.16, 0.026, 0.22), "livre_c", Vector3(0, 7, 0))
	var gy := top + 0.1
	for s in [-1.0, 1.0]:
		b.add(StyleKit.torus(0.019, 0.0025, M(GOLD), 14, 4), ModuleBuilder.at(Vector3(-0.18 + s * 0.023, gy, -0.045), Vector3(8, 0, 0)))
		b.add(_cube(Vector3(0.002, 0.002, 0.075), M(GOLD)), ModuleBuilder.at(Vector3(-0.18 + s * 0.042, gy, -0.085), Vector3(0, s * -4.0, 0)))
	b.add(_cube(Vector3(0.012, 0.002, 0.002), M(GOLD)), ModuleBuilder.at(Vector3(-0.18, gy + 0.004, -0.045)))
	b.omni(Vector3(lx, top + 0.56, lz), Color("#ffb066"), 1.4, 3.5, false)
	b.collide(Vector3(0.6, 0.72, 0.5), Vector3(0, 0.36, 0))
	return b

## Armoire sculptée entrouverte (face +z) : porte gauche fermée, porte droite ouverte sur un manteau et une écharpe,
## valise posée dessus, corniche étagée, pieds boules.
static func armoire() -> ModuleBuilder:
	var b := ModuleBuilder.new("armoire")
	b.box(Vector3(0.72, 2.1, 0.6), 0.05, "bois_sombre", Vector3(-0.35, 1.2, 0), Vector3.ZERO, 1)
	b.box(Vector3(0.7, 2.1, 0.05), 0.02, "bois_sombre", Vector3(0.35, 1.2, -0.275), Vector3.ZERO, 1)
	b.box(Vector3(0.05, 2.1, 0.6), 0.02, "bois_sombre", Vector3(0.675, 1.2, 0), Vector3.ZERO, 1)
	b.box(Vector3(0.7, 0.06, 0.6), 0.02, "bois_sombre", Vector3(0.35, 2.22, 0), Vector3.ZERO, 1)
	b.box(Vector3(0.7, 0.06, 0.6), 0.02, "bois_sombre", Vector3(0.35, 0.2, 0), Vector3.ZERO, 1)
	b.box(Vector3(0.62, 1.96, 0.02), 0.01, "pierre_sombre", Vector3(0.34, 1.2, -0.24), Vector3.ZERO, 1)
	b.box(Vector3(1.48, 0.12, 0.68), 0.04, "bois_sombre", Vector3(0, 0.12, 0), Vector3.ZERO, 1)
	b.box(Vector3(1.52, 0.03, 0.7), 0.012, GOLD, Vector3(0, 0.19, 0), Vector3.ZERO, 1)
	for x in [-0.66, 0.66]:
		for z in [-0.26, 0.26]:
			b.add(StyleKit.sphere(0.055, M(GOLD), 10, 5), ModuleBuilder.at(Vector3(x, 0.035, z), Vector3.ZERO, Vector3(1, 0.7, 1)))
	b.box(Vector3(1.52, 0.1, 0.7), 0.035, "bois_sombre", Vector3(0, 2.3, 0), Vector3.ZERO, 1)
	b.box(Vector3(1.58, 0.07, 0.75), 0.03, "bois_porte", Vector3(0, 2.4, 0), Vector3.ZERO, 1)
	b.box(Vector3(1.6, 0.025, 0.77), 0.01, GOLD, Vector3(0, 2.445, 0), Vector3.ZERO, 1)
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.1, 0.55), 0.04, M("etoile_or"), 0.008), ModuleBuilder.at(Vector3(0, 2.3, 0.355), Vector3(0, 0, 90)))
	b.box(Vector3(1.5, 0.03, 0.04), 0.012, GOLD, Vector3(0, 2.22, 0.33), Vector3.ZERO, 1)
	# porte gauche (fermée)
	b.add(StyleKit.extrude(StyleKit.arch_outline(0.64, 2.0, 14), 0.04, M("bois_porte"), 0.012), ModuleBuilder.at(Vector3(-0.35, 0.18, 0.31)))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(0.44, 1.74, 0.025, 14), 0.05, M(GOLD), 0.0), ModuleBuilder.at(Vector3(-0.35, 0.3, 0.32)))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.075, 0.55), 0.03, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(-0.35, 1.7, 0.345), Vector3(0, 0, 90)))
	b.add(StyleKit.sphere(0.03, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(-0.1, 1.1, 0.35)))
	# porte droite entrouverte (charnière à droite, ouverture ≈ 38°)
	var T := ModuleBuilder.at(Vector3(0.68, 0.0, 0.31), Vector3(0, 38, 0))
	b.add(StyleKit.extrude(StyleKit.arch_outline(0.64, 2.0, 14), 0.04, M("bois_porte"), 0.012), T * Transform3D(Basis.IDENTITY, Vector3(-0.34, 0.18, 0)))
	b.add(StyleKit.extrude(StyleKit.arch_frame_outline(0.44, 1.74, 0.025, 14), 0.05, M(GOLD), 0.0), T * Transform3D(Basis.IDENTITY, Vector3(-0.34, 0.3, 0.01)))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.075, 0.55), 0.03, M("etoile_or"), 0.0), T * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(-0.34, 1.7, 0.035)))
	b.add(StyleKit.sphere(0.03, M(GOLD), 8, 4), T * Transform3D(Basis.IDENTITY, Vector3(-0.58, 1.1, 0.04)))
	# intérieur : tringle, manteau, écharpe
	b.add(StyleKit.cylinder(0.014, 0.62, M(GOLD), 6), ModuleBuilder.at(Vector3(0.03, 1.95, -0.02), Vector3(0, 0, -90)))
	for x in [0.2, 0.46]:
		b.add(StyleKit.torus(0.025, 0.004, M(GOLD), 10, 4), ModuleBuilder.at(Vector3(x, 1.93, -0.02), Vector3(0, 0, 90)))
	b.box(Vector3(0.4, 0.14, 0.1), 0.05, "rideau_velours", Vector3(0.22, 1.86, -0.02), Vector3(0, 0, -6), 2)
	b.box(Vector3(0.36, 1.0, 0.09), 0.04, "rideau_velours", Vector3(0.22, 1.3, -0.02), Vector3(0, 0, 0), 2)
	b.box(Vector3(0.12, 0.7, 0.04), 0.015, "fleur_rose", Vector3(0.5, 1.55, -0.02), Vector3(0, 0, 1.5), 1)
	b.box(Vector3(0.12, 0.05, 0.05), 0.02, "fleur_rose", Vector3(0.5, 1.94, -0.02), Vector3.ZERO, 1)
	# valise posée sur la corniche
	var vy := 2.44
	b.box(Vector3(0.72, 0.26, 0.44), 0.06, "livre_a", Vector3(-0.32, vy + 0.14, 0.0), Vector3(0, 7, 0), 2)
	b.box(Vector3(0.74, 0.02, 0.46), 0.008, GOLD, Vector3(-0.32, vy + 0.14, 0.0), Vector3(0, 7, 0), 1)
	var vt := ModuleBuilder.at(Vector3(-0.32, vy + 0.14, 0.0), Vector3(0, 7, 0))
	for s in [-1.0, 1.0]:
		b.add(StyleKit.rounded_box(Vector3(0.05, 0.28, 0.46), 0.012, M(GOLD), 1), vt * Transform3D(Basis.IDENTITY, Vector3(s * 0.24, 0, 0)))
	b.add(StyleKit.torus(0.07, 0.01, M(GOLD), 12, 4), ModuleBuilder.at(Vector3(-0.32, vy + 0.29, 0.0), Vector3(90, 7, 0), Vector3(1, 1, 0.6)))
	b.collide(Vector3(1.55, 2.45, 0.68), Vector3(0, 1.22, 0))
	b.collide(Vector3(0.5, 2.0, 0.3), Vector3(0.35, 1.2, 0.5))
	return b

## Bureau d'écriture (face +z, plateau à 0,82 m) : sous-main, cahier ouvert, plume dans l'encrier, lettres cachetées,
## bougeoir, petit globe céleste ; casier à livres au fond.
static func bureau_ecriture() -> ModuleBuilder:
	var b := ModuleBuilder.new("bureau_ecriture")
	var ty := 0.82
	b.box(Vector3(1.5, 0.055, 0.76), 0.025, "bois_porte", Vector3(0, 0.79, 0), Vector3.ZERO, 1)
	b.box(Vector3(1.53, 0.02, 0.79), 0.01, GOLD, Vector3(0, 0.757, 0), Vector3.ZERO, 1)
	b.box(Vector3(1.36, 0.2, 0.66), 0.04, "bois_sombre", Vector3(0, 0.65, 0), Vector3.ZERO, 1)
	for x in [-0.34, 0.34]:
		b.box(Vector3(0.52, 0.14, 0.02), 0.01, "bois_porte", Vector3(x, 0.65, 0.335), Vector3.ZERO, 1)
		b.add(StyleKit.sphere(0.02, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(x, 0.65, 0.355)))
	for x in [-0.66, 0.66]:
		for z in [-0.3, 0.3]:
			_turn(b, [[0.04, 0.0], [0.03, 0.12], [0.05, 0.25], [0.03, 0.42], [0.04, 0.56], [0.032, 0.76]], "bois_sombre", Vector3(x, 0, z), 10)
			b.add(StyleKit.torus(0.044, 0.007, M(GOLD), 12, 4), ModuleBuilder.at(Vector3(x, 0.25, z)))
	# sous-main de cuir à filet doré
	_cb(b, Vector3(1.1, 0.004, 0.52), GOLD, Vector3(0, ty + 0.002, 0.07))
	_cb(b, Vector3(1.06, 0.006, 0.48), "banniere", Vector3(0, ty + 0.0035, 0.07))
	# casier du fond
	b.box(Vector3(1.2, 0.07, 0.3), 0.02, "bois_sombre", Vector3(0, 0.855, -0.25), Vector3.ZERO, 1)
	b.box(Vector3(1.2, 0.5, 0.05), 0.02, "bois_sombre", Vector3(0, 1.12, -0.345), Vector3.ZERO, 1)
	for x in [-0.6, 0.6]:
		b.box(Vector3(0.05, 0.5, 0.3), 0.02, "bois_sombre", Vector3(x, 1.12, -0.25), Vector3.ZERO, 1)
	b.box(Vector3(1.2, 0.04, 0.3), 0.015, "bois_sombre", Vector3(0, 1.1, -0.25), Vector3.ZERO, 1)
	b.box(Vector3(1.3, 0.07, 0.34), 0.03, "bois_porte", Vector3(0, 1.395, -0.25), Vector3.ZERO, 1)
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.07, 0.55), 0.03, M("etoile_or"), 0.006), ModuleBuilder.at(Vector3(0, 1.46, -0.25), Vector3(0, 0, 90)))
	var mats := ["livre_a", "livre_b", "livre_c", "bois_porte", "livre_b"]
	for i in 9:
		var hh := 0.2 + 0.03 * float((i * 5) % 4)
		_book(b, Vector3(-0.5 + i * 0.065, 0.875 + hh * 0.5, -0.25), Vector3(0.05, hh, 0.2), "livre_a" if i % 3 == 0 else ("livre_b" if i % 3 == 1 else "livre_c"), Vector3(0, 0, -10.0 if i == 4 else 0.0), i % 2 == 0)
	_book(b, Vector3(0.28, 1.14 + 0.02, -0.25), Vector3(0.24, 0.04, 0.2), "livre_a", Vector3.ZERO, true)
	_book(b, Vector3(0.28, 1.14 + 0.058, -0.25), Vector3(0.2, 0.034, 0.18), "livre_c", Vector3(0, 8, 0))
	# cahier ouvert (deux pages en V), plume et encrier
	_cb(b, Vector3(0.44, 0.012, 0.3), "livre_a", Vector3(-0.18, ty + 0.01, 0.15), Vector3(0, 6, 0))
	for s in [-1.0, 1.0]:
		b.add(_cube(Vector3(0.2, 0.008, 0.27), M("lin_creme")), ModuleBuilder.at(Vector3(-0.18 + s * 0.105, ty + 0.021, 0.15), Vector3(0, 6, s * -3.0)))
	_turn(b, [[0.032, 0.0], [0.034, 0.03], [0.02, 0.05], [0.026, 0.055]], "fer_sombre", Vector3(0.1, ty, 0.2), 10)
	b.add(_cube(Vector3(0.004, 0.004, 0.26), M("lin_creme")), ModuleBuilder.at(Vector3(0.14, ty + 0.12, 0.13), Vector3(-34, 24, 0)))
	b.add(_cube(Vector3(0.026, 0.002, 0.13), M("lin_creme")), ModuleBuilder.at(Vector3(0.155, ty + 0.145, 0.045), Vector3(-34, 24, 0)))
	# lettres, dont une cachetée
	_cb(b, Vector3(0.17, 0.003, 0.12), "lin_creme", Vector3(0.38, ty + 0.011, 0.22), Vector3(0, 14, 0))
	_cb(b, Vector3(0.16, 0.003, 0.11), "draps", Vector3(0.4, ty + 0.014, 0.2), Vector3(0, -9, 0))
	b.add(StyleKit.sphere(0.014, M("fleur_rose"), 8, 4), ModuleBuilder.at(Vector3(0.39, ty + 0.017, 0.2), Vector3.ZERO, Vector3(1, 0.4, 1)))
	# petit globe céleste
	_turn(b, [[0.07, 0.0], [0.05, 0.02], [0.018, 0.05], [0.015, 0.1]], GOLD, Vector3(0.55, ty, -0.02), 12)
	b.add(StyleKit.sphere(0.085, M("banniere"), 16, 8), ModuleBuilder.at(Vector3(0.55, ty + 0.19, -0.02)))
	b.add(StyleKit.torus(0.1, 0.007, M(GOLD), 20, 4), ModuleBuilder.at(Vector3(0.55, ty + 0.19, -0.02), Vector3(23, 0, 32)))
	for i in 5:
		var a := TAU * i / 5.0
		b.add(StyleKit.sphere(0.008, M("etoile_or"), 5, 3), ModuleBuilder.at(Vector3(0.55 + cos(a) * 0.07, ty + 0.19 + sin(a * 2.0) * 0.04, -0.02 + sin(a) * 0.05)))
	# bougeoir
	_turn(b, [[0.065, 0.0], [0.04, 0.02], [0.02, 0.06], [0.03, 0.1], [0.02, 0.14], [0.04, 0.17], [0.04, 0.18]], GOLD, Vector3(-0.58, ty, 0.1), 12)
	b.add(StyleKit.cylinder(0.02, 0.13, M("lin_creme"), 8), ModuleBuilder.at(Vector3(-0.58, ty + 0.18, 0.1)))
	b.add(StyleKit.lathe(P([[0.0, 0.0], [0.016, 0.02], [0.0, 0.07]]), 8, M("verre_chaud"), false, false), ModuleBuilder.at(Vector3(-0.58, ty + 0.31, 0.1)))
	b.omni(Vector3(-0.58, ty + 0.5, 0.15), Color("#ffb066"), 0.9, 3.2, false)
	b.collide(Vector3(1.5, 0.85, 0.76), Vector3(0, 0.42, 0))
	b.collide(Vector3(1.3, 0.6, 0.35), Vector3(0, 1.15, -0.25))
	return b

## Fauteuil de velours à oreilles roulées (face +z) : coussin d'assise, dossier capitonné, accoudoirs en rouleau, pieds
## tournés ; plaid plié sur un accoudoir, livre retourné sur l'assise, petit coussin rose lunaire.
static func fauteuil() -> ModuleBuilder:
	var b := ModuleBuilder.new("fauteuil")
	b.box(Vector3(0.86, 0.16, 0.82), 0.05, "bois_sombre", Vector3(0, 0.3, 0.0), Vector3.ZERO, 1)
	b.box(Vector3(0.88, 0.025, 0.84), 0.012, GOLD, Vector3(0, 0.215, 0.0), Vector3.ZERO, 1)
	b.box(Vector3(0.74, 0.2, 0.74), 0.09, "velours", Vector3(0, 0.48, 0.05), Vector3.ZERO, 3)
	b.box(Vector3(0.84, 0.86, 0.2), 0.1, "velours", Vector3(0, 0.9, -0.35), Vector3(-9, 0, 0), 3)
	for r in 2:
		for c in 3:
			b.add(StyleKit.sphere(0.017, M(GOLD), 6, 3), ModuleBuilder.at(Vector3(-0.2 + c * 0.2, 0.78 + r * 0.2, -0.235 + r * 0.03)))
	for x in [-0.4, 0.4]:
		b.box(Vector3(0.12, 0.4, 0.7), 0.05, "velours", Vector3(x, 0.52, 0.04), Vector3.ZERO, 2)
		b.add(StyleKit.cylinder(0.075, 0.7, M("velours"), 14), ModuleBuilder.at(Vector3(x, 0.74, -0.31), Vector3(90, 0, 0)))
		b.add(StyleKit.sphere(0.076, M("velours"), 12, 6), ModuleBuilder.at(Vector3(x, 0.74, 0.39)))
		for z in [-0.34, 0.34]:
			_turn(b, [[0.035, 0.0], [0.028, 0.06], [0.04, 0.12], [0.03, 0.2]], "bois_sombre", Vector3(x, 0, z), 8)
			b.add(StyleKit.sphere(0.03, M(GOLD), 8, 4), ModuleBuilder.at(Vector3(x, 0.02, z), Vector3.ZERO, Vector3(1, 0.6, 1)))
	# plaid plié sur l'accoudoir droit
	var cols := ["lin_lavande", "fleur_rose", "lin_creme"]
	for i in 3:
		b.box(Vector3(0.2 - i * 0.012, 0.03, 0.46), 0.014, cols[i], Vector3(0.405, 0.835 + i * 0.03, 0.0), Vector3(0, 0, 0), 1)
	# livre retourné sur l'assise, petit coussin
	b.add(_cube(Vector3(0.17, 0.008, 0.22), M("livre_c")), ModuleBuilder.at(Vector3(-0.2, 0.615, 0.12), Vector3(0, 0, 24)))
	b.add(_cube(Vector3(0.17, 0.008, 0.22), M("livre_c")), ModuleBuilder.at(Vector3(-0.04, 0.615, 0.12), Vector3(0, 0, -24)))
	_pillow(b, Vector3(0.36, 0.34, 0.12), "fleur_rose", Vector3(0.14, 0.78, -0.2), Vector3(-24, 18, 0))
	b.collide(Vector3(0.9, 0.95, 0.85), Vector3(0, 0.47, 0.0))
	return b

## Tapis ovale (2,0 × 1,5 m de demi-axes) : champ prune, bande indigo, doubles filets d'or, médaillon de croissant et
## étoiles, franges aux deux bouts. Lames fines superposées à quelques millimètres.
static func tapis() -> ModuleBuilder:
	var b := ModuleBuilder.new("tapis_rond")
	var S := Vector3(1.22, 1.0, 0.9)
	b.add(StyleKit.cylinder(1.7, 0.012, M("banniere"), 56), ModuleBuilder.at(Vector3.ZERO, Vector3.ZERO, S))
	b.add(StyleKit.cylinder(1.58, 0.018, M("tapis_prune"), 56), ModuleBuilder.at(Vector3.ZERO, Vector3.ZERO, S))
	b.add(StyleKit.torus(1.64, 0.012, M(GOLD), 56, 4), ModuleBuilder.at(Vector3(0, 0.018, 0), Vector3.ZERO, Vector3(S.x, 0.5, S.z)))
	b.add(StyleKit.torus(1.5, 0.008, M(GOLD), 56, 4), ModuleBuilder.at(Vector3(0, 0.02, 0), Vector3.ZERO, Vector3(S.x, 0.5, S.z)))
	b.add(StyleKit.cylinder(1.0, 0.024, M("banniere"), 48), ModuleBuilder.at(Vector3.ZERO, Vector3.ZERO, S))
	b.add(StyleKit.cylinder(0.9, 0.028, M("tissu_etoile"), 48), ModuleBuilder.at(Vector3.ZERO, Vector3.ZERO, S))
	b.add(StyleKit.torus(0.95, 0.008, M(GOLD), 48, 4), ModuleBuilder.at(Vector3(0, 0.028, 0), Vector3.ZERO, Vector3(S.x, 0.5, S.z)))
	b.add(StyleKit.extrude(StyleKit.crescent_outline(0.5, 0.55), 0.02, M(GOLD), 0.0), ModuleBuilder.at(Vector3(0, 0.04, 0), Vector3(-90, 0, 0), Vector3(1.0, 1.0, 1.0)))
	# chaîne d'étoiles dorées entre les bandes
	for i in 8:
		var a := TAU * (i + 0.5) / 8.0
		b.add(StyleKit.extrude(StyleKit.star_outline(0.05, 0.02, 4), 0.008, M(GOLD), 0.0), ModuleBuilder.at(Vector3(cos(a) * 1.27 * S.x, 0.032, sin(a) * 1.27 * S.z), Vector3(-90, rad_to_deg(-a), 0)))
	# franges (deux extrémités, selon x)
	for side in [-1.0, 1.0]:
		for i in 17:
			var t := (float(i) / 16.0 - 0.5) * 1.5
			var ex := sqrt(maxf(1.0 - (t / 1.7 / S.z * 1.0) * (t / 1.7 / S.z), 0.0)) * 1.7 * S.x if absf(t) < 1.7 * S.z else 0.0
			if ex > 0.0:
				b.add(StyleKit.cylinder(0.006, 0.07, M("lin_creme"), 4), ModuleBuilder.at(Vector3(side * (ex + 0.01) + side * 0.03, 0.006, t), Vector3(0, 0, -side * 80.0)))
	b.cast_shadows = false
	return b

## Bibliothèque (face +z) : livres de hauteurs variées, certains penchés ou couchés ; coquillage, bocal-lune, plante.
static func etagere() -> ModuleBuilder:
	var b := ModuleBuilder.new("etagere_livres")
	var W := 1.6
	var H := 2.3
	b.box(Vector3(W, H, 0.06), 0.02, "bois_sombre", Vector3(0, H * 0.5, -0.18), Vector3.ZERO, 1)
	for x in [-W * 0.5, W * 0.5]:
		b.box(Vector3(0.08, H, 0.42), 0.03, "bois_sombre", Vector3(x, H * 0.5, 0), Vector3.ZERO, 1)
		b.add(StyleKit.extrude(StyleKit.arch_outline(0.06, 0.12, 6), 0.02, M(GOLD), 0.0), ModuleBuilder.at(Vector3(x, H + 0.1, 0.22), Vector3(0, 0, 0)))
	var mats := ["livre_a", "livre_b", "livre_c", "velours", "bois_porte", "rideau_velours"]
	for s in 5:
		var y := 0.1 + s * 0.52
		b.box(Vector3(W, 0.045, 0.42), 0.02, "bois_sombre", Vector3(0, y, 0), Vector3.ZERO, 1)
		b.box(Vector3(W - 0.08, 0.02, 0.025), 0.008, GOLD, Vector3(0, y, 0.215), Vector3.ZERO, 1)
		if s == 4:
			continue
		var x := -W * 0.5 + 0.08
		var i := 0
		var stop := W * 0.5 - 0.1
		if s == 1:
			stop = 0.1                                          # moitié droite de l'étagère 2 : objets
		if s == 3:
			stop = -0.2
		while x < stop:
			var bw := 0.045 + 0.03 * float((i * 7 + s * 3) % 3)
			var bh := 0.28 + 0.045 * float((i * 5 + s * 2) % 5)
			var lean := (i + s) % 9 == 4
			var rot_z := -13.0 if lean else 0.0
			var cx := x + bw * 0.5 + (0.03 if lean else 0.0)
			_book(b, Vector3(cx, y + 0.0225 + bh * 0.5, 0.0), Vector3(bw, bh, 0.28), mats[(i + s * 2) % mats.size()], Vector3(0, 0, rot_z), (i + s) % 3 == 0)
			x += bw + 0.006 + (0.07 if lean else 0.0)
			i += 1
		if s == 3:
			# livres couchés en pile au bout de la rangée
			for k in 4:
				_book(b, Vector3(0.22, y + 0.0225 + 0.025 + k * 0.05, 0.0), Vector3(0.34 - k * 0.025, 0.045, 0.27), mats[(k + 1) % mats.size()], Vector3(0, [4, -6, 8, -3][k], 0), k % 2 == 0)
			# bocal-lune : verre translucide et petite lune lumineuse
			_turn(b, [[0.07, 0.0], [0.085, 0.07], [0.09, 0.16], [0.07, 0.22], [0.045, 0.25]], "voilage", Vector3(0.62, y + 0.0225, 0.0), 16, Vector3.ZERO, Vector3.ONE, true, false)
			b.add(StyleKit.sphere(0.045, M("lune"), 12, 6), ModuleBuilder.at(Vector3(0.62, y + 0.0225 + 0.11, 0.0)))
			b.add(StyleKit.cylinder(0.05, 0.018, M(GOLD), 12), ModuleBuilder.at(Vector3(0.62, y + 0.0225 + 0.25, 0.0)))
		if s == 1:
			# coquillage en spirale (tores décroissants) et petite plante
			for k in 5:
				var rr := 0.06 - k * 0.009
				b.add(StyleKit.torus(rr, 0.017, M("fleur_rose"), 12, 5), ModuleBuilder.at(Vector3(0.28, y + 0.0225 + 0.02 + k * 0.022, 0.0), Vector3(0, k * 36.0, 0)))
			b.add(StyleKit.sphere(0.026, M("lin_creme"), 8, 4), ModuleBuilder.at(Vector3(0.28, y + 0.0225 + 0.13, 0.0)))
			_turn(b, [[0.05, 0.0], [0.07, 0.04], [0.075, 0.12], [0.06, 0.13]], "pierre_claire", Vector3(0.62, y + 0.0225, 0.02), 14)
			for k in 5:
				var a := TAU * k / 5.0
				b.add(StyleKit.lathe(P([[0.0, 0.0], [0.03, 0.06], [0.0, 0.2]]), 6, M("feuillage"), false, false), ModuleBuilder.at(Vector3(0.62 + cos(a) * 0.035, y + 0.0225 + 0.13, 0.02 + sin(a) * 0.035), Vector3(sin(a) * 28.0, 0, -cos(a) * 28.0), Vector3(1, 1.1 + 0.2 * (k % 2), 0.5)))
	b.box(Vector3(W + 0.12, 0.09, 0.48), 0.035, "bois_sombre", Vector3(0, H + 0.045, 0), Vector3.ZERO, 1)
	b.box(Vector3(W + 0.16, 0.025, 0.5), 0.01, GOLD, Vector3(0, H + 0.1, 0), Vector3.ZERO, 1)
	b.add(StyleKit.extrude(StyleKit.star_outline(0.12, 0.05, 4), 0.03, M("etoile_or"), 0.0), ModuleBuilder.at(Vector3(0, H + 0.26, 0.15)))
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

# ================================================================== helpers de la finition (chambre 107 et couloir)

## Boîte à arêtes vives (12 triangles) pour les petits objets (livres, lettres) : très économe.
static func _cube(size: Vector3, mat: Material) -> ArrayMesh:
	var h := size * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := [[Vector3.RIGHT, Vector3.UP, Vector3.BACK], [Vector3.LEFT, Vector3.UP, Vector3.FORWARD], [Vector3.UP, Vector3.BACK, Vector3.RIGHT],
		[Vector3.DOWN, Vector3.FORWARD, Vector3.RIGHT], [Vector3.BACK, Vector3.UP, Vector3.LEFT], [Vector3.FORWARD, Vector3.UP, Vector3.RIGHT]]
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var c: Vector3 = n * h
		var su: Vector3 = u.abs() * h
		var sv: Vector3 = v.abs() * h
		var q := [c - su - sv, c + su - sv, c + su + sv, c - su + sv]      # u puis v : orientation corrigée ci-dessous
		var geo: Vector3 = (q[1] - q[0]).cross(q[3] - q[0])
		var order := [0, 2, 1, 0, 3, 2] if geo.dot(n) > 0.0 else [0, 1, 2, 0, 2, 3]
		for k in order:
			st.set_normal(n)
			st.set_uv(Vector2(q[k].x + q[k].z, q[k].y))
			st.add_vertex(q[k])
	st.index()
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m

static func _cb(b: ModuleBuilder, size: Vector3, mat: String, pos: Vector3, rot_deg := Vector3.ZERO) -> void:
	b.add(_cube(size, M(mat)), ModuleBuilder.at(pos, rot_deg))

## Quad orienté +z avec UV 0..1 (tableaux, miroirs).
static func _quad(w: float, h: float, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := [Vector3(-w * 0.5, -h * 0.5, 0), Vector3(w * 0.5, -h * 0.5, 0), Vector3(w * 0.5, h * 0.5, 0), Vector3(-w * 0.5, h * 0.5, 0)]
	var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for k in [0, 2, 1, 0, 3, 2]:
		st.set_normal(Vector3(0, 0, 1))
		st.set_uv(uvs[k])
		st.add_vertex(pts[k])
	st.index()
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m

## Maillage à partir d'une grille de points P[i][j] (i le long de u, j le long de v) : normales par différences finies,
## orientées par u × v (inversées si `flip`). Avec `thick` > 0 : seconde nappe décalée vers l'arrière (étoffe visible des deux côtés).
static func _grid_mesh(P: Array, mat: Material, flip := false, thick := 0.0) -> ArrayMesh:
	var ni := P.size()
	var nj: int = (P[0] as Array).size()
	var N := []
	for i in ni:
		var row := []
		for j in nj:
			var du: Vector3 = P[mini(i + 1, ni - 1)][j] - P[maxi(i - 1, 0)][j]
			var dv: Vector3 = P[i][mini(j + 1, nj - 1)] - P[i][maxi(j - 1, 0)]
			var n := du.cross(dv).normalized()
			row.append(-n if flip else n)
		N.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for back in ([false, true] if thick > 0.0 else [false]):
		for i in ni - 1:
			for j in nj - 1:
				var idx := [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]
				var order := [0, 1, 2, 0, 2, 3] if (back != flip) else [0, 2, 1, 0, 3, 2]
				for k in order:
					var a: int = idx[k][0]
					var c: int = idx[k][1]
					var n: Vector3 = N[a][c]
					st.set_normal(-n if back else n)
					st.set_uv(Vector2(float(a) / (ni - 1), float(c) / (nj - 1)))
					st.add_vertex(P[a][c] - (n * thick if back else Vector3.ZERO))
	st.index()
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m

## Rideau plissé : nappe verticale ondulée de x0 à x1, de ytop à ybot, vers le plan z = z0 (face visible vers +z).
## `anchor` : bord (x0 ou x1) où le rideau est retenu ; `tie_y` : hauteur de l'embrasse (< 0 : rideau droit) ; `tie_w` : fraction
## de largeur à l'embrasse ; `flare` : évasement au bas ; `amp` : profondeur des plis.
static func _curtain(x0: float, x1: float, ytop: float, ybot: float, z0: float, pleats: int, amp: float, mat: Material,
		tie_y := -1.0, tie_w := 0.4, flare := 0.0, anchor_left := true, thick := 0.012) -> ArrayMesh:
	var nx := pleats * 3 + 1
	var ny := 9
	var anchor := x0 if anchor_left else x1
	var P := []
	for i in nx:
		var t := float(i) / (nx - 1)
		var col := []
		for j in ny:
			var tv := float(j) / (ny - 1)
			var y := lerpf(ytop, ybot, tv)
			var fac := 1.0
			var amp_k := 1.0
			if tie_y > 0.0:
				var d := (y - tie_y)
				if d > 0.0:                                   # au-dessus de l'embrasse : s'évase doucement vers la tringle
					fac = lerpf(tie_w, 1.0, smoothstep(0.0, ytop - tie_y, d))
				else:
					fac = lerpf(tie_w, 1.0 + flare, smoothstep(0.0, tie_y - ybot, -d))
				amp_k = 1.0 + (1.0 - fac) * 0.9
			var x := lerpf(x0, x1, t)
			x = anchor + (x - anchor) * fac
			var phase := TAU * pleats * t
			var z := z0 + amp * amp_k * sin(phase) * (0.75 + 0.25 * sin(tv * 7.0 + t * 5.0))
			# lourdeur : légère retombée en vague au bas
			if tv > 0.88:
				z += (tv - 0.88) * 0.25 * sin(phase * 0.5)
			col.append(Vector3(x, y, z))
		P.append(col)
	return _grid_mesh(P, mat, true, thick)

## Ruban d'étoffe : suit un chemin (points Vector3) et s'étend sur `ext` (vecteur) ; ondulation `wave` de période `period`
## le long du chemin. Pour plaids, draps retournés, couvre-pieds. `rows` lignes le long de `ext`.
static func _cloth(path: Array, ext: Vector3, rows: int, mat: Material, wave := 0.0, period := 0.3, thick := 0.012, flip := false) -> ArrayMesh:
	var P := []
	var s := 0.0
	for i in path.size():
		if i > 0:
			s += (path[i] as Vector3).distance_to(path[i - 1])
		var col := []
		var tan: Vector3 = (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var nrm := tan.cross(ext.normalized()).normalized()
		for j in rows + 1:
			var tv := float(j) / rows
			var edge := sin(PI * tv)
			var off := wave * sin(TAU * s / period + tv * 2.0) * (0.35 + 0.65 * edge)
			col.append((path[i] as Vector3) + ext * tv + nrm * off)
		P.append(col)
	return _grid_mesh(P, mat, flip, thick)

static func _pillow(b: ModuleBuilder, size: Vector3, mat: String, pos: Vector3, rot_deg := Vector3.ZERO) -> void:
	b.add(StyleKit.rounded_box(size, minf(size.y, size.z) * 0.46, M(mat), 2), ModuleBuilder.at(pos, rot_deg))

## Livre debout ou couché (couverture + filet doré sur la tranche), taille (largeur, hauteur, profondeur).
static func _book(b: ModuleBuilder, pos: Vector3, size: Vector3, mat: String, rot_deg := Vector3.ZERO, band := false) -> void:
	b.add(_cube(size, M(mat)), ModuleBuilder.at(pos, rot_deg))
	if band:
		var t := ModuleBuilder.at(pos, rot_deg)
		b.add(_cube(Vector3(size.x + 0.002, size.y * 0.07, size.z + 0.002), M(GOLD)), t * Transform3D(Basis.IDENTITY, Vector3(0, size.y * 0.25, 0)))

## Cadre rectangulaire doré (4 baguettes) avec toile. Face +z. `canvas` : matériau de la toile (nul : pas de toile).
static func _frame(b: ModuleBuilder, w: float, h: float, band: float, depth: float, pos: Vector3, rot_deg := Vector3.ZERO, canvas := "tableau_nuit") -> void:
	var T := ModuleBuilder.at(pos, rot_deg)
	for spec in [[Vector3(w, band, depth), Vector3(0, (h - band) * 0.5, 0)], [Vector3(w, band, depth), Vector3(0, -(h - band) * 0.5, 0)],
			[Vector3(band, h - band * 2.0, depth), Vector3(-(w - band) * 0.5, 0, 0)], [Vector3(band, h - band * 2.0, depth), Vector3((w - band) * 0.5, 0, 0)]]:
		b.add(StyleKit.rounded_box(spec[0], minf(band, depth) * 0.4, M(GOLD), 1), T * Transform3D(Basis.IDENTITY, spec[1]))
	# filet intérieur sombre et toile
	b.add(_cube(Vector3(w - band * 1.6, h - band * 1.6, depth * 0.3), M("pierre_sombre")), T * Transform3D(Basis.IDENTITY, Vector3(0, 0, -depth * 0.1)))
	if canvas != "":
		b.add(_quad(w - band * 2.0 - 0.02, h - band * 2.0 - 0.02, M(canvas)), T * Transform3D(Basis.IDENTITY, Vector3(0, 0, depth * 0.05 + 0.002)))

## Pièce tournée générique : profil [(rayon, y)…] posé en pos.
static func _turn(b: ModuleBuilder, prof: Array, mat: String, pos: Vector3, segs := 12, rot_deg := Vector3.ZERO, scale := Vector3.ONE, cap_b := true, cap_t := true) -> void:
	b.add(StyleKit.lathe(P(prof), segs, M(mat), cap_b, cap_t), ModuleBuilder.at(pos, rot_deg, scale))

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
