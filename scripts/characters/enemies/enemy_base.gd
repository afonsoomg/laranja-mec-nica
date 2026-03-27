extends CharacterBase
class_name EnemyBase

@onready var ranged_weapon_component = $RangedWeaponComponent
@onready var detection_area: Area2D = $DetectionArea

@onready var ai_component: EnemyAIComponent = $EnemyAIComponent
@onready var enemy_health_bar: ProgressBar = $ProgressBar

var target: Node2D = null
var is_active: bool = true

func _ready() -> void:
	super._ready()
	add_to_group("enemy")
	
	if detection_area == null:
		push_error("DetectionArea não encontrada no inimigo.")
	else:
		if not detection_area.body_entered.is_connected(_on_detection_area_body_entered):
			detection_area.body_entered.connect(_on_detection_area_body_entered)

		if not detection_area.body_exited.is_connected(_on_detection_area_body_exited):
			detection_area.body_exited.connect(_on_detection_area_body_exited)

	if ai_component:
		ai_component.set_target(null)

	if health_component and enemy_health_bar:
		enemy_health_bar.max_value = health_component.max_health
		enemy_health_bar.value = health_component.current_health

	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)

	call_deferred("_check_initial_target")
		
		
		
func _check_initial_target() -> void:
	if detection_area == null:
		return

	var bodies := detection_area.get_overlapping_bodies()
	for body in bodies:
		if body is Node2D and body.is_in_group("player"):
			target = body
			if ai_component:
				ai_component.set_target(target)
			print("Target inicial detectado:", body.name)
			return
			
func _physics_process(delta: float) -> void:
	if is_dead or not is_active:
		return

	super._physics_process(delta)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if is_dead:
		return

	if body.is_in_group("player"):
		target = body
		if ai_component:
			ai_component.set_target(target)

func _on_detection_area_body_exited(body: Node2D) -> void:
	
	if body == target:
		target = null
		if ai_component:
			ai_component.set_target(null)

func _on_died() -> void:
	super._on_died()
	is_active = false
	target = null

	if ai_component:
		ai_component.set_target(null)
		ai_component.set_dead(true)

	await get_tree().create_timer(5).timeout
	queue_free()

func _on_health_changed(current_health: int, max_health: int) -> void:
	if enemy_health_bar == null:
		return

	enemy_health_bar.max_value = max_health
	enemy_health_bar.value = current_health
