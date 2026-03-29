extends CharacterBase

@export_group("Stamina")
@export var attack_stamina_cost: float = 20.0
@export var heavy_attack_stamina_cost: float = 30.0
@export var dodge_stamina_cost: float = 30.0
@export var run_stamina_cost_per_second: float = 18.0

@export_group("Heavy Attack")
@export var heavy_hold_threshold: float = 0.2
@export var heavy_max_charge_time: float = 1.0
@export var heavy_min_damage_multiplier: float = 1.35
@export var heavy_max_damage_multiplier: float = 2.2
@export var heavy_min_knockback_multiplier: float = 1.1
@export var heavy_max_knockback_multiplier: float = 1.8
@export var heavy_hitbox_duration: float = 0.18
@export var heavy_recovery_duration: float = 0.35
@export var heavy_lunge_speed: float = 120.0
@export var heavy_lunge_duration: float = 0.08

var input_component: InputComponent
var weapon_component: WeaponComponent
var stamina_component: StaminaComponent
var combat_state: CombatStateComponent
var dodge_component: DodgeComponent

var locked_attack_direction: Vector2 = Vector2.DOWN

var _attack_intent_active: bool = false
var _attack_intent_direction: Vector2 = Vector2.DOWN
var _attack_hold_elapsed: float = 0.0

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
	
	if not combat_state.attack_cancelled.is_connected(_on_attack_or_charge_cancelled):
		combat_state.attack_cancelled.connect(_on_attack_or_charge_cancelled)

	if not combat_state.attack_finished.is_connected(_on_attack_finished):
		combat_state.attack_finished.connect(_on_attack_finished)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	dodge_component.tick(delta)
	_handle_combat_input(delta)

	if combat_state.is_dodging:
		_update_locomotion_state_from_live_input()
		animation_component.update_animation()
		super._physics_process(delta)
		return

	elif combat_state.is_attacking or combat_state.is_charging:
		move_component.set_move_input(Vector2.ZERO)
		move_component.set_running(false)
		move_component.update_velocity(delta)
		animation_component.update_animation()

	else:
		var can_run := _update_locomotion_state_from_live_input()

		if can_run:
			var spent := stamina_component.spend_over_time(run_stamina_cost_per_second, delta)
			if not spent:
				move_component.set_running(false)

		move_component.update_velocity(delta)
		animation_component.update_animation()

	super._physics_process(delta)


func _handle_combat_input(delta: float) -> void:
	_handle_attack_intent(delta)

	if input_component.is_dodge_just_pressed():
		_try_start_dodge()


func _handle_attack_intent(delta: float) -> void:
	if combat_state.is_charging:
		combat_state.update_charge(delta, input_component.is_attack_pressed())
		if input_component.is_attack_just_released():
			_try_release_charged_attack()
		return

	if combat_state.is_attacking or combat_state.is_dodging:
		return

	if input_component.is_attack_just_pressed():
		_begin_attack_intent()

	if not _attack_intent_active:
		return

	if input_component.is_attack_just_released():
		if _attack_hold_elapsed < heavy_hold_threshold:
			_try_start_light_attack()
		_clear_attack_intent("tap_released")
		return

	if not input_component.is_attack_pressed():
		_clear_attack_intent("button_not_pressed")
		return

	_attack_hold_elapsed += max(delta, 0.0)
	if _attack_hold_elapsed >= heavy_hold_threshold:
		_try_start_charge()


func _begin_attack_intent() -> void:
	if not combat_state.can_start_attack():
		return

	_attack_intent_active = true
	_attack_hold_elapsed = 0.0
	_attack_intent_direction = _get_mouse_attack_direction()
	locked_attack_direction = _attack_intent_direction

	DebugHelper.trace(
		"Combat",
		self,
		"attack_press",
		{
			"direction": _attack_intent_direction,
			"heavy_hold_threshold": heavy_hold_threshold,
			"stamina": stamina_component.current_stamina
		}
	)


func _try_start_light_attack() -> void:
	if not combat_state.can_start_attack():
		return

	if not stamina_component.spend(attack_stamina_cost):
		return

	move_component.facing_direction = _attack_intent_direction
	locked_attack_direction = _attack_intent_direction

	if not combat_state.request_attack(_attack_intent_direction):
		stamina_component.restore(attack_stamina_cost)


func _try_start_charge() -> void:
	if not _attack_intent_active:
		return

	if not combat_state.can_start_attack():
		_clear_attack_intent("charge_blocked")
		return

	if not stamina_component.can_spend(heavy_attack_stamina_cost):
		DebugHelper.trace(
			"Combat",
			self,
			"heavy_cancelled",
			{
				"reason": "stamina_insufficient_for_charge",
				"stamina": stamina_component.current_stamina,
				"required": heavy_attack_stamina_cost
			}
		)
		_clear_attack_intent("stamina_failed")
		return

	move_component.facing_direction = _attack_intent_direction
	locked_attack_direction = _attack_intent_direction
	if combat_state.request_charge_start(_attack_intent_direction, heavy_max_charge_time):
		_clear_attack_intent("charge_started")


