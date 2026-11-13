# Validation

## Finition esthétique du Bureau des rêves (branche `claude/bureau-des-reves-finition`)

Même environnement (Claude Code Cloud, **sans carte graphique**, Godot 4.3-stable). Commande : `tools/check.sh`.

| Contrôle | Résultat |
|---|---|
| Compilation des scripts | 74 / 74 |
| Socle (`tests/run_checks.gd`, dont Star-Faced One) | **189 / 189** |
| Bureau des rêves (`tests/run_checks_bureau.gd` : modules, matériaux partagés, structure, budgets, parcours joué : escaliers, galeries, balustrades, couloir, portes, porte 107, lit) | **547 / 547** |
| Finition chambre 107 et couloir (`tests/run_checks_finition_b.gd` : objets, lit, portes, matériaux) | **36 / 36** |
| Recette jouée (chambre 107 → lit → forêt → réveil sur le lit → pause → sauvegarde → F4) | **22 / 22** |

| Mesure (secteur entier) | Avant (9cd3f4a) | Après |
|---|---|---|
| Triangles | 577 662 | 855 918 (plafond du test : 900 000) |
| Lumières | 66 | 76 (1 seule avec ombres) |
| Matériaux partagés des modules | 32 | 40 (plafond : 40) |
| Rendu A01 atrium (objets / primitives / appels de dessin, rendu logiciel) | 653 / 481 837 / 653 (vue de jeu) | 983 / 1 078 345 / 983 |
| Rendu B02 couloir · C02 chambre · D01 joueur | — | 1066 / 864 990 / 1066 · 406 / 222 608 / 406 · 738 / 908 218 / 738 |

**Non vérifié** : images par seconde et rendu GPU Forward+ (SSR du marbre, clustered lighting) — aucune carte graphique
dans le cloud. Les captures (`docs/captures/finition/INDEX.md`) sont en rendu logiciel « Compatibilité » (8 lumières max par
objet, sans SSR/SSAO). Le nombre d'appels de dessin (~1 000 dans l'atrium) est à surveiller sur Mac (touche F3).

## Bureau des rêves en 3D stylisée (branche `claude/bureau-des-reves-3d`)

Environnement : Claude Code Cloud, Linux **sans carte graphique**, Godot **4.3-stable** (headless pour les tests ; rendu
logiciel OpenGL « Compatibilité » sous Xvfb pour les captures). Commande : `tools/check.sh`.

| Contrôle | Résultat |
|---|---|
| Import du projet | aucune erreur |
| Compilation des scripts (`tools/check_scripts.gd`) | 68 / 68 |
| Socle (`tests/run_checks.gd` : voxel, assets, références, niveaux dont le nouveau, gardien Star-Faced One) | **189 / 189** |
| Bureau des rêves (`tests/run_checks_bureau.gd`) | **325 / 325** |
| Recette du jeu complet (`tests/recette_transition.gd`, autoload `App`) | **22 / 22** |

**`run_checks_bureau.gd`** : 35 modules (scène, maillage, chaque surface sur un matériau partagé, ≤ 16 000 triangles), ≤ 40
matériaux, orientation des faces du kit ; niveau (scène de démarrage, arrivées, aucune structure voxel, pièces maîtresses,
23 portes numérotées uniques dont une seule ouvrable, lit → forêt, forêt → réveil) ; budgets (577 662 triangles pour tout le
secteur, 66 lumières, 1 seule à ombres). **Parcours joué avec la vraie physique** et Star-Faced One : arrivée au sol dans
l'atrium, le comptoir bloque, **montée de l'escalier ouest jusqu'à la galerie (6 m)**, traversée de la galerie nord puis est
jusqu'au fond, la balustrade retient le joueur, descente de l'escalier est, passage de l'arche, **couloir de 36 m en entier**,
mur du fond et murs latéraux, porte 101 (verrouillée : message, aucun geste), **porte 107 ouverte (geste interact)**, entrée dans
la chambre, **lit visé « Se coucher et rêver » : couché sur le lit, commandes gelées, geste sleep**.

**Recette** : démarrage dans l'atrium → E sur la porte 107 → E sur le lit → la forêt se charge (scène distincte, l'hôtel est
déchargé) → E sur « Se réveiller » → retour **sur le lit** (arrivée `reveil`), ambiance de l'hôtel → pause/reprise → sauvegarde
des deux niveaux → l'ancien couloir voxel se charge encore (F4).

**Captures** : `docs/captures/bureau_des_reves/` (10 vues, dont 3 en vue de jeu avec Star-Faced One). Rendu logiciel en mode
Compatibilité : **pas** de SSR (reflets du marbre), pas de SSAO, limite de 8 lumières par objet ; le jeu vise Forward+ sur Mac,
qui sera plus lumineux et plus riche. L'aspect final (lumière, reflets, fluidité) reste à juger sur une vraie carte graphique.

