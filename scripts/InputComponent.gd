extends Node
class_name InputComponent

func get_input_vector() -> Vector2:
	return Vector2(
		Input.get_action_strength("game_right") - Input.get_action_strength("game_left"),
		Input.get_action_strength("game_down") - Input.get_action_strength("game_up")
	).normalized()
