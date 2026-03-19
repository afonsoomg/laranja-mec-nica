extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var knockback_component : KnockbackComponent = $KnockbackComponent
@onready var damage_digit_marker = $DamageDigitMarker
var damage_digit_prefab: PackedScene


func _ready() -> void:
	damage_digit_prefab= preload("res://scenes/GUI/enemies/demage_digit.tscn")
	
	
	if health_component != null:
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)
		
		
func _physics_process(delta: float) -> void:
	move_component.update_velocity(delta)
	knockback_component.update_knockback(delta)
	move_and_slide()		


func _on_damaged(amount: int) -> void:
	print(name, " tomou ", amount, " de dano. Vida restante: ", health_component.current_health)
	
	
	#Criar DamegeDigit
	var damage_digit = damage_digit_prefab.instantiate()
	damage_digit.value = amount

	if damage_digit_marker:
		damage_digit.global_position = damage_digit_marker.global_position
	else:
		damage_digit.global_position = global_position
	get_parent().add_child(damage_digit)
	


func _on_died() -> void:
	print(name, " morreu.")
	queue_free()
