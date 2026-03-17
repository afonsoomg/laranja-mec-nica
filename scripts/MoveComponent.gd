extends Node
class_name MoveComponent

signal direction_changed(new_direction: Vector2)
signal started_moving
signal stopped_moving

@export var max_speed: float = 300
@export var acceleration: float = 800.0
@export var friction: float = 1000.0
@export var can_move: bool = true

var move_input: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN

@onready var body: CharacterBody2D = get_parent() as CharacterBody2D

var _was_moving: bool = false


func _ready() -> void:
	if body == null:
		push_error("MoveComponent precisa ser filho de um CharacterBody2D.")


func set_move_input(input_vector: Vector2) -> void:
	if not can_move:
		move_input = Vector2.ZERO
		return

	var normalized_input := input_vector.normalized()
	move_input = normalized_input

	if normalized_input != Vector2.ZERO and facing_direction != normalized_input:
		facing_direction = normalized_input
		direction_changed.emit(facing_direction)


func update_velocity(delta: float) -> void:
	if body == null:
		return

	if not can_move:
		body.velocity = body.velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		if move_input != Vector2.ZERO:
			body.velocity = body.velocity.move_toward(move_input * max_speed, acceleration * delta)
		else:
			body.velocity = body.velocity.move_toward(Vector2.ZERO, friction * delta)

	_check_move_state()


func stop() -> void:
	move_input = Vector2.ZERO
	if body != null:
		body.velocity = Vector2.ZERO
	_check_move_state()


func is_moving() -> bool:
	return body != null and body.velocity.length() > 1.0


func get_velocity() -> Vector2:
	if body == null:
		return Vector2.ZERO
	return body.velocity


func get_move_input() -> Vector2:
	return move_input


func _check_move_state() -> void:
	var moving_now := is_moving()

	if moving_now and not _was_moving:
		started_moving.emit()
	elif not moving_now and _was_moving:
		stopped_moving.emit()

	_was_moving = moving_now
