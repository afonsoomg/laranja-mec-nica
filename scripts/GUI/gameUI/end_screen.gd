extends Control

signal retry
signal back_to_menu

@onready var restart_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RestartButton


func _ready() -> void:
	restart_button.grab_focus()


func _on_restart_button_pressed() -> void:
	retry.emit()


func _on_main_menu_button_pressed() -> void:
	back_to_menu.emit()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
