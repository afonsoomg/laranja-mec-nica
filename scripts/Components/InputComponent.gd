extends Node
class_name InputComponent

@export_group("Input Configuration")
@export var move_left_action: StringName = &"game_left"
@export var move_right_action: StringName = &"game_right"
@export var move_up_action: StringName = &"game_up"
@export var move_down_action: StringName = &"game_down"
@export var run_action: StringName = &"game_run"
@export var attack_action: StringName = &"game_attack"
@export var dodge_action: StringName = &"game_dodge"
@export var interact_action: StringName = &"game_interact"
@export var use_item1_action: StringName = &"game_use_item1"
@export var use_item2_action: StringName = &"game_use_item2"


func get_input_vector() -> Vector2:
	return Vector2(
		Input.get_action_strength(move_right_action) - Input.get_action_strength(move_left_action),
		Input.get_action_strength(move_down_action) - Input.get_action_strength(move_up_action)
	).normalized()


func is_run_pressed() -> bool:
	return Input.is_action_pressed(run_action)


func is_dodge_just_pressed() -> bool:
	return Input.is_action_just_pressed(dodge_action)


func is_attack_pressed() -> bool:
	return Input.is_action_pressed(attack_action)


func is_attack_just_pressed() -> bool:
	return Input.is_action_just_pressed(attack_action)


func is_attack_just_released() -> bool:
	return Input.is_action_just_released(attack_action)


func is_interact_just_pressed() -> bool:
	return Input.is_action_just_pressed(interact_action)


func is_use_item1_just_pressed() -> bool:
	return Input.is_action_just_pressed(use_item1_action)


func is_use_item2_just_pressed() -> bool:
	return Input.is_action_just_pressed(use_item2_action)
