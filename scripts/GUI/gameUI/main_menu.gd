extends Control

@export var menu_music: AudioStream
@export var ui_click_sound: AudioStream
@export var ui_hover_sound: AudioStream
@onready var main_buttons: PanelContainer = $MarginContainer/MainButtons
@onready var opcoes: Panel = $Opcoes



signal start_game

func _ready() -> void:
	AudioManagerCustom.play_music(menu_music)
	AudioManagerCustom.stop_ambient()
	main_buttons.visible = true
	opcoes.visible = false


func _on_jogar_pressed() -> void:
	AudioManagerCustom.play_ui(ui_click_sound)
	AudioManagerCustom.stop_music()
	start_game.emit()



func _on_sair_pressed() -> void:
	AudioManagerCustom.play_ui(ui_click_sound)
	get_tree().quit()


func _on_mouse_hover() -> void:
	AudioManagerCustom.play_ui(ui_hover_sound)


func _on_opcoes_pressed() -> void:
	print("Opções Selecionada")
	main_buttons.visible = false
	opcoes.visible = true


func _on_voltar_opcoes_pressed() -> void:
	_ready()


func _on_sobre_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GUI/gameUI/sobre_nos.tscn")
