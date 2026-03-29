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
@export var knockback_force: float = 140.0

@export_group("Enemy AI")
@export var chase_range: float = 0.0
@export var lose_target_range: float = 0.0
@export var ai_attack_range: float = 28.0

@export_group("Critical")
@export_range(0.0, 1.0, 0.01) var crit_chance: float = 0.0
@export var crit_multiplier: float = 1.5

var _additive_modifiers: Dictionary = {}

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


func set_chase_range(value: float) -> void:
	if is_equal_approx(chase_range, value):
		return
	chase_range = max(value, 0.0)
	stat_changed.emit(&"chase_range", chase_range)


func set_lose_target_range(value: float) -> void:
	if is_equal_approx(lose_target_range, value):
		return
	lose_target_range = max(value, 0.0)
	stat_changed.emit(&"lose_target_range", lose_target_range)


func set_ai_attack_range(value: float) -> void:
	if is_equal_approx(ai_attack_range, value):
		return
	ai_attack_range = max(value, 0.0)
	stat_changed.emit(&"ai_attack_range", ai_attack_range)


func add_modifier(stat_name: StringName, modifier_id: StringName, additive_value: float) -> void:
	if modifier_id == StringName(""):
		push_warning("StatsComponent.add_modifier requires a non-empty modifier_id.")
		return

	if not _additive_modifiers.has(stat_name):
		_additive_modifiers[stat_name] = {}

	var modifiers_for_stat := _additive_modifiers[stat_name] as Dictionary
	modifiers_for_stat[modifier_id] = additive_value
	_additive_modifiers[stat_name] = modifiers_for_stat
	stat_changed.emit(stat_name, get_stat_value(stat_name))


func remove_modifier(stat_name: StringName, modifier_id: StringName) -> void:
	if not _additive_modifiers.has(stat_name):
		return

	var modifiers_for_stat := _additive_modifiers[stat_name] as Dictionary
	if not modifiers_for_stat.has(modifier_id):
		return

	modifiers_for_stat.erase(modifier_id)
	if modifiers_for_stat.is_empty():
		_additive_modifiers.erase(stat_name)
	else:
		_additive_modifiers[stat_name] = modifiers_for_stat

	stat_changed.emit(stat_name, get_stat_value(stat_name))


func clear_modifiers(stat_name: StringName) -> void:
	if not _additive_modifiers.has(stat_name):
		return

	_additive_modifiers.erase(stat_name)
	stat_changed.emit(stat_name, get_stat_value(stat_name))


func get_attack_damage() -> int:
	return int(round(get_stat_value(&"attack_damage")))


func get_crit_chance() -> float:
	return clampf(get_stat_value(&"crit_chance"), 0.0, 1.0)


func get_crit_multiplier() -> float:
	return max(get_stat_value(&"crit_multiplier"), 1.0)


func get_stat_value(stat_name: StringName) -> float:
	var base_value := _get_base_stat_value(stat_name)
	var additive_total := _get_additive_total(stat_name)
	return base_value + additive_total


func _get_base_stat_value(stat_name: StringName) -> float:
	match stat_name:
		&"walk_speed":
			return walk_speed
		&"run_speed":
			return run_speed
		&"acceleration":
			return acceleration
		&"friction":
			return friction
		&"max_health":
			return float(max_health)
		&"attack_damage":
			return float(attack_damage)
		&"attack_cooldown":
			return attack_cooldown
		&"hitbox_duration":
			return hitbox_duration
		&"knockback_force":
			return knockback_force
		&"chase_range":
			return chase_range
		&"lose_target_range":
			return lose_target_range
		&"ai_attack_range":
			return ai_attack_range
		&"crit_chance":
			return crit_chance
		&"crit_multiplier":
			return crit_multiplier
		_:
			return 0.0


func _get_additive_total(stat_name: StringName) -> float:
	if not _additive_modifiers.has(stat_name):
		return 0.0

	var modifiers_for_stat := _additive_modifiers[stat_name] as Dictionary
	var total := 0.0
	for value in modifiers_for_stat.values():
		total += float(value)

	return total