func _try_release_charged_attack() -> void:
	if not combat_state.is_charging:
		return

	if not stamina_component.spend(heavy_attack_stamina_cost):
		combat_state.cancel_attack_or_charge("stamina_failed")
		DebugHelper.trace("Combat", self, "heavy_cancelled", {"reason": "stamina_failed_on_release"})
		return

	var charge_ratio: float = combat_state.get_charge_ratio()
	var attack_data := {
		"damage_multiplier": lerpf(heavy_min_damage_multiplier, heavy_max_damage_multiplier, charge_ratio),
		"knockback_multiplier": lerpf(heavy_min_knockback_multiplier, heavy_max_knockback_multiplier, charge_ratio),
		"hitbox_duration": heavy_hitbox_duration,
		"recovery_duration": heavy_recovery_duration
	}

	if not combat_state.release_charged_attack(charge_ratio, attack_data):
		stamina_component.restore(heavy_attack_stamina_cost)
		return

	_apply_heavy_lunge(locked_attack_direction)


func _apply_heavy_lunge(direction: Vector2) -> void:
	if heavy_lunge_speed <= 0.0 or heavy_lunge_duration <= 0.0:
		return

	var lunge_dir := direction
	if lunge_dir == Vector2.ZERO:
		lunge_dir = move_component.facing_direction

	move_component.apply_forced_velocity_for_duration(lunge_dir.normalized() * heavy_lunge_speed, heavy_lunge_duration)


func _clear_attack_intent(reason: String) -> void:
	if not _attack_intent_active:
		return

	_attack_intent_active = false
	_attack_hold_elapsed = 0.0

	DebugHelper.trace("Combat", self, "attack_intent_cleared", {"reason": reason})


func _try_start_dodge() -> void:
	if combat_state.is_dodging:
		return

	if not dodge_component.can_start_dodge():
		return

	var dodge_dir := _get_dodge_direction()
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

	_clear_attack_intent("dodge_started")
	move_component.cancel_forced_velocity()
	move_component.facing_direction = dodge_dir


func _get_mouse_attack_direction() -> Vector2:
	var to_mouse := get_global_mouse_position() - global_position

	if to_mouse == Vector2.ZERO:
		return move_component.facing_direction

	return _quantize_to_4_directions(to_mouse)


func _get_dodge_direction() -> Vector2:
	var input_dir := input_component.get_input_vector()
	if input_dir != Vector2.ZERO:
		return input_dir.normalized()

	var facing_dir := _get_facing_direction()
	if facing_dir != Vector2.ZERO:
		return facing_dir.normalized()
		
	return Vector2.DOWN

func _quantize_to_4_directions(dir: Vector2) -> Vector2:
	if dir == Vector2.ZERO:
		return Vector2.ZERO

	if abs(dir.x) > abs(dir.y):
		return Vector2.RIGHT if dir.x > 0.0 else Vector2.LEFT
	else:
		return Vector2.DOWN if dir.y > 0.0 else Vector2.UP


func _get_mouse_direction(MouseOwner: Node2D) -> Vector2:
	var mouse_pos := MouseOwner.get_global_mouse_position()
	return MouseOwner.global_position.direction_to(mouse_pos).normalized()


func _get_facing_direction() -> Vector2:
	if move_component.facing_direction == Vector2.ZERO:
		return Vector2.DOWN
	return move_component.facing_direction.normalized()


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
	if combat_state != null and (combat_state.is_attacking or combat_state.is_charging):
		combat_state.cancel_attack_or_charge("dodge_started")


func _on_dodge_finished() -> void:
	pass


func _on_component_dodge_finished() -> void:
	_update_locomotion_state_from_live_input()
	
	if combat_state != null:
		combat_state.finish_dodge()


func _on_attack_or_charge_cancelled(reason: String) -> void:
	_clear_attack_intent("combat_cancelled_%s" % reason)
	move_component.cancel_forced_velocity()
	DebugHelper.trace("Combat", self, "heavy_cancelled", {"reason": reason})


func _on_attack_finished() -> void:
	move_component.cancel_forced_velocity()
	

func _update_locomotion_state_from_live_input() -> bool:
	var input_dir: Vector2 = input_component.get_input_vector()
	var has_movement := input_dir != Vector2.ZERO
	var wants_run := input_component.is_run_pressed() and has_movement
	var can_run := wants_run and stamina_component.current_stamina > 0.0

	move_component.set_move_input(input_dir)
	move_component.set_running(can_run)
	return can_run
