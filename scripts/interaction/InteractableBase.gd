extends Area2D
class_name InteractableBase

@export var prompt_text: String = "Interagir"
@export var interaction_enabled: bool = true
@export var interaction_priority: int = 0


func can_interact(_interactor: Node) -> bool:
	return interaction_enabled


func interact(_interactor: Node) -> void:
	pass


func get_prompt_text() -> String:
	return prompt_text
