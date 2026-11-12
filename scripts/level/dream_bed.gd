class_name DreamBed
extends Interactable
## Le lit du rêveur : on entre dans un rêve EN S'ENDORMANT (pas par une porte magique).
## Le joueur s'installe sur le lit (marqueur « Coucher »), joue le geste « sleep » s'il le sait, puis fondu vers la scène
## du rêve. Au retour, le niveau reçoit {"spawn": wake_spawn, "reveil": true} et le joueur joue « wake ».

@export var dream_scene := "res://scenes/levels/foret_nocturne.tscn"
@export var dream_spawn := "depart"
@export var sleep_seconds := 3.2

var _busy := false

func _ready() -> void:
	super()
	gesture = &""
	if prompt == "Interagir":
		prompt = "Se coucher et rêver"

func focus_point() -> Vector3:
	return global_transform * Vector3(0.0, 0.7, 0.0)

func can_use(player: Node3D) -> bool:
	return enabled and not _busy and player is Explorer

## Le geste est joué par `use` (après installation sur le lit).
func gesture_for(_player: Node3D) -> StringName:
	return &""

func use(level: Level) -> void:
	if _busy:
		return
	_busy = true
	used.emit(level.player)
	var p := level.player
	p.control_enabled = false
	var lie := get_node_or_null("Coucher") as Node3D
	if lie:
		p.teleport(lie.global_position, lie.global_rotation.y)
	var slept := p.play_gesture(&"sleep")
	level.toast("Les paupières deviennent lourdes…", sleep_seconds + 1.0)
	if is_inside_tree() and DisplayServer.get_name() != "headless":
		await get_tree().create_timer(sleep_seconds if slept else 1.2).timeout
	var a := level.app()
	if a != null:
		a.open(dream_scene, {"spawn": dream_spawn})
	_busy = false
