extends CharacterBody2D

@onready var input_component: InputComponent = $InputComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var animation_component: AnimationComponent = $AnimationComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent

func _physics_process(delta: float) -> void:
	var move_vector := get_input_vector()
	var run_pressed := input_component.is_run_pressed()

	move_component.set_move_input(move_vector)
	move_component.set_running(run_pressed)
	move_component.update_velocity(delta)
	move_and_slide()

	if input_component.is_attack_just_pressed():
		weapon_component.try_attack()

	animation_component.update_animation()

func get_input_vector() -> Vector2:
	return input_component.get_input_vector()
