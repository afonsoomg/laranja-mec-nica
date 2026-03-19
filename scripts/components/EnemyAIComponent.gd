extends Node
class_name EnemyAIComponent

enum AIState {
	IDLE,
	CHASE,
	ATTACK,
	DEAD
}

@export var chase_range: float = 160.0
@export var attack_range: float = 28.0
@export var lose_target_range: float = 220.0

var target: Node2D = null
var current_state: AIState = AIState.IDLE
var desired_move_direction: Vector2 = Vector2.ZERO
var wants_attack: bool = false
var is_dead: bool = false


func set_target(new_target: Node2D) -> void:
	target = new_target


func set_dead(value: bool) -> void:
	is_dead = value

	if is_dead:
		current_state = AIState.DEAD
		desired_move_direction = Vector2.ZERO
		wants_attack = false


func update_ai(owner_position: Vector2) -> void:
	desired_move_direction = Vector2.ZERO
	wants_attack = false

	if is_dead:
		current_state = AIState.DEAD
		return

	if target == null or not is_instance_valid(target):
		current_state = AIState.IDLE
		return

	var to_target: Vector2 = target.global_position - owner_position
	var distance_to_target: float = to_target.length()

	if distance_to_target > lose_target_range:
		current_state = AIState.IDLE
		return

	if distance_to_target <= attack_range:
		current_state = AIState.ATTACK
		wants_attack = true
		return

	if distance_to_target <= chase_range:
		current_state = AIState.CHASE
		desired_move_direction = to_target.normalized()
		return

	current_state = AIState.IDLE


func get_move_direction() -> Vector2:
	return desired_move_direction


func should_attack() -> bool:
	return wants_attack
