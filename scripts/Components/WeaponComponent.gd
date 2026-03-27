extends Node
class_name WeaponComponent

signal attack_started
signal attack_finished
signal target_hit(target: Node, damage: int)
signal critical_hit(target: Node, damage: int)

@export_group("Component References")
@export var stats_component: StatsComponent
@export var move_component: MoveComponent
@export var animation_component: AnimationComponent

@export_group("References")
@export var attack_hitbox: Area2D
@export var attack_collision_shape: CollisionShape2D

@export_group("HitBox Configuration")
@export var horizontal_hitbox_size: Vector2 = Vector2(18, 10)
@export var vertical_hitbox_size: Vector2 = Vector2(10, 18)
@export var horizontal_hitbox_offset: Vector2 = Vector2(16, 0)
@export var vertical_hitbox_offset: Vector2 = Vector2(0, 16)

@export var animated_sprite: AnimatedSprite2D
@export var attack_active_frame: int = 1

var can_attack: bool = true
var is_attacking: bool = false
var _hit_targets: Array[HurtboxComponent] = []

var pending_attack: bool = false
var attack_direction: Vector2 = Vector2.DOWN
var hitbox_activated_this_attack: bool = false
var attack_cancelled: bool = false


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
		
	if animation_component == null:
		push_error("WeaponComponent precisa de um AnimationComponent.")
		return
		
	if stats_component == null:
		push_error("WeaponComponent precisa de um StatsComponent.")	
		return
		
	attack_hitbox.monitoring = false
	attack_hitbox.body_entered.connect(_on_hitbox_body_entered)
	attack_hitbox.area_entered.connect(_on_hitbox_area_entered)
	
	if animated_sprite and not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)

	if animated_sprite and not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

func request_attack(dir: Vector2) -> void:
	if pending_attack:
		return

	pending_attack = true
	attack_cancelled = false
	hitbox_activated_this_attack = false
	attack_direction = dir

	if animation_component:
		animation_component.play_attack_directional(dir)

func cancel_attack() -> void:
	if not pending_attack and not is_attacking:
		return

	attack_cancelled = true
	pending_attack = false
	is_attacking = false
	hitbox_activated_this_attack = false
	_disable_hitbox()
	attack_finished.emit()
	can_attack = true

func _on_frame_changed() -> void:
	if not pending_attack or attack_cancelled:
		return

	if not animated_sprite.animation.begins_with("attack_"):
		return

	if animated_sprite.frame == attack_active_frame and not hitbox_activated_this_attack:
		hitbox_activated_this_attack = true
		try_attack()
	

func try_attack() -> void:
	if not _can_start_attack():
		return

	can_attack = false
	is_attacking = true
	_hit_targets.clear()

	move_component.facing_direction = attack_direction
	_update_hitbox_direction()
	attack_started.emit()

	_start_attack_sequence()


func _can_start_attack() -> bool:
	if not can_attack:
		return false

	if is_attacking:
		return false

	return true


func _start_attack_sequence() -> void:
	_enable_hitbox()

	await get_tree().create_timer(stats_component.hitbox_duration).timeout
	_disable_hitbox()

	is_attacking = false
	attack_finished.emit()

	await get_tree().create_timer(max(stats_component.attack_cooldown - stats_component.hitbox_duration, 0.0)).timeout
	can_attack = true


func _enable_hitbox() -> void:
	if attack_hitbox == null:
		return

	attack_hitbox.monitoring = true

	for body in attack_hitbox.get_overlapping_bodies():
		_try_hit_target(body)

	for area in attack_hitbox.get_overlapping_areas():
		_try_hit_target(area)


func _disable_hitbox() -> void:
	if attack_hitbox == null:
		return

	attack_hitbox.monitoring = false


func _on_hitbox_body_entered(body: Node) -> void:
	if not is_attacking:
		return

	_try_hit_target(body)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not is_attacking:
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

	hurtbox.receive_hit(damage, hit_direction, knockback_force, is_critical)
	target_hit.emit(hurtbox, damage)

	if is_critical:
		critical_hit.emit(hurtbox, damage)
		print("CRITICAL HIT! Damage: ", damage)


func _extract_hurtbox(target: Node) -> HurtboxComponent:
	if target is HurtboxComponent:
		return target as HurtboxComponent

	for child in target.get_children():
		if child is HurtboxComponent:
			return child as HurtboxComponent

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

func _on_animation_finished() -> void:
	if animated_sprite.animation.begins_with("attack_"):
		pending_attack = false
		hitbox_activated_this_attack = false
		_disable_hitbox()

func _belongs_to_owner(target: Node) -> bool:
	var owner_node := get_parent()

	if owner_node == null or target == null:
		return false

	if target == owner_node:
		return true

	return owner_node.is_ancestor_of(target)
