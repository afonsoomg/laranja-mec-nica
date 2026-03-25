extends Node
class_name RangedWeaponComponent

signal shot_fired(projectile: Node)
signal shot_blocked

@export var projectile_scene: PackedScene
@export var projectile_spawn_marker: Node2D
@export var move_component: MoveComponent
@export var animation_component: AnimationComponent
@export var stats_component: StatsComponent

@export var damage: int = 10
@export var cooldown: float = 0.8
@export var can_shoot: bool = true
@export var use_attack_animation: bool = true
@export var projectile_spawn_distance: float = 18.0
@export var knockback_force: float = 120.0

var is_on_cooldown: bool = false


func _ready() -> void:
	if projectile_scene == null:
		push_error("RangedWeaponComponent precisa de um projectile_scene.")
		
	damage = stats_component.attack_damage
	cooldown = stats_component.attack_cooldown


func try_shoot(shoot_direction: Vector2 = Vector2.ZERO) -> void:
	if not _can_shoot():
		shot_blocked.emit()
		return

	var projectile_instance := projectile_scene.instantiate()
	if projectile_instance == null:
		return

	var projectile_area := projectile_instance as Area2D
	if projectile_area == null:
		push_error("A cena do projétil precisa ter Area2D como root.")
		return

	var dir := _resolve_shoot_direction(shoot_direction)
	if dir == Vector2.ZERO:
		shot_blocked.emit()
		return

	var spawn_position := _get_spawn_position(dir)

	projectile_area.global_position = spawn_position
	get_tree().current_scene.add_child.call_deferred(projectile_area)

	var projectile_component := projectile_area.get_node("ProjectileComponent") as ProjectileComponent
	if projectile_component != null:
		projectile_component.initialize(dir, get_parent(), damage, stats_component.knockback_force)

	if use_attack_animation and animation_component != null and animation_component.can_attack():
		animation_component.play_attack()

	shot_fired.emit(projectile_area)
	_start_cooldown()


func _can_shoot() -> bool:
	if not can_shoot:
		return false

	if is_on_cooldown:
		return false

	return projectile_scene != null


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

	var spawn_distance := projectile_spawn_distance

	if projectile_spawn_marker != null:
		spawn_distance = owner_node.global_position.distance_to(projectile_spawn_marker.global_position)

	return owner_node.global_position + dir.normalized() * spawn_distance


func _start_cooldown() -> void:
	is_on_cooldown = true

	await get_tree().create_timer(cooldown).timeout

	if not is_inside_tree():
		return

	is_on_cooldown = false
