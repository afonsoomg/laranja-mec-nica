extends EnemyBase
class_name EnemyChaser

@export_group("Pressure")
@export var hit_pause_duration: float = 0.35
@export var attack_windup_duration: float = 0.18
@export var attack_cooldown_duration: float = 0.75
@export var attack_lunge_speed: float = 170.0
@export var attack_lunge_duration: float = 0.14

@onready var touch_damage_component: TouchDamageComponent = $TouchDamageComponent

var is_paused_after_hit: bool = false
var is_attack_windup: bool = false
var can_attack: bool = true


func _ready() -> void:
	super._ready()

	$AnimatedSprite2D.scale = Vector2(1, 1)
	if touch_damage_component != null:
		if not touch_damage_component.hit_landed.is_connected(_on_hit_landed):
			touch_damage_component.hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	if is_dead or not is_active:
		return

	if move_component == null or ai_component == null:
		return

	ai_component.update_ai(global_position)

	if _should_lock_movement():
		move_component.set_move_input(Vector2.ZERO)
		move_component.set_running(false)
		move_component.update_velocity(delta)

		if animation_component:
			animation_component.update_animation()
			
		super._physics_process(delta)
		return

	if ai_component.should_attack() and can_attack:
		_start_attack_windup(ai_component.get_aim_direction(global_position))
	else:
		move_component.set_move_input(ai_component.get_move_direction())
		move_component.set_running(false)
		move_component.update_velocity(delta)

	if animation_component:
		animation_component.update_animation()

	super._physics_process(delta)


func _on_hit_landed(hurtbox: HurtboxComponent) -> void:
	if hurtbox == null:
		return
	var current_target: Node = ai_component.get_target() if ai_component != null else null
	if hurtbox.get_parent() != current_target:
		return
	if is_paused_after_hit or is_dead:
		return

	_pause_after_hit()


func _pause_after_hit() -> void:
	is_paused_after_hit = true

	await get_tree().create_timer(max(hit_pause_duration, 0.0)).timeout

	if not is_inside_tree() or is_dead:
		return

	is_paused_after_hit = false


func _start_attack_windup(aim_dir: Vector2) -> void:
	is_attack_windup = true
	can_attack = false

	var final_aim := aim_dir
	if final_aim == Vector2.ZERO and move_component != null:
		final_aim = move_component.facing_direction

	if final_aim != Vector2.ZERO and move_component != null:
		move_component.facing_direction = final_aim.normalized()

	if animation_component != null:
		animation_component.play_attack_directional(move_component.facing_direction)

	if audio_component != null:
		audio_component.play_attack()

	await get_tree().create_timer(max(attack_windup_duration, 0.0)).timeout

	if not is_inside_tree() or is_dead:
		return

	is_attack_windup = false
	_do_attack_lunge()
	_start_attack_cooldown()


func _do_attack_lunge() -> void:
	if move_component == null:
		return

	if attack_lunge_speed <= 0.0 or attack_lunge_duration <= 0.0:
		return

	var lunge_dir := move_component.facing_direction
	if lunge_dir == Vector2.ZERO:
		lunge_dir = Vector2.DOWN

	move_component.apply_forced_velocity_for_duration(lunge_dir.normalized() * attack_lunge_speed, attack_lunge_duration)


func _start_attack_cooldown() -> void:
	await get_tree().create_timer(max(attack_cooldown_duration, 0.0)).timeout

	if not is_inside_tree() or is_dead:
		return

	can_attack = true


func _should_lock_movement() -> bool:
	return is_paused_after_hit or is_attack_windup


func _on_died() -> void:
	$AnimatedSprite2D.scale = Vector2(1.15, 1.15)
	is_attack_windup = false
	can_attack = false
	
	super._on_died()
