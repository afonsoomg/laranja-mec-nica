extends CollectableBase
class_name WaterCollectable

@export var heal_amount: int = 20

func apply_to_collector(collector: Node) -> bool:
	print("Water Collected")
	
	if collector == null:
		return false

	if not collector.has_node("HealthComponent"):
		return false

	var health_component := collector.get_node("HealthComponent") as HealthComponent
	if health_component == null:
		return false

	if health_component.is_dead:
		return false

	if health_component.current_health >= health_component.max_health:
		return false

	health_component.heal(heal_amount)
	return true
