# La Forêt de la peur — prototype jouable (vertical slice)

**Intention.** Le premier vrai monde onirique. La forêt représente **la peur** : belle et bleue à l'entrée, elle se resserre,
s'assombrit, fait douter (formes, lumières trompeuses, silhouettes qui s'effacent), puis s'ouvre sur une clairière apaisée.
C'est ici que **Star-Faced One** retrouve **la jeune fille** et que leur lien commence : il la rassure, elle le suit,
puis c'est elle qui, dans la clairière, l'apaise à son tour. Pas de monstre : un **danger suggéré**.

Scène : `scenes/levels/foret_de_la_peur.tscn` (préréglage `foret_peur`). L'ancienne `foret_nocturne.tscn` est conservée.
Entrée : on s'endort dans le lit de la chambre 107 → on arrive dans la forêt. Sortie : « Se réveiller » dans la clairière
→ retour sur le lit (`reveil` du Bureau des rêves).

## Langage visuel

- 3D stylisée de la famille du Bureau des rêves et de Star-Faced One : volumes pleins, arrondis, **silhouettes fortes et
  lisibles** (troncs tordus, grosses racines en arche, houppiers en masses), pas de feuillage photo, pas de voxel.
- Palette : bleu nuit, indigo, violet profond, **verts désaturés** (mousse, feuillage), **cyan froid** pour les lueurs
  (champignons, nénuphars, lucioles), **très rares accents chauds** (la jeune fille, la clairière finale).
- Valeurs : sol et sous-bois sombres, troncs en silhouette, ciel et brume plus clairs derrière → profondeur par plans.
- Le **chemin se lit** sans HUD : sol plus clair et tassé, pierres plates, lucioles qui le bordent ; les fausses pistes
  sont plus sombres ou attirent par une lumière trop belle.

## Parcours (≈ 150 m, de l'entrée au sud vers la clairière au nord ; −Z = nord)

| Zone | z (m, indicatif) | Contenu | Émotion |
|---|---|---|---|
| **1. Lisière du rêve** | 0 → −22 | point d'arrivée `depart` devant un **cadre de porte d'hôtel isolé**, envahi de racines (on vient de l'hôtel) ; sous-bois bleu, champignons cyan, lucioles ; premier embranchement doux | émerveillement |
| **2. La jeune fille** | −18 → −28 | elle est assise sur une souche, recroquevillée, près d'une lanterne éteinte. **E « La rassurer »** (geste `comfort`) → elle se lève et devient **guide** : elle avance d'étape en étape devant le joueur (points d'étape posés à la main, déclenchés quand on approche) | tendresse |
| **3. Le marais** | −30 → −62 | eau sombre réfléchissante, brume basse, roseaux, nénuphars lumineux, arbres sur racines-échasses, passerelle de troncs. **Énigme 1 : réveiller trois fleurs-lanternes** autour de l'étang → les **racines se soulèvent** et forment un pont naturel vers la rive nord | curiosité |
| **4. Le bois noir** | −65 → −108 | troncs serrés, lumière qui baisse, brume plus dense, **feux follets trompeurs** vers deux impasses, **silhouettes d'ombre** entre les arbres qui s'effacent quand on approche, la jeune fille reste tout près. **Énigme 2 : la porte de ruine** — une arche ancienne fermée ; activer le **piédestal de lune** (après l'avoir trouvé dans une ruine latérale) ouvre le passage | peur, doute |
| **5. La clairière** | −110 → −140 | ciel ouvert, grande lune, **arbre ancien** doux et lumineux, cercle de pierres, fleurs blanches, lucioles calmes ; la jeune fille s'assoit ; **E « S'asseoir près d'elle »** ; puis la porte « Se réveiller » | apaisement |

Règles : le joueur n'est jamais perdu longtemps (chemin principal toujours visible depuis une impasse), détours courts,
obstacles doux (racines, rochers, eau peu profonde infranchissable bordée de collisions invisibles), aucune chute mortelle
sauf `kill_y` de sécurité. Largeur de chemin ≥ 2,2 m (caméra à la 3e personne).

## Kit organique PROVISOIRE (Sonnet B) — `scripts/stylized/style_assets_foret.gd`

Chaque module : origine au sol, centré, **id stable**, empreinte de collision simple (cylindre / boîte) → remplaçable plus
tard par un modèle Blender sans toucher au niveau. Budget indicatif : ≤ 6 000 triangles par arbre, ≤ 2 000 par plante ou
rocher, ≤ 14 matériaux de forêt au total.

| Famille | Ids |
|---|---|
| Arbres | `arbre_tordu_a`, `arbre_tordu_b`, `arbre_tordu_c` (9–14 m), `arbre_echasses` (racines-échasses de marais), `arbre_mort`, `arbre_ancien` (clairière, ≈ 18 m) |
| Bois au sol | `tronc_couche` (6 m, franchissable par-dessus ou servant de passerelle), `souche`, `racines_arche`, `racines_basses` |
| Pierre | `rocher_a`, `rocher_b`, `rocher_c` (0,6 → 2,5 m, mousse au sommet), `pierres_plates` (chemin), `cercle_pierres` |
| Plantes | `arbuste_a`, `arbuste_b`, `fougere`, `herbes_touffe`, `roseaux`, `champignons_lumineux`, `nenuphars`, `fleurs_blanches` |
| Ruines | `ruine_arche`, `ruine_colonne`, `ruine_mur`, `ruine_porte_lune` (vantaux à pivots `VantailG`/`VantailD`), `piedestal_lune` |
| Mise en scène | `cadre_porte_reve`, `fleur_lanterne` (nœud `Corolle` + lumière éteinte), `pont_racines` (segments à pivot `Racine_N`), `silhouette_ombre`, `jeune_fille_provisoire` (silhouette simple, sans visage détaillé, cape et cheveux, accent chaud discret) |

## Répartition

- **Sonnet A** — terrain, parcours, collisions, gameplay, tests : `tools/authoring/build_foret_peur.gd`, `scripts/level/foret/*`,
  `tests/run_checks_foret.gd`, raccord lit → forêt → réveil (`dream_bed`, `build_bureau_reves.gd` : seulement la cible du lit,
  `app.gd` : touche F2), recette.
- **Sonnet B** — kit organique : `style_assets_foret.gd`, `style_materials_foret.gd`.
- **Sonnet C** — lumière, ciel, brume, eau, sol, particules, captures : `config/lighting.json` (`foret_peur`),
  `style_materials_foret_fx.gd`, nouveaux shaders `materials/stylized/foret_*.gdshader`, `tools/authoring/foret_ambiance.gd`,
  `tools/captures_foret.sh`.

## Contraintes

- Star-Faced One, sa caméra et ses 11 animations : **intouchables**. Éclat : intouchable. Pas de fusion dans `main`.
- Disposition **à la main** (coordonnées explicites dans le script d'édition) ; dispersion de petites plantes permise
  seulement **hors jeu, à l'édition**, déterministe, cuite dans la scène (MultiMesh), jamais au lancement.
- Budget de la scène : ≤ 600 000 triangles, ≤ 40 lumières (≤ 1 à ombres), draw calls surveillés (MultiMesh pour les
  plantes répétées).
- Rendu des captures : logiciel (pas de GPU) ; performances GPU **non mesurables** dans le cloud.
