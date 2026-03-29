extends EnemyBase
class_name EnemyChaser

@export var hit_pause_duration: float = 5.0

@onready var touch_damage_component: TouchDamageComponent = $TouchDamageComponent

var is_paused_after_hit: bool = false


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

	if is_paused_after_hit:
		move_component.set_move_input(Vector2.ZERO)
		move_component.set_running(false)
		move_component.update_velocity(delta)

		if animation_component:
			animation_component.update_animation()
			
		super._physics_process(delta)
		return

	ai_component.update_ai(global_position)

	if ai_component.should_attack():
		move_component.set_move_input(Vector2.ZERO)
		move_component.set_running(false)
		move_component.update_velocity(delta)

		var aim_dir := ai_component.get_aim_direction(global_position)
		if aim_dir != Vector2.ZERO:
			move_component.facing_direction = aim_dir
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

	await get_tree().create_timer(hit_pause_duration).timeout

	if not is_inside_tree() or is_dead:
		return

	is_paused_after_hit = false

func _on_died() -> void:
	$AnimatedSprite2D.scale = Vector2(1.3, 1.3)
	
	super._on_died()
