#!/usr/bin/env bash
# Vérification complète en mode headless (Mac / Linux / CI).
#   GODOT=/chemin/vers/godot tools/check.sh        (sur Mac : GODOT=/Applications/Godot.app/Contents/MacOS/Godot)
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT:-godot}"
# Messages sans gravité du moteur en mode headless (moteur de rendu factice) : ignorés.
NOISE='Parse JSON failed|Parameter "m" is null|mesh_get_surface_count|leaked at exit|ObjectDB instances|resources still in use|PagedAllocator|Pages in use|^ +at: '
fail=0
run() {  # run <titre> <délai> <commande…>
	local title=$1 limit=$2; shift 2
	echo "== $title"
	local log; log=$(mktemp)
	timeout "$limit" "$@" >"$log" 2>&1
	local code=$?
	grep -Ev "$NOISE" "$log" | grep -v '^$' | grep -v '^Godot Engine'
	if [ $code -ne 0 ] || grep -E "SCRIPT ERROR|Parse Error|Failed to load|Compile Error" "$log" >/dev/null; then
		echo "   >>> ÉCHEC ($title)"; fail=1
	fi
	rm -f "$log"
}
run "Import du projet" 300 "$GODOT_BIN" --headless --import
run "Compilation des scripts" 300 "$GODOT_BIN" --headless -s tools/check_scripts.gd
run "Contrôles (cœur, assets, références, niveaux, physique)" 600 "$GODOT_BIN" --headless -s tests/run_checks.gd
run "Bureau des rêves (modules, structure, parcours joué)" 600 "$GODOT_BIN" --headless -s tests/run_checks_bureau.gd
run "Finition : chambre 107 et couloir (objets, lit, portes)" 300 "$GODOT_BIN" --headless -s tests/run_checks_finition_b.gd
run "Recette jouée : chambre, lit, rêve, réveil" 300 "$GODOT_BIN" --headless --path . -- --recette=res://tests/recette_transition.gd
if [ $fail -ne 0 ]; then echo "ÉCHEC : voir ci-dessus"; exit 1; fi
echo "OK : toutes les vérifications passent."
