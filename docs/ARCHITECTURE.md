# Architecture

## Conventions (héritées d'Éclat)

- **1 unité Godot = 1 mètre.** Joueur : 1,50 m (`config/player.json`).
- Trois grilles : **20 cm** (terrain), **10 cm** (architecture, `VoxelStructure`), **2 cm** (objets, « pixels » du shader).
- Aucun cube n'est un nœud : les voxels sont des tableaux d'octets (1 octet = 1 matière de la palette) convertis en maillages gloutons.
- Une seule palette (`config/palette.json`) et un seul shader (`voxel_stylized.gdshader`) pour le terrain, l'architecture et les objets :
  aucune texture image, nuances calculées par pixel de 2 cm. Détails dans [DIRECTION_ARTISTIQUE.md](DIRECTION_ARTISTIQUE.md).

## Chaîne de rendu

`VoxelModelBuilder`/`AssetKit` (modélisation) ou `VoxelBox` (architecture) ou image de hauteurs (relief) → `VoxelVolume`
→ `VoxelMesher.build_arrays` (maillage glouton, occlusion ambiante par sommet, données de quad pour les motifs de matière)
→ `ArrayMesh` + collision → **cuisson** en `.res`/`.scn` → chargés tels quels au lancement.

Rien n'est généré au lancement : le jeu charge des maillages cuits. Seuls les petits modèles écrits à la main du joueur et des
battants de porte sont maillés au démarrage (quelques millisecondes) ; le reste, c'est la physique, les particules et l'éclairage.

## Flux du jeu

```
godot → autoload App ─┬─ open(scène, {"spawn": …})  fondu → change_scene → fondu
                      ├─ pause (Échap), infos (F3), plein écran (F11)
                      └─ --recette=<script>         recette automatique au-dessus du jeu
Level._ready ─ LightingRig (préréglage) · Explorer + ThirdPersonCamera sur le Marker3D · HUD · GameSave
SceneDoor.use ─ ouvre le battant → App.open(cible, spawn)
```

Les scripts d'édition (`tools/`, lancés avec `-s`) n'ont pas l'autoload `App` : `Level`/`SceneDoor` y accèdent par
`get_node_or_null("/root/App")`, jamais par identifiant global.

## Code

| Dossier | Contenu |
|---|---|
| `scripts/core` | grilles, volumes, palette, mailleur, matériaux, cache de maillages, écriture sûre |
| `scripts/rendering` | `LightingRig` (lune/soleil, ciel, brouillard, SSAO, glow, ambiance), `PropScatter` |
| `scripts/assets` | kit de modélisation 2 cm, registre `AssetLibrary`, arbres, rochers, objets, `bake_assets` (outil) |
| `scripts/game` | `Explorer` (physique, marches), `ThirdPersonCamera`, `PlayerConfig`, `GameInput`, `GameSave` |
| `scripts/characters` | `GuardianModel` (contrat du modèle jouable), `GuardianDef` (config/guardians), `StarFacedOneModel` (AnimationTree, effets) |
| `scripts/level` | `Level`, `Interactable`, `SceneDoor`, `VoxelBox`, `VoxelStructure` |
| `scripts/terrain` | `HeightmapTerrain` |
| `scripts/app` | `App` (autoload), `MenuStyle` |

## Principes

- **Pas de génération au runtime** : les seules graines du projet servent à cuire les assets (`AssetLibrary`, valeurs figées) ;
  `tests/run_checks.gd` interdit le hasard et le bruit dans le code d'exécution.
- **Pas de périmé silencieux** : chaque fichier cuit porte la signature de ses sources (boîtes, images) vérifiée par les tests.
- **Un niveau = une scène** : portes = changements de scène, arrivée par `Marker3D` nommé.
