extends CharacterBase
class_name EnemyBase

@export var target_path: NodePath
@export var ranged_weapon_component: RangedWeaponComponent

@onready var target: Node2D = get_node_or_null(target_path) as Node2D
@onready var ai_component: EnemyAIComponent = $EnemyAIComponent
@onready var enemy_health_bar: ProgressBar = $ProgressBar

var is_active: bool = true

func _ready() -> void:
	super._ready()

	if ai_component:
		ai_component.set_target(target)
		
	if health_component and enemy_health_bar:
		enemy_health_bar.max_value = health_component.max_health
		enemy_health_bar.value = health_component.current_health

	if not health_component.health_changed.is_connected(_on_health_changed):
			health_component.health_changed.connect(_on_health_changed)


func _physics_process(delta: float) -> void:
	if is_dead or not is_active:
		return

	super._physics_process(delta)


func _on_died() -> void:
	super._on_died()
	is_active = false

	if ai_component:
		ai_component.set_dead(true)

	await get_tree().create_timer(5).timeout
	queue_free()


func _on_health_changed(current_health: int, max_health: int) -> void:
	if enemy_health_bar == null:
		return

	enemy_health_bar.max_value = max_health
	enemy_health_bar.value = current_health
