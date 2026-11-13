class_name ForetEtat
extends Node
## État des énigmes de la Forêt de la peur (fleurs allumées, pont, pierre de lune, porte, apaisement).
## Sauvegardé avec GameSave (même identifiant que le niveau) et restauré à l'entrée suivante.
## Les composants (FleurLanterne, PontRacines, PiedestalLune, PorteLune, JeuneFille) le retrouvent par le groupe « foret_etat ».

signal change(cle: StringName)

const LEVEL_ID := "foret-de-la-peur"

var fleurs: Array[String] = []
var pont_ouvert := false
var pierre_prise := false
var porte_ouverte := false
var apaisee := false

func _enter_tree() -> void:
	add_to_group("foret_etat")
	var d := GameSave.level(LEVEL_ID)
	for f in d.get("fleurs", []):
		fleurs.append(String(f))
	pont_ouvert = bool(d.get("pont_ouvert", false))
	pierre_prise = bool(d.get("pierre_prise", false))
	porte_ouverte = bool(d.get("porte_ouverte", false))

func _ready() -> void:
	_persist.call_deferred()                       # après le Level, qui réécrit « visited » à son _ready

static func trouver(depuis: Node) -> ForetEtat:
	return depuis.get_tree().get_first_node_in_group("foret_etat") as ForetEtat if depuis.is_inside_tree() else null

func marquer(cle: StringName, valeur: Variant = true) -> void:
	match cle:
		&"fleur":
			if not fleurs.has(String(valeur)):
				fleurs.append(String(valeur))
		&"pont_ouvert": pont_ouvert = bool(valeur)
		&"pierre_prise": pierre_prise = bool(valeur)
		&"porte_ouverte": porte_ouverte = bool(valeur)
		&"apaisee": apaisee = bool(valeur)
	change.emit(cle)
	_persist()

func _persist() -> void:
	if not is_inside_tree():
		return
	var d := GameSave.level(LEVEL_ID)
	d["fleurs"] = fleurs.duplicate()
	d["pont_ouvert"] = pont_ouvert
	d["pierre_prise"] = pierre_prise
	d["porte_ouverte"] = porte_ouverte
	GameSave.set_level(LEVEL_ID, d)

## Efface la progression des énigmes (tests, nouvelle partie).
static func effacer() -> void:
	GameSave.clear_level(LEVEL_ID)
