extends Node

@onready var current_scene_holder: Node = $CurrentScene

var current_scene: Node = null

func _ready() -> void:
	load_main_menu()

func _clear_current_scene() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null

func _set_scene(scene_path: String) -> Node:
	_clear_current_scene()

	var packed := load(scene_path) as PackedScene
	current_scene = packed.instantiate()
	current_scene_holder.add_child(current_scene)
	return current_scene

func load_main_menu() -> void:
	var menu = _set_scene("res://scenes/GUI/gameUI/main_menu.tscn")
	if menu.has_signal("start_game"):
		menu.start_game.connect(_on_start_game)

func load_world() -> void:
	var world = _set_scene("res://scenes/world.tscn")
	if world.has_signal("player_died"):
		world.player_died.connect(_on_player_died)

func load_game_over() -> void:
	var game_over = _set_scene("res://scenes/GUI/gameUI/GameOver.tscn")
	if game_over.has_signal("retry"):
		game_over.retry.connect(_on_retry)
	if game_over.has_signal("back_to_menu"):
		game_over.back_to_menu.connect(load_main_menu)

func _on_start_game() -> void:
	load_world()

func _on_player_died() -> void:
	load_game_over()

func _on_retry() -> void:
	load_world()
