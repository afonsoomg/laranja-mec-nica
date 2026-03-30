extends Node
class_name InventoryComponent

signal item_changed(item_id: StringName, amount: int, max_amount: int)
signal inventory_changed

@export var stack_limits: Dictionary = {
	&"water": 3,
	&"fertilizer_bar": 2,
	&"garden_key": 1,
}

var _items: Dictionary = {}


func get_amount(item_id: StringName) -> int:
	return int(_items.get(item_id, 0))


func has_item(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	return get_amount(item_id) >= amount


func has_key(key_id: StringName) -> bool:
	return has_item(key_id, 1)


func get_stack_limit(item_id: StringName) -> int:
	var configured := int(stack_limits.get(item_id, 0))
	if configured <= 0:
		return 999
	return configured


func can_add(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	return get_amount(item_id) + amount <= get_stack_limit(item_id)


func add_item(item_id: StringName, amount: int = 1) -> int:
	if amount <= 0:
		return 0

	var current := get_amount(item_id)
	var max_amount := get_stack_limit(item_id)
	var room: int = max(max_amount - current, 0)
	var added := mini(room, amount)

	if added <= 0:
		return 0

	_items[item_id] = current + added
	item_changed.emit(item_id, get_amount(item_id), max_amount)
	inventory_changed.emit()
	return added


func consume_item(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return false

	var current := get_amount(item_id)
	if current < amount:
		return false

	var remaining := current - amount
	if remaining <= 0:
		_items.erase(item_id)
	else:
		_items[item_id] = remaining

	item_changed.emit(item_id, get_amount(item_id), get_stack_limit(item_id))
	inventory_changed.emit()
	return true


func to_dictionary() -> Dictionary:
	return _items.duplicate(true)
