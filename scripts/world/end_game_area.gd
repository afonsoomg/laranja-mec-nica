extends Area2D
class_name EndGameArea

@export var next_scene_path: String = ""
@export var quit_game: bool = false
@export var end_message: String = "Você escapou."

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return

	if not body.is_in_group("player"):
		return

	_triggered = true

	_finish_game(body)

func _finish_game(player: Node) -> void:
	if player.has_method("set_process"):
		player.set_process(false)
	if player.has_method("set_physics_process"):
		player.set_physics_process(false)

	print(end_message)

	await get_tree().create_timer(1.5).timeout

	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
	elif quit_game:
		get_tree().quit()
