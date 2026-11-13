#!/usr/bin/env bash
# Captures de la Forêt de la peur (~34 vues). Usage : GODOT=... tools/captures_foret.sh <dossier_de_sortie> [filtre]
#   filtre : préfixe (L, P, K, M, J, N, F, ou nom complet). Coordonnées recalées sur la scène fusionnée (relief sondé par rayons : y = sol + 1,6).
# Arguments d'une vue : px py pz  tx ty tz  fov   |   spawn=… joueur=x,y,z,lacet
# Rendu LOGICIEL (Xvfb + OpenGL compatibilité) : pas de SSR/SSAO, 8 lumières max par objet.
out=$1; filt=${2:-}
cd "$(dirname "$0")/.."
mkdir -p "$out"
S=res://scenes/levels/foret_de_la_peur.tscn
shot() { local n=$1; shift; [[ -n "$filt" && "$n" != $filt* ]] && return; bash tools/shot.sh $S "$out/$n.jpg" "$@"; }
# --- L : vues larges
shot L01_depart_lisiere        0 2.8 9      0 1.5 -22 70
shot L02_lisiere_lune          0 4.6 6      -6 6 -30 72
shot L03_marais_etang          -4 2.2 -31   -2 0 -46 72
shot L04_bois_noir_entree      0 3.4 -66    0 3.0 -92 72
shot L05_bois_noir_profond     0 3.2 -92    0 3.5 -112 70
shot L06_clairiere_large       0 4.2 -112   0 4 -138 74
shot L07_vue_arriere           0 3.2 -70    0 1.5 10 74
# --- P : parcours
shot P01_depart                0 2.8 6      0 1.8 -10 66
shot P02_souche_jeune_fille    -2 3.0 -17   -6.2 1.8 -23.6 62
shot P03_passerelle            0 1.9 -32.5  0 0.8 -46 64
shot P04_ilot_fleurs           3 1.8 -39    0 0.7 -46 62
shot P05_pont_de_racines       0 4.1 -49    0 2.8 -62 64
shot P06_bois_noir_chemin      0 2.2 -72    0 2 -92 64
shot P07_porte_de_lune         0 3.4 -98    0 5.5 -108 62
# --- K : gros plans
shot K01_sol_mousse            1 1.9 -18    0 0.9 -21 60
shot K02_chemin_bord           1.5 1.3 -12  0 0.2 -15 60
shot K03_eau_reflet_lune       -3 1.4 -33   -4 0 -43 60
shot K04_fleurs_etang          -9 1.4 -38   -13.5 0.4 -40.5 55
shot K05_arbre_clairiere       0 3.8 -118   0 6 -128 60
# --- M : ambiance lumineuse
shot M01_rayons_lune           0 2.0 -14    -4 8 -26 66
shot M02_lucioles              2 1.6 -5     0 1.4 -20 55
shot M03_brume_marais          0 1.8 -36    -4 1 -62 70
shot M04_lueur_clairiere       0 3.9 -116   0 4 -134 64
shot M05_contre_jour_lune      0 2.0 -20    -8 8 -42 66
# --- J : Star-Faced One en jeu
shot J01_jeu_depart            spawn=depart
shot J02_jeu_marais            spawn=marais
shot J03_jeu_bois_noir         spawn=bois_noir
shot J04_jeu_clairiere         spawn=clairiere
shot J05_jeu_passerelle        spawn=marais joueur=0,0.5,-38,0
# --- N : moments inquiétants
shot N01_follets_au_loin       0 2.2 -50    -8 1.5 -78 62
shot N02_impasse_bois          1 2.4 -74    13 1.5 -78 62
shot N03_ruine_laterale        -8 3.0 -84   -18.5 3.0 -88.5 58
# --- F : clairière
shot F01_clairiere_entree      0 3.7 -114   0 4 -130 68
shot F02_porte_de_reveil       2 4.0 -120   8.5 5.5 -127.5 62
shot F03_clairiere_ciel        0 4.0 -126   0 16 -140 74
