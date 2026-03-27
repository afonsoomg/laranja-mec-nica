extends Node

signal retry
signal back_to_menu

func _on_restart_btn_pressed():
	retry.emit()	


func _on_back_to_menu_btn_pressed() -> void:
	back_to_menu.emit()


func _on_quit_btn_pressed():
	get_tree().quit()
	
