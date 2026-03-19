extends Area2D
class_name HurtboxComponent

signal hit_received(damage: int, direction: Vector2, force: float)
signal killed

@onready var health_component: HealthComponent = $"../HealthComponent"

@onready var animation_component: AnimationComponent = get_node_or_null("../AnimationComponent") as AnimationComponent
@onready var knockback_component: KnockbackComponent = get_node_or_null("../KnockbackComponent") as KnockbackComponent

@export var can_receive_hits: bool = true

var death_animation_triggered: bool = false


func _ready() -> void:
	if health_component == null:
		push_error("HurtboxComponent precisa de um HealthComponent.")

	if health_component != null:
		health_component.died.connect(_on_owner_died)


func receive_hit(damage: int, hit_direction: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	if not can_receive_hits:
		return

	if health_component == null:
		return

	if health_component.is_dead:
		return

	hit_received.emit(damage, hit_direction, knockback_force)
	health_component.take_damage(damage)

	if knockback_component != null and knockback_force > 0.0 and not health_component.is_dead:
		knockback_component.apply_knockback(hit_direction, knockback_force)

	if animation_component != null:
		if health_component.is_dead:
			if not death_animation_triggered:
				death_animation_triggered = true
				animation_component.play_dying()
		else:
			animation_component.play_hurt()


func _on_owner_died() -> void:
	can_receive_hits = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	killed.emit()
