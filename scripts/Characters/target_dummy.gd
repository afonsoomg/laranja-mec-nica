extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent


func _ready() -> void:
	if health_component != null:
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)


func _on_damaged(amount: int) -> void:
	print(name, " tomou ", amount, " de dano. Vida restante: ", health_component.current_health)


func _on_died() -> void:
	print(name, " morreu.")
	queue_free()
