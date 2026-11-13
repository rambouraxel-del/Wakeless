# Finition esthétique du Bureau des rêves — direction artistique

**Intention : « l'hôtel qui dort ».** Un hôtel ancien, immense, que personne n'a éclairé depuis longtemps : la nuit y est
profonde et calme, et seules quelques lampes ambrées et le clair de lune y découpent des îlots chaleureux. On doit sentir
la douceur, la mélancolie, l'émerveillement. La forme est celle de Star-Faced One : volumes pleins, arrondis, biseaux
généreux, proportions légèrement trapues, jamais anguleux, jamais plastique.

## Diagnostic de la version 9cd3f4a (captures `docs/captures/finition/avant/`)

1. **Tout est dans la même valeur et la même teinte** : murs, sols, escaliers, plafonds en violet moyen saturé (#6c4ea6).
   Aucune hiérarchie sombre / moyen / clair : l'image est plate, « dessin animé bon marché ».
2. **Grandes surfaces vides** : murs de l'atrium et de la chambre lisses sur 5 à 15 m, plafonds noirs plats.
3. **Les ors ne chantent pas** : noyés dans le violet, sans arêtes sombres ni reflets.
4. **Végétation en boules de coton** (arbre de lune, glycines).
5. **Éclairage uniforme** : la lumière remplit tout de la même façon ; pas de flaques de lune froides, pas d'îlots chauds.
6. **Chambre vide et impersonnelle** : on ne sent personne y vivre.
7. Défaut : rayures verticales sur les pilastres du couloir ; lune du lustre brûlée (blanc saturé).

## Palette et répartition des valeurs (règle 60 / 30 / 10)

| Rôle | Couleurs | Usage |
|---|---|---|
| **60 % — ombre profonde** | indigo nuit #1d1a3a → #2b2752, bleu nuit #232a4f | grands fonds, plafonds, bas des murs, zones loin des lampes |
| **30 % — tons moyens** | lavande poussiéreuse #6b6290, prune enduit #4e3f6e, pierre lilas #8a80a8 | enduits, pierre, colonnes, boiseries vues de loin |
| **10 % — accents** | or ancien #c9a15e (pas jaune), crème #efe4cf, rose lunaire #d9a6b5, ambre #ffb066 | moulures, veines du marbre, coussins, fleurs, abat-jour, filets d'or |

- **Désaturer** les violets d'environ 25–30 % par rapport à la v1 ; le violet pur devient l'exception (velours, tissus).
- **Deux températures** de lumière : lune **froide** (#a9b0ff, bleu-lavande, pas violet) en flaques et rayons ; lampes
  **chaudes** ambrées en îlots à hauteur d'yeux. Entre les deux, une ombre lisible (jamais noire, jamais grise).
- **Le haut est plus sombre que le bas** près des lampes ; les plafonds vivent par les étoiles et les filets d'or.
- Les objets émissifs restent **petits et modérés** (pas d'aplats blancs brûlés hors ampoules et cœur de la lune).

## Langage des formes et des matières

- Chaque arête est **arrondie** ; moulures épaisses, balustres ventrus, consoles galbées, pieds tournés.
- Le détail se **concentre à hauteur d'yeux** (0–3 m) et sur les **points focaux** ; au-dessus, de grandes lignes calmes
  mais **rythmées** (corniches, cadres moulurés, frises de constellations), jamais un aplat nu de plus de ~3 m.
- Matières distinctes et lisibles : enduit mat à variation douce ; bois prune-brun veiné ; velours à liseré de lumière ;
  or métallique aux creux sombres ; marbre indigo aux veines crème brillant ; lin crème-lavande aux plis doux.
- Narration par les objets : traces d'une vie (livre ouvert, lunettes, lettre, tasse, pantoufles) **sans visage, sans nom,
  sans photo identifiable** — le rêveur reste indéterminé.

## Points focaux

- **Atrium** : axe entrée → réception → arbre de lune → horloge céleste, coiffé du lustre astronomique. Les deux escaliers
  encadrent l'axe. La réception est l'îlot chaud principal.
- **Couloir** : perspective profonde vers la fenêtre de lune ; rythme régulier des travées, mais chaque travée a une petite
  différence (tableau, console, objet devant une porte, lumière plus faible).
- **Chambre 107** : le lit (chaud, lampes de chevet) répond à la fenêtre (froide, clair de lune au sol).

## Critères de validation (appliqués à chaque capture)

1. On distingue **trois plans de valeur** (sombre / moyen / clair).
2. **Aucun aplat uniforme** n'occupe plus d'un quart de l'image.
3. **Chaud et froid** sont présents tous les deux.
4. Les ors se lisent comme du **métal** (reflet + creux sombre), pas comme du jaune.
5. Rien ne **flotte**, rien ne **traverse** ; pas de scintillement ni de rayures.
6. Pas de **blanc brûlé** hors ampoules ; pas de zone noire illisible.
7. La silhouette de **Star-Faced One** se détache du décor en vue de jeu.

## Contraintes techniques

- Budget du secteur : ≤ 900 000 triangles, ≤ 110 lumières, ≤ 2 à ombres ; ≤ 16 000 triangles par module.
  Répartition visée : atrium + 150 k tris / + 12 lumières, couloir et chambre + 120 k tris / + 14 lumières.
- Rendu des captures : **logiciel** (OpenGL compatibilité, sans SSR/SSAO, 8 lumières max par objet). Sur Mac (Forward+),
  le marbre a des reflets SSR en plus.
- Pas de hasard à l'exécution (variations déterministes par index), pas de génération de carte en jeu.
- Préserver : collisions, escaliers, galeries, portes et leurs scripts, porte 107, lit (`DreamBed` + marqueur `Coucher`),
  points d'arrivée, transitions forêt / réveil, Star-Faced One.
