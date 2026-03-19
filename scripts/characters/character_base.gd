extends CharacterBody2D
class_name CharacterBase

@onready var animation_component: AnimationComponent = $AnimationComponent
@onready var knockback_component: KnockbackComponent = $KnockbackComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var move_component: MoveComponent = $MoveComponent

var is_dead: bool = false

func _ready() -> void:
	_connect_signals()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if knockback_component:
		knockback_component.update_knockback(delta)

func _connect_signals() -> void:
	if health_component and not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)

func _on_died() -> void:
	is_dead = true
	
	if move_component:
		move_component.can_move = false
		move_component.stop()

	if animation_component:
		animation_component.play_dying()
