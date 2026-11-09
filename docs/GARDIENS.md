# Gardiens jouables (Star-Faced One et les neuf suivants)

Le personnage jouable n'est plus l'explorateur provisoire : c'est un **gardien des rêves** modélisé en 3D lisse et animé
(squelette, 11 animations), à la 3e personne. Cette page décrit l'architecture, pour ajouter les neuf autres gardiens
sans toucher au contrôleur.

## Vue d'ensemble

```
config/player.json            gardien actif, hauteur, rayon de collision, vue de départ
config/guardians/<id>.json    définition d'un gardien : scène, animations, caméra, effets   (GuardianDef)
assets/characters/<id>/       GLB exporté de Blender (+ maillage de particule)
scenes/characters/<id>.tscn   scène du gardien (script GuardianModel)
scripts/characters/           GuardianDef, GuardianModel (contrat), StarFacedOneModel
scripts/game/explorer.gd      corps physique (capsule) : pose le modèle, lui donne sa vitesse et ses gestes
```

Séparation des rôles : la **physique** (`Explorer`, CharacterBody3D, capsule) déplace réellement le personnage ; le **modèle**
(`GuardianModel`) joue ses animations SUR PLACE d'après la vitesse du corps. Aucun mouvement du nœud racine n'est animé.

## Star-Faced One

| Élément | Valeur |
|---|---|
| Modèle | `assets/characters/star_faced_one/star_faced_one.glb` (49 628 triangles, 23 os, 28 maillages, 11 animations) |
| Hauteur | `hauteur_m` de `config/player.json` = **1,10 m, halo compris** (1,17 m natif). Capsule : même hauteur, rayon `rayon_m` 0,26 m |
| Lévitation | 4,5 cm, portée par les animations (os `body`) : la capsule reste au sol, la physique est inchangée |
| Caméra | 3e personne, 3,3 m en extérieur, 2,3 m en intérieur (`config/guardians/star_faced_one.json`) ; `V` bascule en 1re personne |
| Orientation | le gardien se tourne vers sa direction de marche ; **Alt maintenu** = il garde le regard de la caméra (strafe : `float_strafe_*` et `float_backward` jouent alors pleinement) |

### Animations (30 i/s, sur place)

| Rôle | Animation | Durée | Boucle | Déclenchement |
|---|---|---|---|---|
| idle | `idle_float` | 4,80 s | oui | à l'arrêt |
| forward / fast | `float_forward` / `float_fast` | 2,00 / 1,33 s | oui | marche / course |
| backward | `float_backward` | 2,40 s | oui | recul (strafe verrouillé) |
| strafe | `float_strafe_left` / `_right` | 2,13 s | oui | déplacement latéral (strafe verrouillé) |
| interact | `interact` | 2,67 s | non | l'objet visé a un geste (`Interactable.gesture`) : portes ouvrables |
| surprised | `surprised` | 1,60 s | non | chute dans le vide (retour au point d'arrivée) |
| comfort | `comfort` | 3,67 s | non | `GuardianAction` avec `action = comfort` (à poser dans un niveau) |
| sleep / wake | `sleep` / `wake` | 4,67 / 2,80 s | non | `GuardianAction` avec `action = sleep` (se coucher, puis se réveiller) |

La locomotion est un **BlendSpace2D** (x latéral, y avant/arrière en multiples de la vitesse de marche, jusqu'à 2 = course) :
les cinq animations de déplacement et l'idle se mélangent d'après la vitesse réelle du corps physique, avec lissage. Les gestes
passent par une machine à états (`travel`) et reviennent à la locomotion ; `interact`, `surprised` et `comfort` s'annulent
si le joueur repart (après 0,9 s), `sleep` et `wake` verrouillent le déplacement.

Un geste ne se déclenche que si l'action aboutit : une porte fermée à clé n'en joue aucun, et `GuardianAction` n'est
utilisable que si le modèle sait faire le geste et n'est pas déjà occupé.

### Effets (réglables dans `effets` du JSON ; désactivables)

- émission crème-dorée de l'étoile du visage (`visage_emission`, légère pulsation) ; l'étoile et les yeux sont sur le
  **calque de rendu 20**, que la lumière du visage ignore (sinon elle brûle l'étoile et efface les yeux) ;
- lueur des étoiles du halo, de la cape et du fermoir (`halo_emission`, `halo_pulsation`) ;
- lumière chaude du visage (`lumiere_visage_*`), sans ombre, qui éclaire l'intérieur de la capuche, la cape et le sol ;
- 14 petites étoiles qui flottent autour du personnage au repos (`Fx/Motes`) ;
- traînée discrète de 26 étoiles pendant les déplacements (`Fx/Trail`) ;
- renfort pendant les accélérations et la course (`renfort_acceleration`) : plus de lueur, plus de particules.

Particules et lumière sont des nœuds de `star_faced_one.tscn` : réglables dans l'éditeur Godot.

## Ajouter un gardien

1. Exporter le GLB depuis Blender (mêmes noms d'animations que dans `animations`, ou une autre table dans le JSON).
2. Copier `config/guardians/star_faced_one.json` en `<id>.json` : scène, `hauteur_modele_m`, table d'animations, caméra, effets.
3. Créer la scène : soit en réutilisant `StarFacedOneModel` (squelette avec un os `face`, étoiles `SFO2_*` : à adapter),
   soit en créant une classe qui hérite de `GuardianModel` pour un modèle différent. `tools/authoring/build_star_faced_one_scene.gd`
   montre comment construire la scène par script.
4. Mettre `"gardien": "<id>"` dans `config/player.json` (ou `--gardien=<id>` en ligne de commande ; `--gardien=aucun` = explorateur provisoire).

Le contrat à respecter est `GuardianModel` : `apply_height`, `drive`, `supports`, `play_action`, `is_busy`, `is_sleeping`,
`accepts_movement`.

## Vérifier

```
GODOT=/chemin/godot tools/check.sh            # import, scripts, 181 contrôles, recette de transition (headless)
godot --path . -- --recette=res://tools/recette_gardien_visuelle.gd --sorties=<dossier>              # captures (GPU)
godot --path . --disable-vsync -- --recette=res://tools/recette_gardien_visuelle.gd --mode=perf      # FPS
godot --path . --write-movie film.avi --fixed-fps 30 -- --recette=res://tools/recette_gardien_visuelle.gd --mode=film
```

Le modèle source reste dans le dépôt de travail Blender (`source/star_faced_one_optimized.blend`) ; le GLB copié ici n'est
jamais modifié depuis Godot.
