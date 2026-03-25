extends CollectableBase
class_name WaterCollectable

@export var heal_amount: int = 20

func apply_to_collector(collector: Node) -> bool:	
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
	
	var audio_component := collector.get_node_or_null("AudioComponent") as AudioComponent
	if audio_component:
		audio_component.play_collect()
		audio_component.play_heal()

	var vfx_component := collector.get_node_or_null("VfxComponent") as VfxComponent
	if vfx_component:
		vfx_component.play_heal_burst()
		
	return true
