extends InteractableBase
class_name NoteInteractable

@export var note_title: String = "Bilhete"
@export_multiline var note_body: String = "Texto da nota aqui."
@export var show_once: bool = false
@export var sfx_player: AudioStreamPlayer2D
@export var open_sfx: AudioStream
@export var close_sfx: AudioStream

var _already_shown: bool = false
var _listening_for_close: bool = false

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
	
	if not _listening_for_close and not hud.note_panel_closed.is_connected(_on_note_panel_closed):
		hud.note_panel_closed.connect(_on_note_panel_closed)
		_listening_for_close = true

	_play_sfx(open_sfx)
	
	hud.show_note_panel(note_title, note_body)
	_already_shown = true


func _get_hud() -> PlayerHUD:
	return get_tree().get_first_node_in_group("player_hud") as PlayerHUD


func _on_note_panel_closed() -> void:
	_play_sfx(close_sfx)


func _play_sfx(sound: AudioStream) -> void:
	if sfx_player == null or sound == null:
		return
	sfx_player.stream = sound
	sfx_player.play()
