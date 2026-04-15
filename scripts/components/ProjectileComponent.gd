extends Node
class_name ProjectileComponent

signal projectile_hit(target: Node)
signal projectile_expired

@export var speed: float = 260.0
@export var lifetime: float = 2.0
@export var damage: int = 10
@export var knockback_force: float = 120.0
@export var destroy_on_hit: bool = true
@export var projectile_area: Area2D
@export var sprite: CanvasItem
@export var collision_shape: CollisionShape2D
@export var destroy_delay: float = 0.05

var direction: Vector2 = Vector2.RIGHT
var owner_node: Node = null
var is_active: bool = true

var _hit_targets: Array[HurtboxComponent] = []


func _ready() -> void:
	if projectile_area == null:
		push_error("ProjectileComponent precisa de um Area2D atribuído.")
		return

	projectile_area.body_entered.connect(_on_body_entered)
	projectile_area.area_entered.connect(_on_area_entered)

	_start_lifetime_timer()


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	if projectile_area == null:
		return

	projectile_area.global_position += direction * speed * delta


func initialize(start_direction: Vector2, projectile_owner: Node = null, projectile_damage: int = -1, projectile_knockback_force: float = -1.0) -> void:	
	direction = start_direction.normalized()
	owner_node = projectile_owner

	if projectile_damage >= 0:
		damage = projectile_damage

	if projectile_knockback_force >= 0.0:
		knockback_force = projectile_knockback_force

	if projectile_area != null:
		projectile_area.rotation = direction.angle()


func _start_lifetime_timer() -> void:
	await get_tree().create_timer(lifetime).timeout

	if not is_inside_tree():
		return

	if is_active:
		projectile_expired.emit()
		_deactivate_and_destroy()


func _on_body_entered(body: Node) -> void:
	if not is_active:
		return

	if _belongs_to_owner(body):
		return

	projectile_hit.emit(body)

	if destroy_on_hit:
		_deactivate_and_destroy()


func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return

	if _belongs_to_owner(area):
		return

	var hurtbox := _extract_hurtbox(area)
	if hurtbox == null:
		return

	if _belongs_to_owner(hurtbox):
		return
		
	if not _is_player_hurtbox(hurtbox):
		return

	if _hit_targets.has(hurtbox):
		return

	_hit_targets.append(hurtbox)

	var hit_direction := direction
	var attacker_name := str(owner_node.name) if owner_node != null else "Unknown"
	var target_entity := hurtbox.get_parent()
	DebugHelper.trace(
		"Combat",
		owner_node,
		"hit_registered",
		{
			"source": "projectile",
			"projectile": str(get_parent().name) if get_parent() != null else "Projectile",
			"target": str(target_entity.name) if target_entity != null else "Unknown",
			"damage": damage,
			"direction": hit_direction,
			"knockback_force": knockback_force,
			"attacker": attacker_name
		}
	)
	hurtbox.receive_hit(damage, hit_direction, knockback_force)
	projectile_hit.emit(hurtbox)

	if destroy_on_hit:
		_deactivate_and_destroy()


func _extract_hurtbox(target: Node) -> HurtboxComponent:
	if target is HurtboxComponent:
		return target as HurtboxComponent

	for child in target.get_children():
		if child is HurtboxComponent:
			return child as HurtboxComponent

	return null

func _is_player_hurtbox(hurtbox: HurtboxComponent) -> bool:
	if hurtbox == null:
		return false

	var current: Node = hurtbox
	while current != null:
		if current.is_in_group("player"):
			return true
		current = current.get_parent()

	return false


func _belongs_to_owner(target: Node) -> bool:
	if owner_node == null or target == null:
		return false

	if target == owner_node:
		return true

	return owner_node.is_ancestor_of(target)


func _deactivate_and_destroy() -> void:
	is_active = false

	if projectile_area != null:
		projectile_area.set_deferred("monitoring", false)
		projectile_area.set_deferred("monitorable", false)

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	if sprite != null:
		sprite.visible = false

	await get_tree().create_timer(destroy_delay).timeout

	if is_inside_tree():
		queue_free()
