extends Control
class_name PlayerHUD

signal exit_requested
signal back_to_menu_requested

var player: CharacterBase
var health_component: HealthComponent
var stamina_component: StaminaComponent

@onready var health_bar: ProgressBar = $MarginContainer/HBoxContainer2/HealthProgressBar
@onready var stamina_bar: ProgressBar = $MarginContainer/HBoxContainer2/StaminaProgressBar
@onready var pause_menu: Control = $MarginContainer/PauseMenu
@onready var confirm_exit: ConfirmationDialog = $MarginContainer/PauseMenu/ConfirmExitDialog
@onready var timer_label: Label = $MarginContainer/TimerLabel

var time_elapsed: float = 0.0


func _ready() -> void:
	pause_menu.visible = false
	
func _on_health_changed(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health

func _on_stamina_changed(current_stamina: float, max_stamina: float) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina

func setup(new_player: CharacterBase) -> void:
	player = new_player
	print("HUD recebeu player:", player)
	
	if player == null:
		push_error("PlayerHUD precisa de uma referência ao Player.")
		return

	health_component = player.get_node_or_null("HealthComponent") as HealthComponent
	print("HealthComponent:", health_component)
	if health_component == null:
		push_error("PlayerHUD não encontrou HealthComponent no Player.")
		return

	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)

	_on_health_changed(health_component.current_health, health_component.max_health)

	stamina_component = player.get_node_or_null("StaminaComponent") as StaminaComponent
	print("StaminaComponent:", stamina_component)
	if stamina_component == null:
		push_error("PlayerHUD não encontrou StaminaComponent no Player.")
		return

	if not stamina_component.stamina_changed.is_connected(_on_stamina_changed):
		stamina_component.stamina_changed.connect(_on_stamina_changed)

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
	print("HUD emitiu exit")
	confirm_exit.hide()
	pause_menu.visible = false
	get_tree().paused = false
	exit_requested.emit()


func _on_voltar_menu_pause_pressed() -> void:
	confirm_exit.popup_centered()


func _on_voltar_menu_hud_pressed() -> void:
	print("HUD emitiu back_to_menu")
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
	
