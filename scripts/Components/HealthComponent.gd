extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died

@onready var stats_component: StatsComponent = $"../StatsComponent"

var current_health: int = 0
var max_health: int = 0
var is_dead: bool = false


func _ready() -> void:
	if stats_component == null:
		push_error("HealthComponent precisa de um StatsComponent.")	
		return
		
	max_health = stats_component.max_health
	
	current_health = max_health
	health_changed.emit(current_health, max_health)


func take_damage(amount: int) -> void:
	if is_dead:
		return

	if amount <= 0:
		return

	current_health = max(current_health - amount, 0)

	damaged.emit(amount)
	health_changed.emit(current_health, stats_component.max_health)

	if current_health <= 0:
		is_dead = true
		died.emit()


func heal(amount: int) -> void:
	if is_dead:
		return

	if amount <= 0:
		return

	current_health = min(current_health + amount, max_health)

	healed.emit(amount)
	health_changed.emit(current_health, max_health)


func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0

	return float(current_health) / float(max_health)
