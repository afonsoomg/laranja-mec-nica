extends Node
class_name CombatStateComponent

signal attack_started
signal attack_finished
signal attack_cancelled
signal dodge_started
signal dodge_finished

var is_attacking: bool = false
var is_dodging: bool = false

func can_start_attack() -> bool:
	return not is_attacking and not is_dodging

func start_attack() -> bool:
	if not can_start_attack():
		return false

	is_attacking = true
	attack_started.emit()
	return true

func finish_attack() -> void:
	if not is_attacking:
		return

	is_attacking = false
	attack_finished.emit()

func cancel_attack() -> void:
	if not is_attacking:
		return

	is_attacking = false
	attack_cancelled.emit()

func start_dodge() -> bool:
	if is_dodging:
		return false

	if is_attacking:
		cancel_attack()

	is_dodging = true
	dodge_started.emit()
	return true

func finish_dodge() -> void:
	if not is_dodging:
		return

	is_dodging = false
	dodge_finished.emit()
