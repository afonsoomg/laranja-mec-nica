extends Area2D
class_name HurtboxComponent

const Observer = preload("res://scripts/utils/observability.gd")
const LOG_CATEGORY := "HurtboxComponent"

signal hit_received(damage: int, direction: Vector2, force: float, is_critical: bool)
signal killed

var health_component: HealthComponent
var knockback_component: KnockbackComponent

@export var can_receive_hits: bool = true
var dodge_invulnerable: bool = false


func _ready() -> void:
	health_component = ComponentValidator.require_node(self, NodePath("../HealthComponent"), "HealthComponent", "HealthComponent") as HealthComponent
	if health_component == null:
		Observer.log_error(LOG_CATEGORY, "HealthComponent is null on HurtBoxComponent")
		set_physics_process(false)
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		return

	knockback_component = get_node_or_null("../KnockbackComponent") as KnockbackComponent

	Observer.connect_once_safe(health_component.died, _on_owner_died, "HealthComponent._ready died")


func receive_hit(damage: int, hit_direction: Vector2 = Vector2.ZERO, knockback_force: float = 0.0, is_critical: bool = false) -> void:
	if not can_receive_hits or dodge_invulnerable:
		return
	
	if health_component == null or health_component.is_dead:
		return

	hit_received.emit(damage, hit_direction, knockback_force, is_critical)

	if knockback_component != null and knockback_force > 0.0:
		knockback_component.apply_knockback(hit_direction, knockback_force)
	
	health_component.take_damage(damage)


func _on_owner_died() -> void:
	can_receive_hits = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	killed.emit()


func set_dodge_invulnerable(value: bool) -> void:
	dodge_invulnerable = value
