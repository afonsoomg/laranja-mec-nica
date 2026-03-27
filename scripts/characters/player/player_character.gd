extends CharacterBase

@export var attack_stamina_cost: float = 20.0
@export var dodge_stamina_cost: float = 30.0
@export var run_stamina_cost_per_second: float = 18.0

var input_component: InputComponent
var weapon_component: WeaponComponent
var stamina_component: StaminaComponent
var combat_state: CombatStateComponent
var dodge_component: DodgeComponent

var locked_attack_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	super._ready()
	
	if not ComponentValidator.require_nodes(self, [
		{"path": NodePath("InputComponent"), "expected_type": "InputComponent", "name": "InputComponent", "assign_to": "input_component"},
		{"path": NodePath("WeaponComponent"), "expected_type": "WeaponComponent", "name": "WeaponComponent", "assign_to": "weapon_component"},
		{"path": NodePath("StaminaComponent"), "expected_type": "StaminaComponent", "name": "StaminaComponent", "assign_to": "stamina_component"},
		{"path": NodePath("CombatStateComponent"), "expected_type": "CombatStateComponent", "name": "CombatStateComponent", "assign_to": "combat_state"},
		{"path": NodePath("DodgeComponent"), "expected_type": "DodgeComponent", "name": "DodgeComponent", "assign_to": "dodge_component"},
	]):
		set_physics_process(false)
		return
		
	add_to_group("player")

	if not weapon_component.attack_started.is_connected(_on_attack_started):
		weapon_component.attack_started.connect(_on_attack_started)

	if not combat_state.dodge_started.is_connected(_on_dodge_started):
		combat_state.dodge_started.connect(_on_dodge_started)
		
	if not combat_state.dodge_finished.is_connected(_on_dodge_finished):
		combat_state.dodge_finished.connect(_on_dodge_finished)

	if not dodge_component.dodge_finished.is_connected(_on_component_dodge_finished):
		dodge_component.dodge_finished.connect(_on_component_dodge_finished)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	dodge_component.tick(delta)
	_handle_combat_input()

	if combat_state.is_dodging:
		animation_component.update_animation()
		super._physics_process(delta)
		return

	elif combat_state.is_attacking:
		move_component.set_move_input(Vector2.ZERO)
		move_component.set_running(false)
		move_component.update_velocity(delta)
		animation_component.update_animation()

	else:
		var input_dir: Vector2 = input_component.get_input_vector()
		var wants_run := input_component.is_run_pressed() and input_dir != Vector2.ZERO
		var can_run := wants_run and stamina_component.current_stamina > 0.0

		move_component.set_move_input(input_dir)
		move_component.set_running(can_run)

		if can_run:
			var spent := stamina_component.spend_over_time(run_stamina_cost_per_second, delta)
			if not spent:
				move_component.set_running(false)

		move_component.update_velocity(delta)
		animation_component.update_animation()

	super._physics_process(delta)


func _handle_combat_input() -> void:
	if input_component.is_attack_just_pressed():
		_try_start_attack()

	if input_component.is_dodge_just_pressed():
		_try_start_dodge()


func _try_start_attack() -> void:
	if not combat_state.can_start_attack():
		return

	if not stamina_component.spend(attack_stamina_cost):
		return

	var attack_dir := _get_mouse_attack_direction()
	move_component.facing_direction = attack_dir
	locked_attack_direction = attack_dir

	if not combat_state.request_attack(attack_dir):
		stamina_component.restore(attack_stamina_cost)


func _try_start_dodge() -> void:
	if combat_state.is_dodging:
		return

	if not dodge_component.can_start_dodge():
		return

	var dodge_dir := _get_mouse_dodge_direction()
	if dodge_dir == Vector2.ZERO:
		return

	if not stamina_component.can_spend(dodge_stamina_cost):
		return

	if not combat_state.start_dodge():
		return

	if not dodge_component.start_dodge(dodge_dir):
		combat_state.finish_dodge()
		return

	if not stamina_component.spend(dodge_stamina_cost):
		dodge_component.finish_dodge()
		combat_state.finish_dodge()
		return

	move_component.facing_direction = dodge_dir


func _get_mouse_attack_direction() -> Vector2:
	var to_mouse := get_global_mouse_position() - global_position

	if to_mouse == Vector2.ZERO:
		return move_component.facing_direction

	return _quantize_to_4_directions(to_mouse)


func _get_mouse_dodge_direction() -> Vector2:
	var to_mouse := get_global_mouse_position() - global_position

	if to_mouse == Vector2.ZERO:
		if move_component.facing_direction != Vector2.ZERO:
			return _quantize_to_4_directions(move_component.facing_direction)
		return Vector2.DOWN

	return _quantize_to_4_directions(to_mouse)


func _quantize_to_4_directions(dir: Vector2) -> Vector2:
	if dir == Vector2.ZERO:
		return Vector2.ZERO

	if abs(dir.x) > abs(dir.y):
		return Vector2.RIGHT if dir.x > 0.0 else Vector2.LEFT
	else:
		return Vector2.DOWN if dir.y > 0.0 else Vector2.UP


func collect_collectable(collectable: CollectableBase) -> void:
	if collectable == null:
		return

	var collected_successfully := collectable.apply_to_collector(self)

	if collected_successfully:
		collectable.on_collected(self)


func _on_attack_started(_direction: Vector2) -> void:
	if audio_component:
		audio_component.play_attack()


func _on_dodge_started() -> void:
	if combat_state != null and combat_state.is_attacking:
		combat_state.interrupt_attack("dodge_started")


func _on_dodge_finished() -> void:
	pass


func _on_component_dodge_finished() -> void:
	if combat_state != null:
		combat_state.finish_dodge()
