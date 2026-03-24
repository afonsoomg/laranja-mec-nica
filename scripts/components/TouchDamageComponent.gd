extends Node
class_name TouchDamageComponent

signal hit_landed(hurtbox: HurtboxComponent)

@onready var damage_area: Area2D = $"../TouchDamageArea"
@onready var damage_area_shape: CollisionShape2D = $"../TouchDamageArea/CollisionShape2D"

@export var damage: int = 10
@export var hit_interval: float = 1.0
@export var knockback_force: float = 120.0
@export var use_knockback: bool = true

var _can_hit: bool = true
var _targets_in_area: Array[HurtboxComponent] = []


func _ready() -> void:
	var owner_node := get_parent() as Node2D
	if owner_node == null:
		push_error("TouchDamageComponent precisa ser filho de um Node2D.")
		return

	if damage_area == null:
		push_error("TouchDamageComponent precisa de uma Area2D.")
		return

	if damage_area_shape == null:
		push_error("TouchDamageComponent precisa de um CollisionShape2D dentro da Area2D.")
		return


	damage_area.area_entered.connect(_on_area_entered)
	damage_area.area_exited.connect(_on_area_exited)


func _process(_delta: float) -> void:
	if not _can_hit:
		return

	_cleanup_invalid_targets()

	if _targets_in_area.is_empty():
		return

	var target_hurtbox := _targets_in_area[0]
	if target_hurtbox == null or not is_instance_valid(target_hurtbox):
		return

	_hit_target(target_hurtbox)


func _on_area_entered(area: Area2D) -> void:
	if not (area is HurtboxComponent):
		return

	var hurtbox := area as HurtboxComponent

	if _is_own_hurtbox(hurtbox):
		return

	if not _targets_in_area.has(hurtbox):
		_targets_in_area.append(hurtbox)


func _on_area_exited(area: Area2D) -> void:
	if not (area is HurtboxComponent):
		return

	var hurtbox := area as HurtboxComponent
	_targets_in_area.erase(hurtbox)


func _hit_target(hurtbox: HurtboxComponent) -> void:
	if hurtbox == null or not is_instance_valid(hurtbox):
		return

	_can_hit = false

	var hit_direction := Vector2.ZERO
	if use_knockback:
		hit_direction = (hurtbox.global_position - _get_owner_global_position()).normalized()

	hurtbox.receive_hit(
		damage,
		hit_direction,
		knockback_force if use_knockback else 0.0
	)

	hit_landed.emit(hurtbox)

	await get_tree().create_timer(hit_interval).timeout

	if not is_inside_tree():
		return

	_can_hit = true
	

func _get_owner_global_position() -> Vector2:
	var owner_node := get_parent() as Node2D
	if owner_node != null:
		return owner_node.global_position

	return Vector2.ZERO


func _is_own_hurtbox(hurtbox: HurtboxComponent) -> bool:
	var owner_node := get_parent()
	if owner_node == null:
		return false

	return hurtbox.get_parent() == owner_node


func _cleanup_invalid_targets() -> void:
	_targets_in_area = _targets_in_area.filter(
		func(h): return h != null and is_instance_valid(h)
	)
	
