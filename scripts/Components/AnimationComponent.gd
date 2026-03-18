extends Node
class_name AnimationComponent

signal animation_finished(animation_name: String)

@onready var move_component: MoveComponent = $"../MoveComponent"

@export var animated_sprite: AnimatedSprite2D


var current_facing: String = "down"
var action_facing: String = "down"
var locked_action_animation: String = ""

var is_attacking: bool = false
var is_hurt: bool = false
var is_dying: bool = false


func _ready() -> void:
	if animated_sprite == null:
		push_error("AnimationComponent precisa de um AnimatedSprite2D atribuído.")
		return
		
	if move_component == null:
		push_error("AnimationComponent precisa de um MoveComponent atribuído.")
		return
		
	if animated_sprite != null:
		animated_sprite.animation_finished.connect(_on_animation_finished)


func update_animation() -> void:
	if animated_sprite == null or move_component == null:
		return

	if not is_attacking and not is_hurt and not is_dying:
		_update_facing()

	if is_dying:
		_play_if_needed(locked_action_animation)
		return

	if is_hurt:
		_play_if_needed(locked_action_animation)
		return

	if is_attacking:
		_play_if_needed(locked_action_animation)
		return

	_play_if_needed(_get_locomotion_animation_name())


func can_attack() -> bool:
	return not is_dying and not is_hurt and not is_attacking


func play_attack() -> void:
	if not can_attack():
		return

	_update_facing()
	action_facing = current_facing
	locked_action_animation = _build_attack_animation_name()

	is_attacking = true


func play_hurt() -> void:
	if is_dying:
		return

	_update_facing()
	action_facing = current_facing
	locked_action_animation = "hurt_" + action_facing

	is_hurt = true
	is_attacking = false


func play_dying() -> void:
	_update_facing()
	action_facing = current_facing
	locked_action_animation = "dying_" + action_facing

	is_dying = true
	is_hurt = false
	is_attacking = false


func _update_facing() -> void:
	var direction := move_component.facing_direction
	current_facing = _vector_to_direction(direction)


func _get_locomotion_animation_name() -> String:
	if move_component.is_moving():
		if move_component.is_running:
			return "run_" + current_facing
		return "walk_" + current_facing

	return "idle_" + current_facing


func _build_attack_animation_name() -> String:
	if move_component.is_moving():
		if move_component.is_running:
			return "run_attack_" + action_facing
		return "walk_attack_" + action_facing

	return "attack_" + action_facing


func _vector_to_direction(dir: Vector2) -> String:
	if dir == Vector2.ZERO:
		return current_facing

	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0.0 else "left"
	else:
		return "down" if dir.y > 0.0 else "up"


func _play_if_needed(animation_name: String) -> void:
	if animation_name == "":
		return

	if animated_sprite.sprite_frames == null:
		return

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		push_warning("Animação não encontrada: " + animation_name)
		return

	if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		animated_sprite.play(animation_name)


func _on_animation_finished() -> void:
	var finished_animation := animated_sprite.animation

	if finished_animation.begins_with("attack_") \
	or finished_animation.begins_with("walk_attack_") \
	or finished_animation.begins_with("run_attack_"):
		is_attacking = false
		locked_action_animation = ""

	elif finished_animation.begins_with("hurt_"):
		is_hurt = false
		locked_action_animation = ""

	elif finished_animation.begins_with("dying_"):
		pass

	animation_finished.emit(finished_animation)
