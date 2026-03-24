extends Node
class_name MoveComponent

signal direction_changed(new_direction: Vector2)
signal started_moving
signal stopped_moving
signal run_state_changed(is_running: bool)

@onready var stats_component: StatsComponent = $"../StatsComponent"
@onready var body: CharacterBody2D = get_parent() as CharacterBody2D

@export var can_move: bool = true

var move_input: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN
var is_running: bool = false
var _was_moving: bool = false


func _ready() -> void:
	if body == null:
		push_error("MoveComponent precisa ser filho de um CharacterBody2D.")
		return
		
	if stats_component == null:
		push_error("MoveComponent precisa de um StatsComponent.")	
		return


func set_move_input(input_vector: Vector2) -> void:
	if not can_move:
		move_input = Vector2.ZERO
		return

	var normalized_input := input_vector.normalized()
	move_input = normalized_input

	if normalized_input != Vector2.ZERO and facing_direction != normalized_input:
		facing_direction = normalized_input
		direction_changed.emit(facing_direction)


func set_running(value: bool) -> void:
	if is_running == value:
		return

	is_running = value
	#print("MoveComponent is_running:", is_running)
	run_state_changed.emit(is_running)


func update_velocity(delta: float) -> void:
	if body == null or stats_component == null:
		return

	if not can_move:
		set_running(false)
		body.velocity = body.velocity.move_toward(Vector2.ZERO, stats_component.friction * delta)
		_check_move_state()
		return

	var target_speed := get_current_speed()

	if move_input != Vector2.ZERO:
		body.velocity = body.velocity.move_toward(
			move_input * target_speed,
			stats_component.acceleration * delta
		)
	else:
		body.velocity = body.velocity.move_toward(
			Vector2.ZERO,
			stats_component.friction * delta
		)

	_check_move_state()


func stop() -> void:
	move_input = Vector2.ZERO

	if body != null:
		body.velocity = Vector2.ZERO

	_check_move_state()


func get_current_speed() -> float:
	if stats_component == null:
		return 0.0

	return stats_component.run_speed if is_running else stats_component.walk_speed


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
