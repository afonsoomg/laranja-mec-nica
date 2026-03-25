extends Area2D
class_name CollectableBase

@export var destroy_on_collect: bool = true
@export var collect_sfx: AudioStream

var _is_collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:	
	if _is_collected:
		return

	if body == null:
		return

	if not body.has_method("collect_collectable"):
		return

	body.collect_collectable(self)


func apply_to_collector(_collector: Node) -> bool:
	push_warning("CollectableBase.apply_to_collector() deve ser sobrescrito nos filhos.")
	return false


func on_collected(_collector: Node) -> void:
	_is_collected = true
	
	if destroy_on_collect:
		queue_free()
