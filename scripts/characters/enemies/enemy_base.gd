extends CharacterBase
class_name EnemyBase

@export var target: Node2D

@onready var ai_component: EnemyAIComponent = $EnemyAIComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	super._ready()

	if ai_component:
		ai_component.set_target(target)

	if hurtbox_component and hurtbox_component.has_signal("hit_received"):
		if not hurtbox_component.hit_received.is_connected(_on_hit_received):
			hurtbox_component.hit_received.connect(_on_hit_received)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_dead:
		return

	if ai_component == null:
		return

	ai_component.update_ai(global_position)

	if move_component:
		move_component.set_move_input(ai_component.get_move_direction())
		move_component.set_running(false)
		move_component.update_velocity(delta)

	move_and_slide()

	if ai_component.should_attack():
		if weapon_component:
			weapon_component.try_attack()


func _on_died() -> void:
	is_dead = true

	if move_component:
		move_component.can_move = false
		move_component.stop()

	if ai_component:
		ai_component.set_dead(true)

	if weapon_component and weapon_component.attack_hitbox:
		weapon_component.attack_hitbox.set_deferred("monitoring", false)

	if hurtbox_component:
		hurtbox_component.set_deferred("monitorable", false)

	if sprite_2d:
		sprite_2d.modulate = Color(0.7, 0.7, 0.7, 1.0)

	await get_tree().create_timer(0.6).timeout
	queue_free()


func _on_hit_received(_damage: int, _direction: Vector2, _force: float) -> void:
	if sprite_2d == null:
		return

	sprite_2d.modulate = Color(1.0, 0.6, 0.6, 1.0)

	var tween := create_tween()
	tween.tween_property(sprite_2d, "modulate", Color(1, 1, 1, 1), 0.12)
