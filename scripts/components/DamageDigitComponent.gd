extends Node
class_name DamageDigitComponent

@export var damage_digit_prefab: PackedScene
@export var hurtbox_component: HurtboxComponent
@export var spawn_marker: Node2D
@export var spawn_on_parent: bool = true

func _ready() -> void:
	if damage_digit_prefab == null:
		push_error("DamageDigitComponent precisa de um damage_digit_prefab.")
		return

	if hurtbox_component == null:
		hurtbox_component = get_parent().get_node_or_null("HurtboxComponent") as HurtboxComponent

	if hurtbox_component == null:
		push_error("DamageDigitComponent precisa de um HurtboxComponent.")
		return

	hurtbox_component.hit_received.connect(_on_hit_received)


func _on_hit_received(damage: int, _hit_direction: Vector2, _knockback_force: float, is_critical: bool) -> void:
	_spawn_damage_digit(damage, is_critical)


func _spawn_damage_digit(amount: int, is_critical: bool = false) -> void:
	if damage_digit_prefab == null:
		return

	var damage_digit := damage_digit_prefab.instantiate()
	if damage_digit == null:
		return

	damage_digit.value = amount
	damage_digit.is_critical = is_critical

	if spawn_marker != null:
		damage_digit.global_position = spawn_marker.global_position
	else:
		damage_digit.global_position = _get_owner_global_position()

	var parent_node := get_parent() if spawn_on_parent else get_tree().current_scene
	parent_node.add_child(damage_digit)


func _get_owner_global_position() -> Vector2:
	var owner_2d := get_parent() as Node2D
	if owner_2d != null:
		return owner_2d.global_position

	return Vector2.ZERO
