extends Node
class_name WeaponComponent

const Observer = preload("res://scripts/utils/observability.gd")
const LOG_CATEGORY := "WeaponComponent"

signal attack_started(direction: Vector2)
signal attack_finished(direction: Vector2)
signal target_hit(target: Node, damage: int)
signal critical_hit(target: Node, damage: int)

@export_group("Component References")
@export var stats_component: StatsComponent
@export var move_component: MoveComponent

@export_group("References")
@export var attack_hitbox: Area2D
@export var attack_collision_shape: CollisionShape2D

@export_group("HitBox Configuration")
@export var horizontal_hitbox_size: Vector2 = Vector2(18, 10)
@export var vertical_hitbox_size: Vector2 = Vector2(10, 18)
@export var horizontal_hitbox_offset: Vector2 = Vector2(16, 0)
@export var vertical_hitbox_offset: Vector2 = Vector2(0, 16)

var _attack_direction: Vector2 = Vector2.DOWN
var _hit_targets: Array[HurtboxComponent] = []
var _attack_active: bool = false


func _ready() -> void:
	if attack_hitbox == null:
		push_error("WeaponComponent precisa de um AttackHitbox (Area2D).")
		return

	if attack_collision_shape == null:
		push_error("WeaponComponent precisa de um CollisionShape2D da hitbox.")
		return

	if move_component == null:
		push_error("WeaponComponent precisa de um MoveComponent.")
		return

	if stats_component == null:
		push_error("WeaponComponent precisa de um StatsComponent.")
		return

	attack_hitbox.monitoring = false
	Observer.connect_once_safe(attack_hitbox.body_entered, _on_hitbox_body_entered, "WeaponComponent._ready body_entered")
	Observer.connect_once_safe(attack_hitbox.area_entered, _on_hitbox_area_entered, "WeaponComponent._ready area_entered")
	

func begin_attack(dir: Vector2) -> void:
	_attack_direction = dir
	_attack_active = false
	_hit_targets.clear()
	_disable_hitbox()

	if move_component != null:
		move_component.facing_direction = dir
	
	_update_hitbox_direction()
	
	DebugHelper.trace(
		"Combat",
		get_parent(),
		"attack_begin",
		{
			"weapon": name,
			"type": "melee",
			"direction": dir
		}
	)
	
	DebugHelper.trace(
		"Combat",
		get_parent(),
		"attack_start",
		{
			"weapon": name,
			"direction": move_component.facing_direction,
			"hitbox_duration": stats_component.hitbox_duration
		}
	)
	attack_started.emit(dir)


func enable_attack_hitbox() -> void:
	if attack_hitbox == null:
		return
	
	_update_hitbox_direction()
	_attack_active = true
	_enable_hitbox()


func disable_attack_hitbox() -> void:
	if not _attack_active and (attack_hitbox == null or not attack_hitbox.monitoring):
		return

	_attack_active = false
	_disable_hitbox()
	attack_finished.emit(_attack_direction)


func cancel_attack() -> void:
	_attack_active = false
	_disable_hitbox()
	_hit_targets.clear()


func _enable_hitbox() -> void:
	if attack_hitbox == null:
		return

	attack_collision_shape.disabled = false
	attack_hitbox.monitoring = true

	for body in attack_hitbox.get_overlapping_bodies():
		_try_hit_target(body)

	for area in attack_hitbox.get_overlapping_areas():
		_try_hit_target(area)


func _disable_hitbox() -> void:
	if attack_hitbox == null:
		return

	set_deferred("attack_hitbox.monitoring", false)
	set_deferred("attack_collision_shape.disabled", true)


func _on_hitbox_body_entered(body: Node) -> void:
	if not _attack_active:
		return

	_try_hit_target(body)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not _attack_active:
		return

	_try_hit_target(area)


func _roll_damage() -> Dictionary:
	var base_damage := stats_component.attack_damage
	var crit_chance := clampf(stats_component.crit_chance, 0.0, 1.0)
	var crit_multiplier: float = max(stats_component.crit_multiplier, 1.0)

	var is_critical := randf() < crit_chance
	var final_damage := base_damage

	if is_critical:
		final_damage = int(round(base_damage * crit_multiplier))

	return {
		"damage": final_damage,
		"is_critical": is_critical
	}


func _try_hit_target(target: Node) -> void:
	if target == null:
		return

	if _belongs_to_owner(target):
		return

	var hurtbox := _extract_hurtbox(target)

	if hurtbox == null:
		return

	if _belongs_to_owner(hurtbox):
		return

	if _hit_targets.has(hurtbox):
		return

	_hit_targets.append(hurtbox)

	var hit_result := _roll_damage()
	var damage: int = hit_result.damage
	var is_critical: bool = hit_result.is_critical

	var hit_direction := move_component.facing_direction
	var knockback_force := stats_component.knockback_force
	var attacker := get_parent()
	var target_entity := hurtbox.get_parent()
	DebugHelper.trace(
		"Combat",
		attacker,
		"hit_registered",
		{
			"source": "melee_weapon",
			"target": str(target_entity.name) if target_entity != null else "Unknown",
			"damage": damage,
			"is_critical": is_critical,
			"direction": hit_direction,
			"knockback_force": knockback_force
		}
	)
	
	hurtbox.receive_hit(damage, hit_direction, knockback_force, is_critical)
	target_hit.emit(hurtbox, damage)

	if is_critical:
		critical_hit.emit(hurtbox, damage)
		Observer.log_info(LOG_CATEGORY, "Critical hit dealt. Damage=%d" % damage)


func _extract_hurtbox(target: Node) -> HurtboxComponent:
	if target is HurtboxComponent:
		return target as HurtboxComponent

	for child in target.get_children():
		if child is HurtboxComponent:
			return child as HurtboxComponent
			
		var nested := _extract_hurtbox(child)
		if nested != null:
			return nested

	return null


func _update_hitbox_direction() -> void:
	if attack_hitbox == null or attack_collision_shape == null or move_component == null:
		return

	var rect_shape := attack_collision_shape.shape as RectangleShape2D
	if rect_shape == null:
		push_warning("A hitbox melee precisa usar RectangleShape2D.")
		return

	var dir := move_component.facing_direction

	if abs(dir.x) > abs(dir.y):
		rect_shape.size = horizontal_hitbox_size

		if dir.x > 0.0:
			attack_hitbox.position = horizontal_hitbox_offset
		else:
			attack_hitbox.position = Vector2(-horizontal_hitbox_offset.x, horizontal_hitbox_offset.y)
	else:
		rect_shape.size = vertical_hitbox_size

		if dir.y > 0.0:
			attack_hitbox.position = vertical_hitbox_offset
		else:
			attack_hitbox.position = Vector2(vertical_hitbox_offset.x, -vertical_hitbox_offset.y)


func _belongs_to_owner(target: Node) -> bool:
	var owner_node := get_parent()

	if owner_node == null or target == null:
		return false

	if target == owner_node:
		return true

	return owner_node.is_ancestor_of(target)
