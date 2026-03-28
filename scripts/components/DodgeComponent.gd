extends Node
class_name DodgeComponent

signal dodge_started
signal dodge_finished
signal i_frames_started
signal i_frames_finished

@export var move_component: MoveComponent
@export var duration: float = 0.22
@export var start_speed: float = 420.0
@export var end_speed: float = 80.0
@export var cooldown: float = 0.35

@export var invulnerability_duration: float = 0.12

var is_dodging: bool = false
var dodge_direction: Vector2 = Vector2.ZERO
var _cooldown_timer: float = 0.0
var _timer: float = 0.0
var _i_frames_active: bool = false

func tick(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer = max(_cooldown_timer - delta, 0.0)

	if not is_dodging:
		return

	_timer -= delta

	var elapsed := duration - _timer
	var progress := 0.0
	if duration > 0.0:
		progress = clamp(elapsed / duration, 0.0, 1.0)

	var eased_t := 1.0 - pow(1.0 - progress, 3.0)
	var current_speed: float = lerp(start_speed, end_speed, eased_t)

	if move_component != null:
		move_component.set_forced_velocity(dodge_direction * current_speed)
		move_component.update_velocity(delta)

	if _i_frames_active and elapsed >= invulnerability_duration:
		_i_frames_active = false
		i_frames_finished.emit()

	if _timer <= 0.0:
		finish_dodge()

func can_start_dodge() -> bool:
	if is_dodging:
		return false

	if _cooldown_timer > 0.0:
		return false

	if move_component == null:
		return false

	return true

func start_dodge(dir: Vector2) -> bool:
	if not can_start_dodge():
		return false

	if dir == Vector2.ZERO:
		return false

	is_dodging = true
	dodge_direction = dir.normalized()
	_timer = duration
	_i_frames_active = invulnerability_duration > 0.0

	move_component.facing_direction = dodge_direction

	dodge_started.emit()

	if _i_frames_active:
		i_frames_started.emit()

	return true

func finish_dodge() -> void:
	if not is_dodging:
		return

	_cooldown_timer = cooldown
	is_dodging = false

	if move_component != null:
		move_component.clear_forced_velocity()

	if _i_frames_active:
		_i_frames_active = false
		i_frames_finished.emit()

	dodge_direction = Vector2.ZERO
	_timer = 0.0

	dodge_finished.emit()

func is_invulnerable() -> bool:
	return is_dodging and _i_frames_active
