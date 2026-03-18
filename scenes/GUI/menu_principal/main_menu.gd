extends Control

func _on_jogar_pressed():
	get_tree().change_scene_to_file("res://scenes/world.tscn")

#func _on_opcoes_pressed():
	#print("Abrir opções")

func _on_sair_pressed():
	get_tree().quit()
