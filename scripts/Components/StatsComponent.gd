class_name StatsComponent
extends Node

signal stat_changed(stat_name: StringName, new_value: Variant)

@export_group("Movement")
@export var walk_speed: float = 120.0
@export var run_speed: float = 200.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

@export_group("Health")
@export var max_health: int = 100

@export_group("Combat")
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.35
@export var hitbox_duration: float = 0.12


func set_walk_speed(value: float) -> void:
	if is_equal_approx(walk_speed, value):
		return
	walk_speed = value
	stat_changed.emit(&"walk_speed", walk_speed)


func set_run_speed(value: float) -> void:
	if is_equal_approx(run_speed, value):
		return
	run_speed = value
	stat_changed.emit(&"run_speed", run_speed)


func set_acceleration(value: float) -> void:
	if is_equal_approx(acceleration, value):
		return
	acceleration = value
	stat_changed.emit(&"acceleration", acceleration)


func set_friction(value: float) -> void:
	if is_equal_approx(friction, value):
		return
	friction = value
	stat_changed.emit(&"friction", friction)


func set_max_health(value: int) -> void:
	if max_health == value:
		return
	max_health = max(value, 1)
	stat_changed.emit(&"max_health", max_health)


func set_attack_damage(value: int) -> void:
	if attack_damage == value:
		return
	attack_damage = max(value, 0)
	stat_changed.emit(&"attack_damage", attack_damage)


func set_attack_cooldown(value: float) -> void:
	if is_equal_approx(attack_cooldown, value):
		return
	attack_cooldown = max(value, 0.0)
	stat_changed.emit(&"attack_cooldown", attack_cooldown)


func set_hitbox_duration(value: float) -> void:
	if is_equal_approx(hitbox_duration, value):
		return
	hitbox_duration = max(value, 0.0)
	stat_changed.emit(&"hitbox_duration", hitbox_duration)
