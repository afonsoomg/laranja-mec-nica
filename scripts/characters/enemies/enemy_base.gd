extends CharacterBase
class_name EnemyBase

@export var target_path: NodePath
@export var ranged_weapon_component: RangedWeaponComponent

@onready var target: Node2D = get_node_or_null(target_path) as Node2D
@onready var ai_component: EnemyAIComponent = $EnemyAIComponent

var is_active: bool = true

func _ready() -> void:
	super._ready()

	if ai_component:
		ai_component.set_target(target)

func _physics_process(delta: float) -> void:
	if is_dead or not is_active:
		return

	super._physics_process(delta)

func _on_died() -> void:
	super._on_died()
	is_active = false

	if ai_component:
		ai_component.set_dead(true)

	await get_tree().create_timer(0.6).timeout
	queue_free()
