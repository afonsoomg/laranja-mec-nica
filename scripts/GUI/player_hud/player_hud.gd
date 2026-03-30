extends Control
class_name PlayerHUD

const Observer = preload("res://scripts/utils/observability.gd")
const LOG_CATEGORY := "PlayerHUD"

signal exit_requested
signal back_to_menu_requested

var player: CharacterBase
var health_component: HealthComponent
var stamina_component: StaminaComponent
var inventory_component: InventoryComponent

var health_bar: ProgressBar
var stamina_bar: ProgressBar
var pause_menu: Control
var confirm_exit: ConfirmationDialog
var timer_label: Label
var interaction_prompt_label: Label
var message_label: Label
var inventory_label: Label
var note_panel: Panel
var note_title_label: Label
var note_body_label: RichTextLabel
var message_timer: Timer

var time_elapsed: float = 0.0


func _ready() -> void:
	add_to_group("player_hud")
	
	if not ComponentValidator.require_nodes(self, [
		{"path": NodePath("MarginContainer/HBoxContainer2/HealthProgressBar"), "expected_type": "ProgressBar", "name": "HealthProgressBar", "assign_to": "health_bar"},
		{"path": NodePath("MarginContainer/HBoxContainer2/StaminaProgressBar"), "expected_type": "ProgressBar", "name": "StaminaProgressBar", "assign_to": "stamina_bar"},
		{"path": NodePath("MarginContainer/PauseMenu"), "expected_type": "Control", "name": "PauseMenu", "assign_to": "pause_menu"},
		{"path": NodePath("MarginContainer/PauseMenu/ConfirmExitDialog"), "expected_type": "ConfirmationDialog", "name": "ConfirmExitDialog", "assign_to": "confirm_exit"},
		{"path": NodePath("MarginContainer/TimerLabel"), "expected_type": "Label", "name": "TimerLabel", "assign_to": "timer_label"},
		{"path": NodePath("InteractionPromptLabel"), "expected_type": "Label", "name": "InteractionPromptLabel", "assign_to": "interaction_prompt_label"},
		{"path": NodePath("MessageLabel"), "expected_type": "Label", "name": "MessageLabel", "assign_to": "message_label"},
		{"path": NodePath("InventoryLabel"), "expected_type": "Label", "name": "InventoryLabel", "assign_to": "inventory_label"},
		{"path": NodePath("NotePanel"), "expected_type": "Panel", "name": "NotePanel", "assign_to": "note_panel"},
		{"path": NodePath("NotePanel/VBoxContainer/Title"), "expected_type": "Label", "name": "NoteTitleLabel", "assign_to": "note_title_label"},
		{"path": NodePath("NotePanel/VBoxContainer/Body"), "expected_type": "RichTextLabel", "name": "NoteBodyLabel", "assign_to": "note_body_label"},
		{"path": NodePath("MessageTimer"), "expected_type": "Timer", "name": "MessageTimer", "assign_to": "message_timer"},
	]):
		set_process(false)
		return
	pause_menu.visible = false
	interaction_prompt_label.visible = false
	message_label.visible = false
	note_panel.visible = false
	message_timer.timeout.connect(_on_message_timeout)


