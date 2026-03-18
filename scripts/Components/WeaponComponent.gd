extends Node
class_name WeaponComponent

signal attack_started
signal attack_finished
signal target_hit(target: Node, damage: int)

@export var damage: int = 10
@export var attack_cooldown: float = 0.35
@export var hitbox_duration: float = 0.12
@export var attack_hitbox: Area2D
@export var move_component: MoveComponent
@export var animation_component: AnimationComponent
@export var debug_node: Node2D

var can_attack: bool = true
var is_attacking: bool = false

var _hit_targets: Array[Node] = []


func _ready() -> void:
	if attack_hitbox == null:
		push_error("WeaponComponent precisa de um AttackHitbox (Area2D).")

	if move_component == null:
		push_error("WeaponComponent precisa de um MoveComponent.")

	if animation_component == null:
		push_error("WeaponComponent precisa de um AnimationComponent.")

	if attack_hitbox != null:
		attack_hitbox.monitoring = false
		attack_hitbox.body_entered.connect(_on_hitbox_body_entered)
		attack_hitbox.area_entered.connect(_on_hitbox_area_entered)
		
		var hitbox_shape := attack_hitbox.get_node("WeaponCollisionShape") as CollisionShape2D
		if hitbox_shape != null:
			hitbox_shape.debug_color = Color(1, 0, 0, 0.6)


func try_attack() -> void:
	if not _can_start_attack():
		return

	can_attack = false
	is_attacking = true
	_hit_targets.clear()

	_update_hitbox_direction()

	if animation_component != null:
		animation_component.play_attack()

	attack_started.emit()

	_start_attack_sequence()


func _can_start_attack() -> bool:
	if not can_attack:
		return false

	if is_attacking:
		return false

	if animation_component != null and not animation_component.can_attack():
		return false

	return true


func _start_attack_sequence() -> void:
	_enable_hitbox()

	await get_tree().create_timer(hitbox_duration).timeout
	_disable_hitbox()

	is_attacking = false
	attack_finished.emit()

	await get_tree().create_timer(max(attack_cooldown - hitbox_duration, 0.0)).timeout
	can_attack = true


func _enable_hitbox() -> void:
	if attack_hitbox == null:
		return
		
	attack_hitbox.monitoring = true
	
	if debug_node != null:
		debug_node.visible = true


	for body in attack_hitbox.get_overlapping_bodies():
		_try_hit_target(body)

	for area in attack_hitbox.get_overlapping_areas():
		_try_hit_target(area)


func _disable_hitbox() -> void:
	if attack_hitbox == null:
		return

	attack_hitbox.monitoring = false
	
	if debug_node != null:
		debug_node.visible = false


func _on_hitbox_body_entered(body: Node) -> void:
	if not is_attacking:
		return

	_try_hit_target(body)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not is_attacking:
		return

	_try_hit_target(area)


func _try_hit_target(target: Node) -> void:
	if target == null:
		return

	if target == get_parent():
		return

	if _hit_targets.has(target):
		return

	_hit_targets.append(target)

	if target.has_method("take_damage"):
		target.take_damage(damage)
		target_hit.emit(target, damage)


func _update_hitbox_direction() -> void:
	if attack_hitbox == null or move_component == null:
		return

	var dir := move_component.facing_direction

	if abs(dir.x) > abs(dir.y):
		if dir.x > 0.0:
			attack_hitbox.position = Vector2(16, 0)
		else:
			attack_hitbox.position = Vector2(-16, 0)
	else:
		if dir.y > 0.0:
			attack_hitbox.position = Vector2(0, 16)
		else:
			attack_hitbox.position = Vector2(0, -16)
