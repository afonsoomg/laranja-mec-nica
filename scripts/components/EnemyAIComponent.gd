extends Node
class_name EnemyAIComponent

enum AIState {
	IDLE,
	CHASE,
	ATTACK,
	DEAD
}

signal target_acquired(new_target: Node2D)
signal target_lost(previous_target: Node2D)

@onready var stats_component: StatsComponent = $"../StatsComponent"

var detection_area: Area2D = null
var detection_collision_shape: CollisionShape2D = null
var detection_range: float = 0.0

var target: Node2D = null
var current_state: AIState = AIState.IDLE
var desired_move_direction: Vector2 = Vector2.ZERO
var wants_attack: bool = false
var is_dead: bool = false


func configure_detection_area(area: Area2D) -> void:
	detection_area = area

	if detection_area == null:
		detection_collision_shape = null
		detection_range = 0.0
		return

	detection_collision_shape = detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	detection_range = _extract_detection_range_from_shape()


func on_detection_body_entered(body: Node2D) -> void:
	if is_dead or body == null or not body.is_in_group("player"):
		return

	if target == null or not is_instance_valid(target):
		_set_target(body)
		return

	var owner_node := get_parent() as Node2D
	if owner_node == null:
		return

	if owner_node.global_position.distance_to(body.global_position) < owner_node.global_position.distance_to(target.global_position):
		_set_target(body)


func on_detection_body_exited(body: Node2D) -> void:
	if is_dead or body == null:
		return

	if body == target and _is_distance_greater_than_lose_range(body.global_position):
		_clear_target()


func set_dead(value: bool) -> void:
	is_dead = value

	if is_dead:
		current_state = AIState.DEAD
		desired_move_direction = Vector2.ZERO
		wants_attack = false
		_clear_target()


func update_ai(owner_position: Vector2) -> void:
	desired_move_direction = Vector2.ZERO
	wants_attack = false

	if is_dead:
		current_state = AIState.DEAD
		return

	if target == null or not is_instance_valid(target):
		target = _find_target_inside_detection_area()
		if target == null:
			current_state = AIState.IDLE
			return

	var to_target: Vector2 = target.global_position - owner_position
	var distance_to_target: float = to_target.length()

	if distance_to_target > _get_lose_target_range():
		current_state = AIState.IDLE
		_clear_target()
		return

	if distance_to_target <= _get_attack_range():
		current_state = AIState.ATTACK
		wants_attack = true
		return

	if distance_to_target <= _get_chase_range():
		current_state = AIState.CHASE
		desired_move_direction = to_target.normalized()
		return

	current_state = AIState.IDLE


func get_move_direction() -> Vector2:
	return desired_move_direction


func should_attack() -> bool:
	return wants_attack


func get_target() -> Node2D:
	if target == null or not is_instance_valid(target):
		return null
	return target
	

func get_aim_direction(owner_position: Vector2) -> Vector2:
	if target == null or not is_instance_valid(target):
		return Vector2.ZERO

	return (target.global_position - owner_position).normalized()


func _set_target(new_target: Node2D) -> void:
	if target == new_target:
		return

	target = new_target
	target_acquired.emit(new_target)


func _clear_target() -> void:
	var previous_target := target
	target = null

	if previous_target != null and is_instance_valid(previous_target):
		target_lost.emit(previous_target)


func _find_target_inside_detection_area() -> Node2D:
	if detection_area == null:
		return null
		
	var owner_node := get_parent() as Node2D
	if owner_node == null:
		return null

	var best_target: Node2D = null
	var best_distance := INF

	var bodies := detection_area.get_overlapping_bodies()
	for body in bodies:
		if not (body is Node2D) or not body.is_in_group("player"):
			continue

		var distance := owner_node.global_position.distance_to((body as Node2D).global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = body as Node2D

	if best_target != null:
		_set_target(best_target)

	return best_target


func _extract_detection_range_from_shape() -> float:
	if detection_collision_shape == null or detection_collision_shape.shape == null:
		return 0.0

	var shape := detection_collision_shape.shape
	if shape is CircleShape2D:
		return shape.radius
	if shape is CapsuleShape2D:
		return shape.radius + (shape.height * 0.5)
	if shape is RectangleShape2D:
		var half_size: Vector2 = shape.size * 0.5
		return max(half_size.x, half_size.y)

	return 0.0


func _get_chase_range() -> float:
	if stats_component != null:
		if stats_component.chase_range > 0.0:
			return stats_component.chase_range
	return detection_range


func _get_attack_range() -> float:
	if stats_component != null:
		return stats_component.ai_attack_range
	return 28.0


func _get_lose_target_range() -> float:
	var fallback := detection_range
	if stats_component == null:
		return fallback

	return max(stats_component.lose_target_range, fallback)


func _is_distance_greater_than_lose_range(target_position: Vector2) -> bool:
	var owner_node := get_parent() as Node2D
	if owner_node == null:
		return true

	return owner_node.global_position.distance_to(target_position) > _get_lose_target_range()