func _on_health_changed(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health


func _on_stamina_changed(current_stamina: float, max_stamina: float) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina


func _on_inventory_item_changed(_item_id: StringName, _amount: int, _max_amount: int) -> void:
	_update_inventory_label()


func setup(new_player: CharacterBase) -> void:
	player = new_player
	Observer.log_debug(LOG_CATEGORY, "Setup called with player=%s" % player)
	
	if player == null:
		Observer.log_error(LOG_CATEGORY, "Player reference is required in setup().")
		assert(false, "[PlayerHUD] Critical setup failure: player is null.")
		return

	health_component = ComponentValidator.require_node(player, NodePath("HealthComponent"), "HealthComponent", "HealthComponent") as HealthComponent
	Observer.log_debug(LOG_CATEGORY, "Resolved HealthComponent=%s" % health_component)
	if health_component == null:
		Observer.log_error(LOG_CATEGORY, "HealthComponent not found on player.")
		assert(false, "[PlayerHUD] Critical setup failure: missing HealthComponent.")
		return

	Observer.connect_once_safe(health_component.health_changed, _on_health_changed, "PlayerHUD.setup health_changed")
	_on_health_changed(health_component.current_health, health_component.max_health)

	stamina_component = ComponentValidator.require_node(player, NodePath("StaminaComponent"), "StaminaComponent", "StaminaComponent") as StaminaComponent
	Observer.log_debug(LOG_CATEGORY, "Resolved StaminaComponent=%s" % stamina_component)
	if stamina_component == null:
		Observer.log_error(LOG_CATEGORY, "StaminaComponent not found on player.")
		assert(false, "[PlayerHUD] Critical setup failure: missing StaminaComponent.")
		return

	Observer.connect_once_safe(stamina_component.stamina_changed, _on_stamina_changed, "PlayerHUD.setup stamina_changed")
	_on_stamina_changed(stamina_component.current_stamina, stamina_component.max_stamina)

	inventory_component = ComponentValidator.require_node(player, NodePath("InventoryComponent"), "InventoryComponent", "InventoryComponent") as InventoryComponent
	if inventory_component != null:
		Observer.connect_once_safe(inventory_component.item_changed, _on_inventory_item_changed, "PlayerHUD.setup item_changed")
		_update_inventory_label()

	if player.has_signal("interaction_prompt_changed") and not player.interaction_prompt_changed.is_connected(_on_player_interaction_prompt_changed):
		player.interaction_prompt_changed.connect(_on_player_interaction_prompt_changed)

	if player.has_signal("feedback_requested") and not player.feedback_requested.is_connected(show_message):
		player.feedback_requested.connect(show_message)


func show_note_panel(title: String, body: String) -> void:
	note_title_label.text = title
	note_body_label.text = body
	note_panel.visible = true
	show_message("Pressione Esc para fechar a nota")


func show_message(message: String, duration: float = 2.0) -> void:
	message_label.text = message
	message_label.visible = true
	message_timer.start(max(duration, 0.1))


func _on_message_timeout() -> void:
	message_label.visible = false


func _on_player_interaction_prompt_changed(prompt_text: String, visible: bool) -> void:
	if visible:
		interaction_prompt_label.text = "[E] %s" % prompt_text
		interaction_prompt_label.visible = true
	else:
		interaction_prompt_label.visible = false


func _update_inventory_label() -> void:
	if inventory_component == null:
		return

	var water := inventory_component.get_amount(&"water")
	var water_max := inventory_component.get_stack_limit(&"water")
	var fert := inventory_component.get_amount(&"fertilizer_bar")
	var fert_max := inventory_component.get_stack_limit(&"fertilizer_bar")

	inventory_label.text = "Agua: %d/%d  |  Adubo: %d/%d" % [water, water_max, fert, fert_max]


func _input(event: InputEvent) -> void:
	if note_panel.visible and event.is_action_pressed("ui_cancel"):
		note_panel.visible = false
		get_viewport().set_input_as_handled()


func _on_pause_pressed() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused

	if not paused:
		confirm_exit.hide()

	pause_menu.visible = paused


func _on_continuar_pressed() -> void:
	confirm_exit.hide()
	get_tree().paused = false
	pause_menu.visible = false


func _on_confirm_exit_dialog_confirmed() -> void:
	Observer.log_info(LOG_CATEGORY, "Emitting exit_requested signal.")
	confirm_exit.hide()
	pause_menu.visible = false
	get_tree().paused = false
	exit_requested.emit()


func _on_voltar_menu_pause_pressed() -> void:
	confirm_exit.popup_centered()


func _on_voltar_menu_hud_pressed() -> void:
	Observer.log_info(LOG_CATEGORY, "Emitting back_to_menu_requested signal.")
	confirm_exit.hide()
	pause_menu.visible = false
	get_tree().paused = false
	back_to_menu_requested.emit()


#contagem tempo
func _process(delta: float):
	if get_tree().paused:
		return
	
	time_elapsed += delta
	var time_elapsed_in_seconds: int = floori(time_elapsed)
	var seconds: int = time_elapsed_in_seconds % 60
	var minutes: int = time_elapsed_in_seconds / 60
	
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
