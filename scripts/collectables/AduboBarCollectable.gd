extends CollectableBase
class_name AduboBarCollectable

const Observer = preload("res://scripts/utils/observability.gd")
const LOG_CATEGORY := "AduboBarCollectable"

@export_range(0.0, 1.0, 0.01) var crit_bonus: float = 0.25
@export var buff_duration: float = 8.0

func _ready() -> void:
	super._ready()
	Observer.log_debug(LOG_CATEGORY, "Collectable ready.")


func apply_to_collector(collector: Node) -> bool:
	if collector == null:
		return false

	if not collector.has_node("BuffComponent"):
		return false

	var buff_component := collector.get_node("BuffComponent") as BuffComponent
	if buff_component == null:
		return false

	return buff_component.apply_crit_buff(crit_bonus, buff_duration)
