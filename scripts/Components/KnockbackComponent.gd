extends Node
class_name KnockbackComponent

signal knockback_started(direction: Vector2, force: float)
signal knockback_ended

@export var can_receive_knockback: bool = true
@export var decay: float = 900.0
@export var min_force_threshold: float = 8.0

@onready var body: CharacterBody2D = get_parent() as CharacterBody2D

var knockback_velocity: Vector2 = Vector2.ZERO
var is_under_knockback: bool = false


func _ready() -> void:
	if body == null:
		push_error("KnockbackComponent precisa ser filho de um CharacterBody2D.")
		return


func apply_knockback(direction: Vector2, force: float) -> void:
	if not can_receive_knockback:
		return

	if body == null:
		return

	if direction == Vector2.ZERO:
		return

	if force <= 0.0:
		return

	var normalized_direction := direction.normalized()
	knockback_velocity = normalized_direction * force
	is_under_knockback = true
	knockback_started.emit(normalized_direction, force)


func update_knockback(delta: float) -> void:
	if body == null:
		return

	if not is_under_knockback:
		return

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, decay * delta)

	if knockback_velocity.length() <= min_force_threshold:
		knockback_velocity = Vector2.ZERO
		is_under_knockback = false
		knockback_ended.emit()


func clear_knockback() -> void:
	if knockback_velocity == Vector2.ZERO and not is_under_knockback:
		return

	knockback_velocity = Vector2.ZERO
	is_under_knockback = false
	knockback_ended.emit()
	
func get_knockback_velocity() -> Vector2:
	return knockback_velocity
