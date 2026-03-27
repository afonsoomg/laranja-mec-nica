extends CharacterBody2D
class_name CharacterBase

const Observer = preload("res://scripts/utils/observability.gd")
const LOG_CATEGORY := "CharacterBase"

var animation_component: AnimationComponent
var knockback_component: KnockbackComponent
var health_component: HealthComponent
var move_component: MoveComponent
var hurtbox_component: HurtboxComponent
var audio_component: AudioComponent
var vfx_component: VfxComponent
var animated_sprite: AnimatedSprite2D
var combat_state_component: CombatStateComponent

var _last_footstep_frame := -1
var is_dead: bool = false


func _ready() -> void:
	if not ComponentValidator.require_nodes(self, [
		{"path": NodePath("AnimationComponent"), "expected_type": "AnimationComponent", "name": "AnimationComponent", "assign_to": "animation_component"},
		{"path": NodePath("KnockbackComponent"), "expected_type": "KnockbackComponent", "name": "KnockbackComponent", "assign_to": "knockback_component"},
		{"path": NodePath("HealthComponent"), "expected_type": "HealthComponent", "name": "HealthComponent", "assign_to": "health_component"},
		{"path": NodePath("MoveComponent"), "expected_type": "MoveComponent", "name": "MoveComponent", "assign_to": "move_component"},
		{"path": NodePath("HurtboxComponent"), "expected_type": "HurtboxComponent", "name": "HurtboxComponent", "assign_to": "hurtbox_component"},
		{"path": NodePath("AnimatedSprite2D"), "expected_type": "AnimatedSprite2D", "name": "AnimatedSprite2D", "assign_to": "animated_sprite"},
		{"path": NodePath("CombatStateComponent"), "expected_type": "CombatStateComponent", "name": "CombateStateComponent", "assign_to": "combat_state_component"}
	]):
		set_physics_process(false)
		return

	audio_component = get_node_or_null("AudioComponent") as AudioComponent
	vfx_component = get_node_or_null("VfxComponent") as VfxComponent
	_connect_signals()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if knockback_component:
		knockback_component.update_knockback(delta)
		
	_apply_final_movement()


func _connect_signals() -> void:
	if health_component == null:
		Observer.log_error(LOG_CATEGORY, "Missing HealthComponent on %s." % name)
		assert(false, "[CharacterBase] Critical setup failure: missing HealthComponent.")
		return

	if hurtbox_component == null:
		Observer.log_error(LOG_CATEGORY, "Missing HurtboxComponent on %s." % name)
		assert(false, "[CharacterBase] Critical setup failure: missing HurtboxComponent.")
		return

	if animated_sprite == null:
		Observer.log_error(LOG_CATEGORY, "Missing AnimatedSprite2D on %s." % name)
		assert(false, "[CharacterBase] Critical setup failure: missing AnimatedSprite2D.")
		return

	Observer.connect_once_safe(health_component.died, _on_died, "CharacterBase._connect_signals died")
	Observer.connect_once_safe(hurtbox_component.hit_received, _on_hit_received, "CharacterBase._connect_signals hit_received")
	Observer.connect_once_safe(animated_sprite.frame_changed, _on_frame_changed, "CharacterBase._connect_signals frame_changed")


func _on_hit_received(_damage: int, _direction: Vector2, _force: float, _is_critical: bool) -> void:
	if is_dead:
		return

	var tween = get_tree().create_tween()
	tween.tween_method(_set_shader_blink_intensity, 1.0, 0.0, 0.5)
	
	DebugHelper.trace(
		"Combat",
		self,
		"hurt_received",
		{
			"is_dead": is_dead,
			"combat_phase": combat_state_component.get_phase_name() if combat_state_component != null else "unknown",
			"is_hurt": animation_component.is_hurt if animation_component != null else false
		}
	)
	
	if combat_state_component != null and combat_state_component.is_attacking:
		combat_state_component.interrupt_attack("hurt")
	
	if animation_component:
		animation_component.interrupt_for_hurt()



func _set_shader_blink_intensity(newValue : float):
	animated_sprite.material.set_shader_parameter("blink_intensity", newValue)


func _on_died() -> void:
	is_dead = true
	
	if move_component:
		move_component.can_move = false
		move_component.stop()
	
	if knockback_component:
		knockback_component.clear_knockback()
		
	if audio_component:
		audio_component.play_death()

	if animation_component:
		animation_component.play_dying()
		
	if combat_state_component != null:
		combat_state_component.interrupt_attack("death")


func _apply_final_movement() -> void:
	var final_velocity := Vector2.ZERO

	if move_component:
		final_velocity += move_component.get_velocity()

	if knockback_component:
		final_velocity += knockback_component.get_knockback_velocity()

	velocity = final_velocity
	move_and_slide()


func _play_footstep():
	AudioManagerCustom.play_footstep(global_position)


func _on_frame_changed() -> void:
	if not move_component.is_moving():
		_last_footstep_frame = -1
		return

	var anim: String = animated_sprite.animation
	var frame: int = animated_sprite.frame

	var is_walk := anim.begins_with("walk")
	var is_run := anim.begins_with("run")

	if is_walk:
		if frame == 1 or frame == 4:
			if _last_footstep_frame != frame:
				_play_footstep()
				_last_footstep_frame = frame
	elif is_run:
		if frame == 1 or frame == 5:
			if _last_footstep_frame != frame:
				_play_footstep()
				_last_footstep_frame = frame
	else:
		_last_footstep_frame = -1
