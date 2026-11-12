extends Node3D
## Horloge céleste du grand atrium : les aiguilles suivent l'heure de l'ordinateur (lentement, sans à-coup) ;
## l'anneau des constellations tourne d'un tour par heure.
@export var hour_hand: NodePath = ^"Heures"
@export var minute_hand: NodePath = ^"Minutes"
@export var ring: NodePath = ^"Anneau"

func _process(_delta: float) -> void:
	var t := Time.get_time_dict_from_system()
	var minutes := float(t["minute"]) + float(t["second"]) / 60.0
	var hours := float(int(t["hour"]) % 12) + minutes / 60.0
	var h := get_node_or_null(hour_hand) as Node3D
	var m := get_node_or_null(minute_hand) as Node3D
	var r := get_node_or_null(ring) as Node3D
	if h:
		h.rotation.z = -hours / 12.0 * TAU
	if m:
		m.rotation.z = -minutes / 60.0 * TAU
	if r:
		r.rotation.z = minutes / 60.0 * TAU
