extends Control

@export var menu_music: AudioStream
@export var ui_click_sound: AudioStream
@export var ui_hover_sound: AudioStream
@onready var main_buttons: PanelContainer = $MarginContainer/MainButtons
@onready var opcoes: Panel = $Opcoes
@onready var sobre_panel: Panel = $SobrePanel

enum MenuState { MAIN, OPTIONS, ABOUT }
var _state: MenuState = MenuState.MAIN

signal start_game

func _ready() -> void:
	AudioManagerCustom.play_music(menu_music)
	AudioManagerCustom.stop_ambient()
	_set_menu_state(MenuState.MAIN)


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
	_set_menu_state(MenuState.OPTIONS)


func _on_voltar_opcoes_pressed() -> void:
	_set_menu_state(MenuState.MAIN)


func _on_sobre_pressed() -> void:
	_set_menu_state(MenuState.ABOUT)
	
	
func _on_voltar_sobre_pressed() -> void:
	_set_menu_state(MenuState.MAIN)


func _set_menu_state(next_state: MenuState) -> void:
	_state = next_state
	main_buttons.visible = _state == MenuState.MAIN
	opcoes.visible = _state == MenuState.OPTIONS
	sobre_panel.visible = _state == MenuState.ABOUT
