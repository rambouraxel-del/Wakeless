class_name Interactable
extends Node3D
## Objet avec lequel on interagit (touche E) : porte, objet à examiner… Le niveau (Level) choisit l'objet visé
## (proche, devant le regard), affiche l'invite puis appelle `use(level)`. Hériter et surcharger `use`.

signal used(by: Node3D)

@export var prompt := "Interagir"
## Distance maximale (m) entre les yeux et le point de focalisation.
@export var reach := 2.8
@export var enabled := true
## Geste du personnage quand on utilise l'objet (« interact », « comfort »… ; vide = aucun). Joué seulement
## si le modèle du joueur le prend en charge (voir GuardianModel).
@export var gesture: StringName = &"interact"

func _ready() -> void:
	add_to_group("interactable")

## Point visé (monde). Par défaut : l'origine du nœud.
func focus_point() -> Vector3:
	return global_position

func can_use(_player: Node3D) -> bool:
	return enabled

## Texte de l'invite (sans la touche).
func prompt_text() -> String:
	return prompt

## Geste à jouer pour CET usage : vide quand l'action n'aboutit pas (ex. porte fermée à clé).
func gesture_for(_player: Node3D) -> StringName:
	return gesture

func use(level: Level) -> void:
	used.emit(level.player)
