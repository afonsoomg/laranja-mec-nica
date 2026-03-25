extends CharacterBody2D
class_name CharacterBase

@onready var animation_component: AnimationComponent = $AnimationComponent
@onready var knockback_component: KnockbackComponent = $KnockbackComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var audio_component: AudioComponent = get_node_or_null("AudioComponent") as AudioComponent
@onready var vfx_component: VfxComponent = get_node_or_null("VfxComponent") as VfxComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _last_footstep_frame := -1

var is_dead: bool = false

func _ready() -> void:
	_connect_signals()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if knockback_component:
		knockback_component.update_knockback(delta)
		
	_apply_final_movement()

func _connect_signals() -> void:
	if health_component and not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)
		
	if hurtbox_component and not hurtbox_component.hit_received.is_connected(_on_hit_received):
		hurtbox_component.hit_received.connect(_on_hit_received)
		
	if animated_sprite and not 	animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)

func _on_hit_received(_damage: int, _direction: Vector2, _force: float, _is_critical: bool) -> void:
	if is_dead:
		return

	if animation_component:
		animation_component.play_hurt()

func _on_died() -> void:
	is_dead = true
	
	if move_component:
		move_component.can_move = false
		move_component.stop()
	
	if knockback_component:
		knockback_component.clear_knockback()
		
	if audio_component:
		audio_component.play_death()

	if vfx_component:
		vfx_component.play_death_burst()

	if animation_component:
		animation_component.play_dying()

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

	var is_walk := anim.begins_with("walk_") or anim.begins_with("walk_attack")
	var is_run := anim.begins_with("run_") or anim.begins_with("run_attack")

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
