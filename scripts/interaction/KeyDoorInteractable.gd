extends InteractableBase
class_name KeyDoorInteractable

@export var required_key_id: StringName = &"key_1"
@export var consume_key_on_open: bool = false
@export var missing_key_message: String = "Você precisa da chave correta."
@export var opened_prompt_text: String = "Aberta"
@export var collision_node: CollisionShape2D
@export var closed_visual: CanvasItem
@export var opened_visual: CanvasItem
@export var sfx_player: AudioStreamPlayer2D
@export var open_sfx: AudioStream
@export var closed_sfx: AudioStream

var is_open: bool = false


func _ready() -> void:
	_update_visual_state()


func can_interact(_interactor: Node) -> bool:
	if not interaction_enabled:
		return false
	return not is_open


func interact(interactor: Node) -> void:
	if is_open:
		return

	var inventory := interactor.get_node_or_null("InventoryComponent") as InventoryComponent
	if inventory == null:
		return

	if not inventory.has_key(required_key_id):
		_show_message(missing_key_message)
		_play_sfx(closed_sfx)
		return

	if consume_key_on_open and not inventory.consume_item(required_key_id, 1):
		_show_message(missing_key_message)
		_play_sfx(closed_sfx)
		return

	is_open = true
	interaction_enabled = false
	prompt_text = opened_prompt_text
	_update_visual_state()
	_play_sfx(open_sfx)
	_show_message("Porta aberta.")


func _update_visual_state() -> void:
	if collision_node:
		collision_node.set_deferred("disabled", is_open)

	if closed_visual:
		closed_visual.visible = not is_open

	if opened_visual:
		opened_visual.visible = is_open


func _show_message(message: String) -> void:
	var hud := get_tree().get_first_node_in_group("player_hud") as PlayerHUD
	if hud:
		hud.show_message(message)

func _play_sfx(sound: AudioStream) -> void:
	if sfx_player == null or sound == null:
		return
	sfx_player.stream = sound
	sfx_player.play()
