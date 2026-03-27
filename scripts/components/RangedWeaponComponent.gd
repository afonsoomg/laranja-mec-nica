extends Node
class_name RangedWeaponComponent

signal shot_fired(projectile: Node)
signal shot_blocked

@export var projectile_scene: PackedScene
@export var projectile_spawn_marker: Node2D
@export var move_component: MoveComponent
@export var animation_component: AnimationComponent
@export var animated_sprite: AnimatedSprite2D
@export var stats_component: StatsComponent

@export var damage: int = 10
@export var cooldown: float = 0.8
@export var can_shoot: bool = true
@export var use_attack_animation: bool = true
@export var projectile_spawn_distance: float = 18.0
@export var knockback_force: float = 120.0

@export var attack_animation_prefix: String = "attack_"
@export var fire_frame: int = 1

var is_on_cooldown: bool = false
var attack_in_progress: bool = false
var shot_already_released: bool = false
var pending_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	if projectile_scene == null:
		push_error("RangedWeaponComponent precisa de um projectile_scene.")

	if stats_component != null:
		damage = stats_component.attack_damage
		cooldown = stats_component.attack_cooldown

	if animated_sprite != null:
		if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
			animated_sprite.frame_changed.connect(_on_frame_changed)

		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)


func try_shoot(shoot_direction: Vector2 = Vector2.ZERO) -> void:
	if not _can_start_attack():
		shot_blocked.emit()
		return

	var dir := _resolve_shoot_direction(shoot_direction)
	if dir == Vector2.ZERO:
		shot_blocked.emit()
		return
		
	DebugHelper.trace(
		"Combat",
		get_parent(),
		"attack_request",
		{
			"weapon": name,
			"type": "ranged",
			"direction": dir
		}
	)

	if use_attack_animation and animation_component != null and animation_component.can_attack():
		attack_in_progress = true
		shot_already_released = false
		pending_direction = dir

		animation_component.player_attack()
		_start_cooldown()
		return

	_fire_projectile(dir)
	_start_cooldown()


func _can_start_attack() -> bool:
	if not can_shoot:
		return false
	if projectile_scene == null:
		return false
	if is_on_cooldown:
		return false
	if attack_in_progress:
		return false
	return true


func is_busy_attacking() -> bool:
	return attack_in_progress


func update_spawn_marker_towards_target(target_position: Vector2) -> void:
	var owner_node := get_parent() as Node2D
	if owner_node == null or projectile_spawn_marker == null:
		return

	var dir := (target_position - owner_node.global_position).normalized()
	if dir == Vector2.ZERO:
		return

	projectile_spawn_marker.global_position = owner_node.global_position + dir * projectile_spawn_distance


func _on_frame_changed() -> void:
	if not attack_in_progress:
		return
	if shot_already_released:
		return
	if animated_sprite == null:
		return

	var anim_name := animated_sprite.animation
	if not anim_name.begins_with(attack_animation_prefix):
		return

	if animated_sprite.frame == fire_frame:
		shot_already_released = true
		_fire_projectile(pending_direction)


func _on_animation_finished() -> void:
	if animated_sprite == null:
		return

	var anim_name := animated_sprite.animation
	if anim_name.begins_with(attack_animation_prefix):
		attack_in_progress = false
		shot_already_released = false
		pending_direction = Vector2.ZERO


func _fire_projectile(dir: Vector2) -> void:
	DebugHelper.trace(
		"Combat",
		get_parent(),
		"attack_start",
		{
			"weapon": name,
			"type": "ranged",
			"direction": dir
		}
	)
	
	var projectile_instance := projectile_scene.instantiate()
	if projectile_instance == null:
		return

	var projectile_area := projectile_instance as Area2D
	if projectile_area == null:
		push_error("A cena do projétil precisa ter Area2D como root.")
		return

	var spawn_position := _get_spawn_position(dir)
	projectile_area.global_position = spawn_position
	get_tree().current_scene.add_child.call_deferred(projectile_area)

	DebugHelper.trace(
		"World",
		projectile_area,
		"spawn",
		{
			"source": "projectile",
			"owner": str(get_parent().name) if get_parent() != null else "Unknown",
			"position": spawn_position
		}
	)
	
	var projectile_component := ComponentValidator.require_node(projectile_area, NodePath("ProjectileComponent"), "ProjectileComponent", "ProjectileComponent") as ProjectileComponent
	if projectile_component == null:
		shot_blocked.emit()
		return

	var kb := knockback_force
	if stats_component != null:
		kb = stats_component.knockback_force
	projectile_component.initialize(dir, get_parent(), damage, kb)

	shot_fired.emit(projectile_area)


func _resolve_shoot_direction(shoot_direction: Vector2) -> Vector2:
	if shoot_direction != Vector2.ZERO:
		return shoot_direction.normalized()

	if move_component != null and move_component.facing_direction != Vector2.ZERO:
		return move_component.facing_direction.normalized()

	return Vector2.ZERO


func _get_spawn_position(dir: Vector2) -> Vector2:
	var owner_node := get_parent() as Node2D
	if owner_node == null:
		return Vector2.ZERO

	if projectile_spawn_marker != null:
		return projectile_spawn_marker.global_position

	return owner_node.global_position + dir.normalized() * projectile_spawn_distance


func _start_cooldown() -> void:
	is_on_cooldown = true
	await get_tree().create_timer(cooldown).timeout

	if not is_inside_tree():
		return

	is_on_cooldown = false
