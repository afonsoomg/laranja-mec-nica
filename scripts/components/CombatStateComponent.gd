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

@export_group("Heavy Charge")
@export var default_max_charge_time: float = 1.0

enum CombatPhase {
	IDLE,
	ATTACK_STARTUP,
	ATTACK_HIT_WINDOW,
	ATTACK_RECOVERY,
	ATTACK_CHARGE_STARTUP,
	ATTACK_CHARGING,
	ATTACK_HEAVY_RELEASE_STARTUP,
	DODGING
}

var current_phase: CombatPhase = CombatPhase.IDLE
var current_attack_direction: Vector2 = Vector2.DOWN
var _attack_animation_finished: bool = false
var _attack_interrupted: bool = false
var _attack_token: int = 0
var _charge_elapsed: float = 0.0
var _charge_max_time: float = 1.0
var _charge_max_logged: bool = false
var _active_attack_data: Dictionary = {}

var is_attacking: bool:
	get:
		return current_phase == CombatPhase.ATTACK_STARTUP \
			or current_phase == CombatPhase.ATTACK_HEAVY_RELEASE_STARTUP \
			or current_phase == CombatPhase.ATTACK_HIT_WINDOW \
			or current_phase == CombatPhase.ATTACK_RECOVERY


var is_charging: bool:
	get:
		return current_phase == CombatPhase.ATTACK_CHARGE_STARTUP \
			or current_phase == CombatPhase.ATTACK_CHARGING


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

	current_attack_direction = _get_valid_direction(dir)
	_prepare_attack_state()
	_active_attack_data.clear()

	attack_requested.emit(current_attack_direction)
	_transition_to(CombatPhase.ATTACK_STARTUP, "request_attack")
	attack_started.emit(current_attack_direction)

	weapon_component.begin_attack(current_attack_direction)
	animation_component.play_attack_directional(current_attack_direction)
	return true


func request_charge_start(dir: Vector2, max_charge_time: float = -1.0) -> bool:
	if not can_start_attack():
		return false

	if weapon_component == null or animation_component == null or stats_component == null:
		return false

	current_attack_direction = _get_valid_direction(dir)
	_prepare_attack_state()
	_active_attack_data.clear()
	_charge_elapsed = 0.0
	_charge_max_logged = false
	_charge_max_time = max(max_charge_time, default_max_charge_time)
	if _charge_max_time <= 0.0:
		_charge_max_time = 0.01

	_transition_to(CombatPhase.ATTACK_CHARGE_STARTUP, "charge_start")
	animation_component.play_charge_start_directional(current_attack_direction)

	DebugHelper.trace(
		"Combat",
		get_parent(),
		"charge_start",
		{
			"direction": current_attack_direction,
			"max_charge_time": _charge_max_time
		}
	)
	return true


func update_charge(delta: float, held: bool) -> void:
	if not is_charging:
		return

	if current_phase == CombatPhase.ATTACK_CHARGE_STARTUP:
		if not held:
			return
		_transition_to(CombatPhase.ATTACK_CHARGING, "charge_hold")
		if animation_component != null:
			animation_component.play_charge_hold_directional(current_attack_direction)

	if current_phase != CombatPhase.ATTACK_CHARGING:
		return

	if not held:
		return
	
	_charge_elapsed = min(_charge_elapsed + max(delta, 0.0), _charge_max_time)

	if not _charge_max_logged and is_equal_approx(_charge_elapsed, _charge_max_time):
		_charge_max_logged = true
		DebugHelper.trace(
			"Combat",
			get_parent(),
			"charge_max_reached",
			{
				"charge_elapsed": _charge_elapsed,
				"charge_ratio": get_charge_ratio()
			}
		)


func release_charged_attack(charge_ratio: float = -1.0, runtime_attack_data: Dictionary = {}) -> bool:
	if not is_charging:
		return false

	if weapon_component == null or animation_component == null:
		return false

	_prepare_attack_state()
	var ratio := clampf(charge_ratio if charge_ratio >= 0.0 else get_charge_ratio(), 0.0, 1.0)
	_active_attack_data = runtime_attack_data.duplicate(true)
	_active_attack_data["charge_ratio"] = ratio

	attack_requested.emit(current_attack_direction)
	_transition_to(CombatPhase.ATTACK_HEAVY_RELEASE_STARTUP, "heavy_release")
	attack_started.emit(current_attack_direction)

	weapon_component.begin_attack(current_attack_direction, _active_attack_data)
	animation_component.play_heavy_release_directional(current_attack_direction)
	
		
	DebugHelper.trace(
		"Combat",
		get_parent(),
		"heavy_release",
		{
			"direction": current_attack_direction,
			"charge_ratio": ratio,
			"attack_data": _active_attack_data
		}
	)
	return true


