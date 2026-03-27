extends Control

@export var menu_music: AudioStream
@export var ui_click_sound: AudioStream
@export var ui_hover_sound: AudioStream

signal start_game

func _ready() -> void:
	AudioManagerCustom.play_music(menu_music)
	AudioManagerCustom.stop_ambient()


func _on_jogar_pressed() -> void:
	AudioManagerCustom.play_ui(ui_click_sound)
	AudioManagerCustom.stop_music()
	start_game.emit()


func _on_sair_pressed() -> void:
	AudioManagerCustom.play_ui(ui_click_sound)
	get_tree().quit()


func _on_mouse_hover() -> void:
	AudioManagerCustom.play_ui(ui_hover_sound)

	
