extends Node
class_name AnimationComponent

signal animation_finished(animation_name: String)
signal attack_hit_frame_reached(animation_name: String)

@export var move_component: MoveComponent
@export var animated_sprite: AnimatedSprite2D

@export var attack_active_frame: int = 1
@export var hurt_timeout_padding_seconds: float = 0.15

var current_facing: String = "down"
var action_facing: String = "down"
var locked_action_animation: String = ""
var locked_action_kind: String = ""
var dying_animation_finished: bool = false

var is_hurt: bool = false
var is_dying: bool = false
var _hurt_recovery_token: int = 0


func _ready() -> void:
	if animated_sprite == null:
		push_error("AnimationComponent precisa de um AnimatedSprite2D.")
		return
		
	if move_component == null:
		push_error("AnimationComponent precisa de um MoveComponent.")
		return
		
	if animated_sprite != null:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.frame_changed.connect(_on_frame_changed)


func update_animation() -> void:
	if animated_sprite == null or move_component == null:
		return

	if not _is_action_locked() and not is_hurt and not is_dying:
		_update_facing()

	if is_dying:
		if not dying_animation_finished:
			_play_if_needed(locked_action_animation)
		return

	if is_hurt:
		if locked_action_kind != "hurt" or locked_action_animation == "":
			push_warning("Estado de hurt inconsistente detectado; limpando lock de hurt.")
			is_hurt = false
			locked_action_animation = ""
			locked_action_kind = ""
			return

		if not _play_if_needed(locked_action_animation):
			push_warning("Animação de hurt inválida/ausente; limpando estado de hurt.")
			is_hurt = false
			locked_action_animation = ""
			locked_action_kind = ""
		return

	if _is_action_locked():
		_play_if_needed(locked_action_animation)
		return

	_play_if_needed(_get_locomotion_animation_name())


func play_attack_directional(dir: Vector2) -> void:
	if is_dying or is_hurt:
		return

	var suffix := "down"

	if dir == Vector2.UP:
		suffix = "up"
	elif dir == Vector2.DOWN:
		suffix = "down"
	elif dir == Vector2.LEFT:
		suffix = "left"
	elif dir == Vector2.RIGHT:
		suffix = "right"

	action_facing = suffix
	locked_action_animation = "attack_" + suffix
	locked_action_kind = "attack"


func play_hurt() -> void:
	interrupt_for_hurt()


func interrupt_for_hurt() -> void:	
	if is_dying or is_hurt:
		return

	_hurt_recovery_token += 1
	var hurt_token := _hurt_recovery_token
	
	if locked_action_kind == "attack":
		locked_action_animation = ""
		locked_action_kind = ""

	_update_facing()
	action_facing = current_facing
	locked_action_animation = "hurt_" + action_facing
	locked_action_kind = "hurt"
	
	
	is_hurt = true
	_trace_transition("hurt_started", {"token": hurt_token})
	if not _play_if_needed(locked_action_animation):
		push_warning("Falha ao tocar animação de hurt; limpando estado de hurt para evitar lock.")
		is_hurt = false
		locked_action_animation = ""
		locked_action_kind = ""
		_trace_transition("hurt_start_failed", {"token": hurt_token})
		return
	_schedule_hurt_timeout_fallback(hurt_token)
	
	
func can_attack() -> bool:
	return not is_dying and not is_hurt and not _is_action_locked()


func player_attack() -> void:
	if not can_attack():
		return
	
	_update_facing()
	action_facing = current_facing
	locked_action_animation = _build_attack_animation_name()
	locked_action_kind = "attack"


func cancel_attack_animation() -> void:
	if locked_action_kind != "attack":
		return
	
	locked_action_animation = ""
	locked_action_kind = ""
	_trace_transition("attack_animation_cancelled")


func play_dying() -> void:
	if is_dying:
		return
		
	_update_facing()
	action_facing = current_facing
	locked_action_animation = "dying_" + action_facing
	locked_action_kind = "dying"

	is_dying = true
	is_hurt = false
	dying_animation_finished = false

	_play_if_needed(locked_action_animation)


func _update_facing() -> void:
	var direction := move_component.facing_direction
	current_facing = _vector_to_direction(direction)


