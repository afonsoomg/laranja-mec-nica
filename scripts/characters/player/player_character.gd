extends CharacterBase

@export var attack_stamina_cost: float = 20.0
@export var dodge_stamina_cost: float = 30.0
@export var run_stamina_cost_per_second: float = 18.0

@onready var input_component: InputComponent = $InputComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var combat_state: CombatStateComponent = $CombatStateComponent
@onready var dodge_component: DodgeComponent = $DodgeComponent

var locked_attack_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	super._ready()
	add_to_group("player")

	if weapon_component != null and audio_component != null:
		if not weapon_component.attack_started.is_connected(_on_attack_started):
			weapon_component.attack_started.connect(_on_attack_started)

	if animated_sprite and not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

	if combat_state != null:
		combat_state.dodge_started.connect(_on_dodge_started)
		combat_state.dodge_finished.connect(_on_dodge_finished)

	if dodge_component != null:
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

	if animation_component.is_hurt and combat_state.is_attacking:
		_cancel_attack_state()

func _handle_combat_input() -> void:
	if input_component.is_attack_just_pressed():
		_try_start_attack()

	if input_component.is_dodge_just_pressed():
		_try_start_dodge()

func _try_start_attack() -> void:
	if weapon_component == null or animation_component == null or stamina_component == null:
		return

	if weapon_component.pending_attack or weapon_component.is_attacking:
		return

	if animation_component.is_attacking or animation_component.is_hurt or animation_component.is_dying:
		return

	if not combat_state.can_start_attack():
		return

	if not stamina_component.spend(attack_stamina_cost):
		return

	var attack_dir := _get_mouse_attack_direction()
	move_component.facing_direction = attack_dir
	locked_attack_direction = attack_dir

	if not combat_state.start_attack():
		return

	weapon_component.request_attack(attack_dir)

func _try_start_dodge() -> void:
	if dodge_component == null or stamina_component == null:
		return

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

func _cancel_attack_state() -> void:
	if weapon_component != null:
		weapon_component.cancel_attack()

	if combat_state != null:
		combat_state.cancel_attack()

	if animation_component != null:
		animation_component.is_attacking = false
		animation_component.locked_action_animation = ""

func collect_collectable(collectable: CollectableBase) -> void:
	if collectable == null:
		return

	var collected_successfully := collectable.apply_to_collector(self)

	if collected_successfully:
		collectable.on_collected(self)

func _on_attack_started() -> void:
	if audio_component:
		audio_component.play_attack()

func _on_animation_finished() -> void:
	if animated_sprite.animation.begins_with("attack_"):
		combat_state.finish_attack()

func _on_dodge_started() -> void:
	if weapon_component != null:
		weapon_component.cancel_attack()

	if combat_state != null:
		combat_state.cancel_attack()

	if animation_component != null:
		animation_component.is_attacking = false
		animation_component.locked_action_animation = ""

func _on_dodge_finished() -> void:
	pass

func _on_component_dodge_finished() -> void:
	combat_state.finish_dodge()
