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

	# Mira no alvo
	var aim_dir := ai_component.get_aim_direction(global_position)
	if aim_dir != Vector2.ZERO:
		move_component.facing_direction = aim_dir

	# Atira automaticamente quando o alvo entra no range de ataque
	if ai_component.should_attack():
		if ranged_weapon_component != null:
			ranged_weapon_component.try_shoot(aim_dir)

	if animation_component != null:
		animation_component.update_animation()

	super._physics_process(delta)