func _is_action_locked() -> bool:
	return locked_action_animation != "" and locked_action_kind != ""


func _get_locomotion_animation_name() -> String:
	if move_component.is_moving():
		if move_component.is_running:
			return "run_" + current_facing
		return "walk_" + current_facing

	return "idle_" + current_facing


func _build_attack_animation_name() -> String:
	if move_component.is_moving():
		if move_component.is_running:
			return "run_attack_" + action_facing
		return "walk_attack_" + action_facing

	return "attack_" + action_facing


func _vector_to_direction(dir: Vector2) -> String:
	if dir == Vector2.ZERO:
		return current_facing

	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0.0 else "left"
	else:
		return "down" if dir.y > 0.0 else "up"


func _play_if_needed(animation_name: String) -> bool:
	if animation_name == "":
		return false

	if animated_sprite.sprite_frames == null:
		return false

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		push_warning("Animação não encontrada: " + animation_name)
		return false

	if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		animated_sprite.play(animation_name)

	return true

func _on_frame_changed() -> void:
	var current_animation := animated_sprite.animation
	if not _is_attack_animation(current_animation):
		return
		
	if animated_sprite.frame == attack_active_frame:
		attack_hit_frame_reached.emit(current_animation)


func _on_animation_finished() -> void:
	var finished_animation := animated_sprite.animation

	if _is_attack_animation(finished_animation):
		if locked_action_kind == "attack":
			locked_action_animation = ""
			locked_action_kind = ""
			_trace_transition("attack_animation_finished", {"animation": finished_animation})
			
	elif finished_animation.begins_with("hurt_"):
		is_hurt = false
		_hurt_recovery_token += 1
		if locked_action_kind == "hurt":
			locked_action_animation = ""
			locked_action_kind = ""
		_trace_transition("hurt_animation_finished", {"animation": finished_animation})
	elif finished_animation.begins_with("dying_"):
		dying_animation_finished = true
		_trace_transition("dying_animation_finished", {"animation": finished_animation})
	
	animation_finished.emit(finished_animation)


func _is_attack_animation(animation_name: String) -> bool:
	return animation_name.begins_with("attack_") \
		or animation_name.begins_with("walk_attack_") \
		or animation_name.begins_with("run_attack_")

func _schedule_hurt_timeout_fallback(token: int) -> void:
	var expected_duration := _get_animation_expected_duration(locked_action_animation)
	if expected_duration <= 0.0:
		return

	var timeout: float = expected_duration + max(hurt_timeout_padding_seconds, 0.0)
	_hurt_timeout_recovery(token, timeout)


func _hurt_timeout_recovery(token: int, timeout: float) -> void:
	await get_tree().create_timer(timeout).timeout

	if token != _hurt_recovery_token:
		return

	if not is_hurt:
		return

	if locked_action_kind != "hurt":
		return

	push_warning("Timeout de hurt acionado; limpando estado para evitar lock.")
	is_hurt = false
	locked_action_animation = ""
	locked_action_kind = ""
	_trace_transition("hurt_timeout_recovery", {"timeout_seconds": timeout, "token": token})


func _get_animation_expected_duration(animation_name: String) -> float:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return 0.0

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return 0.0

	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return 0.0

	var speed := animated_sprite.sprite_frames.get_animation_speed(animation_name)
	if speed <= 0.0:
		return 0.0

	var total_units := 0.0
	for i in range(frame_count):
		total_units += animated_sprite.sprite_frames.get_frame_duration(animation_name, i)

	return total_units / speed


func _trace_transition(event_name: String, payload: Dictionary = {}) -> void:
	var trace_payload := {
		"is_hurt": is_hurt,
		"is_dying": is_dying,
		"locked_action_kind": locked_action_kind,
		"locked_action_animation": locked_action_animation,
		"combat_phase": _get_combat_phase_name()
	}
	for key in payload.keys():
		trace_payload[key] = payload[key]

	DebugHelper.trace("Animation", get_parent(), event_name, trace_payload)


func _get_combat_phase_name() -> String:
	var combat_state := get_node_or_null("../CombatStateComponent") as CombatStateComponent
	if combat_state == null:
		return "unknown"

	return combat_state.get_phase_name()
