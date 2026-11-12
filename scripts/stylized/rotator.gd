extends Node3D
## Rotation lente et continue (anneaux du lustre astronomique, planètes, mobile d'étoiles). Purement décoratif.
@export var axis := Vector3.UP
@export var degrees_per_second := 6.0

func _process(delta: float) -> void:
	rotate_object_local(axis.normalized(), deg_to_rad(degrees_per_second) * delta)
