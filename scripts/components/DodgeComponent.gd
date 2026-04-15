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

var is_dodging: bool = false
var dodge_direction: Vector2 = Vector2.ZERO
var _cooldown_until_msec: int = 0
var _i_frames_active: bool = false
var _movement_locked_by_dodge: bool = false
var _active_tween: Tween
var _owner_body: CharacterBody2D

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

	var target_position : Vector2 = _owner_body.global_position + (dodge_direction * max(dodge_distance, 0.0))
	_active_tween = _owner_body.create_tween()
	_active_tween.set_trans(dodge_transition).set_ease(dodge_ease)
	_active_tween.tween_property(_owner_body, "global_position", target_position, max(dodge_duration, 0.01))
	_active_tween.finished.connect(_on_tween_finished)

	return true

func finish_dodge() -> void:
	if not is_dodging:
		return

	if _active_tween != null:
		_active_tween.kill()
		_active_tween = null

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


func _on_tween_finished() -> void:
	finish_dodge()
