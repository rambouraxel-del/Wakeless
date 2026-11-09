class_name GuardianModel
extends Node3D
## Contrat commun de tous les modèles jouables (explorateur provisoire, Star-Faced One, futurs gardiens).
## `Explorer` ne connaît que cette interface : il pose le modèle, l'oriente, lui donne la vitesse réelle du corps
## physique (`drive`) et déclenche les gestes contextuels (`play_action`). Le modèle joue ses animations SUR PLACE ;
## le déplacement est toujours celui de la physique.
## Repère : pieds en y = 0, regard vers -z.

signal action_started(action: StringName)
signal action_finished(action: StringName)

## Hauteur native du modèle (m), utilisée pour l'échelle : scale = hauteur voulue / hauteur native.
var native_height := 1.0
## Vitesse de rotation vers la direction de déplacement (rad/s).
var turn_rate := 12.0

## Applique la hauteur voulue du personnage (config/player.json).
func apply_height(h: float) -> void:
	scale = Vector3.ONE * (h / maxf(native_height, 0.01))

## Anime selon la vitesse horizontale en multiples de la marche (0 arrêt, 1 marche, 2 course).
func animate(_speed01: float, _grounded: bool, _delta: float) -> void:
	pass

## Version complète : vitesse monde (m/s) du corps physique. Par défaut, retombe sur `animate`.
func drive(world_velocity: Vector3, walk_speed: float, grounded: bool, delta: float) -> void:
	animate(Vector2(world_velocity.x, world_velocity.z).length() / maxf(walk_speed, 0.01), grounded, delta)

## Gestes contextuels pris en charge (« interact », « surprised », « comfort », « sleep », « wake »).
func supports(_action: StringName) -> bool:
	return false

## Joue un geste ; renvoie faux s'il n'est pas disponible (non pris en charge, ou déjà occupé par un geste).
func play_action(_action: StringName) -> bool:
	return false

func is_busy() -> bool:
	return false

func is_sleeping() -> bool:
	return false

## Orientation désirée pendant un geste ou un verrouillage de caméra : vrai = le joueur peut bouger.
func accepts_movement() -> bool:
	return true
