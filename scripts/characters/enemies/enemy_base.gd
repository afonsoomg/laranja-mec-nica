extends CharacterBase
class_name EnemyBase

@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var touch_damage_area: Area2D = $TouchDamageArea
@onready var touch_damage_collision: CollisionShape2D = $TouchDamageArea/CollisionShape2D

var ranged_weapon_component: RangedWeaponComponent
var detection_area: Area2D
var ai_component: EnemyAIComponent
var enemy_health_bar: ProgressBar
var is_active: bool = true


func _ready() -> void:
	super._ready()

	if not ComponentValidator.require_nodes(self, [
		{"path": NodePath("DetectionArea"), "expected_type": "Area2D", "name": "DetectionArea", "assign_to": "detection_area"},
		{"path": NodePath("EnemyAIComponent"), "expected_type": "EnemyAIComponent", "name": "EnemyAIComponent", "assign_to": "ai_component"},
		{"path": NodePath("ProgressBar"), "expected_type": "ProgressBar", "name": "ProgressBar", "assign_to": "enemy_health_bar"},
	]):
		set_physics_process(false)
		return

	ranged_weapon_component = get_node_or_null("RangedWeaponComponent") as RangedWeaponComponent
	add_to_group("enemy")
	
	if detection_area == null:
		push_error("DetectionArea não encontrada no inimigo.")
		Observability.log_error(LOG_CATEGORY, "DetectionArea missing on enemy.")
		assert(false, "[EnemyBase] Critical setup failure: DetectionArea missing.")
	else:
		Observability.connect_once_safe(detection_area.body_entered, _on_detection_area_body_entered, "EnemyBase._ready body_entered")
		Observability.connect_once_safe(detection_area.body_exited, _on_detection_area_body_exited, "EnemyBase._ready body_exited")
	
	ai_component.configure_detection_area(detection_area)
	enemy_health_bar.max_value = health_component.max_health
	enemy_health_bar.value = health_component.current_health

	if health_component == null:
		Observability.log_error(LOG_CATEGORY, "HealthComponent missing; enemy health UI cannot initialize.")
		assert(false, "[EnemyBase] Critical setup failure: missing HealthComponent.")
		return

	Observability.connect_once_safe(health_component.health_changed, _on_health_changed, "EnemyBase._ready health_changed")
	
	call_deferred("_detect_initial_target")


func _detect_initial_target() -> void:
	if ai_component == null or detection_area == null:
		return

	var bodies := detection_area.get_overlapping_bodies()
	for body in bodies:
		if body is Node2D and body.is_in_group("player"):
			ai_component.on_detection_body_entered(body)
			Observability.log_debug(LOG_CATEGORY, "Initial target detected: %s" % body.name)
			return


func _physics_process(delta: float) -> void:
	if is_dead or not is_active:
		return

	super._physics_process(delta)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if is_dead or ai_component == null:
		return

	ai_component.on_detection_body_entered(body)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if ai_component == null:
		return

	ai_component.on_detection_body_exited(body)


func _on_died() -> void:
	super._on_died()
	is_active = false

	if ai_component:
		ai_component.set_dead(true)
	
	if body_collision:
		body_collision.set_deferred("disabled", true)

	if touch_damage_area:
		touch_damage_area.set_deferred("monitoring", false)
		touch_damage_area.set_deferred("monitorable", false)

	if touch_damage_collision:
		touch_damage_collision.set_deferred("disabled", true)
	
	
	await get_tree().create_timer(3).timeout
	queue_free()


func _on_health_changed(current_health: int, max_health: int) -> void:
	if enemy_health_bar == null:
		return

	enemy_health_bar.max_value = max_health
	enemy_health_bar.value = current_health
