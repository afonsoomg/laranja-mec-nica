extends Area2D
class_name InteractionComponent

signal current_interactable_changed(interactable: InteractableBase)

@export var interact_action: StringName = &"game_interact"

var _candidates: Array[InteractableBase] = []
var _current: InteractableBase


func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func tick(interactor: Node2D) -> void:
	_refresh_current(interactor)

	if _current == null:
		return

	if Input.is_action_just_pressed(interact_action):
		_current.interact(interactor)
		if not is_instance_valid(_current) or not _current.interaction_enabled:
			_refresh_current(interactor)


func get_current_interactable() -> InteractableBase:
	return _current


func _on_area_entered(area: Area2D) -> void:
	if not (area is InteractableBase):
		return

	var interactable := area as InteractableBase
	if _candidates.has(interactable):
		return

	_candidates.append(interactable)


func _on_area_exited(area: Area2D) -> void:
	if not (area is InteractableBase):
		return

	var interactable := area as InteractableBase
	_candidates.erase(interactable)


func _refresh_current(interactor: Node2D) -> void:
	if interactor == null:
		_set_current(null)
		return

	_candidates = _candidates.filter(func(candidate: InteractableBase) -> bool:
		return is_instance_valid(candidate) and candidate.interaction_enabled and candidate.can_interact(interactor)
	)

	if _candidates.is_empty():
		_set_current(null)
		return

	_candidates.sort_custom(func(a: InteractableBase, b: InteractableBase) -> bool:
		if a.interaction_priority == b.interaction_priority:
			var da := interactor.global_position.distance_squared_to(a.global_position)
			var db := interactor.global_position.distance_squared_to(b.global_position)
			return da < db
		return a.interaction_priority > b.interaction_priority
	)

	_set_current(_candidates[0])


func _set_current(interactable: InteractableBase) -> void:
	if _current == interactable:
		return
	_current = interactable
	current_interactable_changed.emit(_current)
