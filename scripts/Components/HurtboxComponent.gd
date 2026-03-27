extends Area2D
class_name HurtboxComponent

signal hit_received(damage: int, direction: Vector2, force: float, is_critical: bool)
signal killed

@onready var health_component: HealthComponent = $"../HealthComponent"
@onready var knockback_component: KnockbackComponent = get_node_or_null("../KnockbackComponent") as KnockbackComponent
@onready var audio_component: AudioComponent = get_node_or_null("../AudioComponent") as AudioComponent
@onready var vfx_component: VfxComponent = get_node_or_null("../VfxComponent") as VfxComponent


@export var can_receive_hits: bool = true


func _ready() -> void:
	if health_component == null:
		push_error("HurtboxComponent precisa de um HealthComponent.")

	if health_component != null:
		health_component.died.connect(_on_owner_died)


func receive_hit(damage: int, hit_direction: Vector2 = Vector2.ZERO, knockback_force: float = 0.0, is_critical: bool = false) -> void:
	if not can_receive_hits:
		return

	if health_component == null or health_component.is_dead:
		return

	hit_received.emit(damage, hit_direction, knockback_force, is_critical)

	if knockback_component != null and knockback_force > 0.0:
		knockback_component.apply_knockback(hit_direction, knockback_force)

	if audio_component:
		audio_component.play_hurt()
	
	if vfx_component:
		vfx_component.play_hit_burst()
	
	health_component.take_damage(damage)

func _on_owner_died() -> void:
	can_receive_hits = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	killed.emit()
