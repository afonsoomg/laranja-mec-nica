extends CharacterBody2D

const Observability = preload("res://scripts/utils/observability.gd")
const LOG_CATEGORY := "TargetDummy"

@onready var health_component: HealthComponent = $HealthComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var knockback_component : KnockbackComponent = $KnockbackComponent


func _ready() -> void:		
	if health_component == null:
		Observability.log_error(LOG_CATEGORY, "Missing HealthComponent.")
		assert(false, "[TargetDummy] Critical setup failure: missing HealthComponent.")
		return

	Observability.connect_once_safe(health_component.damaged, _on_damaged, "TargetDummy._ready damaged")
	Observability.connect_once_safe(health_component.died, _on_died, "TargetDummy._ready died")
		
		
func _physics_process(delta: float) -> void:
	move_component.update_velocity(delta)
	knockback_component.update_knockback(delta)
	move_and_slide()		


func _on_damaged(amount: int) -> void:
	Observability.log_info(LOG_CATEGORY, "%s took %d damage. Remaining HP=%d" % [name, amount, health_component.current_health])	

func _on_died() -> void:
	Observability.log_info(LOG_CATEGORY, "%s died." % name)
	queue_free()
