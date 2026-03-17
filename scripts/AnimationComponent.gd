extends Node
class_name AnimationComponent

@export var animated_sprite: AnimatedSprite2D
@export var move_component: MoveComponent

var current_facing: String = "down"


func _ready() -> void:
	if animated_sprite == null:
		push_error("AnimationComponent precisa de um AnimatedSprite2D atribuído.")
	
	if move_component == null:
		push_error("AnimationComponent precisa de um MoveComponent atribuído.")


func update_animation() -> void:
	if animated_sprite == null or move_component == null:
		return

	var direction := move_component.facing_direction
	current_facing = _vector_to_direction(direction)

	if move_component.is_moving():
		_play_if_needed("walk_" + current_facing)
	else:
		_play_if_needed("idle_" + current_facing)


func _vector_to_direction(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			return "right"
		else:
			return "left"
	else:
		if dir.y > 0:
			return "down"
		else:
			return "up"


func _play_if_needed(animation_name: String) -> void:
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
