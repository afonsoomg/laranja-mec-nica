extends Control

func _on_voltar_sobre_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GUI/gameUI/main_menu.tscn")
