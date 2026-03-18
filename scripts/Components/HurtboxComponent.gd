extends Area2D
class_name HurtboxComponent

signal hit_received(damage: int)
signal killed

@onready var health_component: HealthComponent = $"../HealthComponent"
@onready var animation_component: AnimationComponent = get_node_or_null("../AnimationComponent") as AnimationComponent

@export var can_receive_hits: bool = true


func _ready() -> void:
	if health_component == null:
		push_error("HurtboxComponent precisa de um HealthComponent.")

	if health_component != null:
		health_component.died.connect(_on_owner_died)


func receive_hit(damage: int) -> void:
	if not can_receive_hits:
		return

	if health_component == null:
		return

	if health_component.is_dead:
		return

	hit_received.emit(damage)
	health_component.take_damage(damage)

	if animation_component != null:
		if health_component.is_dead:
			animation_component.play_dying()
		else:
			animation_component.play_hurt()


func _on_owner_died() -> void:
	killed.emit()
