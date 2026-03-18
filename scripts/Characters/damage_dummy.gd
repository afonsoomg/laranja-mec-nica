extends Node2D
class_name DamageDummy

@export var damage_area: Area2D
@export var damage: int = 10
@export var hit_interval: float = 1.0
@export var knockback_force: float = 120.0
@export var use_knockback: bool = true

var _can_hit: bool = true
var _targets_in_area: Array[HurtboxComponent] = []


func _ready() -> void:
	if damage_area == null:
		push_error("DamageDummy precisa de uma DamageArea.")
		return

	damage_area.area_entered.connect(_on_area_entered)
	damage_area.area_exited.connect(_on_area_exited)


func _process(_delta: float) -> void:
	if not _can_hit:
		return

	if _targets_in_area.is_empty():
		return

	var target_hurtbox := _targets_in_area[0]

	if target_hurtbox == null:
		return

	_hit_target(target_hurtbox)


func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		var hurtbox := area as HurtboxComponent

		if not _targets_in_area.has(hurtbox):
			_targets_in_area.append(hurtbox)


func _on_area_exited(area: Area2D) -> void:
	if area is HurtboxComponent:
		var hurtbox := area as HurtboxComponent
		_targets_in_area.erase(hurtbox)


func _hit_target(hurtbox: HurtboxComponent) -> void:
	if hurtbox == null:
		return

	_can_hit = false

	var hit_direction := Vector2.ZERO
	if use_knockback:
		hit_direction = (hurtbox.global_position - global_position).normalized()

	hurtbox.receive_hit(
		damage,
		hit_direction,
		knockback_force if use_knockback else 0.0
	)

	await get_tree().create_timer(hit_interval).timeout
	_can_hit = true