func cancel_attack_or_charge(reason: String = "cancelled") -> void:
	if not is_attacking and not is_charging:
		return

	DebugHelper.trace(
		"Combat",
		get_parent(),
		"attack_or_charge_cancelled",
		{
			"reason": reason,
			"phase": get_phase_name(),
			"direction": current_attack_direction
		}
	)
	_attack_interrupted = true
	_attack_token += 1
	_charge_elapsed = 0.0
	_charge_max_logged = false
	_active_attack_data.clear()

	if weapon_component != null:
		weapon_component.cancel_attack()

	if animation_component != null:
		animation_component.cancel_attack_animation()

	_transition_to(CombatPhase.IDLE, reason)
	attack_cancelled.emit(reason)
	

func interrupt_attack(reason: String = "interrupted") -> void:
	cancel_attack_or_charge(reason)
	
func finish_attack() -> void:
	if not is_attacking:
		return

	_attack_token += 1
	_charge_elapsed = 0.0
	_charge_max_logged = false
	_active_attack_data.clear()

	if weapon_component != null:
		weapon_component.cancel_attack()
	if animation_component != null:
		animation_component.cancel_attack_animation()
		
	_transition_to(CombatPhase.IDLE, "finish_attack")
	attack_finished.emit()


func start_dodge() -> bool:
	if current_phase == CombatPhase.DODGING:
		return false

	if is_attacking or is_charging:
		cancel_attack_or_charge("dodge_started")

	_transition_to(CombatPhase.DODGING, "start_dodge")
	dodge_started.emit()
	return true


func finish_dodge() -> void:
	if not is_dodging:
		return

	_transition_to(CombatPhase.IDLE, "finish_dodge")
	dodge_finished.emit()


func get_charge_ratio() -> float:
	if _charge_max_time <= 0.0:
		return 0.0
	return clampf(_charge_elapsed / _charge_max_time, 0.0, 1.0)


func _on_attack_hit_frame_reached(animation_name: String) -> void:
	if current_phase != CombatPhase.ATTACK_STARTUP and current_phase != CombatPhase.ATTACK_HEAVY_RELEASE_STARTUP:
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
	var hitbox_duration := weapon_component.get_active_hitbox_duration() if weapon_component != null else stats_component.hitbox_duration
	await get_tree().create_timer(hitbox_duration).timeout
	
	if token != _attack_token or _attack_interrupted:
		return

	weapon_component.disable_attack_hitbox()
	attack_hit_window_finished.emit(current_attack_direction)
	_transition_to(CombatPhase.ATTACK_RECOVERY, "hit_window_timeout")
	attack_recovery_started.emit(current_attack_direction)
	_resolve_attack_recovery(token)


func _resolve_attack_recovery(token: int) -> void:
	var recovery_duration: float = weapon_component.get_active_recovery_duration() if weapon_component != null else max(stats_component.attack_cooldown - stats_component.hitbox_duration, 0.0)
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


func _prepare_attack_state() -> void:
	_attack_token += 1
	_attack_interrupted = false
	_attack_animation_finished = false


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
		CombatPhase.ATTACK_CHARGE_STARTUP:
			return "attack_charge_startup"
		CombatPhase.ATTACK_CHARGING:
			return "attack_charging"
		CombatPhase.ATTACK_HEAVY_RELEASE_STARTUP:
			return "attack_heavy_release_startup"
		CombatPhase.DODGING:
			return "dodging"
		_:
			return "unknown"


func _is_attack_animation(animation_name: String) -> bool:
	return animation_name.begins_with("attack_") \
		or animation_name.begins_with("walk_attack_") \
		or animation_name.begins_with("run_attack_") \
		or animation_name.begins_with("heavy_release_")


func _get_valid_direction(dir: Vector2) -> Vector2:
	var quantized := _quantize_to_4_directions(dir)
	if quantized == Vector2.ZERO:
		return Vector2.DOWN
	return quantized


func _quantize_to_4_directions(dir: Vector2) -> Vector2:
	if dir == Vector2.ZERO:
		return Vector2.ZERO

	if abs(dir.x) > abs(dir.y):
		return Vector2.RIGHT if dir.x > 0.0 else Vector2.LEFT

	return Vector2.DOWN if dir.y > 0.0 else Vector2.UP
