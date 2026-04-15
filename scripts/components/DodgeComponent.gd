extends Node
class_name DodgeComponent

signal dodge_started
signal dodge_finished
signal i_frames_started
signal i_frames_finished

@export var move_component: MoveComponent
@export var combat_state_component: CombatStateComponent
@export var hurtbox_component: HurtboxComponent
@export var animation_component: AnimationComponent

@export var dodge_duration: float = 0.18
@export var dodge_distance: float = 64.0
@export var dodge_cooldown: float = 0.35
@export var dodge_transition: Tween.TransitionType = Tween.TRANS_CUBIC
@export var dodge_ease: Tween.EaseType = Tween.EASE_OUT
@export var lock_input_during_dodge: bool = true
@export var invulnerability_duration: float = 0.12
@export_range(0.1, 10.0, 0.1) var stuck_abort_speed_threshold: float = 8.0
@export_range(1, 10, 1) var stuck_abort_frames: int = 3

var is_dodging: bool = false
var dodge_direction: Vector2 = Vector2.ZERO
var _cooldown_until_msec: int = 0
var _i_frames_active: bool = false
var _movement_locked_by_dodge: bool = false
var _owner_body: CharacterBody2D
var _dodge_elapsed: float = 0.0
var _last_position: Vector2 = Vector2.ZERO
var _stuck_frames: int = 0

func _ready() -> void:
	_owner_body = get_parent() as CharacterBody2D
	
	if move_component == null:
		move_component = get_node_or_null("../MoveComponent") as MoveComponent
		
	if combat_state_component == null:
		combat_state_component = get_node_or_null("../CombatStateComponent") as CombatStateComponent

	if hurtbox_component == null:
		hurtbox_component = get_node_or_null("../HurtboxComponent") as HurtboxComponent
		
	if animation_component == null:
		animation_component = get_node_or_null("../AnimationComponent") as AnimationComponent

func can_start_dodge() -> bool:
	if is_dodging:
		return false

	if Time.get_ticks_msec() < _cooldown_until_msec:
		return false

	if move_component == null or _owner_body == null:
		return false

	if combat_state_component != null and combat_state_component.current_phase != CombatStateComponent.CombatPhase.IDLE:
		return false

	return true

func start_dodge(dir: Vector2) -> bool:
	if not can_start_dodge():
		return false

	if dir == Vector2.ZERO:
		return false

	if combat_state_component != null and not combat_state_component.start_dodge():
		return false

	is_dodging = true
	dodge_direction = dir.normalized()
	_i_frames_active = invulnerability_duration > 0.0
	_dodge_elapsed = 0.0
	_last_position = _owner_body.global_position
	_stuck_frames = 0

	move_component.facing_direction = dodge_direction
	move_component.cancel_forced_velocity()
	move_component.stop()

	if lock_input_during_dodge:
		move_component.can_move = false
		_movement_locked_by_dodge = true

	dodge_started.emit()

	if _i_frames_active:
		if hurtbox_component != null:
			hurtbox_component.set_dodge_invulnerable(true)
		i_frames_started.emit()
		_schedule_i_frames_end()

	if animation_component != null:
		animation_component.play_dodge_directional(dodge_direction)

	return true

func tick_physics(delta: float) -> void:
	if not is_dodging:
		return

	if _owner_body == null or move_component == null:
		finish_dodge()
		return

	var duration : float = max(dodge_duration, 0.01)
	var distance : float = max(dodge_distance, 0.0)
	var previous_progress := clampf(_dodge_elapsed / duration, 0.0, 1.0)

	_dodge_elapsed = min(_dodge_elapsed + max(delta, 0.0), duration)
	var progress := clampf(_dodge_elapsed / duration, 0.0, 1.0)

	var previous_curve := _ease_sample(previous_progress)
	var current_curve := _ease_sample(progress)
	var desired_step := dodge_direction * ((current_curve - previous_curve) * distance)
	var desired_speed : Vector2 = desired_step / max(delta, 0.0001)

	move_component.set_move_input(Vector2.ZERO)
	move_component.set_running(false)
	move_component.set_forced_velocity(desired_speed)
	move_component.update_velocity(delta)

	var moved_distance := _owner_body.global_position.distance_to(_last_position)
	_last_position = _owner_body.global_position

	if desired_step.length() > 0.001 and moved_distance < (stuck_abort_speed_threshold * max(delta, 0.0001)):
		_stuck_frames += 1
	else:
		_stuck_frames = 0

	if _stuck_frames >= max(stuck_abort_frames, 1):
		finish_dodge()
		return

	if is_equal_approx(progress, 1.0):
		finish_dodge()


func finish_dodge() -> void:
	if not is_dodging:
		return

	_cooldown_until_msec = Time.get_ticks_msec() + int(max(dodge_cooldown, 0.0) * 1000.0)
	is_dodging = false

	if move_component != null:
		move_component.clear_forced_velocity()
		move_component.stop()
		if _movement_locked_by_dodge:
			move_component.can_move = true
			_movement_locked_by_dodge = false

	if _i_frames_active:
		_i_frames_active = false
		if hurtbox_component != null:
			hurtbox_component.set_dodge_invulnerable(false)
		i_frames_finished.emit()

	dodge_direction = Vector2.ZERO
	_dodge_elapsed = 0.0
	_stuck_frames = 0

	if combat_state_component != null:
		combat_state_component.finish_dodge()

	dodge_finished.emit()

func is_invulnerable() -> bool:
	return is_dodging and _i_frames_active


func force_stop(reason: String = "forced_stop") -> void:
	if not is_dodging:
		return

	DebugHelper.trace("Combat", get_parent(), "dodge_force_stop", {"reason": reason})
	finish_dodge()


func _schedule_i_frames_end() -> void:
	var token_direction := dodge_direction
	await get_tree().create_timer(max(invulnerability_duration, 0.0)).timeout

	if not is_dodging:
		return

	if dodge_direction != token_direction:
		return

	if not _i_frames_active:
		return

	_i_frames_active = false
	if hurtbox_component != null:
		hurtbox_component.set_dodge_invulnerable(false)
	i_frames_finished.emit()


func _ease_sample(progress: float) -> float:
	var p := clampf(progress, 0.0, 1.0)

	match dodge_transition:
		Tween.TRANS_SINE:
			match dodge_ease:
				Tween.EASE_IN:
					return 1.0 - cos((p * PI) / 2.0)
				Tween.EASE_OUT:
					return sin((p * PI) / 2.0)
				_:
					return -(cos(PI * p) - 1.0) / 2.0
		Tween.TRANS_QUAD:
			match dodge_ease:
				Tween.EASE_IN:
					return p * p
				Tween.EASE_OUT:
					return 1.0 - (1.0 - p) * (1.0 - p)
				_:
					return 2.0 * p * p if p < 0.5 else 1.0 - pow(-2.0 * p + 2.0, 2.0) / 2.0
		Tween.TRANS_CUBIC:
			match dodge_ease:
				Tween.EASE_IN:
					return p * p * p
				Tween.EASE_OUT:
					return 1.0 - pow(1.0 - p, 3.0)
				_:
					return 4.0 * p * p * p if p < 0.5 else 1.0 - pow(-2.0 * p + 2.0, 3.0) / 2.0
		_:
			match dodge_ease:
				Tween.EASE_IN:
					return p
				Tween.EASE_OUT:
					return 1.0 - (1.0 - p)
				_:
					return p
