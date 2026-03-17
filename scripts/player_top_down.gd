extends CharacterBody2D

@onready var input_component: InputComponent = $InputComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var animation_component: AnimationComponent = $AnimationComponent

func _physics_process(delta: float) -> void:
	move_component.set_move_input(input_component.get_input_vector())
	move_component.update_velocity(delta)
	move_and_slide()
	animation_component.update_animation()


#func process_animation() -> void:
#	if velocity != Vector2.ZERO:
#		play_animation("run", last_direction)
#	else:
#		play_animation("idle", last_direction)


#func play_animation(prefix: String, dir:Vector2) -> void:
#	if dir.x > 0:
#		animated_sprite_2d.play(prefix + "_right")
#	elif dir.x < 0:
#		animated_sprite_2d.play(prefix + "_left")
#	elif dir.y < 0:
#		animated_sprite_2d.play(prefix + "_up")
#	elif dir.y > 0:
#		animated_sprite_2d.play(prefix + "_down")
