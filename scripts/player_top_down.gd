extends CharacterBody2D

@onready var input_component: InputComponent = $InputComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var animation_component: AnimationComponent = $AnimationComponent

func _physics_process(delta: float) -> void:
	var move_vector := input_component.get_input_vector()
	var run_pressed := input_component.is_run_pressed()

	#print("run_pressed:", run_pressed)

	move_component.set_move_input(move_vector)
	move_component.set_running(run_pressed)
	move_component.update_velocity(delta)
	move_and_slide()

	if input_component.is_attack_just_pressed():
		animation_component.play_attack()

	animation_component.update_animation()
