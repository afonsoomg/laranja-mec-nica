extends CharacterBase
class_name EnemyBase

var ranged_weapon_component: RangedWeaponComponent
var detection_area: Area2D
var ai_component: EnemyAIComponent
var enemy_health_bar: ProgressBar
var target: Node2D = null
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
	
	ai_component.set_target(null)
	enemy_health_bar.max_value = health_component.max_health
	enemy_health_bar.value = health_component.current_health

	if health_component == null:
		Observability.log_error(LOG_CATEGORY, "HealthComponent missing; enemy health UI cannot initialize.")
		assert(false, "[EnemyBase] Critical setup failure: missing HealthComponent.")
		return

	Observability.connect_once_safe(health_component.health_changed, _on_health_changed, "EnemyBase._ready health_changed")
	
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
			Observability.log_debug(LOG_CATEGORY, "Initial target detected: %s" % body.name)
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
