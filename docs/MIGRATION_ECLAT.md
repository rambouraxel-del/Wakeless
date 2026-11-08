# Migration depuis Éclat

Wakeless est un dépôt indépendant : **aucun historique Git, aucun chemin, aucune ressource d'Éclat** ne subsiste
(vérifié par `tests/run_checks.gd`, section « indépendance »). Éclat (`rambouraxel-del/ECLATS`) n'a pas été modifié : il a été
lu seulement (`git fetch` + `git archive` d'une branche dans un dossier temporaire).

## Version source retenue

**Branche `claude/echelle-immersion`, commit `c8d2c93`** (8 nov. 2026), de ECLATS.

Choix après examen des 13 branches (la branche par défaut `claude/nifty-pascal-km2czc` n'est que le « Lot 1 », très en retard) :

| Branche | Position | Décision |
|---|---|---|
| `claude/nifty-pascal-km2czc` (défaut), `claude/admiring-turing-a5mucp` | Lot 1 (`8644997`) | trop ancienne |
| `lot2` … `lot10` | étapes successives (graphisme, île habitée, génération, menus, éditeur, construction) | contenues dans `lot11` |
| `claude/lot11-fiabilite-optimisation` (`c6c5962`) | dernier lot de fonctionnalités : cartes, sauvegardes sûres, optimisation | contenue dans `echelle-immersion` |
| **`claude/echelle-immersion`** (`c8d2c93`) | `lot11` + 3 commits : **personnage 1,50 m, champ de vision réglable, arbres et rochers de l'île d'ouverture agrandis** | **retenue** |
| `claude/comparatif-generation-terrain` (`4f23e8d`) | `lot11` + 3 commits parallèles : comparatif de générations de terrain (Voxel Tools) | non retenue : expérience de génération procédurale |

Les améliorations d'échelle et de confort d'immersion sont présentes et conservées : `config/player.json` (1,50 m, yeux 1,41 m,
rayon 0,25 m, FOV 76° réglable par **F**, première personne par défaut, **V** pour la 3e), `PlayerConfig`, caméra et capsule dérivées.

## Méthode

1. Graphe de dépendances entre classes et chemins `res://` de tous les scripts (`class_name`, `load("res://…")`).
2. Fermeture transitive depuis le joueur, la caméra, l'éclairage, les assets cuits : 34 scripts, **sans aucun lien vers la
   génération de monde** (`scripts/world`, `scripts/map`, `scripts/terrain/island_*`).
3. Copie de la fermeture, réécriture des seuls points d'entrée (App, sauvegarde, registre d'assets), puis contrôle de chaque
   suppression par le projet qui compile (`tools/check_scripts.gd`) et les tests.

Éclat : 123 scripts / 28 600 lignes · Wakeless : 41 scripts / 5 600 lignes (dont ≈ 1 400 lignes nouvelles).

## Conservé tel quel (code et ressources d'Éclat)

| Domaine | Éléments |
|---|---|
| Cœur voxel | `scripts/core/` : grilles 20 cm / 10 cm / 2 cm, `VoxelVolume`, `VoxelPalette`, mailleur glouton (styles STYLIZED et DETAIL), matériaux partagés, cache de maillages, écriture sûre de fichiers |
| Rendu | `materials/voxel_stylized.gdshader` (pixels de 2 cm, aucune image), 4 matériaux, `voxel.gdshader` (ancien rendu), `sky_clouds.gdshader` (ciel, lune, étoiles) ; `LightingRig` (lune/soleil, ciel, brouillard, SSAO, glow) |
| Palette | `config/palette.json` : 118 matières d'Éclat (identifiants inchangés) |
| Joueur | `Explorer` (capsule, course, saut, marches de 36 cm, chute), `ExplorerModel`, `ThirdPersonCamera` (1re personne par défaut, V, F), `GameInput` (touches physiques ZQSD/WASD), `PlayerConfig`, `GameSave` |
| Assets | kit de modélisation 2 cm (`AssetKit`, `VoxelAsset`, `VoxelModelBuilder`, `PlaceableAsset`, `FloatingPart`, `BuildingKit`), `tools/bake_assets.gd`, **33 assets cuits** : 13 arbres (6 espèces), 4 rochers, lampadaire à éclat, amas de cristaux, brasero, colonne et arche en ruine, banc, coffres, bannière, panneaux, jardinière, tonneaux, caisses, clôture, sanctuaire |
| Outils | `PropScatter` (pose économique en MultiMesh, prévue pour la végétation dense), caméra libre, style de menu |
| Documents | `DIRECTION_ARTISTIQUE.md` et les 5 planches de référence |

## Adapté

- **`App`** (autoload) réécrit : plus de menu, d'îles, de laboratoire ; navigation par niveaux avec fondu, pause, infos techniques.
- **`GameSave`** : l'état est rangé par niveau (`levels`) et non par île ; fichier `wakeless_sauvegarde.json`.
- **`LightingRig`** : réglage optionnel `ambient_color` (remplissage uni pour les nuits lisibles).
- **`VoxelPalette`** : `has_key()`. **Palette** : 17 matières ajoutées à la fin (hôtel, nuit, rêve).
- **`AssetLibrary`** : registre réduit aux assets conservés + mobilier d'hôtel ; les variantes d'arbres et de rochers sont des
  graines **figées** (utilisées uniquement à la cuisson, jamais au lancement).
- **`props_*.gd`** : builders des objets supprimés retirés (puits, kiosque, charrette, forge, ancre de téléportation…).
- **`lighting.json`** : 3 préréglages génériques d'Éclat + 2 de Wakeless (`hotel_reve`, `foret_nuit`).

## Supprimé (spécifique à Éclat ou à la génération)

- **Génération procédurale** : `scripts/world/` (22 fichiers : terrain, profils, graines, placement, colonie, bâtiments et
  navires paramétriques, validation de monde), `scripts/terrain/` (générateur d'îles, données, nœud d'île), `scripts/village/`,
  `scripts/island/`, `config/profiles/`, `config/environment.json`, cartes d'îles (`config/islands/`).
- **Outils de création d'îles** : éditeur de carte et générateur de plan (`scripts/map/`), construction et atelier
  (`scripts/build/`), laboratoires (`scripts/lab/`, `scenes/lab/`), galerie de matériaux.
- **Menus et contenus Éclat** : menu principal, île d'ouverture (`opening_island`, quai, sanctuaire, Ancre, `anchor_fx`),
  bibliothèque d'objets du Lot 1, environnement d'îles flottantes (`environment_manager`, nuages 3D, îles lointaines).
- **Assets propres à Éclat** (23) : piédestal et ancre de téléportation, navire, ponton, maisons, atelier, entrepôt, tour,
  puits, étals, charrette, forge, râteliers, potager, fontaine…
- **Outils et tests de développement** : 36 outils de capture/recette/rapport, les suites de tests de chaque lot, les documents de chaque lot,
  27 Mo de captures, scène de démarrage et dépendances de la génération.

## Ajouté pour Wakeless

`scripts/level/` (`Level`, `Interactable`, `SceneDoor`, `VoxelBox`, `VoxelStructure`), `scripts/terrain/heightmap_terrain.gd`,
`props_hotel.gd` (5 meubles), `tools/authoring/` (scripts de départ des deux niveaux), `tests/`, les deux scènes du prototype.
Voir [NIVEAUX.md](NIVEAUX.md).
