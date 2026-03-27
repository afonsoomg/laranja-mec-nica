extends Control
class_name PlayerHUD

const Observer = preload("res://scripts/utils/observability.gd")
const LOG_CATEGORY := "PlayerHUD"

signal exit_requested
signal back_to_menu_requested

var player: CharacterBase
var health_component: HealthComponent
var stamina_component: StaminaComponent

var health_bar: ProgressBar
var stamina_bar: ProgressBar
var pause_menu: Control
var confirm_exit: ConfirmationDialog
var timer_label: Label

var time_elapsed: float = 0.0


func _ready() -> void:
	if not ComponentValidator.require_nodes(self, [
		{"path": NodePath("MarginContainer/HBoxContainer2/HealthProgressBar"), "expected_type": "ProgressBar", "name": "HealthProgressBar", "assign_to": "health_bar"},
		{"path": NodePath("MarginContainer/HBoxContainer2/StaminaProgressBar"), "expected_type": "ProgressBar", "name": "StaminaProgressBar", "assign_to": "stamina_bar"},
		{"path": NodePath("MarginContainer/PauseMenu"), "expected_type": "Control", "name": "PauseMenu", "assign_to": "pause_menu"},
		{"path": NodePath("MarginContainer/PauseMenu/ConfirmExitDialog"), "expected_type": "ConfirmationDialog", "name": "ConfirmExitDialog", "assign_to": "confirm_exit"},
		{"path": NodePath("MarginContainer/TimerLabel"), "expected_type": "Label", "name": "TimerLabel", "assign_to": "timer_label"},
	]):
		set_process(false)
		return
	pause_menu.visible = false


func _on_health_changed(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health


func _on_stamina_changed(current_stamina: float, max_stamina: float) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina


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
	
