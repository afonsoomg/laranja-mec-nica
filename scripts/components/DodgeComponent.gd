extends Node
class_name DodgeComponent

signal dodge_started
signal dodge_finished

@export var move_component: MoveComponent
@export var duration: float = 0.20
@export var speed: float = 260.0

var is_dodging: bool = false
var dodge_direction: Vector2 = Vector2.ZERO
var _timer: float = 0.0

func start_dodge(dir: Vector2) -> bool:
	if is_dodging:
		return false

	if move_component == null:
		return false

	if dir == Vector2.ZERO:
		return false

	is_dodging = true
	dodge_direction = dir.normalized()
	_timer = duration
	dodge_started.emit()
	return true

func update_dodge(delta: float) -> void:
	if not is_dodging:
		return

	_timer -= delta

	move_component.set_move_input(Vector2.ZERO)
	move_component.set_running(false)
	move_component.set_forced_velocity(dodge_direction * speed)
	move_component.update_velocity(delta)

	if _timer <= 0.0:
		finish_dodge()

func finish_dodge() -> void:
	if not is_dodging:
		return

	is_dodging = false
	dodge_direction = Vector2.ZERO

	if move_component != null:
		move_component.clear_forced_velocity()

	dodge_finished.emit()
