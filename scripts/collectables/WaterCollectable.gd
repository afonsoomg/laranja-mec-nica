extends CollectableBase
class_name WaterCollectable

@export var item_id: StringName = &"water"
@export var amount: int = 1
@export var full_inventory_message: String = "Sem espaço para mais água."

func apply_to_collector(collector: Node) -> bool:
	if collector == null:
		return false

	var inventory := collector.get_node_or_null("InventoryComponent") as InventoryComponent
	if inventory == null:
		return false

	var added := inventory.add_item(item_id, amount)
	if added <= 0:
		_show_feedback(full_inventory_message)
		return false

	_show_feedback("Água +%d" % added)
	
	var audio_component := collector.get_node_or_null("AudioComponent") as AudioComponent
	if audio_component:
		audio_component.play_collect()
		
	return true

func _show_feedback(message: String) -> void:
	var hud := get_tree().get_first_node_in_group("player_hud") as PlayerHUD
	if hud:
		hud.show_message(message)
