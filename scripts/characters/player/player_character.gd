extends CharacterBase

@onready var input_component: InputComponent = $InputComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if is_dead:
		return

	var move_vector := input_component.get_input_vector()
	var run_pressed := input_component.is_run_pressed()

	move_component.set_move_input(move_vector)
	move_component.set_running(run_pressed)
	move_component.update_velocity(delta)

	move_and_slide()

	if input_component.is_attack_just_pressed():
		weapon_component.try_attack()

	animation_component.update_animation()
