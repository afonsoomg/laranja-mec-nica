extends CharacterBody2D

@onready var input_component: InputComponent = $InputComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var animation_component: AnimationComponent = $AnimationComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var knockback_component : KnockbackComponent = $KnockbackComponent
@onready var health_component : HealthComponent = $HealthComponent

func _physics_process(delta: float) -> void:
	var move_vector := get_input_vector()
	var run_pressed := input_component.is_run_pressed()

	move_component.set_move_input(move_vector)
	move_component.set_running(run_pressed)
	move_component.update_velocity(delta)
	knockback_component.update_knockback(delta)
	move_and_slide()

	if input_component.is_attack_just_pressed():
		weapon_component.try_attack()

	animation_component.update_animation()

func get_input_vector() -> Vector2:
	return input_component.get_input_vector()

func _ready() -> void:
	if not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)

func _on_died() -> void:
	move_component.can_move = false
	move_component.stop()
