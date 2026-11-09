class_name GuardianAction
extends Interactable
## Point d'action contextuel pour un gardien : lit, personnage à réconforter, objet à examiner…
## Le geste ne se déclenche que lorsque l'action est réellement disponible (le modèle du joueur la prend en charge
## et n'est pas déjà occupé). « sleep » fait dormir ; l'appui suivant réveille (« wake »).
## Aucune instance n'est posée dans les niveaux du prototype : à placer dans Portes/ ou Decor/ d'un niveau.

## Geste joué : « interact », « comfort », « surprised » ou « sleep » (bascule sommeil / réveil).
@export var action: StringName = &"comfort"
@export var prompt_when_sleeping := "Se réveiller"

var _wake_mode := false

func _ready() -> void:
	super()
	if prompt == "Interagir":
		prompt = "Se coucher" if action == &"sleep" else "Réconforter"

func can_use(player: Node3D) -> bool:
	if not enabled:
		return false
	var ex := player as Explorer
	if ex == null or ex.model == null or not ex.model.supports(action):
		return false
	_wake_mode = action == &"sleep" and ex.model.is_sleeping()
	if _wake_mode:
		return true
	return not ex.model.is_busy()

func prompt_text() -> String:
	return prompt_when_sleeping if _wake_mode else prompt

## Le geste est choisi dans `use` (bascule sommeil / réveil) : pas de geste automatique du niveau.
func gesture_for(_player: Node3D) -> StringName:
	return &""

func use(level: Level) -> void:
	var ex := level.player
	if action == &"sleep" and ex.model.is_sleeping():
		ex.play_gesture(&"wake")
	else:
		ex.play_gesture(action)
	super.use(level)
