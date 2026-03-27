extends Node

@export var main_menu_scene: PackedScene
@export var world_scene: PackedScene
@export var game_over_scene: PackedScene
@export var player_hud_scene: PackedScene

@onready var current_scene_holder: Node = $CurrentScene
@onready var ui_root: CanvasLayer = $UIRoot

var current_scene: Node = null
var current_hud: PlayerHUD = null

func _ready() -> void:
	load_main_menu()

func _clear_current_scene() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null

func _clear_current_hud() -> void:
	if current_hud:
		current_hud.queue_free()
		current_hud = null

func _set_scene(scene_resource: PackedScene) -> Node:
	_clear_current_scene()
	current_scene = scene_resource.instantiate()
	current_scene_holder.add_child(current_scene)
	return current_scene

func _set_hud(scene_resource: PackedScene, player: CharacterBase) -> PlayerHUD:
	_clear_current_hud()
	current_hud = scene_resource.instantiate() as PlayerHUD
	ui_root.add_child(current_hud)
	
	current_hud.call_deferred("setup", player)

	if not current_hud.exit_requested.is_connected(_on_hud_exit_requested):
		current_hud.exit_requested.connect(_on_hud_exit_requested)

	if not current_hud.back_to_menu_requested.is_connected(_on_hud_back_to_menu_requested):
		current_hud.back_to_menu_requested.connect(_on_hud_back_to_menu_requested)

	return current_hud

func load_main_menu() -> void:
	get_tree().paused = false
	_clear_current_hud()

	var menu = _set_scene(main_menu_scene)
	if menu.has_signal("start_game"):
		menu.start_game.connect(_on_start_game)

func load_world() -> void:
	get_tree().paused = false
	


	var world = _set_scene(world_scene)
	print("World instanciado:", world)
	print("Player do world:", world.get_player())
	
	if world.has_signal("player_died"):
		world.player_died.connect(_on_player_died)

	_set_hud(player_hud_scene, world.get_player())

func load_game_over() -> void:
	get_tree().paused = false
	_clear_current_hud()

	var game_over = _set_scene(game_over_scene)
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

func _on_hud_exit_requested() -> void:
	print("GameInstance recebeu exit")
	load_main_menu()

func _on_hud_back_to_menu_requested() -> void:
	print("GameInstance recebeu exit")
	load_main_menu()
