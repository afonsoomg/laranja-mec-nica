extends Control
class_name PlayerHUD

@export var player: CharacterBase
@onready var health_bar: ProgressBar = $MarginContainer/HealthProgressBar
@onready var pause_menu: Control = $MarginContainer/PauseMenu
@onready var confirm_exit: ConfirmationDialog = $MarginContainer/PauseMenu/ConfirmExitDialog

@onready var timer_label: Label = $MarginContainer/TimerLabel
var time_elapsed: float = 0.0


var health_component: HealthComponent


func _ready() -> void:
	print("HUD carregando: ", self, " path=", get_path())
	pause_menu.visible = false
	
	if player == null:
		push_error("PlayerHUD precisa de uma referência ao Player.")
		return

	health_component = player.get_node_or_null("HealthComponent") as HealthComponent

	if health_component == null:
		push_error("PlayerHUD não encontrou HealthComponent no Player.")
		return

	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)

	_on_health_changed(health_component.current_health, health_component.max_health)


func _on_health_changed(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health


func _on_pause_pressed() -> void:
	var paused = !get_tree().paused
	get_tree().paused = paused
	pause_menu.visible = paused


func _on_continuar_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false


func _on_confirm_exit_dialog_confirmed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/GUI/menu_principal/main_menu.tscn") 


func _on_voltar_menu_pause_pressed() -> void:
	confirm_exit.popup_centered()


func _on_voltar_menu_hud_pressed() -> void:
	pass # Replace with function body.

#contagem tempo
func _process(delta: float):
	time_elapsed += delta
	var time_elapsed_in_seconds: int = floori(time_elapsed)
	var seconds: int = time_elapsed_in_seconds % 60
	var minutes: int = time_elapsed_in_seconds / 60
	
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
