extends Node
class_name CombatStateComponent

signal combat_transitioned(previous_state: String, next_state: String, reason: String)
signal attack_requested(direction: Vector2)
signal attack_started(direction: Vector2)
signal attack_hit_window_started(direction: Vector2)
signal attack_hit_window_finished(direction: Vector2)
signal attack_recovery_started(direction: Vector2)
signal attack_finished
signal attack_cancelled(reason: String)
signal dodge_started
signal dodge_finished

@export_group("Component References")
@export var weapon_component: WeaponComponent
@export var animation_component: AnimationComponent
@export var stats_component: StatsComponent

enum CombatPhase {
	IDLE,
	ATTACK_STARTUP,
	ATTACK_HIT_WINDOW,
	ATTACK_RECOVERY,
	DODGING
}

var current_phase: CombatPhase = CombatPhase.IDLE
var current_attack_direction: Vector2 = Vector2.DOWN
var _attack_animation_finished: bool = false
var _attack_interrupted: bool = false
var _attack_token: int = 0

var is_attacking: bool:
	get:
		return current_phase == CombatPhase.ATTACK_STARTUP \
			or current_phase == CombatPhase.ATTACK_HIT_WINDOW \
			or current_phase == CombatPhase.ATTACK_RECOVERY

var is_dodging: bool:
	get:
		return current_phase == CombatPhase.DODGING


func _ready() -> void:
	if weapon_component == null:
		weapon_component = get_node_or_null("../WeaponComponent") as WeaponComponent

	if animation_component == null:
		animation_component = get_node_or_null("../AnimationComponent") as AnimationComponent

	if stats_component == null and weapon_component != null:
		stats_component = weapon_component.stats_component

	if animation_component != null and not animation_component.animation_finished.is_connected(_on_animation_finished):
		animation_component.animation_finished.connect(_on_animation_finished)

	if animation_component != null and not animation_component.attack_hit_frame_reached.is_connected(_on_attack_hit_frame_reached):
		animation_component.attack_hit_frame_reached.connect(_on_attack_hit_frame_reached)


func can_start_attack() -> bool:
	if current_phase != CombatPhase.IDLE:
		return false

	if animation_component != null and not animation_component.can_attack():
		return false

	return true


func request_attack(dir: Vector2) -> bool:
	if not can_start_attack():
		DebugHelper.trace(
			"Combat",
			get_parent(),
			"attack_request_blocked",
			{
				"reason": "cannot_start_attack",
				"phase": get_phase_name(),
				"animation_can_attack": animation_component.can_attack() if animation_component != null else false
			}
		)
		return false

	if weapon_component == null or animation_component == null or stats_component == null:
		return false

	current_attack_direction = _quantize_to_4_directions(dir)
	if current_attack_direction == Vector2.ZERO:
		current_attack_direction = Vector2.DOWN

	_attack_token += 1
	_attack_interrupted = false
	_attack_animation_finished = false

	attack_requested.emit(current_attack_direction)
	_transition_to(CombatPhase.ATTACK_STARTUP, "request_attack")
	attack_started.emit(current_attack_direction)

	weapon_component.begin_attack(current_attack_direction)
	animation_component.play_attack_directional(current_attack_direction)
	return true


func interrupt_attack(reason: String = "interrupted") -> void:
	if not is_attacking:
		return
		
	DebugHelper.trace(
		"Combat",
		get_parent(),
		"attack_interrupted",
		{
			"reason": reason,
			"phase": get_phase_name(),
			"direction": current_attack_direction
		}
	)
		
	_attack_interrupted = true
	_attack_token += 1
	weapon_component.cancel_attack()
	animation_component.cancel_attack_animation()
	_transition_to(CombatPhase.IDLE, reason)
	attack_cancelled.emit(reason)


func finish_attack() -> void:
	if not is_attacking:
		return

	_attack_token += 1
	weapon_component.cancel_attack()
	animation_component.cancel_attack_animation()
	_transition_to(CombatPhase.IDLE, "finish_attack")
	attack_finished.emit()


func start_dodge() -> bool:
	if current_phase == CombatPhase.DODGING:
		return false

	if is_attacking:
		interrupt_attack("dodge_started")

	_transition_to(CombatPhase.DODGING, "start_dodge")
	dodge_started.emit()
	return true


func finish_dodge() -> void:
	if not is_dodging:
		return

	_transition_to(CombatPhase.IDLE, "finish_dodge")
	dodge_finished.emit()


func _on_attack_hit_frame_reached(animation_name: String) -> void:
	if current_phase != CombatPhase.ATTACK_STARTUP:
		return

	if not _is_attack_animation(animation_name):
		return

	if _attack_interrupted:
		return

	var token := _attack_token
	_transition_to(CombatPhase.ATTACK_HIT_WINDOW, "hit_frame")
	attack_hit_window_started.emit(current_attack_direction)
	weapon_component.enable_attack_hitbox()
	_resolve_attack_hit_window(token)


func _resolve_attack_hit_window(token: int) -> void:
	await get_tree().create_timer(stats_component.hitbox_duration).timeout

	if token != _attack_token or _attack_interrupted:
		return

	weapon_component.disable_attack_hitbox()
	attack_hit_window_finished.emit(current_attack_direction)
	_transition_to(CombatPhase.ATTACK_RECOVERY, "hit_window_timeout")
	attack_recovery_started.emit(current_attack_direction)
	_resolve_attack_recovery(token)


func _resolve_attack_recovery(token: int) -> void:
	var recovery_duration: float = max(stats_component.attack_cooldown - stats_component.hitbox_duration, 0.0)
	if recovery_duration > 0.0:
		await get_tree().create_timer(recovery_duration).timeout

	if token != _attack_token or _attack_interrupted:
		return

	if _attack_animation_finished:
		finish_attack()


func _on_animation_finished(animation_name: String) -> void:
	if not _is_attack_animation(animation_name):
		return

	if not is_attacking:
		return

	_attack_animation_finished = true
	if current_phase == CombatPhase.ATTACK_RECOVERY:
		finish_attack()


func _transition_to(next_phase: CombatPhase, reason: String) -> void:
	if current_phase == next_phase:
		return

	var previous_name := get_phase_name(current_phase)
	current_phase = next_phase
	var next_name := get_phase_name(current_phase)
	print("[CombatState] %s -> %s | reason=%s" % [previous_name, next_name, reason])
	combat_transitioned.emit(previous_name, next_name, reason)


func get_phase_name(phase: CombatPhase = current_phase) -> String:
	match phase:
		CombatPhase.IDLE:
			return "idle"
		CombatPhase.ATTACK_STARTUP:
			return "attack_startup"
		CombatPhase.ATTACK_HIT_WINDOW:
			return "attack_hit_window"
		CombatPhase.ATTACK_RECOVERY:
			return "attack_recovery"
		CombatPhase.DODGING:
			return "dodging"
		_:
			return "unknown"


func _is_attack_animation(animation_name: String) -> bool:
	return animation_name.begins_with("attack_") \
		or animation_name.begins_with("walk_attack_") \
		or animation_name.begins_with("run_attack_")


func _quantize_to_4_directions(dir: Vector2) -> Vector2:
	if dir == Vector2.ZERO:
		return Vector2.ZERO

	if abs(dir.x) > abs(dir.y):
		return Vector2.RIGHT if dir.x > 0.0 else Vector2.LEFT

	return Vector2.DOWN if dir.y > 0.0 else Vector2.UP
