extends InteractableBase
class_name NoteInteractable

@export var note_title: String = "Bilhete"
@export_multiline var note_body: String = "Texto da nota aqui."
@export var show_once: bool = false

var _already_shown: bool = false


func can_interact(_interactor: Node) -> bool:
	if not interaction_enabled:
		return false
	if show_once and _already_shown:
		return false
	return true


func interact(_interactor: Node) -> void:
	if show_once and _already_shown:
		return

	var hud := _get_hud()
	if hud == null:
		return

	hud.show_note_panel(note_title, note_body)
	_already_shown = true


func _get_hud() -> PlayerHUD:
	return get_tree().get_first_node_in_group("player_hud") as PlayerHUD
