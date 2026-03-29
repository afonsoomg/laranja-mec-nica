extends EnemyBase
class_name EnemyShooter

func _physics_process(delta: float) -> void:
	if is_dead or not is_active:
		return

	if ai_component == null or move_component == null:
		return

	ai_component.update_ai(global_position)

	move_component.set_move_input(Vector2.ZERO)
	move_component.set_running(false)
	move_component.update_velocity(delta)

	var aim_dir := ai_component.get_aim_direction(global_position)
	if aim_dir != Vector2.ZERO:
		move_component.facing_direction = aim_dir

	var current_target: Node = ai_component.get_target()
	if ranged_weapon_component != null and current_target != null:
		ranged_weapon_component.update_spawn_marker_towards_target(current_target.global_position)

	if ai_component.should_attack():
		if ranged_weapon_component != null and not ranged_weapon_component.is_busy_attacking():
			ranged_weapon_component.try_shoot(aim_dir)

	if animation_component != null:
		animation_component.update_animation()

	super._physics_process(delta)
