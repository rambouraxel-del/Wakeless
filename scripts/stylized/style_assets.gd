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
	b.add(StyleKit.extrude(_half_disc(1.6, 24), 0.03, M("lueur_douce"), 0.0), ModuleBuilder.at(Vector3(0, h - 1.6, 0.1)))
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
	b.omni(Vector3(0, -0.05, 0.42), Color("#ffb46a"), 2.0, 7.0, false, "Lumiere")
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
	b.omni(Vector3(0, y, 0), Color("#ffb06a"), 2.6, 9.5, false, "Lumiere")
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
