#!/usr/bin/env bash
# Série de captures de la finition esthétique du Bureau des rêves : les MÊMES angles avant/après.
# Usage : GODOT=... tools/captures_finition.sh <dossier_de_sortie> [filtre]   (filtre : préfixe, ex. « C » pour la chambre)
# Rendu LOGICIEL (Xvfb + OpenGL compatibilité) : pas de SSR/SSAO, 8 lumières max par objet ; le rendu GPU Forward+ diffère.
out=$1; filt=${2:-}
cd "$(dirname "$0")/.."
mkdir -p "$out"
S=res://scenes/levels/bureau_des_reves.tscn
shot() { local n=$1; shift; [[ -n "$filt" && "$n" != $filt* ]] && return; bash tools/shot.sh $S "$out/$n.jpg" "$@"; }
# --- Atrium
shot A01_atrium_entree           0 2.4 12.4   0 6 -6 72
shot A02_atrium_vue_de_jeu       spawn=depart
shot A03_atrium_depuis_galerie   -13.2 8.6 11.5   2 4.5 -6 72
shot A04_lustre_et_horloge       0 4.0 7.0   0 13.0 -8 70
shot A05_reception               0 1.7 4.6   0 1.0 0.0 60
shot A06_escalier_ouest          -4.5 1.7 6.5   -9.5 3.5 -4.0 68
shot A07_galerie_nord            -10.5 7.7 -7.8   8 6.8 -8.2 74
shot A08_plafond                 0 6.5 4.0   0 20 -2 80
shot A09_arbre_de_lune           3.2 1.8 0.8   0 3.0 -4.2 64
shot A10_mur_ouest_portes        -6.0 1.8 1.5   -15 2.4 -1.0 66
shot A11_colonnes_arcades        6.5 1.6 -3.5   11.6 4.0 -9.0 66
shot A12_porte_entree            0 2.2 3.0   0 3.5 13 70
# --- Couloir
shot B01_couloir_vue_de_jeu      spawn=couloir
shot B02_couloir_perspective     17.0 2.0 0.0   45 2.6 0 72
shot B03_couloir_retour          49.5 2.0 0.4   20 2.4 0 72
shot B04_couloir_portes          27.0 1.6 1.6   33 1.8 -2.95 64
shot B05_couloir_voute           30.0 1.4 0.0   38 7.5 0 76
shot B06_porte_107               31.35 1.7 2.6   31.35 1.9 -3 70
# --- Chambre 107
shot C01_chambre_depuis_porte    31.35 1.75 -3.9   33 1.0 -9 78
shot C02_chambre_vue_large       28.2 2.3 -4.3   35 0.9 -9 78
shot C03_lit_baldaquin           30.6 1.7 -5.2   35 1.0 -8.2 70
shot C04_lit_gros_plan           32.4 1.3 -6.2   35.2 0.8 -7.6 58
shot C05_fenetre_bureau          33.5 1.8 -5.0   28.5 1.2 -11.0 72
shot C06_armoire_etagere         31.5 1.7 -6.0   27.0 1.4 -8.5 70
shot C07_chevet_details          33.6 1.1 -4.6   35.4 0.7 -6.0 55
shot C08_plafond_chambre         31.0 1.2 -6.5   32 3.6 -8.5 80
shot C09_chambre_vers_porte      34.0 1.8 -10.5   30.5 1.5 -3.6 76
# --- Star-Faced One (vue de jeu à la 3e personne)
shot D01_joueur_atrium           spawn=depart joueur=0,0.05,7.5,0
shot D02_joueur_galerie          spawn=depart joueur=-8,6.05,-11,90
shot D03_joueur_couloir          spawn=couloir joueur=24,0.05,0,-90
shot D04_joueur_chambre          spawn=depart joueur=31.35,0.05,-5.0,180
shot D05_reveil_sur_le_lit       spawn=reveil
