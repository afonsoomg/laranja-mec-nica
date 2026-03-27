extends Node
class_name StaminaComponent

signal stamina_changed(current: float, max_stamina: float)
signal stamina_spent(amount: float)
signal stamina_depleted

@export var max_stamina: float = 100.0
@export var regen_per_second: float = 25.0
@export var regen_delay: float = 0.4

var current_stamina: float = 0.0
var _regen_block_timer: float = 0.0

func _ready() -> void:
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)

func _process(delta: float) -> void:
	if _regen_block_timer > 0.0:
		_regen_block_timer -= delta
		return

	if current_stamina < max_stamina:
		current_stamina = min(current_stamina + regen_per_second * delta, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)

func can_spend(amount: float) -> bool:
	return current_stamina >= amount

func spend(amount: float) -> bool:
	if amount <= 0.0:
		return true

	if not can_spend(amount):
		stamina_depleted.emit()
		return false

	current_stamina -= amount
	_regen_block_timer = regen_delay
	stamina_changed.emit(current_stamina, max_stamina)
	stamina_spent.emit(amount)
	return true

func spend_over_time(amount_per_second: float, delta: float) -> bool:
	var amount := amount_per_second * delta
	return spend(amount)

func restore(amount: float) -> void:
	current_stamina = min(current_stamina + amount, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)

func get_ratio() -> float:
	if max_stamina <= 0.0:
		return 0.0
	return current_stamina / max_stamina
