# Construire un niveau à la main

Un niveau = **une scène Godot** (`scenes/levels/*.tscn`) dont la racine est un nœud `Level`. Il n'y a ni monde continu, ni graine,
ni génération : on place des nœuds. Les deux niveaux du prototype sont la référence.

```
Level (scripts/level/level.gd)        id, titre, ambiance (lighting_preset), point d'arrivée par défaut
├─ Spawns/        Marker3D nommés : points d'arrivée (le -Z du marqueur = direction du regard)
├─ Architecture/  VoxelStructure + VoxelBox …   (ou « Relief » : HeightmapTerrain)
├─ Decor/         assets cuits (instances de assets/props/*/*.tscn), particules
├─ Lumieres/      OmniLight3D
└─ Portes/        SceneDoor (et tout autre Interactable)
```

Au lancement, `Level` crée l'éclairage, le joueur (1,50 m, capsule) et la caméra sur le point d'arrivée demandé
(`App.launch["spawn"]`, sinon `default_spawn`), affiche l'invite d'interaction et enregistre la visite (`GameSave`).

## Architecture : `VoxelStructure` + `VoxelBox`

Dans l'éditeur, sous un nœud `VoxelStructure`, on ajoute des `VoxelBox` (comme des boîtes de CSG) :

| Propriété | Rôle |
|---|---|
| `position` | coin minimum de la boîte, en mètres (grille de **10 cm**) — ou centre si `centered` |
| `size` | dimensions en mètres |
| `material` | clé de `config/palette.json` (`wallpaper_teal`, `floor_planks`, `marble_black`, `brass`…) |
| `mode` | **Ajouter** ou **Creuser** (retire ce qui a été posé *avant* dans l'arbre : portes, fenêtres, niches) |

Les boîtes sont rastérisées dans l'ordre de l'arbre, maillées en blocs de 6,4 m (maillage glouton, pixels de 2 cm via le shader)
et dotées d'une collision exacte. Rotation et échelle des boîtes sont ignorées ; des nœuds `Node3D` de regroupement sont permis
(ils ne doivent être que déplacés).

**Cuisson.** Le maillage est calculé hors jeu et rangé dans `baked_path` (`scenes/levels/data/*.scn`) ; le jeu charge ce fichier.
Après avoir modifié des boîtes : cocher **Recuire** dans l'inspecteur du `VoxelStructure`, puis enregistrer la scène.
Si les boîtes ne correspondent plus au fichier cuit (signature), le jeu recalcule à la volée et avertit — jamais de périmé silencieux.

## Relief : `HeightmapTerrain`

Deux images PNG (`maps/foret/relief.png`, `peinture.png`), **1 pixel = 1 colonne de 20 cm**, centrées sur le nœud :

- *relief* : niveaux de gris, blanc = `max_height_m` (10,2 m), quantifié à 20 cm ;
- *peinture* (facultative) : noir = herbe de nuit · marron = sentier · gris = roche · vert foncé = mousse · beige = terre sèche ·
  bleu = herbe humide. Les pentes ≥ 60 cm entre colonnes voisines deviennent roche (sauf sentier).

Retoucher les images dans n'importe quel logiciel, **Recuire**, enregistrer. Les images doivent être importées en mode
**Lossless** (défaut de Godot). Même grille, mêmes matières et même shader que le terrain d'Éclat.

## Assets, lumières, portes

- **Assets** : glisser `assets/props/<id>/<id>.tscn` dans `Decor`. L'origine d'un asset est le **coin minimum** de son emprise
  (les arbres ont le tronc au centre) ; niveaux de détail et collisions sont inclus. Nouvel objet : écrire un script avec `AssetKit`
  (modèle : `props_hotel.gd`), l'ajouter à `AssetLibrary._entries()`, `godot --headless -s tools/bake_assets.gd -- <id>`.
- **Lumières** : `OmniLight3D` ordinaires (compter ≤ 10 avec ombres par niveau). Les verres émissifs viennent des matières
  (`lamp_warm`, `lantern_glow`, `dream_glow`, `moon_glass`).
- **Portes** (`SceneDoor`) : origine = charnière au sol, battant vers +X, face avant +Z. `locked` + `locked_message` (décor),
  ouverture sur place (chambre), ou transition : `target_scene` + `target_spawn` (fondu, chargement d'une scène distincte,
  arrivée sur le `Marker3D` de ce nom). `build_frame` ajoute un encadrement autonome (porte isolée en forêt), `portal_glow` la
  lueur de l'autre côté, `look` choisit HOTEL / REVE / ANCIENNE.
- **Ambiance** : `lighting_preset` choisit un préréglage de `config/lighting.json` (`hotel_reve`, `foret_nuit`, …).

## Ajouter un niveau

1. Dupliquer une scène existante, changer `level_id` / `level_title` / `lighting_preset`, vider et reconstruire le contenu.
2. Garder au moins un `Marker3D` pour chaque `default_spawn` et `target_spawn` utilisés.
3. Relier une `SceneDoor` à la nouvelle scène ; ajouter la scène à `LEVELS` dans `tests/run_checks.gd`.
4. `tools/check.sh` : références, points d'arrivée, signatures de cuisson, budgets de lumières, collisions.

## Scripts de départ (`tools/authoring/`)

`build_bureau.gd`, `build_foret.gd` (+ `make_forest_maps.gd`) ont écrit les deux scènes de départ à partir de **coordonnées écrites
dans le script** (aucun hasard) : utiles comme exemples ou pour repartir de zéro ; **la scène `.tscn` est la source de vérité** dès
qu'elle est enregistrée — les relancer la réécrit. `godot --headless -s tools/authoring/build_bureau.gd`.
