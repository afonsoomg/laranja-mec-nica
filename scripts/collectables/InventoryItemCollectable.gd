extends CollectableBase
class_name InventoryItemCollectable

@export var item_id: StringName = &"key_1"
@export var amount: int = 1
@export var pickup_message: String = "Chave coletada"
@export var inventory_full_message: String = "Inventário cheio"


func apply_to_collector(collector: Node) -> bool:
	if collector == null:
		return false

	var inventory := collector.get_node_or_null("InventoryComponent") as InventoryComponent
	if inventory == null:
		return false

	var added := inventory.add_item(item_id, amount)
	if added <= 0:
		_show_feedback(inventory_full_message)
		return false

	_show_feedback("%s +%d" % [pickup_message, added])

	var audio_component := collector.get_node_or_null("AudioComponent") as AudioComponent
	if audio_component:
		audio_component.play_collect()

	return true


func _show_feedback(message: String) -> void:
	var hud := get_tree().get_first_node_in_group("player_hud") as PlayerHUD
	if hud:
		hud.show_message(message)
