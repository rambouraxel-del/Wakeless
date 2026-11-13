#!/usr/bin/env bash
# Captures de la Forêt de la peur (~34 vues). Usage : GODOT=... tools/captures_foret.sh <dossier_de_sortie> [filtre]
#   filtre : préfixe (L, P, K, M, J, N, F, ou nom complet). Coordonnées d'après docs/FORET_DE_LA_PEUR.md ; à recaler après fusion.
# Arguments d'une vue : px py pz  tx ty tz  fov   |   spawn=… joueur=x,y,z,lacet
# Rendu LOGICIEL (Xvfb + OpenGL compatibilité) : pas de SSR/SSAO, 8 lumières max par objet.
out=$1; filt=${2:-}
cd "$(dirname "$0")/.."
mkdir -p "$out"
S=res://scenes/levels/foret_de_la_peur.tscn
shot() { local n=$1; shift; [[ -n "$filt" && "$n" != $filt* ]] && return; bash tools/shot.sh $S "$out/$n.jpg" "$@"; }
# --- L : vues larges
shot L01_depart_lisiere        0 2.2 6      0 1 -24 70
shot L02_lisiere_lune          6 1.6 -4     -10 9 -30 70
shot L03_marais_large          -4 2.4 -30   -10 0 -62 72
shot L04_bois_noir_entree      0 2.0 -62    0 2 -92 72
shot L05_bois_noir_profond     0 1.8 -88    0 2 -112 70
shot L06_clairiere_large       0 3.0 -108   0 3 -138 74
shot L07_vue_arriere           0 2.4 -60    0 2 20 74
# --- P : parcours
shot P01_depart                0 1.7 4      0 1.2 -12 66
shot P02_lisiere_chemin        0 1.7 -12    0 1.2 -30 66
shot P03_gue_marais            0 1.7 -36    -2 1 -52 66
shot P04_sortie_marais         0 1.7 -54    0 1.2 -70 66
shot P05_bois_noir_chemin      0 1.7 -74    0 1.2 -92 64
shot P06_bois_noir_fin         0 1.7 -96    0 1.5 -112 64
shot P07_arrivee_clairiere     0 1.7 -108   0 2.5 -128 66
# --- K : gros plans
shot K01_sol_mousse            1 0.9 -8     0 0 -11 60
shot K02_chemin_bord           1.5 0.8 -16  0 0 -19 60
shot K03_eau_bord              -4 0.9 -38   -8 -0.4 -44 60
shot K04_feu_follet            0 1.3 -50    -5 1.2 -58 50
shot K05_arbre_clairiere       0 1.6 -118   0 4 -128 60
# --- M : ambiance lumineuse
shot M01_rayons_lune           0 1.5 -14    -4 7 -24 66
shot M02_lucioles              1 1.2 -4     0 1.2 -16 55
shot M03_brume_marais          0 1.5 -36    -4 1 -62 70
shot M04_lueur_clairiere       0 1.6 -116   0 2.2 -134 64
shot M05_contre_jour_lune      0 1.4 -20    -8 7 -40 66
# --- J : Star-Faced One en jeu
shot J01_jeu_depart            spawn=depart
shot J02_jeu_lisiere           spawn=depart joueur=0,0.1,-14,0
shot J03_jeu_marais            spawn=depart joueur=0,0.1,-44,0
shot J04_jeu_bois_noir         spawn=depart joueur=0,0.1,-84,0
shot J05_jeu_clairiere         spawn=depart joueur=0,0.1,-124,0
# --- N : moments inquiétants
shot N01_follets_au_loin       0 1.6 -46    -8 1.2 -70 62
shot N02_silhouette_bois       0 1.7 -80    0 2.5 -104 60
shot N03_chemin_se_perd        0 1.5 -98    0 1.2 -116 58
# --- F : clairière
shot F01_clairiere_entree      0 1.7 -110   0 3 -130 68
shot F02_arbre_ancien          6 1.7 -120   0 5 -132 66
shot F03_clairiere_ciel        0 1.4 -126   0 14 -140 74
