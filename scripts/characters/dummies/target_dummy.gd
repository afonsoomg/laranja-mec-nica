extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var knockback_component : KnockbackComponent = $KnockbackComponent


func _ready() -> void:		
	if health_component != null:
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)
		
		
func _physics_process(delta: float) -> void:
	move_component.update_velocity(delta)
	knockback_component.update_knockback(delta)
	move_and_slide()		


func _on_damaged(amount: int) -> void:
	print(name, " tomou ", amount, " de dano. Vida restante: ", health_component.current_health)
	

func _on_died() -> void:
	print(name, " morreu.")
	queue_free()