**Limites** : aucune mesure d'images par seconde (pas de GPU) ; le ressenti de la caméra à la 3e personne dans les espaces
étroits (lit à baldaquin, balcons) n'a été vu qu'en captures ; les tests utilisent Godot 4.3 alors que le personnage a été
importé avec une version plus récente sur le PC (le fichier `.import` du GLB n'a pas été modifié) ; les portes autres que la 107
sont décoratives ; les galeries ne mènent encore nulle part.

---

## Prototype voxel (initialisation depuis Éclat)

Environnement de contrôle : Linux sans carte graphique, **Godot 4.3-stable** (headless pour les tests ; rendu logiciel OpenGL
sous Xvfb pour les captures). Tout est rejouable par `tools/check.sh` (tests) et `tools/shot.sh` (captures).

## Tests effectivement exécutés (tous réussis)

| Contrôle | Résultat |
|---|---|
| Import du projet (`godot --headless --import`) | aucune erreur |
| Compilation des 50 scripts (`tools/check_scripts.gd`) | 50 / 50 |
| `tests/run_checks.gd` (physique réelle, sans rendu) | **131 / 131** |
| `tests/recette_transition.gd` (jeu complet avec l'autoload `App`) | **19 / 19** |

**Ce que couvrent les 131 contrôles**
- *Cœur voxel* : palette (clés uniques, matières ajoutées), mailleur (cube = 12 triangles, fusion), grilles, `VoxelBox`.
- *Configuration* : échelle du joueur 1,50 m / yeux 1,41 m / rayon 0,25 m / FOV 76°, actions de saisie, préréglages d'éclairage
  (ambiance lisible : ambiante ≥ 0,8 ; lune présente en forêt).
- *Sauvegarde* : écriture, relecture, copie de secours `.bak` après corruption du fichier, effacement.
- *Assets* : 38 assets cuits (scène + fiche), 17 instanciés, reconstruction conforme, `PropScatter`.
- *Références* : tous les chemins `res://` de 137 fichiers (scripts, scènes, ressources, config) existent ; toutes les scènes se chargent ;
  tous les scripts compilent.
- *Indépendance et simplification* : aucun hasard ni bruit dans le code d'exécution ; aucune mention du dépôt Éclat ; dossiers de
  génération (`world`, `map`, `profiles`, îles) absents.
- *Niveaux (structure)* : racine `Level`, arrivées (`depart`, `retour_foret`), préréglage d'éclairage existant, fichiers cuits
  présents **et à jour** (signature des boîtes / des images), portes → scène cible et arrivée existantes, budgets (architecture
  < 40 000 triangles, ≤ 10 lumières à ombres au couloir, ≤ 4 en forêt, ≥ 60 arbres et ≥ 10 rochers posés à la main).
- *Niveaux joués* : le joueur se pose au sol à l'arrivée, hauteur des yeux ; **caméra** (orientation, 3e personne par V, retour) ;
  **marche** le long du couloir puis arrêt contre la porte du rêve ; murs nord et fond de chambre infranchissables ;
  **interaction** (porte du rêve visée, invite lisible, porte fermée à clé → message, porte de la chambre s'ouvre) ; entrée dans la
  chambre ; en forêt : altitude conforme au relief, **parcours complet du sentier** en courant (7 jalons, sans chute ni blocage),
  mur invisible à l'est, porte de retour visée.

**Recette jouée (19)** : le jeu démarre au Bureau des rêves ; E devant la porte → battant ouvert, commandes gelées, fondu,
**forêt chargée comme scène distincte** (l'ancienne est déchargée), arrivée sur le point `depart`, joueur au sol, ambiance
« Forêt · nuit » ; E devant la porte de retour → couloir rechargé, arrivée sur `retour_foret`, ambiance de l'hôtel ; pause et
reprise ; la progression des deux niveaux est sauvegardée.

## Rendu, éclairage, performances

- **Captures** : `docs/captures/prototype/` (8 vues). Rendu logiciel en **mode de compatibilité OpenGL** : fidèle pour les
  matières, la lune, les lumières ponctuelles et la brume, mais **sans** SSAO ni les réglages propres à Forward+ (le jeu vise
  Forward+ sur Mac) : la mise au point finale de l'éclairage doit se juger sur Mac (voir limites).
- **Budgets mesurés** : architecture du couloir et de la chambre 10 058 triangles (cuite : 270 Ko) ; relief de la forêt
  176 000 triangles pour 80 × 80 m (cuit : 3 Mo, 169 blocs) ; arbres en 3 niveaux de détail (15 000 → 700 triangles).
  Chargement : couloir ≈ 0,1 s, forêt ≈ 1 s (maillages cuits, aucune génération).
- **Comptes de rendu par image** (rendu logiciel, ombres comprises) : couloir 235 000 – 500 000 primitives, 190 – 320 appels de dessin ;
  forêt 0,7 – 3,3 M primitives, 80 – 780 appels de dessin selon la vue (le maximum quand de nombreux arbres complets sont dans le champ).
  Ce sont des **ordres de grandeur** : les images par seconde réelles dépendent du GPU et doivent être mesurées sur Mac (F3).

## Limites connues

- **Pas de GPU ici** : ni images par seconde, ni rendu Forward+ (SSAO, glow, ombres de lune sur les arbres lointains) n'ont été
  mesurés. À vérifier sur Mac : fluidité de la forêt (si besoin : `shadow_distance` du `Level`, nombre de lampadaires, `PropScatter`
  pour les arbres lointains).
- Le **ressenti** (échelle de 1,50 m, souris, vitesse de marche, confort du champ de vision) n'a pas pu être jugé à la main :
  les déplacements sont vérifiés par pilote automatique (vraies collisions), pas à la souris.
- De nuit, certaines **faces latérales du terrain** (contremarches d'herbe côté ombre) sont très sombres dans le rendu de
  compatibilité ; à confirmer en Forward+ (sinon : relever `ambient_energy` de `foret_nuit`).
- Les étoiles du ciel (héritées d'Éclat) sont de gros pixels carrés : voulu par le style, réglable dans `sky_clouds.gdshader`.
- La **chambre** est volontairement simple (lit, tables de nuit, armoire, fauteuil) : un seul préréglage d'éclairage pour tout
  l'étage ; la porte de chambre s'ouvre et reste ouverte (pas de refermeture, pour ne jamais enfermer le joueur).
- Les six portes du couloir fermées à clé sont du décor (message « Fermée à clé. »), sans contenu derrière.
- `main` n'existe pas encore sur Wakeless : tout est sur la branche `claude/bootstrap-wakeless`, rien n'est fusionné.
